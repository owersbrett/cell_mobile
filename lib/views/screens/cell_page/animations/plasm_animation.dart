import 'package:flutter/material.dart';

class PlasmAnimation extends StatefulWidget {
  PlasmAnimation({required this.image});
  final Widget image;
  @override
  _PlasmAnimationState createState() => _PlasmAnimationState();
}

class _PlasmAnimationState extends State<PlasmAnimation> {
  @override
  Widget build(BuildContext context) {
    return widget.image;
    // return AnimatedOpacity(
    //   duration: null,
    //   opacity: null,
    //   child: widget.image,
    // );
  }
}
