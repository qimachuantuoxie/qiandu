/**
 * SkillPage ViewModel - V2鐗堟湰
 */
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

export interface SkillItem {
  id: string;
  name: string;
  description: string;
  icon: string;
  unlocked: boolean;
  level: number;
}

@ObservedV2
export class SkillViewModel {
  @Trace skills: SkillItem[] = [];
  @Trace selectedSkill: SkillItem | null = null;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace experience: number = 0;
  @Trace level: number = 1;

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadSkills();
    this.loadUserProgress();
  }

  loadSkills(): void {
this.skills = [
      { id: 'reader', name: 'Reading Master', description: 'Read 100 hours', icon: '📚', unlocked: false, level: 1 },
      { id: 'collector', name: 'Collection Master', description: 'Collect 100 books', icon: '📖', unlocked: false, level: 1 },
      { id: 'note_taker', name: 'Note Taker', description: 'Create 100 notes', icon: '✏', unlocked: false, level: 1 },
      { id: 'early_bird', name: 'Early Bird', description: 'Read for 7 days', icon: '🌅', unlocked: false, level: 1 },
      { id: 'night_owl', name: 'Night Owl', description: 'Read 10 hours', icon: '🦉', unlocked: false, level: 1 },
      { id: 'completionist', name: 'Completionist', description: 'Finish 50 books', icon: '🎯', unlocked: false, level: 1 }
    ];
  }

  loadUserProgress(): void {
    this.experience = preferenceManager.getNumber('skill_experience', 0);
    this.level = Math.floor(this.experience / 1000) + 1;

    // 妫€鏌ュ凡瑙ｉ攣鐨勬妧鑳?
    const unlocked = preferenceManager.getString('unlocked_skills', '').split(',');
    const newSkills: SkillItem[] = [];
    for (let i = 0; i < this.skills.length; i++) {
      const s = this.skills[i];
      newSkills.push({
        id: s.id,
        name: s.name,
        description: s.description,
        icon: s.icon,
        unlocked: unlocked.includes(s.id) ? true : s.unlocked,
        level: s.level
      });
    }
    this.skills = newSkills;
  }

  selectSkill(skill: SkillItem): void {
    this.selectedSkill = skill;
  }

  clearSelection(): void {
    this.selectedSkill = null;
  }
}

export const skillViewModel = new SkillViewModel();
