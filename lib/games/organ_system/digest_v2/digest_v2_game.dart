import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../fx.dart';
import '../../mini_game.dart';

/// Digest v2 — "Run the Tract" (UX-refinement-pass alternative to `digest`).
///
/// Food (a *bolus*) travels the digestive tract left→right through five organs:
///   MOUTH → ESOPHAGUS → STOMACH → SMALL INTESTINE → LARGE INTESTINE.
/// Each organ does a *different* job, so each needs a *different* ACTION:
///   • MOUTH — CHEW           (break the food down)
///   • ESOPHAGUS — SWALLOW     (push it down)
///   • STOMACH — CHURN         (mash it with acid)
///   • SMALL INT. — NUTRIENTS  (absorb nutrients into the blood — the big payoff)
///   • LARGE INT. — WATER      (reclaim water before the rest is expelled)
///
/// THE #1 FIX vs the original. In v1 the CHEW/CHURN/ABSORB buttons were
/// decorative: one button sat under each column and `_press(i)` advanced
/// whatever ripe bolus was at column `i` regardless of the verb, so the game was
/// "tap the lit button under the glowing food." The verb was never a choice.
///
/// Here the verb is the SKILL. The verb bar is one shared control, decoupled
/// from the tube columns. A single bolus is the TARGET (the front-most ripe one,
/// nearest the exit — or one you tap). To advance it you must press the action
/// that **its current organ** needs. Press the WRONG verb and the work stalls
/// (ripeness knocked back) and your combo breaks. Matching organ→action *is*
/// playing the lesson, not just reading it. Icons on each organ mirror the icon
/// on its verb button, so a first-timer can match by icon and a master does it
/// from memory at speed.
///
/// Pipeline lesson kept: one bolus per organ; clear the FRONT or new food backs
/// up at the mouth. A flow combo (consecutive correct actions) adds a bounded
/// bonus, rewarding keeping all five organs moving without runaway scoring.
///
/// Accelerates: food arrives faster and ripens faster, so up to five boluses
/// ride the tract at once and you juggle five different recalled verbs — the
/// climax. The host owns the clock, countdown, HUD and results; this widget
/// renders only the play area and reports through the session.
class DigestV2Game extends StatefulWidget {
  final MiniGameSession session;
  const DigestV2Game({super.key, required this.session});

  @override
  State<DigestV2Game> createState() => _DigestV2GameState();
}

// ── Tuning (one place; play-test freely) ─────────────────────────────────────
const int _kStages = 5;

/// Intake interval (seconds between new boluses) ramps fast → frantic.
const double _kIntakeStart = 2.3;
const double _kIntakePeak = 0.95;

/// How long a bolus ripens at an organ (the chew/churn beat). Shrinks over the
/// round so late food is ready almost at once.
const double _kRipenStart = 0.85;
const double _kRipenPeak = 0.46;

/// Slide animation when a bolus moves to the next organ (seconds).
const double _kMoveTime = 0.26;

/// How far a wrong verb knocks back the target's readiness (the penalty).
const double _kWrongStall = 0.55;

/// Points for completing each organ's action. Absorption organs pay the most —
/// that is where the body actually gains nutrients and water.
const List<int> _kStagePoints = [4, 4, 6, 16, 10];

/// Bonus when a bolus exits the large intestine fully processed.
const int _kCompleteBonus = 8;

/// Flow combo: each correct action in a row adds this much, capped, so chains
/// reward keeping the tract flowing without a runaway leader.
const int _kComboCap = 8;

// ── Palette (digestive tract) ────────────────────────────────────────────────
const Color _kBg = Potatuhs.inkDeep;
const Color _kTube = Color(0xFF2C201C);
const Color _kTubeEdge = Color(0xFF44322B);
const Color _kReady = Color(0xFFE1C916); // gold = ripe / actionable
const Color _kDeny = Color(0xFFE2574B); // red = wrong verb
const Color _kBlock = Color(0xFFE19816); // sienna = backed up
const String _kFont = Potatuhs.bodyFont;

class _StageDef {
  final String name;
  final String action;
  final IconData icon;
  final Color tint;
  const _StageDef(this.name, this.action, this.icon, this.tint);
}

/// The verb bar is drawn in tract order, so the control row itself reinforces
/// the sequence MOUTH→…→LARGE INT. Each verb's icon mirrors its organ's icon.
const List<_StageDef> _kStageDefs = [
  _StageDef('MOUTH', 'CHEW', Icons.restaurant, Color(0xFFE08FA0)),
  _StageDef('ESOPHAGUS', 'SWALLOW', Icons.south, Color(0xFFC79A86)),
  _StageDef('STOMACH', 'CHURN', Icons.cyclone, Color(0xFFE0734B)),
  _StageDef('SMALL INT.', 'NUTRIENTS', Icons.grain, Color(0xFF7BBE6E)),
  _StageDef('LARGE INT.', 'WATER', Icons.water_drop, Color(0xFF6FA9C8)),
];

/// Food-flavour tints so successive boluses read as distinct morsels.
const List<Color> _kFoodColors = [
  Color(0xFFE8B873), // potato
  Color(0xFFD86B4B), // tomato
  Color(0xFF8FB96B), // greens
  Color(0xFFE0C24B), // corn
  Color(0xFFB97FD0), // berry
];

class _Bolus {
  int stage; // 0..4 current organ (target organ while moving)
  double ripe; // 0..1 readiness at this organ
  double slide; // -1 → 0 while sliding from the previous organ into [stage]
  bool moving;
  final double bobPhase;
  final int kind;
  _Bolus(this.stage, this.kind, this.bobPhase)
      : ripe = 0,
        slide = 0,
        moving = false;

  bool get ready => !moving && ripe >= 1.0;
}

class _DigestV2GameState extends State<DigestV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  final List<_Bolus> _boluses = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // Per-verb-button shake on a wrong/empty press.
  final List<double> _shake = List<double>.filled(_kStages, 0);

  double _elapsed = 0; // seconds in the playing phase
  double _intakeT = _kIntakeStart; // countdown to next bolus
  int _streak = 0;
  double _bgClock = 0; // atmosphere drift
  int _kindCounter = 0;
  double _idleT = 0; // idle auto-advance timer

  // Player-chosen target (tap a ripe bolus). Falls back to the front-most ripe.
  _Bolus? _picked;

  // Last layout, for hit-testing taps.
  double _w = 1, _h = 1;
  double _footerTop = 0;

  static const double _kFooterH = 72;

  double get _duration =>
      widget.session.spec.durationSeconds.toDouble().clamp(1, 600);

  @override
  void initState() {
    super.initState();
    // Seed one morsel so the calm pre-round preview reads as a live tract.
    _boluses.add(_Bolus(0, 0, _rng.nextDouble() * 6));
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Default cadence (~250ms): the tract accelerates and can carry
    // up to five ripe boluses at once, so acting each tick just keeps the
    // pipeline flowing — never superhuman, since a ripe target is required.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick. Plays Digest v2 *correctly*: it finds
  /// the active target (the ripe bolus nearest the exit — the front of the
  /// pipeline you must clear first) and presses the verb THAT organ needs, by
  /// pressing the button under its own stage. Because the target's `stage` is
  /// exactly the correct verb index, `_press(t.stage)` always takes the CHEW/
  /// SWALLOW/CHURN/NUTRIENTS/WATER action the organ demands — never a wrong
  /// verb. If nothing is ripe yet, it waits (the organs are still doing their
  /// work); if the exit is fully processed, `_advance` scores and clears it.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    final t = _activeTarget();
    if (t == null) return; // no ripe bolus — let the tract keep ripening
    _press(t.stage); // the exact action this organ needs
  }

  // ── The active target: the bolus the next verb press will act on. ───────────
  /// Player's pick if it is still ripe & settled, else the ripe bolus nearest
  /// the exit (largest stage) — the front of the pipeline you must clear first.
  _Bolus? _activeTarget() {
    if (_picked != null && _boluses.contains(_picked) && _picked!.ready) {
      return _picked;
    }
    _Bolus? front;
    for (final b in _boluses) {
      if (b.ready && (front == null || b.stage > front.stage)) front = b;
    }
    return front;
  }

  // ── Loop ────────────────────────────────────────────────────────────────────
  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (dt <= 0) return;

    _bgClock += dt;
    for (var i = 0; i < _kStages; i++) {
      _shake[i] = math.max(0, _shake[i] - dt * 3.5);
    }
    for (final b in _boluses) {
      if (b.moving) {
        b.slide += dt / _kMoveTime;
        if (b.slide >= 0) {
          b.slide = 0;
          b.moving = false;
          b.ripe = 0;
        }
      }
    }
    for (final p in _particles) {
      p.step(dt);
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (widget.session.isRunning) {
      _step(dt);
    } else {
      _idle(dt);
    }

    if (mounted) setState(() {});
  }

  double _progress() => (_elapsed / _duration).clamp(0.0, 1.0);

  double _ripenTime() {
    final p = _progress();
    return _kRipenStart + (_kRipenPeak - _kRipenStart) * p;
  }

  void _step(double dt) {
    _elapsed += dt;
    final p = _progress();
    final ripen = _ripenTime();

    for (final b in _boluses) {
      if (!b.moving && b.ripe < 1.0) {
        b.ripe = math.min(1.0, b.ripe + dt / ripen);
      }
    }

    // Intake new food at the mouth — only if the mouth is clear (pipeline).
    _intakeT -= dt;
    if (_intakeT <= 0) {
      final interval = _kIntakeStart + (_kIntakePeak - _kIntakeStart) * p;
      _intakeT = interval;
      if (!_stageOccupied(0)) {
        _boluses.add(_Bolus(
            0, _kindCounter++ % _kFoodColors.length, _rng.nextDouble() * 6));
      }
    }
  }

  void _idle(double dt) {
    // Calm preview: a single morsel ripens, drifts organ→organ on a slow timer
    // and recycles. No scoring, no penalties.
    final ripen = _ripenTime();
    for (final b in _boluses) {
      if (!b.moving && b.ripe < 1.0) {
        b.ripe = math.min(1.0, b.ripe + dt / (ripen * 1.6));
      }
    }
    _idleT -= dt;
    if (_idleT <= 0) {
      _idleT = 1.1;
      _Bolus? ripe;
      for (final b in _boluses) {
        if (b.ready) {
          ripe = b;
          break;
        }
      }
      if (ripe != null) {
        if (ripe.stage >= _kStages - 1) {
          _boluses.remove(ripe);
        } else if (!_stageOccupied(ripe.stage + 1)) {
          ripe.stage += 1;
          ripe.slide = -1;
          ripe.moving = true;
          ripe.ripe = 0;
        }
      }
      if (_boluses.isEmpty || (_boluses.length < 2 && !_stageOccupied(0))) {
        _boluses.add(_Bolus(
            0, _kindCounter++ % _kFoodColors.length, _rng.nextDouble() * 6));
      }
    }
  }

  bool _stageOccupied(int stage, {_Bolus? except}) {
    for (final b in _boluses) {
      if (b != except && b.stage == stage) return true;
    }
    return false;
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _tapAt(Offset local) {
    if (!widget.session.isRunning) return;
    if (local.dy >= _footerTop) {
      // Verb bar: pick the column → press that verb.
      final colW = _w / _kStages;
      final v = (local.dx / colW).floor().clamp(0, _kStages - 1);
      _press(v);
      return;
    }
    // Tube: tap a ripe bolus to make it the target.
    final colW = _w / _kStages;
    final midY = _midY();
    for (final b in _boluses) {
      if (!b.ready) continue;
      final cx = colW * (b.stage + 0.5);
      if ((local - Offset(cx, midY)).distance <= 30) {
        _picked = b;
        return;
      }
    }
  }

  void _press(int v) {
    final colW = _w / _kStages;
    final btnCenter = Offset(colW * (v + 0.5), _footerTop + _kFooterH * 0.5);

    final t = _activeTarget();
    if (t == null) {
      // No food is ready — a harmless eager tap. Tiny nudge, no streak loss.
      _shake[v] = 0.55;
      _pops.add(FxPop(btnCenter, 'NOTHING RIPE', _kBlock));
      return;
    }

    if (v == t.stage) {
      _advance(t);
      return;
    }

    // WRONG VERB — the lesson made real. The organ's work stalls; combo breaks.
    _shake[v] = 1.0;
    t.ripe = math.max(0.0, t.ripe - _kWrongStall);
    _streak = 0;
    final wantIcon = _kStageDefs[t.stage].name;
    _pops.add(FxPop(_bolusPos(t).translate(0, -18), 'WRONG · $wantIcon', _kDeny));
  }

  void _advance(_Bolus b) {
    final i = b.stage;
    final at = _bolusPos(b);
    final combo = _streak.clamp(0, _kComboCap);

    if (i >= _kStages - 1) {
      // Large intestine: absorb water + the bolus exits fully processed.
      final pts = _kStagePoints[i] + _kCompleteBonus + combo;
      widget.session.addScore(pts);
      _streak += 1;
      widget.session.noteStreak(_streak);
      if (identical(_picked, b)) _picked = null;
      _boluses.remove(b);
      _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: 16));
      _pops.add(FxPop(at.translate(0, -18), 'WATER +$pts', _kReady));
      return;
    }

    if (_stageOccupied(i + 1, except: b)) {
      // Downstream organ is full — correct verb, but it can't move yet. No
      // penalty (you read the tract right); clear the front first. Pipeline.
      final colW = _w / _kStages;
      _pops.add(
          FxPop(Offset(colW * (i + 1.5), _midY() - 16), 'BACKED UP', _kBlock));
      return;
    }

    final pts = _kStagePoints[i] + combo;
    widget.session.addScore(pts);
    _streak += 1;
    widget.session.noteStreak(_streak);
    b.stage = i + 1;
    b.slide = -1;
    b.moving = true;
    b.ripe = 0;
    _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: 10));
    final label = i == 3 ? 'NUTRIENTS +$pts' : '+$pts';
    _pops.add(FxPop(at.translate(0, -16), label,
        i == 3 ? _kStageDefs[3].tint : _kReady));
  }

  Offset _bolusPos(_Bolus b) {
    final colW = _w / _kStages;
    final cx = colW * (b.stage + 0.5) + b.slide * colW;
    return Offset(cx, _midY());
  }

  double _midY() {
    const labelTop = 26.0;
    final tubeTop = labelTop + 34 + 6;
    final tubeBottom = _footerTop - 12;
    return (tubeTop + tubeBottom) / 2;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      _footerTop = _h - _kFooterH;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tapAt(d.localPosition),
        child: CustomPaint(
          size: Size(_w, _h),
          painter: _DigestV2Painter(this),
        ),
      );
    });
  }
}

class _DigestV2Painter extends CustomPainter {
  final _DigestV2GameState s;
  _DigestV2Painter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final running = s.widget.session.isRunning;
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    GameFx.atmosphere(canvas, size, _kStageDefs[2].tint, s._bgClock, motes: 22);

    final colW = size.width / _kStages;
    const labelTop = 26.0;
    const labelH = 34.0;
    final footerTop = size.height - _DigestV2GameState._kFooterH;
    final tubeTop = labelTop + labelH + 6;
    final tubeBottom = footerTop - 12;
    final tubeMid = (tubeTop + tubeBottom) / 2;
    final tubeH = math.max(28.0, tubeBottom - tubeTop);

    final target = s._activeTarget();

    _paintTitle(canvas, size);
    _paintTube(canvas, size, tubeTop, tubeH, colW, target);

    for (var i = 0; i < _kStages; i++) {
      final lit = target != null && target.stage == i;
      _paintStageLabel(canvas, i, colW * (i + 0.5), labelTop, lit);
    }

    for (final b in s._boluses) {
      _paintBolus(canvas, b, colW, tubeMid, identical(b, target));
    }

    // Link the target to the verb bar so input and target read as connected.
    if (running && target != null) {
      _paintTargetLink(canvas, target, colW, footerTop);
    }

    FxBurst.paint(canvas, s._particles);

    for (var i = 0; i < _kStages; i++) {
      // The bar never highlights the *correct* verb — choosing it is the skill.
      _paintVerb(canvas, i, colW * (i + 0.5), footerTop, colW);
    }

    if (!running) _paintReadyHint(canvas, size, footerTop);

    for (final p in s._pops) {
      _paintPop(canvas, p);
    }
  }

  void _paintTitle(Canvas canvas, Size size) {
    _text(canvas, 'DIGESTIVE TRACT', const Offset(14, 13),
        size: 11,
        color: Colors.white.withValues(alpha: 0.5),
        align: -1,
        bold: true);
    if (s._streak >= 3) {
      _text(canvas, 'COMBO ${s._streak}', Offset(size.width - 14, 13),
          size: 12, color: _kReady, align: 1, bold: true);
    }
  }

  void _paintTube(Canvas canvas, Size size, double top, double h, double colW,
      _Bolus? target) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, top, size.width - 12, h),
      Radius.circular(h * 0.42),
    );
    canvas.drawRRect(rr, Paint()..color = _kTube);

    canvas.save();
    canvas.clipRRect(rr);
    for (var i = 0; i < _kStages; i++) {
      final r = Rect.fromLTWH(colW * i, top, colW, h);
      final lit = target != null && target.stage == i;
      canvas.drawRect(
          r,
          Paint()
            ..color = _kStageDefs[i].tint.withValues(alpha: lit ? 0.22 : 0.10));
      if (i > 0) {
        canvas.drawLine(
          Offset(colW * i, top + 4),
          Offset(colW * i, top + h - 4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.06)
            ..strokeWidth = 1,
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kTubeEdge,
    );

    // Exit glow at the far right (fully-processed food leaves here).
    canvas.drawCircle(
      Offset(size.width - 4, top + h / 2),
      14,
      Paint()
        ..color = _kStageDefs[4].tint.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _paintStageLabel(
      Canvas canvas, int i, double cx, double top, bool lit) {
    final def = _kStageDefs[i];
    final color = lit ? _kReady : def.tint.withValues(alpha: 0.85);
    _icon(canvas, def.icon, Offset(cx - 24, top + 11), 15, color);
    _text(canvas, def.name, Offset(cx + 3, top + 6),
        size: 9.5, color: color, align: 0, bold: true);
    // The organ NAME teaches what it needs — no stage numbers, semantic recall.
    _text(canvas, lit ? 'NEEDS…' : '', Offset(cx + 3, top + 19),
        size: 8, color: _kReady.withValues(alpha: 0.85), align: 0, bold: true);
  }

  void _paintBolus(
      Canvas canvas, _Bolus b, double colW, double midY, bool isTarget) {
    final cx = colW * (b.stage + 0.5) + b.slide * colW;
    final bob = math.sin(s._bgClock * 3 + b.bobPhase) * 3;
    final center = Offset(cx, midY + bob);
    final color = _kFoodColors[b.kind];
    final radius = math.min(colW * 0.26, 20.0);

    if (b.ready) {
      final pulse = 0.5 + 0.5 * math.sin(s._bgClock * 6 + b.bobPhase);
      canvas.drawCircle(
        center,
        radius + 6 + pulse * 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _kReady.withValues(alpha: 0.5 + 0.4 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    GameFx.orb(canvas, center, radius, color, glow: b.ready ? 1.0 : 0.5);

    // Ripening ring sweeps as the organ does its work (chew/churn beat).
    if (!b.moving && b.ripe < 1.0) {
      final rect = Rect.fromCircle(center: center, radius: radius + 4);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * b.ripe,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    // Target bracket — the bolus the next verb press will act on.
    if (isTarget) {
      final r = radius + 9;
      final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 5);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = _kReady.withValues(alpha: pulse);
      for (final sx in [-1.0, 1.0]) {
        for (final sy in [-1.0, 1.0]) {
          final corner = center.translate(sx * r, sy * r);
          canvas.drawLine(corner, corner.translate(-sx * 7, 0), paint);
          canvas.drawLine(corner, corner.translate(0, -sy * 7), paint);
        }
      }
    }
  }

  /// A soft beam from the target down to the verb bar — links the food you must
  /// act on with the controls below (collapses the v1 cross-row mapping cost).
  void _paintTargetLink(
      Canvas canvas, _Bolus target, double colW, double footerTop) {
    final top = s._bolusPos(target).translate(0, 24);
    final bottom = Offset(top.dx, footerTop - 2);
    canvas.drawLine(
      top,
      bottom,
      Paint()
        ..color = _kReady.withValues(alpha: 0.22)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    _text(canvas, '↓ ACT', Offset(top.dx, (top.dy + bottom.dy) / 2),
        size: 9, color: _kReady.withValues(alpha: 0.6), align: 0, bold: true);
  }

  void _paintVerb(Canvas canvas, int i, double cx, double top, double colW) {
    final def = _kStageDefs[i];
    final shake = s._shake[i] > 0
        ? (s._rng.nextDouble() - 0.5) * 5 * s._shake[i]
        : 0.0;
    final denying = s._shake[i] > 0.05;
    final base = denying ? _kDeny : def.tint;
    final w = colW * 0.86;
    final rect = Rect.fromCenter(
        center: Offset(cx + shake, top + _DigestV2GameState._kFooterH * 0.5),
        width: w,
        height: 54);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(rr, Paint()..color = base.withValues(alpha: 0.14));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = base.withValues(alpha: denying ? 0.9 : 0.45),
    );

    final txt = denying ? _kDeny : Colors.white.withValues(alpha: 0.82);
    _icon(canvas, def.icon, Offset(cx + shake, top + 19), 17, txt);
    _text(canvas, def.action, Offset(cx + shake, top + 42),
        size: 8.5, color: txt, align: 0, bold: true);
  }

  void _paintReadyHint(Canvas canvas, Size size, double footerTop) {
    _text(
      canvas,
      'Food glows when ready — press the action ITS ORGAN needs (match the icon)',
      Offset(size.width / 2, footerTop - 22),
      size: 10.5,
      color: Colors.white.withValues(alpha: 0.5),
      align: 0,
      bold: true,
    );
  }

  void _paintPop(Canvas canvas, FxPop p) {
    _text(canvas, p.text, p.pos,
        size: 13,
        color: p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
        align: 0,
        bold: true);
  }

  // ── Draw helpers ────────────────────────────────────────────────────────────
  void _icon(
      Canvas canvas, IconData icon, Offset center, double sz, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// [align]: -1 left, 0 centre, 1 right (relative to [at]).
  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required Color color,
      int align = 0,
      bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == 0 ? -tp.width / 2 : (align < 0 ? 0.0 : -tp.width);
    tp.paint(canvas, at + Offset(dx, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DigestV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components,
// palette and primitives the live game uses (tube segments, organ icons, ripe
// boluses, verb buttons). Static + cheap: they render once on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

void _legIcon(
    Canvas canvas, IconData icon, Offset center, double sz, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: sz,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

void _legText(Canvas canvas, String text, Offset at, double size, Color color,
    {int align = 0}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = align == 0 ? -tp.width / 2 : (align < 0 ? 0.0 : -tp.width);
  tp.paint(canvas, at + Offset(dx, -tp.height / 2));
}

/// The five-organ tract with per-organ tints — the same tube the game draws.
void _legTube(Canvas canvas, Size size, double top, double h) {
  final colW = size.width / _kStages;
  final rr = RRect.fromRectAndRadius(
    Rect.fromLTWH(6, top, size.width - 12, h),
    Radius.circular(h * 0.42),
  );
  canvas.drawRRect(rr, Paint()..color = _kTube);
  canvas.save();
  canvas.clipRRect(rr);
  for (var i = 0; i < _kStages; i++) {
    canvas.drawRect(
      Rect.fromLTWH(colW * i, top, colW, h),
      Paint()..color = _kStageDefs[i].tint.withValues(alpha: 0.14),
    );
    if (i > 0) {
      canvas.drawLine(
        Offset(colW * i, top + 4),
        Offset(colW * i, top + h - 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }
  }
  canvas.restore();
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kTubeEdge,
  );
}

/// One morsel — a food orb, gold halo + ripening ring when [ready].
void _legBolus(Canvas canvas, Offset center, int kind,
    {bool ready = false, double radius = 16}) {
  if (ready) {
    canvas.drawCircle(
      center,
      radius + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kReady.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
  GameFx.orb(canvas, center, radius, _kFoodColors[kind % _kFoodColors.length],
      glow: ready ? 1.0 : 0.5);
  if (ready) {
    // The completed ripening ring (the organ's work is done).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }
}

/// A verb button — same tinted pill the footer draws; [deny] paints it red.
void _legVerb(Canvas canvas, Rect rect, _StageDef def, {bool deny = false}) {
  final base = deny ? _kDeny : def.tint;
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = base.withValues(alpha: 0.14));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = base.withValues(alpha: deny ? 0.9 : 0.5),
  );
  final txt = deny ? _kDeny : Colors.white.withValues(alpha: 0.85);
  _legIcon(canvas, def.icon, rect.center.translate(0, -8), 17, txt);
  _legText(canvas, def.action, rect.center.translate(0, 14), 8.5, txt);
}

// (a) The core object + verbs: food rides five organs, each a different job.
void _legendTract(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final top = size.height * 0.42;
  final h = math.max(26.0, size.height * 0.24);
  final colW = size.width / _kStages;
  for (var i = 0; i < _kStages; i++) {
    final cx = colW * (i + 0.5);
    _legIcon(canvas, _kStageDefs[i].icon, Offset(cx, top - 26), 15,
        _kStageDefs[i].tint);
    _legText(canvas, _kStageDefs[i].name, Offset(cx, top - 8), 7.5,
        _kStageDefs[i].tint.withValues(alpha: 0.9));
  }
  _legTube(canvas, size, top, h);
  _legBolus(canvas, Offset(colW * 0.5, top + h / 2), 0,
      radius: math.min(colW * 0.26, 16));
  // Exit glow at the far right — fully-processed food leaves here.
  canvas.drawCircle(
    Offset(size.width - 4, top + h / 2),
    14,
    Paint()
      ..color = _kStageDefs[4].tint.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
}

// (b) How to score: a ripe morsel + the matching verb its organ needs.
void _legendMatch(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final cx = size.width * 0.5;
  final def = _kStageDefs[2]; // STOMACH · CHURN
  _legIcon(canvas, def.icon, Offset(cx - 34, size.height * 0.18), 16, _kReady);
  _legText(canvas, def.name, Offset(cx + 4, size.height * 0.18), 11, _kReady,
      align: -1);
  final bc = Offset(cx, size.height * 0.44);
  _legBolus(canvas, bc, 0, ready: true, radius: 18);
  // Beam linking the ripe morsel to the verb it needs.
  final barTop = size.height * 0.72;
  canvas.drawLine(
    bc.translate(0, 26),
    Offset(cx, barTop - 6),
    Paint()
      ..color = _kReady.withValues(alpha: 0.28)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  _legText(canvas, '↓ ACT', Offset(cx, (bc.dy + barTop) / 2 + 8), 9,
      _kReady.withValues(alpha: 0.7));
  _legVerb(
    canvas,
    Rect.fromCenter(
        center: Offset(cx, barTop + 26),
        width: math.min(size.width * 0.42, 150),
        height: 50),
    def,
  );
}

// (c) The danger: the wrong verb stalls the food and breaks the combo.
void _legendWrong(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final cx = size.width * 0.5;
  final bc = Offset(cx, size.height * 0.36);
  _legBolus(canvas, bc, 1, ready: true, radius: 18);
  _legText(canvas, 'WRONG · STOMACH', bc.translate(0, -32), 10.5, _kDeny);
  final barTop = size.height * 0.70;
  _legVerb(
    canvas,
    Rect.fromCenter(
        center: Offset(cx, barTop + 24),
        width: math.min(size.width * 0.42, 150),
        height: 50),
    _kStageDefs[4], // WATER pressed on a stomach morsel — wrong verb
    deny: true,
  );
  _legText(canvas, 'COMBO BROKEN', Offset(cx, size.height * 0.92), 9.5,
      _kDeny.withValues(alpha: 0.85));
}

// (d) The escalation: late game rides five ripe morsels — recall all five.
void _legendClimax(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final top = size.height * 0.20;
  final h = math.max(22.0, size.height * 0.20);
  final colW = size.width / _kStages;
  _legTube(canvas, size, top, h);
  for (var i = 0; i < _kStages; i++) {
    _legBolus(canvas, Offset(colW * (i + 0.5), top + h / 2), i,
        ready: true, radius: math.min(colW * 0.22, 12));
  }
  final barTop = size.height * 0.64;
  for (var i = 0; i < _kStages; i++) {
    _legVerb(
      canvas,
      Rect.fromCenter(
          center: Offset(colW * (i + 0.5), barTop + 24),
          width: colW * 0.86,
          height: 46),
      _kStageDefs[i],
    );
  }
}

/// The visual manual for Digest v2 — wired into the registry spec.
final List<LegendFrame> digestV2LegendFrames = [
  const LegendFrame(
      caption: 'Food rides five organs: mouth to large intestine',
      paint: _legendTract),
  const LegendFrame(
      caption: "Match the verb to the ripe organ's icon to score",
      paint: _legendMatch),
  const LegendFrame(
      caption: 'Wrong verb stalls the food and breaks your combo',
      paint: _legendWrong),
  const LegendFrame(
      caption: 'Late game: five morsels ripe — recall all five verbs',
      paint: _legendClimax),
];
