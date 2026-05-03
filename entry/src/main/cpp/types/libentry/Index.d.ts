export interface OCRResult {
  success: boolean;
  text: string;
  confidence: number;
  width?: number;
  height?: number;
  error?: string;
  blocks?: TextBlock[];
}

export interface TextBlock {
  text: string;
  confidence: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface OCREngineStatus {
  initialized: boolean;
  engine: string;
  version: string;
  supportedLanguages: string[];
}

export interface OCREngineConfig {
  success: boolean;
  engine: string;
  version: string;
}

export interface PdfMetadata {
  title: string;
  author: string;
  subject: string;
  keywords: string;
  creator: string;
  producer: string;
  pageCount: number;
  isEncrypted: boolean;
}

export interface PdfBookmark {
  title: string;
  pageIndex: number;
  level: number;
}

export interface RenderedPage {
  width: number;
  height: number;
  data: ArrayBuffer;
}

export interface ImageInfo {
  width: number;
  height: number;
  channels: number;
  dataSize: number;
}

export interface OpenPdfResult {
  success: boolean;
  pageCount: number;
  filePath: string;
}

export interface LoadImageResult {
  success: boolean;
  width?: number;
  height?: number;
  channels?: number;
}

export interface PageSizeResult {
  width: number;
  height: number;
  dpi: number;
}

export declare namespace NativeModule {
  export function initOCREngine(tessdataPath: string, language: string): Promise<OCREngineConfig>;
  export function recognizeText(imagePath: string, needPosition?: boolean): Promise<OCRResult>;
  export function recognizeTextBatch(imagePaths: string[]): Promise<OCRResult[]>;
  export function setLanguage(language: string): Promise<boolean>;
  export function destroyOCREngine(): Promise<boolean>;
  export function getEngineStatus(): Promise<OCREngineStatus>;

  export function openPdf(pdfPath: string): Promise<OpenPdfResult>;
  export function closePdf(): Promise<boolean>;
  export function getPageCount(): Promise<number>;
  export function getMetadata(): Promise<PdfMetadata>;
  export function getPageText(pageIndex: number, needLayout?: boolean): Promise<string>;
  export function getAllText(): Promise<string>;
  export function renderPage(pageIndex: number, width: number, height: number, dpi?: number): Promise<RenderedPage>;
  export function renderPageToBase64(pageIndex: number): Promise<string>;
  export function getBookmarks(): Promise<PdfBookmark[]>;
  export function getPageSizeWithDpi(pageIndex: number, dpi: number): Promise<PageSizeResult>;

  export function loadImage(imagePath: string): Promise<LoadImageResult>;
  export function releaseImage(): Promise<boolean>;
  export function getImageInfo(): Promise<ImageInfo>;
  export function resizeImage(width: number, height: number, filter?: string): Promise<boolean>;
  export function cropImage(x: number, y: number, width: number, height: number): Promise<boolean>;
  export function rotateImage(angle: number): Promise<boolean>;
  export function grayscaleImage(): Promise<boolean>;
  export function thresholdImage(threshold?: number): Promise<boolean>;
  export function adjustBrightness(factor: number): Promise<boolean>;
  export function adjustContrast(factor: number): Promise<boolean>;
  export function denoiseImage(strength?: number): Promise<boolean>;
  export function sharpenImage(amount?: number): Promise<boolean>;
  export function saveImage(path: string, format?: string, quality?: number): Promise<boolean>;
  export function imageToBase64(format?: string, quality?: number): Promise<string>;

  export function add(a: number, b: number): number;
}
