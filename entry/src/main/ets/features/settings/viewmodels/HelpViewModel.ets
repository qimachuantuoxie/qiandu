/**
 * HelpPage ViewModel - V2 version
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

interface HelpItem {
  id: string;
  title: string;
  content: string;
  category: string;
}

@ObservedV2
export class HelpViewModel {
  @Trace searchKeyword: string = '';
  @Trace filteredItems: HelpItem[] = [];
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  private helpItems: HelpItem[] = [
    { id: '1', title: '濡備綍瀵煎叆涔︾睄', content: '閫氳繃鏂囦欢绠＄悊鍣ㄦ坊鍔犳垨鏂囦欢閫夋嫨鍣ㄥ鍏ヤ功绫?, category: 'basic' },
    { id: '2', title: '濡備綍璋冩暣瀛椾綋澶у皬', content: '鍦ㄨ缃〉璋冩暣瀛椾綋缂╂斁姣斾緥', category: 'display' },
    { id: '3', title: '濡備綍鍒囨崲涓婚妯″紡', content: '鍦ㄨ缃〉鍒囨崲涓婚妯″紡', category: 'display' },
    { id: '4', title: '濡備綍浣跨敤涔︽簮', content: '鍦ㄤ功婧愮鐞嗕腑娣诲姞鍜岄厤缃功婧?, category: 'source' },
    { id: '5', title: '濡備綍鍚屾闃呰杩涘害', content: '鑱旂綉鍚庤嚜鍔ㄥ悓姝ラ槄璇昏繘搴?, category: 'sync' },
    { id: '6', title: '濡備綍瀵煎嚭绗旇', content: '鍦ㄧ瑪璁伴〉闈㈤€夋嫨瀵煎嚭鍔熻兘', category: 'notes' },
    { id: '7', title: '濡備綍娣诲姞涔︾', content: '闃呰鏃剁偣鍑讳功绛惧浘鏍囨坊鍔?, category: 'reading' },
    { id: '8', title: '濡備綍浣跨敤OCR', content: '鐐瑰嚮OCR鎵弿璇嗗埆鏂囧瓧', category: 'reading' },
    { id: '9', title: '濡備綍鍒囨崲TTS', content: '鍦ㄨ缃腑寮€鍚闊虫湕璇?, category: 'tts' },
    { id: '10', title: '濡備綍鎵归噺绠＄悊', content: '闀挎寜杩涘叆鎵归噺绠＄悊妯″紡', category: 'manage' }
  ];

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.filteredItems = this.helpItems;
  }

  search(keyword: string): void {
    this.searchKeyword = keyword;
    if (keyword.trim() === '') {
      this.filteredItems = Array.from(this.helpItems);
    } else {
      const lower = keyword.toLowerCase();
      this.filteredItems = this.helpItems.filter((item) =>
        item.title.toLowerCase().includes(lower) ||
        item.content.toLowerCase().includes(lower)
      );
    }
  }

  getByCategory(category: string): HelpItem[] {
    if (category === 'all') {
      return Array.from(this.helpItems);
    }
    return this.helpItems.filter((item) => item.category === category);
  }

  getCategories(): string[] {
    const categories = new Set<string>();
    this.helpItems.forEach((item) => categories.add(item.category));
    return Array.from(categories);
  }

  getCategoryTitle(category: string): string {
    const titles: Record<string, string> = {
      basic: '鍩虹鎿嶄綔',
      display: '鏄剧ず璁剧疆',
      source: '涔︽簮绠＄悊',
      sync: '鍚屾鍔熻兘',
      notes: '绗旇瀵煎嚭',
      reading: '闃呰鍔熻兘',
      tts: '璇煶鏈楄',
      manage: '鎵归噺绠＄悊'
    };
    return titles[category] || category;
  }
}

export const helpViewModel = new HelpViewModel();