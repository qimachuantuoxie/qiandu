import { logger } from '../../common/utils/Logger';
import { navigateTo } from '../../../common/utils/NavigationHelper';

import { ReadRecord, formatTime, formatDuration } from '../core/models/CoreBookModel';
import { bookViewModel } from '../core/viewmodels/BookViewModel';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { BackButton } from '../components/common/BackButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

enum TabType {
  ALL,
  TODAY,
  WEEK
}

@Entry
@Component
struct ReadRecordPage {
  @State currentTab: TabType = TabType.ALL;
  @State showSortPanel: boolean = false;
  @State editingRecord: ReadRecord | null = null;
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State screenInfo: ScreenInfo | null = null;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private getFilteredRecords(): ReadRecord[] {
    const records = bookViewModel.getAllReadRecords();
    if (this.currentTab === TabType.TODAY) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayTime = today.getTime();
      return records.filter((r: ReadRecord) => r.endTime >= todayTime);
    } else if (this.currentTab === TabType.WEEK) {
      const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      return records.filter((r: ReadRecord) => r.endTime >= weekAgo);
    }
    return records;
  }

  private getTotalReadBooks(): number {
    const bookIds: string[] = [];
    const records = bookViewModel.getAllReadRecords();
    for (let i = 0; i < records.length; i++) {
      let exists = false;
      for (let j = 0; j < bookIds.length; j++) {
        if (bookIds[j] === records[i].bookId) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        bookIds.push(records[i].bookId);
      }
    }
    return bookIds.length;
  }

  private onRecordClick(record: ReadRecord): void {
    try {
      navigateTo.push('EnhancedReaderPage', { bookId: record.bookId, page: record.endPage });
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      logger.error('[ReadRecordPage] navigate failed:', msg);
    }
  }

  private onDeleteRecord(recordId: string): void {
    bookViewModel.deleteReadRecord(recordId);
  }

  @Builder
  StatCard(title: string, value: string, icon: string, color: string) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(this.isTablet ? 28 : 24)
      Text(value)
        .fontSize(this.isTablet ? 24 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(title)
        .fontSize(this.isTablet ? 14 : 12)
        .fontColor(this.tc('#999999', '#888888'))
    }
    .width('30%')
    .padding(this.isTablet ? 24 : 16)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
  }

  @Builder
  TabButton(label: string, type: TabType) {
    Button(label)
      .width(80)
      .height(32)
      .fontSize(13)
      .backgroundColor(this.currentTab === type ? this.currentColors.primary : '#F5F5F5')
      .fontColor(this.currentTab === type ? '#FFFFFF' : '#666666')
      .borderRadius(16)
      .onClick(() => { this.currentTab = type; })
  }

  @Builder
  RecordItem(record: ReadRecord) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(record.bookTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(`${record.startPage}-${record.endPage}页`)
            .fontSize(12)
            .fontColor(this.tc('#666666', '#AAAAAA'))
          Text('|')
            .fontSize(12)
            .fontColor(this.tc('#999999', '#888888'))
          Text(formatDuration(record.duration))
            .fontSize(12)
            .fontColor(this.currentColors.primary)
        }
        Text(formatTime(record.endTime))
          .fontSize(11)
          .fontColor(this.tc('#999999', '#888888'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Button() {
        Text('×')
          .fontSize(14)
          .fontColor(this.tc('#999999', '#888888'))
      }
      .width(32)
      .height(32)
      .backgroundColor('rgba(255,255,255,0.5)')
      .borderRadius(16)
      .onClick(() => { this.onDeleteRecord(record.id); })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(8)
    .onClick(() => { this.onRecordClick(record); })
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Image($r('sys.symbol.book'))
        .width(64)
        .height(64)
        .fillColor(this.tc('#CCCCCC', '#666666'))
      Text('暂无阅读记录')
        .fontSize(16)
        .fontColor(this.tc('#999999', '#888888'))
      Text('开始阅读书籍，记录会在这里显示')
        .fontSize(14)
        .fontColor(this.tc('#BBBBBB', '#666666'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        BackButton({ isDarkMode: this.isDarkMode })

        Text('阅读记录')
          .fontSize(this.isTablet ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('阅读记录')
          .fontSize(this.isTablet ? 22 : 18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#333333', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button() {
          Text('')
            .fontSize(20)
        }
        .width(40)
        .height(40)
      }
      .width('100%')
      .height(this.isTablet ? 64 : 56)
      .padding({ left: this.isTablet ? 24 : 8, right: this.isTablet ? 24 : 8 })
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))

      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 12 }) {
            this.StatCard('今日阅读', formatDuration(bookViewModel.getTodayReadDuration()), '�?, this.currentColors.primary)
            this.StatCard('累计阅读', formatDuration(bookViewModel.getTotalReadDuration()), '📚', '#4CAF50')
            this.StatCard('阅读书籍', this.getTotalReadBooks().toString(), '📕', '#FF9800')
          }
          .width('100%')
          .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16, top: this.isTablet ? 24 : 16 })
          .justifyContent(FlexAlign.SpaceBetween)

          Row({ space: 12 }) {
            this.TabButton('全部', TabType.ALL)
            this.TabButton('今日', TabType.TODAY)
            this.TabButton('本周', TabType.WEEK)
          }
          .width('100%')
          .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16 })
          .justifyContent(FlexAlign.Start)

          Column({ space: 8 }) {
            Text(`�?${this.getFilteredRecords().length} 条记录`)
              .fontSize(this.isTablet ? 14 : 12)
              .fontColor(this.tc('#999999', '#888888'))
              .width('100%')
              .padding({ left: 4, bottom: 8 })
            if (this.getFilteredRecords().length === 0) {
              this.EmptyView()
            } else {
              ForEach(this.getFilteredRecords(), (record: ReadRecord) => {
                this.RecordItem(record)
              }, (record: ReadRecord) => record.id)
            }
          }
          .width('100%')
          .padding(this.isTablet ? 24 : 16)
          .layoutWeight(1)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor(this.bg('#F5F5F5', '#141414'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F5F5F5', '#141414'))
  }
}

// 预览组件 - 用于DevEco Studio预览�?
@Preview
@Component
struct ReadRecordPagePreview {
  build() {
    Column() {
      Text('阅读记录�?- 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      ReadRecordPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读记录�?- 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ReadRecordPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}