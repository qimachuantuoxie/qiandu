import { logger } from '../../utils/Logger';
/**
 * BookSourceImporter - 涔︽簮瀵煎叆宸ュ叿
 *
 * 鏀�寔浠庣綉缁淯RL瀵煎叆闃呰�APP涔︽簮 (Legado鏍煎紡)
 *
 * @since 6.0.0
 */

import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, ReplaceRule, generateSourceId, SearchRule, BookInfoRule, ContentRule, TocRule } from '../models/CoreSourceModel';

/**
 * Legado 鍘熷�涔︽簮鏍煎紡 (闃呰�APP鐨凧SON鏍煎紡)
 */
export interface LegadoBookSource {
  bookSourceComment?: string;
  bookSourceGroup?: string;
  bookSourceName: string;
  bookSourceType?: number;
  bookSourceUrl: string;
  customOrder?: number;
  enabled?: boolean;
  enabledExplore?: boolean;
  exploreUrl?: string;
  lastUpdateTime?: number;
  respondTime?: number;
  ruleSearch?: LegadoSearchRule;
  ruleExplore?: LegadoExploreRule;
  ruleBookInfo?: LegadoBookInfoRule;
  ruleToc?: LegadoTocRule;
  ruleContent?: LegadoContentRule;
  searchUrl?: string;
  weight?: number;
}

export interface LegadoSearchRule {
  author?: string;
  bookList?: string;
  bookUrl?: string;
  coverUrl?: string;
  intro?: string;
  kind?: string;
  lastChapter?: string;
  name?: string;
  checkKeyWord?: string;
}

export interface LegadoExploreRule {
  author?: string;
  bookList?: string;
  bookUrl?: string;
  coverUrl?: string;
  intro?: string;
  kind?: string;
  lastChapter?: string;
  name?: string;
}

export interface LegadoBookInfoRule {
  author?: string;
  coverUrl?: string;
  init?: string;
  intro?: string;
  kind?: string;
  lastChapter?: string;
  name?: string;
  tocUrl?: string;
  canReName?: string;
}

export interface LegadoTocRule {
  chapterList?: string;
  chapterName?: string;
  chapterUrl?: string;
  isVip?: string;
  isPay?: string;
  updateTime?: string;
  nextTocUrl?: string;
}

export interface LegadoContentRule {
  content?: string;
  nextContentUrl?: string;
  replaceRegex?: string;
  imageUrl?: string;
  payAction?: string;
  sourceRegex?: string;
  webJs?: string;
}

export interface LegadoReplaceRule {
  id?: number;
  name?: string;
  group?: string;
  pattern: string;
  replacement: string;
  scope?: string;
  isEnabled?: boolean;
  isRegex?: boolean;
}

export interface ImportResult {
  success: number;
  fail: number;
  total: number;
  message: string;
}

export interface OnlineSourceInfo {
  name: string;
  url: string;
  count: number;
  updateTime: string;
  description?: string;
}

// 棰勮�涔︽簮URL鍒楄〃 - 宸茬Щ闄わ紝鐢ㄦ埛闇€鎵嬪姩娣诲姞涔︽簮
export const PRESET_SOURCE_URLS: OnlineSourceInfo[] = [];

/**
 * 涔︽簮瀵煎叆绠＄悊鍣?- 鍗曚緥妯″紡
 */
export class BookSourceImporter {
  private static instance: BookSourceImporter;

  private constructor() {}

  static getInstance(): BookSourceImporter {
    if (!BookSourceImporter.instance) {
      BookSourceImporter.instance = new BookSourceImporter();
    }
    return BookSourceImporter.instance;
  }

  /**
   * 浠嶶RL瀵煎叆涔︽簮
   */
  async importFromUrl(url: string): Promise<ImportResult> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36'
        },
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200 && response.result) {
        const content = response.result as string;
        return this.parseAndImport(content);
      } else {
        return {
          success: 0,
          fail: 0,
          total: 0,
          message: '璇锋眰澶辫触: HTTP ' + response.responseCode
        };
      }
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      const errorMsg: string = message;
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '瀵煎叆澶辫触: ' + errorMsg
      };
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 瑙ｆ瀽骞跺�鍏ヤ功婧?   */
  parseAndImport(jsonContent: string): ImportResult {
    try {
      let sources: LegadoBookSource[] = [];
      const content = jsonContent.trim();

      try {
        if (content.startsWith('[')) {
          sources = JSON.parse(content) as LegadoBookSource[];
        } else if (content.startsWith('{')) {
          const single = JSON.parse(content) as LegadoBookSource;
          sources = [single];
        }
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[BookSourceImporter] JSON parse error:', message);
        logger.error('[BookSourceImporter] JSON parse error:', err.message);
        sources = [];
      }

      if (sources.length === 0) {
        return {
          success: 0,
          fail: 0,
          total: 0,
          message: '鏈�壘鍒版湁鏁堜功婧?
        };
      }

      const convertedSources: BookSource[] = this.convertLegadoSources(sources);
      let successCount: number = 0;

      for (let i = 0; i < convertedSources.length; i++) {
        if (this.isValidSource(convertedSources[i])) {
          successCount++;
        }
      }

      return {
        success: successCount,
        fail: convertedSources.length - successCount,
        total: convertedSources.length,
        message: '鎴愬姛瀵煎叆' + successCount + '涓�功婧?
      };
    } catch (error) {
      const err = error as Error;
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '涔︽簮鏍煎紡瑙ｆ瀽澶辫触'
      };
    }
  }

  /**
   * 楠岃瘉涔︽簮鏄�惁鏈夋晥
   */
  private isValidSource(source: BookSource): boolean {
    return !!(source.name && source.url && source.enabled);
  }

  /**
   * Legado鏍煎紡杞�崲涓哄唴閮˙ookSource鏍煎紡
   */
  convertLegadoToBookSource(legadoSource: LegadoBookSource): BookSource {
    const sourceType: number = legadoSource.bookSourceType !== undefined ? legadoSource.bookSourceType : 0;
    return {
      id: generateSourceId(),
      name: legadoSource.bookSourceName || '鏈�懡鍚嶄功婧?,
      url: legadoSource.bookSourceUrl || '',
      enabled: legadoSource.enabled !== false,
      priority: 1,
      weight: legadoSource.weight || legadoSource.customOrder || 0,
      bookSourceType: sourceType === 0 ? BookSourceType.TEXT :
                      sourceType === 1 ? BookSourceType.AUDIO : BookSourceType.IMAGE,
      loginRequired: false,
      exploreUrl: legadoSource.exploreUrl,
      ruleSearch: this.convertSearchRule(legadoSource.ruleSearch),
      ruleBookInfo: this.convertBookInfoRule(legadoSource.ruleBookInfo),
      ruleContent: this.convertContentRule(legadoSource.ruleContent),
      ruleToc: this.convertTocRule(legadoSource.ruleToc),
      createTime: Date.now(),
      lastUpdateTime: legadoSource.lastUpdateTime || Date.now()
    };
  }

  /**
   * 杞�崲鎼滅储瑙勫垯
   */
  private convertSearchRule(rule?: LegadoSearchRule): SearchRule | undefined {
    if (!rule) return undefined;
    return {
      searchUrl: rule.bookList,
      bookList: rule.bookList,
      name: rule.name,
      author: rule.author,
      desc: rule.intro,
      cover: rule.coverUrl
    };
  }

  /**
   * 杞�崲涔︾睄淇℃伅瑙勫垯
   */
  private convertBookInfoRule(rule?: LegadoBookInfoRule): BookInfoRule | undefined {
    if (!rule) return undefined;
    return {
      cover: rule.coverUrl,
      title: rule.name,
      author: rule.author,
      desc: rule.intro,
      lastChapter: rule.lastChapter
    };
  }

  /**
   * 杞�崲鍐呭�瑙勫垯
   */
  private convertContentRule(rule?: LegadoContentRule): ContentRule | undefined {
    if (!rule) return undefined;
    return {
      content: rule.content,
      replaceRegex: rule.replaceRegex,
      nextContent: rule.nextContentUrl
    };
  }

  /**
   * 杞�崲鐩�綍瑙勫垯
   */
  private convertTocRule(rule?: LegadoTocRule): TocRule | undefined {
    if (!rule) return undefined;
    return {
      tocList: rule.chapterList,
      chapterName: rule.chapterName,
      chapterUrl: rule.chapterUrl,
      isVip: rule.isVip,
      updateTime: rule.updateTime
    };
  }

  /**
   * 鎵归噺杞�崲涔︽簮 - 浣跨敤for寰�幆绗﹀悎ArkTS瑙勮寖
   */
  convertLegadoSources(legadoSources: LegadoBookSource[]): BookSource[] {
    const result: BookSource[] = [];
    for (let i = 0; i < legadoSources.length; i++) {
      result.push(this.convertLegadoToBookSource(legadoSources[i]));
    }
    return result;
  }

  /**
   * 瑙ｆ瀽鏇挎崲瑙勫垯 - 浣跨敤for寰�幆绗﹀悎ArkTS瑙勮寖
   */
  parseReplaceRules(jsonContent: string): ReplaceRule[] {
    try {
      const legadoRules: LegadoReplaceRule[] = JSON.parse(jsonContent);
      const result: ReplaceRule[] = [];

      for (let i = 0; i < legadoRules.length; i++) {
        const rule = legadoRules[i];
        result.push({
          id: 'replace_' + Date.now() + '_' + i,
          name: rule.name || '瑙勫垯' + (i + 1),
          sourceId: rule.group || '',
          pattern: rule.pattern,
          replacement: rule.replacement,
          enabled: rule.isEnabled !== false,
          scope: this.convertScope(rule.scope),
          isRegex: rule.isRegex !== false
        });
      }

      return result;
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[BookSourceImporter] Parse replace rules error:', message);
      logger.error('[BookSourceImporter] Parse replace rules error:', err.message);
      return [];
    }
  }

  /**
   * 杞�崲浣滅敤鑼冨洿
   */
  private convertScope(scope?: string): 'title' | 'content' | 'all' {
    if (scope === 'title') return 'title';
    if (scope === 'content') return 'content';
    return 'all';
  }
}

/**
 * 涔︽簮瀵煎叆鍣ㄥ崟渚嬪疄渚? */
export const bookSourceImporter = BookSourceImporter.getInstance();
