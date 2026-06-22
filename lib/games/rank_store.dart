import 'package:shared_preferences/shared_preferences.dart';

import 'game_catalog.dart';

/// Per-device curation store: the rank you assign each game (S A B C D F) AND
/// free-text feedback comments you jot while playing. Both layer over the
/// [GameCatalog] defaults and persist across sessions via SharedPreferences.
///
/// The comments are a capture-now / hand-off-later channel: jot feedback as you
/// play, then copy it out (see [feedbackFor] / [allFeedback]) to paste to the
/// agent modifying the games. Local-only for now — a later pass can sync to
/// Firebase or fold back into the catalog source.
class RankStore {
  RankStore._();

  static const _rankPrefix = 'game_rank_';
  static const _notePrefix = 'game_note_';
  static final Map<String, GameRank> _overrides = {};
  static final Map<String, String> _notes = {};
  static bool _loaded = false;

  /// Load saved ranks + notes into memory. Idempotent.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_rankPrefix)) {
          final id = key.substring(_rankPrefix.length);
          final name = prefs.getString(key);
          if (name == null) continue;
          for (final r in GameRank.values) {
            if (r.name == name) {
              _overrides[id] = r;
              break;
            }
          }
        } else if (key.startsWith(_notePrefix)) {
          final id = key.substring(_notePrefix.length);
          final note = prefs.getString(key);
          if (note != null && note.isNotEmpty) _notes[id] = note;
        }
      }
    } catch (_) {
      // No prefs / read failed → catalog defaults, no notes.
    }
    _loaded = true;
  }

  // ---- ranks ---------------------------------------------------------------

  /// Effective rank: the saved override, else the catalog default.
  static GameRank rankFor(CatalogGame game) => _overrides[game.id] ?? game.rank;

  static Future<void> setRank(String gameId, GameRank rank) async {
    _overrides[gameId] = rank;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_rankPrefix$gameId', rank.name);
    } catch (_) {/* in-memory still applies */}
  }

  // ---- comments ------------------------------------------------------------

  static String noteFor(String gameId) => _notes[gameId] ?? '';
  static bool hasNote(String gameId) =>
      (_notes[gameId]?.trim().isNotEmpty ?? false);
  static int get notedCount => _notes.values.where((n) => n.trim().isNotEmpty).length;

  static Future<void> setNote(String gameId, String note) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      _notes.remove(gameId);
    } else {
      _notes[gameId] = trimmed;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (trimmed.isEmpty) {
        await prefs.remove('$_notePrefix$gameId');
      } else {
        await prefs.setString('$_notePrefix$gameId', trimmed);
      }
    } catch (_) {/* in-memory still applies */}
  }

  // ---- copy payloads -------------------------------------------------------

  /// A copy-ready feedback block for one game: rank, name, id, scale, comment.
  static String feedbackFor(CatalogGame game) {
    final buf = StringBuffer()
      ..writeln('[${rankFor(game).label}] ${game.name} (${game.id}) · '
          '${game.scale.name}');
    final note = noteFor(game.id);
    buf.writeln(note.isEmpty ? '(no comments)' : note);
    return buf.toString().trimRight();
  }

  /// A copy-ready block of EVERY game that has comments — for a batch hand-off.
  static String allFeedback() {
    final buf = StringBuffer('EXPLORE THE CELL — GAME FEEDBACK\n');
    for (final g in GameCatalog.games) {
      if (!hasNote(g.id)) continue;
      buf
        ..writeln()
        ..writeln(feedbackFor(g));
    }
    return buf.toString().trimRight();
  }
}
