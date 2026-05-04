import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
/**
 * 鏂囦欢澶规壂鎻忛〉锟?- v5.2
 * Folder Scanner Page - Scan and Import Documents from Folders
 */

import folderScanner, { ScannedDocument, ScanConfig, ScanProgress, ImportResult, ScanHistory } from '../core/services/book/FolderScannerService';
import { enhancedParser } from '../core/services/reader/EnhancedDocumentParser';
import { DocumentFormat } from '../core/services/models/DocumentModels';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { uiDesignKit, LIGHT_THEME, ThemeColors, FontSize, SpacingSize, BorderRadius } from '../core/services/reader/UIDesignKitService';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BookFormat, ReadStatus, BookInfo } from '../core/models/BookModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';

import { BackButton } from '../components/common/BackButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';
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
  @State screenInfo: ScreenInfo | null = null;

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
   * 椤甸潰鍒濆�锟?
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
    await layoutHelper.init(this.context);
    this.screenInfo = layoutHelper.getScreenInfo();
    await fontScaleManager.init(this.context);
    this.fontScale = await fontScaleManager.getFontScale();
    await folderScanner.init(this.context);

    // 鍔犺浇鎵�弿鍘嗗彶
    this.scanHistory = folderScanner.getScanHistory();
  }

  /**
   * 鏍规嵁涓婚�鑾峰彇棰滆壊
   */
  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鏍规嵁涓婚�鑾峰彇鑳屾櫙锟?
   */
  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 閫夋嫨鏂囦欢锟?
   */
  async onSelectFolder(): Promise<void> {
    try {
      const folderPath: string = (await folderScanner.selectFolder()) ? (await folderScanner.selectFolder()) : '';

      if (folderPath && folderPath.length > 0) {
        this.currentFolder = folderPath;
        this.scannedDocs = [];
        this.selectedDocs = new Set();
        this.importResult = null;

        // 鎺堟潈璁块棶
        await folderScanner.authorizeFolderAccess(folderPath);

        // 寮€濮嬫壂锟?
        await this.startScan();
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[FolderScannerPage] 閫夋嫨鏂囦欢澶瑰け锟? ' + message);
      promptAction.showToast({
        message: '閫夋嫨鏂囦欢澶瑰け锟?,
        duration: 2000
      });
    }
  }

  /**
   * 寮€濮嬫壂锟?
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
          logger.info('[FolderScannerPage] 鎵�弿寮€锟?);
        },
        onScanProgress: (progress: ScanProgress) => {
          this.scanProgress = progress.percentage;
          this.scannedFilesCount = progress.foundDocs;
        },
        onScanComplete: (docs: ScannedDocument[]) => {
          this.scannedDocs = docs;
          this.isScanning = false;

          const duration = Date.now() - startTime;

          // 淇濆瓨鎵�弿鍘嗗彶
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
              message: '鎵�弿瀹屾垚锛屽彂锟? + docs.length + '涓�枃锟?,
              duration: 2000
            });
          } else {
            promptAction.showToast({
              message: '鏈�彂鐜版敮鎸佺殑鏂囨。鏍煎紡',
              duration: 2000
            });
          }
        },
        onScanError: (error: Error) => {
          this.isScanning = false;
          promptAction.showToast({
            message: '鎵�弿澶辫触: ' + error.message,
            duration: 3000
          });
        }
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.isScanning = false;
      logger.error('[FolderScannerPage] 鎵�弿澶辫触: ' + message);
      promptAction.showToast({
        message: '鎵�弿澶辫触锛岃�閲嶈瘯',
        duration: 2000
      });
    }
  }

  /**
   * 鍒囨崲鏂囨。閫夋嫨
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
   * 鍏�拷?鍙栨秷鍏�拷?
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
   * 瀵煎叆閫変腑鐨勬枃锟?
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
          message: '鎴愬姛瀵煎叆' + result.importedCount + '涓�枃锟?,
          duration: 2000
        });

        // 娣诲姞鍒颁功锟?
        await this.addImportedDocsToBookshelf(result);
      }

      if (result.failedCount > 0) {
        promptAction.showToast({
          message: result.failedCount + '涓�枃妗ｅ�鍏ュけ锟?,
          duration: 2000
        });
      }

      if (result.skippedCount > 0) {
        promptAction.showToast({
          message: result.skippedCount + '涓�枃妗ｅ凡瀛樺湪锛屽凡璺宠繃',
          duration: 2000
        });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      logger.error('[FolderScannerPage] 瀵煎叆澶辫触: ' + message);
      promptAction.showToast({
        message: '瀵煎叆澶辫触锛岃�閲嶈瘯',
        duration: 2000
      });
    } finally {
      this.isImporting = false;
    }
  }

  /**
   * 鑾峰彇鏍煎紡鍚嶇О
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
      case DocumentFormat.UNKNOWN: return '鏈�煡';
      default: return '鏈�煡';
    }
  }

  /**
   * 鏍煎紡鍖栨枃浠跺ぇ锟?
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
   * 鑾峰彇鏂囦欢澶圭煭鍚嶇О
   */
  private getShortFolderName(path: string): string {
    const pathParts = path.split('/');
    if (pathParts.length > 0) {
      return pathParts[pathParts.length - 1];
    }
    return path;
  }

  /**
   * 鏍煎紡鍖栨椂闂达紙澶氫箙浠ュ墠锟?
   */
  formatTimeAgo(milliseconds: number): string {
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) {
      return days + ' 澶╁墠';
    } else if (hours > 0) {
      return hours + ' 灏忔椂锟?;
    } else if (minutes > 0) {
      return minutes + ' 鍒嗛挓锟?;
    } else {
      return '鍒氬垰';
    }
  }

  /**
   * 灏嗗�鍏ョ殑鏂囨。娣诲姞鍒颁功锟?
   */
  private async addImportedDocsToBookshelf(result: ImportResult): Promise<void> {
    if (result.successDocs && result.successDocs.length > 0) {
      for (let i = 0; i < result.successDocs.length; i++) {
        const doc = result.successDocs[i];
        try {
          // 妫€鏌ユ槸鍚﹀凡瀛樺湪
          const existingBooks = bookViewModel.getAllBooks();
          let exists = false;
          for (let j = 0; j < existingBooks.length; j++) {
            if (existingBooks[j].filePath === doc.filePath) {
              exists = true;
              break;
            }
          }

          if (!exists) {
            // 灏濊瘯浠庢枃妗ｈВ鏋愯幏鍙栭〉锟?
            let pageCount = 100; // 榛樿�锟?
            try {
              const parseResult = await enhancedParser.parseMetadata(doc.filePath);
              if (parseResult.success && parseResult.metadata && parseResult.metadata.pageCount) {
                pageCount = parseResult.metadata.pageCount;
              }
            } catch (e) {
              const message = e instanceof Error ? e.message : String(e);
              logger.warn('[FolderScannerPage] 鑾峰彇椤垫暟澶辫触锛屼娇鐢ㄩ粯璁わ拷? ' + message);
            }

            // 鍒涘缓涔︾睄淇℃伅
            const bookInfo: BookInfo = {
              id: Date.now().toString(36) + Math.random().toString(36).substring(2, 11),
              title: doc.title && doc.title.length > 0 ? doc.title : doc.fileName,
              author: doc.author && doc.author.length > 0 ? doc.author : '鏈�煡浣滐拷?,
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
            logger.info('[FolderScannerPage] 宸叉坊鍔犲埌涔︽灦: ' + bookInfo.title);
          }
        } catch (error) {
          const message = error instanceof Error ? error.message : 'Unknown error';
          logger.error('[FolderScannerPage] 娣诲姞涔︾睄澶辫触: ' + doc.title + ', ' + message);
        }
      }

      promptAction.showToast({
        message: '宸叉坊锟?' + result.successDocs.length + ' 鏈�功鍒颁功锟?,
        duration: 1500
      });
    }
  }

  /**
   * 锟?DocumentFormat 杞�崲锟?BookFormat
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
   * 妫€鏌ユ牸寮忔槸鍚﹁�鏀�寔
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
   * 鍒囨崲鏍煎紡鏀�寔鐘讹拷?
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

  /**
   * 鍏ㄩ€夋墍鏈夋牸锟?
   */
  private selectAllFormats(): void {
    const allFormats: DocumentFormat[] = [];
    for (let i = 0; i < this.ALL_FORMATS.length; i++) {
      if (this.ALL_FORMATS[i] !== DocumentFormat.UNKNOWN) {
        allFormats.push(this.ALL_FORMATS[i]);
      }
    }
    this.supportedFormats = allFormats;
  }

  /**
   * 娓呴櫎鎵€鏈夋牸锟?
   */
  private clearAllFormats(): void {
    this.supportedFormats = [];
  }

  build() {
    Column() {
      // 椤堕儴瀵艰埅锟?
      Row() {
        BackButton({ isDarkMode: this.isDarkMode, colors: this.theme.textPrimary })

        Text(this.tr('folder_scanner_title') || '鏂囦欢澶规壂锟?)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)

        Text('鎵�弿鏂囦欢锟?)
          .fontSize(FontSize.H3)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.textPrimary)
          .layoutWeight(1)
          .margin({ left: 8 })

        // 璁剧疆鎸夐挳
        if (!this.isScanning) {
          Text('gearshape')
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

      // 鏍煎紡杩囨护璁剧疆
      if (this.showFormatFilter) {
        Column({ space: 12 }) {
          Row() {
            Text('鏀�寔鐨勬牸锟?)
              .fontSize(FontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.textPrimary)
              .layoutWeight(1)

            Button('鍏ㄩ儴閫夋嫨')
              .height(28)
              .fontSize(FontSize.XS)
              .backgroundColor(this.theme.primary + '20')
              .fontColor(this.theme.primary)
              .onClick(() => this.selectAllFormats())

            Button('娓呴櫎')
              .height(28)
              .fontSize(FontSize.XS)
              .backgroundColor(this.theme.backgroundSecondary)
              .fontColor(this.theme.textSecondary)
              .margin({ left: 8 })
              .onClick(() => this.clearAllFormats())
          }
          .width('100%')

          // 鏍煎紡鎸夐挳缃戞牸 - 姣忚�4锟?
          Grid() {
            ForEach(this.ALL_FORMATS, (format: DocumentFormat) => {
              if (format !== DocumentFormat.UNKNOWN) {
                GridItem() {
                  Button(this.getFormatName(format))
                    .width('100%')
                    .height(36)
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
                    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.SM))
                    .onClick(() => this.toggleFormatSupport(format))
                }
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(8)
          .columnsGap(8)
          .width('100%')
          .height('auto')

          Divider()
            .color(this.theme.border)
            .strokeWidth(1)

          Row() {
            Text('閫掑綊鎵�弿瀛愭枃浠跺す')
              .fontSize(FontSize.SM)
              .fontColor(this.theme.textSecondary)
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.recursiveScan })
              .onChange((isOn: boolean) => {
                this.recursiveScan = isOn;
              })
          }

          Row() {
            Text('鎺掗櫎闅愯棌鏂囦欢')
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
        .padding(Spacing.lg)
        .backgroundColor(this.theme.background)
      }

      // 鎵�弿鎸夐挳鍖哄煙
      if (!this.isScanning && this.scannedDocs.length === 0) {
        Column({ space: 20 }) {
          Text('folder')
            .fontSize(80)

          Text('鎵�弿鏂囦欢锟?)
            .fontSize(FontSize.H3)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.textPrimary)

          Text('鎵归噺瀵煎叆鏈�湴鐢靛瓙锟?)
            .fontSize(FontSize.MD)
            .fontColor(this.theme.textSecondary)

          Button('閫夋嫨鏂囦欢锟?)
            .width(200)
            .height(48)
            .backgroundColor(this.theme.primary)
            .fontColor('#FFFFFF')
            .fontSize(FontSize.LG)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.XL))
            .onClick(() => this.onSelectFolder())

          // 鎵�弿鍘嗗彶
          if (this.scanHistory.length > 0) {
            Column({ space: 12 }) {
              Row() {
                Text('鏈€杩戞壂锟?)
                  .fontSize(FontSize.SM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.theme.textPrimary)

                Text('娓呴櫎')
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

                        Text(history.foundCount + ' 涓�枃锟?路 ' + this.formatTimeAgo(Date.now() - history.scanTime))
                          .fontSize(FontSize.XS)
                          .fontColor(this.theme.textTertiary)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      Button('閲嶆柊鎵�弿')
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
                    .padding(Spacing.md)
                    .backgroundColor(this.theme.background)
                    .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.MD))
                  }
                })
              }
              .width('100%')
            }
            .width('80%')
            .padding(Spacing.lg)
            .backgroundColor(this.theme.background)
            .borderRadius(uiDesignKit.getBorderRadius(BorderRadius.LG))
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        // 鎵�弿杩涘害鎴栫粨锟?
        if (this.isScanning) {
          // 鎵�弿杩涘害
          Column({ space: 20 }) {
            Text('magnifyingglass')
              .fontSize(60)

            Text('姝ｅ湪鎵�弿...')
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

            Text('宸插彂锟?' + this.scannedDocs.length + ' 涓�枃锟?)
              .fontSize(FontSize.SM)
              .fontColor(this.theme.textSecondary)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          // 鎵�弿缁撴灉
          Column() {
            // 鎿嶄綔锟?
            Row() {
              Text('鍙戠幇 ' + this.scannedDocs.length + ' 涓�枃锟?)
                .fontSize(FontSize.MD)
                .fontColor(this.theme.textPrimary)
                .layoutWeight(1)

              Button(this.selectedDocs.size === this.scannedDocs.length ? '鍙栨秷鍏�拷? : '鍏�拷?)
                .height(32)
                .backgroundColor('transparent')
                .fontColor(this.theme.primary)
                .fontSize(FontSize.SM)
                .onClick(() => this.toggleSelectAll())

              Button('瀵煎叆 (' + this.selectedDocs.size + ')')
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

            // 鏂囨。鍒楄〃
            if (this.scannedDocs.length > 0) {
              List({ space: 8 }) {
                ForEach(this.scannedDocs, (doc: ScannedDocument) => {
                  ListItem() {
                    Row() {
                      // 閫夋嫨锟?
                      Checkbox()
                        .select(this.selectedDocs.has(doc.filePath))
                        .selectedColor(this.theme.primary)
                        .scale({ x: 0.9, y: 0.9 })
                        .onChange((value: boolean) => {
                          this.toggleDocumentSelection(doc.filePath);
                        })

                      // 鏂囦欢淇℃伅
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

                      // 鐘舵€佸浘锟?
                      if (doc.isImported) {
                        Text('锟?)
                          .fontSize(18)
                      }
                    }
                    .width('100%')
                    .padding(Spacing.md)
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

      // 瀵煎叆缁撴灉鎻愮ず
      if (this.importResult) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('锟?)
              .fontSize(20)

            Text('鎴愬姛瀵煎叆 ' + this.importResult.importedCount + ' 涓�枃锟?)
              .fontSize(FontSize.MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.theme.success)
          }

          if (this.importResult.failedCount > 0) {
            Row({ space: 8 }) {
              Text('锟?)
                .fontSize(20)

              Text(this.importResult.failedCount + ' 涓�枃妗ｅ�鍏ュけ锟?)
                .fontSize(FontSize.SM)
                .fontColor(this.theme.error)
            }
          }

          if (this.importResult.skippedCount > 0) {
            Text(this.importResult.skippedCount + ' 涓�枃妗ｅ凡瀛樺湪锛屽凡璺宠繃')
              .fontSize(FontSize.XS)
              .fontColor(this.theme.textTertiary)
          }
        }
        .width('100%')
        .padding(Spacing.lg)
        .backgroundColor(this.theme.background)
        .border({ width: 1, color: this.theme.success + '40' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.backgroundSecondary)
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct FolderScannerPagePreview {
  build() {
    Column() {
      Text('鏂囦欢澶规壂鎻忛〉 - 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      FolderScannerPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鏂囦欢澶规壂鎻忛〉 - 娣辫壊妯″紡')
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

export default FolderScannerPage;
