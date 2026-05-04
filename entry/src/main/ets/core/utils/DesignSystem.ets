/**
 * Design System - Stub implementation
 * TODO: Implement full design system
 */
export interface DesignTokens {
  spacing: Record<string, number>;
  borderRadius: Record<string, number>;
  shadows: Record<string, string>;
}

export interface DesignSystem {
  tokens: DesignTokens;
}

export interface SpacingToken {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

export interface BorderRadiusToken {
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

export interface ShadowToken {
  sm: string;
  md: string;
  lg: string;
}

const defaultTokens: DesignTokens = {
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 } as SpacingToken,
  borderRadius: { sm: 4, md: 8, lg: 16, xl: 24 } as BorderRadiusToken,
  shadows: { sm: '0 1px 2px rgba(0,0,0,0.1)', md: '0 2px 8px rgba(0,0,0,0.15)', lg: '0 4px 16px rgba(0,0,0,0.2)' } as ShadowToken
};

export const designSystem: DesignSystem = {
  tokens: defaultTokens
};
