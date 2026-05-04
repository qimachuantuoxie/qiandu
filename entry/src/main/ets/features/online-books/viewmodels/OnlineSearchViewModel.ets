/**
 * OnlineSearchPage ViewModel - V2閻楀牊婀?
 */
import { bookSourceViewModel } from './BookSourceViewModel';
import { SourceBookInfo } from '../models/BookSourceModel';

@ObservedV2
export class OnlineSearchViewModel {
  @Trace searchKeyword: string = '';
  @Trace results: SourceBookInfo[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace selectedSourceId: string = '';
  @Trace page: number = 1;
  @Trace hasMore: boolean = true;

  async search(keyword: string): Promise<void> {
    if (!keyword.trim()) return;

    this.searchKeyword = keyword;
    this.isLoading = true;
    this.errorMsg = '';
    this.page = 1;

    try {
      // TODO: 鐎圭偟骞囬崷銊у殠閹兼粎鍌ㄩ崝鐔诲厴
      this.results = [];
      this.hasMore = false;
    } catch (error) {
      this.errorMsg = '閹兼粎鍌ㄦ径杈Е閿涘矁顕柌宥堢槸';
    } finally {
      this.isLoading = false;
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) return;

    this.isLoading = true;
    this.page++;

    try {
      // TODO: 鐎圭偟骞囬崷銊у殠閹兼粎鍌ㄩ崝鐔诲厴
      this.hasMore = false;
    } catch (error) {
      this.page--;
    } finally {
      this.isLoading = false;
    }
  }

  setSource(sourceId: string): void {
    this.selectedSourceId = sourceId;
    if (this.searchKeyword) {
      this.search(this.searchKeyword);
    }
  }

  clear(): void {
    this.searchKeyword = '';
    this.results = [];
    this.page = 1;
    this.hasMore = true;
  }
}

export const onlineSearchViewModel = new OnlineSearchViewModel();
