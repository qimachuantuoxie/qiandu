import { logger } from '../../../utils/Logger';
// TTSService - 鏂囨湰杞��闊虫湇鍔?
import { coreSpeechService, SpeechVoice, SpeechConfig, SpeechProgress } from './CoreSpeechService';
import { common } from '@kit.AbilityKit';

export enum TTSEngine {
  CORESPEECH = 'core_speech',
  SYSTEM = 'system'
}

export enum TTSSpeed {
  VERY_SLOW = 0.5,
  SLOW = 0.75,
  NORMAL = 1.0,
  FAST = 1.25,
  VERY_FAST = 1.5
}

export enum TTSPitch {
  VERY_LOW = 0.5,
  LOW = 0.75,
  NORMAL = 1.0,
  HIGH = 1.25,
  VERY_HIGH = 1.5
}

export enum TTSVolume {
  MUTE = 0,
  LOW = 0.3,
  MEDIUM = 0.6,
  HIGH = 0.8,
  MAX = 1.0
}

export enum Language {
  ZH_CN = 'zh-CN',
  EN_US = 'en-US',
  JA_JP = 'ja-JP',
  KO_KR = 'ko-KR',
  FR_FR = 'fr-FR',
  DE_DE = 'de-DE',
  ES_ES = 'es-ES',
  IT_IT = 'it-IT',
  PT_BR = 'pt-BR',
  RU_RU = 'ru-RU'
}

export enum AudioFormat {
  PCM_16K = 'pcm_16k',
  PCM_8K = 'pcm_8k',
  MP3 = 'mp3',
  AMR = 'amr',
  AMR_WB = 'amr_wb'
}

export interface TTSProgress {
  beginIndex: number;
  endIndex: number;
  audioFragment: string;
}

export interface TTSListener {
  onStart?: () => void;
  onComplete?: () => void;
  onError?: (error: string) => void;
  onPause?: () => void;
  onResume?: () => void;
  onProgress?: (progress: TTSProgress) => void;
}

export interface TTSProgressInfo {
  isPlaying: boolean;
  isPaused: boolean;
  textLength: number;
}

export interface TTSServiceClass {
  init(context: common.Context): Promise<boolean>;
  isInitialized(): boolean;
  isPlaying(): boolean;
  speak(text: string): Promise<boolean>;
  stop(): void;
  pause(): void;
  resume(): void;
  setSpeed(speed: TTSSpeed): void;
  setPitch(pitch: TTSPitch): void;
  setVolume(volume: TTSVolume): void;
  setLanguage(language: Language): void;
  getAvailableLanguages(): Language[];
  release(): void;
  setListener(listener: TTSListener): void;
  synthesizeToFile(text: string, filePath: string): Promise<string>;
  getConfig(): TTSConfig;
}

export interface TTSConfig {
  engine?: TTSEngine;
  language?: Language;
  speed?: TTSSpeed;
  pitch?: TTSPitch;
  volume?: TTSVolume;
  audioFormat?: AudioFormat;
}

class TTSServiceImpl implements TTSServiceClass {
  private context: common.Context | null = null;
  private config: TTSConfig = {
    engine: TTSEngine.CORESPEECH,
    language: Language.ZH_CN,
    speed: TTSSpeed.NORMAL,
    pitch: TTSPitch.NORMAL,
    volume: TTSVolume.HIGH,
    audioFormat: AudioFormat.MP3
  };
  private isReady: boolean = false;
  private isSpeaking: boolean = false;
  private isPaused: boolean = false;
  private listener: TTSListener | null = null;
  private currentText: string = '';
  private readonly DOMAIN = 'TTSService';

  async init(context: common.Context): Promise<boolean> {
    try {
      this.context = context;
      
      // 鍒濆�鍖朇oreSpeechService
      const success = await coreSpeechService.init(context);
      if (!success) {
        logger.error('[' + this.DOMAIN + '] CoreSpeech init failed');
        return false;
      }
      
      // 璁剧疆鐩戝惉鍣ㄥ洖璋?
      coreSpeechService.setListener({
        onStart: () => {
          this.isSpeaking = true;
          this.isPaused = false;
          if (this.listener !== null && this.listener.onStart !== undefined) {
            this.listener.onStart();
          }
        },
        onComplete: () => {
          this.isSpeaking = false;
          this.isPaused = false;
          if (this.listener !== null && this.listener.onComplete !== undefined) {
            this.listener.onComplete();
          }
        },
        onError: (error: string) => {
          this.isSpeaking = false;
          this.isPaused = false;
          if (this.listener !== null && this.listener.onError !== undefined) {
            this.listener.onError(error);
          }
        },
        onPause: () => {
          this.isPaused = true;
          if (this.listener !== null && this.listener.onPause !== undefined) {
            this.listener.onPause();
          }
        },
        onResume: () => {
          this.isPaused = false;
          if (this.listener !== null && this.listener.onResume !== undefined) {
            this.listener.onResume();
          }
        },
        onProgress: (progress: SpeechProgress) => {
          if (this.listener !== null && this.listener.onProgress !== undefined) {
            this.listener.onProgress({
              beginIndex: progress.beginIndex,
              endIndex: progress.endIndex,
              audioFragment: progress.audioFragment
            });
          }
        }
      });
      
      this.isReady = true;
      logger.info('[' + this.DOMAIN + '] Initialization complete');
      return true;
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[' + this.DOMAIN + '] Initialization failed:', errorErr.message);
      return false;
    }
  }

  isInitialized(): boolean {
    return this.isReady;
  }

  isPlaying(): boolean {
    return this.isSpeaking && !this.isPaused;
  }

  async speak(text: string): Promise<boolean> {
    if (!this.isReady) {
      logger.warn('[' + this.DOMAIN + '] Not initialized');
      return false;
    }
    if (!text || text.trim().length === 0) {
      logger.warn('[' + this.DOMAIN + '] Empty text');
      return false;
    }

    try {
      this.currentText = text;
      logger.info('[' + this.DOMAIN + '] Speaking: ' + text.substring(0, 50) + '...');
      
      // 璋冪敤CoreSpeechService 杩涜�璇�煶鍚堟垚
      const success = await coreSpeechService.speak(text);
      return success;
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[' + this.DOMAIN + '] Speech error:', errorErr.message);
      this.isSpeaking = false;
      if (this.listener !== null && this.listener.onError !== undefined) {
        this.listener.onError(errorErr.message);
      }
      return false;
    }
  }

  stop(): void {
    logger.info('[' + this.DOMAIN + '] Stopping');
    coreSpeechService.stop();
    this.isSpeaking = false;
    this.isPaused = false;
  }

  pause(): void {
    if (this.isSpeaking && !this.isPaused) {
      logger.info('[' + this.DOMAIN + '] Pausing');
      coreSpeechService.pause();
      this.isPaused = true;
    }
  }

  resume(): void {
    if (this.isSpeaking && this.isPaused) {
      logger.info('[' + this.DOMAIN + '] Resuming');
      coreSpeechService.resume();
      this.isPaused = false;
    }
  }

  setSpeed(speed: TTSSpeed): void {
    this.config.speed = speed;
    coreSpeechService.setSpeed(speed);
    logger.info('[' + this.DOMAIN + '] Speed set to: ' + speed);
  }

  setPitch(pitch: TTSPitch): void {
    this.config.pitch = pitch;
    coreSpeechService.setPitch(pitch);
    logger.info('[' + this.DOMAIN + '] Pitch set to: ' + pitch);
  }

  setVolume(volume: TTSVolume): void {
    this.config.volume = volume;
    coreSpeechService.setVolume(volume);
    logger.info('[' + this.DOMAIN + '] Volume set to: ' + volume);
  }

  setLanguage(language: Language): void {
    this.config.language = language;
    coreSpeechService.setLanguage(language);
    logger.info('[' + this.DOMAIN + '] Language set to: ' + language);
  }

  getAvailableLanguages(): Language[] {
    return [
      Language.ZH_CN,
      Language.EN_US,
      Language.JA_JP,
      Language.KO_KR,
      Language.FR_FR,
      Language.DE_DE,
      Language.ES_ES
    ];
  }

  getConfig(): TTSConfig {
    return {
      engine: this.config.engine,
      language: this.config.language,
      speed: this.config.speed,
      pitch: this.config.pitch,
      volume: this.config.volume
    };
  }

  setListener(listener: TTSListener): void {
    this.listener = listener;
  }

  async synthesizeToFile(text: string, filePath: string): Promise<string> {
    if (!this.isReady) {
      logger.error('[' + this.DOMAIN + '] Not initialized');
      return '';
    }

    try {
      logger.info('[' + this.DOMAIN + '] Synthesizing to file: ' + filePath);
      const success = await coreSpeechService.synthesizeToFile(text, filePath);
      if (success) {
        return filePath;
      }
      return '';
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[' + this.DOMAIN + '] Synthesize to file failed:', errorErr.message);
      return '';
    }
  }

  release(): void {
    logger.info('[' + this.DOMAIN + '] Releasing resources');
    this.stop();
    coreSpeechService.release();
    this.isReady = false;
    this.listener = null;
    this.context = null;
  }
}

export const ttsService = new TTSServiceImpl();
