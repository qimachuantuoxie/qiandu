/**
 * Display Helper for API 22+
 * Enhanced with foldable screen detection and multi-window support
 */
import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 折叠状态枚举
 */
export enum FoldStatus {
  UNKNOWN = 'unknown',
  FOLDED = 'folded',           // 折叠状态
  HALF_FOLDED = 'half_folded', // 半折叠状态
  EXPANDED = 'expanded'        // 展开状态
}

/**
 * 屏幕类型枚举
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
        
        // 检测是否为折叠屏设备
        this.detectFoldableDevice();
        
        // 注册显示变化监听器
        this.registerDisplayListener();
      }
    } catch (e) {
      const err = e as BusinessError;
      console.error('[DisplayHelper] Init failed:', err.message);
    }
  }

  /**
   * 检测是否为折叠屏设备
   */
  private detectFoldableDevice(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      // 检查是否有折叠状态属性（API 21+）
      const displayInfo = this.currentDisplay;
      
      // 通过屏幕尺寸和比例判断是否为折叠屏
      const widthVp = displayInfo.width / displayInfo.densityPixels;
      const heightVp = displayInfo.height / displayInfo.densityPixels;
      const aspectRatio = Math.max(widthVp, heightVp) / Math.min(widthVp, heightVp);
      
      // 折叠屏特征：展开后接近正方形或超宽屏
      this.isFoldableDevice = (
        aspectRatio < 1.5 ||  // 接近平方
        widthVp > 1000        // 超宽屏
      );
      
      console.info('[DisplayHelper] Foldable device detected:', this.isFoldableDevice);
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[DisplayHelper] Detect foldable failed:', err.message);
      this.isFoldableDevice = false;
    }
  }

  /**
   * 注册显示变化监听器
   */
  private registerDisplayListener(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      // 监听显示变化（包括折叠/展开）
      this.displayListener = (id: number) => {
        console.info('[DisplayHelper] Display changed:', id);
        this.updateFoldStatus();
      };
      
      display.on('change', this.displayListener);
      
      // 初始化折叠状态
      this.updateFoldStatus();
      
      console.info('[DisplayHelper] Display listener registered');
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[DisplayHelper] Register listener failed:', err.message);
    }
  }

  /**
   * 更新折叠状态
   */
  private updateFoldStatus(): void {
    if (!this.currentDisplay) {
      return;
    }

    try {
      const widthVp = this.currentDisplay.width / this.currentDisplay.densityPixels;
      const heightVp = this.currentDisplay.height / this.currentDisplay.densityPixels;
      
      // 根据屏幕尺寸判断折叠状态
      if (widthVp < 600) {
        this.currentFoldStatus = FoldStatus.FOLDED;
      } else if (widthVp >= 600 && widthVp < 840) {
        this.currentFoldStatus = FoldStatus.HALF_FOLDED;
      } else {
        this.currentFoldStatus = FoldStatus.EXPANDED;
      }
      
      console.info('[DisplayHelper] Fold status updated:', this.currentFoldStatus);
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[DisplayHelper] Update fold status failed:', err.message);
    }
  }

  /**
   * 清理资源
   */
  cleanup(): void {
    try {
      if (this.displayListener) {
        display.off('change', this.displayListener);
        this.displayListener = null;
      }
      
      if (this.windowSizeListener) {
        // 移除窗口大小监听器
        this.windowSizeListener = null;
      }
      
      console.info('[DisplayHelper] Cleanup completed');
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[DisplayHelper] Cleanup failed:', err.message);
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
   * 获取当前折叠状态
   */
  getFoldStatus(): FoldStatus {
    return this.currentFoldStatus;
  }

  /**
   * 是否为折叠屏设备
   */
  isFoldable(): boolean {
    return this.isFoldableDevice;
  }

  /**
   * 是否处于折叠状态
   */
  isFolded(): boolean {
    return this.currentFoldStatus === FoldStatus.FOLDED;
  }

  /**
   * 是否处于半折叠状态
   */
  isHalfFolded(): boolean {
    return this.currentFoldStatus === FoldStatus.HALF_FOLDED;
  }

  /**
   * 是否处于展开状态
   */
  isExpanded(): boolean {
    return this.currentFoldStatus === FoldStatus.EXPANDED;
  }

  /**
   * 获取屏幕类型
   */
  getScreenType(): ScreenType {
    if (this.isFoldableDevice) {
      return ScreenType.FOLDABLE;
    }
    
    const widthVp = this.getWidth() / (this.getDPI() || 160);
    if (widthVp >= 840) {
      return ScreenType.TABLET;
    } else if (widthVp >= 600) {
      return ScreenType.PHONE; // 大屏手机
    }
    return ScreenType.PHONE;
  }

  /**
   * 获取推荐的布局模式
   */
  getRecommendedLayout(): 'single' | 'dual' | 'triple' {
    const widthVp = this.getWidth() / (this.getDPI() || 160);
    
    if (widthVp >= 1200) {
      return 'triple';  // 三栏布局
    } else if (widthVp >= 600) {
      return 'dual';    // 双栏布局
    }
    return 'single';    // 单栏布局
  }
}

export const displayHelper = DisplayHelper.getInstance();

// Legacy compatible wrapper
export function getDefaultDisplaySync(): display.Display | null {
  return displayHelper.getDisplay();
}