import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_app.dart';

import 'firebase_bootstrap.dart';

Future<void> mainCommon(String env) async {
  // Always call this if the main method is asynchronous
  WidgetsFlutterBinding.ensureInitialized();
  // Load the JSON config into memory
  await SharedPreferences.getInstance();

  runApp(MyApp());

  // Online play is optional and must NEVER block or slow launch — initialise
  // Firebase + anonymous auth in the background. The lobby falls back to local
  // pass-and-play until it's ready (and re-checks when it is).
  unawaited(initFirebaseSafe());
}
