/**
 * Reader Kit 鏈嶅姟 - 鍩轰簬 HarmonyOS 瀹樻柟闃呰鏈嶅姟
 * 
 * 鎻愪緵鐢靛瓙涔﹁В鏋愩€佹帓鐗堛€侀槄璇讳氦浜掕兘鍔? * 鏀寔鏍煎紡: txt, epub, mobi, azw, azw3
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
 * 涔︾睄淇℃伅鎺ュ彛
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
 * 鐩綍椤规帴鍙? */
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
 * 涔﹁剨椤癸紙鍐呭鑺傜偣锛? */
export interface SpineItem {
  idRef: string;
  href: string;
  linear: string;
  properties: string;
}

/**
 * 闃呰璁剧疆
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
 * 闃呰杩涘害
 */
export interface ReadProgress {
  spineIndex: number;
  domPos: string;
  percentage: number;
}

/**
 * Reader Kit 鏈嶅姟绫? */
export class ReaderKitService {
  private context: common.UIAbilityContext | null = null;
  private bookParserHandler: bookParser.BookParserHandler | null = null;
  private readerController: readerCore.ReaderComponentController | null = null;
  private currentBookPath: string = '';

  /**
   * 鍒濆鍖栨湇鍔?   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'ReaderKitService initialized');
  }

  /**
   * 瑙ｆ瀽涔︾睄鏂囦欢锛岃幏鍙栦功绫嶄俊鎭?   * @param filePath 涔︾睄鏂囦欢璺緞锛堝簲鐢ㄦ矙绠卞唴锛?   */
  async parseBook(filePath: string): Promise<BookInfo> {
    try {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Parsing book: %{public}s', filePath);
      
      // 鑾峰彇涔︾睄瑙ｆ瀽鍣?      this.bookParserHandler = await bookParser.getDefaultHandler(filePath);
      this.currentBookPath = filePath;
      
      // 鑾峰彇涔︾睄鍩烘湰淇℃伅
      const info = this.bookParserHandler.getBookInfo();
      
      // 鎻愬彇灏侀潰鍥剧墖
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
   * 鑾峰彇涔︾睄鐩綍鍒楄〃
   */
  getCatalogList(): CatalogItem[] {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    const catalogItems = this.bookParserHandler.getCatalogList();
    return this.convertCatalogItems(catalogItems);
  }

  /**
   * 鑾峰彇涔﹁剨鍒楄〃锛堥槄璇婚『搴忥級
   */
  getSpineList(): SpineItem[] {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return this.bookParserHandler.getSpineList();
  }

  /**
   * 鑾峰彇鎸囧畾绔犺妭鐨勫唴瀹?   * @param spineIndex 绔犺妭绱㈠紩
   */
  async getChapterContent(spineIndex: number): Promise<string> {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return await this.bookParserHandler.getSpineItemContent(spineIndex);
  }

  /**
   * 鑾峰彇璧勬簮鏂囦欢鍐呭锛堝鍥剧墖銆佹牱寮忕瓑锛?   * @param spineIndex 绔犺妭绱㈠紩
   * @param filePath 璧勬簮鏂囦欢璺緞
   */
  getResourceContent(spineIndex: number, filePath: string): ArrayBuffer {
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    return this.bookParserHandler.getResourceContent(spineIndex, filePath);
  }

  /**
   * 鍒濆鍖栭槄璇诲櫒鎺у埗鍣?   * @param controller 闃呰鍣ㄦ帶鍒跺櫒瀹炰緥
   */
  async initReaderController(controller: readerCore.ReaderComponentController): Promise<void> {
    this.readerController = controller;
    
    if (!this.bookParserHandler) {
      throw new Error('Book parser not initialized');
    }
    
    // 娉ㄥ唽涔︾睄瑙ｆ瀽鍣?    this.readerController.registerBookParser(this.bookParserHandler);
    
    // 鍒濆鍖栨帶鍒跺櫒
    if (this.context) {
      await this.readerController.init(this.context);
    }
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Reader controller initialized');
  }

  /**
   * 寮€濮嬮槄璇伙紙浠庢寚瀹氫綅缃級
   * @param spineIndex 绔犺妭绱㈠紩
   * @param domPos DOM浣嶇疆锛堝彲閫夛級
   */
  async startReading(spineIndex: number, domPos?: string): Promise<void> {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    await this.readerController.startPlay(spineIndex, domPos || '');
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Start reading at spine %{public}d', spineIndex);
  }

  /**
   * 缈婚〉
   * @param isNext true=涓嬩竴椤碉紝false=涓婁竴椤?   */
  flipPage(isNext: boolean): void {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    this.readerController.flipPage(isNext);
  }

  /**
   * 璁剧疆闃呰閰嶇疆
   * @param setting 闃呰璁剧疆
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
   * 璺宠浆鍒版寚瀹氳繘搴?   * @param progress 闃呰杩涘害
   */
  async jumpToProgress(progress: ReadProgress): Promise<void> {
    if (!this.readerController) {
      throw new Error('Reader controller not initialized');
    }
    
    await this.readerController.startPlay(progress.spineIndex, progress.domPos);
  }

  /**
   * 閲婃斁涔︾睄璧勬簮
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
   * 妫€鏌ユ枃浠舵牸寮忔槸鍚︽敮鎸?   * @param format 鏂囦欢鏍煎紡
   */
  static isSupportedFormat(format: string): boolean {
    const supportedFormats = ['txt', 'epub', 'mobi', 'azw', 'azw3'];
    return supportedFormats.includes(format.toLowerCase());
  }

  /**
   * 杞崲鐩綍椤规牸寮?   */
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
   * 娓呯悊璧勬簮
   */
  cleanup(): void {
    this.releaseBook();
    this.context = null;
  }
}

// 瀵煎嚭鍗曚緥
export const readerKitService = new ReaderKitService();
