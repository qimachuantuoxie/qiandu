/**
 * StatisticsPage ViewModel - V2鐗堟湰
 */
import { bookViewModel } from './BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

@ObservedV2
export class StatisticsViewModel {
  @Trace totalBooks: number = 0;
  @Trace finishedBooks: number = 0;
  @Trace readingBooks: number = 0;
  @Trace totalReadingTime: number = 0;
  @Trace totalWords: number = 0;
  @Trace currentStreak: number = 0;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadStats();
  }

  loadStats(): void {
    const books = bookViewModel.getAllBooks();
    this.totalBooks = books.length;
    let finished = 0;
    let reading = 0;
    let readTime = 0;
    for (let i = 0; i < books.length; i++) {
      if (books[i].readProgress >= 100) {
        finished++;
      }
      if (books[i].readProgress > 0 && books[i].readProgress < 100) {
        reading++;
      }
      readTime += books[i].totalReadTime > 0 ? books[i].totalReadTime : 0;
    }
    this.finishedBooks = finished;
    this.readingBooks = reading;
    this.totalReadingTime = readTime;
    this.totalWords = 0;
    this.currentStreak = preferenceManager.getNumber('reading_streak', 0);
  }

  formatTime(minutes: number): string {
    if (minutes < 60) return minutes + '鍒嗛挓';
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return hours + '灏忔椂';
    const days = Math.floor(hours / 24);
    return days + '澶?' + (hours % 24) + '灏忔椂';
  }

  getCompletionRate(): number {
    if (this.totalBooks === 0) return 0;
    return Math.round((this.finishedBooks / this.totalBooks) * 100);
  }
}

export const statisticsViewModel = new StatisticsViewModel();
