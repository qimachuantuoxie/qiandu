import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface SourceItem {
  id: string;
  name: string;
  description: string;
  bookCount: number;
  rating: number;
  installCount: number;
  author: string;
  tags: string[];
}

@Entry
@ComponentV2
struct SourceMarketPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local searchText: string = '';
  @Local sources: SourceItem[] = [];
  private context: common.Context | null = null;

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
        name: '精选书源',
        description: '高质量网络文学书源，包含热门小说',
        bookCount: 50000,
        rating: 4.8,
        installCount: 12500,
        author: '官方推荐',
        tags: ['热门', '官方']
      },
      {
        id: '2',
        name: '经典文学',
        description: '中外经典文学作品合集',
        bookCount: 8000,
        rating: 4.9,
        installCount: 8600,
        author: '文学爱好者',
        tags: ['经典', '文学']
      },
      {
        id: '3',
        name: '漫画书源',
        description: '优质漫画资源，高清无水印',
        bookCount: 3000,
        rating: 4.7,
        installCount: 15200,
        author: '漫画达人',
        tags: ['漫画', '高清']
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
            logger.error('[SourceMarketPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('书源市场')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 管理按钮
        Row() {
          SymbolGlyph($r('sys.symbol.gearshape'))
            .fontSize(Size.iconSM)
            .fontColor([this.currentColors.primary])
        }
        .width(Size.buttonSM)
        .height(Size.buttonSM)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.currentColors.primary + '15')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          navigateTo('pages/BookSourceManagePage');
        })
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

        TextInput({ placeholder: '搜索书源...', text: $$this.searchText })
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

      // 书源列表
      List({ space: Spacing.md }) {
        ForEach(this.sources, (source: SourceItem) => {
          ListItem() {
            this.SourceItem(source)
          }
        }, (source: SourceItem) => source.id)
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
  SourceItem(source: SourceItem) {
    Column({ space: Spacing.md }) {
      // 头部：名称和评分
      Row({ space: Spacing.md }) {
        // 图标
        Column() {
          SymbolGlyph($r('sys.symbol.book.closed.fill'))
            .fontSize(Size.iconXL)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.lg)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
        })
        .justifyContent(FlexAlign.Center)

        Column({ space: Spacing.xs }) {
          Row({ space: Spacing.sm }) {
            Text(source.name)
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            // 评分
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.star.fill'))
                .fontSize(Size.iconXS)
                .fontColor(['#FFD700'])
              
              Text(source.rating.toFixed(1))
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFD700')
            }
          }

          Text(source.description)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 安装按钮
        Button('安装')
          .height(Size.buttonSM)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor('#FFFFFF')
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .borderRadius(BorderRadius.xl)
          .padding({ left: Spacing.lg, right: Spacing.lg })
          .onClick(() => {
            promptAction.showToast({ message: `正在安装 ${source.name}`, duration: 1500 });
          })
          .stateStyles({
            pressed: { .scale({ x: 0.95, y: 0.95 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
      }
      .width('100%')

      // 统计信息
      Row({ space: Spacing.lg }) {
        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.books.vertical'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(this.formatNumber(source.bookCount) + ' 本')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }

        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(source.author)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }

        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.arrow.down.circle'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(this.formatNumber(source.installCount) + ' 次')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }

        Blank()
      }
      .width('100%')

      // 标签
      if (source.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(source.tags, (tag: string) => {
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
        .width('100%')
      }
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
struct SourceMarketPagePreview {
  build() {
    Column() {
      Text('书源市场 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      SourceMarketPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('书源市场 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SourceMarketPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
