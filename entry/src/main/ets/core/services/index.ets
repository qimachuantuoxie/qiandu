/**
 * Services 统一导出
 * 
 * 按功能分类组织：
 * - book: 书籍相关服务
 * - reader: 阅读器相关服务
 * - ai: AI/语音相关服务
 * - audio: 音频播放服务
 * - image: 图片相关服务
 * - network: 网络相关服务
 * - storage: 存储相关服务
 * - auth: 认证相关服务
 * - community: 社区功能服务
 * - backup: 备份恢复服务
 * - parsers: 格式解析器
 * - huawei-kit: 华为Kit封装
 * - external: 外部服务
 */

// ==================== 书籍相关服务 ====================
export { bookSourceService } from './book/BookSourceService';
export { legadoSourceMarket } from './book/LegadoSourceMarket';
export { onlineBookService } from './book/OnlineBookService';
export { folderScannerService } from './book/FolderScannerService';
export { fileManagerKitService } from './book/FileManagerKitService';

// ==================== 阅读器相关服务 ====================
export { readerKitService } from './reader/ReaderKitService';
export { enhancedReaderKitService } from './reader/EnhancedReaderKitService';
export { comicReaderService } from './reader/ComicReaderService';
export { RuleEngine } from './reader/RuleEngine';
export { enhancedDocumentParser } from './reader/EnhancedDocumentParser';
export { accessibilityService } from './reader/AccessibilityService';
export { collaborationKitService } from './reader/CollaborationKitService';
export { harmonySkillService } from './reader/HarmonySkillService';
export { uiDesignKitService } from './reader/UIDesignKitService';

// ==================== AI服务 ====================
export { aiService } from './ai/AIService';
export { ttsService } from './ai/TTSService';
export { coreSpeechService } from './ai/CoreSpeechService';
export { ocrService } from './ai/OcrService';
export { eyeTrackingService } from './ai/EyeTrackingService';
export { xiaoyiAgent } from './ai/XiaoyiAgentService';

// ==================== 音频服务 ====================
export { audioPlayerService } from './audio/AudioPlayerService';
export { novelPlayer } from './audio/NovelPlayerService';

// ==================== 图片服务 ====================
export { imageService } from './image/ImageService';
export { imageLoaderService } from './image/ImageLoaderService';
export { imageCacheManager } from './image/ImageCacheManager';
export { imageCacheService } from './image/ImageCacheService';
export { dynamicCoverService } from './image/DynamicCoverService';

// ==================== 网络服务 ====================
export { apiService } from './external/ApiService';

// ==================== 认证服务 ====================
export { huaweiAuthService } from './auth/HuaweiAuthService';
export { loginStateManager } from './auth/LoginStateManager';

// ==================== 社区服务 ====================
export { readingCommunityService } from './community/ReadingCommunityService';
export { cloudBookshelfService } from './community/CloudBookshelfService';

// ==================== 华为Kit封装 ====================
export { kitManager } from './huawei-kit/KitManager';
export { audioKitService } from './huawei-kit/AudioKitService';
export { imageKitService } from './huawei-kit/ImageKitService';
export { shareKitService } from './huawei-kit/ShareKitService';
export { adsKitService } from './huawei-kit/AdsKitService';

// ==================== 外部服务 ====================
export { harmonyPayment } from './external/HarmonyPaymentService';

// ==================== 格式解析器 ====================
export { BaseParserUtils } from './parsers/BaseParserUtils';
export { ZipFormatParser } from './parsers/ZipFormatParser';
export { TextFormatParser } from './parsers/TextFormatParser';
export { XmlFormatParser } from './parsers/XmlFormatParser';
export { HuaweiKitParser } from './parsers/HuaweiKitParser';
export { DjvuParser } from './parsers/DjvuParser';
export { ChmParser } from './parsers/ChmParser';
export { OtherFormatParser } from './parsers/OtherFormatParser';
export { rarParser } from './parsers/RarParser';
