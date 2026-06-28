import 'package:shared_preferences/shared_preferences.dart';

import '../party/maps/game_map.dart';
import '../party/party_models.dart';

/// How many players a round runs — Solo or against AI opponents.
enum GameMode { solo, duel, trio, quad }

extension GameModeX on GameMode {
  /// AI opponents in this mode (0 = solo score-attack).
  int get opponents => switch (this) {
        GameMode.solo => 0,
        GameMode.duel => 1,
        GameMode.trio => 2,
        GameMode.quad => 3,
      };

  String get label => switch (this) {
        GameMode.solo => 'SOLO',
        GameMode.duel => '1v1',
        GameMode.trio => '1v1v1',
        GameMode.quad => '1v1v1v1',
      };
}

/// The play mode chosen on the home page — how many AI opponents Explore games
/// run you against. Persisted per device so the choice sticks.
class PlayConfig {
  PlayConfig._();

  static const _key = 'play_mode';
  static const _disruptKey = 'play_disruption';
  static GameMode mode = GameMode.quad;

  /// The board chosen for the next local pass-and-play game (set by the lobby).
  static String mapId = kDefaultMapId;

  /// When on, opponents may interfere with your run (games that support it read
  /// this flag). Only meaningful when there are opponents (non-solo).
  static bool disruption = false;
  static bool _loaded = false;

  /// Opponent count fed to [MiniGameHost] for Explore play.
  static int get opponentCount => mode.opponents;

  /// The party room format to default to when hosting, derived from the
  /// home-screen mode — now a clean 1:1 (solo / 1v1 / 1v1v1 / 1v1v1v1).
  static PartyMode get partyMode => switch (mode) {
        GameMode.solo => PartyMode.solo,
        GameMode.duel => PartyMode.duel,
        GameMode.trio => PartyMode.ffa3,
        GameMode.quad => PartyMode.ffa4,
      };

  /// Disruption is only active when there's actually someone to disrupt you.
  static bool get disruptionActive => disruption && opponentCount > 0;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      if (name != null) {
        for (final m in GameMode.values) {
          if (m.name == name) {
            mode = m;
            break;
          }
        }
      }
      disruption = prefs.getBool(_disruptKey) ?? false;
    } catch (_) {/* defaults */}
    _loaded = true;
  }

  static Future<void> setMode(GameMode m) async {
    mode = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, m.name);
    } catch (_) {/* in-memory still applies */}
  }

  static Future<void> setDisruption(bool on) async {
    disruption = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_disruptKey, on);
    } catch (_) {/* in-memory still applies */}
  }
}
