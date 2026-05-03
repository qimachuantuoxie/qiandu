import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { readerSettingsViewModel } from '../viewmodels/ReaderSettingsViewModel';

@Entry
@Component
struct ReaderSettingsPage {
  @State isDarkMode: boolean = false;
  @State activeTab: number = 0;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;

  private tabNames: string[] = ['显示', 'TTS', '漫画', '屏幕'];
  private voiceOptions: string[] = ['晓晓', '小艺', '嘉然', '云伊', '元气'];
  private backgroundColorOptions: string[] = ['#FFFFFF', '#F5F5DC', '#E8F5E9', '#2C2C2E', '#1A1A1A'];
  private backgroundColorNames: string[] = ['白天', '护眼', '绿色', '夜间', '纯黑'];
  private fontSizeOptions: number[] = [14, 16, 18, 20, 22, 24, 26, 28];
  private lineHeightOptions: number[] = [1.2, 1.4, 1.6, 1.8, 2.0];

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    await readerSettingsViewModel.loadSettings();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private async saveSettings(): Promise<void> {
    try {
      await readerSettingsViewModel.saveSettings();
      promptAction.showToast({ message: '设置已保存', duration: 1500 });
    } catch (error) {
      const err = error as BusinessError;
      console.error('[ReaderSettings] Save failed:', err.message);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      Row() {
        Button() {
          Text('←').fontSize(24).fontColor(this.tc('#333333', '#FFFFFF'))
        }
        .width(40).height(40).backgroundColor('rgba(255,255,255,0.5)').borderRadius(20)
        .onClick(() => {
          try {
            router.back();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('[ReaderSettings] back failed:', msg);
          }
        })

        Text('阅读器设置')
          .fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1).textAlign(TextAlign.Center)

        Button('保存')
          .height(32).backgroundColor(this.currentColors.primary)
          .fontColor('#FFFFFF').fontSize(14).borderRadius(16)
          .onClick(() => { this.saveSettings(); })
      }
      .width('100%').height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))

      Row({ space: 0 }) {
        ForEach(this.tabNames, (tab: string, index: number) => {
          Column() {
            Text(tab)
              .fontSize(15)
              .fontColor(this.activeTab === index ? this.currentColors.primary : this.tc('#666666', '#AAAAAA'))
              .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
            Divider()
              .color(this.activeTab === index ? this.currentColors.primary : 'transparent')
              .strokeWidth(2).margin({ top: 4 })
          }
          .layoutWeight(1).height(48).justifyContent(FlexAlign.Center)
          .onClick(() => { this.activeTab = index; })
        })
      }
      .width('100%').backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))

      Scroll() {
        Column() {
          if (this.activeTab === 0) {
            this.buildDisplaySettings()
          } else if (this.activeTab === 1) {
            this.buildTTSSettings()
          } else if (this.activeTab === 2) {
            this.buildComicSettings()
          } else {
            this.buildScreenSettings()
          }
        }
        .width('100%').padding(16)
      }
      .layoutWeight(1).width('100%')

      Row({ space: 12 }) {
        Button('重置')
          .layoutWeight(1).height(44)
          .backgroundColor(this.bg('#F5F5F5', '#3C3C3E'))
          .fontColor(this.tc('#666666', '#AAAAAA')).fontSize(16)
          .borderRadius(12)
          .onClick(() => {
            readerSettingsViewModel.resetToDefault();
            promptAction.showToast({ message: '已重置为默认设置', duration: 1500 });
          })

        Button('保存设置')
          .layoutWeight(1).height(44)
          .backgroundColor(this.currentColors.primary)
          .fontColor('#FFFFFF').fontSize(16)
          .borderRadius(12)
          .onClick(() => { this.saveSettings(); })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    }
    .width('100%').height('100%')
    .backgroundColor(this.bg('#F5F5F5', '#141414'))
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: 20 }) {
      Column({ space: 12 }) {
        Text('背景颜色')
          .fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        Row({ space: 8 }) {
          ForEach(this.backgroundColorOptions, (color: string, index: number) => {
            Column() {
              Circle({ width: 40, height: 40 })
                .fill(color)
                .border({
                  width: readerSettingsViewModel.backgroundColor === color ? 3 : 1,
                  color: readerSettingsViewModel.backgroundColor === color ? this.currentColors.primary : '#CCCCCC'
                })
            }
            .onClick(() => { readerSettingsViewModel.backgroundColor = color; })
          })
        }
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Text('字体大小').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF'))
        Row({ space: 8 }) {
          ForEach(this.fontSizeOptions, (size: number) => {
            Text(size.toString())
              .fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(readerSettingsViewModel.fontSize === size ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
              .fontColor(readerSettingsViewModel.fontSize === size ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
              .borderRadius(16)
              .onClick(() => { readerSettingsViewModel.fontSize = size; })
          })
        }
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('行间距').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(readerSettingsViewModel.lineHeight.toFixed(1)).fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.lineHeight,
          min: 1.2, max: 2.5, step: 0.1, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.lineHeight = value; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('页边距').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(readerSettingsViewModel.pageMargin.toString()).fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.pageMargin,
          min: 0, max: 40, step: 4, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.pageMargin = value; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Row() {
        Text('显示页码').fontSize(16).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: readerSettingsViewModel.showPageNumber })
          .onChange((isOn: boolean) => { readerSettingsViewModel.showPageNumber = isOn; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)
    }
  }

  @Builder
  buildTTSSettings() {
    Column({ space: 20 }) {
      Row() {
        Text('TTS朗读').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: readerSettingsViewModel.enableTTS })
          .onChange((isOn: boolean) => { readerSettingsViewModel.enableTTS = isOn; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Text('语音选择').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF'))
        Row({ space: 8 }) {
          ForEach(this.voiceOptions, (voice: string) => {
            Text(voice)
              .fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(readerSettingsViewModel.selectedVoice === voice ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
              .fontColor(readerSettingsViewModel.selectedVoice === voice ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
              .borderRadius(16)
              .onClick(() => { readerSettingsViewModel.selectedVoice = voice; })
          })
        }
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('朗读速度').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(readerSettingsViewModel.ttsSpeed.toString()).fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.ttsSpeed,
          min: 0.5, max: 2.0, step: 0.1, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.ttsSpeed = value; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('朗读音量').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(Math.round(readerSettingsViewModel.ttsVolume * 100) + '%').fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.ttsVolume * 100,
          min: 0, max: 100, step: 5, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.ttsVolume = value / 100; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)
    }
  }

  @Builder
  buildComicSettings() {
    Column({ space: 20 }) {
      Column({ space: 12 }) {
        Text('漫画阅读模式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF'))
        Row({ space: 8 }) {
          Text('左右滑动').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicReadMode === 0 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicReadMode === 0 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicReadMode = 0; })
          Text('上下滑动').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicReadMode === 1 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicReadMode === 1 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicReadMode = 1; })
          Text('自动播放').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicReadMode === 2 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicReadMode === 2 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicReadMode = 2; })
        }
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('缩放模式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        }
        Row({ space: 8 }) {
          Text('适应宽度').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicScaleMode === 0 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicScaleMode === 0 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicScaleMode = 0; })
          Text('适应高度').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicScaleMode === 1 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicScaleMode === 1 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicScaleMode = 1; })
          Text('原始大小').fontSize(14).padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(readerSettingsViewModel.comicScaleMode === 2 ? this.currentColors.primary : this.bg('#F5F5F5', '#3C3C3E'))
            .fontColor(readerSettingsViewModel.comicScaleMode === 2 ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
            .borderRadius(16)
            .onClick(() => { readerSettingsViewModel.comicScaleMode = 2; })
        }
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('自动播放间隔').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(readerSettingsViewModel.autoPlayInterval + '秒').fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.autoPlayInterval,
          min: 1, max: 10, step: 1, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.autoPlayInterval = value; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)
    }
  }

  @Builder
  buildScreenSettings() {
    Column({ space: 20 }) {
      Row() {
        Text('保持屏幕常亮').fontSize(16).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: readerSettingsViewModel.keepScreenOn })
          .onChange((isOn: boolean) => { readerSettingsViewModel.keepScreenOn = isOn; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Column({ space: 12 }) {
        Row() {
          Text('屏幕亮度').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
          Text(Math.round(readerSettingsViewModel.brightness * 100) + '%').fontSize(14).fontColor(this.currentColors.primary)
        }
        Slider({
          value: readerSettingsViewModel.brightness * 100,
          min: 10, max: 100, step: 1, style: SliderStyle.OutSet
        })
          .width('100%').selectedColor(this.currentColors.primary)
          .onChange((value: number) => { readerSettingsViewModel.brightness = Math.round(value) / 100; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Row() {
        Text('全屏模式').fontSize(16).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: readerSettingsViewModel.fullScreenMode })
          .onChange((isOn: boolean) => { readerSettingsViewModel.fullScreenMode = isOn; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)

      Row() {
        Text('隐藏状态栏').fontSize(16).fontColor(this.tc('#333333', '#FFFFFF')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: readerSettingsViewModel.hideStatusBar })
          .onChange((isOn: boolean) => { readerSettingsViewModel.hideStatusBar = isOn; })
      }
      .width('100%').padding(16)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E')).borderRadius(12)
    }
  }
}