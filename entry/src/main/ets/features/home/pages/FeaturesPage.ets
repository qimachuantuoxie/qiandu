import { router } from '@kit.ArkUI';
import { themeManager, AppColors } from '../../common/constants/AppTheme';
import { fontScaleManager } from '../../common/utils/FontScaleManager';
import { DeviceUtils } from '../../common/utils/DeviceUtils';
import { BackButton } from '../../common/components/BackButton';
import { featuresViewModel, FeatureItem, FeaturesViewModel } from '../../core/viewmodels/FeaturesViewModel';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';
import { ThemeTokens } from '../../common/utils/ThemeTokens';

@Entry
@Component
struct FeaturesPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State screenInfo: ScreenInfo | null = null;

  private vm: FeaturesViewModel = featuresViewModel;

  async aboutToAppear(): Promise<void> {
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    await this.vm.init();
  }

  @Builder
  FeatureCard(item: FeatureItem) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text(item.icon)
          .fontSize(this.isTablet ? 34 : 28)

        Column({ space: 4 }) {
          Text(item.name)
            .fontSize(this.isTablet ? 19 : 16)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeTokens.textPrimary())

          Text(item.description)
            .fontSize(this.isTablet ? 16 : 13)
            .fontColor(ThemeTokens.textSecondary())
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(item.enabled ? '已启用' : '已禁用')
          .fontSize(this.isTablet ? 13 : 11)
          .fontColor(item.enabled ? ThemeTokens.textSuccess() : ThemeTokens.textSecondary())
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(item.enabled ? ThemeTokens.bgSuccess() : ThemeTokens.bgTertiary())
          .borderRadius(10)
      }
      .width('100%')

      if (item.tags && item.tags.length > 0) {
        Row({ space: 8 }) {
          ForEach(item.tags, (tag: string) => {
            Text(tag)
              .fontSize(this.isTablet ? 13 : 11)
              .fontColor(ThemeTokens.textSecondary())
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(ThemeTokens.bgTertiary())
              .borderRadius(8)
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(12)
    .margin({ top: 8 })
  }

  build() {
    Column() {
      Row() {
        BackButton({ isDarkMode: this.isDarkMode })

        Text('功能特性')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)

        Text('功能中心')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(44)
      }
      .width('100%')
      .height(52)
      .padding({ left: 4, right: 16 })
      .backgroundColor(ThemeTokens.bgSecondary())

      Column({ space: 8 }) {
        Text('千读阅界')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.textPrimary())

        Text('Core Features')
          .fontSize(14)
          .fontColor(ThemeTokens.textSecondary())
      }
      .width('100%')
      .padding(20)
      .backgroundColor(ThemeTokens.bgSecondary())

      Scroll() {
        Column({ space: 16 }) {
          ForEach(this.vm.features, (item: FeatureItem) => {
            this.FeatureCard(item)
          }, (item: FeatureItem) => item.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.bgPrimary())
  }
}

// 预览组件 - 用于DevEco Studio预览
@Preview
@Component
struct FeaturesPagePreview {
  build() {
    Column() {
      Text('功能特性页 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      FeaturesPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('功能特性页 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      FeaturesPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}