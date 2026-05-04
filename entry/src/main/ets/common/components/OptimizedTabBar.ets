/**
 * 底部导航栏组件 - 简洁实用版本
 * 使用系统SymbolGlyph图标，无emoji
 * 
 * @since 7.0.0
 */

import { themeManager, AppColors } from '../../core/utils/AppTheme';
import { fontScaleManager } from '../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../core/utils/LayoutConstants';
import { layoutHelper } from '../../core/utils/LayoutHelper';

export interface TabBarItem {
  icon: string;  // 系统图标名称，如 'house.fill'
  activeIcon?: string;
  label: string;
}

export interface TabBarConfig {
  items: TabBarItem[];
  currentIndex: number;
  isDarkMode: boolean;
  onTabChange?: (index: number) => void;
}

@ComponentV2
export struct OptimizedTabBar {
  @Param config: TabBarConfig = {
    items: [],
    currentIndex: 0,
    isDarkMode: false
  };
  
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
  }

  build() {
    Row() {
      ForEach(this.config.items, (item: TabBarItem, index: number) => {
        this.TabItem(item, index)
      }, (item: TabBarItem, index: number) => `${item.label}_${index}`)
    }
    .width('100%')
    .height(this.getTabBarHeight())
    .backgroundColor(this.getTabBarBackground())
    .backdropBlur(this.config.isDarkMode ? 20 : 15)
    .border({
      width: { top: 1 },
      color: this.config.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'
    })
    .shadow(getShadow('lg', this.config.isDarkMode))
    .padding({
      bottom: layoutHelper.getSafeBottomPadding(),
      left: Spacing.sm,
      right: Spacing.sm
    })
  }

  @Builder
  TabItem(item: TabBarItem, index: number) {
    Column({ space: Spacing.xs }) {
      // 图标 - 支持系统符号或emoji
      if (item.icon.length <= 2) {
        // emoji图标（1-2个字符）
        Text(this.getCurrentIcon(item, index))
          .fontSize(this.getIconSize())
          .fontColor(this.getIconColor(index))
      } else {
        // 系统符号图标
        SymbolGlyph($r(`sys.symbol.${this.getCurrentIcon(item, index)}`))
          .fontSize(this.getIconSize())
          .fontColor([this.getIconColor(index)])
      }
      
      // 标签
      Text(item.label)
        .fontSize(this.getLabelFontSize())
        .fontWeight(this.config.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.getLabelColor(index))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.config.onTabChange && this.config.currentIndex !== index) {
        this.config.onTabChange(index);
      }
    })
    .stateStyles({
      pressed: {
        .scale({ x: 0.95, y: 0.95 })
        .opacity(0.7)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(1)
      }
    })
  }

  private getCurrentIcon(item: TabBarItem, index: number): string {
    const isActive = this.config.currentIndex === index;
    return isActive ? (item.activeIcon || item.icon) : item.icon;
  }

  private getIconSize(): number {
    return fontScaleManager.getScaledFontSize(
      this.config.currentIndex === 0 ? Size.iconLG : Size.iconMD
    );
  }

  private getIconColor(index: number): string {
    const isActive = this.config.currentIndex === index;
    if (isActive) {
      return this.currentColors.primary;
    }
    return this.config.isDarkMode ? '#888888' : '#999999';
  }

  private getLabelColor(index: number): string {
    const isActive = this.config.currentIndex === index;
    if (isActive) {
      return this.currentColors.primary;
    }
    return this.config.isDarkMode ? '#888888' : '#999999';
  }

  private getTabBarHeight(): number {
    // 平板使用更高的导航栏
    const screenInfo = layoutHelper.getScreenInfo();
    const baseHeight = screenInfo?.isTablet ? 64 : 56;
    return baseHeight;
  }

  private getTabBarBackground(): string {
    // 毛玻璃效果背景
    return this.config.isDarkMode 
      ? 'rgba(28,28,30,0.85)' 
      : 'rgba(255,255,255,0.85)';
  }

  private getSafeBottomPadding(): number {
    return layoutHelper.getSafeBottomPadding();
  }
}

// ==================== 预览组件 ====================
@Preview
@Component
struct OptimizedTabBarPreview {
  @State currentTab: number = 0;
  @State isDarkMode: boolean = false;

  private tabItems: TabBarItem[] = [
    { icon: 'house.fill', activeIcon: 'house.fill', label: '首页' },
    { icon: 'book.fill', activeIcon: 'book.fill', label: '书架' },
    { icon: 'magnifyingglass', activeIcon: 'magnifyingglass.circle.fill', label: '书城' },
    { icon: 'person', activeIcon: 'person.fill', label: '我的' }
  ];

  build() {
    Column() {
      // 浅色模式预览
      Text('浅色模式 - 系统图标')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')
        .width('100%')
        .textAlign(TextAlign.Center)

      OptimizedTabBar({
        config: {
          items: this.tabItems,
          currentIndex: this.currentTab,
          isDarkMode: false,
          onTabChange: (index: number) => {
            this.currentTab = index;
          }
        }
      })

      Divider().margin({ top: 20, bottom: 20 })

      // 深色模式预览
      Text('深色模式 - 系统图标')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Center)

      OptimizedTabBar({
        config: {
          items: this.tabItems,
          currentIndex: this.currentTab,
          isDarkMode: true,
          onTabChange: (index: number) => {
            this.currentTab = index;
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
