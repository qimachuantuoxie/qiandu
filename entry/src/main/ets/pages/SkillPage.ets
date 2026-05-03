import { router, promptAction } from '@kit.ArkUI';
import { themeManager, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { skillViewModel, SkillViewModel, SkillItem } from '../viewmodels/SkillViewModel';

@Entry
@Component
struct SkillPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;

  private vm: SkillViewModel = skillViewModel;

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    await this.vm.init();
  }

  private tc(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private bg(light: string, dark: string): string {
    return this.isDarkMode ? dark : light;
  }

  private toggleSkill(skill: SkillItem): void {
    skill.unlocked = !skill.unlocked;
    const msg = skill.unlocked ? `${skill.name}已解锁` : `${skill.name}已锁定`;
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch(e) { console.error('showToast error:', e); }
  }

  @Builder
  buildSkillItem(skill: SkillItem) {
    Row({ space: 12 }) {
      Stack() {
        Circle({ width: 56, height: 56 })
          .fill(skill.unlocked ? this.currentColors.primary + '20' : this.bg('#F5F5F5', '#3C3C3E'))
        Text(skill.icon)
          .fontSize(28)
      }

      Column({ space: 4 }) {
        Row() {
          Text(skill.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: skill.unlocked })
            .onChange(() => { this.toggleSkill(skill); })
        }
        .width('100%')

        Text(skill.description)
          .fontSize(12)
          .fontColor(this.tc('#666666', '#AAAAAA'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (skill.unlocked) {
          Text(`等级 ${skill.level}`)
            .fontSize(11)
            .fontColor(this.currentColors.primary)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (skill.unlocked) {
        Button() {
          Text(this.vm.selectedSkill?.id === skill.id ? '✓' : '🎯')
            .fontSize(16)
        }
        .width(36)
        .height(36)
        .backgroundColor(this.vm.selectedSkill?.id === skill.id ? '#4CAF50' : this.currentColors.primary)
        .borderRadius(18)
        .onClick(() => {
          if (this.vm.selectedSkill?.id === skill.id) {
            this.vm.clearSelection();
          } else {
            this.vm.selectSkill(skill);
          }
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
    .borderRadius(12)
    .border({
      width: 1,
      color: skill.unlocked ? this.currentColors.primary + '40' : this.bg('#EEEEEE', '#3C3C3E')
    })
    .onClick(() => {
      if (skill.unlocked) {
        this.vm.selectSkill(skill);
      }
    })
  }

  @Builder
  buildSkillDialog() {
    Stack() {
      Column({ space: 20 }) {
        Text(this.vm.selectedSkill?.icon || '')
          .fontSize(64)

        Text(this.vm.selectedSkill?.name || '')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tc('#333333', '#FFFFFF'))

        if (this.vm.selectedSkill) {
          Text(this.vm.selectedSkill.description)
            .fontSize(14)
            .fontColor(this.tc('#666666', '#AAAAAA'))
            .textAlign(TextAlign.Center)
        }

        Row({ space: 24 }) {
          Text(`等级: ${this.vm.selectedSkill?.level || 1}`)
            .fontSize(14)
            .fontColor(this.currentColors.primary)
            .fontWeight(FontWeight.Medium)

          Text(this.vm.selectedSkill?.unlocked ? '已解锁' : '未解锁')
            .fontSize(14)
            .fontColor(this.vm.selectedSkill?.unlocked ? '#4CAF50' : this.tc('#999999', '#888888'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Button('关闭')
          .width('80%')
          .height(44)
          .backgroundColor(this.currentColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .borderRadius(12)
          .onClick(() => { this.vm.clearSelection(); })
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => { this.vm.clearSelection(); })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button() {
            Text('←')
              .fontSize(24)
              .fontColor(this.tc('#333333', '#FFFFFF'))
          }
          .width(40)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.5)')
          .borderRadius(20)
          .onClick(() => { try { router.back(); } catch(e) { console.error('back error:', e); } })

          Text('技能中心')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text(`Lv.${this.vm.level} | ${this.vm.experience}经验`)
            .fontSize(12)
            .fontColor(this.currentColors.primary)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.currentColors.primary + '20')
            .borderRadius(12)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))

        Scroll() {
          Column({ space: 16 }) {
            ForEach(this.vm.skills, (skill: SkillItem) => {
              this.buildSkillItem(skill)
            })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.bg('#F5F5F5', '#141414'))

        Column({ space: 8 }) {
          Text('💡 提示')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))
          Text('完成任务解锁技能，持续提升等级获得更多奖励')
            .fontSize(11)
            .fontColor(this.tc('#666666', '#AAAAAA'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.bg('#FFFFFF', '#2C2C2E'))
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bg('#F5F5F5', '#141414'))

      if (this.vm.selectedSkill) {
        this.buildSkillDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}