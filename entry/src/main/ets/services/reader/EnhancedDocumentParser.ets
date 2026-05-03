/**
 * 澧炲己鏂囨。瑙ｆ瀽鏈嶅姟 - 涓诲叆鍙?
 * Enhanced Document Parser Service - Main Entry Point
 * 
 * 鏀寔鏍煎紡锛?
 * - PDF, EPUB, TXT, MOBI, DOCX, DOC, RTF
 * - AZW, AZW3, DJVU, CHM, FB2, ODT
 * - Comic: CBR, CBZ
 * - HTML
 * 
 * @since 5.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { BaseParserUtils, ZipParseResult } from '../parsers/BaseParserUtils';
import { ZipFormatParser } from '../parsers/ZipFormatParser';
import { TextFormatParser } from '../parsers/TextFormatParser';
import { XmlFormatParser } from '../parsers/XmlFormatParser';
import { OtherFormatParser } from '../parsers/OtherFormatParser';
import { HuaweiKitParser } from '../parsers/HuaweiKitParser';
import { DjvuParser } from '../parsers/DjvuParser';
import { ChmParser } from '../parsers/ChmParser';
import { DocumentFormat, BookMetadata, ChapterInfo, ParseResult, ParserConfig } from '../models/DocumentModels';

/**
 * 榛樿瑙ｆ瀽閰嶇疆
 */
const DEFAULT_CONFIG: ParserConfig = {
  extractContent: true,
  extractChapters: true,
  extractCover: true,
  paginate: true,
  charsPerPage: 3000
};

/**
 * 澧炲己鏂囨。瑙ｆ瀽鍣ㄧ被
 */
class EnhancedDocumentParser {
  /** 鍗曚緥瀹炰緥 */
  private static instance: EnhancedDocumentParser;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): EnhancedDocumentParser {
    if (!EnhancedDocumentParser.instance) {
      EnhancedDocumentParser.instance = new EnhancedDocumentParser();
    }
    return EnhancedDocumentParser.instance;
  }

  /**
   * 妫€娴嬫枃妗ｆ牸寮?
   */
  detectFormat(filePath: string): DocumentFormat {
    // 鍏堝皾璇曢€氳繃鏂囦欢澶存娴?
    const headerFormat = this.detectFormatByHeader(filePath);
    if (headerFormat !== DocumentFormat.UNKNOWN) {
      return headerFormat;
    }

    // 鍥為€€鍒版墿灞曞悕妫€娴?
    const ext = this.getFileExtension(filePath).toLowerCase();
    return this.extToFormat(ext);
  }

  /**
   * 閫氳繃鏂囦欢澶存娴嬫牸寮忥紙澧炲己鐗堬級
   * 鏀寔鏇村 Magic Number 妫€娴?
   */
  private detectFormatByHeader(filePath: string): DocumentFormat {
    try {
      const file = fileIo.openSync(filePath, 0o0);
      const stat = fileIo.statSync(filePath);
      const readSize = Math.min(stat.size, 512); // 璇诲彇鏇村瀛楄妭鐢ㄤ簬妫€娴?
      const buffer = new ArrayBuffer(readSize);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const uint8Array = new Uint8Array(buffer);

      // PDF: %PDF-
      if (uint8Array.length >= 5 &&
          uint8Array[0] === 0x25 && uint8Array[1] === 0x50 &&
          uint8Array[2] === 0x44 && uint8Array[3] === 0x46 &&
          uint8Array[4] === 0x2D) {
        return DocumentFormat.PDF;
      }

      // MOBI: 绗竴涓?PALM DOC ID 涓?0x44 鎴?0x45锛屽亸绉?60 澶勬湁 BOOKMOBILE
      if (uint8Array.length >= 68) {
        const palmDocId = uint8Array[0x3C]; // 鍋忕Щ 60
        if (palmDocId === 0x44 || palmDocId === 0x45) {
          // 妫€鏌ュ亸绉?60-67 鏄惁涓?"BOOKMOBI" 鎴?"TEXtREAd"
          const mobiSignature = String.fromCharCode(
            uint8Array[0x3C], uint8Array[0x3D], uint8Array[0x3E], uint8Array[0x3F],
            uint8Array[0x40], uint8Array[0x41], uint8Array[0x42], uint8Array[0x43]
          );
          if (mobiSignature === 'BOOKMOBI' || mobiSignature === 'TEXtREAd') {
            return DocumentFormat.MOBI;
          }
        }
      }

      // AZW3: 绫讳技 MOBI 浣嗘湁 CDIC 鏍囪
      if (uint8Array.length >= 68) {
        const palmDocId = uint8Array[0x3C];
        if (palmDocId === 0x45) {
          // 妫€鏌ユ槸鍚︽湁 AZW3 鐗瑰緛
          const mobiType = uint8Array[0x6C] | (uint8Array[0x6D] << 8) | 
                          (uint8Array[0x6E] << 16) | (uint8Array[0x6F] << 24);
          if (mobiType === 0x00000004 || mobiType === 0x00000104) { // KF8/AZW3
            return DocumentFormat.AZW3;
          }
        }
      }

      // ZIP-based: PK\x03\x04 (EPUB, DOCX, ODT, CBZ)
      if (uint8Array.length >= 4 &&
          uint8Array[0] === 0x50 && uint8Array[1] === 0x4B &&
          uint8Array[2] === 0x03 && uint8Array[3] === 0x04) {
        // EPUB 鐗规畩妫€娴嬶細妫€鏌?META-INF/container.xml
        const ext = this.getFileExtension(filePath).toLowerCase();
        if (ext === 'epub') return DocumentFormat.EPUB;
        if (ext === 'docx') return DocumentFormat.DOCX;
        if (ext === 'odt') return DocumentFormat.ODT;
        if (ext === 'cbz') return DocumentFormat.CBZ;
        // 閫氳繃鍐呭妫€娴?
        return this.detectZipContent(uint8Array, ext);
      }

      // OLE-based: D0 CF 11 E0 A1 B1 1A E1 (DOC)
      if (uint8Array.length >= 8 &&
          uint8Array[0] === 0xD0 && uint8Array[1] === 0xCF &&
          uint8Array[2] === 0x11 && uint8Array[3] === 0xE0 &&
          uint8Array[4] === 0xA1 && uint8Array[5] === 0xB1 &&
          uint8Array[6] === 0x1A && uint8Array[7] === 0xE1) {
        return DocumentFormat.DOC;
      }

      // DJVU: AT&TFORM....DJVU 鎴?DJVM
      if (uint8Array.length >= 12) {
        const djvuHeader = String.fromCharCode(
          uint8Array[0], uint8Array[1], uint8Array[2], uint8Array[3]
        );
        if (djvuHeader === 'AT&T' || djvuHeader === 'FORM') {
          // 妫€鏌ユ槸鍚︽湁 DJVU/DJVM 鏍囪
          for (let i = 8; i < Math.min(uint8Array.length, 20); i++) {
            if (uint8Array[i] === 0x44 && uint8Array[i+1] === 0x4A && 
                uint8Array[i+2] === 0x56 && uint8Array[i+3] === 0x55) {
              return DocumentFormat.DJVU;
            }
          }
        }
      }

      // CHM: ITSF
      if (uint8Array.length >= 4 &&
          uint8Array[0] === 0x49 && uint8Array[1] === 0x54 &&
          uint8Array[2] === 0x53 && uint8Array[3] === 0x46) {
        return DocumentFormat.CHM;
      }

      // RAR5: Rar!\x1a\x07\x01\x00
      if (uint8Array.length >= 8 &&
          uint8Array[0] === 0x52 && uint8Array[1] === 0x61 &&
          uint8Array[2] === 0x72 && uint8Array[3] === 0x21 &&
          uint8Array[4] === 0x1A && uint8Array[5] === 0x07 &&
          uint8Array[6] === 0x01 && uint8Array[7] === 0x00) {
        return DocumentFormat.CBR;
      }

      // RAR4: Rar!\x1a\x07
      if (uint8Array.length >= 6 &&
          uint8Array[0] === 0x52 && uint8Array[1] === 0x61 &&
          uint8Array[2] === 0x72 && uint8Array[3] === 0x21 &&
          uint8Array[4] === 0x1A && uint8Array[5] === 0x07) {
        return DocumentFormat.CBR;
      }

      // FB2: 妫€鏌?XML 澹版槑鍜?FictionBook 鍛藉悕绌洪棿
      if (uint8Array.length >= 50) {
        const header = bytesToString(uint8Array, 0, 100);
        if (header.includes('<?xml') && (header.includes('FictionBook') || header.includes('fictionbook'))) {
          return DocumentFormat.FB2;
        }
      }

      // HTML: 妫€鏌?<!DOCTYPE html 鎴?<html
      if (uint8Array.length >= 20) {
        const header = bytesToString(uint8Array, 0, 200).toLowerCase();
        if (header.startsWith('<!doctype html') || header.startsWith('<html') || header.startsWith('<?xml')) {
          const ext = this.getFileExtension(filePath).toLowerCase();
          if (ext === 'html' || ext === 'htm') {
            return DocumentFormat.HTML;
          }
        }
      }

    } catch (error) {
      const err = error as Error;
      console.warn('[Parser] Header detection failed: ' + err.message);
    }

    return DocumentFormat.UNKNOWN;
  }

  /**
   * 妫€娴?ZIP 鍐呭锛堥€氳繃鍐呴儴鏂囦欢鍚嶏級
   */
  private detectZipContent(uint8Array: Uint8Array, ext: string): DocumentFormat {
    try {
      // 鏌ユ壘绗竴涓枃浠跺悕
      for (let i = 30; i < Math.min(uint8Array.length, 100); i++) {
        if (uint8Array[i] === 0x00 && uint8Array[i+1] !== 0x00) {
          const fileNameBytes = uint8Array.slice(i + 1, i + 50);
          const fileName = bytesToString(fileNameBytes).split('\x00')[0];
          if (fileName.includes('META-INF/container.xml')) return DocumentFormat.EPUB;
          if (fileName.includes('word/document.xml')) return DocumentFormat.DOCX;
          if (fileName.includes('content.xml')) return DocumentFormat.ODT;
          if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.png')) {
            return DocumentFormat.CBZ;
          }
          break;
        }
      }
    } catch (e) {
      const err = e as Error;
      console.warn('[Parser] ZIP content detection failed: ' + err.message);
    }
    return DocumentFormat.UNKNOWN;
  }

  /**
   * 鑾峰彇鏂囦欢鎵╁睍鍚?
   */
  private getFileExtension(filePath: string): string {
    const dotIndex = filePath.lastIndexOf('.');
    return dotIndex > 0 ? filePath.substring(dotIndex + 1) : '';
  }

  /**
   * 鎵╁睍鍚嶈浆鏍煎紡
   */
  private extToFormat(ext: string): DocumentFormat {
    const extMap: Record<string, DocumentFormat> = {
      'pdf': DocumentFormat.PDF,
      'epub': DocumentFormat.EPUB,
      'txt': DocumentFormat.TXT,
      'text': DocumentFormat.TXT,
      'mobi': DocumentFormat.MOBI,
      'docx': DocumentFormat.DOCX,
      'doc': DocumentFormat.DOC,
      'rtf': DocumentFormat.RTF,
      'html': DocumentFormat.HTML,
      'htm': DocumentFormat.HTML,
      'azw': DocumentFormat.AZW,
      'azw3': DocumentFormat.AZW3,
      'djvu': DocumentFormat.DJVU,
      'djv': DocumentFormat.DJVU,
      'chm': DocumentFormat.CHM,
      'fb2': DocumentFormat.FB2,
      'odt': DocumentFormat.ODT,
      'cbr': DocumentFormat.CBR,
      'cbz': DocumentFormat.CBZ
    };

    return extMap[ext] || DocumentFormat.UNKNOWN;
  }

  /**
   * 瑙ｆ瀽鏂囨。锛堜富鍏ュ彛 - 澧炲己閿欒澶勭悊鍜岄檷绾х瓥鐣ワ級
   */
  async parseDocument(
    filePath: string,
    config: Partial<ParserConfig> = {}
  ): Promise<ParseResult> {
    const finalConfig: ParserConfig = {
      extractContent: config.extractContent !== undefined ? config.extractContent : DEFAULT_CONFIG.extractContent,
      extractChapters: config.extractChapters !== undefined ? config.extractChapters : DEFAULT_CONFIG.extractChapters,
      extractCover: config.extractCover !== undefined ? config.extractCover : DEFAULT_CONFIG.extractCover,
      paginate: config.paginate !== undefined ? config.paginate : DEFAULT_CONFIG.paginate,
      charsPerPage: config.charsPerPage !== undefined ? config.charsPerPage : DEFAULT_CONFIG.charsPerPage
    };
    
    try {
      let format = this.detectFormat(filePath);
      console.info('[Parser] Detected format:', format);

      if (format === DocumentFormat.UNKNOWN) {
        return this.createFallbackResult(filePath, 'Unknown format');
      }

      return await this.parseWithFallback(filePath, format, finalConfig);
    } catch (error) {
      const err = error as Error;
      console.error('[Parser] Parse document failed: ' + err.message);
      return this.createFallbackResult(
        filePath,
        err.message
      );
    }
  }

  /**
   * 浠呰В鏋愬厓鏁版嵁锛堣交閲忕骇锛?
   */
  async parseMetadata(filePath: string): Promise<ParseResult> {
    const minimalConfig: ParserConfig = {
      extractContent: false,
      extractChapters: false,
      extractCover: true,
      paginate: false
    };
    return await this.parseDocument(filePath, minimalConfig);
  }

  /**
   * 甯﹂檷绾х殑瑙ｆ瀽
   */
  private async parseWithFallback(
    filePath: string,
    format: DocumentFormat,
    config: ParserConfig
  ): Promise<ParseResult> {
    try {
      return await this.parseFormat(filePath, format, config);
    } catch (primaryError) {
      const err = primaryError as Error;
      console.warn('[Parser] Primary parse failed, trying fallback: ' + err.message);

      if (format !== DocumentFormat.TXT) {
        try {
          console.info('[Parser] Falling back to TXT parsing');
          const txtBuffer = await BaseParserUtils.readFileBuffer(filePath);
          return await TextFormatParser.parseTXT(filePath, config, txtBuffer);
        } catch (txtError) {
          const txtErr = txtError as Error;
          console.warn('[Parser] Fallback TXT parsing also failed: ' + txtErr.message);
        }
      }

      return this.createFallbackResult(
        filePath,
        primaryError instanceof Error ? primaryError.message : 'Parse failed'
      );
    }
  }

  /**
   * 鍏蜂綋鏍煎紡瑙ｆ瀽璺敱
   */
  private async parseFormat(
    filePath: string,
    format: DocumentFormat,
    config: ParserConfig
  ): Promise<ParseResult> {
    switch (format) {
      // ZIP-based formats
      case DocumentFormat.EPUB: {
        const epubZip = await BaseParserUtils.parseZipFile(filePath);
        if (epubZip.entries.length === 0) {
          throw new Error('Failed to parse ZIP structure');
        }
        return ZipFormatParser.parseEPUB(filePath, config, epubZip);
      }

      case DocumentFormat.DOCX: {
        const docxZip = await BaseParserUtils.parseZipFile(filePath);
        if (docxZip.entries.length === 0) {
          throw new Error('Failed to parse ZIP structure');
        }
        return ZipFormatParser.parseDOCX(filePath, config, docxZip);
      }

      case DocumentFormat.ODT: {
        const odtZip = await BaseParserUtils.parseZipFile(filePath);
        if (odtZip.entries.length === 0) {
          throw new Error('Failed to parse ZIP structure');
        }
        return ZipFormatParser.parseODT(filePath, config, odtZip);
      }

      case DocumentFormat.CBZ: {
        const cbzZip = await BaseParserUtils.parseZipFile(filePath);
        if (cbzZip.entries.length === 0) {
          throw new Error('Failed to parse ZIP structure');
        }
        return ZipFormatParser.parseCBZ(filePath, config, cbzZip);
      }

      // Text-based formats
      case DocumentFormat.TXT: {
        const txtBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return TextFormatParser.parseTXT(filePath, config, txtBuffer);
      }

      case DocumentFormat.RTF: {
        const rtfBuffer = await BaseParserUtils.readFileBuffer(filePath);
        // 鍏堝皾璇曞寮?RTF 瑙ｆ瀽
        try {
          return await TextFormatParser.parseRTF(filePath, config, rtfBuffer);
        } catch (rtfError) {
          const rtfErr = rtfError as Error;
          console.warn('[Parser] RTF parse failed, falling back to TXT: ' + rtfErr.message);
          return TextFormatParser.parseTXT(filePath, config, rtfBuffer);
        }
      }

      case DocumentFormat.HTML: {
        const htmlBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return TextFormatParser.parseHTML(filePath, config, htmlBuffer);
      }

      // XML-based formats
      case DocumentFormat.FB2: {
        const fb2Buffer = await BaseParserUtils.readFileBuffer(filePath);
        return XmlFormatParser.parseFB2(filePath, config, fb2Buffer);
      }

      case DocumentFormat.MOBI: {
        const mobiBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return XmlFormatParser.parseMOBI(filePath, config, mobiBuffer);
      }

      case DocumentFormat.AZW:
      case DocumentFormat.AZW3: {
        const azwBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return HuaweiKitParser.parseAZWEnhanced(filePath, config, azwBuffer, format);
      }

      // Other formats
      case DocumentFormat.PDF: {
        const pdfBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return OtherFormatParser.parsePDF(filePath, config, pdfBuffer);
      }

      case DocumentFormat.DOC: {
        const docBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return OtherFormatParser.parseDOC(filePath, config, docBuffer);
      }

      case DocumentFormat.DJVU: {
        // 浣跨敤涓撻棬鐨?DJVU 瑙ｆ瀽鍣?
        if (DjvuParser.isValidDjvuFile(filePath)) {
          return await DjvuParser.parse(filePath, config);
        } else {
          // 闄嶇骇澶勭悊
          const djvuBuffer = await BaseParserUtils.readFileBuffer(filePath);
          return OtherFormatParser.parseDJVU(filePath, config, djvuBuffer);
        }
      }

      case DocumentFormat.CHM: {
        // 浣跨敤涓撻棬鐨?CHM 瑙ｆ瀽鍣?
        if (ChmParser.isValidChmFile(filePath)) {
          return await ChmParser.parse(filePath, config);
        } else {
          // 闄嶇骇澶勭悊
          const chmBuffer = await BaseParserUtils.readFileBuffer(filePath);
          return OtherFormatParser.parseCHM(filePath, config, chmBuffer);
        }
      }

      case DocumentFormat.CBR: {
        const cbrBuffer = await BaseParserUtils.readFileBuffer(filePath);
        return OtherFormatParser.parseCBR(filePath, config, cbrBuffer);
      }

      default:
        throw new Error(`Unsupported format: ${format}`);
    }
  }

  /**
   * 鍒涘缓鏈€灏忓寲鍥為€€缁撴灉
   */
  private createFallbackResult(filePath: string, error: string): ParseResult {
    return {
      success: false,
      metadata: {
        title: BaseParserUtils.extractFileName(filePath),
        author: 'Unknown Author',
        language: 'zh-CN',
        pageCount: 0,
        wordCount: 0,
        format: DocumentFormat.UNKNOWN,
        fileSize: 0
      },
      content: '',
      chapters: [],
      pages: [],
      error: error,
      warnings: ['Parse failed, returning minimal metadata']
    };
  }
}

/**
 * 将 Uint8Array 转换为字符串（替代 String.fromCharCode.apply）
 */
function bytesToString(uint8Array: Uint8Array, start: number = 0, length?: number): string {
  const end = length !== undefined ? Math.min(start + length, uint8Array.length) : uint8Array.length;
  const chars: string[] = [];
  for (let i = start; i < end; i++) {
    chars.push(String.fromCharCode(uint8Array[i]));
  }
  return chars.join('');
}

// 瀵煎嚭鍗曚緥
export const enhancedParser = EnhancedDocumentParser.getInstance();
export const enhancedDocumentParser = enhancedParser;
export default enhancedParser;
