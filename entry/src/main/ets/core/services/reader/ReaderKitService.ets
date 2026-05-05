/**
 * Reader Kit 服务 - 基于 HarmonyOS 官方阅读服务
 * 
 * 提供电子书解析、排版、阅读交互能力
 * 支持格式: txt, epub, mobi, azw, azw3
 * 
 * @since API 16 (HarmonyOS 5.0.4+)
 */

import { bookParser, readerCore } from '@kit.ReaderKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'ReaderKitService';
const LOG_DOMAIN = 0x0001;

/**
 * 书籍信息接口
 */
export interface BookInfo {
  title: string;
  author?: string;
  coverImage?: image.PixelMap;
  coverPath?: string;
  charset?: string;
  bookType: string;
  isRtl?: boolean;
  language?: string;
  publishDate?: string;
}

/**
 * 目录项接口
 */
export interface CatalogItem {
  title: string;
  href?: string;
  idRef?: string;
  level?: number;
  playOrder?: number;
  resourceFile?: string;
  children?: CatalogItem[];
}

/**
 * 书脊项（内容节点）
 */
export interface SpineItem {
  idRef: string;
  href: string;
  linear: string;
  properties: string;
}

/**
 * 阅读设置
 */
export interface ReaderSetting {
  fontSize?: number;
  fontFamily?: string;
  lineHeight?: number;
  letterSpacing?: number;
  paragraphSpacing?: number;
  textColor?: string;
  backgroundColor?: string;
  pageMargin?: number;
  brightness?: number;
}

/**
 * 阅读进度
 */
export interface ReadProgress {
  spineIndex: number;
  domPos: string;
  percentage: number;
}

/**
 * Reader Kit 服务类
 */
export class ReaderKitService {
  private context: common.UIAbilityContext | null = null;
  private bookParserHandler: bookParser.BookParserHandler | null = null;
  private readerController: readerCore.ReaderComponentController | null = null;
  private currentBookPath: string = '';

  /**
   * 初始化服务
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'ReaderKitService initialized');
  }

  /**
   * 解析书籍文件，获取书籍信息
   * @param filePath 书籍文件路径（应用沙箱内）
   */
  async parseBook(filePath: string): Promise<BookInfo> {
    try {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Parsing book: %{public}s', filePath);
      
      // 获取书籍解析器
      this.bookParserHandler = await bookParser.getDefaultHandler(filePath);
      this.currentBookPath = filePath;
      
      // 获取书籍基本信息
      const info = this.bookParserHandler.getBookInfo();
      
      // 提取封面图片
      let coverImage: image.PixelMap | undefined;
      if (info.bookCoverImage) {
        try {
          const buffer = this.bookParserHandler.getResourceContent(-1, info.bookCoverImage);
          const imageSource = image.createImageSource(buffer);
          coverImage = await imageSource.createPixelMap();
          imageSource.release();
        } catch (error) {
          hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load cover image: %{public}s', 
            (error as BusinessError).message);
        }
      }
      
      const bookInfo: BookInfo = {
        title: info.bookTitle,
        author: info.bookCreator,
        coverImage: coverImage,
        charset: info.bookCharset,
        bookType: info.bookType || 'unknown',
        isRtl: info.isRtl,
        language: info.bookLanguage,
        publishDate: info.bookPublishDate
      };
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Book parsed successfully: %{public}s', bookInfo.title);
      return bookInfo;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to parse book: %{public}s', 
        (error as BusinessError).message);
      throw error;
    }
  }

  /**
   * 获取书籍目录列表
   */
  getCatalogList(): CatalogItem[] {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    const catalogItems = this.bookParserHandler.getCatalogList();
    return this.convertCatalogItems(catalogItems);
  }

  /**
   * 获取书脊列表（阅读顺序）
   */
  getSpineList(): SpineItem[] {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return this.bookParserHandler.getSpineList();
  }

  /**
   * 获取指定章节的内容
   * @param spineIndex 章节索引
   */
  async getChapterContent(spineIndex: number): Promise<string> {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return await this.bookParserHandler.getSpineItemContent(spineIndex);
  }

  /**
   * 获取资源文件内容（如图片、样式等）
   * @param spineIndex 章节索引
   * @param filePath 资源文件路径
   */
  getResourceContent(spineIndex: number, filePath: string): ArrayBuffer {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return this.bookParserHandler.getResourceContent(spineIndex, filePath);
  }

  /**
   * 初始化阅读器控制器
   * @param controller 阅读器控制器实例
   */
  async initReaderController(controller: readerCore.ReaderComponentController): Promise<void> {
    this.readerController = controller;
    
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    // 注册书籍解析器
    this.readerController.registerBookParser(this.bookParserHandler);
    
    // 初始化控制器
    if (this.context) {
      await this.readerController.init(this.context);
    }
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Reader controller initialized');
  }

  /**
   * 开始阅读（从指定位置）
   * @param spineIndex 章节索引
   * @param domPos DOM位置（可选）
   */
  async startReading(spineIndex: number, domPos?: string): Promise<void> {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    await this.readerController.startPlay(spineIndex, domPos || '');
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Start reading at spine %{public}d', spineIndex);
  }

  /**
   * 翻页
   * @param isNext true=下一页，false=上一页
   */
  flipPage(isNext: boolean): void {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    this.readerController.flipPage(isNext);
  }

  /**
   * 设置阅读配置
   * @param setting 阅读设置
   */
  setPageConfig(setting: ReaderSetting): void {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    const readerSetting: readerCore.ReaderSetting = {
      fontSize: setting.fontSize || 18,
      fontFamily: setting.fontFamily || 'system',
      lineHeight: setting.lineHeight || 1.5,
      letterSpacing: setting.letterSpacing || 0,
      paragraphSpacing: setting.paragraphSpacing || 12,
      textColor: setting.textColor || '#000000',
      backgroundColor: setting.backgroundColor || '#FFFFFF',
      pageMargin: setting.pageMargin || 20,
      brightness: setting.brightness || 100
    };
    
    this.readerController.setPageConfig(readerSetting);
  }

  /**
   * 跳转到指定进度
   * @param progress 阅读进度
   */
  async jumpToProgress(progress: ReadProgress): Promise<void> {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    await this.readerController.startPlay(progress.spineIndex, progress.domPos);
  }

  /**
   * 释放书籍资源
   */
  releaseBook(): void {
    if (this.readerController) {
      this.readerController.releaseBook();
      this.readerController = null;
    }
    
    this.bookParserHandler = null;
    this.currentBookPath = '';
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Book resources released');
  }

  /**
   * 检查文件格式是否支持
   * @param format 文件格式
   */
  static isSupportedFormat(format: string): boolean {
    const supportedFormats = ['txt', 'epub', 'mobi', 'azw', 'azw3'];
    return supportedFormats.includes(format.toLowerCase());
  }

  /**
   * 转换目录项格式
   */
  private convertCatalogItems(items: bookParser.CatalogItem[]): CatalogItem[] {
    return items.map(item => ({
      title: item.title || '',
      href: item.href,
      idRef: item.idRef,
      level: item.catalogLevel,
      playOrder: item.playOrder,
      resourceFile: item.resourceFile,
      children: item.children ? this.convertCatalogItems(item.children) : []
    }));
  }

  /**
   * 清理资源
   */
  cleanup(): void {
    this.releaseBook();
    this.context = null;
  }
}

// 导出单例
export const readerKitService = new ReaderKitService();
