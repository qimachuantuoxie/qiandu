// 发现页组件 - 功能发现入口

import { navigateTo } from '../../../common/utils/NavigationHelper';
import { Spacing, Size, BorderRadius } from '../../../core/utils/LayoutConstants';
import { layoutHelper } from '../../../core/utils/LayoutHelper';

interface DiscoverItem {
  icon: string;
  title: string;
  desc: string;
  url?: string;
  action?: () => void;
}

@ComponentV2
export struct DiscoverContent {
  @Param isDarkMode: boolean = false;
  onOpenFolderScanner?: () => void;

  private readonly discoverItems: DiscoverItem[] = [
    { icon: 'book.fill', title: '书源市场', desc: '浏览和导入在线书源', url: 'features/source-market/pages/SourceMarketPage' },
    { icon: 'globe', title: '在线书源', desc: '发现更多优质书源', url: 'features/source-market/pages/OnlineSourceMarketPage' },
    { icon: 'chart.bar.fill', title: '阅读统计', desc: '查看您的阅读数据', url: 'features/settings/pages/StatisticsPage' },
    { icon: 'clock.fill', title: '阅读记录', desc: '回顾阅读历史', url: 'features/settings/pages/ReadRecordPage' },
    { icon: 'bookmark.fill', title: '书签管理', desc: '管理您的书签', url: 'features/bookshelf/pages/BookmarksPage' },
    { icon: 'note.text', title: '笔记管理', desc: '查看您的读书笔记', url: 'features/bookshelf/pages/NotesPage' },
    { icon: 'checkmark.circle.fill', title: '待办事项', desc: '管理阅读计划和任务', url: 'features/profile/pages/TodoPage' },
    { icon: 'character.book.closed', title: '生词本', desc: '积累您的词汇量', url: 'features/reader/pages/WordBookPage' },
  ];

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Column() {
      // 顶部导航栏
      this.HeaderBar()

      // 功能列表
      this.DiscoverList()
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  HeaderBar() {
    Row() {
      Text('发现')
        .fontSize(layoutHelper.getResponsiveFontSize(22))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(Size.iconMD)
        .fontColor([this.isDarkMode ? '#FFFFFF' : '#1A1A1A'])
        .padding(Spacing.sm)
    }
    .width('100%')
    .height(60)
    .padding({ left: Spacing.xl, right: Spacing.xl })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
  }

  @Builder
  DiscoverList() {
    Scroll() {
      Column({ space: Spacing.lg }) {
        ForEach(this.discoverItems, (item: DiscoverItem) => {
          this.DiscoverCard(item.icon, item.title, item.desc, () => {
            if (item.url) {
              this.navigateTo(item.url);
            } else if (item.action) {
              item.action();
            }
          })
        })

        // 扫描文件夹入口
        this.DiscoverCard('folder.fill', '扫描文件夹', '批量导入本地书籍', () => {
          navigateTo('pages/FolderScannerPage');
        })
      }
      .width('100%')
      .padding(Spacing.lg)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  DiscoverCard(icon: string, title: string, desc: string, action: () => void) {
    Row({ space: Spacing.lg }) {
      SymbolGlyph($r(`sys.symbol.${icon}`))
        .fontSize(Size.iconXXL)
        .fontColor([this.isDarkMode ? '#007DFF' : '#007DFF'])
    
      Column({ space: Spacing.xs }) {
        Text(title)
          .fontSize(layoutHelper.getResponsiveFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
    
        Text(desc)
          .fontSize(layoutHelper.getResponsiveFontSize(12))
          .fontColor(this.isDarkMode ? '#888888' : '#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    
      SymbolGlyph($r('sys.symbol.chevron.right'))
        .fontSize(Size.iconMD)
        .fontColor([this.isDarkMode ? '#555555' : '#CCCCCC'])
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(BorderRadius.lg)
    .onClick(() => {
      action();
    })
  }
}
