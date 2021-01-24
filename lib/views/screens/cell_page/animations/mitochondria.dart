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

  @override
  void initState() {
    super.initState();
    setUpAnimations();
  }

  setUpAnimations() {
    entryAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
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

  @override
  Widget build(BuildContext context) {
    return Image.asset(widget.organelleInfo.mainImagePath);
  }
}
