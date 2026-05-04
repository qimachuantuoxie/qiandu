import { logger } from '../../../common/utils/Logger';
/**
 * Todo ViewModel - 绠＄悊Todo鐨勪笟鍔￠€昏緫
 * 淇��锛氬幓闄??? 鎿嶄綔绗︼紝鏀圭敤鏄惧紡鍒ゆ柇
 */
import { TodoItem, TodoStatus, TodoPriority, TodoFilterType, TodoSortType, TodoStats, isTodoOverdue } from '../models/TodoModel';
import { preferenceManager } from '../utils/PreferenceManager';

/**
 * Todo鏇存柊鍥炶皟鎺ュ彛
 */
export interface TodoUpdateCallback {
  onUpdate(todos: TodoItem[]): void;
}

/**
 * Todo鏇存柊鍥炶皟瀹炵幇绫? */
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
 * 鎷疯礉TodoItem瀵硅薄锛堥伩鍏嶄娇鐢╯pread鎿嶄綔绗︼級
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
 * Todo ViewModel绫? */
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
   * 鍔犺浇鎵€鏈塗odo
   */
  loadTodos(): void {
    try {
      this.isLoading = true;
      const savedTodos = preferenceManager.getTodoList();
      this.todos = savedTodos;
      this.isLoading = false;
    } catch (error) {
      const err = error as Error;
      logger.error('[TodoViewModel] Load todos failed:', err.message);
      this.todos = [];
      this.isLoading = false;
    }
  }

  /**
   * 淇濆瓨鎵€鏈塗odo
   */
  private saveTodos(): void {
    try {
      preferenceManager.setTodoList(this.todos);
    } catch (error) {
      const err = error as Error;
      logger.error('[TodoViewModel] Save todos failed:', err.message);
    }
  }

  /**
   * 娣诲姞Todo
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
   * 鏇存柊Todo
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
   * 鍒犻櫎Todo
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
   * 鑾峰彇杩囨护鍚庣殑Todo鍒楄〃
   */
  getFilteredTodos(): TodoItem[] {
    let result = this.todos;

    // 鎸夌被鍨嬭繃婊?    if (this.filterType === TodoFilterType.PENDING) {
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

    // 鎼滅储杩囨护
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

    // 鎺掑簭
    result = this.sortTodos(result);

    return result;
  }

  /**
   * 鎺掑簭Todo
   */
  private sortTodos(todos: TodoItem[]): TodoItem[] {
    const sorted: TodoItem[] = [];
    for (let i = 0; i < todos.length; i++) {
      sorted.push(todos[i]);
    }

    if (this.sortType === TodoSortType.CREATED_TIME) {
      // 鍒涘缓鏃堕棿闄嶅簭锛堟柊鐨勫湪鍓嶏級
      sorted.sort((a, b) => b.createdTime - a.createdTime);
    } else if (this.sortType === TodoSortType.DUE_DATE) {
      // 鎴��鏃ユ湡鍗囧簭锛堟棭鐨勫湪鍓嶏級
      sorted.sort((a, b) => {
        const aDue = a.dueDate ? a.dueDate : Number.MAX_SAFE_INTEGER;
        const bDue = b.dueDate ? b.dueDate : Number.MAX_SAFE_INTEGER;
        return aDue - bDue;
      });
    } else if (this.sortType === TodoSortType.PRIORITY) {
      // 浼樺厛绾ч檷搴忥紙楂樹紭鍏堢骇鍦ㄥ墠锛?      sorted.sort((a, b) => b.priority - a.priority);
    } else if (this.sortType === TodoSortType.TITLE) {
      // 鏍囬�鍗囧簭
      sorted.sort((a, b) => a.title.localeCompare(b.title));
    }

    return sorted;
  }

  /**
   * 鑾峰彇缁熻�淇℃伅
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

  // 鍒濆�鍖栨柟娉?  async init(): Promise<void> {
    this.loadTodos();
  }

  // 鎼滅储Todo
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

  // 鑾峰彇杩囨护鍜屾帓搴忓悗鐨凾odo鍒楄〃
  getFilteredAndSortedTodos(filterType: TodoFilterType, sortType: TodoSortType): TodoItem[] {
    let result = this.todos;

    // 鎸夌被鍨嬭繃婊?    if (filterType === TodoFilterType.PENDING) {
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

    // 鎺掑簭
    const sorted: TodoItem[] = [];
    for (let i = 0; i < result.length; i++) {
      sorted.push(result[i]);
    }

    if (sortType === TodoSortType.PRIORITY) {
      sorted.sort((a, b) => b.priority - a.priority); // 浼樺厛绾ч檷搴忥紙楂樹紭鍏堢骇鍦ㄥ墠锛?    } else if (sortType === TodoSortType.DUE_DATE) {
      sorted.sort((a, b) => {
        const aDue = a.dueDate ? a.dueDate : Number.MAX_SAFE_INTEGER;
        const bDue = b.dueDate ? b.dueDate : Number.MAX_SAFE_INTEGER;
        return aDue - bDue; // 鎴��鏃ユ湡鍗囧簭锛堟棭鐨勫湪鍓嶏級
      });
    } else if (sortType === TodoSortType.CREATED_TIME) {
      sorted.sort((a, b) => b.createdTime - a.createdTime); // 鍒涘缓鏃堕棿闄嶅簭锛堟柊鐨勫湪鍓嶏級
    } else if (sortType === TodoSortType.TITLE) {
      sorted.sort((a, b) => a.title.localeCompare(b.title)); // 鏍囬�鍗囧簭
    }

    return sorted;
  }

  // 鎭㈠�Todo锛堟爣璁颁负鏈�畬鎴愶級
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

  // 瀹屾垚Todo
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

  // 搴旂敤杩囨护鍜屾帓搴忥紙鍏煎�鏃ф柟娉曪級
  applyFilterAndSort(searchText: string, filterType: TodoFilterType, sortType: TodoSortType): void {
    this.searchKeyword = searchText;
    this.filterType = filterType;
    this.sortType = sortType;
  }
}

// 瀵煎嚭鍗曚緥
export const todoViewModel = new TodoViewModel();
