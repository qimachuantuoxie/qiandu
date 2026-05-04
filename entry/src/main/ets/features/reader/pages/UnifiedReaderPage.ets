import { logger } from '../../common/utils/Logger';
import { BookInfo, BookFormat } from '../../../core/models/CoreBookModel';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { EnhancedReaderPage } from './EnhancedReaderPage';
import { ComicReaderPage } from './ComicReaderPage';

interface ReaderParams {
  bookId?: string;
  bookPath?: string;
  chapterIndex?: string;
}

/**
 * 统一阅读器入口页面
 * 根据书籍格式自动路由到对应的阅读器
 * 
 * - 文本类书籍（EPUB/PDF/TXT等）→ EnhancedReaderPage
 * - 漫画类书籍（CBZ/CBR）→ ComicReaderPage
 * 
 * @since 3.0.0
 */
@Entry
@ComponentV2
struct UnifiedReaderPage {
  @Local readerType: 'text' | 'comic' = 'text';
  @Local bookId: string = '';
  @Local bookPath: string = '';
  @Local chapterIndex: number = 0;
  @Local isLoading: boolean = true;
  @Local bookInfo: BookInfo | null = null;

  aboutToAppear() {
    this.initReader();
  }

  private initReader(): void {
    try {
      const params = this.getUIContext().getRouter()?.getParams() as ReaderParams;
      
      if (params) {
        this.bookId = params.bookId || '';
        this.bookPath = params.bookPath || '';
        this.chapterIndex = params.chapterIndex ? parseInt(params.chapterIndex) : 0;
        
        // 根据书籍信息判断阅读器类型
        if (this.bookId) {
          this.bookInfo = bookViewModel.getBookById(this.bookId);
          if (this.bookInfo) {
            this.readerType = this.isComicFormat(this.bookInfo.format) ? 'comic' : 'text';
            logger.info('[UnifiedReader] Book format:', this.bookInfo.format, '→ Reader type:', this.readerType);
          } else {
            // 如果找不到书籍信息，默认使用文本阅读器
            this.readerType = 'text';
            logger.warn('[UnifiedReader] Book not found, using text reader');
          }
        } else if (this.bookPath) {
          // 根据文件路径判断格式
          const format = this.getFormatFromPath(this.bookPath);
          this.readerType = this.isComicFormat(format) ? 'comic' : 'text';
          logger.info('[UnifiedReader] File format:', format, '→ Reader type:', this.readerType);
        }
      }
      
      this.isLoading = false;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[UnifiedReader] Init failed:', message);
      this.isLoading = false;
      // 出错时使用文本阅读器
      this.readerType = 'text';
    }
  }

  /**
   * 判断是否为漫画格式
   */
  private isComicFormat(format?: string): boolean {
    if (!format) return false;
    const lowerFormat = format.toLowerCase();
    return ['cbz', 'cbr'].includes(lowerFormat);
  }

  /**
   * 从文件路径提取格式
   */
  private getFormatFromPath(path: string): string {
    const ext = path.toLowerCase().split('.').pop();
    return ext || '';
  }

  build() {
    if (this.isLoading) {
      // 加载状态
      Column() {
        LoadingProgress()
          .width(50)
          .height(50)
        
        Text('加载阅读器...')
          .fontSize(14)
          .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      // 根据类型渲染对应阅读器
      if (this.readerType === 'comic') {
        ComicReaderPage({
          bookId: this.bookId,
          bookPath: this.bookPath
        })
      } else {
        EnhancedReaderPage({
          bookId: this.bookId,
          bookPath: this.bookPath,
          chapterIndex: this.chapterIndex.toString()
        })
      }
    }
  }
}

// 预览组件
@Preview
@ComponentV2
struct UnifiedReaderPagePreview {
  build() {
    Column() {
      Text('统一阅读器 - 文本模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      UnifiedReaderPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('统一阅读器 - 漫画模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      UnifiedReaderPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
