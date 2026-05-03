/**
 * Ebook Parser Utils - 电子书解析通用工具
 *
 * 提供电子书解析过程中常用的工具方法，包括：
 * - 文件名提取
 * - 文件大小格式化
 * - 阅读时间计算
 * - 内容摘要生成
 * - 关键词提取
 * - 语言检测
 * - 文件验证
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { BookFormat } from '../core/models/book/CoreBookModel';
import { BookMetadata } from '../core/models/EbookTypes';

/**
 * 电子书解析通用工具类
 */
export class EbookParserUtils {

  /**
   * 从文件路径提取文件名
   * @param filePath 文件路径
   * @returns 文件名（含 URL 解码）
   */
  static extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const lastPart = parts[parts.length - 1];
    try {
      return decodeURIComponent(lastPart);
    } catch {
      return lastPart;
    }
  }

  /**
   * 鑾峰彇鏂囦欢鎵╁睍鍚?   * @param fileName 鏂囦欢鍚?   * @returns 鎵╁睍鍚嶏紙鍚偣鍙凤級
   */
  static getFileExtension(fileName: string): string {
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > -1) {
      return fileName.substring(lastDot);
    }
    return '';
  }

  /**
   * 鍒涘缓榛樿鍏冩暟鎹紙鐢ㄤ簬瑙ｆ瀽澶辫触鏃讹級
   * @param filePath 鏂囦欢璺緞
   * @returns 榛樿鍏冩暟鎹?   */
  static createDefaultMetadata(filePath: string): BookMetadata {
    const fileName = EbookParserUtils.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    return {
      title: nameWithoutExt,
      author: 'Unknown Author',
      totalPages: 100
    };
  }

  /**
   * 鏍煎紡鍖栨枃浠跺ぇ灏?   * @param bytes 瀛楄妭鏁?   * @returns 鏍煎紡鍖栧瓧绗︿覆锛堝 "1.5 MB"锛?   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 璁＄畻棰勮闃呰鏃堕棿
   * @param wordCount 瀛楁暟
   * @param speed 闃呰閫熷害锛堝瓧/鍒嗛挓锛夛紝榛樿 300
   * @returns 闃呰鏃堕棿锛堝垎閽燂級
   */
  static calculateReadingTime(wordCount: number, speed: number = 300): number {
    return Math.ceil(wordCount / speed);
  }

  /**
   * 鐢熸垚鍐呭鎽樿
   * @param content 鍘熷鍐呭
   * @param maxLength 鏈€澶ч暱搴︼紝榛樿 500
   * @returns 鎽樿鏂囨湰
   */
  static generateSummary(content: string, maxLength: number = 500): string {
    if (!content || content.length === 0) return '';

    const text = content.replace(new RegExp('\s+', 'g'), ' ').trim();

    if (text.length <= maxLength) return text;

    let summary = text.substring(0, maxLength);
    const lastSpace = summary.lastIndexOf(' ');
    if (lastSpace > 0) {
      summary = summary.substring(0, lastSpace);
    }

    return summary + '...';
  }

  /**
   * 鎻愬彇鍏抽敭璇嶏紙鍩轰簬鍗曞瓧棰戠巼锛?   * @param content 鏂囨湰鍐呭
   * @param limit 鍏抽敭璇嶆暟閲忛檺鍒讹紝榛樿 10
   * @returns 鍏抽敭璇嶅垪琛?   */
  static extractKeywords(content: string, limit: number = 10): string[] {
    if (!content) return [];

    const chars = content.split('');
    const chineseChars: string[] = [];
    for (let i = 0; i < chars.length; i++) {
      if (new RegExp('[\u4e00-\u9fa5]').test(chars[i])) {
        chineseChars.push(chars[i]);
      }
    }

    const freq: Record<string, number> = {};
    for (let i = 0; i < chineseChars.length; i++) {
      const word = chineseChars[i];
      if (freq[word] !== undefined) {
        freq[word] = freq[word] + 1;
      } else {
        freq[word] = 1;
      }
    }

    const entries = Object.entries(freq);
    const filtered: Array<[string, number]> = [];
    for (let i = 0; i < entries.length; i++) {
      if (entries[i][1] >= 5) {
        filtered.push(entries[i]);
      }
    }

    // 手动排序 (冒泡排序)
    for (let i = 0; i < filtered.length - 1; i++) {
      for (let j = 0; j < filtered.length - 1 - i; j++) {
        if (filtered[j + 1][1] > filtered[j][1]) {
          const temp = filtered[j];
          filtered[j] = filtered[j + 1];
          filtered[j + 1] = temp;
        }
      }
    }

    const result: string[] = [];
    const sliceLen = filtered.length < limit ? filtered.length : limit;
    for (let i = 0; i < sliceLen; i++) {
      result.push(filtered[i][0]);
    }

    return result;
  }

  /**
   * 妫€娴嬫枃鏈瑷€
   * @param content 鏂囨湰鍐呭
   * @returns 璇█浠ｇ爜锛堝 'zh-CN', 'en', 'unknown'锛?   */
  static detectLanguage(content: string): string {
    if (!content) return 'unknown';

    const chineseMatch = content.match(new RegExp('[\u4e00-\u9fa5]', 'g'));
    const chineseChars = chineseMatch ? chineseMatch.length : 0;
    const englishMatch = content.match(new RegExp('[a-zA-Z]', 'g'));
    const englishChars = englishMatch ? englishMatch.length : 0;
    const total = content.length;

    if (chineseChars / total > 0.3) return 'zh-CN';
    if (englishChars / total > 0.3) return 'en';
    return 'unknown';
  }

  /**
   * 楠岃瘉鏂囦欢鏍煎紡鏄惁鍖归厤
   * @param filePath 鏂囦欢璺緞
   * @param format 鏈熸湜鐨勪功绫嶆牸寮?   * @returns 鏄惁鏈夋晥
   */
  static async validateFile(filePath: string, format: BookFormat): Promise<boolean> {
    try {
      const stat = await fileIo.stat(filePath);
      if (!stat.size || stat.size === 0) {
        console.error('[EbookParserUtils] File size is 0');
        return false;
      }

      const fileName = EbookParserUtils.extractFileName(filePath);
      const ext = EbookParserUtils.getFileExtension(fileName).toLowerCase();

      let validExts: string[] = [];
      switch (format) {
        case BookFormat.PDF:
          validExts = ['.pdf'];
          break;
        case BookFormat.EPUB:
          validExts = ['.epub'];
          break;
        case BookFormat.MOBI:
          validExts = ['.mobi'];
          break;
        case BookFormat.TXT:
          validExts = ['.txt'];
          break;
        case BookFormat.DOCX:
          validExts = ['.docx'];
          break;
        case BookFormat.CBZ:
          validExts = ['.cbz'];
          break;
        case BookFormat.CBR:
          validExts = ['.cbr'];
          break;
      }

      return validExts.includes(ext);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[EbookParserUtils] File validation failed:', message);
      return false;
    }
  }
}

/** 鐢靛瓙涔﹁В鏋愬伐鍏峰崟渚嬪疄渚?*/
export const ebookParserUtils = EbookParserUtils;
