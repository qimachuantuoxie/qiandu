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
      PageHeader({
        title: this.bookName || '书籍详情',
        showBack: true,
        onBack: () => {
          try { goBack(); } 
          catch (e) { logger.error('[OnlineBookDetail] back failed', e); }
        }
      })

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
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  LoadingView() {
    Column({ space: HDSSpacing.lg }) {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(HDSColours.primary.blue)

      Text('加载中...')
        .fontSize(HDSTypography.sizes.md)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TabBar() {
    Row() {
      Text('详情')
        .fontSize(HDSTypography.sizes.md)
        .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === 0 ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
        .padding({ left: HDSSpacing.xl, right: HDSSpacing.xl, top: HDSSpacing.md, bottom: HDSSpacing.md })
        .onClick(() => { this.currentTab = 0; })
      
      Text(`目录 (${this.toc.length})`)
        .fontSize(HDSTypography.sizes.md)
        .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === 1 ? HDSColours.primary.blue : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
        .padding({ left: HDSSpacing.xl, right: HDSSpacing.xl, top: HDSSpacing.md, bottom: HDSSpacing.md })
        .onClick(() => { this.currentTab = 1; })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.white)
  }

  @Builder
  DetailTab() {
    Scroll() {
      Column({ space: HDSSpacing.lg }) {
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
      .padding(HDSPacing.lg)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  BookCard() {
    Row({ space: HDSSpacing.lg }) {
      // 封面
      if (this.bookDetail!.coverUrl) {
        Image(this.bookDetail!.coverUrl)
          .width(this.screenInfo?.isTablet ? 140 : 120)
          .height(this.screenInfo?.isTablet ? 185 : 160)
          .objectFit(ImageFit.Cover)
          .borderRadius(HDSBorderRadius.lg)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.book.fill'))
            .fontSize(28)
            .fontColor([HDSColours.primary.blue])
        }
        .width(this.screenInfo?.isTablet ? 140 : 120)
        .height(this.screenInfo?.isTablet ? 185 : 160)
        .borderRadius(HDSBorderRadius.lg)
        .backgroundColor(HDSColours.primary.blue + '15')
        .justifyContent(FlexAlign.Center)
      }

      // 书籍信息
      Column({ space: HDSSpacing.md }) {
        Text(this.bookDetail!.title)
          .fontSize(fontScaleManager.getScaledFontSize(this.screenInfo?.isTablet ? 20 : 18))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.bookDetail!.author)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)

        Column({ space: HDSSpacing.sm }) {
          if (this.bookDetail!.wordCount > 0) {
            Row({ space: HDSSpacing.xs }) {
              SymbolGlyph($r('sys.symbol.doc.text'))
                .fontSize(12)
                .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
              
              Text(this.formatWordCount(this.bookDetail!.wordCount))
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
            }
          }

          if (this.bookDetail!.latestChapter) {
            Row({ space: HDSSpacing.xs }) {
              SymbolGlyph($r('sys.symbol.book.open'))
                .fontSize(12)
                .fontColor([HDSColours.primary.blue])
              
              Text('最新：' + this.bookDetail!.latestChapter)
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(HDSColours.primary.blue)
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
    .padding(HDSPacing.xl)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
  }

  @Builder
  IntroCard() {
    Column({ space: HDSSpacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(20)
          .fontColor([HDSColours.primary.blue])
        
        Text('简介')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .layoutWeight(1)
          .margin({ left: HDSSpacing.sm })

        Text(this.showFullIntro ? '收起' : '展开')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(HDSColours.primary.blue)
          .onClick(() => {
            this.showFullIntro = !this.showFullIntro;
          })
      }
      .width('100%')

      Text(this.bookDetail!.intro || '暂无简介')
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .lineHeight(1.6)
        .maxLines(this.showFullIntro ? undefined : 4)
        .textOverflow({ overflow: this.showFullIntro ? TextOverflow.Clip : TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(HDSPacing.xl)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
  }

  @Builder
  ActionButtons() {
    Row({ space: HDSSpacing.md }) {
      Button() {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.book.open'))
            .fontSize(20)
            .fontColor([HDSColours.neutral.white])
          
          Text('开始阅读')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(HDSColours.neutral.white)
        }
      }
      .layoutWeight(1)
      .height(48 + HDSSpacing.sm)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
      })
      .borderRadius(HDSBorderRadius.xl)
      .onClick(() => {
        if (this.toc.length > 0) {
          const params: Record<string, Object> = {};
          params['bookUrl'] = this.bookUrl;
          params['sourceId'] = this.sourceId;
          params['chapterIndex'] = 0;
          navigateTo('pages/EnhancedReaderPage', params);
        }
      })

      Button() {
        SymbolGlyph($r('sys.symbol.download.circle'))
          .fontSize(20)
          .fontColor([HDSColours.neutral.white])
      }
      .width(48)
      .height(48)
      .backgroundColor('#FF9800')
      .borderRadius(HDSBorderRadius.xl)
      .onClick(() => {
        promptAction.showToast({ message: '下载功能开发中...' });
      })
    }
    .width('100%')
  }

  @Builder
  TocPreview() {
    Column({ space: HDSSpacing.md }) {
      Row() {
        SymbolGlyph($r('sys.symbol.list.bullet'))
          .fontSize(20)
          .fontColor([HDSColours.primary.blue])
        
        Text('章节目录')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .layoutWeight(1)
          .margin({ left: HDSSpacing.sm })

        Text(`查看全部 ${this.toc.length} 章`)
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(HDSColours.primary.blue)
          .onClick(() => {
            this.currentTab = 1;
          })
      }
      .width('100%')

      List({ space: HDSSpacing.sm }) {
        ForEach(this.toc.slice(0, 5), (chapter: OnlineChapterInfo, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}. ${chapter.title}`)
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
            .padding(HDSPacing.md)
            .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : '#F8F9FA')
            .borderRadius(HDSBorderRadius.md)
          }
        }, (chapter: OnlineChapterInfo, index: number) => chapter.url + index)
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding(HDSPacing.xl)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
  }

  @Builder
  TocTab() {
    if (this.isLoadingToc) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(HDSColours.primary.blue)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.toc.length === 0) {
      Column({ space: HDSSpacing.xl }) {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(28)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray400])

        Text('暂无章节')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: HDSSpacing.sm }) {
        ForEach(this.toc, (chapter: OnlineChapterInfo, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}.`)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                .width(40)

              Text(chapter.title)
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              SymbolGlyph($r('sys.symbol.chevron.right'))
                .fontSize(16)
                .fontColor([this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray400])
            }
            .width('100%')
            .padding(HDSPacing.md)
            .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
            .borderRadius(HDSBorderRadius.md)
            .onClick(() => {
              const params: Record<string, Object> = {};
              params['bookUrl'] = this.bookUrl;
              params['sourceId'] = this.sourceId;
              params['chapterIndex'] = index;
              navigateTo('pages/EnhancedReaderPage', params);
            })
          }
        }, (chapter: OnlineChapterInfo, index: number) => chapter.url + index)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(HDSPacing.lg)
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
