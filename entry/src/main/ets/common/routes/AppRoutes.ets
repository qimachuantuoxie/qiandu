/**
 * 应用路由常量统一管理
 * 所有页面路由URL集中定义,避免硬编码
 */

export const AppRoutes = {
  // 主页
  LOGIN: 'pages/LoginPage',
  MAIN: 'pages/MainPage',
  FEATURES: 'pages/FeaturesPage',

  // 书架
  BOOK_DETAIL: 'pages/BookDetailPage',
  BOOK_SOURCE_MANAGE: 'pages/BookSourceManagePage',
  FOLDER_SCANNER: 'pages/FolderScannerPage',
  BOOKMARKS: 'pages/BookmarksPage',

  // 阅读器
  ENHANCED_READER: 'pages/EnhancedReaderPage',
  COMIC_READER: 'pages/ComicReaderPage',
  READER_SETTINGS: 'pages/ReaderSettingsPage',
  READ_RECORD: 'pages/ReadRecordPage',
  NOTES: 'pages/NotesPage',
  DICTIONARY: 'pages/DictionaryPage',
  WORD_BOOK: 'pages/WordBookPage',

  // 发现
  ONLINE_SEARCH: 'pages/OnlineSearchPage',
  ONLINE_BOOK_DETAIL: 'pages/OnlineBookDetailPage',
  ONLINE_SOURCE_MARKET: 'pages/OnlineSourceMarketPage',
  SOURCE_MARKET: 'pages/SourceMarketPage',

  // 个人中心
  PROFILE: 'pages/ProfilePage',
  READING_STATS: 'pages/ReadingStatsPage',
  STATISTICS: 'pages/StatisticsPage',

  // 设置
  SETTINGS: 'pages/SettingsPage',
  PRIVACY_POLICY: 'pages/PrivacyPolicyPage',
  USER_AGREEMENT: 'pages/UserAgreementPage',
  FEEDBACK: 'pages/FeedbackPage',
  HELP: 'pages/HelpPage',
  REWARD: 'pages/RewardPage',
  SKILL: 'pages/SkillPage',

  // 待办
  TODO: 'pages/TodoPage'
} as const;

export type AppRouteType = typeof AppRoutes[keyof typeof AppRoutes];

/**
 * 路由参数辅助函数
 */
export class RouteHelper {
  /**
   * 书籍详情页路由参数
   */
  static bookDetailParams(bookId: string): Record<string, string> {
    return { bookId: bookId };
  }

  /**
   * 阅读器路由参数
   */
  static readerParams(bookId: string, chapterIndex?: number): Record<string, string | number> {
    const idx = chapterIndex !== undefined ? chapterIndex : 0;
    return {
      bookId: bookId,
      chapterIndex: idx
    };
  }

  /**
   * 在线书籍详情路由参数
   */
  static onlineBookDetailParams(bookUrl: string, sourceId: string, bookName: string): Record<string, string> {
    return { bookUrl: bookUrl, sourceId: sourceId, bookName: bookName };
  }
}
