enum AppScreen {
  home, // LEARN / PARTY / GAMES doors live here
  scaleOverview,
  scaleModules, // module picker for a scale (Scale → Module → Entity)
  scaleExplorer,
  entityDetail,
  cellInteractive,
  cellGame,
  miniGame,
  partyLobby, // host / join room lobby
  party,
}

abstract class NavigationEvent {}

class NavigateToScreen extends NavigationEvent {
  final AppScreen screen;
  NavigateToScreen(this.screen);
}
