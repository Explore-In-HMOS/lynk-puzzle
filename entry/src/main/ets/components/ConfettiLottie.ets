import lottie, { AnimationItem } from '@ohos/lottie';

@Component
export struct ConfettiLottie {
  @Prop canvasWidth: Resource | number = 200;
  @Prop canvasHeight: Resource | number = 200;

  private animationItem: AnimationItem | null = null;
  private animationName: string = `confetti_${Date.now()}`;

  private renderingSettings: RenderingContextSettings =
    new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.renderingSettings);

  aboutToDisappear(): void {
    lottie.destroy(this.animationName);
  }

  build() {
    Canvas(this.canvasContext)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .backgroundColor(Color.Transparent)
      .onReady(() => {
        this.canvasContext.imageSmoothingEnabled = true;
        this.canvasContext.imageSmoothingQuality = 'medium';

        this.animationItem = lottie.loadAnimation({
          container: this.canvasContext,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          path: 'rawfile/confetti.json'
        });

        this.animationItem?.addEventListener('DOMLoaded', () => {
          console.info('Lottie loaded');
          this.animationItem?.setSpeed(1);
        });
      });
  }
}