/**
 * Dialog Helper - 基于 @hadss/dialoghub 的统一对话框工具
 * 
 * 提供统一的Toast、Dialog、Loading等提示组件
 */

import { DialogHub } from '@hadss/dialoghub';
import { HDSColours, HDSAnimation } from '../design/tokens/HDSDTokens';

/**
 * Toast 配置接口
 */
export interface ToastConfig {
  message: string;
  duration?: number;
  type?: 'success' | 'error' | 'warning' | 'info';
}

/**
 * Dialog 配置接口
 */
export interface DialogConfig {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm?: () => void;
  onCancel?: () => void;
  showCancel?: boolean;
}

/**
 * Loading 配置接口
 */
export interface LoadingConfig {
  message?: string;
  mask?: boolean;
}

/**
 * 统一对话框工具类
 */
export class DialogHelper {
  
  /**
   * 显示成功提示
   */
  static success(config: string | ToastConfig): void {
    const cfg = typeof config === 'string' ? { message: config } : config;
    
    DialogHub.success({
      title: '成功',
      message: cfg.message,
      duration: cfg.duration || 2000,
      iconColor: HDSColours.success
    });
  }
  
  /**
   * 显示错误提示
   */
  static error(config: string | ToastConfig): void {
    const cfg = typeof config === 'string' ? { message: config } : config;
    
    DialogHub.error({
      title: '错误',
      message: cfg.message,
      duration: cfg.duration || 2500,
      iconColor: HDSColours.error
    });
  }
  
  /**
   * 显示警告提示
   */
  static warning(config: string | ToastConfig): void {
    const cfg = typeof config === 'string' ? { message: config } : config;
    
    DialogHub.warning({
      title: '警告',
      message: cfg.message,
      duration: cfg.duration || 2000,
      iconColor: HDSColours.warning
    });
  }
  
  /**
   * 显示信息提示
   */
  static info(config: string | ToastConfig): void {
    const cfg = typeof config === 'string' ? { message: config } : config;
    
    DialogHub.info({
      title: '提示',
      message: cfg.message,
      duration: cfg.duration || 2000,
      iconColor: HDSColours.info
    });
  }
  
  /**
   * 显示确认对话框
   */
  static confirm(config: DialogConfig): void {
    DialogHub.confirm({
      title: config.title || '确认',
      message: config.message,
      confirmText: config.confirmText || '确定',
      cancelText: config.cancelText || '取消',
      showCancel: config.showCancel !== false,
      onConfirm: config.onConfirm,
      onCancel: config.onCancel,
      confirmColor: HDSColours.primary.blue,
      cancelColor: HDSColours.neutral.gray600
    });
  }
  
  /**
   * 显示加载状态
   */
  static loading(config: string | LoadingConfig = '加载中...'): void {
    const cfg = typeof config === 'string' ? { message: config } : config;
    
    DialogHub.loading({
      message: cfg.message || '加载中...',
      mask: cfg.mask !== false
    });
  }
  
  /**
   * 隐藏加载状态
   */
  static hideLoading(): void {
    DialogHub.dismiss();
  }
  
  /**
   * 显示自定义对话框
   */
  static custom(options: Record<string, ESObject>): void {
    DialogHub.custom(options);
  }
  
  /**
   * 关闭所有对话框
   */
  static dismiss(): void {
    DialogHub.dismiss();
  }
}

export default DialogHelper;
