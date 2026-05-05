import { logger } from '../../../utils/Logger';
/**
 * Legado Book Source Market Service - 书源市场服务
 *
 * 功能说明：
 * - 获取书源市场列表和详情
 * - 预览和下载书源包
 * - 导入和导出书源
 * - 测试书源可用性
 *
 * @since 5.1.0
 */

import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
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
} from '../models/BookSourceModel';
import { CACHE_TTL_SHORT } from '../../constants/TimeConstants';

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



export interface QueryParams {
  category?: SourceMarketCategory;
  sort?: SourceMarketSort;
  filter?: MarketFilter;
  page?: number;
  pageSize?: number;
}

/**
 * Legado规则字段定义
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
 * 书源市场分类
 */
export enum SourceMarketCategory {
  /** 全部 */
  ALL = 'all',
  /** 精选推荐 */
  FEATURED = 'featured',
  /** 男频 */
  MALE = 'male',
  /** 女频 */
  FEMALE = 'female',
  /** 漫画 */
  COMIC = 'comic',
  /** 音频 */
  AUDIO = 'audio',
  /** 聚合 */
  AGGREGATE = 'aggregate'
}

/**
 * 书源市场排序
 */
export enum SourceMarketSort {
  /** 推荐排序 */
  RECOMMENDED = 'recommended',
  /** 下载量 */
  DOWNLOADS = 'downloads',
  /** 评分 */
  RATING = 'rating',
  /** 更新时间 */
  UPDATE_TIME = 'update_time',
  /** 书源数量 */
  SOURCE_COUNT = 'source_count'
}

/**
 * 书源市场项
 */
export interface SourceMarketItem {
  /** 书源ID */
  marketId: string;
  /** 书源包名称 */
  name: string;
  /** 描述 */
  description: string;
  /** 作者 */
  author: string;
  /** 分类 */
  category: SourceMarketCategory;
  /** 书源数量 */
  sourceCount: number;
  /** 下载量 */
  downloads: number;
  /** 评分 */
  rating: number;
  /** 评分人数 */
  ratingCount: number;
  /** 图标URL */
  iconUrl: string;
  /** 书源JSON URL */
  sourceUrl: string;
  /** 详情页URL */
  detailUrl?: string;
  /** 标签 */
  tags: string[];
  /** 是否官方 */
  isOfficial: boolean;
  /** 更新时间 */
  updateTime: number;
  /** 创建时间 */
  createTime: number;
  /** 是否已下载 */
  isDownloaded: boolean;
  /** 是否需要VIP */
  requiresVip: boolean;
  /** 预览书源列表 */
  previewSources?: string[];
}

/**
 * 书源市场查询过滤条件
 */
export interface MarketFilter {
  /** 分类 */
  category?: SourceMarketCategory;
  /** 标签 */
  tag?: string;
  /** 是否官方 */
  isOfficial?: boolean;
  /** 是否需要VIP */
  requiresVip?: boolean;
}

/**
 * 书源市场查询结果
 */
export interface MarketQueryResult {
  /** 总数 */
  total: number;
  /** 当前页 */
  page: number;
  /** 每页数量 */
  pageSize: number;
  /** 数据列表 */
  items: SourceMarketItem[];
}

/**
 * 预览响应
 */
interface PreviewResponse {
  sources: BookSource[];
}

/**
 * 下载响应
 */
interface DownloadResponse {
  sources: LegadoSourceRaw[];
}

/**
 * Legado书源导出格式
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
 * Legado 原始书源JSON格式
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
 * 缓存数据结构
 */
interface CacheData<T> {
  data: T;
  time: number;
}

/**
 * 书源市场服务类
 */
class LegadoSourceMarketService {
  /** 单例实例 */
  private static instance: LegadoSourceMarketService;

  /** 上下文 */
  private context: common.Context | null = null;

  /** API基础URL */
  private baseUrl: string = 'https://api.legado-market.com';

  /** 缓存 */
  private cache: Map<string, CacheData<object>> = new Map();

  /** 缓存过期时间（毫秒） */
  private cacheTTL: number = CACHE_TTL_SHORT;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): LegadoSourceMarketService {
    if (!LegadoSourceMarketService.instance) {
      LegadoSourceMarketService.instance = new LegadoSourceMarketService();
    }
    return LegadoSourceMarketService.instance;
  }

  /**
   * 初始化服务
   */
  async init(context: common.Context, baseUrl?: string): Promise<boolean> {
    try {
      logger.info('[SourceMarket] Initializing...');
      this.context = context;
      if (baseUrl) {
        this.baseUrl = baseUrl;
      }
      logger.info('[SourceMarket] Initialized, baseUrl:', this.baseUrl);
      return true;
    } catch (error) {
      logger.error('[SourceMarket] Init failed:', error);
      return false;
    }
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.context !== null;
  }

  // ==================== 书源市场查询 ====================

  /**
   * 获取精选书源
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
      logger.error('[SourceMarket] Get featured sources failed:', error);
      const result: MarketQueryResult = { total: 0, page: page, pageSize: pageSize, items: [] };
      return result;
    }
  }

  /**
   * 获取热门书源（按下载量排序）
   */
  async getPopularSources(page: number = 1, pageSize: number = 20): Promise<MarketQueryResult> {
    try {
      return await this.querySources({
        sort: SourceMarketSort.DOWNLOADS,
        page,
        pageSize
      });
    } catch (error) {
      logger.error('[SourceMarket] Get popular sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 获取高评分书源
   */
  async getTopRatedSources(page: number = 1, pageSize: number = 20): Promise<MarketQueryResult> {
    try {
      return await this.querySources({
        sort: SourceMarketSort.RATING,
        page,
        pageSize
      });
    } catch (error) {
      logger.error('[SourceMarket] Get top rated sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 按分类获取书源
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
      logger.error('[SourceMarket] Get sources by category failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 搜索书源
   */
  async searchSources(
    keyword: string,
    page: number = 1,
    pageSize: number = 20
  ): Promise<MarketQueryResult> {
    try {
      logger.info('[SourceMarket] Searching:', keyword);

      const cacheKey = 'search:' + keyword + ':' + page + ':' + pageSize;
      const cached = this.getCached<MarketQueryResult>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 实现实际的API调用
      const url = this.baseUrl + '/api/market/search?keyword=' + encodeURIComponent(keyword) + '&page=' + page + '&pageSize=' + pageSize;

      const result = await this.httpGet<MarketQueryResult>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || { total: 0, page, pageSize, items: [] };
    } catch (error) {
      logger.error('[SourceMarket] Search sources failed:', error);
      return { total: 0, page: page, pageSize: pageSize, items: [] };
    }
  }

  /**
   * 通用查询书源
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

      // 构建查询参数
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

      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/sources?${queryParams}`;

      const result = await this.httpGet<MarketQueryResult>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || { total: 0, page, pageSize, items: [] };
    } catch (error) {
      logger.error('[SourceMarket] Query sources failed:', error);
      return { total: 0, page: params.page || 1, pageSize: params.pageSize || 20, items: [] };
    }
  }

  // ==================== 书源包详情 ====================

  /**
   * 获取书源包详情
   */
  async getSourceMarketDetail(marketId: string): Promise<SourceMarketItem | null> {
    try {
      const cacheKey = `detail:${marketId}`;
      const cached = this.getCached<SourceMarketItem>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/sources/${marketId}`;

      const result = await this.httpGet<SourceMarketItem>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result;
    } catch (error) {
      logger.error('[SourceMarket] Get source detail failed:', error);
      return null;
    }
  }

  /**
   * 预览书源包内容
   */
  async previewSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/sources/${marketId}/preview`;

      const response = await this.httpGet<PreviewResponse>(url);

      if (response && response.sources) {
        // 直接返回BookSource格式
        return response.sources;
      }

      return null;
    } catch (error) {
      logger.error('[SourceMarket] Preview source package failed:', error);
      return null;
    }
  }

  // ==================== 下载与导入 ====================

  /**
   * 下载书源包
   */
  async downloadSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      logger.info('[SourceMarket] Downloading source package:', marketId);

      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/sources/${marketId}/download`;

      const response = await this.httpGet<DownloadResponse>(url);

      if (response && response.sources) {
        // 转换格式
        const sources = this.convertLegadoSources(response.sources);

        // 保存下载记录
        await this.saveDownloadRecord(marketId);

        return sources;
      }

      return null;
    } catch (error) {
      logger.error('[SourceMarket] Download source package failed:', error);
      return null;
    }
  }

  /**
   * 从URL导入书源（支持Legado格式的JSON）
   */
  async importFromUrl(url: string): Promise<ImportResult> {
    const httpRequest = http.createHttp();

    try {
      logger.info('[SourceMarket] Importing from URL:', url);

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
      logger.error('[SourceMarket] Import from URL failed:', error);
      const result: ImportResult = {
        success: 0,
        fail: 0,
        sources: []
      };
      return result;
    } finally {
      // 销毁HTTP请求
      httpRequest.destroy();
    }
  }

  /**
   * 解析并转换书源JSON内容为BookSource格式
   */
  parseAndConvertSources(jsonContent: string): BookSource[] {
    try {
      let legadoSources: LegadoSourceRaw[] = [];
      const content = jsonContent.trim();

      // 判断JSON格式
      if (content.startsWith('[')) {
        legadoSources = JSON.parse(content) as LegadoSourceRaw[];
      } else if (content.startsWith('{')) {
        legadoSources = [JSON.parse(content) as LegadoSourceRaw];
      }

      return this.convertLegadoSources(legadoSources);
    } catch (error) {
      logger.error('[SourceMarket] Parse and convert failed:', error);
      return [];
    }
  }

  /**
   * 将Legado原始格式转换为BookSource格式
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
   * 转换书源类型
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

  // ==================== 导出与分享 ====================

  /**
   * 导出书源为JSON格式
   */
  exportSourcesToJson(sources: BookSource[]): string {
    try {
      // 转换为Legado格式
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
      logger.error('[SourceMarket] Export to JSON failed:', error);
      return '';
    }
  }

  /**
   * 生成导入URL（Legado URL Scheme格式）
   */
  generateImportUrl(jsonContent: string): string {
    const encoded = encodeURIComponent(jsonContent);
    return `legado://import/bookSource?src=${encoded}`;
  }

  /**
   * 生成分享链接
   */
  generateShareUrl(marketId: string): string {
    return `${this.baseUrl}/share/${marketId}`;
  }

  // ==================== 排行榜与统计 ====================

  /**
   * 获取书源排行榜
   */
  async getSourceRanking(type: 'downloads' | 'rating' | 'update', limit: number = 50): Promise<SourceMarketItem[]> {
    try {
      const cacheKey = `ranking:${type}:${limit}`;
      const cached = this.getCached<SourceMarketItem[]>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/ranking?type=${type}&limit=${limit}`;

      const result = await this.httpGet<SourceMarketItem[]>(url);

      if (result) {
        this.setCached(cacheKey, result);
      }

      return result || [];
    } catch (error) {
      logger.error('[SourceMarket] Get source ranking failed:', error);
      return [];
    }
  }

  /**
   * 获取书源统计数据
   */
  async getSourceStats(): Promise<SourceStats> {
    try {
      // TODO: 实现实际的API调用
      const url = `${this.baseUrl}/api/market/stats`;

      return await this.httpGet<SourceStats>(url) || {
        totalSources: 0,
        totalDownloads: 0,
        avgRating: 0,
        officialCount: 0
      };
    } catch (error) {
      logger.error('[SourceMarket] Get source stats failed:', error);
      return {
        totalSources: 0,
        totalDownloads: 0,
        avgRating: 0,
        officialCount: 0
      };
    }
  }

  // ==================== 本地存储 ====================

  /**
   * 保存下载记录
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
      logger.error('[SourceMarket] Save download record failed:', error);
    }
  }

  /**
   * 获取已下载的书源ID列表
   */
  async getDownloadedSourceIds(): Promise<string[]> {
    try {
      const records = await preferenceManager.getValue('downloaded_sources', '[]');
      return JSON.parse(records) as string[];
    } catch (error) {
      logger.error('[SourceMarket] Get downloaded sources failed:', error);
      return [];
    }
  }

  // ==================== 缓存管理 ====================

  /**
   * 获取缓存
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
   * 设置缓存
   */
  private setCached<T>(key: string, data: T): void {
    this.cache.set(key, {
      data: data as object,
      time: Date.now()
    });
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.cache.clear();
    logger.info('[SourceMarket] Cache cleared');
  }

  // ==================== HTTP请求 ====================

  /**
   * HTTP GET请求
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
      logger.error('[SourceMarket] HTTP GET failed:', url, error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 释放资源
   */
  release(): void {
    this.cache.clear();
    this.context = null;
    logger.info('[SourceMarket] Released');
  }
}

// 导出单例
export const legadoSourceMarket = LegadoSourceMarketService.getInstance();
export default legadoSourceMarket;
