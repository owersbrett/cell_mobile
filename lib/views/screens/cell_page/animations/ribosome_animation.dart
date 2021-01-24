import 'dart:io';
import 'dart:math';

import 'package:arc_animator/arc_animator.dart';
import 'package:flutter/material.dart';

class RibosomeAnimation extends StatefulWidget {
  RibosomeAnimation({this.path, this.persistant});
  final String path;
  final bool persistant;
  @override
  _RibosomeAnimationState createState() => _RibosomeAnimationState();
}

class _RibosomeAnimationState extends State<RibosomeAnimation>
    with TickerProviderStateMixin {
  Offset top = Offset(0, 4);
  Offset bottom = Offset(0, -4);
  Offset left = Offset(-4, 0);
  Offset right = Offset(4, 0);
  Offset begin;
  Offset end;
  AnimationController animationController;
  Animation<double> animation;
  Tween<double> tween;

  AnimationController xWiggleController;

  @override
  void initState() {
    super.initState();
    begin = top;
    end = right;

    introAnimation();
    persistantAnimation();
  }

  introAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    tween = Tween<double>(begin: 1.75, end: 1);
    animation = tween.animate(animationController)
      ..addListener(() {
        setState(() {});
      });
    animationController.forward();
  }

  persistantAnimation() {
    if (xWiggleController != null) xWiggleController.forward();
    xWiggleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..addListener(() {});
    xWiggleController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    xWiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.persistant
        ? Transform.scale(
            scale: animation.value,
            child: ArcAnimator(
              offsetChanging: (changedOffset) {
                print(changedOffset.direction == begin.direction);
                if (changedOffset.direction > right.direction) {
                  setState(() {
                    begin = right;
                    end = bottom;
                  });
                  xWiggleController.forward();
                } else if (changedOffset.direction == 0.0) {
                  setState(() {
                    begin = bottom;
                    end = left;
                  });
                  xWiggleController.forward();
                }
              },
              curve: Curves.easeInOutSine,
              begin: begin,
              end: end,
              controller: xWiggleController,
              child: Container(
                child: Image.asset(
                  widget.path,
                ),
              ),
            ),
          )
        : Transform.scale(
            scale: animation.value,
            child: Container(
              child: Image.asset(widget.path),
            ),
          );
    // return Transform.scale(
    //   scale: animation.value,
    //   child: Transform.translate(
    //     offset: Offset(animationX.value, animationY.value),
    //     child: Container(
    //       child: Image.asset(
    //         widget.path,
    //       ),
    //     ),
    //   ),
    // );
  }
}
