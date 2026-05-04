// 涓婚〉 - 浼樺寲锟?浣跨敤鎷嗗バー鐨勭粍锟?
// 主页 - 优化版本
// Main Page - Optimized Version with Split Components

import { toast, navigateTo, goBack, navHelper } from '../common';
import { NavPathStack } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { BookInfo, BookFormat, ReadStatus, generateBookId } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { mainPageViewModel, MainPageViewModel } from '../features/home/viewmodels/MainPageViewModel';
import { EbookParser, ParseResult } from '../core/utils/EbookParser';
import { BookCoverData } from '../core/services/image/DynamicCoverService';
import { HomeContent } from '../features/home/components/HomePage';
import { DiscoverContent } from '../features/discover/components/DiscoverPage';
import { SettingsPage } from '../features/settings/pages/SettingsPage';
import { TabBar } from '../common/components/TabBar';
import { SearchBar } from '../common/components/SearchBar';
import { GroupPanel, AddGroupDialog } from '../features/bookshelf/components/GroupPanel';
import { OnlineSearchPage } from './OnlineSearchPage';
import { SmartServicesPanel } from '../common/components/SmartServicesPanel';
import { promptAction } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
import { Spacing, Size, BorderRadius, getShadow } from '../common/constants/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

/**
 * 瀵煎叆缁撴灉绫诲瀷
 */
type ImportResult = 'success' | 'failed' | 'skipped';

@Entry
@Component
struct MainPage {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  private mainPageVM: MainPageViewModel = mainPageViewModel;
  @State screenInfo: ScreenInfo | null = null;

  /**
   * 椤甸潰鍒濆锟?
   */
  aboutToAppear() {
    const context = this.getUIContext().getHostContext();
    if (context) {
      layoutHelper.init(context).then(() => {
        this.screenInfo = layoutHelper.getScreenInfo();
      });
      this.mainPageVM.initApp(context);
    }
  }

  /**
   * 椤甸潰閿€锟?
   */
  aboutToDisappear() {
    this.mainPageVM.cleanup();
  }

  /**
   * 鍔犺浇涔︾
   */
  private loadBooks(): void {
    this.mainPageVM.loadBooks();
  }

  /**
   * 鎸夐渶鑾峰彇灏侀潰鏁版嵁
   */
  private getCoverData(bookId: string): BookCoverData {
    return this.mainPageVM.getCoverData(bookId);
  }


  /**
   * 鍔犺浇鏇村
   */
  private loadMore(): void {
    if (this.mainPageVM.isLoading || !this.mainPageVM.hasMore) {
      return;
    }
    this.mainPageVM.loadMoreBooks();
  }

  /**
   * 涔︾鐐瑰嚮
   */
  private onBookClick(book: BookInfo): void {
    this.pageInfos.pushPath({
      name: 'EnhancedReaderPage',
      param: { bookId: book.id }
    });
  }

  /**
   * 鎵撳紑鏂囦欢閫夋嫨锟?
   */
  private async openFilePicker(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const documentSelectOptions = new picker.DocumentSelectOptions();

      // 鎵╁睍鏀寔鎵€鏈夎В鏋愬櫒鏀寔鐨勬牸寮忥紙16绉嶏級
      documentSelectOptions.fileSuffixFilters = [
        '.txt', '.text',          // 绾枃锟?
        '.pdf',                   // PDF 鏂囨。
        '.epub',                  // EPUB 鐢靛瓙锟?
        '.mobi',                  // Mobipocket
        '.doc', '.docx',          // Word 鏂囨。
        '.rtf',                   // 瀵屾枃鏈牸锟?
        '.html', '.htm',          // 缃戦〉鏂囦欢
        '.azw', '.azw3',          // Kindle 鏍煎紡
        '.djvu', '.djv',          // 鎵弿鏂囨。
        '.chm',                   // 缂栬瘧 HTML 甯姪
        '.fb2',                   // FictionBook
        '.odt',                   // OpenDocument 鏂囨湰
        '.cbr', '.cbz'            // 婕敾鍘缉锟?
      ];
      documentSelectOptions.maxSelectNumber = 10;

      const results = await documentPicker.select(documentSelectOptions);
      if (results && results.length > 0) {
        const uris: string[] = [];
        for (let i = 0; i < results.length; i++) {
          uris.push(results[i]);
        }
        this.importFiles(uris);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('鏂囦欢閫夋嫨澶辫触: ' + message);
      toast('鏂囦欢閫夋嫨澶辫触锛岃閲嶈瘯');
    }
  }

  /**
   * 瀵煎叆鏂囦欢锛堝寮虹増 - 鏀寔澶氭牸寮忋€佸苟鍙戙€佽繘搴﹀弽棣堬級
   */
  private async importFiles(fileUris: string[]): Promise<void> {
    if (fileUris.length === 0) {
      return;
    }

    const totalFiles = fileUris.length;
    let successCount = 0;
    let failedCount = 0;
    let skippedCount = 0;

    // 棰勫厛鑾峰彇宸插鍏ヤ功绫嶅垪琛紙浼樺寲鎬ц兘锟?
    const existingBooks = bookViewModel.getAllBooks();
    const existingPaths = new Set<string>();
    for (let i = 0; i < existingBooks.length; i++) {
      existingPaths.add(existingBooks[i].filePath);
    }

    // 鏄剧ず瀵煎叆杩涘害
    toast('寮€濮嬪锟?' + totalFiles + ' 涓枃锟?..');

    // 骞跺彂瀵煎叆锛堟帶鍒跺苟鍙戞暟锟?3锟?
    const concurrency = 3;
    for (let i = 0; i < fileUris.length; i += concurrency) {
      const batchEnd = i + concurrency;
      const batch: string[] = [];
      for (let j = i; j < batchEnd && j < fileUris.length; j++) {
        batch.push(fileUris[j]);
      }
      const currentBatch = Math.floor(i / concurrency) + 1;
      const totalBatches = Math.ceil(fileUris.length / concurrency);

      // 鏇存柊杩涘害
      const processedCount = batchEnd < fileUris.length ? batchEnd : fileUris.length;
        toast('姝ｅ湪瀵煎叆 ' + processedCount + '/' + totalFiles + '...');

      // 骞跺彂澶勭悊鎵规
      const results: ImportResult[] = [];
      for (let k = 0; k < batch.length; k++) {
        const result = await this.importSingleFile(batch[k], existingPaths);
        results.push(result);
      }

      // 缁�缁撴灉
      for (let m = 0; m < results.length; m++) {
        if (results[m] === 'success') {
          successCount++;
        } else if (results[m] === 'failed') {
          failedCount++;
        } else if (results[m] === 'skipped') {
          skippedCount++;
        }
      }
    }

    // 鏄剧ず瀵煎叆缁撴灉
    let message = '瀵煎叆瀹屾垚锛佹垚锟?' + successCount + ' 锟?;
    if (skippedCount > 0) {
      message += '锛岃烦锟?' + skippedCount + ' 鏈紙宸插瓨鍦級';
    }
    if (failedCount > 0) {
      message += '锛屽け锟?' + failedCount + ' 锟?;
    }

    toast(message);
    this.loadBooks();
  }

  /**
   * 瀵煎叆鍗曚釜鏂囦欢
   */
  private async importSingleFile(
    uri: string,
    existingPaths: Set<string>
  ): Promise<ImportResult> {
    try {
      // 妫€鏌ユ槸鍚﹀凡瀵煎叆
      if (existingPaths.has(uri)) {
        console.info('鏂囦欢宸插瓨鍦紝璺宠繃: ' + uri);
        return 'skipped';
      }

      const pathParts = uri.split('/');
      let fileName = '鏈煡涔︾';
      if (pathParts.length > 0) {
        fileName = pathParts[pathParts.length - 1];
      }

      const lastDot = fileName.lastIndexOf('.');
      const extension = lastDot > -1 ? fileName.substring(lastDot) : '';
      const format = this.extensionToFormat(extension);

      let title = fileName;
      if (extension.length > 0) {
        title = fileName.substring(0, fileName.length - extension.length);
      }
      let author = '鏈煡浣滐拷?";
      let totalPages = 100;
      let coverPath = '';
      let fileSize = 0;

      try {
        // 浣跨敤澧炲己瑙ｆ瀽鍣ㄨВ鏋愬厓鏁版嵁
        const ebookParser = new EbookParser();
        const parseResult: ParseResult = await ebookParser.parseFile(uri, format);
        if (parseResult.success && parseResult.metadata) {
          if (parseResult.metadata.title && parseResult.metadata.title.length > 0) {
            title = parseResult.metadata.title;
          }
          if (parseResult.metadata.author && parseResult.metadata.author.length > 0) {
            author = parseResult.metadata.author;
          }
          if (parseResult.metadata.totalPages && parseResult.metadata.totalPages > 0) {
            totalPages = parseResult.metadata.totalPages;
          }
          if (parseResult.metadata.fileSize && parseResult.metadata.fileSize > 0) {
            fileSize = parseResult.metadata.fileSize;
          }
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error';
        console.warn('瑙ｆ瀽涔︾鍏冩暟鎹け锟? ' + message);
      }

      const book: BookInfo = {
        id: generateBookId(),
        title: title,
        author: author,
        filePath: uri,
        coverPath: coverPath,
        format: format,
        totalPages: totalPages,
        currentPage: 0,
        readProgress: 0,
        lastReadTime: 0,
        addTime: Date.now(),
        status: ReadStatus.UNREAD,
        isFavorite: false,
        groupIds: [],
        totalReadTime: 0,
        fileSize: fileSize
      };

      bookViewModel.addBook(book);
      existingPaths.add(uri);
      return 'success';
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('瀵煎叆澶辫触: ' + uri + ', ' + message);
      return 'failed';
    }
  }

  /**
   * 鎵╁睍鍚嶈浆鏍煎紡锛堝寮虹増 - 鏀寔 16 绉嶆牸寮忥級
   */
  private extensionToFormat(extension: string): BookFormat {
    const lowerExt = extension.toLowerCase();
    if (lowerExt === '.pdf') return BookFormat.PDF;
    if (lowerExt === '.epub') return BookFormat.EPUB;
    if (lowerExt === '.mobi') return BookFormat.MOBI;
    if (lowerExt === '.txt' || lowerExt === '.text') return BookFormat.TXT;
    if (lowerExt === '.docx') return BookFormat.DOCX;
    if (lowerExt === '.doc') return BookFormat.DOC;
    if (lowerExt === '.rtf') return BookFormat.RTF;
    if (lowerExt === '.html' || lowerExt === '.htm') return BookFormat.HTML;
    if (lowerExt === '.azw') return BookFormat.AZW;
    if (lowerExt === '.azw3') return BookFormat.AZW3;
    if (lowerExt === '.djvu' || lowerExt === '.djv') return BookFormat.DJVU;
    if (lowerExt === '.chm') return BookFormat.CHM;
    if (lowerExt === '.fb2') return BookFormat.FB2;
    if (lowerExt === '.odt') return BookFormat.ODT;
    if (lowerExt === '.cbr') return BookFormat.CBR;
    if (lowerExt === '.cbz') return BookFormat.CBZ;
    return BookFormat.TXT;
  }

  /**
   * 鎵归噺鎿嶄綔 - 鍒囨崲閫夋嫨
   */
  private toggleBatchSelection(book: BookInfo): void {
    this.mainPageVM.toggleSelectBook(book.id);
  }

  /**
   * 鎵归噺鎿嶄綔 - 鍏拷?鍙栨秷鍏拷?
   */
  private selectAllBooks(): void {
    if (this.mainPageVM.selectedBooks.size === this.mainPageVM.displayBooks.length) {
      this.mainPageVM.deselectAll();
    } else {
      this.mainPageVM.selectAll();
    }
  }

  /**
   * 鎵归噺鎿嶄綔 - 閫€鍑烘壒閲忔ā锟?
   */
  private exitBatchMode(): void {
    this.mainPageVM.isBatchMode = false;
    this.mainPageVM.selectedBooks.clear();
  }

  /**
   * 鎵归噺鎿嶄綔 - 鍒犻櫎涔︾
   */
  private batchDeleteBooks(): void {
    const selectedCount = this.mainPageVM.selectedBooks.size;
    promptAction.showDialog({
      title: '纭鍒犻櫎',
      message: '纭畾瑕佸垹锟? + selectedCount + '鏈功鍚楋紵姝ゆ搷浣滀笉鍙挙閿€锟?,
      buttons: [
        { text: '鍙栨秷', color: '#888888' },
        { text: '鍒犻櫎', color: '#FF0000' }
      ]
    }).then((data: promptAction.ShowDialogSuccessResponse) => {
      if (data.index === 1) {
        this.mainPageVM.deleteSelectedBooks();
      }
    }).catch((err: Error) => {
      console.error('Dialog error:', err.message);
    });
  }

  /**
   * 鎵归噺鎿嶄綔 - 鏀惰棌
   */
  private batchToggleFavorite(): void {
    const bookIds: string[] = Array.from(this.mainPageVM.selectedBooks);
    for (let i = 0; i < bookIds.length; i++) {
      bookViewModel.toggleFavorite(bookIds[i]);
    }
    toast('宸叉敹锟? + this.mainPageVM.selectedBooks.size + '鏈功');
    this.exitBatchMode();
    this.loadBooks();
  }

  /**
   * 鍒嗙粍 - 閫夋嫨鍒嗙粍
   */
  private selectGroup(groupId: string): void {
    this.mainPageVM.setCurrentGroup(groupId);
    this.mainPageVM.showGroupPanel = false;
  }

  /**
   * 鍒嗙粍 - 鍒涘缓鍒嗙粍
   */
  private createGroup(): void {
    const groupName = this.mainPageVM.newGroupName.trim();
    if (groupName.length === 0) {
      toast('鍒嗙粍鍚嶇О涓嶈兘涓虹┖');
      return;
    }

    this.mainPageVM.addGroup(groupName);
    this.mainPageVM.newGroupName = '';
    this.mainPageVM.showAddGroupDialog = false;
    toast('鍒嗙粍鍒涘缓鎴愬姛');
  }

  /**
   * 鎼滅储 - 澶勭悊鎼滅储鏂囨湰鍙樺寲
   */
  private onSearchChange(text: string): void {
    this.mainPageVM.searchBooks(text);
  }

  /**
   * 鎼滅储 - 鍏抽棴鎼滅储
   */
  private onSearchClose(): void {
    this.mainPageVM.showSearchBar = false;
    this.mainPageVM.searchText = '';
    this.mainPageVM.loadBooks();
  }

  /**
   * 绛涳拷?- 鍒囨崲绛涢€夋潯锟?
   */
  private onFilterChange(filter: number): void {
    this.mainPageVM.setFilter(filter);
  }

  /**
   * 鎺掑簭 - 鍒囨崲鎺掑簭妯″紡
   */
  private onSortChange(sortMode: number): void {
    this.mainPageVM.setSortMode(sortMode);
  }

  build() {
    Navigation(this.pageInfos) {
      Stack() {
        Column() {
          // 主内容区域
          Column() {
            // 根据当前标签页显示不同的内容
            if (this.mainPageVM.currentTab === 0) {
              // 首页
              HomeContent({
                recentBooks: this.mainPageVM.recentBooks,
                isDarkMode: this.mainPageVM.isDarkMode,
                onBookClick: (book: BookInfo) => this.onBookClick(book),
                onOpenFilePicker: () => this.openFilePicker(),
                onOpenSmartServices: () => this.mainPageVM.showSmartServices = true
              })
            } else if (this.mainPageVM.currentTab === 1) {
              // 书架 - 暂时注释，需要创建BookshelfContent组件
              Text('书架内容待实现')
                .fontSize(16)
                .fontColor(this.mainPageVM.currentColors.textSecondary)
            } else if (this.mainPageVM.currentTab === 2) {
              // 书城（在线搜索）
              OnlineSearchPage()
            } else if (this.mainPageVM.currentTab === 3) {
              // 发现
              DiscoverContent({
                isDarkMode: this.mainPageVM.isDarkMode,
                onOpenFolderScanner: () => this.openFilePicker()
              })
            } else {
              // 我的（设置）
              SettingsPage()
            }
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(this.mainPageVM.currentColors.background)
          .padding({
            left: layoutHelper.getResponsiveSpacing(),
            right: layoutHelper.getResponsiveSpacing()
          })

          // 底部导航栏 - 始终可见
          if (!this.mainPageVM.isBatchMode) {
            TabBar({
              currentTab: this.mainPageVM.currentTab,
              isDarkMode: this.mainPageVM.isDarkMode,
              onTabChange: (index: number) => this.mainPageVM.currentTab = index
            })
          }
        }
        .width('100%')
        .height('100%')

        // 搜索栏 - 弹出层
        if (this.mainPageVM.showSearchBar) {
          Stack() {
            // 半透明遮罩
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0,0,0,0.5)')
              .onClick(() => this.onSearchClose())

            // 搜索栏
            SearchBar({
              isDarkMode: this.mainPageVM.isDarkMode,
              searchText: this.mainPageVM.searchText,
              onSearchChange: (text: string) => this.onSearchChange(text),
              onClose: () => this.onSearchClose()
            })
            .transition(
              TransitionEffect.OPACITY.animation({ duration: 200 })
                .combine(TransitionEffect.translate({ y: -50 }))
            )
          }
          .zIndex(100)
        }

        // 分组面板 - 从右侧滑入
        if (this.mainPageVM.showGroupPanel) {
          Stack() {
            // 半透明遮罩
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0,0,0,0.5)')
              .onClick(() => this.mainPageVM.showGroupPanel = false)

            GroupPanel({
              isDarkMode: this.mainPageVM.isDarkMode,
              currentGroupId: this.mainPageVM.currentGroupId,
              groups: this.mainPageVM.groups,
              showAddGroupDialog: this.mainPageVM.showAddGroupDialog,
              onPanelClose: () => this.mainPageVM.showGroupPanel = false,
              onSelectGroup: (groupId: string) => this.selectGroup(groupId),
              onShowAddGroup: () => this.mainPageVM.showAddGroupDialog = true
            })
            .transition(TransitionEffect.translate({ x: 300 }))
          }
          .zIndex(200)
        }

        // 添加分组对话框
        if (this.mainPageVM.showAddGroupDialog) {
          AddGroupDialog({
            isDarkMode: this.mainPageVM.isDarkMode,
            newGroupName: this.mainPageVM.newGroupName,
            onDialogClose: () => this.mainPageVM.showAddGroupDialog = false,
            onCreateGroup: (name: string) => {
              if (name.length > 0) {
                this.mainPageVM.newGroupName = name;
                this.createGroup();
              }
            }
          })
          .zIndex(300)
          .transition(
            TransitionEffect.OPACITY.animation({ duration: 200 })
              .combine(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
          )
        }

        // 智能服务面板
        if (this.mainPageVM.showSmartServices) {
          SmartServicesPanel({
            isDarkMode: this.mainPageVM.isDarkMode,
            panelContext: this.mainPageVM.context,
            onClose: () => this.mainPageVM.showSmartServices = false
          })
          .zIndex(200)
        }
      }
    }
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
    .title('千读阅界')
    .hideTitleBar(true)
    .height('100%')
    .width('100%')
  }

  @Builder
  pageMap(name: string) {
    NavDestination() {
      if (name === 'EnhancedReaderPage') {
        EnhancedReaderPage()
      } else if (name === 'BookDetailPage') {
        BookDetailPage()
      } else if (name === 'OnlineBookDetailPage') {
        OnlineBookDetailPage()
      } else if (name === 'OnlineSearchPage') {
        OnlineSearchPage()
      } else if (name === 'SettingsPage') {
        SettingsPage()
      } else if (name === 'ProfilePage') {
        ProfilePage()
      } else if (name === 'ReadRecordPage') {
        ReadRecordPage()
      } else if (name === 'ReadingStatsPage') {
        ReadingStatsPage()
      } else if (name === 'BookmarksPage') {
        BookmarksPage()
      } else if (name === 'NotesPage') {
        NotesPage()
      } else if (name === 'DictionaryPage') {
        DictionaryPage()
      } else if (name === 'WordBookPage') {
        WordBookPage()
      } else if (name === 'LoginPage') {
        LoginPage()
      } else if (name === 'FeedbackPage') {
        FeedbackPage()
      } else if (name === 'HelpPage') {
        HelpPage()
      } else if (name === 'FeaturesPage') {
        FeaturesPage()
      } else if (name === 'SkillPage') {
        SkillPage()
      } else if (name === 'RewardPage') {
        RewardPage()
      } else if (name === 'SourceMarketPage') {
        SourceMarketPage()
      } else if (name === 'OnlineSourceMarketPage') {
        OnlineSourceMarketPage()
      } else if (name === 'FolderScannerPage') {
        FolderScannerPage()
      } else if (name === 'ComicReaderPage') {
        ComicReaderPage()
      } else if (name === 'EyeTrackingCalibrationPage') {
        EyeTrackingCalibrationPage()
      } else if (name === 'TodoPage') {
        TodoPage()
      } else if (name === 'StatisticsPage') {
        StatisticsPage()
      } else {
        Text('Unknown page: ' + name)
      }
    }
    .onReady((context: NavDestinationContext) => {
      // 鑾峰彇鍙傛暟
      const params = context.pathInfo.param as Record<string, string>;
      if (params) {
        // 鍙傛暟澶勭悊閫昏緫鍦ㄥ悇涓〉闈㈠唴锟?
      }
    })
  }
}

// 棰勮缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮
@Preview
@Component
struct MainPagePreview {
  build() {
    Column() {
      Text('涓婚〉 - 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      MainPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('涓婚〉 - 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      MainPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}

export default MainPage;
