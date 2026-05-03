// 书籍封面组件
import { BookInfo, formatFileSize } from '../../../models/CoreBookModel';
import { bookViewModel } from '../../../viewmodels/BookViewModel';

interface CoverColors {
  background: string;
  textColor: string;
  accentColor: string;
}

@Component
export struct BookCover {
  @Prop book: BookInfo;
  @Prop isGridMode: boolean = true;
  @Prop coverWidth: number = 100;
  @Prop coverHeight: number = 140;
  onBookClick?: (book: BookInfo) => void;
  onBookLongPress?: (book: BookInfo) => void;

  private readonly coverColorPalette: string[] = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
  ];

  private getCoverColors(): CoverColors {
    let hash = 0;
    for (let i = 0; i < this.book.title.length; i++) {
      hash = this.book.title.charCodeAt(i) + ((hash << 5) - hash);
    }
    const bgColor = this.coverColorPalette[Math.abs(hash) % this.coverColorPalette.length];
    const colors: CoverColors = {
      background: bgColor,
      textColor: '#FFFFFF',
      accentColor: bookViewModel.getFormatColor(this.book.format)
    };
    return colors;
  }

  private getInitials(): string {
    return this.book.title.charAt(0).toUpperCase();
  }

  private getLastReadText(): string {
    const diff = Date.now() - this.book.lastReadTime;
    if (diff < 3600000) return '刚才';
    if (diff < 86400000) return Math.floor(diff / 3600000).toString() + '小时前';
    return Math.floor(diff / 86400000).toString() + '天前';
  }

  build() {
    if (this.isGridMode) {
      this.GridItemLayout()
    } else {
      this.ListItemLayout()
    }
  }

  @Builder
  GridItemLayout() {
    Column({ space: 6 }) {
      Stack() {
        this.CoverContent()
      }
      .width(this.coverWidth)
      .height(this.coverHeight)
      .align(Alignment.Center)

      Text(this.book.title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(this.coverWidth)
        .height(34)
        .textAlign(TextAlign.Start)
        .lineHeight(17)

      Text(this.book.author)
        .fontSize(10)
        .fontColor('#999999')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width(this.coverWidth)
        .textAlign(TextAlign.Start)
    }
    .width(this.coverWidth)
    .onClick(() => {
      if (this.onBookClick) {
        this.onBookClick(this.book);
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (this.onBookLongPress) {
            this.onBookLongPress(this.book);
          }
        })
    )
  }

  @Builder
  ListItemLayout() {
    Row({ space: 12 }) {
      Stack() {
        this.CoverContent()
      }
      .width(60)
      .height(80)

      Column({ space: 4 }) {
        Text(this.book.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.book.author)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(this.book.format)
            .fontSize(10)
            .fontColor(bookViewModel.getFormatColor(this.book.format))
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .border({ width: 1, color: bookViewModel.getFormatColor(this.book.format) })
            .borderRadius(3)

          Text(formatFileSize(this.book.fileSize))
            .fontSize(11)
            .fontColor('#999999')

          if (this.book.readProgress > 0) {
            Text(this.book.readProgress.toString() + '%')
              .fontSize(11)
              .fontColor('#4CAF50')
          }
        }
        .width('100%')

        if (this.book.lastReadTime > 0) {
          Text('最后阅读: ' + this.getLastReadText())
            .fontSize(11)
            .fontColor('#999999')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.book.isFavorite) {
        Text('★')
          .fontSize(20)
          .fontColor('#FFD700')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (this.onBookClick) {
        this.onBookClick(this.book);
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (this.onBookLongPress) {
            this.onBookLongPress(this.book);
          }
        })
    )
  }

  @Builder
  CoverContent() {
    Stack() {
      Column() {
        Text(this.getInitials())
          .fontSize(this.coverWidth * 0.4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getCoverColors().textColor)
          .opacity(0.9)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getCoverColors().background)
      .borderRadius(4)

      Text(this.book.format)
        .fontSize(9)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.getCoverColors().accentColor)
        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        .borderRadius(3)
        .position({ x: 4, y: 4 })

      if (this.book.readProgress > 0) {
        Text(this.book.readProgress.toString())
          .fontSize(10)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .backgroundColor('rgba(0,0,0,0.6)')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(8)
          .position({ x: this.coverWidth - 28, y: 4 })
      }

      if (this.book.isFavorite) {
        Text('★')
          .fontSize(12)
          .fontColor('#FFD700')
          .position({ x: 4, bottom: 4 })
      }

      if (this.book.readProgress > 0) {
        Row() {
          Row()
            .width(this.book.readProgress.toString() + '%')
            .height(3)
            .backgroundColor('#4CAF50')
        }
        .width('100%')
        .height(3)
        .backgroundColor('rgba(255,255,255,0.3)')
        .position({ bottom: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .shadow({
      radius: 6,
      color: 'rgba(0,0,0,0.15)',
      offsetY: 3
    })
  }
}
