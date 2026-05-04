// 灏忚壓鏅鸿兘浣撴湇鍔?- 鍗庝负鏅烘収鍔╂墜闆嗘垚
// Xiaoyi Agent Service - Huawei Smart Assistant Integration
// 浣跨敤璇煶璇嗗埆鍜孉I鑳藉姏锛屾彁渚涙櫤鑳介槄璇昏緟鍔╁姛鑳?
// 鏀寔璇煶鎸囦护鎺у埗銆丄I闂瓟銆侀槄璇绘帹鑽愮瓑
// TODO: SpeechKit not available - using stub implementations

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { ttsService } from './TTSService';
import { BookInfo, Bookmark, Note } from '../../models/CoreBookModel';
import { ReadStatus } from '../../models/BookModel';

// ===== Stub types for SpeechKit (TODO: Replace when SpeechKit is available) =====
interface StubSpeechRecognitionResult {
  text: string;
}

interface StubSpeechRecognitionConfig {
  language: string;
  continuous: boolean;
  interimResults: boolean;
}

class StubSpeechRecognizerController {
  on(event: string, callback: (result: StubSpeechRecognitionResult) => void): void {}
  off(event: string, callback: (result: StubSpeechRecognitionResult) => void): void {}
  startListening(): Promise<void> { return Promise.resolve(); }
  stopListening(): Promise<void> { return Promise.resolve(); }
  destroy(): void {}
}

interface StubSpeechRecognizerFactory {
  createSpeechRecognizer(context: common.Context, config: StubSpeechRecognitionConfig): StubSpeechRecognizerController;
}

class StubSpeechRecognizerFactoryImpl implements StubSpeechRecognizerFactory {
  createSpeechRecognizer(context: common.Context, config: StubSpeechRecognitionConfig): StubSpeechRecognizerController {
    return new StubSpeechRecognizerController();
  }
}

const stubSpeechRecognizer: StubSpeechRecognizerFactory = new StubSpeechRecognizerFactoryImpl();
// ===== End Stub types =====

// 鏃ュ織鍩?
const LOG_DOMAIN = 0xFF0A;

// 缃俊搴﹀父閲?
const CONFIDENCE_HIGH = 0.95;
const CONFIDENCE_MEDIUM = 0.85;
const CONFIDENCE_LOW = 0.7;
const CONFIDENCE_DEFAULT = 0.8;
const CONFIDENCE_STATS = 0.9;

// 鏁伴噺闄愬埗甯搁噺
const MAX_SEARCH_RESULTS = 5;
const MAX_RECOMMENDATIONS = 3;

/**
 * 鏅鸿兘浣撹兘鍔涙灇涓?
 * Agent Capability Enum
 */
export enum AgentCapability {
  VOICE_COMMAND = 'voice_command',        // 璇煶鎸囦护
  AI_CHAT = 'ai_chat',                   // AI瀵硅瘽
  CONTENT_RECOMMEND = 'content_recommend', // 鍐呭鎺ㄨ崘
  BOOK_QUERY = 'book_query',             // 涔︾睄鏌ヨ
  READING_COMPANION = 'reading_companion'  // 闃呰浼翠荆
}

export interface VoiceCommandParams {
  rawText?: string;
  direction?: string;
  action?: string;
  key?: string;
  value?: string | number;
}

/**
 * 璇煶鍛戒护缁撴瀯
 * Voice Command Structure
 */
export interface VoiceCommand {
  action: string;                        // 鎿嶄綔绫诲瀷
  params: VoiceCommandParams;            // 鍙傛暟
  confidence: number;                    // 缃俊搴?
}

/**
 * 鏅鸿兘浣撳搷搴旂粨鏋?
 * Agent Response Structure
 */
export interface AgentResponse {
  type: 'text' | 'action' | 'recommendation'; // 鍝嶅簲绫诲瀷
  content: string;                     // 鍐呭
  actions?: AgentAction[];             // 鎿嶄綔鍒楄〃
  confidence: number;                  // 缃俊搴?
}

/**
 * 鏅鸿兘浣撴搷浣滅粨鏋?
 * Agent Action Structure
 */
export interface AgentActionParams {
  direction?: string;
  action?: string;
  key?: string;
  delta?: number;
  type?: string;
  title?: string;
  url?: string;
}

export interface AgentAction {
  type: string;                        // 鎿嶄綔绫诲瀷
  params: AgentActionParams;           // 鍙傛暟
}

/**
 * 涔︾睄鏌ヨ鏉′欢
 * Book Query Condition
 */
export interface BookQuery {
  title?: string;                      // 涔﹀悕鍏抽敭璇?
  author?: string;                     // 浣滆€?
  genre?: string;                      // 鍒嗙被
  tags?: string[];                     // 鏍囩
}

/**
 * 鑱婂ぉ涓婁笅鏂?
 * Chat Context
 */
export interface ChatContext {
  bookTitle?: string;
  currentPage?: number;
  chapterTitle?: string;
}

/**
 * 闃呰浼翠荆鐘舵€?
 * Reading Companion State
 */
export interface ReadingCompanionState {
  bookId: string;                      // 涔︾睄ID
  currentPage: number;                 // 褰撳墠椤电爜
  context: string;                     // 涓婁笅鏂?
  lastInteraction: number;            // 涓婃浜や簰鏃堕棿
}

/**
 * 璇煶鍛戒护澶勭悊鍣?
 */
interface CommandHandler {
  keywords: string[];
  handler: (params: VoiceCommandParams) => Promise<AgentResponse>;
}

/**
 * 灏忚壓鏅鸿兘浣撴湇鍔＄被
 * Xiaoyi Agent Service Class
 */
class XiaoyiAgentService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: XiaoyiAgentService;

  /** 涓婁笅鏂?*/
  private context: common.Context | null = null;

  /** 鏄惁宸插垵濮嬪寲 */
  private isInitialized: boolean = false;

  /** 璇煶璇嗗埆鍣?*/
  private speechRecognizer: StubSpeechRecognizerController | null = null;

  /** 褰撳墠闃呰鐘舵€?*/
  private companionState: ReadingCompanionState | null = null;

  /** 鑱婂ぉ涓婁笅鏂?*/
  private chatContext: ChatContext = {};

  /** 鏄惁姝ｅ湪鐩戝惉璇煶 */
  private isListening: boolean = false;

  /** 鍛戒护澶勭悊鍣ㄦ槧灏?*/
  private commandHandlers: Map<string, CommandHandler> = new Map();

  /** 鍝嶅簲鍥炶皟 */
  private responseCallback: ((response: AgentResponse) => void) | null = null;

  // ArkTS strict mode: use explicit callback reference instead of inline object method
  private onResultCallback: ((result: StubSpeechRecognitionResult) => void) | null = null;

  private constructor() {}

  /**
   * 鑾峰彇鎵€鏈変功绫?浠巔referenceManager鐩存帴璇诲彇)
   */
  private getAllBooks(): BookInfo[] {
    return preferenceManager.getBooks();
  }

  /**
   * 鏍规嵁ID鑾峰彇涔︾睄
   */
  private getBookById(bookId: string): BookInfo | null {
    const books = this.getAllBooks();
    for (let i = 0; i < books.length; i++) {
      if (books[i].id === bookId) {
        return books[i];
      }
    }
    return null;
  }

  /**
   * 鎼滅储涔︾睄
   */
  private searchBooks(keyword: string): BookInfo[] {
    const books = this.getAllBooks();
    const lowerKeyword = keyword.toLowerCase();
    const results: BookInfo[] = [];
    let resultIndex = 0;
    for (let i = 0; i < books.length; i++) {
      const book = books[i];
      const titleMatch = book.title.toLowerCase().includes(lowerKeyword);
      const authorMatch = book.author.toLowerCase().includes(lowerKeyword);
      if (titleMatch || authorMatch) {
        results[resultIndex] = book;
        resultIndex++;
      }
    }
    return results;
  }

  /**
   * 鑾峰彇鎬婚槄璇绘椂闀?鍒嗛挓)
   */
  private getTotalReadDuration(): number {
    const records = preferenceManager.getReadRecords();
    let total = 0;
    for (let i = 0; i < records.length; i++) {
      total += (records[i].duration || 0);
    }
    return total;
  }

  /**
   * 鑾峰彇浠婃棩闃呰鏃堕暱(鍒嗛挓)
   */
  private getTodayReadDuration(): number {
    const records = preferenceManager.getReadRecords();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayTime = today.getTime();
    let total = 0;
    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      if (record.date && new Date(record.date).getTime() >= todayTime) {
        total += (record.duration || 0);
      }
    }
    return total;
  }

  /**
   * 鑾峰彇鎵€鏈変功绛?
   */
  private getAllBookmarks(): Bookmark[] {
    const bookmarksData = preferenceManager.getAllBookmarks();
    const bookmarks: Bookmark[] = [];
    const bookIds: string[] = Object.keys(bookmarksData);
    let bookmarkIndex = 0;
    for (let i = 0; i < bookIds.length; i++) {
      const bookId = bookIds[i];
      const bookBookmarks: Bookmark[] = bookmarksData[bookId];
      for (let j = 0; j < bookBookmarks.length; j++) {
        bookmarks[bookmarkIndex] = bookBookmarks[j];
        bookmarkIndex++;
      }
    }
    return bookmarks;
  }

  /**
   * 鑾峰彇鎵€鏈夌瑪璁?
   */
  private getAllNotes(): Note[] {
    const notesData = preferenceManager.getNotes();
    const notes: Note[] = [];
    const bookIds: string[] = Object.keys(notesData);
    let noteIndex = 0;
    for (let i = 0; i < bookIds.length; i++) {
      const bookId = bookIds[i];
      const bookNotes: Note[] = notesData[bookId];
      for (let j = 0; j < bookNotes.length; j++) {
        notes[noteIndex] = bookNotes[j];
        noteIndex++;
      }
    }
    return notes;
  }

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): XiaoyiAgentService {
    if (!XiaoyiAgentService.instance) {
      XiaoyiAgentService.instance = new XiaoyiAgentService();
    }
    return XiaoyiAgentService.instance;
  }

  /**
   * 鍒濆鍖栨湇鍔?
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Initializing...');
      this.context = context;

      // 鍒濆鍖栬闊宠瘑鍒?
      await this.initSpeechRecognizer();

      // 娉ㄥ唽鍛戒护澶勭悊鍣?
      this.registerCommandHandlers();

      this.isInitialized = true;
      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Initialized successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Init failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 鍒濆鍖栬闊宠瘑鍒櫒
   */
  private async initSpeechRecognizer(): Promise<void> {
    try {
      // 鍒涘缓璇煶璇嗗埆鍣?using stub)
      const config: StubSpeechRecognitionConfig = {
        language: 'zh-CN',
        continuous: true,
        interimResults: true
      };

      // ArkTS strict mode: use arrow function to preserve `this` context
      this.onResultCallback = (result: StubSpeechRecognitionResult): void => {
        this.handleVoiceInput(result.text);
      };

      this.speechRecognizer = stubSpeechRecognizer.createSpeechRecognizer(this.context!, config);

      // 璁剧疆璇嗗埆缁撴灉鐩戝惉
      this.speechRecognizer.on('result', this.onResultCallback);

      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'SpeechRecognizer initialized (stub)');
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Init SpeechRecognizer failed: %{public}s', err.message);
      throw new Error('Speech recognizer initialization failed: ' + err.message);
    }
  }

  /**
   * 娉ㄥ唽鍛戒护澶勭悊鍣?
   */
  private registerCommandHandlers(): void {
    // 缈婚〉鍛戒护
    this.commandHandlers.set('page_turn', {
      keywords: ['涓嬩竴椤?, '涓婁竴椤?, '缈婚〉'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handlePageTurn(params)
    });

    // 涔︾鍛戒护
    this.commandHandlers.set('bookmark', {
      keywords: ['娣诲姞涔︾', '鍔犲叆涔︾', '鏀惰棌'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleBookmark(params)
    });

    // 鏈楄鍛戒护
    this.commandHandlers.set('read_aloud', {
      keywords: ['鏈楄', '璇荤粰鎴戝惉', '寮€濮嬫湕璇?],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleReadAloud(params)
    });

    // 鎼滅储鍛戒护
    this.commandHandlers.set('search', {
      keywords: ['鎼滅储', '鏌ユ壘', '鎵句功'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleSearch(params)
    });

    // 缁熻鍛戒护
    this.commandHandlers.set('stats', {
      keywords: ['缁熻', '闃呰缁熻', '鐪嬩簡澶氫箙'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleStats(params)
    });

    // 鎺ㄨ崘鍛戒护
    this.commandHandlers.set('recommend', {
      keywords: ['鎺ㄨ崘', '鎺ㄨ崘涔?, '鏈変粈涔堝ソ涔?],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleRecommend(params)
    });
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 璇煶浜や簰 ====================

  /**
   * 寮€濮嬭闊崇洃鍚?
   */
  async startListening(): Promise<boolean> {
    try {
      if (!this.isReady() || !this.speechRecognizer) {
        return false;
      }

      if (this.isListening) {
        return true;
      }

      await this.speechRecognizer.startListening();
      this.isListening = true;

      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Started voice listening');
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Start listening failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 鍋滄璇煶鐩戝惉
   */
  async stopListening(): Promise<void> {
    try {
      if (!this.isListening || !this.speechRecognizer) {
        return;
      }

      await this.speechRecognizer.stopListening();
      this.isListening = false;

      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Stopped voice listening');
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Stop listening failed: %{public}s', err.message);
    }
  }

  /**
   * 澶勭悊璇煶杈撳叆
   */
  private async handleVoiceInput(text: string): Promise<void> {
    try {
      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Voice input: %{public}s', text);

      // 鍖归厤鍛戒护
      const command: CommandHandler | null = this.matchCommand(text);
      if (command) {
        const response: AgentResponse = await command.handler({ rawText: text });
        this.sendResponse(response);
      } else {
        // 浣滀负鑱婂ぉ杈撳叆
        const response: AgentResponse = await this.handleChat(text);
        this.sendResponse(response);
      }
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Handle voice input failed: %{public}s', err.message);
    }
  }

  /**
   * 鍖归厤鍛戒护
   */
  private matchCommand(text: string): CommandHandler | null {
    const lowerText: string = text.toLowerCase();

    const handlers: CommandHandler[] = Array.from(this.commandHandlers.values());
    for (let i = 0; i < handlers.length; i++) {
      const handler: CommandHandler = handlers[i];
      for (let k = 0; k < handler.keywords.length; k++) {
        if (lowerText.includes(handler.keywords[k])) {
          return handler;
        }
      }
    }

    return null;
  }

  // ==================== 鍛戒护澶勭悊 ====================

  /**
   * 澶勭悊缈婚〉鍛戒护
   */
  private async handlePageTurn(params: VoiceCommandParams): Promise<AgentResponse> {
    const rawText: string = params.rawText || '';
    const direction: string = rawText.includes('涓?) ? 'prev' : 'next';
    const contentText: string = direction === 'next' ? '缈诲埌涓嬩竴椤? : '缈诲埌涓婁竴椤?;

    const action: AgentAction = {
      type: 'page_turn',
      params: { direction: direction }
    };

    return {
      type: 'action',
      content: contentText,
      actions: [action],
      confidence: CONFIDENCE_HIGH
    };
  }

  /**
   * 澶勭悊涔︾鍛戒护
   */
  private async handleBookmark(params: VoiceCommandParams): Promise<AgentResponse> {
    const action: AgentAction = {
      type: 'add_bookmark',
      params: {}
    };

    return {
      type: 'action',
      content: '宸叉坊鍔犱功绛?,
      actions: [action],
      confidence: CONFIDENCE_HIGH
    };
  }

  /**
   * 澶勭悊鏈楄鍛戒护
   */
  private async handleReadAloud(params: VoiceCommandParams): Promise<AgentResponse> {
    const action: AgentAction = {
      type: 'start_tts',
      params: {}
    };

    return {
      type: 'action',
      content: '寮€濮嬫湕璇?,
      actions: [action],
      confidence: CONFIDENCE_HIGH
    };
  }

  /**
   * 澶勭悊鎼滅储鍛戒护
   */
  private async handleSearch(params: VoiceCommandParams): Promise<AgentResponse> {
    const rawText: string = params.rawText || '';
    const query: string = rawText.replace(new RegExp('鎼滅储|鏌ユ壘|鎵?, 'g'), '').trim();

    if (!query) {
      return {
        type: 'text',
        content: '璇峰憡璇夋垜鎮ㄨ鎼滅储鐨勪功绫嶅悕绉?,
        confidence: CONFIDENCE_DEFAULT
      };
    }

    const books: BookInfo[] = this.searchBooks(query);
    const limit: number = books.length < MAX_SEARCH_RESULTS ? books.length : MAX_SEARCH_RESULTS;
    const sliced: BookInfo[] = [];
    for (let idx = 0; idx < limit; idx++) {
      sliced[idx] = books[idx];
    }

    const resultTitles: string[] = [];
    for (let i = 0; i < sliced.length; i++) {
      const b: BookInfo = sliced[i];
      resultTitles[resultTitles.length] = b.title + ' - ' + b.author;
    }

    const actions: AgentAction[] = [];
    for (let j = 0; j < resultTitles.length; j++) {
      const r: string = resultTitles[j];
      actions[actions.length] = {
        type: 'search_result',
        params: { title: r }
      };
    }

    return {
      type: 'recommendation',
      content: '鎵惧埌 ' + books.length + ' 鏈浉鍏充功绫?,
      actions: actions,
      confidence: CONFIDENCE_MEDIUM
    };
  }

  /**
   * 澶勭悊缁熻鍛戒护
   */
  private async handleStats(params: VoiceCommandParams): Promise<AgentResponse> {
    const books: BookInfo[] = this.getAllBooks();
    let readingBook: BookInfo | null = null;
    for (let i = 0; i < books.length; i++) {
      if (books[i].status === ReadStatus.READING) {
        readingBook = books[i];
        break;
      }
    }

    let content: string = '';
    if (readingBook !== null) {
      const book: BookInfo = readingBook;
      const progress: number = book.readProgress || 0;
      content = '鎮ㄦ鍦ㄩ槄璇汇€? + book.title + '銆嬶紝杩涘害 ' + progress + '%';
    } else {
      content = '鎮ㄨ繕娌℃湁寮€濮嬮槄璇?;
    }

    return {
      type: 'text',
      content: content,
      confidence: CONFIDENCE_STATS
    };
  }

  /**
   * 澶勭悊鎺ㄨ崘鍛戒护
   */
  private async handleRecommend(params: VoiceCommandParams): Promise<AgentResponse> {
    const books: BookInfo[] = this.getAllBooks();
    const unreadBooks: BookInfo[] = [];
    let unreadIndex = 0;
    for (let i = 0; i < books.length; i++) {
      if (books[i].status === ReadStatus.UNREAD) {
        unreadBooks[unreadIndex] = books[i];
        unreadIndex++;
      }
      if (unreadIndex >= MAX_RECOMMENDATIONS) break;
    }

    if (unreadIndex === 0) {
      return {
        type: 'text',
        content: '鏆傛棤鎺ㄨ崘锛岃瀵煎叆鏇村涔︾睄',
        confidence: CONFIDENCE_DEFAULT
      };
    }

    const recommendations: string[] = [];
    for (let i = 0; i < unreadIndex; i++) {
      const b: BookInfo = unreadBooks[i];
      recommendations[recommendations.length] = b.title + ' - ' + b.author;
    }

    const actions: AgentAction[] = [];
    for (let j = 0; j < recommendations.length; j++) {
      const r: string = recommendations[j];
      actions[actions.length] = {
        type: 'book_recommend',
        params: { title: r }
      };
    }

    return {
      type: 'recommendation',
      content: '涓烘偍鎺ㄨ崘浠ヤ笅涔︾睄',
      actions: actions,
      confidence: CONFIDENCE_MEDIUM
    };
  }

  /**
   * 澶勭悊鑱婂ぉ - 浣跨敤鏅鸿兘鍥炲閫昏緫
   */
  private async handleChat(text: string): Promise<AgentResponse> {
    const cleanedMessage: string = text.trim();

    // 涔︾睄鐩稿叧
    if (cleanedMessage.includes('涔?) || cleanedMessage.includes('闃呰') || cleanedMessage.includes('灏忚')) {
      const allBooks: BookInfo[] = this.getAllBooks();
      const bookCount: number = allBooks.length;
      let readingCount: number = 0;
      for (let i = 0; i < allBooks.length; i++) {
        if (allBooks[i].status === ReadStatus.READING) {
          readingCount++;
        }
      }
      return {
        type: 'text',
        content: '鎮ㄧ洰鍓嶆湁 ' + bookCount + ' 鏈功锛屾鍦ㄩ槄璇? + readingCount + ' 鏈€傞渶瑕佹垜甯偍鎵句功鍚楋紵',
        confidence: CONFIDENCE_STATS
      };
    }

    // 闃呰杩涘害
    if (cleanedMessage.includes('杩涘害') || cleanedMessage.includes('璇讳簡澶氬皯')) {
      const allBooks: BookInfo[] = this.getAllBooks();
      const books: BookInfo[] = [];
      let bookIndex = 0;
      for (let i = 0; i < allBooks.length; i++) {
        const progress = allBooks[i].readProgress !== undefined ? allBooks[i].readProgress : 0;
        if (progress > 0) {
          books[bookIndex] = allBooks[i];
          bookIndex++;
        }
      }
      if (bookIndex === 0) {
        return {
          type: 'text',
          content: '鎮ㄨ繕娌℃湁寮€濮嬮槄璇讳换浣曚功绫嶃€?,
          confidence: CONFIDENCE_STATS
        };
      }
      const firstBook: BookInfo = books[0];
      const progress: number = firstBook.readProgress !== undefined ? firstBook.readProgress : 0;
      return {
        type: 'text',
        content: '鎮ㄦ鍦ㄩ槄璇汇€? + firstBook.title + '銆嬶紝杩涘害 ' + progress + '%銆?,
        confidence: CONFIDENCE_STATS
      };
    }

    // 闃呰缁熻
    if (cleanedMessage.includes('缁熻') || cleanedMessage.includes('鏃堕暱') || cleanedMessage.includes('鏃堕棿')) {
      const totalMinutes: number = this.getTotalReadDuration();
      const todayMinutes: number = this.getTodayReadDuration();
      const totalHours: number = Math.floor(totalMinutes / 60);
      const totalRemainder: number = totalMinutes % 60;
      const todayHours: number = Math.floor(todayMinutes / 60);
      const todayRemainder: number = todayMinutes % 60;
      return {
        type: 'text',
        content: '鎮ㄧ疮璁￠槄璇? + totalHours + ' 灏忔椂 ' + totalRemainder + ' 鍒嗛挓锛屼粖澶╅槄璇? + todayHours + ' 灏忔椂 ' + todayRemainder + ' 鍒嗛挓銆?,
        confidence: CONFIDENCE_STATS
      };
    }

    // 涔︾/绗旇
    if (cleanedMessage.includes('涔︾') || cleanedMessage.includes('绗旇')) {
      const bookmarks: Bookmark[] = this.getAllBookmarks();
      const notes: Note[] = this.getAllNotes();
      return {
        type: 'text',
        content: '鎮ㄦ湁 ' + bookmarks.length + ' 涓功绛撅紝' + notes.length + ' 绡囩瑪璁般€?,
        confidence: CONFIDENCE_STATS
      };
    }

    // 闂€欒
    if (cleanedMessage.includes('浣犲ソ') || cleanedMessage.includes('鎮ㄥソ')) {
      return {
        type: 'text',
        content: '鎮ㄥソ锛佹垜鏄皬鑹猴紝鏈変粈涔堝彲浠ュ府鎮ㄧ殑锛?,
        confidence: CONFIDENCE_HIGH
      };
    }

    // 榛樿鍥炲
    const defaultReplies: string[] = [
      '鎴戝彲浠ュ府鎮ㄧ鐞嗕功绫嶃€佹煡鐪嬮槄璇昏繘搴︺€佺粺璁￠槄璇绘椂闂寸瓑銆傝鍛婅瘔鎴戞偍闇€瑕佷粈涔堝府鍔╋紵',
      '鎴戞槸鎮ㄧ殑闃呰鍔╂墜锛屽彲浠ュ府鎮ㄦ壘涔︺€佽褰曡繘搴︺€佺鐞嗕功绛惧拰绗旇銆?,
      '鎮ㄥ彲浠ラ棶鎴戝叧浜庝功绫嶃€侀槄璇昏繘搴︺€佸緟鍔炰簨椤圭瓑闂銆?
    ];

    const randomIndex: number = Math.floor(Math.random() * defaultReplies.length);
    return {
      type: 'text',
      content: defaultReplies[randomIndex],
      confidence: CONFIDENCE_LOW
    };
  }

  // ==================== 鍝嶅簲澶勭悊 ====================

  /**
   * 鍙戦€佸搷搴?
   */
  private sendResponse(response: AgentResponse): void {
    if (this.responseCallback) {
      this.responseCallback(response);
    }

    // 濡傛灉鏄枃鏈搷搴旓紝浣跨敤 TTS 鏈楄
    if (response.type === 'text') {
      ttsService.speak(response.content);
    }
  }

  /**
   * 璁剧疆鍝嶅簲鍥炶皟
   */
  setResponseCallback(callback: (response: AgentResponse) => void): void {
    this.responseCallback = callback;
  }

  // ==================== 闃呰浼翠荆 ====================

  /**
   * 鏇存柊闃呰鐘舵€?
   */
  updateReadingState(bookId: string, page: number, context: string): void {
    this.companionState = {
      bookId: bookId,
      currentPage: page,
      context: context,
      lastInteraction: Date.now()
    };

    // 鏇存柊鑱婂ぉ涓婁笅鏂?
    const book: BookInfo | null = this.getBookById(bookId);
    if (book) {
      this.chatContext.bookTitle = book.title;
      this.chatContext.currentPage = page;
    }
  }

  /**
   * 鑾峰彇闃呰浼翠荆鐘舵€?
   */
  getCompanionState(): ReadingCompanionState | null {
    return this.companionState;
  }

  // ==================== 宸ュ叿鏂规硶 ====================

  /**
   * 閲婃斁璧勬簮
   */
  async release(): Promise<void> {
    await this.stopListening();

    if (this.speechRecognizer) {
      this.speechRecognizer.destroy();
      this.speechRecognizer = null;
    }

    this.isInitialized = false;
    this.context = null;
    this.companionState = null;
    this.commandHandlers.clear();
    this.responseCallback = null;
    this.onResultCallback = null;

    hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Released');
  }
}

// 瀵煎嚭鍗曚緥
export const xiaoyiAgent = XiaoyiAgentService.getInstance();
export default xiaoyiAgent;
