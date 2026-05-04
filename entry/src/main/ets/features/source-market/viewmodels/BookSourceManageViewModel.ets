/**
 * BookSourceManagePage ViewModel - V2 version
 * 
 * Manages all states for book source management page
 */

import { BookSource, ReplaceRule } from '../models/CoreSourceModel';
import { bookSourceViewModel, ImportResult, SourceFilterState } from './BookSourceViewModel';
import { OnlineSourceInfo } from '../utils/BookSourceImporter';
import { appTheme, themeManager, AppColors } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { DeviceUtils } from '../utils/DeviceUtils';

@ObservedV2
export class BookSourceManageViewModel {
  @Trace sourceList: BookSource[] = [];
  @Trace ruleList: ReplaceRule[] = [];

  @Trace activeTab: number = 0;
  @Trace showAddDialog: boolean = false;
  @Trace showEditDialog: boolean = false;
  @Trace showUrlImportDialog: boolean = false;
  @Trace showPresetDialog: boolean = false;
  @Trace showResultDialog: boolean = false;
  @Trace showMoreMenu: boolean = false;
  @Trace isBatchMode: boolean = false;
  @Trace selectAll: boolean = false;
  @Trace selectedIds: string[] = [];
  @Trace selectedCount: number = 0;
  @Trace sourceMoreMenuId: string = '';

  @Trace editingSourceId: string = '';
  @Trace newSourceName: string = '';
  @Trace newSourceUrl: string = '';
  @Trace newSourceEnabled: boolean = true;

  @Trace importUrl: string = '';
  @Trace isImporting: boolean = false;
  @Trace importResult: ImportResult | null = null;

  @Trace presetSources: OnlineSourceInfo[] = [];
  @Trace selectedPreset: OnlineSourceInfo | null = null;

  @Trace filterState: SourceFilterState = bookSourceViewModel.getFilterState();

  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace isTablet: boolean = false;
  @Trace isDarkMode: boolean = false;

  @Trace searchKeyword: string = '';

  unsubscribe: (() => void) | null = null;
  ruleUnsubscribe: (() => void) | null = null;
  longPressTimer: number = -1;

  async init(context: Context): Promise<void> {
    await fontScaleManager.init(context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadSources();
    this.loadRules();

    appTheme.subscribe(() => {
      this.isDarkMode = appTheme.isDarkMode();
      this.currentColors = themeManager.getColors();
    });
  }

  loadSources(): void {
    this.sourceList = bookSourceViewModel.getAllSources();
  }

  loadRules(): void {
    this.ruleList = bookSourceViewModel.getAllRules();
  }

  cleanup(): void {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
    if (this.ruleUnsubscribe) {
      this.ruleUnsubscribe();
    }
    if (this.longPressTimer !== -1) {
      clearTimeout(this.longPressTimer);
    }
  }

  setTab(tab: number): void {
    this.activeTab = tab;
  }

  search(keyword: string): void {
    this.searchKeyword = keyword;
    if (keyword.trim() === '') {
      this.loadSources();
    } else {
      this.sourceList = bookSourceViewModel.searchSources(keyword);
    }
  }

  setFilterState(state: SourceFilterState): void {
    this.filterState = state;
    bookSourceViewModel.setFilterState(state);
    this.loadSources();
  }

  toggleBatchMode(): void {
    this.isBatchMode = !this.isBatchMode;
    if (!this.isBatchMode) {
      this.selectedCount = 0;
    }
  }

  toggleSelectAll(): void {
    this.selectAll = !this.selectAll;
    if (this.selectAll) {
      const ids: string[] = this.sourceList.map((source) => source.id);
      this.selectedIds = ids;
      this.selectedCount = ids.length;
    } else {
      this.selectedIds = [];
      this.selectedCount = 0;
    }
  }

  toggleSelect(sourceId: string): void {
    const index = this.selectedIds.indexOf(sourceId);
    if (index > -1) {
      this.selectedIds.splice(index, 1);
    } else {
      this.selectedIds.push(sourceId);
    }
    this.selectedCount = this.selectedIds.length;
    this.selectAll = this.selectedIds.length === this.sourceList.length && this.sourceList.length > 0;
  }

  async deleteSelected(): Promise<void> {
    for (let i = 0; i < this.selectedIds.length; i++) {
      await bookSourceViewModel.deleteSource(this.selectedIds[i]);
    }
    this.loadSources();
    this.isBatchMode = false;
    this.selectedIds = [];
    this.selectedCount = 0;
  }

  async toggleSourceEnabled(sourceId: string): Promise<void> {
    const sourceIndex = this.sourceList.findIndex((source) => source.id === sourceId);
    if (sourceIndex > -1) {
      const oldSource = this.sourceList[sourceIndex];
      const updatedSource: BookSource = {
        id: oldSource.id,
        name: oldSource.name,
        url: oldSource.url,
        enabled: !oldSource.enabled,
        type: oldSource.type,
        rules: oldSource.rules,
        createTime: oldSource.createTime,
        updateTime: oldSource.updateTime
      };
      this.sourceList[sourceIndex] = updatedSource;
      await bookSourceViewModel.updateSource(updatedSource);
    }
  }

  openAddDialog(): void {
    this.showAddDialog = true;
    this.newSourceName = '';
    this.newSourceUrl = '';
    this.newSourceEnabled = true;
    this.editingSourceId = '';
  }

  closeAddDialog(): void {
    this.showAddDialog = false;
  }

  async saveNewSource(): Promise<void> {
    if (this.newSourceName.trim() && this.newSourceUrl.trim()) {
      const source: BookSource = {
        id: this.editingSourceId || `source_${Date.now()}`,
        name: this.newSourceName.trim(),
        url: this.newSourceUrl.trim(),
        enabled: this.newSourceEnabled,
        type: 'custom',
        rules: [],
        createTime: this.editingSourceId ? this.sourceList.find((s) => s.id === this.editingSourceId)?.createTime || Date.now() : Date.now(),
        updateTime: Date.now()
      };

      if (this.editingSourceId) {
        await bookSourceViewModel.updateSource(source);
      } else {
        await bookSourceViewModel.addSource(source);
      }
      this.loadSources();
      this.closeAddDialog();
    }
  }

  openEditDialog(sourceId: string): void {
    const source = this.sourceList.find((s) => s.id === sourceId);
    if (source) {
      this.editingSourceId = sourceId;
      this.newSourceName = source.name;
      this.newSourceUrl = source.url;
      this.newSourceEnabled = source.enabled;
      this.showEditDialog = true;
    }
  }

  closeEditDialog(): void {
    this.showEditDialog = false;
    this.editingSourceId = '';
  }

  async deleteSource(sourceId: string): Promise<void> {
    await bookSourceViewModel.deleteSource(sourceId);
    this.loadSources();
  }
}

export const bookSourceManageViewModel = new BookSourceManageViewModel();