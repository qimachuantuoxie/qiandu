/**
 * HDS Button Component - 基于华为设计规范的按钮组件
 * 
 * 支持多种样式：Primary、Secondary、Outline、Text
 */

import { HDSColours, HDSSpacing, HDSBorderRadius, HDSAnimation } from '../../design/tokens/HDSDTokens';
import { themeManager } from '../../utils/AppTheme';
import { fontScaleManager } from '../../utils/FontScaleManager';

/**
 * 按钮类型
 */
export enum HDSButtonType {
  Primary = 'primary',      // 主要按钮（填充）
  Secondary = 'secondary',  // 次要按钮（填充）
  Outline = 'outline',      // 描边按钮
  Text = 'text'             // 文本按钮
}

/**
 * 按钮尺寸
 */
export enum HDSButtonSize {
  Small = 'small',          // 小按钮
  Medium = 'medium',        // 中按钮
  Large = 'large'           // 大按钮
}

@ComponentV2
export struct HDSButton {
  @Param text: string;
  @Param type: HDSButtonType = HDSButtonType.Primary;
  @Param size: HDSButtonSize = HDSButtonSize.Medium;
  @Param icon?: Resource | string;
  @Param disabled: boolean = false;
  @Param loading: boolean = false;
  @Param fullWidth: boolean = false;
  @Param onClick?: () => void;
  
  @Local isDarkMode: boolean = themeManager.isDarkMode();
  @Local isPressed: boolean = false;

  // 根据类型和状态获取背景色
  private getBackgroundColor(): string {
    if (this.disabled) {
      return this.isDarkMode ? HDSColours.neutralDark.bgTertiary : HDSColours.neutral.gray200;
    }
    
    if (this.isPressed) {
      switch (this.type) {
        case HDSButtonType.Primary:
          return HDSColours.primary.darkBlue;
        case HDSButtonType.Secondary:
          return HDSColours.success;
        default:
          return 'transparent';
      }
    }
    
    switch (this.type) {
      case HDSButtonType.Primary:
        return HDSColours.primary.blue;
      case HDSButtonType.Secondary:
        return HDSColours.success;
      case HDSButtonType.Outline:
      case HDSButtonType.Text:
        return 'transparent';
      default:
        return HDSColours.primary.blue;
    }
  }

  // 根据类型和状态获取文字颜色
  private getTextColor(): string {
    if (this.disabled) {
      return this.isDarkMode ? HDSColours.neutralDark.textTertiary : HDSColours.neutral.gray500;
    }
    
    switch (this.type) {
      case HDSButtonType.Primary:
      case HDSButtonType.Secondary:
        return HDSColours.neutral.white;
      case HDSButtonType.Outline:
        return this.isDarkMode ? HDSColours.primary.lightBlue : HDSColours.primary.blue;
      case HDSButtonType.Text:
        return this.isDarkMode ? HDSColours.primary.lightBlue : HDSColours.primary.blue;
      default:
        return HDSColours.neutral.white;
    }
  }

  // 根据类型获取边框
  private getBorder(): BorderOptions | undefined {
    if (this.type === HDSButtonType.Outline && !this.disabled) {
      return {
        width: 1,
        color: this.isDarkMode ? HDSColours.primary.lightBlue : HDSColours.primary.blue,
        radius: this.getBorderRadius()
      };
    }
    return undefined;
  }

  // 根据尺寸获取高度
  private getHeight(): number {
    switch (this.size) {
      case HDSButtonSize.Small:
        return 36;
      case HDSButtonSize.Large:
        return 56;
      default:
        return 48;
    }
  }

  // 根据尺寸获取字体大小
  private getFontSize(): number {
    switch (this.size) {
      case HDSButtonSize.Small:
        return 14;
      case HDSButtonSize.Large:
        return 18;
      default:
        return 16;
    }
  }

  // 根据尺寸获取圆角
  private getBorderRadius(): number {
    switch (this.size) {
      case HDSButtonSize.Small:
        return HDSBorderRadius.sm;
      case HDSButtonSize.Large:
        return HDSBorderRadius.xl;
      default:
        return HDSBorderRadius.md;
    }
  }

  // 根据尺寸获取内边距
  private getPadding(): Padding {
    switch (this.size) {
      case HDSButtonSize.Small:
        return { left: HDSSpacing.md, right: HDSSpacing.md };
      case HDSButtonSize.Large:
        return { left: HDSSpacing.xl, right: HDSSpacing.xl };
      default:
        return { left: HDSSpacing.lg, right: HDSSpacing.lg };
    }
  }

  build() {
    Row({ space: HDSSpacing.sm }) {
      // 加载图标
      if (this.loading) {
        LoadingProgress()
          .width(this.size === HDSButtonSize.Small ? 16 : 20)
          .height(this.size === HDSButtonSize.Small ? 16 : 20)
          .color(this.getTextColor())
      }
      
      // 图标（可选）
      if (!this.loading && this.icon) {
        if (typeof this.icon === 'string') {
          Text(this.icon as string)
            .fontSize(this.getFontSize())
            .fontColor(this.getTextColor())
        } else {
          Image(this.icon as Resource)
            .width(this.size === HDSButtonSize.Small ? 16 : 20)
            .height(this.size === HDSButtonSize.Small ? 16 : 20)
            .fillColor(this.getTextColor())
        }
      }
      
      // 按钮文字
      Text(this.text)
        .fontSize(fontScaleManager.getScaledFontSize(this.getFontSize()))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getTextColor())
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Middle)
    .width(this.fullWidth ? '100%' : 'auto')
    .minWidth(this.size === HDSButtonSize.Large ? 120 : (this.size === HDSButtonSize.Small ? 80 : 100))
    .height(this.getHeight())
    .padding(this.getPadding())
    .backgroundColor(this.getBackgroundColor())
    .border(this.getBorder())
    .borderRadius(this.getBorderRadius())
    .enabled(!this.disabled && !this.loading)
    .scale({
      x: this.isPressed && !this.disabled ? 0.96 : 1,
      y: this.isPressed && !this.disabled ? 0.96 : 1
    })
    .animation({
      duration: HDSAnimation.fast,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      if (!this.disabled && !this.loading && this.onClick) {
        this.onClick();
      }
    })
    .onTouch((event: TouchEvent) => {
      if (!this.disabled && !this.loading) {
        if (event.type === TouchType.Down) {
          this.isPressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      }
    })
  }
}
