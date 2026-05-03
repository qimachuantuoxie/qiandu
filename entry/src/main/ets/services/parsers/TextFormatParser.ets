/**
 * 文本格式解析�?- 处理纯文本和简单文本格�?
 * Text Format Parser - Handles plain text and simple text formats
 * 
 * 支持格式：TXT, RTF, HTML
 */

import { BaseParserUtils } from './BaseParserUtils';
import { DocumentFormat, ChapterInfo, ParseResult, ParserConfig } from '../models/DocumentModels';
import { util } from '@kit.ArkTS';

/**
 * 文本格式解析�?
 */
export class TextFormatParser {

  // ==================== TXT 解析 ====================

  /**
   * 解析 TXT 文档
   */
  static async parseTXT(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[TextParser] Parsing TXT:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      
      // 检测编�?
      const encoding = TextFormatParser.detectEncoding(uint8Array);
      const decoder = new util.TextDecoder(encoding);
      let content = decoder.decodeWithStream(uint8Array);

      // 清理 BOM
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }

      // 规范化换行符
      content = content.replace(new RegExp('\r\n', 'g'), '\n').replace(new RegExp('\r', 'g'), '\n');

      // 提取标题（第一行）
      const firstLine = content.split('\n')[0].trim();
      const title = firstLine.length > 0 && firstLine.length < 100 ? firstLine : BaseParserUtils.extractFileName(filePath);

      // 提取章节
      const chapters = config.extractChapters ? TextFormatParser.extractTXTChapters(content) : [];

      // 分页
      const pages = config.paginate ? BaseParserUtils.paginateContent(content, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: TextFormatParser.extractAuthor(content),
          language: 'zh-CN',
          pageCount: pages.length,
          wordCount: content.length,
          format: DocumentFormat.TXT,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? content : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[TextParser] TXT parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 检测文本编码（增强版）
   * 支持 UTF-8, UTF-16, GBK, GB2312, BIG5 等编�?
   */
  private static detectEncoding(uint8Array: Uint8Array): string {
    if (uint8Array.length < 2) return 'utf-8';

    // BOM 检�?
    // UTF-8 BOM: EF BB BF
    if (uint8Array.length >= 3 &&
        uint8Array[0] === 0xEF && uint8Array[1] === 0xBB && uint8Array[2] === 0xBF) {
      return 'utf-8';
    }
    // UTF-16 LE BOM: FF FE
    if (uint8Array.length >= 2 &&
        uint8Array[0] === 0xFF && uint8Array[1] === 0xFE) {
      return 'utf-16le';
    }
    // UTF-16 BE BOM: FE FF
    if (uint8Array.length >= 2 &&
        uint8Array[0] === 0xFE && uint8Array[1] === 0xFF) {
      return 'utf-16be';
    }
    // UTF-32 LE BOM: FF FE 00 00
    if (uint8Array.length >= 4 &&
        uint8Array[0] === 0xFF && uint8Array[1] === 0xFE &&
        uint8Array[2] === 0x00 && uint8Array[3] === 0x00) {
      return 'utf-32le';
    }
    // UTF-32 BE BOM: 00 00 FE FF
    if (uint8Array.length >= 4 &&
        uint8Array[0] === 0x00 && uint8Array[1] === 0x00 &&
        uint8Array[2] === 0xFE && uint8Array[3] === 0xFF) {
      return 'utf-32be';
    }

    // �?BOM 编码检测（基于字节统计�?
    const sampleSize = Math.min(uint8Array.length, 10000);
    let asciiCount = 0;
    let utf8SequenceCount = 0;
    let gbkCandidateCount = 0;
    let invalidUtf8Count = 0;

    for (let i = 0; i < sampleSize; i++) {
      const byte = uint8Array[i];

      if (byte === 0x00) {
        // 空字节可能是 UTF-16
        return 'utf-16le';
      }

      if (byte <= 0x7F) {
        asciiCount++;
        continue;
      }

      // 检�?UTF-8 多字节序�?
      if (byte >= 0xC0 && byte <= 0xDF && i + 1 < sampleSize) {
        if (uint8Array[i + 1] >= 0x80 && uint8Array[i + 1] <= 0xBF) {
          utf8SequenceCount++;
          i++;
          continue;
        }
      }
      if (byte >= 0xE0 && byte <= 0xEF && i + 2 < sampleSize) {
        if (uint8Array[i + 1] >= 0x80 && uint8Array[i + 1] <= 0xBF &&
            uint8Array[i + 2] >= 0x80 && uint8Array[i + 2] <= 0xBF) {
          utf8SequenceCount++;
          i += 2;
          continue;
        }
      }
      if (byte >= 0xF0 && byte <= 0xF7 && i + 3 < sampleSize) {
        if (uint8Array[i + 1] >= 0x80 && uint8Array[i + 1] <= 0xBF &&
            uint8Array[i + 2] >= 0x80 && uint8Array[i + 2] <= 0xBF &&
            uint8Array[i + 3] >= 0x80 && uint8Array[i + 3] <= 0xBF) {
          utf8SequenceCount++;
          i += 3;
          continue;
        }
      }

      // 检测可能的 GBK 双字节（高字�?>= 0x81，低字节 >= 0x40�?
      if (byte >= 0x81 && byte <= 0xFE && i + 1 < sampleSize) {
        const lowByte = uint8Array[i + 1];
        if ((lowByte >= 0x40 && lowByte <= 0x7E) || (lowByte >= 0x80 && lowByte <= 0xFE)) {
          gbkCandidateCount++;
          i++;
          continue;
        }
      }

      // 如果既不�?UTF-8 也不�?GBK，则是无效序�?
      if (byte >= 0x80) {
        invalidUtf8Count++;
      }
    }

    // 根据统计判断编码
    const nonAsciiCount = sampleSize - asciiCount;
    if (nonAsciiCount === 0) return 'ascii';

    // 如果 UTF-8 序列占大多数
    if (utf8SequenceCount > nonAsciiCount * 0.7) {
      return 'utf-8';
    }

    // 如果 GBK 候选占大多数且无效 UTF-8 �?
    if (gbkCandidateCount > nonAsciiCount * 0.5 && invalidUtf8Count < nonAsciiCount * 0.2) {
      return 'gbk';
    }

    // 默认 UTF-8
    return 'utf-8';
  }

  /**
   * 提取 TXT 章节（增强版�?
   * 支持多种章节标题模式和智能分�?
   */
  private static extractTXTChapters(content: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 扩展章节标题正则
    // 支持：第X章、第X节、Chapter X、PART X、卷X、篇X�?
    const chapterRegex = /(第[一二三四五六七八九十百千\d]+[章节卷集部篇回回幕场编]|第[一二三四五六七八九十百千\d]+[章回节]|Chapter\s+\d+|Part\s+\d+|Book\s+\d+|Volume\s+\d+|\d+\.\s+[^\n]{1,50})/gi;

    let match: RegExpExecArray | null;
    let lastIndex = 0;
    let chapterIndex = 0;

    while ((match = chapterRegex.exec(content)) !== null) {
      // 如果有前置内容，创建无名章节
      if (match.index > lastIndex) {
        const sectionContent = content.substring(lastIndex, match.index).trim();
        if (sectionContent.length > 50) { // 内容超过50字才创建章节
          chapters.push({
            index: chapterIndex++,
            title: chapters.length === 0 ? '序章' : `章节 " + chapterIndex + "`,
            content: sectionContent,
            offset: lastIndex
          });
        }
      }

      // 提取章节标题（限制长度）
      const chapterTitle = match[1].trim();
      const title = chapterTitle.length > 100 ? chapterTitle.substring(0, 100) + '...' : chapterTitle;

      lastIndex = match.index;
    }

    // 添加最后一�?
    if (lastIndex < content.length) {
      const lastContent = content.substring(lastIndex).trim();
      if (lastContent.length > 0) {
        chapters.push({
          index: chapterIndex++,
          title: chapters.length === 0 ? '全文' : `章节 " + (chapterIndex + 1) + "`,
          content: lastContent,
          offset: lastIndex
        });
      }
    }

    // 如果没有找到章节，尝试智能分�?
    if (chapters.length <= 1) {
      return TextFormatParser.smartSplitByParagraphs(content);
    }

    return chapters;
  }

  /**
   * 智能按段落分�?
   */
  private static smartSplitByParagraphs(content: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];
    
    // 按双换行符分�?
    const paragraphs = content.split(new RegExp('\n\s*\n', ''));
    
    if (paragraphs.length === 0) {
      // 如果没有分段，按单换行分
      return BaseParserUtils.extractChaptersByParagraphs(content);
    }

    // 合并短段落，避免章节过小
    const minCharsPerChapter = 500; // 每章最�?00�?
    let currentContent = '';
    let currentOffset = 0;
    let chapterIndex = 0;

    for (const paragraph of paragraphs) {
      const trimmed = paragraph.trim();
      if (trimmed.length === 0) continue;

      // 如果当前章节内容够了，创建新章节
      if (currentContent.length >= minCharsPerChapter) {
        const title = currentContent.substring(0, 50).replace(new RegExp('\n', 'g'), ' ').trim();
        chapters.push({
          index: chapterIndex++,
          title: `�?" + chapterIndex + " 部分`,
          content: currentContent.trim(),
          offset: currentOffset
        });
        currentContent = trimmed;
        currentOffset = content.indexOf(trimmed, currentOffset);
      } else {
        currentContent += (currentContent.length > 0 ? '\n\n' : '') + trimmed;
      }
    }

    // 添加最后一�?
    if (currentContent.length > 0) {
      const title = currentContent.substring(0, 50).replace(new RegExp('\n', 'g'), ' ').trim();
      chapters.push({
        index: chapterIndex++,
        title: `�?" + (chapterIndex + 1) + " 部分`,
        content: currentContent.trim(),
        offset: currentOffset
      });
    }

    return chapters.length > 0 ? chapters : BaseParserUtils.extractChaptersByParagraphs(content);
  }

  /**
   * 尝试从文本中提取作�?
   */
  private static extractAuthor(content: string): string {
    const authorPatterns = [
      new RegExp('作者[?:]\s*(.+?)(?:\n|$)', ''),
      new RegExp('著[者]?[?:]\s*(.+?)(?:\n|$)', ''),
      new RegExp('written by[? ]+(.+?)(?:\n|$)', 'i')
    ];

    for (const pattern of authorPatterns) {
      const match = content.match(pattern);
      if (match && match[1].trim().length > 0 && match[1].trim().length < 50) {
        return match[1].trim();
      }
    }

    return 'Unknown Author';
  }

  // ==================== RTF 解析 ====================

  /**
   * 解析 RTF 文档（增强版�?
   */
  static async parseRTF(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[TextParser] Parsing RTF:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      const decoder = new util.TextDecoder('ascii');
      let rtfContent = decoder.decodeWithStream(uint8Array);

      // 增强�?RTF 解析
      rtfContent = TextFormatParser.decodeRTFUnicode(rtfContent);
      rtfContent = TextFormatParser.stripRTFTags(rtfContent);
      rtfContent = rtfContent
        .replace(new RegExp('\r\n', 'g'), '\n')
        .replace(new RegExp('\n{3,}', 'g'), '\n\n')
        .trim();

      const titleMatch = rtfContent.match(new RegExp('^([^\n]{1,100})', ''));
      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);
      const chapters = config.extractChapters ? TextFormatParser.extractRTFChapters(rtfContent) : [];
      const pages = config.paginate ? BaseParserUtils.paginateContent(rtfContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: 'Unknown Author',
          language: 'zh-CN',
          pageCount: pages.length,
          wordCount: rtfContent.length,
          format: DocumentFormat.RTF,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? rtfContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      console.error('[TextParser] RTF parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 解码 RTF Unicode 转义序列
   */
  private static decodeRTFUnicode(content: string): string {
    return content.replace(new RegExp("\\\\'([0-9a-fA-F]{2})", 'g'), (match: string, hex: string): string => {
      try {
        const code = parseInt(hex, 16);
        return String.fromCharCode(code);
      } catch (error) {
        return match;
      }
    });
  }

  /**
   * 去除 RTF 标签（支持嵌套）
   */
  private static stripRTFTags(content: string): string {
    let result = '';
    let depth = 0;
    let i = 0;

    while (i < content.length) {
      const char = content[i];

      if (char === '{') {
        depth++;
        i++;
      } else if (char === '}') {
        depth--;
        i++;
      } else if (char === '\\' && depth <= 1) {
        i++;
        while (i < content.length && new RegExp('[a-zA-Z]').test(content[i])) {
          i++;
        }
        while (i < content.length && new RegExp('[0-9-]').test(content[i])) {
          i++;
        }
        if (i < content.length && new RegExp('[^a-zA-Z0-9]').test(content[i])) {
          i++;
        }
      } else if (depth <= 1) {
        result += char;
        i++;
      } else {
        i++;
      }
    }

    return result;
  }

  /**
   * 提取 RTF 章节
   */
  private static extractRTFChapters(content: string): ChapterInfo[] {
    return BaseParserUtils.extractChaptersByParagraphs(content);
  }

  // ==================== HTML 解析 ====================

  /**
   * 解析 HTML 文档（增强版�?
   */
  static async parseHTML(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    console.info('[TextParser] Parsing HTML:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      
      // 检测编�?
      const encoding = TextFormatParser.detectHTMLEncoding(uint8Array);
      const decoder = new util.TextDecoder(encoding);
      const htmlContent = decoder.decodeWithStream(uint8Array);

      // 提取文本内容
      const textContent = BaseParserUtils.extractHtmlText(htmlContent);

      // 提取标题
      const titleMatch = htmlContent.match(new RegExp('<title[^>]*>([^<]+)<\/title>', 'i')) ||
                        htmlContent.match(new RegExp('<h1[^>]*>([^<]+)<\/h1>', 'i'));
      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);

      const authorNamePattern = new RegExp('<meta[^>]+name=["' + "'" + ']author["' + "'" + '"][^>]+content=["' + "'" + ']([^"' + "'" + ']+)["' + "'" + ']', 'i');
      const authorContentPattern = new RegExp('<meta[^>]+content=["' + "'" + ']([^"' + "'" + ']+)["' + "'" + '"][^>]+name=["' + "'" + ']author["' + "'" + ']', 'i');
      const authorMatch = htmlContent.match(authorNamePattern) ||
                         htmlContent.match(authorContentPattern);
      const author: string = authorMatch ? authorMatch[1].trim() : 'Unknown Author';

      const descPattern = new RegExp('<meta[^>]+name=["' + "'" + ']description["' + "'" + '"][^>]+content=["' + "'" + ']([^"' + "'" + ']+)["' + "'" + ']', 'i');
      const descMatch = htmlContent.match(descPattern);
      const description: string | undefined = descMatch ? descMatch[1].trim() : undefined;

      const chapters = config.extractChapters ? TextFormatParser.extractHTMLChapters(htmlContent) : [];
      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: author,
          language: TextFormatParser.detectHTMLLang(htmlContent) || 'zh-CN',
          pageCount: pages.length,
          wordCount: textContent.length,
          format: DocumentFormat.HTML,
          fileSize: buffer.byteLength,
          description: description
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      console.error('[TextParser] HTML parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 检�?HTML 编码
   */
  private static detectHTMLEncoding(uint8Array: Uint8Array): string {
    // 检�?BOM
    if (uint8Array.length >= 3 &&
        uint8Array[0] === 0xEF && uint8Array[1] === 0xBB && uint8Array[2] === 0xBF) {
      return 'utf-8';
    }

    // 检�?meta charset
    const sampleBytes = uint8Array.slice(0, 1000);
    let sample = '';
    for (let i = 0; i < sampleBytes.length; i++) {
      sample += String.fromCharCode(sampleBytes[i]);
    }
    const charsetMatch = sample.match(new RegExp('charset=["\']?([^"\'\s>]+)', 'i'));
    if (charsetMatch) {
      return charsetMatch[1].toLowerCase();
    }

    return 'utf-8';
  }

  /**
   * 检�?HTML 语言
   */
  private static detectHTMLLang(htmlContent: string): string | undefined {
    const langMatch = htmlContent.match(new RegExp('<html[^>]+lang=["\']([^"\']+)["\']', 'i')) ||
                     htmlContent.match(new RegExp('<html[^>]+xml:lang=["\']([^"\']+)["\']', 'i'));
    return langMatch ? langMatch[1] : undefined;
  }

  /**
   * 提取 HTML 章节（增强版 - 支持多级标题�?
   */
  private static extractHTMLChapters(htmlContent: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配 h1-h6 标题
    const headingRegex = new RegExp('<(h[1-6])[^>]*>([\s\S]*?)<\\/\\1>', 'gi');
    let match: RegExpExecArray | null;
    let lastOffset = 0;

    while ((match = headingRegex.exec(htmlContent)) !== null) {
      const level = parseInt(match[1].substring(1));
      const title = match[2].replace(new RegExp('<[^>]+>', 'g'), ' ').replace(new RegExp('&nbsp;', 'g'), ' ').trim();

      if (title.length > 0 && title.length < 200) {
        chapters.push({
          index: chapters.length,
          title: title,
          content: '',
          offset: match.index
        });
      }
    }

    // 如果没有找到标题，尝试按段落分段
    if (chapters.length === 0) {
      const textContent = BaseParserUtils.extractHtmlText(htmlContent);
      return BaseParserUtils.extractChaptersByParagraphs(textContent);
    }

    return chapters;
  }
}





