// 书籍数据模型 - 核心数据结构

/**
 * 书籍模型类
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
    if (info.coverPath !== undefined) {
      this.coverPath = info.coverPath;
    } else {
      this.coverPath = '';
    }
    this.filePath = info.filePath;
    this.format = info.format;
    this.fileSize = info.fileSize;
    this.totalPages = info.totalPages;
    this.currentPage = info.currentPage;
    this.readProgress = info.readProgress;
    this.lastReadTime = info.lastReadTime;
    this.addTime = info.addTime;
    this.status = info.status;
    if (info.description !== undefined) {
      this.description = info.description;
    } else {
      this.description = '';
    }
    if (info.tags !== undefined) {
      this.tags = info.tags;
    } else {
      this.tags = [];
    }
    this.isFavorite = info.isFavorite;
    if (info.groupIds !== undefined) {
      this.groupIds = info.groupIds;
    } else {
      this.groupIds = [];
    }
    if (info.totalReadTime !== undefined) {
      this.totalReadTime = info.totalReadTime;
    } else {
      this.totalReadTime = 0;
    }
  }
}

/**
 * 电子书格式枚举
 */
export enum BookFormat {
  PDF = 'PDF',
  EPUB = 'EPUB',
  MOBI = 'MOBI',
  TXT = 'TXT',
  DOCX = 'DOCX',      // Word 2007+
  DOC = 'DOC',        // Word 97-2003
  RTF = 'RTF',        // 富文本格式
  HTML = 'HTML',      // 网页格式
  ODT = 'ODT',        // OpenDocument 文本
  FB2 = 'FB2',        // FictionBook
  AZW3 = 'AZW3',      // Kindle 格式
  AZW = 'AZW',        // Kindle 旧格式
  CBR = 'CBR',        // 漫画压缩包(RAR)
  CBZ = 'CBZ',        // 漫画压缩包(ZIP)
  DJVU = 'DJVU',      // 扫描文档
  CHM = 'CHM'         // 编译 HTML 帮助
}

/**
 * 阅读状态枚举一
 */
export enum ReadStatus {
  UNREAD = 'unread',
  READING = 'reading',
  FINISHED = 'finished'
}

/**
 * 阅读主题枚举
 */
export enum ReadTheme {
  LIGHT = 'light',      // 白天模式
  SEPIA = 'sepia',      // 护眼模式
  DARK = 'dark',        // 夜间模式
  AUTO = 'auto'         // 自动（跟随系统）
}

/**
 * 翻页模式枚举
 */
export enum PageTurnMode {
  SCROLL = 'scroll',          // 滚动模式
  COVER = 'cover',            // 覆盖模式
  SIMULATION = 'simulation',  // 仿真翻页
  SLIDE = 'slide',            // 滑动翻页
  NONE = 'none'               // 无动画
}

/**
 * 字体选项接口
 */
export interface FontOption {
  name: string;
  value: string;
}

/**
 * 书签接口
 */
export interface Bookmark {
  id: string;                 // 唯一标识
  bookId: string;             // 书籍 ID
  pageNumber: number;         // 页码
  title: string;              // 书签标题
  createTime: number;         // 创建时间戳
  note?: string;              // 备注
}

/**
 * 笔记接口
 */
export interface Note {
  id: string;                 // 唯一标识
  bookId: string;             // 书籍 ID
  pageNumber: number;         // 页码
  content: string;            // 笔记内容
  highlight?: string;         // 高亮文本
  color?: string;             // 高亮颜色
  createTime: number;         // 创建时间戳
  tags?: string[];            // 标签
}

/**
 * 阅读记录接口
 */
export interface ReadRecord {
  id: string;                 // 唯一标识
  bookId: string;             // 书籍 ID
  bookTitle: string;          // 书名
  startTime: number;          // 开始时间戳
  endTime: number;            // 结束时间
  duration: number;           // 阅读时长（秒）
  startPage: number;          // 起始页
  endPage: number;            // 结束页
  note?: string;              // 笔记
}

/**
 * 书架分组接口
 */
export interface BookshelfGroup {
  id: string;                 // 分组 ID
  name: string;               // 分组名称
  color: string;              // 分组颜色
  bookIds: string[];          // 书籍 ID 列表
  createTime: number;         // 创建时间
  sortOrder: number;          // 排序序号
}

/**
 * 封面尺寸配置
 */
export interface CoverDimensions {
  width: number;
  height: number;
}

/**
 * 书籍解析结果
 */
export interface BookInfoResult {
  success: boolean;
  title?: string;
  author?: string;
  bookInfo?: BookInfo;
  error?: string;
}

/**
 * 书籍信息接口 - 核心数据结构
 */
export interface BookInfo {
  id: string;
  title: string;
  author: string;
  coverPath?: string;
  filePath: string;           // 文件路径
  format: BookFormat;         // 文件格式
  fileSize: number;           // 文件大小（字节）
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
 * 阅读设置接口
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
 * 常用字体选项
 */
export const FONT_OPTIONS: FontOption[] = [
  { name: 'system', value: 'system' },
  { name: 'serif', value: 'source_han_serif' },
  { name: 'sans', value: 'source_han_sans' }
];

/**
 * 默认阅读设置
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
 * 格式化文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * 格式化时间
 */
export function formatTime(timestamp: number): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  
  if (diff < 3600000) {
    const minutes = Math.floor(diff / 60000);
    return minutes < 1 ? '刚刚' : minutes + '分钟前';
  }
  if (diff < 86400000) {
    return Math.floor(diff / 3600000) + '小时前';
  }
  if (diff < 604800000) {
    return Math.floor(diff / 86400000) + '天前';
  }
  
  return (date.getMonth() + 1) + '/' + date.getDate();
}

/**
 * 格式化阅读时长
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return seconds + '秒';
  } else if (seconds < 3600) {
    return Math.floor(seconds / 60) + '分钟';
  } else {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return mins > 0 ? hours + '小时' + mins + '分钟' : hours + '小时';
  }
}

export const MOCK_BOOKS: BookInfo[] = [
  {
    id: 'book_1',
    title: '示例书籍',
    author: '示例作者',
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
