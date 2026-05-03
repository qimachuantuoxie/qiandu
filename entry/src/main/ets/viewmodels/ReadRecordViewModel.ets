/**
 * ReadRecordPage ViewModel - V2鐗堟湰
 */
import { BookInfo, ReadRecord } from '../models/CoreBookModel';
import { bookViewModel } from './BookViewModel';

@ObservedV2
export class ReadRecordViewModel {
  @Trace records: ReadRecord[] = [];
  @Trace filteredRecords: ReadRecord[] = [];
  @Trace searchText: string = '';
  @Trace isLoading: boolean = false;
  @Trace dateFilter: string = 'all';

  init(): void {
    this.loadRecords();
  }

  loadRecords(): void {
    const books = bookViewModel.getAllBooks();
    const newRecords: ReadRecord[] = [];
    for (let i = 0; i < books.length; i++) {
      const book = books[i];
      if (book.lastReadTime && book.lastReadTime > 0) {
        const record: ReadRecord = {
          id: 'record_' + book.id,
          bookId: book.id,
          bookTitle: book.title,
          readTime: book.lastReadTime,
          duration: book.totalReadTime > 0 ? book.totalReadTime : 0,
          progress: book.readProgress
        };
        newRecords.push(record);
      }
    }
    this.records = newRecords;
    this.applyFilter();
  }

  applyFilter(): void {
    let filtered: ReadRecord[] = [];
    for (let i = 0; i < this.records.length; i++) {
      filtered.push(this.records[i]);
    }

    if (this.dateFilter !== 'all') {
      const now = Date.now();
      const dayMs = 24 * 60 * 60 * 1000;
      const filterDays = parseInt(this.dateFilter);
      const filterTime = now - (filterDays * dayMs);
      const dateFiltered: ReadRecord[] = [];
      for (let i = 0; i < filtered.length; i++) {
        if (filtered[i].readTime > filterTime) {
          dateFiltered.push(filtered[i]);
        }
      }
      filtered = dateFiltered;
    }

    if (this.searchText.trim()) {
      const keyword = this.searchText.toLowerCase();
      const searchFiltered: ReadRecord[] = [];
      for (let i = 0; i < filtered.length; i++) {
        if (filtered[i].bookTitle && filtered[i].bookTitle.toLowerCase().includes(keyword)) {
          searchFiltered.push(filtered[i]);
        }
      }
      filtered = searchFiltered;
    }

    const sorted: ReadRecord[] = [];
    for (let i = 0; i < filtered.length; i++) {
      sorted.push(filtered[i]);
    }
    sorted.sort((a, b) => b.readTime - a.readTime);
    this.filteredRecords = sorted;
  }

  search(keyword: string): void {
    this.searchText = keyword;
    this.applyFilter();
  }

  setDateFilter(filter: string): void {
    this.dateFilter = filter;
    this.applyFilter();
  }

  deleteRecord(recordId: string): void {
    let index = -1;
    for (let i = 0; i < this.records.length; i++) {
      if (this.records[i].id === recordId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const newRecords: ReadRecord[] = [];
      for (let i = 0; i < this.records.length; i++) {
        if (i !== index) {
          newRecords.push(this.records[i]);
        }
      }
      this.records = newRecords;
      this.applyFilter();
    }
  }
}

export const readRecordViewModel = new ReadRecordViewModel();
