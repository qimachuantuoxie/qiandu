/**
 * 华为 IAP 支付 UI 组件
 * 提供完整的支付界面和交互
 *
 * @since 2.6.0
 */

import { harmonyPayment, RewardOption, PaymentResult, PaymentStatus } from '../services/external/HarmonyPaymentService';
import { COMMON_COLORS } from '../utils/AppTheme';

/**
 * 支付结果回调
 */
export interface PaymentCallback {
  onSuccess: (result: PaymentResult) => void;
  onFailed: (result: PaymentResult) => void;
  onCancelled: () => void;
}

@CustomDialog
export struct PaymentDialog {
  @Prop isDarkMode: boolean = false;
  @Prop rewardOptions: RewardOption[] = [];
  @Prop selectedAmount: number = 0;
  private callback?: PaymentCallback;
  private controller: CustomDialogController;
  @State isProcessing: boolean = false;
  @State selectedProductId: string = '';

  aboutToAppear() {
    if (this.rewardOptions.length > 0 && this.selectedAmount === 0) {
      this.selectedAmount = this.rewardOptions[0].amount;
      this.selectedProductId = this.rewardOptions[0].productId;
    }
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('支持作者')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .layoutWeight(1)

        Text('✕')
          .fontSize(18)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
          .padding(8)
          .onClick(() => this.controller.close())
      }
      .width('100%')
      .padding({ bottom: 20 })

      // 说明文字
      Text('您的支持是我创作的最大动力！')
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .margin({ bottom: 20 })

      // 金额选择
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.rewardOptions, (option: RewardOption) => {
          Column({ space: 4 }) {
            Text(option.icon)
              .fontSize(32)

            Text(option.displayName)
              .fontSize(13)
              .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
              .fontWeight(FontWeight.Medium)

            Text('¥' + option.amount)
              .fontSize(16)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
              .fontWeight(FontWeight.Bold)
          }
          .width('30%')
          .padding(12)
          .backgroundColor(this.selectedProductId === option.productId
            ? (this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.1)')
            : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'))
          .border({
            width: 2,
            color: this.selectedProductId === option.productId
              ? COMMON_COLORS.PRIMARY_BLUE
              : 'transparent'
          })
          .borderRadius(12)
          .onClick(() => {
            this.selectedProductId = option.productId;
            this.selectedAmount = option.amount;
          })
        })
      }
      .width('100%')
      .margin({ bottom: 24 })

      // 支付按钮
      Button(this.isProcessing ? '处理中...' : '支付 ¥' + this.selectedAmount)
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(this.isProcessing
          ? (this.isDarkMode ? '#555555' : '#CCCCCC')
          : COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(25)
        .enabled(!this.isProcessing)
        .onClick(() => this.handlePayment())
    }
    .width('90%')
    .padding(24)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(20)
  }

  /**
   * 处理支付
   */
  private async handlePayment(): Promise<void> {
    if (this.isProcessing || !this.selectedProductId) {
      return;
    }

    this.isProcessing = true;

    try {
      const result = await harmonyPayment.createRewardOrder(
        this.selectedProductId,
        this.selectedAmount
      );

      if (result.success) {
        // 支付成功
        if (this.callback) {
          this.callback.onSuccess(result);
        }
        this.controller.close();
      } else if (result.status === PaymentStatus.CANCELLED) {
        // 用户取消
        if (this.callback) {
          this.callback.onCancelled();
        }
      } else {
        // 支付失败
        if (this.callback) {
          this.callback.onFailed(result);
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[PaymentDialog] Payment error:', message);
        this.callback.onFailed({
          success: false,
          status: PaymentStatus.FAILED,
          error: message
        });
      }
    } finally {
      this.isProcessing = false;
    }
  }
}
