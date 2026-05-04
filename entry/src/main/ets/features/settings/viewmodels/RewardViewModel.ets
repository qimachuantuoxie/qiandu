import { logger } from '.\.\common/utils/Logger';
/**
 * RewardPage ViewModel - V2閻楀牊婀?
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { appTheme, themeManager, AppColors, LIGHT_COLORS } from '../../../common/constants/AppTheme';

interface RewardHistoryItem {
  id: string;
  rewardId?: string;
  price?: number;
  amount?: number;
  time: number;
}

export interface RewardItem {
  id: string;
  name: string;
  price: number;
  description: string;
  icon: string;
}

@ObservedV2
export class RewardViewModel {
  @Trace selectedReward: RewardItem | null = null;
  @Trace isProcessing: boolean = false;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = LIGHT_COLORS;
  @Trace showSuccessDialog: boolean = false;
  @Trace totalRewards: number = 0;
  @Trace totalRewardAmount: number = 0;

rewardItems: RewardItem[] = [
    { id: 'coffee', name: '涓€鏉�挅鍟?, price: 6, description: '鏀�寔寮€鍙戣€呬竴鏉�挅鍟?, icon: '鈽? },
    { id: 'lunch', name: '涓€椤垮崍椁?, price: 18, description: '鏀�寔寮€鍙戣€呬竴椤垮崍椁?, icon: '馃崥' },
    { id: 'month', name: '鏈堝害鏀�寔', price: 30, description: '鏈堝害鏀�寔寮€鍙戣€?, icon: '馃搮' },
    { id: 'year', name: '骞村害鏀�寔', price: 288, description: '骞村害鏀�寔寮€鍙戣€?, icon: '馃巵' }
  ];

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
  }

  selectReward(item: RewardItem): void {
    this.selectedReward = item;
  }

  async processPayment(): Promise<boolean> {
    if (!this.selectedReward) return false;

    this.isProcessing = true;
    try {
      // 濡�剝瀚欓弨顖欑帛濞翠胶chevron_down
      await new Promise<void>((resolve) => setTimeout(resolve, 1500));

      // 鐠佹澘缍嶉弨顖涘瘮鐠佹澘缍?
      const history = preferenceManager.getString('reward_history', '[]');
      const list: RewardHistoryItem[] = JSON.parse(history) as RewardHistoryItem[];
      const newItem: RewardHistoryItem = {
        id: 'reward_' + Date.now(),
        rewardId: this.selectedReward.id,
        price: this.selectedReward.price,
        time: Date.now()
      };
      list.push(newItem);
      preferenceManager.setString('reward_history', JSON.stringify(list));

      this.showSuccessDialog = true;
      return true;
    } catch (error) {
      const err = error as Error;
      return false;
    } finally {
      this.isProcessing = false;
    }
  }

  async loadPaymentHistory(): Promise<void> {
    // 閸旂姾娴囬弨顖欑帛閸樺棗褰堕敍灞筋洤閺嬫粓娓剁憰浣烘畱鐠?
    // 閻╊喖澧犳穱婵囧瘮缁屽搫鐤勯悳甯�礉閸氬海鐢婚崣顖涘⒖鐏?
  }

  async pay(amount: number): Promise<boolean> {
    if (amount <= 0) return false;

    this.isProcessing = true;
    try {
      // 濡�剝瀚欓弨顖欑帛濞翠胶chevron_down
      await new Promise<void>((resolve) => setTimeout(resolve, 1500));

      // 鐠佹澘缍嶉弨顖欑帛閸樺棗褰?
      const history = preferenceManager.getString('reward_history', '[]');
      const list: RewardHistoryItem[] = JSON.parse(history) as RewardHistoryItem[];
      const newItem: RewardHistoryItem = {
        id: 'reward_' + Date.now(),
        amount: amount,
        time: Date.now()
      };
      list.push(newItem);
      preferenceManager.setString('reward_history', JSON.stringify(list));

      return true;
    } catch (error) {
      const err = error as Error;
      logger.error('Pay failed:', err.message);
      return false;
    } finally {
      this.isProcessing = false;
    }
  }

  closeSuccessDialog(): void {
    this.showSuccessDialog = false;
    this.selectedReward = null;
  }
}

export const rewardViewModel = new RewardViewModel();
