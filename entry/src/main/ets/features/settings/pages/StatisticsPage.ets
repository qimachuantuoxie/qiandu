import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
// 闃呰�缁熻�椤甸潰 - 灞曠ず瀹屾暣缁熻�鏁版嵁


import { common } from '@kit.AbilityKit';
import { BookInfo } from '../core/models/CoreBookModel';
import { ReadingStatistics, AchievementBadge } from '../core/models/AdvancedReading';
import { readingStatisticsManager, achievementManager } from '../core/models/ReadingStats';
import { advancedNoteManager } from '../core/models/AdvancedReading';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, AppColors, COMMON_COLORS } from '../core/utils/AppTheme';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { CommonCard, CardType, EmptyState, EmptyStateType, CommonDivider } from '../components/common/CommonButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

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
    const context = this.getUIContext().getHostContext() as common.Context;
    await layoutHelper.init(context);
    this.screenInfo = layoutHelper.getScreenInfo();
    this.fontScale = await fontScaleManager.getFontScale();

    try {
      preferenceManager.init(context);
      appTheme.init(context);
    } catch (error) {
      logger.info('StatisticsPage context init skipped');
    }

    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
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
      // 杩斿洖鎸夐挳 - 浼樺寲鏍峰紡
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
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[StatisticsPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { scale: { x: 0.9, y: 0.9 } },
        normal: { scale: { x: 1, y: 1 } }
      })

      Text('闃呰�缁熻�')
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
        Text('chart_bar_fill 闃呰�姒傝�')
          .fontSize(this.isTablet ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        Grid() {
          GridItem() {
this.statItem('book_fill', '鎬讳功绫嶆暟', this.statistics.totalBooks + '锟?, COMMON_COLORS.PRIMARY_BLUE)
            }
            GridItem() {
              this.statItem('checkmark_circle_fill', '宸茶�锟?, this.statistics.finishedBooks + '锟?, COMMON_COLORS.SUCCESS_GREEN)
            }
            GridItem() {
              this.statItem('calendar', '闃呰�澶╂暟', this.statistics.readingDays + '锟?, '#FF6B6B')
            }
            GridItem() {
              this.statItem('stopwatch', '鎬绘椂锟?, Math.round(this.statistics.totalReadingTime / 60) + '灏忔椂', '#FA8C16')
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
      // 鍥炬爣瀹瑰櫒 - 甯︽笎鍙樿儗锟?
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
      Text('闃呰�鏃堕暱鍒嗗竷')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 16 }) {
        this.timeBlock('浠婃棩', this.statistics.todayReadingTime, '鍒嗛挓')
        this.timeBlock('鏈�懆', Math.round(this.statistics.weekReadingTime), '鍒嗛挓')
        this.timeBlock('鎬昏�', Math.round(this.statistics.totalReadingTime), '鍒嗛挓')
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
        Text('馃弲 鎴愬氨寰界珷 (' + this.badges.length + ')')
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
            title: '杩樻病鏈夎幏寰楀窘锟?,
            subtitle: '缁х画闃呰�瑙ｉ攣鏇村�鎴愬氨锟?',
            showButton: false
          })
        }
      }
    }
  }
  
@Builder
  notesCard() {
    Column({ space: 16 }) {
      Text('鎴戠殑绗旇�')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 16 }) {
        this.noteStatItem('note', '绗旇�', this.noteCount)
        this.noteStatItem('bookmark', '涔︾�', this.bookmarkCount)
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
      Text('鎺掕�锟?)
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
      
      Column() {
        Text('濂藉弸 PK 鍔熻兘寮€鍙戜腑...')
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

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct StatisticsPagePreview {
  build() {
    Column() {
      Text('闃呰�缁熻�锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      StatisticsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('闃呰�缁熻�锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      StatisticsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
