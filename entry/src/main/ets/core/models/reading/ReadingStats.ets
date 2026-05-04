import { logger } from '../../../utils/Logger';
// 闃呰�缁熻�涓庢垚灏辩郴缁?- 瀵规爣寰�俊璇讳功鐨勭粺璁′綋绯?
import { ReadingStatistics, AchievementBadge } from './AdvancedReading';
import { preferenceManager } from '../../../utils/PreferenceManager';

export function generateBookId(): string {
  return 'book_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

/**
 * 姣忔棩闃呰�璁板綍
 */
export interface DailyReadingRecord {
  date: string;                 // 鏃ユ湡 (YYYY-MM-DD)
  readingTime: number;          // 闃呰�鏃堕暱锛堝垎閽燂級
  booksRead: number;            // 璇讳功鏁伴噺
  pagesRead: number;            // 闃呰�椤垫暟
  notesCount: number;           // 绗旇�鏁?
}

/**
 * 闃呰�鐩�爣鎺ュ彛
 */
export interface ReadingGoal {
  dailyMinutes: number;         // 姣忔棩鐩�爣锛堝垎閽燂級
  weeklyBooks: number;          // 姣忓懆鐩�爣锛堟湰锛?
  monthlyBooks: number;         // 姣忔湀鐩�爣锛堟湰锛?
}

/**
 * 濂藉弸PK鐘舵€佹灇涓?
 */
export enum FriendPKStatus {
  ONGOING = 'ongoing',
  FINISHED = 'finished',
  ACCEPTED = 'accepted'
}

/**
 * 濂藉弸 PK 鎺ュ彛
 */
export interface FriendPK {
  id: string;
  friendId: string;
  friendName: string;
  friendAvatar?: string;
  startTime: number;
  endTime: number;
  myReadingTime: number;        // 鎴戠殑闃呰�鏃堕暱
  friendReadingTime: number;    // 濂藉弸闃呰�鏃堕暱
  status: FriendPKStatus;
  winner?: string;              // 鑾疯儨鑰?
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
 * 闃呰�缁熻�绠＄悊鍣?- 鍗曚緥妯″紡
 */
class ReadingStatisticsManager {
  private static instance: ReadingStatisticsManager;

  private dailyRecords: Record<string, DailyReadingRecord> = {};
  private dailyRecordsKeys: string[] = [];
  private totalReadingTime: number = 0; // 鎬诲垎閽熸暟
  private currentStreak: number = 0;    // 杩炵画澶╂暟
  private longestStreak: number = 0;    // 鏈€闀胯繛缁�ぉ鏁?

  private constructor() {}

  static getInstance(): ReadingStatisticsManager {
    if (!ReadingStatisticsManager.instance) {
      ReadingStatisticsManager.instance = new ReadingStatisticsManager();
    }
    return ReadingStatisticsManager.instance;
  }

  /**
   * 璁板綍闃呰�鏃堕暱
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

    // 鏇存柊杩炵画澶╂暟
    this.updateStreak();

    // 淇濆瓨鍒版湰鍦板瓨鍌?
    await this.saveStats();
  }

  /**
   * 淇濆瓨缁熻�
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
   * 鍔犺浇缁熻�
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
   * 鑾峰彇浠婃棩鏁版嵁
   */
  getTodayData(): TodayDataClass {
    const today = this.getTodayString();
    const record = this.dailyRecords[today];
    const result = new TodayDataClass();
    if (record !== undefined) {
      result.minutes = record.readingTime;
      result.books = record.booksRead;
      result.pages = record.pagesRead;
    } else {
      result.minutes = 0;
      result.books = 0;
      result.pages = 0;
    }
    return result;
  }

  /**
   * 鑾峰彇鏈�懆鏁版嵁
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
   * 鑾峰彇鏈�湀鏁版嵁
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
   * 鑾峰彇瀹屾暣缁熻�淇℃伅
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
   * 鐢熸垚闃呰�鎶ュ憡锛堝懆鎶?鏈堟姤/骞存姤锛?
   */
  generateReport(type: 'week' | 'month' | 'year'): ReadingReport {
    // TODO: 瀹炵幇瀹屾暣鐨勬姤鍛婄敓鎴?
    return {
      period: type,
      totalTime: 0,
      totalBooks: 0,
      favoriteBook: '',
      readingTrend: []
    };
  }

  /**
   * 鏇存柊杩炵画澶╂暟
   */
  private updateStreak(): void {
    const today = this.getTodayString();
    const yesterday = this.getYesterdayString();

    const hasToday = this.dailyRecords[today] !== undefined;
    const hasYesterday = this.dailyRecords[yesterday] !== undefined;

    if (hasToday && hasYesterday) {
      this.currentStreak++;
    } else if (hasToday && !hasYesterday) {
      this.currentStreak = 1;
    }

    if (this.currentStreak > this.longestStreak) {
      this.longestStreak = this.currentStreak;
    }
  }

  /**
   * 鑾峰彇鏃ユ湡瀛楃�涓?
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
 * 鎴愬氨寰界珷绠＄悊鍣?
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
   * 鍒濆�鍖栨墍鏈夊窘绔?
   */
  private initBadges(): void {
    const badgeTemplates: BadgeTemplateClass[] = [
      {
        id: 'first_read',
        name: '鍒濇�浣撻獙',
        description: '寮€濮嬮槄璇荤�涓€鏈�功',
        icon: '闃?,
        requirement: '闃呰�浠绘剰涔︾睄 1 鍒嗛挓'
      },
      {
        id: 'bookworm',
        name: '涔﹁櫕瀹濆疂',
        description: '绱��闃呰� 10 鏈�功',
        icon: 'ladybug_fill',
        requirement: '璇诲畬 10 鏈�功'
      },
      {
        id: 'scholar',
        name: '瀛﹂棶杈句汉',
        description: '绱��闃呰� 100 鏈�功',
        icon: 'graduationcap_fill',
        requirement: '璇诲畬 100 鏈�功'
      },
      {
        id: 'marathon',
        name: '闃呰�椹�媺鏉?,
        description: '鍗曟棩闃呰�瓒呰繃 5 灏忔椂',
        icon: 'figure_run',
        requirement: '鍗曟棩闃呰� 300 鍒嗛挓'
      },
      {
        id: 'nightowl',
        name: '娣卞�璇讳功',
        description: '鍦ㄥ噷鏅?-5 鐐归槄璇?,
        icon: 'moon_stars_fill',
        requirement: '娣卞�鏃舵�闃呰�'
      },
      {
        id: 'earlybird',
        name: '鏅ㄨ�杈句汉',
        description: '杩炵画 7 澶╂棭璧烽槄璇?,
        icon: 'sunrise_fill',
        requirement: '杩炵画 7 澶?-8 鐐归槄璇?
      },
      {
        id: 'note_master',
        name: '绗旇�杈句汉',
        description: '绱��鍐?100 绡囩瑪璁?,
        icon: '绗?,
        requirement: '鍐?100 绡囩瑪璁?
      },
      {
        id: 'highlight_king',
        name: '鍒掔嚎鐜嬭€?,
        description: '绱��鍒掔嚎 500 娆?,
        icon: 'pin_fill',
        requirement: '鍒掔嚎 500 娆?
      },
      {
        id: 'streak_7',
        name: '鎸佷箣浠ユ亽',
        description: '杩炵画闃呰� 7 澶?,
        icon: 'flame_fill',
        requirement: '杩炵画 7 澶╅槄璇?
      },
      {
        id: 'streak_30',
        name: '涓€鏈堜箣绾?,
        description: '杩炵画闃呰� 30 澶?,
        icon: 'calendar',
        requirement: '杩炵画 30 澶╅槄璇?
      },
      {
        id: 'streak_100',
        name: '鐧炬棩鎸戞垬',
        description: '杩炵画闃呰� 100 澶?,
        icon: 'hand_raised_fill',
        requirement: '杩炵画 100 澶╅槄璇?
      },
      {
        id: 'speed_reader',
        name: '閫熻�楂樻墜',
        description: '涓€澶╄�瀹屼竴鏈�功',
        icon: 'bolt_fill',
        requirement: '鍗曟棩璇诲畬 1 鏈�功'
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
   * 妫€鏌ュ苟瑙ｉ攣寰界珷
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
   * 鍒ゆ柇鏄�惁婊¤冻寰界珷鏉′欢
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
   * 鑾峰彇鎵€鏈夊窘绔?
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
   * 鑾峰彇宸茶В閿佸窘绔?
   */
  getUnlockedBadges(): AchievementBadge[] {
    const allBadges = this.getAllBadges();
    const result: AchievementBadge[] = [];
    for (let i = 0; i < allBadges.length; i++) {
      if (allBadges[i].unlocked) {
        result.push(allBadges[i]);
      }
    }
    return result;
  }

  /**
   * 鑾峰彇寰界珷杩涘害
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
 * 濂藉弸 PK 绠＄悊鍣?
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
   * 鍙戣捣 PK 鎸戞垬
   */
  challengeFriend(friendId: string, friendName: string, durationMinutes: number): FriendPK {
    const pk: FriendPK = {
      id: generateBookId(),
      friendId: friendId,
      friendName: friendName,
      startTime: Date.now(),
      endTime: Date.now() + durationMinutes * 60 * 1000,
      myReadingTime: 0,
      friendReadingTime: 0,
      status: FriendPKStatus.ACCEPTED
    };

    this.pks[pk.id] = pk;
    this.pksKeys.push(pk.id);

    // TODO: 鍙戦€侀€氱煡缁欏ソ鍙?

    return pk;
  }

  /**
   * 鏇存柊鎴戠殑闃呰�鏃堕暱
   */
  updateMyTime(pkId: string, minutes: number): void {
    const pk = this.pks[pkId];
    if (pk !== undefined && pk.status === FriendPKStatus.ONGOING) {
      pk.myReadingTime += minutes;

      // 妫€鏌ユ槸鍚︾粨鏉?
      if (Date.now() >= pk.endTime) {
        this.finishPK(pk);
      }
    }
  }

  /**
   * 缁撴潫 PK
   */
  private finishPK(pk: FriendPK): void {
    pk.status = FriendPKStatus.FINISHED;
    pk.winner = pk.myReadingTime > pk.friendReadingTime ? 'me' : 'friend';

    // TODO: 鍙戦€佺粨鏋滈€氱煡
  }

  /**
   * 鑾峰彇杩涜�涓�殑 PK
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
  period: string;
  totalTime: number;
  totalBooks: number;
  favoriteBook: string;
  readingTrend: number[];
}

// 瀵煎嚭鍗曚緥
export const readingStatisticsManager = ReadingStatisticsManager.getInstance();
export const achievementManager = AchievementManager.getInstance();
export const friendPKManager = FriendPKManager.getInstance();
