/**
 * 閸ュ墽澧栫紓鎾崇摠缁狅紕鎮婇崳?- 缁狅紕鎮婇崶鍓у缂傛挸鐡?
 * Image Cache Manager - Manage image caching
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { image } from '@kit.ImageKit';

/**
 * 缂傛挸鐡ㄩ柊宥囩枂
 */
export interface CacheConfig {
  /** 閺堚偓婢堆呯处鐎涙ê銇囩亸蹇ョ礄鐎涙濡敍?*/
  maxSize: number;
  /** 缂傛挸鐡ㄩ惄顔肩秿鐠侯垰绶?*/
  cacheDir: string;
  /** 缂傛挸鐡ㄦ潻鍥ㄦ埂閺冨爼妫块敍鍫燁嚑缁夋帪绱?*/
  expiryTime: number;
}

/**
 * 缂傛挸鐡ㄦい?
 */
export interface CacheItem {
  /** 閸樼喎顫愰弬鍥︽鐠侯垰绶?*/
  sourcePath: string;
  /** 缂傛挸鐡ㄩ弬鍥︽鐠侯垰绶?*/
  cachePath: string;
  /** 閺傚洣娆㈡径褍鐨?*/
  size: number;
  /** 閸掓稑缂撻弮鍫曟？ */
  createTime: number;
  /** 閺堚偓閸氬氦顔栭梻顔芥闂?*/
  lastAccessTime: number;
  /** 缂傛挸鐡ㄩ柨?*/
  key: string;
}

/**
 * 閸ュ墽澧栫紓鈺傛杹闁銆?
 */
export interface ImageScaleOptions {
  width?: number;
  height?: number;
}

/**
 * 閸ュ墽澧栫紓鎾崇摠缁狅紕鎮婇崳?
 */
class ImageCacheManager {
  private static instance: ImageCacheManager;
  private context: common.Context | null = null;
  private cacheConfig: CacheConfig = {
    maxSize: 500 * 1024 * 1024, // 500MB
    cacheDir: '',
    expiryTime: 7 * 24 * 60 * 60 * 1000 // 7婢?
  };
  private memoryCache: Map<string, image.PixelMap> = new Map();
  private cacheIndex: Map<string, CacheItem> = new Map();

  private constructor() {}

  static getInstance(): ImageCacheManager {
    if (!ImageCacheManager.instance) {
      ImageCacheManager.instance = new ImageCacheManager();
    }
    return ImageCacheManager.instance;
  }

  /**
   * 閸掓繂顫愰崠?
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    
    // 閼惧嘲褰囩紓鎾崇摠閻╊喖缍?
    const cacheDir = context.cacheDir;
    this.cacheConfig.cacheDir = cacheDir + '/image_cache';
    
    // 閸掓稑缂撶紓鎾崇摠閻╊喖缍?
    try {
      if (!fileIo.accessSync(this.cacheConfig.cacheDir)) {
        fileIo.mkdirSync(this.cacheConfig.cacheDir);
      }
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageCacheManager] Create cache dir failed: ' + errorErr.message);
    }
    
    // 閸旂姾娴囩紓鎾崇摠缁便垹绱?
    await this.loadCacheIndex();
    
    // 濞撳懐鎮婃潻鍥ㄦ埂缂傛挸鐡?
    await this.cleanExpiredCache();
  }

  /**
   * 閸旂姾娴囩紓鎾崇摠缁便垹绱?
   */
  private async loadCacheIndex(): Promise<void> {
    try {
      const indexJson = preferenceManager.getString('image_cache_index', '');
      if (indexJson && indexJson.length > 0) {
        const index = JSON.parse(indexJson) as Record<string, CacheItem>;
        this.cacheIndex = new Map(Object.entries(index));
      }
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageCacheManager] Load cache index failed: ' + errorErr.message);
    }
  }

  /**
   * 娣囨繂鐡ㄧ紓鎾崇摠缁便垹绱?
   */
  private async saveCacheIndex(): Promise<void> {
    try {
      const indexObj: Record<string, CacheItem> = {};
      const keys = Array.from(this.cacheIndex.keys());
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const item = this.cacheIndex.get(key)!;
        indexObj[key] = item;
      }
      const indexJson = JSON.stringify(indexObj);
      preferenceManager.setString('image_cache_index', indexJson);
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageCacheManager] Save cache index failed: ' + errorErr.message);
    }
  }

  /**
   * 閻㈢喐鍨氱紓鎾崇摠闁?
   */
  private generateCacheKey(sourcePath: string, options?: ImageScaleOptions): string {
    let key = sourcePath;
    if (options !== undefined && options !== null) {
      if (options.width !== undefined && options.width !== null) {
        key += '_w' + options.width;
      }
      if (options.height !== undefined && options.height !== null) {
        key += '_h' + options.height;
      }
    }
    // 娴ｈ法鏁ょ粻鈧崡鏇犳畱閸濆牆绗?
    return this.hashString(key);
  }

  /**
   * 鐎涙顑佹稉鎻掓惐鐢?
   */
  private hashString(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 鏉烆剚宕叉稉?2娴ｅ秵鏆ｉ弫?
    }
    return Math.abs(hash).toString(36);
  }

  /**
   * 閼惧嘲褰囩紓鎾崇摠閸ュ墽澧栫捄顖氱窞
   */
  getCachedImagePath(sourcePath: string, options?: ImageScaleOptions): string | null {
    const key = this.generateCacheKey(sourcePath, options);
    const item = this.cacheIndex.get(key);
    
    if (!item) return null;
    
    // 濡偓閺屻儳绱︾€涙ɑ妲搁崥锕佺箖閺?
    const now = Date.now();
    if (now - item.createTime > this.cacheConfig.expiryTime) {
      return null;
    }
    
    // 濡偓閺屻儳绱︾€涙ɑ鏋冩禒鑸垫Ц閸氾箑鐡ㄩ崷?
    try {
      if (fileIo.accessSync(item.cachePath)) {
        // 閺囧瓨鏌婇張鈧崥搴ゎ問闂傤喗妞傞梻?
        item.lastAccessTime = now;
        this.cacheIndex.set(key, item);
        return item.cachePath;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ImageCacheManager] Access cache file failed: ' + message);
      return null;
    }
    
    return null;
  }

  /**
   * 缂傛挸鐡ㄩ崶鍓у
   */
  async cacheImage(sourcePath: string, cachePath: string, options?: ImageScaleOptions): Promise<void> {
    const key = this.generateCacheKey(sourcePath, options);
    
    try {
      // 閼惧嘲褰囬弬鍥︽婢堆冪毈
      const stat = fileIo.statSync(cachePath);
      
      // 濡偓閺屻儳绱︾€涙ê銇囩亸蹇旀Ц閸氾箒绉撮梽?
      await this.checkCacheSize(stat.size);
      
      // 閸掓稑缂撶紓鎾崇摠妞?
      const cacheItem: CacheItem = {
        sourcePath,
        cachePath,
        size: stat.size,
        createTime: Date.now(),
        lastAccessTime: Date.now(),
        key
      };
      
      // 濞ｈ濮為崚鎵偍瀵?
      this.cacheIndex.set(key, cacheItem);
      await this.saveCacheIndex();
      
      console.info('[ImageCacheManager] Image cached:', key);
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageCacheManager] Cache image failed: ' + errorErr.message);
    }
  }

  /**
   * 濡偓閺屻儳绱︾€涙ê銇囩亸?
   */
  private async checkCacheSize(newFileSize: number): Promise<void> {
    let totalSize = 0;
    const items = Array.from(this.cacheIndex.values());
    for (let i = 0; i < items.length; i++) {
      totalSize += items[i].size;
    }
    
    // 婵″倹鐏夐崝鐘辩瑐閺傜増鏋冩禒鎯扮Т鏉╁洣绗傞梽鎰剁礉濞撳懐鎮婇弮褏绱︾€?
    if (totalSize + newFileSize > this.cacheConfig.maxSize) {
      await this.cleanOldCache(totalSize + newFileSize - this.cacheConfig.maxSize);
    }
  }

  /**
   * 濞撳懐鎮婇弮褏绱︾€?
   */
  private async cleanOldCache(bytesToFree: number): Promise<void> {
    const items = Array.from(this.cacheIndex.values())
      .slice()
      .sort((a, b) => a.lastAccessTime - b.lastAccessTime);

    let freed = 0;
    for (const item of items) {
      if (freed >= bytesToFree) break;

      try {
        if (fileIo.accessSync(item.cachePath)) {
          fileIo.unlinkSync(item.cachePath);
        }
        this.cacheIndex.delete(item.key);
        freed += item.size;
      } catch (error) {
        const err = error as Error;
        const errorErr = error as Error;
        console.error('[ImageCacheManager] Delete cache file failed: ' + errorErr.message);
      }
    }

    await this.saveCacheIndex();
    console.info('[ImageCacheManager] Cleaned cache, freed: ' + freed + ' bytes');
  }

  /**
   * 濞撳懐鎮婃潻鍥ㄦ埂缂傛挸鐡?
   */
  private async cleanExpiredCache(): Promise<void> {
    const now = Date.now();
    const toDelete: string[] = [];
    
    const cacheKeys = Array.from(this.cacheIndex.keys());
    for (let i = 0; i < cacheKeys.length; i++) {
      const key = cacheKeys[i];
      const item = this.cacheIndex.get(key)!;
      if (now - item.createTime > this.cacheConfig.expiryTime) {
        toDelete.push(key);
      }
    }
    
    for (const key of toDelete) {
      const item = this.cacheIndex.get(key);
      if (item) {
        try {
          if (fileIo.accessSync(item.cachePath)) {
            fileIo.unlinkSync(item.cachePath);
          }
          this.cacheIndex.delete(key);
        } catch (error) {
          const err = error as Error;
          const errorErr = error as Error;
          console.error('[ImageCacheManager] Delete expired cache failed: ' + errorErr.message);
        }
      }
    }

    if (toDelete.length > 0) {
      await this.saveCacheIndex();
      console.info('[ImageCacheManager] Cleaned expired cache: ' + toDelete.length + ' items');
    }
  }

  /**
   * 濞撳懐鈹栭幍鈧張澶岀处鐎?
   */
  async clearCache(): Promise<void> {
    try {
      const cacheItems = Array.from(this.cacheIndex.values());
      for (let i = 0; i < cacheItems.length; i++) {
        const item = cacheItems[i];
        try {
          if (fileIo.accessSync(item.cachePath)) {
            fileIo.unlinkSync(item.cachePath);
          }
        } catch (error) {
          const err = error as Error;
          const errorErr = error as Error;
          console.error('[ImageCacheManager] Delete cache file failed: ' + errorErr.message);
        }
      }

      this.cacheIndex.clear();
      this.memoryCache.clear();
      await this.saveCacheIndex();

      console.info('[ImageCacheManager] Cache cleared');
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageCacheManager] Clear cache failed: ' + errorErr.message);
    }
  }

  /**
   * 閼惧嘲褰囩紓鎾崇摠婢堆冪毈
   */
  getCacheSize(): number {
    let totalSize = 0;
    const sizeItems = Array.from(this.cacheIndex.values());
    for (let i = 0; i < sizeItems.length; i++) {
      totalSize += sizeItems[i].size;
    }
    return totalSize;
  }

  /**
   * 閼惧嘲褰囩紓鎾崇摠妞よ鏆熼柌?
   */
  getCacheCount(): number {
    return this.cacheIndex.size;
  }

  /**
   * 鐠佸墽鐤嗛張鈧径褏绱︾€涙ê銇囩亸?
   */
  async setMaxCacheSize(size: number): Promise<void> {
    this.cacheConfig.maxSize = size;
    preferenceManager.setNumber('image_cache_max_size', size);
    await this.checkCacheSize(0);
  }

  /**
   * 鐠佸墽鐤嗙紓鎾崇摠鏉╁洦婀￠弮鍫曟？
   */
  async setCacheExpiryTime(time: number): Promise<void> {
    this.cacheConfig.expiryTime = time;
    preferenceManager.setNumber('image_cache_expiry', time);
    await this.cleanExpiredCache();
  }
}

export const imageCacheManager = ImageCacheManager.getInstance();
export default imageCacheManager;
