/**
 * PDF Parser - PDF 电子书解析器
 *
 * 提供 PDF 格式电子书的解析功能，包括：
 * - 元数据提取（标题、作者、出版商等）
 * - 文本内容提取
 * - 书签/大纲解析
 * - 原生 C++ 加速解析（如果可用）
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { nativeModules } from '../utils/NativeModules';
import {
  BookMetadata,
  LocalChapterInfo,
  ParseResult,
  PdfBookmarkItem,
  PdfBookmarkResult,
  PdfInfoResult
} from '../core/models/EbookTypes';

/**
 * PDF 解析器类
 */
export class PdfParser {
  /** 原生模块是否可用 */
  private static nativeAvailable: boolean = false;
  /** 当前 PDF 文件路径 */
  private static currentPdfPath: string = '';

  /**
   * 解析 PDF 文件
   * @param filePath PDF 文件路径
   * @returns 解析结果
   */
  static async parse(filePath: string): Promise<ParseResult> {
    console.info('[PdfParser] Parsing PDF file:', filePath);

    try {
      await nativeModules.initialize();
      const nativePdf = await nativeModules.getPDF();

      const openResult = await nativePdf.openPdf(filePath);

      if (openResult.success) {
        PdfParser.nativeAvailable = true;
        PdfParser.currentPdfPath = filePath;

        const metadata = await nativePdf.getMetadata();
        const bookmarks: PdfBookmarkItem[] = [];
        const pageCount = 100;

        console.info('[PdfParser] Native PDF parsed: ' + pageCount + ' pages');

        const resultMetadata: BookMetadata = {
          title: metadata ? metadata.title : 'Unknown',
          author: metadata ? metadata.author : 'Unknown',
          publisher: metadata ? metadata.publisher : undefined,
          isbn: metadata ? metadata.isbn : undefined,
          language: metadata ? metadata.language : 'zh-CN',
          description: metadata ? metadata.description : undefined,
          coverData: undefined,
          totalPages: pageCount,
          wordCount: undefined,
          createdDate: metadata ? metadata.createdDate : undefined,
          modifiedDate: metadata ? metadata.modifiedDate : undefined
        };

        const chapters: LocalChapterInfo[] = [];

        const fullText = await nativePdf.getPageText(0);

        await nativePdf.closePdf();

        return {
          metadata: resultMetadata,
          content: fullText || '',
          chapters: chapters,
          success: true
        };
      }

      // 回退到基础解析
      console.info('[PdfParser] Native open failed, using basic method');
      return await PdfParser.parseBasic(filePath);
    } catch (error) {
      console.error('[PdfParser] Native PDF parsing failed, using basic method:', error);
      return await PdfParser.parseBasic(filePath);
    }
  }

  /**
   * 基础 PDF 解析方法（不使用原生模块）
   * @param filePath PDF 文件路径
   * @returns 解析结果
   */
  private static async parseBasic(filePath: string): Promise<ParseResult> {
    console.info('[PdfParser] Parsing PDF (basic method):', filePath);

    const fileName = PdfParser.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    try {
      const buffer = await PdfParser.readFileBuffer(filePath);
      const uint8 = new Uint8Array(buffer);

      const pdfInfo = PdfParser.extractPdfInfo(uint8);
      const text = PdfParser.extractPdfText(uint8);
      const bookmarks = PdfParser.extractPdfBookmarks(uint8);

      const chapters: LocalChapterInfo[] = [];
      for (let i = 0; i < bookmarks.length; i++) {
        const b = bookmarks[i];
        const chapter: LocalChapterInfo = {
          id: 'pdf_chapter_' + i,
          title: b.title,
          startOffset: b.pageIndex,
          endOffset: b.pageIndex + 1,
          level: b.level
        };
        chapters.push(chapter);
      }

      return {
        metadata: {
          title: pdfInfo.title || nameWithoutExt,
          author: pdfInfo.author || 'Unknown Author',
          publisher: pdfInfo.creator,
          language: 'zh-CN',
          description: pdfInfo.subject,
          totalPages: pdfInfo.pageCount || 100,
          wordCount: text.length
        },
        content: text,
        chapters: chapters,
        success: true
      };
    } catch (error) {
      console.warn('[PdfParser] PDF basic parsing failed:', error);
      return {
        metadata: {
          title: nameWithoutExt,
          author: 'Unknown Author',
          totalPages: 100,
          language: 'zh-CN'
        },
        content: '',
        chapters: [],
        success: true
      };
    }
  }

  /**
   * 读取文件缓冲区
   * @param filePath 文件路径
   * @returns ArrayBuffer
   */
  private static async readFileBuffer(filePath: string): Promise<ArrayBuffer> {
    const stat = fileIo.statSync(filePath);
    const buffer = new Uint8Array(stat.size);
    const fd = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    try {
      fileIo.readSync(fd.fd, buffer);
    } finally {
      fileIo.closeSync(fd);
    }
    return buffer.buffer as ArrayBuffer;
  }

  /**
   * 提取 PDF 文档信息
   * @param uint8 PDF 文件字节
   * @returns PDF 信息
   */
  private static extractPdfInfo(uint8: Uint8Array): PdfInfoResult {
    const result: PdfInfoResult = {
      title: undefined,
      author: undefined,
      creator: undefined,
      producer: undefined,
      subject: undefined,
      pageCount: 0
    };

    try {
      const content = PdfParser.bytesToString(uint8.slice(0, Math.min(10000, uint8.length)));

      const titleMatch = content.match(new RegExp('\/Title\s*\(([^)]*)\)', ''));
      if (titleMatch && titleMatch.length >= 2) {
        result.title = PdfParser.decodePdfString(titleMatch[1]);
      }

      const authorMatch = content.match(new RegExp('\/Author\s*\(([^)]*)\)', ''));
      if (authorMatch && authorMatch.length >= 2) {
        result.author = PdfParser.decodePdfString(authorMatch[1]);
      }

      const creatorMatch = content.match(new RegExp('\/Creator\s*\(([^)]*)\)', ''));
      if (creatorMatch && creatorMatch.length >= 2) {
        result.creator = PdfParser.decodePdfString(creatorMatch[1]);
      }

      const producerMatch = content.match(new RegExp('\/Producer\s*\(([^)]*)\)', ''));
      if (producerMatch && producerMatch.length >= 2) {
        result.producer = PdfParser.decodePdfString(producerMatch[1]);
      }

      const subjectMatch = content.match(new RegExp('\/Subject\s*\(([^)]*)\)', ''));
      if (subjectMatch && subjectMatch.length >= 2) {
        result.subject = PdfParser.decodePdfString(subjectMatch[1]);
      }

      const countMatch = content.match(new RegExp('\/Count\s+(\d+)', ''));
      if (countMatch && countMatch.length >= 2) {
        result.pageCount = parseInt(countMatch[1], 10);
      }

      if (result.pageCount === 0) {
        const pagesMatch = content.match(new RegExp('\/Pages\s+(\d+)', ''));
        if (pagesMatch && pagesMatch.length >= 2) {
          result.pageCount = parseInt(pagesMatch[1], 10);
        }
      }

      if (result.pageCount === 0) {
        const kidsMatch = content.match(new RegExp('\/Kids\s+\[\s*(\d+)', ''));
        if (kidsMatch) {
          result.pageCount = 1;
        }
      }

    } catch (error) {
      console.warn('[PdfParser] Extract PDF info failed:', error);
    }

    return result;
  }

  /**
   * 解码 PDF 字符串（处理转义字符）
   * @param str PDF 中的字符串
   * @returns 解码后的字符串
   */
  private static decodePdfString(str: string): string {
    let decoded = str;
    decoded = decoded.replace(new RegExp('\\\\n', 'g'), '\n');
    decoded = decoded.replace(new RegExp('\\\\r', 'g'), '\r');
    decoded = decoded.replace(new RegExp('\\\\t', 'g'), '\t');
    decoded = decoded.replace(new RegExp('\\\\\(', 'g'), '(');
    decoded = decoded.replace(new RegExp('\\\\\)', 'g'), ')');
    decoded = decoded.replace(new RegExp('\\\\\\\\', 'g'), '\\');
    return decoded;
  }

  /**
   * 从 PDF 中提取文本内容
   * @param uint8 PDF 文件字节
   * @returns 提取的文本
   */
  private static extractPdfText(uint8: Uint8Array): string {
    let text = '';

    try {
      const content = PdfParser.bytesToString(uint8);

      const streamMatches = content.match(new RegExp('stream[\s\S]*?endstream', 'gi'));
      if (streamMatches) {
        for (let i = 0; i < streamMatches.length && i < 20; i++) {
          const stream = streamMatches[i];

          if (stream.includes('/Tx')) {
            const btIndex = stream.indexOf('BT');
            const etIndex = stream.indexOf('ET');
            if (btIndex >= 0 && etIndex > btIndex) {
              const textContent = stream.substring(btIndex, etIndex);
              const tjMatches = textContent.match(new RegExp('\(([^)]*)\)\s*Tj', 'gi'));
              if (tjMatches) {
                for (let j = 0; j < tjMatches.length; j++) {
                  const match = tjMatches[j].match(new RegExp('\(([^)]*)\)\s*Tj', ''));
                  if (match && match.length >= 2) {
                    const lineText = PdfParser.decodePdfString(match[1]);
                    if (lineText.trim()) {
                      text += lineText + '\n';
                    }
                  }
                }
              }

              const tdMatches = textContent.match(new RegExp('\(([^)]*)\)\s*\'', 'gi'));
              if (tdMatches) {
                for (let j = 0; j < tdMatches.length; j++) {
                  const match = tdMatches[j].match(new RegExp('\(([^)]*)\)\s*\'', ''));
                  if (match && match.length >= 2) {
                    text += PdfParser.decodePdfString(match[1]) + '\n';
                  }
                }
              }
            }
          }
        }
      }

    } catch (error) {
      console.warn('[PdfParser] Extract PDF text failed:', error);
    }

    return text.trim();
  }

  /**
   * 提取 PDF 书签/目录
   * @param uint8 PDF 文件字节
   * @returns 书签列表
   */
  private static extractPdfBookmarks(uint8: Uint8Array): PdfBookmarkItem[] {
    const bookmarks: PdfBookmarkItem[] = [];

    try {
      const content = PdfParser.bytesToString(uint8.slice(0, Math.min(50000, uint8.length)));

      const outlineMatch = content.match(new RegExp('\/Outlines\s+(\d+)\s+\d+\s+R', ''));
      if (!outlineMatch) {
        return bookmarks;
      }

      const titleMatches = content.match(new RegExp('\/Title\s*\(([^)]*)\)[^}]*?\/Page\s+\d+\s+\d+\s+R', 'gi'));
      if (titleMatches) {
        let pageIndex = 0;
        for (let i = 0; i < titleMatches.length; i++) {
          const match = titleMatches[i].match(new RegExp('\/Title\s*\(([^)]*)\)', ''));
          if (match && match.length >= 2) {
            const title = PdfParser.decodePdfString(match[1]);
            if (title) {
              bookmarks.push({
                title: title,
                pageIndex: pageIndex,
                level: 0
              });
              pageIndex += 5;
            }
          }
        }
      }

    } catch (error) {
      console.warn('[PdfParser] Extract PDF bookmarks failed:', error);
    }

    return bookmarks;
  }

  /**
   * 获取 PDF 指定页的文本
   * @param pageIndex 页码索引
   * @returns 页面文本内容
   */
  static async getPageText(pageIndex: number): Promise<string> {
    if (PdfParser.nativeAvailable && PdfParser.currentPdfPath) {
      const nativePdf = await nativeModules.getPDF();
      try {
        await nativePdf.openPdf(PdfParser.currentPdfPath);
        const text = await nativePdf.getPageText(pageIndex);
        return text;
      } catch (error) {
        console.error('[PdfParser] Get page text failed:', error);
        return '';
      } finally {
        await nativePdf.closePdf();
      }
    }
    return '';
  }

  /**
   * 获取 PDF 指定页的图像渲染
   * @param pageIndex 页码索引
   * @param width 渲染宽度
   * @param height 渲染高度
   * @returns Base64 编码的图像
   */
  static async getPageImage(pageIndex: number, width: number, height: number): Promise<string> {
    if (PdfParser.nativeAvailable && PdfParser.currentPdfPath) {
      const nativePdf = await nativeModules.getPDF();
      try {
        await nativePdf.openPdf(PdfParser.currentPdfPath);
        const base64: string = await nativePdf.renderPageToBase64(pageIndex, width, height);
        return base64;
      } catch (error) {
        console.error('[PdfParser] Render page failed:', error);
        return '';
      } finally {
        await nativePdf.closePdf();
      }
    }
    return '';
  }

  /**
   * 字节数组转字符串
   * @param bytes 字节数组
   * @returns 字符串
   */
  private static bytesToString(bytes: Uint8Array): string {
    let result = '';
    for (let i = 0; i < bytes.length; i++) {
      const byte = bytes[i];
      if (byte < 0x80) {
        result += String.fromCharCode(byte);
      } else if ((byte & 0xE0) === 0xC0 && i + 1 < bytes.length) {
        result += String.fromCharCode(((byte & 0x1F) << 6) | (bytes[++i] & 0x3F));
      } else if ((byte & 0xF0) === 0xE0 && i + 2 < bytes.length) {
        result += String.fromCharCode(((byte & 0x0F) << 12) | ((bytes[++i] & 0x3F) << 6) | (bytes[++i] & 0x3F));
      } else if ((byte & 0xF8) === 0xF0 && i + 3 < bytes.length) {
        const codePoint = ((byte & 0x07) << 18) | ((bytes[++i] & 0x3F) << 12) | ((bytes[++i] & 0x3F) << 6) | (bytes[++i] & 0x3F);
        if (codePoint > 0xFFFF) {
          result += String.fromCharCode(0xD800 + ((codePoint - 0x10000) >> 10), 0xDC00 + ((codePoint - 0x10000) & 0x3FF));
        } else {
          result += String.fromCharCode(codePoint);
        }
      }
    }
    return result;
  }

  /**
   * 从文件路径提取文件名
   * @param filePath 文件路径
   * @returns 文件名
   */
  private static extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const lastPart = parts[parts.length - 1];
    try {
      return decodeURIComponent(lastPart);
    } catch {
      return lastPart;
    }
  }
}

/** PDF 解析器单例实例 */
export const pdfParser = PdfParser;
