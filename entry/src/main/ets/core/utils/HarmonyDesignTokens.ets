/**
 * HarmonyOS Design Tokens - 绠€鍖栫増
 */

export interface IHarmonyColors {
  primary: string;
  background: string;
  backgroundSecondary: string;
  cardBackground: string;
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  border: string;
}

export class HarmonyColorsClass implements IHarmonyColors {
  primary: string = '#007DFF';
  background: string = '#FAFAFA';
  backgroundSecondary: string = '#F5F5F5';
  cardBackground: string = '#FFFFFF';
  textPrimary: string = '#333333';
  textSecondary: string = '#666666';
  textHint: string = '#999999';
  border: string = '#E5E5E5';
}

export const HarmonyColors: IHarmonyColors = new HarmonyColorsClass();

export const LightColors: IHarmonyColors = new HarmonyColorsClass();

export class DarkColorsClass implements IHarmonyColors {
  primary: string = '#007DFF';
  background: string = '#141414';
  backgroundSecondary: string = '#1A1A1A';
  cardBackground: string = '#242424';
  textPrimary: string = '#E0E0E0';
  textSecondary: string = '#AAAAAA';
  textHint: string = '#777777';
  border: string = '#333333';
}

export const DarkColors: IHarmonyColors = new DarkColorsClass();

export function getColors(isDark: boolean): IHarmonyColors {
  return isDark ? DarkColors : LightColors;
}

export class SpacingTokensClass {
  xs: number = 4;
  sm: number = 8;
  md: number = 16;
  lg: number = 24;
  xl: number = 32;
}

export const SpacingTokens: SpacingTokensClass = new SpacingTokensClass();

export class FontSizeTokensClass {
  xs: number = 12;
  sm: number = 14;
  md: number = 16;
  lg: number = 18;
  xl: number = 20;
  xxl: number = 24;
}

export const FontSizeTokens: FontSizeTokensClass = new FontSizeTokensClass();

export interface IDarkModeColors {
  background: string;
  backgroundSecondary: string;
  cardBackground: string;
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  primary: string;
  border: string;
  surface: string;
}

export class DarkModeColorsClass implements IDarkModeColors {
  background: string = '#FAFAFA';
  backgroundSecondary: string = '#F5F5F5';
  cardBackground: string = '#FFFFFF';
  textPrimary: string = '#333333';
  textSecondary: string = '#666666';
  textHint: string = '#999999';
  primary: string = '#007DFF';
  border: string = '#E5E5E5';
  surface: string = 'rgba(255, 255, 255, 0.9)';
}

export class DarkModeColorsDarkClass implements IDarkModeColors {
  background: string = '#141414';
  backgroundSecondary: string = '#1A1A1A';
  cardBackground: string = '#242424';
  textPrimary: string = '#E0E0E0';
  textSecondary: string = '#AAAAAA';
  textHint: string = '#777777';
  primary: string = '#007DFF';
  border: string = '#333333';
  surface: string = 'rgba(40, 40, 40, 0.95)';
}

export function getDarkModeColors(isDark: boolean): IDarkModeColors {
  return isDark ? new DarkModeColorsDarkClass() : new DarkModeColorsClass();
}

export interface IGlassCardStyle {
  backgroundColor: string;
  backdropFilter: string;
  borderWidth: number;
  borderColor: string;
  borderRadius: number;
}

export class GlassCardStyleClass implements IGlassCardStyle {
  backgroundColor: string = '';
  backdropFilter: string = 'blur(20px)';
  borderWidth: number = 1;
  borderColor: string = 'rgba(255, 255, 255, 0.3)';
  borderRadius: number = 16;
}

export function createGlassCardStyle(isDark: boolean, intensity: number = 0.3): IGlassCardStyle {
  const alpha = intensity;
  const style = new GlassCardStyleClass();
  style.backgroundColor = isDark ? 'rgba(255, 255, 255, ' + (alpha * 0.1) + ')' : 'rgba(255, 255, 255, ' + alpha + ')';
  style.borderColor = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(255, 255, 255, 0.3)';
  return style;
}
