import { logger } from '../../../utils/Logger';
// AI 鏈嶅姟 - 鏅鸿兘闃呰�澧炲己
// AI Service for Intelligent Reading Enhancement
// 鍩轰簬鍗庝负浜戞垨鏈�湴妯″瀷鎻愪緵鏅鸿兘鎽樿�銆佺炕璇戙€侀棶绛旂瓑鍔熻兘
// 閫傜敤浜庨槄璇诲簲鐢ㄧ殑AI杈呭姪鍔熻兘

import { http } from '@kit.NetworkKit';
import { errorHandler, ErrorLevel } from '../utils/ErrorHandler';

/**
 * AI 寮曟搸绫诲瀷
 * AI Engine Type
 */
export enum AIEngine {
  HUAWEI_CLOUD = 'huawei_cloud',  // 鍗庝负浜慉I鏈嶅姟
  LOCAL = 'local',                 // 鏈�湴AI妯″瀷
  MOCK = 'mock'                    // 妯℃嫙/娴嬭瘯妯″紡
}

/**
 * AI 浠诲姟绫诲瀷
 * AI Task Type
 */
export enum TaskType {
  SUMMARY = 'summary',     // 鍐呭�鎽樿�
  TRANSLATION = 'translation', // 缈昏瘧
  QNA = 'qna',             // 闂�瓟
  OUTLINE = 'outline'      // 澶х翰鎻愬彇
}

/**
 * 鏀�寔鐨勮�瑷€浠ｇ爜
 * Supported Language Codes
 */
export enum LanguageCode {
  ZH_CN = 'zh-CN',   // 绠€浣撲腑鏂?  EN_US = 'en-US',   // 鑻辫�
  JA_JP = 'ja-JP',   // 鏃ヨ�
  KO_KR = 'ko-KR',   // 闊╄�
  FR_FR = 'fr-FR',   // 娉曡�
  DE_DE = 'de-DE',  // 寰疯�
  ES_ES = 'es-ES',   // 瑗跨彮鐗欒�
  RU_RU = 'ru-RU',   // 淇勮�
  AUTO = 'auto'      // 鑷�姩妫€娴?}

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
 * AI鍒濆�鍖栭厤缃? * AI Initialization Config
 */
export interface AIInitConfig {
  engine?: AIEngine;
  apiKey?: string;
  endpoint?: string;
}

/**
 * AI璇锋眰閫夐」
 * AI Request Options
 */
export interface AIRequestOptions {
  targetLanguage?: LanguageCode;
  maxLength?: number;
  style?: 'formal' | 'casual' | 'academic';
  level?: 'simple' | 'moderate' | 'detailed';
}

/**
 * AI 璇锋眰鍙傛暟
 * AI Request Parameters
 */
export interface AIRequest {
  text: string;                    // 杈撳叆鏂囨湰
  taskType: TaskType;              // 浠诲姟绫诲瀷
  options?: AIRequestOptions;      // 鍙�€夊弬鏁?}

/**
 * AI 鍝嶅簲缁撴灉
 * AI Response Result
 */
export interface AIResponse {
  success: boolean;           // 鏄�惁鎴愬姛
  result?: string;            // 澶勭悊缁撴灉
  error?: string;             // 閿欒�淇℃伅
  processingTime?: number;    // 澶勭悊鑰楁椂(姣��)
}

/**
 * 鎽樿�缁撴灉
 * Summary Result
 */
export interface SummaryResult {
  summary: string;           // 鎽樿�鍐呭�
  keyPoints: string[];       // 鍏抽敭瑕佺偣
  wordCount: number;         // 瀛楁暟
  estimatedReadTime: number; // 棰勮�闃呰�鏃堕棿(鍒嗛挓)
}

/**
 * 缈昏瘧缁撴灉
 * Translation Result
 */
export interface TranslationResult {
  translatedText: string;    // 缈昏瘧鏂囨湰
  sourceLanguage: LanguageCode;  // 婧愯�瑷€
  targetLanguage: LanguageCode; // 鐩�爣璇�█
  confidence: number;         // 缃�俊搴?}

/**
 * AI 鏈嶅姟绫? * AI Service Class
 * 鎻愪緵鏅鸿兘鎽樿�銆佺炕璇戙€佸ぇ绾叉彁鍙栥€侀棶绛旂瓑鍔熻兘
 */
class AIService {
  private static instance: AIService;
  private engine: AIEngine = AIEngine.MOCK;
  private apiKey: string = '';
  private endpoint: string = 'https://api.huaweicloud.com/v1/paas/ml/v1';
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   * Get Singleton Instance
   */
  static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  /**
   * 鍒濆�鍖朅I鏈嶅姟
   * Initialize AI Service
   * @param config 閰嶇疆鍙傛暟
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
    logger.info('[AIService] Initialized with engine:', this.engine);
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?   * Check if service is ready
   */
  isReady(): boolean {
    return this.isInitialized;
  }

  /**
   * 鑾峰彇褰撳墠寮曟搸绫诲瀷
   * Get current engine type
   */
  getEngine(): AIEngine {
    return this.engine;
  }

  /**
   * 鏋勫缓鎽樿�鎻愮ず璇?   * Build summary prompt
   * @param text 鍘熸枃
   * @param level 璇︾粏绋嬪害
   */
  private buildSummaryPrompt(text: string, level: string = 'moderate'): string {
    const instruction = level === 'simple' 
      ? '璇风敤绠€娲佹槗鎳傜殑璇�█鎬荤粨浠ヤ笅鍐呭�瑕佺偣锛? 
      : level === 'detailed'
      ? '璇疯�缁嗘€荤粨浠ヤ笅鍐呭�锛屽寘鎷�儗鏅�€佽�鐐瑰拰缁撹�锛?
      : '璇风畝娲佹€荤粨浠ヤ笅鍐呭�鐨勪富瑕佽�鐐癸細';
    return instruction + '\n\n' + text.substring(0, 8000);
  }

  /**
   * 鏋勫缓缈昏瘧鎻愮ず璇?   * Build translation prompt
   * @param text 鍘熸枃
   * @param targetLang 鐩�爣璇�█
   */
  private buildTranslationPrompt(text: string, targetLang: string): string {
    const langMap: Record<string, string> = {
      'en-US': '鑻辨枃',
      'zh-CN': '涓�枃',
      'ja-JP': '鏃ユ枃',
      'ko-KR': '闊╂枃',
      'fr-FR': '娉曟枃',
      'de-DE': '寰锋枃',
      'es-ES': '瑗跨彮鐗欐枃',
      'ru-RU': '淇勬枃'
    }
    const targetName = langMap[targetLang] || '涓�枃';
    return '璇峰皢浠ヤ笅鍐呭�缈昏瘧鎴? + targetName + '锛歕n\n' + text.substring(0, 5000);
  }

  /**
   * 鏋勫缓澶х翰鎻愬彇鎻愮ず璇?   * Build outline prompt
   * @param text 鍘熸枃
   */
  private buildOutlinePrompt(text: string): string {
    return '璇锋彁鍙栦互涓嬫枃绔犵殑澶х翰缁撴瀯锛屼互markdown鍒楄〃鏍煎紡鍛堢幇锛歕n\n' + text.substring(0, 10000);
  }

  /**
   * 澶勭悊AI璇锋眰
   * Process AI Request
   * @param request AI璇锋眰鍙傛暟
   * @returns AI鍝嶅簲缁撴灉
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
          prompt = '鍩轰簬浠ヤ笅鍐呭�锛岃�鍥炵瓟闂��锛歕n\n' + request.text;
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
      logger.error('[AIService] Process failed:', message);
      return {
        success: false,
        error: message,
        processingTime: Date.now() - startTime
      };
    }
  }

  /**
   * 鐢熸垚鍐呭�鎽樿�
   * Generate Content Summary
   * @param text 瑕佹憳瑕佺殑鏂囨湰
   * @param options 鎽樿�閫夐」
   * @returns 鎽樿�缁撴灉
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
        keyPoints.push(lines[i].replace(new RegExp('^[鈥�-\*\d\.\s]+', ''), '').trim());
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
      logger.error('[AIService] Summary failed:', err.message);
      return {
        summary: text.substring(0, 200) + '...',
        keyPoints: ['鍐呭�鎽樿�鐢熸垚澶辫触'],
        wordCount: text.length,
        estimatedReadTime: Math.ceil(text.length / 300)
      };
    }
  }

  /**
   * 缈昏瘧鏂囨湰
   * Translate Text
   * @param text 瑕佺炕璇戠殑鏂囨湰
   * @param targetLang 鐩�爣璇�█
   * @param sourceLang 婧愯�瑷€(榛樿�鑷�姩妫€娴?
   * @returns 缈昏瘧缁撴灉
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
      logger.error('[AIService] Translation failed:', err.message);
      return {
        translatedText: text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
        confidence: 0.0
      };
    }
  }

  /**
   * 璋冪敤AI API
   * Call AI API
   * @param prompt 鎻愮ず璇?   * @param taskType 浠诲姟绫诲瀷
   * @returns AI鍝嶅簲
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
   * 璋冪敤鍗庝负浜慉I
   * Call Huawei Cloud AI
   * @param prompt 鎻愮ず璇?   * @param taskType 浠诲姟绫诲瀷
   * @returns AI鍝嶅簲
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
          logger.error('AI response parse error:', err.message);
          return '鐢熸垚鍐呭�澶辫触';
        }
        const content = data?.choices?.[0]?.message?.content;
        return content ? content : '鐢熸垚鍐呭�澶辫触';
      }

      throw new Error('API璇锋眰澶辫触: ' + response.responseCode);
    } finally {
      request.destroy();
    }
  }

  /**
   * 妯℃嫙AI鍝嶅簲(鐢ㄤ簬娴嬭瘯)
   * Mock AI Response (for testing)
   * @param prompt 鎻愮ず璇?   * @param taskType 浠诲姟绫诲瀷
   * @returns 妯℃嫙鍝嶅簲
   */
  private mockAIResponse(prompt: string, taskType: string): string {
    if (taskType === 'summary') {
      return '馃摑 鍐呭�鎽樿�锛歕n' +
'鈥?鏈�枃璁ㄨ�浜嗛槄璇荤殑閲嶈�鎬у拰鏂规硶\n' +
'鈥?寮鸿皟浜嗛€夋嫨閫傚悎鑷�繁鐨勯槄璇绘柟寮廫n' +
'鈥?鎻愬嚭浜嗗嚑鐐瑰疄鐢ㄥ缓璁�緵鍙傝€僜n' +
'\n' +
'鍏抽敭瑕佺偣锛歕n' +
'1. 淇濇寔涓撴敞鐨勯槄璇讳範鎯痋n' +
'2. 瀹氭湡澶嶄範鍔犳繁璁板繂\n' +
'3. 缁撳悎瀹炶返鎻愰珮鐞嗚В';
    }

    if (taskType === 'translation') {
      if (prompt.includes('鑻辨枃')) {
        return '[Translated to English content...]';
      }
      return '[Translated content...]';
    }

    if (taskType === 'outline') {
      return '馃搵 鏂囩珷澶х翰锛歕n' +
'1. 寮曡█\n' +
'   - 鑳屾櫙浠嬬粛\n' +
'   - 鐮旂┒鎰忎箟\n' +
'2. 涓昏�鍐呭�\n' +
'   - 绗�竴绔狅細鍩虹�姒傚康\n' +
'   - 绗�簩绔狅細鏍稿績鏂规硶\n' +
'   - 绗�笁绔狅細瀹炶返搴旂敤\n' +
'3. 缁撹�涓庡睍鏈?;
    }

    return 'AI 鍐呭�鐢熸垚涓?..\n\n杩欐槸涓€娈垫ā鎷熺殑 AI 鍝嶅簲鍐呭�銆傚湪瀹為檯閮ㄧ讲鏃讹紝璇烽厤缃�湁鏁堢殑 API Key 浠ヨ幏寰楁洿鍑嗙‘鐨勭粨鏋溿€?;
  }

  /**
   * 绔犺妭鎽樿�
   * Chapter Summary
   * @param chapterTitle 绔犺妭鏍囬�
   * @param content 绔犺妭鍐呭�
   * @returns 鎽樿�鍐呭�
   */
  async summarizeChapter(chapterTitle: string, content: string): Promise<string> {
    const prompt = '璇蜂负璇昏€呮€荤粨绔犺妭"' + chapterTitle + '"鐨勬牳蹇冨唴瀹癸紝瑕佹眰绠€娲佹槑浜嗭細\n\n' + content.substring(0, 5000);
    return this.callAIApi(prompt, 'summary');
  }

  /**
   * 鏈��瑙ｉ噴
   * Term Explanation
   * @param term 鏈��
   * @param context 涓婁笅鏂?   * @returns 瑙ｉ噴鍐呭�
   */
  async explainTerm(term: string, context: string): Promise<string> {
    const prompt = '鍦ㄤ互涓嬩笂涓嬫枃涓�紝瑙ｉ噴"' + term + '"鐨勫惈涔夛細\n\n' + context.substring(0, 2000);
    return this.callAIApi(prompt, 'qna');
  }

  /**
   * 鐢熸垚闃呰�娴嬮獙
   * Generate Reading Quiz
   * @param content 鍐呭�
   * @param count 棰樻暟
   * @returns 闂��鏁扮粍
   */
  async generateQuiz(content: string, count: number = 3): Promise<string[]> {
    const prompt = `鍩轰簬浠ヤ笅鍐呭�锛岀敓鎴?{count}閬撻槄璇荤悊瑙ｉ€夋嫨棰橈紝姣忛�鍗曠嫭涓€琛岋紝鏍煎紡涓?1. 棰樼洰鍐呭�"锛歕n\n${content.substring(0, 3000)}`;
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
