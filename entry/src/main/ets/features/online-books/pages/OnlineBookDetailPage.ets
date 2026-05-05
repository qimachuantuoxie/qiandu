import { logger } from '../../common/utils/Logger';
import { promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { OnlineBookDetail, OnlineChapterInfo } from '../../../core/models/OnlineBookModel';
import { BookInfo, BookFormat, ReadStatus } from '../../../core/models/BookModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { onlineBookService } from '../../../core/services/book/OnlineBookService';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct OnlineBookDetailPage {
  @Local isDarkMode: boolean = false;
  @Local bookUrl: string = '';
  @Local sourceId: string = '';
  @Local bookName: string = '';
  @Local bookDetail: OnlineBookDetail | null = null;
  @Local toc: OnlineChapterInfo[] = [];
  @Local isLoading: boolean = true;
  @Local isLoadingToc: boolean = false;
  @Local showFullIntro: boolean = false;
  @Local currentTab: number = 0;
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;
  private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
    this.loadBookDetail();
  }

  private async initData(): Promise<void> {
    if (!this.context) return;
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();

    const params = this.getUIContext().getRouter()?.getParams() as Record<string, string>;
    this.bookUrl = params['bookUrl'] || '';
    this.sourceId = params['sourceId'] || '';
    this.bookName = params['bookName'] || '';
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private async loadBookDetail(): Promise<void> {
    this.isLoading = true;
    try {
      const detail = await onlineBookService.getBookDetail(this.bookUrl, this.sourceId);
      this.bookDetail = detail;
      
      // 加载目录
      this.isLoadingToc = true;
      const chapters = await onlineBookService.getChapterList(this.bookUrl, this.sourceId);
      this.toc = chapters;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[OnlineBookDetail] Load failed:', message);
    } finally {
      this.isLoading = false;
      this.isLoadingToc = false;
    }
  }

  private formatWordCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万字`;
    }
    return `${count}字`;
  }

  build() {
    Column() {
      // 顶部导航栏
      this.NavBar()

      if (this.isLoading) {
        this.LoadingView()
      } else if (this.bookDetail) {
        // Tab切换
        this.TabBar()
        
        if (this.currentTab === 0) {
          this.DetailTab()
        } else {
          this.TocTab()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  NavBar() {
    Row() {
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
        try { goBack(); } 
        catch (e) { logger.error('[OnlineBookDetail] back failed', e); }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Text(this.bookName || '书籍详情')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()
        .width(Size.buttonMD)
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  LoadingView() {
    Column({ space: Spacing.lg }) {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(COMMON_COLORS.PRIMARY_BLUE)

      Text('加载中...')
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TabBar() {
    Row() {
      Text('详情')
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === 0 ? this.currentColors.primary : this.tc('#8E8E93', '#8E8E93'))
        .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.md })
        .onClick(() => { this.currentTab = 0; })
      
      Text(`目录 (${this.toc.length})`)
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === 1 ? this.currentColors.primary : this.tc('#8E8E93', '#8E8E93'))
        .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.md, bottom: Spacing.md })
        .onClick(() => { this.currentTab = 1; })
    }
    .width('100%')
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  DetailTab() {
    Scroll() {
      Column({ space: Spacing.lg }) {
        // 书籍信息卡片
        this.BookCard()

        // 简介
        this.IntroCard()

        // 操作按钮
        this.ActionButtons()

        // 目录预览
        if (this.toc.length > 0) {
          this.TocPreview()
        }
      }
      .width('100%')
      .padding(Spacing.lg)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  BookCard() {
    Row({ space: Spacing.lg }) {
      // 封面
      if (this.bookDetail!.coverUrl) {
        Image(this.bookDetail!.coverUrl)
          .width(this.screenInfo?.isTablet ? 140 : 120)
          .height(this.screenInfo?.isTablet ? 185 : 160)
          .objectFit(ImageFit.Cover)
          .borderRadius(BorderRadius.lg)
          .shadow(getShadow('md', this.isDarkMode))
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.book.fill'))
            .fontSize(Size.iconXXXL)
            .fontColor([this.currentColors.primary])
        }
        .width(this.screenInfo?.isTablet ? 140 : 120)
        .height(this.screenInfo?.isTablet ? 185 : 160)
        .borderRadius(BorderRadius.lg)
        .backgroundColor(this.currentColors.primary + '15')
        .justifyContent(FlexAlign.Center)
      }

      // 书籍信息
      Column({ space: Spacing.md }) {
        Text(this.bookDetail!.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.screenInfo?.isTablet ? 20 : 18))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.bookDetail!.author)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))

        Column({ space: Spacing.sm }) {
          if (this.bookDetail!.wordCount > 0) {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.doc.text'))
                .fontSize(Size.iconXS)
                .fontColor([this.tc('#8E8E93', '#8E8E93')])
              
              Text(this.formatWordCount(this.bookDetail!.wordCount))
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(this.tc('#8E8E93', '#8E8E93'))
            }
          }

          if (this.bookDetail!.latestChapter) {
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.book.open'))
                .fontSize(Size.iconXS)
                .fontColor([COMMON_COLORS.PRIMARY_BLUE])
              
              Text('最新：' + this.bookDetail!.latestChapter)
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }

  @Builder
  IntroCard() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
        
        Text('简介')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        Text(this.showFullIntro ? '收起' : '展开')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => {
            this.showFullIntro = !this.showFullIntro;
          })
      }
      .width('100%')

      Text(this.bookDetail!.intro || '暂无简介')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .lineHeight(1.6)
        .maxLines(this.showFullIntro ? undefined : 4)
        .textOverflow({ overflow: this.showFullIntro ? TextOverflow.Clip : TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  ActionButtons() {
    Row({ space: Spacing.md }) {
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
      .layoutWeight(1)
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
      .onClick(() => {
        if (this.toc.length > 0) {
          const params: Record<string, Object> = {};
          params['bookUrl'] = this.bookUrl;
          params['sourceId'] = this.sourceId;
          params['chapterIndex'] = 0;
          navigateTo('pages/EnhancedReaderPage', params);
        }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Button() {
        SymbolGlyph($r('sys.symbol.download.circle'))
          .fontSize(Size.iconMD)
          .fontColor(['#FFFFFF'])
      }
      .width(Size.buttonLG)
      .height(Size.buttonLG)
      .backgroundColor('#FF9800')
      .borderRadius(BorderRadius.xl)
      .onClick(() => {
        promptAction.showToast({ message: '下载功能开发中...' });
      })
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
  }

  @Builder
  TocPreview() {
    Column({ space: Spacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.list.bullet'))
          .fontSize(Size.iconMD)
          .fontColor([this.currentColors.primary])
        
        Text('章节目录')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        Text(`查看全部 ${this.toc.length} 章`)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => {
            this.currentTab = 1;
          })
      }
      .width('100%')

      List({ space: Spacing.sm }) {
        ForEach(this.toc.slice(0, 5), (chapter: OnlineChapterInfo, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}. ${chapter.title}`)
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding(Spacing.md)
            .backgroundColor(this.tc('#F8F9FA', '#2C2C2E'))
            .borderRadius(BorderRadius.md)
          }
        }, (chapter: OnlineChapterInfo, index: number) => chapter.url + index)
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  TocTab() {
    if (this.isLoadingToc) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(COMMON_COLORS.PRIMARY_BLUE)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.toc.length === 0) {
      Column({ space: Spacing.xl }) {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(Size.iconXXXL)
          .fontColor([this.tc('#D1D1D6', '#48484A')])

        Text('暂无章节')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: Spacing.sm }) {
        ForEach(this.toc, (chapter: OnlineChapterInfo, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}.`)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor(this.tc('#8E8E93', '#8E8E93'))
                .width(40)

              Text(chapter.title)
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              SymbolGlyph($r('sys.symbol.chevron.right'))
                .fontSize(Size.iconSM)
                .fontColor([this.tc('#C7C7CC', '#48484A')])
            }
            .width('100%')
            .padding(Spacing.md)
            .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
            .borderRadius(BorderRadius.md)
            .onClick(() => {
              const params: Record<string, Object> = {};
              params['bookUrl'] = this.bookUrl;
              params['sourceId'] = this.sourceId;
              params['chapterIndex'] = index;
              navigateTo('pages/EnhancedReaderPage', params);
            })
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
        }, (chapter: OnlineChapterInfo, index: number) => chapter.url + index)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(Spacing.lg)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
  }
}

// 预览组件
@Preview
@ComponentV2
struct OnlineBookDetailPagePreview {
  build() {
    Column() {
      Text('在线书籍详情 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      OnlineBookDetailPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('在线书籍详情 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      OnlineBookDetailPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
