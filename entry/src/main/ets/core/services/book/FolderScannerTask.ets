/**
 * 文件夹扫描 TaskPool 任务
 * 用于异步化文件扫描操作，避免阻塞主线程
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';

/**
 * 扫描配置
 */
export interface TaskScanConfig {
  scanPath: string;
  recursive: boolean;
  supportedFormats: string[];
  excludeHidden: boolean;
}

/**
 * 扫描结果文件
 */
export interface TaskScannedFile {
  filePath: string;
  fileName: string;
  fileSize: number;
  modifyTime: number;
  isDirectory: boolean;
}

/**
 * 扩展名映射
 */
const SUPPORTED_EXTENSIONS: Record<string, boolean> = {
  '.epub': true,
  '.txt': true,
  '.pdf': true,
  '.mobi': true,
  '.azw3': true,
  '.azw': true,
  '.docx': true,
  '.cbz': true,
  '.cbr': true
};

/**
 * 递归扫描目录（TaskPool 版本）
 * @Concurrent 装饰器使函数可在后台线程执行
 */
@Concurrent
export function scanDirectoryTask(config: TaskScanConfig): TaskScannedFile[] {
  const results: TaskScannedFile[] = [];
  scanRecursive(config, config.scanPath, results);
  return results;
}

/**
 * 递归扫描实现
 */
function scanRecursive(config: TaskScanConfig, currentPath: string, results: TaskScannedFile[]): void {
  try {
    const entries = fileIo.listFileSync(currentPath);

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const entryPath = currentPath + '/' + entry;

      try {
        const stat = fileIo.statSync(entryPath);

        // 跳过隐藏文件
        if (config.excludeHidden && entry.startsWith('.')) {
          continue;
        }

        // 递归扫描子文件夹
        if (stat.isDirectory() && config.recursive) {
          scanRecursive(config, entryPath, results);
        }

        // 检查文件
        if (stat.isFile()) {
          const ext = entry.substring(entry.lastIndexOf('.')).toLowerCase();
          if (SUPPORTED_EXTENSIONS[ext] || config.supportedFormats.includes(ext)) {
            const fileResult: TaskScannedFile = {
              filePath: entryPath,
              fileName: entry,
              fileSize: stat.size,
              modifyTime: stat.mtime,
              isDirectory: false
            };
            results.push(fileResult);
          }
        }
      } catch (error) {
        // 忽略单个文件错误，继续扫描其他文件
      }
    }
  } catch (error) {
    // 忽略目录错误
  }
}

/**
 * 统计文件数量（预扫描）
 */
@Concurrent
export function countFilesTask(config: TaskScanConfig): number {
  return countFilesRecursive(config, config.scanPath);
}

/**
 * 递归计数实现
 */
function countFilesRecursive(config: TaskScanConfig, currentPath: string): number {
  let count: number = 0;

  try {
    const entries = fileIo.listFileSync(currentPath);

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const entryPath = currentPath + '/' + entry;

      try {
        const stat = fileIo.statSync(entryPath);

        if (config.excludeHidden && entry.startsWith('.')) {
          continue;
        }

        if (stat.isDirectory() && config.recursive) {
          count += countFilesRecursive(config, entryPath);
        }

        if (stat.isFile()) {
          const ext = entry.substring(entry.lastIndexOf('.')).toLowerCase();
          if (SUPPORTED_EXTENSIONS[ext] || config.supportedFormats.includes(ext)) {
            count++;
          }
        }
      } catch (error) {
        // 忽略
      }
    }
  } catch (error) {
    // 忽略
  }

  return count;
}
