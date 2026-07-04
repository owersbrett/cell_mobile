import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';

/// The device kind every synthetic (bot) pointer carries. A real human touch is
/// `touch` / `mouse` / `trackpad`; the attract-mode bot stamps `unknown` so a
/// top-level [Listener] can tell "the loop tapped" apart from "the human tapped"
/// and eject only on the latter. See `AttractScreen`.
const PointerDeviceKind kAutoTapKind = PointerDeviceKind.unknown;

/// Drives games hands-free by synthesizing real pointer events straight into the
/// gesture pipeline ([GestureBinding.handlePointerEvent]). It knows nothing about
/// any specific game — it just taps (and occasionally drags) inside a rectangle,
/// which is enough to make ~every mini-game visibly react for attract-mode
/// b-roll. Per-game "smart" autopilots can layer on later for camera-featured
/// games; this is the universal baseline that covers all of them day one.
class AutoTapper {
  AutoTapper({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  // Reserved high pointer-id range, well clear of any real engine pointer, so
  // synthetic down/up pairs never collide with a live human touch.
  int _pointer = 1 << 20;
  // Monotonic timestamps keep the velocity tracker happy on drags.
  int _elapsedMs = 0;

  int get _nextPointer => ++_pointer;
  Duration get _stamp => Duration(milliseconds: _elapsedMs += 8);

  void _dispatch(PointerEvent e) =>
      GestureBinding.instance.handlePointerEvent(e);

  /// A quick tap at [p] (global, logical pixels).
  void tap(Offset p) {
    final id = _nextPointer;
    _dispatch(PointerDownEvent(
        pointer: id, kind: kAutoTapKind, position: p, timeStamp: _stamp));
    _dispatch(PointerUpEvent(
        pointer: id, kind: kAutoTapKind, position: p, timeStamp: _stamp));
  }

  /// A short drag from [a] to [b] over a few frames — enough to trip pan
  /// recognizers (steer/aim/launch games) with a bit of velocity.
  Future<void> drag(Offset a, Offset b, {int steps = 6}) async {
    final id = _nextPointer;
    _dispatch(PointerDownEvent(
        pointer: id, kind: kAutoTapKind, position: a, timeStamp: _stamp));
    var prev = a;
    for (var i = 1; i <= steps; i++) {
      final p = Offset.lerp(a, b, i / steps)!;
      _dispatch(PointerMoveEvent(
          pointer: id,
          kind: kAutoTapKind,
          position: p,
          delta: p - prev,
          timeStamp: _stamp));
      prev = p;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _dispatch(PointerUpEvent(
        pointer: id, kind: kAutoTapKind, position: prev, timeStamp: _stamp));
  }

  /// One randomized action inside [area]: mostly taps, sometimes a drag. Fire
  /// this on the loop's cadence (every 250ms during play).
  void act(Rect area) {
    Offset rnd() => Offset(
          area.left + _rng.nextDouble() * area.width,
          area.top + _rng.nextDouble() * area.height,
        );
    if (_rng.nextDouble() < 0.3) {
      // Fire-and-forget; the await inside only paces this one drag.
      unawaited(drag(rnd(), rnd()));
    } else {
      tap(rnd());
    }
  }
}
