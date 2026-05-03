/**
 * 字体大小管理 - 跟随系统字体缩放
 * Font Scale Manager - Follow system font scaling
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from './PreferenceManager';

/**
 * 字体缩放配置
 */
export interface FontScaleConfig {
  /** 缩放比例 (0.8 - 1.5) */
  scale: number;
  /** 是否跟随系统 */
  followSystem: boolean;
  /** 最小字体大小 */
  minFontSize: number;
  /** 最大字体大小 */
  maxFontSize: number;
}

interface Configuration {
  fontScale?: number;
}

/**
 * 字体缩放管理器 - 单例
 */
class FontScaleManager {
  private static instance: FontScaleManager;
  private context: common.Context | null = null;
  private config: FontScaleConfig = {
    scale: 1.0,
    followSystem: true,
    minFontSize: 10,
    maxFontSize: 24
  };
  private cachedSystemScale: number = 1.0;

  private constructor() {}

  static getInstance(): FontScaleManager {
    if (!FontScaleManager.instance) {
      FontScaleManager.instance = new FontScaleManager();
    }
    return FontScaleManager.instance;
  }

  /**
   * 初始化
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadConfig();
    // 缓存系统字体缩放比例
    this.cachedSystemScale = await this.getSystemFontScale();
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig: string = preferenceManager.getString('font_scale_config', '');
      if (savedConfig && savedConfig.length > 0) {
        const parsed: FontScaleConfig = JSON.parse(savedConfig) as FontScaleConfig;
        if (parsed.scale !== undefined) {
          this.config.scale = parsed.scale;
        }
        if (parsed.followSystem !== undefined) {
          this.config.followSystem = parsed.followSystem;
        }
        if (parsed.minFontSize !== undefined) {
          this.config.minFontSize = parsed.minFontSize;
        }
        if (parsed.maxFontSize !== undefined) {
          this.config.maxFontSize = parsed.maxFontSize;
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[FontScaleManager] Load config failed: ' + message);
    }
  }

  /**
   * 保存配置 (使用防抖写入)
   */
  private async saveConfig(): Promise<void> {
    try {
      const configJson = JSON.stringify(this.config);
      preferenceManager.setString('font_scale_config', configJson);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[FontScaleManager] Save config failed: ' + message);
    }
  }

  /**
   * 获取系统字体缩放比例
   */
  async getSystemFontScale(): Promise<number> {
    try {
      if (this.context) {
        const config = await this.context.resourceManager.getConfiguration();
        if (config) {
          const fontScale: number = (config as Configuration).fontScale ?? 1.0;
          if (fontScale !== undefined) {
            return fontScale;
          }
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[FontScaleManager] Get system font scale failed: ' + message);
    }
    return 1.0;
  }

  /**
   * 获取最终字体缩放比例
   */
  async getFontScale(): Promise<number> {
    if (this.config.followSystem) {
      const systemScale = await this.getSystemFontScale();
      this.cachedSystemScale = systemScale;
      return systemScale;
    }
    return this.config.scale;
  }

  /**
   * 计算适配后的字体大小（同步版本，使用缓存的配置值）
   */
  getScaledFontSize(baseSize: number): number {
    // 使用缓存的系统缩放比例或自定义缩放比例
    const scale = this.config.followSystem ? this.cachedSystemScale : this.config.scale;
    const scaled = baseSize * scale;

    // 限制在最小和最大范围内
    return Math.max(this.config.minFontSize, Math.min(this.config.maxFontSize, scaled));
  }

  /**
   * 设置是否跟随系统
   */
  async setFollowSystem(follow: boolean): Promise<void> {
    this.config.followSystem = follow;
    await this.saveConfig();
  }

  /**
   * 设置自定义缩放比例
   */
  async setCustomScale(scale: number): Promise<void> {
    this.config.followSystem = false;
    this.config.scale = Math.max(0.8, Math.min(1.5, scale));
    await this.saveConfig();
  }

  /**
   * 设置最小字体
   */
  async setMinFontSize(size: number): Promise<void> {
    this.config.minFontSize = Math.max(8, size);
    await this.saveConfig();
  }

  /**
   * 设置最大字体
   */
  async setMaxFontSize(size: number): Promise<void> {
    this.config.maxFontSize = Math.min(32, size);
    await this.saveConfig();
  }

  /**
   * 获取系统字体缩放比例（同步版本，使用缓存值）
   */
  getFontScaleSync(): number {
    return this.cachedSystemScale;
  }

  /**
   * 获取当前配置
   */
  getConfig(): FontScaleConfig {
    return {
      scale: this.config.scale,
      followSystem: this.config.followSystem,
      minFontSize: this.config.minFontSize,
      maxFontSize: this.config.maxFontSize
    };
  }
}

export const fontScaleManager = FontScaleManager.getInstance();
export default fontScaleManager;
