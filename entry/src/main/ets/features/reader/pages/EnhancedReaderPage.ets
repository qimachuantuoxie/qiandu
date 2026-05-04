import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
/**
 * 澧炲己闃呰�?- 閫傞厤鎵嬫満/骞虫�?鎶樺彔锟?PC
 * 鍖呭惈锛氬鏍忓竷灞€銆佸瓧浣撹窡闅忋€佹棤闅滅鏀寔銆佹矇娴稿紡浣撻�?
 * 鍔熻兘锛氫功绫嶅唴瀹规覆鏌撱€乀TS鏈楄銆佷功绛俱€佺瑪璁般€佽繘搴﹁窡锟?
 */
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { AdaptiveContainer } from '../presentation/common/components/AdaptiveContainer';
import { A11yButton, A11yImage, A11yListItem } from '../presentation/common/components/A11yComponents';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { ttsService, TTSListener, TTSProgress } from '../core/services/ai/TTSService';
import { novelPlayer, NovelChapter, PlayState, NovelConfig } from '../core/services/audio/NovelPlayerService';
import { BookInfo, Bookmark, Note } from '../core/models/CoreBookModel';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { ReaderSettings } from '../core/utils/prefs';
import { BookContentParser, ChapterInfo } from '../core/utils/BookContentParser';
import { themeManager, appTheme, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { PageStyles } from '../core/utils/PageStyles';
import { LazyDataSource } from '../common/datasource/LazyDataSource';
import { audioPlayerService, AudioPlayState, AudioPlayConfig, AudioPlayProgress } from '../core/services/audio/AudioPlayerService';
import { aiService, TaskType, LanguageCode } from '../core/services/ai/AIService';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

  private win: window.Window | null = null;
  private bookInfo: BookInfo | null = null;
  @State private context: common.Context | null = null;
  private ttsListener: TTSListener | null = null;

  // LazyForEach 閺佺増宓佸┃?
  private chapterDataSource: LazyDataSource<ChapterInfo> = new LazyDataSource<ChapterInfo>((item: ChapterInfo, index: number) => item.title + index);

  aboutToAppear() {
    try {
      this.context = this.getUIContext().getHostContext() as common.Context;
      this.initData();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      logger.error('Reader page init failed:', message);
      this.isLoading = false;
    }
  }

  private async initData(): Promise<void> {
    // 鍒濆鍖栦富棰樺拰瀛椾綋缂╂斁
    await fontScaleManager.init(this.context as common.Context);
    await layoutHelper.init(this.context as common.Context);
    this.screenInfo = layoutHelper.getScreenInfo();
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();

    // 鑾峰彇璺敱鍙傛�?
    const params = this.getUIContext().getRouter()?.getParams() as EnhancedReaderParams;
    if (params) {
      this.bookTitle = params.title || '涔︾睄璇︽儏';
      this.bookPath = params.path || '';
      this.bookId = params.bookId || '';
      this.currentChapterIndex = params.chapterIndex ? parseInt(params.chapterIndex) : 0;
    }

    // 鍒濆鍖朤TS
    await ttsService.init(this.context as common.Context);

    // 璁剧�?TTS 鐩戝惉鍣紙淇濈暀鍩烘湰TTS鐢ㄤ簬绠€鍗曟湕璇伙�?
    this.ttsListener = {
      onStart: () => { this.isTTSPlaying = true; },
      onComplete: () => { this.isTTSPlaying = false; },
      onError: (error: string) => {
        this.isTTSPlaying = false;
        logger.error('TTS Error:', error);
      },
      onProgress: (progress: TTSProgress) => { /* 楂樹寒褰撳墠鏈楄鐨勬枃�?*/ }
    };
    ttsService.setListener(this.ttsListener);

    // 璁剧疆NovelPlayer TTS鐩戝惉锛堢敤浜庣珷鑺傜骇鍒嗛〉鏈楄�?
    novelPlayer.addTTSListener((state: string) => {
      this.isTTSPlaying = state === 'playing';
    });
    novelPlayer.addPageChangeListener((index: number) => {
      this.ttsPageIndex = index;
    });

    // 璁剧疆闊抽鎾斁鐩戝惉锛堣儗鏅煶涔愶�?
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
        logger.error('[Reader] Audio error:', error);
      },
      onCompleted: (): void => {
        this.isAudioPlaying = false;
      }
    });

    // 鍒濆鍖朅I鏈嶅�?
    aiService.init();

    // 鍔犺浇涔︾睄鍐呭�?
    await this.loadBookContent();

    // 鍔犺浇鐢ㄦ埛璁剧�?
    this.loadUserSettings();

    // 绐楀彛鎺у�?
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
      logger.error('Window setup failed:', message);
    }
  }

  aboutToDisappear() {
    // 淇濆瓨闃呰杩涘�?
    this.saveReadingProgress();

    // 鍋滄�?TTS
    if (this.isTTSPlaying) {
      ttsService.stop();
    }
    if (novelPlayer.getPlayState() !== PlayState.STOPPED) {
      novelPlayer.stopPlaying();
    }
    // 涓嶈�?release 鍏ㄥ眬鍗曚緥璧勬簮锛屼細褰卞搷鍏朵粬椤甸�?
  }

  private async loadBookContent(): Promise<void> {
    try {
      this.isLoading = true;
      
      // ?BookViewModel 鑾峰彇涔︾睄淇℃�?
      if (this.bookId) {
        const book = bookViewModel.getBookById(this.bookId);
        this.bookInfo = book ? book : null;
      }
      
      if (this.bookInfo && this.bookInfo.filePath) {
        // 瑙ｆ瀽涔︾睄鍐呭�?
        const parseResult = await BookContentParser.parseFile(this.bookInfo.filePath);
        
        if (parseResult.success && parseResult.content) {
          this.content = parseResult.content;
          this.chapters = parseResult.chapters || [];
          this.chapterDataSource.setData(this.chapters);
          this.bookTitle = parseResult.metadata?.title || this.bookTitle;
          
          // 鍔犺浇涓婃闃呰杩涘害
          if (this.bookInfo.lastReadPosition !== undefined) {
            // lastReadPosition 鏄�?鍋忕Щ?闇€瑕佽浆鎹负绔犺妭绱㈠紩
            const lastReadPos: number = this.bookInfo.lastReadPosition;
            const positionChapterIndex: number = this.chapters.findIndex((chapter: ChapterInfo) =>
              chapter.startPosition <= lastReadPos &&
              chapter.endPosition > lastReadPos
            );
            if (positionChapterIndex >= 0) {
              this.currentChapterIndex = positionChapterIndex;
            }
          }
          
          // 鏄剧ず褰撳墠绔犺�?
          this.displayCurrentChapter();
        } else {
          this.content = '涔︾睄鍐呭瑙ｆ瀽澶辫触';
        }
      } else {
        // 濡傛灉娌℃湁鏂囦欢璺緞锛屽皾璇曚粠缂撳瓨鍔犺浇
        const cachedContent: string = await preferenceManager.getValue(`cached_content_${this.bookId}`, '');
        if (cachedContent) {
          this.content = cachedContent;
        } else {
          this.content = 'No content available';
        }
      }
      
      // 鍔犺浇涔︾鍜岀�?
      const allBookmarks: Record<string, Bookmark[]> = preferenceManager.getAllBookmarks();
      const bookmarksList = allBookmarks[this.bookId];
      this.bookmarks = bookmarksList ? bookmarksList.slice() : [];

      const allNotes: Record<string, Note[]> = preferenceManager.getNotes();
      const notesList = allNotes[this.bookId];
      this.notes = notesList ? notesList.slice() : [];
      
      this.isLoading = false;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      logger.error('Load book content failed:', message);
      this.content = '鍔犺浇澶辫触锛岃閲嶈瘯';
      this.isLoading = false;
    }
  }

  private displayCurrentChapter(): void {
    if (this.chapters.length > 0 && this.currentChapterIndex < this.chapters.length) {
      const chapter = this.chapters[this.currentChapterIndex];
      // 鎻愬彇绔犺妭鍐呭锛堢畝鍖栧疄鐜帮紝瀹為檯搴旇浠庡畬鏁村唴瀹逛腑鎻愬�?
      const chapterStart = chapter.startPosition || 0;
      const chapterEnd = chapter.endPosition || this.content.length;
      this.content = this.content.substring(chapterStart, chapterEnd);
    }
    
    // 鏇存柊杩涘害
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
        0 // 婊氬姩浣嶇疆
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
      title: `涔︾�?${this.bookmarks.length + 1}`,
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

  // ==================== NovelPlayer TTS鎺у埗 ====================

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

    // 鍚屾閰嶇疆
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

  // ==================== AudioPlayer 鑳屾櫙闊充箰鎺у埗 ====================

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
      logger.error('[Reader] Pick audio failed:', e instanceof Error ? e.message : String(e));
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

  // ==================== AI 鏅鸿兘闃呰 ====================

  private async requestAISummary(): Promise<void> {
    if (this.isAIProcessing) return;
    this.isAIProcessing = true;
    this.aiActiveTab = 0;
    this.showAIPanel = true;

    try {
      const chapterContent: string = this.content || '';
      if (chapterContent.length < 50) {
        this.aiSummaryText = '绔犺妭鍐呭杩囩煭锛屾棤娉曠敓鎴愭憳�?;
        this.isAIProcessing = false;
        return;
      }

      const result: string = await aiService.summarizeChapter(
        this.chapters.length > 0 ? this.chapters[this.currentChapterIndex].title : '褰撳墠绔犺妭',
        chapterContent.substring(0, 3000)
      );
      this.aiSummaryText = result;
    } catch (e) {
      this.aiSummaryText = 'AI鎽樿鐢熸垚澶辫�? ' + (e instanceof Error ? e.message : String(e));
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
        this.aiTranslationText = '鍐呭杩囩煭锛屾棤娉曠炕�?;
        this.isAIProcessing = false;
        return;
      }

      const result = await aiService.translate(
        chapterContent.substring(0, 2000),
        LanguageCode.ZH_CN
      );
      this.aiTranslationText = result.translatedText;
    } catch (e) {
      this.aiTranslationText = 'AI缈昏瘧澶辫触: ' + (e instanceof Error ? e.message : String(e));
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
      // 鍔犺浇鎸囩ず�?
      if (this.isLoading) {
        Column({ space: PageStyles.spacing('md') }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(PageStyles.themeColor('primary'))
            .animation({ duration: 1000, curve: Curve.EaseInOut, iterations: -1 })

          Text('鍔犺浇锟?..')
            .fontSize(PageStyles.fontSize('md'))
            .fontColor(PageStyles.textColor(this.isDarkMode, 'secondary'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(PageStyles.bgColor(this.isDarkMode, 'page'))
        .animation(PageStyles.animation('normal'))
      }

      // 澶栧眰浣跨敤鑷€傚簲瀹瑰�?
      AdaptiveContainer({
        sidePanel: () => { this.buildSidePanel(); },
        content: () => { this.buildMainContent(); }
      })
      // 鐐瑰嚮灞忓箷鍒囨崲鑿滃崟鏄剧�?(娌夋蹈寮忎綋�?
      .onClick(() => {
        this.isMenuVisible = !this.isMenuVisible;
      })
      // 鐩戝惉鏂偣鍙樺�?
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.currentBreakpoint = Number(newValue.width) > 600 ? 'md' : 'sm';
        // 鏇存柊灞忓箷淇℃�?
        if (this.context) {
          layoutHelper.updateScreenInfo().then(() => {
            this.screenInfo = layoutHelper.getScreenInfo();
          });
        }
      })

      // TTS鎺у埗闈㈡澘锛堟诞灞傦�?
      if (this.showTTSPanel) {
        this.TTSControlPanel()
      }

      // 闊抽鎾斁闈㈡澘锛堟诞灞傦�?
      if (this.showAudioPanel) {
        this.AudioPlayerPanel()
      }

      // AI闃呰闈㈡澘锛堟诞灞傦級
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
    // 姝ｆ枃鍖哄煙
    Column() {
      // 椤堕儴鏍囬�?浠呭湪鑿滃崟鏄剧ず鏃舵樉绀猴紝鎴栧钩鏉垮父�?
      if (this.isMenuVisible || this.currentBreakpoint !== 'sm') {
        this.buildTopBar()
      }

      // 鏍稿績鏂囨湰鏄剧ず锟?
      Scroll() {
        Column() {
          // 绔犺妭鏍囬
          if (this.chapters.length > 0 && this.currentChapterIndex < this.chapters.length) {
            Text(this.chapters[this.currentChapterIndex].title)
              .fontSize(this.fontSize + 4)
              .fontWeight(FontWeight.Bold)
              .fontColor(PageStyles.textColor(this.isDarkMode, 'primary'))
              .margin({ bottom: PageStyles.spacing('lg') })
          }

          // 姝ｆ枃鍐呭
          Text(this.content || '鍔犺浇锟?..')
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
            // 鏃犻殰纰嶏細闀挎寜鏀寔閫夎�?鏈楄�?
            .accessibilityText(`姝ｅ湪闃呰${this.bookTitle}锛岄暱鎸夊彲閫夋嫨鏂囨湰`)
            .gesture(
              LongPressGesture({ repeat: false })
                .onAction(() => {
                  // TODO: 瀹炵幇鏂囨湰閫夋�?
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

      // 搴曢儴鎺у埗锟?浠呰彍鍗曟樉绀烘椂)
      if (this.isMenuVisible) {
        this.buildBottomBar()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildSidePanel() {
    // 渚ц竟鏍忥細鐩綍/涔︾�?绗旇�?
    Tabs() {
      TabContent() {
        this.buildChapterList()
      }
      .tabBar('鐩�?)

      TabContent() {
        this.buildSidePanel()
      }
      .tabBar('Marks')

      TabContent() {
        this.buildNoteList()
      }
      .tabBar('绗旇�?)
    }
    .width('100%')
    .height('100%')
    .padding(Spacing.lg)
  }

  @Builder
  buildChapterList() {
    Column({ space: 16 }) {
      // 渚ц竟鏍忓�?
      Row() {
        Text('鐩�?)
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
              .padding(Spacing.lg)
              .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFF')
              .borderRadius(BorderRadius.sm)
              .onClick(() => {
                // 璺宠浆鍒颁功绛句�?
                this.isMenuVisible = false;
              })
            }
          }, (bookmark: Bookmark) => bookmark.id)
        }
        .layoutWeight(1)
      } else {
        Text('鏆傛棤涔︾')
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
        Text('绗旇�?)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFF' : '#000')
          .layoutWeight(1)
        A11yButton({
          text: '�?,
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
              .padding(Spacing.lg)
              .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFF')
              .borderRadius(BorderRadius.sm)
            }
          }, (note: Note) => note.id)
        }
        .layoutWeight(1)
      } else {
        Text('鏆傛棤绗旇')
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
            goBack();
          } catch (e) {
            logger.error('EnhancedReaderPage back failed:', e instanceof Error ? e.message : String(e));
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

      // 娣诲姞涔︾鎸夐�?
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
      // 杩涘害鏉′笌缈婚�?
      Row({ space: 16 }) {
        A11yButton({
          text: '涓婁竴锟?,
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
          text: '涓嬩竴锟?,
          btnType: 'secondary',
          onClickCallback: () => this.nextChapter()
        })
      }
      .width('100%')

      // 璁剧疆鎸夐挳?
      Row({ space: 24 }) {
        // 瀛椾綋澶у皬璋冭妭
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

        // TTS 鏈楄鎸夐挳锛堜娇鐢∟ovelPlayer鍒嗛〉鏈楄�?
        A11yButton({
          text: this.isTTSPlaying ? '�?鍋滄�? : '馃攰 鏈楄�?,
          onClickCallback: () => this.toggleNovelTTS()
        })

        // 澶滈棿妯″紡鍒囨�?
        A11yButton({
          text: this.isDarkMode ? '鈽€?鏃ラ�? : 'moon_fill 澶滈�?,
          onClickCallback: () => {
            this.isDarkMode = !this.isDarkMode;
            preferenceManager.setReadSettings({
              fontSize: this.fontSize,
              lineHeight: this.lineHeight,
              isDarkMode: this.isDarkMode
            });
          }
        })

        // 鑳屾櫙闊充箰
        A11yButton({
          text: this.isAudioPlaying ? '馃幍 鏆傚�? : '馃幍 闊充�?,
          onClickCallback: () => {
            if (this.showAudioPanel) {
              this.showAudioPanel = !this.showAudioPanel;
            } else {
              this.pickAndPlayAudio();
            }
          }
        })

        // AI 闃呰�?
        A11yButton({
          text: 'AI 闃呰�?,
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
    .padding(Spacing.xxl)
    .width('100%')
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  TTSControlPanel() {
    Column() {
      // 鍗婇€忔槑鑳屾櫙閬�?
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showTTSPanel = false)

      // TTS鎺у埗闈㈡�?
      Column({ space: 12 }) {
        // 杩涘害淇℃伅
        Row({ space: 8 }) {
          Text('鏈楄锟?)
            .fontSize(13)
            .fontColor(this.isDarkMode ? '#CCCCCC' : '#666666')

          Text(this.chapters.length > 0 ? this.chapters[this.currentChapterIndex].title : '')
            .fontSize(13)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 鍏抽棴鎸夐挳
          Text('�?)
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.stopNovelTTS())
        }
        .width('100%')

        // 杩涘害锟?
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

        // 鎺у埗鎸夐挳锟?
        Row({ space: 24 }) {
          // 涓婁竴锟?
          Column() {
            Text('�?)
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(BorderRadius.xl)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.onTTSPreviousPage())

          // 閫熷害锟?
          Column() {
            Text('�?)
              .fontSize(20)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(36)
          .height(36)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.changeTTSSpeed(-0.25))

          // 鎾�?鏆傚�?
          Column() {
            Text(novelPlayer.getPlayState() === PlayState.PAUSED ? '�? : '�?)
              .fontSize(28)
              .fontColor('#FFFFFF')
          }
          .width(56)
          .height(56)
          .backgroundColor('#007DFF')
          .borderRadius(BorderRadius.xxl)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.toggleNovelTTS())

          // 閫熷害锟?
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

          // 涓嬩竴锟?
          Column() {
            Text('�?)
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(BorderRadius.xl)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.onTTSNextPage())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 閫熷害鏄剧ず
        Text('璇�? ' + this.ttsSpeed.toFixed(2) + 'x')
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
      // 鍗婇€忔槑鑳屾櫙閬�?
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showAudioPanel = false)

      // 闊抽鎺у埗闈㈡澘
      Column({ space: 12 }) {
        // 鏍囬锟?
        Row({ space: 8 }) {
          Text('馃幍 鑳屾櫙闊充箰')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')

          Text(this.audioFileName)
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('�?)
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.stopAudio())
        }
        .width('100%')

        // 杩涘害锟?
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

        // 鎺у埗鎸夐�?
        Row({ space: 32 }) {
          // 鍋滄�?
          Column() {
            Text('�?)
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(BorderRadius.xl)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.stopAudio())

          // 鎾�?鏆傚�?
          Column() {
            Text(this.isAudioPlaying ? '�? : '�?)
              .fontSize(28)
              .fontColor('#FFFFFF')
          }
          .width(56)
          .height(56)
          .backgroundColor('#007DFF')
          .borderRadius(BorderRadius.xxl)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.toggleAudioPlayPause())

          // 閫夋嫨鏂囦欢
          Column() {
            Text('馃搨')
              .fontSize(22)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
          }
          .width(48)
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(BorderRadius.xl)
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
      // 鍗婇€忔槑鑳屾櫙閬�?
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.closeAIPanel())

      // AI 闈㈡�?
      Column({ space: 12 }) {
        // 鏍囬锟?
        Row({ space: 8 }) {
          Text('AI 闃呰鍔╂墜')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')

          Blank()

          Text('�?)
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => this.closeAIPanel())
        }
        .width('100%')

        // Tab 鍒囨�?
        Row({ space: 12 }) {
          // 鎽樿鎸夐挳
          Text('馃摑 鎽樿�?)
            .fontSize(12)
            .fontColor(this.aiActiveTab === 0 ? '#FFFFFF' : this.isDarkMode ? '#AAAAAA' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.aiActiveTab === 0 ? '#007DFF' : this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .borderRadius(BorderRadius.lg)
            .onClick(() => {
              this.aiActiveTab = 0;
              if (!this.aiSummaryText) {
                this.requestAISummary();
              }
            })

          // 缈昏瘧鎸夐挳
          Text('馃寪 缈昏�?)
            .fontSize(12)
            .fontColor(this.aiActiveTab === 1 ? '#FFFFFF' : this.isDarkMode ? '#AAAAAA' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.aiActiveTab === 1 ? '#007DFF' : this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
            .borderRadius(BorderRadius.lg)
            .onClick(() => {
              this.aiActiveTab = 1;
              if (!this.aiTranslationText) {
                this.requestAITranslation();
              }
            })
        }
        .width('100%')

        // 鍐呭锟?
        Scroll() {
          if (this.isAIProcessing) {
            Column({ space: 12 }) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color('#007DFF')

              Text('AI 澶勭悊锟?..')
                .fontSize(13)
                .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
            }
            .width('100%')
            .padding(40)
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 12 }) {
              // 鎽樿鍐呭
              if (this.aiActiveTab === 0) {
                Text(this.aiSummaryText || '鐐瑰嚮鎽樿鎸夐挳鐢熸垚鍐呭鎽樿')
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
                  .lineHeight(20)
              } else {
                Text(this.aiTranslationText || '鐐瑰嚮缈昏瘧鎸夐挳缈昏瘧褰撳墠绔犺妭')
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

// 棰勮缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮锟?
@Preview
@Component
struct EnhancedReaderPagePreview {
  build() {
    Column() {
      Text('澧炲己闃呰�?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      EnhancedReaderPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('澧炲己闃呰�?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      EnhancedReaderPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}