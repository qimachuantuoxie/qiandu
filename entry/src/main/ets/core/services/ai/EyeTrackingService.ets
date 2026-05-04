// 鐪煎姩杩借釜鏈嶅姟 - AI 鏅鸿兘缈婚〉
// Eye Tracking Service - AI Smart Page Turning
// 浣跨敤鍓嶇疆鎽勫儚澶村拰瑙嗚绠楁硶瀹炵幇鐪煎姩妫€娴?鏀寔鍑濊璇嗗埆缈婚〉
// 閫傜敤浜庨槄璇诲簲鐢ㄧ殑鎵嬪娍鎺у埗鍦烘櫙

import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0xFF08;

/**
 * 鐪煎姩杩借釜鐘舵€佹灇涓? */
export enum EyeTrackingState {
  IDLE = 'idle',           // 绌洪棽
  TRACKING = 'tracking',   // 姝ｅ湪杩借釜
  PAUSED = 'paused',       // 鏆傚仠
  CALIBRATING = 'calibrating'  // 鏍″噯涓?}

/**
 * 鍑濊鏂瑰悜鏋氫妇
 */
export enum GazeDirection {
  LEFT = 'left',     // 鍚戝乏鍑濊 -> 涓婁竴椤?  RIGHT = 'right',   // 鍚戝彸鍑濊 -> 涓嬩竴椤?  CENTER = 'center', // 涓棿鍖哄煙
  UP = 'up',         // 鍚戜笂鍑濊
  DOWN = 'down'      // 鍚戜笅鍑濊
}

/**
 * 鍑濊鐐规暟鎹? */
export interface GazePoint {
  x: number;         // X鍧愭爣(灞忓箷鐧惧垎姣?0-1)
  y: number;         // Y鍧愭爣(灞忓箷鐧惧垎姣?0-1)
  timestamp: number; // 鏃堕棿鎴?  duration: number;  // 鎸佺画鏃堕棿(ms)
  confidence: number;// 缃俊搴?0-1
}

/**
 * 鐪煎姩杩借釜閰嶇疆
 */
export interface EyeTrackingConfig {
  enabled: boolean;              // 鏄惁鍚敤
  sensitivity: 'low' | 'medium' | 'high'; // 鐏垫晱搴?  dwellTime: number;             // 椹荤暀鏃堕棿(ms),瑙﹀彂缈婚〉闇€瑕佸嚌瑙嗙殑鏃堕棿
  gazeThreshold: number;         // 缃俊搴﹂槇鍊?  calibrationNeeded: boolean;    // 鏄惁闇€瑕佹牎鍑?}

/**
 * 鎵嬪娍缁撴灉
 */
export interface PageGesture {
  direction: GazeDirection; // 鏂瑰悜
  confidence: number;        // 缃俊搴?  timestamp: number;        // 鏃堕棿鎴?}

/**
 * 鏍″噯鐐? */
export interface CalibrationPoint {
  x: number;
  y: number;
}

/**
 * 鍑濊缁熻
 */
export interface GazeStatistics {
  leftPercentage: number;
  rightPercentage: number;
  centerPercentage: number;
  avgDwellTime: number;
  totalSamples: number;
}

/**
 * 浜鸿劯鍖哄煙
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
 * 榛樿閰嶇疆
 */
const DEFAULT_CONFIG: EyeTrackingConfig = {
  enabled: false,
  sensitivity: 'medium',
  dwellTime: 800,  // 800ms 椹荤暀鏃堕棿
  gazeThreshold: 0.7,
  calibrationNeeded: true
};

/**
 * 鐪煎姩杩借釜鏈嶅姟绫? * 閫氳繃鍓嶇疆鎽勫儚澶存娴嬬敤鎴疯绾?瀹炵幇鏅鸿兘缈婚〉鍔熻兘
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

  // CameraKit 鐩稿叧
  private cameraManager: camera.CameraManager | null = null;
  private cameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private captureSession: camera.CaptureSession | null = null;
  private cameraDevice: camera.CameraDevice | null = null;

  // 鍥惧儚澶勭悊鐩稿叧
  private imageReceiver: image.ImageReceiver | null = null;
  private screenWidth: number = 0;
  private screenHeight: number = 0;

  // 鏍″噯鐩稿叧
  private calibrationData: Map<string, GazePoint> = new Map();
  private isCalibrated: boolean = false;

  // 缁熻鐩稿叧
  private trackingStartTime: number = 0;
  private frameCount: number = 0;
  private gazeStartTime: number = 0;

  private constructor() {}

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  static getInstance(): EyeTrackingService {
    if (!EyeTrackingService.instance) {
      EyeTrackingService.instance = new EyeTrackingService();
    }
    return EyeTrackingService.instance;
  }

  /**
   * 鍒濆鍖栨湇鍔?   */
  async init(context: common.Context): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Initializing...');
      this.context = context;

      // 鑾峰彇灞忓箷灏哄
      await this.getScreenSize();

      // 鍒濆鍖?CameraKit
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
   * 鑾峰彇灞忓箷灏哄
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
      // 浣跨敤榛樿鍊?      this.screenWidth = 1080;
      this.screenHeight = 2400;
    }
  }

  /**
   * 鍒濆鍖栨憚鍍忓ご
   */
  private async initCamera(): Promise<void> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Initializing camera...');

      // 鑾峰彇 CameraManager
      this.cameraManager = camera.getCameraManager(this.context!);

      // 鑾峰彇鎽勫儚澶村垪琛?      const cameras: camera.CameraDevice[] = this.cameraManager.getSupportedCameras();
      if (!cameras || cameras.length === 0) {
        throw new Error('No cameras available');
      }

      // 鏌ユ壘鍓嶇疆鎽勫儚澶?      let frontCamera: camera.CameraDevice | null = null;
      for (let i = 0; i < cameras.length; i++) {
        const cam = cameras[i];
        const cameraType = cam.cameraPosition;
        if (cameraType === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          frontCamera = cam;
          break;
        }
      }

      // 濡傛灉娌℃湁鍓嶇疆鎽勫儚澶?浣跨敤绗竴涓憚鍍忓ご
      if (!frontCamera) {
        frontCamera = cameras[0];
        hilog.warn(DOMAIN, 'EyeTracking', 'No front camera found, using first camera');
      }

      this.cameraDevice = frontCamera;
      hilog.info(DOMAIN, 'EyeTracking', 'Camera selected: %{public}s', frontCamera.cameraPosition);

      // 鍒涘缓鎹曡幏浼氳瘽
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
   * 閰嶇疆骞跺惎鍔ㄦ崟鑾蜂細璇?   * 浣跨敤鏂扮殑浼氳瘽API,甯︽棫API闄嶇骇鍥為€€
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
   * 妫€鏌ユ湇鍔℃槸鍚﹀氨缁?   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null && this.cameraDevice !== null;
  }

  // ==================== 鐪煎姩杩借釜 ====================

  /**
   * 寮€濮嬭拷韪?   */
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

      // 閰嶇疆骞跺惎鍔ㄦ崟鑾蜂細璇?浣跨敤鏂癆PI)
      const sessionStarted: boolean = await this.configureAndStartSession();
      if (!sessionStarted) {
        throw new Error('Failed to start capture session');
      }

      this.isTracking = true;
      this.currentState = EyeTrackingState.TRACKING;
      this.trackingStartTime = Date.now();
      this.frameCount = 0;
      this.gazePoints = [];

      // 寮€濮嬪鐞嗗浘鍍忓抚
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
   * 寮€濮嬪鐞嗗浘鍍忓抚
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
   * 澶勭悊鍥惧儚甯?- 浣跨敤 YUV  luminance 鏁版嵁杩涜浜鸿劯妫€娴?   */
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

      // 浣跨敤 luminance 鏁版嵁绠€鍖栦汉鑴告娴?      const faceRegion: FaceRegion | null = this.detectFaceFromBuffer(byteBuffer, width, height);
      if (!faceRegion) {
        return;
      }

      // 浼扮畻鍑濊鐐?      const gazePoint: GazePoint | null = this.estimateGazePoint(faceRegion);
      if (!gazePoint) {
        return;
      }

      // 搴旂敤鏍″噯
      const calibratedPoint: GazePoint = this.applyCalibration(gazePoint);

      // 娣诲姞鍒板巻鍙?      this.gazePoints.push(calibratedPoint);

      // 淇濇寔鏈€杩?0涓偣
      if (this.gazePoints.length > 50) {
        this.gazePoints = this.gazePoints.slice(-50);
      }

      // 鍒嗘瀽鍑濊鏂瑰悜
      this.analyzeGazeDirection();
    } catch (error) {
      const err = error as BusinessError;
      if (this.frameCount % 100 === 0) {
        hilog.error(DOMAIN, 'EyeTracking', 'Process frame failed: %{public}s', err.message);
      }
    }
  }

  /**
   * 鍩轰簬 luminance 鏁版嵁妫€娴嬩汉鑴稿尯鍩?(YUV Y 骞抽潰鏁版嵁)
   */
  private detectFaceFromBuffer(byteBuffer: ArrayBuffer, width: number, height: number): FaceRegion | null {
    try {
      const pixelView = new DataView(byteBuffer);
      let sumX = 0;
      let sumY = 0;
      let brightPixelCount = 0;

      // 閲囨牱瀵绘壘浜害閫備腑鐨勫尯鍩?(浜鸿劯鑲よ壊鍖哄煙鍦╕閫氶亾鐨勫吀鍨嬪€?
      const step = 4;
      for (let y = Math.floor(height * 0.2); y < Math.floor(height * 0.6); y += step) {
        for (let x = Math.floor(width * 0.2); x < Math.floor(width * 0.8); x += step) {
          const luminance = pixelView.getUint8(y * width + x);
          // 浜鸿劯鍦ㄤ寒搴﹂€氶亾涓€氬父澶勪簬涓瓑浜害鑼冨洿
          if (luminance > 60 && luminance < 220) {
            sumX += x;
            sumY += y;
            brightPixelCount++;
          }
        }
      }

      if (brightPixelCount < 50) {
        return null; // 鏈娴嬪埌浜鸿劯
      }

      // 璁＄畻浜鸿劯涓績
      const faceX = Math.floor(sumX / brightPixelCount);
      const faceY = Math.floor(sumY / brightPixelCount);
      const faceWidth = Math.floor(width * 0.3);
      const faceHeight = Math.floor(height * 0.4);

      // 浼扮畻鐪奸儴浣嶇疆
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
   * 浼扮畻鍑濊鐐?   * 鍩轰簬鍙岀溂涓績浣嶇疆浼扮畻娉ㄨ鐐?   */
  private estimateGazePoint(faceRegion: FaceRegion): GazePoint | null {
    try {
      // 璁＄畻鍙岀溂涓績
      const centerX = (faceRegion.leftEyeX + faceRegion.rightEyeX) / 2;
      const centerY = (faceRegion.leftEyeY + faceRegion.rightEyeY) / 2;

      // 杞崲涓哄睆骞曠櫨鍒嗘瘮
      const screenX = centerX / faceRegion.width * 0.5 + 0.25; // 鏄犲皠鍒?0-1
      const screenY = centerY / faceRegion.height * 0.5 + 0.25;

      // 纭繚鍦ㄦ湁鏁堣寖鍥村唴
      const normalizedX = Math.max(0, Math.min(1, screenX));
      const normalizedY = Math.max(0, Math.min(1, screenY));

      // 璁＄畻缃俊搴?鍩轰簬浜鸿劯妫€娴嬭川閲?
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
   * 搴旂敤鏍″噯鏁版嵁
   */
  private applyCalibration(gazePoint: GazePoint): GazePoint {
    if (!this.isCalibrated || this.calibrationData.size === 0) {
      return gazePoint;
    }

    // 绠€鍗曠殑绾挎€ф牎鍑?    // 瀹為檯椤圭洰涓簲璇ヤ娇鐢ㄦ洿澶嶆潅鐨勬牎鍑嗙畻娉?    let calibratedX = gazePoint.x;
    let calibratedY = gazePoint.y;

    // 搴旂敤鏍″噯鍋忕Щ
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
   * 鍒嗘瀽鍑濊鏂瑰悜
   */
  private analyzeGazeDirection(): void {
    if (this.gazePoints.length < 10) {
      return; // 闇€瑕佽冻澶熺殑鏍锋湰
    }

    // 璁＄畻骞冲潎浣嶇疆(鏈€杩?0涓偣)
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

    // 妫€鏌ョ疆淇″害
    if (avgConfidence < this.config.gazeThreshold) {
      return;
    }

    // 纭畾鍑濊鏂瑰悜
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

    // 妫€鏌ユ槸鍚﹂渶瑕佽Е鍙戝姩浣?    if (newDirection !== this.lastGazeDirection) {
      this.lastGazeDirection = newDirection;
      this.gazeStartTime = Date.now();
    } else if (newDirection !== GazeDirection.CENTER) {
      // 妫€鏌ラ┗鐣欐椂闂?      const dwellTime = Date.now() - this.gazeStartTime;
      if (dwellTime >= this.config.dwellTime) {
        this.triggerGesture(newDirection);
      }
    }
  }

  /**
   * 鑾峰彇闃堝€?鏍规嵁鐏垫晱搴?
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
   * 瑙﹀彂鍔ㄤ綔
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

    // 閲嶇疆鍑濊寮€濮嬫椂闂?    this.gazeStartTime = Date.now();
  }

  /**
   * 鍋滄杩借釜
   */
  async stopTracking(): Promise<void> {
    try {
      if (!this.isTracking) {
        return;
      }

      hilog.info(DOMAIN, 'EyeTracking', 'Stopping eye tracking...');

      // 鍋滄鎹曡幏浼氳瘽 - 灏濊瘯鏂癆PI,鍥為€€鏃PI
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

  // ==================== 閰嶇疆绠＄悊 ====================

  /**
   * 璁剧疆閰嶇疆
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
   * 鑾峰彇閰嶇疆
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

  // ==================== 鐩戝惉鍣?====================

  /**
   * 璁剧疆鎵嬪娍鐩戝惉鍣?   */
  setGestureListener(listener: (gesture: PageGesture) => void): void {
    this.listener = listener;
  }

  // ==================== 鏍″噯 ====================

  /**
   * 寮€濮嬫牎鍑?   */
  async startCalibration(): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'EyeTracking', 'Starting calibration...');
      this.currentState = EyeTrackingState.CALIBRATING;

      // 鏍″噯鐐?灞忓箷鐨?涓綅缃?
      const calibrationPoints: CalibrationPoint[] = [
        { x: 0.5, y: 0.5 },  // 涓績
        { x: 0.2, y: 0.5 },  // 宸?        { x: 0.8, y: 0.5 },  // 鍙?        { x: 0.5, y: 0.2 },  // 涓?        { x: 0.5, y: 0.8 }   // 涓?      ];

      // 瀵规瘡涓牎鍑嗙偣杩涜鏍″噯
      for (let i = 0; i < calibrationPoints.length; i++) {
        const point = calibrationPoints[i];
        hilog.info(DOMAIN, 'EyeTracking', 'Calibrating point %{public}d/%{public}d', i + 1, calibrationPoints.length);

        // 绛夊緟鐢ㄦ埛娉ㄨ璇ョ偣
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
   * 鏍″噯鍗曚釜鐐?   */
  private async calibrateSinglePoint(point: CalibrationPoint): Promise<void> {
    return new Promise<void>((resolve) => {
      // 绛夊緟鐢ㄦ埛娉ㄨ 3 绉?      const startTime = Date.now();
      const duration = 3000;
      const checkInterval = setInterval(() => {
        if (this.gazePoints.length > 0) {
          const elapsed = Date.now() - startTime;
          if (elapsed >= duration) {
            clearInterval(checkInterval);

            // 淇濆瓨鏍″噯鏁版嵁
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
   * 鑾峰彇骞冲潎鍑濊鐐?   */
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
   * 鑾峰彇鍑濊缁熻
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

  // ==================== 鐘舵€佹煡璇?====================

  /**
   * 鏄惁姝ｅ湪杩借釜
   */
  isTrackingActive(): boolean {
    return this.isTracking;
  }

  /**
   * 鑾峰彇鏈€鍚庡嚌瑙嗘柟鍚?   */
  getLastGazeDirection(): GazeDirection {
    return this.lastGazeDirection;
  }

  /**
   * 鑾峰彇褰撳墠鐘舵€?   */
  getState(): EyeTrackingState {
    return this.currentState;
  }

  // ==================== 宸ュ叿鏂规硶 ====================

  /**
   * 閲婃斁璧勬簮
   */
  async release(): Promise<void> {
    // FIX: stopTracking is async, must await
    await this.stopTracking();

    // 閲婃斁 CameraKit 璧勬簮
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

// 瀵煎嚭鍗曚緥
export const eyeTrackingService = EyeTrackingService.getInstance();
export default eyeTrackingService;
