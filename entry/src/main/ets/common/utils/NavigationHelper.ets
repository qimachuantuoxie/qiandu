/**
 * Navigation Helper
 * 使用 Navigation 组件，已移除 router 降级方案
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { NavPathStack } from '@kit.ArkUI';
import { logger } from '../utils/Logger';

const TAG = '[NavigationHelper]';

export class NavigationHelper {
  private static instance: NavigationHelper | null = null;
  private navPathStack: NavPathStack | null = null;

  static getInstance(): NavigationHelper {
    if (!NavigationHelper.instance) {
      NavigationHelper.instance = new NavigationHelper();
    }
    return NavigationHelper.instance;
  }

  /**
   * 设置 NavPathStack（由 MainPage 调用）
   */
  setNavPathStack(stack: NavPathStack): void {
    this.navPathStack = stack;
  }

  /**
   * 获取 NavPathStack
   */
  getNavPathStack(): NavPathStack | null {
    return this.navPathStack;
  }

  getStack(): void | null {
    return null;
  }

  /**
   * 使用 Navigation 导航
   */
  pushPath(name: string, param?: object): void {
    if (this.navPathStack) {
      try {
        this.navPathStack.pushPath({ name, param });
      } catch (error) {
        const err = error as BusinessError;
        logger.error(TAG + ' pushPath failed:', err.message);
      }
    } else {
      logger.error(TAG + ' navPathStack is null, cannot navigate');
    }
  }

  pushPathByName(name: string, param?: object): void {
    this.pushPath(name, param);
  }

  /**
   * 返回上一页
   */
  pop(): void {
    if (this.navPathStack) {
      try {
        this.navPathStack.pop();
      } catch (error) {
        const err = error as BusinessError;
        logger.error(TAG + ' pop failed:', err.message);
      }
    } else {
      logger.error(TAG + ' navPathStack is null, cannot pop');
    }
  }

  popToName(name: string): void {
    if (this.navPathStack) {
      try {
        this.navPathStack.popToName(name);
      } catch (error) {
        const err = error as BusinessError;
        logger.error(TAG + ' popToName failed:', err.message);
      }
    } else {
      logger.error(TAG + ' navPathStack is null, cannot popToName');
    }
  }

  clear(): void {
    if (this.navPathStack) {
      this.navPathStack.clear();
    } else {
      logger.warn(TAG + ' clear() called on empty stack');
    }
  }

  getSize(): number {
    if (this.navPathStack) {
      return this.navPathStack.size();
    }
    return 0;
  }

  getBackStack(): string[] {
    if (this.navPathStack) {
      return this.navPathStack.getAllPathName();
    }
    return [];
  }
}

export const navHelper = NavigationHelper.getInstance();

/**
 * Page transition with Navigation only
 */
export function navigateTo(page: string, param?: object): void {
  navHelper.pushPath(page, param);
}

/**
 * 返回上一页
 */
export function goBack(): void {
  navHelper.pop();
}

/**
 * 清空栈并跳转
 */
export function clearAndNavigate(page: string, param?: object): void {
  navHelper.clear();
  navHelper.pushPath(page, param);
}
