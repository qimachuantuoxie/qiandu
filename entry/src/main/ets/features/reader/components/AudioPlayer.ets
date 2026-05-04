import { logger } from '../../../common/utils/Logger';
/**
 * 闊抽�鎾�斁缁勪欢 - 绠€鍗曠殑鎾�斁鎺у埗 UI
 * Audio Player Component - Simple Playback Control UI
 */

import { audioPlayerService, AudioPlayState, AudioPlayProgress, AudioPlayConfig } from '../../services/audio/AudioPlayerService';
import { COMMON_COLORS } from '../../utils/AppTheme';

@Component
export struct AudioPlayer {
  @Prop isDarkMode: boolean = false;
  @State currentState: AudioPlayState = AudioPlayState.IDLE;
  @State progress: AudioPlayProgress = { currentPosition: 0, duration: 0, percentage: 0 };
  @State audioSrc: string = '';
  @State isPlaying: boolean = false;

  aboutToAppear(): void {
    audioPlayerService.setListener({
      onStateChange: (state: AudioPlayState) => {
        this.currentState = state;
        this.isPlaying = state === AudioPlayState.PLAYING;
      },
      onProgress: (prog: AudioPlayProgress) => {
        this.progress = prog;
      },
      onError: (error: string) => {
        logger.error('[AudioPlayer] Error:', error);
      },
      onCompleted: () => {
        this.isPlaying = false;
      }
    });
  }

  async playAudio(src: string): Promise<void> {
    this.audioSrc = src;
    await audioPlayerService.play({ src });
  }

  async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await audioPlayerService.pause();
    } else {
      if (this.audioSrc) {
        await audioPlayerService.resume();
      }
    }
  }

  async stopPlayback(): Promise<void> {
    await audioPlayerService.stop();
    this.isPlaying = false;
  }

  async seekTo(position: number): Promise<void> {
    await audioPlayerService.seek(position);
  }

  formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return minutes + ':' + secs.toString().padStart(2, '0');
  }

  build() {
    Column({ space: 8 }) {
      // 鎾�斁鎺у埗鎸夐挳
      Row({ space: 16 }) {
        // 鍋滄�鎸夐挳
        if (this.currentState !== AudioPlayState.IDLE) {
          Button() {
            Text('鈴?)
              .fontSize(24)
          }
          .width(48)
          .height(48)
          .backgroundColor(PageStyles.opacityColor(this.isDarkMode, 'medium'))
          .borderRadius(PageStyles.radius('full'))
          .onClick(() => this.stopPlayback())
          .stateStyles(PageStyles.pressedStyle())
          .animation(PageStyles.animation('fast'))
        }

        // 鎾�斁/鏆傚仠鎸夐挳
        Button() {
          Text(this.isPlaying ? '鈴? : '鈻?)
            .fontSize(28)
        }
        .width(64)
        .height(64)
        .backgroundColor(PageStyles.themeColor('primary'))
        .fontColor('#FFFFFF')
        .borderRadius(PageStyles.radius('full'))
        .onClick(() => this.togglePlayPause())
        .stateStyles(PageStyles.pressedStyle())
        .animation(PageStyles.animation('fast'))

        // 杩涘害鏄剧ず
        if (this.progress.duration > 0) {
          Column({ space: 4 }) {
            Text(this.formatTime(this.progress.currentPosition) + ' / ' + this.formatTime(this.progress.duration))
              .fontSize(PageStyles.fontSize('sm'))
              .fontColor(PageStyles.textColor(this.isDarkMode, 'secondary'))

            // 杩涘害鏉?
            Slider({
              value: this.progress.percentage,
              min: 0,
              max: 100
            })
              .width(120)
              .trackColor(PageStyles.opacityColor(this.isDarkMode, 'light'))
              .selectedColor(PageStyles.themeColor('primary'))
              .onChange((value: number) => {
                const position = (value / 100) * this.progress.duration;
                this.seekTo(position);
              })
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(PageStyles.spacing('md'))
    .backgroundColor(PageStyles.bgColor(this.isDarkMode, 'card'))
    .borderRadius(PageStyles.radius('lg'))
    .shadow(PageStyles.elevation('sm', this.isDarkMode))
    .animation(PageStyles.animation('normal'))
}
