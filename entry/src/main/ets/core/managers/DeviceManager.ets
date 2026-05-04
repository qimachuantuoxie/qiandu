import { logger } from '../../utils/Logger';
/**
 * 璁惧�宸ュ叿绫?- 骞虫澘/鎵嬫満閫傞厤
 *
 * 鐢ㄤ簬妫€娴嬭�澶囩被鍨嬶紙鎵嬫満/骞虫澘锛夈€佸睆骞曞昂瀵搞€佹柟鍚戠瓑
 * 鎻愪緵鍝嶅簲寮忚�璁＄殑閫傞厤鍊?
 *
 * @example
 * // 鍒ゆ柇鏄�惁涓哄钩鏉?
 * if (DeviceUtils.isTablet()) {
 *   // 骞虫澘甯冨眬
 * }
 *
 * // 鑾峰彇鑷�€傚簲鍒楁暟
 * const columns = DeviceUtils.getGridColumns(); // 鎵嬫満3鍒楋紝骞虫澘5鍒?
 *
 * // 鑾峰彇瀛椾綋澶у皬
 * const fontSize = DeviceUtils.getFontSize(14); // 鑷�姩閫傞厤
 */

import { displayHelper } from '../utils/DisplayHelper';

/**
 * 璁惧�宸ュ叿绫?
 * 鎻愪緵灞忓箷灏哄�妫€娴嬨€佹柟鍚戝垽鏂�€佽嚜閫傚簲鍊艰�绠楃瓑鍔熻兘
 */
export class DeviceUtils {
  /** 鏄�惁涓哄钩鏉胯�澶?*/
  private static isPad: boolean = false;

  /** 灞忓箷瀹藉害锛堝儚绱狅級 */
  private static screenWidth: number = 0;

  /** 灞忓箷楂樺害锛堝儚绱狅級 */
  private static screenHeight: number = 0;

  /** 鏄�惁宸插垵濮嬪寲 */
  private static isInitialized: boolean = false;

  /**
   * 鍒濆�鍖栬�澶囦俊鎭?
   * 鑾峰彇灞忓箷灏哄�骞跺垽鏂��澶囩被鍨?
   * 浠呭湪棣栨�璋冪敤鏃舵墽琛岋紝鍚庣画鐩存帴杩斿洖
   *
   * @remark
   * 骞虫澘鍒ゆ柇鏍囧噯锛?
   * - 灞忓箷灏哄� >= 7鑻卞�
   * - 鎴栬€?瀹藉害 >= 600dp 涓?DPI < 280
   */
  public static async init(): Promise<void> {
    if (DeviceUtils.isInitialized) {
      return;
    }
    try {
      // 鍒濆�鍖?DisplayHelper
      await displayHelper.init();
      
      DeviceUtils.screenWidth = displayHelper.getWidth();
      DeviceUtils.screenHeight = displayHelper.getHeight();

      const dpi = displayHelper.getDPI();
      const density = dpi > 0 ? dpi : 320; // 榛樿�瀵嗗害

      const screenInches = Math.sqrt(
        Math.pow(DeviceUtils.screenWidth / density * 160, 2) +
        Math.pow(DeviceUtils.screenHeight / density * 160, 2)
      ) / 160;

      DeviceUtils.isPad = screenInches >= 7.0 || (DeviceUtils.screenWidth >= 600 && dpi < 280);
      DeviceUtils.isInitialized = true;

      logger.info('[DeviceUtils] Screen:', DeviceUtils.screenWidth, 'x', DeviceUtils.screenHeight, 'dpi:', dpi, 'isPad:', DeviceUtils.isPad);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      logger.error('[DeviceUtils] Init failed:', message);
      DeviceUtils.isPad = false;
      DeviceUtils.screenWidth = 360;
      DeviceUtils.screenHeight = 780;
      DeviceUtils.isInitialized = true;
    }
  }

  public static isTablet(): boolean {
    if (!DeviceUtils.isInitialized) {
      logger.warn('[DeviceUtils] Not initialized, using default');
      return false;
    }
    return DeviceUtils.isPad;
  }

  public static isLandscape(): boolean {
    if (!DeviceUtils.isInitialized) {
      return false;
    }
    return DeviceUtils.screenWidth > DeviceUtils.screenHeight;
  }

  public static getScreenWidth(): number {
    if (!DeviceUtils.isInitialized) {
      return 360;
    }
    return DeviceUtils.screenWidth;
  }

  public static getScreenHeight(): number {
    if (!DeviceUtils.isInitialized) {
      return 780;
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
