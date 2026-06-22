import 'dart:convert';
// dart:html is deprecated but still the lightest zero-dependency way to reach
// the embedding window; this file only compiles on web. Intentional.
// ignore: deprecated_member_use
import 'dart:html' as html;

/// Web implementation: when the game runs inside the hotpotatogames.com
/// `<iframe>`, post a live "a game was played" tick to the parent page so it
/// can bump its on-screen counter without re-reading the database. The durable
/// count still lives in RTDB; this is only the live nicety. Never throws.
void postPlayToParent({required String kind, String? gameId}) {
  try {
    final parent = html.window.parent;
    if (parent == null) return;
    final msg = jsonEncode({
      'type': 'hpg:cellPlay',
      'kind': kind, // 'mini' | 'board'
      'gameId': gameId,
    });
    parent.postMessage(msg, '*');
  } catch (_) {
    // Embedding page absent / cross-origin quirk — ignore, count still lands in RTDB.
  }
}
