// 分组管理面板组件
import { BookshelfGroup } from '../../../models/CoreBookModel';
import { themeManager, COMMON_COLORS, AppColors } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';

@Component
export struct GroupPanel {
  @Prop isDarkMode: boolean = false;
  @Prop currentGroupId: string = 'all';
  @Prop groups: BookshelfGroup[] = [];
  @Prop showAddGroupDialog: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  onPanelClose?: () => void;
  onSelectGroup?: (groupId: string) => void;
  onShowAddGroup?: () => void;

  async aboutToAppear(): Promise<void> {
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
  }

  build() {
    Column() {
      // 背景遮罩
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          if (this.onPanelClose) {
            this.onPanelClose();
          }
        })

      // 分组面板内容
      Column() {
        // 标题栏
        Row() {
          Text(tr('select_group'))
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentColors.textPrimary)

          Blank()

          Text('+ ' + tr('create_group'))
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontColor(this.currentColors.primary)
            .padding(8)
            .onClick(() => {
              if (this.onShowAddGroup) {
                this.onShowAddGroup();
              }
            })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 20, bottom: 16 })

        // 分组列表
        Scroll() {
          Column({ space: 8 }) {
            // 全部分组
            this.GroupItem('all', 'book_fill', tr('all_books'))

            // 自定义分组
            ForEach(this.groups, (group: BookshelfGroup) => {
              this.GroupItem(group.id, '📁', group.name)
            }, (group: BookshelfGroup) => group.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('55%')
      .backdropBlur(40)
      .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.9)' : 'rgba(255,255,255,0.9)')
      .borderRadius({ topLeft: 20, topRight: 20 })
      .border({
        width: { top: 1 },
        color: this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.1)'
      })
      .shadow({
        radius: 20,
        color: 'rgba(0,0,0,0.25)',
        offsetY: -4
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  GroupItem(groupId: string, icon: string, name: string) {
    Row() {
      Text(icon)
        .fontSize(fontScaleManager.getScaledFontSize(20))
      Text(name)
        .fontSize(fontScaleManager.getScaledFontSize(15))
        .fontColor(this.currentColors.textPrimary)
        .margin({ left: 12 })
      Blank()
      if (this.currentGroupId === groupId) {
        Text('✓')
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor(this.currentColors.primary)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentGroupId === groupId
      ? (this.isDarkMode ? 'rgba(0,125,255,0.15)' : 'rgba(0,125,255,0.1)')
      : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)'))
    .borderRadius(12)
    .onClick(() => {
      if (this.onSelectGroup) {
        this.onSelectGroup(groupId);
      }
    })
  }
}

// 添加分组对话框组件
@Component
export struct AddGroupDialog {
  @Prop isDarkMode: boolean = false;
  @Prop newGroupName: string = '';
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  onDialogClose?: () => void;
  onCreateGroup?: (groupName: string) => void;
  onGroupNameChange?: (name: string) => void;

  async aboutToAppear(): Promise<void> {
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
  }

  build() {
    Column() {
      // 背景遮罩
      Row()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          if (this.onDialogClose) {
            this.onDialogClose();
          }
        })

      // 对话框内容
      Column() {
        Text(tr('create_group'))
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })

        TextInput({ placeholder: tr('group_name') })
          .width('90%')
          .height(48)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.06)')
          .borderRadius(12)
          .padding({ left: 16, right: 16 })
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .onChange((value: string) => {
            if (this.onGroupNameChange) {
              this.onGroupNameChange(value);
            }
          })

        Row({ space: 12 }) {
          Button(tr('cancel'))
            .width('50%')
            .height(48)
            .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.06)')
            .fontColor(this.currentColors.textSecondary)
            .fontSize(fontScaleManager.getScaledFontSize(15))
            .borderRadius(12)
            .onClick(() => {
              if (this.onDialogClose) {
                this.onDialogClose();
              }
            })

          Button(tr('confirm'))
            .width('50%')
            .height(48)
            .backgroundColor(this.currentColors.primary)
            .fontColor('#FFFFFF')
            .fontSize(fontScaleManager.getScaledFontSize(15))
            .borderRadius(12)
            .onClick(() => {
              if (this.onCreateGroup) {
                this.onCreateGroup(this.newGroupName);
              }
            })
        }
        .width('90%')
        .padding({ top: 24, bottom: 24 })
      }
      .width('100%')
      .backdropBlur(40)
      .backgroundColor(this.isDarkMode ? 'rgba(44,44,46,0.9)' : 'rgba(255,255,255,0.9)')
      .borderRadius({ topLeft: 20, topRight: 20 })
      .border({
        width: { top: 1 },
        color: this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.1)'
      })
      .shadow({
        radius: 20,
        color: 'rgba(0,0,0,0.25)',
        offsetY: -4
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }
}