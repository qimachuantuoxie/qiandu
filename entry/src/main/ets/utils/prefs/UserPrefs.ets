/**
 * 用户偏好设置管理
 * 管理用户信息、语言设置、待办等
 */

import { BasePrefs } from './BasePrefs';
import { UserInfo } from '../../models/AuthModels';
import * as Keys from './StorageKeys';

export class UserPrefs extends BasePrefs {
  private static instance: UserPrefs | null = null;

  static getInstance(): UserPrefs {
    if (!UserPrefs.instance) {
      UserPrefs.instance = new UserPrefs();
    }
    return UserPrefs.instance;
  }

  // ========== 用户信息 ==========

  /**
   * 获取用户信息
   */
  getUserInfo(): UserInfo | null {
    try {
      const userInfoJson = this.getString(Keys.KEY_USER_INFO, 'null');
      if (userInfoJson === 'null') {
        return null;
      }
      return JSON.parse(userInfoJson) as UserInfo;
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 获取用户信息失败: ' + err.message);
      return null;
    }
  }

  /**
   * 保存用户信息
   */
  setUserInfo(userInfo: UserInfo): void {
    try {
      const userInfoJson = JSON.stringify(userInfo);
      this.setString(Keys.KEY_USER_INFO, userInfoJson);
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 保存用户信息失败: ' + err.message);
    }
  }

  /**
   * 清除用户信息
   */
  clearUserInfo(): void {
    try {
      this.delete(Keys.KEY_USER_INFO);
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 清除用户信息失败: ' + err.message);
    }
  }

  // ========== 语言设置 ==========

  /**
   * 获取语言设置
   */
  getLanguage(): string {
    try {
      return this.getString(Keys.KEY_LANGUAGE, 'zh-CN');
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 获取语言设置失败: ' + err.message);
      return 'zh-CN';
    }
  }

  /**
   * 设置语言
   */
  setLanguage(language: string): void {
    try {
      this.setString(Keys.KEY_LANGUAGE, language);
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 设置语言失败: ' + err.message);
    }
  }

  // ========== 待办事项 ==========

  /**
   * 保存待办事项
   */
  setTodos(todosJson: string): void {
    try {
      this.setString(Keys.KEY_TODOS, todosJson);
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 保存待办事项失败: ' + err.message);
    }
  }

  /**
   * 获取待办事项
   */
  getTodos(): string {
    try {
      return this.getString(Keys.KEY_TODOS, '[]');
    } catch (error) {
      const err = error as Error;
      console.error('[UserPrefs] 获取待办事项失败: ' + err.message);
      return '[]';
    }
  }
}

// 导出单例
export const userPrefs = UserPrefs.getInstance();
