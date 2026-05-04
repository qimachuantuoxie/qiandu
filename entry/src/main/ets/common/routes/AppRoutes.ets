/**
 * 搴旂敤璺敱甯搁噺缁熶竴绠＄悊
 * 鎵€鏈夐〉闈㈣矾鐢盪RL闆嗕腑瀹氫箟,閬垮厤纭紪鐮?
 */

export const AppRoutes = {
  // 涓婚〉
  LOGIN: 'pages/LoginPage',
  MAIN: 'pages/MainPage',
  FEATURES: 'pages/FeaturesPage',

  // 涔︽灦
  BOOK_DETAIL: 'pages/BookDetailPage',
  BOOK_SOURCE_MANAGE: 'pages/BookSourceManagePage',
  FOLDER_SCANNER: 'pages/FolderScannerPage',
  BOOKMARKS: 'pages/BookmarksPage',

  // 闃呰鍣?
  ENHANCED_READER: 'pages/EnhancedReaderPage',
  COMIC_READER: 'pages/ComicReaderPage',
  READER_SETTINGS: 'pages/ReaderSettingsPage',
  READ_RECORD: 'pages/ReadRecordPage',
  NOTES: 'pages/NotesPage',
  DICTIONARY: 'pages/DictionaryPage',
  WORD_BOOK: 'pages/WordBookPage',

  // 鍙戠幇
  ONLINE_SEARCH: 'pages/OnlineSearchPage',
  ONLINE_BOOK_DETAIL: 'pages/OnlineBookDetailPage',
  ONLINE_SOURCE_MARKET: 'pages/OnlineSourceMarketPage',
  SOURCE_MARKET: 'pages/SourceMarketPage',

  // 涓汉涓績
  PROFILE: 'pages/ProfilePage',
  READING_STATS: 'pages/ReadingStatsPage',
  STATISTICS: 'pages/StatisticsPage',

  // 璁剧疆
  SETTINGS: 'pages/SettingsPage',
  PRIVACY_POLICY: 'pages/PrivacyPolicyPage',
  USER_AGREEMENT: 'pages/UserAgreementPage',
  FEEDBACK: 'pages/FeedbackPage',
  HELP: 'pages/HelpPage',
  REWARD: 'pages/RewardPage',
  SKILL: 'pages/SkillPage',

  // 寰呭姙
  TODO: 'pages/TodoPage'
} as const;

export type AppRouteType = typeof AppRoutes[keyof typeof AppRoutes];

/**
 * 璺敱鍙傛暟杈呭姪鍑芥暟
 */
export class RouteHelper {
  /**
   * 涔︾睄璇︽儏椤佃矾鐢卞弬鏁?
   */
  static bookDetailParams(bookId: string): Record<string, string> {
    return { bookId: bookId };
  }

  /**
   * 闃呰鍣ㄨ矾鐢卞弬鏁?
   */
  static readerParams(bookId: string, chapterIndex?: number): Record<string, string | number> {
    const idx = chapterIndex !== undefined ? chapterIndex : 0;
    return {
      bookId: bookId,
      chapterIndex: idx
    };
  }

  /**
   * 鍦ㄧ嚎涔︾睄璇︽儏璺敱鍙傛暟
   */
  static onlineBookDetailParams(bookUrl: string, sourceId: string, bookName: string): Record<string, string> {
    return { bookUrl: bookUrl, sourceId: sourceId, bookName: bookName };
  }
}
