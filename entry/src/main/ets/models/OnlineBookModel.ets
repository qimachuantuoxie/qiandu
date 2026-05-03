/**
 * 鍦ㄧ嚎涔︾睄淇℃伅妯″瀷
 * 鎵╁睍 BookInfo 鏀寔缃戠粶涔︾睄
 * 
 * @since 2.8.0
 */

import { BookInfo, BookFormat, ReadStatus } from './BookModel';

/**
 * 鍦ㄧ嚎鎼滅储缁撴灉
 */
export interface OnlineSearchResult {
  /** 涔︾睄鍚嶇О */
  bookName: string;
  /** 浣滆€?*/
  author: string;
  /** 灏侀潰URL */
  coverUrl: string;
  /** 涔︾睄璇︽儏椤礥RL */
  bookUrl: string;
  /** 涔︽簮ID */
  sourceId: string;
  /** 涔︽簮鍚嶇О */
  sourceName: string;
  /** 鏈€鏂扮珷鑺?*/
  latestChapter: string;
  /** 绠€浠?*/
  intro: string;
  /** 瀛楁暟 */
  wordCount: number;
  /** 鏇存柊鏃堕棿 */
  updateTime: string;
}

/**
 * 鍦ㄧ嚎涔︾睄璇︽儏
 */
export interface OnlineBookDetail {
  /** 涔︾睄鍚嶇О */
  title: string;
  /** 浣滆€?*/
  author: string;
  /** 灏侀潰URL */
  coverUrl: string;
  /** 涔︾睄璇︽儏椤礥RL */
  bookUrl: string;
  /** 涔︽簮ID */
  sourceId: string;
  /** 绠€浠?*/
  intro: string;
  /** 鏈€鏂扮珷鑺?*/
  latestChapter: string;
  /** 瀛楁暟 */
  wordCount: number;
  /** 鏇存柊鏃堕棿 */
  updateTime: string;
  /** 鍒嗙被 */
  category: string;
  /** 鐘舵€侊紙杩炶浇/瀹岀粨锛?*/
  status: string;
  /** 鐩綍 */
  toc?: OnlineChapterInfo[];
}

/**
 * 鍦ㄧ嚎绔犺妭淇℃伅
 */
export interface OnlineChapterInfo {
  /** 绔犺妭绱㈠紩 */
  index: number;
  /** 绔犺妭鏍囬 */
  title: string;
  /** 绔犺妭URL */
  url: string;
  /** 鏄惁VIP */
  isVip: boolean;
  /** 瀛楁暟 */
  wordCount: number;
  /** 鏇存柊鏃堕棿 */
  updateTime: string;
  /** 鍐呭锛堝姞杞藉悗锛?*/
  content?: string;
}

/**
 * 鍦ㄧ嚎涔︾睄缂撳瓨
 */
export interface OnlineBookCache {
  /** 涔︾睄璇︽儏 */
  detail: OnlineBookDetail;
  /** 鐩綍 */
  toc: OnlineChapterInfo[];
  /** 宸茬紦瀛樼殑绔犺妭鍐呭 */
  cachedChapters: Map<number, string>;
  /** 缂撳瓨鏃堕棿 */
  cacheTime: number;
}

/**
 * 鍦ㄧ嚎涔︾睄淇℃伅锛堟墿灞?BookInfo锛?
 */
export interface OnlineBookInfo {
  /** 涔︾睄鍞竴鏍囪瘑 */
  id: string;
  /** 涔﹀悕 */
  title: string;
  /** 浣滆€?*/
  author: string;
  /** 鏂囦欢璺緞锛堝湪绾夸功绫嶄负绌猴級 */
  filePath: string;
  /** 灏侀潰璺緞 */
  coverPath: string;
  /** 涔︾睄鏍煎紡 */
  format: BookFormat;
  /** 鎬婚〉鏁?*/
  totalPages: number;
  /** 褰撳墠椤?*/
  currentPage: number;
  /** 闃呰杩涘害 */
  readProgress: number;
  /** 鏈€鍚庨槄璇绘椂闂?*/
  lastReadTime: number;
  /** 娣诲姞鏃堕棿 */
  addTime: number;
  /** 闃呰鐘舵€?*/
  status: ReadStatus;
  /** 鏄惁鏀惰棌 */
  isFavorite: boolean;
  /** 鎵€灞炲垎缁?*/
  groupIds: string[];
  /** 鎬婚槄璇绘椂闀?*/
  totalReadTime: number;
  /** 鏂囦欢澶у皬 */
  fileSize: number;
  /** 涔︾睄璇︽儏椤礥RL */
  bookUrl: string;
  /** 涔︽簮ID */
  sourceId: string;
  /** 涔︽簮鍚嶇О */
  sourceName: string;
  /** 鏄惁涓哄湪绾夸功绫?*/
  isOnline: boolean;
  /** 绠€浠?*/
  intro: string;
  /** 鏈€鏂扮珷鑺?*/
  latestChapter: string;
  /** 涔︾睄鎻忚堪锛堝彲閫夛級 */
  description?: string;
  /** 鏍囩锛堝彲閫夛級 */
  tags?: string[];
}

/**
 * 灏嗗湪绾挎悳绱㈢粨鏋滆浆鎹负 OnlineBookInfo
 */
export function convertOnlineSearchToBookInfo(
  searchResult: OnlineSearchResult
): OnlineBookInfo {
  const bookInfo: OnlineBookInfo = {
    id: `online_${searchResult.sourceId}_${Date.now()}`,
    title: searchResult.bookName,
    author: searchResult.author,
    filePath: '',
    coverPath: searchResult.coverUrl,
    format: BookFormat.TXT,
    totalPages: 0,
    currentPage: 0,
    readProgress: 0,
    lastReadTime: 0,
    addTime: Date.now(),
    status: ReadStatus.UNREAD,
    isFavorite: false,
    groupIds: [],
    totalReadTime: 0,
    fileSize: 0,
    bookUrl: searchResult.bookUrl,
    sourceId: searchResult.sourceId,
    sourceName: searchResult.sourceName,
    isOnline: true,
    intro: searchResult.intro,
    latestChapter: searchResult.latestChapter
  };
  return bookInfo;
}
