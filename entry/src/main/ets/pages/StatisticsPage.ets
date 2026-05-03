// 阅读统计页面 - 展示完整统计数据

import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BookInfo } from '../models/CoreBookModel';
import { ReadingStatistics, AchievementBadge } from '../models/AdvancedReading';
import { readingStatisticsManager, achievementManager } from '../models/ReadingStats';
import { advancedNoteManager } from '../models/AdvancedReading';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, AppColors, COMMON_COLORS } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';
import { CommonCard, CardType, EmptyState, EmptyStateType, CommonDivider } from '../components/common/CommonButton';

@Entry
@Component
struct StatisticsPage {
  @State statistics: ReadingStatistics = { totalBooks: 0, finishedBooks: 0, readingDays: 0, totalReadingTime: 0, todayReadingTime: 0, weekReadingTime: 0, totalWords: 0, totalNotes: 0, totalBookmarks: 0 };
  @State badges: AchievementBadge[] = [];
  @State noteCount: number = 0;
  @State bookmarkCount: number = 0;
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;

  aboutToAppear() {
    this.initData();
    this.initAsyncData();
  }

  private initData(): void {
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
  }

  private async initAsyncData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();

    try {
      const context: common.Context = this.getUIContext().getHostContext() as common.Context;
      preferenceManager.init(context);
      appTheme.init(context);
    } catch (error) {
      console.info('StatisticsPage context init skipped');
    }

    this.statistics = readingStatisticsManager.getFullStatistics();
    this.badges = achievementManager.getUnlockedBadges();
    const noteStats = advancedNoteManager.countNotes();
    this.noteCount = noteStats.notes + noteStats.highlights;
    this.bookmarkCount = noteStats.total;
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }
  
  build() {
    Column() {
this.TopBar()
      
      Scroll() {
        Column({ space: 24 }) {
          this.statOverviewCard()
          
          this.timeDistributionCard()
          
          this.badgeCard()
          
          this.notesCard()
          
          this.rankingCard()
        }
        .width('100%')
        .padding(this.isTablet ? 24 : 16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentColors.background)
  }
  
  @Builder
  TopBar() {
    Row() {
      // 返回按钮 - 优化样式
      Row() {
        Text('arrow_left')
          .fontSize(20)
          .fontColor(this.currentColors.textPrimary)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try {
          router.back();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          console.error('[StatisticsPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { scale: { x: 0.9, y: 0.9 } },
        normal: { scale: { x: 1, y: 1 } }
      })

      Text('阅读统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
.backgroundColor(this.currentColors.cardBackground)
  }
  
  @Builder
  statOverviewCard() {
    CommonCard({
      type: CardType.ELEVATED,
      isDarkMode: this.isDarkMode,
      cornerRadius: 16,
      containerPadding: this.isTablet ? 30 : 20
    }) {
      Column({ space: 16 }) {
        Text('chart_bar_fill 阅读概览')
          .fontSize(this.isTablet ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        Grid() {
          GridItem() {
this.statItem('book_fill', '总书籍数', this.statistics.totalBooks + '本', COMMON_COLORS.PRIMARY_BLUE)
            }
            GridItem() {
              this.statItem('checkmark_circle_fill', '已读完', this.statistics.finishedBooks + '本', COMMON_COLORS.SUCCESS_GREEN)
            }
            GridItem() {
              this.statItem('calendar', '阅读天数', this.statistics.readingDays + '天', '#FF6B6B')
            }
            GridItem() {
              this.statItem('stopwatch', '总时长', Math.round(this.statistics.totalReadingTime / 60) + '小时', '#FA8C16')
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(16)
        .columnsGap(16)
      }
    }
  }

  @Builder
  statItem(icon: string, label: string, value: string, color: string) {
    Column({ space: 8 }) {
      // 图标容器 - 带渐变背景
      Column() {
        Text(icon)
          .fontSize(this.isTablet ? 34 : 28)
      }
      .width(this.isTablet ? 56 : 48)
      .height(this.isTablet ? 56 : 48)
      .borderRadius(14)
      .backgroundColor(color + '15')
      .justifyContent(FlexAlign.Center)

      Text(value)
        .fontSize(this.isTablet ? 24 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(this.isTablet ? 14 : 12)
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
    .borderRadius(12)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
  }
  
  @Builder
  timeDistributionCard() {
    Column({ space: 16 }) {
      Text('阅读时长分布')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 16 }) {
        this.timeBlock('今日', this.statistics.todayReadingTime, '分钟')
        this.timeBlock('本周', Math.round(this.statistics.weekReadingTime), '分钟')
        this.timeBlock('总计', Math.round(this.statistics.totalReadingTime), '分钟')
      }
      .width('100%')
    }
    .width('100%')
    .padding(this.isTablet ? 30 : 20)
    .borderRadius(16)
    .backgroundColor(this.currentColors.cardBackground)
  }
  
  @Builder
  timeBlock(label: string, value: number, unit: string) {
    Column({ space: 8 }) {
      Text(value + unit)
        .fontSize(this.isTablet ? 29 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.primary)
      
      Text(label)
        .fontSize(this.isTablet ? 14 : 12)
        .fontColor(this.currentColors.textSecondary)
    }
    .layoutWeight(1)
    .padding(this.isTablet ? 24 : 16)
    .borderRadius(12)
    .backgroundColor(this.currentColors.background)
  }
  
  @Builder
  badgeCard() {
    CommonCard({
      type: CardType.ELEVATED,
      isDarkMode: this.isDarkMode,
      cornerRadius: 16,
      containerPadding: this.isTablet ? 30 : 20
    }) {
      Column({ space: 16 }) {
        Text('🏅 成就徽章 (' + this.badges.length + ')')
          .fontSize(this.isTablet ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        if (this.badges.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            ForEach(this.badges, (badge: AchievementBadge) => {
              Column({ space: 8 }) {
                Text(badge.icon)
                  .fontSize(this.isTablet ? 38 : 32)

                Text(badge.name)
                  .fontSize(this.isTablet ? 14 : 12)
                  .fontColor(this.currentColors.textPrimary)
              }
              .width('25%')
              .padding(this.isTablet ? 18 : 12)
            }, (badge: AchievementBadge) => badge.id)
          }
          .width('100%')
        } else {
          EmptyState({
            type: EmptyStateType.DATA,
            isDarkMode: this.isDarkMode,
            icon: 'trophy_fill',
            title: '还没有获得徽章',
            subtitle: '继续阅读解锁更多成就吧!',
            showButton: false
          })
        }
      }
    }
  }
  
@Builder
  notesCard() {
    Column({ space: 16 }) {
      Text('我的笔记')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 16 }) {
        this.noteStatItem('note', '笔记', this.noteCount)
        this.noteStatItem('bookmark', '书签', this.bookmarkCount)
      }
      .width('100%')
    }
    .width('100%')
    .padding(this.isTablet ? 30 : 20)
    .borderRadius(16)
    .backgroundColor(this.currentColors.cardBackground)
  }
  
  @Builder
  noteStatItem(icon: string, label: string, count: number) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(this.isTablet ? 34 : 28)
      
      Text(count.toString())
        .fontSize(this.isTablet ? 29 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.primary)
      
      Text(label)
        .fontSize(this.isTablet ? 14 : 12)
        .fontColor(this.currentColors.textSecondary)
    }
    .layoutWeight(1)
    .padding(this.isTablet ? 24 : 16)
    .borderRadius(12)
    .backgroundColor(this.currentColors.background)
  }
  
  @Builder
  rankingCard() {
    Column({ space: 16 }) {
      Text('排行榜')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Column() {
        Text('好友 PK 功能开发中...')
          .fontSize(this.isTablet ? 17 : 14)
          .fontColor(this.currentColors.textSecondary)
      }
      .width('100%')
      .padding(40)
    }
    .width('100%')
    .padding(this.isTablet ? 30 : 20)
    .borderRadius(16)
    .backgroundColor(this.currentColors.cardBackground)
  }
  
  scaleFontSize(baseSize: number): number {
    return Math.round(baseSize * this.fontScale);
  }
}
