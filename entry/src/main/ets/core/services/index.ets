/**
 * Services 鐏炲倻绮烘稉鈧€电厧鍤?
 * 
 * 閹稿绗熼崝鈥冲閼宠棄鍨庣猾?
 * - book: 娑旓妇鐫勯惄绋垮彠閺堝秴濮?
 * - reader: 闂冨懓顕伴惄绋垮彠閺堝秴濮? 
 * - ai: AI/鐠囶參鐓堕惄绋垮彠閺堝秴濮?
 * - audio: 闂婃娊顣堕幘顓熸杹閺堝秴濮?
 * - image: 閸ュ墽澧栭惄绋垮彠閺堝秴濮?
 * - network: 缂冩垹绮堕惄绋垮彠閺堝秴濮?
 * - storage: 鐎涙ê鍋嶉惄绋垮彠閺堝秴濮?
 * - auth: 鐠併倛鐦夐惄绋垮彠閺堝秴濮?
 * - community: 缁€鎯у隘閻╃鍙ч張宥呭
 * - backup: 婢跺洣鍞ら幁銏狀槻閺堝秴濮?
 * - parsers: 閺傚洣娆㈢憴锝嗙€介張宥呭
 * - huawei-kit: 閸楀簼璐烱it闂嗗棙鍨?
 * - external: 婢舵牠鍎撮張宥呭
 */

// ==================== 娑旓妇鐫勯惄绋垮彠閺堝秴濮?====================
export { bookSourceService } from './book/BookSourceService';
export { legadoSourceMarket } from './book/LegadoSourceMarket';
export { onlineBookService } from './book/OnlineBookService';
export { folderScannerService } from './book/FolderScannerService';
export { fileManagerKitService } from './book/FileManagerKitService';

// ==================== 闂冨懓顕伴惄绋垮彠閺堝秴濮?====================
export { readerKitService } from './reader/ReaderKitService';
export { enhancedReaderKitService } from './reader/EnhancedReaderKitService';
export { comicReaderService } from './reader/ComicReaderService';
export { RuleEngine } from './reader/RuleEngine';
export { enhancedDocumentParser } from './reader/EnhancedDocumentParser';
export { accessibilityService } from './reader/AccessibilityService';
export { collaborationKitService } from './reader/CollaborationKitService';
export { harmonySkillService } from './reader/HarmonySkillService';
export { uiDesignKitService } from './reader/UIDesignKitService';

// ==================== AI閺堝秴濮?====================
export { aiService } from './ai/AIService';
export { ttsService } from './ai/TTSService';
export { coreSpeechService } from './ai/CoreSpeechService';
export { ocrService } from './ai/OcrService';
export { eyeTrackingService } from './ai/EyeTrackingService';
export { xiaoyiAgent } from './ai/XiaoyiAgentService';

// ==================== 闂婃娊顣堕張宥呭 ====================
export { audioPlayerService } from './audio/AudioPlayerService';
export { novelPlayer } from './audio/NovelPlayerService';

// ==================== 閸ュ墽澧栭張宥呭 ====================
export { imageService } from './image/ImageService';
export { imageLoaderService } from './image/ImageLoaderService';
export { imageCacheManager } from './image/ImageCacheManager';
export { imageCacheService } from './image/ImageCacheService';
export { dynamicCoverService } from './image/DynamicCoverService';

// ==================== 缂冩垹绮堕張宥呭 ====================
export { apiService } from './external/ApiService';

// ==================== 鐠併倛鐦夐張宥呭 ====================
export { huaweiAuthService } from './auth/HuaweiAuthService';
export { loginStateManager } from './auth/LoginStateManager';

// ==================== 缁€鎯у隘閺堝秴濮?====================
export { readingCommunityService } from './community/ReadingCommunityService';
export { cloudBookshelfService } from './community/CloudBookshelfService';

// ==================== 閸楀簼璐烱it闂嗗棙鍨?====================
export { kitManager } from './huawei-kit/KitManager';
export { audioKitService } from './huawei-kit/AudioKitService';
export { imageKitService } from './huawei-kit/ImageKitService';
export { shareKitService } from './huawei-kit/ShareKitService';
export { adsKitService } from './huawei-kit/AdsKitService';

// ==================== 婢舵牠鍎撮張宥呭 ====================
export { harmonyPayment } from './external/HarmonyPaymentService';

// ==================== 閺傚洦銆傜憴锝嗙€介崳?====================
export { BaseParserUtils } from './parsers/BaseParserUtils';
export { ZipFormatParser } from './parsers/ZipFormatParser';
export { TextFormatParser } from './parsers/TextFormatParser';
export { XmlFormatParser } from './parsers/XmlFormatParser';
export { HuaweiKitParser } from './parsers/HuaweiKitParser';
export { DjvuParser } from './parsers/DjvuParser';
export { ChmParser } from './parsers/ChmParser';
export { OtherFormatParser } from './parsers/OtherFormatParser';
export { rarParser } from './parsers/RarParser';
