/**
 * MainPage ViewModel - V2 version
 * 
 * Manages all states for main page, using @ObservedV2 for fine-grained state updates
 */

import { BookInfo, BookshelfGroup } from '../models/CoreBookModel';
import { bookViewModel } from './BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';
import { dynamicCoverService, BookCoverData, CoverStyle, AnimationType } from '../services/image/DynamicCoverService';
import { imageCacheService } from '../services/image/ImageCacheService';

@ObservedV2
export class MainPageViewModel {
  @Trace currentTab: number = 0;

  @Trace isDarkMode: boolean = false;
  @Trace isTablet: boolean = false;
  @Trace isLandscape: boolean = false;
  @Trace isInitialized: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;

  @Trace bookList: BookInfo[] = [];
  @Trace displayBooks: BookInfo[] = [];
  @Trace recentBooks: BookInfo[] = [];
  @Trace currentFilter: number = 0;
  @Trace currentGroupId: string = 'all';
  @Trace currentSortMode: number = 0;
  @Trace gridColumns: number = 3;
  @Trace coverDataMap: Map<string, BookCoverData> = new Map();

  @Trace searchText: string = '';
  @Trace showSearchBar: boolean = false;
  searchTimer: number = -1;

  @Trace isBatchMode: boolean = false;
  @Trace selectedBooks: Set<string> = new Set();
  @Trace showBatchBar: boolean = false;

  @Trace groups: BookshelfGroup[] = [];
  @Trace showGroupPanel: boolean = false;
  @Trace showAddGroupDialog: boolean = false;
  @Trace newGroupName: string = '';

  @Trace showSmartServices: boolean = false;

  @Trace isLoading: boolean = false;
  @Trace hasMore: boolean = true;
  @Trace loadedCount: number = 0;
  pageSize: number = 21;

  unsubscribeBooks: (() => void) | null = null;
  unsubscribeGroups: (() => void) | null = null;
  context: Context | null = null;

  async initApp(context: Context): Promise<void> {
    this.context = context;
    try {
      await preferenceManager.init(context);
      appTheme.init(context);
      DeviceUtils.init();
      fontScaleManager.init(context);
      await imageCacheService.init(context);

      this.isDarkMode = appTheme.isDarkMode();
      this.isTablet = DeviceUtils.isTablet();
      this.isLandscape = DeviceUtils.isLandscape();
      this.gridColumns = this.isTablet ? 5 : 3;
      this.pageSize = this.isTablet ? 30 : 21;
      this.currentColors = themeManager.getColors();

      appTheme.subscribe(() => {
        this.isDarkMode = appTheme.isDarkMode();
        this.currentColors = themeManager.getColors();
      });

      this.fontScale = await fontScaleManager.getFontScale();
      this.loadBooks();
      this.loadGroups();

      this.unsubscribeBooks = bookViewModel.subscribe((books: BookInfo[]) => {
        this.loadBooks();
      });

      this.unsubscribeGroups = bookViewModel.subscribeGroups((groups: BookshelfGroup[]) => {
        this.groups = groups;
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('MainPage init error:', message);
    } finally {
      this.isInitialized = true;
    }
  }

  cleanup(): void {
    if (this.unsubscribeBooks) {
      this.unsubscribeBooks();
    }
    if (this.unsubscribeGroups) {
      this.unsubscribeGroups();
    }
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
  }

  loadBooks(): void {
    const allBooks = bookViewModel.getAllBooks();
    const lastReadSorted = allBooks
      .filter((book) => book.lastReadTime > 0)
      .sort((a, b) => b.lastReadTime - a.lastReadTime);
    
    this.recentBooks = lastReadSorted.slice(0, 6);
    this.bookList = this.getFilteredBooks();
    this.displayBooks = this.bookList.slice(0, this.pageSize);
    this.loadedCount = this.displayBooks.length;
    this.hasMore = this.bookList.length > this.pageSize;
    this.coverDataMap.clear();
  }

  loadGroups(): void {
    this.groups = bookViewModel.getAllGroups();
  }

  private getFilteredBooks(): BookInfo[] {
    let books = bookViewModel.getAllBooks();

    if (this.currentGroupId !== 'all') {
      books = books.filter((book) => 
        book.groupIds && book.groupIds.includes(this.currentGroupId)
      );
    }

    switch (this.currentSortMode) {
      case 1:
        books.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
        break;
      case 2:
        books.sort((a, b) => (b.title || '').localeCompare(a.title || ''));
        break;
      case 3:
        books.sort((a, b) => b.addTime - a.addTime);
        break;
      case 4:
        books.sort((a, b) => a.addTime - b.addTime);
        break;
      case 5:
        books.sort((a, b) => b.lastReadTime - a.lastReadTime);
        break;
    }

    return books;
  }

  getCoverData(bookId: string): BookCoverData {
    if (this.coverDataMap.has(bookId)) {
      const data = this.coverDataMap.get(bookId);
      if (data) {
        return data;
      }
    }

    const book = this.bookList.find((b) => b.id === bookId);
    if (book) {
      const coverData = dynamicCoverService.generateCoverData(book.title, book.author, book.id);
      this.coverDataMap.set(bookId, coverData);
      return coverData;
    }

    return {
      id: bookId,
      title: '',
      author: '',
      style: CoverStyle.ABSTRACT,
      colors: ['#000000', '#FFFFFF'],
      animationType: AnimationType.NONE
    };
  }

  loadMoreBooks(): void {
    if (this.hasMore) {
      const newEnd = this.loadedCount + this.pageSize;
      this.displayBooks = this.bookList.slice(0, newEnd);
      this.loadedCount = this.displayBooks.length;
      this.hasMore = this.loadedCount < this.bookList.length;
    }
  }

  searchBooks(keyword: string): void {
    this.searchText = keyword;
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }

    this.searchTimer = setTimeout(() => {
      if (this.searchText.trim() === '') {
        this.loadBooks();
        return;
      }

      const allBooks = bookViewModel.getAllBooks();
      const lowerKeyword = this.searchText.toLowerCase();
      const filtered = allBooks.filter((b) => {
        const titleMatch = b.title && b.title.toLowerCase().includes(lowerKeyword);
        const authorMatch = b.author && b.author.toLowerCase().includes(lowerKeyword);
        return titleMatch || authorMatch;
      });

      this.bookList = filtered;
      this.displayBooks = this.bookList.slice(0, this.pageSize);
      this.loadedCount = this.displayBooks.length;
      this.hasMore = this.bookList.length > this.pageSize;
    }, 300);
  }

  setTab(tab: number): void {
    this.currentTab = tab;
  }

  toggleBatchMode(): void {
    this.isBatchMode = !this.isBatchMode;
    if (!this.isBatchMode) {
      this.selectedBooks.clear();
    }
  }

  toggleSelectBook(bookId: string): void {
    if (this.selectedBooks.has(bookId)) {
      this.selectedBooks.delete(bookId);
    } else {
      this.selectedBooks.add(bookId);
    }
  }

  selectAll(): void {
    this.displayBooks.forEach((book) => this.selectedBooks.add(book.id));
  }

  deselectAll(): void {
    this.selectedBooks.clear();
  }

  async deleteSelectedBooks(): Promise<void> {
    const idsArray = Array.from(this.selectedBooks);
    for (let i = 0; i < idsArray.length; i++) {
      await bookViewModel.deleteBook(idsArray[i]);
    }
    this.selectedBooks.clear();
    this.isBatchMode = false;
    this.loadBooks();
  }

  async addGroup(name: string): Promise<void> {
    if (name.trim()) {
      bookViewModel.createGroup(name.trim(), '#000000');
      this.loadGroups();
    }
  }

  async deleteGroup(groupId: string): Promise<void> {
    await bookViewModel.deleteGroup(groupId);
    if (this.currentGroupId === groupId) {
      this.currentGroupId = 'all';
    }
    this.loadGroups();
    this.loadBooks();
  }

  setCurrentGroup(groupId: string): void {
    this.currentGroupId = groupId;
    this.loadBooks();
  }

  setSortMode(mode: number): void {
    this.currentSortMode = mode;
    this.loadBooks();
  }

  setFilter(filter: number): void {
    this.currentFilter = filter;
    this.loadBooks();
  }
}

export const mainPageViewModel = new MainPageViewModel();