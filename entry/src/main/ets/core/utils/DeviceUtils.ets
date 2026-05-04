import { logger } from '../../utils/Logger';
/**
 * 璁惧�宸ュ叿绫?- 骞虫澘/鎵嬫満/鎶樺彔灞忛€傞厤
 * 
 * 鐢ㄤ簬妫€娴嬭�澶囩被鍨嬶紙鎵嬫満/骞虫澘/鎶樺彔灞忥級銆佸睆骞曞昂瀵搞€佹柟鍚戠瓑
 * 鎻愪緵鍝嶅簲寮忚�璁＄殑閫傞厤鍊?
 * 
 * @example
 * // 鍒ゆ柇鏄�惁涓哄钩鏉?
 * if (DeviceUtils.isTablet()) {
 *   // 骞虫澘甯冨眬
 * }
 * 
 * // 鍒ゆ柇鏄�惁涓烘姌鍙犲睆
 * if (DeviceUtils.isFoldable()) {
 *   // 鎶樺彔灞忎紭鍖栧竷灞€
 * }
 * 
 * // 鑾峰彇鑷�€傚簲鍒楁暟
 * const columns = DeviceUtils.getGridColumns(); // 鎵嬫満3鍒楋紝骞虫澘5鍒楋紝鎶樺彔灞?鍒?
 * 
 * // 鑾峰彇瀛椾綋澶у皬
 * const fontSize = DeviceUtils.getFontSize(14); // 鑷�姩閫傞厤
 */

import { display } from '@kit.ArkUI';
import { displayHelper, FoldStatus } from './DisplayHelper';
import { foldableAdapter } from './FoldableAdapterManager';

/**
 * 璁惧�宸ュ叿绫?
 * 鎻愪緵灞忓箷灏哄�妫€娴嬨€佹柟鍚戝垽鏂�€佽嚜閫傚簲鍊艰�绠楃瓑鍔熻兘
 */
export class DeviceUtils {
  /** 鏄�惁涓哄钩鏉胯�澶?/
  private static isPad: boolean = false;
  
  /** 灞忓箷瀹藉害锛堝儚绱狅級 */
  private static screenWidth: number = 0;
  
  /** 灞忓箷楂樺害锛堝儚绱狅級 */
  private static screenHeight: number = 0;
  
  /** 鏄�惁宸插垵濮嬪寲 */
  private static isInitialized: boolean = false;

  /**
   * 鍒濆�鍖栬�澶囦俊鎭?
   * 鑾峰彇灞忓箷灏哄�骞舵�娴嬭�澶囩被鍨?
   * 浠呭湪棣栨�璋冪敤鏃舵墽琛岋紝鍚庣画鐩存帴杩斿洖
   * 
   * @remark
   * 璁惧�鍒ゆ柇鏍囧噯锛?
   * - 鎶樺彔灞忥細閫氳繃 DisplayHelper 妫€娴?
   * - 骞虫澘锛氬睆骞曞昂瀵?>= 7鑻卞� 鎴?瀹藉害 >= 600dp 涓?DPI < 280
   * - 鎵嬫満锛氬叾浠栨儏鍐?
   */
  public static async init(): Promise<void> {
    if (DeviceUtils.isInitialized) {
      return;
    }
    try {
      // 鍒濆�鍖?DisplayHelper锛堝寘鍚�姌鍙犲睆妫€娴嬶級
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
        
        // 浼樺厛鍒ゆ柇鎶樺彔灞?
        const isFoldable = displayHelper.isFoldable();
        
        // 骞虫澘鍒ゆ柇锛堟帓闄ゆ姌鍙犲睆锛?
        DeviceUtils.isPad = !isFoldable && (
          screenInches >= 7.0 || 
          (DeviceUtils.screenWidth >= 600 && dpi < 280)
        );
      }
      DeviceUtils.isInitialized = true;
      logger.info('[DeviceUtils] Screen:', DeviceUtils.screenWidth, 'x', DeviceUtils.screenHeight, 
                   'isPad:', DeviceUtils.isPad, 'isFoldable:', displayHelper.isFoldable());
    } catch (error) {
      const err = error instanceof Error ? error : new Error('Unknown error');
      logger.error('[DeviceUtils] Init failed:', err.message);
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
    // 鎶樺彔灞忔牴鎹�姸鎬佽皟鏁?
    if (displayHelper.isFoldable()) {
      return foldableAdapter.getSpacing();
    }
    return DeviceUtils.isTablet() ? 32 : 16;
  }

  public static getGridColumns(): number {
    // 鎶樺彔灞忔牴鎹�姸鎬佽皟鏁?
    if (displayHelper.isFoldable()) {
      return foldableAdapter.getGridColumns();
    }
    return DeviceUtils.isTablet() ? 5 : 3;
  }

  public static getContentMaxWidth(): number {
    // 鎶樺彔灞忓睍寮€鐘舵€佹敮鎸佹洿瀹藉唴瀹?
    if (displayHelper.isFoldable() && displayHelper.isExpanded()) {
      return 1200;
    }
    return DeviceUtils.isTablet() ? 800 : 0;
  }

  public static getFontSize(baseSize: number): number {
    // 鎶樺彔灞忔牴鎹�姸鎬佽皟鏁?
    if (displayHelper.isFoldable()) {
      return baseSize * foldableAdapter.getFontSizeMultiplier();
    }
    return DeviceUtils.isTablet() ? baseSize * 1.2 : baseSize;
  }

  public static getIconSize(baseSize: number): number {
    // 鎶樺彔灞忓睍寮€鐘舵€佷娇鐢ㄦ洿澶у浘鏍?
    if (displayHelper.isFoldable()) {
      const multiplier = displayHelper.isExpanded() ? 1.4 : 1.2;
      return baseSize * multiplier;
    }
    return DeviceUtils.isTablet() ? baseSize * 1.3 : baseSize;
  }

  /**
   * 鍒ゆ柇鏄�惁涓烘姌鍙犲睆璁惧�
   */
  public static isFoldable(): boolean {
    if (!DeviceUtils.isInitialized) {
      DeviceUtils.init();
    }
    return displayHelper.isFoldable();
  }

  /**
   * 鑾峰彇褰撳墠鎶樺彔鐘舵€?
   */
  public static getFoldStatus(): FoldStatus {
    return displayHelper.getFoldStatus();
  }

  /**
   * 鏄�惁澶勪簬鎶樺彔鐘舵€?
   */
  public static isFolded(): boolean {
    return displayHelper.isFolded();
  }

  /**
   * 鏄�惁澶勪簬鍗婃姌鍙犵姸鎬?
   */
  public static isHalfFolded(): boolean {
    return displayHelper.isHalfFolded();
  }

  /**
   * 鏄�惁澶勪簬灞曞紑鐘舵€?
   */
  public static isExpanded(): boolean {
    return displayHelper.isExpanded();
  }

  /**
   * 鍒ゆ柇鏄�惁搴旇�浣跨敤骞宠�瑙嗙晫锛堝弻鏍忓竷灞€锛?
   */
  public static shouldUseParallelView(): boolean {
    return foldableAdapter.shouldUseParallelView();
  }

  /**
   * 鑾峰彇鎺ㄨ崘鐨勫竷灞€妯″紡
   */
  public static getRecommendedLayout(): 'single' | 'dual' | 'triple' {
    return displayHelper.getRecommendedLayout();
  }
}

export default DeviceUtils;