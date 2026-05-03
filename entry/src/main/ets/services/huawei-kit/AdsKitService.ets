import { common } from '@kit.AbilityKit';

// Stub declarations for optional @ohos.ads Huawei Ads Kit
// The actual module is loaded at runtime when available on Huawei devices
// Original import: import { ads, BannerAd, InterstitialAd, RewardedAd, NativeAd } from '@ohos.ads';

// Provide stub classes for compile-time type safety
interface AdCreateParams {
  adId: string;
  adSize?: string;
  testAd: boolean;
}

class _BannerAd {
  on(event: string, callback: Function): void {}
  load(): Promise<void> { return Promise.resolve(); }
  show(): Promise<void> { return Promise.resolve(); }
  hide(): Promise<void> { return Promise.resolve(); }
  destroy(): Promise<void> { return Promise.resolve(); }
}
class _InterstitialAd {
  on(event: string, callback: Function): void {}
  load(): Promise<void> { return Promise.resolve(); }
  show(): Promise<void> { return Promise.resolve(); }
  hide(): Promise<void> { return Promise.resolve(); }
  destroy(): Promise<void> { return Promise.resolve(); }
}
class _RewardedAd {
  on(event: string, callback: Function): void {}
  load(): Promise<void> { return Promise.resolve(); }
  show(): Promise<void> { return Promise.resolve(); }
  hide(): Promise<void> { return Promise.resolve(); }
  destroy(): Promise<void> { return Promise.resolve(); }
}
class _NativeAd {
  on(event: string, callback: Function): void {}
  load(): Promise<void> { return Promise.resolve(); }
  show(): Promise<void> { return Promise.resolve(); }
  hide(): Promise<void> { return Promise.resolve(); }
  destroy(): Promise<void> { return Promise.resolve(); }
}

type BannerAd = _BannerAd;
type InterstitialAd = _InterstitialAd;
type RewardedAd = _RewardedAd;
type NativeAd = _NativeAd;

// Stub ads module with minimal API surface for type checking
class _AdsModule {
  async init(): Promise<void> {
    // Stub - real initialization happens when real module is loaded
  }
  createBannerAd(config: AdCreateParams): _BannerAd {
    return new _BannerAd();
  }
  createInterstitialAd(config: AdCreateParams): _InterstitialAd {
    return new _InterstitialAd();
  }
  createRewardedAd(config: AdCreateParams): _RewardedAd {
    return new _RewardedAd();
  }
  createNativeAd(config: AdCreateParams): _NativeAd {
    return new _NativeAd();
  }
}
const ads = new _AdsModule();

export enum AdType {
  BANNER = 'banner',
  INTERSTITIAL = 'interstitial',
  REWARDED = 'rewarded',
  SPLASH = 'splash',
  NATIVE = 'native'
}

export enum AdSize {
  BANNER_STANDARD = '320x50',
  BANNER_LARGE = '728x90',
  BANNER_SMART = 'smart',
  MEDIUM_RECTANGLE = '300x250',
  FULL_BANNER = '320x480',
  LEADERBOARD = '728x90'
}

export interface AdConfig {
  type: AdType;
  adId: string;
  testMode: boolean;
  refreshInterval?: number;
  size?: AdSize;
}

export enum AdStatus {
  LOADING = 'loading',
  LOADED = 'loaded',
  SHOWING = 'showing',
  CLOSED = 'closed',
  FAILED = 'failed',
  CLICKED = 'clicked'
}

export interface AdListener {
  onAdLoaded?: () => void;
  onAdFailed?: (error: Error) => void;
  onAdOpened?: () => void;
  onAdClosed?: () => void;
  onAdClicked?: () => void;
  onUserEarnedReward?: (amount: number, type: string) => void;
}

interface AdInstance {
  component: BannerAd | InterstitialAd | RewardedAd | NativeAd | null;
  status: AdStatus;
  listener: AdListener | null;
  config: AdConfig;
}

class AdsKitService {
  private static instance: AdsKitService;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private adInstances: Map<string, AdInstance> = new Map();

  private constructor() {}

  static getInstance(): AdsKitService {
    if (!AdsKitService.instance) {
      AdsKitService.instance = new AdsKitService();
    }
    return AdsKitService.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    try {
      this.context = context;
      await ads.init();
      this.isInitialized = true;
      return true;
    } catch (error) {
      console.error('AdsKit init failed:', error);
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  async createBannerAd(config: AdConfig, listener?: AdListener): Promise<BannerAd | null> {
    try {
      if (!this.isReady()) {
        throw new Error('AdsKit not initialized');
      }

      const adParams: AdCreateParams = {
        adId: config.adId,
        adSize: config.size || AdSize.BANNER_STANDARD,
        testAd: config.testMode
      };
      const bannerAd: BannerAd = ads.createBannerAd(adParams);

      if (listener) {
        bannerAd.on('load', () => {
          if (listener.onAdLoaded) {
            listener.onAdLoaded();
          }
        });

        bannerAd.on('error', (error: Error) => {
          if (listener.onAdFailed) {
            listener.onAdFailed(error);
          }
        });

        bannerAd.on('click', () => {
          if (listener.onAdClicked) {
            listener.onAdClicked();
          }
        });
      }

      await bannerAd.load();

      const adInstance: AdInstance = {
        component: bannerAd,
        status: AdStatus.LOADED,
        listener: listener || null,
        config: config
      };
      this.adInstances.set(config.adId, adInstance);

      return bannerAd;
    } catch (error) {
      console.error('CreateBannerAd failed:', error);
      return null;
    }
  }

  async showBannerAd(adId: string): Promise<boolean> {
    try {
      const instance = this.adInstances.get(adId);
      if (!instance || !instance.component) {
        throw new Error('Banner ad not found');
      }

      await (instance.component as BannerAd).show();
      instance.status = AdStatus.SHOWING;
      return true;
    } catch (error) {
      console.error('ShowBannerAd failed:', error);
      return false;
    }
  }

  async hideBannerAd(adId: string): Promise<boolean> {
    try {
      const instance = this.adInstances.get(adId);
      if (!instance || !instance.component) {
        return false;
      }

      await (instance.component as BannerAd).hide();
      instance.status = AdStatus.CLOSED;
      return true;
    } catch (error) {
      console.error('HideBannerAd failed:', error);
      return false;
    }
  }

  async destroyBannerAd(adId: string): Promise<boolean> {
    try {
      const instance = this.adInstances.get(adId);
      if (!instance || !instance.component) {
        return false;
      }

      await (instance.component as BannerAd).destroy();
      this.adInstances.delete(adId);
      return true;
    } catch (error) {
      console.error('DestroyBannerAd failed:', error);
      return false;
    }
  }

  async loadInterstitialAd(config: AdConfig, listener?: AdListener): Promise<InterstitialAd | null> {
    try {
      if (!this.isReady()) {
        throw new Error('AdsKit not initialized');
      }

      const interstitialAdParams: AdCreateParams = {
        adId: config.adId,
        testAd: config.testMode
      };
      const interstitialAd: InterstitialAd = ads.createInterstitialAd(interstitialAdParams);

      if (listener) {
        interstitialAd.on('load', () => {
          if (listener.onAdLoaded) {
            listener.onAdLoaded();
          }
        });

        interstitialAd.on('error', (error: Error) => {
          if (listener.onAdFailed) {
            listener.onAdFailed(error);
          }
        });

        interstitialAd.on('close', () => {
          if (listener.onAdClosed) {
            listener.onAdClosed();
          }
        });
      }

      await interstitialAd.load();

      const adInstance: AdInstance = {
        component: interstitialAd,
        status: AdStatus.LOADED,
        listener: listener || null,
        config: config
      };
      this.adInstances.set(config.adId, adInstance);

      return interstitialAd;
    } catch (error) {
      console.error('LoadInterstitialAd failed:', error);
      return null;
    }
  }

  async showInterstitialAd(adId: string): Promise<boolean> {
    try {
      const instance = this.adInstances.get(adId);
      if (!instance || !instance.component) {
        throw new Error('Interstitial ad not found');
      }

      await (instance.component as InterstitialAd).show();
      instance.status = AdStatus.SHOWING;
      return true;
    } catch (error) {
      console.error('ShowInterstitialAd failed:', error);
      return false;
    }
  }

  async loadRewardedAd(config: AdConfig, listener?: AdListener): Promise<RewardedAd | null> {
    try {
      if (!this.isReady()) {
        throw new Error('AdsKit not initialized');
      }

      const rewardedAdParams: AdCreateParams = {
        adId: config.adId,
        testAd: config.testMode
      };
      const rewardedAd: RewardedAd = ads.createRewardedAd(rewardedAdParams);

      if (listener) {
        rewardedAd.on('load', () => {
          if (listener.onAdLoaded) {
            listener.onAdLoaded();
          }
        });

        rewardedAd.on('error', (error: Error) => {
          if (listener.onAdFailed) {
            listener.onAdFailed(error);
          }
        });

        rewardedAd.on('close', () => {
          if (listener.onAdClosed) {
            listener.onAdClosed();
          }
        });

        rewardedAd.on('reward', (amount: number, type: string) => {
          if (listener.onUserEarnedReward) {
            listener.onUserEarnedReward(amount, type);
          }
        });
      }

      await rewardedAd.load();

      const adInstance: AdInstance = {
        component: rewardedAd,
        status: AdStatus.LOADED,
        listener: listener || null,
        config: config
      };
      this.adInstances.set(config.adId, adInstance);

      return rewardedAd;
    } catch (error) {
      console.error('LoadRewardedAd failed:', error);
      return null;
    }
  }

  async showRewardedAd(adId: string): Promise<boolean> {
    try {
      const instance = this.adInstances.get(adId);
      if (!instance || !instance.component) {
        throw new Error('Rewarded ad not found');
      }

      await (instance.component as RewardedAd).show();
      instance.status = AdStatus.SHOWING;
      return true;
    } catch (error) {
      console.error('ShowRewardedAd failed:', error);
      return false;
    }
  }

  async loadNativeAd(config: AdConfig, listener?: AdListener): Promise<NativeAd | null> {
    try {
      if (!this.isReady()) {
        throw new Error('AdsKit not initialized');
      }

      const nativeAdParams: AdCreateParams = {
        adId: config.adId,
        testAd: config.testMode
      };
      const nativeAd: NativeAd = ads.createNativeAd(nativeAdParams);

      if (listener) {
        nativeAd.on('load', () => {
          if (listener.onAdLoaded) {
            listener.onAdLoaded();
          }
        });

        nativeAd.on('error', (error: Error) => {
          if (listener.onAdFailed) {
            listener.onAdFailed(error);
          }
        });

        nativeAd.on('click', () => {
          if (listener.onAdClicked) {
            listener.onAdClicked();
          }
        });
      }

      await nativeAd.load();

      const adInstance: AdInstance = {
        component: nativeAd,
        status: AdStatus.LOADED,
        listener: listener || null,
        config: config
      };
      this.adInstances.set(config.adId, adInstance);

      return nativeAd;
    } catch (error) {
      console.error('LoadNativeAd failed:', error);
      return null;
    }
  }

  getAdStatus(adId: string): AdStatus {
    const instance = this.adInstances.get(adId);
    return instance ? instance.status : AdStatus.FAILED;
  }

  async releaseAllAds(): Promise<void> {
    try {
      const entries = Array.from(this.adInstances.entries());
      for (let i = 0; i < entries.length; i++) {
        const instance = entries[i][1];
        if (instance.component) {
          await instance.component.destroy();
        }
      }
      this.adInstances.clear();
    } catch (error) {
      console.error('ReleaseAllAds failed:', error);
    }
  }

  release(): void {
    this.releaseAllAds();
    this.isInitialized = false;
    this.context = null;
  }
}

export const adsKitService = AdsKitService.getInstance();
export default adsKitService;
