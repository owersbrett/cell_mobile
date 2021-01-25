import 'dart:math';

import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class GeneticAnimation extends StatefulWidget {
  GeneticAnimation({@required this.organelleInfo, @required this.fast, @required this.right,});
  final bool fast;
  final bool right;
  final OrganelleInfo organelleInfo;
  @override
  _GeneticAnimationState createState() => _GeneticAnimationState();
}

class _GeneticAnimationState extends State<GeneticAnimation>
    with TickerProviderStateMixin {
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.fast ? 2 : 5),
      upperBound: pi * 2,
    );

    animationController.forward();
    animationController.addListener(() {
      setState(() {
        if (animationController.status == AnimationStatus.completed) {
          animationController.repeat();
        }
      });
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      alignment: Alignment.center,
      child: new AnimatedBuilder(
        animation: animationController,
        child: new Container(
          child: new Image.asset(widget.organelleInfo.mainImagePath),
        ),
        builder: (BuildContext context, Widget _widget) {
          return new Transform.rotate(
            angle: widget.right ? animationController.value : -animationController.value,
            child: _widget,
          );
        },
      ),
    );
  }
}
