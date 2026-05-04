import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { rewardViewModel, RewardViewModel, RewardItem } from '../viewmodels/RewardViewModel';
import { BackButton } from '../components/common/BackButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct RewardPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showSuccessDialog: boolean = false;
  @State showCustomInput: boolean = false;
  @State customAmount: number = 0;
  @State screenInfo: ScreenInfo | null = null;

  private vm: RewardViewModel = rewardViewModel;

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
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
      try { promptAction.showToast({ message: '璇烽€夋嫨鎵撹祻閲戦�', duration: 2000 }); } catch(e) { logger.error('showToast error:', e); }
      return;
    }

    if (this.showCustomInput && this.customAmount <= 0) {
      try { promptAction.showToast({ message: '璇疯緭鍏ユ湁鏁堥噾锟?, duration: 2000 }); } catch(e) { logger.error('showToast error:', e); }
      return;
    }

    const success: boolean = await this.vm.processPayment();
    if (success) {
      this.showSuccessDialog = true;
    } else {
      try { promptAction.showToast({ message: '鎵撹祻澶辫触锛岃�閲嶈瘯', duration: 2000 }); } catch(e) { logger.error('showToast error:', e); }
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
      Text(`楼${item.price}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.primary)
    }
    .width('100%')
    .padding(Spacing.md)
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
        Text('馃帀')
          .fontSize(64)
        Text('鎵撹祻鎴愬姛')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))
        Text('鎰熻阿鎮ㄧ殑鏀�寔锟?)
          .fontSize(16)
          .fontColor(this.tc('#666666', '#AAAAAA'))
          .textAlign(TextAlign.Center)
        Button('鐭ラ亾锟?)
          .width('100%')
          .height(44)
          .backgroundColor(this.currentColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .borderRadius(12)
          .onClick(() => {
            this.showSuccessDialog = false;
            try { goBack(); } catch(e) { logger.error('back error:', e); }
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
          BackButton({ isDarkMode: this.isDarkMode })

          Text('鎵撹祻鏀�寔')
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
              Text('锟?)
                .fontSize(64)
              Text('鎰熻阿鎮ㄧ殑鏀�寔')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tc('#333333', '#FFFFFF'))
              Text('鎮ㄧ殑鎵撹祻鏄�垜浠�寔缁�洿鏂扮殑鏈€澶у姩锟?)
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
                  Text('鎵撹祻娆℃暟')
                    .fontSize(12)
                    .fontColor(this.tc('#666666', '#AAAAAA'))
                }
                .layoutWeight(1)
                Column() {
                  Text(`楼${this.vm.totalRewardAmount}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4CAF50')
                  Text('鎵撹祻鎬婚�')
                    .fontSize(12)
                    .fontColor(this.tc('#666666', '#AAAAAA'))
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(Spacing.lg)
              .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
              .borderRadius(12)
            }

            Column({ space: 12 }) {
              Text('閫夋嫨鎵撹祻閲戦�')
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
                Text('鑷�畾涔夐噾锟?)
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
                  TextInput({ placeholder: '杈撳叆閲戦�', text: this.customAmount.toString() })
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
            .padding(Spacing.lg)
            .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
            .borderRadius(12)

            Column({ space: 12 }) {
              Text('鎵撹祻鐣欒█')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.tc('#333333', '#FFFFFF'))
              TextArea({ placeholder: '鐣欎笅鎮ㄧ殑榧撳姳鍜屽缓锟?..' })
                .width('100%')
                .height(80)
                .backgroundColor(this.bg('#F5F5F5', '#3C3C3E'))
            }
            .width('100%')
            .padding(Spacing.lg)
            .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
            .borderRadius(12)

            Button(this.vm.isProcessing ? '澶勭悊锟?..' : '纭��鎵撹祻')
              .width('100%')
              .height(50)
              .backgroundColor(this.vm.isProcessing ? '#CCCCCC' : this.currentColors.primary)
              .fontColor('#FFFFFF')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .borderRadius(25)
              .enabled(!this.vm.isProcessing)
              .onClick(() => { this.handleReward(); })

            Text('鎵€鏈夋敹鐩婂皢鐢ㄤ簬搴旂敤寮€鍙戝拰缁存姢')
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

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct RewardPagePreview {
  build() {
    Column() {
      Text('鎵撹祻鏀�寔锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      RewardPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鎵撹祻鏀�寔锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      RewardPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}