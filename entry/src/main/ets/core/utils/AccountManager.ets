import { logger } from '../../utils/Logger';
import { promptAction } from '@kit.ArkUI';
import { accountAuth } from '@kit.AccountKit';
import { UserInfo, LoginStatus, generateGuestId, LoginType } from '../models/AuthModels';
import { preferenceManager } from './PreferenceManager';
import { secureStorage } from './SecureStorage';
import { MS_PER_MINUTE, MS_PER_YEAR } from '../constants/TimeConstants';

export class AccountManager {
  private static instance: AccountManager;
  private currentUser: UserInfo | null = null;
  private status: LoginStatus = LoginStatus.NOT_LOGGED;
  private listeners: Array<(status: LoginStatus, user: UserInfo | null) => void> = [];
  private autoRefreshTimer: number = -1;

  private constructor() {}

  static getInstance(): AccountManager {
    if (!AccountManager.instance) {
      AccountManager.instance = new AccountManager();
    }
    return AccountManager.instance;
  }

  async init(): Promise<void> {
    try {
      const userJson = preferenceManager.getValue('user_info', 'null');

      if (userJson !== 'null' && userJson !== null) {
        let parsed: UserInfo | null = null;
        try {
          parsed = JSON.parse(userJson) as UserInfo;
        } catch (e) {
          logger.error('User info parse failed:', e);
        }
        if (parsed && parsed.expiresInMillis) {
          if (Date.now() > parsed.expiresInMillis) {
            this.status = LoginStatus.EXPIRED;
            this.currentUser = null;
            await this.logout();
          } else {
            this.currentUser = parsed;
            this.status = parsed.loginType === LoginType.GUEST
              ? LoginStatus.GUEST
              : LoginStatus.LOGGED_IN;
          }
        }
      }
    } catch (error) {
      logger.error('Init failed:', error);
    }
  }

  async loginWithHuawei(): Promise<boolean> {
    try {
      const authInstance = accountAuth.getAuthInstance();
      const signInResult = await authInstance.signIn({
        autoCreateUser: true,
        credentialInfo: { kind: 'hwid' }
      });

      const user = signInResult.getUser();
      const uid = user.getUid();

      const huaweiUser: UserInfo = {
        userId: uid,
        displayName: 'Huawei User',
        avatarUri: '',
        accessToken: uid,
        refreshToken: '',
        expiresInMillis: Date.now() + 3600000,
        loginType: LoginType.HUAWEI,
        loginTime: Date.now()
      };

      await this.setLoggedIn(huaweiUser);
      promptAction.showToast({ message: 'Login success' });
      return true;
    } catch (error) {
      logger.error('Huawei login failed:', error);
      return await this.loginAsGuest();
    }
  }

  async loginAsGuest(): Promise<boolean> {
    try {
      const guestUser: UserInfo = {
        userId: generateGuestId(),
        displayName: 'Guest User',
        avatarUri: '',
        accessToken: '',
        refreshToken: '',
        expiresInMillis: Date.now() + MS_PER_YEAR,
        loginType: 'guest',
        loginTime: Date.now()
      };

      await this.setLoggedIn(guestUser);
      return true;
    } catch (error) {
      logger.error('Guest login failed:', error);
      return false;
    }
  }

  async setLoggedIn(user: UserInfo): Promise<void> {
    this.currentUser = user;
    this.status = user.loginType === LoginType.GUEST
      ? LoginStatus.GUEST
      : LoginStatus.LOGGED_IN;

    if (user.accessToken) {
      await secureStorage.setString('access_token', user.accessToken);
    }

    await preferenceManager.setValue('user_info', JSON.stringify(user));
    this.notifyListeners();
  }

  async logout(): Promise<void> {
    this.currentUser = null;
    this.status = LoginStatus.NOT_LOGGED;

    await secureStorage.remove('access_token');
    await preferenceManager.deleteValue('user_info');

    this.notifyListeners();
  }

  async refreshToken(): Promise<boolean> {
    if (!this.currentUser || this.currentUser.loginType === LoginType.GUEST) {
      return false;
    }

    try {
      const timeUntilExpiry = this.currentUser.expiresInMillis - Date.now();

      if (timeUntilExpiry > 0) {
        this.currentUser.expiresInMillis = Date.now() + MS_PER_YEAR;
        await preferenceManager.setValue('user_info', JSON.stringify(this.currentUser));
        this.status = LoginStatus.LOGGED_IN;
        this.notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (error) {
      logger.error('Token refresh failed:', error);
      return false;
    }
  }

  startAutoRefresh(): void {
    if (!this.currentUser || this.currentUser.loginType === LoginType.GUEST) {
      return;
    }

    this.stopAutoRefresh();

    const checkInterval = 30 * MS_PER_MINUTE;
    const refreshThreshold = 5 * MS_PER_MINUTE;

    this.autoRefreshTimer = setInterval(async () => {
      if (!this.currentUser) {
        this.stopAutoRefresh();
        return;
      }

      const timeUntilExpiry = this.currentUser.expiresInMillis - Date.now();

      if (timeUntilExpiry > 0 && timeUntilExpiry < refreshThreshold) {
        await this.refreshToken();
      } else if (timeUntilExpiry <= 0) {
        await this.logout();
        this.stopAutoRefresh();
      }
    }, checkInterval);
  }

  stopAutoRefresh(): void {
    if (this.autoRefreshTimer !== -1) {
      clearInterval(this.autoRefreshTimer);
      this.autoRefreshTimer = -1;
    }
  }

  getLoginStatus(): LoginStatus {
    return this.status;
  }

  getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  isLoggedIn(): boolean {
    return this.status !== LoginStatus.NOT_LOGGED;
  }

  isHuaweiUser(): boolean {
    return this.status === LoginStatus.LOGGED_IN;
  }

  isGuest(): boolean {
    return this.status === LoginStatus.GUEST;
  }

  subscribe(listener: (status: LoginStatus, user: UserInfo | null) => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  private notifyListeners(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      try {
        this.listeners[i](this.status, this.currentUser);
      } catch (error) {
        logger.error('Listener callback error:', error);
      }
    }
  }

  getDisplayName(): string {
    if (!this.currentUser) {
      return 'Not logged in';
    }
    if (this.currentUser.displayName) {
      return this.currentUser.displayName;
    }
    return this.currentUser.loginType === LoginType.GUEST ? 'Guest User' : 'Huawei User';
  }

  getAvatarUri(): string | undefined {
    return this.currentUser?.avatarUri;
  }
}

export const accountManager = AccountManager.getInstance();