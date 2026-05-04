// 设计令牌 - 颜色定义
// 统一管理应用中的所有颜色，移除硬编码

import { BookFormat } from '../models/CoreBookModel';

// ==================== 书籍格式颜色 ====================

export const BOOK_FORMAT_COLORS: Record<BookFormat, string> = {
  [BookFormat.PDF]: '#FF5722',
  [BookFormat.EPUB]: '#2196F3',
  [BookFormat.MOBI]: '#FF9800',
  [BookFormat.TXT]: '#4CAF50',
  [BookFormat.DOCX]: '#3F51B5',
  [BookFormat.DOC]: '#795548',
  [BookFormat.RTF]: '#607D8B',
  [BookFormat.HTML]: '#FFC107',
  [BookFormat.ODT]: '#009688',
  [BookFormat.FB2]: '#3F51B5',
  [BookFormat.AZW3]: '#FF5722',
  [BookFormat.AZW]: '#FF9800',
  [BookFormat.CBR]: '#E91E63',
  [BookFormat.CBZ]: '#9C27B0',
  [BookFormat.DJVU]: '#607D8B',
  [BookFormat.CHM]: '#4CAF50'
};

// 默认颜色（未知格式）
export const DEFAULT_FORMAT_COLOR = '#999999';

// ==================== 主题颜色 ====================

export const LIGHT_THEME_COLORS = {
  primary: '#2196F3',
  primaryVariant: '#1976D2',
  secondary: '#03DAC6',
  secondaryVariant: '#018786',
  background: '#FFFFFF',
  surface: '#F5F5F5',
  surfaceVariant: '#E0E0E0',
  onPrimary: '#FFFFFF',
  onSecondary: '#000000',
  onBackground: '#000000',
  onSurface: '#000000',
  onSurfaceVariant: '#666666',
  error: '#B00020',
  errorRed: '#FF0000'
};

export const DARK_THEME_COLORS = {
  primary: '#2196F3',
  primaryVariant: '#1976D2',
  secondary: '#03DAC6',
  secondaryVariant: '#018786',
  background: '#141414',
  surface: '#1E1E1E',
  surfaceVariant: '#2E2E2E',
  onPrimary: '#FFFFFF',
  onSecondary: '#000000',
  onBackground: '#FFFFFF',
  onSurface: '#FFFFFF',
  onSurfaceVariant: '#AAAAAA',
  error: '#CF6679',
  errorRed: '#FF5252'
};

// ==================== 通用颜色 ====================

export const COMMON_COLORS = {
  white: '#FFFFFF',
  black: '#000000',
  gray: '#999999',
  lightGray: '#E0E0E0',
  darkGray: '#666666',
  transparent: '#00000000',
  semiTransparent: '#00000080'
};

// ==================== 阅读器颜色 ====================

export const READER_COLORS = {
  paperWhite: '#F5F5DC',
  paperCream: '#FFFBF0',
  darkBackground: '#1A1A1A',
  darkSurface: '#2D2D2D'
};

// ==================== 获取格式颜色（工具函数）====================

export function getBookFormatColor(format: BookFormat): string {
  return BOOK_FORMAT_COLORS[format] || DEFAULT_FORMAT_COLOR;
}

// ==================== 背景颜色选项 ====================

export const BACKGROUND_COLOR_OPTIONS = [
  '#FFFFFF', // 纯白
  '#F5F5DC', // 羊皮纸
  '#E8F5E9', // 淡绿
  '#2C2C2E', // 深灰
  '#1A1A1A'  // 纯黑
];

export const BACKGROUND_COLOR_NAMES = [
  '纯白',
  '羊皮纸',
  '淡绿',
  '深灰',
  '纯黑'
];

// ==================== 字体选项 ====================

export const VOICE_OPTIONS = [
  '标准',
  '沉稳',
  '清脆',
  '浑厚',
  '温和'
];
