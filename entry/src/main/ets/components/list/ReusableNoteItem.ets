/**
 * 可复用的笔记列表项组件
 * 使用 @Reusable 优化列表渲染性能
 *
 * @since 6.0.0
 */

import { Note, BookInfo } from '../../models/CoreBookModel';
import { AppColors } from '../../utils/AppTheme';

interface NoteWithBook {
  note: Note;
  book: BookInfo | null;
}

@Reusable
@Component
export struct ReusableNoteItem {
  @State item: NoteWithBook = {} as NoteWithBook;
  @State isDarkMode: boolean = false;
  @State fontScale: number = 1.0;
  onTap?: (item: NoteWithBook) => void;
  onLongPress?: (item: NoteWithBook) => void;
  onDelete?: (item: NoteWithBook) => void;

  aboutToReuse(): void {
    // 组件复用时重置状态
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Column({ space: 8 }) {
      // 笔记内容
      Text(this.item.note.content)
        .fontSize(14 * this.fontScale)
        .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 高亮文本
      if (this.item.note.highlight) {
        Text(this.item.note.highlight)
          .fontSize(12 * this.fontScale)
          .fontColor(this.tc('#666666', '#999999'))
          .maxLines(2)
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
        Text('P' + this.item.note.pageNumber)
          .fontSize(11 * this.fontScale)
          .fontColor(this.tc('#999999', '#666666'))

        // 时间
        Text(new Date(this.item.note.createTime).toLocaleDateString())
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
