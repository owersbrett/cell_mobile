import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap.dart';
import 'my_app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  // Match main_common: never block first paint on Firebase. Online play inits
  // in the background and the lobby enables once it's ready; awaiting here could
  // gray-screen the web build if anonymous auth ever stalls.
  runApp(MyApp());
  unawaited(initFirebaseSafe());
}
