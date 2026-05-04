import { logger } from '../../../common/utils/Logger';
import { navigateTo, goBack } from '../../../common/utils/NavigationHelper';
import { router, promptAction } from '@kit.ArkUI';
import { themeManager, AppColors } from '../core/utils/AppTheme';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { fontScaleManager } from '../core/utils/FontScaleManager';
import { skillViewModel, SkillViewModel, SkillItem } from '../viewmodels/SkillViewModel';
import { BackButton } from '../components/common/BackButton';
import { layoutHelper, ScreenInfo } from '../common/utils/LayoutHelper';

@Entry
@Component
struct SkillPage {
  @State isDarkMode: boolean = false;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State screenInfo: ScreenInfo | null = null;

  private vm: SkillViewModel = skillViewModel;

  async aboutToAppear(): Promise<void> {
    this.isDarkMode = themeManager.isDarkMode();
    this.currentColors = themeManager.getColors();
    this.fontScale = await fontScaleManager.getFontScale();
    await this.initData();
  }

  private async initData(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context) {
      await layoutHelper.init(context);
      this.screenInfo = layoutHelper.getScreenInfo();
    }
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
    const msg = skill.unlocked ? `${skill.name}宸茶В閿乣 : `${skill.name}宸查攣瀹歚;
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch(e) { logger.error('showToast error:', e); }
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
          Text(`绛夌骇 ${skill.level}`)
            .fontSize(11)
            .fontColor(this.currentColors.primary)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (skill.unlocked) {
        Button() {
          Text(this.vm.selectedSkill?.id === skill.id ? '锟? : '馃幆')
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
          Text(`绛夌骇: ${this.vm.selectedSkill?.level || 1}`)
            .fontSize(14)
            .fontColor(this.currentColors.primary)
            .fontWeight(FontWeight.Medium)

          Text(this.vm.selectedSkill?.unlocked ? '宸茶В锟? : '鏈�В锟?)
            .fontSize(14)
            .fontColor(this.vm.selectedSkill?.unlocked ? '#4CAF50' : this.tc('#999999', '#888888'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Button('鍏抽棴')
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
          BackButton({ isDarkMode: this.isDarkMode })

          Text('鎶€鑳戒腑锟?)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tc('#333333', '#FFFFFF'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text(`Lv.${this.vm.level} | ${this.vm.experience}缁忛獙`)
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
          Text('馃挕 鎻愮ず')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tc('#333333', '#FFFFFF'))
          Text('瀹屾垚浠诲姟瑙ｉ攣鎶€鑳斤紝鎸佺画鎻愬崌绛夌骇鑾峰緱鏇村�濂栧姳')
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

// 棰勮�缁勪欢 - 鐢ㄤ簬DevEco Studio棰勮�锟?
@Preview
@Component
struct SkillPagePreview {
  build() {
    Column() {
      Text('鎶€鑳戒腑蹇冮〉 - 娴呰壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#F0F0F0')

      SkillPage()
        .height(700)

      Divider()
        .margin({ top: 20, bottom: 20 })

      Text('鎶€鑳戒腑蹇冮〉 - 娣辫壊妯″紡')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#333333')
        .fontColor('#FFFFFF')

      SkillPage()
        .height(700)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}