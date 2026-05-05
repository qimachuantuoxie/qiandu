import { logger } from '../../utils/Logger';
// 电子书格式解析器 - 简化版
import { BookFormat, BookInfoResult } from '../models/CoreBookModel';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { nativeModules } from './NativeModules';

export interface NavPoint {
  label: string;
  order: number;
  level: number;
}

export interface PdfInfo {
  Title?: string;
  Author?: string;
  Publisher?: string;
  ISBN?: string;
  Language?: string;
  CreationDate?: string;
  ModDate?: string;
}

export interface PdfOutlineItem {
  title?: string;
  Title?: string;
  pageIndex?: number;
  PageIndex?: number;
  children?: PdfOutlineItem[];
}

export interface EpubMetadata {
  title?: string;
  creator?: string[];
  contributor?: string[];
  publisher?: string;
  language?: string[];
  identifier?: string[];
  date?: string;
  description?: string;
  subject?: string[];
}

export interface ChapterInfo {
  id: string;
  title: string;
  startOffset: number;
  endOffset?: number;
  href?: string;
}

export interface BookMetadata {
  title: string;
  author: string;
  publisher?: string;
  isbn?: string;
  language?: string;
  description?: string;
  coverData?: string;
  totalPages: number;
  wordCount?: number;
  fileSize?: number;
  createdDate?: string;
  modifiedDate?: string;
}

export interface ParseResult {
  metadata: BookMetadata;
  content: string;
  chapters: ChapterInfo[];
  success: boolean;
  error?: string;
}

export class EbookParser {
  async parseFile(filePath: string, format: BookFormat): Promise<ParseResult> {
    try {
      // 使用原生模块解析（如果可用）
      const result: ParseResult | null = await EbookParser.parseWithNativeParser(filePath, format);
      if (result) {
        return result;
      }

      // Fallback: 返回默认结果
      return EbookParser.createDefaultResult(filePath);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('EbookParser parseFile failed:', message);
      logger.error('EbookParser parseFile failed:', message);
      return EbookParser.createDefaultResult(filePath, message);
    }
  }

  static bookFormatToDocumentFormat(format: BookFormat): number {
    return format.charCodeAt(0);
  }

  static createDefaultMetadata(filePath: string): BookMetadata {
    const fileName = filePath.split('/').pop() || filePath.split('\\').pop() || 'Unknown';
    const title = fileName.split('.').slice(0, -1).join('.');
    return {
      title: title || 'Unknown',
      author: 'Unknown',
      publisher: undefined,
      isbn: undefined,
      language: 'zh-CN',
      description: undefined,
      coverData: undefined,
      totalPages: 0,
      wordCount: undefined,
      createdDate: undefined,
      modifiedDate: undefined
    };
  }

  static createDefaultResult(filePath: string, error?: string): ParseResult {
    return {
      metadata: EbookParser.createDefaultMetadata(filePath),
      content: '',
      chapters: [],
      success: false,
      error: error || 'Parser not available'
    };
  }

  private static async parseWithNativeParser(filePath: string, format: BookFormat): Promise<ParseResult | null> {
    // TODO: 原生解析模块待实现
    return null;
  }

  static async extractText(filePath: string): Promise<string> {
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const decoder = new util.TextDecoder('utf-8');
      return decoder.decodeToString(new Uint8Array(buffer));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('EbookParser extractText failed:', message);
      return '';
      return '';
    }
  }

  // 简化的作者提取 - 避免使用被破坏的正则表达式
  static extractAuthorFromText(content: string): string {
    const lines = content.split('\n').slice(0, 20);
    
    for (const line of lines) {
      const trimmed = line.trim();
      
      // 简单的作者匹配模式
      if (trimmed.includes('作者') && trimmed.includes(':')) {
        const parts = trimmed.split(':');
        if (parts.length >= 2 && parts[1].trim().length < 30) {
          return parts[1].trim();
        }
      }
      
      if (trimmed.includes('著') && trimmed.length < 30) {
        return trimmed.replace(new RegExp('[著编]', 'g'), '').trim();
      }
    }
    
    return 'Unknown';
  }

  static extractPublisherFromText(content: string): string {
    const lines = content.split('\n').slice(0, 20);
    
    for (const line of lines) {
      const trimmed = line.trim();
      
      if (trimmed.includes('出版') && trimmed.includes(':')) {
        const parts = trimmed.split(':');
        if (parts.length >= 2 && parts[1].trim().length < 50) {
          return parts[1].trim();
        }
      }
    }
    
    return '';
  }
}
