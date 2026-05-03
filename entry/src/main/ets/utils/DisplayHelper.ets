/**
 * Display Helper for API 22+
 * Replaces deprecated getDefaultDisplaySync
 */
import { display } from '@kit.ArkUI';

export class DisplayHelper {
  private static instance: DisplayHelper | null = null;
  private currentDisplay: display.Display | null = null;

  static getInstance(): DisplayHelper {
    if (!DisplayHelper.instance) {
      DisplayHelper.instance = new DisplayHelper();
    }
    return DisplayHelper.instance;
  }

  async init(): Promise<void> {
    try {
      const displays: display.Display[] = await display.getAllDisplays();
      if (displays && displays.length > 0) {
        this.currentDisplay = displays[0];
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[DisplayHelper] Init failed:', message);
    }
  }

  getDisplay(): display.Display | null {
    return this.currentDisplay;
  }

  getWidth(): number {
    return this.currentDisplay?.width || 0;
  }

  getHeight(): number {
    return this.currentDisplay?.height || 0;
  }

  getDPI(): number {
    return this.currentDisplay?.xDPI || 0;
  }

  isFoldable(): boolean {
    return false;
  }
}

export const displayHelper = DisplayHelper.getInstance();

// Legacy compatible wrapper
export function getDefaultDisplaySync(): display.Display | null {
  return displayHelper.getDisplay();
}