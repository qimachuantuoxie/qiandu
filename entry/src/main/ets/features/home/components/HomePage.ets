// 首页组件 - 展示阅读进度、快捷入口、最近添�?
import { navigateTo } from '../../../common/utils/NavigationHelper';
import { BookInfo } from '../../../core/models/CoreBookModel';
import { CommonHeader } from '../../../common/components/CommonHeader';
import { AppCard, ElevationLevel } from '../../components/cards/AppCard';

interface ShortcutItem {
  icon: string;
  title: string;
  color: string;
  url: string;
}

@Component
export struct HomeContent {
  @Prop recentBooks: BookInfo[] = [];
  @Prop isDarkMode: boolean = false;
  onBookClick?: (book: BookInfo) => void;
  onOpenFilePicker?: () => void;

  private readonly shortcuts: ShortcutItem[] = [
    { icon: 'chart_bar_fill', title: '阅读统计', color: '#007DFF', url: 'features/StatisticsPage' },
    { icon: 'pencil', title: '待办事项', color: '#FF6B6B', url: 'features/TodoPage' },
    { icon: 'book_fill', title: '阅读记录', color: '#52C41A', url: 'features/ReadRecordPage' },
    { icon: 'bookmark_fill', title: '书签', color: '#FA8C16', url: 'features/BookmarksPage' },
    { icon: 'pencil', title: '笔记', color: '#722ED1', url: 'features/NotesPage' },
    { icon: 'globe_asia_australia_fill', title: '在线书源', color: '#13C2C2', url: 'features/OnlineSourceMarketPage' },
    { icon: 'gear', title: '阅读设置', color: '#EB2F96', url: 'features/SettingsPage' }
  ];

  private getFormatIcon(format: string): string {
    const formatIcons: Record<string, string> = {
      'PDF': 'doc_plaintext',
      'EPUB': 'book',
      'MOBI': 'ipad',
      'TXT': 'pencil',
      'DOCX': 'doc_richtext',
      'DOC': 'doc_richtext'
    };
    return formatIcons[format] || 'book_fill';
  }

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Column() {
      // 顶部导航�?
      this.HeaderBar()

      // 主内容区
      this.MainContent()
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F7')
  }

  @Builder
  HeaderBar() {
    CommonHeader({
      title: '千读阅界',
      isDarkMode: this.isDarkMode,
      showBack: false,
      rightActions: [
        { icon: 'bell', tooltip: '通知', action: () => {} },
        { icon: 'plus', tooltip: '添加书籍', action: () => {
          if (this.onOpenFilePicker) {
            this.onOpenFilePicker();
          }
        }}
      ]
    })
  }

  @Builder
  MainContent() {
    Scroll() {
      Column({ space: Spacing.md }) {
        // 继续阅读
        this.RecentBooksCard()

        // 快捷入口
        this.ShortcutsCard()

        // 阅读统计
        this.ReadingStatsCard()
      }
      .width('100%')
      .padding({ 
        left: layoutHelper.getResponsiveSpacing(), 
        right: layoutHelper.getResponsiveSpacing(), 
        top: Spacing.lg, 
        bottom: Spacing.xxxl 
      })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  RecentBooksCard() {
    AppCard({
      content: () => {
        Column({ space: Spacing.sm }) {
          Row() {
            Text('继续阅读')
              .fontSize(layoutHelper.getResponsiveFontSize(18))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
              .layoutWeight(1)
        
            Text('查看全部 >')
              .fontSize(layoutHelper.getResponsiveFontSize(12))
              .fontColor('#007DFF')
          }
          .width('100%')
        
          if (this.recentBooks.length > 0) {
            this.RecentBooksList()
          }
          if (this.recentBooks.length === 0) {
            this.EmptyStateView()
          }
        }
        .width('100%')
      },
      elevation: ElevationLevel.MD,
      isDarkMode: this.isDarkMode,
      padding: 16,
      marginBottom: 0
    })
  }

  @Builder
  RecentBooksList() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.recentBooks, (book: BookInfo, index: number) => {
          if (index < 6) {
            this.BookItem(book)
          }
        }, (book: BookInfo, index: number) => book.id + index.toString())
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  BookItem(book: BookInfo) {
    Column({ space: Spacing.xs }) {
      Stack({ alignContent: Alignment.Bottom }) {
        if (book.coverPath && book.coverPath.length > 0) {
          Image(book.coverPath)
            .width(layoutHelper.getImageSize(80))
            .height(layoutHelper.getImageSize(110))
            .borderRadius(BorderRadius.sm)
            .objectFit(ImageFit.Cover)
        }
        if (!(book.coverPath && book.coverPath.length > 0)) {
          Column() {
            Text(this.getFormatIcon(book.format))
              .fontSize(Size.iconLG)
              .fontColor('#FFFFFF')
          }
          .width(layoutHelper.getImageSize(80))
          .height(layoutHelper.getImageSize(110))
          .backgroundColor('#4A90D9')
          .borderRadius(BorderRadius.sm)
          .justifyContent(FlexAlign.Center)
        }

        if (book.readProgress > 0) {
          Row() {
            Progress({ value: book.readProgress, total: 100 })
              .width(layoutHelper.getImageSize(70))
              .height(3)
              .color('#007DFF')
              .borderRadius(1.5)
          }
          .padding({ bottom: Spacing.sm })
        }
      }

      Text(book.title)
        .fontSize(layoutHelper.getResponsiveFontSize(11))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
        .width(layoutHelper.getImageSize(80))

      if (book.readProgress > 0) {
        Text(book.readProgress + '%')
          .fontSize(layoutHelper.getResponsiveFontSize(10))
          .fontColor('#007DFF')
      }
    }
    .onClick(() => {
      if (this.onBookClick) {
        this.onBookClick(book);
      }
    })
  }

  @Builder
  ShortcutsCard() {
    AppCard({
      content: () => {
        Column({ space: Spacing.md }) {
          Text('快捷入口')
            .fontSize(layoutHelper.getResponsiveFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .width('100%')

          Grid() {
            ForEach(this.shortcuts, (item: ShortcutItem, index: number) => {
              GridItem() {
                this.HomeShortcut(item.icon, item.title, item.color, () => {
                  this.navigateTo(item.url);
                })
              }
            }, (item: ShortcutItem, index: number) => item.title + index.toString())
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .columnsGap(Spacing.sm)
          .rowsGap(Spacing.sm)
        }
        .width('100%')
      },
      elevation: ElevationLevel.MD,
      isDarkMode: this.isDarkMode,
      padding: Spacing.lg,
      marginBottom: 0
    })
  }

  @Builder
  HomeShortcut(icon: string, title: string, color: string, action: () => void) {
    Column({ space: Spacing.xs }) {
      Text(icon)
        .fontSize(Size.iconXL)
        .width(Size.iconXXL + Spacing.md)
        .height(Size.iconXXL + Spacing.md)
        .textAlign(TextAlign.Center)
        .backgroundColor(color + '15')
        .borderRadius(BorderRadius.sm)

      Text(title)
        .fontSize(layoutHelper.getResponsiveFontSize(12))
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
    }
    .width('100%')
    .padding(Spacing.sm)
    .onClick(() => action())
  }

  @Builder
  EmptyStateView() {
    Column({ space: 8 }) {
      Text('book_fill')
        .fontSize(32)

      Text('暂无正在阅读的书�?)
        .fontSize(13)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')

      Text('添加书籍')
        .fontSize(12)
        .fontColor('#007DFF')
        .onClick(() => {
          if (this.onOpenFilePicker) {
            this.onOpenFilePicker();
          }
        })
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ReadingStatsCard() {
    AppCard({
      content: () => {
        Column({ space: Spacing.md }) {
          Text('本周阅读概览')
            .fontSize(layoutHelper.getResponsiveFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .width('100%')
        
          Row({ space: Spacing.sm }) {
            this.StatItem('book_spread', '12h', '阅读时长')
            this.StatItem('books_vertical_fill', '5', '阅读书籍')
            this.StatItem('chart_bar_alt_fill', '78%', '目标完成')
          }
          .width('100%')
        }
        .width('100%')
      },
      elevation: ElevationLevel.MD,
      isDarkMode: this.isDarkMode,
      padding: 16,
      marginBottom: 0
    })
  }

  @Builder
  StatItem(emoji: string, value: string, label: string) {
    Column({ space: Spacing.xs }) {
      Text(emoji)
        .fontSize(Size.iconXL)

      Text(value)
        .fontSize(layoutHelper.getResponsiveFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      Text(label)
        .fontSize(layoutHelper.getResponsiveFontSize(10))
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
    }
    .layoutWeight(1)
    .padding(Spacing.sm)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,125,255,0.04)')
    .borderRadius(BorderRadius.sm)
    .alignItems(HorizontalAlign.Center)
  }
}
