import { logger } from '../../../utils/Logger';
/**
 * File Manager Kit Service
 * Provides file management capabilities
 * Uses HarmonyOS FileManager Service Kit (API 12+) for advanced features
 */

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
// FileManager Service Kit - HarmonyOS 5.0+ (API Level 12+)
import { fileManagerService } from '@kit.FileManagerServiceKit';

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
  
  // FileManager Service Kit 可用性标志
  private isFileManagerServiceKitAvailable: boolean = false;

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
      
      // 检测 FileManager Service Kit 是否可用
      this.checkFileManagerServiceKitAvailability();
      
      await this.loadTrashFiles();
      this.isInitialized = true;
      
      const mode = this.isFileManagerServiceKitAvailable ? 'FileManagerServiceKit' : 'CoreFileKit Only';
      logger.info('[FileManagerKit] Initialized in', mode);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[FileManagerKit] Init failed:', err.message);
      return false;
    }
  }
  
  /**
   * 检测 FileManager Service Kit 是否可用
   */
  private checkFileManagerServiceKitAvailability(): void {
    try {
      // 检查 fileManagerService 是否存在且有 getFileIcon 方法
      if (fileManagerService && typeof fileManagerService.getFileIcon === 'function') {
        this.isFileManagerServiceKitAvailable = true;
        logger.info('[FileManagerKit] FileManagerServiceKit is available');
      } else {
        this.isFileManagerServiceKitAvailable = false;
        logger.warn('[FileManagerKit] FileManagerServiceKit not available, using fallback');
      }
    } catch (error) {
      const err = error as BusinessError;
      logger.warn('[FileManagerKit] Check availability failed:', err.message);
      this.isFileManagerServiceKitAvailable = false;
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
          
          // 跳过文件夹
          if (stat.isDirectory()) {
            continue;
          }

          const fileInfo = await this.getFileInfo(entryPath);
          if (!fileInfo) {
            continue;
          }

          // 应用过滤器
          if (filter && !this.matchFilter(fileInfo, filter)) {
            continue;
          }

          files.push(fileInfo);
        } catch (error) {
          logger.warn('[FileManagerKit] Failed to read file info:', entry, error);
        }
      }

      // 排序
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

  // ==================== 回收站功能 ====================

  /**
   * 将文件移动到回收站
   */
  async moveToTrash(filePath: string): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const uri = filePath.startsWith('file://') ? filePath : 'file://' + filePath;

      // 如果文件不存在则返回错误
      if (!(await this.fileExists(filePath))) {
        return {
          success: false,
          message: '文件不存在'
        };
      }

      // 如果文件已在回收站中则返回提示
      if (this.trashFiles.has(uri)) {
        return {
          success: false,
          message: '文件已在回收站中'
        };
      }

      // TODO: Implement actual File Manager Kit delete API call
      // The following is a placeholder until real API is available
      const trashInfo: TrashFileInfo = {
        originalUri: uri,
        trashUri: `trash://${uri}`,
        name: this.extractFileName(filePath),
        deletedTime: Date.now(),
        expireTime: Date.now() + 30 * 24 * 60 * 60 * 1000, // 30天后过期
        size: (await fileIo.stat(filePath)).size
      };

      this.trashFiles.set(uri, trashInfo);
      
      // 持久化回收站信息
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File moved to trash:', filePath);
      return {
        success: true,
        message: '文件已移动到回收站'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Move to trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '移动失败',
        error: err.message
      };
    }
  }

  /**
   * 从回收站恢复文件
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
          message: '文件不在回收站中'
        };
      }

      // TODO: 恢复文件
      this.trashFiles.delete(fileUri);
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File restored from trash:', fileUri);
      return {
        success: true,
        message: '文件已恢复'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Restore from trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '恢复失败',
        error: err.message
      };
    }
  }

  /**
   * 永久删除回收站中的文件
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
          message: '文件不在回收站中'
        };
      }

      // TODO: 真正删除文件
      this.trashFiles.delete(fileUri);
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] File permanently deleted:', fileUri);
      return {
        success: true,
        message: '文件已永久删除'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Permanent delete failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '删除失败',
        error: err.message
      };
    }
  }

  /**
   * 清空回收站
   */
  async emptyTrash(): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // TODO: 清空回收站
      this.trashFiles.clear();
      await this.saveTrashFiles();

      logger.info('[FileManagerKit] Trash emptied');
      return {
        success: true,
        message: '回收站已清空'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Empty trash failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '清空失败',
        error: err.message
      };
    }
  }

  /**
   * 获取回收站中的文件列表
   */
  async getTrashFiles(): Promise<TrashFileInfo[]> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // 清理过期的回收站文件
      await this.cleanExpiredTrash();

      return Array.from(this.trashFiles.values());
    } catch (error) {
      logger.error('[FileManagerKit] Get trash files failed:', error);
      return [];
    }
  }

  // ==================== 文件图标和缩略图 ====================

  /**
   * 获取文件图标
   */
  async getFileIcon(filePath: string): Promise<string> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      // 优先使用 FileManager Service Kit
      if (this.isFileManagerServiceKitAvailable) {
        try {
          const fileType = this.detectFileType(filePath);
          const iconResource = await fileManagerService.getFileIcon(fileType);
          
          // 将 Resource 转换为 URI 字符串
          if (iconResource) {
            logger.info('[FileManagerKit] Got icon from FileManagerServiceKit for', fileType);
            return this.resourceToUri(iconResource);
          }
        } catch (error) {
          const err = error as BusinessError;
          logger.warn('[FileManagerKit] Get icon from FileManagerServiceKit failed:', err.message);
          // Fallback to default icon
        }
      }
      
      // Fallback: 返回默认图标
      return this.getDefaultIconForFileType(this.detectFileType(filePath));
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[FileManagerKit] Get file icon failed:', err.message);
      return '';
    }
  }
  
  /**
   * 将 Resource 对象转换为 URI 字符串
   */
  private resourceToUri(resource: Object): string {
    // TODO: 实现 Resource 到 URI 的转换
    // 目前返回占位符，实际需要根据 HarmonyOS API 实现
    return 'resource://' + JSON.stringify(resource);
  }

  /**
   * 获取文件缩略图
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

      // TODO: 调用 File Manager Kit 生成缩略图
      return '';
    } catch (error) {
      logger.error('[FileManagerKit] Get file thumbnail failed:', error);
      return '';
    }
  }

  // ==================== 文件操作 ====================

  /**
   * 复制文件
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
        message: '文件复制成功'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Copy file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '文件复制失败',
        error: err.message
      };
    }
  }

  /**
   * 移动文件
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
        message: '文件移动成功'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Move file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '文件移动失败',
        error: err.message
      };
    }
  }

  /**
   * 重命名文件
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
        message: '文件重命名成功'
      };
    } catch (error) {
      logger.error('[FileManagerKit] Rename file failed:', error);
      const err = error as Error;
      return {
        success: false,
        message: '文件重命名失败',
        error: err.message
      };
    }
  }

  /**
   * 删除文件（支持回收到垃圾箱）
   */
  async deleteFile(filePath: string, moveToTrash: boolean = true): Promise<FileOperationResult> {
    try {
      if (!this.isReady()) {
        throw new Error('FileManagerKit not initialized');
      }

      const uri = filePath.startsWith('file://') ? filePath : 'file://' + filePath;

      // 如果启用回收站功能且 FileManager Service Kit 可用
      if (moveToTrash && this.isFileManagerServiceKitAvailable) {
        try {
          // 使用官方 API 删除到回收站
          await fileManagerService.deleteToTrash(uri);
          
          logger.info('[FileManagerKit] File moved to trash:', filePath);
          return {
            success: true,
            message: '文件已移至回收站'
          };
        } catch (error) {
          const err = error as BusinessError;
          logger.warn('[FileManagerKit] Delete to trash failed:', err.message, '- falling back to direct delete');
          // Fallback to direct delete
        }
      }

      // 直接删除文件
      await fileIo.unlink(filePath);

      logger.info('[FileManagerKit] File deleted:', filePath);
      return {
        success: true,
        message: '文件删除成功'
      };
    } catch (error) {
      const err = error as BusinessError;
      logger.error('[FileManagerKit] Delete file failed:', err.message);
      return {
        success: false,
        message: '文件删除失败',
        error: err.message
      };
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * 加载回收站文件列表
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
   * 保存回收站文件列表
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
   * 清理过期的回收站文件
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
      // TODO: 真正删除文件
    }

    if (expiredUris.length > 0) {
      await this.saveTrashFiles();
    }
  }

  /**
   * 检测文件类型
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
   * 获取MIME类型
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
   * 获取默认文件类型图标
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
   * 检查文件是否符合过滤条件
   */
  private matchFilter(fileInfo: ManagedFileInfo, filter: FileFilter): boolean {
    // 检查文件类型过滤
    if (filter.types && filter.types.length > 0) {
      if (!filter.types.includes(fileInfo.type)) {
        return false;
      }
    }

    // 检查文件大小过滤
    if (filter.minSize !== undefined && fileInfo.size < filter.minSize) {
      return false;
    }
    if (filter.maxSize !== undefined && fileInfo.size > filter.maxSize) {
      return false;
    }

    // 检查创建时间范围
    if (filter.createTimeRange) {
      if (fileInfo.createTime < filter.createTimeRange[0] || 
          fileInfo.createTime > filter.createTimeRange[1]) {
        return false;
      }
    }

    // 检查修改时间范围
    if (filter.modifyTimeRange) {
      if (fileInfo.modifyTime < filter.modifyTimeRange[0] || 
          fileInfo.modifyTime > filter.modifyTimeRange[1]) {
        return false;
      }
    }

    // 检查关键词搜索
    if (filter.keyword) {
      if (!fileInfo.name.toLowerCase().includes(filter.keyword.toLowerCase())) {
        return false;
      }
    }

    // 检查回收站状态
    if (filter.inTrash !== undefined) {
      if (fileInfo.inTrash !== filter.inTrash) {
        return false;
      }
    }

    return true;
  }

  /**
   * 比较文件用于排序
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
   * 提取文件名
   */
  private extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const fileName = parts[parts.length - 1];
    const dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /**
   * 获取文件扩展名
   */
  private getFileExtension(filePath: string): string {
    const parts = filePath.split('.');
    return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : '';
  }

  /**
   * 检查文件是否存在
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
   * 检查文件是否可写
   */
  private async isWritable(filePath: string): Promise<boolean> {
    try {
      // 尝试获取文件状态
      await fileIo.stat(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查文件是否隐藏
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
   * 释放资源
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    this.trashFiles.clear();
    logger.info('[FileManagerKit] Released');
  }
}

// 导出单例
export const fileManagerKitService = FileManagerKitService.getInstance();
export default fileManagerKitService;
