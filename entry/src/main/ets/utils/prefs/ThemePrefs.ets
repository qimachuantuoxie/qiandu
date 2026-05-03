/**
 * 主题偏好设置管理
 * 管理书架显示、主题、排序等 UI 相关设置
 */

import { BasePrefs } from './BasePrefs';
import { BookshelfGroup } from '../../models/CoreBookModel';
import * as Keys from './StorageKeys';

export class ThemePrefs extends BasePrefs {
  private static instance: ThemePrefs | null = null;

  static getInstance(): ThemePrefs {
    if (!ThemePrefs.instance) {
      ThemePrefs.instance = new ThemePrefs();
    }
    return ThemePrefs.instance;
  }

  // ========== 书架设置 ==========

  /**
   * 设置书架分组
   */
  setBookshelfGroups(groups: BookshelfGroup[]): void {
    try {
      const groupsJson = JSON.stringify(groups);
      this.setString(Keys.KEY_BOOKSHELF_GROUPS, groupsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[ThemePrefs] 保存书架分组失败: ' + err.message);
    }
  }

  /**
   * 获取书架分组
   */
  getBookshelfGroups(): BookshelfGroup[] {
    try {
      const groupsJson = this.getString(Keys.KEY_BOOKSHELF_GROUPS, '[]');
      return JSON.parse(groupsJson) as BookshelfGroup[];
    } catch (error) {
      const err = error as Error;
      console.error('[ThemePrefs] 获取书架分组失败: ' + err.message);
      return [];
    }
  }

  /**
   * 设置网格列数
   */
  setGridColumns(columns: number): void {
    this.setNumber(Keys.KEY_GRID_COLUMNS, columns);
  }

  /**
   * 获取网格列数
   */
  getGridColumns(): number {
    return this.getNumber(Keys.KEY_GRID_COLUMNS, 3);
  }

  /**
   * 设置排序模式
   */
  setSortMode(mode: number): void {
    this.setNumber(Keys.KEY_SORT_MODE, mode);
  }

  /**
   * 获取排序模式
   */
  getSortMode(): number {
    return this.getNumber(Keys.KEY_SORT_MODE, 0);
  }

  // ========== 主题设置 ==========

  /**
   * 设置主题
   */
  setTheme(theme: string): void {
    this.setString(Keys.KEY_THEME, theme);
  }

  /**
   * 获取主题
   */
  getTheme(): string {
    return this.getString(Keys.KEY_THEME, 'light');
  }
}

// 导出单例
export const themePrefs = ThemePrefs.getInstance();
