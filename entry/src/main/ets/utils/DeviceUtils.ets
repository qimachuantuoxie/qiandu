/**
 * 设备工具类 - 平板/手机适配
 * 
 * 用于检测设备类型（手机/平板）、屏幕尺寸、方向等
 * 提供响应式设计的适配值
 * 
 * @example
 * // 判断是否为平板
 * if (DeviceUtils.isTablet()) {
 *   // 平板布局
 * }
 * 
 * // 获取自适应列数
 * const columns = DeviceUtils.getGridColumns(); // 手机3列，平板5列
 * 
 * // 获取字体大小
 * const fontSize = DeviceUtils.getFontSize(14); // 自动适配
 */

import { display } from '@kit.ArkUI';

/**
 * 设备工具类
 * 提供屏幕尺寸检测、方向判断、自适应值计算等功能
 */
export class DeviceUtils {
  /** 是否为平板设备*/
  private static isPad: boolean = false;
  
  /** 屏幕宽度（像素） */
  private static screenWidth: number = 0;
  
  /** 屏幕高度（像素） */
  private static screenHeight: number = 0;
  
  /** 是否已初始化 */
  private static isInitialized: boolean = false;

  /**
   * 初始化设备信息
   * 获取屏幕尺寸并检测设备类型
   * 仅在首次调用时执行，后续直接返回
   * 
   * @remark
   * 平板判断标准：
   * - 屏幕尺寸 >= 7英寸
   * - 或宽度 >= 600dp 且 DPI < 280
   */
  public static async init(): Promise<void> {
    if (DeviceUtils.isInitialized) {
      return;
    }
    try {
      const displays: display.Display[] = await display.getAllDisplays();
      if (displays && displays.length > 0) {
        const displayObj: display.Display = displays[0];
        DeviceUtils.screenWidth = displayObj.width;
        DeviceUtils.screenHeight = displayObj.height;
        
        const dpi: number = displayObj.xDPI;
        const density: number = 160;
        
        const screenInches = Math.sqrt(
          Math.pow(DeviceUtils.screenWidth / density, 2) +
          Math.pow(DeviceUtils.screenHeight / density, 2)
        );
        
        DeviceUtils.isPad = screenInches >= 7.0 || (DeviceUtils.screenWidth >= 600 && dpi < 280);
      }
      DeviceUtils.isInitialized = true;
      console.info('[DeviceUtils] Screen:', DeviceUtils.screenWidth, 'x', DeviceUtils.screenHeight, 'isPad:', DeviceUtils.isPad);
    } catch {
      DeviceUtils.isPad = false;
      DeviceUtils.screenWidth = 360;
      DeviceUtils.screenHeight = 780;
      DeviceUtils.isInitialized = true;
    }
  }

  public static isTablet(): boolean {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return DeviceUtils.isPad;
  }

  public static isLandscape(): boolean {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return DeviceUtils.screenWidth > DeviceUtils.screenHeight;
  }

  public static getScreenWidth(): number {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return DeviceUtils.screenWidth;
  }

  public static getScreenHeight(): number {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return DeviceUtils.screenHeight;
  }

  public static getPadding(): number {
    return DeviceUtils.isTablet() ? 32 : 16;
  }

  public static getGridColumns(): number {
    return DeviceUtils.isTablet() ? 5 : 3;
  }

  public static getContentMaxWidth(): number {
    return DeviceUtils.isTablet() ? 800 : 0;
  }

  public static getFontSize(baseSize: number): number {
    return DeviceUtils.isTablet() ? baseSize * 1.2 : baseSize;
  }

  public static getIconSize(baseSize: number): number {
    return DeviceUtils.isTablet() ? baseSize * 1.3 : baseSize;
  }
}

export default DeviceUtils;