/**
 * ViewModels 统一导出
 * V3 架构 - ViewModel 兼容层
 * 
 * 注意: 此文件为向后兼容保留,新代码应直接从 features 模块导入
 */

// ==================== 核心ViewModel (仍在core中) ====================
export { bookViewModel, BookViewModel } from './BookViewModel';

// ==================== 首页模块 ====================
export { mainPageViewModel, MainPageViewModel } from '../../features/home/viewmodels/MainPageViewModel';

// ==================== 书架模块 ====================
export { bookDetailViewModel, BookDetailViewModel } from '../../features/bookshelf/viewmodels/BookDetailViewModel';
export { bookmarksViewModel, BookmarksViewModel } from '../../features/bookshelf/viewmodels/BookmarksViewModel';
export { notesViewModel, NotesViewModel } from '../../features/bookshelf/viewmodels/NotesViewModel';

// ==================== 阅读器模块 ====================
export { readerViewModel, ReaderViewModel } from '../../features/reader/viewmodels/ReaderViewModel';
export { enhancedReaderViewModel, EnhancedReaderViewModel } from '../../features/reader/viewmodels/EnhancedReaderViewModel';
export { comicReaderViewModel, ComicReaderViewModel } from '../../features/reader/viewmodels/ComicReaderViewModel';
export { readerSettingsViewModel, ReaderSettingsViewModel } from '../../features/reader/viewmodels/ReaderSettingsViewModel';

// ==================== 设置模块 ====================
export { settingsViewModel, SettingsViewModel } from '../../features/settings/viewmodels/SettingsViewModel';
export { settingsPageViewModel, SettingsPageViewModel } from '../../features/settings/viewmodels/SettingsPageViewModel';
export { helpViewModel, HelpViewModel } from '../../features/settings/viewmodels/HelpViewModel';
export { feedbackViewModel, FeedbackViewModel } from '../../features/settings/viewmodels/FeedbackViewModel';
export { rewardViewModel, RewardViewModel } from '../../features/settings/viewmodels/RewardViewModel';
export { skillViewModel, SkillViewModel } from '../../features/settings/viewmodels/SkillViewModel';

// ==================== 个人中心模块 ====================
export { profileViewModel, ProfileViewModel } from '../../features/profile/viewmodels/ProfileViewModel';
export { profilePageViewModel, ProfilePageViewModel } from '../../features/profile/viewmodels/ProfilePageViewModel';
export { loginViewModel, LoginViewModel } from '../../features/profile/viewmodels/LoginViewModel';

// ==================== 发现模块 ====================
export { todoViewModel, TodoViewModel } from '../../features/discover/viewmodels/TodoViewModel';
export { featuresViewModel, FeaturesViewModel } from '../../features/discover/viewmodels/FeaturesViewModel';
export { statisticsViewModel, StatisticsViewModel } from '../../features/discover/viewmodels/StatisticsViewModel';
export { readingStatsViewModel, ReadingStatsViewModel } from '../../features/discover/viewmodels/ReadingStatsViewModel';
export { readRecordViewModel, ReadRecordViewModel } from '../../features/discover/viewmodels/ReadRecordViewModel';
export { wordBookViewModel, WordBookViewModel } from '../../features/discover/viewmodels/WordBookViewModel';

// ==================== 在线书城模块 ====================
export { onlineBookDetailViewModel, OnlineBookDetailViewModel } from '../../features/online-books/viewmodels/OnlineBookDetailViewModel';
export { onlineSearchViewModel, OnlineSearchViewModel } from '../../features/online-books/viewmodels/OnlineSearchViewModel';
export { onlineSourceMarketViewModel, OnlineSourceMarketViewModel } from '../../features/online-books/viewmodels/OnlineSourceMarketViewModel';

// ==================== 书源市场模块 ====================
export { sourceMarketViewModel, SourceMarketViewModel } from '../../features/source-market/viewmodels/SourceMarketViewModel';
export { bookSourceViewModel, BookSourceViewModel } from '../../features/source-market/viewmodels/BookSourceViewModel';
export { bookSourceManageViewModel, BookSourceManageViewModel } from '../../features/source-market/viewmodels/BookSourceManageViewModel';

// ==================== 工具模块 ====================
export { folderScannerViewModel, FolderScannerViewModel } from '../../features/tools/viewmodels/FolderScannerViewModel';
export { dictionaryViewModel, DictionaryViewModel } from '../../features/tools/viewmodels/DictionaryViewModel';
