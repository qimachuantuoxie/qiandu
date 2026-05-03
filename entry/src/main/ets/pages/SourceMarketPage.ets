/**
 * 书源市场页面 - 鸿蒙版 V2
 * 使用 ViewModel 模式管理状态
 */

import { SourceMarketItem, SourceMarketCategory, SourceMarketSort } from '../services/book/LegadoSourceMarket';
import { sourceMarketViewModel, SourceMarketViewModel } from '../viewmodels/SourceMarketViewModel';
import { uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../services/reader/UIDesignKitService';
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';

@Entry
@Component
struct SourceMarketPage {
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  vm: SourceMarketViewModel = sourceMarketViewModel;

  private theme: ThemeColors = LIGHT_THEME;
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
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();

    await this.vm.init(this.context);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(this.theme.textPrimary)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
          try {
            router.back();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('[SourceMarketPage] back failed:', msg);
          }
        })

        Text('书源市场')
          .fontSize(FontSize.H3)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)
          .margin({ left: 8 })

        // 搜索按钮
        Text('🔍')
          .fontSize(20)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => this.vm.toggleSearch())

        // URL导入按钮
        Text('🔗')
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

      // 搜索框
      if (this.vm.showSearch) {
        Row() {
          TextInput({ placeholder: '搜索书源...', text: this.vm.searchKeyword })
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

          Button('搜索')
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

      // 分类标签
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

      // 排序选项
      Row({ space: SpacingSize.LG }) {
        Button('推荐')
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

        Button('热门')
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

        Button('评分')
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

      // 书源列表
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
        // 空状态
        Column({ space: 16 }) {
          Text('📦')
            .fontSize(64)

          Text('暂无书源')
            .fontSize(FontSize.LG)
            .fontColor(this.theme.textSecondary)

          Text('快去发现好书源吧')
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textTertiary)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }

      // 加载指示器
      if (this.vm.isLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(this.theme.primary)

          Text('加载中...')
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }

      // 底部统计
      Row() {
        Text('共' + this.vm.totalItems + ' 个书源包')
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
      // 遮罩层
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.vm.hideUrlInputDialog())

      // 对话框内容
      Column({ space: 16 }) {
        Text('添加自定义书源')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 10 })

        TextInput({ placeholder: '输入书源 JSON 地址', text: $$this.vm.customSourceUrl })
          .width('100%')
          .height(44)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .fontSize(14)

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.04)')
            .borderRadius(22)
            .onClick(() => this.vm.hideUrlInputDialog())

          Button('添加')
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
   * 构建书源卡片
   */
  @Builder
  buildSourceCard(item: SourceMarketItem) {
    Column() {
      Row() {
        // 图标
        Stack() {
          Image(item.iconUrl || 'media:default_source_icon')
            .width(64)
            .height(64)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
            .objectFit(ImageFit.Cover)

          // 官方标签
          if (item.isOfficial) {
            Text('官方')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor(this.theme.primary)
              .borderRadius(4)
              .position({ x: 0, y: 0 })
          }
        }

        // 信息区域
        Column({ space: 4 }) {
          // 名称
          Text(item.name)
            .fontSize(FontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 描述
          Text(item.description)
            .fontSize(FontSize.SM)
            .fontColor(this.theme.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 统计信息
          Row({ space: 12 }) {
            Row({ space: 4 }) {
              Text('📦')
                .fontSize(12)
              Text(item.sourceCount + '个')
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }

            Row({ space: 4 }) {
              Text('📥')
                .fontSize(12)
              Text(this.vm.formatNumber(item.downloads))
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }

            Row({ space: 4 }) {
              Text('⭐')
                .fontSize(12)
              Text((item.rating || 0).toFixed(1))
                .fontSize(FontSize.XS)
                .fontColor(this.theme.textTertiary)
            }
          }

          // 标签
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

        // 下载按钮
        Button(this.vm.isDownloaded(item.marketId) ? '已导入' : '导入')
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

      // VIP标签
      if (item.requiresVip) {
        Row() {
          Text('💎 VIP专享')
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
