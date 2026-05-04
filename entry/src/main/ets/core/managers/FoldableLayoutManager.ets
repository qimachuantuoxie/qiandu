import { logger } from '../../utils/Logger';
/**
 * 鎶樺彔灞忚嚜閫傚簲甯冨眬绠＄悊鍣?- Foldable Adaptive Layout Manager
 * 
 * 缁熶竴绠＄悊鎶樺彔灞忚�澶囩殑甯冨眬閫傞厤:
 * - 鐩戝惉鎶樺彔鐘舵€佸彉鍖? * - 鑷�姩鍒囨崲甯冨眬妯″紡
 * - 鎻愪緵鍝嶅簲寮忔柇鐐圭郴缁? * - 鏀�寔澶氱獥鍙ｅ垎灞忛€傞厤
 * 
 * @since 4.0.0
 */

import { displayHelper, FoldStatus, ScreenType } from '../utils/DisplayHelper';
import { window, display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/**
 * 甯冨眬妯″紡鏋氫妇
 */
export enum LayoutMode {
  SINGLE = 'single',      // 鍗曟爮 (鎵嬫満/鎶樺彔鎬?
  DUAL = 'dual',          // 鍙屾爮 (骞虫澘/鍗婃姌鍙?
  TRIPLE = 'triple'       // 涓夋爮 (澶у睆骞虫澘/灞曞紑鎬?
}

/**
 * 鏂�偣閰嶇疆
 */
export interface BreakpointConfig {
  sm: number;  // < 600vp  鎵嬫満绔栧睆
  md: number;  // < 840vp  鎵嬫満妯�睆/灏忓钩鏉?  lg: number;  // >= 840vp 澶у钩鏉?鎶樺彔灞忓睍寮€
}

/**
 * 榛樿�鏂�偣
 */
const DEFAULT_BREAKPOINTS: BreakpointConfig = {
  sm: 600,
  md: 840,
  lg: 1200
};

/**
 * 甯冨眬閰嶇疆
 */
export interface AdaptiveLayoutConfig {
  /** 褰撳墠鏂�偣 */
  breakpoint: 'sm' | 'md' | 'lg';
  /** 甯冨眬妯″紡 */
  layoutMode: LayoutMode;
  /** 鍒楁暟 */
  columns: number;
  /** 闂磋窛 */
  gutter: number;
  /** 鏄�惁鏄剧ず渚ц竟鏍?*/
  showSidebar: boolean;
  /** 鏄�惁鏄剧ず璇︽儏闈㈡澘 */
  showDetail: boolean;
}

class FoldableLayoutManagerClass {
  private static instance: FoldableLayoutManagerClass;
  private context: common.Context | null = null;
  private currentConfig: AdaptiveLayoutConfig | null = null;
  private breakpoints: BreakpointConfig = DEFAULT_BREAKPOINTS;
  
  // 鐩戝惉鍣?  private layoutListeners: Array<(config: AdaptiveLayoutConfig) => void> = [];
  private foldListeners: Array<(status: FoldStatus) => void> = [];
  
  // 绐楀彛瀹炰緥
  private mainWindow: window.Window | null = null;
  
  private constructor() {}

  static getInstance(): FoldableLayoutManagerClass {
    if (!FoldableLayoutManagerClass.instance) {
      FoldableLayoutManagerClass.instance = new FoldableLayoutManagerClass();
    }
    return FoldableLayoutManagerClass.instance;
  }

  /**
   * 鍒濆�鍖栫�鐞嗗櫒
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    
    try {
      // 鑾峰彇涓荤獥鍙?      this.mainWindow = await window.getLastWindow(context);
      
      // 娉ㄥ唽鐩戝惉鍣?      this.registerListeners();
      
      // 鍒濆�鍖栭厤缃?      this.updateLayoutConfig();
      
      logger.info('[FoldableLayoutManager] Initialized');
    } catch (error) {
      const err = error as Error;
      logger.error('[FoldableLayoutManager] Init failed:', err.message);
    }
  }

  /**
   * 娉ㄥ唽鎵€鏈夌洃鍚�櫒
   */
  private registerListeners() {
    if (!this.mainWindow) return;
    
    // 鐩戝惉绐楀彛澶у皬鍙樺寲
    this.mainWindow.on('windowSizeChange', (size: window.Size) => {
      logger.info('[FoldableLayoutManager] Window size changed:', size.width, 'x', size.height);
      this.updateLayoutConfig();
    });
    
    // 鐩戝惉鏄剧ず鍙樺寲(鎶樺彔/灞曞紑)
    display.on('change', (id: number) => {
      logger.info('[FoldableLayoutManager] Display changed:', id);
      this.updateLayoutConfig();
    });
  }

  /**
   * 鏇存柊甯冨眬閰嶇疆
   */
  private updateLayoutConfig() {
    const widthVp = this.getWidthVp();
    const breakpoint = this.calculateBreakpoint(widthVp);
    const layoutMode = this.calculateLayoutMode(breakpoint);
    const foldStatus = displayHelper.getFoldStatus();
    
    this.currentConfig = {
      breakpoint,
      layoutMode,
      columns: this.getColumns(layoutMode),
      gutter: this.getGutter(breakpoint),
      showSidebar: layoutMode !== LayoutMode.SINGLE,
      showDetail: layoutMode === LayoutMode.TRIPLE
    };
    
    // 閫氱煡鐩戝惉鍣?    this.notifyLayoutListeners();
    this.notifyFoldListeners(foldStatus);
    
    logger.info('[FoldableLayoutManager] Layout updated:', JSON.stringify(this.currentConfig));
  }

  /**
   * 鑾峰彇瀹藉害(vp)
   */
  private getWidthVp(): number {
    const displayInfo = displayHelper.getDisplay();
    if (!displayInfo) return 360;
    
    return displayInfo.width / displayInfo.densityPixels;
  }

  /**
   * 璁＄畻鏂�偣
   */
  private calculateBreakpoint(widthVp: number): 'sm' | 'md' | 'lg' {
    if (widthVp < this.breakpoints.sm) {
      return 'sm';
    } else if (widthVp < this.breakpoints.md) {
      return 'md';
    }
    return 'lg';
  }

  /**
   * 璁＄畻甯冨眬妯″紡
   */
  private calculateLayoutMode(breakpoint: 'sm' | 'md' | 'lg'): LayoutMode {
    const foldStatus = displayHelper.getFoldStatus();
    
    // 鎶樺彔灞忕壒娈婂�鐞?    if (displayHelper.isFoldable()) {
      if (foldStatus === FoldStatus.FOLDED) {
        return LayoutMode.SINGLE;
      } else if (foldStatus === FoldStatus.HALF_FOLDED) {
        return LayoutMode.DUAL;
      } else if (foldStatus === FoldStatus.EXPANDED) {
        return LayoutMode.TRIPLE;
      }
    }
    
    // 鏅�€氳�澶?    switch (breakpoint) {
      case 'sm':
        return LayoutMode.SINGLE;
      case 'md':
        return LayoutMode.DUAL;
      case 'lg':
        return LayoutMode.TRIPLE;
    }
  }

  /**
   * 鑾峰彇鍒楁暟
   */
  private getColumns(mode: LayoutMode): number {
    switch (mode) {
      case LayoutMode.SINGLE:
        return 1;
      case LayoutMode.DUAL:
        return 2;
      case LayoutMode.TRIPLE:
        return 3;
    }
  }

  /**
   * 鑾峰彇闂磋窛
   */
  private getGutter(breakpoint: 'sm' | 'md' | 'lg'): number {
    switch (breakpoint) {
      case 'sm':
        return 8;
      case 'md':
        return 12;
      case 'lg':
        return 16;
    }
  }

  /**
   * 鑾峰彇褰撳墠閰嶇疆
   */
  getConfig(): AdaptiveLayoutConfig | null {
    return this.currentConfig;
  }

  /**
   * 鑾峰彇褰撳墠鏂�偣
   */
  getCurrentBreakpoint(): 'sm' | 'md' | 'lg' {
    return this.currentConfig?.breakpoint || 'sm';
  }

  /**
   * 鑾峰彇褰撳墠甯冨眬妯″紡
   */
  getCurrentLayoutMode(): LayoutMode {
    return this.currentConfig?.layoutMode || LayoutMode.SINGLE;
  }

  /**
   * 鏄�惁涓哄崟鏍忔ā寮?   */
  isSingleColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.SINGLE;
  }

  /**
   * 鏄�惁涓哄弻鏍忔ā寮?   */
  isDualColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.DUAL;
  }

  /**
   * 鏄�惁涓轰笁鏍忔ā寮?   */
  isTripleColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.TRIPLE;
  }

  /**
   * 鏄�惁搴旇�鏄剧ず骞宠�瑙嗙晫
   */
  shouldShowParallelView(): boolean {
    const mode = this.getCurrentLayoutMode();
    return mode === LayoutMode.DUAL || mode === LayoutMode.TRIPLE;
  }

  /**
   * 鑾峰彇缃戞牸鍒楁暟妯℃澘
   */
  getGridColumnsTemplate(): string {
    const columns = this.currentConfig?.columns || 1;
    return Array(columns).fill('1fr').join(' ');
  }

  /**
   * 娉ㄥ唽甯冨眬鍙樺寲鐩戝惉鍣?   */
  onLayoutChange(callback: (config: AdaptiveLayoutConfig) => void): () => void {
    this.layoutListeners.push(callback);
    
    // 绔嬪嵆璋冪敤涓€娆?    if (this.currentConfig) {
      callback(this.currentConfig);
    }
    
    // 杩斿洖鍙栨秷璁㈤槄鍑芥暟
    return () => {
      const index = this.layoutListeners.indexOf(callback);
      if (index > -1) {
        this.layoutListeners.splice(index, 1);
      }
    };
  }

  /**
   * 娉ㄥ唽鎶樺彔鐘舵€佺洃鍚�櫒
   */
  onFoldStatusChange(callback: (status: FoldStatus) => void): () => void {
    this.foldListeners.push(callback);
    
    // 绔嬪嵆璋冪敤涓€娆?    const currentStatus = displayHelper.getFoldStatus();
    callback(currentStatus);
    
    // 杩斿洖鍙栨秷璁㈤槄鍑芥暟
    return () => {
      const index = this.foldListeners.indexOf(callback);
      if (index > -1) {
        this.foldListeners.splice(index, 1);
      }
    };
  }

  /**
   * 閫氱煡甯冨眬鐩戝惉鍣?   */
  private notifyLayoutListeners() {
    if (!this.currentConfig) return;
    
    for (let i = 0; i < this.layoutListeners.length; i++) {
      try {
        this.layoutListeners[i](this.currentConfig);
      } catch (error) {
        const err = error as Error;
        logger.error('[FoldableLayoutManager] Layout listener error:', err.message);
      }
    }
  }

  /**
   * 閫氱煡鎶樺彔鐩戝惉鍣?   */
  private notifyFoldListeners(status: FoldStatus) {
    for (let i = 0; i < this.foldListeners.length; i++) {
      try {
        this.foldListeners[i](status);
      } catch (error) {
        const err = error as Error;
        logger.error('[FoldableLayoutManager] Fold listener error:', err.message);
      }
    }
  }

  /**
   * 璁剧疆鑷�畾涔夋柇鐐?   */
  setBreakpoints(breakpoints: BreakpointConfig) {
    this.breakpoints = breakpoints;
    this.updateLayoutConfig();
  }

  /**
   * 娓呯悊璧勬簮
   */
  cleanup() {
    if (this.mainWindow) {
      this.mainWindow.off('windowSizeChange');
    }
    display.off('change');
    this.layoutListeners = [];
    this.foldListeners = [];
    logger.info('[FoldableLayoutManager] Cleaned up');
  }
}

export const foldableLayoutManager = FoldableLayoutManagerClass.getInstance();

// ==================== 渚挎嵎Hook鍑芥暟 ====================

/**
 * 鍦ㄧ粍浠朵腑浣跨敤鐨凥ook - 鑾峰彇甯冨眬閰嶇疆
 * 
 * @example
 * const config = useAdaptiveLayout();
 * if (config.layoutMode === LayoutMode.DUAL) {
 *   // 鍙屾爮甯冨眬閫昏緫
 * }
 */
export function useAdaptiveLayout(): AdaptiveLayoutConfig {
  // 娉ㄦ剰: 杩欓渶瑕佸湪@Entry缁勪欢鐨刟boutToAppear涓�皟鐢╥nit
  return foldableLayoutManager.getConfig() || {
    breakpoint: 'sm',
    layoutMode: LayoutMode.SINGLE,
    columns: 1,
    gutter: 8,
    showSidebar: false,
    showDetail: false
  };
}

/**
 * 鍒ゆ柇鏄�惁搴旇�浣跨敤骞宠�瑙嗙晫
 */
export function useParallelView(): boolean {
  return foldableLayoutManager.shouldShowParallelView();
}

/**
 * 鑾峰彇褰撳墠鏂�偣
 */
export function useBreakpoint(): 'sm' | 'md' | 'lg' {
  return foldableLayoutManager.getCurrentBreakpoint();
}
