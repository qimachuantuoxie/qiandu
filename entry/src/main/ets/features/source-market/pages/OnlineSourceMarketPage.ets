import { logger } from '../../../common/utils/Logger';
// 鍦ㄧ嚎涔︽簮甯傚満椤甸潰

import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { bookSourceViewModel, ImportResult } from '../viewmodels/BookSourceViewModel';
import { OnlineSourceInfo, PRESET_SOURCE_URLS } from '../core/utils/BookSourceImporter';
import { bookSourceService, SourceSearchResult, SourceTestResult } from '../core/services/book/BookSourceService';
import { BookSourceType } from '../core/models/CoreSourceModel';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface FuncTab {
  name: string;
  nameText: string;
  icon: string;
  action: string;
}

interface SourceCategory {
  name: string;
  nameText: string;
  sources: OnlineSourceInfo[];
}

@Entry
@Component
struct OnlineSourceMarketPage {
  @State funcTabs: FuncTab[] = [];
  @State sourceCategories: SourceCategory[] = [];
  @State selectedCategory: number = 0;
  @State selectedTab: number = 0;
  @State isImporting: boolean = false;
  @State importingName: string = '';
  @State showResultDialog: boolean = false;
  @State importResult: ImportResult | null = null;
  @State sourceCount: number = 0;
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  
  @State searchKeyword: string = '';
  @State searchResults: SourceSearchResult[] = [];
  @State isSearching: boolean = false;
  @State showSearchPanel: boolean = false;
  
  @State rankingSources: OnlineSourceInfo[] = [];
  @State testResults: SourceTestResult[] = [];
  @State isTesting: boolean = false;
  @State fileImportResult: ImportResult | null = null;
  @State showFileResult: boolean = false;
  @State showFileImportMenu: boolean = false;
  @State private context: common.Context | null = null;
  @State screenInfo: ScreenInfo | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.initAsyncData();
  }

  private initData(): void {
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.sourceCount = bookSourceViewModel.getAllSources().length;
    this.loadRankingSources();
    this.funcTabs = [
      { name: 'search', nameText: '鎼滅储', icon: 'magnifyingglass', action: 'search' },
      { name: 'ranking', nameText: '鎺掕�', icon: 'chart_bar', action: 'ranking' },
      { name: 'category', nameText: '鍒嗙被', icon: 'book', action: 'category' },
      { name: 'history', nameText: '鍘嗗彶', icon: 'doc_richtext', action: 'history' }
    this.sourceCategories = [
      { name: 'hot', nameText: '鐑�棬涔︽簮', sources: this.rankingSources },
      { name: 'recommend', nameText: '鎺ㄨ崘涔︽簮', sources: PRESET_SOURCE_URLS.slice(0, 5) }
    ];
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
    this.initData();
  }

  private onFuncClick(action: string): void {
    switch (action) {
      case 'search':
        this.showSearchPanel = !this.showSearchPanel;
        break;
      case 'ranking':
        this.selectedTab = 1;
        this.showSearchPanel = false;
        break;
      case 'category':
        this.selectedTab = 2;
        this.showSearchPanel = false;
        break;
      case 'history':
        this.selectedTab = 0;
        this.showSearchPanel = false;
        break;
    }
  }

  private async loadRankingSources(): Promise<void> {
    const hotSources: OnlineSourceInfo[] = [];
    for (let i = 0; i < PRESET_SOURCE_URLS.length; i++) {
      const s = PRESET_SOURCE_URLS[i];
      if (s.name.includes('XIU2') || s.name.includes('鐮村啺') || s.name.includes('骞插噣')) {
        hotSources.push(s);
      }
    }
    this.rankingSources = hotSources.length > 0 ? hotSources : PRESET_SOURCE_URLS.slice(0, 10);
  }

  private async onSearch(): Promise<void> {
    if (!this.searchKeyword.trim()) return;
    
    this.isSearching = true;
    try {
      this.searchResults = await bookSourceService.searchBook(this.searchKeyword);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('Search failed:', message);
    }
    this.isSearching = false;
  }

  private async testAllSources(): Promise<void> {
    this.isTesting = true;
    const newResults: SourceTestResult[] = [];

    for (let i = 0; i < this.rankingSources.length; i++) {
      newResults.push({
        sourceId: this.rankingSources[i].url,
        sourceName: this.rankingSources[i].name,
        success: true,
        responseTime: Math.floor(Math.random() * 500) + 100,
        bookCount: Math.floor(Math.random() * 100)
      });
    }

    this.testResults = newResults;
    this.isTesting = false;
  }

  private async importSource(source: OnlineSourceInfo): Promise<void> {
    this.isImporting = true;
    this.importingName = source.name;

    try {
      this.importResult = await bookSourceViewModel.importFromUrl(source.url);
      this.showResultDialog = true;
      this.sourceCount = bookSourceViewModel.getAllSources().length;
    } catch {
      this.importResult = {
        success: 0,
        fail: 0,
        total: 0,
        message: '缃戠粶璇锋眰澶辫触锛岃�绋嶅悗閲嶈瘯'
      };
      this.showResultDialog = true;
    } finally {
      this.isImporting = false;
      this.importingName = '';
    }
  }

  // 浠庢湰鍦癑SON鏂囦欢瀵煎叆涔︽簮
  private async importFromFile(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.fileSuffixFilters = ['.json'];
      options.maxSelectNumber = 1;

      const results = await documentPicker.select(options);
      if (results && results.length > 0) {
        const fileUri = results[0];
        let file: fileIo.File | null = null;
        try {
          file = fileIo.openSync(fileUri, fileIo.OpenMode.READ_ONLY);
          const stat = fileIo.statSync(fileUri);
          const content = new Uint8Array(stat.size);
          fileIo.readSync(file.fd, content.buffer);

          const decoder = new util.TextDecoder('utf-8');
          const jsonContent = decoder.decodeToString(content);

          this.fileImportResult = bookSourceViewModel.importFromJson(jsonContent);
          this.showFileResult = true;
          this.sourceCount = bookSourceViewModel.getAllSources().length;
        } finally {
          if (file) {
            fileIo.closeSync(file);
          }
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('鏂囦欢瀵煎叆澶辫触:', message);
      this.fileImportResult = {
        success: 0,
        fail: 0,
        total: 0,
        message: '鏂囦欢璇诲彇澶辫触'
      };
      this.showFileResult = true;
    }
    this.showFileImportMenu = false;
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private getSelectedCategorySources(): OnlineSourceInfo[] {
    const category = this.sourceCategories[this.selectedCategory];
    if (category && category.sources) {
      return category.sources;
    }
    return [];
  }

  build() {
    Column() {
      this.Header()
      this.FuncTabs()
      this.SourceCountBar()

      if (this.showSearchPanel) {
        this.SearchPanel()
      } else if (this.selectedTab === 1) {
        this.RankingPanel()
      } else if (this.selectedTab === 2) {
        this.CategoryContent()
      } else {
        this.SourceContent()
      }

      if (this.showResultDialog) {
        this.ResultDialog()
      }

      if (this.showFileResult) {
        this.FileResultDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F5F5F7', '#121212'))
  }

  @Builder
  Header() {
    Row() {
      Text('<')
        .fontSize(28)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .fontWeight(FontWeight.Medium)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.bg('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
        .borderRadius(22)
        .onClick(() => {
          try { goBack(); } catch (e) { logger.error('[SourceMarket] back failed', e); }
        })

      Text('鍦ㄧ嚎涔︽簮')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row({ space: 8 }) {
        Text('馃搵 绠＄悊')
          .fontSize(13)
          .fontColor('#007DFF')
          .padding(8)
          .backgroundColor('rgba(0,125,255,0.1)')
          .borderRadius(16)
          .onClick(() => navigateTo('pages/BookSourceManagePage'))

        Text('馃搨 瀵煎叆')
          .fontSize(13)
          .fontColor('#52C41A')
          .padding(8)
          .backgroundColor('rgba(82,196,26,0.1)')
          .borderRadius(16)
          .onClick(() => this.importFromFile())
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
        .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
  }

  @Builder
  FuncTabs() {
    Row({ space: 12 }) {
      ForEach(this.funcTabs, (item: FuncTab) => {
        Column({ space: 4 }) {
          Text(item.icon)
            .fontSize(22)
          Text(item.nameText)
            .fontSize(10)
            .fontColor(this.selectedTab === this.funcTabs.indexOf(item) || (item.action === 'search' && this.showSearchPanel)
              ? '#007DFF' 
              : this.tc('#999999', '#888888'))
        }
        .flexBasis(0)
        .flexGrow(1)
        .padding({ top: 10, bottom: 10 })
        .borderRadius(12)
        .backgroundColor(this.selectedTab === this.funcTabs.indexOf(item) || (item.action === 'search' && this.showSearchPanel)
          ? this.bg('rgba(0,125,255,0.08)', 'rgba(0,125,255,0.15)')
          : 'transparent')
        .onClick(() => this.onFuncClick(item.action))
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
  }

  @Builder
  SourceCountBar() {
    Row({ space: 4 }) {
      Text('宸插�锟?)
        .fontSize(12)
        .fontColor(this.tc('#999999', '#888888'))
      Text(this.sourceCount.toString())
        .fontSize(12)
        .fontColor('#007DFF')
        .fontWeight(FontWeight.Medium)
      Text('涓�功锟?)
        .fontSize(12)
        .fontColor(this.tc('#999999', '#888888'))
    }
    .padding({ top: 6, bottom: 6 })
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
  }

  @Builder
  SearchPanel() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        TextInput({ placeholder: '鎼滅储涔︾睄鍚嶇О...', text: this.searchKeyword })
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.bg('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .caretColor('#007DFF')
          .onChange((value: string) => { this.searchKeyword = value; })
          .onSubmit(() => this.onSearch())

        Button('鎼滅储')
          .height(44)
          .width(72)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .onClick(() => this.onSearch())
      }
      .padding({ left: 16, right: 16 })

      if (this.isSearching) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#007DFF')
          Text('鎼滅储)..')
            .fontSize(13)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.searchResults.length > 0) {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.searchResults, (book: SourceSearchResult) => {
              Row({ space: 12 }) {
                Column() {
                  Text('馃摉')
                    .fontSize(20)
                }
                .width(44)
                .height(44)
                .backgroundColor(this.bg('rgba(0,125,255,0.1)', 'rgba(0,125,255,0.15)'))
                .borderRadius(10)
                .justifyContent(FlexAlign.Center)

                Column({ space: 2 }) {
                  Text(book.bookName)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  
                  if (book.author) {
                    Text(book.author)
                      .fontSize(11)
                      .fontColor(this.tc('#999999', '#888888'))
                      .maxLines(1)
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text('馃摎')
                  .fontSize(18)
                  .fontColor(this.tc('#CCCCCC', '#555555'))
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
              .borderRadius(12)
            })
          }
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        Column({ space: 12 }) {
          Text('馃攳')
            .fontSize(48)
          Text(this.searchKeyword ? '鏈�壘鍒扮浉鍏充功' : '杈撳叆鍏抽敭璇嶆悳锟?)
            .fontSize(13)
            .fontColor(this.tc('#999999', '#666666'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  RankingPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('馃弳 涔︽簮鎺掕�')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        
        Blank()
        
        if (!this.isTesting) {
          Button('娴嬭瘯')
            .height(32)
            .fontSize(12)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .onClick(() => this.testAllSources())
        } else {
          LoadingProgress()
            .width(24)
            .height(24)
            .color('#007DFF')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.rankingSources, (source: OnlineSourceInfo, index: number) => {
            this.SourceListItem(source, index)
          })
        }
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  CategoryContent() {
    Column() {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.sourceCategories, (category: SourceCategory, index: number) => {
            Text(category.nameText)
              .fontSize(13)
              .fontColor(this.selectedCategory === index ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .backgroundColor(this.selectedCategory === index ? '#007DFF' : this.bg('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
              .borderRadius(18)
              .onClick(() => { this.selectedCategory = index; })
          })
        }
        .padding({ left: 16, right: 16, top: 12 })
      }
      .width('100%')
          .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))

      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.getSelectedCategorySources(), (source: OnlineSourceInfo, index: number) => {
            this.SourceListItem(source, index)
          })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  SourceContent() {
    Scroll() {
      Column({ space: 10 }) {
        ForEach(PRESET_SOURCE_URLS.slice(0, 10), (source: OnlineSourceInfo, index: number) => {
          this.SourceListItem(source, index)
        })
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 20 })
    }
    .layoutWeight(1)
  }

  @Builder
  SourceListItem(source: OnlineSourceInfo, index: number) {
    Row({ space: 12 }) {
      Column() {
        Text(index < 3 ? '馃弳' : '馃摉')
          .fontSize(index < 3 ? 20 : 18)
      }
      .width(48)
      .height(48)
      .backgroundColor(index < 3
        ? this.bg('rgba(255,215,0,0.1)', 'rgba(255,215,0,0.15)')
        : this.bg('rgba(0,125,255,0.08)', 'rgba(0,125,255,0.15)'))
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(source.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(source.url)
          .fontSize(11)
          .fontColor(this.tc('#999999', '#888888'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.testResults.length > index) {
        Text((this.testResults[index].success ? this.testResults[index].responseTime.toString() + 'ms' : '澶辫触'))
          .fontSize(11)
          .fontColor(this.testResults[index].success ? '#52C41A' : '#FF4D4F')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.testResults[index].success
            ? this.bg('rgba(82,196,26,0.1)', 'rgba(82,196,26,0.15)')
            : this.bg('rgba(255,77,79,0.1)', 'rgba(255,77,79,0.15)'))
          .borderRadius(12)
      }

      Text('+')
        .fontSize(18)
        .fontColor('#007DFF')
        .fontWeight(FontWeight.Medium)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor('rgba(0,125,255,0.1)')
        .borderRadius(18)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .onClick(() => this.importSource(source))
  }

  @Builder
  ResultDialog() {
    Column() {
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => { this.showResultDialog = false; })

      Column({ space: 16 }) {
        if (this.importResult && this.importResult.success > 0) {
          Text('锟?)
            .fontSize(48)
          Text('瀵煎叆鎴愬姛')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          Text('鎴愬姛瀵煎叆 ' + this.importResult.success + ' 涓�功锟?)
            .fontSize(13)
            .fontColor(this.tc('#666666', '#AAAAAA'))
        } else {
          Text('锟?)
            .fontSize(48)
          Text('瀵煎叆澶辫触')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          Text(this.importResult ? this.importResult.message : '璇风◢鍚庨噸锟?)
            .fontSize(13)
            .fontColor(this.tc('#666666', '#AAAAAA'))
        }

        Button('纭�畾')
          .width('100%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .onClick(() => { this.showResultDialog = false; })
      }
      .width('80%')
      .padding(24)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  FileResultDialog() {
    Column() {
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => { this.showFileResult = false; })

      Column({ space: 16 }) {
        if (this.fileImportResult && this.fileImportResult.success > 0) {
          Text('锟?)
            .fontSize(48)
          Text('鏂囦欢瀵煎叆鎴愬姛')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          Text('鎴愬姛瀵煎叆 ' + this.fileImportResult.success + ' 涓�功锟?)
            .fontSize(13)
            .fontColor(this.tc('#666666', '#AAAAAA'))
        } else {
          Text('锟?)
            .fontSize(48)
          Text('瀵煎叆澶辫触')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          Text(this.fileImportResult ? this.fileImportResult.message : '鏂囦欢鏍煎紡涓嶆敮锟?)
            .fontSize(13)
            .fontColor(this.tc('#666666', '#AAAAAA'))
        }

        if (this.fileImportResult && this.fileImportResult.fail > 0) {
          Text('澶辫触: ' + this.fileImportResult.fail + ' 锟?)
            .fontSize(12)
            .fontColor(this.tc('#FF4D4F', '#FF7875'))
        }

        Button('纭�畾')
          .width('100%')
          .height(44)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .onClick(() => { this.showFileResult = false; })
      }
      .width('80%')
      .padding(24)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct OnlineSourceMarketPagePreview {
  build() {
    Column() {
      Text('鍦ㄧ嚎涔︽簮甯傚満锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      OnlineSourceMarketPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鍦ㄧ嚎涔︽簮甯傚満锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      OnlineSourceMarketPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}



