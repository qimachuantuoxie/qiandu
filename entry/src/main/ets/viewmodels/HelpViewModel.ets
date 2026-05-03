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
    { id: '1', title: '如何导入书籍', content: '通过文件管理器添加或文件选择器导入书籍', category: 'basic' },
    { id: '2', title: '如何调整字体大小', content: '在设置页调整字体缩放比例', category: 'display' },
    { id: '3', title: '如何切换主题模式', content: '在设置页切换主题模式', category: 'display' },
    { id: '4', title: '如何使用书源', content: '在书源管理中添加和配置书源', category: 'source' },
    { id: '5', title: '如何同步阅读进度', content: '联网后自动同步阅读进度', category: 'sync' },
    { id: '6', title: '如何导出笔记', content: '在笔记页面选择导出功能', category: 'notes' },
    { id: '7', title: '如何添加书签', content: '阅读时点击书签图标添加', category: 'reading' },
    { id: '8', title: '如何使用OCR', content: '点击OCR扫描识别文字', category: 'reading' },
    { id: '9', title: '如何切换TTS', content: '在设置中开启语音朗读', category: 'tts' },
    { id: '10', title: '如何批量管理', content: '长按进入批量管理模式', category: 'manage' }
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
      basic: '基础操作',
      display: '显示设置',
      source: '书源管理',
      sync: '同步功能',
      notes: '笔记导出',
      reading: '阅读功能',
      tts: '语音朗读',
      manage: '批量管理'
    };
    return titles[category] || category;
  }
}

export const helpViewModel = new HelpViewModel();