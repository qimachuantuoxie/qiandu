import { logger } from '../../common/utils/Logger';
import { goBack } from '../../../common/utils/NavigationHelper';
// 隐私政策页面 - 鸿蒙原生风格
// Privacy Policy Page - HarmonyOS Native Style

import { common } from '@kit.AbilityKit';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { getDarkModeColors, IDarkModeColors } from '../core/utils/HarmonyDesignTokens';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct PrivacyPolicyPage {
  @State isDarkMode: boolean = false;
  @State colors: IDarkModeColors = { background: '', backgroundSecondary: '', cardBackground: '', textPrimary: '', textSecondary: '', textHint: '', primary: '', border: '', surface: '' };
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State screenInfo: ScreenInfo | null = null;

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
      logger.info('PrivacyPolicyPage init skipped');
    }
  }

  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * this.fontScale * tabletMultiplier);
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }
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
            Text('安全')
              .fontSize(48)

            Text('隐私政策')
              .fontSize(this.scaleFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)

            Text('最后更新日期：2026�?�?�?)
              .fontSize(this.scaleFontSize(12))
              .fontColor(this.colors.textHint)
          }
          .width('100%')
          .padding({ top: 24, bottom: 16 })
          .alignItems(HorizontalAlign.Center)

          // 简�?
          this.ContentCard('引言',
            '欢迎您使用千读阅界（以下简�?本应�?）。我们非常重视您的隐私保护，特制定本隐私政策，向您说明我们如何收集、使用、存储和保护您的个人信息�?
          )

          // 信息收集
          this.ContentCard('1. 信息收集',
            '本应用可能收集以下信息：\n\n' +
            '�?设备信息：设备型号、操作系统版本、设备标识符等\n' +
            '�?使用数据：应用使用频率、功能使用情况等\n' +
            '�?阅读数据：您的阅读进度、书签、笔记等（仅存储在本地）\n' +
            '�?文件信息：您导入的电子书文件信息'
          )

          // 信息使用
          this.ContentCard('2. 信息使用',
            '我们使用收集的信息用于：\n\n' +
            '�?提供和改进应用功能\n' +
            '�?分析应用性能和使用情况\n' +
            '�?保护应用安全\n' +
            '�?遵守法律法规要求'
          )

          // 信息存储与保�?
          this.ContentCard('3. 信息存储与保�?,
            '�?您的阅读数据、书签、笔记等个人信息仅存储在您的设备本地\n\n' +
            '�?我们不会将您的个人数据上传到服务器\n\n' +
            '�?我们采用行业标准的安全措施保护您的信�?
          )

          // 信息共享
          this.ContentCard('4. 信息共享',
            '我们不会向任何第三方出售、出租或分享您的个人信息，除非：\n\n' +
            '�?获得您的明确同意\n' +
            '�?应法律法规要求\n\n' +
            '�?保护我们的合法权�?
          )

          // 您的权利
          this.ContentCard('5. 您的权利',
            '您有权：\n\n' +
            '�?访问和查看您的个人数据\n' +
            '�?删除您的个人数据\n' +
            '�?导出您的阅读数据\n' +
            '�?随时撤回同意'
          )

          // 儿童隐私
          this.ContentCard('6. 儿童隐私',
            '本应用不面向13岁以下的儿童。我们不会故意收集儿童的个人信息。如果您发现我们无意中收集了儿童的信息，请联系我们删除�?
          )

          // 政策更新
          this.ContentCard('7. 政策更新',
            '我们可能会不时更新本隐私政策。更新后的政策将在应用内公布，建议您定期查看以了解最新信息�?
          )

          // 联系我们
          this.ContentCard('8. 联系我们',
            '如果您对本隐私政策有任何疑问，请通过以下方式联系我们：\n\n' +
            '�?应用内反馈功能\n' +
            '�?电子邮件：support@qianduyuejie.com'
          )

          // 免责声明
          this.ContentCard('9. 免责声明',
            '千读阅界是一款独立开发的阅读应用。本应用与任何大型公司均无关联，亦非其官方产品。我们尊重所有知识产权，相关功能基于开源技术实现�?
          )

          // 底部留白
          Blank().height(40)
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

      Text('隐私政策')
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

// 预览组件 - 用于DevEco Studio预览�?
@Preview
@Component
struct PrivacyPolicyPagePreview {
  build() {
    Column() {
      Text('隐私政策�?- 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      PrivacyPolicyPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('隐私政策�?- 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      PrivacyPolicyPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
