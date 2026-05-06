import { logger } from '../../../utils/Logger';
// 小艺智能体服务 - 华为智慧助手集成
// Xiaoyi Agent Service - Huawei Smart Assistant Integration
// 使用语音识别和AI能力，提供智能阅读辅助功能
// 支持语音指令控制、AI问答、阅读推荐等

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { coreSpeechService } from './CoreSpeechService';
import { aiService, TaskType } from './AIService';
import { BookInfo, Bookmark, Note } from '../models/CoreBookModel';
import { ReadStatus } from '../models/BookModel';

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
 * 智能体操作结果
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

  private constructor() {}

  /**
   * 获取所有书籍(从preferenceManager直接读取)
   */
  private getAllBooks(): BookInfo[] {
    try {
      return preferenceManager.getBooks();
    } catch (error) {
      const err = error as Error;
      logger.error('[XiaoyiAgent] Get books failed:', err.message);
      return [];
    }
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
      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Initializing...');
      this.context = context;

      // 注册命令处理器
      this.registerCommandHandlers();

      this.isInitialized = true;
      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Initialized successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'XiaoyiAgent', 'Init failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  /**
   * 注册命令处理器
   */
  private registerCommandHandlers(): void {
    // 翻页命令
    this.commandHandlers.set('next_page', {
      keywords: ['下一页', '下一章', '继续', '向前'],
      handler: async (params) => {
        return {
          type: 'action',
          content: '翻到下一页',
          actions: [{ type: 'page_navigation', params: { direction: 'next' } }],
          confidence: CONFIDENCE_HIGH
        };
      }
    });

    this.commandHandlers.set('prev_page', {
      keywords: ['上一页', '上一章', '返回', '向后'],
      handler: async (params) => {
        return {
          type: 'action',
          content: '翻到上一页',
          actions: [{ type: 'page_navigation', params: { direction: 'prev' } }],
          confidence: CONFIDENCE_HIGH
        };
      }
    });

    // 书签命令
    this.commandHandlers.set('add_bookmark', {
      keywords: ['添加书签', '加入书签', '收藏这里'],
      handler: async (params) => {
        return {
          type: 'action',
          content: '已添加书签',
          actions: [{ type: 'bookmark', params: { action: 'add' } }],
          confidence: CONFIDENCE_HIGH
        };
      }
    });

    // 字体调整命令
    this.commandHandlers.set('font_size', {
      keywords: ['字体', '字号', '大小'],
      handler: async (params) => {
        const delta = params.value ? Number(params.value) : 2;
        return {
          type: 'action',
          content: `字体大小调整${delta}`,
          actions: [{ type: 'font_adjust', params: { delta } }],
          confidence: CONFIDENCE_MEDIUM
        };
      }
    });

    // 搜索书籍命令
    this.commandHandlers.set('search_book', {
      keywords: ['搜索', '查找', '找书'],
      handler: async (params) => {
        const query = params.rawText || '';
        const results = this.searchBooks(query);
        return {
          type: 'recommendation',
          content: `找到${results.length}本书`,
          actions: results.map(book => ({
            type: 'book_result',
            params: { title: book.title, url: book.filePath }
          })),
          confidence: CONFIDENCE_MEDIUM
        };
      }
    });

    // 统计命令
    this.commandHandlers.set('stats', {
      keywords: ['统计', '进度', '读了多少'],
      handler: async (params) => {
        const stats = this.getReadingStats();
        return {
          type: 'text',
          content: stats,
          confidence: CONFIDENCE_STATS
        };
      }
    });
  }

  /**
   * 处理语音命令
   */
  async processVoiceCommand(text: string): Promise<AgentResponse> {
    try {
      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Processing voice command: %{public}s', text);

      // 遍历所有命令处理器
      for (const [key, handler] of this.commandHandlers.entries()) {
        for (const keyword of handler.keywords) {
          if (text.includes(keyword)) {
            hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Matched command: %{public}s', key);
            return await handler.handler({ rawText: text });
          }
        }
      }

      // 未匹配到命令，尝试AI对话
      return await this.handleAIChat(text);
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'XiaoyiAgent', 'Process voice command failed: %{public}s', err.message);
      return {
        type: 'text',
        content: '抱歉，我没有理解您的指令',
        confidence: 0
      };
    }
  }

  /**
   * 处理AI对话
   */
  private async handleAIChat(text: string): Promise<AgentResponse> {
    try {
      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Calling AI service for chat');
      
      // 构建上下文信息
      let contextInfo = '';
      if (this.chatContext.bookTitle) {
        contextInfo += `当前阅读书籍: ${this.chatContext.bookTitle}\n`;
      }
      if (this.chatContext.chapterTitle) {
        contextInfo += `当前章节: ${this.chatContext.chapterTitle}\n`;
      }
      
      // 使用AIService进行智能对话
      const prompt = contextInfo ? `${contextInfo}\n用户问题: ${text}` : text;
      
      const response = await aiService.processAI({
        text: prompt,
        taskType: TaskType.QNA
      });
      
      if (response.success && response.result) {
        hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'AI response received');
        return {
          type: 'text',
          content: response.result,
          confidence: CONFIDENCE_HIGH
        };
      } else {
        hilog.warn(LOG_DOMAIN, 'XiaoyiAgent', 'AI service failed:', response.error);
        return {
          type: 'text',
          content: '抱歉，AI服务暂时不可用，请稍后再试',
          confidence: CONFIDENCE_LOW
        };
      }
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'XiaoyiAgent', 'Handle AI chat failed: %{public}s', err.message);
      return {
        type: 'text',
        content: '抱歉，处理您的问题时出现了错误',
        confidence: 0
      };
    }
  }

  /**
   * 搜索书籍
   */
  private searchBooks(query: string): BookInfo[] {
    const allBooks = this.getAllBooks();
    const results: BookInfo[] = [];

    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (book.title.includes(query) || book.author.includes(query)) {
        results.push(book);
        if (results.length >= MAX_SEARCH_RESULTS) {
          break;
        }
      }
    }

    return results;
  }

  /**
   * 获取阅读统计
   */
  private getReadingStats(): string {
    const allBooks = this.getAllBooks();
    let readingCount = 0;
    let finishedCount = 0;

    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].status === ReadStatus.READING) {
        readingCount++;
      } else if (allBooks[i].status === ReadStatus.FINISHED) {
        finishedCount++;
      }
    }

    return `您共有${allBooks.length}本书，正在阅读${readingCount}本，已完成${finishedCount}本`;
  }

  /**
   * 设置阅读伴侣状态
   */
  setCompanionState(state: ReadingCompanionState): void {
    this.companionState = state;
    hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Companion state updated');
  }

  /**
   * 获取阅读伴侣状态
   */
  getCompanionState(): ReadingCompanionState | null {
    return this.companionState;
  }

  /**
   * 设置聊天上下文
   */
  setChatContext(context: ChatContext): void {
    this.chatContext = context;
  }

  /**
   * 设置响应回调
   */
  setResponseCallback(callback: (response: AgentResponse) => void): void {
    this.responseCallback = callback;
  }

  /**
   * 开始语音监听
   */
  async startListening(): Promise<boolean> {
    try {
      if (!this.isReady()) {
        throw new Error('Service not initialized');
      }

      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Start listening');
      this.isListening = true;

      // TODO: 集成语音识别SDK
      // 目前使用CoreSpeechService作为替代方案
      
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'XiaoyiAgent', 'Start listening failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 停止语音监听
   */
  async stopListening(): Promise<void> {
    try {
      hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Stop listening');
      this.isListening = false;
    } catch (error) {
      const err = error as Error;
      hilog.error(LOG_DOMAIN, 'XiaoyiAgent', 'Stop listening failed: %{public}s', err.message);
    }
  }

  /**
   * 检查是否在监听
   */
  isCurrentlyListening(): boolean {
    return this.isListening;
  }

  /**
   * 释放资源
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    this.isListening = false;
    this.commandHandlers.clear();
    hilog.info(LOG_DOMAIN, 'XiaoyiAgent', 'Released');
  }
}

// 导出单例
export const xiaoyiAgent = XiaoyiAgentService.getInstance();
export default xiaoyiAgent;
