enum AppScreen {
  home, // LEARN / PARTY / GAMES doors live here
  scaleOverview,
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
