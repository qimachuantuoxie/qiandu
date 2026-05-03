/**
 * 基础偏好设置管理
 * 提供核心的读写操作和缓存机制
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREFERENCES_NAME = 'qiandu_yuejie_prefs';

/**
 * 基础偏好设置管理 - 单例模式
 */
export class BasePreferenceManager {
  private static instance: BasePreferenceManager | null = null;
  protected pref: preferences.Preferences | null = null;
  protected context: common.Context | null = null;
  protected cache: Map<string, object | string | number | boolean> = new Map();
  protected cacheEnabled: boolean = true;
  protected initialized: boolean = false;


  /**
   * 获取单例实例
   */
static getInstance(): BasePreferenceManager {
if (!BasePreferenceManager.instance) {
BasePreferenceManager.instance = new BasePreferenceManager();
}
return BasePreferenceManager.instance;
}

  /**
   * 初始化偏好设置
   * 初始化偏好设置
   */
  async init(context: common.Context): Promise<void> {
    if (this.initialized && this.pref) {
      return;
    }
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, PREFERENCES_NAME);
      this.initialized = true;
      console.info('[BasePreferenceManager] Initialized successfully');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Init failed:', message);
    }
  }

  /**
   * 确保偏好设置已初始化
   */
  protected ensureInitialized(): void {
    if (!this.pref) {
      throw new Error('[BasePreferenceManager] Not initialized, call init() first');
    }
  }

  /**
   * 清除所有缓存
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * 禁用缓存
   */
  disableCache(): void {
    this.cacheEnabled = false;
    this.clearCache();
  }

  /**
   * 启用缓存
   */
  enableCache(): void {
    this.cacheEnabled = true;
  }

  /**
   * 获取字符串值
   */
  async getValue(key: string, defaultValue: string): Promise<string> {
    this.ensureInitialized();
    try {
      const value = await this.pref!.get(key, defaultValue) as string;
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
      return value;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Get value failed:', message);
      return defaultValue;
    }
  }

  /**
   * 设置字符串值
   */
  async setValue(key: string, value: string): Promise<void> {
    this.ensureInitialized();
    try {
      await this.pref!.put(key, value);
      await this.pref!.flush();
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Set value failed:', message);
    }
  }

  /**
   * 删除值
   */
  async deleteValue(key: string): Promise<void> {
    this.ensureInitialized();
    try {
      await this.pref!.delete(key);
      await this.pref!.flush();
      if (this.cacheEnabled) {
        this.cache.delete(key);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Delete value failed:', message);
    }
  }

  /**
   * 获取字符串（同步）- 保留兼容性
   */
  getString(key: string, defaultValue: string): string {
    try {
      if (!this.pref) {
        return defaultValue;
      }
      if (this.cacheEnabled && this.cache.has(key)) {
        return this.cache.get(key) as string;
      }
      const value = this.pref.getSync(key, defaultValue) as string;
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
      return value;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] 获取字符串失败:', message);
      return defaultValue;
    }
  }

  /**
   * 获取字符串（异步）- 推荐使用
   */
  async getStringAsync(key: string, defaultValue: string): Promise<string> {
    try {
      if (!this.pref) {
        return defaultValue;
      }
      if (this.cacheEnabled && this.cache.has(key)) {
        return this.cache.get(key) as string;
      }
      const value = await this.pref.get(key, defaultValue) as string;
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
      return value;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Get string failed:', message);
      return defaultValue;
    }
  }

  /**
   * 设置字符串（同步）- 保留兼容性
   */
  setString(key: string, value: string): void {
    try {
      if (!this.pref) {
        return;
      }
      this.pref.putSync(key, value);
      this.pref.flushSync();
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Set string failed:', message);
    }
  }

  /**
   * 设置字符串（异步）- 推荐使用
   */
  async setStringAsync(key: string, value: string): Promise<void> {
    try {
      if (!this.pref) {
        return;
      }
      await this.pref.put(key, value);
      await this.pref.flush();
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BasePreferenceManager] Set string async failed:', message);
    }
  }
}

export const basePreferenceManager = BasePreferenceManager.getInstance();
export default basePreferenceManager;
