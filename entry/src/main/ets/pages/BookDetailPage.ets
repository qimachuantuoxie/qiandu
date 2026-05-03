import { router } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { promptAction } from '@kit.ArkUI';
import { BookInfo, ReadStatus, BookshelfGroup } from '../models/CoreBookModel';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { DeviceUtils } from '../utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { dynamicCoverService, BookCoverData } from '../services/image/DynamicCoverService';
import { tr } from '../utils/I18nManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { common } from '@kit.AbilityKit';
import { CommonCard, CardType, CommonButton, ButtonType, ButtonSize, CommonDivider, CommonProgress } from '../components/common/CommonButton';

interface BookDetailParams {
  bookId: string;
}

@Entry
@Component
struct BookDetailPage {
  @State book: BookInfo | null = null;
  @State isFavorite: boolean = false;
  @State isTablet: boolean = false;
  @State isDarkMode: boolean = false;
  @State coverData: BookCoverData | null = null;
  @State showMoreMenu: boolean = false;
  @State showGroupSheet: boolean = false;
  @State groups: BookshelfGroup[] = [];
  @State bookGroups: string[] = [];
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();

  private unsubscribe: (() => void) | null = null;
  private groupUnsubscribe: (() => void) | null = null;
  @State private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.loadBookData();
    this.loadGroups();
    this.setupSubscriptions();
  }

  private async initData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet();
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
  }

  private setupSubscriptions(): void {
    this.unsubscribe = bookViewModel.subscribe((_books: BookInfo[]): void => {
      this.loadBookData();
    });

    this.groupUnsubscribe = bookViewModel.subscribeGroups((groups: BookshelfGroup[]): void => {
      this.groups = groups;
    });
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
    if (this.groupUnsubscribe) {
      this.groupUnsubscribe();
    }
  }

  private loadGroups(): void {
    this.groups = bookViewModel.getAllGroups();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private loadBookData(): void {
    const paramsObj = router.getParams();
    if (paramsObj) {
      const params = paramsObj as BookDetailParams;
      if (params.bookId) {
        const bookId = params.bookId;
        const allBooks = bookViewModel.getAllBooks();
        for (let i = 0; i < allBooks.length; i++) {
          if (allBooks[i].id === bookId) {
            const foundBook = allBooks[i];
            this.book = foundBook;
            this.isFavorite = foundBook.isFavorite;
            this.bookGroups = foundBook.groupIds || [];
            this.coverData = dynamicCoverService.generateCoverData(
              foundBook.title,
              foundBook.author,
              foundBook.id
            );
            break;
          }
        }
      }
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  private onReadClick(): void {
    if (this.book) {
      const params: Record<string, string> = {};
      params['bookId'] = this.book.id;
      navigateTo('pages/EnhancedReaderPage', params);
    }
  }

  private onToggleFavorite(): void {
    if (this.book) {
      bookViewModel.toggleFavorite(this.book.id);
      this.isFavorite = !this.isFavorite;
    }
  }

  private onDeleteClick(): void {
    if (this.book) {
      bookViewModel.deleteBook(this.book.id);
      try {
        router.back();
      } catch (e) {
        console.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
      }
    }
  }

  private toggleGroup(groupId: string): void {
    if (this.book) {
      const index = this.bookGroups.indexOf(groupId);
      let newGroups: string[] = [];
      if (index > -1) {
        newGroups = this.bookGroups.slice();
        newGroups.splice(index, 1);
      } else {
        newGroups = this.bookGroups.slice();
        newGroups.push(groupId);
      }
      this.bookGroups = newGroups;
      this.book.groupIds = this.bookGroups;
      bookViewModel.updateBook(this.book);
    }
  }

  private isInGroup(groupId: string): boolean {
    return this.bookGroups.includes(groupId);
  }

  @Builder
  Header() {
    Row() {
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .onClick((): void => {
        try {
          router.back();
        } catch (e) {
          console.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Text('书籍详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row() {
        Text('⋯')
          .fontSize(20)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .onClick((): void => { this.showMoreMenu = true; })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
  }

  @Builder
  MoreMenu() {
    if (this.showMoreMenu) {
      Column() {
        Row()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => this.showMoreMenu = false)

        Column() {
          Column() {
            Row() {
              Text('📁')
                .fontSize(20)
              Text('分组管理')
                .fontSize(16)
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .margin({ left: 12 })
            }
            .width('100%')
            .padding(16)
            .onClick((): void => {
              this.showMoreMenu = false;
              this.showGroupSheet = true;
            })
          }
          .width('100%')

          Divider()
            .color(this.tc('rgba(0,0,0,0.1)', 'rgba(255,255,255,0.1)'))

          Column() {
            Row() {
              Text('🗑️')
                .fontSize(20)
              Text('删除书籍')
                .fontSize(16)
                .fontColor('#FF4D4F')
                .margin({ left: 12 })
            }
            .width('100%')
            .padding(16)
            .onClick((): void => {
              this.showMoreMenu = false;
              this.onDeleteClick();
            })
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
        .borderRadius({ topLeft: 16, topRight: 16 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.End)
    }
  }

  @Builder
  GroupSheet() {
    if (this.showGroupSheet) {
      Column() {
        Row()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => this.showGroupSheet = false)

        Column() {
          Row() {
            Text('分组管理')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            Blank()

            Text('完成')
              .fontSize(16)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
              .onClick(() => this.showGroupSheet = false)
          }
          .width('100%')
          .padding(20)

          Scroll() {
            Column({ space: 8 }) {
              if (this.groups.length === 0) {
                Text('暂无分组')
                  .fontSize(14)
                  .fontColor(this.isDarkMode ? '#888888' : '#999999')
                  .padding(20)
              } else {
                ForEach(this.groups, (group: BookshelfGroup) => {
                  Row() {
                    Checkbox()
                      .select(this.isInGroup(group.id))
                      .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
                      .onChange((value: boolean): void => {
                        this.toggleGroup(group.id);
                      })
                    Text(group.name)
                      .fontSize(15)
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .margin({ left: 12 })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
                  .borderRadius(12)
                }, (group: BookshelfGroup) => group.id)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 32 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
  }

  @Builder
  BookCover() {
    Stack() {
      if (this.book && this.book.coverPath && this.book.coverPath.length > 0) {
        Image(this.book.coverPath)
          .width('100%')
          .height('100%')
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          if (this.coverData) {
            Text(this.book !== null && this.book.format !== undefined ? this.book.format : '📚')
              .fontSize(this.isTablet ? 48 : 40)
              .fontColor('rgba(255,255,255,0.9)')
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#4A90D9', 0.0], ['#8B5CF6', 1.0]]
        })
        .borderRadius(12)
      }

      Text(this.book !== null && this.book.format !== undefined ? this.book.format : '')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor('rgba(0,0,0,0.6)')
        .borderRadius(4)
        .position({ x: 8, y: 8 })
    }
    .width(this.isTablet ? 150 : 130)
    .height(this.isTablet ? 210 : 182)
    .shadow({
      radius: 16,
      color: 'rgba(0,0,0,0.3)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  StatusBadge() {
    if (this.book) {
      Row({ space: 4 }) {
        Text(this.getStatusText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor())

        if (this.book.readProgress > 0) {
          Text('·')
            .fontSize(12)
            .fontColor(this.getStatusColor())
          Text(this.book.readProgress + '%')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getStatusColor())
        }
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.getStatusColor() + '15')
      .borderRadius(14)
    }
  }

  @Builder
  ActionBar() {
    Row() {
      Column({ space: 6 }) {
        Row() {
          Text(this.isFavorite ? '⭐' : '☆')
            .fontSize(22)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onToggleFavorite())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text(this.isFavorite ? '已收藏' : '收藏')
          .fontSize(11)
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }

      Blank()

      Column({ space: 6 }) {
        Row() {
          Text('📁')
            .fontSize(22)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.showGroupSheet = true)
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('分组')
          .fontSize(11)
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }

      Blank()

      Column({ space: 6 }) {
        Row() {
          Text('↗')
            .fontSize(22)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.shareBook())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('分享')
          .fontSize(11)
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }
    }
    .width('100%')
    .padding({ left: 32, right: 32, top: 12, bottom: 12 })
  }

  build() {
    Stack() {
      Column() {
        this.Header()

        if (this.book) {
          Scroll() {
            Column({ space: 16 }) {
              // 书籍信息卡片
              CommonCard({
                type: CardType.ELEVATED,
                isDarkMode: this.isDarkMode,
                cornerRadius: 16,
                containerPadding: 20
              }) {
                Row() {
                  this.BookCover()

                  Column({ space: 10 }) {
                    Text(this.book.title)
                      .fontSize(this.isTablet ? 22 : 18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    Text(this.book.author)
                      .fontSize(this.isTablet ? 14 : 12)
                      .fontColor(this.tc('#666666', '#AAAAAA'))

                    this.StatusBadge()

                    if (this.book.lastReadTime > 0) {
                      Text('最近阅读: ' + this.formatDate(this.book.lastReadTime))
                        .fontSize(11)
                        .fontColor(this.tc('#999999', '#666666'))
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .padding({ left: 16 })
                }
                .width('100%')
              }

              // 操作按钮
              CommonCard({
                type: CardType.DEFAULT,
                isDarkMode: this.isDarkMode,
                cornerRadius: 16,
                containerPadding: 0
              }) {
                this.ActionBar()
              }

              // 阅读进度
              if (this.book.readProgress > 0) {
                CommonCard({
                  type: CardType.ELEVATED,
                  isDarkMode: this.isDarkMode,
                  cornerRadius: 16,
                  containerPadding: 16
                }) {
                  Column({ space: 12 }) {
                    Row() {
                      Text('阅读进度')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

                      Text(this.book.readProgress + '%')
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                    }
                    .width('100%')

                    CommonProgress({
                      value: this.book.readProgress,
                      total: 100,
                      isDarkMode: this.isDarkMode,
                      showText: false
                    })

                    Text('第 ' + this.book.currentPage + ' / ' + this.book.totalPages + ' 页')
                      .fontSize(12)
                      .fontColor(this.tc('#666666', '#AAAAAA'))
                  }
                }
              }

              // 书籍信息
              CommonCard({
                type: CardType.ELEVATED,
                isDarkMode: this.isDarkMode,
                cornerRadius: 16,
                containerPadding: 0
              }) {
                Column() {
                  Text('书籍信息')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                    .width('100%')
                    .padding({ left: 16, top: 16, bottom: 12 })

                  this.InfoItem('格式', this.book.format)
                  CommonDivider({ isDarkMode: this.isDarkMode })
                  this.InfoItem('文件大小', this.formatFileSize(this.book.fileSize || 0))
                  CommonDivider({ isDarkMode: this.isDarkMode })
                  this.InfoItem('总页数', this.book.totalPages + ' 页')
                }
              }

              // 书籍简介
              if (this.book.description && this.book.description.length > 0) {
                CommonCard({
                  type: CardType.ELEVATED,
                  isDarkMode: this.isDarkMode,
                  cornerRadius: 16,
                  containerPadding: 16
                }) {
                  Column({ space: 12 }) {
                    Text('简介')
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .width('100%')

                    Text(this.book.description)
                      .fontSize(14)
                      .fontColor(this.tc('#666666', '#AAAAAA'))
                      .lineHeight(22)
                      .width('100%')
                  }
                }
              }

              // 开始阅读按钮
              CommonButton({
                text: this.book.readProgress > 0 ? '继续阅读' : '开始阅读',
                type: ButtonType.PRIMARY,
                buttonSize: ButtonSize.LARGE,
                isEnabled: true,
                isDarkMode: this.isDarkMode,
                onButtonClick: (): void => {
                  this.onReadClick();
                }
              })
              .width('90%')
              .margin({ top: 8, bottom: 40 })
            }
            .width('100%')
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
          }
          .layoutWeight(1)
          .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F7')
        } else {
          Column() {
            Text('📚')
              .fontSize(64)
              .fontColor(this.isDarkMode ? '#333333' : '#DDDDDD')
            Text('暂无数据')
              .fontSize(16)
              .fontColor(this.tc('#999999', '#666666'))
              .margin({ top: 16 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')

      this.MoreMenu()
      this.GroupSheet()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')

      Blank()

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#333333')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  private getStatusText(): string {
    if (!this.book) return '';
    switch (this.book.status) {
      case ReadStatus.READING: return '阅读中';
      case ReadStatus.FINISHED: return '已读完';
      case ReadStatus.UNREAD: return '未阅读';
      default: return '未知';
    }
  }

  private getStatusColor(): string {
    if (!this.book) return '#999999';
    switch (this.book.status) {
      case ReadStatus.READING: return COMMON_COLORS.PRIMARY_BLUE;
      case ReadStatus.FINISHED: return COMMON_COLORS.SUCCESS_GREEN;
      case ReadStatus.UNREAD: return '#999999';
      default: return '#999999';
    }
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) return '今天';
    if (days === 1) return '昨天';
    if (days < 7) return days + '天前';
    if (days < 30) return Math.floor(days / 7) + '周前';
    return Math.floor(days / 30) + '个月前';
  }

  private shareBook(): void {
    if (!this.book) return;

    const shareText = '推荐阅读《' + this.book.title + '》\n作者: ' + this.book.author + '\n\n千读阅界 - 让阅读更美好';

    try {
      promptAction.showToast({
        message: shareText,
        duration: 3000
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('分享失败:', message);
    }
  }
}
