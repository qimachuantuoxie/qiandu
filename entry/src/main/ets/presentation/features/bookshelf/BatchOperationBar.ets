// 批量操作栏
import { BookInfo } from '../../../models/CoreBookModel';
import { bookViewModel } from '../../../viewmodels/BookViewModel';

interface OperationButtonConfig {
  label: string;
  icon: string;
  color: string;
  action: () => void;
}

@Component
export struct BatchOperationBar {
  @Prop selectedBooks: Set<string> = new Set();
  @Prop bookList: BookInfo[] = [];
  @State isSelectAll: boolean = false;
  onCancel?: () => void;
  onComplete?: () => void;

  private readonly operationButtons: OperationButtonConfig[] = [
    { label: '删除', icon: 'trash', color: '#FF4D4F', action: () => this.deleteSelected() },
    { label: '收藏', icon: 'star', color: '#FFB300', action: () => this.addToFavorite() },
    { label: '分组', icon: 'folder', color: '#1890FF', action: () => this.showGroupSelector() },
    { label: '分享', icon: 'share', color: '#52C41A', action: () => this.shareSelected() }
  ];

  private getSelectedCount(): number {
    return this.selectedBooks.size;
  }

  private toggleSelectAll(): void {
    if (this.isSelectAll) {
      this.selectedBooks.clear();
    } else {
      for (let i = 0; i < this.bookList.length; i++) {
        const newSet = new Set(this.selectedBooks);
        newSet.add(this.bookList[i].id);
        this.selectedBooks = newSet;
      }
    }
    this.isSelectAll = !this.isSelectAll;
  }

  private deleteSelected(): void {
    const selectedIds: string[] = Array.from(this.selectedBooks);
    for (const id of selectedIds) {
      bookViewModel.deleteBook(id);
    }
    if (this.onComplete) {
      this.onComplete();
    }
  }

  private addToFavorite(): void {
    const selectedIds: string[] = Array.from(this.selectedBooks);
    for (const id of selectedIds) {
      bookViewModel.toggleFavorite(id);
    }
    if (this.onComplete) {
      this.onComplete();
    }
  }

  private addToGroup(groupId: string): void {
    const selectedIds: string[] = Array.from(this.selectedBooks);
    for (const bookId of selectedIds) {
      bookViewModel.addBookToGroup(bookId, groupId);
    }
    if (this.onComplete) {
      this.onComplete();
    }
  }

  build() {
    Column() {
      // 选择栏
      this.SelectionBar()

      // 操作按钮
      this.OperationButtons()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: -2 })
  }

  @Builder
  SelectionBar() {
    Row() {
      Button() {
        Text('取消')
          .fontSize(14)
          .fontColor('#666666')
      }
      .backgroundColor('rgba(255, 255, 255, 0.5)')
      .borderRadius(16)
      .height(32)
      .onClick(() => {
        if (this.onCancel) {
          this.onCancel();
        }
      })

      Text('已选 ' + this.getSelectedCount() + ' 本')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button() {
        Text(this.isSelectAll ? '取消全选' : '全选')
          .fontSize(14)
          .fontColor('#1890FF')
      }
      .backgroundColor('rgba(255, 255, 255, 0.5)')
      .borderRadius(16)
      .height(32)
      .onClick(() => this.toggleSelectAll())
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  OperationButtons() {
    Row({ space: 0 }) {
      ForEach(this.operationButtons, (config: OperationButtonConfig) => {
        this.OperationButton(config.label, config.icon, config.color, config.action)
      }, (config: OperationButtonConfig) => config.label)
    }
    .width('100%')
    .height(64)
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#F0F0F0' })
  }

  @Builder
  OperationButton(label: string, icon: string, color: string, onClick: () => void) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)

      Text(label)
        .fontSize(12)
        .fontColor('#666666')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      onClick();
    })
  }

  private showGroupSelector(): void {
    const groups = bookViewModel.getAllGroups();
    if (groups.length > 0) {
      this.addToGroup(groups[0].id);
    }
  }

  private shareSelected(): void {
    const selectedIds: string[] = Array.from(this.selectedBooks);
    console.info('分享书籍:', selectedIds);
  }
}

// 批量选择管理器
export class BatchSelectionManager {
  private selectedBooks: Set<string> = new Set();
  private isBatchMode: boolean = false;
  private listeners: Array<(selected: Set<string>, isBatchMode: boolean) => void> = [];

  enterBatchMode(): void {
    this.isBatchMode = true;
    this.notifyListeners();
  }

  exitBatchMode(): void {
    this.isBatchMode = false;
    this.selectedBooks.clear();
    this.notifyListeners();
  }

  toggleSelection(bookId: string): void {
    const newSet = new Set(this.selectedBooks);
    if (newSet.has(bookId)) {
      newSet.delete(bookId);
    } else {
      newSet.add(bookId);
    }
    this.selectedBooks = newSet;
    this.notifyListeners();
  }

  isSelected(bookId: string): boolean {
    return this.selectedBooks.has(bookId);
  }

  selectAll(books: BookInfo[]): void {
    const newSet = new Set<string>();
    for (let i = 0; i < books.length; i++) {
      newSet.add(books[i].id);
    }
    this.selectedBooks = newSet;
    this.notifyListeners();
  }

  clearSelection(): void {
    this.selectedBooks.clear();
    this.notifyListeners();
  }

  getSelectedIds(): string[] {
    return Array.from(this.selectedBooks);
  }

  getSelectedCount(): number {
    return this.selectedBooks.size;
  }

  isInBatchMode(): boolean {
    return this.isBatchMode;
  }

  subscribe(listener: (selected: Set<string>, isBatchMode: boolean) => void): () => void {
    const newListeners = this.listeners.slice();
    newListeners.push(listener);
    this.listeners = newListeners;
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        const updated = this.listeners.slice();
        updated.splice(index, 1);
        this.listeners = updated;
      }
    };
  }

  private notifyListeners(): void {
    for (const listener of this.listeners) {
      listener(new Set(this.selectedBooks), this.isBatchMode);
    }
  }
}

export const batchSelectionManager = new BatchSelectionManager();
