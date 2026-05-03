/**
 * SourceMarket ViewModel - 鐙珛鐗堟湰锛岄€傞厤 LegadoSourceMarket 鏈嶅姟
 * 浣跨敤 V2 鐘舵€佺鐞嗘ā寮?
 */

import { legadoSourceMarket as legadoMarket, SourceMarketItem, SourceMarketCategory, SourceMarketSort, MarketQueryResult, QueryParams } from '../services/book/LegadoSourceMarket';
import { bookSourceViewModel, ImportResult } from '../viewmodels/BookSourceViewModel';
import { BookSource } from '../models/BookSourceModel';
import { toast } from '../utils/ToastHelper';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@ObservedV2
export class SourceMarketViewModel {
  // ==================== 鏁版嵁鐘舵€?====================
  @Trace marketItems: SourceMarketItem[] = [];
  @Trace isLoading: boolean = false;
  @Trace currentPage: number = 1;
  @Trace totalItems: number = 0;

  // ==================== 绛涢€夌姸鎬?====================
  @Trace selectedCategory: SourceMarketCategory = SourceMarketCategory.ALL;
  @Trace selectedSort: SourceMarketSort = SourceMarketSort.RECOMMENDED;
  @Trace searchKeyword: string = '';

  // ==================== UI鐘舵€?====================
  @Trace showSearch: boolean = false;
  @Trace downloadedIds: string[] = [];
  @Trace showUrlInput: boolean = false;
  @Trace customSourceUrl: string = '';

  // ==================== 甯搁噺 ====================
  private pageSize: number = 20;
  readonly ALL_CATEGORIES: SourceMarketCategory[] = [
    SourceMarketCategory.ALL,
    SourceMarketCategory.FEATURED,
    SourceMarketCategory.MALE,
    SourceMarketCategory.FEMALE,
    SourceMarketCategory.COMIC,
    SourceMarketCategory.AUDIO,
    SourceMarketCategory.AGGREGATE
  ];

  /**
   * 初始化 ViewModel
   */
  async init(context: common.Context): Promise<void> {
    try {
      await legadoMarket.init(context);
      this.downloadedIds = await legadoMarket.getDownloadedSourceIds();
      await this.loadData(true);
    } catch (error) {
      const err = error as Error;
      console.error('[SourceMarketVM] Init failed:', err.message);
      promptAction.showToast({
        message: '初始化失败，请重试',
        duration: 2000
      });
    }
  }

  /**
   * 加载数据
   */
  async loadData(refresh: boolean = false): Promise<void> {
    if (this.isLoading) return;

    if (refresh) {
      this.currentPage = 1;
      this.marketItems = [];
    }

    this.isLoading = true;

    try {
      let result: MarketQueryResult;

      if (this.searchKeyword) {
        result = await legadoMarket.searchSources(
          this.searchKeyword,
          this.currentPage,
          this.pageSize
        );
      } else if (this.selectedCategory !== SourceMarketCategory.ALL) {
        result = await legadoMarket.getSourcesByCategory(
          this.selectedCategory,
          this.currentPage,
          this.pageSize
        );
      } else {
        const params: QueryParams = {
          sort: this.selectedSort,
          page: this.currentPage,
          pageSize: this.pageSize
        };
        result = await legadoMarket.querySources(params);
      }

      if (result && result.items) {
        if (refresh) {
          this.marketItems = result.items;
        } else {
          const newItems: SourceMarketItem[] = [];
          for (let i = 0; i < this.marketItems.length; i++) {
            newItems.push(this.marketItems[i]);
          }
          for (let i = 0; i < result.items.length; i++) {
            newItems.push(result.items[i]);
          }
          this.marketItems = newItems;
        }

        this.totalItems = result.total ? result.total : 0;
      }
    } catch (error) {
      const err = error as Error;
      console.error('[SourceMarketVM] Load data failed:', err.message);
      promptAction.showToast({
        message: '加载失败，请检查网络后重试',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 切换分类
   */
  async onCategoryChange(category: SourceMarketCategory): Promise<void> {
    this.selectedCategory = category;
    await this.loadData(true);
  }

  /**
   * 切换排序
   */
  async onSortChange(sort: SourceMarketSort): Promise<void> {
    this.selectedSort = sort;
    await this.loadData(true);
  }

  /**
   * 搜索
   */
  async onSearch(keyword: string): Promise<void> {
    this.searchKeyword = keyword;
    await this.loadData(true);
  }

  /**
   * 加载更多
   */
  async loadMore(): Promise<void> {
    this.currentPage++;
    await this.loadData(false);
  }

  /**
   * 下载并导入书源
   */
  async onDownloadSource(item: SourceMarketItem): Promise<void> {
    try {
      console.info('[SourceMarketVM] Downloading:', item.name);

      const sources: BookSource[] | null = await legadoMarket.downloadSourcePackage(item.marketId);

      if (sources && sources.length > 0) {
        let successCount = 0;
        let failCount = 0;

        for (let i = 0; i < sources.length; i++) {
          const source: BookSource = sources[i] as BookSource;
          try {
            if (bookSourceViewModel.addSource(source)) {
              successCount++;
            } else {
              failCount++;
            }
          } catch (error) {
            const err = error as Error;
            console.error('[SourceMarketVM] Add source failed:', err.message);
            failCount++;
          }
        }

        bookSourceViewModel.saveBookSources();

        let hasId = false;
        for (let i = 0; i < this.downloadedIds.length; i++) {
          if (this.downloadedIds[i] === item.marketId) {
            hasId = true;
            break;
          }
        }
        if (!hasId) {
          const newIds: string[] = [];
          for (let i = 0; i < this.downloadedIds.length; i++) {
            newIds.push(this.downloadedIds[i]);
          }
          newIds.push(item.marketId);
          this.downloadedIds = newIds;
        }

        let msg = '成功导入' + successCount + '个书源';
        if (failCount > 0) {
          msg += '，' + failCount + '个失败';
        }
        promptAction.showToast({
          message: msg,
          duration: 2000
        });
      } else {
        promptAction.showToast({
          message: '未找到可导入的书源',
          duration: 2000
        });
      }
    } catch (error) {
      const err = error as Error;
      console.error('[SourceMarketVM] Download failed:', err.message);
      promptAction.showToast({
        message: '下载失败，请检查网络后重试',
        duration: 2000
      });
    }
  }

  /**
   * 显示 URL 输入框
   */
  showUrlInputDialog(): void {
    this.showUrlInput = true;
    this.customSourceUrl = '';
  }

  /**
   * 隐藏 URL 输入框
   */
  hideUrlInputDialog(): void {
    this.showUrlInput = false;
  }

  /**
   * 从 URL 添加书源
   */
  async addSourceFromUrl(): Promise<void> {
    if (this.customSourceUrl.trim().length > 0) {
      try {
        const result: ImportResult = await bookSourceViewModel.importFromUrl(this.customSourceUrl);
        promptAction.showToast({
          message: '成功导入 ' + result.success + ' 个书源',
          duration: 2000
        });
        this.showUrlInput = false;
        this.customSourceUrl = '';
      } catch (error) {
        const err = error as Error;
        promptAction.showToast({
          message: '导入失败: ' + err.message,
          duration: 2000
        });
      }
    }
  }

  /**
   * 切换搜索框显示
   */
  toggleSearch(): void {
    this.showSearch = !this.showSearch;
  }

  /**
   * 获取分类名称
   */
  getCategoryName(category: SourceMarketCategory): string {
    switch (category) {
      case SourceMarketCategory.ALL: return '全部';
      case SourceMarketCategory.FEATURED: return '精品';
      case SourceMarketCategory.MALE: return '男频';
      case SourceMarketCategory.FEMALE: return '女频';
      case SourceMarketCategory.COMIC: return '漫画';
      case SourceMarketCategory.AUDIO: return '音频';
      case SourceMarketCategory.AGGREGATE: return '聚合';
      default: return '未知';
    }
  }

  /**
   * 格式化数字
   */
  formatNumber(num: number): string {
    if (num >= 10000) {
      return (num / 10000).toFixed(1) + 'w';
    } else if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
  }

  /**
   * 检查是否已下载
   */
  isDownloaded(marketId: string): boolean {
    return this.downloadedIds.includes(marketId);
  }

  /**
   * 重置状态
   */
  reset(): void {
    this.marketItems = [];
    this.isLoading = false;
    this.currentPage = 1;
    this.totalItems = 0;
    this.selectedCategory = SourceMarketCategory.ALL;
    this.selectedSort = SourceMarketSort.RECOMMENDED;
    this.searchKeyword = '';
    this.showSearch = false;
    this.downloadedIds = [];
    this.showUrlInput = false;
    this.customSourceUrl = '';
  }
}

export const sourceMarketViewModel = new SourceMarketViewModel();
export default sourceMarketViewModel;
