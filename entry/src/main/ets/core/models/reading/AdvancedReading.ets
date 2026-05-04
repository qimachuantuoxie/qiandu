import { logger } from '../../../utils/Logger';
// 绉婚櫎瀵筨ookViewModel鐨勫�鍏?- Model灞備笉搴斾緷璧朧iewModel灞?
// 绗旇�鐜板湪鐢盇dvancedNoteManager鐙�珛绠＄悊锛屼笉闇€瑕佸悓姝ュ埌ViewModel

export function generateBookId(): string {
  return 'book_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11);
}

export enum HighlightColor {
  YELLOW = '#FFEB3B',
  BLUE = '#2196F3',
  GREEN = '#4CAF50',
  RED = '#FF5722',
  PURPLE = '#9C27B0'
}

export enum NoteType {
  HIGHLIGHT = 'highlight',
  NOTE = 'note',
  THOUGHT = 'thought',
  BOOKMARK = 'bookmark'
}

export interface NoteItem {
  id: string;
  bookId: string;
  pageNumber: number;
  chapterTitle?: string;
  content: string;
  highlightText?: string;
  highlightColor?: string;
  type: NoteType;
  createTime: number;
  updateTime?: number;
  isPublic: boolean;
  likeCount?: number;
  commentCount?: number;
  tags?: string[];
}

export interface ReadingProgress {
  bookId: string;
  currentPage: number;
  totalPages: number;
  progress: number;
  lastReadTime: number;
  readingTimeToday: number;
  deviceInfo?: string;
}

export interface DictionaryResult {
  word: string;
  phonetic?: string;
  definitions: Definition[];
  examples: Example[];
  synonyms?: string[];
  antonyms?: string[];
}

export interface Definition {
  partOfSpeech: string;
  meaning: string;
}

export interface Example {
  sentence: string;
  translation?: string;
}

export interface ReadingStatistics {
  totalBooks: number;
  finishedBooks: number;
  readingDays: number;
  totalReadingTime: number;
  todayReadingTime: number;
  weekReadingTime: number;
  totalWords: number;
  totalNotes: number;
  totalBookmarks: number;
}

export interface AchievementBadge {
  id: string;
  name: string;
  description: string;
  icon: string;
  requirement: string;
  unlocked: boolean;
  unlockTime?: number;
}

class NoteCountResult {
  total: number = 0;
  highlights: number = 0;
  notes: number = 0;
  thoughts: number = 0;
}

class AdvancedNoteManager {
  private static instance: AdvancedNoteManager;
  private notes: Record<string, NoteItem[]> = {};
  private notesKeys: string[] = [];

  private constructor() {}

  static getInstance(): AdvancedNoteManager {
    if (!AdvancedNoteManager.instance) {
      AdvancedNoteManager.instance = new AdvancedNoteManager();
    }
    return AdvancedNoteManager.instance;
  }

  addHighlight(
    bookId: string,
    pageNumber: number,
    highlightText: string,
    color: HighlightColor = HighlightColor.YELLOW,
    chapterTitle?: string
  ): NoteItem {
    const note: NoteItem = {
      id: generateBookId(),
      bookId: bookId,
      pageNumber: pageNumber,
      chapterTitle: chapterTitle,
      content: '',
      highlightText: highlightText,
      highlightColor: color,
      type: NoteType.HIGHLIGHT,
      createTime: Date.now(),
      isPublic: false
    };

    this.saveNote(note);
    return note;
  }

  addNote(
    bookId: string,
    pageNumber: number,
    content: string,
    highlightText?: string,
    chapterTitle?: string
  ): NoteItem {
    const note: NoteItem = {
      id: generateBookId(),
      bookId: bookId,
      pageNumber: pageNumber,
      chapterTitle: chapterTitle,
      content: content,
      highlightText: highlightText,
      type: NoteType.NOTE,
      createTime: Date.now(),
      isPublic: false
    };

    this.saveNote(note);
    return note;
  }

  addThought(
    bookId: string,
    pageNumber: number,
    content: string,
    highlightText?: string
  ): NoteItem {
    const note: NoteItem = {
      id: generateBookId(),
      bookId: bookId,
      pageNumber: pageNumber,
      content: content,
      highlightText: highlightText,
      type: NoteType.THOUGHT,
      createTime: Date.now(),
      isPublic: true,
      likeCount: 0,
      commentCount: 0
    };

    this.saveNote(note);
    return note;
  }

  private saveNote(note: NoteItem): void {
    let bookNotes: NoteItem[] = this.notes[note.bookId];
    if (bookNotes === undefined) {
      bookNotes = [];
      this.notes[note.bookId] = bookNotes;
      this.notesKeys.push(note.bookId);
    }
    bookNotes.push(note);

    // 绉婚櫎瀵筨ookViewModel鐨勮皟鐢?- Model灞傚簲鐙�珛绠＄悊鏁版嵁
    // 濡傞渶閫氱煡澶栭儴锛屽彲浣跨敤鍥炶皟鎴栦簨浠舵満鍒?
    // bookViewModel.addNote(...) - 宸茬Щ闄?
  }

  getNotesByBook(bookId: string): NoteItem[] {
    const notes = this.notes[bookId];
    if (notes === undefined) {
      return [];
    }
    return notes;
  }

  filterNotesByType(notes: NoteItem[], type: NoteType): NoteItem[] {
    const result: NoteItem[] = [];
    for (let i = 0; i < notes.length; i++) {
      if (notes[i].type === type) {
        result.push(notes[i]);
      }
    }
    return result;
  }

  deleteNote(bookId: string, noteId: string): void {
    const bookNotes: NoteItem[] = this.notes[bookId];
    if (bookNotes === undefined) {
      return;
    }
    const newNotes: NoteItem[] = [];
    let found = false;
    for (let i = 0; i < bookNotes.length; i++) {
      if (bookNotes[i].id !== noteId) {
        newNotes.push(bookNotes[i]);
      } else {
        found = true;
      }
    }
    if (found) {
      this.notes[bookId] = newNotes;
    }
  }

  updateNote(noteId: string, updates: Partial<NoteItem>): void {
    for (let i = 0; i < this.notesKeys.length; i++) {
      const bookId: string = this.notesKeys[i];
      const bookNotes: NoteItem[] = this.notes[bookId];
      if (bookNotes === undefined) {
        continue;
      }
      let foundIndex = -1;
      for (let j = 0; j < bookNotes.length; j++) {
        if (bookNotes[j].id === noteId) {
          foundIndex = j;
          break;
        }
      }
      if (foundIndex > -1) {
        const existingNote: NoteItem = bookNotes[foundIndex];
        const updatedNote: NoteItem = {
          id: existingNote.id,
          bookId: existingNote.bookId,
          pageNumber: existingNote.pageNumber,
          chapterTitle: existingNote.chapterTitle,
          content: updates.content !== undefined ? updates.content : existingNote.content,
          highlightText: existingNote.highlightText,
          highlightColor: existingNote.highlightColor,
          type: existingNote.type,
          createTime: existingNote.createTime,
          updateTime: Date.now(),
          isPublic: existingNote.isPublic,
          likeCount: existingNote.likeCount,
          commentCount: existingNote.commentCount,
          tags: existingNote.tags
        };
        const newNotes: NoteItem[] = bookNotes.slice();
        newNotes[foundIndex] = updatedNote;
        this.notes[bookId] = newNotes;
        break;
      }
    }
  }

  exportToMarkdown(bookId: string, bookTitle: string, author: string): string {
    const notes: NoteItem[] = this.getNotesByBook(bookId);

    let markdown: string = '# ' + bookTitle + '\n\n';
    markdown += 'Author: ' + author + '\n\n';
    markdown += 'Export time: ' + new Date().toLocaleString() + '\n\n';
    markdown += '---\n\n';

    const sortedNotes = notes.slice();
    sortedNotes.sort((a: NoteItem, b: NoteItem) => a.pageNumber - b.pageNumber);

    const highlights: NoteItem[] = this.filterNotesByType(sortedNotes, NoteType.HIGHLIGHT);
    const normalNotes: NoteItem[] = this.filterNotesByType(sortedNotes, NoteType.NOTE);
    const thoughts: NoteItem[] = this.filterNotesByType(sortedNotes, NoteType.THOUGHT);

    if (highlights.length > 0) {
      markdown += '## Highlights\n\n';
      for (let i: number = 0; i < highlights.length; i++) {
        markdown += '> ' + highlights[i].highlightText + '\n\n';
      }
    }

    if (normalNotes.length > 0) {
      markdown += '## Notes\n\n';
      for (let i: number = 0; i < normalNotes.length; i++) {
        markdown += '**P' + normalNotes[i].pageNumber + '** ' + normalNotes[i].content + '\n\n';
      }
    }

    if (thoughts.length > 0) {
      markdown += '## Thoughts\n\n';
      for (let i: number = 0; i < thoughts.length; i++) {
        markdown += '**P' + thoughts[i].pageNumber + '** ' + thoughts[i].content + '\n\n';
      }
    }

    return markdown;
  }

  countNotes(bookId?: string): NoteCountResult {
    let allNotes: NoteItem[] = [];
    if (bookId !== undefined) {
      allNotes = this.getNotesByBook(bookId);
    } else {
      for (let i = 0; i < this.notesKeys.length; i++) {
        const bookNotes = this.notes[this.notesKeys[i]];
        if (bookNotes !== undefined) {
          for (let j = 0; j < bookNotes.length; j++) {
            allNotes.push(bookNotes[j]);
          }
        }
      }
    }

    const result: NoteCountResult = new NoteCountResult();
    result.total = allNotes.length;
    const highlights = this.filterNotesByType(allNotes, NoteType.HIGHLIGHT);
    const notes = this.filterNotesByType(allNotes, NoteType.NOTE);
    const thoughts = this.filterNotesByType(allNotes, NoteType.THOUGHT);
    result.highlights = highlights.length;
    result.notes = notes.length;
    result.thoughts = thoughts.length;
    return result;
  }

  private wordBook: WordBookItem[] = [];

  getWordBook(): WordBookItem[] {
    return this.wordBook;
  }

  addToWordBook(item: WordBookItem): void {
    let exists = false;
    for (let i = 0; i < this.wordBook.length; i++) {
      if (this.wordBook[i].word.toLowerCase() === item.word.toLowerCase()) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      const newItem: WordBookItem = {
        word: item.word,
        phonetic: item.phonetic,
        definitions: item.definitions,
        examples: item.examples,
        addTime: Date.now(),
        mastered: false
      };
      this.wordBook.push(newItem);
    }
  }

  removeFromWordBook(word: string): void {
    const newBook: WordBookItem[] = [];
    let found = false;
    for (let i = 0; i < this.wordBook.length; i++) {
      if (this.wordBook[i].word.toLowerCase() === word.toLowerCase()) {
        found = true;
      } else {
        newBook.push(this.wordBook[i]);
      }
    }
    if (found) {
      this.wordBook = newBook;
    }
  }

  markWordAsMastered(word: string): void {
    for (let i = 0; i < this.wordBook.length; i++) {
      if (this.wordBook[i].word.toLowerCase() === word.toLowerCase()) {
        this.wordBook[i].mastered = true;
        this.wordBook[i].masteredTime = Date.now();
        break;
      }
    }
  }
}

export interface WordBookItem {
  word: string;
  phonetic?: string;
  definitions?: Definition[];
  examples?: Example[];
  addTime?: number;
  mastered?: boolean;
  masteredTime?: number;
}

class DictionaryManager {
  private static instance: DictionaryManager;

  private constructor() {}

  static getInstance(): DictionaryManager {
    if (!DictionaryManager.instance) {
      DictionaryManager.instance = new DictionaryManager();
    }
    return DictionaryManager.instance;
  }

  async queryWord(word: string, language: 'zh' | 'en' = 'en'): Promise<DictionaryResult> {
    return {
      word: word,
      phonetic: '/ws:d/',
      definitions: [
        {
          partOfSpeech: 'n.',
          meaning: 'word; expression'
        },
        {
          partOfSpeech: 'v.',
          meaning: 'to express in words'
        }
      ],
      examples: [
        {
          sentence: 'He did not say a word.',
          translation: 'He said nothing.'
        },
        {
          sentence: 'May I have a word with you?',
          translation: 'Can I talk to you briefly?'
        }
      ],
      synonyms: ['term', 'expression'],
      antonyms: []
    };
  }

  addToVocabulary(word: string, definition: DictionaryResult): void {
    logger.info('Word added: ' + word);
  }
}

export const advancedNoteManager: AdvancedNoteManager = AdvancedNoteManager.getInstance();
export const dictionaryManager: DictionaryManager = DictionaryManager.getInstance();
