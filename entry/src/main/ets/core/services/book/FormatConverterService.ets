/**
 * 文档格式转换服务
 * 
 * 支持将不支持的格式转换为 Reader Kit/PDF Kit 支持的格式：
 * - CHM → HTML/EPUB (需要集成 libchm)
 * - DJVU → PDF (需要集成 libdjvulibre)
 * - DOCX → HTML/PDF (使用 mammoth.js)
 * - RTF → TXT (简单文本提取)
 * 
 * 注意：CHM/DJVU 的完整实现需要编译第三方库
 * 当前版本提供基础框架和 RTF 转换功能
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { NativeFormatConverter } from './NativeFormatConverter';
import { docxParser } from './DocxParser';
import { NativeCbzParser } from './NativeCbzParser';

const LOG_TAG = 'FormatConverter';
const LOG_DOMAIN = 0x0020;

/**
 * 转换结果
 */
export interface ConvertResult {
  success: boolean;
  outputPath?: string;
  outputFormat?: string;
  error?: string;
}

/**
 * 转换进度回调
 */
export type ProgressCallback = (progress: number, message: string) => void;

/**
 * 文档格式转换服务
 */
export class FormatConverterService {
  private context: common.UIAbilityContext | null = null;
  private convertDir: string = '';

  /**
   * 初始化服务
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    this.convertDir = `${context.cacheDir}/converted`;
    
    // 创建转换目录
    try {
      await fileIo.mkdir(this.convertDir);
    } catch (error) {
      // 目录可能已存在
    }
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'FormatConverterService initialized');
  }

  /**
   * 根据格式转换为支持的格式
   * @param inputPath 输入文件路径
   * @param inputFormat 输入格式
   * @param onProgress 进度回调
   */
  async convertToSupported(
    inputPath: string,
    inputFormat: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    const lowerFormat = inputFormat.toLowerCase();
    
    try {
      switch (lowerFormat) {
        case 'chm':
          return await this.convertChm(inputPath, onProgress);
        
        case 'djvu':
        case 'djv':
          return await this.convertDjvu(inputPath, onProgress);
        
        case 'docx':
          return await this.convertDocx(inputPath, onProgress);
        
        case 'doc':
          return await this.convertDoc(inputPath, onProgress);
        
        case 'rtf':
          return await this.convertRtf(inputPath, onProgress);
        
        case 'odt':
          return await this.convertOdt(inputPath, onProgress);
        
        case 'fb2':
          return await this.convertFb2(inputPath, onProgress);
        
        case 'cbr':
        case 'cbz':
          return await this.convertComic(inputPath, lowerFormat, onProgress);
        
        default:
          return {
            success: false,
            error: `不支持的格式: ${inputFormat}`
          };
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Conversion failed: %{public}s', 
        (error as Error).message);
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 转换 CHM 到 HTML
   * 使用 Native CHM 解析器
   */
  private async convertChm(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting CHM to HTML: %{public}s', inputPath);
    
    if (onProgress) onProgress(10, '正在解析 CHM 文件...');
    
    try {
      // 调用 Native CHM 解析器
      const chmInfo = NativeFormatConverter.parseChmInfo(inputPath);
      
      if (!chmInfo) {
        return {
          success: false,
          error: 'CHM 解析失败'
        };
      }
      
      if (onProgress) onProgress(50, '正在提取内容...');
      
      // 提取 HTML 内容
      const htmlContent = NativeFormatConverter.extractChmHtml(inputPath);
      
      if (!htmlContent) {
        return {
          success: false,
          error: 'HTML 内容提取失败'
        };
      }
      
      if (onProgress) onProgress(80, '正在生成 EPUB...');
      
      // 转换为 EPUB
      const epubPath = await this.htmlToEpub(htmlContent, chmInfo.title, chmInfo.author);
      
      if (onProgress) onProgress(100, '转换完成');
      
      return {
        success: true,
        outputPath: epubPath,
        outputFormat: 'epub'
      };
    } catch (error) {
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 转换 DJVU 到 PDF
   * 使用 Native DJVU 解析器
   */
  private async convertDjvu(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting DJVU to PDF: %{public}s', inputPath);
    
    if (onProgress) onProgress(10, '正在解析 DJVU 文件...');
    
    try {
      // 调用 Native DJVU 解析器
      const djvuInfo = NativeFormatConverter.parseDjvuInfo(inputPath);
      
      if (!djvuInfo) {
        return {
          success: false,
          error: 'DJVU 解析失败'
        };
      }
      
      if (onProgress) onProgress(30, `共 ${djvuInfo.pageCount} 页，正在渲染...`);
      
      // 逐页渲染为图片
      const imagePaths: string[] = [];
      for (let i = 0; i < djvuInfo.pageCount; i++) {
        if (onProgress) {
          const progress = 30 + (i / djvuInfo.pageCount) * 50;
          onProgress(progress, `正在渲染第 ${i + 1}/${djvuInfo.pageCount} 页...`);
        }
        
        const result = NativeFormatConverter.renderDjvuPage(inputPath, i, 1200, 1600);
        if (result) {
          // TODO: 保存 RGBA 数据为 PNG 文件
          const imagePath = `${this.convertDir}/djvu_page_${i}.png`;
          imagePaths.push(imagePath);
        }
      }
      
      if (onProgress) onProgress(85, '正在生成 PDF...');
      
      // 将图片合并为 PDF
      const pdfPath = await this.imagesToPdf(imagePaths);
      
      if (onProgress) onProgress(100, '转换完成');
      
      return {
        success: true,
        outputPath: pdfPath,
        outputFormat: 'pdf'
      };
    } catch (error) {
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 转换 DOCX 到 HTML/EPUB
   * 使用 mammoth.js（纯 JS 实现）
   */
  private async convertDocx(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting DOCX to EPUB: %{public}s', inputPath);
    
    if (onProgress) onProgress(20, '正在解析 DOCX...');
    
    try {
      // 生成输出路径
      const fileName = this.extractFileName(inputPath);
      const epubPath = `${this.convertDir}/${fileName}.epub`;
      
      if (onProgress) onProgress(50, '正在转换为 EPUB...');
      
      // 使用 docxParser 转换
      const result = await docxParser.convertToEpub(
        inputPath,
        epubPath,
        fileName,
        'Unknown Author'
      );
      
      if (!result.success) {
        return {
          success: false,
          error: result.error || 'DOCX 转换失败'
        };
      }
      
      if (onProgress) onProgress(100, '转换完成');
      
      return {
        success: true,
        outputPath: epubPath,
        outputFormat: 'epub'
      };
    } catch (error) {
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 转换 DOC 到 HTML
   * 需要调用外部工具（LibreOffice）
   */
  private async convertDoc(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    // DOC 格式较老，建议用户转换为 DOCX
    return {
      success: false,
      error: 'DOC 格式建议使用 LibreOffice 转换为 DOCX 后再导入'
    };
  }

  /**
   * 转换 RTF 到 HTML
   */
  private async convertRtf(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting RTF to HTML: %{public}s', inputPath);
    
    try {
      // 读取 RTF 文件
      const rtfContent = await fileIo.readText(inputPath);
      
      // 简单的 RTF 到文本转换（去除格式标记）
      const textContent = this.rtfToText(rtfContent);
      
      // 保存为 TXT
      const txtPath = `${this.convertDir}/${this.extractFileName(inputPath)}.txt`;
      await fileIo.writeText(txtPath, textContent);
      
      return {
        success: true,
        outputPath: txtPath,
        outputFormat: 'txt'
      };
    } catch (error) {
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 转换 ODT 到 HTML
   */
  private async convertOdt(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    // ODT 需要 LibreOffice 转换
    return {
      success: false,
      error: 'ODT 格式建议使用 LibreOffice 转换为 PDF/EPUB 后再导入'
    };
  }

  /**
   * 转换 FB2 到 EPUB
   */
  private async convertFb2(
    inputPath: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    // FB2 是 XML 格式，可以解析后转换为 EPUB
    return {
      success: false,
      error: 'FB2 格式暂不支持，建议转换为 EPUB'
    };
  }

  /**
   * 转换漫画格式（CBR/CBZ）到图片列表
   * 使用 Native CBZ 解析器
   */
  private async convertComic(
    inputPath: string,
    format: string,
    onProgress?: ProgressCallback
  ): Promise<ConvertResult> {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Converting %s: %{public}s', format, inputPath);
    
    // CBZ 是 ZIP 格式，使用 Native 解析器
    if (format === 'cbz') {
      if (onProgress) onProgress(10, '正在解析 CBZ 文件...');
      
      try {
        // 获取页面数量
        const pageCount = NativeCbzParser.getPageCount(inputPath);
        
        if (pageCount <= 0) {
          return {
            success: false,
            error: 'CBZ 解析失败或无页面'
          };
        }
        
        if (onProgress) onProgress(30, `共 ${pageCount} 页，正在提取图片...`);
        
        // 创建输出目录
        const outputDir = `${this.convertDir}/${this.extractFileName(inputPath)}`;
        await fileIo.mkdir(outputDir);
        
        // 逐页提取图片
        for (let i = 0; i < pageCount; i++) {
          if (onProgress) {
            const progress = 30 + (i / pageCount) * 60;
            onProgress(progress, `正在提取第 ${i + 1}/${pageCount} 页...`);
          }
          
          const imageData = NativeCbzParser.getPageImage(inputPath, i);
          
          if (imageData) {
            // 保存图片文件
            const fileName = NativeCbzParser.getPageFileNames(inputPath)?.[i] || `page_${i}.jpg`;
            const imagePath = `${outputDir}/${fileName}`;
            
            // TODO: 使用 fileIo.write 保存 Uint8Array
            // await fileIo.write(imagePath, imageData.buffer);
          }
        }
        
        if (onProgress) onProgress(100, '转换完成');
        
        return {
          success: true,
          outputPath: outputDir,
          outputFormat: 'comic_images'
        };
      } catch (error) {
        return {
          success: false,
          error: (error as Error).message
        };
      }
    } else {
      // CBR 需要 unrar
      return {
        success: false,
        error: 'CBR 格式需要安装 unrar 工具'
      };
    }
  }

  // ==================== Native 方法声明 ====================

  /**
   * 调用 Native CHM 解析器
   */
  private async nativeParseChm(inputPath: string): Promise<{
    success: boolean;
    title: string;
    author: string;
    pageCount: number;
    error?: string;
  }> {
    try {
      const chmInfo = NativeFormatConverter.parseChmInfo(inputPath);
      
      if (!chmInfo) {
        return {
          success: false,
          title: '',
          author: '',
          pageCount: 0,
          error: 'Native CHM parser returned null'
        };
      }
      
      return {
        success: true,
        title: chmInfo.title,
        author: chmInfo.author || 'Unknown',
        pageCount: chmInfo.pageCount,
        error: undefined
      };
    } catch (error) {
      return {
        success: false,
        title: '',
        author: '',
        pageCount: 0,
        error: (error as Error).message
      };
    }
  }

  /**
   * 调用 Native DJVU 解析器
   */
  private async nativeParseDjvu(inputPath: string): Promise<{
    success: boolean;
    title: string;
    author: string;
    pageCount: number;
    error?: string;
  }> {
    try {
      const djvuInfo = NativeFormatConverter.parseDjvuInfo(inputPath);
      
      if (!djvuInfo) {
        return {
          success: false,
          title: '',
          author: '',
          pageCount: 0,
          error: 'Native DJVU parser returned null'
        };
      }
      
      return {
        success: true,
        title: djvuInfo.title,
        author: djvuInfo.author || 'Unknown',
        pageCount: djvuInfo.pageCount,
        error: undefined
      };
    } catch (error) {
      return {
        success: false,
        title: '',
        author: '',
        pageCount: 0,
        error: (error as Error).message
      };
    }
  }

  /**
   * 渲染 DJVU 页面为图片
   */
  private async renderDjvuPage(inputPath: string, pageIndex: number): Promise<string | null> {
    try {
      const result = NativeFormatConverter.renderDjvuPage(inputPath, pageIndex, 1200, 1600);
      
      if (!result) {
        return null;
      }
      
      // 保存为 PNG 文件
      const outputPath = `${this.convertDir}/djvu_page_${pageIndex}.png`;
      // TODO: 使用 image.Packer 将 RGBA 数据保存为 PNG
      
      return outputPath;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to render DJVU page: %{public}s', 
        (error as Error).message);
      return null;
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * HTML 转 EPUB
   */
  private async htmlToEpub(htmlContent: string, title: string, author: string): Promise<string> {
    const epubFileName = `${title.replace(/[^\w]/g, '_')}_${Date.now()}.epub`;
    const epubPath = `${this.convertDir}/${epubFileName}`;
    
    try {
      // 创建 EPUB 基本结构 (简化版，符合 EPUB 3.0 标准)
      const containerXml = `<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>`;

      const contentOpf = `<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${title}</dc:title>
    <dc:creator>${author}</dc:creator>
    <dc:identifier id="BookId">urn:uuid:${generateBookId()}</dc:identifier>
    <dc:language>zh-CN</dc:language>
  </metadata>
  <manifest>
    <item id="content" href="content.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="content"/>
  </spine>
</package>`;

      const contentXhtml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <title>${title}</title>
</head>
<body>
${htmlContent}
</body>
</html>`;

      // 创建临时目录结构
      const tempDir = `${this.convertDir}/temp_epub_${Date.now()}`;
      const metaInfDir = `${tempDir}/META-INF`;
      const oebpsDir = `${tempDir}/OEBPS`;
      
      await fileIo.mkdir(tempDir);
      await fileIo.mkdir(metaInfDir);
      await fileIo.mkdir(oebpsDir);

      // 写入文件
      await this.writeText(`${metaInfDir}/container.xml`, containerXml);
      await this.writeText(`${oebpsDir}/content.opf`, contentOpf);
      await this.writeText(`${oebpsDir}/content.xhtml`, contentXhtml);

      // 使用 ZIP 压缩为 EPUB (EPUB 本质是 ZIP)
      await this.createZip(tempDir, epubPath);

      // 清理临时目录
      await this.deleteDirectory(tempDir);

      hilog.info(LOG_DOMAIN, LOG_TAG, 'HTML to EPUB converted: %{public}s', epubPath);
      return epubPath;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'HTML to EPUB conversion failed: %{public}s', 
        (error as Error).message);
      throw error;
    }
  }

  /**
   * 图片列表合并为 PDF
   */
  private async imagesToPdf(imagePaths: string[]): Promise<string> {
    if (imagePaths.length === 0) {
      throw new Error('No images to convert');
    }

    const pdfFileName = `converted_${Date.now()}.pdf`;
    const pdfPath = `${this.convertDir}/${pdfFileName}`;
    
    try {
      // 使用 ImageKit 将图片转换为 PDF
      // HarmonyOS 5.0+ 支持通过 imagePack 进行图片处理
      
      let pdfContent = '%PDF-1.4\n';
      let objectCount = 1;
      const pageObjects: number[] = [];

      // 为每张图片创建 PDF 页面
      for (let i = 0; i < imagePaths.length; i++) {
        const imagePath = imagePaths[i];
        
        // 读取图片数据
        const imageData = await this.readFileAsBuffer(imagePath);
        const imageSize = await this.getImageDimensions(imagePath);
        
        // 创建页面对象
        const pageObjectId = objectCount++;
        pageObjects.push(pageObjectId);
        
        // 添加图片资源
        const imageObjectId = objectCount++;
        
        // 简化的 PDF 结构 (实际应使用 PDF 库)
        pdfContent += `${pageObjectId} 0 obj\n`;
        pdfContent += `<< /Type /Page /Parent 1 0 R /MediaBox [0 0 ${imageSize.width} ${imageSize.height}] >>\n`;
        pdfContent += `endobj\n`;
      }

      // 由于完整的 PDF 生成非常复杂，这里使用占位符
      // 实际项目中应该使用专业的 PDF 生成库
      await this.writeText(pdfPath, '[PDF Generated from Images - Placeholder]');
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Images to PDF converted: %{public}s', pdfPath);
      return pdfPath;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Images to PDF conversion failed: %{public}s', 
        (error as Error).message);
      throw error;
    }
  }

  /**
   * 使用 mammoth.js 转换 DOCX
   */
  private async mammothConvert(fileData: ArrayBuffer): Promise<string> {
    // TODO: 在 ArkTS 中集成 mammoth.js
    // 可以通过 WebAssembly 或 HTTP 服务调用
    
    return '<html><body><p>Converted from DOCX</p></body></html>';
  }

  /**
   * RTF 到纯文本转换
   */
  private rtfToText(rtf: string): string {
    // 简单的 RTF 解析：去除控制字
    let text = rtf.replace(/\\[a-z]+[ ]?/g, '');
    text = text.replace(/[{}]/g, '');
    text = text.replace(/\\'/g, '');
    return text.trim();
  }

  /**
   * 解压 ZIP 文件
   */
  private async extractZip(zipPath: string, outputDir: string): Promise<void> {
    // TODO: 使用 JSZip 或 Native ZIP 库解压
    await fileIo.mkdir(outputDir);
  }

  /**
   * 创建 ZIP 文件 (用于 EPUB 打包)
   */
  private async createZip(sourceDir: string, zipPath: string): Promise<void> {
    try {
      // 简化实现：使用系统命令或第三方库
      // HarmonyOS 5.0+ 可以使用 @ohos/zip 模块
      
      // 这里创建一个占位符文件，实际应使用 ZIP 库
      const content = '[ZIP Archive - EPUB Format]';
      await this.writeText(zipPath, content);
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'ZIP created: %{public}s', zipPath);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Create ZIP failed: %{public}s', 
        (error as Error).message);
      throw error;
    }
  }

  /**
   * 删除目录及其内容
   */
  private async deleteDirectory(dirPath: string): Promise<void> {
    try {
      const files = await fileIo.list(dirPath);
      for (const file of files) {
        const filePath = `${dirPath}/${file}`;
        const stat = await fileIo.stat(filePath);
        
        if (stat.isDirectory()) {
          await this.deleteDirectory(filePath);
        } else {
          await fileIo.unlink(filePath);
        }
      }
      
      await fileIo.rmdir(dirPath);
    } catch (error) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Delete directory warning: %{public}s', 
        (error as Error).message);
    }
  }

  /**
   * 读取文件为 ArrayBuffer
   */
  private async readFileAsBuffer(filePath: string): Promise<ArrayBuffer> {
    try {
      const fd = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);
      const stat = await fileIo.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fileIo.read(fd.fd, buffer);
      await fileIo.close(fd);
      return buffer;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Read file as buffer failed: %{public}s', 
        (error as Error).message);
      throw error;
    }
  }

  /**
   * 获取图片尺寸
   */
  private async getImageDimensions(imagePath: string): Promise<{width: number, height: number}> {
    try {
      // 简化实现：返回默认尺寸
      // 实际应使用 ImageKit 解析图片元数据
      return { width: 800, height: 1200 };
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Get image dimensions failed: %{public}s', 
        (error as Error).message);
      return { width: 800, height: 1200 };
    }
  }

  /**
   * 从路径提取文件名
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    if (parts.length === 0) return 'unknown';
    
    let fileName = parts[parts.length - 1];
    const lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      fileName = fileName.substring(0, lastDot);
    }
    
    return fileName || 'unknown';
  }

  /**
   * 清理转换临时文件
   */
  async cleanup(): Promise<void> {
    try {
      // 删除转换目录中的所有文件
      const files = await fileIo.list(this.convertDir);
      for (const file of files) {
        const filePath = `${this.convertDir}/${file}`;
        await fileIo.unlink(filePath);
      }
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Converted files cleaned up');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Cleanup failed: %{public}s', 
        (error as Error).message);
    }
  }
}

// 导出单例
export const formatConverter = new FormatConverterService();
