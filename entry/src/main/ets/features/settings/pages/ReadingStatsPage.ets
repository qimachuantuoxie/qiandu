import { logger } from '../../../common/utils/Logger';
// 闃呰�缁熻�鎶ュ憡椤甸潰

import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { readingStatsViewModel, ReadingStatsViewModel, TrendDataPoint, StatsPeriod } from '../viewmodels/ReadingStatsViewModel';
import { BookInfo, formatDuration } from '../core/models/CoreBookModel';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct ReadingStatsPage {
  // UI 鎺у埗鐘讹拷?
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  @State screenInfo: ScreenInfo | null = null;

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
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

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
      // 椤堕儴瀵艰埅
      this.TopBar()

      Scroll() {
        Column({ space: 16 }) {
          // 鎬昏�鍗＄墖
          this.OverviewCard()

          // 杩炵画闃呰�澶╂暟
          this.StreakCard()

          // 鏈�懆闃呰�瓒嬪娍
          this.WeeklyChartCard()

          // 闃呰�鍒嗗竷
          this.DistributionCard()

          // 鏈€杩戦槄锟?
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
        Text('杩斿洖')
          .fontSize(20)
          .fontColor(this.tc('#333333', '#FFFFFF'))
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(255, 255, 255, 0.5)')
      .borderRadius(20)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[ReadingStatsPage] back failed:', msg);
        }
      })

      Text('闃呰�鎶ュ憡')
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
      Text('闃呰�鎬昏�')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .width('100%')

      Row({ space: 0 }) {
        this.StatItem('鎬婚槄璇绘椂锟?, formatDuration(this.vm.getTotalStats().totalReadingTime), '锟?, COMMON_COLORS.PRIMARY_BLUE)
        this.StatItem('浠婃棩闃呰�', formatDuration(this.vm.getTodayData().readingTime), '锟?, '#52C41A')
      }
      .width('100%')

      Row({ space: 0 }) {
        this.StatItem('鏈�懆闃呰�', formatDuration(this.vm.getWeekData().readingTime), '缁熻�', '#FA8C16')
        this.StatItem('鏈�湀闃呰�', formatDuration(this.vm.getMonthData().readingTime), '瓒嬪娍', '#722ED1')
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
        Text('馃敟')
          .fontSize(24)

        Column({ space: 4 }) {
          Text('杩炵画闃呰� ' + this.vm.getCurrentStreak() + ' 锟?)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF4D4F')

          Text('淇濇寔闃呰�涔犳儻锛岀户缁�姞娌癸紒')
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
        Text('闃呰�瓒嬪娍')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)

        // 鍛ㄦ湡鍒囨崲鎸夐挳
        Row({ space: 8 }) {
          this.PeriodButton('锟?, 'week')
          this.PeriodButton('锟?, 'month')
          this.PeriodButton('锟?, 'year')
        }
      }
      .width('100%')

      // 鏌辩姸锟?
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

      // 骞冲潎锟?
      Row() {
        Text('鏃ュ潎闃呰�: ' + this.getAvgDailyMinutes() + ' 鍒嗛挓')
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
    // 绠€鍖栨棩鏈熸樉锟?
    if (dateStr.includes('-') && dateStr.split('-').length === 3) {
      const parts = dateStr.split('-');
      return parts[2]; // 鍙�樉绀烘棩锟?
    }
    return dateStr.substring(0, 5); // 鏈堜唤
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
      Text('闃呰�鍒嗗竷')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .width('100%')

      Row({ space: 16 }) {
        // 涔︾睄鐘舵€佺粺锟?
        Column({ space: 8 }) {
          Text('馃摎')
            .fontSize(32)

          Text(this.vm.getTotalStats().totalBooks + ' 锟?)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))

          Text('鎬讳功锟?)
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#F6FFED')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text('纭�畾')
            .fontSize(32)

          Text(this.vm.getTotalStats().finishedBooks + ' 锟?)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#52C41A')

          Text('宸茶�锟?)
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .layoutWeight(1)
        .padding(12)
        .backgroundColor('#F6FFED')
        .borderRadius(8)

        Column({ space: 8 }) {
          Text('闃呰�')
            .fontSize(32)

          Text(this.vm.getTotalStats().readingDays + ' 锟?)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)

          Text('闃呰�澶╂暟')
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
        Text('鏈€杩戦槄锟?)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)

        Text('鏌ョ湅鍏ㄩ儴 >')
          .fontSize(13)
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .onClick(() => navigateTo('pages/ReadRecordPage'))
      }
      .width('100%')

      if (this.getRecentBooks().length === 0) {
        Text('鏆傛棤闃呰�璁板綍')
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

                Text('宸茶� ' + book.readProgress + '% 锟?' + formatDuration(book.totalReadTime || 0))
                  .fontSize(12)
                  .fontColor(this.tc('#999999', '#888888'))
                  .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('缁х画')
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

// 闃呰�璁板綍鎺ュ彛锛堣ˉ鍏咃級
