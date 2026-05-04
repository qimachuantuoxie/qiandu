import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router } from '@kit.ArkUI';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct PrivacyPolicyPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
  }

  private tc(light: string, dark: string): string {
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
            logger.error('[PrivacyPolicyPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('隐私政策')
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
        Column({ space: Spacing.xl }) {
          // 头部信息
          Column({ space: Spacing.md }) {
            Column() {
              SymbolGlyph($r('sys.symbol.shield.checkered'))
                .fontSize(Size.iconXXXL)
                .fontColor([this.currentColors.primary])
            }
            .width(70)
            .height(70)
            .borderRadius(BorderRadius.full)
            .backgroundColor(this.currentColors.primary + '15')
            .justifyContent(FlexAlign.Center)

            Text('隐私政策')
              .fontSize(fontScaleManager.getScaledFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            Text('最后更新：2024年1月1日')
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .width('100%')
          .padding(Spacing.xl)
          .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
          .borderRadius(BorderRadius.xl)
          .shadow(getShadow('md', this.isDarkMode))

          // 条款内容
          Column({ space: Spacing.lg }) {
            this.PolicySection('1. 信息收集', [
              '我们可能会收集以下类型的信息：',
              '• 设备信息：设备型号、操作系统版本',
              '• 使用数据：阅读时长、阅读偏好',
              '• 账号信息：用户名、邮箱（如提供）'
            ])

            this.PolicySection('2. 信息使用', [
              '我们收集的信息将用于：',
              '• 提供和改进服务',
              '• 个性化阅读体验',
              '• 同步阅读进度和书签',
              '• 发送重要通知'
            ])

            this.PolicySection('3. 信息保护', [
              '我们采取以下措施保护您的信息：',
              '• 数据加密存储',
              '• 访问权限控制',
              '• 定期安全审计',
              '• 不向第三方出售个人信息'
            ])

            this.PolicySection('4. 信息共享', [
              '在以下情况下，我们可能共享信息：',
              '• 经您明确同意',
              '• 法律法规要求',
              '• 保护我们的合法权益',
              '• 与服务提供商合作（已签署保密协议）'
            ])

            this.PolicySection('5. 您的权利', [
              '您拥有以下权利：',
              '• 访问和查看个人信息',
              '• 更正不准确的信息',
              '• 删除个人账户和数据',
              '• 撤回同意授权'
            ])

            this.PolicySection('6. 联系我们', [
              '如有任何疑问，请联系我们：',
              '• 邮箱：privacy@qianduyuejie.com',
              '• 电话：400-xxx-xxxx',
              '• 地址：北京市朝阳区xxx路xxx号'
            ])
          }
          .width('100%')

          // 底部提示
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text('继续使用即表示您同意本隐私政策')
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
    .backgroundColor(this.tc('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  PolicySection(title: string, content: string[]) {
    Column({ space: Spacing.md }) {
      Text(title)
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .width('100%')

      Column({ space: Spacing.sm }) {
        ForEach(content, (line: string) => {
          Text(line)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
            .lineHeight(22)
            .width('100%')
        }, (line: string) => line)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }
}

// 预览组件
@Preview
@ComponentV2
struct PrivacyPolicyPagePreview {
  build() {
    Column() {
      Text('隐私政策 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      PrivacyPolicyPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('隐私政策 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      PrivacyPolicyPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
