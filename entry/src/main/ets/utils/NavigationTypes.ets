// 路由参数类型定义 - 类型安全的导航
// 为所有页面定义强类型的参数接口

import { BookInfo, ReadStatus, BookshelfGroup } from '../models/CoreBookModel';
import { OnlineSearchResult } from '../models/OnlineBookModel';
import { OnlineBookDetail, OnlineChapterInfo } from '../models/OnlineBookModel';
import { Bookmark, Note } from '../models/CoreBookModel';
import { BookFormat } from '../models/CoreBookModel';

// ==================== 路由参数接口 ====================

export interface RouteParams {
  // 登录页（无参数）
  'LoginPage': Record<string, never>;
  
  // 主页（无参数）
  'MainPage': Record<string, never>;
  
  // 个人中心（无参数）
  'ProfilePage': Record<string, never>;
  
  // 书籍详情页
  'BookDetailPage': {
    bookId: string;
  };
  
  // 增强阅读器
  'EnhancedReaderPage': {
    bookId: string;
    chapterIndex?: string;
    title?: string;
    path?: string;
  };
  
  // 漫画阅读器
  'ComicReaderPage': {
    bookId?: string;
    bookPath?: string;
  };
  
  // 阅读设置
  'ReaderSettingsPage': Record<string, never>;
  
  // 阅读记录
  'ReadRecordPage': Record<string, never>;
  
  // 书源管理
  'BookSourceManagePage': Record<string, never>;
  
  // 在线书源市场
  'OnlineSourceMarketPage': Record<string, never>;
  
  // 在线搜索
  'OnlineSearchPage': Record<string, never>;
  
  // 在线书籍详情
  'OnlineBookDetailPage': {
    bookUrl: string;
    sourceId: string;
    bookName?: string;
  };
  
  // 书源市场
  'SourceMarketPage': Record<string, never>;
  
  // 文件夹扫描
  'FolderScannerPage': Record<string, never>;
  
  // 阅读统计
  'ReadingStatsPage': Record<string, never>;
  
  // 统计页面
  'StatisticsPage': Record<string, never>;
  
  // 设置页
  'SettingsPage': {
    isTablet?: boolean;
  };
  
  // 隐私政策
  'PrivacyPolicyPage': Record<string, never>;
  
  // 用户协议
  'UserAgreementPage': Record<string, never>;
  
  // 功能页面
  'FeaturesPage': Record<string, never>;
  
  // 书签页
  'BookmarksPage': Record<string, never>;
  
  // 笔记页
  'NotesPage': Record<string, never>;
  
  // 反馈页
  'FeedbackPage': Record<string, never>;
  
  // 帮助页
  'HelpPage': Record<string, never>;
  
  // 词典页
  'DictionaryPage': Record<string, never>;
  
  // 单词本
  'WordBookPage': Record<string, never>;
  
  // 打赏页
  'RewardPage': Record<string, never>;
  
  // 技能页
  'SkillPage': Record<string, never>;
  
  // 待办页
  'TodoPage': Record<string, never>;
  
  // 眼动校准
  'EyeTrackingCalibrationPage': Record<string, never>;
}

// ==================== NavigationHelper 扩展（泛型） ====================

import { navHelper } from './NavigationHelper';

export function navigateWithParams<T extends keyof RouteParams>(
  page: T,
  params: RouteParams[T]
): void {
  navHelper.pushPathByName(page, params);
}

export function getPageParams<T extends keyof RouteParams>(
  page: T
): RouteParams[T] | null {
  try {
    const stack = navHelper.getStack();
    if (stack) {
      const params = stack.getParamByName(page);
      if (params && params.length > 0) {
        return params[0] as RouteParams[T];
      }
    }
    return null;
  } catch {
    return null;
  }
}

// ==================== 类型守卫 ====================

export function isValidBookId(params: unknown): params is { bookId: string } {
  return typeof params === 'object' && params !== null && 'bookId' in params;
}

export function isValidOnlineBook(params: unknown): params is RouteParams['OnlineBookDetailPage'] {
  return typeof params === 'object' && params !== null && 'bookUrl' in params && 'sourceId' in params;
}
