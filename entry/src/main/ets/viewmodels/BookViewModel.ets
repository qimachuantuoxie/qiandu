/**
 * 书籍管理 ViewModel - 业务逻辑层
 * 
 * 负责书籍的增删改查、阅读进度管理、书签笔记等核心功能
 * 采用单例模式，通过 preferenceManager 持久化数据
 * 
 * @example
 * // 获取所有书籍
 * const books = bookViewModel.getAllBooks();
 * 
 * // 搜索书籍
 * const results = bookViewModel.searchBooks('关键字');
 * 
 * // 更新阅读进度
 * bookViewModel.updateReadingProgress(bookId, currentPage, duration);
 * 
 * // 订阅书籍变化
 * const unsubscribe = bookViewModel.subscribe((books) => {
 *   // 处理书籍变化
 * });
 */

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
} from '../models/CoreBookModel';

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
 * 书籍视图模型
 * 管理所有书籍相关操作，包括：
 * - 书籍 CRUD 操作
 * - 搜索和排序
 * - 书签和笔记管理
 * - 阅读记录统计
 * - 分组管理
 */
@ObservedV2
class BookViewModel {
  // ==================== 数据存储 ====================

  /** 书籍字典 */
  @Trace private books: BooksMap = new Map();

  /** 书籍ID列表，用于有序遍历 */
  @Trace private bookKeys: string[] = [];

  /** 书签字典 */
  @Trace private bookmarks: BookmarksMap = new Map();

  /** 书签Key列表 */
  @Trace private bookmarkKeys: string[] = [];

  /** 笔记字典 */
  @Trace private notes: NotesMap = new Map();

  /** 笔记Key列表 */
  @Trace private noteKeys: string[] = [];

  /** 分组字典 */
  @Trace private groups: GroupsMap = new Map();

  /** 分组Key列表 */
  @Trace private groupKeys: string[] = [];

  /** 阅读记录字典 {bookId: ReadRecord[]} */
  @Trace private readRecords: ReadRecord[] = [];

  // ==================== 事件监听 ====================
  
  /** 书籍数据变化监听器 */
  private listeners: Array<(books: BookInfo[]) => void> = [];
  
  /** 分组数据变化监听器 */
  private groupListeners: Array<(groups: BookshelfGroup[]) => void> = [];

  /**
   * 构造函数
   * 初始化时加载书籍和分组数据
   */
  constructor() {
    this.loadBooks();
    this.loadGroups();
    this.loadBookmarks();
    this.loadNotes();
    this.loadReadRecords();
  }

  // ==================== 书籍管理 ====================

  /**
   * 加载所有书籍
   * 从持久化存储读取书籍列表
   */
  loadBooks(): void {
    try {
      const savedBooks = preferenceManager.getBooks();
      this.books.clear();
      const keys: string[] = [];
      for (let i = 0; i < savedBooks.length; i++) {
        const book = savedBooks[i];
        this.books.set(book.id, book);
        keys.push(book.id);
      }
      this.bookKeys = keys;
      this.notifyListeners();
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('加载书籍失败:', message);
    }
  }

  /**
   * 添加书籍
   */
  addBook(book: BookInfo): void {
    if (!book.id) {
      book.id = generateBookId();
    }
    this.books.set(book.id, book);
    let exists = false;
    for (let i = 0; i < this.bookKeys.length; i++) {
      if (this.bookKeys[i] === book.id) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.bookKeys.length; i++) {
        newKeys.push(this.bookKeys[i]);
      }
      newKeys.push(book.id);
      this.bookKeys = newKeys;
    }
    this.saveBooks();
    this.notifyListeners();
  }

  /**
   * 删除书籍
   */
  deleteBook(bookId: string): void {
    let bookIndex = -1;
    for (let i = 0; i < this.bookKeys.length; i++) {
      if (this.bookKeys[i] === bookId) {
        bookIndex = i;
        break;
      }
    }
    if (bookIndex > -1) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.bookKeys.length; i++) {
        if (i !== bookIndex) {
          newKeys.push(this.bookKeys[i]);
        }
      }
      this.bookKeys = newKeys;
    }
    let bmIndex = -1;
    for (let i = 0; i < this.bookmarkKeys.length; i++) {
      if (this.bookmarkKeys[i] === bookId) {
        bmIndex = i;
        break;
      }
    }
    if (bmIndex > -1) {
      const newBmKeys: string[] = [];
      for (let i = 0; i < this.bookmarkKeys.length; i++) {
        if (i !== bmIndex) {
          newBmKeys.push(this.bookmarkKeys[i]);
        }
      }
      this.bookmarkKeys = newBmKeys;
      this.bookmarks.set(bookId, []);
      this.saveBookmarks();
    }
    let noteIndex = -1;
    for (let i = 0; i < this.noteKeys.length; i++) {
      if (this.noteKeys[i] === bookId) {
        noteIndex = i;
        break;
      }
    }
    if (noteIndex > -1) {
      const newNoteKeys: string[] = [];
      for (let i = 0; i < this.noteKeys.length; i++) {
        if (i !== noteIndex) {
          newNoteKeys.push(this.noteKeys[i]);
        }
      }
      this.noteKeys = newNoteKeys;
      this.notes.set(bookId, []);
      this.saveNotes();
    }
    
    // 清理阅读记录（保留其他书籍的记录）
    const remainingRecords: ReadRecord[] = [];
    for (let i = 0; i < this.readRecords.length; i++) {
      if (this.readRecords[i].bookId !== bookId) {
        remainingRecords.push(this.readRecords[i]);
      }
    }
    this.readRecords = remainingRecords;
    this.saveReadRecords();
    
    this.saveBooks();
    this.notifyListeners();
  }

  /**
   * 更新书籍信息
   */
  updateBook(book: BookInfo): void {
    this.books.set(book.id, book);
    let exists = false;
    for (let i = 0; i < this.bookKeys.length; i++) {
      if (this.bookKeys[i] === book.id) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.bookKeys.length; i++) {
        newKeys.push(this.bookKeys[i]);
      }
      newKeys.push(book.id);
      this.bookKeys = newKeys;
    }
    this.saveBooks();
    this.notifyListeners();
  }

  private getAllBooksArray(): BookInfo[] {
    const result: BookInfo[] = [];
    for (let i = 0; i < this.bookKeys.length; i++) {
      const key = this.bookKeys[i];
      const book = this.books.get(key);
      if (book) {
        result.push(book);
      }
    }
    return result;
  }

  /**
   * 获取所有书籍
   */
  getAllBooks(): BookInfo[] {
    return this.getAllBooksArray();
  }

  /**
   * 根据 ID 获取书籍
   */
  getBookById(bookId: string): BookInfo | undefined {
    return this.books.get(bookId);
  }

  /**
   * 搜索书籍
   */
  searchBooks(keyword: string): BookInfo[] {
    const lowerKeyword = keyword.toLowerCase();
    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (book.title.toLowerCase().includes(lowerKeyword) ||
          book.author.toLowerCase().includes(lowerKeyword)) {
        result.push(book);
      }
    }
    return result;
  }

  /**
   * 获取正在阅读的书籍
   */
  getReadingBooks(): BookInfo[] {
    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].status === ReadStatus.READING) {
        result.push(allBooks[i]);
      }
    }
    return result;
  }

  /**
   * 获取收藏的书籍
   */
  getFavoriteBooks(): BookInfo[] {
    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].isFavorite) {
        result.push(allBooks[i]);
      }
    }
    return result;
  }

  /**
   * 获取已读完的书籍
   */
  getFinishedBooks(): BookInfo[] {
    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].status === ReadStatus.FINISHED) {
        result.push(allBooks[i]);
      }
    }
    return result;
  }

  /**
   * 获取未读的书籍
   */
  getUnreadBooks(): BookInfo[] {
    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].status === ReadStatus.UNREAD) {
        result.push(allBooks[i]);
      }
    }
    return result;
  }

  /**
   * 排序选项枚举
   */
  static readonly SortOrder: SortOrderMap = {
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

  sortBooks(books: BookInfo[], sortOrder: string): BookInfo[] {
    const sorted: BookInfo[] = [];
    for (let i = 0; i < books.length; i++) {
      sorted.push(books[i]);
    }
    switch (sortOrder) {
      case BookViewModel.SortOrder.TITLE_ASC:
        sorted.sort((a, b) => a.title.localeCompare(b.title, 'zh-CN'));
        break;
      case BookViewModel.SortOrder.TITLE_DESC:
        sorted.sort((a, b) => b.title.localeCompare(a.title, 'zh-CN'));
        break;
      case BookViewModel.SortOrder.AUTHOR_ASC:
        sorted.sort((a, b) => a.author.localeCompare(b.author, 'zh-CN'));
        break;
      case BookViewModel.SortOrder.AUTHOR_DESC:
        sorted.sort((a, b) => b.author.localeCompare(a.author, 'zh-CN'));
        break;
      case BookViewModel.SortOrder.ADD_TIME_DESC:
        sorted.sort((a, b) => b.addTime - a.addTime);
        break;
      case BookViewModel.SortOrder.ADD_TIME_ASC:
        sorted.sort((a, b) => a.addTime - b.addTime);
        break;
      case BookViewModel.SortOrder.LAST_READ_DESC:
        sorted.sort((a, b) => b.lastReadTime - a.lastReadTime);
        break;
      case BookViewModel.SortOrder.LAST_READ_ASC:
        sorted.sort((a, b) => a.lastReadTime - b.lastReadTime);
        break;
      case BookViewModel.SortOrder.PROGRESS_DESC:
        sorted.sort((a, b) => b.readProgress - a.readProgress);
        break;
      case BookViewModel.SortOrder.PROGRESS_ASC:
        sorted.sort((a, b) => a.readProgress - b.readProgress);
        break;
    }
    return sorted;
  }

  advancedSearch(keyword: string, options?: AdvancedSearchOptions): BookInfo[] {
    if (!keyword || keyword.trim().length === 0) {
      return this.getAllBooksArray();
    }
    
    const lowerKeyword = keyword.toLowerCase().trim();
    let searchTitle = true;
    let searchAuthor = true;
    let searchTags = true;
    let searchDescription = false;
    if (options) {
      if (options.searchTitle !== undefined) {
        searchTitle = options.searchTitle;
      }
      if (options.searchAuthor !== undefined) {
        searchAuthor = options.searchAuthor;
      }
      if (options.searchTags !== undefined) {
        searchTags = options.searchTags;
      }
      if (options.searchDescription !== undefined) {
        searchDescription = options.searchDescription;
      }
    }

    const allBooks = this.getAllBooksArray();
    const result: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (searchTitle && book.title.toLowerCase().includes(lowerKeyword)) {
        result.push(book);
        continue;
      }
      if (searchAuthor && book.author.toLowerCase().includes(lowerKeyword)) {
        result.push(book);
        continue;
      }
      if (searchTags && book.tags) {
        for (let j = 0; j < book.tags.length; j++) {
          if (book.tags[j].toLowerCase().includes(lowerKeyword)) {
            result.push(book);
            break;
          }
        }
      }
      if (searchDescription && book.description && book.description.toLowerCase().includes(lowerKeyword)) {
        result.push(book);
      }
    }
    return result;
  }

  getBooksPaginated(page: number, pageSize: number, sortOrder?: string): PaginatedBooksResult {
    let books = this.getAllBooksArray();
    if (sortOrder) {
      books = this.sortBooks(books, sortOrder);
    }
    const total = books.length;
    const totalPages = Math.ceil(total / pageSize);
    const start = (page - 1) * pageSize;
    const end = start + pageSize;
    const paginatedBooks: BookInfo[] = [];
    for (let i = start; i < end && i < books.length; i++) {
      paginatedBooks.push(books[i]);
    }
    return {
      books: paginatedBooks,
      total,
      page,
      pageSize,
      hasMore: end < books.length,
      totalPages
    };
  }

  /**
   * 更新阅读进度
   */
  updateReadingProgress(bookId: string, currentPage: number, duration: number): void {
    const book = this.books.get(bookId);
    if (!book) return;

    book.currentPage = currentPage;
    if (book.totalPages > 0) {
      book.readProgress = Math.round((currentPage / book.totalPages) * 100);
    } else {
      book.readProgress = 0;
    }
    book.lastReadTime = Date.now();
    book.status = ReadStatus.READING;
    book.totalReadTime = (book.totalReadTime || 0) + duration;

    this.saveBooks();
    this.notifyListeners();
  }

  /**
   * 切换收藏状态
   */
  toggleFavorite(bookId: string): void {
    const book = this.books.get(bookId);
    if (book) {
      book.isFavorite = !book.isFavorite;
      this.saveBooks();
      this.notifyListeners();
    }
  }

  // ==================== 书签管理 ====================

  /**
   * 添加书签
   */
  addBookmark(bookId: string, pageNumber: number, title: string, note?: string): Bookmark {
    const bookmark: Bookmark = {
      id: generateBookId(),
      bookId,
      pageNumber,
      title,
      createTime: Date.now(),
      note
    };

    let bookBookmarks = this.bookmarks.get(bookId);
    if (!bookBookmarks) {
      bookBookmarks = [];
      this.bookmarks.set(bookId, bookBookmarks);
      let exists = false;
      for (let i = 0; i < this.bookmarkKeys.length; i++) {
        if (this.bookmarkKeys[i] === bookId) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newKeys: string[] = [];
        for (let i = 0; i < this.bookmarkKeys.length; i++) {
          newKeys.push(this.bookmarkKeys[i]);
        }
        newKeys.push(bookId);
        this.bookmarkKeys = newKeys;
      }
    }
    const newBms: Bookmark[] = [];
    for (let i = 0; i < bookBookmarks.length; i++) {
      newBms.push(bookBookmarks[i]);
    }
    newBms.push(bookmark);
    this.bookmarks.set(bookId, newBms);
    this.saveBookmarks();

    return bookmark;
  }

  /**
   * 删除书签
   */
  deleteBookmark(bookId: string, bookmarkId: string): void {
    const bookBookmarks = this.bookmarks.get(bookId);
    if (bookBookmarks) {
      let index = -1;
      for (let i = 0; i < bookBookmarks.length; i++) {
        if (bookBookmarks[i].id === bookmarkId) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newBms: Bookmark[] = [];
        for (let i = 0; i < bookBookmarks.length; i++) {
          if (i !== index) {
            newBms.push(bookBookmarks[i]);
          }
        }
      this.bookmarks.set(bookId, newBms);
        this.saveBookmarks();
      }
    }
  }

  /**
   * 获取书籍的所有书签
   */
  getBookmarks(bookId: string): Bookmark[] {
    return this.bookmarks.get(bookId) || [];
  }

  /**
   * 获取所有书签（跨所有书籍）
   */
  getAllBookmarks(): Bookmark[] {
    const allBookmarks: Bookmark[] = [];
    for (let i = 0; i < this.bookmarkKeys.length; i++) {
      const bookId = this.bookmarkKeys[i];
    const marks = this.bookmarks.get(bookId);
      if (marks) {
        for (let j = 0; j < marks.length; j++) {
          allBookmarks.push(marks[j]);
        }
      }
    }
    return allBookmarks;
  }

  /**
   * 保存书签
   */
  private saveBookmarks(): void {
    try {
      const bookmarksObj: Record<string, Bookmark[]> = {};
      const bmKeys = this.bookmarkKeys;
      for (let i = 0; i < bmKeys.length; i++) {
        const key = bmKeys[i];
        const val = this.bookmarks.get(key);
        if (val) {
          bookmarksObj[key] = val;
        }
      }
      preferenceManager.setBookmarks(bookmarksObj);
    } catch (error) {
      console.error('保存书签失败');
    }
  }

  // ==================== 笔记管理 ====================

  /**
   * 添加笔记
   */
  addNote(bookId: string, pageNumber: number, content: string, highlight?: string, color?: string): Note {
    const note: Note = {
      id: generateBookId(),
      bookId,
      pageNumber,
      content,
      highlight,
      color,
      createTime: Date.now()
    };

    let bookNotes = this.notes.get(bookId);
    if (!bookNotes) {
      bookNotes = [];
      this.notes.set(bookId, bookNotes);
      let exists = false;
      for (let i = 0; i < this.noteKeys.length; i++) {
        if (this.noteKeys[i] === bookId) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newKeys: string[] = [];
        for (let i = 0; i < this.noteKeys.length; i++) {
          newKeys.push(this.noteKeys[i]);
        }
        newKeys.push(bookId);
        this.noteKeys = newKeys;
      }
    }
    const newNotes: Note[] = [];
    for (let i = 0; i < bookNotes.length; i++) {
      newNotes.push(bookNotes[i]);
    }
    newNotes.push(note);
    this.notes.set(bookId, newNotes);
    this.saveNotes();

    return note;
  }

  /**
   * 删除笔记
   */
  deleteNote(bookId: string, noteId: string): void {
    const bookNotes = this.notes.get(bookId);
    if (bookNotes) {
      let index = -1;
      for (let i = 0; i < bookNotes.length; i++) {
        if (bookNotes[i].id === noteId) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newNotes: Note[] = [];
        for (let i = 0; i < bookNotes.length; i++) {
          if (i !== index) {
            newNotes.push(bookNotes[i]);
          }
        }
      this.notes.set(bookId, newNotes);
        this.saveNotes();
      }
    }
  }

  /**
   * 获取书籍的所有笔记
   */
  getNotes(bookId: string): Note[] {
    return this.notes.get(bookId) || [];
  }

  /**
   * 获取所有笔记（跨所有书籍）
   */
  getAllNotes(): Note[] {
    const allNotes: Note[] = [];
    for (let i = 0; i < this.noteKeys.length; i++) {
      const bookId = this.noteKeys[i];
    const notes = this.notes.get(bookId);
      if (notes) {
        for (let j = 0; j < notes.length; j++) {
          allNotes.push(notes[j]);
        }
      }
    }
    return allNotes;
  }

  // ==================== 分组管理 ====================

  /**
   * 加载分组
   */
  loadGroups(): void {
    try {
      const savedGroups = preferenceManager.getBookshelfGroups();
      this.groups.clear();
      const keys: string[] = [];
      for (let i = 0; i < savedGroups.length; i++) {
        const g = savedGroups[i];
      this.groups.set(g.id, g);
        keys.push(g.id);
      }
      this.groupKeys = keys;
      this.notifyGroupListeners();
    } catch (error) {
      const err = error as Error;
    }
  }

  /**
   * 加载书签
   */
  loadBookmarks(): void {
    try {
      const savedBookmarks = preferenceManager.getAllBookmarks();
      this.bookmarks.clear();
      const keys = Object.keys(savedBookmarks);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        this.bookmarks.set(key, savedBookmarks[key]);
      }
      this.bookmarkKeys = keys;
    } catch (error) {
      const err = error as Error;
    }
  }

  /**
   * 加载笔记
   */
  loadNotes(): void {
    try {
      const savedNotes = preferenceManager.getNotes();
      this.notes.clear();
      const keys = Object.keys(savedNotes);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        this.notes.set(key, savedNotes[key]);
      }
      this.noteKeys = keys;
    } catch (error) {
      console.error('加载笔记失败');
    }
  }

  /**
   * 保存笔记
   */
  private saveNotes(): void {
    try {
      const notesObj: Record<string, Note[]> = {};
      const ntKeys = this.noteKeys;
      for (let i = 0; i < ntKeys.length; i++) {
        const key = ntKeys[i];
        const val = this.notes.get(key);
        if (val) {
          notesObj[key] = val;
        }
      }
      preferenceManager.setNotes(notesObj);
    } catch (error) {
      console.error('保存笔记失败');
    }
  }

  /**
   * 加载阅读记录
   */
  loadReadRecords(): void {
    try {
      this.readRecords = preferenceManager.getReadRecords();
    } catch (error) {
      console.error('加载阅读记录失败');
    }
  }

  /**
   * 保存阅读记录
   */
  private saveReadRecords(): void {
    try {
      preferenceManager.setReadRecords(this.readRecords);
    } catch (error) {
      console.error('Save read records failed');
    }
  }

  /**
   * 保存分组
   */
  saveGroups(): void {
    const groupsArray = this.getAllGroups();
    preferenceManager.setBookshelfGroups(groupsArray);
    this.notifyGroupListeners();
  }

  private getAllGroupsArray(): BookshelfGroup[] {
    const result: BookshelfGroup[] = [];
    for (let i = 0; i < this.groupKeys.length; i++) {
      const key = this.groupKeys[i];
    const group = this.groups.get(key);
      if (group) {
        result.push(group);
      }
    }
    return result;
  }

  /**
   * 添加分组
   */
  addGroup(group: BookshelfGroup): void {
    if (!group.id) {
      group.id = generateBookId();
    }
    this.groups.set(group.id, group);
    let exists = false;
    for (let i = 0; i < this.groupKeys.length; i++) {
      if (this.groupKeys[i] === group.id) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.groupKeys.length; i++) {
        newKeys.push(this.groupKeys[i]);
      }
      newKeys.push(group.id);
      this.groupKeys = newKeys;
    }
    this.saveGroups();
  }

  /**
   * 删除分组
   */
  deleteGroup(groupId: string): void {
    let index = -1;
    for (let i = 0; i < this.groupKeys.length; i++) {
      if (this.groupKeys[i] === groupId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.groupKeys.length; i++) {
        if (i !== index) {
          newKeys.push(this.groupKeys[i]);
        }
      }
      this.groupKeys = newKeys;
    }
    this.saveGroups();
  }

  /**
   * 更新分组
   */
  updateGroup(groupOrId: BookshelfGroup | string, updates?: Partial<BookshelfGroup>): void {
    if (typeof groupOrId === 'string' && updates) {
      const existing = this.groups.get(groupOrId);
      if (existing) {
        const updated: BookshelfGroup = {
          id: existing.id,
          name: updates.name !== undefined ? updates.name : existing.name,
          color: updates.color !== undefined ? updates.color : existing.color,
          bookIds: updates.bookIds !== undefined ? updates.bookIds : existing.bookIds,
          createTime: existing.createTime,
          sortOrder: updates.sortOrder !== undefined ? updates.sortOrder : existing.sortOrder
        };
        this.groups.set(groupOrId, updated);
        let exists = false;
        for (let i = 0; i < this.groupKeys.length; i++) {
          if (this.groupKeys[i] === groupOrId) {
            exists = true;
            break;
          }
        }
        if (!exists) {
          const newKeys: string[] = [];
          for (let i = 0; i < this.groupKeys.length; i++) {
            newKeys.push(this.groupKeys[i]);
          }
          newKeys.push(groupOrId);
          this.groupKeys = newKeys;
        }
        this.saveGroups();
      }
    } else if (typeof groupOrId === 'object') {
      this.groups.set(groupOrId.id, groupOrId);
      let exists = false;
      for (let i = 0; i < this.groupKeys.length; i++) {
        if (this.groupKeys[i] === groupOrId.id) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newKeys: string[] = [];
        for (let i = 0; i < this.groupKeys.length; i++) {
          newKeys.push(this.groupKeys[i]);
        }
        newKeys.push(groupOrId.id);
        this.groupKeys = newKeys;
      }
      this.saveGroups();
    }
  }

  /**
   * 获取所有分组
   */
  getAllGroups(): BookshelfGroup[] {
    return this.getAllGroupsArray();
  }

  // ==================== 持久化 ====================

  /**
   * 保存所有书籍
   */
  private saveBooks(): void {
    try {
      const booksArray = this.getAllBooksArray();
      preferenceManager.setBooks(booksArray);
    } catch (error) {
      const err = error as Error;
    }
  }

  // ==================== 监听器 ====================

  /**
   * 订阅书籍变化
   */
  subscribe(listener: (books: BookInfo[]) => void): () => void {
    this.listeners.push(listener);
    return () => {
      let index = -1;
      for (let i = 0; i < this.listeners.length; i++) {
        if (this.listeners[i] === listener) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newListeners: Array<(books: BookInfo[]) => void> = [];
        for (let i = 0; i < this.listeners.length; i++) {
          if (i !== index) {
            newListeners.push(this.listeners[i]);
          }
        }
        this.listeners = newListeners;
      }
    };
  }

  /**
   * 订阅分组变化
   */
  subscribeGroups(listener: (groups: BookshelfGroup[]) => void): () => void {
    this.groupListeners.push(listener);
    return () => {
      let index = -1;
      for (let i = 0; i < this.groupListeners.length; i++) {
        if (this.groupListeners[i] === listener) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newListeners: Array<(groups: BookshelfGroup[]) => void> = [];
        for (let i = 0; i < this.groupListeners.length; i++) {
          if (i !== index) {
            newListeners.push(this.groupListeners[i]);
          }
        }
        this.groupListeners = newListeners;
      }
    };
  }

  // ==================== 阅读记录管理 ====================

  subscribeRecords(callback: (records: ReadRecord[]) => void): () => void {
    callback(this.readRecords);
    return () => {};
  }

  getAllReadRecords(): ReadRecord[] {
    return this.readRecords;
  }

  getTodayReadDuration(): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    let sum = 0;
    for (let i = 0; i < this.readRecords.length; i++) {
      if (this.readRecords[i].startTime >= todayStart) {
        sum += this.readRecords[i].duration;
      }
    }
    return sum;
  }

  getTotalReadDuration(): number {
    let sum = 0;
    for (let i = 0; i < this.readRecords.length; i++) {
      sum += this.readRecords[i].duration;
    }
    return sum;
  }

  addReadRecord(record: ReadRecord): void {
    const newRecords: ReadRecord[] = [];
    for (let i = 0; i < this.readRecords.length; i++) {
      newRecords.push(this.readRecords[i]);
    }
    newRecords.push(record);
    this.readRecords = newRecords;
    this.saveReadRecords();
  }

  deleteReadRecord(recordId: string): void {
    const newRecords: ReadRecord[] = [];
    for (let i = 0; i < this.readRecords.length; i++) {
      if (this.readRecords[i].id !== recordId) {
        newRecords.push(this.readRecords[i]);
      }
    }
    this.readRecords = newRecords;
    this.saveReadRecords();
  }

  getRecentBooks(count: number): BookInfo[] {
    const allBooks = this.getAllBooksArray();
    const sorted: BookInfo[] = [];
    for (let i = 0; i < allBooks.length; i++) {
      sorted.push(allBooks[i]);
    }
    sorted.sort((a, b) => (b.lastReadTime > 0 ? b.lastReadTime : 0) - (a.lastReadTime > 0 ? a.lastReadTime : 0));
    const result: BookInfo[] = [];
    const limit = sorted.length < count ? sorted.length : count;
    for (let i = 0; i < limit; i++) {
      result.push(sorted[i]);
    }
    return result;
  }

  // ==================== 分组管理 ====================

  createGroup(name: string, color: string): BookshelfGroup {
    const group: BookshelfGroup = {
      id: generateBookId(),
      name,
      color,
      bookIds: [],
      createTime: Date.now(),
      sortOrder: this.groupKeys.length
    };
    this.groups.set(group.id, group);
    let exists = false;
    for (let i = 0; i < this.groupKeys.length; i++) {
      if (this.groupKeys[i] === group.id) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      const newKeys: string[] = [];
      for (let i = 0; i < this.groupKeys.length; i++) {
        newKeys.push(this.groupKeys[i]);
      }
      newKeys.push(group.id);
      this.groupKeys = newKeys;
    }
    this.saveGroups();
    this.notifyGroupListeners();
    return group;
  }

  removeBookFromGroup(bookId: string, groupId: string): void {
    const group = this.groups.get(groupId);
    if (group) {
      const newBookIds: string[] = [];
      for (let i = 0; i < group.bookIds.length; i++) {
        if (group.bookIds[i] !== bookId) {
          newBookIds.push(group.bookIds[i]);
        }
      }
      const updated: BookshelfGroup = {
        id: group.id,
        name: group.name,
        color: group.color,
        bookIds: newBookIds,
        createTime: group.createTime,
        sortOrder: group.sortOrder
      };
      this.groups.set(groupId, updated);
      this.saveGroups();
      this.notifyGroupListeners();
    }
  }

  addBookToGroup(bookId: string, groupId: string): void {
    const group = this.groups.get(groupId);
    if (group) {
      let exists = false;
      for (let i = 0; i < group.bookIds.length; i++) {
        if (group.bookIds[i] === bookId) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newBookIds: string[] = [];
        for (let i = 0; i < group.bookIds.length; i++) {
          newBookIds.push(group.bookIds[i]);
        }
        newBookIds.push(bookId);
        const updated: BookshelfGroup = {
          id: group.id,
          name: group.name,
          color: group.color,
          bookIds: newBookIds,
          createTime: group.createTime,
          sortOrder: group.sortOrder
        };
        this.groups.set(groupId, updated);
        this.saveGroups();
        this.notifyGroupListeners();
      }
    }
  }

  /**
   * 通知监听器
   */
  private notifyListeners(): void {
    const books = this.getAllBooks();
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i](books);
    }
  }

  /**
   * 通知分组监听器
   */
  private notifyGroupListeners(): void {
    const groups = this.getAllGroups();
    for (let i = 0; i < this.groupListeners.length; i++) {
      this.groupListeners[i](groups);
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取格式颜色
   */
  getFormatColor(format: BookFormat): string {
    const colors: Map<BookFormat, string> = new Map([
      [BookFormat.PDF, '#FF5722'],
      [BookFormat.EPUB, '#2196F3'],
      [BookFormat.MOBI, '#FF9800'],
      [BookFormat.TXT, '#4CAF50'],
      [BookFormat.DOCX, '#3F51B5'],
      [BookFormat.DOC, '#795548'],
      [BookFormat.RTF, '#607D8B'],
      [BookFormat.HTML, '#FFC107'],
      [BookFormat.ODT, '#009688'],
      [BookFormat.FB2, '#3F51B5'],
      [BookFormat.AZW3, '#FF5722'],
      [BookFormat.AZW, '#FF9800'],
      [BookFormat.CBR, '#E91E63'],
      [BookFormat.CBZ, '#9C27B0'],
      [BookFormat.DJVU, '#607D8B'],
      [BookFormat.CHM, '#4CAF50']
    ]);
    return colors.get(format) || '#999999';
  }
}

// Export the singleton instance
export const bookViewModel = new BookViewModel();
