/**
 * Ebook Types - 鐢靛瓙涔︽牸寮忕浉鍏崇被鍨嬪畾涔? * 
 * 鍖呭惈鎵€鏈夌數瀛愪功瑙ｆ瀽鐩稿叧鐨勬帴鍙ｅ拰绫诲瀷瀹氫箟
 * 
 * @since 6.0.0
 */

// ==================== PDF 鐩稿叧绫诲瀷 ====================

/** PDF 鏂囨。淇℃伅 */
export interface PdfInfo {
  Title?: string;
  Author?: string;
  Publisher?: string;
  ISBN?: string;
  Language?: string;
  CreationDate?: string;
  ModDate?: string;
}

/** PDF 澶х翰椤?*/
export interface PdfOutlineItem {
  title?: string;
  Title?: string;
  pageIndex?: number;
  PageIndex?: number;
  children?: PdfOutlineItem[];
}

/** PDF 涔︾椤?*/
export interface PdfBookmarkItem {
  title: string;
  pageIndex: number;
  level: number;
}

/** PDF 鏂囨。瀵硅薄 */
export interface PdfDocument {
  pageCount: number;
  info: PdfInfo;
  outline: PdfOutlineItem[];
}

// ==================== EPUB 鐩稿叧绫诲瀷 ====================

/** NCX 瀵艰埅鐐?*/
export interface NavPoint {
  label: string;
  order: number;
  level: number;
}

/** EPUB 娓呭崟椤?*/
export interface ManifestItem {
  id: string;
  href: string;
}

/** EPUB 瀵艰埅椤?*/
export interface NavItem {
  label: string;
  level: number;
}

/** EPUB HTML 鏂囦欢 */
export interface HtmlFile {
  path: string;
  content: string;
}

// ==================== ZIP 鐩稿叧绫诲瀷 ====================

/** ZIP 鏉＄洰 */
export interface ZipEntry {
  path: string;
  isDirectory: boolean;
  size: number;
  data: ArrayBuffer | null;
}

/** ZIP 瑙ｆ瀽缁撴灉 */
export interface ZipParseResult {
  entries: ZipEntry[];
}

// ==================== 閫氱敤绫诲瀷 ====================

/** 涔︾睄鍏冩暟鎹?*/
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

/** 绔犺妭淇℃伅 */
export interface LocalChapterInfo {
  id: string;
  title: string;
  startOffset: number;
  endOffset: number;
  level: number;
}

/** 瑙ｆ瀽缁撴灉 */
export interface ParseResult {
  metadata: BookMetadata;
  content: string;
  chapters: LocalChapterInfo[];
  success: boolean;
  error?: string;
}

// ==================== 鍐呴儴浣跨敤绫诲瀷锛堜笉瀵煎嚭锛?====================

/** PDF 淇℃伅缁撴灉锛堝唴閮級 */
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

/** PDF 涔︾缁撴灉锛堝唴閮級 */
export interface PdfBookmarkResult {
  bookmarks: PdfBookmarkItem[];
  count: number;
}
