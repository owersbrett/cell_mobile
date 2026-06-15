import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'party_controller.dart';

/// Desktop (debug) implementation: writes the replay save to a JSON file the
/// dev daemon also knows about. Active only in debug builds on macOS/Linux/
/// Windows; a no-op (returns false/null) anywhere else, so it's safe to call
/// unconditionally and safe to compile into mobile builds.
class PartySessionStore {
  PartySessionStore._();

  /// Only active in debug desktop builds.
  static bool get enabled =>
      kDebugMode &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  /// When the dev daemon hot-restarts the app it sets `CELL_DEV_AUTORESUME=1`
  /// so the saved game reloads seamlessly instead of showing the resume prompt.
  static bool get autoResume =>
      enabled && Platform.environment['CELL_DEV_AUTORESUME'] == '1';

  /// The save file. The daemon can point both sides at one path via
  /// `CELL_DEV_SAVE`; otherwise it defaults to `.dev/last_session.json` under
  /// the working directory (the project root when launched with `flutter run`).
  static File get _file {
    final override = Platform.environment['CELL_DEV_SAVE'];
    if (override != null && override.isNotEmpty) return File(override);
    return File('${Directory.current.path}/.dev/last_session.json');
  }

  static void save(PartyController controller) {
    if (!enabled) return;
    try {
      final file = _file;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(json.encode(controller.toSaveJson()));
    } catch (_) {
      // Dev convenience only — never let persistence break the game.
    }
  }

  static PartyController? load() {
    if (!enabled) return null;
    try {
      final file = _file;
      if (!file.existsSync()) return null;
      final data =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      return PartyController.fromSaveJson(data);
    } catch (_) {
      return null;
    }
  }

  static void clear() {
    if (!enabled) return;
    try {
      final file = _file;
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
