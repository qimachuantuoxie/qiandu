import { logger } from '../../../common/utils/Logger';
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
@ComponentV2
struct BookmarksPage {
  @Local bookmarks: BookmarkWithBook[] = [];
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local searchText: string = '';
  @Local selectedBookId: string = '';
  @Local isTablet: boolean = false;
  @Local screenInfo: ScreenInfo | null = null;
  private unsubscribe: (() => void) | null = null;
  @Local private context: common.Context | null = null;

  private bookmarksDataSource: LazyDataSource<BookmarkWithBook> = 
    new LazyDataSource<BookmarkWithBook>((item: BookmarkWithBook) => item.bookmark.id);

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

    const sortedBookmarks = allBookmarks.slice().sort((a, b) => 
      b.bookmark.createTime - a.bookmark.createTime);

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

    return date.getFullYear() + '-' + 
      String(date.getMonth() + 1).padStart(2, '0') + '-' + 
      String(date.getDate()).padStart(2, '0');
  }

  build() {
    Column() {
      // 顶部导航栏
      this.Header()

      // 搜索栏
      this.SearchBar()

      // 书签列表
      if (this.getFilteredBookmarks().length === 0) {
        this.EmptyState()
      } else {
        List({ space: Spacing.md }) {
          ForEach(this.getFilteredBookmarks(), (bookmark: BookmarkWithBook) => {
            ListItem() {
              this.BookmarkItem(bookmark)
            }
          }, (bookmark: BookmarkWithBook) => bookmark.bookmark.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg,
          top: Spacing.sm,
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
  Header() {
    Row() {
      // 返回按钮
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
          logger.error('[BookmarksPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Column({ space: Spacing.xs }) {
        Text(tr('bookmarks_title'))
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Text(this.bookmarks.length + ' 个书签')
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.md })

      // 筛选按钮
      Row() {
        SymbolGlyph($r('sys.symbol.line.horizontal.3.decrease.circle'))
          .fontSize(Size.iconMD)
          .fontColor([this.selectedBookId ? COMMON_COLORS.PRIMARY_BLUE : this.tc('#8E8E93', '#8E8E93')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.selectedBookId ? COMMON_COLORS.PRIMARY_BLUE + '15' : this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showBookFilterDialog();
      })
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  SearchBar() {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        // 搜索图标
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])
          .margin({ left: Spacing.md })

        // 搜索输入框
        TextInput({ placeholder: '搜索书签...', text: $$this.searchText })
          .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .height(Size.inputSM)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
            this.updateDataSource();
          })

        // 清空按钮
        if (this.searchText) {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
            this.updateDataSource();
          })
        }
      }
      .width('100%')
      .height(Size.inputSM)
      .padding({ left: Spacing.sm, right: Spacing.sm })
      .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
      .borderRadius(BorderRadius.xl)

      // 激活的筛选标签
      if (this.selectedBookId) {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.book.fill'))
            .fontSize(Size.iconSM)
            .fontColor([COMMON_COLORS.PRIMARY_BLUE])
          
          Text(bookViewModel.getBookById(this.selectedBookId)?.title || '')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(Size.iconXS)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { 
            this.selectedBookId = '';
            this.updateDataSource();
          })
        }
        .width('100%')
        .padding({ 
          left: Spacing.md, 
          right: Spacing.md, 
          top: Spacing.sm, 
          bottom: Spacing.sm 
        })
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '10')
        .borderRadius(BorderRadius.lg)
      }
    }
    .width('100%')
    .padding({ 
      left: Spacing.lg, 
      right: Spacing.lg, 
      top: Spacing.md, 
      bottom: Spacing.sm 
    })
  }

  private showBookFilterDialog(): void {
    const allBooks = bookViewModel.getAllBooks();
    const bookTitles: string[] = ['全部书籍'];
    const bookIds: string[] = [''];
    
    for (let i = 0; i < allBooks.length; i++) {
      bookTitles.push(allBooks[i].title);
      bookIds.push(allBooks[i].id);
    }

    promptAction.showActionMenu({
      title: '按书籍筛选',
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
    Row({ space: Spacing.lg }) {
      // 封面图
      Stack() {
        if (bookmarkWithBook.book && bookmarkWithBook.book.coverPath) {
          Image(bookmarkWithBook.book.coverPath)
            .width(this.isTablet ? 70 : 60)
            .height(this.isTablet ? 95 : 80)
            .borderRadius(BorderRadius.md)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.book.fill'))
              .fontSize(Size.iconXXL)
              .fontColor([this.currentColors.primary])
          }
          .width(this.isTablet ? 70 : 60)
          .height(this.isTablet ? 95 : 80)
          .borderRadius(BorderRadius.md)
          .backgroundColor(this.currentColors.primary + '15')
          .justifyContent(FlexAlign.Center)
        }

        // 页码标签
        Row() {
          Text('P' + bookmarkWithBook.bookmark.pageNumber)
            .fontSize(fontScaleManager.getScaledFontSize(10))
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
        }
        .padding({ 
          left: Spacing.sm, 
          right: Spacing.sm, 
          top: Spacing.xs, 
          bottom: Spacing.xs 
        })
        .backgroundColor('rgba(0,0,0,0.6)')
        .borderRadius(BorderRadius.xl)
        .position({ x: 5, y: 5 })
      }

      // 内容区域
      Column({ space: Spacing.sm }) {
        // 标题
        Text(bookmarkWithBook.bookmark.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 16 : 15))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 书籍名称
        if (bookmarkWithBook.book) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.book'))
              .fontSize(Size.iconXS)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text(bookmarkWithBook.book.title)
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
        }

        // 时间和备注
        Row({ space: Spacing.sm }) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(Size.iconXS)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text(this.formatTime(bookmarkWithBook.bookmark.createTime))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }

          if (bookmarkWithBook.bookmark.note) {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.note.text'))
                .fontSize(Size.iconXS)
                .fontColor([this.currentColors.primary])
              
              Text(bookmarkWithBook.bookmark.note)
                .fontSize(fontScaleManager.getScaledFontSize(11))
                .fontColor(this.currentColors.primary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 跳转箭头
      SymbolGlyph($r('sys.symbol.chevron.right'))
        .fontSize(Size.iconSM)
        .fontColor([this.tc('#C7C7CC', '#48484A')])
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .onClick(() => this.goToBookmark(bookmarkWithBook))
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
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无书签')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('阅读时添加书签，方便快速跳转')
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

      BookmarksPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
