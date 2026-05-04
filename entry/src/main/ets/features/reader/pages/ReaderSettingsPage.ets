import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { readerSettingsViewModel } from '../viewmodels/ReaderSettingsViewModel';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct ReaderSettingsPage {
  @Local isDarkMode: boolean = false;
  @Local activeTab: number = 0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;

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
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
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
      logger.error('[ReaderSettings] Save failed:', err.message);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 返回按钮
        Row() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconLG)
            .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
        }
        .width(Size.buttonMD)
        .height(Size.buttonMD)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[ReaderSettingsPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('阅读器设置')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 保存按钮
        Row() {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(Size.iconSM)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonSM)
        .height(Size.buttonSM)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.currentColors.primary)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.saveSettings(); })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // Tab切换栏
      Scroll() {
        Row({ space: Spacing.sm }) {
          ForEach(this.tabNames, (tab: string, index: number) => {
            Column({ space: Spacing.xs }) {
              Text(tab)
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.activeTab === index ? this.currentColors.primary : this.tc('#8E8E93', '#8E8E93'))
                .fontWeight(this.activeTab === index ? FontWeight.SemiBold : FontWeight.Regular)
              
              // 下划线指示器
              Rectangle()
                .width(this.activeTab === index ? 24 : 0)
                .height(3)
                .fill(this.currentColors.primary)
                .borderRadius(BorderRadius.xl)
                .animation({
                  duration: 200,
                  curve: Curve.EaseInOut
                })
            }
            .padding({ 
              left: Spacing.md, 
              right: Spacing.md, 
              top: Spacing.sm, 
              bottom: Spacing.sm 
            })
            .backgroundColor(this.activeTab === index ? this.currentColors.primary + '10' : 'transparent')
            .borderRadius(BorderRadius.xl)
            .onClick(() => { this.activeTab = index; })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })
          }, (tab: string, index: number) => tab)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))

      // 内容区域
      Scroll() {
        Column({ space: Spacing.lg }) {
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
        .width('100%')
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg, 
          top: Spacing.lg,
          bottom: Spacing.xxxl
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // 底部操作栏
      Row({ space: Spacing.md }) {
        Button() {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.arrow.counterclockwise'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            Text('重置')
              .fontSize(fontScaleManager.getScaledFontSize(15))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
        }
        .layoutWeight(1)
        .height(Size.buttonLG)
        .backgroundColor(this.bg('#F2F2F7', '#2C2C2E'))
        .borderRadius(BorderRadius.xl)
        .onClick(() => {
          readerSettingsViewModel.resetToDefault();
          promptAction.showToast({ message: '已重置为默认设置', duration: 1500 });
        })
        .stateStyles({
          pressed: { .scale({ x: 0.98, y: 0.98 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Button() {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
              .fontSize(Size.iconSM)
              .fontColor(['#FFFFFF'])
            Text('保存设置')
              .fontSize(fontScaleManager.getScaledFontSize(15))
              .fontColor('#FFFFFF')
          }
        }
        .layoutWeight(1)
        .height(Size.buttonLG)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [this.currentColors.primary, this.currentColors.primary + 'CC']
        })
        .borderRadius(BorderRadius.xl)
        .shadow({
          radius: 8,
          color: this.currentColors.primary + '40',
          offsetY: 4
        })
        .onClick(() => { this.saveSettings(); })
        .stateStyles({
          pressed: { .scale({ x: 0.98, y: 0.98 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .padding(Spacing.lg)
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('lg', this.isDarkMode))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: Spacing.lg }) {
      // 背景颜色选择
      Column({ space: Spacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.paintpalette'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])
          
          Text('背景颜色')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .margin({ left: Spacing.sm })
        }
        .width('100%')

        Grid() {
          ForEach(this.backgroundColorOptions, (color: string, index: number) => {
            GridItem() {
              Column({ space: Spacing.xs }) {
                // 颜色圆圈
                Stack() {
                  Circle()
                    .width(50)
                    .height(50)
                    .fill(color)
                    .shadow(getShadow('md', this.isDarkMode))
                  
                  // 选中指示器
                  if (readerSettingsViewModel.backgroundColor === color) {
                    Row() {
                      SymbolGlyph($r('sys.symbol.checkmark'))
                        .fontSize(Size.iconSM)
                        .fontColor(['#FFFFFF'])
                    }
                    .width(Size.buttonSM)
                    .height(Size.buttonSM)
                    .borderRadius(BorderRadius.full)
                    .backgroundColor(this.currentColors.primary)
                    .justifyContent(FlexAlign.Center)
                    .position({ x: 35, y: 35 })
                  }
                }

                Text(this.backgroundColorNames[index])
                  .fontSize(fontScaleManager.getScaledFontSize(12))
                  .fontColor(readerSettingsViewModel.backgroundColor === color ? 
                    this.currentColors.primary : this.tc('#8E8E93', '#8E8E93'))
                  .fontWeight(readerSettingsViewModel.backgroundColor === color ? 
                    FontWeight.Medium : FontWeight.Regular)
              }
              .onClick(() => { readerSettingsViewModel.backgroundColor = color; })
            }
          }, (color: string, index: number) => color)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))

      // 字体大小选择
      Column({ space: Spacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.textformat.size'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])
          
          Text('字体大小')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .margin({ left: Spacing.sm })
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.fontSizeOptions, (size: number) => {
            Text(size.toString())
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .padding({ 
                left: Spacing.md, 
                right: Spacing.md, 
                top: Spacing.sm, 
                bottom: Spacing.sm 
              })
              .backgroundColor(readerSettingsViewModel.fontSize === size ? 
                this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
              .fontColor(readerSettingsViewModel.fontSize === size ? 
                '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
              .borderRadius(BorderRadius.xl)
              .fontWeight(readerSettingsViewModel.fontSize === size ? 
                FontWeight.Medium : FontWeight.Regular)
              .onClick(() => { readerSettingsViewModel.fontSize = size; })
              .stateStyles({
                pressed: { .scale({ x: 0.95, y: 0.95 }) },
                normal: { .scale({ x: 1, y: 1 }) }
              })
              .margin({ right: Spacing.sm, bottom: Spacing.sm })
          }, (size: number) => size.toString())
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))

      // 行间距滑块
      Column({ space: Spacing.md }) {
        Row() {
          SymbolGlyph($r('sysymbol.textformat.line.spacing'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])
          
          Text('行间距')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .margin({ left: Spacing.sm })

          Text(readerSettingsViewModel.lineHeight.toFixed(1))
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentColors.primary)
        }
        .width('100%')

        Slider({
          value: readerSettingsViewModel.lineHeight,
          min: 1.2, max: 2.5, step: 0.1, style: SliderStyle.OutSet
        })
          .width('100%')
          .selectedColor(this.currentColors.primary)
          .trackThickness(6)
          .onChange((value: number) => { readerSettingsViewModel.lineHeight = value; })
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  buildTTSSettings() {
    Column({ space: Spacing.lg }) {
      // TTS语音选择
      Column({ space: Spacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.waveform'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])
          
          Text('TTS语音')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .margin({ left: Spacing.sm })
        }
        .width('100%')

        List({ space: Spacing.sm }) {
          ForEach(this.voiceOptions, (voice: string, index: number) => {
            ListItem() {
              Row({ space: Spacing.md }) {
                Column() {
                  SymbolGlyph($r('sys.symbol.person.fill'))
                    .fontSize(Size.iconLG)
                    .fontColor([readerSettingsViewModel.ttsVoice === voice ? 
                      this.currentColors.primary : this.tc('#8E8E93', '#8E8E93')])
                }
                .width(Size.avatarMD)
                .height(Size.avatarMD)
                .borderRadius(BorderRadius.full)
                .backgroundColor(readerSettingsViewModel.ttsVoice === voice ? 
                  this.currentColors.primary + '15' : this.bg('#F2F2F7', '#2C2C2E'))
                .justifyContent(FlexAlign.Center)

                Text(voice)
                  .fontSize(fontScaleManager.getScaledFontSize(15))
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                  .layoutWeight(1)

                if (readerSettingsViewModel.ttsVoice === voice) {
                  SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
                    .fontSize(Size.iconMD)
                    .fontColor([this.currentColors.primary])
                }
              }
              .width('100%')
              .padding(Spacing.lg)
              .backgroundColor(readerSettingsViewModel.ttsVoice === voice ? 
                this.currentColors.primary + '08' : 'transparent')
              .borderRadius(BorderRadius.lg)
              .onClick(() => { readerSettingsViewModel.ttsVoice = voice; })
            }
          }, (voice: string, index: number) => voice)
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  buildComicSettings() {
    Column({ space: Spacing.lg }) {
      Text('漫画阅读设置')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .width('100%')

      Column() {
        Text('功能开发中...')
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .padding(Spacing.xl)
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  buildScreenSettings() {
    Column({ space: Spacing.lg }) {
      Text('屏幕设置')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .width('100%')

      Column() {
        Text('功能开发中...')
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .padding(Spacing.xl)
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }
}

// 预览组件
@Preview
@ComponentV2
struct ReaderSettingsPagePreview {
  build() {
    Column() {
      Text('阅读器设置 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ReaderSettingsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读器设置 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ReaderSettingsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
