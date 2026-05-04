/**
 * FeedbackPage ViewModel - V2閻楀牊婀?
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../../../common/utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../../../common/constants/AppTheme';

interface FeedbackCategory {
  id: string;
  name: string;
  icon: string;
}

interface FeedbackRecord {
  id: string;
  type: string;
  title: string;
  content: string;
  contact: string;
  screenshots: string[];
  createTime: number;
}

@ObservedV2
export class FeedbackViewModel {
  @Trace feedbackType: string = 'bug';
  @Trace title: string = '';
  @Trace content: string = '';
  @Trace contact: string = '';
  @Trace screenshots: string[] = [];
  @Trace isSubmitting: boolean = false;
  @Trace submitSuccess: boolean = false;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();

  categories: FeedbackCategory[] = [
    { id: 'bug', name: '闂傤噣顣介崣宥夘洯', icon: '棣冩偘' },
    { id: 'suggest', name: '閸旂喕鍏樺楦款唴', icon: '棣冩寱' },
    { id: 'other', name: '閸忔湹绮?, icon: '棣冩憫' }
  ];

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
  }

  setType(type: string): void {
    this.feedbackType = type;
  }

  setTitle(title: string): void {
    this.title = title;
  }

  setContent(content: string): void {
    this.content = content;
  }

  setContact(contact: string): void {
    this.contact = contact;
  }

  async submit(): Promise<boolean> {
    if (!this.title.trim() || !this.content.trim()) {
      return false;
    }

    this.isSubmitting = true;
    
    try {
      // 娣囨繂鐡ㄩ崣宥夘洯閸掔増婀伴崷?
      const feedback: FeedbackRecord = {
        id: 'fb_' + Date.now(),
        type: this.feedbackType,
        title: this.title,
        content: this.content,
        contact: this.contact,
        screenshots: this.screenshots,
        createTime: Date.now()
      };
      
      const existing = preferenceManager.getString('feedback_list', '[]');
      const list: FeedbackRecord[] = JSON.parse(existing) as FeedbackRecord[];
      list.push(feedback);
      preferenceManager.setString('feedback_list', JSON.stringify(list));
      
      this.submitSuccess = true;
      return true;
    } catch (error) {
      const err = error as Error;
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  reset(): void {
    this.feedbackType = 'bug';
    this.title = '';
    this.content = '';
    this.contact = '';
    this.screenshots = [];
    this.submitSuccess = false;
  }
}

export const feedbackViewModel = new FeedbackViewModel();
