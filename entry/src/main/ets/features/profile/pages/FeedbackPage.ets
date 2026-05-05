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
struct FeedbackPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local feedbackType: string = '问题反馈';
  @Local feedbackContent: string = '';
  @Local contactInfo: string = '';
  @Local isSubmitting: boolean = false;
  private context: common.Context | null = null;

  private feedbackTypes: string[] = ['问题反馈', '功能建议', '内容举报', '其他'];

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

  private handleSubmit(): void {
    if (!this.feedbackContent.trim()) {
      promptAction.showToast({ message: '请输入反馈内容', duration: 2000 });
      return;
    }

    this.isSubmitting = true;
    
    setTimeout(() => {
      this.isSubmitting = false;
      promptAction.showToast({ message: '提交成功，感谢您的反馈！', duration: 2000 });
      
      setTimeout(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[FeedbackPage] back failed:', msg);
        }
      }, 1500);
    }, 1500);
  }

  build() {
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
            logger.error('[FeedbackPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('意见反馈')
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

      // 表单区域
      Scroll() {
        Column({ space: Spacing.lg }) {
          // 反馈类型选择
          Column({ space: Spacing.md }) {
            Row() {
              SymbolGlyph($r('sys.symbol.tag.fill'))
                .fontSize(Size.iconMD)
                .fontColor([this.currentColors.primary])
              
              Text('反馈类型')
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontWeight(FontWeight.SemiBold)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .layoutWeight(1)
                .margin({ left: Spacing.sm })
            }
            .width('100%')

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.feedbackTypes, (type: string) => {
                Text(type)
                  .fontSize(fontScaleManager.getScaledFontSize(14))
                  .padding({ 
                    left: Spacing.lg, 
                    right: Spacing.lg, 
                    top: Spacing.md, 
                    bottom: Spacing.md 
                  })
                  .backgroundColor(this.feedbackType === type ? 
                    this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
                  .fontColor(this.feedbackType === type ? 
                    '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
                  .borderRadius(BorderRadius.xl)
                  .fontWeight(this.feedbackType === type ? 
                    FontWeight.Medium : FontWeight.Regular)
                  .onClick(() => { this.feedbackType = type; })
                  .stateStyles({
                    pressed: { .scale({ x: 0.95, y: 0.95 }) },
                    normal: { .scale({ x: 1, y: 1 }) }
                  })
                  .margin({ right: Spacing.sm, bottom: Spacing.sm })
              }, (type: string) => type)
            }
            .width('100%')
          }
          .width('100%')
          .padding(Spacing.xl)
          .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
          .borderRadius(BorderRadius.xl)
          .shadow(getShadow('sm', this.isDarkMode))

          // 反馈内容
          Column({ space: Spacing.md }) {
            Row() {
              SymbolGlyph($r('sys.symbol.text.bubble'))
                .fontSize(Size.iconMD)
                .fontColor([this.currentColors.primary])
              
              Text('反馈内容')
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontWeight(FontWeight.SemiBold)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .layoutWeight(1)
                .margin({ left: Spacing.sm })

              Text(this.feedbackContent.length + '/500')
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(this.feedbackContent.length > 450 ? '#FF4D4F' : this.tc('#8E8E93', '#8E8E93'))
            }
            .width('100%')

            TextArea({ text: $$this.feedbackContent, placeholder: '请详细描述您遇到的问题或建议...' })
              .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .height(150)
              .backgroundColor(this.bg('#F8F9FA', '#2C2C2E'))
              .borderRadius(BorderRadius.lg)
              .padding(Spacing.md)
              .maxLength(500)
              .onChange((value: string) => {
                this.feedbackContent = value;
              })
          }
          .width('100%')
          .padding(Spacing.xl)
          .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
          .borderRadius(BorderRadius.xl)
          .shadow(getShadow('sm', this.isDarkMode))

          // 联系方式（可选）
          Column({ space: Spacing.md }) {
            Row() {
              SymbolGlyph($r('sys.symbol.phone.fill'))
                .fontSize(Size.iconMD)
                .fontColor([this.currentColors.primary])
              
              Text('联系方式（可选）')
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontWeight(FontWeight.SemiBold)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .layoutWeight(1)
                .margin({ left: Spacing.sm })

              Text('方便我们回复您')
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(this.tc('#8E8E93', '#8E8E93'))
            }
            .width('100%')

            TextInput({ placeholder: '手机号/邮箱', text: $$this.contactInfo })
              .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .height(Size.inputSM + Spacing.sm)
              .backgroundColor(this.bg('#F8F9FA', '#2C2C2E'))
              .borderRadius(BorderRadius.lg)
              .padding({ left: Spacing.md, right: Spacing.md })
              .onChange((value: string) => {
                this.contactInfo = value;
              })
          }
          .width('100%')
          .padding(Spacing.xl)
          .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
          .borderRadius(BorderRadius.xl)
          .shadow(getShadow('sm', this.isDarkMode))

          // 提交按钮
          Button() {
            if (this.isSubmitting) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color('#FFFFFF')
            } else {
              Row({ space: Spacing.sm }) {
                SymbolGlyph($r('sys.symbol.paperplane'))
                  .fontSize(Size.iconMD)
                  .fontColor(['#FFFFFF'])
                
                Text('提交反馈')
                  .fontSize(fontScaleManager.getScaledFontSize(16))
                  .fontWeight(FontWeight.SemiBold)
                  .fontColor('#FFFFFF')
              }
            }
          }
          .width('100%')
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
          .enabled(!this.isSubmitting && this.feedbackContent.trim().length > 0)
          .onClick(() => {
            if (!this.isSubmitting) {
              this.handleSubmit();
            }
          })
          .stateStyles({
            pressed: { .scale({ x: 0.98, y: 0.98 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })

          // 提示信息
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text('我们会在1-3个工作日内处理您的反馈')
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: Spacing.xxxl })
        }
        .width('100%')
        .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.lg })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }
}

// 预览组件
@Preview
@ComponentV2
struct FeedbackPagePreview {
  build() {
    Column() {
      Text('意见反馈 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      FeedbackPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('意见反馈 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      FeedbackPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
