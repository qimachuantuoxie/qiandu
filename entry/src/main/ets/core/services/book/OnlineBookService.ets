import { logger } from '../../../utils/Logger';
/**
 * 鍦ㄧ嚎涔︾睄鏈嶅姟 - 瀹屾暣鐨勭綉缁滀功绫嶆悳绱€€佽�鎯呫€佺洰褰曘€佸唴瀹硅幏鍙?
 *
 * @since 2.8.0
 */

import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, SearchRule, BookInfoRule, ContentRule, TocRule } from '../../models/BookSourceModel';
import { bookSourceService } from './BookSourceService';
import { OnlineSearchResult, OnlineBookDetail, OnlineChapterInfo } from '../../models/OnlineBookModel';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

/**
 * 鍦ㄧ嚎涔︾睄鏈嶅姟
 */
class OnlineBookService {
  private static instance: OnlineBookService;

  // 绔犺妭鍐呭�缂撳瓨
  private chapterCache: Map<string, string> = new Map();
  // 鐩�綍缂撳瓨
  private tocCache: Map<string, OnlineChapterInfo[]> = new Map();
  // 璇︽儏缂撳瓨
  private detailCache: Map<string, OnlineBookDetail> = new Map();

  private constructor() {}

  static getInstance(): OnlineBookService {
    if (!OnlineBookService.instance) {
      OnlineBookService.instance = new OnlineBookService();
    }
    return OnlineBookService.instance;
  }

  // ==================== 鍦ㄧ嚎鎼滅储 ====================

  /**
   * 鍦ㄧ嚎鎼滅储涔︾睄
   * @param keyword 鎼滅储鍏抽敭璇?
   * @param sourceId 涔︽簮ID锛堝彲閫夛紝涓嶄紶鍒欐悳绱㈡墍鏈変功婧愶級
   * @returns 鎼滅储缁撴灉
   */
  async searchOnlineBooks(keyword: string, sourceId?: string): Promise<OnlineSearchResult[]> {
    logger.info('[OnlineBook] Searching for:', keyword, 'sourceId:', sourceId);

    try {
      // 鑾峰彇涔︽簮
      let sources: BookSource[] = [];
      if (sourceId) {
        const src = bookSourceService.getSourceById(sourceId);
        if (src) {
          sources = [src];
        }
      } else {
        sources = bookSourceService.getEnabledSources();
      }

      if (sources.length === 0) {
        logger.warn('[OnlineBook] No sources available');
        return [];
      }

      // 骞惰�鎼滅储鎵€鏈変功婧?
      const searchPromises: Promise<OnlineSearchResult[]>[] = [];
      for (let i = 0; i < sources.length; i++) {
        searchPromises.push(this.searchFromSource(sources[i] as BookSource, keyword));
      }

      const results = await Promise.all(searchPromises);

      // 鍚堝苟缁撴灉
      const allResults: OnlineSearchResult[] = [];
      for (let i = 0; i < results.length; i++) {
        const r = results[i];
        for (let j = 0; j < r.length; j++) {
          allResults.push(r[j]);
        }
      }

      logger.info('[OnlineBook] Search complete, found', allResults.length, 'results');
      return allResults;
    } catch (error) {
      const errorErr = error as Error;
      errorHandler.handle(errorErr, { level: ErrorLevel.WARN });
      return [];
    }
  }

  /**
   * 浠庡崟涓�功婧愭悳绱?
   */
  private async searchFromSource(source: BookSource, keyword: string): Promise<OnlineSearchResult[]> {
    try {
      if (!source.enabled || !source.ruleSearch) {
        return [];
      }

      // 鏋勫缓鎼滅储URL
      const searchUrl = this.buildSearchUrl(source, keyword);
      if (!searchUrl) {
        return [];
      }

      // 鍙戦€丠TTP璇锋眰
      const html = await this.fetchUrl(searchUrl);
      if (!html) {
        return [];
      }

      // 瑙ｆ瀽鎼滅储缁撴灉
      return this.parseSearchResults(html, source);
    } catch (error) {
      const errorErr = error as Error;
      logger.error('[OnlineBook] Source search failed:', source.name, errorErr.message);
      return [];
    }
  }

  /**
   * 鏋勫缓鎼滅储URL
   */
  private buildSearchUrl(source: BookSource, keyword: string): string | null {
    try {
      const searchRule = typeof source.ruleSearch === 'object'
        ? source.ruleSearch as SearchRule
        : null;

      // 浼樺厛浣跨敤鎼滅储URL
      if (searchRule && searchRule.searchUrl) {
        return searchRule.searchUrl
          .replace('{{key}}', encodeURIComponent(keyword))
          .replace('{{key+}}', keyword);
      }

      // 鍥為€€鍒颁功婧怳RL
      if (source.url) {
        return source.url
          .replace('{{key}}', encodeURIComponent(keyword))
          .replace('{{key+}}', keyword);
      }

      return null;
    } catch (error) {
      const errorErr = error as Error;
      logger.error(errorErr.message);
      return null;
    }
  }

  /**
   * 瑙ｆ瀽鎼滅储缁撴灉
   */
  private parseSearchResults(html: string, source: BookSource): OnlineSearchResult[] {
    try {
      const searchRule = typeof source.ruleSearch === 'object'
        ? source.ruleSearch as SearchRule
        : null;

      if (!searchRule) {
        return [];
      }

      const results: OnlineSearchResult[] = [];

      // 鑾峰彇涔︾睄鍒楄〃瀹瑰櫒
      const listRule = searchRule.bookList || '';
      const books: string[] = listRule
        ? RuleEngine.extractAllFromHtml(html, listRule)
        : [html];

      // 鎻愬彇姣忔湰涔︾殑淇℃伅
      for (let i = 0; i < books.length; i++) {
        const bookHtml = books[i];
        // TODO: 瀹炵幇涔︾睄淇℃伅鎻愬彇閫昏緫
      }

      return results;
    } catch (error) {
      const errorErr = error as Error;
      logger.error(errorErr.message);
      return [];
    }
  }

  // ==================== 涔︾睄璇︽儏 ====================

  /**
   * 鑾峰彇涔︾睄璇︽儏
   * @param bookUrl 涔︾睄璇︽儏椤礥RL
   * @param sourceId 涔︽簮ID
   * @returns 涔︾睄璇︽儏
   */
  async getBookDetail(bookUrl: string, sourceId: string): Promise<OnlineBookDetail | null> {
    try {
      // 妫€鏌ョ紦瀛?
      const cacheKey = sourceId + '_' + bookUrl;
      if (this.detailCache.has(cacheKey)) {
        const cached = this.detailCache.get(cacheKey);
        if (cached) {
          return cached;
        }
      }

      const source = bookSourceService.getSourceById(sourceId);
      if (!source || !source.ruleBookInfo) {
        return null;
      }

      // 鑾峰彇璇︽儏椤礖TML
      const fullUrl = this.resolveRelativeUrl(source.url, bookUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return null;
      }

      // 瑙ｆ瀽璇︽儏
      const detail = this.parseBookDetail(html, source);

      if (detail) {
        detail.sourceId = sourceId;
        detail.bookUrl = fullUrl;
        this.detailCache.set(cacheKey, detail);
      }

      return detail;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return null;
    }
  }

  /**
   * 瑙ｆ瀽涔︾睄璇︽儏
   */
  private parseBookDetail(html: string, source: BookSource): OnlineBookDetail | null {
    try {
      const bookInfoRule = typeof source.ruleBookInfo === 'object'
        ? source.ruleBookInfo as BookInfoRule
        : null;

      if (!bookInfoRule) {
        return null;
      }

      const title: string = bookInfoRule.name
        ? RuleEngine.extractFromHtml(html, bookInfoRule.name) as string
        : '';

      const author: string = bookInfoRule.author
        ? RuleEngine.extractFromHtml(html, bookInfoRule.author) as string
        : '鏈�煡浣滆€?;

      const coverUrl: string = bookInfoRule.coverUrl
        ? RuleEngine.extractFromHtml(html, bookInfoRule.coverUrl) as string
        : '';

      const intro: string = bookInfoRule.intro
        ? RuleEngine.extractFromHtml(html, bookInfoRule.intro) as string
        : '';

      const latestChapter: string = bookInfoRule.lastChapter
        ? RuleEngine.extractFromHtml(html, bookInfoRule.lastChapter) as string
        : '';

      const wordCountStr: string = bookInfoRule.wordCount
        ? RuleEngine.extractFromHtml(html, bookInfoRule.wordCount) as string
        : '';

      const wordCount = parseInt(wordCountStr.replace(new RegExp('[^0-9]', 'g'), ''), 10) || 0;

      return {
        title,
        author,
        coverUrl,
        bookUrl: '',
        sourceId: '',
        intro,
        latestChapter,
        wordCount,
        updateTime: '',
        category: '',
        status: ''
      };
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return null;
    }
  }

  // ==================== 鐩�綍鑾峰彇 ====================

  /**
   * 鑾峰彇涔︾睄鐩�綍
   * @param bookUrl 涔︾睄璇︽儏椤礥RL
   * @param sourceId 涔︽簮ID
   * @returns 绔犺妭鍒楄〃
   */
  async fetchToc(bookUrl: string, sourceId: string): Promise<OnlineChapterInfo[]> {
    try {
      // 妫€鏌ョ紦瀛?
      const cacheKey = sourceId + '_' + bookUrl;
      if (this.tocCache.has(cacheKey)) {
        const cached = this.tocCache.get(cacheKey);
        if (cached) {
          return cached;
        }
      }

      const source = bookSourceService.getSourceById(sourceId);
      if (!source || !source.ruleToc) {
        return [];
      }

      // 鑾峰彇鐩�綍椤礖TML
      const fullUrl = this.resolveRelativeUrl(source.url, bookUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return [];
      }

      // 瑙ｆ瀽鐩�綍
      const toc = this.parseToc(html, source);

      if (toc.length > 0) {
        this.tocCache.set(cacheKey, toc);
      }

      return toc;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return [];
    }
  }

  /**
   * 瑙ｆ瀽鐩�綍
   */
  private parseToc(html: string, source: BookSource): OnlineChapterInfo[] {
    try {
      const tocRule = typeof source.ruleToc === 'object'
        ? source.ruleToc as TocRule
        : null;

      if (!tocRule) {
        return [];
      }

      const chapters: OnlineChapterInfo[] = [];

      // 鑾峰彇绔犺妭鍒楄〃瀹瑰櫒
      const tocListRule = tocRule.tocList || '';
      const chapterItems: string[] = tocListRule
        ? RuleEngine.extractAllFromHtml(html, tocListRule)
        : [];

      // 鎻愬彇姣忎釜绔犺妭
      for (let i = 0; i < chapterItems.length; i++) {
        const itemHtml: string = chapterItems[i];

        const title: string = tocRule.chapterName
          ? RuleEngine.extractFromHtml(itemHtml, tocRule.chapterName) as string
          : '';

        const url: string = tocRule.chapterUrl
          ? RuleEngine.extractFromHtml(itemHtml, tocRule.chapterUrl) as string
          : '';

        if (!title || !url) continue;

        chapters.push({
          index: i,
          title: title.trim(),
          url,
          isVip: false,
          wordCount: 0,
          updateTime: ''
        });
      }

      return chapters;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return [];
    }
  }

  // ==================== 绔犺妭鍐呭�鑾峰彇 ====================

  /**
   * 鑾峰彇绔犺妭鍐呭�
   * @param chapterUrl 绔犺妭URL
   * @param sourceId 涔︽簮ID
   * @returns 绔犺妭鍐呭�
   */
  async fetchChapterContent(chapterUrl: string, sourceId: string): Promise<string> {
    try {
      // 妫€鏌ョ紦瀛?
      const cacheKey = sourceId + '_' + chapterUrl;
      if (this.chapterCache.has(cacheKey)) {
        const cached = this.chapterCache.get(cacheKey);
        if (cached) {
          return cached;
        }
      }

      const source = bookSourceService.getSourceById(sourceId);
      if (!source || !source.ruleContent) {
        return '';
      }

      // 鑾峰彇绔犺妭HTML
      const fullUrl = this.resolveRelativeUrl(source.url, chapterUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return '';
      }

      // 鎻愬彇鍐呭�
      const content = this.parseChapterContent(html, source);

      if (content) {
        this.chapterCache.set(cacheKey, content);
      }

      return content;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return '';
    }
  }

  /**
   * 瑙ｆ瀽绔犺妭鍐呭�
   */
  private parseChapterContent(html: string, source: BookSource): string {
    try {
      const contentRule = typeof source.ruleContent === 'object'
        ? source.ruleContent as ContentRule
        : null;

      if (!contentRule || !contentRule.content) {
        return '';
      }

      // 鎻愬彇姝ｆ枃鍐呭�
      let content: string = RuleEngine.extractFromHtml(html, contentRule.content) as string;

      // 鍐呭�鍑€鍖?
      content = this.cleanContent(content);

      // 搴旂敤鏇挎崲瑙勫垯
      if (contentRule.replaceRegex) {
        try {
          const parts = contentRule.replaceRegex.split('&&');
          if (parts.length >= 2) {
            const pattern = parts[0];
            const replacement = parts[1] || '';
            content = content.replace(new RegExp(pattern, 'g'), replacement);
          }
        } catch (e) {
          logger.warn('[OnlineBook] Replace regex failed:', e);
        }
      }

      return content;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error(errorErr.message);
      return '';
    }
  }

  /**
   * 鍐呭�鍑€鍖?
   */
  private cleanContent(content: string): string {
    return content
      // 绉婚櫎澶氫綑绌虹櫧
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('<[^>]+>', 'g'), '')
      // 绉婚櫎骞垮憡鏍囪�
      .replace(new RegExp('\[.*?骞垮憡.*?\]', 'g'), '')
      .replace(new RegExp('\[.*?www\..*?\]', 'g'), '')
      // 瑙勮寖鍖栨崲琛?
      .replace(new RegExp('\r\n', 'g'), '\n')
      .replace(new RegExp('\n{3,}', 'g'), '\n\n')
      .trim();
  }

  // ==================== 宸ュ叿鏂规硶 ====================

  /**
   * HTTP GET 璇锋眰
   */
  private async fetchUrl(url: string): Promise<string | null> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8'
        },
        connectTimeout: 15000,
        readTimeout: 15000
      });

      if (response.responseCode === 200 && response.result) {
        const content = response.result as string;
        httpRequest.destroy();
        return content;
      }

      httpRequest.destroy();
      return null;
    } catch (error) {
      const errorErr = error instanceof Error ? error : new Error(String(error));
      logger.error('[OnlineBook] HTTP request failed:', url, errorErr.message);
      return null;
    }
  }

  /**
   * 瑙ｆ瀽鐩稿�URL
   */
  private resolveRelativeUrl(baseUrl: string, relativeUrl: string): string {
    if (!relativeUrl) return '';
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }
    if (relativeUrl.startsWith('//')) {
      return 'https:' + relativeUrl;
    }
    if (relativeUrl.startsWith('/')) {
      try {
        const protocolEnd = baseUrl.indexOf('://');
        const protocol = protocolEnd > 0 ? baseUrl.substring(0, protocolEnd + 3) : 'https://';
        const hostStart = protocol.length;
        const hostEnd = baseUrl.indexOf('/', hostStart);
        const host = hostEnd > 0 ? baseUrl.substring(hostStart, hostEnd) : baseUrl.substring(hostStart);
        return protocol + host + relativeUrl;
      } catch {
        return relativeUrl;
      }
    }
    // 鐩稿�璺�緞
    try {
      const protocolEnd = baseUrl.indexOf('://');
      const protocol = protocolEnd > 0 ? baseUrl.substring(0, protocolEnd + 3) : 'https://';
      const hostStart = protocol.length;
      const hostEnd = baseUrl.indexOf('/', hostStart);
      const host = hostEnd > 0 ? baseUrl.substring(hostStart, hostEnd) : baseUrl.substring(hostStart);
      const pathEnd = baseUrl.indexOf('?', hostStart > 0 ? hostStart : 0);
      const path = pathEnd > 0 ? baseUrl.substring(hostStart, pathEnd) : baseUrl.substring(hostStart);
      const basePath = path.substring(0, path.lastIndexOf('/') + 1);
      return protocol + host + basePath + relativeUrl;
    } catch {
      return relativeUrl;
    }
  }

  /**
   * 娓呴櫎缂撳瓨
   */
  clearCache(): void {
    this.chapterCache.clear();
    this.tocCache.clear();
    this.detailCache.clear();
  }
}

/**
 * RuleEngine - 鏈�湴瑙勫垯寮曟搸瀹炵幇
 * 鐢ㄤ簬浠嶩TML涓�牴鎹��鍒欐彁鍙栧唴瀹?
 */
class RuleEngine {
  static extractFromHtml(html: string, rule: string): string {
    try {
      if (!rule) return '';
      if (rule.startsWith('class.')) {
        const className = rule.replace('class.', '');
        const regex = new RegExp(`<[^>]*class=["']${className}["'][^>]*>([\\s\\S]*?)</[^>]+>`);
        const match = html.match(regex);
        return match ? RuleEngine.stripHtml(match[1]) : '';
      }
      if (rule.startsWith('id.')) {
        const idName = rule.replace('id.', '');
        const regex = new RegExp(`<[^>]*id=["']${idName}["'][^>]*>([\\s\\S]*?)</[^>]+>`);
        const match = html.match(regex);
        return match ? RuleEngine.stripHtml(match[1]) : '';
      }
      if (rule.startsWith('tag.')) {
        const tagName = rule.replace('tag.', '');
        const regex = new RegExp(`<${tagName}[^>]*>([\\s\\S]*?)</${tagName}>`);
        const match = html.match(regex);
        return match ? RuleEngine.stripHtml(match[1]) : '';
      }
      if (rule.startsWith('text.')) {
        const textContent = rule.replace('text.', '');
        const match = html.match(new RegExp(`text\\.(${textContent})`));
        return match ? match[1] : '';
      }
      return RuleEngine.stripHtml(rule);
    } catch {
      return '';
    }
  }

  static extractAllFromHtml(html: string, rule: string): string[] {
    try {
      if (!rule) return [];
      if (rule.startsWith('class.')) {
        const className = rule.replace('class.', '');
        const regex = new RegExp(`<[^>]*class=["']${className}["'][^>]*>([\\s\\S]*?)</[^>]+>`, 'g');
        const matches: string[] = [];
        let match = regex.exec(html);
        while (match) {
          matches.push(RuleEngine.stripHtml(match[1]));
          match = regex.exec(html);
        }
        return matches;
      }
      if (rule.startsWith('tag.')) {
        const tagName = rule.replace('tag.', '');
        const regex = new RegExp(`<${tagName}[^>]*>([\\s\\S]*?)</${tagName}>`, 'g');
        const matches: string[] = [];
        let match = regex.exec(html);
        while (match) {
          matches.push(RuleEngine.stripHtml(match[1]));
          match = regex.exec(html);
        }
        return matches;
      }
      const regex = new RegExp(rule, 'g');
      const matches: string[] = [];
      let match = regex.exec(html);
      while (match) {
        matches.push(match[1] || match[0]);
        match = regex.exec(html);
      }
      return matches;
    } catch {
      return [];
    }
  }

  private static stripHtml(html: string): string {
    return html
      .replace(new RegExp('<[^>]*>', 'g'), '')
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('&quot;', 'g'), '"');
  }
}

// 瀵煎嚭鍗曚緥
export const onlineBookService = OnlineBookService.getInstance();
export default onlineBookService;



