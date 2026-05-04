import { logger } from '../../utils/Logger';
/**
 * DOCX Parser - Word 鏂囨。瑙ｆ瀽鍣?
 *
 * 鎻愪緵 DOCX 鏍煎紡鏂囨。鐨勮В鏋愬姛鑳斤紝鍖呮嫭锛?
 * - ZIP 瀹瑰櫒瑙ｅ帇锛圖OCX 鏈�川鏄?ZIP锛?
 * - 鏍稿績鍏冩暟鎹�彁鍙栵紙鏍囬�銆佷綔鑰呯瓑锛?
 * - Word XML 鏂囨湰鎻愬彇
 * - 绔犺妭鏅鸿兘璇嗗埆
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ZipUtils } from '../utils/ZipUtils';
import { LocalChapterInfo, ParseResult, ZipParseResult } from '../models/EbookTypes';

/**
 * DOCX 瑙ｆ瀽鍣ㄧ被
 */
export class DocxParser {

  /**
   * 瑙ｆ瀽 DOCX 鏂囦欢
   * @param filePath DOCX 鏂囦欢璺�緞
   * @returns 瑙ｆ瀽缁撴灉
   */
  static async parse(filePath: string): Promise<ParseResult> {
    logger.info('[DocxParser] Parsing DOCX file:', filePath);

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
      logger.warn('[DocxParser] DOCX parsing failed:', message);
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
   * 浠?DOCX XML 鍐呭�涓�彁鍙栨枃鏈?
   * @param xmlContent XML 鍐呭�
   * @returns 鎻愬彇鐨勬枃鏈?
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
   * 瑙ｆ瀽绔犺妭缁撴瀯锛堝�鐢?TXT 鐨勭珷鑺傝瘑鍒�€昏緫锛?
   * @param content 鏂囨。鍐呭�
   * @returns 绔犺妭鍒楄〃
   */
  private static parseTxtChapters(content: string): LocalChapterInfo[] {
    const chapters: LocalChapterInfo[] = [];
    const lines = content.split('\n');

    // 澶氱�绔犺妭鏍囬�鍖归厤妯″紡
    const patterns: RegExp[] = [
      new RegExp('^(绗琜涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗佺櫨鍗冮浂\\d]+绔燵\\s\\.路]*(.+)?$', ''),
      new RegExp('^(绗琜\\d]+绔燵\\s\\.路]*(.+)?$', ''),
      new RegExp('^(绗琜涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗佺櫨鍗僜\d]+鑺?[\\s\\.路]*(.+)?$', ''),
      new RegExp('^(Chapter\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(Part\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(\\d+)[\\s\\.路]+(.+)$', ''),
      new RegExp('^\\d+\\.\\s+(.+)$', ''),
      new RegExp('^([涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗乚+)[\\s\\.路]+(.+)$', '')
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

    logger.info('[DocxParser] Parsed ' + chapters.length + ' chapters');
    return chapters;
  }

  /**
   * 鑾峰彇绔犺妭灞傜骇
   * @param title 绔犺妭鏍囬�
   * @returns 灞傜骇锛?=绔狅紝2=鑺傦紝3=灏忚妭锛?
   */
  private static getChapterLevel(title: string): number {
    if (new RegExp('^绗?*鑺?).test(title)) return 2;
    if (new RegExp('^绗?).test(title)) return 1;
    if (new RegExp('^\\d+\\.').test(title)) return 3;
    return 2;
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

/** DOCX 瑙ｆ瀽鍣ㄥ崟渚嬪疄渚?*/
export const docxParser = DocxParser;
