import { logger } from '../../../utils/Logger';
/**
 * 缁熶竴缃戠粶璇锋眰鏈嶅姟
 * 鎷︽埅鍣ㄣ€乀oken 娉ㄥ叆銆侀噸璇曟満鍒躲€佸皝瑁?
 */
import { http } from '@kit.NetworkKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface HttpConfig {
  baseUrl: string;
  timeout: number;
  retryCount: number;
}

export class ApiService {
  private static instance: ApiService;
  private config: HttpConfig = {
    baseUrl: 'https://api.qianduyuejie.com/v1',
    timeout: 15000,
    retryCount: 2
  };
  private token: string = '';

  private constructor() {}

  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  async init(): Promise<void> {
    this.token = await preferenceManager.getValue('access_token', '');
  }

  async get<T>(url: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    let query = '';
    if (params) {
      const keys = Object.keys(params);
      const parts: string[] = [];
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        parts.push(k + '=' + params[k]);
      }
      query = '?' + parts.join('&');
    }
    return this.request<T>(http.RequestMethod.GET, this.config.baseUrl + url + query);
  }

  async post<T>(url: string, body?: Record<string, Object>): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.POST, this.config.baseUrl + url, body);
  }

  private async request<T>(method: http.RequestMethod, url: string, body?: Record<string, Object>): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    let retry = 0;

    while (retry <= this.config.retryCount) {
      try {
        const response = await httpRequest.request(url, {
          method: method,
          header: await this.getHeaders(),
          extraData: body ? JSON.stringify(body) : undefined,
          connectTimeout: this.config.timeout,
          readTimeout: this.config.timeout
        });

        if (response.responseCode !== 200) {
          throw new Error(`HTTP ${response.responseCode}`);
        }

        const result = JSON.parse(response.result as string) as ApiResponse<T>;
        
        if (result.code !== 0 && result.code !== 200) {
          throw new Error(result.message || '娑撴艾濮熷�鍌氱埗');
        }

        return result;
      } catch (e) {
        const err = e as Error;
        errorHandler.handle(err, { level: ErrorLevel.WARN, logConsole: false });
        retry++;
        logger.warn(`[ApiService] Retry ${retry}/${this.config.retryCount} for ${url}`);
        if (retry > this.config.retryCount) {
          logger.error(`[ApiService] ${url} failed after retries`);
          throw new Error('Request failed after retries');
        }
        await new Promise<void>(res => setTimeout(res, 1000 * retry));
      } finally {
        httpRequest.destroy();
      }
    }
    
    throw new Error('Unexpected request failure');
  }

  private async getHeaders(): Promise<Record<string, string>> {
    const token = this.token || await preferenceManager.getValue('access_token', '');
    return {
      'Content-Type': 'application/json',
      'Authorization': token ? `Bearer ${token}` : '',
      'Accept': 'application/json',
      'User-Agent': 'QianDuYueJie/6.0.0 HarmonyOS'
    };
  }

  updateToken(token: string): void {
    this.token = token;
  }

  setConfig(config: Partial<HttpConfig>): void {
    if (config.baseUrl) this.config.baseUrl = config.baseUrl;
    if (config.timeout) this.config.timeout = config.timeout;
    if (config.retryCount) this.config.retryCount = config.retryCount;
  }
}

export const apiService = ApiService.getInstance();
export default apiService;
