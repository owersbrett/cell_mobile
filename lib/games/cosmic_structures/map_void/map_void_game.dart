import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';

// ============================================================================
// MAP THE VOID — Classify the large-scale structure of the universe.
//
// A survey scope sweeps the sky and frames one region at a time. The player
// reads the local galaxy density and TAGS it as one of three forms of cosmic
// large-scale structure:
//   • CLUSTER  — a dense knot where galaxies pile up at a filament crossing.
//   • FILAMENT — a bridging thread of galaxies strung between clusters.
//   • VOID     — vast, near-empty space (the universe is MOSTLY this).
//
// Fast correct tags score more (a speed bonus decays over the decision window);
// consecutive correct tags build a streak multiplier. The teaching catch: most
// regions are VOID, so the instinct to tag everything as "structure" is the
// trap — you must hold back. The survey accelerates over the round (faster
// sweep, shorter decision window, subtler density contrast, more void decoys).
//
// The host owns the round clock, the score readout and the results screen; this
// widget renders ONLY the play area and reports through session.addScore /
// session.noteStreak. One Ticker drives a CustomPainter — no per-frame setState
// over a heavy widget tree.
// ============================================================================

const String _kFont = 'Outfit';

// -- Palette -----------------------------------------------------------------
const Color _kBg = Color(0xFF05060D); // deep intergalactic black
const Color _kVoidColor = Color(0xFF5C6B96); // cool slate — emptiness
const Color _kFilamentColor = Color(0xFF35C2C9); // teal — the bridging thread
const Color _kClusterColor = Color(0xFFFFB14E); // warm amber — the dense knot
const Color _kAccent = Color(0xFF7C5CFF); // cosmic violet (scope / brand)
const Color _kGold = Color(0xFFFFD54F); // streak flashes
const Color _kGood = Color(0xFF69F0AE); // correct
const Color _kBad = Color(0xFFFF5A5A); // wrong

// -- Tunables ----------------------------------------------------------------
/// Max points for an instant correct tag.
const int _kMaxPoints = 100;

/// Floor points for a correct tag made right before the window closes.
const int _kFloorPoints = 20;

/// Every N consecutive correct tags adds +1× to the streak multiplier.
const int _kStreakStep = 3;

/// Seconds the result flash (correct/wrong reveal) holds before the next sweep.
const double _kFeedbackDur = 0.34;

/// Seconds the survey takes to reach full difficulty.
const double _kRampSeconds = 42.0;

/// Decision window (seconds) at the start / at full difficulty.
const double _kWindowEasy = 2.6;
const double _kWindowHard = 1.05;

/// Scope sweep duration (seconds) at the start / at full difficulty.
const double _kSweepEasy = 0.46;
const double _kSweepHard = 0.22;

/// Particle bursts on a correct tag.
const int _kBurstCount = 16;

// ============================================================================
// Region model
// ============================================================================

enum _Form { cluster, filament, void_ }

extension _FormMeta on _Form {
  String get label {
    switch (this) {
      case _Form.cluster:
        return 'CLUSTER';
      case _Form.filament:
        return 'FILAMENT';
      case _Form.void_:
        return 'VOID';
    }
  }

  Color get color {
    switch (this) {
      case _Form.cluster:
        return _kClusterColor;
      case _Form.filament:
        return _kFilamentColor;
      case _Form.void_:
        return _kVoidColor;
    }
  }

  IconData get icon {
    switch (this) {
      case _Form.cluster:
        return Icons.blur_on_rounded;
      case _Form.filament:
        return Icons.timeline_rounded;
      case _Form.void_:
        return Icons.circle_outlined;
    }
  }
}

/// One galaxy in a region patch. [rel] is normalized to the scope radius
/// (a unit disc, with filaments allowed to reach to ~1.1 toward the edge).
class _Galaxy {
  final Offset rel;
  final double size;
  final double bright;
  const _Galaxy(this.rel, this.size, this.bright);
}

/// A generated survey patch: its true form + the galaxies you see inside it.
class _Region {
  final _Form form;
  final List<_Galaxy> galaxies;
  const _Region(this.form, this.galaxies);
}

// ============================================================================
// Lightweight particle (inlined — isolation over DRY, per EXTRACTION_RECIPE).
// ============================================================================

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

class MapVoidGame extends StatefulWidget {
  final MiniGameSession session;
  const MapVoidGame({super.key, required this.session});

  @override
  State<MapVoidGame> createState() => _MapVoidGameState();
}

enum _Phase { active, feedback, sweeping }

class _MapVoidGameState extends State<MapVoidGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0; // free-running, drives ambient drift
  double _runClock = 0; // accumulates only while playing, drives difficulty

  Size _field = Size.zero;

  // -- Survey state ----------------------------------------------------------
  _Phase _phase = _Phase.active;
  late _Region _region; // the patch under the scope right now

  Offset _scope = const Offset(0.5, 0.4); // normalized field position
  Offset _sweepFrom = const Offset(0.5, 0.4);
  Offset _sweepTo = const Offset(0.5, 0.4);
  double _sweepT = 1.0; // 0..1 progress of the current sweep

  double _decisionTimer = 0; // seconds the active patch has been visible
  double _feedbackTimer = 0; // counts down through the result flash

  // Result of the last tag (drives the flash).
  bool _lastCorrect = false;
  _Form? _revealed; // the true form, shown during feedback
  _Form? _picked; // what the player tagged (null on timeout)
  int _lastAward = 0;

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _shownMultiplier = 1;

  final List<_Particle> _particles = [];

  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _region = _generateRegion();
    _scope = _pickScopeTarget();
    _sweepFrom = _scope;
    _sweepTo = _scope;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // -- Difficulty ------------------------------------------------------------

  double get _difficulty => (_runClock / _kRampSeconds).clamp(0.0, 1.0);

  double _lerp(double a, double b) => a + (b - a) * _difficulty;

  double get _decisionWindow => _lerp(_kWindowEasy, _kWindowHard);
  double get _sweepDuration => _lerp(_kSweepEasy, _kSweepHard);

  // -- Region generation -----------------------------------------------------

  _Form _pickForm() {
    // Void-heavy by design — the universe is mostly empty, and the lesson is to
    // resist over-tagging structure. The void share grows a little with
    // difficulty as decoy galaxies make voids more tempting to misread.
    final voidShare = 0.54 + 0.06 * _difficulty;
    final filamentShare = 0.28 - 0.02 * _difficulty;
    final r = _rng.nextDouble();
    if (r < voidShare) return _Form.void_;
    if (r < voidShare + filamentShare) return _Form.filament;
    return _Form.cluster;
  }

  double _g() => (_rng.nextDouble() + _rng.nextDouble() - 1.0); // ~[-1,1] hump

  _Region _generateRegion() {
    final form = _pickForm();
    final d = _difficulty;
    final galaxies = <_Galaxy>[];

    switch (form) {
      case _Form.cluster:
        // A tight knot. Fewer, fainter members at high difficulty so a sparse
        // cluster and a busy filament/void become harder to tell apart.
        final count = (18 - 8 * d).round();
        final spread = 0.30 + 0.10 * d; // knot radius (subtler when tighter)
        for (var i = 0; i < count; i++) {
          final dx = _g() * spread;
          final dy = _g() * spread;
          galaxies.add(_Galaxy(
            Offset(dx, dy),
            1.6 + _rng.nextDouble() * 2.2,
            0.7 + 0.3 * _rng.nextDouble() - 0.18 * d,
          ));
        }
        break;

      case _Form.filament:
        // A thread crossing the scope at a random angle, with light scatter.
        final angle = _rng.nextDouble() * math.pi;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final perp = Offset(-dir.dy, dir.dx);
        final count = (13 - 5 * d).round();
        final jitter = 0.10 + 0.07 * d; // thread gets blurrier with difficulty
        for (var i = 0; i < count; i++) {
          final t = (_rng.nextDouble() * 2 - 1) * 1.05; // along the thread
          final off = _g() * jitter; // perpendicular scatter
          final p = dir * t + perp * off;
          galaxies.add(_Galaxy(
            p,
            1.3 + _rng.nextDouble() * 1.6,
            0.6 + 0.3 * _rng.nextDouble() - 0.15 * d,
          ));
        }
        break;

      case _Form.void_:
        // Near-empty. A few faint strays — and MORE of them at high difficulty
        // — to tempt the player into mis-tagging emptiness as structure.
        final count = (_rng.nextDouble() < 0.55 ? 0 : 1) + (3 * d).round();
        for (var i = 0; i < count; i++) {
          galaxies.add(_Galaxy(
            Offset(_g() * 0.9, _g() * 0.9),
            0.9 + _rng.nextDouble() * 1.1,
            0.30 + 0.25 * _rng.nextDouble(),
          ));
        }
        break;
    }
    return _Region(form, galaxies);
  }

  Offset _pickScopeTarget() {
    // Keep the scope in the upper play area, clear of the answer buttons.
    return Offset(
      0.20 + _rng.nextDouble() * 0.60,
      0.20 + _rng.nextDouble() * 0.42,
    );
  }

  // -- Game loop -------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      _runClock += dt;
      _simulate(dt);
    }
    _stepParticles(dt);
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    switch (_phase) {
      case _Phase.active:
        _decisionTimer += dt;
        if (_decisionTimer >= _decisionWindow) {
          _resolve(null); // ran out of time → a miss
        }
        break;
      case _Phase.feedback:
        _feedbackTimer -= dt;
        if (_feedbackTimer <= 0) _beginSweep();
        break;
      case _Phase.sweeping:
        _sweepT += dt / _sweepDuration;
        if (_sweepT >= 1.0) {
          _sweepT = 1.0;
          _scope = _sweepTo;
          _phase = _Phase.active;
          _decisionTimer = 0;
        } else {
          _scope = Offset.lerp(_sweepFrom, _sweepTo, _easeInOut(_sweepT))!;
        }
        break;
    }
  }

  void _stepParticles(double dt) {
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.10, dt).toDouble(); // drag
      return p.life <= 0;
    });
  }

  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

  // -- Scoring ---------------------------------------------------------------

  int _speedBonus() {
    final frac = (_decisionTimer / _decisionWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  void _onTag(_Form choice) {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.active) return;
    _resolve(choice);
  }

  void _resolve(_Form? choice) {
    final correct = choice != null && choice == _region.form;
    _picked = choice;
    _revealed = _region.form;
    _lastCorrect = correct;

    if (correct) {
      _streak++;
      final mult = _streakMultiplier();
      _shownMultiplier = mult;
      final award = _speedBonus() * mult;
      _lastAward = award;
      widget.session.addScore(award);
      widget.session.noteStreak(_streak);
      _burst(_scopeCenterPx(), _region.form.color);
      if (_streak % _kStreakStep == 0) {
        _burst(_scopeCenterPx(), _kGold, count: 10);
      }
    } else {
      _streak = 0;
      _shownMultiplier = 1;
      _lastAward = 0;
    }

    _phase = _Phase.feedback;
    _feedbackTimer = _kFeedbackDur;
  }

  void _beginSweep() {
    _region = _generateRegion();
    _sweepFrom = _scope;
    _sweepTo = _pickScopeTarget();
    _sweepT = 0;
    _revealed = null;
    _picked = null;
    _phase = _Phase.sweeping;
  }

  // -- Particles -------------------------------------------------------------

  Offset _scopeCenterPx() =>
      Offset(_scope.dx * _field.width, _scope.dy * _field.height);

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 50.0 + _rng.nextDouble() * 150.0;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.4 + _rng.nextDouble() * 2.6,
        color.withValues(alpha: 0.7 + 0.3 * _rng.nextDouble()),
      ));
    }
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      final scopeR = math.min(_field.width, _field.height) * 0.22;
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SkyPainter(
                    clock: _clock,
                    field: _field,
                    scope: _scope,
                    scopeR: scopeR,
                    phase: _phase,
                    region: _region,
                    sweepT: _sweepT,
                    decisionFrac:
                        (_decisionTimer / _decisionWindow).clamp(0.0, 1.0),
                    running: widget.session.isRunning,
                    lastCorrect: _lastCorrect,
                    revealed: _revealed,
                    particles: _particles,
                  ),
                ),
              ),
            ),
            // Streak multiplier badge (gameplay feedback — not the score/timer,
            // which the host owns).
            if (_streak >= _kStreakStep)
              Positioned(
                top: 10,
                left: 12,
                child: _streakBadge(),
              ),
            // The result banner floats above the buttons during feedback.
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _phase == _Phase.feedback ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: _resultBanner(),
                ),
              ),
            ),
            // The three classify buttons.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _buttonRow(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _streakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.7)),
      ),
      child: Text(
        '×$_shownMultiplier  •  $_streak streak',
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kGold,
        ),
      ),
    );
  }

  Widget _resultBanner() {
    final revealed = _revealed;
    if (revealed == null) return const SizedBox(height: 30);
    final color = _lastCorrect ? _kGood : _kBad;
    final text = _lastCorrect
        ? (_shownMultiplier > 1
            ? '+$_lastAward   ×$_shownMultiplier'
            : '+$_lastAward')
        : (_picked == null
            ? 'TOO SLOW — it was ${revealed.label}'
            : 'NOPE — it was ${revealed.label}');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buttonRow() {
    final answered = _phase != _Phase.active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          _tagButton(_Form.void_, answered),
          const SizedBox(width: 8),
          _tagButton(_Form.filament, answered),
          const SizedBox(width: 8),
          _tagButton(_Form.cluster, answered),
        ],
      ),
    );
  }

  Widget _tagButton(_Form form, bool answered) {
    // During feedback, light the correct answer green and a wrong pick red.
    Color border = form.color.withValues(alpha: 0.85);
    Color fill = form.color.withValues(alpha: 0.12);
    Color fg = form.color;
    if (answered && _revealed != null) {
      if (form == _revealed) {
        border = _kGood;
        fill = _kGood.withValues(alpha: 0.16);
        fg = _kGood;
      } else if (form == _picked && !_lastCorrect) {
        border = _kBad;
        fill = _kBad.withValues(alpha: 0.14);
        fg = _kBad;
      } else {
        border = form.color.withValues(alpha: 0.30);
        fill = form.color.withValues(alpha: 0.05);
        fg = form.color.withValues(alpha: 0.55);
      }
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTag(form),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          height: 70,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(form.icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(
                form.label,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Painter — the survey field, the scope, the galaxies and the bursts.
// ============================================================================

class _SkyPainter extends CustomPainter {
  final double clock;
  final Size field;
  final Offset scope; // normalized
  final double scopeR;
  final _Phase phase;
  final _Region region;
  final double sweepT;
  final double decisionFrac;
  final bool running;
  final bool lastCorrect;
  final _Form? revealed;
  final List<_Particle> particles;

  const _SkyPainter({
    required this.clock,
    required this.field,
    required this.scope,
    required this.scopeR,
    required this.phase,
    required this.region,
    required this.sweepT,
    required this.decisionFrac,
    required this.running,
    required this.lastCorrect,
    required this.revealed,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final scopePx = Offset(scope.dx * size.width, scope.dy * size.height);

    // The patch under the scope. While sweeping to a new region it fades in as
    // the scope arrives; otherwise it's fully lit.
    final fade = phase == _Phase.sweeping ? sweepT : 1.0;
    _paintPatch(canvas, region, scopePx, fade);

    _paintScope(canvas, scopePx);
    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // A faint, deterministic cosmic-web backdrop: dim node dots so the field
    // never looks dead, drawn statically (no shimmer on repaint).
    final webPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 70; i++) {
      final fx = (i * 73 % 101) / 101.0;
      final fy = (i * 49 % 89) / 89.0;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        0.6 + (i % 3) * 0.3,
        webPaint,
      );
    }

    // A slow ambient violet glow gives the survey depth.
    final t = clock * 0.18;
    final gx = size.width * (0.5 + 0.12 * math.cos(t));
    final gy = size.height * (0.32 + 0.08 * math.sin(t * 0.8));
    canvas.drawCircle(
      Offset(gx, gy),
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.07),
            _kAccent.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(gx, gy), radius: size.width * 0.55)),
    );
  }

  void _paintPatch(Canvas canvas, _Region r, Offset center, double fade) {
    if (fade <= 0) return;
    final color = r.form.color;
    for (final g in r.galaxies) {
      final p = center + g.rel * scopeR;
      final a = (g.bright * fade).clamp(0.0, 1.0);
      // Soft halo.
      canvas.drawCircle(
        p,
        g.size * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.10 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core.
      canvas.drawCircle(
        p,
        g.size,
        Paint()..color = Color.lerp(color, Colors.white, 0.4)!.withValues(alpha: a),
      );
    }
  }

  void _paintScope(Canvas canvas, Offset center) {
    // Feedback tints the reticle; otherwise it's the brand violet.
    Color ring = _kAccent;
    if (phase == _Phase.feedback && revealed != null) {
      ring = lastCorrect ? _kGood : _kBad;
    }

    // Outer reticle.
    canvas.drawCircle(
      center,
      scopeR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = ring.withValues(alpha: 0.85),
    );
    // Inner faint disc to lift the patch off the background.
    canvas.drawCircle(
      center,
      scopeR,
      Paint()..color = ring.withValues(alpha: 0.05),
    );

    // Crosshair ticks.
    final tick = Paint()
      ..color = ring.withValues(alpha: 0.6)
      ..strokeWidth = 1.6;
    for (final a in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (scopeR - 7),
        center + dir * (scopeR + 7),
        tick,
      );
    }

    // Decision-urgency arc: a depleting ring while the patch is active.
    if (phase == _Phase.active && running) {
      final remaining = 1.0 - decisionFrac;
      final urgent = decisionFrac > 0.7;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: scopeR + 4),
        -math.pi / 2,
        -2 * math.pi * remaining,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = (urgent ? _kBad : _kAccent)
              .withValues(alpha: 0.55 + 0.35 * remaining),
      );
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * a,
        Paint()..color = p.color.withValues(alpha: p.color.a * a),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}
