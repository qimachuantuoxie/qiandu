/**
 * 折叠屏适配管理器
 * 提供折叠屏设备布局、间距、字体等适配值
 * 根据折叠状态动态调整
 */

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
   * 获取折叠屏间距（根据折叠状态调整）
   */
  getSpacing(): number {
    if (!displayHelper.isFoldable()) {
      return 16; // 非折叠屏默认间距
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 32; // 展开状态更大间距
      case FoldStatus.HALF_FOLDED:
        return 24; // 半折叠中等间距
      case FoldStatus.FOLDED:
        return 16; // 折叠状态紧凑间距
      default:
        return 16;
    }
  }

  /**
   * 获取网格列数（根据折叠状态调整）
   */
  getGridColumns(): number {
    if (!displayHelper.isFoldable()) {
      return 3; // 非折叠屏默认列数
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 6; // 展开状态最多列
      case FoldStatus.HALF_FOLDED:
        return 4; // 半折叠中等列数
      case FoldStatus.FOLDED:
        return 3; // 折叠状态较少列
      default:
        return 3;
    }
  }

  /**
   * 获取字体大小乘数（根据折叠状态调整）
   */
  getFontSizeMultiplier(): number {
    if (!displayHelper.isFoldable()) {
      return 1.0;
    }
    const status = displayHelper.getFoldStatus();
    switch (status) {
      case FoldStatus.EXPANDED:
        return 1.2; // 展开状态字体放大
      case FoldStatus.HALF_FOLDED:
        return 1.1;
      case FoldStatus.FOLDED:
        return 1.0;
      default:
        return 1.0;
    }
  }

  /**
   * 是否使用平行视界（双栏布局）
   */
  shouldUseParallelView(): boolean {
    if (!displayHelper.isFoldable()) {
      return false;
    }
    const status = displayHelper.getFoldStatus();
    // 展开或半折叠状态可使用平行视界
    return status === FoldStatus.EXPANDED || status === FoldStatus.HALF_FOLDED;
  }
}

export const foldableAdapter = FoldableAdapterManager.getInstance();
