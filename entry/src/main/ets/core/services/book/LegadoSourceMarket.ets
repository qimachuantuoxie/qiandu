import { logger } from '../../../utils/Logger';
/**
 * Legado Book Source Market Service - 妤﹁儻鎸嬮悧鍫滃姛濠ф劕绔堕崷鐑樻箛閸?
 *
 * 閸旂喕鍏橀敍?
 * - 閸︺劎鍤庢稊锔界爱鐢�倸婧€濞村繗顫? * - 娑旓附绨�崚鍡欒�閸滃本鎮崇槐?
 * - 娑旓附绨�稉瀣�祰閸滃苯顕遍崗?
 * - 娑旓附绨�拠鍕�瀻閸滃本甯撶悰?
 * - 娑旓附绨�崚鍡曢煩閸滃苯顕遍崙?
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
 * Legado鐟欏嫬鍨�€涙�顔岀猾璇茬€烽敍鍫㈡暏娴滃骸顕遍崙鐚寸礆
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
 * 娑旓附绨�敮鍌氭簚閸掑棛琚? */
export enum SourceMarketCategory {
  /** 閸忋劑鍎?*/
  ALL = 'all',
  /** 缁�儳鎼ч幒銊ㄥ礃 */
  FEATURED = 'featured',
  /** 閻㈢兘顣?*/
  MALE = 'male',
  /** 婵傛娊顣?*/
  FEMALE = 'female',
  /** 濠曨偆鏁?*/
  COMIC = 'comic',
  /** 闂婃娊顣?*/
  AUDIO = 'audio',
  /** 閼辨艾鎮?*/
  AGGREGATE = 'aggregate'
}

/**
 * 娑旓附绨�敮鍌氭簚閹烘帒绨? */
export enum SourceMarketSort {
  /** 閹恒劏宕橀幒鎺戠碍 */
  RECOMMENDED = 'recommended',
  /** 娑撳�娴囬柌?*/
  DOWNLOADS = 'downloads',
  /** 鐠囧嫬鍨?*/
  RATING = 'rating',
  /** 閺囧瓨鏌婇弮鍫曟？ */
  UPDATE_TIME = 'update_time',
  /** 娑旓附绨�弫浼村櫤 */
  SOURCE_COUNT = 'source_count'
}

/**
 * 娑旓附绨�敮鍌氭簚妞?
 */
export interface SourceMarketItem {
  /** 鐢�倸婧€ID */
  marketId: string;
  /** 娑旓附绨�崠鍛�倳缁?*/
  name: string;
  /** 閹诲繗鍫?*/
  description: string;
  /** 娴ｆ粏鈧?*/
  author: string;
  /** 閸掑棛琚?*/
  category: SourceMarketCategory;
  /** 娑旓附绨�弫浼村櫤 */
  sourceCount: number;
  /** 娑撳�娴囬柌?*/
  downloads: number;
  /** 鐠囧嫬鍨?*/
  rating: number;
  /** 鐠囧嫬鍨庢禍鐑樻殶 */
  ratingCount: number;
  /** 閸ョ偓鐖�RL */
  iconUrl: string;
  /** 娑旓附绨甁SON URL */
  sourceUrl: string;
  /** 鐠囷附鍎忔い绀�L */
  detailUrl?: string;
  /** 閺嶅洨顒?*/
  tags: string[];
  /** 閺勵垰鎯佺€规ɑ鏌?*/
  isOfficial: boolean;
  /** 閺囧瓨鏌婇弮鍫曟？ */
  updateTime: number;
  /** 閸掓稑缂撻弮鍫曟？ */
  createTime: number;
  /** 閺勵垰鎯佸�韫�瑓鏉?*/
  isDownloaded: boolean;
  /** 閺勵垰鎯侀棁鈧�憰涔侷P */
  requiresVip: boolean;
  /** 妫板嫯顫嶆稊锔界爱閸掓�銆?*/
  previewSources?: string[];
}

/**
 * 娑旓附绨�敮鍌氭簚缁涙盯鈧��娼�禒?
 */
export interface MarketFilter {
  /** 閸掑棛琚?*/
  category?: SourceMarketCategory;
  /** 閺嶅洨顒?*/
  tag?: string;
  /** 閺勵垰鎯佺€规ɑ鏌?*/
  isOfficial?: boolean;
  /** 閺勵垰鎯侀棁鈧�憰涔侷P */
  requiresVip?: boolean;
}

/**
 * 娑旓附绨�敮鍌氭簚閺屻儴顕楃紒鎾寸亯
 */
export interface MarketQueryResult {
  /** 閹�粯鏆?*/
  total: number;
  /** 瑜版挸澧犳い?*/
  page: number;
  /** 濮ｅ繘銆夐弫浼村櫤 */
  pageSize: number;
  /** 閺佺増宓侀崚妤勩€?*/
  items: SourceMarketItem[];
}

/**
 * 妫板嫯顫嶉崫宥呯安
 */
interface PreviewResponse {
  sources: BookSource[];
}

/**
 * 娑撳�娴囬崫宥呯安
 */
interface DownloadResponse {
  sources: LegadoSourceRaw[];
}

/**
 * Legado鐎电厧鍤�┃鎰�壐瀵?
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
 * Legado 閸樼喎顫愭稊锔界爱閺嶇厧绱￠敍鍦漇ON閿?
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
 * 缂傛挸鐡ㄩ弫鐗堝祦閹恒儱褰? */
interface CacheData<T> {
  data: T;
  time: number;
}

/**
 * 娑旓附绨�敮鍌氭簚閺堝秴濮熺猾?
 */
class LegadoSourceMarketService {
  /** 閸楁洑绶ョ€圭偘绶?*/
  private static instance: LegadoSourceMarketService;

  /** 娑撳﹣绗呴弬?*/
  private context: common.Context | null = null;

  /** API閸╄櫣顢匲RL */
  private baseUrl: string = 'https://api.legado-market.com';

  /** 缂傛挸鐡?*/
  private cache: Map<string, CacheData<object>> = new Map();

  /** 缂傛挸鐡ㄩ張澶嬫櫏閺堢噦绱?閸掑棝鎸撻敍?*/
  private cacheTTL: number = 5 * 60 * 1000;

  private constructor() {}

  /**
   * 閼惧嘲褰囬崡鏇氱伐鐎圭偘绶?   */
  static getInstance(): LegadoSourceMarketService {
    if (!LegadoSourceMarketService.instance) {
      LegadoSourceMarketService.instance = new LegadoSourceMarketService();
    }
    return LegadoSourceMarketService.instance;
  }

  /**
   * 閸掓繂顫愰崠鏍ㄦ箛閸?
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
   * 濡�偓閺屻儲婀囬崝鈩冩Ц閸氾箑姘ㄧ紒?
   */
  isReady(): boolean {
    return this.context !== null;
  }

  // ==================== 娑旓附绨�敮鍌氭簚濞村繗顫?====================

  /**
   * 閼惧嘲褰囬幒銊ㄥ礃娑旓附绨�崠?
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
   * 閼惧嘲褰囬悜顓㈡，娑旓附绨�崠鍜冪礄閹稿�绗呮潪浠嬪櫤閿?
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
   * 閼惧嘲褰囨�妯跨槑閸掑棔鍔熷┃鎰�瘶
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
   * 閺嶈�宓侀崚鍡欒�閼惧嘲褰囨稊锔界爱閸?
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
   * 閹兼粎鍌ㄦ稊锔界爱閸?
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

      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = this.baseUrl + '/api/market/search?keyword=' + encodeURIComponent(keyword) + '&page=' + page + '&pageSize=' + pageSize;

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
   * 閺屻儴顕楁稊锔界爱閸栧拑绱欓柅姘辨暏閿?
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

      // 閺嬪嫬缂撻弻銉�嚄閸欏倹鏆?      let queryParams = '';
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

      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/sources?${queryParams}`;

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

  // ==================== 娑旓附绨�崠鍛邦嚊閹?====================

  /**
   * 閼惧嘲褰囨稊锔界爱閸栧懓顕涢幆?
   */
  async getSourceMarketDetail(marketId: string): Promise<SourceMarketItem | null> {
    try {
      const cacheKey = `detail:${marketId}`;
      const cached = this.getCached<SourceMarketItem>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/sources/${marketId}`;

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
   * 妫板嫯顫嶆稊锔界爱閸栧懎鍞寸€?
   */
  async previewSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/sources/${marketId}/preview`;

      const response = await this.httpGet<PreviewResponse>(url);

      if (response && response.sources) {
        // 閻╁瓨甯存潻鏂挎礀BookSource閺佹壆绮?        return response.sources;
      }

      return null;
    } catch (error) {
      logger.error('[SourceMarket] Preview source package failed:', error);
      return null;
    }
  }

  // ==================== 娑撳�娴囬崪灞筋嚤閸?====================

  /**
   * 娑撳�娴囨稊锔界爱閸?
   */
  async downloadSourcePackage(marketId: string): Promise<BookSource[] | null> {
    try {
      logger.info('[SourceMarket] Downloading source package:', marketId);

      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/sources/${marketId}/download`;

      const response = await this.httpGet<DownloadResponse>(url);

      if (response && response.sources) {
        // 鏉烆剚宕查弽鐓庣础
        const sources = this.convertLegadoSources(response.sources);

        // 娣囨繂鐡ㄦ稉瀣�祰鐠佹澘缍?        await this.saveDownloadRecord(marketId);

        return sources;
      }

      return null;
    } catch (error) {
      logger.error('[SourceMarket] Download source package failed:', error);
      return null;
    }
  }

  /**
   * 娴犲抖RL鐎电厧鍙嗘稊锔界爱閸栧拑绱橪egado閺嶇厧绱￠敍?
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
      // 闁插﹥鏂丠TTP鐠у嫭绨?      httpRequest.destroy();
    }
  }

  /**
   * 鐟欙絾鐎介獮鎯版祮閹诡澀鍔熷┃?
   */
  parseAndConvertSources(jsonContent: string): BookSource[] {
    try {
      let legadoSources: LegadoSourceRaw[] = [];
      const content = jsonContent.trim();

      // 鐏忔繆鐦�憴锝嗙€絁SON
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
   * 鏉烆剚宕睱egado閺嶇厧绱℃稉鍝勫敶闁�劍鐗稿�?
   */
  private convertLegadoSources(legadoSources: LegadoSourceRaw[]): BookSource[] {
    return legadoSources
      .filter(source => source.bookSourceName && source.bookSourceUrl)
      .map(source => {
        const bookSource: BookSource = {
          id: generateSourceId(),
          name: source.bookSourceName || '鏈�懡鍚嶄功婧?,
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
   * 鏉烆剚宕叉稊锔界爱缁��鐎?   */
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

  // ==================== 娑旓附绨�ù瀣�槸 ====================

  /**
   * 濞村�鐦�稊锔界爱
   */
  async testSource(source: BookSource, testKeyword: string = '濞村�鐦?): Promise<TestSourceResult> {
    try {
      logger.info('[SourceMarket] Testing source:', source.name);
      const startTime = Date.now();

      // TODO: 鐎圭偟骞囬惇鐔风杽閻ㄥ嫪鍔熷┃鎰�ゴ鐠囨洟鈧�槒绶?      // 1. 濞村�鐦�幖婊呭偍閸旂喕鍏?      // 2. 濞村�鐦�稊锔剧潉鐠囷附鍎?      // 3. 濞村�鐦�粩鐘哄Ν閸掓�銆?      // 4. 濞村�鐦�崘鍛�啇閼惧嘲褰?
      const responseTime = Date.now() - startTime;

      return {
        success: true,
        responseTime,
        searchResultCount: 10 // 濡�剝瀚欓弫鐗堝祦
      };
    } catch (error) {
      logger.error('[SourceMarket] Test source failed:', error);
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
   * 閹靛綊鍣哄ù瀣�槸娑旓附绨?   */
  async testSourcesBatch(sources: BookSource[]): Promise<TestSourceBatchResult> {
    try {
      logger.info('[SourceMarket] Testing', sources.length, 'sources...');

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
      logger.error('[SourceMarket] Test sources batch failed:', error);
      return {
        total: sources.length,
        success: 0,
        failed: sources.length,
        averageResponseTime: 0
      };
    }
  }

  // ==================== 娑旓附绨�崚鍡曢煩閸滃苯顕遍崙?====================

  /**
   * 鐎电厧鍤�稊锔界爱娑撶瘮SON
   */
  exportSourcesToJson(sources: BookSource[]): string {
    try {
      // 鏉烆剚宕叉稉绡杄gado閺嶇厧绱?      const legadoSources: LegadoSourceExport[] = [];
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
   * 閻㈢喐鍨氱€电厧鍙哢RL閿涘湢egado URL Scheme閿?
   */
  generateImportUrl(jsonContent: string): string {
    const encoded = encodeURIComponent(jsonContent);
    return `legado://import/bookSource?src=${encoded}`;
  }

  /**
   * 閻㈢喐鍨氶崚鍡曢煩闁剧偓甯?   */
  generateShareUrl(marketId: string): string {
    return `${this.baseUrl}/share/${marketId}`;
  }

  // ==================== 缂佺喕顓搁崪灞惧笓鐞?====================

  /**
   * 閼惧嘲褰囨稊锔界爱閹烘帟顢戝�?
   */
  async getSourceRanking(type: 'downloads' | 'rating' | 'update', limit: number = 50): Promise<SourceMarketItem[]> {
    try {
      const cacheKey = `ranking:${type}:${limit}`;
      const cached = this.getCached<SourceMarketItem[]>(cacheKey);
      if (cached) {
        return cached;
      }

      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/ranking?type=${type}&limit=${limit}`;

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
   * 閼惧嘲褰囨稊锔界爱缂佺喕顓告穱鈩冧紖
   */
  async getSourceStats(): Promise<SourceStats> {
    try {
      // TODO: 閺囨寧宕叉稉铏规埂鐎规咖PI閸︽澘娼?      const url = `${this.baseUrl}/api/market/stats`;

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

  // ==================== 閺堫剙婀寸粻锛勬倞 ====================

  /**
   * 娣囨繂鐡ㄦ稉瀣�祰鐠佹澘缍?   */
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
   * 閼惧嘲褰囧�韫�瑓鏉炵晫娈戞稊锔界爱閸栧將D閸掓�銆?   */
  async getDownloadedSourceIds(): Promise<string[]> {
    try {
      const records = await preferenceManager.getValue('downloaded_sources', '[]');
      return JSON.parse(records) as string[];
    } catch (error) {
      logger.error('[SourceMarket] Get downloaded sources failed:', error);
      return [];
    }
  }

  // ==================== 缂傛挸鐡ㄧ粻锛勬倞 ====================

  /**
   * 閼惧嘲褰囩紓鎾崇摠
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
   * 鐠佸墽鐤嗙紓鎾崇摠
   */
  private setCached<T>(key: string, data: T): void {
    this.cache.set(key, {
      data: data as object,
      time: Date.now()
    });
  }

  /**
   * 濞撳懘娅庣紓鎾崇摠
   */
  clearCache(): void {
    this.cache.clear();
    logger.info('[SourceMarket] Cache cleared');
  }

  // ==================== HTTP鐠囬攱鐪?====================

  /**
   * HTTP GET鐠囬攱鐪?   */
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
   * 闁插﹥鏂佺挧鍕�爱
   */
  release(): void {
    this.cache.clear();
    this.context = null;
    logger.info('[SourceMarket] Released');
  }
}

// 鐎电厧鍤�崡鏇氱伐
export const legadoSourceMarket = LegadoSourceMarketService.getInstance();
export default legadoSourceMarket;
