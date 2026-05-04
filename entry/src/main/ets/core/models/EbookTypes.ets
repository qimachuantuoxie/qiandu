/**
 * Ebook Types - 閻㈤潧鐡欐稊锔界壐瀵繒娴夐崗宕囪閸ㄥ鐣炬稊? * 
 * 閸栧懎鎯堥幍鈧張澶屾暩鐎涙劒鍔熺憴锝嗙€介惄绋垮彠閻ㄥ嫭甯撮崣锝呮嫲缁鐎风€规矮绠? * 
 * @since 6.0.0
 */

// ==================== PDF 閻╃鍙х猾璇茬€?====================

/** PDF 閺傚洦銆傛穱鈩冧紖 */
export interface PdfInfo {
  Title?: string;
  Author?: string;
  Publisher?: string;
  ISBN?: string;
  Language?: string;
  CreationDate?: string;
  ModDate?: string;
}

/** PDF 婢堆呯堪妞?*/
export interface PdfOutlineItem {
  title?: string;
  Title?: string;
  pageIndex?: number;
  PageIndex?: number;
  children?: PdfOutlineItem[];
}

/** PDF 娑旓妇顒锋い?*/
export interface PdfBookmarkItem {
  title: string;
  pageIndex: number;
  level: number;
}

/** PDF 閺傚洦銆傜€电钖?*/
export interface PdfDocument {
  pageCount: number;
  info: PdfInfo;
  outline: PdfOutlineItem[];
}

// ==================== EPUB 閻╃鍙х猾璇茬€?====================

/** NCX 鐎佃壈鍩呴悙?*/
export interface NavPoint {
  label: string;
  order: number;
  level: number;
}

/** EPUB 濞撳懎宕熸い?*/
export interface ManifestItem {
  id: string;
  href: string;
}

/** EPUB 鐎佃壈鍩呮い?*/
export interface NavItem {
  label: string;
  level: number;
}

/** EPUB HTML 閺傚洣娆?*/
export interface HtmlFile {
  path: string;
  content: string;
}

// ==================== ZIP 閻╃鍙х猾璇茬€?====================

/** ZIP 閺夛紕娲?*/
export interface ZipEntry {
  path: string;
  isDirectory: boolean;
  size: number;
  data: ArrayBuffer | null;
}

/** ZIP 鐟欙絾鐎界紒鎾寸亯 */
export interface ZipParseResult {
  entries: ZipEntry[];
}

// ==================== 闁氨鏁ょ猾璇茬€?====================

/** 娑旓妇鐫勯崗鍐╂殶閹?*/
export interface BookMetadata {
  title: string;
  author: string;
  publisher?: string;
  isbn?: string;
  language?: string;
  description?: string;
  coverData?: string;
  totalPages: number;
  wordCount?: number;
  createdDate?: string;
  modifiedDate?: string;
}

/** 缁旂姾濡穱鈩冧紖 */
export interface LocalChapterInfo {
  id: string;
  title: string;
  startOffset: number;
  endOffset: number;
  level: number;
}

/** 鐟欙絾鐎界紒鎾寸亯 */
export interface ParseResult {
  metadata: BookMetadata;
  content: string;
  chapters: LocalChapterInfo[];
  success: boolean;
  error?: string;
}

// ==================== 閸愬懘鍎存担璺ㄦ暏缁鐎烽敍鍫滅瑝鐎电厧鍤敍?====================

/** PDF 娣団剝浼呯紒鎾寸亯閿涘牆鍞撮柈顭掔礆 */
export interface PdfInfoResult {
  title?: string;
  author?: string;
  subject?: string;
  creator?: string;
  producer?: string;
  creationDate?: string;
  modDate?: string;
  pageCount: number;
}

/** PDF 娑旓妇顒风紒鎾寸亯閿涘牆鍞撮柈顭掔礆 */
export interface PdfBookmarkResult {
  bookmarks: PdfBookmarkItem[];
  count: number;
}
