// 书源数据模型
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
 * 书源接口
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
  // 新增字段：用于同步和管理
  importUrl?: string;       // 书源导入来源URL（用于后续更新同步）
  lastSyncTime?: number;    // 最后同步时间
  version?: number;         // 书源版本号
  description?: string;     // 书源描述
  sourceCount?: number;     // 书源包含的书籍数量
}

/**
 * 书源类型
 */
export enum BookSourceType {
  TEXT = 'text',
  AUDIO = 'audio',
  IMAGE = 'image'
}

/**
 * 搜索结果
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
  books?: SourceBookInfo[];
}

/**
 * 在线书籍信息（书源搜索结果）
 */
export interface SourceBookInfo {
  sourceId: string;
  sourceName: string;
  bookId: string;
  bookUrl: string;
  title: string;
  author: string;
  cover?: string;
  coverUrl?: string;
  description?: string;
  intro?: string;
  genres?: string[];
  status?: string;
  latestChapter?: string;
  chapterCount?: number;
  wordCount?: number;
  updateTime?: string;
  chapters?: string[];
}

/**
 * 章节内容
 */
export interface ChapterContent {
  bookId: string;
  sourceId: string;
  chapters: ChapterInfo[];
  toc?: ChapterInfo[];
}

/**
 * 章节信息
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
 * 替换规则
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
 * 替换范围
 */
export enum ReplaceScope {
  TITLE = 'title',
  AUTHOR = 'author',
  CONTENT = 'content',
  COVER = 'cover',
  DESCRIPTION = 'description'
}

/**
 * 默认书源
 */
export const DEFAULT_BOOK_SOURCES: BookSource[] = [
  {
    id: 'source_001',
    name: '默认书源',
    url: 'https://api.example.com',
    enabled: true,
    weight: 10,
    priority: 1,
    bookSourceType: BookSourceType.TEXT,
    loginRequired: false
  }
];

/**
 * 默认替换规则
 */
export const DEFAULT_REPLACE_RULES: ReplaceRule[] = [];
