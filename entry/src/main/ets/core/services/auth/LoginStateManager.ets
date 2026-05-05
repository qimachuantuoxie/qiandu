import { logger } from '../../../utils/Logger';
/**
 * 登录状态管理服务
 * Login State Management Service
 */

import { preferenceManager } from '../utils/PreferenceManager';
import { secureStorage } from '../utils/SecureStorage';
import { MS_PER_MINUTE, MS_PER_HOUR, MS_PER_DAY } from '../../constants/TimeConstants';

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
  refreshToken?: string;      // 刷新Token
  expiresAt?: number;         // Token过期时间戳
}

/**
 * 登录状态管理器
 */
class LoginStateManager {
  private static instance: LoginStateManager;
  private currentUser: UserInfo | null = null;
  private listeners: Array<(isLoggedIn: boolean) => void> = [];
  private refreshTimer: number = -1;
  
  // Token管理配置
  private readonly TOKEN_REFRESH_THRESHOLD = 5 * MS_PER_MINUTE; // Token刷新阈值：5分钟
  private readonly SESSION_TIMEOUT = 30 * MS_PER_DAY;           // 会话超时：30天
  private readonly TOKEN_EXPIRY_TIME = MS_PER_HOUR;             // Token有效期：1小时

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
        const refreshToken = preferenceManager.getString('refreshToken', '');
        const expiresAtStr = preferenceManager.getString('tokenExpiresAt', '0');
        const expiresAt = parseInt(expiresAtStr, 10);

        if (userId && username) {
          // 检查会话是否过期（30天）
          if (Date.now() - loginTime > this.SESSION_TIMEOUT) {
            logger.info('[LoginStateManager] Session expired, logging out');
            this.logout();
            return;
          }

          this.currentUser = {
            userId,
            username,
            nickname,
            loginTime,
            token,
            refreshToken,
            expiresAt
          };

          // 启动Token自动刷新
          this.startAutoRefresh();
          
          logger.info('[LoginStateManager] User loaded:', username);
        }
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[LoginStateManager] Init failed:', err.message);
    }
  }

  /**
   * 获取单例实例
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
    // 设置Token过期时间
    if (!userInfo.expiresAt) {
      userInfo.expiresAt = Date.now() + this.TOKEN_EXPIRY_TIME;
    }

    this.currentUser = userInfo;

    // 保存到本地存储
    preferenceManager.setString('isLoggedIn', 'true');
    preferenceManager.setString('userId', userInfo.userId);
    preferenceManager.setString('username', userInfo.username);
    preferenceManager.setString('nickname', userInfo.nickname || '');
    preferenceManager.setNumber('loginTime', userInfo.loginTime);
    
    if (userInfo.token) {
      secureStorage.setString('access_token', userInfo.token);
      preferenceManager.setString('token', userInfo.token);
    }
    
    if (userInfo.refreshToken) {
      preferenceManager.setString('refreshToken', userInfo.refreshToken);
    }
    
    if (userInfo.expiresAt) {
      preferenceManager.setString('tokenExpiresAt', userInfo.expiresAt.toString());
    }

    // 启动Token自动刷新
    this.startAutoRefresh();

    // 通知监听器
    this.notifyListeners(true);
    
    logger.info('[LoginStateManager] User logged in:', userInfo.username);
  }

  /**
   * 退出登录
   */
  logout(): void {
    // 停止Token自动刷新
    this.stopAutoRefresh();
    
    this.currentUser = null;

    // 清除本地存储
    preferenceManager.setString('isLoggedIn', 'false');
    preferenceManager.setString('userId', '');
    preferenceManager.setString('username', '');
    preferenceManager.setString('nickname', '');
    preferenceManager.setNumber('loginTime', 0);
    preferenceManager.setString('token', '');
    preferenceManager.setString('refreshToken', '');
    preferenceManager.setString('tokenExpiresAt', '0');

    secureStorage.remove('access_token');

    // 通知监听器
    this.notifyListeners(false);
    
    logger.info('[LoginStateManager] User logged out');
  }

  /**
   * 更新用户信息
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

      // 更新本地存储
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
   * 添加状态监听器
   */
  addListener(listener: (isLoggedIn: boolean) => void): () => void {
    const newListeners = this.listeners.slice();
    newListeners.push(listener);
    this.listeners = newListeners;

    // 返回取消订阅函数
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
        logger.error('[LoginStateManager] Listener error:', err.message);
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

    const thirtyDays = 30 * MS_PER_DAY;
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

  /**
   * 启动Token自动刷新
   */
  private startAutoRefresh(): void {
    this.stopAutoRefresh();

    // 每30分钟检查一次Token状态
    const checkInterval = 30 * MS_PER_MINUTE;
    
    this.refreshTimer = setInterval(async () => {
      if (!this.currentUser) {
        this.stopAutoRefresh();
        return;
      }

      const timeUntilExpiry = (this.currentUser.expiresAt || 0) - Date.now();

      // Token即将过期（少于5分钟），则刷新
      if (timeUntilExpiry > 0 && timeUntilExpiry < this.TOKEN_REFRESH_THRESHOLD) {
        logger.info('[LoginStateManager] Token expiring soon, refreshing...');
        await this.refreshToken();
      } 
      // Token已过期，自动登出
      else if (timeUntilExpiry <= 0) {
        logger.warn('[LoginStateManager] Token expired, logging out');
        await this.logout();
      }
    }, checkInterval);

    logger.info('[LoginStateManager] Auto refresh started');
  }

  /**
   * 停止Token自动刷新
   */
  private stopAutoRefresh(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
      logger.info('[LoginStateManager] Auto refresh stopped');
    }
  }

  /**
   * 刷新Token
   * TODO: 实际项目中需要调用后端API刷新Token
   */
  async refreshToken(): Promise<boolean> {
    if (!this.currentUser || !this.currentUser.token) {
      return false;
    }

    try {
      logger.info('[LoginStateManager] Refreshing token...');
      
      // TODO: 实际项目中需要调用后端API
      // const response = await this.httpPost('/api/auth/refresh', { 
      //   refreshToken: this.currentUser.refreshToken 
      // });
      
      // 临时方案：延长当前Token有效期
      this.currentUser.expiresAt = Date.now() + this.TOKEN_EXPIRY_TIME;
      preferenceManager.setString('tokenExpiresAt', this.currentUser.expiresAt.toString());
      
      logger.info('[LoginStateManager] Token refreshed successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      logger.error('[LoginStateManager] Token refresh failed:', err.message);
      return false;
    }
  }

  /**
   * 获取Token
   */
  getToken(): string | undefined {
    return this.currentUser?.token;
  }

  /**
   * 检查Token是否即将过期
   */
  isTokenExpiringSoon(): boolean {
    if (!this.currentUser || !this.currentUser.expiresAt) {
      return true;
    }
    
    const timeUntilExpiry = this.currentUser.expiresAt - Date.now();
    return timeUntilExpiry <= this.TOKEN_REFRESH_THRESHOLD;
  }
}

// 导出单例
export const loginStateManager = LoginStateManager.getInstance();
export default loginStateManager;
