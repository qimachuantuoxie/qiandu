// Core Source Model - Central export hub for all source-related types
export {
  BookSource,
  BookSourceType,
  SearchRule,
  BookInfoRule,
  ContentRule,
  TocRule,
  SearchResult,

  ChapterContent,
  ChapterInfo,
  ReplaceRule,
  ReplaceScope,
  DEFAULT_BOOK_SOURCES,
  DEFAULT_REPLACE_RULES,
  generateSourceId,
  validateBookSource,
  ImportResult
} from '../core/models/source/BookSourceModel';