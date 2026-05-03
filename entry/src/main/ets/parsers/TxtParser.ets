/**
 * TXT Parser - 纯文本电子书解析器
 *
 * 提供 TXT 格式电子书的解析功能，包括：
 * - 文件读取与编码检测
 * - 元数据提取（从文件头部提取作者、简介等）
 * - 章节智能识别（支持多种中文章节格式）
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BookMetadata, LocalChapterInfo, ParseResult } from '../core/models/EbookTypes';

/**
 * TXT 解析器类
 */
export class TxtParser {

  /**
   * 解析 TXT 文件
   * @param filePath TXT 文件路径
   * @returns 解析结果
   */
  static async parse(filePath: string): Promise<ParseResult> {
    console.info('[TxtParser] Parsing TXT file:', filePath);

    try {
      const content = await TxtParser.readTxtFile(filePath);
      const encoding = TxtParser.detectEncodingFromContent(content);
      console.info('[TxtParser] Detected encoding:', encoding);

      const metadata = TxtParser.extractTxtMetadata(content, filePath);
      const chapters = TxtParser.parseTxtChapters(content);

      console.info('[TxtParser] TXT parsed: ' + chapters.length + ' chapters, ' + metadata.wordCount + ' characters');

      return {
        metadata,
        content,
        chapters,
        success: true
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      const errorMsg = message;
      throw new Error('TXT file read failed: ' + errorMsg);
    }
  }

  /**
   * 读取 TXT 文件内容
   * @param filePath 文件路径
   * @returns 文件内容
   */
  private static async readTxtFile(filePath: string): Promise<string> {
    try {
      const stat = fileIo.statSync(filePath);
      const buffer = new Uint8Array(stat.size);
      const fd = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.readSync(fd.fd, buffer);
      } finally {
        fileIo.closeSync(fd);
      }

      const encoding = TxtParser.detectEncoding(buffer.buffer as ArrayBuffer);
      const decoder = new util.TextDecoder(encoding);
      let content = decoder.decodeToString(buffer);

      // 移除 BOM 标记
      if (encoding === 'UTF-8' && content.charCodeAt(0) === 0xFEFF) {
        content = content.substring(1);
      }

      return content;
    } catch (err) {
      console.error('[TxtParser] Read file failed:', err);
      throw new Error(message instanceof Error ? message.message : 'Read file failed');
    }
  }

  /**
   * 从 TXT 文件头部提取元数据
   * @param content 文件内容
   * @param filePath 文件路径
   * @returns 书籍元数据
   */
  private static extractTxtMetadata(content: string, filePath: string): BookMetadata {
    const fileName = TxtParser.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    const lines = content.split('\n');
    let author = 'Unknown Author';
    let description = '';
    let publisher: string | undefined = undefined;
    let language = 'zh-CN';

    // 从文件头部（前50行）提取元数据
    const headerLines = lines.slice(0, Math.min(50, lines.length));
    let headerText = '';
    for (let i = 0; i < headerLines.length; i++) {
      if (i > 0) {
        headerText += '\n';
      }
      headerText += headerLines[i];
    }

    // 尝试多种作者匹配模式
    const authorPatterns: RegExp[] = [
      new RegExp('作者[:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('著者[:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('文案[:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('(.+?)\s*著\s*(?:\n|$)', '')
    ];

    for (let i = 0; i < authorPatterns.length; i++) {
      const pattern = authorPatterns[i];
      const match = headerText.match(pattern);
      if (match && match[1] && match[1].trim().length < 30) {
        author = match[1].trim();
        break;
      }
    }

    // 提取出版社信息
    const publisherPattern = new RegExp('出版社[:\uff1a]\s*(.+?)(?:\n|$)', '');
    const pubMatch = headerText.match(publisherPattern);
    if (pubMatch) {
      publisher = pubMatch[1].trim();
    }

    // 提取简介/描述
    const descPatterns: RegExp[] = [
      new RegExp('简介[:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|Author|ISBN|$)', ''),
      new RegExp('内容介绍[:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|$)', ''),
      new RegExp('书籍简介[:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|$)', '')
    ];

    for (let i = 0; i < descPatterns.length; i++) {
      const pattern = descPatterns[i];
      const match = headerText.match(pattern);
      if (match && match[1]) {
        description = match[1].trim();
        break;
      }
    }

    const wordCount = content.replace(new RegExp('\s', 'g'), '').length;
    const totalPages = Math.ceil(wordCount / 800);

    return {
      title: nameWithoutExt,
      author,
      publisher,
      isbn: undefined,
      language,
      description,
      coverData: undefined,
      totalPages,
      wordCount
    };
  }

  /**
   * 解析 TXT 章节结构
   * @param content 文件内容
   * @returns 章节列表
   */
  private static parseTxtChapters(content: string): LocalChapterInfo[] {
    const chapters: LocalChapterInfo[] = [];
    const lines = content.split('\n');

    // 多种章节标题匹配模式
    const patterns = [
      new RegExp('^(第?[一二三四五六七八九十百千零\\d]+章?[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(第?[\\d]+章?[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(卷?[一二三四五六七八九十百千\\d]+)[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(Chapter\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(Part\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(\\d+)[\\s\\.·]+(.+)$', ''),
      new RegExp('^\\d+\\.\\s+(.+)$', ''),
      new RegExp('^([一二三四五六七八九十]+)[\\s\\.·]+(.+)$', ''),
    ];

    const isChapterTitle = (line: string): boolean => {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.length > 100) return false;

      for (let i = 0; i < patterns.length; i++) {
        if (patterns[i].test(trimmed)) return true;
      }

      return false;
    };

    let currentChapterStart = -1;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      if (isChapterTitle(line)) {
        // 保存上一个章节
        if (currentChapterStart >= 0 && currentChapterStart < i) {
          const chapterTitle = lines[currentChapterStart].trim();
          chapters.push({
            id: 'chapter_' + chapters.length,
            title: chapterTitle,
            startOffset: currentChapterStart,
            endOffset: i,
            level: TxtParser.getChapterLevel(chapterTitle)
          });
        }

        currentChapterStart = i;
      }
    }

    // 保存最后一个章节
    if (currentChapterStart >= 0 && currentChapterStart < lines.length) {
      const chapterTitle = lines[currentChapterStart].trim();
      chapters.push({
        id: 'chapter_' + chapters.length,
        title: chapterTitle,
        startOffset: currentChapterStart,
        endOffset: lines.length,
        level: TxtParser.getChapterLevel(chapterTitle)
      });
    }

    console.info('[TxtParser] Parsed ' + chapters.length + ' chapters');
    return chapters;
  }

  /**
   * 获取章节层级
   * @param title 章节标题
   * @returns 层级（1=卷 2=章 3=节）
   */
  private static getChapterLevel(title: string): number {
    if (new RegExp('^卷?').test(title)) return 1;
    if (new RegExp('^第?章?').test(title)) return 2;
    if (new RegExp('^\\d+\\.').test(title)) return 3;
    return 2;
  }

  /**
   * 检测文件编码
   * @param buffer 文件缓冲区
   * @returns 编码名称
   */
  static detectEncoding(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);

    // UTF-8 BOM
    if (bytes.length >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF) {
      return 'UTF-8';
    }

    // UTF-16 BE BOM
    if (bytes.length >= 2 && bytes[0] === 0xFE && bytes[1] === 0xFF) {
      return 'UTF-16BE';
    }

    // UTF-16 LE BOM
    if (bytes.length >= 2 && bytes[0] === 0xFF && bytes[1] === 0xFE) {
      return 'UTF-16LE';
    }

    return 'UTF-8';
  }

  /**
   * 从文件内容检测编码（启发式）
   * @param content 文件内容
   * @returns 编码名称
   */
  static detectEncodingFromContent(content: string): string {
    if (!content || content.length === 0) {
      return 'UTF-8';
    }

    // 检测中文字符
    const matchResult = content.match(new RegExp('[\u4e00-\u9fa5]', 'g'));
    const chineseChars = matchResult ? matchResult.length : 0;
    if (chineseChars > 0) {
      return 'UTF-8';
    }

    return 'UTF-8';
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
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.warn('[TxtParser] decodeURIComponent failed:', message);
      return lastPart;
    }
  }
}

/** TXT 解析器单例实例 */
export const txtParser = TxtParser;
