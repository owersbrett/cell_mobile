import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'general_view_delegate.dart';

class SplashDelegate extends StatefulWidget {
  @override
  _SplashDelegateState createState() => _SplashDelegateState();
}

class _SplashDelegateState extends State<SplashDelegate> {
  late SharedPreferences prefs;
  Future<bool> checkFirstSeen() async {
    prefs = await SharedPreferences.getInstance();
    return (prefs.getBool('seen') ?? false);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkFirstSeen().then((value) {
        prefs.setBool("seen", true);
        return true;
      }),
      builder: (ctx, snapshot) {
        if (snapshot.hasData && snapshot.data as bool) return GeneralViewDelegate(showSplash: false);

        return GeneralViewDelegate(showSplash: true);
      },
    );
  }
}
