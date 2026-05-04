// 登录状态管理服务
import { preferenceManager } from '../utils/PreferenceManager';

export interface UserInfo {
  userId: string;
  username: string;
  nickname?: string;
  avatar?: string;
  loginTime: number;
  token?: string;
}

class LoginStateManager {
  private static instance: LoginStateManager;
  private currentUser: UserInfo | null = null;
  private listeners: Array<(isLoggedIn: boolean) => void> = [];

  // 初始化登录状态
  init(): void {
    const isLoggedIn = preferenceManager.get('isLoggedIn', false);
    if (isLoggedIn) {
      const userId = preferenceManager.get('userId', '');
      const username = preferenceManager.get('username', '');
      const nickname = preferenceManager.get('nickname', '');
      const loginTime = preferenceManager.get('loginTime', 0);
      const token = preferenceManager.get('token', '');

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
  }

  // 单例模式
  static getInstance(): LoginStateManager {
    if (!LoginStateManager.instance) {
      LoginStateManager.instance = new LoginStateManager();
    }
    return LoginStateManager.instance;
  }

  // 检查是否已登录
  isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  // 获取当前用户信息
  getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  // 登录成功
  loginSuccess(userInfo: UserInfo): void {
    this.currentUser = userInfo;
    
    // 保存到本地存储
    preferenceManager.set('isLoggedIn', true);
    preferenceManager.set('userId', userInfo.userId);
    preferenceManager.set('username', userInfo.username);
    preferenceManager.set('nickname', userInfo.nickname || '');
    preferenceManager.set('loginTime', userInfo.loginTime);
    if (userInfo.token) {
      preferenceManager.set('token', userInfo.token);
    }

    // 通知监听器
    this.notifyListeners(true);
  }

  // 退出登录
  logout(): void {
    this.currentUser = null;
    
    // 清除本地存储
    preferenceManager.set('isLoggedIn', false);
    preferenceManager.set('userId', '');
    preferenceManager.set('username', '');
    preferenceManager.set('nickname', '');
    preferenceManager.set('loginTime', 0);
    preferenceManager.set('token', '');

    // 通知监听器
    this.notifyListeners(false);
  }

  // 更新用户信息
  updateUserInfo(userInfo: Partial<UserInfo>): void {
    if (this.currentUser) {
      const updated = this.currentUser;
      if (userInfo.userId !== undefined) updated.userId = userInfo.userId;
      if (userInfo.username !== undefined) updated.username = userInfo.username;
      if (userInfo.nickname !== undefined) updated.nickname = userInfo.nickname;
      if (userInfo.avatar !== undefined) updated.avatar = userInfo.avatar;
      if (userInfo.loginTime !== undefined) updated.loginTime = userInfo.loginTime;
      if (userInfo.token !== undefined) updated.token = userInfo.token;
      this.currentUser = updated;

      // 更新本地存储
      if (userInfo.nickname !== undefined) {
        preferenceManager.set('nickname', userInfo.nickname);
      }
      if (userInfo.avatar !== undefined) {
        preferenceManager.set('avatar', userInfo.avatar);
      }
      if (userInfo.token !== undefined) {
        preferenceManager.set('token', userInfo.token);
      }
    }
  }

  // 添加监听器
  addListener(listener: (isLoggedIn: boolean) => void): () => void {
    const newListeners: Array<(isLoggedIn: boolean) => void> = [];
    for (let i = 0; i < this.listeners.length; i++) {
      newListeners.push(this.listeners[i]);
    }
    newListeners.push(listener);
    this.listeners = newListeners;

    // 返回取消订阅函数
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        const updatedListeners: Array<(isLoggedIn: boolean) => void> = [];
        for (let i = 0; i < this.listeners.length; i++) {
          if (i !== index) {
            updatedListeners.push(this.listeners[i]);
          }
        }
        this.listeners = updatedListeners;
      }
    };
  }

  // 通知所有监听器
  private notifyListeners(isLoggedIn: boolean): void {
    for (let i = 0; i < this.listeners.length; i++) {
      try {
        this.listeners[i](isLoggedIn);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error('Login state listener error:', message);
      }
    }
  }

  // 获取登录时间
  getLoginTime(): number {
    return this.currentUser !== null && this.currentUser !== undefined ? this.currentUser.loginTime : 0;
  }

  // 检查登录是否过期（可选，30天）
  isLoginExpired(): boolean {
    if (!this.currentUser) {
      return true;
    }
    
    const thirtyDays = 30 * 24 * 60 * 60 * 1000;
    return Date.now() - this.currentUser.loginTime > thirtyDays;
  }

  // 刷新登录时间
  refreshLoginTime(): void {
    if (this.currentUser) {
      this.currentUser.loginTime = Date.now();
      preferenceManager.set('loginTime', Date.now());
    }
  }
}

// 导出单例
export const loginStateManager = LoginStateManager.getInstance();
