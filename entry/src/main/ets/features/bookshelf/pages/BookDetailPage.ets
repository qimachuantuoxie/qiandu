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
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';
import { ThemeTokens } from '../../common/utils/ThemeTokens';

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

  build() {
    Scroll() {
      Column({ space: Spacing.lg }) {
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
          Column({ space: Spacing.xl }) {
            SymbolGlyph($r('sys.symbol.book.closed'))
              .fontSize(Size.iconXXXL * 1.5)
              .fontColor([ThemeTokens.textDisabled()])
            
            Text('书籍不存在')
              .fontSize(fontScaleManager.getScaledFontSize(16))
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeTokens.textPrimary())
          }
          .width('100%')
          .padding(Spacing.xxxl)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding({ 
        left: Spacing.lg, 
        right: Spacing.lg, 
        top: Spacing.lg,
        bottom: Spacing.xxxl
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.bgPrimary())
  }

  @Builder
  BookHeader() {
    Column({ space: Spacing.xl }) {
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
            .borderRadius(BorderRadius.xl)
            .shadow(getShadow('xl', this.isDarkMode))

          // 书名和作者
          Column({ space: Spacing.sm }) {
            Text(this.book!.title)
              .fontSize(fontScaleManager.getScaledFontSize(this.isTablet ? 20 : 18))
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)

            Text(this.book!.author)
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .fontColor('rgba(255,255,255,0.9)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding(Spacing.lg)
          .position({ bottom: 0 })
          .linearGradient({
            direction: GradientDirection.Top,
            colors: ['rgba(0,0,0,0)', 'rgba(0,0,0,0.6)']
          })
          .borderRadius(BorderRadius.xl)
        } else {
          // 默认封面
          Column() {
            SymbolGlyph($r('sys.symbol.book.fill'))
              .fontSize(Size.iconXXXL)
              .fontColor([this.currentColors.primary])
          }
          .width(this.isTablet ? 180 : 150)
          .height(this.isTablet ? 240 : 200)
          .borderRadius(BorderRadius.xl)
          .backgroundColor(this.currentColors.primary + '15')
          .justifyContent(FlexAlign.Center)
        }

        // 收藏按钮
        Row() {
          SymbolGlyph($r(this.isFavorite ? 'sys.symbol.heart.fill' : 'sys.symbol.heart'))
            .fontSize(Size.iconLG)
            .fontColor([this.isFavorite ? '#FF4757' : '#FFFFFF'])
        }
        .width(Size.buttonLG)
        .height(Size.buttonLG)
        .borderRadius(BorderRadius.full)
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
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
            .fontSize(Size.iconSM)
            .fontColor([this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A' : COMMON_COLORS.PRIMARY_BLUE])
          
          Text(this.book!.readStatus === ReadStatus.FINISHED ? '已读完' : '阅读中')
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A' : COMMON_COLORS.PRIMARY_BLUE)
        }
        .padding({ 
          left: Spacing.md, 
          right: Spacing.md, 
          top: Spacing.sm, 
          bottom: Spacing.sm 
        })
        .backgroundColor(this.book!.readStatus === ReadStatus.FINISHED ? '#52C41A15' : COMMON_COLORS.PRIMARY_BLUE + '15')
        .borderRadius(BorderRadius.xl)
      }
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
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
        .borderRadius(BorderRadius.xl)
        .color(this.currentColors.primary)
        .backgroundColor(ThemeTokens.borderLight())

      Row() {
        Text(`上次阅读：第${this.book!.lastReadChapter || 1}章`)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(ThemeTokens.textSecondary())
        
        Blank()

        Text(this.book!.lastReadTime ? new Date(this.book!.lastReadTime).toLocaleDateString() : '未开始')
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(ThemeTokens.textSecondary())
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  BookInfoCard() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.info.circle'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
        
        Text('书籍信息')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      Column({ space: Spacing.md }) {
        this.InfoRow('作者', this.book!.author)
        this.InfoRow('格式', this.book!.format || '未知')
        this.InfoRow('大小', this.formatFileSize(this.book!.fileSize || 0))
        this.InfoRow('添加时间', new Date(this.book!.addTime || Date.now()).toLocaleDateString())
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(ThemeTokens.textSecondary())
        .width(80)

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(ThemeTokens.textPrimary())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  ActionButtons() {
    Row({ space: Spacing.md }) {
      // 开始阅读按钮
      Button() {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.book.open'))
            .fontSize(Size.iconMD)
            .fontColor(['#FFFFFF'])
          
          Text('开始阅读')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor('#FFFFFF')
        }
      }
      .layoutWeight(2)
      .height(Size.buttonLG + Spacing.sm)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
      })
      .borderRadius(BorderRadius.xl)
      .shadow({
        radius: 8,
        color: COMMON_COLORS.PRIMARY_BLUE + '40',
        offsetY: 4
      })
      .onClick(() => this.onReadClick())
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      // 更多操作按钮
      Button() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(Size.iconMD)
          .fontColor(['#FFFFFF'])
      }
      .layoutWeight(1)
      .height(Size.buttonLG + Spacing.sm)
      .backgroundColor('#FF4D4F')
      .borderRadius(BorderRadius.xl)
      .onClick(() => this.onDeleteClick())
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
  }

  @Builder
  GroupManagement() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
        
        Text('分组管理')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.groups, (group: BookshelfGroup) => {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r(this.isInGroup(group.id) ? 'sys.symbol.checkmark.circle.fill' : 'sys.symbol.circle'))
              .fontSize(Size.iconXS)
              .fontColor([this.isInGroup(group.id) ? this.currentColors.primary : ThemeTokens.textSecondary()])
            
            Text(group.name)
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.isInGroup(group.id) ? this.currentColors.primary : ThemeTokens.textPrimary())
          }
          .padding({ 
            left: Spacing.md, 
            right: Spacing.md, 
            top: Spacing.sm, 
            bottom: Spacing.sm 
          })
          .backgroundColor(this.isInGroup(group.id) ? this.currentColors.primary + '15' : ThemeTokens.bgTertiary())
          .borderRadius(BorderRadius.xl)
          .border({ 
            width: 1, 
            color: this.isInGroup(group.id) ? this.currentColors.primary : 'transparent' 
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
          .margin({ right: Spacing.sm, bottom: Spacing.sm })
        }, (group: BookshelfGroup) => group.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(ThemeTokens.bgSecondary())
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
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
