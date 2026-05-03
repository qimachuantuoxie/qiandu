/**
 * 眼动追踪校准页面
 * Eye Tracking Calibration Page
 * 
 * 引导用户注视屏幕上的校准点，完成眼动追踪校准
 */

import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { eyeTrackingService, EyeTrackingState, GazeDirection } from '../services/ai/EyeTrackingService';
import { themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

interface CalibrationPoint {
  x: number;
  y: number;
  label: string;
}

@Entry
@Component
export struct EyeTrackingCalibrationPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  
  @State currentStep: number = 0;
  @State totalSteps: number = 5;
  @State isCalibrating: boolean = false;
  @State calibrationProgress: number = 0;
  @State showGuide: boolean = true;
  @State calibrationComplete: boolean = false;
  @State calibrationPoints: CalibrationPoint[] = [];
  @State private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = false;
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  build() {
    Column() {
      // 标题栏
      this.buildHeader()

      if (this.showGuide) {
        // 引导页面
        this.buildGuidePage()
      } else if (this.calibrationComplete) {
        // 校准完成页面
        this.buildCompletePage()
      } else {
        // 校准进行中
        this.buildCalibrationView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentColors.background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildHeader() {
    Row() {
      Button('返回')
        .width(80)
        .height(40)
        .fontSize(14 * this.fontScale)
        .backgroundColor(this.currentColors.surface)
        .fontColor(this.currentColors.textPrimary)
        .onClick(() => {
          try { router.back(); } catch(e) { console.error('back error:', e); }
        })

      Text('眼动追踪校准')
        .layoutWeight(1)
        .fontSize(20 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .textAlign(TextAlign.Center)

      Text(this.currentStep > 0 ? (this.currentStep + '/' + this.totalSteps) : '')
        .width(80)
        .fontSize(14 * this.fontScale)
        .fontColor(this.currentColors.textSecondary)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.currentColors.surface)
  }

  @Builder
  buildGuidePage() {
    Column() {
      Text('eye')
        .fontSize(80)
        .margin({ top: 60 })

      Text('眼动追踪校准')
        .fontSize(24 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .margin({ top: 24 })

      Text('校准可以帮助系统更准确地识别您的视线位置')
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })
        .padding({ left: 32, right: 32 })

      Column({ space: 16 }) {
        this.buildGuideItem('1️⃣', '保持正常坐姿，面对屏幕')
        this.buildGuideItem('2️⃣', '当圆点出现时，请注视圆点')
        this.buildGuideItem('3️⃣', '保持注视 3 秒钟')
        this.buildGuideItem('4️⃣', '完成 5 个位置的校准')
      }
      .margin({ top: 40 })
      .padding(24)
      .backgroundColor(this.currentColors.surface)
      .borderRadius(12)
      .width('90%')

      Button('开始校准')
        .width('80%')
        .height(50)
        .fontSize(18 * this.fontScale)
        .margin({ top: 60 })
        .onClick(() => {
          this.startCalibration();
        })
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  buildGuideItem(icon: string, text: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(24)

      Text(text)
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  buildCalibrationView() {
    Stack() {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.currentColors.background)

      // 进度指示
      Column() {
        Text('校准进度')
          .fontSize(16 * this.fontScale)
          .fontColor(this.currentColors.textPrimary)
          .margin({ bottom: 8 })

        Progress({ value: this.calibrationProgress, total: 100 })
          .width('80%')
          .height(8)
          .color(this.currentColors.primary)
          .backgroundColor(this.currentColors.background)

        Text(Math.round(this.calibrationProgress) + '%')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.textSecondary)
          .margin({ top: 4 })
      }
      .position({ x: '10%', y: 20 })

      // 校准点
      this.CalibrationPoint()

      // 提示信息
      Column() {
        Text('请注视圆点')
          .fontSize(20 * this.fontScale)
          .fontColor(this.currentColors.textPrimary)
          .fontWeight(FontWeight.Bold)

        Text(this.calibrationPoints[this.currentStep].label)
          .fontSize(16 * this.fontScale)
          .fontColor(this.currentColors.textSecondary)
          .margin({ top: 8 })
      }
      .position({ x: '35%', y: '85%' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CalibrationPoint() {
    Circle()
      .width(60)
      .height(60)
      .fill(this.currentColors.primary)
      .opacity(0.3)
      .position({
        x: this.calibrationPoints[this.currentStep].x / 100 * 400 - 30,
        y: this.calibrationPoints[this.currentStep].y / 100 * 800 - 30
      })

    Circle()
      .width(30)
      .height(30)
      .fill(this.currentColors.primary)
      .position({
        x: this.calibrationPoints[this.currentStep].x / 100 * 400 - 15,
        y: this.calibrationPoints[this.currentStep].y / 100 * 800 - 15
      })
  }

  @Builder
  buildCompletePage() {
    Column() {
      Text('checkmark_circle_fill')
        .fontSize(80)
        .margin({ top: 60 })

      Text('校准完成！')
        .fontSize(24 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .margin({ top: 24 })

      Text('眼动追踪已准备就绪')
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.textSecondary)
        .margin({ top: 12 })

      Button('开始使用')
        .width('80%')
        .height(50)
        .fontSize(18 * this.fontScale)
        .margin({ top: 60 })
        .onClick(() => {
          try { router.back(); } catch(e) { console.error('back error:', e); }
        })
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private async startCalibration(): Promise<void> {
    this.showGuide = false;
    this.isCalibrating = true;
    this.currentStep = 0;
    this.calibrationProgress = 0;

    try {
      // 初始化服务
      const context = this.context;
      if (context) {
        await eyeTrackingService.init(context);
      }

      // 设置手势监听
      eyeTrackingService.setGestureListener((gesture) => {
        console.info('[Calibration] Gesture:', gesture.direction);
      });

      // 开始校准
      const success = await eyeTrackingService.startCalibration();

      if (success) {
        this.calibrationComplete = true;
        try { promptAction.showToast({
          message: '校准成功',
          duration: 2000
        }); } catch(e) { console.error('showToast error:', e); }
      } else {
        try { promptAction.showToast({
          message: '校准失败，请重试',
          duration: 2000
        }); } catch(e) { console.error('showToast error:', e); }
        this.showGuide = true;
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[Calibration] Failed:', message);
      try { promptAction.showToast({
        message: '校准失败：' + message,
        duration: 3000
      }); } catch(se) { console.error('showToast error:', se); }
      this.showGuide = true;
    } finally {
      this.isCalibrating = false;
    }
  }
}
