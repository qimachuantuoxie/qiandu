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

interface RewardItem {
  id: string;
  title: string;
  description: string;
  icon: string;
  points: number;
  color: string;
}

@Entry
@ComponentV2
struct RewardPage {
  @Local isDarkMode: boolean = false;
  @Local currentColors: AppColors = themeManager.getColors();
  @Local fontScale: number = 1.0;
  @Local screenInfo: ScreenInfo | null = null;
  @Local userPoints: number = 1250;
  private context: common.Context | null = null;

  private rewardList: RewardItem[] = [
    {
      id: '1',
      title: '连续阅读7天',
      description: '保持阅读习惯，获得奖励',
      icon: 'calendar.badge.clock',
      points: 100,
      color: '#52C41A'
    },
    {
      id: '2',
      title: '完成一本书',
      description: '读完一本完整的书籍',
      icon: 'book.fill',
      points: 200,
      color: COMMON_COLORS.PRIMARY_BLUE
    },
    {
      id: '3',
      title: '添加10个书签',
      description: '收藏精彩段落',
      icon: 'bookmark.fill',
      points: 50,
      color: '#FA8C16'
    },
    {
      id: '4',
      title: '撰写5篇笔记',
      description: '记录阅读心得',
      icon: 'note.text',
      points: 150,
      color: '#722ED1'
    },
    {
      id: '5',
      title: '分享应用',
      description: '邀请好友使用',
      icon: 'square.and.arrow.up',
      points: 300,
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
            logger.error('[RewardPage] back failed:', msg);
          }
        })
        .stateStyles({
          pressed: { .scale({ x: 0.9, y: 0.9 }) },
          normal: { .scale({ x: 1, y: 1 }) }
        })

        Text('积分奖励')
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
          // 积分卡片
          Column({ space: Spacing.md }) {
            Row({ space: Spacing.lg }) {
              // 积分图标
              Column() {
                SymbolGlyph($r('sys.symbol.star.fill'))
                  .fontSize(Size.iconXXXL)
                  .fontColor(['#FFD700'])
              }
              .width(80)
              .height(80)
              .borderRadius(BorderRadius.full)
              .linearGradient({
                direction: GradientDirection.Top,
                colors: ['rgba(255,215,0,0.2)', 'rgba(255,165,0,0.1)']
              })
              .justifyContent(FlexAlign.Center)

              Column({ space: Spacing.sm }) {
                Text('我的积分')
                  .fontSize(fontScaleManager.getScaledFontSize(14))
                  .fontColor(this.tc('#8E8E93', '#8E8E93'))

                Text(this.userPoints.toString())
                  .fontSize(fontScaleManager.getScaledFontSize(36))
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFD700')

                Text('积分可用于兑换奖励')
                  .fontSize(fontScaleManager.getScaledFontSize(12))
                  .fontColor(this.tc('#8E8E93', '#8E8E93'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            // 积分规则提示
            Row({ space: Spacing.xs }) {
              SymbolGlyph($r('sys.symbol.info.circle'))
                .fontSize(Size.iconSM)
                .fontColor([this.tc('#8E8E93', '#8E8E93')])
              
              Text('完成任务即可获得积分奖励')
                .fontSize(fontScaleManager.getScaledFontSize(12))
                .fontColor(this.tc('#8E8E93', '#8E8E93'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding(Spacing.xl)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: this.isDarkMode 
              ? ['rgba(255,215,0,0.15)', 'rgba(255,165,0,0.08)']
              : ['rgba(255,215,0,0.2)', 'rgba(255,165,0,0.1)']
          })
          .borderRadius(BorderRadius.xl)
          .border({ 
            width: 1.5, 
            color: this.isDarkMode ? 'rgba(255,215,0,0.3)' : 'rgba(255,215,0,0.4)' 
          })
          .shadow({
            radius: 12,
            color: 'rgba(255,215,0,0.2)',
            offsetY: 6
          })

          // 任务列表标题
          Row() {
            SymbolGlyph($r('sys.symbol.list.bullet'))
              .fontSize(Size.iconLG)
              .fontColor([this.currentColors.primary])
            
            Text('积分任务')
              .fontSize(fontScaleManager.getScaledFontSize(17))
              .fontWeight(FontWeight.SemiBold)
              .fontColor(this.tc('#1A1A1A', '#FFFFFF'))
              .layoutWeight(1)
              .margin({ left: Spacing.sm })

            Text('查看全部')
              .fontSize(fontScaleManager.getScaledFontSize(13))
              .fontColor(this.currentColors.primary)
          }
          .width('100%')

          // 任务列表
          List({ space: Spacing.md }) {
            ForEach(this.rewardList, (reward: RewardItem) => {
              ListItem() {
                this.RewardItem(reward)
              }
            }, (reward: RewardItem) => reward.id)
          }
          .width('100%')
          .scrollBar(BarState.Off)
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
  RewardItem(reward: RewardItem) {
    Row({ space: Spacing.lg }) {
      // 图标容器
      Column() {
        SymbolGlyph($r(`sys.symbol.${reward.icon}`))
          .fontSize(Size.iconXL)
          .fontColor([reward.color])
      }
      .width(Size.avatarLG)
      .height(Size.avatarLG)
      .borderRadius(BorderRadius.lg)
      .backgroundColor(reward.color + '15')
      .justifyContent(FlexAlign.Center)

      // 内容
      Column({ space: Spacing.xs }) {
        Text(reward.title)
          .fontSize(fontScaleManager.getScaledFontSize(15))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tc('#1A1A1A', '#FFFFFF'))

        Text(reward.description)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.tc('#8E8E93', '#8E8E93'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 积分徽章
      Column({ space: Spacing.xs }) {
        Row({ space: Spacing.xs }) {
          SymbolGlyph($r('sys.symbol.star.fill'))
            .fontSize(Size.iconXS)
            .fontColor(['#FFD700'])
          
          Text('+' + reward.points)
            .fontSize(fontScaleManager.getScaledFontSize(14))
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
        }

        Button('领取')
          .height(Size.buttonSM)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor('#FFFFFF')
          .backgroundColor(reward.color)
          .borderRadius(BorderRadius.xl)
          .padding({ left: Spacing.md, right: Spacing.md })
          .onClick(() => {
            promptAction.showToast({ message: `已领取 ${reward.points} 积分`, duration: 1500 });
            this.userPoints += reward.points;
          })
          .stateStyles({
            pressed: { .scale({ x: 0.95, y: 0.95 }) },
            normal: { .scale({ x: 1, y: 1 }) }
          })
      }
      .alignItems(HorizontalAlign.End)
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
struct RewardPagePreview {
  build() {
    Column() {
      Text('积分奖励 - 浅色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#F0F0F0')

      RewardPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('积分奖励 - 深色模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(Spacing.md)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      RewardPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
