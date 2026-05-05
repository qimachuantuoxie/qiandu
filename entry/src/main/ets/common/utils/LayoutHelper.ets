/**
 * 布局辅助工具类
 * 提供屏幕检测、响应式值计算、字体缩放等实用功能
 * 
 * @since 7.0.0
 */

import { Breakpoints, Spacing, Size } from '../constants/LayoutConstants';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { logger } from '../../core/utils/Logger';

export interface ScreenInfo {
  width: number;
  height: number;
  density: number;
  isPhone: boolean;
  isTablet: boolean;
  isFoldable: boolean;
  breakpoint: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl';
}

class LayoutHelper {
  private screenInfo: ScreenInfo | null = null;
  private context: common.Context | null = null;

  /**
   * 初始化屏幕信息
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.updateScreenInfo();
  }

  /**
   * 更新屏幕信息
   */
  async updateScreenInfo(): Promise<void> {
    if (!this.context) return;

    try {
      const win = await window.getLastWindow(this.context);
      const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const rect = avoidArea.windowRect;
      
      const width = rect.width;
      const height = rect.height;
      const density = win.getWindowProperties().density;

      this.screenInfo = {
        width,
        height,
        density,
        isPhone: width < Breakpoints.md,
        isTablet: width >= Breakpoints.md && width < Breakpoints.xl,
        isFoldable: width >= Breakpoints.md && width < Breakpoints.lg,
        breakpoint: this.getBreakpoint(width)
      };
    } catch (error) {
      logger.error('Failed to update screen info:', error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 获取当前断点
   */
  private getBreakpoint(width: number): 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl' {
    if (width < Breakpoints.sm) return 'xs';
    if (width < Breakpoints.md) return 'sm';
    if (width < Breakpoints.lg) return 'md';
    if (width < Breakpoints.xl) return 'lg';
    if (width < Breakpoints.xxl) return 'xl';
    return 'xxl';
  }

  /**
   * 获取屏幕信息
   */
  getScreenInfo(): ScreenInfo | null {
    return this.screenInfo;
  }

  /**
   * 根据断点获取响应式值
   * @param values 不同断点对应的值
   * @returns 当前断点对应的值
   */
  getResponsiveValue<T>(values: { xs?: T; sm?: T; md?: T; lg?: T; xl?: T; xxl?: T }): T | undefined {
    if (!this.screenInfo) return undefined;

    const breakpoint = this.screenInfo.breakpoint;
    switch (breakpoint) {
      case 'xs':
        return values.xs ?? values.sm ?? values.md;
      case 'sm':
        return values.sm ?? values.md;
      case 'md':
        return values.md ?? values.lg;
      case 'lg':
        return values.lg ?? values.xl;
      case 'xl':
        return values.xl ?? values.xxl;
      case 'xxl':
        return values.xxl ?? values.xl;
      default:
        return values.md;
    }
  }

  /**
   * 获取响应式间距
   */
  getResponsiveSpacing(): number {
    return this.getResponsiveValue({
      xs: Spacing.xs,
      sm: Spacing.sm,
      md: Spacing.md,
      lg: Spacing.lg,
      xl: Spacing.xl,
      xxl: Spacing.xxl
    }) || Spacing.md;
  }

  /**
   * 获取响应式网格列数
   */
  getResponsiveColumns(): number {
    if (!this.screenInfo) return 2;

    const width = this.screenInfo.width;
    if (width < Breakpoints.md) return 2;
    if (width < Breakpoints.lg) return 3;
    if (width < Breakpoints.xl) return 4;
    return 5;
  }

  /**
   * 获取响应式字体大小
   * @param baseSize 基础字体大小
   * @returns 响应式字体大小
   */
  getResponsiveFontSize(baseSize: number): number {
    if (!this.screenInfo) return baseSize;

    const scale = this.getResponsiveValue({
      xs: 0.85,
      sm: 0.9,
      md: 1.0,
      lg: 1.1,
      xl: 1.15,
      xxl: 1.2
    }) || 1.0;

    return Math.round(baseSize * scale);
  }

  /**
   * 获取响应式卡片宽度
   * @param columns 列数
   * @param gutter 间距
   * @returns 卡片宽度
   */
  getCardWidth(columns: number = 2, gutter: number = Spacing.md): number {
    if (!this.screenInfo) return 150;

    const availableWidth = this.screenInfo.width - (gutter * (columns + 1));
    return Math.floor(availableWidth / columns);
  }

  /**
   * 判断是否为横屏
   */
  isLandscape(): boolean {
    if (!this.screenInfo) return false;
    return this.screenInfo.width > this.screenInfo.height;
  }

  /**
   * 获取安全的顶部间距（避开状态栏）
   */
  getSafeTopPadding(): number {
    if (!this.screenInfo) return Spacing.lg;
    
    // 平板和桌面端需要更大的顶部间距
    if (this.screenInfo.isTablet || this.screenInfo.breakpoint === 'xl' || this.screenInfo.breakpoint === 'xxl') {
      return Spacing.xl;
    }
    return Spacing.lg;
  }

  /**
   * 获取安全的底部间距（避开导航栏）
   */
  getSafeBottomPadding(): number {
    if (!this.screenInfo) return Spacing.lg;
    
    // 平板和桌面端需要更大的底部间距
    if (this.screenInfo.isTablet || this.screenInfo.breakpoint === 'xl' || this.screenInfo.breakpoint === 'xxl') {
      return Spacing.xl;
    }
    return Spacing.lg;
  }

  /**
   * 计算合适的列表项高度
   * @param baseHeight 基础高度
   * @returns 响应式列表项高度
   */
  getListItemHeight(baseHeight: number = 60): number {
    if (!this.screenInfo) return baseHeight;

    const scale = this.getResponsiveValue({
      xs: 0.9,
      sm: 0.95,
      md: 1.0,
      lg: 1.05,
      xl: 1.1,
      xxl: 1.15
    }) || 1.0;

    return Math.round(baseHeight * scale);
  }

  /**
   * 获取响应式图片尺寸
   * @param baseSize 基础尺寸
   * @returns 响应式图片尺寸
   */
  getImageSize(baseSize: number): number {
    return this.getResponsiveFontSize(baseSize);
  }

  /**
   * 获取适合当前屏幕的布局模式
   * @returns 布局模式：single（单栏）、split（分栏）、grid（网格）
   */
  getLayoutMode(): 'single' | 'split' | 'grid' {
    if (!this.screenInfo) return 'single';

    if (this.screenInfo.isPhone) return 'single';
    if (this.screenInfo.isFoldable) return 'split';
    if (this.isLandscape()) return 'split';
    return 'grid';
  }
}

// 导出单例
export const layoutHelper = new LayoutHelper();
