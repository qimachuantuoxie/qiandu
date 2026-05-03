// 书架页面组件 - 优化版
import { promptAction } from '@kit.ArkUI';
import { BookInfo, BookshelfGroup } from '../../../models/CoreBookModel';
import { bookViewModel } from '../../../viewmodels/BookViewModel';
import { themeManager, COMMON_COLORS, AppColors } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';
import { dynamicCoverService, BookCoverData } from '../../../services/image/DynamicCoverService';
import { CommonCard, CardType, EmptyState, EmptyStateType, CommonProgress, CommonDivider } from '../../../components/common/CommonButton';

export interface SortOption {
  label: string;
  value: number;
}

export interface GroupOption {
  groupId: string;
  groupName: string;
  bookCount: number;
}

const SORT_OPTIONS: SortOption[] = [
  { label: '按添加时间降序', value: 0 },
  { label: '按添加时间升序', value: 1 },
  { label: '按书名升序', value: 2 },
  { label: '按书名降序', value: 3 },
  { label: '按作者升序', value: 4 },
  { label: '按作者降序', value: 5 },
  { label: '按阅读进度降序', value: 6 },
  { label: '按阅读进度升序', value: 7 },
  { label: '按最近阅读降序', value: 8 },
  { label: '按最近阅读升序', value: 9 }
];

@Component
export struct BookshelfContent {
  @Prop isDarkMode: boolean = false;
  @Prop isTablet: boolean = false;
  @Prop isBatchMode: boolean = false;
  @Prop selectedBooks: Set<string> = new Set();
  @Prop showBatchBar: boolean = false;
  @Prop currentFilter: number = 0;
  @Prop currentGroupId: string = 'all';
  @Prop currentSortMode: number = 0;
  @Prop searchText: string = '';
  @Prop displayBooks: BookInfo[] = [];
  @Prop gridColumns: number = 3;
  @Prop coverDataMap: Map<string, BookCoverData> = new Map();
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showSortPanel: boolean = false;
  @State viewMode: 'grid' | 'list' = 'grid';
  @State isRefreshing: boolean = false;
  @State loadingCovers: Set<string> = new Set();
  @State failedCovers: Set<string> = new Set();

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.initFontScale();
  }

  private async initFontScale(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  onBookClick?: (book: BookInfo) => void;
  onOpenFilePicker?: () => void;
  onToggleBatchSelection?: (book: BookInfo) => void;
  onExitBatchMode?: () => void;
  onSelectAllBooks?: () => void;
  onBatchDelete?: () => void;
  onBatchToggleFavorite?: () => void;
  onShowGroupPanel?: () => void;
  onFilterChange?: (filter: number) => void;
  onSortChange?: (sortMode: number) => void;
  onSearchChange?: (searchText: string) => void;
  onSelectGroup?: (groupId: string) => void;
  onGetCoverData?: (bookId: string) => BookCoverData;

  private getFormatIcon(format: string): string {
    const formatIcons = new Map<string, string>([
      ['PDF', '📄'],
      ['EPUB', '📖'],
      ['MOBI', '📱'],
      ['TXT', '📝'],
      ['DOCX', '📃'],
      ['DOC', '📃']
    ]);
    return formatIcons.get(format) || '📚';
  }

  private isBookSelected(bookId: string): boolean {
    return this.selectedBooks.has(bookId);
  }

  build() {
    Stack() {
      Column() {
        // 头部导航
        this.Header()

        // 筛选和排序栏
        this.FilterAndSortTabs()

        // 内容区域
        if (this.displayBooks.length === 0) {
          Column() {
            this.EmptyView()
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          this.BookGrid()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDarkMode ? '#0F0F10' : '#F5F5F7')

      // 批量操作栏 - 底部悬浮
      if (this.isBatchMode) {
        this.BatchOperationBar()
      }

      // 排序面板 - 弹出层
      this.SortSheet()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    if (this.isBatchMode) {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(this.currentColors.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.onExitBatchMode) {
              this.onExitBatchMode();
            }
          })

        Text('已选 ' + this.selectedBooks.size + ' 本')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(this.selectedBooks.size === this.displayBooks.length ? '取消全选' : '全选')
          .fontSize(16)
          .fontColor(this.currentColors.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.onSelectAllBooks) {
              this.onSelectAllBooks();
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.currentColors.surface)
      .border({
        width: { bottom: 1 },
        color: this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'
      })
    } else {
      Row() {
        Text('书架')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)
          .layoutWeight(1)

        Row({ space: 8 }) {
          Column() {
            Text('🔍').fontSize(20)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.onSearchChange) {
              this.onSearchChange('');
            }
          })
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })

          Column() {
            Text('＋').fontSize(22).fontColor(this.currentColors.primary)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.15)' : 'rgba(0,125,255,0.1)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.onOpenFilePicker) {
              this.onOpenFilePicker();
            }
          })
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.currentColors.surface)
    }
  }

  @Builder
  FilterAndSortTabs() {
    CommonCard({
      type: CardType.DEFAULT,
      isDarkMode: this.isDarkMode,
      cornerRadius: 0,
      containerPadding: 12
    }) {
      Row({ space: 12 }) {
        Column() {
          Text('📁').fontSize(18)
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onShowGroupPanel) {
            this.onShowGroupPanel();
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(['全部', '阅读中', '收藏', '已完成'], (item: string, index: number) => {
              Text(item)
                .fontSize(13)
                .fontWeight(this.currentFilter === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentFilter === index ? '#FFFFFF' : (this.isDarkMode ? '#AAAAAA' : '#666666'))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.currentFilter === index ? COMMON_COLORS.PRIMARY_BLUE : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'))
                .borderRadius(18)
                .onClick(() => {
                  if (this.onFilterChange) {
                    this.onFilterChange(index);
                  }
                })
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        Row({ space: 4 }) {
          Column() {
            Text('▦').fontSize(18)
          }
          .width(36)
          .height(36)
          .borderRadius(10)
          .backgroundColor(this.viewMode === 'grid'
            ? (this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.12)')
            : 'transparent')
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.viewMode = 'grid')
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })

          Column() {
            Text('☰').fontSize(18)
          }
          .width(36)
          .height(36)
          .borderRadius(10)
          .backgroundColor(this.viewMode === 'list'
            ? (this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.12)')
            : 'transparent')
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.viewMode = 'list')
          .stateStyles({
            pressed: { .scale({ x: 0.9, y: 0.9 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
        }

        Column() {
          Text('⇅').fontSize(18)
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showSortPanel = !this.showSortPanel;
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
    }
  }

  @Builder
  SortSheet() {
    if (this.showSortPanel) {
      Column() {
        Row()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => this.showSortPanel = false)

        Column() {
          Row() {
            Text('排序方式')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

            Blank()

            Text('✕')
              .fontSize(18)
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
              .onClick(() => this.showSortPanel = false)
          }
          .width('100%')
          .padding(16)

          Scroll() {
            Column({ space: 0 }) {
              ForEach(SORT_OPTIONS, (item: SortOption) => {
                Row() {
                  Text(item.label)
                    .fontSize(15)
                    .fontColor(this.currentSortMode === item.value
                      ? '#007DFF'
                      : (this.isDarkMode ? '#CCCCCC' : '#333333'))
                    .fontWeight(this.currentSortMode === item.value ? FontWeight.Medium : FontWeight.Normal)
                    .layoutWeight(1)

                  if (this.currentSortMode === item.value) {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#007DFF')
                  }
                }
                .width('100%')
                .padding({ top: 14, bottom: 14, left: 16, right: 16 })
                .backgroundColor(this.currentSortMode === item.value
                  ? (this.isDarkMode ? 'rgba(0,125,255,0.1)' : 'rgba(0,125,255,0.05)')
                  : 'transparent')
                .onClick(() => {
                  if (this.onSortChange) {
                    this.onSortChange(item.value);
                  }
                  this.showSortPanel = false;
                })
              })
            }
            .width('100%')
          }
          .layoutWeight(1)
        .width('100%')
        .height('60%')
        .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
        .borderRadius({ topLeft: 20, topRight: 20 })
        .transition(TransitionEffect.translate({ y: 300 }).animation({ duration: 250 }))
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    }
  }

  @Builder
  GridBookView() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Scroll() {
        Grid() {
          ForEach(this.displayBooks, (book: BookInfo) => {
            GridItem() {
              this.BookItem(book)
            }
          }, (book: BookInfo) => book.id)
        }
        .columnsTemplate(this.isTablet ? '1fr 1fr 1fr 1fr 1fr' : '1fr 1fr 1fr 1fr')
        .columnsGap(6)
        .rowsGap(8)
        .padding({ left: 6, right: 6, top: 6, bottom: 12 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .onRefreshing(async () => {
      await this.refreshBooks();
      this.isRefreshing = false;
    })
  }

  @Builder
  ListBookView() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      List({ space: 12 }) {
        ForEach(this.displayBooks, (book: BookInfo) => {
          ListItem() {
            this.ListBookItem(book)
          }
        }, (book: BookInfo) => book.id)
      }
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8 })
      .width('100%')
      .edgeEffect(EdgeEffect.Spring)
    }
    .onRefreshing(async () => {
      await this.refreshBooks();
      this.isRefreshing = false;
    })
  }

  @Builder
  BookGrid() {
    if (this.viewMode === 'grid') {
      this.GridBookView()
    } else {
      this.ListBookView()
    }
  }

  private async refreshBooks(): Promise<void> {
    if (this.onFilterChange) {
      const currentFilter = this.currentFilter;
      this.onFilterChange(currentFilter);
    }
  }

  @Builder
  ListBookItem(book: BookInfo) {
    Column() {
      CommonCard({
      type: CardType.DEFAULT,
      isDarkMode: this.isDarkMode,
      cornerRadius: 12,
      containerPadding: 12
    }) {
      Row({ space: 12 }) {
        Column() {
          if (this.failedCovers.has(book.id)) {
            Column() {
              Text(this.getFormatIcon(book.format))
                .fontSize(24)
                .fontColor('#FFFFFF')
            }
            .width(60)
            .height(84)
            .justifyContent(FlexAlign.Center)
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [['#4A90D9', 0.0], ['#6BA5E7', 1.0]]
            })
            .borderRadius(8)
          } else if (this.loadingCovers.has(book.id)) {
            Column()
              .width(60)
              .height(84)
              .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#E0E0E0')
              .borderRadius(8)
          } else if (book.coverPath && book.coverPath.length > 0) {
            Image(book.coverPath)
              .width(60)
              .height(84)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .shadow({
                radius: 6,
                color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.15)',
                offsetX: 0,
                offsetY: 2
              })
              .onError(() => {
                const newLoading = new Set(this.loadingCovers);
                newLoading.delete(book.id);
                this.loadingCovers = newLoading;
                
                const newFailed = new Set(this.failedCovers);
                newFailed.add(book.id);
                this.failedCovers = newFailed;
              })
          } else {
            Column() {
              Text(this.getFormatIcon(book.format))
                .fontSize(24)
                .fontColor('#FFFFFF')
            }
            .width(60)
            .height(84)
            .justifyContent(FlexAlign.Center)
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [['#4A90D9', 0.0], ['#6BA5E7', 1.0]]
            })
            .borderRadius(8)
          }
        }

        Column({ space: 6 }) {
          Text(book.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')

          Text(book.author)
            .fontSize(12)
            .fontColor(this.isDarkMode ? '#888888' : '#8E8E93')

          Row({ space: 8 }) {
            Text(book.format)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)')
              .borderRadius(4)
              .fontColor(this.isDarkMode ? '#CCCCCC' : '#666666')

            if (book.readProgress > 0) {
              Text('已读 ' + book.readProgress + '%')
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.isBatchMode) {
          Column() {
            Text(this.isBookSelected(book.id) ? '✓' : '')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(24)
          .height(24)
          .backgroundColor(this.isBookSelected(book.id) ? COMMON_COLORS.PRIMARY_BLUE : 'rgba(0,0,0,0.3)')
          .borderRadius(12)
          .border({
            width: 1.5,
            color: '#FFFFFF'
          })
        }
      }
      .width('100%')
      }
    }
    .onClick(() => {
      if (this.isBatchMode && this.onToggleBatchSelection) {
        this.onToggleBatchSelection(book);
      } else if (!this.isBatchMode && this.onBookClick) {
        this.onBookClick(book);
      }
    })
    .stateStyles({
      pressed: {
        .scale({ x: 0.98, y: 0.98 })
        .opacity(0.9)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(1)
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (!this.isBatchMode && this.onToggleBatchSelection) {
            this.onToggleBatchSelection(book);
          }
        })
    )
  }

  @Builder
  BookItem(book: BookInfo) {
    Column({ space: 4 }) {
      Stack() {
        if (this.failedCovers.has(book.id)) {
          Column() {
            Text(this.getFormatIcon(book.format)).fontSize(24).fontColor('#FFFFFF')
          }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          .linearGradient({direction: GradientDirection.Top, colors: [['#4A90D9', 0.0], ['#6BA5E7', 1.0]]})
          .borderRadius(8)
        } else if (this.loadingCovers.has(book.id)) {
          Column().width('100%').height('100%').backgroundColor(this.isDarkMode ? '#2C2C2E' : '#E0E0E0').borderRadius(8)
        } else if (book.coverPath && book.coverPath.length > 0) {
          Image(book.coverPath).width('100%').aspectRatio(0.72).objectFit(ImageFit.Cover).borderRadius(8)
            .onError(() => {
              const newFailed = new Set(this.failedCovers);
              newFailed.add(book.id);
              this.failedCovers = newFailed;
            })
        } else {
          Column() {
            Text(this.getFormatIcon(book.format)).fontSize(24).fontColor('#FFFFFF')
          }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE).borderRadius(8)
        }

        Text(book.format)
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 3, right: 3, top: 1, bottom: 1 })
          .backgroundColor('rgba(0,0,0,0.6)')
          .borderRadius(3)
          .position({ x: 4, y: 4 })

        if (book.readProgress > 0) {
          Column() {
            CommonProgress({
              value: book.readProgress,
              total: 100,
              isDarkMode: this.isDarkMode,
              showText: false
            })
            .width('88%')
            .padding({ bottom: 3 })
          }
          .position({ bottom: 0 })
        }

        if (this.isBatchMode) {
          Column() {
            Text(this.isBookSelected(book.id) ? '✓' : '')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(18)
          .height(18)
          .borderRadius(9)
          .backgroundColor(this.isBookSelected(book.id) ? '#007DFF' : 'rgba(0,0,0,0.3)')
          .border({ width: 1.5, color: '#FFFFFF' })
          .position({ top: 4, right: 4 })
        }
      }

      Text(book.title)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(13)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
        .width('100%')
    }
    .width('100%')
    .onClick(() => {
      if (this.isBatchMode && this.onToggleBatchSelection) {
        this.onToggleBatchSelection(book);
      } else if (!this.isBatchMode && this.onBookClick) {
        this.onBookClick(book);
      }
    })
    .stateStyles({
      pressed: {
        .scale({ x: 0.96, y: 0.96 })
        .opacity(0.85)
      },
      normal: {
        .scale({ x: 1, y: 1 })
        .opacity(1)
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (!this.isBatchMode && this.onToggleBatchSelection) {
            this.onToggleBatchSelection(book);
          }
        })
    )
  }


  @Builder
  EmptyView() {
    EmptyState({
      type: EmptyStateType.DATA,
      isDarkMode: this.isDarkMode,
      icon: '📚',
      title: '暂无书籍',
      subtitle: '点击下方按钮添加您的第一本书',
      showButton: true,
      buttonText: '添加书籍',
      onButtonClick: (): void => {
        if (this.onOpenFilePicker) {
          this.onOpenFilePicker();
        }
      }
    })
  }

  @Builder
  BatchOperationBar() {
    Column() {
      CommonCard({
      type: CardType.ELEVATED,
      isDarkMode: this.isDarkMode,
      cornerRadius: 0,
      containerPadding: 0
    }) {
      Row({ space: 0 }) {
        Column({ space: 4 }) {
          Text('🗑️').fontSize(22)
          Text('删除')
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#FF6B6B' : '#FF3B30')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onBatchDelete) {
            this.onBatchDelete();
          }
        })
        .stateStyles({
          pressed: {
            .backgroundColor(this.isDarkMode ? 'rgba(255,59,48,0.12)' : 'rgba(255,59,48,0.06)')
          },
          normal: {
            .backgroundColor('transparent')
          }
        })

        Divider()
          .vertical(true)
          .color(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
          .height(40)

        Column({ space: 4 }) {
          Text('⭐').fontSize(22)
          Text('收藏')
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#FFB340' : '#FF9500')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onBatchToggleFavorite) {
            this.onBatchToggleFavorite();
          }
        })
        .stateStyles({
          pressed: {
            .backgroundColor(this.isDarkMode ? 'rgba(255,149,0,0.12)' : 'rgba(255,149,0,0.06)')
          },
          normal: {
            .backgroundColor('transparent')
          }
        })

        Divider()
          .vertical(true)
          .color(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
          .height(40)

        Column({ space: 4 }) {
          Text('📁').fontSize(22)
          Text('分组')
            .fontSize(11)
            .fontColor(this.isDarkMode ? '#5AC8FA' : '#007DFF')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onShowGroupPanel) {
            this.onShowGroupPanel();
          }
        })
        .stateStyles({
          pressed: {
            .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.12)' : 'rgba(0,125,255,0.06)')
          },
          normal: {
            .backgroundColor('transparent')
          }
        })
      }
      .width('100%')
      }
    }
    .position({ bottom: 0 })
    .transition(TransitionEffect.translate({ y: 80 }).animation({ duration: 200 }))
  }
}
