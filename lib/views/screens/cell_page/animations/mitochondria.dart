import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class Mitochondria extends StatefulWidget {
  const Mitochondria({@required this.organelleInfo});
  final OrganelleInfo organelleInfo;
  @override
  _MitochondriaState createState() => _MitochondriaState();
}

class _MitochondriaState extends State<Mitochondria>
    with TickerProviderStateMixin {
  AnimationController entryAnimation;
  AnimationController pulsingAnimation;
  Tween<double> entryTween;
  Animation animation;


  @override
  void initState() {
    super.initState();
    setUpAnimations();
  }

  setUpAnimations() {
    introAnimation();
    pulsingAnimation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
      reverseDuration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
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
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: animation.value,
          child: AnimatedBuilder(
        animation: entryAnimation,
        builder: (BuildContext context, Widget child) { 
          print('hey');
          return child;
         },
        child: Image.asset(widget.organelleInfo.mainImagePath),
      ),
    );
  }
}
