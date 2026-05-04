/**
 * ProfilePage ViewModel - V2閻楀牊婀?
 * 
 * 缁狅紕鎮婃稉顏冩眽娑擃厼绺炬い鐢告桨閹碘偓閺堝濮搁幀?
 */

import { loginStateManager, UserInfo } from '../services/auth/LoginStateManager';
import { preferenceManager } from '../utils/PreferenceManager';
import { bookViewModel } from './BookViewModel';
import { appTheme, themeManager, AppColors } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { tr } from '../utils/LocalizationUtil';

interface ProfileMenuItem {
  icon: string;
  titleKey: string;
  subtitleKey?: string;
  action: () => void;
}

@ObservedV2
export class ProfileViewModel {
  // ==================== 娑撳顣介悩鑸碘偓?====================
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace fontScale: number = 1.0;

  // ==================== 閻劍鍩涢悩鑸碘偓?====================
  @Trace userInfo: UserInfo | null = null;
  @Trace isLoggedIn: boolean = false;

  // ==================== 闂冨懓顕扮紒鐔活吀 ====================
  @Trace totalBooks: number = 0;
  @Trace totalReadingTime: number = 0;
  @Trace totalBookmarks: number = 0;
  @Trace totalNotes: number = 0;

  /**
   * 閸旂姾娴囨稉顏冩眽鐠у嫭鏋￠敍鍫㈢埠娑撯偓閸忋儱褰涢敍?
   */
  async loadProfile(): Promise<void> {
    this.init();
  }

  /**
   * 閸掓繂顫愰崠?
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
   * 閼惧嘲褰囩紓鈺傛杹閸氬海娈戠€涙ぞ缍嬫径褍鐨?
   */
  getFontSize(base: number): number {
    return fontScaleManager.getScaledFontSize(base);
  }

  /**
   * 閸旂姾娴囬悽銊﹀煕娣団剝浼?
   */
  loadUserInfo(): void {
    this.userInfo = loginStateManager.getCurrentUser();
    this.isLoggedIn = this.userInfo !== null;
  }

  /**
   * 閸旂姾娴囬梼鍛邦嚢缂佺喕顓?
   */
  loadReadingStats(): void {
    const allBooks = bookViewModel.getAllBooks();
    this.totalBooks = allBooks.length;
    let total = 0;
    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (book) {
        total += (book.totalReadTime ? book.totalReadTime : 0) > 0 ? (book.totalReadTime ? book.totalReadTime : 0) : 0;
      }
    }
    this.totalReadingTime = total;
    const bookmarks = bookViewModel.getAllBookmarks();
    const notes = bookViewModel.getAllNotes();
    this.totalBookmarks = bookmarks ? bookmarks.length : 0;
    this.totalNotes = notes ? notes.length : 0;
  }

  /**
   * 閸掗攱鏌婇弫鐗堝祦
   */
  refresh(): void {
    this.loadUserInfo();
    this.loadReadingStats();
  }

  /**
   * 閼惧嘲褰囬懣婊冨礋妞?
   */
  getMenuItems(action: (item: ProfileMenuItem) => void): ProfileMenuItem[] {
    return [
      {
        icon: '棣冩憥',
        titleKey: 'myBooks',
        subtitleKey: this.totalBooks + ' ' + tr('books'),
        action: () => action({ icon: '棣冩憥', titleKey: 'myBooks', action: () => {} })
      },
      {
        icon: '閳存唻绗?,
        titleKey: 'readingTime',
        subtitleKey: this.formatReadingTime(this.totalReadingTime),
        action: () => action({ icon: '閳存唻绗?, titleKey: 'readingTime', action: () => {} })
      },
      {
        icon: '棣冩晞',
        titleKey: 'bookmarks',
        subtitleKey: this.totalBookmarks + ' ' + tr('items'),
        action: () => action({ icon: '棣冩晞', titleKey: 'bookmarks', action: () => {} })
      },
      {
        icon: '棣冩憫',
        titleKey: 'notes',
        subtitleKey: this.totalNotes + ' ' + tr('items'),
        action: () => action({ icon: '棣冩憫', titleKey: 'notes', action: () => {} })
      }
    ];
  }

  /**
   * 閺嶇厧绱￠崠鏍鐠囩粯妞傞梻?
   */
  formatReadingTime(minutes: number): string {
    if (minutes < 60) {
      return minutes + ' ' + tr('minutes');
    }
    const hours = Math.floor(minutes / 60);
    return hours + ' ' + tr('hours');
  }
}

// 鐎电厧鍤崡鏇氱伐
export const profileViewModel = new ProfileViewModel();
