/**
 * 统一进度条组件
 * 支持线性/环形进度、自定义颜色和无障碍访问
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppProgress 组件属性
 * @value - 当前进度值
 * @max - 进度最大值
 * @type - 进度条类型：linear | circular
 * @color - 进度条颜色（可选）
 * @showText - 是否显示百分比文本
 */
@Component
export struct AppProgress {
  @Prop value: number = 0;
  @Prop max: number = 100;
  @Prop type: 'linear' | 'circular' = 'linear';
  @Prop color?: string;
  @Prop showText: boolean = true;
  @Prop isDarkMode: boolean = false;

  build() {
    if (this.type === 'linear') {
      Column({ space: 8 }) {
        Progress({ value: this.value, total: this.max })
          .width('100%')
          .color(this.getColor())
          .style({ strokeWidth: 8 })

        if (this.showText && this.max > 0) {
          Text(this.getPercentText())
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        }
      }
    } else {
      Stack() {
        Progress({ value: this.value, total: this.max })
          .width(64)
          .height(64)
          .color(this.getColor())
          .style({ strokeWidth: 6 })

        if (this.showText && this.max > 0) {
          Text(this.getPercentText())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        }
      }
    }
  }

  private getColor(): string {
    if (this.color && this.color.length > 0) {
      return this.color;
    }
    return COMMON_COLORS.PRIMARY_BLUE;
  }

  private getPercentText(): string {
    if (this.max > 0) {
      const percent: number = Math.round((this.value / this.max) * 100);
      return percent + '%';
    }
    return '0%';
  }
