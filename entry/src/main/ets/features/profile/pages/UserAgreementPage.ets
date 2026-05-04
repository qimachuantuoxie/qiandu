import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router } from '@kit.ArkUI';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct UserAgreementPage {
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
            logger.error('[UserAgreementPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('用户协议')
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
              SymbolGlyph($r('sys.symbol.doc.text'))
                .fontSize(Size.iconXXXL)
                .fontColor([this.currentColors.primary])
            }
            .width(70)
            .height(70)
            .borderRadius(BorderRadius.full)
            .backgroundColor(this.currentColors.primary + '15')
            .justifyContent(FlexAlign.Center)

            Text('用户协议')
              .fontSize(fontScaleManager.getScaledFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            Text('生效日期：2024年1月1日')
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
            this.AgreementSection('1. 接受条款', [
              '欢迎使用千读阅界！在使用我们的服务之前，请您仔细阅读并理解本用户协议。',
              '当您注册、登录或使用我们的服务时，即表示您已阅读、理解并同意接受本协议的全部内容。'
            ])

            this.AgreementSection('2. 服务内容', [
              '千读阅界提供以下服务：',
              '• 电子书阅读和管理',
              '• 在线阅读资源搜索',
              '• 阅读进度同步',
              '• 书签和笔记管理',
              '• TTS语音朗读',
              '• 生词本和词典查询'
            ])

            this.AgreementSection('3. 用户义务', [
              '您在使用服务时应遵守以下义务：',
              '• 提供真实、准确的个人信息',
              '• 妥善保管账号和密码',
              '• 不得利用服务从事违法活动',
              '• 尊重知识产权，不传播侵权内容',
              '• 不破坏或干扰服务正常运行'
            ])

            this.AgreementSection('4. 知识产权', [
              '关于知识产权的说明：',
              '• 本平台所有内容版权均归原作者所有',
              '• 用户生成的内容（笔记、书评等）版权归用户所有',
              '• 未经授权不得转载、摘编或使用本站内容',
              '• 如发现侵权内容，请联系我们删除'
            ])

            this.AgreementSection('5. 免责声明', [
              '在以下情况下，我们不承担责任：',
              '• 因不可抗力导致的服务中断',
              '• 用户自身操作不当造成的损失',
              '• 第三方链接的内容和服务',
              '• 网络故障或设备问题',
              '• 法律法规规定的其他情形'
            ])

            this.AgreementSection('6. 协议变更', [
              '我们有权根据需要修改本协议：',
              '• 修改后将通过公告或通知方式告知用户',
              '• 继续使用服务视为接受修改后的协议',
              '• 如不同意修改，可停止使用服务',
              '• 重大变更将提前7天通知用户'
            ])

            this.AgreementSection('7. 服务终止', [
              '在以下情况下，我们可能终止服务：',
              '• 用户违反本协议规定',
              '• 法律法规要求停止服务',
              '• 业务调整或技术原因',
              '• 用户主动注销账号'
            ])

            this.AgreementSection('8. 法律适用', [
              '本协议的解释和执行适用中华人民共和国法律。',
              '如发生争议，双方应友好协商解决；协商不成的，可向本公司所在地人民法院提起诉讼。'
            ])
          }
          .width('100%')

          // 底部提示
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text('继续使用即表示您同意本协议')
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
  AgreementSection(title: string, content: string[]) {
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
struct UserAgreementPagePreview {
  build() {
    Column() {
      Text('用户协议 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      UserAgreementPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('用户协议 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      UserAgreementPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
