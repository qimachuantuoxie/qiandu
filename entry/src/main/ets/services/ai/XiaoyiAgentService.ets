// 小艺智能体服务 - 华为智慧助手集成
// Xiaoyi Agent Service - Huawei Smart Assistant Integration
// 使用语音识别和AI能力，提供智能阅读辅助功能
// 支持语音指令控制、AI问答、阅读推荐等
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

// 日志域
const LOG_DOMAIN = 0xFF0A;

// 置信度常量
const CONFIDENCE_HIGH = 0.95;
const CONFIDENCE_MEDIUM = 0.85;
const CONFIDENCE_LOW = 0.7;
const CONFIDENCE_DEFAULT = 0.8;
const CONFIDENCE_STATS = 0.9;

// 数量限制常量
const MAX_SEARCH_RESULTS = 5;
const MAX_RECOMMENDATIONS = 3;

/**
 * 智能体能力枚举
 * Agent Capability Enum
 */
export enum AgentCapability {
  VOICE_COMMAND = 'voice_command',        // 语音指令
  AI_CHAT = 'ai_chat',                   // AI对话
  CONTENT_RECOMMEND = 'content_recommend', // 内容推荐
  BOOK_QUERY = 'book_query',             // 书籍查询
  READING_COMPANION = 'reading_companion'  // 阅读伴侣
}

export interface VoiceCommandParams {
  rawText?: string;
  direction?: string;
  action?: string;
  key?: string;
  value?: string | number;
}

/**
 * 语音命令结构
 * Voice Command Structure
 */
export interface VoiceCommand {
  action: string;                        // 操作类型
  params: VoiceCommandParams;            // 参数
  confidence: number;                    // 置信度
}

/**
 * 智能体响应结果
 * Agent Response Structure
 */
export interface AgentResponse {
  type: 'text' | 'action' | 'recommendation'; // 响应类型
  content: string;                     // 内容
  actions?: AgentAction[];             // 操作列表
  confidence: number;                  // 置信度
}

/**
 * 智能体操作结构
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
  type: string;                        // 操作类型
  params: AgentActionParams;           // 参数
}

/**
 * 书籍查询条件
 * Book Query Condition
 */
export interface BookQuery {
  title?: string;                      // 书名关键词
  author?: string;                     // 作者
  genre?: string;                      // 分类
  tags?: string[];                     // 标签
}

/**
 * 聊天上下文
 * Chat Context
 */
export interface ChatContext {
  bookTitle?: string;
  currentPage?: number;
  chapterTitle?: string;
}

/**
 * 阅读伴侣状态
 * Reading Companion State
 */
export interface ReadingCompanionState {
  bookId: string;                      // 书籍ID
  currentPage: number;                 // 当前页码
  context: string;                     // 上下文
  lastInteraction: number;            // 上次交互时间
}

/**
 * 语音命令处理器
 */
interface CommandHandler {
  keywords: string[];
  handler: (params: VoiceCommandParams) => Promise<AgentResponse>;
}

/**
 * 小艺智能体服务类
 * Xiaoyi Agent Service Class
 */
class XiaoyiAgentService {
  /** 单例实例 */
  private static instance: XiaoyiAgentService;

  /** 上下文 */
  private context: common.Context | null = null;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /** 语音识别器 */
  private speechRecognizer: StubSpeechRecognizerController | null = null;

  /** 当前阅读状态 */
  private companionState: ReadingCompanionState | null = null;

  /** 聊天上下文 */
  private chatContext: ChatContext = {};

  /** 是否正在监听语音 */
  private isListening: boolean = false;

  /** 命令处理器映射 */
  private commandHandlers: Map<string, CommandHandler> = new Map();

  /** 响应回调 */
  private responseCallback: ((response: AgentResponse) => void) | null = null;

  // ArkTS strict mode: use explicit callback reference instead of inline object method
  private onResultCallback: ((result: StubSpeechRecognitionResult) => void) | null = null;

  private constructor() {}

  /**
   * 获取所有书籍(从preferenceManager直接读取)
   */
  private getAllBooks(): BookInfo[] {
    return preferenceManager.getBooks();
  }

  /**
   * 根据ID获取书籍
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
   * 搜索书籍
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
   * 获取总阅读时长(分钟)
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
   * 获取今日阅读时长(分钟)
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
   * 获取所有书签
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
   * 获取所有笔记
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
   * 获取单例实例
   */
  static getInstance(): XiaoyiAgentService {
    if (!XiaoyiAgentService.instance) {
      XiaoyiAgentService.instance = new XiaoyiAgentService();
    }
    return XiaoyiAgentService.instance;
  }

  /**
   * 初始化服务
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Initializing...');
      this.context = context;

      // 初始化语音识别
      await this.initSpeechRecognizer();

      // 注册命令处理器
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
   * 初始化语音识别器
   */
  private async initSpeechRecognizer(): Promise<void> {
    try {
      // 创建语音识别器(using stub)
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

      // 设置识别结果监听
      this.speechRecognizer.on('result', this.onResultCallback);

      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'SpeechRecognizer initialized (stub)');
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Init SpeechRecognizer failed: %{public}s', err.message);
      throw new Error('Speech recognizer initialization failed: ' + err.message);
    }
  }

  /**
   * 注册命令处理器
   */
  private registerCommandHandlers(): void {
    // 翻页命令
    this.commandHandlers.set('page_turn', {
      keywords: ['下一页', '上一页', '翻页'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handlePageTurn(params)
    });

    // 书签命令
    this.commandHandlers.set('bookmark', {
      keywords: ['添加书签', '加入书签', '收藏'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleBookmark(params)
    });

    // 朗读命令
    this.commandHandlers.set('read_aloud', {
      keywords: ['朗读', '读给我听', '开始朗读'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleReadAloud(params)
    });

    // 搜索命令
    this.commandHandlers.set('search', {
      keywords: ['搜索', '查找', '找书'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleSearch(params)
    });

    // 统计命令
    this.commandHandlers.set('stats', {
      keywords: ['统计', '阅读统计', '看了多久'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleStats(params)
    });

    // 推荐命令
    this.commandHandlers.set('recommend', {
      keywords: ['推荐', '推荐书', '有什么好书'],
      handler: async (params: VoiceCommandParams): Promise<AgentResponse> => await this.handleRecommend(params)
    });
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 语音交互 ====================

  /**
   * 开始语音监听
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
   * 停止语音监听
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
   * 处理语音输入
   */
  private async handleVoiceInput(text: string): Promise<void> {
    try {
      hilog.info(LOG_DOMAIN, 'Xiaoyi', 'Voice input: %{public}s', text);

      // 匹配命令
      const command: CommandHandler | null = this.matchCommand(text);
      if (command) {
        const response: AgentResponse = await command.handler({ rawText: text });
        this.sendResponse(response);
      } else {
        // 作为聊天输入
        const response: AgentResponse = await this.handleChat(text);
        this.sendResponse(response);
      }
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'Xiaoyi', 'Handle voice input failed: %{public}s', err.message);
    }
  }

  /**
   * 匹配命令
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

  // ==================== 命令处理 ====================

  /**
   * 处理翻页命令
   */
  private async handlePageTurn(params: VoiceCommandParams): Promise<AgentResponse> {
    const rawText: string = params.rawText || '';
    const direction: string = rawText.includes('上') ? 'prev' : 'next';
    const contentText: string = direction === 'next' ? '翻到下一页' : '翻到上一页';

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
   * 处理书签命令
   */
  private async handleBookmark(params: VoiceCommandParams): Promise<AgentResponse> {
    const action: AgentAction = {
      type: 'add_bookmark',
      params: {}
    };

    return {
      type: 'action',
      content: '已添加书签',
      actions: [action],
      confidence: CONFIDENCE_HIGH
    };
  }

  /**
   * 处理朗读命令
   */
  private async handleReadAloud(params: VoiceCommandParams): Promise<AgentResponse> {
    const action: AgentAction = {
      type: 'start_tts',
      params: {}
    };

    return {
      type: 'action',
      content: '开始朗读',
      actions: [action],
      confidence: CONFIDENCE_HIGH
    };
  }

  /**
   * 处理搜索命令
   */
  private async handleSearch(params: VoiceCommandParams): Promise<AgentResponse> {
    const rawText: string = params.rawText || '';
    const query: string = rawText.replace(new RegExp('搜索|查找|找', 'g'), '').trim();

    if (!query) {
      return {
        type: 'text',
        content: '请告诉我您要搜索的书籍名称',
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
      content: '找到 ' + books.length + ' 本相关书籍',
      actions: actions,
      confidence: CONFIDENCE_MEDIUM
    };
  }

  /**
   * 处理统计命令
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
      content = '您正在阅读《' + book.title + '》，进度 ' + progress + '%';
    } else {
      content = '您还没有开始阅读';
    }

    return {
      type: 'text',
      content: content,
      confidence: CONFIDENCE_STATS
    };
  }

  /**
   * 处理推荐命令
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
        content: '暂无推荐，请导入更多书籍',
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
      content: '为您推荐以下书籍',
      actions: actions,
      confidence: CONFIDENCE_MEDIUM
    };
  }

  /**
   * 处理聊天 - 使用智能回复逻辑
   */
  private async handleChat(text: string): Promise<AgentResponse> {
    const cleanedMessage: string = text.trim();

    // 书籍相关
    if (cleanedMessage.includes('书') || cleanedMessage.includes('阅读') || cleanedMessage.includes('小说')) {
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
        content: '您目前有 ' + bookCount + ' 本书，正在阅读' + readingCount + ' 本。需要我帮您找书吗？',
        confidence: CONFIDENCE_STATS
      };
    }

    // 阅读进度
    if (cleanedMessage.includes('进度') || cleanedMessage.includes('读了多少')) {
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
          content: '您还没有开始阅读任何书籍。',
          confidence: CONFIDENCE_STATS
        };
      }
      const firstBook: BookInfo = books[0];
      const progress: number = firstBook.readProgress !== undefined ? firstBook.readProgress : 0;
      return {
        type: 'text',
        content: '您正在阅读《' + firstBook.title + '》，进度 ' + progress + '%。',
        confidence: CONFIDENCE_STATS
      };
    }

    // 阅读统计
    if (cleanedMessage.includes('统计') || cleanedMessage.includes('时长') || cleanedMessage.includes('时间')) {
      const totalMinutes: number = this.getTotalReadDuration();
      const todayMinutes: number = this.getTodayReadDuration();
      const totalHours: number = Math.floor(totalMinutes / 60);
      const totalRemainder: number = totalMinutes % 60;
      const todayHours: number = Math.floor(todayMinutes / 60);
      const todayRemainder: number = todayMinutes % 60;
      return {
        type: 'text',
        content: '您累计阅读' + totalHours + ' 小时 ' + totalRemainder + ' 分钟，今天阅读' + todayHours + ' 小时 ' + todayRemainder + ' 分钟。',
        confidence: CONFIDENCE_STATS
      };
    }

    // 书签/笔记
    if (cleanedMessage.includes('书签') || cleanedMessage.includes('笔记')) {
      const bookmarks: Bookmark[] = this.getAllBookmarks();
      const notes: Note[] = this.getAllNotes();
      return {
        type: 'text',
        content: '您有 ' + bookmarks.length + ' 个书签，' + notes.length + ' 篇笔记。',
        confidence: CONFIDENCE_STATS
      };
    }

    // 问候语
    if (cleanedMessage.includes('你好') || cleanedMessage.includes('您好')) {
      return {
        type: 'text',
        content: '您好！我是小艺，有什么可以帮您的？',
        confidence: CONFIDENCE_HIGH
      };
    }

    // 默认回复
    const defaultReplies: string[] = [
      '我可以帮您管理书籍、查看阅读进度、统计阅读时间等。请告诉我您需要什么帮助？',
      '我是您的阅读助手，可以帮您找书、记录进度、管理书签和笔记。',
      '您可以问我关于书籍、阅读进度、待办事项等问题。'
    ];

    const randomIndex: number = Math.floor(Math.random() * defaultReplies.length);
    return {
      type: 'text',
      content: defaultReplies[randomIndex],
      confidence: CONFIDENCE_LOW
    };
  }

  // ==================== 响应处理 ====================

  /**
   * 发送响应
   */
  private sendResponse(response: AgentResponse): void {
    if (this.responseCallback) {
      this.responseCallback(response);
    }

    // 如果是文本响应，使用 TTS 朗读
    if (response.type === 'text') {
      ttsService.speak(response.content);
    }
  }

  /**
   * 设置响应回调
   */
  setResponseCallback(callback: (response: AgentResponse) => void): void {
    this.responseCallback = callback;
  }

  // ==================== 阅读伴侣 ====================

  /**
   * 更新阅读状态
   */
  updateReadingState(bookId: string, page: number, context: string): void {
    this.companionState = {
      bookId: bookId,
      currentPage: page,
      context: context,
      lastInteraction: Date.now()
    };

    // 更新聊天上下文
    const book: BookInfo | null = this.getBookById(bookId);
    if (book) {
      this.chatContext.bookTitle = book.title;
      this.chatContext.currentPage = page;
    }
  }

  /**
   * 获取阅读伴侣状态
   */
  getCompanionState(): ReadingCompanionState | null {
    return this.companionState;
  }

  // ==================== 工具方法 ====================

  /**
   * 释放资源
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

// 导出单例
export const xiaoyiAgent = XiaoyiAgentService.getInstance();
export default xiaoyiAgent;
