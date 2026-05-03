/**
 * FeaturesPage ViewModel - V2鐗堟湰
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

export interface FeatureItem {
  id: string;
  name: string;
  description: string;
  icon: string;
  enabled: boolean;
  titleKey?: string;
  descKey?: string;
  statusKey?: string;
  tags?: string[];
}

@ObservedV2
export class FeaturesViewModel {
  @Trace features: FeatureItem[] = [];
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadFeatures();
  }

loadFeatures(): void {
    this.features = [
      { id: 'online_book', name: '在线书店', description: '在线搜索和阅读图书', icon: 'book', enabled: true },
      { id: 'book_source', name: '书源管理', description: '管理阅读源和规则', icon: 'source', enabled: true },
      { id: 'folder_scan', name: '文件夹扫描', description: '扫描本地图书文件', icon: 'folder', enabled: true },
      { id: 'reading_stats', name: '阅读统计', description: '查看阅读数据统计', icon: 'stats', enabled: true },
      { id: 'todo', name: '待办事项', description: '管理阅读计划', icon: 'todo', enabled: true },
      { id: 'notes', name: '笔记管理', description: '管理和导出笔记', icon: 'notes', enabled: true },
      { id: 'bookmarks', name: '书签管理', description: '管理书籍书签', icon: 'bookmark', enabled: true },
      { id: 'reward', name: '赞助支持', description: '支持开发者', icon: 'support', enabled: true }
    ];
  }

  toggleFeature(featureId: string): void {
    const newFeatures: FeatureItem[] = [];
    for (let i = 0; i < this.features.length; i++) {
      const f = this.features[i];
      if (f.id === featureId) {
        newFeatures.push({
          id: f.id,
          name: f.name,
          description: f.description,
          icon: f.icon,
          enabled: !f.enabled,
          titleKey: f.titleKey,
          descKey: f.descKey,
          statusKey: f.statusKey,
          tags: f.tags
        });
      } else {
        newFeatures.push(f);
      }
    }
    this.features = newFeatures;
  }

  saveFeatures(): void {
    const enabledIds: string[] = [];
    for (let i = 0; i < this.features.length; i++) {
      if (this.features[i].enabled) {
        enabledIds.push(this.features[i].id);
      }
    }
    preferenceManager.setString('enabled_features', enabledIds.join(','));
  }
}

export const featuresViewModel = new FeaturesViewModel();
