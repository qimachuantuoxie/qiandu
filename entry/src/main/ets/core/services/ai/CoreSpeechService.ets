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

// Core Speech Kit 配置常量
const VOICE_PERSON_MAP: Record<SpeechVoice, number> = {
  [SpeechVoice.XIAOYI]: 0,  // 聆小珊女声
  [SpeechVoice.XIAOQI]: 2,  // 凌飞哲男声
  [SpeechVoice.LAURA]: 1    // 劳拉女声(英文)
};

// CoreSpeechKit 参数范围常量
const PARAM_MULTIPLIER = 10;  // 将0-1.5范围转换为0-10范围
const QUEUE_MODE_IMMEDIATE = 0;  // 立即播放模式
const ONLINE_MODE = 1;  // 在线模式

// 默认配置
const DEFAULT_CONFIG: SpeechConfig = {
  voice: SpeechVoice.XIAOYI,
  speed: 1.0,
  pitch: 1.0,
  volume: 0.8,
  language: 'zh-CN'
};

// 引擎初始化参数
const ENGINE_STYLE = 'interaction-broadcast';
const ENGINE_LOCATE = 'CN';

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
  
  // 请求ID计数器
  private requestIdCounter: number = 0;
  private currentRequestId: string = '';
  
  // 暂停/恢复支持
  private pausedText: string = '';  // 保存暂停时的文本
  
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
      await this.initCoreSpeechKit();
      this.isInitialized = true;
      logger.info('[CoreSpeech] Initialized successfully with CoreSpeechKit');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[CoreSpeech] Init failed:', err.message);
      return false;
    }
  }
  
  /**
   * 初始化 Core Speech Kit
   */
  private async initCoreSpeechKit(): Promise<void> {
    const person = VOICE_PERSON_MAP[this.config.voice] ?? 0;
    const extraParams: Record<string, string> = {
      'style': ENGINE_STYLE,
      'locate': ENGINE_LOCATE
    };
    
    const initParamsInfo: textToSpeech.CreateEngineParams = {
      language: this.config.language,
      person: person,
      online: ONLINE_MODE,
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
    
    logger.info('[CoreSpeech] CoreSpeechKit engine created successfully');
  }

  setListener(listener: SpeechListener): void {
    this.listener = listener;
  }

  async speak(text: string): Promise<boolean> {
    if (!this.isInitialized || !this.ttsEngine) {
      logger.error('[CoreSpeech] Not initialized or engine is null');
      return false;
    }
    if (!text || text.trim().length === 0) {
      logger.warn('[CoreSpeech] Empty text');
      return false;
    }

    try {
      this.currentText = text;
      return await this.speakWithCoreSpeechKit(text);
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
      this.currentRequestId = `req_${this.requestIdCounter}_${Date.now()}`;
      
      // 配置播报参数（转换为CoreSpeechKit的范围0-10）
      const speakParams: textToSpeech.SpeakParams = {
        requestId: this.currentRequestId,
        extraParams: {
          'queueMode': QUEUE_MODE_IMMEDIATE,
          'speed': Math.round(this.config.speed * PARAM_MULTIPLIER),
          'volume': Math.round(this.config.volume * PARAM_MULTIPLIER),
          'pitch': Math.round(this.config.pitch * PARAM_MULTIPLIER)
        }
      };
      
      // 创建回调函数
      this.speakCallback = (err: BusinessError, eventId: number): void => {
        if (err) {
          logger.error('[CoreSpeech] Speak error:', err.message);
          this.isServiceSpeaking = false;
          this.isServicePaused = false;
          this.currentRequestId = '';
          if (this.listener && this.listener.onError) {
            this.listener.onError('语音合成失败: ' + err.message);
          }
        } else {
          logger.info('[CoreSpeech] Speak event:', eventId);
          // 根据eventId判断状态
          // eventId: 1-开始, 2-结束, 3-进度, 4-错误
          if (eventId === 1) {  // 开始
            this.isServiceSpeaking = true;
            this.isServicePaused = false;
            if (this.listener && this.listener.onStart) {
              this.listener.onStart();
            }
          } else if (eventId === 2) {  // 完成
            this.isServiceSpeaking = false;
            this.isServicePaused = false;
            this.currentRequestId = '';
            if (this.listener && this.listener.onComplete) {
              this.listener.onComplete();
            }
          } else if (eventId === 3) {  // 进度
            // 可以根据需要处理进度信息
            if (this.listener && this.listener.onProgress) {
              const progress: SpeechProgress = {
                beginIndex: 0,
                endIndex: this.currentText.length,
                audioFragment: ''
              };
              this.listener.onProgress(progress);
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
   * 注意：CoreSpeechKit不直接支持pause，通过停止并保存状态实现
   */
  pause(): void {
    if (!this.isServiceSpeaking || this.isServicePaused || !this.ttsEngine) {
      return;
    }

    try {
      // 保存当前状态
      this.pausedText = this.currentText;
      
      // 停止当前播报
      if (this.currentRequestId) {
        this.ttsEngine.stop(this.currentRequestId);
      }
      
      this.isServicePaused = true;
      this.isServiceSpeaking = false;
      
      logger.info('[CoreSpeech] Paused (state saved)');
      
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
   * 注意：CoreSpeechKit不直接支持resume，通过重新开始实现
   */
  resume(): void {
    if (!this.isServicePaused) {
      return;
    }

    try {
      // 恢复状态
      this.isServicePaused = false;
      
      // 如果有保存的文本，重新开始播报
      if (this.pausedText && this.pausedText.length > 0) {
        logger.info('[CoreSpeech] Resuming from saved state');
        // 异步重新开始播报
        setTimeout(() => {
          this.speak(this.pausedText);
          this.pausedText = '';
          this.pausedPosition = 0;
        }, 100);
      }
      
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
      if (this.currentRequestId) {
        this.ttsEngine.stop(this.currentRequestId);
        this.currentRequestId = '';
      }
      
      // 清空暂停状态
      this.pausedText = '';
      this.pausedPosition = 0;
      
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
  async updateConfig(config: Partial<SpeechConfig>): Promise<void> {
    const needReinit = config.voice && config.voice !== this.config.voice;
    
    this.config = { ...this.config, ...config };
    
    // 如果音色改变且引擎已创建，需要重新初始化
    if (needReinit && this.isInitialized && this.context) {
      logger.info('[CoreSpeech] Voice changed, reinitializing engine');
      
      // 先释放旧引擎
      if (this.ttsEngine) {
        try {
          this.ttsEngine.destroy();
        } catch (error) {
          logger.warn('[CoreSpeech] Destroy old engine failed:', error);
        }
      }
      
      // 重新初始化
      await this.initCoreSpeechKit();
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
        if (this.currentRequestId) {
          this.ttsEngine.stop(this.currentRequestId);
          this.currentRequestId = '';
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
    
    // 清空状态
    this.pausedText = '';
    this.isInitialized = false;
    this.listener = null;
    this.speakCallback = null;
  }
}

export const coreSpeechService = CoreSpeechService.getInstance();
export default coreSpeechService;
