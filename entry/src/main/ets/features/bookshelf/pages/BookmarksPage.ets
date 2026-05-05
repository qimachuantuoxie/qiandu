import { logger } from '../../../common/utils/Logger';
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Bookmark } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { tr } from '../../../core/utils/LocalizationUtil';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { LazyDataSource } from '../../common/datasource/LazyDataSource';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

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
      PageHeader({
        title: tr('bookmarks_title'),
        subtitle: this.bookmarks.length + ' 个书签',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[BookmarksPage] back failed:', msg);
          }
        },
        rightContent: () => {
          Row() {
            SymbolGlyph($r('sys.symbol.line.horizontal.3.decrease.circle'))
              .fontSize(20)
              .fontColor([this.selectedBookId ? HDSColours.primary.blue : this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          }
          .width(40)
          .height(40)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(this.selectedBookId ? HDSColours.primary.blue + '15' : this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showBookFilterDialog();
          })
        }
      })

      // 搜索栏
      this.SearchBar()

      // 书签列表
      if (this.getFilteredBookmarks().length === 0) {
        this.EmptyState()
      } else {
        List({ space: HDSSpacing.md }) {
          ForEach(this.getFilteredBookmarks(), (bookmark: BookmarkWithBook) => {
            ListItem() {
              this.BookmarkItem(bookmark)
            }
          }, (bookmark: BookmarkWithBook) => bookmark.bookmark.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg,
          top: HDSSpacing.sm,
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
  SearchBar() {
    Column({ space: HDSSpacing.sm }) {
      Row({ space: HDSSpacing.sm }) {
        // 搜索图标
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(16)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          .margin({ left: HDSSpacing.md })

        // 搜索输入框
        TextInput({ placeholder: '搜索书签...', text: $$this.searchText })
          .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray400)
          .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
          .height(40)
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
              .fontSize(16)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
            this.updateDataSource();
          })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm })
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
      .borderRadius(HDSBorderRadius.xl)

      // 激活的筛选标签
      if (this.selectedBookId) {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.book.fill'))
            .fontSize(16)
            .fontColor([HDSColours.primary.blue])
          
          Text(bookViewModel.getBookById(this.selectedBookId)?.title || '')
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(12)
              .fontColor([HDSColours.primary.blue])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { 
            this.selectedBookId = '';
            this.updateDataSource();
          })
        }
        .width('100%')
        .padding({ 
          left: HDSSpacing.md, 
          right: HDSSpacing.md, 
          top: HDSSpacing.sm, 
          bottom: HDSSpacing.sm 
        })
        .backgroundColor(HDSColours.primary.blue + '10')
        .borderRadius(HDSBorderRadius.lg)
      }
    }
    .width('100%')
    .padding({ 
      left: HDSSpacing.lg, 
      right: HDSSpacing.lg, 
      top: HDSSpacing.md, 
      bottom: HDSSpacing.sm 
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
          .fontColor(ThemeTokens.textPrimary())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 书籍名称
        if (bookmarkWithBook.book) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.book'))
              .fontSize(Size.iconXS)
              .fontColor([ThemeTokens.textSecondary()])
            
            Text(bookmarkWithBook.book.title)
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(ThemeTokens.textSecondary())
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
              .fontColor([ThemeTokens.textSecondary()])
            
            Text(this.formatTime(bookmarkWithBook.bookmark.createTime))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(ThemeTokens.textSecondary())
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
        .fontColor([ThemeTokens.textTertiary()])
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .onClick(() => this.goToBookmark(bookmarkWithBook))
    .stateStyles({
      pressed: {
        scale: { x: 0.98, y: 0.98 },
        backgroundColor: ThemeTokens.bgHover()
      },
      normal: {
        scale: { x: 1, y: 1 },
        backgroundColor: ThemeTokens.bgSecondary()
      }
    })
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([ThemeTokens.textDisabled()])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(ThemeTokens.bgHover())
      .justifyContent(FlexAlign.Center)

      Text('暂无书签')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeTokens.textPrimary())

      Text('阅读时添加书签，方便快速跳转')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(ThemeTokens.textSecondary())
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
