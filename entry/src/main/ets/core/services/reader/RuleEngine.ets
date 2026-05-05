import { logger } from '../../../utils/Logger';
/**
 * Rule Engine - 规则引擎
 * 用于从HTML中提取数据
 *
 * @since 2.8.0
 */

/**
 * 规则引擎类
 * 提供从HTML文档中提取结构化数据的方法
 */
export class RuleEngine {
  /**
   * 从HTML中提取单个匹配结果
   * @param html HTML文本
   * @param rule CSS选择器或正则表达式规则
   * @returns 提取的文本内容
   */
  static extractFromHtml(html: string, rule: string): string {
    try {
      if (!html || !rule) {
        return '';
      }

      // 支持CSS选择器格式: tag.class#id
      if (rule.startsWith('.') || rule.startsWith('#') || rule.startsWith('[') || !rule.includes('{')) {
        return RuleEngine.extractBySelector(html, rule);
      }

      // 支持正则表达式格式: /pattern/replacement
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
   * 从HTML中提取所有匹配结果
   * @param html HTML文本
   * @param rule CSS选择器或正则表达式规则
   * @returns 提取的文本内容数组
   */
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
   * 通过CSS选择器提取内容
   */
  private static extractBySelector(html: string, selector: string): string {
    // 简单的选择器解析实现
    // 在实际场景中，这里应该使用更完整的HTML解析
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
   * 通过正则表达式提取内容
   */
  private static extractByRegex(html: string, pattern: string): string {
    try {
      // 去掉首尾的斜杠
      let regexStr = pattern;
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
   * 对规则表达式字符串进行转义
   */
  private static escapeRegex(str: string): string {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

export default RuleEngine;
