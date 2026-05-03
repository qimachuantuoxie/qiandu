/**
 * EPUB Parser - EPUB 电子书解析器
 *
 * 提供 EPUB 格式电子书的解析功能，包括：
 * - ZIP 容器解压
 * - OPF 元数据提取
 * - NCX/NAV 目录解析
 * - XHTML 内容文本提取
 *
 * @since 6.0.0
 */

import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ZipUtils } from '../utils/ZipUtils';
import {
  BookMetadata,
  LocalChapterInfo,
  HtmlFile,
  NavItem,
  NavPoint,
  ParseResult,
  ZipParseResult
} from '../core/models/EbookTypes';

/**
 * EPUB 解析器类
 */
export class EpubParser {

  /**
   * 解析 EPUB 文件
   * @param filePath EPUB 文件路径
   * @returns 解析结果
   */
  static async parse(filePath: string): Promise<ParseResult> {
    console.info('[EpubParser] Parsing EPUB file:', filePath);

    try {
      const epubContent = await EpubParser.unzipEpub(filePath);
      const metadata = await EpubParser.parseOpfMetadata(epubContent, filePath);
      const chapters = await EpubParser.parseNcxNavigation(epubContent);
      const content = await EpubParser.extractEpubText(epubContent);

      console.info('[EpubParser] EPUB parsed: ' + metadata.title + ', ' + chapters.length + ' chapters');

      return {
        metadata,
        content,
        chapters,
        success: true
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[EpubParser] EPUB parsing failed:', message);
      throw new Error('EPUB parsing failed: ' + message);
    }
  }

  /**
   * 解压 EPUB 文件（EPUB 本质是 ZIP）
   * @param filePath EPUB 文件路径
   * @returns 文件路径到内容的映射
   */
  private static async unzipEpub(filePath: string): Promise<Record<string, string>> {
    console.info('[EpubParser] Unzipping EPUB:', filePath);
    const contentMap: Record<string, string> = {};

    try {
      const stat = fileIo.statSync(filePath);
      const buffer = new Uint8Array(stat.size);
      const fd = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.readSync(fd.fd, buffer);
      } finally {
        fileIo.closeSync(fd);
      }

      const zipResult: ZipParseResult = ZipUtils.parseZipBuffer(buffer.buffer as ArrayBuffer);

      const entryCount = zipResult.entries.length;
      for (let i = 0; i < entryCount; i++) {
        const entry = zipResult.entries[i];
        if (!entry.isDirectory && entry.data) {
          const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
          const content = decoder.decode(new Uint8Array(entry.data));
          contentMap[entry.path] = content;
        }
      }

      console.info('[EpubParser] EPUB unzip complete: ' + Object.keys(contentMap).length + ' files');
      return contentMap;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('[EpubParser] Unzip EPUB failed:', message);
      return contentMap;
    }
  }

  /**
   * 解析 OPF 元数据
   * @param contentMap 文件内容映射
   * @param filePath 原始文件路径
   * @returns 书籍元数据
   */
  private static async parseOpfMetadata(contentMap: Record<string, string>, filePath: string): Promise<BookMetadata> {
    const fileName = EpubParser.extractFileName(filePath);
    const nameWithoutExt = fileName.replace(new RegExp('\.[^/.]+$', ''), '');

    let opfPath = 'content.opf';
    let opfBasePath = '';

    const containerXml = contentMap['META-INF/container.xml'];
    if (containerXml) {
      const rootfileMatch = containerXml.match(new RegExp('full-path="([^"]+)"', ''));
      if (rootfileMatch && rootfileMatch.length >= 2) {
        opfPath = rootfileMatch[1];
        const lastSlash = opfPath.lastIndexOf('/');
        opfBasePath = lastSlash >= 0 ? opfPath.substring(0, lastSlash + 1) : '';
      }
    }

    try {
      const opfContent = contentMap[opfPath] || '';

      if (!opfContent) {
        console.warn('[EpubParser] OPF file not found:', opfPath);
        return {
          title: nameWithoutExt,
          author: 'Unknown Author',
          totalPages: 150
        };
      }

      const manifest: Record<string, string> = {};
      const manifestPattern = new RegExp('<item[^>]+id="([^"]+)"[^>]+href="([^"]+)"[^>]*>', 'gi');
      let manifestMatch: RegExpExecArray | null;
      while ((manifestMatch = manifestPattern.exec(opfContent)) !== null) {
        if (manifestMatch.length >= 3) {
          manifest[manifestMatch[1]] = manifestMatch[2];
        }
      }

      const coverId = EpubParser.extractMetaAttribute(opfContent, 'cover', 'name');
      let coverData: string | undefined;
      if (coverId && manifest[coverId]) {
        const coverPath = opfBasePath + manifest[coverId];
        const coverContent = contentMap[coverPath];
        if (coverContent) {
          coverData = coverContent.startsWith('/9j/') || coverContent.startsWith('iVBOR')
            ? coverContent
            : 'data:image/jpeg;base64,' + coverContent;
        }
      }

      const dcTitle = EpubParser.extractDublinCore(opfContent, 'title') || nameWithoutExt;
      const dcCreator = EpubParser.extractDublinCore(opfContent, 'creator') || 'Unknown Author';

      return {
        title: dcTitle,
        author: dcCreator,
        publisher: EpubParser.extractDublinCore(opfContent, 'publisher'),
        language: EpubParser.extractDublinCore(opfContent, 'language') || 'zh-CN',
        isbn: EpubParser.extractDublinCore(opfContent, 'identifier'),
        description: EpubParser.extractDublinCore(opfContent, 'description'),
        coverData: coverData,
        totalPages: 150,
        wordCount: undefined,
        createdDate: EpubParser.extractDublinCore(opfContent, 'date'),
        modifiedDate: undefined
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.warn('[EpubParser] Parse OPF metadata failed:', message);
      return {
        title: nameWithoutExt,
        author: 'Unknown Author',
        totalPages: 150
      };
    }
  }

  /**
   * 提取 Dublin Core 元数据字段
   * @param content OPF 内容
   * @param tag 标签名
   * @returns 字段值
   */
  private static extractDublinCore(content: string, tag: string): string | undefined {
    const patterns = [
      new RegExp('<dc:' + tag + '[^>]*>([\\s\\S]*?)</dc:' + tag + '>', 'i'),
      new RegExp('<' + tag + '[^>]*opf:scheme="dublin core"[^>]*>([\\s\\S]*?)</' + tag + '>', 'i')
    ];

    for (let i = 0; i < patterns.length; i++) {
      const pattern = patterns[i];
      const match = content.match(pattern);
      if (match && match.length >= 2) {
        return match[1].trim();
      }
    }
    return undefined;
  }

  /**
   * 提取 meta 标签属性
   * @param content OPF 内容
   * @param name meta 名称
   * @param attr 属性名
   * @returns 属性值
   */
  private static extractMetaAttribute(content: string, name: string, attr: string): string | undefined {
    const pattern = new RegExp('<meta[^>]+content="([^"]+)"[^>]+name="' + name + '"', 'i');
    const match = content.match(pattern);
    return match ? match[1] : undefined;
  }

  /**
   * 解析 NCX 导航文件
   * @param contentMap 文件内容映射
   * @returns 章节列表
   */
  private static async parseNcxNavigation(contentMap: Record<string, string>): Promise<LocalChapterInfo[]> {
    const chapters: LocalChapterInfo[] = [];

    try {
      let ncxContent = '';
      let navContent = '';

      const keys = Object.keys(contentMap);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key.endsWith('.ncx')) {
          ncxContent = contentMap[key];
          break;
        }
      }

      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if ((key.endsWith('nav.xhtml') || key.endsWith('nav.html') || key.endsWith('toc.xhtml')) &&
            contentMap[key].includes('epub:type="toc"')) {
          navContent = contentMap[key];
          break;
        }
      }

      if (ncxContent) {
        const navPoints = EpubParser.extractNavPoints(ncxContent);
        for (let i = 0; i < navPoints.length; i++) {
          const point = navPoints[i];
          chapters.push({
            id: 'epub_nav_' + i,
            title: point.label,
            startOffset: point.order,
            endOffset: point.order + 1,
            level: point.level
          });
        }
      }

      if (navContent && chapters.length === 0) {
        const navItems = EpubParser.extractNavItems(navContent);
        for (let i = 0; i < navItems.length; i++) {
          const item = navItems[i];
          chapters.push({
            id: 'epub_nav_' + i,
            title: item.label,
            startOffset: i,
            endOffset: i + 1,
            level: item.level
          });
        }
      }

      if (chapters.length === 0) {
        chapters.push({
          id: 'epub_nav_0',
          title: '内容',
          startOffset: 0,
          endOffset: 1,
          level: 1
        });
      }

      console.info('[EpubParser] Extracted ' + chapters.length + ' EPUB chapters');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.warn('[EpubParser] Parse NCX navigation failed:', message);
    }

    return chapters;
  }

  /**
   * 从 NCX 内容中提取导航点
   * @param ncxContent NCX XML 内容
   * @returns 导航点列表
   */
  private static extractNavPoints(ncxContent: string): NavPoint[] {
    const navPoints: NavPoint[] = [];
    let currentLevel = 1;

    const navPointPattern = new RegExp('<navPoint([^>]*)>([\s\S]*?)<\/navPoint>', 'gi');
    let match: RegExpExecArray | null = null;

    while ((match = navPointPattern.exec(ncxContent)) !== null) {
      const attrs: string = match[1];
      const content: string = match[2];

      const depthMatch = attrs.match(new RegExp('class="([^"]*)"', ''));
      if (depthMatch && depthMatch.length >= 2) {
        const className: string = depthMatch[1];
        if (className.includes('level1')) currentLevel = 1;
        else if (className.includes('level2')) currentLevel = 2;
        else if (className.includes('level3')) currentLevel = 3;
      }

      const textMatch = content.match(new RegExp('<text[^>]*>([\s\S]*?)<\/text>', 'i'));
      const label: string = textMatch && textMatch.length >= 2 ? textMatch[1].replace(new RegExp('<[^>]+>', 'g'), '').trim() : 'Unnamed';

      if (label && label !== 'Unnamed') {
      const playOrderMatch = content.match(new RegExp('playOrder="(\d+)"', ''));
        let order: number = navPoints.length;
        if (playOrderMatch && playOrderMatch.length >= 2) {
          const parsed = parseInt(playOrderMatch[1], 10);
          order = isNaN(parsed) ? navPoints.length : parsed;
        }

        const navPoint: NavPoint = {
          label: label,
          order: order,
          level: currentLevel
        };
        navPoints.push(navPoint);
      }
    }

    return navPoints;
  }

  /**
   * 从导航 HTML 中提取导航项
   * @param navContent 导航 HTML 内容
   * @returns 导航项列表
   */
  private static extractNavItems(navContent: string): NavItem[] {
    const items: NavItem[] = [];

    const listPattern = new RegExp('<ol[^>]*>([\s\S]*?)<\/ol>', 'gi');
    let listMatch: RegExpExecArray | null;

    while ((listMatch = listPattern.exec(navContent)) !== null) {
      const olContent = listMatch[1];
      const itemPattern = new RegExp('<li[^>]*>([\s\S]*?)<\/li>', 'gi');
      let itemMatch: RegExpExecArray | null;

      while ((itemMatch = itemPattern.exec(olContent)) !== null) {
        const liContent = itemMatch[1];
        const linkMatch = liContent.match(new RegExp('<a[^>]*>([\s\S]*?)<\/a>', 'i'));
        const label = linkMatch ? linkMatch[1].replace(new RegExp('<[^>]+>', 'g'), '').trim() : '';

        if (label) {
          const item: NavItem = { label: label, level: 1 };
          items.push(item);
        }

        const nestedOl = liContent.match(new RegExp('<ol[^>]*>([\s\S]*?)<\/ol>', 'i'));
        if (nestedOl) {
          const nestedItems = EpubParser.extractNavItems(nestedOl[0]);
          for (let i = 0; i < nestedItems.length; i++) {
            const nestedItem: NavItem = { label: nestedItems[i].label, level: nestedItems[i].level + 1 };
            items.push(nestedItem);
          }
        }
      }
    }

    return items;
  }

  /**
   * 从 EPUB 中提取全部文本内容
   * @param contentMap 文件内容映射
   * @returns 纯文本内容
   */
  private static async extractEpubText(contentMap: Record<string, string>): Promise<string> {
    let fullText = '';

    try {
      const htmlFiles: HtmlFile[] = [];

      const keys = Object.keys(contentMap);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const lowerKey = key.toLowerCase();
        if (lowerKey.endsWith('.xhtml') || lowerKey.endsWith('.html') || lowerKey.endsWith('.htm')) {
          if (!key.includes('nav') && !key.includes('toc') && !key.includes('cover')) {
            const htmlFile: HtmlFile = { path: key, content: contentMap[key] };
            htmlFiles.push(htmlFile);
          }
        }
      }

      const sortedHtmlFiles: HtmlFile[] = htmlFiles.slice();
      sortedHtmlFiles.sort((a: HtmlFile, b: HtmlFile): number => a.path.localeCompare(b.path));

      for (let i = 0; i < sortedHtmlFiles.length; i++) {
        const file = sortedHtmlFiles[i];
        const text = EpubParser.extractTextFromXhtml(file.content);
        if (text.trim()) {
          fullText += text + '\n\n';
        }
      }

      if (!fullText.trim()) {
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const lowerKey = key.toLowerCase();
          if (lowerKey.endsWith('.xhtml') || lowerKey.endsWith('.html') || lowerKey.endsWith('.htm')) {
            const text = EpubParser.extractTextFromXhtml(contentMap[key]);
            if (text.trim()) {
              fullText += text + '\n\n';
            }
          }
        }
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.warn('[EpubParser] Extract EPUB text failed:', message);
    }

    return fullText.trim();
  }

  /**
   * 从 XHTML/HTML 中提取纯文本
   * @param html HTML 内容
   * @returns 纯文本
   */
  private static extractTextFromXhtml(html: string): string {
    let text = html;

    // 移除 style 和 script 标签
    text = text.replace(new RegExp('<style[^>]*>[\s\S]*?<\/style>', 'gi'), '');
    text = text.replace(new RegExp('<script[^>]*>[\s\S]*?<\/script>', 'gi'), '');

    // 将块级元素结束标签替换为换行
    text = text.replace(new RegExp('<br\s*\/>?>', 'gi'), '\n');
    text = text.replace(new RegExp('<\/p>', 'gi'), '\n');
    text = text.replace(new RegExp('<\/div>', 'gi'), '\n');
    text = text.replace(new RegExp('<\/h[1-6]>', 'gi'), '\n');
    text = text.replace(new RegExp('<\/li>', 'gi'), '\n');

    // 移除所有 HTML 标签
    text = text.replace(new RegExp('<[^>]+>', 'g'), ' ');

    // 解码 HTML 实体
    text = text.replace(new RegExp('&nbsp;', 'gi'), ' ');
    text = text.replace(new RegExp('&amp;', 'gi'), '&');
    text = text.replace(new RegExp('&lt;', 'gi'), '<');
    text = text.replace(new RegExp('&gt;', 'gi'), '>');
    text = text.replace(new RegExp('&quot;', 'gi'), '"');
    text = text.replace(new RegExp('&#39;', 'gi'), "'");
    text = text.replace(new RegExp('&apos;', 'gi'), "'");
    text = text.replace(new RegExp('&#(\d+);', 'gi'), (_p1: string, num: string): string => String.fromCharCode(parseInt(num)));
    text = text.replace(new RegExp('&#x([0-9a-fA-F]+);', 'gi'), (_p1: string, hex: string): string => String.fromCharCode(parseInt(hex, 16)));

    // 清理空白
    text = text.replace(new RegExp('[\r\n]+', 'g'), '\n');
    text = text.replace(new RegExp('[ \t]+', 'g'), ' ');


    // 将块级元素结束标签替换为换行






    // 移除所有 HTML 标签


    // 解码 HTML 实体










    // 清理空白


    text = text.trim();

    return text;
  }

  /**
   * 从文件路径提取文件名
   * @param filePath 文件路径
   * @returns 文件名
   */
  private static extractFileName(filePath: string): string {
    const parts = filePath.split('/');
    const lastPart = parts[parts.length - 1];
    try {
      return decodeURIComponent(lastPart);
    } catch {
      return lastPart;
    }
  }
}

/** EPUB 解析器单例实例 */
export const epubParser = EpubParser;
