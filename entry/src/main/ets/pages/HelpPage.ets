// 帮助中心页面 - 千读阅界
// Help Center Page - QianDu YueJie

import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';
import { fontScaleManager } from '../utils/FontScaleManager';

/**
 * 帮助项接口
 */
interface HelpItem {
  question: string;
  answer: string;
}

/**
 * 帮助分类接口
 */
interface HelpCategory {
  key: string;
  label: string;
  icon: string;
  color: string;
}

@Entry
@Component
struct HelpPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State isTablet: boolean = false;
  @State selectedCategory: string = 'gettingStarted';
  @State expandedIndex: number = -1;

  /**
   * 帮助分类列表
   */
  private helpCategories: HelpCategory[] = [
    { key: 'gettingStarted', label: '快速入门', icon: '🚀', color: COMMON_COLORS.PRIMARY_BLUE },
    { key: 'import', label: '导入书籍', icon: '📖', color: COMMON_COLORS.SUCCESS_GREEN },
    { key: 'reading', label: '阅读功能', icon: '📚', color: COMMON_COLORS.WARNING_ORANGE },
    { key: 'settings', label: '设置指南', icon: '⚙️', color: COMMON_COLORS.PURPLE },
    { key: 'account', label: '账号相关', icon: '👤', color: COMMON_COLORS.PRIMARY_BLUE }
  ];

  /**
   * 快速入门问题列表
   */
  private helpItemsGettingStarted: HelpItem[] = [
    {
      question: '如何开始使用千读阅界？',
      answer: '首次使用时，您可以通过登录页面登录账号，或选择"跳过"直接进入书架。点击右下角的"+"按钮可以导入本地电子书文件。'
    },
    {
      question: '支持哪些电子书格式？',
      answer: '千读阅界支持多种主流电子书格式，包括：EPUB、PDF、TXT、MOBI、DOCX 等常见格式。'
    },
    {
      question: '如何获取更多书籍？',
      answer: '您可以通过以下方式获取书籍：\n1) 从本地导入已下载的电子书\n2) 使用书源管理添加在线书源\n3) 访问书源市场搜索更多资源'
    }
  ];

  /**
   * 导入书籍问题列表
   */
  private helpItemsImport: HelpItem[] = [
    {
      question: '如何导入本地书籍？',
      answer: '点击书架页面右下角的"+"按钮，选择"从本地导入"，然后在文件选择器中选择您的电子书文件。支持单本导入和批量导入。'
    },
    {
      question: '导入的书籍在哪里查看？',
      answer: '导入的书籍会自动添加到书架中。您可以在书架页面看到所有已导入的书籍，按照最近阅读、书名、作者等方式排序。'
    },
    {
      question: '支持批量导入吗？',
      answer: '是的，支持批量导入。在文件选择器中，您可以一次选择多本书籍进行导入，提高效率。'
    }
  ];

  /**
   * 阅读功能问题列表
   */
  private helpItemsReading: HelpItem[] = [
    {
      question: '阅读时如何翻页？',
      answer: '在阅读页面，您可以通过以下方式翻页：\n1) 点击屏幕左/右侧区域\n2) 滑动屏幕\n3) 使用音量键翻页（需在设置中开启）'
    },
    {
      question: '如何调整字体大小？',
      answer: '在阅读页面，点击屏幕中央打开控制面板，点击"Aa"按钮可以调整字体大小、行间距等阅读设置。'
    },
    {
      question: '如何添加书签？',
      answer: '在阅读页面，点击屏幕中央打开控制面板，点击书签图标即可添加书签。您可以为书签添加备注，方便日后查找。'
    },
    {
      question: '如何做笔记？',
      answer: '长按选择想要做笔记的文本，然后选择"笔记"选项。您可以添加笔记内容、标签，方便日后复习整理。'
    },
    {
      question: '支持朗读功能吗？',
      answer: '是的，千读阅界支持 TTS 语音朗读功能。在阅读页面打开控制面板，点击耳机图标即可开启朗读。支持调节语速、音调等参数。'
    }
  ];

  /**
   * 设置指南问题列表
   */
  private helpItemsSettings: HelpItem[] = [
    {
      question: '如何更改阅读主题？',
      answer: '在阅读页面，点击屏幕中央打开控制面板，点击主题图标，可以切换白天、护眼、夜间等阅读主题。'
    },
    {
      question: '如何备份数据？',
      answer: '您可以在设置页面找到"数据备份"选项，支持将书架、阅读进度、书签笔记等数据导出备份到本地或云端。'
    },
    {
      question: '如何清理缓存？',
      answer: '在设置页面的"存储设置"中，您可以查看当前缓存大小，并一键清理。清理缓存不会影响您的书籍和阅读数据。'
    }
  ];

  /**
   * 账号相关问题列表
   */
  private helpItemsAccount: HelpItem[] = [
    {
      question: '需要登录才能使用吗？',
      answer: '不需要。您可以直接跳过登录使用基础功能。登录账号可以享受云端同步、VIP 特权等高级功能。'
    },
    {
      question: '如何修改个人信息？',
      answer: '登录后，在"我的"页面点击头像区域，可以修改昵称、头像等个人信息。'
    },
    {
      question: '如何退出登录？',
      answer: '在"我的"页面，点击右上角设置图标，找到"退出登录"选项即可。退出登录不会删除本地数据。'
    }
  ];

  /**
   * 页面初始化
   */
  aboutToAppear(): void {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context: common.Context = this.getUIContext().getHostContext() as common.Context;
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      console.info('HelpPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet();
  }

  /**
   * 根据主题获取文字颜色
   */
  private getTextColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 根据主题获取背景色
   */
  private getBgColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 获取当前分类的帮助项
   */
  private getCurrentHelpItems(): HelpItem[] {
    if (this.selectedCategory === 'gettingStarted') {
      return this.helpItemsGettingStarted;
    }
    if (this.selectedCategory === 'import') {
      return this.helpItemsImport;
    }
    if (this.selectedCategory === 'reading') {
      return this.helpItemsReading;
    }
    if (this.selectedCategory === 'settings') {
      return this.helpItemsSettings;
    }
    if (this.selectedCategory === 'account') {
      return this.helpItemsAccount;
    }
    return [];
  }

  /**
   * 获取当前分类的颜色
   */
  private getCurrentCategoryColor(): string {
    let result: string = COMMON_COLORS.PRIMARY_BLUE;
    for (let i: number = 0; i < this.helpCategories.length; i++) {
      if (this.helpCategories[i].key === this.selectedCategory) {
        result = this.helpCategories[i].color;
        break;
      }
    }
    return result;
  }

  /**
   * 页面主体构建
   */
  build() {
    Column() {
      this.Header()

      Scroll() {
        Column() {
          this.CategorySelector()

          ForEach(this.getCurrentHelpItems(), (item: HelpItem, index: number): void => {
            this.QuestionCard(item, index)
          }, (item: HelpItem, index: number): string => {
            return item.question + index.toString()
          })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F7')
  }

  /**
   * 顶部导航栏
   */
  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(28)
        .fontColor(this.getTextColor('#333333', '#FFFFFF'))
        .fontWeight(FontWeight.Medium)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getTextColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
        .borderRadius(22)
        .onClick((): void => {
          router.back()
        })

      Text('帮助中心')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getTextColor('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('···')
        .fontSize(14)
        .fontColor(this.getTextColor('#333333', '#FFFFFF'))
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getBgColor('#FFFFFF', '#1C1C1E'))
  }

  /**
   * 分类选择器
   */
  @Builder
  CategorySelector() {
    Column() {
      Text('常见问题')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextColor('#1A1A1A', '#FFFFFF'))
        .width('100%')
        .padding({ left: 4, bottom: 8 })

      Scroll() {
        Row() {
          ForEach(this.helpCategories, (category: HelpCategory): void => {
            this.CategoryItem(category)
          }, (category: HelpCategory): string => {
            return category.key
          })
        }
        .padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.getBgColor('#FFFFFF', '#2C2C2E'))
    .borderRadius(16)
  }

  /**
   * 分类项
   */
  @Builder
  CategoryItem(category: HelpCategory) {
    Column() {
      Column() {
        Text(category.icon)
          .fontSize(24)
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.selectedCategory === category.key
        ? category.color + '20'
        : this.getTextColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.06)'))
      .borderRadius(14)
      .border({
        width: 2,
        color: this.selectedCategory === category.key ? category.color : 'transparent'
      })

      Text(category.label)
        .fontSize(11)
        .fontColor(this.selectedCategory === category.key
          ? category.color
          : this.getTextColor('#999999', '#888888'))
    }
    .onClick((): void => {
      this.selectedCategory = category.key
      this.expandedIndex = -1
    })
  }

  /**
   * 问题卡片
   */
  @Builder
  QuestionCard(item: HelpItem, index: number) {
    Column() {
      Row() {
        Column() {
          Text('Q' + (index + 1).toString())
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.getCurrentCategoryColor())
        .borderRadius(8)

        Text(item.question)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .alignSelf(ItemAlign.Start)

        Text(this.expandedIndex === index ? '▼' : '▶')
          .fontSize(12)
          .fontColor(this.isDarkMode ? '#666666' : '#CCCCCC')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.expandedIndex === index) {
        this.AnswerSection(item.answer)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(16)
    .onClick((): void => {
      this.expandedIndex = this.expandedIndex === index ? -1 : index
    })
  }

  /**
   * 答案区域
   */
  @Builder
  AnswerSection(answer: string) {
    Column() {
      Divider()
        .color(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
        .margin({ top: 12, bottom: 12 })

      Text(answer)
        .fontSize(14)
        .fontColor(this.getTextColor('#666666', '#AAAAAA'))
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
