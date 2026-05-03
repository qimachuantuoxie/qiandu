import { router, promptAction } from '@kit.ArkUI';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { rewardViewModel, RewardViewModel, RewardItem } from '../viewmodels/RewardViewModel';

@Entry
@Component
struct RewardPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showSuccessDialog: boolean = false;
  @State showCustomInput: boolean = false;
  @State customAmount: number = 0;

  private vm: RewardViewModel = rewardViewModel;

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    await this.vm.init();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private async handleReward(): Promise<void> {
    if (!this.vm.selectedReward && !this.showCustomInput) {
      try { promptAction.showToast({ message: '请选择打赏金额', duration: 2000 }); } catch(e) { console.error('showToast error:', e); }
      return;
    }

    if (this.showCustomInput && this.customAmount <= 0) {
      try { promptAction.showToast({ message: '请输入有效金额', duration: 2000 }); } catch(e) { console.error('showToast error:', e); }
      return;
    }

    const success: boolean = await this.vm.processPayment();
    if (success) {
      this.showSuccessDialog = true;
    } else {
      try { promptAction.showToast({ message: '打赏失败，请重试', duration: 2000 }); } catch(e) { console.error('showToast error:', e); }
    }
  }

  @Builder
  buildRewardOption(item: RewardItem, isSelected: boolean) {
    Column({ space: 8 }) {
      Text(item.icon)
        .fontSize(32)
      Text(item.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#333333', '#FFFFFF'))
      Text(`¥${item.price}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.primary)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(isSelected ? this.currentColors.primary + '20' : this.bg('#FFFFFF', '#2C2C2E'))
    .border({
      width: 2,
      color: isSelected ? this.currentColors.primary : 'transparent'
    })
    .borderRadius(12)
    .onClick(() => {
      this.vm.selectReward(item);
      this.showCustomInput = false;
    })
  }

  @Builder
  buildSuccessDialog() {
    Column() {
      Column({ space: 20 }) {
        Text('🎉')
          .fontSize(64)
        Text('打赏成功')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))
        Text('感谢您的支持！')
          .fontSize(16)
          .fontColor(this.tc('#666666', '#AAAAAA'))
          .textAlign(TextAlign.Center)
        Button('知道了')
          .width('100%')
          .height(44)
          .backgroundColor(this.currentColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .borderRadius(12)
          .onClick(() => {
            this.showSuccessDialog = false;
            try { router.back(); } catch(e) { console.error('back error:', e); }
          })
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.showSuccessDialog = false; })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button() {
            Text('←')
              .fontSize(24)
              .fontColor(this.tc('#333333', '#FFFFFF'))
          }
          .width(40)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.5)')
          .borderRadius(20)
          .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })

          Text('打赏支持')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))

        Scroll() {
          Column({ space: 20 }) {
            Column({ space: 12 }) {
              Text('☕')
                .fontSize(64)
              Text('感谢您的支持')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tc('#333333', '#FFFFFF'))
              Text('您的打赏是我们持续更新的最大动力')
                .fontSize(14)
                .fontColor(this.tc('#666666', '#AAAAAA'))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 24, bottom: 16 })

            if (this.vm.totalRewards > 0) {
              Row({ space: 16 }) {
                Column() {
                  Text(this.vm.totalRewards.toString())
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.currentColors.primary)
                  Text('打赏次数')
                    .fontSize(12)
                    .fontColor(this.tc('#666666', '#AAAAAA'))
                }
                .layoutWeight(1)
                Column() {
                  Text(`¥${this.vm.totalRewardAmount}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4CAF50')
                  Text('打赏总额')
                    .fontSize(12)
                    .fontColor(this.tc('#666666', '#AAAAAA'))
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
              .borderRadius(12)
            }

            Column({ space: 12 }) {
              Text('选择打赏金额')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.tc('#333333', '#FFFFFF'))

              Grid() {
                ForEach(this.vm.rewardItems, (item: RewardItem) => {
                  GridItem() {
                    this.buildRewardOption(item, this.vm.selectedReward?.id === item.id)
                  }
                })
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(12)
              .rowsGap(12)
              .margin({ top: 8 })

              Row({ space: 12 }) {
                Text('自定义金额')
                  .fontSize(14)
                  .fontColor(this.tc('#666666', '#AAAAAA'))
                  .onClick(() => {
                    this.showCustomInput = !this.showCustomInput;
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
              .margin({ top: 8 })

              if (this.showCustomInput) {
                Column({ space: 12 }) {
                  TextInput({ placeholder: '输入金额', text: this.customAmount.toString() })
                    .type(InputType.Number)
                    .width('100%')
                    .height(44)
                    .backgroundColor(this.bg('#F5F5F5', '#3C3C3E'))
                    .onChange((value: string) => {
                      const num = parseInt(value, 10);
                      this.customAmount = isNaN(num) ? 0 : num;
                    })
                }
                .width('100%')
                .margin({ top: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
            .borderRadius(12)

            Column({ space: 12 }) {
              Text('打赏留言')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.tc('#333333', '#FFFFFF'))
              TextArea({ placeholder: '留下您的鼓励和建议...' })
                .width('100%')
                .height(80)
                .backgroundColor(this.bg('#F5F5F5', '#3C3C3E'))
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
            .borderRadius(12)

            Button(this.vm.isProcessing ? '处理中...' : '确认打赏')
              .width('100%')
              .height(50)
              .backgroundColor(this.vm.isProcessing ? '#CCCCCC' : this.currentColors.primary)
              .fontColor('#FFFFFF')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .borderRadius(25)
              .enabled(!this.vm.isProcessing)
              .onClick(() => { this.handleReward(); })

            Text('所有收益将用于应用开发和维护')
              .fontSize(12)
              .fontColor(this.tc('#999999', '#888888'))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#F5F5F5', '#141414'))

      if (this.showSuccessDialog) {
        this.buildSuccessDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}