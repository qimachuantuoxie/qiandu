/**
 * 统一UI组件库 - 基础组件
 * 提供统一的按钮、卡片、列表、空状态、加载等组件
 */

import { AppColors, COMMON_COLORS, LIGHT_COLORS } from '../../common/constants/AppTheme';
import { tr } from '../../core/utils/LocalizationUtil';

/**
 * 按钮颜色映射
 */
interface ButtonColorMap {
  bg: string;
  text: string;
  border: string;
}

/**
 * 标签颜色映射
 */
interface TagColorMap {
  bg: string;
  text: string;
}

// ============ 按钮组件 ============

export enum ButtonType {
  PRIMARY = 'primary',
  SECONDARY = 'secondary',
  DANGER = 'danger',
  GHOST = 'ghost',
  TEXT = 'text'
}

export enum ButtonSize {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large'
}

export interface ButtonConfig {
  text: string;
  type: ButtonType;
  buttonSize: ButtonSize;
  isEnabled: boolean;
  icon?: string;
}

@Component
export struct CommonButton {
  @Prop text: string = '按钮';
  @Prop type: ButtonType = ButtonType.PRIMARY;
  @Prop buttonSize: ButtonSize = ButtonSize.MEDIUM;
  @Prop isEnabled: boolean = true;
  @Prop icon: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop colors: AppColors = LIGHT_COLORS;
  onButtonClick?: () => void;

  private getButtonColors(): ButtonColorMap {
    const colors: AppColors = this.colors;

    const buttonColors: ButtonColorMap = {
      bg: colors.primary,
      text: '#FFFFFF',
      border: 'transparent'
    };

    if (this.type === ButtonType.SECONDARY) {
      buttonColors.bg = this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)';
      buttonColors.text = this.isDarkMode ? '#FFFFFF' : '#1A1A1A';
      buttonColors.border = this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.08)';
    } else if (this.type === ButtonType.DANGER) {
      buttonColors.bg = '#FF3B30';
      buttonColors.text = '#FFFFFF';
    } else if (this.type === ButtonType.GHOST) {
      buttonColors.bg = 'transparent';
      buttonColors.text = colors.primary;
      buttonColors.border = colors.primary;
    } else if (this.type === ButtonType.TEXT) {
      buttonColors.bg = 'transparent';
      buttonColors.text = colors.primary;
    }

    if (!this.isEnabled) {
      buttonColors.bg = this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)';
      buttonColors.text = this.isDarkMode ? '#666666' : '#CCCCCC';
    }

    return buttonColors;
  }

  private getPadding(): number {
    if (this.buttonSize === ButtonSize.SMALL) return 8;
    if (this.buttonSize === ButtonSize.LARGE) return 16;
    return 12;
  }

  private getFontSize(): number {
    if (this.buttonSize === ButtonSize.SMALL) return 13;
    if (this.buttonSize === ButtonSize.LARGE) return 16;
    return 14;
  }

  private getHeight(): number {
    if (this.buttonSize === ButtonSize.SMALL) return 32;
    if (this.buttonSize === ButtonSize.LARGE) return 48;
    return 40;
  }

  build() {
    Row({ space: this.icon ? 6 : 0 }) {
      if (this.icon) {
        Text(this.icon)
          .fontSize(this.getFontSize())
      }

      Text(this.text)
        .fontSize(this.getFontSize())
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(this.getHeight())
    .justifyContent(FlexAlign.Center)
    .padding({
      left: this.getPadding(),
      right: this.getPadding()
    })
    .backgroundColor(this.getButtonColors().bg)
    .borderRadius(this.buttonSize === ButtonSize.SMALL ? 6 : 8)
    .border({
      width: this.type === ButtonType.GHOST ? 1 : 0,
      color: this.getButtonColors().border
    })
    .opacity(this.isEnabled ? 1 : 0.5)
    .onClick(() => {
      if (this.isEnabled && this.onButtonClick) {
        this.onButtonClick();
      }
    })
    .stateStyles({
      pressed: {
        .scale({ x: 0.96, y: 0.96 })
        .opacity(this.isEnabled ? 0.85 : 0.5)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(this.isEnabled ? 1 : 0.5)
      }
    })
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
  }
}

// ============ 卡片组件 ============

export enum CardType {
  DEFAULT = 'default',
  ELEVATED = 'elevated',
  OUTLINED = 'outlined',
  GLASS = 'glass' // 毛玻璃效果
}

@Component
export struct CommonCard {
  @Prop type: CardType = CardType.DEFAULT;
  @Prop isDarkMode: boolean = false;
  @Prop cornerRadius: number = 12;
  @Prop containerPadding: number = 16;
  @Prop marginBottom: number = 0;
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder
  private emptyBuilder() {}

  private getBackgroundColor(): string {
    if (this.type === CardType.ELEVATED) {
      return this.isDarkMode ? '#2C2C2E' : '#FFFFFF';
    } else if (this.type === CardType.GLASS) {
      // 毛玻璃效果 - ArkUI标准实现
      // 浅色: 72%不透明白色 + backdropBlur(20)
      // 深色: 65%不透明深色 + backdropBlur(20)
      return this.isDarkMode ? 'rgba(30,30,32,0.65)' : 'rgba(255,255,255,0.72)';
    } else if (this.type === CardType.OUTLINED) {
      return 'rgba(0,0,0,0)'; // 完全透明
    }
    return this.isDarkMode ? '#1C1C1E' : '#FFFFFF';
  }

  private getBorderColor(): string {
    if (this.type === CardType.OUTLINED) {
      return this.isDarkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.08)';
    }
    if (this.type === CardType.GLASS) {
      // 毛玻璃边框 - 使用半透明白色
      return this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.5)';
    }
    return 'rgba(0,0,0,0)';
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.containerPadding)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(this.cornerRadius)
    .border({
      width: this.type === CardType.OUTLINED || this.type === CardType.GLASS ? 1 : 0,
      color: this.getBorderColor()
    })
    .shadow(this.type === CardType.ELEVATED ? {
      radius: 12,
      color: this.isDarkMode ? 'rgba(0,0,0,0.35)' : 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 4
    } : undefined)
    // 毛玻璃效果 - ArkUI标准实现
    .backdropBlur(this.type === CardType.GLASS ? 20 : 0)
    .margin({ bottom: this.marginBottom })
  }
}

// ============ 列表项组件 ============

export interface ListItemAction {
  icon?: string;
  text: string;
}

@Component
export struct CommonListItem {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop action: ListItemAction = {text: '', icon: ''};
  @Prop isDarkMode: boolean = false;
  @Prop showDivider: boolean = true;
  @Prop cornerRadius: number = 0;
  onListItemClick?: () => void;

  build() {
    Column() {
      Row({ space: 12 }) {
        if (this.icon) {
          Text(this.icon)
            .fontSize(20)
        }

        Column({ space: 4 }) {
          Text(this.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.action) {
          Row({ space: 4 }) {
            if (this.action.icon) {
              Text(this.action.icon)
                .fontSize(16)
            }
            Text(this.action.text)
              .fontSize(13)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
          }
        } else {
          Text('›')
            .fontSize(18)
            .fontColor(this.isDarkMode ? '#555555' : '#CCCCCC')
        }
      }
      .width('100%')
      .padding(16)
      .stateStyles({
        pressed: {
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
          .scale({ x: 0.99, y: 0.99 })
        },
        normal: {
          .backgroundColor('transparent')
          .scale({ x: 1, y: 1 })
        }
      })
      .onClick(() => {
        if (this.onListItemClick) {
          this.onListItemClick();
        }
      })

      if (this.showDivider) {
        Divider()
          .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
          .margin({ left: this.icon ? 48 : 16 })
      }
    }
    .width('100%')
    .borderRadius(this.cornerRadius)
  }
}

// ============ 空状态组件 ============

export enum EmptyStateType {
  DATA = 'data',
  NETWORK = 'network',
  SEARCH = 'search',
  CUSTOM = 'custom'
}

@Component
export struct EmptyState {
  @Prop type: EmptyStateType = EmptyStateType.DATA;
  @Prop title: string = '暂无数据';
  @Prop subtitle: string = '快去添加一些内容吧';
  @Prop icon: string = '📭';
  @Prop isDarkMode: boolean = false;
  @Prop showButton: boolean = false;
  @Prop buttonText: string = '立即添加';
  onButtonClick?: () => void;

  private getIcon(): string {
    if (this.type === EmptyStateType.NETWORK) return 'network';
    if (this.type === EmptyStateType.SEARCH) return 'magnifyingglass';
    return this.icon;
  }

  private getTitle(): string {
    if (this.type === EmptyStateType.NETWORK) return tr('network_error');
    if (this.type === EmptyStateType.SEARCH) return tr('no_result');
    return this.title;
  }

  private getSubtitle(): string {
    if (this.type === EmptyStateType.NETWORK) return tr('check_network_hint');
    if (this.type === EmptyStateType.SEARCH) return tr('no_results_hint');
    return this.subtitle;
  }

  build() {
    Column({ space: 12 }) {
      Text(this.getIcon())
        .fontSize(64)

      Text(this.getTitle())
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      Text(this.getSubtitle())
        .fontSize(13)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')

      if (this.showButton) {
        CommonButton({
          text: this.buttonText,
          type: ButtonType.PRIMARY,
          buttonSize: ButtonSize.MEDIUM,
          isEnabled: true,
          isDarkMode: this.isDarkMode,
          onButtonClick: (): void => {
            if (this.onButtonClick) {
              this.onButtonClick();
            }
          }
        })
        .width(200)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(40)
    .justifyContent(FlexAlign.Center)
  }
}

// ============ 加载骨架屏组件 ============

@Component
export struct SkeletonCard {
  @Prop isDarkMode: boolean = false;
  @Prop containerHeight: number = 120;

  build() {
    Column() {
      Row()
        .width('100%')
        .height(this.containerHeight)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)')
        .borderRadius(12)
    }
    .width('100%')
    .padding(16)
  }
}

@Component
export struct SkeletonList {
  @Prop isDarkMode: boolean = false;
  @Prop count: number = 5;

  build() {
    Column({ space: 0 }) {
      ForEach(this.generateArray(this.count), (item: number) => {
        SkeletonCard({ isDarkMode: this.isDarkMode })
      }, (item: number) => '' + item)
    }
    .width('100%')
  }

  private generateArray(count: number): number[] {
    const arr: number[] = [];
    for (let i = 0; i < count; i++) {
      arr.push(i);
    }
    return arr;
  }
}

// ============ 分割线组件 ============

@Component
export struct CommonDivider {
  @Prop isDarkMode: boolean = false;
  @Prop marginLeft: number = 16;
  @Prop marginRight: number = 16;
  @Prop vertical: boolean = false;
  @Prop containerHeight: number = 1;

  build() {
    Divider()
      .color(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)')
      .margin({
        left: this.marginLeft,
        right: this.marginRight
      })
  }
}

// ============ 标签组件 ============

export enum TagType {
  DEFAULT = 'default',
  PRIMARY = 'primary',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error'
}

@Component
export struct CommonTag {
  @Prop text: string = '';
  @Prop type: TagType = TagType.DEFAULT;
  @Prop isDarkMode: boolean = false;

  private getColors(): TagColorMap {
    const colors: TagColorMap = {
      bg: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
      text: this.isDarkMode ? '#AAAAAA' : '#666666'
    };

    if (this.type === TagType.PRIMARY) {
      colors.bg = 'rgba(0,125,255,0.1)';
      colors.text = '#007DFF';
    } else if (this.type === TagType.SUCCESS) {
      colors.bg = 'rgba(52,199,89,0.1)';
      colors.text = COMMON_COLORS.SUCCESS_GREEN;
    } else if (this.type === TagType.WARNING) {
      colors.bg = 'rgba(255,149,0,0.1)';
      colors.text = COMMON_COLORS.WARNING_ORANGE;
    } else if (this.type === TagType.ERROR) {
      colors.bg = 'rgba(255,59,48,0.1)';
      colors.text = COMMON_COLORS.ERROR_RED;
    }

    return colors;
  }

  build() {
    Text(this.text)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .backgroundColor(this.getColors().bg)
      .borderRadius(4)
      .fontColor(this.getColors().text)
  }
}

// ============ 进度条组件 ============

@Component
export struct CommonProgress {
  @Prop value: number = 0;
  @Prop total: number = 100;
  @Prop isDarkMode: boolean = false;
  @Prop showText: boolean = true;

  private calcPercent(): number {
    return Math.floor(this.value / this.total * 100);
  }

  build() {
    Column({ space: 6 }) {
      Progress({
        value: this.value,
        total: this.total
      })
        .width('100%')
        .height(6)
        .color('#007DFF')
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .borderRadius(3)

      if (this.showText && this.total > 0) {
        Text(this.calcPercent() + '%')
          .fontSize(11)
          .fontColor(this.isDarkMode ? '#888888' : '#999999')
          .textAlign(TextAlign.End)
          .width('100%')
      }
    }
    .width('100%')
  }
}

// ============ 图标组件 ============

export enum IconSize {
  SMALL = 16,
  MEDIUM = 20,
  LARGE = 24,
  XLARGE = 32
}

@Component
export struct CommonIcon {
  @Prop icon: string = '';
  @Prop iconSize: IconSize = IconSize.MEDIUM;
  @Prop color: string = '';
  @Prop isDarkMode: boolean = false;

  build() {
    Text(this.icon)
      .fontSize(this.iconSize)
      .fontColor(this.color || (this.isDarkMode ? '#FFFFFF' : '#1A1A1A'))
  }
}
