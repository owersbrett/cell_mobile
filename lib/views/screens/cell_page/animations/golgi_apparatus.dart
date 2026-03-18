import 'package:cell_mobile/models/organelle.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/ribosome_animation.dart';
import 'package:flutter/material.dart';

class GolgiApparatus extends StatefulWidget {
  GolgiApparatus({required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  _GolgiApparatusState createState() => _GolgiApparatusState();
}

class _GolgiApparatusState extends State<GolgiApparatus> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11.0, right: 4),
      child: Transform.translate(
        offset: Offset(-15, 10),
        child: Transform.scale(
          scale: .75,
          child: RibosomeAnimation(
            path: widget.organelleInfo.mainImagePath,
            persistant: false,
          ),
        ),
      ),
    );
  }
}
