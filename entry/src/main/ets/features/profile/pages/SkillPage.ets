import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferenceManager } from '../../../core/utils/PreferenceManager';
import { themeManager, AppColors, COMMON_COLORS } from '../../../core/utils/AppTheme';
import { fontScaleManager } from '../../../core/utils/FontScaleManager';
import { PageHeader, getPageBackgroundColor } from '../../../common/utils/PageLayoutHelper';
import { HDSCard } from '../../../common/components/HDSCard';
import { DialogHelper } from '../../../common/utils/DialogHelper';
import { HDSColours, HDSSpacing, HDSBorderRadius, HDSTypography } from '../../../core/design/tokens/HDSDTokens';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

interface SkillItem {
  id: string;
  name: string;
  description: string;
  icon: string;
  level: number;
  maxLevel: number;
  color: string;
}

@Entry
@ComponentV2
struct SkillPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  private context: common.Context | null = null;

  private skillList: SkillItem[] = [
    {
      id: '1',
      name: '快速阅读',
      description: '提升阅读速度，一目十行',
      icon: 'gauge.high',
      level: 3,
      maxLevel: 5,
      color: COMMON_COLORS.PRIMARY_BLUE
    },
    {
      id: '2',
      name: '深度理解',
      description: '增强内容理解和记忆',
      icon: 'brain.head.profile',
      level: 2,
      maxLevel: 5,
      color: '#722ED1'
    },
    {
      id: '3',
      name: '笔记整理',
      description: '高效整理和管理笔记',
      icon: 'note.text',
      level: 4,
      maxLevel: 5,
      color: '#52C41A'
    },
    {
      id: '4',
      name: '词汇积累',
      description: '扩展词汇量和表达能力',
      icon: 'character.bubble',
      level: 1,
      maxLevel: 5,
      color: '#FA8C16'
    },
    {
      id: '5',
      name: '专注力',
      description: '提高阅读专注度和持久力',
      icon: 'eye',
      level: 3,
      maxLevel: 5,
      color: '#FF6B6B'
    }
  ];

  async aboutToAppear(): Promise<void> {
    this.context = this.getUIContext().getHostContext() as common.Context;
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    if (this.context) {
      await layoutHelper.init(this.context);
      this.screenInfo = layoutHelper.getScreenInfo();
      await preferenceManager.init(this.context);
    }
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private getProgress(level: number, maxLevel: number): number {
    return level / maxLevel;
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron.left'))
            .fontSize(Size.iconLG)
            .fontColor([this.tc('#1A1A1A', '#FFFFFF')])
        }
        .width(Size.buttonMD)
        .height(Size.buttonMD)
        .borderRadius(BorderRadius.full)
        .backgroundColor(this.tc('rgba(0,0,0,0.05)', 'rgba(255,255,255,0.1)'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          try {
            goBack();
          } catch (error) {
            const msg = error instanceof Error ? error.message : String(error);
            logger.error('[SkillPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('阅读技能')
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.SemiBold)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(Size.buttonMD)
      }
      .width('100%')
      .height(Size.buttonLG + Spacing.sm)
      .padding({ left: Spacing.lg, right: Spacing.lg })
      .backgroundColor(this.tc('#FFFFFF', '#1A1A1A'))
      .shadow(getShadow('sm', this.isDarkMode))

      // 内容区域
      Scroll() {
        Column({ space: Spacing.lg }) {
          // 头部说明
          Column({ space: Spacing.md }) {
            Row({ space: Spacing.md }) {
              Column() {
                SymbolGlyph($r('sys.symbol.wand.and.stars'))
                  .fontSize(Size.iconXL)
                  .fontColor(['#FFFFFF'])
              }
              .width(Size.avatarLG)
              .height(Size.avatarLG)
              .borderRadius(BorderRadius.lg)
              .linearGradient({
                direction: GradientDirection.Top,
                colors: ['#FFD700', '#FFA500']
              })
              .justifyContent(FlexAlign.Center)

              Column({ space: Spacing.xs }) {
                Text('技能系统')
                  .fontSize(fontScaleManager.getScaledFontSize(17))
                  .fontWeight(FontWeight.SemiBold)
                  .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

                Text('通过阅读提升各项能力等级')
                  .fontSize(fontScaleManager.getScaledFontSize(13))
                  .fontColor(this.tc('#8E8E93', '#8E8E93'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
          }
          .width('100%')
          .padding(Spacing.xl)
          .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
          .borderRadius(BorderRadius.xl)
          .shadow(getShadow('md', this.isDarkMode))

          // 技能列表标题
          Row() {
            SymbolGlyph($r('sys.symbol.star.fill'))
              .fontSize(Size.iconLG)
              .fontColor(['#FFD700'])
            
            Text('我的技能')
              .fontSize(fontScaleManager.getScaledFontSize(17))
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              .layoutWeight(1)
              .margin({ left: Spacing.sm })
          }
          .width('100%')

          // 技能列表
          List({ space: Spacing.md }) {
            ForEach(this.skillList, (skill: SkillItem) => {
              ListItem() {
                this.SkillItem(skill)
              }
            }, (skill: SkillItem) => skill.id)
          }
          .width('100%')
          .scrollBar(BarState.Off)

          // 底部提示
          Row({ space: Spacing.xs }) {
            SymbolGlyph($r('sys.symbol.info.circle'))
              .fontSize(Size.iconSM)
              .fontColor([this.tc('#8E8E93', '#8E8E93')])
            
            Text('持续阅读可提升技能等级')
              .fontSize(fontScaleManager.getScaledFontSize(12))
              .fontColor(this.tc('#8E8E93', '#8E8E93'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: Spacing.xxxl })
        }
        .width('100%')
        .padding({ 
          left: Spacing.lg, 
          right: Spacing.lg, 
          top: Spacing.lg,
          bottom: Spacing.xxxl
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bg('#F8F9FA', '#0F0F0F'))
  }

  @Builder
  SkillItem(skill: SkillItem) {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.lg }) {
        // 图标容器
        Column() {
          SymbolGlyph($r(`sys.symbol.${skill.icon}`))
            .fontSize(Size.iconXL)
            .fontColor([skill.color])
        }
        .width(Size.avatarLG)
        .height(Size.avatarLG)
        .borderRadius(BorderRadius.lg)
        .backgroundColor(skill.color + '15')
        .justifyContent(FlexAlign.Center)

        // 内容
        Column({ space: Spacing.xs }) {
          Text(skill.name)
            .fontSize(fontScaleManager.getScaledFontSize(15))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

          Text(skill.description)
            .fontSize(fontScaleManager.getScaledFontSize(12))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 等级徽章
        Column({ space: Spacing.xs }) {
          Text('Lv.' + skill.level)
            .fontSize(fontScaleManager.getScaledFontSize(16))
            .fontWeight(FontWeight.Bold)
            .fontColor(skill.color)

          Text('/ ' + skill.maxLevel)
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      // 进度条
      Column({ space: Spacing.xs }) {
        Progress({ value: skill.level, total: skill.maxLevel, type: ProgressType.Linear })
          .width('100%')
          .height(6)
          .borderRadius(BorderRadius.xl)
          .color(skill.color)
          .backgroundColor(this.tc('rgba(0,0,0,0.06)', 'rgba(255,255,255,0.1)'))

        Row() {
          Text('进度')
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontColor(this.tc('#8E8E93', '#8E8E93'))
          
          Blank()

          Text(`${Math.floor(this.getProgress(skill.level, skill.maxLevel) * 100)}%`)
            .fontSize(fontScaleManager.getScaledFontSize(11))
            .fontWeight(FontWeight.Medium)
            .fontColor(skill.color)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
    .borderRadius(BorderRadius.xl)
    .shadow(getShadow('sm', this.isDarkMode))
    .stateStyles({
      pressed: { 
        .scale({ x: 0.98, y: 0.98 }),
        .backgroundColor(this.tc('rgba(0,0,0,0.03)', 'rgba(255,255,255,0.05)'))
      },
      normal: { 
        .scale({ x: 1, y: 1 }),
        .backgroundColor(this.tc('#FFFFFF', '#1E1E2E'))
      }
    })
  }
}

// 预览组件
@Preview
@ComponentV2
struct SkillPagePreview {
  build() {
    Column() {
      Text('阅读技能 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      SkillPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('阅读技能 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SkillPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
