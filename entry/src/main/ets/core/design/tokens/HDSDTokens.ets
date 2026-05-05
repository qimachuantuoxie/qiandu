/**
 * HDS Design Tokens - HarmonyOS Design System 设计规范
 * 
 * 基于华为官方设计规范的色彩、间距、圆角、阴影系统
 */

// ==================== 色彩系统 (Color System) ====================
export const HDSColours = {
  // 主色调 - Primary Colors
  primary: {
    blue: '#007DFF',        // 华为主蓝
    darkBlue: '#0056CC',
    lightBlue: '#3399FF'
  },
  
  // 功能色 - Functional Colors
  success: '#4CAF50',       // 成功绿
  warning: '#FF9800',       // 警告橙
  error: '#F44336',         // 错误红
  info: '#2196F3',          // 信息蓝
  
  // 中性色 - Neutral Colors (Light Mode)
  neutral: {
    white: '#FFFFFF',
    gray50: '#FAFAFA',
    gray100: '#F5F5F5',
    gray200: '#EEEEEE',
    gray300: '#E0E0E0',
    gray400: '#BDBDBD',
    gray500: '#9E9E9E',
    gray600: '#757575',
    gray700: '#616161',
    gray800: '#424242',
    gray900: '#212121',
    black: '#000000'
  },
  
  // 深色模式中性色 - Neutral Colors (Dark Mode)
  neutralDark: {
    bgPrimary: '#121212',
    bgSecondary: '#1E1E1E',
    bgTertiary: '#2C2C2C',
    surface: '#242424',
    textPrimary: '#FFFFFF',
    textSecondary: '#B3B3B3',
    textTertiary: '#808080',
    divider: '#333333'
  },
  
  // 渐变色 - Gradients
  gradients: {
    primary: ['#007DFF', '#0056CC'],
    success: ['#4CAF50', '#388E3C'],
    warning: ['#FF9800', '#F57C00'],
    error: ['#F44336', '#D32F2F']
  }
};

// ==================== 间距系统 (Spacing System) ====================
export const HDSSpacing = {
  xs: 4,      // 超小间距
  sm: 8,      // 小间距
  md: 12,     // 中间距
  lg: 16,     // 大间距
  xl: 24,     // 超大间距
  xxl: 32,    // 特大间距
  xxxl: 48    // 巨大间距
};

// ==================== 圆角系统 (Border Radius System) ====================
export const HDSBorderRadius = {
  none: 0,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  full: 9999  // 圆形
};

// ==================== 阴影系统 (Shadow System) ====================
export const HDSShadows = {
  // 浅色模式阴影
  light: {
    sm: {
      radius: 8,
      color: 'rgba(0, 0, 0, 0.08)',
      offsetX: 0,
      offsetY: 2
    },
    md: {
      radius: 12,
      color: 'rgba(0, 0, 0, 0.12)',
      offsetX: 0,
      offsetY: 4
    },
    lg: {
      radius: 16,
      color: 'rgba(0, 0, 0, 0.16)',
      offsetX: 0,
      offsetY: 8
    },
    xl: {
      radius: 24,
      color: 'rgba(0, 0, 0, 0.20)',
      offsetX: 0,
      offsetY: 12
    }
  },
  
  // 深色模式阴影（更淡）
  dark: {
    sm: {
      radius: 8,
      color: 'rgba(0, 0, 0, 0.2)',
      offsetX: 0,
      offsetY: 2
    },
    md: {
      radius: 12,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 4
    },
    lg: {
      radius: 16,
      color: 'rgba(0, 0, 0, 0.4)',
      offsetX: 0,
      offsetY: 8
    }
  }
};

// ==================== 字体系统 (Typography System) ====================
export const HDSTypography = {
  // 字号
  sizes: {
    xs: 12,
    sm: 14,
    md: 16,
    lg: 18,
    xl: 20,
    xxl: 24,
    xxxl: 32,
    display: 48
  },
  
  // 字重
  weights: {
    regular: 400,
    medium: 500,
    semibold: 600,
    bold: 700
  },
  
  // 行高
  lineHeights: {
    tight: 1.2,
    normal: 1.5,
    relaxed: 1.8
  }
};

// ==================== 动画时长 (Animation Durations) ====================
export const HDSAnimation = {
  fast: 150,      // 快速动画
  normal: 300,    // 正常动画
  slow: 500,      // 慢速动画
  slower: 800     // 更慢动画
};

// ==================== 断点系统 (Breakpoint System) ====================
export const HDSBreakpoints = {
  xs: 320,    // 超小屏（手机竖屏）
  sm: 480,    // 小屏（手机横屏）
  md: 768,    // 中屏（平板竖屏）
  lg: 1024,   // 大屏（平板横屏）
  xl: 1280,   // 超大屏
  xxl: 1920   // 巨屏
};

// ==================== Z-Index 层级 ====================
export const HDSZIndex = {
  dropdown: 1000,
  sticky: 1020,
  fixed: 1030,
  modalBackdrop: 1040,
  modal: 1050,
  popover: 1060,
  tooltip: 1070,
  toast: 1080
};
