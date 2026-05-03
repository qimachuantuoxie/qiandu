// 生词本页面 - 鸿蒙原生风格
// 功能：展示、搜索、排序、管理生词本中的单词

import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { getDarkModeColors, IDarkModeColors, HarmonyColors } from '../utils/HarmonyDesignTokens';
import { advancedNoteManager, WordBookItem } from '../models/AdvancedReading';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';

/**
 * 生词本页面组件
 * 展示用户收藏的单词列表，支持搜索、排序、标记已掌握、删除等功能
 */
@Entry
@Component
export default struct WordBookPage {
  /** 是否为深色模式 */
  @State isDarkMode: boolean = false;
  /** 当前主题颜色集合 */
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
  /** 字体缩放比例 */
  @State fontScale: number = 1.0;
  /** 是否为平板设备 */
  @State isTablet: boolean = false;
  /** 动态主题颜色 */
  @State currentColors: AppColors = themeManager.getColors();

  /** 生词列表 */
  @State wordList: WordBookItem[] = [];
  /** 搜索关键词 */
  @State searchKeyword: string = '';
  /** 排序方式：time=时间, alpha=字母, mastered=掌握状态 */
  @State sortBy: string = 'time';
  /** 待删除的单词（未使用但保留扩展） */
  @State selectedWord: WordBookItem | null = null;
  /** 是否显示删除确认对话框 */
  @State showDeleteConfirm: boolean = false;
  /** 待删除的单词名 */
  @State wordToDelete: string = '';

  /**
   * 组件挂载时初始化
   */
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
      console.info('WordBookPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.colors = getDarkModeColors(this.isDarkMode);
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet();

    this.loadWordBook();
  }

  /**
   * 根据字体缩放和设备类型计算实际字体大小
   * @param baseSize 基础字体大小
   * @returns 缩放后的字体大小
   */
  private scaleFontSize(baseSize: number): number {
    const tabletMultiplier = this.isTablet ? 1.2 : 1.0;
    return Math.round(baseSize * this.fontScale * tabletMultiplier);
  }

  /**
   * 加载生词本数据
   */
  private loadWordBook(): void {
    const wordBook = advancedNoteManager.getWordBook();
    this.wordList = wordBook;
    this.sortWordList();
  }

  /**
   * 根据当前排序方式对单词列表进行排序
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
   * 根据搜索关键词过滤单词列表
   * @returns 过滤后的单词列表
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
      // 检查释义是否包含关键词
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
   * 标记单词为已掌握
   * @param word 要标记的单词
   */
  private markAsMastered(word: string): void {
    advancedNoteManager.markWordAsMastered(word);
    this.loadWordBook();
  }

  /**
   * 显示删除确认对话框
   * @param word 要删除的单词
   */
  private deleteWord(word: string): void {
    this.wordToDelete = word;
    this.showDeleteConfirm = true;
  }

  /**
   * 确认删除单词
   */
  private confirmDelete(): void {
    advancedNoteManager.removeFromWordBook(this.wordToDelete);
    this.showDeleteConfirm = false;
    this.wordToDelete = '';
    this.loadWordBook();
  }

  /**
   * 根据深色模式选择颜色值
   * @param light 浅色模式颜色
   * @param dark 深色模式颜色
   * @returns 当前模式对应的颜色
   */
  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 根据深色模式选择背景色（与tc功能相同，保留以兼容）
   * @param light 浅色模式背景色
   * @param dark 深色模式背景色
   * @returns 当前模式对应的背景色
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
   * 顶部导航栏
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
      .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })

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
   * 搜索栏和排序控制
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
   * 单词列表
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
   * 单个单词项
   * @param word 单词数据对象
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
   * 空状态提示
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
          try { router.pushUrl({ url: 'pages/DictionaryPage' }); } catch(e) { console.error('pushUrl error:', e); }
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 删除确认对话框
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
