export enum DocumentFormat {
  PDF = 'pdf',
  EPUB = 'epub',
  TXT = 'txt',
  MOBI = 'mobi',
  DOCX = 'docx',
  DOC = 'doc',
  RTF = 'rtf',
  HTML = 'html',
  AZW = 'azw',
  AZW3 = 'azw3',
  DJVU = 'djvu',
  CHM = 'chm',
  FB2 = 'fb2',
  ODT = 'odt',
  CBR = 'cbr',
  CBZ = 'cbz',
  UNKNOWN = 'unknown'
}

export interface ChapterInfo {
  index: number;
  title: string;
  content: string;
  offset: number;
}

export interface BookMetadata {
  title: string;
  author: string;
  language: string;
  pageCount: number;
  wordCount: number;
  format: DocumentFormat;
  fileSize: number;
  publisher?: string;
  description?: string;
  coverData?: string;
  genre?: string;
  keywords?: string;
  createdDate?: number;
  modifiedDate?: number;
}

export interface ParseResult {
  success: boolean;
  metadata?: Partial<BookMetadata>;
  content?: string;
  chapters?: ChapterInfo[];
  pages?: string[];
  warnings?: string[];
  error?: string;
}

export interface ParserConfig {
  extractContent: boolean;
  extractChapters: boolean;
  extractCover: boolean;
  paginate: boolean;
  charsPerPage?: number;
}