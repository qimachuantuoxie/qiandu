import { router, promptAction } from '@kit.ArkUI';
import { todoViewModel, TodoViewModel } from '../viewmodels/TodoViewModel';
import { TodoItem, TodoStatus, TodoPriority, TodoFilterType, TodoSortType, getPriorityLabel, getPriorityColor, getStatusLabel, formatDueDate, isTodoOverdue } from '../../models/TodoModel';
import { themeManager } from '../../../core/utils/AppTheme';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { HDSColours, HDSSpacing, HDSTypography } from '../../../core/design/tokens/HDSDTokens';

@Entry
@ComponentV2
struct TodoPage {
  @Local vm: TodoViewModel = todoViewModel;
  @Local isDarkMode: boolean = themeManager.isDarkMode();
  @Local showAddDialog: boolean = false;
  @Local newTodoTitle: string = '';
  @Local newTodoDesc: string = '';
  @Local newTodoPriority: TodoPriority = TodoPriority.MEDIUM;

  aboutToAppear() {
    this.vm.loadTodos();
  }

  build() {
    Column() {
      PageHeader({
        title: '待办事项',
        showBack: true,
        rightContent: () => {
          Row({ space: 16 }) {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(20)
              .fontColor([this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900])
              .onClick(() => { this.showAddDialog = true; })
          }
        }
      })

      // 过滤选项
      this.FilterBar()

      // Todo列表
      this.TodoList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(getPageBackgroundColor())
    .dialog(this.AddTodoDialog())
  }

  @Builder
  FilterBar() {
    Scroll() {
      Row({ space: HDSSpacing.sm }) {
        this.FilterChip('全部', TodoFilterType.ALL)
        this.FilterChip('待完成', TodoFilterType.PENDING)
        this.FilterChip('已完成', TodoFilterType.COMPLETED)
        this.FilterChip('已过期', TodoFilterType.OVERDUE)
      }
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .margin({ top: HDSSpacing.md, bottom: HDSSpacing.sm })
  }

  @Builder
  FilterChip(label: string, type: TodoFilterType) {
    Text(label)
      .fontSize(HDSTypography.sizes.sm)
      .fontColor(this.vm.getFilterType() === type ? '#FFFFFF' : (this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900))
      .padding({ left: HDSSpacing.md, right: HDSSpacing.md, top: HDSSpacing.sm, bottom: HDSSpacing.sm })
      .backgroundColor(this.vm.getFilterType() === type ? HDSColours.primary.blue : 'transparent')
      .borderRadius(HDSBorderRadius.full)
      .border({ width: 1, color: this.vm.getFilterType() === type ? 'transparent' : (this.isDarkMode ? '#555555' : '#CCCCCC') })
      .onClick(() => { this.vm.setFilterType(type); })
  }

  @Builder
  TodoList() {
    let todos = this.vm.getFilteredTodos();
    if (todos.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.checkmark.circle'))
          .fontSize(48)
          .fontColor([this.isDarkMode ? '#555555' : '#CCCCCC'])
          .margin({ bottom: HDSSpacing.md })
        Text('暂无待办事项')
          .fontSize(HDSTypography.sizes.lg)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List() {
        ForEach(todos, (todo: TodoItem) => {
          ListItem() {
            this.TodoItemCard(todo)
          }
          .margin({ bottom: HDSSpacing.md })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: HDSSpacing.lg, right: HDSSpacing.lg })
      .scrollBar(BarState.Auto)
    }
  }

  @Builder
  TodoItemCard(todo: TodoItem) {
    HDSCard({
      padding: HDSSpacing.lg,
      onClick: () => { this.toggleTodoStatus(todo); },
      content: () => {
        Column({ space: HDSSpacing.sm }) {
          Row() {
            // 优先级标识
            Circle({ width: 8, height: 8 })
              .fill(getPriorityColor(todo.priority, this.isDarkMode))
              .margin({ right: HDSSpacing.sm })

            Text(todo.title)
              .fontSize(HDSTypography.sizes.md)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
              .decoration({ type: todo.status === TodoStatus.COMPLETED ? TextDecorationType.LineThrough : TextDecorationType.None })
              .layoutWeight(1)

            if (todo.status !== TodoStatus.COMPLETED) {
              SymbolGlyph($r('sys.symbol.checkmark.circle'))
                .fontSize(20)
                .fontColor([HDSColours.primary.blue])
                .onClick((event: ClickEvent) => {
                  event.stopPropagation();
                  this.vm.completeTodo(todo.id);
                })
            } else {
              SymbolGlyph($r('sys.symbol.arrow.counterclockwise'))
                .fontSize(20)
                .fontColor([HDSColours.neutral.gray600])
                .onClick((event: ClickEvent) => {
                  event.stopPropagation();
                  this.vm.restoreTodo(todo.id);
                })
            }
          }

          if (todo.description) {
            Text(todo.description)
              .fontSize(HDSTypography.sizes.sm)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
              .margin({ top: HDSSpacing.xs })
          }

          Row({ space: HDSSpacing.md }) {
            Text(getPriorityLabel(todo.priority))
              .fontSize(HDSTypography.sizes.xs)
              .fontColor(getPriorityColor(todo.priority, this.isDarkMode))
              .padding({ left: HDSSpacing.sm, right: HDSSpacing.sm, top: 2, bottom: 2 })
              .borderRadius(HDSBorderRadius.sm)
              .backgroundColor(getPriorityColor(todo.priority, this.isDarkMode) + '20')

            if (todo.dueDate > 0) {
              Text(formatDueDate(todo.dueDate))
                .fontSize(HDSTypography.sizes.xs)
                .fontColor(isTodoOverdue(todo) ? '#FF4D4F' : (this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600))
            }

            Text(getStatusLabel(todo.status))
              .fontSize(HDSTypography.sizes.xs)
              .fontColor(this.isDarkMode ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
          }

          Row() {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(16)
              .fontColor(['#FF4D4F'])
              .onClick((event: ClickEvent) => {
                event.stopPropagation();
                this.deleteTodo(todo);
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
        }
      }
    })
  }

  @Builder
  AddTodoDialog() {
    if (this.showAddDialog) {
      Column({ space: HDSSpacing.lg }) {
        Text('添加待办')
          .fontSize(HDSTypography.sizes.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

        TextInput({ placeholder: '标题', text: this.newTodoTitle })
          .width('100%')
          .onChange((value: string) => { this.newTodoTitle = value; })

        TextInput({ placeholder: '描述（可选）', text: this.newTodoDesc })
          .width('100%')
          .onChange((value: string) => { this.newTodoDesc = value; })

        Text('优先级')
          .fontSize(HDSTypography.sizes.md)
          .fontColor(this.isDarkMode ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)

        Row({ space: HDSSpacing.sm }) {
          this.PriorityButton('低', TodoPriority.LOW)
          this.PriorityButton('中', TodoPriority.MEDIUM)
          this.PriorityButton('高', TodoPriority.HIGH)
          this.PriorityButton('紧急', TodoPriority.URGENT)
        }

        Row({ space: HDSSpacing.md }) {
          Button('取消')
            .layoutWeight(1)
            .onClick(() => {
              this.showAddDialog = false;
              this.resetForm();
            })

          Button('添加')
            .layoutWeight(1)
            .onClick(() => {
              this.addTodo();
            })
        }
      }
      .padding(HDSPacing.xl)
      .backgroundColor(this.isDarkMode ? '#2A2A2A' : '#FFFFFF')
      .borderRadius(HDSBorderRadius.lg)
      .width('80%')
    }
  }

  @Builder
  PriorityButton(label: string, priority: TodoPriority) {
    Button(label)
      .backgroundColor(this.newTodoPriority === priority ? getPriorityColor(priority, false) : 'transparent')
      .fontColor(this.newTodoPriority === priority ? '#FFFFFF' : getPriorityColor(priority, this.isDarkMode))
      .border({ width: 1, color: getPriorityColor(priority, this.isDarkMode) })
      .onClick(() => { this.newTodoPriority = priority; })
  }

  private addTodo(): void {
    if (!this.newTodoTitle.trim()) {
      promptAction.showToast({ message: '请输入标题' });
      return;
    }

    const todo: TodoItem = {
      id: Date.now().toString(36) + Math.random().toString(36).substr(2, 9),
      title: this.newTodoTitle.trim(),
      description: this.newTodoDesc.trim(),
      priority: this.newTodoPriority,
      status: TodoStatus.PENDING,
      dueDate: 0,
      createdTime: Date.now(),
      completedTime: 0,
      relatedBookId: '',
      relatedBookTitle: '',
      tags: [],
      reminder: false
    };

    this.vm.addTodo(todo);
    this.showAddDialog = false;
    this.resetForm();
    promptAction.showToast({ message: '添加成功' });
  }

  private toggleTodoStatus(todo: TodoItem): void {
    if (todo.status === TodoStatus.COMPLETED) {
      this.vm.restoreTodo(todo.id);
    } else {
      this.vm.completeTodo(todo.id);
    }
  }

  private deleteTodo(todo: TodoItem): void {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除"${todo.title}"吗？`,
      primaryButton: { value: '取消' },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.vm.deleteTodo(todo.id);
          promptAction.showToast({ message: '已删除' });
        }
      }
    });
  }

  private resetForm(): void {
    this.newTodoTitle = '';
    this.newTodoDesc = '';
    this.newTodoPriority = TodoPriority.MEDIUM;
  }
}
