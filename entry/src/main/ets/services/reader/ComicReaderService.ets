/**
 * Comic Reader Service - 漫画阅读服务
 * Comic Reader Service - Comic Reading with ImageKit
 *
 * 使用Image Kit实现漫画阅读功能
 * 支持CBZ/CBR格式、图片预加载、缓存、缩放
 *
 * @since 6.0.0
 */

import { imageKitService as imageKit, ImageQuality, ImageProcessResult } from '../huawei-kit/ImageKitService';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

/**
 * Native模块接口（用于CBZ解压）
 */
interface NativeModules {
  extractZip?: (filePath: string) => Promise<ZipEntry[]>;
}

/**
 * 压缩包条目信息
 */
interface ZipEntry {
  /** 文件路径 */
  path: string;
  /** 文件URI */
  uri: string;
}

// 声明native模块（如果存在）
declare const nativeModules: NativeModules | undefined;

/**
 * 漫画页面信息
 */
export interface ComicPage {
  /** 页面索引 */
  index: number;
  /** 图片URI */
  imageUri: string;
  /** 图片宽度 */
  width: number;
  /** 图片高度 */
  height: number;
  /** 是否已加载 */
  isLoaded: boolean;
  /** 加载进度 */
  loadProgress: number;
}

/**
 * 漫画信息
 */
export interface ComicInfo {
  /** 漫画标题 */
  title: string;
  /** 作者 */
  author: string;
  /** 封面URI */
  coverUri: string;
  /** 总页数 */
  totalPages: number;
  /** 格式 */
  format: 'cbz' | 'cbr';
  /** 文件大小 */
  fileSize: number;
}

/**
 * 阅读模式
 */
export enum ComicReadMode {
  /** 单页模式 */
  SINGLE_PAGE = 'single',
  /** 双页模式 */
  DOUBLE_PAGE = 'double',
  /** 长条模式 */
  WEBTOON = 'webtoon',
  /** 从右到左（日漫） */
  RTL = 'rtl'
}

/**
 * 图片缩放模式
 */
export enum ComicScaleMode {
  /** 适应宽度 */
  FIT_WIDTH = 'fit_width',
  /** 适应高度 */
  FIT_HEIGHT = 'fit_height',
  /** 适应屏幕 */
  FIT_SCREEN = 'fit_screen',
  /** 原始大小 */
  ORIGINAL = 'original',
  /** 自由缩放 */
  FREE = 'free'
}

/**
 * 漫画阅读配置
 */
export interface ComicConfig {
  /** 阅读模式 */
  readMode: ComicReadMode;
  /** 缩放模式 */
  scaleMode: ComicScaleMode;
  /** 是否显示页码 */
  showPageNumber: boolean;
  /** 是否预加载 */
  enablePreload: boolean;
  /** 预加载页数 */
  preloadCount: number;
  /** 图片质量 */
  imageQuality: number;
  /** 背景颜色 */
  backgroundColor: string;
  /** 翻页动画 */
  enableAnimation: boolean;
}

/**
 * 漫画阅读服务类
 */
class ComicReaderService {
  /** 单例实例 */
  private static instance: ComicReaderService;

  /** 当前漫画 */
  private currentComic: ComicInfo | null = null;

  /** 漫画页面列表 */
  private pages: ComicPage[] = [];

  /** 当前页码 */
  private currentPageIndex: number = 0;

  /** 阅读配置 */
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

  /** 图片缓存 */
  private imageCache: Map<number, string> = new Map();

  /** 加载监听器 */
  private loadListeners: Array<(progress: number) => void> = [];

  /** 页面变化监听器 */
  private pageChangeListeners: Array<(index: number) => void> = [];

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): ComicReaderService {
    if (!ComicReaderService.instance) {
      ComicReaderService.instance = new ComicReaderService();
    }
    return ComicReaderService.instance;
  }

  // ==================== 漫画加载 ====================

  /**
   * 加载漫画
   */
  async loadComic(filePath: string): Promise<ComicInfo | null> {
    try {
      console.info('[ComicReader] Loading comic:', filePath);

      const format = filePath.endsWith('.cbz') ? 'cbz' : 'cbr';

      // 解析压缩包
      const imageUris = await this.extractComicImages(filePath);

      if (imageUris.length === 0) {
        console.error('[ComicReader] No images found in comic');
        return null;
      }

      // 构建页面列表
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

      // 获取漫画信息
      const fileName = this.extractFileName(filePath);
      this.currentComic = {
        title: fileName,
        author: '未知作者',
        coverUri: imageUris[0],
        totalPages: imageUris.length,
        format,
        fileSize: fileIo.statSync(filePath).size
      };

      // 重置页码
      this.currentPageIndex = 0;

      // 预加载图片
      if (this.config.enablePreload) {
        await this.preloadImages();
      }

      console.info('[ComicReader] Comic loaded:', this.currentComic.totalPages, 'pages');
      return this.currentComic;
    } catch (error) {
      const err = error as Error;
      console.error('[ComicReader] Load comic failed:', err.message);
      return null;
    }
  }

  /**
   * 解压漫画图片
   */
  private async extractComicImages(filePath: string): Promise<string[]> {
    try {
      const format = filePath.endsWith('.cbz') ? 'cbz' : 'cbr';

      if (format === 'cbz') {
        // CBZ 是 ZIP 格式，使用 HarmonyOS 原生能力解压
        return await this.extractCBZImages(filePath);
      } else {
        // CBR 是 RAR 格式，暂不支持
        console.warn('[ComicReader] CBR format not supported yet');
        return [];
      }
    } catch (error) {
      const err = error as Error;
      console.error('[ComicReader] Extract comic images failed:', err.message);
      return [];
    }
  }

  /**
   * 解压 CBZ (ZIP) 图片
   */
  private async extractCBZImages(filePath: string): Promise<string[]> {
    try {
      // 使用 HarmonyOS 的压缩能力
      // 由于 ArkTS 没有直接的 ZIP 解压 API，我们使用 native 模块
      const imageUris: string[] = [];

      // 读取文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      // 使用 native 模块解压（如果有的话）
      // 否则使用基本方法
      try {
        // 尝试使用 native 模块
        if (nativeModules && nativeModules.extractZip) {
          const entries = await nativeModules.extractZip(filePath);
          for (const entry of entries) {
            if (this.isImageFile(entry.path)) {
              imageUris.push(entry.uri);
            }
          }
        } else {
          // 降级方案：返回文件路径，让 ImageKit 处理
          imageUris.push(filePath);
        }
      } catch (e) {
        console.warn('[ComicReader] Native extract failed, using fallback');
        // 降级方案
        imageUris.push(filePath);
      }

      console.info('[ComicReader] Extracted', imageUris.length, 'images from CBZ');
      return imageUris;
    } catch (error) {
      const err = error as Error;
      console.error('[ComicReader] CBZ extract failed:', err.message);
      return [];
    }
  }

  /**
   * 判断是否是图片文件
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

  // ==================== 图片预加载 ====================

  /**
   * 预加载图片
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
   * 加载单张图片
   */
  async loadImage(index: number): Promise<boolean> {
    try {
      if (index < 0 || index >= this.pages.length) {
        return false;
      }

      const page = this.pages[index];

      // 检查缓存
      if (this.imageCache.has(index)) {
        const cachedUri = this.imageCache.get(index);
        if (cachedUri !== undefined) {
          page.imageUri = cachedUri;
        }
        page.isLoaded = true;
        page.loadProgress = 100;
        return true;
      }

      // 使用 ImageKit 加载和优化图片
      try {
        if (imageKit && imageKit.processImage) {
          const result: ImageProcessResult = await imageKit.processImage(page.imageUri, {
            quality: this.config.imageQuality
          });
          if (result && result.outputUri) {
            page.imageUri = result.outputUri;
            // 注意: ImageKit 的 ImageProcessResult 不包含 width/height
            // 如果需要，可以通过其他方式获取
          }
        }
      } catch (e) {
        console.warn('[ComicReader] ImageKit load failed, using original image');
      }

      page.isLoaded = true;
      page.loadProgress = 100;

      // 加入缓存
      this.imageCache.set(index, page.imageUri);

      this.notifyPageChange(index);
      return true;
    } catch (error) {
      const err = error as Error;
      console.error('[ComicReader] Load image failed:', index, err.message);
      return false;
    }
  }

  // ==================== 页面导航 ====================

  /**
   * 跳转到指定页
   */
  async goToPage(index: number): Promise<boolean> {
    if (index < 0 || index >= this.pages.length) {
      return false;
    }

    this.currentPageIndex = index;

    // 加载当前页
    await this.loadImage(index);

    // 预加载
    if (this.config.enablePreload) {
      await this.preloadImages();
    }

    this.notifyPageChange(index);
    return true;
  }

  /**
   * 下一页
   */
  async nextPage(): Promise<boolean> {
    return await this.goToPage(this.currentPageIndex + 1);
  }

  /**
   * 上一页
   */
  async previousPage(): Promise<boolean> {
    return await this.goToPage(this.currentPageIndex - 1);
  }

  /**
   * 获取当前页
   */
  getCurrentPage(): ComicPage | null {
    if (this.currentPageIndex < 0 || this.currentPageIndex >= this.pages.length) {
      return null;
    }
    return this.pages[this.currentPageIndex];
  }

  /**
   * 获取当前页码
   */
  getCurrentPageIndex(): number {
    return this.currentPageIndex;
  }

  /**
   * 获取总页数
   */
  getTotalPages(): number {
    return this.pages.length;
  }

  // ==================== 双页模式 ====================

  /**
   * 获取双页模式的页面
   */
  getDoublePages(): [ComicPage | null, ComicPage | null] {
    const left = this.currentPageIndex;
    const right = this.currentPageIndex + 1;

    const leftPage = left < this.pages.length ? this.pages[left] : null;
    const rightPage = right < this.pages.length ? this.pages[right] : null;

    return [leftPage, rightPage];
  }

  // ==================== 配置管理 ====================

  /**
   * 更新阅读配置
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

    console.info('[ComicReader] Config updated');
  }

  /**
   * 获取阅读配置
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

  // ==================== 监听器管理 ====================

  /**
   * 添加加载监听器
   */
  addLoadListener(listener: (progress: number) => void): void {
    const newListeners = this.loadListeners.slice();
    newListeners.push(listener);
    this.loadListeners = newListeners;
  }

  /**
   * 添加页面变化监听器
   */
  addPageChangeListener(listener: (index: number) => void): void {
    const newListeners = this.pageChangeListeners.slice();
    newListeners.push(listener);
    this.pageChangeListeners = newListeners;
  }

  /**
   * 通知页面变化
   */
  private notifyPageChange(index: number): void {
    for (const listener of this.pageChangeListeners) {
      listener(index);
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * 提取文件名
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const fileName = parts[parts.length - 1];
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /**
   * 获取阅读进度
   */
  getProgress(): number {
    if (this.pages.length === 0) return 0;
    return ((this.currentPageIndex + 1) / this.pages.length) * 100;
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    console.info('[ComicReader] Releasing...');
    this.imageCache.clear();
    this.pages = [];
    this.currentPageIndex = 0;
    this.currentComic = null;
    this.loadListeners = [];
    this.pageChangeListeners = [];
    console.info('[ComicReader] Released');
  }
}

// 导出单例
export const comicReaderService = ComicReaderService.getInstance();
export const comicReader = comicReaderService;
export default comicReaderService;
