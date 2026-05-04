/**
 * 统一返回按钮组件
 * 使用 SymbolGlyph 图标，支持深色/浅色主题
 */

import { goBack } from '../utils/NavigationHelper';

@Component
export struct BackButton {
  @Prop isDarkMode: boolean = false;
  @Prop colors: string = ''; // 可选：自定义颜色
  @Prop size: number = 40; // 按钮尺寸
  private onBack?: () => void;

  private getBgColor(): string {
    if (this.colors) {
      return this.colors;
    }
    return this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)';
  }

  private getIconColor(): string {
    return this.isDarkMode ? '#FFFFFF' : '#333333';
  }

  build() {
    Row() {
      Image($r('sys.symbol.chevron_left'))
        .width(20)
        .height(20)
        .fillColor(this.getIconColor())
    }
    .width(this.size)
    .height(this.size)
    .borderRadius(this.size / 2)
    .backgroundColor(this.getBgColor())
    .justifyContent(FlexAlign.Center)
    .onClick((): void => {
      if (this.onBack) {
        this.onBack();
      } else {
        try {
          goBack();
        } catch (e) {
          console.error('BackButton: goBack() failed:', e instanceof Error ? e.message : String(e));
        }
      }
    })
    .stateStyles({
      pressed: { .scale({ x: 0.9, y: 0.9 }) },
      normal: { .scale({ x: 1, y: 1 }) }
    })
  }
}
