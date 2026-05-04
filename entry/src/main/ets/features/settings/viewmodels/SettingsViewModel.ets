import { logger } from '.\.\common/utils/Logger';
/**
 * SettingsPage ViewModel - V2鐗堟湰
 * 
 * 绠＄悊璁剧疆椤甸潰鎵€鏈夌姸鎬侊紝浣跨敤 @ObservedV2 瀹炵幇缁嗙矑搴︾姸鎬佹洿鏂? */

import { preferenceManager } from '../utils/PreferenceManager';
import { themeManager, AppColors } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
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
  // ==================== Tab鐘舵€?====================
  @Trace currentTab: SettingTab = SettingTab.BASIC;

  // ==================== 涓婚�鍜屾樉绀虹姸鎬?====================
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;
  @Trace breakpoint: string = 'sm';

  // ==================== 瀛樺偍鐘舵€?====================
  @Trace cacheSize: string = '128 MB';

  // ==================== 鐢ㄦ埛鐘舵€?====================
  @Trace isLoggedIn: boolean = false;
  @Trace username: string = '';

  /**
   * 鍒濆�鍖?   */
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
   * 鍒囨崲Tab
   */
  setTab(tab: SettingTab): void {
    this.currentTab = tab;
  }

  /**
   * 鑾峰彇Tab鍒楄〃
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
   * 鏇存柊涓婚�
   */
  refreshTheme(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    this.currentColors = themeManager.getColors();
  }

  /**
   * 鏇存柊瀛椾綋缂╂斁
   */
  refreshFontScale(): void {
    const fontConfig = fontScaleManager.getConfig();
    this.fontScale = fontConfig.followSystem ? fontScaleManager.getSystemFontScale() : fontConfig.scale;
  }

  /**
   * 璁＄畻缂撳瓨澶у皬
   */
  async calculateCacheSize(): Promise<void> {
    try {
      this.cacheSize = '128 MB';
    } catch (error) {
      this.cacheSize = 'Unknown';
    }
  }

  /**
   * 娓呴櫎缂撳瓨
   */
  async clearCache(): Promise<void> {
    try {
      this.cacheSize = '0 MB';
    } catch (error) {
      logger.error('Clear cache failed:', error);
    }
  }

  /**
   * 閫€鍑虹櫥褰?   */
  logout(): void {
    loginStateManager.logout();
    this.isLoggedIn = false;
    this.username = '';
  }
}

// 瀵煎嚭鍗曚緥
export const settingsViewModel = new SettingsViewModel();