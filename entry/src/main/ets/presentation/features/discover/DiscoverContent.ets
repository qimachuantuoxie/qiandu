/**
 * 发现页面 - 优化版
 * 主打在线书城功能，辅以书源市场、阅读工具等
 * 优化：UI 美化、动画、交互体验、系统符号
 *
 * @since 3.0.0
 */

import { router } from '@kit.ArkUI';
import { navigateTo } from '../../../utils/NavigationHelper';
import { themeManager, COMMON_COLORS, AppColors } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';
import { CommonCard, CardType, CommonListItem, CommonDivider } from '../../../components/common/CommonButton';

interface NavParam {
  keyword: string;
}

interface OnlineBookCategory {
  icon: string;
  nameKey: string;
  gradient: string[];
  keyword: string;
}

interface QuickAction {
  icon: string;
  titleKey: string;
  bgColor: string;
  action: () => void;
}

@Component
export struct DiscoverContent {
  @Prop isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State hoveredIndex: number = -1;
  onOpenFolderScanner?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.initFontScale();
  }

  private async initFontScale(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  // 在线书城分类（系统符号图标）
  private readonly bookCategories: OnlineBookCategory[] = [
    { icon: 'flame_fill', nameKey: 'hot', gradient: ['#FF6B6B', '#FF8E53'], keyword: '热门' },
    { icon: 'wand_and_stars', nameKey: 'fantasy', gradient: ['#667eea', '#764ba2'], keyword: '玄幻' },
    { icon: 'heart_fill', nameKey: 'romance', gradient: ['#f093fb', '#f5576c'], keyword: '都市' },
    { icon: 'sword', nameKey: 'martial', gradient: ['#4facfe', '#00f2fe'], keyword: '武侠' },
    { icon: 'bolt_fill', nameKey: 'horror', gradient: ['#43e97b', '#38f9d7'], keyword: '灵异' },
    { icon: 'gamecontroller_fill', nameKey: 'game', gradient: ['#fa709a', '#fee140'], keyword: '游戏' },
    { icon: 'clock_fill', nameKey: 'history', gradient: ['#a8edea', '#fed6e3'], keyword: '历史' },
    { icon: 'globe', nameKey: 'scifi', gradient: ['#d299c2', '#fef9d7'], keyword: '科幻' }
  ];

  // 快捷操作（系统符号图标）
  private get quickActions(): QuickAction[] {
    return [
      {
        icon: 'magnifyingglass',
        titleKey: 'online_store',
        bgColor: COMMON_COLORS.PRIMARY_BLUE,
        action: () => navigateTo('pages/OnlineSearchPage')
      },
      {
        icon: 'bag_fill',
        titleKey: 'source_market',
        bgColor: '#52C41A',
        action: () => navigateTo('pages/SourceMarketPage')
      },
      {
        icon: 'folder_fill',
        titleKey: 'local_import',
        bgColor: '#FF9800',
        action: () => {
          if (this.onOpenFolderScanner) {
            this.onOpenFolderScanner();
          }
        }
      },
      {
        icon: 'calendar',
        titleKey: 'reading_plan',
        bgColor: '#722ED1',
        action: () => navigateTo('pages/TodoPage')
      }
    ];
  }

  build() {
    Column() {
      // 顶部搜索栏
      this.buildSearchBar()

      // 主要内容区
      Scroll() {
        Column({ space: 16 }) {
          // 在线书城核心区域
          this.buildOnlineBookstore()

          // 快捷操作区
          this.buildQuickActions()

          // 阅读工具区
          this.buildReadingTools()
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 16 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentColors.background)
  }

  @Builder
  buildSearchBar() {
    Row({ space: 12 }) {
      // 搜索框
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor([this.currentColors.textSecondary])

        Text(tr('search_hint'))
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontColor(this.currentColors.textSecondary)
      }
      .layoutWeight(1)
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
      .borderRadius(24)
      .onClick(() => navigateTo('pages/OnlineSearchPage'))
      .stateStyles({
        pressed: {
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)')
        },
        normal: {
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
        }
      })

      // 扫描按钮
      Column({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.camera_fill'))
          .fontSize(fontScaleManager.getScaledFontSize(20))
          .fontColor([COMMON_COLORS.PRIMARY_BLUE])

        Text('扫描')
          .fontSize(fontScaleManager.getScaledFontSize(9))
          .fontColor(this.currentColors.textSecondary)
      }
      .width(56)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.1)' : 'rgba(0,125,255,0.08)')
      .borderRadius(12)
      .onClick(() => {
        if (this.onOpenFolderScanner) {
          this.onOpenFolderScanner();
        }
      })
      .stateStyles({
        pressed: {
          .scale({ x: 0.95, y: 0.95 })
        },
        normal: {
          .scale({ x: 1, y: 1 })
        }
      })
    }
    .width('100%')
  }

  @Builder
  buildOnlineBookstore() {
    Column() {
      // 标题栏
      Row() {
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.book'))
            .fontSize(fontScaleManager.getScaledFontSize(20))
            .fontColor([this.currentColors.primary])

          Text(tr('online_store'))
            .fontSize(fontScaleManager.getScaledFontSize(20))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)
        }

        Blank()

        Row({ space: 4 }) {
          Text(tr('view_all'))
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor(this.currentColors.primary)
            .fontWeight(FontWeight.Medium)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor([this.currentColors.primary])
        }
        .onClick(() => navigateTo('pages/OnlineSearchPage'))
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 分类网格
      Grid() {
        ForEach(this.bookCategories, (category: OnlineBookCategory, index: number) => {
          GridItem() {
            Column({ space: 8 }) {
              SymbolGlyph(this.getCategoryResource(category.icon))
                .fontSize(fontScaleManager.getScaledFontSize(32))
                .fontColor(['#FFFFFF'])

              Text(tr(category.nameKey))
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .linearGradient({
              angle: 135,
              colors: this.buildGradientColors(category.gradient)
            })
            .shadow({
              radius: 10,
              color: category.gradient[0] + '40',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              const navParam: NavParam = { keyword: category.keyword };
              navigateTo('pages/OnlineSearchPage', navParam);
            })
            .stateStyles({
              pressed: {
                .scale({ x: 0.95, y: 0.95 })
                .opacity(0.9)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(16)
  }

  private buildGradientColors(gradient: string[]): [string, number][] {
    const result: [string, number][] = [];
    for (let i = 0; i < gradient.length; i++) {
      const item: [string, number] = [gradient[i], 1.0];
      result.push(item);
    }
    return result;
  }

  private getCategoryResource(name: string): Resource {
    if (name === 'flame_fill' || name === 'flame') return $r('sys.symbol.flame');
    if (name === 'wand_and_stars') return $r('sys.symbol.star');
    if (name === 'heart_fill' || name === 'heart') return $r('sys.symbol.heart');
    if (name === 'sword') return $r('sys.symbol.arrow_right');
    if (name === 'bolt_fill' || name === 'bolt') return $r('sys.symbol.bolt');
    if (name === 'gamecontroller_fill' || name === 'gamecontroller') return $r('sys.symbol.star');
    if (name === 'clock_fill' || name === 'clock') return $r('sys.symbol.clock');
    if (name === 'globe') return $r('sys.symbol.star');
    return $r('sys.symbol.star');
  }

  private getQuickActionResource(name: string): Resource {
    if (name === 'magnifyingglass') return $r('sys.symbol.magnifyingglass');
    if (name === 'bag_fill') return $r('sys.symbol.star');
    if (name === 'folder_fill') return $r('sys.symbol.folder');
    if (name === 'calendar') return $r('sys.symbol.calendar');
    return $r('sys.symbol.star');
  }

  private getToolResource(name: string): Resource {
    if (name === 'clock_fill' || name === 'clock') return $r('sys.symbol.clock');
    if (name === 'bookmark_fill' || name === 'bookmark') return $r('sys.symbol.bookmark');
    if (name === 'book') return $r('sys.symbol.book');
    return $r('sys.symbol.star');
  }

  @Builder
  buildQuickActions() {
    Column() {
      Text(tr('quick_actions'))
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      Grid() {
        ForEach(this.quickActions, (action: QuickAction, index: number) => {
          GridItem() {
            Column({ space: 12 }) {
              // 图标容器
              Column() {
                SymbolGlyph(this.getQuickActionResource(action.icon))
                  .fontSize(fontScaleManager.getScaledFontSize(26))
                  .fontColor([action.bgColor])
              }
              .width(60)
              .height(60)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(action.bgColor + '18')
              .borderRadius(30)

              Text(tr(action.titleKey))
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.currentColors.textSecondary)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding(12)
            .onClick(() => action.action())
            .stateStyles({
              pressed: {
                .scale({ x: 0.95, y: 0.95 })
                .opacity(0.85)
              },
              normal: {
                .scale({ x: 1, y: 1 })
                .opacity(1)
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(16)
  }

  @Builder
  buildReadingTools() {
    Column() {
      Text(tr('reading_tools'))
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      Column({ space: 0 }) {
        this.buildToolItem('chart_bar_fill', 'reading_statistics', 'view_reading_data', () => navigateTo('pages/StatisticsPage'))
        CommonDivider({ isDarkMode: this.isDarkMode, marginLeft: 54 })
        this.buildToolItem('clock_fill', 'read_records', 'review_reading_history', () => navigateTo('pages/ReadRecordPage'))
        CommonDivider({ isDarkMode: this.isDarkMode, marginLeft: 54 })
        this.buildToolItem('bookmark_fill', 'bookmarks', 'manage_bookmarks', () => navigateTo('pages/BookmarksPage'))
        CommonDivider({ isDarkMode: this.isDarkMode, marginLeft: 54 })
        this.buildToolItem('pencil', 'notes', 'view_edit_notes', () => navigateTo('pages/NotesPage'))
        CommonDivider({ isDarkMode: this.isDarkMode, marginLeft: 54 })
        this.buildToolItem('book', 'word_book', 'vocabulary_management', () => navigateTo('pages/WordBookPage'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentColors.surface)
    .borderRadius(16)
  }

  @Builder
  buildToolItem(icon: string, titleKey: string, descKey: string, action: () => void) {
    Row({ space: 16 }) {
      SymbolGlyph(this.getToolResource(icon))
        .fontSize(fontScaleManager.getScaledFontSize(22))
        .fontColor([this.currentColors.primary])

      Column({ space: 4 }) {
        Text(tr(titleKey))
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)

        Text(tr(descKey))
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.currentColors.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor([this.currentColors.textSecondary])
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(() => action())
    .stateStyles({
      pressed: {
        .opacity(0.7)
      },
      normal: {
        .opacity(1)
      }
    })
  }

}
