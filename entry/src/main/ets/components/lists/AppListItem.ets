/**
 * 统一列表项组件
 * 支持图标、徽章、副标题和无障碍访问
 */

import { TouchType } from '@kit.ArkUI';
import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppListItem 组件属性
 */
@Component
export struct AppListItem {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop icon: string = '';
  @Prop showArrow: boolean = true;
  @Prop badge: string = '';
  @Prop badgeColor: string = '';
  @Prop isDarkMode: boolean = false;
  onClick?: () => void;

  @State isPressed: boolean = false;

  build() {
    Row() {
      // 图标
      if (this.icon && this.icon.length > 0) {
        Text(this.icon)
          .fontSize(22)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 })
      }

      // 标题和副标题
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.subtitle && this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(13)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ right: 8 })

      // 徽章
      if (this.badge && this.badge.length > 0) {
        Text(this.badge)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.getBadgeColor())
          .borderRadius(10)
          .margin({ right: 8 })
      }

      // 箭头
      if (this.showArrow) {
        Text('›')
          .fontSize(20)
          .fontColor(this.isDarkMode ? '#666666' : '#CCCCCC')
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isPressed
      ? (this.isDarkMode ? '#2C2C2E' : '#F5F5F5')
      : (this.isDarkMode ? '#1C1C1E' : '#FFFFFF'))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      if (this.onClick) {
        this.onClick();
      }
    })
  }

  private getBadgeColor(): string {
    if (this.badgeColor && this.badgeColor.length > 0) {
      return this.badgeColor;
    }
    return COMMON_COLORS.PRIMARY_BLUE;
  }
}
