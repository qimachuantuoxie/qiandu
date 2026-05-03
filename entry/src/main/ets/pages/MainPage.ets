// 主页 - 优化版(使用拆分的组件)
// Main Page - Optimized Version with Split Components

import { toast } from '../utils/ToastHelper';
import { navigateTo } from '../utils/NavigationHelper';
import { picker } from '@kit.CoreFileKit';
import { BookInfo, BookFormat, ReadStatus, generateBookId } from '../models/CoreBookModel';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { mainPageViewModel, MainPageViewModel } from '../viewmodels/MainPageViewModel';
import { EbookParser, ParseResult } from '../utils/EbookParser';
import { BookCoverData } from '../services/image/DynamicCoverService';
import { HomeContent } from '../presentation/features/home/HomeContent';
import { BookshelfContent } from '../presentation/features/bookshelf/BookshelfContent';
import { DiscoverContent } from '../presentation/features/discover/DiscoverContent';
import { SettingsContent } from '../presentation/features/settings/SettingsContent';
import { TabBar } from '../components/TabBar';
import { SearchBar } from '../components/SearchBar';
import { GroupPanel, AddGroupDialog } from '../features/bookshelf/components/GroupPanel';
import { OnlineSearchPage } from './OnlineSearchPage';
import { SmartServicesPanel } from '../components/SmartServicesPanel';
import { promptAction } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';

/**
 * 导入结果类型
 */
type ImportResult = 'success' | 'failed' | 'skipped';

@Entry
@Component
struct MainPage {
  private mainPageVM: MainPageViewModel = mainPageViewModel;

  /**
   * 页面初始化
   */
  aboutToAppear() {
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.mainPageVM.initApp(context);
    }
  }

  /**
   * 页面销毁
   */
  aboutToDisappear() {
    this.mainPageVM.cleanup();
  }

  /**
   * 加载书籍
   */
  private loadBooks(): void {
    this.mainPageVM.loadBooks();
  }

  /**
   * 按需获取封面数据
   */
  private getCoverData(bookId: string): BookCoverData {
    return this.mainPageVM.getCoverData(bookId);
  }


  /**
   * 加载更多
   */
  private loadMore(): void {
    if (this.mainPageVM.isLoading || !this.mainPageVM.hasMore) {
      return;
    }
    this.mainPageVM.loadMoreBooks();
  }

  /**
   * 书籍点击
   */
  private onBookClick(book: BookInfo): void {
    const params: Record<string, string> = {};
    params['bookId'] = book.id;
    navigateTo('pages/EnhancedReaderPage', params);
  }

  /**
   * 打开文件选择器
   */
  private async openFilePicker(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const documentSelectOptions = new picker.DocumentSelectOptions();

      // 扩展支持所有解析器支持的格式（16种）
      documentSelectOptions.fileSuffixFilters = [
        '.txt', '.text',          // 纯文本
        '.pdf',                   // PDF 文档
        '.epub',                  // EPUB 电子书
        '.mobi',                  // Mobipocket
        '.doc', '.docx',          // Word 文档
        '.rtf',                   // 富文本格式
        '.html', '.htm',          // 网页文件
        '.azw', '.azw3',          // Kindle 格式
        '.djvu', '.djv',          // 扫描文档
        '.chm',                   // 编译 HTML 帮助
        '.fb2',                   // FictionBook
        '.odt',                   // OpenDocument 文本
        '.cbr', '.cbz'            // 漫画压缩包
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
      console.error('文件选择失败: ' + message);
      toast('文件选择失败，请重试');
    }
  }

  /**
   * 导入文件（增强版 - 支持多格式、并发、进度反馈）
   */
  private async importFiles(fileUris: string[]): Promise<void> {
    if (fileUris.length === 0) {
      return;
    }

    const totalFiles = fileUris.length;
    let successCount = 0;
    let failedCount = 0;
    let skippedCount = 0;

    // 预先获取已导入书籍列表（优化性能）
    const existingBooks = bookViewModel.getAllBooks();
    const existingPaths = new Set<string>();
    for (let i = 0; i < existingBooks.length; i++) {
      existingPaths.add(existingBooks[i].filePath);
    }

    // 显示导入进度
    toast('开始导入 ' + totalFiles + ' 个文件...');

    // 并发导入（控制并发数为 3）
    const concurrency = 3;
    for (let i = 0; i < fileUris.length; i += concurrency) {
      const batchEnd = i + concurrency;
      const batch: string[] = [];
      for (let j = i; j < batchEnd && j < fileUris.length; j++) {
        batch.push(fileUris[j]);
      }
      const currentBatch = Math.floor(i / concurrency) + 1;
      const totalBatches = Math.ceil(fileUris.length / concurrency);

      // 更新进度
      const processedCount = batchEnd < fileUris.length ? batchEnd : fileUris.length;
        toast('正在导入 ' + processedCount + '/' + totalFiles + '...');

      // 并发处理批次
      const results: ImportResult[] = [];
      for (let k = 0; k < batch.length; k++) {
        const result = await this.importSingleFile(batch[k], existingPaths);
        results.push(result);
      }

      // 统计结果
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

    // 显示导入结果
    let message = '导入完成！成功 ' + successCount + ' 本';
    if (skippedCount > 0) {
      message += '，跳过 ' + skippedCount + ' 本（已存在）';
    }
    if (failedCount > 0) {
      message += '，失败 ' + failedCount + ' 本';
    }

    toast(message);
    this.loadBooks();
  }

  /**
   * 导入单个文件
   */
  private async importSingleFile(
    uri: string,
    existingPaths: Set<string>
  ): Promise<ImportResult> {
    try {
      // 检查是否已导入
      if (existingPaths.has(uri)) {
        console.info('文件已存在，跳过: ' + uri);
        return 'skipped';
      }

      const pathParts = uri.split('/');
      let fileName = '未知书籍';
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
      let author = '未知作者';
      let totalPages = 100;
      let coverPath = '';
      let fileSize = 0;

      try {
        // 使用增强解析器解析元数据
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
        console.warn('解析书籍元数据失败: ' + message);
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
      console.error('导入失败: ' + uri + ', ' + message);
      return 'failed';
    }
  }

  /**
   * 扩展名转格式（增强版 - 支持 16 种格式）
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
   * 批量操作 - 切换选择
   */
  private toggleBatchSelection(book: BookInfo): void {
    this.mainPageVM.toggleSelectBook(book.id);
  }

  /**
   * 批量操作 - 全选/取消全选
   */
  private selectAllBooks(): void {
    if (this.mainPageVM.selectedBooks.size === this.mainPageVM.displayBooks.length) {
      this.mainPageVM.deselectAll();
    } else {
      this.mainPageVM.selectAll();
    }
  }

  /**
   * 批量操作 - 退出批量模式
   */
  private exitBatchMode(): void {
    this.mainPageVM.isBatchMode = false;
    this.mainPageVM.selectedBooks.clear();
  }

  /**
   * 批量操作 - 删除书籍
   */
  private batchDeleteBooks(): void {
    const selectedCount = this.mainPageVM.selectedBooks.size;
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除' + selectedCount + '本书吗？此操作不可撤销。',
      buttons: [
        { text: '取消', color: '#888888' },
        { text: '删除', color: '#FF0000' }
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
   * 批量操作 - 收藏
   */
  private batchToggleFavorite(): void {
    const bookIds: string[] = Array.from(this.mainPageVM.selectedBooks);
    for (let i = 0; i < bookIds.length; i++) {
      bookViewModel.toggleFavorite(bookIds[i]);
    }
    toast('已收藏' + this.mainPageVM.selectedBooks.size + '本书');
    this.exitBatchMode();
    this.loadBooks();
  }

  /**
   * 分组 - 选择分组
   */
  private selectGroup(groupId: string): void {
    this.mainPageVM.setCurrentGroup(groupId);
    this.mainPageVM.showGroupPanel = false;
  }

  /**
   * 分组 - 创建分组
   */
  private createGroup(): void {
    const groupName = this.mainPageVM.newGroupName.trim();
    if (groupName.length === 0) {
      toast('分组名称不能为空');
      return;
    }

    this.mainPageVM.addGroup(groupName);
    this.mainPageVM.newGroupName = '';
    this.mainPageVM.showAddGroupDialog = false;
    toast('分组创建成功');
  }

  /**
   * 搜索 - 处理搜索文本变化
   */
  private onSearchChange(text: string): void {
    this.mainPageVM.searchBooks(text);
  }

  /**
   * 搜索 - 关闭搜索
   */
  private onSearchClose(): void {
    this.mainPageVM.showSearchBar = false;
    this.mainPageVM.searchText = '';
    this.mainPageVM.loadBooks();
  }

  /**
   * 筛选 - 切换筛选条件
   */
  private onFilterChange(filter: number): void {
    this.mainPageVM.setFilter(filter);
  }

  /**
   * 排序 - 切换排序模式
   */
  private onSortChange(sortMode: number): void {
    this.mainPageVM.setSortMode(sortMode);
  }

  build() {
    Stack() {
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
          // 书架
          BookshelfContent({
            isDarkMode: this.mainPageVM.isDarkMode,
            isTablet: this.mainPageVM.isTablet,
            isBatchMode: this.mainPageVM.isBatchMode,
            selectedBooks: this.mainPageVM.selectedBooks,
            showBatchBar: this.mainPageVM.showBatchBar,
            currentFilter: this.mainPageVM.currentFilter,
            currentGroupId: this.mainPageVM.currentGroupId,
            currentSortMode: this.mainPageVM.currentSortMode,
            searchText: this.mainPageVM.searchText,
            displayBooks: this.mainPageVM.displayBooks,
            gridColumns: this.mainPageVM.gridColumns,
            coverDataMap: this.mainPageVM.coverDataMap as Map<string, BookCoverData>,
            onGetCoverData: (bookId: string): BookCoverData => this.getCoverData(bookId),
            onBookClick: (book: BookInfo) => this.onBookClick(book),
            onOpenFilePicker: () => this.openFilePicker(),
            onToggleBatchSelection: (book: BookInfo) => this.toggleBatchSelection(book),
            onExitBatchMode: () => this.exitBatchMode(),
            onSelectAllBooks: () => this.selectAllBooks(),
            onBatchDelete: () => this.batchDeleteBooks(),
            onBatchToggleFavorite: () => this.batchToggleFavorite(),
            onShowGroupPanel: () => this.mainPageVM.showGroupPanel = true,
            onFilterChange: (filter: number) => this.onFilterChange(filter),
            onSortChange: (sortMode: number) => this.onSortChange(sortMode),
            onSearchChange: (text: string) => {
              this.mainPageVM.showSearchBar = true;
              this.onSearchChange(text);
            }
          })
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
          SettingsContent({
            isDarkMode: this.mainPageVM.isDarkMode
          })
        }

        // 底部导航栏
        TabBar({
          currentTab: this.mainPageVM.currentTab,
          isDarkMode: this.mainPageVM.isDarkMode,
          onTabChange: (index: number) => this.mainPageVM.currentTab = index
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.mainPageVM.currentColors.background)

      // 搜索栏
      if (this.mainPageVM.showSearchBar) {
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

      // 分组面板
      if (this.mainPageVM.showGroupPanel) {
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
      }
    }
    .width('100%')
    .height('100%')
  }
}

export default MainPage;
