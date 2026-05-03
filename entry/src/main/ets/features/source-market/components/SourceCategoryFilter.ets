// 书源分类筛选器组件
import { BookSourceType } from '../../../core/models/source/BookSourceModel';
import { bookSourceViewModel, SourceFilterState, DEFAULT_FILTER_STATE } from '../../../viewmodels/BookSourceViewModel';
import { COMMON_COLORS } from '../../../utils/AppTheme';

// 筛选类型枚举
enum EnabledStatusFilter {
  ALL = 'all',
  ENABLED = 'enabled',
  DISABLED = 'disabled'
}

enum SyncStatusFilter {
  ALL = 'all',
  SYNCED = 'synced',
  UNSYNCED = 'unsynced'
}

enum TestStatusFilter {
  ALL = 'all',
  AVAILABLE = 'available',
  UNAVAILABLE = 'unavailable',
  UNTESTED = 'untested'
}

@Preview
@Component
export struct SourceCategoryFilter {
  @Prop isDarkMode: boolean = false;
  @Link filterState: SourceFilterState;
  @State showTypePicker: boolean = false;
  @State showEnabledPicker: boolean = false;
  @State showSyncPicker: boolean = false;
  @State showTestPicker: boolean = false;

  onFilterChange?: (filter: SourceFilterState) => void;

  private getActiveFilterCount(): number {
    let count = 0;
    if (this.filterState.typeFilter !== 'all') count++;
    if (this.filterState.enabledFilter !== 'all') count++;
    if (this.filterState.syncFilter !== 'all') count++;
    if (this.filterState.testFilter !== 'all') count++;
    return count;
  }

  private clearAllFilters(): void {
    this.filterState.typeFilter = DEFAULT_FILTER_STATE.typeFilter;
    this.filterState.enabledFilter = DEFAULT_FILTER_STATE.enabledFilter;
    this.filterState.syncFilter = DEFAULT_FILTER_STATE.syncFilter;
    this.filterState.testFilter = DEFAULT_FILTER_STATE.testFilter;
    if (this.onFilterChange) {
      this.onFilterChange(this.filterState);
    }
  }

  private setTypeFilter(type: BookSourceType | 'all'): void {
    this.filterState.typeFilter = type;
    if (this.onFilterChange) {
      this.onFilterChange(this.filterState);
    }
  }

  private setEnabledFilter(status: 'all' | 'enabled' | 'disabled'): void {
    this.filterState.enabledFilter = status;
    if (this.onFilterChange) {
      this.onFilterChange(this.filterState);
    }
  }

  private setSyncFilter(status: 'all' | 'synced' | 'unsynced'): void {
    this.filterState.syncFilter = status;
    if (this.onFilterChange) {
      this.onFilterChange(this.filterState);
    }
  }

  private setTestFilter(status: 'all' | 'available' | 'unavailable' | 'untested'): void {
    this.filterState.testFilter = status;
    if (this.onFilterChange) {
      this.onFilterChange(this.filterState);
    }
  }

  private getTypeLabel(type: BookSourceType | 'all'): string {
    switch (type) {
      case 'all':
        return '全部类型';
      case BookSourceType.TEXT:
        return '文字';
      case BookSourceType.IMAGE:
        return '漫画';
      case BookSourceType.AUDIO:
        return '音频';
      default:
        return '全部类型';
    }
  }

  private getEnabledLabel(status: 'all' | 'enabled' | 'disabled'): string {
    switch (status) {
      case 'all':
        return '全部状态';
      case 'enabled':
        return '已启用';
      case 'disabled':
        return '已禁用';
      default:
        return '全部状态';
    }
  }

  private getSyncLabel(status: 'all' | 'synced' | 'unsynced'): string {
    switch (status) {
      case 'all':
        return '同步状态';
      case 'synced':
        return '已同步';
      case 'unsynced':
        return '未同步';
      default:
        return '同步状态';
    }
  }

  private getTestLabel(status: 'all' | 'available' | 'unavailable' | 'untested'): string {
    switch (status) {
      case 'all':
        return '测试状态';
      case 'available':
        return '可用';
      case 'unavailable':
        return '不可用';
      case 'untested':
        return '未测试';
      default:
        return '测试状态';
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Column() {
      Row() {
        Text('筛选')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .margin({ right: 8 })

        if (this.getActiveFilterCount() > 0) {
          Text(this.getActiveFilterCount().toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
            .borderRadius(8)
            .margin({ right: 8 })
        }

        Blank()
          .layoutWeight(1)

        if (this.getActiveFilterCount() > 0) {
          Button() {
            Row({ space: 4 }) {
              Text('×')
                .fontSize(12)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
              Text('清除筛选')
                .fontSize(12)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            }
          }
          .height(28)
          .backgroundColor(this.tc('rgba(0,125,255,0.1)', 'rgba(0,125,255,0.2)'))
          .borderRadius(14)
          .padding({ left: 8, right: 8 })
          .onClick(() => this.clearAllFilters())
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      Row() {
        this.FilterSegment(
          this.getTypeLabel(this.filterState.typeFilter),
          this.filterState.typeFilter !== 'all',
          () => { this.showTypePicker = true; }
        )

        this.FilterSegment(
          this.getEnabledLabel(this.filterState.enabledFilter),
          this.filterState.enabledFilter !== 'all',
          () => { this.showEnabledPicker = true; }
        )

        this.FilterSegment(
          this.getSyncLabel(this.filterState.syncFilter),
          this.filterState.syncFilter !== 'all',
          () => { this.showSyncPicker = true; }
        )

        this.FilterSegment(
          this.getTestLabel(this.filterState.testFilter),
          this.filterState.testFilter !== 'all',
          () => { this.showTestPicker = true; }
        )
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })

      if (this.showTypePicker) {
        this.FilterPickerOverlay(
          ['全部类型', '文字', '漫画', '音频'],
          [BookSourceType.TEXT, BookSourceType.IMAGE, BookSourceType.AUDIO],
          this.filterState.typeFilter,
          (value: string) => {
            if (value === '全部类型') {
              this.setTypeFilter('all');
            } else if (value === '文字') {
              this.setTypeFilter(BookSourceType.TEXT);
            } else if (value === '漫画') {
              this.setTypeFilter(BookSourceType.IMAGE);
            } else if (value === '音频') {
              this.setTypeFilter(BookSourceType.AUDIO);
            }
            this.showTypePicker = false;
          },
          () => { this.showTypePicker = false; }
        )
      }

      if (this.showEnabledPicker) {
        this.FilterPickerOverlay(
          ['全部状态', '已启用', '已禁用'],
          ['enabled', 'disabled'],
          this.filterState.enabledFilter,
          (value: string) => {
            if (value === '全部状态') {
              this.setEnabledFilter('all');
            } else if (value === '已启用') {
              this.setEnabledFilter('enabled');
            } else if (value === '已禁用') {
              this.setEnabledFilter('disabled');
            }
            this.showEnabledPicker = false;
          },
          () => { this.showEnabledPicker = false; }
        )
      }

      if (this.showSyncPicker) {
        this.FilterPickerOverlay(
          ['同步状态', '已同步', '未同步'],
          ['synced', 'unsynced'],
          this.filterState.syncFilter,
          (value: string) => {
            if (value === '同步状态') {
              this.setSyncFilter('all');
            } else if (value === '已同步') {
              this.setSyncFilter('synced');
            } else if (value === '未同步') {
              this.setSyncFilter('unsynced');
            }
            this.showSyncPicker = false;
          },
          () => { this.showSyncPicker = false; }
        )
      }

      if (this.showTestPicker) {
        this.FilterPickerOverlay(
          ['测试状态', '可用', '不可用', '未测试'],
          ['available', 'unavailable', 'untested'],
          this.filterState.testFilter,
          (value: string) => {
            if (value === '测试状态') {
              this.setTestFilter('all');
            } else if (value === '可用') {
              this.setTestFilter('available');
            } else if (value === '不可用') {
              this.setTestFilter('unavailable');
            } else if (value === '未测试') {
              this.setTestFilter('untested');
            }
            this.showTestPicker = false;
          },
          () => { this.showTestPicker = false; }
        )
      }
    }
    .width('100%')
    .backgroundColor(this.tc('#FFFFFF', '#2C2C2E'))
  }

  @Builder
  FilterSegment(label: string, isActive: boolean, onClick: () => void) {
    Button() {
      Row({ space: 4 }) {
        Text(label)
          .fontSize(13)
          .fontColor(isActive ? '#FFFFFF' : this.tc('#666666', '#AAAAAA'))
          .maxLines(1)

        Text('▼')
          .fontSize(8)
          .fontColor(isActive ? '#FFFFFF' : this.tc('#999999', '#888888'))
      }
    }
    .height(32)
    .backgroundColor(isActive ? COMMON_COLORS.PRIMARY_BLUE : this.tc('#F5F5F5', '#1A1A1A'))
    .borderRadius(16)
    .padding({ left: 12, right: 12 })
    .margin({ right: 8 })
    .onClick(onClick)
  }

  @Builder
  FilterPickerOverlay(
    labels: string[],
    values: string[],
    currentValue: string,
    onSelect: (value: string) => void,
    onCancel: () => void
  ) {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => onCancel())

      Column({ space: 12 }) {
        Row() {
          Text('选择筛选条件')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))

          Blank().layoutWeight(1)

          Button() {
            Text('取消')
              .fontSize(14)
              .fontColor(this.tc('#666666', '#AAAAAA'))
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => onCancel())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

        Column({ space: 0 }) {
          ForEach(labels, (label: string, index: number) => {
            Column() {
              this.PickerItem(label, index === 0 ? 'all' : values[index - 1], currentValue, () => onSelect(label))

              if (index < labels.length - 1) {
                Divider()
                  .color(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
              }
            }
          }, (label: string, index: number) => label + '_' + index)
        }
        .width('100%')
      }
      .width('100%')
      .backgroundColor(this.tc('#FFFFFF', '#2C2C2E'))
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  @Builder
  PickerItem(label: string, value: string, currentValue: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.tc('#333333', '#FFFFFF'))
        .layoutWeight(1)

      if (value === currentValue) {
        Text('✓')
          .fontSize(18)
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(onClick)
  }
}
