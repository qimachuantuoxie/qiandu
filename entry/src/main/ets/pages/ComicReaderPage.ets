/**
 * 漫画阅读页面 - v6.0
 * Comic Reader Page - Full Featured Comic Reader
 */

import { comicReaderService as comicReader, ComicPage, ComicInfo, ComicReadMode, ComicScaleMode } from '../services/reader/ComicReaderService';
import { ComicReaderViewModel, comicReaderViewModel } from '../viewmodels/ComicReaderViewModel';
import { uiDesignKitService as uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../services/reader/UIDesignKitService';
import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DeviceUtils } from '../utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

@Entry
@Component
struct ComicReaderPage {
  @State isDarkMode: boolean = false;
  @State comicInfo: ComicInfo | null = null;
  @State showSettings: boolean = false;
  @State showToolbar: boolean = true;
  @State isLandscape: boolean = false;
  @State isTablet: boolean = false;
  @State readMode: ComicReadMode = ComicReadMode.SINGLE_PAGE;
  @State scaleMode: ComicScaleMode = ComicScaleMode.FIT_WIDTH;
  @State doublePages: [ComicPage | null, ComicPage | null] = [null, null];
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  comicVM: ComicReaderViewModel = comicReaderViewModel;

  private theme: ThemeColors = LIGHT_THEME;
  private bookId: string = '';
  private bookPath: string = '';

  @State private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.initAsyncData();
  }

  private initData(): void {
    this.isDarkMode = appTheme.isDarkMode();
    this.theme = uiDesignKit.getThemeColors();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet();
    this.isLandscape = DeviceUtils.isLandscape();
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    DeviceUtils.init();

    // 获取参数
    const params = router.getParams() as Record<string, string>;
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

  /**
   * 加载漫画
   */
  async loadComic(): Promise<void> {
    this.comicVM.isLoading = true;

    try {
      const info = await comicReader.loadComic(this.bookPath);

      if (info) {
        this.comicInfo = info;
        this.comicVM.totalPages = info.totalPages;
        this.comicVM.currentPage = 0;

        // 根据设备设置阅读模式
        if (this.isTablet && this.isLandscape) {
          this.readMode = ComicReadMode.DOUBLE_PAGE;
          await comicReader.updateConfig({ readMode: this.readMode });
          this.updateDoublePages();
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[ComicReaderPage] Load comic failed:', message);
    } finally {
      this.comicVM.isLoading = false;
    }
  }

  /**
   * 更新双页显示
   */
  updateDoublePages(): void {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      this.doublePages = comicReader.getDoublePages();
      this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    }
  }

  /**
   * 下一)
   */
  async nextPage(): Promise<void> {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      await comicReader.goToPage(this.comicVM.currentPage + 2);
    } else {
      await comicReader.nextPage();
    }
    this.updatePageState();
  }

  /**
   * 上一)
   */
  async previousPage(): Promise<void> {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      await comicReader.goToPage(this.comicVM.currentPage - 2);
    } else {
      await comicReader.previousPage();
    }
    this.updatePageState();
  }

  /**
   * 更新页面状)
   */
  updatePageState(): void {
    this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    this.updateDoublePages();
  }

  /**
   * 切换屏幕方向
   */
  async toggleOrientation(): Promise<void> {
    try {
      // TODO: Use window.setPreferredOrientation if available
      // For now, just toggle the flag
      this.isLandscape = !this.isLandscape;
      console.info('[ComicReaderPage] Orientation toggled to:', this.isLandscape ? 'landscape' : 'portrait');

      // 根据屏幕方向调整阅读模式
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
      console.error('[ComicReaderPage] Toggle orientation failed:', message);
    }
  }

  /**
   * 切换工具栏显)
   */
  toggleToolbar(): void {
    this.showToolbar = !this.showToolbar;
    this.showSettings = false;
  }

  build() {
    Stack() {
      // 主内容区)
      Column() {
        // 顶部工具)
        if (this.showToolbar) {
          this.buildTopToolbar()
        }

        // 漫画内容)
        this.buildComicContent()

        // 底部控制)
        if (this.showToolbar) {
          this.buildBottomBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#000000', '#000000'))

      // 设置面板
      if (this.showSettings) {
        this.buildSettingsPanel()
      }

      // 加载指示)
      if (this.comicVM.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#FFFFFF')

          Text(tr('loading'))
            .fontSize(FontSize.MD)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => this.toggleToolbar())
  }

  /**
   * 构建顶部工具)
   */
  @Builder
  buildTopToolbar() {
    Row() {
      Button('<')
        .width(40)
        .height(40)
        .backgroundColor('rgba(0,0,0,0.5)')
        .fontColor('#FFFFFF')
        .fontSize(20)
        .borderRadius(20)
        .onClick(() => router.back())

      // 标题
      Text(this.comicInfo?.title || '漫画阅读')
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
        .margin({ left: 12 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button(this.isLandscape ? 'V' : 'H')
        .width(40)
        .height(40)
        .backgroundColor('rgba(0,0,0,0.5)')
        .fontColor('#FFFFFF')
        .fontSize(18)
        .borderRadius(20)
        .margin({ right: 8 })
        .onClick(() => this.toggleOrientation())

      // 设置按钮
      Button('⚙️')
        .width(40)
        .height(40)
        .backgroundColor('rgba(0,0,0,0.5)')
        .fontColor('#FFFFFF')
        .fontSize(18)
        .borderRadius(20)
        .onClick(() => {
          this.showSettings = !this.showSettings;
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(0,0,0,0.7)')
  }

  /**
   * 构建漫画内容)
   */
  @Builder
  buildComicContent() {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE && this.isTablet && this.doublePages.length >= 2) {
      // ˫ҳģʽƽ壩
      Row() {
        // ҳ
        this.buildComicPage(this.doublePages[0])

        Divider()
          .vertical(true)
          .color('#333333')
          .strokeWidth(1)

        // ҳ
        this.buildComicPage(this.doublePages[1])
      }
      .layoutWeight(1)
      .width('100%')
    } else {
      // ҳģʽ
      this.buildComicPage(this.comicVM.currentPage >= 0 && this.comicVM.currentPage < this.comicVM.totalPages ?
        comicReader.getCurrentPage() : null)
    }
  }

  /**
   * 构建单页漫画
   */
  @Builder
  buildComicPage(page: ComicPage | null) {
    if (page && page.imageUri) {
      Stack() {
        Image(page.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)

        // 页码显示
        if (comicReader.getConfig().showPageNumber) {
          Text((this.comicVM.currentPage + 1) + ' / ' + this.comicVM.totalPages)
            .fontSize(FontSize.SM)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(12)
            .position({ x: '50%', y: '90%' })
            .translate({ x: '-50%' })
        }
      }
      .layoutWeight(1)
      .onClick(() => this.toggleToolbar())
    } else {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#FFFFFF')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
  }

  /**
   * 构建底部控制)
   */
  @Builder
  buildBottomBar() {
    Column({ space: 12 }) {
      // 进度)
      Row() {
        Text((this.comicVM.currentPage + 1) + '')
          .fontSize(FontSize.XS)
          .fontColor('#FFFFFF')
          .width(30)

        Slider({
          value: this.comicVM.currentPage,
          min: 0,
          max: this.comicVM.totalPages - 1,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .selectedColor('#007DFF')
          .trackColor('#333333')
          .blockColor('#FFFFFF')
          .onChange((value: number) => {
            this.comicVM.goToPage(Math.round(value));
            comicReader.goToPage(Math.round(value));
            this.updatePageState();
          })

        Text(this.comicVM.totalPages + '')
          .fontSize(FontSize.XS)
          .fontColor('#FFFFFF')
          .width(30)
          .textAlign(TextAlign.End)
      }

      // 控制按钮
      Row({ space: 16 }) {
        Button('Prev')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.2)')
          .fontColor('#FFFFFF')
          .fontSize(FontSize.SM)
          .borderRadius(20)
          .onClick(() => this.previousPage())

        Button('Next')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('rgba(0,125,255,0.8)')
          .fontColor('#FFFFFF')
          .fontSize(FontSize.SM)
          .borderRadius(20)
          .onClick(() => this.nextPage())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
    .backgroundColor('rgba(0,0,0,0.7)')
  }

  /**
   * 构建设置面板
   */
  @Builder
  buildSettingsPanel() {
    Column() {
      // 面板标题
      Row() {
        Text('阅读设置')
          .fontSize(FontSize.H4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Button('✕')
          .width(32)
          .height(32)
          .fontSize(FontSize.LG)
          .onClick(() => this.showSettings = false)
      }
      .width('100%')

      // 阅读模式
      Column({ space: 12 }) {
        Text('阅读模式')
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.textPrimary)

        Row({ space: 8 }) {
          Button('单页')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.SINGLE_PAGE ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.SINGLE_PAGE ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(16)
            .onClick(async () => {
              this.readMode = ComicReadMode.SINGLE_PAGE;
              await comicReader.updateConfig({ readMode: this.readMode });
            })

          Button('双页')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.DOUBLE_PAGE ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.DOUBLE_PAGE ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(16)
            .onClick(async () => {
              this.readMode = ComicReadMode.DOUBLE_PAGE;
              await comicReader.updateConfig({ readMode: this.readMode });
              this.updateDoublePages();
            })

          Button('长条')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.WEBTOON ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.WEBTOON ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(16)
            .onClick(async () => {
              this.readMode = ComicReadMode.WEBTOON;
              await comicReader.updateConfig({ readMode: this.readMode });
            })
        }
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 缩放模式
      Column({ space: 12 }) {
        Text('缩放模式')
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.textPrimary)

        Row({ space: 8 }) {
          Button('适应宽度')
            .height(32)
            .backgroundColor(this.scaleMode === ComicScaleMode.FIT_WIDTH ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.scaleMode === ComicScaleMode.FIT_WIDTH ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(16)
            .onClick(async () => {
              this.scaleMode = ComicScaleMode.FIT_WIDTH;
              await comicReader.updateConfig({ scaleMode: this.scaleMode });
            })

          Button('适应高度')
            .height(32)
            .backgroundColor(this.scaleMode === ComicScaleMode.FIT_HEIGHT ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.scaleMode === ComicScaleMode.FIT_HEIGHT ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(16)
            .onClick(async () => {
              this.scaleMode = ComicScaleMode.FIT_HEIGHT;
              await comicReader.updateConfig({ scaleMode: this.scaleMode });
            })
        }
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 显示页码开)
      Row() {
        Text('显示页码')
          .fontSize(FontSize.MD)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: comicReader.getConfig().showPageNumber })
          .onChange(async (isOn: boolean) => {
            await comicReader.updateConfig({ showPageNumber: isOn });
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 预加载设)
      Row() {
        Text('Preload')
          .fontSize(FontSize.MD)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: comicReader.getConfig().enablePreload })
          .onChange(async (isOn: boolean) => {
            await comicReader.updateConfig({ enablePreload: isOn });
          })
      }
      .width('100%')
    }
    .width('90%')
    .padding(20)
    .backgroundColor(this.theme.background)
    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.XL))
    .shadow({
      radius: 20,
      color: 'rgba(0,0,0,0.3)',
      offsetX: 0,
      offsetY: 8
    })
    .position({ x: '50%', y: '50%' })
    .translate({ x: '-50%', y: '-50%' })
  }
}




