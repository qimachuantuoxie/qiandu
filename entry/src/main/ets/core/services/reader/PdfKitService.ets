/**
 * PDF Kit 服务 - 基于 HarmonyOS 官方 PDF 处理服务
 * 
 * 提供 PDF 文档浏览、渲染能力
 * 
 * @since API 16 (HarmonyOS 5.0.4+)
 */

import { pdfService } from '@kit.PDFKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const LOG_TAG = 'PdfKitService';
const LOG_DOMAIN = 0x0002;

/**
 * PDF 文档信息
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
 * PDF 页面信息
 */
export interface PdfPageInfo {
  width: number;
  height: number;
  rotation: number;
}

/**
 * PDF 书签
 */
export interface PdfBookmark {
  title: string;
  pageIndex: number;
  level: number;
  children?: PdfBookmark[];
}

/**
 * PDF Kit 服务类
 */
export class PdfKitService {
  private pdfDocument: pdfService.PdfDocument | null = null;
  private currentFilePath: string = '';

  /**
   * 打开 PDF 文档
   * @param filePath PDF 文件路径
   */
  async openPdf(filePath: string): Promise<PdfDocumentInfo> {
    try {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Opening PDF: %{public}s', filePath);
      
      // 打开 PDF 文档
      this.pdfDocument = await pdfService.openDocument(filePath);
      this.currentFilePath = filePath;
      
      // 获取文档信息
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
   * 获取页面数量
   */
  async getPageCount(): Promise<number> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    return await this.pdfDocument.getPageCount();
  }

  /**
   * 获取页面信息
   * @param pageIndex 页码（从0开始）
   */
  async getPageInfo(pageIndex: number): Promise<PdfPageInfo> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    return await this.pdfDocument.getPageInfo(pageIndex);
  }

  /**
   * 渲染页面为图片
   * @param pageIndex 页码
   * @param width 宽度
   * @param height 高度
   * @param dpi DPI（默认150）
   */
  async renderPage(pageIndex: number, width: number, height: number, dpi: number = 150): Promise<image.PixelMap> {
    if (!this.pdfDocument) {
      throw new Error('PDF document not opened');
    }
    
    // 创建渲染参数
    const renderParam: pdfService.RenderParam = {
      width: width,
      height: height,
      dpi: dpi
    };
    
    // 渲染页面
    const pixelMap = await this.pdfDocument.renderPage(pageIndex, renderParam);
    return pixelMap;
  }

  /**
   * 获取 PDF 书签
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
   * 关闭 PDF 文档
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
   * 检查是否为 PDF 格式
   */
  static isPdfFormat(format: string): boolean {
    return format.toLowerCase() === 'pdf';
  }

  /**
   * 转换书签格式
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
   * 清理资源
   */
  async cleanup(): Promise<void> {
    await this.closePdf();
  }
}

// 导出单例
export const pdfKitService = new PdfKitService();
