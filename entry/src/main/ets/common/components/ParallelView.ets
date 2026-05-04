/**
 * 折叠屏平行视界组件 - Foldable Parallel View
 * 
 * 实现类似华为平板的平行视界功能:
 * - 左侧显示列表/菜单
 * - 右侧显示详情内容
 * - 支持动态调整分割比例
 * - 自动适配折叠/展开状态
 * 
 * @since 4.0.0
 */

import { displayHelper, FoldStatus } from '../../common/utils/DisplayHelper';
import { DeviceUtils } from '../../common/utils/DeviceUtils';
import { BookInfo } from '../../core/models/CoreBookModel';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { tr } from '../../core/utils/LocalizationUtil';

/**
 * 平行视界配置
 */
export interface ParallelViewConfig {
  /** 左侧面板宽度比例 (0.3-0.7) */
  leftRatio: number;
  /** 是否显示分割线 */
  showDivider: boolean;
  /** 分割线颜色 */
  dividerColor?: string;
  /** 是否允许拖拽调整宽度 */
  resizable: boolean;
  /** 最小左侧宽度(vp) */
  minLeftWidth: number;
  /** 最大左侧宽度(vp) */
  maxLeftWidth: number;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: ParallelViewConfig = {
  leftRatio: 0.4,
  showDivider: true,
  dividerColor: '#E0E0E0',
  resizable: true,
  minLeftWidth: 280,
  maxLeftWidth: 600
};

@ComponentV2
export struct ParallelView {
  // 配置
  @Param config: ParallelViewConfig = DEFAULT_CONFIG;
  @Param isDarkMode: boolean = false;
  
  // 状态
  @Local leftWidth: number = 0;
  @Local rightWidth: number = 0;
  @Local containerWidth: number = 0;
  @Local isDragging: boolean = false;
  
  // 折叠状态
  @Local foldStatus: FoldStatus = FoldStatus.UNKNOWN;
  @Local shouldShowParallel: boolean = false;
  
  // 内容构建器
  @BuilderParam leftContent: () => void;
  @BuilderParam rightContent: () => void;
  @BuilderParam emptyRight?: () => void;
  
  // 回调
  onLayoutChange?: (layout: 'single' | 'parallel') => void;
  
  private dragStartX: number = 0;
  private dragStartWidth: number = 0;

  aboutToAppear(): void {
    this.updateLayout();
    this.foldStatus = displayHelper.getFoldStatus();
    
    // 监听窗口大小变化
    const context = this.getUIContext().getHostContext();
    if (context) {
      window.getLastWindow(context).then((win: window.Window) => {
        win.on('windowSizeChange', (size: window.Size) => {
          this.updateLayout();
        });
      }).catch((err: Error) => {
        console.error('[ParallelView] Failed to get window:', err.message);
      });
    }
  }

  /**
   * 更新布局状态
   */
  private updateLayout(): void {
    const layout: 'single' | 'dual' | 'triple' = displayHelper.getRecommendedLayout();
    this.shouldShowParallel = layout === 'dual' || layout === 'triple';
    this.foldStatus = displayHelper.getFoldStatus();
    
    // 计算宽度
    if (this.containerWidth > 0) {
      this.leftWidth = Math.floor(this.containerWidth * this.config.leftRatio);
      this.rightWidth = this.containerWidth - this.leftWidth;
    }
    
    // 通知布局变化
    if (this.onLayoutChange) {
      this.onLayoutChange(this.shouldShowParallel ? 'parallel' : 'single');
    }
  }

  /**
   * 处理拖拽开始
   */
  private handleDragStart(event: GestureEvent): void {
    if (!this.config.resizable) return;
    
    this.isDragging = true;
    this.dragStartX = event.offsetX;
    this.dragStartWidth = this.leftWidth;
  }

  /**
   * 处理拖拽中
   */
  private handleDragUpdate(event: GestureEvent): void {
    if (!this.isDragging) return;
    
    const deltaX = event.offsetX - this.dragStartX;
    let newWidth = this.dragStartWidth + deltaX;
    
    // 限制范围
    newWidth = Math.max(this.config.minLeftWidth, newWidth);
    newWidth = Math.min(this.config.maxLeftWidth, newWidth);
    newWidth = Math.min(newWidth, this.containerWidth - 200); // 右侧至少200vp
    
    this.leftWidth = newWidth;
    this.rightWidth = this.containerWidth - newWidth;
  }

  /**
   * 处理拖拽结束
   */
  private handleDragEnd(): void {
    this.isDragging = false;
  }

  build() {
    if (!this.shouldShowParallel) {
      // 单栏模式 - 只显示左侧内容
      Column() {
        this.leftContent()
      }
      .width('100%')
      .height('100%')
    } else {
      // 平行视界模式 - 左右分栏
      Row() {
        // 左侧面板
        Column() {
          this.leftContent()
        }
        .width(this.leftWidth)
        .height('100%')
        .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
        
        // 分割线(可拖拽)
        if (this.config.showDivider) {
          Column()
            .width(2)
            .height('100%')
            .backgroundColor(this.isDragging ? '#007DFF' : (this.config.dividerColor || (this.isDarkMode ? '#333333' : '#E0E0E0')))

            .gesture(
              PanGesture({ direction: PanDirection.Horizontal })
                .onActionStart((event: GestureEvent): void => this.handleDragStart(event))
                .onActionUpdate((event: GestureEvent): void => this.handleDragUpdate(event))
                .onActionEnd((): void => this.handleDragEnd())
            )
        }
        
        // 右侧面板
        Column() {
          if (this.emptyRight) {
            this.emptyRight()
          } else {
            this.rightContent()
          }
        }
        .layoutWeight(1)
        .height('100%')
        .backgroundColor(this.isDarkMode ? '#0F0F10' : '#F5F5F7')
      }
      .width('100%')
      .height('100%')
      .onAreaChange((oldValue: Area, newValue: Area): void => {
        this.containerWidth = Number(newValue.width);
        this.updateLayout();
      })
    }
  }
}

// ==================== 预设平行视界模板 ====================

/**
 * 书架平行视界
 * 左侧: 书籍列表/分组
 * 右侧: 书籍详情/阅读器
 */
@Component
export struct BookshelfParallelView {
  @Prop selectedBookId: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop books: BookInfo[] = [];
  
  onBookSelect?: (bookId: string) => void;
  @BuilderParam bookListContent: () => void;
  @BuilderParam bookDetailContent: (bookId: string) => void;

  build() {
    ParallelView({
      isDarkMode: this.isDarkMode,
      config: {
        leftRatio: 0.35,
        showDivider: true,
        resizable: true,
        minLeftWidth: 280,
        maxLeftWidth: 450
      },
      leftContent: () => {
        this.bookListContent()
      },
      rightContent: () => {
        if (this.selectedBookId) {
          this.bookDetailContent(this.selectedBookId)
        } else {
          this.EmptyDetail()
        }
      }
    })
  }

  @Builder
  EmptyDetail() {
    Column() {
      SymbolGlyph($r('sys.symbol.books_vertical_fill'))
        .fontSize(64)
        .fontColor([this.isDarkMode ? '#888888' : '#999999'])
      Text(tr('select_book_start'))
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 设置平行视界
 * 左侧: 设置分类
 * 右侧: 设置详情
 */
@Component
export struct SettingsParallelView {
  @Prop selectedCategory: string = '';
  @Prop isDarkMode: boolean = false;
  
  @BuilderParam categoryList: () => void;
  @BuilderParam settingDetail: (category: string) => void;

  build() {
    ParallelView({
      isDarkMode: this.isDarkMode,
      config: {
        leftRatio: 0.3,
        showDivider: true,
        resizable: false,
        minLeftWidth: 240,
        maxLeftWidth: 320
      },
      leftContent: () => {
        this.categoryList()
      },
      rightContent: () => {
        if (this.selectedCategory) {
          this.settingDetail(this.selectedCategory)
        } else {
          this.EmptySettings()
        }
      }
    })
  }

  @Builder
  EmptySettings() {
    Column() {
      SymbolGlyph($r('sys.symbol.gearshape_2'))
        .fontSize(64)
        .fontColor([this.isDarkMode ? '#888888' : '#999999'])
      Text(tr('select_settings_category'))
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 搜索平行视界
 * 左侧: 搜索结果列表
 * 右侧: 结果详情预览
 */
@Component
export struct SearchParallelView {
  @Prop selectedResultId: string = '';
  @Prop isDarkMode: boolean = false;
  @Prop results: object[] = [];
  
  @BuilderParam resultList: () => void;
  @BuilderParam resultPreview: (resultId: string) => void;

  build() {
    ParallelView({
      isDarkMode: this.isDarkMode,
      config: {
        leftRatio: 0.45,
        showDivider: true,
        resizable: true,
        minLeftWidth: 300,
        maxLeftWidth: 500
      },
      leftContent: () => {
        this.resultList()
      },
      rightContent: () => {
        if (this.selectedResultId) {
          this.resultPreview(this.selectedResultId)
        } else {
          this.EmptySearch()
        }
      }
    })
  }

  @Builder
  EmptySearch() {
    Column() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(64)
        .fontColor([this.isDarkMode ? '#888888' : '#999999'])
      Text(tr('click_view_details'))
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#888888' : '#999999')
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
