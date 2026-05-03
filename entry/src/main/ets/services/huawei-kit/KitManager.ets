/**
 * Kit Manager - 统一Kit服务管理器
 * Kit Manager - Unified Kit Service Manager
 *
 * 集中管理所有Kit服务的初始化、配置和生命周期
 *
 * @since 2.0.0
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';
import { enhancedReaderKitService as enhancedReaderKit } from '../reader/EnhancedReaderKitService';
import { shareKitService } from './ShareKitService';
import { fileManagerKitService as fileManagerKit } from '../book/FileManagerKitService';
import { imageKitService as imageKit } from './ImageKitService';
import { audioKitService } from './AudioKitService';
import { collaborationKitService as collaborationKit } from '../reader/CollaborationKitService';
import { adsKitService } from './AdsKitService';

/**
 * Kit服务状态
 */
export enum KitServiceStatus {
  /** 未初始化 */
  NOT_INITIALIZED = 'not_initialized',
  /** 初始化中 */
  INITIALIZING = 'initializing',
  /** 已就绪 */
  READY = 'ready',
  /** 错误 */
  ERROR = 'error'
}

/**
 * Kit服务信息
 */
export interface KitServiceInfo {
  /** 服务名称 */
  name: string;
  /** 服务状态 */
  status: KitServiceStatus;
  /** 是否启用 */
  enabled: boolean;
  /** 错误信息 */
  error?: string;
  /** 初始化时间 */
  initTime?: number;
}

/**
 * Kit配置
 */
export interface KitConfig {
  /** 是否启用Reader Kit */
  enableReaderKit: boolean;
  /** 是否启用Share Kit */
  enableShareKit: boolean;
  /** 是否启用File Manager Kit */
  enableFileManagerKit: boolean;
  /** 是否启用Image Kit */
  enableImageKit: boolean;
  /** 是否启用Audio Kit */
  enableAudioKit: boolean;
  /** 是否启用Collaboration Kit */
  enableCollaborationKit: boolean;
  /** 是否启用Ads Kit */
  enableAdsKit: boolean;
}

/**
 * Kit管理器类
 */
export class KitManager {
  /** 单例实例 */
  private static instance: KitManager;

  /** 上下文 */
  private context: common.Context | null = null;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /** Kit配置 */
  private config: KitConfig = {
    enableReaderKit: true,
    enableShareKit: true,
    enableFileManagerKit: true,
    enableImageKit: true,
    enableAudioKit: true,
    enableCollaborationKit: true,
    enableAdsKit: false // 默认禁用广告，用户可手动启用
  };

  /** Kit服务信息列表 */
  private serviceInfoList: Map<string, KitServiceInfo> = new Map();

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): KitManager {
    if (!KitManager.instance) {
      KitManager.instance = new KitManager();
    }
    return KitManager.instance;
  }

  /**
   * 初始化所有Kit服务
   */
  async initAllKits(context: common.Context): Promise<boolean> {
    try {
      console.info('[KitManager] Initializing all kits...');
      this.context = context;

      const startTime = Date.now();
      let successCount = 0;
      let errorCount = 0;

      // 1. 初始化Reader Kit
      if (this.config.enableReaderKit) {
        await this.initKit('ReaderKit', async () => {
          return await enhancedReaderKit.init(context);
        });
        successCount++;
      }

      // 2. 初始化Share Kit
      if (this.config.enableShareKit) {
        await this.initKit('ShareKit', async () => {
          return await shareKitService.init(context);
        });
        successCount++;
      }

      // 3. 初始化File Manager Kit
      if (this.config.enableFileManagerKit) {
        await this.initKit('FileManagerKit', async () => {
          return await fileManagerKit.init(context);
        });
        successCount++;
      }

      // 4. 初始化Image Kit
      if (this.config.enableImageKit) {
        await this.initKit('ImageKit', async () => {
          return await imageKit.init(context);
        });
        successCount++;
      }

      // 5. 初始化Audio Kit
      if (this.config.enableAudioKit) {
        await this.initKit('AudioKit', async () => {
          return await audioKitService.init(context);
        });
        successCount++;
      }

      // 6. 初始化Collaboration Kit
      if (this.config.enableCollaborationKit) {
        await this.initKit('CollaborationKit', async () => {
          return await collaborationKit.init(context);
        });
        successCount++;
      }

      // 7. 初始化Ads Kit
      if (this.config.enableAdsKit) {
        await this.initKit('AdsKit', async () => {
          return await adsKitService.init(context);
        });
        successCount++;
      }

      const initTime = Date.now() - startTime;
      console.info(`[KitManager] All kits initialized: ${successCount} succeeded, ${errorCount} failed, time: ${initTime}ms`);

      this.isInitialized = true;
      return errorCount === 0;
    } catch (error) {
      console.error('[KitManager] Init all kits failed:', error);
      return false;
    }
  }

  /**
   * 初始化单个Kit服务
   */
  private async initKit(
    name: string,
    initFunc: () => Promise<boolean>
  ): Promise<void> {
    const serviceInfo: KitServiceInfo = {
      name: name,
      status: KitServiceStatus.INITIALIZING,
      enabled: true
    };

    try {
      console.info(`[KitManager] Initializing ${name}...`);
      const success = await initFunc();

      if (success) {
        serviceInfo.status = KitServiceStatus.READY;
        serviceInfo.initTime = Date.now();
        console.info(`[KitManager] ${name} initialized successfully`);
      } else {
        serviceInfo.status = KitServiceStatus.ERROR;
        serviceInfo.error = 'Initialization returned false';
        console.error(`[KitManager] ${name} initialization failed`);
      }
    } catch (error) {
      serviceInfo.status = KitServiceStatus.ERROR;
      const err = error as Error;
      serviceInfo.error = err.message || 'Unknown error';
      console.error(`[KitManager] ${name} initialization error:`, err.message);
    }

    this.serviceInfoList.set(name, serviceInfo);
  }

  /**
   * 检查所有Kit服务是否就绪
   */
  isReady(): boolean {
    if (!this.isInitialized) {
      return false;
    }

    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const info = entries[i][1];
      if (info.enabled && info.status !== KitServiceStatus.READY) {
        console.warn(`[KitManager] ${info.name} is not ready`);
        return false;
      }
    }

    return true;
  }

  /**
   * 获取Kit服务状态
   */
  getServiceStatus(name: string): KitServiceInfo | undefined {
    return this.serviceInfoList.get(name);
  }

  /**
   * 获取所有Kit服务状态
   */
  getAllServiceStatus(): KitServiceInfo[] {
    return Array.from(this.serviceInfoList.values());
  }

  /**
   * 获取就绪的Kit服务数量
   */
  getReadyServiceCount(): number {
    let count = 0;
    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const info = entries[i][1];
      if (info.status === KitServiceStatus.READY) {
        count++;
      }
    }
    return count;
  }

  /**
   * 获取启用的Kit服务数量
   */
  getEnabledServiceCount(): number {
    let count = 0;
    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const info = entries[i][1];
      if (info.enabled) {
        count++;
      }
    }
    return count;
  }

  // ==================== Kit服务访问 ====================

  /**
   * 获取Reader Kit服务
   */
  getReaderKit(): object {
    return enhancedReaderKit;
  }

  /**
   * 获取Share Kit服务
   */
  getShareKit(): object {
    return shareKitService;
  }

  /**
   * 获取File Manager Kit服务
   */
  getFileManagerKit(): object {
    return fileManagerKit;
  }

  /**
   * 获取Image Kit服务
   */
  getImageKit(): object {
    return imageKit;
  }

  /**
   * 获取Audio Kit服务
   */
  getAudioKit(): object {
    return audioKitService;
  }

  /**
   * 获取Collaboration Kit服务
   */
  getCollaborationKit(): object {
    return collaborationKit;
  }

  /**
   * 获取Ads Kit服务
   */
  getAdsKit(): object {
    return adsKitService;
  }

  // ==================== 配置管理 ====================

  /**
   * 加载配置
   */
  async loadConfig(): Promise<void> {
    try {
      const configJson = preferenceManager.getString('kit_config', '');
      if (configJson && configJson.length > 0) {
        const savedConfig = JSON.parse(configJson) as Partial<KitConfig>;
        if (savedConfig.enableReaderKit !== undefined) this.config.enableReaderKit = savedConfig.enableReaderKit;
        if (savedConfig.enableShareKit !== undefined) this.config.enableShareKit = savedConfig.enableShareKit;
        if (savedConfig.enableFileManagerKit !== undefined) this.config.enableFileManagerKit = savedConfig.enableFileManagerKit;
        if (savedConfig.enableImageKit !== undefined) this.config.enableImageKit = savedConfig.enableImageKit;
        if (savedConfig.enableAudioKit !== undefined) this.config.enableAudioKit = savedConfig.enableAudioKit;
        if (savedConfig.enableCollaborationKit !== undefined) this.config.enableCollaborationKit = savedConfig.enableCollaborationKit;
        if (savedConfig.enableAdsKit !== undefined) this.config.enableAdsKit = savedConfig.enableAdsKit;
      }
      console.info('[KitManager] Config loaded from preferences');
    } catch (error) {
      console.error('[KitManager] Load config failed:', error);
    }
  }

  /**
   * 保存配置
   */
  async saveConfig(): Promise<void> {
    try {
      const configJson = JSON.stringify({
        enableReaderKit: this.config.enableReaderKit,
        enableShareKit: this.config.enableShareKit,
        enableFileManagerKit: this.config.enableFileManagerKit,
        enableImageKit: this.config.enableImageKit,
        enableAudioKit: this.config.enableAudioKit,
        enableCollaborationKit: this.config.enableCollaborationKit,
        enableAdsKit: this.config.enableAdsKit
      });
      preferenceManager.setString('kit_config', configJson);
      console.info('[KitManager] Config saved to preferences');
    } catch (error) {
      console.error('[KitManager] Save config failed:', error);
    }
  }

  /**
   * 更新配置
   */
  async updateConfig(config: Partial<KitConfig>): Promise<void> {
    if (config.enableReaderKit !== undefined) { this.config.enableReaderKit = config.enableReaderKit; }
    if (config.enableShareKit !== undefined) { this.config.enableShareKit = config.enableShareKit; }
    if (config.enableFileManagerKit !== undefined) { this.config.enableFileManagerKit = config.enableFileManagerKit; }
    if (config.enableImageKit !== undefined) { this.config.enableImageKit = config.enableImageKit; }
    if (config.enableAudioKit !== undefined) { this.config.enableAudioKit = config.enableAudioKit; }
    if (config.enableCollaborationKit !== undefined) { this.config.enableCollaborationKit = config.enableCollaborationKit; }
    if (config.enableAdsKit !== undefined) { this.config.enableAdsKit = config.enableAdsKit; }

    await this.saveConfig();
    console.info('[KitManager] Config updated');
  }

  /**
   * 获取配置
   */
  getConfig(): KitConfig {
    const configCopy: KitConfig = {
      enableReaderKit: this.config.enableReaderKit,
      enableShareKit: this.config.enableShareKit,
      enableFileManagerKit: this.config.enableFileManagerKit,
      enableImageKit: this.config.enableImageKit,
      enableAudioKit: this.config.enableAudioKit,
      enableCollaborationKit: this.config.enableCollaborationKit,
      enableAdsKit: this.config.enableAdsKit
    };
    return configCopy;
  }

  /**
   * 启用Kit服务
   */
  async enableKitService(name: string): Promise<void> {
    const info = this.serviceInfoList.get(name);
    if (info) {
      info.enabled = true;
      console.info(`[KitManager] ${name} enabled`);
    }
  }

  /**
   * 禁用Kit服务
   */
  async disableKitService(name: string): Promise<void> {
    const info = this.serviceInfoList.get(name);
    if (info) {
      info.enabled = false;
      console.info(`[KitManager] ${name} disabled`);
    }
  }

  // ==================== 生命周期管理 ====================

  /**
   * 应用进入前台时的处理
   * 恢复需要同步的服务
   */
  onForeground(): void {
    try {
      console.info('[KitManager] App entered foreground');

      // 恢复阅读器服务
      if (this.config.enableReaderKit) {
        enhancedReaderKit.onForeground();
      }

      // 恢复协作服务
      if (this.config.enableCollaborationKit) {
        collaborationKit.onForeground();
      }

      console.info('[KitManager] Foreground processing completed');
    } catch (error) {
      console.error('[KitManager] Foreground processing failed:', error);
    }
  }

  /**
   * 应用进入后台时的处理
   * 保存进度、暂停不必要的同步
   */
  onBackground(): void {
    try {
      console.info('[KitManager] App entered background');

      // 暂停阅读器服务
      if (this.config.enableReaderKit) {
        enhancedReaderKit.onBackground();
      }

      // 暂停协作服务
      if (this.config.enableCollaborationKit) {
        collaborationKit.onBackground();
      }

      console.info('[KitManager] Background processing completed');
    } catch (error) {
      console.error('[KitManager] Background processing failed:', error);
    }
  }

  /**
   * 释放所有Kit服务
   */
  async releaseAllKits(): Promise<void> {
    try {
      console.info('[KitManager] Releasing all kits...');

      if (this.config.enableReaderKit) {
        await enhancedReaderKit.release();
      }

      if (this.config.enableShareKit) {
        shareKitService.release();
      }

      if (this.config.enableFileManagerKit) {
        fileManagerKit.release();
      }

      if (this.config.enableImageKit) {
        imageKit.release();
      }

      if (this.config.enableAudioKit) {
        await audioKitService.release();
      }

      if (this.config.enableCollaborationKit) {
        await collaborationKit.release();
      }

      if (this.config.enableAdsKit) {
        adsKitService.release();
      }

      this.isInitialized = false;
      this.serviceInfoList.clear();

      console.info('[KitManager] All kits released');
    } catch (error) {
      console.error('[KitManager] Release all kits failed:', error);
    }
  }

  /**
   * 获取Kit管理器摘要信息
   */
  getSummary(): string {
    const readyCount = this.getReadyServiceCount();
    const enabledCount = this.getEnabledServiceCount();
    const totalCount = this.serviceInfoList.size;

    return `KitManager: ${readyCount}/${totalCount} ready, ${enabledCount} enabled`;
  }

  /**
   * 打印Kit服务状态
   */
  printStatus(): void {
    console.info('===== Kit Service Status =====');
    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const name = entries[i][0];
      const info = entries[i][1];
      const statusIcon = info.status === KitServiceStatus.READY ? 'checkmark_circle_fill' :
                        info.status === KitServiceStatus.ERROR ? 'xmark_circle_fill' : '⏳';
      const enabledIcon = info.enabled ? '🟢' : '🔴';
      console.info(`${statusIcon} ${enabledIcon} ${name}: ${info.status}`);
    }
    console.info('===============================');
  }
}

// 导出单例
export const kitManager = KitManager.getInstance();
export default kitManager;
