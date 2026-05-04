import { logger } from '../../../utils/Logger';
/**
 * File Manager Kit Service
 * Provides file management capabilities
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export enum FileType {
  PDF = 'pdf',
  EPUB = 'epub',
  MOBI = 'mobi',
  TXT = 'txt',
  DOCX = 'docx',
  CBZ = 'cbz',
  CBR = 'cbr',
  IMAGE = 'image',
  AUDIO = 'audio',
  VIDEO = 'video',
  OTHER = 'other'
}

export interface ManagedFileInfo {
  uri: string;
  name: string;
  path: string;
  size: number;
  type: FileType;
  mimeType: string;
  iconUri?: string;
  thumbnailUri?: string;
  createTime: number;
  modifyTime: number;
  inTrash: boolean;
  trashTime?: number;
  isReadOnly: boolean;
  isHidden: boolean;
}

export interface TrashFileInfo {
  originalUri: string;
  trashUri: string;
  name: string;
  deletedTime: number;
  expireTime: number;
  size: number;
}

export interface FileFilter {
  types?: FileType[];
  minSize?: number;
  maxSize?: number;
  createTimeRange?: [number, number];
  modifyTimeRange?: [number, number];
  keyword?: string;
  inTrash?: boolean;
}

export interface FileSortOptions {
  sortBy: 'name' | 'size' | 'createTime' | 'modifyTime' | 'type';
  descending: boolean;
}

export interface FileOperationResult {
  success: boolean;
  message: string;
  error?: string;
}

export interface FolderInfo {
  uri: string;
  name: string;
  fileCount: number;
  folderCount: number;
  totalSize: number;
  modifyTime: number;
}


class FileManagerKitService {
  private static instance: FileManagerKitService;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private trashFiles: Map<string, TrashFileInfo> = new Map();
  private appFilesDir: string = '';

  private constructor() {}

  static getInstance(): FileManagerKitService {
    if (!FileManagerKitService.instance) {
      FileManagerKitService.instance = new FileManagerKitService();
    }
    return FileManagerKitService.instance;
  }

  async init(context: common.Context): Promise<boolean> {
    try {
      logger.info('[FileManagerKit] Initializing...');
      this.context = context;
      const filesDir = context.filesDir;
      this.appFilesDir = filesDir;
      await this.loadTrashFiles();
      this.isInitialized = true;
      logger.info('FileManagerKit initialized');
      return true;
    } catch (error) {
      logger.error('Init failed:', error);
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  async getFileInfo(filePath: string): Promise<ManagedFileInfo | null> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const uri = filePath.startsWith('file://') ? filePath : 'file://' + filePath;
      const stat = await fileIo.stat(filePath);

      const fileInfo: ManagedFileInfo = {
        uri: uri,
        name: this.extractFileName(filePath),
        path: filePath,
        size: stat.size,
        type: this.detectFileType(filePath),
        mimeType: this.getMimeType(filePath),
        iconUri: '',
        createTime: stat.mtime,
        modifyTime: stat.mtime,
        inTrash: this.trashFiles.has(uri),
        isReadOnly: !(await this.isWritable(filePath)),
        isHidden: this.isHidden(filePath)
      };

      return fileInfo;
    } catch (error) {
      logger.error('GetFileInfo failed:', error);
      return null;
    }
  }

  async getFolderInfo(folderPath: string): Promise<FolderInfo | null> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const entries = await fileIo.listFile(folderPath);
      let fileCount = 0;
      let folderCount = 0;
      let totalSize = 0;

      for (const entry of entries) {
        const entryPath = `${folderPath}/${entry}`;
        const stat = await fileIo.stat(entryPath);
        
        if (stat.isDirectory()) {
          folderCount++;
        } else {
          fileCount++;
          totalSize += stat.size;
        }
      }

      const folderInfo: FolderInfo = {
        uri: 'file://' + folderPath,
        name: this.extractFileName(folderPath),
        fileCount: fileCount,
        folderCount: folderCount,
        totalSize: totalSize,
        modifyTime: (await fileIo.stat(folderPath)).mtime
      };

      return folderInfo;
    } catch (error) {
      logger.error('[FileManagerKit] Get folder info failed:', error);
      return null;
    }
  }

  async listFiles(
    folderPath: string, 
    filter?: FileFilter, 
    sort?: FileSortOptions
  ): Promise<ManagedFileInfo[]> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const entries = await fileIo.listFile(folderPath);
      const files: ManagedFileInfo[] = [];

      for (const entry of entries) {
        const entryPath = `${folderPath}/${entry}`;

        try {
          const stat = await fileIo.stat(entryPath);
          
          // 鐠哄疇绻冮惄顔肩秿
          if (stat.isDirectory()) {
            continue;
          }

          const fileInfo = await this.getFileInfo(entryPath);
          if (!fileInfo) {
            continue;
          }

          // 鎼存梻鏁ゆ潻鍥ㄦ姢閸?
          if (filter && !this.matchFilter(fileInfo, filter)) {
            continue;
          }

          files.push(fileInfo);
        } catch (error) {
          logger.warn('[FileManagerKit] Failed to read file info:', entry, error);
        }
      }

      // 閹烘帒绨?
      if (sort) {
        const sortedFiles = files.slice().sort((a, b) => this.compareFiles(a, b, sort!));
        return sortedFiles;
      }

      return files;
    } catch (error) {
      logger.error('[FileManagerKit] List files failed:', error);
      return [];
    }
  }

  // ==================== 閸ョ偞鏁圭粩娆忓�閼?====================

  /**
   * 缁夎�濮╅弬鍥︽�閸掓澘娲栭弨鍓佺彲
   */
  async moveToTrash(filePath: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const uri = filePath.startsWith('file://') ? filePath : 'file://' + filePath;

      // 濡�偓閺屻儲鏋冩禒鑸垫Ц閸氾箑鐡ㄩ崷?
      if (!(await this.fileExists(filePath))) {
        return {
          success: false,
          message: '鏂囦欢涓嶅瓨鍦?
        };
      }

      // 濡�偓閺屻儲妲搁崥锕€鍑￠崷銊ユ礀閺€鍓佺彲
      if (this.trashFiles.has(uri)) {
        return {
          success: false,
          message: '閺傚洣娆㈠�鎻掓躬閸ョ偞鏁圭粩娆庤厬'
        };
      }

      // TODO: 闂嗗棙鍨?File Manager Kit 閻ㄥ嫬娲栭弨鍓佺彲閸旂喕鍏?
      // 瑜版挸澧犳担璺ㄦ暏濡�剝瀚欑€圭偟骞?
      const trashInfo: TrashFileInfo = {
        originalUri: uri,
        trashUri: `trash://${uri}`,
        name: this.extractFileName(filePath),
        deletedTime: Date.now(),
        expireTime: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30婢垛晛鎮楁潻鍥ㄦ埂
        size: (await fileIo.stat(filePath)).size
      };

      this.trashFiles.set(uri, trashInfo);
      
      // 娣囨繂鐡ㄩ崶鐐存暪缁旀瑥鍨�悰?
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File moved to trash:', filePath);
      return {
        success: true,
        message: '鏂囦欢宸茬Щ鍔ㄥ埌鍥炴敹绔?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Move to trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '缁夎�濮╂径杈�Е',
        error: err.message
      };
    }
  }

  /**
   * 娴犲骸娲栭弨鍓佺彲閹�垹顦查弬鍥︽�
   */
  async restoreFromTrash(fileUri: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const trashInfo = this.trashFiles.get(fileUri);
      if (!trashInfo) {
        return {
          success: false,
          message: '閺傚洣娆㈡稉宥呮躬閸ョ偞鏁圭粩娆庤厬'
        };
      }

      // TODO: 閹�垹顦查弬鍥︽�
      this.trashFiles.delete(fileUri);
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File restored from trash:', fileUri);
      return {
        success: true,
        message: '鏂囦欢宸叉仮澶?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Restore from trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '閹�垹顦叉径杈�Е',
        error: err.message
      };
    }
  }

  /**
   * 濮橀晲绠欓崚鐘绘珟閺傚洣娆?
   */
  async permanentDelete(fileUri: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const trashInfo = this.trashFiles.get(fileUri);
      if (!trashInfo) {
        return {
          success: false,
          message: '閺傚洣娆㈡稉宥呮躬閸ョ偞鏁圭粩娆庤厬'
        };
      }

      // TODO: 鐎圭偤妾�崚鐘绘珟閺傚洣娆?
      this.trashFiles.delete(fileUri);
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File permanently deleted:', fileUri);
      return {
        success: true,
        message: '鏂囦欢宸叉案涔呭垹闄?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Permanent delete failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '鍒犻櫎澶辫触',
        error: err.message
      };
    }
  }

  /**
   * 濞撳懐鈹栭崶鐐存暪缁?
   */
  async emptyTrash(): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // TODO: 濞撳懐鈹栭崶鐐存暪缁?
      this.trashFiles.clear();
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] Trash emptied');
      return {
        success: true,
        message: '閸ョ偞鏁圭粩娆忓嚒濞撳懐鈹?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Empty trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '娓呯┖澶辫触',
        error: err.message
      };
    }
  }

  /**
   * 閼惧嘲褰囬崶鐐存暪缁旀瑦鏋冩禒璺哄灙鐞?
   */
  async getTrashFiles(): Promise<TrashFileInfo[]> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // 濞撳懐鎮婃潻鍥ㄦ埂閺傚洣娆?
      await this.cleanExpiredTrash();

      return Array.from(this.trashFiles.values());
    } catch (error) {
      logger.error('[FileManagerKit] Get trash files failed:', error);
      return [];
    }
  }

  // ==================== 閺傚洣娆㈤崶鐐�垼 ====================

  /**
   * 閼惧嘲褰囬弬鍥︽�閸ョ偓鐖?
   */
  async getFileIcon(filePath: string): Promise<string> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // TODO: 闂嗗棙鍨?File Manager Kit 閻ㄥ嫬娴橀弽鍥�箯閸欐牞鍏橀崝?
      // const fileManager = fileManager.FileManagerService.getInstance();
      // return await fileManager.getFileIcon(filePath);
      
      // 瑜版挸澧犳潻鏂挎礀姒涙ǹ顓婚崶鐐�垼
      return this.getDefaultIconForFileType(this.detectFileType(filePath));
    } catch (error) {
      logger.error('[FileManagerKit] Get file icon failed:', error);
      return '';
    }
  }

  /**
   * 閼惧嘲褰囬弬鍥︽�缂傗晝鏆愰崶?
   */
  async getFileThumbnail(
    filePath: string, 
    width: number = 200, 
    height: number = 280
  ): Promise<string> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // TODO: 闂嗗棙鍨?File Manager Kit 閻ㄥ嫮缂夐悾銉ユ禈閻㈢喐鍨?
      return '';
    } catch (error) {
      logger.error('[FileManagerKit] Get file thumbnail failed:', error);
      return '';
    }
  }

  // ==================== 閺傚洣娆㈤幙宥勭稊 ====================

  /**
   * 婢跺秴鍩楅弬鍥︽�
   */
  async copyFile(sourcePath: string, destPath: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      await fileIo.copyFile(sourcePath, destPath);

      logger.info('[FileManagerKit] File copied:', sourcePath, '->', destPath);
      return {
        success: true,
        message: '閺傚洣娆㈡径宥呭煑閹存劕濮?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Copy file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '鏂囦欢澶嶅埗澶辫触',
        error: err.message
      };
    }
  }

  /**
   * 缁夎�濮╅弬鍥︽�
   */
  async moveFile(sourcePath: string, destPath: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      await fileIo.rename(sourcePath, destPath);

      logger.info('[FileManagerKit] File moved:', sourcePath, '->', destPath);
      return {
        success: true,
        message: '閺傚洣娆㈢粔璇插З閹存劕濮?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Move file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '鏂囦欢绉诲姩澶辫触',
        error: err.message
      };
    }
  }

  /**
   * 闁插秴鎳￠崥宥嗘瀮娴?
   */
  async renameFile(filePath: string, newName: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
      const newPath = `${dirPath}/${newName}`;

      await fileIo.rename(filePath, newPath);

      logger.info('[FileManagerKit] File renamed:', filePath, '->', newPath);
      return {
        success: true,
        message: '鏂囦欢閲嶅懡鍚嶆垚鍔?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Rename file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '鏂囦欢閲嶅懡鍚嶅け璐?,
        error: err.message
      };
    }
  }

  /**
   * 閸掔娀娅庨弬鍥︽�
   */
  async deleteFile(filePath: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      await fileIo.unlink(filePath);

      logger.info('[FileManagerKit] File deleted:', filePath);
      return {
        success: true,
        message: '閺傚洣娆㈤崚鐘绘珟閹存劕濮?
      };
    } catch (error) {
      logger.error('[FileManagerKit] Delete file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '鏂囦欢鍒犻櫎澶辫触',
        error: err.message
      };
    }
  }

  // ==================== 鏉堝懎濮�弬瑙勭《 ====================

  /**
   * 閸旂姾娴囬崶鐐存暪缁旀瑥鍨�悰?
   */
  private async loadTrashFiles(): Promise<void> {
    try {
      const trashPath = `${this.appFilesDir}/trash.json`;
      if (await this.fileExists(trashPath)) {
        const content = await fileIo.readText(trashPath);
        const trashArray = JSON.parse(content) as Array<TrashFileInfo>;
        
        this.trashFiles.clear();
        for (const trashInfo of trashArray) {
          this.trashFiles.set(trashInfo.originalUri, trashInfo);
        }
        
        logger.info('[FileManagerKit] Loaded', this.trashFiles.size, 'trash files');
      }
    } catch (error) {
      logger.warn('[FileManagerKit] Load trash files failed:', error);
    }
  }

  /**
   * 娣囨繂鐡ㄩ崶鐐存暪缁旀瑥鍨�悰?
   */
  private async saveTrashFiles(): Promise<void> {
    try {
      const trashPath = `${this.appFilesDir}/trash.json`;
      const trashArray = Array.from(this.trashFiles.values());
      const content = JSON.stringify(trashArray, null, 2);

      await this.writeText(trashPath, content);
    } catch (error) {
      logger.error('[FileManagerKit] Save trash files failed:', error);
    }
  }

  /**
   * 濞撳懐鎮婃潻鍥ㄦ埂閻ㄥ嫬娲栭弨鍓佺彲閺傚洣娆?
   */
  private async cleanExpiredTrash(): Promise<void> {
    const now = Date.now();
    const expiredUris: string[] = [];

    const entries = Array.from(this.trashFiles.entries());
    for (let i = 0; i < entries.length; i++) {
      const uri = entries[i][0];
      const trashInfo = entries[i][1];
      if (trashInfo.expireTime < now) {
        expiredUris.push(uri);
      }
    }

    for (const uri of expiredUris) {
      this.trashFiles.delete(uri);
      // TODO: 鐎圭偤妾�崚鐘绘珟閺傚洣娆?
    }

    if (expiredUris.length > 0) {
      await this.saveTrashFiles();
    }
  }

  /**
   * 濡�偓濞村�鏋冩禒鍓佽�閸?
   */
  private detectFileType(filePath: string): FileType {
    const ext = this.getFileExtension(filePath).toLowerCase();
    
    switch (ext) {
      case 'pdf':
        return FileType.PDF;
      case 'epub':
        return FileType.EPUB;
      case 'mobi':
        return FileType.MOBI;
      case 'txt':
        return FileType.TXT;
      case 'docx':
        return FileType.DOCX;
      case 'cbz':
        return FileType.CBZ;
      case 'cbr':
        return FileType.CBR;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.IMAGE;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return FileType.AUDIO;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return FileType.VIDEO;
      default:
        return FileType.OTHER;
    }
  }

  /**
   * 閼惧嘲褰嘙IME缁��鐎?
   */
  private getMimeType(filePath: string): string {
    const ext = this.getFileExtension(filePath).toLowerCase();
    
    const mimeMap: Record<string, string> = {
      'pdf': 'application/pdf',
      'epub': 'application/epub+zip',
      'mobi': 'application/x-mobipocket-ebook',
      'txt': 'text/plain',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'cbz': 'application/zip',
      'cbr': 'application/x-rar-compressed',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4'
    };

    return mimeMap[ext] || 'application/octet-stream';
  }

  /**
   * 閼惧嘲褰囨�妯款吇閸ョ偓鐖?
   */
  private getDefaultIconForFileType(fileType: FileType): string {
    switch (fileType) {
      case FileType.PDF:
        return 'media:icon_pdf';
      case FileType.EPUB:
        return 'media:icon_epub';
      case FileType.MOBI:
        return 'media:icon_mobi';
      case FileType.TXT:
        return 'media:icon_txt';
      case FileType.DOCX:
        return 'media:icon_docx';
      case FileType.CBZ:
      case FileType.CBR:
        return 'media:icon_comic';
      case FileType.IMAGE:
        return 'media:icon_image';
      case FileType.AUDIO:
        return 'media:icon_audio';
      case FileType.VIDEO:
        return 'media:icon_video';
      default:
        return 'media:icon_file';
    }
  }

  /**
   * 閺傚洣娆㈤崠褰掑帳鏉╁洦鎶ら崳?
   */
  private matchFilter(fileInfo: ManagedFileInfo, filter: FileFilter): boolean {
    // 閺傚洣娆㈢猾璇茬€锋潻鍥ㄦ姢
    if (filter.types && filter.types.length > 0) {
      if (!filter.types.includes(fileInfo.type)) {
        return false;
      }
    }

    // 閺傚洣娆㈡径褍鐨�潻鍥ㄦ姢
    if (filter.minSize !== undefined && fileInfo.size < filter.minSize) {
      return false;
    }
    if (filter.maxSize !== undefined && fileInfo.size > filter.maxSize) {
      return false;
    }

    // 閸掓稑缂撻弮鍫曟？鏉╁洦鎶?
    if (filter.createTimeRange) {
      if (fileInfo.createTime < filter.createTimeRange[0] || 
          fileInfo.createTime > filter.createTimeRange[1]) {
        return false;
      }
    }

    // 娣囶喗鏁奸弮鍫曟？鏉╁洦鎶?
    if (filter.modifyTimeRange) {
      if (fileInfo.modifyTime < filter.modifyTimeRange[0] || 
          fileInfo.modifyTime > filter.modifyTimeRange[1]) {
        return false;
      }
    }

    // 閸忔娊鏁�€涙�绻冨⿰?
    if (filter.keyword) {
      if (!fileInfo.name.toLowerCase().includes(filter.keyword.toLowerCase())) {
        return false;
      }
    }

    // 閸ョ偞鏁圭粩娆掔箖濠?
    if (filter.inTrash !== undefined) {
      if (fileInfo.inTrash !== filter.inTrash) {
        return false;
      }
    }

    return true;
  }

  /**
   * 閺傚洣娆㈠В鏃囩窛
   */
  private compareFiles(
    a: ManagedFileInfo, 
    b: ManagedFileInfo, 
    sort: FileSortOptions
  ): number {
    let result = 0;

    switch (sort.sortBy) {
      case 'name':
        result = a.name.localeCompare(b.name);
        break;
      case 'size':
        result = a.size - b.size;
        break;
      case 'createTime':
        result = a.createTime - b.createTime;
        break;
      case 'modifyTime':
        result = a.modifyTime - b.modifyTime;
        break;
      case 'type':
        result = a.type.localeCompare(b.type);
        break;
    }

    return sort.descending ? -result : result;
  }

  /**
   * 閹绘劕褰囬弬鍥︽�閸?
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const fileName = parts[parts.length - 1];
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /**
   * 閼惧嘲褰囬弬鍥︽�閹碘晛鐫嶉崥?
   */
  private getFileExtension(filePath: string): string {
    const parts = filePath.split('.');
    return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : '';
  }

  /**
   * 濡�偓閺屻儲鏋冩禒鑸垫Ц閸氾箑鐡ㄩ崷?
   */
  private async fileExists(filePath: string): Promise<boolean> {
    try {
      await fileIo.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 濡�偓閺屻儲鏋冩禒鑸垫Ц閸氾箑褰查崘?
   */
  private async isWritable(filePath: string): Promise<boolean> {
    try {
      // 鐏忔繆鐦�懢宄板絿閺傚洣娆㈤悩鑸碘偓?
      await fileIo.stat(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 濡�偓閺屻儲鏋冩禒鑸垫Ц閸氾箓娈ｉ挊?
   */
  private isHidden(filePath: string): boolean {
    const fileName = this.extractFileName(filePath);
    return fileName.startsWith('.');
  }

  private async writeText(filePath: string, content: string): Promise<void> {
    try {
      const fd = await fileIo.open(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        const encoder = new util.TextEncoder();
        const buffer = encoder.encodeInto(content);
        await fileIo.write(fd.fd, buffer);
      } finally {
        await fileIo.close(fd);
      }
    } catch (error) {
      logger.error('[FileManagerKit] Write text failed:', error);
    }
  }

  /**
   * 闁插﹥鏂佺挧鍕�爱
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    this.trashFiles.clear();
    logger.info('[FileManagerKit] Released');
  }
}

// 鐎电厧鍤�崡鏇氱伐
export const fileManagerKitService = FileManagerKitService.getInstance();
export default fileManagerKitService;
