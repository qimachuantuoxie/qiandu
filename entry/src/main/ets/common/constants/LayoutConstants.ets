/**
 * ArkUI 甯冨眬甯搁噺绯荤粺
 * 鎻愪緵缁熶竴鐨勯棿璺濄€佸昂瀵搞€佸渾瑙掔瓑甯冨眬甯搁噺
 * 
 * @since 7.0.0
 */

// ==================== 鎺ュ彛瀹氫箟 (Interface Definitions) ====================
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

// ==================== 闂磋窛绯荤粺 (Spacing System) ====================
export const Spacing: SpacingType = {
  xs: 4,    // 瓒呭皬闂磋窛
  sm: 8,    // 灏忛棿璺?  md: 12,   // 涓瓑闂磋窛
  lg: 16,   // 澶ч棿璺?  xl: 20,   // 瓒呭ぇ闂磋窛
  xxl: 24,  // 鐗瑰ぇ闂磋窛
  xxxl: 32  // 宸ㄥぇ闂磋窛
};

// ==================== 灏哄绯荤粺 (Size System) ====================
export const Size: SizeType = {
  // 鍥炬爣灏哄
  iconXS: 16,
  iconSM: 20,
  iconMD: 24,
  iconLG: 28,
  iconXL: 32,
  iconXXL: 40,

  // 澶村儚灏哄
  avatarSM: 32,
  avatarMD: 40,
  avatarLG: 48,
  avatarXL: 56,

  // 鎸夐挳楂樺害
  buttonSM: 36,
  buttonMD: 44,
  buttonLG: 48,
  buttonXL: 56,

  // 杈撳叆妗嗛珮搴?  inputSM: 36,
  inputMD: 40,
  inputLG: 48,

  // 鍗＄墖鏈€灏忛珮搴?  cardSM: 80,
  cardMD: 120,
  cardLG: 160
};

// ==================== 鍦嗚绯荤粺 (Border Radius System) ====================
export const BorderRadius: BorderRadiusType = {
  none: 0,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  full: 999  // 瀹屽叏鍦嗗舰
};

// ==================== 闃村奖绯荤粺 (Shadow System) ====================
export const Shadow: ShadowType = {
  // 杞诲井闃村奖
  sm: {
    radius: 4,
    color: 'rgba(0,0,0,0.08)',
    offsetX: 0,
    offsetY: 2
  },
  // 涓瓑闃村奖
  md: {
    radius: 8,
    color: 'rgba(0,0,0,0.12)',
    offsetX: 0,
    offsetY: 4
  },
  // 娣卞害闃村奖
  lg: {
    radius: 12,
    color: 'rgba(0,0,0,0.16)',
    offsetX: 0,
    offsetY: 6
  },
  // 鎮诞闃村奖
  xl: {
    radius: 16,
    color: 'rgba(0,0,0,0.2)',
    offsetX: 0,
    offsetY: 8
  }
};

// 娣辫壊妯″紡闃村奖
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

// ==================== 鏂偣绯荤粺 (Breakpoint System) ====================
export const Breakpoints: BreakpointsType = {
  xs: 0,      // 瓒呭皬灞忓箷
  sm: 320,    // 灏忓睆骞曪紙鎵嬫満绔栧睆锛?  md: 600,    // 涓瓑灞忓箷锛堟姌鍙犲睆/澶ф墜鏈猴級
  lg: 840,    // 澶у睆骞曪紙骞虫澘绔栧睆锛?  xl: 1200,   // 瓒呭ぇ灞忓箷锛堝钩鏉挎í灞?妗岄潰锛?  xxl: 1600   // 鐗瑰ぇ灞忓箷锛堝ぇ灞忔闈級
};

// ==================== 缃戞牸绯荤粺 (Grid System) ====================
export const Grid: GridType = {
  columns: 12,  // 鎬诲垪鏁?  gutter: {
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24
  }
};

// ==================== Z-Index 灞傜骇绯荤粺 ====================
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

// ==================== 鍔ㄧ敾鏃堕暱绯荤粺 ====================
export const AnimationDuration: AnimationDurationType = {
  fast: 150,
  normal: 200,
  slow: 300,
  slower: 400
};

// ==================== 閫忔槑搴︾郴缁?====================
export const Opacity: OpacityType = {
  disabled: 0.4,
  secondary: 0.6,
  hover: 0.8,
  full: 1.0
};

/**
 * 鑾峰彇鍝嶅簲寮忛棿璺? * @param breakpoint 褰撳墠鏂偣
 * @returns 鍚堥€傜殑闂磋窛鍊? */
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
 * 鑾峰彇鍝嶅簲寮忕綉鏍煎垪鏁? * @param screenWidth 灞忓箷瀹藉害
 * @returns 缃戞牸鍒楁暟
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
 * 鑾峰彇闃村奖閰嶇疆
 * @param level 闃村奖绾у埆
 * @param isDarkMode 鏄惁娣辫壊妯″紡
 * @returns 闃村奖閰嶇疆瀵硅薄
 */
export function getShadow(level: 'sm' | 'md' | 'lg' | 'xl', isDarkMode: boolean = false) {
  return isDarkMode ? ShadowDark[level] : Shadow[level];
}
