/**
 * Mammoth.js 包装器 - 通过 Web 组件实现 DOCX 转 HTML
 * 
 * 使用 HarmonyOS Web 组件加载 mammoth.browser.min.js
 * 实现 DOCX 文件到 HTML 的转换
 */

import { webview } from '@kit.ArkWeb';
import { logger } from '../utils/Logger';
import { common } from '@kit.AbilityKit';

export class MammothWrapper {
  private controller: webview.WebviewController = new webview.WebviewController();
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  
  /**
   * 初始化 Web 组件
   */
  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      this.context = context;
      this.isInitialized = true;
      logger.info('[MammothWrapper] Initialized successfully');
    } catch (error) {
      logger.error('[MammothWrapper] Init failed:', error);
      throw error;
    }
  }
  
  /**
   * 将 DOCX 转换为 HTML
   * @param docxData DOCX 文件的 ArrayBuffer 数据
   * @returns HTML 字符串
   */
  async convertDocxToHtml(docxData: ArrayBuffer): Promise<string> {
    if (!this.isInitialized) {
      throw new Error('MammothWrapper not initialized. Call init() first.');
    }
    
    return new Promise((resolve, reject) => {
      try {
        // 创建包含 mammoth.js 的 HTML 页面
        const htmlContent = this.createConversionPage();
        
        // 设置消息监听
        this.controller.onMessageEvent = (event: webview.MessageEvent): void => {
          try {
            const data = JSON.parse(event.data as string);
            
            if (data.type === 'CONVERSION_RESULT') {
              resolve(data.html as string);
            } else if (data.type === 'CONVERSION_ERROR') {
              reject(new Error(data.error as string));
            }
          } catch (error) {
            logger.error('[MammothWrapper] Message parsing failed:', error);
            reject(error);
          }
        };
        
        // 加载 HTML 页面
        this.controller.loadData(htmlContent, 'text/html', 'UTF-8');
        
        // 等待页面加载完成后发送转换请求
        setTimeout(() => {
          try {
            // 将 ArrayBuffer 转换为数组
            const uint8Array = new Uint8Array(docxData);
            const arrayData = Array.from(uint8Array);
            
            // 发送转换请求
            const script = `
              if (typeof mammoth !== 'undefined') {
                const arrayBuffer = new Uint8Array(${JSON.stringify(arrayData)}).buffer;
                mammoth.convertToHtml({ arrayBuffer: arrayBuffer })
                  .then(function(result) {
                    window.postMessage(JSON.stringify({
                      type: 'CONVERSION_RESULT',
                      html: result.value,
                      warnings: result.messages
                    }));
                  })
                  .catch(function(error) {
                    window.postMessage(JSON.stringify({
                      type: 'CONVERSION_ERROR',
                      error: error.message
                    }));
                  });
              } else {
                window.postMessage(JSON.stringify({
                  type: 'CONVERSION_ERROR',
                  error: 'mammoth.js not loaded'
                }));
              }
            `;
            
            this.controller.runJavaScript(script);
          } catch (error) {
            logger.error('[MammothWrapper] JavaScript execution failed:', error);
            reject(error);
          }
        }, 1500); // 给页面足够的加载时间
        
      } catch (error) {
        logger.error('[MammothWrapper] Conversion setup failed:', error);
        reject(error);
      }
    });
  }
  
  /**
   * 创建包含 mammoth.js 的 HTML 页面
   */
  private createConversionPage(): string {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>DOCX Converter</title>
  <script src="mammoth.browser.min.js"></script>
</head>
<body>
  <div id="output"></div>
  <script>
    console.log('Mammoth.js loaded:', typeof mammoth !== 'undefined');
  </script>
</body>
</html>`;
  }
  
  /**
   * 清理资源
   */
  cleanup(): void {
    this.controller = new webview.WebviewController();
    this.isInitialized = false;
    logger.info('[MammothWrapper] Cleaned up');
  }
}
