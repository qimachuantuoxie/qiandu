// Todo 数据模型
import { MS_PER_DAY } from '../constants/TimeConstants';
import { PRIORITY_ICONS } from '../constants/UIIcons';

/**
 * Todo优先级枚举
 */
export enum TodoPriority {
  LOW = 0,      // 低优先级
  MEDIUM = 1,   // 中优先级
  HIGH = 2,     // 高优先级
  URGENT = 3    // 紧急
}

/**
 * Todo状态枚举
 */
export enum TodoStatus {
  PENDING = 0,    // 待完成
  IN_PROGRESS = 1, // 进行中
  COMPLETED = 2,   // 已完成
  CANCELLED = 3    // 已取消
}

/**
 * Todo接口定义
 */
export interface TodoItem {
  id: string;               // 唯一标识
  title: string;            // 标题
  description: string;      // 详细描述
  priority: TodoPriority;   // 优先级
  status: TodoStatus;       // 状态
  dueDate: number;          // 截止日期（时间戳）
  createdTime: number;      // 创建时间
  completedTime: number;    // 完成时间
  relatedBookId: string;    // 关联的书架ID（可选）
  relatedBookTitle: string; // 关联的书籍标题
  tags: string[];           // 标签列表
  reminder: boolean;        // 是否开启提醒
}

/**
 * Todo过滤类型枚举
 */
export enum TodoFilterType {
  ALL = 0,          // 全部
  PENDING = 1,      // 待完成
  IN_PROGRESS = 2,  // 进行中
  COMPLETED = 3,    // 已完成
  TODAY = 4,        // 今天到期
  OVERDUE = 5       // 已过期
}

/**
 * Todo排序类型枚举
 */
export enum TodoSortType {
  PRIORITY = 0,     // 按优先级
  DUE_DATE = 1,     // 按截止日期
  CREATED_TIME = 2, // 按创建时间
  TITLE = 3         // 按标题
}

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
 * 获取优先级标签文本
 */
export function getPriorityLabel(priority: TodoPriority): string {
  switch (priority) {
    case TodoPriority.LOW:
      return '低';
    case TodoPriority.MEDIUM:
      return '中';
    case TodoPriority.HIGH:
      return '高';
    case TodoPriority.URGENT:
      return '紧急';
    default:
      return '未知';
  }
}

/**
 * 获取优先级颜色
 */
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
 * 获取状态标签文本
 */
export function getStatusLabel(status: TodoStatus): string {
  switch (status) {
    case TodoStatus.PENDING:
      return '待完成';
    case TodoStatus.IN_PROGRESS:
      return '进行中';
    case TodoStatus.COMPLETED:
      return '已完成';
    case TodoStatus.CANCELLED:
      return '已取消';
    default:
      return '未知';
  }
}

/**
 * 获取优先级图标
 */
export function getPriorityIcon(priority: TodoPriority): string {
  switch (priority) {
    case TodoPriority.LOW:
      return PRIORITY_ICONS.LOW;
    case TodoPriority.MEDIUM:
      return PRIORITY_ICONS.MEDIUM;
    case TodoPriority.HIGH:
      return PRIORITY_ICONS.HIGH;
    case TodoPriority.URGENT:
      return PRIORITY_ICONS.HIGH;  // 紧急使用高优先级图标
    default:
      return PRIORITY_ICONS.MEDIUM;
  }
}

/**
 * 格式化截止日期显示
 */
export function formatDueDate(dueDate: number): string {
  if (dueDate <= 0) {
    return '无截止日期';
  }
  
  const now = Date.now();
  const diff = dueDate - now;
  const days = Math.floor(diff / MS_PER_DAY);
  
  if (days < 0) {
    return '已过期' + Math.abs(days) + '天';
  } else if (days === 0) {
    return '今天到期';
  } else if (days === 1) {
    return '明天到期';
  } else if (days < 7) {
    return days + '天后到期';
  } else {
    const date = new Date(dueDate);
    return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0');
  }
}

/**
 * 检查Todo是否已过期
 */
export function isTodoOverdue(todo: TodoItem): boolean {
  if (todo.dueDate <= 0 || todo.status === TodoStatus.COMPLETED || todo.status === TodoStatus.CANCELLED) {
    return false;
  }
  return Date.now() > todo.dueDate;
}

/**
 * 创建默认Todo项
 */
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
