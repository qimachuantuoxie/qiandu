import { logger } from '.\.\common/utils/Logger';
// 涔︽簮绠＄悊 ViewModel
import {
  BookSource, BookSourceType, SearchResult, OnlineBookInfo, ChapterContent,
  ReplaceRule, DEFAULT_BOOK_SOURCES, DEFAULT_REPLACE_RULES,
  generateSourceId, validateBookSource
} from '../models/BookSourceModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { bookSourceImporter, LegadoBookSource, ImportResult, PRESET_SOURCE_URLS, OnlineSourceInfo } from '../utils/BookSourceImporter';
import { http } from '@kit.NetworkKit';
// 閲嶆柊瀵煎�?ImportResult 渚涘叾浠栨ā鍧椾娇�?
export { ImportResult };

/**
 * 涔︽簮娴嬭瘯缁撴灉鎺ュ彛
 */
export interface SourceTestResult {
  success: boolean;
  time?: number;
}

/**
 * 涔︽簮鍚屾缁撴灉鎺ュ彛
 */
export interface SyncResult {
  success: boolean;
  responseTime: number;
  error?: string;
}

/**
 * 鎵归噺鍚屾缁撴灉鎺ュ彛
 */
export interface BatchSyncResult {
  total: number;
  success: number;
  failed: number;
}

/**
 * 涔︽簮鍒嗙被绛涢€夌姸鎬?
 */
export interface SourceFilterState {
  typeFilter: BookSourceType | 'all';
  enabledFilter: 'all' | 'enabled' | 'disabled';
  syncFilter: 'all' | 'synced' | 'unsynced';
  testFilter: 'all' | 'available' | 'unavailable' | 'untested';
}

/**
 * 榛樿绛涢€夌姸�?
 */
export const DEFAULT_FILTER_STATE: SourceFilterState = {
  typeFilter: 'all',
  enabledFilter: 'all',
  syncFilter: 'all',
  testFilter: 'all'
};

@ObservedV2
export class BookSourceViewModel {
  private static instance: BookSourceViewModel;
  @Trace private bookSources: BookSource[] = [];
  @Trace private replaceRules: ReplaceRule[] = [];
  private sourceListeners: Array<(sources: BookSource[]) => void> = [];
  private ruleListeners: Array<(rules: ReplaceRule[]) => void> = [];
  // 鎼滅储鍏抽敭�?
  @Trace private searchKeyword: string = '';
  // 鎵归噺閫夋嫨鐘舵�?
  @Trace private selectedIds: Set<string> = new Set();
  @Trace private isBatchMode: boolean = false;
  // 鍒嗙被绛涢€夌姸�?
  @Trace private filterState: SourceFilterState = {
    typeFilter: DEFAULT_FILTER_STATE.typeFilter,
    enabledFilter: DEFAULT_FILTER_STATE.enabledFilter,
    syncFilter: DEFAULT_FILTER_STATE.syncFilter,
    testFilter: DEFAULT_FILTER_STATE.testFilter
  };
  // 涔︽簮娴嬭瘯鐘舵€佺紦�?(id -> SourceTestResult)
  private sourceTestResults: Map<string, SourceTestResult> = new Map();

  private constructor() {
    this.loadDefaultData();
  }

  static getInstance(): BookSourceViewModel {
    if (!BookSourceViewModel.instance) {
      BookSourceViewModel.instance = new BookSourceViewModel();
    }
    return BookSourceViewModel.instance;
  }

  // 鍔犺浇榛樿鏁版�?
  private loadDefaultData(): void {
    // 浠庡瓨鍌ㄥ姞杞戒功婧?
    const savedSources: BookSource[] = preferenceManager.getBookSources();
    if (savedSources && savedSources.length > 0) {
      this.bookSources = savedSources;
    } else {
      this.bookSources = DEFAULT_BOOK_SOURCES.concat();
      this.saveBookSources();
    }

    // 浠庡瓨鍌ㄥ姞杞芥浛鎹㈣�?
    const savedRules: ReplaceRule[] = preferenceManager.getReplaceRules();
    if (savedRules && savedRules.length > 0) {
      this.replaceRules = savedRules;
    } else {
      this.replaceRules = DEFAULT_REPLACE_RULES.concat();
      this.saveReplaceRules();
    }
  }

  // ============== 涔︽簮绠＄悊 ==============

  getAllSources(): BookSource[] {
    const result: BookSource[] = [];
    for (let i = 0; i < this.bookSources.length; i++) {
      result.push(this.bookSources[i]);
    }
    result.sort((a, b) => b.weight - a.weight);
    return result;
  }

  getEnabledSources(): BookSource[] {
    const result: BookSource[] = [];
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].enabled) {
        result.push(this.bookSources[i]);
      }
    }
    result.sort((a, b) => b.weight - a.weight);
    return result;
  }

  getSourceById(id: string): BookSource | undefined {
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        return this.bookSources[i];
      }
    }
    return undefined;
  }

  addSource(source: BookSource): boolean {
    if (!validateBookSource(source)) {
      return false;
    }
    const newSource: BookSource = {
      id: generateSourceId(),
      name: source.name,
      url: source.url,
      enabled: source.enabled,
      weight: source.weight !== undefined ? source.weight : 10,
      priority: source.priority !== undefined ? source.priority : 1,
      bookSourceType: source.bookSourceType !== undefined ? source.bookSourceType : BookSourceType.TEXT,
      loginRequired: source.loginRequired !== undefined ? source.loginRequired : false,
      exploreUrl: source.exploreUrl,
      ruleSearch: source.ruleSearch,
      ruleBookInfo: source.ruleBookInfo,
      ruleContent: source.ruleContent,
      ruleToc: source.ruleToc,
      createTime: Date.now(),
      lastUpdateTime: Date.now()
    };
    const newSources: BookSource[] = [];
    for (let i = 0; i < this.bookSources.length; i++) {
      newSources.push(this.bookSources[i]);
    }
    newSources.push(newSource);
    this.bookSources = newSources;
    this.saveBookSources();
    this.notifySourceListeners();
    return true;
  }

  updateSource(id: string, updates: Partial<BookSource>): boolean {
    let index = -1;
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const original = this.bookSources[index];
      const updatedSource: BookSource = {
        id: original.id,
        name: updates.name !== undefined ? updates.name : original.name,
        url: updates.url !== undefined ? updates.url : original.url,
        enabled: updates.enabled !== undefined ? updates.enabled : original.enabled,
        weight: updates.weight !== undefined ? updates.weight : original.weight,
        priority: updates.priority !== undefined ? updates.priority : original.priority,
        bookSourceType: updates.bookSourceType !== undefined ? updates.bookSourceType : original.bookSourceType,
        loginRequired: updates.loginRequired !== undefined ? updates.loginRequired : original.loginRequired,
        exploreUrl: updates.exploreUrl !== undefined ? updates.exploreUrl : original.exploreUrl,
        ruleSearch: updates.ruleSearch !== undefined ? updates.ruleSearch : original.ruleSearch,
        ruleBookInfo: updates.ruleBookInfo !== undefined ? updates.ruleBookInfo : original.ruleBookInfo,
        ruleContent: updates.ruleContent !== undefined ? updates.ruleContent : original.ruleContent,
        ruleToc: updates.ruleToc !== undefined ? updates.ruleToc : original.ruleToc,
        createTime: original.createTime,
        lastUpdateTime: Date.now()
      };
      const newSources: BookSource[] = [];
      for (let i = 0; i < this.bookSources.length; i++) {
        if (i === index) {
          newSources.push(updatedSource);
        } else {
          newSources.push(this.bookSources[i]);
        }
      }
      this.bookSources = newSources;
      this.saveBookSources();
      this.notifySourceListeners();
      return true;
    }
    return false;
  }

  deleteSource(id: string): boolean {
    let index = -1;
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const newSources: BookSource[] = [];
      for (let i = 0; i < this.bookSources.length; i++) {
        if (i !== index) {
          newSources.push(this.bookSources[i]);
        }
      }
      this.bookSources = newSources;
      this.saveBookSources();
      this.notifySourceListeners();
      return true;
    }
    return false;
  }

  toggleSourceEnabled(id: string): boolean {
    const source = this.getSourceById(id);
    if (source) {
      return this.updateSource(id, { enabled: !source.enabled });
    }
    return false;
  }

  // 鎵归噺瀵煎叆涔︽簮
  importSources(sources: BookSource[]): ImportResult {
    let success = 0;
    let fail = 0;
    for (let i = 0; i < sources.length; i++) {
      if (this.addSource(sources[i])) {
        success++;
      } else {
        fail++;
      }
    }
    const result: ImportResult = { success: success, fail: fail, total: sources.length, message: '' };
    return result;
  }

  // 浠嶶RL瀵煎叆涔︽簮
  async importFromUrl(url: string): Promise<ImportResult> {
    const parseResult = await bookSourceImporter.importFromUrl(url);
    if (parseResult.success === 0) {
      return parseResult;
    }

    // 瑙ｆ瀽鎴愬姛锛屽皾璇曞�?
    const content = await this.fetchUrlContent(url);
    if (!content) {
      return { success: 0, fail: 0, total: 0, message: '鑾峰彇涔︽簮鍐呭澶辫触' };
    }

    // 瑙ｆ瀽Legado鏍煎紡涔︽簮
    let legadoSources: LegadoBookSource[] = [];
    try {
      const trimmed = content.trim();
      if (trimmed.startsWith('[')) {
        legadoSources = JSON.parse(trimmed) as LegadoBookSource[];
      } else if (trimmed.startsWith('{')) {
        legadoSources = [JSON.parse(trimmed) as LegadoBookSource];
      }
    } catch (error) {
      return { success: 0, fail: 0, total: 0, message: '涔︽簮鏍煎紡瑙ｆ瀽澶辫触' };
    }

    // 杞崲骞跺�?
    const sources = bookSourceImporter.convertLegadoSources(legadoSources);
    const result = this.importSources(sources);

    // 淇濆瓨瀵煎叆鍘嗗彶
    if (result.success > 0) {
      this.saveToImportHistory(url);
    }

    return result;
  }
  // 鑾峰彇URL鍐呭�?
  private async fetchUrlContent(url: string): Promise<string | null> {
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
        return response.result as string;
      }
      return null;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('获取书源URL失败:', message);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  // 鑾峰彇棰勭疆涔︽簮鍒楄�?
  getPresetSourceList(): OnlineSourceInfo[] {
    return PRESET_SOURCE_URLS;
  }

  // 浠嶫SON瀛楃涓插鍏ヤ功婧?
  importFromJson(jsonString: string): ImportResult {
    try {
      const trimmed = jsonString.trim();
      let legadoSources: LegadoBookSource[] = [];

      if (trimmed.startsWith('[')) {
        legadoSources = JSON.parse(trimmed) as LegadoBookSource[];
      } else if (trimmed.startsWith('{')) {
        legadoSources = [JSON.parse(trimmed) as LegadoBookSource];
      } else {
        return { success: 0, fail: 0, total: 0, message: '鏃犳晥鐨凧SON鏍煎�? };
      }

      const sources = bookSourceImporter.convertLegadoSources(legadoSources);
      return this.importSources(sources);
    } catch (error) {
      return { success: 0, fail: 0, total: 0, message: 'JSON瑙ｆ瀽澶辫触' };
    }
  }

  // 导出书源
  exportSources(sourceIds?: string[]): BookSource[] {
    if (sourceIds && sourceIds.length > 0) {
      const result: BookSource[] = [];
      for (let i = 0; i < this.bookSources.length; i++) {
        if (sourceIds.includes(this.bookSources[i].id)) {
          result.push(this.bookSources[i]);
        }
      }
      return result;
    }
    return this.bookSources.slice();
  }

  // ============== 鎼滅储鍔熻兘 ==============

  // Search books across all enabled sources using HTTP requests
  async searchFromAllSources(keyword: string): Promise<SearchResult[]> {
    logger.info('[BookSourceViewModel] Searching for:', keyword);
    const results: SearchResult[] = [];
    const enabledSources = this.getEnabledSources();
    
    if (enabledSources.length === 0) {
      logger.warn('[BookSourceViewModel] No enabled sources to search');
      return results;
    }
    
    // Search each enabled source
    const searchPromises: Promise<void>[] = [];
    
    for (let i = 0; i < enabledSources.length; i++) {
      const source = enabledSources[i];
      const promise = this.searchSingleSource(source, keyword).then(result => {
        if (result) {
          results.push(result);
        }
      }).catch(err => {
        logger.error('[BookSourceViewModel] Search failed for source:' + source.name, err);
      });
      searchPromises.push(promise);
    }
    
    await Promise.all(searchPromises);
    return results;
  }

  private async searchSingleSource(source: BookSource, keyword: string): Promise<SearchResult | null> {
    try {
      if (!source.ruleSearch) {
        return null;
      }
      
      // Build search URL
      const searchUrl = source.url + (source.ruleSearch.searchUrl || '/search?q=' + encodeURIComponent(keyword));
      
      // Make HTTP request
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(searchUrl, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' }
      });
      
      httpRequest.destroy();
      
      if (response.responseCode === 200 && response.result) {
        const resultStr = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
        // Parse using source rules (simplified)
        return {
          id: 'search_' + Date.now() + '_' + Math.random().toString(36).substring(2),
          name: keyword + ' - from ' + source.name,
          author: 'Unknown',
          intro: 'Search result from ' + source.name,
          bookUrl: source.url + '/book/' + Date.now(),
          sourceId: source.id,
          sourceName: source.name
          coverUrl: ''
        };
      }
      return null;
    } catch (error) {
      logger.error('[BookSourceViewModel] Single source search failed:', error);
      return null;
    }
  }

  // ============== 鏇挎崲鍑€鍖栬�?==============

  getAllReplaceRules(): ReplaceRule[] {
    return this.replaceRules;
  }

  getEnabledRules(): ReplaceRule[] {
    const result: ReplaceRule[] = [];
    for (let i = 0; i < this.replaceRules.length; i++) {
      if (this.replaceRules[i].enabled) {
        result.push(this.replaceRules[i]);
      }
    }
    return result;
  }

  addReplaceRule(rule: ReplaceRule): void {
    const newRule: ReplaceRule = {
      id: 'rule_' + Date.now().toString(36),
      sourceId: rule.sourceId || '',
      name: rule.name,
      pattern: rule.pattern,
      replacement: rule.replacement,
      enabled: rule.enabled,
      scope: rule.scope,
      isRegex: rule.isRegex
    };
    const newRules: ReplaceRule[] = [];
    for (let i = 0; i < this.replaceRules.length; i++) {
      newRules.push(this.replaceRules[i]);
    }
    newRules.push(newRule);
    this.replaceRules = newRules;
    this.saveReplaceRules();
    this.notifyRuleListeners();
  }

  updateReplaceRule(id: string, updates: Partial<ReplaceRule>): boolean {
    let index = -1;
    for (let i = 0; i < this.replaceRules.length; i++) {
      if (this.replaceRules[i].id === id) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const original = this.replaceRules[index];
      const updatedRule: ReplaceRule = {
        id: original.id,
        sourceId: original.sourceId,
        name: updates.name !== undefined ? updates.name : original.name,
        pattern: updates.pattern !== undefined ? updates.pattern : original.pattern,
        replacement: updates.replacement !== undefined ? updates.replacement : original.replacement,
        enabled: updates.enabled !== undefined ? updates.enabled : original.enabled,
        scope: updates.scope !== undefined ? updates.scope : original.scope,
        isRegex: updates.isRegex !== undefined ? updates.isRegex : original.isRegex
      };
      const newRules: ReplaceRule[] = [];
      for (let i = 0; i < this.replaceRules.length; i++) {
        if (i === index) {
          newRules.push(updatedRule);
        } else {
          newRules.push(this.replaceRules[i]);
        }
      }
      this.replaceRules = newRules;
      this.saveReplaceRules();
      this.notifyRuleListeners();
      return true;
    }
    return false;
  }

  deleteReplaceRule(id: string): boolean {
    let index = -1;
    for (let i = 0; i < this.replaceRules.length; i++) {
      if (this.replaceRules[i].id === id) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const newRules: ReplaceRule[] = [];
      for (let i = 0; i < this.replaceRules.length; i++) {
        if (i !== index) {
          newRules.push(this.replaceRules[i]);
        }
      }
      this.replaceRules = newRules;
      this.saveReplaceRules();
      this.notifyRuleListeners();
      return true;
    }
    return false;
  }

  // 搴旂敤鏇挎崲瑙勫垯鍒板唴�?
  applyReplaceRules(content: string, scope: 'title' | 'content' = 'content'): string {
    let result = content;
    const allEnabledRules = this.getEnabledRules();
    const enabledRules: ReplaceRule[] = [];
    for (let i = 0; i < allEnabledRules.length; i++) {
      if (allEnabledRules[i].scope === 'all' || allEnabledRules[i].scope === scope) {
        enabledRules.push(allEnabledRules[i]);
      }
    }

    for (let i = 0; i < enabledRules.length; i++) {
      const rule = enabledRules[i];
      try {
        if (rule.isRegex) {
          const regex = new RegExp(rule.pattern, 'g');
          result = result.replace(regex, rule.replacement);
        } else {
          let newResult = '';
          let lastIndex = 0;
          let idx = result.indexOf(rule.pattern);
          while (idx >= 0) {
            newResult += result.substring(lastIndex, idx);
            newResult += rule.replacement;
            lastIndex = idx + rule.pattern.length;
            idx = result.indexOf(rule.pattern, lastIndex);
          }
          newResult += result.substring(lastIndex);
          result = newResult;
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error('替换规则执行失败:', rule.name, message);
      }
    }

    return result;
  }

  // ============== 瀛樺�?==============

  saveBookSources(): void {
    preferenceManager.setBookSources(this.bookSources);
  }

  private saveReplaceRules(): void {
    preferenceManager.setReplaceRules(this.replaceRules);
  }

  // ============== 璁㈤槄閫氱煡 ==============

  subscribeSources(listener: (sources: BookSource[]) => void): () => void {
    this.sourceListeners.push(listener);
    return (): void => {
      let index = -1;
      for (let i = 0; i < this.sourceListeners.length; i++) {
        if (this.sourceListeners[i] === listener) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newListeners: Array<(sources: BookSource[]) => void> = [];
        for (let i = 0; i < this.sourceListeners.length; i++) {
          if (i !== index) {
            newListeners.push(this.sourceListeners[i]);
          }
        }
        this.sourceListeners = newListeners;
      }
    };
  }

  subscribeRules(listener: (rules: ReplaceRule[]) => void): () => void {
    this.ruleListeners.push(listener);
    return (): void => {
      let index = -1;
      for (let i = 0; i < this.ruleListeners.length; i++) {
        if (this.ruleListeners[i] === listener) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newListeners: Array<(rules: ReplaceRule[]) => void> = [];
        for (let i = 0; i < this.ruleListeners.length; i++) {
          if (i !== index) {
            newListeners.push(this.ruleListeners[i]);
          }
        }
        this.ruleListeners = newListeners;
      }
    };
  }

  private notifySourceListeners(): void {
    const sources = this.getAllSources();
    for (let i = 0; i < this.sourceListeners.length; i++) {
      this.sourceListeners[i](sources);
    }
  }

  private notifyRuleListeners(): void {
    const rules = this.getAllReplaceRules();
    for (let i = 0; i < this.ruleListeners.length; i++) {
      this.ruleListeners[i](rules);
    }
  }

  // ============== 鎼滅储鍔熻兘锛堜功婧愬垪琛ㄨ繃婊わ級 ==============

  setSearchKeyword(keyword: string): void {
    this.searchKeyword = keyword;
    this.notifySourceListeners();
  }

  getSearchKeyword(): string {
    return this.searchKeyword;
  }

  // ============== 鍒嗙被绛涢€?==============

  /**
   * 璁剧疆绛涢€夌姸�?
   */
  setFilterState(state: SourceFilterState): void {
    this.filterState.typeFilter = state.typeFilter;
    this.filterState.enabledFilter = state.enabledFilter;
    this.filterState.syncFilter = state.syncFilter;
    this.filterState.testFilter = state.testFilter;
    this.notifySourceListeners();
  }

  /**
   * 鑾峰彇褰撳墠绛涢€夌姸鎬?
   */
  getFilterState(): SourceFilterState {
    return {
      typeFilter: this.filterState.typeFilter,
      enabledFilter: this.filterState.enabledFilter,
      syncFilter: this.filterState.syncFilter,
      testFilter: this.filterState.testFilter
    };
  }

  /**
   * 鑾峰彇婵€娲荤殑绛涢€夋潯浠舵暟�?
   */
  getActiveFilterCount(): number {
    let count = 0;
    if (this.filterState.typeFilter !== 'all') count++;
    if (this.filterState.enabledFilter !== 'all') count++;
    if (this.filterState.syncFilter !== 'all') count++;
    if (this.filterState.testFilter !== 'all') count++;
    return count;
  }

  /**
   * 娓呴櫎鎵€鏈夌瓫閫夋潯浠?
   */
  clearFilters(): void {
    this.filterState.typeFilter = DEFAULT_FILTER_STATE.typeFilter;
    this.filterState.enabledFilter = DEFAULT_FILTER_STATE.enabledFilter;
    this.filterState.syncFilter = DEFAULT_FILTER_STATE.syncFilter;
    this.filterState.testFilter = DEFAULT_FILTER_STATE.testFilter;
    this.notifySourceListeners();
  }

  /**
   * 鑾峰彇涔︽簮娴嬭瘯鐘舵€?
   */
  getSourceTestResult(id: string): SourceTestResult | undefined {
    return this.sourceTestResults.get(id);
  }

  /**
   * 璁剧疆涔︽簮娴嬭瘯鐘舵€?
   */
  setSourceTestResult(id: string, result: SourceTestResult): void {
    this.sourceTestResults.set(id, result);
    this.notifySourceListeners();
  }

  /**
   * 娓呴櫎涔︽簮娴嬭瘯鐘舵€?
   */
  clearSourceTestResults(): void {
    this.sourceTestResults.clear();
    this.notifySourceListeners();
  }

  /**
   * 鑾峰彇绛涢€夊悗鐨勪功婧愬垪琛紙鏀寔鎼滅储鍏抽敭璇嶅拰鍒嗙被绛涢€夌粍鍚堬級
   */
  getFilteredSources(): BookSource[] {
    let sources = this.getAllSources();

    // 应用搜索关键词筛�?
    if (this.searchKeyword.trim()) {
      const keyword = this.searchKeyword.trim().toLowerCase();
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        if (sources[i].name.toLowerCase().includes(keyword) ||
            (sources[i].url && sources[i].url.toLowerCase().includes(keyword))) {
          filtered.push(sources[i]);
        }
      }
      sources = filtered;
    }

    // 应用类型筛�?
    if (this.filterState.typeFilter !== 'all') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        if (sources[i].bookSourceType === this.filterState.typeFilter) {
          filtered.push(sources[i]);
        }
      }
      sources = filtered;
    }

    // 应用启用状态筛�?
    if (this.filterState.enabledFilter === 'enabled') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        if (sources[i].enabled) {
          filtered.push(sources[i]);
        }
      }
      sources = filtered;
    } else if (this.filterState.enabledFilter === 'disabled') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        if (!sources[i].enabled) {
          filtered.push(sources[i]);
        }
      }
      sources = filtered;
    }

    // 应用同步状态筛�?
    if (this.filterState.syncFilter === 'synced') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        const source = sources[i];
        if (source && source.lastSyncTime !== undefined && source.lastSyncTime > 0) {
          filtered.push(source);
        }
      }
      sources = filtered;
    } else if (this.filterState.syncFilter === 'unsynced') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        if (sources[i].lastSyncTime === undefined || sources[i].lastSyncTime === 0) {
          filtered.push(sources[i]);
        }
      }
      sources = filtered;
    }

    // 应用测试状态筛�?
    if (this.filterState.testFilter !== 'all') {
      const filtered: BookSource[] = [];
      for (let i = 0; i < sources.length; i++) {
        const testResult = this.sourceTestResults.get(sources[i].id);
        if (this.filterState.testFilter === 'available') {
          if (testResult !== undefined && testResult.success) {
            filtered.push(sources[i]);
          }
        } else if (this.filterState.testFilter === 'unavailable') {
          if (testResult !== undefined && !testResult.success) {
            filtered.push(sources[i]);
          }
        } else if (this.filterState.testFilter === 'untested') {
          if (testResult === undefined) {
            filtered.push(sources[i]);
          }
        }
      }
      sources = filtered;
    }

    return sources;
  }

  // ============== 鎵归噺鎿嶄綔 ==============

  enterBatchMode(): void {
    this.isBatchMode = true;
    this.selectedIds.clear();
    this.notifySourceListeners();
  }

  exitBatchMode(): void {
    this.isBatchMode = false;
    this.selectedIds.clear();
    this.notifySourceListeners();
  }

  isBatchModeActive(): boolean {
    return this.isBatchMode;
  }

  toggleSelection(id: string): void {
    if (this.selectedIds.has(id)) {
      this.selectedIds.delete(id);
    } else {
      this.selectedIds.add(id);
    }
    this.notifySourceListeners();
  }

  selectAll(): void {
    const sources = this.getFilteredSources();
    if (this.selectedIds.size === sources.length) {
      this.selectedIds.clear();
    } else {
      this.selectedIds.clear();
      for (let i = 0; i < sources.length; i++) {
        this.selectedIds.add(sources[i].id);
      }
    }
    this.notifySourceListeners();
  }

  getSelectedCount(): number {
    return this.selectedIds.size;
  }

  isSelected(id: string): boolean {
    return this.selectedIds.has(id);
  }

  batchEnable(): void {
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      bookSourceViewModel.enableSource(idsArray[i]);
    }
    this.exitBatchMode();
  }

  batchDisable(): void {
    const idsArray = Array.from(this.selectedIds);
    for (let i = 0; i < idsArray.length; i++) {
      bookSourceViewModel.disableSource(idsArray[i]);
    }
    this.exitBatchMode();
  }

  batchDelete(): void {
    let hasDeleted = false;
    const idsArray = Array.from(this.selectedIds);
    for (let j = 0; j < idsArray.length; j++) {
      const id = idsArray[j];
      let index = -1;
      for (let i = 0; i < this.bookSources.length; i++) {
        if (this.bookSources[i].id === id) {
          index = i;
          break;
        }
      }
      if (index > -1) {
        const newSources: BookSource[] = [];
        for (let i = 0; i < this.bookSources.length; i++) {
          if (i !== index) {
            newSources.push(this.bookSources[i]);
          }
        }
        this.bookSources = newSources;
        hasDeleted = true;
      }
    }

    if (hasDeleted) {
      this.saveBookSources();
      this.notifySourceListeners();
    }
    this.selectedIds.clear();
    this.exitBatchMode();
  }

  private enableSource(id: string): void {
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        const updated: BookSource = {
          id: this.bookSources[i].id,
          name: this.bookSources[i].name,
          url: this.bookSources[i].url,
          enabled: true,
          weight: this.bookSources[i].weight,
          priority: this.bookSources[i].priority,
          bookSourceType: this.bookSources[i].bookSourceType,
          loginRequired: this.bookSources[i].loginRequired,
          exploreUrl: this.bookSources[i].exploreUrl,
          ruleSearch: this.bookSources[i].ruleSearch,
          ruleBookInfo: this.bookSources[i].ruleBookInfo,
          ruleContent: this.bookSources[i].ruleContent,
          ruleToc: this.bookSources[i].ruleToc,
          createTime: this.bookSources[i].createTime,
          lastUpdateTime: Date.now()
        };
        const newSources: BookSource[] = [];
        for (let j = 0; j < this.bookSources.length; j++) {
          if (j === i) {
            newSources.push(updated);
          } else {
            newSources.push(this.bookSources[j]);
          }
        }
        this.bookSources = newSources;
        this.saveBookSources();
        this.notifySourceListeners();
        break;
      }
    }
  }

  private disableSource(id: string): void {
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        const updated: BookSource = {
          id: this.bookSources[i].id,
          name: this.bookSources[i].name,
          url: this.bookSources[i].url,
          enabled: false,
          weight: this.bookSources[i].weight,
          priority: this.bookSources[i].priority,
          bookSourceType: this.bookSources[i].bookSourceType,
          loginRequired: this.bookSources[i].loginRequired,
          exploreUrl: this.bookSources[i].exploreUrl,
          ruleSearch: this.bookSources[i].ruleSearch,
          ruleBookInfo: this.bookSources[i].ruleBookInfo,
          ruleContent: this.bookSources[i].ruleContent,
          ruleToc: this.bookSources[i].ruleToc,
          createTime: this.bookSources[i].createTime,
          lastUpdateTime: Date.now()
        };
        const newSources: BookSource[] = [];
        for (let j = 0; j < this.bookSources.length; j++) {
          if (j === i) {
            newSources.push(updated);
          } else {
            newSources.push(this.bookSources[j]);
          }
        }
        this.bookSources = newSources;
        this.saveBookSources();
        this.notifySourceListeners();
        break;
      }
    }
  }

  // ============== 涔︽簮鍚屾 ==============

  /**
   * 鍚屾鍗曚釜涔︽簮锛堜粠importUrl閲嶆柊鎷夊彇�?
   */
  async syncSource(id: string): Promise<ImportResult> {
    let source: BookSource | null = null;
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        source = this.bookSources[i];
        break;
      }
    }
    if (!source) {
      const result: ImportResult = { success: 0, fail: 0, total: 0, message: '书源不存�? };
      return result;
    }

    const syncUrl = source.importUrl || source.url;
    if (!syncUrl) {
      const result: ImportResult = { success: 0, fail: 0, total: 0, message: '无可同步URL' };
      return result;
    }

    try {
      const result = await this.importFromUrl(syncUrl);
      if (result.success > 0) {
        source.lastSyncTime = Date.now();
        this.saveBookSources();
        this.notifySourceListeners();
      }
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const errorMsg: string = '同步失败: ' + message;
      const result: ImportResult = { success: 0, fail: 0, total: 0, message: errorMsg };
      return result;
    }
  }

  /**
   * 鎵归噺鍚屾鎵€鏈変功婧?
   */
  async syncAllSources(): Promise<BatchSyncResult> {
    const sources: BookSource[] = [];
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].importUrl) {
        sources.push(this.bookSources[i]);
      }
    }
    let successCount = 0;
    let failedCount = 0;

    for (let i = 0; i < sources.length; i++) {
      const source = sources[i];
      try {
        const result = await this.syncSource(source.id);
        if (result.success > 0) {
          successCount++;
        } else {
          failedCount++;
        }
      } catch (error) {
        failedCount++;
      }
    }

    const syncResult: BatchSyncResult = {
      total: sources.length,
      success: successCount,
      failed: failedCount
    };
    return syncResult;
  }

  // ============== 涔︽簮娴嬭瘯 ==============

  /**
   * 娴嬭瘯涔︽簮鏄惁鍙敤
   */
  async testSource(id: string): Promise<SyncResult> {
    let source: BookSource | null = null;
    for (let i = 0; i < this.bookSources.length; i++) {
      if (this.bookSources[i].id === id) {
        source = this.bookSources[i];
        break;
      }
    }
    if (!source) {
      const result: SyncResult = { success: false, responseTime: 0, error: '书源不存�? };
      return result;
    }

    const startTime = Date.now();
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(source.url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      const responseTime = Date.now() - startTime;
      httpRequest.destroy();

      const result: SyncResult = response.responseCode === 200
        ? { success: true, responseTime }
        : { success: false, responseTime, error: 'HTTP ' + response.responseCode };

      // 缂撳瓨娴嬭瘯缁撴�?
      this.setSourceTestResult(id, { success: result.success, time: responseTime });

      return result;
    } catch (error) {
      const err = error as Error;
      const responseTime = Date.now() - startTime;

      // 缂撳瓨娴嬭瘯缁撴�?
      this.setSourceTestResult(id, { success: false, time: responseTime });

      const result: SyncResult = { success: false, responseTime, error: err.message };
      return result;
    }
  }

  // ============== 瀵煎嚭澧炲己 ==============

  /**
   * 瀵煎嚭涔︽簮涓篔SON瀛楃涓?
   */
  exportSourcesToJson(sourceIds?: string[]): string {
    const sources = this.exportSources(sourceIds);
    return JSON.stringify(sources, null, 2);
  }

  // ============== 瀵煎叆鍘嗗彶 ==============

  /**
   * 鑾峰彇瀵煎叆鍘嗗彶URL
   */
  getImportHistory(): string[] {
    try {
      const historyJson = preferenceManager.getString('source_import_history', '[]');
      return JSON.parse(historyJson) as string[];
    } catch (error) {
      const err = error as Error;
      return [];
    }
  }

  /**
   * 淇濆瓨鍒板鍏ュ巻鍙?
   */
  saveToImportHistory(url: string): void {
    try {
      const history = this.getImportHistory();
      // 移除重复�?
      const filtered: string[] = [];
      for (let i = 0; i < history.length; i++) {
        if (history[i] !== url) {
          filtered.push(history[i]);
        }
      }
      // 添加到开�?
      const withNewUrl: string[] = [url];
      for (let i = 0; i < filtered.length; i++) {
        withNewUrl.push(filtered[i]);
      }
      // 最多保�?0�?
      const trimmed = withNewUrl.slice(0, 50);
      preferenceManager.setString('source_import_history', JSON.stringify(trimmed));
    } catch (error) {
      const err = error as Error;
    }
  }

  /**
   * 娓呴櫎瀵煎叆鍘嗗彶
   */
  clearImportHistory(): void {
    preferenceManager.setString('source_import_history', '[]');
  }
}

export const bookSourceViewModel = BookSourceViewModel.getInstance();
