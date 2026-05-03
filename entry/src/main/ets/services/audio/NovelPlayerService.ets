/**
 * Novel Player Service - 书源小说阅读服务
 * Novel Player Service - Online Novel Reading with TTS
 *
 * 使用CoreSpeech Kit和Audio Kit实现书源小说播放
 * 支持TTS朗读、自动翻页、定时播放
 *
 * @since 6.0.0
 */

import { audioKitService, AudioType, PlayMode } from '../huawei-kit/AudioKitService';
import { coreSpeechService } from '../ai/CoreSpeechService';

/**
 * 章节内容
 */
export interface NovelChapter {
  /** 章节ID */
  chapterId: string;
  /** 章节标题 */
  title: string;
  /** 章节内容 */
  content: string;
  /** 字数 */
  wordCount: number;
  /** 是否VIP章节 */
  isVip: boolean;
}

/**
 * 小说阅读配置
 */
export interface NovelConfig {
  /** 是否启用TTS */
  enableTTS: boolean;
  /** 语速 */
  speechRate: number;
  /** 音调 */
  speechPitch: number;
  /** 音量 */
  volume: number;
  /** 音色 */
  voiceType: string;
  /** 自动翻页 */
  autoScroll: boolean;
  /** 翻页速度（秒/页） */
  scrollSpeed: number;
  /** 每页字符数 */
  charsPerPage: number;
  /** 背景颜色 */
  backgroundColor: string;
  /** 文字颜色 */
  textColor: string;
  /** 字体大小 */
  fontSize: number;
}

/**
 * 播放状态
 */
export enum PlayState {
  /** 停止 */
  STOPPED = 'stopped',
  /** 播放中 */
  PLAYING = 'playing',
  /** 暂停 */
  PAUSED = 'paused'
}

/**
 * 小说阅读服务类
 */
class NovelPlayerService {
  /** 单例实例 */
  private static instance: NovelPlayerService;

  /** 当前章节 */
  private currentChapter: NovelChapter | null = null;

  /** 分页内容 */
  private pages: string[] = [];

  /** 当前页码 */
  private currentPageIndex: number = 0;

  /** 播放状态 */
  private playState: PlayState = PlayState.STOPPED;

  /** 小说配置 */
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

  /** TTS监听器 */
  private ttsListeners: Array<(state: string) => void> = [];

  /** 页面变化监听器 */
  private pageChangeListeners: Array<(index: number) => void> = [];

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): NovelPlayerService {
    if (!NovelPlayerService.instance) {
      NovelPlayerService.instance = new NovelPlayerService();
    }
    return NovelPlayerService.instance;
  }

  // ==================== 章节加载 ====================

  /**
   * 加载章节
   */
  async loadChapter(chapter: NovelChapter): Promise<void> {
    try {
      console.info('[NovelPlayer] Loading chapter:', chapter.title);

      this.currentChapter = chapter;

      // 分页
      this.pages = this.paginateContent(chapter.content, this.config.charsPerPage);
      this.currentPageIndex = 0;

      console.info('[NovelPlayer] Chapter loaded:', this.pages.length, 'pages');
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Load chapter failed:', err.message);
    }
  }

  /**
   * 内容分页
   */
  private paginateContent(content: string, charsPerPage: number): string[] {
    const pages: string[] = [];
    const totalChars = content.length;

    for (let i = 0; i < totalChars; i += charsPerPage) {
      // 尝试在段落边界分页
      let endIndex = Math.min(i + charsPerPage, totalChars);

      // 查找最近的段落结束位置
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

  // ==================== TTS播放 ====================

  /**
   * 开始播放
   */
  async startPlaying(): Promise<boolean> {
    try {
      if (!this.config.enableTTS) {
        console.warn('[NovelPlayer] TTS is disabled');
        return false;
      }

      if (this.pages.length === 0) {
        console.warn('[NovelPlayer] No pages to play');
        return false;
      }

      console.info('[NovelPlayer] Starting TTS playback');
      this.playState = PlayState.PLAYING;

      // 使用CoreSpeech Kit进行TTS
      await this.speakCurrentPage();

      // 如果启用自动翻页
      if (this.config.autoScroll) {
        this.startAutoScroll();
      }

      return true;
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Start playing failed:', err.message);
      return false;
    }
  }

  /**
   * 朗读当前页
   */
  private async speakCurrentPage(): Promise<void> {
    if (this.currentPageIndex >= this.pages.length) {
      console.info('[NovelPlayer] Reached end of chapter');
      this.playState = PlayState.STOPPED;
      return;
    }

    const text = this.pages[this.currentPageIndex];

    try {
      // 使用CoreSpeech Kit朗读
      await coreSpeechService.speak(text);

      console.info('[NovelPlayer] Speaking page:', this.currentPageIndex);
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Speak failed:', err.message);
    }
  }

  /**
   * 暂停播放
   */
  async pausePlaying(): Promise<void> {
    try {
      console.info('[NovelPlayer] Pausing playback');
      this.playState = PlayState.PAUSED;

      // 暂停TTS
      await coreSpeechService.pause();

      // 停止自动翻页
      this.stopAutoScroll();
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Pause failed:', err.message);
    }
  }

  /**
   * 恢复播放
   */
  async resumePlaying(): Promise<void> {
    try {
      console.info('[NovelPlayer] Resuming playback');
      this.playState = PlayState.PLAYING;

      // 恢复TTS
      await coreSpeechService.resume();

      // 恢复自动翻页
      if (this.config.autoScroll) {
        this.startAutoScroll();
      }
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Resume failed:', err.message);
    }
  }

  /**
   * 停止播放
   */
  async stopPlaying(): Promise<void> {
    try {
      console.info('[NovelPlayer] Stopping playback');
      this.playState = PlayState.STOPPED;

      // 停止TTS (同步方法，不需要 await)
      coreSpeechService.stop();

      // 停止自动翻页
      this.stopAutoScroll();
    } catch (error) {
      const err = error as Error;
      console.error('[NovelPlayer] Stop failed:', err.message);
    }
  }

  // ==================== 自动翻页 ====================

  /** 自动翻页定时器 */
  private autoScrollTimer: number | null = null;

  /**
   * 启动自动翻页
   */
  private startAutoScroll(): void {
    if (this.autoScrollTimer) {
      this.stopAutoScroll();
    }

    console.info('[NovelPlayer] Starting auto scroll, speed:', this.config.scrollSpeed, 's/page');

    this.autoScrollTimer = setInterval(async () => {
      if (this.playState === PlayState.PLAYING) {
        await this.nextPage();
      }
    }, this.config.scrollSpeed * 1000);
  }

  /**
   * 停止自动翻页
   */
  private stopAutoScroll(): void {
    if (this.autoScrollTimer) {
      clearInterval(this.autoScrollTimer);
      this.autoScrollTimer = null;
      console.info('[NovelPlayer] Auto scroll stopped');
    }
  }

  // ==================== 页面导航 ====================

  /**
   * 下一页
   */
  async nextPage(): Promise<boolean> {
    if (this.currentPageIndex >= this.pages.length - 1) {
      console.info('[NovelPlayer] Reached last page');
      return false;
    }

    this.currentPageIndex++;

    // 朗读新页面
    if (this.playState === PlayState.PLAYING && this.config.enableTTS) {
      await this.speakCurrentPage();
    }

    this.notifyPageChange(this.currentPageIndex);
    return true;
  }

  /**
   * 上一页
   */
  async previousPage(): Promise<boolean> {
    if (this.currentPageIndex <= 0) {
      console.info('[NovelPlayer] Already at first page');
      return false;
    }

    this.currentPageIndex--;

    // 朗读新页面
    if (this.playState === PlayState.PLAYING && this.config.enableTTS) {
      await this.speakCurrentPage();
    }

    this.notifyPageChange(this.currentPageIndex);
    return true;
  }

  /**
   * 跳转到指定页
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

  // ==================== 配置管理 ====================

  /**
   * 更新小说配置
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
        this.startAutoScroll(); // 重启以应用新速度
      }
    }
    if (config.charsPerPage !== undefined) {
      this.config.charsPerPage = config.charsPerPage;
      // 重新分页
      if (this.currentChapter) {
        this.pages = this.paginateContent(this.currentChapter.content, this.config.charsPerPage);
      }
    }
    if (config.backgroundColor !== undefined) this.config.backgroundColor = config.backgroundColor;
    if (config.textColor !== undefined) this.config.textColor = config.textColor;
    if (config.fontSize !== undefined) this.config.fontSize = config.fontSize;

    console.info('[NovelPlayer] Config updated');
  }

  /**
   * 获取小说配置
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

  // ==================== 状态查询 ====================

  /**
   * 获取播放状态
   */
  getPlayState(): PlayState {
    return this.playState;
  }

  /**
   * 获取当前页码
   */
  getCurrentPageIndex(): number {
    return this.currentPageIndex;
  }

  /**
   * 获取总页数
   */
  getTotalPages(): number {
    return this.pages.length;
  }

  /**
   * 获取阅读进度
   */
  getProgress(): number {
    if (this.pages.length === 0) return 0;
    return ((this.currentPageIndex + 1) / this.pages.length) * 100;
  }

  /**
   * 获取当前页面内容
   */
  getCurrentPageContent(): string {
    if (this.currentPageIndex < 0 || this.currentPageIndex >= this.pages.length) {
      return '';
    }
    return this.pages[this.currentPageIndex];
  }

  // ==================== 监听器管理 ====================

  /**
   * 添加TTS监听器
   */
  addTTSListener(listener: (state: string) => void): void {
    const newListeners = this.ttsListeners.slice();
    newListeners.push(listener);
    this.ttsListeners = newListeners;
  }

  /**
   * 添加页面变化监听器
   */
  addPageChangeListener(listener: (index: number) => void): void {
    const newListeners = this.pageChangeListeners.slice();
    newListeners.push(listener);
    this.pageChangeListeners = newListeners;
  }

  /**
   * 通知页面变化
   */
  private notifyPageChange(index: number): void {
    for (const listener of this.pageChangeListeners) {
      listener(index);
    }
  }

  // ==================== 释放资源 ====================

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    console.info('[NovelPlayer] Releasing...');

    await this.stopPlaying();
    this.stopAutoScroll();

    this.currentChapter = null;
    this.pages = [];
    this.currentPageIndex = 0;
    this.ttsListeners = [];
    this.pageChangeListeners = [];

    console.info('[NovelPlayer] Released');
  }
}

// 导出单例
export const novelPlayer = NovelPlayerService.getInstance();
export default novelPlayer;
