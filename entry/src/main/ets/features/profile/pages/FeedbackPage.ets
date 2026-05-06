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
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';

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
      // 标准页面头部
      PageHeader({
        title: '意见反馈',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[FeedbackPage] back failed:', msg);
          }
        }
      })

      // 表单区域
      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          // 反馈类型选择
          HDSCard({
            padding: HDSSpacing.xl,
            content: () => {
              Column({ space: HDSSpacing.md }) {
                Row() {
                  SymbolGlyph($r('sys.symbol.tag.fill'))
                    .fontSize(HDSTypography.sizes.lg)
                    .fontColor([HDSColours.primary.blue])
                  
                  Text('反馈类型')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
                    .fontWeight(FontWeight.SemiBold)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                    .layoutWeight(1)
                    .margin({ left: HDSSpacing.sm })
                }
                .width('100%')

                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(this.feedbackTypes, (type: string) => {
                    Text(type)
                      .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                      .padding({ 
                        left: HDSSpacing.lg, 
                        right: HDSSpacing.lg, 
                        top: HDSSpacing.md, 
                        bottom: HDSSpacing.md 
                      })
                      .backgroundColor(this.feedbackType === type ? 
                        HDSColours.primary.blue : this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray100)
                      .fontColor(this.feedbackType === type ? 
                        HDSColours.neutral.white : this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                      .borderRadius(HDSBorderRadius.xl)
                      .fontWeight(this.feedbackType === type ? 
                        FontWeight.Medium : FontWeight.Regular)
                      .onClick(() => { this.feedbackType = type; })
                      .stateStyles({
                        pressed: { .scale({ x: 0.95, y: 0.95 }) },
                        normal: { .scale({ x: 1, y: 1 }) }
                      })
                      .margin({ right: HDSSpacing.sm, bottom: HDSSpacing.sm })
                  }, (type: string) => type)
                }
                .width('100%')
              }
              .width('100%')
            }
          })

          // 反馈内容
          HDSCard({
            padding: HDSSpacing.xl,
            content: () => {
              Column({ space: HDSSpacing.md }) {
                Row() {
                  SymbolGlyph($r('sys.symbol.text.bubble'))
                    .fontSize(HDSTypography.sizes.lg)
                    .fontColor([HDSColours.primary.blue])
                  
                  Text('反馈内容')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
                    .fontWeight(FontWeight.SemiBold)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                    .layoutWeight(1)
                    .margin({ left: HDSSpacing.sm })

                  Text(this.feedbackContent.length + '/500')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
                    .fontColor(this.feedbackContent.length > 450 ? HDSColours.status.error : this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                }
                .width('100%')

                TextArea({ text: $$this.feedbackContent, placeholder: '请详细描述您遇到的问题或建议...' })
                  .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textTertiary : HDSColours.neutral.gray400)
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                  .height(150)
                  .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray50)
                  .borderRadius(HDSBorderRadius.lg)
                  .padding(HDSPacing.md)
                  .maxLength(500)
                  .onChange((value: string) => {
                    this.feedbackContent = value;
                  })
              }
              .width('100%')
            }
          })

          // 联系方式（可选）
          HDSCard({
            padding: HDSSpacing.xl,
            content: () => {
              Column({ space: HDSSpacing.md }) {
                Row() {
                  SymbolGlyph($r('sys.symbol.phone.fill'))
                    .fontSize(HDSTypography.sizes.lg)
                    .fontColor([HDSColours.primary.blue])
                  
                  Text('联系方式（可选）')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
                    .fontWeight(FontWeight.SemiBold)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                    .layoutWeight(1)
                    .margin({ left: HDSSpacing.sm })

                  Text('方便我们回复您')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                }
                .width('100%')

                TextInput({ placeholder: '手机号/邮箱', text: $$this.contactInfo })
                  .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textTertiary : HDSColours.neutral.gray400)
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                  .height(48)
                  .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray50)
                  .borderRadius(HDSBorderRadius.lg)
                  .padding({ left: HDSSpacing.md, right: HDSSpacing.md })
                  .onChange((value: string) => {
                    this.contactInfo = value;
                  })
              }
              .width('100%')
            }
          })

          // 提交按钮
          Button() {
            if (this.isSubmitting) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(HDSColours.neutral.white)
            } else {
              Row({ space: HDSSpacing.sm }) {
                SymbolGlyph($r('sys.symbol.paperplane'))
                  .fontSize(HDSTypography.sizes.lg)
                  .fontColor([HDSColours.neutral.white])
                
                Text('提交反馈')
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
                  .fontWeight(FontWeight.SemiBold)
                  .fontColor(HDSColours.neutral.white)
              }
            }
          }
          .width('100%')
          .height(56)
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
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(HDSTypography.sizes.md)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            
            Text('我们会在1-3个工作日内处理您的反馈')
              .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: HDSSpacing.xxxl })
        }
        .width('100%')
        .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg, top: HDSSpacing.lg })
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
}

// 预览组件
@Preview
@ComponentV2
struct FeedbackPagePreview {
  build() {
    Column() {
      Text('意见反馈 - 浅色模式')
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutral.gray100)

      FeedbackPage()
        .height(700)

      Divider()
        .margin({ top: HDSSpacing.xl, bottom: HDSSpacing.xl })

      Text('意见反馈 - 深色模式')
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutralDark.surface)
        .fontColor(HDSColours.neutralDark.textPrimary)

      FeedbackPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor(HDSColours.neutral.white)
  }
}
