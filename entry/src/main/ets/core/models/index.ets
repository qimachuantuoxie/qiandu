/**
 * 数据模型统一导出
 * V3 架构 - 数据模型层
 */

// 核心书籍模型
export {
  BookInfo,
  BookFormat,
  ReadStatus,
  Bookmark,
  Note,
  ReadRecord,
  BooksMap,
  BookmarksMap,
  NotesMap,
  GroupsMap,
  BookshelfGroup,
  generateBookId
} from './CoreBookModel';

// 在线书籍模型
export {
  OnlineBook,
  OnlineSearchResult,
  OnlineSource,
  BookSourceConfig
} from './OnlineBookModel';

// 阅读统计模型
export {
  ReadingStatistics,
  ReadingAchievement,
  Badge
} from './reading/ReadingStats';

export {
  AdvancedReadingStatistics,
  ReadingInsight
} from './reading/AdvancedReading';

// 认证模型
export * from './auth';

// 书籍相关
export * from './book';

// 来源相关
export * from './source';

// Todo 模型
export * from './todo';

// Ebook 类型
export { EbookType, EbookMetadata } from './EbookTypes';
