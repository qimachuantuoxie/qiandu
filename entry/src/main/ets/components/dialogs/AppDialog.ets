/**
 * 统一对话框组件
 * 支持多种类型、自定义按钮和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppDialog 组件属性
 */
@Component
export struct AppDialog {
  @Prop title: string = '';
  @Prop message: string = '';
  @Prop confirmText: string = '确定';
  @Prop cancelText: string = '取消';
  @Prop showCancel: boolean = true;
  @Prop type: 'info' | 'warning' | 'error' | 'success' = 'info';
  @Prop isDarkMode: boolean = false;
  onConfirmCallback?: () => void;
  onCancelCallback?: () => void;

  /**
   * 根据对话框类型获取图标
   */
  private getIcon(): string {
    switch (this.type) {
      case 'info': return 'ℹ️';
      case 'warning': return '⚠️';
      case 'error': return '❌';
      case 'success': return '✅';
      default: return 'ℹ️';
    }
  }

  /**
   * 根据对话框类型获取图标颜色
   */
  private getIconColor(): string {
    switch (this.type) {
      case 'info': return COMMON_COLORS.CYAN;
      case 'warning': return COMMON_COLORS.WARNING_ORANGE;
      case 'error': return COMMON_COLORS.ERROR_RED;
      case 'success': return COMMON_COLORS.SUCCESS_GREEN;
      default: return COMMON_COLORS.CYAN;
    }
  }

  build() {
    Column() {
      // 图标
      Text(this.getIcon())
        .fontSize(48)
        .margin({ top: 24, bottom: 16 })

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .margin({ bottom: 12 })

      // 消息
      Text(this.message)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .textAlign(TextAlign.Center)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 24 })
        .padding({ left: 24, right: 24 })

      Divider()
        .color(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)')
        .strokeWidth(1)

      // 按钮组
      Row() {
        if (this.showCancel) {
          Button(this.cancelText)
            .layoutWeight(1)
            .height(44)
            .backgroundColor('rgba(0,0,0,0)')
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
            .fontSize(15)
            .onClick(() => {
              if (this.onCancelCallback) {
                this.onCancelCallback();
              }
            })

          Divider()
            .vertical(true)
            .color(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)')
            .height(44)
        }

        Button(this.confirmText)
          .layoutWeight(1)
          .height(44)
          .backgroundColor('rgba(0,0,0,0)')
          .fontColor(this.getIconColor())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.onConfirmCallback) {
              this.onConfirmCallback();
            }
          })
      }
    }
    .width('85%')
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(16)
  }
}
