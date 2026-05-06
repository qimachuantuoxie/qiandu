import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';
import { bookSourceViewModel } from '../viewmodels/BookSourceViewModel';
import { BookSource, BookSourceType } from '../../../core/models/BookSourceModel';

interface SourceItem {
  id: string;
  name: string;
  description: string;
  bookCount: number;
  rating: number;
  installCount: number;
  author: string;
  tags: string[];
  type: BookSourceType;
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
      const bookSources = bookSourceViewModel.getAllSources();
      const mappedSources: SourceItem[] = [];
      for (let i = 0; i < bookSources.length; i++) {
        const src = bookSources[i];
        mappedSources.push({
          id: src.id,
          name: src.name,
          description: src.url,
          bookCount: src.sourceCount || 0,
          rating: src.weight / 10,
          installCount: 0,
          author: src.bookSourceType === BookSourceType.TEXT ? '文本书源' : (src.bookSourceType === BookSourceType.AUDIO ? '音频书源' : '漫画书源'),
          tags: this.getSourceTags(src),
          type: src.bookSourceType
        });
      }
      this.sources = mappedSources;
    } catch (error) {
      const err = error as Error;
      logger.error('[SourceMarketPage] Load sources failed:', err.message);
    } finally {
      this.isLoading = false;
    }
  }

  private getSourceTags(source: BookSource): string[] {
    const tags: string[] = [];
    if (source.enabled) {
      tags.push('已启用');
    }
    if (source.bookSourceType === BookSourceType.TEXT) {
      tags.push('小说');
    } else if (source.bookSourceType === BookSourceType.AUDIO) {
      tags.push('音频');
    } else if (source.bookSourceType === BookSourceType.IMAGE) {
      tags.push('漫画');
    }
    if (source.loginRequired) {
      tags.push('需登录');
    }
    return tags;
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

  private getFilteredSources(): SourceItem[] {
    if (!this.searchText) {
      return this.sources;
    }
    const keyword = this.searchText.toLowerCase();
    const filtered: SourceItem[] = [];
    for (let i = 0; i < this.sources.length; i++) {
      const src = this.sources[i];
      if (src.name.toLowerCase().indexOf(keyword) > -1 ||
          src.description.toLowerCase().indexOf(keyword) > -1 ||
          src.author.toLowerCase().indexOf(keyword) > -1) {
        filtered.push(src);
      }
    }
    return filtered;
  }

  build() {
    Column() {
      // 标准页面头部
      PageHeader({
        title: '书源市场',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[SourceMarketPage] back failed:', msg);
          }
        },
        rightContent: () => {
          // 管理按钮
          Row() {
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(HDSTypography.sizes.md)
              .fontColor([HDSColours.primary.blue])
          }
          .width(32)
          .height(32)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(HDSColours.primary.blue + '15')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            navigateTo('features/source-market/pages/BookSourceManagePage');
          })
        }
      })

      // 搜索栏
      Row({ space: HDSSpacing.sm }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(HDSTypography.sizes.md)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          .margin({ left: HDSSpacing.md })

        TextInput({ placeholder: '搜索书源...', text: $$this.searchText })
          .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textTertiary : HDSColours.neutral.gray400)
          .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
          .height(40)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
          })

        if (this.searchText) {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
              .fontSize(HDSTypography.sizes.md)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
          })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm })
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray100)
      .borderRadius(HDSBorderRadius.xl)
      .margin({ left: HDSSpacing.lg, right: HDSSpacing.lg, top: HDSSpacing.md })

      // 书源列表
      if (this.getFilteredSources().length === 0) {
        this.EmptyState()
      } else {
        List({ space: HDSSpacing.md }) {
          ForEach(this.getFilteredSources(), (source: SourceItem) => {
            ListItem() {
              this.SourceItem(source)
            }
          }, (source: SourceItem) => source.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg,
          top: HDSSpacing.md,
          bottom: HDSSpacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  EmptyState() {
    Column({ space: HDSSpacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.book.closed'))
          .fontSize(64)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textDisabled : HDSColours.neutral.gray400])
      }
      .width(100)
      .height(100)
      .borderRadius(HDSBorderRadius.full)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray100)
      .justifyContent(FlexAlign.Center)

      Text('暂无书源')
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Text('前往书源管理页面添加书源')
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)

      Button('管理书源')
        .height(40)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
        .fontColor(HDSColours.neutral.white)
        .backgroundColor(HDSColours.primary.blue)
        .borderRadius(HDSBorderRadius.xl)
        .padding({ left: HDSSpacing.xxl, right: HDSSpacing.xxl })
        .onClick(() => {
          navigateTo('features/source-market/pages/BookSourceManagePage');
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SourceItem(source: SourceItem) {
    Column({ space: HDSSpacing.md }) {
      // 头部：名称和评分
      Row({ space: HDSSpacing.md }) {
        // 图标
        Column() {
          SymbolGlyph($r('sys.symbol.book.closed.fill'))
            .fontSize(HDSTypography.sizes.xl)
            .fontColor([HDSColours.neutral.white])
        }
        .width(48)
        .height(48)
        .borderRadius(HDSBorderRadius.lg)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
        })
        .justifyContent(FlexAlign.Center)

        Column({ space: HDSSpacing.xs }) {
          Row({ space: HDSSpacing.sm }) {
            Text(source.name)
              .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

            // 评分
            Row({ space: HDSSpacing.xs }) {
              SymbolGlyph($r('sys.symbol.star.fill'))
                .fontSize(HDSTypography.sizes.xs)
                .fontColor(['#FFD700'])
              
              Text(source.rating.toFixed(1))
                .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFD700')
            }
          }

          Text(source.description)
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 安装按钮
        Button('安装')
          .height(32)
          .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
          .fontColor(HDSColours.neutral.white)
          .backgroundColor(HDSColours.primary.blue)
          .borderRadius(HDSBorderRadius.xl)
          .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg })
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
      Row({ space: HDSSpacing.lg }) {
        Row({ space: HDSSpacing.xs }) {
          SymbolGlyph($r('sys.symbol.books.vertical'))
            .fontSize(HDSTypography.sizes.xs)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          
          Text(this.formatNumber(source.bookCount) + ' 本')
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        }

        Row({ space: HDSSpacing.xs }) {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(HDSTypography.sizes.xs)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          
          Text(source.author)
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        }

        Row({ space: HDSSpacing.xs }) {
          SymbolGlyph($r('sys.symbol.arrow.down.circle'))
            .fontSize(HDSTypography.sizes.xs)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          
          Text(this.formatNumber(source.installCount) + ' 次')
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        }

        Blank()
      }
      .width('100%')

      // 标签
      if (source.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(source.tags, (tag: string) => {
            Text(tag)
              .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
              .padding({ 
                left: HDSSpacing.sm, 
                right: HDSSpacing.sm, 
                top: HDSSpacing.xs, 
                bottom: HDSSpacing.xs 
              })
              .backgroundColor(HDSColours.primary.blue + '10')
              .fontColor(HDSColours.primary.blue)
              .borderRadius(HDSBorderRadius.xl)
              .margin({ right: HDSSpacing.xs })
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(HDSPacing.lg)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
    .shadow({
      radius: 4,
      color: this.isDarkMode ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)',
      offsetY: 2
    })
    .stateStyles({
      pressed: { 
        scale: { x: 0.98, y: 0.98 },
        backgroundColor: this.isDarkMode ? HDSColours.neutralDark.bgHover : HDSColours.neutral.gray50
      },
      normal: { 
        scale: { x: 1, y: 1 },
        backgroundColor: this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white
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
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutral.gray100)

      SourceMarketPage()
        .height(700)

      Divider()
        .margin({ top: HDSSpacing.xl, bottom: HDSSpacing.xl })

      Text('书源市场 - 深色模式')
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutralDark.surface)
        .fontColor(HDSColours.neutralDark.textPrimary)

      SourceMarketPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor(HDSColours.neutral.white)
  }
}
