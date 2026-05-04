/**
 * 统一进度条组件
 * 支持线性/环形进度、自定义颜色和无障碍访问
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';
import { MaterialProgressBar, MaterialModel } from '../feedback/MaterialProgressBar';

/**
 * AppProgress 组件属性
 * @value - 当前进度值
 * @max - 进度最大值
 * @type - 进度条类型：linear | circular
 * @color - 进度条颜色（可选）
 * @showText - 是否显示百分比文本
 */
@ComponentV2
export struct AppProgress {
  @Param value: number = 0;
  @Param max: number = 100;
  @Param type: 'linear' | 'circular' = 'linear';
  @Param color?: string;
  @Param showText: boolean = true;
  @Param isDarkMode: boolean = false;

  build() {
    if (this.type === 'linear') {
      Column({ space: 8 }) {
        MaterialProgressBar({
          style: 'MaterialHorizontal',
          modelBuild: {
            progress: this.max > 0 ? (this.value / this.max) * 100 : 0,
            color: this.getColor(),
            strokeWidth: 8,
            bgColor: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)'
          }
        })
        .width('100%')
        .height(8)

        if (this.showText && this.max > 0) {
          Text(this.getPercentText())
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        }
      }
    } else {
      Stack() {
        MaterialProgressBar({
          style: 'MaterialCircular',
          modelBuild: {
            progress: this.max > 0 ? (this.value / this.max) * 100 : 0,
            color: this.getColor(),
            strokeWidth: 6,
            radius: 32
          }
        })
        .width(64)
        .height(64)

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
