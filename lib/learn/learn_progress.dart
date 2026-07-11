import 'package:flutter/foundation.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which LEARN topics (entities) the player has actually opened, so the
/// carousel cards, module tiles, and explorer can show "how far through" a
/// scale or module you are. Persisted locally — progress survives sessions but
/// is per-device, not per-account.
///
/// Load once at startup ([load]); after that all reads are synchronous from
/// the in-memory set and writes persist fire-and-forget.
class LearnProgress extends ChangeNotifier {
  LearnProgress._();
  static final LearnProgress instance = LearnProgress._();

  static const _prefsKey = 'learn_viewed_topics_v1';

  final Set<String> _viewed = <String>{};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _viewed
      ..clear()
      ..addAll(_prefs?.getStringList(_prefsKey) ?? const []);
  }

  bool isViewed(String entityId) => _viewed.contains(entityId);

  /// Marks a topic as viewed. Safe to call repeatedly; only persists/notifies
  /// on first view.
  void markViewed(String entityId) {
    if (!_viewed.add(entityId)) return;
    _prefs?.setStringList(_prefsKey, _viewed.toList());
    notifyListeners();
  }

  int viewedCountOf(Iterable<BioEntity> entities) =>
      entities.where((e) => _viewed.contains(e.id)).length;
}
