enum AppScreen {
  splash,
  scaleOverview,
  scaleExplorer,
  entityDetail,
  cellInteractive,
  cellGame,
}

abstract class NavigationEvent {}

class NavigateToScreen extends NavigationEvent {
  final AppScreen screen;
  NavigateToScreen(this.screen);
}
