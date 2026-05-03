/**
 * Todo ViewModel - 管理Todo的业务逻辑
 * 修复：去除 ?? 操作符，改用显式判断
 */
import { TodoItem, TodoStatus, TodoPriority, TodoFilterType, TodoSortType, TodoStats, isTodoOverdue } from '../models/TodoModel';
import { preferenceManager } from '../utils/PreferenceManager';

/**
 * Todo更新回调接口
 */
export interface TodoUpdateCallback {
  onUpdate(todos: TodoItem[]): void;
}

/**
 * Todo更新回调实现类
 */
class TodoUpdateCallbackImpl implements TodoUpdateCallback {
  private callback: (todos: TodoItem[]) => void;

  constructor(callback: (todos: TodoItem[]) => void) {
    this.callback = callback;
  }

  onUpdate(todos: TodoItem[]): void {
    this.callback(todos);
  }
}

/**
 * 拷贝TodoItem对象（避免使用spread操作符）
 */
function copyTodoItem(todo: TodoItem, updates?: Partial<TodoItem>): TodoItem {
  const newItem: TodoItem = {
    id: updates && updates.id !== undefined ? updates.id : todo.id,
    title: updates && updates.title !== undefined ? updates.title : todo.title,
    description: updates && updates.description !== undefined ? updates.description : todo.description,
    priority: updates && updates.priority !== undefined ? updates.priority : todo.priority,
    status: updates && updates.status !== undefined ? updates.status : todo.status,
    dueDate: updates && updates.dueDate !== undefined ? updates.dueDate : todo.dueDate,
    createdTime: updates && updates.createdTime !== undefined ? updates.createdTime : todo.createdTime,
    completedTime: updates && updates.completedTime !== undefined ? updates.completedTime : todo.completedTime,
    relatedBookId: updates && updates.relatedBookId !== undefined ? updates.relatedBookId : todo.relatedBookId,
    relatedBookTitle: updates && updates.relatedBookTitle !== undefined ? updates.relatedBookTitle : todo.relatedBookTitle,
    tags: updates && updates.tags !== undefined ? updates.tags : todo.tags,
    reminder: updates && updates.reminder !== undefined ? updates.reminder : todo.reminder
  };
  return newItem;
}

/**
 * Todo ViewModel类
 */
@ObservedV2
export class TodoViewModel {
  @Trace private todos: TodoItem[] = [];
  @Trace private isLoading: boolean = false;
  @Trace private filterType: TodoFilterType = TodoFilterType.ALL;
  @Trace private sortType: TodoSortType = TodoSortType.CREATED_TIME;
  @Trace private searchKeyword: string = '';

  constructor() {
    this.loadTodos();
  }

  /**
   * 加载所有Todo
   */
  loadTodos(): void {
    try {
      this.isLoading = true;
      const savedTodos = preferenceManager.getTodoList();
      this.todos = savedTodos;
      this.isLoading = false;
    } catch (error) {
      const err = error as Error;
      console.error('[TodoViewModel] Load todos failed:', err.message);
      this.todos = [];
      this.isLoading = false;
    }
  }

  /**
   * 保存所有Todo
   */
  private saveTodos(): void {
    try {
      preferenceManager.setTodoList(this.todos);
    } catch (error) {
      const err = error as Error;
      console.error('[TodoViewModel] Save todos failed:', err.message);
    }
  }

  /**
   * 添加Todo
   */
  addTodo(todo: TodoItem): void {
    const newTodos: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      newTodos.push(this.todos[i]);
    }
    newTodos.push(todo);
    this.todos = newTodos;
    this.saveTodos();
  }

  /**
   * 更新Todo
   */
  updateTodo(todoId: string, updates: Partial<TodoItem>): void {
    let index = -1;
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id === todoId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const updatedTodo = copyTodoItem(this.todos[index], updates);
      const newTodos: TodoItem[] = [];
      for (let i = 0; i < this.todos.length; i++) {
        if (i === index) {
          newTodos.push(updatedTodo);
        } else {
          newTodos.push(this.todos[i]);
        }
      }
      this.todos = newTodos;
      this.saveTodos();
    }
  }

  /**
   * 删除Todo
   */
  deleteTodo(todoId: string): void {
    const newTodos: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id !== todoId) {
        newTodos.push(this.todos[i]);
      }
    }
    this.todos = newTodos;
    this.saveTodos();
  }

  /**
   * 获取过滤后的Todo列表
   */
  getFilteredTodos(): TodoItem[] {
    let result = this.todos;

    // 按类型过滤
    if (this.filterType === TodoFilterType.PENDING) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (result[i].status === TodoStatus.PENDING) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (this.filterType === TodoFilterType.COMPLETED) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (result[i].status === TodoStatus.COMPLETED) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (this.filterType === TodoFilterType.OVERDUE) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (isTodoOverdue(result[i])) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    }

    // 搜索过滤
    if (this.searchKeyword && this.searchKeyword.length > 0) {
      const lowerKeyword = this.searchKeyword.toLowerCase();
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        const title = result[i].title.toLowerCase();
        const description = result[i].description ? result[i].description.toLowerCase() : '';
        if (title.includes(lowerKeyword) || description.includes(lowerKeyword)) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    }

    // 排序
    result = this.sortTodos(result);

    return result;
  }

  /**
   * 排序Todo
   */
  private sortTodos(todos: TodoItem[]): TodoItem[] {
    const sorted: TodoItem[] = [];
    for (let i = 0; i < todos.length; i++) {
      sorted.push(todos[i]);
    }

    if (this.sortType === TodoSortType.CREATED_TIME) {
      // 创建时间降序（新的在前）
      sorted.sort((a, b) => b.createdTime - a.createdTime);
    } else if (this.sortType === TodoSortType.DUE_DATE) {
      // 截止日期升序（早的在前）
      sorted.sort((a, b) => {
        const aDue = a.dueDate ? a.dueDate : Number.MAX_SAFE_INTEGER;
        const bDue = b.dueDate ? b.dueDate : Number.MAX_SAFE_INTEGER;
        return aDue - bDue;
      });
    } else if (this.sortType === TodoSortType.PRIORITY) {
      // 优先级降序（高优先级在前）
      sorted.sort((a, b) => b.priority - a.priority);
    } else if (this.sortType === TodoSortType.TITLE) {
      // 标题升序
      sorted.sort((a, b) => a.title.localeCompare(b.title));
    }

    return sorted;
  }

  /**
   * 获取统计信息
   */
  getStats(): TodoStats {
    let total = 0;
    let pending = 0;
    let inProgress = 0;
    let completed = 0;
    let overdue = 0;
    let todayDue = 0;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    const todayEnd = todayStart + 24 * 60 * 60 * 1000;

    for (let i = 0; i < this.todos.length; i++) {
      const todo = this.todos[i];
      total++;
      if (todo.status === TodoStatus.PENDING) {
        pending++;
      } else if (todo.status === TodoStatus.IN_PROGRESS) {
        inProgress++;
      } else if (todo.status === TodoStatus.COMPLETED) {
        completed++;
      }
      if (isTodoOverdue(todo)) {
        overdue++;
      }
      if (todo.dueDate > 0 && todo.dueDate >= todayStart && todo.dueDate < todayEnd) {
        todayDue++;
      }
    }

    return { total, pending, inProgress, completed, overdue, todayDue };
  }

  // Getters
  getTodos(): TodoItem[] {
    return this.todos;
  }

  getIsLoading(): boolean {
    return this.isLoading;
  }

  getFilterType(): TodoFilterType {
    return this.filterType;
  }

  setFilterType(type: TodoFilterType): void {
    this.filterType = type;
  }

  getSortType(): TodoSortType {
    return this.sortType;
  }

  setSortType(type: TodoSortType): void {
    this.sortType = type;
  }

  getSearchKeyword(): string {
    return this.searchKeyword;
  }

  setSearchKeyword(keyword: string): void {
    this.searchKeyword = keyword;
  }

  // 初始化方法
  async init(): Promise<void> {
    this.loadTodos();
  }

  // 搜索Todo
  searchTodos(keyword: string): TodoItem[] {
    const lowerKeyword = keyword.toLowerCase();
    const result: TodoItem[] = [];
    for (let i = 0; i < this.todos.length; i++) {
      const todo = this.todos[i];
      const title = todo.title.toLowerCase();
      const description = todo.description ? todo.description.toLowerCase() : '';
      if (title.includes(lowerKeyword) || description.includes(lowerKeyword)) {
        result.push(todo);
      }
    }
    return result;
  }

  // 获取过滤和排序后的Todo列表
  getFilteredAndSortedTodos(filterType: TodoFilterType, sortType: TodoSortType): TodoItem[] {
    let result = this.todos;

    // 按类型过滤
    if (filterType === TodoFilterType.PENDING) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (result[i].status === TodoStatus.PENDING) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (filterType === TodoFilterType.IN_PROGRESS) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (result[i].status === TodoStatus.IN_PROGRESS) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (filterType === TodoFilterType.COMPLETED) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (result[i].status === TodoStatus.COMPLETED) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (filterType === TodoFilterType.OVERDUE) {
      const filtered: TodoItem[] = [];
      for (let i = 0; i < result.length; i++) {
        if (isTodoOverdue(result[i])) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    } else if (filterType === TodoFilterType.TODAY) {
      const filtered: TodoItem[] = [];
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayStart = today.getTime();
      const todayEnd = todayStart + 24 * 60 * 60 * 1000;
      for (let i = 0; i < result.length; i++) {
        const dueDate = result[i].dueDate;
        if (dueDate > 0 && dueDate >= todayStart && dueDate < todayEnd) {
          filtered.push(result[i]);
        }
      }
      result = filtered;
    }

    // 排序
    const sorted: TodoItem[] = [];
    for (let i = 0; i < result.length; i++) {
      sorted.push(result[i]);
    }

    if (sortType === TodoSortType.PRIORITY) {
      sorted.sort((a, b) => b.priority - a.priority); // 优先级降序（高优先级在前）
    } else if (sortType === TodoSortType.DUE_DATE) {
      sorted.sort((a, b) => {
        const aDue = a.dueDate ? a.dueDate : Number.MAX_SAFE_INTEGER;
        const bDue = b.dueDate ? b.dueDate : Number.MAX_SAFE_INTEGER;
        return aDue - bDue; // 截止日期升序（早的在前）
      });
    } else if (sortType === TodoSortType.CREATED_TIME) {
      sorted.sort((a, b) => b.createdTime - a.createdTime); // 创建时间降序（新的在前）
    } else if (sortType === TodoSortType.TITLE) {
      sorted.sort((a, b) => a.title.localeCompare(b.title)); // 标题升序
    }

    return sorted;
  }

  // 恢复Todo（标记为未完成）
  async restoreTodo(todoId: string): Promise<void> {
    let index = -1;
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id === todoId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const updatedTodo = copyTodoItem(this.todos[index], { status: TodoStatus.PENDING, completedTime: 0 });
      const newTodos: TodoItem[] = [];
      for (let i = 0; i < this.todos.length; i++) {
        if (i === index) {
          newTodos.push(updatedTodo);
        } else {
          newTodos.push(this.todos[i]);
        }
      }
      this.todos = newTodos;
      this.saveTodos();
    }
  }

  // 完成Todo
  async completeTodo(todoId: string): Promise<void> {
    let index = -1;
    for (let i = 0; i < this.todos.length; i++) {
      if (this.todos[i].id === todoId) {
        index = i;
        break;
      }
    }
    if (index > -1) {
      const updatedTodo = copyTodoItem(this.todos[index], { status: TodoStatus.COMPLETED, completedTime: Date.now() });
      const newTodos: TodoItem[] = [];
      for (let i = 0; i < this.todos.length; i++) {
        if (i === index) {
          newTodos.push(updatedTodo);
        } else {
          newTodos.push(this.todos[i]);
        }
      }
      this.todos = newTodos;
      this.saveTodos();
    }
  }

  // 应用过滤和排序（兼容旧方法）
  applyFilterAndSort(searchText: string, filterType: TodoFilterType, sortType: TodoSortType): void {
    this.searchKeyword = searchText;
    this.filterType = filterType;
    this.sortType = sortType;
  }
}

// 导出单例
export const todoViewModel = new TodoViewModel();
