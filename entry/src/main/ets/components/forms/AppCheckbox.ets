/**
 * 统一复选框组件
 * 支持选中/未选中状态、自定义标签和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppCheckbox 组件属性
 */
@Component
export struct AppCheckbox {
  @Prop checked: boolean = false;
  @Prop label: string = '';
  @Prop disabled: boolean = false;
  @Prop isDarkMode: boolean = false;
  onChangeCallback?: (checked: boolean) => void;

  build() {
    Row({ space: 8 }) {
      Checkbox({ name: 'checkbox', group: 'checkboxGroup' })
        .select(this.checked)
        .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
        .enabled(!this.disabled)
        .onChange((isChecked: boolean) => {
          if (this.onChangeCallback) {
            this.onChangeCallback(isChecked);
          }
        })

      if (this.label && this.label.length > 0) {
        Text(this.label)
          .fontSize(14)
          .fontColor(this.disabled
            ? (this.isDarkMode ? '#555555' : '#CCCCCC')
            : (this.isDarkMode ? '#FFFFFF' : '#1A1A1A'))
      }
    }
  }
}
