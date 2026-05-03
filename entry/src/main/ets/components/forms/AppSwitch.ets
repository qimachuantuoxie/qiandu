/**
 * 统一开关组件
 * 支持启用/禁用状态、自定义颜色和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppSwitch 组件属性
 */
@Component
export struct AppSwitch {
  @Prop checked: boolean = false;
  @Prop disabled: boolean = false;
  @Prop activeColor: string = '';
  @Prop isDarkMode: boolean = false;
  onChangeCallback?: (checked: boolean) => void;

  /**
   * 获取开关颜色
   */
  private getSelectedColor(): string {
    if (this.activeColor && this.activeColor.length > 0) {
      return this.activeColor;
    }
    return COMMON_COLORS.PRIMARY_BLUE;
  }

  build() {
    Toggle({ type: ToggleType.Switch, isOn: this.checked })
      .selectedColor(this.getSelectedColor())
      .switchPointColor('#FFFFFF')
      .enabled(!this.disabled)
      .onChange((isOn: boolean) => {
        if (this.onChangeCallback) {
          this.onChangeCallback(isOn);
        }
      })
  }
}
