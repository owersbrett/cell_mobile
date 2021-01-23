import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class Nucleolus extends StatefulWidget {
  Nucleolus({@required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  _NucleolousState createState() => _NucleolousState();
}

class _NucleolousState extends State<Nucleolus> with TickerProviderStateMixin {
  AnimationController motionController;
  Animation motionAnimation;

  double size = 20;

  void initState() {
    super.initState();

    motionController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
      lowerBound: 0.5,
    );

    motionAnimation = CurvedAnimation(
      parent: motionController,
      curve: Curves.ease,
    );

    motionController.forward();
    motionController.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.completed) {
          motionController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          motionController.forward();
        }
      });
    });

    motionController.addListener(() {
      setState(() {
        size = motionController.value * 250;
      });
    });
    // motionController.repeat();
  }

  @override
  void dispose() {
    motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      widget.organelleInfo.mainImagePath,
      width: size,
      height: size,
    );
  }
}

// OrganelleInfo(
//     0,
//     name: "Nucleolus",
//     organelle: Organelle.nucleolus,
//     mainImagePath: "assets/images/nucleolus.png",
//     shortDescription: "I am the nucleolus...",
//     longDescription: "My function is...",
//     carouselImagesPaths: ["Link this to repo"],
//   ),
