import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
/**
 * 閻�厧濮╂潻鍊熼嚋閺嶁€冲櫙妞ょ敻娼?
 * Eye Tracking Calibration Page
 * 
 * 瀵�洖顕遍悽銊﹀煕濞夈劏顫嬬仦蹇撶�娑撳﹦娈戦弽鈥冲櫙閻愮櫢绱濈€瑰本鍨氶惇鐓庡З鏉╁€熼嚋閺嶁€冲櫙
 */

import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { eyeTrackingService, EyeTrackingState, GazeDirection } from '../core/services/ai/EyeTrackingService';
import { themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = false;
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    this.fontScale = await fontScaleManager.getFontScale();
  }

  build() {
    Column() {
      // 閺嶅洭顣介弽?
      this.buildHeader()

      if (this.showGuide) {
        // 瀵�洖顕辨い鐢告桨
        this.buildGuidePage()
      } else if (this.calibrationComplete) {
        // 閺嶁€冲櫙鐎瑰本鍨氭い鐢告桨
        this.buildCompletePage()
      } else {
        // 閺嶁€冲櫙鏉╂稖顢戞稉?
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
      Button('鏉╂柨娲?)
        .width(80)
        .height(40)
        .fontSize(14 * this.fontScale)
        .backgroundColor(this.currentColors.surface)
        .fontColor(this.currentColors.textPrimary)
        .onClick(() => {
          try { goBack(); } catch(e) { logger.error('back error:', e); }
        })

      Text('閻�厧濮╂潻鍊熼嚋閺嶁€冲櫙')
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

      Text('閻�厧濮╂潻鍊熼嚋閺嶁€冲櫙')
        .fontSize(24 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .margin({ top: 24 })

      Text('閺嶁€冲櫙閸欘垯浜掔敮顔煎И缁�崵绮洪弴鏉戝櫙绾�喖婀寸拠鍡楀焼閹�劎娈戠憴鍡欏殠娴ｅ秶鐤?)
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })
        .padding({ left: 32, right: 32 })

      Column({ space: 16 }) {
        this.buildGuideItem('1.circle', '娣囨繃瀵斿�锝呯埗閸ф劕协閿涘矂娼扮€电懓鐫嗛獮?)
        this.buildGuideItem('2.circle', '瑜版挸娓鹃悙鐟板毉閻滅増妞傞敍宀冾嚞濞夈劏顫嬮崷鍡欏仯')
        this.buildGuideItem('3.circle', '娣囨繃瀵斿▔銊�潒 3 缁夋帡鎸?)
        this.buildGuideItem('4.circle', '鐎瑰本鍨?5 娑擃亙缍呯純顔炬畱閺嶁€冲櫙')
      }
      .margin({ top: 40 })
      .padding(24)
      .backgroundColor(this.currentColors.surface)
      .borderRadius(12)
      .width('90%')

      Button('瀵�偓婵��鐗庨崙?)
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
      // 閼冲本娅?
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.currentColors.background)

      // 鏉╂稑瀹抽幐鍥┿仛
      Column() {
        Text('閺嶁€冲櫙鏉╂稑瀹?)
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

      // 閺嶁€冲櫙閻?
      this.CalibrationPoint()

      // 閹绘劗銇氭穱鈩冧紖
      Column() {
        Text('鐠囬攱鏁炵憴鍡楁妇閻?)
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

      Text('閺嶁€冲櫙鐎瑰本鍨氶敍?)
        .fontSize(24 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .margin({ top: 24 })

      Text('閻�厧濮╂潻鍊熼嚋瀹告彃鍣�径鍥ф皑缂?)
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.textSecondary)
        .margin({ top: 12 })

      Button('瀵�偓婵��濞囬悽?)
        .width('80%')
        .height(50)
        .fontSize(18 * this.fontScale)
        .margin({ top: 60 })
        .onClick(() => {
          try { goBack(); } catch(e) { logger.error('back error:', e); }
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
      // 閸掓繂顫愰崠鏍ㄦ箛閸?
      const context = this.context;
      if (context) {
        await eyeTrackingService.init(context);
      }

      // 鐠佸墽鐤嗛幍瀣�◢閻╂垵鎯?
      eyeTrackingService.setGestureListener((gesture) => {
        logger.info('[Calibration] Gesture:', gesture.direction);
      });

      // 瀵�偓婵��鐗庨崙?
      const success = await eyeTrackingService.startCalibration();

      if (success) {
        this.calibrationComplete = true;
        try { promptAction.showToast({
          message: '閺嶁€冲櫙閹存劕濮?,
          duration: 2000
        }); } catch(e) { logger.error('showToast error:', e); }
      } else {
        try { promptAction.showToast({
          message: '閺嶁€冲櫙婢惰精瑙﹂敍宀冾嚞闁插秷鐦?,
          duration: 2000
        }); } catch(e) { logger.error('showToast error:', e); }
        this.showGuide = true;
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      logger.error('[Calibration] Failed:', message);
      try { promptAction.showToast({
        message: '閺嶁€冲櫙婢惰精瑙﹂敍? + message,
        duration: 3000
      }); } catch(se) { logger.error('showToast error:', se); }
      this.showGuide = true;
    } finally {
      this.isCalibrating = false;
    }
  }
}

// 妫板嫯顫嶇紒鍕�� - 閻€劋绨珼evEco Studio妫板嫯顫嶉崳?
@Preview
@Component
struct EyeTrackingCalibrationPagePreview {
  build() {
    Column() {
      Text('閻�厧濮╂潻鍊熼嚋閺嶁€冲櫙妞?- 濞村懓澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      EyeTrackingCalibrationPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('閻�厧濮╂潻鍊熼嚋閺嶁€冲櫙妞?- 濞ｈ精澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      EyeTrackingCalibrationPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
