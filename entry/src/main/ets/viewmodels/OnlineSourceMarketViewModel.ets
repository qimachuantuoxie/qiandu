/**
 * 鍦ㄧ嚎涔︽簮甯傚満 ViewModel
 * 绠＄悊鍦ㄧ嚎涔︽簮鐨勬祻瑙堛€佹悳绱€佹祴璇曘€佸鍏?
 */

interface OnlineSourceInfo {
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
 * 鍦ㄧ嚎涔︽簮甯傚満 ViewModel
 * 浣跨敤 V2 鐘舵€佺鐞?
 */
@ObservedV2
export class OnlineSourceMarketViewModel {
  // ==================== 鏁版嵁鐘舵€?====================
  @Trace sources: OnlineSourceInfo[] = [];
  @Trace categories: string[] = [];
  @Trace isLoading: boolean = false;
  @Trace isLoadingMore: boolean = false;
  @Trace errorMsg: string = '';

  // ==================== 鎼滅储鍜岀瓫閫?====================
  @Trace searchText: string = '';
  @Trace selectedCategory: string = 'all';
  @Trace sortBy: string = 'download';

  // ==================== 鍒嗛〉鐘舵€?====================
  @Trace currentPage: number = 1;
  @Trace pageSize: number = 20;
  @Trace hasMore: boolean = true;
  @Trace totalCount: number = 0;

  // ==================== 鎵归噺鎿嶄綔 ====================
  @Trace selectedIds: Set<string> = new Set();
  @Trace isBatchMode: boolean = false;

  // ==================== 娴嬭瘯鐘舵€?====================
  @Trace testingIds: Set<string> = new Set();
  @Trace testResults: Map<string, { success: boolean; time?: number }> = new Map();

  /**
   * 鍔犺浇涔︽簮鍒楄〃
   */
  async loadSources(reset: boolean = false): Promise<void> {
    if (reset) {
      this.currentPage = 1;
      this.sources = [];
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      // TODO: 瀹為檯搴斾粠API鑾峰彇
      this.sources = [];
      this.hasMore = false;
      this.totalCount = 0;
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 鎼滅储涔︽簮
   */
  async searchSources(keyword: string): Promise<void> {
    this.searchText = keyword;
    await this.loadSources(true);
  }

  /**
   * 閫夋嫨/鍙栨秷閫夋嫨涔︽簮
   */
  selectSource(id: string): void {
    if (this.selectedIds.has(id)) {
      this.selectedIds.delete(id);
    } else {
      this.selectedIds.add(id);
    }
  }

  /**
   * 鍏ㄩ€?鍙栨秷鍏ㄩ€?
   */
  toggleSelectAll(): void {
    if (this.selectedIds.size === this.sources.length) {
      this.selectedIds.clear();
    } else {
      for (let i = 0; i < this.sources.length; i++) {
        this.selectedIds.add(this.sources[i].id);
      }
    }
  }

  /**
   * 娓呯┖閫夋嫨
   */
  clearSelection(): void {
    this.selectedIds.clear();
  }

  /**
   * 娴嬭瘯涔︽簮
   */
  async testSource(id: string): Promise<boolean> {
    this.testingIds.add(id);
    
    try {
      const startTime = Date.now();
      // TODO: 瀹為檯娴嬭瘯閫昏緫
      await new Promise(resolve => setTimeout(resolve, 1000));
      const success = true;
      const time = Date.now() - startTime;
      
      this.testResults.set(id, { success, time });
      return success;
    } catch (error) {
      const err = error as Error;
      this.testResults.set(id, { success: false });
      return false;
    } finally {
      this.testingIds.delete(id);
    }
  }

  /**
   * 鎵归噺娴嬭瘯涔︽簮
   */
  async batchTestSources(): Promise<void> {
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      await this.testSource(idsArray[i]);
    }
  }

  /**
   * 瀵煎叆閫変腑鐨勪功婧?
   */
  async importSelected(): Promise<number> {
    let importedCount = 0;
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      try {
        // TODO: 瀹為檯瀵煎叆閫昏緫
        importedCount++;
      } catch (error) {
        const err = error as Error;
      }
    }

    return importedCount;
  }

  /**
   * 鍔犺浇鏇村
   */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoadingMore) return;
    
    this.isLoadingMore = true;
    this.currentPage++;
    
    try {
      // TODO: 鍔犺浇涓嬩竴椤?
      this.hasMore = false;
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isLoadingMore = false;
    }
  }

  /**
   * 閲嶇疆鐘舵€?
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
}

export const onlineSourceMarketViewModel = new OnlineSourceMarketViewModel();
export default onlineSourceMarketViewModel;
