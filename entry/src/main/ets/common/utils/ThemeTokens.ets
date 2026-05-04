/**
 * 主题令牌系统 - Theme Tokens
 * 统一管理应用的颜色、阴影、圆角等设计变量
 * 支持深色/浅色模式自动切换
 * 
 * @since 3.0.0
 */

import { themeManager } from './AppTheme';
import { ShadowOptions } from '@kit.ArkUI';

/**
 * 主题令牌定义
 * 使用语义化命名，不直接暴露颜色值
 * 所有方法都是响应式的，会根据主题变化自动更新
 */
export const ThemeTokens = {
  // ==================== 文字颜色 ====================
  
  /** 主要文字颜色 */
  textPrimary: (): string => themeManager.isDarkMode() ? '#FFFFFF' : '#1A1A1A',
  
  /** 次要文字颜色 */
  textSecondary: (): string => themeManager.isDarkMode() ? '#8E8E93' : '#8E8E93',
  
  /** 辅助文字颜色 */
  textTertiary: (): string => themeManager.isDarkMode() ? '#636366' : '#C7C7CC',
  
  /** 禁用文字颜色 */
  textDisabled: (): string => themeManager.isDarkMode() ? '#48484A' : '#D1D1D6',
  
  /** 链接/强调文字颜色 */
  textLink: (): string => themeManager.getColors().primary,
  
  /** 成功状态文字 */
  textSuccess: (): string => '#52C41A',
  
  /** 警告状态文字 */
  textWarning: (): string => '#FA8C16',
  
  /** 错误状态文字 */
  textError: (): string => '#FF4D4F',
  
  // ==================== 背景颜色 ====================
  
  /** 主要背景色（页面背景） */
  bgPrimary: (): string => themeManager.isDarkMode() ? '#0F0F0F' : '#F8F9FA',
  
  /** 次要背景色（卡片背景） */
  bgSecondary: (): string => themeManager.isDarkMode() ? '#1A1A1A' : '#FFFFFF',
  
  /** 第三背景色（分组背景） */
  bgTertiary: (): string => themeManager.isDarkMode() ? '#2C2C2E' : '#F2F2F7',
  
  /** 悬停/按下状态背景 */
  bgHover: (): string => themeManager.isDarkMode() ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)',
  
  /** 选中状态背景 */
  bgSelected: (): string => themeManager.getColors().primary + '15',
  
  /** 成功状态背景 */
  bgSuccess: (): string => themeManager.isDarkMode() ? 'rgba(82,196,26,0.15)' : 'rgba(82,196,26,0.05)',
  
  /** 警告状态背景 */
  bgWarning: (): string => themeManager.isDarkMode() ? 'rgba(250,140,22,0.15)' : 'rgba(250,140,22,0.05)',
  
  /** 错误状态背景 */
  bgError: (): string => themeManager.isDarkMode() ? 'rgba(255,77,79,0.15)' : 'rgba(255,77,79,0.05)',
  
  /** 遮罩层背景 */
  bgOverlay: (): string => themeManager.isDarkMode() ? 'rgba(0,0,0,0.7)' : 'rgba(0,0,0,0.5)',
  
  // ==================== 边框颜色 ====================
  
  /** 浅色边框 */
  borderLight: (): string => themeManager.isDarkMode() ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)',
  
  /** 中等边框 */
  borderMedium: (): string => themeManager.isDarkMode() ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.12)',
  
  /** 深色边框 */
  borderDark: (): string => themeManager.isDarkMode() ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.18)',
  
  /** 主色边框 */
  borderPrimary: (): string => themeManager.getColors().primary,
  
  // ==================== 阴影配置 ====================
  
  /** 小阴影（导航栏、小组件） */
  shadowSm: (): ShadowOptions => themeManager.isDarkMode() 
    ? { radius: 4, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 2 }
    : { radius: 4, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 },
  
  /** 中阴影（普通卡片） */
  shadowMd: (): ShadowOptions => themeManager.isDarkMode()
    ? { radius: 8, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 4 }
    : { radius: 8, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 4 },
  
  /** 大阴影（突出卡片） */
  shadowLg: (): ShadowOptions => themeManager.isDarkMode()
    ? { radius: 12, color: 'rgba(0,0,0,0.5)', offsetX: 0, offsetY: 6 }
    : { radius: 12, color: 'rgba(0,0,0,0.16)', offsetX: 0, offsetY: 6 },
  
  /** 超大阴影（悬浮元素） */
  shadowXl: (): ShadowOptions => themeManager.isDarkMode()
    ? { radius: 16, color: 'rgba(0,0,0,0.6)', offsetX: 0, offsetY: 8 }
    : { radius: 16, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 8 },
  
  /** 彩色阴影（主色） */
  shadowColored: (opacity: number = 0.3): ShadowOptions => ({
    radius: 8,
    color: themeManager.getColors().primary + Math.floor(opacity * 255).toString(16).padStart(2, '0'),
    offsetX: 0,
    offsetY: 4
  }),
  
  // ==================== 渐变色 ====================
  
  /** 主色渐变（从左到右） */
  gradientPrimary: (): Array<[string, number]> => {
    const primary = themeManager.getColors().primary;
    return [[primary, 0], [primary + 'CC', 1]];
  },
  
  /** 金色渐变（奖励/积分） */
  gradientGold: (): Array<[string, number]> => 
    themeManager.isDarkMode()
      ? [['rgba(255,215,0,0.15)', 0], ['rgba(255,165,0,0.08)', 1]]
      : [['rgba(255,215,0,0.2)', 0], ['rgba(255,165,0,0.1)', 1]],
  
  /** 透明渐变（从上到下） */
  gradientTransparentTop: (): Array<[string, number]> => 
    themeManager.isDarkMode()
      ? [['rgba(0,0,0,0.7)', 0], ['rgba(0,0,0,0)', 1]]
      : [['rgba(0,0,0,0.5)', 0], ['rgba(0,0,0,0)', 1]],
  
  /** 透明渐变（从下到上） */
  gradientTransparentBottom: (): Array<[string, number]> => 
    themeManager.isDarkMode()
      ? [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.7)', 1]]
      : [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.5)', 1]],
  
  // ==================== 透明度变体 ====================
  
  /** 主色透明度变体 */
  primaryWithOpacity: (opacity: number): string => {
    const hex = Math.floor(opacity * 255).toString(16).padStart(2, '0');
    return themeManager.getColors().primary + hex;
  },
  
  /** 白色透明度变体 */
  whiteWithOpacity: (opacity: number): string => {
    const hex = Math.floor(opacity * 255).toString(16).padStart(2, '0');
    return `#FFFFFF${hex}`;
  },
  
  /** 黑色透明度变体 */
  blackWithOpacity: (opacity: number): string => {
    const hex = Math.floor(opacity * 255).toString(16).padStart(2, '0');
    return `#000000${hex}`;
  },
};

/**
 * 主题助手类
 * 提供便捷的主题相关方法
 */
export class ThemeHelper {
  /**
   * 根据主题返回颜色（兼容旧代码）
   * @param light 浅色模式颜色
   * @param dark 深色模式颜色
   * @returns 当前主题对应的颜色
   */
  static tc(light: string, dark: string): string {
    return themeManager.isDarkMode() ? dark : light;
  }
  
  /**
   * 根据主题返回背景色（兼容旧代码）
   * @param light 浅色模式背景
   * @param dark 深色模式背景
   * @returns 当前主题对应的背景色
   */
  static bg(light: string, dark: string): string {
    return themeManager.isDarkMode() ? dark : light;
  }
  
  /**
   * 获取当前主题的颜色对象
   */
  static getCurrentColors() {
    return themeManager.getColors();
  }
  
  /**
   * 判断是否为深色模式
   */
  static isDarkMode(): boolean {
    return themeManager.isDarkMode();
  }
  
  /**
   * 根据主题返回阴影配置（兼容旧代码）
   */
  static getShadow(level: 'sm' | 'md' | 'lg' | 'xl', isDark: boolean): ShadowOptions {
    switch (level) {
      case 'sm':
        return isDark ? ThemeTokens.shadowSm() : ThemeTokens.shadowSm();
      case 'md':
        return isDark ? ThemeTokens.shadowMd() : ThemeTokens.shadowMd();
      case 'lg':
        return isDark ? ThemeTokens.shadowLg() : ThemeTokens.shadowLg();
      case 'xl':
        return isDark ? ThemeTokens.shadowXl() : ThemeTokens.shadowXl();
      default:
        return ThemeTokens.shadowMd();
    }
  }
}

// 导出默认实例，方便使用
export default ThemeTokens;
