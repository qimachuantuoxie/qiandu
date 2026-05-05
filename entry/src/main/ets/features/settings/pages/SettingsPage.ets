import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

interface SettingItem {
  icon: string;
  title: string;
  subtitle?: string;
  value?: string;
  type: 'toggle' | 'select' | 'link' | 'slider';
  action?: () => void;
}

@Entry
@ComponentV2
struct SettingsPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local activeTab: number = 0;
  private context: common.Context | null = null;

  private tabNames: string[] = ['通用', '阅读', '显示'];

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
      await themeManager.init(this.context);
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Column() {
      // 顶部导航栏
      PageHeader({
        title: '设置',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[SettingsPage] back failed:', msg);
          }
        }
      })

      // Tab切换
      Row({ space: HDSSpacing.sm }) {
        ForEach(this.tabNames, (tab: string, index: number) => {
          Column({ space: HDSSpacing.xs }) {
            Text(tab)
              .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
              .fontColor(this.activeTab === index ? HDSColours.primary.blue : this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
              .fontWeight(this.activeTab === index ? FontWeight.SemiBold : FontWeight.Regular)
            
            Rectangle()
              .width(this.activeTab === index ? 24 : 0)
              .height(3)
              .fill(HDSColours.primary.blue)
              .borderRadius(HDSBorderRadius.xl)
              .animation({ duration: 200, curve: Curve.EaseInOut })
          }
          .padding({ 
            left: HDSSpacing.md, 
            right: HDSSpacing.md, 
            top: HDSSpacing.sm, 
            bottom: HDSSpacing.sm 
          })
          .backgroundColor(this.activeTab === index ? HDSColours.primary.blue + '10' : 'transparent')
          .borderRadius(HDSBorderRadius.xl)
          .onClick(() => { this.activeTab = index; })
          .animation({ duration: 200, curve: Curve.EaseInOut })
        }, (tab: string, index: number) => tab)
      }
      .width('100%')
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg, top: HDSSpacing.md })
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)

      // 内容区域
      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          if (this.activeTab === 0) {
            this.buildGeneralSettings()
          } else if (this.activeTab === 1) {
            this.buildReadingSettings()
          } else {
            this.buildDisplaySettings()
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  buildGeneralSettings() {
    Column({ space: HDSSpacing.lg }) {
      // 账号设置
      HDSCard({
        padding: 0,
        content: () => {
          this.SettingItem('person.circle.fill', '账号管理', '查看和管理您的账号信息', 'link', () => {
            navigateTo('pages/LoginPage');
          })
        }
      })

      // 数据与存储
      HDSCard({
        padding: 0,
        content: () => {
          Column() {
            this.SettingItem('externaldrive.fill', '清除缓存', '释放存储空间', 'link', () => {
              DialogHelper.success('缓存已清除');
            })
            
            Divider()
              .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
              .strokeWidth(0.5)
              .margin({ left: 40 + HDSSpacing.lg * 2 })

            this.SettingItem('icloud.fill', '备份与恢复', '同步阅读进度和数据', 'link', () => {
              DialogHelper.info('功能开发中');
            })
          }
        }
      })

      // 关于
      HDSCard({
        padding: 0,
        content: () => {
          Column() {
            this.SettingItem('info.circle.fill', '关于我们', '千读阅界 v1.0.0', 'link', () => {
              DialogHelper.info('千读阅界 - 专业阅读器');
            })
            
            Divider()
              .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
              .strokeWidth(0.5)
              .margin({ left: 40 + HDSSpacing.lg * 2 })

            this.SettingItem('doc.text', '用户协议', '', 'link', () => {
              navigateTo('pages/UserAgreementPage');
            })
            
            Divider()
              .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
              .strokeWidth(0.5)
              .margin({ left: 40 + HDSSpacing.lg * 2 })

            this.SettingItem('shield.checkered', '隐私政策', '', 'link', () => {
              navigateTo('pages/PrivacyPolicyPage');
            })
          }
        }
      })
    }
  }

  @Builder
  buildReadingSettings() {
    Column({ space: Spacing.lg }) {
      // 阅读偏好
      Column() {
        this.SettingItem('book.fill', '默认字体大小', '当前: 18px', 'select', () => {
          navigateTo('pages/ReaderSettingsPage');
        })
        
        Divider()
          .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
          .strokeWidth(0.5)
          .margin({ left: Size.avatarMD + Spacing.lg * 2 })

        this.SettingItem('textformat.size', '行间距', '当前: 1.6', 'select', () => {
          navigateTo('pages/ReaderSettingsPage');
        })
        
        Divider()
          .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
          .strokeWidth(0.5)
          .margin({ left: Size.avatarMD + Spacing.lg * 2 })

        this.SettingItem('paintpalette', '背景主题', '白天模式', 'select', () => {
          navigateTo('pages/ReaderSettingsPage');
        })
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))

      // TTS设置
      Column() {
        this.SettingItem('waveform', 'TTS语音', '晓晓', 'select', () => {
          navigateTo('pages/ReaderSettingsPage');
        })
        
        Divider()
          .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
          .strokeWidth(0.5)
          .margin({ left: Size.avatarMD + Spacing.lg * 2 })

        this.ToggleSettingItem('speaker.wave.2.fill', '自动朗读', '打开书籍时自动开始朗读', false, (value: boolean) => {
          promptAction.showToast({ message: `自动朗读: ${value ? '开启' : '关闭'}`, duration: 1500 });
        })
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: Spacing.lg }) {
      // 主题设置
      Column() {
        this.ToggleSettingItem('moon.fill', '深色模式', '使用深色主题保护眼睛', this.isDarkMode, async (value: boolean) => {
          await themeManager.setDarkMode(value);
          this.isDarkMode = value;
          this.currentColors = themeManager.getColors();
        })
        
        Divider()
          .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
          .strokeWidth(0.5)
          .margin({ left: Size.avatarMD + Spacing.lg * 2 })

        this.SettingItem('sun.max.fill', '跟随系统', '根据系统设置自动切换', 'toggle', () => {
          promptAction.showToast({ message: '功能开发中', duration: 1500 });
        })
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))

      // 字体缩放
      Column() {
        Row({ space: Spacing.md }) {
          Column() {
            SymbolGlyph($r('sys.symbol.textformat.size'))
              .fontSize(Size.iconLG)
              .fontColor([this.currentColors.primary])
          }
          .width(Size.avatarMD)
          .height(Size.avatarMD)
          .borderRadius(BorderRadius.lg)
          .backgroundColor(this.currentColors.primary + '15')
          .justifyContent(FlexAlign.Center)

          Column({ space: Spacing.xs }) {
            Text('字体缩放')
              .fontSize(fontScaleManager.getScaledFontSize(15))
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            
            Text(`当前: ${(this.fontScale * 100).toFixed(0)}%`)
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.lg)

        Slider({
          value: this.fontScale,
          min: 0.8, max: 1.5, step: 0.1, style: SliderStyle.OutSet
        })
          .width('100%')
          .selectedColor(this.currentColors.primary)
          .trackThickness(6)
          .padding({ left: Spacing.lg, right: Spacing.lg })
          .onChange(async (value: number) => {
            this.fontScale = value;
            await fontScaleManager.setFontScale(value);
          })
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('sm', this.isDarkMode))
    }
  }

  @Builder
  SettingItem(iconName: string, title: string, subtitle: string, type: string, action?: () => void) {
    Row({ space: Spacing.md }) {
      // 图标
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
      }
      .width(Size.avatarMD)
      .height(Size.avatarMD)
      .borderRadius(BorderRadius.lg)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      // 文本
      Column({ space: Spacing.xs }) {
        Text(title)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        
        if (subtitle) {
          Text(subtitle)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧指示器
      if (type === 'link') {
        SymbolGlyph($r('sys.symbol.chevron.right'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#C7C7CC', '#48484A')])
      } else if (type === 'select') {
        Row() {
          Text('选择')
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontColor(this.currentColors.primary)
          
          SymbolGlyph($r('sys.symbol.chevron.right'))
            .fontSize(Size.iconXS)
            .fontColor([this.currentColors.primary])
            .margin({ left: Spacing.xs })
        }
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .onClick(() => {
      if (action) {
        action();
      }
    })
    .stateStyles({
      pressed: { 
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .backgroundColor('transparent')
      }
    })
  }

  @Builder
  ToggleSettingItem(iconName: string, title: string, subtitle: string, value: boolean, onToggle: (value: boolean) => void) {
    Row({ space: Spacing.md }) {
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
      }
      .width(Size.avatarMD)
      .height(Size.avatarMD)
      .borderRadius(BorderRadius.lg)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      Column({ space: Spacing.xs }) {
        Text(title)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        
        Text(subtitle)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Toggle开关
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(this.currentColors.primary)
        .onChange((isOn: boolean) => {
          onToggle(isOn);
        })
    }
    .width('100%')
    .padding(Spacing.lg)
  }
}

// 预览组件
@Preview
@ComponentV2
struct SettingsPagePreview {
  build() {
    Column() {
      Text('设置页面 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      SettingsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('设置页面 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SettingsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
