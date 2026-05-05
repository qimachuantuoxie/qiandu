import { logger } from '../../utils/Logger';
/**
 * 涔︾睄鐘舵€佺�鐞?- 鍩轰簬 @hadss/state_store
 * 
 * 浣跨敤 StateStore 绠＄悊鍏ㄥ眬涔︾睄鐘舵€侊紝瀹炵幇鐘舵€佷笌UI瑙ｈ€? * 鏇夸唬鍘熸湁鐨?BookViewModel锛?268琛岋級
 */

import { BookInfo, BookFormat, ReadStatus, Bookmark, Note, ReadRecord, BookshelfGroup, generateBookId, BooksMap, BookmarksMap, NotesMap, GroupsMap } from '../models/CoreBookModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { StateStore, Store, Reducer, Action } from '@hadss/state_store';

// Re-export types
export {
  BookInfo,
  BookFormat,
  ReadStatus,
  Bookmark,
  Note,
  ReadRecord,
  BookshelfGroup,
  generateBookId,
  BooksMap,
  BookmarksMap,
  NotesMap,
  GroupsMap
} from '../models/CoreBookModel';

export type SortOrderType = 'TITLE_ASC' | 'TITLE_DESC' | 'AUTHOR_ASC' | 'AUTHOR_DESC' | 'ADD_TIME_DESC' | 'ADD_TIME_ASC' | 'LAST_READ_DESC' | 'LAST_READ_ASC' | 'PROGRESS_DESC' | 'PROGRESS_ASC';

export interface SortOrderMap {
  TITLE_ASC: string;
  TITLE_DESC: string;
  AUTHOR_ASC: string;
  AUTHOR_DESC: string;
  ADD_TIME_DESC: string;
  ADD_TIME_ASC: string;
  LAST_READ_DESC: string;
  LAST_READ_ASC: string;
  PROGRESS_DESC: string;
  PROGRESS_ASC: string;
}

export const SortOrderValues: SortOrderMap = {
  TITLE_ASC: 'title_asc',
  TITLE_DESC: 'title_desc',
  AUTHOR_ASC: 'author_asc',
  AUTHOR_DESC: 'author_desc',
  ADD_TIME_DESC: 'add_time_desc',
  ADD_TIME_ASC: 'add_time_asc',
  LAST_READ_DESC: 'last_read_desc',
  LAST_READ_ASC: 'last_read_asc',
  PROGRESS_DESC: 'progress_desc',
  PROGRESS_ASC: 'progress_asc'
};

export interface PaginatedBooksResult {
  books: BookInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
  totalPages?: number;
}

export interface AdvancedSearchOptions {
  searchTitle?: boolean;
  searchAuthor?: boolean;
  searchTags?: boolean;
  searchDescription?: boolean;
}

// ==================== State 定义 ====================

@ObservedV2
export class BookState {
  @Trace books: BooksMap = new Map();
  @Trace bookKeys: string[] = [];
  
  @Trace bookmarks: BookmarksMap = new Map();
  @Trace bookmarkKeys: string[] = [];
  
  @Trace notes: NotesMap = new Map();
  @Trace noteKeys: string[] = [];
  
  @Trace groups: GroupsMap = new Map();
  @Trace groupKeys: string[] = [];
  
  @Trace readRecords: ReadRecord[] = [];
}

// ==================== Actions 定义 ====================

export const LOAD_BOOKS = StateStore.createAction("LOAD_BOOKS");
export const ADD_BOOK = StateStore.createAction("ADD_BOOK");
export const DELETE_BOOK = StateStore.createAction("DELETE_BOOK");
export const UPDATE_BOOK = StateStore.createAction("UPDATE_BOOK");
export const UPDATE_READING_PROGRESS = StateStore.createAction("UPDATE_READING_PROGRESS");
export const TOGGLE_FAVORITE = StateStore.createAction("TOGGLE_FAVORITE");

export const ADD_BOOKMARK = StateStore.createAction("ADD_BOOKMARK");
export const DELETE_BOOKMARK = StateStore.createAction("DELETE_BOOKMARK");

export const ADD_NOTE = StateStore.createAction("ADD_NOTE");
export const DELETE_NOTE = StateStore.createAction("DELETE_NOTE");

export const ADD_GROUP = StateStore.createAction("ADD_GROUP");
export const DELETE_GROUP = StateStore.createAction("DELETE_GROUP");
export const UPDATE_GROUP = StateStore.createAction("UPDATE_GROUP");
export const ADD_BOOK_TO_GROUP = StateStore.createAction("ADD_BOOK_TO_GROUP");
export const REMOVE_BOOK_FROM_GROUP = StateStore.createAction("REMOVE_BOOK_FROM_GROUP");

export const ADD_READ_RECORD = StateStore.createAction("ADD_READ_RECORD");
export const DELETE_READ_RECORD = StateStore.createAction("DELETE_READ_RECORD");

// ==================== Reducer 定义 ====================

const bookReducer: Reducer<BookState> = (state: BookState, action: Action) => {
  switch (action.type) {
    case LOAD_BOOKS.type: {
      const { books, bookKeys, bookmarks, bookmarkKeys, notes, noteKeys, groups, groupKeys, readRecords } = action.payload;
      state.books = books;
      state.bookKeys = bookKeys;
      state.bookmarks = bookmarks;
      state.bookmarkKeys = bookmarkKeys;
      state.notes = notes;
      state.noteKeys = noteKeys;
      state.groups = groups;
      state.groupKeys = groupKeys;
      state.readRecords = readRecords;
      break;
    }
    
    case ADD_BOOK.type: {
      const book: BookInfo = action.payload;
      if (!book.id) {
        book.id = generateBookId();
      }
      state.books.set(book.id, book);
      
      let exists = false;
      for (let i = 0; i < state.bookKeys.length; i++) {
        if (state.bookKeys[i] === book.id) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newKeys: string[] = [];
        for (let i = 0; i < state.bookKeys.length; i++) {
          newKeys.push(state.bookKeys[i]);
        }
        newKeys.push(book.id);
        state.bookKeys = newKeys;
      }
      
      // 鎸佷箙鍖?      saveBooksToPrefs(state);
      break;
    }
    
    case DELETE_BOOK.type: {
      const bookId: string = action.payload;
      let bookIndex = -1;
      for (let i = 0; i < state.bookKeys.length; i++) {
        if (state.bookKeys[i] === bookId) {
          bookIndex = i;
          break;
        }
      }
      if (bookIndex > -1) {
        const newKeys: string[] = [];
        for (let i = 0; i < state.bookKeys.length; i++) {
          if (i !== bookIndex) {
            newKeys.push(state.bookKeys[i]);
          }
        }
        state.bookKeys = newKeys;
      }
      
      // 娓呯悊涔︾�
      let bmIndex = -1;
      for (let i = 0; i < state.bookmarkKeys.length; i++) {
        if (state.bookmarkKeys[i] === bookId) {
          bmIndex = i;
          break;
        }
      }
      if (bmIndex > -1) {
        const newBmKeys: string[] = [];
        for (let i = 0; i < state.bookmarkKeys.length; i++) {
          if (i !== bmIndex) {
            newBmKeys.push(state.bookmarkKeys[i]);
          }
        }
        state.bookmarkKeys = newBmKeys;
        state.bookmarks.set(bookId, []);
        saveBookmarksToPrefs(state);
      }
      
      // 娓呯悊绗旇�
      let noteIndex = -1;
      for (let i = 0; i < state.noteKeys.length; i++) {
        if (state.noteKeys[i] === bookId) {
          noteIndex = i;
          break;
        }
      }
      if (noteIndex > -1) {
        const newNoteKeys: string[] = [];
        for (let i = 0; i < state.noteKeys.length; i++) {
          if (i !== noteIndex) {
            newNoteKeys.push(state.noteKeys[i]);
          }
        }
        state.noteKeys = newNoteKeys;
        state.notes.set(bookId, []);
        saveNotesToPrefs(state);
      }
      
      // 娓呯悊闃呰�璁板綍
      const remainingRecords: ReadRecord[] = [];
      for (let i = 0; i < state.readRecords.length; i++) {
        if (state.readRecords[i].bookId !== bookId) {
          remainingRecords.push(state.readRecords[i]);
        }
      }
      state.readRecords = remainingRecords;
      saveReadRecordsToPrefs(state);
      
      saveBooksToPrefs(state);
      break;
    }
    
    case UPDATE_BOOK.type: {
      const book: BookInfo = action.payload;
      state.books.set(book.id, book);
      
      let exists = false;
      for (let i = 0; i < state.bookKeys.length; i++) {
        if (state.bookKeys[i] === book.id) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        const newKeys: string[] = [];
        for (let i = 0; i < state.bookKeys.length; i++) {
          newKeys.push(state.bookKeys[i]);
        }
        newKeys.push(book.id);
        state.bookKeys = newKeys;
      }
      
      saveBooksToPrefs(state);
      break;
    }
    
    case UPDATE_READING_PROGRESS.type: {
      const { bookId, currentPage, duration } = action.payload;
      const book = state.books.get(bookId);
      if (book) {
        book.currentPage = currentPage;
        if (book.totalPages > 0) {
          book.readProgress = Math.round((currentPage / book.totalPages) * 100);
        } else {
          book.readProgress = 0;
        }
        book.lastReadTime = Date.now();
        book.status = ReadStatus.READING;
        book.totalReadTime = (book.totalReadTime || 0) + duration;
        saveBooksToPrefs(state);
      }
      break;
    }
    
    case TOGGLE_FAVORITE.type: {
      const bookId: string = action.payload;
      const book = state.books.get(bookId);
      if (book) {
        book.isFavorite = !book.isFavorite;
        saveBooksToPrefs(state);
      }
      break;
    }
    
    case ADD_BOOKMARK.type: {
      const { bookId, bookmark } = action.payload;
      let bookBookmarks = state.bookmarks.get(bookId);
      if (!bookBookmarks) {
        bookBookmarks = [];
        state.bookmarks.set(bookId, bookBookmarks);
        let exists = false;
        for (let i = 0; i < state.bookmarkKeys.length; i++) {
          if (state.bookmarkKeys[i] === bookId) {
            exists = true;
            break;
          }
        }
        if (!exists) {
          const newKeys: string[] = [];
          for (let i = 0; i < state.bookmarkKeys.length; i++) {
            newKeys.push(state.bookmarkKeys[i]);
          }
          newKeys.push(bookId);
          state.bookmarkKeys = newKeys;
        }
      }
      const newBms: Bookmark[] = [];
      for (let i = 0; i < bookBookmarks.length; i++) {
        newBms.push(bookBookmarks[i]);
      }
      newBms.push(bookmark);
      state.bookmarks.set(bookId, newBms);
      saveBookmarksToPrefs(state);
      break;
    }
    
    case DELETE_BOOKMARK.type: {
      const { bookId, bookmarkId } = action.payload;
      const bookBookmarks = state.bookmarks.get(bookId);
      if (bookBookmarks) {
        let index = -1;
        for (let i = 0; i < bookBookmarks.length; i++) {
          if (bookBookmarks[i].id === bookmarkId) {
            index = i;
            break;
          }
        }
        if (index > -1) {
          const newBms: Bookmark[] = [];
          for (let i = 0; i < bookBookmarks.length; i++) {
            if (i !== index) {
              newBms.push(bookBookmarks[i]);
            }
          }
          state.bookmarks.set(bookId, newBms);
          saveBookmarksToPrefs(state);
        }
      }
      break;
    }
    
    default:
      break;
  }
  return null;
};

// ==================== 鎸佷箙鍖栬緟鍔╁嚱鏁?====================

function saveBooksToPrefs(state: BookState): void {
  try {
    const booksArray: BookInfo[] = [];
    for (let i = 0; i < state.bookKeys.length; i++) {
      const key = state.bookKeys[i];
      const book = state.books.get(key);
      if (book) {
        booksArray.push(book);
      }
    }
    preferenceManager.setBooks(booksArray);
  } catch (error) {
    logger.error('淇濆瓨涔︾睄澶辫触:', error);
  }
}

function saveBookmarksToPrefs(state: BookState): void {
  try {
    const bookmarksObj: Record<string, Bookmark[]> = {};
    for (let i = 0; i < state.bookmarkKeys.length; i++) {
      const key = state.bookmarkKeys[i];
      const val = state.bookmarks.get(key);
      if (val) {
        bookmarksObj[key] = val;
      }
    }
    preferenceManager.setBookmarks(bookmarksObj);
  } catch (error) {
    logger.error('淇濆瓨涔︾�澶辫触:', error);
  }
}

function saveNotesToPrefs(state: BookState): void {
  try {
    const notesObj: Record<string, Note[]> = {};
    for (let i = 0; i < state.noteKeys.length; i++) {
      const key = state.noteKeys[i];
      const val = state.notes.get(key);
      if (val) {
        notesObj[key] = val;
      }
    }
    preferenceManager.setNotes(notesObj);
  } catch (error) {
    logger.error('淇濆瓨绗旇�澶辫触:', error);
  }
}

function saveReadRecordsToPrefs(state: BookState): void {
  try {
    preferenceManager.setReadRecords(state.readRecords);
  } catch (error) {
    logger.error('淇濆瓨闃呰�璁板綍澶辫触:', error);
  }
}

function saveGroupsToPrefs(state: BookState): void {
  try {
    const groupsArray: BookshelfGroup[] = [];
    for (let i = 0; i < state.groupKeys.length; i++) {
      const key = state.groupKeys[i];
      const group = state.groups.get(key);
      if (group) {
        groupsArray.push(group);
      }
    }
    preferenceManager.setBookshelfGroups(groupsArray);
  } catch (error) {
    logger.error('淇濆瓨鍒嗙粍澶辫触:', error);
  }
}

// ==================== Store 鍒涘缓 ====================

const initialState = new BookState();

export const bookStore: Store<BookState> = StateStore.createStore<BookState>(
  'bookStore',
  initialState,
  bookReducer
);

// ==================== 鍒濆�鍖栧姞杞?====================

export function initializeBookStore(): void {
  try {
    // 鍔犺浇涔︾睄
    const savedBooks = preferenceManager.getBooks();
    const books: BooksMap = new Map();
    const bookKeys: string[] = [];
    for (let i = 0; i < savedBooks.length; i++) {
      const book = savedBooks[i];
      books.set(book.id, book);
      bookKeys.push(book.id);
    }
    
    // 鍔犺浇涔︾�
    const savedBookmarks = preferenceManager.getAllBookmarks();
    const bookmarks: BookmarksMap = new Map();
    const bookmarkKeys = Object.keys(savedBookmarks);
    for (let i = 0; i < bookmarkKeys.length; i++) {
      const key = bookmarkKeys[i];
      bookmarks.set(key, savedBookmarks[key]);
    }
    
    // 鍔犺浇绗旇�
    const savedNotes = preferenceManager.getNotes();
    const notes: NotesMap = new Map();
    const noteKeys = Object.keys(savedNotes);
    for (let i = 0; i < noteKeys.length; i++) {
      const key = noteKeys[i];
      notes.set(key, savedNotes[key]);
    }
    
    // 鍔犺浇鍒嗙粍
    const savedGroups = preferenceManager.getBookshelfGroups();
    const groups: GroupsMap = new Map();
    const groupKeys: string[] = [];
    for (let i = 0; i < savedGroups.length; i++) {
      const g = savedGroups[i];
      groups.set(g.id, g);
      groupKeys.push(g.id);
    }
    
    // 鍔犺浇闃呰�璁板綍
    const readRecords = preferenceManager.getReadRecords();
    
    bookStore.dispatch(LOAD_BOOKS, {
      books,
      bookKeys,
      bookmarks,
      bookmarkKeys,
      notes,
      noteKeys,
      groups,
      groupKeys,
      readRecords
    });
  } catch (error) {
    logger.error('鍒濆�鍖?BookStore 澶辫触:', error);
  }
}

// ==================== 宸ュ叿鍑芥暟 ====================

export function getAllBooksFromStore(): BookInfo[] {
  const state = bookStore.getState();
  const result: BookInfo[] = [];
  for (let i = 0; i < state.bookKeys.length; i++) {
    const key = state.bookKeys[i];
    const book = state.books.get(key);
    if (book) {
      result.push(book);
    }
  }
  return result;
}

export function getBookByIdFromStore(bookId: string): BookInfo | undefined {
  const state = bookStore.getState();
  return state.books.get(bookId);
}

export function searchBooksInStore(keyword: string): BookInfo[] {
  const state = bookStore.getState();
  const lowerKeyword = keyword.toLowerCase();
  const allBooks = getAllBooksFromStore();
  const result: BookInfo[] = [];
  for (let i = 0; i < allBooks.length; i++) {
    const book = allBooks[i];
    if (book.title.toLowerCase().includes(lowerKeyword) ||
        book.author.toLowerCase().includes(lowerKeyword)) {
      result.push(book);
    }
  }
  return result;
}
