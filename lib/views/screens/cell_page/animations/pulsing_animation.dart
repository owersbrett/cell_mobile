import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class PulsingAnimation extends StatefulWidget {
  PulsingAnimation({@required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  _PulsingAnimationState createState() => _PulsingAnimationState();
}

class _PulsingAnimationState extends State<PulsingAnimation> with TickerProviderStateMixin {
  AnimationController motionController;
  Animation motionAnimation;

  double size = 20;

  void initState() {
    super.initState();

    motionController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
      lowerBound: .9,
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
        size = motionController.value * 300;
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
    print('hello');
    print('brett');
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
