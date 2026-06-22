import 'dart:async';
import 'dart:convert';
// dart:html is deprecated but the lightest zero-dependency way to reach the
// embedding window; this file only compiles on web. Intentional.
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'auth_profile.dart';

/// Embedded SSO handshake. When the cell runs inside the hotpotatogames.com
/// `<iframe>`, announce readiness to the parent and wait briefly for it to post
/// back a Firebase custom token minted (via the `issueCustomToken` function)
/// for the site's signed-in user.
///
/// Returns the custom token, or `null` when: not embedded (no parent frame),
/// the visitor is logged out, or the parent doesn't answer in time. In every
/// null case the caller falls back to anonymous auth. Never throws.
Future<String?> requestParentAuthToken({
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final parent = html.window.parent;
    // Outside an iframe, window.parent is the window itself — nothing to ask.
    if (parent == null || identical(parent, html.window)) return null;

    final completer = Completer<String?>();
    late StreamSubscription<html.MessageEvent> sub;
    sub = html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is! String) return; // we speak JSON strings both ways
        final msg = jsonDecode(data);
        if (msg is Map &&
            msg['type'] == 'hpg:auth' &&
            msg['customToken'] is String) {
          // Capture the player's identity (name + custom VIPotato avatar) so
          // an authenticated player plays as their own avatar.
          AuthProfile.set(
            name: msg['name'] is String ? msg['name'] as String : null,
            avatarUrl:
                msg['avatarUrl'] is String ? msg['avatarUrl'] as String : null,
          );
          if (!completer.isCompleted) {
            completer.complete(msg['customToken'] as String);
          }
        }
      } catch (_) {
        // Ignore malformed / unrelated postMessages.
      }
    });

    // Tell the parent we're mounted and ready to receive a token.
    parent.postMessage(jsonEncode({'type': 'hpg:authReady'}), '*');

    Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    final token = await completer.future;
    await sub.cancel();
    return token;
  } catch (_) {
    return null;
  }
}
