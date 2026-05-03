/**
 * 闃呰璁剧疆绠＄悊鍣?
 * 绠＄悊闃呰鍣ㄧ浉鍏崇殑璁剧疆锛堝瓧浣撱€佷富棰樸€佺炕椤电瓑锛?
 */

import { basePreferenceManager } from './BasePreferenceManager';
import { ReadSettings, ReadTheme, PageTurnMode } from '../models/CoreBookModel';

const DEFAULT_READER_SETTINGS: ReadSettings = {
  fontSize: 18,
  lineSpacing: 1.6,
  theme: ReadTheme.LIGHT,
  brightness: 100,
  screenOrientation: 0,
  pageTurnMode: PageTurnMode.SIMULATION,
  fontFamily: 'system',
  paragraphSpacing: 0,
  letterSpacing: 0,
  textIndent: 0
};

/**
 * 闃呰璁剧疆绠＄悊鍣?
 */
export class ReadingSettingsManager {
  /**
   * 淇濆瓨闃呰璁剧疆
   */
  setReadSettings(settings: ReadSettings): void {
    try {
      basePreferenceManager.setString('read_settings', JSON.stringify(settings));
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Save settings failed:', message);
    }
  }

  /**
   * 鑾峰彇闃呰璁剧疆
   */
  getReadSettings(): ReadSettings {
    try {
      const settingsStr = basePreferenceManager.getString('read_settings', '');
      if (settingsStr) {
        const settings = JSON.parse(settingsStr) as ReadSettings;
        return settings;
      }
      return DEFAULT_READER_SETTINGS;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Load settings failed:', message);
      return DEFAULT_READER_SETTINGS;
    }
  }

  /**
   * 淇濆瓨涓婚
   */
  setTheme(theme: ReadTheme): void {
    try {
      basePreferenceManager.setString('theme', theme.toString());
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Save theme failed:', message);
    }
  }

  /**
   * 鑾峰彇涓婚
   */
  getTheme(): ReadTheme {
    try {
      const theme = basePreferenceManager.getString('theme', ReadTheme.LIGHT.toString()) as ReadTheme;
      const validThemes: ReadTheme[] = [ReadTheme.LIGHT, ReadTheme.SEPIA, ReadTheme.DARK, ReadTheme.AUTO];
      return validThemes.indexOf(theme) !== -1 ? theme : ReadTheme.LIGHT;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Load theme failed:', message);
      console.error('[ReadingSettings] Load theme failed:', err.message);
      return ReadTheme.LIGHT;
    }
  }

  /**
   * 淇濆瓨缈婚〉妯″紡
   */
  setPageTurnMode(mode: PageTurnMode): void {
    try {
      basePreferenceManager.setString('page_turn_mode', mode.toString());
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Save page turn mode failed:', message);
      console.error('[ReadingSettings] Save page turn mode failed:', err.message);
    }
  }

  /**
   * 鑾峰彇缈婚〉妯″紡
   */
  getPageTurnMode(): PageTurnMode {
    try {
      const mode = basePreferenceManager.getString('page_turn_mode', PageTurnMode.SIMULATION.toString()) as PageTurnMode;
      const validModes: PageTurnMode[] = [PageTurnMode.SCROLL, PageTurnMode.COVER, PageTurnMode.SIMULATION, PageTurnMode.SLIDE, PageTurnMode.NONE];
      return validModes.indexOf(mode) !== -1 ? mode : PageTurnMode.SIMULATION;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Load page turn mode failed:', message);
      console.error('[ReadingSettings] Load page turn mode failed:', err.message);
      return PageTurnMode.SIMULATION;
    }
  }

  /**
   * 淇濆瓨瀛椾綋澶у皬
   */
  setFontSize(fontSize: number): void {
    try {
      basePreferenceManager.setString('font_size', fontSize.toString());
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Save font size failed:', message);
      console.error('[ReadingSettings] Save font size failed:', err.message);
    }
  }

  /**
   * 鑾峰彇瀛椾綋澶у皬
   */
  getFontSize(): number {
    try {
      const size = basePreferenceManager.getString('font_size', '18');
      return parseInt(size, 10) || 18;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Load font size failed:', message);
      console.error('[ReadingSettings] Load font size failed:', err.message);
      return 18;
    }
  }

  /**
   * 淇濆瓨瀛椾綋缂╂斁
   */
  setFontScale(scale: number): void {
    try {
      basePreferenceManager.setString('font_scale', scale.toString());
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Save font scale failed:', message);
      console.error('[ReadingSettings] Save font scale failed:', err.message);
    }
  }

  /**
   * 鑾峰彇瀛椾綋缂╂斁
   */
  getFontScale(): number {
    try {
      const scale = basePreferenceManager.getString('font_scale', '1.0');
      return parseFloat(scale) || 1.0;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[ReadingSettings] Load font scale failed:', message);
      console.error('[ReadingSettings] Load font scale failed:', err.message);
      return 1.0;
    }
  }
}

export const readingSettingsManager = new ReadingSettingsManager();
export default readingSettingsManager;

