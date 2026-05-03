// 入口Ability - 应用生命周期管理

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, router, display } from '@kit.ArkUI';
import { displayHelper } from '../utils/DisplayHelper';
import { nativeModules } from '../utils/NativeModules';
import { preferenceManager } from '../utils/PreferenceManager';
import { i18nManager } from '../utils/I18nManager';
import { DeviceUtils } from '../utils/DeviceUtils';
import { kitManager } from '../services/huawei-kit/KitManager';
import { imageCacheService } from '../services/image/ImageCacheService';
import { secureStorage } from '../utils/SecureStorage';
import { initAppStore } from '../store/AppStore';
import { huaweiAuthService } from '../services/auth/HuaweiAuthService';
import { foldableAdapter } from '../utils/FoldableAdapterManager';

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

    // 3. 加载主页面（此时所有服务已就绪）
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 'Load content failed: %{public}s', err.code ? err.code.toString() : 'Unknown error');
        return;
      }
      hilog.info(0x0000, 'EntryAbility', 'Content loaded successfully');
    });
  }

  private async initHeavyServices(): Promise<void> {
    try {
      // 这些服务需要按顺序初始化
      await preferenceManager.init(this.context);
      await imageCacheService.init(this.context);
      await nativeModules.initialize();

      // 初始化 Huawei 认证服务（关键：必须在LoginPage加载前完成）
      huaweiAuthService.init(this.context);

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
      // Set window background to transparent using the new API
      this.windowClass.setWindowBackgroundColor('#00000000');

      // Enable multi-window for tablets based on screen width
      const screenWidth = displayHelper.getWidth();
      const isTablet = screenWidth >= 600;

      if (isTablet) {
        hilog.info(0x0000, 'EntryAbility', 'Tablet mode enabled');
      }

      // Set preferred orientation based on device
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
