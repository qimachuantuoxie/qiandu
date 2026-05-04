import { logger } from '../../utils/Logger';

// 书籍内容解析??
import { BookFormat } from '../models/CoreBookModel';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

// 目录??
export interface TocItem {
  id?: string;
  title: string;
  startPosition?: number;
  endPosition?: number;
  level?: number;
  href?: string;
  pageNumber?: number;
}

export interface SearchResult {
  pageNumber: number;
  chapterTitle: string;
  previewText: string;
  matchStart: number;
  matchEnd: number;
}

export interface ChapterInfo {
  id: string;
  title: string;
  startPosition: number;
  endPosition: number;
  level: number;
}

// 解析结果
export interface ParseResult {
  success: boolean;
  content: string;
  chapters: ChapterInfo[];
  metadata: BookMetadata;
  error?: string;
}

// 书籍元数据
export interface BookMetadata {
  title: string;
  author: string;
  description?: string;
  cover?: string;
  language?: string;
  publisher?: string;
  publishedDate?: string;
  isbn?: string;
  toc: TocItem[];
  totalPages: number;
  pageSize?: number;
  fileSize?: number;
}

// 解析后的内容
export interface ParsedContent {
  metadata: BookMetadata;
  pages: string[];         // 分页后的内容
  plainText: string;       // 纯文本（用于搜索??
}

export class BookContentParser {
  // 解析书籍文件
  static async parseFile(filePath: string): Promise<ParseResult> {
    try {
      // 读取文件
      let content = '';
      try {
        const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
        const stat = fileIo.statSync(filePath);
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);

        // 尝试 UTF-8 解码
        const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
        content = decoder.decodeWithStream(new Uint8Array(buffer));
      } catch {
        logger.error('Read file failed');
        return {
          success: false,
          content: '',
          chapters: [],
          metadata: { title: '', author: '', toc: [], totalPages: 0 },
          error: '文件读取失败或编码不支持'
        };
      }

      // 检测文件格式
      const format = BookContentParser.detectFormat(filePath);

      // 解析元数据
      const metadata = BookContentParser.parseMetadata(content, format);

      // 解析章节
      const chapters = BookContentParser.parseChapters(content, format);

      return {
        success: true,
        content: content,
        chapters: chapters,
        metadata: metadata
      };
    } catch {
      logger.error('Parse file failed');
      return {
        success: false,
        content: '',
        chapters: [],
        metadata: { title: '', author: '', toc: [], totalPages: 0 },
        error: 'Parse failed'
      };
    }
  }

  // 检测文件格式
  private static detectFormat(filePath: string): BookFormat {
    const ext = filePath.toLowerCase().split('.').pop();
    switch (ext) {
      case 'epub':
        return BookFormat.EPUB;
      case 'pdf':
        return BookFormat.PDF;
      case 'txt':
        return BookFormat.TXT;
      case 'mobi':
        return BookFormat.MOBI;
      case 'azw3':
        return BookFormat.AZW3;
      case 'azw':
        return BookFormat.AZW;
      case 'docx':
        return BookFormat.DOCX;
      case 'doc':
        return BookFormat.DOC;
      case 'rtf':
        return BookFormat.RTF;
      case 'html':
      case 'htm':
        return BookFormat.HTML;
      case 'odt':
        return BookFormat.ODT;
      case 'fb2':
        return BookFormat.FB2;
      case 'cbr':
        return BookFormat.CBR;
      case 'cbz':
        return BookFormat.CBZ;
      case 'djvu':
      case 'djv':
        return BookFormat.DJVU;
      case 'chm':
        return BookFormat.CHM;
      case 'md':
        return BookFormat.MD;
      default:
        return BookFormat.TXT;
    }
  }

  // 解析元数据
  private static parseMetadata(content: string, format: BookFormat): BookMetadata {
    let title = '';
    let author = '';
    let description = '';

    switch (format) {
      case BookFormat.TXT:
        const firstLines = content.split('\n').slice(0, 20).join('\n');
        const titleMatch = firstLines.match(new RegExp('书名[：:]\s*(.+)$', 'm'));
        const authorMatch = firstLines.match(new RegExp('作者[：:]\s*(.+)$', 'm'));
        title = titleMatch ? titleMatch[1].trim() : '';
        author = authorMatch ? authorMatch[1].trim() : '';
        break;
    }

    return {
      title,
      author,
      description,
      toc: [],
      totalPages: 0
    };
  }

  // 解析章节
  private static parseChapters(content: string, format: BookFormat): ChapterInfo[] {
    const chapters: ChapterInfo[] = [];
    const lines = content.split('\n');

    // 多种目录模式
    const patterns = [
      new RegExp('^(第[一二三四五六七八九十百千\d]+[章节]?[\s\.]+(.+)$', ''),
      new RegExp('^(第\d+[章节]?[\s\.]+(.+)$', ''),
      new RegExp('^(Chapter\s+\d+)[\s\.]*(.+)?$', 'i'),
      new RegExp('^(\d+)[\s\.]+(.+)$', ''),
      new RegExp('^[\s]*([一二三四五六七八九十]+)[\s\.]+(.+)$', ''),
    ];

    let currentPos = 0;
    let chapterIndex = 0;
    let lastChapterStartPos = -1;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      for (const pattern of patterns) {
        const match = line.match(pattern);
        if (match && match[0].length < 50) {
          const startPos = currentPos;

          // 更新上一个章节的结束位置
          if (chapters.length > 0) {
            chapters[chapters.length - 1].endPosition = startPos;
          }

          chapters.push({
            id: `chapter_${chapterIndex}`,
            title: match[2] || match[1],
            startPosition: startPos,
            endPosition: content.length, // 默认??将在后续迭代中更??
            level: 1,
          });

          chapterIndex++;
          lastChapterStartPos = startPos;
          break;
        }
      }

      currentPos += lines[i].length + 1; // +1 是因为换行符
    }

    // 最后一个章节的结束位置已经??content.length,无需更新

    return chapters;
  }

  // 解析目录（从PDF/EPUB中提取）
  static parseToc(content: string, format: BookFormat): TocItem[] {
    let toc: TocItem[] = [];

    switch (format) {
      case BookFormat.PDF:
        toc = toc.concat(BookContentParser.parsePdfToc(content));
        break;
      case BookFormat.EPUB:
        toc = toc.concat(BookContentParser.parseEpubToc(content));
        break;
      case BookFormat.TXT:
        toc = toc.concat(BookContentParser.parseTxtToc(content));
        break;
      default:
        toc = toc.concat(BookContentParser.parseGenericToc(content));
    }

    return toc;
  }

  // PDF目录解析
  private static parsePdfToc(content: string): TocItem[] {
    const toc: TocItem[] = [];
    const lines = content.split('\n');

    // 匹配常见的目录格式："第X??标题" ??"X.X 标题"
    const chapterPattern = new RegExp('^(第[一二三四五六七八九十\d]+章|第\d+章|Chapter\s+\d+|\d+\.\d+)[\s\.]+(.+)$', 'i');
    const pagePattern = new RegExp('(\d+)$', '');  // 行尾的页码

    let currentPage = 1;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      const match = line.match(chapterPattern);

      if (match) {
        // 尝试从行尾提取页??
        const pageMatch = line.match(pagePattern);
        if (pageMatch) {
          const parsed = parseInt(pageMatch[1], 10);
          currentPage = isNaN(parsed) ? 1 : parsed;
        }

        toc.push({
          title: match[2] || match[0],
          pageNumber: currentPage,
          level: BookContentParser.getLevelFromNumber(match[1]),
        });
      }
    }

    return toc;
  }

  // EPUB目录解析
  private static parseEpubToc(content: string): TocItem[] {
    const toc: TocItem[] = [];

    // 简单的HTML目录解析
    const navPattern = new RegExp('<nav[^>]*epub:type="toc"[^>]*>([\s\S]*?)<\/nav>', 'i');
    const navMatch = content.match(navPattern);

    if (navMatch) {
      const navContent = navMatch[1];
      const itemPattern = new RegExp('<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>', 'gi');
      let match: RegExpExecArray | null;

      while ((match = itemPattern.exec(navContent)) !== null) {
        const href = match[1];
        const title = BookContentParser.stripHtml(match[2]).trim();
        const pageNumber = BookContentParser.extractPageFromHref(href);

        if (title) {
          toc.push({
            title: title,
            pageNumber: pageNumber,
            level: BookContentParser.getLevelFromHref(href),
          });
        }
      }
    }

    return toc;
  }

  // TXT智能目录解析
  private static parseTxtToc(content: string): TocItem[] {
    const toc: TocItem[] = [];
    const lines = content.split('\n');

    // 多种目录模式
    const patterns = [
      new RegExp('^(第[一二三四五六七八九十百千\d]+[章节]?[\s\.]+(.+)$', ''),
      new RegExp('^(第\d+[章节]?[\s\.]+(.+)$', ''),
      new RegExp('^(Chapter\s+\d+)[\s\.]*(.+)?$', 'i'),
      new RegExp('^(\d+)[\s\.]+(.+)$', ''),
      new RegExp('^[\s]*([一二三四五六七八九十]+)[\s\.]+(.+)$', ''),
    ];

    let lineCount = 0;
    const charsPerPage = 800; // 估算每页字符??

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      for (const pattern of patterns) {
        const match = line.match(pattern);
        if (match && match[0].length < 50) {  // 限制长度避免误匹??
          const pageNumber = Math.floor(lineCount / charsPerPage) + 1;

          toc.push({
            title: match[2] || match[1],
            pageNumber: pageNumber,
            level: 1,
          });
          break;
        }
      }

      lineCount += lines[i].length + 1;
    }

    return toc;
  }

  // 通用目录解析
  private static parseGenericToc(content: string): TocItem[] {
    const toc: TocItem[] = [];
    const lines = content.split('\n');
    const pattern = new RegExp('^(第\d+章|Chapter\s+\d+|\d+\.\s+)(.+)$', 'i');

    for (let i = 0; i < lines.length; i++) {
      const match = lines[i].trim().match(pattern);
      if (match) {
        toc.push({
          title: match[2],
          pageNumber: Math.floor(i / 40) + 1,
          level: 1,
        });
      }
    }

    return toc;
  }

  // 全文搜索
  static searchInContent(content: string, keyword: string, toc: TocItem[]): SearchResult[] {
    const results: SearchResult[] = [];
    if (!keyword || keyword.trim().length === 0) return results;

    const lines = content.split('\n');
    const lowerKeyword = keyword.toLowerCase();
    const charsPerPage = 800;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lowerLine = line.toLowerCase();
      let index = lowerLine.indexOf(lowerKeyword);

      while (index !== -1) {
        const pageNumber = Math.floor((i * 80) / charsPerPage) + 1;
        const chapterTitle = BookContentParser.findChapterByPage(toc, pageNumber);

        // 提取预览文本
        const previewStart = Math.max(0, index - 30);
        const previewEnd = Math.min(line.length, index + keyword.length + 30);
        let previewText = line.substring(previewStart, previewEnd);

        if (previewStart > 0) previewText = '...' + previewText;
        if (previewEnd < line.length) previewText = previewText + '...';

        const result: SearchResult = {
          pageNumber: pageNumber,
          chapterTitle: chapterTitle ? chapterTitle : '',
          previewText: previewText,
          matchStart: index,
          matchEnd: index + keyword.length,
        };
        results.push(result);

        // 继续搜索下一个匹??
        index = lowerLine.indexOf(lowerKeyword, index + 1);
      }
    }

    return results;
  }

  // 根据页码查找章节
  private static findChapterByPage(toc: TocItem[], pageNumber: number): string | undefined {
    let chapter: TocItem | undefined;

    for (const item of toc) {
      if (item.pageNumber !== undefined && item.pageNumber <= pageNumber) {
        chapter = item;
      } else {
        break;
      }
    }

    return chapter?.title;
  }

  // 提取纯文本（去除HTML标签??
  static extractPlainText(html: string): string {
    return html
      .replace(/<[^>]+>/g, ' ')  // 去除HTML标签
      .replace(/\s+/g, ' ')      // 合并空白
      .trim();
  }

  // 分页处理
  static paginateContent(content: string, charsPerPage: number = 800): string[] {
    const pages: string[] = [];
    const plainText = BookContentParser.extractPlainText(content);
    const totalChars = plainText.length;

    for (let i = 0; i < totalChars; i += charsPerPage) {
      pages.push(plainText.substring(i, i + charsPerPage));
    }

    return pages;
  }

  // 辅助方法：去除HTML标签
  private static stripHtml(html: string): string {
    return html.replace(new RegExp('<[^>]*>', 'g'), '');
  }

  // 辅助方法：从href提取页码
  private static extractPageFromHref(href: string): number {
    const match = href.match(new RegExp('page(\d+)', 'i'));
    if (match) {
      const parsed = parseInt(match[1], 10);
      return isNaN(parsed) ? 1 : parsed;
    }
    return 1;
  }

  // 辅助方法：从章节号判断层??
  private static getLevelFromNumber(numberStr: string): number {
    if (numberStr.includes('.')) {
      const parts = numberStr.split('.');
      return parts.length;
    }
    return 1;
  }

  // 辅助方法：从href判断层级
  private static getLevelFromHref(href: string): number {
    const depth = (href.match(/\//g) || []).length;
    return Math.max(1, depth);
  }
}



