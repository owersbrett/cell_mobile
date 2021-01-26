import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_app.dart';

import 'config_reader.dart';
import 'environment.dart';

Future<void> mainCommon(String env) async {
  // Always call this if the main method is asynchronous
  WidgetsFlutterBinding.ensureInitialized();
  // Load the JSON config into memory 
  await SharedPreferences.getInstance();

  await ConfigReader.initialize();

  switch (env) {
    case Environment.dev:
    print('running dev environment');
      break;
    case Environment.prod:
    print('running prod environment');
      break;
  }
  // pass / provide environment specific values in environment specific 
  runApp(MyApp());
}

