import 'package:flutter/material.dart';

/// Wraps a vertical scrollable and paints a bottom fade whenever more content
/// lies below the fold — the "there's more, keep scrolling" affordance. The
/// fade disappears at the end of the content, so a long article can never be
/// mistaken for one that was cut off mid-sentence.
class ScrollFade extends StatefulWidget {
  final Widget child;

  /// The page background the fade dissolves into.
  final Color color;
  final double height;

  const ScrollFade({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.height = 48,
  });

  @override
  State<ScrollFade> createState() => _ScrollFadeState();
}

class _ScrollFadeState extends State<ScrollFade> {
  bool _more = false;

  void _onMetrics(ScrollMetrics m) {
    final more = m.extentAfter > 4;
    if (more != _more) setState(() => _more = more);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Metrics notifications cover the initial layout / content changes;
        // scroll notifications cover the user actually scrolling.
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            _onMetrics(n.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _onMetrics(n.metrics);
              return false;
            },
            child: widget.child,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _more ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withValues(alpha: 0),
                      widget.color,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
