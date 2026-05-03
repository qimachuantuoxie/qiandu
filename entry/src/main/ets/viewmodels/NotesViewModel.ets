/**
 * NotesPage ViewModel
 * 管理书籍笔记的加载、添加和删除
 */
import { Note } from '../models/CoreBookModel';
import { bookViewModel } from './BookViewModel';

@ObservedV2
export class NotesViewModel {
  @Trace notes: Note[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace currentBookId: string = '';

  /**
   * 加载指定书籍的所有笔记
   */
  async loadNotes(bookId: string): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    this.currentBookId = bookId;
    try {
      this.notes = bookViewModel.getNotes(bookId);
    } catch (error) {
      this.errorMsg = '加载笔记失败: ' + (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 添加一条新笔记
   */
  async addNote(content: string): Promise<void> {
    if (!content.trim()) {
      this.errorMsg = '笔记内容不能为空';
      return;
    }
    if (!this.currentBookId) {
      this.errorMsg = '未选择书籍,无法添加笔记';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const note = bookViewModel.addNote(this.currentBookId, 0, content);
      const newNotes: Note[] = [];
      for (let i = 0; i < this.notes.length; i++) {
        newNotes.push(this.notes[i]);
      }
      newNotes.push(note);
      this.notes = newNotes;
    } catch (error) {
      this.errorMsg = '添加笔记失败: ' + (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 删除指定笔记
   */
  deleteNote(noteId: string): void {
    if (!this.currentBookId) return;
    bookViewModel.deleteNote(this.currentBookId, noteId);
    const newNotes: Note[] = [];
    for (let i = 0; i < this.notes.length; i++) {
      if (this.notes[i].id !== noteId) {
        newNotes.push(this.notes[i]);
      }
    }
    this.notes = newNotes;
  }
}

export const notesViewModel = new NotesViewModel();
