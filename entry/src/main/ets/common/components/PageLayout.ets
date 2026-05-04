/**
 * 通用页面布局组件
 * 提供标准化的页面结构：Header + Content + (Optional Footer)
 * 
 * @since 7.0.0
 */

import { UnifiedHeader, HeaderAction } from './UnifiedHeader';
import { Spacing, BorderRadius, getShadow } from '../../common/constants/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';
import { themeManager, AppColors } from '../../common/constants/AppTheme';
import { tr } from '../../core/utils/LocalizationUtil';

export interface PageLayoutConfig {
  title: string;
  subtitle?: string;
  showBack?: boolean;
  showHeader?: boolean;
  headerHeight?: number;
  padding?: number;
  backgroundColor?: string;
  rightActions?: HeaderAction[];
  gradientColors?: Array<[string, number]>;
}

@ComponentV2
export struct StandardPageLayout {
  @Param config: PageLayoutConfig = {
    title: '',
    showBack: true,
    showHeader: true,
    padding: Spacing.lg
  };
  
  @Param isDarkMode: boolean = false;
  @Param screenInfo: ScreenInfo | null = null;
  @Local currentColors: AppColors = themeManager.getColors();
  
  @BuilderParam header?: () => void;
  @BuilderParam content: () => void;
  @BuilderParam footer?: () => void;
  @BuilderParam floatingAction?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
  }

  build() {
    Stack() {
      Column() {
        // 头部区域
        if (this.config.showHeader !== false) {
          if (this.header) {
            this.header()
          } else {
            UnifiedHeader({
              title: this.config.title,
              subtitle: this.config.subtitle || '',
              showBack: this.config.showBack !== false,
              isDarkMode: this.isDarkMode,
              backgroundColor: this.config.backgroundColor || '',
              textColor: '',
              rightActions: this.config.rightActions || [],
              gradientColors: this.config.gradientColors || [],
              height: this.config.headerHeight || 0
            })
          }
        }

        // 内容区域
        Scroll() {
          Column() {
            this.content()
          }
          .width('100%')
          .padding(this.config.padding || Spacing.lg)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .backgroundColor(this.getBackgroundColor())

        // 底部区域（可选）
        if (this.footer) {
          this.footer()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getBackgroundColor())

      // 浮动操作按钮（可选）
      if (this.floatingAction) {
        this.floatingAction()
      }
    }
    .width('100%')
    .height('100%')
  }

  private getBackgroundColor(): string {
    if (this.config.backgroundColor && this.config.backgroundColor.length > 0) {
      return this.config.backgroundColor;
    }
    return this.currentColors.background;
  }
}

/**
 * 列表页面布局组件
 * 针对列表场景优化，支持下拉刷新和加载更多
 */
@ComponentV2
export struct ListPageLayout {
  @Param config: PageLayoutConfig = {
    title: '',
    showBack: true,
    showHeader: true,
    padding: 0
  };
  
  @Param isDarkMode: boolean = false;
  @Param isLoading: boolean = false;
  @Param hasMore: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  
  @BuilderParam header?: () => void;
  @BuilderParam listContent: () => void;
  @BuilderParam emptyState?: () => void;
  @BuilderParam loadingFooter?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
  }

  build() {
    StandardPageLayout({
      config: this.config,
      isDarkMode: this.isDarkMode,
      screenInfo: null,
      header: this.header,
      content: () => {
        List() {
          this.listContent()
          
          // 加载更多指示器
          if (this.hasMore || this.isLoading) {
            ListItem() {
              if (this.loadingFooter) {
                this.loadingFooter()
              } else {
                this.DefaultLoadingFooter()
              }
            }
            .enabled(false)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .cachedCount(5)
      },
      footer: undefined,
      floatingAction: undefined
    })
  }

  @Builder
  DefaultLoadingFooter() {
    Row() {
      LoadingProgress()
        .width(24)
        .height(24)
        .color(this.currentColors.primary)
      
      Text(tr('loading'))
        .fontSize(14)
        .fontColor(this.currentColors.textSecondary)
        .margin({ left: Spacing.sm })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: Spacing.lg, bottom: Spacing.lg })
  }
}

/**
 * 表单页面布局组件
 * 针对表单场景优化，提供统一的表单项样式
 */
@ComponentV2
export struct FormPageLayout {
  @Param config: PageLayoutConfig = {
    title: '',
    showBack: true,
    showHeader: true,
    padding: Spacing.lg
  };
  
  @Prop isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  
  @BuilderParam header?: () => void;
  @BuilderParam formContent: () => void;
  @BuilderParam submitButton?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
  }

  build() {
    StandardPageLayout({
      config: this.config,
      isDarkMode: this.isDarkMode,
      screenInfo: null,
      header: this.header,
      content: () => {
        Column({ space: Spacing.md }) {
          this.formContent()
        }
        .width('100%')
      },
      footer: this.submitButton ? () => {
        Column() {
          if (this.submitButton) {
            this.submitButton()
          }
        }
        .width('100%')
        .padding(Spacing.lg)
        .backgroundColor(this.currentColors.surface)
        .shadow(getShadow('lg', this.isDarkMode))
      } : undefined,
      floatingAction: undefined
    })
  }
}
