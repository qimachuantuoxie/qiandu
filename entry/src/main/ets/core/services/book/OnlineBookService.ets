import { logger } from '../../../utils/Logger';
/**
 * 在线书籍服务 - 完整的网络书籍搜索、详情、目录、内容获取
 *
 * @since 2.8.0
 */

import { http } from '@kit.NetworkKit';
import { BookSource, BookSourceType, SearchRule, BookInfoRule, ContentRule, TocRule } from '../models/BookSourceModel';
import { bookSourceService } from './BookSourceService';
import { OnlineSearchResult, OnlineBookDetail, OnlineChapterInfo } from '../models/OnlineBookModel';
import { errorHandler, ErrorLevel } from '../utils/ErrorHandler';

/**
 * 在线书籍服务
 */
class OnlineBookService {
  private static instance: OnlineBookService;

  // 章节内容缓存
  private chapterCache: Map<string, string> = new Map();
  // 目录缓存
  private tocCache: Map<string, OnlineChapterInfo[]> = new Map();
  // 详情缓存
  private detailCache: Map<string, OnlineBookDetail> = new Map();

  private constructor() {}

  static getInstance(): OnlineBookService {
    if (!OnlineBookService.instance) {
      OnlineBookService.instance = new OnlineBookService();
    }
    return OnlineBookService.instance;
  }

  // ==================== 在线搜索 ====================

  /**
   * 在线搜索书籍
   * @param keyword 搜索关键词
   * @param sourceId 书源ID（可选，不传则搜索所有书源）
   * @returns 搜索结果
   */
  async searchOnlineBooks(keyword: string, sourceId?: string): Promise<OnlineSearchResult[]> {
    logger.info('[OnlineBook] Searching for:', keyword, 'sourceId:', sourceId);

    try {
      // 获取书源
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

      // 并发搜索所有书源
      const searchPromises: Promise<OnlineSearchResult[]>[] = [];
      for (let i = 0; i < sources.length; i++) {
        searchPromises.push(this.searchFromSource(sources[i] as BookSource, keyword));
      }

      const results = await Promise.all(searchPromises);

      // 合并结果
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
   * 从单一书源搜索
   */
  private async searchFromSource(source: BookSource, keyword: string): Promise<OnlineSearchResult[]> {
    try {
      if (!source.enabled || !source.ruleSearch) {
        return [];
      }

      // 构建搜索URL
      const searchUrl = this.buildSearchUrl(source, keyword);
      if (!searchUrl) {
        return [];
      }

      // 发送HTTP请求
      const html = await this.fetchUrl(searchUrl);
      if (!html) {
        return [];
      }

      // 解析搜索结果
      return this.parseSearchResults(html, source);
    } catch (error) {
      const errorErr = error as Error;
      logger.error('[OnlineBook] Source search failed:', source.name, errorErr.message);
      return [];
    }
  }

  /**
   * 构建搜索URL
   */
  private buildSearchUrl(source: BookSource, keyword: string): string | null {
    try {
      const searchRule = typeof source.ruleSearch === 'object'
        ? source.ruleSearch as SearchRule
        : null;

      // 优先使用搜索URL
      if (searchRule && searchRule.searchUrl) {
        return searchRule.searchUrl
          .replace('{{key}}', encodeURIComponent(keyword))
          .replace('{{key+}}', keyword);
      }

      // 回退到书源URL
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
   * 解析搜索结果
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

      // 获取书籍列表容器
      const listRule = searchRule.bookList || '';
      const books: string[] = listRule
        ? RuleEngine.extractAllFromHtml(html, listRule)
        : [html];

      // 提取每本书的信息
      for (let i = 0; i < books.length; i++) {
        const bookHtml = books[i];
        
        // 提取书名
        const title: string = searchRule.bookName
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.bookName) as string
          : '';
        
        if (!title) continue; // 跳过没有书名的结果
        
        // 提取作者
        const author: string = searchRule.author
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.author) as string
          : '未知作者';
        
        // 提取封面
        const coverUrl: string = searchRule.coverUrl
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.coverUrl) as string
          : '';
        
        // 提取书籍链接
        const bookUrl: string = searchRule.bookUrl
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.bookUrl) as string
          : '';
        
        // 提取最新章节
        const latestChapter: string = searchRule.latestChapter
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.latestChapter) as string
          : '';
        
        // 提取简介
        const intro: string = searchRule.intro
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.intro) as string
          : '';
        
        // 提取字数
        const wordCountStr: string = searchRule.wordCount
          ? RuleEngine.extractFromHtml(bookHtml, searchRule.wordCount) as string
          : '';
        const wordCount = parseInt(wordCountStr.replace(new RegExp('[^0-9]', 'g'), ''), 10) || 0;
        
        // 解析完整 URL
        const fullBookUrl = this.resolveRelativeUrl(source.url, bookUrl);
        const fullCoverUrl = coverUrl ? this.resolveRelativeUrl(source.url, coverUrl) : '';
        
        results.push({
          title,
          author,
          coverUrl: fullCoverUrl,
          bookUrl: fullBookUrl,
          sourceId: source.id,
          latestChapter,
          intro,
          wordCount
        });
      }

      return results;
    } catch (error) {
      const errorErr = error as Error;
      logger.error(errorErr.message);
      return [];
    }
  }

  // ==================== 书籍详情 ====================

  /**
   * 获取书籍详情
   * @param bookUrl 书籍详情页URL
   * @param sourceId 书源ID
   * @returns 书籍详情
   */
  async getBookDetail(bookUrl: string, sourceId: string): Promise<OnlineBookDetail | null> {
    try {
      // 检查缓存
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

      // 获取详情页HTML
      const fullUrl = this.resolveRelativeUrl(source.url, bookUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return null;
      }

      // 解析详情
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
   * 解析书籍详情
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
        : '未知作者';

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

  // ==================== 目录获取 ====================

  /**
   * 获取书籍目录
   * @param bookUrl 书籍详情页URL
   * @param sourceId 书源ID
   * @returns 章节列表
   */
  async fetchToc(bookUrl: string, sourceId: string): Promise<OnlineChapterInfo[]> {
    try {
      // 检查缓存
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

      // 获取目录页HTML
      const fullUrl = this.resolveRelativeUrl(source.url, bookUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return [];
      }

      // 解析目录
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
   * 解析目录
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

      // 获取章节列表容器
      const tocListRule = tocRule.tocList || '';
      const chapterItems: string[] = tocListRule
        ? RuleEngine.extractAllFromHtml(html, tocListRule)
        : [];

      // 提取每个章节
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

  // ==================== 章节内容获取 ====================

  /**
   * 获取章节内容
   * @param chapterUrl 章节URL
   * @param sourceId 书源ID
   * @returns 章节内容
   */
  async fetchChapterContent(chapterUrl: string, sourceId: string): Promise<string> {
    try {
      // 检查缓存
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

      // 获取章节HTML
      const fullUrl = this.resolveRelativeUrl(source.url, chapterUrl);
      const html = await this.fetchUrl(fullUrl);
      if (!html) {
        return '';
      }

      // 提取内容
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
   * 解析章节内容
   */
  private parseChapterContent(html: string, source: BookSource): string {
    try {
      const contentRule = typeof source.ruleContent === 'object'
        ? source.ruleContent as ContentRule
        : null;

      if (!contentRule || !contentRule.content) {
        return '';
      }

      // 提取正文内容
      let content: string = RuleEngine.extractFromHtml(html, contentRule.content) as string;

      // 内容净化
      content = this.cleanContent(content);

      // 应用替换规则
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
   * 内容净化
   */
  private cleanContent(content: string): string {
    return content
      // 移除多余空白
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('<[^>]+>', 'g'), '')
      // 移除广告标记
      .replace(new RegExp('\[.*?广告.*?\]', 'g'), '')
      .replace(new RegExp('\[.*?www\..*?\]', 'g'), '')
      // 规范化换行
      .replace(new RegExp('\r\n', 'g'), '\n')
      .replace(new RegExp('\n{3,}', 'g'), '\n\n')
      .trim();
  }

  // ==================== 工具方法 ====================

  /**
   * HTTP GET 请求
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
   * 解析相对URL
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
    // 相对路径
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
   * 清除缓存
   */
  clearCache(): void {
    this.chapterCache.clear();
    this.tocCache.clear();
    this.detailCache.clear();
  }
}

/**
 * RuleEngine - 本地规则引擎实现
 * 用于从HTML中根据规则提取内容
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

// 导出单例
export const onlineBookService = OnlineBookService.getInstance();
export default onlineBookService;
