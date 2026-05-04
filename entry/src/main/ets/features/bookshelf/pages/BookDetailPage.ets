import { logger } from '../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { getContext } from '@ohos.arkui';
import { promptAction } from '@kit.ArkUI';
import { BookInfo, ReadStatus, BookshelfGroup } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { dynamicCoverService, BookCoverData } from '../core/services/image/DynamicCoverService';
import { tr } from '../core/utils/LocalizationUtil';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { common } from '@kit.AbilityKit';
import { CommonCard, CardType, CommonButton, ButtonType, ButtonSize, CommonDivider, CommonProgress } from '../components/common/CommonButton';
import { BackButton } from '../components/common/BackButton';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

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
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    DeviceUtils.init();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
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
    const paramsObj = this.getUIContext().getRouter()?.getParams();
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
        goBack();
      } catch (e) {
        logger.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
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
      BackButton({ 
        isDarkMode: this.isDarkMode, 
        onBack: (): void => {
          try {
            goBack();
          } catch (e) {
            logger.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
          }
        } 
      })

      Text(tr('book_detail'))
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row() {
        Text('•••')
          .fontSize(Size.iconMD)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#333333')
      }
      .width(Size.avatarMD)
      .height(Size.avatarMD)
      .borderRadius(BorderRadius.full)
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
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.bg('#FFFFFF', '#1C1C1E'))
    .padding({
      top: layoutHelper.getSafeTopPadding(),
      bottom: Spacing.sm
    })
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
              SymbolGlyph($r('sys.symbol.folder'))
                .fontSize(Size.iconMD)
                .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
              Text(tr('group_manage'))
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .margin({ left: Spacing.md })
            }
            .width('100%')
            .padding(Spacing.lg)
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
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(Size.iconMD)
                .fontColor(['#FF4D4F'])
              Text(tr('delete_book'))
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontColor('#FF4D4F')
                .margin({ left: Spacing.md })
            }
            .width('100%')
            .padding(Spacing.lg)
            .onClick((): void => {
              this.showMoreMenu = false;
              this.onDeleteClick();
            })
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
        .borderRadius({ topLeft: BorderRadius.lg, topRight: BorderRadius.lg })
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
            Text(tr('group_manage'))
              .fontSize(fontScaleManager.getScaledFontSize(18))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            Blank()

            Text(tr('done'))
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
              .onClick(() => this.showGroupSheet = false)
          }
          .width('100%')
          .padding(Spacing.xl)

          Scroll() {
            Column({ space: Spacing.sm }) {
              if (this.groups.length === 0) {
                Text(tr('no_groups'))
                  .fontSize(fontScaleManager.getScaledFontSize(14))
                  .fontColor(this.isDarkMode ? '#888888' : '#999999')
                  .padding(Spacing.xl)
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
                      .fontSize(fontScaleManager.getScaledFontSize(15))
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .margin({ left: Spacing.md })
                  }
                  .width('100%')
                  .padding(Spacing.md)
                  .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
                  .borderRadius(BorderRadius.md)
                }, (group: BookshelfGroup) => group.id)
              }
            }
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.xxxl })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
        .borderRadius({ topLeft: BorderRadius.xxl, topRight: BorderRadius.xxl })
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
          .borderRadius(BorderRadius.md)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          if (this.coverData) {
            Text(this.book !== null && this.book.format !== undefined ? this.book.format : '📖')
              .fontSize(this.isTablet ? Size.iconXXL * 1.2 : Size.iconXXL)
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
        .borderRadius(BorderRadius.md)
      }

      Text(this.book !== null && this.book.format !== undefined ? this.book.format : '')
        .fontSize(fontScaleManager.getScaledFontSize(10))
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
        .backgroundColor('rgba(0,0,0,0.6)')
        .borderRadius(BorderRadius.xs)
        .position({ x: Spacing.sm, y: Spacing.sm })
    }
    .width(this.isTablet ? 150 : 130)
    .height(this.isTablet ? 210 : 182)
    .shadow(getShadow('lg', this.isDarkMode))
  }

  @Builder
  StatusBadge() {
    if (this.book) {
      Row({ space: Spacing.xs }) {
        Text(this.getStatusText())
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStatusColor())

        if (this.book.readProgress > 0) {
          Text('●')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.getStatusColor())
          Text(this.book.readProgress + '%')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getStatusColor())
        }
      }
      .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.xs, bottom: Spacing.xs })
      .backgroundColor(this.getStatusColor() + '15')
      .borderRadius(BorderRadius.xl)
    }
  }

  @Builder
  ActionBar() {
    Row({ space: Spacing.xxxl }) {
      Column({ space: Spacing.sm }) {
        Row() {
          Text(this.isFavorite ? '❤️' : '🤍')
            .fontSize(Size.iconLG)
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onToggleFavorite())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text(this.isFavorite ? tr('favorited') : tr('favorite'))
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }

      Blank()

      Column({ space: Spacing.sm }) {
        Row() {
          Text('folder')
            .fontSize(Size.iconLG)
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.showGroupSheet = true)
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text(tr('groups'))
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }

      Blank()

      Column({ space: Spacing.sm }) {
        Row() {
          Text('⬆️')
            .fontSize(Size.iconLG)
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.shareBook())
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text(tr('share'))
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.tc('#666666', '#AAAAAA'))
      }
    }
    .width('100%')
    .padding({ left: Spacing.xxxl, right: Spacing.xxxl, top: Spacing.md, bottom: Spacing.md })
  }

  build() {
    Stack() {
      Column() {
        this.Header()

        if (this.book) {
          Scroll() {
            Column({ space: Spacing.lg }) {
              CommonCard({
                type: CardType.ELEVATED,
                isDarkMode: this.isDarkMode,
                cornerRadius: BorderRadius.lg,
                containerPadding: Spacing.xl
              }) {
                Row() {
                  this.BookCover()

                  Column({ space: Spacing.md }) {
                    Text(this.book.title)
                      .fontSize(this.isTablet ? fontScaleManager.getScaledFontSize(22) : fontScaleManager.getScaledFontSize(18))
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    Text(this.book.author)
                      .fontSize(this.isTablet ? fontScaleManager.getScaledFontSize(14) : fontScaleManager.getScaledFontSize(12))
                      .fontColor(this.tc('#666666', '#AAAAAA'))

                    this.StatusBadge()

                    if (this.book.lastReadTime > 0) {
                      Text(tr('last_read') + ' ' + this.formatDate(this.book.lastReadTime))
                        .fontSize(fontScaleManager.getScaledFontSize(11))
                        .fontColor(this.tc('#999999', '#666666'))
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .padding({ left: Spacing.lg })
                }
                .width('100%')
                .padding({ top: Spacing.sm, bottom: Spacing.sm })
              }

              CommonCard({
                type: CardType.DEFAULT,
                isDarkMode: this.isDarkMode,
                cornerRadius: BorderRadius.lg,
                containerPadding: 0
              }) {
                this.ActionBar()
              }
              .margin({ top: Spacing.sm, bottom: Spacing.sm })

              if (this.book.readProgress > 0) {
                CommonCard({
                  type: CardType.ELEVATED,
                  isDarkMode: this.isDarkMode,
                  cornerRadius: BorderRadius.lg,
                  containerPadding: Spacing.lg
                }) {
                  Column({ space: Spacing.md }) {
                    Row() {
                      Text(tr('reading_progress'))
                        .fontSize(fontScaleManager.getScaledFontSize(16))
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

                      Text(this.book.readProgress + '%')
                        .fontSize(fontScaleManager.getScaledFontSize(14))
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

                    Text(tr('page_info', { current: String(this.book.currentPage), total: String(this.book.totalPages) }))
                      .fontSize(fontScaleManager.getScaledFontSize(12))
                      .fontColor(this.tc('#666666', '#AAAAAA'))
                  }
                  .padding({ top: Spacing.md, bottom: Spacing.md })
                }
              }

              CommonCard({
                type: CardType.ELEVATED,
                isDarkMode: this.isDarkMode,
                cornerRadius: BorderRadius.lg,
                containerPadding: 0
              }) {
                Column() {
                  Text(tr('book_info'))
                    .fontSize(fontScaleManager.getScaledFontSize(16))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                    .width('100%')
                    .padding({ left: Spacing.lg, top: Spacing.lg, bottom: Spacing.md })

                  this.InfoItem(tr('format'), this.book.format)
                  CommonDivider({ isDarkMode: this.isDarkMode })
                  this.InfoItem(tr('file_size'), this.formatFileSize(this.book.fileSize || 0))
                  CommonDivider({ isDarkMode: this.isDarkMode })
                  this.InfoItem(tr('total_pages'), String(this.book.totalPages))
                }
                .padding({ bottom: Spacing.sm })
              }

              if (this.book.description && this.book.description.length > 0) {
                CommonCard({
                  type: CardType.ELEVATED,
                  isDarkMode: this.isDarkMode,
                  cornerRadius: BorderRadius.lg,
                  containerPadding: Spacing.lg
                }) {
                  Column({ space: Spacing.md }) {
                    Text(tr('description'))
                      .fontSize(fontScaleManager.getScaledFontSize(16))
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                      .width('100%')

                    Text(this.book.description)
                      .fontSize(fontScaleManager.getScaledFontSize(14))
                      .fontColor(this.tc('#666666', '#AAAAAA'))
                      .lineHeight(fontScaleManager.getScaledFontSize(22))
                      .width('100%')
                  }
                  .padding({ top: Spacing.md, bottom: Spacing.md })
                }
              }

              CommonButton({
                text: this.book.readProgress > 0 ? tr('continue_reading') : tr('start_reading'),
                type: ButtonType.PRIMARY,
                buttonSize: ButtonSize.LARGE,
                isEnabled: true,
                isDarkMode: this.isDarkMode,
                onButtonClick: (): void => {
                  this.onReadClick();
                }
              })
              .width('90%')
              .margin({ top: Spacing.lg, bottom: Spacing.xxxl })
            }
            .width('100%')
            .padding({ 
              top: Spacing.md, 
              bottom: Spacing.md, 
              left: layoutHelper.getResponsiveSpacing(), 
              right: layoutHelper.getResponsiveSpacing() 
            })
          }
          .layoutWeight(1)
          .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F7')
        } else {
          Column() {
            Text('books_vertical_fill')
              .fontSize(Size.iconXXL * 2)
              .fontColor(this.isDarkMode ? '#333333' : '#DDDDDD')
            Text(tr('no_data'))
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontColor(this.tc('#999999', '#666666'))
              .margin({ top: Spacing.lg })
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
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.isDarkMode ? '#888888' : '#999999')

      Blank()

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#E8E8E8' : '#333333')
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.md })
  }

  private getStatusText(): string {
    if (!this.book) return '';
    switch (this.book.status) {
      case ReadStatus.READING: return tr('reading');
      case ReadStatus.FINISHED: return tr('finished');
      case ReadStatus.UNREAD: return tr('unread');
      default: return tr('unknown');
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

    if (days === 0) return tr('today');
    if (days === 1) return tr('yesterday');
    if (days < 7) return days + tr('days_ago');
    if (days < 30) return Math.floor(days / 7) + tr('weeks_ago');
    return Math.floor(days / 30) + tr('months_ago');
  }

  private shareBook(): void {
    if (!this.book) return;

    const shareText = tr('recommend_book') + this.book.title + '\n' + tr('author_label') + this.book.author + '\n\n' + tr('app_slogan');

    try {
      promptAction.showToast({
        message: shareText,
        duration: 3000
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error(tr('share_failed') + ':', message);
    }
  }
}
