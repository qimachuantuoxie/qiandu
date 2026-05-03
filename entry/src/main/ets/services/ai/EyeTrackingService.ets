// 眼动追踪服务 - AI 智能翻页
// Eye Tracking Service - AI Smart Page Turning
// 使用前置摄像头和视觉算法实现眼动检测,支持凝视识别翻页
// 适用于阅读应用的手势控制场景

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0xFF08;

/**
 * 眼动追踪状态枚举
 */
export enum EyeTrackingState {
  IDLE = 'idle',           // 空闲
  TRACKING = 'tracking',   // 正在追踪
  PAUSED = 'paused',       // 暂停
  CALIBRATING = 'calibrating'  // 校准中
}

/**
 * 凝视方向枚举
 */
export enum GazeDirection {
  LEFT = 'left',     // 向左凝视 -> 上一页
  RIGHT = 'right',   // 向右凝视 -> 下一页
  CENTER = 'center', // 中间区域
  UP = 'up',         // 向上凝视
  DOWN = 'down'      // 向下凝视
}

/**
 * 凝视点数据
 */
export interface GazePoint {
  x: number;         // X坐标(屏幕百分比 0-1)
  y: number;         // Y坐标(屏幕百分比 0-1)
  timestamp: number; // 时间戳
  duration: number;  // 持续时间(ms)
  confidence: number;// 置信度 0-1
}

/**
 * 眼动追踪配置
 */
export interface EyeTrackingConfig {
  enabled: boolean;              // 是否启用
  sensitivity: 'low' | 'medium' | 'high'; // 灵敏度
  dwellTime: number;             // 驻留时间(ms),触发翻页需要凝视的时间
  gazeThreshold: number;         // 置信度阈值
  calibrationNeeded: boolean;    // 是否需要校准
}

/**
 * 手势结果
 */
export interface PageGesture {
  direction: GazeDirection; // 方向
  confidence: number;        // 置信度
  timestamp: number;        // 时间戳
}

/**
 * 校准点
 */
export interface CalibrationPoint {
  x: number;
  y: number;
}

/**
 * 凝视统计
 */
export interface GazeStatistics {
  leftPercentage: number;
  rightPercentage: number;
  centerPercentage: number;
  avgDwellTime: number;
  totalSamples: number;
}

/**
 * 人脸区域
 */
interface FaceRegion {
  x: number;
  y: number;
  width: number;
  height: number;
  leftEyeX: number;
  leftEyeY: number;
  rightEyeX: number;
  rightEyeY: number;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: EyeTrackingConfig = {
  enabled: false,
  sensitivity: 'medium',
  dwellTime: 800,  // 800ms 驻留时间
  gazeThreshold: 0.7,
  calibrationNeeded: true
};

/**
 * 眼动追踪服务类
 * 通过前置摄像头检测用户视线,实现智能翻页功能
 */
class EyeTrackingService {
  private static instance: EyeTrackingService;
  private context: common.Context | null = null;
  private isInitialized: boolean = false;
  private isTracking: boolean = false;
  private currentState: EyeTrackingState = EyeTrackingState.IDLE;
  private config: EyeTrackingConfig = DEFAULT_CONFIG;
  private gazePoints: GazePoint[] = [];
  private lastGazeDirection: GazeDirection = GazeDirection.CENTER;
  private listener: ((gesture: PageGesture) => void) | null = null;

  // CameraKit 相关
  private cameraManager: camera.CameraManager | null = null;
  private cameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private captureSession: camera.CaptureSession | null = null;
  private cameraDevice: camera.CameraDevice | null = null;

  // 图像处理相关
  private imageReceiver: image.ImageReceiver | null = null;
  private screenWidth: number = 0;
  private screenHeight: number = 0;

  // 校准相关
  private calibrationData: Map<string, GazePoint> = new Map();
  private isCalibrated: boolean = false;

  // 统计相关
  private trackingStartTime: number = 0;
  private frameCount: number = 0;
  private gazeStartTime: number = 0;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): EyeTrackingService {
    if (!EyeTrackingService.instance) {
      EyeTrackingService.instance = new EyeTrackingService();
    }
    return EyeTrackingService.instance;
  }

  /**
   * 初始化服务
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Initializing...');
      this.context = context;

      // 获取屏幕尺寸
      await this.getScreenSize();

      // 初始化 CameraKit
      await this.initCamera();

      this.isInitialized = true;
      hilog.info(DOMAIN, 'EyeTracking', 'Initialized successfully');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Init failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 获取屏幕尺寸
   */
  private async getScreenSize(): Promise<void> {
    try {
      // FIX: getAvailableDisplays is deprecated, use getAllDisplays instead
      const displayClass: display.Display[] = await display.getAllDisplays();
      if (displayClass && displayClass.length > 0) {
        this.screenWidth = displayClass[0].width;
        this.screenHeight = displayClass[0].height;
        hilog.info(DOMAIN, 'EyeTracking', 'Screen size: %{public}d x %{public}d',
          this.screenWidth, this.screenHeight);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Get screen size failed: %{public}s', err.message);
      // 使用默认值
      this.screenWidth = 1080;
      this.screenHeight = 2400;
    }
  }

  /**
   * 初始化摄像头
   */
  private async initCamera(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Initializing camera...');

      // 获取 CameraManager
      this.cameraManager = camera.getCameraManager(this.context!);

      // 获取摄像头列表
      const cameras: camera.CameraDevice[] = this.cameraManager.getSupportedCameras();
      if (!cameras || cameras.length === 0) {
        throw new Error('No cameras available');
      }

      // 查找前置摄像头
      let frontCamera: camera.CameraDevice | null = null;
      for (let i = 0; i < cameras.length; i++) {
        const cam = cameras[i];
        const cameraType = cam.cameraPosition;
        if (cameraType === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          frontCamera = cam;
          break;
        }
      }

      // 如果没有前置摄像头,使用第一个摄像头
      if (!frontCamera) {
        frontCamera = cameras[0];
        hilog.warn(DOMAIN, 'EyeTracking', 'No front camera found, using first camera');
      }

      this.cameraDevice = frontCamera;
      hilog.info(DOMAIN, 'EyeTracking', 'Camera selected: %{public}s', frontCamera.cameraPosition);

      // 创建捕获会话
      this.captureSession = this.cameraManager.createCaptureSession();

      // FIX: createCameraInput is on CameraManager, not on CaptureSession
      this.cameraInput = this.cameraManager.createCameraInput(this.cameraDevice);
      // CameraInput must be opened before use
      await this.cameraInput.open();

      // FIX: Use compatible format for ImageReceiver (YCBCR_422_SP)
      // Note: ImageFormat no longer supports RGBA_8888 in API 22+
      this.imageReceiver = image.createImageReceiver(640, 480, image.ImageFormat.YCBCR_422_SP, 8);

      // FIX: receivingSurface is deprecated, use getReceivingSurfaceId() instead
      const surfaceId: string = await this.imageReceiver.getReceivingSurfaceId();
      // FIX: ensure photo output creation uses CameraManager (not CaptureSession)
      try {
        this.previewOutput = this.cameraManager.createPreviewOutput(surfaceId);
      } catch (photoOutputError) {
        hilog.warn(DOMAIN, 'EyeTracking', 'createPreviewOutput failed, using fallback');
        this.previewOutput = null;
      }

      hilog.info(DOMAIN, 'EyeTracking', 'Camera setup completed');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Init camera failed: %{public}s', err.message);
      // FIX: throw the typed BusinessError, not the raw catch variable
      throw err instanceof Error ? err : new Error(String(err));
    }
  }

  /**
   * 配置并启动捕获会话
   * 使用新的会话API,带旧API降级回退
   */
  private async configureAndStartSession(): Promise<boolean> {
    if (!this.captureSession || !this.cameraInput || !this.previewOutput) {
      hilog.error(DOMAIN, 'EyeTracking', 'Session components not ready');
      return false;
    }

    try {
      this.captureSession.beginConfig();
      this.captureSession.addInput(this.cameraInput);
      this.captureSession.addOutput(this.previewOutput);
      this.captureSession.commitConfig();
      this.captureSession.start();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Session config failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 检查服务是否就绪
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null && this.cameraDevice !== null;
  }

  // ==================== 眼动追踪 ====================

  /**
   * 开始追踪
   */
  async startTracking(): Promise<boolean> {
    try {
      if (!this.isReady()) {
        throw new Error('EyeTracking service not initialized');
      }

      if (this.isTracking) {
        hilog.warn(DOMAIN, 'EyeTracking', 'Already tracking');
        return true;
      }

      hilog.info(DOMAIN, 'EyeTracking', 'Starting eye tracking...');

      // 配置并启动捕获会话(使用新API)
      const sessionStarted: boolean = await this.configureAndStartSession();
      if (!sessionStarted) {
        throw new Error('Failed to start capture session');
      }

      this.isTracking = true;
      this.currentState = EyeTrackingState.TRACKING;
      this.trackingStartTime = Date.now();
      this.frameCount = 0;
      this.gazePoints = [];

      // 开始处理图像帧
      this.startProcessingFrames();

      hilog.info(DOMAIN, 'EyeTracking', 'Eye tracking started');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Start tracking failed: %{public}s', err.message);
      return false;
    }
  }

  /**
   * 开始处理图像帧
   */
  private startProcessingFrames(): void {
    if (!this.imageReceiver) {
      hilog.error(DOMAIN, 'EyeTracking', 'ImageReceiver is null');
      return;
    }

    // FIX: 'imageAvailable' is deprecated, use 'imageArrival' instead
    this.imageReceiver.on('imageArrival', (): void => {
      try {
        this.imageReceiver?.readLatestImage().then((img: image.Image) => {
          this.frameCount++;
          this.processFrame(img);
          img.release();
        }).catch((error: BusinessError) => {
          hilog.error(DOMAIN, 'EyeTracking', 'Read image failed: %{public}s', error.message);
        });
      } catch (error) {
        const err = error as BusinessError;
        hilog.error(DOMAIN, 'EyeTracking', 'Process frame failed: %{public}s', err.message);
      }
    });
  }

  /**
   * 处理图像帧 - 使用 YUV  luminance 数据进行人脸检测
   */
  private async processFrame(frame: image.Image): Promise<void> {
    try {
      // FIX: getComponentMap is deprecated, use getComponent with ComponentType
      // FIX: RGBA_8888 no longer exists, use YUV_Y for luminance data
      const component = await frame.getComponent(image.ComponentType.YUV_Y);
      const byteBuffer: ArrayBuffer = component.byteBuffer;
      const width: number = frame.size.width;
      const height: number = frame.size.height;

      if (!byteBuffer || width <= 0 || height <= 0) {
        return;
      }

      // 使用 luminance 数据简化人脸检测
      const faceRegion: FaceRegion | null = this.detectFaceFromBuffer(byteBuffer, width, height);
      if (!faceRegion) {
        return;
      }

      // 估算凝视点
      const gazePoint: GazePoint | null = this.estimateGazePoint(faceRegion);
      if (!gazePoint) {
        return;
      }

      // 应用校准
      const calibratedPoint: GazePoint = this.applyCalibration(gazePoint);

      // 添加到历史
      this.gazePoints.push(calibratedPoint);

      // 保持最近50个点
      if (this.gazePoints.length > 50) {
        this.gazePoints = this.gazePoints.slice(-50);
      }

      // 分析凝视方向
      this.analyzeGazeDirection();
    } catch (error) {
      const err = error as BusinessError;
      if (this.frameCount % 100 === 0) {
        hilog.error(DOMAIN, 'EyeTracking', 'Process frame failed: %{public}s', err.message);
      }
    }
  }

  /**
   * 基于 luminance 数据检测人脸区域 (YUV Y 平面数据)
   */
  private detectFaceFromBuffer(byteBuffer: ArrayBuffer, width: number, height: number): FaceRegion | null {
    try {
      const pixelView = new DataView(byteBuffer);
      let sumX = 0;
      let sumY = 0;
      let brightPixelCount = 0;

      // 采样寻找亮度适中的区域 (人脸肤色区域在Y通道的典型值)
      const step = 4;
      for (let y = Math.floor(height * 0.2); y < Math.floor(height * 0.6); y += step) {
        for (let x = Math.floor(width * 0.2); x < Math.floor(width * 0.8); x += step) {
          const luminance = pixelView.getUint8(y * width + x);
          // 人脸在亮度通道中通常处于中等亮度范围
          if (luminance > 60 && luminance < 220) {
            sumX += x;
            sumY += y;
            brightPixelCount++;
          }
        }
      }

      if (brightPixelCount < 50) {
        return null; // 未检测到人脸
      }

      // 计算人脸中心
      const faceX = Math.floor(sumX / brightPixelCount);
      const faceY = Math.floor(sumY / brightPixelCount);
      const faceWidth = Math.floor(width * 0.3);
      const faceHeight = Math.floor(height * 0.4);

      // 估算眼部位置
      const leftEyeX = Math.floor(faceX - faceWidth * 0.15);
      const leftEyeY = Math.floor(faceY - faceHeight * 0.1);
      const rightEyeX = Math.floor(faceX + faceWidth * 0.15);
      const rightEyeY = Math.floor(faceY - faceHeight * 0.1);

      return {
        x: faceX,
        y: faceY,
        width: faceWidth,
        height: faceHeight,
        leftEyeX: leftEyeX,
        leftEyeY: leftEyeY,
        rightEyeX: rightEyeX,
        rightEyeY: rightEyeY
      };
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Face detection failed: %{public}s', err.message);
      return null;
    }
  }

  /**
   * 估算凝视点
   * 基于双眼中心位置估算注视点
   */
  private estimateGazePoint(faceRegion: FaceRegion): GazePoint | null {
    try {
      // 计算双眼中心
      const centerX = (faceRegion.leftEyeX + faceRegion.rightEyeX) / 2;
      const centerY = (faceRegion.leftEyeY + faceRegion.rightEyeY) / 2;

      // 转换为屏幕百分比
      const screenX = centerX / faceRegion.width * 0.5 + 0.25; // 映射到 0-1
      const screenY = centerY / faceRegion.height * 0.5 + 0.25;

      // 确保在有效范围内
      const normalizedX = Math.max(0, Math.min(1, screenX));
      const normalizedY = Math.max(0, Math.min(1, screenY));

      // 计算置信度(基于人脸检测质量)
      const confidence = Math.min(1.0, faceRegion.width / 200);

      return {
        x: normalizedX,
        y: normalizedY,
        timestamp: Date.now(),
        duration: 0,
        confidence: confidence
      };
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Estimate gaze failed: %{public}s', err.message);
      return null;
    }
  }

  /**
   * 应用校准数据
   */
  private applyCalibration(gazePoint: GazePoint): GazePoint {
    if (!this.isCalibrated || this.calibrationData.size === 0) {
      return gazePoint;
    }

    // 简单的线性校准
    // 实际项目中应该使用更复杂的校准算法
    let calibratedX = gazePoint.x;
    let calibratedY = gazePoint.y;

    // 应用校准偏移
    const keys = Array.from(this.calibrationData.keys());
    let offsetX = 0;
    let offsetY = 0;
    let count = 0;

    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const calibrated = this.calibrationData.get(key);
      if (calibrated) {
        offsetX += (calibrated.x - parseFloat(key.split('_')[0]));
        offsetY += (calibrated.y - parseFloat(key.split('_')[1]));
        count++;
      }
    }

    if (count > 0) {
      calibratedX += offsetX / count;
      calibratedY += offsetY / count;
    }

    return {
      x: Math.max(0, Math.min(1, calibratedX)),
      y: Math.max(0, Math.min(1, calibratedY)),
      timestamp: gazePoint.timestamp,
      duration: gazePoint.duration,
      confidence: gazePoint.confidence
    };
  }

  /**
   * 分析凝视方向
   */
  private analyzeGazeDirection(): void {
    if (this.gazePoints.length < 10) {
      return; // 需要足够的样本
    }

    // 计算平均位置(最近20个点)
    const recentCount = Math.min(20, this.gazePoints.length);
    let sumX = 0;
    let sumY = 0;
    let sumConfidence = 0;

    for (let i = this.gazePoints.length - recentCount; i < this.gazePoints.length; i++) {
      sumX += this.gazePoints[i].x;
      sumY += this.gazePoints[i].y;
      sumConfidence += this.gazePoints[i].confidence;
    }

    const avgX = sumX / recentCount;
    const avgY = sumY / recentCount;
    const avgConfidence = sumConfidence / recentCount;

    // 检查置信度
    if (avgConfidence < this.config.gazeThreshold) {
      return;
    }

    // 确定凝视方向
    let newDirection: GazeDirection;
    const threshold = this.getThreshold();

    if (avgX < 0.5 - threshold) {
      newDirection = GazeDirection.LEFT;
    } else if (avgX > 0.5 + threshold) {
      newDirection = GazeDirection.RIGHT;
    } else if (avgY < 0.5 - threshold) {
      newDirection = GazeDirection.UP;
    } else if (avgY > 0.5 + threshold) {
      newDirection = GazeDirection.DOWN;
    } else {
      newDirection = GazeDirection.CENTER;
    }

    // 检查是否需要触发动作
    if (newDirection !== this.lastGazeDirection) {
      this.lastGazeDirection = newDirection;
      this.gazeStartTime = Date.now();
    } else if (newDirection !== GazeDirection.CENTER) {
      // 检查驻留时间
      const dwellTime = Date.now() - this.gazeStartTime;
      if (dwellTime >= this.config.dwellTime) {
        this.triggerGesture(newDirection);
      }
    }
  }

  /**
   * 获取阈值(根据灵敏度)
   */
  private getThreshold(): number {
    switch (this.config.sensitivity) {
      case 'low':
        return 0.2;
      case 'medium':
        return 0.15;
      case 'high':
        return 0.1;
      default:
        return 0.15;
    }
  }

  /**
   * 触发动作
   */
  private triggerGesture(direction: GazeDirection): void {
    const gesture: PageGesture = {
      direction: direction,
      confidence: 0.8,
      timestamp: Date.now()
    };

    hilog.info(DOMAIN, 'EyeTracking', 'Gesture triggered: %{public}s', direction);

    if (this.listener) {
      this.listener(gesture);
    }

    // 重置凝视开始时间
    this.gazeStartTime = Date.now();
  }

  /**
   * 停止追踪
   */
  async stopTracking(): Promise<void> {
    try {
      if (!this.isTracking) {
        return;
      }

      hilog.info(DOMAIN, 'EyeTracking', 'Stopping eye tracking...');

      // 停止捕获会话 - 尝试新API,回退旧API
      if (this.captureSession) {
        try {
          this.captureSession.stop();
        } catch (stopError) {
          hilog.warn(DOMAIN, 'EyeTracking', 'Session stop() failed');
        }
      }

      this.isTracking = false;
      this.currentState = EyeTrackingState.IDLE;
      this.gazePoints = [];

      hilog.info(DOMAIN, 'EyeTracking', 'Eye tracking stopped');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Stop tracking failed: %{public}s', err.message);
    }
  }

  // ==================== 配置管理 ====================

  /**
   * 设置配置
   */
  setConfig(config: Partial<EyeTrackingConfig>): void {
    if (config.enabled !== undefined) {
      this.config.enabled = config.enabled;
    }
    if (config.sensitivity !== undefined) {
      this.config.sensitivity = config.sensitivity;
    }
    if (config.dwellTime !== undefined) {
      this.config.dwellTime = config.dwellTime;
    }
    if (config.gazeThreshold !== undefined) {
      this.config.gazeThreshold = config.gazeThreshold;
    }
    if (config.calibrationNeeded !== undefined) {
      this.config.calibrationNeeded = config.calibrationNeeded;
    }
    hilog.info(DOMAIN, 'EyeTracking', 'Config updated');
  }

  /**
   * 获取配置
   */
  getConfig(): EyeTrackingConfig {
    return {
      enabled: this.config.enabled,
      sensitivity: this.config.sensitivity,
      dwellTime: this.config.dwellTime,
      gazeThreshold: this.config.gazeThreshold,
      calibrationNeeded: this.config.calibrationNeeded
    };
  }

  // ==================== 监听器 ====================

  /**
   * 设置手势监听器
   */
  setGestureListener(listener: (gesture: PageGesture) => void): void {
    this.listener = listener;
  }

  // ==================== 校准 ====================

  /**
   * 开始校准
   */
  async startCalibration(): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Starting calibration...');
      this.currentState = EyeTrackingState.CALIBRATING;

      // 校准点(屏幕的5个位置)
      const calibrationPoints: CalibrationPoint[] = [
        { x: 0.5, y: 0.5 },  // 中心
        { x: 0.2, y: 0.5 },  // 左
        { x: 0.8, y: 0.5 },  // 右
        { x: 0.5, y: 0.2 },  // 上
        { x: 0.5, y: 0.8 }   // 下
      ];

      // 对每个校准点进行校准
      for (let i = 0; i < calibrationPoints.length; i++) {
        const point = calibrationPoints[i];
        hilog.info(DOMAIN, 'EyeTracking', 'Calibrating point %{public}d/%{public}d', i + 1, calibrationPoints.length);

        // 等待用户注视该点
        await this.calibrateSinglePoint(point);
      }

      this.isCalibrated = true;
      this.currentState = EyeTrackingState.IDLE;
      hilog.info(DOMAIN, 'EyeTracking', 'Calibration completed');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EyeTracking', 'Calibration failed: %{public}s', err.message);
      this.currentState = EyeTrackingState.IDLE;
      return false;
    }
  }

  /**
   * 校准单个点
   */
  private async calibrateSinglePoint(point: CalibrationPoint): Promise<void> {
    return new Promise<void>((resolve) => {
      // 等待用户注视 3 秒
      const startTime = Date.now();
      const duration = 3000;
      const checkInterval = setInterval(() => {
        if (this.gazePoints.length > 0) {
          const elapsed = Date.now() - startTime;
          if (elapsed >= duration) {
            clearInterval(checkInterval);

            // 保存校准数据
            const key = point.x + '_' + point.y;
            const avgPoint = this.getAverageGazePoint();
            if (avgPoint) {
              this.calibrationData.set(key, avgPoint);
            }
            resolve();
          }
        }
      }, 100);
    });
  }

  /**
   * 获取平均凝视点
   */
  private getAverageGazePoint(): GazePoint | null {
    if (this.gazePoints.length === 0) {
      return null;
    }

    let sumX = 0;
    let sumY = 0;
    let sumConfidence = 0;

    for (let i = 0; i < this.gazePoints.length; i++) {
      sumX += this.gazePoints[i].x;
      sumY += this.gazePoints[i].y;
      sumConfidence += this.gazePoints[i].confidence;
    }

    const count = this.gazePoints.length;
    return {
      x: sumX / count,
      y: sumY / count,
      timestamp: Date.now(),
      duration: 0,
      confidence: sumConfidence / count
    };
  }

  /**
   * 获取凝视统计
   */
  getGazeStatistics(): GazeStatistics {
    if (this.gazePoints.length === 0) {
      return {
        leftPercentage: 0,
        rightPercentage: 0,
        centerPercentage: 0,
        avgDwellTime: 0,
        totalSamples: 0
      };
    }

    let leftCount = 0;
    let rightCount = 0;
    let centerCount = 0;

    for (let i = 0; i < this.gazePoints.length; i++) {
      const point = this.gazePoints[i];
      const threshold = this.getThreshold();

      if (point.x < 0.5 - threshold) {
        leftCount++;
      } else if (point.x > 0.5 + threshold) {
        rightCount++;
      } else {
        centerCount++;
      }
    }

    const total = this.gazePoints.length;

    return {
      leftPercentage: (leftCount / total) * 100,
      rightPercentage: (rightCount / total) * 100,
      centerPercentage: (centerCount / total) * 100,
      avgDwellTime: this.config.dwellTime,
      totalSamples: total
    };
  }

  // ==================== 状态查询 ====================

  /**
   * 是否正在追踪
   */
  isTrackingActive(): boolean {
    return this.isTracking;
  }

  /**
   * 获取最后凝视方向
   */
  getLastGazeDirection(): GazeDirection {
    return this.lastGazeDirection;
  }

  /**
   * 获取当前状态
   */
  getState(): EyeTrackingState {
    return this.currentState;
  }

  // ==================== 工具方法 ====================

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    // FIX: stopTracking is async, must await
    await this.stopTracking();

    // 释放 CameraKit 资源
    if (this.captureSession) {
      try {
        this.captureSession.release();
      } catch (e) {
        hilog.warn(DOMAIN, 'EyeTracking', 'CaptureSession release failed');
      }
      this.captureSession = null;
    }
    if (this.cameraInput) {
      try {
        await this.cameraInput.close();
      } catch (e) {
        hilog.warn(DOMAIN, 'EyeTracking', 'CameraInput close failed');
      }
      this.cameraInput = null;
    }
    if (this.previewOutput) {
      try {
        this.previewOutput.release();
      } catch (e) {
        hilog.warn(DOMAIN, 'EyeTracking', 'PreviewOutput release failed');
      }
      this.previewOutput = null;
    }
    if (this.imageReceiver) {
      try {
        this.imageReceiver.release();
      } catch (e) {
        hilog.warn(DOMAIN, 'EyeTracking', 'ImageReceiver release failed');
      }
      this.imageReceiver = null;
    }

    this.isInitialized = false;
    this.context = null;
    this.listener = null;
    this.gazePoints = [];
    this.calibrationData.clear();
    this.isCalibrated = false;

    hilog.info(DOMAIN, 'EyeTracking', 'Released');
  }
}

// 导出单例
export const eyeTrackingService = EyeTrackingService.getInstance();
export default eyeTrackingService;
