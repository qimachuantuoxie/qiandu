/**
 * Dynamic Cover Service
 * Generates dynamic book cover data based on book metadata
 */

export enum CoverStyle {
  ABSTRACT = 'abstract',
  GRADIENT = 'gradient',
  PATTERN = 'pattern',
  MINIMAL = 'minimal'
}

export enum AnimationType {
  NONE = 'none',
  FADE = 'fade',
  SLIDE = 'slide',
  ZOOM = 'zoom'
}

export interface BookCoverData {
  id: string;
  title: string;
  author: string;
  style: CoverStyle;
  colors: string[];
  animationType: AnimationType;
}

export class DynamicCoverService {
  private static instance: DynamicCoverService;

  private constructor() {}

  static getInstance(): DynamicCoverService {
    if (!DynamicCoverService.instance) {
      DynamicCoverService.instance = new DynamicCoverService();
    }
    return DynamicCoverService.instance;
  }

  generateCoverData(title: string, author: string, id: string): BookCoverData {
    // Generate a simple deterministic color based on book id
    const colors = this.generateColors(id);
    const style = this.determineStyle(id);
    const animationType = AnimationType.NONE;

    return {
      id,
      title: title || '',
      author: author || '',
      style,
      colors,
      animationType
    };
  }

  private generateColors(id: string): string[] {
    // Simple hash-based color generation
    let hash = 0;
    for (let i = 0; i < id.length; i++) {
      hash = id.charCodeAt(i) + ((hash << 5) - hash);
    }
    
    const hue = Math.abs(hash % 360);
    const saturation = 70 + Math.abs(hash % 30);
    const lightness = 50 + Math.abs(hash % 20);
    
    const color1 = `hsl(${hue}, ${saturation}%, ${lightness}%)`;
    const color2 = `hsl(${(hue + 60) % 360}, ${saturation}%, ${lightness - 10}%)`;
    
    return [color1, color2];
  }

  private determineStyle(id: string): CoverStyle {
    // Simple deterministic style selection
    const hash = this.stringHash(id);
    const styles = [CoverStyle.ABSTRACT, CoverStyle.GRADIENT, CoverStyle.PATTERN, CoverStyle.MINIMAL];
    return styles[hash % styles.length];
  }

  private stringHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    return Math.abs(hash);
  }
}

export const dynamicCoverService = DynamicCoverService.getInstance();