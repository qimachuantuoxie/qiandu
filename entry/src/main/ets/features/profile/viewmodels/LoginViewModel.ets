/**
 * LoginPage ViewModel - V2鐗堟湰
 */
import { loginStateManager, UserInfo } from '../../../core/services/auth/LoginStateManager';
import { huaweiAuthService } from '../../../core/services/auth/HuaweiAuthService';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../../../core/utils/AppTheme';

@ObservedV2
export class LoginViewModel {
  @Trace username: string = '';
  @Trace password: string = '';
  @Trace rememberMe: boolean = false;
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace isDarkMode: boolean = false;
  @Trace currentColors: AppColors = themeManager.getColors();

  init(): void {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.loadRemembered();
  }

  private loadRemembered(): void {
    const saved = preferenceManager.getString('remembered_user', '');
    if (saved) {
      this.username = saved;
      this.rememberMe = true;
    }
  }

  setUsername(name: string): void {
    this.username = name;
  }

  setPassword(pwd: string): void {
    this.password = pwd;
  }

  setRememberMe(remember: boolean): void {
    this.rememberMe = remember;
  }

  async login(): Promise<boolean> {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMsg = '璇疯緭鍏ョ敤鎴峰悕鍜屽瘑鐮?;
      return false;
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      // TODO: 瀹炵幇瀹為檯鐨勭敤鎴峰悕瀵嗙爜鐧诲綍閫昏緫
      // 鐩墠浣跨敤妯℃嫙鐧诲綍
      const userInfo: UserInfo = {
        userId: 'user_' + Date.now(),
        username: this.username,
        loginTime: Date.now()
      };
      loginStateManager.loginSuccess(userInfo);
      
      if (this.rememberMe) {
        preferenceManager.setString('remembered_user', this.username);
      } else {
        preferenceManager.setString('remembered_user', '');
      }
      return true;
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '鐧诲綍澶辫触: ' + message;
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  async loginWithHuawei(): Promise<boolean> {
    this.isLoading = true;
    this.errorMsg = '';

    try {
      const result = await huaweiAuthService.login();
      if (result.success) {
        const userInfo: UserInfo = {
          userId: result.userId || 'huawei_' + Date.now(),
          username: result.userName || '鍗庝负鐢ㄦ埛',
          loginTime: Date.now()
        };
        loginStateManager.loginSuccess(userInfo);
        return true;
      } else {
        this.errorMsg = '鍗庝负鐧诲綍澶辫触';
        return false;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '鍗庝负鐧诲綍澶辫触: ' + message;
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  clearError(): void {
    this.errorMsg = '';
  }
}

export const loginViewModel = new LoginViewModel();
