/**
 * ComicReaderPage ViewModel - V2閻楀牊婀?
 */
import { BookInfo } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';

@ObservedV2
export class ComicReaderViewModel {
  @Trace book: BookInfo | null = null;
  @Trace currentPage: number = 0;
  @Trace totalPages: number = 0;
  @Trace images: string[] = [];
  @Trace isLoading: boolean = false;
  @Trace showControls: boolean = false;
  @Trace scale: number = 1.0;
  @Trace fitMode: string = 'width';

  async init(bookId: string): Promise<void> {
    this.isLoading = true;
    this.book = bookViewModel.getBookById(bookId) || null;
    if (this.book) {
      this.totalPages = this.book.totalPages ? this.book.totalPages : 0;
      this.currentPage = this.book.currentPage || 0;
    }
    this.isLoading = false;
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.saveProgress();
    }
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.saveProgress();
    }
  }

  goToPage(page: number): void {
    if (page >= 0 && page < this.totalPages) {
      this.currentPage = page;
      this.saveProgress();
    }
  }

  private saveProgress(): void {
    if (this.book) {
      bookViewModel.updateReadingProgress(this.book.id, this.currentPage, 0);
    }
  }

  toggleControls(): void {
    this.showControls = !this.showControls;
  }

  setScale(scale: number): void {
    this.scale = Math.max(0.5, Math.min(3.0, scale));
  }

  setFitMode(mode: string): void {
    this.fitMode = mode;
  }
}

export const comicReaderViewModel = new ComicReaderViewModel();
