/**
 * 简易加密存储工具
 */
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';

export class SecureStorage {
  private static instance: SecureStorage;
  private pref: preferences.Preferences | null = null;
  private isInitialized: boolean = false;
  private encoder: util.TextEncoder = new util.TextEncoder();
  private decoder: util.TextDecoder = new util.TextDecoder('utf-8', { ignoreBOM: true });

  private base64Helper: util.Base64Helper = new util.Base64Helper();

  private constructor() {}

  static getInstance(): SecureStorage {
    if (!SecureStorage.instance) {
      SecureStorage.instance = new SecureStorage();
    }
    return SecureStorage.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.isInitialized) return;
    try {
      this.pref = await preferences.getPreferences(context, 'secure_data');
      this.isInitialized = true;
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[SecureStorage] Init failed:', message);
    }
  }

  async setString(key: string, value: string): Promise<boolean> {
    if (!this.isInitialized || !this.pref) return false;
    try {
      const encoded: Uint8Array = this.encoder.encodeInto(value);
      const base64Str: string = this.encodeToBase64(encoded);
      await this.pref.put(key, base64Str);
      await this.pref.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.isInitialized || !this.pref) return defaultValue;
    try {
      const base64Str = await this.pref.get(key, '') as string;
      if (!base64Str) return defaultValue;
      const decoded: Uint8Array = this.decodeFromBase64(base64Str);
      return this.decoder.decodeWithStream(decoded);
    } catch (e) {
      return defaultValue;
    }
  }

  async remove(key: string): Promise<void> {
    if (this.pref) {
      try {
        await this.pref.delete(key);
        await this.pref.flush();
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        console.error('[SecureStorage] Remove failed:', message);
      }
    }
  }

  private encodeToBase64(data: Uint8Array): string {
    return this.base64Helper.encodeToStringSync(data);
  }

  private decodeFromBase64(base64Str: string): Uint8Array {
    const decoded: Uint8Array = this.base64Helper.decodeSync(base64Str);
    return decoded;
  }
}

export const secureStorage = SecureStorage.getInstance();
export default secureStorage;
