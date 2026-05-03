// 通用页面组件库
import { router } from '@kit.ArkUI';

interface PageHeaderConfig {
  title: string;
  showBack: boolean;
  isTablet: boolean;
  isDarkMode: boolean;
}

/**
 * 通用页面Header组件
 */
@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  @Prop isTablet: boolean = false;
  @Prop isDarkMode: boolean = false;
  onCustomAction?: () => void;

  build() {
    Row() {
      if (this.showBack) {
        Text('←')
          .fontSize(28)
          .fontColor(this.isDarkMode ? '#E8E8E8' : '#333333')
          .fontWeight(FontWeight.Light)
          .width(this.isTablet ? 44 : 40)
          .height(this.isTablet ? 44 : 40)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
          .borderRadius(this.isTablet ? 22 : 20)
          .onClick(() => {
            router.back();
          })
      }

      Text(this.title)
        .fontSize(this.isTablet ? 20 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .margin({ left: this.showBack ? (this.isTablet ? 12 : 8) : 0 })

      Blank()

      if (this.onCustomAction) {
        this.onCustomAction();
      }
    }
    .width('100%')
    .height(this.isTablet ? 64 : 60)
    .padding({ left: this.isTablet ? 20 : 16, right: this.isTablet ? 20 : 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
  }
}

interface SettingItemConfig {
  label: string;
  value: string;
  type: 'nav' | 'switch' | 'action';
}

/**
 * 通用设置项组件
 */
@Component
export struct SettingItem {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop itemType: 'nav' | 'switch' | 'action' = 'nav';
  @Prop isDarkMode: boolean = false;
  @Prop isTablet: boolean = false;
  onClick?: () => void;

  build() {
    Row() {
      Text(this.label)
        .fontSize(this.isTablet ? 16 : 14)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')

      if (this.itemType === 'nav' || this.itemType === 'action') {
        Blank()
        Text(this.value || (this.itemType === 'nav' ? '›' : ''))
          .fontSize(this.isTablet ? 14 : 13)
          .fontColor(this.isDarkMode ? '#888888' : '#999999')
      }
    }
    .width('100%')
    .height(this.isTablet ? 56 : 48)
    .padding({ left: this.isTablet ? 20 : 16, right: this.isTablet ? 20 : 16 })
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .onClick(() => {
      if (this.onClick) {
        this.onClick();
      }
    })
  }
}

/**
 * 通用卡片组件
 */
@Component
export struct CardView {
  @Prop title: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop isTablet: boolean = false;
  @BuilderParam content: () => void;

  build() {
    Column({ space: 12 }) {
      if (this.title) {
        Text(this.title)
          .fontSize(this.isTablet ? 17 : 15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .width('100%')
          .padding({ left: this.isTablet ? 20 : 16, right: this.isTablet ? 20 : 16 })
      }
      this.content()
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(this.isTablet ? 16 : 12)
    .padding({ top: 12, bottom: 12 })
  }
}

interface EmptyStateConfig {
  icon: string;
  title: string;
  subtitle: string;
  actionText: string;
}

/**
 * 通用空状态组件
 */
@Component
export struct EmptyState {
  @Prop icon: string = '📭';
  @Prop title: string = '暂无数据';
  @Prop subtitle: string = '';
  @Prop actionText: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop isTablet: boolean = false;
  onAction?: () => void;

  build() {
    Column({ space: 20 }) {
      Column() {
        Text(this.icon)
          .fontSize(this.isTablet ? 64 : 56)
      }
      .width(100)
      .height(100)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
      .borderRadius(50)

      Column({ space: 8 }) {
        Text(this.title)
          .fontSize(this.isTablet ? 18 : 16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')

        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(this.isTablet ? 14 : 12)
            .fontColor(this.isDarkMode ? '#666666' : '#999999')
        }
      }

      if (this.actionText && this.onAction) {
        Button(this.actionText)
          .fontSize(this.isTablet ? 15 : 14)
          .fontWeight(FontWeight.Medium)
          .height(this.isTablet ? 48 : 44)
          .padding({ left: this.isTablet ? 32 : 24, right: this.isTablet ? 32 : 24 })
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .shadow({
            radius: 10,
            color: 'rgba(0,125,255,0.3)',
            offsetY: 4
          })
          .onClick(() => {
            if (this.onAction) {
              this.onAction();
            }
          })
      }
    }
    .width('100%')
    .padding({ top: 80, bottom: 80 })
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 通用加载状态组件
 */
@Component
export struct LoadingState {
  @Prop text: string = '加载中...';
  @Prop isDarkMode: boolean = false;

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.isDarkMode ? '#FFFFFF' : '#007DFF')

      Text(this.text)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 通用错误状态组件
 */
@Component
export struct ErrorState {
  @Prop message: string = '加载失败';
  @Prop isDarkMode: boolean = false;
  onRetry?: () => void;

  build() {
    Column({ space: 12 }) {
      Text('⚠️')
        .fontSize(48)

      Text(this.message)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')

      if (this.onRetry) {
        Button('重试')
          .height(36)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(18)
          .onClick(() => {
            if (this.onRetry) {
              this.onRetry();
            }
          })
      }
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }
}
