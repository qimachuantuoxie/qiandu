/**
 * Base Preferences Management
 * Provides common read/write functionality for preferences
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { PREFERENCES_NAME } from './StorageKeys';

export class BasePrefs {
  protected pref: preferences.Preferences | null = null;
  protected context: common.Context | null = null;
  protected cache: Map<string, string | number | boolean> = new Map();
  protected cacheEnabled: boolean = true;
  protected initialized: boolean = false;

  async init(context: common.Context): Promise<void> {
    if (this.initialized && this.pref) {
      return;
    }
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, PREFERENCES_NAME);
      this.initialized = true;
      console.info('[BasePrefs] Initialized successfully');
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Init failed:', err.message);
    }
  }

  protected ensureInitialized(): void {
    if (!this.pref) {
      throw new Error('Preferences not initialized. Call init() first.');
    }
  }

  clearCache(): void {
    this.cache.clear();
  }

  async getStringAsync(key: string, defaultValue: string): Promise<string> {
    this.ensureInitialized();
    if (!this.pref) {
      return defaultValue;
    }
    const cached = this.cache.get(key);
    if (this.cacheEnabled && cached !== undefined) {
      return cached as string;
    }
    try {
      const value = await this.pref.get(key, defaultValue);
      const result = value as string;
      if (this.cacheEnabled) {
        this.cache.set(key, result);
      }
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Read failed:', err.message);
      return defaultValue;
    }
  }

  async setStringAsync(key: string, value: string): Promise<void> {
    this.ensureInitialized();
    if (!this.pref) {
      return;
    }
    try {
      await this.pref.put(key, value);
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Write failed:', err.message);
    }
  }

  async getNumberAsync(key: string, defaultValue: number): Promise<number> {
    this.ensureInitialized();
    if (!this.pref) {
      return defaultValue;
    }
    const cached = this.cache.get(key);
    if (this.cacheEnabled && cached !== undefined) {
      return cached as number;
    }
    try {
      const value = await this.pref.get(key, defaultValue);
      const result = value as number;
      if (this.cacheEnabled) {
        this.cache.set(key, result);
      }
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Read failed:', err.message);
      return defaultValue;
    }
  }

  async setNumberAsync(key: string, value: number): Promise<void> {
    this.ensureInitialized();
    if (!this.pref) {
      return;
    }
    try {
      await this.pref.put(key, value);
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Write failed:', err.message);
    }
  }

  async getBooleanAsync(key: string, defaultValue: boolean): Promise<boolean> {
    this.ensureInitialized();
    if (!this.pref) {
      return defaultValue;
    }
    const cached = this.cache.get(key);
    if (this.cacheEnabled && cached !== undefined) {
      return cached as boolean;
    }
    try {
      const val = await this.pref.get(key, defaultValue);
      const result = val as boolean;
      if (this.cacheEnabled) {
        this.cache.set(key, result);
      }
      return result;
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Read failed:', err.message);
      return defaultValue;
    }
  }

  async setBooleanAsync(key: string, value: boolean): Promise<void> {
    this.ensureInitialized();
    if (!this.pref) {
      return;
    }
    try {
      await this.pref.put(key, value);
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Write failed:', err.message);
    }
  }

  getString(key: string, defaultValue: string): string {
    if (!this.pref) return defaultValue;
    try {
      return this.pref.getSync(key, defaultValue) as string;
    } catch {
      return defaultValue;
    }
  }

  setString(key: string, value: string): void {
    if (!this.pref) return;
    try {
      this.pref.putSync(key, value);
      this.pref.flush();
    } catch (e) {
      const err = e as Error;
      console.error('[BasePrefs] Set string failed:', err.message);
    }
  }

  getNumber(key: string, defaultValue: number = 0): number {
    const value = this.getString(key, '');
    return value === '' ? defaultValue : Number(value);
  }

  setNumber(key: string, value: number): void {
    this.setString(key, String(value));
  }

  deleteValue(key: string): void {
    this.setString(key, '');
  }

  getBoolean(key: string, defaultValue: boolean = false): boolean {
    if (!this.pref) return defaultValue;
    try {
      return this.pref.getSync(key, defaultValue) as boolean;
    } catch {
      return defaultValue;
    }
  }

  setBoolean(key: string, value: boolean): void {
    if (!this.pref) return;
    try {
      this.pref.putSync(key, value);
      if (this.cacheEnabled) {
        this.cache.set(key, value);
      }
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] setSync failed:', err.message);
    }
  }

  async delete(key: string): Promise<void> {
    this.ensureInitialized();
    if (!this.pref) {
      return;
    }
    try {
      await this.pref.delete(key);
      this.cache.delete(key);
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Delete failed:', err.message);
    }
  }

  async flush(): Promise<void> {
    this.ensureInitialized();
    if (!this.pref) {
      return;
    }
    try {
      await this.pref.flush();
    } catch (error) {
      const err = error as Error;
      console.error('[BasePrefs] Flush failed:', err.message);
    }
  }
}
