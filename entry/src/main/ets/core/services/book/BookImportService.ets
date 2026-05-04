/**
 * 涔︾睄瀵煎叆鏈嶅姟 - 浣跨敤 Reader Kit 瑙ｆ瀽鐪熷疄鍏冩暟鎹? * 
 * 鏇夸唬鏃х殑 EbookParser锛屼娇鐢?HarmonyOS 瀹樻柟 Reader Kit
 * 鏀寔鏍煎紡锛歵xt, epub, mobi, azw, azw3, pdf
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
 * 瀵煎叆缁撴灉
 */
export interface ImportResult {
  success: boolean;
  book?: BookInfo;
  error?: string;
  skipped?: boolean;
}

/**
 * 涔︾睄瀵煎叆鏈嶅姟
 */
export class BookImportService {
  private context: common.UIAbilityContext | null = null;

  /**
   * 鍒濆鍖栨湇鍔?   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await readerKitService.init(context);
    hilog.info(LOG_DOMAIN, LOG_TAG, 'BookImportService initialized');
  }

  /**
   * 瀵煎叆鍗曚釜涔︾睄鏂囦欢
   * @param filePath 鏂囦欢璺緞锛堝閮ㄥ瓨鍌級
   * @param existingPaths 宸插瓨鍦ㄧ殑鏂囦欢璺緞闆嗗悎
   */
  async importBook(filePath: string, existingPaths: Set<string>): Promise<ImportResult> {
    try {
      // 妫€鏌ユ槸鍚﹀凡瀵煎叆
      if (existingPaths.has(filePath)) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'File already exists, skip: %{public}s', filePath);
        return { success: true, skipped: true };
      }

      // 妫€鏌ユ牸寮忔敮鎸?      const format = this.detectFormat(filePath);
      const routeResult = ReaderRouterService.getReaderType(format);
      
      if (!routeResult.supported) {
        return {
          success: false,
          error: routeResult.message || `涓嶆敮鎸佺殑鏍煎紡: ${format}`
        };
      }

      // 澶嶅埗鏂囦欢鍒版矙绠?      const sandboxPath = await this.copyToSandbox(filePath);
      
      // 瑙ｆ瀽涔︾睄鍏冩暟鎹?      let bookInfo: BookInfo;
      
      if (routeResult.type === ReaderType.READER_KIT) {
        // 浣跨敤 Reader Kit 瑙ｆ瀽
        bookInfo = await this.parseWithReaderKit(sandboxPath, format);
      } else if (routeResult.type === ReaderType.PDF_KIT) {
        // 浣跨敤 PDF Kit 瑙ｆ瀽
        bookInfo = await this.parseWithPdfKit(sandboxPath, format);
      } else {
        return {
          success: false,
          error: '鏈煡鐨勯槄璇诲櫒绫诲瀷'
        };
      }

      // 娣诲姞鍒颁功鏋?      bookInfo.filePath = sandboxPath; // 浣跨敤娌欑璺緞
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
   * 浣跨敤 Reader Kit 瑙ｆ瀽涔︾睄
   */
  private async parseWithReaderKit(filePath: string, format: string): Promise<BookInfo> {
    const bookMeta = await readerKitService.parseBook(filePath);
    
    // 淇濆瓨灏侀潰鍥剧墖
    let coverPath = '';
    if (bookMeta.coverImage) {
      coverPath = await this.saveCoverImage(bookMeta.coverImage, bookMeta.title);
    }

    return {
      id: generateBookId(),
      title: bookMeta.title || this.extractFileName(filePath),
      author: bookMeta.author || '鏈煡浣滆€?,
      coverPath: coverPath,
      filePath: '', // 绋嶅悗璁剧疆
      format: this.stringToBookFormat(format),
      fileSize: await this.getFileSize(filePath),
      totalPages: 0, // Reader Kit 涓嶇洿鎺ユ彁渚涙€婚〉鏁?      currentPage: 0,
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
   * 浣跨敤 PDF Kit 瑙ｆ瀽 PDF
   */
  private async parseWithPdfKit(filePath: string, format: string): Promise<BookInfo> {
    const pdfInfo = await pdfKitService.openPdf(filePath);
    
    // 鑾峰彇绗竴椤典綔涓哄皝闈紙绠€鍖栧鐞嗭級
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
      author: '鏈煡浣滆€?,
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
   * 澶嶅埗鏂囦欢鍒版矙绠?   */
  private async copyToSandbox(externalPath: string): Promise<string> {
    if (!this.context) {
      throw new Error('Context not initialized');
    }

    const fileName = this.extractFileName(externalPath);
    const sandboxPath = `${this.context.filesDir}/books/${fileName}`;
    
    // 纭繚鐩綍瀛樺湪
    const dirPath = `${this.context.filesDir}/books`;
    try {
      await fileIo.mkdir(dirPath);
    } catch (error) {
      // 鐩綍鍙兘宸插瓨鍦?    }

    // 澶嶅埗鏂囦欢
    await fileIo.copy(externalPath, sandboxPath);
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'File copied to sandbox: %{public}s', sandboxPath);
    return sandboxPath;
  }

  /**
   * 淇濆瓨灏侀潰鍥剧墖
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
        // 鐩綍鍙兘宸插瓨鍦?      }

      const fileName = `cover_${bookTitle.replace(/[^\w]/g, '_')}.png`;
      const coverPath = `${coverDir}/${fileName}`;

      // 杩欓噷闇€瑕佷娇鐢?image.PackingOption 淇濆瓨 PixelMap
      // 绠€鍖栧鐞嗭紝杩斿洖绌哄瓧绗︿覆锛屼娇鐢ㄥ姩鎬佸皝闈?      return '';
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to save cover: %{public}s', (error as Error).message);
      return '';
    }
  }

  /**
   * 淇濆瓨 PixelMap 涓哄浘鐗?   */
  private async savePixelMapAsImage(pixelMap: image.PixelMap, fileName: string): Promise<string> {
    // 绠€鍖栧疄鐜帮紝瀹為檯闇€瑕佷娇鐢?image.Packer
    return '';
  }

  /**
   * 妫€娴嬫枃浠舵牸寮?   */
  private detectFormat(filePath: string): string {
    const lastDot = filePath.lastIndexOf('.');
    if (lastDot === -1) return '';
    return filePath.substring(lastDot + 1).toLowerCase();
  }

  /**
   * 瀛楃涓叉牸寮忚浆 BookFormat 鏋氫妇
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
   * 浠庤矾寰勬彁鍙栨枃浠跺悕
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    if (parts.length === 0) return '鏈煡涔︾睄';
    
    let fileName = parts[parts.length - 1];
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      fileName = fileName.substring(0, lastDot);
    }
    
    return fileName || '鏈煡涔︾睄';
  }

  /**
   * 鑾峰彇鏂囦欢澶у皬
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
   * 娓呯悊璧勬簮
   */
  cleanup(): void {
    readerKitService.cleanup();
    pdfKitService.cleanup();
  }
}

// 瀵煎嚭鍗曚緥
export const bookImportService = new BookImportService();
