/**
 * LoginPage ViewModel - V2版本
 */
import { loginStateManager, UserInfo } from '../services/auth/LoginStateManager';
import { huaweiAuthService } from '../services/auth/HuaweiAuthService';
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

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
      this.errorMsg = '请输入用户名和密码';
      return false;
    }

    this.isLoading = true;
    this.errorMsg = '';

    try {
      // TODO: 实现实际的用户名密码登录逻辑
      // 目前使用模拟登录
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
      this.errorMsg = '登录失败: ' + message;
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
          username: result.userName || '华为用户',
          loginTime: Date.now()
        };
        loginStateManager.loginSuccess(userInfo);
        return true;
      } else {
        this.errorMsg = '华为登录失败';
        return false;
      }
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '华为登录失败: ' + message;
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
