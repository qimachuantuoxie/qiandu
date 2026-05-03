/**
 * Reader preferences management
 * Manages reader settings: font, page turn, TTS, etc.
 */

import { BasePrefs } from './BasePrefs';
import * as Keys from './StorageKeys';

export interface ReaderSettings {
  fontSize: number;
  lineHeight: number;
  isDarkMode: boolean;
}

export const DEFAULT_READER_SETTINGS: ReaderSettings = {
  fontSize: 18,
  lineHeight: 1.6,
  isDarkMode: false
};

export class ReaderPrefs extends BasePrefs {
  private static instance: ReaderPrefs | null = null;

  static getInstance(): ReaderPrefs {
    if (!ReaderPrefs.instance) {
      ReaderPrefs.instance = new ReaderPrefs();
    }
    return ReaderPrefs.instance;
  }

  // ========== Reader Settings ==========

  saveReaderSettings(settings: ReaderSettings): void {
    try {
      const settingsJson = JSON.stringify(settings);
      this.setString('reader_settings', settingsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[ReaderPrefs] Save settings failed:', err.message);
    }
  }

  getReaderSettings(): ReaderSettings {
    try {
      const settingsJson = this.getString('reader_settings', JSON.stringify(DEFAULT_READER_SETTINGS));
      return JSON.parse(settingsJson) as ReaderSettings;
    } catch (error) {
      const err = error as Error;
      console.error('[ReaderPrefs] Load settings failed:', err.message);
      return DEFAULT_READER_SETTINGS;
    }
  }

  // ========== Display Settings ==========

  setAutoBrightness(enabled: boolean): void {
    this.setBoolean(Keys.KEY_AUTO_BRIGHTNESS, enabled);
  }

  getAutoBrightness(): boolean {
    return this.getBoolean(Keys.KEY_AUTO_BRIGHTNESS, false);
  }

  setKeepScreenOn(enabled: boolean): void {
    this.setBoolean(Keys.KEY_KEEP_SCREEN_ON, enabled);
  }

  getKeepScreenOn(): boolean {
    return this.getBoolean(Keys.KEY_KEEP_SCREEN_ON, false);
  }

  // ========== Page Turn Settings ==========

  setVolumeKeyPageTurn(enabled: boolean): void {
    this.setBoolean(Keys.KEY_VOLUME_PAGE_TURN, enabled);
  }

  getVolumeKeyPageTurn(): boolean {
    return this.getBoolean(Keys.KEY_VOLUME_PAGE_TURN, true);
  }

  setClickPageTurn(enabled: boolean): void {
    this.setBoolean(Keys.KEY_CLICK_PAGE_TURN, enabled);
  }

  getClickPageTurn(): boolean {
    return this.getBoolean(Keys.KEY_CLICK_PAGE_TURN, true);
  }

  // ========== Font Settings ==========

  setFontScale(scale: number): void {
    this.setNumber(Keys.KEY_FONT_SCALE, scale);
  }

  getFontScale(): number {
    return this.getNumber(Keys.KEY_FONT_SCALE, 1.0);
  }

  // ========== TTS Settings ==========

  setTtsSpeed(speed: number): void {
    this.setNumber(Keys.KEY_TTS_SPEED, speed);
  }

  getTtsSpeed(): number {
    return this.getNumber(Keys.KEY_TTS_SPEED, 1.0);
  }

  setTtsPitch(pitch: number): void {
    this.setNumber(Keys.KEY_TTS_PITCH, pitch);
  }

  getTtsPitch(): number {
    return this.getNumber(Keys.KEY_TTS_PITCH, 1.0);
  }

  // ========== Chinese Conversion ==========

  setChineseConvertMode(mode: number): void {
    this.setNumber(Keys.KEY_CHINESE_CONVERT, mode);
  }

  getChineseConvertMode(): number {
    return this.getNumber(Keys.KEY_CHINESE_CONVERT, 0);
  }

  // ========== Recent Folders ==========

  setRecentFolders(paths: string[]): void {
    try {
      const pathsJson = JSON.stringify(paths);
      this.setString(Keys.KEY_RECENT_FOLDERS, pathsJson);
    } catch (error) {
      const err = error as Error;
      console.error('[ReaderPrefs] Save recent folders failed:', err.message);
    }
  }

  getRecentFolders(): string[] {
    try {
      const pathsJson = this.getString(Keys.KEY_RECENT_FOLDERS, '[]');
      return JSON.parse(pathsJson) as string[];
    } catch (error) {
      const err = error as Error;
      console.error('[ReaderPrefs] Load recent folders failed:', err.message);
      return [];
    }
  }
}

export const readerPrefs = ReaderPrefs.getInstance();