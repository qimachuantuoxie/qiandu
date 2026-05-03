/**
 * 搴旂敤甯搁噺瀹氫箟
 * 
 * 缁熶竴绠＄悊鎵€鏈夐瓟娉曟暟瀛楋紝鎻愰珮浠ｇ爜鍙淮鎶ゆ€? */

// ==================== 缃戠粶鐩稿叧甯搁噺 ====================

/** HTTP 璇锋眰榛樿瓒呮椂鏃堕棿锛堟绉掞級 */
export const HTTP_TIMEOUT_MS = 15000;

/** 涔︽簮鎼滅储瓒呮椂鏃堕棿锛堟绉掞級 */
export const SOURCE_TEST_TIMEOUT_MS = 30000;

/** HTTP 鏈€澶ч噸璇曟鏁?*/
export const HTTP_MAX_RETRY_COUNT = 2;

/** 闀胯繛鎺ヨ秴鏃舵椂闂达紙姣锛?*/
export const LONG_TIMEOUT_MS = 30000;

// ==================== 缂撳瓨鐩稿叧甯搁噺 ====================

/** 鍥剧墖缂撳瓨鏈€澶уぇ灏忥紙200MB锛?*/
export const MAX_CACHE_SIZE = 200 * 1024 * 1024;

/** 缂撳瓨杩囨湡鏃堕棿锛?4灏忔椂锛屾绉掞級 */
export const CACHE_EXPIRY_MS = 24 * 60 * 60 * 1000;

// ==================== 鏃堕棿鐩稿叧甯搁噺 ====================

/** 涓€骞寸殑姣鏁?*/
export const ONE_YEAR_MS = 365 * 24 * 60 * 60 * 1000;

/** 涓€澶╃殑姣鏁?*/
export const ONE_DAY_MS = 24 * 60 * 60 * 1000;

/** 涓€鍒嗛挓鐨勬绉掓暟 */
export const ONE_MINUTE_MS = 60 * 1000;

/** 涓€绉掗挓鐨勬绉掓暟 */
export const ONE_SECOND_MS = 1000;

// ==================== UI 鐩稿叧甯搁噺 ====================

/** Toast 鏄剧ず鏃堕暱锛堢煭锛夋绉?*/
export const TOAST_DURATION_SHORT = 1500;

/** Toast 鏄剧ず鏃堕暱锛堥暱锛夋绉?*/
export const TOAST_DURATION_LONG = 3000;

/** 鍔ㄧ敾榛樿鏃堕暱锛堟绉掞級 */
export const ANIMATION_DURATION = 300;

/** 闃叉姈寤惰繜鏃堕棿锛堟绉掞級 */
export const DEBOUNCE_DELAY = 300;

/** 鑺傛祦闂撮殧鏃堕棿锛堟绉掞級 */
export const THROTTLE_INTERVAL = 500;

// ==================== 鍒嗛〉鐩稿叧甯搁噺 ====================

/** 榛樿姣忛〉鍔犺浇鏁伴噺 */
export const DEFAULT_PAGE_SIZE = 20;

/** 涔︽簮娴嬭瘯姣忔壒鏁伴噺 */
export const SOURCE_TEST_BATCH_SIZE = 10;

// ==================== 鏂囦欢鐩稿叧甯搁噺 ====================

/** 鏀寔鐨勪功鏈牸寮?*/
export const SUPPORTED_BOOK_FORMATS = ['.epub', '.txt', '.pdf', '.rar', '.zip', '.cbz', '.cbr'];

/** 鏀寔鐨勫浘鐗囨牸寮?*/
export const SUPPORTED_IMAGE_FORMATS = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

/** 澶囦唤鏂囦欢鐗堟湰 */
export const BACKUP_VERSION = '1.0.0';

// ==================== 鏃ュ織鐩稿叧甯搁噺 ====================

/** 鏃ュ織鍩?- 搴旂敤 */
export const LOG_DOMAIN_APP = 0x0000;

/** 鏃ュ織鍩?- 缃戠粶 */
export const LOG_DOMAIN_NETWORK = 0x0001;

/** 鏃ュ織鍩?- 鏁版嵁搴?*/
export const LOG_DOMAIN_DATABASE = 0x0002;
