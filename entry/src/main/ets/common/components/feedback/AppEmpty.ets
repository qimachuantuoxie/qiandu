/**
 * 统一空状态组件
 * 支持自定义图标、文本和操作按钮
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';
import { EMPTY_STATE_ICONS } from '../../../core/constants/UIIcons';

/**
 * AppEmpty 组件属性
 */
@ComponentV2
export struct AppEmpty {
  @Param icon: string = EMPTY_STATE_ICONS.DEFAULT;
  @Param title: string = '暂无数据';
  @Param subtitle: string = '';
  @Param actionText: string = '';
  @Param isDarkMode: boolean = false;
  onActionCallback?: () => void;

  build() {
    Column({ space: 12 }) {
      Text(this.icon)
        .fontSize(64)
        .margin({ top: 40, bottom: 16 })

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      if (this.subtitle && this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
          .textAlign(TextAlign.Center)
      }

      if (this.actionText && this.actionText.length > 0) {
        Button(this.actionText)
          .margin({ top: 16 })
          .height(40)
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .fontColor('#FFFFFF')
          .fontSize(14)
          .borderRadius(8)
          .onClick(() => {
            if (this.onActionCallback) {
              this.onActionCallback();
            }
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
