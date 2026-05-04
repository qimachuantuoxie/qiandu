/**
 * NotesPage ViewModel
 * 绠＄悊涔︾睄绗旇鐨勫姞杞姐€佹坊鍔犲拰鍒犻櫎
 */
import { Note } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';

@ObservedV2
export class NotesViewModel {
  @Trace notes: Note[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace currentBookId: string = '';

  /**
   * 鍔犺浇鎸囧畾涔︾睄鐨勬墍鏈夌瑪璁?
   */
  async loadNotes(bookId: string): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    this.currentBookId = bookId;
    try {
      this.notes = bookViewModel.getNotes(bookId);
    } catch (error) {
      this.errorMsg = '鍔犺浇绗旇澶辫触: ' + (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 娣诲姞涓€鏉℃柊绗旇
   */
  async addNote(content: string): Promise<void> {
    if (!content.trim()) {
      this.errorMsg = '绗旇鍐呭涓嶈兘涓虹┖';
      return;
    }
    if (!this.currentBookId) {
      this.errorMsg = '鏈€夋嫨涔︾睄,鏃犳硶娣诲姞绗旇';
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
      this.errorMsg = '娣诲姞绗旇澶辫触: ' + (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 鍒犻櫎鎸囧畾绗旇
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
