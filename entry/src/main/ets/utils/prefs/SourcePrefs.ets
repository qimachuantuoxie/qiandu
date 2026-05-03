/**
 * 书源偏好设置管理
 * 管理书源、替换规则等
 */

import { BasePrefs } from './BasePrefs';
import { BookSource, ReplaceRule } from '../../models/CoreSourceModel';
import * as Keys from './StorageKeys';

export class SourcePrefs extends BasePrefs {
  private static instance: SourcePrefs | null = null;

  static getInstance(): SourcePrefs {
    if (!SourcePrefs.instance) {
      SourcePrefs.instance = new SourcePrefs();
    }
    return SourcePrefs.instance;
  }

  // ========== 书源管理 ==========

  /**
   * 保存书源列表
   */
  setBookSources(sources: BookSource[]): void {
    try {
      const sourcesJson = JSON.stringify(sources);
      this.setString(Keys.KEY_BOOK_SOURCES, sourcesJson);
    } catch (error) {
      const err = error as Error;
      console.error('[SourcePrefs] 保存书源失败: ' + err.message);
    }
  }

  /**
   * 获取书源列表
   */
  getBookSources(): BookSource[] {
    try {
      const sourcesJson = this.getString(Keys.KEY_BOOK_SOURCES, '[]');
      return JSON.parse(sourcesJson) as BookSource[];
    } catch (error) {
      const err = error as Error;
      console.error('[SourcePrefs] 获取书源失败: ' + err.message);
      return [];
    }
  }

  // ========== 替换规则 ==========

  /**
   * 获取替换规则
   */
  getReplaceRules(): ReplaceRule[] {
    try {
      const rulesJson = this.getString(Keys.KEY_REPLACE_RULES, '[]');
      return JSON.parse(rulesJson) as ReplaceRule[];
    } catch (error) {
      const err = error as Error;
      console.error('[SourcePrefs] 获取替换规则失败: ' + err.message);
      return [];
    }
  }

  /**
   * 保存替换规则
   */
  setReplaceRules(rules: ReplaceRule[]): void {
    try {
      const rulesJson = JSON.stringify(rules);
      this.setString(Keys.KEY_REPLACE_RULES, rulesJson);
    } catch (error) {
      const err = error as Error;
      console.error('[SourcePrefs] 保存替换规则失败: ' + err.message);
    }
  }
}

// 导出单例
export const sourcePrefs = SourcePrefs.getInstance();
