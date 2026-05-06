import { logger } from '../../../utils/Logger';
/**
 * Share Kit Service - Sharing Service
 * 分享服务 - 使用 HarmonyOS ShareKit 实现真实分享功能
 * 
 * 支持分享文本、图片、文件等到其他应用
 * Using HarmonyOS ShareKit for real sharing functionality
 *
 * @since 3.0.0
 */

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { shareExtension, ShareParams, ShareResult } from '@kit.ShareKit';

const DOMAIN = 0xFF06;

/**
 * 分享类型枚举
 */
export enum ShareType {
  /** 纯文本 */
  TEXT = 'text',
  /** 图片 */
  IMAGE = 'image',
  /** 图文混合 */
  IMAGE_AND_TEXT = 'image_and_text',
  /** 文件 */
  FILE = 'file',
  /** 多个文件 */
  MULTIPLE_FILES = 'multiple_files'
}

/**
 * 分享数据接口
 */
export interface ShareData {
  /** 分享类型 */
  type: ShareType;
  /** 分享的文本内容 */
  text?: string;
  /** 分享标题 */
  title?: string;
  /** 图片URI数组 */
  imageUris?: string[];
  /** 文件URI数组 */
  fileUris?: string[];
  /** 指定分享到特定应用包名 */
  targetPackage?: string;
}

/**
 * 分享结果接口
 */
export interface ShareResultData {
  /** 是否成功 */
  success: boolean;
  /** 分享到的目标应用 */
  targetApp?: string;
  /** 错误信息 */
  error?: string;
}

/**
 * 分享选项接口
 */
export interface ShareOptions {
  /** 分享面板标题 */
  panelTitle?: string;
  /** 分享面板描述 */
  panelDescription?: string;
  /** 是否显示预览 */
  showPreview?: boolean;
}

/**
 * Share Kit 服务类
 */
class ShareKitService {
  /** 单例实例 */
  private static instance: ShareKitService;

  /** 上下文 */
  private context: common.Context | null = null;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): ShareKitService {
    if (!ShareKitService.instance) {
      ShareKitService.instance = new ShareKitService();
    }
    return ShareKitService.instance;
  }

  /**
   * 初始化ShareKit服务
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'ShareKit', 'Initializing...');
      this.context = context;

      this.isInitialized = true;
      hilog.info(DOMAIN, 'ShareKit', 'Initialized successfully with ShareKit');
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Init failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 分享功能 ====================

  /**
   * 分享文本
   */
  async shareText(text: string, title?: string, options?: ShareOptions): Promise<ShareResultData> {
    try {
      if (!this.isReady()) {
        throw new Error('ShareKit service not initialized');
      }

      hilog.info(DOMAIN, 'ShareKit', 'Sharing text: %{public}s', text.substring(0, 50));

      const shareParams: ShareParams = {
        text: text,
        title: title || '分享'
      };

      const result: ShareResult = await shareExtension.share(this.context!, shareParams);
      
      hilog.info(DOMAIN, 'ShareKit', 'Share text completed, result: %{public}s', result.success ? 'success' : 'failed');
      
      return {
        success: result.success,
        targetApp: result.targetPackage,
        error: result.errorCode ? `Error code: ${result.errorCode}` : undefined
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Share text failed: %{public}s', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 分享图片
   */
  async shareImage(imageUri: string, text?: string, options?: ShareOptions): Promise<ShareResultData> {
    try {
      if (!this.isReady()) {
        throw new Error('ShareKit service not initialized');
      }

      hilog.info(DOMAIN, 'ShareKit', 'Sharing image: %{public}s', imageUri);

      const shareParams: ShareParams = {
        uris: [imageUri],
        text: text,
        title: options?.panelTitle || '分享图片'
      };

      const result: ShareResult = await shareExtension.share(this.context!, shareParams);
      
      hilog.info(DOMAIN, 'ShareKit', 'Share image completed');
      
      return {
        success: result.success,
        targetApp: result.targetPackage,
        error: result.errorCode ? `Error code: ${result.errorCode}` : undefined
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Share image failed: %{public}s', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 分享图文混合
   */
  async shareImageAndText(imageUris: string[], text: string, options?: ShareOptions): Promise<ShareResultData> {
    try {
      if (!this.isReady()) {
        throw new Error('ShareKit service not initialized');
      }

      hilog.info(DOMAIN, 'ShareKit', 'Sharing image and text, images count: %{public}d', imageUris.length);

      const shareParams: ShareParams = {
        uris: imageUris,
        text: text,
        title: options?.panelTitle || '分享'
      };

      const result: ShareResult = await shareExtension.share(this.context!, shareParams);
      
      hilog.info(DOMAIN, 'ShareKit', 'Share image and text completed');
      
      return {
        success: result.success,
        targetApp: result.targetPackage,
        error: result.errorCode ? `Error code: ${result.errorCode}` : undefined
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Share image and text failed: %{public}s', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 分享文件
   */
  async shareFile(fileUri: string, text?: string, options?: ShareOptions): Promise<ShareResultData> {
    try {
      if (!this.isReady()) {
        throw new Error('ShareKit service not initialized');
      }

      hilog.info(DOMAIN, 'ShareKit', 'Sharing file: %{public}s', fileUri);

      const shareParams: ShareParams = {
        uris: [fileUri],
        text: text,
        title: options?.panelTitle || '分享文件'
      };

      const result: ShareResult = await shareExtension.share(this.context!, shareParams);
      
      hilog.info(DOMAIN, 'ShareKit', 'Share file completed');
      
      return {
        success: result.success,
        targetApp: result.targetPackage,
        error: result.errorCode ? `Error code: ${result.errorCode}` : undefined
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Share file failed: %{public}s', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 分享多个文件
   */
  async shareMultipleFiles(fileUris: string[], text?: string, options?: ShareOptions): Promise<ShareResultData> {
    try {
      if (!this.isReady()) {
        throw new Error('ShareKit service not initialized');
      }

      hilog.info(DOMAIN, 'ShareKit', 'Sharing multiple files, count: %{public}d', fileUris.length);

      const shareParams: ShareParams = {
        uris: fileUris,
        text: text,
        title: options?.panelTitle || '分享文件'
      };

      const result: ShareResult = await shareExtension.share(this.context!, shareParams);
      
      hilog.info(DOMAIN, 'ShareKit', 'Share multiple files completed');
      
      return {
        success: result.success,
        targetApp: result.targetPackage,
        error: result.errorCode ? `Error code: ${result.errorCode}` : undefined
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'ShareKit', 'Share multiple files failed: %{public}s', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 通用分享方法
   */
  async share(data: ShareData, options?: ShareOptions): Promise<ShareResultData> {
    switch (data.type) {
      case ShareType.TEXT:
        return this.shareText(data.text || '', data.title, options);
      case ShareType.IMAGE: {
        const firstImage = data.imageUris !== undefined && data.imageUris.length > 0 ? data.imageUris[0] : '';
        return this.shareImage(firstImage, data.text, options);
      }
      case ShareType.IMAGE_AND_TEXT:
        return this.shareImageAndText(data.imageUris || [], data.text || '', options);
      case ShareType.FILE: {
        const firstFile = data.fileUris !== undefined && data.fileUris.length > 0 ? data.fileUris[0] : '';
        return this.shareFile(firstFile, data.text, options);
      }
      case ShareType.MULTIPLE_FILES:
        return this.shareMultipleFiles(data.fileUris || [], data.text, options);
      default:
        return { success: false, error: 'Unsupported share type' };
    }
  }

  // ==================== 资源释放 ====================

  /**
   * 释放资源
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    hilog.info(DOMAIN, 'ShareKit', 'Released');
  }
}

// 导出单例
const shareKitService: ShareKitService = ShareKitService.getInstance();
export { shareKitService, shareKitService as default };
