/**
 * 设备工具类 - 平板/手机/折叠屏适配
 * 
 * 用于检测设备类型（手机/平板/折叠屏）、屏幕尺寸、方向等
 * 提供响应式设计的适配值
 * 
 * @example
 * // 判断是否为平板
 * if (DeviceUtils.isTablet()) {
 *   // 平板布局
 * }
 * 
 * // 判断是否为折叠屏
 * if (DeviceUtils.isFoldable()) {
 *   // 折叠屏优化布局
 * }
 * 
 * // 获取自适应列数
 * const columns = DeviceUtils.getGridColumns(); // 手机3列，平板5列，折叠屏6列
 * 
 * // 获取字体大小
 * const fontSize = DeviceUtils.getFontSize(14); // 自动适配
 */

import { display } from '@kit.ArkUI';
import { displayHelper, FoldStatus } from './DisplayHelper';
import { foldableAdapter } from './FoldableAdapterManager';

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
   * 设备判断标准：
   * - 折叠屏：通过 DisplayHelper 检测
   * - 平板：屏幕尺寸 >= 7英寸 或 宽度 >= 600dp 且 DPI < 280
   * - 手机：其他情况
   */
  public static async init(): Promise<void> {
    if (DeviceUtils.isInitialized) {
      return;
    }
    try {
      // 初始化 DisplayHelper（包含折叠屏检测）
      await displayHelper.init();
      
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
        
        // 优先判断折叠屏
        const isFoldable = displayHelper.isFoldable();
        
        // 平板判断（排除折叠屏）
        DeviceUtils.isPad = !isFoldable && (
          screenInches >= 7.0 || 
          (DeviceUtils.screenWidth >= 600 && dpi < 280)
        );
      }
      DeviceUtils.isInitialized = true;
      console.info('[DeviceUtils] Screen:', DeviceUtils.screenWidth, 'x', DeviceUtils.screenHeight, 
                   'isPad:', DeviceUtils.isPad, 'isFoldable:', displayHelper.isFoldable());
    } catch (error) {
      const err = error instanceof Error ? error : new Error('Unknown error');
      console.error('[DeviceUtils] Init failed:', err.message);
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
    // 折叠屏根据状态调整
    if (displayHelper.isFoldable()) {
      return foldableAdapter.getSpacing();
    }
    return DeviceUtils.isTablet() ? 32 : 16;
  }

  public static getGridColumns(): number {
    // 折叠屏根据状态调整
    if (displayHelper.isFoldable()) {
      return foldableAdapter.getGridColumns();
    }
    return DeviceUtils.isTablet() ? 5 : 3;
  }

  public static getContentMaxWidth(): number {
    // 折叠屏展开状态支持更宽内容
    if (displayHelper.isFoldable() && displayHelper.isExpanded()) {
      return 1200;
    }
    return DeviceUtils.isTablet() ? 800 : 0;
  }

  public static getFontSize(baseSize: number): number {
    // 折叠屏根据状态调整
    if (displayHelper.isFoldable()) {
      return baseSize * foldableAdapter.getFontSizeMultiplier();
    }
    return DeviceUtils.isTablet() ? baseSize * 1.2 : baseSize;
  }

  public static getIconSize(baseSize: number): number {
    // 折叠屏展开状态使用更大图标
    if (displayHelper.isFoldable()) {
      const multiplier = displayHelper.isExpanded() ? 1.4 : 1.2;
      return baseSize * multiplier;
    }
    return DeviceUtils.isTablet() ? baseSize * 1.3 : baseSize;
  }

  /**
   * 判断是否为折叠屏设备
   */
  public static isFoldable(): boolean {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return displayHelper.isFoldable();
  }

  /**
   * 获取当前折叠状态
   */
  public static getFoldStatus(): FoldStatus {
    return displayHelper.getFoldStatus();
  }

  /**
   * 是否处于折叠状态
   */
  public static isFolded(): boolean {
    return displayHelper.isFolded();
  }

  /**
   * 是否处于半折叠状态
   */
  public static isHalfFolded(): boolean {
    return displayHelper.isHalfFolded();
  }

  /**
   * 是否处于展开状态
   */
  public static isExpanded(): boolean {
    return displayHelper.isExpanded();
  }

  /**
   * 判断是否应该使用平行视界（双栏布局）
   */
  public static shouldUseParallelView(): boolean {
    return foldableAdapter.shouldUseParallelView();
  }

  /**
   * 获取推荐的布局模式
   */
  public static getRecommendedLayout(): 'single' | 'dual' | 'triple' {
    return displayHelper.getRecommendedLayout();
  }
}

export default DeviceUtils;