import { router } from '@kit.ArkUI';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { DeviceUtils } from '../utils/DeviceUtils';
import { featuresViewModel, FeatureItem, FeaturesViewModel } from '../viewmodels/FeaturesViewModel';

@Entry
@Component
struct FeaturesPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;

  private vm: FeaturesViewModel = featuresViewModel;

  async aboutToAppear(): Promise<void> {
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    await this.vm.init();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
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
            .fontColor(this.tc('#333333', '#FFFFFF'))

          Text(item.description)
            .fontSize(this.isTablet ? 16 : 13)
            .fontColor(this.tc('#999999', '#8E8E93'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(item.enabled ? '已启用' : '已禁用')
          .fontSize(this.isTablet ? 13 : 11)
          .fontColor(item.enabled ? '#52C41A' : '#999999')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(item.enabled ? 'rgba(82,196,26,0.1)' : 'rgba(153,153,153,0.1)')
          .borderRadius(10)
      }
      .width('100%')

      if (item.tags && item.tags.length > 0) {
        Row({ space: 8 }) {
          ForEach(item.tags, (tag: string) => {
            Text(tag)
              .fontSize(this.isTablet ? 13 : 11)
              .fontColor(this.tc('#666666', '#8E8E93'))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.bg('#F0F0F0', '#2C2C2E'))
              .borderRadius(8)
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .margin({ top: 8 })
  }

  build() {
    Column() {
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor(this.tc('#333333', '#FFFFFF'))
        }
        .width(44)
        .height(44)
        .backgroundColor('transparent')
        .onClick(() => {
          try {
            router.back();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('[FeaturesPage] back failed:', msg);
          }
        })

        Text('功能中心')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(44)
      }
      .width('100%')
      .height(52)
      .padding({ left: 4, right: 16 })
      .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))

      Column({ space: 8 }) {
        Text('千读阅界')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        Text('Core Features')
          .fontSize(14)
          .fontColor(this.tc('#999999', '#8E8E93'))
      }
      .width('100%')
      .padding(20)
      .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))

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
    .backgroundColor(this.bg('#F5F5F5', '#1C1C1E'))
  }
}