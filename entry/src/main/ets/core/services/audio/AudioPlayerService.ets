import { logger } from '../../../utils/Logger';
/**
 * 闂婃娊顣堕幘顓熸杹閺堝秴濮?- 娴ｈ法鏁ら崡搴濊礋闂婃娊顣堕幘顓熸杹閼宠棄濮?
 * Audio Player Service - Uses Huawei Audio Playback Capability
 */

import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 閹绢厽鏂侀悩鑸碘偓浣圭亣娑?
 */
export enum AudioPlayState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  ERROR = 'error'
}

/**
 * 閹绢厽鏂侀柊宥囩枂
 */
export interface AudioPlayConfig {
  /** 闂婃娊顣堕弬鍥︽�鐠侯垰绶?*/
  src: string;
  /** 閺勵垰鎯佸�顏嗗箚閹绢厽鏂?*/
  loop?: boolean;
  /** 閸掓繂顫愰棅鎶藉櫤 (0.0 - 1.0) */
  volume?: number;
  /** 閸掓繂顫愰幘顓熸杹娴ｅ秶鐤?(濮ｎ偆顫? */
  startPosition?: number;
}

/**
 * 閹绢厽鏂佹潻娑樺�
 */
export interface AudioPlayProgress {
  /** 瑜版挸澧犻幘顓熸杹娴ｅ秶鐤?(濮ｎ偆顫? */
  currentPosition: number;
  /** 閹�粯妞傞梹?(濮ｎ偆顫? */
  duration: number;
  /** 閹绢厽鏂侀惂鎯у瀻濮?*/
  percentage: number;
}

/**
 * 閹绢厽鏂侀惄鎴濇儔閸?
 */
export interface AudioPlayerListener {
  /** 閻樿埖鈧�礁褰夐崠?*/
  onStateChange?: (state: AudioPlayState) => void;
  /** 鏉╂稑瀹抽弴瀛樻煀 */
  onProgress?: (progress: AudioPlayProgress) => void;
  /** 閹绢厽鏂侀柨娆掝嚖 */
  onError?: (error: string) => void;
  /** 閹绢厽鏂佺€瑰本鍨?*/
  onCompleted?: () => void;
}

/**
 * 闂婃娊顣堕幘顓熸杹閺堝秴濮?
 */
class AudioPlayerService {
  private static instance: AudioPlayerService;
  private context: common.Context | null = null;
  private audioPlayer: media.AVPlayer | null = null;
  private listener: AudioPlayerListener | null = null;
  private currentState: AudioPlayState = AudioPlayState.IDLE;
  private progressTimer: number = -1;

  private constructor() {}

  static getInstance(): AudioPlayerService {
    if (!AudioPlayerService.instance) {
      AudioPlayerService.instance = new AudioPlayerService();
    }
    return AudioPlayerService.instance;
  }

  /**
   * 閸掓繂顫愰崠鏍ㄦ箛閸?
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.createPlayer();
  }

  /**
   * 閸掓稑缂撻幘顓熸杹閸?
   */
  private async createPlayer(): Promise<void> {
    try {
      this.audioPlayer = await media.createAVPlayer();

      // 濞夈劌鍞介悩鑸碘偓浣稿綁閸栨牕娲栫拫?
      this.audioPlayer.on('stateChange', (state: media.AVPlayerState, reason: media.StateChangeReason): void => {
        logger.info('[AudioPlayer] State changed to:', state, 'reason:', reason);
        this.handleStateChange(state);
      });

      // 濞夈劌鍞介柨娆掝嚖閸ョ偠鐨?
      this.audioPlayer.on('error', (err: BusinessError): void => {
        logger.error('[AudioPlayer] Error:', err.code, err.message);
        this.currentState = AudioPlayState.ERROR;
        if (this.listener && this.listener.onError) {
          this.listener.onError('閿欒�鐮? ' + err.code + ', 淇℃伅: ' + err.message);
        }
      });

      // 濞夈劌鍞介幘顓熸杹鐎瑰本鍨氶崶鐐剁殶
      this.audioPlayer.on('endOfStream', () => {
        logger.info('[AudioPlayer] Playback completed');
        this.currentState = AudioPlayState.COMPLETED;
        if (this.listener && this.listener.onCompleted) {
          this.listener.onCompleted();
        }
        this.stopProgressTimer();
      });

      logger.info('[AudioPlayer] Player created');
    } catch (error) {
      const err = error as Error;
      let msg = '[AudioPlayer] Create player failed:';
      if (err) {
        msg = msg + err.message;
      }
      logger.error(msg);
    }
  }

  /**
   * 婢跺嫮鎮婇悩鑸碘偓浣稿綁閸?
   */
  private handleStateChange(state: media.AVPlayerState): void {
    switch (state) {
      case 'idle':
        this.currentState = AudioPlayState.IDLE;
        break;
      case 'initialized':
      case 'prepared':
        this.currentState = AudioPlayState.LOADING;
        break;
      case 'playing':
        this.currentState = AudioPlayState.PLAYING;
        this.startProgressTimer();
        break;
      case 'paused':
        this.currentState = AudioPlayState.PAUSED;
        this.stopProgressTimer();
        break;
      case 'completed':
        this.currentState = AudioPlayState.COMPLETED;
        this.stopProgressTimer();
        break;
    }
    if (this.listener && this.listener.onStateChange) {
      this.listener.onStateChange(this.currentState);
    }
  }

  /**
   * 鐠佸墽鐤嗛惄鎴濇儔閸?
   */
  setListener(listener: AudioPlayerListener): void {
    this.listener = listener;
  }

  /**
   * 閹绢厽鏂侀棅鎶筋暥
   */
  async play(config: AudioPlayConfig): Promise<void> {
    if (!this.audioPlayer) {
      await this.createPlayer();
    }

    try {
      this.stopProgressTimer();

      // 闁插秶鐤嗛幘顓熸杹閸?
      if (this.currentState !== AudioPlayState.IDLE) {
        await this.reset();
      }

      // 璁剧疆闊虫簮
      const file = await fileIo.open(config.src, 0o0);

      try {
        const fdSrc: media.AVFileDescriptor = {
          fd: file.fd,
          offset: 0,
          length: -1
        };
        this.audioPlayer!.fdSrc = fdSrc;

        // 璁剧疆寰�幆鎾�斁
        if (config.loop) {
          this.audioPlayer!.loop = true;
        }

        // 鍑嗗�鎾�斁
        await this.audioPlayer!.prepare();

        // 璁剧疆闊抽噺
        if (config.volume !== undefined) {
          this.audioPlayer!.setVolume(config.volume);
        }

        // 璁剧疆璧峰�浣嶇疆
        if (config.startPosition && config.startPosition > 0) {
          await this.audioPlayer!.seek(config.startPosition);
        }

        // 寮€濮嬫挱鏀?
        await this.audioPlayer!.play();

        logger.info('[AudioPlayer] Playing:', config.src);
      } finally {
        // 纭�繚鏂囦欢鎻忚堪绗﹀�缁堣�鍏抽棴
        fileIo.close(file);
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Play failed:', err.message);
      this.currentState = AudioPlayState.ERROR;
      if (this.listener && this.listener.onError) {
        this.listener.onError(err.message);
      }
    }
  }

  /**
   * 閺嗗倸浠犻幘顓熸杹
   */
  async pause(): Promise<void> {
    if (!this.audioPlayer || this.currentState !== AudioPlayState.PLAYING) {
      return;
    }

    try {
      await this.audioPlayer.pause();
      logger.info('[AudioPlayer] Paused');
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Pause failed:', err.message);
    }
  }

  /**
   * 閹�垹顦查幘顓熸杹
   */
  async resume(): Promise<void> {
    if (!this.audioPlayer || this.currentState !== AudioPlayState.PAUSED) {
      return;
    }

    try {
      await this.audioPlayer.play();
      logger.info('[AudioPlayer] Resumed');
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Resume failed:', err.message);
    }
  }

  /**
   * 閸嬫粍顒涢幘顓熸杹
   */
  async stop(): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      this.stopProgressTimer();
      await this.audioPlayer.stop();
      logger.info('[AudioPlayer] Stopped');
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Stop failed:', err.message);
    }
  }

  /**
   * 闁插秶鐤嗛幘顓熸杹閸?
   */
  private async reset(): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      this.stopProgressTimer();
      await this.audioPlayer.reset();
      logger.info('[AudioPlayer] Reset');
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Reset failed:', err.message);
    }
  }

  /**
   * 鐠哄疇娴嗛崚鐗堝瘹鐎规矮缍呯純?
   */
  async seek(position: number): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      await this.audioPlayer.seek(position);
      logger.info('[AudioPlayer] Seek to:', position);
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Seek failed:', err.message);
    }
  }

  /**
   * 閼惧嘲褰囪ぐ鎾冲�閻樿埖鈧?
   */
  getState(): AudioPlayState {
    return this.currentState;
  }

  /**
   * 閼惧嘲褰囪ぐ鎾冲�鏉╂稑瀹?
   */
  async getProgress(): Promise<AudioPlayProgress | null> {
    if (!this.audioPlayer) {
      return null;
    }

    try {
      const currentPosition = this.audioPlayer.currentTime;
      const duration = this.audioPlayer.duration;

      if (duration <= 0) {
        return null;
      }

      return {
        currentPosition,
        duration,
        percentage: (currentPosition / duration) * 100
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[AudioPlayer] Get progress failed:', err.message);
      return null;
    }
  }

  /**
   * 閸氼垰濮╂潻娑樺�鐎规碍妞傞崳?
   */
  private startProgressTimer(): void {
    if (this.progressTimer !== -1) {
      return;
    }

    this.progressTimer = setInterval(async () => {
      const progress = await this.getProgress();
      if (progress && this.listener && this.listener.onProgress) {
        this.listener.onProgress(progress);
      }
    }, 500); // 濮?500ms 閺囧瓨鏌婃稉鈧�▎?
  }

  /**
   * 閸嬫粍顒涙潻娑樺�鐎规碍妞傞崳?
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  /**
   * 闁插﹥鏂佺挧鍕�爱
   */
  async release(): Promise<void> {
    this.stopProgressTimer();
    this.listener = null;

    if (this.audioPlayer) {
      try {
        await this.audioPlayer.release();
        this.audioPlayer = null;
        logger.info('[AudioPlayer] Released');
      } catch (error) {
        const err = error as Error;
        logger.error('[AudioPlayer] Release failed:', err.message);
      }
    }
  }
}

export const audioPlayerService = AudioPlayerService.getInstance();
export default audioPlayerService;
