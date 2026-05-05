/**
 * 应用根级统一导出
 * V3 架构 - 单一导入入口
 */

// 核心模块
export * from './core';

// 公共模块
export * from './common';

// 功能模块
export * from './features';

// 页面入口
// export * from './pages'; // 页面不使用统一导出，保持独立
// ViewModels（兼容层）
export * from './core/viewmodels';
