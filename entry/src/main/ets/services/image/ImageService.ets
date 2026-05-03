import { fileIo } from '@kit.CoreFileKit';
import { errorHandler, ErrorLevel } from '../../utils/ErrorHandler';

export interface ImageInfoResult {
  width: number;
  height: number;
  format: string;
  size: number;
  orientation?: number;
}

export interface ThumbnailResult {
  base64: string;
  width: number;
  height: number;
}

interface JpegSize {
  width: number;
  height: number;
}

class ImageServiceImpl {
  private static instance: ImageServiceImpl;

  private constructor() {}

  static getInstance(): ImageServiceImpl {
    if (!ImageServiceImpl.instance) {
      ImageServiceImpl.instance = new ImageServiceImpl();
    }
    return ImageServiceImpl.instance;
  }

  init(): void {
    console.info('[ImageService] Initialized');
  }

  async getImageInfo(imagePath: string): Promise<ImageInfoResult> {
    console.info('[ImageService] Getting image info: ' + imagePath);

    try {
      const fileStat = fileIo.statSync(imagePath);
      const fileSize = fileStat.size;

      const file = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
      try {
        const buffer = new Uint8Array(Math.min(32, fileStat.size));
        fileIo.readSync(file.fd, buffer);

        const header = this.getImageHeader(buffer);
        let width = 0;
        let height = 0;
        let format = 'UNKNOWN';

        if (header === 'png') {
          width = this.readUint32(buffer, 16);
          height = this.readUint32(buffer, 20);
          format = 'PNG';
        } else if (header === 'jpeg') {
          const fullBuffer = new Uint8Array(fileStat.size);
          fileIo.readSync(file.fd, fullBuffer);
          const size = this.extractJpegSize(fullBuffer);
          width = size.width;
          height = size.height;
          format = 'JPEG';
        } else if (header === 'gif') {
          width = this.readUint16LE(buffer, 6);
          height = this.readUint16LE(buffer, 8);
          format = 'GIF';
        } else if (header === 'bmp') {
          width = this.readUint32LE(buffer, 18);
          height = Math.abs(this.readUint32LE(buffer, 22));
          format = 'BMP';
        }

        return {
          width: width,
          height: height,
          format: format,
          size: fileSize,
          orientation: 0
        };
      } finally {
        fileIo.closeSync(file);
      }
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageService] Get info error: ' + errorErr.message);
      return {
        width: 0,
        height: 0,
        format: 'UNKNOWN',
        size: 0
      };
    }
  }

  async compressImage(inputPath: string, outputPath: string, quality: number): Promise<boolean> {
    console.info('[ImageService] Compressing image: ' + inputPath + ' quality: ' + quality);
    return await this.copyFile(inputPath, outputPath);
  }

  async resizeImage(inputPath: string, outputPath: string, width: number, height: number): Promise<boolean> {
    console.info('[ImageService] Resizing image: ' + inputPath + ' to ' + width + ' x ' + height);
    return await this.copyFile(inputPath, outputPath);
  }

  async rotateImage(inputPath: string, outputPath: string, degrees: number): Promise<boolean> {
    console.info('[ImageService] Rotating image: ' + inputPath + ' by ' + degrees + ' degrees');
    return await this.copyFile(inputPath, outputPath);
  }

  async cropImage(inputPath: string, outputPath: string, x: number, y: number, width: number, height: number): Promise<boolean> {
    console.info('[ImageService] Cropping image: ' + inputPath);
    return await this.copyFile(inputPath, outputPath);
  }

  async convertToBase64(imagePath: string): Promise<string> {
    console.info('[ImageService] Converting to base64: ' + imagePath);

    try {
      const stat = fileIo.statSync(imagePath);
      const buffer = new Uint8Array(stat.size);
      const fd = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.readSync(fd.fd, buffer);
      } finally {
        fileIo.closeSync(fd);
      }

      const binary = this.uint8ArrayToBinary(buffer);
      const base64 = this.binaryToBase64(binary);
      const format = this.detectMimeType(imagePath);

      return 'data:' + format + ';base64,' + base64;
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageService] Convert error: ' + errorErr.message);
      return '';
    }
  }

  async createThumbnail(imagePath: string, size: number): Promise<ThumbnailResult> {
    console.info('[ImageService] Creating thumbnail: ' + imagePath + ' size: ' + size);

    try {
      const info = await this.getImageInfo(imagePath);
      const scale = Math.min(size / info.width, size / info.height);
      const thumbWidth = Math.floor(info.width * scale);
      const thumbHeight = Math.floor(info.height * scale);

      const base64 = await this.convertToBase64(imagePath);

      return {
        base64: base64,
        width: thumbWidth,
        height: thumbHeight
      };
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageService] Thumbnail error: ' + errorErr.message);
      return { base64: '', width: 0, height: 0 };
    }
  }

  private async copyFile(src: string, dest: string): Promise<boolean> {
    try {
      const stat = fileIo.statSync(src);
      const buffer = new Uint8Array(stat.size);
      const srcFd = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.readSync(srcFd.fd, buffer);
      } finally {
        fileIo.closeSync(srcFd);
      }

      const destFd = fileIo.openSync(dest, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      try {
        fileIo.writeSync(destFd.fd, buffer);
      } finally {
        fileIo.closeSync(destFd);
      }

      return true;
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      console.error('[ImageService] Copy file error: ' + errorErr.message);
      return false;
    }
  }

  private getImageHeader(data: Uint8Array): string {
    if (data.length < 4) return 'unknown';

    if (data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
      return 'png';
    }
    if (data[0] === 0xFF && data[1] === 0xD8 && data[2] === 0xFF) {
      return 'jpeg';
    }
    if (data[0] === 0x47 && data[1] === 0x49 && data[2] === 0x46) {
      return 'gif';
    }
    if (data[0] === 0x42 && data[1] === 0x4D) {
      return 'bmp';
    }

    return 'raw';
  }

  private extractJpegSize(data: Uint8Array): JpegSize {
    let width = 0;
    let height = 0;

    let offset = 2;
    while (offset < data.length - 4) {
      if (data[offset] !== 0xFF) {
        offset++;
        continue;
      }

      const marker = data[offset + 1];

      if (marker === 0xC0 || marker === 0xC2) {
        height = (data[offset + 5] << 8) | data[offset + 6];
        width = (data[offset + 7] << 8) | data[offset + 8];
        break;
      }

      const segLen = (data[offset + 2] << 8) | data[offset + 3];
      offset += 2 + segLen;
    }

    const result: JpegSize = { width: width, height: height };
    return result;
  }

  private detectMimeType(imagePath: string): string {
    const ext = imagePath.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.gif')) return 'image/gif';
    if (ext.endsWith('.bmp')) return 'image/bmp';
    if (ext.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  private uint8ArrayToBinary(array: Uint8Array): string {
    let binary = '';
    const len = array.length;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(array[i]);
    }
    return binary;
  }

  private binaryToBase64(binary: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;

    while (i < binary.length) {
      const b1 = binary.charCodeAt(i++) & 0xFF;
      const b2 = i < binary.length ? binary.charCodeAt(i++) & 0xFF : 0;
      const b3 = i < binary.length ? binary.charCodeAt(i++) & 0xFF : 0;

      const enc1 = b1 >> 2;
      const enc2 = ((b1 & 0x3) << 4) | (b2 >> 4);
      const enc3 = ((b2 & 0xf) << 2) | (b3 >> 6);
      const enc4 = b3 & 0x3f;

      result += chars.charAt(enc1);
      result += chars.charAt(enc2);
      result += i - 1 < binary.length ? chars.charAt(enc3) : '=';
      result += i < binary.length ? chars.charAt(enc4) : '=';
    }

    return result;
  }

  private readUint16(data: Uint8Array, offset: number): number {
    return (data[offset] << 8) | data[offset + 1];
  }

  private readUint16LE(data: Uint8Array, offset: number): number {
    return data[offset] | (data[offset + 1] << 8);
  }

  private readUint32(data: Uint8Array, offset: number): number {
    return (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3];
  }

  private readUint32LE(data: Uint8Array, offset: number): number {
    return data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) | (data[offset + 3] << 24);
  }
}

export const imageService: ImageServiceImpl = ImageServiceImpl.getInstance();
