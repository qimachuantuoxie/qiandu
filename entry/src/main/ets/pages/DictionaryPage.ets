
// 词典查询页面 - 鸿蒙原生风格
// Dictionary Page - HarmonyOS Native Style

import { router } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { getDarkModeColors, IDarkModeColors, HarmonyColors } from '../utils/HarmonyDesignTokens';
import { dictionaryManager, advancedNoteManager, DictionaryResult, Definition, Example, WordBookItem } from '../models/AdvancedReading';
import { dictionaryViewModel, DictionaryViewModel } from '../viewmodels/DictionaryViewModel';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

@Entry
@Component
struct DictionaryPage {
  @State isDarkMode: boolean = false;
  @State colors: IDarkModeColors = { background: '', backgroundSecondary: '', cardBackground: '', textPrimary: '', textSecondary: '', textHint: '', primary: '', border: '', surface: '' };
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();

  vm: DictionaryViewModel = dictionaryViewModel;

  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      console.info('DictionaryPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.colors = getDarkModeColors(this.isDarkMode);
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet();

    this.vm.init();
  }

  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * this.fontScale * tabletMultiplier);
  }

  private async searchWordAction(): Promise<void> {
    if (!this.vm.searchWord.trim()) return;

    await this.vm.search(this.vm.searchWord.trim());
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private addToWordBook(): void {
    if (!this.vm.currentResult) return;

    dictionaryManager.addToVocabulary(this.vm.currentResult.word, this.vm.currentResult);
    this.vm.checkWordBookStatus(this.vm.currentResult.word);
  }

  build() {
    Column() {
      this.NavBar()
      this.SearchBar()
      
      if (this.vm.showResult && this.vm.currentResult) {
        this.ResultCard()
      } else if (this.vm.searchHistory.length > 0) {
        this.HistoryCard()
      }
      
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  @Builder
  NavBar() {
    Row() {
      Button() {
        Text('←')
          .fontSize(this.scaleFontSize(20))
          .fontColor(this.colors.textPrimary)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.tc('rgba(0,0,0,0.3)', 'rgba(255,255,255,0.3)'))
      .borderRadius(20)
      .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })
      
      Text('词典')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(600)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Button() {
        Text('词')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.tc('rgba(0,0,0,0.3)', 'rgba(255,255,255,0.3)'))
      .borderRadius(20)
      .onClick(() => {
        navigateTo('pages/WordBookPage');
      })
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16 })
    .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.3)')
  }

  @Builder
  SearchBar() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Row() {
          Text('查')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 12 })
          
          TextInput({ placeholder: '输入单词查询...', text: this.vm.searchWord })
            .layoutWeight(1)
            .height(44)
            .fontSize(this.scaleFontSize(15))
            .fontColor(this.colors.textPrimary)
            .placeholderColor(this.colors.textHint)
            .backgroundColor('transparent')
            .onChange((value: string) => {
              this.vm.searchWord = value;
            })
            .onSubmit(() => {
              this.searchWordAction();
            })
        }
        .layoutWeight(1)
        .padding({ left: 8 })
        .borderRadius(22)
        .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)')
        
        Button(this.vm.isLoading ? '...' : '查询')
          .height(44)
          .padding({ left: 20, right: 20 })
          .backgroundColor(HarmonyColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(this.scaleFontSize(14))
          .borderRadius(22)
          .enabled(!this.vm.isLoading)
          .onClick(() => this.searchWordAction())
      }
      
      Row({ space: 8 }) {
        Text('查询语言：')
          .fontSize(13)
          .fontColor(this.colors.textSecondary)
        
        Radio({ value: 'en', group: 'lang' })
          .checked(this.vm.selectedLanguage === 'en')
          .onChange((isChecked: boolean) => {
            if (isChecked) this.vm.selectedLanguage = 'en';
          })
        Text('English')
          .fontSize(13)
          .fontColor(this.colors.textSecondary)

        Radio({ value: 'zh', group: 'lang' })
          .checked(this.vm.selectedLanguage === 'zh')
          .onChange((isChecked: boolean) => {
            if (isChecked) this.vm.selectedLanguage = 'zh';
          })
        Text('中文')
          .fontSize(13)
          .fontColor(this.colors.textSecondary)
      }
    }
    .width('100%')
    .padding(this.isTablet ? 24 : 16)
  }

  @Builder
  ResultCard() {
    if (this.vm.currentResult) {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Text(this.vm.currentResult.word)
              .fontSize(this.scaleFontSize(28))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colors.textPrimary)

            if (this.vm.currentResult.phonetic) {
              Text(this.vm.currentResult.phonetic)
                .fontSize(this.scaleFontSize(16))
                .fontColor(this.colors.textHint)
                .margin({ left: 12 })
            }
          }
          .width('100%')

          Button(this.vm.isAddedToWordBook ? '✓ 已加入生词本' : '+ 加入生词本')
            .height(40)
            .padding({ left: 20, right: 20 })
            .backgroundColor(this.vm.isAddedToWordBook ? 'rgba(76, 175, 80, 0.2)' : HarmonyColors.primary)
            .fontColor(this.vm.isAddedToWordBook ? '#4CAF50' : '#FFFFFF')
            .fontSize(this.scaleFontSize(14))
            .borderRadius(20)
            .enabled(!this.vm.isAddedToWordBook)
            .onClick(() => this.addToWordBook())

          Column({ space: 12 }) {
            ForEach(this.vm.currentResult.definitions, (def: Definition, index: number) => {
              Column({ space: 4 }) {
                Text(def.partOfSpeech)
                  .fontSize(this.scaleFontSize(14))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(HarmonyColors.primary)

                Text(String(index + 1) + '. ' + def.meaning)
                  .fontSize(this.scaleFontSize(15))
                  .fontColor(this.colors.textPrimary)
                  .lineHeight(22)
              }
              .width('100%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.03)')
            }, (def: Definition, index: number) => def.partOfSpeech + index)
          }
          .width('100%')

          if (this.vm.currentResult.examples && this.vm.currentResult.examples.length > 0) {
            Column({ space: 8 }) {
              Text('例句')
                .fontSize(this.scaleFontSize(16))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.colors.textPrimary)

              ForEach(this.vm.currentResult.examples, (example: Example) => {
                Column({ space: 4 }) {
                  Text(example.sentence)
                    .fontSize(this.scaleFontSize(14))
                    .fontColor(this.colors.textPrimary)
                    .fontStyle(FontStyle.Italic)

                  Text(example.translation || '')
                    .fontSize(this.scaleFontSize(13))
                    .fontColor(this.colors.textSecondary)
                }
                .width('100%')
                .padding(12)
                .borderRadius(8)
                .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.03)')
              }, (example: Example, index: number) => example.sentence + index)
            }
            .width('100%')
          }

          if (this.vm.currentResult.synonyms && this.vm.currentResult.synonyms.length > 0) {
            Row({ space: 8 }) {
              Text('同义词：')
                .fontSize(this.scaleFontSize(14))
                .fontColor(this.colors.textSecondary)

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.vm.currentResult.synonyms, (word: string) => {
                  Text(word)
                    .fontSize(this.scaleFontSize(13))
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#007DFF20')
                    .fontColor(HarmonyColors.primary)
                    .borderRadius(4)
                    .margin({ right: 6, bottom: 4 })
                    .onClick(() => {
                      this.vm.searchWord = word;
                      this.searchWordAction();
                    })
                }, (word: string) => word)
              }
              .layoutWeight(1)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
  }

  @Builder
  HistoryCard() {
    Column({ space: 12 }) {
      Row() {
        Text('搜索历史')
          .fontSize(this.scaleFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        Blank()

        Text('清除')
          .fontSize(this.scaleFontSize(14))
          .fontColor(this.colors.textHint)
          .onClick(() => {
            this.vm.searchHistory = [];
            preferenceManager.setValue('dictionary_history', '');
          })
      }

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.vm.searchHistory, (word: string) => {
          Text(word)
            .fontSize(this.scaleFontSize(14))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)')
            .fontColor(this.colors.textPrimary)
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.vm.searchWord = word;
              this.searchWordAction();
            })
        }, (word: string) => word)
      }
    }
    .width('100%')
    .padding(16)
  }
}
