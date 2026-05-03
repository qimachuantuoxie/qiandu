/**
 * 可复用的 Todo 列表项组件
 * 使用 @Reusable 优化列表渲染性能
 *
 * @since 6.0.0
 */

import {
  TodoItem,
  TodoStatus,
  TodoPriority,
  getPriorityLabel,
  getPriorityColor,
  getPriorityIcon,
  formatDueDate,
  isTodoOverdue
} from '../../models/TodoModel';
import { AppColors } from '../../utils/AppTheme';

@Reusable
@Component
export struct ReusableTodoItem {
  @State todo: TodoItem = {} as TodoItem;
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = {} as AppColors;
  onToggleStatus?: (todo: TodoItem) => void;
  onEdit?: (todo: TodoItem) => void;
  onDelete?: (todo: TodoItem) => void;

  aboutToReuse(): void {
    // 组件复用时重置状态
  }

  private textColor(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  build() {
    Row({ space: 12 }) {
      // 完成复选框
      Button(this.todo.status === TodoStatus.COMPLETED ? '✓' : '○')
        .width(28)
        .height(28)
        .fontSize(20)
        .fontColor(this.todo.status === TodoStatus.COMPLETED ? '#52C41A' : this.textColor('#666666', '#CCCCCC'))
        .backgroundColor('transparent')
        .border({
          width: 2,
          color: this.todo.status === TodoStatus.COMPLETED ? '#52C41A' : this.textColor('#666666', '#CCCCCC')
        })
        .borderRadius(14)
        .onClick(() => {
          if (this.onToggleStatus) {
            this.onToggleStatus(this.todo);
          }
        })

      // 内容区
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(getPriorityIcon(this.todo.priority))
            .fontSize(14)

          Text(this.todo.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.todo.status === TodoStatus.COMPLETED ?
              this.textColor('#666666', '#999999') :
              this.textColor('#1A1A1A', '#FFFFFF'))
            .decoration({
              type: this.todo.status === TodoStatus.COMPLETED ? TextDecorationType.LineThrough : TextDecorationType.None
            })
            .layoutWeight(1)

          // 编辑按钮
          if (this.todo.status !== TodoStatus.COMPLETED) {
            Text('✎')
              .fontSize(16)
              .fontColor('#007DFF')
              .padding(4)
              .onClick(() => {
                if (this.onEdit) {
                  this.onEdit(this.todo);
                }
              })
          }
        }

        if (this.todo.description && this.todo.description.length > 0) {
          Text(this.todo.description)
            .fontSize(13)
            .fontColor(this.textColor('#666666', '#999999'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Row({ space: 12 }) {
          Text(getPriorityLabel(this.todo.priority))
            .fontSize(11)
            .fontColor(getPriorityColor(this.todo.priority, this.isDarkMode))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(getPriorityColor(this.todo.priority, this.isDarkMode) + '20')
            .borderRadius(8)

          if (this.todo.dueDate && this.todo.dueDate.length > 0) {
            Text(formatDueDate(this.todo.dueDate, this.isDarkMode))
              .fontSize(11)
              .fontColor(isTodoOverdue(this.todo) && this.todo.status !== TodoStatus.COMPLETED ?
                '#FF4D4F' :
                this.textColor('#999999', '#666666'))
          }

          if (this.todo.status === TodoStatus.COMPLETED && this.todo.completedTime) {
            Text('完成于 ' + new Date(this.todo.completedTime).toLocaleDateString())
              .fontSize(11)
              .fontColor(this.textColor('#999999', '#666666'))
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.textColor('#FFFFFF', '#1C1C1E'))
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: 'rgba(0,0,0,0.05)',
      offsetX: 0,
      offsetY: 2
    })
  }
}
