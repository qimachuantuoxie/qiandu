import { logger } from '../../../common/utils/Logger';
// 笔记管理页面
// Notes Management Page

import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Note } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { tr } from '../core/utils/LocalizationUtil';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { LazyDataSource } from '../common/datasource/LazyDataSource';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;
  private unsubscribe: (() => void) | null = null;
  @State private context: common.Context | null = null;

  // LazyForEach 数据源
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
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

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
    const bookTitle = note.book !== null && note.book !== undefined ? note.book.title : tr('unknown_book');
    const highlight = note.note.highlight !== null && note.note !== undefined ? note.note.highlight : '';
    const content = '【笔记】' + bookTitle + '\n' +
                   '时间: ' + this.formatTime(note.note.createTime) + '\n' +
                   '页码: 第' + note.note.pageNumber + '页\n' +
                   '摘录: ' + highlight + '\n\n' +
                   '笔记: ' + note.note.content;

    logger.info('导出笔记:', content);
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
          .fontSize(Size.iconXL)
          .fontColor(this.currentColors.textPrimary)
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .backgroundColor(this.tc('rgba(255, 255, 255, 0.3)', 'rgba(0, 0, 0, 0.3)'))
      .borderRadius(BorderRadius.full)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[NotesPage] back failed:', msg);
        }
      })

      Text(tr('notes_title'))
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .layoutWeight(1)

      Text(this.notes.length + '条笔记')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .height(Size.buttonLG)
    .padding({ left: Spacing.xs, right: Spacing.lg })
    .backgroundColor(this.bg('rgba(255, 255, 255, 0.95)', 'rgba(44, 44, 46, 0.95)'))
  }

  @Builder
  SearchBar() {
    Column({ space: Spacing.sm }) {
      // 搜索框和筛选按钮
      Row({ space: Spacing.sm }) {
        // 搜索输入框
        TextInput({ placeholder: '搜索笔记...' })
          .layoutWeight(1)
          .height(Size.inputSM)
          .padding({ left: Spacing.lg, right: Spacing.lg })
          .backgroundColor(this.bg('#F5F5F5', '#2C2C2E'))
          .borderRadius(BorderRadius.md)
          .onChange((value: string) => {
            this.searchText = value;
            this.updateDataSource();
          })

        // 筛选按钮
        Button() {
          Row({ space: Spacing.xs }) {
            Text('line_horizontal_3_decrease_circle')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor((this.selectedBookId || this.selectedTag) ? COMMON_COLORS.PRIMARY_BLUE : this.currentColors.textSecondary)
            if (this.selectedBookId || this.selectedTag) {
              Text('●')
                .fontSize(8)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            }
          }
        }
        .width(Size.buttonMD)
        .height(Size.inputSM)
        .backgroundColor((this.selectedBookId || this.selectedTag) ? COMMON_COLORS.PRIMARY_BLUE + '15' : this.bg('#F5F5F5', '#2C2C2E'))
        .borderRadius(BorderRadius.md)
        .onClick(() => {
          this.showFilterDialog();
        })
      }
      .width('100%')

      // 激活的筛选标签
      if (this.selectedBookId || this.selectedTag) {
        Scroll() {
          Row({ space: Spacing.sm }) {
            if (this.selectedBookId) {
              Row({ space: Spacing.xs }) {
                Text('book.circle')
                  .fontSize(14)
                  .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                
                Text(bookViewModel.getBookById(this.selectedBookId)?.title || '')
                  .fontSize(fontScaleManager.getScaledFontSize(12))
                  .fontColor(this.currentColors.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Button() {
                  Text('xmark.circle.fill')
                    .fontSize(16)
                    .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                }
                .width(20)
                .height(20)
                .backgroundColor(Color.Transparent)
                .onClick(() => { 
                  this.selectedBookId = '';
                  this.updateDataSource();
                })
              }
              .height(28)
              .padding({ left: Spacing.sm, right: Spacing.xs })
              .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '10')
              .borderRadius(BorderRadius.full)
            }

            if (this.selectedTag) {
              Row({ space: Spacing.xs }) {
                Text('number.circle')
                  .fontSize(14)
                  .fontColor('#1976D2')
                
                Text('#' + this.selectedTag)
                  .fontSize(fontScaleManager.getScaledFontSize(12))
                  .fontColor('#1976D2')

                Button() {
                  Text('xmark.circle.fill')
                    .fontSize(16)
                    .fontColor('#1976D2')
                }
                .width(20)
                .height(20)
                .backgroundColor(Color.Transparent)
                .onClick(() => { 
                  this.selectedTag = '';
                  this.updateDataSource();
                })
              }
              .height(28)
              .padding({ left: Spacing.sm, right: Spacing.xs })
              .backgroundColor('#1976D2' + '15')
              .borderRadius(BorderRadius.full)
            }
          }
          .padding({ top: Spacing.xs, bottom: Spacing.xs })
        }
        .scrollBar(BarState.Off)
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.sm })
  }

  private showFilterDialog(): void {
    const allBooks = bookViewModel.getAllBooks();
    const allTags = this.getAllTags();
    
    const menuItems: Array<{ text: string, action: () => void }> = [];
    
    // 添加书籍选项
    menuItems.push({ text: tr('all_books'), action: () => { this.selectedBookId = ''; this.updateDataSource(); } });
    for (let i = 0; i < allBooks.length; i++) {
      menuItems.push({ 
        text: allBooks[i].title, 
        action: () => { this.selectedBookId = allBooks[i].id; this.updateDataSource(); } 
      });
    }
    
    // 添加分隔符
    menuItems.push({ text: '---', action: () => {} });
    
    // 添加标签选项
    menuItems.push({ text: tr('all_tags'), action: () => { this.selectedTag = ''; this.updateDataSource(); } });
    for (let i = 0; i < allTags.length; i++) {
      menuItems.push({ 
        text: '#' + allTags[i], 
        action: () => { this.selectedTag = allTags[i]; this.updateDataSource(); } 
      });
    }

    promptAction.showActionMenu({
      title: tr('filter_notes'),
      buttons: menuItems.map(item => ({
        text: item.text,
        action: item.action
      }))
    });
  }

  @Builder
  NoteItem(noteWithBook: NoteWithBook) {
    Column({ space: Spacing.none }) {
      Row() {
        Column({ space: Spacing.sm }) {
          if (noteWithBook.book) {
            Image(noteWithBook.book.coverPath || '')
              .width(this.isTablet ? Size.avatarLG : Size.avatarMD)
              .height(this.isTablet ? Size.cardSM : Size.cardXS)
              .borderRadius(BorderRadius.xs)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.app_icon'))
          } else {
            Column()
              .width(this.isTablet ? Size.avatarLG : Size.avatarMD)
              .height(this.isTablet ? Size.cardSM : Size.cardXS)
              .backgroundColor(this.currentColors.surface)
              .borderRadius(BorderRadius.xs)
          }
        }
        .width(this.isTablet ? Size.avatarLG + 12 : Size.avatarMD + 10)
        .alignItems(HorizontalAlign.Start)

        Column({ space: Spacing.sm }) {
          Text(noteWithBook.book !== null && noteWithBook.book !== undefined ? noteWithBook.book.title : tr('unknown_book'))
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 16 : 13))
            .fontColor(this.currentColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: Spacing.sm }) {
            Text('第' + noteWithBook.note.pageNumber + '页')
              .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 12 : 10))
              .fontColor(this.tc(COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE))
              .padding({ left: Spacing.xs, right: Spacing.xs, top: Spacing.xs / 2, bottom: Spacing.xs / 2 })
              .backgroundColor(this.isDarkMode ? 'rgba(0, 125, 255, 0.2)' : 'rgba(0, 125, 255, 0.1)')
              .borderRadius(BorderRadius.xs / 2)

            Text(this.formatTime(noteWithBook.note.createTime))
              .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 12 : 10))
              .fontColor(this.currentColors.textHint)
          }

          if (noteWithBook.previewTags.length > 0) {
            Row({ space: Spacing.xs }) {
              ForEach(noteWithBook.previewTags, (tag: string) => {
                Text('#' + tag)
                  .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 12 : 10))
                  .fontColor('#1976D2')
              }, (tag: string) => tag)
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: this.isTablet ? Spacing.md : Spacing.sm })
        
        Column({ space: Spacing.sm }) {
          Button() {
            Text('square_and_arrow_up')
              .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 19 : 16))
          }
          .width(this.isTablet ? Size.avatarSM - 2 : Size.avatarSM - 8)
          .height(this.isTablet ? Size.avatarSM - 2 : Size.avatarSM - 8)
          .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.1)'))
          .borderRadius(BorderRadius.full)
          .onClick(() => { this.exportNote(noteWithBook); })

          Button() {
            Text('trash')
              .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 19 : 16))
          }
          .width(this.isTablet ? Size.avatarSM - 2 : Size.avatarSM - 8)
          .height(this.isTablet ? Size.avatarSM - 2 : Size.avatarSM - 8)
          .backgroundColor(this.bg('rgba(255, 255, 255, 0.5)', 'rgba(255, 255, 255, 0.1)'))
          .borderRadius(BorderRadius.full)
          .onClick(() => { this.confirmDelete(noteWithBook); })
        }
      }
      .width('100%')
      .padding(this.isTablet ? Spacing.md + 2 : Spacing.md)

      if (noteWithBook.note.highlight) {
        Column() {
          Text(noteWithBook.note.highlight)
            .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 16 : 13))
            .fontColor(this.currentColors.textPrimary)
            .lineHeight(20)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding(Spacing.md)
            .width('100%')
            .backgroundColor(this.getHighlightColor(noteWithBook.note.color))
            .opacity(0.3)
            .borderRadius(BorderRadius.xs)
        }
        .width('100%')
        .padding({ left: Spacing.md, right: Spacing.md, bottom: Spacing.xs })
      }

      Text(noteWithBook.note.content)
        .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 17 : 14))
        .fontColor(this.currentColors.textPrimary)
        .lineHeight(22)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: Spacing.md, right: Spacing.md, bottom: Spacing.md })
    }
    .width('100%')
    .backgroundColor(this.currentColors.surface)
    .borderRadius(BorderRadius.md)
    .margin({ left: this.isTablet ? Spacing.xxl : Spacing.xl, right: this.isTablet ? Spacing.xxl : Spacing.xl, bottom: this.isTablet ? Spacing.lg + 2 : Spacing.md })
    .onClick(() => { this.goToNote(noteWithBook); })
  }

  @Builder
  EmptyView() {
    Column({ space: Spacing.lg }) {
      Text('note_text')
        .fontSize(Size.iconXXL * 2)
      
      Text(tr('no_notes'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)
      
      Text(tr('long_press_to_add_note'))
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textHint)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DeleteConfirmDialog() {
    Column() {
      Text('确认删除')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentColors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: Spacing.xl, bottom: Spacing.md })

      Text('确定要删除这条笔记吗？')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.currentColors.textSecondary)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.xl, right: Spacing.xl, bottom: Spacing.xl })

      Row() {
        Button('取消')
          .width('45%')
          .height(Size.buttonSM)
          .backgroundColor(this.bg('rgba(0, 0, 0, 0.1)', 'rgba(255, 255, 255, 0.1)'))
          .fontColor(this.currentColors.textPrimary)
          .borderRadius(BorderRadius.full)
          .onClick(() => {
            this.showDeleteConfirm = false;
            this.noteToDelete = null;
          })

        Button('删除')
          .width('45%')
          .height(Size.buttonSM)
          .backgroundColor(COMMON_COLORS.ERROR_RED)
          .fontColor(this.tc('#FFFFFF', '#FFFFFF'))
          .borderRadius(BorderRadius.full)
          .onClick(() => { this.deleteNote(); })
      }
      .width('100%')
      .padding({ left: Spacing.xl, right: Spacing.xl, bottom: Spacing.xl })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('80%')
    .backgroundColor(this.currentColors.surface)
    .borderRadius(BorderRadius.lg)
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SearchBar()

        if (this.getFilteredNotes().length === 0) {
          this.EmptyView()
        } else {
          Scroll() {
            Column({ space: Spacing.none }) {
              LazyForEach(this.notesDataSource, (item: NoteWithBook) => {
                this.NoteItem(item)
              }, (item: NoteWithBook) => item.note.id)
            }
            .padding({ top: Spacing.xs, bottom: Spacing.xl })
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

// 预览组件 - 用于DevEco Studio预览
@Preview
@Component
struct NotesPagePreview {
  build() {
    Column() {
      Text('笔记管理 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      NotesPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('笔记管理 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      NotesPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}

export default NotesPage;
