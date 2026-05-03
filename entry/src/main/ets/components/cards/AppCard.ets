
/**
 * 统一卡片组件
 * 支持阴影、边框、点击效果和无障碍访问
 *
 * @since 3.0.1
 */

import { TouchType } from '@kit.ArkUI';

/**
 * 阴影层级枚举
 */
export enum ElevationLevel {
  NONE = 'none',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

/**
 * AppCard 组件属性接口
 */
export interface AppCardType {
  content: () => void;
  elevation?: ElevationLevel;
  padding?: number;
  marginTop?: number;
  marginBottom?: number;
  marginLeft?: number;
  marginRight?: number;
  clickable?: boolean;
  isDarkMode?: boolean;
  onClickCallback?: () => void;
}

/**
 * AppCard 组件属性
 */
@Component
export struct AppCard {
  @BuilderParam content: () => void;
  @Prop elevation: ElevationLevel = ElevationLevel.MD;
  @Prop padding: number = 16;
  @Prop marginTop: number = 0;
  @Prop marginBottom: number = 0;
  @Prop marginLeft: number = 0;
  @Prop marginRight: number = 0;
  @Prop clickable: boolean = false;
  @Prop isDarkMode: boolean = false;
  onClickCallback?: () => void;

  @State isPressed: boolean = false;

  /**
   * 根据 elevation 获取阴影配置
   */
  private getShadowRadius(): number {
    switch (this.elevation) {
      case ElevationLevel.NONE: return 0;
      case ElevationLevel.SM: return 4;
      case ElevationLevel.MD: return 8;
      case ElevationLevel.LG: return 12;
      case ElevationLevel.XL: return 16;
      default: return 8;
    }
  }

  private getShadowColor(): string {
    if (this.elevation === ElevationLevel.NONE) {
      return 'rgba(0,0,0,0)';
    }
    switch (this.elevation) {
      case ElevationLevel.SM: return this.isDarkMode ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.08)';
      case ElevationLevel.MD: return this.isDarkMode ? 'rgba(0,0,0,0.25)' : 'rgba(0,0,0,0.12)';
      case ElevationLevel.LG: return this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.16)';
      case ElevationLevel.XL: return this.isDarkMode ? 'rgba(0,0,0,0.35)' : 'rgba(0,0,0,0.2)';
      default: return 'rgba(0,0,0,0)';
    }
  }

  private getShadowOffsetY(): number {
    switch (this.elevation) {
      case ElevationLevel.NONE: return 0;
      case ElevationLevel.SM: return 1;
      case ElevationLevel.MD: return 2;
      case ElevationLevel.LG: return 4;
      case ElevationLevel.XL: return 8;
      default: return 0;
    }
  }

  /**
   * 获取背景颜色
   */
  private getBackgroundColor(): string {
    if (this.isPressed && this.clickable) {
      return this.isDarkMode ? '#2C2C2E' : '#F0F0F0';
    }
    return this.isDarkMode ? '#1C1C1E' : '#FFFFFF';
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.padding)
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(12)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'
    })
    .shadow({
      radius: this.getShadowRadius(),
      color: this.getShadowColor(),
      offsetX: 0,
      offsetY: this.getShadowOffsetY()
    })
    .margin({
      top: this.marginTop,
      bottom: this.marginBottom,
      left: this.marginLeft,
      right: this.marginRight
    })
    .onClick(() => {
      if (this.clickable && this.onClickCallback) {
        this.onClickCallback();
      }
    })
    .onTouch((event: TouchEvent) => {
      if (this.clickable) {
        if (event.type === TouchType.Down) {
          this.isPressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      }
    })
  }
}
