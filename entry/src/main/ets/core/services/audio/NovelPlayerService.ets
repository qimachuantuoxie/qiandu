import { logger } from '../../../utils/Logger';
/**
 * Novel Player Service - 涔︽簮灏忚�闃呰�鏈嶅姟
 * Novel Player Service - Online Novel Reading with TTS
 *
 * 浣跨敤CoreSpeech Kit鍜孉udio Kit瀹炵幇涔︽簮灏忚�鎾�斁
 * 鏀�寔TTS鏈楄�銆佽嚜鍔ㄧ炕椤点€佸畾鏃舵挱鏀?
 *
 * @since 6.0.0
 */

import { audioKitService, AudioType, PlayMode } from '../huawei-kit/AudioKitService';
import { coreSpeechService } from '../ai/CoreSpeechService';

/**
 * 绔犺妭鍐呭�
 */
export interface NovelChapter {
  /** 绔犺妭ID */
  chapterId: string;
  /** 绔犺妭鏍囬� */
  title: string;
  /** 绔犺妭鍐呭� */
  content: string;
  /** 瀛楁暟 */
  wordCount: number;
  /** 鏄�惁VIP绔犺妭 */
  isVip: boolean;
}

/**
 * 灏忚�闃呰�閰嶇疆
 */
export interface NovelConfig {
  /** 鏄�惁鍚�敤TTS */
  enableTTS: boolean;
  /** 璇�€?*/
  speechRate: number;
  /** 闊宠皟 */
  speechPitch: number;
  /** 闊抽噺 */
  volume: number;
  /** 闊宠壊 */
  voiceType: string;
  /** 鑷�姩缈婚〉 */
  autoScroll: boolean;
  /** 缈婚〉閫熷害锛堢�/椤碉級 */
  scrollSpeed: number;
  /** 姣忛〉瀛楃�鏁?*/
  charsPerPage: number;
  /** 鑳屾櫙棰滆壊 */
  backgroundColor: string;
  /** 鏂囧瓧棰滆壊 */
  textColor: string;
  /** 瀛椾綋澶у皬 */
  fontSize: number;
}

/**
 * 鎾�斁鐘舵€?
 */
export enum PlayState {
  /** 鍋滄� */
  STOPPED = 'stopped',
  /** 鎾�斁涓?*/
  PLAYING = 'playing',
  /** 鏆傚仠 */
  PAUSED = 'paused'
}

/**
 * 灏忚�闃呰�鏈嶅姟绫?
 */
class NovelPlayerService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: NovelPlayerService;

  /** 褰撳墠绔犺妭 */
  private currentChapter: NovelChapter | null = null;

  /** 鍒嗛〉鍐呭� */
  private pages: string[] = [];

  /** 褰撳墠椤电爜 */
  private currentPageIndex: number = 0;

  /** 鎾�斁鐘舵€?*/
  private playState: PlayState = PlayState.STOPPED;

  /** 灏忚�閰嶇疆 */
  private config: NovelConfig = {
    enableTTS: true,
    speechRate: 1.0,
    speechPitch: 1.0,
    volume: 80,
    voiceType: 'xiaoyan',
    autoScroll: false,
    scrollSpeed: 3,
    charsPerPage: 800,
    backgroundColor: '#F5F5DC',
    textColor: '#333333',
    fontSize: 18
  };

  /** TTS鐩戝惉鍣?*/
  private ttsListeners: Array<(state: string) => void> = [];

  /** 椤甸潰鍙樺寲鐩戝惉鍣?*/
  private pageChangeListeners: Array<(index: number) => void> = [];

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): NovelPlayerService {
    if (!NovelPlayerService.instance) {
      NovelPlayerService.instance = new NovelPlayerService();
    }
    return NovelPlayerService.instance;
  }

  // ==================== 绔犺妭鍔犺浇 ====================

  /**
   * 鍔犺浇绔犺妭
   */
  async loadChapter(chapter: NovelChapter): Promise<void> {
    try {
      logger.info('[NovelPlayer] Loading chapter:', chapter.title);

      this.currentChapter = chapter;

      // 鍒嗛〉
      this.pages = this.paginateContent(chapter.content, this.config.charsPerPage);
      this.currentPageIndex = 0;

      logger.info('[NovelPlayer] Chapter loaded:', this.pages.length, 'pages');
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Load chapter failed:', err.message);
    }
  }

  /**
   * 鍐呭�鍒嗛〉
   */
  private paginateContent(content: string, charsPerPage: number): string[] {
    const pages: string[] = [];
    const totalChars = content.length;

    for (let i = 0; i < totalChars; i += charsPerPage) {
      // 灏濊瘯鍦ㄦ�钀借竟鐣屽垎椤?
      let endIndex = Math.min(i + charsPerPage, totalChars);

      // 鏌ユ壘鏈€杩戠殑娈佃惤缁撴潫浣嶇疆
      if (endIndex < totalChars) {
        const paragraphEnd = content.lastIndexOf('\n', endIndex);
        if (paragraphEnd > i) {
          endIndex = paragraphEnd;
        }
      }

      pages.push(content.substring(i, endIndex).trim());
    }

    return pages;
  }

  // ==================== TTS鎾�斁 ====================

  /**
   * 寮€濮嬫挱鏀?
   */
  async startPlaying(): Promise<boolean> {
    try {
      if (!this.config.enableTTS) {
        logger.warn('[NovelPlayer] TTS is disabled');
        return false;
      }

      if (this.pages.length === 0) {
        logger.warn('[NovelPlayer] No pages to play');
        return false;
      }

      logger.info('[NovelPlayer] Starting TTS playback');
      this.playState = PlayState.PLAYING;

      // 浣跨敤CoreSpeech Kit杩涜�TTS
      await this.speakCurrentPage();

      // 濡傛灉鍚�敤鑷�姩缈婚〉
      if (this.config.autoScroll) {
        this.startAutoScroll();
      }

      return true;
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Start playing failed:', err.message);
      return false;
    }
  }

  /**
   * 鏈楄�褰撳墠椤?
   */
  private async speakCurrentPage(): Promise<void> {
    if (this.currentPageIndex >= this.pages.length) {
      logger.info('[NovelPlayer] Reached end of chapter');
      this.playState = PlayState.STOPPED;
      return;
    }

    const text = this.pages[this.currentPageIndex];

    try {
      // 浣跨敤CoreSpeech Kit鏈楄�
      await coreSpeechService.speak(text);

      logger.info('[NovelPlayer] Speaking page:', this.currentPageIndex);
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Speak failed:', err.message);
    }
  }

  /**
   * 鏆傚仠鎾�斁
   */
  async pausePlaying(): Promise<void> {
    try {
      logger.info('[NovelPlayer] Pausing playback');
      this.playState = PlayState.PAUSED;

      // 鏆傚仠TTS
      await coreSpeechService.pause();

      // 鍋滄�鑷�姩缈婚〉
      this.stopAutoScroll();
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Pause failed:', err.message);
    }
  }

  /**
   * 鎭㈠�鎾�斁
   */
  async resumePlaying(): Promise<void> {
    try {
      logger.info('[NovelPlayer] Resuming playback');
      this.playState = PlayState.PLAYING;

      // 鎭㈠�TTS
      await coreSpeechService.resume();

      // 鎭㈠�鑷�姩缈婚〉
      if (this.config.autoScroll) {
        this.startAutoScroll();
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Resume failed:', err.message);
    }
  }

  /**
   * 鍋滄�鎾�斁
   */
  async stopPlaying(): Promise<void> {
    try {
      logger.info('[NovelPlayer] Stopping playback');
      this.playState = PlayState.STOPPED;

      // 鍋滄�TTS (鍚屾�鏂规硶锛屼笉闇€瑕?await)
      coreSpeechService.stop();

      // 鍋滄�鑷�姩缈婚〉
      this.stopAutoScroll();
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Stop failed:', err.message);
    }
  }

  // ==================== 鑷�姩缈婚〉 ====================

  /** 鑷�姩缈婚〉瀹氭椂鍣?*/
  private autoScrollTimer: number | null = null;

  /**
   * 鍚�姩鑷�姩缈婚〉
   */
  private startAutoScroll(): void {
    if (this.autoScrollTimer) {
      this.stopAutoScroll();
    }

    logger.info('[NovelPlayer] Starting auto scroll, speed:', this.config.scrollSpeed, 's/page');

    this.autoScrollTimer = setInterval(async () => {
      if (this.playState === PlayState.PLAYING) {
        await this.nextPage();
      }
    }, this.config.scrollSpeed * 1000);
  }

  /**
   * 鍋滄�鑷�姩缈婚〉
   */
  private stopAutoScroll(): void {
    if (this.autoScrollTimer) {
      clearInterval(this.autoScrollTimer);
      this.autoScrollTimer = null;
      logger.info('[NovelPlayer] Auto scroll stopped');
    }
  }

  // ==================== 椤甸潰瀵艰埅 ====================

  /**
   * 涓嬩竴椤?
   */
  async nextPage(): Promise<boolean> {
    if (this.currentPageIndex >= this.pages.length - 1) {
      logger.info('[NovelPlayer] Reached last page');
      return false;
    }

    this.currentPageIndex++;

    // 鏈楄�鏂伴〉闈?
    if (this.playState === PlayState.PLAYING && this.config.enableTTS) {
      await this.speakCurrentPage();
    }

    this.notifyPageChange(this.currentPageIndex);
    return true;
  }

  /**
   * 涓婁竴椤?
   */
  async previousPage(): Promise<boolean> {
    if (this.currentPageIndex <= 0) {
      logger.info('[NovelPlayer] Already at first page');
      return false;
    }

    this.currentPageIndex--;

    // 鏈楄�鏂伴〉闈?
    if (this.playState === PlayState.PLAYING && this.config.enableTTS) {
      await this.speakCurrentPage();
    }

    this.notifyPageChange(this.currentPageIndex);
    return true;
  }

  /**
   * 璺宠浆鍒版寚瀹氶〉
   */
  async goToPage(index: number): Promise<boolean> {
    if (index < 0 || index >= this.pages.length) {
      return false;
    }

    this.currentPageIndex = index;

    if (this.playState === PlayState.PLAYING && this.config.enableTTS) {
      await this.speakCurrentPage();
    }

    this.notifyPageChange(index);
    return true;
  }

  // ==================== 閰嶇疆绠＄悊 ====================

  /**
   * 鏇存柊灏忚�閰嶇疆
   */
  async updateConfig(config: Partial<NovelConfig>): Promise<void> {
    if (config.enableTTS !== undefined) this.config.enableTTS = config.enableTTS;
    if (config.speechRate !== undefined) this.config.speechRate = config.speechRate;
    if (config.speechPitch !== undefined) this.config.speechPitch = config.speechPitch;
    if (config.volume !== undefined) {
      this.config.volume = config.volume;
      await audioKitService.setVolume(config.volume);
    }
    if (config.voiceType !== undefined) this.config.voiceType = config.voiceType;
    if (config.autoScroll !== undefined) {
      this.config.autoScroll = config.autoScroll;
      if (config.autoScroll && this.playState === PlayState.PLAYING) {
        this.startAutoScroll();
      } else {
        this.stopAutoScroll();
      }
    }
    if (config.scrollSpeed !== undefined) {
      this.config.scrollSpeed = config.scrollSpeed;
      if (this.autoScrollTimer) {
        this.startAutoScroll(); // 閲嶅惎浠ュ簲鐢ㄦ柊閫熷害
      }
    }
    if (config.charsPerPage !== undefined) {
      this.config.charsPerPage = config.charsPerPage;
      // 閲嶆柊鍒嗛〉
      if (this.currentChapter) {
        this.pages = this.paginateContent(this.currentChapter.content, this.config.charsPerPage);
      }
    }
    if (config.backgroundColor !== undefined) this.config.backgroundColor = config.backgroundColor;
    if (config.textColor !== undefined) this.config.textColor = config.textColor;
    if (config.fontSize !== undefined) this.config.fontSize = config.fontSize;

    logger.info('[NovelPlayer] Config updated');
  }

  /**
   * 鑾峰彇灏忚�閰嶇疆
   */
  getConfig(): NovelConfig {
    const cfg: NovelConfig = {
      enableTTS: this.config.enableTTS,
      speechRate: this.config.speechRate,
      speechPitch: this.config.speechPitch,
      volume: this.config.volume,
      voiceType: this.config.voiceType,
      autoScroll: this.config.autoScroll,
      scrollSpeed: this.config.scrollSpeed,
      charsPerPage: this.config.charsPerPage,
      backgroundColor: this.config.backgroundColor,
      textColor: this.config.textColor,
      fontSize: this.config.fontSize
    };
    return cfg;
  }

  // ==================== 鐘舵€佹煡璇?====================

  /**
   * 鑾峰彇鎾�斁鐘舵€?
   */
  getPlayState(): PlayState {
    return this.playState;
  }

  /**
   * 鑾峰彇褰撳墠椤电爜
   */
  getCurrentPageIndex(): number {
    return this.currentPageIndex;
  }

  /**
   * 鑾峰彇鎬婚〉鏁?
   */
  getTotalPages(): number {
    return this.pages.length;
  }

  /**
   * 鑾峰彇闃呰�杩涘害
   */
  getProgress(): number {
    if (this.pages.length === 0) return 0;
    return ((this.currentPageIndex + 1) / this.pages.length) * 100;
  }

  /**
   * 鑾峰彇褰撳墠椤甸潰鍐呭�
   */
  getCurrentPageContent(): string {
    if (this.currentPageIndex < 0 || this.currentPageIndex >= this.pages.length) {
      return '';
    }
    return this.pages[this.currentPageIndex];
  }

  // ==================== 鐩戝惉鍣ㄧ�鐞?====================

  /**
   * 娣诲姞TTS鐩戝惉鍣?
   */
  addTTSListener(listener: (state: string) => void): void {
    const newListeners = this.ttsListeners.slice();
    newListeners.push(listener);
    this.ttsListeners = newListeners;
  }

  /**
   * 娣诲姞椤甸潰鍙樺寲鐩戝惉鍣?
   */
  addPageChangeListener(listener: (index: number) => void): void {
    const newListeners = this.pageChangeListeners.slice();
    newListeners.push(listener);
    this.pageChangeListeners = newListeners;
  }

  /**
   * 閫氱煡椤甸潰鍙樺寲
   */
  private notifyPageChange(index: number): void {
    for (const listener of this.pageChangeListeners) {
      listener(index);
    }
  }

  // ==================== 閲婃斁璧勬簮 ====================

  /**
   * 閲婃斁璧勬簮
   */
  async release(): Promise<void> {
    logger.info('[NovelPlayer] Releasing...');

    await this.stopPlaying();
    this.stopAutoScroll();

    this.currentChapter = null;
    this.pages = [];
    this.currentPageIndex = 0;
    this.ttsListeners = [];
    this.pageChangeListeners = [];

    logger.info('[NovelPlayer] Released');
  }
}

// 瀵煎嚭鍗曚緥
export const novelPlayer = NovelPlayerService.getInstance();
export default novelPlayer;
