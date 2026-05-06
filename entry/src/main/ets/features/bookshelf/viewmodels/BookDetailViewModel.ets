/**
 * BookDetailPage ViewModel - V2鐗堟湰
 */
import { BookInfo, BookshelfGroup } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { appTheme, themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { dynamicCoverService, BookCoverData } from '../../../core/services/image/DynamicCoverService';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
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
    if (!this.book) return;
    const newFavorite = !this.isFavorite;
    this.isFavorite = newFavorite;
    const updatedBook = Object.assign({}, this.book, { isFavorite: newFavorite });
    bookViewModel.updateBook(updatedBook);
    this.book = updatedBook;
  }
}

export const bookDetailViewModel = new BookDetailViewModel();
