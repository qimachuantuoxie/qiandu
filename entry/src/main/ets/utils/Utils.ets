/**
 * 全局提示工具 (GlobalToast)
 * 统一用户提示体验
 */
import { promptAction } from '@kit.ArkUI';

export enum ToastType {
  SUCCESS = '√',
  ERROR = '✕',
  WARNING = '⚠',
  INFO = 'ℹ'
}

export class GlobalToast {
  /**
   * 显示提示
   */
  static show(message: string, type: ToastType = ToastType.INFO, duration: number = 2000): void {
    promptAction.showToast({
      message: `${type} ${message}`,
      duration: duration
    });
  }

  static success(msg: string): void { GlobalToast.show(msg, ToastType.SUCCESS); }
  static error(msg: string): void { GlobalToast.show(msg, ToastType.ERROR, 3000); }
  static warning(msg: string): void { GlobalToast.show(msg, ToastType.WARNING); }
  static info(msg: string): void { GlobalToast.show(msg, ToastType.INFO); }
}

/**
 * 防抖与节流工具类 (DebounceUtils)
 */
export class DebounceUtils {
  private static timers: Map<string, number> = new Map();

  /**
   * 防抖：事件触发后等待 delay 毫秒再执行，如期间再次触发则重新计时
   */
  static debounce(fn: () => void, delay: number = 300): () => void {
    const timerKey = String(Date.now());
    return (): void => {
      if (DebounceUtils.timers.has(timerKey)) {
        clearTimeout(DebounceUtils.timers.get(timerKey)!);
      }
      const timer = setTimeout((): void => {
        fn();
        DebounceUtils.timers.delete(timerKey);
      }, delay) as number;
      DebounceUtils.timers.set(timerKey, timer);
    };
  }
  }

  /**
   * 节流：单段时间内只执行一次
   */
  static throttle(fn: () => void, interval: number = 500): () => void {
    let lastTime: number = 0;
    return (): void => {
      const now = Date.now();
      if (now - lastTime >= interval) {
        lastTime = now;
        fn();
      }
    };
  }
  }

  /**
   * 清理所有定时器
   */
  static clearAll(): void {
    for (const timer of DebounceUtils.timers.values()) {
      clearTimeout(timer);
    }
    DebounceUtils.timers.clear();
  }
}
