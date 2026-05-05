import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { coreSpeechService, SpeechProgress } from '../../../core/services/ai/CoreSpeechService';
import { BookInfo, Bookmark, Note } from '../../../core/models/CoreBookModel';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, appTheme, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { tr } from '../../../core/utils/LocalizationUtil';
import { BookContentParser, ChapterInfo } from '../../../core/utils/BookContentParser';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../../../common/utils/LayoutHelper';

interface EnhancedReaderParams {
  title?: string;
  path?: string;
  bookId?: string;
  chapterIndex?: string;
}

@Entry
@ComponentV2
struct EnhancedReaderPage {
  @Local bookTitle: string = '';
  @Local bookId: string = '';
  @Local bookPath: string = '';
  @Local content: string = '';
  @Local chapters: ChapterInfo[] = [];
  @Local currentChapterIndex: number = 0;
  @Local isMenuVisible: boolean = false;
  @Local isTTSPlaying: boolean = false;
  @Local fontSize: number = 18;
  @Local lineHeight: number = 1.6;
  @Local isDarkMode: boolean = false;
  @Local progress: number = 0;
  @Local bookmarks: Bookmark[] = [];
  @Local notes: Note[] = [];
  @Local showBookmarkDialog: boolean = false;
  @Local showNoteDialog: boolean = false;
  @Local selectedText: string = '';
  @Local isLoading: boolean = true;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local showTTSPanel: boolean = false;
  @Local screenInfo: ScreenInfo | null = null;

  private win: window.Window | null = null;
  private bookInfo: BookInfo | null = null;
  private context: common.Context | null = null;
  private coreSpeechListener: { onStart?: () => void; onComplete?: () => void; onError?: (error: string) => void; onPause?: () => void; onResume?: () => void; onProgress?: (progress: SpeechProgress) => void; } | null = null;

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
    await fontScaleManager.init(this.context as common.Context);
    await layoutHelper.init(this.context as common.Context);
    this.screenInfo = layoutHelper.getScreenInfo();
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();

    const params = this.getUIContext().getRouter()?.getParams() as EnhancedReaderParams;
    if (params) {
      this.bookTitle = params.title || '书籍详情';
      this.bookPath = params.path || '';
      this.bookId = params.bookId || '';
      this.currentChapterIndex = params.chapterIndex ? parseInt(params.chapterIndex) : 0;
    }

    await coreSpeechService.init(this.context as common.Context);

    this.coreSpeechListener = {
      onStart: () => { this.isTTSPlaying = true; },
      onComplete: () => { this.isTTSPlaying = false; },
      onError: (error: string) => {
        this.isTTSPlaying = false;
        logger.error('TTS Error:', error);
      }
    };
    coreSpeechService.setListener(this.coreSpeechListener);

    await this.loadBookContent();
    this.loadUserSettings();

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
    this.saveReadingProgress();
    if (this.isTTSPlaying) {
      coreSpeechService.stop();
    }
  }

  private async loadBookContent(): Promise<void> {
    try {
      this.isLoading = true;
      
      if (this.bookId) {
        this.bookInfo = bookViewModel.getBookById(this.bookId);
        if (this.bookInfo) {
          this.bookTitle = this.bookInfo.title;
          this.chapters = await BookContentParser.parseChapters(this.bookInfo.path);
          
          if (this.chapters.length > 0 && this.currentChapterIndex < this.chapters.length) {
            const chapter = this.chapters[this.currentChapterIndex];
            this.content = await BookContentParser.parseChapter(this.bookInfo.path, chapter);
          }
        }
      } else if (this.bookPath) {
        this.bookTitle = this.bookPath.split('/').pop() || '未知书籍';
        this.chapters = await BookContentParser.parseChapters(this.bookPath);
        
        if (this.chapters.length > 0) {
          const chapter = this.chapters[0];
          this.content = await BookContentParser.parseChapter(this.bookPath, chapter);
        }
      }

      this.progress = this.calculateProgress();
      this.bookmarks = this.bookId ? bookViewModel.getBookmarks(this.bookId) : [];
      this.notes = this.bookId ? bookViewModel.getNotes(this.bookId) : [];
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[EnhancedReaderPage] Load content failed:', message);
    } finally {
      this.isLoading = false;
    }
  }

  private loadUserSettings(): void {
    const settings = preferenceManager.getReaderSettings();
    this.fontSize = settings.fontSize || 18;
    this.lineHeight = settings.lineHeight || 1.6;
  }

  private saveReadingProgress(): void {
    if (this.bookId) {
      bookViewModel.updateReadingProgress(this.bookId, this.currentChapterIndex, this.progress);
    }
  }

  private calculateProgress(): number {
    if (this.chapters.length === 0) return 0;
    return Math.floor((this.currentChapterIndex + 1) / this.chapters.length * 100);
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  async previousChapter(): Promise<void> {
    if (this.currentChapterIndex > 0) {
      this.currentChapterIndex--;
      await this.loadCurrentChapter();
    }
  }

  async nextChapter(): Promise<void> {
    if (this.currentChapterIndex < this.chapters.length - 1) {
      this.currentChapterIndex++;
      await this.loadCurrentChapter();
    }
  }

  private async loadCurrentChapter(): Promise<void> {
    if (this.bookInfo && this.currentChapterIndex < this.chapters.length) {
      const chapter = this.chapters[this.currentChapterIndex];
      this.content = await BookContentParser.parseChapter(this.bookInfo.path, chapter);
      this.progress = this.calculateProgress();
    }
  }

  private toggleTTS(): void {
    if (this.isTTSPlaying) {
      coreSpeechService.stop();
    } else {
      coreSpeechService.speak(this.content);
    }
  }

  private addBookmark(): void {
    if (this.bookId) {
      const bookmark: Bookmark = {
        id: Date.now().toString(),
        bookId: this.bookId,
        pageNumber: this.currentChapterIndex,
        title: this.chapters[this.currentChapterIndex]?.title || '',
        createTime: Date.now(),
        note: ''
      };
      bookViewModel.addBookmark(this.bookId, bookmark);
      this.bookmarks = bookViewModel.getBookmarks(this.bookId);
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部工具栏
        if (this.isMenuVisible) {
          this.buildTopToolbar()
        }

        // 阅读内容区
        if (this.isLoading) {
          // 加载状态
          Column({ space: Spacing.lg }) {
            LoadingProgress()
              .width(50)
              .height(50)
              .color(this.currentColors.primary)
            
            Text('加载中...')
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.content) {
          // 文本内容
          Scroll() {
            Text(this.content)
              .fontSize(fontScaleManager.getScaledFontSize(this.fontSize))
              .lineHeight(this.lineHeight)
              .fontColor(this.tc('#1A1A1A', '#E5E5EA'))
              .padding(Spacing.xl)
              .textAlign(TextAlign.Justify)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .onClick(() => {
            this.isMenuVisible = !this.isMenuVisible;
          })
        } else {
          // 空状态
          Column({ space: Spacing.xl }) {
            SymbolGlyph($r('sys.symbol.book.open'))
              .fontSize(Size.iconXXXL * 1.5)
              .fontColor([this.tc('#D1D1D6', '#48484A')])
            
            Text('暂无内容')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontWeight(FontWeight.Medium)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }

        // 底部工具栏
        if (this.isMenuVisible) {
          this.buildBottomToolbar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#FFFFFF', '#1A1A1A'))

      // TTS面板
      if (this.showTTSPanel) {
        this.TTSPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#FFFFFF', '#1A1A1A'))
  }

  @Builder
  buildTopToolbar() {
    Row() {
      // 返回按钮
      Row() {
        SymbolGlyph($r('sys.symbol.chevron.left'))
          .fontSize(Size.iconLG)
          .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[EnhancedReaderPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      // 标题
      Text(this.bookTitle)
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: Spacing.md })

      // 书签按钮
      Row() {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.addBookmark();
      })
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  buildBottomToolbar() {
    Column() {
      // 章节信息
      Row() {
        Text(this.chapters[this.currentChapterIndex]?.title || '')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(`${this.progress}%`)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.sm })

      // 进度条
      Progress({ 
        value: this.currentChapterIndex + 1, 
        total: this.chapters.length, 
        type: ProgressType.Linear 
      })
        .width('100%')
        .height(4)
        .borderRadius(BorderRadius.xl)
        .color(this.currentColors.primary)
        .backgroundColor(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.1)'))

      // 控制按钮
      Row() {
        // 上一章
        Button() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconLG)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonLG)
        .height(Size.buttonLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.currentColors.primary)
        .enabled(this.currentChapterIndex > 0)
        .onClick(() => this.previousChapter())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Blank()

        // TTS按钮
        Button() {
          SymbolGlyph($r(this.isTTSPlaying ? 'sys.symbol.pause.fill' : 'sys.symbol.play.fill'))
            .fontSize(Size.iconXL)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonLG + Spacing.sm)
        .height(Size.buttonLG + Spacing.sm)
        .borderRadius(BorderRadius.full)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [this.currentColors.primary, this.currentColors.primary + 'CC']
        })
        .shadow({
          radius: 8,
          color: this.currentColors.primary + '40',
          offsetY: 4
        })
        .onClick(() => {
          this.toggleTTS();
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Blank()

        // 下一章
        Button() {
          SymbolGlyph($r('sys.symbol.chevron.right'))
            .fontSize(Size.iconLG)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonLG)
        .height(Size.buttonLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.currentColors.primary)
        .enabled(this.currentChapterIndex < this.chapters.length - 1)
        .onClick(() => this.nextChapter())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.lg })
    }
    .width('100%')
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('lg', this.isDarkMode))
  }

  @Builder
  TTSPanel() {
    Column() {
      // 头部
      Row() {
        Text('语音朗读')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)

        Row() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(Size.iconMD)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
        }
        .width(Size.buttonSM)
        .height(Size.buttonSM)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showTTSPanel = false;
        })
      }
      .width('100%')
      .padding(Spacing.lg)

      Divider()
        .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
        .strokeWidth(0.5)

      // TTS控制
      Column({ space: Spacing.xl }) {
        // 播放控制
        Row({ space: Spacing.xxl }) {
          Button() {
            SymbolGlyph($r('sys.symbol.backward.fill'))
              .fontSize(Size.iconXL)
              .fontColor(['#FFFFFF'])
          }
          .width(Size.buttonLG)
          .height(Size.buttonLG)
          .borderRadius(BorderRadius.full)
          .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))

          Button() {
            SymbolGlyph($r(this.isTTSPlaying ? 'sys.symbol.pause.circle.fill' : 'sys.symbol.play.circle.fill'))
              .fontSize(Size.iconXXXL)
              .fontColor([this.currentColors.primary])
          }
          .width(Size.buttonXL)
          .height(Size.buttonXL)
          .borderRadius(BorderRadius.full)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.toggleTTS())

          Button() {
            SymbolGlyph($r('sys.symbol.forward.fill'))
              .fontSize(Size.iconXL)
              .fontColor(['#FFFFFF'])
          }
          .width(Size.buttonLG)
          .height(Size.buttonLG)
          .borderRadius(BorderRadius.full)
          .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(Spacing.xl)
    }
    .width(this.screenInfo?.isTablet ? '40%' : '80%')
    .height('100%')
    .position({ bottom: 0 })
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .shadow(getShadow('xl', this.isDarkMode))
    .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
  }
}

// 预览组件
@Preview
@ComponentV2
struct EnhancedReaderPagePreview {
  build() {
    Column() {
      Text('增强阅读器 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      EnhancedReaderPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('增强阅读器 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      EnhancedReaderPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
