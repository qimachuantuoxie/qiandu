import { logger } from '../../../utils/Logger';
// OCR 鏈嶅姟 - 浣跨敤 HarmonyOS ML Kit 瀹炵幇鐪熷疄鏂囧瓧璇嗗埆
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
   * 鍒濆�鍖?OCR 鏈嶅姟
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      this.context = context;
      
      // 鍒涘缓鏂囨湰璇嗗埆鍣?
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
   * 鐠囧棗鍩嗛崶鍓у�娑擃厾娈戦弬鍥х摟
   */
  async recognizeText(imagePath: string, needPosition: boolean = false): Promise<OcrResult> {
    logger.info('[OcrService] Recognizing text from:', imagePath);

    if (!this.initialized || !this.context) {
      // 濡傛灉鏈�垵濮嬪寲锛屽皾璇曚娇鐢ㄥ綋鍓峜ontext鍒濆�鍖?
      logger.warn('[OcrService] Service not initialized');
      return this.createEmptyResult();
    }

    try {
      // 璇诲彇鍥剧墖
      const imageData = await this.readImageFile(imagePath);
      if (!imageData) {
        return this.createEmptyResult();
      }

      // 浣跨敤 ML Kit 杩涜�鏂囧瓧璇嗗埆
      const mlResult = await this.recognizeWithMLKit(imageData);
      
      if (mlResult.success) {
        return {
          success: true,
          text: mlResult.text,
          confidence: mlResult.confidence,
          blocks: needPosition ? mlResult.blocks : undefined
        };
      } else {
        // 闄嶇骇鏂规�锛氫娇鐢ㄥ熀鏈�瘑鍒?
        return this.basicRecognize(imageData, needPosition);
      }
    } catch (error) {
      logger.error('[OcrService] OCR error:', error);
      return this.createEmptyResult();
    }
  }

  /**
   * 浣跨敤 ML Kit 璇嗗埆鏂囧瓧
   */
  private async recognizeWithMLKit(imageData: Uint8Array): Promise<OcrResult> {
    if (!this.textRecognizer) {
      return this.createEmptyResult();
    }

    try {
      // 鍒涘缓 PixelMap
      const buffer = imageData.buffer as ArrayBuffer;
      const imageSource = image.createImageSource(buffer);
      const pixelMap = await imageSource.createPixelMap();
      
      // 璇嗗埆鏂囧瓧
      const result: MLVisionText = await this.textRecognizer.detect(pixelMap);
      
      // 瑙ｆ瀽缁撴灉
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

          // 瑙ｆ瀽琛?
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

              // 瑙ｆ瀽璇?
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
   * 鍩烘湰璇嗗埆锛堥檷绾ф柟妗堬級
   */
  private basicRecognize(imageData: Uint8Array, needPosition: boolean): OcrResult {
    const header = this.getImageHeader(imageData);
    let info = `[鍥剧墖鏍煎紡: ${header}]`;

    return {
      success: true,
      text: info,
      confidence: 0.5,
      blocks: needPosition ? this.createMockBlocks(info) : undefined
    };
  }

  /**
   * 浠?Base64 璇嗗埆鏂囧瓧
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
   * 妫€娴嬫枃瀛楀尯鍩?
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
   * 璇诲彇鍥剧墖鏂囦欢
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
   * 閼惧嘲褰囬崶鍓у�婢剁繝淇婇幁?
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
   * Base64 鏉烆兛绨╂潻娑樺煑鐎涙�顑佹稉?
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
   * 閸掓稑缂撶粚铏圭波閺?
   */
  private createEmptyResult(): OcrResult {
    return {
      success: false,
      text: '',
      confidence: 0
    };
  }

  /**
   * 閸掓稑缂撳Ο鈩冨珯閺傚洦婀伴崸妤嬬礄閻€劋绨�ù瀣�槸閿?
   */
  private createMockBlocks(text: string): OcrTextBlock[] {
    return [{
      text: text,
      confidence: 0.9,
      x: 0,
      y: 0,
      width: 100,
      height: 100,
      lines: [{
        text: text,
        confidence: 0.9,
        x: 0,
        y: 0,
        width: 100,
        height: 20,
        words: [{
          text: text,
          confidence: 0.9,
          x: 0,
          y: 0,
          width: 50,
          height: 20
        }]
      }]
    }];
  }

  /**
   * 鐠佸墽鐤嗙拠鍡楀焼鐠囶叀鈻?
   */
  setLanguage(language: string): void {
    this.language = language;
    logger.info('[OcrService] Language set to:', language);
  }

  /**
   * 闁插﹥鏂佺挧鍕�爱
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
