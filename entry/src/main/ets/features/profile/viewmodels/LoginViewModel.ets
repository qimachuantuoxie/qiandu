/**
 * LoginPage ViewModel - V2版本
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

  /**
   * 用户名密码登录（需要后端API支持）
   */
  async login(): Promise<boolean> {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMsg = '请输入用户名和密码';
      return false;
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      // TODO: 实现实际的用户名密码登录逻辑
      // 需要后端API支持，目前建议使用华为账号登录
      this.errorMsg = '请使用华为账号登录';
      return false;
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '登录失败: ' + err.message;
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 华为账号登录（真实实现）
   */
  async loginWithHuawei(): Promise<boolean> {
    this.isLoading = true;
    this.errorMsg = '';

    try {
      const result = await huaweiAuthService.login();
      
      if (result.success && result.userId) {
        const userInfo: UserInfo = {
          userId: result.userId,
          username: result.userName || '华为用户',
          nickname: result.displayName,
          avatar: result.avatarUrl,
          loginTime: Date.now(),
          token: result.authorizationCode
        };
        
        loginStateManager.loginSuccess(userInfo);
        
        if (this.rememberMe) {
          preferenceManager.setString('remembered_user', this.username);
        } else {
          preferenceManager.setString('remembered_user', '');
        }
        
        return true;
      } else {
        this.errorMsg = result.error || '华为登录失败';
        return false;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '华为登录失败: ' + err.message;
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
