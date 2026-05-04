/**
 * 统一评分组件
 * 支持自定义星级、只读模式和无障碍访问
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppRating 组件属性
 * @value - 当前评分
 * @max - 最大评分
 * @readOnly - 是否只读模式
 * @size - 星星大小
 * @onChange - 评分变化回调
 */
@ComponentV2
export struct AppRating {
  @Param value: number = 0;
  @Param max: number = 5;
  @Param readOnly: boolean = false;
  @Param size: number = 20;
  @Param isDarkMode: boolean = false;
  onChange?: (value: number) => void;

  build() {
    Row({ space: 4 }) {
      ForEach(this.generateStarArray(), (star: number) => {
        Text(this.getStarText(star))
          .fontSize(this.size)
          .fontColor(star <= this.value ? '#FFC107' : (this.isDarkMode ? '#555555' : '#CCCCCC'))
          .onClick(() => {
            if (!this.readOnly && this.onChange) {
              this.onChange(star);
            }
          })
      }, (star: number) => '' + star)
    }
  }

  private generateStarArray(): number[] {
    const arr: number[] = [];
    for (let i = 1; i <= this.max; i++) {
      arr.push(i);
    }
    return arr;
  }

  private getStarText(star: number): string {
    if (star <= this.value) {
      return '★';
    }
    return '☆';
  }
