import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
// 鐢熻瘝鏈�〉锟?- 楦胯挋鍘熺敓椋庢牸
// 鍔熻兘锛氬睍绀恒€佹悳绱€€佹帓搴忋€佺�鐞嗙敓璇嶆湰涓�殑鍗曡瘝


import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, AppColors } from '../core/utils/AppTheme';
import { getDarkModeColors, IDarkModeColors, HarmonyColors } from '../core/utils/HarmonyDesignTokens';
import { advancedNoteManager, WordBookItem } from '../core/models/AdvancedReading';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

/**
 * 鐢熻瘝鏈�〉闈㈢粍锟?
 * 灞曠ず鐢ㄦ埛鏀惰棌鐨勫崟璇嶅垪琛�紝鏀�寔鎼滅储銆佹帓搴忋€佹爣璁板凡鎺屾彙銆佸垹闄ょ瓑鍔熻兘
 */
@Entry
@Component
export default struct WordBookPage {
  /** 鏄�惁涓烘繁鑹叉ā锟?*/
  @State isDarkMode: boolean = false;
  /** 褰撳墠涓婚�棰滆壊闆嗗悎 */
  @State colors: IDarkModeColors = {
    background: '',
    backgroundSecondary: '',
    cardBackground: '',
    textPrimary: '',
    textSecondary: '',
    textHint: '',
    primary: '',
    border: '',
    surface: ''
  };
  /** 瀛椾綋缂╂斁姣斾緥 */
  @State fontScale: number = 1.0;
  /** 鏄�惁涓哄钩鏉胯�锟?*/
  @State isTablet: boolean = false;
  /** 鍔ㄦ€佷富棰橀�锟?*/
  @State currentColors: AppColors = themeManager.getColors();
  @State screenInfo: ScreenInfo | null = null;

  /** 鐢熻瘝鍒楄〃 */
  @State wordList: WordBookItem[] = [];
  /** 鎼滅储鍏抽敭锟?*/
  @State searchKeyword: string = '';
  /** 鎺掑簭鏂瑰紡锛歵ime=鏃堕棿, alpha=瀛楁瘝, mastered=鎺屾彙鐘讹拷?*/
  @State sortBy: string = 'time';
  /** 寰呭垹闄ょ殑鍗曡瘝锛堟湭浣跨敤浣嗕繚鐣欐墿灞曪級 */
  @State selectedWord: WordBookItem | null = null;
  /** 鏄�惁鏄剧ず鍒犻櫎纭��瀵硅瘽锟?*/
  @State showDeleteConfirm: boolean = false;
  /** 寰呭垹闄ょ殑鍗曡瘝锟?*/
  @State wordToDelete: string = '';

  /**
   * 缁勪欢鎸傝浇鏃跺垵濮嬪寲
   */
  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      logger.info('WordBookPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.colors = getDarkModeColors(this.isDarkMode);
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);

    this.loadWordBook();
  }

  /**
   * 鏍规嵁瀛椾綋缂╂斁鍜岃�澶囩被鍨嬭�绠楀疄闄呭瓧浣撳ぇ锟?
   * @param baseSize 鍩虹�瀛椾綋澶у皬
   * @returns 缂╂斁鍚庣殑瀛椾綋澶у皬
   */
  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * this.fontScale * tabletMultiplier);
  }

  /**
   * 鍔犺浇鐢熻瘝鏈�暟锟?
   */
  private loadWordBook(): void {
    const wordBook = advancedNoteManager.getWordBook();
    this.wordList = wordBook;
    this.sortWordList();
  }

  /**
   * 鏍规嵁褰撳墠鎺掑簭鏂瑰紡瀵瑰崟璇嶅垪琛ㄨ繘琛屾帓锟?
   */
  private sortWordList(): void {
    const newList = this.wordList.slice();
    if (this.sortBy === 'time') {
      newList.sort((a: WordBookItem, b: WordBookItem) => {
        const timeA = a.addTime !== undefined ? a.addTime : 0;
        const timeB = b.addTime !== undefined ? b.addTime : 0;
        return timeB - timeA;
      });
    } else if (this.sortBy === 'alpha') {
      newList.sort((a: WordBookItem, b: WordBookItem) => a.word.localeCompare(b.word));
    } else if (this.sortBy === 'mastered') {
      newList.sort((a: WordBookItem, b: WordBookItem) => {
        const masteredA = a.mastered ? 1 : 0;
        const masteredB = b.mastered ? 1 : 0;
        return masteredA - masteredB;
      });
    }
    this.wordList = newList;
  }

  /**
   * 鏍规嵁鎼滅储鍏抽敭璇嶈繃婊ゅ崟璇嶅垪锟?
   * @returns 杩囨护鍚庣殑鍗曡瘝鍒楄〃
   */
  private getFilteredWords(): WordBookItem[] {
    if (!this.searchKeyword.trim()) {
      return this.wordList;
    }
    const keyword = this.searchKeyword.toLowerCase();
    const result: WordBookItem[] = [];
    for (let i = 0; i < this.wordList.length; i++) {
      const word = this.wordList[i];
      const wordLower = word.word.toLowerCase();
      if (wordLower.indexOf(keyword) >= 0) {
        result.push(word);
        continue;
      }
      // 妫€鏌ラ噴涔夋槸鍚﹀寘鍚�叧閿�瘝
      if (word.definitions !== undefined && word.definitions.length > 0) {
        let hasMatch = false;
        for (let j = 0; j < word.definitions.length; j++) {
          const def = word.definitions[j];
          if (def.meaning.toLowerCase().indexOf(keyword) >= 0) {
            hasMatch = true;
            break;
          }
        }
        if (hasMatch) {
          result.push(word);
        }
      }
    }
    return result;
  }

  /**
   * 鏍囪�鍗曡瘝涓哄凡鎺屾彙
   * @param word 瑕佹爣璁扮殑鍗曡瘝
   */
  private markAsMastered(word: string): void {
    advancedNoteManager.markWordAsMastered(word);
    this.loadWordBook();
  }

  /**
   * 鏄剧ず鍒犻櫎纭��瀵硅瘽锟?
   * @param word 瑕佸垹闄ょ殑鍗曡瘝
   */
  private deleteWord(word: string): void {
    this.wordToDelete = word;
    this.showDeleteConfirm = true;
  }

  /**
   * 纭��鍒犻櫎鍗曡瘝
   */
  private confirmDelete(): void {
    advancedNoteManager.removeFromWordBook(this.wordToDelete);
    this.showDeleteConfirm = false;
    this.wordToDelete = '';
    this.loadWordBook();
  }

  /**
   * 鏍规嵁娣辫壊妯″紡閫夋嫨棰滆壊锟?
   * @param light 娴呰壊妯″紡棰滆壊
   * @param dark 娣辫壊妯″紡棰滆壊
   * @returns 褰撳墠妯″紡瀵瑰簲鐨勯�锟?
   */
  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鏍规嵁娣辫壊妯″紡閫夋嫨鑳屾櫙鑹诧紙涓巘c鍔熻兘鐩稿悓锛屼繚鐣欎互鍏煎�锟?
   * @param light 娴呰壊妯″紡鑳屾櫙锟?
   * @param dark 娣辫壊妯″紡鑳屾櫙锟?
   * @returns 褰撳墠妯″紡瀵瑰簲鐨勮儗鏅�壊
   */
  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Stack() {
      Column() {
        this.NavBar()
        this.SearchBar()

        if (this.getFilteredWords().length > 0) {
          this.WordList()
        } else {
          this.EmptyState()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.background)

      if (this.showDeleteConfirm) {
        Column() {
          Row()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showDeleteConfirm = false;
            })
          this.DeleteConfirmDialog()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 椤堕儴瀵艰埅锟?
   */
  @Builder
  NavBar() {
    Row() {
      Button() {
        Text('\u2190')
          .fontSize(this.scaleFontSize(20))
          .fontColor(this.colors.textPrimary)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.tc('rgba(0,0,0,0.3)', 'rgba(255,255,255,0.3)'))
      .borderRadius(20)
      .onClick(() => { try { goBack(); } catch(e) { logger.error('back error:', e); } })

      Text('\u751f\u8bcd\u672c')
        .fontSize(this.isTablet ? 22 : 18)
        .fontWeight(600)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text(String(this.wordList.length))
        .fontSize(this.isTablet ? 18 : 14)
        .fontColor(this.colors.textHint)
        .padding({ right: this.isTablet ? 24 : 16 })
    }
    .width('100%')
    .height(this.isTablet ? 64 : 56)
    .padding({ left: this.isTablet ? 24 : 16, right: this.isTablet ? 24 : 16 })
    .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.3)')
  }

  /**
   * 鎼滅储鏍忓拰鎺掑簭鎺у埗
   */
  @Builder
  SearchBar() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Row() {
          Text('\uD83D\uDD0D')
            .fontSize(16)
            .margin({ left: 12 })

          TextInput({ placeholder: '\u641c\u7d22\u5355\u8bcd...' })
            .layoutWeight(1)
            .height(40)
            .fontSize(this.scaleFontSize(14))
            .fontColor(this.colors.textPrimary)
            .placeholderColor(this.colors.textHint)
            .backgroundColor('transparent')
            .onChange((value: string) => {
              this.searchKeyword = value;
            })
        }
        .layoutWeight(1)
        .padding({ left: 8 })
        .borderRadius(20)
        .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)')

        Row({ space: 4 }) {
          Text('\u6392\u5e8f\uff1a')
            .fontSize(12)
            .fontColor(this.colors.textHint)

          Text(this.sortBy === 'time' ? '\u65f6\u95f4' : (this.sortBy === 'alpha' ? '\u5b57\u6bcd' : '\u638c\u63e1'))
            .fontSize(12)
            .fontColor(HarmonyColors.primary)
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(12)
        .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)')
        .onClick(() => {
          const sorts: string[] = ['time', 'alpha', 'mastered'];
          let currentIndex = -1;
          for (let i = 0; i < sorts.length; i++) {
            if (sorts[i] === this.sortBy) {
              currentIndex = i;
              break;
            }
          }
          if (currentIndex >= 0) {
            this.sortBy = sorts[(currentIndex + 1) % sorts.length];
          }
          this.sortWordList();
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  /**
   * 鍗曡瘝鍒楄〃
   */
  @Builder
  WordList() {
    List() {
      ForEach(this.getFilteredWords(), (word: WordBookItem) => {
        ListItem() {
          this.WordItem(word)
        }
      }, (word: WordBookItem) => word.word)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .divider({ strokeWidth: 0.5, color: this.colors.border, startMargin: 56 })
  }

  /**
   * 鍗曚釜鍗曡瘝锟?
   * @param word 鍗曡瘝鏁版嵁瀵硅薄
   */
  @Builder
  WordItem(word: WordBookItem) {
    Row() {
      Column() {
        if (word.mastered) {
          Text('\u2713')
            .fontSize(16)
            .fontColor('#4CAF50')
        } else {
          Text('\u25cb')
            .fontSize(16)
            .fontColor(this.colors.textHint)
        }
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(word.mastered ? 'rgba(76, 175, 80, 0.1)' : (this.isDarkMode ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)'))
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (!word.mastered) {
          this.markAsMastered(word.word);
        }
      })

      Column({ space: 4 }) {
        Text(word.word)
          .fontSize(this.scaleFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        if (word.definitions !== undefined && word.definitions.length > 0) {
          Text(word.definitions[0].meaning)
            .fontSize(this.scaleFontSize(13))
            .fontColor(this.colors.textSecondary)
            .maxLines(1)
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      Text('\uD83D\uDDD1')
        .fontSize(18)
        .padding(8)
        .onClick(() => {
          this.deleteWord(word.word);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  /**
   * 绌虹姸鎬佹彁锟?
   */
  @Builder
  EmptyState() {
    Column() {
      Text('\u8bcd')
        .fontSize(64)
        .fontWeight(FontWeight.Bold)

      Text('\u751f\u8bcd\u672c\u4e3a\u7a7a')
        .fontSize(this.scaleFontSize(18))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ top: 16 })

      Text('\u5728\u9605\u8bfb\u65f6\u67e5\u8be2\u5355\u8bcd\uff0c\u53ef\u4ee5\u6dfb\u52a0\u5230\u751f\u8bcd\u672c')
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.colors.textSecondary)
        .margin({ top: 8 })

      Button('\u53bb\u67e5\u8be2')
        .height(44)
        .padding({ left: 32, right: 32 })
        .backgroundColor(HarmonyColors.primary)
        .fontColor('#FFFFFF')
        .fontSize(this.scaleFontSize(14))
        .borderRadius(22)
        .margin({ top: 24 })
        .onClick(() => {
          try { navigateTo.push('DictionaryPage'); } catch(e) { logger.error('pushUrl error:', e instanceof Error ? e.message : String(e)); }
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 鍒犻櫎纭��瀵硅瘽锟?
   */
  @Builder
  DeleteConfirmDialog() {
    Column() {
      Text('\u5220\u9664\u786e\u8ba4')
        .fontSize(this.scaleFontSize(18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)

      Text('\u786e\u5b9a\u8981\u4ece\u751f\u8bcd\u672c\u4e2d\u5220\u9664 "' + this.wordToDelete + '" \u5417\uff1f')
        .fontSize(this.scaleFontSize(14))
        .fontColor(this.colors.textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })

      Row({ space: 16 }) {
        Button('\u53d6\u6d88')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)')
          .fontColor(this.colors.textPrimary)
          .borderRadius(22)
          .onClick(() => {
            this.showDeleteConfirm = false;
          })

        Button('\u5220\u9664')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#E53935')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .onClick(() => {
            this.confirmDelete();
          })
      }
      .margin({ top: 24 })
    }
    .width('80%')
    .padding(24)
    .backgroundColor(this.isDarkMode ? 'rgba(40, 40, 40, 0.95)' : 'rgba(255, 255, 255, 0.95)')
    .borderRadius(16)
  }
}

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct WordBookPagePreview {
  build() {
    Column() {
      Text('鐢熻瘝鏈�〉 - 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      WordBookPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鐢熻瘝鏈�〉 - 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      WordBookPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
