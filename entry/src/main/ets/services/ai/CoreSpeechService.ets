// CoreSpeechService - 核心语音合成服务
// 使用 HarmonyOS Speech Kit 实现真实 TTS 功能
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
  XIAOYI = 'zh-CN-Xiaoyi',      // 中文女声
  XIAOQI = 'zh-CN-Xiaoqi',      // 中文男声
  NINGNING = 'zh-CN-Ningning',  // 中文女声
  YUANZI = 'zh-CN-Yuanzi',      // 中文男声
  YEYUN = 'zh-CN-Yeyun'         // 中文女声
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

      // 初始化语音合成引擎(using stub)
      const engine: StubSpeechSynthesisEngine = new StubSpeechSynthesisEngine(context);
      this.synthesizer = engine.createSynthesizer();

      // 设置语音合成监听器 - using arrow functions to preserve `this` context (ArkTS strict mode)
      this.onStartCallback = (event: Object): void => {
        console.info('[CoreSpeech] Speech started');
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
        console.info('[CoreSpeech] Speech completed');
        this.isServiceSpeaking = false;
        this.isServicePaused = false;
        if (this.listener && this.listener.onComplete) {
          this.listener.onComplete();
        }
      };

      this.onErrorCallback = (event: Object): void => {
        const errEvent = event as StubSpeechSynthesisErrorEvent;
        console.error('[CoreSpeech] Speech error:', errEvent.errorCode, errEvent.errorMessage);
        this.isServiceSpeaking = false;
        this.isServicePaused = false;
        const errorMsg: string = errEvent.errorMessage || '未知错误';
        if (this.listener && this.listener.onError) {
          this.listener.onError('语音合成失败: ' + errorMsg);
        }
      };

      if (this.synthesizer) {
        this.synthesizer.on('start', this.onStartCallback);
        this.synthesizer.on('progress', this.onProgressCallback);
        this.synthesizer.on('complete', this.onCompleteCallback);
        this.synthesizer.on('error', this.onErrorCallback);
      }

      this.isInitialized = true;
      console.info('[CoreSpeech] Initialized successfully with Speech Kit (stub)');
      return true;
    } catch (error) {
      console.error('[CoreSpeech] Init failed:', error);
      return false;
    }
  }

  setListener(listener: SpeechListener): void {
    this.listener = listener;
  }

  async speak(text: string): Promise<boolean> {
    if (!this.isInitialized || !this.synthesizer) {
      console.warn('[CoreSpeech] Not initialized');
      return false;
    }
    if (!text || text.trim().length === 0) {
      console.warn('[CoreSpeech] Empty text');
      return false;
    }

    try {
      this.currentText = text;
      this.isServiceSpeaking = true;
      this.isServicePaused = false;
      console.info('[CoreSpeech] Speaking:', text.substring(0, 30) + '...');

      // 设置语音参数
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
      console.error('[CoreSpeech] Speak failed:', error);
      this.isServiceSpeaking = false;
      this.isServicePaused = false;
      if (this.listener && this.listener.onError) {
        this.listener.onError('语音播放失败: ' + error);
      }
      return false;
    }
  }

  async speakWithCallback(text: string, onProgress?: (text: string) => void): Promise<boolean> {
    if (onProgress) {
      // 按句子分割，逐句播放
      const sentences: string[] = text.split(new RegExp('([，。！？、；\\n])', ''));
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
        console.error('[CoreSpeech] Stop failed:', error);
      }
    }
    this.isServiceSpeaking = false;
    this.isServicePaused = false;
    console.info('[CoreSpeech] Stopped');
  }

  pause(): void {
    if (this.isServiceSpeaking && !this.isServicePaused && this.synthesizer) {
      try {
        this.synthesizer.pause();
        this.isServicePaused = true;
        if (this.listener && this.listener.onPause) {
          this.listener.onPause();
        }
        console.info('[CoreSpeech] Paused');
      } catch (error) {
        console.error('[CoreSpeech] Pause failed:', error);
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
        console.info('[CoreSpeech] Resumed');
      } catch (error) {
        console.error('[CoreSpeech] Resume failed:', error);
      }
    }
  }

  setSpeed(speed: number): void {
    this.config.speed = Math.max(0.5, Math.min(2.0, speed));
    console.info('[CoreSpeech] Speed set to: ' + this.config.speed);
  }

  setPitch(pitch: number): void {
    this.config.pitch = Math.max(0.5, Math.min(2.0, pitch));
    console.info('[CoreSpeech] Pitch set to: ' + this.config.pitch);
  }

  setVolume(volume: number): void {
    this.config.volume = Math.max(0, Math.min(1, volume));
    console.info('[CoreSpeech] Volume set to: ' + this.config.volume);
  }

  setVoice(voice: SpeechVoice): void {
    this.config.voice = voice;
    console.info('[CoreSpeech] Voice set to: ' + voice);
  }

  setLanguage(language: string): void {
    this.config.language = language;
    console.info('[CoreSpeech] Language set to: ' + language);
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
      console.error('[CoreSpeech] Not initialized');
      return false;
    }

    try {
      console.info('[CoreSpeech] Synthesize to file:', filePath);
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
      console.error('[CoreSpeech] Synthesize to file failed:', error);
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
        console.error('[CoreSpeech] Release failed:', error);
      }
    }
    this.synthesizer = null;
    this.onStartCallback = null;
    this.onProgressCallback = null;
    this.onCompleteCallback = null;
    this.onErrorCallback = null;
    this.isInitialized = false;
    this.context = null;
    console.info('[CoreSpeech] Released');
  }
}

export const coreSpeechService = CoreSpeechService.getInstance();
export default coreSpeechService;
