import { logger } from '../../../common/utils/Logger';
import { TodoItem, TodoStatus, TodoPriority, TodoFilterType, TodoSortType, TodoStats, isTodoOverdue } from '../models/TodoModel';
import { MS_PER_DAY } from '../../../core/constants/TimeConstants';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

function copyTodoItem(todo: TodoItem, updates?: Partial<TodoItem>): TodoItem {
  return {
    id: updates?.id ?? todo.id,
    title: updates?.title ?? todo.title,
    description: updates?.description ?? todo.description,
    priority: updates?.priority ?? todo.priority,
    status: updates?.status ?? todo.status,
    dueDate: updates?.dueDate ?? todo.dueDate,
    createdTime: updates?.createdTime ?? todo.createdTime,
    completedTime: updates?.completedTime ?? todo.completedTime,
    relatedBookId: updates?.relatedBookId ?? todo.relatedBookId,
    relatedBookTitle: updates?.relatedBookTitle ?? todo.relatedBookTitle,
    tags: updates?.tags ?? todo.tags,
    reminder: updates?.reminder ?? todo.reminder
  };
}

@ObservedV2
export class TodoViewModel {
  @Trace private todos: TodoItem[] = [];
  @Trace private isLoading: boolean = false;
  @Trace private filterType: TodoFilterType = TodoFilterType.ALL;
  @Trace private sortType: TodoSortType = TodoSortType.CREATED_TIME;
  @Trace private searchKeyword: string = '';
  private pref: preferences.Preferences | null = null;

  constructor() {
    this.initPreferences();
  }

  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this) as common.Context;
      this.pref = await preferences.getPreferences(context, 'todo_data');
      this.loadTodos();
    } catch (error) {
      const err = error as Error;
      logger.error('[TodoViewModel] Init preferences failed:', err.message);
    }
  }

  loadTodos(): void {
    try {
      this.isLoading = true;
      if (this.pref) {
        this.pref.get('todo_list', '[]').then((value: string) => {
          try {
            const savedTodos = JSON.parse(value) as TodoItem[];
            this.todos = savedTodos;
          } catch {
            this.todos = [];
          }
          this.isLoading = false;
        });
      } else {
        this.todos = [];
        this.isLoading = false;
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[TodoViewModel] Load todos failed:', err.message);
      this.todos = [];
      this.isLoading = false;
    }
  }

  private saveTodos(): void {
    try {
      if (this.pref) {
        const jsonStr = JSON.stringify(this.todos);
        this.pref.put('todo_list', jsonStr).then(() => {
          this.pref?.flush();
        });
      }
    } catch (error) {
      const err = error as Error;
      logger.error('[TodoViewModel] Save todos failed:', err.message);
    }
  }

  addTodo(todo: TodoItem): void {
    const newTodos = [...this.todos, todo];
    this.todos = newTodos;
    this.saveTodos();
  }

  updateTodo(todoId: string, updates: Partial<TodoItem>): void {
    const index = this.todos.findIndex(t => t.id === todoId);
    if (index > -1) {
      const updatedTodo = copyTodoItem(this.todos[index], updates);
      const newTodos = [...this.todos];
      newTodos[index] = updatedTodo;
      this.todos = newTodos;
      this.saveTodos();
    }
  }

  deleteTodo(todoId: string): void {
    const newTodos = this.todos.filter(t => t.id !== todoId);
    this.todos = newTodos;
    this.saveTodos();
  }

  getFilteredTodos(): TodoItem[] {
    let result = this.todos;

    if (this.filterType === TodoFilterType.PENDING) {
      result = result.filter(t => t.status === TodoStatus.PENDING);
    } else if (this.filterType === TodoFilterType.COMPLETED) {
      result = result.filter(t => t.status === TodoStatus.COMPLETED);
    } else if (this.filterType === TodoFilterType.OVERDUE) {
      result = result.filter(t => isTodoOverdue(t));
    }

    if (this.searchKeyword && this.searchKeyword.length > 0) {
      const lowerKeyword = this.searchKeyword.toLowerCase();
      result = result.filter(t =>
        t.title.toLowerCase().includes(lowerKeyword) ||
        t.description.toLowerCase().includes(lowerKeyword)
      );
    }

    return this.sortTodos(result);
  }

  private sortTodos(todos: TodoItem[]): TodoItem[] {
    const sorted = [...todos];

    if (this.sortType === TodoSortType.CREATED_TIME) {
      sorted.sort((a, b) => b.createdTime - a.createdTime);
    } else if (this.sortType === TodoSortType.DUE_DATE) {
      sorted.sort((a, b) => {
        const aDue = a.dueDate || Number.MAX_SAFE_INTEGER;
        const bDue = b.dueDate || Number.MAX_SAFE_INTEGER;
        return aDue - bDue;
      });
    } else if (this.sortType === TodoSortType.PRIORITY) {
      sorted.sort((a, b) => b.priority - a.priority);
    } else if (this.sortType === TodoSortType.TITLE) {
      sorted.sort((a, b) => a.title.localeCompare(b.title));
    }

    return sorted;
  }

  getStats(): TodoStats {
    let total = 0, pending = 0, inProgress = 0, completed = 0, overdue = 0, todayDue = 0;
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = todayStart.getTime() + MS_PER_DAY;

    for (const todo of this.todos) {
      total++;
      if (todo.status === TodoStatus.PENDING) pending++;
      else if (todo.status === TodoStatus.IN_PROGRESS) inProgress++;
      else if (todo.status === TodoStatus.COMPLETED) completed++;
      if (isTodoOverdue(todo)) overdue++;
      if (todo.dueDate > 0 && todo.dueDate >= todayStart.getTime() && todo.dueDate < todayEnd) todayDue++;
    }

    return { total, pending, inProgress, completed, overdue, todayDue };
  }

  getTodos(): TodoItem[] { return this.todos; }
  getIsLoading(): boolean { return this.isLoading; }
  getFilterType(): TodoFilterType { return this.filterType; }
  setFilterType(type: TodoFilterType): void { this.filterType = type; }
  getSortType(): TodoSortType { return this.sortType; }
  setSortType(type: TodoSortType): void { this.sortType = type; }
  getSearchKeyword(): string { return this.searchKeyword; }
  setSearchKeyword(keyword: string): void { this.searchKeyword = keyword; }

  async init(): Promise<void> { this.loadTodos(); }

  searchTodos(keyword: string): TodoItem[] {
    const lowerKeyword = keyword.toLowerCase();
    return this.todos.filter(t =>
      t.title.toLowerCase().includes(lowerKeyword) ||
      t.description.toLowerCase().includes(lowerKeyword)
    );
  }

  getFilteredAndSortedTodos(filterType: TodoFilterType, sortType: TodoSortType): TodoItem[] {
    let result = this.todos;

    if (filterType === TodoFilterType.PENDING) {
      result = result.filter(t => t.status === TodoStatus.PENDING);
    } else if (filterType === TodoFilterType.IN_PROGRESS) {
      result = result.filter(t => t.status === TodoStatus.IN_PROGRESS);
    } else if (filterType === TodoFilterType.COMPLETED) {
      result = result.filter(t => t.status === TodoStatus.COMPLETED);
    } else if (filterType === TodoFilterType.OVERDUE) {
      result = result.filter(t => isTodoOverdue(t));
    } else if (filterType === TodoFilterType.TODAY) {
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const todayEnd = todayStart.getTime() + MS_PER_DAY;
      result = result.filter(t => t.dueDate > 0 && t.dueDate >= todayStart.getTime() && t.dueDate < todayEnd);
    }

    return this.sortTodos(result);
  }

  async restoreTodo(todoId: string): Promise<void> {
    this.updateTodo(todoId, { status: TodoStatus.PENDING, completedTime: 0 });
  }

  async completeTodo(todoId: string): Promise<void> {
    this.updateTodo(todoId, { status: TodoStatus.COMPLETED, completedTime: Date.now() });
  }

  applyFilterAndSort(searchText: string, filterType: TodoFilterType, sortType: TodoSortType): void {
    this.searchKeyword = searchText;
    this.filterType = filterType;
    this.sortType = sortType;
  }
}

export const todoViewModel = new TodoViewModel();
