@Builder
export function InfoScreenBuilder() {
  InfoScreen()
}

@Component
struct InfoScreen {
  private pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text('Lynk Puzzle')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 8 })

          Text('Connect matching nodes\nby drawing paths.\nFill every node to\ncomplete the level.')
            .fontSize(14)
            .fontColor('#ccffffff')
            .textAlign(TextAlign.Center)
            .lineHeight(20)
            .margin({ bottom: 16 })

          Divider()
            .color('#33ffffff')
            .width('60%')
            .margin({ bottom: 16 })

          Text('Drag from a colored node\nto draw a path.\n\nPaths cannot cross.')
            .fontSize(13)
            .fontColor('#aaffffff')
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .margin({ bottom: 20 })

          Button('Back')
            .fontSize(16)
            .height(36)
            .width(80)
            .borderRadius(18)
            .backgroundColor(Color.White)
            .fontColor(Color.Black)
            .onClick(() => {
              this.pathStack.pop();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .scrollable(ScrollDirection.Vertical)
    }
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['#070843', 0.0],
        ['#BD4C7F', 1.0]
      ]
    })
    .hideTitleBar(true)
    .hideBackButton(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}
