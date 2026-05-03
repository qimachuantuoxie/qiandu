/**
 * 系统符号图标组件
 * 统一封装 SymbolGlyph，简化使用方式
 * 
 * @since 3.0.0
 */

import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';

/**
 * 系统符号图标组件
 * 
 * @param symbol 符号名称（不含 sys.symbol. 前缀）
 * @param size 图标尺寸（默认 24）
 * @param color 图标颜色（默认当前主题色）
 */
@Component
export struct SysIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;
  @Prop color: string = '';
  @State currentColors: AppColors = themeManager.getColors();

  build() {
    if (this.symbol && this.symbol.length > 0) {
      SymbolGlyph($r(`sys.symbol.${this.symbol}`))
        .fontSize(this.size)
        .fontColor([this.color && this.color.length > 0 ? this.color : this.currentColors.onSurface])
    } else {
      // 空占位
      Text('')
        .width(this.size)
        .height(this.size)
    }
  }
}

/**
 * 主色系统符号组件
 */
@Component
export struct PrimaryIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().primary])
  }
}

/**
 * 次要色系统符号组件
 */
@Component
export struct SecondaryIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().onSurfaceVariant])
  }
}

/**
 * 成功色系统符号组件
 */
@Component
export struct SuccessIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().success])
  }
}

/**
 * 警告色系统符号组件
 */
@Component
export struct WarningIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().warning])
  }
}

/**
 * 错误色系统符号组件
 */
@Component
export struct ErrorIcon {
  @Prop symbol: string = '';
  @Prop size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().error])
  }
}
