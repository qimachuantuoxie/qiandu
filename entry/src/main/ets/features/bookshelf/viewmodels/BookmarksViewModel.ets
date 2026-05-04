/**
 * BookmarksPage ViewModel - V2閻楀牊婀?
 */
import { BookInfo, Bookmark } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';

@ObservedV2
export class BookmarksViewModel {
  @Trace bookmarks: Bookmark[] = [];
  @Trace selectedBookId: string = '';
  @Trace isLoading: boolean = false;
  @Trace searchText: string = '';

  init(): void {
    this.loadBookmarks();
  }

  loadBookmarks(): void {
    if (this.selectedBookId) {
      this.bookmarks = bookViewModel.getBookmarks(this.selectedBookId) || [];
    } else {
      this.bookmarks = bookViewModel.getAllBookmarks() || [];
    }
  }

  /**
   * 鑾峰彇杩囨护鍚庣殑涔︾鍒楄〃 (getter 鏂规硶锛屼笉鍐嶄娇鐢?@Trace 娲剧敓灞炴€?
   */
  getFilteredBookmarks(): Bookmark[] {
    if (this.searchText.trim() === '') {
      const filtered: Bookmark[] = [];
      for (let i = 0; i < this.bookmarks.length; i++) {
        filtered.push(this.bookmarks[i]);
      }
      return filtered;
    } else {
      const keyword = this.searchText.toLowerCase();
      const filtered: Bookmark[] = [];
      for (let i = 0; i < this.bookmarks.length; i++) {
        const b = this.bookmarks[i];
        if (b.note && b.note.toLowerCase().includes(keyword)) {
          filtered.push(b);
        }
      }
      return filtered;
    }
  }

  search(keyword: string): void {
    this.searchText = keyword;
  }

  setBook(bookId: string): void {
    this.selectedBookId = bookId;
    this.loadBookmarks();
  }

  async deleteBookmark(bookId: string, bookmarkId: string): Promise<void> {
    await bookViewModel.deleteBookmark(bookId, bookmarkId);
    this.loadBookmarks();
  }
}

export const bookmarksViewModel = new BookmarksViewModel();
