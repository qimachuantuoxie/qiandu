import { logger } from '../../../common/utils/Logger';
import { toast } from '../../../core/utils/ToastHelper';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { onlineBookService } from '../../../core/services/book/OnlineBookService';
import { OnlineSearchResult } from '../../../core/models/OnlineBookModel';
import { themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { tr } from '../../../core/utils/LocalizationUtil';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

const PREFERENCES_NAME = 'search_preferences';

@Entry
@ComponentV2
struct OnlineSearchPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local searchKeyword: string = '';
  @Local searchResults: OnlineSearchResult[] = [];
  @Local isSearching: boolean = false;
  @Local showHistory: boolean = false;
  @Local searchHistory: string[] = [];
  @Local isLoading: boolean = false;
  @Local sortBy: string = 'relevance';
  @Local filterSource: string = 'all';
  @Local showFilterPanel: boolean = false;
  @Local screenInfo: ScreenInfo | null = null;

  private readonly hotSearches: string[] = ['三体', '斗破苍穹', '凡人修仙传', '遮天', '完美世界'];

  aboutToAppear() {
    this.isDarkMode = false;
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    this.fontScale = await fontScaleManager.getFontScale();
    await this.loadSearchHistory();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private async loadSearchHistory(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) return;
      
      const dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      const history = await dataPreferences.get('search_history', '[]');
      this.searchHistory = JSON.parse(history as string);
    } catch (error) {
      logger.error('Load search history failed:', error);
    }
  }

  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (!context) return;
      
      const index = this.searchHistory.indexOf(keyword);
      if (index > -1) {
        this.searchHistory.splice(index, 1);
      }
      this.searchHistory.unshift(keyword);
      if (this.searchHistory.length > 10) {
        this.searchHistory = this.searchHistory.slice(0, 10);
      }
      
      const dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      await dataPreferences.put('search_history', JSON.stringify(this.searchHistory));
      await dataPreferences.flush();
    } catch (error) {
      logger.error('Save search history failed:', error);
    }
  }

  private async performSearch(): Promise<void> {
    if (!this.searchKeyword.trim()) return;
    
    this.isSearching = true;
    this.isLoading = true;
    
    try {
      await this.saveSearchHistory(this.searchKeyword);
      
      const results = await onlineBookService.searchBooks(this.searchKeyword);
      this.searchResults = this.sortResults(results);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[OnlineSearch] Search failed:', message);
      toast('搜索失败，请重试');
    } finally {
      this.isSearching = false;
      this.isLoading = false;
    }
  }

  private sortResults(results: OnlineSearchResult[]): OnlineSearchResult[] {
    switch (this.sortBy) {
      case 'name':
        return results.sort((a, b) => a.name.localeCompare(b.name));
      case 'author':
        return results.sort((a, b) => a.author.localeCompare(b.author));
      default:
        return results;
    }
  }

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        // 返回按钮
        Row() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(24)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900])
        }
        .width(40)
        .height(40)
        .borderRadius(HDSBorderRadius.full)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try { goBack(); } 
          catch (e) { logger.error('[OnlineSearch] back failed', e); }
        })

        // 搜索框
        TextInput({ placeholder: '搜索书籍、作者...', text: this.searchKeyword })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F2F2F7')
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .fontSize(HDSTypography.sizes.md)
          .borderRadius(HDSBorderRadius.xl)
          .margin({ left: HDSSpacing.md })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => {
            if (this.searchKeyword.trim().length > 0) {
              this.performSearch();
            }
          })

        // 筛选按钮
        Row() {
          SymbolGlyph($r('sys.symbol.line.3.horizontal'))
            .fontSize(20)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900])
        }
        .width(40)
        .height(40)
        .borderRadius(HDSBorderRadius.full)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .justifyContent(FlexAlign.Center)
        .margin({ left: HDSSpacing.sm })
        .onClick(() => {
          this.showFilterPanel = !this.showFilterPanel;
        })
      }
      .width('100%')
      .padding(HDSPacing.lg)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)

      // 主内容区
      if (this.isLoading) {
        this.SkeletonLoading()
      } else if (this.isSearching) {
        this.LoadingView()
      } else if (this.searchResults.length > 0) {
        this.SearchResults()
      } else if (this.searchKeyword.length > 0) {
        this.EmptyView()
      } else {
        this.DefaultView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  DefaultView() {
    Scroll() {
      Column({ space: Spacing.xxl }) {
        // 热门搜索
        this.HotSearches()

        // 搜索历史
        this.HistoryView()
      }
      .width('100%')
      .padding(Spacing.lg)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  HotSearches() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.flame.fill'))
          .fontSize(Size.iconMD)
          .fontColor([COMMON_COLORS.ERROR_RED])

        Text('热门搜索')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.hotSearches, (keyword: string) => {
          Text(keyword)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
            .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => {
              this.searchKeyword = keyword;
              this.performSearch();
            })
            .stateStyles({
              pressed: { .scale({ x: 0.95, y: 0.95 }) },
              normal: { .scale({ x: 1, y: 1 }) }
            })
            .margin({ right: Spacing.sm, bottom: Spacing.sm })
        }, (keyword: string) => keyword)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  HistoryView() {
    if (this.searchHistory.length > 0) {
      Column({ space: Spacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])

          Text('搜索历史')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .margin({ left: Spacing.sm })

          Text('清空')
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontColor(COMMON_COLORS.ERROR_RED)
            .onClick(async () => {
              this.searchHistory = [];
              const context = this.getUIContext().getHostContext();
              if (context) {
                const dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
                await dataPreferences.put('search_history', '[]');
                await dataPreferences.flush();
              }
            })
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.searchHistory, (keyword: string) => {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(Size.iconXS)
                .fontColor([this.tc('#8E8E93', '#8E8E93')])
              
              Text(keyword)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            }
            .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
            .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => {
              this.searchKeyword = keyword;
              this.performSearch();
            })
            .margin({ right: Spacing.sm, bottom: Spacing.sm })
          }, (keyword: string) => keyword)
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  LoadingView() {
    Column({ space: Spacing.lg }) {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.currentColors.primary)

      Text('搜索中...')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SkeletonLoading() {
    Column({ space: Spacing.md }) {
      ForEach([1, 2, 3, 4, 5], (_: number, index: number) => {
        Row({ space: Spacing.lg }) {
          Column()
            .width(60)
            .height(80)
            .backgroundColor(this.tc('#E5E5EA', '#3A3A3C'))
            .borderRadius(BorderRadius.md)

          Column({ space: Spacing.sm }) {
            Column()
              .width('60%')
              .height(16)
              .backgroundColor(this.tc('#E5E5EA', '#3A3A3C'))
              .borderRadius(BorderRadius.sm)

            Column()
              .width('40%')
              .height(14)
              .backgroundColor(this.tc('#E5E5EA', '#3A3A3C'))
              .borderRadius(BorderRadius.sm)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.lg)
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
        .borderRadius(BorderRadius.xl)
      }, (item: number) => item.toString())
    }
    .width('100%')
    .layoutWeight(1)
    .padding(Spacing.lg)
  }

  @Builder
  SearchResults() {
    Column() {
      // 结果统计
      Row() {
        Text(`找到 ${this.searchResults.length} 个结果`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))

        Blank()

        // 排序选择
        Text(this.sortBy === 'relevance' ? '相关度' : this.sortBy === 'name' ? '书名' : '作者')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => {
            const sorts = ['relevance', 'name', 'author'];
            const currentIndex = sorts.indexOf(this.sortBy);
            this.sortBy = sorts[(currentIndex + 1) % sorts.length];
            this.searchResults = this.sortResults(this.searchResults);
          })
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.sm })

      // 结果列表
      List({ space: Spacing.md }) {
        ForEach(this.searchResults, (result: OnlineSearchResult) => {
          ListItem() {
            this.ResultItem(result)
          }
        }, (result: OnlineSearchResult) => result.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.xxxl })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ResultItem(result: OnlineSearchResult) {
    Row({ space: Spacing.lg }) {
      // 封面
      Column() {
        if (result.coverUrl) {
          Image(result.coverUrl)
            .width(60)
            .height(80)
            .borderRadius(BorderRadius.md)
            .objectFit(ImageFit.Cover)
        } else {
          SymbolGlyph($r('sys.symbol.book.fill'))
            .fontSize(Size.iconXL)
            .fontColor([this.currentColors.primary])
        }
      }
      .width(60)
      .height(80)
      .borderRadius(BorderRadius.md)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      // 信息
      Column({ space: Spacing.sm }) {
        Text(result.name)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(result.author)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: Spacing.sm }) {
          Text(result.sourceName || '未知书源')
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.currentColors.primary + '15')
            .fontColor(this.currentColors.primary)
            .borderRadius(BorderRadius.xl)

          if (result.chapterCount) {
            Text(`${result.chapterCount}章`)
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头
      SymbolGlyph($r('sys.symbol.chevron.right'))
        .fontSize(Size.iconSM)
        .fontColor([this.tc('#C7C7CC', '#48484A')])
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .onClick(() => {
      const params: Record<string, Object> = {};
      params['result'] = result;
      navigateTo('pages/OnlineBookDetailPage', params);
    })
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

  @Builder
  EmptyView() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('未找到相关书籍')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('试试其他关键词吧')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

// 预览组件
@Preview
@ComponentV2
struct OnlineSearchPagePreview {
  build() {
    Column() {
      Text('在线搜索 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      OnlineSearchPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('在线搜索 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      OnlineSearchPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
