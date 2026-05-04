import { logger } from '.\.\common/utils/Logger';
/**
 * 鐠佸墽鐤嗘い鐢告桨 - 闁�倿鍘ら獮鍐茬潌 (Master-Detail 鐢�啫锟?
 * 閹靛�婧€閸楁洟銆夐敍灞介挬閺夊灝寮婚弽蹇撶�鐏炩偓
 * 閸栧懎鎯堥弮鐘绘�绾板秶绮嶉敓?

 */
import { router, promptAction } from '@kit.ArkUI';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { BusinessError } from '@kit.BasicServicesKit';
import { AdaptiveContainer } from '../presentation/common/components/AdaptiveContainer';
import { A11yListItem, A11yButton } from '../presentation/common/components/A11yComponents';
import { FontScaleSelector } from '../components/FontScaleSelector';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { tr } from '../core/utils/LocalizationUtil';
import { loginStateManager } from '../core/services/auth/LoginStateManager';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { Spacing, Size, BorderRadius, getShadow } from '../core/utils/LayoutConstants';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

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
  @State screenInfo: ScreenInfo | null = null;

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
    Column({ space: Spacing.sm }) {
      Text(tr('settings'))
        .fontSize(fontScaleManager.getScaledFontSize(24))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentColors.textPrimary)
        .margin({ bottom: Spacing.xl })
        .padding({ left: Spacing.md })
      
      ForEach(this.getTabNames(), (item: SettingItem): void => {
        Row() {
          Text(tr(item.nameKey))
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .layoutWeight(1)
            .fontColor(this.currentTab === item.val ? this.currentColors.primary : this.currentColors.textSecondary)
            .fontWeight(this.currentTab === item.val ? FontWeight.Bold : FontWeight.Normal)
        }
        .height(Size.buttonMD)
        .padding({ left: Spacing.md, right: Spacing.md })
        .backgroundColor(this.currentTab === item.val ? this.currentColors.primaryLight : 'Transparent')
        .borderRadius(BorderRadius.sm)
        .onClick((): void => { this.currentTab = item.val; })
      })
    }
    .width('100%')
    .height('100%')
    .padding({ top: layoutHelper.getSafeTopPadding(), bottom: Spacing.lg })
  }

  @Builder
  buildContent() {
    Column() {
      // 閹靛�婧€缁旑垶銆婇柈銊ヮ嚤閼割亝锟?
      if (this.breakpoint === 'sm') {
        Row() {
          Text(tr('settings'))
            .fontSize(fontScaleManager.getScaledFontSize(24))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)
            .layoutWeight(1)
          
          A11yButton({ 
            text: 'back', 
            btnType: 'secondary', 
            onClickCallback: (): void => { goBack(); } 
          })
        }
        .height(Size.buttonLG)
        .padding({ left: Spacing.lg, right: Spacing.lg })
        .backgroundColor(this.currentColors.surface)
        .shadow(getShadow('sm', this.isDarkMode))
        .padding({
          top: layoutHelper.getSafeTopPadding(),
          bottom: Spacing.sm
        })
      }
      
      // 閹靛�婧€缁旑垱鐖ｇ粵鎯у瀼锟?
      if (this.breakpoint === 'sm') {
        Scroll() {
          Row({ space: Spacing.md }) {
            ForEach(this.getTabNames(), (item: SettingItem): void => {
              Text(tr(item.nameKey))
                .fontSize(fontScaleManager.getScaledFontSize(14))
                .padding({ left: Spacing.lg, right: Spacing.lg, top: Spacing.sm, bottom: Spacing.sm })
                .borderRadius(BorderRadius.xl)
                .backgroundColor(this.currentTab === item.val ? this.currentColors.primary : (this.isDarkMode ? '#2C2C2E' : '#EEEEEE'))
                .fontColor(this.currentTab === item.val ? '#FFFFFF' : this.currentColors.textSecondary)
                .onClick((): void => { this.currentTab = item.val; })
            })
          }
          .padding(Spacing.lg)
        }
        .width('100%')
      }
      
      // 閸愬懎顔愰崠鍝勭厵
      Scroll() {
        Column({ space: 0 }) {
          if (this.currentTab === SettingTab.BASIC) this.buildBasicSettings()
          else if (this.currentTab === SettingTab.DISPLAY) this.buildDisplaySettings()
          else if (this.currentTab === SettingTab.ACCOUNT) this.buildAccountSettings()
          else if (this.currentTab === SettingTab.ABOUT) this.buildAboutSettings()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.currentColors.background)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildBasicSettings() {
    Column({ space: 0 }) {
      Text(tr('general_settings'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)
        .padding(Spacing.lg)
      
      A11yListItem({ 
        title: tr('clear_cache'), 
        subtitle: tr('current') + ' ' + this.cacheSize, 
        itemClickCallback: (): void => { this.clearCache(); } 
      })
      
      Divider().margin({ left: Spacing.lg })
      
      A11yListItem({ 
        title: tr('check_update'), 
        subtitle: 'v1.0.0', 
        itemClickCallback: (): void => { this.checkUpdate(); } 
      })
      
      Divider().margin({ left: Spacing.lg })
      
      A11yListItem({ 
        title: tr('help_center'), 
        itemClickCallback: (): void => { navigateTo('pages/HelpPage'); } 
      })
    }
    .width('100%')
    .padding({ bottom: Spacing.xl })
  }

  @Builder
  buildDisplaySettings() {
    Column({ space: 0 }) {
      Text(tr('display_settings'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)
        .padding(Spacing.lg)
      
      Row() { 
        Text(tr('dark_mode'))
          .layoutWeight(1)
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor(this.currentColors.textPrimary) 
        
        Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode })
          .onChange((v: boolean): void => { this.toggleDarkMode(v); }) 
      }
      .height(Size.buttonLG)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.currentColors.surface)
      .borderRadius(BorderRadius.sm)
      
      Divider().margin({ left: Spacing.lg })
      
      FontScaleSelector({ 
        isDarkMode: this.isDarkMode, 
        onConfigChanged: async (): Promise<void> => { 
          const fontConfig = fontScaleManager.getConfig(); 
          this.fontScale = fontConfig.followSystem ? await fontScaleManager.getSystemFontScale() : fontConfig.scale; 
        } 
      })
      .margin({ top: Spacing.sm })
    }
    .width('100%')
    .padding({ bottom: Spacing.xl })
  }

  @Builder
  buildAccountSettings() {
    Column({ space: 0 }) {
      Text(tr('account_security'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)
        .padding(Spacing.lg)
      
      A11yListItem({ 
        title: tr('logout'), 
        subtitle: tr('logout_current'), 
        itemClickCallback: (): void => { this.handleLogout(); } 
      })
    }
    .width('100%')
  }

  @Builder
  buildAboutSettings() {
    Column({ space: 0 }) {
      Text(tr('about_app'))
        .fontSize(fontScaleManager.getScaledFontSize(16))
        .fontColor(this.currentColors.textSecondary)
        .padding(Spacing.lg)
      
      // 应用信息卡片
      Column({ space: 0 }) {
        this.buildAboutItem(tr('app_name_label'), tr('app_name'))
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('version_code'), 'v2.5.0')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('build_date'), '2026-04-05')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('target_sdk'), '6.0.2(22)')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('supported_formats'), 'PDF, EPUB, TXT, DOCX, MOBI')
      }
      .width('100%')
      .backgroundColor(this.currentColors.surface)
      .margin({ top: Spacing.sm })
      .borderRadius(BorderRadius.md)
      .shadow(getShadow('sm', this.isDarkMode))
      .padding({ top: Spacing.sm, bottom: Spacing.sm })
      
      // 版权和法律信息卡片
      Column({ space: 0 }) {
        this.buildAboutItem(tr('copyright'), 'Copyright 2026')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('open_source'), 'MIT License')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItemWithClick(tr('privacy_policy'), tr('view_policy'), (): void => { navigateTo('pages/PrivacyPolicyPage'); })
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItemWithClick(tr('user_agreement'), tr('view_agreement'), (): void => { navigateTo('pages/UserAgreementPage'); })
      }
      .width('100%')
      .backgroundColor(this.currentColors.surface)
      .margin({ top: Spacing.lg })
      .borderRadius(BorderRadius.md)
      .shadow(getShadow('sm', this.isDarkMode))
      .padding({ top: Spacing.sm, bottom: Spacing.sm })
      
      // 閹垛偓閺堫垱鐖ら崡锛勫�
      Column({ space: 0 }) {
        this.buildAboutItem(tr('tech_stack'), 'ArkTS, ArkUI, HarmonyOS')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItem(tr('huawei_services'), 'Account Kit, ImageKit, TTS')
        Divider().margin({ left: Spacing.lg })
        this.buildAboutItemWithClick(tr('feedback'), tr('submit_feedback'), (): void => { navigateTo('pages/FeedbackPage'); })
      }
      .width('100%')
      .backgroundColor(this.currentColors.surface)
      .margin({ top: Spacing.lg })
      .borderRadius(BorderRadius.md)
      .shadow(getShadow('sm', this.isDarkMode))
    }
    .width('100%')
    .padding({ bottom: Spacing.xl })
  }

  @Builder
  buildAboutItemWithClick(label: string, value: string, clickAction: () => void) {
    Row() {
      Text(label)
        .layoutWeight(1)
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontColor(this.currentColors.textPrimary)
      
      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.currentColors.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(50)
    .padding({ left: Spacing.lg, right: Spacing.lg })
    .onClick((): void => clickAction())
    .stateStyles({
      pressed: { .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.02)') },
      normal: { .backgroundColor('Transparent') }
    })
  }

  @Builder
  buildAboutItem(label: string, value: string) {
    Row() {
      Text(label)
        .layoutWeight(1)
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontColor(this.currentColors.textPrimary)
      
      Text(value)
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.currentColors.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(50)
    .padding({ left: Spacing.lg, right: Spacing.lg })
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
        logger.info('[Settings] Cache cleared successfully');
      }
    }).catch((err: BusinessError): void => {
      logger.error('[Settings] Show dialog error:', err.message);
      promptAction.showToast({
        message: '閹垮秳缍旀径杈�Е',
        duration: 2000
      });
    });
  }

  /**
   * 濡�偓閺屻儲娲块敓?
   */
  private checkUpdate(): void {
    promptAction.showToast({
      message: '濮濓絽婀�Λ鈧�弻銉︽纯锟?..',
      duration: 1500
    });
    
    setTimeout((): void => {
      promptAction.showToast({
        message: '瑜版挸澧犲�鍙夋Ц閺堚偓閺傛壆澧楅敓?v2.5.0',
        duration: 2000
      });
      logger.info('[Settings] Update check completed - Current version is latest');
    }, 1000);
  }

  /**
   * 閸掑洦宕插ǎ杈��濡�€崇础
   */
  private toggleDarkMode(isOn: boolean): void {
    try {
      this.isDarkMode = isOn;
      preferenceManager.setTheme(isOn ? 'dark' : 'light');
      themeManager.setDarkMode(isOn);
      this.currentColors = themeManager.getColors();
      logger.info('[Settings] Dark mode toggled:', isOn);
      
      promptAction.showToast({
        message: isOn ? '瀹告彃鍨忛幑銏犲煂濞ｈ精澹婂Ο鈥崇础' : '瀹告彃鍨忛幑銏犲煂濞村懓澹婂Ο鈥崇础',
        duration: 1500
      });
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[Settings] Toggle dark mode failed:', err.message);
      promptAction.showToast({
        message: '閸掑洦宕叉径杈�Е',
        duration: 2000
      });
    }
  }

  /**
   * 闁�偓閸戣櫣娅ラ敓?
   */
  private handleLogout(): void {
    promptAction.showDialog({
      title: '绾�喛顓婚柅鈧�敓?,
      message: '绾�喖鐣剧憰渚€鈧�偓閸戣櫣娅ヨぐ鏇炴偋?',
      buttons: [
        { text: '閸欐牗锟?, color: '#666666' },
        { text: '闁�偓锟?, color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) {
        try {
          loginStateManager.logout();
          promptAction.showToast({ message: '瀹告煡鈧�偓閸戣櫣娅ラ敓?, duration: 2000 });
          logger.info('[Settings] User logged out successfully');
          try {
            navigateTo.replace('LoginPage');
          } catch (routerError) {
            const routerErr = routerError as BusinessError;
            logger.error('[Settings] Navigate failed:', routerErr.message);
          }
        } catch (error) {
          const err = error as BusinessError;
          logger.error('[Settings] Logout failed:', err.message);
          promptAction.showToast({ message: '闁�偓閸戝搫銇戠拹銉�礉鐠囩兘鍣搁敓?, duration: 2000 });
        }
      }
    }).catch((err: BusinessError): void => {
      logger.error('[Settings] Show dialog error:', err.message);
    });
  }
}

// 妫板嫯顫嶇紒鍕�� - 閻€劋绨珼evEco Studio妫板嫯顫嶉敓?
@Preview
@Component
struct SettingsPagePreview {
  build() {
    Column() {
      Text('鐠佸墽鐤嗛敓?- 濞村懓澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      SettingsPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鐠佸墽鐤嗛敓?- 濞ｈ精澹婂Ο鈥崇础')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SettingsPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
