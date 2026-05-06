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
      const notes = bookViewModel.getNotes(bookId);
      this.notes = notes || [];
    } catch (error) {
      this.errorMsg = '加载笔记失败: ' + (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 娣诲姞涓€鏉℃柊绗旇
   */
  async addNote(content: string): Promise<void> {
    if (!content.trim()) {
      this.errorMsg = '笔记内容不能为空';
      return;
    }
    if (!this.currentBookId) {
      this.errorMsg = '未选择书籍，无法添加笔记';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      bookViewModel.addNote(this.currentBookId, 0, content);
      await this.loadNotes(this.currentBookId);
    } catch (error) {
      this.errorMsg = '添加笔记失败: ' + (error as Error).message;
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
    this.loadNotes(this.currentBookId);
  }
}

export const notesViewModel = new NotesViewModel();
