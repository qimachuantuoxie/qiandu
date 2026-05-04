import { logger } from '../../../utils/Logger';
/**
 * HarmonyOS Payment Service - 楦胯挋鏀�粯鏈嶅姟
 * 鎺ュ叆鍗庝负搴旂敤鍐呮敮浠橈紙IAP锛? * 浣跨敤 @kit.InAppPurchasesKit 瀹炵幇鐪熷疄鏀�粯
 *
 * @since 7.0.0
 */

import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
// TODO: @kit.InAppPurchasesKit not available in this SDK version
// import { iap, ProductInfo, PurchaseInfo, PurchaseResult } from '@kit.InAppPurchasesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferenceManager } from '../utils/PreferenceManager';

// Stub types for InAppPurchasesKit (replace when SDK supports)
interface StubProductInfo { productId: string; name: string; price: string; currency: string; description: string; }
interface StubPurchaseInfo { productId: string; purchaseTime: number; orderId: string; }
interface StubPurchaseResult { result: number; purchaseInfo?: StubPurchaseInfo; errMsg?: string; returnCode?: number; }
interface StubIapClient {
  init(): Promise<void>;
  createPurchase(req: PurchaseRequest): Promise<StubPurchaseResult>;
  obtainProductInfo(req: ProductInfoRequest): Promise<StubProductInfoResponse>;
  obtainOwnedPurchases(req: OwnedPurchasesRequest): Promise<StubOwnedPurchasesResponse>;
  consumePurchase(req: ConsumeRequest): Promise<StubConsumeResponse>;
  getProductInfo(productId: string): Promise<StubProductInfo | null>;
  getPurchaseInfo(orderId: string): Promise<StubPurchaseInfo | null>;
  confirmOrder(req: ConfirmOrderRequest): Promise<StubConfirmOrderResponse>;
  destroy(): void;
}
interface StubPurchaseRequest { productId: string; developerPayload: string; }
interface StubProductInfoRequest { productIds: string[]; }
interface StubOwnedPurchasesRequest { }
interface StubConsumeRequest { purchaseToken: string; }
interface StubConfirmOrderRequest { orderId: string; }
interface StubProductInfoResponse { returnCode: number; productInfoList?: StubProductInfo[]; }
interface StubOwnedPurchasesResponse { returnCode: number; purchaseInfoList?: StubPurchaseInfo[]; }
interface StubConsumeResponse { returnCode: number; }
interface StubConfirmOrderResponse { returnCode: number; }
interface ConfirmOrderRequest { orderId: string; }
type PurchaseRequest = StubPurchaseRequest;
type IapClient = StubIapClient;
type ProductInfoRequest = StubProductInfoRequest;
type OwnedPurchasesRequest = StubOwnedPurchasesRequest;
type ConsumeRequest = StubConsumeRequest;
type StubIap = {
  createIapClient(): StubIapClient;
  createPurchase(req: PurchaseRequest): Promise<StubPurchaseResult>;
  getProductInfo(productId: string): Promise<StubProductInfo | null>;
  getPurchaseInfo(orderId: string): Promise<StubPurchaseInfo | null>;
};
const iap: StubIap = {
  createIapClient: (): StubIapClient => ({
    init: async () => {},
    createPurchase: async (): Promise<StubPurchaseResult> => ({ result: 0, returnCode: 0, errMsg: 'IAP not available' }),
    obtainProductInfo: async (): Promise<StubProductInfoResponse> => ({ returnCode: -1, productInfoList: [] }),
    obtainOwnedPurchases: async (): Promise<StubOwnedPurchasesResponse> => ({ returnCode: -1, purchaseInfoList: [] }),
    consumePurchase: async (): Promise<StubConsumeResponse> => ({ returnCode: -1 }),
    getProductInfo: async (): Promise<null> => null,
    getPurchaseInfo: async (): Promise<null> => null,
    confirmOrder: async (): Promise<StubConfirmOrderResponse> => ({ returnCode: 0 }),
    destroy: () => {}
  }),
  createPurchase: async (): Promise<StubPurchaseResult> => ({ result: 0, returnCode: 0, errMsg: 'IAP not available' }),
  getProductInfo: async (): Promise<null> => null,
  getPurchaseInfo: async (): Promise<null> => null,
};
type ProductInfo = StubProductInfo;
type PurchaseInfo = StubPurchaseInfo;
type PurchaseResult = StubPurchaseResult;

const DOMAIN = 0xFF04;

/**
 * 鎵撹祻閲戦�閫夐」
 */
export interface RewardOption {
  /** 閲戦�锛堝厓锛?*/
  amount: number;
  /** 鍟嗗搧ID锛堝湪AppGallery Connect涓�厤缃�級 */
  productId: string;
  /** 鏄剧ず鍚嶇О */
  displayName: string;
  /** 鎻忚堪 */
  description: string;
  /** 鍥炬爣 */
  icon: string;
}

/**
 * 鏀�粯鐘舵€? */
export enum PaymentStatus {
  /** 寰呮敮浠?*/
  PENDING = 'pending',
  /** 鏀�粯鎴愬姛 */
  SUCCESS = 'success',
  /** 鏀�粯澶辫触 */
  FAILED = 'failed',
  /** 宸插彇娑?*/
  CANCELLED = 'cancelled'
}

/**
 * 鏀�粯缁撴灉
 */
export interface PaymentResult {
  /** 鏄�惁鎴愬姛 */
  success: boolean;
  /** 鐘舵€?*/
  status: PaymentStatus;
  /** 璁㈠崟鍙?*/
  orderId?: string;
  /** 鍟嗗搧ID */
  productId?: string;
  /** 閲戦� */
  amount?: number;
  /** 閿欒�淇℃伅 */
  error?: string;
}

/**
 * 鎵撹祻璁板綍
 */
export interface RewardRecord {
  /** 璁板綍ID */
  id: string;
  /** 閲戦� */
  amount: number;
  /** 鍟嗗搧ID */
  productId: string;
  /** 鏃堕棿 */
  timestamp: number;
  /** 璁㈠崟鍙?*/
  orderId: string;
  /** 鐣欒█ */
  message?: string;
}

/**
 * 楦胯挋鏀�粯鏈嶅姟绫? */
class HarmonyPaymentService {
  /** 鍗曚緥瀹炰緥 */
  private static instance: HarmonyPaymentService;

  /** 涓婁笅鏂?*/
  private context: common.Context | null = null;

  /** 鏄�惁宸插垵濮嬪寲 */
  private isInitialized: boolean = false;

  /** 鎵撹祻璁板綍 */
  private rewardRecords: RewardRecord[] = [];

  /** IAP 瀹㈡埛绔?*/
  private iapClient: IapClient | null = null;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): HarmonyPaymentService {
    if (!HarmonyPaymentService.instance) {
      HarmonyPaymentService.instance = new HarmonyPaymentService();
    }
    return HarmonyPaymentService.instance;
  }

  /**
   * 鍒濆�鍖栨敮浠樻湇鍔?   */
  async init(context: common.Context): Promise<boolean> {
    try {
      logger.info('[HarmonyPayment] Initializing...');
      this.context = context;

      // 鍒涘缓 IAP 瀹㈡埛绔?      this.iapClient = iap.createIapClient();

      // 鍒濆�鍖?IAP 鏈嶅姟
      await this.iapClient.init();

      // 鍔犺浇鍘嗗彶璁板綍
      await this.loadRewardRecords();

      this.isInitialized = true;
      logger.info('[HarmonyPayment] Initialized successfully');
      return true;
    } catch (error) {
      logger.error('[HarmonyPayment] Init failed:', error);
      return false;
    }
  }

  /**
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null && this.iapClient !== null;
  }

  // ==================== 鎵撹祻閫夐」 ====================

  /**
   * 鑾峰彇鎵撹祻閲戦�閫夐」
   */
  getRewardOptions(): RewardOption[] {
    return [
      {
        amount: 1,
        productId: 'reward_1_cny',
        displayName: '璇蜂綔鑰呭枬鏉�按',
        description: '鎰熻阿鎮ㄧ殑鏀�寔锛?,
        icon: '猸?
      },
      {
        amount: 6,
        productId: 'reward_6_cny',
        displayName: '璇蜂綔鑰呭悆涓�啺娣囨穻',
        description: '鎮ㄧ殑鏀�寔鏄�垜鏈€澶х殑鍔ㄥ姏锛?,
        icon: '馃崷'
      },
      {
        amount: 18,
        productId: 'reward_18_cny',
        displayName: '缁欎綔鑰呭姞涓�浮鑵?,
        description: '鎰熻阿鎮ㄧ殑鎱锋叏鎵撹祻锛?,
        icon: '馃崡'
      },
      {
        amount: 30,
        productId: 'reward_30_cny',
        displayName: 'VIP瓒呯骇鎵撹祻',
        description: '鎮ㄦ槸鐪熺埍绮夛紒',
        icon: '馃挅'
      },
      {
        amount: 66,
        productId: 'reward_66_cny',
        displayName: '66澶ч『',
        description: '绁濇偍浜嬩簨椤哄績锛?,
        icon: '馃帄'
      },
      {
        amount: 88,
        productId: 'reward_88_cny',
        displayName: '88鍙戣储',
        description: '鎭�枩鍙戣储锛岃储婧愬箍杩涳紒',
        icon: '馃挵'
      }
    ];
  }

  // ==================== 鏀�粯娴佺▼ ====================

  /**
   * 鍒涘缓鎵撹祻璁㈠崟
   */
  async createRewardOrder(productId: string, amount: number, message?: string): Promise<PaymentResult> {
    try {
      if (!this.isReady()) {
        throw new Error('Payment service not initialized');
      }

      logger.info('[HarmonyPayment] Creating reward order:', productId, amount);

      // 鑾峰彇鍟嗗搧淇℃伅
      const productInfo = await this.getProductInfo(productId);
      if (!productInfo) {
        throw new Error(`Product not found: ${productId}`);
      }

      // 鍒涘缓璐�拱璇锋眰
      const purchaseRequest: PurchaseRequest = {
        productId: productId,
        developerPayload: message || ''
      };

      // 鎵ц�璐�拱
      const purchaseResult: PurchaseResult = await this.iapClient!.createPurchase(purchaseRequest);

      if (purchaseResult.returnCode === 0) {
        // 鏀�粯鎴愬姛
        const purchaseInfo: PurchaseInfo = purchaseResult.purchaseInfo!;
        
        // 淇濆瓨鎵撹祻璁板綍
        const record: RewardRecord = {
          id: Date.now().toString(),
          amount: amount,
          productId: productId,
          timestamp: Date.now(),
          orderId: purchaseInfo.orderId || '',
          message: message
        };

        this.rewardRecords.push(record);
        await this.saveRewardRecords();

        logger.info('[HarmonyPayment] Reward order success:', purchaseInfo.orderId);

        return {
          success: true,
          status: PaymentStatus.SUCCESS,
          orderId: purchaseInfo.orderId,
          productId: productId,
          amount: amount
        };
      } else if (purchaseResult.returnCode === 60050) {
        // 鐢ㄦ埛鍙栨秷
        logger.info('[HarmonyPayment] User cancelled payment');
        return {
          success: false,
          status: PaymentStatus.CANCELLED,
          error: '鐢ㄦ埛鍙栨秷鏀�粯'
        };
      } else {
        // 鏀�粯澶辫触
        throw new Error(`Purchase failed with code: ${purchaseResult.returnCode}`);
      }
    } catch (error) {
      logger.error('[HarmonyPayment] Create reward order failed:', error);

      let errorCode = 0;
      if (error instanceof Error) {
        errorCode = 1;
      }

      return {
        success: false,
        status: PaymentStatus.FAILED,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * 鑾峰彇鍟嗗搧淇℃伅
   */
  async getProductInfo(productId: string): Promise<ProductInfo | null> {
    try {
      if (!this.isReady()) {
        return null;
      }

      const productInfoRequest: ProductInfoRequest = {
        productIds: [productId]
      };

      const response = await this.iapClient!.obtainProductInfo(productInfoRequest);
      
      if (response.returnCode === 0 && response.productInfoList && response.productInfoList.length > 0) {
        return response.productInfoList[0];
      }

      return null;
    } catch (error) {
      logger.error('[HarmonyPayment] Get product info failed:', error);
      return null;
    }
  }

  /**
   * 鑾峰彇鎵€鏈夊晢鍝佸垪琛?   */
  async getAllProducts(productIds: string[]): Promise<ProductInfo[]> {
    try {
      if (!this.isReady()) {
        return [];
      }

      const productInfoRequest: ProductInfoRequest = {
        productIds: productIds
      };

      const response = await this.iapClient!.obtainProductInfo(productInfoRequest);
      
      if (response.returnCode === 0 && response.productInfoList) {
        return response.productInfoList;
      }

      return [];
    } catch (error) {
      logger.error('[HarmonyPayment] Get all products failed:', error);
      return [];
    }
  }

  /**
   * 鏌ヨ�宸茶喘鍟嗗搧
   */
  async getOwnedPurchases(): Promise<PurchaseInfo[]> {
    try {
      if (!this.isReady()) {
        return [];
      }

      const ownedPurchasesRequest: OwnedPurchasesRequest = {};
      const response = await this.iapClient!.obtainOwnedPurchases(ownedPurchasesRequest);
      
      if (response.returnCode === 0 && response.purchaseInfoList) {
        return response.purchaseInfoList;
      }

      return [];
    } catch (error) {
      logger.error('[HarmonyPayment] Get owned purchases failed:', error);
      return [];
    }
  }

  /**
   * 娑堣€楀晢鍝侊紙鐢ㄤ簬娑堣€楀瀷鍟嗗搧锛?   */
  async consumePurchase(purchaseToken: string): Promise<boolean> {
    try {
      if (!this.isReady()) {
        return false;
      }

      const consumeRequest: ConsumeRequest = {
        purchaseToken: purchaseToken
      };

      const response = await this.iapClient!.consumePurchase(consumeRequest);
      return response.returnCode === 0;
    } catch (error) {
      logger.error('[HarmonyPayment] Consume purchase failed:', error);
      return false;
    }
  }

  /**
   * 纭��璁㈠崟锛堢敤浜庣‘璁ゆ敹璐э級
   */
  async confirmOrder(orderId: string): Promise<boolean> {
    try {
      if (!this.isReady()) {
        return false;
      }

      const confirmRequest: ConfirmOrderRequest = {
        orderId: orderId
      };

      const response = await this.iapClient!.confirmOrder(confirmRequest);
      return response.returnCode === 0;
    } catch (error) {
      logger.error('[HarmonyPayment] Confirm order failed:', error);
      return false;
    }
  }

  // ==================== 鎵撹祻璁板綍 ====================

  /**
   * 鍔犺浇鎵撹祻璁板綍
   */
  private async loadRewardRecords(): Promise<void> {
    try {
      const recordsJson = await preferenceManager.getValue('reward_records', '[]');
      this.rewardRecords = JSON.parse(recordsJson) as RewardRecord[];
      logger.info('[HarmonyPayment] Loaded', this.rewardRecords.length, 'reward records');
    } catch (error) {
      logger.error('[HarmonyPayment] Load reward records failed:', error);
      this.rewardRecords = [];
    }
  }

  /**
   * 淇濆瓨鎵撹祻璁板綍
   */
  private async saveRewardRecords(): Promise<void> {
    try {
      const recordsJson = JSON.stringify(this.rewardRecords);
      await preferenceManager.setValue('reward_records', recordsJson);
    } catch (error) {
      logger.error('[HarmonyPayment] Save reward records failed:', error);
    }
  }

  /**
   * 鑾峰彇鎵撹祻璁板綍
   */
  getRewardRecords(): RewardRecord[] {
    return this.rewardRecords;
  }

  /**
   * 鑾峰彇鎵撹祻鎬婚�
   */
  getTotalRewardAmount(): number {
    return this.rewardRecords.reduce((sum: number, record: RewardRecord) => sum + record.amount, 0);
  }

  /**
   * 鑾峰彇鎵撹祻娆℃暟
   */
  getRewardCount(): number {
    return this.rewardRecords.length;
  }

  /**
   * 鏍煎紡鍖栭噾棰濇樉绀?   */
  formatAmount(amount: number): string {
    return `楼${amount.toFixed(2)}`;
  }

  // ==================== 宸ュ叿鏂规硶 ====================

  /**
   * 閲婃斁璧勬簮
   */
  release(): void {
    if (this.iapClient) {
      this.iapClient.destroy();
      this.iapClient = null;
    }
    this.isInitialized = false;
    this.context = null;
    logger.info('[HarmonyPayment] Released');
  }
}

// 瀵煎嚭鍗曚緥
export const harmonyPayment = HarmonyPaymentService.getInstance();
export default harmonyPayment;
