// 日志工具类 - 区分开发/生产环境
// 提供统一的日志输出，便于管理和控制

import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '千读阅界';

// 开发环境判断（可通过构建配置注入）
const IS_DEV_MODE = true; // 生产环境改为 false

class Logger {
  // 调试日志（仅开发环境）
  static debug(message: string, ...args: unknown[]): void {
    if (!IS_DEV_MODE) return;
    hilog.debug(0x0000, TAG, message, ...args);
  }

  // 信息日志
  static info(message: string, ...args: unknown[]): void {
    hilog.info(0x0000, TAG, message, ...args);
  }

  // 警告日志
  static warn(message: string, ...args: unknown[]): void {
    hilog.warn(0x0000, TAG, message, ...args);
  }

  // 错误日志
  static error(message: string, ...args: unknown[]): void {
    hilog.error(0x0000, TAG, message, ...args);
  }

  // 生产环境错误（始终输出）
  static productionError(message: string, ...args: unknown[]): void {
    hilog.error(0x0000, TAG, message, ...args);
  }
}

export const logger = Logger;
