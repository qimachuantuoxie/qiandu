import { logger } from '../../../utils/Logger';
/**
 * RAR 鏍煎紡瑙ｆ瀽鍣?- 鐢ㄤ簬 CBR 婕�敾鏂囦欢
 * RAR Format Parser - For CBR Comic Files
 *
 * 鏀�寔 RAR4 鍜?RAR5 鏍煎紡鐨勫熀鏈�В鏋?
 * 澧炲己鐗堬細鏀�寔鍥剧墖瑙ｇ爜鍜屽厓鏁版嵁鎻愬彇
 */

import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

/**
 * RAR 鏉＄洰
 */
export interface RarEntry {
  fileName: string;
  fileSize: number;
  fileTime: number;
  data: Uint8Array;
  isDirectory: boolean;
  imageInfo?: ImageInfo;  // 鍥剧墖鍏冩暟鎹?
}

/**
 * 鍥剧墖淇℃伅
 */
export interface ImageInfo {
  width: number;
  height: number;
  format: string;
}

/**
 * RAR 瑙ｆ瀽缁撴灉
 */
export interface RarParseResult {
  entries: RarEntry[];
  success: boolean;
  error?: string;
  totalImageCount: number;
  totalSize: number;
}

/**
 * 鏀�寔鐨勫浘鐗囨牸寮忔墿灞曞悕
 */
const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'tif'];

/**
 * RAR 瑙ｆ瀽鍣?
 */
export class RarParser {

  /**
   * 瑙ｆ瀽 RAR 鏂囦欢锛堝�寮虹増锛?
   */
  async parseRarFile(filePath: string): Promise<RarParseResult> {
    logger.info('[RarParser] Parsing RAR file:', filePath);

    let file: fileIo.File | undefined;
    try {
      const stat = fileIo.statSync(filePath);
      file = fileIo.openSync(filePath, 0o0);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);

      const uint8Array = new Uint8Array(buffer);

      // 楠岃瘉 RAR 鏂囦欢澶?
      if (!this.isValidRarHeader(uint8Array)) {
        return {
          entries: [],
          success: false,
          error: 'Invalid RAR file header',
          totalImageCount: 0,
          totalSize: 0
        };
      }

      // 鎻愬彇鏂囦欢鏉＄洰
      const entries = this.extractRarEntries(uint8Array);

      // 瑙ｇ爜鍥剧墖鍏冩暟鎹?
      const imageEntries: RarEntry[] = [];
      for (let i = 0; i < entries.length; i++) {
        if (this.isImageFile(entries[i].fileName)) {
          imageEntries.push(entries[i]);
        }
      }
      await this.decodeImageMetadata(imageEntries, filePath);

      return {
        entries: entries,
        success: true,
        totalImageCount: imageEntries.length,
        totalSize: stat.size
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      logger.error('[RarParser] Parse RAR failed:', err.message);
      return {
        entries: [],
        success: false,
        error: err.message,
        totalImageCount: 0,
        totalSize: 0
      };
    } finally {
      if (file) {
        try { fileIo.closeSync(file); } catch (error) {}
      }
    }
  }

  /**
   * 楠岃瘉 RAR 鏂囦欢澶?
   */
  private isValidRarHeader(uint8Array: Uint8Array): boolean {
    if (uint8Array.length < 7) return false;

    // RAR4: Rar!\x1a\x07
    if (uint8Array[0] === 0x52 && uint8Array[1] === 0x61 &&
        uint8Array[2] === 0x72 && uint8Array[3] === 0x21 &&
        uint8Array[4] === 0x1A && uint8Array[5] === 0x07) {
      return true;
    }

    // RAR5: Rar!\x1a\x07\x01\x00
    if (uint8Array.length >= 8 &&
        uint8Array[0] === 0x52 && uint8Array[1] === 0x61 &&
        uint8Array[2] === 0x72 && uint8Array[3] === 0x21 &&
        uint8Array[4] === 0x1A && uint8Array[5] === 0x07 &&
        uint8Array[6] === 0x01 && uint8Array[7] === 0x00) {
      return true;
    }

    return false;
  }

  /**
   * 妫€鏌ユ槸鍚︿负鍥剧墖鏂囦欢
   */
  private isImageFile(fileName: string): boolean {
    const parts = fileName.split('.');
    let ext = '';
    if (parts.length > 0) {
      ext = parts[parts.length - 1].toLowerCase();
    }
    for (let i = 0; i < IMAGE_EXTENSIONS.length; i++) {
      if (IMAGE_EXTENSIONS[i] === ext) {
        return true;
      }
    }
    return false;
  }

  /**
   * 瑙ｇ爜鍥剧墖鍏冩暟鎹?
   */
  private async decodeImageMetadata(entries: RarEntry[], rarFilePath: string): Promise<void> {
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      try {
        // 濡傛灉鏈夋暟鎹�紝灏濊瘯鑾峰彇鍥剧墖淇℃伅
        if (entry.data && entry.data.length > 0) {
          // 绠€鍖栧疄鐜帮細鏍规嵁鎵╁睍鍚嶅垽鏂?
          const parts = entry.fileName.split('.');
          let ext = '';
          if (parts.length > 0) {
            ext = parts[parts.length - 1].toLowerCase();
          }
          entry.imageInfo = {
            width: 0,  // 闇€瑕佸疄闄呰В鐮?
            height: 0,
            format: ext.toUpperCase()
          };
        }
      } catch (error) {
        const err = error as Error;
        logger.warn('[RarParser] Failed to decode image metadata for', entry.fileName, err.message);
        entry.imageInfo = {
          width: 0,
          height: 0,
          format: 'UNKNOWN'
        };
      }
    }
  }

  /**
   * 鎻愬彇 RAR 鏂囦欢鏉＄洰
   */
  private extractRarEntries(uint8Array: Uint8Array): RarEntry[] {
    const entries: RarEntry[] = [];
    let offset = 0;

    // 璺宠繃鏂囦欢澶寸�鍚?
    if (uint8Array.length >= 8 && uint8Array[6] === 0x01 && uint8Array[7] === 0x00) {
      // RAR5
      offset = this.skipRar5Header(uint8Array, 0);
    } else {
      // RAR4
      offset = this.skipRar4Header(uint8Array, 0);
    }

    // 瑙ｆ瀽鏂囦欢鍧?
    while (offset < uint8Array.length - 4) {
      const entry = this.parseRarFileBlock(uint8Array, offset);
      if (!entry) break;

      // 鍙�繚鐣欏彲鑳界殑鍥剧墖鏂囦欢
      if (this.isImageFile(entry.fileName)) {
        entries.push(entry);
      }

      offset += Math.max(entry.fileSize, 100) + this.getBlockHeaderSize(entry);
    }

    // 鎸夋枃浠跺悕鎺掑簭
    const sortedEntries = entries.slice().sort((a, b) => a.fileName.localeCompare(b.fileName));

    return sortedEntries;
  }

  /**
   * 璺宠繃 RAR4 鏂囦欢澶?
   */
  private skipRar4Header(uint8Array: Uint8Array, offset: number): number {
    // RAR4 鏂囦欢澶村ぇ绾?7 瀛楄妭 (绛惧悕) + 43 瀛楄妭 (褰掓。澶?
    return offset + 50;
  }

  /**
   * 璺宠繃 RAR5 鏂囦欢澶?
   */
  private skipRar5Header(uint8Array: Uint8Array, offset: number): number {
    // RAR5 鏂囦欢澶村ぇ绾?8 瀛楄妭 (绛惧悕) + 鍙�彉 (褰掓。澶?
    return offset + 16;
  }

  /**
   * 瑙ｆ瀽 RAR 鏂囦欢鍧?
   */
  private parseRarFileBlock(uint8Array: Uint8Array, offset: number): RarEntry | null {
    if (offset + 4 > uint8Array.length) return null;

    try {
      // 绠€鍖栧疄鐜帮細鎻愬彇鏂囦欢鍚嶅拰鏁版嵁
      // 鏌ユ壘鏂囦欢鍚嶏紙閫氬父鏄?ASCII 鏂囨湰锛?
      let fileName = '';

      for (let i = offset; i < Math.min(offset + 256, uint8Array.length); i++) {
        if (uint8Array[i] >= 0x20 && uint8Array[i] <= 0x7E) {
          fileName += String.fromCharCode(uint8Array[i]);
        } else if (fileName.length > 0) {
          break;
        }
      }

      if (fileName.length < 3) {
        fileName = 'file_' + offset + '.bin';
      }

      // 浼扮畻澶у皬
      const remainingLength = uint8Array.length - offset;
      const fileSize = Math.min(remainingLength, 1024 * 1024);

      return {
        fileName: fileName,
        fileSize: fileSize,
        fileTime: Date.now(),
        data: uint8Array.slice(offset, offset + Math.min(fileSize, 1000)),
        isDirectory: false
      };
    } catch (error) {
      return null;
    }
  }

  /**
   * 鑾峰彇鍧楀ご澶у皬
   */
  private getBlockHeaderSize(entry: RarEntry): number {
    return 32;
  }

  /**
   * 鎻愬彇鍥剧墖鏂囦欢锛堝�寮虹増锛?
   */
  async extractImages(filePath: string): Promise<RarEntry[]> {
    const result = await this.parseRarFile(filePath);

    if (!result.success) {
      logger.warn('[RarParser] Failed to parse RAR file:', result.error);
      return [];
    }

    // 杩囨护鍥剧墖鏂囦欢
    const imageEntries: RarEntry[] = [];
    for (let i = 0; i < result.entries.length; i++) {
      if (this.isImageFile(result.entries[i].fileName)) {
        imageEntries.push(result.entries[i]);
      }
    }

    logger.info('[RarParser] Extracted', imageEntries.length, 'image files');
    return imageEntries;
  }

  /**
   * 鑾峰彇婕�敾淇℃伅
   */
  async getComicInfo(filePath: string): Promise<{
    title: string;
    imageCount: number;
    totalSize: number;
    formats: string[];
  }> {
    const result = await this.parseRarFile(filePath);

    const imageEntries: RarEntry[] = [];
    for (let i = 0; i < result.entries.length; i++) {
      if (this.isImageFile(result.entries[i].fileName)) {
        imageEntries.push(result.entries[i]);
      }
    }

    const formatSet = new Set<string>();
    for (let i = 0; i < imageEntries.length; i++) {
      const e = imageEntries[i];
      let format = 'UNKNOWN';
      if (e.imageInfo) {
        format = e.imageInfo.format;
      }
      formatSet.add(format);
    }

    const formats: string[] = [];
    formatSet.forEach(f => formats.push(f));

    return {
      title: this.extractTitleFromPath(filePath),
      imageCount: imageEntries.length,
      totalSize: result.totalSize,
      formats: formats
    };
  }

  /**
   * 浠庤矾寰勬彁鍙栨爣棰?
   */
  private extractTitleFromPath(filePath: string): string {
    const parts = filePath.split('/');
    let fileName = '';
    if (parts.length > 0) {
      fileName = parts[parts.length - 1];
    }
    return fileName.replace(new RegExp('\.(cbr|rar)$', 'i'), '');
  }

  /**
   * 妫€鏌ユ槸鍚︿负鏈夋晥鐨?RAR 鏂囦欢
   */
  static isValidRarFile(filePath: string): boolean {
    let file: fileIo.File | undefined;
    try {
      file = fileIo.openSync(filePath, 0o0);
      const buffer = new ArrayBuffer(8);
      fileIo.readSync(file.fd, buffer);

      const uint8Array = new Uint8Array(buffer);
      return uint8Array.length >= 6 &&
        uint8Array[0] === 0x52 && uint8Array[1] === 0x61 &&
        uint8Array[2] === 0x72 && uint8Array[3] === 0x21 &&
        uint8Array[4] === 0x1A && uint8Array[5] === 0x07;
    } catch (error) {
      return false;
    } finally {
      if (file) {
        try { fileIo.closeSync(file); } catch (error) {}
      }
    }
  }
}

// 瀵煎嚭瀹炰緥
export const rarParser = new RarParser();
export default rarParser;

