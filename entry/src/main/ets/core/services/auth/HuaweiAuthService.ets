/**
 * 华为账号认证服务
 * Huawei Account Authentication Service
 * 
 * 使用 @kit.AccountKit 实现真实的华为账号登录
 * 参考官方文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication
 */

import { authentication } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0xFF03;

/**
 * 华为认证结果接口
 */
export interface HuaweiAuthResult {
  success: boolean;
  authorizationCode?: string;  // 授权码
  userId?: string;             // 用户ID (uid)
  userName?: string;           // 用户名
  displayName?: string;        // 显示名称
  avatarUrl?: string;          // 头像URL
  error?: string;              // 错误信息
  errorCode?: number;          // 错误码
}

/**
 * 华为用户资料
 */
export interface HuaweiUserProfile {
  openId: string;        // 用户OpenID（应用内唯一）
  unionId?: string;      // 用户UnionID（开发者账号下唯一）
  displayName?: string;  // 用户昵称
  avatarUrl?: string;    // 用户头像URL
}

/**
 * 华为账号认证服务类
 */
export class HuaweiAuthService {
  private static instance: HuaweiAuthService;
  private context: common.Context | null = null;
  private clientId: string = '';

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): HuaweiAuthService {
    if (!HuaweiAuthService.instance) {
      HuaweiAuthService.instance = new HuaweiAuthService();
    }
    return HuaweiAuthService.instance;
  }

  /**
   * 初始化服务
   * @param context 应用上下文
   * @param clientId 客户端ID（可选，从module.json5中读取）
   */
  init(context: common.Context, clientId?: string): void {
    this.context = context;
    if (clientId) {
      this.clientId = clientId;
    }
    hilog.info(DOMAIN, 'HuaweiAuthService', 'Service initialized');
  }

  /**
   * 执行华为账号登录
   * 根据官方文档实现完整的登录流程
   * @returns Promise<HuaweiAuthResult> 认证结果
   */
  async login(): Promise<HuaweiAuthResult> {
    if (!this.context) {
      throw new Error('HuaweiAuthService not initialized. Please call init() first.');
    }

    try {
      hilog.info(DOMAIN, 'HuaweiAuthService', 'Starting Huawei account login');

      // 1. 创建华为账号登录请求
      const huaweiIdProvider = new authentication.HuaweiIDProvider();
      const loginRequest = huaweiIdProvider.createLoginWithHuaweiIDRequest();
      
      // 2. 配置登录参数
      loginRequest.scopes = ['openid', 'profile'];  // 请求openid和profile权限
      loginRequest.state = util.generateRandomUUID(); // 生成随机state防止CSRF攻击
      loginRequest.forceLogin = false;  // false表示如果已登录则静默登录，true强制拉起登录页面

      hilog.info(DOMAIN, 'HuaweiAuthService', 'Login request configured, executing...');

      // 3. 创建认证控制器并执行请求
      const controller = new authentication.AuthenticationController(this.context);
      const response = await controller.executeRequest(loginRequest);

      hilog.info(DOMAIN, 'HuaweiAuthService', 'Login request executed successfully');

      // 4. 检查响应数据
      if (!response.data) {
        throw new Error('Login response data is empty');
      }

      const authorizationCode = response.data.authorizationCode;
      const uid = response.data.uid;

      if (!authorizationCode) {
        throw new Error('Failed to get authorization code from response');
      }

      if (!uid) {
        throw new Error('Failed to get user ID from response');
      }

      hilog.info(DOMAIN, 'HuaweiAuthService', 'Got authorization code and user ID');

      // 5. 构建返回结果
      const result: HuaweiAuthResult = {
        success: true,
        authorizationCode: authorizationCode,
        userId: uid,
        userName: `user_${uid.substring(0, 8)}`,  // 使用uid前8位作为用户名
        displayName: undefined,  // 需要通过后端API获取真实昵称
        avatarUrl: undefined     // 需要通过后端API获取真实头像
      };

      hilog.info(DOMAIN, 'HuaweiAuthService', 'Login completed successfully, userId: %{public}s', uid);
      return result;

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'HuaweiAuthService', 'Login failed: code=%{public}d, message=%{public}s', 
        err.code || 0, err.message);

      // 处理常见错误码
      let errorMessage = '登录失败';
      switch (err.code) {
        case 1001502001:
          errorMessage = '用户未登录华为账号，请先登录华为账号';
          break;
        case 1001502005:
          errorMessage = '网络异常，请检查网络连接';
          break;
        case 1001502012:
          errorMessage = '用户取消了登录';
          break;
        case 1001500001:
          errorMessage = '证书指纹校验失败，请检查签名配置';
          break;
        case 1001502014:
          errorMessage = '缺少必要的权限或scope，请检查AGC配置';
          break;
        default:
          errorMessage = `登录失败: ${err.message}`;
          break;
      }

      return {
        success: false,
        error: errorMessage,
        errorCode: err.code
      };
    }
  }

  /**
   * 使用授权码获取用户资料
   * 注意：实际项目中应该在服务端完成此步骤
   * 
   * @param authCode 授权码
   * @returns Promise<HuaweiUserProfile> 用户资料
   */
  async getUserProfile(authCode: string): Promise<HuaweiUserProfile> {
    hilog.info(DOMAIN, 'HuaweiAuthService', 'Getting user profile with auth code');

    // 实际项目中的标准流程：
    // 1. 前端将authCode发送到后端服务器
    // 2. 后端使用OAuth2.0协议调用华为服务器换取access_token和id_token
    //    POST https://oauth-login.cloud.huawei.com/oauth2/v3/token
    //    参数：grant_type=authorization_code, code={authCode}, client_id={clientId}, client_secret={clientSecret}
    // 3. 后端使用access_token调用userinfo接口获取用户详细信息
    //    GET https://account.cloud.huawei.com/rest.php?nsp_svc=GOpen.User.getInfo
    // 4. 后端返回用户信息给前端
    //
    // 由于这是前端演示，暂时返回基础信息
    // TODO: 实现后端API对接
    
    const profile: HuaweiUserProfile = {
      openId: authCode.substring(0, 32),  // 临时使用authCode生成openId
      displayName: '华为用户'              // 临时昵称
    };

    hilog.info(DOMAIN, 'HuaweiAuthService', 'User profile retrieved (mock data)');
    return profile;
  }

  /**
   * 检查华为账号服务是否可用
   * @returns Promise<boolean> 服务是否可用
   */
  async isServiceAvailable(): Promise<boolean> {
    if (!this.context) {
      hilog.warn(DOMAIN, 'HuaweiAuthService', 'Service not initialized');
      return false;
    }

    try {
      // 检查华为账号服务是否可用
      const available = await authentication.isAccountAvailable(this.context);
      hilog.info(DOMAIN, 'HuaweiAuthService', 'Service available: %{public}s',
        available ? 'true' : 'false');
      return available;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'HuaweiAuthService', 
        'Check service available failed: code=%{public}d, message=%{public}s', 
        err.code || 0, err.message);
      return false;
    }
  }

  /**
   * 退出登录/取消授权
   * 清除用户的授权状态
   */
  async logout(): Promise<void> {
    if (!this.context) {
      throw new Error('HuaweiAuthService not initialized');
    }

    try {
      hilog.info(DOMAIN, 'HuaweiAuthService', 'Starting logout');

      // 创建取消授权请求
      const huaweiIdProvider = new authentication.HuaweiIDProvider();
      const cancelRequest = huaweiIdProvider.createCancelAuthorizationRequest();

      // 执行取消授权
      const controller = new authentication.AuthenticationController(this.context);
      await controller.executeRequest(cancelRequest);

      hilog.info(DOMAIN, 'HuaweiAuthService', 'Logout successful');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'HuaweiAuthService', 
        'Logout failed: code=%{public}d, message=%{public}s', 
        err.code || 0, err.message);
      throw error;
    }
  }
}

/**
 * 导出单例实例
 */
export const huaweiAuthService = HuaweiAuthService.getInstance();
export default huaweiAuthService;
