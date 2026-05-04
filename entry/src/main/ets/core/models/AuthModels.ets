// 华为账号登录模型
// Huawei Account Login Models

/**
 * 用户信息接口
 */
export interface UserInfo {
  userId: string;           // 用户ID
  displayName?: string;     // 显示名称
  avatarUri?: string;       // 头像URI
  accessToken: string;      // 访问令牌
  refreshToken?: string;    // 刷新令牌
  expiresInMillis: number;  // 过期时间戳
  loginType: LoginType;     // 登录类型
  loginTime: number;        // 登录时间戳
}

/**
 * 登录类型枚举
 */
export enum LoginType {
  HUAWEI = 'huawei',
  GUEST = 'guest'
}

/**
 * 登录状态枚举
 */
export enum LoginStatus {
  NOT_LOGGED = 'not_logged',
  LOGGED_IN = 'logged_in',
  EXPIRED = 'expired',
  GUEST = 'guest'
}

/**
 * 认证结果接口（包含授权码和用户数据）
 */
export interface AuthResult {
  authCode: string;
  uid: string;
  data?: UserData;
}

export interface UserData {
  displayName?: string;
  avatarUri?: string;
}

/**
 * 登录配置
 */
export interface LoginConfig {
  appId: string;
  scope: string;
  responseType: string;
}

export const HUAWEI_LOGIN_CONFIG: LoginConfig = {
  appId: '__YOUR_APP_ID__',
  scope: 'https://www.huawei.com/auth/account',
  responseType: 'code'
};

/**
 * 生成访客用户ID
 */
export function generateGuestId(): string {
  return 'guest_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

/**
 * 格式化过期时间显示
 */
export function formatExpiresTime(expiresInMillis: number): string {
  const date = new Date(Date.now() + expiresInMillis);
  return date.toLocaleString('zh-CN');
}
