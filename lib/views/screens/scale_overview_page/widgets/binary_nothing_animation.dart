import 'package:flutter/material.dart';

/// Binary-to-nothing animation for the BioScale.nothings card.
///
/// Sequence (runs once, ~7s total):
///  1. Pure black (1s)
///  2. "0" fades in — holds 0.8s
///  3. "0" morphs to "1" (crossfade) — holds 0.8s
///  4. Flickers: rapid 0→1→0→1 (4 flickers, 0.1s each = 0.4s)
///  5. Settles on "1" (0.3s)
///  6. "1" → "Φ" crossfade — holds 0.6s
///  7. "Φ" → "Θ" crossfade — holds 0.6s
///  8. "Θ" → "θ" crossfade — holds 0.6s
///  9. "θ" → "ι" crossfade — holds 0.6s
/// 10. "ι" fades to nothing (0.5s)
/// 11. Black — tap to replay.
class BinaryNothingAnimation extends StatefulWidget {
  final Color color;

  const BinaryNothingAnimation({Key? key, required this.color})
      : super(key: key);

  @override
  State<BinaryNothingAnimation> createState() =>
      _BinaryNothingAnimationState();
}

class _BinaryNothingAnimationState extends State<BinaryNothingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _completed = false;

  // Total duration in seconds
  static const double _totalSeconds = 6.7;

  // Phase boundaries (cumulative seconds)
  //  Phase 0: black           0.0  – 1.0
  //  Phase 1: "0" fade-in     1.0  – 1.8
  //  Phase 2: "0"→"1"         1.8  – 2.6
  //  Phase 3: flicker         2.6  – 3.0
  //  Phase 4: settle "1"      3.0  – 3.3
  //  Phase 5: "1"→"Φ"         3.3  – 3.9
  //  Phase 6: "Φ"→"Θ"         3.9  – 4.5
  //  Phase 7: "Θ"→"θ"         4.5  – 5.1
  //  Phase 8: "θ"→"ι"         5.1  – 5.7
  //  Phase 9: "ι" fade-out    5.7  – 6.2
  //  Phase 10: stay black     6.2  – 6.7 (done)

  static const List<double> _phaseEnds = [
    1.0, // 0: black
    1.8, // 1: "0" fade-in
    2.6, // 2: "0" → "1"
    3.0, // 3: flicker
    3.3, // 4: settle "1"
    3.9, // 5: "1" → "Φ"
    4.5, // 6: "Φ" → "Θ"
    5.1, // 7: "Θ" → "θ"
    5.7, // 8: "θ" → "ι"
    6.2, // 9: "ι" fade-out
    6.7, // 10: black (done)
  ];

  static double _phaseStart(int phase) => phase == 0 ? 0.0 : _phaseEnds[phase - 1];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalSeconds * 1000).round()),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _completed = true);
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _replay() {
    if (_completed) {
      setState(() => _completed = false);
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  /// Returns [phase, localProgress 0..1] as a two-element list.
  List<double> _currentPhase(double seconds) {
    for (int i = 0; i < _phaseEnds.length; i++) {
      if (seconds <= _phaseEnds[i]) {
        final start = _phaseStart(i);
        final dur = _phaseEnds[i] - start;
        final local = dur > 0 ? ((seconds - start) / dur).clamp(0.0, 1.0) : 1.0;
        return [i.toDouble(), local];
      }
    }
    return [10.0, 1.0];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _replay,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final seconds = _ctrl.value * _totalSeconds;
          final phaseData = _currentPhase(seconds);
          final phase = phaseData[0].toInt();
          final t = phaseData[1];

          return Container(
            color: Colors.black,
            child: Center(
              child: _buildPhaseContent(phase, t),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhaseContent(int phase, double t) {
    switch (phase) {
      case 0: // Pure black
        return const SizedBox.shrink();

      case 1: // "0" fades in
        return Opacity(
          opacity: Curves.easeIn.transform(t),
          child: _glyph('0', 48),
        );

      case 2: // "0" → "1" crossfade
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 1.0 - Curves.easeInOut.transform(t),
              child: Transform.scale(
                scale: 1.0 + t * 0.05,
                child: _glyph('0', 48),
              ),
            ),
            Opacity(
              opacity: Curves.easeInOut.transform(t),
              child: Transform.scale(
                scale: 0.95 + t * 0.05,
                child: _glyph('1', 48),
              ),
            ),
          ],
        );

      case 3: // Flicker: 4 rapid alternations (0→1→0→1)
        // 4 flickers in 0.4s: each 0.1s
        final flickerIndex = (t * 4).floor().clamp(0, 3);
        final showOne = flickerIndex.isOdd;
        return Opacity(
          opacity: 0.7 + (flickerIndex.isEven ? 0.3 : 0.0),
          child: _glyph(showOne ? '1' : '0', 48),
        );

      case 4: // Settle on "1"
        return _glyph('1', 48);

      case 5: // "1" → "Φ" crossfade
        return _crossfade('1', 48, '\u03A6', 44, t);

      case 6: // "Φ" → "Θ" crossfade
        return _crossfade('\u03A6', 44, '\u0398', 42, t);

      case 7: // "Θ" → "θ" crossfade
        return _crossfade('\u0398', 42, '\u03B8', 38, t);

      case 8: // "θ" → "ι" crossfade
        return _crossfade('\u03B8', 38, '\u03B9', 34, t);

      case 9: // "ι" fade out
        return Opacity(
          opacity: 1.0 - Curves.easeOut.transform(t),
          child: _glyph('\u03B9', 34),
        );

      default: // Phase 10+: black
        return const SizedBox.shrink();
    }
  }

  Widget _glyph(String char, double fontSize) {
    return Text(
      char,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontFamily: 'Avenir',
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _crossfade(
      String from, double fromSize, String to, double toSize, double t) {
    final eased = Curves.easeInOut.transform(t);
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 1.0 - eased,
          child: Transform.scale(
            scale: 1.0 + eased * 0.08,
            child: _glyph(from, fromSize),
          ),
        ),
        Opacity(
          opacity: eased,
          child: Transform.scale(
            scale: 0.92 + eased * 0.08,
            child: _glyph(to, toSize),
          ),
        ),
      ],
    );
  }
}
