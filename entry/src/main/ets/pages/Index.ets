import { GamePageBuilder } from './GamePage';
import { InfoScreenBuilder } from './InfoScreen';

@Entry
@Component
struct Index {
  private pathStack: NavPathStack = new NavPathStack();

  @Builder
  private PageMap(name: string) {
    if (name === 'GamePage') {
      GamePageBuilder()
    } else if (name === 'InfoScreen') {
      InfoScreenBuilder()
    } else {
      NavDestination() {
        Column() {
          Text('Unknown Destination')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Black)
      }
      .hideTitleBar(true)
      .hideBackButton(true)
    }
  }

  aboutToAppear(): void {
    this.pathStack.pushPath({ name: 'GamePage' });
    this.pathStack.pushPath({ name: 'InfoScreen' });
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
  }
}