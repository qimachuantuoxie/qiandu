// 首页组件 - 展示阅读进度、快捷入口、最近添加
import { router } from '@kit.ArkUI';
import { navigateTo } from '../../../utils/NavigationHelper';
import { BookInfo, ReadStatus } from '../../../models/CoreBookModel';
import { bookViewModel } from '../../../viewmodels/BookViewModel';
import { themeManager, COMMON_COLORS, AppColors } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';
import { ShortcutItem, ShortcutEditor } from '../../../features/settings/components/ShortcutEditor';
import { preferenceManager } from '../../../utils/PreferenceManager';
import { CommonCard, CardType, EmptyState, EmptyStateType, CommonProgress } from '../../../components/common/CommonButton';
import { onlineBookService } from '../../../services/book/OnlineBookService';
import { OnlineSearchResult } from '../../../models/OnlineBookModel';

interface ReadingStats {
  totalBooks: number;
  readingBooks: number;
  todayMinutes: number;
  streakDays: number;
}

@Component
export struct HomeContent {
  @Prop recentBooks: BookInfo[] = [];
  @Prop isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State stats: ReadingStats = {
    totalBooks: 0,
    readingBooks: 0,
    todayMinutes: 0,
    streakDays: 0
  };
  @State showShortcutEditor: boolean = false;
  @State shortcuts: ShortcutItem[] = [];
  // AI找书
  @State showAISearch: boolean = false;
  @State aiSearchKeyword: string = '';
  @State aiSearchResults: OnlineSearchResult[] = [];
  @State isAISearching: boolean = false;
  onBookClick?: (book: BookInfo) => void;
  onOpenFilePicker?: () => void;
  onOpenSmartServices?: () => void;

  aboutToAppear() {
    this.loadStats();
    this.loadShortcuts();
    this.currentColors = themeManager.getColors();
    this.initAsyncData();
  }

  private async initAsyncData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  /**
   * ????????
   */
  private loadShortcuts(): void {
    try {
      const saved: string = preferenceManager.getString('home_shortcuts', '');
      if (saved && saved.length > 0) {
        this.shortcuts = JSON.parse(saved) as ShortcutItem[];
      } else {
        // ????
        this.shortcuts = [
          { id: 'smart', icon: '??', titleKey: 'smart_services', color: COMMON_COLORS.PURPLE, url: '', enabled: true },
          { id: 'stats', icon: '??', titleKey: 'reading_statistics', color: COMMON_COLORS.PRIMARY_BLUE, url: 'pages/StatisticsPage', enabled: true },
          { id: 'todo', icon: '??', titleKey: 'todo', color: '#FF6B6B', url: 'pages/TodoPage', enabled: true },
          { id: 'records', icon: '??', titleKey: 'read_records', color: '#52C41A', url: 'pages/ReadRecordPage', enabled: true },
          { id: 'bookmarks', icon: '??', titleKey: 'bookmarks', color: '#FA8C16', url: 'pages/BookmarksPage', enabled: true },
          { id: 'notes', icon: '??', titleKey: 'notes', color: '#722ED1', url: 'pages/NotesPage', enabled: true },
          { id: 'source', icon: '??', titleKey: 'online_sources', color: '#13C2C2', url: 'pages/OnlineSourceMarketPage', enabled: true },
          { id: 'settings', icon: '??', titleKey: 'read_settings', color: '#EB2F96', url: 'pages/SettingsPage', enabled: true }
        ];
      }
    } catch (error) {
      const err = error as Error;
      console.error('[HomeContent] Load shortcuts failed:', err.message);
      this.shortcuts = [];
    }
  }

  /**
   * ????????
   */
  private onShortcutsChange(shortcuts: ShortcutItem[]): void {
    this.shortcuts = shortcuts;
  }

  private getEnabledShortcuts(): ShortcutItem[] {
    const result: ShortcutItem[] = [];
    for (let i = 0; i < this.shortcuts.length; i++) {
      if (this.shortcuts[i].enabled) {
        result.push(this.shortcuts[i]);
      }
    }
    return result;
  }

  private loadStats(): void {
    const allBooks: BookInfo[] = bookViewModel.getAllBooks();
    
    let readingBooks: number = 0;
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].status === ReadStatus.READING) {
        readingBooks++;
      }
    }

    let todayMinutes: number = 0;
    const today: Date = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart: number = today.getTime();

    for (let i = 0; i < allBooks.length; i++) {
      const book = allBooks[i];
      if (book.lastReadTime && book.lastReadTime >= todayStart) {
        todayMinutes += Math.floor((book.totalReadTime || 0) / 60);
      }
    }

    const streakDays = this.calculateStreakDays(allBooks);

    this.stats = {
      totalBooks: allBooks.length,
      readingBooks: readingBooks,
      todayMinutes: todayMinutes,
      streakDays: streakDays
    };
  }

  private calculateStreakDays(books: BookInfo[]): number {
    const readDates = new Set<string>();
    for (let i = 0; i < books.length; i++) {
      const book = books[i];
      if (book.lastReadTime && book.lastReadTime > 0) {
        const date = new Date(book.lastReadTime);
        const dateStr = date.getFullYear() + '-' + date.getMonth() + '-' + date.getDate();
        readDates.add(dateStr);
      }
    }

    let streak = 0;
    const today = new Date();

    for (let i = 0; i < 365; i++) {
      const checkDate = new Date(today);
      checkDate.setDate(checkDate.getDate() - i);
      const dateStr = checkDate.getFullYear() + '-' + checkDate.getMonth() + '-' + checkDate.getDate();

      if (readDates.has(dateStr)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  private getFormatIcon(format: string): string {
    const formatIcons: Record<string, string> = {
      'PDF': '??',
      'EPUB': '??',
      'MOBI': '??',
      'TXT': '??',
      'DOCX': '??',
      'DOC': '??'
    };
    return formatIcons[format] || '??';
  }

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Stack() {
      Column() {
        // ?????
        this.HeaderBar()

        // ????
        this.MainContent()
      }
      .width('100%')
      .layoutWeight(1)

      // 快捷入口编辑面板
      if (this.showShortcutEditor) {
        this.ShortcutEditorSheet()
      }

      // AI找书面板
      if (this.showAISearch) {
        this.AISearchPanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  private async onAISearch(): Promise<void> {
    if (!this.aiSearchKeyword || this.aiSearchKeyword.trim().length === 0) {
      return;
    }
    this.isAISearching = true;
    try {
      const results: OnlineSearchResult[] = await onlineBookService.searchOnlineBooks(this.aiSearchKeyword.trim());
      this.aiSearchResults = results;
    } catch (e) {
      console.error('[HomeContent] AI search failed:', e instanceof Error ? e.message : String(e));
      this.aiSearchResults = [];
    } finally {
      this.isAISearching = false;
    }
  }

  private onAIBookClick(book: OnlineSearchResult): void {
    this.showAISearch = false;
    const params: Record<string, string> = {};
    params['bookUrl'] = book.bookUrl || '';
    params['sourceId'] = book.sourceId || 'ai_search';
    params['bookName'] = book.bookName;
    navigateTo('pages/OnlineBookDetailPage', params);
  }

  @Builder
  AISearchPanel() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showAISearch = false;
        })

      // 面板
      Column({ space: 12 }) {
        // 标题
        Row({ space: 8 }) {
          Text('🤖 AI 找书')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)

          Blank()

          Text('✕')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontColor(this.currentColors.textSecondary)
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.showAISearch = false;
            })
        }
        .width('100%')

        // 搜索输入
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入书名、作者或关键词...', text: this.aiSearchKeyword })
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
            .borderRadius(22)
            .padding({ left: 16, right: 16 })
            .caretColor('#007DFF')
            .onChange((value: string) => {
              this.aiSearchKeyword = value;
            })
            .onSubmit(() => this.onAISearch())

          Button('搜索')
            .height(44)
            .width(72)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')
            .borderRadius(22)
            .onClick(() => this.onAISearch())
        }
        .width('100%')

        // 结果区
        if (this.isAISearching) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(32)
              .height(32)
              .color('#007DFF')
            Text('搜索中...')
              .fontSize(13)
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#888888')
          }
          .width('100%')
          .padding(40)
          .justifyContent(FlexAlign.Center)
        } else if (this.aiSearchResults.length > 0) {
          Scroll() {
            Column({ space: 8 }) {
              ForEach(this.aiSearchResults, (book: OnlineSearchResult) => {
                Row({ space: 12 }) {
                  // 封面
                  Column() {
                    Text('📖')
                      .fontSize(24)
                  }
                  .width(48)
                  .height(48)
                  .backgroundColor('rgba(0,125,255,0.1)')
                  .borderRadius(12)
                  .justifyContent(FlexAlign.Center)

                  // 信息
                  Column({ space: 2 }) {
                    Text(book.bookName)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.currentColors.textPrimary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (book.author) {
                      Text(book.author)
                        .fontSize(11)
                        .fontColor(this.currentColors.textSecondary)
                        .maxLines(1)
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  // 阅读按钮
                  Text('📖 阅读')
                    .fontSize(12)
                    .fontColor('#007DFF')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('rgba(0,125,255,0.1)')
                    .borderRadius(12)
                    .onClick(() => this.onAIBookClick(book))
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
                .borderRadius(12)
              })
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
        } else if (this.aiSearchKeyword && this.aiSearchKeyword.length > 0) {
          // 无结果
          Column({ space: 12 }) {
            Text('🔍')
              .fontSize(48)
            Text('未找到相关书籍')
              .fontSize(13)
              .fontColor(this.currentColors.textSecondary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 默认提示
          Column({ space: 12 }) {
            Text('🤖')
              .fontSize(48)
            Text('输入书名或作者，AI帮你快速找到书籍')
              .fontSize(13)
              .fontColor(this.currentColors.textSecondary)
            Text('找到后可直接阅读')
              .fontSize(11)
              .fontColor(this.isDarkMode ? '#666666' : '#999999')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('75%')
      .position({ y: '25%' })
      .padding(20)
      .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ShortcutEditorSheet() {
    ShortcutEditor({
      onClose: () => { this.showShortcutEditor = false; }
    })
    .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
  }

  @Builder
  HeaderBar() {
    Row() {
      Column({ space: 4 }) {
        Text(tr('app_name'))
          .fontSize(fontScaleManager.getScaledFontSize(22))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)

        Text(tr('app_slogan'))
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.currentColors.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: 12 }) {
        // 搜索按钮
        Column({ space: 2 }) {
          Text('🔍')
            .fontSize(fontScaleManager.getScaledFontSize(20))
          Text(tr('search'))
            .fontSize(fontScaleManager.getScaledFontSize(9))
            .fontColor(this.currentColors.textSecondary)
        }
        .width(50)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
        .borderRadius(12)
        .onClick(() => {
          navigateTo('pages/OnlineSearchPage')
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.95, y: 0.95 })
            .opacity(0.8)
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .opacity(1)
          }
        })

        // 导入按钮
        Column({ space: 2 }) {
          Text('＋')
            .fontSize(fontScaleManager.getScaledFontSize(22))
            .fontColor(this.currentColors.primary)
            .fontWeight(FontWeight.Bold)
          Text(tr('import'))
            .fontSize(fontScaleManager.getScaledFontSize(9))
            .fontColor(this.currentColors.textSecondary)
        }
        .width(50)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.1)' : 'rgba(0,125,255,0.08)')
        .borderRadius(12)
        .onClick(() => {
          if (this.onOpenFilePicker) {
            this.onOpenFilePicker();
          }
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.95, y: 0.95 })
            .opacity(0.8)
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .opacity(1)
          }
        })

        // AI找书按钮
        Column({ space: 2 }) {
          Text('🤖')
            .fontSize(fontScaleManager.getScaledFontSize(20))
          Text('AI找书')
            .fontSize(fontScaleManager.getScaledFontSize(9))
            .fontColor(this.currentColors.textSecondary)
        }
        .width(50)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDarkMode ? 'rgba(114,46,209,0.1)' : 'rgba(114,46,209,0.08)')
        .borderRadius(12)
        .onClick(() => {
          this.showAISearch = true;
          this.aiSearchKeyword = '';
          this.aiSearchResults = [];
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.95, y: 0.95 })
            .opacity(0.8)
          },
          normal: {
            .scale({ x: 1, y: 1 })
            .opacity(1)
          }
        })
      }
    }
    .width('100%')
    .height(68)
    .padding({ left: 20, right: 20, top: 8, bottom: 8 })
    .backgroundColor(this.currentColors.surface)
  }

  @Builder
  MainContent() {
    Scroll() {
      Column({ space: 16 }) {
        // ??????
        this.StatsCards()

        // ????
        this.RecentBooksSection()

        // ????
        this.ShortcutsSection()
      }
      .width('100%')
      .padding(16)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  StatsCards() {
    Column({ space: 12 }) {
      // 第一行
      Row({ space: 12 }) {
        Column() { this.StatCard('📚', this.stats.totalBooks.toString(), tr('total_books'), COMMON_COLORS.PRIMARY_BLUE) }.layoutWeight(1)
        Column() { this.StatCard('📖', this.stats.readingBooks.toString(), tr('reading'), '#52C41A') }.layoutWeight(1)
      }
      .width('100%')

      // 第二行
      Row({ space: 12 }) {
        Column() { this.StatCard('⏱️', this.stats.todayMinutes.toString() + tr('minutes'), tr('today'), '#FA8C16') }.layoutWeight(1)
        Column() { this.StatCard('🔥', this.stats.streakDays.toString() + tr('days'), tr('reading_days'), '#FF6B6B') }.layoutWeight(1)
      }
      .width('100%')
    }
  }

  @Builder
  StatCard(icon: string, value: string, label: string, color: string) {
    CommonCard({
      type: CardType.DEFAULT,
      isDarkMode: this.isDarkMode,
      cornerRadius: 14,
      containerPadding: 14
    }) {
      Column({ space: 8 }) {
        // 图标容器
        Column() {
          Text(icon)
            .fontSize(fontScaleManager.getScaledFontSize(24))
        }
        .width(44)
        .height(44)
        .borderRadius(12)
        .backgroundColor(color + '15')
        .justifyContent(FlexAlign.Center)

        // 数值
        Text(value)
          .fontSize(fontScaleManager.getScaledFontSize(20))
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .maxLines(1)

        // 标签
        Text(label)
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.currentColors.textSecondary)
          .maxLines(1)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  RecentBooksSection() {
    CommonCard({
      type: CardType.ELEVATED,
      isDarkMode: this.isDarkMode,
      cornerRadius: 16,
      containerPadding: 16
    }) {
      Column({ space: 16 }) {
        // 标题栏
        Row() {
          Text(tr('continue_reading'))
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)

          Row({ space: 4 }) {
            Text(tr('view_all'))
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.currentColors.primary)
              .fontWeight(FontWeight.Medium)

            Text('→')
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.currentColors.primary)
          }
          .onClick(() => {
            // 查看全部 - 跳转到书架
            navigateTo('pages/MainPage')
          })
          .stateStyles({
            pressed: {
              .opacity(0.6)
            },
            normal: {
              .opacity(1)
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        if (this.recentBooks.length > 0) {
          this.RecentBooksList()
        } else {
          EmptyState({
            type: EmptyStateType.DATA,
            isDarkMode: this.isDarkMode,
            icon: 'book_fill',
            title: tr('no_reading_books'),
            subtitle: ''
          })
        }
      }
    }
  }

  @Builder
  RecentBooksList() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.recentBooks.slice(0, 6), (book: BookInfo) => {
          this.BookItem(book)
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  BookItem(book: BookInfo) {
    Column({ space: 8 }) {
      Stack() {
        // 封面
        if (book.coverPath && book.coverPath.length > 0) {
          Image(book.coverPath)
            .width(90)
            .height(120)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
            .shadow({
              radius: 8,
              color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.15)',
              offsetX: 0,
              offsetY: 2
            })
        } else {
          // 动态封面
          Column() {
            Text(this.getFormatIcon(book.format))
              .fontSize(32)
              .fontColor('#FFFFFF')
          }
          .width(90)
          .height(120)
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [['#4A90D9', 0.0], ['#6BA5E7', 1.0]]
          })
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .shadow({
            radius: 8,
            color: 'rgba(74,144,217,0.3)',
            offsetX: 0,
            offsetY: 2
          })
        }

        // 阅读进度条
        if (book.readProgress > 0) {
          Column() {
            CommonProgress({
              value: book.readProgress,
              total: 100,
              isDarkMode: this.isDarkMode,
              showText: false
            })
            .width(80)
            .padding({ left: 5, right: 5, bottom: 6 })
          }
          .position({ bottom: 0 })
        }
      }
      .width(90)
      .height(120)

      // 书名
      Text(book.title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
        .width(90)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      if (this.onBookClick) {
        this.onBookClick(book);
      }
    })
    .stateStyles({
      pressed: {
        .scale({ x: 0.95, y: 0.95 })
        .opacity(0.8)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(1)
      }
    })
  }

  @Builder
  ShortcutsSection() {
    CommonCard({
      type: CardType.ELEVATED,
      isDarkMode: this.isDarkMode,
      cornerRadius: 16,
      containerPadding: 16
    }) {
      Column({ space: 16 }) {
        // 标题栏
        Row() {
          Text(tr('shortcuts'))
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)

          Text(tr('edit_shortcuts'))
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontColor(this.currentColors.primary)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.showShortcutEditor = true;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 快捷入口网格
        Grid() {
          ForEach(this.getEnabledShortcuts(), (item: ShortcutItem, index: number) => {
            GridItem() {
              this.HomeShortcut(item.icon, item.titleKey, item.color, index, () => {
                if (item.id === 'smart' && this.onOpenSmartServices) {
                  this.onOpenSmartServices();
                } else {
                  this.navigateTo(item.url);
                }
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .padding({ top: 4 })
      }
    }
  }

  @Builder
  HomeShortcut(icon: string, title: string, color: string, index: number, action: () => void) {
    Column({ space: 8 }) {
      // 图标容器 - 优化渐变背景
      Column() {
        Text(icon)
          .fontSize(26)
      }
      .width(52)
      .height(52)
      .borderRadius(14)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [[color + '25', 0.0], [color + '15', 1.0]]
      })
      .justifyContent(FlexAlign.Center)
      .shadow({
        radius: 6,
        color: color + '20',
        offsetX: 0,
        offsetY: 2
      })

      // 标题
      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(10)
    .onClick(() => {
      action();
    })
    // 交互动画
    .stateStyles({
      pressed: {
        .scale({ x: 0.92, y: 0.92 })
        .opacity(0.85)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(1)
      }
    })
  }
}
