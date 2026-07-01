import 'package:flutter/foundation.dart' show kIsWeb;

import 'game_catalog.dart';

/// URL-slug support for embedding a SINGLE game at
/// `explore-the-cell.web.app/{slug}` (e.g. `/farm-panic`), so an iframe can host
/// one minigame directly.
///
/// A game's slug is its registry [CatalogGame.specId] in kebab-case
/// (`farm_panic` → `farm-panic`). Only registry games (`specId != null`) are
/// embeddable. Add an entry to [_slugOverrides] to give a game a
/// marketing-clean URL that differs from its derived slug.
///
/// This is a pure, additive lookup — it does not touch the app's navigation.
class GameSlug {
  GameSlug._();

  /// Optional pretty overrides: slug → specId. Derived slugs already cover every
  /// game, so this stays empty until a game wants a custom URL.
  static const Map<String, String> _slugOverrides = {
    // 'farm-panic': 'farm_panic', // (already the derived default — example only)
  };

  static String _slugify(String specId) =>
      specId.toLowerCase().replaceAll('_', '-');

  /// The canonical slug for a catalog game, or null if it isn't embeddable
  /// (legacy game with no registry spec).
  static String? slugFor(CatalogGame g) {
    final id = g.specId;
    return id == null ? null : _slugify(id);
  }

  /// Resolve a raw slug (case-insensitive, e.g. `farm-panic`) to a specId, or
  /// null if no game matches.
  static String? specIdForSlug(String rawSlug) {
    final slug = rawSlug.trim().toLowerCase();
    if (slug.isEmpty) return null;
    final override = _slugOverrides[slug];
    if (override != null) return override;
    for (final g in GameCatalog.games) {
      final id = g.specId;
      if (id != null && _slugify(id) == slug) return id;
    }
    return null;
  }

  /// If the current web URL points at a known game slug — either as a path
  /// segment (`/farm-panic`, path URL strategy) or in the fragment
  /// (`/#/farm-panic`, hash strategy) — return that game's specId. On non-web,
  /// the root path, or an unknown slug, returns null so the normal app boots.
  static String? embedSpecIdFromUrl() {
    if (!kIsWeb) return null;
    final uri = Uri.base;

    // First real path segment is the game slug (path URL strategy).
    final pathSegs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (pathSegs.isNotEmpty) {
      final spec = specIdForSlug(pathSegs.first);
      if (spec != null) return spec;
    }

    // Fallback: hash strategy leaves the route in the fragment.
    final fragSegs = uri.fragment.split('/').where((s) => s.isNotEmpty).toList();
    if (fragSegs.isNotEmpty) {
      final spec = specIdForSlug(fragSegs.first);
      if (spec != null) return spec;
    }

    return null;
  }
}
