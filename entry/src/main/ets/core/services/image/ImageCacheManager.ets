import { logger } from '../../../utils/Logger';
/**
 * Image Cache Manager - Manage image caching
 * 图片缓存管理器 - 管理图片缓存
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { image } from '@kit.ImageKit';
import { MS_PER_DAY } from '../../constants/TimeConstants';

/**
 * Cache configuration interface
 * 缓存配置接口
 */
export interface CacheConfig {
  /** Maximum cache size in bytes */
  maxSize: number;
  /** Cache directory path */
  cacheDir: string;
  /** Cache expiry time in milliseconds */
  expiryTime: number;
}

/**
 * Cache item interface
 * 缓存项接口
 */
export interface CacheItem {
  /** Source image path */
  sourcePath: string;
  /** Cached file path */
  cachePath: string;
  /** File size in bytes */
  size: number;
  /** Creation timestamp */
  createTime: number;
  /** Last access timestamp */
  lastAccessTime: number;
  /** Cache key */
  key: string;
}

/**
 * Image scaling options
 * 图片缩放选项
 */
export interface ImageScaleOptions {
  width?: number;
  height?: number;
}

/**
 * Image Cache Manager class
 * 图片缓存管理器类
 */
class ImageCacheManager {
  private static instance: ImageCacheManager;
  private context: common.Context | null = null;
  private cacheConfig: CacheConfig = {
    maxSize: 500 * 1024 * 1024, // 500MB
    cacheDir: '',
    expiryTime: 7 * MS_PER_DAY // 7 days
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
   * Initialize cache manager
   * 初始化缓存管理器
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    
    // Get cache directory
    const cacheDir = context.cacheDir;
    this.cacheConfig.cacheDir = cacheDir + '/image_cache';
    
    // Create cache directory if not exists
    try {
      if (!fileIo.accessSync(this.cacheConfig.cacheDir)) {
        fileIo.mkdirSync(this.cacheConfig.cacheDir);
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageCacheManager] Create cache dir failed:', err.message);
    }
    
    // Load cache index
    await this.loadCacheIndex();
    
    // Clean expired cache
    await this.cleanExpiredCache();
  }

  /**
   * Load cache index from storage
   * 从存储加载缓存索引
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
      logger.error('[ImageCacheManager] Load cache index failed:', err.message);
    }
  }

  /**
   * Save cache index to storage
   * 保存缓存索引到存储
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
      logger.error('[ImageCacheManager] Save cache index failed:', err.message);
    }
  }

  /**
   * Generate cache key
   * 生成缓存键
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
    // Hash the key
    return this.hashString(key);
  }

  /**
   * Hash string function
   * 字符串哈希函数
   */
  private hashString(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(36);
  }

  /**
   * Get cached image path
   * 获取缓存图片路径
   */
  getCachedImagePath(sourcePath: string, options?: ImageScaleOptions): string | null {
    const key = this.generateCacheKey(sourcePath, options);
    const item = this.cacheIndex.get(key);
    
    if (!item) return null;
    
    // Check if cache is expired
    const now = Date.now();
    if (now - item.createTime > this.cacheConfig.expiryTime) {
      return null;
    }
    
    // Check if cache file exists
    try {
      if (fileIo.accessSync(item.cachePath)) {
        // Update last access time
        item.lastAccessTime = now;
        this.cacheIndex.set(key, item);
        return item.cachePath;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[ImageCacheManager] Access cache file failed:', message);
      return null;
    }
    
    return null;
  }

  /**
   * Cache image
   * 缓存图片
   */
  async cacheImage(sourcePath: string, cachePath: string, options?: ImageScaleOptions): Promise<void> {
    const key = this.generateCacheKey(sourcePath, options);
    
    try {
      // Get file stats
      const stat = fileIo.statSync(cachePath);
      
      // Check cache size and clean if needed
      await this.checkCacheSize(stat.size);
      
      // Create cache item
      const cacheItem: CacheItem = {
        sourcePath,
        cachePath,
        size: stat.size,
        createTime: Date.now(),
        lastAccessTime: Date.now(),
        key
      };
      
      // Add to cache index
      this.cacheIndex.set(key, cacheItem);
      await this.saveCacheIndex();
      
      logger.info('[ImageCacheManager] Image cached:', key);
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageCacheManager] Cache image failed:', err.message);
    }
  }

  /**
   * Check cache size and clean if needed
   * 检查缓存大小并在需要时清理
   */
  private async checkCacheSize(newFileSize: number): Promise<void> {
    let totalSize = 0;
    const items = Array.from(this.cacheIndex.values());
    for (let i = 0; i < items.length; i++) {
      totalSize += items[i].size;
    }
    
    // If cache exceeds limit, clean old cache
    if (totalSize + newFileSize > this.cacheConfig.maxSize) {
      await this.cleanOldCache(totalSize + newFileSize - this.cacheConfig.maxSize);
    }
  }

  /**
   * Clean old cache based on LRU
   * 基于LRU清理旧缓存
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
        logger.error('[ImageCacheManager] Delete cache file failed:', err.message);
      }
    }

    await this.saveCacheIndex();
    logger.info('[ImageCacheManager] Cleaned cache, freed:', freed, 'bytes');
  }

  /**
   * Clean expired cache
   * 清理过期缓存
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
          logger.error('[ImageCacheManager] Delete expired cache failed:', err.message);
        }
      }
    }

    if (toDelete.length > 0) {
      await this.saveCacheIndex();
      logger.info('[ImageCacheManager] Cleaned expired cache:', toDelete.length, 'items');
    }
  }

  /**
   * Clear all cache
   * 清除所有缓存
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
          logger.error('[ImageCacheManager] Delete cache file failed:', err.message);
        }
      }

      this.cacheIndex.clear();
      this.memoryCache.clear();
      await this.saveCacheIndex();

      logger.info('[ImageCacheManager] Cache cleared');
    } catch (error) {
      const err = error as Error;
      logger.error('[ImageCacheManager] Clear cache failed:', err.message);
    }
  }

  /**
   * Get total cache size
   * 获取总缓存大小
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
   * Get cache item count
   * 获取缓存项数量
   */
  getCacheCount(): number {
    return this.cacheIndex.size;
  }

  /**
   * Set maximum cache size
   * 设置最大缓存大小
   */
  async setMaxCacheSize(size: number): Promise<void> {
    this.cacheConfig.maxSize = size;
    preferenceManager.setNumber('image_cache_max_size', size);
    await this.checkCacheSize(0);
  }

  /**
   * Set cache expiry time
   * 设置缓存过期时间
   */
  async setCacheExpiryTime(time: number): Promise<void> {
    this.cacheConfig.expiryTime = time;
    preferenceManager.setNumber('image_cache_expiry', time);
    await this.cleanExpiredCache();
  }
}

export const imageCacheManager = ImageCacheManager.getInstance();
export default imageCacheManager;
