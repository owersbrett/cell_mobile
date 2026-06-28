import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// CPU difficulty — how close to a game's realistic human ceiling a bot scores.
///
/// A character's difficulty is **only applied when that character is used as a
/// CPU opponent**. When the human plays *as* a character, this is ignored — the
/// human plays themselves. See [OpponentRoster].
enum CpuDifficulty { easy, medium, hard, expert }

extension CpuDifficultyX on CpuDifficulty {
  String get label => switch (this) {
        CpuDifficulty.easy => 'EASY',
        CpuDifficulty.medium => 'MED',
        CpuDifficulty.hard => 'HARD',
        CpuDifficulty.expert => 'EXPERT',
      };

  /// Score band as a fraction of the game's realistic human ceiling. The bot's
  /// score is a random point in [lo, hi] with a little noise.
  (double lo, double hi) get band => switch (this) {
        CpuDifficulty.easy => (0.25, 0.55),
        CpuDifficulty.medium => (0.45, 0.75),
        CpuDifficulty.hard => (0.65, 0.90),
        CpuDifficulty.expert => (0.85, 1.00),
      };
}

/// Per-character tuning: how tough they play as a CPU, and which mini-game they
/// favour when CPUs pick games in board (party) mode.
class CharacterConfig {
  CpuDifficulty difficulty;

  /// Registry id of this character's favourite mini-game, or null for "any".
  String? favoriteGameId;

  CharacterConfig({
    this.difficulty = CpuDifficulty.medium,
    this.favoriteGameId,
  });

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        if (favoriteGameId != null) 'favoriteGameId': favoriteGameId,
      };

  factory CharacterConfig.fromJson(Map<String, dynamic> j) => CharacterConfig(
        difficulty: CpuDifficulty.values.firstWhere(
          (d) => d.name == j['difficulty'],
          orElse: () => CpuDifficulty.medium,
        ),
        favoriteGameId: j['favoriteGameId'] as String?,
      );
}

/// Device-local roster config, keyed by character name (the [PartyCharacter]
/// names in `kCharacters`). Persisted so each player's hand-tuned cast sticks.
///
/// Sibling to [PlayConfig]: the home-screen settings sheet writes here; the
/// mini-game host reads it to score CPU opponents, and board mode reads
/// favourites to bias a CPU's game pick.
class OpponentRoster {
  OpponentRoster._();

  static const _key = 'opponent_roster_v1';
  static const _playAsKey = 'play_as_character';

  static final Map<String, CharacterConfig> _configs = {};
  static bool _loaded = false;

  /// The character name the human plays as in Explore/solo. Its config is never
  /// applied as a CPU (the human is the human). null = no choice yet.
  static String? playAs;

  /// Config for [characterName], created on first access with defaults.
  static CharacterConfig configFor(String characterName) =>
      _configs.putIfAbsent(characterName, CharacterConfig.new);

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((name, cfg) {
          _configs[name] =
              CharacterConfig.fromJson((cfg as Map).cast<String, dynamic>());
        });
      }
      playAs = prefs.getString(_playAsKey);
    } catch (_) {/* defaults */}
    _loaded = true;
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        for (final e in _configs.entries) e.key: e.value.toJson(),
      };
      await prefs.setString(_key, jsonEncode(map));
    } catch (_) {/* in-memory still applies */}
  }

  static Future<void> setDifficulty(String name, CpuDifficulty d) async {
    configFor(name).difficulty = d;
    await _save();
  }

  static Future<void> setFavoriteGame(String name, String? gameId) async {
    configFor(name).favoriteGameId = gameId;
    await _save();
  }

  static Future<void> setPlayAs(String? name) async {
    playAs = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name == null) {
        await prefs.remove(_playAsKey);
      } else {
        await prefs.setString(_playAsKey, name);
      }
    } catch (_) {/* in-memory still applies */}
  }
}
