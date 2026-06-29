import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Tzimtzum  (BioScale.nothings)  —  the constant-rate withdrawal
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]), the shared fx kit and the brand theme. No other game's
// code. An agent can rebuild this game by editing only this folder. See
// GAME.md / AGENT.md / EDUCATION.md / POTATUHS.md alongside this file.
//
// THE VERB — GESTURE / HOLD A CONSTANT RATE (a brand-new verb in the catalog):
//   Each prompt names a direction and a duration ("PINCH for 3s" /
//   "STRETCH for 4s"). With TWO fingers you pinch (contract) or stretch
//   (expand) a void on the canvas — and you must keep a STEADY, CONSTANT rate
//   for the whole hold.
//     • Too FAST  → you collapsed too hard: ticks score 0, steadiness craters.
//     • Too SLOW  → you barely contracted: low quality, fewer points.
//     • A smooth CONSTANT speed the entire hold → IDEAL, max points.
//   A live RATE gauge (with an ideal band) and a STEADINESS meter give feedback.
//
// THE LESSON — tzimtzum: the primordial self-contraction. The infinite light
//   withdraws at a measured, deliberate rate to make SPACE — the very making of
//   "nothing". Withdraw too violently and you collapse; too timidly and no
//   space opens. Creation is an act of CONSTANT, restrained contraction.
//
// HOST CONTRACT: the host (MiniGameHost) owns the clock, countdown, score HUD
//   and results. This widget renders ONLY the play area, auto-starts when the
//   session enters play, and reports points via session.addScore /
//   session.noteStreak. It draws no timer, no score, no results.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────

/// Accent — matches the Tzimtzum catalog entry (a withdrawn violet-light).
const Color _kAccent = Color(0xFF8E7BEF);
const Color _kWarn = Color(0xFFFF6E5A);
const Color _kGood = Color(0xFF9DF5C8);

/// The void travel a full ideal hold covers, in normalized void-level units.
/// idealRate = travel / duration, so longer holds want a SLOWER constant rate.
const double _kTravel = 0.78;

/// Maps a two-finger scale delta into void-level change. Higher = a smaller
/// physical pinch moves the void further (so the full travel is reachable).
const double _kSens = 1.35;

/// Per-event void delta clamp — tames spikes when a pointer is added/removed.
const double _kDeltaClamp = 0.12;

/// Relative-rate tolerance for full quality at prompt 0 (tightens each prompt).
/// quality = 1 − |inst−ideal| / (ideal × tol); off by `tol×100%` → zero.
const double _kBaseTol = 1.0;
const double _kMinTol = 0.5;

/// Hold duration ramp (seconds): longer holds as the run progresses.
const double _kBaseDuration = 2.0;
const double _kDurationStep = 0.5;
const double _kMaxDuration = 5.0;

/// Wall-clock grace beyond the target hold before a prompt resolves partial.
const double _kGrace = 3.0;

/// Points for a flawless 3-second hold; other durations scale linearly.
const double _kScorePer3s = 100.0;

/// A "clean" hold (counts toward the streak award).
const double _kCleanCompletion = 0.9;
const double _kCleanSteadiness = 0.78;

/// How long the per-prompt result flash lingers before the next prompt.
const double _kFlashTime = 1.1;

enum _Phase { ready, playing, flash }

class TzimtzumGame extends StatefulWidget {
  final MiniGameSession session;
  const TzimtzumGame({super.key, required this.session});

  @override
  State<TzimtzumGame> createState() => _TzimtzumGameState();
}

class _TzimtzumGameState extends State<TzimtzumGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Run state ──
  bool _started = false;
  _Phase _phase = _Phase.ready;
  int _promptIndex = 0;
  int _streak = 0;
  double _idle = 0.0;

  // ── Current prompt ──
  bool _isPinch = true;
  double _targetDur = _kBaseDuration; // seconds to hold
  double _tol = _kBaseTol; // steadiness tolerance (tightens over run)
  double _idealRate = 0.0; // |void-level / sec| for an ideal hold

  // ── Live gesture / hold tracking ──
  double _voidLevel = 0.9; // 0 = fully withdrawn (space), 1 = full light
  double _prevVoidTick = 0.9; // void level at the previous tick
  double _prevScale = 1.0; // last raw scale from the recognizer
  int _prevPointers = 0; // pointer count at the last update
  bool _active = false; // a valid two-finger gesture is in progress
  double _curRate = 0.0; // smoothed signed rate (void-level / sec)

  double _holdElapsed = 0.0; // valid, correct-direction hold time accrued
  double _qualitySum = 0.0; // ∫ tickQuality dt over active ticks
  double _rateSum = 0.0; // ∫ |inst| dt over active ticks (for too-fast/slow)
  double _activeTime = 0.0; // total active, correct-direction time
  double _steadiness = 0.0; // running average quality (0..1)
  double _promptWall = 0.0; // wall-clock since the prompt began

  // ── Result flash ──
  double _flashAge = 0.0;
  String _flashText = '';
  Color _flashColor = _kAccent;
  int _flashScore = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Prompt lifecycle ───────────────────────────────────────────────────
  void _startPrompt() {
    _isPinch = _promptIndex.isEven; // alternate pinch / stretch
    _targetDur =
        (_kBaseDuration + _kDurationStep * _promptIndex).clamp(_kBaseDuration, _kMaxDuration);
    _tol = (_kBaseTol - 0.05 * _promptIndex).clamp(_kMinTol, _kBaseTol);
    _idealRate = _kTravel / _targetDur;

    // Pinch starts full of light (contract it DOWN); stretch starts withdrawn
    // (expand it UP). The gesture drives the void from there.
    _voidLevel = _isPinch ? 0.9 : 0.1;
    _prevVoidTick = _voidLevel;
    _prevScale = 1.0;
    _active = false;
    _curRate = 0.0;

    _holdElapsed = 0.0;
    _qualitySum = 0.0;
    _rateSum = 0.0;
    _activeTime = 0.0;
    _steadiness = 0.0;
    _promptWall = 0.0;
    _phase = _Phase.playing;
  }

  void _resolvePrompt() {
    final completion = (_holdElapsed / _targetDur).clamp(0.0, 1.0);
    final steadiness =
        _activeTime > 0 ? (_qualitySum / _activeTime).clamp(0.0, 1.0) : 0.0;
    final avgInst = _activeTime > 0 ? _rateSum / _activeTime : 0.0;

    final score =
        (_kScorePer3s * (_targetDur / 3.0) * completion * steadiness).round();
    final clean =
        completion >= _kCleanCompletion && steadiness >= _kCleanSteadiness;

    if (score > 0) widget.session.addScore(score);
    if (clean) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    // Diagnose the result for the flash label.
    if (completion < 0.5) {
      _flashText = 'INCOMPLETE';
      _flashColor = _kWarn;
    } else if (avgInst > _idealRate * 1.3) {
      _flashText = 'TOO FAST';
      _flashColor = _kWarn;
    } else if (avgInst < _idealRate * 0.7) {
      _flashText = 'TOO SLOW';
      _flashColor = Potatuhs.sienna;
    } else if (steadiness >= 0.9 && clean) {
      _flashText = 'PERFECT';
      _flashColor = _kGood;
    } else {
      _flashText = 'STEADY';
      _flashColor = _kAccent;
    }
    _flashScore = score;
    _flashAge = 0.0;
    _phase = _Phase.flash;
  }

  // ── Frame loop ─────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _idle += dt;

    final running = widget.session.isRunning;

    if (running && !_started) {
      _started = true;
      _promptIndex = 0;
      _streak = 0;
      _startPrompt();
    }

    if (running && _started) {
      switch (_phase) {
        case _Phase.playing:
          _promptWall += dt;

          // Instantaneous rate from the void's change since the last tick.
          final rawRate = (_voidLevel - _prevVoidTick) / dt;
          _prevVoidTick = _voidLevel;
          _curRate = _curRate * 0.55 + rawRate * 0.45; // light smoothing

          final dirCorrect =
              _isPinch ? _curRate < -1e-4 : _curRate > 1e-4;
          if (_active && dirCorrect) {
            final inst = _curRate.abs();
            final err = (inst - _idealRate).abs() / _idealRate;
            final q = (1.0 - err / _tol).clamp(0.0, 1.0);
            _qualitySum += q * dt;
            _rateSum += inst * dt;
            _activeTime += dt;
            _holdElapsed += dt;
            _steadiness = _qualitySum / math.max(_activeTime, 1e-3);
          }

          if (_holdElapsed >= _targetDur) {
            _resolvePrompt();
          } else if (_promptWall >= _targetDur + _kGrace) {
            _resolvePrompt();
          }
          break;
        case _Phase.flash:
          _flashAge += dt;
          if (_flashAge >= _kFlashTime) {
            _promptIndex++;
            _startPrompt();
          }
          break;
        case _Phase.ready:
          break;
      }
    }

    if (mounted) setState(() {});
  }

  // ── Two-finger gesture handling (the verb) ──────────────────────────────
  void _onScaleStart(ScaleStartDetails d) {
    _prevScale = 1.0;
    _prevPointers = d.pointerCount;
    _active = d.pointerCount >= 2;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_phase != _Phase.playing || !widget.session.isRunning) {
      _prevScale = d.scale;
      _prevPointers = d.pointerCount;
      _active = false;
      return;
    }
    if (d.pointerCount < 2) {
      // A single finger never withdraws the light — two-finger gesture only.
      _prevScale = d.scale;
      _prevPointers = d.pointerCount;
      _active = false;
      return;
    }
    // When the pointer count changes the recognizer re-bases scale; skip that
    // delta so it doesn't read as a violent collapse.
    if (d.pointerCount == _prevPointers) {
      final dv = ((d.scale - _prevScale) * _kSens)
          .clamp(-_kDeltaClamp, _kDeltaClamp);
      _voidLevel = (_voidLevel + dv).clamp(0.0, 1.0);
    }
    _prevScale = d.scale;
    _prevPointers = d.pointerCount;
    _active = true;
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _active = false;
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TzimtzumPainter(
            t: _idle,
            phase: _phase,
            started: _started,
            running: widget.session.isRunning,
            isPinch: _isPinch,
            voidLevel: _voidLevel,
            idealRate: _idealRate,
            curRate: _curRate,
            tol: _tol,
            steadiness: _activeTime > 0 ? _steadiness : 0.0,
            holdProgress: (_holdElapsed / _targetDur).clamp(0.0, 1.0),
            targetDur: _targetDur,
            active: _active,
            streak: _streak,
            flashText: _flashText,
            flashColor: _flashColor,
            flashScore: _flashScore,
            flashAge: _flashAge,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TzimtzumPainter extends CustomPainter {
  final double t;
  final _Phase phase;
  final bool started;
  final bool running;
  final bool isPinch;
  final double voidLevel;
  final double idealRate;
  final double curRate;
  final double tol;
  final double steadiness;
  final double holdProgress;
  final double targetDur;
  final bool active;
  final int streak;
  final String flashText;
  final Color flashColor;
  final int flashScore;
  final double flashAge;

  _TzimtzumPainter({
    required this.t,
    required this.phase,
    required this.started,
    required this.running,
    required this.isPinch,
    required this.voidLevel,
    required this.idealRate,
    required this.curRate,
    required this.tol,
    required this.steadiness,
    required this.holdProgress,
    required this.targetDur,
    required this.active,
    required this.streak,
    required this.flashText,
    required this.flashColor,
    required this.flashScore,
    required this.flashAge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 30);

    final center = Offset(size.width / 2, size.height * 0.40);
    final maxR = size.shortestSide * 0.34;

    _paintVoid(canvas, center, maxR);

    if (!started) {
      _paintReady(canvas, size);
      return;
    }

    _paintPrompt(canvas, size);
    _paintGauge(canvas, size);
    if (phase == _Phase.flash) _paintFlash(canvas, size);
  }

  // The tzimtzum itself: a field of light with a withdrawn space at the core.
  void _paintVoid(Canvas canvas, Offset center, double maxR) {
    final breathe = started ? 0.0 : 0.02 * math.sin(t * 1.6);
    // The light orb (the Ein-Sof fullness). Shrinks as the void is withdrawn.
    final lightR = maxR * (0.55 + 0.55 * (voidLevel + breathe)).clamp(0.2, 1.1);
    canvas.drawCircle(
      center,
      lightR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(_kAccent, Colors.white, 0.7)!.withValues(alpha: 0.9),
            _kAccent.withValues(alpha: 0.55),
            _kAccent.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: lightR)),
    );

    // The created space (chalal): a dark void grows as the light withdraws.
    final spaceR = maxR * (1.0 - voidLevel).clamp(0.0, 1.0) * 0.92;
    if (spaceR > 1) {
      canvas.drawCircle(
        center,
        spaceR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Potatuhs.inkDeep,
              Potatuhs.inkDeep.withValues(alpha: 0.0),
            ],
            stops: const [0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: spaceR)),
      );
      // The boundary rim where withdrawal meets light.
      canvas.drawCircle(
        center,
        spaceR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kAccent.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Hold-progress arc around the field — fills as a valid hold accrues.
    if (started && phase == _Phase.playing) {
      final arcRect = Rect.fromCircle(center: center, radius: maxR + 14);
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * holdProgress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = (active ? _kGood : _kAccent).withValues(alpha: 0.85),
      );
    }
  }

  void _paintReady(Canvas canvas, Size size) {
    GameFx.text(canvas, 'TZIMTZUM', Offset(size.width / 2, size.height * 0.74),
        30, _kAccent,
        display: true, glow: 0.6);
    GameFx.text(
        canvas,
        'Two-finger PINCH / STRETCH',
        Offset(size.width / 2, size.height * 0.80),
        15,
        Potatuhs.textPrimary);
    GameFx.text(
        canvas,
        'hold a STEADY, constant rate',
        Offset(size.width / 2, size.height * 0.84),
        13,
        Potatuhs.textSecondary);
  }

  void _paintPrompt(Canvas canvas, Size size) {
    final label = isPinch ? 'PINCH' : 'STRETCH';
    final color = isPinch ? _kAccent : Potatuhs.sienna;
    GameFx.text(canvas, label, Offset(size.width / 2, size.height * 0.085), 34,
        color,
        display: true, glow: 0.5);
    GameFx.text(
        canvas,
        'hold ${targetDur.toStringAsFixed(1)}s at a constant rate',
        Offset(size.width / 2, size.height * 0.135),
        13,
        Potatuhs.textSecondary);
    if (streak > 1) {
      GameFx.text(canvas, 'STREAK $streak',
          Offset(size.width / 2, size.height * 0.17), 12, Potatuhs.gold,
          weight: FontWeight.w800);
    }
  }

  // Live RATE gauge (with ideal band) + STEADINESS meter, anchored at bottom.
  void _paintGauge(Canvas canvas, Size size) {
    final x0 = 28.0;
    final x1 = size.width - 28.0;
    final w = x1 - x0;
    final gy = size.height - 84.0;
    final maxRate = idealRate * 2.4;

    double mapRate(double r) => x0 + (r / maxRate).clamp(0.0, 1.0) * w;

    // Track.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0, gy, w, 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(
        track, Paint()..color = Colors.white.withValues(alpha: 0.07));

    // Ideal band.
    final lo = mapRate((idealRate * (1 - tol)).clamp(0.0, maxRate));
    final hi = mapRate((idealRate * (1 + tol)).clamp(0.0, maxRate));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(lo, gy, hi - lo, 16), const Radius.circular(8)),
      Paint()..color = _kGood.withValues(alpha: 0.28),
    );
    // Ideal center line.
    final cx = mapRate(idealRate);
    canvas.drawLine(Offset(cx, gy - 4), Offset(cx, gy + 20),
        Paint()..color = _kGood.withValues(alpha: 0.9)..strokeWidth = 2);

    // Current-rate marker.
    final dirCorrect = isPinch ? curRate < -1e-4 : curRate > 1e-4;
    final mx = mapRate(curRate.abs());
    final inBand = dirCorrect && mx >= lo && mx <= hi;
    final mc = !dirCorrect && active
        ? _kWarn
        : (inBand ? _kGood : _kAccent);
    canvas.drawCircle(Offset(mx, gy + 8), 9,
        Paint()..color = mc.withValues(alpha: active ? 1.0 : 0.45));
    canvas.drawCircle(
        Offset(mx, gy + 8),
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.7));

    GameFx.text(canvas, 'RATE', Offset(x0 + 18, gy - 12), 10,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);

    // Steadiness meter (thin bar below the gauge).
    final sy = gy + 30;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, sy, w, 8), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, sy, w * steadiness, 8), const Radius.circular(4)),
      Paint()
        ..color = Color.lerp(_kWarn, _kGood, steadiness)!
            .withValues(alpha: 0.9),
    );
    GameFx.text(canvas, 'STEADINESS', Offset(x0 + 42, sy + 18), 10,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);
  }

  void _paintFlash(Canvas canvas, Size size) {
    final a = (1.0 - flashAge / _kFlashTime).clamp(0.0, 1.0);
    GameFx.text(canvas, flashText, Offset(size.width / 2, size.height * 0.40),
        38, flashColor.withValues(alpha: a),
        display: true, glow: 0.7 * a);
    if (flashScore > 0) {
      GameFx.text(canvas, '+$flashScore',
          Offset(size.width / 2, size.height * 0.47), 22,
          Potatuhs.gold.withValues(alpha: a),
          weight: FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(covariant _TzimtzumPainter oldDelegate) => true;
}
