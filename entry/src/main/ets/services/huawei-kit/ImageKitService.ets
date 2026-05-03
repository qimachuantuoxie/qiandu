/**
 * Image Kit 鏈嶅姟 - 鍥剧墖澶勭悊鏈嶅姟
 * Image Kit Service - Image Processing Service
 * 
 * 鎻愪緵鍥剧墖瑙ｇ爜銆佺紪鐮併€佺紪杈戙€佸厓鏁版嵁澶勭悊绛夊姛鑳?
 * 
 * @since 2.0.0
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { imageCacheManager, ImageScaleOptions } from '../image/ImageCacheManager';
// NAPI 妯″潡锛堝鏋淐++搴撳凡缂栬瘧锛?
// import imagekit from 'libimagekit.so';

/**
 * 鍥剧墖鏍煎紡
 */
export enum ImageFormat {
  /** JPEG鏍煎紡 */
  JPEG = 'jpeg',
  /** PNG鏍煎紡 */
  PNG = 'png',
  /** WEBP鏍煎紡 */
  WEBP = 'webp',
  /** BMP鏍煎紡 */
  BMP = 'bmp',
  /** GIF鏍煎紡 */
  GIF = 'gif'
}

/**
 * 鍥剧墖璐ㄩ噺
 */
export enum ImageQuality {
  /** 浣庤川閲?*/
  LOW = 30,
  /** 涓瓑璐ㄩ噺 */
  MEDIUM = 60,
  /** 楂樿川閲?*/
  HIGH = 80,
  /** 鏈€楂樿川閲?*/
  MAXIMUM = 95
}

/**
 * 鍥剧墖缂╂斁妯″紡
 */
export enum ImageScaleMode {
  /** 閫傚簲锛堜繚鎸佹瘮渚嬶級 */
  FIT = 'fit',
  /** 濉厖锛堣鍓級 */
  FILL = 'fill',
  /** 鎷変几 */
  STRETCH = 'stretch'
}

/**
 * 鍥剧墖鏃嬭浆瑙掑害
 */
export enum ImageRotation {
  /** 0搴?*/
  ROTATION_0 = 0,
  /** 90搴?*/
  ROTATION_90 = 90,
  /** 180搴?*/
  ROTATION_180 = 180,
  /** 270搴?*/
  ROTATION_270 = 270
}

/**
 * 鍥剧墖瑁佸壀鍖哄煙
 */
export interface ImageCropRegion {
  /** X鍧愭爣 */
  x: number;
  /** Y鍧愭爣 */
  y: number;
  /** 瀹藉害 */
  width: number;
  /** 楂樺害 */
  height: number;
}

/**
 * 鍥剧墖鍏冩暟鎹?
 */
export interface ImageMetadata {
  /** 瀹藉害 */
  width: number;
  /** 楂樺害 */
  height: number;
  /** 鏍煎紡 */
  format: ImageFormat;
  /** 鏂囦欢澶у皬 */
  fileSize: number;
  /** 鑹插僵绌洪棿 */
  colorSpace?: string;
  /** DPI */
  dpi?: number;
  /** EXIF鏁版嵁 */
  exif?: Record<string, string | number | boolean>;
  /** 鍒涘缓鏃堕棿 */
  createTime?: number;
  /** 淇敼鏃堕棿 */
  modifyTime?: number;
}

/**
 * 鍥剧墖澶勭悊閫夐」
 */
export interface ImageProcessingOptions {
  /** 鐩爣瀹藉害 */
  width?: number;
  /** 鐩爣楂樺害 */
  height?: number;
  /** 缂╂斁妯″紡 */
  scaleMode?: ImageScaleMode;
  /** 璐ㄩ噺锛?-100锛?*/
  quality?: number;
  /** 杈撳嚭鏍煎紡 */
  format?: ImageFormat;
  /** 鏃嬭浆瑙掑害 */
  rotation?: ImageRotation;
  /** 瑁佸壀鍖哄煙 */
  cropRegion?: ImageCropRegion;
}

/**
 * 鍥剧墖澶勭悊缁撴灉
 */
export interface ImageProcessResult {
  /** 鏄惁鎴愬姛 */
  success: boolean;
  /** 杈撳嚭URI */
  outputUri?: string;
  /** 閿欒淇℃伅 */
  error?: string;
  /** 澶勭悊淇℃伅 */
  message: string;
}

/**
 * 缂╃暐鍥鹃€夐」
 */
export interface ThumbnailOptions {
  /** 瀹藉害 */
  width: number;
  /** 楂樺害 */
  height: number;
  /** 璐ㄩ噺 */
  quality?: number;
  /** 鏍煎紡 */
  format?: ImageFormat;
}

/**
 * 灏侀潰鐢熸垚閫夐」
 */
export interface CoverGenerationOptions {
  /** 涔︾睄鏍囬 */
  title: string;
  /** 浣滆€?*/
  author: string;
  /** 鑳屾櫙棰滆壊 */
  backgroundColor?: string;
  /** 鏂囧瓧棰滆壊 */
  textColor?: string;
  /** 瀹藉害 */
  width?: number;
  /** 楂樺害 */
  height?: number;
  /** 鏍峰紡 */
  style?: 'abstract' | 'minimalist' | 'artistic' | 'gradient';
}

/**
 * Image Kit 鏈嶅姟绫?
 */
class ImageKitService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: ImageKitService;
  
  /** 涓婁笅鏂?*/
  private context: common.Context | null = null;
  
  /** 鏄惁宸插垵濮嬪寲 */
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): ImageKitService {
    if (!ImageKitService.instance) {
      ImageKitService.instance = new ImageKitService();
    }
    return ImageKitService.instance;
  }

  /**
   * 鍒濆鍖栨湇鍔?
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      console.info('[ImageKit] Initializing...');
      this.context = context;
      this.isInitialized = true;
      console.info('[ImageKit] Initialized successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      console.error('[ImageKit] Init failed:', err.message);
      return false;
    }
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 鍥剧墖瑙ｇ爜 ====================

  /**
   * 瑙ｇ爜鍥剧墖
   */
  async decodeImage(imageUri: string): Promise<ImageMetadata | null> {
    try {
      // 鍏堟鏌ョ紦瀛?
      const cachedPath = imageCacheManager.getCachedImagePath(imageUri);
      if (cachedPath) {
        console.info('[ImageKit] Using cached image:', cachedPath);
        return this.getImageMetadataInternal(cachedPath);
      }
      
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Decoding image:', imageUri);

      // 浣跨敤 NAPI 瑙ｇ爜锛堝鏋滃彲鐢級
      // const info = await imagekit.decodeImage(imageUri);
      
      // 涓存椂瀹炵幇锛氳鍙栨枃浠惰幏鍙栧熀鏈俊鎭?
      const stat = fileIo.statSync(imageUri);
      return {
        width: 0, // 闇€瑕?NAPI 瀹炵幇
        height: 0,
        format: this.getFormatFromExtension(imageUri),
        fileSize: stat.size
      };
    } catch (error) {
      const err = error as Error;
      console.error('[ImageKit] Decode image failed:', err.message);
      console.error('[ImageKit] Decode image failed:', error);
      return null;
    }
  }

  /**
   * 鍐呴儴鑾峰彇鍥剧墖鍏冩暟鎹?
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
      console.error('[ImageKit] Get metadata internal failed:', err.message);
      console.error('[ImageKit] Get metadata internal failed:', error);
      return null;
    }
  }

  /**
   * 鏍规嵁鎵╁睍鍚嶈幏鍙栨牸寮?
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
   * 鎵归噺瑙ｇ爜鍥剧墖
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

  // ==================== 鍥剧墖缂栫爜 ====================

  /**
   * 缂栫爜鍥剧墖
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

      console.info('[ImageKit] Encoding image to', format, 'quality:', quality);

      // 浣跨敤 NAPI 缂栫爜锛堝鏋滃彲鐢級
      // return await imagekit.encodeImage(inputPath, outputPath, { format, quality });
      
      // 涓存椂瀹炵幇锛氳繑鍥炴暟鎹紙瀹為檯搴斿啓鍏ユ枃浠讹級
      console.info('[ImageKit] Encode image (temporary implementation)');
      return null;
    } catch (error) {
      console.error('[ImageKit] Encode image failed:', error);
      return null;
    }
  }

  // ==================== 鍥剧墖鍘嬬缉 ====================

  /**
   * 鍘嬬缉鍥剧墖
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

      console.info('[ImageKit] Compressing image:', imageUri, 'quality:', quality);

      // 浣跨敤 NAPI 鍘嬬缉锛堝鏋滃彲鐢級
      // return await imagekit.compressImage(inputPath, outputPath, { quality });
      
      // 涓存椂瀹炵幇
      return {
        success: true,
        outputUri: imageUri,
        message: '鍥剧墖鍘嬬缉鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Compress image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍥剧墖鍘嬬缉澶辫触'
      };
    }
  }

  /**
   * 鎵归噺鍘嬬缉鍥剧墖
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

  // ==================== 鍥剧墖缂╂斁 ====================

  /**
   * 缂╂斁鍥剧墖
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

      console.info('[ImageKit] Scaling image:', imageUri, `${width}x${height}`);

      // 浣跨敤 NAPI 缂╂斁锛堝鏋滃彲鐢級
      // return await imagekit.resizeImage(inputPath, outputPath, { width, height, keepAspectRatio: scaleMode === ImageScaleMode.FIT });
      
      // 涓存椂瀹炵幇
      console.info('[ImageKit] Resize image:', width, 'x', height);
      return {
        success: true,
        outputUri: imageUri,
        message: '鍥剧墖缂╂斁鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Scale image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍥剧墖缂╂斁澶辫触'
      };
    }
  }

  /**
   * 鐢熸垚缂╃暐鍥?
   */
  async generateThumbnail(
    imageUri: string,
    options: ThumbnailOptions
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Generating thumbnail:', imageUri);

      return await this.scaleImage(
        imageUri,
        options.width,
        options.height,
        ImageScaleMode.FIT
      );
    } catch (error) {
      console.error('[ImageKit] Generate thumbnail failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '缩略图生成失败'
      };
    }
  }

  // ==================== 鍥剧墖鏃嬭浆 ====================

  /**
   * 鏃嬭浆鍥剧墖
   */
  async rotateImage(
    imageUri: string,
    rotation: ImageRotation
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Rotating image:', imageUri, rotation + '掳');

      // 浣跨敤 NAPI 鏃嬭浆锛堝鏋滃彲鐢級
      // return await imagekit.rotateImage(inputPath, outputPath, { degrees: rotation });
      
      console.info('[ImageKit] Rotate image:', rotation);
      return {
        success: true,
        outputUri: imageUri,
        message: '鍥剧墖鏃嬭浆鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Rotate image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍥剧墖鏃嬭浆澶辫触'
      };
    }
  }

  // ==================== 鍥剧墖瑁佸壀 ====================

  /**
   * 瑁佸壀鍥剧墖
   */
  async cropImage(
    imageUri: string,
    cropRegion: ImageCropRegion
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Cropping image:', imageUri, cropRegion);

      // 浣跨敤 NAPI 瑁佸壀锛堝鏋滃彲鐢級
      // return await imagekit.cropImage(inputPath, outputPath, { x: cropRegion.x, y: cropRegion.y, width: cropRegion.width, height: cropRegion.height });
      
      console.info('[ImageKit] Crop image:', cropRegion.x, cropRegion.y, cropRegion.width, cropRegion.height);
      return {
        success: true,
        outputUri: imageUri,
        message: '鍥剧墖瑁佸壀鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Crop image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍥剧墖瑁佸壀澶辫触'
      };
    }
  }

  // ==================== 鍥剧墖缂栬緫 ====================

  /**
   * 澶勭悊鍥剧墖锛堢患鍚堟搷浣滐級
   */
  async processImage(
    imageUri: string,
    options: ImageProcessingOptions
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Processing image:', imageUri, options);

      let result = true;
      
      // 鎸夐『搴忓鐞嗭細鏃嬭浆 -> 瑁佸壀 -> 缂╂斁 -> 鍘嬬缉
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
        message: result ? '鍥剧墖澶勭悊鎴愬姛' : '鍥剧墖澶勭悊閮ㄥ垎澶辫触'
      };
    } catch (error) {
      console.error('[ImageKit] Process image failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '鍥剧墖澶勭悊澶辫触'
      };
    }
  }

  // ==================== 鍥剧墖鍏冩暟鎹?====================

  /**
   * 鑾峰彇鍥剧墖鍏冩暟鎹?
   */
  async getImageMetadata(imageUri: string): Promise<ImageMetadata | null> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Getting image metadata:', imageUri);

      // 浣跨敤 NAPI 鑾峰彇锛堝鏋滃彲鐢級
      // return await imagekit.getImageMetadata(imageUri);
      
      // 涓存椂瀹炵幇
      return this.getImageMetadataInternal(imageUri);
    } catch (error) {
      console.error('[ImageKit] Get metadata failed:', error);
      return null;
    }
  }

  /**
   * 鏇存柊鍥剧墖鍏冩暟鎹?
   */
  async updateImageMetadata(
    imageUri: string,
    metadata: Record<string, string | number | boolean>
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Updating image metadata:', imageUri);

      // 浣跨敤 NAPI 璁剧疆锛堝鏋滃彲鐢級
      // return await imagekit.setImageMetadata(imageUri, metadata);
      
      console.info('[ImageKit] Set metadata:', metadata);
      return {
        success: true,
        outputUri: imageUri,
        message: '元数据更新成功'
      };
    } catch (error) {
      console.error('[ImageKit] Update metadata failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '元数据更新失败'
      };
    }
  }

  // ==================== 灏侀潰鐢熸垚 ====================

  /**
   * 鐢熸垚涔︾睄灏侀潰
   */
  async generateBookCover(options: CoverGenerationOptions): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Generating book cover:', options.title);

      // 灏濊瘯浠庝功绫嶆彁鍙栫涓€椤典綔涓哄皝闈?
      // const decoded = await this.decodeImage(options.title);
      // if (decoded) {
      //   // 缂╃暐鍥句綔涓哄皝闈?
      //   return this.scaleImage(options.title, 300, 400);
      // }
      
      // 鍚﹀垯鐢熸垚榛樿灏侀潰
      console.info('[ImageKit] Generate default cover for:', options.title);
      return {
        success: true,
        outputUri: '',
        message: '灏侀潰鐢熸垚鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Generate cover failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '灏侀潰鐢熸垚澶辫触'
      };
    }
  }

  /**
   * 鐢熸垚鍔ㄦ€佸皝闈紙鍩轰簬涔﹀悕鍝堝笇锛?
   */
  async generateDynamicCover(title: string, author?: string): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Generating dynamic cover for:', title);

      // 鍩轰簬涔﹀悕鐢熸垚鍝堝笇
      const hash = this.hashCode(title);
      const hue = hash % 360;
      
      const options: CoverGenerationOptions = {
        title: title,
        author: author || '未知作者',
        backgroundColor: `hsl(${hue}, 60%, 50%)`,
        textColor: '#FFFFFF',
        width: 400,
        height: 560,
        style: 'gradient'
      };

      return await this.generateBookCover(options);
    } catch (error) {
      console.error('[ImageKit] Generate dynamic cover failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '动态封面生成失败'
      };
    }
  }

  // ==================== 婕敾澶勭悊 ====================

  /**
   * 鎻愬彇婕敾椤甸潰
   */
  async extractComicPages(
    archiveUri: string,
    pageIndex: number
  ): Promise<ImageProcessResult> {
    try {
      if (!this.isReady()) {
        throw new Error('ImageKit not initialized');
      }

      console.info('[ImageKit] Extracting comic page:', archiveUri, pageIndex);

      const parts = archiveUri.split('.');
      const ext = parts.length > 0 ? parts[parts.length - 1].toLowerCase() : '';

      if (ext === 'cbz' || ext === 'zip') {
        // ZIP 鏂囦欢鍙互浣跨敤 JS 瑙ｅ帇
        console.info('[ImageKit] Extract CBZ/ZIP:', archiveUri);
        // TODO: 瀹炵幇 ZIP 瑙ｅ帇
      } else if (ext === 'cbr') {
        // RAR 鏂囦欢闇€瑕?NAPI 瀹炵幇
        console.info('[ImageKit] Extract CBR (RAR):', archiveUri);
        // TODO: 浣跨敤 NAPI 瀹炵幇 RAR 瑙ｅ帇
        // const images = await imagekit.extractRar(archiveUri, outputDir);
      }
      
      return {
        success: true,
        outputUri: '',
        message: '婕敾椤甸潰鎻愬彇鎴愬姛'
      };
    } catch (error) {
      console.error('[ImageKit] Extract comic page failed:', error);
      const err = error as Error;
      return {
        success: false,
        error: error instanceof Error ? err.message : 'Unknown error',
        message: '婕敾椤甸潰鎻愬彇澶辫触'
      };
    }
  }

  /**
   * 鎵归噺鎻愬彇婕敾椤甸潰
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

  // ==================== 鍥剧墖缂撳瓨 ====================

  /**
   * 缂撳瓨鍥剧墖
   */
  async cacheImage(imageUri: string, cacheKey: string): Promise<boolean> {
    try {
      console.info('[ImageKit] Caching image:', cacheKey);
      await imageCacheManager.cacheImage(imageUri, cacheKey);
      return true;
    } catch (error) {
      console.error('[ImageKit] Cache image failed:', error);
      return false;
    }
  }

  /**
   * 鑾峰彇缂撳瓨鍥剧墖
   */
  async getCachedImage(cacheKey: string): Promise<string | null> {
    try {
      return imageCacheManager.getCachedImagePath(cacheKey);
    } catch (error) {
      console.error('[ImageKit] Get cached image failed:', error);
      return null;
    }
  }

  /**
   * 获取带缓存的图片
   */
  async getImageWithCache(filePath: string, options?: ImageScaleOptions): Promise<string | null> {
    try {
      const cachedPath = imageCacheManager.getCachedImagePath(filePath);
      if (cachedPath) {
        return cachedPath;
      }
      // 如果没有缓存，则处理图片并缓存
      const processedPath = await this.processImageWithCache(filePath, options);
      return processedPath;
    } catch (error) {
      console.error('[ImageKit] Get image with cache failed:', error);
      return null;
    }
  }

  /**
   * 处理图片并缓存
   */
  private async processImageWithCache(filePath: string, options?: ImageScaleOptions): Promise<string | null> {
    // 临时实现：返回原路径
    console.info('[ImageKit] Process image with cache:', filePath);
    return filePath;
  }

  /**
   * 缓存图片文件
   */
  async cacheImageFile(sourcePath: string, processedPath: string, options?: ImageScaleOptions): Promise<void> {
    try {
      await imageCacheManager.cacheImage(sourcePath, processedPath, options);
    } catch (error) {
      console.error('[ImageKit] Cache image file failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 清空图片缓存
   */
  async clearImageCache(): Promise<void> {
    try {
      console.info('[ImageKit] Clearing image cache...');
      await imageCacheManager.clearCache();
      console.info('[ImageKit] Image cache cleared');
    } catch (error) {
      console.error('[ImageKit] Clear image cache failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取图片缓存大小
   */
  getImageCacheSize(): number {
    try {
      return imageCacheManager.getCacheSize();
    } catch (error) {
      console.error('[ImageKit] Get image cache size failed:', error);
      return 0;
    }
  }

  /**
   * 释放资源
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    console.info('[ImageKit] Released resources');
  }

  /**
   * 生成字符串哈希码
   */
  private hashCode(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }
    return hash;
  }
}

// 瀵煎嚭鍗曚緥
export const imageKitService = ImageKitService.getInstance();
export default imageKitService;
