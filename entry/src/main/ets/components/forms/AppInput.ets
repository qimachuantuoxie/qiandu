/**
 * 统一输入框组件
 * 支持多种类型、前后缀、验证和无障碍访问
 *
 * @since 3.0.0
 */

import { COMMON_COLORS } from '../../utils/AppTheme';

/**
 * AppInput 组件属性
 */
@Component
export struct AppInput {
  @Prop placeholder: string = '';
  @Prop value: string = '';
  @Prop type: 'text' | 'password' | 'number' | 'email' | 'phone' = 'text';
  @Prop disabled: boolean = false;
  @Prop prefix: string = '';
  @Prop suffix: string = '';
  @Prop maxLength: number = 1000;
  @Prop error: string = '';
  @Prop label: string = '';
  @Prop isDarkMode: boolean = false;
  onChangeCallback?: (value: string) => void;
  onSubmitCallback?: (value: string) => void;
  onFocusCallback?: () => void;
  onBlurCallback?: () => void;

  @State isFocused: boolean = false;
  @State inputText: string = '';

  aboutToAppear() {
    this.inputText = this.value;
  }

  /**
   * 根据状态获取边框颜色
   */
  private getBorderColor(): string {
    if (this.disabled) {
      return this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)';
    }
    if (this.error && this.error.length > 0) {
      return COMMON_COLORS.ERROR_RED;
    }
    if (this.isFocused) {
      return COMMON_COLORS.PRIMARY_BLUE;
    }
    return this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.15)';
  }

  /**
   * 获取背景颜色
   */
  private getBackgroundColor(): string {
    if (this.isFocused) {
      return this.isDarkMode ? '#1C1C1E' : '#FFFFFF';
    }
    return this.isDarkMode ? '#2C2C2E' : '#F5F5F5';
  }

  build() {
    Column({ space: 8 }) {
      // 标签
      if (this.label && this.label.length > 0) {
        Text(this.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .width('100%')
      }

      // 输入框容器
      Row() {
        // 前缀图标
        if (this.prefix && this.prefix.length > 0) {
          Text(this.prefix)
            .fontSize(18)
            .margin({ right: 8 })
        }

        // 输入框
        TextInput({ placeholder: this.placeholder, text: this.inputText })
          .type(this.getInputType())
          .placeholderColor(this.isDarkMode ? '#666666' : '#999999')
          .placeholderFont({ size: 14 })
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .fontSize(15)
          .height(44)
          .backgroundColor('rgba(0,0,0,0)')
          .enabled(!this.disabled)
          .maxLength(this.maxLength)
          .onChange((value: string) => {
            this.inputText = value;
            if (this.onChangeCallback) {
              this.onChangeCallback(value);
            }
          })
          .onSubmit((value: string) => {
            if (this.onSubmitCallback) {
              this.onSubmitCallback(value);
            }
          })
          .onFocus(() => {
            this.isFocused = true;
            if (this.onFocusCallback) {
              this.onFocusCallback();
            }
          })
          .onBlur(() => {
            this.isFocused = false;
            if (this.onBlurCallback) {
              this.onBlurCallback();
            }
          })
          .layoutWeight(1)

        // 后缀图标
        if (this.suffix && this.suffix.length > 0) {
          Text(this.suffix)
            .fontSize(18)
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(8)
      .border({
        width: 1.5,
        color: this.getBorderColor()
      })

      // 错误提示
      if (this.error && this.error.length > 0) {
        Text(this.error)
          .fontSize(12)
          .fontColor(COMMON_COLORS.ERROR_RED)
          .width('100%')
      }
    }
    .width('100%')
  }

  /**
   * 根据类型获取输入框类型
   */
  private getInputType(): InputType {
    switch (this.type) {
      case 'password': return InputType.Password;
      case 'number': return InputType.Number;
      case 'email': return InputType.Email;
      case 'phone': return InputType.Phone;
      default: return InputType.Text;
    }
  }
}
