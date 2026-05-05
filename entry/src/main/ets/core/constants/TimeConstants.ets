/**
 * Time Constants - 时间常量定义
 * 
 * 统一管理系统中使用的时间相关常量，避免魔法数字
 */

// ==================== 基础时间单位（毫秒）====================
export const MS_PER_SECOND = 1000;
export const MS_PER_MINUTE = 60 * MS_PER_SECOND;        // 60,000
export const MS_PER_HOUR = 60 * MS_PER_MINUTE;          // 3,600,000
export const MS_PER_DAY = 24 * MS_PER_HOUR;             // 86,400,000
export const MS_PER_WEEK = 7 * MS_PER_DAY;              // 604,800,000
export const MS_PER_MONTH = 30 * MS_PER_DAY;            // 2,592,000,000 (按30天)
export const MS_PER_YEAR = 365 * MS_PER_DAY;            // 31,536,000,000 (按365天)

// ==================== 常用时间间隔 ====================
export const TIMEOUT_SHORT = 5 * MS_PER_SECOND;         // 5秒
export const TIMEOUT_MEDIUM = 30 * MS_PER_SECOND;       // 30秒
export const TIMEOUT_LONG = 5 * MS_PER_MINUTE;          // 5分钟

// ==================== 缓存过期时间 ====================
export const CACHE_TTL_SHORT = 5 * MS_PER_MINUTE;       // 短缓存：5分钟
export const CACHE_TTL_MEDIUM = MS_PER_HOUR;            // 中缓存：1小时
export const CACHE_TTL_LONG = MS_PER_DAY;               // 长缓存：24小时
export const CACHE_IMAGE = 7 * MS_PER_DAY;              // 图片缓存：7天

// ==================== 业务相关时间 ====================
export const SESSION_TIMEOUT = 30 * MS_PER_MINUTE;      // 会话超时：30分钟
export const TOKEN_REFRESH_THRESHOLD = 5 * MS_PER_MINUTE; // Token刷新阈值：5分钟
export const TRASH_RETENTION = 30 * MS_PER_DAY;         // 回收站保留：30天
export const ACCOUNT_EXPIRY = MS_PER_YEAR;              // 账户过期：1年
