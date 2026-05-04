// Todo 鏁版嵁妯″瀷

/**
 * Todo浼樺厛绾ф灇涓? */
export enum TodoPriority {
  LOW = 0,      // 浣庝紭鍏堢骇
  MEDIUM = 1,   // 涓紭鍏堢骇
  HIGH = 2,     // 楂樹紭鍏堢骇
  URGENT = 3    // 绱ф€?}

/**
 * Todo鐘舵€佹灇涓? */
export enum TodoStatus {
  PENDING = 0,    // 寰呭畬鎴?  IN_PROGRESS = 1, // 杩涜涓?  COMPLETED = 2,   // 宸插畬鎴?  CANCELLED = 3    // 宸插彇娑?}

/**
 * Todo鎺ュ彛瀹氫箟
 */
export interface TodoItem {
  id: string;               // 鍞竴鏍囪瘑
  title: string;            // 鏍囬
  description: string;      // 璇︾粏鎻忚堪
  priority: TodoPriority;   // 浼樺厛绾?  status: TodoStatus;       // 鐘舵€?  dueDate: number;          // 鎴鏃ユ湡锛堟椂闂存埑锛?  createdTime: number;      // 鍒涘缓鏃堕棿
  completedTime: number;    // 瀹屾垚鏃堕棿
  relatedBookId: string;    // 鍏宠仈鐨勪功鏋禝D锛堝彲閫夛級
  relatedBookTitle: string; // 鍏宠仈鐨勪功绫嶆爣棰?  tags: string[];           // 鏍囩鍒楄〃
  reminder: boolean;        // 鏄惁寮€鍚彁閱?}

/**
 * Todo杩囨护绫诲瀷鏋氫妇
 */
export enum TodoFilterType {
  ALL = 0,          // 鍏ㄩ儴
  PENDING = 1,      // 寰呭畬鎴?  IN_PROGRESS = 2,  // 杩涜涓?  COMPLETED = 3,    // 宸插畬鎴?  TODAY = 4,        // 浠婂ぉ鍒版湡
  OVERDUE = 5       // 宸茶繃鏈?}

/**
 * Todo鎺掑簭绫诲瀷鏋氫妇
 */
export enum TodoSortType {
  PRIORITY = 0,     // 鎸変紭鍏堢骇
  DUE_DATE = 1,     // 鎸夋埅姝㈡棩鏈?  CREATED_TIME = 2, // 鎸夊垱寤烘椂闂?  TITLE = 3         // 鎸夋爣棰?}

export interface TodoStats {
  total: number;
  pending: number;
  inProgress: number;
  completed: number;
  overdue: number;
  todayDue: number;
}

export function generateTodoId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
}

/**
 * 鑾峰彇浼樺厛绾ф爣绛炬枃鏈? */
export function getPriorityLabel(priority: TodoPriority): string {
  switch (priority) {
    case TodoPriority.LOW:
      return '浣?;
    case TodoPriority.MEDIUM:
      return '涓?;
    case TodoPriority.HIGH:
      return '楂?;
    case TodoPriority.URGENT:
      return '绱ф€?;
    default:
      return '鏈煡';
  }
}

/**
 * 鑾峰彇浼樺厛绾ч鑹? */
export function getPriorityColor(priority: TodoPriority, isDarkMode: boolean = false): string {
  switch (priority) {
    case TodoPriority.LOW:
      return isDarkMode ? '#4A90D9' : '#1890FF';
    case TodoPriority.MEDIUM:
      return isDarkMode ? '#F5A623' : '#FA8C16';
    case TodoPriority.HIGH:
      return isDarkMode ? '#F55050' : '#FF4D4F';
    case TodoPriority.URGENT:
      return isDarkMode ? '#FF0000' : '#CF1322';
    default:
      return isDarkMode ? '#888888' : '#999999';
  }
}

/**
 * 鑾峰彇鐘舵€佹爣绛炬枃鏈? */
export function getStatusLabel(status: TodoStatus): string {
  switch (status) {
    case TodoStatus.PENDING:
      return '寰呭畬鎴?;
    case TodoStatus.IN_PROGRESS:
      return '杩涜涓?;
    case TodoStatus.COMPLETED:
      return '宸插畬鎴?;
    case TodoStatus.CANCELLED:
      return '宸插彇娑?;
    default:
      return '鏈煡';
  }
}

/**
 * 鑾峰彇浼樺厛绾у浘鏍? */
export function getPriorityIcon(priority: TodoPriority): string {
  switch (priority) {
    case TodoPriority.LOW:
      return '馃敺';
    case TodoPriority.MEDIUM:
      return '馃敹';
    case TodoPriority.HIGH:
      return '馃敶';
    case TodoPriority.URGENT:
      return '鈿?;
    default:
      return '鉂?;
  }
}

/**
 * 鏍煎紡鍖栨埅姝㈡棩鏈熸樉绀? */
export function formatDueDate(dueDate: number): string {
  if (dueDate <= 0) {
    return '鏃犳埅姝㈡棩鏈?;
  }
  
  const now = Date.now();
  const diff = dueDate - now;
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  
  if (days < 0) {
    return '宸茶繃鏈? + Math.abs(days) + ' 澶?;
  } else if (days === 0) {
    return '浠婂ぉ鍒版湡';
  } else if (days === 1) {
    return '鏄庡ぉ鍒版湡';
  } else if (days < 7) {
    return days + ' 澶╁悗鍒版湡';
  } else {
    const date = new Date(dueDate);
    return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
  }
}

/**
 * 妫€鏌odo鏄惁宸茶繃鏈? */
export function isTodoOverdue(todo: TodoItem): boolean {
  if (todo.dueDate <= 0 || todo.status === TodoStatus.COMPLETED || todo.status === TodoStatus.CANCELLED) {
    return false;
  }
  return Date.now() > todo.dueDate;
}

/**
 * 鍒涘缓榛樿Todo椤? */
export function createDefaultTodo(relatedBookId: string = '', relatedBookTitle: string = ''): TodoItem {
  return {
    id: generateTodoId(),
    title: '',
    description: '',
    priority: TodoPriority.MEDIUM,
    status: TodoStatus.PENDING,
    dueDate: 0,
    createdTime: Date.now(),
    completedTime: 0,
    relatedBookId: relatedBookId,
    relatedBookTitle: relatedBookTitle,
    tags: [],
    reminder: false
  };
}
