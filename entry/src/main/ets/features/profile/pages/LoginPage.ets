import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct LoginPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local username: string = '';
  @Local password: string = '';
  @Local rememberPassword: boolean = false;
  @Local isLoading: boolean = false;
  private context: common.Context | null = null;

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

  private async handleLogin(): Promise<void> {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请输入用户名和密码', duration: 2000 });
      return;
    }

    this.isLoading = true;
    
    // 模拟登录请求
    setTimeout(() => {
      this.isLoading = false;
      promptAction.showToast({ message: '登录成功', duration: 1500 });
      
      if (this.rememberPassword) {
        preferenceManager.save('username', this.username);
        preferenceManager.save('password', this.password);
      }
      
      setTimeout(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[LoginPage] back failed:', msg);
        }
      }, 1000);
    }, 1500);
  }

  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.isDarkMode 
            ? [['#1A1A2E', 0.0], ['#16213E', 0.5], ['#0F3460', 1.0]]
            : [[COMMON_COLORS.PRIMARY_BLUE, 0.0], ['#667EEA', 0.5], ['#764BA2', 1.0]]
        })

      // 内容区域
      Column() {
        // 返回按钮
        Row() {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron.left'))
              .fontSize(Size.iconLG)
              .fontColor(['#FFFFFF'])
          }
          .width(Size.buttonMD)
          .height(Size.buttonMD)
          .borderRadius(BorderRadius.full)
          .backgroundColor('rgba(255,255,255,0.2)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            try {
              goBack();
            } catch (error) {
              const msg = error instanceof Error ? error.message : String(error);
              logger.error('[LoginPage] back failed:', msg);
            }
          })
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
        }
        .width('100%')
        .padding({ left: Spacing.lg, top: Spacing.xl })
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 登录卡片
        Column({ space: Spacing.xxl }) {
          // Logo和标题
          Column({ space: Spacing.md }) {
            Column() {
              SymbolGlyph($r('sysymbol.book.fill'))
                .fontSize(Size.iconXXXL * 1.5)
                .fontColor(['#FFFFFF'])
            }
            .width(80)
            .height(80)
            .borderRadius(BorderRadius.full)
            .backgroundColor('rgba(255,255,255,0.2)')
            .justifyContent(FlexAlign.Center)

            Text('欢迎回来')
              .fontSize(fontScaleManager.getScaledFontSize(28))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Text('登录您的账号以继续阅读')
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .fontColor('rgba(255,255,255,0.8)')
          }

          // 表单区域
          Column({ space: Spacing.lg }) {
            // 用户名输入框
            Column({ space: Spacing.sm }) {
              Row({ space: Spacing.md }) {
                SymbolGlyph($r('sysymbol.person.fill'))
                  .fontSize(Size.iconMD)
                  .fontColor([this.tc('#8E8E93', '#C7C7CC')])
                
                TextInput({ placeholder: '用户名/邮箱', text: $$this.username })
                  .placeholderColor(this.tc('#8E8E93', '#C7C7CC'))
                  .fontSize(fontScaleManager.getScaledFontSize(15))
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              }
              .width('100%')
              .padding(Spacing.md)
              .backgroundColor('rgba(255,255,255,0.95)')
              .borderRadius(BorderRadius.xl)
            }

            // 密码输入框
            Column({ space: Spacing.sm }) {
              Row({ space: Spacing.md }) {
                SymbolGlyph($r('sysymbol.lock.fill'))
                  .fontSize(Size.iconMD)
                  .fontColor([this.tc('#8E8E93', '#C7C7CC')])
                
                TextInput({ placeholder: '密码', text: $$this.password })
                  .placeholderColor(this.tc('#8E8E93', '#C7C7CC'))
                  .fontSize(fontScaleManager.getScaledFontSize(15))
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .type(InputType.Password)
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              }
              .width('100%')
              .padding(Spacing.md)
              .backgroundColor('rgba(255,255,255,0.95)')
              .borderRadius(BorderRadius.xl)
            }

            // 记住密码
            Row({ space: Spacing.sm }) {
              Toggle({ type: ToggleType.Checkbox, isOn: $$this.rememberPassword })
                .selectedColor(this.currentColors.primary)
              
              Text('记住密码')
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor('rgba(255,255,255,0.9)')
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)

            // 登录按钮
            Button() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color('#FFFFFF')
              } else {
                Row({ space: Spacing.sm }) {
                  SymbolGlyph($r('sysymbol.arrow.right'))
                    .fontSize(Size.iconMD)
                    .fontColor(['#FFFFFF'])
                  
                  Text('登录')
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
              colors: ['#FFFFFF', '#F0F0F0']
            })
            .borderRadius(BorderRadius.xl)
            .shadow(getShadow('lg', false))
            .enabled(!this.isLoading)
            .onClick(() => {
              if (!this.isLoading) {
                this.handleLogin();
              }
            })
            .stateStyles({
              pressed: { .scale({ x: 0.98, y: 0.98 }) },
              normal: { .scale({ x: 1, y: 1 }) }
            })

            // 其他操作
            Row({ space: Spacing.lg }) {
              Text('忘记密码?')
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor('rgba(255,255,255,0.8)')
                .onClick(() => {
                  promptAction.showToast({ message: '功能开发中', duration: 1500 });
                })

              Text('注册账号')
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .onClick(() => {
                  promptAction.showToast({ message: '功能开发中', duration: 1500 });
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ 
          left: Spacing.xxl, 
          right: Spacing.xxl, 
          bottom: Spacing.xxxl 
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

// 预览组件
@Preview
@ComponentV2
struct LoginPagePreview {
  build() {
    Column() {
      Text('登录页面 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      LoginPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('登录页面 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      LoginPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
