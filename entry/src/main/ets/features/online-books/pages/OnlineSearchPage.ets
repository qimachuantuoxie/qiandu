import { logger } from '../../../common/utils/Logger';
/**
 * 鍦ㄧ嚎涔︾睄鎼滅储椤甸潰 - 浼樺寲锟?
 * 鏀�寔澶氫功婧愬苟琛屾悳绱€€佺粨鏋滃睍绀恒€佽�鎯呮煡锟?
 * 浼樺寲锛歎I 缇庡寲銆侀�鏋跺睆銆佸垎绫荤瓫閫夈€佹帓搴忓姛锟?
 *
 * @since 3.0.0
 */


import { toast } from '../core/utils/ToastHelper';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { onlineBookService } from '../core/services/book/OnlineBookService';
import { OnlineSearchResult } from '../core/models/OnlineBookModel';
import { themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

  // 鐑�棬鎼滅储锟?
  private readonly hotSearches: string[] = ['涓変綋', '鏂楃牬鑻嶇┕', '鍑′汉淇�粰锟?, '閬�ぉ', '瀹岀編涓栫晫'];

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

  build() {
    Column() {
      // 椤堕儴鎼滅储锟?
      this.buildSearchBar()

      // 涓诲唴瀹瑰尯
      if (this.isLoading) {
        // 楠ㄦ灦灞忓姞锟?
        this.buildSkeletonLoading()
      } else if (this.isSearching) {
        // 鎼滅储锟?
        this.buildLoadingView()
      } else if (this.searchResults.length > 0) {
        // 鎼滅储缁撴灉
        this.buildSearchResults()
      } else if (this.searchKeyword.length > 0) {
        // 鏃犵粨锟?
        this.buildEmptyView()
      } else {
        // 榛樿�椤甸潰 - 鎼滅储鍘嗗彶 + 鐑�棬鎼滅储
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
      // 杩斿洖鎸夐挳
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(20)
        .fontColor([this.currentColors.onSurface])
        .onClick(() => {
          try { goBack(); } catch (e) { logger.error('[OnlineSearch] back failed', e); }
        })
        .margin({ right: 12 })

      // 鎼滅储锟?
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

      // 绛涢€夋寜锟?
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
        // 鐑�棬鎼滅储
        this.buildHotSearches()

        // 鎼滅储鍘嗗彶
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

        Text('鐑�棬鎼滅储')
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
            // 灏侀潰楠ㄦ灦
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
      // 缁撴灉缁熻�
      Row() {
        Text('鎵惧埌 ' + this.searchResults.length + ' 涓�粨锟?)
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.onSurfaceVariant)

        Blank()

        // 鎺掑簭閫夐」
        Text(this.sortBy === 'relevance' ? '鐩稿叧锟? : this.sortBy === 'name' ? '涔﹀悕' : '浣滐拷?)
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.primary)
          .onClick(() => this.toggleSort())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 缁撴灉鍒楄〃
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
      // 灏侀潰鍗犱綅
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

      // 鍙崇�锟?
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

      Text('璇曡瘯鍏朵粬鍏抽敭璇嶅惂')
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
          Text('娓呯┖')
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
        Text('鏆傛棤鎼滅储鍘嗗彶')
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

      // 淇濆瓨鍒板巻锟?
      await this.saveToHistory(this.searchKeyword.trim());
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      logger.error('[OnlineSearch] Search failed:', message);
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

    // 绛涢€変功锟?
    if (this.filterSource !== 'all') {
      results = results.filter(r => r.sourceId === this.filterSource);
    }

    // 鎺掑簭
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

  // ==================== 鎼滅储鍘嗗彶绠＄悊 ====================
  @State private pageContext: common.Context | null = null;

  private async loadSearchHistory(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext()!;
      const pref: preferences.Preferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      const historyJson: string = await pref.get('search_history', '[]') as string;
      this.searchHistory = JSON.parse(historyJson) as string[];
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      logger.error('[OnlineSearch] Load history failed:', message);
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
      logger.error('[OnlineSearch] Save history failed:', message);
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
      logger.error('[OnlineSearch] Clear history failed:', message);
    }
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct OnlineSearchPagePreview {
  build() {
    Column() {
      Text('鍦ㄧ嚎鎼滅储锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      OnlineSearchPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鍦ㄧ嚎鎼滅储锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      OnlineSearchPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
