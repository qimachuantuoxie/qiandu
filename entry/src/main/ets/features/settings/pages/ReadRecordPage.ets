import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { BookInfo, formatDuration } from '../core/models/CoreBookModel';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
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
      Row() {
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
            logger.error('[ReadRecordPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('阅读记录')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(Size.buttonMD)
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // 统计卡片
      this.StatCards()

      // Tab切换
      this.TabBar()

      // 书籍列表
      if (this.books.length === 0) {
        this.EmptyState()
      } else {
        List({ space: Spacing.md }) {
          ForEach(this.books, (book: BookInfo) => {
            ListItem() {
              this.BookItem(book)
            }
          }, (book: BookInfo) => book.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg,
          top: Spacing.md,
          bottom: Spacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  StatCards() {
    Row({ space: Spacing.md }) {
      // 今日阅读
      this.StatCard('今日阅读', formatDuration(this.getTodayReadingTime()), 'clock.fill', this.currentColors.primary)
      
      // 累计阅读
      this.StatCard('累计阅读', formatDuration(this.getTotalReadingTime()), 'book.fill', '#4CAF50')
      
      // 阅读书籍
      this.StatCard('阅读书籍', this.getTotalReadBooks().toString(), 'bookmark.fill', '#FF9800')
    }
    .width('100%')
    .padding(Spacing.lg)
  }

  @Builder
  StatCard(title: string, value: string, iconName: string, color: string) {
    Column({ space: Spacing.sm }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(this.screenInfo?.isTablet ? Size.iconXXL : Size.iconXL)
        .fontColor([color])

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(this.screenInfo?.isTablet ? 20 : 18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text(title)
        .fontSize(fontScaleManager.getScaledFontSize(12))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .layoutWeight(1)
    .padding(Spacing.md)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.lg)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  private getTodayReadingTime(): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return this.books.reduce((total: number, book: BookInfo) => {
      if (book.lastReadTime && book.lastReadTime >= today.getTime()) {
        return total + (book.todayReadingTime || 0);
      }
      return total;
    }, 0);
  }

  @Builder
  TabBar() {
    Scroll() {
      Row({ space: Spacing.sm }) {
        ForEach(Object.values(TabType), (tab: TabType) => {
          Text(tab)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .padding({ 
              left: Spacing.lg, 
              right: Spacing.lg, 
              top: Spacing.sm, 
              bottom: Spacing.sm 
            })
            .backgroundColor(this.currentTab === tab ? 
              this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
            .fontColor(this.currentTab === tab ? 
              '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .fontWeight(this.currentTab === tab ? 
              FontWeight.Medium : FontWeight.Regular)
            .onClick(() => { 
              this.currentTab = tab;
              this.loadBooks();
            })
            .stateStyles({
              pressed: { .scale({ x: 0.95, y: 0.95 }) },
              normal: { .scale({ x: 1, y: 1 }) }
            })
        }, (tab: TabType) => tab)
      }
      .padding({ left: Spacing.lg, right: Spacing.lg })
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  BookItem(book: BookInfo) {
    Row({ space: Spacing.lg }) {
      // 封面
      Stack() {
        if (book.coverPath) {
          Image(book.coverPath)
            .width(this.screenInfo?.isTablet ? 70 : 60)
            .height(this.screenInfo?.isTablet ? 95 : 80)
            .borderRadius(BorderRadius.md)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.book.fill'))
              .fontSize(Size.iconXL)
              .fontColor([this.currentColors.primary])
          }
          .width(this.screenInfo?.isTablet ? 70 : 60)
          .height(this.screenInfo?.isTablet ? 95 : 80)
          .borderRadius(BorderRadius.md)
          .backgroundColor(this.currentColors.primary + '15')
          .justifyContent(FlexAlign.Center)
        }

        // 进度标签
        if (book.progress && book.progress > 0) {
          Text(`${book.progress}%`)
            .fontSize(fontScaleManager.getScaledFontSize(10))
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .padding({ 
              left: Spacing.sm, 
              right: Spacing.sm, 
              top: Spacing.xs, 
              bottom: Spacing.xs 
            })
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(BorderRadius.xl)
            .position({ bottom: 5, right: 5 })
        }
      }

      // 信息
      Column({ space: Spacing.sm }) {
        Text(book.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.screenInfo?.isTablet ? 16 : 15))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(book.author)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: Spacing.sm }) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(Size.iconXS)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text(formatDuration(book.totalReadingTime || 0))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }

          if (book.readStatus === 2) {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
                .fontSize(Size.iconXS)
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
