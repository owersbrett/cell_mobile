import 'package:shared_preferences/shared_preferences.dart';

/// Per-device DEV TOOLS switch (flipped in the settings sheet, default OFF).
///
/// OFF = player mode: the games surfaces hide the triage tooling — rank
/// grades, the RATE flow, feedback filters/copy — and the un-judged `_v2`
/// A/B alternates, showing one clean game per pair.
/// ON = the generate→grade→promote loop exactly as it always was.
///
/// SharedPreferences-backed like [RankStore]; call [load] before reading [on].
class DevMode {
  DevMode._();

  static const _key = 'dev_tools_enabled';
  static bool _on = false;
  static bool _loaded = false;

  static bool get on => _on;

  /// Load the saved switch into memory. Idempotent.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _on = prefs.getBool(_key) ?? false;
    } catch (_) {
      // No prefs / read failed → player mode.
    }
    _loaded = true;
  }

  static Future<void> set(bool value) async {
    _on = value;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {/* in-memory still applies */}
  }
}
