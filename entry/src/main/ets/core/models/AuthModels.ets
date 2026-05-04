// 閸楀簼璐熺拹锕€褰块惂璇茬秿濡€崇€?
// Huawei Account Login Models

/**
 * 閻劍鍩涙穱鈩冧紖閹恒儱褰?
 */
export interface UserInfo {
  userId: string;           // 閻劍鍩?ID
  displayName?: string;     // 閺勫墽銇氶崥宥囆?
  avatarUri?: string;       // 婢舵潙鍎?URI
  accessToken: string;      // 鐠佸潡妫舵禒銈囧
  refreshToken?: string;    // 閸掗攱鏌婃禒銈囧
  expiresInMillis: number;  // 鏉╁洦婀￠弮鍫曟？閿涘牊顕犵粔鎺炵礆
  loginType: LoginType;     // 閻ц缍嶇猾璇茬€?
  loginTime: number;        // 閻ц缍嶉弮鍫曟？閹?
}

/**
 * 閻ц缍嶇猾璇茬€烽弸姘
 */
export enum LoginType {
  HUAWEI = 'huawei',
  GUEST = 'guest'
}

/**
 * 閻ц缍嶉悩鑸碘偓浣圭亣娑?
 */
export enum LoginStatus {
  NOT_LOGGED = 'not_logged',
  LOGGED_IN = 'logged_in',
  EXPIRED = 'expired',
  GUEST = 'guest'
}

/**
 * 閹哄牊娼堥崫宥呯安閹恒儱褰涢敍鍫濆磿娑撻缚澶勯崣鍑ょ礆
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
 * 閻ц缍嶉柊宥囩枂
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
 * 閻㈢喐鍨氬〒绋款吂閻劍鍩?ID
 */
export function generateGuestId(): string {
  return 'guest_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

/**
 * 閺嶇厧绱￠崠鏍箖閺堢喐妞傞梻?
 */
export function formatExpiresTime(expiresInMillis: number): string {
  const date = new Date(Date.now() + expiresInMillis);
  return date.toLocaleString('zh-CN');
}
