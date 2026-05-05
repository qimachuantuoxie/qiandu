/**
 * 书籍导入服务 - 使用 Reader Kit 解析真实元数据
 * 
 * 替代旧的 EbookParser，使用 HarmonyOS 官方 Reader Kit
 * 支持格式：txt, epub, mobi, azw, azw3, pdf
 */

import { readerKitService } from '../services/reader/ReaderKitService';
import { pdfKitService } from '../services/reader/PdfKitService';
import { ReaderRouterService, ReaderType } from '../services/reader/ReaderRouterService';
import { BookInfo, BookFormat, ReadStatus, generateBookId } from '../models/CoreBookModel';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';

const LOG_TAG = 'BookImportService';
const LOG_DOMAIN = 0x0010;

/**
 * 导入结果
 */
export interface ImportResult {
  success: boolean;
  book?: BookInfo;
  error?: string;
  skipped?: boolean;
}

/**
 * 书籍导入服务
 */
export class BookImportService {
  private context: common.UIAbilityContext | null = null;

  /**
   * 初始化服务
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await readerKitService.init(context);
    hilog.info(LOG_DOMAIN, LOG_TAG, 'BookImportService initialized');
  }

  /**
   * 导入单个书籍文件
   * @param filePath 文件路径（外部存储）
   * @param existingPaths 已存在的文件路径集合
   */
  async importBook(filePath: string, existingPaths: Set<string>): Promise<ImportResult> {
    try {
      // 检查是否已导入
      if (existingPaths.has(filePath)) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'File already exists, skip: %{public}s', filePath);
        return { success: true, skipped: true };
      }

      // 检查格式支持
      const format = this.detectFormat(filePath);
      const routeResult = ReaderRouterService.getReaderType(format);
      
      if (!routeResult.supported) {
        return {
          success: false,
          error: routeResult.message || `不支持的格式: ${format}`
        };
      }

      // 复制文件到沙箱
      const sandboxPath = await this.copyToSandbox(filePath);
      
      // 解析书籍元数据
      let bookInfo: BookInfo;
      
      if (routeResult.type === ReaderType.READER_KIT) {
        // 使用 Reader Kit 解析
        bookInfo = await this.parseWithReaderKit(sandboxPath, format);
      } else if (routeResult.type === ReaderType.PDF_KIT) {
        // 使用 PDF Kit 解析
        bookInfo = await this.parseWithPdfKit(sandboxPath, format);
      } else {
        return {
          success: false,
          error: '未知的阅读器类型'
        };
      }

      // 添加到书架
      bookInfo.filePath = sandboxPath; // 使用沙箱路径
      bookInfo.addTime = Date.now();
      bookInfo.status = ReadStatus.UNREAD;
      bookInfo.isFavorite = false;
      bookInfo.groupIds = [];
      bookInfo.totalReadTime = 0;
      bookInfo.currentPage = 0;
      bookInfo.readProgress = 0;
      bookInfo.lastReadTime = 0;

      hilog.info(LOG_DOMAIN, LOG_TAG, 'Book imported successfully: %{public}s', bookInfo.title);
      
      return {
        success: true,
        book: bookInfo
      };
    } catch (error) {
      const errorMsg = (error as Error).message;
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to import book: %{public}s, error: %{public}s', 
        filePath, errorMsg);
      
      return {
        success: false,
        error: errorMsg
      };
    }
  }

  /**
   * 使用 Reader Kit 解析书籍
   */
  private async parseWithReaderKit(filePath: string, format: string): Promise<BookInfo> {
    const bookMeta = await readerKitService.parseBook(filePath);
    
    // 保存封面图片
    let coverPath = '';
    if (bookMeta.coverImage) {
      coverPath = await this.saveCoverImage(bookMeta.coverImage, bookMeta.title);
    }

    return {
      id: generateBookId(),
      title: bookMeta.title || this.extractFileName(filePath),
      author: bookMeta.author || '未知作者',
      coverPath: coverPath,
      filePath: '', // 稍后设置
      format: this.stringToBookFormat(format),
      fileSize: await this.getFileSize(filePath),
      totalPages: 0, // Reader Kit 不直接提供总页数
      currentPage: 0,
      readProgress: 0,
      lastReadTime: 0,
      addTime: 0,
      status: ReadStatus.UNREAD,
      description: '',
      tags: [],
      isFavorite: false,
      groupIds: [],
      totalReadTime: 0
    };
  }

  /**
   * 使用 PDF Kit 解析 PDF
   */
  private async parseWithPdfKit(filePath: string, format: string): Promise<BookInfo> {
    const pdfInfo = await pdfKitService.openPdf(filePath);
    
    // 获取第一页作为封面（简化处理）
    let coverPath = '';
    try {
      const pixelMap = await pdfKitService.renderPage(0, 400, 600, 72);
      coverPath = await this.savePixelMapAsImage(pixelMap, this.extractFileName(filePath));
    } catch (error) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Failed to generate PDF cover');
    }

    await pdfKitService.closePdf();

    return {
      id: generateBookId(),
      title: this.extractFileName(filePath),
      author: '未知作者',
      coverPath: coverPath,
      filePath: '',
      format: BookFormat.PDF,
      fileSize: await this.getFileSize(filePath),
      totalPages: pdfInfo.pageCount,
      currentPage: 0,
      readProgress: 0,
      lastReadTime: 0,
      addTime: 0,
      status: ReadStatus.UNREAD,
      description: '',
      tags: [],
      isFavorite: false,
      groupIds: [],
      totalReadTime: 0
    };
  }

  /**
   * 复制文件到沙箱
   */
  private async copyToSandbox(externalPath: string): Promise<string> {
    if (!this.context) {
      throw new Error('Context not initialized');
    }

    const fileName = this.extractFileName(externalPath);
    const sandboxPath = `${this.context.filesDir}/books/${fileName}`;
    
    // 确保目录存在
    const dirPath = `${this.context.filesDir}/books`;
    try {
      await fileIo.mkdir(dirPath);
    } catch (error) {
      // 目录可能已存在
    }

    // 复制文件
    await fileIo.copy(externalPath, sandboxPath);
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'File copied to sandbox: %{public}s', sandboxPath);
    return sandboxPath;
  }

  /**
   * 保存封面图片
   */
  private async saveCoverImage(pixelMap: image.PixelMap, bookTitle: string): Promise<string> {
    if (!this.context) {
      return '';
    }

    try {
      const coverDir = `${this.context.cacheDir}/covers`;
      try {
        await fileIo.mkdir(coverDir);
      } catch (error) {
        // 目录可能已存在
      }

      const fileName = `cover_${bookTitle.replace(/[^\w]/g, '_')}.png`;
      const coverPath = `${coverDir}/${fileName}`;

      // 这里需要使用 image.PackingOption 保存 PixelMap
      // 简化处理，返回空字符串，使用动态封面
      return '';
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to save cover: %{public}s', (error as Error).message);
      return '';
    }
  }

  /**
   * 保存 PixelMap 为图片
   */
  private async savePixelMapAsImage(pixelMap: image.PixelMap, fileName: string): Promise<string> {
    // 简化实现，实际需要使用 image.Packer
    return '';
  }

  /**
   * 检测文件格式
   */
  private detectFormat(filePath: string): string {
    const lastDot = filePath.lastIndexOf('.');
    if (lastDot === -1) return '';
    return filePath.substring(lastDot + 1).toLowerCase();
  }

  /**
   * 字符串格式转 BookFormat 枚举
   */
  private stringToBookFormat(format: string): BookFormat {
    const upperFormat = format.toUpperCase();
    switch (upperFormat) {
      case 'PDF': return BookFormat.PDF;
      case 'EPUB': return BookFormat.EPUB;
      case 'MOBI': return BookFormat.MOBI;
      case 'TXT': return BookFormat.TXT;
      case 'AZW': return BookFormat.AZW;
      case 'AZW3': return BookFormat.AZW3;
      default: return BookFormat.TXT;
    }
  }

  /**
   * 从路径提取文件名
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    if (parts.length === 0) return '未知书籍';
    
    let fileName = parts[parts.length - 1];
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      fileName = fileName.substring(0, lastDot);
    }
    
    return fileName || '未知书籍';
  }

  /**
   * 获取文件大小
   */
  private async getFileSize(filePath: string): Promise<number> {
    try {
      const stat = await fileIo.stat(filePath);
      return stat.size;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 清理资源
   */
  cleanup(): void {
    readerKitService.cleanup();
    pdfKitService.cleanup();
  }
}

// 导出单例
export const bookImportService = new BookImportService();
