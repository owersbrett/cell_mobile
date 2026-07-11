import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'game_catalog.dart';

/// What a game deep-link URL resolved to: which game, and whether it should
/// run hands-free (attract autopilot — dashboard/kiosk b-roll).
class EmbedTarget {
  final String specId;
  final bool attract;
  const EmbedTarget(this.specId, {this.attract = false});
}

/// URL-slug support for embedding a SINGLE game at
/// `explore-the-cell.web.app/{slug}` (e.g. `/farm-panic`), so an iframe can host
/// one minigame directly.
///
/// A game's slug is its registry [CatalogGame.specId] in kebab-case
/// (`farm_panic` → `farm-panic`). Only registry games (`specId != null`) are
/// embeddable. Add an entry to [_slugOverrides] to give a game a
/// marketing-clean URL that differs from its derived slug.
///
/// ATTRACT VARIANT — the game self-plays on a loop (autopilot bot, replays
/// forever). Canonical form: `/{slug}?attract=true`. Also accepted:
/// `/{slug}/attract` and `/attract/{slug}`.
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
  /// (`/#/farm-panic`, hash strategy) — return that game as an [EmbedTarget],
  /// with `attract` set when the URL asks for the self-playing variant (see
  /// the class doc for the accepted forms). On non-web, the root path, or an
  /// unknown slug, returns null so the normal app boots.
  static EmbedTarget? embedTargetFromUrl() {
    if (!kIsWeb) return null;
    final uri = Uri.base;

    // Path URL strategy: route + ?query live on the real URI.
    final fromPath = targetFrom(uri.pathSegments, uri.queryParameters);
    if (fromPath != null) return fromPath;

    // Fallback: hash strategy keeps the route (and any ?query) in the
    // fragment — re-parse it as its own URI.
    final frag = Uri.parse(uri.fragment);
    return targetFrom(frag.pathSegments, frag.queryParameters);
  }

  /// The reserved `/loop` route — a chromeless, perpetual cell animation with
  /// the "Explore The Cell" title, for embedding as a marketing loop. Matches
  /// under both URL strategies (path and hash), never collides with a game slug
  /// (no game's specId is `loop`). Additive — does not touch navigation.
  static bool isLoopRoute() {
    if (!kIsWeb) return false;
    final uri = Uri.base;
    if (_firstSegment(uri.pathSegments) == 'loop') return true;
    return _firstSegment(Uri.parse(uri.fragment).pathSegments) == 'loop';
  }

  static String? _firstSegment(List<String> segs) {
    for (final s in segs) {
      if (s.isNotEmpty) return s.toLowerCase();
    }
    return null;
  }

  static const _attractSeg = 'attract';

  /// Resolves route segments + query to an embed target. Exposed for tests —
  /// production goes through [embedTargetFromUrl] (which owns `Uri.base`).
  @visibleForTesting
  static EmbedTarget? targetFrom(
      List<String> rawSegments, Map<String, String> query) {
    final segs = rawSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return null;

    // /attract/{slug}
    if (segs.first.toLowerCase() == _attractSeg) {
      if (segs.length < 2) return null;
      final spec = specIdForSlug(segs[1]);
      return spec == null ? null : EmbedTarget(spec, attract: true);
    }

    final spec = specIdForSlug(segs.first);
    if (spec == null) return null;

    // /{slug}/attract
    final pathAttract =
        segs.length >= 2 && segs[1].toLowerCase() == _attractSeg;
    // /{slug}?attract=true (canonical; `attract=1` also accepted)
    final q = (query['attract'] ?? '').toLowerCase();
    final queryAttract = q == 'true' || q == '1';

    return EmbedTarget(spec, attract: pathAttract || queryAttract);
  }
}
