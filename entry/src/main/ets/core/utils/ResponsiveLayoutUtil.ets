import { logger } from '../../utils/Logger';
/**
 * 鍝嶅簲寮忓竷灞€宸ュ叿
 * 鎻愪緵閽堝�涓嶅悓灞忓箷灏哄�鐨勫竷灞€杈呭姪鍑芥暟
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
   * 鑾峰彇璁惧�绫诲瀷
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
   * 鑾峰彇甯冨眬閰嶇疆
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
        sidebarWidth = 0; // 鎵嬫満涓嶆樉绀轰晶杈规爮
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
   * 鑾峰彇褰撳墠灞忓箷瀹藉害
   */
  public async getScreenWidth(): Promise<number> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.width;
    } catch (error) {
      logger.error('Failed to get screen width:', error);
      return 360; // 榛樿�鍊?    }
  }

  /**
   * 鑾峰彇褰撳墠灞忓箷楂樺害
   */
  public async getScreenHeight(): Promise<number> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      return defaultDisplay.height;
    } catch (error) {
      logger.error('Failed to get screen height:', error);
      return 640; // 榛樿�鍊?    }
  }

  /**
   * 鍒ゆ柇鏄�惁涓烘í灞?   */
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
   * 鏍规嵁璁惧�绫诲瀷鑾峰彇鍚堥€傜殑缃戞牸鍒楁暟
   */
  public getGridColumns(screenWidth: number, isPortrait: boolean = true): number {
    const config = this.getLayoutConfig(screenWidth, 0, isPortrait);
    return config.gridColumns;
  }

  /**
   * 鏍规嵁璁惧�绫诲瀷鑾峰彇鍚堥€傜殑闂磋窛
   */
  public getSpacing(screenWidth: number): number {
    const config = this.getLayoutConfig(screenWidth, 0, true);
    return config.spacing;
  }

  /**
   * 鏍规嵁璁惧�绫诲瀷鑾峰彇鍚堥€傜殑澶撮儴楂樺害
   */
  public getHeaderHeight(screenWidth: number): number {
    const config = this.getLayoutConfig(screenWidth, 0, true);
    return config.headerHeight;
  }
}

export const responsiveLayoutUtil = ResponsiveLayoutUtil.getInstance();
