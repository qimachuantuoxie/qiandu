// 搜索栏组件
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

@Component
export struct SearchBar {
  @Prop isDarkMode: boolean = false;
  @Prop searchText: string = '';
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  onSearchChange?: (text: string) => void;
  onClose?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.loadFontScale();
  }

  private async loadFontScale(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private searchTimer: number = -1;

  aboutToDisappear() {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
  }

  build() {
    Row() {
      // 关闭按钮
      Text('✕')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontColor(this.currentColors.textSecondary)
        .padding(8)
        .onClick(() => {
          if (this.onClose) {
            this.onClose();
          }
        })

      // 搜索输入框
      TextInput({ placeholder: tr('search_books'), text: this.searchText })
        .layoutWeight(1)
        .height(40)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.06)')
        .borderRadius(20)
        .padding({ left: 18, right: 18 })
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .caretColor(this.currentColors.primary)
        .onChange((value: string) => {
          if (this.onSearchChange) {
            // 清除之前的定时器
            if (this.searchTimer !== -1) {
              clearTimeout(this.searchTimer);
            }
            // 设置防抖
            this.searchTimer = setTimeout(() => {
              this.onSearchChange!(value);
              this.searchTimer = -1;
            }, 300);
          }
        })

      // 搜索图标
      Text('🔍')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontColor(this.currentColors.textSecondary)
        .padding(8)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backdropBlur(30)
    .backgroundColor(this.isDarkMode ? 'rgba(28,28,30,0.85)' : 'rgba(255,255,255,0.85)')
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'
    })
  }
}