// 书源管理页面 - 参考阅读3.0设计
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BookSource, BookSourceType, ReplaceRule } from '../models/BookSourceModel';
import { bookSourceViewModel, ImportResult, SourceFilterState } from '../viewmodels/BookSourceViewModel';
import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { OnlineSourceInfo } from '../utils/BookSourceImporter';
import { DeviceUtils } from '../utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { SourceCategoryFilter } from '../features/source-market/components/SourceCategoryFilter';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

@Entry
@Component
struct BookSourceManagePage {
  @State sourceList: BookSource[] = [];
  @State ruleList: ReplaceRule[] = [];
  @State activeTab: number = 0;
  @State showAddDialog: boolean = false;
  @State showEditDialog: boolean = false;
  @State showUrlImportDialog: boolean = false;
  @State showPresetDialog: boolean = false;
  @State showResultDialog: boolean = false;
  @State showMoreMenu: boolean = false;
  @State editingSourceId: string = '';
  @State selectAll: boolean = false;
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State searchKeyword: string = '';
  @State isBatchMode: boolean = false;
  @State selectedCount: number = 0;
  @State sourceMoreMenuId: string = '';

  @State newSourceName: string = '';
  @State newSourceUrl: string = '';
  @State newSourceEnabled: boolean = true;

  @State importUrl: string = '';
  @State isImporting: boolean = false;
  @State importResult: ImportResult | null = null;

  @State presetSources: OnlineSourceInfo[] = [];
  @State selectedPreset: OnlineSourceInfo | null = null;
  @State filterState: SourceFilterState = bookSourceViewModel.getFilterState();
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();

  private unsubscribe: (() => void) | null = null;
  private ruleUnsubscribe: (() => void) | null = null;
  private longPressTimer: number = -1;

  @State private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.setupSubscriptions();
  }

  private async initData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadData();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookSourceViewModel.subscribeSources((sources: BookSource[]) => {
      this.sourceList = bookSourceViewModel.getFilteredSources();
      this.selectedCount = bookSourceViewModel.getSelectedCount();
      this.isBatchMode = bookSourceViewModel.isBatchModeActive();
    });
    this.ruleUnsubscribe = bookSourceViewModel.subscribeRules((rules: ReplaceRule[]) => {
      this.ruleList = rules;
    });
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * tabletMultiplier);
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
    if (this.ruleUnsubscribe) {
      this.ruleUnsubscribe();
    }
  }

  private loadData(): void {
    this.sourceList = bookSourceViewModel.getFilteredSources();
    this.ruleList = bookSourceViewModel.getAllReplaceRules();
    this.presetSources = bookSourceViewModel.getPresetSourceList();
    this.filterState = bookSourceViewModel.getFilterState();
  }

  // 筛选条件变化处理
  private onFilterChange(filter: SourceFilterState): void {
    this.filterState = filter;
    bookSourceViewModel.setFilterState(filter);
    this.sourceList = bookSourceViewModel.getFilteredSources();
  }

  // 导入书源
  private async importSources(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.fileSuffixFilters = ['.json', '.txt'];
      options.maxSelectNumber = 1;

      const results = await documentPicker.select(options);
      if (results && results.length > 0) {
        const fileUri = results[0];
        // 读取文件内容
        let file: fileIo.File | null = null;
        try {
          file = fileIo.openSync(fileUri, fileIo.OpenMode.READ_ONLY);
          const stat = fileIo.statSync(fileUri);
          const content = new Uint8Array(stat.size);
          fileIo.readSync(file.fd, content.buffer);

          // 解码内容
          const decoder = new util.TextDecoder('utf-8');
          const jsonContent = decoder.decodeToString(content);

          // 导入书源
          this.importResult = bookSourceViewModel.importFromJson(jsonContent);
          this.showResultDialog = true;
        } finally {
          if (file) {
            fileIo.closeSync(file);
          }
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('导入失败:', message);
      this.importResult = {
        success: 0,
        fail: 0,
        total: 0,
        message: '文件读取失败'
      };
      this.showResultDialog = true;
    }
  }

  // 从URL导入
  private async importFromUrl(): Promise<void> {
    if (!this.importUrl.trim()) {
      return;
    }
    
    this.isImporting = true;
    try {
      this.importResult = await bookSourceViewModel.importFromUrl(this.importUrl.trim());
      this.showUrlImportDialog = false;
      this.showResultDialog = true;
      this.importUrl = '';
    } catch {
      this.importResult = {
        success: 0,
        fail: 0,
        total: 0,
        message: '网络请求失败'
      };
      this.showResultDialog = true;
    } finally {
      this.isImporting = false;
    }
  }

  // 从预设书源导入
  private async importFromPreset(preset: OnlineSourceInfo): Promise<void> {
    this.selectedPreset = preset;
    this.isImporting = true;
    try {
      this.importResult = await bookSourceViewModel.importFromUrl(preset.url);
      this.showPresetDialog = false;
      this.showResultDialog = true;
    } catch {
      this.importResult = {
        success: 0,
        fail: 0,
        total: 0,
        message: '导入失败'
      };
      this.showResultDialog = true;
    } finally {
      this.isImporting = false;
      this.selectedPreset = null;
    }
  }

  // 导出书源
  private exportSources(): void {
    const sources = bookSourceViewModel.exportSources();
    console.info('导出书源:', JSON.stringify(sources));
    // 这里应该保存到文件
  }

  // 添加新书源
  private addNewSource(): void {
    if (this.newSourceName.trim() && this.newSourceUrl.trim()) {
      const newSource: BookSource = {
        id: '',
        name: this.newSourceName.trim(),
        url: this.newSourceUrl.trim(),
        enabled: this.newSourceEnabled,
        weight: 10,
        priority: 1,
        bookSourceType: BookSourceType.TEXT,
        loginRequired: false,
        createTime: Date.now(),
        lastUpdateTime: Date.now()
      };
      if (bookSourceViewModel.addSource(newSource)) {
        this.showAddDialog = false;
        this.resetForm();
      }
    }
  }

  private resetForm(): void {
    this.newSourceName = '';
    this.newSourceUrl = '';
    this.newSourceEnabled = true;
    this.editingSourceId = '';
  }

  build() {
    Column() {
      // 顶部导航
      if (this.isBatchMode) {
        this.BatchTopBar()
      } else {
        this.TopBar()
      }

      // 标签切换（批量模式下隐藏）
      if (!this.isBatchMode) {
        this.TabBar()
      }

      // 搜索框（仅在书源Tab且非批量模式）
      if (this.activeTab === 0 && !this.isBatchMode) {
        this.SearchBar()
      }

      // 分类筛选器（仅在书源Tab且非批量模式）
      if (this.activeTab === 0 && !this.isBatchMode) {
        this.FilterView()
      }

      // 内容区域
      if (this.activeTab === 0) {
        this.SourceListView()
      } else {
        this.RuleListView()
      }

      // 批量操作栏
      if (this.isBatchMode) {
        this.BatchActionBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F5F5F5', '#141414'))
  }

  @Builder
  TopBar() {
    Row() {
      Button() {
        Text('返回')
          .fontSize(20)
          .fontColor(this.tc('#333333', '#FFFFFF'))
      }
      .width(40)
      .height(40)
      .backgroundColor(this.bg('rgba(255,255,255,0.5)', 'rgba(255,255,255,0.1)'))
      .borderRadius(20)
      .onClick(() => {
          try {
            router.back();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            console.error('[BookSourceManagePage] back failed:', msg);
          }
        })

      Text('书源管理')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .layoutWeight(1)

      if (this.activeTab === 0) {
        Button() {
          Text('+')
            .fontSize(20)
            .fontColor(this.tc('#333333', '#FFFFFF'))
        }
        .width(40)
        .height(40)
        .backgroundColor(this.bg('rgba(255,255,255,0.5)', 'rgba(255,255,255,0.1)'))
        .borderRadius(20)
        .onClick(() => this.showImportExportMenu())
      }
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 8, right: this.isTablet ? 24 : 8 })
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
  }

  @Builder
  TabBar() {
    Row({ space: 0 }) {
      this.TabItem('书源', 0)
      this.TabItem('替换规则', 1)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
  }

  @Builder
  TabItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeTab === index ? COMMON_COLORS.PRIMARY_BLUE : this.tc('#666666', '#AAAAAA'))

      if (this.activeTab === index) {
        Row()
          .width(24)
          .height(3)
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .borderRadius(2)
          .margin({ top: 4 })
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.activeTab = index)
  }

  @Builder
  SourceListView() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.sourceList.length === 0) {
        Column({ space: 16 }) {
          Text('书')
            .fontSize(64)
            .fontColor(this.tc('#CCCCCC', '#666666'))

          Text(this.searchKeyword ? '未找到匹配的书源' : '暂无书源')
            .fontSize(16)
            .fontColor(this.tc('#999999', '#888888'))

          Text(this.searchKeyword ? '请尝试其他搜索关键词' : '点击右下角添加书源或导入')
            .fontSize(13)
            .fontColor(this.tc('#BBBBBB', '#666666'))
        }
        .width('100%')
        .height('60%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.sourceList, (source: BookSource) => {
            ListItem() {
              this.SourceItem(source)
            }
          }, (source: BookSource) => source.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(this.bg('#F5F5F5', '#141414'))
      }

      // 添加按钮（批量模式下隐藏）
      if (!this.isBatchMode) {
        Button() {
          Text('+')
            .fontSize(28)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .width(56)
        .height(56)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(28)
        .shadow({
          radius: 8,
          color: 'rgba(24,144,255,0.4)',
          offsetY: 4
        })
        .margin({ right: 20, bottom: 40 })
        .onClick(() => this.showAddDialog = true)
      }
    }
    .width('100%')
    .layoutWeight(1)

    // 添加书源弹窗
    if (this.showAddDialog) {
      this.AddSourceDialog()
    }

    // URL导入弹窗
    if (this.showUrlImportDialog) {
      this.UrlImportDialog()
    }

    // 预设书源弹窗
    if (this.showPresetDialog) {
      this.PresetSourceDialog()
    }

    // 结果弹窗
    if (this.showResultDialog) {
      this.ResultDialog()
    }

    // 书源更多操作菜单
    if (this.showMoreMenu) {
      this.SourceMoreMenu()
    }

    // 编辑书源弹窗
    if (this.showEditDialog) {
      this.EditSourceDialog()
    }
  }

  @Builder
  SourceItem(source: BookSource) {
    Column() {
      Row({ space: 12 }) {
        // 批量选择框（批量模式下显示）
        if (this.isBatchMode) {
          Checkbox({ name: source.id, group: 'batch' })
            .select(bookSourceViewModel.isSelected(source.id))
            .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
            .width(24)
            .height(24)
            .onChange((value: boolean) => {
              bookSourceViewModel.toggleSelection(source.id);
              this.selectedCount = bookSourceViewModel.getSelectedCount();
            })
        }

        // 书源类型图标
        Column() {
          Text(this.getSourceTypeIcon(source.bookSourceType))
            .fontSize(24)

          Text(this.getSourceTypeLabel(source.bookSourceType))
            .fontSize(10)
            .fontColor(this.tc('#999999', '#888888'))
            .margin({ top: 2 })
        }
        .width(44)
        .height(44)
        .backgroundColor(this.bg('#F0F7FF', '#1A3A5C'))
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 书源信息
        Column({ space: 4 }) {
          Row() {
            Text(source.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.tc('#333333', '#FFFFFF'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            // 启用状态标签
            if (source.enabled) {
              Text('启用')
                .fontSize(10)
                .fontColor(COMMON_COLORS.SUCCESS_GREEN)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.bg('rgba(40,167,69,0.1)', 'rgba(40,167,69,0.2)'))
                .borderRadius(8)
            } else {
              Text('禁用')
                .fontSize(10)
                .fontColor(COMMON_COLORS.ERROR_RED)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.bg('rgba(220,53,69,0.1)', 'rgba(220,53,69,0.2)'))
                .borderRadius(8)
            }
          }
          .width('100%')

          // URL行
          Row() {
            Text('馃敆')
              .fontSize(12)
              .margin({ right: 4 })

            Text(this.formatUrl(source.url))
              .fontSize(12)
              .fontColor(this.tc('#999999', '#888888'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')

          // 时间和权重信息行
          Row({ space: 12 }) {
            // 最后更新时间
            if (source.lastUpdateTime) {
              Row() {
                Text('馃晵')
                  .fontSize(11)
                  .margin({ right: 2 })

                Text(this.formatTime(source.lastUpdateTime))
                  .fontSize(11)
                  .fontColor(this.tc('#999999', '#888888'))
              }
            }

            // 导入时间
            if (source.createTime) {
              Row() {
                Text('馃搮')
                  .fontSize(11)
                  .margin({ right: 2 })

                Text('导入:' + this.formatDate(source.createTime))
                  .fontSize(11)
                  .fontColor(this.tc('#999999', '#888888'))
              }
            }

            // 权重
            Row() {
              Text('权重:' + source.weight.toString())
                .fontSize(11)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            }
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.bg('rgba(0,125,255,0.1)', 'rgba(0,125,255,0.15)'))
            .borderRadius(10)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 右侧操作按钮
        Column({ space: 8 }) {
          // 编辑按钮
          Button() {
            Text('鉁忥笍')
              .fontSize(16)
          }
          .width(32)
          .height(32)
          .backgroundColor(this.bg('rgba(255,255,255,0.7)', 'rgba(255,255,255,0.1)'))
          .borderRadius(16)
          .onClick(() => this.editSource(source.id))

          // 更多按钮
          Button() {
            Text('..')
              .fontSize(18)
              .fontColor(this.tc('#666666', '#AAAAAA'))
          }
          .width(32)
          .height(32)
          .backgroundColor(this.bg('rgba(255,255,255,0.7)', 'rgba(255,255,255,0.1)'))
          .borderRadius(16)
          .onClick(() => {
            this.sourceMoreMenuId = source.id;
            this.showMoreMenu = true;
          })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分隔线
      Divider()
        .color(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .shadow({
      radius: 2,
      color: this.tc('rgba(0,0,0,0.05)', 'rgba(0,0,0,0.2)'),
      offsetX: 0,
      offsetY: 1
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down && !this.isBatchMode) {
        this.longPressTimer = setTimeout(() => {
          if (!bookSourceViewModel.isBatchModeActive()) {
            bookSourceViewModel.enterBatchMode();
            this.isBatchMode = true;
            this.selectedCount = bookSourceViewModel.getSelectedCount();
          }
        }, 500);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        if (this.longPressTimer !== -1) {
          clearTimeout(this.longPressTimer);
          this.longPressTimer = -1;
        }
      }
    })
    .onClick(() => {
      if (!this.isBatchMode) {
        this.editSource(source.id);
      }
    })
  }

  @Builder
  SourceMoreMenu() {
    Column() {
      Row()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => this.showMoreMenu = false)

      Column({ space: 2 }) {
        // 编辑
        Button() {
          Row({ space: 8 }) {
            Text('✏️')
              .fontSize(16)
            Text('编辑')
              .fontSize(14)
              .fontColor(this.tc('#333333', '#FFFFFF'))
          }
          .width('100%')
          .padding(12)
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showMoreMenu = false;
          this.editSource(this.sourceMoreMenuId);
        })

        // 测试
        Button() {
          Row({ space: 8 }) {
            Text('🔍')
              .fontSize(16)
            Text('测试')
              .fontSize(14)
              .fontColor(this.tc('#333333', '#FFFFFF'))
          }
          .width('100%')
          .padding(12)
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showMoreMenu = false;
          this.testSource(this.sourceMoreMenuId);
        })

        // 导出
        Button() {
          Row({ space: 8 }) {
            Text('📤')
              .fontSize(16)
            Text('导出')
              .fontSize(14)
              .fontColor(this.tc('#333333', '#FFFFFF'))
          }
          .width('100%')
          .padding(12)
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showMoreMenu = false;
          this.exportSingleSource(this.sourceMoreMenuId);
        })

        // 删除
        Button() {
          Row({ space: 8 }) {
            Text('🗑️')
              .fontSize(16)
            Text('删除')
              .fontSize(14)
              .fontColor(COMMON_COLORS.ERROR_RED)
          }
          .width('100%')
          .padding(12)
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showMoreMenu = false;
          bookSourceViewModel.deleteSource(this.sourceMoreMenuId);
        })
      }
      .width(160)
      .padding(8)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0,0,0,0.15)',
        offsetX: 0,
        offsetY: 4
      })

      Row()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => this.showMoreMenu = false)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RuleListView() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.ruleList.length === 0) {
        Column({ space: 16 }) {
          Text('替换')
            .fontSize(64)
            .fontColor(this.tc('#CCCCCC', '#666666'))

          Text('暂无替换规则')
            .fontSize(16)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .width('100%')
        .height('60%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.ruleList, (rule: ReplaceRule) => {
            ListItem() {
              this.RuleItem(rule)
            }
          }, (rule: ReplaceRule) => rule.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(this.bg('#F5F5F5', '#141414'))
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  RuleItem(rule: ReplaceRule) {
    Row({ space: 12 }) {
      Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
        .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
        .width(44)
        .height(24)
        .onChange((value: boolean) => {
          bookSourceViewModel.updateReplaceRule(rule.id, { enabled: value });
        })

      Column({ space: 4 }) {
        Text(rule.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .width('100%')

        Text(rule.pattern)
          .fontSize(12)
          .fontColor(this.tc('#999999', '#888888'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('> ' + (rule.replacement || '(空)'))
          .fontSize(11)
          .fontColor(COMMON_COLORS.SUCCESS_GREEN)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button() {
        Text('删除')
          .fontSize(16)
      }
      .width(36)
      .height(36)
      .backgroundColor(this.bg('rgba(255,255,255,0.5)', 'rgba(255,255,255,0.1)'))
      .borderRadius(18)
      .onClick(() => bookSourceViewModel.deleteReplaceRule(rule.id))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
  }

  @Builder
  AddSourceDialog() {
    Column() {
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.showAddDialog = false)

      Column({ space: 16 }) {
        Text('添加书源')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        TextInput({ placeholder: '书源名称', text: $$this.newSourceName })
          .placeholderColor(this.tc('#999999', '#888888'))
          .fontSize(14)
          .height(44)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .borderRadius(8)

        TextInput({ placeholder: '书源URL', text: $$this.newSourceUrl })
          .placeholderColor(this.tc('#999999', '#888888'))
          .fontSize(14)
          .height(44)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .borderRadius(8)

        Row() {
          Text('启用')
            .fontSize(14)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: $$this.newSourceEnabled })
            .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width('100%')

        Row({ space: 12 }) {
          Button('取消')
            .width(120)
            .height(44)
            .fontSize(16)
            .backgroundColor(this.bg('#F5F5F5', '#141414'))
            .fontColor(this.tc('#666666', '#AAAAAA'))
            .borderRadius(22)
            .onClick(() => {
              this.showAddDialog = false;
              this.resetForm();
            })

          Button('添加')
            .width(120)
            .height(44)
            .fontSize(16)
            .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .enabled(this.newSourceName.trim().length > 0 && this.newSourceUrl.trim().length > 0)
            .onClick(() => this.addNewSource())
        }
      }
      .width('85%')
      .padding(20)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)

      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.showAddDialog = false)
    }
    .width('100%')
    .height('100%')
  }

  private showImportExportMenu(): void {
    // 显示导入/导出菜单 - 直接显示预设书源对话框
    this.showPresetDialog = true;
  }

  @Builder
  PresetSourceDialog() {
    Column() {
      Column({ space: 16 }) {
        // 标题
        Text('在线书源')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        Text('选择书源导入')
          .fontSize(12)
          .fontColor(this.tc('#999999', '#888888'))

        // 预设书源列表
        List({ space: 8 }) {
          ForEach(this.presetSources, (preset: OnlineSourceInfo) => {
            ListItem() {
              this.PresetSourceItem(preset)
            }
          }, (preset: OnlineSourceInfo) => preset.name)
        }
        .width('100%')
        .height(280)
        .margin({ top: 8 })

        // 手动输入URL
        Row() {
          Button('手动输入URL')
            .fontSize(14)
            .backgroundColor(this.bg('#F5F5F5', '#141414'))
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            .borderRadius(20)
            .onClick(() => {
              this.showPresetDialog = false;
              this.showUrlImportDialog = true;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })

        // 关闭按钮
        Button('关闭')
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .fontColor(this.tc('#666666', '#AAAAAA'))
          .borderRadius(22)
          .margin({ top: 8 })
          .onClick(() => this.showPresetDialog = false)
      }
      .width('90%')
      .padding(20)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => this.showPresetDialog = false)
  }

  @Builder
  PresetSourceItem(preset: OnlineSourceInfo) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(preset.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .width('100%')

        Text('共' + preset.count + '个书源 · ' + preset.updateTime)
          .fontSize(12)
          .fontColor(this.tc('#999999', '#888888'))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 导入按钮
      Button(this.selectedPreset?.name === preset.name && this.isImporting ? '导入中...' : '导入')
        .fontSize(13)
        .height(32)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .enabled(!(this.isImporting && this.selectedPreset?.name === preset.name))
        .onClick(() => this.importFromPreset(preset))
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.bg('#F8F8F8', '#2C2C2E'))
    .borderRadius(8)
  }

  @Builder
  UrlImportDialog() {
    Column() {
      Column({ space: 16 }) {
        Text('从URL导入书源')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        TextInput({ placeholder: '输入书源JSON地址', text: $$this.importUrl })
          .placeholderColor(this.tc('#999999', '#888888'))
          .fontSize(14)
          .height(48)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .borderRadius(8)

        Text('支持 JSON 格式书源导入')
          .fontSize(12)
          .fontColor(this.tc('#999999', '#888888'))

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .backgroundColor(this.bg('#F5F5F5', '#141414'))
            .fontColor(this.tc('#666666', '#AAAAAA'))
            .borderRadius(22)
            .onClick(() => {
              this.showUrlImportDialog = false;
              this.importUrl = '';
            })

          Button(this.isImporting ? '导入中...' : '导入')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .enabled(!this.isImporting && this.importUrl.trim().length > 0)
            .onClick(() => this.importFromUrl())
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => this.showUrlImportDialog = false)
  }

  @Builder
  ResultDialog() {
    Column() {
      Column({ space: 16 }) {
        Text(this.importResult?.success && this.importResult.success > 0 ? '导入成功' : '导入失败')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        Column({ space: 8 }) {
          Text('成功: ' + (this.importResult?.success || 0) + '个')
            .fontSize(14)
            .fontColor(COMMON_COLORS.SUCCESS_GREEN)

          Text('失败: ' + (this.importResult?.fail || 0) + '个')
            .fontSize(14)
            .fontColor(COMMON_COLORS.ERROR_RED)

          if (this.importResult?.message) {
            Text(this.importResult.message)
              .fontSize(12)
              .fontColor(this.tc('#999999', '#888888'))
              .margin({ top: 8 })
          }
        }

        Button('确定')
          .width(140)
          .height(44)
          .fontSize(16)
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .onClick(() => {
            this.showResultDialog = false;
            this.importResult = null;
          })
      }
      .width('75%')
      .padding(24)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => {
      this.showResultDialog = false;
      this.importResult = null;
    })
  }

  // ============== 搜索框 ==============

  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      // 搜索图标
      Text('🔍')
        .fontSize(16)
        .margin({ left: 12 })

      // 搜索输入框
      TextInput({ placeholder: '搜索书源名称或URL', text: $$this.searchKeyword })
        .placeholderColor(this.tc('#999999', '#888888'))
        .fontSize(14)
        .height(40)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.onSearchChange(value);
        })

      // 清空按钮
      if (this.searchKeyword) {
        Button() {
          Text('✕')
            .fontSize(14)
            .fontColor(this.tc('#999999', '#888888'))
        }
        .width(28)
        .height(28)
        .backgroundColor(this.bg('#F0F0F0', '#3A3A3C'))
        .borderRadius(14)
        .margin({ right: 8 })
        .onClick(() => this.clearSearch())
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
  }

  // 分类筛选器视图
  @Builder
  FilterView() {
    SourceCategoryFilter({
      isDarkMode: this.isDarkMode,
      filterState: $filterState,
      onFilterChange: (filter: SourceFilterState) => {
        this.onFilterChange(filter);
      }
    })
  }

  // ============== 批量模式顶部栏 ==============

  @Builder
  BatchTopBar() {
    Column() {
      Row({ space: 12 }) {
        // 取消按钮
        Button() {
          Text('取消')
            .fontSize(16)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => this.exitBatchMode())

        Text('已选择 ' + this.selectedCount + '个')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 全选按钮
        Button() {
          Text('全选')
            .fontSize(14)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => this.batchSelectAll())
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
  }

  // ============== 批量操作栏 ==============

  @Builder
  BatchActionBar() {
    Row({ space: 12 }) {
      // 批量启用
      Button() {
        Row({ space: 4 }) {
          Text('✓')
            .fontSize(16)
            .fontColor('#FFFFFF')
          Text('启用')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor(COMMON_COLORS.SUCCESS_GREEN)
      .borderRadius(22)
      .enabled(this.selectedCount > 0)
      .onClick(() => this.batchEnableSources())

      // 批量禁用
      Button() {
        Row({ space: 4 }) {
          Text('✓')
            .fontSize(16)
            .fontColor('#FFFFFF')
          Text('禁用')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor(COMMON_COLORS.WARNING_ORANGE)
      .borderRadius(22)
      .enabled(this.selectedCount > 0)
      .onClick(() => this.batchDisableSources())

      // 批量删除
      Button() {
        Row({ space: 4 }) {
          Text('🗑')
            .fontSize(16)
            .fontColor('#FFFFFF')
          Text('删除')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor(COMMON_COLORS.ERROR_RED)
      .borderRadius(22)
      .enabled(this.selectedCount > 0)
      .onClick(() => this.batchDeleteSources())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 20 })
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: -2
    })
  }

  // ============== 编辑书源对话框 ==============

  @Builder
  EditSourceDialog() {
    Column() {
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showEditDialog = false;
          this.resetForm();
        })

      Column({ space: 16 }) {
        Text('编辑书源')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        TextInput({ placeholder: '书源名称', text: $$this.newSourceName })
          .placeholderColor(this.tc('#999999', '#888888'))
          .fontSize(14)
          .height(44)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .borderRadius(8)

        TextInput({ placeholder: '书源URL', text: $$this.newSourceUrl })
          .placeholderColor(this.tc('#999999', '#888888'))
          .fontSize(14)
          .height(44)
          .backgroundColor(this.bg('#F5F5F5', '#141414'))
          .borderRadius(8)

        Row() {
          Text('启用')
            .fontSize(14)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: $$this.newSourceEnabled })
            .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width('100%')

        Row({ space: 12 }) {
          Button('取消')
            .width(120)
            .height(44)
            .fontSize(16)
            .backgroundColor(this.bg('#F5F5F5', '#141414'))
            .fontColor(this.tc('#666666', '#AAAAAA'))
            .borderRadius(22)
            .onClick(() => {
              this.showEditDialog = false;
              this.resetForm();
            })

          Button('保存')
            .width(120)
            .height(44)
            .fontSize(16)
            .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .enabled(this.newSourceName.trim().length > 0 && this.newSourceUrl.trim().length > 0)
            .onClick(() => this.updateSource())
        }
      }
      .width('85%')
      .padding(20)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)

      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showEditDialog = false;
          this.resetForm();
        })
    }
    .width('100%')
    .height('100%')
  }

  // ============== 新增的辅助方法 ==============

  // 获取书源类型图标
  private getSourceTypeIcon(type: BookSourceType): string {
    switch (type) {
      case BookSourceType.TEXT:
        return '📖';
      case BookSourceType.IMAGE:
        return '🖼️';
      case BookSourceType.AUDIO:
        return '🎧';
      default:
        return '📖';
    }
  }

  // 获取书源类型标签
  private getSourceTypeLabel(type: BookSourceType): string {
    switch (type) {
      case BookSourceType.TEXT:
        return '文字';
      case BookSourceType.IMAGE:
        return '漫画';
      case BookSourceType.AUDIO:
        return '音频';
      default:
        return '文字';
    }
  }

  // 格式化URL（截断显示）
  private formatUrl(url: string): string {
    if (!url) return '';
    if (url.length > 35) {
      return url.substring(0, 35) + '...';
    }
    return url;
  }

  // 格式化时间（月/日）
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${month}-${day}`;
  }

  // 格式化日期（年/月/日）
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear().toString().substring(2);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 编辑书源
  private editSource(id: string): void {
    const source = bookSourceViewModel.getSourceById(id);
    if (source) {
      this.newSourceName = source.name;
      this.newSourceUrl = source.url;
      this.newSourceEnabled = source.enabled;
      this.editingSourceId = id;
      this.showEditDialog = true;
    }
  }

  // 更新书源
  private updateSource(): void {
    if (this.newSourceName.trim() && this.newSourceUrl.trim() && this.editingSourceId) {
      const updateData: Partial<BookSource> = {
        name: this.newSourceName.trim(),
        url: this.newSourceUrl.trim(),
        enabled: this.newSourceEnabled,
        lastUpdateTime: Date.now()
      };
      bookSourceViewModel.updateSource(this.editingSourceId, updateData);
      this.showEditDialog = false;
      this.resetForm();
    }
  }

  // 测试书源
  private async testSource(id: string): Promise<void> {
    console.info('测试书源:', id);
    // TODO: 实现书源测试逻辑
  }

  // 导出单个书源
  private exportSingleSource(id: string): void {
    const sources = bookSourceViewModel.exportSources([id]);
    console.info('导出书源:', JSON.stringify(sources));
    // TODO: 实现保存到文件逻辑
  }

  // 搜索框变化处理
  private onSearchChange(value: string): void {
    this.searchKeyword = value;
    bookSourceViewModel.setSearchKeyword(value);
    this.sourceList = bookSourceViewModel.getFilteredSources();
  }

  // 清空搜索
  private clearSearch(): void {
    this.searchKeyword = '';
    bookSourceViewModel.setSearchKeyword('');
    this.sourceList = bookSourceViewModel.getFilteredSources();
  }

  // 退出批量模式
  private exitBatchMode(): void {
    bookSourceViewModel.exitBatchMode();
    this.isBatchMode = false;
    this.selectedCount = 0;
  }

  // 批量全选/取消
  private batchSelectAll(): void {
    bookSourceViewModel.selectAll();
    this.selectedCount = bookSourceViewModel.getSelectedCount();
  }

  // 批量启用
  private batchEnableSources(): void {
    if (this.selectedCount > 0) {
      bookSourceViewModel.batchEnable();
    }
  }

  // 批量禁用
  private batchDisableSources(): void {
    if (this.selectedCount > 0) {
      bookSourceViewModel.batchDisable();
    }
  }

  // 批量删除
  private batchDeleteSources(): void {
    if (this.selectedCount > 0) {
      bookSourceViewModel.batchDelete();
      this.isBatchMode = false;
      this.selectedCount = 0;
    }
  }
}
