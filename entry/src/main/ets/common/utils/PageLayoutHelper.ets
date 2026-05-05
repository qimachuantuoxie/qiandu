/**
 * Page Layout Helper - 页面布局辅助工具
 * 
 * 提供统一的页面结构、导航栏、内容区域等布局组件
 */

import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../design/tokens/HDSDTokens';
import { themeManager } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { goBack } from '../utils/NavigationHelper';

/**
 * 页面配置接口
 */
export interface PageConfig {
  title?: string;
  showBack?: boolean;
  backgroundColor?: string;
  padding?: number;
}

/**
 * 创建标准页面头部
 */
@Builder
export function PageHeader(config: {
  title: string;
  showBack?: boolean;
  onBack?: () => void;
  rightContent?: () => void;
}) {
  Row() {
    // 返回按钮
    if (config.showBack !== false) {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
          .fontWeight(FontWeight.Bold)
      }
      .width(40)
      .height(40)
      .borderRadius(HDSBorderRadius.full)
      .backgroundColor(themeManager.isDarkMode() ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (config.onBack) {
          config.onBack();
        } else {
          try {
            goBack();
          } catch (error) {
            console.error('[PageHeader] Back failed:', error);
          }
        }
      })
    }
    
    // 标题
    Text(config.title)
      .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.xl))
      .fontWeight(FontWeight.Semibold)
      .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
    
    // 右侧内容（可选）
    if (config.rightContent) {
      Row() {
        config.rightContent!()
      }
      .justifyContent(FlexAlign.End)
    } else {
      // 占位，保持标题居中
      Row().width(40)
    }
  }
  .width('100%')
  .padding({
    left: config.showBack !== false ? HDSSpacing.lg : HDSSpacing.xl,
    right: HDSSpacing.lg,
    top: HDSSpacing.lg,
    bottom: HDSSpacing.md
  })
}

/**
 * 创建空状态页面
 */
@Builder
export function EmptyState(config: {
  icon?: string;
  title: string;
  subtitle?: string;
  actionText?: string;
  onAction?: () => void;
}) {
  Column({ space: HDSSpacing.lg }) {
    // 图标
    Text(config.icon || '📭')
      .fontSize(64)
      .opacity(0.5)
    
    // 标题
    Text(config.title)
      .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.lg))
      .fontWeight(FontWeight.Medium)
      .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textPrimary : HDSColours.neutral.gray900)
    
    // 副标题
    if (config.subtitle) {
      Text(config.subtitle)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
        .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    
    // 操作按钮
    if (config.actionText && config.onAction) {
      Button(config.actionText)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
        .fontColor(HDSColours.primary.blue)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          config.onAction!();
        })
    }
  }
  .width('100%')
  .padding(HDSPacing.xxxl)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

/**
 * 创建加载状态
 */
@Builder
export function LoadingState(config: {
  message?: string;
}) {
  Column({ space: HDSSpacing.md }) {
    LoadingProgress()
      .width(48)
      .height(48)
      .color(HDSColours.primary.blue)
    
    if (config.message) {
      Text(config.message)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.sm))
        .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
    }
  }
  .width('100%')
  .padding(HDSPacing.xxxl)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

/**
 * 创建错误状态
 */
@Builder
export function ErrorState(config: {
  message: string;
  retryText?: string;
  onRetry?: () => void;
}) {
  Column({ space: HDSSpacing.lg }) {
    Text('⚠️')
      .fontSize(48)
      .opacity(0.5)
    
    Text(config.message)
      .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
      .fontColor(themeManager.isDarkMode() ? HDSColours.neutralDark.textSecondary : HDSColours.neutral.gray600)
      .textAlign(TextAlign.Center)
      .maxLines(3)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    
    if (config.retryText && config.onRetry) {
      Button(config.retryText)
        .fontSize(fontScaleManager.getScaledFontSize(HDSTypography.sizes.md))
        .fontColor(HDSColours.primary.blue)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          config.onRetry!();
        })
    }
  }
  .width('100%')
  .padding(HDSPacing.xxxl)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

/**
 * 获取页面背景色
 */
export function getPageBackgroundColor(): string {
  return themeManager.isDarkMode() 
    ? HDSColours.neutralDark.bgPrimary 
    : HDSColours.neutral.gray50;
}

/**
 * 获取卡片背景色
 */
export function getCardBackgroundColor(): string {
  return themeManager.isDarkMode() 
    ? HDSColours.neutralDark.surface 
    : HDSColours.neutral.white;
}

/**
 * 获取文本主色
 */
export function getTextPrimaryColor(): string {
  return themeManager.isDarkMode() 
    ? HDSColours.neutralDark.textPrimary 
    : HDSColours.neutral.gray900;
}

/**
 * 获取文本次要色
 */
export function getTextSecondaryColor(): string {
  return themeManager.isDarkMode() 
    ? HDSColours.neutralDark.textSecondary 
    : HDSColours.neutral.gray600;
}
