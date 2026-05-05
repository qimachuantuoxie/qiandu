import { logger } from '../../utils/Logger';
// Localization Kit 工具类 - 使用HarmonyOS官方国际化服务
// Localization Kit Utility - Using HarmonyOS Official i18n Service

import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

/**
 * Localization Kit 工具类
 * 使用HarmonyOS官方的Localization Kit进行国际化
 */
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
   * 初始化
   * @param context 应用上下文
   */
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
   * 获取翻译文本
   * @param key 资源键名（对应string.json中的name）
   * @param params 参数对象，用于替换占位符（如 %{count}）
   * @returns 翻译后的文本
   * 
   * @example
   * // string.json: { "name": "import_success", "value": "成功导入 %{count} 本书" }
   * tr('import_success', { count: 5 }) // 返回: "成功导入 5 本书"
   */
  tr(key: string, params?: Record<string, string | number>): string {
    if (!this.resMgr) {
      logger.warn('[LocalizationUtil] Not initialized, returning key:', key);
      return key;
    }

    try {
      // 使用resourceManager获取字符串资源
      let text = this.resMgr.getStringByNameSync(key);
      
      // 如果获取失败，返回key作为fallback
      if (!text || text.length === 0) {
        logger.warn('[LocalizationUtil] Resource not found:', key);
        return key;
      }

      // 替换参数
      if (params) {
        const keys = Object.keys(params);
        for (let i = 0; i < keys.length; i++) {
          const paramKey = keys[i];
          const paramValue = params[paramKey];
          // 替换 %{key} 格式的占位符
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
   * 获取当前系统语言
   * @returns 语言代码，如 zh_CN, en_US
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
   * 检查资源是否存在
   * @param key 资源键名
   * @returns 是否存在
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

// 导出单例
export const localizationUtil = LocalizationUtil.getInstance();

/**
 * 快捷翻译函数
 * @param key 资源键名
 * @param params 参数对象
 * @returns 翻译文本
 * 
 * @example
 * Text(tr('bookshelf'))
 * Text(tr('import_success', { count: 5 }))
 */
export const tr = (key: string, params?: Record<string, string | number>): string => {
  return localizationUtil.tr(key, params);
};

export default localizationUtil;
