/**
 * 系统符号图标组件
 * 统一封装 SymbolGlyph，简化使用方式
 * 
 * @since 3.0.0
 */

import { themeManager, AppColors } from '../../core/utils/AppTheme';
import { fontScaleManager } from '../../core/utils/FontScaleManager';

/**
 * 系统符号图标组件
 * 
 * @param symbol 符号名称（不含 sys.symbol. 前缀）
 * @param size 图标尺寸（默认 24）
 * @param color 图标颜色（默认当前主题色）
 */
@ComponentV2
export struct SysIcon {
  @Param symbol: string = '';
  @Param size: number = 24;
  @Param color: string = '';
  @Local currentColors: AppColors = themeManager.getColors();

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
@ComponentV2
export struct PrimaryIcon {
  @Param symbol: string = '';
  @Param size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().primary])
  }
}

/**
 * 次要色系统符号组件
 */
@ComponentV2
export struct SecondaryIcon {
  @Param symbol: string = '';
  @Param size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().onSurfaceVariant])
  }
}

/**
 * 成功色系统符号组件
 */
@ComponentV2
export struct SuccessIcon {
  @Param symbol: string = '';
  @Param size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().success])
  }
}

/**
 * 警告色系统符号组件
 */
@ComponentV2
export struct WarningIcon {
  @Param symbol: string = '';
  @Param size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().warning])
  }
}

/**
 * 错误色系统符号组件
 */
@ComponentV2
export struct ErrorIcon {
  @Param symbol: string = '';
  @Param size: number = 24;

  build() {
    SymbolGlyph($r(`sys.symbol.${this.symbol}`))
      .fontSize(this.size)
      .fontColor([themeManager.getColors().error])
  }
}
