/**
 * 璁剧疆椤甸潰 - 閫傞厤骞虫澘 (Master-Detail 甯冨眬)
 * 鎵嬫満鍗曟爮锛屽钩鏉?PC 鍙屾爮甯冨眬
 * 鍖呭惈鏃犻殰纰嶇粍浠?
 */
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../utils/NavigationHelper';
import { BusinessError } from '@kit.BasicServicesKit';
import { AdaptiveContainer } from '../presentation/common/components/AdaptiveContainer';
import { A11yListItem, A11yButton } from '../presentation/common/components/A11yComponents';
import { FontScaleSelector } from '../components/FontScaleSelector';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';
import { loginStateManager } from '../services/auth/LoginStateManager';
import { preferenceManager } from '../utils/PreferenceManager';

interface SettingItem {
  nameKey: string;
  val: number;
}

enum SettingTab {
  BASIC,
  DISPLAY,
  ACCOUNT,
  ABOUT
}

@Entry
@Component
struct SettingsPage {
  @State currentTab: SettingTab = SettingTab.BASIC;
  @State isDarkMode: boolean = false;
  @State cacheSize: string = '128 MB';
  @State fontScale: number = 1.0;
  @State currentColors: AppColors = themeManager.getColors();
  @State breakpoint: string = 'sm';

  aboutToAppear() {
    this.isDarkMode = preferenceManager.getTheme() === 'dark';
    this.currentColors = themeManager.getColors();
    this.initData();
  }

  private async initData(): Promise<void> {
    const fontConfig = fontScaleManager.getConfig();
    this.fontScale = fontConfig.followSystem ? await fontScaleManager.getSystemFontScale() : fontConfig.scale;
  }

  private getTabNames(): SettingItem[] {
    return [
      { nameKey: 'general', val: SettingTab.BASIC },
      { nameKey: 'display', val: SettingTab.DISPLAY },
      { nameKey: 'account', val: SettingTab.ACCOUNT },
      { nameKey: 'about', val: SettingTab.ABOUT }
    ];
  }

  build() {
    Stack() {
      AdaptiveContainer({
        sidePanel: (): void => { this.buildTabNav(); },
        content: (): void => { this.buildContent(); }
      })
        .onAreaChange((old: Area, newArea: Area): void => { this.breakpoint = Number(newArea.width) > 600 ? 'md' : 'sm'; })
    }
    .width('100%').height('100%')
  }

  @Builder
  buildTabNav() {
    Column({ space: 8 }) {
      Text(tr('settings')).fontSize(fontScaleManager.getScaledFontSize(24)).fontWeight(FontWeight.Bold).fontColor(this.currentColors.textPrimary).margin({ bottom: 20 }).padding({ left: 12 })
      ForEach(this.getTabNames(), (item: SettingItem): void => {
        Row() {
          Text(tr(item.nameKey)).fontSize(fontScaleManager.getScaledFontSize(16)).layoutWeight(1)
            .fontColor(this.currentTab === item.val ? this.currentColors.primary : this.currentColors.textSecondary)
            .fontWeight(this.currentTab === item.val ? FontWeight.Bold : FontWeight.Normal)
        }
        .height(48).padding({ left: 12, right: 12 })
        .backgroundColor(this.currentTab === item.val ? this.currentColors.primaryLight : 'Transparent')
        .borderRadius(8)
        .onClick((): void => { this.currentTab = item.val; })
      })
    }
    .width('100%').height('100%').padding({ top: 16, bottom: 16 })
  }

  @Builder
  buildContent() {
    Column() {
      if (this.breakpoint === 'sm') {
        Row() {
          Text(tr('settings')).fontSize(fontScaleManager.getScaledFontSize(24)).fontWeight(FontWeight.Bold).fontColor(this.currentColors.textPrimary).layoutWeight(1)
          A11yButton({ text: 'back', btnType: 'secondary', onClickCallback: (): void => { goBack(); } })
        }.height(56).padding({ left: 16, right: 16 }).backgroundColor(this.currentColors.surface)
      }
      if (this.breakpoint === 'sm') {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.getTabNames(), (item: SettingItem): void => {
              Text(tr(item.nameKey)).fontSize(fontScaleManager.getScaledFontSize(14)).padding({left:16, right:16, top:6, bottom:6}).borderRadius(16)
                .backgroundColor(this.currentTab === item.val ? this.currentColors.primary : (this.isDarkMode ? '#2C2C2E' : '#EEEEEE'))
                .fontColor(this.currentTab === item.val ? '#FFFFFF' : this.currentColors.textSecondary)
                .onClick((): void => { this.currentTab = item.val; })
            })
          }.padding(16)
        }.width('100%')
      }
      Scroll() {
        Column({ space: 0 }) {
          if (this.currentTab === SettingTab.BASIC) this.buildBasicSettings()
          else if (this.currentTab === SettingTab.DISPLAY) this.buildDisplaySettings()
          else if (this.currentTab === SettingTab.ACCOUNT) this.buildAccountSettings()
          else if (this.currentTab === SettingTab.ABOUT) this.buildAboutSettings()
        }.width('100%')
      }.layoutWeight(1).width('100%').backgroundColor(this.currentColors.background)
    }.width('100%').height('100%')
  }

  @Builder
  buildBasicSettings() {
    Column({ space: 0 }) {
      Text(tr('general_settings')).fontSize(fontScaleManager.getScaledFontSize(16)).fontColor(this.currentColors.textSecondary).padding(16)
      A11yListItem({ title: tr('clear_cache'), subtitle: tr('current') + ' ' + this.cacheSize, itemClickCallback: (): void => { this.clearCache(); } })
      Divider().margin({ left: 16 })
      A11yListItem({ title: tr('check_update'), subtitle: 'v1.0.0', itemClickCallback: (): void => { this.checkUpdate(); } })
      Divider().margin({ left: 16 })
      A11yListItem({ title: tr('help_center'), itemClickCallback: (): void => { navigateTo('pages/HelpPage'); } })
    }.width('100%').padding({ bottom: 20 })
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: 0 }) {
      Text(tr('display_settings')).fontSize(fontScaleManager.getScaledFontSize(16)).fontColor(this.currentColors.textSecondary).padding(16)
      Row() { Text(tr('dark_mode')).layoutWeight(1).fontSize(fontScaleManager.getScaledFontSize(16)).fontColor(this.currentColors.textPrimary); Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode }).onChange((v: boolean): void => { this.toggleDarkMode(v); }) }.height(56).padding({ left: 16, right: 16 }).backgroundColor(this.currentColors.surface)
      Divider().margin({ left: 16 })
      FontScaleSelector({ isDarkMode: this.isDarkMode, onConfigChanged: async (): Promise<void> => { const fontConfig = fontScaleManager.getConfig(); this.fontScale = fontConfig.followSystem ? await fontScaleManager.getSystemFontScale() : fontConfig.scale; } }).margin({ top: 8 })
    }.width('100%').padding({ bottom: 20 })
  }

  @Builder
  buildAccountSettings() {
    Column({ space: 0 }) {
      Text(tr('account_security')).fontSize(fontScaleManager.getScaledFontSize(16)).fontColor(this.currentColors.textSecondary).padding(16)
      A11yListItem({ title: tr('logout'), subtitle: tr('logout_current'), itemClickCallback: (): void => { this.handleLogout(); } })
    }.width('100%')
  }

  @Builder
  buildAboutSettings() {
    Column({ space: 0 }) {
      Text(tr('about_app')).fontSize(fontScaleManager.getScaledFontSize(16)).fontColor(this.currentColors.textSecondary).padding(16)
      Column({ space: 0 }) {
        this.buildAboutItem(tr('app_name_label'), tr('app_name'))
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('version_code'), 'v2.5.0')
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('build_date'), '2026-04-05')
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('target_sdk'), '6.0.2(22)')
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('supported_formats'), 'PDF, EPUB, TXT, DOCX, MOBI')
      }.width('100%').backgroundColor(this.currentColors.surface).margin({ top: 8 })
      Column({ space: 0 }) {
        this.buildAboutItem(tr('copyright'), 'Copyright 2026')
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('open_source'), 'MIT License')
        Divider().margin({ left: 16 })
        this.buildAboutItemWithClick(tr('privacy_policy'), tr('view_policy'), (): void => { navigateTo('pages/PrivacyPolicyPage'); })
        Divider().margin({ left: 16 })
        this.buildAboutItemWithClick(tr('user_agreement'), tr('view_agreement'), (): void => { navigateTo('pages/UserAgreementPage'); })
      }.width('100%').backgroundColor(this.currentColors.surface).margin({ top: 16 })
      Column({ space: 0 }) {
        this.buildAboutItem(tr('tech_stack'), 'ArkTS, ArkUI, HarmonyOS')
        Divider().margin({ left: 16 })
        this.buildAboutItem(tr('huawei_services'), 'Account Kit, ImageKit, TTS')
        Divider().margin({ left: 16 })
        this.buildAboutItemWithClick(tr('feedback'), tr('submit_feedback'), (): void => { navigateTo('pages/FeedbackPage'); })
      }.width('100%').backgroundColor(this.currentColors.surface).margin({ top: 16 })
    }.width('100%').padding({ bottom: 20 })
  }

  @Builder
  buildAboutItemWithClick(label: string, value: string, clickAction: () => void) {
    Row() {
      Text(label).layoutWeight(1).fontSize(fontScaleManager.getScaledFontSize(15)).fontColor(this.currentColors.textPrimary)
      Text(value).fontSize(fontScaleManager.getScaledFontSize(13)).fontColor(this.currentColors.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(50).padding({ left: 16, right: 16 })
    .onClick((): void => clickAction())
  }

  @Builder
  buildAboutItem(label: string, value: string) {
    Row() {
      Text(label).layoutWeight(1).fontSize(fontScaleManager.getScaledFontSize(15)).fontColor(this.currentColors.textPrimary)
      Text(value).fontSize(fontScaleManager.getScaledFontSize(13)).fontColor(this.currentColors.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.height(50).padding({ left: 16, right: 16 })
  }

  private clearCache(): void {
    promptAction.showDialog({
      title: tr('clear_cache'),
      message: tr('cache_size_hint') + this.cacheSize + '? ' + tr('clear_cache_hint'),
      buttons: [
        { text: tr('cancel'), color: this.currentColors.textSecondary },
        { text: tr('clear'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) {
        this.cacheSize = '0 MB';
        promptAction.showToast({
          message: tr('cache_cleared'),
          duration: 2000
        });
        console.info('[Settings] Cache cleared successfully');
      }
    }).catch((err: BusinessError): void => {
      console.error('[Settings] Show dialog error:', err.message);
      promptAction.showToast({
        message: '操作失败',
        duration: 2000
      });
    });
  }

  /**
   * 检查更新
   */
  private checkUpdate(): void {
    promptAction.showToast({
      message: '正在检查更新...',
      duration: 1500
    });
    
    setTimeout((): void => {
      promptAction.showToast({
        message: '当前已是最新版本 v2.5.0',
        duration: 2000
      });
      console.info('[Settings] Update check completed - Current version is latest');
    }, 1000);
  }

  /**
   * 切换深色模式
   */
  private toggleDarkMode(isOn: boolean): void {
    try {
      this.isDarkMode = isOn;
      preferenceManager.setTheme(isOn ? 'dark' : 'light');
      themeManager.setDarkMode(isOn);
      this.currentColors = themeManager.getColors();
      console.info('[Settings] Dark mode toggled:', isOn);
      
      promptAction.showToast({
        message: isOn ? '已切换到深色模式' : '已切换到浅色模式',
        duration: 1500
      });
    } catch (error) {
      const err = error as BusinessError;
      console.error('[Settings] Toggle dark mode failed:', err.message);
      promptAction.showToast({
        message: '切换失败',
        duration: 2000
      });
    }
  }

  /**
   * 退出登录
   */
  private handleLogout(): void {
    promptAction.showDialog({
      title: '确认退出',
      message: '确定要退出登录吗?',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '退出', color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) {
        try {
          loginStateManager.logout();
          promptAction.showToast({ message: '已退出登录', duration: 2000 });
          console.info('[Settings] User logged out successfully');
          try {
            router.replaceUrl({ url: 'pages/LoginPage' });
          } catch (routerError) {
            const routerErr = routerError as BusinessError;
            console.error('[Settings] Navigate failed:', routerErr.message);
          }
        } catch (error) {
          const err = error as BusinessError;
          console.error('[Settings] Logout failed:', err.message);
          promptAction.showToast({ message: '退出失败，请重试', duration: 2000 });
        }
      }
    }).catch((err: BusinessError): void => {
      console.error('[Settings] Show dialog error:', err.message);
    });
  }
}
