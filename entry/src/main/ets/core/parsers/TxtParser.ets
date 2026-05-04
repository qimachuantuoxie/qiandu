import { logger } from '../../utils/Logger';
/**
 * TXT Parser - 绾�枃鏈�數瀛愪功瑙ｆ瀽鍣?
 *
 * 鎻愪緵 TXT 鏍煎紡鐢靛瓙涔︾殑瑙ｆ瀽鍔熻兘锛屽寘鎷�細
 * - 鏂囦欢璇诲彇涓庣紪鐮佹�娴?
 * - 鍏冩暟鎹�彁鍙栵紙浠庢枃浠跺ご閮ㄦ彁鍙栦綔鑰呫€佺畝浠嬬瓑锛?
 * - 绔犺妭鏅鸿兘璇嗗埆锛堟敮鎸佸�绉嶄腑鏂囩珷鑺傛牸寮忥級
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BookMetadata, LocalChapterInfo, ParseResult } from '../models/EbookTypes';

/**
 * TXT 瑙ｆ瀽鍣ㄧ被
 */
export class TxtParser {

  /**
   * 瑙ｆ瀽 TXT 鏂囦欢
   * @param filePath TXT 鏂囦欢璺�緞
   * @returns 瑙ｆ瀽缁撴灉
   */
  static async parse(filePath: string): Promise<ParseResult> {
    logger.info('[TxtParser] Parsing TXT file:', filePath);

    try {
      const content = await TxtParser.readTxtFile(filePath);
      const encoding = TxtParser.detectEncodingFromContent(content);
      logger.info('[TxtParser] Detected encoding:', encoding);

      const metadata = TxtParser.extractTxtMetadata(content, filePath);
      const chapters = TxtParser.parseTxtChapters(content);

      logger.info('[TxtParser] TXT parsed: ' + chapters.length + ' chapters, ' + metadata.wordCount + ' characters');

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
   * 璇诲彇 TXT 鏂囦欢鍐呭�
   * @param filePath 鏂囦欢璺�緞
   * @returns 鏂囦欢鍐呭�
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

      // 绉婚櫎 BOM 鏍囪�
      if (encoding === 'UTF-8' && content.charCodeAt(0) === 0xFEFF) {
        content = content.substring(1);
      }

      return content;
    } catch (err) {
      logger.error('[TxtParser] Read file failed:', err);
      throw new Error(message instanceof Error ? message.message : 'Read file failed');
    }
  }

  /**
   * 浠?TXT 鏂囦欢澶撮儴鎻愬彇鍏冩暟鎹?
   * @param content 鏂囦欢鍐呭�
   * @param filePath 鏂囦欢璺�緞
   * @returns 涔︾睄鍏冩暟鎹?
   */
  private static extractTxtMetadata(content: string, filePath: string): BookMetadata {
    const fileName = TxtParser.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    const lines = content.split('\n');
    let author = 'Unknown Author';
    let description = '';
    let publisher: string | undefined = undefined;
    let language = 'zh-CN';

    // 浠庢枃浠跺ご閮�紙鍓?0琛岋級鎻愬彇鍏冩暟鎹?
    const headerLines = lines.slice(0, Math.min(50, lines.length));
    let headerText = '';
    for (let i = 0; i < headerLines.length; i++) {
      if (i > 0) {
        headerText += '\n';
      }
      headerText += headerLines[i];
    }

    // 灏濊瘯澶氱�浣滆€呭尮閰嶆ā寮?
    const authorPatterns: RegExp[] = [
      new RegExp('浣滆€匸:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('钁楄€匸:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('鏂囨�[:\uff1a]\s*(.+?)(?:\n|$)', ''),
      new RegExp('(.+?)\s*钁梊s*(?:\n|$)', '')
    ];

    for (let i = 0; i < authorPatterns.length; i++) {
      const pattern = authorPatterns[i];
      const match = headerText.match(pattern);
      if (match && match[1] && match[1].trim().length < 30) {
        author = match[1].trim();
        break;
      }
    }

    // 鎻愬彇鍑虹増绀句俊鎭?
    const publisherPattern = new RegExp('鍑虹増绀綶:\uff1a]\s*(.+?)(?:\n|$)', '');
    const pubMatch = headerText.match(publisherPattern);
    if (pubMatch) {
      publisher = pubMatch[1].trim();
    }

    // 鎻愬彇绠€浠?鎻忚堪
    const descPatterns: RegExp[] = [
      new RegExp('绠€浠媅:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|Author|ISBN|$)', ''),
      new RegExp('鍐呭�浠嬬粛[:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|$)', ''),
      new RegExp('涔︾睄绠€浠媅:\uff1a]\s*([\s\S]{0,200}?)(?=\n\n|$)', '')
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
   * 瑙ｆ瀽 TXT 绔犺妭缁撴瀯
   * @param content 鏂囦欢鍐呭�
   * @returns 绔犺妭鍒楄〃
   */
  private static parseTxtChapters(content: string): LocalChapterInfo[] {
    const chapters: LocalChapterInfo[] = [];
    const lines = content.split('\n');

    // 澶氱�绔犺妭鏍囬�鍖归厤妯″紡
    const patterns = [
      new RegExp('^(绗?[涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗佺櫨鍗冮浂\\d]+绔?[\\s\\.路]*(.+)?$', ''),
      new RegExp('^(绗?[\\d]+绔?[\\s\\.路]*(.+)?$', ''),
      new RegExp('^(鍗?[涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗佺櫨鍗僜\d]+)[\\s\\.路]*(.+)?$', ''),
      new RegExp('^(Chapter\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(Part\\s+\\d+)[\\s\\.]*(.+)?$', 'i'),
      new RegExp('^(\\d+)[\\s\\.路]+(.+)$', ''),
      new RegExp('^\\d+\\.\\s+(.+)$', ''),
      new RegExp('^([涓€浜屼笁鍥涗簲鍏�竷鍏�節鍗乚+)[\\s\\.路]+(.+)$', ''),
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
        // 淇濆瓨涓婁竴涓�珷鑺?
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

    // 淇濆瓨鏈€鍚庝竴涓�珷鑺?
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

    logger.info('[TxtParser] Parsed ' + chapters.length + ' chapters');
    return chapters;
  }

  /**
   * 鑾峰彇绔犺妭灞傜骇
   * @param title 绔犺妭鏍囬�
   * @returns 灞傜骇锛?=鍗?2=绔?3=鑺傦級
   */
  private static getChapterLevel(title: string): number {
    if (new RegExp('^鍗?').test(title)) return 1;
    if (new RegExp('^绗?绔?').test(title)) return 2;
    if (new RegExp('^\\d+\\.').test(title)) return 3;
    return 2;
  }

  /**
   * 妫€娴嬫枃浠剁紪鐮?
   * @param buffer 鏂囦欢缂撳啿鍖?
   * @returns 缂栫爜鍚嶇О
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
   * 浠庢枃浠跺唴瀹规�娴嬬紪鐮侊紙鍚�彂寮忥級
   * @param content 鏂囦欢鍐呭�
   * @returns 缂栫爜鍚嶇О
   */
  static detectEncodingFromContent(content: string): string {
    if (!content || content.length === 0) {
      return 'UTF-8';
    }

    // 妫€娴嬩腑鏂囧瓧绗?
    const matchResult = content.match(new RegExp('[\u4e00-\u9fa5]', 'g'));
    const chineseChars = matchResult ? matchResult.length : 0;
    if (chineseChars > 0) {
      return 'UTF-8';
    }

    return 'UTF-8';
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
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.warn('[TxtParser] decodeURIComponent failed:', message);
      return lastPart;
    }
  }
}

/** TXT 瑙ｆ瀽鍣ㄥ崟渚嬪疄渚?*/
export const txtParser = TxtParser;
