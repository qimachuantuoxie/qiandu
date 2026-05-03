/**
 * 统一页面样式工具类 - 整合所有页面样式规范
 * Unified Page Style Utils - Provide global style constants and helper methods
 *
 * 整合自：PageStyleHelper.ets, PageStyleMixin.ets, PageStyles.ets
 *
 * 提供：
 * - 颜色管理（文字、背景、主题色、透明度）
 * - 间距规范
 * - 圆角规范
 * - 字体规范
 * - 阴影规范
 * - 动画规范
 * - 快捷方法
 */

import { curves } from '@kit.ArkUI';
import { appTheme, COMMON_COLORS, AppColors } from './AppTheme';

// ==================== 类型定义 ====================

/**
 * 阴影配置接口
 */
export interface ElevationConfig {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

/**
 * 动画配置接口
 */
export interface AnimationConfig {
  duration: number;
  curve: curves.Curve;
}

/**
 * 按压状态样式集合 - 对应 ArkUI stateStyles API
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
 * 页面样式工具类 - 主入口
 */
export class PageStyles {
  // ==================== 颜色管理 ====================

  /**
   * 获取文字颜色（深色模式适配）
   */
  static textColor(isDarkMode: boolean, level: 'primary' | 'secondary' | 'tertiary' = 'primary'): string {
    switch (level) {
      case 'primary':
        return isDarkMode ? '#FFFFFF' : '#1A1A1A';
      case 'secondary':
        return isDarkMode ? '#AAAAAA' : '#666666';
      case 'tertiary':
        return isDarkMode ? '#666666' : '#999999';
      default:
        return isDarkMode ? '#FFFFFF' : '#1A1A1A';
    }
  }

  /**
   * 获取背景颜色
   */
  static bgColor(isDarkMode: boolean, level: 'page' | 'card' | 'input' | 'surface' = 'page'): string {
    switch (level) {
      case 'page':
        return isDarkMode ? '#000000' : '#F5F5F7';
      case 'card':
        return isDarkMode ? '#1C1C1E' : '#FFFFFF';
      case 'input':
        return isDarkMode ? '#2C2C2E' : '#F5F5F5';
      case 'surface':
        return isDarkMode ? '#2C2C2E' : '#F5F5F5';
      default:
        return isDarkMode ? '#000000' : '#F5F5F7';
    }
  }

  /**
   * 获取主题颜色
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
   * 获取透明度颜色
   */
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

  // ==================== 快捷方法 ====================

  /**
   * 获取主色调背景（含透明度）
   */
  static primaryBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(0,125,255,0.15)' : 'rgba(0,125,255,0.05)';
  }

  /**
   * 获取成功色背景
   */
  static successBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(52,199,89,0.15)' : 'rgba(52,199,89,0.05)';
  }

  /**
   * 获取警告色背景
   */
  static warningBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(250,140,22,0.15)' : 'rgba(250,140,22,0.05)';
  }

  /**
   * 获取错误色背景
   */
  static errorBg(isDarkMode: boolean): string {
    return isDarkMode ? 'rgba(255,59,48,0.15)' : 'rgba(255,59,48,0.05)';
  }

  // ==================== 间距规范 ====================

  /**
   * 获取间距值
   */
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

  // ==================== 圆角规范 ====================

  /**
   * 获取圆角值
   */
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

  // ==================== 字体规范 ====================

  /**
   * 获取字体大小
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

  // ==================== 阴影规范 ====================

  /**
   * 获取阴影配置
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

  // ==================== 动画规范 ====================

  /**
   * 获取标准动画配置
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
   * 获取按压态样式
   */
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
 * 页面样式 Mixin - 提供 tc/bg 快捷方法
 * 使用方法：
 * 1. 在页面中定义: @State isDarkMode: boolean = false;
 * 2. 在 aboutToAppear 中: this.isDarkMode = appTheme.isDarkMode();
 * 3. 继承该类或复制方法到组件中
 */
export class PageStyleMixin {
  isDarkMode: boolean = false;

  /**
   * 文字颜色快捷方法 (light: 浅色模式值, dark: 深色模式值)
   */
  tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 背景颜色快捷方法 (light: 浅色模式值, dark: 深色模式值)
   */
  bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 按压效果（添加到可点击元素）
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
