/**
 * Toast Helper for API 22+
 * Replaces deprecated promptAction.showToast
 */
// API 22+: promptAction.showToast is deprecated
// Use custom toast component or system notification
import { UIContext } from '@kit.ArkUI';
import { logger } from '../../core/utils/Logger';

export interface ToastOptions {
  message: string;
  duration?: number;
  bottom?: number;
}

export class ToastHelper {
  private static instance: ToastHelper | null = null;

  static getInstance(): ToastHelper {
    if (!ToastHelper.instance) {
      ToastHelper.instance = new ToastHelper();
    }
    return ToastHelper.instance;
  }

  show(options: ToastOptions): void {
    try {
      // API 22+ replacement for deprecated showToast
      logger.info('[Toast] ' + options.message);
      // TODO: Implement proper custom toast UI component - Using system log as fallback
      // For now, use system log as fallback
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      logger.error('[ToastHelper] Show failed:', message);
    }
  }

  showShort(message: string): void {
    this.show({ message: message, duration: 1500 });
  }

  showLong(message: string): void {
    this.show({ message: message, duration: 3000 });
  }

  // API 22+: Use custom dialog component instead of CommonDialog
  showDialog(options: ToastOptions): void {
    logger.info('[ToastDialog] ' + options.message);
    // Fallback to simple show
    this.show(options);
  }
}

export const toastHelper = ToastHelper.getInstance();

// Quick alias
export function toast(message: string, duration: number = 2000): void {
  toastHelper.show({ message: message, duration: duration });
}

export function toastShort(message: string): void {
  toastHelper.showShort(message);
}

export function toastLong(message: string): void {
  toastHelper.showLong(message);
}