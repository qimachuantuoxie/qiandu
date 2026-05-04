/**
 * ProfilePage ViewModel - V2閻楀牊婀?
 */
import { loginStateManager, UserInfo } from '../services/auth/LoginStateManager';
import { bookViewModel } from './BookViewModel';
import { appTheme, themeManager, AppColors } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';

@ObservedV2
export class ProfilePageViewModel {
  @Trace isLoggedIn: boolean = false;
  @Trace userInfo: UserInfo | null = null;
  @Trace totalBooks: number = 0;
  @Trace totalReadingTime: number = 0;
  @Trace totalBookmarks: number = 0;
  @Trace totalNotes: number = 0;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.loadUserInfo();
    this.loadStats();
  }

  loadUserInfo(): void {
    this.userInfo = loginStateManager.getCurrentUser();
    this.isLoggedIn = this.userInfo !== null;
  }

  loadStats(): void {
    const books = bookViewModel.getAllBooks();
    this.totalBooks = books.length;
    let readTime = 0;
    for (let i = 0; i < books.length; i++) {
      readTime += books[i].totalReadTime > 0 ? books[i].totalReadTime : 0;
    }
    this.totalReadingTime = readTime;
    const bookmarks = bookViewModel.getAllBookmarks();
    const notes = bookViewModel.getAllNotes();
    this.totalBookmarks = bookmarks ? bookmarks.length : 0;
    this.totalNotes = notes ? notes.length : 0;
  }

  refresh(): void {
    this.loadUserInfo();
    this.loadStats();
  }

  logout(): void {
    loginStateManager.logout();
    this.isLoggedIn = false;
    this.userInfo = null;
  }
}

export const profilePageViewModel = new ProfilePageViewModel();
