/**
 * 统一下拉刷新组件
 * 支持下拉刷新、加载中和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

/**
 * AppPullToRefresh 组件属性
 */
@ComponentV2
export struct AppPullToRefresh {
  @BuilderParam content: () => void;
  @Param isRefreshing: boolean = false;
  @Param refreshingText: string = '正在刷新...';
  @Param pullText: string = '下拉刷新';
  @Param isDarkMode: boolean = false;
  onRefreshCallback?: () => void;

  /**
   * 刷新指示器构建器
   */
  @Builder
  refreshBuilder() {
    Column({ space: 8 }) {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(COMMON_COLORS.PRIMARY_BLUE)

      Text(this.isRefreshing ? this.refreshingText : this.pullText)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
    }
    .padding(16)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Refresh({ refreshing: this.isRefreshing, builder: this.refreshBuilder() }) {
      this.content()
    }
    .onRefreshing(() => {
      if (this.onRefreshCallback) {
        this.onRefreshCallback();
      }
    })
  }
}
