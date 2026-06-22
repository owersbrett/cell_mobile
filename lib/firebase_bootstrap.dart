import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_bridge_stub.dart' if (dart.library.html) 'auth_bridge_web.dart';
import 'firebase_options.dart';

/// Initialises Firebase + auth for online party play and play-counting.
/// Idempotent, guarded, and NEVER throws: if it fails (unconfigured platform,
/// offline, auth disabled), the app simply continues as local pass-and-play.
/// Shared by every entry point (main.dart for web, main_common.dart for the
/// flavored mobile/desktop builds) so it behaves the same everywhere.
///
/// Auth resolution order:
///  1. **Embedded SSO** — when running inside the hotpotatogames.com `<iframe>`,
///     ask the parent page for a Firebase custom token minted (via the
///     `issueCustomToken` function) for the site's signed-in user, and sign in
///     with it. Plays + party are then attributed to the real account.
///  2. **Anonymous fallback** — standalone app, logged-out visitor, or the
///     parent doesn't respond: anonymous auth, exactly as before.
Future<void> initFirebaseSafe() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      final customToken = await requestParentAuthToken();
      if (customToken != null) {
        try {
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
        } catch (e) {
          debugPrint('Cell SSO sign-in failed; using anonymous: $e');
          await FirebaseAuth.instance.signInAnonymously();
        }
      } else {
        await FirebaseAuth.instance.signInAnonymously();
      }
    }
  } catch (e) {
    debugPrint('Firebase init skipped; online play disabled this session: $e');
  }
}
