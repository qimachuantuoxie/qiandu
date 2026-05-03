/**
 * 应用主题管理
 * App Theme Management - Centralized theme and color management
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from './PreferenceManager';

export interface ReaderThemeColors {
  background: string;
  text: string;
}

export interface AppColors {
  primary: string;
  primaryLight: string;
  onPrimary: string;
  background: string;
  backgroundSecondary: string;
  surface: string;
  onSurface: string;
  onSurfaceVariant: string;
  surfaceVariant: string;
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  divider: string;
  error: string;
  success: string;
  warning: string;
  cardBackground: string;
  border: string;
}

export interface CommonColors {
  PRIMARY_BLUE: string;
  TEXT_DARK: string;
  TEXT_LIGHT: string;
  SUCCESS_GREEN: string;
  WARNING_ORANGE: string;
  ERROR_RED: string;
  PURPLE: string;
  CYAN: string;
  RED: string;
}

export const LIGHT_COLORS: AppColors = {
  primary: '#007DFF',
  primaryLight: '#4DA3FF',
  onPrimary: '#FFFFFF',
  background: '#F5F5F7',
  backgroundSecondary: '#FFFFFF',
  surface: '#FFFFFF',
  onSurface: '#1A1A1A',
  onSurfaceVariant: '#666666',
  surfaceVariant: '#F5F5F7',
  textPrimary: '#1A1A1A',
  textSecondary: '#666666',
  textHint: '#999999',
  divider: '#E5E5E5',
  error: '#FF3B30',
  success: '#34C759',
  warning: '#FF9500',
  cardBackground: '#FFFFFF',
  border: '#E5E5E5'
};

export const DARK_COLORS: AppColors = {
  primary: '#0A84FF',
  primaryLight: '#409CFF',
  onPrimary: '#FFFFFF',
  background: '#000000',
  backgroundSecondary: '#1C1C1E',
  surface: '#1C1C1E',
  onSurface: '#FFFFFF',
  onSurfaceVariant: '#AAAAAA',
  surfaceVariant: '#2C2C2E',
  textPrimary: '#FFFFFF',
  textSecondary: '#AAAAAA',
  textHint: '#666666',
  divider: '#38383A',
  error: '#FF453A',
  success: '#32D74B',
  warning: '#FF9F0A',
  cardBackground: '#1C1C1E',
  border: '#38383A'
};

export const COMMON_COLORS: CommonColors = {
  PRIMARY_BLUE: '#007DFF',
  TEXT_DARK: '#1A1A1A',
  TEXT_LIGHT: '#FFFFFF',
  SUCCESS_GREEN: '#34C759',
  WARNING_ORANGE: '#FF9500',
  ERROR_RED: '#FF3B30',
  PURPLE: '#AF52DE',
  CYAN: '#5AC8FA',
  RED: '#FF3B30'
};

/**
 * 涓婚绠＄悊鍣ㄧ被
 */
export class ThemeManager {
  private isDark: boolean = false;
  private colors: AppColors = LIGHT_COLORS;
  private fontScale: number = 1.0;
  private context: common.Context | null = null;
  private configChangeCallback: (() => void) | null = null;

  init(context: common.Context): void {
    this.context = context;
    this.syncSystemTheme();
  }

  private syncSystemTheme(): void {
    try {
      const savedTheme = preferenceManager.getString('theme', 'light');
      this.isDark = savedTheme === 'dark';
      this.updateTheme();
    } catch {
      this.isDark = false;
      this.updateTheme();
    }
  }

  private updateTheme(): void {
    this.colors = this.isDark ? DARK_COLORS : LIGHT_COLORS;
  }

  watchSystemTheme(callback: () => void): void {
    this.configChangeCallback = callback;
  }

  unwatchSystemTheme(): void {
    this.configChangeCallback = null;
  }

  setDarkMode(isDark: boolean): void {
    this.isDark = isDark;
    this.updateTheme();
  }

  toggleDarkMode(): void {
    this.isDark = !this.isDark;
    this.updateTheme();
  }

  isDarkMode(): boolean {
    return this.isDark;
  }

  subscribe(callback: () => void): void {
    this.configChangeCallback = callback;
  }

  getColors(): AppColors {
    return this.colors;
  }

  getFontScale(): number {
    return this.fontScale;
  }

  setFontScale(scale: number): void {
    this.fontScale = Math.max(0.8, Math.min(1.5, scale));
  }

  scaleFontSize(baseSize: number): number {
    return Math.round(baseSize * this.fontScale);
  }

  getReaderTheme(themeName: string): ReaderThemeColors {
    if (themeName === 'dark') {
      return { background: '#1A1A1A', text: '#CCCCCC' };
    }
    return { background: '#FFFFFF', text: '#000000' };
  }

  hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + alpha + ')';
  }
}

// 瀵煎嚭鍗曚緥瀹炰緥
export const themeManager = new ThemeManager();
export const appTheme = themeManager;
