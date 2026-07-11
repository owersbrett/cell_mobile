import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learn/learn_progress.dart';
import 'my_app.dart';

import 'firebase_bootstrap.dart';

Future<void> mainCommon(String env) async {
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
