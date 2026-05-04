import { logger } from '../../common/utils/Logger';
/**
 * 在线书籍详情页面
 * 展示书籍详情、目录列表、开始阅)
 * 
 * @since 2.8.0
 */

import { promptAction } from '@kit.ArkUI';
import { navigateTo } from '../../../common/utils/NavigationHelper';
import { common } from '@kit.AbilityKit';

import { OnlineBookDetail, OnlineChapterInfo } from '../core/models/OnlineBookModel';
import { BookInfo, BookFormat, ReadStatus } from '../core/models/BookModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { BackButton } from '../components/common/BackButton';
import { onlineBookService } from '../core/services/book/OnlineBookService';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct OnlineBookDetailPage {
  @State isDarkMode: boolean = false;
  @State bookUrl: string = '';
  @State sourceId: string = '';
  @State bookName: string = '';
  @State bookDetail: OnlineBookDetail | null = null;
  @State toc: OnlineChapterInfo[] = [];
  @State isLoading: boolean = true;
  @State isLoadingToc: boolean = false;
  @State showFullIntro: boolean = false;
  @State currentTab: number = 0; // 0: 详情 1: 目录
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  @State private context: common.Context | null = null;
  @State screenInfo: ScreenInfo | null = null;

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

  build() {
    Column() {
      // 顶部导航)
      this.buildNavBar()

      if (this.isLoading) {
        this.buildLoadingView()
      } else if (this.bookDetail) {
        // Tab切换
        if (this.currentTab === 0) {
          this.buildDetailTab()
        } else {
          this.buildTocTab()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#141414' : '#F5F5F5')
  }

  // ==================== 导航)====================

  @Builder
  buildNavBar() {
    Row() {
      BackButton({ isDarkMode: this.isDarkMode })

      Text(this.bookName || '书籍详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('>')
        .fontSize(24)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .padding(Spacing.sm)
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
  }

  // ==================== 加载视图 ====================

  @Builder
  buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(COMMON_COLORS.PRIMARY_BLUE)

      Text('加载)..')
        .fontSize(15)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 详情Tab ====================

  @Builder
  buildDetailTab() {
    Scroll() {
      Column({ space: 16 }) {
        // 书籍信息卡片
        this.buildBookCard()

        // 简)
        this.buildIntroCard()

        // 操作按钮
        this.buildActionButtons()

        // 目录预览
        if (this.toc.length > 0) {
          this.buildTocPreview()
        }
      }
      .padding(Spacing.lg)
    }
    .layoutWeight(1)
  }

  @Builder
  buildBookCard() {
    Row({ space: 16 }) {
      // 封面
      if (this.bookDetail!.coverUrl) {
        Image(this.bookDetail!.coverUrl)
          .width(120)
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius(BorderRadius.md)
      } else {
        Column() {
          Text('📚')
            .fontSize(48)
        }
        .width(120)
        .height(160)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#E8E8E8')
        .borderRadius(BorderRadius.md)
      }

      // 书籍信息
      Column({ space: 10 }) {
        Text(this.bookDetail!.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.bookDetail!.author)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')

        Row({ space: 8 }) {
          if (this.bookDetail!.wordCount > 0) {
            Text(this.formatWordCount(this.bookDetail!.wordCount))
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
          }

          if (this.bookDetail!.latestChapter) {
            Text('最新：' + this.bookDetail!.latestChapter)
              .fontSize(12)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(BorderRadius.md)
  }

  @Builder
  buildIntroCard() {
    Column() {
      Text('Intro')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      Text(this.bookDetail!.intro || 'No intro')
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
        .lineHeight(22)
        .maxLines(this.showFullIntro ? 1000 : 4)
        .textOverflow({ overflow: this.showFullIntro ? TextOverflow.Clip : TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(BorderRadius.md)
    .onClick(() => this.showFullIntro = !this.showFullIntro)
  }

  @Builder
  buildActionButtons() {
    Row({ space: 12 }) {
      // 加入书架
      Button('加入书架')
        .layoutWeight(1)
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .fontColor('#FFFFFF')
        .borderRadius(BorderRadius.xl)
        .onClick(() => this.addToBookshelf())

      // 查看目录
      Button('查看目录')
        .layoutWeight(1)
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .borderRadius(BorderRadius.xl)
        .onClick(() => this.currentTab = 1)
    }
    .width('100%')
  }

  @Builder
  buildTocPreview() {
    Column() {
      Row() {
        Text('目录预览')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

        Blank()

        Text('查看全部')
          .fontSize(14)
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          .onClick(() => this.currentTab = 1)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column({ space: 0 }) {
        ForEach(this.toc.slice(0, 5), (chapter: OnlineChapterInfo) => {
          Row() {
            Text(chapter.title)
              .fontSize(14)
              .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('...')
              .fontSize(16)
              .fontColor(this.isDarkMode ? '#666666' : '#999999')
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .borderRadius(BorderRadius.sm)
          .onClick(() => this.startReading(chapter))
        }, (chapter: OnlineChapterInfo) => chapter.title + chapter.index)
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(BorderRadius.md)
  }

  // ==================== 目录Tab ====================

  @Builder
  buildTocTab() {
    Column() {
      // 目录统计
      Row() {
        Text(this.toc.length + ' �?)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#888888' : '#666666')
          .padding({ left: 16, top: 12, bottom: 12 })
      }
      .width('100%')

      // 目录列表
      if (this.isLoadingToc) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(COMMON_COLORS.PRIMARY_BLUE)

          Text('加载目录...')
            .fontSize(14)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.toc, (chapter: OnlineChapterInfo, index: number) => {
            ListItem() {
              Row() {
                Text(index + 1 + '')
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#666666' : '#999999')
                  .width(50)

                Text(chapter.title)
                  .fontSize(15)
                  .fontColor(this.isDarkMode ? '#CCCCCC' : '#333333')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (chapter.isVip) {
                  Text('VIP')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('#FF6B6B')
                    .borderRadius(BorderRadius.xs)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .onClick(() => this.startReading(chapter))
            }
          }, (chapter: OnlineChapterInfo, index: number) => chapter.title + index)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  // ==================== 方法 ====================

  private async loadBookDetail(): Promise<void> {
    this.isLoading = true;

    try {
      // 获取书籍详情
      const detail = await onlineBookService.getBookDetail(this.bookUrl, this.sourceId);
      if (detail) {
        this.bookDetail = detail;

        // 获取目录
        this.isLoadingToc = true;
        const toc = await onlineBookService.fetchToc(this.bookUrl, this.sourceId);
        this.toc = toc;
        this.isLoadingToc = false;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[OnlineBookDetail] Load failed:', message);
    } finally {
      this.isLoading = false;
    }
  }

  private addToBookshelf(): void {
    if (!this.bookDetail) return;

    const bookInfo: BookInfo = {
      id: 'online_' + this.sourceId + '_' + Date.now(),
      title: this.bookDetail.title,
      author: this.bookDetail.author,
      filePath: '',
      coverPath: this.bookDetail.coverUrl || '',
      format: BookFormat.TXT,
      totalPages: this.toc.length,
      currentPage: 0,
      readProgress: 0,
      lastReadTime: 0,
      addTime: Date.now(),
      status: ReadStatus.READING,
      isFavorite: true,
      groupIds: [],
      totalReadTime: 0,
      fileSize: 0,
      description: this.bookDetail.intro
    };

    bookViewModel.addBook(bookInfo);

    promptAction.showToast({
      message: '已加入书�?,
      duration: 2000
    });
  }

  private startReading(chapter?: OnlineChapterInfo): void {
    if (!this.bookDetail) return;

    const bookInfo: BookInfo = {
      id: 'online_' + this.sourceId + '_' + Date.now(),
      title: this.bookDetail.title,
      author: this.bookDetail.author,
      filePath: this.bookUrl,
      coverPath: this.bookDetail.coverUrl || '',
      format: BookFormat.TXT,
      totalPages: this.toc.length,
      currentPage: chapter ? chapter.index : 0,
      readProgress: 0,
      lastReadTime: Date.now(),
      addTime: Date.now(),
      status: ReadStatus.READING,
      isFavorite: false,
      groupIds: [],
      totalReadTime: 0,
      fileSize: 0,
      description: this.bookDetail.intro
    };

    // 跳转到阅读器
    const navParams: Record<string, string> = {};
    navParams['bookId'] = bookInfo.id;
    navParams['chapterIndex'] = String(chapter ? chapter.index : 0);
    navigateTo('pages/EnhancedReaderPage', navParams);
  }

  private formatWordCount(count: number): string {
    if (count >= 10000) {
      return (count / 10000).toFixed(1) + '万字';
    }
    return count + '�?;
  }
}

// 预览组件 - 用于DevEco Studio预览�?
@Preview
@Component
struct OnlineBookDetailPagePreview {
  build() {
    Column() {
      Text('在线书籍详情�?- 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      OnlineBookDetailPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('在线书籍详情�?- 深色模式')
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


