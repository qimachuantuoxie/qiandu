// 涔︽簮鏁版嵁妯″瀷
// Book Source Data Models

export interface SearchRule {
  searchUrl?: string;
  bookList?: string;
  name?: string;
  author?: string;
  cover?: string;
  coverUrl?: string;
  desc?: string;
  intro?: string;
  detail?: string;
  bookUrl?: string;
  latestChapter?: string;
  wordCount?: string;
  updateTime?: string;
}

export interface BookInfoRule {
  infoBox?: string;
  cover?: string;
  coverUrl?: string;
  title?: string;
  name?: string;
  author?: string;
  desc?: string;
  intro?: string;
  category?: string;
  status?: string;
  lastChapter?: string;
  wordCount?: string;
}

export interface ContentRule {
  content?: string;
  replaceRegex?: string;
  payNeed?: string;
  nextContent?: string;
  prevContent?: string;
}

export interface TocRule {
  tocList?: string;
  chapterName?: string;
  chapterUrl?: string;
  isVip?: string;
  chapterSize?: string;
  updateTime?: string;
}

/**
 * 涔︽簮鎺ュ彛
 */
export interface BookSource {
  id: string;
  name: string;
  url: string;
  enabled: boolean;
  lastUsed?: number;
  priority: number;
  weight: number;
  exploreUrl?: string;
  bookSourceType: BookSourceType;
  loginRequired: boolean;
  headers?: Record<string, string>;
  ruleSearch?: string | SearchRule;
  ruleBookInfo?: string | BookInfoRule;
  ruleContent?: string | ContentRule;
  ruleToc?: string | TocRule;
  createTime?: number;
  lastUpdateTime?: number;
  // 鏂板瀛楁锛氱敤浜庡悓姝ュ拰绠＄悊
  importUrl?: string;       // 涔︽簮瀵煎叆鏉ユ簮URL锛堢敤浜庡悗缁洿鏂板悓姝ワ級
  lastSyncTime?: number;    // 鏈€鍚庡悓姝ユ椂闂?
  version?: number;         // 涔︽簮鐗堟湰鍙?
  description?: string;     // 涔︽簮鎻忚堪
  sourceCount?: number;     // 涔︽簮鍖呭惈鐨勪功绫嶆暟閲?
}

/**
 * 涔︽簮绫诲瀷
 */
export enum BookSourceType {
  TEXT = 'text',
  AUDIO = 'audio',
  IMAGE = 'image'
}

/**
 * 鎼滅储缁撴灉
 */
export interface SearchResult {
  id?: string;
  name?: string;
  title?: string;
  author?: string;
  intro?: string;
  description?: string;
  cover?: string;
  bookUrl?: string;
  sourceId: string;
  sourceName: string;
  total?: number;
  page?: number;
  pageSize?: number;
  books?: OnlineBookInfo[];
}

/**
 * 鍦ㄧ嚎涔︾睄淇℃伅
 */
export interface OnlineBookInfo {
  sourceId: string;
  sourceName: string;
  bookId: string;
  title: string;
  author: string;
  cover?: string;
  description?: string;
  genres?: string[];
  status?: string;
  latestChapter?: string;
  chapterCount?: number;
  updateTime?: string;
}

/**
 * 绔犺妭鍐呭
 */
export interface ChapterContent {
  bookId: string;
  sourceId: string;
  chapters: ChapterInfo[];
  toc?: ChapterInfo[];
}

/**
 * 绔犺妭淇℃伅
 */
export interface ChapterInfo {
  index: number;
  title: string;
  url: string;
  content?: string;
  wordCount?: number;
  isVip?: boolean;
}

/**
 * 鏇挎崲瑙勫垯
 */
export interface ReplaceRule {
  id: string;
  name: string;
  sourceId: string;
  enabled: boolean;
  pattern: string;
  replacement: string;
  scope: ReplaceScope | string;
  isRegex?: boolean;
}

/**
 * 鏇挎崲鑼冨洿
 */
export enum ReplaceScope {
  TITLE = 'title',
  AUTHOR = 'author',
  CONTENT = 'content',
  COVER = 'cover',
  DESCRIPTION = 'description'
}

/**
 * 榛樿涔︽簮
 */
export const DEFAULT_BOOK_SOURCES: BookSource[] = [
  {
    id: 'source_001',
    name: '榛樿涔︽簮',
    url: 'https://api.example.com',
    enabled: true,
    weight: 10,
    priority: 1,
    bookSourceType: BookSourceType.TEXT,
    loginRequired: false
  }
];

/**
 * 榛樿鏇挎崲瑙勫垯
 */
export const DEFAULT_REPLACE_RULES: ReplaceRule[] = [];

/**
 * 鐢熸垚涔︽簮ID
 */
export function generateSourceId(): string {
  return `source_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * 楠岃瘉涔︽簮
 */
export function validateBookSource(source: BookSource): boolean {
  return !!(source.id && source.name && source.url);
}

/**
 * 瀵煎叆缁撴灉
 */
export interface ImportResult {
  success: number;
  fail: number;
  total: number;
  message: string;
}
