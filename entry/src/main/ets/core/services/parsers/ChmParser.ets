import { logger } from '../../../utils/Logger';
import { DocumentFormat, ChapterInfo, ParseResult, ParserConfig, BookMetadata } from '../models/DocumentModels';
import { BaseParserUtils } from './BaseParserUtils';

interface ChmFileInfo {
  title: string;
  author: string;
  pageCount: number;
  fileCount: number;
  success: number;
}

interface ChmNativeModule {
  getChmInfo(filePath: string): ChmFileInfo;
}

let chmModule: ChmNativeModule | null = null;

function initChmModule(): void {
  try {
    // Use module-level approach instead of globalThis (not supported in ArkTS)
    chmModule = null;
  } catch (error) {
    logger.warn('ChmParser: Native module not available');
  }
}
initChmModule();

interface ChmChapterInfo {
  title: string;
  path: string;
  offset: number;
  length: number;
}

export class ChmParser {

  static async parse(filePath: string, config: ParserConfig): Promise<ParseResult> {
    logger.info('ChmParser: Parsing', filePath);

    try {
      if (!chmModule) {
        return { success: false, error: 'CHM native module not available' };
      }

      const chmInfo = chmModule.getChmInfo(filePath);

      if (!chmInfo || chmInfo.success !== 1) {
        return { success: false, error: 'Failed to parse CHM file' };
      }

      const chapters: ChapterInfo[] = [];
      if (config.extractChapters && chmInfo.fileCount > 0) {
        chapters.push({
          index: 0,
          title: 'Contents',
          content: '',
          offset: 0
        });
      }

      const result: ParseResult = {
        success: true,
        metadata: {
          title: chmInfo.title || BaseParserUtils.extractFileName(filePath),
          author: chmInfo.author || 'Unknown Author',
          language: 'zh-CN',
          pageCount: chmInfo.pageCount,
          wordCount: 0,
          format: DocumentFormat.CHM,
          fileSize: 0
        },
        chapters: chapters,
        pages: []
      };

      const metaTitle = result.metadata?.title || 'Unknown';
      logger.info('ChmParser: Success', metaTitle);
      return result;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('ChmParser: Parse failed', err.message);
      return { success: false, error: err.message };
    }
  }

  static isValidChmFile(filePath: string): boolean {
    try {
      if (!filePath.toLowerCase().endsWith('.chm')) {
        return false;
      }
      return true;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('ChmParser: Validation failed', err.message);
      return false;
    }
  }

  static async getMetadata(filePath: string): Promise<Partial<BookMetadata>> {
    try {
      if (!chmModule) {
        return {};
      }

      const chmInfo = chmModule.getChmInfo(filePath);

      return {
        title: chmInfo.title,
        author: chmInfo.author,
        pageCount: chmInfo.pageCount,
        format: DocumentFormat.CHM
      };
    } catch (error) {
      const err = error as Error;
      logger.error('ChmParser: GetMetadata failed', err.message);
      return {};
    }
  }

  static async extractContent(filePath: string, chapterPath: string): Promise<string | null> {
    try {
      logger.warn('ChmParser: Content extraction not implemented');
      return null;
    } catch (error) {
      const err = error as Error;
      logger.error('ChmParser: ExtractContent failed', err.message);
      return null;
    }
  }

  static async getTableOfContents(filePath: string): Promise<ChapterInfo[]> {
    try {
      logger.warn('ChmParser: TOC extraction not implemented');
      return [];
    } catch (error) {
      const err = error as Error;
      logger.error('ChmParser: GetTOC failed', err.message);
      return [];
    }
  }
}
