/**
 * 甯冨眬杈呭姪宸ュ叿绫? * 鎻愪緵灞忓箷妫€娴嬨€佸搷搴斿紡鍊艰绠椼€佸瓧浣撶缉鏀剧瓑瀹炵敤鍔熻兘
 * 
 * @since 7.0.0
 */

import { Breakpoints, Spacing, Size } from '../constants/LayoutConstants';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

export interface ScreenInfo {
  width: number;
  height: number;
  density: number;
  isPhone: boolean;
  isTablet: boolean;
  isFoldable: boolean;
  breakpoint: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl';
}

class LayoutHelper {
  private screenInfo: ScreenInfo | null = null;
  private context: common.Context | null = null;

  /**
   * 鍒濆鍖栧睆骞曚俊鎭?   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.updateScreenInfo();
  }

  /**
   * 鏇存柊灞忓箷淇℃伅
   */
  async updateScreenInfo(): Promise<void> {
    if (!this.context) return;

    try {
      const win = await window.getLastWindow(this.context);
      const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const rect = avoidArea.windowRect;
      
      const width = rect.width;
      const height = rect.height;
      const density = win.getWindowProperties().density;

      this.screenInfo = {
        width,
        height,
        density,
        isPhone: width < Breakpoints.md,
        isTablet: width >= Breakpoints.md && width < Breakpoints.xl,
        isFoldable: width >= Breakpoints.md && width < Breakpoints.lg,
        breakpoint: this.getBreakpoint(width)
      };
    } catch (error) {
      console.error('Failed to update screen info:', error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 鑾峰彇褰撳墠鏂偣
   */
  private getBreakpoint(width: number): 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl' {
    if (width < Breakpoints.sm) return 'xs';
    if (width < Breakpoints.md) return 'sm';
    if (width < Breakpoints.lg) return 'md';
    if (width < Breakpoints.xl) return 'lg';
    if (width < Breakpoints.xxl) return 'xl';
    return 'xxl';
  }

  /**
   * 鑾峰彇灞忓箷淇℃伅
   */
  getScreenInfo(): ScreenInfo | null {
    return this.screenInfo;
  }

  /**
   * 鏍规嵁鏂偣鑾峰彇鍝嶅簲寮忓€?   * @param values 涓嶅悓鏂偣瀵瑰簲鐨勫€?   * @returns 褰撳墠鏂偣瀵瑰簲鐨勫€?   */
  getResponsiveValue<T>(values: { xs?: T; sm?: T; md?: T; lg?: T; xl?: T; xxl?: T }): T | undefined {
    if (!this.screenInfo) return undefined;

    const breakpoint = this.screenInfo.breakpoint;
    switch (breakpoint) {
      case 'xs':
        return values.xs ?? values.sm ?? values.md;
      case 'sm':
        return values.sm ?? values.md;
      case 'md':
        return values.md ?? values.lg;
      case 'lg':
        return values.lg ?? values.xl;
      case 'xl':
        return values.xl ?? values.xxl;
      case 'xxl':
        return values.xxl ?? values.xl;
      default:
        return values.md;
    }
  }

  /**
   * 鑾峰彇鍝嶅簲寮忛棿璺?   */
  getResponsiveSpacing(): number {
    return this.getResponsiveValue({
      xs: Spacing.xs,
      sm: Spacing.sm,
      md: Spacing.md,
      lg: Spacing.lg,
      xl: Spacing.xl,
      xxl: Spacing.xxl
    }) || Spacing.md;
  }

  /**
   * 鑾峰彇鍝嶅簲寮忕綉鏍煎垪鏁?   */
  getResponsiveColumns(): number {
    if (!this.screenInfo) return 2;

    const width = this.screenInfo.width;
    if (width < Breakpoints.md) return 2;
    if (width < Breakpoints.lg) return 3;
    if (width < Breakpoints.xl) return 4;
    return 5;
  }

  /**
   * 鑾峰彇鍝嶅簲寮忓瓧浣撳ぇ灏?   * @param baseSize 鍩虹瀛椾綋澶у皬
   * @returns 鍝嶅簲寮忓瓧浣撳ぇ灏?   */
  getResponsiveFontSize(baseSize: number): number {
    if (!this.screenInfo) return baseSize;

    const scale = this.getResponsiveValue({
      xs: 0.85,
      sm: 0.9,
      md: 1.0,
      lg: 1.1,
      xl: 1.15,
      xxl: 1.2
    }) || 1.0;

    return Math.round(baseSize * scale);
  }

  /**
   * 鑾峰彇鍝嶅簲寮忓崱鐗囧搴?   * @param columns 鍒楁暟
   * @param gutter 闂磋窛
   * @returns 鍗＄墖瀹藉害
   */
  getCardWidth(columns: number = 2, gutter: number = Spacing.md): number {
    if (!this.screenInfo) return 150;

    const availableWidth = this.screenInfo.width - (gutter * (columns + 1));
    return Math.floor(availableWidth / columns);
  }

  /**
   * 鍒ゆ柇鏄惁涓烘í灞?   */
  isLandscape(): boolean {
    if (!this.screenInfo) return false;
    return this.screenInfo.width > this.screenInfo.height;
  }

  /**
   * 鑾峰彇瀹夊叏鐨勯《閮ㄩ棿璺濓紙閬垮紑鐘舵€佹爮锛?   */
  getSafeTopPadding(): number {
    if (!this.screenInfo) return Spacing.lg;
    
    // 骞虫澘鍜屾闈㈢闇€瑕佹洿澶х殑椤堕儴闂磋窛
    if (this.screenInfo.isTablet || this.screenInfo.breakpoint === 'xl' || this.screenInfo.breakpoint === 'xxl') {
      return Spacing.xl;
    }
    return Spacing.lg;
  }

  /**
   * 鑾峰彇瀹夊叏鐨勫簳閮ㄩ棿璺濓紙閬垮紑瀵艰埅鏍忥級
   */
  getSafeBottomPadding(): number {
    if (!this.screenInfo) return Spacing.lg;
    
    // 骞虫澘鍜屾闈㈢闇€瑕佹洿澶х殑搴曢儴闂磋窛
    if (this.screenInfo.isTablet || this.screenInfo.breakpoint === 'xl' || this.screenInfo.breakpoint === 'xxl') {
      return Spacing.xl;
    }
    return Spacing.lg;
  }

  /**
   * 璁＄畻鍚堥€傜殑鍒楄〃椤归珮搴?   * @param baseHeight 鍩虹楂樺害
   * @returns 鍝嶅簲寮忓垪琛ㄩ」楂樺害
   */
  getListItemHeight(baseHeight: number = 60): number {
    if (!this.screenInfo) return baseHeight;

    const scale = this.getResponsiveValue({
      xs: 0.9,
      sm: 0.95,
      md: 1.0,
      lg: 1.05,
      xl: 1.1,
      xxl: 1.15
    }) || 1.0;

    return Math.round(baseHeight * scale);
  }

  /**
   * 鑾峰彇鍝嶅簲寮忓浘鐗囧昂瀵?   * @param baseSize 鍩虹灏哄
   * @returns 鍝嶅簲寮忓浘鐗囧昂瀵?   */
  getImageSize(baseSize: number): number {
    return this.getResponsiveFontSize(baseSize);
  }

  /**
   * 鑾峰彇閫傚悎褰撳墠灞忓箷鐨勫竷灞€妯″紡
   * @returns 甯冨眬妯″紡锛歴ingle锛堝崟鏍忥級銆乻plit锛堝垎鏍忥級銆乬rid锛堢綉鏍硷級
   */
  getLayoutMode(): 'single' | 'split' | 'grid' {
    if (!this.screenInfo) return 'single';

    if (this.screenInfo.isPhone) return 'single';
    if (this.screenInfo.isFoldable) return 'split';
    if (this.isLandscape()) return 'split';
    return 'grid';
  }
}

// 瀵煎嚭鍗曚緥
export const layoutHelper = new LayoutHelper();
