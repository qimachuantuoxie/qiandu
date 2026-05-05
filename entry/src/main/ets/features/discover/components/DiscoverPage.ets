// 发现页组件 - 功能发现入口

import { navigateTo } from '../../../common/utils/NavigationHelper';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { themeManager } from '../../../common/constants/AppTheme';

interface DiscoverItem {
  icon: string;
  title: string;
  desc: string;
  url?: string;
  action?: () => void;
}

@ComponentV2
export struct DiscoverContent {
  @Local isDarkMode: boolean = themeManager.isDarkMode();
  onOpenFolderScanner?: () => void;

  private readonly discoverItems: DiscoverItem[] = [
    { icon: 'book.fill', title: '书源市场', desc: '浏览和导入在线书源', url: 'features/source-market/pages/SourceMarketPage' },
    { icon: 'globe', title: '在线书源', desc: '发现更多优质书源', url: 'features/source-market/pages/OnlineSourceMarketPage' },
    { icon: 'chart.bar.fill', title: '阅读统计', desc: '查看您的阅读数据', url: 'features/settings/pages/StatisticsPage' },
    { icon: 'clock.fill', title: '阅读记录', desc: '回顾阅读历史', url: 'features/settings/pages/ReadRecordPage' },
    { icon: 'bookmark.fill', title: '书签管理', desc: '管理您的书签', url: 'features/bookshelf/pages/BookmarksPage' },
    { icon: 'note.text', title: '笔记管理', desc: '查看您的读书笔记', url: 'features/bookshelf/pages/NotesPage' },
    { icon: 'checkmark.circle.fill', title: '待办事项', desc: '管理阅读计划和任务', url: 'features/discover/pages/TodoPage' },
    { icon: 'character.book.closed', title: '生词本', desc: '积累您的词汇量', url: 'features/reader/pages/WordBookPage' },
  ];

  private navigateTo(url: string): void {
    navigateTo(url);
  }

  build() {
    Column() {
      // 顶部导航栏
      PageHeader({
        title: '发现',
        showBack: false,
        rightContent: () => {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900])
        }
      })

      // 功能列表
      this.DiscoverList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }

  @Builder
  DiscoverList() {
    Scroll() {
      Column({ space: HDSSpacing.lg }) {
        ForEach(this.discoverItems, (item: DiscoverItem) => {
          HDSCard({
            padding: HDSSpacing.lg,
            onClick: () => {
              if (item.url) {
                this.navigateTo(item.url);
              } else if (item.action) {
                item.action();
              }
            },
            content: () => {
              Row({ space: HDSSpacing.lg }) {
                SymbolGlyph($r(`sys.symbol.${item.icon}`))
                  .fontSize(28)
                  .fontColor([HDSColours.primary.blue])
              
                Column({ space: HDSSpacing.xs }) {
                  Text(item.title)
                    .fontSize(HDSTypography.sizes.lg)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              
                  Text(item.desc)
                    .fontSize(HDSTypography.sizes.sm)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              
                SymbolGlyph($r('sys.symbol.chevron.right'))
                  .fontSize(20)
                  .fontColor([this.isDarkMode ? '#555555' : '#CCCCCC'])
              }
              .width('100%')
            }
          })
        })

        // 扫描文件夹入口
        HDSCard({
          padding: HDSSpacing.lg,
          onClick: () => {
            navigateTo('pages/FolderScannerPage');
          },
          content: () => {
            Row({ space: HDSSpacing.lg }) {
              SymbolGlyph($r('sys.symbol.folder.fill'))
                .fontSize(28)
                .fontColor([HDSColours.primary.blue])
            
              Column({ space: HDSSpacing.xs }) {
                Text('扫描文件夹')
                  .fontSize(HDSTypography.sizes.lg)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
            
                Text('批量导入本地书籍')
                  .fontSize(HDSTypography.sizes.sm)
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            
              SymbolGlyph($r('sys.symbol.chevron.right'))
                .fontSize(20)
                .fontColor([this.isDarkMode ? '#555555' : '#CCCCCC'])
            }
            .width('100%')
          }
        })
      }
      .padding(HDSPacing.lg)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}
