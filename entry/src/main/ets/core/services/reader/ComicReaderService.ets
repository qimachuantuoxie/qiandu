import { logger } from '../../../utils/Logger';
/**
 * Comic Reader Service - 婕�敾闃呰�鏈嶅姟
 * Comic Reader Service - Comic Reading with ImageKit
 *
 * 浣跨敤Image Kit瀹炵幇婕�敾闃呰�鍔熻兘
 * 鏀�寔CBZ/CBR鏍煎紡銆佸浘鐗囬�鍔犺浇銆佺紦瀛樸€佺缉鏀?
 *
 * @since 6.0.0
 */

import { imageKitService as imageKit, ImageQuality, ImageProcessResult } from '../huawei-kit/ImageKitService';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

/**
 * Native妯″潡鎺ュ彛锛堢敤浜嶤BZ瑙ｅ帇锛?
 */
interface NativeModules {
  extractZip?: (filePath: string) => Promise<ZipEntry[]>;
}

/**
 * 鍘嬬缉鍖呮潯鐩�俊鎭?
 */
interface ZipEntry {
  /** 鏂囦欢璺�緞 */
  path: string;
  /** 鏂囦欢URI */
  uri: string;
}

// 澹版槑native妯″潡锛堝�鏋滃瓨鍦�級
declare const nativeModules: NativeModules | undefined;

/**
 * 婕�敾椤甸潰淇℃伅
 */
export interface ComicPage {
  /** 椤甸潰绱㈠紩 */
  index: number;
  /** 鍥剧墖URI */
  imageUri: string;
  /** 鍥剧墖瀹藉害 */
  width: number;
  /** 鍥剧墖楂樺害 */
  height: number;
  /** 鏄�惁宸插姞杞?*/
  isLoaded: boolean;
  /** 鍔犺浇杩涘害 */
  loadProgress: number;
}

/**
 * 婕�敾淇℃伅
 */
export interface ComicInfo {
  /** 婕�敾鏍囬� */
  title: string;
  /** 浣滆€?*/
  author: string;
  /** 灏侀潰URI */
  coverUri: string;
  /** 鎬婚〉鏁?*/
  totalPages: number;
  /** 鏍煎紡 */
  format: 'cbz' | 'cbr';
  /** 鏂囦欢澶у皬 */
  fileSize: number;
}

/**
 * 闃呰�妯″紡
 */
export enum ComicReadMode {
  /** 鍗曢〉妯″紡 */
  SINGLE_PAGE = 'single',
  /** 鍙岄〉妯″紡 */
  DOUBLE_PAGE = 'double',
  /** 闀挎潯妯″紡 */
  WEBTOON = 'webtoon',
  /** 浠庡彸鍒板乏锛堟棩婕�級 */
  RTL = 'rtl'
}

/**
 * 鍥剧墖缂╂斁妯″紡
 */
export enum ComicScaleMode {
  /** 閫傚簲瀹藉害 */
  FIT_WIDTH = 'fit_width',
  /** 閫傚簲楂樺害 */
  FIT_HEIGHT = 'fit_height',
  /** 閫傚簲灞忓箷 */
  FIT_SCREEN = 'fit_screen',
  /** 鍘熷�澶у皬 */
  ORIGINAL = 'original',
  /** 鑷�敱缂╂斁 */
  FREE = 'free'
}

/**
 * 婕�敾闃呰�閰嶇疆
 */
export interface ComicConfig {
  /** 闃呰�妯″紡 */
  readMode: ComicReadMode;
  /** 缂╂斁妯″紡 */
  scaleMode: ComicScaleMode;
  /** 鏄�惁鏄剧ず椤电爜 */
  showPageNumber: boolean;
  /** 鏄�惁棰勫姞杞?*/
  enablePreload: boolean;
  /** 棰勫姞杞介〉鏁?*/
  preloadCount: number;
  /** 鍥剧墖璐ㄩ噺 */
  imageQuality: number;
  /** 鑳屾櫙棰滆壊 */
  backgroundColor: string;
  /** 缈婚〉鍔ㄧ敾 */
  enableAnimation: boolean;
}

/**
 * 婕�敾闃呰�鏈嶅姟绫?
 */
class ComicReaderService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: ComicReaderService;

  /** 褰撳墠婕�敾 */
  private currentComic: ComicInfo | null = null;

  /** 婕�敾椤甸潰鍒楄〃 */
  private pages: ComicPage[] = [];

  /** 褰撳墠椤电爜 */
  private currentPageIndex: number = 0;

  /** 闃呰�閰嶇疆 */
  private config: ComicConfig = {
    readMode: ComicReadMode.SINGLE_PAGE,
    scaleMode: ComicScaleMode.FIT_WIDTH,
    showPageNumber: true,
    enablePreload: true,
    preloadCount: 3,
    imageQuality: ImageQuality.HIGH,
    backgroundColor: '#000000',
    enableAnimation: true
  };

  /** 鍥剧墖缂撳瓨 */
  private imageCache: Map<number, string> = new Map();

  /** 鍔犺浇鐩戝惉鍣?*/
  private loadListeners: Array<(progress: number) => void> = [];

  /** 椤甸潰鍙樺寲鐩戝惉鍣?*/
  private pageChangeListeners: Array<(index: number) => void> = [];

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): ComicReaderService {
    if (!ComicReaderService.instance) {
      ComicReaderService.instance = new ComicReaderService();
    }
    return ComicReaderService.instance;
  }

  // ==================== 婕�敾鍔犺浇 ====================

  /**
   * 鍔犺浇婕�敾
   */
  async loadComic(filePath: string): Promise<ComicInfo | null> {
    try {
      logger.info('[ComicReader] Loading comic:', filePath);

      const format = filePath.endsWith('.cbz') ? 'cbz' : 'cbr';

      // 瑙ｆ瀽鍘嬬缉鍖?
      const imageUris = await this.extractComicImages(filePath);

      if (imageUris.length === 0) {
        logger.error('[ComicReader] No images found in comic');
        return null;
      }

      // 鏋勫缓椤甸潰鍒楄〃
      const newPages: ComicPage[] = [];
      for (let i = 0; i < imageUris.length; i++) {
        const page: ComicPage = {
          index: i,
          imageUri: imageUris[i],
          width: 0,
          height: 0,
          isLoaded: false,
          loadProgress: 0
        };
        newPages.push(page);
      }
      this.pages = newPages;

      // 鑾峰彇婕�敾淇℃伅
      const fileName = this.extractFileName(filePath);
      this.currentComic = {
        title: fileName,
        author: '鏈�煡浣滆€?,
        coverUri: imageUris[0],
        totalPages: imageUris.length,
        format,
        fileSize: fileIo.statSync(filePath).size
      };

      // 閲嶇疆椤电爜
      this.currentPageIndex = 0;

      // 棰勫姞杞藉浘鐗?
      if (this.config.enablePreload) {
        await this.preloadImages();
      }

      logger.info('[ComicReader] Comic loaded:', this.currentComic.totalPages, 'pages');
      return this.currentComic;
    } catch (error) {
      const err = error as Error;
      logger.error('[ComicReader] Load comic failed:', err.message);
      return null;
    }
  }

  /**
   * 瑙ｅ帇婕�敾鍥剧墖
   */
  private async extractComicImages(filePath: string): Promise<string[]> {
    try {
      const format = filePath.endsWith('.cbz') ? 'cbz' : 'cbr';

      if (format === 'cbz') {
        // CBZ 鏄?ZIP 鏍煎紡锛屼娇鐢?HarmonyOS 鍘熺敓鑳藉姏瑙ｅ帇
        return await this.extractCBZImages(filePath);
      } else {
        // CBR 鏄?RAR 鏍煎紡锛屾殏涓嶆敮鎸?
        logger.warn('[ComicReader] CBR format not supported yet');
        return [];
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[ComicReader] Extract comic images failed:', err.message);
      return [];
    }
  }

  /**
   * 瑙ｅ帇 CBZ (ZIP) 鍥剧墖
   */
  private async extractCBZImages(filePath: string): Promise<string[]> {
    try {
      // 浣跨敤 HarmonyOS 鐨勫帇缂╄兘鍔?
      // 鐢变簬 ArkTS 娌℃湁鐩存帴鐨?ZIP 瑙ｅ帇 API锛屾垜浠�娇鐢?native 妯″潡
      const imageUris: string[] = [];

      // 璇诲彇鏂囦欢
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      // 浣跨敤 native 妯″潡瑙ｅ帇锛堝�鏋滄湁鐨勮瘽锛?
      // 鍚﹀垯浣跨敤鍩烘湰鏂规硶
      try {
        // 灏濊瘯浣跨敤 native 妯″潡
        if (nativeModules && nativeModules.extractZip) {
          const entries = await nativeModules.extractZip(filePath);
          for (const entry of entries) {
            if (this.isImageFile(entry.path)) {
              imageUris.push(entry.uri);
            }
          }
        } else {
          // 闄嶇骇鏂规�锛氳繑鍥炴枃浠惰矾寰勶紝璁?ImageKit 澶勭悊
          imageUris.push(filePath);
        }
      } catch (e) {
        logger.warn('[ComicReader] Native extract failed, using fallback');
        // 闄嶇骇鏂规�
        imageUris.push(filePath);
      }

      logger.info('[ComicReader] Extracted', imageUris.length, 'images from CBZ');
      return imageUris;
    } catch (error) {
      const err = error as Error;
      logger.error('[ComicReader] CBZ extract failed:', err.message);
      return [];
    }
  }

  /**
   * 鍒ゆ柇鏄�惁鏄�浘鐗囨枃浠?
   */
  private isImageFile(path: string): boolean {
    const ext = path.toLowerCase().split('.').pop();
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    const checkExt = ext || '';
    for (let i = 0; i < imageExts.length; i++) {
      if (imageExts[i] === checkExt) {
        return true;
      }
    }
    return false;
  }

  // ==================== 鍥剧墖棰勫姞杞?====================

  /**
   * 棰勫姞杞藉浘鐗?
   */
  async preloadImages(): Promise<void> {
    if (!this.config.enablePreload) return;

    const start = Math.max(0, this.currentPageIndex - this.config.preloadCount);
    const end = Math.min(this.pages.length, this.currentPageIndex + this.config.preloadCount + 1);

    for (let i = start; i < end; i++) {
      if (!this.pages[i].isLoaded) {
        await this.loadImage(i);
      }
    }
  }

  /**
   * 鍔犺浇鍗曞紶鍥剧墖
   */
  async loadImage(index: number): Promise<boolean> {
    try {
      if (index < 0 || index >= this.pages.length) {
        return false;
      }

      const page = this.pages[index];

      // 妫€鏌ョ紦瀛?
      if (this.imageCache.has(index)) {
        const cachedUri = this.imageCache.get(index);
        if (cachedUri !== undefined) {
          page.imageUri = cachedUri;
        }
        page.isLoaded = true;
        page.loadProgress = 100;
        return true;
      }

      // 浣跨敤 ImageKit 鍔犺浇鍜屼紭鍖栧浘鐗?
      try {
        if (imageKit && imageKit.processImage) {
          const result: ImageProcessResult = await imageKit.processImage(page.imageUri, {
            quality: this.config.imageQuality
          });
          if (result && result.outputUri) {
            page.imageUri = result.outputUri;
            // 娉ㄦ剰: ImageKit 鐨?ImageProcessResult 涓嶅寘鍚?width/height
            // 濡傛灉闇€瑕侊紝鍙�互閫氳繃鍏朵粬鏂瑰紡鑾峰彇
          }
        }
      } catch (e) {
        logger.warn('[ComicReader] ImageKit load failed, using original image');
      }

      page.isLoaded = true;
      page.loadProgress = 100;

      // 鍔犲叆缂撳瓨
      this.imageCache.set(index, page.imageUri);

      this.notifyPageChange(index);
      return true;
    } catch (error) {
      const err = error as Error;
      logger.error('[ComicReader] Load image failed:', index, err.message);
      return false;
    }
  }

  // ==================== 椤甸潰瀵艰埅 ====================

  /**
   * 璺宠浆鍒版寚瀹氶〉
   */
  async goToPage(index: number): Promise<boolean> {
    if (index < 0 || index >= this.pages.length) {
      return false;
    }

    this.currentPageIndex = index;

    // 鍔犺浇褰撳墠椤?
    await this.loadImage(index);

    // 棰勫姞杞?
    if (this.config.enablePreload) {
      await this.preloadImages();
    }

    this.notifyPageChange(index);
    return true;
  }

  /**
   * 涓嬩竴椤?
   */
  async nextPage(): Promise<boolean> {
    return await this.goToPage(this.currentPageIndex + 1);
  }

  /**
   * 涓婁竴椤?
   */
  async previousPage(): Promise<boolean> {
    return await this.goToPage(this.currentPageIndex - 1);
  }

  /**
   * 鑾峰彇褰撳墠椤?
   */
  getCurrentPage(): ComicPage | null {
    if (this.currentPageIndex < 0 || this.currentPageIndex >= this.pages.length) {
      return null;
    }
    return this.pages[this.currentPageIndex];
  }

  /**
   * 鑾峰彇褰撳墠椤电爜
   */
  getCurrentPageIndex(): number {
    return this.currentPageIndex;
  }

  /**
   * 鑾峰彇鎬婚〉鏁?
   */
  getTotalPages(): number {
    return this.pages.length;
  }

  // ==================== 鍙岄〉妯″紡 ====================

  /**
   * 鑾峰彇鍙岄〉妯″紡鐨勯〉闈?
   */
  getDoublePages(): [ComicPage | null, ComicPage | null] {
    const left = this.currentPageIndex;
    const right = this.currentPageIndex + 1;

    const leftPage = left < this.pages.length ? this.pages[left] : null;
    const rightPage = right < this.pages.length ? this.pages[right] : null;

    return [leftPage, rightPage];
  }

  // ==================== 閰嶇疆绠＄悊 ====================

  /**
   * 鏇存柊闃呰�閰嶇疆
   */
  async updateConfig(config: Partial<ComicConfig>): Promise<void> {
    if (config.readMode !== undefined) this.config.readMode = config.readMode;
    if (config.scaleMode !== undefined) this.config.scaleMode = config.scaleMode;
    if (config.showPageNumber !== undefined) this.config.showPageNumber = config.showPageNumber;
    if (config.enablePreload !== undefined) this.config.enablePreload = config.enablePreload;
    if (config.preloadCount !== undefined) this.config.preloadCount = config.preloadCount;
    if (config.imageQuality !== undefined) this.config.imageQuality = config.imageQuality;
    if (config.backgroundColor !== undefined) this.config.backgroundColor = config.backgroundColor;
    if (config.enableAnimation !== undefined) this.config.enableAnimation = config.enableAnimation;

    logger.info('[ComicReader] Config updated');
  }

  /**
   * 鑾峰彇闃呰�閰嶇疆
   */
  getConfig(): ComicConfig {
    const cfg: ComicConfig = {
      readMode: this.config.readMode,
      scaleMode: this.config.scaleMode,
      showPageNumber: this.config.showPageNumber,
      enablePreload: this.config.enablePreload,
      preloadCount: this.config.preloadCount,
      imageQuality: this.config.imageQuality,
      backgroundColor: this.config.backgroundColor,
      enableAnimation: this.config.enableAnimation
    };
    return cfg;
  }

  // ==================== 鐩戝惉鍣ㄧ�鐞?====================

  /**
   * 娣诲姞鍔犺浇鐩戝惉鍣?
   */
  addLoadListener(listener: (progress: number) => void): void {
    const newListeners = this.loadListeners.slice();
    newListeners.push(listener);
    this.loadListeners = newListeners;
  }

  /**
   * 娣诲姞椤甸潰鍙樺寲鐩戝惉鍣?
   */
  addPageChangeListener(listener: (index: number) => void): void {
    const newListeners = this.pageChangeListeners.slice();
    newListeners.push(listener);
    this.pageChangeListeners = newListeners;
  }

  /**
   * 閫氱煡椤甸潰鍙樺寲
   */
  private notifyPageChange(index: number): void {
    for (const listener of this.pageChangeListeners) {
      listener(index);
    }
  }

  // ==================== 杈呭姪鏂规硶 ====================

  /**
   * 鎻愬彇鏂囦欢鍚?
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const fileName = parts[parts.length - 1];
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /**
   * 鑾峰彇闃呰�杩涘害
   */
  getProgress(): number {
    if (this.pages.length === 0) return 0;
    return ((this.currentPageIndex + 1) / this.pages.length) * 100;
  }

  /**
   * 閲婃斁璧勬簮
   */
  async release(): Promise<void> {
    logger.info('[ComicReader] Releasing...');
    this.imageCache.clear();
    this.pages = [];
    this.currentPageIndex = 0;
    this.currentComic = null;
    this.loadListeners = [];
    this.pageChangeListeners = [];
    logger.info('[ComicReader] Released');
  }
}

// 瀵煎嚭鍗曚緥
export const comicReaderService = ComicReaderService.getInstance();
export const comicReader = comicReaderService;
export default comicReaderService;
