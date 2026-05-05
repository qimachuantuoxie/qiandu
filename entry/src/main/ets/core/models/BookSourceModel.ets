// 娑旓附绨弫鐗堝祦濡€崇€?
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
 * 娑旓附绨幒銉ュ經
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
  // 閺傛澘顤冪€涙顔岄敍姘辨暏娴滃骸鎮撳銉ユ嫲缁狅紕鎮?
  importUrl?: string;       // 娑旓附绨€电厧鍙嗛弶銉︾爱URL閿涘牏鏁ゆ禍搴℃倵缂侇厽娲块弬鏉挎倱濮濄儻绱?
  lastSyncTime?: number;    // 閺堚偓閸氬骸鎮撳銉︽闂?
  version?: number;         // 娑旓附绨悧鍫熸拱閸?
  description?: string;     // 娑旓附绨幓蹇氬牚
  sourceCount?: number;     // 娑旓附绨崠鍛儓閻ㄥ嫪鍔熺猾宥嗘殶闁?
}

/**
 * 娑旓附绨猾璇茬€?
 */
export enum BookSourceType {
  TEXT = 'text',
  AUDIO = 'audio',
  IMAGE = 'image'
}

/**
 * 閹兼粎鍌ㄧ紒鎾寸亯
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
 * 閸︺劎鍤庢稊锔剧潉娣団剝浼?
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
 * 缁旂姾濡崘鍛啇
 */
export interface ChapterContent {
  bookId: string;
  sourceId: string;
  chapters: ChapterInfo[];
  toc?: ChapterInfo[];
}

/**
 * 缁旂姾濡穱鈩冧紖
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
 * 閺囨寧宕茬憴鍕灟
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
 * 閺囨寧宕查懠鍐ㄦ纯
 */
export enum ReplaceScope {
  TITLE = 'title',
  AUTHOR = 'author',
  CONTENT = 'content',
  COVER = 'cover',
  DESCRIPTION = 'description'
}

/**
 * 姒涙顓绘稊锔界爱
 */
// DEFAULT_BOOK_SOURCES removed - load from storage or network only
// Empty array as default - actual sources should be loaded from storage
export const DEFAULT_BOOK_SOURCES: BookSource[] = [];

// Default replace rules (can be empty)
export const DEFAULT_REPLACE_RULES: ReplaceRule[] = [];

/**
 * 閻㈢喐鍨氭稊锔界爱ID
 */
export function generateSourceId(): string {
  return `source_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * 妤犲矁鐦夋稊锔界爱
 */
export function validateBookSource(source: BookSource): boolean {
  return !!(source.id && source.name && source.url);
}

/**
 * 鐎电厧鍙嗙紒鎾寸亯
 */
export interface ImportResult {
  success: number;
  fail: number;
  total: number;
  message: string;
}
