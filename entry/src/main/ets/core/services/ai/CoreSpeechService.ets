import { logger } from '../../../utils/Logger';
// CoreSpeechService - 核心语音合成服务
// 使用 HarmonyOS Core Speech Kit 实现真实 TTS 功能
// 支持 HarmonyOS 5.0+ (API Level 12+)
import { textToSpeech } from '@kit.CoreSpeechKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export enum SpeechVoice {
  XIAOYI = 'zh-CN-Xiaoyi',      // 中文女声 - 聆小珊
  XIAOQI = 'zh-CN-Xiaoqi',      // 中文男声 - 凌飞哲
  LAURA = 'en-US-Laura'         // 英文女声 - 劳拉
}

// Core Speech Kit person参数映射
const VOICE_PERSON_MAP: Record<SpeechVoice, number> = {
  [SpeechVoice.XIAOYI]: 0,  // 聆小珊女声
  [SpeechVoice.XIAOQI]: 2,  // 凌飞哲男声
  [SpeechVoice.LAURA]: 1    // 劳拉女声(英文)
};

export interface SpeechConfig {
  voice: SpeechVoice;
  speed: number;
  pitch: number;
  volume: number;
  language: string;
}

export interface SpeechProgress {
  beginIndex: number;
  endIndex: number;
  audioFragment: string;
}

export interface SpeechListener {
  onStart?: () => void;
  onComplete?: () => void;
  onError?: (error: string) => void;
  onProgress?: (progress: SpeechProgress) => void;
  onPause?: () => void;
  onResume?: () => void;
}

const DEFAULT_CONFIG: SpeechConfig = {
  voice: SpeechVoice.XIAOYI,
  speed: 1.0,
  pitch: 1.0,
  volume: 0.8,
  language: 'zh-CN'
};

class CoreSpeechService {
  private static instance: CoreSpeechService;
  private context: common.Context | null = null;
  private config: SpeechConfig = DEFAULT_CONFIG;
  private isServiceSpeaking: boolean = false;
  private isServicePaused: boolean = false;
  private isInitialized: boolean = false;
  private listener: SpeechListener | null = null;
  private currentText: string = '';
  
  // Core Speech Kit 引擎实例
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private isCoreSpeechKitAvailable: boolean = false;
  
  // 请求ID计数器
  private requestIdCounter: number = 0;
  
  // 回调引用（用于清理）
  private speakCallback: ((err: BusinessError, eventId: number) => void) | null = null;

  private constructor() {}

  static getInstance(): CoreSpeechService {
    if (!CoreSpeechService.instance) {
      CoreSpeechService.instance = new CoreSpeechService();
    }
    return CoreSpeechService.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }
    try {
      this.context = context;

      // 尝试初始化 Core Speech Kit
      await this.initCoreSpeechKit();
      
      this.isInitialized = true;
      const mode = this.isCoreSpeechKitAvailable ? 'CoreSpeechKit' : 'Fallback Mode';
      logger.info('[CoreSpeech] Initialized successfully in', mode);
      return true;
    } catch (error) {
      logger.error('[CoreSpeech] Init failed:', error);
      return false;
    }
  }
  
  /**
   * 初始化 Core Speech Kit
   */
  private async initCoreSpeechKit(): Promise<void> {
    try {
      // 检测 Core Speech Kit 是否可用
      if (!textToSpeech || !textToSpeech.createEngine) {
        logger.warn('[CoreSpeech] CoreSpeechKit not available, using fallback');
        this.isCoreSpeechKitAvailable = false;
        return;
      }
      
      // 创建TTS引擎
      const person = VOICE_PERSON_MAP[this.config.voice] ?? 0;
      const extraParams: Record<string, string> = {
        'style': 'interaction-broadcast',
        'locate': 'CN'
      };
      
      const initParamsInfo: textToSpeech.CreateEngineParams = {
        language: this.config.language,
        person: person,
        online: 1,  // 在线模式
        extraParams: extraParams
      };
      
      // 异步创建引擎
      this.ttsEngine = await new Promise<textToSpeech.TextToSpeechEngine>((resolve, reject) => {
        textToSpeech.createEngine(initParamsInfo, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
          if (err) {
            logger.error('[CoreSpeech] Create engine failed:', err.message);
            reject(err);
          } else {
            resolve(engine);
          }
        });
      });
      
      this.isCoreSpeechKitAvailable = true;
      logger.info('[CoreSpeech] CoreSpeechKit engine created successfully');
      
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Init CoreSpeechKit failed:', err.message);
      this.isCoreSpeechKitAvailable = false;
      this.ttsEngine = null;
    }
  }

  setListener(listener: SpeechListener): void {
    this.listener = listener;
  }

  async speak(text: string): Promise<boolean> {
    if (!this.isInitialized) {
      logger.warn('[CoreSpeech] Not initialized');
      return false;
    }
    if (!text || text.trim().length === 0) {
      logger.warn('[CoreSpeech] Empty text');
      return false;
    }

    try {
      this.currentText = text;
      
      // 使用 Core Speech Kit
      if (this.isCoreSpeechKitAvailable && this.ttsEngine) {
        return await this.speakWithCoreSpeechKit(text);
      } else {
        logger.warn('[CoreSpeech] CoreSpeechKit not available, TTS disabled');
        return false;
      }
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Speak failed:', err.message);
      return false;
    }
  }
  
  /**
   * 使用 Core Speech Kit 进行语音合成
   */
  private async speakWithCoreSpeechKit(text: string): Promise<boolean> {
    if (!this.ttsEngine) {
      logger.error('[CoreSpeech] TTS engine is null');
      return false;
    }
    
    try {
      // 生成请求ID
      this.requestIdCounter++;
      const requestId = `req_${this.requestIdCounter}_${Date.now()}`;
      
      // 配置播报参数
      const speed = Math.round(this.config.speed * 10);  // CoreSpeechKit速度范围0-10
      const volume = Math.round(this.config.volume * 10); // CoreSpeechKit音量范围0-10
      const pitch = Math.round(this.config.pitch * 10);   // CoreSpeechKit音调范围0-10
      
      const speakParams: textToSpeech.SpeakParams = {
        requestId: requestId,
        extraParams: {
          'queueMode': 0,  // 队列模式：0-立即播放
          'speed': speed,
          'volume': volume,
          'pitch': pitch
        }
      };
      
      // 创建回调函数
      this.speakCallback = (err: BusinessError, eventId: number): void => {
        if (err) {
          logger.error('[CoreSpeech] Speak error:', err.message);
          this.isServiceSpeaking = false;
          if (this.listener && this.listener.onError) {
            this.listener.onError('语音合成失败: ' + err.message);
          }
        } else {
          logger.info('[CoreSpeech] Speak event:', eventId);
          // 根据eventId判断状态
          if (eventId === 1) {  // 开始
            this.isServiceSpeaking = true;
            this.isServicePaused = false;
            if (this.listener && this.listener.onStart) {
              this.listener.onStart();
            }
          } else if (eventId === 2) {  // 完成
            this.isServiceSpeaking = false;
            this.isServicePaused = false;
            if (this.listener && this.listener.onComplete) {
              this.listener.onComplete();
            }
          }
        }
      };
      
      // 执行播报
      this.ttsEngine.speak(text, speakParams, this.speakCallback);
      logger.info('[CoreSpeech] Speaking with CoreSpeechKit:', text.substring(0, 50) + '...');
      return true;
      
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] SpeakWithCoreSpeechKit failed:', err.message);
      return false;
    }
  }

  /**
   * 暂停语音合成
   */
  pause(): void {
    if (!this.isServiceSpeaking) {
      return;
    }

    try {
      // Core Speech Kit 暂不支持pause，需要停止后重新开始
      // TODO: 实现暂停逻辑（保存当前进度）
      logger.warn('[CoreSpeech] Pause not fully supported in CoreSpeechKit');
      this.isServicePaused = true;
      
      if (this.listener && this.listener.onPause) {
        this.listener.onPause();
      }
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Pause failed:', err.message);
    }
  }

  /**
   * 恢复语音合成
   */
  resume(): void {
    if (!this.isServicePaused) {
      return;
    }

    try {
      // Core Speech Kit 暂不支持resume，需要重新调用speak
      // TODO: 实现恢复逻辑（从暂停位置继续）
      logger.warn('[CoreSpeech] Resume not fully supported in CoreSpeechKit');
      this.isServicePaused = false;
      
      if (this.listener && this.listener.onResume) {
        this.listener.onResume();
      }
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Resume failed:', err.message);
    }
  }

  /**
   * 停止语音合成
   */
  stop(): void {
    if (!this.ttsEngine) {
      return;
    }

    try {
      // 停止当前播报
      if (this.requestIdCounter > 0) {
        const requestId = `req_${this.requestIdCounter}_${Date.now()}`;
        this.ttsEngine.stop(requestId);
      }
      
      this.isServiceSpeaking = false;
      this.isServicePaused = false;
      logger.info('[CoreSpeech] Stopped');
      
      if (this.listener && this.listener.onComplete) {
        this.listener.onComplete();
      }
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Stop failed:', err.message);
    }
  }

  /**
   * 更新配置
   */
  updateConfig(config: Partial<SpeechConfig>): void {
    this.config = { ...this.config, ...config };
    
    // 如果引擎已创建，需要重新初始化以应用新的音色设置
    if (config.voice && this.isInitialized) {
      logger.info('[CoreSpeech] Voice changed, need to reinitialize engine');
      // TODO: 重新初始化引擎以应用新音色
    }
    
    logger.info('[CoreSpeech] Config updated:', this.config);
  }

  /**
   * 获取当前配置
   */
  getConfig(): SpeechConfig {
    return this.config;
  }

  /**
   * 检查是否正在说话
   */
  isSpeaking(): boolean {
    return this.isServiceSpeaking;
  }

  /**
   * 检查是否已暂停
   */
  isPaused(): boolean {
    return this.isServicePaused;
  }

  /**
   * 释放资源
   */
  release(): void {
    if (this.ttsEngine) {
      try {
        // 停止所有播报
        if (this.requestIdCounter > 0) {
          const requestId = `req_${this.requestIdCounter}_${Date.now()}`;
          this.ttsEngine.stop(requestId);
        }
        
        // 销毁引擎
        this.ttsEngine.destroy();
        this.ttsEngine = null;
        
        logger.info('[CoreSpeech] Engine destroyed');
      } catch (error) {
        const err = error as BusinessError;
        logger.error('[CoreSpeech] Release failed:', err.message);
      }
    }
    
    this.isInitialized = false;
    this.isCoreSpeechKitAvailable = false;
    this.listener = null;
    this.speakCallback = null;
  }
}

export const coreSpeechService = CoreSpeechService.getInstance();
export default coreSpeechService;
