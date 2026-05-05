// 入口Ability - 使用 Navigation 架构

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { displayHelper } from '../utils/DisplayHelper';
import { nativeModules } from '../utils/NativeModules';
import { preferenceManager } from '../core/utils/PreferenceManager';
import { localizationUtil } from '../core/utils/LocalizationUtil';
import { DeviceUtils } from '../core/utils/DeviceUtils';
import { kitManager } from '../core/services/huawei-kit/KitManager';
import { imageCacheService } from '../core/services/image/ImageCacheService';
import { secureStorage } from '../core/utils/SecureStorage';
import { initAppStore } from '../core/stores/AppStore';
import { authService } from '../core/services/auth/AuthService';
import { foldableAdapter } from '../core/utils/FoldableAdapterManager';
import { AppNavigationBuilder } from '../AppNavigation';

export default class EntryAbility extends UIAbility {
  private windowClass: window.Window | null = null;
  private displayListener: ((id: number) => void) | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0x0000, 'EntryAbility', 'Ability onCreate');
    // 轻量级同步初始化
    initAppStore();
    await secureStorage.init(this.context);
    await DeviceUtils.init();
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(0x0000, 'EntryAbility', 'Window stage create');

    // 1. 获取窗口并设置
    try {
      this.windowClass = windowStage.getMainWindowSync();
      this.setupWindowMode();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Failed to get main window: %{public}s', message);
    }

    // 2. 初始化所有重型服务（等待完成）
    await this.initHeavyServices();

    // 3. 使用 Navigation 架构加载根组件
    windowStage.loadContentBuilder(AppNavigationBuilder, (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 'Load content failed: %{public}s', err.code ? err.code.toString() : 'Unknown error');
        return;
      }
      hilog.info(0x0000, 'EntryAbility', 'Navigation content loaded successfully');
    });
  }

  private async initHeavyServices(): Promise<void> {
    try {
      await preferenceManager.init(this.context);
      await localizationUtil.init(this.context);
      await imageCacheService.init(this.context);
      await nativeModules.initialize();

      // 初始化统一认证服务（包含Token自动刷新）
      authService.init(this.context);

      // 初始化 Kit 服务
      await kitManager.initAllKits(this.context);

      hilog.info(0x0000, 'EntryAbility', 'All heavy services initialized');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Heavy init failed: %{public}s', message);
    }
  }

  private setupWindowMode(): void {
    if (!this.windowClass) {
      return;
    }

    try {
      this.windowClass.setWindowBackgroundColor('#00000000');

      const screenWidth = displayHelper.getWidth();
      const isTablet = screenWidth >= 600;

      if (isTablet) {
        hilog.info(0x0000, 'EntryAbility', 'Tablet mode enabled');
      }

      if (isTablet) {
        this.windowClass.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
      } else {
        this.windowClass.setPreferredOrientation(window.Orientation.PORTRAIT);
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Setup window mode failed: %{public}s', message);
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Window stage destroy');
    this.cleanupFoldableListeners();
    this.releaseKitServices();
    displayHelper.cleanup();
  }

  private cleanupFoldableListeners(): void {
    try {
      if (this.displayListener) {
        display.off('change', this.displayListener);
        this.displayListener = null;
        hilog.info(0x0000, 'EntryAbility', 'Display listener removed');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Cleanup listeners failed: %{public}s', message);
    }
  }

  private async releaseKitServices(): Promise<void> {
    try {
      hilog.info(0x0000, 'EntryAbility', 'Releasing Kit services...');
      await kitManager.releaseAllKits();
      hilog.info(0x0000, 'EntryAbility', 'Kit services released');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility',
        'Release Kit services failed: %{public}s',
        message);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'onNewWant');
  }
}
