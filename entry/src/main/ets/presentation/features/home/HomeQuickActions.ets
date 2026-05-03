/**
 * 首页快捷操作组件 - v5.0 优化版
 * Home Quick Actions Component - Optimized v5.0
 *
 * 包含快捷操作网格、统计卡片、继续阅读等组件
 */

import { uiDesignKit, LIGHT_THEME, ThemeColors, IconSize, FontSize, SpacingSize, BorderRadius } from '../../../services/reader/UIDesignKitService';
import { router } from '@kit.ArkUI';
import { navigateTo } from '../../../utils/NavigationHelper';

/**
 * ?????
 */
interface QuickAction {
  id: string;
  icon: string;
  title: string;
  subtitle?: string;
  targetPage?: string;
  bgColor: string;
  iconColor?: string;
  showBadge?: boolean;
  badgeText?: string;
  onClick?: () => void;
}

/**
 * ?????
 */
interface RecommendedBook {
  bookId: string;
  title: string;
  author: string;
  coverUri: string;
  rating: number;
  category: string;
  isRead: boolean;
  progress?: number;
}

/**
 * ????
 */
interface StatCard {
  icon: string;
  value: string;
  label: string;
  color: string;
}

// ==================== ????? ====================

/**
 * ????????
 */
@Component
export struct QuickActionGrid {
  @State actions: QuickAction[] = [];
  private theme: ThemeColors = LIGHT_THEME;

  aboutToAppear() {
    this.theme = uiDesignKit.getThemeColors();
    this.initActions();
  }

  private initActions(): void {
    this.actions = [
      {
        id: 'scan_folder',
        icon: '??',
        title: '?????',
        subtitle: '??????',
        bgColor: '#E3F2FD',
        targetPage: 'pages/FolderScannerPage'
      },
      {
        id: 'online_books',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#F3E5F5',
        targetPage: 'pages/OnlineBookstorePage'
      },
      {
        id: 'reading_stats',
        icon: '??',
        title: '????',
        subtitle: '??????',
        bgColor: '#E8F5E9',
        targetPage: 'pages/ReadingStatsPage'
      },
      {
        id: 'bookmarks',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#FFF3E0',
        targetPage: 'pages/BookmarksPage'
      },
      {
        id: 'notes',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#FCE4EC',
        targetPage: 'pages/NotesPage'
      },
      {
        id: 'community',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#E0F7FA',
        targetPage: 'pages/CommunityPage',
        showBadge: true,
        badgeText: 'NEW'
      },
      {
        id: 'cloud_sync',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#EDE7F6',
        targetPage: 'pages/CloudSyncPage'
      },
      {
        id: 'vip_member',
        icon: '??',
        title: '????',
        subtitle: '????',
        bgColor: '#FFF9C4',
        targetPage: 'pages/VipMemberPage'
      }
    ];
  }

  build() {
    Column() {
      // ??
      Row() {
        Text('????')
          .fontSize(FontSize.H4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Text('???? ?)
          .fontSize(FontSize.SM)
          .fontColor(this.theme.primary)
          .onClick(() => {
            // ?????????
          })
      }
      .width('100%')
      .margin({ bottom: SpacingSize.LG })

      // ??????
      Grid() {
        ForEach(this.actions, (action: QuickAction) => {
          GridItem() {
            this.ActionItem(action)
          }
        }, (action: QuickAction) => action.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(SpacingSize.MD)
      .rowsGap(SpacingSize.MD)
      .height(200)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  ActionItem(action: QuickAction) {
    Column({ space: SpacingSize.SM }) {
      // ??
      Stack() {
        Circle({ width: 56, height: 56 })
          .fill(action.bgColor)

        Text(action.icon)
          .fontSize(28)
      }

      // ??
      Text(action.title)
        .fontSize(FontSize.SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // ???
      if (action.subtitle) {
        Text(action.subtitle)
          .fontSize(FontSize.XS)
          .fontColor(this.theme.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(SpacingSize.SM)
    .onClick(() => {
      if (action.onClick) {
        action.onClick();
      } else if (action.targetPage) {
        navigateTo(action.targetPage);
      }
    })
  }
}

// ==================== ????? ====================

/**
 * ????????
 */
@Component
export struct ReadingStatsCards {
  @State stats: StatCard[] = [];
  private theme: ThemeColors = LIGHT_THEME;

  aboutToAppear() {
    this.theme = uiDesignKit.getThemeColors();
    this.initStats();
  }

  private initStats(): void {
    this.stats = [
      {
        icon: '??',
        value: '128',
        label: '??',
        color: this.theme.primary
      },
      {
        icon: '??',
        value: '356h',
        label: '????',
        color: this.theme.success
      },
      {
        icon: '??',
        value: '24',
        label: '????',
        color: this.theme.warning
      },
      {
        icon: '??',
        value: '15?',
        label: '????',
        color: this.theme.error
      }
    ];
  }

  build() {
    Column() {
      // ??
      Text('????')
        .fontSize(FontSize.H4)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.textPrimary)
        .width('100%')
        .margin({ bottom: SpacingSize.LG })

      // ??????
      Scroll() {
        Row({ space: SpacingSize.LG }) {
          ForEach(this.stats, (stat: StatCard) => {
            this.StatCardItem(stat)
          }, (stat: StatCard) => stat.label + stat.value)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  StatCardItem(stat: StatCard) {
    Column({ space: SpacingSize.SM }) {
      // ?????
      Row({ space: SpacingSize.SM }) {
        Text(stat.icon)
          .fontSize(24)

        Text(stat.value)
          .fontSize(FontSize.XXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(stat.color)
      }

      // ??
      Text(stat.label)
        .fontSize(FontSize.XS)
        .fontColor(this.theme.textSecondary)
    }
    .padding(SpacingSize.LG)
    .backgroundColor(this.theme.background)
    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.LG))
    .border({ width: 1, color: this.theme.borderLight })
  }
}

// ==================== ????? ====================

/**
 * ???????
 */
interface ReadingBookItem {
  bookId: string;
  title: string;
  author: string;
  coverUri: string;
  progress: number;
  lastReadTime: number;
}

/**
 * ????????
 */
@Component
export struct ContinueReadingCard {
  @State readingBooks: ReadingBookItem[] = [];

  private theme: ThemeColors = LIGHT_THEME;

  aboutToAppear() {
    this.theme = uiDesignKit.getThemeColors();
  }

  build() {
    Column() {
      // ??
      Row() {
        Text('????')
          .fontSize(FontSize.H4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Text('???? ?)
          .fontSize(FontSize.SM)
          .fontColor(this.theme.primary)
          .onClick(() => {
            navigateTo('pages/ReadRecordPage');
          })
      }
      .width('100%')
      .margin({ bottom: SpacingSize.LG })

      // ????
      if (this.readingBooks.length > 0) {
        this.ReadingBooksList()
      } else {
        this.EmptyState()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  ReadingBooksList() {
    List({ space: SpacingSize.LG }) {
      ForEach(this.readingBooks, (book: ReadingBookItem) => {
        ListItem() {
          this.ReadingBookItem(book)
        }
      }, (book: ReadingBookItem) => book.bookId)
    }
    .width('100%')
  }

  @Builder
  ReadingBookItem(book: ReadingBookItem) {
    Row() {
      // ??
      Stack() {
        Image(book.coverUri || 'media:default_cover')
          .width(72)
          .height(100)
          .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
          .objectFit(ImageFit.Cover)

        // ???
        Progress({ value: book.progress, total: 100, type: ProgressType.Linear })
          .width(72)
          .position({ x: 0, y: 88 })
          .borderRadius({ bottomLeft: uiDesignKit.getBorderRadius(BorderRadius.MD), bottomRight: uiDesignKit.getBorderRadius(BorderRadius.MD) })
      }

      // ????
      Column({ space: SpacingSize.SM }) {
        Text(book.title)
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.theme.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(book.author)
          .fontSize(FontSize.SM)
          .fontColor(this.theme.textSecondary)

        Text('?? ' + book.progress + '%')
          .fontSize(FontSize.XS)
          .fontColor(this.theme.primary)

        Text('????: ' + this.formatTime(book.lastReadTime))
          .fontSize(FontSize.XS)
          .fontColor(this.theme.textTertiary)
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SpacingSize.LG })
      .layoutWeight(1)

      // ??????
      Button('????')
        .height(36)
        .backgroundColor(this.theme.primary)
        .fontColor('#FFFFFF')
        .fontSize(FontSize.SM)
        .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
        .onClick(() => {
          navigateTo('pages/EnhancedReaderPage', { bookId: book.bookId });
        })
    }
    .width('100%')
    .padding(SpacingSize.MD)
    .backgroundColor(this.theme.background)
    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.LG))
    .border({ width: 1, color: this.theme.borderLight })
  }

  @Builder
  EmptyState() {
    Column({ space: SpacingSize.LG }) {
      Text('??')
        .fontSize(64)

      Text('??????')
        .fontSize(FontSize.LG)
        .fontColor(this.theme.textSecondary)

      Text('?????????')
        .fontSize(FontSize.SM)
        .fontColor(this.theme.textTertiary)

      Button('????')
        .height(40)
        .backgroundColor(this.theme.primary)
        .fontColor('#FFFFFF')
        .fontSize(FontSize.MD)
        .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
        .onClick(() => {
          // ?????????
        })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      return '??';
    } else if (days === 1) {
      return '??';
    } else if (days < 7) {
      return days + '??';
    } else {
      return date.toLocaleDateString('zh-CN');
    }
  }
}

// ==================== ????? ====================

/**
 * ????????
 */
@Component
export struct RecommendedBooksGrid {
  @State books: RecommendedBook[] = [];
  private theme: ThemeColors = LIGHT_THEME;

  aboutToAppear() {
    this.theme = uiDesignKit.getThemeColors();
  }

  build() {
    Column() {
      // ??
      Row() {
        Text('????')
          .fontSize(FontSize.H4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Text('?? ?)
          .fontSize(FontSize.SM)
          .fontColor(this.theme.primary)
      }
      .width('100%')
      .margin({ bottom: SpacingSize.LG })

      // ????
      Grid() {
        ForEach(this.books, (book: RecommendedBook) => {
          GridItem() {
            this.RecommendedBookItem(book)
          }
        }, (book: RecommendedBook) => book.bookId)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(SpacingSize.LG)
      .columnsGap(SpacingSize.MD)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  RecommendedBookItem(book: RecommendedBook) {
    Column() {
      // ??
      Stack() {
        Image(book.coverUri || 'media:default_cover')
          .width('100%')
          .aspectRatio(0.71)
          .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
          .objectFit(ImageFit.Cover)

        // ????
        if (book.rating > 0) {
          Row({ space: 2 }) {
            Text('?')
              .fontSize(10)
            Text(book.rating.toFixed(1))
              .fontSize(10)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .backgroundColor('rgba(0,0,0,0.6)')
          .borderRadius(8)
          .position({ x: 4, y: 4 })
        }

        // ????
        if (book.isRead) {
          Text('??')
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.theme.success)
            .borderRadius(8)
            .position({ x: 4, y: 32 })
        }
      }

      // ??
      Text(book.title)
        .fontSize(FontSize.SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.theme.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: SpacingSize.SM })

      // ??
      Text(book.author)
        .fontSize(FontSize.XS)
        .fontColor(this.theme.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .onClick(() => {
      navigateTo('pages/BookDetailPage', { bookId: book.bookId });
    })
  }
}

// ==================== ????? ====================

/**
 * ???????
 */
@Component
export struct HomeSearchBar {
  @State searchText: string = '';
  private theme: ThemeColors = LIGHT_THEME;

  aboutToAppear() {
    this.theme = uiDesignKit.getThemeColors();
  }

  build() {
    Row({ space: SpacingSize.MD }) {
      // ???
      Row() {
        Text('??')
          .fontSize(18)
          .margin({ right: 8 })

        TextInput({ placeholder: '??????????...', text: this.searchText })
          .placeholderColor(this.theme.textTertiary)
          .backgroundColor('transparent')
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => {
            this.searchText = value;
          })
          .onSubmit((value: string) => {
            // ????
            navigateTo('pages/SearchResultPage', { keyword: value });
          })
      }
      .layoutWeight(1)
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.theme.backgroundSecondary)
      .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.XL))
      .border({ width: 1, color: this.theme.border })

      // ????
      Button() {
        Text('??')
          .fontSize(20)
      }
      .width(44)
      .height(44)
      .backgroundColor(this.theme.primary)
      .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
      .onClick(() => {
        // ??????
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}
