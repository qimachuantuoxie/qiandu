/**
 * ZIP 格式解析器 - 专门处理基于 ZIP 的文档格式
 * ZIP Format Parser - Handles ZIP-based document formats
 *
 * 支持格式：EPUB, DOCX, ODT, CBZ
 */

import { BaseParserUtils, ZipEntry, ZipParseResult } from './BaseParserUtils';
import { DocumentFormat, ChapterInfo, BookMetadata, ParseResult, ParserConfig } from '../models/DocumentModels';
import { util } from '@kit.ArkTS';

/**
 * 元数据类型
 */
interface PartialBookMetadata {
  title?: string;
  author?: string;
  language?: string;
  description?: string;
  pageCount?: number;
  wordCount?: number;
  format?: DocumentFormat;
  fileSize?: number;
}

/**
 * CBZ 章节项（用于 map 返回的对象字面量）
 */
interface CbzChapterItem {
  index: number;
  title: string;
  content: string;
  offset: number;
}

/**
 * ZIP 格式解析器
 */
export class ZipFormatParser {

  // ==================== EPUB 解析 ====================

  /**
   * 解析 EPUB 文档
   */
  static async parseEPUB(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    console.info('[ZipParser] Parsing EPUB:', filePath);

    try {
      // 查找 OPF 文件
      const opfEntry = ZipFormatParser.findOpfFile(zipResult.entries);
      if (!opfEntry) {
        return {
          success: false,
          error: 'OPF file not found'
        };
      }

      const opfContent = ZipFormatParser.decodeText(opfEntry.data);

      // 提取元数据
      const metadata = ZipFormatParser.extractEPUBMetadata(opfContent, zipResult.entries);

      // 提取文本内容
      const textContent = ZipFormatParser.extractEPUBText(zipResult.entries, opfContent);

      // 提取章节（传递 opfContent）
      const chapters = config.extractChapters ? ZipFormatParser.extractEPUBChapters(zipResult.entries, opfContent) : [];

      // 分页
      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: metadata.title !== undefined ? metadata.title : 'Unknown Title',
          author: metadata.author !== undefined ? metadata.author : 'Unknown Author',
          language: metadata.language !== undefined ? metadata.language : 'zh-CN',
          description: metadata.description,
          pageCount: pages.length,
          wordCount: textContent.length,
          format: DocumentFormat.EPUB,
          fileSize: opfEntry.data.length
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[ZipParser] EPUB parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 查找 OPF 文件
   */
  private static findOpfFile(entries: ZipEntry[]): ZipEntry | null {
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].path.endsWith('.opf')) {
        return entries[i];
      }
    }
    return null;
  }

  /**
   * 提取 EPUB 元数据
   */
  private static extractEPUBMetadata(opfContent: string, entries: ZipEntry[]): PartialBookMetadata {
    const titleMatch = opfContent.match(new RegExp('<dc:title[^>]*>([^<]+)<\/dc:title>', 'i'));
    const authorMatch = opfContent.match(new RegExp('<dc:creator[^>]*>([^<]+)<\/dc:creator>', 'i'));
    const langMatch = opfContent.match(new RegExp('<dc:language[^>]*>([^<]+)<\/dc:language>', 'i'));
    const descMatch = opfContent.match(new RegExp('<dc:description[^>]*>([^<]+)<\/dc:description>', 'i'));

    return {
      title: titleMatch ? titleMatch[1].trim() : 'Unknown Title',
      author: authorMatch ? authorMatch[1].trim() : 'Unknown Author',
      language: langMatch ? langMatch[1].trim() : 'zh-CN',
      description: descMatch ? descMatch[1].trim() : undefined
    };
  }

  /**
   * 提取 EPUB 文本内容
   */
  private static extractEPUBText(entries: ZipEntry[], opfContent: string): string {
    let fullText = '';

    // 查找 XHTML/HTML 文件
    const htmlEntries: ZipEntry[] = [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (e.path.endsWith('.xhtml') || e.path.endsWith('.html')) {
        htmlEntries.push(e);
      }
    }

    for (let i = 0; i < htmlEntries.length; i++) {
      const entry = htmlEntries[i];
      const htmlContent = ZipFormatParser.decodeText(entry.data);
      const text = BaseParserUtils.extractHtmlText(htmlContent);
      if (text.length > 10) {
        fullText += text + '\n\n';
      }
    }

    return fullText.trim();
  }

  /**
   * 提取 EPUB 章节（增强版 - 支持 NCX/TOC 导航）
   */
  private static extractEPUBChapters(entries: ZipEntry[], opfContent: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 尝试从 NCX 文件提取目录
    let ncxEntry: ZipEntry | null = null;
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].path.endsWith('.ncx')) {
        ncxEntry = entries[i];
        break;
      }
    }
    if (ncxEntry) {
      const ncxContent = ZipFormatParser.decodeText(ncxEntry.data);
      const ncxChapters = ZipFormatParser.extractNCXChapters(ncxContent, entries);
      if (ncxChapters.length > 0) {
        return ncxChapters;
      }
    }

    // 尝试从 XHTML TOC 文件提取（EPUB3）
    let tocEntry: ZipEntry | null = null;
    for (let i = 0; i < entries.length; i++) {
      const epath = entries[i].path;
      if (epath.endsWith('toc.xhtml') ||
          epath.endsWith('toc.html') ||
          epath.includes('nav.xhtml')) {
        tocEntry = entries[i];
        break;
      }
    }
    if (tocEntry) {
      const tocContent = ZipFormatParser.decodeText(tocEntry.data);
      const tocChapters = ZipFormatParser.extractTOCChapters(tocContent, entries);
      if (tocChapters.length > 0) {
        return tocChapters;
      }
    }

    // 回退到按文件顺序提取
    const htmlEntries: ZipEntry[] = [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (e.path.endsWith('.xhtml') || e.path.endsWith('.html')) {
        htmlEntries.push(e);
      }
    }

    for (let i = 0; i < htmlEntries.length; i++) {
      const entry = htmlEntries[i];
      const pathParts = entry.path.split('/');
      let fileName = 'Chapter ' + (i + 1);
      if (pathParts.length > 0) {
        fileName = pathParts[pathParts.length - 1];
      }

      // 尝试从内容提取标题
      const htmlContent = ZipFormatParser.decodeText(entry.data);
      let titleMatch = htmlContent.match(new RegExp('<title[^>]*>([^<]+)<\/title>', 'i'));
      if (!titleMatch) {
        titleMatch = htmlContent.match(new RegExp('<h1[^>]*>([^<]+)<\/h1>', 'i'));
      }
      let title = fileName;
      if (titleMatch) {
        title = titleMatch[1].trim();
      }
      title = title.replace('.xhtml', '').replace('.html', '');

      chapters.push({
        index: i,
        title: title,
        content: htmlContent,
        offset: 0
      });
    }

    return chapters;
  }

  /**
   * 从 NCX 文件提取章节
   */
  private static extractNCXChapters(ncxContent: string, entries: ZipEntry[]): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配 navPoint 元素
    const navPointRegex = new RegExp('<navPoint[^>]*id="([^"]*)"[^>]*playOrder="(\d+)"[^>]*>[\s\S]*?<navLabel[^>]*>[\s\S]*?<text[^>]*>([^<]+)<\/text>[\s\S]*?<content[^>]*src="([^"]*)"', 'gi');
    let match: RegExpExecArray | null;

    while ((match = navPointRegex.exec(ncxContent)) !== null) {
      const id = match[1];
      const playOrder = match[2];
      const title = match[3].trim();
      const src = match[4];

      // 查找对应的 HTML 文件
      let targetEntry: ZipEntry | null = null;
      for (let i = 0; i < entries.length; i++) {
        const e = entries[i];
        if (src.includes(e.path) || e.path.includes(src)) {
          targetEntry = e;
          break;
        }
      }

      if (targetEntry) {
        chapters.push({
          index: chapters.length,
          title: title,
          content: ZipFormatParser.decodeText(targetEntry.data),
          offset: 0
        });
      }
    }

    return chapters;
  }

  /**
   * 从 TOC XHTML 文件提取章节（EPUB3）
   */
  private static extractTOCChapters(tocContent: string, entries: ZipEntry[]): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配 EPUB3 TOC 中的 <a href="..."> 标签
    const linkRegex = new RegExp('<a[^>]+href="([^"]+)"[^>]*>([^<]+)<\/a>', 'gi');
    let match: RegExpExecArray | null;

    while ((match = linkRegex.exec(tocContent)) !== null) {
      const href = match[1];
      const title = match[2].trim();

      if (title.length === 0) continue;

      // 查找对应的 HTML 文件
      let targetEntry: ZipEntry | null = null;
      const hrefBase = href.split('#')[0];
      for (let i = 0; i < entries.length; i++) {
        const e = entries[i];
        if (href.includes(e.path) || e.path.includes(hrefBase)) {
          targetEntry = e;
          break;
        }
      }

      if (targetEntry) {
        chapters.push({
          index: chapters.length,
          title: title,
          content: ZipFormatParser.decodeText(targetEntry.data),
          offset: 0
        });
      }
    }

    return chapters;
  }

  // ==================== DOCX 解析 ====================

  /**
   * 解析 DOCX 文档
   */
  static async parseDOCX(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    console.info('[ZipParser] Parsing DOCX:', filePath);

    try {
      // 查找 document.xml
      let docEntry: ZipEntry | null = null;
      for (let i = 0; i < zipResult.entries.length; i++) {
        if (zipResult.entries[i].path.endsWith('word/document.xml')) {
          docEntry = zipResult.entries[i];
          break;
        }
      }
      if (!docEntry) {
        return {
          success: false,
          error: 'document.xml not found'
        };
      }

      const docContent = ZipFormatParser.decodeText(docEntry.data);
      const textContent = ZipFormatParser.extractDOCXText(docContent);

      // 提取元数据
      let coreEntry: ZipEntry | null = null;
      for (let i = 0; i < zipResult.entries.length; i++) {
        if (zipResult.entries[i].path.endsWith('docProps/core.xml')) {
          coreEntry = zipResult.entries[i];
          break;
        }
      }
      const coreMetadata: PartialBookMetadata = coreEntry ? ZipFormatParser.extractDOCXMetadata(ZipFormatParser.decodeText(coreEntry.data)) : {};

      // 提取章节（优先使用标题样式，否则按段落）
      let chapters = config.extractChapters ? ZipFormatParser.extractDOCXChapters(docContent) : [];
      if (chapters.length === 0) {
        chapters = BaseParserUtils.extractChaptersByParagraphs(textContent);
      }

      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: coreMetadata.title !== undefined ? coreMetadata.title : BaseParserUtils.extractFileName(filePath),
          author: coreMetadata.author !== undefined ? coreMetadata.author : 'Unknown Author',
          language: coreMetadata.language !== undefined ? coreMetadata.language : 'zh-CN',
          pageCount: pages.length,
          wordCount: textContent.length,
          format: DocumentFormat.DOCX,
          fileSize: docEntry.data.length
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters,
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      console.error('[ZipParser] DOCX parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 提取 DOCX 文本（增强版 - 保留段落结构）
   */
  private static extractDOCXText(xmlContent: string): string {
    const paragraphs: string[] = [];

    // 匹配段落 <w:p>...</w:p>
    const paragraphRegex = new RegExp('<w:p[^>]*>([\s\S]*?)<\/w:p>', 'g');
    let pMatch: RegExpExecArray | null;

    while ((pMatch = paragraphRegex.exec(xmlContent)) !== null) {
      const paragraphXml = pMatch[1];
      const paragraphText = ZipFormatParser.extractParagraphText(paragraphXml);
      if (paragraphText.trim().length > 0) {
        paragraphs.push(paragraphText.trim());
      }
    }

    // 如果没有找到段落，尝试提取所有文本
    if (paragraphs.length === 0) {
      const textParts: string[] = [];
      const regex = new RegExp('<w:t[^>]*>([^<]*)<\/w:t>', 'g');
      let match: RegExpExecArray | null;

      while ((match = regex.exec(xmlContent)) !== null) {
        if (match[1].trim().length > 0) {
          textParts.push(match[1]);
        }
      }
      return textParts.join(' ').trim();
    }

    return paragraphs.join('\n\n');
  }

  /**
   * 从段落 XML 中提取文本
   */
  private static extractParagraphText(paragraphXml: string): string {
    const textParts: string[] = [];
    const regex = new RegExp('<w:t[^>]*>([^<]*)<\/w:t>', 'g');
    let match: RegExpExecArray | null;

    while ((match = regex.exec(paragraphXml)) !== null) {
      textParts.push(match[1]);
    }

    return textParts.join('');
  }

  /**
   * 提取 DOCX 章节（增强版 - 按标题分级）
   */
  private static extractDOCXChapters(xmlContent: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配标题样式 <w:pStyle w:val="Heading1"/> 等
    const headingRegex = new RegExp('<w:p[^>]*>[\s\S]*?<w:pStyle\s+w:val="(Heading\d+)"[^>]*>[\s\S]*?<w:t[^>]*>([^<]+)<\/w:t>', 'gi');
    let match: RegExpExecArray | null;
    let lastIndex = 0;

    while ((match = headingRegex.exec(xmlContent)) !== null) {
      const headingLevel = match[1];
      const headingText = match[2].trim();

      if (headingText.length > 0) {
        chapters.push({
          index: chapters.length,
          title: headingText,
          content: '',
          offset: match.index
        });
      }
    }

    return chapters;
  }

  /**
   * 提取 DOCX 元数据
   */
  private static extractDOCXMetadata(coreXml: string): PartialBookMetadata {
    const title = BaseParserUtils.extractXmlTag(coreXml, 'dc:title');
    const creator = BaseParserUtils.extractXmlTag(coreXml, 'dc:creator');
    const language = BaseParserUtils.extractXmlTag(coreXml, 'dc:language');

    return {
      title: title,
      author: creator,
      language: language
    };
  }

  // ==================== ODT 解析 ====================

  /**
   * 解析 ODT 文档（增强版）
   */
  static async parseODT(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    console.info('[ZipParser] Parsing ODT:', filePath);

    try {
      // 查找 content.xml
      let contentEntry: ZipEntry | null = null;
      for (let i = 0; i < zipResult.entries.length; i++) {
        if (zipResult.entries[i].path.endsWith('content.xml')) {
          contentEntry = zipResult.entries[i];
          break;
        }
      }
      if (!contentEntry) {
        return {
          success: false,
          error: 'content.xml not found'
        };
      }

      const contentXml = ZipFormatParser.decodeText(contentEntry.data);
      const textContent = ZipFormatParser.extractODTText(contentXml);

      // 提取元数据
      let metaEntry: ZipEntry | null = null;
      for (let i = 0; i < zipResult.entries.length; i++) {
        if (zipResult.entries[i].path.endsWith('meta.xml')) {
          metaEntry = zipResult.entries[i];
          break;
        }
      }
      const metaMetadata: PartialBookMetadata = metaEntry ? ZipFormatParser.extractODTMetadata(ZipFormatParser.decodeText(metaEntry.data)) : {};

      // 提取章节
      const chapters = config.extractChapters ? ZipFormatParser.extractODTChapters(contentXml) : [];

      // 分页
      const pages = config.paginate ? BaseParserUtils.paginateContent(textContent, config.charsPerPage) : [];

      return {
        success: true,
        metadata: {
          title: metaMetadata.title !== undefined ? metaMetadata.title : BaseParserUtils.extractFileName(filePath),
          author: metaMetadata.author !== undefined ? metaMetadata.author : 'Unknown Author',
          language: metaMetadata.language !== undefined ? metaMetadata.language : 'zh-CN',
          pageCount: pages.length,
          wordCount: textContent.length,
          format: DocumentFormat.ODT,
          fileSize: contentEntry.data.length,
          description: metaMetadata.description
        },
        content: config.extractContent ? textContent : undefined,
        chapters: chapters.length > 0 ? chapters : BaseParserUtils.extractChaptersByParagraphs(textContent),
        pages: pages
      };
    } catch (error) {
      const err = error as Error;
      console.error('[ZipParser] ODT parse failed:', err.message);
      return {
        success: false,
        error: err.message
      };
    }
  }

  /**
   * 提取 ODT 文本（增强版 - 保留段落）
   */
  private static extractODTText(contentXml: string): string {
    const paragraphs: string[] = [];

    // 匹配文本段落 <text:p>...</text:p>
    const paragraphRegex = new RegExp('<text:p[^>]*>([\s\S]*?)<\/text:p>', 'g');
    let match: RegExpExecArray | null;

    while ((match = paragraphRegex.exec(contentXml)) !== null) {
      const text = match[1].replace(new RegExp('<[^>]+>', 'g'), ' ').replace(new RegExp('&nbsp;', 'g'), ' ').trim();
      if (text.length > 0) {
        paragraphs.push(text);
      }
    }

    // 如果没有找到段落，尝试提取所有文本
    if (paragraphs.length === 0) {
      return BaseParserUtils.extractXmlText(contentXml);
    }

    return paragraphs.join('\n\n');
  }

  /**
   * 提取 ODT 章节
   */
  private static extractODTChapters(contentXml: string): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];

    // 匹配标题 <text:h text:outline-level="1">...</text:h>
    const headingRegex = new RegExp('<text:h[^>]*text:outline-level="(\d+)"[^>]*>([\s\S]*?)<\/text:h>', 'gi');
    let match: RegExpExecArray | null;

    while ((match = headingRegex.exec(contentXml)) !== null) {
      const level = parseInt(match[1]);
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

    return chapters;
  }

  /**
   * 提取 ODT 元数据（增强版）
   */
  private static extractODTMetadata(metaXml: string): PartialBookMetadata {
    const title = BaseParserUtils.extractXmlTag(metaXml, 'dc:title');
    const creator = BaseParserUtils.extractXmlTag(metaXml, 'dc:creator');
    const language = BaseParserUtils.extractXmlTag(metaXml, 'dc:language');
    const description = BaseParserUtils.extractXmlTag(metaXml, 'dc:description');

    return {
      title: title,
      author: creator,
      language: language,
      description: description
    };
  }

  // ==================== CBZ 解析 ====================

  /**
   * 解析 CBZ 漫画文档
   */
  static async parseCBZ(filePath: string, config: ParserConfig, zipResult: ZipParseResult): Promise<ParseResult> {
    console.info('[ZipParser] Parsing CBZ:', filePath);

    try {
      // 查找图片文件
      const imageEntries: ZipEntry[] = [];
      for (let i = 0; i < zipResult.entries.length; i++) {
        const e = zipResult.entries[i];
        const lowerPath = e.path.toLowerCase();
        if (lowerPath.endsWith('.jpg') ||
            lowerPath.endsWith('.jpeg') ||
            lowerPath.endsWith('.png') ||
            lowerPath.endsWith('.gif') ||
            lowerPath.endsWith('.webp')) {
          imageEntries.push(e);
        }
      }

      // 按文件名排序
      const sortedImageEntries = imageEntries.slice().sort((a, b) => a.path.localeCompare(b.path));

      if (sortedImageEntries.length === 0) {
        return {
          success: false,
          error: 'No image files found in CBZ'
        };
      }

      const fileName = BaseParserUtils.extractFileName(filePath);

      // 计算总文件大小
      let totalSize = 0;
      for (let i = 0; i < imageEntries.length; i++) {
        totalSize += imageEntries[i].data.length;
      }

      // 构建章节
      const chapters: CbzChapterItem[] = [];
      for (let i = 0; i < imageEntries.length; i++) {
        const entry = imageEntries[i];
        const pathParts = entry.path.split('/');
        let pageName = 'Unknown';
        if (pathParts.length > 0) {
          pageName = pathParts[pathParts.length - 1];
        }
        chapters.push({
          index: i,
          title: 'Page ' + (i + 1) + ': ' + pageName,
          content: '',
          offset: 0
        });
      }

      return {
        success: true,
        metadata: {
          title: fileName,
          author: 'Unknown Author',
          language: 'N/A',
          pageCount: imageEntries.length,
          wordCount: 0,
          format: DocumentFormat.CBZ,
          fileSize: totalSize
        },
        chapters: chapters,
        pages: []
      };
    } catch (error) {
      const err = error as Error;
      console.error('[ZipParser] CBZ parse failed:', err.message);
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
      const decoder = new util.TextDecoder('utf-8');
      return decoder.decodeWithStream(data);
    } catch (error) {
      const decoder = new util.TextDecoder('ascii');
      return decoder.decodeWithStream(data);
    }
  }
}


