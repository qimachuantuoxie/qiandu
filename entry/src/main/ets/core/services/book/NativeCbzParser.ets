/**
 * Native CBZ Parser 模块封装
 * 
 * 提供 CBZ/CBR 漫画文件的 Native 解析能力
 */

import nativeCbzParser from 'libcbzparser.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'NativeCbzParser';
const LOG_DOMAIN = 0x0050;

/**
 * CBZ 文件信息
 */
export interface CbzFileInfo {
  title: string;
  author: string;
  pageCount: number;
}

/**
 * Native CBZ 解析器
 */
export class NativeCbzParser {
  
  /**
   * 解析 CBZ 文件信息
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
   * 获取页面数量
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
   * 获取页面图片数据
   * @param filePath CBZ 文件路径
   * @param pageIndex 页码（从0开始）
   * @returns 图片数据（JPEG/PNG 等原始格式）
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
   * 获取所有页面文件名列表
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
   * 检查 Native 模块是否可用
   */
  static isAvailable(): boolean {
    try {
      return typeof nativeCbzParser.parseCbzInfo === 'function';
    } catch (error) {
      return false;
    }
  }
}
