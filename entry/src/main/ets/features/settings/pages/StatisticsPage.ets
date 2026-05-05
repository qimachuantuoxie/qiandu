import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { BookInfo, formatDuration } from '../../../core/models/CoreBookModel';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

@Entry
@ComponentV2
struct StatisticsPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local books: BookInfo[] = [];
  private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.loadBooks();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await fontScaleManager.init(this.context);
    }
    DeviceUtils.init();
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private loadBooks(): void {
    this.books = bookViewModel.getAllBooks();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private getTotalReadingTime(): number {
    return this.books.reduce((total: number, book: BookInfo) => 
      total + (book.totalReadingTime || 0), 0);
  }

  private getTotalReadBooks(): number {
    return this.books.filter(book => book.readStatus === 2).length;
  }

  private getAverageReadingTime(): number {
    const readingBooks = this.books.filter(book => book.totalReadingTime && book.totalReadingTime > 0);
    if (readingBooks.length === 0) return 0;
    return Math.floor(
      readingBooks.reduce((total: number, book: BookInfo) => 
        total + (book.totalReadingTime || 0), 0) / readingBooks.length
    );
  }

  build() {
    Column() {
      // 顶部导航栏
      PageHeader({
        title: '阅读统计',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[StatisticsPage] back failed:', msg);
          }
        }
      })

      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          // 核心数据卡片
          this.CoreStats()

          // 阅读趋势
          this.ReadingTrend()

          // 阅读偏好
          this.ReadingPreference()

          // 成就徽章
          this.Achievements()
        }
        .width('100%')
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg,
          top: HDSSpacing.md,
          bottom: HDSSpacing.xxxl
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  CoreStats() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Text('核心数据')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .width('100%')

          Row({ space: HDSSpacing.md }) {
            // 总阅读时长
            this.StatCard('总阅读时长', formatDuration(this.getTotalReadingTime()), 'clock.fill', HDSColours.primary.blue)
            
            // 已读书籍
            this.StatCard('已读书籍', `${this.getTotalReadBooks()}本`, 'book.fill', '#4CAF50')
          }
          .width('100%')

          Row({ space: HDSSpacing.md }) {
            // 平均阅读时长
            this.StatCard('平均每本', formatDuration(this.getAverageReadingTime()), 'chart.bar.xaxis', '#FF9800')
            
            // 藏书数量
            this.StatCard('藏书总数', `${this.books.length}本`, 'folder.fill', '#9C27B0')
          }
          .width('100%')
        }
      }
    })
  }

  @Builder
  StatCard(title: string, value: string, iconName: string, color: string) {
    Column({ space: HDSSpacing.sm }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(28)
        .fontColor([color])

      Text(value)
        .fontSize(HDSTypography.sizes.xxl)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Text(title)
        .fontSize(HDSTypography.sizes.sm)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
    }
    .layoutWeight(1)
    .padding(HDSPacing.md)
    .backgroundColor(color + '15')
    .borderRadius(HDSBorderRadius.lg)
  }

  @Builder
  ReadingTrend() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Row() {
            SymbolGlyph($r("sys.symbol.chart.line.uptrend.xyaxis"))
              .fontSize(20)
              .fontColor([HDSColours.primary.blue])
            
            Text("阅读趋势")
              .fontSize(HDSTypography.sizes.xl)
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .layoutWeight(1)
              .margin({ left: HDSSpacing.sm })
          }
          .width("100%")

          if (this.books.length === 0) {
            Column() {
              Text("暂无阅读数据")
                .fontSize(HDSTypography.sizes.md)
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                .width("100%")
                .textAlign(TextAlign.Center)
                .margin({ top: HDSSpacing.xl })
            }
            .width("100%")
            .height(150)
            .padding({ top: HDSSpacing.lg })
          } else {
            // Simple bar chart using real data
            Row() {
              ForEach(["周一", "周二", "周三", "周四", "周五", "周六", "周日"], (day: string, index: number) => {
                Column() {
                  // Use real reading time from books
                  const book = this.books[index % this.books.length];
                  const height = Math.min(120, Math.max(30, (book.totalReadingTime || 0) / 60000));
                  Column()
                    .width("100%")
                    .height(height)
                    .linearGradient({
                      direction: GradientDirection.Top,
                      colors: [HDSColours.primary.blue, HDSColours.primary.blue + "CC"]
                    })
                    .borderRadius(HDSBorderRadius.sm)
                }
                .width("100%")
                .alignItems(VerticalAlign.Bottom)
                .margin({ bottom: HDSSpacing.sm })

                Text("周" + day)
                  .fontSize(HDSTypography.sizes.xs)
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                  .margin({ top: HDSSpacing.xs })
              }, (day: string, index: number) => index.toString())
            }
            .width("100%")
            .height(150)
            .padding({ top: HDSSpacing.lg })
          }
        }
      }
    })
  }

  @Builder
  ReadingPreference() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Row() {
            SymbolGlyph($r('sys.symbol.piechart'))
              .fontSize(20)
              .fontColor([HDSColours.primary.blue])
            
            Text('阅读偏好')
              .fontSize(HDSTypography.sizes.xl)
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .layoutWeight(1)
              .margin({ left: HDSSpacing.sm })
          }
          .width('100%')

          // 格式分布
          Column({ space: HDSSpacing.md }) {
            Text('书籍格式')
              .fontSize(HDSTypography.sizes.md)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .width('100%')

            this.PreferenceBar('EPUB', this.getFormatCount('epub'), '#4CAF50')
            this.PreferenceBar('PDF', this.getFormatCount('pdf'), '#F44336')
            this.PreferenceBar('TXT', this.getFormatCount('txt'), '#2196F3')
            this.PreferenceBar('其他', this.getFormatCount('other'), '#FF9800')
          }
          .width('100%')
        }
      }
    })
  }

  @Builder
  PreferenceBar(label: string, count: number, color: string) {
    const total = this.books.length || 1;
    const percentage = Math.floor(count / total * 100);

    Row({ space: HDSSpacing.md }) {
      Text(label)
        .fontSize(HDSTypography.sizes.sm)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .width(50)

      Progress({ value: count, total: total, type: ProgressType.Linear })
        .layoutWeight(1)
        .height(8)
        .borderRadius(HDSBorderRadius.xl)
        .color(color)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)')

      Text(`${count}本 (${percentage}%)`)
        .fontSize(HDSTypography.sizes.sm)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        .width(80)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  private getFormatCount(format: string): number {
    if (format === 'other') {
      return this.books.filter(book => 
        !['epub', 'pdf', 'txt'].includes((book.format || '').toLowerCase())
      ).length;
    }
    return this.books.filter(book => 
      (book.format || '').toLowerCase() === format
    ).length;
  }

  @Builder
  Achievements() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Row() {
            SymbolGlyph($r('sys.symbol.trophy.fill'))
              .fontSize(20)
              .fontColor(['#FFD700'])
            
            Text('成就徽章')
              .fontSize(HDSTypography.sizes.xl)
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .layoutWeight(1)
              .margin({ left: HDSSpacing.sm })
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            this.AchievementBadge('初次阅读', 'book.fill', '#4CAF50', true)
            this.AchievementBadge('阅读达人', 'clock.fill', '#2196F3', this.getTotalReadingTime() > 3600000)
            this.AchievementBadge('博览群书', 'books.vertical.fill', '#9C27B0', this.getTotalReadBooks() >= 10)
            this.AchievementBadge('坚持阅读', 'calendar.badge.clock', '#FF9800', this.books.some(b => b.lastReadTime && Date.now() - b.lastReadTime < 86400000))
          }
          .width('100%')
        }
      }
    })
  }

  @Builder
  AchievementBadge(name: string, iconName: string, color: string, unlocked: boolean) {
    Column({ space: HDSSpacing.sm }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(24)
        .fontColor([unlocked ? color : (this.isDarkMode ? '#48484A' : '#D1D1D6')])

      Text(name)
        .fontSize(HDSTypography.sizes.xs)
        .fontColor(unlocked ? color : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('30%')
    .padding(HDSPacing.md)
    .backgroundColor(unlocked ? color + '15' : (this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)'))
    .borderRadius(HDSBorderRadius.lg)
    .border({ 
      width: 1, 
      color: unlocked ? color + '40' : 'transparent' 
    })
    .margin({ right: Spacing.md, bottom: Spacing.md })
  }
}

// 预览组件
@Preview
@ComponentV2
struct StatisticsPagePreview {
  build() {
    Column() {
      Text('阅读统计 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      StatisticsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读统计 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      StatisticsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
