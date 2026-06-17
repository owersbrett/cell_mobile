import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Initialises Firebase + anonymous auth for online party play. Idempotent,
/// guarded, and NEVER throws: if it fails (unconfigured platform, offline,
/// auth disabled), the app simply continues as local pass-and-play. Shared by
/// every entry point (main.dart for web, main_common.dart for the flavored
/// mobile/desktop builds) so online play works the same everywhere.
Future<void> initFirebaseSafe() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase init skipped; online play disabled this session: $e');
  }
}
