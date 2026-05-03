/**
 * 闊抽鎾斁鏈嶅姟 - 浣跨敤鍗庝负闊抽鎾斁鑳藉姏
 * Audio Player Service - Uses Huawei Audio Playback Capability
 */

import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 鎾斁鐘舵€佹灇涓?
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
 * 鎾斁閰嶇疆
 */
export interface AudioPlayConfig {
  /** 闊抽鏂囦欢璺緞 */
  src: string;
  /** 鏄惁寰幆鎾斁 */
  loop?: boolean;
  /** 鍒濆闊抽噺 (0.0 - 1.0) */
  volume?: number;
  /** 鍒濆鎾斁浣嶇疆 (姣) */
  startPosition?: number;
}

/**
 * 鎾斁杩涘害
 */
export interface AudioPlayProgress {
  /** 褰撳墠鎾斁浣嶇疆 (姣) */
  currentPosition: number;
  /** 鎬绘椂闀?(姣) */
  duration: number;
  /** 鎾斁鐧惧垎姣?*/
  percentage: number;
}

/**
 * 鎾斁鐩戝惉鍣?
 */
export interface AudioPlayerListener {
  /** 鐘舵€佸彉鍖?*/
  onStateChange?: (state: AudioPlayState) => void;
  /** 杩涘害鏇存柊 */
  onProgress?: (progress: AudioPlayProgress) => void;
  /** 鎾斁閿欒 */
  onError?: (error: string) => void;
  /** 鎾斁瀹屾垚 */
  onCompleted?: () => void;
}

/**
 * 闊抽鎾斁鏈嶅姟
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
   * 鍒濆鍖栨湇鍔?
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.createPlayer();
  }

  /**
   * 鍒涘缓鎾斁鍣?
   */
  private async createPlayer(): Promise<void> {
    try {
      this.audioPlayer = await media.createAVPlayer();

      // 娉ㄥ唽鐘舵€佸彉鍖栧洖璋?
      this.audioPlayer.on('stateChange', (state: media.AVPlayerState, reason: media.StateChangeReason): void => {
        console.info('[AudioPlayer] State changed to:', state, 'reason:', reason);
        this.handleStateChange(state);
      });

      // 娉ㄥ唽閿欒鍥炶皟
      this.audioPlayer.on('error', (err: BusinessError): void => {
        console.error('[AudioPlayer] Error:', err.code, err.message);
        this.currentState = AudioPlayState.ERROR;
        if (this.listener && this.listener.onError) {
          this.listener.onError('错误码: ' + err.code + ', 信息: ' + err.message);
        }
      });

      // 娉ㄥ唽鎾斁瀹屾垚鍥炶皟
      this.audioPlayer.on('endOfStream', () => {
        console.info('[AudioPlayer] Playback completed');
        this.currentState = AudioPlayState.COMPLETED;
        if (this.listener && this.listener.onCompleted) {
          this.listener.onCompleted();
        }
        this.stopProgressTimer();
      });

      console.info('[AudioPlayer] Player created');
    } catch (error) {
      const err = error as Error;
      let msg = '[AudioPlayer] Create player failed:';
      if (err) {
        msg = msg + err.message;
      }
      console.error(msg);
    }
  }

  /**
   * 澶勭悊鐘舵€佸彉鍖?
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
   * 璁剧疆鐩戝惉鍣?
   */
  setListener(listener: AudioPlayerListener): void {
    this.listener = listener;
  }

  /**
   * 鎾斁闊抽
   */
  async play(config: AudioPlayConfig): Promise<void> {
    if (!this.audioPlayer) {
      await this.createPlayer();
    }

    try {
      this.stopProgressTimer();

      // 閲嶇疆鎾斁鍣?
      if (this.currentState !== AudioPlayState.IDLE) {
        await this.reset();
      }

      // 设置音源
      const file = await fileIo.open(config.src, 0o0);

      try {
        const fdSrc: media.AVFileDescriptor = {
          fd: file.fd,
          offset: 0,
          length: -1
        };
        this.audioPlayer!.fdSrc = fdSrc;

        // 设置循环播放
        if (config.loop) {
          this.audioPlayer!.loop = true;
        }

        // 准备播放
        await this.audioPlayer!.prepare();

        // 设置音量
        if (config.volume !== undefined) {
          this.audioPlayer!.setVolume(config.volume);
        }

        // 设置起始位置
        if (config.startPosition && config.startPosition > 0) {
          await this.audioPlayer!.seek(config.startPosition);
        }

        // 开始播放
        await this.audioPlayer!.play();

        console.info('[AudioPlayer] Playing:', config.src);
      } finally {
        // 确保文件描述符始终被关闭
        fileIo.close(file);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Play failed:', err.message);
      this.currentState = AudioPlayState.ERROR;
      if (this.listener && this.listener.onError) {
        this.listener.onError(err.message);
      }
    }
  }

  /**
   * 鏆傚仠鎾斁
   */
  async pause(): Promise<void> {
    if (!this.audioPlayer || this.currentState !== AudioPlayState.PLAYING) {
      return;
    }

    try {
      await this.audioPlayer.pause();
      console.info('[AudioPlayer] Paused');
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Pause failed:', err.message);
    }
  }

  /**
   * 鎭㈠鎾斁
   */
  async resume(): Promise<void> {
    if (!this.audioPlayer || this.currentState !== AudioPlayState.PAUSED) {
      return;
    }

    try {
      await this.audioPlayer.play();
      console.info('[AudioPlayer] Resumed');
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Resume failed:', err.message);
    }
  }

  /**
   * 鍋滄鎾斁
   */
  async stop(): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      this.stopProgressTimer();
      await this.audioPlayer.stop();
      console.info('[AudioPlayer] Stopped');
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Stop failed:', err.message);
    }
  }

  /**
   * 閲嶇疆鎾斁鍣?
   */
  private async reset(): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      this.stopProgressTimer();
      await this.audioPlayer.reset();
      console.info('[AudioPlayer] Reset');
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Reset failed:', err.message);
    }
  }

  /**
   * 璺宠浆鍒版寚瀹氫綅缃?
   */
  async seek(position: number): Promise<void> {
    if (!this.audioPlayer) {
      return;
    }

    try {
      await this.audioPlayer.seek(position);
      console.info('[AudioPlayer] Seek to:', position);
    } catch (error) {
      const err = error as Error;
      console.error('[AudioPlayer] Seek failed:', err.message);
    }
  }

  /**
   * 鑾峰彇褰撳墠鐘舵€?
   */
  getState(): AudioPlayState {
    return this.currentState;
  }

  /**
   * 鑾峰彇褰撳墠杩涘害
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
      console.error('[AudioPlayer] Get progress failed:', err.message);
      return null;
    }
  }

  /**
   * 鍚姩杩涘害瀹氭椂鍣?
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
    }, 500); // 姣?500ms 鏇存柊涓€娆?
  }

  /**
   * 鍋滄杩涘害瀹氭椂鍣?
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  /**
   * 閲婃斁璧勬簮
   */
  async release(): Promise<void> {
    this.stopProgressTimer();
    this.listener = null;

    if (this.audioPlayer) {
      try {
        await this.audioPlayer.release();
        this.audioPlayer = null;
        console.info('[AudioPlayer] Released');
      } catch (error) {
        const err = error as Error;
        console.error('[AudioPlayer] Release failed:', err.message);
      }
    }
  }
}

export const audioPlayerService = AudioPlayerService.getInstance();
export default audioPlayerService;
