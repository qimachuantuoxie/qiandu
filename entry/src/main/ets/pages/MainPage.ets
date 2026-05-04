import { toast, navigateTo, goBack, navHelper } from '../common';
import { NavPathStack } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { BookInfo, BookFormat, ReadStatus, generateBookId } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { mainPageViewModel, MainPageViewModel } from '../features/home/viewmodels/MainPageViewModel';
import { HomeContent } from '../features/home/components/HomePage';
import { DiscoverContent } from '../features/discover/components/DiscoverPage';
import { SettingsPage } from '../features/settings/pages/SettingsPage';
import { OptimizedTabBar, TabBarItem } from '../common/components/OptimizedTabBar';
import { SearchBar } from '../common/components/SearchBar';
import { GroupPanel, AddGroupDialog } from '../features/bookshelf/components/GroupPanel';
import { SmartServicesPanel } from '../common/components/SmartServicesPanel';
import { promptAction } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
import { Spacing, Size, BorderRadius, getShadow } from '../common/constants/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';

type ImportResult = 'success' | 'failed' | 'skipped';

@Entry
@ComponentV2
struct MainPage {
  @Local pageInfos: NavPathStack = new NavPathStack();
  @Local currentTabIndex: number = 0;
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local showSearch: boolean = false;
  @Local showGroupPanel: boolean = false;
  
  private mainPageVM: MainPageViewModel = mainPageViewModel;
  
  // TabBar配置 - 5个标签页
  private tabBarItems: TabBarItem[] = [
    { icon: 'house.fill', activeIcon: 'house.fill', label: '首页' },
    { icon: 'book.fill', activeIcon: 'book.fill', label: '书架' },
    { icon: 'magnifyingglass', activeIcon: 'magnifyingglass.circle.fill', label: '书城' },
    { icon: 'compass.drawing', activeIcon: 'compass.drawing', label: '发现' },
    { icon: 'person', activeIcon: 'person.fill', label: '我的' }
  ];

  aboutToAppear() {
    const context = this.getUIContext().getHostContext();
    if (context) {
      this.initData(context);
      this.mainPageVM.initApp(context);
    }
  }

  private async initData(context: Context): Promise<void> {
    await layoutHelper.init(context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(context);
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
  }

  aboutToDisappear() {
    this.mainPageVM.cleanup();
  }

  private onBookClick(book: BookInfo): void {
    this.pageInfos.pushPath({
      name: 'EnhancedReaderPage',
      param: { bookId: book.id }
    });
  }

  private async openFilePicker(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const documentSelectOptions = new picker.DocumentSelectOptions();

      documentSelectOptions.fileSuffixFilters = [
        '.txt', '.text', '.pdf', '.epub', '.mobi',
        '.doc', '.docx', '.rtf', '.html', '.htm',
        '.azw', '.azw3', '.djvu', '.djv', '.chm',
        '.fb2', '.odt', '.cbr', '.cbz'
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

  private async importFiles(fileUris: string[]): Promise<void> {
    if (fileUris.length === 0) return;

    const totalFiles = fileUris.length;
    let successCount = 0;
    let failedCount = 0;
    let skippedCount = 0;

    const existingBooks = bookViewModel.getAllBooks();
    const existingPaths = new Set<string>();
    for (let i = 0; i < existingBooks.length; i++) {
      existingPaths.add(existingBooks[i].filePath);
    }

    toast('开始导入 ' + totalFiles + ' 个文件...');

    const concurrency = 3;
    for (let i = 0; i < fileUris.length; i += concurrency) {
      const batchEnd = Math.min(i + concurrency, fileUris.length);
      const batch: string[] = [];
      for (let j = i; j < batchEnd; j++) {
        batch.push(fileUris[j]);
      }

      const processedCount = batchEnd;
      toast('正在导入 ' + processedCount + '/' + totalFiles + '...');

      for (let k = 0; k < batch.length; k++) {
        const result = await this.importSingleFile(batch[k], existingPaths);
        if (result === 'success') successCount++;
        else if (result === 'failed') failedCount++;
        else if (result === 'skipped') skippedCount++;
      }
    }

    let resultMsg = '导入完成！';
    if (successCount > 0) resultMsg += '\n成功: ' + successCount;
    if (failedCount > 0) resultMsg += '\n失败: ' + failedCount;
    if (skippedCount > 0) resultMsg += '\n跳过: ' + skippedCount;
    
    toast(resultMsg);
    this.mainPageVM.loadBooks();
  }

  private async importSingleFile(uri: string, existingPaths: Set<string>): Promise<ImportResult> {
    try {
      if (existingPaths.has(uri)) {
        return 'skipped';
      }

      const parser = new EbookParser();
      const result: ParseResult = await parser.parse(uri);
      
      if (!result.success || !result.bookInfo) {
        return 'failed';
      }

      const bookInfo = result.bookInfo;
      bookInfo.filePath = uri;
      bookInfo.format = this.getFormatFromUri(uri);
      bookInfo.addTime = Date.now();
      bookInfo.readStatus = ReadStatus.NOT_STARTED;
      bookInfo.progress = 0;
      bookInfo.totalReadingTime = 0;
      bookInfo.lastReadTime = 0;
      bookInfo.lastReadChapter = 0;
      bookInfo.isFavorite = false;
      bookInfo.groupIds = [];

      bookViewModel.addBook(bookInfo);
      existingPaths.add(uri);
      
      return 'success';
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('导入失败: ' + message);
      return 'failed';
    }
  }

  private getFormatFromUri(uri: string): BookFormat {
    const ext = uri.toLowerCase().split('.').pop();
    switch (ext) {
      case 'epub': return BookFormat.EPUB;
      case 'pdf': return BookFormat.PDF;
      case 'txt': return BookFormat.TXT;
      case 'mobi': return BookFormat.MOBI;
      case 'doc':
      case 'docx': return BookFormat.DOCX;
      default: return BookFormat.TXT;
    }
  }

  build() {
    Navigation(this.pageInfos) {
      Stack() {
        Column() {
          // 顶部搜索栏（条件显示）
          if (this.showSearch) {
            this.SearchHeader()
          }

          // 主内容区
          this.MainContent()
        }
        .width('100%')
        .height('100%')

        // 底部导航栏
        OptimizedTabBar({
          items: this.tabBarItems,
          currentIndex: this.currentTabIndex,
          onTabChange: (index: number) => {
            this.currentTabIndex = index;
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }

  @Builder
  SearchHeader() {
    Row() {
      SearchBar({
        placeholder: '搜索书籍、作者...',
        onSearch: (keyword: string) => {
          console.log('搜索:', keyword);
        },
        onCancel: () => {
          this.showSearch = false;
        }
      })
      .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  MainContent() {
    if (this.currentTabIndex === 0) {
      // 首页
      Column() {
        // 顶部操作栏
        this.HomeHeader()

        // 首页内容
        HomeContent({
          onBookClick: (book: BookInfo) => this.onBookClick(book),
          onAddBook: () => this.openFilePicker()
        })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    } else if (this.currentTabIndex === 1) {
      // 书架
      Column() {
        // 书架头部
        this.BookshelfHeader()

        // 书架内容（简化版，实际应使用BookshelfPage组件）
        Scroll() {
          Column({ space: Spacing.md }) {
            Text('书架功能开发中...')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
              .padding(Spacing.xxxl)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    } else if (this.currentTabIndex === 2) {
      // 书城
      Column() {
        Text('书城功能开发中...')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
          .padding(Spacing.xxxl)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (this.currentTabIndex === 3) {
      // 发现
      DiscoverContent({
        onBookClick: (book: BookInfo) => this.onBookClick(book)
      })
    } else {
      // 我的
      SettingsPage()
    }
  }

  @Builder
  HomeHeader() {
    Row() {
      // 标题
      Text('千读阅界')
        .fontSize(fontScaleManager.getScaledFontSize(24))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)

      // 搜索按钮
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconMD)
          .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showSearch = !this.showSearch;
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      // 添加书籍按钮
      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(Size.iconMD)
          .fontColor(['#FFFFFF'])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
      .justifyContent(FlexAlign.Center)
      .margin({ left: Spacing.sm })
      .onClick(() => this.openFilePicker())
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
    .padding({ 
      left: Spacing.lg, 
      right: Spacing.lg, 
      top: Spacing.lg,
      bottom: Spacing.md
    })
  }

  @Builder
  BookshelfHeader() {
    Row() {
      Text('我的书架')
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)

      // 分组管理按钮
      Row() {
        SymbolGlyph($r('sysymbol.folder'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showGroupPanel = true;
      })

      // 添加书籍按钮
      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(Size.iconMD)
          .fontColor(['#FFFFFF'])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
      .justifyContent(FlexAlign.Center)
      .margin({ left: Spacing.sm })
      .onClick(() => this.openFilePicker())
    }
    .width('100%')
    .padding({ 
      left: Spacing.lg, 
      right: Spacing.lg, 
      top: Spacing.lg,
      bottom: Spacing.md
    })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }
}

// 预览组件
@Preview
@ComponentV2
struct MainPagePreview {
  build() {
    Column() {
      Text('主页 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      MainPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('主页 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      MainPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
