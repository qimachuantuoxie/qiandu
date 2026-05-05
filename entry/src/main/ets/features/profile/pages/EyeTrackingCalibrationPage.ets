import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct EyeTrackingCalibrationPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local calibrationStep: number = 0;
  @Local isCalibrating: boolean = false;
  private context: common.Context | null = null;

  private steps: string[] = [
    '准备阶段',
    '注视左上角',
    '注视右上角',
    '注视左下角',
    '注视右下角',
    '注视中心',
    '完成'
  ];

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
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private startCalibration(): void {
    this.isCalibrating = true;
    this.calibrationStep = 1;
    
    // Calibration process - requires actual eye tracking hardware integration
    let step = 1;
    const interval = setInterval(() => {
      step++;
      this.calibrationStep = step;
      
      if (step >= this.steps.length - 1) {
        clearInterval(interval);
        this.isCalibrating = false;
        setTimeout(() => {
          promptAction.showToast({ message: '校准完成！', duration: 2000 });
          setTimeout(() => {
            try {
              goBack();
            } catch (error) {
              const msg = error instanceof Error ? error.message : String(error);
              logger.error('[EyeTrackingCalibrationPage] back failed:', msg);
            }
          }, 1500);
        }, 1000);
      }
    }, 2000);

  build() {
    Stack() {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))

      Column() {
        // 顶部导航栏
        Row() {
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
              logger.error('[EyeTrackingCalibrationPage] back failed:', msg);
            }
          })
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })

          Text('眼动追踪校准')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank()
            .width(Size.buttonMD)
        }
        .width('100%')
        .height(Size.buttonLG + Spacing.sm)
        .padding({ left: Spacing.lg, right: Spacing.lg })
        .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
        .shadow(getShadow('sm', this.isDarkMode))

        // 内容区域
        if (!this.isCalibrating && this.calibrationStep === 0) {
          // 准备界面
          this.CalibrationIntro()
        } else if (this.isCalibrating) {
          // 校准进行中
          this.CalibrationProcess()
        } else {
          // 完成界面
          this.CalibrationComplete()
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CalibrationIntro() {
    Column({ space: Spacing.xxl }) {
      // 图标
      Column() {
        SymbolGlyph($r('sys.symbol.eye'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.currentColors.primary])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      // 标题和说明
      Column({ space: Spacing.md }) {
        Text('眼动追踪校准')
          .fontSize(fontScaleManager.getScaledFontSize(24))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Text('请按照屏幕提示，依次注视各个位置\n以完成眼动追踪校准')
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .textAlign(TextAlign.Center)
          .lineHeight(22)
      }

      // 步骤预览
      Column({ space: Spacing.sm }) {
        Text('校准步骤')
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Column({ space: Spacing.xs }) {
          ForEach(this.steps.slice(0, this.steps.length - 1), (step: string, index: number) => {
            Row({ space: Spacing.sm }) {
              Circle()
                .width(8)
                .height(8)
                .fill(this.currentColors.primary)
              
              Text(step)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
            }
            .width('100%')
          }, (step: string, index: number) => step)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: Spacing.lg })
      }
      .width('100%')
      .padding(Spacing.xl)
      .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      .borderRadius(BorderRadius.xl)
      .shadow(getShadow('md', this.isDarkMode))

      // 开始按钮
      Button() {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.play.fill'))
            .fontSize(Size.iconMD)
            .fontColor(['#FFFFFF'])
          
          Text('开始校准')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor('#FFFFFF')
        }
      }
      .width('80%')
      .height(Size.buttonLG + Spacing.sm)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
      })
      .borderRadius(BorderRadius.xl)
      .shadow({
        radius: 8,
        color: COMMON_COLORS.PRIMARY_BLUE + '40',
        offsetY: 4
      })
      .onClick(() => {
        this.startCalibration();
      })
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding(Spacing.xxl)
  }

  @Builder
  CalibrationProcess() {
    Column({ space: Spacing.xxl }) {
      // 进度指示
      Column({ space: Spacing.md }) {
        Text(this.steps[this.calibrationStep])
          .fontSize(fontScaleManager.getScaledFontSize(20))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.primary)

        Text(`步骤 ${this.calibrationStep} / ${this.steps.length - 1}`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }

      // 进度条
      Progress({ value: this.calibrationStep, total: this.steps.length - 1, type: ProgressType.Linear })
        .width('80%')
        .height(8)
        .borderRadius(BorderRadius.xl)
        .color(this.currentColors.primary)
        .backgroundColor(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.1)'))

      // 注视点
      Stack() {
        // 外圈
        Circle()
          .width(120)
          .height(120)
          .stroke(this.currentColors.primary)
          .strokeWidth(3)
          .opacity(0.3)

        // 中圈
        Circle()
          .width(80)
          .height(80)
          .stroke(this.currentColors.primary)
          .strokeWidth(3)
          .opacity(0.6)

        // 内圈
        Circle()
          .width(40)
          .height(40)
          .fill(this.currentColors.primary)

        // 动画效果
        Circle()
          .width(100)
          .height(100)
          .stroke(this.currentColors.primary)
          .strokeWidth(2)
          .opacity(0.5)
          .scale({ x: 1.2, y: 1.2 })
          .animation({
            duration: 1000,
            iterations: -1,
            curve: Curve.EaseInOut
          })
      }
      .width(150)
      .height(150)

      Text('请注视圆点')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CalibrationComplete() {
    Column({ space: Spacing.xxl }) {
      // 成功图标
      Column() {
        SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor(['#52C41A'])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor('#52C41A15')
      .justifyContent(FlexAlign.Center)

      // 完成信息
      Column({ space: Spacing.md }) {
        Text('校准完成！')
          .fontSize(fontScaleManager.getScaledFontSize(24))
          .fontWeight(FontWeight.Bold)
          .fontColor('#52C41A')

        Text('眼动追踪已成功校准\n现在可以开始使用了')
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .textAlign(TextAlign.Center)
          .lineHeight(22)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding(Spacing.xxl)
  }
}

// 预览组件
@Preview
@ComponentV2
struct EyeTrackingCalibrationPagePreview {
  build() {
    Column() {
      Text('眼动追踪校准 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      EyeTrackingCalibrationPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('眼动追踪校准 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      EyeTrackingCalibrationPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
