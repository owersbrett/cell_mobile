import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(MyApp());
}

