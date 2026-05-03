/**
 * ProfilePage ViewModel - V2鐗堟湰
 * 
 * 绠＄悊涓汉涓績椤甸潰鎵€鏈夌姸鎬?
 */

import { loginStateManager, UserInfo } from '../services/auth/LoginStateManager';
import { preferenceManager } from '../utils/PreferenceManager';
import { bookViewModel } from './BookViewModel';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

interface ProfileMenuItem {
  icon: string;
  titleKey: string;
  subtitleKey?: string;
  action: () => void;
}

@ObservedV2
export class ProfileViewModel {
  // ==================== 涓婚鐘舵€?====================
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;

  // ==================== 鐢ㄦ埛鐘舵€?====================
  @Trace userInfo: UserInfo | null = null;
  @Trace isLoggedIn: boolean = false;

  // ==================== 闃呰缁熻 ====================
  @Trace totalBooks: number = 0;
  @Trace totalReadingTime: number = 0;
  @Trace totalBookmarks: number = 0;
  @Trace totalNotes: number = 0;

  /**
   * 鍔犺浇涓汉璧勬枡锛堢粺涓€鍏ュ彛锛?
   */
  async loadProfile(): Promise<void> {
    this.init();
  }

  /**
   * 鍒濆鍖?
   */
  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.loadUserInfo();
    this.loadReadingStats();

    appTheme.subscribe(() => {
      this.isDarkMode = appTheme.isDarkMode();
      this.currentColors = themeManager.getColors();
    });
  }

  /**
   * 鑾峰彇缂╂斁鍚庣殑瀛椾綋澶у皬
   */
  getFontSize(base: number): number {
    return fontScaleManager.getScaledFontSize(base);
  }

  /**
   * 鍔犺浇鐢ㄦ埛淇℃伅
   */
  loadUserInfo(): void {
    this.userInfo = loginStateManager.getCurrentUser();
    this.isLoggedIn = this.userInfo !== null;
  }

  /**
   * 鍔犺浇闃呰缁熻
   */
  loadReadingStats(): void {
    const allBooks = bookViewModel.getAllBooks();
    this.totalBooks = allBooks.length;
    let total = 0;
    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (book) {
        total += (book.totalReadTime ?? 0) > 0 ? (book.totalReadTime ?? 0) : 0;
      }
    }
    this.totalReadingTime = total;
    const bookmarks = bookViewModel.getAllBookmarks();
    const notes = bookViewModel.getAllNotes();
    this.totalBookmarks = bookmarks ? bookmarks.length : 0;
    this.totalNotes = notes ? notes.length : 0;
  }

  /**
   * 鍒锋柊鏁版嵁
   */
  refresh(): void {
    this.loadUserInfo();
    this.loadReadingStats();
  }

  /**
   * 鑾峰彇鑿滃崟椤?
   */
  getMenuItems(action: (item: ProfileMenuItem) => void): ProfileMenuItem[] {
    return [
      {
        icon: '馃摎',
        titleKey: 'myBooks',
        subtitleKey: this.totalBooks + ' ' + tr('books'),
        action: () => action({ icon: '馃摎', titleKey: 'myBooks', action: () => {} })
      },
      {
        icon: '鈴憋笍',
        titleKey: 'readingTime',
        subtitleKey: this.formatReadingTime(this.totalReadingTime),
        action: () => action({ icon: '鈴憋笍', titleKey: 'readingTime', action: () => {} })
      },
      {
        icon: '馃敄',
        titleKey: 'bookmarks',
        subtitleKey: this.totalBookmarks + ' ' + tr('items'),
        action: () => action({ icon: '馃敄', titleKey: 'bookmarks', action: () => {} })
      },
      {
        icon: '馃摑',
        titleKey: 'notes',
        subtitleKey: this.totalNotes + ' ' + tr('items'),
        action: () => action({ icon: '馃摑', titleKey: 'notes', action: () => {} })
      }
    ];
  }

  /**
   * 鏍煎紡鍖栭槄璇绘椂闂?
   */
  formatReadingTime(minutes: number): string {
    if (minutes < 60) {
      return minutes + ' ' + tr('minutes');
    }
    const hours = Math.floor(minutes / 60);
    return hours + ' ' + tr('hours');
  }
}

// 瀵煎嚭鍗曚緥
export const profileViewModel = new ProfileViewModel();
