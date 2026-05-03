/**
 * Services 灞傜粺涓€瀵煎嚭
 * 
 * 鎸変笟鍔″姛鑳藉垎绫?
 * - book: 涔︾睄鐩稿叧鏈嶅姟
 * - reader: 闃呰鐩稿叧鏈嶅姟  
 * - ai: AI/璇煶鐩稿叧鏈嶅姟
 * - audio: 闊抽鎾斁鏈嶅姟
 * - image: 鍥剧墖鐩稿叧鏈嶅姟
 * - network: 缃戠粶鐩稿叧鏈嶅姟
 * - storage: 瀛樺偍鐩稿叧鏈嶅姟
 * - auth: 璁よ瘉鐩稿叧鏈嶅姟
 * - community: 绀惧尯鐩稿叧鏈嶅姟
 * - backup: 澶囦唤鎭㈠鏈嶅姟
 * - parsers: 鏂囦欢瑙ｆ瀽鏈嶅姟
 * - huawei-kit: 鍗庝负Kit闆嗘垚
 * - external: 澶栭儴鏈嶅姟
 */

// ==================== 涔︾睄鐩稿叧鏈嶅姟 ====================
export { bookSourceService } from './book/BookSourceService';
export { legadoSourceMarket } from './book/LegadoSourceMarket';
export { onlineBookService } from './book/OnlineBookService';
export { folderScannerService } from './book/FolderScannerService';
export { fileManagerKitService } from './book/FileManagerKitService';

// ==================== 闃呰鐩稿叧鏈嶅姟 ====================
export { readerKitService } from './reader/ReaderKitService';
export { enhancedReaderKitService } from './reader/EnhancedReaderKitService';
export { comicReaderService } from './reader/ComicReaderService';
export { RuleEngine } from './reader/RuleEngine';
export { enhancedDocumentParser } from './reader/EnhancedDocumentParser';
export { accessibilityService } from './reader/AccessibilityService';
export { collaborationKitService } from './reader/CollaborationKitService';
export { harmonySkillService } from './reader/HarmonySkillService';
export { uiDesignKitService } from './reader/UIDesignKitService';

// ==================== AI鏈嶅姟 ====================
export { aiService } from './ai/AIService';
export { ttsService } from './ai/TTSService';
export { coreSpeechService } from './ai/CoreSpeechService';
export { ocrService } from './ai/OcrService';
export { eyeTrackingService } from './ai/EyeTrackingService';
export { xiaoyiAgent } from './ai/XiaoyiAgentService';

// ==================== 闊抽鏈嶅姟 ====================
export { audioPlayerService } from './audio/AudioPlayerService';
export { novelPlayer } from './audio/NovelPlayerService';

// ==================== 鍥剧墖鏈嶅姟 ====================
export { imageService } from './image/ImageService';
export { imageLoaderService } from './image/ImageLoaderService';
export { imageCacheManager } from './image/ImageCacheManager';
export { imageCacheService } from './image/ImageCacheService';
export { dynamicCoverService } from './image/DynamicCoverService';

// ==================== 缃戠粶鏈嶅姟 ====================
export { apiService } from './external/ApiService';

// ==================== 璁よ瘉鏈嶅姟 ====================
export { huaweiAuthService } from './auth/HuaweiAuthService';
export { loginStateManager } from './auth/LoginStateManager';

// ==================== 绀惧尯鏈嶅姟 ====================
export { readingCommunityService } from './community/ReadingCommunityService';
export { cloudBookshelfService } from './community/CloudBookshelfService';

// ==================== 鍗庝负Kit闆嗘垚 ====================
export { kitManager } from './huawei-kit/KitManager';
export { audioKitService } from './huawei-kit/AudioKitService';
export { imageKitService } from './huawei-kit/ImageKitService';
export { shareKitService } from './huawei-kit/ShareKitService';
export { adsKitService } from './huawei-kit/AdsKitService';

// ==================== 澶栭儴鏈嶅姟 ====================
export { harmonyPayment } from './external/HarmonyPaymentService';

// ==================== 鏂囨。瑙ｆ瀽鍣?====================
export { BaseParserUtils } from './parsers/BaseParserUtils';
export { ZipFormatParser } from './parsers/ZipFormatParser';
export { TextFormatParser } from './parsers/TextFormatParser';
export { XmlFormatParser } from './parsers/XmlFormatParser';
export { HuaweiKitParser } from './parsers/HuaweiKitParser';
export { DjvuParser } from './parsers/DjvuParser';
export { ChmParser } from './parsers/ChmParser';
export { OtherFormatParser } from './parsers/OtherFormatParser';
export { rarParser } from './parsers/RarParser';
