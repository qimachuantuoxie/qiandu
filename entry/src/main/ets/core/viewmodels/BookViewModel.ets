/**
 * 涔︾睄绠＄悊 ViewModel - 鍏煎灞? * 
 * 宸茶縼绉昏嚦 @hadss/state_store 鏋舵瀯
 * 鏂颁唬鐮佽鐩存帴浣跨敤 bookStore (from '../store/BookStore')
 * 姝ゆ枃浠朵繚鎸佸悜鍚庡吋瀹癸紝杞彂鍒?BookStore
 */

import { getBookFormatColor } from '../../design/tokens/ColorTokens';
import { bookStore, initializeBookStore, getAllBooksFromStore, getBookByIdFromStore, searchBooksInStore } from '../store/BookStore';
import { BookInfo, BookFormat, ReadStatus, Bookmark, Note, ReadRecord, BookshelfGroup, generateBookId, BooksMap, BookmarksMap, NotesMap, GroupsMap } from '../models/CoreBookModel';
import { preferenceManager } from '../utils/PreferenceManager';

// Re-export types for other files that import from this module
export {
  BookInfo,
  BookFormat,
  ReadStatus,
  Bookmark,
  Note,
  ReadRecord,
  BookshelfGroup,
  generateBookId,
  BooksMap,
  BookmarksMap,
  NotesMap,
  GroupsMap
};

export type SortOrderType = 'TITLE_ASC' | 'TITLE_DESC' | 'AUTHOR_ASC' | 'AUTHOR_DESC' | 'ADD_TIME_DESC' | 'ADD_TIME_ASC' | 'LAST_READ_DESC' | 'LAST_READ_ASC' | 'PROGRESS_DESC' | 'PROGRESS_ASC';

export interface SortOrderMap {
  TITLE_ASC: string;
  TITLE_DESC: string;
  AUTHOR_ASC: string;
  AUTHOR_DESC: string;
  ADD_TIME_DESC: string;
  ADD_TIME_ASC: string;
  LAST_READ_DESC: string;
  LAST_READ_ASC: string;
  PROGRESS_DESC: string;
  PROGRESS_ASC: string;
}

export const SortOrderValues: SortOrderMap = {
  TITLE_ASC: 'title_asc',
  TITLE_DESC: 'title_desc',
  AUTHOR_ASC: 'author_asc',
  AUTHOR_DESC: 'author_desc',
  ADD_TIME_DESC: 'add_time_desc',
  ADD_TIME_ASC: 'add_time_asc',
  LAST_READ_DESC: 'last_read_desc',
  LAST_READ_ASC: 'last_read_asc',
  PROGRESS_DESC: 'progress_desc',
  PROGRESS_ASC: 'progress_asc'
};

export interface PaginatedBooksResult {
  books: BookInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalPages?: number;
}

export interface AdvancedSearchOptions {
  searchTitle?: boolean;
  searchAuthor?: boolean;
  searchTags?: boolean;
  searchDescription?: boolean;
}

export type SortOrderType = 'TITLE_ASC' | 'TITLE_DESC' | 'AUTHOR_ASC' | 'AUTHOR_DESC' | 'ADD_TIME_DESC' | 'ADD_TIME_ASC' | 'LAST_READ_DESC' | 'LAST_READ_ASC' | 'PROGRESS_DESC' | 'PROGRESS_ASC';

export interface SortOrderMap {
  TITLE_ASC: string;
  TITLE_DESC: string;
  AUTHOR_ASC: string;
  AUTHOR_DESC: string;
  ADD_TIME_DESC: string;
  ADD_TIME_ASC: string;
  LAST_READ_DESC: string;
  LAST_READ_ASC: string;
  PROGRESS_DESC: string;
  PROGRESS_ASC: string;
}

export const SortOrderValues: SortOrderMap = {
  TITLE_ASC: 'title_asc',
  TITLE_DESC: 'title_desc',
  AUTHOR_ASC: 'author_asc',
  AUTHOR_DESC: 'author_desc',
  ADD_TIME_DESC: 'add_time_desc',
  ADD_TIME_ASC: 'add_time_asc',
  LAST_READ_DESC: 'last_read_desc',
  LAST_READ_ASC: 'last_read_asc',
  PROGRESS_DESC: 'progress_desc',
  PROGRESS_ASC: 'progress_asc'
};

export interface PaginatedBooksResult {
  books: BookInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalPages?: number;
}

export interface AdvancedSearchOptions {
  searchTitle?: boolean;
  searchAuthor?: boolean;
  searchTags?: boolean;
  searchDescription?: boolean;
}

/**
 * 涔︾睄瑙嗗浘妯″瀷
 * 绠＄悊鎵€鏈変功绫嶇浉鍏虫搷浣滐紝鍖呮嫭锛? * - 涔︾睄 CRUD 鎿嶄綔
 * - 鎼滅储鍜屾帓搴? * - 涔︾鍜岀瑪璁扮鐞? * - 闃呰璁板綍缁熻
 /**
 * 鍏煎灞傦細杞彂鍒?BookStore
 * 鏂颁唬鐮佽鐩存帴浣跨敤 bookStore
 */

/** 涔︾睄瀛楀吀 - 浠?store 鑾峰彇 */
const booksMap = (): BooksMap => bookStore.getState().books;

/** 涔︾睄ID鍒楄〃 - 浠?store 鑾峰彇 */
const bookKeys = (): string[] => bookStore.getState().bookKeys;

// ==================== 鍏煎鍗曚緥 ====================

class BookViewModelCompat {
  // 鍒濆鍖?  constructor() {
    initializeBookStore();
  }

  // ==================== 涔︾睄绠＄悊 ====================

  loadBooks(): void {
    initializeBookStore();
  }

  addBook(book: BookInfo): void {
    if (!book.id) book.id = generateBookId();
    bookStore.dispatch(ADD_BOOK, book);
  }

  deleteBook(bookId: string): void {
    bookStore.dispatch(DELETE_BOOK, bookId);
  }

  updateBook(book: BookInfo): void {
    bookStore.dispatch(UPDATE_BOOK, book);
  }

  getAllBooks(): BookInfo[] {
    return getAllBooksFromStore();
  }

  getBookById(bookId: string): BookInfo | undefined {
    return getBookByIdFromStore(bookId);
  }

  searchBooks(keyword: string): BookInfo[] {
    return searchBooksInStore(keyword);
  }

  getReadingBooks(): BookInfo[] {
    const all = getAllBooksFromStore();
    const result: BookInfo[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].status === ReadStatus.READING) result.push(all[i]);
    }
    return result;
  }

  getFavoriteBooks(): BookInfo[] {
    const all = getAllBooksFromStore();
    const result: BookInfo[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].isFavorite) result.push(all[i]);
    }
    return result;
  }

  getFinishedBooks(): BookInfo[] {
    const all = getAllBooksFromStore();
    const result: BookInfo[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].status === ReadStatus.FINISHED) result.push(all[i]);
    }
    return result;
  }

  getUnreadBooks(): BookInfo[] {
    const all = getAllBooksFromStore();
    const result: BookInfo[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].status === ReadStatus.UNREAD) result.push(all[i]);
    }
    return result;
  }

  static readonly SortOrder: SortOrderMap = SortOrderValues;

  sortBooks(books: BookInfo[], sortOrder: string): BookInfo[] {
    const sorted: BookInfo[] = [];
    for (let i = 0; i < books.length; i++) sorted.push(books[i]);
    switch (sortOrder) {
      case SortOrderValues.TITLE_ASC: sorted.sort((a, b) => a.title.localeCompare(b.title, 'zh-CN')); break;
      case SortOrderValues.TITLE_DESC: sorted.sort((a, b) => b.title.localeCompare(a.title, 'zh-CN')); break;
      case SortOrderValues.AUTHOR_ASC: sorted.sort((a, b) => a.author.localeCompare(b.author, 'zh-CN')); break;
      case SortOrderValues.AUTHOR_DESC: sorted.sort((a, b) => b.author.localeCompare(a.author, 'zh-CN')); break;
      case SortOrderValues.ADD_TIME_DESC: sorted.sort((a, b) => b.addTime - a.addTime); break;
      case SortOrderValues.ADD_TIME_ASC: sorted.sort((a, b) => a.addTime - b.addTime); break;
      case SortOrderValues.LAST_READ_DESC: sorted.sort((a, b) => b.lastReadTime - a.lastReadTime); break;
      case SortOrderValues.LAST_READ_ASC: sorted.sort((a, b) => a.lastReadTime - b.lastReadTime); break;
      case SortOrderValues.PROGRESS_DESC: sorted.sort((a, b) => b.readProgress - a.readProgress); break;
      case SortOrderValues.PROGRESS_ASC: sorted.sort((a, b) => a.readProgress - b.readProgress); break;
    }
    return sorted;
  }

  advancedSearch(keyword: string, options?: AdvancedSearchOptions): BookInfo[] {
    if (!keyword || keyword.trim().length === 0) return getAllBooksFromStore();
    const lowerKeyword = keyword.toLowerCase().trim();
    let searchTitle = true, searchAuthor = true, searchTags = true, searchDescription = false;
    if (options) {
      if (options.searchTitle !== undefined) searchTitle = options.searchTitle;
      if (options.searchAuthor !== undefined) searchAuthor = options.searchAuthor;
      if (options.searchTags !== undefined) searchTags = options.searchTags;
      if (options.searchDescription !== undefined) searchDescription = options.searchDescription;
    }
    const allBooks = getAllBooksFromStore();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (searchTitle && book.title.toLowerCase().includes(lowerKeyword)) { result.push(book); continue; }
      if (searchAuthor && book.author.toLowerCase().includes(lowerKeyword)) { result.push(book); continue; }
      if (searchTags && book.tags) {
        for (let j = 0; j < book.tags.length; j++) {
          if (book.tags[j].toLowerCase().includes(lowerKeyword)) { result.push(book); break; }
        }
      }
      if (searchDescription && book.description && book.description.toLowerCase().includes(lowerKeyword)) result.push(book);
    }
    return result;
  }

  getBooksPaginated(page: number, pageSize: number, sortOrder?: string): PaginatedBooksResult {
    let books = getAllBooksFromStore();
    if (sortOrder) books = this.sortBooks(books, sortOrder);
    const total = books.length;
    const totalPages = Math.ceil(total / pageSize);
    const start = (page - 1) * pageSize;
    const end = start + pageSize;
    const paginatedBooks: BookInfo[] = [];
    for (let i = start; i < end && i < books.length; i++) paginatedBooks.push(books[i]);
    return { books: paginatedBooks, total, page, pageSize, hasMore: end < books.length, totalPages };
  }

  updateReadingProgress(bookId: string, currentPage: number, duration: number): void {
    bookStore.dispatch(UPDATE_READING_PROGRESS, { bookId, currentPage, duration });
  }

  toggleFavorite(bookId: string): void {
    bookStore.dispatch(TOGGLE_FAVORITE, bookId);
  }

  // ==================== 涔︾绠＄悊 ====================

  addBookmark(bookId: string, pageNumber: number, title: string, note?: string): Bookmark {
    const bookmark: Bookmark = { id: generateBookId(), bookId, pageNumber, title, createTime: Date.now(), note };
    bookStore.dispatch(ADD_BOOKMARK, { bookId, bookmark });
    return bookmark;
  }

  deleteBookmark(bookId: string, bookmarkId: string): void {
    bookStore.dispatch(DELETE_BOOKMARK, { bookId, bookmarkId });
  }

  getBookmarks(bookId: string): Bookmark[] {
    return bookStore.getState().bookmarks.get(bookId) || [];
  }

  getAllBookmarks(): Bookmark[] {
    const state = bookStore.getState();
    const all: Bookmark[] = [];
    for (let i = 0; i < state.bookmarkKeys.length; i++) {
      const marks = state.bookmarks.get(state.bookmarkKeys[i]);
      if (marks) for (let j = 0; j < marks.length; j++) all.push(marks[j]);
    }
    return all;
  }

  // ==================== 绗旇绠＄悊 ====================

  addNote(bookId: string, pageNumber: number, content: string, highlight?: string, color?: string): Note {
    const note: Note = { id: generateBookId(), bookId, pageNumber, content, createTime: Date.now(), highlight, color };
    bookStore.dispatch(ADD_NOTE, { bookId, note });
    return note;
  }

  deleteNote(bookId: string, noteId: string): void {
    bookStore.dispatch(DELETE_NOTE, { bookId, noteId });
  }

  getNotes(bookId: string): Note[] {
    return bookStore.getState().notes.get(bookId) || [];
  }

  getAllNotes(): Note[] {
    const state = bookStore.getState();
    const all: Note[] = [];
    for (let i = 0; i < state.noteKeys.length; i++) {
      const notes = state.notes.get(state.noteKeys[i]);
      if (notes) for (let j = 0; j < notes.length; j++) all.push(notes[j]);
    }
    return all;
  }

  // ==================== 鍒嗙粍绠＄悊 ====================

  loadGroups(): void { initializeBookStore(); }

  addGroup(group: BookshelfGroup): void {
    if (!group.id) group.id = generateBookId();
    bookStore.dispatch(ADD_GROUP, group);
  }

  deleteGroup(groupId: string): void {
    bookStore.dispatch(DELETE_GROUP, groupId);
  }

  updateGroup(groupOrId: BookshelfGroup | string, updates?: Partial<BookshelfGroup>): void {
    bookStore.dispatch(UPDATE_GROUP, { groupOrId, updates });
  }

  getAllGroups(): BookshelfGroup[] {
    const state = bookStore.getState();
    const result: BookshelfGroup[] = [];
    for (let i = 0; i < state.groupKeys.length; i++) {
      const g = state.groups.get(state.groupKeys[i]);
      if (g) result.push(g);
    }
    return result;
  }

  // ==================== 闃呰璁板綍 ====================

  getAllReadRecords(): ReadRecord[] {
    return bookStore.getState().readRecords;
  }

  addReadRecord(record: ReadRecord): void {
    bookStore.dispatch(ADD_READ_RECORD, record);
  }

  deleteReadRecord(recordId: string): void {
    bookStore.dispatch(DELETE_READ_RECORD, recordId);
  }

  getTodayReadDuration(): number {
    const state = bookStore.getState();
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    let sum = 0;
    for (let i = 0; i < state.readRecords.length; i++) {
      if (state.readRecords[i].startTime >= todayStart) sum += state.readRecords[i].duration;
    }
    return sum;
  }

  getTotalReadDuration(): number {
    const state = bookStore.getState();
    let sum = 0;
    for (let i = 0; i < state.readRecords.length; i++) sum += state.readRecords[i].duration;
    return sum;
  }

  getRecentBooks(count: number): BookInfo[] {
    const all = getAllBooksFromStore();
    const sorted: BookInfo[] = [];
    for (let i = 0; i < all.length; i++) sorted.push(all[i]);
    sorted.sort((a, b) => (b.lastReadTime > 0 ? b.lastReadTime : 0) - (a.lastReadTime > 0 ? a.lastReadTime : 0));
    const limit = sorted.length < count ? sorted.length : count;
    const result: BookInfo[] = [];
    for (let i = 0; i < limit; i++) result.push(sorted[i]);
    return result;
  }

  createGroup(name: string, color: string): BookshelfGroup {
    const group: BookshelfGroup = { id: generateBookId(), name, color, bookIds: [], createTime: Date.now(), sortOrder: bookStore.getState().groupKeys.length };
    this.addGroup(group);
    return group;
  }

  removeBookFromGroup(bookId: string, groupId: string): void {
    bookStore.dispatch(REMOVE_BOOK_FROM_GROUP, { bookId, groupId });
  }

  addBookToGroup(bookId: string, groupId: string): void {
    bookStore.dispatch(ADD_BOOK_TO_GROUP, { bookId, groupId });
  }

  getFormatColor(format: BookFormat): string {
    return getBookFormatColor(format);
  }

  // 璁㈤槄鍏煎锛堟棫浠ｇ爜锛?  subscribe(listener: (books: BookInfo[]) => void): () => void {
    listener(getAllBooksFromStore());
    return () => {};
  }

  subscribeGroups(listener: (groups: BookshelfGroup[]) => void): () => void {
    listener(this.getAllGroups());
    return () => {};
  }

  subscribeRecords(callback: (records: ReadRecord[]) => void): () => void {
    callback(this.getAllReadRecords());
    return () => {};
  }
}

// Export the singleton instance (鍏煎灞?
export const bookViewModel = new BookViewModelCompat();
