// Todo 寰呭姙浜嬮」椤甸潰
import { router } from '@kit.ArkUI';
import { todoViewModel, TodoViewModel } from '../viewmodels/TodoViewModel';
import {
  TodoItem,
  TodoStatus,
  TodoPriority,
  TodoFilterType,
  TodoSortType,
  TodoStats,
  generateTodoId,
  getPriorityLabel,
  getPriorityColor,
  getPriorityIcon,
  getStatusLabel,
  formatDueDate,
  isTodoOverdue
} from '../models/TodoModel';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';
import { LazyDataSource } from '../common/datasource/LazyDataSource';

interface SortOption {
  label: string;
  value: TodoSortType;
}

const SORT_OPTIONS: SortOption[] = [
  { label: '按优先级', value: TodoSortType.PRIORITY },
  { label: '按截止日期', value: TodoSortType.DUE_DATE },
  { label: '按创建时间', value: TodoSortType.CREATED_TIME },
  { label: '按标题', value: TodoSortType.TITLE }
];

@Entry
@Component
struct TodoPage {
  // V2 ViewModel 鐩存帴浣跨敤
  viewModel: TodoViewModel = todoViewModel;

  // UI鎺у埗鐘舵€?
  @State currentFilter: TodoFilterType = TodoFilterType.ALL;
  @State currentSort: TodoSortType = TodoSortType.PRIORITY;
  @State searchText: string = '';
  @State showAddDialog: boolean = false;
  @State newTodoTitle: string = '';
  @State newTodoDescription: string = '';
  @State newTodoPriority: TodoPriority = TodoPriority.MEDIUM;
  @State newTodoDueDate: string = '';
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showSortPanel: boolean = false;
  @State editingTodo: TodoItem | null = null;
  @State showEditDialog: boolean = false;
  @State editTitle: string = '';
  @State editDescription: string = '';
  @State editPriority: TodoPriority = TodoPriority.MEDIUM;
  @State editDueDate: string = '';

  // LazyForEach 鏁版嵁婧?
  private todoDataSource: LazyDataSource<TodoItem> = new LazyDataSource<TodoItem>((item: TodoItem) => item.id);

  aboutToAppear() {
    this.initData();
  }

  private async initData(): Promise<void> {
    try {
      this.currentColors = themeManager.getColors();
      this.fontScale = await fontScaleManager.getFontScale();
      await this.viewModel.init();
      this.updateDataSource();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('Todo页面初始化失败:', message);
    }
  }

  // 鏇存柊 LazyForEach 鏁版嵁婧?
  private updateDataSource(): void {
    let todos: TodoItem[];
    if (this.searchText.length > 0) {
      todos = this.viewModel.searchTodos(this.searchText);
    } else {
      todos = this.viewModel.getFilteredAndSortedTodos(this.currentFilter, this.currentSort);
    }
    this.todoDataSource.setData(todos);
  }

  // 鑾峰彇杩囨护鍚庣殑Todo鍒楄〃 (浠呯敤浜庡悜鍚庡吋瀹?
  get filteredTodos(): TodoItem[] {
    if (this.searchText.length > 0) {
      return this.viewModel.searchTodos(this.searchText);
    } else {
      return this.viewModel.getFilteredAndSortedTodos(this.currentFilter, this.currentSort);
    }
  }

  // 绛涢€夋潯浠跺彉鍖栨椂璋冪敤
  onFilterChange(): void {
    this.updateDataSource();
  }

  // 鎼滅储妗嗚緭鍏ユ椂璋冪敤 (甯﹂槻鎶?
  onSearchChange(): void {
    this.updateDataSource();
  }

  // 鑾峰彇缁熻鏁版嵁
  get stats(): TodoStats {
    return this.viewModel.getStats();
  }

  // 棰滆壊杈呭姪鍑芥暟
  private textColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bgColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  // 鑾峰彇涓婚棰滆壊
  private getColors(): AppColors {
    return this.currentColors;
  }

  private async toggleTodoStatus(todo: TodoItem): Promise<void> {
    if (todo.status === TodoStatus.COMPLETED) {
      await todoViewModel.restoreTodo(todo.id);
    } else {
      await todoViewModel.completeTodo(todo.id);
    }
    this.updateDataSource();
  }

  private async deleteTodo(todo: TodoItem): Promise<void> {
    await todoViewModel.deleteTodo(todo.id);
    this.updateDataSource();
  }

  private openAddDialog(): void {
    this.newTodoTitle = '';
    this.newTodoDescription = '';
    this.newTodoPriority = TodoPriority.MEDIUM;
    this.newTodoDueDate = '';
    this.showAddDialog = true;
  }

  private async addTodo(): Promise<void> {
    if (this.newTodoTitle.trim().length === 0) {
      return;
    }

    let dueDate = 0;
    if (this.newTodoDueDate.length > 0) {
      const date = new Date(this.newTodoDueDate);
      dueDate = date.getTime();
    }

    const newTodo: TodoItem = {
      id: generateTodoId(),
      title: this.newTodoTitle.trim(),
      description: this.newTodoDescription.trim(),
      priority: this.newTodoPriority,
      status: TodoStatus.PENDING,
      dueDate: dueDate,
      createdTime: Date.now(),
      completedTime: 0,
      relatedBookId: '',
      relatedBookTitle: '',
      tags: [],
      reminder: false
    };

    await todoViewModel.addTodo(newTodo);
    this.showAddDialog = false;
  }

  /**
   * 搴旂敤杩囨护鍜屾帓搴?
   */
  private applyFilterAndSort(): void {
    // 鐢?ViewModel 澶勭悊杩囨护鍜屾帓搴?
    this.viewModel.applyFilterAndSort(this.searchText, this.currentFilter, this.currentSort);
    this.updateDataSource();
  }

  build() {
    Stack() {
      Column() {
        // 椤堕儴瀵艰埅鏍?
        this.Header()

        // 缁熻鍗＄墖
        this.StatsCards()

        // 鎼滅储鏍?
        this.SearchBar()

        // 杩囨护鍜屾帓搴忔爣绛?
        this.FilterAndSortTabs()

        // Todo鍒楄〃
        if (this.filteredTodos.length === 0) {
          this.EmptyView()
        } else {
          this.TodoList()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgColor('#F5F5F7', '#141414'))

      // 娣诲姞Todo瀵硅瘽妗?
      if (this.showAddDialog) {
        this.AddTodoDialog()
      }

      // 缂栬緫Todo瀵硅瘽妗?
      this.EditTodoDialog()

      // 娴姩娣诲姞鎸夐挳
      Button('+')
        .width(56)
        .height(56)
        .fontSize(32)
        .fontColor('#FFFFFF')
        .backgroundColor('#007DFF')
        .borderRadius(28)
        .shadow({ radius: 8, color: 'rgba(0,125,255,0.3)', offsetY: 4 })
        .position({ x: '100% - 76px', y: '100% - 140px' })
        .onClick(() => this.openAddDialog())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(this.textColor('#666666', '#AAAAAA'))
        .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })

      Text('待办事项')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('⚙')
        .fontSize(24)
        .fontColor(this.textColor('#666666', '#AAAAAA'))
        .padding(8)
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.bgColor('#FFFFFF', '#1C1C1E'))
  }

  @Builder
  StatsCards() {
    Scroll() {
      Row({ space: 12 }) {
        this.StatCard('全部', this.stats.total.toString(), '#007DFF')
        this.StatCard('未完成', this.stats.pending.toString(), '#FA8C16')
        this.StatCard('进行中', this.stats.inProgress.toString(), '#1890FF')
        this.StatCard('已完成', this.stats.completed.toString(), '#52C41A')
        this.StatCard('已过期', this.stats.overdue.toString(), '#FF4D4F')
        this.StatCard('今天到期', this.stats.todayDue.toString(), '#FFA940')
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  StatCard(label: string, count: string, color: string) {
    Column({ space: 4 }) {
      Text(count)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(11)
        .fontColor(this.textColor('#666666', '#888888'))
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .width(80)
  }

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: '搜索待办事项...' })
        .width('100%')
        .height(40)
        .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
        .borderRadius(20)
        .padding({ left: 18, right: 18 })
        .fontSize(14)
        .onChange((value: string) => {
          this.searchText = value;
          this.applyFilterAndSort();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  FilterAndSortTabs() {
    Row({ space: 8 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(['全部', '未完成', '进行中', '已完成', '今天到期', '已过期'],
            (item: string, index: number) => {
              Text(item)
                .fontSize(13)
                .fontColor(this.currentFilter === index ? '#FFFFFF' : this.textColor('#666666', '#AAAAAA'))
                .fontWeight(this.currentFilter === index ? FontWeight.Medium : FontWeight.Normal)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .backgroundColor(this.currentFilter === index ? '#007DFF' : 'transparent')
                .borderRadius(18)
                .onClick(() => {
                  this.currentFilter = index;
                  this.applyFilterAndSort();
                })
            })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      Text('⇅')
        .fontSize(18)
        .fontColor(this.textColor('#666666', '#AAAAAA'))
        .padding(8)
        .onClick(() => {
          this.showSortPanel = !this.showSortPanel;
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })

    // 鎺掑簭闈㈡澘
    if (this.showSortPanel) {
      this.SortPanel()
    }
  }

  @Builder
  SortPanel() {
    Column() {
      Column({ space: 0 }) {
        ForEach(SORT_OPTIONS, (item: SortOption) => {
          Row() {
            Text(item.label)
              .fontSize(14)
              .fontColor(this.currentSort === item.value
                ? '#007DFF'
                : this.textColor('#333333', '#CCCCCC'))
              .fontWeight(this.currentSort === item.value ? FontWeight.Medium : FontWeight.Normal)
              .layoutWeight(1)

            if (this.currentSort === item.value) {
              Text('✓')
                .fontSize(16)
                .fontColor('#007DFF')
            }
          }
          .width('100%')
          .padding({ top: 14, bottom: 14, left: 16, right: 16 })
          .backgroundColor(this.currentSort === item.value
            ? this.bgColor('rgba(0,125,255,0.05)', 'rgba(0,125,255,0.1)')
            : 'transparent')
          .onClick(() => {
            this.currentSort = item.value;
            this.showSortPanel = false;
            this.applyFilterAndSort();
          })
        })
      }
      .width('100%')
      .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
      .borderRadius(12)
    }
    .width('90%')
    .padding(16)
    .backgroundColor(this.bgColor('#FFFFFF', '#1C1C1E'))
    .borderRadius(16)
    .shadow({
      radius: 16,
      color: 'rgba(0,0,0,0.15)',
      offsetX: 0,
      offsetY: 4
    })
    .position({ x: '5%', y: 280 })
  }

  @Builder
  TodoList() {
    Scroll() {
      Column({ space: 12 }) {
        LazyForEach(this.todoDataSource, (todo: TodoItem) => {
          this.TodoItem(todo)
        }, (todo: TodoItem) => todo.id)
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 100 })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  TodoItem(todo: TodoItem) {
    Row({ space: 12 }) {
      // 瀹屾垚澶嶉€夋
      Button(todo.status === TodoStatus.COMPLETED ? '✓' : '○')
        .width(28)
        .height(28)
        .fontSize(20)
        .fontColor(todo.status === TodoStatus.COMPLETED ? '#52C41A' : this.textColor('#666666', '#CCCCCC'))
        .backgroundColor('transparent')
        .border({
          width: 2,
          color: todo.status === TodoStatus.COMPLETED ? '#52C41A' : this.textColor('#666666', '#CCCCCC')
        })
        .borderRadius(14)
        .onClick(() => this.toggleTodoStatus(todo))

      // 鍐呭鍖?
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(getPriorityIcon(todo.priority))
            .fontSize(14)

          Text(todo.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(todo.status === TodoStatus.COMPLETED ?
              this.textColor('#666666', '#999999') :
              this.textColor('#1A1A1A', '#FFFFFF'))
            .decoration({
              type: todo.status === TodoStatus.COMPLETED ? TextDecorationType.LineThrough : TextDecorationType.None
            })
            .layoutWeight(1)

          // 缂栬緫鎸夐挳
          if (todo.status !== TodoStatus.COMPLETED) {
            Text('✎')
              .fontSize(16)
              .fontColor('#007DFF')
              .padding(4)
              .onClick(() => this.editTodo(todo))
          }
        }

        if (todo.description.length > 0) {
          Text(todo.description)
            .fontSize(13)
            .fontColor(this.textColor('#666666', '#999999'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Row({ space: 12 }) {
          Text(getPriorityLabel(todo.priority))
            .fontSize(11)
            .fontColor(getPriorityColor(todo.priority, this.isDarkMode))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(getPriorityColor(todo.priority, this.isDarkMode) + '20')
            .borderRadius(8)

          if (todo.dueDate > 0) {
            Text(formatDueDate(todo.dueDate))
              .fontSize(11)
              .fontColor(isTodoOverdue(todo) ? '#FF4D4F' : this.textColor('#888888', '#999999'))
          }

          Text(getStatusLabel(todo.status))
            .fontSize(11)
            .fontColor(this.textColor('#888888', '#999999'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 鍒犻櫎鎸夐挳
      Text('馃棏')
        .fontSize(18)
        .padding(8)
        .onClick(() => this.deleteTodo(todo))
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .opacity(todo.status === TodoStatus.COMPLETED ? 0.6 : 1.0)
    .stateStyles({
      pressed: {
        .backgroundColor(this.bgColor('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
        .scale({ x: 0.98, y: 0.98 })
      },
      normal: {
        .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
        .scale({ x: 1, y: 1 })
      }
    })
  }

  private editTodo(todo: TodoItem): void {
    this.editingTodo = todo;
    this.editTitle = todo.title;
    this.editDescription = todo.description;
    this.editPriority = todo.priority;
    this.editDueDate = todo.dueDate > 0 ? new Date(todo.dueDate).toISOString().split('T')[0] : '';
    this.showEditDialog = true;
  }

  private async saveEditTodo(): Promise<void> {
    if (this.editTitle.trim().length === 0 || !this.editingTodo) {
      return;
    }

    let dueDate = 0;
    if (this.editDueDate.length > 0) {
      const date = new Date(this.editDueDate);
      dueDate = date.getTime();
    }

    await todoViewModel.updateTodo(this.editingTodo.id, {
      title: this.editTitle.trim(),
      description: this.editDescription.trim(),
      priority: this.editPriority,
      dueDate: dueDate
    });

    this.showEditDialog = false;
    this.editingTodo = null;
  }

  @Builder
  EmptyView() {
    Column({ space: 20 }) {
      Column() {
        Text('📋')
          .fontSize(64)
      }
      .width(120)
      .height(120)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.06)'))
      .borderRadius(60)

      Column({ space: 8 }) {
        Text('暂无待办事项')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor('#666666', '#AAAAAA'))

        Text('点击下方 + 按钮添加')
          .fontSize(13)
          .fontColor(this.textColor('#999999', '#666666'))
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  AddTodoDialog() {
    Column() {
      // 閬僵灞?
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => this.showAddDialog = false)

      // 瀵硅瘽妗嗗唴瀹?
      Column({ space: 16 }) {
        Text('娣诲姞寰呭姙浜嬮」')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 10 })

        // 鏍囬杈撳叆
        TextInput({ placeholder: '鏍囬' })
          .width('100%')
          .height(44)
          .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .onChange((value: string) => {
            this.newTodoTitle = value;
          })

        // 鎻忚堪杈撳叆
        TextArea({ placeholder: '鎻忚堪锛堝彲閫夛級' })
          .width('100%')
          .height(80)
          .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .fontSize(13)
          .onChange((value: string) => {
            this.newTodoDescription = value;
          })

        // 浼樺厛绾ч€夋嫨
        Row({ space: 12 }) {
          Text('浼樺厛绾?')
            .fontSize(14)
            .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))

          ForEach([TodoPriority.LOW, TodoPriority.MEDIUM, TodoPriority.HIGH, TodoPriority.URGENT],
            (priority: TodoPriority) => {
              Text(getPriorityLabel(priority))
                .fontSize(13)
                .fontColor(this.newTodoPriority === priority ? '#FFFFFF' : getPriorityColor(priority, this.isDarkMode))
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.newTodoPriority === priority ? getPriorityColor(priority, this.isDarkMode) : 'transparent')
                .border({
                  width: 1,
                  color: getPriorityColor(priority, this.isDarkMode)
                })
                .borderRadius(12)
                .onClick(() => {
                  this.newTodoPriority = priority;
                })
            })
        }
        .width('100%')

        // 鎴鏃ユ湡
        TextInput({ placeholder: '鎴鏃ユ湡 (YYYY-MM-DD, 鍙€?' })
          .width('100%')
          .height(44)
          .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .onChange((value: string) => {
            this.newTodoDueDate = value;
          })

        // 鎸夐挳
        Row({ space: 12 }) {
          Button('鍙栨秷')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))
            .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.1)'))
            .borderRadius(22)
            .onClick(() => this.showAddDialog = false)

          Button('娣诲姞')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#007DFF')
            .borderRadius(22)
            .onClick(() => this.addTodo())
        }
        .width('100%')
        .padding({ top: 10, bottom: 20 })
      }
      .width('100%')
      .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
      .borderRadius({ topLeft: 20, topRight: 20 })
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  EditTodoDialog() {
    if (this.showEditDialog && this.editingTodo) {
      Column() {
        // 閬僵灞?
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => this.showEditDialog = false)

        // 瀵硅瘽妗嗗唴瀹?
        Column({ space: 16 }) {
          Text('缂栬緫寰呭姙浜嬮」')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 20, bottom: 10 })

          // 鏍囬杈撳叆
          TextInput({ placeholder: '鏍囬', text: this.editTitle })
            .width('100%')
            .height(44)
            .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .fontSize(14)
            .onChange((value: string) => {
              this.editTitle = value;
            })

          // 鎻忚堪杈撳叆
          TextArea({ placeholder: '鎻忚堪锛堝彲閫夛級', text: this.editDescription })
            .width('100%')
            .height(80)
            .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .fontSize(13)
            .onChange((value: string) => {
              this.editDescription = value;
            })

          // 浼樺厛绾ч€夋嫨
          Row({ space: 12 }) {
            Text('浼樺厛绾?')
              .fontSize(14)
              .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))

            ForEach([TodoPriority.LOW, TodoPriority.MEDIUM, TodoPriority.HIGH, TodoPriority.URGENT],
              (priority: TodoPriority) => {
                Text(getPriorityLabel(priority))
                  .fontSize(13)
                  .fontColor(this.editPriority === priority ? '#FFFFFF' : getPriorityColor(priority, this.isDarkMode))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(this.editPriority === priority ? getPriorityColor(priority, this.isDarkMode) : 'transparent')
                  .border({
                    width: 1,
                    color: getPriorityColor(priority, this.isDarkMode)
                  })
                  .borderRadius(12)
                  .onClick(() => {
                    this.editPriority = priority;
                  })
              })
          }
          .width('100%')

          // 鎴鏃ユ湡
          TextInput({ placeholder: '鎴鏃ユ湡 (YYYY-MM-DD, 鍙€?', text: this.editDueDate })
            .width('100%')
            .height(44)
            .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.08)'))
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .fontSize(14)
            .onChange((value: string) => {
              this.editDueDate = value;
            })

          // 鎸夐挳
          Row({ space: 12 }) {
            Button('鍙栨秷')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor(this.textColor('#1A1A1A', '#FFFFFF'))
              .backgroundColor(this.bgColor('rgba(0,0,0,0.04)', 'rgba(255,255,255,0.1)'))
              .borderRadius(22)
              .onClick(() => this.showEditDialog = false)

            Button('淇濆瓨')
              .layoutWeight(1)
              .height(44)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#007DFF')
              .borderRadius(22)
              .onClick(() => this.saveEditTodo())
          }
          .width('100%')
          .padding({ top: 10, bottom: 20 })
        }
        .width('100%')
        .backgroundColor(this.bgColor('#FFFFFF', '#2C2C2E'))
        .borderRadius({ topLeft: 20, topRight: 20 })
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
  }
}
