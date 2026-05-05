/**
 * ArkUI 布局常量系统
 * 提供统一的间距、尺寸、圆角等布局常量
 * 
 * @since 7.0.0
 */

// ==================== 接口定义 (Interface Definitions) ====================
interface SpacingType {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
  xxxl: number;
}

interface SizeType {
  iconXS: number;
  iconSM: number;
  iconMD: number;
  iconLG: number;
  iconXL: number;
  iconXXL: number;
  avatarSM: number;
  avatarMD: number;
  avatarLG: number;
  avatarXL: number;
  buttonSM: number;
  buttonMD: number;
  buttonLG: number;
  buttonXL: number;
  inputSM: number;
  inputMD: number;
  inputLG: number;
  cardSM: number;
  cardMD: number;
  cardLG: number;
}

interface BorderRadiusType {
  none: number;
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
  full: number;
}

interface ShadowItem {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

interface ShadowType {
  sm: ShadowItem;
  md: ShadowItem;
  lg: ShadowItem;
  xl: ShadowItem;
}

interface BreakpointsType {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
}

interface GridGutter {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface GridType {
  columns: number;
  gutter: GridGutter;
}

interface ZIndexType {
  base: number;
  dropdown: number;
  sticky: number;
  fixed: number;
  modalBackdrop: number;
  modal: number;
  popover: number;
  tooltip: number;
  toast: number;
}

interface AnimationDurationType {
  fast: number;
  normal: number;
  slow: number;
  slower: number;
}

interface OpacityType {
  disabled: number;
  secondary: number;
  hover: number;
  full: number;
}

// ==================== 间距系统 (Spacing System) ====================
export const Spacing: SpacingType = {
  xs: 4,    // 超小间距
  sm: 8,    // 小间距
  md: 12,   // 中等间距
  lg: 16,   // 大间距
  xl: 20,   // 超大间距
  xxl: 24,  // 特大间距
  xxxl: 32  // 巨大间距
};

// ==================== 尺寸系统 (Size System) ====================
export const Size: SizeType = {
  // 图标尺寸
  iconXS: 16,
  iconSM: 20,
  iconMD: 24,
  iconLG: 28,
  iconXL: 32,
  iconXXL: 40,

  // 头像尺寸
  avatarSM: 32,
  avatarMD: 40,
  avatarLG: 48,
  avatarXL: 56,

  // 按钮高度
  buttonSM: 36,
  buttonMD: 44,
  buttonLG: 48,
  buttonXL: 56,

  // 输入框高度
  inputSM: 36,
  inputMD: 40,
  inputLG: 48,

  // 卡片最小高度
  cardSM: 80,
  cardMD: 120,
  cardLG: 160
};

// ==================== 圆角系统 (Border Radius System) ====================
export const BorderRadius: BorderRadiusType = {
  none: 0,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  full: 999  // 完全圆形
};

// ==================== 阴影系统 (Shadow System) ====================
export const Shadow: ShadowType = {
  // 轻微阴影
  sm: {
    radius: 4,
    color: 'rgba(0,0,0,0.08)',
    offsetX: 0,
    offsetY: 2
  },
  // 中等阴影
  md: {
    radius: 8,
    color: 'rgba(0,0,0,0.12)',
    offsetX: 0,
    offsetY: 4
  },
  // 深度阴影
  lg: {
    radius: 12,
    color: 'rgba(0,0,0,0.16)',
    offsetX: 0,
    offsetY: 6
  },
  // 悬浮阴影
  xl: {
    radius: 16,
    color: 'rgba(0,0,0,0.2)',
    offsetX: 0,
    offsetY: 8
  }
};

// 深色模式阴影
export const ShadowDark: ShadowType = {
  sm: {
    radius: 4,
    color: 'rgba(0,0,0,0.3)',
    offsetX: 0,
    offsetY: 2
  },
  md: {
    radius: 8,
    color: 'rgba(0,0,0,0.4)',
    offsetX: 0,
    offsetY: 4
  },
  lg: {
    radius: 12,
    color: 'rgba(0,0,0,0.5)',
    offsetX: 0,
    offsetY: 6
  },
  xl: {
    radius: 16,
    color: 'rgba(0,0,0,0.6)',
    offsetX: 0,
    offsetY: 8
  }
};

// ==================== 断点系统 (Breakpoint System) ====================
export const Breakpoints: BreakpointsType = {
  xs: 0,      // 超小屏幕
  sm: 320,    // 小屏幕（手机竖屏）
  md: 600,    // 中等屏幕（折叠屏/大手机）
  lg: 840,    // 大屏幕（平板竖屏）
  xl: 1200,   // 超大屏幕（平板横屏/桌面）
  xxl: 1600   // 特大屏幕（大屏桌面）
};

// ==================== 网格系统 (Grid System) ====================
export const Grid: GridType = {
  columns: 12,  // 总列数
  gutter: {
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24
  }
};

// ==================== Z-Index 层级系统 ====================
export const ZIndex: ZIndexType = {
  base: 0,
  dropdown: 100,
  sticky: 200,
  fixed: 300,
  modalBackdrop: 400,
  modal: 500,
  popover: 600,
  tooltip: 700,
  toast: 800
};

// ==================== 动画时长系统 ====================
export const AnimationDuration: AnimationDurationType = {
  fast: 150,
  normal: 200,
  slow: 300,
  slower: 400
};

// ==================== 透明度系统 ====================
export const Opacity: OpacityType = {
  disabled: 0.4,
  secondary: 0.6,
  hover: 0.8,
  full: 1.0
};

/**
 * 获取响应式间距
 * @param breakpoint 当前断点
 * @returns 合适的间距值
 */
export function getResponsiveSpacing(breakpoint: string): number {
  switch (breakpoint) {
    case 'xs':
      return Spacing.xs;
    case 'sm':
      return Spacing.sm;
    case 'md':
      return Spacing.md;
    case 'lg':
      return Spacing.lg;
    case 'xl':
      return Spacing.xl;
    default:
      return Spacing.md;
  }
}

/**
 * 获取响应式网格列数
 * @param screenWidth 屏幕宽度
 * @returns 网格列数
 */
export function getResponsiveColumns(screenWidth: number): number {
  if (screenWidth < Breakpoints.md) {
    return 2;
  } else if (screenWidth < Breakpoints.lg) {
    return 3;
  } else if (screenWidth < Breakpoints.xl) {
    return 4;
  } else {
    return 5;
  }
}

/**
 * 获取阴影配置
 * @param level 阴影级别
 * @param isDarkMode 是否深色模式
 * @returns 阴影配置对象
 */
export function getShadow(level: 'sm' | 'md' | 'lg' | 'xl', isDarkMode: boolean = false) {
  return isDarkMode ? ShadowDark[level] : Shadow[level];
}
