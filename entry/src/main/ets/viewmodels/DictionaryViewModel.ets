/**
 * DictionaryPage ViewModel
 */

import { dictionaryManager, advancedNoteManager, DictionaryResult, WordBookItem } from '../models/AdvancedReading';
import { preferenceManager } from '../utils/PreferenceManager';

@ObservedV2
export class DictionaryViewModel {
  @Trace searchHistory: string[] = [];
  @Trace searchWord: string = '';
  @Trace currentWord: string = '';
  @Trace currentResult: DictionaryResult | null = null;
  @Trace showResult: boolean = false;
  @Trace definitions: string[] = [];
  @Trace isLoading: boolean = false;
  @Trace isAddedToWordBook: boolean = false;
  @Trace selectedLanguage: 'zh' | 'en' = 'en';

  /**
   * 鍒濆鍖?
   */
  async init(): Promise<void> {
    try {
      const history = await preferenceManager.getValue('dictionary_history', '');
      if (history) {
        const parts = history.split(',');
        const result: string[] = [];
        const limit = parts.length < 10 ? parts.length : 10;
        for (let i = 0; i < limit; i++) {
          result.push(parts[i]);
        }
        this.searchHistory = result;
      }
    } catch (error) {
      console.info('Load dictionary history failed');
    }
  }

  /**
   * 鎼滅储鍗曡瘝
   */
  async search(word: string): Promise<void> {
    if (!word.trim()) return;

    this.isLoading = true;
    this.showResult = false;

    try {
      const result = await dictionaryManager.queryWord(word.trim().toLowerCase(), this.selectedLanguage);
      this.currentResult = result;
      this.currentWord = word;
      this.showResult = true;
      this.addToHistory(word);
      this.checkWordBookStatus(word);
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 妫€鏌ュ崟璇嶆槸鍚﹀湪鐢熻瘝鏈腑
   */
  checkWordBookStatus(word: string): void {
    const wordBook = advancedNoteManager.getWordBook();
    let found = false;
    for (let i = 0; i < wordBook.length; i++) {
      if (wordBook[i].word.toLowerCase() === word.toLowerCase()) {
        found = true;
        break;
      }
    }
    this.isAddedToWordBook = found;
  }

  /**
   * 娣诲姞鍒版悳绱㈠巻鍙?
   */
  private async addToHistory(word: string): Promise<void> {
    if (!word.trim()) return;
    let exists = false;
    for (let i = 0; i < this.searchHistory.length; i++) {
      if (this.searchHistory[i] === word) {
        exists = true;
        break;
      }
    }
    if (exists) return;

    const newHistory: string[] = [word];
    const limit = this.searchHistory.length < 9 ? this.searchHistory.length : 9;
    for (let i = 0; i < limit; i++) {
      newHistory.push(this.searchHistory[i]);
    }
    this.searchHistory = newHistory;
    try {
      let historyStr = '';
      for (let i = 0; i < this.searchHistory.length; i++) {
        if (i > 0) {
          historyStr += ',';
        }
        historyStr += this.searchHistory[i];
      }
      await preferenceManager.setValue('dictionary_history', historyStr);
    } catch (error) {
      console.info('Save dictionary history failed');
    }
  }

  /**
   * 娓呯┖鎼滅储鍘嗗彶
   */
  clearHistory(): void {
    this.searchHistory = [];
    preferenceManager.setValue('dictionary_history', '');
  }
}

export const dictionaryViewModel = new DictionaryViewModel();
