import { logger } from '.\.\common/utils/Logger';
/**
 * RewardPage ViewModel - V2鐗堟�?
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors, LIGHT_COLORS } from '../utils/AppTheme';

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
    { id: 'coffee', name: '一杯咖�?, price: 6, description: '支持开发者一杯咖�?, icon: '�? },
    { id: 'lunch', name: '一顿午�?, price: 18, description: '支持开发者一顿午�?, icon: '🍚' },
    { id: 'month', name: '月度支持', price: 30, description: '月度支持开发�?, icon: '📅' },
    { id: 'year', name: '年度支持', price: 288, description: '年度支持开发�?, icon: '🎁' }
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
      // 妯℃嫙鏀粯娴佺chevron_down
      await new Promise<void>((resolve) => setTimeout(resolve, 1500));

      // 璁板綍鏀寔璁板�?
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
    // 鍔犺浇鏀粯鍘嗗彶锛屽鏋滈渶瑕佺殑�?
    // 鐩墠淇濇寔绌哄疄鐜帮紝鍚庣画鍙墿�?
  }

  async pay(amount: number): Promise<boolean> {
    if (amount <= 0) return false;

    this.isProcessing = true;
    try {
      // 妯℃嫙鏀粯娴佺chevron_down
      await new Promise<void>((resolve) => setTimeout(resolve, 1500));

      // 璁板綍鏀粯鍘嗗�?
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
