/**
 * 音频播放组件 - 简单的播放控制 UI
 * Audio Player Component - Simple Playback Control UI
 */

import { audioPlayerService, AudioPlayState, AudioPlayProgress, AudioPlayConfig } from '../../../services/audio/AudioPlayerService';
import { COMMON_COLORS } from '../../../utils/AppTheme';

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
        console.error('[AudioPlayer] Error:', error);
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
      // 播放控制按钮
      Row({ space: 16 }) {
        // 停止按钮
        if (this.currentState !== AudioPlayState.IDLE) {
          Button() {
            Text('⏹')
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

        // 播放/暂停按钮
        Button() {
          Text(this.isPlaying ? '⏸' : '▶')
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

        // 进度显示
        if (this.progress.duration > 0) {
          Column({ space: 4 }) {
            Text(this.formatTime(this.progress.currentPosition) + ' / ' + this.formatTime(this.progress.duration))
              .fontSize(PageStyles.fontSize('sm'))
              .fontColor(PageStyles.textColor(this.isDarkMode, 'secondary'))

            // 进度条
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
