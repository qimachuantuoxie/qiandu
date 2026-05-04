// 涔︾睄鏁版嵁妯″瀷 - 鏍稿績鏁版嵁缁撴瀯

/**
 * 涔︾睄妯″瀷绫?
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
 * 鐢靛瓙涔︽牸寮忔灇涓?
 */
export enum BookFormat {
  PDF = 'PDF',
  EPUB = 'EPUB',
  MOBI = 'MOBI',
  TXT = 'TXT',
  DOCX = 'DOCX',      // Word 2007+
  DOC = 'DOC',        // Word 97-2003
  RTF = 'RTF',        // 瀵屾枃鏈牸寮?
  HTML = 'HTML',      // 缃戦〉鏍煎紡
  ODT = 'ODT',        // OpenDocument 鏂囨湰
  FB2 = 'FB2',        // FictionBook
  AZW3 = 'AZW3',      // Kindle 鏍煎紡
  AZW = 'AZW',        // Kindle 鏃ф牸寮?
  CBR = 'CBR',        // 婕敾鍘嬬缉鍖?RAR)
  CBZ = 'CBZ',        // 婕敾鍘嬬缉鍖?ZIP)
  DJVU = 'DJVU',      // 鎵弿鏂囨。
  CHM = 'CHM'         // 缂栬瘧 HTML 甯姪
}

/**
 * 闃呰鐘舵€佹灇涓句竴
 */
export enum ReadStatus {
  UNREAD = 'unread',
  READING = 'reading',
  FINISHED = 'finished'
}

/**
 * 闃呰涓婚鏋氫妇
 */
export enum ReadTheme {
  LIGHT = 'light',      // 鐧藉ぉ妯″紡
  SEPIA = 'sepia',      // 鎶ょ溂妯″紡
  DARK = 'dark',        // 澶滈棿妯″紡
  AUTO = 'auto'         // 鑷姩锛堣窡闅忕郴缁燂級
}

/**
 * 缈婚〉妯″紡鏋氫妇
 */
export enum PageTurnMode {
  SCROLL = 'scroll',          // 婊氬姩妯″紡
  COVER = 'cover',            // 瑕嗙洊妯″紡
  SIMULATION = 'simulation',  // 浠跨湡缈婚〉
  SLIDE = 'slide',            // 婊戝姩缈婚〉
  NONE = 'none'               // 鏃犲姩鐢?
}

/**
 * 瀛椾綋閫夐」鎺ュ彛
 */
export interface FontOption {
  name: string;
  value: string;
}

/**
 * 涔︾鎺ュ彛
 */
export interface Bookmark {
  id: string;                 // 鍞竴鏍囪瘑
  bookId: string;             // 涔︾睄 ID
  pageNumber: number;         // 椤电爜
  title: string;              // 涔︾鏍囬
  createTime: number;         // 鍒涘缓鏃堕棿鎴?
  note?: string;              // 澶囨敞
}

/**
 * 绗旇鎺ュ彛
 */
export interface Note {
  id: string;                 // 鍞竴鏍囪瘑
  bookId: string;             // 涔︾睄 ID
  pageNumber: number;         // 椤电爜
  content: string;            // 绗旇鍐呭
  highlight?: string;         // 楂樹寒鏂囨湰
  color?: string;             // 楂樹寒棰滆壊
  createTime: number;         // 鍒涘缓鏃堕棿鎴?
  tags?: string[];            // 鏍囩
}

/**
 * 闃呰璁板綍鎺ュ彛
 */
export interface ReadRecord {
  id: string;                 // 鍞竴鏍囪瘑
  bookId: string;             // 涔︾睄 ID
  bookTitle: string;          // 涔﹀悕
  startTime: number;          // 寮€濮嬫椂闂存埑
  endTime: number;            // 缁撴潫鏃堕棿
  duration: number;           // 闃呰鏃堕暱锛堢锛?
  startPage: number;          // 璧峰椤?
  endPage: number;            // 缁撴潫椤?
  note?: string;              // 绗旇
}

/**
 * 涔︽灦鍒嗙粍鎺ュ彛
 */
export interface BookshelfGroup {
  id: string;                 // 鍒嗙粍 ID
  name: string;               // 鍒嗙粍鍚嶇О
  color: string;              // 鍒嗙粍棰滆壊
  bookIds: string[];          // 涔︾睄 ID 鍒楄〃
  createTime: number;         // 鍒涘缓鏃堕棿
  sortOrder: number;          // 鎺掑簭搴忓彿
}

/**
 * 灏侀潰灏哄閰嶇疆
 */
export interface CoverDimensions {
  width: number;
  height: number;
}

/**
 * 涔︾睄瑙ｆ瀽缁撴灉
 */
export interface BookInfoResult {
  success: boolean;
  title?: string;
  author?: string;
  bookInfo?: BookInfo;
  error?: string;
}

/**
 * 涔︾睄淇℃伅鎺ュ彛 - 鏍稿績鏁版嵁缁撴瀯
 */
export interface BookInfo {
  id: string;                 // 鍞竴鏍囪瘑
  title: string;              // 涔﹀悕
  author: string;             // 浣滆€?
  coverPath?: string;         // 灏侀潰璺緞
  filePath: string;           // 鏂囦欢璺緞
  format: BookFormat;         // 鏂囦欢鏍煎紡
  fileSize: number;           // 鏂囦欢澶у皬锛堝瓧鑺傦級
  totalPages: number;         // 鎬婚〉鏁?
  currentPage: number;        // 褰撳墠椤?
  readProgress: number;       // 闃呰杩涘害锛?-100锛?
  lastReadTime: number;       // 鏈€鍚庨槄璇绘椂闂存埑
  addTime: number;            // 娣诲姞鏃堕棿
  status: ReadStatus;         // 闃呰鐘舵€?
  description?: string;       // 涔︾睄鎻忚堪
  tags?: string[];            // 鏍囩
  isFavorite: boolean;        // 鏄惁鏀惰棌
  groupIds?: string[];        // 鎵€灞炲垎缁?ID 鍒楄〃)
  totalReadTime?: number;     // 鎬婚槄璇绘椂闀匡紙绉掞級
  readStatus?: ReadStatus;    // 闃呰鐘舵€侊紙鍐椾綑瀛楁锛屽吋瀹规棫浠ｇ爜锛?
  lastReadPosition?: number;  // 鏈€鍚庨槄璇讳綅缃紙椤电爜/鍋忕Щ锛?
}

/**
 * 闃呰璁剧疆鎺ュ彛
 */
export interface ReadSettings {
  fontSize: number;           // 瀛椾綋澶у皬
  lineSpacing: number;        // 琛岄棿璺?
  theme: ReadTheme;           // 闃呰涓婚
  brightness: number;         // 浜害 (0-100)
  screenOrientation: number;  // 灞忓箷鏂瑰悜
  pageTurnMode: PageTurnMode; // 缈婚〉妯″紡
  fontFamily: string;         // 瀛椾綋
  paragraphSpacing: number;   // 娈甸棿璺?
  letterSpacing: number;      // 瀛楅棿璺?
  textIndent: number;         // 棣栬缂╄繘
}

/**
 * 甯哥敤瀛椾綋閫夐」
 */
export const FONT_OPTIONS: FontOption[] = [
  { name: 'system', value: 'system' },
  { name: 'source_han_serif', value: 'source_han_serif' },
  { name: 'source_han_sans', value: 'source_han_sans' },
  { name: 'lxgw_wenkai', value: 'lxgw_wenkai' },
  { name: 'ysbth', value: 'ysbth' }
];

/**
 * 榛樿闃呰璁剧疆
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
 * 鏍煎紡鍖栨枃浠跺ぇ灏?
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  const value = parseFloat((bytes / Math.pow(k, i)).toFixed(2));
  return value.toString() + ' ' + sizes[i];
}

/**
 * 鏍煎紡鍖栨椂闂?
 */
export function formatTime(timestamp: number): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diff = now.getTime() - date.getTime();

  if (diff < 3600000) {
    const minutes = Math.floor(diff / 60000);
    return minutes < 1 ? '鍒氬垰' : minutes.toString() + '鍒嗛挓鍓?;
  }
  if (diff < 86400000) {
    return Math.floor(diff / 3600000).toString() + '灏忔椂鍓?;
  }
  if (diff < 604800000) {
    return Math.floor(diff / 86400000).toString() + '澶╁墠';
  }

  return (date.getMonth() + 1).toString() + '鏈? + date.getDate().toString() + '鏃?;
}

/**
 * 鏍煎紡鍖栭槄璇绘椂闀?
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return seconds.toString() + '绉?;
  } else if (seconds < 3600) {
    const mins = Math.floor(seconds / 60);
    return mins.toString() + '鍒嗛挓';
  } else {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return mins > 0 ? hours.toString() + '灏忔椂' + mins.toString() + '鍒嗛挓' : hours.toString() + '灏忔椂';
  }
}

export const MOCK_BOOKS: BookInfo[] = [
  {
    id: 'book_1',
    title: '绀轰緥涔︾睄',
    author: '绀轰緥浣滆€?,
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
