import { logger } from '../../../utils/Logger';
// CoreSpeechService - 鏍稿績璇�煶鍚堟垚鏈嶅姟
// 浣跨敤 HarmonyOS Speech Kit 瀹炵幇鐪熷疄 TTS 鍔熻兘
// TODO: SpeechKit not available - using stub implementations
// import { speechSynthesis, SpeechSynthesisEngine, SpeechSynthesizer, SpeechSynthesisParams, SpeechSynthesisListener } from '@kit.SpeechKit';
import { common } from '@kit.AbilityKit';

// ===== Stub types for SpeechKit (TODO: Replace when SpeechKit is available) =====
interface StubSpeechSynthesisEvent {
  offset: number;
  length: number;
}

interface StubSpeechSynthesisProgressEvent {
  offset: number;
  length: number;
}

interface StubSpeechSynthesisErrorEvent {
  errorCode: number;
  errorMessage: string;
}

interface StubSpeechSynthesisParams {
  text: string;
  language: string;
  voiceName: string;
  speakingRate: number;
  pitchRate: number;
  volumeRate: number;
}

class StubSpeechSynthesizer {
  on(event: string, callback: (data: Object) => void): void {}
  off(event: string, callback: (data: Object) => void): void {}
  start(params: StubSpeechSynthesisParams): void {}
  stop(): void {}
  pause(): void {}
  resume(): void {}
  synthesizeToFile(params: StubSpeechSynthesisParams, filePath: string): void {}
  release(): void {}
}

class StubSpeechSynthesisEngine {
  constructor(context: common.Context) {}
  createSynthesizer(): StubSpeechSynthesizer {
    return new StubSpeechSynthesizer();
  }
}
// ===== End Stub types =====

export enum SpeechVoice {
  XIAOYI = 'zh-CN-Xiaoyi',      // 涓�枃濂冲０
  XIAOQI = 'zh-CN-Xiaoqi',      // 涓�枃鐢峰０
  NINGNING = 'zh-CN-Ningning',  // 涓�枃濂冲０
  YUANZI = 'zh-CN-Yuanzi',      // 涓�枃鐢峰０
  YEYUN = 'zh-CN-Yeyun'         // 涓�枃濂冲０
}

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
  private synthesizer: StubSpeechSynthesizer | null = null;
  // Using individual callback references instead of object with methods (ArkTS strict mode)
  private onStartCallback: ((event: Object) => void) | null = null;
  private onProgressCallback: ((event: Object) => void) | null = null;
  private onCompleteCallback: ((event: Object) => void) | null = null;
  private onErrorCallback: ((event: Object) => void) | null = null;

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

      // 鍒濆�鍖栬�闊冲悎鎴愬紩鎿?using stub)
      const engine: StubSpeechSynthesisEngine = new StubSpeechSynthesisEngine(context);
      this.synthesizer = engine.createSynthesizer();

      // 璁剧疆璇�煶鍚堟垚鐩戝惉鍣?- using arrow functions to preserve `this` context (ArkTS strict mode)
      this.onStartCallback = (event: Object): void => {
        logger.info('[CoreSpeech] Speech started');
        this.isServiceSpeaking = true;
        this.isServicePaused = false;
        if (this.listener && this.listener.onStart) {
          this.listener.onStart();
        }
      };

      this.onProgressCallback = (event: Object): void => {
        const progEvent = event as StubSpeechSynthesisProgressEvent;
        const progress: SpeechProgress = {
          beginIndex: progEvent.offset,
          endIndex: progEvent.offset + (progEvent.length || 1),
          audioFragment: ''
        };
        if (this.listener && this.listener.onProgress) {
          this.listener.onProgress(progress);
        }
      };

      this.onCompleteCallback = (event: Object): void => {
        logger.info('[CoreSpeech] Speech completed');
        this.isServiceSpeaking = false;
        this.isServicePaused = false;
        if (this.listener && this.listener.onComplete) {
          this.listener.onComplete();
        }
      };

      this.onErrorCallback = (event: Object): void => {
        const errEvent = event as StubSpeechSynthesisErrorEvent;
        logger.error('[CoreSpeech] Speech error:', errEvent.errorCode, errEvent.errorMessage);
        this.isServiceSpeaking = false;
        this.isServicePaused = false;
        const errorMsg: string = errEvent.errorMessage || '鏈�煡閿欒�';
        if (this.listener && this.listener.onError) {
          this.listener.onError('璇�煶鍚堟垚澶辫触: ' + errorMsg);
        }
      };

      if (this.synthesizer) {
        this.synthesizer.on('start', this.onStartCallback);
        this.synthesizer.on('progress', this.onProgressCallback);
        this.synthesizer.on('complete', this.onCompleteCallback);
        this.synthesizer.on('error', this.onErrorCallback);
      }

      this.isInitialized = true;
      logger.info('[CoreSpeech] Initialized successfully with Speech Kit (stub)');
      return true;
    } catch (error) {
      logger.error('[CoreSpeech] Init failed:', error);
      return false;
    }
  }

  setListener(listener: SpeechListener): void {
    this.listener = listener;
  }

  async speak(text: string): Promise<boolean> {
    if (!this.isInitialized || !this.synthesizer) {
      logger.warn('[CoreSpeech] Not initialized');
      return false;
    }
    if (!text || text.trim().length === 0) {
      logger.warn('[CoreSpeech] Empty text');
      return false;
    }

    try {
      this.currentText = text;
      this.isServiceSpeaking = true;
      this.isServicePaused = false;
      logger.info('[CoreSpeech] Speaking:', text.substring(0, 30) + '...');

      // 璁剧疆璇�煶鍙傛暟
      const params: StubSpeechSynthesisParams = {
        text: text,
        language: this.config.language,
        voiceName: this.config.voice,
        speakingRate: this.config.speed,
        pitchRate: this.config.pitch,
        volumeRate: Math.round(this.config.volume * 100)
      };

      this.synthesizer.start(params);
      return true;
    } catch (error) {
      logger.error('[CoreSpeech] Speak failed:', error);
      this.isServiceSpeaking = false;
      this.isServicePaused = false;
      if (this.listener && this.listener.onError) {
        this.listener.onError('璇�煶鎾�斁澶辫触: ' + error);
      }
      return false;
    }
  }

  async speakWithCallback(text: string, onProgress?: (text: string) => void): Promise<boolean> {
    if (onProgress) {
      // 鎸夊彞瀛愬垎鍓诧紝閫愬彞鎾�斁
      const sentences: string[] = text.split(new RegExp('([锛屻€傦紒锛熴€侊紱\\n])', ''));
      let i: number = 0;
      for (i = 0; i < sentences.length; i++) {
        if (!this.isServiceSpeaking) break;
        while (this.isServicePaused && this.isServiceSpeaking) {
          await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100));
        }
        if (!this.isServiceSpeaking) break;
        const sentence: string = sentences[i];
        if (sentence && sentence.trim().length > 0) {
          await this.speak(sentence);
          onProgress(sentence);
        }
      }
    }
    return this.speak(text);
  }

  stop(): void {
    if (this.synthesizer && this.isServiceSpeaking) {
      try {
        this.synthesizer.stop();
      } catch (error) {
        logger.error('[CoreSpeech] Stop failed:', error);
      }
    }
    this.isServiceSpeaking = false;
    this.isServicePaused = false;
    logger.info('[CoreSpeech] Stopped');
  }

  pause(): void {
    if (this.isServiceSpeaking && !this.isServicePaused && this.synthesizer) {
      try {
        this.synthesizer.pause();
        this.isServicePaused = true;
        if (this.listener && this.listener.onPause) {
          this.listener.onPause();
        }
        logger.info('[CoreSpeech] Paused');
      } catch (error) {
        logger.error('[CoreSpeech] Pause failed:', error);
      }
    }
  }

  resume(): void {
    if (this.isServicePaused && this.synthesizer) {
      try {
        this.synthesizer.resume();
        this.isServicePaused = false;
        if (this.listener && this.listener.onResume) {
          this.listener.onResume();
        }
        logger.info('[CoreSpeech] Resumed');
      } catch (error) {
        logger.error('[CoreSpeech] Resume failed:', error);
      }
    }
  }

  setSpeed(speed: number): void {
    this.config.speed = Math.max(0.5, Math.min(2.0, speed));
    logger.info('[CoreSpeech] Speed set to: ' + this.config.speed);
  }

  setPitch(pitch: number): void {
    this.config.pitch = Math.max(0.5, Math.min(2.0, pitch));
    logger.info('[CoreSpeech] Pitch set to: ' + this.config.pitch);
  }

  setVolume(volume: number): void {
    this.config.volume = Math.max(0, Math.min(1, volume));
    logger.info('[CoreSpeech] Volume set to: ' + this.config.volume);
  }

  setVoice(voice: SpeechVoice): void {
    this.config.voice = voice;
    logger.info('[CoreSpeech] Voice set to: ' + voice);
  }

  setLanguage(language: string): void {
    this.config.language = language;
    logger.info('[CoreSpeech] Language set to: ' + language);
  }

  getConfig(): SpeechConfig {
    return {
      voice: this.config.voice,
      speed: this.config.speed,
      pitch: this.config.pitch,
      volume: this.config.volume,
      language: this.config.language
    };
  }

  isSpeaking(): boolean {
    return this.isServiceSpeaking;
  }

  isPaused(): boolean {
    return this.isServicePaused;
  }

  isInitializedService(): boolean {
    return this.isInitialized;
  }

  getCurrentText(): string {
    return this.currentText;
  }

  async synthesizeToFile(text: string, filePath: string): Promise<boolean> {
    if (!this.isInitialized || !this.synthesizer) {
      logger.error('[CoreSpeech] Not initialized');
      return false;
    }

    try {
      logger.info('[CoreSpeech] Synthesize to file:', filePath);
      const params: StubSpeechSynthesisParams = {
        text: text,
        language: this.config.language,
        voiceName: this.config.voice,
        speakingRate: this.config.speed,
        pitchRate: this.config.pitch,
        volumeRate: Math.round(this.config.volume * 100)
      };

      this.synthesizer.synthesizeToFile(params, filePath);
      return true;
    } catch (error) {
      logger.error('[CoreSpeech] Synthesize to file failed:', error);
      return false;
    }
  }

  async getAvailableVoices(): Promise<SpeechVoice[]> {
    return [
      SpeechVoice.XIAOYI,
      SpeechVoice.XIAOQI,
      SpeechVoice.NINGNING,
      SpeechVoice.YEYUN,
      SpeechVoice.YUANZI
    ];
  }

  release(): void {
    this.stop();
    if (this.synthesizer) {
      try {
        if (this.onStartCallback) {
          this.synthesizer.off('start', this.onStartCallback);
        }
        if (this.onProgressCallback) {
          this.synthesizer.off('progress', this.onProgressCallback);
        }
        if (this.onCompleteCallback) {
          this.synthesizer.off('complete', this.onCompleteCallback);
        }
        if (this.onErrorCallback) {
          this.synthesizer.off('error', this.onErrorCallback);
        }
        this.synthesizer.release();
      } catch (error) {
        logger.error('[CoreSpeech] Release failed:', error);
      }
    }
    this.synthesizer = null;
    this.onStartCallback = null;
    this.onProgressCallback = null;
    this.onCompleteCallback = null;
    this.onErrorCallback = null;
    this.isInitialized = false;
    this.context = null;
    logger.info('[CoreSpeech] Released');
  }
}

export const coreSpeechService = CoreSpeechService.getInstance();
export default coreSpeechService;
