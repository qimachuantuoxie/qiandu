/**
 * 统一导航栏组件
 * 支持返回按钮、标题、副标题和自定义操作
 */

import { router } from '@kit.ArkUI';
import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppBar 组件属性
 */
@Component
export struct AppBar {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = true;
  @Prop backgroundColor: string = '';
  @Prop textColor: string = '';
  @Prop isDarkMode: boolean = false;
  onBack?: () => void;
  @BuilderParam actions: () => void = () => {};

  build() {
    Row() {
      // 返回按钮
      if (this.showBack) {
        Text('←')
          .fontSize(24)
          .fontColor(this.getTextColor())
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            } else {
              router.back();
            }
          })
      }

      // 标题
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.subtitle && this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 })

      // 右侧操作按钮
      if (this.actions) {
        Row() {
          this.actions()
        }
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getBackgroundColor())
    .shadow({
      radius: 4,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  private getBackgroundColor(): string {
    if (this.backgroundColor && this.backgroundColor.length > 0) {
      return this.backgroundColor;
    }
    return this.isDarkMode ? '#1C1C1E' : '#FFFFFF';
  }

  private getTextColor(): string {
    if (this.textColor && this.textColor.length > 0) {
      return this.textColor;
    }
    return this.isDarkMode ? '#FFFFFF' : '#1A1A1A';
  }
}
