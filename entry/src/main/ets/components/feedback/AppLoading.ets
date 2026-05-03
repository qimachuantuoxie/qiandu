/**
 * 统一加载指示器组件
 * 支持自定义大小、颜色和文本
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppLoading 组件属性
 */
@Component
export struct AppLoading {
  @Prop text: string = '加载中...';
  @Prop size: number = 32;
  @Prop color: string = '';
  @Prop isDarkMode: boolean = false;

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(this.size)
        .height(this.size)
        .color(this.color && this.color.length > 0 ? this.color : COMMON_COLORS.PRIMARY_BLUE)

      if (this.text && this.text.length > 0) {
        Text(this.text)
          .fontSize(13)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
      }
    }
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
