/**
 * 缁熶竴椤甸潰鏍峰紡宸ュ叿绫?- 鏁村悎鎵€鏈夐〉闈㈡牱寮忚鑼? * Unified Page Style Utils - Provide global style constants and helper methods
 *
 * 鏁村悎鑷細PageStyleHelper.ets, PageStyleMixin.ets, PageStyles.ets
 *
 * 鎻愪緵锛? * - 棰滆壊绠＄悊锛堟枃瀛椼€佽儗鏅€佷富棰樿壊銆侀€忔槑搴︼級
 * - 闂磋窛瑙勮寖
 * - 鍦嗚瑙勮寖
 * - 瀛椾綋瑙勮寖
 * - 闃村奖瑙勮寖
 * - 鍔ㄧ敾瑙勮寖
 * - 蹇嵎鏂规硶
 */

import { curves } from '@kit.ArkUI';
import { appTheme, COMMON_COLORS, AppColors, LIGHT_COLORS, DARK_COLORS } from '../../common/constants/AppTheme';

// ==================== 绫诲瀷瀹氫箟 ====================

/**
 * 闃村奖閰嶇疆鎺ュ彛
 */
export interface ElevationConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

/**
 * 鍔ㄧ敾閰嶇疆鎺ュ彛
 */
export interface AnimationConfig {
  duration: number;
  curve: curves.Curve;
}

/**
 * 鎸夊帇鐘舵€佹牱寮忛泦鍚?- 瀵瑰簲 ArkUI stateStyles API
 */
export interface ScaleOption {
  x: number;
  y: number;
}

export interface StateStyle {
  scale?: ScaleOption;
  opacity?: number;
  backgroundColor?: string;
}

export interface PressedStyleSet {
  pressed: StateStyle;
  normal: StateStyle;
}

/**
 * 椤甸潰鏍峰紡宸ュ叿绫?- 涓诲叆鍙? */
export class PageStyles {
  // ==================== 棰滆壊绠＄悊 ====================

  /**
   * 鑾峰彇鏂囧瓧棰滆壊锛堟繁鑹叉ā寮忛€傞厤锛?   */
  static textColor(isDarkMode: boolean, level: 'primary' | 'secondary' | 'tertiary' = 'primary'): string {
    const colors = isDarkMode ? DARK_COLORS : LIGHT_COLORS;
    switch (level) {
      case 'primary':
        return colors.onSurface;
      case 'secondary':
        return colors.onSurfaceVariant;
      case 'tertiary':
        return colors.textHint;
      default:
        return colors.onSurface;
    }
  }

  /**
   * 鑾峰彇鑳屾櫙棰滆壊
   */
  static bgColor(isDarkMode: boolean, level: 'page' | 'card' | 'input' | 'surface' = 'page'): string {
    const colors = isDarkMode ? DARK_COLORS : LIGHT_COLORS;
    switch (level) {
      case 'page':
        return colors.background;
      case 'card':
        return colors.cardBackground;
      case 'input':
        return colors.surfaceVariant;
      case 'surface':
        return colors.surfaceVariant;
      default:
        return colors.background;
    }
  }

  /**
   * 鑾峰彇涓婚棰滆壊
   */
  static themeColor(name: 'primary' | 'success' | 'warning' | 'error'): string {
    switch (name) {
      case 'primary':
        return COMMON_COLORS.PRIMARY_BLUE;
      case 'success':
        return COMMON_COLORS.SUCCESS_GREEN;
      case 'warning':
        return COMMON_COLORS.WARNING_ORANGE;
      case 'error':
        return COMMON_COLORS.ERROR_RED;
      default:
        return COMMON_COLORS.PRIMARY_BLUE;
    }
  }

  /**
   * 鑾峰彇閫忔槑搴﹂鑹?   */
  static opacityColor(isDarkMode: boolean, type: 'light' | 'medium' | 'dark'): string {
    switch (type) {
      case 'light':
        return isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.02)';
      case 'medium':
        return isDarkMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.04)';
      case 'dark':
        return isDarkMode ? 'rgba(0,0,0,0.4)' : 'rgba(0,0,0,0.06)';
      default:
        return isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.02)';
    }
  }

  // ==================== 蹇嵎鏂规硶 ====================

  /**
   * 鑾峰彇涓昏壊璋冭儗鏅紙鍚€忔槑搴︼級
   */
  static primaryBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(0,125,255,0.15)' : 'rgba(0,125,255,0.05)';
  }

  /**
   * 鑾峰彇鎴愬姛鑹茶儗鏅?   */
  static successBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(52,199,89,0.15)' : 'rgba(52,199,89,0.05)';
  }

  /**
   * 鑾峰彇璀﹀憡鑹茶儗鏅?   */
  static warningBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(250,140,22,0.15)' : 'rgba(250,140,22,0.05)';
  }

  /**
   * 鑾峰彇閿欒鑹茶儗鏅?   */
  static errorBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(255,59,48,0.15)' : 'rgba(255,59,48,0.05)';
  }

  // ==================== 闂磋窛瑙勮寖 ====================

  /**
   * 鑾峰彇闂磋窛鍊?   */
  static spacing(size: 'xs' | 'sm' | 'md' | 'lg' | 'xl'): number {
    switch (size) {
      case 'xs':
        return 4;
      case 'sm':
        return 8;
      case 'md':
        return 12;
      case 'lg':
        return 16;
      case 'xl':
        return 24;
      default:
        return 0;
    }
  }

  // ==================== 鍦嗚瑙勮寖 ====================

  /**
   * 鑾峰彇鍦嗚鍊?   */
  static radius(size: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'full' = 'md'): number {
    switch (size) {
      case 'xs':
        return 4;
      case 'sm':
        return 8;
      case 'md':
        return 12;
      case 'lg':
        return 16;
      case 'xl':
        return 20;
      case 'full':
        return 999;
      default:
        return 12;
    }
  }

  // ==================== 瀛椾綋瑙勮寖 ====================

  /**
   * 鑾峰彇瀛椾綋澶у皬
   */
  static fontSize(size: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl'): number {
    switch (size) {
      case 'xs':
        return 10;
      case 'sm':
        return 12;
      case 'md':
        return 14;
      case 'lg':
        return 16;
      case 'xl':
        return 18;
      case 'xxl':
        return 22;
      default:
        return 14;
    }
  }

  // ==================== 闃村奖瑙勮寖 ====================

  /**
   * 鑾峰彇闃村奖閰嶇疆
   */
  static elevation(level: 'none' | 'sm' | 'md' | 'lg' | 'xl', isDarkMode: boolean = false): ElevationConfig | undefined {
    switch (level) {
      case 'none':
        return undefined;
      case 'sm':
        return { radius: 4, color: isDarkMode ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 1 };
      case 'md':
        return { radius: 8, color: isDarkMode ? 'rgba(0,0,0,0.25)' : 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 2 };
      case 'lg':
        return { radius: 12, color: isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.16)', offsetX: 0, offsetY: 4 };
      case 'xl':
        return { radius: 16, color: isDarkMode ? 'rgba(0,0,0,0.35)' : 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 8 };
      default:
        return undefined;
    }
  }

  // ==================== 鍔ㄧ敾瑙勮寖 ====================

  /**
   * 鑾峰彇鏍囧噯鍔ㄧ敾閰嶇疆
   */
  static animation(duration: 'fast' | 'normal' | 'slow' = 'normal'): AnimationConfig {
    switch (duration) {
      case 'fast':
        return { duration: 150, curve: curves.Curve.EaseOut };
      case 'normal':
        return { duration: 300, curve: curves.Curve.EaseInOut };
      case 'slow':
        return { duration: 500, curve: curves.Curve.EaseInOut };
      default:
        return { duration: 300, curve: curves.Curve.EaseInOut };
    }
  }

  /**
   * 鑾峰彇鎸夊帇鎬佹牱寮?   */
  static pressedStyle(scale: number = 0.96, opacity: number = 0.8): PressedStyleSet {
    return {
      pressed: {
        scale: { x: scale, y: scale },
        opacity: opacity
      },
      normal: {
        scale: { x: 1, y: 1 },
        opacity: 1
      }
    };
  }
}

/**
 * 椤甸潰鏍峰紡 Mixin - 鎻愪緵 tc/bg 蹇嵎鏂规硶
 * 浣跨敤鏂规硶锛? * 1. 鍦ㄩ〉闈腑瀹氫箟: @State isDarkMode: boolean = false;
 * 2. 鍦?aboutToAppear 涓? this.isDarkMode = appTheme.isDarkMode();
 * 3. 缁ф壙璇ョ被鎴栧鍒舵柟娉曞埌缁勪欢涓? */
export class PageStyleMixin {
  isDarkMode: boolean = false;

  /**
   * 鏂囧瓧棰滆壊蹇嵎鏂规硶 (light: 娴呰壊妯″紡鍊? dark: 娣辫壊妯″紡鍊?
   */
  tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鑳屾櫙棰滆壊蹇嵎鏂规硶 (light: 娴呰壊妯″紡鍊? dark: 娣辫壊妯″紡鍊?
   */
  bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鎸夊帇鏁堟灉锛堟坊鍔犲埌鍙偣鍑诲厓绱狅級
   */
  getPressedStyle(): PressedStyleSet {
    return {
      pressed: {
        scale: { x: 0.96, y: 0.96 },
        opacity: 0.8
      },
      normal: {
        scale: { x: 1, y: 1 },
        opacity: 1
      }
    };
  }
}
