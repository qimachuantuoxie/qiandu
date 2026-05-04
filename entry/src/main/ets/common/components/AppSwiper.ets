/**
 * 统一轮播组件
 * 支持自动播放、指示器和无障碍访问
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

/**
 * AppSwiper 组件属性
 * @content - 轮播内容构建器（接收索引参数）
 * @count - 轮播项数量
 * @autoPlay - 是否自动播放
 * @interval - 自动播放间隔（毫秒）
 * @showIndicator - 是否显示指示器
 * @indicatorColor - 指示器激活颜色（可选）
 * @onIndexChanged - 索引变化回调
 */
@ComponentV2
export struct AppSwiper {
  @BuilderParam content: (index: number) => void;
  @Param count: number = 0;
  @Param autoPlay: boolean = true;
  @Param interval: number = 3000;
  @Param showIndicator: boolean = true;
  @Param indicatorColor?: string;
  @Param isDarkMode: boolean = false;
  onIndexChanged?: (index: number) => void;

  @Local currentIndex: number = 0;

  build() {
    Stack() {
      Swiper() {
        ForEach(this.generateIndexArray(), (index: number) => {
          this.content(index)
        }, (index: number) => '' + index)
      }
      .autoPlay(this.shouldAutoPlay())
      .interval(this.interval)
      .indicator(false)
      .onChange((index: number) => {
        const nextIndex: number = this.clampIndex(index);
        this.currentIndex = nextIndex;
        if (this.onIndexChanged) {
          this.onIndexChanged(nextIndex);
        }
      })

      if (this.showIndicator && this.count > 1) {
        Row({ space: 6 }) {
          ForEach(this.generateIndexArray(), (index: number) => {
            Row()
              .width(this.getSafeCurrentIndex() === index ? 20 : 6)
              .height(6)
              .backgroundColor(this.getSafeCurrentIndex() === index ? this.getIndicatorColor() : (this.isDarkMode ? '#555555' : '#CCCCCC'))
              .borderRadius(3)
              .animation({ duration: 200 })
          }, (index: number) => '' + index)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .position({ bottom: 12 })
      }
    }
  }

  private shouldAutoPlay(): boolean {
    return this.autoPlay && this.count > 1;
  }

  private generateIndexArray(): number[] {
    const arr: number[] = [];
    for (let i = 0; i < this.count; i++) {
      arr.push(i);
    }
    return arr;
  }

  private clampIndex(index: number): number {
    if (this.count <= 0 || index < 0) {
      return 0;
    }
    if (index >= this.count) {
      return this.count - 1;
    }
    return index;
  }

  private getSafeCurrentIndex(): number {
    return this.clampIndex(this.currentIndex);
  }

  private getIndicatorColor(): string {
    if (this.indicatorColor && this.indicatorColor.length > 0) {
      return this.indicatorColor;
    }
    return COMMON_COLORS.PRIMARY_BLUE;
  }
