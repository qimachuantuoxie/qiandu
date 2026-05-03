/**
 * 文件夹扫描页面 - v5.2
 * Folder Scanner Page - Scan and Import Documents from Folders
 */

import folderScanner, { ScannedDocument, ScanConfig, ScanProgress, ImportResult, ScanHistory } from '../services/book/FolderScannerService';
import { enhancedParser } from '../services/reader/EnhancedDocumentParser';
import { DocumentFormat } from '../services/models/DocumentModels';
import { bookViewModel } from '../viewmodels/BookViewModel';
import { uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../services/reader/UIDesignKitService';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BookFormat, ReadStatus, BookInfo } from '../models/BookModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';

@Entry
@Component
struct FolderScannerPage {
  @State isDarkMode: boolean = false;
  @State isScanning: boolean = false;
  @State scanProgress: number = 0;
  @State scannedDocs: ScannedDocument[] = [];
  @State selectedDocs: Set<string> = new Set();
  @State isImporting: boolean = false;
  @State importResult: ImportResult | null = null;
  @State currentFolder: string = '';
  @State supportedFormats: DocumentFormat[] = [
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
  @State showFormatFilter: boolean = false;
  @State recursiveScan: boolean = true;
  @State excludeHidden: boolean = true;
  @State scanHistory: ScanHistory[] = [];
  @State showHistory: boolean = false;
  @State scannedFilesCount: number = 0;
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();

  private readonly ALL_FORMATS: DocumentFormat[] = [
    DocumentFormat.PDF, DocumentFormat.EPUB, DocumentFormat.TXT,
    DocumentFormat.MOBI, DocumentFormat.DOCX, DocumentFormat.DOC,
    DocumentFormat.RTF, DocumentFormat.HTML, DocumentFormat.AZW,
    DocumentFormat.AZW3, DocumentFormat.DJVU, DocumentFormat.CHM,
    DocumentFormat.FB2, DocumentFormat.ODT, DocumentFormat.CBR,
    DocumentFormat.CBZ
  ];

  private theme: ThemeColors = LIGHT_THEME;
  @State private context: common.Context | null = null;

  /**
   * 页面初始化
   */
  aboutToAppear() {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.initData();
  }

  private initData(): void {
    this.isDarkMode = appTheme.isDarkMode();
    this.theme = uiDesignKit.getThemeColors();
    this.currentColors = themeManager.getColors();
  }

  private async initAsyncData(): Promise<void> {
    if (!this.context) return;
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    await folderScanner.init(this.context);

    // 加载扫描历史
    this.scanHistory = folderScanner.getScanHistory();
  }

  /**
   * 根据主题获取颜色
   */
  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 根据主题获取背景色
   */
  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 选择文件夹
   */
  async onSelectFolder(): Promise<void> {
    try {
      const folderPath: string = (await folderScanner.selectFolder()) ?? '';

      if (folderPath && folderPath.length > 0) {
        this.currentFolder = folderPath;
        this.scannedDocs = [];
        this.selectedDocs = new Set();
        this.importResult = null;

        // 授权访问
        await folderScanner.authorizeFolderAccess(folderPath);

        // 开始扫描
        await this.startScan();
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[FolderScannerPage] 选择文件夹失败: ' + message);
      promptAction.showToast({
        message: '选择文件夹失败',
        duration: 2000
      });
    }
  }

  /**
   * 开始扫描
   */
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
          console.info('[FolderScannerPage] 扫描开始');
        },
        onScanProgress: (progress: ScanProgress) => {
          this.scanProgress = progress.percentage;
          this.scannedFilesCount = progress.foundDocs;
        },
        onScanComplete: (docs: ScannedDocument[]) => {
          this.scannedDocs = docs;
          this.isScanning = false;

          const duration = Date.now() - startTime;

          // 保存扫描历史
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
          }

          if (docs.length > 0) {
            promptAction.showToast({
              message: '扫描完成，发现' + docs.length + '个文档',
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
            duration: 3000
          });
        }
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.isScanning = false;
      console.error('[FolderScannerPage] 扫描失败: ' + message);
      promptAction.showToast({
        message: '扫描失败，请重试',
        duration: 2000
      });
    }
  }

  /**
   * 切换文档选择
   */
  toggleDocumentSelection(filePath: string): void {
    const newSet = new Set(this.selectedDocs);
    if (newSet.has(filePath)) {
      newSet.delete(filePath);
    } else {
      newSet.add(filePath);
    }
    this.selectedDocs = newSet;
  }

  /**
   * 全选/取消全选
   */
  toggleSelectAll(): void {
    if (this.selectedDocs.size === this.scannedDocs.length) {
      this.selectedDocs = new Set();
    } else {
      const newSet = new Set<string>();
      for (let i = 0; i < this.scannedDocs.length; i++) {
        newSet.add(this.scannedDocs[i].filePath);
      }
      this.selectedDocs = newSet;
    }
  }

  /**
   * 导入选中的文档
   */
  async importSelectedDocs(): Promise<void> {
    if (this.selectedDocs.size === 0 || this.isImporting) {
      return;
    }

    this.isImporting = true;

    try {
      const docsToImport: ScannedDocument[] = [];
      for (let i = 0; i < this.scannedDocs.length; i++) {
        if (this.selectedDocs.has(this.scannedDocs[i].filePath)) {
          docsToImport.push(this.scannedDocs[i]);
        }
      }

      const result: ImportResult = await folderScanner.importDocuments(docsToImport, true);
      this.importResult = result;

      if (result.importedCount > 0) {
        promptAction.showToast({
          message: '成功导入' + result.importedCount + '个文档',
          duration: 2000
        });

        // 添加到书架
        await this.addImportedDocsToBookshelf(result);
      }

      if (result.failedCount > 0) {
        promptAction.showToast({
          message: result.failedCount + '个文档导入失败',
          duration: 2000
        });
      }

      if (result.skippedCount > 0) {
        promptAction.showToast({
          message: result.skippedCount + '个文档已存在，已跳过',
          duration: 2000
        });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[FolderScannerPage] 导入失败: ' + message);
      promptAction.showToast({
        message: '导入失败，请重试',
        duration: 2000
      });
    } finally {
      this.isImporting = false;
    }
  }

  /**
   * 获取格式名称
   */
  getFormatName(format: DocumentFormat): string {
    switch (format) {
      case DocumentFormat.PDF: return 'PDF';
      case DocumentFormat.EPUB: return 'EPUB';
      case DocumentFormat.TXT: return 'TXT';
      case DocumentFormat.MOBI: return 'MOBI';
      case DocumentFormat.DOCX: return 'DOCX';
      case DocumentFormat.DOC: return 'DOC';
      case DocumentFormat.RTF: return 'RTF';
      case DocumentFormat.HTML: return 'HTML';
      case DocumentFormat.AZW: return 'AZW';
      case DocumentFormat.AZW3: return 'AZW3';
      case DocumentFormat.DJVU: return 'DJVU';
      case DocumentFormat.CHM: return 'CHM';
      case DocumentFormat.FB2: return 'FB2';
      case DocumentFormat.ODT: return 'ODT';
      case DocumentFormat.CBR: return 'CBR';
      case DocumentFormat.CBZ: return 'CBZ';
      case DocumentFormat.UNKNOWN: return '未知';
      default: return '未知';
    }
  }

  /**
   * 格式化文件大小
   */
  formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    } else if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    } else {
      return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    }
  }

  /**
   * 获取文件夹短名称
   */
  private getShortFolderName(path: string): string {
    const pathParts = path.split('/');
    if (pathParts.length > 0) {
      return pathParts[pathParts.length - 1];
    }
    return path;
  }

  /**
   * 格式化时间（多久以前）
   */
  formatTimeAgo(milliseconds: number): string {
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return days + ' 天前';
    } else if (hours > 0) {
      return hours + ' 小时前';
    } else if (minutes > 0) {
      return minutes + ' 分钟前';
    } else {
      return '刚刚';
    }
  }

  /**
   * 将导入的文档添加到书架
   */
  private async addImportedDocsToBookshelf(result: ImportResult): Promise<void> {
    if (result.successDocs && result.successDocs.length > 0) {
      for (let i = 0; i < result.successDocs.length; i++) {
        const doc = result.successDocs[i];
        try {
          // 检查是否已存在
          const existingBooks = bookViewModel.getAllBooks();
          let exists = false;
          for (let j = 0; j < existingBooks.length; j++) {
            if (existingBooks[j].filePath === doc.filePath) {
              exists = true;
              break;
            }
          }

          if (!exists) {
            // 尝试从文档解析获取页数
            let pageCount = 100; // 默认值
            try {
              const parseResult = await enhancedParser.parseMetadata(doc.filePath);
              if (parseResult.success && parseResult.metadata && parseResult.metadata.pageCount) {
                pageCount = parseResult.metadata.pageCount;
              }
            } catch (e) {
              const message = e instanceof Error ? e.message : String(e);
              console.warn('[FolderScannerPage] 获取页数失败，使用默认值: ' + message);
            }

            // 创建书籍信息
            const bookInfo: BookInfo = {
              id: Date.now().toString(36) + Math.random().toString(36).substring(2, 11),
              title: doc.title && doc.title.length > 0 ? doc.title : doc.fileName,
              author: doc.author && doc.author.length > 0 ? doc.author : '未知作者',
              filePath: doc.filePath,
              coverPath: '',
              format: this.convertToBookFormat(doc.format),
              totalPages: pageCount,
              currentPage: 0,
              readProgress: 0,
              lastReadTime: 0,
              addTime: Date.now(),
              status: ReadStatus.UNREAD,
              isFavorite: false,
              groupIds: [],
              totalReadTime: 0,
              fileSize: doc.fileSize || 0
            };

            bookViewModel.addBook(bookInfo);
            console.info('[FolderScannerPage] 已添加到书架: ' + bookInfo.title);
          }
        } catch (error) {
          const message = error instanceof Error ? error.message : 'Unknown error';
          console.error('[FolderScannerPage] 添加书籍失败: ' + doc.title + ', ' + message);
        }
      }

      promptAction.showToast({
        message: '已添加 ' + result.successDocs.length + ' 本书到书架',
        duration: 1500
      });
    }
  }

  /**
   * 将 DocumentFormat 转换为 BookFormat
   */
  private convertToBookFormat(format: DocumentFormat): BookFormat {
    switch (format) {
      case DocumentFormat.PDF: return BookFormat.PDF;
      case DocumentFormat.EPUB: return BookFormat.EPUB;
      case DocumentFormat.MOBI: return BookFormat.MOBI;
      case DocumentFormat.TXT: return BookFormat.TXT;
      case DocumentFormat.DOCX: return BookFormat.DOCX;
      case DocumentFormat.DOC: return BookFormat.DOC;
      case DocumentFormat.RTF: return BookFormat.RTF;
      case DocumentFormat.HTML: return BookFormat.HTML;
      case DocumentFormat.ODT: return BookFormat.ODT;
      case DocumentFormat.FB2: return BookFormat.FB2;
      case DocumentFormat.AZW3: return BookFormat.AZW3;
      case DocumentFormat.CBR: return BookFormat.CBR;
      case DocumentFormat.CBZ: return BookFormat.CBZ;
      default: return BookFormat.TXT;
    }
  }

  /**
   * 检查格式是否被支持
   */
  private isFormatSupported(format: DocumentFormat): boolean {
    for (let i = 0; i < this.supportedFormats.length; i++) {
      if (this.supportedFormats[i] === format) {
        return true;
      }
    }
    return false;
  }

  /**
   * 切换格式支持状态
   */
  private toggleFormatSupport(format: DocumentFormat): void {
    if (this.isFormatSupported(format)) {
      const newFormats: DocumentFormat[] = [];
      for (let i = 0; i < this.supportedFormats.length; i++) {
        if (this.supportedFormats[i] !== format) {
          newFormats.push(this.supportedFormats[i]);
        }
      }
      this.supportedFormats = newFormats;
    } else {
      const newFormats: DocumentFormat[] = [];
      for (let i = 0; i < this.supportedFormats.length; i++) {
        newFormats.push(this.supportedFormats[i]);
      }
      newFormats.push(format);
      this.supportedFormats = newFormats;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(this.theme.textPrimary)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            try {
              router.back();
            } catch (error) {
              const msg = error instanceof Error ? error.message : String(error);
              console.error('[FolderScannerPage] back failed:', msg);
            }
          })

        Text('扫描文件夹')
          .fontSize(FontSize.H3)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)
          .margin({ left: 8 })

        // 设置按钮
        if (!this.isScanning) {
          Text('⚙️')
            .fontSize(20)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.showFormatFilter = !this.showFormatFilter;
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.theme.background)
      .shadow({
        radius: 4,
        color: this.theme.shadowDark,
        offsetX: 0,
        offsetY: 2
      })

      // 格式过滤设置
      if (this.showFormatFilter) {
        Column({ space: 12 }) {
          Text('支持的格式')
            .fontSize(FontSize.MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.textPrimary)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.ALL_FORMATS, (format: DocumentFormat) => {
              if (format !== DocumentFormat.UNKNOWN) {
                Button(this.getFormatName(format))
                  .height(32)
                  .backgroundColor(
                    this.isFormatSupported(format)
                      ? this.theme.primary
                      : this.theme.backgroundSecondary
                  )
                  .fontColor(
                    this.isFormatSupported(format)
                      ? '#FFFFFF'
                      : this.theme.textSecondary
                  )
                  .fontSize(FontSize.XS)
                  .borderRadius(16)
                  .onClick(() => this.toggleFormatSupport(format))
              }
            })
          }

          Row() {
            Text('递归扫描子文件夹')
              .fontSize(FontSize.SM)
              .fontColor(this.theme.textSecondary)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.recursiveScan })
              .onChange((isOn: boolean) => {
                this.recursiveScan = isOn;
              })
          }

          Row() {
            Text('排除隐藏文件')
              .fontSize(FontSize.SM)
              .fontColor(this.theme.textSecondary)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.excludeHidden })
              .onChange((isOn: boolean) => {
                this.excludeHidden = isOn;
              })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.theme.background)
      }

      // 扫描按钮区域
      if (!this.isScanning && this.scannedDocs.length === 0) {
        Column({ space: 20 }) {
          Text('📂')
            .fontSize(80)

          Text('扫描文件夹')
            .fontSize(FontSize.H3)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.textPrimary)

          Text('批量导入本地电子书')
            .fontSize(FontSize.MD)
            .fontColor(this.theme.textSecondary)

          Button('选择文件夹')
            .width(200)
            .height(48)
            .backgroundColor(this.theme.primary)
            .fontColor('#FFFFFF')
            .fontSize(FontSize.LG)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.XL))
            .onClick(() => this.onSelectFolder())

          // 扫描历史
          if (this.scanHistory.length > 0) {
            Column({ space: 12 }) {
              Row() {
                Text('最近扫描')
                  .fontSize(FontSize.SM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.textPrimary)

                Text('清除')
                  .fontSize(FontSize.XS)
                  .fontColor(this.theme.primary)
                  .onClick(() => {
                    folderScanner.clearScanHistory();
                    this.scanHistory = [];
                  })
              }
              .width('100%')

              List({ space: 8 }) {
                ForEach(this.scanHistory.slice(0, 3), (history: ScanHistory, index: number) => {
                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text(this.getShortFolderName(history.path))
                          .fontSize(FontSize.SM)
                          .fontColor(this.theme.textPrimary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })

                        Text(history.foundCount + ' 个文档 · ' + this.formatTimeAgo(Date.now() - history.scanTime))
                          .fontSize(FontSize.XS)
                          .fontColor(this.theme.textTertiary)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      Button('重新扫描')
                        .height(28)
                        .fontSize(FontSize.XS)
                        .backgroundColor(this.theme.primary + '20')
                        .fontColor(this.theme.primary)
                        .onClick(() => {
                          this.currentFolder = history.path;
                          this.recursiveScan = history.recursive;
                          this.startScan();
                        })
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(this.theme.background)
                    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
                  }
                })
              }
              .width('100%')
            }
            .width('80%')
            .padding(16)
            .backgroundColor(this.theme.background)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.LG))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        // 扫描进度或结果
        if (this.isScanning) {
          // 扫描进度
          Column({ space: 20 }) {
            Text('🔍')
              .fontSize(60)

            Text('正在扫描...')
              .fontSize(FontSize.H4)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.textPrimary)

            Progress({ value: this.scanProgress, total: 100, type: ProgressType.Linear })
              .width('80%')
              .height(8)
              .color(this.theme.primary)
              .backgroundColor(this.theme.backgroundSecondary)

            Text(this.scanProgress + '%')
              .fontSize(FontSize.LG)
              .fontColor(this.theme.primary)

            Text('已发现 ' + this.scannedDocs.length + ' 个文档')
              .fontSize(FontSize.SM)
              .fontColor(this.theme.textSecondary)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          // 扫描结果
          Column() {
            // 操作栏
            Row() {
              Text('发现 ' + this.scannedDocs.length + ' 个文档')
                .fontSize(FontSize.MD)
                .fontColor(this.theme.textPrimary)
                .layoutWeight(1)

              Button(this.selectedDocs.size === this.scannedDocs.length ? '取消全选' : '全选')
                .height(32)
                .backgroundColor('transparent')
                .fontColor(this.theme.primary)
                .fontSize(FontSize.SM)
                .onClick(() => this.toggleSelectAll())

              Button('导入 (' + this.selectedDocs.size + ')')
                .height(36)
                .backgroundColor(this.theme.primary)
                .fontColor('#FFFFFF')
                .fontSize(FontSize.SM)
                .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
                .margin({ left: 8 })
                .enabled(this.selectedDocs.size > 0 && !this.isImporting)
                .onClick(() => this.importSelectedDocs())
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.theme.background)

            // 文档列表
            if (this.scannedDocs.length > 0) {
              List({ space: 8 }) {
                ForEach(this.scannedDocs, (doc: ScannedDocument) => {
                  ListItem() {
                    Row() {
                      // 选择框
                      Checkbox()
                        .select(this.selectedDocs.has(doc.filePath))
                        .selectedColor(this.theme.primary)
                        .scale({ x: 0.9, y: 0.9 })
                        .onChange((value: boolean) => {
                          this.toggleDocumentSelection(doc.filePath);
                        })

                      // 文件信息
                      Column({ space: 4 }) {
                        Row({ space: 8 }) {
                          Text(this.getFormatName(doc.format))
                            .fontSize(FontSize.XS)
                            .fontColor(this.theme.primary)
                            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                            .backgroundColor(this.theme.primary + '20')
                            .borderRadius(4)

                          Text(doc.fileName)
                            .fontSize(FontSize.MD)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(this.theme.textPrimary)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }

                        Text(this.formatFileSize(doc.fileSize))
                          .fontSize(FontSize.XS)
                          .fontColor(this.theme.textTertiary)
                      }
                      .margin({ left: 8 })
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      // 状态图标
                      if (doc.isImported) {
                        Text('✓')
                          .fontSize(18)
                      }
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(this.theme.background)
                    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
                    .border({
                      width: 1,
                      color: this.selectedDocs.has(doc.filePath)
                        ? this.theme.primary
                        : this.theme.borderLight
                    })
                  }
                })
              }
              .layoutWeight(1)
              .width('100%')
              .padding({ left: 16, right: 16 })
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
      }

      // 导入结果提示
      if (this.importResult) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('✓')
              .fontSize(20)

            Text('成功导入 ' + this.importResult.importedCount + ' 个文档')
              .fontSize(FontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.success)
          }

          if (this.importResult.failedCount > 0) {
            Row({ space: 8 }) {
              Text('❌')
                .fontSize(20)

              Text(this.importResult.failedCount + ' 个文档导入失败')
                .fontSize(FontSize.SM)
                .fontColor(this.theme.error)
            }
          }

          if (this.importResult.skippedCount > 0) {
            Text(this.importResult.skippedCount + ' 个文档已存在，已跳过')
              .fontSize(FontSize.XS)
              .fontColor(this.theme.textTertiary)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.theme.background)
        .border({ width: 1, color: this.theme.success + '40' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.backgroundSecondary)
  }
}

export default FolderScannerPage;
