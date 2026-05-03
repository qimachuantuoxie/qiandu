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

    // 1. 初始化全局状态存储
    initAppStore();

    // 2. 初始化安全存储
    await secureStorage.init(this.context);

    // 3. 初始化设备工具（包含折叠屏检测）
    await DeviceUtils.init();

    // 4. 初始化折叠屏适配器
    if (DeviceUtils.isFoldable()) {
      await foldableAdapter.init();
      hilog.info(0x0000, 'EntryAbility', 'Foldable device detected and initialized');
    }

    // 5. 异步初始化重量级服务（不阻塞 UI 加载）
    this.initHeavyServices();
  }

  private async initHeavyServices(): Promise<void> {
    try {
      // 这些服务不需要在启动瞬间完成
      await preferenceManager.init(this.context);
      await imageCacheService.init(this.context);
      await nativeModules.initialize();

      // 初始化 Huawei 认证服务
      huaweiAuthService.init(this.context);

      // 初始化 Kit 服务
      await kitManager.initAllKits(this.context);

      hilog.info(0x0000, 'EntryAbility', 'Heavy services initialized');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Heavy init failed: %{public}s', message);
    }
  }

  // 保留旧方法以防其他地方调用，但不再在 onCreate 调用
  private async initializeApp(): Promise<void> {
    try {
      await preferenceManager.init(this.context);
      hilog.info(0x0000, 'EntryAbility', 'Preference manager initialized');

      i18nManager.init(this.context);
      hilog.info(0x0000, 'EntryAbility', 'I18n initialized');

      await nativeModules.initialize();
      hilog.info(0x0000, 'EntryAbility', 'Native modules initialized');

      // 初始化所有Kit服务 (v2.0新增)
      await this.initializeKitServices();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Init failed: %{public}s', message);
    }
  }

  /**
   * 初始化所有Kit服务
   */
  private async initializeKitServices(): Promise<void> {
    try {
      hilog.info(0x0000, 'EntryAbility', 'Initializing Kit services...');

      // 使用KitManager统一初始化所有Kit服务
      const success = await kitManager.initAllKits(this.context);

      if (success) {
        hilog.info(0x0000, 'EntryAbility',
          'Kit services initialization: %{public}s',
          kitManager.getSummary());
      } else {
        hilog.warn(0x0000, 'EntryAbility',
          'Some Kit services failed to initialize');
      }

      // 打印详细状态
      kitManager.printStatus();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility',
        'Kit services init failed: %{public}s',
        message);
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'App onDestroy');
  
    // 清理折叠屏监听器
    this.cleanupFoldableListeners();
  
    // 释放所有 Kit 服务
    this.releaseKitServices();
      
    // 清理 DisplayHelper
    displayHelper.cleanup();
  }
  
  /**
   * 清理折叠屏监听器
   */
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

  /**
   * 释放所有Kit服务
   */
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

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Window stage create');

    // Get window and setup orientation
    try {
      this.windowClass = windowStage.getMainWindowSync();
      this.setupWindowMode();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      hilog.error(0x0000, 'EntryAbility', 'Failed to get main window: %{public}s', message);
    }

    // Load main page - 使用 LoginPage 作为应用入口
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 'Load content failed: %{public}s', err.code ? err.code.toString() : 'Unknown error');
        return;
      }
      hilog.info(0x0000, 'EntryAbility', 'Content loaded successfully');
    });
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
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'onNewWant');
  }
}

