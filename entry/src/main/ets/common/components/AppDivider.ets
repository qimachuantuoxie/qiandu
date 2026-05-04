/**
 * 统一分割线组件
 * 支持水平/垂直、带文本和无障碍访问
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppDivider 组件属性
 * @text - 分割线中间文本（可选）
 * @vertical - 是否垂直分割
 * @color - 分割线颜色（可选）
 */
@ComponentV2
export struct AppDivider {
  @Param text?: string;
  @Param vertical: boolean = false;
  @Param color?: string;
  @Param isDarkMode: boolean = false;

  build() {
    if (this.vertical) {
      Divider()
        .vertical(true)
        .color(this.getColor())
        .strokeWidth(1)
        .height(20)
    } else if (this.text && this.text.length > 0) {
      Row() {
        Divider()
          .color(this.getColor())
          .strokeWidth(1)
          .layoutWeight(1)

        Text(this.text)
          .fontSize(12)
          .fontColor(this.isDarkMode ? '#888888' : '#999999')
          .padding({ left: 12, right: 12 })

        Divider()
          .color(this.getColor())
          .strokeWidth(1)
          .layoutWeight(1)
      }
      .width('100%')
    } else {
      Divider()
        .color(this.getColor())
        .strokeWidth(1)
    }
  }

  private getColor(): string {
    if (this.color && this.color.length > 0) {
      return this.color;
    }
    return this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)';
  }
