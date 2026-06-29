import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══ Superposition ════════════════════════════════════════════════════════════
// VERB: MEASURE-AT-THE-RIGHT-MOMENT.
//
// A qubit lives in a SUPERPOSITION of |↑⟩ and |↓⟩. Its wavefunction oscillates,
// so the probability of measuring "up" — P↑ = ½ + ½·sin(phase) — sweeps between
// 0 and 1 over time (P↓ = 1 − P↑; they always sum to one). A glowing target pole
// tells you which outcome you want. Tap MEASURE to COLLAPSE the wavefunction: the
// system snaps to a single definite state, drawn at random *weighted by the
// current probability*. Land your target and you score by that probability — so
// measure when the wave most favors the target (P near 1). Measure at the equator
// (50/50) and it is a literal coin-flip.
//
// Accelerates: the oscillation speeds up (favorable windows pass faster), then a
// SECOND qubit appears — both must collapse to their targets, and the joint
// probability multiplies (amplitudes multiply), so the payoff for nailing both at
// once is huge but the timing is brutal.

// ── Feel constants ────────────────────────────────────────────────────────────
const Color _kUp = Color(0xFF7C9CFF); // |↑⟩ — cool blue
const Color _kDown = Color(0xFFCE93D8); // |↓⟩ — violet
const Color _kAccent = Color(0xFF7272AB); // glaucous — multiverse accent
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kInk = Color(0xFF07060D);

/// Base angular speed of the wavefunction (rad/s) at level 1.
const double _kBaseOmega = 1.55;

/// Added to omega per level (oscillation accelerates → narrower windows).
const double _kOmegaStep = 0.32;
const double _kOmegaCap = 4.6;

/// Favorable collapses per difficulty level.
const int _kFavPerLevel = 3;

/// Level at which a second qubit joins the system.
const int _kTwoQubitLevel = 4;

/// How long the collapsed (definite) state is held before a fresh superposition.
const double _kCollapseHold = 0.62;

/// Idle oscillation speed during the calm ready / countdown state.
const double _kIdleOmega = 0.7;

class SuperpositionGame extends StatefulWidget {
  final MiniGameSession session;
  const SuperpositionGame({super.key, required this.session});

  @override
  State<SuperpositionGame> createState() => _SuperpositionGameState();
}

class _SuperpositionGameState extends State<SuperpositionGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Wavefunction state (index 0 & 1 are the two possible qubits) ───────────
  final List<double> _phase = [0.0, math.pi];
  final List<bool> _target = [true, true]; // true = want |↑⟩
  final List<bool> _outUp = [true, true]; // last measured outcome
  final List<bool> _fav = [true, true]; // whether each landed its target
  int _n = 1; // active qubit count this round

  // ── Progress ───────────────────────────────────────────────────────────────
  int _favorable = 0;
  int _streak = 0;

  // ── Collapse state machine ──────────────────────────────────────────────────
  double _collapseT = 0.0; // >0 ⇒ showing a definite (collapsed) state
  bool? _lastAllFav; // result tint for the collapse flash

  // ── Juice ───────────────────────────────────────────────────────────────────
  double _flashGood = 0.0;
  double _flashBad = 0.0;
  double _idle = 0.0; // ambient clock for background drift
  final List<FxParticle> _parts = [];
  final List<FxPop> _pops = [];

  int get _level =>
      (1 + _favorable ~/ _kFavPerLevel).clamp(1, 9);
  double get _omega =>
      math.min(_kOmegaCap, _kBaseOmega + (_level - 1) * _kOmegaStep);

  @override
  void initState() {
    super.initState();
    _respawn();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    _idle += dt;

    if (_collapseT > 0) {
      // Wavefunction frozen at its collapsed (definite) outcome.
      _collapseT = math.max(0.0, _collapseT - dt);
      if (_collapseT == 0 && running) _respawn();
    } else {
      // Oscillate. Faster while playing, gentle while idle/countdown.
      final w = running ? _omega : _kIdleOmega;
      for (var i = 0; i < 2; i++) {
        _phase[i] += w * (i == 1 ? 0.86 : 1.0) * dt;
        if (_phase[i] > 2 * math.pi) _phase[i] -= 2 * math.pi;
      }
    }

    _flashGood = math.max(0.0, _flashGood - dt * 2.6);
    _flashBad = math.max(0.0, _flashBad - dt * 3.0);

    _parts.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  double _pUp(int i) => 0.5 + 0.5 * math.sin(_phase[i]);

  void _measure(Size size) {
    if (!widget.session.isRunning || _collapseT > 0) return;

    double joint = 1.0;
    bool allFav = true;
    for (var i = 0; i < _n; i++) {
      final pUp = _pUp(i);
      final up = _rng.nextDouble() < pUp;
      _outUp[i] = up;
      _fav[i] = up == _target[i];
      if (!_fav[i]) allFav = false;
      joint *= _target[i] ? pUp : (1.0 - pUp);
    }

    final centers = _spheres(size);
    if (allFav) {
      final base = _n == 2 ? 150 : 100;
      final pts = (base * joint).round() + _streak * 4;
      widget.session.addScore(pts);
      _favorable++;
      _streak++;
      widget.session.noteStreak(_streak);
      _flashGood = 1.0;
      for (var i = 0; i < _n; i++) {
        _parts.addAll(FxBurst.spawn(centers[i], _kGood, count: 16, speed: 150));
      }
      _pops.add(FxPop(
        Offset(size.width / 2, size.height * 0.30),
        '+$pts',
        _kGood,
      ));
    } else {
      _streak = 0;
      _flashBad = 1.0;
      _pops.add(FxPop(
        Offset(size.width / 2, size.height * 0.30),
        'WRONG STATE',
        _kBad,
      ));
    }
    _lastAllFav = allFav;
    _collapseT = _kCollapseHold;
  }

  void _respawn() {
    _n = _level >= _kTwoQubitLevel ? 2 : 1;
    for (var i = 0; i < 2; i++) {
      _phase[i] = _rng.nextDouble() * 2 * math.pi;
      _target[i] = _rng.nextBool();
    }
    _lastAllFav = null;
  }

  /// Centers of the active spheres for the current size.
  List<Offset> _spheres(Size size) {
    final cy = size.height * 0.44;
    if (_n == 1) return [Offset(size.width / 2, cy)];
    final dx = size.width * 0.24;
    return [Offset(size.width / 2 - dx, cy), Offset(size.width / 2 + dx, cy)];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _measure(size),
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _SuperpositionPainter(
              phase: List<double>.from(_phase),
              target: List<bool>.from(_target),
              outUp: List<bool>.from(_outUp),
              fav: List<bool>.from(_fav),
              n: _n,
              collapsed: _collapseT > 0,
              collapseT: _collapseT,
              lastAllFav: _lastAllFav,
              flashGood: _flashGood,
              flashBad: _flashBad,
              idle: _idle,
              level: _level,
              streak: _streak,
              running: widget.session.isRunning,
              parts: _parts,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SuperpositionPainter extends CustomPainter {
  final List<double> phase;
  final List<bool> target;
  final List<bool> outUp;
  final List<bool> fav;
  final int n;
  final bool collapsed;
  final double collapseT;
  final bool? lastAllFav;
  final double flashGood;
  final double flashBad;
  final double idle;
  final int level;
  final int streak;
  final bool running;
  final List<FxParticle> parts;
  final List<FxPop> pops;

  _SuperpositionPainter({
    required this.phase,
    required this.target,
    required this.outUp,
    required this.fav,
    required this.n,
    required this.collapsed,
    required this.collapseT,
    required this.lastAllFav,
    required this.flashGood,
    required this.flashBad,
    required this.idle,
    required this.level,
    required this.streak,
    required this.running,
    required this.parts,
    required this.pops,
  });

  double _pUp(int i) => 0.5 + 0.5 * math.sin(phase[i]);

  List<Offset> _spheres(Size size) {
    final cy = size.height * 0.44;
    if (n == 1) return [Offset(size.width / 2, cy)];
    final dx = size.width * 0.24;
    return [Offset(size.width / 2 - dx, cy), Offset(size.width / 2 + dx, cy)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background.
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, _kAccent, idle, motes: 26);

    final centers = _spheres(size);
    final r = math.min(size.width / (n == 1 ? 3.4 : 5.4), size.height * 0.20);

    _paintHeader(canvas, size);
    for (var i = 0; i < n; i++) {
      _paintQubit(canvas, centers[i], r, i);
    }
    _paintProbabilityBar(canvas, size);
    _paintMeasurePrompt(canvas, size);

    FxBurst.paint(canvas, parts);
    for (final p in pops) {
      p.paint(canvas);
    }

    // Full-screen collapse flash.
    if (flashGood > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: (flashGood - 0.25) * 0.32));
    }
    if (flashBad > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: (flashBad - 0.25) * 0.30));
    }
  }

  // ── Header: level + target instruction ─────────────────────────────────────
  void _paintHeader(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      n == 2 ? 'COLLAPSE BOTH TO TARGET' : 'COLLAPSE TO THE GLOWING STATE',
      Offset(size.width / 2, 22),
      12,
      Potatuhs.textSecondary,
      weight: FontWeight.w700,
    );
    // Level + streak chips.
    GameFx.text(canvas, 'LV $level', Offset(28, 18), 11, _kAccent,
        weight: FontWeight.w800);
    if (streak >= 2) {
      GameFx.text(canvas, '🔥$streak', Offset(size.width - 26, 18), 12, _kGood,
          weight: FontWeight.w800);
    }
  }

  // ── One Bloch-style qubit sphere ───────────────────────────────────────────
  void _paintQubit(Canvas canvas, Offset c, double r, int i) {
    final pUp = _pUp(i);
    final wantUp = target[i];
    final targetColor = wantUp ? _kUp : _kDown;

    // Sphere shell.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kAccent.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          _kAccent.withValues(alpha: 0.10),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Equator ellipse (the 50/50 line).
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 2, height: r * 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    // Vertical axis.
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy + r),
      Paint()
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    final upPole = Offset(c.dx, c.dy - r);
    final downPole = Offset(c.dx, c.dy + r);
    _paintPole(canvas, upPole, '↑', _kUp, wantUp);
    _paintPole(canvas, downPole, '↓', _kDown, !wantUp);

    if (collapsed) {
      // Definite, collapsed state: crisp vector snapped to the measured pole.
      final landedUp = outUp[i];
      final tip = landedUp ? upPole : downPole;
      final ok = fav[i];
      final col = ok ? _kGood : _kBad;
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..color = col,
      );
      GameFx.orb(canvas, tip, 9, col, glow: 1.2);
      // Collapse ring.
      final ringT = 1.0 - (collapseT / _kCollapseHold);
      canvas.drawCircle(
        c,
        r * (0.3 + ringT * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - ringT)
          ..color = col.withValues(alpha: 0.6 * (1 - ringT)),
      );
    } else {
      // Live superposition: a blurred, sweeping state vector with ghost trail.
      // tip vertical position: P↑=1 → up pole, P↑=0 → down pole.
      double tipY(double p) => c.dy - r * (2 * p - 1) * 0.92;
      // Ghost trail conveys the oscillation / uncertainty.
      for (var g = 5; g >= 1; g--) {
        final ph = phase[i] - g * 0.16;
        final p = 0.5 + 0.5 * math.sin(ph);
        final wob = math.sin(ph * 1.7) * r * 0.18;
        final tip = Offset(c.dx + wob, tipY(p));
        canvas.drawLine(
          c,
          tip,
          Paint()
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round
            ..color = targetColor.withValues(alpha: 0.10 * (6 - g)),
        );
      }
      final wob = math.sin(phase[i] * 1.7) * r * 0.18;
      final tip = Offset(c.dx + wob, tipY(pUp));
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4)
          ..color = Color.lerp(_kDown, _kUp, pUp)!.withValues(alpha: 0.95),
      );
      // Fuzzy probability cloud at the tip.
      canvas.drawCircle(
        tip,
        11,
        Paint()
          ..color = Color.lerp(_kDown, _kUp, pUp)!.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // P(target) readout under the sphere.
      final pTarget = wantUp ? pUp : (1 - pUp);
      final near = pTarget > 0.85;
      GameFx.text(
        canvas,
        'P(target) ${(pTarget * 100).round()}%',
        Offset(c.dx, c.dy + r + 22),
        13,
        near ? _kGood : Potatuhs.textSecondary,
        weight: FontWeight.w800,
        glow: near ? 0.7 : 0,
      );
    }
  }

  void _paintPole(
      Canvas canvas, Offset p, String glyph, Color color, bool isTarget) {
    if (isTarget) {
      // Target pole glows — this is the outcome you want.
      canvas.drawCircle(
        p,
        16,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = color,
      );
    }
    canvas.drawCircle(p, 5, Paint()..color = color.withValues(alpha: 0.9));
    GameFx.text(canvas, glyph, p, 13, Colors.white,
        weight: FontWeight.w900);
  }

  // ── Probability bar (the skill read) ───────────────────────────────────────
  void _paintProbabilityBar(Canvas canvas, Size size) {
    if (collapsed) return;
    final w = size.width * 0.74;
    final left = (size.width - w) / 2;
    final y = size.height * 0.80;
    const h = 14.0;
    final rect = Rect.fromLTWH(left, y, w, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));

    canvas.drawRRect(rr, Paint()..color = const Color(0xFF15131F));
    // "Sweet spot" zone near 100% (right edge).
    final sweet = Rect.fromLTWH(left + w * 0.85, y, w * 0.15, h);
    canvas.drawRect(sweet, Paint()..color = _kGood.withValues(alpha: 0.18));

    // Joint P(all targets) across active qubits.
    double joint = 1.0;
    for (var i = 0; i < n; i++) {
      joint *= target[i] ? _pUp(i) : (1 - _pUp(i));
    }
    final fillW = w * joint;
    if (fillW > 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, y, fillW, h), const Radius.circular(7)),
        Paint()
          ..color = Color.lerp(_kBad, _kGood, joint)!.withValues(alpha: 0.9),
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    GameFx.text(
      canvas,
      n == 2 ? 'JOINT AMPLITUDE — MEASURE NEAR 100%' : 'MEASURE NEAR 100%',
      Offset(size.width / 2, y - 14),
      10,
      Potatuhs.textFaint,
      weight: FontWeight.w700,
    );
  }

  // ── Bottom prompt ───────────────────────────────────────────────────────────
  void _paintMeasurePrompt(Canvas canvas, Size size) {
    final y = size.height * 0.92;
    if (!running) {
      GameFx.text(
        canvas,
        'Tap MEASURE when the wave favors the glowing state',
        Offset(size.width / 2, y),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
      );
      return;
    }
    final pulse = collapsed ? 0.4 : (0.7 + 0.3 * math.sin(idle * 4));
    GameFx.text(
      canvas,
      collapsed ? 'COLLAPSED' : 'TAP TO MEASURE',
      Offset(size.width / 2, y),
      16,
      (collapsed ? (lastAllFav == true ? _kGood : _kBad) : _kAccent)
          .withValues(alpha: pulse.clamp(0.0, 1.0)),
      display: true,
      weight: FontWeight.w900,
      glow: 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SuperpositionPainter old) => true;
}
