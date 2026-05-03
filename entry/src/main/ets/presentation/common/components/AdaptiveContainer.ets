/**
 * 自适应布局容器
 * 自动处理 手机(单列) -> 平板(双列) -> PC/折叠屏(三列) 的切换
 * 支持侧边栏 (Side Panel) 和详情栏 (Detail Panel) 的响应式显隐
 */

interface SpaceConfig {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface RadiusConfig {
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface ColorConfig {
  primary: string;
  error: string;
  bgSurfaceDark: string;
  bgMain: string;
  bgMainDark: string;
  bgSurface: string;
}

// 常量定义
const SPACE: SpaceConfig = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32
};

const RADIUS: RadiusConfig = {
  sm: 4,
  md: 8,
  lg: 16,
  xl: 24
};

const COLORS: ColorConfig = {
  primary: '#007DFF',
  error: '#FF3B30',
  bgSurfaceDark: '#1C1C1E',
  bgMain: '#F5F5F5',
  bgMainDark: '#000000',
  bgSurface: '#FFFFFF'
};

@Component
export struct AdaptiveContainer {
  @BuilderParam content: () => void;
  @BuilderParam sidePanel?: () => void;
  @BuilderParam detailPanel?: () => void;

  @State currentBreakpoint: string = 'sm';
  @State isDarkMode: boolean = false;

  build() {
    Column() {
      GridRow({
        columns: { sm: 12, md: 12, lg: 12 },
        gutter: SPACE.md,
        breakpoints: {
          value: ['320vp', '600vp', '840vp'],
          reference: BreakpointsReference.WindowSize
        }
      }) {
        // 侧边栏 (平板/PC 显示，手机隐藏)
        if (this.sidePanel && this.currentBreakpoint !== 'sm') {
          GridCol({
            span: { sm: 0, md: 4, lg: 3 }
          }) {
            Column() {
              this.sidePanel()
            }
            .width('100%')
            .height('100%')
            .padding(SPACE.md)
            .backgroundColor(this.isDarkMode ? COLORS.bgSurfaceDark : COLORS.bgMain)
            .borderRadius(RADIUS.lg)
            .border({
              width: { right: 1 },
              color: this.isDarkMode ? '#333' : '#E5E5EA'
            })
          }
        }

        // 主内容区 (全机型显示)
        GridCol({ span: this.getSpanOption() }) {
          Column() {
            this.content()
          }
          .width('100%')
          .height('100%')
        }

        // 详情栏 (仅 PC/大屏 显示)
        if (this.detailPanel && this.currentBreakpoint === 'lg') {
          GridCol({
            span: 3
          }) {
            Column() {
              this.detailPanel()
            }
            .width('100%')
            .height('100%')
            .padding(SPACE.md)
            .backgroundColor(this.isDarkMode ? COLORS.bgSurfaceDark : COLORS.bgMain)
            .borderRadius(RADIUS.lg)
            .border({
              width: { left: 1 },
              color: this.isDarkMode ? '#333' : '#E5E5EA'
            })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .onBreakpointChange((breakpoint: string) => {
        this.currentBreakpoint = breakpoint;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? COLORS.bgMainDark : COLORS.bgSurface)
  }

  private getSpanOption(): number {
    return this.getMainContentSpan();
  }

  private getMainContentSpan(): number {
    if (this.currentBreakpoint === 'sm') {
      return 12;
    }
    if (this.currentBreakpoint === 'md') {
      return this.sidePanel ? 8 : 12;
    }
    return this.sidePanel ? (this.detailPanel ? 6 : 9) : 12;
  }
}
