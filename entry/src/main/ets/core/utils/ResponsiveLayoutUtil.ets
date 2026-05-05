import { logger } from '../../utils/Logger';
/**
 * 响应式布局工具
 * 提供针对不同屏幕尺寸的布局辅助函数
 */

import { display } from '@kit.ArkUI';

export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  FOLDABLE = 'foldable',
  DESKTOP = 'desktop'
}

export interface LayoutConfig {
  deviceType: DeviceType;
  screenWidth: number;
  screenHeight: number;
  isPortrait: boolean;
  gridColumns: number;
  spacing: number;
  headerHeight: number;
  sidebarWidth: number;
}

class ResponsiveLayoutUtil {
  private static instance: ResponsiveLayoutUtil;
  
  public static getInstance(): ResponsiveLayoutUtil {
    if (!ResponsiveLayoutUtil.instance) {
      ResponsiveLayoutUtil.instance = new ResponsiveLayoutUtil();
    }
    return ResponsiveLayoutUtil.instance;
  }

  /**
   * 获取设备类型
   */
  public getDeviceType(screenWidth: number): DeviceType {
    if (screenWidth < 600) {
      return DeviceType.PHONE;
    } else if (screenWidth < 840) {
      return DeviceType.FOLDABLE;
    } else if (screenWidth < 1200) {
      return DeviceType.TABLET;
    } else {
      return DeviceType.DESKTOP;
    }
  }

  /**
   * 获取布局配置
   */
  public getLayoutConfig(screenWidth: number, screenHeight: number, isPortrait: boolean): LayoutConfig {
    const deviceType = this.getDeviceType(screenWidth);
    
    let gridColumns: number;
    let spacing: number;
    let headerHeight: number;
    let sidebarWidth: number;

    switch (deviceType) {
      case DeviceType.PHONE:
        gridColumns = 2;
        spacing = 12;
        headerHeight = 56;
        sidebarWidth = 0; // 手机不显示侧边栏
        break;
      case DeviceType.FOLDABLE:
        gridColumns = isPortrait ? 2 : 3;
        spacing = 16;
        headerHeight = 56;
        sidebarWidth = isPortrait ? 0 : 240;
        break;
      case DeviceType.TABLET:
        gridColumns = isPortrait ? 3 : 4;
        spacing = 20;
        headerHeight = 64;
        sidebarWidth = 280;
        break;
      case DeviceType.DESKTOP:
        gridColumns = 4;
        spacing = 24;
        headerHeight = 64;
        sidebarWidth = 320;
        break;
    }

    return {
      deviceType,
      screenWidth,
      screenHeight,
      isPortrait,
      gridColumns,
      spacing,
      headerHeight,
      sidebarWidth
    };
  }

  /**
   * 获取当前屏幕宽度
   */
  public async getScreenWidth(): Promise<number> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.width;
    } catch (error) {
      logger.error('Failed to get screen width:', error);
      return 360; // 默认值
    }
  }

  /**
   * 获取当前屏幕高度
   */
  public async getScreenHeight(): Promise<number> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.height;
    } catch (error) {
      logger.error('Failed to get screen height:', error);
      return 640; // 默认值
    }
  }

  /**
   * 判断是否为横屏
   */
  public async isLandscape(): Promise<boolean> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.width > defaultDisplay.height;
    } catch (error) {
      logger.error('Failed to check orientation:', error);
      return false;
    }
  }

  /**
   * 根据设备类型获取合适的网格列数
   */
  public getGridColumns(screenWidth: number, isPortrait: boolean = true): number {
    const config = this.getLayoutConfig(screenWidth, 0, isPortrait);
    return config.gridColumns;
  }

  /**
   * 根据设备类型获取合适的间距
   */
  public getSpacing(screenWidth: number): number {
    const config = this.getLayoutConfig(screenWidth, 0, true);
    return config.spacing;
  }

  /**
   * 根据设备类型获取合适的头部高度
   */
  public getHeaderHeight(screenWidth: number): number {
    const config = this.getLayoutConfig(screenWidth, 0, true);
    return config.headerHeight;
  }
}

export const responsiveLayoutUtil = ResponsiveLayoutUtil.getInstance();
