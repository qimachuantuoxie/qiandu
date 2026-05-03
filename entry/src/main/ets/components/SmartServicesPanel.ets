/**
 * 智能服务面板 - 优化版（系统符号）
 * 使用 HarmonyOS SymbolGlyph 替代 Emoji，支持主题色
 *
 * @since 3.0.0
 */

import { toast } from '../utils/ToastHelper';
import { xiaoyiAgent, AgentResponse } from '../services/ai/XiaoyiAgentService';
import { harmonySkillService, SkillInfo } from '../services/reader/HarmonySkillService';
import { coreSpeechService } from '../services/ai/CoreSpeechService';
import { eyeTrackingService, EyeTrackingState } from '../services/ai/EyeTrackingService';
import { themeManager, COMMON_COLORS, AppColors } from '../utils/AppTheme';
import { fontScaleManager } from '../utils/FontScaleManager';
import { tr } from '../utils/I18nManager';
import { common } from '@kit.AbilityKit';

interface SmartServiceItem {
  icon: string;
  titleKey: string;
  subtitleKey: string;
  color: string;
  action: () => void;
}

interface VoiceAssistantState {
  isListening: boolean;
  isSpeaking: boolean;
  lastResponse: string;
}

@Component
export struct SmartServicesPanel {
  @Prop isDarkMode: boolean = false;
  @Prop panelContext: common.Context | null = null;
  @State currentColors: AppColors = themeManager.getColors();
  @State fontScale: number = 1.0;
  @State showVoiceAssistant: boolean = false;
  @State voiceState: VoiceAssistantState = {
    isListening: false,
    isSpeaking: false,
    lastResponse: ''
  };
  @State skills: SkillInfo[] = [];
  @State eyeTrackingState: EyeTrackingState = EyeTrackingState.IDLE;
  onClose?: () => void;

  aboutToAppear() {
    this.currentColors = themeManager.getColors();
    this.initPanel();
  }

  private async initPanel(): Promise<void> {
    this.fontScale = await fontScaleManager.getFontScale();
    await this.loadSkills();
    await this.loadEyeTrackingState();
  }

  private async loadSkills(): Promise<void> {
    this.skills = harmonySkillService.getSkills();
  }

  private async loadEyeTrackingState(): Promise<void> {
    this.eyeTrackingState = eyeTrackingService.getState();
  }

  private get smartServices(): SmartServiceItem[] {
    return [
      { icon: 'brain_headphones', titleKey: 'yiyi_assistant', subtitleKey: 'voice_dialogue', color: COMMON_COLORS.PRIMARY_BLUE, action: () => this.showVoiceAssistant = true },
      { icon: 'gear', titleKey: 'skill_services', subtitleKey: 'available_skills', color: COMMON_COLORS.SUCCESS_GREEN, action: () => this.showSkillsSheet() },
      { icon: 'speaker_wave', titleKey: 'voice_read', subtitleKey: 'tts_text_to_speech', color: COMMON_COLORS.WARNING_ORANGE, action: () => this.testTTS() },
      { icon: 'eye', titleKey: 'eye_tracking', subtitleKey: this.eyeTrackingState === EyeTrackingState.TRACKING ? 'tracking' : 'click_to_start', color: COMMON_COLORS.PURPLE, action: () => this.toggleEyeTracking() },
      { icon: 'lightbulb', titleKey: 'smart_recommend', subtitleKey: 'based_on_habits', color: COMMON_COLORS.CYAN, action: () => this.showRecommendations() }
    ];
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { if (this.onClose) this.onClose(); })

      Column() {
        Row() {
          Text(tr('smart_services'))
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentColors.textPrimary)
            .layoutWeight(1)

          // 关闭按钮
          Text('✕')
            .fontSize(fontScaleManager.getScaledFontSize(18))
            .fontColor(this.currentColors.textSecondary)
            .onClick(() => { if (this.onClose) this.onClose(); })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 16 })

        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.smartServices, (service: SmartServiceItem) => {
              this.ServiceCard(service.icon, tr(service.titleKey), tr(service.subtitleKey), service.color, service.action)
            })
          }
          .padding({ left: 16, right: 16, bottom: 100 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .height('80%')
      .position({ y: '20%' })
      .backgroundColor(this.currentColors.surface)
      .borderRadius({ topLeft: 20, topRight: 20 })

      if (this.showVoiceAssistant) {
        this.VoiceAssistantDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ServiceCard(icon: string, title: string, subtitle: string, color: string, action: () => void) {
    Row({ space: 16 }) {
      // 图标容器
      Text(this.getIconText(icon))
        .fontSize(fontScaleManager.getScaledFontSize(26))
        .fontColor(color)
        .width(56)
        .height(56)
        .textAlign(TextAlign.Center)
        .backgroundColor(color + '20')
        .borderRadius(16)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(fontScaleManager.getScaledFontSize(16))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentColors.textPrimary)
        Text(subtitle)
          .fontSize(fontScaleManager.getScaledFontSize(12))
          .fontColor(this.currentColors.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右箭头
      Text('›')
        .fontSize(fontScaleManager.getScaledFontSize(20))
        .fontColor(this.currentColors.textSecondary)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
    .borderRadius(16)
    .onClick(() => action())
  }

  private getIconText(icon: string): string {
    const iconMap: Map<string, string> = new Map<string, string>([
      ['brain_headphones', '🧠'],
      ['gear', '⚙️'],
      ['speaker_wave', '🔊'],
      ['eye', '👁️'],
      ['lightbulb', '💡'],
      ['xmark', '✕'],
      ['chevron_right', '›']
    ]);
    return iconMap.get(icon) || '•';
  }

  @Builder
  VoiceAssistantDialog() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => this.showVoiceAssistant = false)

      Column() {
        Text(tr('yiyi_assistant'))
          .fontSize(fontScaleManager.getScaledFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentColors.textPrimary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })

        Column({ space: 16 }) {
          Button(this.voiceState.isListening ? tr('listening') : tr('tap_to_speak'))
            .width('100%')
            .height(48)
            .backgroundColor(this.currentColors.primary)
            .fontColor('#FFFFFF')
            .borderRadius(24)
            .onClick(() => this.toggleVoiceListening())

          if (this.voiceState.lastResponse) {
            Text(this.voiceState.lastResponse)
              .fontSize(fontScaleManager.getScaledFontSize(14))
              .fontColor(this.currentColors.textSecondary)
              .width('100%')
              .padding(12)
          }
        }
        .padding({ left: 20, right: 20, bottom: 40 })
      }
      .width('100%')
      .backgroundColor(this.currentColors.surface)
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  private async toggleVoiceListening(): Promise<void> {
    if (this.voiceState.isListening) {
      await xiaoyiAgent.stopListening();
      this.voiceState.isListening = false;
    } else {
      try {
        const context = this.panelContext;
        if (context) {
          await xiaoyiAgent.init(context);
        }
        xiaoyiAgent.setResponseCallback((response: AgentResponse) => {
          this.voiceState.lastResponse = response.content;
          this.voiceState.isListening = false;
        });
        this.voiceState.isListening = true;
        await xiaoyiAgent.startListening();
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.voiceState.lastResponse = tr('voice_recognition_failed') + ': ' + message;
      }
    }
  }

  private async testTTS(): Promise<void> {
    try {
const context = this.panelContext;
        if (context) {
          await coreSpeechService.init(context);
        }
        await coreSpeechService.speak('Welcome to read app');
      toast(tr('reading'));
    } catch (error) {
        toast(tr('read_failed'));
    }
  }

  private async toggleEyeTracking(): Promise<void> {
    try {
      if (this.eyeTrackingState === EyeTrackingState.TRACKING) {
        await eyeTrackingService.stopTracking();
      } else {
        const context = this.panelContext;
        let isReady: boolean = false;
        if (context) {
          isReady = await eyeTrackingService.init(context);
        }

        if (!isReady) {
          toast('眼动追踪初始化失败', 2000);
          return;
        }
        
        await eyeTrackingService.startTracking();
      }
      this.eyeTrackingState = eyeTrackingService.getState();
    } catch (error) {
      toast(tr('operation_failed'));
    }
  }

  private showSkillsSheet(): void {
    let skillNames: string = '';
    for (let i = 0; i < this.skills.length; i++) {
      if (i > 0) {
        skillNames = skillNames + '\n';
      }
      skillNames = skillNames + this.skills[i].name;
    }
    // API 22+: showDialog is deprecated
    toast(tr('available_skills') + ': ' + skillNames);
  }

  private showRecommendations(): void {
    toast(tr('feature_dev'));
  }
}
