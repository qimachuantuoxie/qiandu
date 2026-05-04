import { logger } from '../../common/utils/Logger';
import { goBack } from '../../../common/utils/NavigationHelper';
// 用户协议页面 - 鸿蒙原生风格
// User Agreement Page - HarmonyOS Native Style

import { common } from '@kit.AbilityKit';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { getDarkModeColors, IDarkModeColors } from '../core/utils/HarmonyDesignTokens';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

/**
 * 用户协议页面
 * 展示应用的用户协议条款，包括服务说明、用户行为规范、知识产权、免责声明等内容
 * 支持深色模式、字体缩放和平板适配
 */
@Entry
@Component
struct UserAgreementPage {
  /** 是否为深色模?*/
  @State isDarkMode: boolean = false;
  /** 深色模式颜色配置 */
  @State colors: IDarkModeColors = { background: '', backgroundSecondary: '', cardBackground: '', textPrimary: '', textSecondary: '', textHint: '', primary: '', border: '', surface: '' };
  /** 字体缩放比例 */
  @State fontScale: number = 1.0;
  /** 是否为平板设?*/
  @State isTablet: boolean = false;
  /** 当前主题颜色 */
  @State currentColors: AppColors = themeManager.getColors();
  @State screenInfo: ScreenInfo | null = null;

  /**
   * 页面初始�?
   * 加载主题、字体缩放比例和设备类型信息
   */
  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();

      this.isDarkMode = appTheme.isDarkMode();
      this.colors = getDarkModeColors(this.isDarkMode);
      this.fontScale = await fontScaleManager.getFontScale();
      this.currentColors = themeManager.getColors();
      this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
    } catch (error) {
      logger.info('UserAgreementPage init skipped');
    }
  }

  /**
   * 根据字体缩放和设备类型计算实际字�?
   * @param baseSize 基础字号
   * @returns 缩放后的字号
   */
  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * this.fontScale * tabletMultiplier);
  }

  /**
   * 根据深色模式状态选择文本颜色
   * @param light 浅色模式颜色
   * @param dark 深色模式颜色
   * @returns 当前模式对应的颜�?
   */
  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 根据深色模式状态选择背景颜色
   * @param light 浅色模式颜色
   * @param dark 深色模式颜色
   * @returns 当前模式对应的颜�?
   */
  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Column() {
      // 标题�?
      this.NavBar()

      // 内容区域
      Scroll() {
        Column({ space: 20 }) {
          // 标题
          Column({ space: 8 }) {
            Text('协议')
              .fontSize(48)

            Text('用户协议')
              .fontSize(this.scaleFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)

            Text('最后更新日期：2026�?�?8�?)
              .fontSize(this.scaleFontSize(12))
              .fontColor(this.colors.textHint)
          }
          .width('100%')
          .padding({ top: 24, bottom: 16 })
          .alignItems(HorizontalAlign.Center)

          // 引言
          this.ContentCard('引言',
            '欢迎使用千读阅界！在您开始使用本应用之前，请仔细阅读本用户协议�?
          )

          // 协议接受
          this.ContentCard('1. 协议接受',
            '通过下载、安装或使用千读阅界（以下简�?本应�?），您表示同意接受本用户协议的所有条款。\n\n' +
            '如果您不同意本协议的任何条款，请勿使用本应用�?
          )

          // 服务说明
          this.ContentCard('2. 服务说明',
            '千读阅界是一款本地电子书阅读应用，提供以下功能：\n\n' +
            '�?本地电子书文件管理和阅读\n' +
            '�?阅读进度记录和书签功能\n' +
            '�?阅读笔记和标注功能\n' +
            '�?阅读统计和个性化设置\n' +
            '�?书架管理和分类功�?
          )

          // 用户行为规范
          this.ContentCard('3. 用户行为规范',
            '您同意在使用本应用时：\n\n' +
            '�?遵守所有适用的法律法规\n' +
            '�?不得上传或传播违法、侵权内容\n' +
            '�?不得干扰或破坏应用的正常运行\n' +
            '�?不得尝试未经授权访问应用系统\n' +
            '�?对自己导入的文件内容负责'
          )

          // 知识产权
          this.ContentCard('4. 知识产权',
            '�?本应用的著作权、商标权等知识产权归开发者所有\n\n' +
            '�?您导入的电子书文件的知识产权归原权利人所有\n\n' +
            '�?您创建的书签、笔记等内容归您所�?
          )

          // 免责声明
          this.ContentCard('5. 免责声明',
            '�?本应用按"现状"提供，不提供任何明示或暗示的担保\n\n' +
            '�?我们不对因使用本应用而导致的任何损失承担责任\n\n' +
            '�?您导入的文件内容由您自行负责，我们不对内容的合法性负责\n\n' +
            '�?我们保留随时修改或终止服务的权利'
          )

          // 服务变更
          this.ContentCard('6. 服务变更',
            '我们保留随时修改、暂停或终止本应用服务的权利，恕不另行通知。对于服务的任何修改或终止，我们不对用户或第三方承担责任�?
          )

          // 协议修改
          this.ContentCard('7. 协议修改',
            '我们保留随时修改本用户协议的权利。修改后的协议将在应用内公布，继续使用本应用即表示您接受修改后的协议。建议您定期查看以了解最新条款�?
          )

          // 适用法律
          this.ContentCard('8. 适用法律与争议解�?,
            '本协议受中华人民共和国法律管辖。如发生争议，双方应友好协商解决；协商不成的，任何一方均可向有管辖权的法院提起诉讼�?
          )

          // 终止
          this.ContentCard('9. 协议终止',
            '如果您违反本协议的任何条款，我们有权立即终止您使用本应用的资格，无需事先通知。您在协议终止后仍需对之前的行为承担责任�?
          )

          // 联系我们
          this.ContentCard('10. 联系我们',
            '如果您对本用户协议有任何疑问，请通过以下方式联系我们：\n\n' +
            '�?应用内反馈功能\n' +
            '�?电子邮件：support@qianduyuejie.com'
          )

          // 免责声明
          this.ContentCard('11. 免责声明',
            '千读阅界是一款独立开发的阅读应用。本应用与任何大型公司均无关联，亦非其官方产品。我们尊重所有知识产权，相关功能基于开源技术实现�?
          )

          // 底部提示
          Text('继续使用本应用即表示您已阅读并同意上述条�?)
            .fontSize(this.scaleFontSize(12))
            .fontColor(this.colors.textHint)
            .textAlign(TextAlign.Center)
            .margin({ top: 16, bottom: 40 })
        }
        .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.backgroundSecondary)
  }

  /**
   * 导航栏构建器
   * 包含返回按钮和页面标�?
   */
  @Builder
  NavBar() {
    Row() {
      Button() {
        Text('返回')
          .fontSize(this.isTablet ? 18 : 14)
          .fontColor(this.colors.textPrimary)
      }
      .width(this.isTablet ? 56 : 50)
      .height(this.isTablet ? 48 : 40)
      .backgroundColor(this.bg('rgba(255, 255, 255, 0.3)', 'rgba(255, 255, 255, 0.05)'))
      .borderRadius(20)
      .onClick(() => { try { goBack(); } catch(e) { logger.error('back error:', e); } })

      Text('用户协议')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank().width(this.isTablet ? 56 : 50)
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 8, right: this.isTablet ? 24 : 16 })
    .backgroundColor(this.colors.background)
  }

  /**
   * 内容卡片构建�?
   * @param title 卡片标题
   * @param content 卡片内容
   */
  @Builder
  ContentCard(title: string, content: string) {
    Column({ space: 12 }) {
      Text(title)
        .fontSize(this.scaleFontSize(16))
        .fontWeight(600)
        .fontColor(this.colors.textPrimary)

      Text(content)
        .fontSize(this.scaleFontSize(14))
        .lineHeight(this.scaleFontSize(22))
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
    .backgroundColor(this.colors.background)
    .borderRadius(12)
  }
}
