import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import folderScanner, { ScannedDocument, ScanConfig, ScanProgress, ImportResult, ScanHistory } from '../../../core/services/book/FolderScannerService';
import { enhancedParser } from '../../../core/services/reader/EnhancedDocumentParser';
import { DocumentFormat } from '../../../core/services/models/DocumentModels';
import { bookViewModel } from '../../../core/viewmodels/BookViewModel';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BookFormat, ReadStatus, BookInfo } from '../../../core/models/BookModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';

@Entry
@ComponentV2
struct FolderScannerPage {
  @Local isDarkMode: boolean = false;
  @Local isScanning: boolean = false;
  @Local scanProgress: number = 0;
  @Local scannedDocs: ScannedDocument[] = [];
  @Local selectedDocs: Set<string> = new Set();
  @Local isImporting: boolean = false;
  @Local importResult: ImportResult | null = null;
  @Local currentFolder: string = '';
  @Local supportedFormats: DocumentFormat[] = [
    DocumentFormat.PDF,
    DocumentFormat.EPUB,
    DocumentFormat.TXT,
    DocumentFormat.DOCX,
    DocumentFormat.RTF,
    DocumentFormat.FB2,
    DocumentFormat.ODT,
    DocumentFormat.HTML,
    DocumentFormat.CBZ
  ];
  @Local showFormatFilter: boolean = false;
  @Local recursiveScan: boolean = true;
  @Local excludeHidden: boolean = true;
  @Local scanHistory: ScanHistory[] = [];
  @Local showHistory: boolean = false;
  @Local scannedFilesCount: number = 0;
  @Local fontScale: number = 1.0;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local screenInfo: ScreenInfo | null = null;

  private readonly ALL_FORMATS: DocumentFormat[] = [
    DocumentFormat.PDF, DocumentFormat.EPUB, DocumentFormat.TXT,
    DocumentFormat.MOBI, DocumentFormat.DOCX, DocumentFormat.DOC,
    DocumentFormat.RTF, DocumentFormat.HTML, DocumentFormat.AZW,
    DocumentFormat.AZW3, DocumentFormat.DJVU, DocumentFormat.CHM,
    DocumentFormat.FB2, DocumentFormat.ODT, DocumentFormat.CBR,
    DocumentFormat.CBZ
  ];

  private context: common.Context | null = null;

  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await fontScaleManager.init(this.context);
    }
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await folderScanner.init(this.context as common.Context);
    this.scanHistory = folderScanner.getScanHistory();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  async onSelectFolder(): Promise<void> {
    try {
      const folderPath: string = (await folderScanner.selectFolder()) || '';

      if (folderPath && folderPath.length > 0) {
        this.currentFolder = folderPath;
        this.scannedDocs = [];
        this.selectedDocs = new Set();
        this.importResult = null;

        await folderScanner.authorizeFolderAccess(folderPath);
        await this.startScan();
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[FolderScannerPage] 选择文件夹失败: ' + message);
      promptAction.showToast({
        message: '选择文件夹失败',
        duration: 2000
      });
    }
  }

  async startScan(): Promise<void> {
    if (this.currentFolder.length === 0 || this.isScanning) {
      return;
    }

    this.isScanning = true;
    this.scanProgress = 0;
    this.scannedDocs = [];
    this.scannedFilesCount = 0;
    this.importResult = null;

    const startTime = Date.now();

    try {
      const config: ScanConfig = {
        scanPath: this.currentFolder,
        recursive: this.recursiveScan,
        supportedFormats: this.supportedFormats,
        excludeHidden: this.excludeHidden
      };

      await folderScanner.scanFolder(config, {
        onScanStart: () => {
          logger.info('[FolderScannerPage] 扫描开始');
        },
        onScanProgress: (progress: ScanProgress) => {
          this.scanProgress = progress.percentage;
          this.scannedFilesCount = progress.foundDocs;
        },
        onScanComplete: (docs: ScannedDocument[]) => {
          this.scannedDocs = docs;
          this.isScanning = false;

          const duration = Date.now() - startTime;

          if (docs.length > 0) {
            const history: ScanHistory = {
              path: this.currentFolder,
              scanTime: Date.now(),
              foundCount: docs.length,
              importedCount: 0,
              recursive: this.recursiveScan,
              duration: duration
            };
            folderScanner.addScanHistory(history);
            this.scanHistory = folderScanner.getScanHistory();

            promptAction.showToast({
              message: '扫描完成，发现 ' + docs.length + '个文档',
              duration: 2000
            });
          } else {
            promptAction.showToast({
              message: '未发现支持的文档格式',
              duration: 2000
            });
          }
        },
        onScanError: (error: Error) => {
          this.isScanning = false;
          promptAction.showToast({
            message: '扫描失败: ' + error.message,
            duration: 2000
          });
        }
      });
    } catch (error) {
      this.isScanning = false;
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[FolderScannerPage] 扫描失败: ' + message);
    }
  }

  private toggleSelect(docId: string): void {
    if (this.selectedDocs.has(docId)) {
      this.selectedDocs.delete(docId);
    } else {
      this.selectedDocs.add(docId);
    }
  }

  private selectAll(): void {
    if (this.selectedDocs.size === this.scannedDocs.length) {
      this.selectedDocs.clear();
    } else {
      this.scannedDocs.forEach(doc => this.selectedDocs.add(doc.id));
    }
  }

  async importSelected(): Promise<void> {
    if (this.selectedDocs.size === 0) {
      promptAction.showToast({
        message: '请选择要导入的文档',
        duration: 2000
      });
      return;
    }

    this.isImporting = true;

    try {
      const selectedList = this.scannedDocs.filter(doc => this.selectedDocs.has(doc.id));
      let successCount = 0;
      let failedCount = 0;

      for (const doc of selectedList) {
        try {
          const result = await enhancedParser.parse(doc.path);
          
          if (result.success && result.bookInfo) {
            const bookInfo = result.bookInfo;
            bookInfo.filePath = doc.path;
            bookInfo.format = this.getBookFormat(doc.format);
            bookInfo.addTime = Date.now();
            bookInfo.readStatus = ReadStatus.NOT_STARTED;
            bookInfo.progress = 0;
            bookInfo.totalReadingTime = 0;
            bookInfo.lastReadTime = 0;
            bookInfo.lastReadChapter = 0;
            bookInfo.isFavorite = false;
            bookInfo.groupIds = [];

            bookViewModel.addBook(bookInfo);
            successCount++;
          } else {
            failedCount++;
          }
        } catch (error) {
          failedCount++;
          const message = error instanceof Error ? error.message : String(error);
          logger.error('[FolderScannerPage] 导入失败: ' + message);
        }
      }

      this.importResult = {
        success: successCount,
        fail: failedCount,
        total: selectedList.length,
        message: `成功: ${successCount}, 失败: ${failedCount}`
      };

      promptAction.showToast({
        message: this.importResult.message,
        duration: 2000
      });
    } finally {
      this.isImporting = false;
    }
  }

  private getBookFormat(format: DocumentFormat): BookFormat {
    switch (format) {
      case DocumentFormat.EPUB: return BookFormat.EPUB;
      case DocumentFormat.PDF: return BookFormat.PDF;
      case DocumentFormat.TXT: return BookFormat.TXT;
      case DocumentFormat.MOBI: return BookFormat.MOBI;
      case DocumentFormat.DOCX:
      case DocumentFormat.DOC: return BookFormat.DOCX;
      default: return BookFormat.TXT;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.NavBar()

      if (this.currentFolder.length === 0) {
        // 空状态
        this.EmptyState()
      } else if (this.isScanning) {
        // 扫描中
        this.ScanningView()
      } else {
        // 扫描结果
        this.ScanResults()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  NavBar() {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron.left'))
          .fontSize(Size.iconLG)
          .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
      }
      .width(Size.buttonMD)
      .height(Size.buttonMD)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        try { goBack(); } 
        catch (e) { logger.error('[FolderScannerPage] back failed', e); }
      })
      .stateStyles({
        pressed: { .scale({ x: 0.9, y: 0.9 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })

      Text('文件夹扫描')
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.SemiBold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 历史记录按钮
      if (this.scanHistory.length > 0) {
        Row() {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(Size.iconMD)
            .fontColor([this.currentColors.primary])
        }
        .width(Size.buttonMD)
        .height(Size.buttonMD)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.currentColors.primary + '15')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showHistory = !this.showHistory;
        })
      }
    }
    .width('100%')
    .height(Size.buttonLG + Spacing.sm)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
    .shadow(getShadow('sm', this.isDarkMode))
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('选择文件夹开始扫描')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Button() {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.folder.badge.plus'))
            .fontSize(Size.iconMD)
            .fontColor(['#FFFFFF'])
          
          Text('选择文件夹')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.SemiBold)
            .fontColor('#FFFFFF')
        }
      }
      .height(Size.buttonLG + Spacing.sm)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
      })
      .borderRadius(BorderRadius.xl)
      .shadow({
        radius: 8,
        color: COMMON_COLORS.PRIMARY_BLUE + '40',
        offsetY: 4
      })
      .onClick(() => this.onSelectFolder())
      .stateStyles({
        pressed: { .scale({ x: 0.98, y: 0.98 }) },
        normal: { .scale({ x: 1, y: 1 }) }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ScanningView() {
    Column({ space: Spacing.xxl }) {
      LoadingProgress()
        .width(60)
        .height(60)
        .color(COMMON_COLORS.PRIMARY_BLUE)

      Column({ space: Spacing.md }) {
        Text('正在扫描...')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Text(`已发现 ${this.scannedFilesCount} 个文档`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }

      Progress({ value: this.scanProgress, total: 100, type: ProgressType.Linear })
        .width('80%')
        .height(8)
        .borderRadius(BorderRadius.xl)
        .color(COMMON_COLORS.PRIMARY_BLUE)
        .backgroundColor(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.1)'))

      Text(`${this.scanProgress}%`)
        .fontSize(fontScaleManager.getScaledFontSize(14))
        .fontColor(COMMON_COLORS.PRIMARY_BLUE)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ScanResults() {
    Column() {
      // 操作栏
      Row() {
        Text(`共 ${this.scannedDocs.length} 个文档`)
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))

        Blank()

        // 全选
        Text(this.selectedDocs.size === this.scannedDocs.length ? '取消全选' : '全选')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => this.selectAll())

        // 导入按钮
        Button() {
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.square.and.arrow.down'))
              .fontSize(Size.iconSM)
              .fontColor(['#FFFFFF'])
            
            Text(`导入 (${this.selectedDocs.size})`)
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor('#FFFFFF')
          }
        }
        .height(Size.buttonSM + Spacing.sm)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(BorderRadius.xl)
        .margin({ left: Spacing.md })
        .enabled(this.selectedDocs.size > 0 && !this.isImporting)
        .onClick(() => this.importSelected())
        .stateStyles({
          pressed: { .scale({ x: 0.95, y: 0.95 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md, bottom: Spacing.sm })

      // 文档列表
      List({ space: Spacing.md }) {
        ForEach(this.scannedDocs, (doc: ScannedDocument) => {
          ListItem() {
            this.DocumentItem(doc)
          }
        }, (doc: ScannedDocument) => doc.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: Spacing.lg, right: Spacing.lg, bottom: Spacing.xxxl })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DocumentItem(doc: ScannedDocument) {
    Row({ space: Spacing.lg }) {
      // 复选框
      Toggle({ type: ToggleType.Checkbox, isOn: this.selectedDocs.has(doc.id) })
        .selectedColor(COMMON_COLORS.PRIMARY_BLUE)
        .onChange(() => this.toggleSelect(doc.id))

      // 文件图标
      Column() {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(Size.iconXL)
          .fontColor([this.currentColors.primary])
      }
      .width(50)
      .height(50)
      .borderRadius(BorderRadius.lg)
      .backgroundColor(this.currentColors.primary + '15')
      .justifyContent(FlexAlign.Center)

      // 文件信息
      Column({ space: Spacing.sm }) {
        Text(doc.name)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: Spacing.sm }) {
          Text(doc.format.toUpperCase())
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
            .backgroundColor(this.currentColors.primary + '15')
            .fontColor(this.currentColors.primary)
            .borderRadius(BorderRadius.xl)

          Text(this.formatFileSize(doc.size))
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}

// 预览组件
@Preview
@ComponentV2
struct FolderScannerPagePreview {
  build() {
    Column() {
      Text('文件夹扫描 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      FolderScannerPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('文件夹扫描 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      FolderScannerPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
