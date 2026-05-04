import { logger } from '../../../utils/Logger';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

export class ImageCacheService {
  private static instance: ImageCacheService;
  private cacheDir: string = '';
  private isInitialized: boolean = false;

  private constructor() {}

  static getInstance(): ImageCacheService {
    if (!ImageCacheService.instance) {
      ImageCacheService.instance = new ImageCacheService();
    }
    return ImageCacheService.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;
    try {
      this.cacheDir = context.cacheDir + '/image_cache/';
      if (!(await this.access(this.cacheDir))) {
        await this.mkdir(this.cacheDir);
      }
      this.isInitialized = true;
    } catch (error) {
      logger.error('ImageCache init failed:', error);
    }
  }

  async getImage(url: string): Promise<string> {
    if (!this.isInitialized) return url;

    const cachedPath = await this.getCachedPath(url);
    if (cachedPath !== null && await this.access(cachedPath)) {
      return `file://${cachedPath}`;
    }

    return await this.downloadAndCache(url);
  }

  private async downloadAndCache(url: string): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 200 && response.result) {
        let filePath = this.getNewCachePath(url);
        const data = response.result as ArrayBuffer;
        const uint8 = new Uint8Array(data);

        const fd = await fileIo.open(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
        try {
          await fileIo.write(fd.fd, uint8);
        } finally {
          await fileIo.close(fd);
        }
        return `file://${filePath}`;
      }
    } catch (error) {
      logger.warn('ImageCache download failed:', url);
    } finally {
      httpRequest.destroy();
    }
    return url;
  }

  private async getCachedPath(url: string): Promise<string | null> {
    const hash = this.hashUrl(url);
    const path = this.cacheDir + hash;
    return await this.access(path) ? path : null;
  }

  private getNewCachePath(url: string): string {
    return this.cacheDir + this.hashUrl(url);
  }

  private hashUrl(url: string): string {
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      hash = ((hash << 5) - hash) + url.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash).toString(36) + '.jpg';
  }

  async getCacheSize(): Promise<number> {
    let totalSize = 0;
    try {
      if (!(await this.access(this.cacheDir))) {
        return 0;
      }

      const entries = await fileIo.listFile(this.cacheDir);
      for (const entry of entries) {
        const filePath = this.cacheDir + entry;
        if (await this.access(filePath)) {
          const stat = await fileIo.stat(filePath);
          totalSize += stat.size;
        }
      }
    } catch (error) {
      logger.error('GetCacheSize failed:', error);
    }
    return totalSize;
  }

  async getCacheSizeFormatted(): Promise<string> {
    const size = await this.getCacheSize();
    if (size < 1024) {
      return size + ' B';
    } else if (size < 1024 * 1024) {
      return (size / 1024).toFixed(2) + ' KB';
    } else {
      return (size / (1024 * 1024)).toFixed(2) + ' MB';
    }
  }

  async clearCache(): Promise<void> {
    try {
      if (!(await this.access(this.cacheDir))) {
        return;
      }

      const entries = await fileIo.listFile(this.cacheDir);
      let deletedCount = 0;

      for (const entry of entries) {
        const filePath = this.cacheDir + entry;
        try {
          if (await this.access(filePath)) {
            await fileIo.unlink(filePath);
            deletedCount++;
          }
        } catch (error) {
          logger.error('Delete file failed:', filePath);
        }
      }

      try {
        await fileIo.rmdir(this.cacheDir);
        await this.mkdir(this.cacheDir);
      } catch (error) {
        logger.error('Recreate cache dir failed:', error);
      }
    } catch (error) {
      logger.error('ClearCache failed:', error);
    }
  }

  private async access(path: string): Promise<boolean> {
    try {
      await fileIo.access(path);
      return true;
    } catch {
      return false;
    }
  }

  private async mkdir(path: string): Promise<void> {
    try {
      await fileIo.mkdir(path);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('ImageCache mkdir failed:', message);
    }
  }
}

export const imageCacheService = ImageCacheService.getInstance();
export default imageCacheService;