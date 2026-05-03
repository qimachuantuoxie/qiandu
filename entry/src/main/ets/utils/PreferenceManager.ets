/**
 * 偏好设置管理器 - 委托给 prefs 模块
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BookInfo, Note, ReadRecord, Bookmark, BookmarksMap, NotesMap } from '../models/CoreBookModel';
import { UserInfo } from '../models/AuthModels';
import { BookSource } from '../models/BookSourceModel';
import { ReplaceRule } from '../models/BookSourceModel';
import { TodoItem } from '../models/TodoModel';
import { BookshelfGroup } from '../models/BookModel';
import { bookPrefs, userPrefs, themePrefs, readerPrefs, ReaderSettings } from './prefs';

const PREFERENCES_NAME = 'qiandu_yuejie_prefs';

class PreferenceManager {
  private static instance: PreferenceManager | null = null;
  private pref: preferences.Preferences | null = null;
  private context: common.Context | null = null;
  private initialized: boolean = false;

  static getInstance(): PreferenceManager {
    if (!PreferenceManager.instance) {
      PreferenceManager.instance = new PreferenceManager();
    }
    return PreferenceManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.initialized) return;
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, PREFERENCES_NAME);
      await Promise.all([
        bookPrefs.init(context),
        userPrefs.init(context),
        themePrefs.init(context),
        readerPrefs.init(context)
      ]);
      this.initialized = true;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[PreferenceManager] Init failed:', message);
    }
  }

  setBooks(books: BookInfo[]): void {
    bookPrefs.setBooks(books);
  }

  getBooks(): BookInfo[] {
    return bookPrefs.getBooks();
  }

  saveBook(book: BookInfo): void {
    bookPrefs.saveBook(book);
  }

  deleteBook(bookId: string): void {
    bookPrefs.deleteBook(bookId);
  }

  getUserInfo(): UserInfo | null {
    return userPrefs.getUserInfo();
  }

  setUserInfo(userInfo: UserInfo): void {
    userPrefs.setUserInfo(userInfo);
  }

  clearUserInfo(): void {
    userPrefs.clearUserInfo();
  }

  getLanguage(): string {
    return userPrefs.getLanguage();
  }

  setLanguage(language: string): void {
    userPrefs.setLanguage(language);
  }

  getTheme(): string {
    return themePrefs.getTheme();
  }

  setTheme(theme: string): void {
    themePrefs.setTheme(theme);
  }

  getFontScale(): number {
    return readerPrefs.getFontScale();
  }

  setFontScale(scale: number): void {
    readerPrefs.setFontScale(scale);
  }

  getReadSettings(): ReaderSettings {
    return readerPrefs.getReaderSettings();
  }

  setReadSettings(settings: ReaderSettings): void {
    readerPrefs.saveReaderSettings(settings);
  }


  getTtsSpeed(): number {
    return readerPrefs.getTtsSpeed();
  }

  setTtsSpeed(speed: number): void {
    readerPrefs.setTtsSpeed(speed);
  }

  setBookmarks(bookmarks: Record<string, Bookmark[]>): void {
    bookPrefs.setBookmarks(bookmarks);
  }
  getAllBookmarks(): Record<string, Bookmark[]> {
    return bookPrefs.getBookmarksRecord();
  }

  setNotes(notes: Record<string, Note[]>): void {
    bookPrefs.setNotes(notes);
  }
  getNotes(): Record<string, Note[]> {
    return bookPrefs.getNotesRecord();
  }

  addReadRecord(record: ReadRecord): void {
    try {
      const records = bookPrefs.getReadRecords();
      records.push(record);
      bookPrefs.setReadRecords(records);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[PreferenceManager] Add read record failed:', message);
    }
  }

  setReadRecords(records: ReadRecord[]): void {
    bookPrefs.setReadRecords(records);
  }

  getReadRecords(): ReadRecord[] {
    return bookPrefs.getReadRecords();
  }

  getString(key: string, defaultValue: string): string {
    if (!this.pref) return defaultValue;
    try {
      return this.pref.getSync(key, defaultValue) as string;
    } catch {
      return defaultValue;
    }
  }

  async getStringAsync(key: string, defaultValue: string): Promise<string> {
    if (!this.pref) return defaultValue;
    try {
      const value = await this.pref.get(key, defaultValue) as string;
      return value;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[PreferenceManager] Get string async failed:', message);
      return defaultValue;
    }
  }

  setString(key: string, value: string): void {
    if (!this.pref) return;
    try {
      this.pref.putSync(key, value);
      this.pref.flushSync();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[PreferenceManager] Set string failed:', message);
      console.error('[PreferenceManager] Set string failed:', message);
    }
  }

  async setStringAsync(key: string, value: string): Promise<void> {
    if (!this.pref) return;
    try {
      await this.pref.put(key, value);
      await this.pref.flush();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[PreferenceManager] Set string async failed:', message);
      console.error('[PreferenceManager] Set string async failed:', message);
    }
  }

  getValue(key: string, defaultValue: string = ''): string {
    return this.getString(key, defaultValue);
  }

  setValue(key: string, value: string): void {
    this.setString(key, value);
  }

  getNumber(key: string, defaultValue: number = 0): number {
    const value = this.getString(key, '');
    return value === '' ? defaultValue : Number(value);
  }

  setNumber(key: string, value: number): void {
    this.setString(key, String(value));
  }

  deleteValue(key: string): void {
    this.setString(key, '');
  }

  getBookSources(): BookSource[] {
    try {
      const data = this.getString('book_sources', '[]');
      return JSON.parse(data) as BookSource[];
    } catch {
      return [];
    }
  }

  setBookSources(sources: BookSource[]): void {
    this.setString('book_sources', JSON.stringify(sources));
  }

  getReplaceRules(): ReplaceRule[] {
    try {
      const data = this.getString('replace_rules', '[]');
      return JSON.parse(data) as ReplaceRule[];
    } catch {
      return [];
    }
  }

  setReplaceRules(rules: ReplaceRule[]): void {
    this.setString('replace_rules', JSON.stringify(rules));
  }



  getTodoList(): TodoItem[] {
    try {
      const data = this.getString('todo_list', '[]');
      return JSON.parse(data) as TodoItem[];
    } catch {
      return [];
    }
  }

  setTodoList(todos: TodoItem[]): void {
    this.setString('todo_list', JSON.stringify(todos));
  }

  getBookshelfGroups(): BookshelfGroup[] {
    try {
      const data = this.getString('bookshelf_groups', '[]');
      return JSON.parse(data) as BookshelfGroup[];
    } catch {
      return [];
    }
  }

  setBookshelfGroups(groups: BookshelfGroup[]): void {
    this.setString('bookshelf_groups', JSON.stringify(groups));
  }
}

export const preferenceManager = PreferenceManager.getInstance();