// 阅读统计报告页面
import { router } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { readingStatsViewModel, ReadingStatsViewModel, TrendDataPoint, StatsPeriod } from '../viewmodels/ReadingStatsViewModel';
import { BookInfo, formatDuration } from '../models/CoreBookModel';
import { DeviceUtils } from '../utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';

@Entry
@Component
struct ReadingStatsPage {
  // UI 控制状态
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();

  // ViewModel
  vm: ReadingStatsViewModel = readingStatsViewModel;
  @State private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
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
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();

    await this.vm.loadStats();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * tabletMultiplier);
  }

  build() {
    Column() {
      // 顶部导航
      this.TopBar()

      Scroll() {
        Column({ space: 16 }) {
          // 总览卡片
          this.OverviewCard()

          // 连续阅读天数
          this.StreakCard()

          // 本周阅读趋势
          this.WeeklyChartCard()

          // 阅读分布
          this.DistributionCard()

          // 最近阅读
          this.RecentBooksCard()
        }
        .width('100%')
        .padding(this.isTablet ? 24 : 16)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F5F5F5', '#141414'))
  }

  @Builder
  TopBar() {
    Row() {
      Button() {
        Text('返回')
          .fontSize(20)
          .fontColor(this.tc('#333333', '#FFFFFF'))
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(255, 255, 255, 0.5)')
      .borderRadius(20)
      .onClick(() => {
        try {
          router.back();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          console.error('[ReadingStatsPage] back failed:', msg);
        }
      })

      Text('阅读报告')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(40)
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 8, right: this.isTablet ? 24 : 8 })
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
  }

  @Builder
  OverviewCard() {
    Column({ space: 16 }) {
      Text('阅读总览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .width('100%')

      Row({ space: 0 }) {
        this.StatItem('总阅读时长', formatDuration(this.vm.getTotalStats().totalReadingTime), '日', COMMON_COLORS.PRIMARY_BLUE)
        this.StatItem('今日阅读', formatDuration(this.vm.getTodayData().readingTime), '日', '#52C41A')
      }
      .width('100%')

      Row({ space: 0 }) {
        this.StatItem('本周阅读', formatDuration(this.vm.getWeekData().readingTime), '统计', '#FA8C16')
        this.StatItem('本月阅读', formatDuration(this.vm.getMonthData().readingTime), '趋势', '#722ED1')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
    .borderRadius(12)
  }

  @Builder
  StatItem(label: string, value: string, icon: string, color: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(24)

      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(12)
        .fontColor(this.tc('#999999', '#888888'))
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F8F8F8')
    .borderRadius(8)
  }

  @Builder
  StreakCard() {
    Column({ space: 12 }) {
      Row() {
        Text('🔥')
          .fontSize(24)

        Column({ space: 4 }) {
          Text('连续阅读 ' + this.vm.getCurrentStreak() + ' 天')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF4D4F')

          Text('保持阅读习惯，继续加油！')
            .fontSize(13)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF2F0')
    .borderRadius(12)
    .border({ width: 1, color: '#FFCCC7' })
  }

  @Builder
  WeeklyChartCard() {
    Column({ space: 16 }) {
      Row() {
        Text('阅读趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)

        // 周期切换按钮
        Row({ space: 8 }) {
          this.PeriodButton('周', 'week')
          this.PeriodButton('月', 'month')
          this.PeriodButton('年', 'year')
        }
      }
      .width('100%')

      // 柱状图
      Row({ space: 8 }) {
        ForEach(this.vm.getTrendData(), (value: TrendDataPoint, index: number) => {
          Column({ space: 4 }) {
            Column()
              .width(24)
              .height(value.minutes > 0 ? Math.max(20, (value.minutes / this.getMaxTrendValue()) * 100) : 4)
              .backgroundColor(value.minutes > 0 ? COMMON_COLORS.PRIMARY_BLUE : '#E8E8E8')
              .borderRadius(4)

            Text(this.getShortDateLabel(value.date))
              .fontSize(11)
              .fontColor(this.tc('#999999', '#888888'))
          }
          .layoutWeight(1)
          .height(120)
          .justifyContent(FlexAlign.End)
        }, (value: TrendDataPoint, index: number) => value.date)
      }
      .width('100%')
      .height(140)

      // 平均值
      Row() {
        Text('日均阅读: ' + this.getAvgDailyMinutes() + ' 分钟')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
    .borderRadius(12)
  }

  @Builder
  PeriodButton(label: string, period: StatsPeriod) {
    Button(label)
      .height(28)
      .fontSize(12)
      .fontColor(this.vm.getSelectedPeriod() === period ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
      .backgroundColor(this.vm.getSelectedPeriod() === period ? COMMON_COLORS.PRIMARY_BLUE : 'rgba(150, 150, 150, 0.1)')
      .borderRadius(14)
      .onClick(() => this.vm.setSelectedPeriod(period))
  }

  private getMaxTrendValue(): number {
    const data = this.vm.getTrendData();
    return data.reduce((max: number, val: TrendDataPoint) => val.minutes > max ? val.minutes : max, 1);
  }

  private getShortDateLabel(dateStr: string): string {
    // 简化日期显示
    if (dateStr.includes('-') && dateStr.split('-').length === 3) {
      const parts = dateStr.split('-');
      return parts[2]; // 只显示日期
    }
    return dateStr.substring(0, 5); // 月份
  }

  private getAvgDailyMinutes(): number {
    const data = this.vm.getTrendData();
    if (data.length === 0) return 0;
    const total = data.reduce((sum: number, item: TrendDataPoint) => sum + item.minutes, 0);
    return Math.floor(total / data.length);
  }

  @Builder
  DistributionCard() {
    Column({ space: 16 }) {
      Text('阅读分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .width('100%')

      Row({ space: 16 }) {
        // 书籍状态统计
        Column({ space: 8 }) {
          Text('📚')
            .fontSize(32)

          Text(this.vm.getTotalStats().totalBooks + ' 本')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))

          Text('总书籍')
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#F6FFED')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text('确定')
            .fontSize(32)

          Text(this.vm.getTotalStats().finishedBooks + ' 本')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#52C41A')

          Text('已读完')
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#F6FFED')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text('阅读')
            .fontSize(32)

          Text(this.vm.getTotalStats().readingDays + ' 天')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)

          Text('阅读天数')
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#E6F7FF')
        .borderRadius(8)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
    .borderRadius(12)
  }

  @Builder
  RecentBooksCard() {
    Column({ space: 12 }) {
      Row() {
        Text('最近阅读')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)

        Text('查看全部 >')
          .fontSize(13)
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .onClick(() => navigateTo('pages/ReadRecordPage'))
      }
      .width('100%')

      if (this.getRecentBooks().length === 0) {
        Text('暂无阅读记录')
          .fontSize(13)
          .fontColor(this.tc('#999999', '#888888'))
          .width('100%')
          .padding(20)
          .textAlign(TextAlign.Center)
      } else {
        Column({ space: 8 }) {
          ForEach(this.getRecentBooks(), (book: BookInfo) => {
            Row({ space: 12 }) {
              Column() {
                Text(book.title.charAt(0))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .width(40)
              .height(40)
              .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)

              Column({ space: 4 }) {
                Text(book.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.tc('#333333', '#FFFFFF'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Text('已读 ' + book.readProgress + '% 路 ' + formatDuration(book.totalReadTime || 0))
                  .fontSize(12)
                  .fontColor(this.tc('#999999', '#888888'))
                  .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('继续')
                .height(28)
                .fontSize(12)
                .backgroundColor('#E6F7FF')
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                .borderRadius(14)
                .onClick(() => {
  const navParams: Record<string, Object> = {};
  navParams['bookId'] = book.id;
  navigateTo('pages/EnhancedReaderPage', navParams);
})
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
          }, (book: BookInfo) => book.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
    .borderRadius(12)
  }

  private getRecentBooks(): BookInfo[] {
    return bookViewModel.getRecentBooks(5);
  }
}

// 阅读记录接口（补充）
