/**
 * EnhancedReaderPage ViewModel - V2閻楀牊婀?
 */
import { BookInfo, Bookmark, Note } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { readerSettingsViewModel } from './ReaderSettingsViewModel';
import { appTheme, themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';

@ObservedV2
export class EnhancedReaderViewModel {
  @Trace book: BookInfo | null = null;
  @Trace currentPage: number = 0;
  @Trace totalPages: number = 0;
  @Trace content: string = '';
  @Trace chapters: string[] = [];
  @Trace currentChapterIndex: number = 0;
  @Trace isLoading: boolean = false;
  @Trace showControls: boolean = false;
  @Trace showBookmarkPanel: boolean = false;
  @Trace showNotePanel: boolean = false;
  @Trace bookmarks: Bookmark[] = [];
  @Trace notes: Note[] = [];
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace isDarkMode: boolean = false;
  @Trace isTablet: boolean = false;

  async init(bookId: string): Promise<void> {
    this.isLoading = true;
    this.book = bookViewModel.getBook(bookId);
    if (this.book) {
      this.currentPage = this.book.currentPage || 0;
      this.totalPages = this.book.totalPages || 0;
    }
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet();
    this.loadBookmarks(bookId);
    this.loadNotes(bookId);
    this.isLoading = false;
  }

  loadBookmarks(bookId: string): void {
    this.bookmarks = bookViewModel.getBookmarks(bookId) || [];
  }

  loadNotes(bookId: string): void {
    this.notes = bookViewModel.getNotes(bookId) || [];
  }

  async saveProgress(): Promise<void> {
    if (this.book) {
      bookViewModel.updateReadingProgress(this.book.id, this.currentPage, 0);
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      if (this.book) {
        bookViewModel.updateReadingProgress(this.book.id, this.currentPage, 0);
      }
    }
  }

  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      if (this.book) {
        bookViewModel.updateReadingProgress(this.book.id, this.currentPage, 0);
      }
    }
  }

  goToPage(page: number): void {
    if (page >= 0 && page < this.totalPages) {
      this.currentPage = page;
      if (this.book) {
        bookViewModel.updateReadingProgress(this.book.id, this.currentPage, 0);
      }
    }
  }

  toggleControls(): void {
    this.showControls = !this.showControls;
  }

  toggleBookmarkPanel(): void {
    this.showBookmarkPanel = !this.showBookmarkPanel;
    if (this.showBookmarkPanel) this.showNotePanel = false;
  }

  toggleNotePanel(): void {
    this.showNotePanel = !this.showNotePanel;
    if (this.showNotePanel) this.showBookmarkPanel = false;
  }

  async addBookmark(noteText: string): Promise<void> {
    if (this.book) {
      bookViewModel.addBookmark(this.book.id, this.currentPage, '涔︾', noteText);
      this.loadBookmarks(this.book.id);
    }
  }

  async addNote(content: string): Promise<void> {
    if (this.book) {
      bookViewModel.addNote(this.book.id, this.currentPage, content);
      this.loadNotes(this.book.id);
    }
  }
}

export const enhancedReaderViewModel = new EnhancedReaderViewModel();
