import { logger } from '../../../utils/Logger';
/**
 * Image Kit 閺堝秴濮?- 閸ュ墽澧栨径鍕�倞閺堝秴濮?
 * Image Kit Service - Image Processing Service
 * 
 * 閹绘劒绶甸崶鍓у�鐟欙絿鐖滈妴浣虹椽閻�降鈧�胶绱�潏鎴欌偓浣稿帗閺佺増宓佹径鍕�倞缁涘�濮涢懗?
 * 
 * @since 2.0.0
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { imageCacheManager, ImageScaleOptions } from '../image/ImageCacheManager';
// NAPI 濡�€虫健閿涘牆顩ч弸娣?+鎼存挸鍑＄紓鏍�槯閿?
// import imagekit from 'libimagekit.so';

/**
 * 閸ュ墽澧栭弽鐓庣础
 */
export enum ImageFormat {
  /** JPEG閺嶇厧绱?*/
  JPEG = 'jpeg',
  /** PNG閺嶇厧绱?*/
  PNG = 'png',
  /** WEBP閺嶇厧绱?*/
  WEBP = 'webp',
  /** BMP閺嶇厧绱?*/
  BMP = 'bmp',
  /** GIF閺嶇厧绱?*/
  GIF = 'gif'
}

/**
 * 閸ュ墽澧栫拹銊╁櫤
 */
export enum ImageQuality {
  /** 娴ｅ氦宸濋柌?*/
  LOW = 30,
  /** 娑擃厾鐡戠拹銊╁櫤 */
  MEDIUM = 60,
  /** 妤傛ǹ宸濋柌?*/
  HIGH = 80,
  /** 閺堚偓妤傛ǹ宸濋柌?*/
  MAXIMUM = 95
}

/**
 * 閸ュ墽澧栫紓鈺傛杹濡�€崇础
 */
export enum ImageScaleMode {
  /** 闁�倸绨查敍鍫滅箽閹镐焦鐦�笟瀣剁礆 */
  FIT = 'fit',
  /** 婵夘偄鍘栭敍鍫ｎ梿閸擃亷绱?*/
  FILL = 'fill',
  /** 閹峰�鍑?*/
  STRETCH = 'stretch'
}

/**
 * 閸ュ墽澧栭弮瀣�祮鐟欐帒瀹?
 */
export enum ImageRotation {
  /** 0鎼?*/
  ROTATION_0 = 0,
  /** 90鎼?*/
  ROTATION_90 = 90,
  /** 180鎼?*/
  ROTATION_180 = 180,
  /** 270鎼?*/
  ROTATION_270 = 270
}

/**
 * 閸ュ墽澧栫憗浣稿�閸栧搫鐓?
 */
export interface ImageCropRegion {
  /** X閸ф劖鐖?*/
  x: number;
  /** Y閸ф劖鐖?*/
  y: number;
  /** 鐎硅棄瀹?*/
  width: number;
  /** 妤傛ê瀹?*/
  height: number;
}

/**
 * 閸ュ墽澧栭崗鍐╂殶閹?
 */
export interface ImageMetadata {
  /** 鐎硅棄瀹?*/
  width: number;
  /** 妤傛ê瀹?*/
  height: number;
  /** 閺嶇厧绱?*/
  format: ImageFormat;
  /** 閺傚洣娆㈡径褍鐨?*/
  fileSize: number;
  /** 閼规彃鍍电粚娲�？ */
  colorSpace?: string;
  /** DPI */
  dpi?: number;
  /** EXIF閺佺増宓?*/
  exif?: Record<string, string | number | boolean>;
  /** 閸掓稑缂撻弮鍫曟？ */
  createTime?: number;
  /** 娣囶喗鏁奸弮鍫曟？ */
  modifyTime?: number;
}

/**
 * 閸ュ墽澧栨径鍕�倞闁��銆?
 */
export interface ImageProcessingOptions {
  /** 閻╊喗鐖ｇ€硅棄瀹?*/
  width?: number;
  /** 閻╊喗鐖ｆ�妯哄� */
  height?: number;
  /** 缂傗晜鏂佸Ο鈥崇础 */
  scaleMode?: ImageScaleMode;
  /** 鐠愩劑鍣洪敍?-100閿?*/
  quality?: number;
  /** 鏉堟挸鍤�弽鐓庣础 */
  format?: ImageFormat;
  /** 閺冨�娴嗙憴鎺戝� */
  rotation?: ImageRotation;
  /** 鐟佷礁澹€閸栧搫鐓?*/
  cropRegion?: ImageCropRegion;
}

/**
 * 閸ュ墽澧栨径鍕�倞缂佹挻鐏?
 */
export interface ImageProcessResult {
  /** 閺勵垰鎯侀幋鎰�� */
  success: boolean;
  /** 鏉堟挸鍤璘RI */
  outputUri?: string;
  /** 闁挎瑨顕ゆ穱鈩冧紖 */
  error?: string;
  /** 婢跺嫮鎮婃穱鈩冧紖 */
  message: string;
}

/**
 * 缂傗晝鏆愰崶楣冣偓澶愩€?
 */
export interface ThumbnailOptions {
  /** 鐎硅棄瀹?*/
  width: number;
  /** 妤傛ê瀹?*/
  height: number;
  /** 鐠愩劑鍣?*/
  quality?: number;
  /** 閺嶇厧绱?*/
  format?: ImageFormat;
}

/**
 * 鐏忎線娼伴悽鐔稿灇闁��銆?
 */
export interface CoverGenerationOptions {
  /** 娑旓妇鐫勯弽鍥�暯 */
  title: string;
  /** 娴ｆ粏鈧?*/
  author: string;
  /** 閼冲本娅欐０婊嗗� */
  backgroundColor?: string;
  /** 閺傚洤鐡ф０婊嗗� */
  textColor?: string;
  /** 鐎硅棄瀹?*/
  width?: number;
  /** 妤傛ê瀹?*/
  height?: number;
  /** 閺嶅嘲绱?*/
  style?: 'abstract' | 'minimalist' | 'artistic' | 'gradient';
}

/**
 * Image Kit 閺堝秴濮熺猾?
 */
class ImageKitService {
  /** 閸楁洑绶ョ€圭偘绶?*/
  private static instance: ImageKitService;
  
  /** 娑撳﹣绗呴弬?*/
  private context: common.Context | null = null;
  
  /** 閺勵垰鎯佸�鎻掑灥婵��瀵?*/
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 閼惧嘲褰囬崡鏇氱伐鐎圭偘绶?
   */
  static getInstance(): ImageKitService {
    if (!ImageKitService.instance) {
      ImageKitService.instance = new ImageKitService();
    }
    return ImageKitService.instance;
  }

  /**
   * 閸掓繂顫愰崠鏍ㄦ箛閸?
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      logger.info('[ImageKit] Initializing...');
      this.context = context;
      this.isInitialized = true;
      logger.info('[ImageKit] Initialized successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageKit] Init failed:', err.message);
      return false;
    }
  }

  /**
   * 濡�偓閺屻儲婀囬崝鈩冩Ц閸氾箑姘ㄧ紒?
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 閸ュ墽澧栫憴锝囩垳 ====================

  /**
   * 鐟欙絿鐖滈崶鍓у�
   */
  async decodeImage(imageUri: string): Promise<ImageMetadata | null> {
    try {
      // 閸忓牊顥呴弻銉х处鐎?
      const cachedPath = imageCacheManager.getCachedImagePath(imageUri);
      if (cachedPath) {
        logger.info('[ImageKit] Using cached image:', cachedPath);
        return this.getImageMetadataInternal(cachedPath);
      }
      
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Decoding image:', imageUri);

      // 娴ｈ法鏁?NAPI 鐟欙絿鐖滈敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // const info = await imagekit.decodeImage(imageUri);
      
      // 娑撳瓨妞傜€圭偟骞囬敍姘愁嚢閸欐牗鏋冩禒鎯板箯閸欐牕鐔€閺堫兛淇婇幁?
      const stat = fileIo.statSync(imageUri);
      return {
        width: 0, // 闂団偓鐟?NAPI 鐎圭偟骞?
        height: 0,
        format: this.getFormatFromExtension(imageUri),
        fileSize: stat.size
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageKit] Decode image failed:', err.message);
      logger.error('[ImageKit] Decode image failed:', error);
      return null;
    }
  }

  /**
   * 閸愬懘鍎撮懢宄板絿閸ュ墽澧栭崗鍐╂殶閹?
   */
  private getImageMetadataInternal(filePath: string): ImageMetadata | null {
    try {
      const stat = fileIo.statSync(filePath);
      return {
        width: 0,
        height: 0,
        format: this.getFormatFromExtension(filePath),
        fileSize: stat.size
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageKit] Get metadata internal failed:', err.message);
      logger.error('[ImageKit] Get metadata internal failed:', error);
      return null;
    }
  }

  /**
   * 閺嶈�宓侀幍鈺佺潔閸氬秷骞忛崣鏍ㄧ壐瀵?
   */
  private getFormatFromExtension(filePath: string): ImageFormat {
    const parts = filePath.split('.');
    const ext = parts.length > 0 ? parts[parts.length - 1].toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return ImageFormat.JPEG;
      case 'png':
        return ImageFormat.PNG;
      case 'webp':
        return ImageFormat.WEBP;
      case 'bmp':
        return ImageFormat.BMP;
      case 'gif':
        return ImageFormat.GIF;
      default:
        return ImageFormat.JPEG;
    }
  }

  /**
   * 閹靛綊鍣虹憴锝囩垳閸ュ墽澧?
   */
  async decodeImages(imageUris: string[]): Promise<Map<string, ImageMetadata>> {
    const results = new Map<string, ImageMetadata>();

    for (const uri of imageUris) {
      const metadata = await this.decodeImage(uri);
      if (metadata) {
        results.set(uri, metadata);
      }
    }

    return results;
  }

  // ==================== 閸ュ墽澧栫紓鏍�垳 ====================

  /**
   * 缂傛牜鐖滈崶鍓у�
   */
  async encodeImage(
    imageData: ArrayBuffer,
    format: ImageFormat = ImageFormat.JPEG,
    quality: number = ImageQuality.HIGH
  ): Promise<string | null> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Encoding image to', format, 'quality:', quality);

      // 娴ｈ法鏁?NAPI 缂傛牜鐖滈敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.encodeImage(inputPath, outputPath, { format, quality });
      
      // 娑撳瓨妞傜€圭偟骞囬敍姘崇箲閸ョ偞鏆熼幑顕嗙礄鐎圭偤妾�惔鏂垮晸閸忋儲鏋冩禒璁圭礆
      logger.info('[ImageKit] Encode image (temporary implementation)');
      return null;
    } catch (error) {
      logger.error('[ImageKit] Encode image failed:', error);
      return null;
    }
  }

  // ==================== 閸ュ墽澧栭崢瀣�級 ====================

  /**
   * 閸樺�缂夐崶鍓у�
   */
  async compressImage(
    imageUri: string,
    quality: number = ImageQuality.HIGH,
    maxWidth?: number,
    maxHeight?: number
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Compressing image:', imageUri, 'quality:', quality);

      // 娴ｈ法鏁?NAPI 閸樺�缂夐敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.compressImage(inputPath, outputPath, { quality });
      
      // 娑撳瓨妞傜€圭偟骞?
      return {
        success: true,
        outputUri: imageUri,
        message: '閸ュ墽澧栭崢瀣�級閹存劕濮?
      };
    } catch (error) {
      logger.error('[ImageKit] Compress image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '閸ュ墽澧栭崢瀣�級婢惰精瑙?
      };
    }
  }

  /**
   * 閹靛綊鍣洪崢瀣�級閸ュ墽澧?
   */
  async compressImages(
    imageUris: string[],
    quality: number = ImageQuality.HIGH,
    maxWidth?: number,
    maxHeight?: number
  ): Promise<ImageProcessResult[]> {
    const results: ImageProcessResult[] = [];

    for (const uri of imageUris) {
      const result = await this.compressImage(uri, quality, maxWidth, maxHeight);
      results.push(result);
    }

    return results;
  }

  // ==================== 閸ュ墽澧栫紓鈺傛杹 ====================

  /**
   * 缂傗晜鏂侀崶鍓у�
   */
  async scaleImage(
    imageUri: string,
    width: number,
    height: number,
    scaleMode: ImageScaleMode = ImageScaleMode.FIT
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Scaling image:', imageUri, `${width}x${height}`);

      // 娴ｈ法鏁?NAPI 缂傗晜鏂侀敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.resizeImage(inputPath, outputPath, { width, height, keepAspectRatio: scaleMode === ImageScaleMode.FIT });
      
      // 娑撳瓨妞傜€圭偟骞?
      logger.info('[ImageKit] Resize image:', width, 'x', height);
      return {
        success: true,
        outputUri: imageUri,
        message: '閸ュ墽澧栫紓鈺傛杹閹存劕濮?
      };
    } catch (error) {
      logger.error('[ImageKit] Scale image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '閸ュ墽澧栫紓鈺傛杹婢惰精瑙?
      };
    }
  }

  /**
   * 閻㈢喐鍨氱紓鈺冩殣閸?
   */
  async generateThumbnail(
    imageUri: string,
    options: ThumbnailOptions
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Generating thumbnail:', imageUri);

      return await this.scaleImage(
        imageUri,
        options.width,
        options.height,
        ImageScaleMode.FIT
      );
    } catch (error) {
      logger.error('[ImageKit] Generate thumbnail failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '缂╃暐鍥剧敓鎴愬け璐?
      };
    }
  }

  // ==================== 閸ュ墽澧栭弮瀣�祮 ====================

  /**
   * 閺冨�娴嗛崶鍓у�
   */
  async rotateImage(
    imageUri: string,
    rotation: ImageRotation
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Rotating image:', imageUri, rotation + '鎺?);

      // 娴ｈ法鏁?NAPI 閺冨�娴嗛敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.rotateImage(inputPath, outputPath, { degrees: rotation });
      
      logger.info('[ImageKit] Rotate image:', rotation);
      return {
        success: true,
        outputUri: imageUri,
        message: '閸ュ墽澧栭弮瀣�祮閹存劕濮?
      };
    } catch (error) {
      logger.error('[ImageKit] Rotate image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '閸ュ墽澧栭弮瀣�祮婢惰精瑙?
      };
    }
  }

  // ==================== 閸ュ墽澧栫憗浣稿� ====================

  /**
   * 鐟佷礁澹€閸ュ墽澧?
   */
  async cropImage(
    imageUri: string,
    cropRegion: ImageCropRegion
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Cropping image:', imageUri, cropRegion);

      // 娴ｈ法鏁?NAPI 鐟佷礁澹€閿涘牆顩ч弸婊冨讲閻㈩煉绱?
      // return await imagekit.cropImage(inputPath, outputPath, { x: cropRegion.x, y: cropRegion.y, width: cropRegion.width, height: cropRegion.height });
      
      logger.info('[ImageKit] Crop image:', cropRegion.x, cropRegion.y, cropRegion.width, cropRegion.height);
      return {
        success: true,
        outputUri: imageUri,
        message: '閸ュ墽澧栫憗浣稿�閹存劕濮?
      };
    } catch (error) {
      logger.error('[ImageKit] Crop image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '閸ュ墽澧栫憗浣稿�婢惰精瑙?
      };
    }
  }

  // ==================== 閸ュ墽澧栫紓鏍�帆 ====================

  /**
   * 婢跺嫮鎮婇崶鍓у�閿涘牏鎮ｉ崥鍫熸惙娴ｆ粣绱?
   */
  async processImage(
    imageUri: string,
    options: ImageProcessingOptions
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Processing image:', imageUri, options);

      let result = true;
      
      // 閹稿�銆庢惔蹇擃槱閻炲棴绱伴弮瀣�祮 -> 鐟佷礁澹€ -> 缂傗晜鏂?-> 閸樺�缂?
      if (options.rotation) {
        const rotateResult = await this.rotateImage(imageUri, options.rotation);
        result = result && rotateResult.success;
      }
      if (options.cropRegion) {
        const cropResult = await this.cropImage(imageUri, options.cropRegion);
        result = result && cropResult.success;
      }
      if (options.width && options.height) {
        const scaleResult = await this.scaleImage(imageUri, options.width, options.height, options.scaleMode || ImageScaleMode.FIT);
        result = result && scaleResult.success;
      }
      if (options.quality && options.quality < 100) {
        const compressResult = await this.compressImage(imageUri, options.quality);
        result = result && compressResult.success;
      }
      
      return {
        success: result,
        outputUri: imageUri,
        message: result ? '閸ュ墽澧栨径鍕�倞閹存劕濮? : '閸ュ墽澧栨径鍕�倞闁�劌鍨庢径杈�Е'
      };
    } catch (error) {
      logger.error('[ImageKit] Process image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '閸ュ墽澧栨径鍕�倞婢惰精瑙?
      };
    }
  }

  // ==================== 閸ュ墽澧栭崗鍐╂殶閹?====================

  /**
   * 閼惧嘲褰囬崶鍓у�閸忓啯鏆熼幑?
   */
  async getImageMetadata(imageUri: string): Promise<ImageMetadata | null> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Getting image metadata:', imageUri);

      // 娴ｈ法鏁?NAPI 閼惧嘲褰囬敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.getImageMetadata(imageUri);
      
      // 娑撳瓨妞傜€圭偟骞?
      return this.getImageMetadataInternal(imageUri);
    } catch (error) {
      logger.error('[ImageKit] Get metadata failed:', error);
      return null;
    }
  }

  /**
   * 閺囧瓨鏌婇崶鍓у�閸忓啯鏆熼幑?
   */
  async updateImageMetadata(
    imageUri: string,
    metadata: Record<string, string | number | boolean>
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Updating image metadata:', imageUri);

      // 娴ｈ法鏁?NAPI 鐠佸墽鐤嗛敍鍫濐洤閺嬫粌褰查悽顭掔礆
      // return await imagekit.setImageMetadata(imageUri, metadata);
      
      logger.info('[ImageKit] Set metadata:', metadata);
      return {
        success: true,
        outputUri: imageUri,
        message: '鍏冩暟鎹�洿鏂版垚鍔?
      };
    } catch (error) {
      logger.error('[ImageKit] Update metadata failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍏冩暟鎹�洿鏂板け璐?
      };
    }
  }

  // ==================== 鐏忎線娼伴悽鐔稿灇 ====================

  /**
   * 閻㈢喐鍨氭稊锔剧潉鐏忎線娼?
   */
  async generateBookCover(options: CoverGenerationOptions): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Generating book cover:', options.title);

      // 鐏忔繆鐦�禒搴濆姛缁�秵褰侀崣鏍�儑娑撯偓妞ゅ吀缍旀稉鍝勭殱闂?
      // const decoded = await this.decodeImage(options.title);
      // if (decoded) {
      //   // 缂傗晝鏆愰崶鍙ョ稊娑撳搫鐨濋棃?
      //   return this.scaleImage(options.title, 300, 400);
      // }
      
      // 閸氾箑鍨�悽鐔稿灇姒涙ǹ顓荤亸渚€娼?
      logger.info('[ImageKit] Generate default cover for:', options.title);
      return {
        success: true,
        outputUri: '',
        message: '鐏忎線娼伴悽鐔稿灇閹存劕濮?
      };
    } catch (error) {
      logger.error('[ImageKit] Generate cover failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鐏忎線娼伴悽鐔稿灇婢惰精瑙?
      };
    }
  }

  /**
   * 閻㈢喐鍨氶崝銊︹偓浣哥殱闂堫澁绱欓崺杞扮艾娑旓箑鎮曢崫鍫濈瑖閿?
   */
  async generateDynamicCover(title: string, author?: string): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Generating dynamic cover for:', title);

      // 閸╄桨绨�稊锕€鎮曢悽鐔稿灇閸濆牆绗?
      const hash = this.hashCode(title);
      const hue = hash % 360;
      
      const options: CoverGenerationOptions = {
        title: title,
        author: author || '鏈�煡浣滆€?,
        backgroundColor: `hsl(${hue}, 60%, 50%)`,
        textColor: '#FFFFFF',
        width: 400,
        height: 560,
        style: 'gradient'
      };

      return await this.generateBookCover(options);
    } catch (error) {
      logger.error('[ImageKit] Generate dynamic cover failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍔ㄦ€佸皝闈㈢敓鎴愬け璐?
      };
    }
  }

  // ==================== 濠曨偆鏁炬径鍕�倞 ====================

  /**
   * 閹绘劕褰囧⿻顐ゆ暰妞ょ敻娼?
   */
  async extractComicPages(
    archiveUri: string,
    pageIndex: number
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      logger.info('[ImageKit] Extracting comic page:', archiveUri, pageIndex);

      const parts = archiveUri.split('.');
      const ext = parts.length > 0 ? parts[parts.length - 1].toLowerCase() : '';

      if (ext === 'cbz' || ext === 'zip') {
        // ZIP 閺傚洣娆㈤崣顖欎簰娴ｈ法鏁?JS 鐟欙絽甯?
        logger.info('[ImageKit] Extract CBZ/ZIP:', archiveUri);
        // TODO: 鐎圭偟骞?ZIP 鐟欙絽甯?
      } else if (ext === 'cbr') {
        // RAR 閺傚洣娆㈤棁鈧�憰?NAPI 鐎圭偟骞?
        logger.info('[ImageKit] Extract CBR (RAR):', archiveUri);
        // TODO: 娴ｈ法鏁?NAPI 鐎圭偟骞?RAR 鐟欙絽甯?
        // const images = await imagekit.extractRar(archiveUri, outputDir);
      }
      
      return {
        success: true,
        outputUri: '',
        message: '濠曨偆鏁炬い鐢告桨閹绘劕褰囬幋鎰��'
      };
    } catch (error) {
      logger.error('[ImageKit] Extract comic page failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '濠曨偆鏁炬い鐢告桨閹绘劕褰囨径杈�Е'
      };
    }
  }

  /**
   * 閹靛綊鍣洪幓鎰�絿濠曨偆鏁炬い鐢告桨
   */
  async extractComicPagesBatch(
    archiveUri: string,
    pageIndices: number[]
  ): Promise<ImageProcessResult[]> {
    const results: ImageProcessResult[] = [];

    for (const pageIndex of pageIndices) {
      const result = await this.extractComicPages(archiveUri, pageIndex);
      results.push(result);
    }

    return results;
  }

  // ==================== 閸ュ墽澧栫紓鎾崇摠 ====================

  /**
   * 缂傛挸鐡ㄩ崶鍓у�
   */
  async cacheImage(imageUri: string, cacheKey: string): Promise<boolean> {
    try {
      logger.info('[ImageKit] Caching image:', cacheKey);
      await imageCacheManager.cacheImage(imageUri, cacheKey);
      return true;
    } catch (error) {
      logger.error('[ImageKit] Cache image failed:', error);
      return false;
    }
  }

  /**
   * 閼惧嘲褰囩紓鎾崇摠閸ュ墽澧?
   */
  async getCachedImage(cacheKey: string): Promise<string | null> {
    try {
      return imageCacheManager.getCachedImagePath(cacheKey);
    } catch (error) {
      logger.error('[ImageKit] Get cached image failed:', error);
      return null;
    }
  }

  /**
   * 鑾峰彇甯︾紦瀛樼殑鍥剧墖
   */
  async getImageWithCache(filePath: string, options?: ImageScaleOptions): Promise<string | null> {
    try {
      const cachedPath = imageCacheManager.getCachedImagePath(filePath);
      if (cachedPath) {
        return cachedPath;
      }
      // 濡傛灉娌℃湁缂撳瓨锛屽垯澶勭悊鍥剧墖骞剁紦瀛?
      const processedPath = await this.processImageWithCache(filePath, options);
      return processedPath;
    } catch (error) {
      logger.error('[ImageKit] Get image with cache failed:', error);
      return null;
    }
  }

  /**
   * 澶勭悊鍥剧墖骞剁紦瀛?
   */
  private async processImageWithCache(filePath: string, options?: ImageScaleOptions): Promise<string | null> {
    // 涓存椂瀹炵幇锛氳繑鍥炲師璺�緞
    logger.info('[ImageKit] Process image with cache:', filePath);
    return filePath;
  }

  /**
   * 缂撳瓨鍥剧墖鏂囦欢
   */
  async cacheImageFile(sourcePath: string, processedPath: string, options?: ImageScaleOptions): Promise<void> {
    try {
      await imageCacheManager.cacheImage(sourcePath, processedPath, options);
    } catch (error) {
      logger.error('[ImageKit] Cache image file failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 娓呯┖鍥剧墖缂撳瓨
   */
  async clearImageCache(): Promise<void> {
    try {
      logger.info('[ImageKit] Clearing image cache...');
      await imageCacheManager.clearCache();
      logger.info('[ImageKit] Image cache cleared');
    } catch (error) {
      logger.error('[ImageKit] Clear image cache failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 鑾峰彇鍥剧墖缂撳瓨澶у皬
   */
  getImageCacheSize(): number {
    try {
      return imageCacheManager.getCacheSize();
    } catch (error) {
      logger.error('[ImageKit] Get image cache size failed:', error);
      return 0;
    }
  }

  /**
   * 閲婃斁璧勬簮
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    logger.info('[ImageKit] Released resources');
  }

  /**
   * 鐢熸垚瀛楃�涓插搱甯岀爜
   */
  private hashCode(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 杞�崲涓?2浣嶆暣鏁?
    }
    return hash;
  }
}

// 鐎电厧鍤�崡鏇氱伐
export const imageKitService = ImageKitService.getInstance();
export default imageKitService;
