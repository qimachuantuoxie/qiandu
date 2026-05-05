import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { readerSettingsViewModel } from '../viewmodels/ReaderSettingsViewModel';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

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
      PageHeader({
        title: '阅读器设置',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[ReaderSettingsPage] back failed:', msg);
          }
        },
        rightContent: () => {
          Row() {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(16)
              .fontColor([HDSColours.neutral.white])
          }
          .width(32)
          .height(32)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(HDSColours.primary.blue)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.saveSettings(); })
        }
      })

      // Tab切换栏
      Scroll() {
        Row({ space: HDSSpacing.sm }) {
          ForEach(this.tabNames, (tab: string, index: number) => {
            Column({ space: HDSSpacing.xs }) {
              Text(tab)
                .fontSize(HDSTypography.sizes.md)
                .fontColor(this.activeTab === index ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
                .fontWeight(this.activeTab === index ? FontWeight.SemiBold : FontWeight.Regular)
              
              // 下划线指示器
              Rectangle()
                .width(this.activeTab === index ? 24 : 0)
                .height(3)
                .fill(HDSColours.primary.blue)
                .borderRadius(HDSBorderRadius.xl)
                .animation({
                  duration: 200,
                  curve: Curve.EaseInOut
                })
            }
            .padding({ 
              left: HDSSpacing.md, 
              right: HDSSpacing.md, 
              top: HDSSpacing.sm, 
              bottom: HDSSpacing.sm 
            })
            .backgroundColor(this.activeTab === index ? HDSColours.primary.blue + '10' : Color.Transparent)
            .borderRadius(HDSBorderRadius.xl)
            .onClick(() => { this.activeTab = index; })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })
          }, (tab: string, index: number) => tab)
        }
        .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)

      // 内容区域
      Scroll() {
        Column({ space: HDSSpacing.lg }) {
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
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg, 
          top: HDSSpacing.lg,
          bottom: HDSSpacing.xxxl
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // 底部操作栏
      Row({ space: HDSSpacing.md }) {
        Button() {
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.arrow.counterclockwise'))
              .fontSize(16)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            Text('重置')
              .fontSize(HDSTypography.sizes.md)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          }
        }
        .layoutWeight(1)
        .height(48)
        .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F2F2F7')
        .borderRadius(HDSBorderRadius.xl)
        .onClick(() => {
          readerSettingsViewModel.resetToDefault();
          DialogHelper.success('已重置为默认设置');
        })

        Button() {
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
              .fontSize(16)
              .fontColor([HDSColours.neutral.white])
            Text('保存设置')
              .fontSize(HDSTypography.sizes.md)
              .fontColor(HDSColours.neutral.white)
          }
        }
        .layoutWeight(1)
        .height(48)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
        })
        .borderRadius(HDSBorderRadius.xl)
        .shadow({
          radius: 8,
          color: HDSColours.primary.blue + '40',
          offsetY: 4
        })
        .onClick(() => { this.saveSettings(); })
      }
      .width('100%')
      .padding(HDSPacing.lg)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: HDSSpacing.lg }) {
      // 背景颜色选择
      Column({ space: HDSSpacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.paintpalette'))
            .fontSize(20)
            .fontColor([HDSColours.primary.blue])
          
          Text('背景颜色')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .layoutWeight(1)
            .margin({ left: HDSSpacing.sm })
        }
        .width('100%')

        Grid() {
          ForEach(this.backgroundColorOptions, (color: string, index: number) => {
            GridItem() {
              Column({ space: HDSSpacing.xs }) {
                // 颜色圆圈
                Stack() {
                  Circle()
                    .width(50)
                    .height(50)
                    .fill(color)
                  
                  // 选中指示器
                  if (readerSettingsViewModel.backgroundColor === color) {
                    Row() {
                      SymbolGlyph($r('sys.symbol.checkmark'))
                        .fontSize(16)
                        .fontColor([HDSColours.neutral.white])
                    }
                    .width(32)
                    .height(32)
                    .borderRadius(HDSBorderRadius.full)
                    .backgroundColor(HDSColours.primary.blue)
                    .justifyContent(FlexAlign.Center)
                    .position({ x: 35, y: 35 })
                  }
                }

                Text(this.backgroundColorNames[index])
                  .fontSize(HDSTypography.sizes.sm)
                  .fontColor(readerSettingsViewModel.backgroundColor === color ? 
                    HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
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
      .padding(HDSPacing.xl)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)

      // 字体大小选择
      Column({ space: HDSSpacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.textformat.size'))
            .fontSize(20)
            .fontColor([HDSColours.primary.blue])
          
          Text('字体大小')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .layoutWeight(1)
            .margin({ left: HDSSpacing.sm })
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.fontSizeOptions, (size: number) => {
            Text(size.toString())
              .fontSize(HDSTypography.sizes.md)
              .padding({ 
                left: HDSSpacing.md, 
                right: HDSSpacing.md, 
                top: HDSSpacing.sm, 
                bottom: HDSSpacing.sm 
              })
              .backgroundColor(readerSettingsViewModel.fontSize === size ? 
                HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F2F2F7'))
              .fontColor(readerSettingsViewModel.fontSize === size ? 
                HDSColours.neutral.white : (this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900))
              .borderRadius(HDSBorderRadius.xl)
              .fontWeight(readerSettingsViewModel.fontSize === size ? 
                FontWeight.Medium : FontWeight.Regular)
              .onClick(() => { readerSettingsViewModel.fontSize = size; })
              .margin({ right: HDSSpacing.sm, bottom: HDSSpacing.sm })
          }, (size: number) => size.toString())
        }
        .width('100%')
      }
      .width('100%')
      .padding(HDSPacing.xl)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)

      // 行间距滑块
      Column({ space: HDSSpacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.textformat.line.spacing'))
            .fontSize(20)
            .fontColor([HDSColours.primary.blue])
          
          Text('行间距')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .layoutWeight(1)
            .margin({ left: HDSSpacing.sm })

          Text(readerSettingsViewModel.lineHeight.toFixed(1))
            .fontSize(HDSTypography.sizes.md)
            .fontWeight(FontWeight.Medium)
            .fontColor(HDSColours.primary.blue)
        }
        .width('100%')

        Slider({
          value: readerSettingsViewModel.lineHeight,
          min: 1.2, max: 2.5, step: 0.1, style: SliderStyle.OutSet
        })
          .width('100%')
          .selectedColor(HDSColours.primary.blue)
          .trackThickness(6)
          .onChange((value: number) => { readerSettingsViewModel.lineHeight = value; })
      }
      .width('100%')
      .padding(HDSPacing.xl)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)
    }
  }

  @Builder
  buildTTSSettings() {
    Column({ space: HDSSpacing.lg }) {
      // TTS语音选择
      Column({ space: HDSSpacing.md }) {
        Row() {
          SymbolGlyph($r('sys.symbol.waveform'))
            .fontSize(20)
            .fontColor([HDSColours.primary.blue])
          
          Text('TTS语音')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .layoutWeight(1)
            .margin({ left: HDSSpacing.sm })
        }
        .width('100%')

        List({ space: HDSSpacing.sm }) {
          ForEach(this.voiceOptions, (voice: string, index: number) => {
            ListItem() {
              Row({ space: HDSSpacing.md }) {
                Column() {
                  SymbolGlyph($r('sys.symbol.person.fill'))
                    .fontSize(24)
                    .fontColor([readerSettingsViewModel.ttsVoice === voice ? 
                      HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)])
                }
                .width(40)
                .height(40)
                .borderRadius(HDSBorderRadius.full)
                .backgroundColor(readerSettingsViewModel.ttsVoice === voice ? 
                  HDSColours.primary.blue + '15' : (this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F2F2F7'))
                .justifyContent(FlexAlign.Center)

                Text(voice)
                  .fontSize(HDSTypography.sizes.md)
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                  .layoutWeight(1)

                if (readerSettingsViewModel.ttsVoice === voice) {
                  SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
                    .fontSize(20)
                    .fontColor([HDSColours.primary.blue])
                }
              }
              .width('100%')
              .padding(HDSPacing.lg)
              .backgroundColor(readerSettingsViewModel.ttsVoice === voice ? 
                HDSColours.primary.blue + '08' : Color.Transparent)
              .borderRadius(HDSBorderRadius.lg)
              .onClick(() => { readerSettingsViewModel.ttsVoice = voice; })
            }
          }, (voice: string, index: number) => voice)
        }
        .width('100%')
      }
      .width('100%')
      .padding(HDSPacing.xl)
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)
    }
  }

  @Builder
  buildComicSettings() {
    Column({ space: HDSSpacing.lg }) {
      Text('漫画阅读设置')
        .fontSize(HDSTypography.sizes.xl)
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .width('100%')

      Column() {
        Text('功能开发中...')
          .fontSize(HDSTypography.sizes.md)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          .padding(HDSPacing.xl)
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)
    }
  }

  @Builder
  buildScreenSettings() {
    Column({ space: HDSSpacing.lg }) {
      Text('屏幕设置')
        .fontSize(HDSTypography.sizes.xl)
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .width('100%')

      Column() {
        Text('功能开发中...')
          .fontSize(HDSTypography.sizes.md)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          .padding(HDSPacing.xl)
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#FFFFFF')
      .borderRadius(HDSBorderRadius.xl)
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
