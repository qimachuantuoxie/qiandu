import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
// 甯�姪涓�績椤甸潰 - 鍗冭�闃呯晫
// Help Center Page - QianDu YueJie


import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { BackButton } from '../components/common/BackButton';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

/**
 * 甯�姪椤规帴锟?
 */
interface HelpItem {
  question: string;
  answer: string;
}

/**
 * 甯�姪鍒嗙被鎺ュ彛
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
  @State screenInfo: ScreenInfo | null = null;

  /**
   * 甯�姪鍒嗙被鍒楄〃
   */
  private helpCategories: HelpCategory[] = [
    { key: 'gettingStarted', label: '蹇�€熷叆锟?, icon: 'arrow_up_right_circle', color: COMMON_COLORS.PRIMARY_BLUE },
    { key: 'import', label: '瀵煎叆涔︾睄', icon: 'book_spread', color: COMMON_COLORS.SUCCESS_GREEN },
    { key: 'reading', label: '闃呰�鍔熻兘', icon: 'books_vertical_fill', color: COMMON_COLORS.WARNING_ORANGE },
    { key: 'settings', label: '璁剧疆鎸囧崡', icon: 'gearshape_2', color: COMMON_COLORS.PURPLE },
    { key: 'account', label: '璐﹀彿鐩稿叧', icon: 'person_crop_circle', color: COMMON_COLORS.PRIMARY_BLUE }
  ];

  /**
   * 蹇�€熷叆闂ㄩ棶棰樺垪锟?
   */
  private helpItemsGettingStarted: HelpItem[] = [
    {
      question: '濡備綍寮€濮嬩娇鐢ㄥ崈璇婚槄鐣岋紵',
      answer: '棣栨�浣跨敤鏃讹紝鎮ㄥ彲浠ラ€氳繃鐧诲綍椤甸潰鐧诲綍璐﹀彿锛屾垨閫夋嫨"璺宠繃"鐩存帴杩涘叆涔︽灦銆傜偣鍑诲彸涓嬭�锟?+"鎸夐挳鍙�互瀵煎叆鏈�湴鐢靛瓙涔︽枃浠讹拷?
    },
    {
      question: '鏀�寔鍝�簺鐢靛瓙涔︽牸寮忥紵',
      answer: '鍗冭�闃呯晫鏀�寔澶氱�涓绘祦鐢靛瓙涔︽牸寮忥紝鍖呮嫭锛欵PUB銆丳DF銆乀XT銆丮OBI銆丏OCX 绛夊父瑙佹牸寮忥拷?
    },
    {
      question: '濡備綍鑾峰彇鏇村�涔︾睄锟?,
      answer: '鎮ㄥ彲浠ラ€氳繃浠ヤ笅鏂瑰紡鑾峰彇涔︾睄锛歕n1) 浠庢湰鍦板�鍏ュ凡涓嬭浇鐨勭數瀛愪功\n2) 浣跨敤涔︽簮绠＄悊娣诲姞鍦ㄧ嚎涔︽簮\n3) 璁块棶涔︽簮甯傚満鎼滅储鏇村�璧勬簮'
    }
  ];

  /**
   * 瀵煎叆涔︾睄闂��鍒楄〃
   */
  private helpItemsImport: HelpItem[] = [
    {
      question: '濡備綍瀵煎叆鏈�湴涔︾睄锟?,
      answer: '鐐瑰嚮涔︽灦椤甸潰鍙充笅瑙掔殑"+"鎸夐挳锛岄€夋嫨"浠庢湰鍦板�锟?锛岀劧鍚庡湪鏂囦欢閫夋嫨鍣ㄤ腑閫夋嫨鎮ㄧ殑鐢靛瓙涔︽枃浠躲€傛敮鎸佸崟鏈��鍏ュ拰鎵归噺瀵煎叆锟?
    },
    {
      question: '瀵煎叆鐨勪功绫嶅湪鍝�噷鏌ョ湅锟?,
      answer: '瀵煎叆鐨勪功绫嶄細鑷�姩娣诲姞鍒颁功鏋朵腑銆傛偍鍙�互鍦ㄤ功鏋堕〉闈㈢湅鍒版墍鏈夊凡瀵煎叆鐨勪功绫嶏紝鎸夌収鏈€杩戦槄璇汇€佷功鍚嶃€佷綔鑰呯瓑鏂瑰紡鎺掑簭锟?
    },
    {
      question: '鏀�寔鎵归噺瀵煎叆鍚楋紵',
      answer: '鏄�殑锛屾敮鎸佹壒閲忓�鍏ャ€傚湪鏂囦欢閫夋嫨鍣ㄤ腑锛屾偍鍙�互涓€娆￠€夋嫨澶氭湰涔︾睄杩涜�瀵煎叆锛屾彁楂樻晥鐜囷拷?
    }
  ];

  /**
   * 闃呰�鍔熻兘闂��鍒楄〃
   */
  private helpItemsReading: HelpItem[] = [
    {
      question: '闃呰�鏃跺�浣曠炕椤碉紵',
      answer: '鍦ㄩ槄璇婚〉闈�紝鎮ㄥ彲浠ラ€氳繃浠ヤ笅鏂瑰紡缈婚〉锛歕n1) 鐐瑰嚮灞忓箷锟?鍙充晶鍖哄煙\n2) 婊戝姩灞忓箷\n3) 浣跨敤闊抽噺閿�炕椤碉紙闇€鍦ㄨ�缃�腑寮€鍚�級'
    },
    {
      question: '濡備綍璋冩暣瀛椾綋澶у皬锟?,
      answer: '鍦ㄩ槄璇婚〉闈�紝鐐瑰嚮灞忓箷涓�ぎ鎵撳紑鎺у埗闈㈡澘锛岀偣锟?Aa"鎸夐挳鍙�互璋冩暣瀛椾綋澶у皬銆佽�闂磋窛绛夐槄璇昏�缃�拷?
    },
    {
      question: '濡備綍娣诲姞涔︾�锟?,
      answer: '鍦ㄩ槄璇婚〉闈�紝鐐瑰嚮灞忓箷涓�ぎ鎵撳紑鎺у埗闈㈡澘锛岀偣鍑讳功绛惧浘鏍囧嵆鍙�坊鍔犱功绛俱€傛偍鍙�互涓轰功绛炬坊鍔犲�娉�紝鏂逛究鏃ュ悗鏌ユ壘锟?
    },
    {
      question: '濡備綍鍋氱瑪璁帮紵',
      answer: '闀挎寜閫夋嫨鎯宠�鍋氱瑪璁扮殑鏂囨湰锛岀劧鍚庨€夋嫨"绗旇�"閫夐」銆傛偍鍙�互娣诲姞绗旇�鍐呭�銆佹爣绛撅紝鏂逛究鏃ュ悗澶嶄範鏁寸悊锟?
    },
    {
      question: '鏀�寔鏈楄�鍔熻兘鍚楋紵',
      answer: '鏄�殑锛屽崈璇婚槄鐣屾敮?TTS 璇�煶鏈楄�鍔熻兘銆傚湪闃呰�椤甸潰鎵撳紑鎺у埗闈㈡澘锛岀偣鍑昏€虫満鍥炬爣鍗冲彲寮€鍚�湕璇汇€傛敮鎸佽皟鑺傝�閫熴€侀煶璋冪瓑鍙傛暟锟?
    }
  ];

  /**
   * 璁剧疆鎸囧崡闂��鍒楄〃
   */
  private helpItemsSettings: HelpItem[] = [
    {
      question: '濡備綍鏇存敼闃呰�涓婚�锟?,
      answer: '鍦ㄩ槄璇婚〉闈�紝鐐瑰嚮灞忓箷涓�ぎ鎵撳紑鎺у埗闈㈡澘锛岀偣鍑讳富棰樺浘鏍囷紝鍙�互鍒囨崲鐧藉ぉ銆佹姢鐪笺€佸�闂寸瓑闃呰�涓婚�锟?
    },
    {
      question: '濡備綍澶囦唤鏁版嵁锟?,
      answer: '鎮ㄥ彲浠ュ湪璁剧疆椤甸潰鎵惧埌"鏁版嵁澶囦唤"閫夐」锛屾敮鎸佸皢涔︽灦銆侀槄璇昏繘搴︺€佷功绛剧瑪璁扮瓑鏁版嵁瀵煎嚭澶囦唤鍒版湰鍦版垨浜戠�锟?
    },
    {
      question: '濡備綍娓呯悊缂撳瓨锟?,
      answer: '鍦ㄨ�缃�〉闈㈢殑"瀛樺偍璁剧疆"涓�紝鎮ㄥ彲浠ユ煡鐪嬪綋鍓嶇紦瀛樺ぇ灏忥紝骞朵竴閿�竻鐞嗐€傛竻鐞嗙紦瀛樹笉浼氬奖鍝嶆偍鐨勪功绫嶅拰闃呰�鏁版嵁锟?
    }
  ];

  /**
   * 璐﹀彿鐩稿叧闂��鍒楄〃
   */
  private helpItemsAccount: HelpItem[] = [
    {
      question: '闇€瑕佺櫥褰曟墠鑳戒娇鐢ㄥ悧锟?,
      answer: '涓嶉渶瑕併€傛偍鍙�互鐩存帴璺宠繃鐧诲綍浣跨敤鍩虹�鍔熻兘銆傜櫥褰曡处鍙峰彲浠ヤ韩鍙椾簯绔�悓姝ャ€乂IP 鐗规潈绛夐珮绾у姛鑳斤拷?
    },
    {
      question: '濡備綍淇�敼涓�汉淇℃伅锟?,
      answer: '鐧诲綍鍚庯紝锟?鎴戠殑"椤甸潰鐐瑰嚮澶村儚鍖哄煙锛屽彲浠ヤ慨鏀规樀绉般€佸ご鍍忕瓑涓�汉淇℃伅锟?
    },
    {
      question: '濡備綍閫€鍑虹櫥褰曪紵',
      answer: '锟?鎴戠殑"椤甸潰锛岀偣鍑诲彸涓婅�璁剧疆鍥炬爣锛屾壘锟?閫€鍑虹櫥锟?閫夐」鍗冲彲銆傞€€鍑虹櫥褰曚笉浼氬垹闄ゆ湰鍦版暟鎹�拷?
    }
  ];

  /**
   * 椤甸潰鍒濆�锟?
   */
  aboutToAppear(): void {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      const context: common.Context = this.getUIContext().getHostContext() as common.Context;
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
      preferenceManager.init(context);
      appTheme.init(context);
      await fontScaleManager.init(context);
      DeviceUtils.init();
    } catch (error) {
      logger.info('HelpPage context init skipped');
    }

    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    this.isTablet = DeviceUtils.isTablet() || (this.screenInfo?.isTablet ?? false);
  }

  /**
   * 鏍规嵁涓婚�鑾峰彇鏂囧瓧棰滆壊
   */
  private getTextColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鏍规嵁涓婚�鑾峰彇鑳屾櫙锟?
   */
  private getBgColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  /**
   * 鑾峰彇褰撳墠鍒嗙被鐨勫府鍔╅」
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
   * 鑾峰彇褰撳墠鍒嗙被鐨勯�锟?
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
   * 椤甸潰涓讳綋鏋勫缓
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
        .padding(Spacing.lg)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F7')
  }

  /**
   * 椤堕儴瀵艰埅锟?
   */
  @Builder
  Header() {
    Row() {
      BackButton({ isDarkMode: this.isDarkMode, colors: this.getTextColor('#333333', '#FFFFFF') })

      Text('甯�姪涓�績')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextColor('#333333', '#FFFFFF'))
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getTextColor('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('路路路')
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
   * 鍒嗙被閫夋嫨锟?
   */
  @Builder
  CategorySelector() {
    Column() {
      Text('甯歌�闂��')
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
    .padding(Spacing.lg)
    .backgroundColor(this.getBgColor('#FFFFFF', '#2C2C2E'))
    .borderRadius(BorderRadius.lg)
  }

  /**
   * 鍒嗙被锟?
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
   * 闂��鍗＄墖
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
        .borderRadius(BorderRadius.sm)

        Text(item.question)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .alignSelf(ItemAlign.Start)

        Text(this.expandedIndex === index ? '锟? : '锟?)
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
    .padding(Spacing.lg)
    .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#FFFFFF')
    .borderRadius(BorderRadius.lg)
    .onClick((): void => {
      this.expandedIndex = this.expandedIndex === index ? -1 : index
    })
  }

  /**
   * 绛旀�鍖哄煙
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

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct HelpPagePreview {
  build() {
    Column() {
      Text('甯�姪涓�績锟?- 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      HelpPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('甯�姪涓�績锟?- 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      HelpPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
