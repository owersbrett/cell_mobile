import 'package:flutter/material.dart';

class LoadingResource extends StatelessWidget {
  LoadingResource({@required this.resource});

  final String resource;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 25),
          Text("Loading $resource..."),
        ],
      ),
    );
  }
}
