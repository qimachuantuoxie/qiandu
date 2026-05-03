/**
 * 防抖偏好写入器
 * 用于减少频繁的 preferences 写入操作，提升性能
 *
 * @since 6.0.0
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREFERENCES_NAME = 'qiandu_yuejie_prefs';

/**
 * 防抖写入管理器
 * 将多次写入操作合并为一次，减少 I/O 开销
 */
class DebouncedPreferenceWriter {
  private static instance: DebouncedPreferenceWriter;
  private pref: preferences.Preferences | null = null;
  private pendingWrites: Map<string, string> = new Map();
  private flushTimer: number = -1;
  private readonly FLUSH_DELAY_MS = 2000; // 2秒延迟合并写入
  private initialized = false;

  private constructor() {}

  static getInstance(): DebouncedPreferenceWriter {
    if (!DebouncedPreferenceWriter.instance) {
      DebouncedPreferenceWriter.instance = new DebouncedPreferenceWriter();
    }
    return DebouncedPreferenceWriter.instance;
  }

  /**
   * 初始化 preferences
   */
  async init(context: common.Context): Promise<void> {
    if (this.initialized) return;
    try {
      this.pref = await preferences.getPreferences(context, PREFERENCES_NAME);
      this.initialized = true;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[DebouncedPrefs] Init failed: ' + message);
    }
  }

  /**
   * 防抖写入
   * @param key 键
   * @param value 值
   */
  setString(key: string, value: string): void {
    this.pendingWrites.set(key, value);
    this.scheduleFlush();
  }

  /**
   * 立即刷新所有待写入的数据
   */
  async flushNow(): Promise<void> {
    if (this.pendingWrites.size === 0) return;
    if (this.pref === null) return;

    const writes = this.pendingWrites;
    this.pendingWrites = new Map();

    // 取消待执行的刷新定时器
    if (this.flushTimer !== -1) {
      clearTimeout(this.flushTimer);
      this.flushTimer = -1;
    }

    try {
      const keys: string[] = [];
      const values: string[] = [];
      writes.forEach((value: string, key: string) => {
        keys.push(key);
        values.push(value);
      });

      for (let i = 0; i < keys.length; i++) {
        this.pref.put(keys[i], values[i]);
      }
      await this.pref.flush();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[DebouncedPrefs] Flush failed: ' + message);
      // 失败时将写入重新放入pending
      writes.forEach((value: string, key: string) => {
        this.pendingWrites.set(key, value);
      });
    }
  }

  /**
   * 安排延迟刷新
   */
  private scheduleFlush(): void {
    if (this.flushTimer !== -1) {
      clearTimeout(this.flushTimer);
    }

    this.flushTimer = setTimeout(() => {
      this.flushTimer = -1;
      this.flushNow();
    }, this.FLUSH_DELAY_MS);
  }

  /**
   * 清理资源
   */
  async cleanup(): Promise<void> {
    if (this.flushTimer !== -1) {
      clearTimeout(this.flushTimer);
      this.flushTimer = -1;
    }
    await this.flushNow();
  }
}

export const debouncedPrefs = DebouncedPreferenceWriter.getInstance();
