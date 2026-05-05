import { logger } from '../../../utils/Logger';
// OCR 服务 - 使用 HarmonyOS ML Kit 实现真实文字识别
import { fileIo } from '@kit.CoreFileKit';
import { mlVision, MLVisionTextRecognizer, MLVisionText, MLVisionTextBlock, MLVisionTextLine, MLVisionTextElement } from '@kit.MLKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';

export interface OcrResult {
  success: boolean;
  text: string;
  confidence: number;
  blocks?: OcrTextBlock[];
}

export interface OcrTextBlock {
  text: string;
  confidence: number;
  x: number;
  y: number;
  width: number;
  height: number;
  lines?: OcrTextLine[];
}

export interface OcrTextLine {
  text: string;
  confidence: number;
  x: number;
  y: number;
  width: number;
  height: number;
  words: OcrWord[];
}

export interface OcrWord {
  text: string;
  confidence: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface RegionResult {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
}

class OcrServiceImpl {
  private static instance: OcrServiceImpl;
  private initialized: boolean = false;
  private language: string = 'zh-CN';
  private context: common.Context | null = null;
  private textRecognizer: MLVisionTextRecognizer | null = null;

  private constructor() {}

  static getInstance(): OcrServiceImpl {
    if (!OcrServiceImpl.instance) {
      OcrServiceImpl.instance = new OcrServiceImpl();
    }
    return OcrServiceImpl.instance;
  }

  /**
   * 初始化 OCR 服务
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      this.context = context;
      
      // 创建文本识别器
      const setting = {
        language: this.language,
        scene: mlVision.MLVisionTextScene.DOCUMENT
      };
      
      this.textRecognizer = mlVision.createTextRecognizer(setting);
      
      this.initialized = true;
      logger.info('[OcrService] Initialized with ML Kit');
      return true;
    } catch (error) {
      logger.error('[OcrService] Init failed:', error);
      return false;
    }
  }

  /**
   * 识别图片中的文字
   */
  async recognizeText(imagePath: string, needPosition: boolean = false): Promise<OcrResult> {
    logger.info('[OcrService] Recognizing text from:', imagePath);

    if (!this.initialized || !this.context) {
      // 如果未初始化，尝试使用当前context初始化
      logger.warn('[OcrService] Service not initialized');
      return this.createEmptyResult();
    }

    try {
      // 读取图片
      const imageData = await this.readImageFile(imagePath);
      if (!imageData) {
        return this.createEmptyResult();
      }

      // 使用 ML Kit 进行文字识别
      const mlResult = await this.recognizeWithMLKit(imageData);
      
      if (mlResult.success) {
        return {
          success: true,
          text: mlResult.text,
          confidence: mlResult.confidence,
          blocks: needPosition ? mlResult.blocks : undefined
        };
      } else {
        // 降级方案：使用基本识别
        return this.basicRecognize(imageData, needPosition);
      }
    } catch (error) {
      logger.error('[OcrService] OCR error:', error);
      return this.createEmptyResult();
    }
  }

  /**
   * 使用 ML Kit 识别文字
   */
  private async recognizeWithMLKit(imageData: Uint8Array): Promise<OcrResult> {
    if (!this.textRecognizer) {
      return this.createEmptyResult();
    }

    try {
      // 创建 PixelMap
      const buffer = imageData.buffer as ArrayBuffer;
      const imageSource = image.createImageSource(buffer);
      const pixelMap = await imageSource.createPixelMap();
      
      // 识别文字
      const result: MLVisionText = await this.textRecognizer.detect(pixelMap);
      
      // 解析结果
      let fullText = '';
      const blocks: OcrTextBlock[] = [];
      let totalConfidence = 0;
      let blockCount = 0;

      if (result.blocks) {
        for (const block of result.blocks) {
          const blockText = block.content || '';
          fullText += blockText + '\n';
          totalConfidence += block.confidence || 0;
          blockCount++;

          const ocrBlock: OcrTextBlock = {
            text: blockText,
            confidence: block.confidence || 0,
            x: block.boundingRect !== undefined ? block.boundingRect.x : 0,
            y: block.boundingRect !== undefined ? block.boundingRect.y : 0,
            width: block.boundingRect !== undefined ? block.boundingRect.width : 0,
            height: block.boundingRect !== undefined ? block.boundingRect.height : 0,
            lines: []
          };

          // 解析行
          if (block.lines) {
            for (const line of block.lines) {
              const ocrLine: OcrTextLine = {
                text: line.content || '',
                confidence: line.confidence || 0,
                x: line.boundingRect !== undefined ? line.boundingRect.x : 0,
                y: line.boundingRect !== undefined ? line.boundingRect.y : 0,
                width: line.boundingRect !== undefined ? line.boundingRect.width : 0,
                height: line.boundingRect !== undefined ? line.boundingRect.height : 0,
                words: []
              };

              // 解析词
              if (line.elements) {
                for (const element of line.elements) {
                  const word: OcrWord = {
                    text: element.content || '',
                    confidence: element.confidence || 0,
                    x: element.boundingRect !== undefined ? element.boundingRect.x : 0,
                    y: element.boundingRect !== undefined ? element.boundingRect.y : 0,
                    width: element.boundingRect !== undefined ? element.boundingRect.width : 0,
                    height: element.boundingRect !== undefined ? element.boundingRect.height : 0
                  };
                  const newWords: OcrWord[] = [];
                  for (let j = 0; j < ocrLine.words.length; j++) {
                    newWords.push(ocrLine.words[j]);
                  }
                  newWords.push(word);
                  ocrLine.words = newWords;
                }
              }

              if (ocrBlock.lines !== undefined) {
                const newLines: OcrTextLine[] = [];
                for (let j = 0; j < ocrBlock.lines.length; j++) {
                  newLines.push(ocrBlock.lines[j]);
                }
                newLines.push(ocrLine);
                ocrBlock.lines = newLines;
              }
            }
          }

          const newBlocks: OcrTextBlock[] = [];
          for (let j = 0; j < blocks.length; j++) {
            newBlocks.push(blocks[j]);
          }
          newBlocks.push(ocrBlock);
          blocks.length = 0;
          for (let j = 0; j < newBlocks.length; j++) {
            blocks.push(newBlocks[j]);
          }
        }
      }

      const avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0;

      return {
        success: true,
        text: fullText.trim(),
        confidence: avgConfidence,
        blocks: blocks
      };
    } catch (error) {
      logger.error('[OcrService] ML Kit recognition failed:', error);
      return this.createEmptyResult();
    }
  }

  /**
   * 基本识别（降级方案）
   */
  private basicRecognize(imageData: Uint8Array, needPosition: boolean): OcrResult {
    logger.warn('[OcrService] ML Kit recognition not available, no fallback mock data');
    return this.createEmptyResult();
  }

  /**
   * 从 Base64 识别文字
   */
  async recognizeTextFromBase64(imageBase64: string, needPosition: boolean = false): Promise<OcrResult> {
    logger.info('[OcrService] Recognizing text from base64 image');

    if (!this.initialized) {
      logger.warn('[OcrService] Service not initialized');
      return this.createEmptyResult();
    }

    try {
      let base64Data = imageBase64;
      if (base64Data.includes(',')) {
        base64Data = base64Data.split(',')[1];
      }

      const binaryStr = this.base64ToBinaryString(base64Data);
      const bytes = new Uint8Array(binaryStr.length);
      for (let i = 0; i < binaryStr.length; i++) {
        bytes[i] = binaryStr.charCodeAt(i);
      }

      return await this.recognizeWithMLKit(bytes);
    } catch (error) {
      logger.error('[OcrService] Base64 OCR error:', error);
      return this.createEmptyResult();
    }
  }

  /**
   * 检测文字区域
   */
  async detectTextRegions(imagePath: string): Promise<RegionResult[]> {
    logger.info('[OcrService] Detecting text regions in:', imagePath);

    if (!this.initialized) {
      logger.warn('[OcrService] Service not initialized');
      return [];
    }

    try {
      const imageData = await this.readImageFile(imagePath);
      if (!imageData) return [];

      const result = await this.recognizeWithMLKit(imageData);
      const regions: RegionResult[] = [];

      if (result.blocks) {
        for (const block of result.blocks) {
          regions.push({
            x: block.x,
            y: block.y,
            width: block.width,
            height: block.height,
            label: block.text
          });
        }
      }

      return regions;
    } catch (error) {
      logger.error('[OcrService] Region detection error:', error);
      return [];
    }
  }

  /**
   * 读取图片文件
   */
  private async readImageFile(imagePath: string): Promise<Uint8Array | null> {
    try {
      const stat = fileIo.statSync(imagePath);
      const buffer = new ArrayBuffer(stat.size);
      const file = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return new Uint8Array(buffer);
    } catch (error) {
      logger.error('[OcrService] Read image file failed:', error);
      return null;
    }
  }

  /**
   * 获取图片头部信息
   */
  private getImageHeader(data: Uint8Array): string {
    if (data.length < 4) return 'unknown';
    
    if (data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4E && data[3] === 0x47) {
      return 'PNG';
    }
    if (data[0] === 0xFF && data[1] === 0xD8) {
      return 'JPEG';
    }
    if (data[0] === 0x47 && data[1] === 0x49 && data[2] === 0x46) {
      return 'GIF';
    }
    if (data[0] === 0x42 && data[1] === 0x4D) {
      return 'BMP';
    }
    return 'unknown';
  }

  /**
   * Base64 转换为二进制字符串
   */
  private base64ToBinaryString(base64: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let binaryStr = '';
    
    for (let i = 0; i < base64.length; i += 4) {
      const bytes = [
        chars.indexOf(base64[i]),
        chars.indexOf(base64[i + 1]),
        chars.indexOf(base64[i + 2]),
        chars.indexOf(base64[i + 3])
      ];
      
      binaryStr += String.fromCharCode((bytes[0] << 2) | (bytes[1] >> 4));
      if (bytes[2] !== -1) {
        binaryStr += String.fromCharCode(((bytes[1] & 0x0F) << 4) | (bytes[2] >> 2));
      }
      if (bytes[3] !== -1) {
        binaryStr += String.fromCharCode(((bytes[2] & 0x03) << 6) | bytes[3]);
      }
    }
    
    return binaryStr;
  }

  /**
   * 创建空结果
   */
  private createEmptyResult(): OcrResult {
    return {
      success: false,
      text: '',
      confidence: 0
    };
  }

  // createMockBlocks removed - no mock data allowed in production

  /**
   * 设置语言
   */
  setLanguage(language: string): void {
    this.language = language;
    logger.info('[OcrService] Language set to:', language);
  }

  /**
   * 释放资源
   */
  release(): void {
    if (this.textRecognizer) {
      this.textRecognizer.destroy();
      this.textRecognizer = null;
    }
    this.initialized = false;
    logger.info('[OcrService] Released');
  }
}

export const ocrService = OcrServiceImpl.getInstance();
export default ocrService;
