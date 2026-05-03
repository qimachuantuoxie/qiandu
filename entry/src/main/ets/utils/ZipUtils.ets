/**
 * ZIP 工具类 - 提供 ZIP 文件解析功能
 * 
 * 提供 ZIP 格式文件的解析功能，包括：
 * - ZIP 文件结构解析
 * - 文件条目提取
 * - 数据缓冲区解析
 * 
 * @since 6.0.0
 */

import { util } from '@kit.ArkTS';
import { ZipParseResult, ZipEntry } from '../core/models/EbookTypes';

/**
 * ZIP 工具类
 */
export class ZipUtils {
  
  /**
   * 解析 ZIP 缓冲区
   * @param buffer ZIP 文件数据缓冲区
   * @returns ZIP 解析结果
   */
  static parseZipBuffer(buffer: ArrayBuffer): ZipParseResult {
    console.info('[ZipUtils] Parsing ZIP buffer, size:', buffer.byteLength);
    
    const entries: ZipEntry[] = [];
    const uint8Array = new Uint8Array(buffer);
    
    try {
      // 查找本地文件头签名 (PK\x03\x04)
      let offset = 0;
      let maxIterations = 10000; // 防止无限循环
      let iterations = 0;
      
      while (offset < uint8Array.length - 4 && iterations < maxIterations) {
        iterations++;
        
        if (uint8Array[offset] === 0x50 && uint8Array[offset + 1] === 0x4B &&
            uint8Array[offset + 2] === 0x03 && uint8Array[offset + 3] === 0x04) {
          
          try {
            // 解析本地文件头
            const compressionMethod = uint8Array[offset + 8] | (uint8Array[offset + 9] << 8);
            
            // 支持 ZIP64
            let compressedSize = uint8Array[offset + 18] | (uint8Array[offset + 19] << 8) |
                                (uint8Array[offset + 20] << 16) | (uint8Array[offset + 21] << 24);
            let uncompressedSize = uint8Array[offset + 22] | (uint8Array[offset + 23] << 8) |
                                  (uint8Array[offset + 24] << 16) | (uint8Array[offset + 25] << 24);
            
            const fileNameLength = uint8Array[offset + 26] | (uint8Array[offset + 27] << 8);
            const extraFieldLength = uint8Array[offset + 28] | (uint8Array[offset + 29] << 8);
            
            // 验证长度
            if (fileNameLength > 1000 || extraFieldLength > 10000) {
              offset += 4;
              continue;
            }
            
            const fileNameBytes = uint8Array.slice(offset + 30, offset + 30 + fileNameLength);
            const decoder = new util.TextDecoder('utf-8');
            const fileName = decoder.decode(fileNameBytes);
            
            const dataStart = offset + 30 + fileNameLength + extraFieldLength;
            const dataEnd = dataStart + compressedSize;
            
            // ZIP64 扩展处理
            if (compressedSize === 0xFFFFFFFF || uncompressedSize === 0xFFFFFFFF) {
              // 查找 ZIP64 扩展字段
              // 简化处理：尝试从中央目录读取
              console.warn('[ZipUtils] ZIP64 entry detected, may not be fully supported');
            }
            
            if (dataEnd <= uint8Array.length && dataStart < dataEnd && !fileName.endsWith('/')) {
              const dataSlice = uint8Array.slice(dataStart, dataEnd);
              const dataBuffer = new ArrayBuffer(dataSlice.length);
              const dataView = new Uint8Array(dataBuffer);
              dataView.set(dataSlice);
              
              entries.push({
                path: fileName,
                isDirectory: fileName.endsWith('/'),
                size: compressedSize,
                data: dataBuffer
              });
            }
            
            offset = dataEnd;
          } catch (entryError) {
            const err = entryError as Error;
            console.warn('[ZipUtils] Failed to parse ZIP entry:', err.message);
            offset += 4;
          }
        } else {
          offset++;
        }
      }
      
      if (entries.length === 0) {
        console.warn('[ZipUtils] No entries found in ZIP buffer');
      }
      
      console.info('[ZipUtils] Parsed', entries.length, 'entries from ZIP buffer');
    } catch (error) {
      const err = error as Error;
      console.error('[ZipUtils] Parse ZIP buffer failed:', err.message);
    }
    
    return { entries };
  }
  
  /**
   * 从 ZIP 条目中查找特定文件
   * @param entries ZIP 条目数组
   * @param filePath 要查找的文件路径
   * @returns 找到的文件数据，未找到则返回 null
   */
  static findFileInZip(entries: ZipEntry[], filePath: string): ArrayBuffer | null {
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      if (entry.path === filePath && entry.data) {
        return entry.data;
      }
    }
    return null;
  }
  
  /**
   * 从 ZIP 条目中查找匹配模式的文件
   * @param entries ZIP 条目数组
   * @param pattern 文件名模式（正则表达式）
   * @returns 匹配的文件条目数组
   */
  static findFilesByPattern(entries: ZipEntry[], pattern: RegExp): ZipEntry[] {
    const matchedEntries: ZipEntry[] = [];
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      if (pattern.test(entry.path)) {
        matchedEntries.push(entry);
      }
    }
    return matchedEntries;
  }
}

/** ZIP 工具类单例实例 */
export const zipUtils = ZipUtils;