// 意见反馈页面 - 鸿蒙原生风格
// Feedback Page - HarmonyOS Native Style

import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';
import { feedbackViewModel, FeedbackViewModel } from '../viewmodels/FeedbackViewModel';

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

  vm: FeedbackViewModel = feedbackViewModel;

  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      console.info('FeedbackPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet();
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
          try { router.back(); } catch(e) { console.error('back error:', e); }
        }, 2000);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('Feedback submit error:', message);
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
      Button() {
        Text('←')
          .fontSize(this.scaleFontSize(20))
          .fontColor(this.currentColors.textPrimary)
      }
      .width(40)
      .height(40)
      .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })

      Text('意见反馈')
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
          Text('✓')
            .fontSize(48)
            .fontColor('#1976D2')

          Text('感谢您的反馈!')
            .fontSize(this.scaleFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)
            .margin({ top: 16 })

          Text('我们会尽快处理您的意见')
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
      Text('反馈类型')
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
        Text('反馈内容')
          .fontSize(this.scaleFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
        
        Text('*')
          .fontSize(this.scaleFontSize(16))
          .fontColor('#E53935')
          .margin({ left: 4 })
      }
      
      TextArea({ placeholder: '请详细描述您的问题或建议...' })
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
      Text('联系方式（选填）')
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.currentColors.textSecondary)
      
      TextInput({ placeholder: '邮箱或手机号', text: this.vm.contact })
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
      
      Text('方便我们及时回复您的反馈')
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
    Button(this.vm.isSubmitting ? '提交中...' : '提交反馈')
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
