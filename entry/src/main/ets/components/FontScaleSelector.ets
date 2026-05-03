/**
 * 字体大小选择器组件
 * Font Scale Selector Component
 */

import { fontScaleManager, FontScaleConfig } from '../utils/FontScaleManager';
import { COMMON_COLORS } from '../utils/AppTheme';

@Component
export struct FontScaleSelector {
  @State config: FontScaleConfig = fontScaleManager.getConfig();
  @Prop isDarkMode: boolean = false;
  onConfigChanged?: () => void;

  aboutToAppear() {
    this.config = fontScaleManager.getConfig();
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      Text('字体大小')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .width('100%')

      // 跟随系统开关
      Row() {
        Text('跟随系统')
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.config.followSystem })
          .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
          .onChange(async (isOn: boolean) => {
            await fontScaleManager.setFollowSystem(isOn);
            this.config = fontScaleManager.getConfig();
            if (this.onConfigChanged) this.onConfigChanged();
          })
      }

      // 自定义滑块（仅在不跟随系统时显示）
      if (!this.config.followSystem) {
        Column({ space: 8 }) {
          Text('自定义大小')
            .fontSize(14)
            .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')

          Row({ space: 12 }) {
            Text('小')
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')

            Slider({
              value: this.config.scale,
              min: 0.8,
              max: 1.5,
              step: 0.1
            })
              .layoutWeight(1)
              .showTips(true)
              .onChange(async (value: number) => {
                await fontScaleManager.setCustomScale(value);
                this.config = fontScaleManager.getConfig();
                if (this.onConfigChanged) this.onConfigChanged();
              })

            Text('大')
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
          }

          // 预览
          Column({ space: 8 }) {
            Text('预览文字')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

            Text('当前缩放: ' + (this.config.scale * 100).toFixed(0) + '%')
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
          .borderRadius(12)
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(16)
  }
}
