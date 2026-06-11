enum AppScreen {
  splash,
  scaleOverview,
  scaleExplorer,
  entityDetail,
  cellInteractive,
  cellGame,
  miniGame,
  party,
}

abstract class NavigationEvent {}

class NavigateToScreen extends NavigationEvent {
  final AppScreen screen;
  NavigateToScreen(this.screen);
}
