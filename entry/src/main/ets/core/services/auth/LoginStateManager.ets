import { logger } from '../../../utils/Logger';
/**
 * 鐧诲綍鐘舵€佺�鐞嗘湇鍔?
 * Login State Management Service
 */

import { preferenceManager } from '../utils/PreferenceManager';

/**
 * 鐢ㄦ埛淇℃伅鎺ュ彛
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
 * 鐧诲綍鐘舵€佺�鐞嗗櫒
 */
class LoginStateManager {
  private static instance: LoginStateManager;
  private currentUser: UserInfo | null = null;
  private listeners: Array<(isLoggedIn: boolean) => void> = [];

  /**
   * 鍒濆�鍖栫櫥褰曠姸鎬?
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
      logger.error('[LoginStateManager] Init failed:', err.message);
    }
  }

  /**
   * 閼惧嘲褰囬崡鏇氱伐鐎圭偘绶?
   */
  static getInstance(): LoginStateManager {
    if (!LoginStateManager.instance) {
      LoginStateManager.instance = new LoginStateManager();
    }
    return LoginStateManager.instance;
  }

  /**
   * 妫€鏌ユ槸鍚﹀凡鐧诲綍
   */
  isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  /**
   * 鑾峰彇褰撳墠鐢ㄦ埛淇℃伅
   */
  getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  /**
   * 鐧诲綍鎴愬姛
   */
  loginSuccess(userInfo: UserInfo): void {
    this.currentUser = userInfo;

    // 淇濆瓨鍒版湰鍦板瓨鍌?
    preferenceManager.setString('isLoggedIn', 'true');
    preferenceManager.setString('userId', userInfo.userId);
    preferenceManager.setString('username', userInfo.username);
    preferenceManager.setString('nickname', userInfo.nickname || '');
    preferenceManager.setNumber('loginTime', userInfo.loginTime);
    if (userInfo.token) {
      preferenceManager.setString('token', userInfo.token);
    }

    // 闁�氨鐓￠惄鎴濇儔閸?
    this.notifyListeners(true);
  }

  /**
   * 闁�偓閸戣櫣娅ヨぐ?
   */
  logout(): void {
    this.currentUser = null;

    // 濞撳懘娅庨張顒€婀寸€涙ê鍋?
    preferenceManager.setString('isLoggedIn', 'false');
    preferenceManager.setString('userId', '');
    preferenceManager.setString('username', '');
    preferenceManager.setString('nickname', '');
    preferenceManager.setNumber('loginTime', 0);
    preferenceManager.setString('token', '');

    // 闁�氨鐓￠惄鎴濇儔閸?
    this.notifyListeners(false);
  }

  /**
   * 閺囧瓨鏌婇悽銊﹀煕娣団剝浼?
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

      // 閺囧瓨鏌婇張顒€婀寸€涙ê鍋?
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
   * 濞ｈ�濮為惄鎴濇儔閸?
   */
  addListener(listener: (isLoggedIn: boolean) => void): () => void {
    const newListeners = this.listeners.slice();
    newListeners.push(listener);
    this.listeners = newListeners;

    // 鏉╂柨娲栭崣鏍ㄧХ鐠併垽妲勯崙鑺ユ殶
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
   * 閫氱煡鎵€鏈夌洃鍚�櫒
   */
  private notifyListeners(isLoggedIn: boolean): void {
    this.listeners.forEach((listener: (isLoggedIn: boolean) => void): void => {
      try {
        listener(isLoggedIn);
      } catch (error) {
        const err = error as Error;
        logger.error('[LoginStateManager] Listener error:', err.message);
      }
    });
  }

  /**
   * 鑾峰彇鐧诲綍鏃堕棿
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
   * 妫€鏌ョ櫥褰曟槸鍚﹁繃鏈燂紙30澶╋級
   */
  isLoginExpired(): boolean {
    if (!this.currentUser) {
      return true;
    }

    const thirtyDays = 30 * 24 * 60 * 60 * 1000;
    return Date.now() - this.currentUser.loginTime > thirtyDays;
  }

  /**
   * 鍒锋柊鐧诲綍鏃堕棿
   */
  refreshLoginTime(): void {
    if (this.currentUser) {
      this.currentUser.loginTime = Date.now();
      preferenceManager.setNumber('loginTime', Date.now());
    }
  }
}

// 瀵煎嚭鍗曚緥
export const loginStateManager = LoginStateManager.getInstance();
export default loginStateManager;
