import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HEARTBEAT v2 — route blood through the heart IN ORDER, on the LUB-DUB.
//
// Scale: BioScale.organ. SAME SOUL as v1: tap the six chambers in the correct
// circulation sequence (Body → RA → RV → Lungs → LA → LV → Body); deoxygenated
// (blue) blood turns red at the lungs; the win condition IS the circulation
// path. This is a LIGHT-TOUCH UX pass, not a rebuild — the original already had
// the best juice + the strongest education-in-mechanic of the batch.
//
// WHAT CHANGED vs v1 (the three teardown asks; full list in AGENT.md):
//   1. SECOND SKILL AXIS — the cardiac cycle is now a real two-phase beat. The
//      heart sounds "LUB-DUB": LUB (S1, systole) is the ventricles pumping;
//      DUB (S2, diastole) is the atria filling. So the ATRIA (RA, LA) must be
//      tapped on the DUB (mid-beat); every other stage on the LUB (downbeat).
//      Timing is no longer "tap on every downbeat" — you must hit the correct
//      HALF of the beat per chamber. This is genuine depth AND pure
//      education-in-mechanic (systole vs diastole). The required rhythm —
//      lub·dub … lub … lub·dub … lub — literally reproduces a heartbeat.
//   2. SOFTER RESET — a slip no longer collapses BPM to resting. A stall costs
//      a few streak steps (not the whole streak), so a late mistake costs a
//      step, not the built-up climax. The self-balancing streak→BPM→window
//      loop is preserved, just de-fanged.
//   3. SCAFFOLD — the first cycle grades gently: a wider window plus a loud
//      LUB / DUB tag on each node so a first-timer learns the two-phase rule
//      before timing tightens. After cycle 1 the tag fades to a quiet tint.
//   4. CLIMAX — the final 8 s become a "FINAL SURGE": BPM holds a high floor
//      (a stall can't deflate the buzzer) and pumps score ×1.5, so the
//      accelerate builds INTO the buzzer instead of yo-yoing.
//   5. FAIRNESS (kept) — the per-pump streak bonus stays capped, so no runaway
//      leader; the softer reset keeps a trailing player's ramp re-earnable, so
//      standings stay legible and comparable (pass-and-play clean).
//
// PERFORMANCE: one [Ticker] → one [CustomPainter] via a repaint notifier. No
// per-frame setState over a tree. Haptics are fire-and-forget (no-op on web).
// The host owns the clock, countdown, score HUD and results — this renders
// ONLY the play area.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (tune freely) ────────────────────────────────────────────
const double _kBaseBpm = 64; // resting rate when the streak is cold
const double _kMaxBpm = 176; // ceiling — streak can't push faster than this
const double _kBpmPerStreak = 5; // each clean pump in a streak adds this much
const double _kIdleBpm = 50; // gentle resting thump in the calm ready state

// Timing window (in beat-phase units; a full beat is 0..1). The LUB target is
// phase 0, the DUB target is phase 0.5. The window shrinks as BPM climbs.
const double _kWindowWide = 0.20; // forgiving window at resting rate
const double _kWindowTight = 0.085; // tightest window at max rate
const double _kPerfectFrac = 0.4; // inside this fraction of the window = PERFECT
const double _kScaffoldBonus = 0.09; // extra window during the first (graded) cycle

// Scoring.
const int _kPumpBase = 12; // points for a clean pump
const int _kPerfectBonus = 8; // extra for a dead-on-the-beat pump
const int _kAtrialKick = 3; // extra for a PERFECT atrial (DUB) fill
const int _kStreakCap = 12; // streak bonus is min(streak, cap) — caps runaway
const int _kCycleBonus = 40; // returning blood to the body completes a cycle

// Soft reset + climax (the two teardown fixes).
const int _kStallPenalty = 3; // streak steps lost on a stall (was: all of them)
const int _kClimaxMs = 8000; // final-surge window before the buzzer
const double _kClimaxFloorBpm = 120; // BPM can't fall below this during the surge
const double _kClimaxMult = 1.5; // pump/cycle score multiplier during the surge

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFFE5484D); // cardinal red — the heart
const Color _kBlue = Color(0xFF42A5F5); // deoxygenated blood
const Color _kBlueDeep = Color(0xFF1565C0);
const Color _kRed = Color(0xFFEF5350); // oxygenated blood
const Color _kRedDeep = Color(0xFFB71C1C);
const Color _kGreen = Color(0xFF69F0AE);
const Color _kDub = Color(0xFFB388FF); // violet — the DUB (diastole) accent
const Color _kWhite = Colors.white;

/// One stage in the circulation loop.
class _Stage {
  final String label; // short tag drawn on the node
  final String full; // full name surfaced for the active stage
  final bool oxy; // true = oxygenated (red), false = deoxygenated (blue)
  final bool dub; // true = atrial fill on the DUB (diastole); else LUB (systole)
  const _Stage(this.label, this.full, this.oxy, this.dub);

  Color get color => oxy ? _kRed : _kBlue;
  Color get deep => oxy ? _kRedDeep : _kBlueDeep;
}

/// The fixed loop. Index order IS the pump order. Blood turns red at the lungs
/// (oxygenate) and back to blue at the body (O₂ delivered). The two ATRIA fill
/// on the DUB (diastole); everything else pumps on the LUB (systole).
const List<_Stage> _kLoop = <_Stage>[
  _Stage('BODY', 'Body · O₂ delivered', false, false),
  _Stage('RA', 'Right Atrium · fills', false, true),
  _Stage('RV', 'Right Ventricle', false, false),
  _Stage('LUNGS', 'Lungs · oxygenate', true, false),
  _Stage('LA', 'Left Atrium · fills', true, true),
  _Stage('LV', 'Left Ventricle', true, false),
];

class HeartbeatV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HeartbeatV2Game({super.key, required this.session});

  @override
  State<HeartbeatV2Game> createState() => _HeartbeatV2GameState();
}

/// Repaint driver — pumped once per tick so the painter repaints without a
/// per-frame `setState` over the widget tree.
class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _HeartbeatV2GameState extends State<HeartbeatV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  // ── Core state ─────────────────────────────────────────────────────────────
  int _pos = 0; // index of the stage currently holding the blood
  int _streak = 0; // consecutive clean pumps
  int _cycles = 0; // full loops completed
  double _bpm = _kBaseBpm;
  double _window = _kWindowWide;

  // Beat metronome. _beatPhase wraps 0→1 every beat; LUB is phase 0, DUB is 0.5.
  double _beatPhase = 0.0;

  // ── Climax ───────────────────────────────────────────────────────────────
  bool _climax = false; // inside the final-surge window
  bool _climaxHit = false; // one-shot FINAL SURGE announce

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _beatFlash = 0.0; // bloom on a clean pump, 1 → 0
  double _missFlash = 0.0; // red wash on a stall, 1 → 0
  double _perfectFlash = 0.0; // gold ring on a PERFECT pump
  String? _banner; // transient callout (CYCLE, PERFECT, MISS…)
  double _bannerAge = 0.0;
  Color _bannerColor = _kGreen;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  int get _active => (_pos + 1) % _kLoop.length;
  bool get _scaffold => _cycles == 0; // first cycle is graded gently

  @override
  void initState() {
    super.initState();
    _recalc();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _recalc() {
    var bpm = _kBaseBpm + _streak * _kBpmPerStreak;
    if (_climax) bpm = math.max(bpm, _kClimaxFloorBpm); // surge holds the floor
    _bpm = bpm.clamp(_kBaseBpm, _kMaxBpm);
    final t = ((_bpm - _kBaseBpm) / (_kMaxBpm - _kBaseBpm)).clamp(0.0, 1.0);
    _window = _kWindowWide + (_kWindowTight - _kWindowWide) * t;
  }

  void _resetRun() {
    _pos = 0;
    _streak = 0;
    _cycles = 0;
    _beatPhase = 0.0;
    _beatFlash = 0;
    _missFlash = 0;
    _perfectFlash = 0;
    _banner = null;
    _bannerAge = 0;
    _climax = false;
    _climaxHit = false;
    _fx.clear();
    _pops.clear();
    _recalc();
  }

  /// Effective window for [stage], widened during the graded first cycle.
  double _winFor() => _window + (_scaffold ? _kScaffoldBonus : 0.0);

  /// Timing error to a stage's REQUIRED half-beat (0 = dead on target).
  double _teTo(bool dub) =>
      dub ? (_beatPhase - 0.5).abs() : math.min(_beatPhase, 1 - _beatPhase);

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    // Fresh run detected: reset internal state so a session can re-enter clean.
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // Final-surge detection (the host owns the clock; we just read it).
    final remMs = widget.session.remaining.inMilliseconds;
    final climaxNow = running && remMs > 0 && remMs <= _kClimaxMs;
    if (climaxNow != _climax) {
      _climax = climaxNow;
      _recalc(); // surge raises the BPM floor immediately
    }
    if (_climax && !_climaxHit) {
      _climaxHit = true;
      _flash('FINAL SURGE', _kAccent);
      HapticFeedback.mediumImpact();
    }

    // Advance the metronome. Idle (calm) thump when not running.
    final bpm = running ? _bpm : _kIdleBpm;
    final period = 60.0 / bpm;
    _beatPhase = (_beatPhase + dt / period) % 1.0;

    // Decay juice.
    _beatFlash = math.max(0.0, _beatFlash - dt * 2.6);
    _missFlash = math.max(0.0, _missFlash - dt * 3.0);
    _perfectFlash = math.max(0.0, _perfectFlash - dt * 2.2);
    if (_banner != null) {
      _bannerAge += dt;
      if (_bannerAge > 1.2) _banner = null;
    }
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    _repaint.tick();
  }

  // ── Input ────────────────────────────────────────────────────────────────
  void _handleTap(Offset local, Size size) {
    if (!widget.session.isRunning) return;
    final geo = _HeartGeo.of(size);

    // Nearest node within a generous, thumb-friendly hit radius.
    int hit = -1;
    double best = geo.nodeR * 1.7;
    for (var i = 0; i < geo.nodes.length; i++) {
      final d = (geo.nodes[i] - local).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit < 0) return;

    // Axis 1 — must tap the NEXT stage in the loop (the circulation path).
    if (hit != _active) {
      _stall('WRONG WAY', geo.nodes[hit]);
      return;
    }

    // Axis 2 — must hit the correct HALF of the beat for this chamber.
    final dub = _kLoop[_active].dub;
    final te = _teTo(dub); // distance to the required phase
    final other = _teTo(!dub); // distance to the OTHER phase
    final win = _winFor();

    if (te <= win) {
      _pump(te, dub, win, geo);
    } else if (other <= win) {
      // Tapped on a real beat — but the wrong half. Teach the rule.
      _stall(dub ? 'FILL ON THE DUB' : 'PUMP ON THE LUB', geo.nodes[hit]);
    } else {
      _stall(_beatPhase < (dub ? 0.5 : 0.25) ? 'TOO SOON' : 'TOO LATE',
          geo.nodes[hit]);
    }
  }

  void _pump(double te, bool dub, double win, _HeartGeo geo) {
    final perfect = te <= win * _kPerfectFrac;
    _pos = _active;
    _streak++;
    _recalc();

    var pts = _kPumpBase + _streak.clamp(0, _kStreakCap);
    if (perfect) {
      pts += _kPerfectBonus;
      _perfectFlash = 1.0;
      if (dub) pts += _kAtrialKick; // nailing the off-beat atrial fill pays
    }
    if (_climax) pts = (pts * _kClimaxMult).round();

    final stage = _kLoop[_pos];
    final pos = geo.nodes[_pos];
    widget.session.addScore(pts);
    widget.session.noteStreak(_streak);
    _beatFlash = 1.0;
    _fx.addAll(FxBurst.spawn(pos, dub ? _kDub : stage.color,
        count: perfect ? 18 : 12, speed: perfect ? 150 : 110));
    _pops.add(FxPop(pos, '+$pts', perfect ? Potatuhs.gold : _kWhite));
    HapticFeedback.lightImpact();

    // Returning blood to the body closes a full circulation cycle.
    if (_pos == 0) {
      _cycles++;
      final cyc = (_climax ? _kCycleBonus * _kClimaxMult : _kCycleBonus).round();
      widget.session.addScore(cyc);
      _flash('CYCLE +$cyc', Potatuhs.gold);
      HapticFeedback.mediumImpact();
    } else if (_pos == 3) {
      _flash('OXYGENATED', _kRed);
    } else if (dub && perfect) {
      _flash('ATRIAL KICK', _kDub);
    } else if (perfect) {
      _flash('PERFECT', Potatuhs.gold);
    }
  }

  void _stall(String why, Offset at) {
    // SOFTER than v1: lose a few streak steps, not the whole streak. The ramp
    // (and the climax) survives a single late slip.
    _streak = math.max(0, _streak - _kStallPenalty);
    _recalc();
    _missFlash = 0.7;
    _pops.add(FxPop(at, why, _kRedDeep));
    HapticFeedback.heavyImpact();
  }

  void _flash(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerAge = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _handleTap(d.localPosition, size),
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _HeartV2Painter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Geometry — the six stages laid out on an ellipse so the loop reads as a ring.
// Shared by hit-testing and the painter so they never drift.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartGeo {
  final Offset center;
  final double nodeR;
  final List<Offset> nodes;
  const _HeartGeo(this.center, this.nodeR, this.nodes);

  factory _HeartGeo.of(Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final rx = size.width * 0.33;
    final ry = size.height * 0.33;
    final nodeR = (size.shortestSide * 0.085).clamp(22.0, 42.0);
    final nodes = <Offset>[
      for (var i = 0; i < _kLoop.length; i++)
        center +
            Offset(
              math.cos(math.pi / 2 + i * math.pi / 3) * rx,
              math.sin(math.pi / 2 + i * math.pi / 3) * ry,
            ),
    ];
    return _HeartGeo(center, nodeR, nodes);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — one pass, whole play area. Reads game state directly and repaints
// when the [_RepaintNotifier] ticks.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartV2Painter extends CustomPainter {
  final _HeartbeatV2GameState state;
  _HeartV2Painter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  // Pulse peaking at a given beat-phase center (wrap-aware).
  double _pulseAt(double center) {
    final d = (state._beatPhase - center).abs();
    final dd = math.min(d, 1 - d);
    return math.pow(math.max(0.0, 1 - dd / 0.16), 2).toDouble();
  }

  double get _lubPulse => _pulseAt(0.0);
  double get _dubPulse => _pulseAt(0.5) * 0.72; // S2 is the softer sound
  double get _beatPulse => math.max(_lubPulse, _dubPulse);

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    GameFx.atmosphere(canvas, size, _kAccent, s._beatPhase + s._cycles.toDouble());
    if (s._climax) _paintClimaxVignette(canvas, size);
    final geo = _HeartGeo.of(size);

    _paintSegments(canvas, geo);
    _paintCenterHeart(canvas, geo);
    for (var i = 0; i < geo.nodes.length; i++) {
      _paintNode(canvas, geo, i);
    }
    _paintApproachRing(canvas, geo);
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
    _paintActiveLabel(canvas, size, geo);
    _paintBanner(canvas, size);
    _paintFlashes(canvas, size);
    if (!s.widget.session.isRunning) _paintReadyHint(canvas, size);
  }

  // ── Loop segments + flow arrows ────────────────────────────────────────────
  void _paintSegments(Canvas canvas, _HeartGeo geo) {
    final n = geo.nodes.length;
    for (var i = 0; i < n; i++) {
      final a = geo.nodes[i];
      final b = geo.nodes[(i + 1) % n];
      final color = _kLoop[i].color; // blood color leaving stage i
      final isActiveSeg = i == state._pos; // the segment about to be pumped along
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color.withValues(alpha: isActiveSeg ? 0.55 : 0.22)
          ..strokeWidth = isActiveSeg ? 7 : 4
          ..strokeCap = StrokeCap.round,
      );
      _paintArrow(canvas, a, b, color.withValues(alpha: isActiveSeg ? 0.9 : 0.4));
    }
  }

  void _paintArrow(Canvas canvas, Offset a, Offset b, Color color) {
    final mid = Offset.lerp(a, b, 0.5)!;
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    const sz = 7.0;
    final tip = mid + u * sz;
    final p1 = mid - u * sz + perp * sz;
    final p2 = mid - u * sz - perp * sz;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── Central heart that thumps LUB-DUB ─────────────────────────────────────
  void _paintCenterHeart(Canvas canvas, _HeartGeo geo) {
    final sz = geo.nodeR * (0.9 + 0.16 * _beatPulse);
    final path = _heartPath(geo.center, sz);
    canvas.drawPath(
      path,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.30 + 0.35 * _beatPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kRed, _kAccent, _kRedDeep],
        ).createShader(Rect.fromCircle(center: geo.center, radius: sz)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kWhite.withValues(alpha: 0.5),
    );
    // LUB-DUB readout: the two sounds light up as the beat passes each.
    GameFx.text(
      canvas,
      'lub',
      geo.center.translate(-geo.nodeR * 0.6, geo.nodeR * 1.5),
      11,
      _kWhite.withValues(alpha: 0.35 + 0.6 * _lubPulse),
      weight: FontWeight.w800,
    );
    GameFx.text(
      canvas,
      'dub',
      geo.center.translate(geo.nodeR * 0.6, geo.nodeR * 1.5),
      11,
      _kDub.withValues(alpha: 0.35 + 0.6 * (_dubPulse / 0.72)),
      weight: FontWeight.w800,
    );
    GameFx.text(
      canvas,
      '${state._bpm.round()} BPM',
      geo.center.translate(0, geo.nodeR * 1.5 + 16),
      12,
      _kWhite.withValues(alpha: 0.85),
      weight: FontWeight.w800,
    );
    if (state._streak >= 2) {
      GameFx.text(
        canvas,
        '🔥 ${state._streak}',
        geo.center.translate(0, geo.nodeR * 1.5 + 32),
        12,
        Potatuhs.gold,
        weight: FontWeight.w700,
      );
    }
  }

  Path _heartPath(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.36)
      ..cubicTo(c.dx + s * 1.05, c.dy - s * 0.45, c.dx + s * 0.5, c.dy - s,
          c.dx, c.dy - s * 0.42)
      ..cubicTo(c.dx - s * 0.5, c.dy - s, c.dx - s * 1.05, c.dy - s * 0.45,
          c.dx, c.dy + s * 0.36)
      ..close();
  }

  // ── A circulation stage node ──────────────────────────────────────────────
  void _paintNode(Canvas canvas, _HeartGeo geo, int i) {
    final stage = _kLoop[i];
    final pos = geo.nodes[i];
    final isHere = i == state._pos; // blood currently here
    final isActive = i == state._active; // next to be tapped
    final dim = !isHere && !isActive;

    final pulse = isHere ? (1.0 + 0.12 * _beatPulse) : 1.0;
    GameFx.orb(
      canvas,
      pos,
      geo.nodeR * pulse,
      dim ? stage.deep : stage.color,
      glow: isHere ? (0.7 + 0.6 * _beatPulse) : (isActive ? 0.7 : 0.25),
      rim: isActive ? _kWhite : null,
    );

    if (isHere) {
      canvas.drawCircle(
        pos,
        geo.nodeR * 0.42 * pulse,
        Paint()
          ..color = _kWhite.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    GameFx.text(
      canvas,
      stage.label,
      pos,
      geo.nodeR * 0.42,
      _kWhite.withValues(alpha: dim ? 0.65 : 0.95),
      weight: FontWeight.w800,
    );

    // The phase tag — LOUD during the scaffold first cycle, a quiet tint after.
    // This is the second skill axis made legible: atria say DUB, the rest LUB.
    final tagAlpha = state._scaffold ? 0.95 : (isActive ? 0.7 : 0.32);
    GameFx.text(
      canvas,
      stage.dub ? 'DUB' : 'LUB',
      pos.translate(0, geo.nodeR + 9),
      geo.nodeR * 0.3,
      (stage.dub ? _kDub : _kGreen).withValues(alpha: tagAlpha),
      weight: FontWeight.w800,
    );
  }

  // ── Rhythm approach ring on the active node (target-phase aware) ───────────
  void _paintApproachRing(Canvas canvas, _HeartGeo geo) {
    if (!state.widget.session.isRunning) return;
    final active = state._active;
    final pos = geo.nodes[active];
    final dub = _kLoop[active].dub;
    final ringColor = dub ? _kDub : _kLoop[active].color;

    // Distance to the REQUIRED half-beat → drives the closing ring.
    final te = state._teTo(dub); // 0..0.5
    final win = state._winFor();
    final inWindow = te <= win;
    final r = geo.nodeR * (1.0 + 1.8 * (te * 2)); // te*2 ∈ 0..1

    // Static target ring — tap when the approach ring shrinks onto it.
    canvas.drawCircle(
      pos,
      geo.nodeR * 1.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (inWindow ? _kGreen : _kWhite).withValues(alpha: 0.45),
    );
    // Shrinking approach ring, tinted by which sound it's chasing.
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inWindow ? 4 : 2.4
        ..color = (inWindow ? _kGreen : ringColor)
            .withValues(alpha: inWindow ? 0.95 : 0.6),
    );
  }

  // ── Active-stage name + the phase coaching (the educational label) ─────────
  void _paintActiveLabel(Canvas canvas, Size size, _HeartGeo geo) {
    if (!state.widget.session.isRunning) return;
    final stage = _kLoop[state._active];
    final tint = stage.oxy ? _kRed : _kBlue;
    GameFx.text(
      canvas,
      'NEXT  →  ${stage.full}',
      Offset(size.width / 2, size.height - 42),
      14,
      tint,
      weight: FontWeight.w800,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      stage.dub
          ? 'DIASTOLE · atrium fills — tap on the DUB'
          : 'SYSTOLE · pump out — tap on the LUB',
      Offset(size.width / 2, size.height - 24),
      11,
      (stage.dub ? _kDub : _kGreen).withValues(alpha: 0.9),
      weight: FontWeight.w700,
    );
    GameFx.text(
      canvas,
      stage.oxy ? 'oxygenated · red' : 'deoxygenated · blue',
      Offset(size.width / 2, size.height - 10),
      10,
      _kWhite.withValues(alpha: 0.55),
    );
  }

  void _paintBanner(Canvas canvas, Size size) {
    final banner = state._banner;
    if (banner == null) return;
    final t = (state._bannerAge / 1.2).clamp(0.0, 1.0);
    final alpha = (1 - t * t);
    GameFx.text(
      canvas,
      banner,
      Offset(size.width / 2, size.height * 0.18 - 24 * t),
      26,
      state._bannerColor.withValues(alpha: alpha),
      display: true,
      glow: 0.8 * alpha,
    );
  }

  void _paintFlashes(Canvas canvas, Size size) {
    if (state._missFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kRedDeep.withValues(alpha: 0.28 * state._missFlash),
      );
    }
    if (state._perfectFlash > 0.3) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.14 * state._perfectFlash),
      );
    }
  }

  // ── Final-surge vignette ──────────────────────────────────────────────────
  void _paintClimaxVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pulse = 0.10 + 0.10 * _beatPulse;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.0),
            _kAccent.withValues(alpha: pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
    GameFx.text(
      canvas,
      'FINAL SURGE  ×${_kClimaxMult.toStringAsFixed(1)}',
      Offset(size.width / 2, 22),
      13,
      _kAccent.withValues(alpha: 0.7 + 0.3 * _beatPulse),
      weight: FontWeight.w800,
      glow: 0.5,
    );
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'HEARTBEAT',
      Offset(size.width / 2, size.height * 0.12),
      30,
      _kAccent,
      display: true,
      glow: 0.6,
    );
    GameFx.text(
      canvas,
      'Route blood through the heart — in order, on the lub-dub.',
      Offset(size.width / 2, size.height * 0.12 + 30),
      13,
      _kWhite.withValues(alpha: 0.8),
    );
    GameFx.text(
      canvas,
      'Ventricles pump on the LUB · atria fill on the DUB.',
      Offset(size.width / 2, size.height * 0.12 + 50),
      12,
      _kWhite.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartV2Painter old) => false;
}
