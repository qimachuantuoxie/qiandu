import { logger } from '../../../utils/Logger';
// 阅读统计与成就系统 - 对标微信读书的统计体系
import { ReadingStatistics, AchievementBadge } from './AdvancedReading';
import { preferenceManager } from '../../../utils/PreferenceManager';

export function generateBookId(): string {
  return 'book_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

/**
 * 每日阅读记录
 */
export interface DailyReadingRecord {
  date: string;                 // 日期 (YYYY-MM-DD)
  readingTime: number;          // 阅读时长（分钟）
  booksRead: number;            // 读书数量
  pagesRead: number;            // 阅读页数
  notesCount: number;           // 笔记数
}

/**
 * 阅读目标接口
 */
export interface ReadingGoal {
  dailyMinutes: number;         // 每日目标（分钟）
  weeklyBooks: number;          // 每周目标（本）
  monthlyBooks: number;         // 每月目标（本）
}

/**
 * 好友PK状态枚举
 */
export enum FriendPKStatus {
  ONGOING = 'ongoing',
  FINISHED = 'finished',
  ACCEPTED = 'accepted'
}

/**
 * 好友 PK 接口
 */
export interface FriendPK {
  id: string;
  friendId: string;
  friendName: string;
  friendAvatar?: string;
  startTime: number;
  endTime: number;
  myReadingTime: number;        // 我的阅读时长
  friendReadingTime: number;    // 好友阅读时长
  status: FriendPKStatus;
  winner?: string;              // 获胜者
}

export class TodayDataClass {
  minutes: number = 0;
  books: number = 0;
  pages: number = 0;
}

export class WeekDataClass {
  minutes: number = 0;
  books: number = 0;
  days: number = 0;
}

export class MonthDataClass {
  minutes: number = 0;
  books: number = 0;
  days: number = 0;
}

class BadgeTemplateClass {
  id: string = '';
  name: string = '';
  description: string = '';
  icon: string = '';
  requirement: string = '';
}

/**
 * 阅读统计管理器 - 单例模式
 */
class ReadingStatisticsManager {
  private static instance: ReadingStatisticsManager;

  private dailyRecords: Record<string, DailyReadingRecord> = {};
  private dailyRecordsKeys: string[] = [];
  private totalReadingTime: number = 0; // 总分钟数
  private currentStreak: number = 0;    // 连续天数
  private longestStreak: number = 0;    // 最长连续天数

  private constructor() {}

  static getInstance(): ReadingStatisticsManager {
    if (!ReadingStatisticsManager.instance) {
      ReadingStatisticsManager.instance = new ReadingStatisticsManager();
    }
    return ReadingStatisticsManager.instance;
  }

  /**
   * 记录阅读时长
   */
  async recordReadingTime(minutes: number, bookId?: string): Promise<void> {
    const today = this.getTodayString();

    let record = this.dailyRecords[today];
    if (record === undefined) {
      record = {
        date: today,
        readingTime: 0,
        booksRead: 0,
        pagesRead: 0,
        notesCount: 0
      };
      this.dailyRecords[today] = record;
      this.dailyRecordsKeys.push(today);
    }

    record.readingTime += minutes;
    this.dailyRecords[today] = record;
    this.totalReadingTime += minutes;

    // 更新连续天数
    this.updateStreak();

    // 保存到本地存储
    await this.saveStats();
  }

  /**
   * 保存统计
   */
  private async saveStats(): Promise<void> {
    try {
      const statsData = {
        dailyRecords: this.dailyRecords,
        dailyRecordsKeys: this.dailyRecordsKeys,
        totalReadingTime: this.totalReadingTime,
        currentStreak: this.currentStreak,
        longestStreak: this.longestStreak
      };
      const statsJson = JSON.stringify(statsData);
      preferenceManager.setString('reading_stats', statsJson);
      logger.info('[ReadingStats] Statistics saved');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[ReadingStats] Save stats failed:', message);
    }
  }

  /**
   * 加载统计
   */
  async loadStats(): Promise<void> {
    try {
      const statsJson = preferenceManager.getString('reading_stats', '');
      if (statsJson && statsJson.length > 0) {
        const statsData = JSON.parse(statsJson);
        if (statsData.dailyRecords !== undefined) {
          this.dailyRecords = statsData.dailyRecords;
        } else {
          this.dailyRecords = {};
        }
        if (statsData.dailyRecordsKeys !== undefined) {
          this.dailyRecordsKeys = statsData.dailyRecordsKeys;
        } else {
          this.dailyRecordsKeys = [];
        }
        if (statsData.totalReadingTime !== undefined) {
          this.totalReadingTime = statsData.totalReadingTime;
        } else {
          this.totalReadingTime = 0;
        }
        if (statsData.currentStreak !== undefined) {
          this.currentStreak = statsData.currentStreak;
        } else {
          this.currentStreak = 0;
        }
        if (statsData.longestStreak !== undefined) {
          this.longestStreak = statsData.longestStreak;
        } else {
          this.longestStreak = 0;
        }
        logger.info('[ReadingStats] Statistics loaded');
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[ReadingStats] Load stats failed: ' + message);
    }
  }

  /**
   * 获取今日数据
   */
  getTodayData(): TodayDataClass {
    const today = this.getTodayString();
    const record = this.dailyRecords[today];
    const result = new TodayDataClass();
    result.minutes = record?.readingTime || 0;
    result.books = record?.booksRead || 0;
    result.pages = record?.pagesRead || 0;
    return result;
  }

  /**
   * 获取本周数据
   */
  getWeekData(): WeekDataClass {
    const weekStart = this.getWeekStart();
    let totalMinutes = 0;
    let totalBooks = 0;
    let activeDays = 0;
    
    for (let i = 0; i < this.dailyRecordsKeys.length; i++) {
      const date = this.dailyRecordsKeys[i];
      const record = this.dailyRecords[date];
      if (record !== undefined && date >= weekStart) {
        totalMinutes += record.readingTime;
        totalBooks += record.booksRead;
        activeDays++;
      }
    }

    const result = new WeekDataClass();
    result.minutes = totalMinutes;
    result.books = totalBooks;
    result.days = activeDays;
    return result;
  }

  /**
   * 获取本月数据
   */
  getMonthData(): MonthDataClass {
    const monthStart = this.getMonthStart();
    let totalMinutes = 0;
    let totalBooks = 0;
    let activeDays = 0;
    
    for (let i = 0; i < this.dailyRecordsKeys.length; i++) {
      const date = this.dailyRecordsKeys[i];
      const record = this.dailyRecords[date];
      if (record !== undefined && date >= monthStart) {
        totalMinutes += record.readingTime;
        totalBooks += record.booksRead;
        activeDays++;
      }
    }

    const result = new MonthDataClass();
    result.minutes = totalMinutes;
    result.books = totalBooks;
    result.days = activeDays;
    return result;
  }

  /**
   * 获取完整统计信息
   */
  getFullStatistics(): ReadingStatistics {
    const today = this.getTodayData();
    const week = this.getWeekData();
    const month = this.getMonthData();

    return {
      totalBooks: 0,
      finishedBooks: 0,
      readingDays: this.dailyRecordsKeys.length,
      totalReadingTime: this.totalReadingTime,
      todayReadingTime: today.minutes,
      weekReadingTime: week.minutes,
      totalWords: 0,
      totalNotes: 0,
      totalBookmarks: 0
    };
  }

  /**
   * 生成阅读报告（周报/月报/年报）
   */
  generateReport(type: 'week' | 'month' | 'year'): ReadingReport {
    const now = new Date();
    let startDate: Date;
    let endDate = now;

    // 计算时间范围
    if (type === 'week') {
      const dayOfWeek = now.getDay();
      const diff = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
      startDate = new Date(now.getFullYear(), now.getMonth(), diff);
    } else if (type === 'month') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    } else {
      // year
      startDate = new Date(now.getFullYear(), 0, 1);
    }

    const startTime = startDate.getTime();
    const endTime = endDate.getTime();

    // 统计该时间段的数据
    let totalTime = 0;
    let totalBooks = 0;
    const bookTimeMap: Map<string, number> = new Map();
    const dailyTrend: Array<{date: string, minutes: number}> = [];

    // 遍历每日记录
    for (const dateKey of this.dailyRecordsKeys) {
      const recordDate = new Date(dateKey).getTime();
      if (recordDate >= startTime && recordDate <= endTime) {
        const record = this.dailyRecords[dateKey];
        if (record) {
          totalTime += record.minutes;
          
          // 统计书籍数量
          const books = Object.keys(record.books || {});
          totalBooks += books.length;
          
          // 累加每本书的阅读时间
          for (const bookId in record.books) {
            const currentBookTime = bookTimeMap.get(bookId) || 0;
            bookTimeMap.set(bookId, currentBookTime + record.books[bookId]);
          }

          // 添加到趋势数据
          dailyTrend.push({
            date: dateKey,
            minutes: record.minutes
          });
        }
      }
    }

    // 按日期排序趋势数据
    dailyTrend.sort((a, b) => a.date.localeCompare(b.date));

    // 找出最喜欢的书（阅读时间最长）
    let favoriteBook = '';
    let maxTime = 0;
    for (const [bookId, time] of bookTimeMap.entries()) {
      if (time > maxTime) {
        maxTime = time;
        favoriteBook = bookId;
      }
    }

    // 计算平均每日阅读时间
    const daysInPeriod = Math.floor((endTime - startTime) / MS_PER_DAY) + 1;
    const avgDailyTime = daysInPeriod > 0 ? Math.round(totalTime / daysInPeriod) : 0;

    // 计算活跃天数
    const activeDays = dailyTrend.filter(d => d.minutes > 0).length;

    return {
      period: type,
      totalTime: totalTime,
      totalBooks: totalBooks,
      favoriteBook: favoriteBook,
      readingTrend: dailyTrend,
      avgDailyTime: avgDailyTime,
      activeDays: activeDays,
      totalDays: daysInPeriod
    };
  }

  /**
   * 获取当前连续天数
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
   * 更新连续天数
   */
  private updateStreak(): void {
    const today = this.getTodayString();
    const yesterday = this.getYesterdayString();

    const todayRecord = this.dailyRecords[today];
    if (todayRecord === undefined) {
      return;
    }

    const yesterdayRecord = this.dailyRecords[yesterday];
    const hasYesterday = yesterdayRecord !== undefined;

    if (hasYesterday) {
      this.currentStreak++;
    } else {
      this.currentStreak = 1;
    }

    if (this.currentStreak > this.longestStreak) {
      this.longestStreak = this.currentStreak;
    }
  }

  /**
   * 获取日期字符串
   */
  private getTodayString(): string {
    return new Date().toISOString().split('T')[0];
  }

  private getYesterdayString(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }

  private getWeekStart(): string {
    const now = new Date();
    const dayOfWeek = now.getDay();
    const diff = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
    const weekStart = new Date(now.setDate(diff));
    return weekStart.toISOString().split('T')[0];
  }

  private getMonthStart(): string {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    return monthStart.toISOString().split('T')[0];
  }
}

/**
 * 成就徽章管理器
 */
class AchievementManager {
  private static instance: AchievementManager;
  private badges: Record<string, AchievementBadge> = {};
  private badgesKeys: string[] = [];

  private constructor() {
    this.initBadges();
  }

  static getInstance(): AchievementManager {
    if (!AchievementManager.instance) {
      AchievementManager.instance = new AchievementManager();
    }
    return AchievementManager.instance;
  }

  /**
   * 初始化所有徽章
   */
  private initBadges(): void {
    const badgeTemplates: BadgeTemplateClass[] = [
      {
        id: 'first_read',
        name: '初次体验',
        description: '开始阅读第一本书',
        icon: '阅',
        requirement: '阅读任意书籍 1 分钟'
      },
      {
        id: 'bookworm',
        name: '书虫宝宝',
        description: '累计阅读 10 本书',
        icon: 'ladybug_fill',
        requirement: '读完 10 本书'
      },
      {
        id: 'scholar',
        name: '学问达人',
        description: '累计阅读 100 本书',
        icon: 'graduationcap_fill',
        requirement: '读完 100 本书'
      },
      {
        id: 'marathon',
        name: '阅读马拉松',
        description: '单日阅读超过 5 小时',
        icon: 'figure_run',
        requirement: '单日阅读 300 分钟'
      },
      {
        id: 'nightowl',
        name: '深夜读书',
        description: '在凌晨 0-5 点阅读',
        icon: 'moon_stars_fill',
        requirement: '深夜时段阅读'
      },
      {
        id: 'earlybird',
        name: '晨读达人',
        description: '连续 7 天早起阅读',
        icon: 'sunrise_fill',
        requirement: '连续 7 天 6-8 点阅读'
      },
      {
        id: 'note_master',
        name: '笔记达人',
        description: '累计写 100 篇笔记',
        icon: '笔',
        requirement: '写 100 篇笔记'
      },
      {
        id: 'highlight_king',
        name: '划线王者',
        description: '累计划线 500 次',
        icon: 'crown_fill',
        requirement: '划线 500 次'
      },
      {
        id: 'streak_7',
        name: '持之以恒',
        description: '连续阅读 7 天',
        icon: 'flame_fill',
        requirement: '连续 7 天阅读'
      },
      {
        id: 'streak_30',
        name: '一月之约',
        description: '连续阅读 30 天',
        icon: 'gemstone_fill',
        requirement: '连续 30 天阅读'
      },
      {
        id: 'streak_100',
        name: '百日挑战',
        description: '连续阅读 100 天',
        icon: 'trophy_fill',
        requirement: '连续 100 天阅读'
      },
      {
        id: 'speed_reader',
        name: '速读高手',
        description: '一天读完一本书',
        icon: 'bolt_fill',
        requirement: '单日读完 1 本书'
      }
    ];

    for (let i = 0; i < badgeTemplates.length; i++) {
      const template = badgeTemplates[i];
      const badge: AchievementBadge = {
        id: template.id,
        name: template.name,
        description: template.description,
        icon: template.icon,
        requirement: template.requirement,
        unlocked: false
      };
      this.badges[template.id] = badge;
      this.badgesKeys.push(template.id);
    }
  }

  /**
   * 检查并解锁徽章
   */
  checkAndUnlock(statistics: ReadingStatistics, streak: number): AchievementBadge[] {
    const unlockedBadges: AchievementBadge[] = [];

    for (let i = 0; i < this.badgesKeys.length; i++) {
      const id = this.badgesKeys[i];
      const badge = this.badges[id];
      if (badge !== undefined && !badge.unlocked && this.meetsRequirement(id, statistics, streak)) {
        badge.unlocked = true;
        badge.unlockTime = Date.now();
        unlockedBadges.push(badge);
      }
    }

    return unlockedBadges;
  }

  /**
   * 判断是否满足徽章条件
   */
  private meetsRequirement(
    badgeId: string, 
    stats: ReadingStatistics, 
    streak: number
  ): boolean {
    switch (badgeId) {
      case 'first_read':
        return stats.totalReadingTime >= 1;
      case 'bookworm':
        return stats.finishedBooks >= 10;
      case 'scholar':
        return stats.finishedBooks >= 100;
      case 'marathon':
        return stats.todayReadingTime >= 300;
      case 'streak_7':
        return streak >= 7;
      case 'streak_30':
        return streak >= 30;
      case 'streak_100':
        return streak >= 100;
      case 'note_master':
        return stats.totalNotes >= 100;
      default:
        return false;
    }
  }

  /**
   * 获取所有徽章
   */
  getAllBadges(): AchievementBadge[] {
    const result: AchievementBadge[] = [];
    for (let i = 0; i < this.badgesKeys.length; i++) {
      const badge = this.badges[this.badgesKeys[i]];
      if (badge !== undefined) {
        result.push(badge);
      }
    }
    return result;
  }

  /**
   * 获取已解锁徽章
   */
  getUnlockedBadges(): AchievementBadge[] {
    return this.getAllBadges().filter(badge => badge.unlocked);
  }

  /**
   * 获取徽章进度
   */
  getBadgeProgress(badgeId: string, stats: ReadingStatistics, streak: number): number {
    switch (badgeId) {
      case 'bookworm':
        return Math.min(100, (stats.finishedBooks / 10) * 100);
      case 'scholar':
        return Math.min(100, (stats.finishedBooks / 100) * 100);
      case 'streak_7':
        return Math.min(100, (streak / 7) * 100);
      case 'streak_30':
        return Math.min(100, (streak / 30) * 100);
      default:
        return 0;
    }
  }
}

/**
 * 好友 PK 管理器
 */
class FriendPKManager {
  private static instance: FriendPKManager;
  private pks: Record<string, FriendPK> = {};
  private pksKeys: string[] = [];

  private constructor() {}

  static getInstance(): FriendPKManager {
    if (!FriendPKManager.instance) {
      FriendPKManager.instance = new FriendPKManager();
    }
    return FriendPKManager.instance;
  }

  /**
   * 发起 PK 挑战
   */
  challengeFriend(friendId: string, friendName: string, durationMinutes: number): FriendPK {
    const pk: FriendPK = {
      id: generateBookId(),
      friendId,
      friendName,
      startTime: Date.now(),
      endTime: Date.now() + durationMinutes * 60 * 1000,
      myReadingTime: 0,
      friendReadingTime: 0,
      status: FriendPKStatus.ACCEPTED
    };

    this.pks[pk.id] = pk;
    this.pksKeys.push(pk.id);
    
    // TODO: 发送通知给好友
    
    return pk;
  }

  /**
   * 更新我的阅读时长
   */
  updateMyTime(pkId: string, minutes: number): void {
    const pk = this.pks[pkId];
    if (pk !== undefined && pk.status === FriendPKStatus.ONGOING) {
      pk.myReadingTime += minutes;
      
      // 检查是否结束
      if (Date.now() >= pk.endTime) {
        this.finishPK(pk);
      }
    }
  }

  /**
   * 结束 PK
   */
  private finishPK(pk: FriendPK): void {
    pk.status = FriendPKStatus.FINISHED;
    pk.winner = pk.myReadingTime > pk.friendReadingTime ? 'me' : 'friend';
    
    // TODO: 发送结果通知
  }

  /**
   * 获取进行中的 PK
   */
  getOngoingPKs(): FriendPK[] {
    const result: FriendPK[] = [];
    for (let i = 0; i < this.pksKeys.length; i++) {
      const pk = this.pks[this.pksKeys[i]];
      if (pk !== undefined && pk.status === FriendPKStatus.ONGOING) {
        result.push(pk);
      }
    }
    return result;
  }
}

interface ReadingReport {
  period: string;                        // 报告类型 (week/month/year)
  totalTime: number;                     // 总阅读时间（分钟）
  totalBooks: number;                    // 阅读书籍数量
  favoriteBook: string;                  // 最喜欢的书 ID
  readingTrend: Array<{date: string, minutes: number}>;  // 阅读趋势数据
  avgDailyTime: number;                  // 平均每日阅读时间
  activeDays: number;                    // 活跃天数
  totalDays: number;                     // 总天数
}

// 导出单例
export const readingStatisticsManager = ReadingStatisticsManager.getInstance();
export const achievementManager = AchievementManager.getInstance();
export const friendPKManager = FriendPKManager.getInstance();
