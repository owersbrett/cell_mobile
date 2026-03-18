import 'package:flutter/material.dart';

class RibosomeAnimation extends StatefulWidget {
  RibosomeAnimation({required this.path, required this.persistant});
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
  late Offset begin;
  late Offset end;
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<Offset> positionAnimation;

  late AnimationController xWiggleController;

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
    scaleAnimation = Tween<double>(begin: 1.75, end: 1).animate(animationController)
      ..addListener(() {
        setState(() {});
      });
    animationController.forward();
  }

  persistantAnimation() {
    xWiggleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    positionAnimation = Tween<Offset>(begin: top, end: right).animate(
      CurvedAnimation(
        parent: xWiggleController,
        curve: Curves.easeInOutSine,
      ),
    )..addListener(() {
        setState(() {});
      });

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
            scale: scaleAnimation.value,
            child: AnimatedBuilder(
              animation: positionAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: positionAnimation.value,
                  child: child,
                );
              },
              child: Container(
                child: Image.asset(
                  widget.path,
                ),
              ),
            ),
          )
        : Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              child: Image.asset(widget.path),
            ),
          );
  }
}
