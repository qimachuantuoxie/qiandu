import { logger } from '../../../utils/Logger';
/**
 * SettingsPage ViewModel - V2 Version
 * 
 * Manages all settings page state, uses @ObservedV2 for fine-grained state updates
 */

import { preferenceManager } from '../utils/PreferenceManager';
import { themeManager, AppColors } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { loginStateManager } from '../services/auth/LoginStateManager';
import { imageCacheManager } from '../../core/services/image/ImageCacheManager';

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
  // ==================== Tab State ====================
  @Trace currentTab: SettingTab = SettingTab.BASIC;

  // ==================== Theme and Display State ====================
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;
  @Trace breakpoint: string = 'sm';

  // ==================== Storage State ====================
  @Trace cacheSize: string = '0 MB';

  // ==================== User State ====================
  @Trace isLoggedIn: boolean = false;
  @Trace username: string = '';

  /**
   * Initialize
   */
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
   * Switch Tab
   */
  setTab(tab: SettingTab): void {
    this.currentTab = tab;
  }

  /**
   * Get Tab List
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
   * Refresh Theme
   */
  refreshTheme(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    this.currentColors = themeManager.getColors();
  }

  /**
   * Refresh Font Scale
   */
  refreshFontScale(): void {
    const fontConfig = fontScaleManager.getConfig();
    this.fontScale = fontConfig.followSystem ? fontScaleManager.getSystemFontScale() : fontConfig.scale;
  }

  /**
   * Calculate Cache Size
   */
  async calculateCacheSize(): Promise<void> {
    try {
      const size = imageCacheManager.getCacheSize();
      if (size < 1024) {
        this.cacheSize = size + ' B';
      } else if (size < 1024 * 1024) {
        this.cacheSize = (size / 1024).toFixed(2) + ' KB';
      } else if (size < 1024 * 1024 * 1024) {
        this.cacheSize = (size / (1024 * 1024)).toFixed(2) + ' MB';
      } else {
        this.cacheSize = (size / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[SettingsViewModel] Calculate cache size failed:', err.message);
      this.cacheSize = 'Unknown';
    }
  }

  /**
   * Clear Cache
   */
  async clearCache(): Promise<void> {
    try {
      await imageCacheManager.clearCache();
      this.cacheSize = '0 MB';
      logger.info('[SettingsViewModel] Cache cleared successfully');
    } catch (error) {
      const err = error as Error;
      logger.error('[SettingsViewModel] Clear cache failed:', err.message);
    }
  }

  /**
   * Logout
   */
  logout(): void {
    loginStateManager.logout();
    this.isLoggedIn = false;
    this.username = '';
  }
}

// Export singleton
export const settingsViewModel = new SettingsViewModel();
