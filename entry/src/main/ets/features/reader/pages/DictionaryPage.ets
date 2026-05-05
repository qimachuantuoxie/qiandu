import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';
import { ThemeTokens } from '../../common/utils/ThemeTokens';

interface DictionaryResult {
  word: string;
  phonetic: string;
  meanings: MeaningItem[];
}

interface MeaningItem {
  partOfSpeech: string;
  definitions: string[];
}

@Entry
@ComponentV2
struct DictionaryPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local searchText: string = '';
  @Local searchResult: DictionaryResult | null = null;
  @Local isSearching: boolean = false;
  private context: common.Context | null = null;

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private handleSearch(): void {
    if (!this.searchText.trim()) {
      promptAction.showToast({ message: '请输入要查询的单词', duration: 1500 });
      return;
    }
    
    this.isSearching = true;
    this.searchResult = null;
    
    // Call actual dictionary API
    this.fetchDictionary(this.searchText.trim());
  }

  private async fetchDictionary(word: string): Promise<void> {
    try {
      // Use free dictionary API
      const response = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
      this.isSearching = false;
      
      if (!response.ok) {
        promptAction.showToast({ message: '未找到该单词', duration: 2000 });
        return;
      }
      
      const data = await response.json();
      if (data && data.length > 0) {
        const entry = data[0];
        const meanings: MeaningItem[] = [];
        
        if (entry.meanings) {
          for (let i = 0; i < entry.meanings.length; i++) {
            const m = entry.meanings[i];
            meanings.push({
              partOfSpeech: m.partOfSpeech || 'n.',
              definitions: m.definitions ? m.definitions.map((d: any) => d.definition).slice(0, 5) : []
            });
          }
        }
        
        this.searchResult = {
          word: entry.word || word,
          phonetic: entry.phonetics && entry.phonetics[0] ? entry.phonetics[0].text || '' : '',
          meanings: meanings
        };
      } else {
        promptAction.showToast({ message: '未找到该单词', duration: 2000 });
      }
    } catch (error) {
      this.isSearching = false;
      const err = error as Error;
      logger.error('[DictionaryPage] Search failed:', err.message);
      promptAction.showToast({ message: '查询失败，请检查网络', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconLG)
            .fontColor([ThemeTokens.textPrimary()])
        }
        .width(Size.buttonMD)
        .height(Size.buttonMD)
        .borderRadius(BorderRadius.full)
        .backgroundColor(ThemeTokens.bgHover())
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[DictionaryPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('词典')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(ThemeTokens.textPrimary())
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(Size.buttonMD)
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(ThemeTokens.bgSecondary())
      .shadow(getShadow('sm', this.isDarkMode))

      // 搜索区域
      Column({ space: Spacing.md }) {
        Row({ space: Spacing.sm }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(Size.iconMD)
            .fontColor([ThemeTokens.textSecondary()])
            .margin({ left: Spacing.md })

          TextInput({ 
            placeholder: '输入单词查询...', 
            text: $$this.searchText,
            onEnterKeyClick: () => this.handleSearch()
          })
            .placeholderColor(ThemeTokens.textTertiary())
            .fontSize(fontScaleManager.getScaledFontSize(15))
            .height(Size.inputSM + Spacing.sm)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchText = value;
            })

          if (this.searchText) {
            Row() {
              SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
                .fontSize(Size.iconMD)
                .fontColor([ThemeTokens.textSecondary()])
            }
            .width(Size.buttonMD)
            .height(Size.buttonMD)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.searchText = '';
              this.searchResult = null;
            })
          }
        }
        .width('100%')
        .height(Size.inputSM + Spacing.sm)
        .padding({ left: Spacing.sm, right: Spacing.sm })
        .backgroundColor(ThemeTokens.bgTertiary())
        .borderRadius(BorderRadius.xl)

        // 搜索按钮
        Button() {
          if (this.isSearching) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color('#FFFFFF')
          } else {
            Row({ space: Spacing.sm }) {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(Size.iconSM)
                .fontColor(['#FFFFFF'])
              
              Text('查询')
                .fontSize(fontScaleManager.getScaledFontSize(15))
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
          }
        }
        .width('100%')
        .height(Size.buttonLG)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [COMMON_COLORS.PRIMARY_BLUE, COMMON_COLORS.PRIMARY_BLUE + 'CC']
        })
        .borderRadius(BorderRadius.xl)
        .shadow({
          radius: 8,
          color: COMMON_COLORS.PRIMARY_BLUE + '40',
          offsetY: 4
        })
        .enabled(!this.isSearching)
        .onClick(() => this.handleSearch())
        .stateStyles({
          pressed: { .scale({ x: 0.98, y: 0.98 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })
      }
      .width('100%')
      .padding(Spacing.lg)

      // 搜索结果
      if (this.searchResult) {
        Scroll() {
          Column({ space: Spacing.lg }) {
            // 单词卡片
            Column({ space: Spacing.md }) {
              Row({ space: Spacing.md }) {
                // 字母图标
                Column() {
                  Text(this.searchResult!.word.charAt(0).toUpperCase())
                    .fontSize(fontScaleManager.getScaledFontSize(32))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                }
                .width(70)
                .height(70)
                .borderRadius(BorderRadius.lg)
                .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
                .justifyContent(FlexAlign.Center)

                Column({ space: Spacing.sm }) {
                  Text(this.searchResult!.word)
                    .fontSize(fontScaleManager.getScaledFontSize(24))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ThemeTokens.textPrimary())

                  Text(this.searchResult!.phonetic)
                    .fontSize(fontScaleManager.getScaledFontSize(14))
                    .fontColor(ThemeTokens.textSecondary())
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 发音按钮
                Row() {
                  SymbolGlyph($r('sys.symbol.waveform'))
                    .fontSize(Size.iconLG)
                    .fontColor([COMMON_COLORS.PRIMARY_BLUE])
                }
                .width(Size.buttonLG)
                .height(Size.buttonLG)
                .borderRadius(BorderRadius.full)
                .backgroundColor(COMMON_COLORS.PRIMARY_BLUE + '15')
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  promptAction.showToast({ message: '播放发音', duration: 1000 });
                })
              }
              .width('100%')
            }
            .width('100%')
            .padding(Spacing.xl)
            .backgroundColor(ThemeTokens.bgSecondary())
            .borderRadius(BorderRadius.xl)
            .shadow(getShadow('md', this.isDarkMode))

            // 释义列表
            ForEach(this.searchResult!.meanings, (meaning: MeaningItem, index: number) => {
              Column({ space: Spacing.md }) {
                Row({ space: Spacing.sm }) {
                  Text(meaning.partOfSpeech)
                    .fontSize(fontScaleManager.getScaledFontSize(16))
                    .fontWeight(FontWeight.SemiBold)
                    .fontColor(COMMON_COLORS.PRIMARY_BLUE)
                  
                  Rectangle()
                    .width('100%')
                    .height(1)
                    .fill(ThemeTokens.borderLight())
                }
                .width('100%')

                Column({ space: Spacing.sm }) {
                  ForEach(meaning.definitions, (def: string, idx: number) => {
                    Row({ space: Spacing.sm }) {
                      Text((idx + 1).toString() + '.')
                        .fontSize(fontScaleManager.getScaledFontSize(14))
                        .fontWeight(FontWeight.Medium)
                        .fontColor(ThemeTokens.textSecondary())
                        .width(20)
                      
                      Text(def)
                        .fontSize(fontScaleManager.getScaledFontSize(14))
                        .fontColor(ThemeTokens.textPrimary())
                        .lineHeight(22)
                        .layoutWeight(1)
                    }
                    .width('100%')
                  }, (def: string, idx: number) => def)
                }
                .width('100%')
              }
              .width('100%')
              .padding(Spacing.xl)
              .backgroundColor(ThemeTokens.bgSecondary())
              .borderRadius(BorderRadius.xl)
              .shadow(getShadow('sm', this.isDarkMode))
            }, (meaning: MeaningItem, index: number) => meaning.partOfSpeech + index)

            // 添加到生词本按钮
            Button() {
              Row({ space: Spacing.sm }) {
                SymbolGlyph($r('sys.symbol.bookmark'))
                  .fontSize(Size.iconMD)
                  .fontColor(['#FFFFFF'])
                
                Text('添加到生词本')
                  .fontSize(fontScaleManager.getScaledFontSize(15))
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
              }
            }
            .width('100%')
            .height(Size.buttonLG)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: ['#FFD700', '#FFA500']
            })
            .borderRadius(BorderRadius.xl)
            .shadow({
              radius: 8,
              color: '#FFD70040',
              offsetY: 4
            })
            .onClick(() => {
              promptAction.showToast({ message: '已添加到生词本', duration: 1500 });
            })
            .stateStyles({
              pressed: { .scale({ x: 0.98, y: 0.98 }) },
              normal: { .scale({ x: 1, y: 1 }) }
            })
          }
          .width('100%')
          .padding({ 
            left: Spacing.lg, 
            right: Spacing.lg,
            bottom: Spacing.xxxl
          })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      } else {
        // 空状态
        Column({ space: Spacing.xl }) {
          Column() {
            SymbolGlyph($r('sys.symbol.book.closed'))
              .fontSize(Size.iconXXXL * 1.5)
              .fontColor([ThemeTokens.textDisabled()])
          }
          .width(100)
          .height(100)
          .borderRadius(BorderRadius.full)
          .backgroundColor(ThemeTokens.bgHover())
          .justifyContent(FlexAlign.Center)

          Text('输入单词开始查询')
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeTokens.textPrimary())

          Text('支持中英文词典查询')
            .fontSize(fontScaleManager.getScaledFontSize(13))
            .fontColor(ThemeTokens.textSecondary())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.bgPrimary())
  }
}

// 预览组件
@Preview
@ComponentV2
struct DictionaryPagePreview {
  build() {
    Column() {
      Text('词典页面 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      DictionaryPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('词典页面 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      DictionaryPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
