import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface OnlineSourceItem {
  id: string;
  name: string;
  url: string;
  description: string;
  bookCount: number;
  rating: number;
  downloadCount: number;
  author: string;
  tags: string[];
  isVerified: boolean;
}

@Entry
@ComponentV2
struct OnlineSourceMarketPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local searchText: string = '';
  @Local selectedCategory: string = '全部';
  @Local sources: OnlineSourceItem[] = [];
  private context: common.Context | null = null;

  private categories: string[] = ['全部', '小说', '文学', '漫画', '学术', '其他'];

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
    this.loadSources();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
    }
  }

  private loadSources(): void {
    // 模拟数据
    this.sources = [
      {
        id: '1',
        name: '精选小说网',
        url: 'https://example.com/novel',
        description: '热门网络小说资源，更新快速',
        bookCount: 80000,
        rating: 4.9,
        downloadCount: 25600,
        author: '官方认证',
        tags: ['小说', '热门', '官方'],
        isVerified: true
      },
      {
        id: '2',
        name: '经典文学库',
        url: 'https://example.com/literature',
        description: '中外经典文学作品，品质保证',
        bookCount: 15000,
        rating: 4.8,
        downloadCount: 18900,
        author: '文学社',
        tags: ['文学', '经典'],
        isVerified: true
      },
      {
        id: '3',
        name: '高清漫画站',
        url: 'https://example.com/comic',
        description: '优质漫画资源，高清无水印',
        bookCount: 5000,
        rating: 4.7,
        downloadCount: 32100,
        author: '漫画联盟',
        tags: ['漫画', '高清'],
        isVerified: false
      }
    ];
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
      List({ space: Spacing.md }) {
        ForEach(this.sources, (source: OnlineSourceItem) => {
          ListItem() {
            this.SourceItem(source)
          }
        }, (source: OnlineSourceItem) => source.id)
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
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  SourceItem(source: OnlineSourceItem) {
    Column({ space: Spacing.md }) {
      // 头部：名称和验证标识
      Row({ space: Spacing.sm }) {
        Text(source.name)
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)

        if (source.isVerified) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.checkmark.seal.fill'))
              .fontSize(Size.iconSM)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
            
            Text('已认证')
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          }
          .padding({ 
            left: Spacing.sm, 
            right: Spacing.sm, 
            top: Spacing.xs, 
            bottom: Spacing.xs 
          })
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
          .borderRadius(BorderRadius.xl)
        }
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
          SymbolGlyph($r('sys.symbol.books.vertical'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(this.formatNumber(source.bookCount))
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }

        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.star.fill'))
            .fontSize(Size.iconXS)
            .fontColor(['#FFD700'])
          
          Text(source.rating.toFixed(1))
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor('#FFD700')
        }

        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.arrow.down.circle'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(this.formatNumber(source.downloadCount))
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
