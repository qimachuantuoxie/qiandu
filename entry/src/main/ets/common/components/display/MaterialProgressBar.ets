/**
 * 自写 Material 风格进度条组件
 * 仿 MaterialProgressBar 效果，无外部依赖
 * 支持线性/环形、颜色、二级进度、渐变等
 */

import { COMMON_COLORS } from '../../common/constants/AppTheme';

export interface MaterialModel {
  progress?: number;        // 进度 0-100
  secondProgress?: number;   // 二级进度 0-100
  color?: string;           // 主进度颜色
  secondColor?: string;     // 二级进度颜色
  bgColor?: string;         // 背景颜色
  strokeWidth?: number;     // 线条宽度
  radius?: number;          // 环形半径（仅圆形）
  indeterminate?: boolean;   // 是否不确定模式（旋转动画）
  isPocket?: boolean;       // 是否口袋样式（方形端点）
  isReversed?: boolean;     // 是否反向
  isMirror?: boolean;       // 是否镜像
  isGradients?: boolean;    // 是否渐变
  speed?: number;           // 动画速度
  colors?: number[];        // 渐变颜色数组
  separatorLength?: number;  // 间距（口袋样式）
  active?: boolean;         // 是否启用动画
}

@ComponentV2
export struct MaterialProgressBar {
  @Param style: 'MaterialCircular' | 'MaterialHorizontal' | 'SmoothCircular' | 'SmoothHorizontal' = 'MaterialHorizontal';
  @Param modelBuild?: MaterialModel;

  private progressValue: number = 0;
  private secondProgressValue: number = 0;
  private animatedValue: number = 0;
  private indeterminateAngle: number = 0;
  private timer: number = -1;

  aboutToAppear() {
    this.updateValues();
    this.startAnimation();
  }

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private updateValues(): void {
    if (this.modelBuild) {
      this.progressValue = this.modelBuild.progress !== undefined ? this.modelBuild.progress : 0;
      this.secondProgressValue = this.modelBuild.secondProgress !== undefined ? this.modelBuild.secondProgress : 0;
    }
  }

  private startAnimation(): void {
    if (this.modelBuild && this.modelBuild.indeterminate) {
      this.timer = setInterval(() => {
        this.indeterminateAngle = (this.indeterminateAngle + 5) % 360;
      }, 50) as unknown as number;
    }
    if (this.modelBuild && this.modelBuild.active && !this.modelBuild.indeterminate) {
      this.timer = setInterval(() => {
        this.animatedValue = (this.animatedValue + 1) % 101;
      }, 30) as unknown as number;
    }
  }

  build() {
    if (this.style === 'MaterialCircular' || this.style === 'SmoothCircular') {
      this.buildCircular();
    } else {
      this.buildLinear();
    }
  }

  @Builder
  private buildCircular() {
    const radius = this.modelBuild?.radius || 50;
    const strokeWidth = this.modelBuild?.strokeWidth || 8;
    const color = this.modelBuild?.color || COMMON_COLORS.PRIMARY_BLUE;
    const bgColor = this.modelBuild?.bgColor || 'rgba(0,0,0,0.05)';
    const progress = this.modelBuild?.indeterminate ? 75 : (this.animatedValue || this.progressValue);
    const startAngle = this.modelBuild?.indeterminate ? this.indeterminateAngle : 0;
    const sweepAngle = (progress / 100) * 360;
    const isSmooth = this.style === 'SmoothCircular';

    Stack() {
      // 背景圆
      Circle()
        .width(radius * 2)
        .height(radius * 2)
        .stroke(bgColor)
        .strokeWidth(strokeWidth)
        .fill('transparent')

      // 进度圆弧
      if (progress > 0) {
        Circle()
          .width(radius * 2)
          .height(radius * 2)
          .stroke(color)
          .strokeWidth(strokeWidth)
          .fill('transparent')
          .startAngle(startAngle)
          .sweepAngle(isSmooth ? sweepAngle * 1.2 : sweepAngle)
          .antiAlias(true)
      }
    }
    .width(radius * 2)
    .height(radius * 2)
  }

  @Builder
  private buildLinear() {
    const strokeWidth = this.modelBuild?.strokeWidth || 8;
    const color = this.modelBuild?.color || COMMON_COLORS.PRIMARY_BLUE;
    const secondColor = this.modelBuild?.secondColor || color;
    const bgColor = this.modelBuild?.bgColor || 'rgba(0,0,0,0.05)';
    const progress = this.modelBuild?.indeterminate ? 60 : (this.animatedValue || this.progressValue);
    const secondProgress = this.secondProgressValue;
    const isPocket = this.modelBuild?.isPocket || false;
    const separatorLength = this.modelBuild?.separatorLength || 4;
    const progressWidth = `${progress}%`;
    const secondWidth = `${secondProgress}%`;
    const isSmooth = this.style === 'SmoothHorizontal';

    Column() {
      // 背景
      Row()
        .width('100%')
        .height(strokeWidth)
        .backgroundColor(bgColor)
        .borderRadius(isPocket ? 0 : strokeWidth / 2)

      // 二级进度
      if (secondProgress > 0) {
        Row()
          .width(secondWidth)
          .height(strokeWidth)
          .backgroundColor(secondColor)
          .borderRadius(isPocket ? 0 : strokeWidth / 2)
          .position({ x: 0, y: 0 })
      }

      // 主进度
      if (progress > 0) {
        Row()
          .width(progressWidth)
          .height(strokeWidth)
          .backgroundColor(color)
          .borderRadius(isPocket ? 0 : strokeWidth / 2)
          .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height(strokeWidth)
    .positionRelative()
    .borderRadius(isPocket ? 0 : strokeWidth / 2)
    .clipContent(isPocket)
  }
}
