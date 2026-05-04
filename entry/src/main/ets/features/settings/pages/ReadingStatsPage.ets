import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { readingStatsViewModel, ReadingStatsViewModel, TrendDataPoint, StatsPeriod } from '../viewmodels/ReadingStatsViewModel';
import { BookInfo, formatDuration } from '../../../core/models/CoreBookModel';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct ReadingStatsPage {
  @Local isTablet: boolean = false;
  @Local isDarkMode: boolean = false;
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;

  vm: ReadingStatsViewModel = readingStatsViewModel;
  @Local private context: common.Context | null = null;

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

  build() {
    Column() {
      // 顶部导航栏
      this.TopBar()

      Scroll() {
        Column({ space: Spacing.lg }) {
          // 总览卡片 - 渐变背景
          this.OverviewCard()

          // 连续阅读天数 - 激励卡片
          this.StreakCard()

          // 阅读趋势图表
          this.WeeklyChartCard()

          // 阅读分布统计
          this.DistributionCard()

          // 最近阅读书籍
          this.RecentBooksCard()
        }
        .width('100%')
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg, 
          bottom: Spacing.xxxl 
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  TopBar() {
    Row() {
      // 返回按钮 - 带背景
      Row() {
        SymbolGlyph($r('sys.symbol.chevron.left'))
          .fontSize(Size.iconLG)
          .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[ReadingStatsPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Text('阅读报告')
        .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 22 : 18))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(Size.buttonMD)
    }
    .width('100%')
    .height(this.isTablet ? Size.buttonXL + Spacing.md : Size.buttonLG + Spacing.sm)
    .padding({ 
      left: Spacing.lg, 
      right: Spacing.lg,
      top: layoutHelper.getSafeTopPadding()
    })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  OverviewCard() {
    Column({ space: Spacing.lg }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chart.pie.fill'))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
        
        Text('阅读总览')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      // 统计数据网格 - 2x2布局
      Grid() {
        GridItem() {
          this.StatItem(
            'clock.fill', 
            '总阅读时长', 
            formatDuration(this.vm.getTotalStats().totalReadingTime), 
            COMMON_COLORS.PRIMARY_BLUE,
            'linear-gradient(135deg, #667EEA 0%, #764BA2 100%)'
          )
        }
        GridItem() {
          this.StatItem(
            'sun.max.fill', 
            '今日阅读', 
            formatDuration(this.vm.getTodayData().readingTime), 
            '#52C41A',
            'linear-gradient(135deg, #52C41A 0%, #73D13D 100%)'
          )
        }
        GridItem() {
          this.StatItem(
            'calendar.badge.clock', 
            '本周阅读', 
            formatDuration(this.vm.getWeekData().readingTime), 
            '#FA8C16',
            'linear-gradient(135deg, #FA8C16 0%, #FFC53D 100%)'
          )
        }
        GridItem() {
          this.StatItem(
            'chart.line.uptrend.xyaxis', 
            '本月阅读', 
            formatDuration(this.vm.getMonthData().readingTime), 
            '#722ED1',
            'linear-gradient(135deg, #722ED1 0%, #B37FEB 100%)'
          )
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(Spacing.md)
      .rowsGap(Spacing.md)
      .width('100%')
      .height(this.isTablet ? 220 : 200)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }

  @Builder
  StatItem(iconName: string, label: string, value: string, color: string, gradient: string) {
    Column({ space: Spacing.sm }) {
      // 图标容器 - 渐变色背景
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(this.isTablet ? Size.iconXXL : Size.iconXL)
          .fontColor(['#FFFFFF'])
      }
      .width(this.isTablet ? Size.avatarLG : Size.avatarMD)
      .height(this.isTablet ? Size.avatarLG : Size.avatarMD)
      .borderRadius(BorderRadius.lg)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [
          [color, 0.0],
          [color + 'CC', 1.0]
        ]
      })
      .justifyContent(FlexAlign.Center)
      .shadow({
        radius: 8,
        color: color + '40',
        offsetY: 4
      })

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(11))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(Spacing.sm)
    .backgroundColor(this.tc('rgba(0,0,0,0.02)', 'rgba(255,255,255,0.03)'))
    .borderRadius(BorderRadius.md)
  }

  @Builder
  StreakCard() {
    Row({ space: Spacing.lg }) {
      // 火焰图标 - 带动画效果
      Column() {
        SymbolGlyph($r('sys.symbol.flame.fill'))
          .fontSize(Size.iconXXXL)
          .fontColor(['#FF4D4F'])
      }
      .width(this.isTablet ? Size.avatarXL : Size.avatarLG)
      .height(this.isTablet ? Size.avatarXL : Size.avatarLG)
      .borderRadius(BorderRadius.full)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: ['#FFF2F0', '#FFCCC7']
      })
      .justifyContent(FlexAlign.Center)

      Column({ space: Spacing.xs }) {
        Text('连续阅读 ' + this.vm.getCurrentStreak() + ' 天')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF4D4F')

        Text('保持阅读习惯，继续加油！')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.xl)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: this.isDarkMode 
        ? [['rgba(255,77,79,0.15)', 0.0], ['rgba(255,77,79,0.05)', 1.0]]
        : [['#FFF2F0', 0.0], ['#FFFFFF', 1.0]]
    })
    .borderRadius(BorderRadius.xl)
    .border({ 
      width: 1.5, 
      color: this.isDarkMode ? 'rgba(255,77,79,0.3)' : '#FFCCC7' 
    })
    .shadow({
      radius: 12,
      color: 'rgba(255,77,79,0.15)',
      offsetY: 4
    })
  }

  @Builder
  WeeklyChartCard() {
    Column({ space: Spacing.lg }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chart.bar.xaxis'))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
        
        Text('阅读趋势')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        // 周期切换按钮
        Row({ space: Spacing.xs }) {
          this.PeriodButton('周', 'week')
          this.PeriodButton('月', 'month')
          this.PeriodButton('年', 'year')
        }
      }
      .width('100%')

      // 柱状图
      Row({ space: Spacing.sm }) {
        ForEach(this.vm.getTrendData(), (value: TrendDataPoint, index: number) => {
          Column({ space: Spacing.xs }) {
            // 柱子
            Column()
              .width('100%')
              .height(value.minutes > 0 
                ? Math.max(30, (value.minutes / this.getMaxTrendValue()) * 120) 
                : 4)
              .linearGradient({
                direction: GradientDirection.Top,
                colors: value.minutes > 0 
                  ? [
                      [COMMON_COLORS.PRIMARY_BLUE, 0.0], 
                      [COMMON_COLORS.PRIMARY_BLUE + '80', 1.0]
                    ]
                  : [
                      [this.tc('#E8E8E8', '#3A3A3C'), 0.0], 
                      [this.tc('#E8E8E8', '#3A3A3C'), 1.0]
                    ]
              })
              .borderRadius({ topLeft: 6, topRight: 6 })

            // 日期标签
            Text(this.getShortDateLabel(value.date))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .layoutWeight(1)
          .height(150)
          .justifyContent(FlexAlign.End)
        }, (value: TrendDataPoint, index: number) => value.date)
      }
      .width('100%')
      .height(170)
      .padding({ top: Spacing.sm })

      // 平均数据
      Row({ space: Spacing.xs }) {
        SymbolGlyph($r('sys.symbol.info.circle'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])
        
        Text('日均阅读: ' + this.getAvgDailyMinutes() + ' 分钟')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: Spacing.sm })
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }

  @Builder
  PeriodButton(label: string, period: StatsPeriod) {
    Button(label)
      .height(Size.buttonSM)
      .fontSize(fontScaleManager.getScaledFontSize(12))
      .fontColor(this.vm.getSelectedPeriod() === period 
        ? '#FFFFFF' 
        : this.tc('#8E8E93', '#8E8E93'))
      .backgroundColor(this.vm.getSelectedPeriod() === period 
        ? COMMON_COLORS.PRIMARY_BLUE 
        : this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .borderRadius(BorderRadius.xl)
      .onClick(() => this.vm.setSelectedPeriod(period))
      .stateStyles({
        pressed: { .scale({ x: 0.95, y: 0.95 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
  }

  private getMaxTrendValue(): number {
    const data = this.vm.getTrendData();
    return data.reduce((max: number, val: TrendDataPoint) => 
      val.minutes > max ? val.minutes : max, 1);
  }

  private getShortDateLabel(dateStr: string): string {
    if (dateStr.includes('-') && dateStr.split('-').length === 3) {
      const parts = dateStr.split('-');
      return parts[2];
    }
    return dateStr.substring(0, 5);
  }

  private getAvgDailyMinutes(): number {
    const data = this.vm.getTrendData();
    if (data.length === 0) return 0;
    const total = data.reduce((sum: number, item: TrendDataPoint) => 
      sum + item.minutes, 0);
    return Math.floor(total / data.length);
  }

  @Builder
  DistributionCard() {
    Column({ space: Spacing.lg }) {
      Row() {
        SymbolGlyph($r('sys.symbol.piechart.fill'))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
        
        Text('阅读分布')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      Row({ space: Spacing.md }) {
        // 总书籍数
        Column({ space: Spacing.sm }) {
          Column() {
            SymbolGlyph($r('sys.symbol.books.vertical.fill'))
              .fontSize(this.isTablet ? Size.iconXXXL : Size.iconXXL)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
          }
          .width(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .height(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .borderRadius(BorderRadius.lg)
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
          .justifyContent(FlexAlign.Center)

          Text(this.vm.getTotalStats().totalBooks + ' 本')
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

          Text('总藏书')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .layoutWeight(1)
        .padding(Spacing.md)
        .backgroundColor(this.tc('#F6FFED', 'rgba(82,196,26,0.1)'))
        .borderRadius(BorderRadius.lg)

        // 已读完
        Column({ space: Spacing.sm }) {
          Column() {
            SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
              .fontSize(this.isTablet ? Size.iconXXXL : Size.iconXXL)
              .fontColor(['#52C41A'])
          }
          .width(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .height(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .borderRadius(BorderRadius.lg)
          .backgroundColor('#52C41A15')
          .justifyContent(FlexAlign.Center)

          Text(this.vm.getTotalStats().finishedBooks + ' 本')
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor('#52C41A')

          Text('已读完')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .layoutWeight(1)
        .padding(Spacing.md)
        .backgroundColor(this.tc('#F6FFED', 'rgba(82,196,26,0.1)'))
        .borderRadius(BorderRadius.lg)

        // 阅读天数
        Column({ space: Spacing.sm }) {
          Column() {
            SymbolGlyph($r('sys.symbol.calendar.badge.clock'))
              .fontSize(this.isTablet ? Size.iconXXXL : Size.iconXXL)
              .fontColor(['#FA8C16'])
          }
          .width(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .height(this.isTablet ? Size.avatarXL : Size.avatarLG)
          .borderRadius(BorderRadius.lg)
          .backgroundColor('#FA8C1615')
          .justifyContent(FlexAlign.Center)

          Text(this.vm.getTotalStats().readingDays + ' 天')
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor('#FA8C16')

          Text('阅读天数')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .layoutWeight(1)
        .padding(Spacing.md)
        .backgroundColor(this.tc('#FFF7E6', 'rgba(250,140,22,0.1)'))
        .borderRadius(BorderRadius.lg)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }

  @Builder
  RecentBooksCard() {
    Column({ space: Spacing.lg }) {
      Row() {
        SymbolGlyph($r('sys.symbol.book.fill'))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
        
        Text('最近阅读')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        Text('查看全部')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => navigateTo('pages/ReadRecordPage'))
      }
      .width('100%')

      // 最近阅读列表（简化版）
      Column() {
        Text('暂无阅读记录')
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .padding(Spacing.xl)
      }
      .width('100%')
      .backgroundColor(this.tc('rgba(0,0,0,0.02)', 'rgba(255,255,255,0.03)'))
      .borderRadius(BorderRadius.md)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }
}

// 预览组件
@Preview
@ComponentV2
struct ReadingStatsPagePreview {
  build() {
    Column() {
      Text('阅读统计 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ReadingStatsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读统计 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ReadingStatsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
