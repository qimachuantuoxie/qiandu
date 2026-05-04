/**
 * 统一提示消息组件
 * 支持多种类型、自动消失和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

/**
 * AppToast 组件属性
 */
@ComponentV2
export struct AppToast {
  @Param message: string = '';
  @Param type: 'success' | 'error' | 'warning' | 'info' = 'info';
  @Param duration: number = 2000;
  @Param visible: boolean = false;
  @Param isDarkMode: boolean = false;

  /**
   * 根据类型获取图标
   */
  private getIcon(): string {
    switch (this.type) {
      case 'success': return 'checkmark_circle';
      case 'error': return 'xmark_circle';
      case 'warning': return 'exclamationmark_triangle';
      case 'info': return 'info_circle';
      default: return 'info_circle';
    }
  }

  /**
   * 根据类型获取背景颜色
   */
  private getBackgroundColor(): string {
    switch (this.type) {
      case 'success': return COMMON_COLORS.SUCCESS_GREEN;
      case 'error': return COMMON_COLORS.ERROR_RED;
      case 'warning': return COMMON_COLORS.WARNING_ORANGE;
      case 'info': return COMMON_COLORS.CYAN;
      default: return COMMON_COLORS.CYAN;
    }
  }

  build() {
    if (this.visible && this.message.length > 0) {
      Row({ space: 8 }) {
        Text(this.getIcon())
          .fontSize(18)

        Text(this.message)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0,0,0,0.15)',
        offsetX: 0,
        offsetY: 4
      })
      .position({ x: '50%', y: 100 })
      .translate({ x: '-50%' })
      .animation({
        duration: 300,
        curve: Curve.EaseOut
      })
    }
}
