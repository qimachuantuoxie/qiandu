import { logger } from '../../../common/utils/Logger';
// 书签管理页面
// Bookmarks Management Page

import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Bookmark } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { tr } from '../core/utils/LocalizationUtil';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { LazyDataSource } from '../common/datasource/LazyDataSource';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface BookmarkWithBook {
  bookmark: Bookmark;
  book: BookInfo | null;
}

@Entry
@Component
struct BookmarksPage {
  @State bookmarks: BookmarkWithBook[] = [];
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State searchText: string = '';
  @State selectedBookId: string = '';
  @State isTablet: boolean = false;
  @State screenInfo: ScreenInfo | null = null;
  private unsubscribe: (() => void) | null = null;
  @State private context: common.Context | null = null;

  // LazyForEach 数据源
  private bookmarksDataSource: LazyDataSource<BookmarkWithBook> = new LazyDataSource<BookmarkWithBook>((item: BookmarkWithBook) => item.bookmark.id);

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.initAsyncData();
    this.setupSubscriptions();
  }

  private initData(): void {
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();

    if (this.context) {
      preferenceManager.init(this.context);
      appTheme.init(this.context);
    }
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

    this.loadBookmarks();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookViewModel.subscribe(() => {
      this.loadBookmarks();
    });
  }

  private updateDataSource(): void {
    const filtered = this.getFilteredBookmarks();
    this.bookmarksDataSource.setData(filtered);
  }

  private loadBookmarks(): void {
    const allBooks = bookViewModel.getAllBooks();
    const allBookmarks: BookmarkWithBook[] = [];

    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      const bookmarks = bookViewModel.getBookmarks(book.id);

      for (let j = 0; j < bookmarks.length; j++) {
        allBookmarks.push({
          bookmark: bookmarks[j],
          book: book
        });
      }
    }

    const sortedBookmarks = allBookmarks.slice().sort((a, b) => b.bookmark.createTime - a.bookmark.createTime);

    this.bookmarks = sortedBookmarks;
    this.updateDataSource();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
  }

  private getFilteredBookmarks(): BookmarkWithBook[] {
    let filtered: BookmarkWithBook[] = [];

    for (let i = 0; i < this.bookmarks.length; i++) {
      filtered.push(this.bookmarks[i]);
    }

    if (this.selectedBookId) {
      const bookFiltered: BookmarkWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item: BookmarkWithBook = filtered[i];
        if (item.book && item.book.id === this.selectedBookId) {
          bookFiltered.push(item);
        }
      }
      filtered = bookFiltered;
    }

    if (this.searchText.trim()) {
      const keyword = this.searchText.toLowerCase();
      const searchFiltered: BookmarkWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item: BookmarkWithBook = filtered[i];
        const titleMatch: boolean = item.bookmark.title.toLowerCase().includes(keyword);
        const note: string | undefined = item.bookmark.note;
        const noteMatch: boolean = note ? note.toLowerCase().includes(keyword) : false;
        const bookTitle: string = item.book ? item.book.title : '';
        const bookTitleMatch: boolean = bookTitle.toLowerCase().includes(keyword);

        if (titleMatch || noteMatch || bookTitleMatch) {
          searchFiltered.push(item);
        }
      }
      filtered = searchFiltered;
    }

    return filtered;
  }

  private goToBookmark(bookmark: BookmarkWithBook): void {
    if (bookmark.book) {
      const params: Record<string, Object> = {};
      params['bookId'] = bookmark.book.id;
      params['page'] = bookmark.bookmark.pageNumber;
      navigateTo('pages/EnhancedReaderPage', params);
    }
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';

    return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text('<')
          .fontSize(Size.iconXL)
          .fontColor(this.currentColors.textPrimary)
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .backgroundColor(this.tc('rgba(255, 255, 255, 0.3)', 'rgba(0, 0, 0, 0.3)'))
      .borderRadius(BorderRadius.full)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[BookmarksPage] back failed:', msg);
        }
      })

      Text(tr('bookmarks_title'))
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)

      Text(this.bookmarks.length + '个书签')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .height(Size.buttonLG)
    .padding({ left: Spacing.xs, right: Spacing.lg })
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.95)', 'rgba(44, 44, 46, 0.95)'))
  }

  @Builder
  SearchBar() {
    Column({ space: Spacing.sm }) {
      // 搜索框和筛选按钮
      Row({ space: Spacing.sm }) {
        // 搜索输入框
        TextInput({ placeholder: '搜索书签...' })
          .layoutWeight(1)
          .height(Size.inputSM)
          .padding({ left: Spacing.lg, right: Spacing.lg })
          .backgroundColor(this.bg('#F5F5F5', '#2C2C2E'))
          .borderRadius(BorderRadius.md)
          .onChange((value: string) => {
            this.searchText = value;
            this.updateDataSource();
          })

        // 筛选按钮
        Button() {
          Row({ space: Spacing.xs }) {
            Text('line_horizontal_3_decrease_circle')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor(this.selectedBookId ? COMMON_COLORS.PRIMARY_BLUE : this.currentColors.textSecondary)
            if (this.selectedBookId) {
              Text('●')
                .fontSize(8)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            }
          }
        }
        .width(Size.buttonMD)
        .height(Size.inputSM)
        .backgroundColor(this.selectedBookId ? COMMON_COLORS.PRIMARY_BLUE + '15' : this.bg('#F5F5F5', '#2C2C2E'))
        .borderRadius(BorderRadius.md)
        .onClick(() => {
          this.showBookFilterDialog();
        })
      }
      .width('100%')

      // 激活的筛选标签
      if (this.selectedBookId) {
        Row({ space: Spacing.sm }) {
          Text('filter.circle')
            .fontSize(14)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          
          Text(bookViewModel.getBookById(this.selectedBookId)?.title || '')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.currentColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Button() {
            Text('xmark.circle.fill')
              .fontSize(16)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          }
          .width(24)
          .height(24)
          .backgroundColor(Color.Transparent)
          .onClick(() => { 
            this.selectedBookId = '';
            this.updateDataSource();
          })
        }
        .width('100%')
        .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '10')
        .borderRadius(BorderRadius.sm)
      }
    }
    .width('100%')
    .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.sm })
  }

  private showBookFilterDialog(): void {
    const allBooks = bookViewModel.getAllBooks();
    const bookTitles: string[] = [tr('all_books')];
    const bookIds: string[] = [''];
    
    for (let i = 0; i < allBooks.length; i++) {
      bookTitles.push(allBooks[i].title);
      bookIds.push(allBooks[i].id);
    }

    promptAction.showActionMenu({
      title: tr('filter_by_book'),
      buttons: bookTitles.map((title, index) => ({
        text: title,
        action: () => {
          this.selectedBookId = bookIds[index];
          this.updateDataSource();
        }
      }))
    });
  }

  @Builder
  BookmarkItem(bookmarkWithBook: BookmarkWithBook) {
    Row() {
      Column({ space: Spacing.sm }) {
        if (bookmarkWithBook.book) {
          Image(bookmarkWithBook.book.coverPath || '')
            .width(this.isTablet ? Size.avatarLG + 12 : Size.avatarMD + 10)
            .height(this.isTablet ? Size.cardSM + 14 : Size.cardXS + 14)
            .borderRadius(BorderRadius.xs)
            .objectFit(ImageFit.Cover)
            .alt($r('app.media.app_icon'))
        } else {
          Column()
            .width(this.isTablet ? Size.avatarLG + 12 : Size.avatarMD + 10)
            .height(this.isTablet ? Size.cardSM + 14 : Size.cardXS + 14)
            .backgroundColor(this.currentColors.surface)
            .borderRadius(BorderRadius.xs)
        }
      }
      .width(this.isTablet ? Size.avatarLG + 24 : Size.avatarMD + 20)
      .alignItems(HorizontalAlign.Start)

      Column({ space: Spacing.sm }) {
        Text(bookmarkWithBook.bookmark.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 18 : 15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (bookmarkWithBook.book) {
          Text(bookmarkWithBook.book.title)
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 14 : 12))
            .fontColor(this.currentColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Row({ space: Spacing.sm }) {
          Text(tr('prev_page') + ' ' + bookmarkWithBook.bookmark.pageNumber + ' ' + tr('books_count'))
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 13 : 11))
            .fontColor(this.currentColors.textHint)
            .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs / 2, bottom: Spacing.xs / 2 })
            .backgroundColor('#007DFF20')
            .borderRadius(BorderRadius.xs)

          Text(this.formatTime(bookmarkWithBook.bookmark.createTime))
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 13 : 11))
            .fontColor(this.currentColors.textHint)
        }

        if (bookmarkWithBook.bookmark.note) {
          Text(bookmarkWithBook.bookmark.note)
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 14 : 12))
            .fontColor(this.currentColors.textSecondary)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: this.isTablet ? Spacing.md + 2 : Spacing.md })
    }
    .width('100%')
    .padding(this.isTablet ? Spacing.xxl : Spacing.lg)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(BorderRadius.md)
    .margin({ left: this.isTablet ? Spacing.xxl : Spacing.xl, right: this.isTablet ? Spacing.xxl : Spacing.xl, bottom: this.isTablet ? Spacing.lg + 2 : Spacing.md })
    .onClick(() => { this.goToBookmark(bookmarkWithBook); })
  }

  @Builder
  EmptyView() {
    Column({ space: Spacing.lg }) {
      Text(tr('no_bookmarks'))
        .fontSize(fontScaleManager.getScaledFontSize(64))
        .fontWeight(FontWeight.Bold)

      Text(tr('no_bookmarks') || tr('no_data'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)

      Text(tr('no_bookmarks') || tr('no_data'))
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textHint)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      this.Header()
      this.SearchBar()

      if (this.getFilteredBookmarks().length === 0) {
        this.EmptyView()
      } else {
        Scroll() {
          Column({ space: Spacing.none }) {
            LazyForEach(this.bookmarksDataSource, (item: BookmarkWithBook) => {
              this.BookmarkItem(item)
            }, (item: BookmarkWithBook) => item.bookmark.id)
          }
          .padding({ top: Spacing.xs, bottom: Spacing.xl })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentColors.background)
  }
}

// 预览组件 - 用于DevEco Studio预览
@Preview
@Component
struct BookmarksPagePreview {
  build() {
    Column() {
      Text('书签管理 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      BookmarksPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('书签管理 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      // 注意：深色模式需要通过主题管理器设置
      BookmarksPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}

export default BookmarksPage;
