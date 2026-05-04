import { logger } from '../../utils/Logger';
/**
 * Ebook Parser Utils - 鐢靛瓙涔﹁В鏋愰€氱敤宸ュ叿
 *
 * 鎻愪緵鐢靛瓙涔﹁В鏋愯繃绋嬩腑甯哥敤鐨勫伐鍏锋柟娉曪紝鍖呮嫭锛? * - 鏂囦欢鍚嶆彁鍙? * - 鏂囦欢澶у皬鏍煎紡鍖? * - 闃呰�鏃堕棿璁＄畻
 * - 鍐呭�鎽樿�鐢熸垚
 * - 鍏抽敭璇嶆彁鍙? * - 璇�█妫€娴? * - 鏂囦欢楠岃瘉
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { BookFormat } from '../core/models/book/CoreBookModel';
import { BookMetadata } from '../core/models/EbookTypes';

/**
 * 鐢靛瓙涔﹁В鏋愰€氱敤宸ュ叿绫? */
export class EbookParserUtils {

  /**
   * 浠庢枃浠惰矾寰勬彁鍙栨枃浠跺悕
   * @param filePath 鏂囦欢璺�緞
   * @returns 鏂囦欢鍚嶏紙鍚?URL 瑙ｇ爜锛?   */
  static extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const lastPart = parts[parts.length - 1];
    try {
      return decodeURIComponent(lastPart);
    } catch {
      return lastPart;
    }
  }

  /**
   * 閼惧嘲褰囬弬鍥︽�閹碘晛鐫嶉崥?   * @param fileName 閺傚洣娆㈤崥?   * @returns 閹碘晛鐫嶉崥宥忕礄閸氼偆鍋ｉ崣鍑ょ礆
   */
  static getFileExtension(fileName: string): string {
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > -1) {
      return fileName.substring(lastDot);
    }
    return '';
  }

  /**
   * 閸掓稑缂撴�妯款吇閸忓啯鏆熼幑顕嗙礄閻€劋绨�憴锝嗙€芥径杈�Е閺冭�绱?   * @param filePath 閺傚洣娆㈢捄顖氱窞
   * @returns 姒涙ǹ顓婚崗鍐╂殶閹?   */
  static createDefaultMetadata(filePath: string): BookMetadata {
    const fileName = EbookParserUtils.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    return {
      title: nameWithoutExt,
      author: 'Unknown Author',
      totalPages: 100
    };
  }

  /**
   * 閺嶇厧绱￠崠鏍ㄦ瀮娴犺泛銇囩亸?   * @param bytes 鐎涙�濡�弫?   * @returns 閺嶇厧绱￠崠鏍х摟缁楋缚瑕嗛敍鍫濐洤 "1.5 MB"閿?   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 鐠侊紕鐣绘０鍕�吀闂冨懓顕伴弮鍫曟？
   * @param wordCount 鐎涙�鏆?   * @param speed 闂冨懓顕伴柅鐔峰�閿涘牆鐡?閸掑棝鎸撻敍澶涚礉姒涙ǹ顓?300
   * @returns 闂冨懓顕伴弮鍫曟？閿涘牆鍨庨柦鐕傜礆
   */
  static calculateReadingTime(wordCount: number, speed: number = 300): number {
    return Math.ceil(wordCount / speed);
  }

  /**
   * 閻㈢喐鍨氶崘鍛�啇閹芥ǹ顩?   * @param content 閸樼喎顫愰崘鍛�啇
   * @param maxLength 閺堚偓婢堆囨毐鎼达讣绱濇�妯款吇 500
   * @returns 閹芥ǹ顩﹂弬鍥ㄦ拱
   */
  static generateSummary(content: string, maxLength: number = 500): string {
    if (!content || content.length === 0) return '';

    const text = content.replace(new RegExp('\s+', 'g'), ' ').trim();

    if (text.length <= maxLength) return text;

    let summary = text.substring(0, maxLength);
    const lastSpace = summary.lastIndexOf(' ');
    if (lastSpace > 0) {
      summary = summary.substring(0, lastSpace);
    }

    return summary + '...';
  }

  /**
   * 閹绘劕褰囬崗鎶芥暛鐠囧稄绱欓崺杞扮艾閸楁洖鐡ф０鎴犲芳閿?   * @param content 閺傚洦婀伴崘鍛�啇
   * @param limit 閸忔娊鏁�拠宥嗘殶闁插繘妾洪崚璁圭礉姒涙ǹ顓?10
   * @returns 閸忔娊鏁�拠宥呭灙鐞?   */
  static extractKeywords(content: string, limit: number = 10): string[] {
    if (!content) return [];

    const chars = content.split('');
    const chineseChars: string[] = [];
    for (let i = 0; i < chars.length; i++) {
      if (new RegExp('[\u4e00-\u9fa5]').test(chars[i])) {
        chineseChars.push(chars[i]);
      }
    }

    const freq: Record<string, number> = {};
    for (let i = 0; i < chineseChars.length; i++) {
      const word = chineseChars[i];
      if (freq[word] !== undefined) {
        freq[word] = freq[word] + 1;
      } else {
        freq[word] = 1;
      }
    }

    const entries = Object.entries(freq);
    const filtered: Array<[string, number]> = [];
    for (let i = 0; i < entries.length; i++) {
      if (entries[i][1] >= 5) {
        filtered.push(entries[i]);
      }
    }

    // 鎵嬪姩鎺掑簭 (鍐掓场鎺掑簭)
    for (let i = 0; i < filtered.length - 1; i++) {
      for (let j = 0; j < filtered.length - 1 - i; j++) {
        if (filtered[j + 1][1] > filtered[j][1]) {
          const temp = filtered[j];
          filtered[j] = filtered[j + 1];
          filtered[j + 1] = temp;
        }
      }
    }

    const result: string[] = [];
    const sliceLen = filtered.length < limit ? filtered.length : limit;
    for (let i = 0; i < sliceLen; i++) {
      result.push(filtered[i][0]);
    }

    return result;
  }

  /**
   * 濡�偓濞村�鏋冮張顒冾嚔鐟封偓
   * @param content 閺傚洦婀伴崘鍛�啇
   * @returns 鐠囶叀鈻堟禒锝囩垳閿涘牆顩?'zh-CN', 'en', 'unknown'閿?   */
  static detectLanguage(content: string): string {
    if (!content) return 'unknown';

    const chineseMatch = content.match(new RegExp('[\u4e00-\u9fa5]', 'g'));
    const chineseChars = chineseMatch ? chineseMatch.length : 0;
    const englishMatch = content.match(new RegExp('[a-zA-Z]', 'g'));
    const englishChars = englishMatch ? englishMatch.length : 0;
    const total = content.length;

    if (chineseChars / total > 0.3) return 'zh-CN';
    if (englishChars / total > 0.3) return 'en';
    return 'unknown';
  }

  /**
   * 妤犲矁鐦夐弬鍥︽�閺嶇厧绱￠弰顖氭儊閸栧綊鍘?   * @param filePath 閺傚洣娆㈢捄顖氱窞
   * @param format 閺堢喐婀滈惃鍕�姛缁�秵鐗稿�?   * @returns 閺勵垰鎯侀張澶嬫櫏
   */
  static async validateFile(filePath: string, format: BookFormat): Promise<boolean> {
    try {
      const stat = await fileIo.stat(filePath);
      if (!stat.size || stat.size === 0) {
        logger.error('[EbookParserUtils] File size is 0');
        return false;
      }

      const fileName = EbookParserUtils.extractFileName(filePath);
      const ext = EbookParserUtils.getFileExtension(fileName).toLowerCase();

      let validExts: string[] = [];
      switch (format) {
        case BookFormat.PDF:
          validExts = ['.pdf'];
          break;
        case BookFormat.EPUB:
          validExts = ['.epub'];
          break;
        case BookFormat.MOBI:
          validExts = ['.mobi'];
          break;
        case BookFormat.TXT:
          validExts = ['.txt'];
          break;
        case BookFormat.DOCX:
          validExts = ['.docx'];
          break;
        case BookFormat.CBZ:
          validExts = ['.cbz'];
          break;
        case BookFormat.CBR:
          validExts = ['.cbr'];
          break;
      }

      return validExts.includes(ext);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[EbookParserUtils] File validation failed:', message);
      return false;
    }
  }
}

/** 閻㈤潧鐡欐稊锕佇掗弸鎰�紣閸忓嘲宕熸笟瀣�杽娓?*/
export const ebookParserUtils = EbookParserUtils;
