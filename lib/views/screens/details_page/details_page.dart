import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  DetailsPage({@required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black,),
      body: Center(
        child: Text(organelleInfo.name),
      ),
    );
  }
}
