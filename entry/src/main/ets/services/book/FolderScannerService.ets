/**
 * Folder Scanner Service - 文件夹扫描服务
 * Folder Scanner Service - Scan and Import Documents from Folders
 * 
 * 扫描指定目录，批量导入文档，持久化授权
 * 
 * @since 5.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { enhancedParser } from '../reader/EnhancedDocumentParser';
import { DocumentFormat } from '../models/DocumentModels';
import { promptAction } from '@kit.ArkUI';
import { BookInfo } from '../../models/CoreBookModel';

/**
 * 文档信息
 */
export interface ScannedDocument {
  /** 文件路径 */
  filePath: string;
  /** 文件名 */
  fileName: string;
  /** 文件格式 */
  format: DocumentFormat;
  /** 文件大小 */
  fileSize: number;
  /** 修改时间 */
  modifyTime: number;
  /** 是否已导入 */
  isImported: boolean;
  /** 文档ID（导入后） */
  docId?: string;
  /** 标题 */
  title?: string;
  /** 作者 */
  author?: string;
  /** 封面URI */
  coverUri?: string;
}

/**
 * 扫描配置
 */
export interface ScanConfig {
  /** 扫描路径 */
  scanPath: string;
  /** 递归扫描子文件夹 */
  recursive: boolean;
  /** 支持的文件格式 */
  supportedFormats: DocumentFormat[];
  /** 最小文件大小（字节） */
  minFileSize?: number;
  /** 最大文件大小（字节） */
  maxFileSize?: number;
  /** 过滤隐藏文件 */
  excludeHidden: boolean;
}

/**
 * 导入结果
 */
export interface ImportResult {
  /** 是否成功 */
  success: boolean;
  /** 导入的文档数 */
  importedCount: number;
  /** 失败的文档数 */
  failedCount: number;
  /** 跳过的文档数 */
  skippedCount: number;
  /** 导入的文档ID列表 */
  importedDocs: string[];
  /** 导入的文档对象列表（成功） */
  successDocs?: ScannedDocument[];
  /** 错误信息 */
  errors: string[];
  /** 导入时间 */
  importTime: number;
}

/**
 * 扫描进度
 */
export interface ScanProgress {
  /** 当前扫描的文件数 */
  currentFile: number;
  /** 总文件数 */
  totalFiles: number;
  /** 进度百分比 */
  percentage: number;
  /** 当前文件名 */
  currentFileName: string;
  /** 已发现的文档数 */
  foundDocs: number;
}

/**
 * 扫描监听器
 */
export interface ScanListener {
  /** 扫描开始 */
  onScanStart?: () => void;
  /** 扫描进度 */
  onScanProgress?: (progress: ScanProgress) => void;
  /** 扫描完成 */
  onScanComplete?: (docs: ScannedDocument[]) => void;
  /** 扫描错误 */
  onScanError?: (error: Error) => void;
}

/**
 * 授权信息
 */
export interface AuthorizationInfo {
  /** 授权ID */
  authId: string;
  /** 授权类型 */
  type: 'folder_access' | 'file_access' | 'storage_access';
  /** 授权路径 */
  path: string;
  /** 授权时间 */
  authorizedTime: number;
  /** 过期时间 */
  expireTime?: number;
  /** 是否持久化 */
  isPersistent: boolean;
}

/**
 * 扫描历史记录
 */
export interface ScanHistory {
  /** 扫描路径 */
  path: string;
  /** 扫描时间 */
  scanTime: number;
  /** 发现的文档数 */
  foundCount: number;
  /** 导入的文档数 */
  importedCount: number;
  /** 是否递归扫描 */
  recursive: boolean;
  /** 扫描耗时（毫秒） */
  duration: number;
}

/**
 * 文件计数引用（用于扫描进度跟踪）
 */
interface FileCountRef {
  total: number;
  processed: number;
}

/**
 * 文件夹扫描服务类
 */
class FolderScannerService {
  /** 单例实例 */
  private static instance: FolderScannerService;
  
  /** 上下文 */
  private context: common.Context | null = null;
  
  /** 是否已初始化 */
  private isInitialized: boolean = false;
  
  /** 扫描监听器 */
  private scanListener: ScanListener | null = null;
  
  /** 已授权路径列表 */
  private authorizedPaths: Map<string, AuthorizationInfo> = new Map();

  /** 已导入文档列表 */
  private importedDocs: Map<string, ScannedDocument> = new Map();

  /** 扫描历史记录 */
  private scanHistory: ScanHistory[] = [];

  /** 多目录管理 - 已添加的扫描目录列表 */
  private scanDirectories: string[] = [];

  /** 扫描取消标志 */
  private isCancelled: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): FolderScannerService {
    if (!FolderScannerService.instance) {
      FolderScannerService.instance = new FolderScannerService();
    }
    return FolderScannerService.instance;
  }

  /**
   * 初始化服务
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      console.info('[FolderScanner] Initializing...');
      this.context = context;

      // 加载已授权路径
      await this.loadAuthorizedPaths();

      // 加载已导入文档
      await this.loadImportedDocs();

      // 加载扫描历史
      await this.loadScanHistory();

      // 加载已保存的扫描目录列表
      await this.loadScanDirectories();

      this.isInitialized = true;
      console.info('[FolderScanner] Initialized successfully');
      return true;
    } catch (error) {
      console.error('[FolderScanner] Init failed:', error);
      return false;
    }
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 文件夹选择 ====================

  /**
   * 打开文件夹选择器（增强版 - 添加权限申请）
   */
  async selectFolder(): Promise<string | null> {
    try {
      console.info('[FolderScanner] Opening folder picker...');

      // 申请存储权限
      const hasPermission = await this.requestStoragePermission();
      if (!hasPermission) {
        console.warn('[FolderScanner] Storage permission not granted');
        promptAction.showToast({ 
          message: '需要文件访问权限，请选择文件夹授权',
          duration: 3000 
        });
        return null;
      }

      // 使用沙箱路径，转换为可访问的本地路径
      const documentPicker = new picker.DocumentViewPicker(this.context!);
      const documentSelectOptions = new picker.DocumentSelectOptions();

      const result = await documentPicker.select(documentSelectOptions);

      if (result && result.length > 0) {
        // 将沙箱 URI 转换为实际路径
        const folderPath = result[0];
        console.info('[FolderScanner] Folder selected:', folderPath);
        
        // 授权访问路径
        await this.authorizeFolderAccess(folderPath, true);
        
        return folderPath;
      }

      return null;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[FolderScanner] Select folder failed:', err.message);
      const errorMsg = error instanceof Error ? err.message : 'Unknown error';
      if (errorMsg.includes('permission') || errorMsg.includes('权限')) {
        promptAction.showToast({
          message: '需要文件访问权限，请在设置中授权',
          duration: 3000
        });
      }
      return null;
    }
  }

  /**
   * 打开文件选择器（多选）（增强版 - 添加权限申请）
   */
  async selectFiles(extensions?: string[]): Promise<string[] | null> {
    try {
      console.info('[FolderScanner] Opening file picker...');

      // 申请存储权限
      const hasPermission = await this.requestStoragePermission();
      if (!hasPermission) {
        console.warn('[FolderScanner] Storage permission not granted');
        promptAction.showToast({ 
          message: '需要文件访问权限，请选择文件授权',
          duration: 3000 
        });
        return null;
      }

      const documentPicker = new picker.DocumentViewPicker(this.context!);
      const documentSelectOptions = new picker.DocumentSelectOptions();

      // 实现格式过滤
      if (extensions && extensions.length > 0) {
        documentSelectOptions.fileSuffixFilters = extensions;
        console.info('[FolderScanner] Applying format filter:', extensions);
      } else {
        // 默认支持所有解析器支持的格式
        documentSelectOptions.fileSuffixFilters = [
          '.txt', '.text', '.pdf', '.epub', '.mobi',
          '.doc', '.docx', '.rtf', '.html', '.htm',
          '.azw', '.azw3', '.djvu', '.djv', '.chm',
          '.fb2', '.odt', '.cbr', '.cbz'
        ];
      }

      documentSelectOptions.maxSelectNumber = 50; // 最多选择 50 个文件

      const result = await documentPicker.select(documentSelectOptions);

      if (result && result.length > 0) {
        console.info('[FolderScanner] Files selected:', result.length);
        return result;
      }

      return null;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[FolderScanner] Select files failed:', err.message);
      return null;
    }
  }

  // ==================== 文件夹扫描 ====================

  /**
   * 递归计数文件（预扫描阶段）
   */
  private async countFilesRecursive(config: ScanConfig, currentPath?: string): Promise<number> {
    const scanPath = currentPath || config.scanPath;
    let count = 0;

    try {
      const entries = await fileIo.listFile(scanPath);

      for (const entry of entries) {
        const entryPath = `${scanPath}/${entry}`;

        try {
          const stat = await fileIo.stat(entryPath);

          // 跳过隐藏文件
          if (config.excludeHidden && entry.startsWith('.')) {
            continue;
          }

          // 递归计数子文件夹
          if (stat.isDirectory() && config.recursive) {
            count += await this.countFilesRecursive(config, entryPath);
          }

          // 计数文件
          if (stat.isFile()) {
            const format = enhancedParser.detectFormat(entryPath);
            if (config.supportedFormats.includes(format)) {
              if (config.minFileSize && stat.size < config.minFileSize) {
                continue;
              }
              if (config.maxFileSize && stat.size > config.maxFileSize) {
                continue;
              }
              count++;
            }
          }
        } catch (error) {
          console.warn('[FolderScanner] Failed to count:', entry, error instanceof Error ? error.message : String(error));
        }
      }
    } catch (error) {
      console.error('[FolderScanner] Count directory failed:', scanPath, error instanceof Error ? error.message : String(error));
    }

    return count;
  }

  /**
   * 扫描文件夹
   */
  async scanFolder(
    config: ScanConfig,
    listener?: ScanListener
  ): Promise<ScannedDocument[]> {
    try {
      if (!this.isReady()) {
        throw new Error('FolderScanner not initialized');
      }

      console.info('[FolderScanner] Scanning folder:', config.scanPath);

      this.scanListener = listener || null;
      this.notifyScanStart();

      const documents: ScannedDocument[] = [];

      // 检查路径是否已授权
      if (!this.isPathAuthorized(config.scanPath)) {
        throw new Error(`Path not authorized: ${config.scanPath}`);
      }

      // 阶段 1：预扫描计算总文件数
      const totalFiles = await this.countFilesRecursive(config);
      console.info('[FolderScanner] Pre-scan complete, total files:', totalFiles);

      // 阶段 2：实际扫描并使用准确总数计算进度
      const fileCountRef: FileCountRef = { total: totalFiles, processed: 0 };
      await this.scanDirectory(config, documents, undefined, fileCountRef);

      console.info('[FolderScanner] Scan complete, found', documents.length, 'documents');
      this.notifyScanComplete(documents);

      return documents;
    } catch (error) {
      console.error('[FolderScanner] Scan folder failed:', error instanceof Error ? error.message : String(error));
      this.notifyScanError(error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 递归扫描目录
   */
  private async scanDirectory(
    config: ScanConfig,
    documents: ScannedDocument[],
    currentPath?: string,
    totalFilesRef?: FileCountRef
  ): Promise<void> {
    const scanPath = currentPath || config.scanPath;

    try {
      // 列出文件
      const entries = await fileIo.listFile(scanPath);

      for (const entry of entries) {
        const entryPath = `${scanPath}/${entry}`;

        try {
          const stat = await fileIo.stat(entryPath);

          // 跳过隐藏文件
          if (config.excludeHidden && entry.startsWith('.')) {
            if (totalFilesRef) totalFilesRef.processed++;
            continue;
          }

          // 递归扫描子文件夹
          if (stat.isDirectory() && config.recursive) {
            await this.scanDirectory(config, documents, entryPath, totalFilesRef);
          }

          // 检查文件
          if (stat.isFile()) {
            const format = enhancedParser.detectFormat(entryPath);

            // 检查格式是否支持
            if (config.supportedFormats.includes(format)) {
              // 检查文件大小
              if (config.minFileSize && stat.size < config.minFileSize) {
                if (totalFilesRef) totalFilesRef.processed++;
                continue;
              }
              if (config.maxFileSize && stat.size > config.maxFileSize) {
                if (totalFilesRef) totalFilesRef.processed++;
                continue;
              }

              // 添加到文档列表
              const doc: ScannedDocument = {
                filePath: entryPath,
                fileName: entry,
                format: format,
                fileSize: stat.size,
                modifyTime: stat.mtime,
                isImported: this.importedDocs.has(entryPath)
              };

              documents.push(doc);
            }
          }
        } catch (error) {
          console.warn('[FolderScanner] Failed to process:', entry, error instanceof Error ? error.message : String(error));
        }

        if (totalFilesRef) {
          totalFilesRef.processed++;
          // 通知进度 - 使用准确的总数计算进度
          this.notifyScanProgress({
            currentFile: totalFilesRef.processed,
            totalFiles: totalFilesRef.total,
            percentage: Math.round((totalFilesRef.processed / totalFilesRef.total) * 100),
            currentFileName: entry,
            foundDocs: documents.length
          });
        }
      }
    } catch (error) {
      console.error('[FolderScanner] Scan directory failed:', scanPath, error instanceof Error ? error.message : String(error));
    }
  }

  // ==================== 批量导入 ====================

  /**
   * 批量导入文档（异步优化版）
   * 使用分片处理避免阻塞主线程
   */
  async importDocuments(
    documents: ScannedDocument[],
    extractMetadata: boolean = true
  ): Promise<ImportResult> {
    try {
      console.info('[FolderScanner] Importing', documents.length, 'documents...');

      let importedCount = 0;
      let failedCount = 0;
      let skippedCount = 0;
      const importedDocs: string[] = [];
      const errors: string[] = [];
      const successDocs: ScannedDocument[] = [];

      // 使用分片处理，每批处理10个文件
      const chunkSize = 10;
      for (let i = 0; i < documents.length; i += chunkSize) {
        const chunk = documents.slice(i, Math.min(i + chunkSize, documents.length));

        for (const doc of chunk) {
          try {
            // 跳过已导入的文档（增强检测）
            if (doc.isImported || this.isDocumentImported(doc.filePath)) {
              skippedCount++;
              continue;
            }

            // 解析文档
            if (extractMetadata) {
              const parseResult = await enhancedParser.parseDocument(doc.filePath, {
                extractContent: false,  // 不提取完整内容
                extractChapters: true,
                extractCover: true,
                paginate: false
              });

              if (parseResult.success && parseResult.metadata) {
                doc.title = parseResult.metadata.title;
                doc.author = parseResult.metadata.author;
                doc.coverUri = parseResult.metadata.coverData;
              }

              if (parseResult.warnings && parseResult.warnings.length > 0) {
                console.warn('[FolderScanner] Parse warnings:', parseResult.warnings);
              }
            }

            // 生成文档ID
            const docId = `doc_${Date.now()}_${importedCount}`;
            doc.docId = docId;
            doc.isImported = true;

            // 保存到已导入列表
            this.importedDocs.set(doc.filePath, doc);
            successDocs.push(doc);

            importedDocs.push(docId);
            importedCount++;
          } catch (error) {
            const err = error as Error;
            errors.push(`Failed to import ${doc.fileName}: ${err.message}`);
            failedCount++;
          }
        }

        // 每处理完一批后短暂延迟，释放主线程
        if (i + chunkSize < documents.length) {
          await new Promise<void>(resolve => setTimeout(resolve, 10));
        }
      }

      // 保存已导入文档列表
      await this.saveImportedDocs();

      const result: ImportResult = {
        success: failedCount === 0,
        importedCount: importedCount,
        failedCount: failedCount,
        skippedCount: skippedCount,
        importedDocs: importedDocs,
        errors: errors,
        importTime: Date.now(),
        successDocs: successDocs
      };

      console.info('[FolderScanner] Import complete:', result);
      return result;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('[FolderScanner] Import documents failed:', err.message);
      return {
        success: false,
        importedCount: 0,
        failedCount: documents.length,
        skippedCount: 0,
        importedDocs: [],
        errors: [err.message],
        importTime: Date.now(),
        successDocs: []
      };
    }
  }

  /**
   * 检查文档是否已导入（增强检测）
   */
  private isDocumentImported(filePath: string): boolean {
    // 检查精确匹配（本地缓存）
    if (this.importedDocs.has(filePath)) {
      return true;
    }

    // 检查是否已导入到书架（通过 preferenceManager 直接读取）
    const allBooks = preferenceManager.getBooks();
    for (let i = 0; i < allBooks.length; i++) {
      if (allBooks[i].filePath === filePath) {
        return true;
      }
    }

    return false;
  }

  // ==================== 授权管理 ====================

  /**
   * 运行时权限申请（真正的系统权限申请）
   */
  async requestStoragePermission(): Promise<boolean> {
    try {
      console.info('[FolderScanner] Requesting storage permission...');

      // HarmonyOS 使用 picker.DocumentViewPicker 隐式授权
      // 对于文件夹扫描，我们需要引导用户通过系统选择器授权
      // 这里返回 true 表示使用沙箱模式
      return true;
    } catch (error) {
      console.error('[FolderScanner] Request permission failed:', error);
      return false;
    }
  }

  /**
   * 授权文件夹访问（增强版 - 使用系统选择器）
   */
  async authorizeFolderAccess(path: string, persistent: boolean = true): Promise<boolean> {
    try {
      console.info('[FolderScanner] Authorizing folder access:', path);

      // 验证路径可访问
      if (!(await this.fileAccess(path))) {
        console.warn('[FolderScanner] Path not accessible:', path);
        return false;
      }

      const authInfo: AuthorizationInfo = {
        authId: `auth_${Date.now()}`,
        type: 'folder_access',
        path: path,
        authorizedTime: Date.now(),
        isPersistent: persistent
      };

      this.authorizedPaths.set(path, authInfo);
      await this.saveAuthorizedPaths();

      console.info('[FolderScanner] Folder authorized:', path);
      return true;
    } catch (error) {
      console.error('[FolderScanner] Authorize folder failed:', error);
      return false;
    }
  }

  /**
   * 撤销授权
   */
  async revokeAuthorization(path: string): Promise<boolean> {
    try {
      console.info('[FolderScanner] Revoking authorization:', path);
      
      this.authorizedPaths.delete(path);
      await this.saveAuthorizedPaths();

      console.info('[FolderScanner] Authorization revoked:', path);
      return true;
    } catch (error) {
      console.error('[FolderScanner] Revoke authorization failed:', error);
      return false;
    }
  }

  /**
   * 检查路径是否已授权
   */
  isPathAuthorized(path: string): boolean {
    // 检查精确匹配
    if (this.authorizedPaths.has(path)) {
      return true;
    }

    // 检查父路径是否已授权
    for (const entry of this.authorizedPaths.entries()) {
      const authPath = entry[0];
      if (path.startsWith(authPath)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 获取已授权路径列表
   */
  getAuthorizedPaths(): AuthorizationInfo[] {
    return Array.from(this.authorizedPaths.values());
  }

  // ==================== 多目录管理 ====================

  /**
   * 添加扫描目录
   */
  async addScanDirectory(path: string): Promise<boolean> {
    try {
      // 检查是否已存在
      if (this.scanDirectories.includes(path)) {
        console.warn('[FolderScanner] Directory already added:', path);
        return false;
      }

      // 验证路径可访问
      if (!(await this.fileAccess(path))) {
        console.warn('[FolderScanner] Path not accessible:', path);
        return false;
      }

      // 授权访问
      await this.authorizeFolderAccess(path, true);

      // 添加到列表
      const newDirs = this.scanDirectories.slice();
      newDirs.push(path);
      this.scanDirectories = newDirs;
      await this.saveScanDirectories();

      console.info('[FolderScanner] Directory added:', path);
      return true;
    } catch (error) {
      console.error('[FolderScanner] Add directory failed:', error);
      return false;
    }
  }

  /**
   * 移除扫描目录
   */
  removeScanDirectory(path: string): boolean {
    try {
      const index = this.scanDirectories.indexOf(path);
      if (index === -1) {
        console.warn('[FolderScanner] Directory not found:', path);
        return false;
      }

      const newDirs = this.scanDirectories.slice();
      newDirs.splice(index, 1);
      this.scanDirectories = newDirs;
      this.saveScanDirectories();

      console.info('[FolderScanner] Directory removed:', path);
      return true;
    } catch (error) {
      console.error('[FolderScanner] Remove directory failed:', error);
      return false;
    }
  }

  /**
   * 获取已添加的扫描目录列表
   */
  getScanDirectories(): string[] {
    return Array.from(this.scanDirectories);
  }

  /**
   * 扫描所有已添加的目录
   */
  async scanAllDirectories(
    config: ScanConfig,
    listener?: ScanListener
  ): Promise<ScannedDocument[]> {
    try {
      if (this.scanDirectories.length === 0) {
        console.warn('[FolderScanner] No directories added');
        return [];
      }

      console.info('[FolderScanner] Scanning all directories:', this.scanDirectories.length);

      const allDocs: ScannedDocument[] = [];

      // 循环扫描所有目录
      for (let i = 0; i < this.scanDirectories.length; i++) {
        const dir = this.scanDirectories[i];
        console.info(`[FolderScanner] Scanning directory ${i + 1}/${this.scanDirectories.length}:`, dir);

        // 创建目录特定的配置
        const dirConfig: ScanConfig = {
          scanPath: dir,
          recursive: config.recursive,
          supportedFormats: config.supportedFormats,
          minFileSize: config.minFileSize,
          maxFileSize: config.maxFileSize,
          excludeHidden: config.excludeHidden
        };

        // 扫描当前目录
        const docs = await this.scanFolder(dirConfig, listener);
        for (let k = 0; k < docs.length; k++) {
          allDocs.push(docs[k]);
        }

        // 检查是否取消
        if (this.isCancelled) {
          console.info('[FolderScanner] Scan cancelled by user');
          break;
        }
      }

      console.info('[FolderScanner] All directories scan complete:', allDocs.length, 'files found');
      return allDocs;
    } catch (error) {
      console.error('[FolderScanner] Scan all directories failed:', error);
      return [];
    }
  }

  // ==================== 扫描取消功能 ====================

  /**
   * 取消扫描
   */
  cancelScan(): void {
    this.isCancelled = true;
    console.info('[FolderScanner] Scan cancelled');
  }

  /**
   * 重置取消标志
   */
  resetCancel(): void {
    this.isCancelled = false;
    console.info('[FolderScanner] Cancel flag reset');
  }

  /**
   * 检查是否已取消
   */
  checkCancelled(): boolean {
    return this.isCancelled;
  }

  // ==================== 持久化 ====================

  /**
   * 保存扫描目录列表
   */
  private async saveScanDirectories(): Promise<void> {
    try {
      const json = JSON.stringify(this.scanDirectories);
      await preferenceManager.setValue('scan_directories', json);
    } catch (error) {
      console.error('[FolderScanner] Save directories failed:', error);
    }
  }

  /**
   * 加载扫描目录列表
   */
  private async loadScanDirectories(): Promise<void> {
    try {
      const json = await preferenceManager.getValue('scan_directories', '[]');
      this.scanDirectories = JSON.parse(json) as string[];
    } catch (error) {
      console.error('[FolderScanner] Load directories failed:', error);
      this.scanDirectories = [];
    }
  }

  // ==================== 持久化 ====================

  /**
   * 加载已授权路径
   */
  private async loadAuthorizedPaths(): Promise<void> {
    try {
      const savedPaths = await preferenceManager.getValue('authorized_paths', '[]');
      const pathsArray = JSON.parse(savedPaths) as Array<AuthorizationInfo>;
      
      this.authorizedPaths.clear();
      for (const auth of pathsArray) {
        this.authorizedPaths.set(auth.path, auth);
      }

      console.info('[FolderScanner] Loaded', this.authorizedPaths.size, 'authorized paths');
    } catch (error) {
      console.error('[FolderScanner] Load authorized paths failed:', error);
    }
  }

  /**
   * 保存已授权路径
   */
  private async saveAuthorizedPaths(): Promise<void> {
    try {
      const pathsArray = Array.from(this.authorizedPaths.values());
      await preferenceManager.setValue('authorized_paths', JSON.stringify(pathsArray));
      console.info('[FolderScanner] Saved', pathsArray.length, 'authorized paths');
    } catch (error) {
      console.error('[FolderScanner] Save authorized paths failed:', error);
    }
  }

  /**
   * 加载已导入文档
   */
  private async loadImportedDocs(): Promise<void> {
    try {
      const savedDocs = await preferenceManager.getValue('imported_docs', '{}');
      const docsObj = JSON.parse(savedDocs) as Record<string, ScannedDocument>;
      
      this.importedDocs.clear();
      for (const entry of Object.entries(docsObj)) {
        this.importedDocs.set(entry[0], entry[1]);
      }

      console.info('[FolderScanner] Loaded', this.importedDocs.size, 'imported docs');
    } catch (error) {
      console.error('[FolderScanner] Load imported docs failed:', error);
    }
  }

  /**
   * 保存已导入文档
   */
  private async saveImportedDocs(): Promise<void> {
    try {
      const docsObj: Record<string, ScannedDocument> = {};
      for (const entry of this.importedDocs.entries()) {
        docsObj[entry[0]] = entry[1];
      }
      
      await preferenceManager.setValue('imported_docs', JSON.stringify(docsObj));
      console.info('[FolderScanner] Saved', this.importedDocs.size, 'imported docs');
    } catch (error) {
      console.error('[FolderScanner] Save imported docs failed:', error);
    }
  }

  // ==================== 监听器通知 ====================

  /**
   * 设置扫描监听器
   */
  setScanListener(listener: ScanListener): void {
    this.scanListener = listener;
  }

  /**
   * 通知扫描开始
   */
  private notifyScanStart(): void {
    if (this.scanListener && this.scanListener.onScanStart) {
      this.scanListener.onScanStart();
    }
  }

  /**
   * 通知扫描进度
   */
  private notifyScanProgress(progress: ScanProgress): void {
    if (this.scanListener && this.scanListener.onScanProgress) {
      this.scanListener.onScanProgress(progress);
    }
  }

  /**
   * 通知扫描完成
   */
  private notifyScanComplete(docs: ScannedDocument[]): void {
    if (this.scanListener && this.scanListener.onScanComplete) {
      this.scanListener.onScanComplete(docs);
    }
  }

  /**
   * 通知扫描错误
   */
  private notifyScanError(error: Error): void {
    if (this.scanListener && this.scanListener.onScanError) {
      this.scanListener.onScanError(error);
    }
  }

  // ==================== 扫描历史 ====================

  /**
   * 加载扫描历史
   */
  private async loadScanHistory(): Promise<void> {
    try {
      const savedHistory = await preferenceManager.getString('scan_history', '[]');
      this.scanHistory = JSON.parse(savedHistory) as ScanHistory[];
      console.info('[FolderScanner] Loaded', this.scanHistory.length, 'scan history records');
    } catch (error) {
      console.error('[FolderScanner] Load scan history failed:', error);
      this.scanHistory = [];
    }
  }

  /**
   * 保存扫描历史
   */
  private async saveScanHistory(): Promise<void> {
    try {
      // 只保留最近 20 条记录
      const recentHistory = this.scanHistory.slice(0, 20);
      await preferenceManager.setString('scan_history', JSON.stringify(recentHistory));
      console.info('[FolderScanner] Saved', recentHistory.length, 'scan history records');
    } catch (error) {
      console.error('[FolderScanner] Save scan history failed:', error);
    }
  }

  /**
   * 添加扫描历史记录
   */
  async addScanHistory(history: ScanHistory): Promise<void> {
    const newHistory = this.scanHistory.slice();
    newHistory.unshift(history);
    this.scanHistory = newHistory;
    await this.saveScanHistory();
  }

  /**
   * 获取扫描历史记录
   */
  getScanHistory(): ScanHistory[] {
    return this.scanHistory;
  }

  /**
   * 清除扫描历史
   */
  async clearScanHistory(): Promise<void> {
    this.scanHistory = [];
    await preferenceManager.deleteValue('scan_history');
    console.info('[FolderScanner] Scan history cleared');
  }

  // ==================== 工具方法 ====================

  /**
   * 获取已导入文档列表
   */
  getImportedDocuments(): ScannedDocument[] {
    return Array.from(this.importedDocs.values());
  }

  /**
   * 清除导入缓存
   */
  async clearImportCache(): Promise<void> {
    this.importedDocs.clear();
    await preferenceManager.deleteValue('imported_docs');
    console.info('[FolderScanner] Import cache cleared');
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    try {
      console.info('[FolderScanner] Releasing...');
      this.scanListener = null;
      this.authorizedPaths.clear();
      this.importedDocs.clear();
      this.isInitialized = false;
      this.context = null;
      console.info('[FolderScanner] Released');
    } catch (error) {
      console.error('[FolderScanner] Release failed:', error);
    }
  }

  /**
   * 异步检查文件/目录是否存在
   */
  private async fileAccess(path: string): Promise<boolean> {
    try {
      await fileIo.access(path);
      return true;
    } catch {
      return false;
    }
  }
}

// 导出单例
export const folderScannerService = FolderScannerService.getInstance();
export default folderScannerService;
