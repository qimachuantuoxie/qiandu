import { logger } from '../../../common/utils/Logger';
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { BookInfo, Note } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { tr } from '../../../core/utils/LocalizationUtil';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { LazyDataSource } from '../../common/datasource/LazyDataSource';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

interface NoteWithBook {
  note: Note;
  book: BookInfo | null;
  previewTags: string[];
}

@Entry
@ComponentV2
struct NotesPage {
  @Local notes: NoteWithBook[] = [];
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local searchText: string = '';
  @Local selectedBookId: string = '';
  @Local selectedTag: string = '';
  @Local showDeleteConfirm: boolean = false;
  @Local noteToDelete: NoteWithBook | null = null;
  @Local isTablet: boolean = false;
  @Local screenInfo: ScreenInfo | null = null;
  private unsubscribe: (() => void) | null = null;
  @Local private context: common.Context | null = null;

  private notesDataSource: LazyDataSource<NoteWithBook> = 
    new LazyDataSource<NoteWithBook>((item: NoteWithBook) => item.note.id);

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

    const sortedNotes = allNotes.slice().sort((a, b) => 
      b.note.createTime - a.note.createTime);

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
    if (this.noteToDelete !== null && this.noteToDelete !== undefined && 
        this.noteToDelete.book !== null && this.noteToDelete.book !== undefined) {
      bookViewModel.deleteNote(this.noteToDelete.book.id, this.noteToDelete.note.id);
      this.loadNotes();
    }
    this.showDeleteConfirm = false;
    this.noteToDelete = null;
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前';
    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';

    return date.getFullYear() + '-' + 
      String(date.getMonth() + 1).padStart(2, '0') + '-' + 
      String(date.getDate()).padStart(2, '0');
  }

  build() {
    Column() {
      // 顶部导航栏
      this.Header()

      // 搜索和筛选栏
      this.SearchBar()

      // 笔记列表
      if (this.getFilteredNotes().length === 0) {
        this.EmptyState()
      } else {
        List({ space: Spacing.md }) {
          ForEach(this.getFilteredNotes(), (note: NoteWithBook) => {
            ListItem() {
              this.NoteItem(note)
            }
          }, (note: NoteWithBook) => note.note.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg,
          top: Spacing.sm,
          bottom: Spacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  Header() {
    Row() {
      // 返回按钮
      Row() {
        SymbolGlyph($r('sys.symbol.chevron.left'))
          .fontSize(Size.iconLG)
          .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try {
          goBack();
        } catch (error) {
          const msg = error instanceof Error ? error.message : String(error);
          logger.error('[NotesPage] back failed:', msg);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Column({ space: Spacing.xs }) {
        Text(tr('notes_title'))
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Text(this.notes.length + ' 条笔记')
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: Spacing.md })

      // 标签筛选按钮
      Row() {
        SymbolGlyph($r('sys.symbol.tag.fill'))
          .fontSize(Size.iconMD)
          .fontColor([this.selectedTag ? COMMON_COLORS.PRIMARY_BLUE : this.tc('#8E8E93', '#8E8E93')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.selectedTag ? COMMON_COLORS.PRIMARY_BLUE + '15' : this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showTagFilterDialog();
      })
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  SearchBar() {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        // 搜索图标
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])
          .margin({ left: Spacing.md })

        // 搜索输入框
        TextInput({ placeholder: '搜索笔记...', text: $$this.searchText })
          .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .height(Size.inputSM)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
            this.updateDataSource();
          })

        // 清空按钮
        if (this.searchText) {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
            this.updateDataSource();
          })
        }
      }
      .width('100%')
      .height(Size.inputSM)
      .padding({ left: Spacing.sm, right: Spacing.sm })
      .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
      .borderRadius(BorderRadius.xl)

      // 激活的筛选标签
      if (this.selectedTag) {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.tag.fill'))
            .fontSize(Size.iconSM)
            .fontColor([COMMON_COLORS.PRIMARY_BLUE])
          
          Text(this.selectedTag)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          
          Blank()

          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(Size.iconXS)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { 
            this.selectedTag = '';
            this.updateDataSource();
          })
        }
        .width('100%')
        .padding({ 
          left: Spacing.md, 
          right: Spacing.md, 
          top: Spacing.sm, 
          bottom: Spacing.sm 
        })
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '10')
        .borderRadius(BorderRadius.lg)
      }
    }
    .width('100%')
    .padding({ 
      left: Spacing.lg, 
      right: Spacing.lg, 
      top: Spacing.md, 
      bottom: Spacing.sm 
    })
  }

  private showTagFilterDialog(): void {
    const allTags = new Set<string>();
    for (let i = 0; i < this.notes.length; i++) {
      const note = this.notes[i];
      if (note.note.tags) {
        for (let j = 0; j < note.note.tags.length; j++) {
          allTags.add(note.note.tags[j]);
        }
      }
    }

    const tags = ['全部标签', ...Array.from(allTags)];
    
    promptAction.showActionMenu({
      title: '按标签筛选',
      buttons: tags.map((tag) => ({
        text: tag,
        action: () => {
          this.selectedTag = tag === '全部标签' ? '' : tag;
          this.updateDataSource();
        }
      }))
    });
  }

  @Builder
  NoteItem(noteWithBook: NoteWithBook) {
    Column({ space: Spacing.md }) {
      // 头部：书籍信息和操作
      Row({ space: Spacing.sm }) {
        // 书籍封面
        Stack() {
          if (noteWithBook.book && noteWithBook.book.coverPath) {
            Image(noteWithBook.book.coverPath)
              .width(45)
              .height(60)
              .borderRadius(BorderRadius.sm)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              SymbolGlyph($r('sys.symbol.book.fill'))
                .fontSize(Size.iconLG)
                .fontColor([this.currentColors.primary])
            }
            .width(45)
            .height(60)
            .borderRadius(BorderRadius.sm)
            .backgroundColor(this.currentColors.primary + '15')
            .justifyContent(FlexAlign.Center)
          }
        }

        // 书籍信息
        Column({ space: Spacing.xs }) {
          Text(noteWithBook.book?.title || '未知书籍')
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(Size.iconXS)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text(this.formatTime(noteWithBook.note.createTime))
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 删除按钮
        Row() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(Size.iconSM)
            .fontColor(['#FF4D4F'])
        }
        .width(Size.buttonSM)
        .height(Size.buttonSM)
        .borderRadius(BorderRadius.full)
        .backgroundColor('#FF4D4F15')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.confirmDelete(noteWithBook))
      }
      .width('100%')

      // 高亮文本
      if (noteWithBook.note.highlight) {
        Column({ space: Spacing.xs }) {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.quote.opening'))
              .fontSize(Size.iconSM)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
            
            Text('高亮')
              .fontSize(fontScaleManager.getScaledFontSize(11))
              .fontWeight(FontWeight.Medium)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          }

          Text(noteWithBook.note.highlight)
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
            .lineHeight(20)
            .padding({ left: Spacing.md })
            .borderLeftWidth(3)
            .borderLeftColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(Spacing.md)
        .backgroundColor(this.tc('#F8F9FA', '#2C2C2E'))
        .borderRadius(BorderRadius.md)
      }

      // 笔记内容
      Text(noteWithBook.note.content)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
        .lineHeight(22)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 标签
      if (noteWithBook.previewTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(noteWithBook.previewTags, (tag: string) => {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.tag'))
                .fontSize(Size.iconXS)
                .fontColor([this.currentColors.primary])
              
              Text(tag)
                .fontSize(fontScaleManager.getScaledFontSize(11))
                .fontColor(this.currentColors.primary)
            }
            .padding({ 
              left: Spacing.sm, 
              right: Spacing.sm, 
              top: Spacing.xs, 
              bottom: Spacing.xs 
            })
            .backgroundColor(this.currentColors.primary + '10')
            .borderRadius(BorderRadius.xl)
            .margin({ right: Spacing.xs, bottom: Spacing.xs })
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .stateStyles({
      pressed: { 
        .scale({ x: 0.98, y: 0.98 }),
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .scale({ x: 1, y: 1 }),
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      }
    })
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.note.text'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无笔记')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('阅读时添加笔记，记录精彩瞬间')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

// 预览组件
@Preview
@ComponentV2
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
