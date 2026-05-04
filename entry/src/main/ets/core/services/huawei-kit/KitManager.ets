import { logger } from '../../../utils/Logger';
/**
 * Kit Manager - 缁熶竴Kit鏈嶅姟绠＄悊鍣?
 * Kit Manager - Unified Kit Service Manager
 *
 * 闆嗕腑绠＄悊鎵€鏈塊it鏈嶅姟鐨勫垵濮嬪寲銆侀厤缃�拰鐢熷懡鍛ㄦ湡
 *
 * @since 2.0.0
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { errorHandler, ErrorLevel } from '../utils/ErrorHandler';
import { enhancedReaderKitService as enhancedReaderKit } from '../reader/EnhancedReaderKitService';
import { shareKitService } from './ShareKitService';
import { fileManagerKitService as fileManagerKit } from '../book/FileManagerKitService';
import { imageKitService as imageKit } from './ImageKitService';
import { audioKitService } from './AudioKitService';
import { collaborationKitService as collaborationKit } from '../reader/CollaborationKitService';
import { adsKitService } from './AdsKitService';

/**
 * Kit鏈嶅姟鐘舵€?
 */
export enum KitServiceStatus {
  /** 鏈�垵濮嬪寲 */
  NOT_INITIALIZED = 'not_initialized',
  /** 鍒濆�鍖栦腑 */
  INITIALIZING = 'initializing',
  /** 宸插氨缁?*/
  READY = 'ready',
  /** 閿欒� */
  ERROR = 'error'
}

/**
 * Kit鏈嶅姟淇℃伅
 */
export interface KitServiceInfo {
  /** 鏈嶅姟鍚嶇О */
  name: string;
  /** 鏈嶅姟鐘舵€?*/
  status: KitServiceStatus;
  /** 鏄�惁鍚�敤 */
  enabled: boolean;
  /** 閿欒�淇℃伅 */
  error?: string;
  /** 鍒濆�鍖栨椂闂?*/
  initTime?: number;
}

/**
 * Kit閰嶇疆
 */
export interface KitConfig {
  /** 鏄�惁鍚�敤Reader Kit */
  enableReaderKit: boolean;
  /** 鏄�惁鍚�敤Share Kit */
  enableShareKit: boolean;
  /** 鏄�惁鍚�敤File Manager Kit */
  enableFileManagerKit: boolean;
  /** 鏄�惁鍚�敤Image Kit */
  enableImageKit: boolean;
  /** 鏄�惁鍚�敤Audio Kit */
  enableAudioKit: boolean;
  /** 鏄�惁鍚�敤Collaboration Kit */
  enableCollaborationKit: boolean;
  /** 鏄�惁鍚�敤Ads Kit */
  enableAdsKit: boolean;
}

/**
 * Kit绠＄悊鍣ㄧ被
 */
export class KitManager {
  /** 鍗曚緥瀹炰緥 */
  private static instance: KitManager;

  /** 涓婁笅鏂?*/
  private context: common.Context | null = null;

  /** 鏄�惁宸插垵濮嬪寲 */
  private isInitialized: boolean = false;

  /** Kit閰嶇疆 */
  private config: KitConfig = {
    enableReaderKit: true,
    enableShareKit: true,
    enableFileManagerKit: true,
    enableImageKit: true,
    enableAudioKit: true,
    enableCollaborationKit: true,
    enableAdsKit: false // 榛樿�绂佺敤骞垮憡锛岀敤鎴峰彲鎵嬪姩鍚�敤
  };

  /** Kit鏈嶅姟淇℃伅鍒楄〃 */
  private serviceInfoList: Map<string, KitServiceInfo> = new Map();

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): KitManager {
    if (!KitManager.instance) {
      KitManager.instance = new KitManager();
    }
    return KitManager.instance;
  }

  /**
   * 鍒濆�鍖栨墍鏈塊it鏈嶅姟
   */
  async initAllKits(context: common.Context): Promise<boolean> {
    try {
      logger.info('[KitManager] Initializing all kits...');
      this.context = context;

      const startTime = Date.now();
      let successCount = 0;
      let errorCount = 0;

      // 1. 鍒濆�鍖朢eader Kit
      if (this.config.enableReaderKit) {
        await this.initKit('ReaderKit', async () => {
          return await enhancedReaderKit.init(context);
        });
        successCount++;
      }

      // 2. 鍒濆�鍖朣hare Kit
      if (this.config.enableShareKit) {
        await this.initKit('ShareKit', async () => {
          return await shareKitService.init(context);
        });
        successCount++;
      }

      // 3. 鍒濆�鍖朏ile Manager Kit
      if (this.config.enableFileManagerKit) {
        await this.initKit('FileManagerKit', async () => {
          return await fileManagerKit.init(context);
        });
        successCount++;
      }

      // 4. 鍒濆�鍖朓mage Kit
      if (this.config.enableImageKit) {
        await this.initKit('ImageKit', async () => {
          return await imageKit.init(context);
        });
        successCount++;
      }

      // 5. 鍒濆�鍖朅udio Kit
      if (this.config.enableAudioKit) {
        await this.initKit('AudioKit', async () => {
          return await audioKitService.init(context);
        });
        successCount++;
      }

      // 6. 鍒濆�鍖朇ollaboration Kit
      if (this.config.enableCollaborationKit) {
        await this.initKit('CollaborationKit', async () => {
          return await collaborationKit.init(context);
        });
        successCount++;
      }

      // 7. 鍒濆�鍖朅ds Kit
      if (this.config.enableAdsKit) {
        await this.initKit('AdsKit', async () => {
          return await adsKitService.init(context);
        });
        successCount++;
      }

      const initTime = Date.now() - startTime;
      logger.info(`[KitManager] All kits initialized: ${successCount} succeeded, ${errorCount} failed, time: ${initTime}ms`);

      this.isInitialized = true;
      return errorCount === 0;
    } catch (error) {
      logger.error('[KitManager] Init all kits failed:', error);
      return false;
    }
  }

  /**
   * 鍒濆�鍖栧崟涓狵it鏈嶅姟
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
      logger.info(`[KitManager] Initializing ${name}...`);
      const success = await initFunc();

      if (success) {
        serviceInfo.status = KitServiceStatus.READY;
        serviceInfo.initTime = Date.now();
        logger.info(`[KitManager] ${name} initialized successfully`);
      } else {
        serviceInfo.status = KitServiceStatus.ERROR;
        serviceInfo.error = 'Initialization returned false';
        logger.error(`[KitManager] ${name} initialization failed`);
      }
    } catch (error) {
      serviceInfo.status = KitServiceStatus.ERROR;
      const err = error as Error;
      serviceInfo.error = err.message || 'Unknown error';
      logger.error(`[KitManager] ${name} initialization error:`, err.message);
    }

    this.serviceInfoList.set(name, serviceInfo);
  }

  /**
   * 妫€鏌ユ墍鏈塊it鏈嶅姟鏄�惁灏辩华
   */
  isReady(): boolean {
    if (!this.isInitialized) {
      return false;
    }

    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const info = entries[i][1];
      if (info.enabled && info.status !== KitServiceStatus.READY) {
        logger.warn(`[KitManager] ${info.name} is not ready`);
        return false;
      }
    }

    return true;
  }

  /**
   * 鑾峰彇Kit鏈嶅姟鐘舵€?
   */
  getServiceStatus(name: string): KitServiceInfo | undefined {
    return this.serviceInfoList.get(name);
  }

  /**
   * 鑾峰彇鎵€鏈塊it鏈嶅姟鐘舵€?
   */
  getAllServiceStatus(): KitServiceInfo[] {
    return Array.from(this.serviceInfoList.values());
  }

  /**
   * 鑾峰彇灏辩华鐨凨it鏈嶅姟鏁伴噺
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
   * 鑾峰彇鍚�敤鐨凨it鏈嶅姟鏁伴噺
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

  // ==================== Kit鏈嶅姟璁块棶 ====================

  /**
   * 鑾峰彇Reader Kit鏈嶅姟
   */
  getReaderKit(): object {
    return enhancedReaderKit;
  }

  /**
   * 鑾峰彇Share Kit鏈嶅姟
   */
  getShareKit(): object {
    return shareKitService;
  }

  /**
   * 鑾峰彇File Manager Kit鏈嶅姟
   */
  getFileManagerKit(): object {
    return fileManagerKit;
  }

  /**
   * 鑾峰彇Image Kit鏈嶅姟
   */
  getImageKit(): object {
    return imageKit;
  }

  /**
   * 鑾峰彇Audio Kit鏈嶅姟
   */
  getAudioKit(): object {
    return audioKitService;
  }

  /**
   * 鑾峰彇Collaboration Kit鏈嶅姟
   */
  getCollaborationKit(): object {
    return collaborationKit;
  }

  /**
   * 鑾峰彇Ads Kit鏈嶅姟
   */
  getAdsKit(): object {
    return adsKitService;
  }

  // ==================== 閰嶇疆绠＄悊 ====================

  /**
   * 鍔犺浇閰嶇疆
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
      logger.info('[KitManager] Config loaded from preferences');
    } catch (error) {
      logger.error('[KitManager] Load config failed:', error);
    }
  }

  /**
   * 淇濆瓨閰嶇疆
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
      logger.info('[KitManager] Config saved to preferences');
    } catch (error) {
      logger.error('[KitManager] Save config failed:', error);
    }
  }

  /**
   * 鏇存柊閰嶇疆
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
    logger.info('[KitManager] Config updated');
  }

  /**
   * 鑾峰彇閰嶇疆
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
   * 鍚�敤Kit鏈嶅姟
   */
  async enableKitService(name: string): Promise<void> {
    const info = this.serviceInfoList.get(name);
    if (info) {
      info.enabled = true;
      logger.info(`[KitManager] ${name} enabled`);
    }
  }

  /**
   * 绂佺敤Kit鏈嶅姟
   */
  async disableKitService(name: string): Promise<void> {
    const info = this.serviceInfoList.get(name);
    if (info) {
      info.enabled = false;
      logger.info(`[KitManager] ${name} disabled`);
    }
  }

  // ==================== 鐢熷懡鍛ㄦ湡绠＄悊 ====================

  /**
   * 搴旂敤杩涘叆鍓嶅彴鏃剁殑澶勭悊
   * 鎭㈠�闇€瑕佸悓姝ョ殑鏈嶅姟
   */
  onForeground(): void {
    try {
      logger.info('[KitManager] App entered foreground');

      // 鎭㈠�闃呰�鍣ㄦ湇鍔?
      if (this.config.enableReaderKit) {
        enhancedReaderKit.onForeground();
      }

      // 鎭㈠�鍗忎綔鏈嶅姟
      if (this.config.enableCollaborationKit) {
        collaborationKit.onForeground();
      }

      logger.info('[KitManager] Foreground processing completed');
    } catch (error) {
      logger.error('[KitManager] Foreground processing failed:', error);
    }
  }

  /**
   * 搴旂敤杩涘叆鍚庡彴鏃剁殑澶勭悊
   * 淇濆瓨杩涘害銆佹殏鍋滀笉蹇呰�鐨勫悓姝?
   */
  onBackground(): void {
    try {
      logger.info('[KitManager] App entered background');

      // 鏆傚仠闃呰�鍣ㄦ湇鍔?
      if (this.config.enableReaderKit) {
        enhancedReaderKit.onBackground();
      }

      // 鏆傚仠鍗忎綔鏈嶅姟
      if (this.config.enableCollaborationKit) {
        collaborationKit.onBackground();
      }

      logger.info('[KitManager] Background processing completed');
    } catch (error) {
      logger.error('[KitManager] Background processing failed:', error);
    }
  }

  /**
   * 閲婃斁鎵€鏈塊it鏈嶅姟
   */
  async releaseAllKits(): Promise<void> {
    try {
      logger.info('[KitManager] Releasing all kits...');

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

      logger.info('[KitManager] All kits released');
    } catch (error) {
      logger.error('[KitManager] Release all kits failed:', error);
    }
  }

  /**
   * 鑾峰彇Kit绠＄悊鍣ㄦ憳瑕佷俊鎭?
   */
  getSummary(): string {
    const readyCount = this.getReadyServiceCount();
    const enabledCount = this.getEnabledServiceCount();
    const totalCount = this.serviceInfoList.size;

    return `KitManager: ${readyCount}/${totalCount} ready, ${enabledCount} enabled`;
  }

  /**
   * 鎵撳嵃Kit鏈嶅姟鐘舵€?
   */
  printStatus(): void {
    logger.info('===== Kit Service Status =====');
    const entries = Array.from(this.serviceInfoList.entries());
    for (let i = 0; i < entries.length; i++) {
      const name = entries[i][0];
      const info = entries[i][1];
      const statusIcon = info.status === KitServiceStatus.READY ? 'checkmark_circle_fill' :
                        info.status === KitServiceStatus.ERROR ? 'xmark_circle_fill' : '鈴?;
      const enabledIcon = info.enabled ? '馃煝' : '馃敶';
      logger.info(`${statusIcon} ${enabledIcon} ${name}: ${info.status}`);
    }
    logger.info('===============================');
  }
}

// 瀵煎嚭鍗曚緥
export const kitManager = KitManager.getInstance();
export default kitManager;
