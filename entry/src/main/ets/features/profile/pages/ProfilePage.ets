import { logger } from '../../../common/utils/Logger';
// 濞戞搩浜欏Ч澶嬬▔椤撶偟濡囧�銈囨暬閿?- 閻忕偞娲滈妵姘舵偨閵婏箑鐓曞ǎ鍥ｅ墲娴煎懘宕�畝鍕�潐閻犲洨绮�弳鐔煎箲?
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { profileViewModel, ProfileViewModel } from '../viewmodels/ProfileViewModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface ProfileMenuItem {
  icon: string;
  titleKey: string;
  title?: string;
  subtitleKey?: string;
  subtitle?: string;
  action: () => void;
}

@Entry
@Component
struct ProfilePage {
  // UI 闁硅矇鍐ㄧ厬闁绘ǹ鍩栭敓?
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State screenInfo: ScreenInfo | null = null;
  // ViewModel (閻╁瓨甯村�鏇犳暏@ObservedV2閸楁洑绶?ViewModel)
  private vm: ProfileViewModel = profileViewModel;

  aboutToAppear() {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
    this.fontScale = await fontScaleManager.getFontScale();
    await this.vm.loadProfile();
  }

  private getFontSize(base: number): number {
    return fontScaleManager.getScaledFontSize(base);
  }

  /**
   * 闁哄洤鐡ㄩ弻濠囨偨閵婏箑鐓曞�鑸垫綑閿?
   */
  private updateAvatar(): void {
    promptAction.showToast({
      message: '濠㈣埖娼欓崕姘跺即鐎涙ɑ鐓€闁告梻鍠曢崗妯侯嚕閳ь剟宕ｉ幋婊嗗幀',
      duration: 1500
    });
  }

  build() {
    Stack() {
      Column() {
        // 濡炪倕鐖奸崕鎾�嚄鐏炵偓鐝?
        this.HeaderBackground()

        Scroll() {
          Column({ space: 16 }) {
            // 闁活潿鍔嶉崺娑欑┍閳╁啩绱栭柛妤嬬磿閿?
            this.UserInfoCard()

            // 闂傚啫鎳撻�鎵�磼閻旀椿鍚€闁告�绱曢敓?
            this.ReadingStatsCard()

            // 闁告梻鍠曢崗姗€鎳ｅ⿰鍐ㄧ�闁告帗顨夐敓?
            this.MenuList()

            // 閹煎瓨娲熼崕鎾�⒒绾惧�鐛?
            Column().height(40)
          }
          .width('100%')
          .padding(Spacing.lg)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDarkMode ? '#141414' : '#FAFAFA')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeaderBackground() {
    Column()
      .width('100%')
      .height(200)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.isDarkMode 
          ? [['#1C1C1E', 0.0], ['#2C2C2E', 1.0]]
          : [[COMMON_COLORS.PRIMARY_BLUE, 0.0], ['#5B8DEF', 1.0]]
      })
      .position({ top: 0 })
  }

  @Builder
  UserInfoCard() {
    Column() {
      if (this.vm.userInfo) {
        Row({ space: Spacing.lg }) {
          // 濠㈣埖娼欓敓?
          Stack() {
            if (this.vm.userInfo.avatar && this.vm.userInfo.avatar.length > 0) {
              Image(this.vm.userInfo.avatar)
                .width(Size.avatarXL)
                .height(Size.avatarXL)
                .borderRadius(BorderRadius.full)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                Text('妫ｅ啯鍣?)
                  .fontSize(Size.iconXXL)
              }
              .width(Size.avatarXL)
              .height(Size.avatarXL)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.3)')
              .borderRadius(BorderRadius.full)
            }

            // 缂傚倹鐗炵欢顐﹀炊閻愵剛鍨?
            Column() {
              Text('妫ｅ啯鎳?)
                .fontSize(Size.iconSM)
            }
            .width(Size.iconLG)
            .height(Size.iconLG)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(BorderRadius.full)
            .position({ x: 50, y: 50 })
          }
          .onClick(() => this.updateAvatar())

          // 闁活潿鍔嶉崺娑欑┍閳╁啩绱?
          Column({ space: Spacing.sm }) {
            Text(this.vm.userInfo.nickname || this.vm.userInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDarkMode ? '#FFFFFF' : '#FFFFFF')

            Row({ space: 8 }) {
              Text('ID: ')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')

              Text(this.vm.userInfo.userId)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.9)')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(Spacing.xl)
      }
    }
    .width('100%')
    // 婵�絾绋撻獮鎾绘偣閸愨晜娅忛敓?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.7)' : 'rgba(255,255,255,0.75)')
    .backdropBlur(20)
    .borderRadius(BorderRadius.lg)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.5)'
    })
    .shadow({
      radius: 16,
      color: 'rgba(0,0,0,0.12)',
      offsetY: 6
    })
    .offset({ y: -40 })
  }

  @Builder
  ReadingStatsCard() {
    Column({ space: 16 }) {
      Text('闂傚啫鎳撻�鎵�磼閻旀椿鍚€')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .width('100%')

      Grid() {
        GridItem() {
          this.StatItem('Bks', this.vm.totalBooks.toString(), '閹��鍔熼敓?)
        }
        GridItem() {
          this.StatItem('Time', this.vm.formatReadingTime(this.vm.totalReadingTime), '闂冨懓顕伴弮鍫曟毐')
        }
        GridItem() {
          this.StatItem('Marks', this.vm.totalBookmarks.toString(), '娑旓妇顒?)
        }
        GridItem() {
          this.StatItem('Notes', this.vm.totalNotes.toString(), '缁楁棁顔?)
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .height(180)
    }
    .width('100%')
    .padding(Spacing.xl)
    // 婵�絾绋撻獮鎾绘偣閸愨晜娅忛敓?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.6)' : 'rgba(255,255,255,0.7)')
    .backdropBlur(15)
    .borderRadius(BorderRadius.lg)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.4)'
    })
    .shadow({
      radius: 12,
      color: 'rgba(0,0,0,0.08)',
      offsetY: 4
    })
  }

  @Builder
  StatItem(icon: string, value: string, label: string) {
    Column({ space: Spacing.sm }) {
      Text(icon)
        .fontSize(Size.iconXL)

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(12))
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
    .borderRadius(BorderRadius.md)
  }

  @Builder
  MenuList() {
    Column({ space: 0 }) {
      ForEach(this.getMenuItems(), (item: ProfileMenuItem, index: number) => {
        Column() {
          Row({ space: Spacing.lg }) {
            Text(item.icon)
              .fontSize(Size.iconMD)

            Text(item.title)
              .fontSize(15)
              .fontColor(this.isDarkMode ? '#E8E8E8' : '#1A1A1A')
              .layoutWeight(1)

            if (item.subtitle) {
              Text(item.subtitle)
                .fontSize(13)
                .fontColor(this.isDarkMode ? '#888888' : '#999999')
            }

            Text('>')
              .fontSize(Size.iconSM)
              .fontColor(this.isDarkMode ? '#555555' : '#CCCCCC')
          }
          .width('100%')
          .padding(Spacing.lg)
          .onClick(() => item.action())
          .stateStyles({
            pressed: {
              .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.03)')
              .scale({ x: 0.98, y: 0.98 })
            },
            normal: {
              .backgroundColor('transparent')
              .scale({ x: 1, y: 1 })
            }
          })

          // 闁告帒妫濆▓褏鐥�崠锛勭�闁哄牃鍋撻柛姘�凹缁斿瓨銇勯柅娑氱憹闁哄嫬澧介妵姘舵晬?
          if (index < this.getMenuItems().length - 1) {
            Divider()
              .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
              .padding({ left: 52 })
          }
        }
      })
    }
    .width('100%')
    // 婵�絾绋撻獮鎾绘偣閸愨晜娅忛敓?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.6)' : 'rgba(255,255,255,0.7)')
    .backdropBlur(15)
    .borderRadius(BorderRadius.lg)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.4)'
    })
    .shadow({
      radius: 12,
      color: 'rgba(0,0,0,0.08)',
      offsetY: 4
    })
  }

  private getMenuItems(): ProfileMenuItem[] {
    return [
      {
        icon: '妫ｅ啯鎲?,
        titleKey: 'my_bookshelf',
        subtitleKey: 'book_count',
        action: (): void => {
          try {
            goBack();
          } catch (e) {
            logger.error('ProfilePage back failed:', e instanceof Error ? e.message : String(e));
          }
        }
      },
      {
        icon: '妫ｅ啯鎯?,
        titleKey: 'reading_stats',
        action: (): void => {
          navigateTo('pages/StatisticsPage');
        }
      },
      {
        icon: '妫ｅ啯鎲?,
        titleKey: 'reading_notes',
        subtitleKey: 'note_count',
        action: (): void => {
          navigateTo('pages/NotesPage');
        }
      },
      {
        icon: '妫ｅ啯鏅?,
        titleKey: 'bookmark_manage',
        subtitleKey: 'bookmark_count',
        action: (): void => {
          navigateTo('pages/BookmarksPage');
        }
      },
      {
        icon: '閿?,
        titleKey: 'todo_items',
        action: (): void => {
          navigateTo('pages/TodoPage');
        }
      },
      {
        icon: '閿?,
        titleKey: 'read_settings',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 0;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: '閿?,
        titleKey: 'display_settings',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 1;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: '棣冩暋',
        titleKey: 'help_feedback',
        action: (): void => {
          navigateTo('pages/HelpPage');
        }
      },
      {
        icon: '妫ｅ啯鎲?,
        titleKey: 'privacy_policy',
        action: (): void => {
          navigateTo('pages/PrivacyPolicyPage');
        }
      }
    ];
  }
}

// 妫板嫯顫嶇紒鍕�� - 閻€劋绨珼evEco Studio妫板嫯顫嶉敓?
@Preview
@Component
struct ProfilePagePreview {
  build() {
    Column() {
      Text('娑擃亙姹夌挧鍕�灐閿?- 濞村懓澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ProfilePage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('娑擃亙姹夌挧鍕�灐閿?- 濞ｈ精澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      ProfilePage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}

