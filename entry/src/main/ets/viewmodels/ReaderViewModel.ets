/**
 * 阅读器 ViewModel
 * 管理阅读器核心状态（书籍、进度、书签、笔记、TTS等）
 */

import { bookViewModel } from './BookViewModel';
import { BookInfo, Bookmark, Note } from '../models/CoreBookModel';

interface ChapterInfo {
  id: string;
  title: string;
  startIndex: number;
  endIndex: number;
}

/**
 * 阅读器 ViewModel
 * 使用 V2 状态管理
 */
@ObservedV2
export class ReaderViewModel {
  // ==================== 书籍状态 ====================
  @Trace currentBook: BookInfo | null = null;
  @Trace currentPage: number = 0;
  @Trace totalPages: number = 0;
  @Trace chapters: ChapterInfo[] = [];
  @Trace currentChapterIndex: number = 0;

  // ==================== 加载状态 ====================
  @Trace isLoading: boolean = false;
  @Trace isLoadingContent: boolean = false;
  @Trace errorMsg: string = '';

  // ==================== 书签和笔记 ====================
  @Trace bookmarks: Bookmark[] = [];
  @Trace notes: Note[] = [];

  // ==================== TTS状态 ====================
  @Trace ttsPlaying: boolean = false;
  @Trace ttsSpeed: number = 1.0;

  // ==================== 阅读进度 ====================
  @Trace readProgress: number = 0;
  @Trace readDuration: number = 0;

  /**
   * 加载书籍
   */
  async loadBook(bookId: string): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    
    try {
      const book = bookViewModel.getBookById(bookId);
      if (!book) {
        throw new Error('书籍不存在');
      }
      
      this.currentBook = book;
      this.currentPage = book.currentPage || 0;
      this.totalPages = book.totalPages || 0;
      this.readProgress = book.readProgress || 0;
      
      // 加载书签和笔记
      this.bookmarks = bookViewModel.getBookmarks(bookId);
      this.notes = bookViewModel.getNotes(bookId);
      
      // 加载章节
      this.chapters = book.chapters || [];
      this.currentChapterIndex = this.getCurrentChapterIndex();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.errorMsg = message;
      console.error('ReaderVM: Load book failed', message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 下一页
   */
  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.updateProgress();
    }
  }

  /**
   * 上一页
   */
  prevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.updateProgress();
    }
  }

  /**
   * 跳转到指定页
   */
  goToPage(page: number): void {
    if (page >= 0 && page < this.totalPages) {
      this.currentPage = page;
      this.updateProgress();
    }
  }

  /**
   * 添加书签
   */
  async addBookmark(): Promise<void> {
    if (!this.currentBook) return;

    try {
      const bookmark: Bookmark = {
        id: 'bookmark_' + Date.now(),
        bookId: this.currentBook.id,
        pageNumber: this.currentPage,
        title: '',
        createTime: Date.now()
      };

      const newBookmarks: Bookmark[] = [];
      for (let i = 0; i < this.bookmarks.length; i++) {
        newBookmarks.push(this.bookmarks[i]);
      }
      newBookmarks.push(bookmark);
      this.bookmarks = newBookmarks;
      bookViewModel.addBookmark(this.currentBook.id, bookmark.pageNumber, bookmark.title);
    } catch (error) {
      const err = error as Error;
      console.error('ReaderVM: Add bookmark failed', err.message);
    }
  }

  /**
   * 删除书签
   */
  async removeBookmark(bookmarkId: string): Promise<void> {
    const newBookmarks: Bookmark[] = [];
    for (let i = 0; i < this.bookmarks.length; i++) {
      if (this.bookmarks[i].id !== bookmarkId) {
        newBookmarks.push(this.bookmarks[i]);
      }
    }
    this.bookmarks = newBookmarks;
    if (this.currentBook) {
      bookViewModel.deleteBookmark(this.currentBook.id, bookmarkId);
    }
  }

  /**
   * 添加笔记
   */
  async addNote(content: string): Promise<void> {
    if (!this.currentBook) return;

    try {
      const note: Note = {
        id: 'note_' + Date.now(),
        bookId: this.currentBook.id,
        pageNumber: this.currentPage,
        content: content,
        createTime: Date.now()
      };

      const newNotes: Note[] = [];
      for (let i = 0; i < this.notes.length; i++) {
        newNotes.push(this.notes[i]);
      }
      newNotes.push(note);
      this.notes = newNotes;
      bookViewModel.addNote(this.currentBook.id, note.pageNumber, note.content);
    } catch (error) {
      const err = error as Error;
    }
  }

  /**
   * 开始TTS
   */
  startTTS(): void {
    this.ttsPlaying = true;
  }

  /**
   * 停止TTS
   */
  stopTTS(): void {
    this.ttsPlaying = false;
  }

  /**
   * 调整TTS速度
   */
  setTTSSpeed(speed: number): void {
    this.ttsSpeed = speed;
  }

  /**
   * 更新阅读进度
   */
  private updateProgress(): void {
    if (this.totalPages > 0) {
      this.readProgress = (this.currentPage + 1) / this.totalPages;
    }
    
    if (this.currentBook) {
      bookViewModel.updateReadingProgress(
        this.currentBook.id,
        this.currentPage,
        this.readDuration
      );
    }
  }

  /**
   * 获取当前章节索引
   */
  private getCurrentChapterIndex(): number {
    if (!this.chapters.length) return 0;
    
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.currentPage >= this.chapters[i].startIndex && 
          this.currentPage <= this.chapters[i].endIndex) {
        return i;
      }
    }
    return 0;
  }

  /**
   * 跳转到章节
   */
  goToChapter(chapterIndex: number): void {
    if (chapterIndex >= 0 && chapterIndex < this.chapters.length) {
      this.currentChapterIndex = chapterIndex;
      this.currentPage = this.chapters[chapterIndex].startIndex;
      this.updateProgress();
    }
  }

  /**
   * 重置状态
   */
  reset(): void {
    this.currentBook = null;
    this.currentPage = 0;
    this.totalPages = 0;
    this.isLoading = false;
    this.errorMsg = '';
    this.bookmarks = [];
    this.notes = [];
    this.ttsPlaying = false;
    this.readProgress = 0;
    this.readDuration = 0;
  }
}

export const readerViewModel = new ReaderViewModel();
export default readerViewModel;
