import { logger } from '../../../utils/Logger';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferenceManager } from '../../utils/PreferenceManager';

interface ImageCacheItem {
  path: string;
  size: number;
  createTime: number;
}

class ImageLoaderService {
  private static instance: ImageLoaderService;
  private context: common.Context | null = null;
  private cacheDir: string = '';
  private cacheMap: Map<string, ImageCacheItem> = new Map();
  private maxCacheSize: number = 200 * 1024 * 1024;

  private constructor() {}

  static getInstance(): ImageLoaderService {
    if (!ImageLoaderService.instance) {
      ImageLoaderService.instance = new ImageLoaderService();
    }
    return ImageLoaderService.instance;
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    this.cacheDir = context.cacheDir + '/image_viewer';

    try {
      if (!fileIo.accessSync(this.cacheDir)) {
        fileIo.mkdirSync(this.cacheDir);
      }
    } catch (error) {
      logger.error('Create cache dir failed:', error);
    }

    await this.loadCacheIndex();
  }

  private async loadCacheIndex(): Promise<void> {
    try {
      const indexJson = preferenceManager.getString('image_viewer_cache_index', '');
      if (indexJson && indexJson.length > 0) {
        const index = JSON.parse(indexJson) as Record<string, ImageCacheItem>;
        this.cacheMap = new Map(Object.entries(index));
      }
    } catch (error) {
      logger.error('LoadCacheIndex failed:', error);
    }
  }

  private async saveCacheIndex(): Promise<void> {
    try {
      const indexObj: Record<string, ImageCacheItem> = {};
      const keys = Array.from(this.cacheMap.keys());
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const item = this.cacheMap.get(key);
        if (item) {
          indexObj[key] = item;
        }
      }
      const indexJson = JSON.stringify(indexObj);
      preferenceManager.setString('image_viewer_cache_index', indexJson);
    } catch (error) {
      logger.error('SaveCacheIndex failed:', error);
    }
  }

  isCached(imagePath: string): boolean {
    const item = this.cacheMap.get(imagePath);
    if (!item) return false;
    return fileIo.accessSync(item.path);
  }

  getCachedImagePath(imagePath: string): string | null {
    const item = this.cacheMap.get(imagePath);
    if (item && fileIo.accessSync(item.path)) {
      return item.path;
    }
    return null;
  }

  async cacheImage(sourcePath: string, cachePath: string): Promise<void> {
    try {
      const stat = fileIo.statSync(cachePath);
      await this.checkCacheSize(stat.size);

      const cacheItem: ImageCacheItem = {
        path: cachePath,
        size: stat.size,
        createTime: Date.now()
      };

      this.cacheMap.set(sourcePath, cacheItem);
      await this.saveCacheIndex();
    } catch (error) {
      logger.error('CacheImage failed:', error);
    }
  }

  private async checkCacheSize(newFileSize: number): Promise<void> {
    let totalSize = 0;
    const items = Array.from(this.cacheMap.values());
    for (let i = 0; i < items.length; i++) {
      totalSize += items[i].size;
    }

    if (totalSize + newFileSize > this.maxCacheSize) {
      await this.cleanOldCache(totalSize + newFileSize - this.maxCacheSize);
    }
  }

  private async cleanOldCache(bytesToFree: number): Promise<void> {
    const items = Array.from(this.cacheMap.values())
      .slice()
      .sort((a, b) => a.createTime - b.createTime);

    let freed = 0;
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (freed >= bytesToFree) break;

      try {
        if (fileIo.accessSync(item.path)) {
          fileIo.unlinkSync(item.path);
        }
        for (const entry of this.cacheMap.entries()) {
          const key = entry[0];
          const value = entry[1];
          if (value.path === item.path) {
            this.cacheMap.delete(key);
            break;
          }
        }
        freed += item.size;
      } catch (error) {
        logger.error('Delete cache file failed:', item.path);
      }
    }

    await this.saveCacheIndex();
  }

  async clearCache(): Promise<void> {
    try {
      const cacheItems = Array.from(this.cacheMap.values());
      for (let i = 0; i < cacheItems.length; i++) {
        const item = cacheItems[i];
        try {
          if (fileIo.accessSync(item.path)) {
            fileIo.unlinkSync(item.path);
          }
        } catch (error) {
          logger.error('Delete cache file failed:', item.path);
        }
      }

      this.cacheMap.clear();
      await this.saveCacheIndex();
    } catch (error) {
      logger.error('ClearCache failed:', error);
    }
  }

  getCacheSize(): number {
    let totalSize = 0;
    const sizeItems = Array.from(this.cacheMap.values());
    for (let i = 0; i < sizeItems.length; i++) {
      totalSize += sizeItems[i].size;
    }
    return totalSize;
  }

  async preloadImage(imagePath: string): Promise<void> {
    if (this.isCached(imagePath)) {
      return;
    }

    try {
      if (fileIo.accessSync(imagePath)) {
        const pathParts = imagePath.split('/');
        let fileName = Date.now().toString();
        if (pathParts.length > 0) {
          fileName = pathParts[pathParts.length - 1];
        }
        const cachePath = this.cacheDir + '/' + fileName;
        logger.info('Preload image:', imagePath);
      }
    } catch (error) {
      logger.error('PreloadImage failed:', error);
    }
  }
}

export const imageLoaderService = ImageLoaderService.getInstance();
export default imageLoaderService;