/**
 * 增强阅读器 - 适配手机/平板/折叠屏 PC
 * 包含：多栏布局、字体跟随、无障碍支持、沉浸式体验
 * 功能：书籍内容渲染、TTS朗读、书签、笔记、进度跟踪
 */
import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { AdaptiveContainer } from '../presentation/common/components/AdaptiveContainer';
import { A11yButton, A11yImage, A11yListItem } from '../presentation/common/components/A11yComponents';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { ttsService, TTSListener, TTSProgress } from '../services/ai/TTSService';
import { novelPlayer, NovelChapter, PlayState, NovelConfig } from '../services/audio/NovelPlayerService';
import { BookInfo, Bookmark, Note } from '../models/CoreBookModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { ReaderSettings } from '../utils/prefs';
import { BookContentParser, ChapterInfo } from '../utils/BookContentParser';
import { themeManager, appTheme, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';
import { PageStyles } from '../utils/PageStyles';
import { LazyDataSource } from '../common/datasource/LazyDataSource';
import { audioPlayerService, AudioPlayState, AudioPlayConfig, AudioPlayProgress } from '../services/audio/AudioPlayerService';
import { aiService, TaskType, LanguageCode } from '../services/ai/AIService';

interface EnhancedReaderParams {
  title?: string;
  path?: string;
  bookId?: string;
  chapterIndex?: string;
}

@Entry
@Component
struct EnhancedReaderPage {
  @State bookTitle: string = '';
  @State bookId: string = '';
  @State bookPath: string = '';
  @State content: string = '';
  @State chapters: ChapterInfo[] = [];
  @State currentChapterIndex: number = 0;
  @State isMenuVisible: boolean = false;
  @State isTTSPlaying: boolean = false;
  @State fontSize: number = 18;
  @State lineHeight: number = 1.6;
  @State isDarkMode: boolean = false;
  @State currentBreakpoint: string = 'sm';
  @State progress: number = 0;
  @State bookmarks: Bookmark[] = [];
  @State notes: Note[] = [];
  @State showBookmarkDialog: boolean = false;
  @State showNoteDialog: boolean = false;
  @State selectedText: string = '';
  @State isLoading: boolean = true;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showTTSPanel: boolean = false;
  @State ttsSpeed: number = 1.0;
  @State ttsPageIndex: number = 0;
  @State ttsTotalPages: number = 0;
  // AudioPlayer (music)
  @State showAudioPanel: boolean = false;
  @State isAudioPlaying: boolean = false;
  @State audioProgressValue: number = 0;
  @State audioCurrentTime: number = 0;
  @State audioDuration: number = 0;
  @State audioFileName: string = '';
  // AI panel
  @State showAIPanel: boolean = false;
  @State aiSummaryText: string = '';
  @State aiTranslationText: string = '';
  @State isAIProcessing: boolean = false;
  @State aiActiveTab: number = 0;

  private win: window.Window | null = null;
  private bookInfo: BookInfo | null = null;
  @State private context: common.Context | null = null;
  private ttsListener: TTSListener | null = null;

  // LazyForEach 鏁版嵁婧?
  private chapterDataSource: LazyDataSource<ChapterInfo> = new LazyDataSource<ChapterInfo>((item: ChapterInfo, index: number) => item.title + index);

  aboutToAppear() {
    try {
      this.context = this.getUIContext().getHostContext() as common.Context;
      this.initData();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('Reader page init failed:', message);
      this.isLoading = false;
    }
  }

  private async initData(): Promise<void> {
    // 初始化主题和字体缩放
    await fontScaleManager.init(this.context as common.Context);
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();

    // 获取路由参数
    const params = router.getParams() as EnhancedReaderParams;
    if (params) {
      this.bookTitle = params.title || '书籍详情';
      this.bookPath = params.path || '';
      this.bookId = params.bookId || '';
      this.currentChapterIndex = params.chapterIndex ? parseInt(params.chapterIndex) : 0;
    }

    // 初始化TTS
    await ttsService.init(this.context as common.Context);

    // 设置 TTS 监听器（保留基本TTS用于简单朗读）
    this.ttsListener = {
      onStart: () => { this.isTTSPlaying = true; },
      onComplete: () => { this.isTTSPlaying = false; },
      onError: (error: string) => {
        this.isTTSPlaying = false;
        console.error('TTS Error:', error);
      },
      onProgress: (progress: TTSProgress) => { /* 高亮当前朗读的文字 */ }
    };
    ttsService.setListener(this.ttsListener);

    // 设置NovelPlayer TTS监听（用于章节级分页朗读）
    novelPlayer.addTTSListener((state: string) => {
      this.isTTSPlaying = state === 'playing';
    });
    novelPlayer.addPageChangeListener((index: number) => {
      this.ttsPageIndex = index;
    });

    // 设置音频播放监听（背景音乐）
    audioPlayerService.setListener({
      onStateChange: (state: AudioPlayState): void => {
        this.isAudioPlaying = state === AudioPlayState.PLAYING;
      },
      onProgress: (progress: AudioPlayProgress): void => {
        this.audioProgressValue = progress.percentage;
        this.audioCurrentTime = progress.currentPosition;
        this.audioDuration = progress.duration;
      },
      onError: (error: string): void => {
        console.error('[Reader] Audio error:', error);
      },
      onCompleted: (): void => {
        this.isAudioPlaying = false;
      }
    });

    // 初始化AI服务
    aiService.init();

    // 加载书籍内容
    await this.loadBookContent();

    // 加载用户设置
    this.loadUserSettings();

    // 窗口控制
    try {
      this.win = await window.getLastWindow(this.context as common.Context);
      if (this.win) {
        await this.win.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          statusBarContentColor: '#FFFFFF'
        });
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('Window setup failed:', message);
    }
  }

  aboutToDisappear() {
    // 保存阅读进度
    this.saveReadingProgress();

    // 停止 TTS
    if (this.isTTSPlaying) {
      ttsService.stop();
    }
    if (novelPlayer.getPlayState() !== PlayState.STOPPED) {
      novelPlayer.stopPlaying();
    }
    // 不要 release 全局单例资源，会影响其他页面
  }

  private async loadBookContent(): Promise<void> {
    try {
      this.isLoading = true;
      
      // ?BookViewModel 获取书籍信息
      if (this.bookId) {
        const book = bookViewModel.getBookById(this.bookId);
        this.bookInfo = book ? book : null;
      }
      
      if (this.bookInfo && this.bookInfo.filePath) {
        // 解析书籍内容
        const parseResult = await BookContentParser.parseFile(this.bookInfo.filePath);
        
        if (parseResult.success && parseResult.content) {
          this.content = parseResult.content;
          this.chapters = parseResult.chapters || [];
          this.chapterDataSource.setData(this.chapters);
          this.bookTitle = parseResult.metadata?.title || this.bookTitle;
          
          // 加载上次阅读进度
          if (this.bookInfo.lastReadPosition !== undefined) {
            // lastReadPosition 是页?偏移?需要转换为章节索引
            const lastReadPos: number = this.bookInfo.lastReadPosition;
            const positionChapterIndex: number = this.chapters.findIndex((chapter: ChapterInfo) =>
              chapter.startPosition <= lastReadPos &&
              chapter.endPosition > lastReadPos
            );
            if (positionChapterIndex >= 0) {
              this.currentChapterIndex = positionChapterIndex;
            }
          }
          
          // 显示当前章节
          this.displayCurrentChapter();
        } else {
          this.content = '书籍内容解析失败';
        }
      } else {
        // 如果没有文件路径，尝试从缓存加载
        const cachedContent: string = await preferenceManager.getValue(`cached_content_${this.bookId}`, '');
        if (cachedContent) {
          this.content = cachedContent;
        } else {
          this.content = 'No content available';
        }
      }
      
      // 加载书签和笔?
      const allBookmarks: Record<string, Bookmark[]> = preferenceManager.getAllBookmarks();
      const bookmarksList = allBookmarks[this.bookId];
      this.bookmarks = bookmarksList ? bookmarksList.slice() : [];

      const allNotes: Record<string, Note[]> = preferenceManager.getNotes();
      const notesList = allNotes[this.bookId];
      this.notes = notesList ? notesList.slice() : [];
      
      this.isLoading = false;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('Load book content failed:', message);
      this.content = '加载失败，请重试';
      this.isLoading = false;
    }
  }

  private displayCurrentChapter(): void {
    if (this.chapters.length > 0 && this.currentChapterIndex < this.chapters.length) {
      const chapter = this.chapters[this.currentChapterIndex];
      // 提取章节内容（简化实现，实际应该从完整内容中提取?
      const chapterStart = chapter.startPosition || 0;
      const chapterEnd = chapter.endPosition || this.content.length;
      this.content = this.content.substring(chapterStart, chapterEnd);
    }
    
    // 更新进度
    this.updateProgress();
  }

  private loadUserSettings(): void {
    const settings: ReaderSettings = preferenceManager.getReadSettings();
    this.fontSize = settings.fontSize || 18;
    this.lineHeight = settings.lineHeight || 1.6;
    this.isDarkMode = settings.isDarkMode || false;
  }

  private saveReadingProgress(): void {
    if (this.bookId) {
      bookViewModel.updateReadingProgress(
        this.bookId,
        this.currentChapterIndex,
        0 // 滚动位置
      );
    }
  }

  private updateProgress(): void {
    if (this.chapters.length > 0) {
      this.progress = Math.round((this.currentChapterIndex / this.chapters.length) * 100);
    }
  }

  private goToChapter(index: number): void {
    if (index >= 0 && index < this.chapters.length) {
      this.currentChapterIndex = index;
      this.displayCurrentChapter();
      this.saveReadingProgress();
    }
  }

  private previousChapter(): void {
    this.goToChapter(this.currentChapterIndex - 1);
  }

  private nextChapter(): void {
    this.goToChapter(this.currentChapterIndex + 1);
  }

  private addBookmark(): void {
    if (!this.bookId) return;

    const bookmark: Bookmark = {
      id: Date.now().toString(),
      bookId: this.bookId,
      pageNumber: this.currentChapterIndex,
      title: `书签 ${this.bookmarks.length + 1}`,
      createTime: Date.now()
    };

    const newBookmarks = this.bookmarks.slice();
    newBookmarks.push(bookmark);
    this.bookmarks = newBookmarks;
    const allBookmarks: Record<string, Bookmark[]> = preferenceManager.getAllBookmarks();
    allBookmarks[this.bookId] = this.bookmarks;
    preferenceManager.setBookmarks(allBookmarks);
  }

  private addNote(text: string): void {
    if (!this.bookId) return;

    const note: Note = {
      id: Date.now().toString(),
      bookId: this.bookId,
      pageNumber: this.currentChapterIndex,
      content: '',
      highlight: text || this.selectedText,
      createTime: Date.now(),
      tags: []
    };

    this.notes.push(note);
    const allNotes: Record<string, Note[]> = preferenceManager.getNotes();
    allNotes[this.bookId] = this.notes;
    preferenceManager.setNotes(allNotes);
  }

  // ==================== NovelPlayer TTS控制 ====================

  private toggleNovelTTS(): void {
    const state = novelPlayer.getPlayState();
    if (state === PlayState.PLAYING) {
      novelPlayer.pausePlaying();
    } else if (state === PlayState.PAUSED) {
      novelPlayer.resumePlaying();
    } else {
      this.loadCurrentChapterToNovelPlayer();
    }
    this.showTTSPanel = novelPlayer.getPlayState() !== PlayState.STOPPED;
  }

  private async loadCurrentChapterToNovelPlayer(): Promise<void> {
    if (this.chapters.length === 0 || this.currentChapterIndex >= this.chapters.length) {
      return;
    }

    const chapter = this.chapters[this.currentChapterIndex];
    const chapterStart = chapter.startPosition || 0;
    const chapterEnd = chapter.endPosition || this.content.length;
    const chapterContent = this.content;

    const novelChapter: NovelChapter = {
      chapterId: chapter.id,
      title: chapter.title,
      content: chapterContent,
      wordCount: chapterContent.length,
      isVip: false
    };

    await novelPlayer.loadChapter(novelChapter);

    // 同步配置
    await novelPlayer.updateConfig({
      speechRate: this.ttsSpeed,
      autoScroll: true,
      scrollSpeed: 3
    });

    this.ttsTotalPages = novelPlayer.getTotalPages();
    this.ttsPageIndex = 0;

    await novelPlayer.startPlaying();
    this.isTTSPlaying = true;
    this.showTTSPanel = true;
  }

  private stopNovelTTS(): void {
    novelPlayer.stopPlaying();
    this.isTTSPlaying = false;
    this.showTTSPanel = false;
    this.ttsPageIndex = 0;
    this.ttsTotalPages = 0;
  }

  private changeTTSSpeed(delta: number): void {
    const newSpeed = Math.max(0.5, Math.min(2.0, this.ttsSpeed + delta));
    this.ttsSpeed = newSpeed;
    novelPlayer.updateConfig({ speechRate: newSpeed });
  }

  private onTTSPreviousPage(): void {
    novelPlayer.previousPage();
    this.ttsPageIndex = novelPlayer.getCurrentPageIndex();
  }

  private onTTSNextPage(): void {
    novelPlayer.nextPage();
    this.ttsPageIndex = novelPlayer.getCurrentPageIndex();
  }

  // ==================== AudioPlayer 背景音乐控制 ====================

  private async pickAndPlayAudio(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.fileSuffixFilters = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];
      options.maxSelectNumber = 1;

      const result = await documentPicker.select(options);
      if (result && result.length > 0) {
        const uri: string = result[0];
        const nameStart: number = uri.lastIndexOf('/') + 1;
        this.audioFileName = uri.substring(nameStart);
        await audioPlayerService.play({ src: uri, loop: false, volume: 0.8 });
        this.showAudioPanel = true;
      }
    } catch (e) {
      console.error('[Reader] Pick audio failed:', e instanceof Error ? e.message : String(e));
    }
  }

  private toggleAudioPlayPause(): void {
    if (this.isAudioPlaying) {
      audioPlayerService.pause();
    } else {
      audioPlayerService.resume();
    }
  }

  private async stopAudio(): Promise<void> {
    await audioPlayerService.stop();
    this.isAudioPlaying = false;
    this.showAudioPanel = false;
    this.audioFileName = '';
  }

  private formatAudioTime(ms: number): string {
    if (ms <= 0) return '00:00';
    const totalSec: number = Math.floor(ms / 1000);
    const min: number = Math.floor(totalSec / 60);
    const sec: number = totalSec % 60;
    return min.toString().padStart(2, '0') + ':' + sec.toString().padStart(2, '0');
  }

  // ==================== AI 智能阅读 ====================

  private async requestAISummary(): Promise<void> {
    if (this.isAIProcessing) return;
    this.isAIProcessing = true;
    this.aiActiveTab = 0;
    this.showAIPanel = true;

    try {
      const chapterContent: string = this.content || '';
      if (chapterContent.length < 50) {
        this.aiSummaryText = '章节内容过短，无法生成摘要';
        this.isAIProcessing = false;
        return;
      }

      const result: string = await aiService.summarizeChapter(
        this.chapters.length > 0 ? this.chapters[this.currentChapterIndex].title : '当前章节',
        chapterContent.substring(0, 3000)
      );
      this.aiSummaryText = result;
    } catch (e) {
      this.aiSummaryText = 'AI摘要生成失败: ' + (e instanceof Error ? e.message : String(e));
    } finally {
      this.isAIProcessing = false;
    }
  }

  private async requestAITranslation(): Promise<void> {
    if (this.isAIProcessing) return;
    this.isAIProcessing = true;
    this.aiActiveTab = 1;
    this.showAIPanel = true;

    try {
      const chapterContent: string = this.content || '';
      if (chapterContent.length < 20) {
        this.aiTranslationText = '内容过短，无法翻译';
        this.isAIProcessing = false;
        return;
      }

      const result = await aiService.translate(
        chapterContent.substring(0, 2000),
        LanguageCode.ZH_CN
      );
      this.aiTranslationText = result.translatedText;
    } catch (e) {
      this.aiTranslationText = 'AI翻译失败: ' + (e instanceof Error ? e.message : String(e));
    } finally {
      this.isAIProcessing = false;
    }
  }

  private closeAIPanel(): void {
    this.showAIPanel = false;
    this.aiSummaryText = '';
    this.aiTranslationText = '';
  }

  build() {
    Stack() {
      // 加载指示器
      if (this.isLoading) {
        Column({ space: PageStyles.spacing('md') }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(PageStyles.themeColor('primary'))
            .animation({ duration: 1000, curve: Curve.EaseInOut, iterations: -1 })

          Text('加载中...')
            .fontSize(PageStyles.fontSize('md'))
            .fontColor(PageStyles.textColor(this.isDarkMode, 'secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(PageStyles.bgColor(this.isDarkMode, 'page'))
        .animation(PageStyles.animation('normal'))
      }

      // 外层使用自适应容器
      AdaptiveContainer({
        sidePanel: () => { this.buildSidePanel(); },
        content: () => { this.buildMainContent(); }
      })
      // 点击屏幕切换菜单显示 (沉浸式体验)
      .onClick(() => {
        this.isMenuVisible = !this.isMenuVisible;
      })
      // 监听断点变化
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.currentBreakpoint = Number(newValue.width) > 600 ? 'md' : 'sm';
      })

      // TTS控制面板（浮层）
      if (this.showTTSPanel) {
        this.TTSControlPanel()
      }

      // 音频播放面板（浮层）
      if (this.showAudioPanel) {
        this.AudioPlayerPanel()
      }

      // AI阅读面板（浮层）
      if (this.showAIPanel) {
        this.AIPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageStyles.bgColor(this.isDarkMode, 'page'))
  }

  @Builder
  buildMainContent() {
    // 正文区域
    Column() {
      // 顶部标题栏(仅在菜单显示时显示，或平板常显)
      if (this.isMenuVisible || this.currentBreakpoint !== 'sm') {
        this.buildTopBar()
      }

      // 核心文本显示区
      Scroll() {
        Column() {
          // 章节标题
          if (this.chapters.length > 0 && this.currentChapterIndex < this.chapters.length) {
            Text(this.chapters[this.currentChapterIndex].title)
              .fontSize(this.fontSize + 4)
              .fontWeight(FontWeight.Bold)
              .fontColor(PageStyles.textColor(this.isDarkMode, 'primary'))
              .margin({ bottom: PageStyles.spacing('lg') })
          }

          // 正文内容
          Text(this.content || '加载中...')
            .fontSize(this.fontSize)
            .lineHeight(this.fontSize * this.lineHeight)
            .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
            .textAlign(TextAlign.JUSTIFY)
            .padding({
              left: this.currentBreakpoint === 'sm' ? PageStyles.spacing('md') : PageStyles.spacing('lg'),
              right: this.currentBreakpoint === 'sm' ? PageStyles.spacing('md') : PageStyles.spacing('lg'),
              top: PageStyles.spacing('sm'),
              bottom: PageStyles.spacing('xl')
            })
            // 无障碍：长按支持选词/朗读
            .accessibilityText(`正在阅读${this.bookTitle}，长按可选择文本`)
            .gesture(
              LongPressGesture({ repeat: false })
                .onAction(() => {
                  // TODO: 实现文本选择
                })
            )
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(this.isDarkMode ? '#1A1A1A' : '#FDFBF7')
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)

      // 底部控制栏(仅菜单显示时)
      if (this.isMenuVisible) {
        this.buildBottomBar()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildSidePanel() {
    // 侧边栏：目录/书签/笔记
    Tabs() {
      TabContent() {
        this.buildChapterList()
      }
      .tabBar('目录')

      TabContent() {
        this.buildSidePanel()
      }
      .tabBar('Marks')

      TabContent() {
        this.buildNoteList()
      }
      .tabBar('笔记')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  @Builder
  buildChapterList() {
    Column({ space: 16 }) {
      // 侧边栏头?
      Row() {
        Text('目录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFF' : '#000')
.layoutWeight(1)
        A11yButton({
          text: 'X',
          btnType: 'secondary',
          onClickCallback: () => this.isMenuVisible = false
        })
      }
      .padding({ bottom: 8 })

      if (this.bookmarks.length > 0) {
        List({ space: 8 }) {
          ForEach(this.bookmarks, (bookmark: Bookmark) => {
            ListItem() {
              Column() {
                Text(bookmark.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDarkMode ? '#FFF' : '#000')
                if (bookmark.note) {
                  Text(bookmark.note)
                    .fontSize(12)
                    .fontColor(this.isDarkMode ? '#999' : '#666')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFF')
              .borderRadius(8)
              .onClick(() => {
                // 跳转到书签位?
                this.isMenuVisible = false;
              })
            }
          }, (bookmark: Bookmark) => bookmark.id)
        }
        .layoutWeight(1)
      } else {
        Text('暂无书签')
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#999' : '#666')
          .textAlign(TextAlign.Center)
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildNoteList() {
    Column({ space: 16 }) {
      Row() {
        Text('笔记')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFF' : '#000')
          .layoutWeight(1)
        A11yButton({
          text: '×',
          btnType: 'secondary',
          onClickCallback: () => this.isMenuVisible = false
        })
      }
      .padding({ bottom: 8 })

      if (this.notes.length > 0) {
        List({ space: 8 }) {
          ForEach(this.notes, (note: Note) => {
            ListItem() {
              Column() {
                if (note.highlight) {
                  Text(note.highlight)
                    .fontSize(14)
                    .fontColor(this.isDarkMode ? '#CCC' : '#333')
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                if (note.content) {
                  Text(note.content)
                    .fontSize(12)
                    .fontColor(this.isDarkMode ? '#999' : '#666')
                    .margin({ top: 4 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFF')
              .borderRadius(8)
            }
          }, (note: Note) => note.id)
        }
        .layoutWeight(1)
      } else {
        Text('暂无笔记')
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#999' : '#666')
          .textAlign(TextAlign.Center)
          .width('100%')
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTopBar() {
    Row() {
      A11yButton({
text: 'Cancel',
          btnType: 'secondary',
        onClickCallback: () => {
          try {
            router.back();
          } catch (e) {
            console.error('EnhancedReaderPage back failed:', e instanceof Error ? e.message : String(e));
          }
        }
      })
      Text(this.bookTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFF' : '#000')
        .layoutWeight(1)
        .margin({ left: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 添加书签按钮
      A11yButton({
        text: 'bookmark_fill',
        btnType: 'secondary',
        onClickCallback: () => this.addBookmark()
      })
    }
    .height(56)
    .padding({ left: 16, right: 16 })
    .width('100%')
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
  }

  @Builder
  buildBottomBar() {
    Column({ space: 16 }) {
      // 进度条与翻页
      Row({ space: 16 }) {
        A11yButton({
          text: '上一页',
          btnType: 'secondary',
          onClickCallback: () => this.previousChapter()
        })

        Column() {
          Slider({
            value: this.progress,
            min: 0,
            max: 100
          })
            .layoutWeight(1)
            .height(40)
            .onChange((value: number) => {
              const chapterIndex = Math.floor((value / 100) * (this.chapters.length - 1));
              this.goToChapter(chapterIndex);
            })
          Text(`${this.progress}%`)
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#999' : '#666')
        }
        .layoutWeight(1)

        A11yButton({
          text: '下一章',
          btnType: 'secondary',
          onClickCallback: () => this.nextChapter()
        })
      }
      .width('100%')

      // 设置按钮?
      Row({ space: 24 }) {
        // 字体大小调节
        A11yButton({
          text: 'A-',
          onClickCallback: () => {
            this.fontSize = Math.max(this.fontSize - 2, 12);
            preferenceManager.setReadSettings({
              fontSize: this.fontSize,
              lineHeight: this.lineHeight,
              isDarkMode: this.isDarkMode
            });
          }
        })
        A11yButton({
          text: 'A+',
          onClickCallback: () => {
            this.fontSize = Math.min(this.fontSize + 2, 30);
            preferenceManager.setReadSettings({
              fontSize: this.fontSize,
              lineHeight: this.lineHeight,
              isDarkMode: this.isDarkMode
            });
          }
        })

        // TTS 朗读按钮（使用NovelPlayer分页朗读）
        A11yButton({
          text: this.isTTSPlaying ? '⏹ 停止' : '🔊 朗读',
          onClickCallback: () => this.toggleNovelTTS()
        })

        // 夜间模式切换
        A11yButton({
          text: this.isDarkMode ? '☀?日间' : 'moon_fill 夜间',
          onClickCallback: () => {
            this.isDarkMode = !this.isDarkMode;
            preferenceManager.setReadSettings({
              fontSize: this.fontSize,
              lineHeight: this.lineHeight,
              isDarkMode: this.isDarkMode
            });
          }
        })

        // 背景音乐
        A11yButton({
          text: this.isAudioPlaying ? '🎵 暂停' : '🎵 音乐',
          onClickCallback: () => {
            if (this.showAudioPanel) {
              this.showAudioPanel = !this.showAudioPanel;
            } else {
              this.pickAndPlayAudio();
            }
          }
        })

        // AI 阅读
        A11yButton({
          text: 'AI 阅读',
          onClickCallback: () => {
            this.showAIPanel = !this.showAIPanel;
            if (this.showAIPanel && !this.aiSummaryText && !this.aiTranslationText) {
              this.requestAISummary();
            }
          }
        })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .padding(24)
    .width('100%')
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  TTSControlPanel() {
    Column() {
      // 半透明背景遮罩
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showTTSPanel = false)

      // TTS控制面板
      Column({ space: 12 }) {
        // 进度信息
        Row({ space: 8 }) {
          Text('朗读中')
            .fontSize(13)
            .fontColor(this.isDarkMode ? '#CCCCCC' : '#666666')

          Text(this.chapters.length > 0 ? this.chapters[this.currentChapterIndex].title : '')
            .fontSize(13)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 关闭按钮
          Text('✕')
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.stopNovelTTS())
        }
        .width('100%')

        // 进度条
        Row({ space: 8 }) {
          Text(this.ttsPageIndex.toString())
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')

          Slider({
            value: this.ttsTotalPages > 0 ? this.ttsPageIndex : 0,
            min: 0,
            max: this.ttsTotalPages > 0 ? this.ttsTotalPages - 1 : 1
          })
            .layoutWeight(1)
            .height(32)
            .onChange((value: number) => {
              novelPlayer.goToPage(value);
              this.ttsPageIndex = novelPlayer.getCurrentPageIndex();
            })

          Text(this.ttsTotalPages > 0 ? (this.ttsTotalPages - 1).toString() : '0')
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
        }
        .width('100%')

        // 控制按钮行
        Row({ space: 24 }) {
          // 上一页
          Column() {
            Text('⏮')
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.onTTSPreviousPage())

          // 速度减
          Column() {
            Text('−')
              .fontSize(20)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(36)
          .height(36)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.changeTTSSpeed(-0.25))

          // 播放/暂停
          Column() {
            Text(novelPlayer.getPlayState() === PlayState.PAUSED ? '▶' : '⏸')
              .fontSize(28)
              .fontColor('#FFFFFF')
          }
          .width(56)
          .height(56)
          .backgroundColor('#007DFF')
          .borderRadius(28)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.toggleNovelTTS())

          // 速度加
          Column() {
            Text('+')
              .fontSize(20)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(36)
          .height(36)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.changeTTSSpeed(0.25))

          // 下一页
          Column() {
            Text('⏭')
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.onTTSNextPage())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 速度显示
        Text('语速: ' + this.ttsSpeed.toFixed(2) + 'x')
          .fontSize(11)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(20)
      .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AudioPlayerPanel() {
    Column() {
      // 半透明背景遮罩
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showAudioPanel = false)

      // 音频控制面板
      Column({ space: 12 }) {
        // 标题行
        Row({ space: 8 }) {
          Text('🎵 背景音乐')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')

          Text(this.audioFileName)
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('✕')
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.stopAudio())
        }
        .width('100%')

        // 进度条
        Row({ space: 8 }) {
          Text(this.formatAudioTime(this.audioCurrentTime))
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')

          Slider({
            value: this.audioProgressValue,
            min: 0,
            max: 100
          })
            .layoutWeight(1)
            .height(32)
            .onChange((value: number) => {
              const pos: number = (value / 100) * this.audioDuration;
              audioPlayerService.seek(pos);
            })

          Text(this.formatAudioTime(this.audioDuration))
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
        }
        .width('100%')

        // 控制按钮
        Row({ space: 32 }) {
          // 停止
          Column() {
            Text('⏹')
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.stopAudio())

          // 播放/暂停
          Column() {
            Text(this.isAudioPlaying ? '⏸' : '▶')
              .fontSize(28)
              .fontColor('#FFFFFF')
          }
          .width(56)
          .height(56)
          .backgroundColor('#007DFF')
          .borderRadius(28)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.toggleAudioPlayPause())

          // 选择文件
          Column() {
            Text('📂')
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.pickAndPlayAudio())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(20)
      .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AIPanel() {
    Column() {
      // 半透明背景遮罩
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.closeAIPanel())

      // AI 面板
      Column({ space: 12 }) {
        // 标题行
        Row({ space: 8 }) {
          Text('AI 阅读助手')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')

          Blank()

          Text('✕')
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.closeAIPanel())
        }
        .width('100%')

        // Tab 切换
        Row({ space: 12 }) {
          // 摘要按钮
          Text('📝 摘要')
            .fontSize(12)
            .fontColor(this.aiActiveTab === 0 ? '#FFFFFF' : this.isDarkMode ? '#AAAAAA' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.aiActiveTab === 0 ? '#007DFF' : this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .borderRadius(16)
            .onClick(() => {
              this.aiActiveTab = 0;
              if (!this.aiSummaryText) {
                this.requestAISummary();
              }
            })

          // 翻译按钮
          Text('🌐 翻译')
            .fontSize(12)
            .fontColor(this.aiActiveTab === 1 ? '#FFFFFF' : this.isDarkMode ? '#AAAAAA' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.aiActiveTab === 1 ? '#007DFF' : this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .borderRadius(16)
            .onClick(() => {
              this.aiActiveTab = 1;
              if (!this.aiTranslationText) {
                this.requestAITranslation();
              }
            })
        }
        .width('100%')

        // 内容区
        Scroll() {
          if (this.isAIProcessing) {
            Column({ space: 12 }) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color('#007DFF')

              Text('AI 处理中...')
                .fontSize(13)
                .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
            }
            .width('100%')
            .padding(40)
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 12 }) {
              // 摘要内容
              if (this.aiActiveTab === 0) {
                Text(this.aiSummaryText || '点击摘要按钮生成内容摘要')
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
                  .lineHeight(20)
              } else {
                Text(this.aiTranslationText || '点击翻译按钮翻译当前章节')
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
                  .lineHeight(20)
              }
            }
            .width('100%')
            .padding(4)
          }
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height(320)
      .padding(20)
      .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
  }
}