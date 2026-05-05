/**
 * 统一头像组件
 * 支持图片、文字头像、多种尺寸和圆形/方形
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

/**
 * AppAvatar 组件属性
 * @imageUrl - 头像图片URL（可选）
 * @text - 文字头像文本（可选）
 * @size - 头像尺寸：xs | sm | md | lg | xl
 * @shape - 头像形状：circle | square
 * @backgroundColor - 背景颜色（可选，用于文字头像）
 */
@ComponentV2
export struct AppAvatar {
  @Param imageUrl?: string;
  @Param text?: string;
  @Param size: 'xs' | 'sm' | 'md' | 'lg' | 'xl' = 'md';
  @Param shape: 'circle' | 'square' = 'circle';
  @Param backgroundColor?: string;
  @Param isDarkMode: boolean = false;

  /**
   * 根据尺寸获取头像大小
   * @returns 头像宽高（vp）
   */
  private getSize(): number {
    switch (this.size) {
      case 'xs': return 24;
      case 'sm': return 32;
      case 'md': return 40;
      case 'lg': return 48;
      case 'xl': return 64;
      default: return 40;
    }
  }

  /**
   * 根据尺寸获取字体大小
   * @returns 字体大小（fp）
   */
  private getFontSize(): number {
    switch (this.size) {
      case 'xs': return 12;
      case 'sm': return 14;
      case 'md': return 16;
      case 'lg': return 18;
      case 'xl': return 24;
      default: return 16;
    }
  }

  /**
   * 获取头像背景颜色
   * @returns 颜色值
   */
  private getBackgroundColor(): string {
    if (this.backgroundColor && this.backgroundColor.length > 0) {
      return this.backgroundColor;
    }
    return COMMON_COLORS.PRIMARY_BLUE;
  }

  build() {
    if (this.imageUrl && this.imageUrl.length > 0) {
      Image(this.imageUrl)
        .width(this.getSize())
        .height(this.getSize())
        .borderRadius(this.shape === 'circle' ? this.getSize() / 2 : 8)
        .objectFit(ImageFit.Cover)
    } else {
      Text(this.getText())
        .fontSize(this.getFontSize())
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .width(this.getSize())
        .height(this.getSize())
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getBackgroundColor())
        .borderRadius(this.shape === 'circle' ? this.getSize() / 2 : 8)
    }
  }

  private getText(): string {
    if (this.text && this.text.length > 0) {
      return this.text.substring(0, 1);
    }
    return 'A';
  }
}
