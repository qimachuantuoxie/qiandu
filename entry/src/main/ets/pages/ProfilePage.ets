// 涓汉涓績椤甸潰 - 灞曠ず鐢ㄦ埛淇℃伅鍜岄槄璇绘暟鎹?
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo } from '../utils/NavigationHelper';
import { preferenceManager } from '../utils/PreferenceManager';
import { profileViewModel, ProfileViewModel } from '../viewmodels/ProfileViewModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';

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
  // UI 鎺у埗鐘舵€?
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  // ViewModel (直接引用@ObservedV2单例 ViewModel)
  private vm: ProfileViewModel = profileViewModel;

  aboutToAppear() {
    this.isDarkMode = appTheme.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
    await this.vm.loadProfile();
  }

  private getFontSize(base: number): number {
    return fontScaleManager.getScaledFontSize(base);
  }

  /**
   * 鏇存柊鐢ㄦ埛澶村儚
   */
  private updateAvatar(): void {
    promptAction.showToast({
      message: '澶村儚鏇存柊鍔熻兘寮€鍙戜腑',
      duration: 1500
    });
  }

  build() {
    Stack() {
      Column() {
        // 椤堕儴鑳屾櫙
        this.HeaderBackground()

        Scroll() {
          Column({ space: 16 }) {
            // 鐢ㄦ埛淇℃伅鍗＄墖
            this.UserInfoCard()

            // 闃呰缁熻鍗＄墖
            this.ReadingStatsCard()

            // 鍔熻兘鑿滃崟鍒楄〃
            this.MenuList()

            // 搴曢儴闂磋窛
            Column().height(40)
          }
          .width('100%')
          .padding(16)
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
        Row({ space: 16 }) {
          // 澶村儚
          Stack() {
            if (this.vm.userInfo.avatar && this.vm.userInfo.avatar.length > 0) {
              Image(this.vm.userInfo.avatar)
                .width(72)
                .height(72)
                .borderRadius(36)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                Text('馃懁')
                  .fontSize(36)
              }
              .width(72)
              .height(72)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.3)')
              .borderRadius(36)
            }

            // 缂栬緫鍥炬爣
            Column() {
              Text('馃摲')
                .fontSize(12)
            }
            .width(24)
            .height(24)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(12)
            .position({ x: 50, y: 50 })
          }
          .onClick(() => this.updateAvatar())

          // 鐢ㄦ埛淇℃伅
          Column({ space: 8 }) {
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
        .padding(20)
      }
    }
    .width('100%')
    // 姣涚幓鐠冩晥鏋?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.7)' : 'rgba(255,255,255,0.75)')
    .backdropBlur(20)
    .borderRadius(16)
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
      Text('闃呰缁熻')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')
        .width('100%')

      Grid() {
        GridItem() {
          this.StatItem('Bks', this.vm.totalBooks.toString(), '总书籍')
        }
        GridItem() {
          this.StatItem('Time', this.vm.formatReadingTime(this.vm.totalReadingTime), '阅读时长')
        }
        GridItem() {
          this.StatItem('Marks', this.vm.totalBookmarks.toString(), '书签')
        }
        GridItem() {
          this.StatItem('Notes', this.vm.totalNotes.toString(), '笔记')
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
    .padding(20)
    // 姣涚幓鐠冩晥鏋?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.6)' : 'rgba(255,255,255,0.7)')
    .backdropBlur(15)
    .borderRadius(16)
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
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)

      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#1A1A1A')

      Text(label)
        .fontSize(12)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
    .borderRadius(12)
  }

  @Builder
  MenuList() {
    Column({ space: 0 }) {
      ForEach(this.getMenuItems(), (item: ProfileMenuItem, index: number) => {
        Column() {
          Row({ space: 16 }) {
            Text(item.icon)
              .fontSize(22)

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
              .fontSize(18)
              .fontColor(this.isDarkMode ? '#555555' : '#CCCCCC')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
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

          // 鍒嗛殧绾匡紙鏈€鍚庝竴椤逛笉鏄剧ず锛?
          if (index < this.getMenuItems().length - 1) {
            Divider()
              .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
              .padding({ left: 52 })
          }
        }
      })
    }
    .width('100%')
    // 姣涚幓鐠冩晥鏋?
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.6)' : 'rgba(255,255,255,0.7)')
    .backdropBlur(15)
    .borderRadius(16)
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
        icon: '馃摉',
        titleKey: 'my_bookshelf',
        subtitleKey: 'book_count',
        action: (): void => {
          try {
            router.back();
          } catch (e) {
            console.error('ProfilePage back failed:', e instanceof Error ? e.message : String(e));
          }
        }
      },
      {
        icon: '馃搳',
        titleKey: 'reading_stats',
        action: (): void => {
          navigateTo('pages/StatisticsPage');
        }
      },
      {
        icon: '馃摑',
        titleKey: 'reading_notes',
        subtitleKey: 'note_count',
        action: (): void => {
          navigateTo('pages/NotesPage');
        }
      },
      {
        icon: '馃敄',
        titleKey: 'bookmark_manage',
        subtitleKey: 'bookmark_count',
        action: (): void => {
          navigateTo('pages/BookmarksPage');
        }
      },
      {
        icon: '√',
        titleKey: 'todo_items',
        action: (): void => {
          navigateTo('pages/TodoPage');
        }
      },
      {
        icon: '≡',
        titleKey: 'read_settings',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 0;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: '▣',
        titleKey: 'display_settings',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 1;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: '🔧',
        titleKey: 'help_feedback',
        action: (): void => {
          navigateTo('pages/HelpPage');
        }
      },
      {
        icon: '馃摐',
        titleKey: 'privacy_policy',
        action: (): void => {
          navigateTo('pages/PrivacyPolicyPage');
        }
      }
    ];
  }
}

