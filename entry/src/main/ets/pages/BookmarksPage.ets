// 书签绠＄悊椤甸潰
// Bookmark Management Page

import { router } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Bookmark } from '../models/CoreBookModel';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { tr } from '../utils/I18nManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { LazyDataSource } from '../common/datasource/LazyDataSource';

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
  private unsubscribe: (() => void) | null = null;
  @State private context: common.Context | null = null;

  // LazyForEach 数据源
  private bookmarksDataSource: LazyDataSource<BookmarkWithBook> = new LazyDataSource<BookmarkWithBook>((item: BookmarkWithBook) => item.bookmark.id);

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.loadBookmarks();
    this.setupSubscriptions();
  }

  private async initData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    preferenceManager.init(this.context);
    appTheme.init(this.context);
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookViewModel.subscribe(() => {
      this.loadBookmarks();
    });
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
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

    const sortedBookmarks: BookmarkWithBook[] = [];
    for (let i = 0; i < allBookmarks.length; i++) {
      sortedBookmarks.push(allBookmarks[i]);
    }
    sortedBookmarks.sort((a, b) => b.bookmark.createTime - a.bookmark.createTime);

    this.bookmarks = sortedBookmarks;
    this.updateDataSource();
  }

  private getFilteredBookmarks(): BookmarkWithBook[] {
    let filtered: BookmarkWithBook[] = [];
    
    if (this.selectedBookId) {
      for (let i = 0; i < this.bookmarks.length; i++) {
        if (this.bookmarks[i].book !== undefined && this.bookmarks[i].book!.id === this.selectedBookId) {
          filtered.push(this.bookmarks[i]);
        }
      }
    } else {
      for (let i = 0; i < this.bookmarks.length; i++) {
        filtered.push(this.bookmarks[i]);
      }
    }

    if (this.searchText.trim().length > 0) {
      const keyword = this.searchText.toLowerCase();
      const result: BookmarkWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item = filtered[i];
        const titleMatch = item.bookmark.title.toLowerCase().includes(keyword);
        const noteMatch = item.bookmark.note !== undefined && item.bookmark.note!.toLowerCase().includes(keyword);
        const bookMatch = item.book !== undefined && item.book!.title.toLowerCase().includes(keyword);
        if (titleMatch || noteMatch || bookMatch) {
          result.push(item);
        }
      }
      return result;
    }

    return filtered;
  }

  private deleteBookmark(bookmark: BookmarkWithBook): void {
    if (bookmark.book) {
      bookViewModel.deleteBookmark(bookmark.book.id, bookmark.bookmark.id);
      this.loadBookmarks();
    }
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

    return (date.getMonth() + 1) + '月' + date.getDate() + '日';
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text(tr('back'))
          .fontSize(fontScaleManager.getScaledFontSize(24))
          .fontColor(this.currentColors.textPrimary)
      }
      .width(44)
      .height(44)
      .backgroundColor(this.tc('rgba(0,0,0,0.3)', 'rgba(255,255,255,0.3)'))
      .borderRadius(22)
      .onClick(() => {
        try {
          router.back();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          console.error('[BookmarksPage] back failed:', msg);
        }
      })

      Text(tr('bookmarks'))
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)

      Text(this.bookmarks.length + tr('bookmarks'))
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 16 })
    .backgroundColor('rgba(255, 255, 255, ' + (this.isDarkMode ? 0.05 : 0.95) + ')')
  }

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: tr('search_books') })
        .width('100%')
        .height(40)
        .padding({ left: 16, right: 16 })
        .backgroundColor('rgba(255, 255, 255, ' + (this.isDarkMode ? 0.1 : 0.1) + ')')
        .borderRadius(20)
        .onChange((value: string) => {
          this.searchText = value;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }

  @Builder
  BookFilter() {
    if (this.selectedBookId) {
      Row() {
        Text(tr('filter') + ': ' + (bookViewModel.getBookById(this.selectedBookId) !== null ? bookViewModel.getBookById(this.selectedBookId)!.title : ''))
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .padding({ left: 12, right: 8 })

        Button() {
          Text('脳')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width(24)
        .height(24)
        .backgroundColor(this.tc('rgba(0,0,0,0.5)', 'rgba(255,255,255,0.5)'))
        .borderRadius(12)
        .onClick(() => { this.selectedBookId = ''; })
      }
      .width('100%')
      .height(36)
      .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '20')
      .borderRadius(18)
      .margin({ left: 20, right: 20, bottom: 12 })
    }
  }

  @Builder
  BookmarkItem(bookmarkWithBook: BookmarkWithBook) {
    Row() {
      Column({ space: 8 }) {
        if (bookmarkWithBook.book) {
          Image(bookmarkWithBook.book.coverPath || '')
            .width(this.isTablet ? 60 : 50)
            .height(this.isTablet ? 84 : 70)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)
            .alt($r('app.media.app_icon'))
        } else {
          Column()
            .width(this.isTablet ? 60 : 50)
            .height(this.isTablet ? 84 : 70)
            .backgroundColor(this.currentColors.surface)
            .borderRadius(4)
        }
      }
      .width(this.isTablet ? 72 : 60)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
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

        Row({ space: 8 }) {
          Text(tr('prev_page') + ' ' + bookmarkWithBook.bookmark.pageNumber + ' ' + tr('books_count'))
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 13 : 11))
            .fontColor(this.currentColors.textHint)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#007DFF20')
            .borderRadius(4)

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
      .margin({ left: this.isTablet ? 14 : 12 })
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(12)
    .margin({ left: this.isTablet ? 24 : 20, right: this.isTablet ? 24 : 20, bottom: this.isTablet ? 18 : 12 })
    .onClick(() => { this.goToBookmark(bookmarkWithBook); })
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('No Bookmarks')
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
      this.BookFilter()

      if (this.getFilteredBookmarks().length === 0) {
        this.EmptyView()
      } else {
        Scroll() {
          Column({ space: 0 }) {
            LazyForEach(this.bookmarksDataSource, (item: BookmarkWithBook) => {
              this.BookmarkItem(item)
            }, (item: BookmarkWithBook) => item.bookmark.id)
          }
          .padding({ top: 8, bottom: 20 })
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

export default BookmarksPage;
