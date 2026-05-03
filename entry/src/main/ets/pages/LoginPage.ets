/**
 * LoginPage - Huawei Account Login Page
 *
 * Provides Huawei account authentication with privacy agreement,
 * loading overlay, and dark mode support.
 */
import { router } from '@kit.ArkUI';
import { toast } from '../utils/ToastHelper';
import { huaweiAuthService } from '../services/auth/HuaweiAuthService';
import { loginStateManager } from '../services/auth/LoginStateManager';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

@Entry
@Component
export struct LoginPage {
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isPrivacyAgreed: boolean = false;

  aboutToAppear(): void {
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private async handleHuaweiLogin(): Promise<void> {
    if (!this.isPrivacyAgreed) {
      this.errorMsg = '请先阅读并同意用户协议和隐私政策';
      return;
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      const authResult = await huaweiAuthService.login();
      console.info('[LoginPage] Get auth code success:', authResult.authorizationCode);

      const userProfile = await huaweiAuthService.getUserProfile(authResult.authorizationCode);

      const userId: string = userProfile.openId ?? 'huawei_user_' + Date.now();
      const displayName: string = userProfile.displayName ?? '华为用户';

      loginStateManager.loginSuccess({
        userId: userId,
        username: displayName,
        nickname: displayName,
        avatar: userProfile.avatarUrl ?? '',
        loginTime: Date.now(),
        token: authResult.authorizationCode
      });

      toast('欢迎 ' + displayName, 2000);

      setTimeout((): void => {
        this.navigateToMain();
      }, 500);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      if (message.includes('cancel') || message.includes('取消') || message.includes('1001')) {
        console.info('[LoginPage] User cancelled login');
      } else {
        console.error('[LoginPage] Huawei login error:', message);
        this.errorMsg = '登录失败，请重试';
      }
    } finally {
      this.isLoading = false;
    }
  }

  private navigateToMain(): void {
    try {
      router.pushUrl({ url: 'pages/MainPage' }, router.RouterMode.Standard);
    } catch (err) {
      console.error('[LoginPage] Navigation error:', JSON.stringify(err));
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
      Text('千读阅界')
        .fontSize(36 * this.fontScale)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.onPrimary)
        .textAlign(TextAlign.Center)

      Text('您的专业阅读助手')
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

        Text('华为账号登录')
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
    .borderRadius(26)
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

      Text('已阅读并同意 ')
        .fontSize(13 * this.fontScale)
        .fontColor(this.currentColors.onSurfaceVariant)

      Text('《用户协议和隐私政策》')
        .fontSize(13 * this.fontScale)
        .fontColor(this.currentColors.primary)
        .decoration({ type: TextDecorationType.Underline })
        .onClick(() => {
          console.info('[LoginPage] Privacy policy link clicked');
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
    Text('登录后可同步阅读数据，随时随地继续阅读')
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

        Text('登录中...')
          .fontSize(14 * this.fontScale)
          .fontColor(this.currentColors.onSurface)
      }
      .padding(24)
      .backgroundColor(this.currentColors.surface)
      .borderRadius(12)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
