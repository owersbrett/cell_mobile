import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'environment.dart';
import 'firebase_bootstrap.dart';
import 'learn/learn_progress.dart';
import 'my_app.dart';

/// Single launch path for every entry point (web `main.dart` and the flavored
/// `main_<env>.dart` builds). Resolving the environment FIRST — before any
/// Firebase or data access — is the whole contract: the data layer namespaces
/// itself off [AppEnv.current], so it must be pinned before `initFirebaseSafe`.
///
/// [env] is passed only by the flavored entry points; web omits it and the
/// environment comes from `--dart-define=APP_ENV` (default prod).
Future<void> bootstrap({AppEnvId? env}) async {
  // Pin the environment before ANYTHING touches Firebase/Firestore/RTDB.
  if (env != null) AppEnv.override(env);

  // Always call this if the main method is asynchronous
  WidgetsFlutterBinding.ensureInitialized();
  // Clean /{slug} URLs on web for single-game iframe embeds. No-op on mobile.
  if (kIsWeb) usePathUrlStrategy();
  // Load the JSON config into memory
  await SharedPreferences.getInstance();
  // Viewed-topic progress for LEARN (cards/modules/explorer read it sync).
  await LearnProgress.instance.load();

  runApp(MyApp());

  // Online play is optional and must NEVER block or slow launch — initialise
  // Firebase + anonymous auth in the background. The lobby falls back to local
  // pass-and-play until it's ready (and re-checks when it is).
  unawaited(initFirebaseSafe());
}

/// Back-compat alias for the flavored entry points.
Future<void> mainCommon(AppEnvId env) => bootstrap(env: env);
