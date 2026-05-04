import { logger } from '../../../utils/Logger';
/**
 * Rule Engine - 瑙勫垯寮曟搸
 * 鐢ㄤ簬浠嶩TML涓�彁鍙栨暟鎹? *
 * @since 2.8.0
 */

/**
 * 瑙勫垯寮曟搸绫? * 鎻愪緵浠嶩TML鏂囨。涓�彁鍙栫粨鏋勫寲鏁版嵁鐨勬柟娉? */
export class RuleEngine {
  /**
   * 浠嶩TML涓�彁鍙栧崟涓�尮閰嶇粨鏋?   * @param html HTML鏂囨湰
   * @param rule CSS閫夋嫨鍣ㄦ垨姝ｅ垯琛ㄨ揪寮忚�鍒?   * @returns 鎻愬彇鐨勬枃鏈�唴瀹?   */
  static extractFromHtml(html: string, rule: string): string {
    try {
      if (!html || !rule) {
        return '';
      }

      // 鏀�寔CSS閫夋嫨鍣ㄦ牸寮? tag.class#id
      if (rule.startsWith('.') || rule.startsWith('#') || rule.startsWith('[') || !rule.includes('{')) {
        return RuleEngine.extractBySelector(html, rule);
      }

      // 鏀�寔姝ｅ垯琛ㄨ揪寮忔牸寮? /pattern/replacement
      if (rule.startsWith('/')) {
        return RuleEngine.extractByRegex(html, rule);
      }

      return '';
    } catch (error) {
      const err = error as Error;
      logger.error('[RuleEngine] extractFromHtml failed:', err.message);
      return '';
    }
  }

  /**
   * 浠嶩TML涓�彁鍙栨墍鏈夊尮閰嶇粨鏋?   * @param html HTML鏂囨湰
   * @param rule CSS閫夋嫨鍣ㄦ垨姝ｅ垯琛ㄨ揪寮忚�鍒?   * @returns 鎻愬彇鐨勬枃鏈�唴瀹规暟缁?   */
  static extractAllFromHtml(html: string, rule: string): string[] {
    try {
      if (!html || !rule) {
        return [];
      }

      const results: string[] = [];
      const regex = new RegExp(RuleEngine.escapeRegex(rule), 'g');
      let match: RegExpExecArray | null;
      while ((match = regex.exec(html)) !== null) {
        if (match[1] !== undefined) {
          results.push(match[1].trim());
        } else {
          results.push(match[0].trim());
        }
      }

      return results;
    } catch (error) {
      const err = error as Error;
      logger.error('[RuleEngine] extractAllFromHtml failed:', err.message);
      return [];
    }
  }

  /**
   * 閫氳繃CSS閫夋嫨鍣ㄦ彁鍙栧唴瀹?   */
  private static extractBySelector(html: string, selector: string): string {
    // 绠€鍗曠殑閫夋嫨鍣ㄨВ鏋愬疄鐜?    // 鍦ㄥ疄闄呭満鏅�腑锛岃繖閲屽簲璇ヤ娇鐢ㄦ洿瀹屾暣鐨凥TML瑙ｆ瀽
    try {
      const tagPattern = selector.replace(/\./g, '');
      const regex = new RegExp(`<[^>]*${tagPattern}[^>]*>([^<]*)</[^>]*>`, 'i');
      const match: RegExpExecArray | null = regex.exec(html);
      if (match && match[1]) {
        return match[1].trim();
      }
      return '';
    } catch {
      return '';
    }
  }

  /**
   * 閫氳繃姝ｅ垯琛ㄨ揪寮忔彁鍙栧唴瀹?   */
  private static extractByRegex(html: string, pattern: string): string {
    try {
      // 鍘绘帀棣栧熬鐨勬枩鏉?      let regexStr = pattern;
      if (regexStr.startsWith('/')) {
        regexStr = regexStr.substring(1);
      }
      if (regexStr.endsWith('/')) {
        regexStr = regexStr.substring(0, regexStr.length - 1);
      }

      const regex = new RegExp(regexStr);
      const match: RegExpExecArray | null = regex.exec(html);
      if (match && match[1] !== undefined) {
        return match[1].trim();
      }
      if (match) {
        return match[0].trim();
      }
      return '';
    } catch {
      return '';
    }
  }

  /**
   * 瀵规�鍒欒〃杈惧紡瀛楃�涓茶繘琛岃浆涔?   */
  private static escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

export default RuleEngine;
