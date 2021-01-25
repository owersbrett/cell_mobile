import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Center(
            child: Text('Cell'),
          ),
          SizedBox(height: 100),
          MaterialButton(
            child: Text(
              'Explore The Cell',
              style: Theme.of(context).textTheme.headline1,
            ),
            color: Colors.red,
          
            onPressed: () {
              print('hello');
            },
          )
        ],
      ),
    );
  }
}
