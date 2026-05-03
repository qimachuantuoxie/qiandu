/**
 * 设置页组件 - 优化版
 * 应用设置、账号管理、支持、法律等
 * 优化：UI 美化、账号卡片、系统符号、动画交互
 *
 * @since 3.0.0
 */

import { router } from '@kit.ArkUI';
import { toast } from '../../../utils/ToastHelper';
import { navigateTo } from '../../../utils/NavigationHelper';
import { loginStateManager } from '../../../services/auth/LoginStateManager';
import { preferenceManager } from '../../../utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';

interface SettingsTabParam {
  tab: number;
}

interface SettingsItem {
  labelKey: string;
  icon: string;
  action: () => void;
  badge?: string;
}

interface SettingsGroup {
  titleKey: string;
  icon: string;
  items: SettingsItem[];
}

@Component
export struct SettingsContent {
  @Prop isDarkMode: boolean = false;
  @State isLoggedIn: boolean = false;
  @State username: string = '';
  @State userAvatar: string = '';
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;

  aboutToAppear() {
    this.isLoggedIn = loginStateManager.isLoggedIn();
    if (this.isLoggedIn) {
      const user = loginStateManager.getCurrentUser();
      this.username = user ? user.username : '';
      this.userAvatar = user ? (user.avatar ?? '') : '';
    }
    this.currentColors = themeManager.getColors();
    this.initAsyncData();
  }

  private async initAsyncData(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
  }

  private handleLogin(): void {
    navigateTo('pages/LoginPage');
  }

  private handleLogout(): void {
    AlertDialog.show({
      title: tr('confirm_logout'),
      message: tr('confirm_logout') + '?',
      primaryButton: {
        value: tr('cancel'),
        action: () => {}
      },
      secondaryButton: {
        value: tr('logout'),
        fontColor: '#FF3B30',
        action: () => {
          loginStateManager.logout();
          this.isLoggedIn = false;
          this.username = '';
          this.userAvatar = '';
          toast(tr('logout_success'));
        }
      },
      cancel: () => {}
    });
  }

  private getSymbolResource(name: string): Resource {
    if (name === 'book_fill' || name === 'book') return $r('sys.symbol.book');
    if (name === 'sun_max_fill' || name === 'sun_max') return $r('sys.symbol.sun_max');
    if (name === 'questionmark_circle') return $r('sys.symbol.questionmark_circle');
    if (name === 'star_fill' || name === 'star') return $r('sys.symbol.star');
    if (name === 'doc_text_fill' || name === 'doc_text') return $r('sys.symbol.doc_text');
    if (name === 'doc_plaintext') return $r('sys.symbol.doc_plaintext');
    return $r('sys.symbol.star');
  }

  private settingsGroups: SettingsGroup[] = [
    {
      titleKey: 'settings',
      icon: 'gear_fill',
      items: [
        {
          labelKey: 'read_settings', icon: 'book_fill', action: () => {
            const p: SettingsTabParam = { tab: 0 };
            navigateTo('pages/SettingsPage', p);
          }
        },
        {
          labelKey: 'display_settings', icon: 'sun_max_fill', action: () => {
            const p: SettingsTabParam = { tab: 1 };
            navigateTo('pages/SettingsPage', p);
          }
        }
      ]
    },
    {
      titleKey: 'support',
      icon: 'sparkles',
      items: [
        { labelKey: 'help_docs', icon: 'questionmark_circle', action: () => navigateTo('pages/HelpPage') },
        { labelKey: 'feedback', icon: 'pencil', action: () => navigateTo('pages/FeedbackPage') },
        { labelKey: 'features', icon: 'star_fill', action: () => navigateTo('pages/FeaturesPage') }
      ]
    },
    {
      titleKey: 'legal',
      icon: 'doc_text_fill',
      items: [
        { labelKey: 'privacy_policy', icon: 'hand_raised_fill', action: () => navigateTo('pages/PrivacyPolicyPage') },
        { labelKey: 'user_agreement', icon: 'doc_plaintext', action: () => navigateTo('pages/UserAgreementPage') }
      ]
    }
  ];

  build() {
    Column() {
      // 顶部导航栏
      this.HeaderBar()

      // 设置列表
      this.SettingsList()
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  HeaderBar() {
    Row() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.star'))
          .fontSize(fontScaleManager.getScaledFontSize(22))
          .fontColor([this.currentColors.primary])

        Text(tr('settings'))
          .fontSize(fontScaleManager.getScaledFontSize(22))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.currentColors.surface)
  }

  @Builder
  SettingsList() {
    Scroll() {
      Column({ space: 16 }) {
        // 账号卡片
        this.AccountCard()

        ForEach(this.settingsGroups, (group: SettingsGroup) => {
          this.SettingsCard(group)
        })

        // 版本信息
        this.VersionInfo()
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  AccountCard() {
    Column() {
      if (this.isLoggedIn) {
        // 已登录状态
        Row({ space: 16 }) {
          // 头像
          if (this.userAvatar && this.userAvatar.length > 0) {
            Image(this.userAvatar)
              .width(64)
              .height(64)
              .borderRadius(32)
          } else {
            Column() {
              SymbolGlyph($r('sys.symbol.person_fill'))
                .fontSize(fontScaleManager.getScaledFontSize(32))
                .fontColor([COMMON_COLORS.PRIMARY_BLUE])
            }
            .width(64)
            .height(64)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.15)')
            .borderRadius(32)
          }

          // 用户信息
          Column({ space: 8 }) {
            Text(this.username)
              .fontSize(fontScaleManager.getScaledFontSize(18))
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentColors.textPrimary)

            Text(tr('click_manage_account'))
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.currentColors.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(fontScaleManager.getScaledFontSize(20))
            .fontColor([this.currentColors.textSecondary])
        }
        .width('100%')
        .padding(16)
        .onClick(() => {
          navigateTo('pages/ProfilePage');
        })
        .stateStyles({
          pressed: {
            .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
          },
          normal: {
            .backgroundColor('transparent')
          }
        })

        Divider()
          .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')

        // 退出登录按钮
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.star'))
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontColor(['#FF3B30'])

          Text(tr('logout'))
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor('#FF3B30')
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.handleLogout())
      } else {
        // 未登录状态
        Row({ space: 16 }) {
          Column() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(fontScaleManager.getScaledFontSize(32))
              .fontColor([this.currentColors.textSecondary])
          }
          .width(64)
          .height(64)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.isDarkMode ? 'rgba(0,125,255,0.2)' : 'rgba(0,125,255,0.15)')
          .borderRadius(32)

          Column({ space: 8 }) {
            Text(tr('not_logged_in'))
              .fontSize(fontScaleManager.getScaledFontSize(18))
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentColors.textPrimary)

            Text(tr('login_for_more'))
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.currentColors.textSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(fontScaleManager.getScaledFontSize(20))
            .fontColor([this.currentColors.textSecondary])
        }
        .width('100%')
        .padding(16)
        .onClick(() => this.handleLogin())
      }
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.6)' : 'rgba(255,255,255,0.7)')
    .backdropBlur(15)
    .borderRadius(16)
    .border({
      width: 1,
      color: this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.4)'
    })
  }

  @Builder
  SettingsCard(group: SettingsGroup) {
    Column() {
      // 分组标题
      Row({ space: 8 }) {
        SymbolGlyph(this.getSymbolResource(group.icon))
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor([this.currentColors.primary])

        Text(tr(group.titleKey))
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
      }
      .alignSelf(ItemAlign.Start)
      .width('100%')
      .padding(16)

      // 设置项列表
      Column({ space: 0 }) {
        ForEach(group.items, (item: SettingsItem, index: number) => {
          Column() {
            Row({ space: 12 }) {
              SymbolGlyph(this.getSymbolResource(item.icon))
                .fontSize(fontScaleManager.getScaledFontSize(18))
                .fontColor([this.currentColors.onSurfaceVariant])

              Text(tr(item.labelKey))
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .fontColor(this.currentColors.textPrimary)
                .layoutWeight(1)

              if (item.badge && item.badge.length > 0) {
                Text(item.badge)
                  .fontSize(fontScaleManager.getScaledFontSize(12))
                  .fontColor(this.currentColors.primary)
              }

              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(fontScaleManager.getScaledFontSize(16))
                .fontColor([this.currentColors.textSecondary])
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .onClick(() => {
              item.action();
            })
            .stateStyles({
              pressed: {
                .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.03)')
              },
              normal: {
                .backgroundColor('transparent')
              }
            })

            if (index < group.items.length - 1) {
              Divider()
                .color(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')
                .padding({ left: 46 })
            }
          }
        })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(this.currentColors.surface)
    .borderRadius(16)
  }

  @Builder
  VersionInfo() {
    Column({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.info_circle'))
        .fontSize(fontScaleManager.getScaledFontSize(32))
        .fontColor([this.currentColors.onSurfaceVariant])
        .opacity(0.5)

      Text(tr('app_name'))
        .fontSize(fontScaleManager.getScaledFontSize(18))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)

      Text(tr('version') + ' 1.0.0')
        .fontSize(fontScaleManager.getScaledFontSize(12))
        .fontColor(this.currentColors.textSecondary)

      Text(tr('app_slogan'))
        .fontSize(fontScaleManager.getScaledFontSize(12))
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
  }
}
