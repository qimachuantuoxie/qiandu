/**
 * HDS Card Component - 基于华为设计规范的卡片组件
 * 
 * 支持浅色/深色模式、阴影、圆角、动画效果
 */

import { HDSColours, HDSSpacing, HDSBorderRadius, HDSShadows } from '../../design/tokens/HDSDTokens';
import { themeManager } from '../../utils/AppTheme';

@ComponentV2
export struct HDSCard {
  @Param title?: string;
  @Param subtitle?: string;
  @Param icon?: Resource | string;
  @Param padding: number = HDSSpacing.lg;
  @Param margin: number = HDSSpacing.md;
  @Param borderRadius: number = HDSBorderRadius.lg;
  @Param shadow: boolean = true;
  @Param onClick?: () => void;
  @BuilderParam content: () => void;
  
  @Local isDarkMode: boolean = themeManager.isDarkMode();
  @Local isPressed: boolean = false;

  build() {
    Column() {
      // 标题区域（可选）
      if (this.title) {
        Row({ space: HDSSpacing.sm }) {
          // 图标（可选）
          if (this.icon) {
            if (typeof this.icon === 'string') {
              Text(this.icon as string)
                .fontSize(20)
            } else {
              Image(this.icon as Resource)
                .width(24)
                .height(24)
            }
          }
          
          Column({ space: 2 }) {
            Text(this.title!)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            
            if (this.subtitle) {
              Text(this.subtitle)
                .fontSize(12)
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: HDSSpacing.md })
      }
      
      // 内容区域
      Column() {
        this.content()
      }
      .width('100%')
    }
    .width('100%')
    .padding(this.padding)
    .margin(this.margin)
    .borderRadius(this.borderRadius)
    .backgroundColor(
      this.isDarkMode 
        ? HDSColours.neutralDark.surface 
        : HDSColours.neutral.white
    )
    .shadow(
      this.shadow && !this.isPressed
        ? (this.isDarkMode ? HDSShadows.dark.md : HDSShadows.light.md)
        : undefined
    )
    .scale({
      x: this.isPressed ? 0.98 : 1,
      y: this.isPressed ? 0.98 : 1
    })
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      if (this.onClick) {
        this.onClick();
      }
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }
}
