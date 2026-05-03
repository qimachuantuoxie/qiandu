/**
 * 图片查看器组件 - 支持缩放、拖动、双击放大
 * Image Viewer Component - Supports Zoom, Pan, Double-tap
 */

import { router } from '@kit.ArkUI';
import { COMMON_COLORS } from '../utils/AppTheme';

@Component
export struct ImageViewer {
  // 图片路径
  @Prop imagePath: string = '';
  // 是否深色模式
  @Prop isDarkMode: boolean = false;
  // 图片列表（用于多图浏览）
  @Prop imageList: string[] = [];
  // 当前图片索引
  @State currentIndex: number = 0;
  // 缩放比例
  @State scale: number = 1.0;
  // 偏移量
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  // 是否显示控制栏
  @State showControls: boolean = true;
  // 加载状态
  @State isLoading: boolean = true;
  // 加载失败
  @State loadError: boolean = false;

  // 缩放手势
  private lastScaleDistance: number = 0;
  private lastScale: number = 1.0;

  // 双击计时器
  private lastTapTime: number = 0;

  build() {
    Stack() {
      // 图片显示区域
      Column() {
        if (this.isLoading) {
          // 加载占位
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(COMMON_COLORS.PRIMARY_BLUE)

            Text('加载中...')
              .fontSize(14)
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.loadError) {
          // 错误占位
          Column() {
            Text('🖼️')
              .fontSize(64)

            Text('图片加载失败')
              .fontSize(14)
              .fontColor(this.isDarkMode ? '#AAAAAA' : '#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          // 图片显示
          this.ImageContent()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
      // 点击图片隐藏/显示控制栏
      .onClick(() => {
        this.showControls = !this.showControls;
      })

      // 顶部控制栏
      if (this.showControls) {
        this.TopBar()
      }

      // 底部控制栏
      if (this.showControls) {
        this.BottomBar()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ImageContent() {
    Image(this.imagePath)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Contain)
      .scale({ x: this.scale, y: this.scale })
      .translate({ x: this.offsetX, y: this.offsetY })
      // 图片加载成功
      .onComplete(() => {
        this.isLoading = false;
        this.loadError = false;
      })
      // 图片加载失败
      .onError(() => {
        this.isLoading = false;
        this.loadError = true;
      })
      // 缩放手势
      .gesture(
        PinchGesture({ fingers: 2 })
          .onActionStart((event: PinchGestureEvent) => {
            this.lastScaleDistance = event.pinchDistance;
            this.lastScale = this.scale;
          })
          .onActionUpdate((event: PinchGestureEvent) => {
            const delta = event.pinchDistance - this.lastScaleDistance;
            const newScale = this.lastScale * (1 + delta / 200);
            this.scale = Math.max(0.5, Math.min(5.0, newScale));
          })
      )
      // 拖动手势
      .gesture(
        PanGesture({ fingers: 1 })
          .onActionUpdate((event: GestureEvent) => {
            if (this.scale > 1.0) {
              this.offsetX += event.offsetX;
              this.offsetY += event.offsetY;
            }
          })
          .onActionEnd(() => {
            // 松开时如果缩放比例接近1则重置
            if (this.scale < 1.1) {
              this.scale = 1.0;
              this.offsetX = 0;
              this.offsetY = 0;
            }
          })
      )
      // 双击放大/缩小
      .gesture(
        TapGesture({ count: 2 })
          .onAction((event: GestureEvent) => {
            if (this.scale > 1.0) {
              // 缩小到原始大小
              this.scale = 1.0;
              this.offsetX = 0;
              this.offsetY = 0;
            } else {
              // 放大到2倍
              this.scale = 2.0;
            }
          })
      )
  }

  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Button() {
        Text('←')
          .fontSize(28)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor('rgba(0,0,0,0.5)')
      .borderRadius(22)
      .onClick(() => {
        // 返回上一页
        router.back();
      })

      // 图片计数
      if (this.imageList.length > 1) {
        Text((this.currentIndex + 1) + ' / ' + this.imageList.length)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        Blank()
          .layoutWeight(1)
      }

      // 更多操作
      Button() {
        Text('⋯')
          .fontSize(20)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .backgroundColor('rgba(0,0,0,0.5)')
      .borderRadius(22)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('rgba(0,0,0,0.3)')
  }

  @Builder
  BottomBar() {
    Row() {
      // 上一张
      if (this.currentIndex > 0) {
        Button() {
          Text('←')
            .fontSize(32)
            .fontColor('#FFFFFF')
        }
        .width(48)
        .height(48)
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(24)
        .onClick(() => {
          this.currentIndex--;
          this.imagePath = this.imageList[this.currentIndex];
          this.resetZoom();
        })
      }

      Blank()

      // 缩放控制
      Row({ space: 16 }) {
        Button('-')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .width(40)
          .height(40)
          .backgroundColor('rgba(0,0,0,0.5)')
          .borderRadius(20)
          .onClick(() => {
            this.scale = Math.max(0.5, this.scale - 0.25);
            if (this.scale <= 1.0) {
              this.offsetX = 0;
              this.offsetY = 0;
            }
          })

        Text((this.scale * 100).toFixed(0) + '%')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .width(60)
          .textAlign(TextAlign.Center)

        Button('+')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .width(40)
          .height(40)
          .backgroundColor('rgba(0,0,0,0.5)')
          .borderRadius(20)
          .onClick(() => {
            this.scale = Math.min(5.0, this.scale + 0.25);
          })
      }

      Blank()

      // 下一张
      if (this.currentIndex < this.imageList.length - 1) {
        Button() {
          Text('→')
            .fontSize(32)
            .fontColor('#FFFFFF')
        }
        .width(48)
        .height(48)
        .backgroundColor('rgba(0,0,0,0.5)')
        .borderRadius(24)
        .onClick(() => {
          this.currentIndex++;
          this.imagePath = this.imageList[this.currentIndex];
          this.resetZoom();
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('rgba(0,0,0,0.3)')
  }

  /**
   * 重置缩放
   */
  private resetZoom(): void {
    this.scale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
    this.isLoading = true;
    this.loadError = false;
  }
}
