import { logger } from '../../../utils/Logger';
/**
 * XML 格式解析器 - 处理基于 XML 的文档格式
 * XML Format Parser - Handles XML-based document formats
 *
 * 支持格式：FB2, MOBI, AZW, AZW3
 */

import { BaseParserUtils } from './BaseParserUtils';
import { DocumentFormat, ChapterInfo, ParseResult, ParserConfig } from '../models/DocumentModels';
import { util } from '@kit.ArkTS';

/**
 * 元数据类型
 */
interface PartialFB2Metadata {
  title?: string;
  author?: string;
  language?: string;
}

/**
 * XML 格式解析器
 */
export class XmlFormatParser {

  // ==================== FB2 解析 ====================

  /**
   * 解析 FB2 文档 (FictionBook 2)
   */
  static async parseFB2(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    logger.info('[XmlParser] Parsing FB2:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
      const xmlContent = decoder.decode(uint8Array);

      // 提取元数据
      const metadata = XmlFormatParser.extractFB2Metadata(xmlContent);

      // 提取正文内容
      const bodyContent = XmlFormatParser.extractFB2Body(xmlContent);

      // 提取章节
      const chapters = config.extractChapters ? XmlFormatParser.extractFB2Chapters(xmlContent) : [];

      // 分页
      const pages = config.paginate ? BaseParserUtils.paginateContent(bodyContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: metadata.title ? metadata.title : 'Unknown Title',
          author: metadata.author ? metadata.author : 'Unknown Author',
          language: metadata.language ? metadata.language : 'zh-CN',
          pageCount: pages.length,
          wordCount: bodyContent.length,
          format: DocumentFormat.FB2,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? bodyContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[XmlParser] FB2 parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 提取 FB2 元数据
   */
  private static extractFB2Metadata(xmlContent: string): PartialFB2Metadata {
    const titleMatch = xmlContent.match(new RegExp('<book-title>([^<]+)<\/book-title>', 'i'));
    const firstNameMatch = xmlContent.match(new RegExp('<first-name>([^<]+)<\/first-name>', 'i'));
    const lastNameMatch = xmlContent.match(new RegExp('<last-name>([^<]+)<\/last-name>', 'i'));
    const langMatch = xmlContent.match(new RegExp('<lang>([^<]+)<\/lang>', 'i'));

    const firstName = firstNameMatch ? firstNameMatch[1] : '';
    const lastName = lastNameMatch ? lastNameMatch[1] : '';
    const author = (firstName + ' ' + lastName).trim() || 'Unknown Author';

    return {
      title: titleMatch ? titleMatch[1].trim() : 'Unknown Title',
      author: author,
      language: langMatch ? langMatch[1].trim() : 'zh-CN'
    };
  }

  /**
   * 提取 FB2 正文内容（增强版）
   */
  private static extractFB2Body(xmlContent: string): string {
    // 匹配所有 body 元素
    const bodyRegex = new RegExp('<body[^>]*>([\s\S]*?)<\/body>', 'gi');
    const bodies: string[] = [];
    let bodyMatch: RegExpExecArray | null;

    while ((bodyMatch = bodyRegex.exec(xmlContent)) !== null) {
      let body = bodyMatch[1];
      // 提取文本内容，保留段落结构
      body = XmlFormatParser.extractFB2SectionText(body);
      if (body.trim().length > 0) {
        bodies.push(body.trim());
      }
    }

    return bodies.join('\n\n');
  }

  /**
   * 提取 FB2 章节文本（保留段落结构）
   */
  private static extractFB2SectionText(xmlContent: string): string {
    const paragraphs: string[] = [];

    // 匹配 <p>...</p> 段落
    const pRegex = new RegExp('<p[^>]*>([\s\S]*?)<\/p>', 'gi');
    let pMatch: RegExpExecArray | null;

    while ((pMatch = pRegex.exec(xmlContent)) !== null) {
      let text = pMatch[1];
      // 处理内部标签
      text = text.replace(new RegExp('<[^>]+>', 'g'), ' ');
      text = text.replace(new RegExp('&nbsp;', 'g'), ' ');
      text = text.replace(new RegExp('&amp;', 'g'), '&');
      text = text.replace(new RegExp('&lt;', 'g'), '<');
      text = text.replace(new RegExp('&gt;', 'g'), '>');
      text = text.replace(new RegExp('&#\d+;', 'g'), (match: string): string => {
        const code = parseInt(match.substring(2, match.length - 1));
        return String.fromCharCode(code);
      });
      text = text.replace(new RegExp('\s+', 'g'), ' ').trim();

      if (text.length > 0) {
        paragraphs.push(text);
      }
    }

    // 如果没有找到段落，尝试提取所有文本
    if (paragraphs.length === 0) {
      let text = xmlContent.replace(new RegExp('<[^>]+>', 'g'), ' ');
      text = text.replace(new RegExp('&nbsp;', 'g'), ' ');
      text = text.replace(new RegExp('&amp;', 'g'), '&');
      text = text.replace(new RegExp('&lt;', 'g'), '<');
      text = text.replace(new RegExp('&gt;', 'g'), '>');
      text = text.replace(new RegExp('\s+', 'g'), ' ').trim();
      return text;
    }

    return paragraphs.join('\n\n');
  }

  /**
   * 提取 FB2 章节（增强版）
   */
  private static extractFB2Chapters(xmlContent: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配 <section> 元素
    const sectionRegex = new RegExp('<section[^>]*>([\s\S]*?)<\/section>', 'gi');
    let match: RegExpExecArray | null;

    while ((match = sectionRegex.exec(xmlContent)) !== null) {
      const sectionContent = match[1];

      // 尝试提取标题
      const titleMatch = sectionContent.match(new RegExp('<title[^>]*>([\s\S]*?)<\/title>', 'i'));
      let title = '';

      if (titleMatch) {
        title = titleMatch[1].replace(new RegExp('<[^>]+>', 'g'), ' ').trim();
        // 清理 HTML 实体
        title = title.replace(new RegExp('&nbsp;', 'g'), ' ')
                    .replace(new RegExp('&amp;', 'g'), '&')
                    .replace(new RegExp('&lt;', 'g'), '<')
                    .replace(new RegExp('&gt;', 'g'), '>')
                    .replace(new RegExp('\s+', 'g'), ' ')
                    .trim();
      }

      // 提取章节文本内容
      const textContent = XmlFormatParser.extractFB2SectionText(sectionContent);

      if (title.length > 0 || textContent.length > 100) {
        chapters.push({
          index: chapters.length,
          title: title || '章节 ' + (chapters.length + 1),
          content: textContent,
          offset: match.index
        });
      }
    }

    return chapters;
  }

  // ==================== MOBI 解析 ====================

  /**
   * 解析 MOBI 文档
   */
  static async parseMOBI(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    logger.info('[XmlParser] Parsing MOBI:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
      const content = decoder.decodeWithStream(uint8Array);

      // MOBI 文件基本解析：提取文本内容
      const plainText = content
        .replace(new RegExp('<[^>]+>', 'g'), ' ')
        .replace(new RegExp('\s+', 'g'), ' ')
        .trim();

      // 尝试提取元数据
      const titleMatch = content.match(new RegExp('<dc:title>([^<]+)<\/dc:title>', 'i'));
      const authorMatch = content.match(new RegExp('<dc:creator>([^<]+)<\/dc:creator>', 'i'));

      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);
      const author = authorMatch ? authorMatch[1].trim() : 'Unknown Author';

      const pages = config.paginate ? BaseParserUtils.paginateContent(plainText, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: author,
          language: 'zh-CN',
          pageCount: pages.length,
          wordCount: plainText.length,
          format: DocumentFormat.MOBI,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? plainText : undefined,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[XmlParser] MOBI parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  // ==================== AZW/AZW3 解析 ====================

  /**
   * 解析 AZW/AZW3 文档
   */
  static async parseAZW(filePath: string, config: ParserConfig, buffer: ArrayBuffer, format: DocumentFormat): Promise<ParseResult> {
    logger.info('[XmlParser] Parsing AZW:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      const decoder: util.TextDecoder = new util.TextDecoder('utf-8');
      const content = decoder.decodeWithStream(uint8Array);

      // AZW/AZW3 文件基本解析：提取文本内容
      const plainText = content
        .replace(new RegExp('<[^>]+>', 'g'), ' ')
        .replace(new RegExp('\s+', 'g'), ' ')
        .trim();

      // 尝试提取元数据
      const titleMatch = content.match(new RegExp('<dc:title>([^<]+)<\/dc:title>', 'i'));
      const authorMatch = content.match(new RegExp('<dc:creator>([^<]+)<\/dc:creator>', 'i'));

      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);
      const author = authorMatch ? authorMatch[1].trim() : 'Unknown Author';

      const pages = config.paginate ? BaseParserUtils.paginateContent(plainText, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: author,
          language: 'zh-CN',
          pageCount: pages.length,
          wordCount: plainText.length,
          format: format,
          fileSize: buffer.byteLength
        },
        content: config.extractContent ? plainText : undefined,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[XmlParser] AZW parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }
}




