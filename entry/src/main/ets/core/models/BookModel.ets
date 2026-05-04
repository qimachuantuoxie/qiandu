// Book data model - Core data structures

/**
 * Book model class
 */
export class BookModelClass {
  id: string = '';
  title: string = '';
  author: string = '';
  coverPath: string = '';
  filePath: string = '';
  format: BookFormat = BookFormat.EPUB;
  fileSize: number = 0;
  totalPages: number = 0;
  currentPage: number = 0;
  readProgress: number = 0;
  lastReadTime: number = 0;
  addTime: number = 0;
  status: ReadStatus = ReadStatus.UNREAD;
  description: string = '';
  tags: string[] = [];
  isFavorite: boolean = false;
  groupIds: string[] = [];
  totalReadTime: number = 0;

  constructor(info: BookInfo) {
    this.id = info.id;
    this.title = info.title;
    this.author = info.author;
    this.coverPath = info.coverPath || '';
    this.filePath = info.filePath;
    this.format = info.format;
    this.fileSize = info.fileSize;
    this.totalPages = info.totalPages;
    this.currentPage = info.currentPage;
    this.readProgress = info.readProgress;
    this.lastReadTime = info.lastReadTime;
    this.addTime = info.addTime;
    this.status = info.status;
    this.description = info.description || '';
    this.tags = info.tags || [];
    this.isFavorite = info.isFavorite;
    this.groupIds = info.groupIds || [];
    this.totalReadTime = info.totalReadTime || 0;
  }
}

/**
 * E-book format enum
 */
export enum BookFormat {
  PDF = 'PDF',
  EPUB = 'EPUB',
  MOBI = 'MOBI',
  TXT = 'TXT',
  DOCX = 'DOCX',
  DOC = 'DOC',
  RTF = 'RTF',
  HTML = 'HTML',
  ODT = 'ODT',
  FB2 = 'FB2',
  AZW3 = 'AZW3',
  AZW = 'AZW',
  CBR = 'CBR',
  CBZ = 'CBZ',
  DJVU = 'DJVU',
  CHM = 'CHM',
  MD = 'MD'
}

/**
 * Read status enum
 */
export enum ReadStatus {
  UNREAD = 'unread',
  READING = 'reading',
  FINISHED = 'finished'
}

/**
 * Read theme enum
 */
export enum ReadTheme {
  LIGHT = 'light',
  SEPIA = 'sepia',
  DARK = 'dark',
  AUTO = 'auto'
}

/**
 * Page turn mode enum
 */
export enum PageTurnMode {
  SCROLL = 'scroll',
  COVER = 'cover',
  SIMULATION = 'simulation',
  SLIDE = 'slide',
  NONE = 'none'
}

/**
 * Font option interface
 */
export interface FontOption {
  name: string;
  value: string;
}

/**
 * Bookmark interface
 */
export interface Bookmark {
  id: string;
  bookId: string;
  pageNumber: number;
  title: string;
  createTime: number;
  note?: string;
}

/**
 * Note interface
 */
export interface Note {
  id: string;
  bookId: string;
  pageNumber: number;
  content: string;
  highlight?: string;
  color?: string;
  createTime: number;
  tags?: string[];
}

/**
 * Read record interface
 */
export interface ReadRecord {
  id: string;
  bookId: string;
  bookTitle: string;
  startTime: number;
  endTime: number;
  duration: number;
  startPage: number;
  endPage: number;
  note?: string;
  date?: string;
}

/**
 * Bookshelf group interface
 */
export interface BookshelfGroup {
  id: string;
  name: string;
  color: string;
  bookIds: string[];
  createTime: number;
  sortOrder: number;
}

/**
 * Cover dimensions interface
 */
export interface CoverDimensions {
  width: number;
  height: number;
}

/**
 * Book parse result
 */
export interface BookInfoResult {
  success: boolean;
  title?: string;
  author?: string;
  bookInfo?: BookInfo;
  error?: string;
}

/**
 * Book info interface - Core data structure
 */
export interface BookInfo {
  id: string;
  title: string;
  author: string;
  coverPath?: string;
  filePath: string;
  format: BookFormat;
  fileSize: number;
  totalPages: number;
  currentPage: number;
  readProgress: number;
  lastReadTime: number;
  addTime: number;
  status: ReadStatus;
  description?: string;
  tags?: string[];
  isFavorite: boolean;
  groupIds?: string[];
  totalReadTime?: number;
  readStatus?: ReadStatus;
  lastReadPosition?: number;
}

// Type aliases for Record<string, T> (ArkTS strict compliance)
export type BooksMap = Map<string, BookInfo>;
export type BookmarksMap = Map<string, Bookmark[]>;
export type NotesMap = Map<string, Note[]>;
export type GroupsMap = Map<string, BookshelfGroup>;
export type FormatColorMap = Map<BookFormat, string>;

/**
 * Read settings interface
 */
export interface ReadSettings {
  fontSize: number;
  lineSpacing: number;
  theme: ReadTheme;
  brightness: number;
  screenOrientation: number;
  pageTurnMode: PageTurnMode;
  fontFamily: string;
  paragraphSpacing: number;
  letterSpacing: number;
  textIndent: number;
  fontName?: string;
  lineHeight?: number;
  volumeKeyEnabled?: boolean;
  clickEnabled?: boolean;
  keepScreenOn?: boolean;
  autoPageSpeed?: number;
}

/**
 * Common font options
 */
export const FONT_OPTIONS: FontOption[] = [
  { name: 'system', value: 'system' },
  { name: 'serif', value: 'source_han_serif' },
  { name: 'sans', value: 'source_han_sans' }
];

/**
 * Default read settings
 */
export const DEFAULT_READ_SETTINGS: ReadSettings = {
  fontSize: 18,
  lineSpacing: 1.5,
  theme: ReadTheme.LIGHT,
  brightness: 100,
  screenOrientation: 0,
  pageTurnMode: PageTurnMode.SCROLL,
  fontFamily: 'system',
  paragraphSpacing: 12,
  letterSpacing: 0,
  textIndent: 2
};

let bookIdCounter = 0;

export function generateBookId(): string {
  return Date.now().toString(36) + (++bookIdCounter).toString(36);
}

/**
 * Format file size
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Format time
 */
export function formatTime(timestamp: number): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  
  if (diff < 3600000) {
    const minutes = Math.floor(diff / 60000);
    return minutes < 1 ? 'just now' : minutes + ' min ago';
  }
  if (diff < 86400000) {
    return Math.floor(diff / 3600000) + ' hours ago';
  }
  if (diff < 604800000) {
    return Math.floor(diff / 86400000) + ' days ago';
  }
  
  return (date.getMonth() + 1) + '/' + date.getDate();
}

/**
 * Format read duration
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return seconds + 's';
  } else if (seconds < 3600) {
    return Math.floor(seconds / 60) + 'm';
  } else {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return mins > 0 ? hours + 'h ' + mins + 'm' : hours + 'h';
  }
}

export const MOCK_BOOKS: BookInfo[] = [
  {
    id: 'book_1',
    title: 'Example Book',
    author: 'Example Author',
    filePath: '/data/example.txt',
    format: BookFormat.TXT,
    fileSize: 1024000,
    totalPages: 100,
    currentPage: 0,
    readProgress: 0,
    lastReadTime: 0,
    addTime: Date.now(),
    status: ReadStatus.UNREAD,
    isFavorite: false,
    groupIds: ['default']
  }
];