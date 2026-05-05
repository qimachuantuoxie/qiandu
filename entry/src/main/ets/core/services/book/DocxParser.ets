/**
 * DOCX 解析服务 - 使用 mammoth.js 转换 DOCX 为 HTML
 * 
 * mammoth.js 是一个纯 JavaScript 库，可以将 DOCX 文件转换为 HTML
 * 支持文本、表格、列表、图片等元素
 * 
 * GitHub: https://github.com/mwilliamson/mammoth.js
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { MammothWrapper } from './MammothWrapper';
import { common } from '@kit.AbilityKit';

const LOG_TAG = 'DocxParser';
const LOG_DOMAIN = 0x0040;

/**
 * DOCX 转换选项
 */
export interface DocxConvertOptions {
  /**
   * 是否保留样式
   */
  preserveStyles?: boolean;
  
  /**
   * 是否提取图片
   */
  extractImages?: boolean;
  
  /**
   * 自定义样式映射
   */
  styleMap?: string;
}

/**
 * DOCX 转换结果
 */
export interface DocxConvertResult {
  success: boolean;
  html?: string;
  error?: string;
  warnings?: string[];
}

/**
 * DOCX 解析器
 */
export class DocxParser {
  private mammothWrapper: MammothWrapper | null = null;
  
  /**
   * 初始化 DOCX 解析器
   * @param context 应用上下文
   */
  async init(context: common.Context): Promise<void> {
    if (!this.mammothWrapper) {
      this.mammothWrapper = new MammothWrapper();
      await this.mammothWrapper.init(context);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'DocxParser initialized with MammothWrapper');
    }
  }
  
  /**
   * 将 DOCX 文件转换为 HTML
   * @param docxPath DOCX 文件路径
   * @param options 转换选项
   */
  async convertToHtml(docxPath: string, options?: DocxConvertOptions): Promise<DocxConvertResult> {
    try {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting DOCX to HTML: %{public}s', docxPath);
      
      // 读取 DOCX 文件
      const fileData = await fileIo.read(docxPath);
      
      if (!fileData || fileData.byteLength === 0) {
        return {
          success: false,
          error: 'DOCX 文件为空或读取失败'
        };
      }
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'DOCX file size: %{public}d bytes', fileData.byteLength);
      
      // 使用 mammoth.js 转换
      const result = await this.mammothConvert(fileData, options);
      
      if (result.success && result.html) {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'DOCX converted successfully, HTML length: %{public}d', 
          result.html.length);
      }
      
      return result;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to convert DOCX: %{public}s', 
        (error as Error).message);
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }
  
  /**
   * 将 DOCX 直接转换为 EPUB
   * @param docxPath DOCX 文件路径
   * @param outputPath EPUB 输出路径
   * @param title 书籍标题
   * @param author 作者
   */
  async convertToEpub(
    docxPath: string,
    outputPath: string,
    title?: string,
    author?: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // 1. 先转换为 HTML
      const htmlResult = await this.convertToHtml(docxPath);
      
      if (!htmlResult.success || !htmlResult.html) {
        return {
          success: false,
          error: htmlResult.error || 'HTML 转换失败'
        };
      }
      
      // 2. 将 HTML 包装为 EPUB 格式
      const epubContent = this.wrapAsEpub(htmlResult.html, title || 'Untitled', author || 'Unknown');
      
      // 3. 保存 EPUB 文件
      await fileIo.writeText(outputPath, epubContent);
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'EPUB saved to: %{public}s', outputPath);
      
      return {
        success: true
      };
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to convert to EPUB: %{public}s', 
        (error as Error).message);
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }
  
  /**
   * 使用 mammoth.js 转换 DOCX
   * @param fileData DOCX 文件数据
   * @param options 转换选项
   */
  private async mammothConvert(
    fileData: ArrayBuffer,
    options?: DocxConvertOptions
  ): Promise<DocxConvertResult> {
    try {
      if (!this.mammothWrapper) {
        return {
          success: false,
          error: 'MammothWrapper not initialized. Call init() first.'
        };
      }
      
      // 使用 MammothWrapper 进行转换
      const html = await this.mammothWrapper.convertDocxToHtml(fileData);
      
      return {
        success: true,
        html: html,
        warnings: []
      };
    } catch (error) {
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }
  

  
  /**
   * 将 HTML 包装为简单的 EPUB 格式
   */
  private wrapAsEpub(htmlContent: string, title: string, author: string): string {
    // 这是一个简化的 EPUB 生成
    // 完整的 EPUB 需要正确的目录结构、OPF、NCX 等
    const epubTemplate = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${this.escapeXml(title)}</title>
  <meta name="author" content="${this.escapeXml(author)}"/>
  <style>
    body { font-family: sans-serif; line-height: 1.6; padding: 20px; }
    h1, h2, h3 { margin-top: 1.5em; margin-bottom: 0.5em; }
    p { margin: 0.5em 0; }
  </style>
</head>
<body>
  <h1>${this.escapeXml(title)}</h1>
  ${htmlContent}
</body>
</html>`;
    
    return epubTemplate;
  }
  
  /**
   * XML 转义
   */
  private escapeXml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}

// 导出单例
export const docxParser = new DocxParser();
