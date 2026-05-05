import { logger } from '../../../utils/Logger';
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
      logger.info('[NovelPlayer] Loading chapter:', chapter.title);

      this.currentChapter = chapter;

      // 分页
      this.pages = this.paginateContent(chapter.content, this.config.charsPerPage);
      this.currentPageIndex = 0;

      logger.info('[NovelPlayer] Chapter loaded:', this.pages.length, 'pages');
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Load chapter failed:', err.message);
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
        logger.warn('[NovelPlayer] TTS is disabled');
        return false;
      }

      if (this.pages.length === 0) {
        logger.warn('[NovelPlayer] No pages to play');
        return false;
      }

      logger.info('[NovelPlayer] Starting TTS playback');
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
      logger.error('[NovelPlayer] Start playing failed:', err.message);
      return false;
    }
  }

  /**
   * 朗读当前页
   */
  private async speakCurrentPage(): Promise<void> {
    if (this.currentPageIndex >= this.pages.length) {
      logger.info('[NovelPlayer] All pages played');
      this.playState = PlayState.STOPPED;
      return;
    }

    const currentPage = this.pages[this.currentPageIndex];
    
    try {
      // TODO: 调用CoreSpeech Service进行TTS
      logger.info('[NovelPlayer] Speaking page:', this.currentPageIndex + 1);
      
      // 通知TTS状态变化
      this.notifyTTSListeners('speaking');
    } catch (error) {
      const err = error as Error;
      logger.error('[NovelPlayer] Speak failed:', err.message);
    }
  }

  /**
   * 启动自动滚动
   */
  private startAutoScroll(): void {
    // TODO: 实现自动滚动逻辑
    logger.info('[NovelPlayer] Auto scroll started');
  }

  /**
   * 暂停播放
   */
  pausePlaying(): void {
    if (this.playState === PlayState.PLAYING) {
      this.playState = PlayState.PAUSED;
      logger.info('[NovelPlayer] Playback paused');
      
      // TODO: 暂停TTS
      this.notifyTTSListeners('paused');
    }
  }

  /**
   * 恢复播放
   */
  resumePlaying(): void {
    if (this.playState === PlayState.PAUSED) {
      this.playState = PlayState.PLAYING;
      logger.info('[NovelPlayer] Playback resumed');
      
      // TODO: 恢复TTS
      this.notifyTTSListeners('resumed');
    }
  }

  /**
   * 停止播放
   */
  stopPlaying(): void {
    this.playState = PlayState.STOPPED;
    logger.info('[NovelPlayer] Playback stopped');
    
    // TODO: 停止TTS
    this.notifyTTSListeners('stopped');
  }

  // ==================== 翻页控制 ====================

  /**
   * 下一页
   */
  nextPage(): boolean {
    if (this.currentPageIndex < this.pages.length - 1) {
      this.currentPageIndex++;
      this.notifyPageChangeListeners(this.currentPageIndex);
      logger.info('[NovelPlayer] Next page:', this.currentPageIndex + 1);
      
      // 如果正在播放，朗读新页面
      if (this.playState === PlayState.PLAYING) {
        this.speakCurrentPage();
      }
      
      return true;
    }
    return false;
  }

  /**
   * 上一页
   */
  previousPage(): boolean {
    if (this.currentPageIndex > 0) {
      this.currentPageIndex--;
      this.notifyPageChangeListeners(this.currentPageIndex);
      logger.info('[NovelPlayer] Previous page:', this.currentPageIndex + 1);
      
      // 如果正在播放，朗读新页面
      if (this.playState === PlayState.PLAYING) {
        this.speakCurrentPage();
      }
      
      return true;
    }
    return false;
  }

  /**
   * 跳转到指定页
   */
  goToPage(pageIndex: number): boolean {
    if (pageIndex >= 0 && pageIndex < this.pages.length) {
      this.currentPageIndex = pageIndex;
      this.notifyPageChangeListeners(this.currentPageIndex);
      logger.info('[NovelPlayer] Go to page:', pageIndex + 1);
      
      // 如果正在播放，朗读新页面
      if (this.playState === PlayState.PLAYING) {
        this.speakCurrentPage();
      }
      
      return true;
    }
    return false;
  }

  // ==================== 配置管理 ====================

  /**
   * 获取小说配置
   */
  getConfig(): NovelConfig {
    return this.config;
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<NovelConfig>): void {
    this.config = { ...this.config, ...newConfig };
    logger.info('[NovelPlayer] Config updated');
  }

  // ==================== 监听器管理 ====================

  /**
   * 添加TTS监听器
   */
  addTTSListener(listener: (state: string) => void): void {
    this.ttsListeners.push(listener);
  }

  /**
   * 移除TTS监听器
   */
  removeTTSListener(listener: (state: string) => void): void {
    const index = this.ttsListeners.indexOf(listener);
    if (index !== -1) {
      this.ttsListeners.splice(index, 1);
    }
  }

  /**
   * 通知TTS监听器
   */
  private notifyTTSListeners(state: string): void {
    for (const listener of this.ttsListeners) {
      listener(state);
    }
  }

  /**
   * 添加页面变化监听器
   */
  addPageChangeListener(listener: (index: number) => void): void {
    this.pageChangeListeners.push(listener);
  }

  /**
   * 移除页面变化监听器
   */
  removePageChangeListener(listener: (index: number) => void): void {
    const index = this.pageChangeListeners.indexOf(listener);
    if (index !== -1) {
      this.pageChangeListeners.splice(index, 1);
    }
  }

  /**
   * 通知页面变化监听器
   */
  private notifyPageChangeListeners(index: number): void {
    for (const listener of this.pageChangeListeners) {
      listener(index);
    }
  }

  // ==================== 状态查询 ====================

  /**
   * 获取播放状态
   */
  getPlayState(): PlayState {
    return this.playState;
  }

  /**
   * 获取当前章节
   */
  getCurrentChapter(): NovelChapter | null {
    return this.currentChapter;
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
   * 获取当前页内容
   */
  getCurrentPageContent(): string {
    if (this.currentPageIndex >= 0 && this.currentPageIndex < this.pages.length) {
      return this.pages[this.currentPageIndex];
    }
    return '';
  }
}

export const novelPlayerService = NovelPlayerService.getInstance();
export default novelPlayerService;
