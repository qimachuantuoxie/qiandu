// 首页组件 - 展示阅读进度、快捷入口、最近添加
import { navigateTo } from '../../../common/utils/NavigationHelper';
import { BookInfo } from '../../../core/models/CoreBookModel';
import { PageHeader, EmptyState, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { themeManager } from '../../../common/constants/AppTheme';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';

interface ShortcutItem {
  symbol: string;
  title: string;
  color: string;
  url: string;
}

@ComponentV2
export struct HomeContent {
  @Prop recentBooks: BookInfo[] = [];
  @Local isDarkMode: boolean = themeManager.isDarkMode();
  onBookClick?: (book: BookInfo) => void;
  onOpenFilePicker?: () => void;

  private readonly shortcuts: ShortcutItem[] = [
    { symbol: 'chart.bar.fill', title: '阅读统计', color: HDSColours.primary.blue, url: 'features/StatisticsPage' },
    { symbol: 'checkmark.circle.fill', title: '待办事项', color: '#FF6B6B', url: 'features/TodoPage' },
    { symbol: 'clock.fill', title: '阅读记录', color: '#52C41A', url: 'features/ReadRecordPage' },
    { symbol: 'bookmark.fill', title: '书签', color: '#FA8C16', url: 'features/BookmarksPage' },
    { symbol: 'note.text', title: '笔记', color: '#722ED1', url: 'features/NotesPage' },
    { symbol: 'globe.asia.australia.fill', title: '在线书源', color: '#13C2C2', url: 'features/OnlineSourceMarketPage' },
    { symbol: 'gearshape.fill', title: '阅读设置', color: '#EB2F96', url: 'features/SettingsPage' }
  ];

  private getFormatSymbol(format: string): Resource {
    const formatSymbols: Record<string, Resource> = {
      'PDF': $r('sys.symbol.doc.plaintext'),
      'EPUB': $r('sys.symbol.book'),
      'MOBI': $r('sys.symbol.ipad'),
      'TXT': $r('sys.symbol.pencil'),
      'DOCX': $r('sys.symbol.doc.richtext'),
      'DOC': $r('sys.symbol.doc.richtext')
    };
    return formatSymbols[format] || $r('sys.symbol.book.fill');
  }

  build() {
    Column() {
      PageHeader({
        title: '千读阅界',
        showBack: false,
        rightContent: () => {
          Row({ space: HDSSpacing.sm }) {
            SymbolGlyph($r('sys.symbol.bell'))
              .fontSize(20)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900])
              .onClick(() => DialogHelper.info('通知功能开发中'))
            
            SymbolGlyph($r('sys.symbol.plus.circle.fill'))
              .fontSize(24)
              .fontColor([HDSColours.primary.blue])
              .onClick(() => {
                if (this.onOpenFilePicker) {
                  this.onOpenFilePicker();
                }
              })
          }
        }
      })

      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          this.RecentBooksCard()
          this.ShortcutsCard()
          this.ReadingStatsCard()
          Column().height(HDSPacing.xxxl)
        }
        .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg, top: HDSSpacing.md })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  RecentBooksCard() {
    HDSCard({
      title: '继续阅读',
      padding: HDSSpacing.lg,
      content: () => {
        if (this.recentBooks.length > 0) {
          Scroll() {
            Row({ space: HDSSpacing.md }) {
              ForEach(this.recentBooks.slice(0, 6), (book: BookInfo) => {
                this.BookItem(book)
              }, (book: BookInfo) => book.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        } else {
          EmptyState({
            icon: '',
            title: '暂无正在阅读的书籍',
            subtitle: '快去添加一些书籍吧',
            actionText: '添加书籍',
            onAction: () => {
              if (this.onOpenFilePicker) {
                this.onOpenFilePicker();
              }
            }
          })
        }
      }
    })
  }

  @Builder
  BookItem(book: BookInfo) {
    Column({ space: HDSSpacing.xs }) {
      Stack({ alignContent: Alignment.Bottom }) {
        if (book.coverPath && book.coverPath.length > 0) {
          Image(book.coverPath)
            .width(80)
            .height(110)
            .borderRadius(HDSBorderRadius.sm)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            SymbolGlyph(this.getFormatSymbol(book.format))
              .fontSize(32)
              .fontColor([HDSColours.neutral.white])
          }
          .width(80)
          .height(110)
          .backgroundColor(HDSColours.primary.blue)
          .borderRadius(HDSBorderRadius.sm)
          .justifyContent(FlexAlign.Center)
        }

        if (book.readProgress > 0) {
          Progress({ value: book.readProgress, total: 100 })
            .width(70)
            .height(3)
            .color(HDSColours.primary.blue)
            .borderRadius(1.5)
        }
      }

      Text(book.title)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
        .width(80)

      if (book.readProgress > 0) {
        Text(`${book.readProgress}%`)
          .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
          .fontColor(HDSColours.primary.blue)
      }
    }
    .onClick(() => {
      if (this.onBookClick) {
        this.onBookClick(book);
      }
    })
  }

  @Builder
  ShortcutsCard() {
    HDSCard({
      title: '快捷入口',
      padding: HDSSpacing.lg,
      content: () => {
        Grid() {
          ForEach(this.shortcuts, (item: ShortcutItem) => {
            GridItem() {
              this.HomeShortcut(item.symbol, item.title, item.color, () => {
                navigateTo(item.url);
              })
            }
          }, (item: ShortcutItem) => item.title)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr')
        .columnsGap(HDSPacing.sm)
        .rowsGap(HDSPacing.sm)
      }
    })
  }

  @Builder
  HomeShortcut(symbolName: string, title: string, color: string, action: () => void) {
    Column({ space: HDSSpacing.xs }) {
      Column() {
        SymbolGlyph($r(`sys.symbol.${symbolName}`))
          .fontSize(24)
          .fontColor([color])
      }
      .width(48)
      .height(48)
      .borderRadius(HDSBorderRadius.sm)
      .backgroundColor(color + '15')
      .justifyContent(FlexAlign.Center)

      Text(title)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
    }
    .width('100%')
    .padding(HDSPacing.sm)
    .onClick(() => action())
    .stateStyles({
      pressed: { .scale({ x: 0.95, y: 0.95 }) },
      normal: { .scale({ x: 1, y: 1 }) }
    })
  }

  @Builder
  ReadingStatsCard() {
    HDSCard({
      title: '本周阅读概览',
      icon: $r('sys.symbol.chart.bar.xaxis'),
      padding: HDSSpacing.lg,
      content: () => {
        Row({ space: HDSSpacing.sm }) {
          this.StatItem('book.spread', '12h', '阅读时长', HDSColours.primary.blue)
          this.StatItem('books.vertical.fill', '5', '阅读书籍', '#FF6B6B')
          this.StatItem('chart.bar.alt.fill', '78%', '目标完成', '#52C41A')
        }
        .width('100%')
      }
    })
  }

  @Builder
  StatItem(symbolName: string, value: string, label: string, color: string) {
    Column({ space: HDSSpacing.xs }) {
      SymbolGlyph($r(`sys.symbol.${symbolName}`))
        .fontSize(24)
        .fontColor([color])

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xxl))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
    }
    .layoutWeight(1)
    .padding(HDSPacing.sm)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,125,255,0.04)')
    .borderRadius(HDSBorderRadius.sm)
    .alignItems(HorizontalAlign.Center)
  }
}
