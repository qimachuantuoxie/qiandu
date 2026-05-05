import { logger } from '../../utils/Logger';
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
import { BookFormat } from '../models/CoreBookModel';
import { BookMetadata } from '../models/EbookTypes';

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
   * 获取文件扩展名
   * @param fileName 文件名
   * @returns 文件扩展名（如 .pdf）
   */
  static getFileExtension(fileName: string): string {
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > -1) {
      return fileName.substring(lastDot);
    }
    return '';
  }

  /**
   * 创建默认元数据对象
   * @param filePath 文件路径
   * @returns 默认元数据
   */
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
   * 格式化文件大小
   * @param bytes 字节数
   * @returns 格式化后的字符串，如 "1.5 MB"
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 计算预计阅读时间
   * @param wordCount 字数
   * @param speed 阅读速度（字/分钟），默认300
   * @returns 预计阅读时间（分钟）
   */
  static calculateReadingTime(wordCount: number, speed: number = 300): number {
    return Math.ceil(wordCount / speed);
  }

  /**
   * 生成内容摘要
   * @param content 原始内容
   * @param maxLength 最大长度，默认 500
   * @returns 摘要文本
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
   * 从内容中提取高频中文字符作为关键词
   * @param content 文本内容
   * @param limit 返回的关键词数量，默认 10
   * @returns 关键词列表
   */
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
   * 检测文本语言
   * @param content 文本内容
   * @returns 语言代码，'zh-CN', 'en', 'unknown'
   */
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
   * 验证文件格式是否正确
   * @param filePath 文件路径
   * @param format 期望的文件格式
   * @returns 是否有效
   */
  static async validateFile(filePath: string, format: BookFormat): Promise<boolean> {
    try {
      const stat = await fileIo.stat(filePath);
      if (!stat.size || stat.size === 0) {
        logger.error('[EbookParserUtils] File size is 0');
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
      logger.error('[EbookParserUtils] File validation failed:', message);
      return false;
    }
  }
}

/** 电子书解析工具单例实例 */
export const ebookParserUtils = EbookParserUtils;
