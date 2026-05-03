/**
 * DOCX Parser - Word 文档解析器
 *
 * 提供 DOCX 格式文档的解析功能，包括：
 * - ZIP 容器解压（DOCX 本质是 ZIP）
 * - 核心元数据提取（标题、作者等）
 * - Word XML 文本提取
 * - 章节智能识别
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ZipUtils } from '../utils/ZipUtils';
import { LocalChapterInfo, ParseResult, ZipParseResult } from '../core/models/EbookTypes';

/**
 * DOCX 解析器类
 */
export class DocxParser {

  /**
   * 解析 DOCX 文件
   * @param filePath DOCX 文件路径
   * @returns 解析结果
   */
  static async parse(filePath: string): Promise<ParseResult> {
    console.info('[DocxParser] Parsing DOCX file:', filePath);

    const fileName = DocxParser.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    try {
      const buffer = await DocxParser.readFileBuffer(filePath);
      const zipResult: ZipParseResult = ZipUtils.parseZipBuffer(buffer);

      let title = nameWithoutExt;
      let author = 'Unknown Author';

      const entryCount1 = zipResult.entries.length;
      for (let i = 0; i < entryCount1; i++) {
        const entry = zipResult.entries[i];
        if (entry.path === 'docProps/core.xml' && entry.data) {
          const decoder = new util.TextDecoder('utf-8');
          const corePropsXml = decoder.decode(new Uint8Array(entry.data));

          const titleMatch = corePropsXml.match(new RegExp('<dc:title[^>]*>([^<]*)<\/dc:title>', 'i'));
          if (titleMatch && titleMatch.length >= 2) {
            title = titleMatch[1].trim() || title;
          }

          const authorMatch = corePropsXml.match(new RegExp('<dc:creator[^>]*>([^<]*)<\/dc:creator>', 'i'));
          if (authorMatch && authorMatch.length >= 2) {
            author = authorMatch[1].trim() || author;
          }
        }
      }

      let fullText = '';
      const entryCount2 = zipResult.entries.length;
      for (let i = 0; i < entryCount2; i++) {
        const entry = zipResult.entries[i];
        if (entry.path.startsWith('word/') && entry.path.endsWith('.xml') && entry.data) {
          const decoder = new util.TextDecoder('utf-8');
          const xmlContent = decoder.decode(new Uint8Array(entry.data));
          const text = DocxParser.extractDocxText(xmlContent);
          if (text) {
            fullText += text + '\n\n';
          }
        }
      }

      const chapters = DocxParser.parseTxtChapters(fullText);
      const wordCount = fullText.replace(new RegExp('\s', 'g'), '').length;
      const totalPages = Math.ceil(wordCount / 500);

      return {
        metadata: {
          title: title,
          author: author,
          totalPages: totalPages > 0 ? totalPages : 80,
          wordCount: wordCount
        },
        content: fullText,
        chapters: chapters,
        success: true
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.warn('[DocxParser] DOCX parsing failed:', message);
      return {
        metadata: {
          title: nameWithoutExt,
          author: 'Unknown Author',
          totalPages: 80
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
   * 从 DOCX XML 内容中提取文本
   * @param xmlContent XML 内容
   * @returns 提取的文本
   */
  private static extractDocxText(xmlContent: string): string {
    let text = '';

    text = xmlContent.replace(new RegExp('<w:p[^>]*>', 'gi'), '\n');
    text = text.replace(new RegExp('<\/w:p>', 'gi'), '');

    text = text.replace(new RegExp('<w:br[^>]*\/>', 'gi'), '\n');

    text = text.replace(new RegExp('<[^>]+>', 'g'), ' ');

    text = text.replace(new RegExp('&nbsp;', 'gi'), ' ');
    text = text.replace(new RegExp('&amp;', 'gi'), '&');
    text = text.replace(new RegExp('&lt;', 'gi'), '<');
    text = text.replace(new RegExp('&gt;', 'gi'), '>');

    text = text.replace(new RegExp('\s+', 'g'), ' ');
    text = text.trim();

    return text;
  }

  /**
   * 解析章节结构（复用 TXT 的章节识别逻辑）
   * @param content 文档内容
   * @returns 章节列表
   */
  private static parseTxtChapters(content: string): LocalChapterInfo[] {
    const chapters: LocalChapterInfo[] = [];
    const lines = content.split('\n');

    // 多种章节标题匹配模式
    const patterns: RegExp[] = [
      new RegExp('^(第[一二三四五六七八九十百千零\\d]+章[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(第[\\d]+章[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(第[一二三四五六七八九十百千\\d]+节)[\\s\\.·]*(.+)?$', ''),
      new RegExp('^(Chapter\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(Part\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(\\d+)[\\s\\.·]+(.+)$', ''),
      new RegExp('^\\d+\\.\\s+(.+)$', ''),
      new RegExp('^([一二三四五六七八九十]+)[\\s\\.·]+(.+)$', '')
    ];

    const isChapterTitle = (line: string): boolean => {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.length > 100) return false;

      for (let i = 0; i < patterns.length; i++) {
        const pattern = patterns[i];
        if (pattern.test(trimmed)) return true;
      }

      return false;
    };

    let currentChapterStart = -1;
    const linesCount = lines.length;

    for (let i = 0; i < linesCount; i++) {
      const line = lines[i];

      if (isChapterTitle(line)) {
        if (currentChapterStart >= 0 && currentChapterStart < i) {
          const chapterTitle = lines[currentChapterStart].trim();
          chapters.push({
            id: 'chapter_' + chapters.length,
            title: chapterTitle,
            startOffset: currentChapterStart,
            endOffset: i,
            level: DocxParser.getChapterLevel(chapterTitle)
          });
        }

        currentChapterStart = i;
      }
    }

    if (currentChapterStart >= 0 && currentChapterStart < linesCount) {
      const chapterTitle = lines[currentChapterStart].trim();
      chapters.push({
        id: 'chapter_' + chapters.length,
        title: chapterTitle,
        startOffset: currentChapterStart,
        endOffset: linesCount,
        level: DocxParser.getChapterLevel(chapterTitle)
      });
    }

    console.info('[DocxParser] Parsed ' + chapters.length + ' chapters');
    return chapters;
  }

  /**
   * 获取章节层级
   * @param title 章节标题
   * @returns 层级（1=章，2=节，3=小节）
   */
  private static getChapterLevel(title: string): number {
    if (new RegExp('^第.*节').test(title)) return 2;
    if (new RegExp('^第').test(title)) return 1;
    if (new RegExp('^\\d+\\.').test(title)) return 3;
    return 2;
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

/** DOCX 解析器单例实例 */
export const docxParser = DocxParser;
