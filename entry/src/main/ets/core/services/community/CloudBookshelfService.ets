/**
 * Local Backup Service - Cloud Bookshelf Sync
 * 浜戠涔︽灦鍚屾鏈嶅姟
 *
 * 鎻愪緵浜戠涔︽灦澶囦唤涓庡悓姝ュ姛鑳? * 鏀寔闃呰璁板綍銆佷功绛俱€佺瑪璁扮殑浜戠鍚屾
 *
 * @since 4.0.0
 */

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { preferenceManager } from '../../utils/PreferenceManager';
import { BookInfo, Bookmark, Note, ReadRecord } from '../../models/CoreBookModel';

const DOMAIN = 0xFF05;
const BACKUP_DIR = '/data/storage/el2/base/backup/';

interface BackupData {
  books: BookInfo[];
  bookmarks: Bookmark[];
  notes: Note[];
  readRecords: ReadRecord[];
  timestamp: number;
}

interface SyncResult {
  success: boolean;
  message: string;
  data?: BackupData;
}

class CloudBookshelfService {
  private static instance: CloudBookshelfService;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private syncEnabled: boolean = false;
  private lastSyncTime: number = 0;

  private constructor() {}

  static getInstance(): CloudBookshelfService {
    if (!CloudBookshelfService.instance) {
      CloudBookshelfService.instance = new CloudBookshelfService();
    }
    return CloudBookshelfService.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    try {
      this.context = context;
      this.isInitialized = true;
      hilog.info(DOMAIN, 'CloudBookshelf', 'Service initialized');
      return true;
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'CloudBookshelf', 'Init failed: %{public}s', err?.message);
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  async backup(data: BackupData): Promise<SyncResult> {
    try {
      if (!this.isReady()) {
        return { success: false, message: 'Service not initialized' };
      }

      const backupData: BackupData = {
        books: data.books,
        bookmarks: data.bookmarks,
        notes: data.notes,
        readRecords: data.readRecords,
        timestamp: Date.now()
      };

      const encoder = new util.TextEncoder();
      const buffer = encoder.encodeInto(JSON.stringify(backupData), new ArrayBuffer(0));
      const backupPath = BACKUP_DIR + 'cloud_backup.json';

      this.ensureDirectoryExists(backupPath);
      fileIo.writeSync(backupPath, buffer);

      this.lastSyncTime = Date.now();
      hilog.info(DOMAIN, 'CloudBookshelf', 'Backup completed');

      return { success: true, message: 'Backup completed' };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'CloudBookshelf', 'Backup failed: %{public}s', err?.message);
      return { success: false, message: err?.message || 'Backup failed' };
    }
  }

  async restore(): Promise<SyncResult> {
    try {
      if (!this.isReady()) {
        return { success: false, message: 'Service not initialized' };
      }

      const backupPath = BACKUP_DIR + 'cloud_backup.json';

      if (!fileIo.accessSync(backupPath)) {
        return { success: false, message: 'No backup found' };
      }

      const content = fileIo.readTextSync(backupPath);
      const backupData: BackupData = JSON.parse(content);

      hilog.info(DOMAIN, 'CloudBookshelf', 'Restore completed');

      return {
        success: true,
        message: 'Restore completed',
        data: backupData
      };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'CloudBookshelf', 'Restore failed: %{public}s', err?.message);
      return { success: false, message: err?.message || 'Restore failed' };
    }
  }

  async sync(): Promise<SyncResult> {
    try {
      if (!this.syncEnabled) {
        return { success: false, message: 'Sync not enabled' };
      }

      const restoreResult = await this.restore();
      if (!restoreResult.success) {
        return restoreResult;
      }

      this.lastSyncTime = Date.now();
      hilog.info(DOMAIN, 'CloudBookshelf', 'Sync completed');

      return { success: true, message: 'Sync completed', data: restoreResult.data };
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'CloudBookshelf', 'Sync failed: %{public}s', err?.message);
      return { success: false, message: err?.message || 'Sync failed' };
    }
  }

  setSyncEnabled(enabled: boolean): void {
    this.syncEnabled = enabled;
    hilog.info(DOMAIN, 'CloudBookshelf', 'Sync enabled: %{public}s', enabled.toString());
  }

  getLastSyncTime(): number {
    return this.lastSyncTime;
  }

  private ensureDirectoryExists(path: string): void {
    const dir = path.substring(0, path.lastIndexOf('/'));
    if (!fileIo.accessSync(dir)) {
      fileIo.mkdirSync(dir);
    }
  }

  release(): void {
    this.isInitialized = false;
    this.context = null;
    this.syncEnabled = false;
    hilog.info(DOMAIN, 'CloudBookshelf', 'Service released');
  }
}

export const cloudBookshelfService = CloudBookshelfService.getInstance();
export default cloudBookshelfService;