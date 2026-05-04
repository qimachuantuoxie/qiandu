import { logger } from '../../../common/utils/Logger';
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
  color?: string;
}

@Entry
@ComponentV2
struct ProfilePage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
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

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private updateAvatar(): void {
    promptAction.showToast({
      message: '更换头像功能开发中',
      duration: 1500
    });
  }

  build() {
    Stack() {
      Column() {
        // 渐变背景头部
        this.HeaderBackground()

        Scroll() {
          Column({ space: Spacing.lg }) {
            // 用户信息卡片
            this.UserInfoCard()

            // 阅读统计卡片
            this.ReadingStatsCard()

            // 功能菜单列表
            this.MenuList()

            // 底部留白
            Column().height(Spacing.xxxl)
          }
          .width('100%')
          .padding({ 
            left: Spacing.lg, 
            right: Spacing.lg, 
            top: Spacing.xxl 
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeaderBackground() {
    Column()
      .width('100%')
      .height(this.screenInfo?.isTablet ? 240 : 200)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.isDarkMode 
          ? [['#1A1A2E', 0.0], ['#16213E', 0.5], ['#0F3460', 1.0]]
          : [[COMMON_COLORS.PRIMARY_BLUE, 0.0], ['#667EEA', 0.5], ['#764BA2', 1.0]]
      })
      .position({ top: 0 })
  }

  @Builder
  UserInfoCard() {
    Column() {
      if (this.vm.userInfo) {
        Row({ space: Spacing.xl }) {
          // 头像 - 带光环效果
          Stack() {
            // 外圈光环
            Circle()
              .width(Size.avatarXXL + Spacing.md)
              .height(Size.avatarXXL + Spacing.md)
              .fill(this.isDarkMode ? 'rgba(102, 126, 234, 0.2)' : 'rgba(102, 126, 234, 0.15)')

            // 头像本身
            if (this.vm.userInfo.avatar && this.vm.userInfo.avatar.length > 0) {
              Image(this.vm.userInfo.avatar)
                .width(Size.avatarXXL)
                .height(Size.avatarXXL)
                .borderRadius(BorderRadius.full)
                .objectFit(ImageFit.Cover)
                .border({
                  width: 3,
                  color: this.isDarkMode ? '#1A1A2E' : '#FFFFFF'
                })
            } else {
              Column() {
                SymbolGlyph($r('sys.symbol.person.fill'))
                  .fontSize(Size.iconXXXL)
                  .fontColor([this.isDarkMode ? '#667EEA' : '#FFFFFF'])
              }
              .width(Size.avatarXXL)
              .height(Size.avatarXXL)
              .justifyContent(FlexAlign.Center)
              .linearGradient({
                direction: GradientDirection.Top,
                colors: this.isDarkMode 
                  ? [['#667EEA', 0.0], ['#764BA2', 1.0]]
                  : [['rgba(255,255,255,0.3)', 0.0], ['rgba(255,255,255,0.1)', 1.0]]
              })
              .borderRadius(BorderRadius.full)
            }

            // 编辑按钮
            Row() {
              SymbolGlyph($r('sys.symbol.camera.fill'))
                .fontSize(Size.iconSM)
                .fontColor(['#FFFFFF'])
            }
            .width(Size.buttonSM)
            .height(Size.buttonSM)
            .borderRadius(BorderRadius.full)
            .backgroundColor('rgba(0,0,0,0.6)')
            .justifyContent(FlexAlign.Center)
            .position({ x: Size.avatarXXL - 5, y: Size.avatarXXL - 5 })
          }
          .onClick(() => this.updateAvatar())

          // 用户信息
          Column({ space: Spacing.sm }) {
            Text(this.vm.userInfo.nickname || this.vm.userInfo.username)
              .fontSize(fontScaleManager.getScaledFontSize(22))
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tc('#FFFFFF', '#FFFFFF'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.tag.fill'))
                .fontSize(Size.iconXS)
                .fontColor(['rgba(255,255,255,0.7)'])
              
              Text('ID: ' + this.vm.userInfo.userId)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor('rgba(255,255,255,0.85)')
            }

            // 会员标识（如果有）
            if (this.vm.userInfo.isVip) {
              Row({ space: Spacing.xs }) {
                SymbolGlyph($r('sys.symbol.star.fill'))
                  .fontSize(Size.iconXS)
                  .fontColor(['#FFD700'])
                
                Text('VIP会员')
                  .fontSize(fontScaleManager.getScaledFontSize(11))
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFD700')
              }
              .padding({ 
                left: Spacing.sm, 
                right: Spacing.sm, 
                top: Spacing.xs, 
                bottom: Spacing.xs 
              })
              .backgroundColor('rgba(255,215,0,0.15)')
              .borderRadius(BorderRadius.xl)
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
    // 毛玻璃效果卡片
    .backgroundColor(this.isDarkMode ? 'rgba(30,30,50,0.75)' : 'rgba(255,255,255,0.85)')
    .backdropBlur(30)
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.6)'
    })
    .shadow(getShadow('xl', this.isDarkMode))
    .offset({ y: -50 })
  }

  @Builder
  ReadingStatsCard() {
    Column({ space: Spacing.lg }) {
      Row() {
        SymbolGlyph($r('sys.symbol.chart.bar.xaxis'))
          .fontSize(Size.iconLG)
          .fontColor([this.currentColors.primary])
        
        Text('阅读数据统计')
          .fontSize(fontScaleManager.getScaledFontSize(17))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .margin({ left: Spacing.sm })

        Text('查看更多')
          .fontSize(fontScaleManager.getScaledFontSize(13))
          .fontColor(this.currentColors.primary)
          .onClick(() => navigateTo('pages/StatisticsPage'))
      }
      .width('100%')

      // 统计数据网格
      Grid() {
        GridItem() {
          this.StatItem('book.fill', this.vm.totalBooks.toString(), '藏书', COMMON_COLORS.PRIMARY_BLUE)
        }
        GridItem() {
          this.StatItem('clock.fill', this.vm.formatReadingTime(this.vm.totalReadingTime), '时长', '#FF6B6B')
        }
        GridItem() {
          this.StatItem('bookmark.fill', this.vm.totalBookmarks.toString(), '书签', '#52C41A')
        }
        GridItem() {
          this.StatItem('note.text', this.vm.totalNotes.toString(), '笔记', '#722ED1')
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(Spacing.md)
      .rowsGap(Spacing.md)
      .width('100%')
      .height(this.screenInfo?.isTablet ? 200 : 180)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('md', this.isDarkMode))
  }

  @Builder
  StatItem(iconName: string, value: string, label: string, color: string) {
    Column({ space: Spacing.sm }) {
      // 图标容器 - 渐变色背景
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(this.screenInfo?.isTablet ? Size.iconXXL : Size.iconXL)
          .fontColor([color])
      }
      .width(this.screenInfo?.isTablet ? Size.avatarLG : Size.avatarMD)
      .height(this.screenInfo?.isTablet ? Size.avatarLG : Size.avatarMD)
      .borderRadius(BorderRadius.lg)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [
          [color + '20', 0.0],
          [color + '10', 1.0]
        ]
      })
      .justifyContent(FlexAlign.Center)

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(12))
        .fontColor(this.tc('#8E8E93', '#8E8E93'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MenuList() {
    Column({ space: 0 }) {
      ForEach(this.getMenuItems(), (item: ProfileMenuItem, index: number) => {
        Column() {
          Row({ space: Spacing.lg }) {
            // 图标容器
            Column() {
              SymbolGlyph($r(`sys.symbol.${item.icon}`))
                .fontSize(Size.iconLG)
                .fontColor([item.color || this.currentColors.primary])
            }
            .width(Size.avatarMD)
            .height(Size.avatarMD)
            .borderRadius(BorderRadius.lg)
            .backgroundColor((item.color || this.currentColors.primary) + '15')
            .justifyContent(FlexAlign.Center)

            Text(item.title || tr(item.titleKey))
              .fontSize(fontScaleManager.getScaledFontSize(15))
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              .layoutWeight(1)

            if (item.subtitle) {
              Text(item.subtitle)
                .fontSize(fontScaleManager.getScaledFontSize(13))
                .fontColor(this.tc('#8E8E93', '#8E8E93'))
            }

            SymbolGlyph($r('sys.symbol.chevron.right'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#C7C7CC', '#48484A')])
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

          // 分割线
          if (index < this.getMenuItems().length - 1) {
            Divider()
              .color(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.06)'))
              .strokeWidth(0.5)
              .margin({ left: Size.avatarMD + Spacing.lg * 2 })
          }
        }
      })
    }
    .width('100%')
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
  }

  private getMenuItems(): ProfileMenuItem[] {
    return [
      {
        icon: 'books.vertical.fill',
        titleKey: 'my_bookshelf',
        subtitleKey: 'book_count',
        color: COMMON_COLORS.PRIMARY_BLUE,
        action: (): void => {
          try {
            goBack();
          } catch (e) {
            logger.error('ProfilePage back failed:', e instanceof Error ? e.message : String(e));
          }
        }
      },
      {
        icon: 'chart.bar.fill',
        titleKey: 'reading_stats',
        color: '#FF6B6B',
        action: (): void => {
          navigateTo('pages/StatisticsPage');
        }
      },
      {
        icon: 'note.text',
        titleKey: 'reading_notes',
        subtitleKey: 'note_count',
        color: '#52C41A',
        action: (): void => {
          navigateTo('pages/NotesPage');
        }
      },
      {
        icon: 'bookmark.fill',
        titleKey: 'bookmark_manage',
        subtitleKey: 'bookmark_count',
        color: '#FA8C16',
        action: (): void => {
          navigateTo('pages/BookmarksPage');
        }
      },
      {
        icon: 'checkmark.circle.fill',
        titleKey: 'todo_items',
        color: '#722ED1',
        action: (): void => {
          navigateTo('pages/TodoPage');
        }
      },
      {
        icon: 'gearshape.fill',
        titleKey: 'read_settings',
        color: '#13C2C2',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 0;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: 'paintbrush.fill',
        titleKey: 'display_settings',
        color: '#EB2F96',
        action: (): void => {
          const params: Record<string, number> = {};
          params['tab'] = 1;
          navigateTo('pages/SettingsPage', params);
        }
      },
      {
        icon: 'questionmark.circle.fill',
        titleKey: 'help_feedback',
        color: '#F5222D',
        action: (): void => {
          navigateTo('pages/HelpPage');
        }
      },
      {
        icon: 'shield.checkered',
        titleKey: 'privacy_policy',
        color: '#8E8E93',
        action: (): void => {
          navigateTo('pages/PrivacyPolicyPage');
        }
      }
    ];
  }
}

// 预览组件
@Preview
@ComponentV2
struct ProfilePagePreview {
  build() {
    Column() {
      Text('个人主页 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      ProfilePage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('个人主页 - 深色模式')
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
