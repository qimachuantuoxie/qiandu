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
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
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
      PageHeader({
        title: '文件夹扫描',
        showBack: true,
        onBack: () => {
          try { goBack(); } 
          catch (e) { logger.error('[FolderScannerPage] back failed', e); }
        },
        rightContent: this.scanHistory.length > 0 ? () => {
          Row() {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(20)
              .fontColor([HDSColours.primary.blue])
          }
          .width(40)
          .height(40)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(HDSColours.primary.blue + '15')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showHistory = !this.showHistory;
          })
        } : undefined
      })

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
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  EmptyState() {
    Column({ space: HDSSpacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(48)
          .fontColor([this.isDarkMode ? HDSColours.neutralDark.textHint : HDSColours.neutral.gray300])
      }
      .width(100)
      .height(100)
      .borderRadius(HDSBorderRadius.full)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
      .justifyContent(FlexAlign.Center)

      Text('选择文件夹开始扫描')
        .fontSize(HDSTypography.sizes.xl)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Button() {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.folder.badge.plus'))
            .fontSize(20)
            .fontColor([HDSColours.neutral.white])
          
          Text('选择文件夹')
            .fontSize(HDSTypography.sizes.xl)
            .fontWeight(FontWeight.SemiBold)
            .fontColor(HDSColours.neutral.white)
        }
      }
      .height(56)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
      })
      .borderRadius(HDSBorderRadius.xl)
      .shadow({
        radius: 8,
        color: HDSColours.primary.blue + '40',
        offsetY: 4
      })
      .onClick(() => this.onSelectFolder())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ScanningView() {
    Column({ space: HDSSpacing.xxl }) {
      LoadingProgress()
        .width(60)
        .height(60)
        .color(HDSColours.primary.blue)

      Column({ space: HDSSpacing.md }) {
        Text('正在扫描...')
          .fontSize(HDSTypography.sizes.xl)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

        Text(`已发现 ${this.scannedFilesCount} 个文档`)
          .fontSize(HDSTypography.sizes.md)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
      }

      Progress({ value: this.scanProgress, total: 100, type: ProgressType.Linear })
        .width('80%')
        .height(8)
        .borderRadius(HDSBorderRadius.xl)
        .color(HDSColours.primary.blue)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)')

      Text(`${this.scanProgress}%`)
        .fontSize(HDSTypography.sizes.md)
        .fontColor(HDSColours.primary.blue)
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
          .fontSize(HDSTypography.sizes.md)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)

        Blank()

        // 全选
        Text(this.selectedDocs.size === this.scannedDocs.length ? '取消全选' : '全选')
          .fontSize(HDSTypography.sizes.sm)
          .fontColor(HDSColours.primary.blue)
          .onClick(() => this.selectAll())

        // 导入按钮
        Button() {
          Row({ space: HDSSpacing.xs }) {
            SymbolGlyph($r('sys.symbol.square.and.arrow.down'))
              .fontSize(16)
              .fontColor([HDSColours.neutral.white])
            
            Text(`导入 (${this.selectedDocs.size})`)
              .fontSize(HDSTypography.sizes.sm)
              .fontColor(HDSColours.neutral.white)
          }
        }
        .height(40)
        .backgroundColor(HDSColours.primary.blue)
        .borderRadius(HDSBorderRadius.xl)
        .margin({ left: HDSSpacing.md })
        .enabled(this.selectedDocs.size > 0 && !this.isImporting)
        .onClick(() => this.importSelected())
      }
      .width('100%')
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg, top: HDSSpacing.md, bottom: HDSSpacing.sm })

      // 文档列表
      List({ space: HDSSpacing.md }) {
        ForEach(this.scannedDocs, (doc: ScannedDocument) => {
          ListItem() {
            this.DocumentItem(doc)
          }
        }, (doc: ScannedDocument) => doc.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg, bottom: HDSSpacing.xxxl })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DocumentItem(doc: ScannedDocument) {
    Row({ space: HDSSpacing.lg }) {
      // 复选框
      Toggle({ type: ToggleType.Checkbox, isOn: this.selectedDocs.has(doc.id) })
        .selectedColor(HDSColours.primary.blue)
        .onChange(() => this.toggleSelect(doc.id))

      // 文件图标
      Column() {
        SymbolGlyph($r('sys.symbol.doc.text'))
          .fontSize(24)
          .fontColor([HDSColours.primary.blue])
      }
      .width(50)
      .height(50)
      .borderRadius(HDSBorderRadius.lg)
      .backgroundColor(HDSColours.primary.blue + '15')
      .justifyContent(FlexAlign.Center)

      // 文件信息
      Column({ space: HDSSpacing.sm }) {
        Text(doc.name)
          .fontSize(HDSTypography.sizes.md)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: HDSSpacing.sm }) {
          Text(doc.format.toUpperCase())
            .fontSize(HDSTypography.sizes.xs)
            .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm, top: HDSSpacing.xs, bottom: HDSSpacing.xs })
            .backgroundColor(HDSColours.primary.blue + '15')
            .fontColor(HDSColours.primary.blue)
            .borderRadius(HDSBorderRadius.xl)

          Text(this.formatFileSize(doc.size))
            .fontSize(HDSTypography.sizes.xs)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(HDSPacing.lg)
    .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.cardBackground : HDSColours.neutral.white)
    .borderRadius(HDSBorderRadius.xl)
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
