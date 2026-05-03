// 发现页组件 - 功能发现入口
import { router } from '@kit.ArkUI';
import { navigateTo } from '../../../utils/NavigationHelper';

interface DiscoverItem {
  icon: string;
  title: string;
  desc: string;
  url?: string;
  action?: () => void;
}

@Component
export struct DiscoverContent {
  @Prop isDarkMode: boolean = false;
  onOpenFolderScanner?: () => void;

  private readonly discoverItems: DiscoverItem[] = [
    { icon: '\ud83d\udcda', title: '书源市场', desc: '浏览和导入在线书源', url: 'pages/SourceMarketPage' },
    { icon: '\ud83d\udce6', title: '在线书源', desc: '发现更多优质书源', url: 'pages/OnlineSourceMarketPage' },
    { icon: '\ud83d\udcca', title: '阅读统计', desc: '查看您的阅读数据', url: 'pages/StatisticsPage' },
    { icon: '\ud83d\udcc9', title: '阅读记录', desc: '回顾阅读历史', url: 'pages/ReadRecordPage' },
    { icon: '\ud83d\udd16', title: '书签管理', desc: '管理您的书签', url: 'pages/BookmarksPage' },
    { icon: '\ud83d\udcdd', title: '笔记管理', desc: '查看您的读书笔记', url: 'pages/NotesPage' },
    { icon: '\u2705', title: '待办事项', desc: '管理阅读计划和任务', url: 'pages/TodoPage' },
    { icon: '\ud83d\udcd6', title: '生词本', desc: '积累您的词汇量', url: 'pages/WordBookPage' }
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
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .layoutWeight(1)

      Text('\ud83d\udd0d')
        .fontSize(20)
        .padding(8)
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
  }

  @Builder
  DiscoverList() {
    Scroll() {
      Column({ space: 16 }) {
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
        this.DiscoverCard('\ud83d\udcc2', '扫描文件夹', '批量导入本地书籍', () => {
          navigateTo('pages/FolderScannerPage');
        })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  DiscoverCard(icon: string, title: string, desc: string, action: () => void) {
    Row({ space: 16 }) {
      Text(icon)
        .fontSize(32)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

        Text(desc)
          .fontSize(12)
          .fontColor(this.isDarkMode ? '#888888' : '#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('\u2192')
        .fontSize(20)
        .fontColor(this.isDarkMode ? '#555555' : '#CCCCCC')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      action();
    })
  }
}
