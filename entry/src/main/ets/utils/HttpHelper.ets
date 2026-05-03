/**
 * HTTP Helper for API 22+
 * Ensures proper resource cleanup with finally block
 */
import { http } from '@kit.NetworkKit';

export interface HttpRequestOptions {
  url: string;
  method?: http.RequestMethod;
  header?: Record<string, string>;
  extraData?: string | object;
  connectTimeout?: number;
  readTimeout?: number;
}

export interface HttpResponse {
  code: number;
  result: string;
  header: Record<string, string>;
}

export class HttpHelper {
  private static instance: HttpHelper | null = null;

  static getInstance(): HttpHelper {
    if (!HttpHelper.instance) {
      HttpHelper.instance = new HttpHelper();
    }
    return HttpHelper.instance;
  }

  async request(options: HttpRequestOptions): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        options.url,
        {
          method: options.method || http.RequestMethod.GET,
          header: options.header,
          extraData: options.extraData,
          connectTimeout: options.connectTimeout || 30000,
          readTimeout: options.readTimeout || 30000
        }
      );

      const result = response.responseCode as number;
      const data = response.result as string;
      const headers = response.header as Record<string, string>;

      return {
        code: result,
        result: data,
        header: headers
      };
    } finally {
      // Always destroy to release resources
      httpRequest.destroy();
    }
  }

  async get(url: string, header?: Record<string, string>): Promise<HttpResponse> {
    return this.request({ url: url, method: http.RequestMethod.GET, header: header });
  }

  async post(url: string, extraData: string | object, header?: Record<string, string>): Promise<HttpResponse> {
    return this.request({
      url: url,
      method: http.RequestMethod.POST,
      header: header,
      extraData: extraData
    });
  }
}

export const httpHelper = HttpHelper.getInstance();

// Quick aliases
export async function httpGet(url: string, header?: Record<string, string>): Promise<HttpResponse> {
  return httpHelper.get(url, header);
}

export async function httpPost(url: string, data: string | object, header?: Record<string, string>): Promise<HttpResponse> {
  return httpHelper.post(url, data, header);
}