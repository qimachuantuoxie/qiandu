/**
 * 核心模块统一导出
 * Core Module Export
 */

// 偏好管理
export { preferenceManager } from './stores/PreferenceManager';

// 数据模型
export * from './models';

// 解析器
export * from './parsers';

// 阅读器
export * from './reader';

// 服务
export * from './services';

// 状态管理
export * from './stores';

// 管理器
export * from './managers';

// 工具函数
export * from './utils';

// 设计系统
export { DesignSystem, designSystem } from './utils/DesignSystem';
export { LIGHT_THEME, DARK_THEME, ThemeColors } from './services/reader/UIDesignKitService';
export {
  IHarmonyColors,
  HarmonyColors,
  LightColors,
  DarkColors,
  getColors,
  SpacingTokens,
  FontSizeTokens,
  IDarkModeColors,
  getDarkModeColors,
  IClassCardStyle,
  createClassCardStyle
} from './utils/HarmonyDesignTokens';
