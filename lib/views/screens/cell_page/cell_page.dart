import 'package:flutter/material.dart';
import 'cell_body.dart';

class CellPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: CellBody(),
    );
  }
}
