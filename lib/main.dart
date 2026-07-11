import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap.dart';
import 'learn/learn_progress.dart';
import 'my_app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean /{slug} URLs on web for single-game iframe embeds. No-op on mobile.
  if (kIsWeb) usePathUrlStrategy();
  await SharedPreferences.getInstance();
  // Viewed-topic progress for LEARN (cards/modules/explorer read it sync).
  await LearnProgress.instance.load();
  // Match main_common: never block first paint on Firebase. Online play inits
  // in the background and the lobby enables once it's ready; awaiting here could
  // gray-screen the web build if anonymous auth ever stalls.
  runApp(MyApp());
  unawaited(initFirebaseSafe());
}
