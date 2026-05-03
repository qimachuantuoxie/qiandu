/**
 * WordBookPage ViewModel - V2鐗堟湰
 */
import { bookViewModel } from './BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';

interface WordItem {
  id: string;
  word: string;
  pronunciation: string;
  definition: string;
  example: string;
  bookId: string;
  bookTitle: string;
  createTime: number;
}

@ObservedV2
export class WordBookViewModel {
  @Trace words: WordItem[] = [];
  @Trace filteredWords: WordItem[] = [];
  @Trace searchText: string = '';
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace isLoading: boolean = false;

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.loadWords();
  }

  loadWords(): void {
    try {
      const saved = preferenceManager.getString('word_book', '[]');
      this.words = JSON.parse(saved);
      this.applyFilter();
    } catch (error) {
      console.error('Load words failed:', (error as Error).message);
      this.words = [];
      this.filteredWords = [];
    }
  }

  applyFilter(): void {
    if (this.searchText.trim() === '') {
      const filtered: WordItem[] = [];
      for (let i = 0; i < this.words.length; i++) {
        filtered.push(this.words[i]);
      }
      this.filteredWords = filtered;
    } else {
      const keyword = this.searchText.toLowerCase();
      const filtered: WordItem[] = [];
      for (let i = 0; i < this.words.length; i++) {
        const w = this.words[i];
        if (w.word.toLowerCase().includes(keyword) || w.definition.toLowerCase().includes(keyword)) {
          filtered.push(w);
        }
      }
      this.filteredWords = filtered;
    }
  }

  search(keyword: string): void {
    this.searchText = keyword;
    this.applyFilter();
  }

  addWord(word: WordItem): void {
    const newWords = [word];
    for (let i = 0; i < this.words.length; i++) {
      newWords.push(this.words[i]);
    }
    this.words = newWords;
    this.saveWords();
    this.applyFilter();
  }

  deleteWord(wordId: string): void {
    let index = -1;
    for (let i = 0; i < this.words.length; i++) {
      if (this.words[i].id === wordId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const newWords: WordItem[] = [];
      for (let i = 0; i < this.words.length; i++) {
        if (i !== index) {
          newWords.push(this.words[i]);
        }
      }
      this.words = newWords;
      this.saveWords();
      this.applyFilter();
    }
  }

  private saveWords(): void {
    preferenceManager.setString('word_book', JSON.stringify(this.words));
  }
}

export const wordBookViewModel = new WordBookViewModel();
