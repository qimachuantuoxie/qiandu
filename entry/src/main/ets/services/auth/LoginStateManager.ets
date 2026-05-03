/**
 * 登录状态管理服务
 * Login State Management Service
 */

import { preferenceManager } from '../../utils/PreferenceManager';

/**
 * 用户信息接口
 */
export interface UserInfo {
  userId: string;
  username: string;
  nickname?: string;
  avatar?: string;
  loginTime: number;
  token?: string;
}

/**
 * 登录状态管理器
 */
class LoginStateManager {
  private static instance: LoginStateManager;
  private currentUser: UserInfo | null = null;
  private listeners: Array<(isLoggedIn: boolean) => void> = [];

  /**
   * 初始化登录状态
   */
  init(): void {
    try {
      const isLoggedInStr = preferenceManager.getString('isLoggedIn', 'false');
      const isLoggedIn = isLoggedInStr === 'true';
      if (isLoggedIn) {
        const userId = preferenceManager.getString('userId', '');
        const username = preferenceManager.getString('username', '');
        const nickname = preferenceManager.getString('nickname', '');
        const loginTimeStr = preferenceManager.getString('loginTime', '0');
        const loginTime = parseInt(loginTimeStr, 10);
        const token = preferenceManager.getString('token', '');

        if (userId && username) {
          this.currentUser = {
            userId,
            username,
            nickname,
            loginTime,
            token
          };
        }
      }
    } catch (error) {
      const err = error as Error;
      console.error('[LoginStateManager] Init failed:', err.message);
    }
  }

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): LoginStateManager {
    if (!LoginStateManager.instance) {
      LoginStateManager.instance = new LoginStateManager();
    }
    return LoginStateManager.instance;
  }

  /**
   * 检查是否已登录
   */
  isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  /**
   * 获取当前用户信息
   */
  getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  /**
   * 登录成功
   */
  loginSuccess(userInfo: UserInfo): void {
    this.currentUser = userInfo;

    // 保存到本地存储
    preferenceManager.setString('isLoggedIn', 'true');
    preferenceManager.setString('userId', userInfo.userId);
    preferenceManager.setString('username', userInfo.username);
    preferenceManager.setString('nickname', userInfo.nickname || '');
    preferenceManager.setNumber('loginTime', userInfo.loginTime);
    if (userInfo.token) {
      preferenceManager.setString('token', userInfo.token);
    }

    // 閫氱煡鐩戝惉鍣?
    this.notifyListeners(true);
  }

  /**
   * 閫€鍑虹櫥褰?
   */
  logout(): void {
    this.currentUser = null;

    // 娓呴櫎鏈湴瀛樺偍
    preferenceManager.setString('isLoggedIn', 'false');
    preferenceManager.setString('userId', '');
    preferenceManager.setString('username', '');
    preferenceManager.setString('nickname', '');
    preferenceManager.setNumber('loginTime', 0);
    preferenceManager.setString('token', '');

    // 閫氱煡鐩戝惉鍣?
    this.notifyListeners(false);
  }

  /**
   * 鏇存柊鐢ㄦ埛淇℃伅
   */
  updateUserInfo(userInfo: Partial<UserInfo>): void {
    if (this.currentUser) {
      if (userInfo.userId !== undefined) {
        this.currentUser.userId = userInfo.userId;
      }
      if (userInfo.username !== undefined) {
        this.currentUser.username = userInfo.username;
      }
      if (userInfo.nickname !== undefined) {
        this.currentUser.nickname = userInfo.nickname;
      }
      if (userInfo.avatar !== undefined) {
        this.currentUser.avatar = userInfo.avatar;
      }
      if (userInfo.loginTime !== undefined) {
        this.currentUser.loginTime = userInfo.loginTime;
      }
      if (userInfo.token !== undefined) {
        this.currentUser.token = userInfo.token;
      }

      // 鏇存柊鏈湴瀛樺偍
      if (userInfo.nickname !== undefined) {
        preferenceManager.setString('nickname', userInfo.nickname);
      }
      if (userInfo.avatar !== undefined) {
        preferenceManager.setString('avatar', userInfo.avatar);
      }
      if (userInfo.token !== undefined) {
        preferenceManager.setString('token', userInfo.token);
      }
    }
  }

  /**
   * 娣诲姞鐩戝惉鍣?
   */
  addListener(listener: (isLoggedIn: boolean) => void): () => void {
    const newListeners = this.listeners.slice();
    newListeners.push(listener);
    this.listeners = newListeners;

    // 杩斿洖鍙栨秷璁㈤槄鍑芥暟
    return (): void => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        const newListeners = this.listeners.slice();
        newListeners.splice(index, 1);
        this.listeners = newListeners;
      }
    };
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(isLoggedIn: boolean): void {
    this.listeners.forEach((listener: (isLoggedIn: boolean) => void): void => {
      try {
        listener(isLoggedIn);
      } catch (error) {
        const err = error as Error;
        console.error('[LoginStateManager] Listener error:', err.message);
      }
    });
  }

  /**
   * 获取登录时间
   */
  getLoginTime(): number {
    if (this.currentUser === undefined || this.currentUser === null) {
      return 0;
    }
    if (this.currentUser.loginTime === undefined || this.currentUser.loginTime === null) {
      return 0;
    }
    return this.currentUser.loginTime;
  }

  /**
   * 检查登录是否过期（30天）
   */
  isLoginExpired(): boolean {
    if (!this.currentUser) {
      return true;
    }

    const thirtyDays = 30 * 24 * 60 * 60 * 1000;
    return Date.now() - this.currentUser.loginTime > thirtyDays;
  }

  /**
   * 刷新登录时间
   */
  refreshLoginTime(): void {
    if (this.currentUser) {
      this.currentUser.loginTime = Date.now();
      preferenceManager.setNumber('loginTime', Date.now());
    }
  }
}

// 导出单例
export const loginStateManager = LoginStateManager.getInstance();
export default loginStateManager;
