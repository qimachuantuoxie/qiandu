/**
 * Native 模块服务 - PDF 处理、压缩包处理
 * 封装跨平台 Native API 调用，提供 HarmonyOS 原生能力
 *
 * 优先使用 C++ NAPI 原生模块（libentry.so），
 * 不可用时降级为 ArkTS 实现。
 */
import { fileIo } from '@kit.CoreFileKit';

// 原生 C++ NAPI 模块接口（libentry.so）
// 由 CMakeLists.txt 编译，注册了 getPdfInfo/getZipFileCount/getDjvuInfo/getChmInfo
// 当前通过 ArkTS 实现，原生模块可用于性能优化

interface ZipEntry {
  path: string;
  uri: string;
}

export class PdfOpenResult {
  success: boolean = false;
  pageCount: number = 0;
  errorMessage: string = '';
}

export class PdfMetadata {
  title: string = '';
  author: string = '';
  subject: string = '';
  creator: string = '';
  producer: string = '';
  pageCount: number = 0;
}

export class PdfEngineClass {
  private currentPdfPath: string = '';
  private metadata: PdfMetadata | null = null;

  /**
   * 打开 PDF 文件
   */
  async openPdf(filePath: string): Promise<PdfOpenResult> {
    try {
      const stat = fileIo.statSync(filePath);
      if (stat.size === 0) {
        return { success: false, pageCount: 0, errorMessage: 'File is empty' };
      }

      this.currentPdfPath = filePath;

      // 尝试解析 PDF 元数据
      let file: fileIo.File | undefined;
      try {
        file = fileIo.openSync(filePath, 0o0);
        const headerBuffer = new ArrayBuffer(1024);
        fileIo.readSync(file.fd, headerBuffer);

        const headerStr = this.decodePdfHeader(headerBuffer);
        this.metadata = this.parsePdfMetadata(headerStr);
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (e) {
            const message = e instanceof Error ? e.message : String(e);
            console.warn('[NativeModules] Close file failed:', message);
          }
        }
      }

      // 扫描文件查找 /Type /Page 标记来估算页数
      const fullBuffer = new ArrayBuffer(Math.min(stat.size, 10 * 1024 * 1024));
      let file2: fileIo.File | undefined;
      try {
        file2 = fileIo.openSync(filePath, 0o0);
        fileIo.readSync(file2.fd, fullBuffer);
      } finally {
        if (file2) {
          try {
            fileIo.closeSync(file2);
          } catch (e) {
            const message = e instanceof Error ? e.message : String(e);
            console.warn('[NativeModules] Close file2 failed:', message);
          }
        }
      }

      const content = this.arrayBufferToString(fullBuffer);
      // Count /Type /Page occurrences to estimate PDF page count
      let pageCount = 1;
      const typePageStr = '/Type /Page';
      let searchFrom = 0;
      while (true) {
        const idx = content.indexOf(typePageStr, searchFrom);
        if (idx === -1) break;
        pageCount++;
        searchFrom = idx + typePageStr.length;
      }
      this.metadata!.pageCount = pageCount;

      return {
        success: true,
        pageCount: this.metadata.pageCount,
        errorMessage: ''
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[PdfEngine] Open PDF failed:', message);
      return {
        success: false,
        pageCount: 0,
        errorMessage: message
      };
    }
  }

  /**
   * 获取 PDF 元数据
   */
  async getMetadata(): Promise<string[]> {
    if (!this.metadata) {
      return [];
    }
    return [
      'Title: ' + this.metadata.title,
      'Author: ' + this.metadata.author,
      'Subject: ' + this.metadata.subject,
      'Pages: ' + this.metadata.pageCount
    ];
  }

  /**
   * 获取页面文本
   */
  async getPageText(pageIndex: number): Promise<string> {
    if (!this.currentPdfPath) {
      console.warn('[PdfEngine] No PDF opened');
      return '';
    }

    try {
      const stat = fileIo.statSync(this.currentPdfPath);
      const bufferSize = Math.min(stat.size, 10 * 1024 * 1024);
      const buffer = new ArrayBuffer(bufferSize);

      let file: fileIo.File | undefined;
      try {
        file = fileIo.openSync(this.currentPdfPath, 0o0);
        fileIo.readSync(file.fd, buffer);
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (e) {
            const message = e instanceof Error ? e.message : String(e);
            console.warn('[NativeModules] Close file failed:', message);
          }
        }
      }

      return this.extractPageText(buffer, pageIndex);
    } catch (error) {
      console.error('[PdfEngine] Get page text failed:', error);
      return '';
    }
  }

  /**
   * 渲染页面为 Base64
   */
  async renderPageToBase64(pageIndex: number, width: number, height: number): Promise<string> {
    console.warn('[PdfEngine] Render to Base64 not fully supported');
    return 'data:image/svg+xml;base64,' + this.btoa('<svg width="' + width + '" height="' + height + '"><text x="50%" y="50%" text-anchor="middle">PDF Page ' + (pageIndex + 1) + '</text></svg>');
  }

  /**
   * 关闭 PDF
   */
  async closePdf(): Promise<void> {
    this.currentPdfPath = '';
    this.metadata = null;
  }

  // ==================== 私有方法 ====================

  private decodePdfHeader(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < Math.min(bytes.length, 1024); i++) {
      if (bytes[i] >= 32 && bytes[i] <= 126) {
        result += String.fromCharCode(bytes[i]);
      }
    }
    return result;
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < bytes.length; i++) {
      if (bytes[i] >= 32 && bytes[i] <= 126) {
        result += String.fromCharCode(bytes[i]);
      }
    }
    return result;
  }

  private parsePdfMetadata(headerStr: string): PdfMetadata {
    const metadata = new PdfMetadata();

    const titleMatch = headerStr.match(new RegExp('/Title\\s*\\(([^)]*)\\)'));
    if (titleMatch) metadata.title = titleMatch[1].trim();

    const authorMatch = headerStr.match(new RegExp('/Author\\s*\\(([^)]*)\\)'));
    if (authorMatch) metadata.author = authorMatch[1].trim();

    const subjectMatch = headerStr.match(new RegExp('/Subject\\s*\\(([^)]*)\\)'));
    if (subjectMatch) metadata.subject = subjectMatch[1].trim();

    const creatorMatch = headerStr.match(new RegExp('/Creator\\s*\\(([^)]*)\\)'));
    if (creatorMatch) metadata.creator = creatorMatch[1].trim();

    return metadata;
  }

  private extractPageText(buffer: ArrayBuffer, pageIndex: number): string {
    const content = this.arrayBufferToString(buffer);
    const textParts: string[] = [];

    // 提取 BT...ET 块中的文本
    const btEtRegex = /BT\\s+([\\s\\S]*?)\\s+ET/g;
    let match: RegExpExecArray | null;

    while ((match = btEtRegex.exec(content)) !== null) {
      const blockContent = match[1];

      // 提取文本字符串 (literal strings)
      const literalRegex = /\(([^)]*)\)/g;
      let literalMatch: RegExpExecArray | null;

      while ((literalMatch = literalRegex.exec(blockContent)) !== null) {
        const text = this.decodePdfString(literalMatch[1]);
        if (text.trim().length > 0) {
          textParts.push(text);
        }
      }

      // 提取十六进制字符串 <...>
      const hexRegex = /<([0-9a-fA-F\\s]*)>/g;
      let hexMatch: RegExpExecArray | null;

      while ((hexMatch = hexRegex.exec(blockContent)) !== null) {
        const hexStr = hexMatch[1].replace(/\\s/g, '');
        const text = this.decodePdfHexStream(hexStr);
        if (text.trim().length > 0) {
          textParts.push(text);
        }
      }
    }

    return this.postProcessPdfText(textParts);
  }

  private decodePdfString(str: string): string {
    return str
      .replace(/\\n/g, '\n')
      .replace(/\\r/g, '\r')
      .replace(/\\t/g, '\t')
      .replace(/\\b/g, '\b')
      .replace(/\\f/g, '\f')
      .replace(/\\([0-7]{1,3})/g, (_match: string, octal: string): string => {
        return String.fromCharCode(parseInt(octal, 8));
      })
      .replace(/\\(.)/g, '$1')
      .replace(/\r\n/g, '\n')
      .replace(/\\r/g, '\n');
  }

  private decodePdfHexStream(hexStr: string): string {
    try {
      let result = '';
      for (let i = 0; i < hexStr.length; i += 2) {
        const byte = parseInt(hexStr.substring(i, i + 2), 16);
        if (byte >= 32 && byte <= 126) {
          result += String.fromCharCode(byte);
        } else if (byte === 10 || byte === 13) {
          result += '\n';
        }
      }
      return result;
    } catch {
      return '';
    }
  }

  private postProcessPdfText(parts: string[]): string {
    if (parts.length === 0) return '';

    let text = parts.join(' ');

    // 清理空白
    text = text.replace(/\\s+/g, ' ').trim();

    // 处理标点符号后的换行
    text = text.replace(/([。！？?!?])\\s*/g, '$1\n');

    return text;
  }

  private btoa(str: string): string {
    const charArray: string[] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('');
    let result = '';
    const bytes = new Uint8Array(str.length);
    for (let i = 0; i < str.length; i++) {
      bytes[i] = str.charCodeAt(i);
    }

    const chunkSize = 3;
    for (let i = 0; i < bytes.length; i += chunkSize) {
      const b1 = bytes[i];
      const b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      result += charArray[b1 >> 2];
      result += charArray[((b1 & 3) << 4) | (b2 >> 4)];
      result += (i + 1 < bytes.length) ? charArray[((b2 & 15) << 2) | (b3 >> 6)] : '=';
      result += (i + 2 < bytes.length) ? charArray[b3 & 63] : '=';
    }

    return result;
  }
}

export class PdfInfoResult {
  title: string = '';
  author: string = '';
  pageCount: number = 0;
}

export class NativeModulesClass {
  private pdfEngine: PdfEngineClass = new PdfEngineClass();

  async initialize(): Promise<void> {
    console.info('[NativeModules] Initialized');
  }

  async getPdfInfo(path: string): Promise<PdfInfoResult> {
    const result = new PdfInfoResult();
    try {
      const engine = await this.getPDF();
      const openResult = await engine.openPdf(path);
      if (openResult.success) {
        const metadata = await engine.getMetadata();
        result.pageCount = openResult.pageCount;
        for (const item of metadata) {
          if (item.startsWith('Title:')) result.title = item.substring(6).trim();
          if (item.startsWith('Author:')) result.author = item.substring(7).trim();
        }
      }
    } catch (error) {
      console.error('[NativeModules] Get PDF info failed:', error);
    }
    return result;
  }

  async getZipFileCount(path: string): Promise<number> {
    try {
      const file = fileIo.openSync(path, 0o0);
      const buffer = new ArrayBuffer(1024);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const bytes = new Uint8Array(buffer);
      let count = 0;
      // 扫描 ZIP 文件头 PK\x03\x04
      for (let i = 0; i < bytes.length - 3; i++) {
        if (bytes[i] === 0x50 && bytes[i+1] === 0x4B &&
            bytes[i+2] === 0x03 && bytes[i+3] === 0x04) {
          count++;
        }
      }
      return count;
    } catch {
      return 0;
    }
  }

  async getDjvuInfo(path: string): Promise<PdfInfoResult> {
    const result = new PdfInfoResult();
    try {
      const stat = fileIo.statSync(path);
      if (stat.size <= 0) return result;

      const file = fileIo.openSync(path, 0o0);
      const buffer = new ArrayBuffer(Math.min(stat.size, 4096));
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const bytes = new Uint8Array(buffer);
      let header = '';
      for (let i = 0; i < bytes.length; i++) {
        if (bytes[i] >= 32 && bytes[i] <= 126) {
          header += String.fromCharCode(bytes[i]);
        }
      }

      if (header.includes('AT&T')) {
        result.title = path.split('/').pop() || path;
      }
      result.pageCount = 1;
    } catch {
      console.warn('[NativeModules] getDjvuInfo failed');
    }
    return result;
  }

  async getChmInfo(path: string): Promise<PdfInfoResult> {
    const result = new PdfInfoResult();
    try {
      const stat = fileIo.statSync(path);
      if (stat.size <= 0) return result;

      const file = fileIo.openSync(path, 0o0);
      const buffer = new ArrayBuffer(Math.min(stat.size, 4096));
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      const bytes = new Uint8Array(buffer);
      let header = '';
      for (let i = 0; i < bytes.length; i++) {
        if (bytes[i] >= 32 && bytes[i] <= 126) {
          header += String.fromCharCode(bytes[i]);
        }
      }

      if (header.includes('ITSF')) {
        result.title = path.split('/').pop() || path;
      }
      result.pageCount = 1;
    } catch {
      console.warn('[NativeModules] getChmInfo failed');
    }
    return result;
  }

  async extractZip(filePath: string): Promise<ZipEntry[]> {
    console.info('[NativeModules] extractZip not implemented, returning empty array');
    return [];
  }

  async getPDF(): Promise<PdfEngineClass> {
    return this.pdfEngine;
  }
}

export const nativeModules: NativeModulesClass = new NativeModulesClass();
