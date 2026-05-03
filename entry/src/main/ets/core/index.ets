/**
 * 核心模块统一导出
 * Core Module Export
 */

// 偏好管理
export { preferenceManager } from '../utils/PreferenceManager';

// 全局状态
export { UserState, ThemeState, initAppStore } from '../store/AppStore';

// 管理器
export { DeviceUtils } from '../utils/DeviceUtils';
export { I18nManager, i18n, tr, SUPPORTED_LOCALES, LocaleInfo, LocaleCode } from '../utils/I18nManager';
export { AccountManager, accountManager } from '../utils/AccountManager';
export { SecureStorage, secureStorage } from '../utils/SecureStorage';
export { KitManager, kitManager } from '../services/huawei-kit/KitManager';

// 设计系统
export { DesignSystem, designSystem } from '../utils/DesignSystem';
export { LIGHT_THEME, DARK_THEME, ThemeColors } from '../services/reader/UIDesignKitService';
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
  IGlassCardStyle,
  createGlassCardStyle
} from '../utils/HarmonyDesignTokens';
