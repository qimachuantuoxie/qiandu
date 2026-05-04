/**
 * 主题迁移助手 - Theme Migration Helper
 * 提供向后兼容的tc()/bg()方法，自动映射到ThemeTokens
 * 
 * 用途：
 * 1. 为旧代码提供兼容性支持，无需立即修改所有页面
 * 2. 渐进式迁移到ThemeTokens系统
 * 3. 减少代码重复，统一管理主题逻辑
 * 
 * @since 3.0.0
 */

import { ThemeTokens } from './ThemeTokens';

/**
 * 主题迁移助手类
 * 提供静态方法供所有页面使用
 */
export class ThemeMigrationHelper {
  /**
   * 根据主题返回颜色（兼容旧代码）
   * 自动映射到ThemeTokens的语义化令牌
   * 
   * @param light 浅色模式颜色
   * @param dark 深色模式颜色
   * @returns 当前主题对应的颜色
   * 
   * @example
   * // 旧代码
   * .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
   * 
   * // 推荐的新代码
   * .fontColor(ThemeTokens.textPrimary())
   */
  static tc(light: string, dark: string): string {
    // 尝试匹配常见的颜色组合，映射到语义化令牌
    const colorMap = this.getColorMapping(light, dark);
    if (colorMap) {
      return colorMap();
    }
    
    // 如果没有匹配，直接返回对应主题的颜色
    return ThemeMigrationHelper.isDarkMode() ? dark : light;
  }
  
  /**
   * 根据主题返回背景色（兼容旧代码）
   * 
   * @param light 浅色模式背景
   * @param dark 深色模式背景
   * @returns 当前主题对应的背景色
   */
  static bg(light: string, dark: string): string {
    // 尝试匹配常见的背景色组合
    const bgMap = this.getBackgroundMapping(light, dark);
    if (bgMap) {
      return bgMap();
    }
    
    // 如果没有匹配，直接返回对应主题的背景色
    return ThemeMigrationHelper.isDarkMode() ? dark : light;
  }
  
  /**
   * 判断是否为深色模式
   */
  static isDarkMode(): boolean {
    return ThemeTokens.textPrimary() === '#FFFFFF';
  }
  
  /**
   * 获取颜色映射（常见颜色组合 -> ThemeTokens）
   */
  private static getColorMapping(light: string, dark: string): (() => string) | null {
    // 主要文字颜色
    if (light === '#1A1A1A' && dark === '#FFFFFF') {
      return ThemeTokens.textPrimary;
    }
    
    // 次要文字颜色
    if (light === '#8E8E93' && dark === '#8E8E93') {
      return ThemeTokens.textSecondary;
    }
    
    // 辅助文字颜色
    if (light === '#C7C7CC' && dark === '#636366') {
      return ThemeTokens.textTertiary;
    }
    
    // 禁用文字颜色
    if (light === '#D1D1D6' && dark === '#48484A') {
      return ThemeTokens.textDisabled;
    }
    
    // 成功状态文字
    if (light === '#52C41A' && dark === '#52C41A') {
      return ThemeTokens.textSuccess;
    }
    
    // 警告状态文字
    if (light === '#FA8C16' && dark === '#FA8C16') {
      return ThemeTokens.textWarning;
    }
    
    // 错误状态文字
    if (light === '#FF4D4F' && dark === '#FF4D4F') {
      return ThemeTokens.textError;
    }
    
    // 没有匹配
    return null;
  }
  
  /**
   * 获取背景色映射（常见背景色组合 -> ThemeTokens）
   */
  private static getBackgroundMapping(light: string, dark: string): (() => string) | null {
    // 主要背景色（页面背景）
    if (light === '#F8F9FA' && dark === '#0F0F0F') {
      return ThemeTokens.bgPrimary;
    }
    
    // 次要背景色（卡片背景）
    if (light === '#FFFFFF' && dark === '#1E1E2E') {
      return ThemeTokens.bgSecondary;
    }
    
    // 第三背景色（分组背景）
    if (light === '#F2F2F7' && dark === '#2C2C2E') {
      return ThemeTokens.bgTertiary;
    }
    
    // 遮罩层背景
    if (light === 'rgba(0,0,0,0.5)' && dark === 'rgba(0,0,0,0.7)') {
      return ThemeTokens.bgOverlay;
    }
    
    // 悬停/按下状态背景
    if (light === 'rgba(0,0,0,0.03)' && dark === 'rgba(255,255,255,0.05)') {
      return ThemeTokens.bgHover;
    }
    
    // 边框颜色（作为背景使用时）
    if (light === 'rgba(0,0,0,0.06)' && dark === 'rgba(255,255,255,0.1)') {
      return ThemeTokens.borderLight;
    }
    
    if (light === 'rgba(0,0,0,0.12)' && dark === 'rgba(255,255,255,0.2)') {
      return ThemeTokens.borderMedium;
    }
    
    // 没有匹配
    return null;
  }
}

/**
 * 便捷导出，方便在组件中直接使用
 * 
 * 使用方式：
 * import { tc, bg } from './ThemeMigrationHelper';
 * 
 * .fontColor(tc('#1A1A1A', '#FFFFFF'))
 * .backgroundColor(bg('#F8F9FA', '#0F0F0F'))
 */
export const tc = ThemeMigrationHelper.tc;
export const bg = ThemeMigrationHelper.bg;

export default ThemeMigrationHelper;
