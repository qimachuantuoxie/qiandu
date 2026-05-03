/**
 * 在线书籍搜索页面 - 优化版
 * 支持多书源并行搜索、结果展示、详情查看
 * 优化：UI 美化、骨架屏、分类筛选、排序功能
 *
 * @since 3.0.0
 */

import { router } from '@kit.ArkUI';
import { toast } from '../utils/ToastHelper';
import { navigateTo } from '../utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { onlineBookService } from '../services/book/OnlineBookService';
import { OnlineSearchResult } from '../models/OnlineBookModel';
import { themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

const PREFERENCES_NAME = 'search_preferences';

@Entry
@Component
export struct OnlineSearchPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State searchKeyword: string = '';
  @State searchResults: OnlineSearchResult[] = [];
  @State isSearching: boolean = false;
  @State showHistory: boolean = false;
  @State searchHistory: string[] = [];
  @State isLoading: boolean = false;
  @State sortBy: string = 'relevance'; // relevance, name, author
  @State filterSource: string = 'all';
  @State showFilterPanel: boolean = false;

  // 热门搜索词
  private readonly hotSearches: string[] = ['三体', '斗破苍穹', '凡人修仙传', '遮天', '完美世界'];

  aboutToAppear() {
    this.isDarkMode = false;
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
    await this.loadSearchHistory();
  }

  build() {
    Column() {
      // 顶部搜索栏
      this.buildSearchBar()

      // 主内容区
      if (this.isLoading) {
        // 骨架屏加载
        this.buildSkeletonLoading()
      } else if (this.isSearching) {
        // 搜索中
        this.buildLoadingView()
      } else if (this.searchResults.length > 0) {
        // 搜索结果
        this.buildSearchResults()
      } else if (this.searchKeyword.length > 0) {
        // 无结果
        this.buildEmptyView()
      } else {
        // 默认页面 - 搜索历史 + 热门搜索
        this.buildDefaultView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentColors.background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildSearchBar() {
    Row() {
      // 返回按钮
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(20)
        .fontColor([this.currentColors.onSurface])
        .onClick(() => {
          try { router.back(); } catch (e) { console.error('[OnlineSearch] back failed', e); }
        })
        .margin({ right: 12 })

      // 搜索框
      TextInput({ placeholder: tr('search_books_hint'), text: this.searchKeyword })
        .layoutWeight(1)
        .height(40)
        .backgroundColor(this.currentColors.surfaceVariant)
        .fontColor(this.currentColors.onSurface)
        .fontSize(16 * this.fontScale)
        .borderRadius(20)
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
        .onSubmit(() => {
          if (this.searchKeyword.trim().length > 0) {
            this.performSearch();
          }
        })

      // 筛选按钮
      SymbolGlyph($r('sys.symbol.line_3_horizontal'))
        .fontSize(20)
        .fontColor([this.currentColors.onSurface])
        .margin({ left: 12 })
        .onClick(() => {
          this.showFilterPanel = !this.showFilterPanel;
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.currentColors.surface)
  }

  @Builder
  buildDefaultView() {
    Scroll() {
      Column({ space: 24 }) {
        // 热门搜索
        this.buildHotSearches()

        // 搜索历史
        this.buildHistoryView()
      }
      .padding(16)
      .width('100%')
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildHotSearches() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.flame_fill'))
          .fontSize(18)
          .fontColor([COMMON_COLORS.ERROR_RED])

        Text('热门搜索')
          .fontSize(18 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.onSurface)
          .margin({ left: 8 })
      }
      .alignSelf(ItemAlign.Start)
      .margin({ bottom: 16 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.hotSearches, (keyword: string) => {
          Text(keyword)
            .fontSize(14 * this.fontScale)
            .fontColor(this.currentColors.onSurface)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin(4)
            .backgroundColor(this.currentColors.surface)
            .borderRadius(16)
            .onClick(() => {
              this.searchKeyword = keyword;
              this.performSearch();
            })
        }, (keyword: string) => keyword)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(12)
  }

  @Builder
  buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .margin({ top: 50 })

      Text(tr('searching_hint'))
        .fontSize(14 * this.fontScale)
        .fontColor(this.currentColors.onSurfaceVariant)
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildSkeletonLoading() {
    List({ space: 12 }) {
      ForEach([1, 2, 3, 4, 5], (item: number) => {
        ListItem() {
          Row() {
            // 封面骨架
            Rect()
              .width(80)
              .height(110)
              .fill(this.currentColors.surfaceVariant)
              .borderRadius(8)

            Column({ space: 8 }) {
              Rect()
                .width('60%')
                .height(18)
                .fill(this.currentColors.surfaceVariant)
                .borderRadius(4)

              Rect()
                .width('40%')
                .height(14)
                .fill(this.currentColors.surfaceVariant)
                .borderRadius(4)

              Rect()
                .width('30%')
                .height(12)
                .fill(this.currentColors.surfaceVariant)
                .borderRadius(4)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.currentColors.surface)
          .borderRadius(12)
        }
      })
    }
    .layoutWeight(1)
    .padding(12)
    .width('100%')
  }

  @Builder
  buildSearchResults() {
    Column() {
      // 结果统计
      Row() {
        Text('找到 ' + this.searchResults.length + ' 个结果')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.onSurfaceVariant)

        Blank()

        // 排序选项
        Text(this.sortBy === 'relevance' ? '相关度' : this.sortBy === 'name' ? '书名' : '作者')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.primary)
          .onClick(() => this.toggleSort())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 结果列表
      List({ space: 8 }) {
        ForEach(this.getFilteredResults(), (result: OnlineSearchResult) => {
          ListItem() {
            this.buildSearchResultItem(result)
          }
        }, (result: OnlineSearchResult) => result.bookUrl + result.sourceId)
      }
      .layoutWeight(1)
      .padding(12)
      .width('100%')
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildSearchResultItem(result: OnlineSearchResult) {
    Row() {
      // 封面占位
      Column() {
        SymbolGlyph($r('sys.symbol.book'))
          .fontSize(32)
          .fontColor([this.currentColors.onSurfaceVariant])
      }
      .width(80)
      .height(110)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentColors.surfaceVariant)
      .borderRadius(8)

      Column({ space: 8 }) {
        Text(result.bookName)
          .fontSize(16 * this.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.onSurface)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(12)
            .fontColor([this.currentColors.onSurfaceVariant])

          Text(result.author || tr('unknown_author'))
            .fontSize(12 * this.fontScale)
            .fontColor(this.currentColors.onSurfaceVariant)
        }
        .alignSelf(ItemAlign.Start)

        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.bookmark'))
            .fontSize(12)
            .fontColor([this.currentColors.primary])

          Text(result.sourceName)
            .fontSize(11 * this.fontScale)
            .fontColor(this.currentColors.primary)
        }
        .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 右箭头
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([this.currentColors.onSurfaceVariant])
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(12)
    .onClick(() => {
      this.openBookDetail(result);
    })
  }

  @Builder
  buildEmptyView() {
    Column() {
      SymbolGlyph($r('sys.symbol.book'))
        .fontSize(64)
        .fontColor([this.currentColors.onSurfaceVariant])
        .opacity(0.3)

      Text(tr('no_results_hint'))
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.onSurfaceVariant)
        .margin({ top: 16 })

      Text('试试其他关键词吧')
        .fontSize(14 * this.fontScale)
        .fontColor(this.currentColors.onSurfaceVariant)
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  @Builder
  buildHistoryView() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(18)
          .fontColor([this.currentColors.onSurfaceVariant])

        Text(tr('search_history_title'))
          .fontSize(18 * this.fontScale)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.onSurface)
          .margin({ left: 8 })
          .layoutWeight(1)

        if (this.searchHistory.length > 0) {
          Text('清空')
            .fontSize(14 * this.fontScale)
            .fontColor(this.currentColors.primary)
            .onClick(() => this.clearHistory())
        }
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.searchHistory.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.searchHistory, (keyword: string) => {
            Text(keyword)
              .fontSize(14 * this.fontScale)
              .fontColor(this.currentColors.onSurface)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .margin(4)
              .backgroundColor(this.currentColors.surface)
              .borderRadius(16)
              .onClick(() => {
                this.searchKeyword = keyword;
                this.performSearch();
              })
          }, (keyword: string) => keyword)
        }
      } else {
        Text('暂无搜索历史')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.onSurfaceVariant)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(20)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(12)
  }

  private async performSearch(): Promise<void> {
    if (this.searchKeyword.trim().length === 0) {
      return;
    }

    this.isLoading = true;
    this.isSearching = true;
    this.searchResults = [];

    try {
      const results = await onlineBookService.searchOnlineBooks(this.searchKeyword.trim());
      this.searchResults = results;

      // 保存到历史
      await this.saveToHistory(this.searchKeyword.trim());
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      console.error('[OnlineSearch] Search failed:', message);
    } finally {
      this.isSearching = false;
      this.isLoading = false;
    }
  }

  private openBookDetail(result: OnlineSearchResult): void {
    const params: Record<string, string> = {};
    params['bookUrl'] = result.bookUrl;
    params['sourceId'] = result.sourceId;
    params['bookName'] = result.bookName;
    navigateTo('pages/OnlineBookDetailPage', params);
  }

  private toggleSort(): void {
    if (this.sortBy === 'relevance') {
      this.sortBy = 'name';
    } else if (this.sortBy === 'name') {
      this.sortBy = 'author';
    } else {
      this.sortBy = 'relevance';
    }
  }

  private getFilteredResults(): OnlineSearchResult[] {
    let results = this.searchResults.slice();

    // 筛选书源
    if (this.filterSource !== 'all') {
      results = results.filter(r => r.sourceId === this.filterSource);
    }

    // 排序
    if (this.sortBy === 'name') {
      results.sort((a, b) => a.bookName.localeCompare(b.bookName, 'zh-CN'));
    } else if (this.sortBy === 'author') {
      results.sort((a, b) => {
        const authorA = a.author || '';
        const authorB = b.author || '';
        return authorA.localeCompare(authorB, 'zh-CN');
      });
    }

    return results;
  }

  // ==================== 搜索历史管理 ====================
  @State private pageContext: common.Context | null = null;

  private async loadSearchHistory(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext()!;
      const pref: preferences.Preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      const historyJson: string = await pref.get('search_history', '[]') as string;
      this.searchHistory = JSON.parse(historyJson) as string[];
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      console.error('[OnlineSearch] Load history failed:', message);
      this.searchHistory = [];
    }
  }

  private async saveToHistory(keyword: string): Promise<void> {
    this.searchHistory = this.searchHistory.filter(k => k !== keyword);
    this.searchHistory.unshift(keyword);
    if (this.searchHistory.length > 20) {
      this.searchHistory = this.searchHistory.slice(0, 20);
    }
    try {
      const context = this.getUIContext().getHostContext()!;
      const pref: preferences.Preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      await pref.put('search_history', JSON.stringify(this.searchHistory));
      await pref.flush();
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      console.error('[OnlineSearch] Save history failed:', message);
    }
  }

  private async clearHistory(): Promise<void> {
    this.searchHistory = [];
    try {
      const context = this.getUIContext().getHostContext()!;
      const pref: preferences.Preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      await pref.put('search_history', '[]');
      await pref.flush();
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      console.error('[OnlineSearch] Clear history failed:', message);
    }
  }
}
