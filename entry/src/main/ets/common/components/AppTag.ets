/**
 * 统一标签组件
 * 支持多种样式、尺寸、可关闭和无障碍访问
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

/**
 * AppTag 组件属性
 * @text - 标签文本
 * @type - 标签类型：primary | success | warning | error | info
 * @size - 标签尺寸：sm | md | lg
 * @closable - 是否可关闭
 * @onClose - 关闭按钮回调
 */
@ComponentV2
export struct AppTag {
  @Param text: string = '';
  @Param type: 'primary' | 'success' | 'warning' | 'error' | 'info' = 'primary';
  @Param size: 'sm' | 'md' | 'lg' = 'md';
  @Param closable: boolean = false;
  @Param isDarkMode: boolean = false;
  onClose?: () => void;

  /**
   * 根据类型获取背景颜色
   * @returns 带透明度的背景颜色
   */
  private getBackgroundColor(): string {
    switch (this.type) {
      case 'primary': return 'rgba(0,125,255,0.1)';
      case 'success': return 'rgba(52,199,89,0.1)';
      case 'warning': return 'rgba(255,149,0,0.1)';
      case 'error': return 'rgba(255,59,48,0.1)';
      case 'info': return 'rgba(90,200,250,0.1)';
      default: return 'rgba(0,125,255,0.1)';
    }
  }

  /**
   * 根据类型获取文字颜色
   * @returns 颜色值
   */
  private getTextColor(): string {
    switch (this.type) {
      case 'primary': return COMMON_COLORS.PRIMARY_BLUE;
      case 'success': return COMMON_COLORS.SUCCESS_GREEN;
      case 'warning': return COMMON_COLORS.WARNING_ORANGE;
      case 'error': return COMMON_COLORS.ERROR_RED;
      case 'info': return COMMON_COLORS.CYAN;
      default: return COMMON_COLORS.PRIMARY_BLUE;
    }
  }

  /**
   * 根据尺寸获取字体大小
   * @returns 字体大小（fp）
   */
  private getFontSize(): number {
    switch (this.size) {
      case 'sm': return 11;
      case 'md': return 12;
      case 'lg': return 13;
      default: return 12;
    }
  }

  build() {
    Row({ space: 4 }) {
      Text(this.text)
        .fontSize(this.getFontSize())
        .fontColor(this.getTextColor())
        .padding({ left: 8, right: this.closable ? 4 : 8, top: 4, bottom: 4 })

      if (this.closable) {
        Text('×')
          .fontSize(this.getFontSize() + 2)
          .fontColor(this.getTextColor())
          .width(16)
          .height(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })
      }
    }
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(4)
  }
}
