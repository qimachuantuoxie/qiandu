import { logger } from '../../../utils/Logger';
// 涔︽簮鏈嶅姟 - 缃戠粶涔︾睄鎼滅储涓庡�鍏?// Book Source Service - Network Book Search & Import
// 鏀�寔闃呰�3.0 (Legado) 涔︽簮鏍煎紡鐨勫�鍏ャ€佹悳绱㈠拰娴嬭瘯
// 鎻愪緵鍦ㄧ嚎涔︽簮绠＄悊鍜屼功绫嶅唴瀹硅幏鍙栧姛鑳?
import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, SearchRule, ContentRule } from '../../models/BookSourceModel';
import { BookSourceImporter, LegadoBookSource } from '../../utils/BookSourceImporter';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

/**
 * 缃戠粶涔︽簮鎼滅储缁撴灉
 * Source Search Result
 */
export interface SourceSearchResult {
  bookName: string;        // 涔﹀悕
  author: string;          // 浣滆€?  coverUrl: string;        // 灏侀潰URL
  bookUrl: string;         // 涔︾睄璇︽儏椤礥RL
  sourceName: string;      // 鏉ユ簮鍚嶇О
  sourceId: string;        // 鏉ユ簮ID
  latestChapter: string;   // 鏈€鏂扮珷鑺?  intro: string;           // 绠€浠?}

/**
 * 涔︽簮娴嬭瘯缁撴灉
 * Source Test Result
 */
export interface SourceTestResult {
  sourceId: string;        // 鏉ユ簮ID
  sourceName: string;      // 鏉ユ簮鍚嶇О
  success: boolean;        // 鏄�惁鎴愬姛
  responseTime: number;    // 鍝嶅簲鏃堕棿(ms)
  bookCount: number;       // 鎼滅储鍒扮殑涔︾睄鏁伴噺
  error?: string;          // 閿欒�淇℃伅
}

export interface SourceStats {
  total: number;
  enabled: number;
  avgResponseTime: number;
}

/**
 * 鍦ㄧ嚎涔︽簮淇℃伅
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
 * 瀵煎叆缁撴灉
 * Import Result
 */
export interface ImportResult {
  success: number;
  fail: number;
  total: number;
  message: string;
}

/**
 * 涔︽簮鏈嶅姟绫? * Book Source Service Class
 * 绠＄悊鍦ㄧ嚎涔︽簮鐨勫�鍏ャ€佹悳绱€€佹祴璇曠瓑鍔熻兘
 */
class BookSourceService {
  private static instance: BookSourceService;
  private sources: Map<string, BookSource> = new Map();
  private httpClients: http.HttpRequest[] = [];
  private isInitialized: boolean = false;
  private importer: BookSourceImporter = BookSourceImporter.getInstance();

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   * Get Singleton Instance
   */
  static getInstance(): BookSourceService {
    if (!BookSourceService.instance) {
      BookSourceService.instance = new BookSourceService();
    }
    return BookSourceService.instance;
  }

  /**
   * 鍒濆�鍖栨湇鍔?   * Initialize Service
   */
  async init(): Promise<void> {
    this.isInitialized = true;
    logger.info('[BookSource] Service initialized');
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?   * Check if service is ready
   */
  isReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 浠嶶RL 瀵煎叆涔︽簮 (鏀�寔闃呰�3.0 Legado鏍煎紡)
   * Import book sources from URL (supports Legado format)
   * @param url 涔︽簮JSON鏂囦欢鐨刄RL
   * @returns 瀵煎叆缁撴灉缁熻�
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
   * 鑾峰彇缃戠粶鍐呭�
   * Fetch network content
   * @param url 鐩�爣URL
   * @returns 鍐呭�瀛楃�涓?   */
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
   * 瑙ｆ瀽 JSON 瀛楃�涓插�鍏?(闃呰�3.0鏍煎紡)
   * Import from JSON string (Legado format)
   * @param jsonString 涔︽簮JSON瀛楃�涓?   * @returns 瀵煎叆缁撴灉缁熻�
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
          message: '鏃犳晥鐨勪功婧愭牸寮?
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
        message: '鎴愬姛瀵煎叆 ' + successCount + ' 涓�功婧?
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return {
        success: 0,
        fail: 0,
        total: 0,
        message: '瑙ｆ瀽澶辫触: ' + message
      };
    }
  }

  /**
   * 浠嶣ase64 瀵煎叆
   * Import from Base64 string
   * @param base64String Base64缂栫爜鐨勪功婧愭暟鎹?   * @returns 瀵煎叆缁撴灉缁熻�
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
        message: '瑙ｆ瀽澶辫触: ' + message
      };
    }
  }

  /**
   * Base64瑙ｇ爜
   * Base64 decode
   * @param str Base64瀛楃�涓?   * @returns 瑙ｇ爜鍚庣殑瀛楃�涓?   */
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
   * 鎼滅储涔︾睄
   * Search Books
   * @param keyword 鎼滅储鍏抽敭璇?   * @param sourceId 鍙�€夛紝鎸囧畾涔︽簮ID
   * @returns 鎼滅储缁撴灉鏁扮粍
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
   * 浠庢寚瀹氫功婧愭悳绱?   * Search from specific source
   * @param source 涔︽簮瀵硅薄
   * @param keyword 鍏抽敭璇?   * @returns 鎼滅储缁撴灉
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
   * 瑙ｆ瀽涔︾睄鍒楄〃
   * Parse book list from HTML
   * @param html HTML鍐呭�
   * @param rule 瑙ｆ瀽瑙勫垯
   * @param source 涔︽簮瀵硅薄
   * @returns 涔︾睄鏁版嵁鏁扮粍
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
        const authorMatch = authorRule ? this.extractRuleValue(match, authorRule) : '鏈�煡浣滆€?;

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
   * 鏍规嵁瑙勫垯鎻愬彇鍊?   * Extract value by rule
   * @param html HTML鍐呭�
   * @param rule 鎻愬彇瑙勫垯
   * @returns 鎻愬彇鐨勫€?   */
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
   * 鍘婚櫎HTML鏍囩�
   * Strip HTML tags
   * @param html HTML瀛楃�涓?   * @returns 绾�枃鏈?   */
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
   * 娴嬭瘯涔︽簮
   * Test Book Source
   * @param source 瑕佹祴璇曠殑涔︽簮
   * @returns 娴嬭瘯缁撴灉
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
   * 娣诲姞涔︽簮
   * Add source
   * @param source 涔︽簮瀵硅薄
   */
  addSource(source: BookSource): void {
    this.sources.set(source.id, source);
  }

  /**
   * 绉婚櫎涔︽簮
   * Remove source
   * @param id 涔︽簮ID
   */
  removeSource(id: string): void {
    this.sources.delete(id);
  }

  /**
   * 鍚�敤涔︽簮
   * Enable source
   * @param id 涔︽簮ID
   */
  enableSource(id: string): void {
    const source = this.sources.get(id);
    if (source) {
      source.enabled = true;
      this.sources.set(id, source);
    }
  }

  /**
   * 绂佺敤涔︽簮
   * Disable source
   * @param id 涔︽簮ID
   */
  disableSource(id: string): void {
    const source = this.sources.get(id);
    if (source) {
      source.enabled = false;
      this.sources.set(id, source);
    }
  }

  /**
   * 鑾峰彇涔︽簮鎬绘暟
   * Get total source count
   * @returns 涔︽簮鏁伴噺
   */
  getSourceCount(): number {
    return this.sources.size;
  }

  /**
   * 鑾峰彇鍚�敤鐨勪功婧愭暟
   * Get enabled source count
   * @returns 鍚�敤鐨勪功婧愭暟閲?   */
  getEnabledSourceCount(): number {
    return this.getEnabledSources().length;
  }

  /**
   * 鑾峰彇鎺掑簭鍚庣殑涔︽簮(鎸夋潈閲?
   * Get ranked sources by weight
   * @returns 鎺掑簭鍚庣殑涔︽簮鏁扮粍
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
   * 鎸夊垎绫昏幏鍙栦功婧?   * Get sources by category
   * @param category 鍒嗙被鍚嶇О
   * @returns 璇ヤ功婧愮殑涔︽簮鏁扮粍
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
      logger.error('[BookSource] Fetch content error:', message);
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
