/**
 * 路由路径常量
 * V3 架构 - 统一管理所有页面路由
 */

export const ROUTES = {
  // ==================== 首页模块 ====================
  HOME: 'pages/MainPage',
  
  // ==================== 书架模块 ====================
  BOOK_DETAIL: 'features/bookshelf/pages/BookDetailPage',
  BOOKMARKS: 'features/bookshelf/pages/BookmarksPage',
  NOTES: 'features/bookshelf/pages/NotesPage',
  
  // ==================== 阅读器模块 ====================
  READER: 'features/reader/pages/EnhancedReaderPage',
  COMIC_READER: 'features/reader/pages/ComicReaderPage',
  READER_SETTINGS: 'features/reader/pages/ReaderSettingsPage',
  DICTIONARY: 'features/reader/pages/DictionaryPage',
  WORD_BOOK: 'features/reader/pages/WordBookPage',
  
  // ==================== 发现模块 ====================
  TODO: 'features/discover/pages/TodoPage',
  FEATURES: 'features/discover/pages/FeaturesPage',
  STATISTICS: 'features/discover/pages/StatisticsPage',
  READING_STATS: 'features/settings/pages/ReadingStatsPage',
  READ_RECORD: 'features/discover/pages/ReadRecordPage',
  
  // ==================== 设置模块 ====================
  SETTINGS: 'features/settings/pages/SettingsPage',
  HELP: 'features/profile/pages/HelpPage',
  FEEDBACK: 'features/profile/pages/FeedbackPage',
  REWARD: 'features/profile/pages/RewardPage',
  SKILL: 'features/profile/pages/SkillPage',
  
  // ==================== 个人中心模块 ====================
  PROFILE: 'features/profile/pages/ProfilePage',
  LOGIN: 'features/profile/pages/LoginPage',
  EYE_TRACKING_CALIBRATION: 'features/profile/pages/EyeTrackingCalibrationPage',
  
  // ==================== 在线书城模块 ====================
  ONLINE_SEARCH: 'features/online-books/pages/OnlineSearchPage',
  ONLINE_BOOK_DETAIL: 'features/online-books/pages/OnlineBookDetailPage',
  ONLINE_SOURCE_MARKET: 'features/online-books/pages/OnlineSourceMarketPage',
  FOLDER_SCANNER: 'features/online-books/pages/FolderScannerPage',
  
  // ==================== 书源市场模块 ====================
  SOURCE_MARKET: 'features/source-market/pages/SourceMarketPage',
  BOOK_SOURCE_MANAGE: 'features/source-market/pages/BookSourceManagePage',
} as const;

export type RouteKey = keyof typeof ROUTES;
export type RoutePath = typeof ROUTES[RouteKey];

/**
 * 获取路由路径
 * @param key 路由键
 * @returns 路由路径
 */
export function getRoute(key: RouteKey): RoutePath {
  return ROUTES[key];
}
