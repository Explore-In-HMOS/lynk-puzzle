import preferences from '@ohos.data.preferences';
import GlobalContext from '../utils/GlobalContext';
import { ConfettiLottie } from '../components/ConfettiLottie';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { CanvasController, canvasSize } from '../components/GameCanvas';
import { MoveInfo } from '../core/Game';

@Builder
export function GamePageBuilder() {
  GamePage()
}

@Entry
@Component
struct GamePage {
  private navPathStack: NavPathStack = new NavPathStack();
  private soundPool: media.SoundPool | undefined = undefined;
  private soundIds: number[] = []; // 0: drop-thunk, 1: reverse-thunk, 3: confetti
  private pref: preferences.Preferences | null = null;
  private canvasController = new CanvasController();
  private dragging: boolean = false;
  private readonly maxLevel: number = 10;
  private reachedMaxLevel: number = 1;
  @State isMenuOpen: boolean = false;
  @State isCompleted: boolean = false;
  @State level: number = 1;
  @State soundsOn: boolean = true;

  private async initPreferences() {
    const pref = await preferences.getPreferences(GlobalContext.getInstance().getAppContext(), 'gameData');
    if (pref) {
      this.pref = pref;
    }
  }

  private async initSoundPool() {
    const audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_GAME,
      rendererFlags: 1 // AudioRenderer flag.
    };
    this.soundPool =
      await media.createSoundPool(14, audioRendererInfo); // A maximum of 14 streams can be played simultaneously.

    // load sounds
    const context = GlobalContext.getInstance().getAppContext();
    const filesPaths = ['drop-thunk.mp3', 'reverse-thunk.mp3', 'confetti.mp3'];
    for (const filePath of filesPaths) {
      const fileDescriptor = await context!.resourceManager.getRawFd(filePath);
      this.soundIds.push(await this.soundPool!.load(fileDescriptor.fd, fileDescriptor.offset, fileDescriptor.length));
    }
  }

  private async playSound(soundId: number) {
    if (!this.soundsOn) {
      return;
    }
    const streamID: number = 0
    const playParameters: media.PlayParameters = {
      loop: 0, // Loop once, meaning the sound will play twice in total.
      rate: 1, // Play at double speed.
      leftVolume: 0.5, // The value ranges from 0.0 to 1.0.
      rightVolume: 0.5, // The value ranges from 0.0 to 1.0.
      priority: 0, // The sound playback has the lowest priority.
    };
    this.soundPool!.play(soundId, playParameters, (error, streamID: number) => {
      if (error) {
        console.error(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
      } else {
        console.info(`play success soundId: ${soundId}`);
      }
    });
  }

  private async saveProgress() {
    if (!this.pref) {
      return;
    }

    await this.pref.put('level', this.level);
    await this.pref.put('reachedMaxLevel', this.reachedMaxLevel);
    await this.pref.flush();
  }

  private async loadProgress() {
    if (!this.pref) {
      return;
    }

    const savedLevel = await this.pref.get('level', 1) as number;
    const savedMax = await this.pref.get('reachedMaxLevel', 1) as number;

    this.level = savedLevel;
    this.reachedMaxLevel = savedMax;

    this.canvasController.loadLevel(this.level);
  }

  aboutToAppear() {
    this.initPreferences().then(() => {
      this.loadProgress();
    });
    this.initSoundPool();
  }

  aboutToDisappear(): void {
    this.soundPool!.release();
  }

  build() {
    NavDestination() {
      RelativeContainer() {
        Stack({ alignContent: Alignment.Top }) {

          NodeContainer(this.canvasController)
            .width('100%')
            .height('100%')

          Text(this.level === this.maxLevel ? 'All levels\ncompleted!' : 'Completed!')
            .backgroundColor(Color.Black)
            .fontColor(Color.White)
            .margin({ top: 85 })
            .fontSize(32)
            .padding(10)
            .visibility(this.isCompleted ? Visibility.Visible : Visibility.Hidden)

          Column({ space: 10 }) {
            Column() {
              Row() {
                Button('←')
                  .height(30)
                  .width(30)
                  .borderRadius(15)
                  .backgroundColor(Color.White)
                  .fontColor(this.level > 1 ? Color.Black : Color.Gray)
                  .padding(0)
                  .fontSize(22)
                  .onClick(async () => {
                    if (this.level > 1) {
                      this.isCompleted = false;
                      this.level--;
                      await this.saveProgress();
                      this.canvasController.loadLevel(this.level);
                    }
                  })

                Text(`#${this.level}`)
                  .fontColor(Color.Black)
                  .fontSize(20)
                  .padding({ left: 15, right: 15 })

                Button('→')
                  .height(30)
                  .width(30)
                  .borderRadius(15)
                  .backgroundColor(Color.White)
                  .fontColor(this.level < this.reachedMaxLevel ? Color.Black : Color.Gray)
                  .padding(0)
                  .fontSize(22)
                  .onClick(async () => {
                    if (this.level < this.reachedMaxLevel) {
                      this.isCompleted = false;
                      this.level++
                      await this.saveProgress();
                      this.canvasController.loadLevel(this.level)
                    }
                  })
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
              .height(50)
              .borderRadius(25)
              .borderColor(Color.Black)
              .borderWidth(3)
              .backgroundColor(Color.White)
            }
            .width('60%')
            .height(50)
            .margin({ top: 60 })

            Row({ space: 5 }) {
              Button() {
                Image($r('app.media.info'))
                  .width(32)
                  .height(32)
              }
              .height(50)
              .width(50)
              .borderRadius(25)
              .borderColor(Color.Black)
              .borderWidth(3)
              .backgroundColor(Color.White)
              .onClick(() => {
                this.navPathStack.pushPath({ name: 'InfoScreen' });
                this.isMenuOpen = false;
              })

              Button() {
                Image($r('app.media.replay'))
                  .width(32)
                  .height(32)
              }
              .fontColor(Color.Black)
              .height(50)
              .width(50)
              .borderRadius(25)
              .borderColor(Color.Black)
              .borderWidth(3)
              .backgroundColor(Color.White)
              .onClick(() => {
                this.canvasController.loadLevel(this.level);
                this.isMenuOpen = false;
              })

              Button() {
                Image(this.soundsOn ? $r('app.media.music') : $r('app.media.music_off'))
                  .width(32)
                  .height(32)
              }
              .height(50)
              .width(50)
              .borderRadius(25)
              .borderColor(Color.Black)
              .borderWidth(3)
              .backgroundColor(Color.White)
              .onClick(() => {
                this.soundsOn = !this.soundsOn
              })

            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height(50)

          }
          .width('100%')
          .height('100%')
          .backgroundColor('#a9ffffff')
          .visibility(this.isMenuOpen ? Visibility.Visible : Visibility.Hidden)

          Button() {
            Image($r('app.media.listwhite'))
              .width(32)
              .height(32)
          }
          .height(40)
          .width(40)
          .backgroundColor(Color.Black)
          .onClick(() => {
            this.isMenuOpen = !this.isMenuOpen
          })

          if (this.isCompleted) {
            ConfettiLottie({
              canvasWidth: canvasSize[0] / 2,
              canvasHeight: canvasSize[1] / 2
            })
          }
        }
        .onTouch(async (event) => {
          if (this.isCompleted) {
            if (event.type === TouchType.Down) {
              this.isCompleted = false;
              if (this.level === this.maxLevel) {
                return;
              }
              this.isCompleted = false;
              this.level++;
              await this.saveProgress();
              this.canvasController.loadLevel(this.level);
            }
            return;
          }

          if (event.type === TouchType.Down) {
            const x = event.touches[0].x * 2;
            const y = event.touches[0].y * 2;
            this.dragging = this.canvasController.getGame().startDragging(x, y);
          }
          if (event.type === TouchType.Up) {
            this.dragging = false;
          }

          if (event.type === TouchType.Move) {
            if (this.dragging) {
              const x = event.touches[0].x * 2;
              const y = event.touches[0].y * 2;
              const moveInfo: MoveInfo = this.canvasController.getGame().move(x, y);
              if (moveInfo === MoveInfo.move) {
                console.info('[LynkPuzzle] move sound')
                this.playSound(this.soundIds[0]);
              } else if (moveInfo === MoveInfo.undoMove) {
                console.info('[LynkPuzzle] undo move sound')
                this.playSound(this.soundIds[1]);
              }
              this.canvasController.invalidate();
              if (this.canvasController.checkLevelCompleted()) {
                this.isCompleted = true;
                this.playSound(this.soundIds[2])
                if (this.level === this.reachedMaxLevel && this.reachedMaxLevel !== this.maxLevel) {
                  this.reachedMaxLevel++;
                }
                await this.saveProgress();
              }
            }
          }
        })
      }
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          ['#070843', 0.0],
          ['#BD4C7F', 1.0]
        ]
      })
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .onBackPressed(() => {
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
    })
  }
}