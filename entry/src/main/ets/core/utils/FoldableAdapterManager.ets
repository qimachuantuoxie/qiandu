/**
 * 鎶樺彔灞忛€傞厤绠＄悊鍣? * 鎻愪緵鎶樺彔灞忚澶囧竷灞€銆侀棿璺濄€佸瓧浣撶瓑閫傞厤鍊? * 鏍规嵁鎶樺彔鐘舵€佸姩鎬佽皟鏁? */

import { displayHelper, FoldStatus } from './DisplayHelper';

export class FoldableAdapterManager {
  private static instance: FoldableAdapterManager | null = null;

  static getInstance(): FoldableAdapterManager {
    if (!FoldableAdapterManager.instance) {
      FoldableAdapterManager.instance = new FoldableAdapterManager();
    }
    return FoldableAdapterManager.instance;
  }

  /**
   * 鑾峰彇鎶樺彔灞忛棿璺濓紙鏍规嵁鎶樺彔鐘舵€佽皟鏁达級
   */
  getSpacing(): number {
    if (!displayHelper.isFoldable()) {
      return 16; // 闈炴姌鍙犲睆榛樿闂磋窛
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 32; // 灞曞紑鐘舵€佹洿澶ч棿璺?      case FoldStatus.HALF_FOLDED:
        return 24; // 鍗婃姌鍙犱腑绛夐棿璺?      case FoldStatus.FOLDED:
        return 16; // 鎶樺彔鐘舵€佺揣鍑戦棿璺?      default:
        return 16;
    }
  }

  /**
   * 鑾峰彇缃戞牸鍒楁暟锛堟牴鎹姌鍙犵姸鎬佽皟鏁达級
   */
  getGridColumns(): number {
    if (!displayHelper.isFoldable()) {
      return 3; // 闈炴姌鍙犲睆榛樿鍒楁暟
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 6; // 灞曞紑鐘舵€佹渶澶氬垪
      case FoldStatus.HALF_FOLDED:
        return 4; // 鍗婃姌鍙犱腑绛夊垪鏁?      case FoldStatus.FOLDED:
        return 3; // 鎶樺彔鐘舵€佽緝灏戝垪
      default:
        return 3;
    }
  }

  /**
   * 鑾峰彇瀛椾綋澶у皬涔樻暟锛堟牴鎹姌鍙犵姸鎬佽皟鏁达級
   */
  getFontSizeMultiplier(): number {
    if (!displayHelper.isFoldable()) {
      return 1.0;
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 1.2; // 灞曞紑鐘舵€佸瓧浣撴斁澶?      case FoldStatus.HALF_FOLDED:
        return 1.1;
      case FoldStatus.FOLDED:
        return 1.0;
      default:
        return 1.0;
    }
  }

  /**
   * 鏄惁浣跨敤骞宠瑙嗙晫锛堝弻鏍忓竷灞€锛?   */
  shouldUseParallelView(): boolean {
    if (!displayHelper.isFoldable()) {
      return false;
    }
    const status = displayHelper.getFoldStatus();
    // 灞曞紑鎴栧崐鎶樺彔鐘舵€佸彲浣跨敤骞宠瑙嗙晫
    return status === FoldStatus.EXPANDED || status === FoldStatus.HALF_FOLDED;
  }
}

export const foldableAdapter = FoldableAdapterManager.getInstance();