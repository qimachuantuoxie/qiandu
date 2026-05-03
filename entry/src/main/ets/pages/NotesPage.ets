// 绗旇绠＄悊椤甸潰
// Notes Management Page

import { router } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Note } from '../models/CoreBookModel';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { tr } from '../utils/I18nManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { LazyDataSource } from '../common/datasource/LazyDataSource';

interface NoteWithBook {
  note: Note;
  book: BookInfo | null;
  previewTags: string[];
}

@Entry
@Component
struct NotesPage {
  @State notes: NoteWithBook[] = [];
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State searchText: string = '';
  @State selectedBookId: string = '';
  @State selectedTag: string = '';
  @State showDeleteConfirm: boolean = false;
  @State noteToDelete: NoteWithBook | null = null;
  @State isTablet: boolean = false;
  private unsubscribe: (() => void) | null = null;
  @State private context: common.Context | null = null;

  // LazyForEach 鏁版嵁婧?
  private notesDataSource: LazyDataSource<NoteWithBook> = new LazyDataSource<NoteWithBook>((item: NoteWithBook) => item.note.id);

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.initAsyncData();
    this.setupSubscriptions();
  }

  private initData(): void {
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();

    if (this.context) {
      preferenceManager.init(this.context);
      appTheme.init(this.context);
    }
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();

    this.loadNotes();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookViewModel.subscribe(() => {
      this.loadNotes();
    });
  }

  private updateDataSource(): void {
    const filtered = this.getFilteredNotes();
    this.notesDataSource.setData(filtered);
  }

  private loadNotes(): void {
    const allBooks = bookViewModel.getAllBooks();
    const allNotes: NoteWithBook[] = [];

    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      const notes = bookViewModel.getNotes(book.id);

      for (let j = 0; j < notes.length; j++) {
        const note = notes[j];
        const previewTags: string[] = [];
        if (note.tags) {
          const maxLen = note.tags.length < 3 ? note.tags.length : 3;
          for (let k = 0; k < maxLen; k++) {
            previewTags.push(note.tags[k]);
          }
        }
        allNotes.push({
          note: note,
          book: book,
          previewTags: previewTags
        });
      }
    }

    const sortedNotes = allNotes.slice().sort((a, b) => b.note.createTime - a.note.createTime);

    this.notes = sortedNotes;
    this.updateDataSource();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
  }

  private getFilteredNotes(): NoteWithBook[] {
    let filtered: NoteWithBook[] = [];

    for (let i = 0; i < this.notes.length; i++) {
      filtered.push(this.notes[i]);
    }

    if (this.selectedBookId) {
      const bookFiltered: NoteWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item: NoteWithBook = filtered[i];
        if (item.book && item.book.id === this.selectedBookId) {
          bookFiltered.push(item);
        }
      }
      filtered = bookFiltered;
    }

    if (this.selectedTag) {
      const tagFiltered: NoteWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item: NoteWithBook = filtered[i];
        const noteTags: string[] | undefined = item.note.tags;
        if (noteTags) {
          for (let j = 0; j < noteTags.length; j++) {
            if (noteTags[j] === this.selectedTag) {
              tagFiltered.push(item);
              break;
            }
          }
        }
      }
      filtered = tagFiltered;
    }

    if (this.searchText.trim()) {
      const keyword = this.searchText.toLowerCase();
      const searchFiltered: NoteWithBook[] = [];
      for (let i = 0; i < filtered.length; i++) {
        const item: NoteWithBook = filtered[i];
        const noteContent: string = item.note.content;
        const contentMatch: boolean = noteContent ? noteContent.toLowerCase().includes(keyword) : false;
        const highlight: string | undefined = item.note.highlight;
        const highlightMatch: boolean = highlight ? highlight.toLowerCase().includes(keyword) : false;
        const bookTitle: string = item.book ? item.book.title : '';
        const titleMatch: boolean = bookTitle.toLowerCase().includes(keyword);

        if (contentMatch || highlightMatch || titleMatch) {
          searchFiltered.push(item);
        }
      }
      filtered = searchFiltered;
    }

    return filtered;
  }

  private confirmDelete(note: NoteWithBook): void {
    this.noteToDelete = note;
    this.showDeleteConfirm = true;
  }

  private deleteNote(): void {
    if (this.noteToDelete !== null && this.noteToDelete !== undefined && this.noteToDelete.book !== null && this.noteToDelete.book !== undefined) {
      bookViewModel.deleteNote(this.noteToDelete.book.id, this.noteToDelete.note.id);
      this.loadNotes();
    }
    this.showDeleteConfirm = false;
    this.noteToDelete = null;
  }

  private goToNote(note: NoteWithBook): void {
    if (note.book) {
      const params: Record<string, Object> = {};
      params['bookId'] = note.book.id;
      params['page'] = note.note.pageNumber;
      navigateTo('pages/EnhancedReaderPage', params);
    }
  }

  private exportNote(note: NoteWithBook): void {
    const bookTitle = note.book !== null && note.book !== undefined ? note.book.title : '未知书籍';
    const highlight = note.note.highlight !== null && note.note !== undefined ? note.note.highlight : '';
    const content = '【笔记】' + bookTitle + '\n' +
                   '时间: ' + this.formatTime(note.note.createTime) + '\n' +
                   '页码: 第' + note.note.pageNumber + ' 页\n' +
                   '摘录: ' + highlight + '\n\n' +
                   '笔记: ' + note.note.content;

    console.info('导出笔记:', content);
  }

  private getAllTags(): string[] {
    const tags = new Set<string>();
    for (let i = 0; i < this.notes.length; i++) {
      const noteTags = this.notes[i].note.tags;
      if (noteTags) {
        for (let j = 0; j < noteTags.length; j++) {
          tags.add(noteTags[j]);
        }
      }
    }
    return Array.from(tags);
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';

    return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
  }

  private getHighlightColor(color: string | undefined): string {
    if (color) return color;
    return COMMON_COLORS.WARNING_ORANGE;
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text('<')
          .fontSize(24)
          .fontColor(this.currentColors.textPrimary)
      }
      .width(44)
      .height(44)
      .backgroundColor(this.tc('rgba(255, 255, 255, 0.3)', 'rgba(0, 0, 0, 0.3)'))
      .borderRadius(22)
      .onClick(() => {
        try {
          router.back();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          console.error('[NotesPage] back failed:', msg);
        }
      })

      Text('绗旇')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)

      Text(this.notes.length + '条笔记')
        .fontSize(14)
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 16 })
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.95)', 'rgba(44, 44, 46, 0.95)'))
  }

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: '鎼滅储绗旇...' })
        .width('100%')
        .height(40)
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.bg('rgba(255, 255, 255, 0.1)', 'rgba(255, 255, 255, 0.1)'))
        .borderRadius(20)
        .onChange((value: string) => {
          this.searchText = value;
          this.updateDataSource();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }

  @Builder
  TagFilter() {
    Scroll() {
      Row({ space: 8 }) {
        if (this.selectedTag) {
          Row() {
            Text(this.selectedTag)
              .fontSize(12)
              .fontColor(this.tc('#FFFFFF', '#FFFFFF'))
            Text('脳')
              .fontSize(14)
              .fontColor(this.tc('#FFFFFF', '#FFFFFF'))
              .margin({ left: 4 })
          }
          .height(28)
          .padding({ left: 12, right: 8 })
          .backgroundColor('#1976D2')
          .borderRadius(14)
          .onClick(() => { this.selectedTag = ''; })
        }
      }
      .padding({ left: 20, right: 20, top: 4, bottom: 8 })
    }
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  NoteItem(noteWithBook: NoteWithBook) {
    Column({ space: 0 }) {
      Row() {
        Column({ space: 8 }) {
          if (noteWithBook.book) {
            Image(noteWithBook.book.coverPath || '')
              .width(this.isTablet ? 48 : 40)
              .height(this.isTablet ? 67 : 56)
              .borderRadius(4)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.app_icon'))
          } else {
            Column()
              .width(this.isTablet ? 48 : 40)
              .height(this.isTablet ? 67 : 56)
              .backgroundColor(this.currentColors.surface)
              .borderRadius(4)
          }
        }
        .width(this.isTablet ? 60 : 50)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text(noteWithBook.book !== null && noteWithBook.book !== undefined ? noteWithBook.book.title : '未知书籍')
            .fontSize(this.isTablet ? 16 : 13)
            .fontColor(this.currentColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: 8 }) {
            Text('第' + noteWithBook.note.pageNumber + ' 页')
              .fontSize(this.isTablet ? 12 : 10)
              .fontColor(this.tc(COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.isDarkMode ? 'rgba(0, 125, 255, 0.2)' : 'rgba(0, 125, 255, 0.1)')
              .borderRadius(3)

            Text(this.formatTime(noteWithBook.note.createTime))
              .fontSize(this.isTablet ? 12 : 10)
              .fontColor(this.currentColors.textHint)
          }

          if (noteWithBook.previewTags.length > 0) {
            Row({ space: 4 }) {
              ForEach(noteWithBook.previewTags, (tag: string) => {
                Text('#' + tag)
                  .fontSize(this.isTablet ? 12 : 10)
                  .fontColor('#1976D2')
              }, (tag: string) => tag)
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: this.isTablet ? 12 : 10 })
        
        Column({ space: 8 }) {
          Button() {
            Text('馃摛')
              .fontSize(this.isTablet ? 19 : 16)
          }
          .width(this.isTablet ? 38 : 32)
          .height(this.isTablet ? 38 : 32)
          .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.1)'))
          .borderRadius(16)
          .onClick(() => { this.exportNote(noteWithBook); })

          Button() {
            Text('馃棏')
              .fontSize(this.isTablet ? 19 : 16)
          }
          .width(this.isTablet ? 38 : 32)
          .height(this.isTablet ? 38 : 32)
          .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.1)'))
          .borderRadius(16)
          .onClick(() => { this.confirmDelete(noteWithBook); })
        }
      }
      .width('100%')
      .padding(this.isTablet ? 14 : 12)

      if (noteWithBook.note.highlight) {
        Column() {
          Text(noteWithBook.note.highlight)
            .fontSize(this.isTablet ? 16 : 13)
            .fontColor(this.currentColors.textPrimary)
            .lineHeight(20)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding(12)
            .width('100%')
            .backgroundColor(this.getHighlightColor(noteWithBook.note.color))
            .opacity(0.3)
            .borderRadius(4)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 4 })
      }

      Text(noteWithBook.note.content)
        .fontSize(this.isTablet ? 17 : 14)
        .fontColor(this.currentColors.textPrimary)
        .lineHeight(22)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.currentColors.surface)
    .borderRadius(12)
    .margin({ left: this.isTablet ? 24 : 20, right: this.isTablet ? 24 : 20, bottom: this.isTablet ? 18 : 12 })
    .onClick(() => { this.goToNote(noteWithBook); })
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('馃摑')
        .fontSize(64)
      
      Text('鏆傛棤绗旇')
        .fontSize(16)
        .fontColor(this.currentColors.textSecondary)
      
      Text('闀挎寜閫変腑鏂囧瓧娣诲姞绗旇')
        .fontSize(14)
        .fontColor(this.currentColors.textHint)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DeleteConfirmDialog() {
    Column() {
      Text('纭鍒犻櫎')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .width('100%')
.textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 })

      Text('Delete note?')
        .fontSize(14)
        .fontColor(this.currentColors.textSecondary)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20, bottom: 20 })

      Row() {
        Button('鍙栨秷')
          .width('45%')
          .height(40)
          .backgroundColor(this.bg('rgba(0, 0, 0, 0.1)', 'rgba(255, 255, 255, 0.1)'))
          .fontColor(this.currentColors.textPrimary)
          .borderRadius(20)
          .onClick(() => {
            this.showDeleteConfirm = false;
            this.noteToDelete = null;
          })

        Button('鍒犻櫎')
          .width('45%')
          .height(40)
          .backgroundColor(COMMON_COLORS.ERROR_RED)
          .fontColor(this.tc('#FFFFFF', '#FFFFFF'))
          .borderRadius(20)
          .onClick(() => { this.deleteNote(); })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('80%')
    .backgroundColor(this.currentColors.surface)
    .borderRadius(16)
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SearchBar()
        this.TagFilter()

        if (this.getFilteredNotes().length === 0) {
          this.EmptyView()
        } else {
          Scroll() {
            Column({ space: 0 }) {
              LazyForEach(this.notesDataSource, (item: NoteWithBook) => {
                this.NoteItem(item)
              }, (item: NoteWithBook) => item.note.id)
            }
            .padding({ top: 8, bottom: 20 })
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentColors.background)

      if (this.showDeleteConfirm) {
        Column() {
          Row()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor(this.tc('rgba(0,0,0,0.5)', 'rgba(0,0,0,0.7)'))
            .onClick(() => {
              this.showDeleteConfirm = false;
              this.noteToDelete = null;
            })
          this.DeleteConfirmDialog()
        }
        .width('100%')
        .height('100%')
      }
    }
  }
}

export default NotesPage;
