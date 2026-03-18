import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_app.dart';

import 'config_reader.dart';


Future main() async {
  // Always call this if the main method is asynchronous
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  // Load the JSON config into memory 
  // await ConfigReader.initialize();

  runApp(MyApp());
}

