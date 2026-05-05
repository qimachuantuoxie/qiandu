import { logger } from '../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { promptAction } from '@kit.ArkUI';
import { BookInfo, ReadStatus, BookshelfGroup } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { DeviceUtils } from '../../../core/utils/DeviceUtils';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { dynamicCoverService, BookCoverData } from '../../../core/services/image/DynamicCoverService';
import { tr } from '../../../core/utils/LocalizationUtil';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { common } from '@kit.AbilityKit';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { EbookParserUtils } from '../../../core/parsers/EbookParserUtils';

interface BookDetailParams {
  bookId: string;
}

@Entry
@ComponentV2
struct BookDetailPage {
  @Local book: BookInfo | null = null;
  @Local isFavorite: boolean = false;
  @Local isTablet: boolean = false;
  @Local isDarkMode: boolean = false;
  @Local coverData: BookCoverData | null = null;
  @Local showMoreMenu: boolean = false;
  @Local groups: BookshelfGroup[] = [];
  @Local bookGroups: string[] = [];
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;

  private unsubscribe: (() => void) | null = null;
  private context: common.Context | null = null;

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
    this.unsubscribe = bookViewModel.subscribe((): void => {
      this.loadBookData();
    });
  }

  aboutToDisappear() {
    if (this.unsubscribe) {
      this.unsubscribe();
    }
  }

  private loadGroups(): void {
    this.groups = bookViewModel.getAllGroups();
  }

  private loadBookData(): void {
    const paramsObj = this.getUIContext().getRouter()?.getParams();
    if (paramsObj) {
      const params = paramsObj as BookDetailParams;
      if (params.bookId) {
        const allBooks = bookViewModel.getAllBooks();
        for (let i = 0; i < allBooks.length; i++) {
          if (allBooks[i].id === params.bookId) {
            this.book = allBooks[i];
            this.isFavorite = allBooks[i].isFavorite;
            this.bookGroups = allBooks[i].groupIds || [];
            this.coverData = dynamicCoverService.generateCoverData(
              allBooks[i].title,
              allBooks[i].author,
              allBooks[i].id
            );
            break;
          }
        }
      }
    }
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

  build() {
    Column() {
      // 顶部导航栏
      PageHeader({
        title: '书籍详情',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (e) {
            logger.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
          }
        }
      })
      
      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          if (this.book) {
            // 封面和基本信息
            this.BookHeader()

            // 阅读进度卡片
            this.ProgressCard()

            // 书籍信息卡片
            this.BookInfoCard()

            // 操作按钮
            this.ActionButtons()

            // 分组管理
            if (this.groups.length > 0) {
              this.GroupManagement()
            }
          } else {
            // 空状态
            EmptyState({
              title: '书籍不存在',
              icon: $r('sys.symbol.book.closed'),
              actionText: '返回',
              onAction: () => {
                try {
                  goBack();
                } catch (e) {
                  logger.error('BookDetailPage back failed:', e instanceof Error ? e.message : String(e));
                }
              }
            })
          }
        }
        .width('100%')
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg, 
          top: HDSSpacing.md,
          bottom: HDSSpacing.xxxl
        })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  BookHeader() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.xl }) {
          // 封面图
          Stack() {
            if (this.coverData) {
              // 渐变背景封面
              Column()
                .width(this.isTablet ? 180 : 150)
                .height(this.isTablet ? 240 : 200)
                .linearGradient({
                  direction: GradientDirection.Top,
                  colors: [
                    this.coverData.primaryColor,
                    this.coverData.secondaryColor
                  ]
                })
                .borderRadius(HDSBorderRadius.xl)

              // 书名和作者
              Column({ space: HDSSpacing.sm }) {
                Text(this.book!.title)
                  .fontSize(this.isTablet ? HDSTypography.sizes.xxl : HDSTypography.sizes.xl)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(HDSColours.neutral.white)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Center)

                Text(this.book!.author)
                  .fontSize(HDSTypography.sizes.md)
                  .fontColor('rgba(255,255,255,0.9)')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(HDSPacing.lg)
              .position({ bottom: 0 })
              .linearGradient({
                direction: GradientDirection.Top,
                colors: ['rgba(0,0,0,0)', 'rgba(0,0,0,0.6)']
              })
              .borderRadius(HDSBorderRadius.xl)
            } else {
              // 默认封面
              Column() {
                SymbolGlyph($r('sys.symbol.book.fill'))
                  .fontSize(40)
                  .fontColor([HDSColours.primary.blue])
              }
              .width(this.isTablet ? 180 : 150)
              .height(this.isTablet ? 240 : 200)
              .borderRadius(HDSBorderRadius.xl)
              .backgroundColor(HDSColours.primary.blue + '15')
              .justifyContent(FlexAlign.Center)
            }

            // 收藏按钮
            Row() {
              SymbolGlyph($r(this.isFavorite ? 'sys.symbol.heart.fill' : 'sys.symbol.heart'))
                .fontSize(24)
                .fontColor([this.isFavorite ? '#FF4757' : HDSColours.neutral.white])
            }
            .width(40)
            .height(40)
            .borderRadius(HDSBorderRadius.full)
            .backgroundColor('rgba(0,0,0,0.5)')
            .justifyContent(FlexAlign.Center)
            .position({ top: 10, right: 10 })
            .onClick(() => this.onToggleFavorite())
          }
          .width('100%')
          .height(this.isTablet ? 260 : 220)
          .justifyContent(FlexAlign.Center)

          // 阅读状态标签
          if (this.book!.readStatus !== undefined) {
            Row({ space: HDSSpacing.sm }) {
              SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
                .fontSize(16)
                .fontColor([this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A' : HDSColours.primary.blue])
              
              Text(this.book!.readStatus === ReadStatus.FINISHED ? '已读完' : '阅读中')
                .fontSize(HDSTypography.sizes.sm)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A' : HDSColours.primary.blue)
            }
            .padding({ 
              left: HDSSpacing.md, 
              right: HDSSpacing.md, 
              top: HDSSpacing.sm, 
              bottom: HDSSpacing.sm 
            })
            .backgroundColor(this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A15' : HDSColours.primary.blue + '15')
            .borderRadius(HDSBorderRadius.xl)
          }
        }
      }
    })
  }

  @Builder
  ProgressCard() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chart.bar.xaxis'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
        
        Text('阅读进度')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        Text(`${this.book!.progress || 0}%`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.primary)
      }
      .width('100%')

      Progress({ 
        value: this.book!.progress || 0, 
        total: 100, 
        type: ProgressType.Linear 
      })
        .width('100%')
        .height(8)
        .borderRadius(HDSBorderRadius.xl)
        .color(HDSColours.primary.blue)
        .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.border : HDSColours.neutral.gray200)
  
      Row() {
        Text(`上次阅读：第${this.book!.lastReadChapter || 1}章`)
          .fontSize(HDSTypography.sizes.sm)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        
        Blank()
  
        Text(this.book!.lastReadTime ? new Date(this.book!.lastReadTime).toLocaleDateString() : '未开始')
          .fontSize(HDSTypography.sizes.sm)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
      }
      .width('100%')
    }
    .width('100%')
    .padding(HDSPacing.xl)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
  }

  @Builder
  BookInfoCard() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Row() {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(20)
              .fontColor([HDSColours.primary.blue])
            
            Text('书籍信息')
              .fontSize(HDSTypography.sizes.xl)
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .layoutWeight(1)
              .margin({ left: HDSSpacing.sm })
          }
          .width('100%')

          Column({ space: HDSSpacing.md }) {
            this.InfoRow('作者', this.book!.author)
            this.InfoRow('格式', this.book!.format || '未知')
            this.InfoRow('大小', this.formatFileSize(this.book!.fileSize || 0))
            this.InfoRow('添加时间', new Date(this.book!.addTime || Date.now()).toLocaleDateString())
          }
          .width('100%')
        }
      }
    })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(HDSTypography.sizes.md)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        .width(80)

      Text(value)
        .fontSize(HDSTypography.sizes.md)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  ActionButtons() {
    Row({ space: HDSSpacing.md }) {
      // 开始阅读按钮
      Button() {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.book.open'))
            .fontSize(20)
            .fontColor([HDSColours.neutral.white])
          
          Text('开始阅读')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(HDSColours.neutral.white)
        }
      }
      .layoutWeight(2)
      .height(56)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
      })
      .borderRadius(HDSBorderRadius.xl)
      .shadow({
        radius: 8,
        color: HDSColours.primary.blue + '40',
        offsetY: 4
      })
      .onClick(() => this.onReadClick())

      // 更多操作按钮
      Button() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(20)
          .fontColor([HDSColours.neutral.white])
      }
      .layoutWeight(1)
      .height(56)
      .backgroundColor('#FF4D4F')
      .borderRadius(HDSBorderRadius.xl)
      .onClick(() => this.onDeleteClick())
    }
    .width('100%')
  }

  @Builder
  GroupManagement() {
    HDSCard({
      padding: HDSSpacing.xl,
      content: () => {
        Column({ space: HDSSpacing.md }) {
          Row() {
            SymbolGlyph($r('sys.symbol.folder'))
              .fontSize(20)
              .fontColor([HDSColours.primary.blue])
            
            Text('分组管理')
              .fontSize(HDSTypography.sizes.xl)
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .layoutWeight(1)
              .margin({ left: HDSSpacing.sm })
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.groups, (group: BookshelfGroup) => {
              Row({ space: HDSSpacing.xs }) {
                SymbolGlyph($r(this.isInGroup(group.id) ? 'sys.symbol.checkmark.circle.fill' : 'sys.symbol.circle'))
                  .fontSize(12)
                  .fontColor([this.isInGroup(group.id) ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)])
                
                Text(group.name)
                  .fontSize(HDSTypography.sizes.sm)
                  .fontColor(this.isInGroup(group.id) ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900))
              }
              .padding({ 
                left: HDSSpacing.md, 
                right: HDSSpacing.md, 
                top: HDSSpacing.sm, 
                bottom: HDSSpacing.sm 
              })
              .backgroundColor(this.isInGroup(group.id) ? HDSColours.primary.blue + '15' : (this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.gray100))
              .borderRadius(HDSBorderRadius.xl)
              .border({ 
                width: 1, 
                color: this.isInGroup(group.id) ? HDSColours.primary.blue : Color.Transparent 
              })
              .onClick(() => {
                if (this.book) {
                  const index = this.bookGroups.indexOf(group.id);
                  let newGroups: string[] = [];
                  if (index > -1) {
                    newGroups = this.bookGroups.slice();
                    newGroups.splice(index, 1);
                  } else {
                    newGroups = this.bookGroups.slice();
                    newGroups.push(group.id);
                  }
                  this.bookGroups = newGroups;
                  this.book.groupIds = this.bookGroups;
                  bookViewModel.updateBook(this.book);
                }
              })
              .margin({ right: HDSSpacing.sm, bottom: HDSSpacing.sm })
            }, (group: BookshelfGroup) => group.id)
          }
          .width('100%')
        }
      }
    })
  }
}

// 预览组件
@Preview
@ComponentV2
struct BookDetailPagePreview {
  build() {
    Column() {
      Text('书籍详情 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      BookDetailPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('书籍详情 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      BookDetailPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
