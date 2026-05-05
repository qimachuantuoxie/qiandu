import { logger } from '../../../common/utils/Logger';
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { profileViewModel, ProfileViewModel } from '../viewmodels/ProfileViewModel';
import { appTheme, themeManager, COMMON_COLORS, AppColors } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { tr } from '../../../core/utils/LocalizationUtil';
import { layoutHelper, ScreenInfo } from '../../common/utils/LayoutHelper';
import { PageHeader, EmptyState, LoadingState, ErrorState, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { HDSButton, HDSButtonType } from '../../../common/components/HDSButton';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

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
    DialogHelper.info('更换头像功能开发中');
  }

  build() {
    Column() {
      // 标准页面头部
      PageHeader({
        title: '个人中心',
        showBack: false
      })
      
      // 内容区域
      Scroll() {
        Column({ space: HDSSpacing.lg }) {
          // 用户信息卡片
          this.UserInfoCard()

          // 阅读统计卡片
          this.ReadingStatsCard()

          // 功能菜单列表
          this.MenuList()

          // 底部留白
          Column().height(HDSPacing.xxxl)
        }
        .width('100%')
        .padding({ 
          left: HDSSpacing.lg, 
          right: HDSSpacing.lg, 
          top: HDSSpacing.md 
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
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
    HDSCard({
      padding: HDSSpacing.xl,
      shadow: true,
      content: () => {
        if (this.vm.userInfo) {
          Row({ space: HDSSpacing.xl }) {
            // 头像 - 带光环效果
            Stack() {
              // 外圈光环
              Circle()
                .width(80 + HDSSpacing.md)
                .height(80 + HDSSpacing.md)
                .fill(this.isDarkMode ? 'rgba(102, 126, 234, 0.2)' : 'rgba(102, 126, 234, 0.15)')

              // 头像本身
              if (this.vm.userInfo.avatar && this.vm.userInfo.avatar.length > 0) {
                Image(this.vm.userInfo.avatar)
                  .width(80)
                  .height(80)
                  .borderRadius(HDSBorderRadius.full)
                  .objectFit(ImageFit.Cover)
                  .border({
                    width: 3,
                    color: this.isDarkMode ? HDSColours.neutralDark.bgPrimary : HDSColours.neutral.white
                  })
              } else {
                Column() {
                  SymbolGlyph($r('sys.symbol.person.fill'))
                    .fontSize(32)
                    .fontColor([this.isDarkMode ? HDSColours.primary.lightBlue : HDSColours.neutral.white])
                }
                .width(80)
                .height(80)
                .justifyContent(FlexAlign.Center)
                .linearGradient({
                  direction: GradientDirection.Top,
                  colors: this.isDarkMode 
                    ? [[HDSColours.primary.blue, 0.0], ['#764BA2', 1.0]]
                    : [['rgba(255,255,255,0.3)', 0.0], ['rgba(255,255,255,0.1)', 1.0]]
                })
                .borderRadius(HDSBorderRadius.full)
              }

              // 编辑按钮
              Row() {
                SymbolGlyph($r('sys.symbol.camera.fill'))
                  .fontSize(14)
                  .fontColor([HDSColours.neutral.white])
              }
              .width(28)
              .height(28)
              .borderRadius(HDSBorderRadius.full)
              .backgroundColor('rgba(0,0,0,0.6)')
              .justifyContent(FlexAlign.Center)
              .position({ x: 75, y: 75 })
            }
            .onClick(() => this.updateAvatar())

            // 用户信息
            Column({ space: HDSSpacing.sm }) {
              Text(this.vm.userInfo.nickname || this.vm.userInfo.username)
                .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xxl))
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row({ space: HDSSpacing.xs }) {
                SymbolGlyph($r('sys.symbol.tag.fill'))
                  .fontSize(12)
                  .fontColor([this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600])
                
                Text('ID: ' + this.vm.userInfo.userId)
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
              }

              // 会员标识（如果有）
              if (this.vm.userInfo.isVip) {
                Row({ space: HDSSpacing.xs }) {
                  SymbolGlyph($r('sys.symbol.star.fill'))
                    .fontSize(12)
                    .fontColor(['#FFD700'])
                  
                  Text('VIP会员')
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFD700')
                }
                .padding({ 
                  left: HDSSpacing.sm, 
                  right: HDSSpacing.sm, 
                  top: HDSSpacing.xs, 
                  bottom: HDSSpacing.xs 
                })
                .backgroundColor('rgba(255,215,0,0.15)')
                .borderRadius(HDSBorderRadius.xl)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
        }
      }
    })
  }

  @Builder
  ReadingStatsCard() {
    HDSCard({
      title: '阅读数据统计',
      icon: $r('sys.symbol.chart.bar.xaxis'),
      padding: HDSSpacing.xl,
      content: () => {
        // 统计数据网格
        Grid() {
          GridItem() {
            this.StatItem('book.fill', this.vm.totalBooks.toString(), '藏书', HDSColours.primary.blue)
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
        .columnsGap(HDSPacing.md)
        .rowsGap(HDSPacing.md)
        .width('100%')
        .height(this.screenInfo?.isTablet ? 200 : 180)
      }
    })
  }

  @Builder
  StatItem(iconName: string, value: string, label: string, color: string) {
    Column({ space: HDSSpacing.sm }) {
      // 图标容器 - 渐变色背景
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(this.screenInfo?.isTablet ? 28 : 24)
          .fontColor([color])
      }
      .width(this.screenInfo?.isTablet ? 56 : 48)
      .height(this.screenInfo?.isTablet ? 56 : 48)
      .borderRadius(HDSBorderRadius.lg)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [
          [color + '20', 0.0],
          [color + '10', 1.0]
        ]
      })
      .justifyContent(FlexAlign.Center)

      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xxl))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

      Text(label)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xs))
        .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MenuList() {
    HDSCard({
      padding: 0,
      shadow: true,
      content: () => {
        Column({ space: 0 }) {
          ForEach(this.getMenuItems(), (item: ProfileMenuItem, index: number) => {
            Column() {
              Row({ space: HDSSpacing.lg }) {
                // 图标容器
                Column() {
                  SymbolGlyph($r(`sys.symbol.${item.icon}`))
                    .fontSize(20)
                    .fontColor([item.color || HDSColours.primary.blue])
                }
                .width(40)
                .height(40)
                .borderRadius(HDSBorderRadius.lg)
                .backgroundColor((item.color || HDSColours.primary.blue) + '15')
                .justifyContent(FlexAlign.Center)

                Text(item.title || tr(item.titleKey))
                  .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
                  .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
                  .layoutWeight(1)

                if (item.subtitle) {
                  Text(item.subtitle)
                    .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
                    .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
                }

                SymbolGlyph($r('sys.symbol.chevron.right'))
                  .fontSize(16)
                  .fontColor([this.isDarkMode ? '#48484A' : '#C7C7CC'])
              }
              .width('100%')
              .padding(HDSPacing.lg)
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
                  .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
                  .strokeWidth(0.5)
                  .margin({ left: 40 + HDSSpacing.lg * 2 })
              }
            }
          })
        }
        .width('100%')
      }
    })
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
