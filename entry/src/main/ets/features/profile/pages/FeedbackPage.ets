import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
// 鎰忚�鍙嶉�椤甸潰 - 楦胯挋鍘熺敓椋庢牸
// Feedback Page - HarmonyOS Native Style


import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { feedbackViewModel, FeedbackViewModel } from '../viewmodels/FeedbackViewModel';
import { BackButton } from '../components/common/BackButton';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface FeedbackCategory {
  id: string;
  name: string;
  icon: string;
}

@Entry
@Component
struct FeedbackPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State screenInfo: ScreenInfo | null = null;

  vm: FeedbackViewModel = feedbackViewModel;

  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      logger.info('FeedbackPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
  }

  private scaleFontSize(baseSize: number): number {
    return fontScaleManager.getScaledFontSize(baseSize);
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }
  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private async submitFeedback(): Promise<void> {
    if (!this.vm.content.trim()) {
      return;
    }

    try {
      const success = await this.vm.submit();
      if (success) {
        setTimeout(() => {
          this.vm.reset();
          try { goBack(); } catch(e) { logger.error('back error:', e); }
        }, 2000);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('Feedback submit error:', message);
    }
  }

  build() {
    Stack() {
      Column() {
        this.NavBar()

        if (this.vm.submitSuccess) {
          this.SuccessOverlay()
        }

        Scroll() {
          Column({ space: 20 }) {
            this.FeedbackTypeCard()
            this.FeedbackContentCard()
            this.ContactCard()
            this.SubmitButton()
          }
          .width('100%')
          .padding(this.isTablet ? 24 : 20)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentColors.background)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  NavBar() {
    Row() {
      BackButton({ isDarkMode: this.isDarkMode, colors: this.currentColors.textPrimary })

      Text('鎰忚�鍙嶉�')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(600)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(40)
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16 })
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.3)', 'rgba(255, 255, 255, 0.05)'))
  }

  @Builder
  SuccessOverlay() {
    Stack() {
      Column() {
        Column() {
          Text('锟?)
            .fontSize(48)
            .fontColor('#1976D2')

          Text('鎰熻阿鎮ㄧ殑鍙嶉�!')
            .fontSize(this.scaleFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)
            .margin({ top: 16 })

          Text('鎴戜滑浼氬敖蹇��鐞嗘偍鐨勬剰锟?)
            .fontSize(this.scaleFontSize(14))
            .fontColor(this.currentColors.textSecondary)
            .margin({ top: 8 })
        }
        .width('70%')
        .padding(40)
        .backgroundColor(this.bg('rgba(40, 40, 40, 0.95)', 'rgba(255, 255, 255, 0.95)'))
        .borderRadius(24)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .alignContent(Alignment.Center)
  }

  @Builder
  FeedbackTypeCard() {
    Column({ space: 16 }) {
      Text('鍙嶉�绫诲瀷')
        .fontSize(this.scaleFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.vm.categories, (type: FeedbackCategory) => {
          Column({ space: 4 }) {
            Text(type.icon)
              .fontSize(this.isTablet ? 24 : 20)

            Text(type.name)
              .fontSize(this.scaleFontSize(12))
              .fontColor(this.vm.feedbackType === type.id ? '#FFFFFF' : this.currentColors.textSecondary)
          }
          .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16, top: 12, bottom: 12 })
          .borderRadius(12)
          .backgroundColor(this.vm.feedbackType === type.id ? '#1976D2' : this.bg('rgba(255, 255, 255, 0.3)', 'rgba(255, 255, 255, 0.05)'))
          .onClick(() => {
            this.vm.setType(type.id);
          })
          .margin({ right: 12, bottom: 8 })
        }, (type: FeedbackCategory) => type.id)
      }
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 20)
    .borderRadius(16)
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.08)'))
  }

  @Builder
  FeedbackContentCard() {
    Column({ space: 12 }) {
      Row() {
        Text('鍙嶉�鍐呭�')
          .fontSize(this.scaleFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
        
        Text('*')
          .fontSize(this.scaleFontSize(16))
          .fontColor('#E53935')
          .margin({ left: 4 })
      }
      
      TextArea({ placeholder: '璇疯�缁嗘弿杩版偍鐨勯棶棰樻垨寤鸿�...' })
        .width('100%')
        .height(160)
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.currentColors.textPrimary)
        .placeholderColor(this.currentColors.textHint)
        .backgroundColor(this.bg('rgba(255, 255, 255, 0.3)', 'rgba(255, 255, 255, 0.05)'))
        .borderRadius(12)
        .padding(12)
        .onChange((value: string) => {
          this.vm.setContent(value);
        })

      Row() {
        Text(String(this.vm.content.length))
          .fontSize(12)
          .fontColor(this.currentColors.textHint)
        
        Text('/ 500')
          .fontSize(12)
          .fontColor(this.currentColors.textHint)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 20)
    .borderRadius(16)
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.08)'))
  }

  @Builder
  ContactCard() {
    Column({ space: 12 }) {
      Text('鑱旂郴鏂瑰紡锛堥€夊～锟?)
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.currentColors.textSecondary)
      
      TextInput({ placeholder: '閭��鎴栨墜鏈哄彿', text: this.vm.contact })
        .width('100%')
        .height(48)
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.currentColors.textPrimary)
        .placeholderColor(this.currentColors.textHint)
        .backgroundColor(this.bg('rgba(255, 255, 255, 0.3)', 'rgba(255, 255, 255, 0.05)'))
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.vm.setContact(value);
        })
      
      Text('鏂逛究鎴戜滑鍙婃椂鍥炲�鎮ㄧ殑鍙嶉�')
        .fontSize(12)
        .fontColor(this.currentColors.textHint)
    }
    .width('100%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.08)'))
  }

  @Builder
  SubmitButton() {
    Button(this.vm.isSubmitting ? '鎻愪氦锟?..' : '鎻愪氦鍙嶉�')
      .width('100%')
      .height(52)
      .backgroundColor(this.vm.content.trim() ? '#1976D2' : this.bg('rgba(0, 0, 0, 0.1)', 'rgba(255, 255, 255, 0.1)'))
      .fontColor(this.vm.content.trim() ? '#FFFFFF' : this.currentColors.textHint)
      .fontSize(this.scaleFontSize(16))
      .fontWeight(FontWeight.Medium)
      .borderRadius(26)
      .enabled(!this.vm.isSubmitting && !!this.vm.content.trim())
      .onClick(() => this.submitFeedback())
      .margin({ top: 12, bottom: 40 })
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct FeedbackPagePreview {
  build() {
    Column() {
      Text('鎰忚�鍙嶉�锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      FeedbackPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鎰忚�鍙嶉�锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      FeedbackPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
