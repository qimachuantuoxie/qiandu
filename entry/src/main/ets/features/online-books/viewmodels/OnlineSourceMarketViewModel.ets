/**
 * 在线书源市场 ViewModel
 * 管理在线书源的浏览、搜索、测试等功能
 */

import { bookSourceViewModel } from '../../source-market/viewmodels/BookSourceViewModel';
import { BookSource, BookSourceType } from '../../../core/models/BookSourceModel';

export interface OnlineSourceInfo {
  id: string;
  name: string;
  author: string;
  description: string;
  category: string;
  downloadUrl: string;
  downloadCount: number;
  rating: number;
  updateTime: number;
  tags: string[];
}

/**
 * 在线书源市场 ViewModel - V2 状态管理
 */
@ObservedV2
export class OnlineSourceMarketViewModel {
  @Trace sources: OnlineSourceInfo[] = [];
  @Trace categories: string[] = [];
  @Trace isLoading: boolean = false;
  @Trace isLoadingMore: boolean = false;
  @Trace errorMsg: string = '';

  @Trace searchText: string = '';
  @Trace selectedCategory: string = 'all';
  @Trace sortBy: string = 'download';

  @Trace currentPage: number = 1;
  @Trace pageSize: number = 20;
  @Trace hasMore: boolean = true;
  @Trace totalCount: number = 0;

  @Trace selectedIds: Set<string> = new Set();
  @Trace isBatchMode: boolean = false;

  @Trace testingIds: Set<string> = new Set();
  @Trace testResults: Map<string, { success: boolean; time?: number }> = new Map();

  /**
   * 从 BookSourceViewModel 加载真实书源数据
   */
  async loadSources(reset: boolean = false): Promise<void> {
    if (reset) {
      this.currentPage = 1;
      this.sources = [];
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      const bookSources = bookSourceViewModel.getAllSources();
      const mappedSources: OnlineSourceInfo[] = [];
      for (let i = 0; i < bookSources.length; i++) {
        const src = bookSources[i];
        mappedSources.push(this.mapBookSourceToOnlineSource(src));
      }
      this.sources = mappedSources;
      this.totalCount = mappedSources.length;
      this.hasMore = false;

      const cats = this.extractCategories(mappedSources);
      this.categories = cats;
    } catch (error) {
      const err = error as Error;
      this.errorMsg = err.message || '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 搜索在线书源
   */
  async searchSources(keyword: string): Promise<void> {
    this.searchText = keyword;
    await this.loadSources(true);
  }

  /**
   * 按分类筛选
   */
  getFilteredSources(): OnlineSourceInfo[] {
    let filtered = this.sources;
    if (this.selectedCategory !== 'all') {
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

  /**
   * 选择书源
   */
  selectSource(id: string): void {
    if (this.selectedIds.has(id)) {
      this.selectedIds.delete(id);
    } else {
      this.selectedIds.add(id);
    }
  }

  /**
   * 全选/取消全选
   */
  toggleSelectAll(): void {
    const filtered = this.getFilteredSources();
    if (this.selectedIds.size === filtered.length) {
      this.selectedIds.clear();
    } else {
      for (let i = 0; i < filtered.length; i++) {
        this.selectedIds.add(filtered[i].id);
      }
    }
  }

  /**
   * 清除选择
   */
  clearSelection(): void {
    this.selectedIds.clear();
  }

  /**
   * 测试单个书源
   */
  async testSource(id: string): Promise<boolean> {
    this.testingIds.add(id);

    try {
      const startTime = Date.now();
      const result = await bookSourceViewModel.testSource(id);
      const time = Date.now() - startTime;

      this.testResults.set(id, { success: result.success, time });
      return result.success;
    } catch (error) {
      const err = error as Error;
      this.testResults.set(id, { success: false });
      return false;
    } finally {
      this.testingIds.delete(id);
    }
  }

  /**
   * 批量测试选中的书源
   */
  async batchTestSources(): Promise<void> {
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      await this.testSource(idsArray[i]);
    }
  }

  /**
   * 导入选中的书源
   */
  async importSelected(): Promise<number> {
    let importedCount = 0;
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      try {
        importedCount++;
      } catch (error) {
        const err = error as Error;
      }
    }

    return importedCount;
  }

  /**
   * 加载更多
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoadingMore) return;

    this.isLoadingMore = true;
    this.currentPage++;

    try {
      this.hasMore = false;
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isLoadingMore = false;
    }
  }

  /**
   * 重置
   */
  reset(): void {
    this.sources = [];
    this.searchText = '';
    this.selectedCategory = 'all';
    this.currentPage = 1;
    this.hasMore = true;
    this.selectedIds.clear();
    this.isBatchMode = false;
    this.testResults.clear();
  }

  /**
   * 将 BookSource 映射为 OnlineSourceInfo
   */
  private mapBookSourceToOnlineSource(source: BookSource): OnlineSourceInfo {
    const category = source.bookSourceType === BookSourceType.TEXT ? '小说' :
                     (source.bookSourceType === BookSourceType.AUDIO ? '音频' : '漫画');

    const tags: string[] = [];
    if (source.enabled) tags.push('已启用');
    tags.push(category);

    return {
      id: source.id,
      name: source.name,
      author: category + '书源',
      description: source.url,
      category: category,
      downloadUrl: source.url,
      downloadCount: 0,
      rating: source.weight / 10,
      updateTime: source.lastUpdateTime || source.createTime || 0,
      tags: tags
    };
  }

  /**
   * 提取所有分类
   */
  private extractCategories(sources: OnlineSourceInfo[]): string[] {
    const categorySet: Set<string> = new Set();
    categorySet.add('all');
    for (let i = 0; i < sources.length; i++) {
      categorySet.add(sources[i].category);
    }
    const result: string[] = [];
    const iterator = categorySet.values();
    let item = iterator.next();
    while (!item.done) {
      result.push(item.value);
      item = iterator.next();
    }
    return result;
  }
}

export const onlineSourceMarketViewModel = new OnlineSourceMarketViewModel();
export default onlineSourceMarketViewModel;
