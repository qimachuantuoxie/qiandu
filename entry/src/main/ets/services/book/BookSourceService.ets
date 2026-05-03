// 书源服务 - 网络书籍搜索与导入
// Book Source Service - Network Book Search & Import
// 支持阅读3.0 (Legado) 书源格式的导入、搜索和测试
// 提供在线书源管理和书籍内容获取功能

import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, SearchRule, ContentRule } from '../../models/BookSourceModel';
import { BookSourceImporter, LegadoBookSource } from '../../utils/BookSourceImporter';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

/**
 * 网络书源搜索结果
 * Source Search Result
 */
export interface SourceSearchResult {
  bookName: string;        // 书名
  author: string;          // 作者
  coverUrl: string;        // 封面URL
  bookUrl: string;         // 书籍详情页URL
  sourceName: string;      // 来源名称
  sourceId: string;        // 来源ID
  latestChapter: string;   // 最新章节
  intro: string;           // 简介
}

/**
 * 书源测试结果
 * Source Test Result
 */
export interface SourceTestResult {
  sourceId: string;        // 来源ID
  sourceName: string;      // 来源名称
  success: boolean;        // 是否成功
  responseTime: number;    // 响应时间(ms)
  bookCount: number;       // 搜索到的书籍数量
  error?: string;          // 错误信息
}

export interface SourceStats {
  total: number;
  enabled: number;
  avgResponseTime: number;
}

/**
 * 在线书源信息
 * Online Source Info
 */
export interface OnlineSource {
  id: string;
  name: string;
  url: string;
  type: 'epub' | 'txt' | 'pdf' | 'web';
  category: string;
  language: string;
  weight: number;
  enabled: boolean;
}

/**
 * 导入结果
 * Import Result
 */
export interface ImportResult {
  success: number;
  fail: number;
  total: number;
  message: string;
}

/**
 * 书源服务类
 * Book Source Service Class
 * 管理在线书源的导入、搜索、测试等功能
 */
class BookSourceService {
  private static instance: BookSourceService;
  private sources: Map<string, BookSource> = new Map();
  private httpClients: http.HttpRequest[] = [];
  private isInitialized: boolean = false;
  private importer: BookSourceImporter = BookSourceImporter.getInstance();

  private constructor() {}

  /**
   * 获取单例实例
   * Get Singleton Instance
   */
  static getInstance(): BookSourceService {
    if (!BookSourceService.instance) {
      BookSourceService.instance = new BookSourceService();
    }
    return BookSourceService.instance;
  }

  /**
   * 初始化服务
   * Initialize Service
   */
  async init(): Promise<void> {
    this.isInitialized = true;
    console.info('[BookSource] Service initialized');
  }

  /**
   * 检查服务是否就绪
   * Check if service is ready
   */
  isReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 从URL 导入书源 (支持阅读3.0 Legado格式)
   * Import book sources from URL (supports Legado format)
   * @param url 书源JSON文件的URL
   * @returns 导入结果统计
   */
  async importFromUrl(url: string): Promise<ImportResult> {
    try {
      const result = await this.importer.importFromUrl(url);

      if (result.success > 0) {
        const sources = this.importer.parseAndImport(
          await this.fetchContent(url)
        );

        if (Array.isArray(sources)) {
          const sourceArray: BookSource[] = sources as BookSource[];
          for (let i = 0; i < sourceArray.length; i++) {
            this.sources.set(sourceArray[i].id, sourceArray[i]);
          }
        }
      }

      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: message
      };
    }
  }

  /**
   * 获取网络内容
   * Fetch network content
   * @param url 目标URL
   * @returns 内容字符串
   */
  private async fetchContent(url: string): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET
      });
      return response.result as string;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      throw new Error('Failed to fetch content: ' + message);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 解析 JSON 字符串导入 (阅读3.0格式)
   * Import from JSON string (Legado format)
   * @param jsonString 书源JSON字符串
   * @returns 导入结果统计
   */
  importFromJson(jsonString: string): ImportResult {
    try {
      const parsedData: Record<string, Object> = JSON.parse(jsonString);
      const legadoSources: LegadoBookSource[] = Array.isArray(parsedData) ? parsedData as LegadoBookSource[] : [];

      if (legadoSources.length === 0) {
        return {
          success: 0,
          fail: 0,
          total: 0,
          message: '无效的书源格式'
        };
      }

      let successCount = 0;
      const totalCount = legadoSources.length;

      for (let i = 0; i < totalCount; i++) {
        const legado: LegadoBookSource = legadoSources[i];
        if (legado.bookSourceName && legado.bookSourceUrl) {
          const source: BookSource = {
            id: 'source_' + Date.now() + '_' + i,
            name: legado.bookSourceName || '',
            url: legado.bookSourceUrl || '',
            enabled: true,
            weight: 1,
            priority: 1,
            bookSourceType: BookSourceType.TEXT,
            loginRequired: false
          };
          this.sources.set(source.id, source);
          successCount++;
        }
      }

      return {
        success: successCount,
        fail: totalCount - successCount,
        total: totalCount,
        message: '成功导入 ' + successCount + ' 个书源'
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '解析失败: ' + message
      };
    }
  }

  /**
   * 从Base64 导入
   * Import from Base64 string
   * @param base64String Base64编码的书源数据
   * @returns 导入结果统计
   */
  importFromBase64(base64String: string): ImportResult {
    try {
      const decoded = this.base64Decode(base64String);
      return this.importFromJson(decoded);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '解析失败: ' + message
      };
    }
  }

  /**
   * Base64解码
   * Base64 decode
   * @param str Base64字符串
   * @returns 解码后的字符串
   */
  private base64Decode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    let output = '';
    str = str.replace(new RegExp('=+$', ''), '');

    for (let bc = 0, bs = 0, buffer = 0; bc < str.length; bc++) {
      const i = chars.indexOf(str[bc]);
      if (i < 0) continue;
      buffer = (buffer << 6) + i;
      bs += 6;
      if (bs >= 8) {
        output += String.fromCharCode((buffer >> (bs - 8)) & 0xFF);
        bs -= 8;
      }
    }
    return output;
  }

  /**
   * 搜索书籍
   * Search Books
   * @param keyword 搜索关键词
   * @param sourceId 可选，指定书源ID
   * @returns 搜索结果数组
   */
  async searchBook(keyword: string, sourceId?: string): Promise<SourceSearchResult[]> {
    const results: SourceSearchResult[] = [];

    try {
      let sources: BookSource[] = [];
      if (sourceId) {
        const src = this.sources.get(sourceId);
        if (src) {
          sources = [src];
        }
      } else {
        const sourcesArr: BookSource[] = [];
        const valuesIterator = this.sources.values();
        let item = valuesIterator.next();
        while (!item.done) {
          sourcesArr.push(item.value);
          item = valuesIterator.next();
        }
        sources = sourcesArr;
      }

      for (let i = 0; i < sources.length; i++) {
        const source = sources[i];
        if (!source || !source.enabled || !source.ruleSearch) continue;

        try {
          const searchResults = await this.searchFromSource(source, keyword);
          for (let j = 0; j < searchResults.length; j++) {
            results.push(searchResults[j]);
          }
        } catch (error) {
          const message = error instanceof Error ? error.message : 'Unknown error';
          errorHandler.handle(new Error(message), { level: ErrorLevel.WARN });
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      errorHandler.handle(new Error(message));
    }

    return results;
  }

  /**
   * 从指定书源搜索
   * Search from specific source
   * @param source 书源对象
   * @param keyword 关键词
   * @returns 搜索结果
   */
  private async searchFromSource(source: BookSource, keyword: string): Promise<SourceSearchResult[]> {
    const results: SourceSearchResult[] = [];

    if (!source.url || !source.ruleSearch) {
      return results;
    }

    try {
      const searchUrl = source.url.replace('{{key}}', encodeURIComponent(keyword));

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(searchUrl, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 200) {
        const html = response.result as string;
        let bookListRule = '';
        if (typeof source.ruleSearch === 'object' && source.ruleSearch !== null) {
          bookListRule = (source.ruleSearch as SearchRule).bookList || '';
        }
        const books = this.parseBookList(html, bookListRule, source);

        for (let i = 0; i < books.length; i++) {
          results.push(books[i]);
        }
      }

      httpRequest.destroy();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      errorHandler.handle(new Error(message), { level: ErrorLevel.WARN });
    }

    return results;
  }

  /**
   * 解析书籍列表
   * Parse book list from HTML
   * @param html HTML内容
   * @param rule 解析规则
   * @param source 书源对象
   * @returns 书籍数据数组
   */
  private parseBookList(html: string, rule: string, source: BookSource): SourceSearchResult[] {
    const results: SourceSearchResult[] = [];

    try {
      const ruleSearch = source.ruleSearch;
      const searchRule = typeof ruleSearch === 'object' ? ruleSearch as SearchRule : null;
      const nameRule = searchRule ? searchRule.name : '';
      const authorRule = searchRule ? searchRule.author : '';
      const bookUrlRule = searchRule ? searchRule.bookUrl : '';
      const coverUrlRule = searchRule ? searchRule.coverUrl : '';

      const bookMatches = html.match(new RegExp('<li[^>]*>[\s\S]*?<\/li>', 'g')) || [];

      const limitCount = bookMatches.length < 20 ? bookMatches.length : 20;
      for (let i = 0; i < limitCount; i++) {
        const match = bookMatches[i];
        const nameMatch = nameRule ? this.extractRuleValue(match, nameRule) : '';
        const authorMatch = authorRule ? this.extractRuleValue(match, authorRule) : '未知作者';

        if (nameMatch) {
          results.push({
            bookName: nameMatch,
            author: authorMatch,
            coverUrl: coverUrlRule ? this.extractRuleValue(match, coverUrlRule) : '',
            bookUrl: bookUrlRule ? this.extractRuleValue(match, bookUrlRule) : '',
            sourceName: source.name,
            sourceId: source.id,
            latestChapter: '',
            intro: ''
          });
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      errorHandler.handle(new Error(message), { level: ErrorLevel.WARN });
    }

    return results;
  }

  /**
   * 根据规则提取值
   * Extract value by rule
   * @param html HTML内容
   * @param rule 提取规则
   * @returns 提取的值
   */
  private extractRuleValue(html: string, rule: string): string {
    try {
      if (rule.startsWith('class.')) {
        const className = rule.replace('class.', '');
        const match = html.match(new RegExp(`<[^>]*class=["']${className}["'][^>]*>([\\s\\S]*?)</[^>]+>`));
        return match ? this.stripHtml(match[1]) : '';
      }

      if (rule.startsWith('id.')) {
        const idName = rule.replace('id.', '');
        const match = html.match(new RegExp(`<[^>]*id=["']${idName}["'][^>]*>([\\s\\S]*?)</[^>]+>`));
        return match ? this.stripHtml(match[1]) : '';
      }

      if (rule.startsWith('tag.')) {
        const tagName = rule.replace('tag.', '');
        const match = html.match(new RegExp(`<${tagName}[^>]*>([\\s\\S]*?)</${tagName}>`));
        return match ? this.stripHtml(match[1]) : '';
      }

      if (rule.startsWith('text.')) {
        const textContent = rule.replace('text.', '');
        const match = html.match(new RegExp(`text\\.(${textContent})`));
        return match ? match[1] : '';
      }

      return this.stripHtml(rule);
    } catch {
      return '';
    }
  }

  /**
   * 去除HTML标签
   * Strip HTML tags
   * @param html HTML字符串
   * @returns 纯文本
   */
  private stripHtml(html: string): string {
    return html
      .replace(new RegExp('<[^>]*>', 'g'), '')
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('&quot;', 'g'), '"');
  }

  /**
   * 测试书源
   * Test Book Source
   * @param source 要测试的书源
   * @returns 测试结果
   */
  async testSource(source: BookSource): Promise<SourceTestResult> {
    const startTime = Date.now();

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(source.url, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      const responseTime = Date.now() - startTime;
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const html = response.result as string;
        const bookCount = (html.match(new RegExp('<li', 'g')) || []).length;

        return {
          sourceId: source.id,
          sourceName: source.name,
          success: true,
          responseTime,
          bookCount
        };
      }

      return {
        sourceId: source.id,
        sourceName: source.name,
        success: false,
        responseTime: Date.now() - startTime,
        bookCount: 0,
        error: 'HTTP ' + response.responseCode
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return {
        sourceId: source.id,
        sourceName: source.name,
        success: false,
        responseTime: Date.now() - startTime,
        bookCount: 0,
        error: message
      };
    }
  }

  async testAllSources(): Promise<SourceTestResult[]> {
    const results: SourceTestResult[] = [];
    const allSources: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      allSources.push(item.value);
      item = valuesIterator.next();
    }

    for (let i = 0; i < allSources.length; i++) {
      const source = allSources[i];
      if (source.enabled) {
        const testResult = await this.testSource(source);
        results.push(testResult);
        await new Promise<void>(resolve => setTimeout(resolve, 500));
      }
    }

    return results;
  }

  getSources(): BookSource[] {
    const result: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      result.push(item.value);
      item = valuesIterator.next();
    }
    return result;
  }

  getEnabledSources(): BookSource[] {
    const enabled: BookSource[] = [];
    const allSources: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      allSources.push(item.value);
      item = valuesIterator.next();
    }
    for (let i = 0; i < allSources.length; i++) {
      if (allSources[i].enabled) {
        enabled.push(allSources[i]);
      }
    }
    return enabled;
  }

  getSourceById(id: string): BookSource | undefined {
    return this.sources.get(id);
  }

  /**
   * 添加书源
   * Add source
   * @param source 书源对象
   */
  addSource(source: BookSource): void {
    this.sources.set(source.id, source);
  }

  /**
   * 移除书源
   * Remove source
   * @param id 书源ID
   */
  removeSource(id: string): void {
    this.sources.delete(id);
  }

  /**
   * 启用书源
   * Enable source
   * @param id 书源ID
   */
  enableSource(id: string): void {
    const source = this.sources.get(id);
    if (source) {
      source.enabled = true;
      this.sources.set(id, source);
    }
  }

  /**
   * 禁用书源
   * Disable source
   * @param id 书源ID
   */
  disableSource(id: string): void {
    const source = this.sources.get(id);
    if (source) {
      source.enabled = false;
      this.sources.set(id, source);
    }
  }

  /**
   * 获取书源总数
   * Get total source count
   * @returns 书源数量
   */
  getSourceCount(): number {
    return this.sources.size;
  }

  /**
   * 获取启用的书源数
   * Get enabled source count
   * @returns 启用的书源数量
   */
  getEnabledSourceCount(): number {
    return this.getEnabledSources().length;
  }

  /**
   * 获取排序后的书源(按权重)
   * Get ranked sources by weight
   * @returns 排序后的书源数组
   */
  getRankingSources(): BookSource[] {
    const allSources: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      allSources.push(item.value);
      item = valuesIterator.next();
    }
    const enabledSources: BookSource[] = [];
    for (let i = 0; i < allSources.length; i++) {
      if (allSources[i].enabled) {
        enabledSources.push(allSources[i]);
      }
    }
    const sortedSources: BookSource[] = [];
    for (let i = 0; i < enabledSources.length; i++) {
      sortedSources.push(enabledSources[i]);
    }
    for (let i = 0; i < sortedSources.length; i++) {
      for (let j = i + 1; j < sortedSources.length; j++) {
        const weightA = sortedSources[i].weight || 0;
        const weightB = sortedSources[j].weight || 0;
        if (weightB > weightA) {
          const temp = sortedSources[i];
          sortedSources[i] = sortedSources[j];
          sortedSources[j] = temp;
        }
      }
    }
    return sortedSources;
  }

  /**
   * 按分类获取书源
   * Get sources by category
   * @param category 分类名称
   * @returns 该书源的书源数组
   */
  getSourcesByCategory(category: string): BookSource[] {
    const results: BookSource[] = [];
    const allSources: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      allSources.push(item.value);
      item = valuesIterator.next();
    }
    for (let i = 0; i < allSources.length; i++) {
      if (allSources[i].weight > 0) {
        results.push(allSources[i]);
      }
    }
    return results;
  }

  async fetchBookContent(bookUrl: string, sourceId: string): Promise<string> {
    const source = this.sources.get(sourceId);
    if (!source || !source.ruleContent) {
      return '';
    }

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(bookUrl, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      httpRequest.destroy();

      if (response.responseCode === 200) {
        const html = response.result as string;
        let contentRule = '';
        if (typeof source.ruleContent === 'object' && source.ruleContent !== null) {
          contentRule = (source.ruleContent as ContentRule).content || '';
        }
        return this.extractRuleValue(html, contentRule);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[BookSource] Fetch content error:', message);
    }

    return '';
  }

  getSourceStats(): SourceStats {
    const allSources: BookSource[] = [];
    const valuesIterator = this.sources.values();
    let item = valuesIterator.next();
    while (!item.done) {
      allSources.push(item.value);
      item = valuesIterator.next();
    }
    let enabledCount = 0;
    for (let i = 0; i < allSources.length; i++) {
      if (allSources[i].enabled) {
        enabledCount++;
      }
    }
    const stats: SourceStats = {
      total: allSources.length,
      enabled: enabledCount,
      avgResponseTime: 1500
    };
    return stats;
  }
}

export const bookSourceService = BookSourceService.getInstance();
export default bookSourceService;
