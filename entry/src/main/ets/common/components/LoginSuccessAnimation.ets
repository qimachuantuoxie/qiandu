/**
 * 登录成功动画组件
 * Login Success Animation Component
 */

import { fontScaleManager } from '../utils/FontScaleManager';

@ComponentV2
export struct LoginSuccessAnimation {
  @Param isVisible: boolean = false;
  
  private animationController: AnimationController | null = null;
  
  aboutToAppear(): void {
    this.animationController = new AnimationController({
      duration: 1500,
      easing: 'ease-out',
      iterations: 1,
      fill: 'forwards'
    });
  }
  
  aboutToDisappear(): void {
    if (this.animationController) {
      this.animationController.cancel();
    }
  }

  build() {
    if (!this.isVisible) {
      Empty();
      return;
    }

    Column() {
      // 成功图标
      Column() {
        Text('✓')
          .fontSize(fontScaleManager.getScaledFontSize(60))
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Bold)
      }
      .width(100)
      .height(100)
      .borderRadius(50)
      .backgroundColor('rgba(76, 175, 80, 0.1)')
      .justifyContent(FlexAlign.Center)
      .animation({
        duration: 500,
        easing: 'ease-out',
        delay: 0
      })
      
      // 成功文字
      Text('登录成功')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 16 })
        .opacity(this.isVisible ? 1 : 0)
        .animation({
          duration: 300,
          easing: 'ease-in',
          delay: 300
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
