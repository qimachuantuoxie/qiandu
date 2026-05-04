// 鍙戠幇椤电粍锟?- 鍔熻兘鍙戠幇鍏ュ彛

import { navigateTo } from '../../../../common/utils/NavigationHelper';

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
    { icon: '\ud83d\udcda', title: '涔︽簮甯傚満', desc: '娴忚�鍜屽�鍏ュ湪绾夸功婧?, url: 'features/source-market/pages/SourceMarketPage' },
    { icon: '\ud83d\udce6', title: '鍦ㄧ嚎涔︽簮', desc: '鍙戠幇鏇村�浼樿川涔︽簮', url: 'features/source-market/pages/OnlineSourceMarketPage' },
    { icon: '\ud83d\udcca', title: '闃呰�缁熻�', desc: '鏌ョ湅鎮ㄧ殑闃呰�鏁版嵁', url: 'features/settings/pages/StatisticsPage' },
    { icon: '\ud83d\udcc9', title: '闃呰�璁板綍', desc: '鍥為【闃呰�鍘嗗彶', url: 'features/settings/pages/ReadRecordPage' },
    { icon: '\ud83d\udd16', title: '涔︾�绠＄悊', desc: '绠＄悊鎮ㄧ殑涔︾�', url: 'features/bookshelf/pages/BookmarksPage' },
    { icon: '\ud83d\udcdd', title: '绗旇�绠＄悊', desc: '鏌ョ湅鎮ㄧ殑璇讳功绗旇�', url: 'features/bookshelf/pages/NotesPage' },
    { icon: '\u2705', title: '寰呭姙浜嬮」', desc: '绠＄悊闃呰�璁″垝鍜屼换鍔?, url: 'features/profile/pages/TodoPage' },
    { icon: '\ud83d\udcd6', title: '鐢熻瘝鏈?, desc: '绉�疮鎮ㄧ殑璇嶆眹搴?, url: 'features/reader/pages/WordBookPage' },
  ];

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Column() {
      // 椤堕儴瀵艰埅锟?
      this.HeaderBar()

      // 鍔熻兘鍒楄〃
      this.DiscoverList()
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  HeaderBar() {
    Row() {
      Text('鍙戠幇')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .layoutWeight(1)

      Text('\ud83d\udd0d')
        .fontSize(20)
        .padding(Spacing.sm)
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

        // 鎵�弿鏂囦欢澶瑰叆锟?
        this.DiscoverCard('\ud83d\udcc2', '鎵�弿鏂囦欢锟?, '鎵归噺瀵煎叆鏈�湴涔︾睄', () => {
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
      Text(icon)
        .fontSize(Size.iconXXL)
    
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
    
      Text('→')
        .fontSize(Size.iconLG)
        .fontColor(this.isDarkMode ? '#555555' : '#CCCCCC')
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
