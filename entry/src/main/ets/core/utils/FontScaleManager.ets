import { logger } from '../../utils/Logger';
/**
 * 瀛椾綋澶у皬绠＄悊 - 璺熼殢绯荤粺瀛椾綋缂╂斁
 * Font Scale Manager - Follow system font scaling
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from './PreferenceManager';

/**
 * 瀛椾綋缂╂斁閰嶇疆
 */
export interface FontScaleConfig {
  /** 缂╂斁姣斾緥 (0.8 - 1.5) */
  scale: number;
  /** 鏄�惁璺熼殢绯荤粺 */
  followSystem: boolean;
  /** 鏈€灏忓瓧浣撳ぇ灏?*/
  minFontSize: number;
  /** 鏈€澶у瓧浣撳ぇ灏?*/
  maxFontSize: number;
}

interface Configuration {
  fontScale?: number;
}

/**
 * 瀛椾綋缂╂斁绠＄悊鍣?- 鍗曚緥
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
   * 鍒濆�鍖?
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadConfig();
    // 缂撳瓨绯荤粺瀛椾綋缂╂斁姣斾緥
    this.cachedSystemScale = await this.getSystemFontScale();
  }

  /**
   * 鍔犺浇閰嶇疆
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
      logger.error('[FontScaleManager] Load config failed: ' + message);
    }
  }

  /**
   * 淇濆瓨閰嶇疆 (浣跨敤闃叉姈鍐欏叆)
   */
  private async saveConfig(): Promise<void> {
    try {
      const configJson = JSON.stringify(this.config);
      preferenceManager.setString('font_scale_config', configJson);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[FontScaleManager] Save config failed: ' + message);
    }
  }

  /**
   * 鑾峰彇绯荤粺瀛椾綋缂╂斁姣斾緥
   */
  async getSystemFontScale(): Promise<number> {
    try {
      if (this.context) {
        const config = await this.context.resourceManager.getConfiguration();
        if (config) {
          const fontScale: number = (config as Configuration).fontScale ? (config as Configuration).fontScale : 1.0;
          if (fontScale !== undefined) {
            return fontScale;
          }
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[FontScaleManager] Get system font scale failed: ' + message);
    }
    return 1.0;
  }

  /**
   * 鑾峰彇鏈€缁堝瓧浣撶缉鏀炬瘮渚?
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
   * 璁＄畻閫傞厤鍚庣殑瀛椾綋澶у皬锛堝悓姝ョ増鏈�紝浣跨敤缂撳瓨鐨勯厤缃�€硷級
   */
  getScaledFontSize(baseSize: number): number {
    // 浣跨敤缂撳瓨鐨勭郴缁熺缉鏀炬瘮渚嬫垨鑷�畾涔夌缉鏀炬瘮渚?
    const scale = this.config.followSystem ? this.cachedSystemScale : this.config.scale;
    const scaled = baseSize * scale;

    // 闄愬埗鍦ㄦ渶灏忓拰鏈€澶ц寖鍥村唴
    return Math.max(this.config.minFontSize, Math.min(this.config.maxFontSize, scaled));
  }

  /**
   * 璁剧疆鏄�惁璺熼殢绯荤粺
   */
  async setFollowSystem(follow: boolean): Promise<void> {
    this.config.followSystem = follow;
    await this.saveConfig();
  }

  /**
   * 璁剧疆鑷�畾涔夌缉鏀炬瘮渚?
   */
  async setCustomScale(scale: number): Promise<void> {
    this.config.followSystem = false;
    this.config.scale = Math.max(0.8, Math.min(1.5, scale));
    await this.saveConfig();
  }

  /**
   * 璁剧疆鏈€灏忓瓧浣?
   */
  async setMinFontSize(size: number): Promise<void> {
    this.config.minFontSize = Math.max(8, size);
    await this.saveConfig();
  }

  /**
   * 璁剧疆鏈€澶у瓧浣?
   */
  async setMaxFontSize(size: number): Promise<void> {
    this.config.maxFontSize = Math.min(32, size);
    await this.saveConfig();
  }

  /**
   * 鑾峰彇绯荤粺瀛椾綋缂╂斁姣斾緥锛堝悓姝ョ増鏈�紝浣跨敤缂撳瓨鍊硷級
   */
  getFontScaleSync(): number {
    return this.cachedSystemScale;
  }

  /**
   * 鑾峰彇褰撳墠閰嶇疆
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
