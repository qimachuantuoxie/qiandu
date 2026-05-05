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
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

enum TabType {
  ALL = '全部',
  READING = '阅读中',
  FINISHED = '已读完'
}

@Entry
@ComponentV2
struct ReadRecordPage {
  @Local currentTab: TabType = TabType.ALL;
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
    const allBooks = bookViewModel.getAllBooks();
    
    switch (this.currentTab) {
      case TabType.READING:
        this.books = allBooks.filter(book => book.readStatus !== 2);
        break;
      case TabType.FINISHED:
        this.books = allBooks.filter(book => book.readStatus === 2);
        break;
      default:
        this.books = allBooks;
        break;
    }
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

  build() {
    Column() {
      // 顶部导航栏
      PageHeader({
        title: '阅读记录',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[ReadRecordPage] back failed:', msg);
          }
        }
      })

      // 统计卡片
      this.StatCards()

      // Tab切换
      this.TabBar()

      // 书籍列表
      if (this.books.length === 0) {
        this.EmptyState()
      } else {
        List({ space: HDSSpacing.md }) {
          ForEach(this.books, (book: BookInfo) => {
            ListItem() {
              this.BookItem(book)
            }
          }, (book: BookInfo) => book.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg,
          top: HDSSpacing.md,
          bottom: HDSSpacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  StatCards() {
    HDSCard({
      padding: HDSSpacing.lg,
      content: () => {
        Row({ space: HDSSpacing.md }) {
          // 今日阅读
          this.StatCard('今日阅读', formatDuration(this.getTodayReadingTime()), 'clock.fill', HDSColours.primary.blue)
          
          // 累计阅读
          this.StatCard('累计阅读', formatDuration(this.getTotalReadingTime()), 'book.fill', '#4CAF50')
          
          // 阅读书籍
          this.StatCard('阅读书籍', this.getTotalReadBooks().toString(), 'bookmark.fill', '#FF9800')
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
  TabBar() {
    Scroll() {
      Row({ space: HDSSpacing.sm }) {
        ForEach(Object.values(TabType), (tab: TabType) => {
          Text(tab)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .padding({ 
              left: HDSSpacing.lg, 
              right: HDSSpacing.lg, 
              top: HDSSpacing.sm, 
              bottom: HDSSpacing.sm 
            })
            .backgroundColor(this.currentTab === tab ? 
              HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.surface : '#F2F2F7'))
            .fontColor(this.currentTab === tab ? 
              HDSColours.neutral.white : (this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900))
            .borderRadius(HDSBorderRadius.xl)
            .fontWeight(this.currentTab === tab ? 
              FontWeight.Medium : FontWeight.Regular)
            .onClick(() => { 
              this.currentTab = tab;
              this.loadBooks();
            })
        }, (tab: TabType) => tab)
      }
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg })
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  BookItem(book: BookInfo) {
    Row({ space: HDSSpacing.lg }) {
      // 封面
      Stack() {
        if (book.coverPath) {
          Image(book.coverPath)
            .width(this.screenInfo?.isTablet ? 70 : 60)
            .height(this.screenInfo?.isTablet ? 95 : 80)
            .borderRadius(HDSBorderRadius.md)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.book.fill'))
              .fontSize(24)
              .fontColor([HDSColours.primary.blue])
          }
          .width(this.screenInfo?.isTablet ? 70 : 60)
          .height(this.screenInfo?.isTablet ? 95 : 80)
          .borderRadius(HDSBorderRadius.md)
          .backgroundColor(HDSColours.primary.blue + '15')
          .justifyContent(FlexAlign.Center)
        }

        // 进度标签
        if (book.progress && book.progress > 0) {
          Text(`${book.progress}%`)
            .fontSize(fontScaleManager.getScaledFontSize(10))
            .fontWeight(FontWeight.Medium)
            .fontColor(HDSColours.neutral.white)
            .padding({ 
              left: HDSSpacing.sm, 
              right: HDSSpacing.sm, 
              top: HDSSpacing.xs, 
              bottom: HDSSpacing.xs 
            })
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(HDSBorderRadius.xl)
            .position({ bottom: 5, right: 5 })
        }
      }

      // 信息
      Column({ space: HDSSpacing.sm }) {
        Text(book.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.screenInfo?.isTablet ? 16 : 15))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(book.author)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: HDSSpacing.sm }) {
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(12)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            
            Text(formatDuration(book.totalReadingTime || 0))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          }

          if (book.readStatus === 2) {
            Row({ space: HDSSpacing.xs }) {
              SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
                .fontSize(12)
                .fontColor(['#52C41A'])
              
              Text('已读完')
                .fontSize(fontScaleManager.getScaledFontSize(11))
                .fontColor('#52C41A')
            }
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头
      SymbolGlyph($r('sys.symbol.chevron.right'))
        .fontSize(Size.iconSM)
        .fontColor([this.tc('#C7C7CC', '#48484A')])
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .onClick(() => {
      const params: Record<string, string> = {};
      params['bookId'] = book.id;
      navigateTo('pages/EnhancedReaderPage', params);
    })
    .stateStyles({
      pressed: { 
        .scale({ x: 0.98, y: 0.98 }),
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .scale({ x: 1, y: 1 }),
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      }
    })
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.book.closed'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无阅读记录')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('开始阅读第一本书吧')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

// 预览组件
@Preview
@ComponentV2
struct ReadRecordPagePreview {
  build() {
    Column() {
      Text('阅读记录 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ReadRecordPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读记录 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ReadRecordPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
