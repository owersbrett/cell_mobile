import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  DetailsPage({@required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(organelleInfo.name),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 300),
                Text(
                  organelleInfo.name,
                  style: Theme.of(context).textTheme.headline1,
                ),
                Text(organelleInfo.title,
                style: Theme.of(context).textTheme.bodyText2,)
              ],
            ),
          ],
        ),
      ),
    );
  }
}
