/**
 * Native CBZ Parser 妯″潡灏佽
 * 
 * 鎻愪緵 CBZ/CBR 婕敾鏂囦欢鐨?Native 瑙ｆ瀽鑳藉姏
 */

import nativeCbzParser from 'libcbzparser.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'NativeCbzParser';
const LOG_DOMAIN = 0x0050;

/**
 * CBZ 鏂囦欢淇℃伅
 */
export interface CbzFileInfo {
  title: string;
  author: string;
  pageCount: number;
}

/**
 * Native CBZ 瑙ｆ瀽鍣? */
export class NativeCbzParser {
  
  /**
   * 瑙ｆ瀽 CBZ 鏂囦欢淇℃伅
   */
  static parseCbzInfo(filePath: string): CbzFileInfo | null {
    try {
      const result = nativeCbzParser.parseCbzInfo(filePath);
      return result as CbzFileInfo;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to parse CBZ: %{public}s', 
        (error as Error).message);
      return null;
    }
  }
  
  /**
   * 鑾峰彇椤甸潰鏁伴噺
   */
  static getPageCount(filePath: string): number {
    try {
      return nativeCbzParser.getCbzPageCount(filePath) as number;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get page count: %{public}s', 
        (error as Error).message);
      return -1;
    }
  }
  
  /**
   * 鑾峰彇椤甸潰鍥剧墖鏁版嵁
   * @param filePath CBZ 鏂囦欢璺緞
   * @param pageIndex 椤电爜锛堜粠0寮€濮嬶級
   * @returns 鍥剧墖鏁版嵁锛圝PEG/PNG 绛夊師濮嬫牸寮忥級
   */
  static getPageImage(filePath: string, pageIndex: number): Uint8Array | null {
    try {
      const imageData = nativeCbzParser.getCbzPageImage(filePath, pageIndex);
      return imageData as Uint8Array;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get page image: %{public}s', 
        (error as Error).message);
      return null;
    }
  }
  
  /**
   * 鑾峰彇鎵€鏈夐〉闈㈡枃浠跺悕鍒楄〃
   */
  static getPageFileNames(filePath: string): string[] | null {
    try {
      const fileNames = nativeCbzParser.getCbzPageFileNames(filePath);
      return fileNames as string[];
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to get file names: %{public}s', 
        (error as Error).message);
      return null;
    }
  }
  
  /**
   * 妫€鏌?Native 妯″潡鏄惁鍙敤
   */
  static isAvailable(): boolean {
    try {
      return typeof nativeCbzParser.parseCbzInfo === 'function';
    } catch (error) {
      return false;
    }
  }
}
