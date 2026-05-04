import { logger } from '../../../common/utils/Logger';
/**
 * OnlineBookDetailPage ViewModel - V2鐗堟湰
 * 娉ㄦ剰: 浠ヤ笅鏂规硶闇€瑕侀�澶栧疄鐜癝ervice鏀�寔:
 * - getOnlineBookInfo: 浠庡湪绾挎簮鑾峰彇涔︾睄淇℃伅
 * - getChapterList: 鑾峰彇绔犺妭鍒楄〃
 * - getChapterContent: 鑾峰彇绔犺妭鍐呭�
 * TODO: 鍦∣nlineBookService鎴朢uleEngine涓�疄鐜颁笂杩版柟娉?
 */
import { SourceBookInfo } from '../models/BookSourceModel';
import { bookSourceViewModel } from './BookSourceViewModel';

@ObservedV2
export class OnlineBookDetailViewModel {
  @Trace book: SourceBookInfo | null = null;
  @Trace chapters: string[] = [];
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace isFavorite: boolean = false;
  @Trace readProgress: number = 0;

  async init(bookUrl: string, sourceId: string): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';

    try {
      // TODO: 闇€瑕佸厛瀹炵幇OnlineBookService.getOnlineBookInfo鏂规硶
      // this.book = await onlineBookService.getBookInfo(bookUrl, sourceId);
      this.errorMsg = '鍦ㄧ嚎涔︾睄璇︽儏鍔熻兘鏆傛湭瀹炵幇,闇€瑕佸疄鐜癘nlineBookService';
      logger.warn('OnlineBookDetail: getOnlineBookInfo鏂规硶鏈�疄鐜?);
      
      if (this.book) {
        if (this.book.chapters) {
          const chapters: string[] = [];
          for (let i = 0; i < this.book.chapters.length; i++) {
            chapters.push(this.book.chapters[i]);
          }
          this.chapters = chapters;
        } else {
          this.chapters = [];
        }
      }
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '鍔犺浇涔︾睄璇︽儏澶辫触: ' + message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadChapters(): Promise<void> {
    if (!this.book) return;
    this.isLoading = true;
    try {
      // TODO: 闇€瑕佸厛瀹炵幇OnlineBookService.getChapterList鏂规硶
      // this.chapters = await onlineBookService.getChapterList(this.book.bookUrl, this.book.sourceId);
      this.errorMsg = '绔犺妭鍔犺浇鍔熻兘鏆傛湭瀹炵幇,闇€瑕佸疄鐜癘nlineBookService';
      logger.warn('OnlineBookDetail: getChapterList鏂规硶鏈�疄鐜?);
    } catch (error) {
      const err = error as Error;
      this.errorMsg = '鍔犺浇绔犺妭澶辫触: ' + message;
    } finally {
      this.isLoading = false;
    }
  }

  async getChapterContent(chapterUrl: string): Promise<string> {
    // TODO: 闇€瑕佸厛瀹炵幇OnlineBookService.getChapterContent鏂规硶
    // const sourceId = this.book ? this.book.sourceId : '';
    // return await onlineBookService.getChapterContent(chapterUrl, sourceId);
    logger.warn('OnlineBookDetail: getChapterContent鏂规硶鏈�疄鐜?);
    return '绔犺妭鍐呭�鑾峰彇鍔熻兘鏆傛湭瀹炵幇';
  }

  toggleFavorite(): void {
    this.isFavorite = !this.isFavorite;
  }
}

export const onlineBookDetailViewModel = new OnlineBookDetailViewModel();
