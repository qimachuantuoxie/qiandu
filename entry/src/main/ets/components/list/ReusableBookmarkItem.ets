/**
 * 可复用的书签列表项组件
 * 使用 @Reusable 优化列表渲染性能
 *
 * @since 6.0.0
 */

import { Bookmark, BookInfo } from '../../models/CoreBookModel';
import { AppColors } from '../../utils/AppTheme';

interface BookmarkWithBook {
  bookmark: Bookmark;
  book: BookInfo | null;
}

@Reusable
@Component
export struct ReusableBookmarkItem {
  @State item: BookmarkWithBook = {} as BookmarkWithBook;
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  onTap?: (item: BookmarkWithBook) => void;
  onDelete?: (item: BookmarkWithBook) => void;

  aboutToReuse(): void {
    // 组件复用时重置状态
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Column({ space: 6 }) {
      // 书签标题
      Text(this.item.bookmark.title)
        .fontSize(15 * this.fontScale)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 备注
      if (this.item.bookmark.note) {
        Text(this.item.bookmark.note)
          .fontSize(12 * this.fontScale)
          .fontColor(this.tc('#666666', '#999999'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      // 底部信息
      Row({ space: 8 }) {
        // 书名
        if (this.item.book) {
          Text(this.item.book.title)
            .fontSize(11 * this.fontScale)
            .fontColor(this.tc('#999999', '#666666'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 页码
        Text('P' + this.item.bookmark.pageNumber)
          .fontSize(11 * this.fontScale)
          .fontColor(this.tc('#999999', '#666666'))

        // 时间
        Text(new Date(this.item.bookmark.createTime).toLocaleDateString())
          .fontSize(11 * this.fontScale)
          .fontColor(this.tc('#999999', '#666666'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.tc('#FFFFFF', '#1C1C1E'))
    .borderRadius(8)
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.item);
      }
    })
  }
}
