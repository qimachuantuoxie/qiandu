/**
 * 其他格式解析器 - 处理特殊格式
 * Other Format Parser - Handles special formats
 *
 * 支持格式：PDF, DOC, DJVU, CHM, CBR
 */

import { fileIo } from '@kit.CoreFileKit';
import { BaseParserUtils } from './BaseParserUtils';
import { DocumentFormat, ChapterInfo, ParseResult, ParserConfig } from '../models/DocumentModels';

/**
 * 元数据类型
 */
interface PartialPDFMetadata {
  title?: string;
  author?: string;
  subject?: string;
  pageCount?: number;
}

/**
 * 其他格式解析器
 */
export class OtherFormatParser {

  // ==================== PDF 解析 ====================

  /**
   * 解析 PDF 文档（增强版）
   */
  static async parsePDF(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[OtherParser] Parsing PDF:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查 PDF 文件头
      if (uint8Array.length < 5 ||
          uint8Array[0] !== 0x25 || uint8Array[1] !== 0x50 ||
          uint8Array[2] !== 0x44 || uint8Array[3] !== 0x46) {
        return {
          success: false,
          error: 'Invalid PDF file header'
        };
      }

      // 尝试提取元数据
      const metadata = OtherFormatParser.extractPDFMetadata(uint8Array);

      // 提取文本内容
      const textContent = OtherFormatParser.extractPDFText(uint8Array);

      // 提取大纲/书签
      const outline = config.extractChapters ? OtherFormatParser.extractPDFOutline(uint8Array) : [];

      // 估算页数（基于文本长度）
      const estimatedPages = Math.max(1, Math.ceil(textContent.length / 3000));
      const pageCount = metadata.pageCount !== undefined ? metadata.pageCount : estimatedPages;

      // 创建章节（优先使用大纲，否则按段落）
      const chapters = outline.length > 0 ? outline :
        BaseParserUtils.extractChaptersByParagraphs(textContent);

      // 分页
      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: metadata.title !== undefined ? metadata.title : BaseParserUtils.extractFileName(filePath),
          author: metadata.author !== undefined ? metadata.author : 'Unknown Author',
          pageCount: pages.length > 0 ? pages.length : pageCount,
          wordCount: textContent.length,
          format: DocumentFormat.PDF,
          fileSize: buffer.byteLength,
          description: metadata.subject
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[OtherParser] PDF parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 提取 PDF 元数据
   */
  private static extractPDFMetadata(uint8Array: Uint8Array): PartialPDFMetadata {
    const metadata: PartialPDFMetadata = {
      title: undefined,
      author: undefined,
      subject: undefined,
      pageCount: undefined
    };

    try {
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }

      // 尝试从 Info 字典提取元数据
      const titleMatch = content.match(new RegExp('\\/Title\s*\(([^)]*)\)', ''));
      const authorMatch = content.match(new RegExp('\\/Author\s*\(([^)]*)\)', ''));
      const subjectMatch = content.match(new RegExp('\\/Subject\s*\(([^)]*)\)', ''));
      const creatorMatch = content.match(new RegExp('\\/Creator\s*\(([^)]*)\)', ''));

      if (titleMatch) metadata.title = titleMatch[1].trim();
      if (authorMatch) metadata.author = authorMatch[1].trim();
      if (subjectMatch) metadata.subject = subjectMatch[1].trim();

      // 尝试估算页数（通过 /Type /Page 计数）
      const pageMatches = content.match(new RegExp('\\/Type\s*\/Page[^s]', 'g'));
      if (pageMatches) {
        metadata.pageCount = pageMatches.length;
      }
    } catch (error) {
      const err = error as Error;
      console.warn('[OtherParser] PDF metadata extraction failed:', err.message);
    }

    return metadata;
  }

  /**
   * 从 PDF 中提取文本（增强版）
   */
  private static extractPDFText(uint8Array: Uint8Array): string {
    const textParts: string[] = [];
    let currentText = '';
    let inTextStream = false;
    let inStream = false;
    let streamStart = 0;

    for (let i = 0; i < uint8Array.length; i++) {
      const byte = uint8Array[i];

      // 检测 stream 开始
      if (!inStream && byte === 0x73 && i + 6 < uint8Array.length) {
        const streamKeyword = String.fromCharCode(
          uint8Array[i], uint8Array[i+1], uint8Array[i+2],
          uint8Array[i+3], uint8Array[i+4], uint8Array[i+5]
        );
        if (streamKeyword === 'stream') {
          inStream = true;
          streamStart = i + 7; // 跳过 "stream" 和换行
          i += 6;
          continue;
        }
      }

      // 检测 endstream
      if (inStream && byte === 0x65 && i + 9 < uint8Array.length) {
        const endstreamKeyword = String.fromCharCode(
          uint8Array[i], uint8Array[i+1], uint8Array[i+2], uint8Array[i+3],
          uint8Array[i+4], uint8Array[i+5], uint8Array[i+6], uint8Array[i+7],
          uint8Array[i+8], uint8Array[i+9]
        );
        if (endstreamKeyword === 'endstream') {
          inStream = false;
          i += 9;
          continue;
        }
      }

      // 只在文本流内处理
      if (!inStream) continue;

      // 查找 BT (Begin Text)
      if (byte === 0x42 && i + 1 < uint8Array.length && uint8Array[i + 1] === 0x54) {
        // 检查是否是独立的 BT 操作符（前后有空白或括号）
        const prevChar = i > 0 ? uint8Array[i - 1] : 0;
        const nextChar = i + 2 < uint8Array.length ? uint8Array[i + 2] : 0;
        if ((prevChar === 0 || prevChar === 0x0A || prevChar === 0x0D || prevChar === 0x20) &&
            (nextChar === 0x0A || nextChar === 0x0D || nextChar === 0x20)) {
          inTextStream = true;
          i++;
          continue;
        }
      }

      // 查找 ET (End Text)
      if (byte === 0x45 && i + 1 < uint8Array.length && uint8Array[i + 1] === 0x54) {
        const prevChar = i > 0 ? uint8Array[i - 1] : 0;
        const nextChar = i + 2 < uint8Array.length ? uint8Array[i + 2] : 0;
        if ((prevChar === 0 || prevChar === 0x0A || prevChar === 0x0D || prevChar === 0x20) &&
            (nextChar === 0x0A || nextChar === 0x0D || nextChar === 0x20 || nextChar === 0)) {
          if (currentText.trim().length > 2) {
            textParts.push(currentText.trim());
          }
          currentText = '';
          inTextStream = false;
          i++;
          continue;
        }
      }

      // 在文本对象内，提取字符串
      if (inTextStream && byte === 0x28) { // ( 开始字符串
        let str = '';
        let escape = false;
        i++;
        while (i < uint8Array.length) {
          if (escape) {
            const escaped = uint8Array[i];
            if (escaped === 0x6E) str += '\n';
            else if (escaped === 0x72) str += '\r';
            else if (escaped === 0x74) str += '\t';
            else if (escaped === 0x28 || escaped === 0x29 || escaped === 0x5C) {
              str += String.fromCharCode(escaped);
            } else if (escaped >= 0x30 && escaped <= 0x39) {
              // 八进制转义
              let octal = String.fromCharCode(escaped);
              i++;
              if (i < uint8Array.length && uint8Array[i] >= 0x30 && uint8Array[i] <= 0x39) {
                octal += String.fromCharCode(uint8Array[i]);
                i++;
                if (i < uint8Array.length && uint8Array[i] >= 0x30 && uint8Array[i] <= 0x39) {
                  octal += String.fromCharCode(uint8Array[i]);
                }
              }
              str += String.fromCharCode(parseInt(octal, 8));
              continue;
            } else {
              str += String.fromCharCode(escaped);
            }
            escape = false;
            i++;
            continue;
          }

          if (uint8Array[i] === 0x5C) { // \ 转义
            escape = true;
            i++;
            continue;
          }

          if (uint8Array[i] === 0x29) { // ) 结束
            break;
          }

          str += String.fromCharCode(uint8Array[i]);
          i++;
        }
        currentText += str;
      } else if (inTextStream && byte === 0x3C) { // < 十六进制字符串开始
        let hexStr = '';
        i++;
        while (i < uint8Array.length && uint8Array[i] !== 0x3E) {
          const char = String.fromCharCode(uint8Array[i]);
          if (new RegExp('[0-9a-fA-F]').test(char)) {
            hexStr += char;
          }
          i++;
        }
        // 解码十六进制字符串
        for (let j = 0; j < hexStr.length; j += 2) {
          const hex = hexStr.substring(j, j + 2);
          if (hex.length === 2) {
            currentText += String.fromCharCode(parseInt(hex, 16));
          }
        }
      } else if (inTextStream && (byte >= 0x20 && byte <= 0x7E)) {
        // 直接文本字符
        currentText += String.fromCharCode(byte);
      }
    }

    // 清理和解码文本
    const cleanedText = textParts
      .join('\n')
      .replace(new RegExp('\s+', 'g'), ' ')
      .replace(/([。！？!?])\s*/g, '$1\n') // 在标点后换行
      .trim();

    return cleanedText;
  }

  /**
   * 提取 PDF 大纲/书签
   */
  private static extractPDFOutline(uint8Array: Uint8Array): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    try {
      let content = '';
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i]);
      }

      // 尝试查找 Outline 结构
      // 简化版：查找 /Title 和 /Dest 或 /A 的组合
      const outlineRegex = new RegExp('\\/Title\s*\(([^)]*)\)', 'g');
      let match: RegExpExecArray | null;
      let level = 0;

      while ((match = outlineRegex.exec(content)) !== null) {
        const title = match[1].trim();
        const dest = match[2] || match[3];

        if (title.length > 0 && title.length < 200) {
          // 尝试从标题缩进判断层级
          const currentLevel = title.startsWith('  ') ? 1 : 0;

          chapters.push({
            index: chapters.length,
            title: title.replace(/^\s+/, ''), // 去除前导空格
            content: '',
            offset: match.index
          });
        }
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.warn('[OtherParser] PDF outline extraction failed:', err.message);
    }

    return chapters;
  }

  // ==================== DOC 解析 ====================

  /**
   * 解析 DOC 文档（OLE格式）
   */
  static async parseDOC(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[OtherParser] Parsing DOC:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查 OLE 文件头
      if (uint8Array.length < 8 ||
          uint8Array[0] !== 0xD0 || uint8Array[1] !== 0xCF ||
          uint8Array[2] !== 0x11 || uint8Array[3] !== 0xE0) {
        return {
          success: false,
          error: 'Invalid OLE file header'
        };
      }

      const textContent = OtherFormatParser.extractDOCText(uint8Array);
      const cleanedText = textContent
        .replace(new RegExp('[^\x20-\x7E\u4e00-\u9fa5\n\r\t]', 'g'), ' ')
        .replace(new RegExp('\s+', 'g'), ' ')
        .trim();

      if (cleanedText.length === 0) {
        return {
          success: true,
          metadata: {
            title: BaseParserUtils.extractFileName(filePath),
            author: 'Unknown Author',
            language: 'zh-CN',
            pageCount: 0,
            wordCount: 0,
            format: DocumentFormat.DOC,
            fileSize: buffer.byteLength
          },
          warnings: ['DOC format parsing is limited, no text extracted']
        };
      }

      const titleMatch = cleanedText.match(new RegExp('^(.{1,100})', ''));
      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);

      const chapters = config.extractChapters ? BaseParserUtils.extractChaptersByParagraphs(cleanedText) : [];
      const pages = config.paginate ? BaseParserUtils.paginateContent(cleanedText, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: 'Unknown Author',
          language: 'zh-CN',
          pageCount: pages.length,
          wordCount: cleanedText.length,
          format: DocumentFormat.DOC,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? cleanedText : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      console.error('[OtherParser] DOC parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 从 DOC 文件中提取文本
   */
  private static extractDOCText(uint8Array: Uint8Array): string {
    const textParts: string[] = [];
    let currentText = '';

    for (let i = 0; i < uint8Array.length; i++) {
      const byte = uint8Array[i];

      if ((byte >= 0x20 && byte <= 0x7E) || byte >= 0x80) {
        if (byte >= 0x80 && i + 1 < uint8Array.length) {
          if (byte >= 0xE0 && byte <= 0xEF && i + 2 < uint8Array.length) {
            const codePoint = ((byte & 0x0F) << 12) |
                             ((uint8Array[i + 1] & 0x3F) << 6) |
                             (uint8Array[i + 2] & 0x3F);
            currentText += String.fromCharCode(codePoint);
            i += 2;
          } else if (byte >= 0xC0 && byte <= 0xDF) {
            const codePoint = ((byte & 0x1F) << 6) | (uint8Array[i + 1] & 0x3F);
            currentText += String.fromCharCode(codePoint);
            i += 1;
          } else {
            currentText += String.fromCharCode(byte);
          }
        } else {
          currentText += String.fromCharCode(byte);
        }
      } else if (byte === 0x0A || byte === 0x0D) {
        if (currentText.trim().length > 10) {
          textParts.push(currentText.trim());
        }
        currentText = '';
      } else if (byte === 0x00 || byte === 0x09) {
        if (currentText.trim().length > 10) {
          textParts.push(currentText.trim());
        }
        currentText = '';
      }
    }

    if (currentText.trim().length > 10) {
      textParts.push(currentText.trim());
    }

    return textParts.join('\n\n');
  }

  // ==================== DJVU 解析 ====================

  /**
   * 解析 DJVU 文档
   */
  static async parseDJVU(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[OtherParser] Parsing DJVU:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查 DJVU 文件头 (AT&TFORM)
      if (uint8Array.length < 4 ||
          uint8Array[0] !== 0x41 || uint8Array[1] !== 0x54 ||
          uint8Array[2] !== 0x26 || uint8Array[3] !== 0x54) {
        return {
          success: false,
          error: 'Invalid DJVU file header'
        };
      }

      const fileName = BaseParserUtils.extractFileName(filePath);

      return {
        success: true,
        metadata: {
          title: fileName,
          author: 'Unknown Author',
          language: 'zh-CN',
          pageCount: 0,
          wordCount: 0,
          format: DocumentFormat.DJVU,
          fileSize: buffer.byteLength
        },
        warnings: ['DJVU format requires djvulibre library for full text extraction']
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[OtherParser] DJVU parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  // ==================== CHM 解析 ====================

  /**
   * 解析 CHM 文档
   */
  static async parseCHM(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[OtherParser] Parsing CHM:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查 CHM 文件头 (ITSF)
      if (uint8Array.length < 4 ||
          uint8Array[0] !== 0x49 || uint8Array[1] !== 0x54 ||
          uint8Array[2] !== 0x53 || uint8Array[3] !== 0x46) {
        return {
          success: false,
          error: 'Invalid CHM file header'
        };
      }

      // 提取版本信息
      const version = uint8Array.length > 8 ?
        (uint8Array[4] | (uint8Array[5] << 8) | (uint8Array[6] << 16) | (uint8Array[7] << 24)) : 0;

      const fileName = BaseParserUtils.extractFileName(filePath);

      return {
        success: true,
        metadata: {
          title: fileName,
          author: 'Unknown Author',
          language: 'zh-CN',
          pageCount: 0,
          wordCount: 0,
          format: DocumentFormat.CHM,
          fileSize: buffer.byteLength
        },
        warnings: ['CHM format version ' + version + ' requires chmlib library for full content extraction']
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[OtherParser] CHM parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  // ==================== CBR 解析 ====================

  /**
   * 解析 CBR 漫画文档（RAR 格式）
   */
  static async parseCBR(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[OtherParser] Parsing CBR:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查 RAR 文件头
      if (uint8Array.length < 7 ||
          uint8Array[0] !== 0x52 || uint8Array[1] !== 0x61 ||
          uint8Array[2] !== 0x72 || uint8Array[3] !== 0x21 ||
          uint8Array[4] !== 0x1A || uint8Array[5] !== 0x07) {
        return {
          success: false,
          error: 'Invalid RAR file header'
        };
      }

      const fileName = BaseParserUtils.extractFileName(filePath);

      // CBR 解析需要 RAR 解压库
      // 当前返回基本元数据
      return {
        success: true,
        metadata: {
          title: fileName,
          author: 'Unknown Author',
          language: 'N/A',
          pageCount: 0,
          wordCount: 0,
          format: DocumentFormat.CBR,
          fileSize: buffer.byteLength
        },
        warnings: ['CBR format requires unrar library for image extraction']
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[OtherParser] CBR parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }
}


