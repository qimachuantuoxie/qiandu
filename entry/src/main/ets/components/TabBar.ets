/**
 * 底部导航栏组件 - 优化版（系统符号）
 * 使用 HarmonyOS SymbolGlyph 替代 Emoji，支持主题色
 *
 * @since 3.0.0
 */

import { themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

interface TabItem {
  key: string;
  symbol: string;        // 未选中状态符号
  activeSymbol: string;  // 选中状态符号
  hasBadge?: boolean;    // 是否显示红点
}

@Component
export struct TabBar {
  @Prop currentTab: number = 0;
  @Prop isDarkMode: boolean = false;
  @Prop unreadCount: number = 0; // 未读消息数
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  onTabChange?: (index: number) => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.loadFontScale();
  }

  private async loadFontScale(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  // 5个Tab：首页、书架、书城、发现、我的（使用系统符号）
  private readonly tabs: TabItem[] = [
    { key: 'home', symbol: 'house', activeSymbol: 'house_fill' },
    { key: 'bookshelf', symbol: 'book', activeSymbol: 'book_fill' },
    { key: 'store', symbol: 'bag', activeSymbol: 'bag_fill' },
    { key: 'discover', symbol: 'safari', activeSymbol: 'safari_fill' },
    { key: 'profile', symbol: 'person', activeSymbol: 'person_fill' }
  ];

  build() {
    Column() {
      // 顶部细线
      Row()
        .width('100%')
        .height(0.5)
        .backgroundColor(this.currentColors.divider)

      Row() {
        ForEach(this.tabs, (tab: TabItem, index: number) => {
          Stack() {
            Column({ space: 4 }) {
              // 图标 - 使用 SymbolGlyph
              SymbolGlyph($r(`sys.symbol.${this.currentTab === index ? tab.activeSymbol : tab.symbol}`))
                .fontSize(fontScaleManager.getScaledFontSize(24))
                .fontColor([this.currentTab === index ? this.currentColors.primary : this.currentColors.textSecondary])
                .animation({ duration: 200 })

              // 文字
              Text(tr(tab.key))
                .fontSize(fontScaleManager.getScaledFontSize(11))
                .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTab === index
                  ? this.currentColors.primary
                  : this.currentColors.textSecondary)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .height(56)
            .onClick(() => {
              if (this.onTabChange) {
                this.onTabChange(index);
              }
            })

            // 红点提示
            if (tab.hasBadge && this.unreadCount > 0) {
              Text(this.unreadCount > 99 ? '99+' : String(this.unreadCount))
                .fontSize(fontScaleManager.getScaledFontSize(10))
                .fontColor('#FFFFFF')
                .backgroundColor(COMMON_COLORS.ERROR_RED)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(8)
                .position({ x: '50%', y: -4 })
            }
          }
          .layoutWeight(1)
        })
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.currentColors.surface)
    }
  }
}
