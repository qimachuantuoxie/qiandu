import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { comicReaderService as comicReader, ComicPage, ComicInfo, ComicReadMode, ComicScaleMode } from '../core/services/reader/ComicReaderService';
import { ComicReaderViewModel, comicReaderViewModel } from '../viewmodels/ComicReaderViewModel';
import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct ComicReaderPage {
  @Local isDarkMode: boolean = false;
  @Local comicInfo: ComicInfo | null = null;
  @Local showSettings: boolean = false;
  @Local showToolbar: boolean = true;
  @Local isLandscape: boolean = false;
  @Local isTablet: boolean = false;
  @Local readMode: ComicReadMode = ComicReadMode.SINGLE_PAGE;
  @Local scaleMode: ComicScaleMode = ComicScaleMode.FIT_WIDTH;
  @Local doublePages: [ComicPage | null, ComicPage | null] = [null, null];
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;
  
  comicVM: ComicReaderViewModel = comicReaderViewModel;
  private bookId: string = '';
  private bookPath: string = '';
  private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.initAsyncData();
  }

  private initData(): void {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet();
    this.isLandscape = DeviceUtils.isLandscape();
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

    const params = this.getUIContext().getRouter()?.getParams() as Record<string, string>;
    this.bookId = params?.bookId || '';
    this.bookPath = params?.bookPath || '';

    if (this.bookId) {
      await this.comicVM.init(this.bookId);
    }
    if (this.bookPath) {
      await this.loadComic();
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  async loadComic(): Promise<void> {
    this.comicVM.isLoading = true;

    try {
      const info = await comicReader.loadComic(this.bookPath);

      if (info) {
        this.comicInfo = info;
        this.comicVM.totalPages = info.totalPages;
        this.comicVM.currentPage = 0;

        if (this.isTablet && this.isLandscape) {
          this.readMode = ComicReadMode.DOUBLE_PAGE;
          await comicReader.updateConfig({ readMode: this.readMode });
          this.updateDoublePages();
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[ComicReaderPage] Load comic failed:', message);
    } finally {
      this.comicVM.isLoading = false;
    }
  }

  updateDoublePages(): void {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      this.doublePages = comicReader.getDoublePages();
      this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    }
  }

  async nextPage(): Promise<void> {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      await comicReader.goToPage(this.comicVM.currentPage + 2);
    } else {
      await comicReader.nextPage();
    }
    this.updatePageState();
  }

  async previousPage(): Promise<void> {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      await comicReader.goToPage(this.comicVM.currentPage - 2);
    } else {
      await comicReader.previousPage();
    }
    this.updatePageState();
  }

  updatePageState(): void {
    this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    this.updateDoublePages();
  }

  async toggleOrientation(): Promise<void> {
    try {
      this.isLandscape = !this.isLandscape;
      logger.info('[ComicReaderPage] Orientation toggled to:', this.isLandscape ? 'landscape' : 'portrait');

      if (this.isTablet) {
        if (this.isLandscape) {
          this.readMode = ComicReadMode.DOUBLE_PAGE;
        } else {
          this.readMode = ComicReadMode.SINGLE_PAGE;
        }
        await comicReader.updateConfig({ readMode: this.readMode });
        this.updateDoublePages();
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[ComicReaderPage] Toggle orientation failed:', message);
    }
  }

  toggleToolbar(): void {
    this.showToolbar = !this.showToolbar;
    this.showSettings = false;
  }

  build() {
    Stack() {
      Column() {
        // 顶部工具栏
        if (this.showToolbar) {
          this.buildTopToolbar()
        }

        // 漫画内容区
        Column() {
          if (this.comicVM.isLoading) {
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
          } else if (this.comicInfo) {
            // 漫画显示区
            this.ComicDisplayArea()
          } else {
            // 空状态
            Column({ space: Spacing.xl }) {
              SymbolGlyph($r('sys.symbol.photo'))
                .fontSize(Size.iconXXXL * 1.5)
                .fontColor([this.tc('#D1D1D6', '#48484A')])
              
              Text('暂无漫画内容')
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.bg('#000000', '#000000'))
        .onClick(() => this.toggleToolbar())

        // 底部进度条
        if (this.showToolbar && this.comicInfo) {
          this.buildBottomProgress()
        }
      }
      .width('100%')
      .height('100%')

      // 设置面板
      if (this.showSettings) {
        this.SettingsPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#000000', '#000000'))
  }

  @Builder
  buildTopToolbar() {
    Row() {
      // 返回按钮
      Row() {
        SymbolGlyph($r('sys.symbol.chevron.left'))
          .fontSize(Size.iconLG)
          .fontColor(['#FFFFFF'])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor('rgba(255,255,255,0.2)')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[ComicReaderPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      // 标题
      Text(this.comicInfo?.title || '漫画阅读')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: Spacing.md })

      // 设置按钮
      Row() {
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(Size.iconMD)
          .fontColor(['#FFFFFF'])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor('rgba(255,255,255,0.2)')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showSettings = !this.showSettings;
      })
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: ['rgba(0,0,0,0.7)', 'rgba(0,0,0,0)']
    })
    .position({ top: 0 })
    .zIndex(100)
  }

  @Builder
  ComicDisplayArea() {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      // 双页模式
      Row({ space: Spacing.xs }) {
        if (this.doublePages[0]) {
          Image(this.doublePages[0].imagePath)
            .width('50%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }
        if (this.doublePages[1]) {
          Image(this.doublePages[1].imagePath)
            .width('50%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }
      }
      .width('100%')
      .height('100%')
    } else {
      // 单页模式
      if (this.comicVM.currentPage < this.comicVM.totalPages) {
        Image(this.comicVM.pages[this.comicVM.currentPage]?.imagePath || '')
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      }
    }
  }

  @Builder
  buildBottomProgress() {
    Column() {
      // 进度信息
      Row() {
        Text(`${this.comicVM.currentPage + 1} / ${this.comicVM.totalPages}`)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor('#FFFFFF')
        
        Blank()

        Text(`${Math.floor((this.comicVM.currentPage + 1) / this.comicVM.totalPages * 100)}%`)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.sm })

      // 进度条
      Progress({ 
        value: this.comicVM.currentPage + 1, 
        total: this.comicVM.totalPages, 
        type: ProgressType.Linear 
      })
        .width('100%')
        .height(4)
        .borderRadius(BorderRadius.xl)
        .color(COMMON_COLORS.PRIMARY_BLUE)
        .backgroundColor('rgba(255,255,255,0.2)')

      // 翻页按钮
      Row() {
        // 上一页
        Button() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconXL)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonLG)
        .height(Size.buttonLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor('rgba(255,255,255,0.2)')
        .enabled(this.comicVM.currentPage > 0)
        .onClick(() => this.previousPage())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Blank()

        // 下一页
        Button() {
          SymbolGlyph($r('sys.symbol.chevron.right'))
            .fontSize(Size.iconXL)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonLG)
        .height(Size.buttonLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor('rgba(255,255,255,0.2)')
        .enabled(this.comicVM.currentPage < this.comicVM.totalPages - 1)
        .onClick(() => this.nextPage())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.lg })
    }
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: ['rgba(0,0,0,0.7)', 'rgba(0,0,0,0)']
    })
    .position({ bottom: 0 })
    .zIndex(100)
  }

  @Builder
  SettingsPanel() {
    Column() {
      // 头部
      Row() {
        Text('阅读设置')
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
          this.showSettings = false;
        })
      }
      .width('100%')
      .padding(Spacing.lg)

      Divider()
        .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
        .strokeWidth(0.5)

      // 设置选项
      Scroll() {
        Column({ space: Spacing.lg }) {
          // 阅读模式
          this.SettingSection('阅读模式', [
            { label: '单页模式', value: ComicReadMode.SINGLE_PAGE },
            { label: '双页模式', value: ComicReadMode.DOUBLE_PAGE }
          ], this.readMode, (value) => {
            this.readMode = value as ComicReadMode;
            comicReader.updateConfig({ readMode: this.readMode });
            this.updateDoublePages();
          })

          // 缩放模式
          this.SettingSection('缩放模式', [
            { label: '适应宽度', value: ComicScaleMode.FIT_WIDTH },
            { label: '适应高度', value: ComicScaleMode.FIT_HEIGHT },
            { label: '原始大小', value: ComicScaleMode.ORIGINAL }
          ], this.scaleMode, (value) => {
            this.scaleMode = value as ComicScaleMode;
            comicReader.updateConfig({ scaleMode: this.scaleMode });
          })
        }
        .width('100%')
        .padding(Spacing.lg)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width(this.isTablet ? '40%' : '80%')
    .height('100%')
    .position({ right: 0 })
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .shadow(getShadow('xl', this.isDarkMode))
    .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
  }

  @Builder
  SettingSection(title: string, options: Array<{label: string, value: any}>, currentValue: any, onSelect: (value: any) => void) {
    Column({ space: Spacing.md }) {
      Text(title)
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(options, (option) => {
          Text(option.label)
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .padding({ 
              left: Spacing.md, 
              right: Spacing.md, 
              top: Spacing.sm, 
              bottom: Spacing.sm 
            })
            .backgroundColor(currentValue === option.value ? 
              this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
            .fontColor(currentValue === option.value ? 
              '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => onSelect(option.value))
            .stateStyles({
              pressed: { .scale({ x: 0.95, y: 0.95 }) },
              normal: { .scale({ x: 1, y: 1 }) }
            })
            .margin({ right: Spacing.sm, bottom: Spacing.sm })
        }, (option) => option.label)
      }
      .width('100%')
    }
    .width('100%')
  }
}

// 预览组件
@Preview
@ComponentV2
struct ComicReaderPagePreview {
  build() {
    Column() {
      Text('漫画阅读器 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ComicReaderPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('漫画阅读器 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ComicReaderPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
