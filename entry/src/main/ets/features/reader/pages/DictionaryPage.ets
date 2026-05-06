import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';

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
      // 标准页面头部
      PageHeader({
        title: '词典',
        showBack: true,
        onBack: () => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[DictionaryPage] back failed:', msg);
          }
        }
      })

      // 搜索区域
      Column({ space: HDSSpacing.md }) {
        Row({ space: HDSSpacing.sm }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(HDSTypography.sizes.lg)
            .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            .margin({ left: HDSSpacing.md })

          TextInput({ 
            placeholder: '输入单词查询...', 
            text: $$this.searchText,
            onEnterKeyClick: () => this.handleSearch()
          })
            .placeholderColor(this.isDarkMode ? HDSColours.neutralDark.textTertiary : HDSColours.neutral.gray400)
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
            .height(48)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchText = value;
            })

          if (this.searchText) {
            Row() {
              SymbolGlyph($r('sys.symbol.xmark.circle.fill'))
                .fontSize(HDSTypography.sizes.lg)
                .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
            }
            .width(32)
            .height(32)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.searchText = '';
              this.searchResult = null;
            })
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm })
        .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray50)
        .borderRadius(HDSBorderRadius.xl)

        // 搜索按钮
        Button() {
          if (this.isSearching) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color('#FFFFFF')
          } else {
            Row({ space: HDSSpacing.sm }) {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(HDSTypography.sizes.md)
                .fontColor([HDSColours.neutral.white])
              
              Text('查询')
                .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
                .fontWeight(FontWeight.Medium)
                .fontColor(HDSColours.neutral.white)
            }
          }
        }
        .width('100%')
        .height(48)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [HDSColours.primary.blue, HDSColours.primary.blue + 'CC']
        })
        .borderRadius(HDSBorderRadius.xl)
        .shadow({
          radius: 8,
          color: HDSColours.primary.blue + '40',
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
      .padding(HDSPacing.lg)

      // 搜索结果
      if (this.searchResult) {
        Scroll() {
          Column({ space: HDSSpacing.lg }) {
            // 单词卡片
            Column({ space: HDSSpacing.md }) {
              Row({ space: HDSSpacing.md }) {
                // 字母图标
                Column() {
                  Text(this.searchResult!.word.charAt(0).toUpperCase())
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xxxl))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(HDSColours.primary.blue)
                }
                .width(70)
                .height(70)
                .borderRadius(HDSBorderRadius.lg)
                .backgroundColor(HDSColours.primary.blue + '15')
                .justifyContent(FlexAlign.Center)

                Column({ space: HDSSpacing.sm }) {
                  Text(this.searchResult!.word)
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xxl))
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

                  Text(this.searchResult!.phonetic)
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 发音按钮
                Row() {
                  SymbolGlyph($r('sys.symbol.waveform'))
                    .fontSize(HDSTypography.sizes.xl)
                    .fontColor([HDSColours.primary.blue])
                }
                .width(48)
                .height(48)
                .borderRadius(HDSBorderRadius.full)
                .backgroundColor(HDSColours.primary.blue + '15')
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  promptAction.showToast({ message: '播放发音', duration: 1000 });
                })
              }
              .width('100%')
            }
            .width('100%')
            .padding(HDSPacing.xl)
            .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray50)
            .borderRadius(HDSBorderRadius.xl)
            .shadow({
              radius: 8,
              color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)',
              offsetY: 4
            })

            // 释义列表
            ForEach(this.searchResult!.meanings, (meaning: MeaningItem, index: number) => {
              Column({ space: HDSSpacing.md }) {
                Row({ space: HDSSpacing.sm }) {
                  Text(meaning.partOfSpeech)
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
                    .fontWeight(FontWeight.SemiBold)
                    .fontColor(HDSColours.primary.blue)
                  
                  Rectangle()
                    .width('100%')
                    .height(1)
                    .fill(this.isDarkMode ? HDSColours.neutralDark.border : HDSColours.neutral.gray200)
                }
                .width('100%')

                Column({ space: HDSSpacing.sm }) {
                  ForEach(meaning.definitions, (def: string, idx: number) => {
                    Row({ space: HDSSpacing.sm }) {
                      Text((idx + 1).toString() + '.')
                        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                        .width(20)
                      
                      Text(def)
                        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                        .lineHeight(22)
                        .layoutWeight(1)
                    }
                    .width('100%')
                  }, (def: string, idx: number) => def)
                }
                .width('100%')
              }
              .width('100%')
              .padding(HDSPacing.xl)
              .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray50)
              .borderRadius(HDSBorderRadius.xl)
              .shadow({
                radius: 4,
                color: this.isDarkMode ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)',
                offsetY: 2
              })
            }, (meaning: MeaningItem, index: number) => meaning.partOfSpeech + index)

            // 添加到生词本按钮
            Button() {
              Row({ space: HDSSpacing.sm }) {
                SymbolGlyph($r('sys.symbol.bookmark'))
                  .fontSize(HDSTypography.sizes.lg)
                  .fontColor([HDSColours.neutral.white])
                
                Text('添加到生词本')
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(HDSColours.neutral.white)
              }
            }
            .width('100%')
            .height(48)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: ['#FFD700', '#FFA500']
            })
            .borderRadius(HDSBorderRadius.xl)
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
            left: HDSSpacing.lg, 
            right: HDSSpacing.lg,
            bottom: HDSSpacing.xxxl
          })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      } else {
        // 空状态
        Column({ space: HDSSpacing.xl }) {
          Column() {
            SymbolGlyph($r('sys.symbol.book.closed'))
              .fontSize(64)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textDisabled : HDSColours.neutral.gray400])
          }
          .width(100)
          .height(100)
          .borderRadius(HDSBorderRadius.full)
          .backgroundColor(this.isDarkMode ? HDSColours.neutralDark.surface : HDSColours.neutral.gray100)
          .justifyContent(FlexAlign.Center)

          Text('输入单词开始查询')
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

          Text('支持中英文词典查询')
            .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
            .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
  }
}

// 预览组件
@Preview
@ComponentV2
struct DictionaryPagePreview {
  build() {
    Column() {
      Text('词典页面 - 浅色模式')
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutral.gray100)

      DictionaryPage()
        .height(700)

      Divider()
        .margin({ top: HDSSpacing.xl, bottom: HDSSpacing.xl })

      Text('词典页面 - 深色模式')
        .fontSize(HDSTypography.sizes.lg)
        .fontWeight(FontWeight.Bold)
        .padding(HDSPacing.md)
        .backgroundColor(HDSColours.neutralDark.surface)
        .fontColor(HDSColours.neutralDark.textPrimary)

      DictionaryPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor(HDSColours.neutral.white)
  }
}
