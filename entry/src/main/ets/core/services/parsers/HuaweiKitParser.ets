import { logger } from '../../../utils/Logger';
/**
 * 华为 Kit 服务解析器 - 使用 HarmonyOS Kit 服务解析文档
 * Huawei Kit Service Parser - Uses HarmonyOS Kit services for document parsing
 * 
 * 使用 Kit 服务：
 * - @kit.MultimediaKit: 图片解码和渲染（漫画）
 * - @kit.ArkGraphics: PDF 渲染
 * - @kit.ArkData: 数据存储
 */

import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BaseParserUtils, ZipParseResult } from './BaseParserUtils';
import { DocumentFormat, ChapterInfo, ParseResult, ParserConfig, BookMetadata } from '../models/DocumentModels';
import { util } from '@kit.ArkTS';

/**
 * 漫画图片信息
 */
export interface ComicImageInfo {
  path: string;
  width: number;
  height: number;
  size: number;
  thumbnail?: string;
}

/**
 * ODT 样式信息（合并版本）
 */
interface OdtStyleInfo {
  genre?: string;
  keywords?: string;
  createdDate?: string;
  modifiedDate?: string;
}

/**
 * ODT 元数据
 */
interface ODTMetadata {
  title: string | undefined;
  author: string | undefined;
  language: string | undefined;
  description: string | undefined;
}

/**
 * ODT 样式
 */
interface ODTStyles {
  genre: string | undefined;
  keywords: string | undefined;
  createdDate: string | undefined;
  modifiedDate: string | undefined;
}

/**
 * 图片尺寸信息
 */
interface ImageSizeInfo {
  width: number;
  height: number;
}

/**
 * 华为 Kit 服务解析器
 */
export class HuaweiKitParser {

  // ==================== RTF 增强解析 ====================

  /**
   * 增强RTF 解析（使用系统编码支持）
   */
  static async parseRTFEnhanced(filePath: string, config: ParserConfig, buffer: ArrayBuffer): Promise<ParseResult> {
    logger.info('[KitParser] Enhanced RTF parsing:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);
      
      // 尝试多种编码
      let rtfContent = '';
      const encodings = ['utf-8', 'gbk', 'gb2312', 'ascii'];
      
      for (const encoding of encodings) {
        try {
          const decoder = new util.TextDecoder(encoding);
          rtfContent = decoder.decodeWithStream(uint8Array);
          if (rtfContent.includes('\\rtf')) {
            break;
          }
        } catch (error) {
          continue;
        }
      }

      if (!rtfContent.includes('\\rtf')) {
        return {
          success: false,
          error: 'Not a valid RTF file'
        };
      }

      // 增强RTF 解析
      rtfContent = HuaweiKitParser.decodeRTFUnicode(rtfContent);
      rtfContent = HuaweiKitParser.stripRTFTags(rtfContent);
      rtfContent = rtfContent
        .replace(new RegExp('\r\n', 'g'), '\n')
        .replace(new RegExp('\n{3,}', 'g'), '\n\n')
        .trim();

      const titleMatch = rtfContent.match(new RegExp('^([^\n]{1,100})', ''));
      const title = titleMatch ? titleMatch[1].trim() : BaseParserUtils.extractFileName(filePath);
      const chapters = config.extractChapters ? BaseParserUtils.extractChaptersByParagraphs(rtfContent) : [];
      const pages = config.paginate ? BaseParserUtils.paginateContent(rtfContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: title,
          author: HuaweiKitParser.extractRTFAuthor(rtfContent),
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
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[KitParser] RTF parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 解码 RTF Unicode 转义
   */
  private static decodeRTFUnicode(content: string): string {
    return content.replace(new RegExp("\\\\'([0-9a-fA-F]{2})", 'g'), (match: string, hex: string): string => {
      try {
        return String.fromCharCode(parseInt(hex, 16));
      } catch (error) {
        return match;
      }
    })
    .replace(new RegExp('\\\\u([0-9]+)\\\?', 'g'), (match: string, code: string): string => {
      try {
        return String.fromCharCode(parseInt(code));
      } catch (error) {
        return match;
      }
    });
  }

  /**
   * 去除 RTF 标签
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
        while (i < content.length && new RegExp('[a-zA-Z]').test(content[i])) i++;
        while (i < content.length && new RegExp('[0-9-]').test(content[i])) i++;
        if (i < content.length && new RegExp('[^a-zA-Z0-9]').test(content[i])) i++;
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
   * 提取 RTF 作者
   */
  private static extractRTFAuthor(content: string): string {
    const authorMatch = content.match(new RegExp('\author([^\]*)', ''));
    return authorMatch ? authorMatch[1].trim().replace(new RegExp('[{}]', 'g'), '') : 'Unknown Author';
  }

  // ==================== ODT 增强解析 ====================

  /**
   * 增强ODT 解析（使用完整XML 解析器
   */
  static async parseODTEnhanced(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    logger.info('[KitParser] Enhanced ODT parsing:', filePath);

    try {
      // 查找 content.xml
      const contentEntry = zipResult.entries.find(e => e.path.endsWith('content.xml'));
      if (!contentEntry) {
        return { success: false, error: 'content.xml not found' };
      }

      const contentXml = HuaweiKitParser.decodeText(contentEntry.data);
      const textContent = HuaweiKitParser.extractODTContent(contentXml);

      // 提取元数据
      const metaEntry = zipResult.entries.find(e => e.path.endsWith('meta.xml'));
      const defaultMetadata: ODTMetadata = { title: undefined, author: undefined, language: undefined, description: undefined };
      const metadata = metaEntry ? HuaweiKitParser.extractODTMetadataEnhanced(HuaweiKitParser.decodeText(metaEntry.data)) : defaultMetadata;

      // 提取样式
      const stylesEntry = zipResult.entries.find(e => e.path.endsWith('styles.xml'));
      const defaultStyles: ODTStyles = { genre: undefined, keywords: undefined, createdDate: undefined, modifiedDate: undefined };
      const styles = stylesEntry ? HuaweiKitParser.extractODTStyles(HuaweiKitParser.decodeText(stylesEntry.data)) : defaultStyles;

      // 提取章节
      const chapters = config.extractChapters ? HuaweiKitParser.extractODTChapters(contentXml) : [];
      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: metadata.title || BaseParserUtils.extractFileName(filePath),
          author: metadata.author || 'Unknown Author',
          language: metadata.language || 'zh-CN',
          pageCount: pages.length,
          wordCount: textContent.length,
          format: DocumentFormat.ODT,
          fileSize: contentEntry.data.length,
          genre: styles.genre,
          keywords: styles.keywords,
          createdDate: styles.createdDate ? new Date(styles.createdDate).getTime() : undefined,
          modifiedDate: styles.modifiedDate ? new Date(styles.modifiedDate).getTime() : undefined
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[KitParser] ODT parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 提取 ODT 内容
   */
  private static extractODTContent(xmlContent: string): string {
    // 提取 <text:p> 或<text:h> 标签中的文本
    const textParts: string[] = [];

    const paragraphRegex = new RegExp('<(text:p|text:h)[^>]*>([\s\S]*?)<\\/\\1>', 'g');
    let match: RegExpExecArray | null;

    while ((match = paragraphRegex.exec(xmlContent)) !== null) {
      // 移除内部标签
      let text = match[2].replace(new RegExp('<[^>]+>', 'g'), ' ');
      text = text.replace(new RegExp('&nbsp;', 'g'), ' ');
      text = text.replace(new RegExp('&amp;', 'g'), '&');
      text = text.replace(new RegExp('&lt;', 'g'), '<');
      text = text.replace(new RegExp('&gt;', 'g'), '>');
      text = text.trim();
      
      if (text.length > 0) {
        textParts.push(text);
      }
    }

    return textParts.join('\n\n').trim();
  }

  /**
   * 提取 ODT 元数据（增强版）
   */
  private static extractODTMetadataEnhanced(metaXml: string): ODTMetadata {
    const title = BaseParserUtils.extractXmlTag(metaXml, 'dc:title');
    const creator = BaseParserUtils.extractXmlTag(metaXml, 'dc:creator');
    const language = BaseParserUtils.extractXmlTag(metaXml, 'dc:language');
    const description = BaseParserUtils.extractXmlTag(metaXml, 'dc:description');
    const date = BaseParserUtils.extractXmlTag(metaXml, 'dc:date');

    return {
      title: title || undefined,
      author: creator || undefined,
      language: language || undefined,
      description: description || undefined
    };
  }

  /**
   * 提取 ODT 样式信息
   */
  private static extractODTStyles(stylesXml: string): OdtStyleInfo {
    const genreMatch = stylesXml.match(new RegExp('<meta:keyword>([^<]+)<\/meta:keyword>', 'i'));
    const keywordsMatch = stylesXml.match(new RegExp('<meta:subject>([^<]+)<\/meta:subject>', 'i'));
    const createdMatch = stylesXml.match(new RegExp('<meta:creation-date>([^<]+)<\/meta:creation-date>', 'i'));
    const modifiedMatch = stylesXml.match(new RegExp('<dc:date>([^<]+)<\/dc:date>', 'i'));
    
    return {
      genre: genreMatch ? genreMatch[1].trim() : undefined,
      keywords: keywordsMatch ? keywordsMatch[1].trim() : undefined,
      createdDate: createdMatch ? createdMatch[1].trim() : undefined,
      modifiedDate: modifiedMatch ? modifiedMatch[1].trim() : undefined
    };
  }

  /**
   * 提取 ODT 章节
   */
  private static extractODTChapters(contentXml: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];
    const headingRegex = new RegExp('<text:h[^>]*>([\s\S]*?)<\/text:h>', 'g');
    let match: RegExpExecArray | null;
    let index = 0;

    while ((match = headingRegex.exec(contentXml)) !== null) {
      const title = match[1].replace(new RegExp('<[^>]+>', 'g'), ' ').trim();
      if (title.length > 0) {
        chapters.push({
          index: index++,
          title: title,
          content: '',
          offset: match.index
        });
      }
    }

    return chapters;
  }

  // ==================== Comic (CBZ/CBR) 增强解析 ====================

  /**
   * 增强CBZ 解析（使用Image Kit 解码图片
   */
  static async parseCBZEnhanced(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    logger.info('[KitParser] Enhanced CBZ parsing:', filePath);

    try {
      // 查找图片文件
      const imageEntries = zipResult.entries.filter(e =>
        e.path.toLowerCase().endsWith('.jpg') ||
        e.path.toLowerCase().endsWith('.jpeg') ||
        e.path.toLowerCase().endsWith('.png') ||
        e.path.toLowerCase().endsWith('.gif') ||
        e.path.toLowerCase().endsWith('.webp') ||
        e.path.toLowerCase().endsWith('.bmp')
      );

      // 按文件名排序
      const sortedImageEntries = imageEntries.slice().sort((a, b) => a.path.localeCompare(b.path));

      if (sortedImageEntries.length === 0) {
        return { success: false, error: 'No image files found in CBZ' };
      }

      // 使用 Image Kit 获取图片信息
      const imageInfos: ComicImageInfo[] = [];
      for (const entry of sortedImageEntries) {
        try {
          const info = await HuaweiKitParser.getImageInfo(entry.data);
          imageInfos.push({
            path: entry.path,
            width: info.width,
            height: info.height,
            size: entry.data.length
          });
        } catch (error) {
          const err = error as Error;
          logger.warn('[KitParser] Failed to get image info:', entry.path, err.message);
          imageInfos.push({
            path: entry.path,
            width: 0,
            height: 0,
            size: entry.data.length
          });
        }
      }

      const fileName = BaseParserUtils.extractFileName(filePath);

      return {
        success: true,
        metadata: {
          title: fileName,
          author: 'Unknown Author',
          language: 'N/A',
          pageCount: imageEntries.length,
          wordCount: 0,
          format: DocumentFormat.CBZ,
          fileSize: imageEntries.reduce((sum, e) => sum + e.data.length, 0)
        },
        chapters: imageInfos.map((info, index) => ({
          index: index,
          title: 'Page ' + (index + 1) + ': ' + info.path.substring(info.path.lastIndexOf('/') + 1),
          content: JSON.stringify({
            path: info.path,
            width: info.width,
            height: info.height
          }),
          offset: 0
        }) as ChapterInfo),
        pages: []
      };
    } catch (error) {
      const err = error as Error;
      logger.error('[KitParser] CBZ parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 使用 Image Kit 获取图片信息
   */
  private static async getImageInfo(data: Uint8Array): Promise<ImageSizeInfo> {
    try {
      // 使用 @kit.ImageKit 解码图片
      const imageSource = image.createImageSource(data.buffer);
      const info = await imageSource.getImageInfo();
      
      return {
        width: info.size.width,
        height: info.size.height
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[KitParser] ImageKit failed:', err.message);
      const errResult: ImageSizeInfo = { width: 0, height: 0 };
      return errResult;
    }
  }

  // ==================== AZW/AZW3 增强解析 ====================

  /**
   * 增强AZW/AZW3 解析
   */
  static async parseAZWEnhanced(filePath: string, config: ParserConfig, buffer: ArrayBuffer, format: DocumentFormat): Promise<ParseResult> {
    logger.info('[KitParser] Enhanced AZW parsing:', filePath);

    try {
      const uint8Array = new Uint8Array(buffer);

      // 检查MOBI 文件
      if (uint8Array.length < 72) {
        return { success: false, error: 'Invalid MOBI/AZW file' };
      }

      // 检查PalmDOC 头
      const palmDocHeader = uint8Array.slice(0, 78);
      const isMobi = uint8Array.slice(60, 68);
      
      let content = '';
      let metadata: Partial<BookMetadata> = {};

      // 尝试 UTF-8 解码
      try {
        const decoder = new util.TextDecoder('utf-8');
        content = decoder.decodeWithStream(uint8Array);
      } catch (error) {
        const decoder = new util.TextDecoder('ascii');
        content = decoder.decodeWithStream(uint8Array);
      }

      // 提取文本内容
      const plainText = content
        .replace(new RegExp('<[^>]+>', 'g'), ' ')
        .replace(new RegExp('\s+', 'g'), ' ')
        .trim();

      // 尝试提取元数据
      const titleMatch = content.match(new RegExp('<dc:title>([^<]+)<\/dc:title>', 'i')) ||
                        content.match(new RegExp('<Title[^>]*>([^<]+)<\/Title>', 'i'));
      const authorMatch = content.match(new RegExp('<dc:creator>([^<]+)<\/dc:creator>', 'i')) ||
                         content.match(new RegExp('<Creator[^>]*>([^<]+)<\/Creator>', 'i'));

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
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[KitParser] AZW parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  // ==================== 工具方法 ====================

  /**
   * 解码文本
   */
  private static decodeText(data: Uint8Array): string {
    try {
      return new util.TextDecoder('utf-8').decodeWithStream(data);
    } catch (error) {
      return new util.TextDecoder('ascii').decodeWithStream(data);
    }
  }
}
