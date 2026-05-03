// AI 服务 - 智能阅读增强
// AI Service for Intelligent Reading Enhancement
// 基于华为云或本地模型提供智能摘要、翻译、问答等功能
// 适用于阅读应用的AI辅助功能

import { http } from '@kit.NetworkKit';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

/**
 * AI 引擎类型
 * AI Engine Type
 */
export enum AIEngine {
  HUAWEI_CLOUD = 'huawei_cloud',  // 华为云AI服务
  LOCAL = 'local',                 // 本地AI模型
  MOCK = 'mock'                    // 模拟/测试模式
}

/**
 * AI 任务类型
 * AI Task Type
 */
export enum TaskType {
  SUMMARY = 'summary',     // 内容摘要
  TRANSLATION = 'translation', // 翻译
  QNA = 'qna',             // 问答
  OUTLINE = 'outline'      // 大纲提取
}

/**
 * 支持的语言代码
 * Supported Language Codes
 */
export enum LanguageCode {
  ZH_CN = 'zh-CN',   // 简体中文
  EN_US = 'en-US',   // 英语
  JA_JP = 'ja-JP',   // 日语
  KO_KR = 'ko-KR',   // 韩语
  FR_FR = 'fr-FR',   // 法语
  DE_DE = 'de-DE',  // 德语
  ES_ES = 'es-ES',   // 西班牙语
  RU_RU = 'ru-RU',   // 俄语
  AUTO = 'auto'      // 自动检测
}

export interface AIResponseContent {
  content?: string;
}

export interface AIMessage {
  message?: AIResponseContent;
}

export interface AIResponseData {
  choices?: AIMessage[];
}

export interface SummaryOptions {
  level?: string;
  maxLength?: number;
}

/**
 * AI初始化配置
 * AI Initialization Config
 */
export interface AIInitConfig {
  engine?: AIEngine;
  apiKey?: string;
  endpoint?: string;
}

/**
 * AI请求选项
 * AI Request Options
 */
export interface AIRequestOptions {
  targetLanguage?: LanguageCode;
  maxLength?: number;
  style?: 'formal' | 'casual' | 'academic';
  level?: 'simple' | 'moderate' | 'detailed';
}

/**
 * AI 请求参数
 * AI Request Parameters
 */
export interface AIRequest {
  text: string;                    // 输入文本
  taskType: TaskType;              // 任务类型
  options?: AIRequestOptions;      // 可选参数
}

/**
 * AI 响应结果
 * AI Response Result
 */
export interface AIResponse {
  success: boolean;           // 是否成功
  result?: string;            // 处理结果
  error?: string;             // 错误信息
  processingTime?: number;    // 处理耗时(毫秒)
}

/**
 * 摘要结果
 * Summary Result
 */
export interface SummaryResult {
  summary: string;           // 摘要内容
  keyPoints: string[];       // 关键要点
  wordCount: number;         // 字数
  estimatedReadTime: number; // 预计阅读时间(分钟)
}

/**
 * 翻译结果
 * Translation Result
 */
export interface TranslationResult {
  translatedText: string;    // 翻译文本
  sourceLanguage: LanguageCode;  // 源语言
  targetLanguage: LanguageCode; // 目标语言
  confidence: number;         // 置信度
}

/**
 * AI 服务类
 * AI Service Class
 * 提供智能摘要、翻译、大纲提取、问答等功能
 */
class AIService {
  private static instance: AIService;
  private engine: AIEngine = AIEngine.MOCK;
  private apiKey: string = '';
  private endpoint: string = 'https://api.huaweicloud.com/v1/paas/ml/v1';
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   * Get Singleton Instance
   */
  static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  /**
   * 初始化AI服务
   * Initialize AI Service
   * @param config 配置参数
   */
  init(config?: AIInitConfig): void {
    if (config && config.engine) {
      this.engine = config.engine;
    }
    if (config && config.apiKey) {
      this.apiKey = config.apiKey;
    }
    if (config && config.endpoint) {
      this.endpoint = config.endpoint;
    }
    this.isInitialized = true;
    console.info('[AIService] Initialized with engine:', this.engine);
  }

  /**
   * 检查服务是否就绪
   * Check if service is ready
   */
  isReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 获取当前引擎类型
   * Get current engine type
   */
  getEngine(): AIEngine {
    return this.engine;
  }

  /**
   * 构建摘要提示词
   * Build summary prompt
   * @param text 原文
   * @param level 详细程度
   */
  private buildSummaryPrompt(text: string, level: string = 'moderate'): string {
    const instruction = level === 'simple' 
      ? '请用简洁易懂的语言总结以下内容要点：' 
      : level === 'detailed'
      ? '请详细总结以下内容，包括背景、要点和结论：'
      : '请简洁总结以下内容的主要要点：';
    return instruction + '\n\n' + text.substring(0, 8000);
  }

  /**
   * 构建翻译提示词
   * Build translation prompt
   * @param text 原文
   * @param targetLang 目标语言
   */
  private buildTranslationPrompt(text: string, targetLang: string): string {
    const langMap: Record<string, string> = {
      'en-US': '英文',
      'zh-CN': '中文',
      'ja-JP': '日文',
      'ko-KR': '韩文',
      'fr-FR': '法文',
      'de-DE': '德文',
      'es-ES': '西班牙文',
      'ru-RU': '俄文'
    }
    const targetName = langMap[targetLang] || '中文';
    return '请将以下内容翻译成' + targetName + '：\n\n' + text.substring(0, 5000);
  }

  /**
   * 构建大纲提取提示词
   * Build outline prompt
   * @param text 原文
   */
  private buildOutlinePrompt(text: string): string {
    return '请提取以下文章的大纲结构，以markdown列表格式呈现：\n\n' + text.substring(0, 10000);
  }

  /**
   * 处理AI请求
   * Process AI Request
   * @param request AI请求参数
   * @returns AI响应结果
   */
  async processAI(request: AIRequest): Promise<AIResponse> {
    const startTime = Date.now();
    
    try {
      let prompt: string;
      let taskType: string;

      switch (request.taskType) {
        case TaskType.SUMMARY:
          prompt = this.buildSummaryPrompt(request.text, request.options?.level);
          taskType = 'summary';
          break;
        case TaskType.TRANSLATION:
          prompt = this.buildTranslationPrompt(request.text, request.options?.targetLanguage || LanguageCode.ZH_CN);
          taskType = 'translation';
          break;
        case TaskType.OUTLINE:
          prompt = this.buildOutlinePrompt(request.text);
          taskType = 'outline';
          break;
        case TaskType.QNA:
          prompt = '基于以下内容，请回答问题：\n\n' + request.text;
          taskType = 'qna';
          break;
        default:
          prompt = request.text;
          taskType = 'general';
      }

      const result = await this.callAIApi(prompt, taskType);
      const processingTime = Date.now() - startTime;

      return {
        success: true,
        result,
        processingTime
      };
    } catch (error) {
      const err = error as Error;
      const message = error instanceof Error ? error.message : String(error);
      console.error('[AIService] Process failed:', message);
      return {
        success: false,
        error: message,
        processingTime: Date.now() - startTime
      };
    }
  }

  /**
   * 生成内容摘要
   * Generate Content Summary
   * @param text 要摘要的文本
   * @param options 摘要选项
   * @returns 摘要结果
   */
  async summarize(text: string, options?: SummaryOptions): Promise<SummaryResult> {
    let level = 'moderate';
    if (options && options.level) {
      level = options.level;
    }
    const prompt = this.buildSummaryPrompt(text, level);
    const startTime = Date.now();

    try {
      const result = await this.callAIApi(prompt, 'summary');
      const allLines = result.split('\n');
      const lines: string[] = [];
      for (let i = 0; i < allLines.length; i++) {
        if (allLines[i].trim()) {
          lines.push(allLines[i]);
        }
      }
      const keyPoints: string[] = [];
      for (let i = 0; i < Math.min(5, lines.length); i++) {
        keyPoints.push(lines[i].replace(new RegExp('^[•\-\*\d\.\s]+', ''), '').trim());
      }
      const summary = lines.join('\n');

      let maxLen = 500;
      if (options && options.maxLength) {
        maxLen = options.maxLength;
      }
      return {
        summary: summary.substring(0, maxLen),
        keyPoints,
        wordCount: summary.length,
        estimatedReadTime: Math.ceil(summary.length / 300)
      };
    } catch (error) {
      const err = error as Error;
      console.error('[AIService] Summary failed:', err.message);
      return {
        summary: text.substring(0, 200) + '...',
        keyPoints: ['内容摘要生成失败'],
        wordCount: text.length,
        estimatedReadTime: Math.ceil(text.length / 300)
      };
    }
  }

  /**
   * 翻译文本
   * Translate Text
   * @param text 要翻译的文本
   * @param targetLang 目标语言
   * @param sourceLang 源语言(默认自动检测)
   * @returns 翻译结果
   */
  async translate(text: string, targetLang: LanguageCode, sourceLang: LanguageCode = LanguageCode.AUTO): Promise<TranslationResult> {
    const prompt = this.buildTranslationPrompt(text, targetLang);
    
    try {
      const result = await this.callAIApi(prompt, 'translation');
      
      return {
        translatedText: result,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: 0.9
      };
    } catch (error) {
      const err = error as Error;
      console.error('[AIService] Translation failed:', err.message);
      return {
        translatedText: text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: 0.0
      };
    }
  }

  /**
   * 调用AI API
   * Call AI API
   * @param prompt 提示词
   * @param taskType 任务类型
   * @returns AI响应
   */
  private async callAIApi(prompt: string, taskType: string): Promise<string> {
    if (this.engine === AIEngine.MOCK) {
      return this.mockAIResponse(prompt, taskType);
    }

    if (this.engine === AIEngine.HUAWEI_CLOUD) {
      return this.callHuaweiCloud(prompt, taskType);
    }

    return this.mockAIResponse(prompt, taskType);
  }

  /**
   * 调用华为云AI
   * Call Huawei Cloud AI
   * @param prompt 提示词
   * @param taskType 任务类型
   * @returns AI响应
   */
  private async callHuaweiCloud(prompt: string, taskType: string): Promise<string> {
    const request = http.createHttp();

    try {
      const authHeader = 'Bearer ' + this.apiKey;

      const response = await request.request(
        this.endpoint + '/text/chat',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': authHeader
          },
          extraData: JSON.stringify({
            prompt,
            task_type: taskType,
            max_tokens: 2048,
            temperature: 0.7
          })
        }
      );

      if (response.responseCode === 200) {
        const resultStr = response.result !== null && response.result !== undefined
          ? String(response.result)
          : '{}';
        let data: AIResponseData;
        try {
          data = JSON.parse(resultStr);
        } catch (error) {
          const err = error as Error;
          console.error('AI response parse error:', err.message);
          return '生成内容失败';
        }
        const content = data?.choices?.[0]?.message?.content;
        return content ?? '生成内容失败';
      }

      throw new Error('API请求失败: ' + response.responseCode);
    } finally {
      request.destroy();
    }
  }

  /**
   * 模拟AI响应(用于测试)
   * Mock AI Response (for testing)
   * @param prompt 提示词
   * @param taskType 任务类型
   * @returns 模拟响应
   */
  private mockAIResponse(prompt: string, taskType: string): string {
    if (taskType === 'summary') {
      return '📝 内容摘要：\n' +
'• 本文讨论了阅读的重要性和方法\n' +
'• 强调了选择适合自己的阅读方式\n' +
'• 提出了几点实用建议供参考\n' +
'\n' +
'关键要点：\n' +
'1. 保持专注的阅读习惯\n' +
'2. 定期复习加深记忆\n' +
'3. 结合实践提高理解';
    }

    if (taskType === 'translation') {
      if (prompt.includes('英文')) {
        return '[Translated to English content...]';
      }
      return '[Translated content...]';
    }

    if (taskType === 'outline') {
      return '📋 文章大纲：\n' +
'1. 引言\n' +
'   - 背景介绍\n' +
'   - 研究意义\n' +
'2. 主要内容\n' +
'   - 第一章：基础概念\n' +
'   - 第二章：核心方法\n' +
'   - 第三章：实践应用\n' +
'3. 结论与展望';
    }

    return 'AI 内容生成中...\n\n这是一段模拟的 AI 响应内容。在实际部署时，请配置有效的 API Key 以获得更准确的结果。';
  }

  /**
   * 章节摘要
   * Chapter Summary
   * @param chapterTitle 章节标题
   * @param content 章节内容
   * @returns 摘要内容
   */
  async summarizeChapter(chapterTitle: string, content: string): Promise<string> {
    const prompt = '请为读者总结章节"' + chapterTitle + '"的核心内容，要求简洁明了：\n\n' + content.substring(0, 5000);
    return this.callAIApi(prompt, 'summary');
  }

  /**
   * 术语解释
   * Term Explanation
   * @param term 术语
   * @param context 上下文
   * @returns 解释内容
   */
  async explainTerm(term: string, context: string): Promise<string> {
    const prompt = '在以下上下文中，解释"' + term + '"的含义：\n\n' + context.substring(0, 2000);
    return this.callAIApi(prompt, 'qna');
  }

  /**
   * 生成阅读测验
   * Generate Reading Quiz
   * @param content 内容
   * @param count 题数
   * @returns 问题数组
   */
  async generateQuiz(content: string, count: number = 3): Promise<string[]> {
    const prompt = `基于以下内容，生成${count}道阅读理解选择题，每题单独一行，格式为"1. 题目内容"：\n\n${content.substring(0, 3000)}`;
    const result = await this.callAIApi(prompt, 'qna');
    const lines = result.split('\n').map(line => line.trim()).filter(line => line.length > 0);
    const quizLines: string[] = [];
    const questionRegex = new RegExp('^\\d+[\\.\\)]\\s*.+');
    for (const line of lines) {
      if (questionRegex.test(line) && quizLines.length < count) {
        quizLines.push(line);
      }
    }
    return quizLines;
  }
}

export const aiService = AIService.getInstance();
export default aiService;
