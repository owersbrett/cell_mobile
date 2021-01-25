import 'package:flutter/material.dart';
import 'my_app.dart';

import 'config_reader.dart';
import 'environment.dart';

Future main(String env) async {
  // Always call this if the main method is asynchronous
  WidgetsFlutterBinding.ensureInitialized();
  // Load the JSON config into memory 
  await ConfigReader.initialize();

  runApp(MyApp());
}

