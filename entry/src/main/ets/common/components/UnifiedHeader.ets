/**
 * 统一导航栏组件
 * 整合了PageHeader、CommonHeader和AppBar的功能
 * 支持返回按钮、标题、副标题、自定义操作和渐变背景
 */

import { themeManager, AppColors } from '../../common/constants/AppTheme';
import { fontScaleManager } from '../../common/utils/FontScaleManager';
import { tr } from '../../core/utils/LocalizationUtil';
import { responsiveLayoutUtil } from '../../core/utils/ResponsiveLayoutUtil';
import { goBack } from '../utils/NavigationHelper';

export interface HeaderAction {
  icon: string;
  tooltip: string;
  action: () => void;
}

export interface UnifiedHeaderConfig {
  title: string;
  subtitle?: string;
  showBack?: boolean;
  backgroundColor?: string;
  textColor?: string;
  isDarkMode?: boolean;
  rightActions?: HeaderAction[];
  gradientColors?: Array<[string, number]>;
  height?: number;
}

@ComponentV2
export struct UnifiedHeader {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param showBack: boolean = true;
  @Param backgroundColor: string = '';
  @Param textColor: string = '';
  @Param isDarkMode: boolean = false;
  @Param rightActions: HeaderAction[] = [];
  @Param gradientColors: Array<[string, number]> = [];
  @Param height: number = 0; // 0表示自动根据设备类型确定
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local actualHeight: number = 56;
  
  onBack?: () => void;
  @BuilderParam actions: () => void = () => {};

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.loadFontScale();
    this.updateHeight();
  }

  private async loadFontScale(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private async updateHeight(): Promise<void> {
    if (this.height > 0) {
      this.actualHeight = this.height;
    } else {
      const screenWidth = await responsiveLayoutUtil.getScreenWidth();
      this.actualHeight = responsiveLayoutUtil.getHeaderHeight(screenWidth);
    }
  }

  private getBackgroundColor(): string {
    if (this.backgroundColor && this.backgroundColor.length > 0) {
      return this.backgroundColor;
    }
    return this.isDarkMode ? '#1C1C1E' : '#FFFFFF';
  }

  private getTextColor(): string {
    if (this.textColor && this.textColor.length > 0) {
      return this.textColor;
    }
    return this.isDarkMode ? '#FFFFFF' : '#1A1A1A';
  }

  private handleBack(): void {
    if (this.onBack) {
      this.onBack();
    } else {
      goBack();
    }
  }

  build() {
    if (this.gradientColors.length > 0) {
      // 渐变背景头部
      this.GradientHeaderContent();
    } else {
      // 普通背景头部
      this.NormalHeaderContent();
    }
  }

  @Builder
  NormalHeaderContent() {
    Row() {
      // 左侧区域
      Row({ space: 12 }) {
        if (this.showBack) {
          Row() {
            SymbolGlyph($r('sys.symbol.arrow_left'))
              .fontSize(fontScaleManager.getScaledFontSize(20))
              .fontColor([this.getTextColor()])
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .borderRadius(20)
          .onClick(() => this.handleBack())
          .stateStyles({
            pressed: {
              .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
            },
            normal: {
              .backgroundColor('transparent')
            }
          })
          .accessibilityLabel(tr('back'))
        }

        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTextColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.subtitle && this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: this.showBack ? 8 : 0 })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      // 右侧操作按钮
      if (this.rightActions.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.rightActions, (action: HeaderAction) => {
            Row() {
              SymbolGlyph($r(`sys.symbol.${action.icon}`))
                .fontSize(fontScaleManager.getScaledFontSize(20))
                .fontColor([this.getTextColor()])
            }
            .width(40)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .borderRadius(20)
            .onClick(() => action.action())
            .stateStyles({
              pressed: {
                .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
              },
              normal: {
                .backgroundColor('transparent')
              }
            })
            .accessibilityLabel(action.tooltip)
          })
        }
      } else if (this.actions) {
        Row() {
          this.actions()
        }
      }
    }
    .width('100%')
    .height(this.actualHeight)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getBackgroundColor())
    .shadow({
      radius: 4,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  GradientHeaderContent() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height(this.actualHeight + 124) // 额外高度用于渐变效果
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.gradientColors.length > 0 ? this.gradientColors : 
            (this.isDarkMode ? [['#1C1C1E', 0.0], ['#2C2C2E', 1.0]] : [['#007DFF', 0.0], ['#5B8DEF', 1.0]])
        })
        .position({ top: 0 })

      // 内容区域
      Row() {
        // 左侧
        Row({ space: 12 }) {
          if (this.showBack) {
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_left'))
                .fontSize(fontScaleManager.getScaledFontSize(20))
                .fontColor(['#FFFFFF'])
            }
            .width(40)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .borderRadius(20)
            .backgroundColor('rgba(255,255,255,0.2)')
            .onClick(() => this.handleBack())
            .accessibilityLabel(tr('back'))
          }

          Column({ space: 4 }) {
            Text(this.title)
              .fontSize(fontScaleManager.getScaledFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.subtitle && this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor('rgba(255,255,255,0.8)')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: this.showBack ? 8 : 0 })
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 右侧
        if (this.rightActions.length > 0) {
          Row({ space: 8 }) {
            ForEach(this.rightActions, (action: HeaderAction) => {
              Row() {
                SymbolGlyph($r(`sys.symbol.${action.icon}`))
                  .fontSize(fontScaleManager.getScaledFontSize(20))
                  .fontColor(['#FFFFFF'])
              }
              .width(40)
              .height(40)
              .justifyContent(FlexAlign.Center)
              .borderRadius(20)
              .backgroundColor('rgba(255,255,255,0.2)')
              .onClick(() => action.action())
              .accessibilityLabel(action.tooltip)
            })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .position({ top: 20 })
    }
    .width('100%')
    .height(this.actualHeight + 124)
  }
}
