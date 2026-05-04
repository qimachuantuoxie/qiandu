import { navigateTo } from '../../../common/utils/NavigationHelper';
/**
 * 涔︽簮甯傚満椤甸潰 - 楦胯挋锟?V2
 * 浣跨敤 ViewModel 妯″紡绠＄悊鐘讹拷?
 */

import { SourceMarketItem, SourceMarketCategory, SourceMarketSort } from '../core/services/book/LegadoSourceMarket';
import { sourceMarketViewModel, SourceMarketViewModel } from '../viewmodels/SourceMarketViewModel';
import { uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../core/services/reader/UIDesignKitService';
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { BackButton } from '../components/common/BackButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct SourceMarketPage {
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  vm: SourceMarketViewModel = sourceMarketViewModel;

  private theme: ThemeColors = LIGHT_THEME;
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
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();

    await this.vm.init(this.context);
  }

  build() {
    Column() {
      // 椤堕儴瀵艰埅锟?
      Row() {
        BackButton({ isDarkMode: this.isDarkMode, colors: this.theme.textPrimary })

        Text('涔︽簮甯傚満')
          .fontSize(FontSize.H3)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)
          .margin({ left: 8 })

        // 鎼滅储鎸夐挳
        Text('馃攳')
          .fontSize(20)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => this.vm.toggleSearch())

        // URL瀵煎叆鎸夐挳
        Text('馃敆')
          .fontSize(20)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => this.vm.showUrlInputDialog())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.theme.background)
      .shadow({
        radius: 4,
        color: this.theme.shadowDark,
        offsetX: 0,
        offsetY: 2
      })

      // 鎼滅储锟?
      if (this.vm.showSearch) {
        Row() {
          TextInput({ placeholder: '鎼滅储涔︽簮...', text: this.vm.searchKeyword })
            .placeholderColor(this.theme.textTertiary)
            .backgroundColor(this.theme.backgroundSecondary)
            .layoutWeight(1)
            .height(40)
            .onChange((value: string) => {
              this.vm.searchKeyword = value;
            })
            .onSubmit(() => {
              this.vm.onSearch(this.vm.searchKeyword);
            })

          Button('鎼滅储')
            .width(70)
            .height(40)
            .backgroundColor(this.theme.primary)
            .fontColor('#FFFFFF')
            .fontSize(FontSize.SM)
            .margin({ left: 8 })
            .onClick(() => {
              this.vm.onSearch(this.vm.searchKeyword);
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.theme.background)
      }

      // 鍒嗙被鏍囩�
      Scroll() {
        Row({ space: SpacingSize.MD }) {
          ForEach(this.vm.ALL_CATEGORIES, (category: SourceMarketCategory) => {
            Button(this.vm.getCategoryName(category))
              .height(32)
              .backgroundColor(
                this.vm.selectedCategory === category
                  ? this.theme.primary
                  : this.theme.backgroundSecondary
              )
              .fontColor(
                this.vm.selectedCategory === category
                  ? '#FFFFFF'
                  : this.theme.textSecondary
              )
              .fontSize(FontSize.SM)
              .borderRadius(16)
              .onClick(() => this.vm.onCategoryChange(category))
          })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .backgroundColor(this.theme.background)

      // 鎺掑簭閫夐」
      Row({ space: SpacingSize.LG }) {
        Button('鎺ㄨ崘')
          .height(28)
          .backgroundColor(
            this.vm.selectedSort === SourceMarketSort.RECOMMENDED
              ? this.theme.primary
              : 'transparent'
          )
          .fontColor(
            this.vm.selectedSort === SourceMarketSort.RECOMMENDED
              ? '#FFFFFF'
              : this.theme.textSecondary
          )
          .fontSize(FontSize.XS)
          .borderRadius(14)
          .onClick(() => this.vm.onSortChange(SourceMarketSort.RECOMMENDED))

        Button('鐑�棬')
          .height(28)
          .backgroundColor(
            this.vm.selectedSort === SourceMarketSort.DOWNLOADS
              ? this.theme.primary
              : 'transparent'
          )
          .fontColor(
            this.vm.selectedSort === SourceMarketSort.DOWNLOADS
              ? '#FFFFFF'
              : this.theme.textSecondary
          )
          .fontSize(FontSize.XS)
          .borderRadius(14)
          .onClick(() => this.vm.onSortChange(SourceMarketSort.DOWNLOADS))

        Button('璇勫垎')
          .height(28)
          .backgroundColor(
            this.vm.selectedSort === SourceMarketSort.RATING
              ? this.theme.primary
              : 'transparent'
          )
          .fontColor(
            this.vm.selectedSort === SourceMarketSort.RATING
              ? '#FFFFFF'
              : this.theme.textSecondary
          )
          .fontSize(FontSize.XS)
          .borderRadius(14)
          .onClick(() => this.vm.onSortChange(SourceMarketSort.RATING))
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .width('100%')
      .backgroundColor(this.theme.background)

      // 涔︽簮鍒楄〃
      if (this.vm.marketItems.length > 0) {
        List({ space: 12 }) {
          ForEach(this.vm.marketItems, (item: SourceMarketItem) => {
            ListItem() {
              this.buildSourceCard(item)
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .width('100%')
        .onReachEnd(() => {
          this.vm.loadMore();
        })
      } else if (!this.vm.isLoading) {
        // 绌虹姸锟?
        Column({ space: 16 }) {
          Text('馃摝')
            .fontSize(64)

          Text('鏆傛棤涔︽簮')
            .fontSize(FontSize.LG)
            .fontColor(this.theme.textSecondary)

          Text('蹇�幓鍙戠幇濂戒功婧愬惂')
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textTertiary)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }

      // 鍔犺浇鎸囩ず锟?
      if (this.vm.isLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.theme.primary)

          Text('鍔犺浇锟?..')
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }

      // 搴曢儴缁熻�
      Row() {
        Text('锟? + this.vm.totalItems + ' 涓�功婧愬寘')
          .fontSize(FontSize.XS)
          .fontColor(this.theme.textTertiary)
      }
      .width('100%')
      .padding(12)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.theme.backgroundSecondary)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.backgroundSecondary)
    .bindMenu(this.vm.showUrlInput, this.UrlInputDialogBuilder())
  }

  @Builder
  UrlInputDialogBuilder() {
    Column() {
      // 閬�僵锟?
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.vm.hideUrlInputDialog())

      // 瀵硅瘽妗嗗唴锟?
      Column({ space: 16 }) {
        Text('娣诲姞鑷�畾涔変功锟?)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 10 })

        TextInput({ placeholder: '杈撳叆涔︽簮 JSON 鍦板潃', text: $$this.vm.customSourceUrl })
          .width('100%')
          .height(44)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .fontSize(14)

        Row({ space: 12 }) {
          Button('鍙栨秷')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.04)')
            .borderRadius(22)
            .onClick(() => this.vm.hideUrlInputDialog())

          Button('娣诲姞')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(this.theme.primary)
            .borderRadius(22)
            .onClick(() => this.vm.addSourceFromUrl())
        }
        .width('100%')
        .padding({ top: 10, bottom: 20 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  /**
   * 鏋勫缓涔︽簮鍗＄墖
   */
  @Builder
  buildSourceCard(item: SourceMarketItem) {
    Column() {
      Row() {
        // 鍥炬爣
        Stack() {
          Image(item.iconUrl || 'media:default_source_icon')
            .width(64)
            .height(64)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
            .objectFit(ImageFit.Cover)

          // 瀹樻柟鏍囩�
          if (item.isOfficial) {
            Text('瀹樻柟')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor(this.theme.primary)
              .borderRadius(4)
              .position({ x: 0, y: 0 })
          }
        }

        // 淇℃伅鍖哄煙
        Column({ space: 4 }) {
          // 鍚嶇О
          Text(item.name)
            .fontSize(FontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 鎻忚堪
          Text(item.description)
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 缁熻�淇℃伅
          Row({ space: 12 }) {
            Row({ space: 4 }) {
              Text('馃摝')
                .fontSize(12)
              Text(item.sourceCount + '锟?)
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }

            Row({ space: 4 }) {
              Text('馃摜')
                .fontSize(12)
              Text(this.vm.formatNumber(item.downloads))
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }

            Row({ space: 4 }) {
              Text('锟?)
                .fontSize(12)
              Text((item.rating || 0).toFixed(1))
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }
          }

          // 鏍囩�
          if (item.tags && item.tags.length > 0) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach((item.tags || []).slice(0, 3), (tag: string) => {
                Text(tag)
                  .fontSize(10)
                  .fontColor(this.theme.primary)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .backgroundColor(this.theme.primary + '20')
                  .borderRadius(4)
              })
            }
          }
        }
        .margin({ left: 12 })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 涓嬭浇鎸夐挳
        Button(this.vm.isDownloaded(item.marketId) ? '宸插�锟? : '瀵煎叆')
          .width(70)
          .height(36)
          .backgroundColor(
            this.vm.isDownloaded(item.marketId)
              ? this.theme.textDisabled
              : this.theme.primary
          )
          .fontColor('#FFFFFF')
          .fontSize(FontSize.SM)
          .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
          .enabled(!this.vm.isDownloaded(item.marketId))
          .onClick(() => this.vm.onDownloadSource(item))
      }
      .width('100%')
      .padding(12)

      // VIP鏍囩�
      if (item.requiresVip) {
        Row() {
          Text('馃拵 VIP涓撲韩')
            .fontSize(FontSize.XS)
            .fontColor('#FF9800')
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 8 })
      }
    }
    .width('100%')
    .backgroundColor(this.theme.background)
    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.LG))
    .border({ width: 1, color: this.theme.borderLight })
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct SourceMarketPagePreview {
  build() {
    Column() {
      Text('涔︽簮甯傚満锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      SourceMarketPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('涔︽簮甯傚満锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SourceMarketPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
