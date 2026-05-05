import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';
import { onlineSourceMarketViewModel, OnlineSourceInfo } from '../viewmodels/OnlineSourceMarketViewModel';

@Entry
@ComponentV2
struct OnlineSourceMarketPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local searchText: string = '';
  @Local selectedCategory: string = '全部';
  @Local sources: OnlineSourceInfo[] = [];
  @Local categories: string[] = [];
  @Local isLoading: boolean = false;
  private context: common.Context | null = null;

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
    await this.loadSources();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
    }
  }

  private async loadSources(): Promise<void> {
    this.isLoading = true;
    try {
      await onlineSourceMarketViewModel.loadSources(true);
      this.categories = ['全部'];
      for (let i = 0; i < onlineSourceMarketViewModel.categories.length; i++) {
        if (onlineSourceMarketViewModel.categories[i] !== 'all') {
          this.categories.push(onlineSourceMarketViewModel.categories[i]);
        }
      }
      this.sources = onlineSourceMarketViewModel.sources;
    } catch (error) {
      const err = error as Error;
      logger.error('[OnlineSourceMarketPage] Load sources failed:', err.message);
    } finally {
      this.isLoading = false;
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private formatNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + '万';
    }
    return num.toString();
  }

  private getFilteredSources(): OnlineSourceInfo[] {
    let filtered = this.sources;
    if (this.selectedCategory !== '全部') {
      const filteredList: OnlineSourceInfo[] = [];
      for (let i = 0; i < this.sources.length; i++) {
        if (this.sources[i].category === this.selectedCategory) {
          filteredList.push(this.sources[i]);
        }
      }
      filtered = filteredList;
    }

    if (this.searchText) {
      const keyword = this.searchText.toLowerCase();
      const searchFiltered: OnlineSourceInfo[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const src = filtered[i];
        if (src.name.toLowerCase().indexOf(keyword) > -1 ||
            src.description.toLowerCase().indexOf(keyword) > -1 ||
            src.author.toLowerCase().indexOf(keyword) > -1) {
          searchFiltered.push(src);
        }
      }
      filtered = searchFiltered;
    }

    return filtered;
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
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
            logger.error('[OnlineSourceMarketPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('在线书源')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(Size.buttonMD)
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // 搜索栏
      Row({ space: Spacing.sm }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])
          .margin({ left: Spacing.md })

        TextInput({ placeholder: '搜索在线书源...', text: $$this.searchText })
          .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .height(Size.inputSM)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
          })

        if (this.searchText) {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
          })
        }
      }
      .width('100%')
      .height(Size.inputSM)
      .padding({ left: Spacing.sm, right: Spacing.sm })
      .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
      .borderRadius(BorderRadius.xl)
      .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })

      // 分类标签
      Scroll() {
        Row({ space: Spacing.sm }) {
          ForEach(this.categories, (category: string) => {
            Text(category)
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .padding({ 
                left: Spacing.lg, 
                right: Spacing.lg, 
                top: Spacing.sm, 
                bottom: Spacing.sm 
              })
              .backgroundColor(this.selectedCategory === category ? 
                this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
              .fontColor(this.selectedCategory === category ? 
                '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
              .borderRadius(BorderRadius.xl)
              .fontWeight(this.selectedCategory === category ? 
                FontWeight.Medium : FontWeight.Regular)
              .onClick(() => { this.selectedCategory = category; })
              .stateStyles({
                pressed: { .scale({ x: 0.95, y: 0.95 }) },
                normal: { .scale({ x: 1, y: 1 }) }
              })
          }, (category: string) => category)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 书源列表
      if (this.getFilteredSources().length === 0) {
        this.EmptyState()
      } else {
        List({ space: Spacing.md }) {
          ForEach(this.getFilteredSources(), (source: OnlineSourceInfo) => {
            ListItem() {
              this.SourceItem(source)
            }
          }, (source: OnlineSourceInfo) => source.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg,
          top: Spacing.md,
          bottom: Spacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.book.closed'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无在线书源')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('请先在书源管理中添加书源')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))

      Button('管理书源')
        .height(Size.buttonMD)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor('#FFFFFF')
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(BorderRadius.xl)
        .padding({ left: Spacing.xxl, right: Spacing.xxl })
        .onClick(() => {
          navigateTo('pages/BookSourceManagePage');
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SourceItem(source: OnlineSourceInfo) {
    Column({ space: Spacing.md }) {
      // 头部：名称
      Row({ space: Spacing.sm }) {
        Text(source.name)
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)

        Text(source.category)
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .padding({ 
            left: Spacing.sm, 
            right: Spacing.sm, 
            top: Spacing.xs, 
            bottom: Spacing.xs 
          })
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .borderRadius(BorderRadius.xl)
      }
      .width('100%')

      // 描述
      Text(source.description)
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
        .lineHeight(20)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 统计信息
      Row({ space: Spacing.lg }) {
        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.star.fill'))
            .fontSize(Size.iconXS)
            .fontColor(['#FFD700'])
          
          Text(source.rating.toFixed(1))
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor('#FFD700')
        }

        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(source.author)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }

        Blank()
      }
      .width('100%')

      // 标签和操作
      Row({ space: Spacing.md }) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(source.tags.slice(0, 3), (tag: string) => {
            Text(tag)
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .padding({ 
                left: Spacing.sm, 
                right: Spacing.sm, 
                top: Spacing.xs, 
                bottom: Spacing.xs 
              })
              .backgroundColor(this.currentColors.primary + '10')
              .fontColor(this.currentColors.primary)
              .borderRadius(BorderRadius.xl)
              .margin({ right: Spacing.xs })
          }, (tag: string) => tag)
        }
        .layoutWeight(1)

        Button('添加')
          .height(Size.buttonSM)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor('#FFFFFF')
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .borderRadius(BorderRadius.xl)
          .padding({ left: Spacing.lg, right: Spacing.lg })
          .onClick(() => {
            promptAction.showToast({ message: `已添加 ${source.name}`, duration: 1500 });
          })
          .stateStyles({
            pressed: { .scale({ x: 0.95, y: 0.95 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .stateStyles({
      pressed: { 
        .scale({ x: 0.98, y: 0.98 }),
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .scale({ x: 1, y: 1 }),
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      }
    })
  }
}

// 预览组件
@Preview
@ComponentV2
struct OnlineSourceMarketPagePreview {
  build() {
    Column() {
      Text('在线书源 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      OnlineSourceMarketPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('在线书源 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      OnlineSourceMarketPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
