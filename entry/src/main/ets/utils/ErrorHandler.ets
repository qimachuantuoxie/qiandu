import { toast } from './ToastHelper';

export enum ErrorLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4
}

export interface ErrorInfo {
  code: string;
  message: string;
  level: ErrorLevel;
  timestamp: number;
  stack?: string;
}

export interface ErrorHandlerOptions {
  showToast?: boolean;
  logConsole?: boolean;
  level?: ErrorLevel;
}

export class ErrorHandler {
  private static instance: ErrorHandler | null = null;
  private errorListeners: ((info: ErrorInfo) => void)[] = [];

  static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  handle(error: Error | string, options: ErrorHandlerOptions = {}): ErrorInfo {
    let showToast = false;
    let logConsole = true;
    let level = ErrorLevel.ERROR;

    if (options.showToast !== undefined) {
      showToast = options.showToast;
    }
    if (options.logConsole !== undefined) {
      logConsole = options.logConsole;
    }
    if (options.level !== undefined) {
      level = options.level;
    }

    const errorInfo: ErrorInfo = {
      code: 'UNKNOWN',
      message: typeof error === 'string' ? error : error.message,
      level,
      timestamp: Date.now()
    };

    if (error instanceof Error) {
      errorInfo.code = this.getErrorCode(error);
      errorInfo.stack = error.stack;
    }

    if (logConsole) {
      this.log(errorInfo);
    }

    if (showToast) {
      toast(errorInfo.message);
    }

    this.notifyListeners(errorInfo);

    return errorInfo;
  }

  handleAsync<T>(
    promise: Promise<T>,
    options: ErrorHandlerOptions = {}
  ): Promise<T> {
    return promise.catch((error: Error) => {
      this.handle(error, options);
      throw error instanceof Error ? error : new Error(String(error));
    });
  }

  tryCatch<T>(
    fn: () => T,
    options: ErrorHandlerOptions = {}
  ): T | undefined {
    try {
      return fn();
    } catch (error) {
      this.handle(error, options);
      return undefined;
    }
  }

  async tryCatchAsync<T>(
    fn: () => Promise<T>,
    options: ErrorHandlerOptions = {}
  ): Promise<T | undefined> {
    try {
      return await fn();
    } catch (error) {
      this.handle(error, options);
      return undefined;
    }
  }

  private getErrorCode(error: Error): string {
    const name = error.constructor.name;
    const codeMap = new Map<string, string>([
      ['RangeError', 'RANGE_ERROR'],
      ['TypeError', 'TYPE_ERROR'],
      ['ReferenceError', 'REFERENCE_ERROR'],
      ['SyntaxError', 'SYNTAX_ERROR'],
      ['URIError', 'URI_ERROR'],
      ['EvalError', 'EVAL_ERROR']
    ]);
    return codeMap.get(name) || 'UNKNOWN_ERROR';
  }

  private log(info: ErrorInfo): void {
    const levelNames = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'];
    const prefix = `[${levelNames[info.level]}]`;
    console.error(`${prefix} [${info.code}] ${info.message}`);
    if (info.stack) {
      console.error(info.stack);
    }
  }

  addListener(listener: (info: ErrorInfo) => void): void {
    this.errorListeners.push(listener);
  }

  removeListener(listener: (info: ErrorInfo) => void): void {
    const index = this.errorListeners.indexOf(listener);
    if (index > -1) {
      this.errorListeners.splice(index, 1);
    }
  }

  private notifyListeners(info: ErrorInfo): void {
    this.errorListeners.forEach((listener) => {
      try {
        listener(info);
      } catch (e) {
        console.error('[ErrorHandler] Listener error:', e);
      }
    });
  }
}

export const errorHandler = ErrorHandler.getInstance();

export function handleError(
  error: Error | string,
  options?: ErrorHandlerOptions
): ErrorInfo {
  return errorHandler.handle(error, options);
}

export function tryCatch<T>(
  fn: () => T,
  options?: ErrorHandlerOptions
): T | undefined {
  return errorHandler.tryCatch(fn, options);
}

export async function tryCatchAsync<T>(
  fn: () => Promise<T>,
  options?: ErrorHandlerOptions
): Promise<T | undefined> {
  return errorHandler.tryCatchAsync(fn, options);
}

