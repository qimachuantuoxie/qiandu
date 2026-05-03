// ReadingStats ViewModel - 管理阅读统计与成就的业务逻辑

import { readingStatisticsManager, achievementManager, friendPKManager } from '../models/ReadingStats';
import { TodayDataClass, WeekDataClass, MonthDataClass, FriendPK } from '../models/ReadingStats';
import { ReadingStatistics, AchievementBadge } from '../models/AdvancedReading';

/**
 * 统计周期类型
 */
export type StatsPeriod = 'today' | 'week' | 'month' | 'year' | 'all';

/**
 * 阅读趋势数据点
 */
export interface TrendDataPoint {
  date: string;
  minutes: number;
  books: number;
  pages: number;
}

/**
 * 书籍阅读统计
 */
export interface BookReadingStats {
  bookId: string;
  bookTitle: string;
  totalReadingTime: number;
  lastReadDate: string;
  readingDays: number;
  progress: number;
}

/**
 * 阅读统计 ViewModel 类
 */
@ObservedV2
export class ReadingStatsViewModel {
  // UI 状态 - 使用 @Trace 装饰
  @Trace private dailyStats: TodayDataClass = new TodayDataClass();
  @Trace private weeklyStats: WeekDataClass = new WeekDataClass();
  @Trace private monthlyStats: MonthDataClass = new MonthDataClass();
  @Trace private totalStats: ReadingStatistics = {
    totalBooks: 0,
    finishedBooks: 0,
    readingDays: 0,
    totalReadingTime: 0,
    todayReadingTime: 0,
    weekReadingTime: 0,
    totalWords: 0,
    totalNotes: 0,
    totalBookmarks: 0
  };
  @Trace private selectedPeriod: StatsPeriod = 'week';
  @Trace private currentBookStats: BookReadingStats | null = null;
  @Trace private trendData: TrendDataPoint[] = [];
  @Trace private unlockedBadges: AchievementBadge[] = [];
  @Trace private ongoingPKs: FriendPK[] = [];
  @Trace private currentStreak: number = 0;
  @Trace private longestStreak: number = 0;
  @Trace private isLoading: boolean = false;
  @Trace private errorMessage: string = '';

  /**
   * 初始化 ViewModel
   */
  async init(): Promise<void> {
    try {
      await this.loadStats();
      console.info('[ReadingStatsViewModel] 初始化成功');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = '加载统计数据失败';
    }
  }

  /**
   * 加载所有统计数据
   */
  async loadStats(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 从管理器加载基础统计数据
      await readingStatisticsManager.loadStats();

      // 更新各周期数据
      this.dailyStats = readingStatisticsManager.getTodayData();
      this.weeklyStats = readingStatisticsManager.getWeekData();
      this.monthlyStats = readingStatisticsManager.getMonthData();
      this.totalStats = readingStatisticsManager.getFullStatistics();

      // 加载徽章数据
      this.unlockedBadges = achievementManager.getUnlockedBadges();

      // 加载进行中的PK
      this.ongoingPKs = friendPKManager.getOngoingPKs();

      // 加载趋势数据
      await this.loadTrendData();

      this.isLoading = false;
      console.info('[ReadingStatsViewModel] 统计数据加载完成');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = '加载统计数据失败: ' + err.message;
      this.isLoading = false;
      console.error('[ReadingStatsViewModel] 加载失败:', err.message);
    }
  }

  /**
   * 记录阅读时长
   */
  async recordReadingTime(minutes: number, bookId?: string): Promise<void> {
    try {
      await readingStatisticsManager.recordReadingTime(minutes, bookId);

      // 重新加载数据以更新UI
      this.dailyStats = readingStatisticsManager.getTodayData();
      this.weeklyStats = readingStatisticsManager.getWeekData();
      this.monthlyStats = readingStatisticsManager.getMonthData();
      this.totalStats = readingStatisticsManager.getFullStatistics();

      // 检查徽章解锁
      const streak = this.currentStreak;
      const newlyUnlocked = achievementManager.checkAndUnlock(this.totalStats, streak);
      if (newlyUnlocked.length > 0) {
        this.unlockedBadges = achievementManager.getUnlockedBadges();
        console.info('[ReadingStatsViewModel] 解锁新徽章', newlyUnlocked.length, '个');
      }

      console.info('[ReadingStatsViewModel] 记录阅读时长:', minutes, '分钟');
    } catch (error) {
      const err = error as Error;
      console.error('[ReadingStatsViewModel] 记录阅读时长失败:', err.message);
    }
  }

  /**
   * 获取周数据
   */
  getWeekData(): WeekDataClass {
    return this.weeklyStats;
  }

  /**
   * 获取月数据
   */
  getMonthData(): MonthDataClass {
    return this.monthlyStats;
  }

  /**
   * 获取今日数据
   */
  getTodayData(): TodayDataClass {
    return this.dailyStats;
  }

  /**
   * 获取完整统计信息
   */
  getTotalStats(): ReadingStatistics {
    return this.totalStats;
  }

  /**
   * 加载趋势数据
   */
  async loadTrendData(): Promise<void> {
    try {
      // 根据选择的周期加载趋势数据
      switch (this.selectedPeriod) {
        case 'today':
          this.trendData = await this.getHourlyTrend();
          break;
        case 'week':
          this.trendData = await this.getDailyTrend(7);
          break;
        case 'month':
          this.trendData = await this.getDailyTrend(30);
          break;
        case 'year':
          this.trendData = await this.getMonthlyTrend();
          break;
        case 'all':
          this.trendData = await this.getYearlyTrend();
          break;
        default:
          this.trendData = await this.getDailyTrend(7);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[ReadingStatsViewModel] 加载趋势数据失败:', err.message);
      this.trendData = [];
    }
  }

  /**
   * 获取每日趋势数据（最近N天）
   */
  private async getDailyTrend(days: number): Promise<TrendDataPoint[]> {
    const result: TrendDataPoint[] = [];
    const now = new Date();

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];

      result.push({
        date: dateStr,
        minutes: 0,
        books: 0,
        pages: 0
      });
    }

    return result;
  }

  /**
   * 获取每小时趋势数据
   */
  private async getHourlyTrend(): Promise<TrendDataPoint[]> {
    const result: TrendDataPoint[] = [];
    for (let i = 0; i < 24; i++) {
      const pad = i < 10 ? '0' + i : i.toString();
      result.push({
        date: pad + ':00',
        minutes: 0,
        books: 0,
        pages: 0
      });
    }
    return result;
  }

  /**
   * 获取每月趋势数据
   */
  private async getMonthlyTrend(): Promise<TrendDataPoint[]> {
    const result: TrendDataPoint[] = [];
    const now = new Date();

    for (let i = 11; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const month = date.getMonth() + 1;
      const monthPad = month < 10 ? '0' + month : month.toString();
      const monthStr = date.getFullYear() + '-' + monthPad;

      result.push({
        date: monthStr,
        minutes: 0,
        books: 0,
        pages: 0
      });
    }

    return result;
  }

  /**
   * 获取每年趋势数据
   */
  private async getYearlyTrend(): Promise<TrendDataPoint[]> {
    const result: TrendDataPoint[] = [];
    const currentYear = new Date().getFullYear();

    for (let year = currentYear - 4; year <= currentYear; year++) {
      result.push({
        date: year.toString(),
        minutes: 0,
        books: 0,
        pages: 0
      });
    }

    return result;
  }

  /**
   * 设置选中的周期
   */
  setSelectedPeriod(period: StatsPeriod): void {
    this.selectedPeriod = period;
    this.loadTrendData();
  }

  /**
   * 获取选中的周期
   */
  getSelectedPeriod(): StatsPeriod {
    return this.selectedPeriod;
  }

  /**
   * 获取趋势数据
   */
  getTrendData(): TrendDataPoint[] {
    return this.trendData;
  }

  /**
   * 设置当前书籍统计
   */
  setCurrentBookStats(stats: BookReadingStats | null): void {
    this.currentBookStats = stats;
  }

  /**
   * 获取当前书籍统计
   */
  getCurrentBookStats(): BookReadingStats | null {
    return this.currentBookStats;
  }

  /**
   * 获取所有已解锁徽章
   */
  getUnlockedBadges(): AchievementBadge[] {
    return this.unlockedBadges;
  }

  /**
   * 获取所有徽章（包括未解锁）
   */
  getAllBadges(): AchievementBadge[] {
    return achievementManager.getAllBadges();
  }

  /**
   * 获取徽章进度
   */
  getBadgeProgress(badgeId: string): number {
    return achievementManager.getBadgeProgress(badgeId, this.totalStats, this.currentStreak);
  }

  /**
   * 获取进行中的PK
   */
  getOngoingPKs(): FriendPK[] {
    return this.ongoingPKs;
  }

  /**
   * 发起PK挑战
   */
  async startPKChallenge(friendId: string, friendName: string, durationMinutes: number): Promise<FriendPK | null> {
    try {
      const pk = friendPKManager.challengeFriend(friendId, friendName, durationMinutes);
      this.ongoingPKs = friendPKManager.getOngoingPKs();
      return pk;
    } catch (error) {
      const err = error as Error;
      console.error('[ReadingStatsViewModel] 发起PK失败:', err.message);
      return null;
    }
  }

  /**
   * 更新PK阅读时长
   */
  updatePKReadingTime(pkId: string, minutes: number): void {
    try {
      friendPKManager.updateMyTime(pkId, minutes);
      this.ongoingPKs = friendPKManager.getOngoingPKs();
    } catch (error) {
      const err = error as Error;
      console.error('[ReadingStatsViewModel] 更新PK时长失败:', err.message);
    }
  }

  /**
   * 获取连续阅读天数
   */
  getCurrentStreak(): number {
    return this.currentStreak;
  }

  /**
   * 获取最长连续天数
   */
  getLongestStreak(): number {
    return this.longestStreak;
  }

  /**
   * 获取错误信息
   */
  getErrorMessage(): string {
    return this.errorMessage;
  }

  /**
   * 检查是否正在加载
   */
  isLoadingData(): boolean {
    return this.isLoading;
  }

  /**
   * 清空错误信息
   */
  clearError(): void {
    this.errorMessage = '';
  }

  /**
   * 生成阅读报告
   */
  generateReport(type: 'week' | 'month' | 'year'): void {
    try {
      const report = readingStatisticsManager.generateReport(type);
      console.info('[ReadingStatsViewModel] 生成报告:', type, report);
    } catch (error) {
      const err = error as Error;
      console.error('[ReadingStatsViewModel] 生成报告失败:', err.message);
    }
  }

  /**
   * 清理资源
   */
  destroy(): void {
    this.trendData = [];
    this.unlockedBadges = [];
    this.ongoingPKs = [];
    this.currentBookStats = null;
    console.info('[ReadingStatsViewModel] 资源已清理');
  }
}

// 导出单例
export const readingStatsViewModel: ReadingStatsViewModel = new ReadingStatsViewModel();
