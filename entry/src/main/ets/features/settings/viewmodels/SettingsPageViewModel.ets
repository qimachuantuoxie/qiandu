/**
 * SettingsPage ViewModel - V2閻楀牊婀?
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { themeManager, AppColors } from '../utils/AppTheme';
import { loginStateManager } from '../services/auth/LoginStateManager';

export enum SettingTab {
  BASIC = 0,
  DISPLAY = 1,
  ACCOUNT = 2,
  ABOUT = 3
}

@ObservedV2
export class SettingsPageViewModel {
  @Trace currentTab: SettingTab = SettingTab.BASIC;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace cacheSize: string = '128 MB';
  @Trace isLoggedIn: boolean = false;
  @Trace username: string = '';
  @Trace breakpoint: string = 'sm';

  init(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    const config = fontScaleManager.getConfig();
    this.fontScale = config.followSystem ? fontScaleManager.getSystemFontScale() : config.scale;
    this.currentColors = themeManager.getColors();
    this.isLoggedIn = loginStateManager.isLoggedIn();
    if (this.isLoggedIn) {
      const user = loginStateManager.getCurrentUser();
      this.username = user ? user.username : '';
    }
  }

  setTab(tab: SettingTab): void {
    this.currentTab = tab;
  }

  refreshTheme(): void {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    this.currentColors = themeManager.getColors();
  }

  refreshFontScale(): void {
    const config = fontScaleManager.getConfig();
    this.fontScale = config.followSystem ? fontScaleManager.getSystemFontScale() : config.scale;
  }

  async calculateCacheSize(): Promise<void> {
    try {
      const context = preferenceManager.getContext();
      if (context) {
        const cacheDir = context.cacheDir;
        if (cacheDir) {
          const fileStat = cacheDir.statSync();
          const sizeBytes = fileStat.size;
          const sizeMB = sizeBytes / (1024 * 1024);
          this.cacheSize = sizeMB.toFixed(2) + ' MB';
        } else {
          this.cacheSize = '0 MB';
        }
      }
    } catch (error) {
      const err = error as Error;
      this.cacheSize = '0 MB';
    }
  }

  async clearCache(): Promise<void> {
    try {
      const context = preferenceManager.getContext();
      if (context) {
        const cacheDir = context.cacheDir;
        if (cacheDir) {
          cacheDir.deleteSync();
          cacheDir.mkdirSync();
          this.cacheSize = '0 MB';
        }
      }
    } catch (error) {
      const err = error as Error;
    }
  }

  logout(): void {
    loginStateManager.logout();
    this.isLoggedIn = false;
    this.username = '';
  }
}

export const settingsPageViewModel = new SettingsPageViewModel();
