/**
 * 图片信息
 */
export interface ImageInfo {
  width: number;
  height: number;
  size: number;
  format?: string;
}

/**
 * 图片元数据
 */
export interface ImageMetadata {
  title?: string;
  author?: string;
  description?: string;
  copyright?: string;
  [key: string]: string | undefined;
}

/**
 * 缩放选项
 */
export interface ResizeOptions {
  width: number;
  height: number;
  keepAspectRatio?: boolean;
}

/**
 * 旋转选项
 */
export interface RotateOptions {
  degrees: 90 | 180 | 270;
}

/**
 * 裁剪选项
 */
export interface CropOptions {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * 编码选项
 */
export interface EncodeOptions {
  format: 'jpeg' | 'png' | 'bmp';
  quality?: number; // 0-100
}

/**
 * ImageKit Native Module
 */
export declare function decodeImage(filePath: string): Promise<ImageInfo>;
export declare function decodeImageInfo(filePath: string): Promise<ImageInfo>;
export declare function encodeImage(inputPath: string, outputPath: string, options: EncodeOptions): Promise<boolean>;
export declare function resizeImage(inputPath: string, outputPath: string, options: ResizeOptions): Promise<boolean>;
export declare function rotateImage(inputPath: string, outputPath: string, options: RotateOptions): Promise<boolean>;
export declare function cropImage(inputPath: string, outputPath: string, options: CropOptions): Promise<boolean>;
export declare function getImageMetadata(filePath: string): Promise<ImageMetadata>;
export declare function setImageMetadata(filePath: string, metadata: ImageMetadata): Promise<boolean>;

export default {
  decodeImage,
  decodeImageInfo,
  encodeImage,
  resizeImage,
  rotateImage,
  cropImage,
  getImageMetadata,
  setImageMetadata
};
