/**
 * 书源备份/恢复对话框
 *
 * 功能：
 * - 备份所有书源为JSON文件
 * - 从JSON文件恢复书源
 * - 支持覆盖/追加/跳过已存在三种导入模式
 *
 * @since 2.7.0
 */

import { filePicker, fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { bookSourceViewModel, ImportResult } from '../viewmodels/BookSourceViewModel';
import { COMMON_COLORS } from '../utils/AppTheme';
import { BookSource } from '../models/BookSourceModel';
import { common } from '@kit.AbilityKit';

/**
 * 导入模式枚举
 */
export enum ImportMode {
  /** 覆盖：删除现有书源，完全替换 */
  OVERWRITE = 'overwrite',
  /** 追加：合并到现有书源，保留重复项 */
  APPEND = 'append',
  /** 跳过已存在：只导入新书源 */
  SKIP_EXISTING = 'skip_existing'
}

/**
 * 导入预览数据
 */
export interface ImportPreview {
  /** 书源总数 */
  totalCount: number;
  /** 书源名称列表 */
  sourceNames: string[];
  /** 原始JSON字符串 */
  jsonString: string;
  /** 解析后的书源数组 */
  sources: BookSource[];
}

/**
 * 导入结果统计
 */
export interface ImportStats {
  /** 成功数量 */
  success: number;
  /** 澶辫触鏁伴噺 */
  fail: number;
  /** 璺宠繃鏁伴噺 */
  skipped: number;
  /** 娑堟伅 */
  message: string;
}

/**
 * 澶囦唤鎭㈠瀵硅瘽妗嗙姸鎬?
 */
enum DialogState {
  /** 鍒濆鐘舵€?*/
  IDLE = 'idle',
  /** 澶囦唤涓?*/
  BACKING_UP = 'backing_up',
  /** 澶囦唤鎴愬姛 */
  BACKUP_SUCCESS = 'backup_success',
  /** 澶囦唤澶辫触 */
  BACKUP_FAILED = 'backup_failed',
  /** 閫夋嫨鏂囦欢鍚庨瑙?*/
  PREVIEW = 'preview',
  /** 閫夋嫨瀵煎叆妯″紡 */
  CHOOSE_MODE = 'choose_mode',
  /** 瀵煎叆涓?*/
  IMPORTING = 'importing',
  /** 瀵煎叆鎴愬姛 */
  IMPORT_SUCCESS = 'import_success',
  /** 瀵煎叆澶辫触 */
  IMPORT_FAILED = 'import_failed'
}

@CustomDialog
export struct BackupRestoreDialog {
  controller: CustomDialogController;
  @Prop dialogContext: common.Context | null = null;
  @State private dialogState: DialogState = DialogState.IDLE;
  @State private isDarkMode: boolean = false;
  // 棰勮鏁版嵁
  @State private preview: ImportPreview | null = null;
  // 瀵煎叆妯″紡
  @State private selectedMode: ImportMode = ImportMode.SKIP_EXISTING;
  // 瀵煎叆缁撴灉
  @State private importStats: ImportStats | null = null;
  // 閿欒淇℃伅
  @State private errorMessage: string = '';
  // 澶囦唤鎴愬姛娑堟伅
  @State private backupMessage: string = '';

  build() {
    Column() {
      // 鏍囬鏍?
      this.buildHeader();

      // 鍐呭鍖?
      this.buildContent();

      // 搴曢儴鎸夐挳
      this.buildFooter();
    }
    .width('90%')
    .maxHeight('80%')
    .padding(24)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(20)
  }

  /**
   * 鏋勫缓鏍囬鏍?
   */
  @Builder
  buildHeader() {
    Row() {
      Text('涔︽簮澶囦唤涓庢仮澶?)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .layoutWeight(1)

      Text('\u2715')
        .fontSize(18)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .padding(8)
        .onClick(() => this.controller.close())
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 鏋勫缓鍐呭鍖?
   */
  @Builder
  buildContent() {
    if (this.dialogState === DialogState.IDLE) {
      this.buildIdleContent();
    } else if (this.dialogState === DialogState.BACKING_UP) {
      this.buildLoadingContent('姝ｅ湪澶囦唤涔︽簮...');
    } else if (this.dialogState === DialogState.BACKUP_SUCCESS) {
      this.buildSuccessContent(this.backupMessage);
    } else if (this.dialogState === DialogState.BACKUP_FAILED) {
      this.buildFailedContent(this.errorMessage, '澶囦唤');
    } else if (this.dialogState === DialogState.PREVIEW) {
      this.buildPreviewContent();
    } else if (this.dialogState === DialogState.CHOOSE_MODE) {
      this.buildChooseModeContent();
    } else if (this.dialogState === DialogState.IMPORTING) {
      this.buildLoadingContent('姝ｅ湪瀵煎叆涔︽簮...');
    } else if (this.dialogState === DialogState.IMPORT_SUCCESS) {
      this.buildImportSuccessContent();
    } else if (this.dialogState === DialogState.IMPORT_FAILED) {
      this.buildFailedContent(this.errorMessage, '瀵煎叆');
    }
  }

  /**
   * 鍒濆鐘舵€佸唴瀹?
   */
  @Builder
  buildIdleContent() {
    Column({ space: 16 }) {
      // 缁熻淇℃伅
      Column({ space: 8 }) {
        Text('褰撳墠涔︽簮鏁伴噺')
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')

        Text(`${bookSourceViewModel.getAllSources().length} 涓猔)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(COMMON_COLORS.PRIMARY_BLUE)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,125,255,0.05)')
      .borderRadius(12)

      // 澶囦唤鎸夐挳
      Button('澶囦唤涔︽簮')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(12)
        .onClick(() => this.handleBackup())

      // 鎭㈠鎸夐挳
      Button('鎭㈠涔︽簮')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .borderRadius(12)
        .onClick(() => this.handleRestore())

      // 璇存槑鏂囧瓧
      Text('澶囦唤锛氬皢鎵€鏈変功婧愬鍑轰负JSON鏂囦欢\n鎭㈠锛氫粠JSON鏂囦欢瀵煎叆涔︽簮')
        .fontSize(12)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
  }

  /**
   * 鍔犺浇鐘舵€佸唴瀹?
   */
  @Builder
  buildLoadingContent(message: string) {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(COMMON_COLORS.PRIMARY_BLUE)

      Text(message)
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#E0E0E0' : '#1A1A1A')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 澶囦唤鎴愬姛鍐呭
   */
  @Builder
  buildSuccessContent(message: string) {
    Column({ space: 16 }) {
      Text('\u2705')
        .fontSize(48)

      Text('澶囦唤鎴愬姛')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COMMON_COLORS.SUCCESS_GREEN)

      Text(message)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 瀵煎叆鎴愬姛鍐呭
   */
  @Builder
  buildImportSuccessContent() {
    Column({ space: 12 }) {
      Text('\u2705')
        .fontSize(48)

      Text('瀵煎叆鎴愬姛')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COMMON_COLORS.SUCCESS_GREEN)

      if (this.importStats) {
        Column({ space: 6 }) {
          Text(`鎴愬姛锛?{this.importStats.success} 涓猔)
            .fontSize(14)
            .fontColor(this.isDarkMode ? '#E0E0E0' : '#1A1A1A')

          if (this.importStats.fail > 0) {
            Text(`澶辫触锛?{this.importStats.fail} 涓猔)
              .fontSize(14)
              .fontColor(COMMON_COLORS.ERROR_RED)
          }

          if (this.importStats.skipped > 0) {
            Text(`璺宠繃锛?{this.importStats.skipped} 涓猔)
              .fontSize(14)
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
          }

          if (this.importStats.message) {
            Text(this.importStats.message)
              .fontSize(12)
              .fontColor(this.isDarkMode ? '#888888' : '#999999')
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
        .borderRadius(8)
      }
    }
    .width('100%')
  }

  /**
   * 澶辫触鍐呭
   */
  @Builder
  buildFailedContent(message: string, action: string) {
    Column({ space: 16 }) {
      Text('\u274C')
        .fontSize(48)

      Text(action + '澶辫触')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COMMON_COLORS.ERROR_RED)

      Text(message)
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 棰勮鍐呭
   */
  @Builder
  buildPreviewContent() {
    if (this.preview) {
      Column({ space: 12 }) {
        // 鏍囬
        Text('瀵煎叆棰勮')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .width('100%')

        // 缁熻淇℃伅
        Row() {
          Text('涔︽簮鏁伴噺')
            .fontSize(14)
            .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')

          Text(`${this.preview.totalCount} 涓猔)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 涔︽簮鍚嶇О鍒楄〃
        Text('涔︽簮鍒楄〃')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#E0E0E0' : '#1A1A1A')
          .margin({ top: 8 })
          .width('100%')

        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.preview.sourceNames, (name: string, index: number) => {
              Row() {
                Text((index + 1) + '. ')
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#888888' : '#999999')
                  .width(30)

                Text(name)
                  .fontSize(13)
                  .fontColor(this.isDarkMode ? '#E0E0E0' : '#1A1A1A')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ left: 4, top: 4, bottom: 4 })
            })
          }
          .width('100%')
        }
        .height(200)
        .width('100%')
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
        .borderRadius(8)
        .padding(8)
      }
      .width('100%')
    }
  }

  /**
   * 閫夋嫨瀵煎叆妯″紡鍐呭
   */
  @Builder
  buildChooseModeContent() {
    Column({ space: 12 }) {
      Text('閫夋嫨瀵煎叆妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .width('100%')

      // 瑕嗙洊妯″紡
      this.buildModeOption(
        ImportMode.OVERWRITE,
        '\u26A0\uFE0F 瑕嗙洊',
        '鍒犻櫎鐜版湁鎵€鏈変功婧愶紝瀹屽叏鏇挎崲涓哄鍏ョ殑涔︽簮'
      );

      // 杩藉姞妯″紡
      this.buildModeOption(
        ImportMode.APPEND,
        '\u2795 杩藉姞',
        '灏嗗鍏ョ殑涔︽簮鍚堝苟鍒扮幇鏈変功婧愪腑锛屼繚鐣欓噸澶嶉」'
      );

      // 璺宠繃宸插瓨鍦ㄦā寮?
      this.buildModeOption(
        ImportMode.SKIP_EXISTING,
        '\u23ED\uFE0F 璺宠繃宸插瓨鍦?(鎺ㄨ崘)',
        '鍙鍏ヤ笉瀛樺湪鐨勬柊涔︽簮锛岃烦杩囬噸澶嶉」'
      );

      // 纭鎸夐挳
      Button('纭瀵煎叆')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(12)
        .margin({ top: 12 })
        .onClick(() => this.executeImport())
    }
    .width('100%')
  }

  /**
   * 鏋勫缓瀵煎叆妯″紡閫夐」
   */
  @Builder
  buildModeOption(mode: ImportMode, title: string, description: string) {
    Row({ space: 12 }) {
      // 閫夋嫨鎸囩ず鍣?
      Row() {
        if (this.selectedMode === mode) {
          Circle({ width: 10, height: 10 })
            .fill(COMMON_COLORS.PRIMARY_BLUE)
        } else {
          Circle({ width: 10, height: 10 })
            .fill(this.isDarkMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.1)')
        }
      }
      .width(20)
      .height(20)
      .justifyContent(FlexAlign.Center)

      // 鏂囧瓧
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

        Text(description)
          .fontSize(12)
          .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selectedMode === mode
      ? (this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.08)')
      : (this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)'))
    .borderRadius(12)
    .border({
      width: 1,
      color: this.selectedMode === mode
        ? COMMON_COLORS.PRIMARY_BLUE
        : (this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
    })
    .onClick(() => {
      this.selectedMode = mode;
    })
  }

  /**
   * 鏋勫缓搴曢儴鎸夐挳
   */
  @Builder
  buildFooter() {
    if (this.dialogState === DialogState.IDLE) {
      // 鍒濆鐘舵€佹棤搴曢儴鎸夐挳
    } else if (this.dialogState === DialogState.BACKUP_SUCCESS ||
               this.dialogState === DialogState.BACKUP_FAILED) {
      Button('杩斿洖')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .borderRadius(12)
        .margin({ top: 20 })
        .onClick(() => {
          this.dialogState = DialogState.IDLE;
          this.backupMessage = '';
          this.errorMessage = '';
        })
    } else if (this.dialogState === DialogState.PREVIEW) {
      Row({ space: 12 }) {
        Button('鍙栨秷')
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(12)
          .onClick(() => {
            this.dialogState = DialogState.IDLE;
            this.preview = null;
          })

        Button('涓嬩竴姝?)
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
          .borderRadius(12)
          .onClick(() => {
            this.dialogState = DialogState.CHOOSE_MODE;
          })
      }
      .width('100%')
      .margin({ top: 16 })
    } else if (this.dialogState === DialogState.CHOOSE_MODE) {
      Row({ space: 12 }) {
        Button('杩斿洖')
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
          .borderRadius(12)
          .onClick(() => {
            this.dialogState = DialogState.PREVIEW;
          })
      }
      .width('100%')
      .margin({ top: 16 })
    } else if (this.dialogState === DialogState.IMPORT_SUCCESS ||
               this.dialogState === DialogState.IMPORT_FAILED) {
      Button('瀹屾垚')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .borderRadius(12)
        .margin({ top: 20 })
        .onClick(() => {
          this.controller.close();
        })
    }
  }

  /**
   * 澶勭悊澶囦唤鎿嶄綔
   */
  private async handleBackup(): Promise<void> {
    try {
      this.dialogState = DialogState.BACKING_UP;

      // 瀵煎嚭涔︽簮涓篔SON
      const jsonString = bookSourceViewModel.exportSourcesToJson();
      const sources = bookSourceViewModel.getAllSources();
      const timestamp = this.formatTimestamp(new Date());
      const fileName = 'booksource_backup_' + timestamp + '.json';

      // 浣跨敤鏂囦欢閫夋嫨鍣ㄤ繚瀛?
      const saveDialog = new filePicker.SaveDialogOptions();
      saveDialog.title = '淇濆瓨涔︽簮澶囦唤';
      saveDialog.defaultName = fileName;

      const saveResult = await filePicker.saveDialog(saveDialog);

      if (saveResult && saveResult.uri) {
        const context = this.getUIContext().getHostContext() as common.Context;
        const fs = fileIo.openSync(saveResult.uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        fileIo.writeSync(fs, new Uint8Array(new TextEncoder().encode(jsonString)));
        fileIo.closeSync(fs);

        this.backupMessage = '已备份' + sources.length + ' 个书源到 ' + fileName;
        this.dialogState = DialogState.BACKUP_SUCCESS;
      } else {
        this.errorMessage = '用户取消了备份操作';
        this.dialogState = DialogState.BACKUP_FAILED;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error('[BackupRestoreDialog] 备份失败:', message);
      this.dialogState = DialogState.BACKUP_FAILED;
    }
  }

  /**
   * 澶勭悊鎭㈠鎿嶄綔
   */
  private async handleRestore(): Promise<void> {
    try {
      // 鎵撳紑鏂囦欢閫夋嫨鍣?
      const selectOptions = new filePicker.DocumentSelectOptions();
      selectOptions.type = filePicker.DocumentType.DOCUMENT;

      const result = await filePicker.selectDocument(selectOptions);

if (result && result.uri) {
        // 读取文件内容
        const context = this.getUIContext().getHostContext() as common.Context;
        const fs = fileIo.openSync(result.uri, fileIo.OpenMode.READ_ONLY);
        const stat = fileIo.statSync(result.uri);
        const buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(fs, buffer);
        fileIo.closeSync(fs);

        const jsonString = new TextDecoder('utf-8').decode(buffer);
        this.parseAndPreview(jsonString);
      }
    } catch (error) {
      console.error('[BackupRestoreDialog] 鎭㈠澶辫触:', error);
      this.errorMessage = this.getErrorMessage(error);
      this.dialogState = DialogState.IMPORT_FAILED;
    }
  }

  /**
   * 瑙ｆ瀽骞堕瑙堜功婧?
   */
  private parseAndPreview(jsonString: string): void {
    try {
      const trimmed = jsonString.trim();
      let sources: BookSource[] = [];

      if (trimmed.startsWith('[')) {
        sources = JSON.parse(trimmed) as BookSource[];
      } else if (trimmed.startsWith('{')) {
        const single = JSON.parse(trimmed) as BookSource;
        sources = [single];
      } else {
        this.errorMessage = '鏃犳晥鐨凧SON鏍煎紡';
        this.dialogState = DialogState.IMPORT_FAILED;
        return;
      }

      if (sources.length === 0) {
        this.errorMessage = '鏂囦欢涓病鏈変功婧愭暟鎹?;
        this.dialogState = DialogState.IMPORT_FAILED;
        return;
      }

      const sourceNames = sources.map(s => s.name);

      this.preview = {
        totalCount: sources.length,
        sourceNames: sourceNames,
        jsonString: jsonString,
        sources: sources
      };

      this.dialogState = DialogState.PREVIEW;
    } catch (error) {
      console.error('[BackupRestoreDialog] 瑙ｆ瀽澶辫触:', error);
      this.errorMessage = 'JSON瑙ｆ瀽澶辫触锛屾枃浠舵牸寮忎笉姝ｇ‘';
      this.dialogState = DialogState.IMPORT_FAILED;
    }
  }

  /**
   * 鎵ц瀵煎叆
   */
  private async executeImport(): Promise<void> {
    if (!this.preview) {
      this.errorMessage = '棰勮鏁版嵁涓虹┖';
      this.dialogState = DialogState.IMPORT_FAILED;
      return;
    }

    try {
      this.dialogState = DialogState.IMPORTING;

      let successCount = 0;
      let failCount = 0;
      let skippedCount = 0;

      if (this.selectedMode === ImportMode.OVERWRITE) {
        // 瑕嗙洊妯″紡锛氬垹闄ゆ墍鏈夌幇鏈変功婧?
        const allSources = bookSourceViewModel.getAllSources();
        for (const source of allSources) {
          bookSourceViewModel.deleteSource(source.id);
        }

        // 瀵煎叆鏂版暟鎹?
        const result = bookSourceViewModel.importFromJson(this.preview.jsonString);
        successCount = result.success;
        failCount = result.fail;

      } else if (this.selectedMode === ImportMode.APPEND) {
        // 杩藉姞妯″紡锛氱洿鎺ュ鍏?
        const result = bookSourceViewModel.importFromJson(this.preview.jsonString);
        successCount = result.success;
        failCount = result.fail;

      } else if (this.selectedMode === ImportMode.SKIP_EXISTING) {
        // 璺宠繃宸插瓨鍦ㄦā寮?
        const allSources = bookSourceViewModel.getAllSources();
        const existingUrls = new Set(allSources.map(s => s.url));

        for (const source of this.preview.sources) {
          if (existingUrls.has(source.url)) {
            skippedCount++;
          } else {
            if (bookSourceViewModel.importSources([source])) {
              successCount++;
            } else {
              failCount++;
            }
          }
        }
      }

      this.importStats = {
        success: successCount,
        fail: failCount,
        skipped: skippedCount,
        message: `鍏?${this.preview.totalCount} 涓功婧恅
      };

      this.dialogState = DialogState.IMPORT_SUCCESS;
    } catch (error) {
      console.error('[BackupRestoreDialog] 瀵煎叆澶辫触:', error);
      this.errorMessage = this.getErrorMessage(error);
      this.dialogState = DialogState.IMPORT_FAILED;
    }
  }

  /**
   * 鏍煎紡鍖栨椂闂存埑
   */
  private formatTimestamp(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return year + month + day + '_' + hours + minutes + seconds;
  }

  /**
   * 鑾峰彇鍙嬪ソ鐨勯敊璇俊鎭?
   */
  private getErrorMessage(error: Error): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    return '鏈煡閿欒锛岃閲嶈瘯';
  }
}
