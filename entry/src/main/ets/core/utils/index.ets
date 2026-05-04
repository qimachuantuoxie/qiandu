/**
 * 核心工具函数统一导出
 * V3 架构 - 工具层 */

// 偏好管理
export { preferenceManager } from '../stores/PreferenceManager';
export { BasePreferenceManager } from './BasePreferenceManager';
export { DebouncedPreferenceWriter } from './DebouncedPreferenceWriter';

// 存储
export { SecureStorage, secureStorage } from './SecureStorage';

// 设备相关
export { DeviceUtils } from './DeviceUtils';
export { DisplayHelper } from './DisplayHelper';
export { responsiveLayoutUtil } from './ResponsiveLayoutUtil';
export { FoldableAdapterManager } from './FoldableAdapterManager';

// 国际化
export { localizationUtil, tr } from './LocalizationUtil';

// 设计系统
export { DesignSystem, designSystem } from './DesignSystem';
export { HarmonyDesignTokens, IHarmonyColors, HarmonyColors, LightColors, DarkColors, getColors, SpacingTokens, FontSizeTokens, IDarkModeColors, getDarkModeColors, IClassCardStyle, createClassCardStyle } from './HarmonyDesignTokens';
export { PageStyles } from './PageStyles';

// 解析器
export { EbookParser, ParseResult } from './EbookParser';
export { BookContentParser } from './BookContentParser';

// 辅助工具
export { AsyncHelper } from './AsyncHelper';
export { ErrorHandler } from './ErrorHandler';
export { HttpHelper } from './HttpHelper';
export { LayoutHelper } from './LayoutHelper';
export { LazyDataSource } from './LazyDataSource';
export { NativeModules } from './NativeModules';
export { ReadingSettingsManager } from './ReadingSettingsManager';
export { FontScaleManager } from './FontScaleManager';
export { Utils } from './Utils';
export { ZipUtils } from './ZipUtils';

// 账户
export { AccountManager, accountManager } from './AccountManager';
