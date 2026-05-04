import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
/**
 * 婕�敾闃呰�椤甸潰 - v6.0
 * Comic Reader Page - Full Featured Comic Reader
 */

import { comicReaderService as comicReader, ComicPage, ComicInfo, ComicReadMode, ComicScaleMode } from '../core/services/reader/ComicReaderService';
import { ComicReaderViewModel, comicReaderViewModel } from '../viewmodels/ComicReaderViewModel';
import { uiDesignKitService as uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../core/services/reader/UIDesignKitService';
import { router, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

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
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

    // 鑾峰彇鍙傛暟
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

  /**
   * 鍔犺浇婕�敾
   */
  async loadComic(): Promise<void> {
    this.comicVM.isLoading = true;

    try {
      const info = await comicReader.loadComic(this.bookPath);

      if (info) {
        this.comicInfo = info;
        this.comicVM.totalPages = info.totalPages;
        this.comicVM.currentPage = 0;

        // 鏍规嵁璁惧�璁剧疆闃呰�妯″紡
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

  /**
   * 鏇存柊鍙岄〉鏄剧ず
   */
  updateDoublePages(): void {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE) {
      this.doublePages = comicReader.getDoublePages();
      this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    }
  }

  /**
   * 涓嬩竴)
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
   * 涓婁竴)
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
   * 鏇存柊椤甸潰锟?
   */
  updatePageState(): void {
    this.comicVM.currentPage = comicReader.getCurrentPageIndex();
    this.updateDoublePages();
  }

  /**
   * 鍒囨崲灞忓箷鏂瑰悜
   */
  async toggleOrientation(): Promise<void> {
    try {
      // TODO: Use window.setPreferredOrientation if available
      // For now, just toggle the flag
      this.isLandscape = !this.isLandscape;
      logger.info('[ComicReaderPage] Orientation toggled to:', this.isLandscape ? 'landscape' : 'portrait');

      // 鏍规嵁灞忓箷鏂瑰悜璋冩暣闃呰�妯″紡
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

  /**
   * 鍒囨崲宸ュ叿鏍忔樉)
   */
  toggleToolbar(): void {
    this.showToolbar = !this.showToolbar;
    this.showSettings = false;
  }

  build() {
    Stack() {
      // 涓诲唴瀹瑰尯)
      Column() {
        // 椤堕儴宸ュ叿)
        if (this.showToolbar) {
          this.buildTopToolbar()
        }

        // 婕�敾鍐呭�)
        this.buildComicContent()

        // 搴曢儴鎺у埗)
        if (this.showToolbar) {
          this.buildBottomBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#000000', '#000000'))

      // 璁剧疆闈㈡澘
      if (this.showSettings) {
        this.buildSettingsPanel()
      }

      // 鍔犺浇鎸囩ず)
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
   * 鏋勫缓椤堕儴宸ュ叿)
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
        .borderRadius(BorderRadius.xl)
        .onClick(() => goBack())

      // 鏍囬�
      Text(this.comicInfo?.title || '婕�敾闃呰�')
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
        .borderRadius(BorderRadius.xl)
        .margin({ right: 8 })
        .onClick(() => this.toggleOrientation())

      // 璁剧疆鎸夐挳
      Button('gearshape')
        .width(40)
        .height(40)
        .backgroundColor('rgba(0,0,0,0.5)')
        .fontColor('#FFFFFF')
        .fontSize(18)
        .borderRadius(BorderRadius.xl)
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
   * 鏋勫缓婕�敾鍐呭�)
   */
  @Builder
  buildComicContent() {
    if (this.readMode === ComicReadMode.DOUBLE_PAGE && this.isTablet && this.doublePages.length >= 2) {
      // 双页模式平锟?
      Row() {
        // 页
        this.buildComicPage(this.doublePages[0])

        Divider()
          .vertical(true)
          .color('#333333')
          .strokeWidth(1)

        // 页
        this.buildComicPage(this.doublePages[1])
      }
      .layoutWeight(1)
      .width('100%')
    } else {
      // 页模式
      this.buildComicPage(this.comicVM.currentPage >= 0 && this.comicVM.currentPage < this.comicVM.totalPages ?
        comicReader.getCurrentPage() : null)
    }
  }

  /**
   * 鏋勫缓鍗曢〉婕�敾
   */
  @Builder
  buildComicPage(page: ComicPage | null) {
    if (page && page.imageUri) {
      Stack() {
        Image(page.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)

        // 椤电爜鏄剧ず
        if (comicReader.getConfig().showPageNumber) {
          Text((this.comicVM.currentPage + 1) + ' / ' + this.comicVM.totalPages)
            .fontSize(FontSize.SM)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(BorderRadius.md)
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
   * 鏋勫缓搴曢儴鎺у埗)
   */
  @Builder
  buildBottomBar() {
    Column({ space: 12 }) {
      // 杩涘害)
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

      // 鎺у埗鎸夐挳
      Row({ space: 16 }) {
        Button('Prev')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.2)')
          .fontColor('#FFFFFF')
          .fontSize(FontSize.SM)
          .borderRadius(BorderRadius.xl)
          .onClick(() => this.previousPage())

        Button('Next')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('rgba(0,125,255,0.8)')
          .fontColor('#FFFFFF')
          .fontSize(FontSize.SM)
          .borderRadius(BorderRadius.xl)
          .onClick(() => this.nextPage())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
    .backgroundColor('rgba(0,0,0,0.7)')
  }

  /**
   * 鏋勫缓璁剧疆闈㈡澘
   */
  @Builder
  buildSettingsPanel() {
    Column() {
      // 闈㈡澘鏍囬�
      Row() {
        Text('闃呰�璁剧疆')
          .fontSize(FontSize.H4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Button('锟?)
          .width(32)
          .height(32)
          .fontSize(FontSize.LG)
          .onClick(() => this.showSettings = false)
      }
      .width('100%')

      // 闃呰�妯″紡
      Column({ space: 12 }) {
        Text('闃呰�妯″紡')
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.textPrimary)

        Row({ space: 8 }) {
          Button('鍗曢〉')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.SINGLE_PAGE ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.SINGLE_PAGE ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(BorderRadius.lg)
            .onClick(async () => {
              this.readMode = ComicReadMode.SINGLE_PAGE;
              await comicReader.updateConfig({ readMode: this.readMode });
            })

          Button('鍙岄〉')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.DOUBLE_PAGE ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.DOUBLE_PAGE ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(BorderRadius.lg)
            .onClick(async () => {
              this.readMode = ComicReadMode.DOUBLE_PAGE;
              await comicReader.updateConfig({ readMode: this.readMode });
              this.updateDoublePages();
            })

          Button('闀挎潯')
            .height(32)
            .backgroundColor(this.readMode === ComicReadMode.WEBTOON ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.readMode === ComicReadMode.WEBTOON ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(BorderRadius.lg)
            .onClick(async () => {
              this.readMode = ComicReadMode.WEBTOON;
              await comicReader.updateConfig({ readMode: this.readMode });
            })
        }
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 缂╂斁妯″紡
      Column({ space: 12 }) {
        Text('缂╂斁妯″紡')
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.textPrimary)

        Row({ space: 8 }) {
          Button('閫傚簲瀹藉害')
            .height(32)
            .backgroundColor(this.scaleMode === ComicScaleMode.FIT_WIDTH ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.scaleMode === ComicScaleMode.FIT_WIDTH ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(BorderRadius.lg)
            .onClick(async () => {
              this.scaleMode = ComicScaleMode.FIT_WIDTH;
              await comicReader.updateConfig({ scaleMode: this.scaleMode });
            })

          Button('閫傚簲楂樺害')
            .height(32)
            .backgroundColor(this.scaleMode === ComicScaleMode.FIT_HEIGHT ? this.theme.primary : this.theme.backgroundSecondary)
            .fontColor(this.scaleMode === ComicScaleMode.FIT_HEIGHT ? '#FFFFFF' : this.theme.textSecondary)
            .fontSize(FontSize.SM)
            .borderRadius(BorderRadius.lg)
            .onClick(async () => {
              this.scaleMode = ComicScaleMode.FIT_HEIGHT;
              await comicReader.updateConfig({ scaleMode: this.scaleMode });
            })
        }
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 鏄剧ず椤电爜寮€)
      Row() {
        Text('鏄剧ず椤电爜')
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

      // 棰勫姞杞借�)
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
    .padding(Spacing.xl)
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

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct ComicReaderPagePreview {
  build() {
    Column() {
      Text('婕�敾闃呰�锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ComicReaderPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('婕�敾闃呰�锟?- 娣辫壊妯″紡')
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




