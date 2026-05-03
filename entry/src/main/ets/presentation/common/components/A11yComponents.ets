/**
 * 无障碍 (Accessibility) 基础组件库
 * 封装标准触控区域、朗读文本、焦点管理等
 */

interface SpaceConfig {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface RadiusConfig {
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface ColorConfig {
  primary: string;
  error: string;
  bgSurfaceDark: string;
  bgMain: string;
  bgMainDark: string;
  bgSurface: string;
}

// 常量定义
const SPACE: SpaceConfig = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32
};

const TOUCH_TARGET_MIN = 48;

const RADIUS: RadiusConfig = {
  sm: 4,
  md: 8,
  lg: 16,
  xl: 24
};

const COLORS: ColorConfig = {
  primary: '#007DFF',
  error: '#FF3B30',
  bgSurfaceDark: '#1C1C1E',
  bgMain: '#F5F5F5',
  bgMainDark: '#000000',
  bgSurface: '#FFFFFF'
};

/**
 * 按钮颜色接口
 */
interface ButtonColors {
  bgColor: string;
  fontColor: string;
}

/**
 * 鏃犻殰纰嶆寜閽?
 * 淇濊瘉鏈€灏忚Е鎺у尯鍩?48x48vp锛岃嚜鍔ㄦ湕璇?
 */
@Component
export struct A11yButton {
  @Prop text: string = '';
  @Prop icon: string = '';
  @Prop btnType: string = 'primary';
  @Prop btnEnabled: boolean = true;
  onClickCallback?: () => void;

  build() {
    Button() {
      Row({ space: SPACE.xs }) {
        if (this.icon) {
          Image(this.icon)
            .width(20)
            .height(20)
            .fillColor(this.getButtonColor().fontColor)
        }
        Text(this.text)
          .fontColor(this.getButtonColor().fontColor)
          .fontSize(16)
      }
      .justifyContent(FlexAlign.Center)
    }
    .type(ButtonType.Normal)
    .height(TOUCH_TARGET_MIN)
    .backgroundColor(this.getButtonColor().bgColor)
    .borderRadius(RADIUS.md)
    .enabled(this.btnEnabled)
    .onClick(() => {
      if (this.onClickCallback) {
        this.onClickCallback();
      }
    })
    .accessibilityText(this.text)
    .accessibilityTextHint('双击激活')
  }

  private getButtonColor(): ButtonColors {
    const colors: ButtonColors = { bgColor: '#CCC', fontColor: '#000' };
    
    if (!this.btnEnabled) {
      colors.bgColor = '#E5E5EA';
      colors.fontColor = '#999';
      return colors;
    }
    
    if (this.btnType === 'primary') {
      colors.bgColor = COLORS.primary;
      colors.fontColor = '#FFF';
      return colors;
    }
    
    if (this.btnType === 'secondary') {
      colors.bgColor = '#E5E5EA';
      colors.fontColor = '#333';
      return colors;
    }
    
    if (this.btnType === 'danger') {
      colors.bgColor = COLORS.error;
      colors.fontColor = '#FFF';
      return colors;
    }
    
    return colors;
  }
}

/**
 * 鏃犻殰纰嶅浘鐗?
 * 寮哄埗瑕佹眰 alt 鏂囨湰锛岄伩鍏嶈灞忚蒋浠舵湕璇?"Image"
 */
@Component
export struct A11yImage {
  @Prop src: string = '';
  @Prop alt: string = '鍥剧墖';
  @Prop imgWidth: number = 100;
  @Prop imgHeight: number = 100;
  @Prop imgBorderRadius: number = 0;
  @Prop objectFit: ImageFit = ImageFit.Cover;

  build() {
    Image(this.src)
      .width(this.imgWidth)
      .height(this.imgHeight)
      .borderRadius({
        topLeft: this.imgBorderRadius,
        topRight: this.imgBorderRadius,
        bottomRight: this.imgBorderRadius,
        bottomLeft: this.imgBorderRadius
      })
      .objectFit(this.objectFit)
      .accessibilityText(this.alt)
  }
}

/**
 * 鏃犻殰纰嶅垪琛ㄩ」
 * 灏嗘爣棰樸€佸壇鏍囬銆佹搷浣滄暣鍚堜负涓€涓湕璇诲崟鍏?
 */
@Component
export struct A11yListItem {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop icon: string = '';
  itemClickCallback?: () => void;

  build() {
    Row({ space: SPACE.sm }) {
      if (this.icon) {
        Image(this.icon)
          .width(24)
          .height(24)
      }
      Column({ space: SPACE.xs }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor('#666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor('#CCC')
    }
    .height(56)
    .padding({ left: SPACE.md, right: SPACE.md })
    .width('100%')
    .onClick(() => {
      if (this.itemClickCallback) {
        this.itemClickCallback();
      }
    })
    .accessibilityGroup(true)
    .accessibilityText(this.title + (this.subtitle ? '，' + this.subtitle : ''))
    .accessibilityTextHint('双击进入')
  }
}
