/**
 * FolderScannerPage ViewModel - V2鐗堟湰
 */
import { fileIo, picker } from '@kit.CoreFileKit';
import { BookInfo, BookFormat, ReadStatus } from '../models/CoreBookModel';
import { bookViewModel } from './BookViewModel';
import { preferenceManager } from '../utils/PreferenceManager';
import { fontScaleManager } from '../utils/FontScaleManager';
import { appTheme, themeManager, AppColors } from '../utils/AppTheme';
import { DeviceUtils } from '../utils/DeviceUtils';

interface ScanResult {
  id?: string;
  path: string;
  name: string;
  format: BookFormat;
  size: number;
  selected: boolean;
}

@ObservedV2
export class FolderScannerViewModel {
  @Trace scanPath: string = '';
  @Trace results: ScanResult[] = [];
  @Trace selectedCount: number = 0;
  @Trace isScanning: boolean = false;
  @Trace isImporting: boolean = false;
  @Trace isDarkMode: boolean = false;
  @Trace fontScale: number = 1.0;
  @Trace currentColors: AppColors = themeManager.getColors();
  @Trace isTablet: boolean = false;
  @Trace scanProgress: string = '';

  async init(): Promise<void> {
    this.isDarkMode = appTheme.isDarkMode();
    this.fontScale = await fontScaleManager.getFontScale();
    this.currentColors = themeManager.getColors();
    this.isTablet = DeviceUtils.isTablet();
  }

  async selectFolder(): Promise<void> {
    try {
      // 按需申请文件访问权限
      const hasPermission = await this.requestFilePermission();
      if (!hasPermission) {
        this.scanProgress = '需要文件访问权限，请在设置中授权';
        return;
      }

      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;

      const result = await documentPicker.select(options);
      if (result && result.length > 0) {
        this.scanPath = result[0];
        this.scanProgress = '已选择目录，正在扫描...';
        await this.scanFolder(result[0]);
      }
    } catch (error) {
      const err = error as Error;
      this.scanProgress = '选择目录失败: ' + err.message;
    }
  }

  private async requestFilePermission(): Promise<boolean> {
    try {
      // HarmonyOS 使用 picker 隐式授权，不需要额外权限请求
      // 如果用户拒绝，picker 会自动返回空结果
      return true;
    } catch {
      return false;
    }
  }

  async scanFolder(path: string): Promise<void> {
    this.isScanning = true;
    this.scanProgress = 'Scanning...';
    this.results = [];

    try {
      const files = await this.getBookFiles(path);
      const newResults: ScanResult[] = [];
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        newResults.push({
          path: file.path,
          name: file.name,
          format: file.format,
          size: file.size,
          selected: false
        });
        this.scanProgress = 'Scanning ' + (i + 1) + '/' + files.length;
      }
      this.results = newResults;
    } catch (error) {
      const err = error as Error;
    } finally {
      this.isScanning = false;
      this.scanProgress = '';
    }
  }

  private async getBookFiles(dirPath: string): Promise<ScanResult[]> {
    const bookExtensions = [
      '.txt', '.epub', '.pdf', '.mobi', '.doc', '.docx',
      '.azw', '.azw3', '.rtf', '.html', '.htm', '.odt',
      '.fb2', '.cbr', '.cbz', '.djvu', '.djv', '.chm', '.md'
    ];
    const results: ScanResult[] = [];

    try {
      const files = fileIo.listFileSync(dirPath);
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const dotIndex = file.name.lastIndexOf('.');
        if (dotIndex < 0) continue;
        const ext = file.name.substring(dotIndex).toLowerCase();
        if (bookExtensions.includes(ext)) {
          results.push({
            path: file.path,
            name: file.name,
            format: this.getFormatFromExt(ext),
            size: file.length || 0
          });
        }
      }
    } catch {
      // 忽略无权访问的目录
    }

    return results;
  }

  private getFormatFromExt(ext: string): BookFormat {
    const formatMap: Record<string, BookFormat> = {
      '.txt': BookFormat.TXT,
      '.epub': BookFormat.EPUB,
      '.pdf': BookFormat.PDF,
      '.mobi': BookFormat.MOBI,
      '.doc': BookFormat.DOC,
      '.docx': BookFormat.DOCX,
      '.azw': BookFormat.AZW,
      '.azw3': BookFormat.AZW3,
      '.rtf': BookFormat.RTF,
      '.html': BookFormat.HTML,
      '.htm': BookFormat.HTML,
      '.odt': BookFormat.ODT,
      '.fb2': BookFormat.FB2,
      '.cbr': BookFormat.CBR,
      '.cbz': BookFormat.CBZ,
      '.djvu': BookFormat.DJVU,
      '.djv': BookFormat.DJVU,
      '.chm': BookFormat.CHM,
      '.md': BookFormat.MD
    };
    return formatMap[ext] || BookFormat.TXT;
  }

  toggleSelect(index: number): void {
    if (index >= 0 && index < this.results.length) {
      const newResults: ScanResult[] = [];
      for (let i = 0; i < this.results.length; i++) {
        const r = this.results[i];
        if (i === index) {
          newResults.push({
            path: r.path,
            name: r.name,
            format: r.format,
            size: r.size,
            selected: !r.selected
          });
        } else {
          newResults.push(r);
        }
      }
      this.results = newResults;
      let count = 0;
      for (let i = 0; i < this.results.length; i++) {
        if (this.results[i].selected) {
          count++;
        }
      }
      this.selectedCount = count;
    }
  }

  selectAll(): void {
    const newResults: ScanResult[] = [];
    for (let i = 0; i < this.results.length; i++) {
      const item: ScanResult = {
        id: this.results[i].id,
        name: this.results[i].name,
        path: this.results[i].path,
        format: this.results[i].format,
        size: this.results[i].size,
        selected: true
      };
      newResults.push(item);
    }
    this.results = newResults;
    this.selectedCount = this.results.length;
  }

  deselectAll(): void {
    const newResults: ScanResult[] = [];
    for (let i = 0; i < this.results.length; i++) {
      const item: ScanResult = {
        id: this.results[i].id,
        name: this.results[i].name,
        path: this.results[i].path,
        format: this.results[i].format,
        size: this.results[i].size,
        selected: false
      };
      newResults.push(item);
    }
    this.results = newResults;
    this.selectedCount = 0;
  }

  async importSelected(): Promise<void> {
    this.isImporting = true;
    const selected: ScanResult[] = [];
    for (let i = 0; i < this.results.length; i++) {
      if (this.results[i].selected) {
        selected.push(this.results[i]);
      }
    }

    for (let i = 0; i < selected.length; i++) {
      try {
        const book: BookInfo = {
          id: 'book_' + Date.now() + '_' + i,
          title: selected[i].name,
          author: '',
          filePath: selected[i].path,
          format: selected[i].format,
          totalPages: 0,
          currentPage: 0,
          readProgress: 0,
          lastReadTime: 0,
          addTime: Date.now(),
          fileSize: selected[i].size,
          status: ReadStatus.UNREAD,
          isFavorite: false
        };
        bookViewModel.addBook(book);
      } catch (e) {
        const err = e as Error;
        console.error('Import book failed:', err.message);
      }
    }

    this.isImporting = false;
  }
}

export const folderScannerViewModel = new FolderScannerViewModel();
