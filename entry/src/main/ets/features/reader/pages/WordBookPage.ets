import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../../../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface WordItem {
  id: string;
  word: string;
  phonetic: string;
  meaning: string;
  bookTitle: string;
  createTime: number;
  reviewCount: number;
}

@Entry
@ComponentV2
struct WordBookPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local searchText: string = '';
  @Local words: WordItem[] = [];
  private context: common.Context | null = null;

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
    this.loadWords();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
    }
  }

  private loadWords(): void {
    try {
      const wordsJson = preferenceManager.getString('wordbook_words', '[]');
      const saved = JSON.parse(wordsJson) as WordItem[];
      this.words = saved;
      logger.info('[WordBookPage] Loaded ' + saved.length + ' words');
    } catch (error) {
      const err = error as Error;
      logger.error('[WordBookPage] Failed to load words:', err.message);
      this.words = [];
    }
  }

  private saveWords(): void {
    try {
      const json = JSON.stringify(this.words);
      preferenceManager.setString('wordbook_words', json);
    } catch (error) {
      const err = error as Error;
      logger.error('[WordBookPage] Failed to save words:', err.message);
    }
  }

  addWord(word: string, meaning: string, bookTitle: string, phonetic?: string): void {
    const newWord: WordItem = {
      id: 'word_' + Date.now().toString(36),
      word: word,
      phonetic: phonetic || '',
      meaning: meaning,
      bookTitle: bookTitle,
      createTime: Date.now(),
      reviewCount: 0
    };
    const newWords = [...this.words, newWord];
    this.words = newWords;
    this.saveWords();
    promptAction.showToast({ message: '已添加：' + word, duration: 1500 });
  }

  deleteWord(id: string): void {
    const newWords = this.words.filter(w => w.id !== id);
    this.words = newWords;
    this.saveWords();
    promptAction.showToast({ message: '已删除', duration: 1500 });
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前';
    if (diff < 604800000) return Math.floor(diff / 86400000) + '天前';

    return date.getMonth() + 1 + '-' + date.getDate();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconLG)
            .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
        }
        .width(Size.buttonMD)
        .height(Size.buttonMD)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[WordBookPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Column({ space: Spacing.xs }) {
          Text('生词本')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.SemiBold)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

          Text(this.words.length + ' 个单词')
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: Spacing.md })

        // 复习按钮
        Row() {
          SymbolGlyph($r('sys.symbol.arrow.repeat'))
            .fontSize(Size.iconSM)
            .fontColor(['#FFFFFF'])
        }
        .width(Size.buttonSM)
        .height(Size.buttonSM)
        .borderRadius(BorderRadius.full)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          promptAction.showToast({ message: '开始复习', duration: 1500 });
        })
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // 搜索栏
      Row({ space: Spacing.sm }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(Size.iconSM)
          .fontColor([this.tc('#8E8E93', '#8E8E93')])
          .margin({ left: Spacing.md })

        TextInput({ placeholder: '搜索单词...', text: $$this.searchText })
          .placeholderColor(this.tc('#C7C7CC', '#8E8E93'))
          .fontSize(fontScaleManager.getScaledFontSize(14))
          .height(Size.inputSM)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchText = value;
          })

        if (this.searchText) {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
          }
          .width(Size.buttonSM)
          .height(Size.buttonSM)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.searchText = '';
          })
        }
      }
      .width('100%')
      .height(Size.inputSM)
      .padding({ left: Spacing.sm, right: Spacing.sm })
      .backgroundColor(this.tc('#F2F2F7', '#2C2C2E'))
      .borderRadius(BorderRadius.xl)
      .margin({ left: Spacing.lg, right: Spacing.lg, top: Spacing.md })

      // 单词列表
      if (this.words.length === 0) {
        this.EmptyState()
      } else {
        List({ space: Spacing.md }) {
          ForEach(this.words, (word: WordItem) => {
            ListItem() {
              this.WordItem(word)
            }
          }, (word: WordItem) => word.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg,
          top: Spacing.md,
          bottom: Spacing.xxxl
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  WordItem(word: WordItem) {
    Column({ space: Spacing.md }) {
      // 头部：单词和音标
      Row({ space: Spacing.md }) {
        // 字母图标
        Column() {
          Text(word.word.charAt(0).toUpperCase())
            .fontSize(fontScaleManager.getScaledFontSize(24))
            .fontWeight(FontWeight.Bold)
            .fontColor(COMMON_COLORS.PRIMARY_BLUE)
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.lg)
        .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
        .justifyContent(FlexAlign.Center)

        Column({ space: Spacing.xs }) {
          Row({ space: Spacing.sm }) {
            Text(word.word)
              .fontSize(fontScaleManager.getScaledFontSize(18))
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

            Text(word.phonetic)
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }

          Text(word.meaning)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor(this.tc('#3A3A3C', '#E5E5EA'))
            .lineHeight(20)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 复习次数
        Column({ space: Spacing.xs }) {
          Row() {
            SymbolGlyph($r('sys.symbol.arrow.repeat'))
              .fontSize(Size.iconXS)
              .fontColor([COMMON_COLORS.PRIMARY_BLUE])
            
            Text(word.reviewCount.toString())
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontWeight(FontWeight.Medium)
              .fontColor(COMMON_COLORS.PRIMARY_BLUE)
          }
          
          Text('复习')
            .fontSize(fontScaleManager.getScaledFontSize(10))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
      }
      .width('100%')

      // 底部：书籍信息和时间
      Row({ space: Spacing.sm }) {
        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.book'))
            .fontSize(Size.iconXS)
            .fontColor([this.tc('#8E8E93', '#8E8E93')])
          
          Text(word.bookTitle)
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Blank()

        Text(this.formatTime(word.createTime))
          .fontSize(fontScaleManager.getScaledFontSize(11))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .onClick(() => {
      promptAction.showToast({ message: `查看 "${word.word}" 详情`, duration: 1500 });
    })
    .stateStyles({
      pressed: { 
        .scale({ x: 0.98, y: 0.98 }),
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .scale({ x: 1, y: 1 }),
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      }
    })
  }

  @Builder
  EmptyState() {
    Column({ space: Spacing.xl }) {
      Column() {
        SymbolGlyph($r('sys.symbol.book.closed'))
          .fontSize(Size.iconXXXL * 1.5)
          .fontColor([this.tc('#D1D1D6', '#48484A')])
      }
      .width(100)
      .height(100)
      .borderRadius(BorderRadius.full)
      .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      .justifyContent(FlexAlign.Center)

      Text('暂无生词')
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text('阅读时添加生词，积累词汇量')
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

// 预览组件
@Preview
@ComponentV2
struct WordBookPagePreview {
  build() {
    Column() {
      Text('生词本 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      WordBookPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('生词本 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      WordBookPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
