/**
 * FeedbackPage ViewModel - V2鐗堟湰
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

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
    { id: 'bug', name: '闂鍙嶉', icon: '馃悰' },
    { id: 'suggest', name: '鍔熻兘寤鸿', icon: '馃挕' },
    { id: 'other', name: '鍏朵粬', icon: '馃摑' }
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
      // 淇濆瓨鍙嶉鍒版湰鍦?
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
