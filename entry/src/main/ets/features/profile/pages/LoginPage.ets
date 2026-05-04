import { logger } from '../../common/utils/Logger';
/**
 * LoginPage - Huawei Account Login Page
 *
 * Provides Huawei account authentication with privacy agreement,
 * loading overlay, and dark mode support.
 */
import { promptAction } from '@kit.ArkUI';
import { toast } from '../core/utils/ToastHelper';
import { huaweiAuthService } from '../core/services/auth/HuaweiAuthService';
import { loginStateManager } from '../core/services/auth/LoginStateManager';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
export struct LoginPage {
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isPrivacyAgreed: boolean = false;
  @State screenInfo: ScreenInfo | null = null;

  aboutToAppear(): void {
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private async handleHuaweiLogin(): Promise<void> {
    if (!this.isPrivacyAgreed) {
      this.errorMsg = '璇峰厛闃呰�骞跺悓鎰忕敤鎴峰崗璁�拰闅愮�鏀跨瓥';
      return;
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      const authResult = await huaweiAuthService.login();
      logger.info('[LoginPage] Get auth code success:', authResult.authorizationCode);

      const userProfile = await huaweiAuthService.getUserProfile(authResult.authorizationCode);

      const userId: string = userProfile.openId ? userProfile.openId : 'huawei_user_' + Date.now();
      const displayName: string = userProfile.displayName ? userProfile.displayName : '鍗庝负鐢ㄦ埛';

      loginStateManager.loginSuccess({
        userId: userId,
        username: displayName,
        nickname: displayName,
        avatar: userProfile.avatarUrl ? userProfile.avatarUrl : ''
        loginTime: Date.now(),
        token: authResult.authorizationCode
      });

      toast('娆㈣繋 ' + displayName, 2000);

      setTimeout((): void => {
        this.navigateToMain();
      }, 500);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      if (message.includes('cancel') || message.includes('鍙栨秷') || message.includes('1001')) {
      logger.info('[LoginPage] User cancelled login');
      } else {
        logger.error('[LoginPage] Huawei login error:', message);
        this.errorMsg = '鐧诲綍澶辫触锛岃�閲嶈瘯';
      }
    } finally {
      this.isLoading = false;
    }
  }

  private navigateToMain(): void {
    try {
      navigateTo.push('MainPage');
    } catch (err) {
      logger.error('[LoginPage] Navigation error:', JSON.stringify(err));
    }
  }

  build() {
    Stack() {
      Column() {
        this.BackgroundSection()

        Scroll() {
          Column({ space: 24 }) {
            this.HeaderSection()
            this.HuaweiLoginButton()
            this.PrivacyAgreementSection()
            this.ErrorMessageSection()
            this.LoginDescription()
          }
          .width('100%')
          .padding({ left: 32, right: 32, top: 48, bottom: 32 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentColors.background)

      if (this.isLoading) {
        this.LoadingOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BackgroundSection() {
    Column()
      .width('100%')
      .height(280)
      .linearGradient({
        angle: 180,
        colors: [
          [this.currentColors.primary, 0.0],
          [this.currentColors.primary, 0.3],
          [this.currentColors.background, 1.0]
        ]
      })
  }

  @Builder
  HeaderSection() {
    Column({ space: 12 }) {
      Text('鍗冭�闃呯晫')
        .fontSize(36 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.onPrimary)
        .textAlign(TextAlign.Center)

      Text('鎮ㄧ殑涓撲笟闃呰�鍔╂墜')
        .fontSize(16 * this.fontScale)
        .fontColor(this.currentColors.onPrimary)
        .opacity(0.8)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HuaweiLoginButton() {
    Button() {
      Row({ space: 8 }) {
        Text('H')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)

        Text('鍗庝负璐﹀彿鐧诲綍')
          .fontSize(18 * this.fontScale)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.onSurface)
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(52)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(BorderRadius.xl)
    .onClick(() => {
      this.handleHuaweiLogin();
    })
  }

  @Builder
  PrivacyAgreementSection() {
    Row({ space: 8 }) {
      Checkbox()
        .width(18)
        .height(18)
        .selectedColor(this.currentColors.primary)
        .onChange((isChecked: boolean): void => {
          this.isPrivacyAgreed = isChecked;
        })

      Text('宸查槄璇诲苟鍚屾剰 ')
        .fontSize(13 * this.fontScale)
        .fontColor(this.currentColors.onSurfaceVariant)

      Text('銆婄敤鎴峰崗璁�拰闅愮�鏀跨瓥锟?)
        .fontSize(13 * this.fontScale)
        .fontColor(this.currentColors.primary)
        .decoration({ type: TextDecorationType.Underline })
        .onClick(() => {
          logger.info('[LoginPage] Privacy policy link clicked');
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ErrorMessageSection() {
    if (this.errorMsg.length > 0) {
      Text(this.errorMsg)
        .fontSize(14 * this.fontScale)
        .fontColor(Color.Red)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 8, bottom: 4 })
    }
  }

  @Builder
  LoginDescription() {
    Text('鐧诲綍鍚庡彲鍚屾�闃呰�鏁版嵁锛岄殢鏃堕殢鍦扮户缁�槄锟?)
      .fontSize(14 * this.fontScale)
      .fontColor(this.currentColors.onSurfaceVariant)
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 16 })
  }

  @Builder
  LoadingOverlay() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .opacity(0.5)

      Column({ space: 16 }) {
        LoadingProgress()
          .width(50)
          .height(50)
          .color(this.currentColors.onSurface)

        Text('鐧诲綍锟?..')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.onSurface)
      }
      .padding(Spacing.xxl)
      .backgroundColor(this.currentColors.surface)
      .borderRadius(BorderRadius.md)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct LoginPagePreview {
  build() {
    Column() {
      Text('鐧诲綍锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      LoginPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鐧诲綍锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      LoginPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
