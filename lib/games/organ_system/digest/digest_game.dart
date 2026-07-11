import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../fx.dart';
import '../../mini_game.dart';

/// Digest — "Route the Bolus".
///
/// A morsel of food (a *bolus*) travels the digestive tract left→right through
/// five stages:
///   MOUTH → ESOPHAGUS → STOMACH → SMALL INTESTINE → LARGE INTESTINE.
/// Each stage does a different job, so each needs a different ACTION at the
/// right moment:
///   • MOUTH — CHEW (break the food down)
///   • ESOPHAGUS — SWALLOW (push it down)
///   • STOMACH — CHURN (mash it with acid)
///   • SMALL INTESTINE — ABSORB NUTRIENTS (where almost all nutrients enter the blood)
///   • LARGE INTESTINE — ABSORB WATER (reclaim water before the rest is expelled)
///
/// Five action buttons sit under the tract, one per stage. A bolus has to
/// finish its stage's work first — it *ripens* (chewing/churning takes a beat)
/// and only then glows ready. Press the matching action while it glows and the
/// bolus advances; nutrients (small intestine) and water (large intestine)
/// absorbed at the correct stage score big. Press too early, press an empty
/// stage, or press the wrong action and it's a MIS-ACTION — the bolus stalls
/// and the streak breaks. A stage can hold only one bolus, so you must clear
/// the FRONT of the tract first or new food backs up (the pipeline lesson).
///
/// Accelerates: food arrives faster and ripens faster, so up to five boluses
/// ride the tract at once and you juggle every stage.
///
/// Score = food processed + nutrients & water absorbed at the right stage.
/// The host owns the clock, 3-2-1 countdown, score HUD and results; this widget
/// renders only the play area and reports through the session.
class DigestGame extends StatefulWidget {
  final MiniGameSession session;
  const DigestGame({super.key, required this.session});

  @override
  State<DigestGame> createState() => _DigestGameState();
}

// ── Tuning (all in one place; play-test freely) ───────────────────────────────
const int _kStages = 5;

/// Intake interval (seconds between new boluses) ramps fast → frantic.
const double _kIntakeStart = 2.3;
const double _kIntakePeak = 0.95;

/// How long a bolus takes to ripen at a stage (the chew/churn beat). Shrinks
/// over the round so late food is ready almost at once.
const double _kRipenStart = 0.85;
const double _kRipenPeak = 0.48;

/// Slide animation when a bolus moves to the next stage (seconds).
const double _kMoveTime = 0.28;

/// Points awarded for completing each stage's action. Absorption stages pay the
/// most — that is where the body actually gains nutrients and water.
const List<int> _kStagePoints = [4, 4, 6, 16, 10];

/// Bonus when a bolus exits the large intestine fully processed.
const int _kCompleteBonus = 8;

/// Height of the always-visible top header band (objective line + nutrient
/// meter). Everything below (stage labels, tube) is laid out under it.
const double _kHeaderH = 38.0;

// ── Palette (digestive tract) ─────────────────────────────────────────────────
const Color _kBg = Potatuhs.inkDeep;
const Color _kTube = Color(0xFF2C201C);
const Color _kTubeEdge = Color(0xFF44322B);
const Color _kReady = Color(0xFFE1C916); // gold = ripe / actionable
const Color _kDeny = Color(0xFFE2574B); // red = mis-action
const Color _kBlock = Color(0xFFE19816); // sienna = downstream full
const String _kFont = Potatuhs.bodyFont;

class _StageDef {
  final String name;
  final String action;
  final IconData icon;
  final Color tint;
  const _StageDef(this.name, this.action, this.icon, this.tint);
}

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
  int stage; // 0..4 current stage (target stage while moving)
  double ripe; // 0..1 readiness at this stage
  double slide; // -1 → 0 while sliding from previous stage into [stage]
  bool moving;
  final double bobPhase;
  final int kind;
  _Bolus(this.stage, this.kind, this.bobPhase)
      : ripe = 0,
        slide = 0,
        moving = false;

  bool get ready => !moving && ripe >= 1.0;
}

/// A fading ghost dot left behind a sliding bolus — cheap "rush" motion trail.
class _Trail {
  Offset pos;
  final Color color;
  final double radius;
  double life = 1.0;
  _Trail(this.pos, this.color, this.radius);
  bool step(double dt) {
    life -= dt / 0.35;
    return life > 0;
  }
}

class _DigestGameState extends State<DigestGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  final List<_Bolus> _boluses = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // Per-button shake feedback on a denied press (mis-action / blocked).
  final List<double> _shake = List<double>.filled(_kStages, 0);

  double _elapsed = 0; // seconds in the playing phase
  double _intakeT = _kIntakeStart; // countdown to next bolus
  int _streak = 0;
  double _bgClock = 0; // atmosphere drift
  int _kindCounter = 0;
  double _idleT = 0; // idle auto-advance timer

  // ── Feedback / juice state ────────────────────────────────────────────────
  /// Nutrient meter (0..1): fills on correct actions (esp. absorption), drains
  /// slowly. A live "am I winning?" gauge, independent of the host score HUD.
  double _nutrient = 0;
  /// Green success flash (1→0) painted on a correct action; red on a mis-action.
  double _goodFlash = 0;
  double _badFlash = 0;
  /// Streak-pulse ring under the bolus that just advanced (1→0).
  double _streakPulse = 0;
  /// Objective/how-to banner opacity. Starts fully visible; fades after the
  /// player's first correct action so the biology reads, then gets out of
  /// the way (WarioWare-style teach-then-vanish).
  double _hintAlpha = 1.0;
  bool _actedOnce = false;
  int _processed = 0; // boluses fully processed (exited large intestine)
  /// Micro "rush" trail spawned behind a sliding bolus for a sense of motion.
  final List<_Trail> _trails = [];

  // Last layout, for hit-testing taps → button index.
  double _w = 1, _h = 1;
  double _footerTop = 0;

  double get _duration =>
      widget.session.spec.durationSeconds.toDouble().clamp(1, 600);

  @override
  void initState() {
    super.initState();
    // Seed one morsel so the calm pre-round preview reads as a live tract.
    _boluses.add(_Bolus(0, 0, _rng.nextDouble() * 6));
    // ATTRACT autopilot: this game knows how to route the tract itself. The
    // host calls [_autoStep] ~4×/s only in autoplay; harmless in normal play.
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One correct hands-free move per host tick (~250ms). Plays Digest the way
  /// the game intends: it advances the most DOWNSTREAM ready bolus whose exit
  /// is clear — clearing the front of the pipeline first — via the game's own
  /// [_press] handler. It only ever presses a stage that holds a ripe bolus
  /// that can actually move (last stage always exits; any other stage only if
  /// the next stage is free), so it never triggers a mis-action or a FULL
  /// block. If no bolus is ready to move, it does nothing this tick.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    _Bolus? best;
    for (final b in _boluses) {
      if (!b.ready) continue;
      // Last stage always exits; otherwise the next stage must be clear.
      final canMove = b.stage >= _kStages - 1 ||
          !_stageOccupied(b.stage + 1, except: b);
      if (!canMove) continue;
      if (best == null || b.stage > best.stage) best = b;
    }
    if (best == null) return; // nothing ripe & unblocked; wait for the tract
    _press(best.stage);
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
    // Feedback flashes decay.
    _goodFlash = math.max(0, _goodFlash - dt * 2.6);
    _badFlash = math.max(0, _badFlash - dt * 3.2);
    _streakPulse = math.max(0, _streakPulse - dt * 2.4);
    // Objective banner fades out once the player has acted correctly.
    if (_actedOnce) _hintAlpha = math.max(0, _hintAlpha - dt * 0.9);
    // Nutrient meter drains slowly (keep processing to keep it up).
    if (widget.session.isRunning) {
      _nutrient = math.max(0, _nutrient - dt * 0.05);
    }
    // Advance moving boluses (shared by play + idle). Leave a rush trail.
    for (final b in _boluses) {
      if (b.moving) {
        final beforeCx = b.stage + 0.5 + b.slide;
        b.slide += dt / _kMoveTime;
        if (b.slide >= 0) {
          b.slide = 0;
          b.moving = false;
          b.ripe = 0;
        }
        // Spawn a faint trail dot at the previous position (in stage units;
        // converted to px in the painter frame is overkill — store px here).
        final colW = _w / _kStages;
        _trails.add(_Trail(
          Offset(colW * beforeCx, _midY()),
          _kFoodColors[b.kind],
          math.min(colW * 0.2, 15.0),
        ));
      }
    }
    _trails.removeWhere((t) => !t.step(dt));
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

    // Ripen every settled bolus.
    for (final b in _boluses) {
      if (!b.moving && b.ripe < 1.0) {
        b.ripe = math.min(1.0, b.ripe + dt / ripen);
      }
    }

    // Intake new food at the mouth — only if the mouth is clear.
    _intakeT -= dt;
    if (_intakeT <= 0) {
      final interval = _kIntakeStart + (_kIntakePeak - _kIntakeStart) * p;
      _intakeT = interval;
      if (!_stageOccupied(0)) {
        _boluses.add(_Bolus(0, _kindCounter++ % _kFoodColors.length,
            _rng.nextDouble() * 6));
      }
    }
  }

  void _idle(double dt) {
    // Calm preview: a single morsel ripens, drifts stage→stage on a slow timer
    // and recycles at the end. No scoring.
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
        _boluses.add(_Bolus(0, _kindCounter++ % _kFoodColors.length,
            _rng.nextDouble() * 6));
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
    if (local.dy < _footerTop) return; // only the action buttons act
    final colW = _w / _kStages;
    final i = (local.dx / colW).floor().clamp(0, _kStages - 1);
    _press(i);
  }

  void _press(int i) {
    final colW = _w / _kStages;
    final buttonCenter = Offset(colW * (i + 0.5), _footerTop + 30);

    // The actionable bolus is the ripe one sitting at this stage.
    _Bolus? ripe;
    _Bolus? unripe;
    for (final b in _boluses) {
      if (b.stage == i && !b.moving) {
        if (b.ready) {
          ripe = b;
        } else {
          unripe = b;
        }
      }
    }

    if (ripe != null) {
      _advance(ripe);
      return;
    }

    // Mis-action.
    _shake[i] = 1.0;
    _badFlash = 1.0;
    if (unripe != null) {
      // Acted too soon — the stage's work isn't finished. It stalls.
      unripe.ripe = math.max(0, unripe.ripe - 0.4);
      _pops.add(FxPop(buttonCenter, 'TOO SOON', _kDeny));
    } else {
      _pops.add(FxPop(buttonCenter, 'NOTHING HERE', _kDeny));
    }
    _streak = 0;
  }

  void _advance(_Bolus b) {
    final i = b.stage;
    final colW = _w / _kStages;
    final at = Offset(colW * (i + 0.5), _midY());

    if (i >= _kStages - 1) {
      // Large intestine: absorb water + the bolus exits fully processed.
      var pts = _kStagePoints[i] + _kCompleteBonus;
      pts += _streakBonus();
      widget.session.addScore(pts);
      _onGood();
      _processed += 1;
      _nutrient = math.min(1.0, _nutrient + 0.16); // water reclaim tops it up
      _boluses.remove(b);
      _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: 22));
      _particles.addAll(FxBurst.spawn(at, _kReady, count: 10, speed: 180));
      _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'PROCESSED +$pts', _kReady));
      return;
    }

    if (_stageOccupied(i + 1, except: b)) {
      // Downstream stage is full — can't move yet. Clear the front first.
      _shake[i + 1] = 1.0;
      _badFlash = math.max(_badFlash, 0.6);
      _pops.add(FxPop(Offset(colW * (i + 1.5), _midY() - 16), 'FULL', _kBlock));
      return;
    }

    var pts = _kStagePoints[i];
    pts += _streakBonus();
    widget.session.addScore(pts);
    _onGood();
    // Absorption stages feed the nutrient meter hardest — that's the lesson.
    _nutrient = math.min(1.0, _nutrient + (i == 3 ? 0.22 : 0.06));
    b.stage = i + 1;
    b.slide = -1;
    b.moving = true;
    b.ripe = 0;
    final burstCount = 9 + (_streak.clamp(0, 8));
    _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: burstCount));
    final label = i == 3 ? 'NUTRIENTS +$pts' : '+$pts';
    _pops.add(FxPop(Offset(at.dx, at.dy - 16), label,
        i == 3 ? _kStageDefs[3].tint : _kReady));
  }

  /// Consecutive-correct bonus so a hot streak visibly compounds the score.
  int _streakBonus() => (_streak.clamp(0, 10) ~/ 2);

  /// Shared bookkeeping for any correct action: streak, juice, hint-fade.
  void _onGood() {
    _streak += 1;
    widget.session.noteStreak(_streak);
    _goodFlash = 1.0;
    _streakPulse = 1.0;
    if (!_actedOnce) {
      _actedOnce = true; // begins the objective-banner fade
    }
  }

  double _midY() {
    const labelTop = _kHeaderH + 6;
    const tubeTop = labelTop + 34 + 6;
    final tubeBottom = _footerTop - 10;
    return (tubeTop + tubeBottom) / 2;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      _footerTop = _h - 64;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tapAt(d.localPosition),
        child: CustomPaint(
          size: Size(_w, _h),
          painter: _DigestPainter(this),
        ),
      );
    });
  }
}

class _DigestPainter extends CustomPainter {
  final _DigestGameState s;
  _DigestPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final running = s.widget.session.isRunning;
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    GameFx.atmosphere(canvas, size, _kStageDefs[2].tint, s._bgClock, motes: 22);

    final colW = size.width / _kStages;
    const labelTop = _kHeaderH + 6;
    const labelH = 34.0;
    final footerTop = size.height - 64;
    const tubeTop = labelTop + labelH + 6;
    final tubeBottom = footerTop - 10;
    final tubeMid = (tubeTop + tubeBottom) / 2;
    final tubeH = math.max(28.0, tubeBottom - tubeTop);

    _paintHeader(canvas, size); // always-visible objective + nutrient meter
    _paintTube(canvas, size, tubeTop, tubeH, colW);

    for (var i = 0; i < _kStages; i++) {
      _paintStageLabel(canvas, i, colW * (i + 0.5), labelTop, colW);
    }

    // Rush trails ride under the food.
    for (final t in s._trails) {
      canvas.drawCircle(
        t.pos,
        t.radius * (0.5 + 0.5 * t.life),
        Paint()
          ..color = t.color.withValues(alpha: 0.28 * t.life)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Food rides the tract.
    for (final b in s._boluses) {
      _paintBolus(canvas, b, colW, tubeMid);
    }

    FxBurst.paint(canvas, s._particles);

    for (var i = 0; i < _kStages; i++) {
      _paintButton(canvas, i, colW * (i + 0.5), footerTop, colW);
    }

    // Always-visible in-context how-to; fades out after the first correct act.
    _paintHowTo(canvas, size, footerTop, running);

    for (final p in s._pops) {
      _paintPop(canvas, p);
    }

    // Screen-edge success/failure flashes (subtle vignette).
    _paintFlash(canvas, size);
  }

  // ── Header: ALWAYS-VISIBLE objective + nutrient meter + streak ───────────────
  void _paintHeader(Canvas canvas, Size size) {
    // The one-line objective — the first thing the player reads, always on.
    final objective = s._processed > 0
        ? 'FEED THE BODY · ${s._processed} processed'
        : 'FEED THE BODY: glow → tap that organ\'s action';
    _text(canvas, objective, const Offset(14, 11),
        size: 10.5,
        color: Colors.white.withValues(alpha: 0.62),
        align: -1,
        bold: true);

    // Streak badge (right).
    if (s._streak >= 3) {
      final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 8);
      _text(canvas, 'STREAK ${s._streak}  +${s._streakBonus()}',
          Offset(size.width - 14, 11),
          size: 11.5,
          color: Color.lerp(_kReady, Colors.white, s._streakPulse * 0.6 * pulse)!,
          align: 1,
          bold: true);
    }

    // NUTRIENT METER — a live gauge of how well you're feeding the body.
    const barLeft = 14.0;
    final barRight = size.width - 14.0;
    const barY = 30.0;
    final barW = barRight - barLeft;
    const trackH = 6.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barY, barW, trackH),
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final fillW = (barW * s._nutrient).clamp(0.0, barW);
    if (fillW > 1) {
      final fillRect = Rect.fromLTWH(barLeft, barY, fillW, trackH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(colors: [
            _kStageDefs[3].tint, // nutrients green
            _kReady, // gold
          ]).createShader(fillRect),
      );
      // Leading glow bead.
      canvas.drawCircle(
        Offset(barLeft + fillW, barY + trackH / 2),
        4,
        Paint()
          ..color = _kReady.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    _text(canvas, 'NUTRIENT', const Offset(barLeft, barY - 8),
        size: 7.5, color: _kStageDefs[3].tint.withValues(alpha: 0.75),
        align: -1, bold: true);
  }

  // ── The tract tube + per-stage tinted zones ─────────────────────────────────
  void _paintTube(
      Canvas canvas, Size size, double top, double h, double colW) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, top, size.width - 12, h),
      Radius.circular(h * 0.42),
    );
    canvas.drawRRect(rr, Paint()..color = _kTube);

    // Tinted stage zones inside the tube so colour teaches where you are.
    canvas.save();
    canvas.clipRRect(rr);
    for (var i = 0; i < _kStages; i++) {
      final r = Rect.fromLTWH(colW * i, top, colW, h);
      canvas.drawRect(
          r, Paint()..color = _kStageDefs[i].tint.withValues(alpha: 0.10));
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

  // ── Stage label: icon + name + action ───────────────────────────────────────
  void _paintStageLabel(
      Canvas canvas, int i, double cx, double top, double colW) {
    final def = _kStageDefs[i];
    final active = s._boluses.any((b) => b.stage == i && b.ready);
    final color = active ? _kReady : def.tint.withValues(alpha: 0.85);
    _icon(canvas, def.icon, Offset(cx - 22, top + 11), 15, color);
    _text(canvas, def.name, Offset(cx + 4, top + 6),
        size: 9.5, color: color, align: 0, bold: true);
    _text(canvas, def.action, Offset(cx + 4, top + 19),
        size: 8,
        color: Colors.white.withValues(alpha: active ? 0.7 : 0.32),
        align: 0,
        bold: true);
  }

  // ── A bolus (food morsel) ───────────────────────────────────────────────────
  void _paintBolus(Canvas canvas, _Bolus b, double colW, double midY) {
    final cx = colW * (b.stage + 0.5) + b.slide * colW;
    final bob = math.sin(s._bgClock * 3 + b.bobPhase) * 3;
    final center = Offset(cx, midY + bob);
    final color = _kFoodColors[b.kind];
    final radius = math.min(colW * 0.26, 20.0);

    // Ready halo — gold pulse invites the matching action.
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

    // Ripening ring sweeps as the stage does its work (chew/churn beat).
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
  }

  // ── Action button (footer) ──────────────────────────────────────────────────
  void _paintButton(
      Canvas canvas, int i, double cx, double top, double colW) {
    final def = _kStageDefs[i];
    final active = s._boluses.any((b) => b.stage == i && b.ready);
    final shake = s._shake[i] > 0
        ? (s._rng.nextDouble() - 0.5) * 5 * s._shake[i]
        : 0.0;
    final w = colW * 0.84;
    final rect = Rect.fromCenter(
        center: Offset(cx + shake, top + 30), width: w, height: 46);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final denying = s._shake[i] > 0.05;
    final baseColor = denying ? _kDeny : def.tint;

    canvas.drawRRect(
      rr,
      Paint()
        ..color = (active ? _kReady : baseColor)
            .withValues(alpha: active ? 0.22 : 0.12),
    );
    if (active) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _kReady
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (active ? _kReady : baseColor)
            .withValues(alpha: active ? 0.9 : 0.4),
    );

    final txtColor = active ? _kReady : Colors.white.withValues(alpha: 0.7);
    _icon(canvas, def.icon, Offset(cx + shake, top + 22), 16, txtColor);
    _text(canvas, def.action, Offset(cx + shake, top + 40),
        size: 8.5, color: txtColor, align: 0, bold: true);
  }

  /// In-context how-to. Full strength before the round and until the player's
  /// first correct action, then fades away (WarioWare teach-then-vanish). A
  /// pointer nudges the currently-ready stage so the control is unmissable.
  void _paintHowTo(Canvas canvas, Size size, double footerTop, bool running) {
    final a = running ? s._hintAlpha : 1.0;
    if (a <= 0.01) return;

    // Highlight arrow over a ready stage's button (points at what to press).
    final colW = size.width / _kStages;
    for (var i = 0; i < _kStages; i++) {
      final ready = s._boluses.any((b) => b.stage == i && b.ready);
      if (!ready) continue;
      final cx = colW * (i + 0.5);
      final bob = math.sin(s._bgClock * 5) * 3;
      final tip = Offset(cx, footerTop + 4 + bob);
      final path = Path()
        ..moveTo(tip.dx - 7, tip.dy - 8)
        ..lineTo(tip.dx + 7, tip.dy - 8)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _kReady.withValues(alpha: 0.85 * a));
      _text(canvas, 'TAP!', Offset(cx, footerTop - 12),
          size: 9, color: _kReady.withValues(alpha: a), align: 0, bold: true);
      break;
    }

    _text(
      canvas,
      running
          ? 'Wait for a morsel to GLOW GOLD, then tap that organ\'s button'
          : 'Route food through 5 organs — glow, then tap · clear the FRONT first',
      Offset(size.width / 2, footerTop - 24),
      size: 10.5,
      color: Colors.white.withValues(alpha: 0.55 * a),
      align: 0,
      bold: true,
    );
  }

  /// Soft full-screen success (green) / failure (red) vignette flash.
  void _paintFlash(Canvas canvas, Size size) {
    final good = s._goodFlash;
    final bad = s._badFlash;
    if (good <= 0.01 && bad <= 0.01) return;
    final color = bad > good ? _kDeny : _kStageDefs[3].tint;
    final strength = math.max(good, bad);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.16 * strength),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
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
  bool shouldRepaint(covariant _DigestPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components the
// live game uses (the tinted tract tube, a glowing bolus orb, the action
// buttons). Static + cheap: rendered once on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

void _lgText(Canvas canvas, String text, Offset at, double size, Color color,
    {int align = 0, bool bold = true}) {
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

void _lgIcon(
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

/// One food morsel — the real bolus orb, optionally ripe (gold halo) or with a
/// sweeping ripen ring.
void _lgBolus(Canvas canvas, Offset center, double radius, Color color,
    {bool ready = false, double ripe = 1.0}) {
  if (ready) {
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kReady.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
  GameFx.orb(canvas, center, radius, color, glow: ready ? 1.0 : 0.5);
  if (!ready && ripe < 1.0) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      -math.pi / 2,
      2 * math.pi * ripe,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }
}

/// The tract tube with the five tinted stage zones — same look as the game.
void _lgTube(Canvas canvas, Rect r) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.42));
  canvas.drawRRect(rr, Paint()..color = _kTube);
  final colW = r.width / _kStages;
  canvas.save();
  canvas.clipRRect(rr);
  for (var i = 0; i < _kStages; i++) {
    canvas.drawRect(
      Rect.fromLTWH(r.left + colW * i, r.top, colW, r.height),
      Paint()..color = _kStageDefs[i].tint.withValues(alpha: 0.16),
    );
    if (i > 0) {
      canvas.drawLine(
        Offset(r.left + colW * i, r.top + 4),
        Offset(r.left + colW * i, r.bottom - 4),
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

/// One footer action button — the real lit/idle look from the game.
void _lgButton(Canvas canvas, Rect rect, _StageDef def, {bool active = false}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  final base = active ? _kReady : def.tint;
  canvas.drawRRect(
    rr,
    Paint()..color = base.withValues(alpha: active ? 0.22 : 0.12),
  );
  if (active) {
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _kReady
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = base.withValues(alpha: active ? 0.9 : 0.4),
  );
  final txt = active ? _kReady : Colors.white.withValues(alpha: 0.75);
  _lgIcon(canvas, def.icon, Offset(rect.center.dx, rect.top + 15), 16, txt);
  _lgText(canvas, def.action, Offset(rect.center.dx, rect.bottom - 9), 8.5, txt);
}

// Frame 1 — the tract: five tinted organ stages, a bolus riding left→right.
void _legendTract(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final colW = size.width / _kStages;
  final labelTop = size.height * 0.20;
  // Stage icons + names above the tube.
  for (var i = 0; i < _kStages; i++) {
    final cx = colW * (i + 0.5);
    final def = _kStageDefs[i];
    _lgIcon(canvas, def.icon, Offset(cx, labelTop), 15, def.tint);
    _lgText(canvas, def.name, Offset(cx, labelTop + 16), 8, def.tint);
  }
  final tubeH = math.max(24.0, size.height * 0.24);
  final tubeTop = size.height * 0.46;
  _lgTube(canvas, Rect.fromLTWH(6, tubeTop, size.width - 12, tubeH));
  final midY = tubeTop + tubeH / 2;
  final r = math.min(colW * 0.24, 18.0);
  // A morsel riding the tract, with a motion trail toward the exit.
  for (var i = 0; i < 3; i++) {
    final cx = colW * (1.2 + i * 0.5);
    _lgBolus(canvas, Offset(cx, midY), r,
        _kFoodColors[i % _kFoodColors.length],
        ready: i == 2);
  }
  _lgText(canvas, 'left  →  right', Offset(size.width / 2, size.height * 0.88),
      9.5, Colors.white.withValues(alpha: 0.5));
}

// Frame 2 — the core loop: food ripens, glows gold, tap its action.
void _legendRipen(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final cx = size.width / 2;
  final r = math.min(size.width * 0.14, 26.0);
  // Left: still ripening (ring sweep). Right: ripe + gold halo.
  _lgBolus(canvas, Offset(size.width * 0.30, size.height * 0.34), r,
      _kFoodColors[0],
      ready: false, ripe: 0.6);
  _lgText(canvas, 'RIPENING', Offset(size.width * 0.30, size.height * 0.60),
      8.5, Colors.white.withValues(alpha: 0.55));
  _lgBolus(canvas, Offset(size.width * 0.70, size.height * 0.34), r,
      _kFoodColors[0],
      ready: true);
  _lgText(canvas, 'READY', Offset(size.width * 0.70, size.height * 0.60), 8.5,
      _kReady);
  // The lit action button below — the STOMACH's CHURN, ready to press.
  final bw = math.min(size.width * 0.4, 120.0);
  _lgButton(
    canvas,
    Rect.fromCenter(
        center: Offset(cx, size.height * 0.82), width: bw, height: 44),
    _kStageDefs[2],
    active: true,
  );
}

// Frame 3 — scoring: absorption pays most (NUTRIENTS +16, WATER +10).
void _legendAbsorb(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = math.min(size.width * 0.13, 24.0);
  final cy = size.height * 0.40;
  // Small intestine — nutrients.
  final sx = size.width * 0.30;
  _lgBolus(canvas, Offset(sx, cy), r, _kStageDefs[3].tint, ready: true);
  _lgIcon(canvas, _kStageDefs[3].icon, Offset(sx, size.height * 0.14), 15,
      _kStageDefs[3].tint);
  _lgText(canvas, 'NUTRIENTS', Offset(sx, size.height * 0.66), 9,
      _kStageDefs[3].tint);
  _lgText(canvas, '+16', Offset(sx, size.height * 0.80), 15, _kReady);
  // Large intestine — water.
  final wx = size.width * 0.70;
  _lgBolus(canvas, Offset(wx, cy), r, _kStageDefs[4].tint, ready: true);
  _lgIcon(canvas, _kStageDefs[4].icon, Offset(wx, size.height * 0.14), 15,
      _kStageDefs[4].tint);
  _lgText(canvas, 'WATER', Offset(wx, size.height * 0.66), 9,
      _kStageDefs[4].tint);
  _lgText(canvas, '+10', Offset(wx, size.height * 0.80), 15, _kReady);
}

// Frame 4 — the pipeline danger: one food per stage, a full stage jams (FULL).
void _legendJam(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final colW = size.width / _kStages;
  final tubeH = math.max(24.0, size.height * 0.30);
  final tubeTop = size.height * 0.32;
  _lgTube(canvas, Rect.fromLTWH(6, tubeTop, size.width - 12, tubeH));
  final midY = tubeTop + tubeH / 2;
  final r = math.min(colW * 0.24, 17.0);
  // Every stage occupied — the tract is backed up.
  for (var i = 0; i < _kStages; i++) {
    _lgBolus(canvas, Offset(colW * (i + 0.5), midY), r,
        _kFoodColors[i % _kFoodColors.length],
        ready: i == 0);
  }
  // A FULL block warning over the stage the front bolus is trying to enter.
  final blockX = colW * 1.5;
  _lgText(canvas, 'FULL', Offset(blockX, tubeTop - 12), 12, _kBlock);
  _lgText(
      canvas,
      'clear the FRONT first',
      Offset(size.width / 2, size.height * 0.82),
      10,
      Colors.white.withValues(alpha: 0.55));
}

/// The visual manual for Digest — wired into the registry spec.
final List<LegendFrame> digestLegendFrames = [
  const LegendFrame(
      caption: 'FEED THE BODY — route food left → right through 5 organs',
      paint: _legendTract),
  const LegendFrame(
      caption: 'Wait for food to glow gold, then tap its stage action',
      paint: _legendRipen),
  const LegendFrame(
      caption: 'Absorb NUTRIENTS (+16) then WATER (+10) — the big points',
      paint: _legendAbsorb),
  const LegendFrame(
      caption: 'One food per stage — clear the FRONT or it jams (FULL)',
      paint: _legendJam),
];
