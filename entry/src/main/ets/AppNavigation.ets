// 应用根导航组件 - 完整版
// 使用 Navigation + NavPathStack 官方架构

import { NavPathStack, NavDestination } from '@kit.ArkUI';
import { navHelper } from './utils/NavigationHelper';

// 导入所有页面组件
import { LoginPage } from './features/profile/pages/LoginPage';
import { MainPage } from './features/home/pages/MainPage';
import { ProfilePage } from './features/profile/pages/ProfilePage';
import { BookDetailPage } from './features/bookshelf/pages/BookDetailPage';
import { EnhancedReaderPage } from './features/reader/pages/EnhancedReaderPage';
import { ComicReaderPage } from './features/reader/pages/ComicReaderPage';
import { ReaderSettingsPage } from './features/reader/pages/ReaderSettingsPage';
import { ReadRecordPage } from './features/settings/pages/ReadRecordPage';
import { BookSourceManagePage } from './features/source-market/pages/BookSourceManagePage';
import { OnlineSourceMarketPage } from './features/source-market/pages/OnlineSourceMarketPage';
import { OnlineSearchPage } from './features/online-books/pages/OnlineSearchPage';
import { OnlineBookDetailPage } from './features/online-books/pages/OnlineBookDetailPage';
import { SourceMarketPage } from './features/source-market/pages/SourceMarketPage';
import { FolderScannerPage } from './features/online-books/pages/FolderScannerPage';
import { ReadingStatsPage } from './features/settings/pages/ReadingStatsPage';
import { StatisticsPage } from './features/settings/pages/StatisticsPage';
import { SettingsPage } from './features/settings/pages/SettingsPage';
import { PrivacyPolicyPage } from './features/profile/pages/PrivacyPolicyPage';
import { UserAgreementPage } from './features/profile/pages/UserAgreementPage';
import { FeaturesPage } from './features/home/pages/FeaturesPage';
import { BookmarksPage } from './features/bookshelf/pages/BookmarksPage';
import { NotesPage } from './features/bookshelf/pages/NotesPage';
import { FeedbackPage } from './features/profile/pages/FeedbackPage';
import { HelpPage } from './features/profile/pages/HelpPage';
import { DictionaryPage } from './features/reader/pages/DictionaryPage';
import { WordBookPage } from './features/reader/pages/WordBookPage';
import { RewardPage } from './features/profile/pages/RewardPage';
import { SkillPage } from './features/profile/pages/SkillPage';
import { TodoPage } from './features/profile/pages/TodoPage';
import { EyeTrackingCalibrationPage } from './features/profile/pages/EyeTrackingCalibrationPage';

@Entry
@Component
struct AppNavigation {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    navHelper.setNavPathStack(this.navPathStack);
  }

  build() {
    Navigation(this.navPathStack) {
      // 初始页面由 onAppear 中的 pushPath 决定
    }
    .title('千读阅界')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .navDestination((name: string, param: Object) => {
      // 根据路由名称动态返回对应页面
      return this.buildPageDestination(name);
    })
    .onAppear(() => {
      // 初始导航到 LoginPage
      this.navPathStack.pushPath({ name: 'LoginPage' });
    })
  }

  @Builder
  buildPageDestination(name: string): NavDestination {
    // 登录页
    if (name === 'LoginPage' || name === 'pages/LoginPage') {
      return NavDestination() {
        LoginPage()
      }
      .title('登录')
    }

    // 主页
    if (name === 'MainPage' || name === 'pages/MainPage') {
      return NavDestination() {
        MainPage()
      }
      .title('主页')
    }

    // 个人中心
    if (name === 'ProfilePage' || name === 'pages/ProfilePage') {
      return NavDestination() {
        ProfilePage()
      }
      .title('个人中心')
    }

    // 书籍详情
    if (name === 'BookDetailPage' || name === 'pages/BookDetailPage') {
      return NavDestination() {
        BookDetailPage()
      }
      .title('书籍详情')
    }

    // 阅读器
    if (name === 'EnhancedReaderPage' || name === 'pages/EnhancedReaderPage') {
      return NavDestination() {
        EnhancedReaderPage()
      }
      .title('阅读器')
    }

    // 漫画阅读
    if (name === 'ComicReaderPage' || name === 'pages/ComicReaderPage') {
      return NavDestination() {
        ComicReaderPage()
      }
      .title('漫画阅读')
    }

    // 阅读设置
    if (name === 'ReaderSettingsPage' || name === 'pages/ReaderSettingsPage') {
      return NavDestination() {
        ReaderSettingsPage()
      }
      .title('阅读设置')
    }

    // 阅读记录
    if (name === 'ReadRecordPage' || name === 'pages/ReadRecordPage') {
      return NavDestination() {
        ReadRecordPage()
      }
      .title('阅读记录')
    }

    // 书源管理
    if (name === 'BookSourceManagePage' || name === 'pages/BookSourceManagePage') {
      return NavDestination() {
        BookSourceManagePage()
      }
      .title('书源管理')
    }

    // 在线书源市场
    if (name === 'OnlineSourceMarketPage' || name === 'pages/OnlineSourceMarketPage') {
      return NavDestination() {
        OnlineSourceMarketPage()
      }
      .title('在线书源')
    }

    // 在线搜索
    if (name === 'OnlineSearchPage' || name === 'pages/OnlineSearchPage') {
      return NavDestination() {
        OnlineSearchPage()
      }
      .title('搜索')
    }

    // 在线书籍详情
    if (name === 'OnlineBookDetailPage' || name === 'pages/OnlineBookDetailPage') {
      return NavDestination() {
        OnlineBookDetailPage()
      }
      .title('书籍详情')
    }

    // 书源市场
    if (name === 'SourceMarketPage' || name === 'pages/SourceMarketPage') {
      return NavDestination() {
        SourceMarketPage()
      }
      .title('书源市场')
    }

    // 文件夹扫描
    if (name === 'FolderScannerPage' || name === 'pages/FolderScannerPage') {
      return NavDestination() {
        FolderScannerPage()
      }
      .title('文件夹扫描')
    }

    // 阅读统计
    if (name === 'ReadingStatsPage' || name === 'pages/ReadingStatsPage') {
      return NavDestination() {
        ReadingStatsPage()
      }
      .title('阅读统计')
    }

    // 统计页面
    if (name === 'StatisticsPage' || name === 'pages/StatisticsPage') {
      return NavDestination() {
        StatisticsPage()
      }
      .title('统计')
    }

    // 设置
    if (name === 'SettingsPage' || name === 'pages/SettingsPage') {
      return NavDestination() {
        SettingsPage()
      }
      .title('设置')
    }

    // 隐私政策
    if (name === 'PrivacyPolicyPage' || name === 'pages/PrivacyPolicyPage') {
      return NavDestination() {
        PrivacyPolicyPage()
      }
      .title('隐私政策')
    }

    // 用户协议
    if (name === 'UserAgreementPage' || name === 'pages/UserAgreementPage') {
      return NavDestination() {
        UserAgreementPage()
      }
      .title('用户协议')
    }

    // 功能页面
    if (name === 'FeaturesPage' || name === 'pages/FeaturesPage') {
      return NavDestination() {
        FeaturesPage()
      }
      .title('功能')
    }

    // 书签
    if (name === 'BookmarksPage' || name === 'pages/BookmarksPage') {
      return NavDestination() {
        BookmarksPage()
      }
      .title('书签')
    }

    // 笔记
    if (name === 'NotesPage' || name === 'pages/NotesPage') {
      return NavDestination() {
        NotesPage()
      }
      .title('笔记')
    }

    // 反馈
    if (name === 'FeedbackPage' || name === 'pages/FeedbackPage') {
      return NavDestination() {
        FeedbackPage()
      }
      .title('反馈')
    }

    // 帮助
    if (name === 'HelpPage' || name === 'pages/HelpPage') {
      return NavDestination() {
        HelpPage()
      }
      .title('帮助')
    }

    // 词典
    if (name === 'DictionaryPage' || name === 'pages/DictionaryPage') {
      return NavDestination() {
        DictionaryPage()
      }
      .title('词典')
    }

    // 单词本
    if (name === 'WordBookPage' || name === 'pages/WordBookPage') {
      return NavDestination() {
        WordBookPage()
      }
      .title('单词本')
    }

    // 打赏
    if (name === 'RewardPage' || name === 'pages/RewardPage') {
      return NavDestination() {
        RewardPage()
      }
      .title('打赏')
    }

    // 技能
    if (name === 'SkillPage' || name === 'pages/SkillPage') {
      return NavDestination() {
        SkillPage()
      }
      .title('技能')
    }

    // 待办
    if (name === 'TodoPage' || name === 'pages/TodoPage') {
      return NavDestination() {
        TodoPage()
      }
      .title('待办')
    }

    // 眼动校准
    if (name === 'EyeTrackingCalibrationPage' || name === 'pages/EyeTrackingCalibrationPage') {
      return NavDestination() {
        EyeTrackingCalibrationPage()
      }
      .title('眼动校准')
    }

    // 未知页面
    return NavDestination() {
      Column() {
        Text('未知页面: ' + name)
          .fontSize(16)
          .fontColor('#FF0000')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('未知')
  }
}

// 导出 Builder 供 EntryAbility 使用
@Builder
export function AppNavigationBuilder(): void {
  AppNavigation()
}
