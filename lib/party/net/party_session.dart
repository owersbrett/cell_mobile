import 'party_net.dart';

/// Carries the active online match across the lobby → board navigation, which
/// (being BLoC `AppScreen`-based) doesn't pass parameters. The lobby sets
/// [active] when a room is hosted/joined; `PartyFlowPage` reads it to decide
/// online vs local. Null means local pass-and-play.
class PartySession {
  PartySession._();

  static PartyNet? active;

  /// Tears down and clears the active match (call on exit / game over).
  static void clear() {
    active?.dispose();
    active = null;
  }
}
