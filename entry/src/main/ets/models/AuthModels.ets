// 鍗庝负璐﹀彿鐧诲綍妯″瀷
// Huawei Account Login Models

/**
 * 鐢ㄦ埛淇℃伅鎺ュ彛
 */
export interface UserInfo {
  userId: string;           // 鐢ㄦ埛 ID
  displayName?: string;     // 鏄剧ず鍚嶇О
  avatarUri?: string;       // 澶村儚 URI
  accessToken: string;      // 璁块棶浠ょ墝
  refreshToken?: string;    // 鍒锋柊浠ょ墝
  expiresInMillis: number;  // 杩囨湡鏃堕棿锛堟绉掞級
  loginType: LoginType;     // 鐧诲綍绫诲瀷
  loginTime: number;        // 鐧诲綍鏃堕棿鎴?
}

/**
 * 鐧诲綍绫诲瀷鏋氫妇
 */
export enum LoginType {
  HUAWEI = 'huawei',
  GUEST = 'guest'
}

/**
 * 鐧诲綍鐘舵€佹灇涓?
 */
export enum LoginStatus {
  NOT_LOGGED = 'not_logged',
  LOGGED_IN = 'logged_in',
  EXPIRED = 'expired',
  GUEST = 'guest'
}

/**
 * 鎺堟潈鍝嶅簲鎺ュ彛锛堝崕涓鸿处鍙凤級
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
 * 鐧诲綍閰嶇疆
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
 * 鐢熸垚娓稿鐢ㄦ埛 ID
 */
export function generateGuestId(): string {
  return 'guest_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

/**
 * 鏍煎紡鍖栬繃鏈熸椂闂?
 */
export function formatExpiresTime(expiresInMillis: number): string {
  const date = new Date(Date.now() + expiresInMillis);
  return date.toLocaleString('zh-CN');
}
