import { logger } from '../../utils/Logger';
/**
 * BookSourceImporter - 书源导入工具
 *
 * 支持从网络URL导入阅读APP书源 (Legado格式)
 *
 * @since 6.0.0
 */

import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, ReplaceRule, generateSourceId, SearchRule, BookInfoRule, ContentRule, TocRule } from '../models/CoreSourceModel';

/**
 * Legado 原始书源格式 (阅读APP的JSON格式)
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

// 预设书源URL列表 - 已移除，用户需手动添加书源
export const PRESET_SOURCE_URLS: OnlineSourceInfo[] = [];

/**
 * 书源导入管理器 - 单例模式
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
   * 从URL导入书源
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
          message: '请求失败: HTTP ' + response.responseCode
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
        message: '导入失败: ' + errorMsg
      };
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 解析并导入书源
   */
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
          message: '未找到有效书源'
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
        message: '成功导入' + successCount + '个书源'
      };
    } catch (error) {
      const err = error as Error;
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '书源格式解析失败'
      };
    }
  }

  /**
   * 验证书源是否有效
   */
  private isValidSource(source: BookSource): boolean {
    return !!(source.name && source.url && source.enabled);
  }

  /**
   * Legado格式转换为内部BookSource格式
   */
  convertLegadoToBookSource(legadoSource: LegadoBookSource): BookSource {
    const sourceType: number = legadoSource.bookSourceType !== undefined ? legadoSource.bookSourceType : 0;
    return {
      id: generateSourceId(),
      name: legadoSource.bookSourceName || '未命名书源',
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
   * 转换搜索规则
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
   * 转换书籍信息规则
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
   * 转换内容规则
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
   * 转换目录规则
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
   * 批量转换书源 - 使用for循环符合ArkTS规范
   */
  convertLegadoSources(legadoSources: LegadoBookSource[]): BookSource[] {
    const result: BookSource[] = [];
    for (let i = 0; i < legadoSources.length; i++) {
      result.push(this.convertLegadoToBookSource(legadoSources[i]));
    }
    return result;
  }

  /**
   * 解析替换规则 - 使用for循环符合ArkTS规范
   */
  parseReplaceRules(jsonContent: string): ReplaceRule[] {
    try {
      const legadoRules: LegadoReplaceRule[] = JSON.parse(jsonContent);
      const result: ReplaceRule[] = [];

      for (let i = 0; i < legadoRules.length; i++) {
        const rule = legadoRules[i];
        result.push({
          id: 'replace_' + Date.now() + '_' + i,
          name: rule.name || '规则' + (i + 1),
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
   * 转换作用范围
   */
  private convertScope(scope?: string): 'title' | 'content' | 'all' {
    if (scope === 'title') return 'title';
    if (scope === 'content') return 'content';
    return 'all';
  }
}

/**
 * 书源导入器单例实例
 */
export const bookSourceImporter = BookSourceImporter.getInstance();
