import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Powerhouse ═══════════════════════════════════════════════════════════
/// Run a MITOCHONDRION making ATP through the three real stages of cellular
/// respiration — and each stage is its OWN mechanic, not the same tap:
///
///   1. GLYCOLYSIS  (cytoplasm)      — CLEAVE. A 6-carbon glucose slides across
///      a cutting line; tap when it's centred to split it into two 3-carbon
///      pyruvates. Precision timing.
///   2. KREBS       (matrix)         — CYCLE. A marker sweeps a rotating ring;
///      tap it through each lit release GATE (CO₂ out, NADH captured) in one
///      loop. Rhythm on a turning wheel.
///   3. ELECTRON TRANSPORT (cristae) — PUMP + RELEASE. Alternate-tap two proton
///      pumps to build the H⁺ gradient, then release the ATP-synthase rotor in
///      the green zone. Flow + a timed climax.
///
/// The three phases loop; every completed loop is one respiration cycle. The
/// game speeds up and tightens every window as the run goes on, so a perfect
/// run becomes humanly impossible. Score = ATP minted.
///
/// Rendering follows the project perf rule: ONE ticker drives ONE CustomPainter;
/// game state mutates every frame WITHOUT setState (the canvas repaints off the
/// ticker); the widget tree (banner, quit-safe host) rebuilds at ~15fps.
/// Particles are capped.

// ── Education: one fact surfaced per phase, in-context ───────────────────────
const Map<_Phase, List<String>> _kPhaseFacts = {
  _Phase.glycolysis: [
    'GLYCOLYSIS: one 6-carbon glucose is split into two 3-carbon pyruvate — in the cytoplasm, no oxygen needed.',
    'Glycolysis nets 2 ATP and 2 NADH up front, before the mitochondrion even starts.',
    'The cut you time IS the split: glucose (C₆) → 2 × pyruvate (C₃).',
  ],
  _Phase.krebs: [
    'KREBS / CITRIC ACID CYCLE: a turning loop in the matrix that strips carbons off as CO₂.',
    'Each turn of the cycle releases CO₂ and loads electron carriers — NADH and FADH₂.',
    'The gates you hit are where CO₂ leaves and NADH is captured, once per turn.',
  ],
  _Phase.etc: [
    'ELECTRON TRANSPORT: pumps push H⁺ across the inner membrane, building a gradient.',
    'ATP synthase is a real molecular rotor — the proton flow spins it to mint ATP.',
    'This chain needs OXYGEN as the final electron acceptor; it makes most of the ATP.',
  ],
};

enum _Phase { glycolysis, krebs, etc }

/// A tiny cache of laid-out [TextPainter]s keyed by (string,size,color,weight).
/// The old code built a fresh `TextPainter` + `.layout()` for every HUD label on
/// EVERY frame (~8 per frame at 60fps) — that allocation + shaping churn was the
/// main source of the stutter. This caches each glyph run and only re-lays-out
/// when the text/style actually changes.
class _TextCache {
  final Map<String, TextPainter> _cache = {};

  TextPainter get(String s, double size, Color color,
      {bool display = false, FontWeight weight = FontWeight.w700, double glow = 0}) {
    final key = '$s|$size|${color.toARGB32()}|${display ? 1 : 0}|${weight.value}|$glow';
    final existing = _cache[key];
    if (existing != null) return existing;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: display ? Potatuhs.displayFont : Potatuhs.bodyFont,
          fontSize: size,
          fontWeight: weight,
          color: color,
          shadows: glow > 0
              ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 12)]
              : null,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    // Cap the cache so an animating alpha string (rare) can't grow it forever.
    if (_cache.length > 48) _cache.clear();
    _cache[key] = tp;
    return tp;
  }

  /// Draw a cached, centered text run.
  void draw(Canvas canvas, String s, Offset center, double size, Color color,
      {bool display = false, FontWeight weight = FontWeight.w700, double glow = 0}) {
    final tp = get(s, size, color, display: display, weight: weight, glow: glow);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}

/// A floating score/label pop, glyph laid out ONCE at spawn.
class _Pop {
  double x, y;
  double life = 1.0;
  final TextPainter tp;
  _Pop({required this.x, required this.y, required String label, required Color color})
      : tp = (TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout());
}

class PowerhouseGame extends StatefulWidget {
  final MiniGameSession session;
  const PowerhouseGame({super.key, required this.session});

  @override
  State<PowerhouseGame> createState() => _PowerhouseGameState();
}

class _PowerhouseGameState extends State<PowerhouseGame>
    with SingleTickerProviderStateMixin {
  // ── Tunables ────────────────────────────────────────────────────────────
  static const int _maxParticles = 60;
  static const int _maxPops = 5;

  // The "rush to gather ATP" framing: a visible target the player races toward.
  // Purely motivational — the run still ends on the host clock; hitting the goal
  // just fills the ATP bar and pays a one-time "GOAL!" flourish.
  static const int _atpGoal = 120;
  bool _goalHit = false;

  // Glycolysis: glucose slides left↔right; you cleave it near centre.
  static const double _glySlideStart = 0.9; // half-sweeps/sec at t=0
  static const double _glySlideEnd = 2.4; //   at run end
  static const double _glyWindowStart = 0.20; // |offset| accepted, t=0
  static const double _glyWindowEnd = 0.075; //  at run end

  // Krebs: marker sweeps a ring; hit each gate as it passes.
  static const double _krebsSpinStart = 1.05; // turns/sec at t=0
  static const double _krebsSpinEnd = 2.6; //    at run end
  static const int _krebsGatesStart = 3; // gates per loop, t=0
  static const int _krebsGatesEnd = 5; //   at run end
  static const double _krebsHitArc = 0.34; // radians of hit tolerance (shrinks)

  // ETC: build gradient by alternating pumps, then release rotor in green zone.
  static const int _etcPumpsNeeded = 6; // alternating taps to charge
  static const double _etcRotorStart = 1.1; // rotor turns/sec at t=0
  static const double _etcRotorEnd = 2.9; //   at run end
  static const double _etcZoneStart = 0.9; // green-zone radians, t=0
  static const double _etcZoneEnd = 0.42; //   at run end
  static const double _etcLeakStart = 0.12; // gradient decay/sec (rises)
  static const double _etcLeakEnd = 0.5;

  // ── Runtime ───────────────────────────────────────────────────────────────
  late final AnimationController _ticker;
  final math.Random _rng = math.Random();

  double _clock = 0;
  double _lastT = 0;
  double _runElapsed = 0;
  bool _wasRunning = false;

  _Phase _phase = _Phase.glycolysis;
  int _cycles = 0; // completed full respiration loops
  double _pulse = 0; // decaying success flash
  double _shake = 0; // decaying fail shake

  // Glycolysis state
  double _glyPos = 0; // -1..1, cut target at 0
  int _glyDir = 1;
  bool _glyDone = false;
  double _glyBonus = 0; // 0..1 precision of the last cut (for scoring feedback)

  // Krebs state
  double _krebsAngle = 0; // marker angle (radians)
  late List<double> _krebsGateAngles;
  late List<bool> _krebsGateHit;
  int _krebsGates = _krebsGatesStart;

  // ETC state
  int _etcCharge = 0; // 0.._etcPumpsNeeded
  int _etcNextPump = 0; // which pump must be tapped next (0 = left, 1 = right)
  bool _etcReleasing = false; // gradient charged → rotor spinning, awaiting release
  double _etcRotor = 0; // rotor angle
  double _etcGradient = 0; // 0..1 (leaks while releasing)

  String _flashMsg = '';
  double _flashTimer = 0;

  String _currentFact = '';

  final List<FxParticle> _fx = [];
  final List<_Pop> _pops = [];
  final _TextCache _textCache = _TextCache();

  // Geometry cached from painter layout for hit-testing.
  Offset _center = Offset.zero;
  double _radius = 80;

  double _uiAccum = 0;

  @override
  void initState() {
    super.initState();
    _resetRun();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_update);
    _ticker.forward();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  double _ramp() {
    final dur = widget.session.spec.durationSeconds;
    return dur <= 0 ? 0.0 : (_runElapsed / dur).clamp(0.0, 1.0);
  }

  double _lerpRamp(double a, double b) => a + (b - a) * _ramp();

  void _resetRun() {
    _phase = _Phase.glycolysis;
    _cycles = 0;
    _pulse = 0;
    _shake = 0;
    _runElapsed = 0;
    _glyPos = -1;
    _glyDir = 1;
    _glyDone = false;
    _glyBonus = 0;
    _krebsAngle = 0;
    _krebsGates = _krebsGatesStart;
    _seedKrebsGates();
    _etcCharge = 0;
    _etcNextPump = 0;
    _etcReleasing = false;
    _etcRotor = 0;
    _etcGradient = 0;
    _flashMsg = '';
    _flashTimer = 0;
    _goalHit = false;
    _fx.clear();
    _pops.clear();
    _setFact();
  }

  void _seedKrebsGates() {
    _krebsGates = _lerpRamp(
            _krebsGatesStart.toDouble(), _krebsGatesEnd.toDouble())
        .round()
        .clamp(_krebsGatesStart, _krebsGatesEnd);
    _krebsGateAngles = List<double>.generate(
        _krebsGates, (i) => (i / _krebsGates) * 2 * math.pi);
    // small per-loop jitter so it never memorises to a fixed rhythm
    for (int i = 0; i < _krebsGates; i++) {
      _krebsGateAngles[i] += (_rng.nextDouble() - 0.5) * 0.25;
    }
    _krebsGateHit = List<bool>.filled(_krebsGates, false);
    _krebsAngle = -math.pi / 2; // start at top
  }

  void _setFact() {
    final pool = _kPhaseFacts[_phase]!;
    _currentFact = pool[_rng.nextInt(pool.length)];
  }

  void _flash(String msg) {
    _flashMsg = msg;
    _flashTimer = 1.0;
  }

  // ── Frame update ────────────────────────────────────────────────────────
  void _update() {
    final now = (_ticker.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = (_lastT == 0 ? 0.016 : (now - _lastT)).clamp(0.0, 0.05);
    _lastT = now;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    if (_pulse > 0) _pulse = (_pulse - dt * 2).clamp(0.0, 1.0);
    if (_shake > 0) _shake = (_shake - dt * 3).clamp(0.0, 1.0);
    if (_flashTimer > 0) _flashTimer = (_flashTimer - dt).clamp(0.0, 99.0);

    _fx.removeWhere((p) => !p.step(dt));
    for (final p in _pops) {
      p.y -= 70 * dt;
      p.life -= dt * 0.9;
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (running) {
      _runElapsed += dt;
      _advancePhase(dt);
    }

    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      if (mounted) setState(() {});
    }
  }

  /// Continuous, per-phase motion (all on the ticker, not widget rebuilds).
  void _advancePhase(double dt) {
    switch (_phase) {
      case _Phase.glycolysis:
        final speed = _lerpRamp(_glySlideStart, _glySlideEnd);
        _glyPos += _glyDir * speed * 2 * dt;
        if (_glyPos >= 1) {
          _glyPos = 1;
          _glyDir = -1;
        } else if (_glyPos <= -1) {
          _glyPos = -1;
          _glyDir = 1;
        }
        break;
      case _Phase.krebs:
        final spin = _lerpRamp(_krebsSpinStart, _krebsSpinEnd);
        _krebsAngle += spin * 2 * math.pi * dt;
        if (_krebsAngle > math.pi) _krebsAngle -= 2 * math.pi;
        break;
      case _Phase.etc:
        if (_etcReleasing) {
          final spin = _lerpRamp(_etcRotorStart, _etcRotorEnd);
          _etcRotor += spin * 2 * math.pi * dt;
          if (_etcRotor > math.pi) _etcRotor -= 2 * math.pi;
          // Gradient leaks while you wait for the release moment.
          final leak = _lerpRamp(_etcLeakStart, _etcLeakEnd);
          _etcGradient = (_etcGradient - leak * dt).clamp(0.0, 1.0);
          if (_etcGradient <= 0) {
            // Lost the gradient — fell back to charging (a soft failure).
            _etcReleasing = false;
            _etcCharge = 0;
            _shake = 1.0;
            _flash('GRADIENT LOST');
          }
        }
        break;
    }
  }

  // ── Input — one gesture handler, routed by phase ──────────────────────────
  void _onTap(Offset local) {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.glycolysis:
        _glyTap();
        break;
      case _Phase.krebs:
        _krebsTap();
        break;
      case _Phase.etc:
        _etcTap(local);
        break;
    }
    setState(() {}); // immediate tactile feedback
  }

  // GLYCOLYSIS: cleave when the glucose is centred.
  void _glyTap() {
    if (_glyDone) return;
    final window = _lerpRamp(_glyWindowStart, _glyWindowEnd);
    final err = _glyPos.abs();
    if (err <= window) {
      _glyBonus = (1 - err / window).clamp(0.0, 1.0);
      _glyDone = true;
      _pulse = 1.0;
      final int atp = 2 + (_glyBonus * 2).round(); // 2..4 (NADH bonus)
      _award(atp, _center, Potatuhs.gold, '+$atp glycolysis');
      _fx.addAll(FxBurst.spawn(_center, const Color(0xFF66BB6A),
          count: 12, speed: 130, size: 3));
      _trim();
      widget.session.noteStreak(_cycles * 3 + 1);
      // Move to Krebs after a brief beat handled in the tap flow.
      _phase = _Phase.krebs;
      _seedKrebsGates();
      _setFact();
    } else {
      _shake = 1.0;
      _flash('OFF-CENTRE');
    }
  }

  // KREBS: hit the marker through each lit gate as it sweeps.
  void _krebsTap() {
    final arc = _lerpRamp(_krebsHitArc, _krebsHitArc * 0.6);
    int hitIdx = -1;
    double best = arc;
    for (int i = 0; i < _krebsGates; i++) {
      if (_krebsGateHit[i]) continue;
      final d = _angDist(_krebsAngle, _krebsGateAngles[i]);
      if (d < best) {
        best = d;
        hitIdx = i;
      }
    }
    if (hitIdx >= 0) {
      _krebsGateHit[hitIdx] = true;
      _pulse = 1.0;
      final gp = _gatePoint(hitIdx);
      _award(3, gp, const Color(0xFF7E57C2), '+3 CO₂/NADH');
      _fx.addAll(FxBurst.spawn(gp, const Color(0xFFB39DDB),
          count: 8, speed: 110, size: 2.6));
      _trim();
      if (_krebsGateHit.every((h) => h)) {
        // Full turn complete → electron transport.
        _phase = _Phase.etc;
        _etcCharge = 0;
        _etcNextPump = 0;
        _etcReleasing = false;
        _etcRotor = -math.pi / 2;
        _etcGradient = 0;
        _setFact();
      }
    } else {
      _shake = 1.0;
      _flash('MISSED GATE');
    }
  }

  // ETC: alternate the two pumps to charge, then release the rotor.
  void _etcTap(Offset local) {
    if (!_etcReleasing) {
      // Charging phase: left half = pump 0, right half = pump 1. Must alternate.
      final side = local.dx < _center.dx ? 0 : 1;
      if (side == _etcNextPump) {
        _etcCharge = (_etcCharge + 1).clamp(0, _etcPumpsNeeded);
        _etcNextPump = 1 - _etcNextPump;
        _pulse = 0.5;
        final px = Offset(_center.dx + (side == 0 ? -_radius : _radius) * 0.9,
            _center.dy);
        _fx.addAll(FxBurst.spawn(px, const Color(0xFF42A5F5),
            count: 4, speed: 70, size: 2));
        _trim();
        if (_etcCharge >= _etcPumpsNeeded) {
          _etcReleasing = true;
          _etcGradient = 1.0;
        }
      } else {
        // Tapped the wrong pump — no progress, tiny nudge.
        _shake = 0.5;
        _flash('ALTERNATE PUMPS');
      }
    } else {
      // Release phase: rotor must be in the green zone (top).
      final zone = _lerpRamp(_etcZoneStart, _etcZoneEnd);
      final d = _angDist(_etcRotor, -math.pi / 2);
      if (d <= zone / 2) {
        final prec = (1 - d / (zone / 2)).clamp(0.0, 1.0);
        // ATP scaled by how full the gradient still is AND rotor precision.
        final int atp =
            (12 + (12 * _etcGradient) + (8 * prec)).round(); // ~12..32
        _pulse = 1.0;
        _award(atp, _center, Potatuhs.gold, '+$atp ATP');
        _fx.addAll(FxBurst.spawn(_center, Potatuhs.gold,
            count: 20, speed: 170, size: 3.6));
        _trim();
        // FULL respiration cycle done.
        _cycles++;
        widget.session.noteStreak(_cycles * 3);
        _phase = _Phase.glycolysis;
        _glyPos = -1;
        _glyDir = 1;
        _glyDone = false;
        _glyBonus = 0;
        _setFact();
      } else {
        _shake = 1.0;
        _flash('ROTOR OUT OF ZONE');
      }
    }
  }

  void _award(int atp, Offset at, Color c, String label) {
    widget.session.addScore(atp);
    _pops.add(_Pop(x: at.dx, y: at.dy - _radius - 8, label: label, color: c));
    if (_pops.length > _maxPops) _pops.removeRange(0, _pops.length - _maxPops);
    // One-time flourish when the visible ATP goal is reached — reinforces the
    // "rush to gather ATP" framing without ending or gating the run.
    if (!_goalHit && widget.session.score >= _atpGoal) {
      _goalHit = true;
      _pulse = 1.0;
      _flash('ATP GOAL! keep stacking');
      _fx.addAll(FxBurst.spawn(_center, Potatuhs.gold,
          count: 24, speed: 190, size: 3.8));
      _trim();
    }
  }

  void _trim() {
    if (_fx.length > _maxParticles) {
      _fx.removeRange(0, _fx.length - _maxParticles);
    }
  }

  double _angDist(double a, double b) {
    double d = (a - b).abs() % (2 * math.pi);
    if (d > math.pi) d = 2 * math.pi - d;
    return d;
  }

  Offset _gatePoint(int i) {
    final ang = _krebsGateAngles[i];
    return Offset(_center.dx + math.cos(ang) * _radius,
        _center.dy + math.sin(ang) * _radius);
  }

  void _onGeometry(Offset center, double radius) {
    _center = center;
    _radius = radius;
  }

  // ── ATTRACT autopilot — plays competently, phase-aware ────────────────────
  void _autoStep() {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.glycolysis:
        // Cut when near centre.
        if (!_glyDone && _glyPos.abs() < 0.08) _onTap(_center);
        break;
      case _Phase.krebs:
        // Fire when the marker is close to any un-hit gate.
        for (int i = 0; i < _krebsGates; i++) {
          if (_krebsGateHit[i]) continue;
          if (_angDist(_krebsAngle, _krebsGateAngles[i]) < 0.12) {
            _onTap(_center);
            break;
          }
        }
        break;
      case _Phase.etc:
        if (!_etcReleasing) {
          // Tap the correct alternating pump side.
          final x = _etcNextPump == 0 ? _center.dx - _radius : _center.dx + _radius;
          _onTap(Offset(x, _center.dy));
        } else if (_angDist(_etcRotor, -math.pi / 2) < 0.12) {
          _onTap(_center);
        }
        break;
    }
  }

  // ── UI text helpers ───────────────────────────────────────────────────────
  String get _phaseName {
    switch (_phase) {
      case _Phase.glycolysis:
        return 'GLYCOLYSIS';
      case _Phase.krebs:
        return 'KREBS CYCLE';
      case _Phase.etc:
        return 'ELECTRON TRANSPORT';
    }
  }

  /// The always-visible "what do I DO right now" line. Updates as the phase
  /// (and the ETC sub-state) changes so the player is never guessing.
  String get _phaseVerb {
    switch (_phase) {
      case _Phase.glycolysis:
        return 'TAP when the green glucose is on the CENTER line';
      case _Phase.krebs:
        return 'TAP as the white marker crosses each lit GATE';
      case _Phase.etc:
        return _etcReleasing
            ? 'TAP when the spinning blade is in the GREEN zone'
            : 'TAP LEFT then RIGHT — alternate the two pumps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.session.spec;
    final running = widget.session.isRunning;
    return Container(
      color: Potatuhs.inkDeep,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _onTap(d.localPosition),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PowerhousePainter(
                    repaint: _ticker,
                    clock: _clock,
                    accent: spec.accent,
                    phase: _phase,
                    running: running,
                    ramp: _ramp(),
                    pulse: _pulse,
                    shake: _shake,
                    glyPos: _glyPos,
                    glyWindow: _lerpRamp(_glyWindowStart, _glyWindowEnd),
                    glyDone: _glyDone,
                    krebsAngle: _krebsAngle,
                    krebsGates: _krebsGateAngles,
                    krebsHit: _krebsGateHit,
                    etcCharge: _etcCharge,
                    etcPumpsNeeded: _etcPumpsNeeded,
                    etcNextPump: _etcNextPump,
                    etcReleasing: _etcReleasing,
                    etcRotor: _etcRotor,
                    etcGradient: _etcGradient,
                    etcZone: _lerpRamp(_etcZoneStart, _etcZoneEnd),
                    cycles: _cycles,
                    phaseName: _phaseName,
                    phaseVerb: _phaseVerb,
                    atp: widget.session.score,
                    atpGoal: _atpGoal,
                    flashMsg: _flashTimer > 0 ? _flashMsg : '',
                    flashAlpha: _flashTimer.clamp(0.0, 1.0),
                    fx: _fx,
                    pops: _pops,
                    onGeometry: _onGeometry,
                    textCache: _textCache,
                  ),
                ),
              ),
            ),
          ),

          // ── Fact banner (the educational payload — non-moving, cheap) ──────
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Potatuhs.inkPanel.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: spec.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  _currentFact,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                      size: 11, color: Potatuhs.textSecondary, height: 1.3),
                ),
              ),
            ),
          ),

          if (!running)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    'RUSH TO STACK ATP — three moves:\n'
                    '1  SPLIT the glucose on the centre line\n'
                    '2  TAP the marker through each Krebs gate\n'
                    '3  PUMP L/R, then RELEASE the rotor in the green',
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(
                        size: 13, color: Potatuhs.textFaint, height: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
class _PowerhousePainter extends CustomPainter {
  final double clock;
  final Color accent;
  final _Phase phase;
  final bool running;
  final double ramp, pulse, shake;
  final double glyPos, glyWindow;
  final bool glyDone;
  final double krebsAngle;
  final List<double> krebsGates;
  final List<bool> krebsHit;
  final int etcCharge, etcPumpsNeeded, etcNextPump;
  final bool etcReleasing;
  final double etcRotor, etcGradient, etcZone;
  final int cycles;
  final String phaseName, phaseVerb, flashMsg;
  final int atp, atpGoal;
  final double flashAlpha;
  final List<FxParticle> fx;
  final List<_Pop> pops;
  final void Function(Offset center, double radius) onGeometry;
  final _TextCache textCache;

  _PowerhousePainter({
    required Listenable repaint,
    required this.clock,
    required this.accent,
    required this.phase,
    required this.running,
    required this.ramp,
    required this.pulse,
    required this.shake,
    required this.glyPos,
    required this.glyWindow,
    required this.glyDone,
    required this.krebsAngle,
    required this.krebsGates,
    required this.krebsHit,
    required this.etcCharge,
    required this.etcPumpsNeeded,
    required this.etcNextPump,
    required this.etcReleasing,
    required this.etcRotor,
    required this.etcGradient,
    required this.etcZone,
    required this.cycles,
    required this.phaseName,
    required this.phaseVerb,
    required this.atp,
    required this.atpGoal,
    required this.flashMsg,
    required this.flashAlpha,
    required this.fx,
    required this.pops,
    required this.onGeometry,
    required this.textCache,
  }) : super(repaint: repaint);

  static const Color _glucose = Color(0xFF66BB6A);
  static const Color _oxygen = Color(0xFF42A5F5);
  static const Color _krebsC = Color(0xFF7E57C2);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;

    GameFx.atmosphere(canvas, size, accent, clock, motes: 24);

    // Screen shake on failure.
    if (shake > 0) {
      final s = shake * 6;
      canvas.save();
      canvas.translate(
          math.sin(clock * 60) * s, math.cos(clock * 55) * s * 0.6);
    }

    final double fieldBottom = h - 92; // clear of banner
    final double cy = (fieldBottom * 0.42).clamp(120.0, math.max(120.0, fieldBottom - 90));
    final double radius =
        (math.min(w, fieldBottom) * 0.30).clamp(60.0, 150.0);
    final center = Offset(w / 2, cy);
    onGeometry(center, radius);

    // The mitochondrion housing is always present; the active stage draws inside.
    _drawMitoHousing(canvas, center, radius);

    switch (phase) {
      case _Phase.glycolysis:
        _drawGlycolysis(canvas, center, radius);
        break;
      case _Phase.krebs:
        _drawKrebs(canvas, center, radius);
        break;
      case _Phase.etc:
        _drawEtc(canvas, center, radius);
        break;
    }

    // ── ATP counter + goal bar (the "rush to gather ATP" framing) ──────────
    _drawAtpGoal(canvas, w);

    // ── Phase HUD (name + always-visible instruction line) ─────────────────
    if (running) {
      textCache.draw(canvas, phaseName, Offset(center.dx, 46), 20,
          Color.lerp(accent, Colors.white, 0.4)!,
          display: true, weight: FontWeight.w800, glow: 0.4);
      // A pill behind the instruction so it always reads over the play field.
      final tp = textCache.get(
          phaseVerb, 12.5, Potatuhs.textPrimary, weight: FontWeight.w800);
      final pill = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(center.dx, 74),
              width: tp.width + 22,
              height: tp.height + 10),
          const Radius.circular(9));
      canvas.drawRRect(
          pill, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.82));
      canvas.drawRRect(
          pill,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = accent.withValues(alpha: 0.5));
      tp.paint(canvas, Offset(center.dx - tp.width / 2, 74 - tp.height / 2));

      textCache.draw(
          canvas,
          'CYCLE ${cycles + 1}  ·  STAGE ${_stageNum()}/3',
          Offset(center.dx, 96),
          10,
          Potatuhs.textFaint,
          weight: FontWeight.w700);
    }

    // ── Particles + pops ───────────────────────────────────────────────────
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      if (!p.x.isFinite || !p.y.isFinite) continue;
      final a = p.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      final off = Offset(p.x - p.tp.width / 2, p.y);
      if (a >= 0.98) {
        p.tp.paint(canvas, off);
      } else {
        canvas.saveLayer(off & p.tp.size, Paint()..color = Color.fromRGBO(0, 0, 0, a));
        p.tp.paint(canvas, off);
        canvas.restore();
      }
    }

    if (flashMsg.isNotEmpty && flashAlpha > 0) {
      // Alpha animates, so this one intentionally does not cache (the cache
      // would fill with per-alpha keys); it's a single call, only while flashing.
      GameFx.text(canvas, flashMsg, Offset(center.dx, center.dy - radius - 40),
          14, const Color(0xFFFF7043).withValues(alpha: flashAlpha),
          weight: FontWeight.w800, glow: 0.5 * flashAlpha);
    }

    if (shake > 0) canvas.restore();
  }

  int _stageNum() => phase == _Phase.glycolysis
      ? 1
      : phase == _Phase.krebs
          ? 2
          : 3;

  // Big top-right ATP tally + a filling goal bar — the player should feel they
  // are racing to STACK ATP. Drawn on the canvas (no widget rebuild cost).
  void _drawAtpGoal(Canvas canvas, double w) {
    final frac = atpGoal <= 0 ? 0.0 : (atp / atpGoal).clamp(0.0, 1.0);
    final full = atp >= atpGoal;
    // "ATP" label + big number, top-right.
    textCache.draw(canvas, 'ATP', Offset(w - 58, 30), 12,
        Potatuhs.textFaint, weight: FontWeight.w800);
    textCache.draw(canvas, '$atp', Offset(w - 58, 52), 26,
        full ? Potatuhs.gold : Potatuhs.textPrimary,
        display: true, weight: FontWeight.w800, glow: full ? 0.6 : 0.0);
    // Goal bar under it.
    const barY = 72.0;
    const barW = 88.0;
    final barX = w - 58 - barW / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW * frac, 6), const Radius.circular(3)),
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.95));
    textCache.draw(canvas, full ? 'GOAL!' : 'goal $atpGoal',
        Offset(w - 58, barY + 14), 9,
        full ? Potatuhs.gold : Potatuhs.textFaint, weight: FontWeight.w700);
  }

  // The double-membrane mitochondrion, drawn as the stage housing.
  void _drawMitoHousing(Canvas canvas, Offset center, double r) {
    final glow = 0.12 + 0.35 * pulse;
    canvas.drawCircle(
        center,
        r + 20,
        Paint()
          ..color = accent.withValues(alpha: glow.clamp(0.0, 0.6))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    final bodyRect = Rect.fromCircle(center: center, radius: r + 8);
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(accent, Colors.white, 0.22)!,
            Color.lerp(accent, Colors.black, 0.30)!,
            Color.lerp(accent, Colors.black, 0.62)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(bodyRect),
    );
    // Inner membrane ring.
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Color.lerp(accent, Colors.black, 0.35)!
              .withValues(alpha: 0.7));
    // Dark matrix interior so the stage art reads.
    canvas.drawCircle(center, r - 2,
        Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.55));
  }

  // ── GLYCOLYSIS — split the sliding glucose at the cut line ────────────────
  void _drawGlycolysis(Canvas canvas, Offset center, double r) {
    final trackHalf = r * 0.78;
    final y = center.dy;

    // Track.
    canvas.drawLine(
        Offset(center.dx - trackHalf, y),
        Offset(center.dx + trackHalf, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // Cut line + acceptance window at centre.
    final winPx = trackHalf * glyWindow;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(center.dx, y), width: winPx * 2, height: r * 1.0),
        Paint()..color = _glucose.withValues(alpha: 0.10));
    canvas.drawLine(
        Offset(center.dx, y - r * 0.5),
        Offset(center.dx, y + r * 0.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2);

    // The glucose molecule sliding along the track (6-carbon chain).
    final gx = center.dx + glyPos * trackHalf;
    if (!glyDone) {
      _drawCarbonChain(canvas, Offset(gx, y), 6, r * 0.14, _glucose);
    } else {
      // Split result: two 3-carbon pyruvates drifting apart (brief).
      _drawCarbonChain(
          canvas, Offset(center.dx - r * 0.34, y), 3, r * 0.12, _glucose);
      _drawCarbonChain(
          canvas, Offset(center.dx + r * 0.34, y), 3, r * 0.12, _glucose);
    }
    textCache.draw(canvas, 'C₆  →  2 × C₃', Offset(center.dx, y + r * 0.62), 11,
        _glucose.withValues(alpha: 0.9), weight: FontWeight.w700);
  }

  void _drawCarbonChain(Canvas canvas, Offset at, int n, double rad, Color c) {
    final spacing = rad * 1.7;
    final startX = at.dx - spacing * (n - 1) / 2;
    for (int i = 0; i < n; i++) {
      final p = Offset(startX + i * spacing, at.dy);
      GameFx.orb(canvas, p, rad, c, glow: 0.8);
    }
    // Bonds.
    for (int i = 0; i < n - 1; i++) {
      final a = Offset(startX + i * spacing, at.dy);
      final b = Offset(startX + (i + 1) * spacing, at.dy);
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..strokeWidth = 2);
    }
  }

  // ── KREBS — sweeping marker through gates on a turning ring ────────────────
  void _drawKrebs(Canvas canvas, Offset center, double r) {
    // Ring track.
    canvas.drawCircle(
        center,
        r * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = _krebsC.withValues(alpha: 0.22));

    // Gates.
    for (int i = 0; i < krebsGates.length; i++) {
      final ang = krebsGates[i];
      final gp = Offset(center.dx + math.cos(ang) * r * 0.78,
          center.dy + math.sin(ang) * r * 0.78);
      final hit = krebsHit[i];
      if (hit) {
        GameFx.orb(canvas, gp, r * 0.11, Potatuhs.gold, glow: 0.9);
      } else {
        // A lit, pulsing gate to hit; a CO₂/NADH release point.
        final pulseG = 0.6 + 0.4 * math.sin(clock * 4 + i);
        canvas.drawCircle(
            gp,
            r * 0.13,
            Paint()
              ..color = _krebsC.withValues(alpha: 0.25 * pulseG)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        GameFx.orb(canvas, gp, r * 0.10, _krebsC, glow: 0.9);
        canvas.drawCircle(
            gp,
            r * 0.10,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withValues(alpha: 0.5 * pulseG));
      }
    }

    // The sweeping marker.
    final mp = Offset(center.dx + math.cos(krebsAngle) * r * 0.78,
        center.dy + math.sin(krebsAngle) * r * 0.78);
    canvas.drawCircle(
        mp,
        r * 0.09,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    GameFx.orb(canvas, mp, r * 0.07, Colors.white, glow: 1.0);

    textCache.draw(canvas, 'CITRIC ACID CYCLE', Offset(center.dx, center.dy),
        11, _krebsC.withValues(alpha: 0.9), weight: FontWeight.w700);
  }

  // ── ELECTRON TRANSPORT — pumps + ATP-synthase rotor ────────────────────────
  void _drawEtc(Canvas canvas, Offset center, double r) {
    // Two proton pumps left & right; the ATP-synthase rotor in the middle.
    final leftActive = !etcReleasing && etcNextPump == 0;
    final rightActive = !etcReleasing && etcNextPump == 1;
    _drawPump(canvas, Offset(center.dx - r * 0.62, center.dy), r * 0.2,
        leftActive, _oxygen, 'LEFT');
    _drawPump(canvas, Offset(center.dx + r * 0.62, center.dy), r * 0.2,
        rightActive, _oxygen, 'RIGHT');

    // Gradient bar (H⁺ charge) beneath.
    final by = center.dy + r * 0.5;
    final bw = r * 1.2;
    final frac =
        etcReleasing ? etcGradient : (etcCharge / etcPumpsNeeded);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx, by), width: bw, height: 8),
            const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(center.dx - bw / 2, by - 4, bw * frac, 8),
            const Radius.circular(4)),
        Paint()
          ..color = (etcReleasing ? Potatuhs.gold : _oxygen)
              .withValues(alpha: 0.9));

    // The rotor (ATP synthase) — only spins/releases once charged.
    final rr = r * 0.34;
    if (etcReleasing) {
      // Green release zone at the top.
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: rr),
          -math.pi / 2 - etcZone / 2,
          etcZone,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF66E0A3).withValues(alpha: 0.8));
      // Rotor hub + spinning blade.
      GameFx.orb(canvas, center, rr * 0.35, Potatuhs.gold, glow: 1.0);
      final tip = Offset(center.dx + math.cos(etcRotor) * rr,
          center.dy + math.sin(etcRotor) * rr);
      canvas.drawLine(
          center,
          tip,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
      GameFx.orb(canvas, tip, rr * 0.16, Colors.white, glow: 1.0);
    } else {
      // Idle rotor waiting for charge.
      canvas.drawCircle(
          center,
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.15));
      GameFx.orb(canvas, center, rr * 0.3,
          _oxygen.withValues(alpha: 0.6), glow: 0.6);
      textCache.draw(
          canvas,
          '$etcCharge / $etcPumpsNeeded H⁺',
          Offset(center.dx, center.dy + rr + 4),
          10,
          _oxygen.withValues(alpha: 0.9),
          weight: FontWeight.w700);
    }
  }

  void _drawPump(
      Canvas canvas, Offset at, double rad, bool active, Color c, String side) {
    if (active) {
      final p = 0.6 + 0.4 * math.sin(clock * 6);
      canvas.drawCircle(
          at,
          rad + 6,
          Paint()
            ..color = c.withValues(alpha: 0.35 * p)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    GameFx.orb(canvas, at, rad, active ? c : c.withValues(alpha: 0.4),
        glow: active ? 1.0 : 0.4);
    // A little "channel" notch to read as a membrane pump.
    canvas.drawLine(
        Offset(at.dx, at.dy - rad * 0.5),
        Offset(at.dx, at.dy + rad * 0.5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = 3);
    // Always name the side; brighten "TAP" on the one that's next.
    textCache.draw(canvas, side, Offset(at.dx, at.dy + rad + 11), 9,
        Colors.white.withValues(alpha: active ? 0.95 : 0.45),
        weight: FontWeight.w800);
    if (active) {
      textCache.draw(canvas, 'TAP', Offset(at.dx, at.dy - rad - 11), 10,
          Colors.white.withValues(alpha: 0.9), weight: FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerhousePainter oldDelegate) => true;
}
