/**
 * BookDetailPage ViewModel - V2版本
 */
import { BookInfo, BookshelfGroup } from '../models/CoreBookModel';
import { bookViewModel } from './BookViewModel';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { dynamicCoverService, BookCoverData } from '../services/image/DynamicCoverService';
import { DeviceUtils } from '../utils/DeviceUtils';
import { common } from '@kit.AbilityKit';

@ObservedV2
export class BookDetailViewModel {
  @Trace book: BookInfo | null = null;
  @Trace isFavorite: boolean = false;
  @Trace isTablet: boolean = false;
  @Trace isDarkMode: boolean = false;
  @Trace coverData: BookCoverData | null = null;
  @Trace showMoreMenu: boolean = false;
  @Trace showGroupSheet: boolean = false;
  @Trace groups: BookshelfGroup[] = [];
  @Trace bookGroups: string[] = [];
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  unsubscribe: (() => void) | null = null;
  groupUnsubscribe: (() => void) | null = null;

  async init(context: common.Context, bookId: string): Promise<void> {
    await fontScaleManager.init(context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadBookData(bookId);
    this.loadGroups();
  }

  loadBookData(bookId: string): void {
    const book = bookViewModel.getBook(bookId);
    if (book) {
      this.book = book;
      this.isFavorite = book.isFavorite;
      this.coverData = dynamicCoverService.generateCoverData(book.title, book.author, book.id);
    } else {
      this.book = null;
      this.isFavorite = false;
      this.coverData = null;
    }
  }

  loadGroups(): void {
    this.groups = bookViewModel.getAllGroups();
  }

  cleanup(): void {
    if (this.unsubscribe) this.unsubscribe();
    if (this.groupUnsubscribe) this.groupUnsubscribe();
  }

  toggleFavorite(): void {
    if (this.book) {
      const newFavorite = !this.isFavorite;
      this.isFavorite = newFavorite;
      const updatedBook: BookInfo = {
        id: this.book.id,
        title: this.book.title,
        author: this.book.author,
        coverUrl: this.book.coverUrl,
        description: this.book.description,
        status: this.book.status,
        currentPage: this.book.currentPage,
        totalPages: this.book.totalPages,
        readProgress: this.book.readProgress,
        isFavorite: newFavorite,
        addTime: this.book.addTime,
        lastReadTime: this.book.lastReadTime,
        totalReadTime: this.book.totalReadTime,
        chapters: this.book.chapters,
        tags: this.book.tags,
        groupIds: this.book.groupIds,
        format: this.book.format,
        filePath: this.book.filePath
      };
      bookViewModel.updateBook(updatedBook);
      this.book = updatedBook;
    }
  }
}

export const bookDetailViewModel = new BookDetailViewModel();
