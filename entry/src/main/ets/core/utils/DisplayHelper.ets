import { logger } from '../../utils/Logger';
/**
 * Display Helper for API 22+
 * Enhanced with foldable screen detection and multi-window support
 */
import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 鎶樺彔鐘舵€佹灇涓? */
export enum FoldStatus {
  UNKNOWN = 'unknown',
  FOLDED = 'folded',           // 鎶樺彔鐘舵€?  HALF_FOLDED = 'half_folded', // 鍗婃姌鍙犵姸鎬?  EXPANDED = 'expanded'        // 灞曞紑鐘舵€?}

/**
 * 灞忓箷绫诲瀷鏋氫妇
 */
export enum ScreenType {
  PHONE = 'phone',
  TABLET = 'tablet',
  FOLDABLE = 'foldable',
  CAR = 'car',
  TV = 'tv'
}

export class DisplayHelper {
  private static instance: DisplayHelper | null = null;
  private currentDisplay: display.Display | null = null;
  private isFoldableDevice: boolean = false;
  private currentFoldStatus: FoldStatus = FoldStatus.UNKNOWN;
  private displayListener: ((id: number) => void) | null = null;
  private windowSizeListener: ((size: window.Size) => void) | null = null;

  static getInstance(): DisplayHelper {
    if (!DisplayHelper.instance) {
      DisplayHelper.instance = new DisplayHelper();
    }
    return DisplayHelper.instance;
  }

  async init(): Promise<void> {
    try {
      const displays: display.Display[] = await display.getAllDisplays();
      if (displays && displays.length > 0) {
        this.currentDisplay = displays[0];
        
        // 妫€娴嬫槸鍚︿负鎶樺彔灞忚�澶?        this.detectFoldableDevice();
        
        // 娉ㄥ唽鏄剧ず鍙樺寲鐩戝惉鍣?        this.registerDisplayListener();
      }
    } catch (e) {
      const err = e as BusinessError;
      logger.error('[DisplayHelper] Init failed:', err.message);
    }
  }

  /**
   * 妫€娴嬫槸鍚︿负鎶樺彔灞忚�澶?   */
  private detectFoldableDevice(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      // 妫€鏌ユ槸鍚︽湁鎶樺彔鐘舵€佸睘鎬э紙API 21+锛?      const displayInfo = this.currentDisplay;
      
      // 閫氳繃灞忓箷灏哄�鍜屾瘮渚嬪垽鏂�槸鍚︿负鎶樺彔灞?      const widthVp = displayInfo.width / displayInfo.densityPixels;
      const heightVp = displayInfo.height / displayInfo.densityPixels;
      const aspectRatio = Math.max(widthVp, heightVp) / Math.min(widthVp, heightVp);
      
      // 鎶樺彔灞忕壒寰侊細灞曞紑鍚庢帴杩戞�鏂瑰舰鎴栬秴瀹藉睆
      this.isFoldableDevice = (
        aspectRatio < 1.5 ||  // 鎺ヨ繎骞虫柟
        widthVp > 1000        // 瓒呭�灞?      );
      
      logger.info('[DisplayHelper] Foldable device detected:', this.isFoldableDevice);
    } catch (e) {
      const err = e as BusinessError;
      logger.warn('[DisplayHelper] Detect foldable failed:', err.message);
      this.isFoldableDevice = false;
    }
  }

  /**
   * 娉ㄥ唽鏄剧ず鍙樺寲鐩戝惉鍣?   */
  private registerDisplayListener(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      // 鐩戝惉鏄剧ず鍙樺寲锛堝寘鎷�姌鍙?灞曞紑锛?      this.displayListener = (id: number) => {
        logger.info('[DisplayHelper] Display changed:', id);
        this.updateFoldStatus();
      };
      
      display.on('change', this.displayListener);
      
      // 鍒濆�鍖栨姌鍙犵姸鎬?      this.updateFoldStatus();
      
      logger.info('[DisplayHelper] Display listener registered');
    } catch (e) {
      const err = e as BusinessError;
      logger.warn('[DisplayHelper] Register listener failed:', err.message);
    }
  }

  /**
   * 鏇存柊鎶樺彔鐘舵€?   */
  private updateFoldStatus(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      const widthVp = this.currentDisplay.width / this.currentDisplay.densityPixels;
      const heightVp = this.currentDisplay.height / this.currentDisplay.densityPixels;
      
      // 鏍规嵁灞忓箷灏哄�鍒ゆ柇鎶樺彔鐘舵€?      if (widthVp < 600) {
        this.currentFoldStatus = FoldStatus.FOLDED;
      } else if (widthVp >= 600 && widthVp < 840) {
        this.currentFoldStatus = FoldStatus.HALF_FOLDED;
      } else {
        this.currentFoldStatus = FoldStatus.EXPANDED;
      }
      
      logger.info('[DisplayHelper] Fold status updated:', this.currentFoldStatus);
    } catch (e) {
      const err = e as BusinessError;
      logger.warn('[DisplayHelper] Update fold status failed:', err.message);
    }
  }

  /**
   * 娓呯悊璧勬簮
   */
  cleanup(): void {
    try {
      if (this.displayListener) {
        display.off('change', this.displayListener);
        this.displayListener = null;
      }
      
      if (this.windowSizeListener) {
        // 绉婚櫎绐楀彛澶у皬鐩戝惉鍣?        this.windowSizeListener = null;
      }
      
      logger.info('[DisplayHelper] Cleanup completed');
    } catch (e) {
      const err = e as BusinessError;
      logger.warn('[DisplayHelper] Cleanup failed:', err.message);
    }
  }

  getDisplay(): display.Display | null {
    return this.currentDisplay;
  }

  getWidth(): number {
    return this.currentDisplay?.width || 0;
  }

  getHeight(): number {
    return this.currentDisplay?.height || 0;
  }

  getDPI(): number {
    return this.currentDisplay?.xDPI || 0;
  }

  /**
   * 鑾峰彇褰撳墠鎶樺彔鐘舵€?   */
  getFoldStatus(): FoldStatus {
    return this.currentFoldStatus;
  }

  /**
   * 鏄�惁涓烘姌鍙犲睆璁惧�
   */
  isFoldable(): boolean {
    return this.isFoldableDevice;
  }

  /**
   * 鏄�惁澶勪簬鎶樺彔鐘舵€?   */
  isFolded(): boolean {
    return this.currentFoldStatus === FoldStatus.FOLDED;
  }

  /**
   * 鏄�惁澶勪簬鍗婃姌鍙犵姸鎬?   */
  isHalfFolded(): boolean {
    return this.currentFoldStatus === FoldStatus.HALF_FOLDED;
  }

  /**
   * 鏄�惁澶勪簬灞曞紑鐘舵€?   */
  isExpanded(): boolean {
    return this.currentFoldStatus === FoldStatus.EXPANDED;
  }

  /**
   * 鑾峰彇灞忓箷绫诲瀷
   */
  getScreenType(): ScreenType {
    if (this.isFoldableDevice) {
      return ScreenType.FOLDABLE;
    }
    
    const widthVp = this.getWidth() / (this.getDPI() || 160);
    if (widthVp >= 840) {
      return ScreenType.TABLET;
    } else if (widthVp >= 600) {
      return ScreenType.PHONE; // 澶у睆鎵嬫満
    }
    return ScreenType.PHONE;
  }

  /**
   * 鑾峰彇鎺ㄨ崘鐨勫竷灞€妯″紡
   */
  getRecommendedLayout(): 'single' | 'dual' | 'triple' {
    const widthVp = this.getWidth() / (this.getDPI() || 160);
    
    if (widthVp >= 1200) {
      return 'triple';  // 涓夋爮甯冨眬
    } else if (widthVp >= 600) {
      return 'dual';    // 鍙屾爮甯冨眬
    }
    return 'single';    // 鍗曟爮甯冨眬
  }
}

export const displayHelper = DisplayHelper.getInstance();

// Legacy compatible wrapper
export function getDefaultDisplaySync(): display.Display | null {
  return displayHelper.getDisplay();
}