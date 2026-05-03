/**
 * Navigation Helper
 * Uses router with proper exception handling
 */
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = '[NavigationHelper]';

export class NavigationHelper {
  private static instance: NavigationHelper | null = null;

  static getInstance(): NavigationHelper {
    if (!NavigationHelper.instance) {
      NavigationHelper.instance = new NavigationHelper();
    }
    return NavigationHelper.instance;
  }

  getStack(): void | null {
    return null;
  }


  pushPath(name: string, param?: object): void {
    try {
      router.pushUrl({ url: name, params: param })
        .catch((err: BusinessError) => {
          console.error(`${TAG} pushPath failed:`, err.message);
        });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} pushPath error:`, err.message);
    }
  }

  pushPathByName(name: string, param?: object): void {
    try {
      router.pushUrl({ url: name, params: param })
        .catch((err: BusinessError) => {
          console.error(`${TAG} pushPathByName failed:`, err.message);
        });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} pushPathByName error:`, err.message);
    }
  }

  pop(): void {
    try {
      router.back();
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} pop failed:`, err.message);
    }
  }

  popToName(name: string): void {
    try {
      router.back({ url: name });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} popToName failed:`, err.message);
    }
  }

  clear(): void {
    console.warn(`${TAG} clear() is not supported by router`);
  }

  getSize(): number {
    return 0;
  }

  getBackStack(): string[] {
    return [];
  }
}

export const navHelper = NavigationHelper.getInstance();

/**
 * Page transition with Navigation
 */
export function navigateTo(page: string, param?: object): void {
  try {
    router.pushUrl({ url: page, params: param })
      .catch((err: BusinessError) => {
        console.error(`${TAG} navigateTo failed:`, err.message);
      });
  } catch (error) {
    const err = error as BusinessError;
    console.error(`${TAG} navigateTo error:`, err.message);
  }
}

export function goBack(): void {
  try {
    router.back();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`${TAG} goBack failed:`, err.message);
  }
}

export function clearAndNavigate(page: string, param?: object): void {
  try {
    router.pushUrl({ url: page, params: param })
      .catch((err: BusinessError) => {
        console.error(`${TAG} clearAndNavigate failed:`, err.message);
      });
  } catch (error) {
    const err = error as BusinessError;
    console.error(`${TAG} clearAndNavigate error:`, err.message);
  }
}
