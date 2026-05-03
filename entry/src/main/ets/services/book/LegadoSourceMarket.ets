/**
 * Legado Book Source Market Service - 楦胯挋鐗堜功婧愬競鍦烘湇鍔?
 *
 * 鍔熻兘锛?
 * - 鍦ㄧ嚎涔︽簮甯傚満娴忚
 * - 涔︽簮鍒嗙被鍜屾悳绱?
 * - 涔︽簮涓嬭浇鍜屽鍏?
 * - 涔︽簮璇勫垎鍜屾帓琛?
 * - 涔︽簮鍒嗕韩鍜屽鍑?
 *
 * @since 5.1.0
 */

import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import {
  BookSource,
  BookSourceType,
  SearchResult,
  SearchRule,
  BookInfoRule,
  ContentRule,
  TocRule,
  generateSourceId,
  validateBookSource
} from '../../models/BookSourceModel';

interface ImportResult {
  success: number;
  fail: number;
  sources: BookSource[];
}

interface ParseResult {
  success: boolean;
  fail: number;
  sources: BookSource[];
}

interface TestSourceResult {
  success: boolean;
  responseTime: number;
  searchResultCount: number;
  error?: string;
}

interface TestSourceBatchResult {
  total: number;
  success: number;
  failed: number;
  averageResponseTime: number;
}

export interface QueryParams {
  category?: SourceMarketCategory;
  sort?: SourceMarketSort;
  filter?: MarketFilter;
  page?: number;
  pageSize?: number;
}

/**
 * Legado瑙勫垯瀛楁绫诲瀷锛堢敤浜庡鍑猴級
 */
export interface LegadoRuleFields {
  bookSourceName?: string;
  bookSourceUrl?: string;
  bookSourceType?: number;
  enabled?: boolean;
  customOrder?: number;
  weight?: number;
  exploreUrl?: string;
  lastUpdateTime?: number;
}

/**
 * 涔︽簮甯傚満鍒嗙被
 */
export enum SourceMarketCategory {
  /** 鍏ㄩ儴 */
  ALL = 'all',
  /** 绮惧搧鎺ㄨ崘 */
  FEATURED = 'featured',
  /** 鐢烽 */
  MALE = 'male',
  /** 濂抽 */
  FEMALE = 'female',
  /** 婕敾 */
  COMIC = 'comic',
  /** 闊抽 */
  AUDIO = 'audio',
  /** 鑱氬悎 */
  AGGREGATE = 'aggregate'
}

/**
 * 涔︽簮甯傚満鎺掑簭
 */
export enum SourceMarketSort {
  /** 鎺ㄨ崘鎺掑簭 */
  RECOMMENDED = 'recommended',
  /** 涓嬭浇閲?*/
  DOWNLOADS = 'downloads',
  /** 璇勫垎 */
  RATING = 'rating',
  /** 鏇存柊鏃堕棿 */
  UPDATE_TIME = 'update_time',
  /** 涔︽簮鏁伴噺 */
  SOURCE_COUNT = 'source_count'
}

/**
 * 涔︽簮甯傚満椤?
 */
export interface SourceMarketItem {
  /** 甯傚満ID */
  marketId: string;
  /** 涔︽簮鍖呭悕绉?*/
  name: string;
  /** 鎻忚堪 */
  description: string;
  /** 浣滆€?*/
  author: string;
  /** 鍒嗙被 */
  category: SourceMarketCategory;
  /** 涔︽簮鏁伴噺 */
  sourceCount: number;
  /** 涓嬭浇閲?*/
  downloads: number;
  /** 璇勫垎 */
  rating: number;
  /** 璇勫垎浜烘暟 */
  ratingCount: number;
  /** 鍥炬爣URL */
  iconUrl: string;
  /** 涔︽簮JSON URL */
  sourceUrl: string;
  /** 璇︽儏椤礥RL */
  detailUrl?: string;
  /** 鏍囩 */
  tags: string[];
  /** 鏄惁瀹樻柟 */
  isOfficial: boolean;
  /** 鏇存柊鏃堕棿 */
  updateTime: number;
  /** 鍒涘缓鏃堕棿 */
  createTime: number;
  /** 鏄惁宸蹭笅杞?*/
  isDownloaded: boolean;
  /** 鏄惁闇€瑕乂IP */
  requiresVip: boolean;
  /** 棰勮涔︽簮鍒楄〃 */
  previewSources?: string[];
}

/**
 * 涔︽簮甯傚満绛涢€夋潯浠?
 */
export interface MarketFilter {
  /** 鍒嗙被 */
  category?: SourceMarketCategory;
  /** 鏍囩 */
  tag?: string;
  /** 鏄惁瀹樻柟 */
  isOfficial?: boolean;
  /** 鏄惁闇€瑕乂IP */
  requiresVip?: boolean;
}

/**
 * 涔︽簮甯傚満鏌ヨ缁撴灉
 */
export interface MarketQueryResult {
  /** 鎬绘暟 */
  total: number;
  /** 褰撳墠椤?*/
  page: number;
  /** 姣忛〉鏁伴噺 */
  pageSize: number;
  /** 鏁版嵁鍒楄〃 */
  items: SourceMarketItem[];
}

/**
 * 棰勮鍝嶅簲
 */
interface PreviewResponse {
  sources: BookSource[];
}

/**
 * 涓嬭浇鍝嶅簲
 */
interface DownloadResponse {
  sources: LegadoSourceRaw[];
}

/**
 * Legado瀵煎嚭婧愭牸寮?
 */
interface LegadoSourceExport {
  bookSourceName: string;
  bookSourceUrl: string;
  bookSourceType: number;
  enabled: boolean;
  customOrder: number;
  weight: number;
  exploreUrl?: string;
  ruleSearch?: LegadoRuleFields;
  ruleBookInfo?: LegadoRuleFields;
  ruleContent?: LegadoRuleFields;
  ruleToc?: LegadoRuleFields;
  lastUpdateTime: number;
}

export interface SourceStats {
  totalSources: number;
  totalDownloads: number;
  avgRating: number;
  officialCount: number;
}

/**
 * Legado 鍘熷涔︽簮鏍煎紡锛圝SON锛?
 */
export interface LegadoSourceRaw {
  bookSourceName?: string;
  bookSourceUrl?: string;
  bookSourceType?: number;
  enabled?: boolean;
  customOrder?: number;
  weight?: number;
  exploreUrl?: string;
  ruleSearch?: LegadoRuleFields;
  ruleBookInfo?: LegadoRuleFields;
  ruleContent?: LegadoRuleFields;
  ruleToc?: LegadoRuleFields;
  lastUpdateTime?: number;
}

/**
 * 缂撳瓨鏁版嵁鎺ュ彛
 */
interface CacheData<T> {
  data: T;
  time: number;
}

/**
 * 涔︽簮甯傚満鏈嶅姟绫?
 */
class LegadoSourceMarketService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: LegadoSourceMarketService;

  /** 涓婁笅鏂?*/
  private context: common.Context | null = null;

  /** API鍩虹URL */
  private baseUrl: string = 'https://api.legado-market.com';

  /** 缂撳瓨 */
  private cache: Map<string, CacheData<object>> = new Map();

  /** 缂撳瓨鏈夋晥鏈燂紙5鍒嗛挓锛?*/
  private cacheTTL: number = 5 * 60 * 1000;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): LegadoSourceMarketService {
    if (!LegadoSourceMarketService.instance) {
      LegadoSourceMarketService.instance = new LegadoSourceMarketService();
    }
    return LegadoSourceMarketService.instance;
  }

  /**
   * 鍒濆鍖栨湇鍔?
   */
  async init(context: common.Context, baseUrl?: string): Promise<boolean> {
    try {
      console.info('[SourceMarket] Initializing...');
      this.context = context;
      if (baseUrl) {
        this.baseUrl = baseUrl;
      }
      console.info('[SourceMarket] Initialized, baseUrl:', this.baseUrl);
      return true;
    } catch (error) {
      console.error('[SourceMarket] Init failed:', error);
      return false;
    }
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?
   */
  isReady(): boolean {
    return this.context !== null;
  }

  // ==================== 涔︽簮甯傚満娴忚 ====================

  /**
   * 鑾峰彇鎺ㄨ崘涔︽簮鍖?
   */
  async getFeaturedSources(page: number = 1, pageSize: number = 20): Promise<MarketQueryResult> {
    try {
      const params: QueryParams = {
        category: SourceMarketCategory.FEATURED,
        sort: SourceMarketSort.RECOMMENDED,
        page: page,
        pageSize: pageSize
      };
      return await this.querySources(params);
    } catch (error) {
      console.error('[SourceMarket] Get featured sources failed:', error);
      const result: MarketQueryResult = { total: 0, page: page, pageSize: pageSize, items: [] };
      return result;
    }
  }

  /**
   * 鑾峰彇鐑棬涔︽簮鍖咃紙鎸変笅杞介噺锛?
   */
  async getPopularSources(page: number = 1, pageSize: number = 20): Promise<MarketQueryResult> {
    try {
      return await this.querySources({
        sort: SourceMarketSort.DOWNLOADS,
        page,
        pageSize
      });
    } catch (error) {
      console.error('[SourceMarket] Get popular sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 鑾峰彇楂樿瘎鍒嗕功婧愬寘
   */
  async getTopRatedSources(page: number = 1, pageSize: number = 20): Promise<MarketQueryResult> {
    try {
      return await this.querySources({
        sort: SourceMarketSort.RATING,
        page,
        pageSize
      });
    } catch (error) {
      console.error('[SourceMarket] Get top rated sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 鏍规嵁鍒嗙被鑾峰彇涔︽簮鍖?
   */
  async getSourcesByCategory(
    category: SourceMarketCategory,
    page: number = 1,
    pageSize: number = 20
  ): Promise<MarketQueryResult> {
    try {
      return await this.querySources({
        category,
        page,
        pageSize
      });
    } catch (error) {
      console.error('[SourceMarket] Get sources by category failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 鎼滅储涔︽簮鍖?
   */
  async searchSources(
    keyword: string,
    page: number = 1,
    pageSize: number = 20
  ): Promise<MarketQueryResult> {
    try {
      console.info('[SourceMarket] Searching:', keyword);

      const cacheKey = 'search:' + keyword + ':' + page + ':' + pageSize;
      const cached = this.getCached<MarketQueryResult>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = this.baseUrl + '/api/market/search?keyword=' + encodeURIComponent(keyword) + '&page=' + page + '&pageSize=' + pageSize;

      const result = await this.httpGet<MarketQueryResult>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || { total: 0, page, pageSize, items: [] };
    } catch (error) {
      console.error('[SourceMarket] Search sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 鏌ヨ涔︽簮鍖咃紙閫氱敤锛?
   */
  async querySources(params: QueryParams): Promise<MarketQueryResult> {
    try {
      const category = params.category;
      const sort = params.sort || SourceMarketSort.RECOMMENDED;
      const filter = params.filter;
      const page = params.page || 1;
      const pageSize = params.pageSize || 20;

      const cacheKey = `query:${JSON.stringify(params)}`;
      const cached = this.getCached<MarketQueryResult>(cacheKey);
      if (cached) {
        return cached;
      }

      // 鏋勫缓鏌ヨ鍙傛暟
      let queryParams = '';
      if (category) queryParams += `&category=${category}`;
      if (sort) queryParams += `&sort=${sort}`;
      queryParams += `&page=${page}&pageSize=${pageSize}`;

      if (filter) {
        if (filter.isOfficial !== undefined) {
          queryParams += `&isOfficial=${filter.isOfficial}`;
        }
        if (filter.tag) {
          queryParams += `&tag=${filter.tag}`;
        }
      }

      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/sources?${queryParams}`;

      const result = await this.httpGet<MarketQueryResult>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || { total: 0, page, pageSize, items: [] };
    } catch (error) {
      console.error('[SourceMarket] Query sources failed:', error);
      return { total: 0, page: params.page || 1, pageSize: params.pageSize || 20, items: [] };
    }
  }

  // ==================== 涔︽簮鍖呰鎯?====================

  /**
   * 鑾峰彇涔︽簮鍖呰鎯?
   */
  async getSourceMarketDetail(marketId: string): Promise<SourceMarketItem | null> {
    try {
      const cacheKey = `detail:${marketId}`;
      const cached = this.getCached<SourceMarketItem>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/sources/${marketId}`;

      const result = await this.httpGet<SourceMarketItem>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result;
    } catch (error) {
      console.error('[SourceMarket] Get source detail failed:', error);
      return null;
    }
  }

  /**
   * 棰勮涔︽簮鍖呭唴瀹?
   */
  async previewSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/sources/${marketId}/preview`;

      const response = await this.httpGet<PreviewResponse>(url);

      if (response && response.sources) {
        // 鐩存帴杩斿洖BookSource鏁扮粍
        return response.sources;
      }

      return null;
    } catch (error) {
      console.error('[SourceMarket] Preview source package failed:', error);
      return null;
    }
  }

  // ==================== 涓嬭浇鍜屽鍏?====================

  /**
   * 涓嬭浇涔︽簮鍖?
   */
  async downloadSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      console.info('[SourceMarket] Downloading source package:', marketId);

      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/sources/${marketId}/download`;

      const response = await this.httpGet<DownloadResponse>(url);

      if (response && response.sources) {
        // 杞崲鏍煎紡
        const sources = this.convertLegadoSources(response.sources);

        // 淇濆瓨涓嬭浇璁板綍
        await this.saveDownloadRecord(marketId);

        return sources;
      }

      return null;
    } catch (error) {
      console.error('[SourceMarket] Download source package failed:', error);
      return null;
    }
  }

  /**
   * 浠嶶RL瀵煎叆涔︽簮鍖咃紙Legado鏍煎紡锛?
   */
  async importFromUrl(url: string): Promise<ImportResult> {
    const httpRequest = http.createHttp();

    try {
      console.info('[SourceMarket] Importing from URL:', url);

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (HarmonyOS; LegadoMarket) AppleWebKit/537.36'
        },
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200 && response.result) {
        const content = response.result as string;
        const sources = this.parseAndConvertSources(content);

        const result: ImportResult = {
          success: sources.length,
          fail: 0,
          sources: sources
        };
        return result;
      } else {
        const result: ImportResult = {
          success: 0,
          fail: 0,
          sources: []
        };
        return result;
      }
    } catch (error) {
      console.error('[SourceMarket] Import from URL failed:', error);
      const result: ImportResult = {
        success: 0,
        fail: 0,
        sources: []
      };
      return result;
    } finally {
      // 閲婃斁HTTP璧勬簮
      httpRequest.destroy();
    }
  }

  /**
   * 瑙ｆ瀽骞惰浆鎹功婧?
   */
  parseAndConvertSources(jsonContent: string): BookSource[] {
    try {
      let legadoSources: LegadoSourceRaw[] = [];
      const content = jsonContent.trim();

      // 灏濊瘯瑙ｆ瀽JSON
      if (content.startsWith('[')) {
        legadoSources = JSON.parse(content) as LegadoSourceRaw[];
      } else if (content.startsWith('{')) {
        legadoSources = [JSON.parse(content) as LegadoSourceRaw];
      }

      return this.convertLegadoSources(legadoSources);
    } catch (error) {
      console.error('[SourceMarket] Parse and convert failed:', error);
      return [];
    }
  }

  /**
   * 杞崲Legado鏍煎紡涓哄唴閮ㄦ牸寮?
   */
  private convertLegadoSources(legadoSources: LegadoSourceRaw[]): BookSource[] {
    return legadoSources
      .filter(source => source.bookSourceName && source.bookSourceUrl)
      .map(source => {
        const bookSource: BookSource = {
          id: generateSourceId(),
          name: source.bookSourceName || '未命名书源',
          url: source.bookSourceUrl || '',
          enabled: source.enabled !== false,
          priority: source.customOrder || 1,
          weight: source.weight || 0,
          bookSourceType: this.convertSourceType(source.bookSourceType || 0),
          loginRequired: false,
          exploreUrl: source.exploreUrl,
          createTime: Date.now(),
          lastUpdateTime: source.lastUpdateTime || Date.now()
        };

        // Assign optional fields if they exist and are objects
        if (source.ruleSearch) bookSource.ruleSearch = source.ruleSearch as SearchRule;
        if (source.ruleBookInfo) bookSource.ruleBookInfo = source.ruleBookInfo as BookInfoRule;
        if (source.ruleContent) bookSource.ruleContent = source.ruleContent as ContentRule;
        if (source.ruleToc) bookSource.ruleToc = source.ruleToc as TocRule;

        return bookSource;
      });
  }

  /**
   * 杞崲涔︽簮绫诲瀷
   */
  private convertSourceType(type: number): BookSourceType {
    switch (type) {
      case 0:
        return BookSourceType.TEXT;
      case 1:
        return BookSourceType.AUDIO;
      case 2:
        return BookSourceType.IMAGE;
      default:
        return BookSourceType.TEXT;
    }
  }

  // ==================== 涔︽簮娴嬭瘯 ====================

  /**
   * 娴嬭瘯涔︽簮
   */
  async testSource(source: BookSource, testKeyword: string = '娴嬭瘯'): Promise<TestSourceResult> {
    try {
      console.info('[SourceMarket] Testing source:', source.name);
      const startTime = Date.now();

      // TODO: 瀹炵幇鐪熷疄鐨勪功婧愭祴璇曢€昏緫
      // 1. 娴嬭瘯鎼滅储鍔熻兘
      // 2. 娴嬭瘯涔︾睄璇︽儏
      // 3. 娴嬭瘯绔犺妭鍒楄〃
      // 4. 娴嬭瘯鍐呭鑾峰彇

      const responseTime = Date.now() - startTime;

      return {
        success: true,
        responseTime,
        searchResultCount: 10 // 妯℃嫙鏁版嵁
      };
    } catch (error) {
      console.error('[SourceMarket] Test source failed:', error);
      const err = error as Error;
      return {
        success: false,
        responseTime: 0,
        searchResultCount: 0,
        error: err.message
      };
    }
  }

  /**
   * 鎵归噺娴嬭瘯涔︽簮
   */
  async testSourcesBatch(sources: BookSource[]): Promise<TestSourceBatchResult> {
    try {
      console.info('[SourceMarket] Testing', sources.length, 'sources...');

      let successCount = 0;
      let failedCount = 0;
      let totalResponseTime = 0;

      for (const source of sources) {
        const result = await this.testSource(source);

        if (result.success) {
          successCount++;
          totalResponseTime += result.responseTime;
        } else {
          failedCount++;
        }
      }

      const averageResponseTime = successCount > 0
        ? Math.round(totalResponseTime / successCount)
        : 0;

      return {
        total: sources.length,
        success: successCount,
        failed: failedCount,
        averageResponseTime
      };
    } catch (error) {
      console.error('[SourceMarket] Test sources batch failed:', error);
      return {
        total: sources.length,
        success: 0,
        failed: sources.length,
        averageResponseTime: 0
      };
    }
  }

  // ==================== 涔︽簮鍒嗕韩鍜屽鍑?====================

  /**
   * 瀵煎嚭涔︽簮涓篔SON
   */
  exportSourcesToJson(sources: BookSource[]): string {
    try {
      // 杞崲涓篖egado鏍煎紡
      const legadoSources: LegadoSourceExport[] = [];
      for (let i = 0; i < sources.length; i++) {
        const source = sources[i];
        const legadoSource: LegadoSourceExport = {
          bookSourceName: source.name,
          bookSourceUrl: source.url,
          bookSourceType: source.bookSourceType === BookSourceType.TEXT ? 0 :
                          source.bookSourceType === BookSourceType.AUDIO ? 1 : 2,
          enabled: source.enabled,
          customOrder: source.priority,
          weight: source.weight,
          exploreUrl: source.exploreUrl,
          ruleSearch: source.ruleSearch as LegadoRuleFields,
          ruleBookInfo: source.ruleBookInfo as LegadoRuleFields,
          ruleContent: source.ruleContent as LegadoRuleFields,
          ruleToc: source.ruleToc as LegadoRuleFields,
          lastUpdateTime: source.lastUpdateTime || 0
        };
        legadoSources.push(legadoSource);
      }

      return JSON.stringify(legadoSources, null, 2);
    } catch (error) {
      console.error('[SourceMarket] Export to JSON failed:', error);
      return '';
    }
  }

  /**
   * 鐢熸垚瀵煎叆URL锛圠egado URL Scheme锛?
   */
  generateImportUrl(jsonContent: string): string {
    const encoded = encodeURIComponent(jsonContent);
    return `legado://import/bookSource?src=${encoded}`;
  }

  /**
   * 鐢熸垚鍒嗕韩閾炬帴
   */
  generateShareUrl(marketId: string): string {
    return `${this.baseUrl}/share/${marketId}`;
  }

  // ==================== 缁熻鍜屾帓琛?====================

  /**
   * 鑾峰彇涔︽簮鎺掕姒?
   */
  async getSourceRanking(type: 'downloads' | 'rating' | 'update', limit: number = 50): Promise<SourceMarketItem[]> {
    try {
      const cacheKey = `ranking:${type}:${limit}`;
      const cached = this.getCached<SourceMarketItem[]>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/ranking?type=${type}&limit=${limit}`;

      const result = await this.httpGet<SourceMarketItem[]>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || [];
    } catch (error) {
      console.error('[SourceMarket] Get source ranking failed:', error);
      return [];
    }
  }

  /**
   * 鑾峰彇涔︽簮缁熻淇℃伅
   */
  async getSourceStats(): Promise<SourceStats> {
    try {
      // TODO: 鏇挎崲涓虹湡瀹濧PI鍦板潃
      const url = `${this.baseUrl}/api/market/stats`;

      return await this.httpGet<SourceStats>(url) || {
        totalSources: 0,
        totalDownloads: 0,
        avgRating: 0,
        officialCount: 0
      };
    } catch (error) {
      console.error('[SourceMarket] Get source stats failed:', error);
      return {
        totalSources: 0,
        totalDownloads: 0,
        avgRating: 0,
        officialCount: 0
      };
    }
  }

  // ==================== 鏈湴绠＄悊 ====================

  /**
   * 淇濆瓨涓嬭浇璁板綍
   */
  private async saveDownloadRecord(marketId: string): Promise<void> {
    try {
      const records = await preferenceManager.getValue('downloaded_sources', '[]');
      const recordsArray = JSON.parse(records) as string[];

      if (!recordsArray.includes(marketId)) {
        recordsArray.push(marketId);
        await preferenceManager.setValue('downloaded_sources', JSON.stringify(recordsArray));
      }
    } catch (error) {
      console.error('[SourceMarket] Save download record failed:', error);
    }
  }

  /**
   * 鑾峰彇宸蹭笅杞界殑涔︽簮鍖匢D鍒楄〃
   */
  async getDownloadedSourceIds(): Promise<string[]> {
    try {
      const records = await preferenceManager.getValue('downloaded_sources', '[]');
      return JSON.parse(records) as string[];
    } catch (error) {
      console.error('[SourceMarket] Get downloaded sources failed:', error);
      return [];
    }
  }

  // ==================== 缂撳瓨绠＄悊 ====================

  /**
   * 鑾峰彇缂撳瓨
   */
  private getCached<T>(key: string): T | null {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.time < this.cacheTTL) {
      return cached.data as T;
    }
    this.cache.delete(key);
    return null;
  }

  /**
   * 璁剧疆缂撳瓨
   */
  private setCached<T>(key: string, data: T): void {
    this.cache.set(key, {
      data: data as object,
      time: Date.now()
    });
  }

  /**
   * 娓呴櫎缂撳瓨
   */
  clearCache(): void {
    this.cache.clear();
    console.info('[SourceMarket] Cache cleared');
  }

  // ==================== HTTP璇锋眰 ====================

  /**
   * HTTP GET璇锋眰
   */
  private async httpGet<T>(url: string): Promise<T | null> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'LegadoMarket/1.0 (HarmonyOS)'
        },
        connectTimeout: 15000,
        readTimeout: 15000
      });

      if (response.responseCode === 200 && response.result) {
        return JSON.parse(response.result as string) as T;
      }

      return null;
    } catch (error) {
      console.error('[SourceMarket] HTTP GET failed:', url, error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 閲婃斁璧勬簮
   */
  release(): void {
    this.cache.clear();
    this.context = null;
    console.info('[SourceMarket] Released');
  }
}

// 瀵煎嚭鍗曚緥
export const legadoSourceMarket = LegadoSourceMarketService.getInstance();
export default legadoSourceMarket;
