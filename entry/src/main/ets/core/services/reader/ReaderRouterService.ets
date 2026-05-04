/**
 * 闃呰鍣ㄨ矾鐢辨湇鍔?- 鏍规嵁涔︾睄鏍煎紡閫夋嫨鍚堥€傜殑闃呰寮曟搸
 * 
 * - Reader Kit: txt, epub, mobi, azw, azw3
 * - PDF Kit: pdf
 * - 鍏朵粬鏍煎紡: 鎻愮ず涓嶆敮鎸佹垨杞崲
 */

import { readerKitService } from './ReaderKitService';
import { pdfKitService } from './PdfKitService';
import { BookFormat } from '../../models/CoreBookModel';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'ReaderRouter';
const LOG_DOMAIN = 0x0003;

/**
 * 闃呰鍣ㄧ被鍨? */
export enum ReaderType {
  READER_KIT = 'reader_kit',
  PDF_KIT = 'pdf_kit',
  UNSUPPORTED = 'unsupported'
}

/**
 * 闃呰鍣ㄨ矾鐢辩粨鏋? */
export interface ReaderRouteResult {
  type: ReaderType;
  supported: boolean;
  message?: string;
}

/**
 * 闃呰鍣ㄨ矾鐢辨湇鍔? */
export class ReaderRouterService {
  
  /**
   * 鏍规嵁涔︾睄鏍煎紡鑾峰彇闃呰鍣ㄧ被鍨?   * @param format 涔︾睄鏍煎紡
   */
  static getReaderType(format: BookFormat | string): ReaderRouteResult {
    const formatStr = typeof format === 'string' ? format : format.toString();
    const lowerFormat = formatStr.toLowerCase();
    
    // Reader Kit 鏀寔鐨勬牸寮?    if (['txt', 'epub', 'mobi', 'azw', 'azw3'].includes(lowerFormat)) {
      return {
        type: ReaderType.READER_KIT,
        supported: true
      };
    }
    
    // PDF Kit 鏀寔鐨勬牸寮?    if (lowerFormat === 'pdf') {
      return {
        type: ReaderType.PDF_KIT,
        supported: true
      };
    }
    
    // 涓嶆敮鎸佺殑鏍煎紡
    return {
      type: ReaderType.UNSUPPORTED,
      supported: false,
      message: `鏆備笉鏀寔 ${formatStr} 鏍煎紡锛屽缓璁娇鐢?EPUB銆丳DF銆丮OBI 绛夋牸寮廯
    };
  }
  
  /**
   * 妫€鏌ユ牸寮忔槸鍚︽敮鎸?   * @param format 涔︾睄鏍煎紡
   */
  static isSupported(format: BookFormat | string): boolean {
    return this.getReaderType(format).supported;
  }
  
  /**
   * 娓呯悊鎵€鏈夐槄璇诲櫒璧勬簮
   */
  static async cleanup(): Promise<void> {
    try {
      readerKitService.cleanup();
      await pdfKitService.cleanup();
      hilog.info(LOG_DOMAIN, LOG_TAG, 'All reader resources cleaned up');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to cleanup readers: %{public}s', 
        (error as Error).message);
    }
  }
}
