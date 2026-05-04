import { logger } from '../../utils/Logger';
// Localization Kit 宸ュ叿绫?- 浣跨敤HarmonyOS瀹樻柟鍥介檯鍖栨湇鍔?// Localization Kit Utility - Using HarmonyOS Official i18n Service

import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

/**
 * Localization Kit 宸ュ叿绫? * 浣跨敤HarmonyOS瀹樻柟鐨凩ocalization Kit杩涜�鍥介檯鍖? */
class LocalizationUtil {
  private static instance: LocalizationUtil;
  private context: common.Context | null = null;
  private resMgr: resourceManager.ResourceManager | null = null;

  private constructor() {}

  static getInstance(): LocalizationUtil {
    if (!LocalizationUtil.instance) {
      LocalizationUtil.instance = new LocalizationUtil();
    }
    return LocalizationUtil.instance;
  }

  /**
   * 鍒濆�鍖?   * @param context 搴旂敤涓婁笅鏂?   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      this.resMgr = context.resourceManager;
      logger.info('[LocalizationUtil] Initialized successfully');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[LocalizationUtil] Init failed:', message);
    }
  }

  /**
   * 鑾峰彇缈昏瘧鏂囨湰
   * @param key 璧勬簮閿�悕锛堝�搴攕tring.json涓�殑name锛?   * @param params 鍙傛暟瀵硅薄锛岀敤浜庢浛鎹㈠崰浣嶇�锛堝� %{count}锛?   * @returns 缈昏瘧鍚庣殑鏂囨湰
   * 
   * @example
   * // string.json: { "name": "import_success", "value": "鎴愬姛瀵煎叆 %{count} 鏈�功" }
   * tr('import_success', { count: 5 }) // 杩斿洖: "鎴愬姛瀵煎叆 5 鏈�功"
   */
  tr(key: string, params?: Record<string, string | number>): string {
    if (!this.resMgr) {
      logger.warn('[LocalizationUtil] Not initialized, returning key:', key);
      return key;
    }

    try {
      // 浣跨敤resourceManager鑾峰彇瀛楃�涓茶祫婧?      let text = this.resMgr.getStringByNameSync(key);
      
      // 濡傛灉鑾峰彇澶辫触锛岃繑鍥瀔ey浣滀负fallback
      if (!text || text.length === 0) {
        logger.warn('[LocalizationUtil] Resource not found:', key);
        return key;
      }

      // 鏇挎崲鍙傛暟
      if (params) {
        const keys = Object.keys(params);
        for (let i = 0; i < keys.length; i++) {
          const paramKey = keys[i];
          const paramValue = params[paramKey];
          // 鏇挎崲 %{key} 鏍煎紡鐨勫崰浣嶇�
          text = text.replace(new RegExp(`%\\{${paramKey}\\}`, 'g'), String(paramValue));
        }
      }

      return text;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[LocalizationUtil] Get string failed:', key, message);
      return key;
    }
  }

  /**
   * 鑾峰彇褰撳墠绯荤粺璇�█
   * @returns 璇�█浠ｇ爜锛屽� zh_CN, en_US
   */
  getSystemLanguage(): string {
    if (!this.context) {
      return 'zh_CN';
    }

    try {
      const config = this.context.resourceManager.getConfigurationSync();
      if (config && config.language) {
        return config.language;
      }
      return 'zh_CN';
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[LocalizationUtil] Get system language failed:', message);
      return 'zh_CN';
    }
  }

  /**
   * 妫€鏌ヨ祫婧愭槸鍚﹀瓨鍦?   * @param key 璧勬簮閿�悕
   * @returns 鏄�惁瀛樺湪
   */
  hasResource(key: string): boolean {
    if (!this.resMgr) {
      return false;
    }

    try {
      this.resMgr.getStringByNameSync(key);
      return true;
    } catch {
      return false;
    }
  }
}

// 瀵煎嚭鍗曚緥
export const localizationUtil = LocalizationUtil.getInstance();

/**
 * 蹇�嵎缈昏瘧鍑芥暟
 * @param key 璧勬簮閿�悕
 * @param params 鍙傛暟瀵硅薄
 * @returns 缈昏瘧鏂囨湰
 * 
 * @example
 * Text(tr('bookshelf'))
 * Text(tr('import_success', { count: 5 }))
 */
export const tr = (key: string, params?: Record<string, string | number>): string => {
  return localizationUtil.tr(key, params);
};

export default localizationUtil;
