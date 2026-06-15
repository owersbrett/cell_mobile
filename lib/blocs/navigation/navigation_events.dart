enum AppScreen {
  splash, // home: LEARN / PLAY doors live here
  scaleOverview,
  scaleExplorer,
  entityDetail,
  cellInteractive,
  cellGame,
  miniGame,
  play, // host / join room lobby
  party,
}

abstract class NavigationEvent {}

class NavigateToScreen extends NavigationEvent {
  final AppScreen screen;
  NavigateToScreen(this.screen);
}
