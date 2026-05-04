/**
 * 统一页面头部组件 - 已废弃，请使用UnifiedHeader
 * @deprecated 使用UnifiedHeader替代
 */

import { fontScaleManager } from '../../core/utils/FontScaleManager';
import { AppColors } from '../constants/AppTheme';
import { UnifiedHeader, HeaderAction } from './UnifiedHeader';
import { goBack } from '../utils/NavigationHelper';

export interface HeaderAction {
  icon: string;
  tooltip: string;
  action: () => void;
}

@Component
export struct CommonHeader {
  @Prop title: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop showBack: boolean = true;
  @Prop backgroundColor?: string;
  @Prop rightActions: HeaderAction[] = [];
  @Prop colors?: AppColors;
  onBack?: () => void;

  build() {
    // 使用新的统一头部组件
    UnifiedHeader({
      title: this.title,
      isDarkMode: this.isDarkMode,
      showBack: this.showBack,
      backgroundColor: this.backgroundColor || '',
      textColor: '',
      rightActions: this.rightActions,
      onBack: this.onBack
    })
  }
}

// ============ 渐变背景头部 ============

@Component
export struct GradientHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop showBack: boolean = true;
  @Prop gradientColors: Array<[string, number]> = [];
  @Prop rightActions: HeaderAction[] = [];

private getDefaultGradient(): Array<[string, number]> {
if (this.gradientColors.length > 0) {
return this.gradientColors;
}
if (this.isDarkMode) {
return [['#1C1C1E', 0.0], ['#2C2C2E', 1.0]];
}
return [['#007DFF', 0.0], ['#5B8DEF', 1.0]];
}

  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height(180)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.getDefaultGradient()
        })
        .position({ top: 0 })

      // 内容区域
      Column() {
        Row() {
          // 左侧
          Row({ space: 12 }) {
            if (this.showBack) {
              Row() {
                SymbolGlyph($r('sys.symbol.arrow_left'))
              .fontSize(20)
              .fontColor([this.currentColors.onSurface])
                  .fontSize(20)
                .fontColor(['#FFFFFF'])
              }
              .width(40)
              .height(40)
              .justifyContent(FlexAlign.Center)
              .borderRadius(20)
              .backgroundColor('rgba(255,255,255,0.2)')
              .onClick(() => goBack())
            }

            Column({ space: 4 }) {
              Text(this.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(['#FFFFFF'])
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.subtitle) {
                Text(this.subtitle)
                  .fontSize(12)
                .fontColor('rgba(255,255,255,0.8)']
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)

          // 右侧
          if (this.rightActions.length > 0) {
            Row({ space: 8 }) {
              ForEach(this.rightActions, (action: HeaderAction) => {
                Row() {
                  Text(action.icon)
                    .fontSize(20)
                    .fontColor(['#FFFFFF'])
                }
                .width(40)
                .height(40)
                .justifyContent(FlexAlign.Center)
                .borderRadius(20)
                .backgroundColor('rgba(255,255,255,0.2)')
                .onClick(() => action.action())
              })
            }
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .position({ top: 20 })
    }
    .width('100%')
    .height(180)
  }
}

// ============ 标签页头部 ============

export interface TabItem {
  key: string;
  title: string;
  badge?: number;
}

@Component
export struct TabHeader {
  @Prop tabs: TabItem[] = [];
  @Prop currentTab: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop colors?: AppColors;
  onTabChange?: (tabKey: string) => void;

  private getPrimaryColor(): string {
    if (this.colors) {
      return this.colors.primary;
    }
    return '#007DFF';
  }

  build() {
    Column() {
      Row() {
        ForEach(this.tabs, (tab: TabItem) => {
          Column({ space: 4 }) {
            Row({ space: 4 }) {
              Text(tab.title)
                .fontSize(15)
                .fontWeight(this.currentTab === tab.key ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.currentTab === tab.key ? this.getPrimaryColor() : (this.isDarkMode ? '#AAAAAA' : '#666666'))

              if (tab.badge && tab.badge > 0) {
                Text(tab.badge > 99 ? '99+' : tab.badge.toString())
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .backgroundColor('#FF3B30')
                  .borderRadius(10)
              }
            }

            // 底部指示条
            Row()
              .width(24)
              .height(3)
              .backgroundColor(this.currentTab === tab.key ? this.getPrimaryColor() : 'transparent')
              .borderRadius(1.5)
          }
          .layoutWeight(1)
          .onClick(() => {
            if (this.onTabChange) {
              this.onTabChange(tab.key);
            }
          })
        })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })

      Divider()
        .color(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)')
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
  }
}
