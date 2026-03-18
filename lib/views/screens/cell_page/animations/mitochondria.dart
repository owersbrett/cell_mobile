import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class Mitochondria extends StatefulWidget {
  const Mitochondria({required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  _MitochondriaState createState() => _MitochondriaState();
}

class _MitochondriaState extends State<Mitochondria>
    with TickerProviderStateMixin {
  late AnimationController entryAnimation;
  late AnimationController pulsingAnimation;
  late Tween<double> entryTween;
  late Tween<double> pulseTween;
  late Animation animation;
  late Animation pulseAnimation;

  @override
  void initState() {
    super.initState();
    setUpAnimations();
  }

  setUpAnimations() {
    introAnimation();
    persistantAnimation();
  }

  @override
  void dispose() {
    entryAnimation.dispose();
    pulsingAnimation.dispose();
    super.dispose();
  }

  introAnimation() {
    entryAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    entryTween = Tween<double>(begin: 1.75, end: 1);
    animation = entryTween.animate(entryAnimation)
      ..addListener(() {
        setState(() {});
      });
    entryAnimation.forward();
  }

  persistantAnimation() {
    pulsingAnimation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
      reverseDuration: Duration(milliseconds: 200),
    );
    pulseTween = Tween<double>(begin: 1, end: 1.03);
    pulseAnimation = pulseTween.animate(pulsingAnimation)
      ..addListener(() {
        if (pulsingAnimation.isCompleted){
          pulsingAnimation.reverse();
        } else if (pulsingAnimation.isDismissed) {
          
    pulsingAnimation.forward();
        }
        setState(() {});
      });
    pulsingAnimation.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: animation.value,
      child: AnimatedBuilder(
        animation: entryAnimation,
        builder: (BuildContext context, Widget? child) {
          return AnimatedBuilder(
            animation: pulseAnimation,
            builder: (BuildContext context, Widget? child) {  
              return Transform.scale(
                scale: pulseAnimation.value,
                child: child ?? Container());
            },
            child: child,
          );
        },
        child: Image.asset(widget.organelleInfo.mainImagePath),
      ),
    );
  }
}
