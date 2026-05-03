/**
 * Book preferences management
 */
import { BasePrefs } from './BasePrefs';
import { BookInfo, ReadSettings, DEFAULT_READ_SETTINGS, Bookmark, Note, ReadRecord, BookmarksMap, NotesMap } from '../../models/BookModel';
import * as Keys from './StorageKeys';

export class BookPrefs extends BasePrefs {
  private static instance: BookPrefs | null = null;

  static getInstance(): BookPrefs {
    if (!BookPrefs.instance) {
      BookPrefs.instance = new BookPrefs();
    }
    return BookPrefs.instance;
  }

  async setBooksAsync(books: BookInfo[]): Promise<void> {
    try {
      const booksJson = JSON.stringify(books);
      await this.setStringAsync(Keys.KEY_BOOKS, booksJson);
    } catch (e) {
      const err = e as Error;
      console.error('[BookPrefs] Save books failed:', err.message);
      console.error('[BookPrefs] Save books failed:', e);
    }
  }

  async saveBookAsync(book: BookInfo): Promise<void> {
    try {
      const books: BookInfo[] = await this.getBooksAsync();
      const index = books.findIndex((b: BookInfo) => b.id === book.id);
      if (index >= 0) {
        books[index] = book;
      } else {
        books.push(book);
      }
      await this.setBooksAsync(books);
    } catch (e) {
      const err = e as Error;
      console.error('[BookPrefs] Save book failed:', err.message);
      console.error('[BookPrefs] Save book failed:', e);
    }
  }

  async getBooksAsync(): Promise<BookInfo[]> {
    try {
      const booksJson: string = await this.getStringAsync(Keys.KEY_BOOKS, '[]');
      if (!booksJson || booksJson === '[]') {
        return [] as BookInfo[];
      }
      const result: BookInfo[] = JSON.parse(booksJson) as BookInfo[];
      return result;
    } catch (e) {
      const err = e as Error;
      console.error('[BookPrefs] Get books failed:', err.message);
      console.error('[BookPrefs] Get books failed:', e);
      return [] as BookInfo[];
    }
  }

  async getBookAsync(bookId: string): Promise<BookInfo | null> {
    try {
      const books: BookInfo[] = await this.getBooksAsync();
      const result = books.find((b: BookInfo) => b.id === bookId);
      return result || null;
    } catch (e) {
      const err = e as Error;
      console.error('[BookPrefs] Get book failed:', err.message);
      console.error('[BookPrefs] Get book failed:', e);
      return null;
    }
  }

  setBooks(books: BookInfo[]): void {
    try {
      const booksJson = JSON.stringify(books);
      this.setString(Keys.KEY_BOOKS, booksJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save books failed:', err.message);
    }
  }

  saveBook(book: BookInfo): void {
    try {
      const books: BookInfo[] = this.getBooks();
      const index = books.findIndex((b: BookInfo) => b.id === book.id);
      if (index >= 0) {
        books[index] = book;
      } else {
        books.push(book);
      }
      this.setBooks(books);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save book failed:', err.message);
    }
  }

  getBooks(): BookInfo[] {
    try {
      const booksJson: string = this.getString(Keys.KEY_BOOKS, '[]');
      if (!booksJson || booksJson === '[]') {
        return [] as BookInfo[];
      }
      const result: BookInfo[] = JSON.parse(booksJson) as BookInfo[];
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get books failed:', err.message);
      console.error('[BookPrefs] Get books failed:');
      return [] as BookInfo[];
    }
  }

  getBook(bookId: string): BookInfo | null {
    try {
      const books: BookInfo[] = this.getBooks();
      const result = books.find((b: BookInfo) => b.id === bookId);
      return result || null;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get book failed:', err.message);
      return null;
    }
  }

  async setReadSettingsAsync(settings: ReadSettings): Promise<void> {
    try {
      const settingsJson = JSON.stringify(settings);
      await this.setStringAsync(Keys.KEY_READ_SETTINGS, settingsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save read settings failed:', err.message);
    }
  }

  async getReadSettingsAsync(): Promise<ReadSettings> {
    try {
      const settingsJson: string = await this.getStringAsync(Keys.KEY_READ_SETTINGS, JSON.stringify(DEFAULT_READ_SETTINGS));
      if (!settingsJson) {
        return DEFAULT_READ_SETTINGS;
      }
      const result: ReadSettings = JSON.parse(settingsJson) as ReadSettings;
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get read settings failed:', err.message);
      return DEFAULT_READ_SETTINGS;
    }
  }

  setReadSettings(settings: ReadSettings): void {
    try {
      const settingsJson = JSON.stringify(settings);
      this.setString(Keys.KEY_READ_SETTINGS, settingsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save read settings failed:', err.message);
    }
  }

  getReadSettings(): ReadSettings {
    try {
      const settingsJson: string = this.getString(Keys.KEY_READ_SETTINGS, JSON.stringify(DEFAULT_READ_SETTINGS));
      if (!settingsJson) {
        return DEFAULT_READ_SETTINGS;
      }
      const result: ReadSettings = JSON.parse(settingsJson) as ReadSettings;
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get read settings failed:', err.message);
      return DEFAULT_READ_SETTINGS;
    }
  }

  async setBookmarksAsync(bookmarks: Record<string, Bookmark[]>): Promise<void> {
    try {
      const bookmarksJson = JSON.stringify(bookmarks);
      await this.setStringAsync(Keys.KEY_BOOKMARKS, bookmarksJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save bookmarks failed:', err.message);
    }
  }

  async getBookmarksAsync(): Promise<BookmarksMap> {
    const result = new Map<string, Bookmark[]>();
    try {
      const bookmarksJson: string = await this.getStringAsync(Keys.KEY_BOOKMARKS, '{}');
      if (!bookmarksJson || bookmarksJson === '{}') {
        return result;
      }
      const obj: Record<string, Bookmark[]> = JSON.parse(bookmarksJson) as Record<string, Bookmark[]>;
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        result.set(keys[i], obj[keys[i]]);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get bookmarks failed:', err.message);
    }
    return result;
  }

  async saveBookmarksAsync(bookId: string, bookmarks: Bookmark[]): Promise<void> {
    try {
      // Work directly with JSON storage format to avoid Map/Record conversion issues
      const bookmarksJson: string = await this.getStringAsync(Keys.KEY_BOOKMARKS, '{}');
      const allBookmarks: Record<string, Bookmark[]> = JSON.parse(bookmarksJson) as Record<string, Bookmark[]>;
      allBookmarks[bookId] = bookmarks;
      await this.setBookmarksAsync(allBookmarks);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save bookmarks failed:', err.message);
    }
  }

  setBookmarks(bookmarks: Record<string, Bookmark[]>): void {
    try {
      const bookmarksJson = JSON.stringify(bookmarks);
      this.setString(Keys.KEY_BOOKMARKS, bookmarksJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save bookmarks failed:', err.message);
    }
  }

  getBookmarks(): BookmarksMap {
    const result = new Map<string, Bookmark[]>();
    try {
      const bookmarksJson: string = this.getString(Keys.KEY_BOOKMARKS, '{}');
      if (!bookmarksJson || bookmarksJson === '{}') {
        return result;
      }
      const obj: Record<string, Bookmark[]> = JSON.parse(bookmarksJson) as Record<string, Bookmark[]>;
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        result.set(keys[i], obj[keys[i]]);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get bookmarks failed:', err.message);
    }
    return result;
  }

  /**
   * Get bookmarks as Record (for callers that need Record type)
   */
  getBookmarksRecord(): Record<string, Bookmark[]> {
    try {
      const bookmarksJson: string = this.getString(Keys.KEY_BOOKMARKS, '{}');
      if (!bookmarksJson || bookmarksJson === '{}') {
        return {};
      }
      return JSON.parse(bookmarksJson) as Record<string, Bookmark[]>;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get bookmarks record failed:', err.message);
      return {};
    }
  }

  getBookmarksByBookId(bookId: string): Bookmark[] {
    try {
      const allBookmarks = this.getBookmarks();
      const result = allBookmarks.get(bookId);
      return result || [] as Bookmark[];
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get bookmarks failed:', err.message);
      return [] as Bookmark[];
    }
  }

  saveBookmarks(bookId: string, bookmarks: Bookmark[]): void {
    try {
      // Work directly with JSON storage format to avoid Map/Record conversion issues
      const bookmarksJson: string = this.getString(Keys.KEY_BOOKMARKS, '{}');
      const allBookmarks: Record<string, Bookmark[]> = JSON.parse(bookmarksJson) as Record<string, Bookmark[]>;
      allBookmarks[bookId] = bookmarks;
      this.setBookmarks(allBookmarks);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save bookmarks failed:', err.message);
    }
  }

  async setNotesAsync(notes: Record<string, Note[]>): Promise<void> {
    try {
      const notesJson = JSON.stringify(notes);
      await this.setStringAsync(Keys.KEY_NOTES, notesJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save notes failed:', err.message);
    }
  }

  async getNotesAsync(): Promise<NotesMap> {
    const result = new Map<string, Note[]>();
    try {
      const notesJson: string = await this.getStringAsync(Keys.KEY_NOTES, '{}');
      if (!notesJson || notesJson === '{}') {
        return result;
      }
      const obj: Record<string, Note[]> = JSON.parse(notesJson) as Record<string, Note[]>;
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        result.set(keys[i], obj[keys[i]]);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get notes failed:', err.message);
    }
    return result;
  }

  async saveNotesAsync(bookId: string, notes: Note[]): Promise<void> {
    try {
      // Work directly with JSON storage format to avoid Map/Record conversion issues
      const notesJson: string = await this.getStringAsync(Keys.KEY_NOTES, '{}');
      const allNotes: Record<string, Note[]> = JSON.parse(notesJson) as Record<string, Note[]>;
      allNotes[bookId] = notes;
      await this.setNotesAsync(allNotes);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save notes failed:', err.message);
    }
  }

  setNotes(notes: Record<string, Note[]>): void {
    try {
      const notesJson = JSON.stringify(notes);
      this.setString(Keys.KEY_NOTES, notesJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save notes failed:', err.message);
    }
  }

  getNotes(): NotesMap {
    const result = new Map<string, Note[]>();
    try {
      const notesJson: string = this.getString(Keys.KEY_NOTES, '{}');
      if (!notesJson || notesJson === '{}') {
        return result;
      }
      const obj: Record<string, Note[]> = JSON.parse(notesJson) as Record<string, Note[]>;
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        result.set(keys[i], obj[keys[i]]);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get notes failed:', err.message);
    }
    return result;
  }

  /**
   * Get notes as Record (for callers that need Record type)
   */
  getNotesRecord(): Record<string, Note[]> {
    try {
      const notesJson: string = this.getString(Keys.KEY_NOTES, '{}');
      if (!notesJson || notesJson === '{}') {
        return {};
      }
      return JSON.parse(notesJson) as Record<string, Note[]>;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get notes record failed:', err.message);
      return {};
    }
  }

  getNotesByBookId(bookId: string): Note[] {
    try {
      const allNotes = this.getNotes();
      const result = allNotes.get(bookId);
      return result || [] as Note[];
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get notes failed:', err.message);
      return [] as Note[];
    }
  }

  saveNotes(bookId: string, notes: Note[]): void {
    try {
      // Work directly with JSON storage format to avoid Map/Record conversion issues
      const notesJson: string = this.getString(Keys.KEY_NOTES, '{}');
      const allNotes: Record<string, Note[]> = JSON.parse(notesJson) as Record<string, Note[]>;
      allNotes[bookId] = notes;
      this.setNotes(allNotes);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save notes failed:', err.message);
    }
  }

  deleteBook(bookId: string): void {
    try {
      const books: BookInfo[] = this.getBooks();
      const filtered: BookInfo[] = [];
      for (let i = 0; i < books.length; i++) {
        if (books[i].id !== bookId) {
          filtered.push(books[i]);
        }
      }
      this.setBooks(filtered);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Delete book failed:', err.message);
    }
  }

  async setReadRecordsAsync(records: ReadRecord[]): Promise<void> {
    try {
      const recordsJson = JSON.stringify(records);
      await this.setStringAsync(Keys.KEY_READ_RECORDS, recordsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save read records failed:', err.message);
    }
  }

  async getReadRecordsAsync(): Promise<ReadRecord[]> {
    try {
      const recordsJson: string = await this.getStringAsync(Keys.KEY_READ_RECORDS, '[]');
      if (!recordsJson || recordsJson === '[]') {
        return [] as ReadRecord[];
      }
      const result: ReadRecord[] = JSON.parse(recordsJson) as ReadRecord[];
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get read records failed:', err.message);
      return [] as ReadRecord[];
    }
  }

  setReadRecords(records: ReadRecord[]): void {
    try {
      const recordsJson = JSON.stringify(records);
      this.setString(Keys.KEY_READ_RECORDS, recordsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Save read records failed:', err.message);
    }
  }

  getReadRecords(): ReadRecord[] {
    try {
      const recordsJson: string = this.getString(Keys.KEY_READ_RECORDS, '[]');
      if (!recordsJson || recordsJson === '[]') {
        return [] as ReadRecord[];
      }
      const result: ReadRecord[] = JSON.parse(recordsJson) as ReadRecord[];
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BookPrefs] Get read records failed:', err.message);
      return [] as ReadRecord[];
    }
  }
}

export const bookPrefs = BookPrefs.getInstance();