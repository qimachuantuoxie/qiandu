/**
 * 鎼存梻鏁ょ敮鎼佸櫤鐎规矮绠? * 
 * 缂佺喍绔寸粻锛勬倞閹碘偓閺堝鐡熷▔鏇熸殶鐎涙绱濋幓鎰扮彯娴狅絿鐖滈崣顖滄樊閹躲倖鈧? */

// ==================== 缂冩垹绮堕惄绋垮彠鐢悂鍣?====================

/** HTTP 鐠囬攱鐪版妯款吇鐡掑懏妞傞弮鍫曟？閿涘牊顕犵粔鎺炵礆 */
export const HTTP_TIMEOUT_MS = 15000;

/** 娑旓附绨幖婊呭偍鐡掑懏妞傞弮鍫曟？閿涘牊顕犵粔鎺炵礆 */
export const SOURCE_TEST_TIMEOUT_MS = 30000;

/** HTTP 閺堚偓婢堆囧櫢鐠囨洘顐奸弫?*/
export const HTTP_MAX_RETRY_COUNT = 2;

/** 闂€鑳箾閹恒儴绉撮弮鑸垫闂傝揪绱欏В顐ゎ潡閿?*/
export const LONG_TIMEOUT_MS = 30000;

// ==================== 缂傛挸鐡ㄩ惄绋垮彠鐢悂鍣?====================

/** 閸ュ墽澧栫紓鎾崇摠閺堚偓婢堆冦亣鐏忓骏绱?00MB閿?*/
export const MAX_CACHE_SIZE = 200 * 1024 * 1024;

/** 缂傛挸鐡ㄦ潻鍥ㄦ埂閺冨爼妫块敍?4鐏忓繑妞傞敍灞绢嚑缁夋帪绱?*/
export const CACHE_EXPIRY_MS = 24 * 60 * 60 * 1000;

// ==================== 閺冨爼妫块惄绋垮彠鐢悂鍣?====================

/** 娑撯偓楠炲娈戝В顐ゎ潡閺?*/
export const ONE_YEAR_MS = 365 * 24 * 60 * 60 * 1000;

/** 娑撯偓婢垛晝娈戝В顐ゎ潡閺?*/
export const ONE_DAY_MS = 24 * 60 * 60 * 1000;

/** 娑撯偓閸掑棝鎸撻惃鍕嚑缁夋帗鏆?*/
export const ONE_MINUTE_MS = 60 * 1000;

/** 娑撯偓缁夋帡鎸撻惃鍕嚑缁夋帗鏆?*/
export const ONE_SECOND_MS = 1000;

// ==================== UI 閻╃鍙х敮鎼佸櫤 ====================

/** Toast 閺勫墽銇氶弮鍫曟毐閿涘牏鐓敍澶嬵嚑缁?*/
export const TOAST_DURATION_SHORT = 1500;

/** Toast 閺勫墽銇氶弮鍫曟毐閿涘牓鏆遍敍澶嬵嚑缁?*/
export const TOAST_DURATION_LONG = 3000;

/** 閸斻劎鏁炬妯款吇閺冨爼鏆遍敍鍫燁嚑缁夋帪绱?*/
export const ANIMATION_DURATION = 300;

/** 闂冨弶濮堝鎯扮箿閺冨爼妫块敍鍫燁嚑缁夋帪绱?*/
export const DEBOUNCE_DELAY = 300;

/** 閼哄倹绁﹂梻鎾閺冨爼妫块敍鍫燁嚑缁夋帪绱?*/
export const THROTTLE_INTERVAL = 500;

// ==================== 閸掑棝銆夐惄绋垮彠鐢悂鍣?====================

/** 姒涙顓诲В蹇涖€夐崝鐘烘祰閺佷即鍣?*/
export const DEFAULT_PAGE_SIZE = 20;

/** 娑旓附绨ù瀣槸濮ｅ繑澹掗弫浼村櫤 */
export const SOURCE_TEST_BATCH_SIZE = 10;

// ==================== 閺傚洣娆㈤惄绋垮彠鐢悂鍣?====================

/** 閺€顖涘瘮閻ㄥ嫪鍔熼張顒佺壐瀵?*/
export const SUPPORTED_BOOK_FORMATS = ['.epub', '.txt', '.pdf', '.rar', '.zip', '.cbz', '.cbr'];

/** 閺€顖涘瘮閻ㄥ嫬娴橀悧鍥ㄧ壐瀵?*/
export const SUPPORTED_IMAGE_FORMATS = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

/** 婢跺洣鍞ら弬鍥︽閻楀牊婀?*/
export const BACKUP_VERSION = '1.0.0';

// ==================== 閺冦儱绻旈惄绋垮彠鐢悂鍣?====================

/** 閺冦儱绻旈崺?- 鎼存梻鏁?*/
export const LOG_DOMAIN_APP = 0x0000;

/** 閺冦儱绻旈崺?- 缂冩垹绮?*/
export const LOG_DOMAIN_NETWORK = 0x0001;

/** 閺冦儱绻旈崺?- 閺佺増宓佹惔?*/
export const LOG_DOMAIN_DATABASE = 0x0002;
