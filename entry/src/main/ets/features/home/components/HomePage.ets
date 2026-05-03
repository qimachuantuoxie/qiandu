// 首页组件 - 展示阅读进度、快捷入口、最近添加
import { navigateTo } from '../../../utils/NavigationHelper';
import { BookInfo } from '../../../models/CoreBookModel';
import { CommonHeader } from '../../../components/common';
import { AppCard, ElevationLevel } from '../../../components/cards/AppCard';

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
    { icon: 'chart_bar_fill', title: '阅读统计', color: '#007DFF', url: 'pages/StatisticsPage' },
    { icon: 'pencil', title: '待办事项', color: '#FF6B6B', url: 'pages/TodoPage' },
    { icon: 'book_fill', title: '阅读记录', color: '#52C41A', url: 'pages/ReadRecordPage' },
    { icon: 'bookmark_fill', title: '书签', color: '#FA8C16', url: 'pages/BookmarksPage' },
    { icon: 'pencil', title: '笔记', color: '#722ED1', url: 'pages/NotesPage' },
    { icon: '📰', title: '在线书源', color: '#13C2C2', url: 'pages/OnlineSourceMarketPage' },
    { icon: 'gear', title: '阅读设置', color: '#EB2F96', url: 'pages/SettingsPage' }
  ];

  private getFormatIcon(format: string): string {
    const formatIcons: Record<string, string> = {
      'PDF': '📄',
      'EPUB': 'book',
      'MOBI': '📱',
      'TXT': 'pencil',
      'DOCX': '📃',
      'DOC': '📃'
    };
    return formatIcons[format] || 'book_fill';
  }

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Column() {
      // 顶部导航栏
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
        { icon: '🔔', tooltip: '通知', action: () => {} },
        { icon: '+', tooltip: '添加书籍', action: () => {
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
      Column({ space: 16 }) {
        // 继续阅读
        this.RecentBooksCard()

        // 快捷入口
        this.ShortcutsCard()

        // 阅读统计
        this.ReadingStatsCard()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 32 })
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
        Column({ space: 12 }) {
          Row() {
            Text('继续阅读')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
              .layoutWeight(1)

            Text('查看全部 >')
              .fontSize(12)
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
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.Bottom }) {
        if (book.coverPath && book.coverPath.length > 0) {
          Image(book.coverPath)
            .width(80)
            .height(110)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        }
        if (!(book.coverPath && book.coverPath.length > 0)) {
          Column() {
            Text(this.getFormatIcon(book.format))
              .fontSize(20)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(110)
          .backgroundColor('#4A90D9')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        if (book.readProgress > 0) {
          Row() {
            Progress({ value: book.readProgress, total: 100 })
              .width(70)
              .height(3)
              .color('#007DFF')
              .borderRadius(1.5)
          }
          .padding({ bottom: 8 })
        }
      }

      Text(book.title)
        .fontSize(11)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
        .width(80)

      if (book.readProgress > 0) {
        Text(book.readProgress + '%')
          .fontSize(10)
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
        Column({ space: 12 }) {
          Text('快捷入口')
            .fontSize(18)
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
          .columnsGap(12)
          .rowsGap(12)
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
  HomeShortcut(icon: string, title: string, color: string, action: () => void) {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(28)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(color + '15')
        .borderRadius(8)

      Text(title)
        .fontSize(12)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
    }
    .width('100%')
    .padding(8)
    .onClick(() => action())
  }

  @Builder
  EmptyStateView() {
    Column({ space: 8 }) {
      Text('📚')
        .fontSize(32)

      Text('暂无正在阅读的书籍')
        .fontSize(13)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')

      Text('点击右上角 + 添加书籍')
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
        Column({ space: 12 }) {
          Text('本周阅读概览')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .width('100%')

          Row({ space: 12 }) {
            this.StatItem('📖', '12h', '阅读时长')
            this.StatItem('📚', '5', '阅读书籍')
            this.StatItem('📊', '78%', '目标完成')
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
    Column({ space: 4 }) {
      Text(emoji)
        .fontSize(24)

      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      Text(label)
        .fontSize(10)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
    }
    .layoutWeight(1)
    .padding(8)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,125,255,0.04)')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Center)
  }
}
