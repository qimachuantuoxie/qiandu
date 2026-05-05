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

interface FAQItem {
  question: string;
  answer: string;
}

@Entry
@ComponentV2
struct HelpPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local expandedIndex: number | null = null;
  private context: common.Context | null = null;

  private faqList: FAQItem[] = [
    {
      question: '如何添加书籍？',
      answer: '您可以在书架页面点击右上角的"+"按钮，选择从本地导入或在线搜索添加书籍。支持EPUB、PDF、TXT等多种格式。'
    },
    {
      question: '如何调整字体大小？',
      answer: '在阅读页面点击屏幕中央，弹出菜单后选择"设置"图标，即可调整字体大小、行间距等阅读参数。'
    },
    {
      question: '如何使用TTS朗读？',
      answer: '在阅读页面点击TTS图标，选择语音类型后即可开始朗读。您可以在设置中配置默认语音和语速。'
    },
    {
      question: '如何同步阅读进度？',
      answer: '登录账号后，系统会自动同步您的阅读进度、书签和笔记。确保在设置中开启了"自动同步"功能。'
    },
    {
      question: '如何导出笔记？',
      answer: '进入笔记管理页面，选择要导出的笔记，点击右上角的分享按钮，可以选择导出为TXT或PDF格式。'
    },
    {
      question: '如何更换主题？',
      answer: '在设置页面的"显示"标签中，可以选择不同的背景主题，包括白天、护眼、夜间等模式。'
    }
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
            logger.error('[HelpPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('帮助中心')
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
      Scroll() {
        Column({ space: Spacing.lg }) {
          // 常见问题
          Column({ space: Spacing.md }) {
            Row() {
              SymbolGlyph($r('sys.symbol.questionmark.circle.fill'))
                .fontSize(Size.iconLG)
                .fontColor([this.currentColors.primary])
              
              Text('常见问题')
                .fontSize(fontScaleManager.getScaledFontSize(17))
                .fontWeight(FontWeight.SemiBold)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .layoutWeight(1)
                .margin({ left: Spacing.sm })
            }
            .width('100%')

            List({ space: Spacing.sm }) {
              ForEach(this.faqList, (item: FAQItem, index: number) => {
                ListItem() {
                  Column() {
                    // 问题标题
                    Row({ space: Spacing.md }) {
                      Column() {
                        Text((index + 1).toString())
                          .fontSize(fontScaleManager.getScaledFontSize(14))
                          .fontWeight(FontWeight.Bold)
                          .fontColor(this.currentColors.primary)
                      }
                      .width(28)
                      .height(28)
                      .borderRadius(BorderRadius.full)
                      .backgroundColor(this.currentColors.primary + '15')
                      .justifyContent(FlexAlign.Center)

                      Text(item.question)
                        .fontSize(fontScaleManager.getScaledFontSize(15))
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                        .layoutWeight(1)

                      SymbolGlyph($r('sys.symbol.chevron.down'))
                        .fontSize(Size.iconSM)
                        .fontColor([this.tc('#8E8E93', '#8E8E93')])
                        .rotate({ angle: this.expandedIndex === index ? 180 : 0 })
                        .animation({ duration: 200 })
                    }
                    .width('100%')
                    .padding(Spacing.lg)
                    .onClick(() => {
                      this.expandedIndex = this.expandedIndex === index ? null : index;
                    })

                    // 答案内容
                    if (this.expandedIndex === index) {
                      Text(item.answer)
                        .fontSize(fontScaleManager.getScaledFontSize(14))
                        .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
                        .lineHeight(22)
                        .width('100%')
                        .padding({ 
                          left: Spacing.lg + 14, 
                          right: Spacing.lg, 
                          bottom: Spacing.lg 
                        })
                        .animation({ duration: 200 })
                    }
                  }
                  .width('100%')
                  .backgroundColor(this.expandedIndex === index ? 
                    this.currentColors.primary + '05' : this.tc('#FFFFFF', '#1E1E2E'))
                  .borderRadius(BorderRadius.xl)
                  .shadow(getShadow('sm', this.isDarkMode))
                }
              }, (item: FAQItem, index: number) => item.question)
            }
            .width('100%')
            .scrollBar(BarState.Off)
          }
          .width('100%')

          // 联系客服
          Column({ space: Spacing.lg }) {
            Row() {
              SymbolGlyph($r('sys.symbol.headphones'))
                .fontSize(Size.iconLG)
                .fontColor([this.currentColors.primary])
              
              Text('联系客服')
                .fontSize(fontScaleManager.getScaledFontSize(17))
                .fontWeight(FontWeight.SemiBold)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .layoutWeight(1)
                .margin({ left: Spacing.sm })
            }
            .width('100%')

            Row({ space: Spacing.lg }) {
              // 在线客服
              Column({ space: Spacing.sm }) {
                Column() {
                  SymbolGlyph($r('sys.symbol.text.bubble.fill'))
                    .fontSize(Size.iconXL)
                    .fontColor(['#FFFFFF'])
                }
                .width(Size.avatarLG)
                .height(Size.avatarLG)
                .borderRadius(BorderRadius.full)
                .linearGradient({
                  direction: GradientDirection.Top,
                  colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
                })
                .justifyContent(FlexAlign.Center)

                Text('在线客服')
                  .fontSize(fontScaleManager.getScaledFontSize(13))
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              }
              .layoutWeight(1)
              .padding(Spacing.lg)
              .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
              .borderRadius(BorderRadius.xl)
              .shadow(getShadow('sm', this.isDarkMode))
              .onClick(() => {
                promptAction.showToast({ message: '客服功能开发中', duration: 1500 });
              })

              // 意见反馈
              Column({ space: Spacing.sm }) {
                Column() {
                  SymbolGlyph($r('sys.symbol.pencil'))
                    .fontSize(Size.iconXL)
                    .fontColor(['#FFFFFF'])
                }
                .width(Size.avatarLG)
                .height(Size.avatarLG)
                .borderRadius(BorderRadius.full)
                .linearGradient({
                  direction: GradientDirection.Top,
                  colors: ['#FFD700', '#FFA500']
                })
                .justifyContent(FlexAlign.Center)

                Text('意见反馈')
                  .fontSize(fontScaleManager.getScaledFontSize(13))
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              }
              .layoutWeight(1)
              .padding(Spacing.lg)
              .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
              .borderRadius(BorderRadius.xl)
              .shadow(getShadow('sm', this.isDarkMode))
              .onClick(() => {
                navigateTo('pages/FeedbackPage');
              })
            }
            .width('100%')
          }
          .width('100%')

          // 温馨提示
          Column({ space: Spacing.md }) {
            Row({ space: Spacing.sm }) {
              SymbolGlyph($r('sys.symbol.lightbulb.fill'))
                .fontSize(Size.iconMD)
                .fontColor(['#FFD700'])
              
              Text('温馨提示')
                .fontSize(fontScaleManager.getScaledFontSize(15))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFD700')
            }
            .width('100%')

            Text('如果您在使用过程中遇到任何问题，欢迎通过以下方式联系我们：\n\n• 在线客服：工作日 9:00-18:00\n• 意见反馈：随时提交，1-3个工作日回复\n• 邮箱联系：support@qianduyuejie.com')
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
              .lineHeight(22)
          }
          .width('100%')
          .padding(Spacing.xl)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: this.isDarkMode 
              ? ['rgba(255,215,0,0.1)', 'rgba(255,165,0,0.05)']
              : ['rgba(255,215,0,0.15)', 'rgba(255,165,0,0.08)']
          })
          .borderRadius(BorderRadius.xl)
          .border({ 
            width: 1, 
            color: this.isDarkMode ? 'rgba(255,215,0,0.3)' : 'rgba(255,215,0,0.4)' 
          })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }
}

// 预览组件
@Preview
@ComponentV2
struct HelpPagePreview {
  build() {
    Column() {
      Text('帮助中心 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      HelpPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('帮助中心 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      HelpPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
