/**
 * 閫氱敤 LazyForEach 鏁版嵁婧?
 * 鏇夸唬 ForEach锛屽疄鐜伴暱鍒楄〃鎸夐渶娓叉煋
 */

export interface DataChangeListener {
  onDataReloaded(): void;
  onDataAdded(index: number): void;
  onDataChanged(index: number): void;
  onDataDeleted(index: number): void;
}

export interface BookRecord {
  id: string;
  title: string;
  author: string;
}

export class LazyDataSource {
  private dataList: BookRecord[] = [];
  private listener: DataChangeListener | undefined = undefined;
  private isLoading: boolean = false;
  private hasMore: boolean = true;
  private onLoadMore: ((page: number) => Promise<BookRecord[]>) | undefined;
  private currentPage: number = 1;
  private pageSize: number = 20;

  constructor(onLoadMore?: (page: number) => Promise<BookRecord[]>, pageSize: number = 20) {
    this.onLoadMore = onLoadMore;
    this.pageSize = pageSize;
  }

  totalCount(): number {
    return this.dataList.length;
  }

  getData(index: number): BookRecord | undefined {
    const item = this.dataList[index];
    if (this.onLoadMore && !this.isLoading && this.hasMore && index >= this.dataList.length - 5) {
      this.loadNextPage();
    }
    return item;
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener;
  }

  unregisterDataChangeListener(): void {
    this.listener = undefined;
  }

  async refresh(): Promise<void> {
    this.dataList = [];
    this.currentPage = 1;
    this.hasMore = true;
    if (this.onLoadMore) {
      await this.loadNextPage();
    } else {
      this.notifyDataReloaded();
    }
  }

  private async loadNextPage(): Promise<void> {
    if (this.isLoading || !this.hasMore || !this.onLoadMore) return;
    this.isLoading = true;
    try {
      const newData = await this.onLoadMore(this.currentPage);
      if (newData.length > 0) {
        this.dataList = this.dataList.concat(newData);
        this.currentPage++;
        this.notifyDataReloaded();
      } else {
        this.hasMore = false;
      }
    } catch (e) {
      console.error('[LazyDataSource] Load more failed:', e);
    } finally {
      this.isLoading = false;
    }
  }

  private notifyDataReloaded(): void {
    if (this.listener) {
      this.listener.onDataReloaded();
    }
  }
}
