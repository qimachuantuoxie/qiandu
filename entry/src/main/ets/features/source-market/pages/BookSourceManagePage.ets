import { logger } from '../../common/utils/Logger';
import { goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookSource, BookSourceType, ReplaceRule } from '../../../core/models/BookSourceModel';
import { bookSourceViewModel, ImportResult, SourceFilterState } from '../viewmodels/BookSourceViewModel';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { OnlineSourceInfo } from '../../../core/utils/BookSourceImporter';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { tr } from '../../../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct BookSourceManagePage {
  @Local sourceList: BookSource[] = [];
  @Local ruleList: ReplaceRule[] = [];
  @Local activeTab: number = 0;
  @Local showAddDialog: boolean = false;
  @Local showUrlImportDialog: boolean = false;
  @Local showResultDialog: boolean = false;
  @Local isTablet: boolean = false;
  @Local isDarkMode: boolean = false;
  @Local searchKeyword: string = '';
  @Local isBatchMode: boolean = false;
  @Local selectedCount: number = 0;
  @Local filterState: SourceFilterState = bookSourceViewModel.getFilterState();
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;

  @Local newSourceName: string = '';
  @Local newSourceUrl: string = '';
  @Local importUrl: string = '';
  @Local isImporting: boolean = false;
  @Local importResult: ImportResult | null = null;

  private unsubscribe: (() => void) | null = null;
  private ruleUnsubscribe: (() => void) | null = null;
  private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.setupSubscriptions();
  }

  private async initData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadData();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookSourceViewModel.subscribeSources((): void => {
      this.sourceList = bookSourceViewModel.getFilteredSources();
      this.selectedCount = bookSourceViewModel.getSelectedCount();
      this.isBatchMode = bookSourceViewModel.isBatchModeActive();
    });
    this.ruleUnsubscribe = bookSourceViewModel.subscribeRules((rules: ReplaceRule[]): void => {
      this.ruleList = rules;
    });
  }

  aboutToDisappear() {
    if (this.unsubscribe) this.unsubscribe();
    if (this.ruleUnsubscribe) this.ruleUnsubscribe();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private loadData(): void {
    this.sourceList = bookSourceViewModel.getFilteredSources();
    this.ruleList = bookSourceViewModel.getAllReplaceRules();
    this.filterState = bookSourceViewModel.getFilterState();
  }

  private onFilterChange(filter: SourceFilterState): void {
    this.filterState = filter;
    bookSourceViewModel.setFilterState(filter);
    this.sourceList = bookSourceViewModel.getFilteredSources();
  }

  private async importSources(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.fileSuffixFilters = ['.json', '.txt'];
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

          this.importResult = bookSourceViewModel.importFromJson(jsonContent);
          this.showResultDialog = true;
        } finally {
          if (file) fileIo.closeSync(file);
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('导入失败:', message);
      this.importResult = { success: 0, fail: 0, total: 0, message: '文件读取失败' };
      this.showResultDialog = true;
    }
  }

  private async importFromUrl(): Promise<void> {
    if (!this.importUrl.trim()) return;
    
    this.isImporting = true;
    try {
      this.importResult = await bookSourceViewModel.importFromUrl(this.importUrl.trim());
      this.showUrlImportDialog = false;
      this.showResultDialog = true;
      this.importUrl = '';
    } catch {
      this.importResult = { success: 0, fail: 0, total: 0, message: '网络请求失败' };
      this.showResultDialog = true;
    } finally {
      this.isImporting = false;
    }
  }

  private toggleSourceEnabled(source: BookSource): void {
    bookSourceViewModel.toggleSourceEnabled(source.id);
  }

  private deleteSource(source: BookSource): void {
    bookSourceViewModel.deleteSource(source.id);
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
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
          try { goBack(); } 
          catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[BookSourceManagePage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('书源管理')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 添加按钮
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
        .onClick(() => {
          this.showAddDialog = true;
        })
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // Tab切换
      Row({ space: Spacing.md }) {
        Text(`书源 (${this.sourceList.length})`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
          .backgroundColor(this.activeTab === 0 ? this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
          .fontColor(this.activeTab === 0 ? '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
          .borderRadius(BorderRadius.xl)
          .onClick(() => { this.activeTab = 0; })
        
        Text(`替换规则 (${this.ruleList.length})`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
          .backgroundColor(this.activeTab === 1 ? this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
          .fontColor(this.activeTab === 1 ? '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
          .borderRadius(BorderRadius.xl)
          .onClick(() => { this.activeTab = 1; })
      }
      .width('100%')
      .padding(Spacing.lg)

      // 搜索和筛选
      if (this.activeTab === 0) {
        this.SearchAndFilter()
      }

      // 内容区
      if (this.activeTab === 0) {
        // 书源列表
        if (this.sourceList.length === 0) {
          this.EmptyState()
        } else {
          List({ space: Spacing.md }) {
            ForEach(this.sourceList, (source: BookSource) => {
              ListItem() {
                this.SourceItem(source)
              }
            }, (source: BookSource) => source.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.xxxl })
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
        }
      } else {
        // 替换规则列表（简化）
        Column() {
          Text('替换规则功能开发中...')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
            .padding(Spacing.xxxl)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  SearchAndFilter() {
    Column({ space: Spacing.md }) {
      // 搜索框
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])

        TextInput({ placeholder: '搜索书源...', text: this.searchKeyword })
          .layoutWeight(1)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchKeyword = value;
            bookSourceViewModel.setSearchKeyword(value);
            this.sourceList = bookSourceViewModel.getFilteredSources();
          })
      }
      .width('100%')
      .padding(Spacing.md)
      .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
      .borderRadius(BorderRadius.xl)

      // 筛选标签
      Scroll() {
        Row({ space: Spacing.sm }) {
          Text('全部')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.filterState.type === 'all' ? this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
            .fontColor(this.filterState.type === 'all' ? '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => {
              this.onFilterChange(Object.assign({}, this.filterState, { type: 'all' }));
            })

          Text('文本')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.filterState.type === 'text' ? this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
            .fontColor(this.filterState.type === 'text' ? '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => {
              this.onFilterChange(Object.assign({}, this.filterState, { type: 'text' }));
            })

          Text('音频')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.filterState.type === 'audio' ? this.currentColors.primary : this.bg('#F2F2F7', '#2C2C2E'))
            .fontColor(this.filterState.type === 'audio' ? '#FFFFFF' : this.tc('#1A1A1A', '#FFFFFF'))
            .borderRadius(BorderRadius.xl)
            .onClick(() => {
              this.onFilterChange(Object.assign({}, this.filterState, { type: 'audio' }));
            })
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg })
  }

  @Builder
  SourceItem(source: BookSource) {
    Row({ space: Spacing.lg }) {
      // 图标
      Column() {
        SymbolGlyph($r('sys.symbol.globe'))
          .fontSize(Size.iconXL)
          .fontColor([this.currentColors.primary])
      }
      .width(50)
      .height(50)
      .borderRadius(BorderRadius.lg)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      // 信息
      Column({ space: Spacing.sm }) {
        Text(source.name)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: Spacing.sm }) {
          Text(source.type === BookSourceType.TEXT ? '文本' : '音频')
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.currentColors.primary + '15')
            .fontColor(this.currentColors.primary)
            .borderRadius(BorderRadius.xl)

          Text(source.url)
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: source.enabled })
        .selectedColor(this.currentColors.primary)
        .onChange((isOn: boolean) => {
          this.toggleSourceEnabled(source);
        })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.book.closed'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无书源')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('点击"+"添加书源')
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
struct BookSourceManagePagePreview {
  build() {
    Column() {
      Text('书源管理 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      BookSourceManagePage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('书源管理 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      BookSourceManagePage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
