/**
 * FeaturesPage ViewModel - V2閻楀牊婀?
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../../../common/constants/AppTheme';

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
      { id: 'online_book', name: '鍦ㄧ嚎涔﹀簵', description: '鍦ㄧ嚎鎼滅储鍜岄槄璇诲浘涔?, icon: 'book', enabled: true },
      { id: 'book_source', name: '涔︽簮绠＄悊', description: '绠＄悊闃呰婧愬拰瑙勫垯', icon: 'source', enabled: true },
      { id: 'folder_scan', name: '鏂囦欢澶规壂鎻?, description: '鎵弿鏈湴鍥句功鏂囦欢', icon: 'folder', enabled: true },
      { id: 'reading_stats', name: '闃呰缁熻', description: '鏌ョ湅闃呰鏁版嵁缁熻', icon: 'stats', enabled: true },
      { id: 'todo', name: '寰呭姙浜嬮」', description: '绠＄悊闃呰璁″垝', icon: 'todo', enabled: true },
      { id: 'notes', name: '绗旇绠＄悊', description: '绠＄悊鍜屽鍑虹瑪璁?, icon: 'notes', enabled: true },
      { id: 'bookmarks', name: '涔︾绠＄悊', description: '绠＄悊涔︾睄涔︾', icon: 'bookmark', enabled: true },
      { id: 'reward', name: '璧炲姪鏀寔', description: '鏀寔寮€鍙戣€?, icon: 'support', enabled: true }
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
