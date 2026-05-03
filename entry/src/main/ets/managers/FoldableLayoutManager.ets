/**
 * 折叠屏自适应布局管理器 - Foldable Adaptive Layout Manager
 * 
 * 统一管理折叠屏设备的布局适配:
 * - 监听折叠状态变化
 * - 自动切换布局模式
 * - 提供响应式断点系统
 * - 支持多窗口分屏适配
 * 
 * @since 4.0.0
 */

import { displayHelper, FoldStatus, ScreenType } from '../utils/DisplayHelper';
import { window, display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/**
 * 布局模式枚举
 */
export enum LayoutMode {
  SINGLE = 'single',      // 单栏 (手机/折叠态)
  DUAL = 'dual',          // 双栏 (平板/半折叠)
  TRIPLE = 'triple'       // 三栏 (大屏平板/展开态)
}

/**
 * 断点配置
 */
export interface BreakpointConfig {
  sm: number;  // < 600vp  手机竖屏
  md: number;  // < 840vp  手机横屏/小平板
  lg: number;  // >= 840vp 大平板/折叠屏展开
}

/**
 * 默认断点
 */
const DEFAULT_BREAKPOINTS: BreakpointConfig = {
  sm: 600,
  md: 840,
  lg: 1200
};

/**
 * 布局配置
 */
export interface AdaptiveLayoutConfig {
  /** 当前断点 */
  breakpoint: 'sm' | 'md' | 'lg';
  /** 布局模式 */
  layoutMode: LayoutMode;
  /** 列数 */
  columns: number;
  /** 间距 */
  gutter: number;
  /** 是否显示侧边栏 */
  showSidebar: boolean;
  /** 是否显示详情面板 */
  showDetail: boolean;
}

class FoldableLayoutManagerClass {
  private static instance: FoldableLayoutManagerClass;
  private context: common.Context | null = null;
  private currentConfig: AdaptiveLayoutConfig | null = null;
  private breakpoints: BreakpointConfig = DEFAULT_BREAKPOINTS;
  
  // 监听器
  private layoutListeners: Array<(config: AdaptiveLayoutConfig) => void> = [];
  private foldListeners: Array<(status: FoldStatus) => void> = [];
  
  // 窗口实例
  private mainWindow: window.Window | null = null;
  
  private constructor() {}

  static getInstance(): FoldableLayoutManagerClass {
    if (!FoldableLayoutManagerClass.instance) {
      FoldableLayoutManagerClass.instance = new FoldableLayoutManagerClass();
    }
    return FoldableLayoutManagerClass.instance;
  }

  /**
   * 初始化管理器
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    
    try {
      // 获取主窗口
      this.mainWindow = await window.getLastWindow(context);
      
      // 注册监听器
      this.registerListeners();
      
      // 初始化配置
      this.updateLayoutConfig();
      
      console.info('[FoldableLayoutManager] Initialized');
    } catch (error) {
      const err = error as Error;
      console.error('[FoldableLayoutManager] Init failed:', err.message);
    }
  }

  /**
   * 注册所有监听器
   */
  private registerListeners() {
    if (!this.mainWindow) return;
    
    // 监听窗口大小变化
    this.mainWindow.on('windowSizeChange', (size: window.Size) => {
      console.info('[FoldableLayoutManager] Window size changed:', size.width, 'x', size.height);
      this.updateLayoutConfig();
    });
    
    // 监听显示变化(折叠/展开)
    display.on('change', (id: number) => {
      console.info('[FoldableLayoutManager] Display changed:', id);
      this.updateLayoutConfig();
    });
  }

  /**
   * 更新布局配置
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
    
    // 通知监听器
    this.notifyLayoutListeners();
    this.notifyFoldListeners(foldStatus);
    
    console.info('[FoldableLayoutManager] Layout updated:', JSON.stringify(this.currentConfig));
  }

  /**
   * 获取宽度(vp)
   */
  private getWidthVp(): number {
    const displayInfo = displayHelper.getDisplay();
    if (!displayInfo) return 360;
    
    return displayInfo.width / displayInfo.densityPixels;
  }

  /**
   * 计算断点
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
   * 计算布局模式
   */
  private calculateLayoutMode(breakpoint: 'sm' | 'md' | 'lg'): LayoutMode {
    const foldStatus = displayHelper.getFoldStatus();
    
    // 折叠屏特殊处理
    if (displayHelper.isFoldable()) {
      if (foldStatus === FoldStatus.FOLDED) {
        return LayoutMode.SINGLE;
      } else if (foldStatus === FoldStatus.HALF_FOLDED) {
        return LayoutMode.DUAL;
      } else if (foldStatus === FoldStatus.EXPANDED) {
        return LayoutMode.TRIPLE;
      }
    }
    
    // 普通设备
    switch (breakpoint) {
      case 'sm':
        return LayoutMode.SINGLE;
      case 'md':
        return LayoutMode.DUAL;
      case 'lg':
        return LayoutMode.TRIPLE;
    }
  }

  /**
   * 获取列数
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
   * 获取间距
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
   * 获取当前配置
   */
  getConfig(): AdaptiveLayoutConfig | null {
    return this.currentConfig;
  }

  /**
   * 获取当前断点
   */
  getCurrentBreakpoint(): 'sm' | 'md' | 'lg' {
    return this.currentConfig?.breakpoint || 'sm';
  }

  /**
   * 获取当前布局模式
   */
  getCurrentLayoutMode(): LayoutMode {
    return this.currentConfig?.layoutMode || LayoutMode.SINGLE;
  }

  /**
   * 是否为单栏模式
   */
  isSingleColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.SINGLE;
  }

  /**
   * 是否为双栏模式
   */
  isDualColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.DUAL;
  }

  /**
   * 是否为三栏模式
   */
  isTripleColumn(): boolean {
    return this.getCurrentLayoutMode() === LayoutMode.TRIPLE;
  }

  /**
   * 是否应该显示平行视界
   */
  shouldShowParallelView(): boolean {
    const mode = this.getCurrentLayoutMode();
    return mode === LayoutMode.DUAL || mode === LayoutMode.TRIPLE;
  }

  /**
   * 获取网格列数模板
   */
  getGridColumnsTemplate(): string {
    const columns = this.currentConfig?.columns || 1;
    return Array(columns).fill('1fr').join(' ');
  }

  /**
   * 注册布局变化监听器
   */
  onLayoutChange(callback: (config: AdaptiveLayoutConfig) => void): () => void {
    this.layoutListeners.push(callback);
    
    // 立即调用一次
    if (this.currentConfig) {
      callback(this.currentConfig);
    }
    
    // 返回取消订阅函数
    return () => {
      const index = this.layoutListeners.indexOf(callback);
      if (index > -1) {
        this.layoutListeners.splice(index, 1);
      }
    };
  }

  /**
   * 注册折叠状态监听器
   */
  onFoldStatusChange(callback: (status: FoldStatus) => void): () => void {
    this.foldListeners.push(callback);
    
    // 立即调用一次
    const currentStatus = displayHelper.getFoldStatus();
    callback(currentStatus);
    
    // 返回取消订阅函数
    return () => {
      const index = this.foldListeners.indexOf(callback);
      if (index > -1) {
        this.foldListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知布局监听器
   */
  private notifyLayoutListeners() {
    if (!this.currentConfig) return;
    
    for (let i = 0; i < this.layoutListeners.length; i++) {
      try {
        this.layoutListeners[i](this.currentConfig);
      } catch (error) {
        const err = error as Error;
        console.error('[FoldableLayoutManager] Layout listener error:', err.message);
      }
    }
  }

  /**
   * 通知折叠监听器
   */
  private notifyFoldListeners(status: FoldStatus) {
    for (let i = 0; i < this.foldListeners.length; i++) {
      try {
        this.foldListeners[i](status);
      } catch (error) {
        const err = error as Error;
        console.error('[FoldableLayoutManager] Fold listener error:', err.message);
      }
    }
  }

  /**
   * 设置自定义断点
   */
  setBreakpoints(breakpoints: BreakpointConfig) {
    this.breakpoints = breakpoints;
    this.updateLayoutConfig();
  }

  /**
   * 清理资源
   */
  cleanup() {
    if (this.mainWindow) {
      this.mainWindow.off('windowSizeChange');
    }
    display.off('change');
    this.layoutListeners = [];
    this.foldListeners = [];
    console.info('[FoldableLayoutManager] Cleaned up');
  }
}

export const foldableLayoutManager = FoldableLayoutManagerClass.getInstance();

// ==================== 便捷Hook函数 ====================

/**
 * 在组件中使用的Hook - 获取布局配置
 * 
 * @example
 * const config = useAdaptiveLayout();
 * if (config.layoutMode === LayoutMode.DUAL) {
 *   // 双栏布局逻辑
 * }
 */
export function useAdaptiveLayout(): AdaptiveLayoutConfig {
  // 注意: 这需要在@Entry组件的aboutToAppear中调用init
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
 * 判断是否应该使用平行视界
 */
export function useParallelView(): boolean {
  return foldableLayoutManager.shouldShowParallelView();
}

/**
 * 获取当前断点
 */
export function useBreakpoint(): 'sm' | 'md' | 'lg' {
  return foldableLayoutManager.getCurrentBreakpoint();
}
