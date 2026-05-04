import { logger } from '../../../utils/Logger';
/**
 * UI Design Kit 閺堝秴濮?- 缂佺喍绔碪I鐠佹崘顓哥化鑽ょ埠
 * UI Design Kit Service - Unified UI Design System
 * 
 * 閸╄桨绨琀armonyOS Design鐟欏嫯瀵栭敍灞惧絹娓氭稓绮烘稉鈧�惃鍒処缂佸嫪娆㈤妴浣告禈閺嶅洢鈧�線顤侀懝鎻掓嫲娴溿倓绨扮拋鎹愵吀
 * 
 * @since 3.0.0
 */

import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../utils/PreferenceManager';
import { appTheme } from '../../utils/AppTheme';

// ==================== 妫版粏澹婄化鑽ょ埠 ====================

/**
 * 娑撳�顣芥０婊嗗�鐎规矮绠?
 */
export interface ThemeColors {
  // 娑撴槒澹婄拫?
  primary: string;
  primaryLight: string;
  primaryDark: string;
  
  // 鏉堝懎濮�懝?
  secondary: string;
  secondaryLight: string;
  secondaryDark: string;
  
  // 閸旂喕鍏橀懝?
  success: string;
  warning: string;
  error: string;
  info: string;
  
  // 閼冲本娅欓懝?
  background: string;
  backgroundSecondary: string;
  backgroundTertiary: string;
  
  // 閺傚洤鐡ф０婊嗗�
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  textDisabled: string;
  textInverse: string;
  
  // 鏉堣�顢嬫０婊嗗�
  border: string;
  borderLight: string;
  borderDark: string;
  
  // 閸掑棗澹婄痪?
  divider: string;
  
  // 闂冩潙濂?
  shadowLight: string;
  shadowDark: string;
  
  // 閸楀簼璐熼崫浣哄�閼?
  huaweiOrange: string;
  huaweiRed: string;
  huaweiBlue: string;
}

/**
 * 濞村懓澹婃稉濠氼暯
 */
export const LIGHT_THEME: ThemeColors = {
  // 娑撴槒澹婄拫?- HarmonyOS閽?
  primary: '#007DFF',
  primaryLight: '#339AFF',
  primaryDark: '#0066CC',
  
  // 鏉堝懎濮�懝?
  secondary: '#6B7280',
  secondaryLight: '#9CA3AF',
  secondaryDark: '#4B5563',
  
  // 閸旂喕鍏橀懝?
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',
  info: '#3B82F6',
  
  // 閼冲本娅欓懝?
  background: '#FFFFFF',
  backgroundSecondary: '#F8F9FA',
  backgroundTertiary: '#F1F3F5',
  
  // 閺傚洤鐡ф０婊嗗�
  textPrimary: '#1A1A1A',
  textSecondary: '#6B7280',
  textTertiary: '#9CA3AF',
  textDisabled: '#D1D5DB',
  textInverse: '#FFFFFF',
  
  // 鏉堣�顢嬫０婊嗗�
  border: '#E5E7EB',
  borderLight: '#F3F4F6',
  borderDark: '#D1D5DB',
  
  // 閸掑棗澹婄痪?
  divider: '#F3F4F6',
  
  // 闂冩潙濂?
  shadowLight: 'rgba(0, 0, 0, 0.05)',
  shadowDark: 'rgba(0, 0, 0, 0.15)',
  
  // 閸楀簼璐熼崫浣哄�閼?
  huaweiOrange: '#FF6600',
  huaweiRed: '#FF0000',
  huaweiBlue: '#007DFF'
};

/**
 * 濞ｈ精澹婃稉濠氼暯
 */
export const DARK_THEME: ThemeColors = {
  // 娑撴槒澹婄拫?
  primary: '#339AFF',
  primaryLight: '#66B3FF',
  primaryDark: '#007DFF',
  
  // 鏉堝懎濮�懝?
  secondary: '#9CA3AF',
  secondaryLight: '#D1D5DB',
  secondaryDark: '#6B7280',
  
  // 閸旂喕鍏橀懝?
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',
  info: '#60A5FA',
  
  // 閼冲本娅欓懝?
  background: '#1A1A1A',
  backgroundSecondary: '#2D2D2D',
  backgroundTertiary: '#404040',
  
  // 閺傚洤鐡ф０婊嗗�
  textPrimary: '#F9FAFB',
  textSecondary: '#D1D5DB',
  textTertiary: '#9CA3AF',
  textDisabled: '#4B5563',
  textInverse: '#1A1A1A',
  
  // 鏉堣�顢嬫０婊嗗�
  border: '#404040',
  borderLight: '#2D2D2D',
  borderDark: '#4B5563',
  
  // 閸掑棗澹婄痪?
  divider: '#2D2D2D',
  
  // 闂冩潙濂?
  shadowLight: 'rgba(255, 255, 255, 0.05)',
  shadowDark: 'rgba(0, 0, 0, 0.3)',
  
  // 閸楀簼璐熼崫浣哄�閼?
  huaweiOrange: '#FF8533',
  huaweiRed: '#FF3333',
  huaweiBlue: '#339AFF'
};

// ==================== 閸ョ偓鐖ｇ化鑽ょ埠 ====================

/**
 * 閸ョ偓鐖ｉ崥宥囆為弸姘��
 */
export enum IconName {
  // 鐎佃壈鍩呴崶鐐�垼
  HOME = 'home',
  BOOKSHELF = 'bookshelf',
  DISCOVER = 'discover',
  SETTINGS = 'settings',
  BACK = 'back',
  FORWARD = 'forward',
  MORE = 'more',
  CLOSE = 'close',
  
  // 閸旂喕鍏橀崶鐐�垼
  SEARCH = 'search',
  SCAN = 'scan',
  SHARE = 'share',
  DOWNLOAD = 'download',
  UPLOAD = 'upload',
  DELETE = 'delete',
  EDIT = 'edit',
  SAVE = 'save',
  CANCEL = 'cancel',
  CONFIRM = 'confirm',
  
  // 闂冨懓顕伴惄绋垮彠
  BOOK = 'book',
  READING = 'reading',
  BOOKMARK = 'bookmark',
  NOTE = 'note',
  CHAPTER = 'chapter',
  PAGE = 'page',
  FONT_SIZE = 'font_size',
  BRIGHTNESS = 'brightness',
  THEME = 'theme',
  
  // 婵�帊缍嬮惄绋垮彠
  PLAY = 'play',
  PAUSE = 'pause',
  STOP = 'stop',
  NEXT = 'next',
  PREVIOUS = 'previous',
  VOLUME = 'volume',
  MUTE = 'mute',
  
  // 閻€劍鍩涢惄绋垮彠
  USER = 'user',
  LOGIN = 'login',
  LOGOUT = 'logout',
  AVATAR = 'avatar',
  PROFILE = 'profile',
  
  // 閻樿埖鈧�礁娴橀弽?
  CHECK = 'check',
  CHECK_CIRCLE = 'check_circle',
  WARNING = 'warning',
  ERROR = 'error',
  INFO = 'info',
  LOADING = 'loading',
  SUCCESS = 'success',
  
  // 缁€鍙ユ唉閸ョ偓鐖?
  LIKE = 'like',
  COMMENT = 'comment',
  FAVORITE = 'favorite',
  STAR = 'star',
  
  // 閸楀簼璐熼惄绋垮彠
  HUAWEI = 'huawei',
  HUAWEI_ID = 'huawei_id',
  CLOUD = 'cloud',
  SYNC = 'sync',
  
  // 閺傚洣娆㈤惄绋垮彠
  FILE = 'file',
  FOLDER = 'folder',
  IMAGE = 'image',
  PDF = 'pdf',
  TXT = 'txt',
  EPUB = 'epub'
}

/**
 * 閸ョ偓鐖ｇ亸鍝勵嚟
 */
export enum IconSize {
  XS = 12,
  SM = 16,
  MD = 20,
  LG = 24,
  XL = 32,
  XXL = 48
}

// ==================== 鐎涙ぞ缍嬬化鑽ょ埠 ====================

/**
 * 鐎涙ぞ缍嬫径褍鐨?
 */
export enum FontSize {
  XS = 10,
  SM = 12,
  MD = 14,
  LG = 16,
  XL = 18,
  XXL = 20,
  XXXL = 24,
  H1 = 32,
  H2 = 28,
  H3 = 24,
  H4 = 20
}

/**
 * 鐎涙�鍣?
 */
export enum FontWeight {
  LIGHT = 300,
  REGULAR = 400,
  MEDIUM = 500,
  SEMIBOLD = 600,
  BOLD = 700
}

/**
 * 鐞涘矂鐝?
 */
export enum LineHeight {
  TIGHT = 1.2,
  NORMAL = 1.5,
  RELAXED = 1.75,
  LOOSE = 2.0
}

// ==================== 闂傜�绐涚化鑽ょ埠 ====================

/**
 * 闂傜�绐涚亸鍝勵嚟閿涘澊p閿?
 */
export enum SpacingSize {
  XS = 4,
  SM = 8,
  MD = 12,
  LG = 16,
  XL = 20,
  XXL = 24,
  XXXL = 32,
  HUGE = 40,
  MASSIVE = 48
}

// ==================== 閸﹀棜顫楃化鑽ょ埠 ====================

/**
 * 閸﹀棜顫楃亸鍝勵嚟
 */
export enum BorderRadius {
  NONE = 0,
  XS = 2,
  SM = 4,
  MD = 8,
  LG = 12,
  XL = 16,
  XXL = 20,
  FULL = 9999
}

// ==================== 闂冩潙濂栫化鑽ょ埠 ====================

/**
 * 闂冩潙濂栫痪褍鍩?
 */
export enum ShadowLevel {
  NONE = 'none',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

/**
 * 闂冩潙濂栭柊宥囩枂
 */
export interface ShadowConfig {
  offsetX: number;
  offsetY: number;
  blur: number;
  spread: number;
  color: string;
}

class ShadowConfigImpl implements ShadowConfig {
  offsetX: number = 0;
  offsetY: number = 0;
  blur: number = 0;
  spread: number = 0;
  color: string = 'transparent';
  
  constructor(offsetX: number, offsetY: number, blur: number, spread: number, color: string) {
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.blur = blur;
    this.spread = spread;
    this.color = color;
  }
}

const SHADOW_NONE = new ShadowConfigImpl(0, 0, 0, 0, 'transparent');
const SHADOW_SM = new ShadowConfigImpl(0, 1, 2, 0, 'rgba(0,0,0,0.05)');
const SHADOW_MD = new ShadowConfigImpl(0, 2, 4, 0, 'rgba(0,0,0,0.1)');
const SHADOW_LG = new ShadowConfigImpl(0, 4, 8, 0, 'rgba(0,0,0,0.15)');
const SHADOW_XL = new ShadowConfigImpl(0, 8, 16, 0, 'rgba(0,0,0,0.2)');

export const SHADOWS_NONE: ShadowConfig = SHADOW_NONE;
export const SHADOWS_SM: ShadowConfig = SHADOW_SM;
export const SHADOWS_MD: ShadowConfig = SHADOW_MD;
export const SHADOWS_LG: ShadowConfig = SHADOW_LG;
export const SHADOWS_XL: ShadowConfig = SHADOW_XL;

export function getShadow(level: ShadowLevel): ShadowConfig {
  switch (level) {
    case ShadowLevel.NONE: return SHADOW_NONE;
    case ShadowLevel.SM: return SHADOW_SM;
    case ShadowLevel.MD: return SHADOW_MD;
    case ShadowLevel.LG: return SHADOW_LG;
    case ShadowLevel.XL: return SHADOW_XL;
  }
}

// ==================== 閸斻劎鏁剧化鑽ょ埠 ====================

/**
 * 閸斻劎鏁鹃弮鍫曟毐
 */
export enum AnimationDuration {
  FAST = 150,
  NORMAL = 200,
  SLOW = 300,
  SLOWER = 500
}

/**
 * 閸斻劎鏁鹃弴鑼�殠
 */
export enum AnimationCurve {
  EASE_IN = 'ease-in',
  EASE_OUT = 'ease-out',
  EASE_IN_OUT = 'ease-in-out',
  LINEAR = 'linear',
  BOUNCE = 'bounce'
}

// ==================== 缂佸嫪娆㈤弽宄扮础 ====================

/**
 * 閹稿�鎸崇猾璇茬€?
 */
export enum ButtonType {
  PRIMARY = 'primary',
  SECONDARY = 'secondary',
  OUTLINE = 'outline',
  TEXT = 'text',
  ICON = 'icon'
}

/**
 * 閹稿�鎸崇亸鍝勵嚟
 */
export enum ButtonSize {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

/**
 * 閸楋紕澧栫猾璇茬€?
 */
export enum CardType {
  ELEVATED = 'elevated',
  OUTLINED = 'outlined',
  FILLED = 'filled'
}

// ==================== UI闁板秶鐤?====================

/**
 * UI闁板秶鐤?
 */
export interface UIConfig {
  /** 娑撳�顣?*/
  theme: 'light' | 'dark' | 'auto';
  /** 娑撴槒澹婄拫?*/
  primaryColor: string;
  /** 鐎涙ぞ缍嬫径褍鐨�紓鈺傛杹 */
  fontScale: number;
  /** 閺勵垰鎯侀崥顖滄暏閸﹀棜顫?*/
  enableRoundedCorners: boolean;
  /** 閺勵垰鎯侀崥顖滄暏闂冩潙濂?*/
  enableShadows: boolean;
  /** 閺勵垰鎯侀崥顖滄暏閸斻劎鏁?*/
  enableAnimations: boolean;
  /** 閸ョ偓鐖ｇ亸鍝勵嚟 */
  iconSize: IconSize;
  /** 閹稿�鎸抽崷鍡氼潡 */
  buttonBorderRadius: BorderRadius;
  /** 閸楋紕澧栭崷鍡氼潡 */
  cardBorderRadius: BorderRadius;
}

/**
 * 姒涙ǹ顓籙I闁板秶鐤?
 */
export const DEFAULT_UI_CONFIG: UIConfig = {
  theme: 'light',
  primaryColor: LIGHT_THEME.primary,
  fontScale: 1.0,
  enableRoundedCorners: true,
  enableShadows: true,
  enableAnimations: true,
  iconSize: IconSize.MD,
  buttonBorderRadius: BorderRadius.MD,
  cardBorderRadius: BorderRadius.LG
};

/**
 * 閹风柉绀塙IConfig
 */
function copyUIConfig(src: UIConfig): UIConfig {
  return {
    theme: src.theme,
    primaryColor: src.primaryColor,
    fontScale: src.fontScale,
    enableRoundedCorners: src.enableRoundedCorners,
    enableShadows: src.enableShadows,
    enableAnimations: src.enableAnimations,
    iconSize: src.iconSize,
    buttonBorderRadius: src.buttonBorderRadius,
    cardBorderRadius: src.cardBorderRadius
  };
}

// ==================== UI Design Kit閺堝秴濮熺猾?====================

/**
 * UI Design Kit 閺堝秴濮熺猾?
 */
class UIDesignKitService {
  /** 閸楁洑绶ョ€圭偘绶?*/
  private static instance: UIDesignKitService;
  
  /** 娑撳﹣绗呴弬?*/
  private context: common.Context | null = null;
  
  /** 閺勵垰鎯佸�鎻掑灥婵��瀵?*/
  private isInitialized: boolean = false;
  
  /** 瑜版挸澧犻柊宥囩枂 */
  private config: UIConfig = copyUIConfig(DEFAULT_UI_CONFIG);
  
  /** 瑜版挸澧犳稉濠氼暯 */
  private currentTheme: ThemeColors = LIGHT_THEME;

  private constructor() {}

  /**
   * 閼惧嘲褰囬崡鏇氱伐鐎圭偘绶?
   */
  static getInstance(): UIDesignKitService {
    if (!UIDesignKitService.instance) {
      UIDesignKitService.instance = new UIDesignKitService();
    }
    return UIDesignKitService.instance;
  }

  /**
   * 閸掓繂顫愰崠鏍ㄦ箛閸?
   */
  async init(context: common.Context): Promise<boolean> {
    try {
      logger.info('[UIDesignKit] Initializing...');
      this.context = context;
      
      // 閸旂姾娴囬柊宥囩枂
      await this.loadConfig();
      
      this.isInitialized = true;
      logger.info('[UIDesignKit] Initialized successfully');
      return true;
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[UIDesignKit] Init failed:', errorErr.message);
      return false;
    }
  }

  /**
   * 濡�偓閺屻儲婀囬崝鈩冩Ц閸氾箑姘ㄧ紒?
   */
  isReady(): boolean {
    return this.isInitialized && this.context !== null;
  }

  // ==================== 娑撳�顣界粻锛勬倞 ====================

  /**
   * 鐠佸墽鐤嗘稉濠氼暯
   */
  async setTheme(theme: 'light' | 'dark' | 'auto'): Promise<void> {
    this.config.theme = theme;
    
    switch (theme) {
      case 'light':
        this.currentTheme = LIGHT_THEME;
        break;
      case 'dark':
        this.currentTheme = DARK_THEME;
        break;
      case 'auto':
        // 閺嶈�宓佺化鑽ょ埠鐠佸墽鐤嗛懛顏勫З閸掑洦宕叉稉濠氼暯
        this.syncSystemTheme();
        break;
    }

    await this.saveConfig();
    logger.info('[UIDesignKit] Theme set to:', theme);
  }

  /**
   * 閺嶈�宓佺化鑽ょ埠鐠佸墽鐤嗛懛顏勫З閸掑洦宕叉稉濠氼暯
   */
  private async syncSystemTheme(): Promise<void> {
    try {
      // 閼惧嘲褰囩化鑽ょ埠瑜版挸澧犻惃鍕�箒閼瑰弶膩瀵�繒濮搁幀?
      const isSystemDark = appTheme.isDarkMode();
      this.currentTheme = isSystemDark ? DARK_THEME : LIGHT_THEME;
      logger.info('[UIDesignKit] Synced to system theme:', isSystemDark ? 'dark' : 'light');
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[UIDesignKit] Sync system theme failed:', errorErr.message);
    }
  }

  /**
   * 閼惧嘲褰囪ぐ鎾冲�娑撳�顣?
   */
  getTheme(): 'light' | 'dark' | 'auto' {
    return this.config.theme;
  }

  /**
   * 閼惧嘲褰囨稉濠氼暯妫版粏澹?
   */
  getThemeColors(): ThemeColors {
    return this.currentTheme;
  }

  /**
   * 閸掑洦宕叉稉濠氼暯
   */
  async toggleTheme(): Promise<void> {
    const newTheme = this.config.theme === 'light' ? 'dark' : 'light';
    await this.setTheme(newTheme);
  }

  // ==================== 閸ョ偓鐖ｇ粻锛勬倞 ====================

  /**
   * 閼惧嘲褰囬崶鐐�垼鐠у嫭绨�捄顖氱窞
   */
  getIconPath(iconName: IconName): string {
    return `media:icon_${iconName}`;
  }

  /**
   * 閼惧嘲褰囬崶鐐�垼鐏忓搫顕?
   */
  getIconSize(size: IconSize = this.config.iconSize): number {
    return size;
  }

  // ==================== 妫版粏澹婂�銉ュ徔 ====================

  /**
   * 閼惧嘲褰囨稉鏄忓�鐠?
   */
  getPrimaryColor(): string {
    return this.config.primaryColor || this.currentTheme.primary;
  }

  /**
   * 閼惧嘲褰囬弬鍥х摟妫版粏澹?
   */
  getTextColor(level: 'primary' | 'secondary' | 'tertiary' | 'disabled' = 'primary'): string {
    switch (level) {
      case 'primary':
        return this.currentTheme.textPrimary;
      case 'secondary':
        return this.currentTheme.textSecondary;
      case 'tertiary':
        return this.currentTheme.textTertiary;
      case 'disabled':
        return this.currentTheme.textDisabled;
      default:
        return this.currentTheme.textPrimary;
    }
  }

  /**
   * 閼惧嘲褰囬懗灞炬珯妫版粏澹?
   */
  getBackgroundColor(level: 'primary' | 'secondary' | 'tertiary' = 'primary'): string {
    switch (level) {
      case 'primary':
        return this.currentTheme.background;
      case 'secondary':
        return this.currentTheme.backgroundSecondary;
      case 'tertiary':
        return this.currentTheme.backgroundTertiary;
      default:
        return this.currentTheme.background;
    }
  }

  // ==================== 闂傜�绐涘�銉ュ徔 ====================

  /**
   * 閼惧嘲褰囬梻纾嬬獩
   */
  getSpacing(size: SpacingSize): number {
    return size;
  }

  // ==================== 閸﹀棜顫楀�銉ュ徔 ====================

  /**
   * 閼惧嘲褰囬崷鍡氼潡閸?
   */
  getBorderRadius(size: BorderRadius): number {
    if (!this.config.enableRoundedCorners) {
      return BorderRadius.NONE;
    }
    return size;
  }

  // ==================== 闂冩潙濂栧�銉ュ徔 ====================

  /**
   * 閼惧嘲褰囬梼鏉戝�闁板秶鐤?
   */
  getShadow(level: ShadowLevel): ShadowConfig {
    if (!this.config.enableShadows) {
      return SHADOWS_NONE;
    }
    return getShadow(level);
  }

  // ==================== 閸斻劎鏁惧�銉ュ徔 ====================

  /**
   * 閼惧嘲褰囬崝銊ф暰閺冨爼鏆?
   */
  getAnimationDuration(duration: AnimationDuration): number {
    if (!this.config.enableAnimations) {
      return 0;
    }
    return duration;
  }

  // ==================== 闁板秶鐤嗙粻锛勬倞 ====================

  /**
   * 閸旂姾娴囬柊宥囩枂
   */
  private async loadConfig(): Promise<void> {
    try {
      const themeJson = preferenceManager.getString('ui_theme', '');
      if (themeJson && themeJson.length > 0) {
        const savedTheme = JSON.parse(themeJson) as Partial<UIConfig>;
        if (savedTheme.theme !== undefined) this.config.theme = savedTheme.theme;
        if (savedTheme.primaryColor !== undefined) this.config.primaryColor = savedTheme.primaryColor;
        if (savedTheme.fontScale !== undefined) this.config.fontScale = savedTheme.fontScale;
        if (savedTheme.enableRoundedCorners !== undefined) this.config.enableRoundedCorners = savedTheme.enableRoundedCorners;
        if (savedTheme.enableShadows !== undefined) this.config.enableShadows = savedTheme.enableShadows;
        if (savedTheme.enableAnimations !== undefined) this.config.enableAnimations = savedTheme.enableAnimations;
        if (savedTheme.iconSize !== undefined) this.config.iconSize = savedTheme.iconSize;
        if (savedTheme.buttonBorderRadius !== undefined) this.config.buttonBorderRadius = savedTheme.buttonBorderRadius;
        if (savedTheme.cardBorderRadius !== undefined) this.config.cardBorderRadius = savedTheme.cardBorderRadius;

        // Update currentTheme based on loaded theme setting
        switch (this.config.theme) {
          case 'light':
            this.currentTheme = LIGHT_THEME;
            break;
          case 'dark':
            this.currentTheme = DARK_THEME;
            break;
          case 'auto':
            this.currentTheme = LIGHT_THEME;
            break;
        }
      }
      logger.info('[UIDesignKit] Theme config loaded from preferences');
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[UIDesignKit] Load theme config failed:', errorErr.message);
    }
  }

  /**
   * 娣囨繂鐡ㄩ柊宥囩枂
   */
  private async saveConfig(): Promise<void> {
    try {
      const themeJson = JSON.stringify(this.config);
      preferenceManager.setString('ui_theme', themeJson);
      logger.info('[UIDesignKit] Theme config saved to preferences');
    } catch (error) {
      const err = error as Error;
      const errorErr = error as Error;
      logger.error('[UIDesignKit] Save theme config failed:', errorErr.message);
    }
  }

  /**
   * 閺囧瓨鏌婇柊宥囩枂
   */
  async updateConfig(config: Partial<UIConfig>): Promise<void> {
    if (config.theme !== undefined) { await this.setTheme(config.theme); }
    if (config.primaryColor !== undefined) { this.config.primaryColor = config.primaryColor; }
    if (config.fontScale !== undefined) { this.config.fontScale = config.fontScale; }
    if (config.enableRoundedCorners !== undefined) { this.config.enableRoundedCorners = config.enableRoundedCorners; }
    if (config.enableShadows !== undefined) { this.config.enableShadows = config.enableShadows; }
    if (config.enableAnimations !== undefined) { this.config.enableAnimations = config.enableAnimations; }
    if (config.iconSize !== undefined) { this.config.iconSize = config.iconSize; }
    if (config.buttonBorderRadius !== undefined) { this.config.buttonBorderRadius = config.buttonBorderRadius; }
    if (config.cardBorderRadius !== undefined) { this.config.cardBorderRadius = config.cardBorderRadius; }
    
    await this.saveConfig();
    logger.info('[UIDesignKit] Config updated');
  }

  /**
   * 閼惧嘲褰囬柊宥囩枂
   */
  getConfig(): UIConfig {
    const cfg: UIConfig = {
      theme: this.config.theme,
      primaryColor: this.config.primaryColor,
      fontScale: this.config.fontScale,
      enableRoundedCorners: this.config.enableRoundedCorners,
      enableShadows: this.config.enableShadows,
      enableAnimations: this.config.enableAnimations,
      iconSize: this.config.iconSize,
      buttonBorderRadius: this.config.buttonBorderRadius,
      cardBorderRadius: this.config.cardBorderRadius
    };
    return cfg;
  }

  /**
   * 闁插秶鐤嗛柊宥囩枂
   */
  async resetConfig(): Promise<void> {
    this.config = copyUIConfig(DEFAULT_UI_CONFIG);
    this.currentTheme = LIGHT_THEME;
    await this.saveConfig();
    logger.info('[UIDesignKit] Config reset to default');
  }

  /**
   * 闁插﹥鏂佺挧鍕�爱
   */
  release(): void {
    this.isInitialized = false;
    this.context = null;
    logger.info('[UIDesignKit] Released');
  }
}

// Export singleton
export const uiDesignKitService = UIDesignKitService.getInstance();
export const uiDesignKit = uiDesignKitService;
export default uiDesignKitService;
