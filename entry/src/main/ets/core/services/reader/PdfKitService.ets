/**
 * PDF Kit 鏈嶅姟 - 鍩轰簬 HarmonyOS 瀹樻柟 PDF 澶勭悊鏈嶅姟
 * 
 * 鎻愪緵 PDF 鏂囨。娴忚銆佹覆鏌撹兘鍔? * 
 * @since API 16 (HarmonyOS 5.0.4+)
 */

import { pdfService } from '@kit.PDFKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const LOG_TAG = 'PdfKitService';
const LOG_DOMAIN = 0x0002;

/**
 * PDF 鏂囨。淇℃伅
 */
export interface PdfDocumentInfo {
  pageCount: number;
  title?: string;
  author?: string;
  subject?: string;
  creator?: string;
  producer?: string;
  isEncrypted: boolean;
}

/**
 * PDF 椤甸潰淇℃伅
 */
export interface PdfPageInfo {
  width: number;
  height: number;
  rotation: number;
}

/**
 * PDF 涔︾
 */
export interface PdfBookmark {
  title: string;
  pageIndex: number;
  level: number;
  children?: PdfBookmark[];
}

/**
 * PDF Kit 鏈嶅姟绫? */
export class PdfKitService {
  private pdfDocument: pdfService.PdfDocument | null = null;
  private currentFilePath: string = '';

  /**
   * 鎵撳紑 PDF 鏂囨。
   * @param filePath PDF 鏂囦欢璺緞
   */
  async openPdf(filePath: string): Promise<PdfDocumentInfo> {
    try {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Opening PDF: %{public}s', filePath);
      
      // 鎵撳紑 PDF 鏂囨。
      this.pdfDocument = await pdfService.openDocument(filePath);
      this.currentFilePath = filePath;
      
      // 鑾峰彇鏂囨。淇℃伅
      const pageInfo = await this.pdfDocument.getPageInfo(0);
      const info: PdfDocumentInfo = {
        pageCount: await this.pdfDocument.getPageCount(),
        title: '',
        author: '',
        subject: '',
        creator: '',
        producer: '',
        isEncrypted: false
      };
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'PDF opened successfully, pages: %{public}d', info.pageCount);
      return info;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to open PDF: %{public}s', 
        (error as BusinessError).message);
      throw error;
    }
  }

  /**
   * 鑾峰彇椤甸潰鏁伴噺
   */
  async getPageCount(): Promise<number> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    return await this.pdfDocument.getPageCount();
  }

  /**
   * 鑾峰彇椤甸潰淇℃伅
   * @param pageIndex 椤电爜锛堜粠0寮€濮嬶級
   */
  async getPageInfo(pageIndex: number): Promise<PdfPageInfo> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    return await this.pdfDocument.getPageInfo(pageIndex);
  }

  /**
   * 娓叉煋椤甸潰涓哄浘鐗?   * @param pageIndex 椤电爜
   * @param width 瀹藉害
   * @param height 楂樺害
   * @param dpi DPI锛堥粯璁?50锛?   */
  async renderPage(pageIndex: number, width: number, height: number, dpi: number = 150): Promise<image.PixelMap> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    // 鍒涘缓娓叉煋鍙傛暟
    const renderParam: pdfService.RenderParam = {
      width: width,
      height: height,
      dpi: dpi
    };
    
    // 娓叉煋椤甸潰
    const pixelMap = await this.pdfDocument.renderPage(pageIndex, renderParam);
    return pixelMap;
  }

  /**
   * 鑾峰彇 PDF 涔︾
   */
  async getBookmarks(): Promise<PdfBookmark[]> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    try {
      const bookmarks = await this.pdfDocument.getBookmarks();
      return this.convertBookmarks(bookmarks);
    } catch (error) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'No bookmarks found in PDF');
      return [];
    }
  }

  /**
   * 鍏抽棴 PDF 鏂囨。
   */
  async closePdf(): Promise<void> {
    if (this.pdfDocument) {
      await this.pdfDocument.close();
      this.pdfDocument = null;
      this.currentFilePath = '';
      hilog.info(LOG_DOMAIN, LOG_TAG, 'PDF document closed');
    }
  }

  /**
   * 妫€鏌ユ槸鍚︿负 PDF 鏍煎紡
   */
  static isPdfFormat(format: string): boolean {
    return format.toLowerCase() === 'pdf';
  }

  /**
   * 杞崲涔︾鏍煎紡
   */
  private convertBookmarks(bookmarks: pdfService.Bookmark[]): PdfBookmark[] {
    return bookmarks.map(bm => ({
      title: bm.title,
      pageIndex: bm.pageIndex,
      level: bm.level,
      children: bm.children ? this.convertBookmarks(bm.children) : []
    }));
  }

  /**
   * 娓呯悊璧勬簮
   */
  async cleanup(): Promise<void> {
    await this.closePdf();
  }
}

// 瀵煎嚭鍗曚緥
export const pdfKitService = new PdfKitService();
