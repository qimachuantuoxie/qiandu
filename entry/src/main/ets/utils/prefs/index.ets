/**
 * 偏好设置模块统一导出
 * 提供向后兼容的接口
 */

export { BasePrefs } from './BasePrefs';
export { BookPrefs, bookPrefs } from './BookPrefs';
export { UserPrefs, userPrefs } from './UserPrefs';
export { ReaderPrefs, readerPrefs, ReaderSettings, DEFAULT_READER_SETTINGS } from './ReaderPrefs';
export { ThemePrefs, themePrefs } from './ThemePrefs';
export { SourcePrefs, sourcePrefs } from './SourcePrefs';
export * as StorageKeys from './StorageKeys';
