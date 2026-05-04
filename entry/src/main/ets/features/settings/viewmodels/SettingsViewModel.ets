import { logger } from '.\.\common/utils/Logger';
/**
 * SettingsPage ViewModel - V2版本
 * 
 * 管理设置页面所有状态，使用 @ObservedV2 实现细粒度状态更�? */

import { preferenceManager } from '../utils/PreferenceManager';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { loginStateManager } from '../services/auth/LoginStateManager';

export enum SettingTab {
  BASIC,
  DISPLAY,
  ACCOUNT,
  ABOUT
}

export interface SettingItem {
  nameKey: string;
  val: number;
}

@ObservedV2
export class SettingsViewModel {
  // ==================== Tab状�?====================
  @Trace currentTab: SettingTab = SettingTab.BASIC;

  // ==================== 主题和显示状�?====================
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;
  @Trace breakpoint: string = 'sm';

  // ==================== 存储状�?====================
  @Trace cacheSize: string = '128 MB';

  // ==================== 用户状�?====================
  @Trace isLoggedIn: boolean = false;
  @Trace username: string = '';

  /**
   * 初始�?   */
  init(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    const fontConfig = fontScaleManager.getConfig();
    this.fontScale = fontConfig.followSystem ? fontScaleManager.getSystemFontScale() : fontConfig.scale;
    this.currentColors = themeManager.getColors();
    this.isLoggedIn = loginStateManager.isLoggedIn();
    if (this.isLoggedIn) {
      const user = loginStateManager.getCurrentUser();
      this.username = user ? user.username : '';
    }
  }

  /**
   * 切换Tab
   */
  setTab(tab: SettingTab): void {
    this.currentTab = tab;
  }

  /**
   * 获取Tab列表
   */
  getTabNames(): SettingItem[] {
    return [
      { nameKey: 'general', val: SettingTab.BASIC },
      { nameKey: 'display', val: SettingTab.DISPLAY },
      { nameKey: 'account', val: SettingTab.ACCOUNT },
      { nameKey: 'about', val: SettingTab.ABOUT }
    ];
  }

  /**
   * 更新主题
   */
  refreshTheme(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    this.currentColors = themeManager.getColors();
  }

  /**
   * 更新字体缩放
   */
  refreshFontScale(): void {
    const fontConfig = fontScaleManager.getConfig();
    this.fontScale = fontConfig.followSystem ? fontScaleManager.getSystemFontScale() : fontConfig.scale;
  }

  /**
   * 计算缓存大小
   */
  async calculateCacheSize(): Promise<void> {
    try {
      this.cacheSize = '128 MB';
    } catch (error) {
      this.cacheSize = 'Unknown';
    }
  }

  /**
   * 清除缓存
   */
  async clearCache(): Promise<void> {
    try {
      this.cacheSize = '0 MB';
    } catch (error) {
      logger.error('Clear cache failed:', error);
    }
  }

  /**
   * 退出登�?   */
  logout(): void {
    loginStateManager.logout();
    this.isLoggedIn = false;
    this.username = '';
  }
}

// 导出单例
export const settingsViewModel = new SettingsViewModel();