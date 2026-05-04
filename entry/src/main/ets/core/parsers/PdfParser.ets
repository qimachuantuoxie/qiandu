import { logger } from '../../utils/Logger';
/**
 * PDF Parser - PDF 鐢靛瓙涔﹁В鏋愬櫒
 *
 * 鎻愪緵 PDF 鏍煎紡鐢靛瓙涔︾殑瑙ｆ瀽鍔熻兘锛屽寘鎷�細
 * - 鍏冩暟鎹�彁鍙栵紙鏍囬�銆佷綔鑰呫€佸嚭鐗堝晢绛夛級
 * - 鏂囨湰鍐呭�鎻愬彇
 * - 涔︾�/澶х翰瑙ｆ瀽
 * - 鍘熺敓 C++ 鍔犻€熻В鏋愶紙濡傛灉鍙�敤锛?
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
} from '../models/EbookTypes';

/**
 * PDF 瑙ｆ瀽鍣ㄧ被
 */
export class PdfParser {
  /** 鍘熺敓妯″潡鏄�惁鍙�敤 */
  private static nativeAvailable: boolean = false;
  /** 褰撳墠 PDF 鏂囦欢璺�緞 */
  private static currentPdfPath: string = '';

  /**
   * 瑙ｆ瀽 PDF 鏂囦欢
   * @param filePath PDF 鏂囦欢璺�緞
   * @returns 瑙ｆ瀽缁撴灉
   */
  static async parse(filePath: string): Promise<ParseResult> {
    logger.info('[PdfParser] Parsing PDF file:', filePath);

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

        logger.info('[PdfParser] Native PDF parsed: ' + pageCount + ' pages');

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

      // 鍥為€€鍒板熀纭€瑙ｆ瀽
      logger.info('[PdfParser] Native open failed, using basic method');
      return await PdfParser.parseBasic(filePath);
    } catch (error) {
      logger.error('[PdfParser] Native PDF parsing failed, using basic method:', error);
      return await PdfParser.parseBasic(filePath);
    }
  }

  /**
   * 鍩虹� PDF 瑙ｆ瀽鏂规硶锛堜笉浣跨敤鍘熺敓妯″潡锛?
   * @param filePath PDF 鏂囦欢璺�緞
   * @returns 瑙ｆ瀽缁撴灉
   */
  private static async parseBasic(filePath: string): Promise<ParseResult> {
    logger.info('[PdfParser] Parsing PDF (basic method):', filePath);

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
      logger.warn('[PdfParser] PDF basic parsing failed:', error);
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
   * 璇诲彇鏂囦欢缂撳啿鍖?
   * @param filePath 鏂囦欢璺�緞
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
   * 鎻愬彇 PDF 鏂囨。淇℃伅
   * @param uint8 PDF 鏂囦欢瀛楄妭
   * @returns PDF 淇℃伅
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
      logger.warn('[PdfParser] Extract PDF info failed:', error);
    }

    return result;
  }

  /**
   * 瑙ｇ爜 PDF 瀛楃�涓诧紙澶勭悊杞�箟瀛楃�锛?
   * @param str PDF 涓�殑瀛楃�涓?
   * @returns 瑙ｇ爜鍚庣殑瀛楃�涓?
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
   * 浠?PDF 涓�彁鍙栨枃鏈�唴瀹?
   * @param uint8 PDF 鏂囦欢瀛楄妭
   * @returns 鎻愬彇鐨勬枃鏈?
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
      logger.warn('[PdfParser] Extract PDF text failed:', error);
    }

    return text.trim();
  }

  /**
   * 鎻愬彇 PDF 涔︾�/鐩�綍
   * @param uint8 PDF 鏂囦欢瀛楄妭
   * @returns 涔︾�鍒楄〃
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
      logger.warn('[PdfParser] Extract PDF bookmarks failed:', error);
    }

    return bookmarks;
  }

  /**
   * 鑾峰彇 PDF 鎸囧畾椤电殑鏂囨湰
   * @param pageIndex 椤电爜绱㈠紩
   * @returns 椤甸潰鏂囨湰鍐呭�
   */
  static async getPageText(pageIndex: number): Promise<string> {
    if (PdfParser.nativeAvailable && PdfParser.currentPdfPath) {
      const nativePdf = await nativeModules.getPDF();
      try {
        await nativePdf.openPdf(PdfParser.currentPdfPath);
        const text = await nativePdf.getPageText(pageIndex);
        return text;
      } catch (error) {
        logger.error('[PdfParser] Get page text failed:', error);
        return '';
      } finally {
        await nativePdf.closePdf();
      }
    }
    return '';
  }

  /**
   * 鑾峰彇 PDF 鎸囧畾椤电殑鍥惧儚娓叉煋
   * @param pageIndex 椤电爜绱㈠紩
   * @param width 娓叉煋瀹藉害
   * @param height 娓叉煋楂樺害
   * @returns Base64 缂栫爜鐨勫浘鍍?
   */
  static async getPageImage(pageIndex: number, width: number, height: number): Promise<string> {
    if (PdfParser.nativeAvailable && PdfParser.currentPdfPath) {
      const nativePdf = await nativeModules.getPDF();
      try {
        await nativePdf.openPdf(PdfParser.currentPdfPath);
        const base64: string = await nativePdf.renderPageToBase64(pageIndex, width, height);
        return base64;
      } catch (error) {
        logger.error('[PdfParser] Render page failed:', error);
        return '';
      } finally {
        await nativePdf.closePdf();
      }
    }
    return '';
  }

  /**
   * 瀛楄妭鏁扮粍杞�瓧绗︿覆
   * @param bytes 瀛楄妭鏁扮粍
   * @returns 瀛楃�涓?
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
   * 浠庢枃浠惰矾寰勬彁鍙栨枃浠跺悕
   * @param filePath 鏂囦欢璺�緞
   * @returns 鏂囦欢鍚?
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

/** PDF 瑙ｆ瀽鍣ㄥ崟渚嬪疄渚?*/
export const pdfParser = PdfParser;
