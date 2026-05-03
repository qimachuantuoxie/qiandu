/**
 * 阅读设置 ViewModel
 * 管理阅读器所有设置
 */
import { readingSettingsManager } from '../utils/ReadingSettingsManager';
import { ReadTheme, PageTurnMode, ReadSettings } from '../models/CoreBookModel';

@ObservedV2
export class ReaderSettingsViewModel {
  // 显示设置
  @Trace fontSize: number = 18;
  @Trace fontName: string = 'system';
  @Trace fontWeightValue: number = 400;
  @Trace lineHeight: number = 1.6;
  @Trace backgroundColor: string = '#FFFFFF';
  @Trace pageMargin: number = 16;
  @Trace showPageNumber: boolean = true;

  // 主题设置
  @Trace theme: ReadTheme = ReadTheme.LIGHT;
  @Trace isAutoTheme: boolean = false;
  @Trace brightness: number = 0.5;

  // 翻页设置
  @Trace pageTurnMode: PageTurnMode = PageTurnMode.SIMULATION;
  @Trace volumeKeyEnabled: boolean = true;
  @Trace clickEnabled: boolean = true;

  // 自动翻页
  @Trace autoPageEnabled: boolean = false;
  @Trace autoPageSpeed: number = 3000;

  // TTS设置
  @Trace ttsSpeed: number = 1.0;
  @Trace ttsVolume: number = 1.0;
  @Trace enableTTS: boolean = false;
  @Trace selectedVoice: string = '晓晓';

  // 漫画设置
  @Trace comicScale: number = 1.0;
  @Trace comicFitMode: string = 'width';
  @Trace comicPreloadEnabled: boolean = true;
  @Trace comicPreloadCount: number = 2;
  @Trace comicReadMode: number = 0;
  @Trace comicScaleMode: number = 0;
  @Trace autoPlayInterval: number = 3;

  // 其他设置
  @Trace keepScreenOn: boolean = true;
  @Trace statusBarVisible: boolean = true;
  @Trace navigationBarVisible: boolean = true;
  @Trace fullScreenMode: boolean = false;
  @Trace hideStatusBar: boolean = false;

  // UI控制状态
  @Trace isLoading: boolean = false;
  @Trace hasChanges: boolean = false;
  @Trace showResetDialog: boolean = false;

  async loadSettings(): Promise<void> {
    this.isLoading = true;
    try {
      const settings = readingSettingsManager.getReadSettings();

      this.fontSize = settings.fontSize || 18;
      this.fontName = settings.fontName || 'system';
      this.lineHeight = settings.lineHeight || 1.6;
      this.theme = settings.theme || ReadTheme.LIGHT;
      this.pageTurnMode = settings.pageTurnMode || PageTurnMode.SIMULATION;
      this.volumeKeyEnabled = settings.volumeKeyEnabled !== undefined ? settings.volumeKeyEnabled : true;
      this.clickEnabled = settings.clickEnabled !== undefined ? settings.clickEnabled : true;
      this.brightness = settings.brightness !== undefined ? settings.brightness : 0.5;
      this.keepScreenOn = settings.keepScreenOn !== undefined ? settings.keepScreenOn : true;
      this.autoPageSpeed = settings.autoPageSpeed || 3000;

      this.hasChanges = false;
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isLoading = false;
    }
  }

  async saveSettings(): Promise<void> {
    try {
      const readSettings: ReadSettings = {
        fontSize: this.fontSize,
        fontFamily: this.fontName,
        lineSpacing: this.lineHeight,
        theme: this.theme,
        brightness: this.brightness,
        screenOrientation: 0,
        pageTurnMode: this.pageTurnMode,
        paragraphSpacing: 0,
        letterSpacing: 0,
        textIndent: 0
      };
      readingSettingsManager.setReadSettings(readSettings);
      this.hasChanges = false;
    } catch (error) {
      const err = error as Error;
    }
  }

  resetToDefault(): void {
    this.fontSize = 18;
    this.fontName = 'system';
    this.fontWeightValue = 400;
    this.lineHeight = 1.6;
    this.theme = ReadTheme.LIGHT;
    this.isAutoTheme = false;
    this.brightness = 0.5;
    this.pageTurnMode = PageTurnMode.SIMULATION;
    this.volumeKeyEnabled = true;
    this.clickEnabled = true;
    this.backgroundColor = '#FFFFFF';
    this.pageMargin = 16;
    this.showPageNumber = true;
    this.autoPageEnabled = false;
    this.autoPageSpeed = 3000;
    this.ttsSpeed = 1.0;
    this.ttsVolume = 1.0;
    this.enableTTS = false;
    this.selectedVoice = '晓晓';
    this.comicScale = 1.0;
    this.comicFitMode = 'width';
    this.comicReadMode = 0;
    this.comicScaleMode = 0;
    this.autoPlayInterval = 3;
    this.keepScreenOn = true;
    this.statusBarVisible = true;
    this.navigationBarVisible = true;
    this.fullScreenMode = false;
    this.hideStatusBar = false;
    this.hasChanges = true;
  }

  markChanged(): void {
    this.hasChanges = true;
  }

  applySettings(): void {
    this.markChanged();
  }
}

export const readerSettingsViewModel = new ReaderSettingsViewModel();
export default readerSettingsViewModel;