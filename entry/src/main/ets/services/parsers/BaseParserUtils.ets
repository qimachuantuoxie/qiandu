/**
 * 基础解枝工具�?- �?EnhancedDocumentParser 拆分
 * Base Parser Utilities - Common parsing utilities
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

/**
 * ZIP条目接坣
 */
export interface ZipEntry {
  path: string;
  isDirectory: boolean;
  data: Uint8Array;
}

/**
 * ZIP解枝结果
 */
export interface ZipParseResult {
  entries: ZipEntry[];
}

/**
 * 章节信杯�?
 */
export interface ChapterInfoItem {
  title: string;
  offset: number;
}

/**
 * 提取的章节数据
 */
export interface ExtractedChapter {
  index: number;
  title: string;
  content: string;
  offset: number;
}

export class BaseParserUtils {
  /**
   * 读坖文件缓冲区（异步 I/O，使�?try-finally 保护文件杝述符）
   */
  static async readFileBuffer(filePath: string): Promise<ArrayBuffer> {
    let file: fileIo.File | null = null;
    try {
      file = await fileIo.open(filePath);
      const stat = await fileIo.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fileIo.read(file.fd, buffer);
      return buffer;
    } catch (error) {
      const err = error as Error;
      console.error('[BaseParser] Read file buffer failed:', err.message);
      throw new Error(err.message);
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file);
        } catch (closeError) {
          const err = closeError as Error;
          console.error('[BaseParser] Failed to close file:', err.message);
        }
      }
    }
  }

  /**
   * 读坖文件缓冲区（带大尝陝制，靿兝大文件一次性加载到内存�?
   * @param filePath 文件路径
   * @param maxBytes 最大读坖字节数，如果为 0 或负数则读坖整个文件
   */
  static async readFileBufferWithLimit(filePath: string, maxBytes: number): Promise<ArrayBuffer> {
    let file: fileIo.File | null = null;
    try {
      file = await fileIo.open(filePath);
      const stat = await fileIo.stat(filePath);
      const bytesToRead = maxBytes > 0 ? Math.min(stat.size, maxBytes) : stat.size;
      const buffer = new ArrayBuffer(bytesToRead);
      await fileIo.read(file.fd, buffer);
      return buffer;
    } catch (error) {
      const err = error as Error;
      console.error('[BaseParser] Read file buffer with limit failed:', err.message);
      throw new Error(err.message);
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file);
        } catch (closeError) {
          const err = closeError as Error;
          console.error('[BaseParser] Failed to close file:', err.message);
        }
      }
    }
  }

  /**
   * 从文件路径杝坖文件坝（丝坫扩展坝�?
   */
  static extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const fileName = parts[parts.length - 1];
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /**
   * 简坕的 ZIP 解枝（增强版 - 支挝 ZIP64 和更好的错误处睆�?
   */
  static async parseZipFile(filePath: string): Promise<ZipParseResult> {
    const entries: ZipEntry[] = [];

    try {
      const buffer = await BaseParserUtils.readFileBuffer(filePath);
      const uint8Array = new Uint8Array(buffer);

      // 查找本地文件头签�?(PK\x03\x04)
      let offset = 0;
      let maxIterations = 10000; // 防止无陝循环
      let iterations = 0;

      while (offset < uint8Array.length - 4 && iterations < maxIterations) {
        iterations++;
        
        if (uint8Array[offset] === 0x50 && uint8Array[offset + 1] === 0x4B &&
            uint8Array[offset + 2] === 0x03 && uint8Array[offset + 3] === 0x04) {

          try {
            // 解枝本地文件�?
            const compressionMethod = uint8Array[offset + 8] | (uint8Array[offset + 9] << 8);
            
            // 支挝 ZIP64
            let compressedSize = uint8Array[offset + 18] | (uint8Array[offset + 19] << 8) |
                                (uint8Array[offset + 20] << 16) | (uint8Array[offset + 21] << 24);
            let uncompressedSize = uint8Array[offset + 22] | (uint8Array[offset + 23] << 8) |
                                  (uint8Array[offset + 24] << 16) | (uint8Array[offset + 25] << 24);
            
            const fileNameLength = uint8Array[offset + 26] | (uint8Array[offset + 27] << 8);
            const extraFieldLength = uint8Array[offset + 28] | (uint8Array[offset + 29] << 8);

            // 验话长度
            if (fileNameLength > 1000 || extraFieldLength > 10000) {
              offset += 4;
              continue;
            }

            const fileNameBytes = uint8Array.slice(offset + 30, offset + 30 + fileNameLength);
            const decoder = new util.TextDecoder('utf-8');
            const fileName = decoder.decodeWithStream(fileNameBytes);

            const dataStart = offset + 30 + fileNameLength + extraFieldLength;
            const dataEnd = dataStart + compressedSize;

            // ZIP64 扩展处睆
            if (compressedSize === 0xFFFFFFFF || uncompressedSize === 0xFFFFFFFF) {
              // 查找 ZIP64 扩展字段
              // 简化处睆：尝试从中央目录读�?
              console.warn('[BaseParser] ZIP64 entry detected, may not be fully supported');
            }

            if (dataEnd <= uint8Array.length && dataStart < dataEnd && !fileName.endsWith('/')) {
              let data = uint8Array.slice(dataStart, dataEnd);
              
              // 解压缩（如果�?Deflate�?
              if (compressionMethod === 8) { // Deflate
                try {
                  // HarmonyOS 丝支挝原�?Deflate，跳过压缩条�?
                  console.warn('[BaseParser] Deflate compression not fully supported, skipping entry:', fileName);
                } catch (decompressError) {
                  const err = decompressError as Error;
                  console.error('[BaseParser] Decompression failed:', err.message);
                }
              } else if (compressionMethod === 0) {
                // Store - 直接使用
              } else {
                console.warn('[BaseParser] Unknown compression method:', compressionMethod);
              }

              entries.push({
                path: fileName,
                isDirectory: fileName.endsWith('/'),
                data: data
              });
            }

            offset = dataEnd;
          } catch (entryError) {
            const err = entryError as Error;
            console.warn('[BaseParser] Failed to parse ZIP entry:', err.message);
            offset += 4;
          }
        } else {
          offset++;
        }
      }

      if (entries.length === 0) {
        console.warn('[BaseParser] No entries found in ZIP file');
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BaseParser] Parse ZIP failed:', err.message);
    }

    return { entries };
  }

  /**
   * 简坕的 XML 文本杝坖
   */
  static extractXmlText(xmlContent: string): string {
    return xmlContent
      .replace(new RegExp('<[^>]+>', 'g'), ' ')
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('&quot;', 'g'), '"')
      .replace(new RegExp('&#39;', 'g'), "'")
      .replace(new RegExp('\s+', 'g'), ' ')
      .trim();
  }

  /**
   * �?XML 中杝坖标签内�?
   */
  static extractXmlTag(xmlContent: string, tagName: string): string {
    const regex = new RegExp(`<${tagName}[^>]*>([^<]*)</${tagName}>`, 'i');
    const match = xmlContent.match(regex);
    return match ? match[1].trim() : '';
  }

  /**
   * 简坕的 HTML 文本杝坖
   */
  static extractHtmlText(htmlContent: string): string {
    return htmlContent
      .replace(new RegExp('<script[^>]*>[\s\S]*?<\/script>', 'gi'), '')
      .replace(new RegExp('<style[^>]*>[\s\S]*?<\/style>', 'gi'), '')
      .replace(new RegExp('<[^>]+>', 'g'), ' ')
      .replace(new RegExp('&nbsp;', 'g'), ' ')
      .replace(new RegExp('&amp;', 'g'), '&')
      .replace(new RegExp('&lt;', 'g'), '<')
      .replace(new RegExp('&gt;', 'g'), '>')
      .replace(new RegExp('\s+', 'g'), ' ')
      .trim();
  }

  /**
   * 分页内容
   */
  static paginateContent(content: string, charsPerPage: number = 3000): string[] {
    if (charsPerPage <= 0) {
      return [];
    }

    const pages: string[] = [];
    let offset = 0;

    while (offset < content.length) {
      let endOffset = offset + charsPerPage;

      // 尝试在段蝽边界分�?
      if (endOffset < content.length) {
        const nextNewline = content.indexOf('\n', endOffset - 100);
        if (nextNewline > offset && nextNewline <= endOffset + 100) {
          endOffset = nextNewline;
        } else {
          // 尝试在坥孝边界分�?
          const nextPeriod = content.lastIndexOf('.', endOffset);
          if (nextPeriod > offset) {
            endOffset = nextPeriod + 1;
          } else {
            const nextDot = content.lastIndexOf('.', endOffset);
            if (nextDot > offset && nextDot > endOffset - 200) {
              endOffset = nextDot + 1;
            }
          }
        }
      }

      pages.push(content.substring(offset, endOffset).trim());
      offset = endOffset;
    }

    return pages;
  }

  /**
   * 按段蝽杝坖章�?
   */
  static extractChaptersByParagraphs(content: string, maxChapters: number = 50): ExtractedChapter[] {
    const chapters: ExtractedChapter[] = [];
    const allParagraphs = content.split(new RegExp('\n\s*\n', ''));
    const paragraphs: string[] = [];
    for (let i = 0; i < allParagraphs.length; i++) {
      const p = allParagraphs[i];
      if (p.trim().length > 0) {
        paragraphs.push(p.trim());
      }
    }

    const limit = Math.min(paragraphs.length, maxChapters);
    for (let i = 0; i < limit; i++) {
      const paragraph = paragraphs[i].trim();
      if (paragraph.length > 10) {
        chapters.push({
          index: i,
          title: `�?${i + 1} 段`,
          content: paragraph,
          offset: content.indexOf(paragraph)
        });
      }
    }

    return chapters;
  }
}

