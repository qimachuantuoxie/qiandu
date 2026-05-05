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
      PageHeader({
        title: tr('notes_title'),
        subtitle: this.notes.length + ' 条笔记',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[NotesPage] back failed:', msg);
          }
        },
        rightContent: () => {
          Row() {
            SymbolGlyph($r('sys.symbol.tag.fill'))
              .fontSize(20)
              .fontColor([this.selectedTag ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)])
          }
          .width(40)
          .height(40)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(this.selectedTag ? HDSColours.primary.blue + '15' : (this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)'))
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showTagFilterDialog();
          })
        }
      })

      // 搜索和筛选栏
      this.SearchBar()

      // 笔记列表
      if (this.getFilteredNotes().length === 0) {
        this.EmptyState()
      } else {
        List({ space: HDSSpacing.md }) {
          ForEach(this.getFilteredNotes(), (note: NoteWithBook) => {
            ListItem() {
              this.NoteItem(note)
            }
          }, (note: NoteWithBook) => note.note.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg,
          top: HDSSpacing.sm,
          bottom: HDSSpacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  SearchBar() {
    Column({ space: HDSSpacing.sm }) {
      Row({ space: HDSSpacing.sm }) {
        // 搜索图标
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(16)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          .margin({ left: HDSSpacing.md })

        // 搜索输入框
        TextInput({ placeholder: '搜索笔记...', text: $$this.searchText })
          .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray400)
          .fontSize(HDSTypography.sizes.md)
          .height(40)
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
              .fontSize(16)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
            this.updateDataSource();
          })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm })
      .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F2F2F7')
      .borderRadius(HDSBorderRadius.xl)

      // 激活的筛选标签
      if (this.selectedTag) {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.tag.fill'))
            .fontSize(16)
            .fontColor([HDSColours.primary.blue])
          
          Text(this.selectedTag)
            .fontSize(HDSTypography.sizes.sm)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          
          Blank()

          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(12)
              .fontColor([HDSColours.primary.blue])
          }
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .onClick(() => { 
            this.selectedTag = '';
            this.updateDataSource();
          })
        }
        .width('100%')
        .padding({ 
          left: HDSSpacing.md, 
          right: HDSSpacing.md, 
          top: HDSSpacing.sm, 
          bottom: HDSSpacing.sm 
        })
        .backgroundColor(HDSColours.primary.blue + '10')
        .borderRadius(HDSBorderRadius.lg)
      }
    }
    .width('100%')
    .padding({ 
      left: HDSSpacing.lg, 
      right: HDSSpacing.lg, 
      top: HDSSpacing.md, 
      bottom: HDSSpacing.sm 
    })
  }
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
        Column({ space: HDSSpacing.xs }) {
          Text(noteWithBook.book?.title || '未知书籍')
            .fontSize(HDSTypography.sizes.sm)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(12)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            
            Text(this.formatTime(noteWithBook.note.createTime))
              .fontSize(HDSTypography.sizes.xs)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 删除按钮
        Row() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(16)
            .fontColor(['#FF4D4F'])
        }
        .width(32)
        .height(32)
        .borderRadius(HDSBorderRadius.full)
        .backgroundColor('#FF4D4F15')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.confirmDelete(noteWithBook))
      }
      .width('100%')

      // 高亮文本
      if (noteWithBook.note.highlight) {
        Column({ space: HDSSpacing.xs }) {
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.quote.opening'))
              .fontSize(16)
              .fontColor([HDSColours.primary.blue])
            
            Text('高亮')
              .fontSize(HDSTypography.sizes.xs)
              .fontWeight(FontWeight.Medium)
              .fontColor(HDSColours.primary.blue)
          }

          Text(noteWithBook.note.highlight)
            .fontSize(HDSTypography.sizes.sm)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            .lineHeight(20)
            .padding({ left: HDSSpacing.md })
            .borderLeftWidth(3)
            .borderLeftColor(HDSColours.primary.blue)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(HDSPacing.md)
        .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : '#F8F9FA')
        .borderRadius(HDSBorderRadius.md)
      }

      // 笔记内容
      Text(noteWithBook.note.content)
        .fontSize(HDSTypography.sizes.md)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : '#3A3A3C')
        .lineHeight(22)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 标签
      if (noteWithBook.previewTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(noteWithBook.previewTags, (tag: string) => {
            Row({ space: HDSSpacing.xs }) {
              SymbolGlyph($r('sys.symbol.tag'))
                .fontSize(12)
                .fontColor([HDSColours.primary.blue])
              
              Text(tag)
                .fontSize(HDSTypography.sizes.xs)
                .fontColor(HDSColours.primary.blue)
            }
            .padding({ 
              left: HDSSpacing.sm, 
              right: HDSSpacing.sm, 
              top: HDSSpacing.xs, 
              bottom: HDSSpacing.xs 
            })
            .backgroundColor(HDSColours.primary.blue + '10')
            .borderRadius(HDSBorderRadius.xl)
            .margin({ right: HDSSpacing.xs, bottom: HDSSpacing.xs })
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(HDSPacing.lg)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
  }

  @Builder
  EmptyState() {
    Column({ space: HDSSpacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.note.text'))
          .fontSize(48)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray300])
      }
      .width(100)
      .height(100)
      .borderRadius(HDSBorderRadius.full)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
      .justifyContent(FlexAlign.Center)

      Text('暂无笔记')
        .fontSize(HDSTypography.sizes.xl)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Text('阅读时添加笔记，记录精彩瞬间')
        .fontSize(HDSTypography.sizes.sm)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
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
