/**
 * 快捷入口编辑器组件
 * Shortcut Entry Editor Component
 *
 * 功能:
 * 1. 支持启用/禁用快捷入口
 * 2. 保存用户自定义配置
 */

import { toast } from '../../../utils/ToastHelper';
import { preferenceManager } from '../../../utils/PreferenceManager';
import { themeManager, COMMON_COLORS, AppColors } from '../../../utils/AppTheme';
import { fontScaleManager } from '../../../utils/FontScaleManager';
import { tr } from '../../../utils/I18nManager';

/**
 * 快捷入口项
 */
export interface ShortcutItem {
  id: string;
  icon: string;
  titleKey: string;
  color: string;
  url: string;
  enabled: boolean;
}

/**
 * 默认快捷入口配置
 */
const DEFAULT_SHORTCUTS: ShortcutItem[] = [
  { id: 'stats', icon: 'chart_bar_fill', titleKey: 'reading_statistics', color: '#007DFF', url: 'pages/StatisticsPage', enabled: true },
  { id: 'todo', icon: 'pencil', titleKey: 'todo', color: '#FF6B6B', url: 'pages/TodoPage', enabled: true },
  { id: 'records', icon: 'book_fill', titleKey: 'read_records', color: '#52C41A', url: 'pages/ReadRecordPage', enabled: true },
  { id: 'bookmarks', icon: 'bookmark_fill', titleKey: 'bookmarks', color: '#FFA500', url: 'pages/BookmarkPage', enabled: true },
  { id: 'notes', icon: '✏️', titleKey: 'notes', color: '#9370DB', url: 'pages/NotePage', enabled: true },
  { id: 'smart', icon: 'brain_headphones', titleKey: 'smart_services', color: '#00CED1', url: '', enabled: true }
];

@Component
export struct ShortcutEditor {
  @Consume('isDarkMode') isDarkMode: boolean;
  @State shortcuts: ShortcutItem[] = DEFAULT_SHORTCUTS;
  @State draggedIndex: number = -1;
  @State dragY: number = 0;
  onClose?: () => void;
  currentColors: AppColors = themeManager.getColors();

  aboutToAppear(): void {
    this.currentColors = themeManager.getColors();
    this.loadShortcuts();
  }

  private loadShortcuts(): void {
    try {
      const saved = preferenceManager.getString('shortcuts', '');
      if (saved) {
        this.shortcuts = JSON.parse(saved) as ShortcutItem[];
      }
    } catch {
      this.shortcuts = DEFAULT_SHORTCUTS;
    }
  }

  private saveShortcuts(): void {
    try {
      preferenceManager.setString('shortcuts', JSON.stringify(this.shortcuts));
    } catch (error) {
      const err = error as Error;
      console.error('保存快捷方式失败:', err.message);
    }
  }

  private resetToDefault(): void {
    this.shortcuts = DEFAULT_SHORTCUTS;
    this.saveShortcuts();
    toast(tr('reset_default'), 1500);
  }

  private toggleShortcut(index: number): void {
    const newShortcuts = this.shortcuts.slice();
    const updatedItem: ShortcutItem = {
      id: newShortcuts[index].id,
      icon: newShortcuts[index].icon,
      titleKey: newShortcuts[index].titleKey,
      color: newShortcuts[index].color,
      url: newShortcuts[index].url,
      enabled: !newShortcuts[index].enabled
    };
    newShortcuts[index] = updatedItem;
    this.shortcuts = newShortcuts;
    this.saveShortcuts();
  }

  build() {
    Column() {
      Row() {
        Text(tr('cancel'))
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor(this.currentColors.textSecondary)
          .onClick(() => { if (this.onClose) this.onClose(); })

        Text(tr('edit_shortcuts'))
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(tr('reset'))
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontColor(this.currentColors.primary)
          .onClick(() => this.resetToDefault())
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })

      Text(tr('drag_sort_hint'))
        .fontSize(fontScaleManager.getScaledFontSize(13))
        .fontColor(this.currentColors.textSecondary)
        .width('100%')
        .padding({ left: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.shortcuts, (item: ShortcutItem, index: number) => {
            this.ShortcutListItem(item, index)
          }, (item: ShortcutItem) => item.id)
        }.padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Auto)
    }
    .width('100%').height('100%')
  }

  @Builder
  ShortcutListItem(item: ShortcutItem, index: number) {
    Row() {
      Column() {
        Text('≡')
          .fontSize(fontScaleManager.getScaledFontSize(20))
          .fontColor(this.currentColors.textSecondary)
      }
      .width(40).height(40).justifyContent(FlexAlign.Center)

      Row({ space: 12 }) {
        Column() {
          Text(item.icon).fontSize(fontScaleManager.getScaledFontSize(24))
        }
        .width(48).height(48).borderRadius(12).backgroundColor(item.color + '20').justifyContent(FlexAlign.Center)

        Column({ space: 4 }) {
          Text(tr(item.titleKey)).fontSize(fontScaleManager.getScaledFontSize(15)).fontWeight(FontWeight.Medium).fontColor(this.currentColors.textPrimary)
          Text(item.enabled ? tr('enabled') : tr('disabled')).fontSize(fontScaleManager.getScaledFontSize(12)).fontColor(item.enabled ? COMMON_COLORS.SUCCESS_GREEN : this.currentColors.textSecondary)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: item.enabled })
        .selectedColor(this.currentColors.primary)
        .onChange((isOn: boolean) => {
          const newShortcuts = this.shortcuts.slice();
          const updatedItem: ShortcutItem = {
            id: newShortcuts[index].id,
            icon: newShortcuts[index].icon,
            titleKey: newShortcuts[index].titleKey,
            color: newShortcuts[index].color,
            url: newShortcuts[index].url,
            enabled: isOn
          };
          newShortcuts[index] = updatedItem;
          this.shortcuts = newShortcuts;
          this.saveShortcuts();
        })
    }
    .width('100%').height(72).padding({ left: 12, right: 12 })
    .borderRadius(12)
    .onClick(() => this.toggleShortcut(index))
  }
}
