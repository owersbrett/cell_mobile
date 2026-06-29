import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// pH Balance v2 — UX-passed rebuild of `ph_balance`.
//
// SAME LESSON (the Keep): titrate a beaker to a TARGET pH. Tapping ACID (H⁺)
// lowers pH, BASE (OH⁻) raises it. The titration curve is STEEP near pH 7 — a
// single drop near neutral leaps the needle across the equivalence point and
// slings past it, while far from 7 the liquid is "buffered" and barely moves.
// A universal-indicator color ramp (red→green→violet) and a live 0–14 scale
// teach acids, bases, and neutralization in the mechanic itself. CO₂ slowly
// acidifies the liquid (carbonic acid) — homeostasis as a verb.
//
// WHAT CHANGED vs v1 (per the UX teardown):
//   1. RESPONSIVE NEEDLE + PREDICTIVE GHOST. v1 eased the needle toward the
//      chemical pH via exp(-dt*14) so a tap's effect landed a frame late and
//      overshoot felt like input LAG, not skill. v2 lands 60% of every drop the
//      SAME frame (then settles fast), AND draws GHOST ticks on the scale
//      showing exactly where the next ACID / BASE drop would land — so the
//      steep-near-7 leap is a READ before you tap, not a surprise after. A
//      shaded STEEP zone around pH 7 makes the lesson *shown*, not just felt.
//   2. ACTIVE HOLD (no more camping). v1's optimal play once in-band was to
//      STOP touching and let a drip meter fill — the skill-tested landing was
//      followed by a do-nothing hold. v2 makes CO₂ acid-creep ALWAYS-ON: the
//      pH constantly slides down, so holding a target is sustained micro-control
//      — feather taps to keep the needle CENTRED and fill the LOCK ring. Near
//      pH 7, taps are too coarse to sit still, so you PUMP: tap, let the drift
//      sweep you through the band, tap again (dropwise titration, for real).
//   3. FAIR, CAPPED SCORE. v1 paid a passive +4/s drip for camping. v2 scores
//      each lock on THIS-attempt precision + speed only, hard-capped per lock
//      (no level or streak multiplier) → standings cluster and stay catchable.
//      Streak feeds only the mastery award via `noteStreak`.
//
// Perf: ONE Ticker → ONE CustomPainter. Taps mutate fields (no per-tap
// setState); the running ticker repaints next frame.
// ═══════════════════════════════════════════════════════════════════════════

// ── Needle response (the input-lag fix) ──────────────────────────────────────
const double _kNeedleEase = 26.0; // fast settle — feels instant, still smooth
const double _kTapSnap = 0.60; // fraction of a drop that lands THIS frame

// ── Tolerance: half-width of the target band (pH). Tightens per level. ────────
const double _kTolStart = 0.95;
const double _kTolStep = 0.07;
const double _kTolMin = 0.42;

// ── Active LOCK: centred-dwell needed to score a target (centeredness-weighted)
const double _kLockStart = 1.05; // seconds of dead-centre dwell at level 0
const double _kLockStep = 0.03;
const double _kLockMin = 0.70;
const double _kLockDecay = 1.4; // lock bleeds this×dt while out of band

// ── Drop strength: base pH delta per tap (before steepness). Grows per level. ─
const double _kDropBase = 0.075;
const double _kDropStep = 0.009;
const double _kDropMax = 0.165;

// ── Steepness of the titration curve near pH 7 (the equivalence spike). ───────
// effect = drop × (1 + steepK · gaussian(pH−7)). Grows per level.
const double _kSteepBase = 1.6;
const double _kSteepStep = 0.10;
const double _kSteepMax = 2.8;
const double _kSigma = 1.7; // width of the steep region around pH 7
// INVARIANT: max near-7 drop = _kDropMax·(1+_kSteepMax) = 0.627 < 2·_kTolMin
// (0.84) → near-neutral targets stay landable. Re-check if you raise the caps.

// ── CO₂ acid-creep — ALWAYS ON now (the active-hold driver). Grows per level. ─
const double _kDriftStart = 0.16; // pH/s downward at level 0
const double _kDriftStep = 0.03;
const double _kDriftMax = 0.55;

// ── Scoring (fair — capped, NO level/streak multiplier). ──────────────────────
const int _kScoreBase = 45; // floor for any lock
const int _kScorePrecision = 30; // max bonus for holding dead-centre
const int _kScoreSpeed = 20; // max bonus for locking fast
const int _kScoreSurge = 20; // flat climax bonus (same for everyone)
const double _kSpeedFull = 2.0; // lock within this many s → full speed bonus
const double _kSpeedZero = 6.5; // slower than this → no speed bonus

// ── Climax: last N seconds = SURGE (faster creep, tighter band, flat bonus). ──
const double _kSurgeRemaining = 12.0;
const double _kSurgeDrift = 1.5; // drift multiplier during the surge
const double _kSurgeTol = 0.85; // band multiplier during the surge (tighter)

// ── Palette ──────────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont; // 'Outfit'
const Color _kAccent = Color(0xFF3DDC97); // neutral-green, the game accent
const Color _kGlass = Color(0xFFBFE9DA);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kAcid = Color(0xFFEF5350); // acid button (red end)
const Color _kBase = Color(0xFF5E7CE2); // base button (blue end)

// Universal-indicator color ramp, one entry per integer pH 0..14.
const List<Color> _kPhColors = [
  Color(0xFFE53935), // 0  strong acid — red
  Color(0xFFEF5350), // 1
  Color(0xFFFF7043), // 2
  Color(0xFFFF9800), // 3  orange
  Color(0xFFFFB300), // 4
  Color(0xFFFDD835), // 5  yellow
  Color(0xFFD4E157), // 6  lime
  Color(0xFF66BB6A), // 7  NEUTRAL — green
  Color(0xFF26A69A), // 8  teal
  Color(0xFF29B6F6), // 9
  Color(0xFF2196F3), // 10 blue
  Color(0xFF3F51B5), // 11 indigo
  Color(0xFF5E35B1), // 12
  Color(0xFF7B1FA2), // 13 purple
  Color(0xFF6A1B9A), // 14 strong base — violet
];

Color _phColor(double ph) {
  final p = ph.clamp(0.0, 14.0);
  final i = p.floor().clamp(0, 13);
  return Color.lerp(_kPhColors[i], _kPhColors[i + 1], p - i)!;
}

/// "pH Balance v2" — titrate to the target and feather the CO₂ drift to lock it.
/// Acid/base drops swing hardest near neutral, where the titration curve is steep.
class PhBalanceV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PhBalanceV2Game({super.key, required this.session});

  @override
  State<PhBalanceV2Game> createState() => _PhBalanceV2GameState();
}

class _PhBalanceV2GameState extends State<PhBalanceV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────────
  double _ph = 7.0; // displayed needle (snappy: most of a tap lands instantly)
  double _phGoal = 7.0; // chemical pH the drops/drift set; _ph settles toward it
  double _target = 4.0; // centre of the target band
  int _level = 0; // difficulty ramp ONLY — never feeds score
  int _targetsHit = 0;
  int _streak = 0;
  bool _approached = false; // got near the band → arms overshoot detection
  bool _wasRunning = false;

  // Active-dwell lock (replaces v1's passive drip+hold).
  double _lock = 0.0; // 0..1 — fills with centred dwell, drains out of band
  double _attemptTime = 0.0; // seconds since this target was assigned
  double _centAccum = 0.0; // Σ centredness·dt while in band (precision quality)
  double _centTime = 0.0; // total time spent inside the band this attempt

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _time = 0.0; // seconds clock for wobble/bubbles
  double _greenFlash = 0.0;
  double _missFlash = 0.0;
  double _ripple = 0.0;
  final List<_Bubble> _bubbles = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // ── Per-level derived values ────────────────────────────────────────────────
  bool get _isSurge =>
      widget.session.remaining.inMilliseconds / 1000.0 <= _kSurgeRemaining;

  double get _dropStrength =>
      math.min(_kDropMax, _kDropBase + _level * _kDropStep);
  double get _steepK => math.min(_kSteepMax, _kSteepBase + _level * _kSteepStep);
  double get _lockNeed =>
      math.max(_kLockMin, _kLockStart - _level * _kLockStep);

  double get _bandHalf {
    var t = math.max(_kTolMin, _kTolStart - _level * _kTolStep);
    if (_isSurge) t *= _kSurgeTol;
    return t;
  }

  double get _driftRate {
    var d = math.min(_kDriftMax, _kDriftStart + _level * _kDriftStep);
    if (_isSurge) d *= _kSurgeDrift;
    return d;
  }

  double _steep(double ph) {
    final d = ph - 7.0;
    return 1.0 + _steepK * math.exp(-(d * d) / (2 * _kSigma * _kSigma));
  }

  // Where the next ACID / BASE tap would land (the predictive ghost).
  double get _ghostAcid =>
      (_phGoal - _dropStrength * _steep(_phGoal)).clamp(0.0, 14.0);
  double get _ghostBase =>
      (_phGoal + _dropStrength * _steep(_phGoal)).clamp(0.0, 14.0);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 7; i++) {
      _bubbles.add(_Bubble.random(_rng));
    }
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt <= 0) return;
    _time += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRound();
    _wasRunning = running;

    if (running) {
      _attemptTime += dt;
      // CO₂ acid-creep: the liquid constantly self-acidifies. THIS is what makes
      // holding active — you must keep tapping BASE to hold your ground.
      _phGoal = (_phGoal - _driftRate * dt).clamp(0.0, 14.0);
    } else {
      // Calm ready state: idle green at neutral with a gentle breath.
      _phGoal = 7.0 + 0.05 * math.sin(_time * 0.6);
    }

    // Responsive needle: settles fast toward the chemical pH (taps already
    // jumped it most of the way — see _addDrop). Feels instant, not laggy.
    _ph += (_phGoal - _ph) * (1 - math.exp(-dt * _kNeedleEase));

    if (running) {
      final err = (_ph - _target).abs();
      final inBand = err <= _bandHalf;
      if (err < _bandHalf * 1.5) _approached = true;
      // Overshoot: closed in, then flung well past → break the streak.
      if (_approached && err > _bandHalf * 3.2) {
        _streak = 0;
        _missFlash = 0.8;
        _approached = false;
      }

      if (inBand) {
        final centred = (1 - err / _bandHalf).clamp(0.0, 1.0);
        _lock = (_lock + centred * dt / _lockNeed).clamp(0.0, 1.0);
        _centAccum += centred * dt;
        _centTime += dt;
        if (_lock >= 1.0) _registerHit();
      } else {
        if (_lock > 0.04) _missFlash = math.max(_missFlash, 0.25);
        _lock = math.max(0.0, _lock - dt * _kLockDecay);
      }
    }

    _updateBubbles(dt, running);
    _greenFlash = math.max(0.0, _greenFlash - dt * 2.5);
    _missFlash = math.max(0.0, _missFlash - dt * 3.0);
    _ripple = math.max(0.0, _ripple - dt * 1.8);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _startRound() {
    _targetsHit = 0;
    _level = 0;
    _streak = 0;
    _phGoal = 7.0;
    _ph = 7.0;
    _approached = false;
    _greenFlash = 0;
    _missFlash = 0;
    _fx.clear();
    _pops.clear();
    _newTarget();
  }

  void _registerHit() {
    // FAIR scoring: this-attempt precision + speed only, hard-capped per lock.
    // No level/streak multiplier → no runaway leader, comebacks stay possible.
    final precision =
        _centTime > 0 ? (_centAccum / _centTime).clamp(0.0, 1.0) : 0.0;
    final speed = ((_kSpeedZero - _attemptTime) / (_kSpeedZero - _kSpeedFull))
        .clamp(0.0, 1.0);
    var pts = _kScoreBase +
        (precision * _kScorePrecision).round() +
        (speed * _kScoreSpeed).round();
    if (_isSurge) pts += _kScoreSurge;
    widget.session.addScore(pts);

    _targetsHit++;
    _level = _targetsHit;
    _streak++;
    widget.session.noteStreak(_streak); // mastery award ONLY — not score

    _greenFlash = 1.0;
    _ripple = 1.0;
    final tag = precision > 0.8 ? 'PERFECT +$pts' : '+$pts';
    _pops.add(FxPop(_lastBeakerCenter, tag, _kGood));
    _fx.addAll(
        FxBurst.spawn(_lastBeakerCenter, _kGood, count: 18, speed: 150, size: 3));
    _newTarget();
  }

  void _newTarget() {
    _lock = 0.0;
    _attemptTime = 0.0;
    _centAccum = 0.0;
    _centTime = 0.0;
    _approached = false;
    // Bias toward the hard near-neutral region as the level climbs.
    final neutralChance = (0.16 + _level * 0.05).clamp(0.0, 0.6);
    double t = 7.0;
    var tries = 0;
    do {
      if (_rng.nextDouble() < neutralChance) {
        t = 6.0 + _rng.nextDouble() * 2.0; // 6–8: steep, twitchy
      } else {
        t = 1.5 + _rng.nextDouble() * 11.0; // 1.5–12.5
      }
      tries++;
    } while ((t - _ph).abs() < 1.6 && tries < 8);
    _target = t;
  }

  void _addDrop(bool acid) {
    if (!widget.session.isRunning) return;
    final delta = _dropStrength * _steep(_phGoal);
    final signed = acid ? -delta : delta;
    // Responsive: most of the drop lands on the visible needle THIS frame; the
    // rest settles next tick. No more "tap now, see it later" lag.
    _ph = (_ph + signed * _kTapSnap).clamp(0.0, 14.0);
    _phGoal = (_phGoal + signed).clamp(0.0, 14.0);
    _ripple = 1.0;
    for (var i = 0; i < 4; i++) {
      _bubbles.add(_Bubble.burst(_rng));
    }
  }

  void _updateBubbles(double dt, bool running) {
    final rate = running ? (0.7 + _ripple) : 0.35;
    for (final b in _bubbles) {
      b.y += b.speed * rate * dt;
      b.x += math.sin((_time + b.phase) * 1.6) * 0.05 * dt;
    }
    _bubbles.removeWhere((b) => b.y > 1.0);
    if (_bubbles.length < 7 && _rng.nextDouble() < 0.5) {
      _bubbles.add(_Bubble.random(_rng)..y = 0.0);
    }
  }

  // Cached so juice spawned in the tick lands on the beaker (build sets it).
  Offset _lastBeakerCenter = const Offset(160, 280);

  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PhPainter(
                ph: _ph,
                target: _target,
                tol: _bandHalf,
                ghostAcid: _ghostAcid,
                ghostBase: _ghostBase,
                lock: _lock,
                level: _level + 1,
                streak: _streak,
                running: running,
                surge: _isSurge && running,
                time: _time,
                ripple: _ripple,
                greenFlash: _greenFlash,
                missFlash: _missFlash,
                bubbles: _bubbles,
                fx: _fx,
                pops: _pops,
                onLayout: (c) => _lastBeakerCenter = c,
              ),
            ),
          ),
          // Two big titration buttons along the bottom.
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: _DropButton(
                    label: 'ACID',
                    sub: 'H⁺  pH ▼',
                    color: _kAcid,
                    icon: Icons.south_rounded,
                    enabled: running,
                    onTap: () => _addDrop(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropButton(
                    label: 'BASE',
                    sub: 'OH⁻  pH ▲',
                    color: _kBase,
                    icon: Icons.north_rounded,
                    enabled: running,
                    onTap: () => _addDrop(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom titration button (own press state; no per-frame parent rebuild) ────

class _DropButton extends StatefulWidget {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _DropButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DropButton> createState() => _DropButtonState();
}

class _DropButtonState extends State<_DropButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final c = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: on ? () => setState(() => _down = false) : null,
      onTapUp: on
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(c, Colors.white, _down ? 0.16 : 0.02)!
                    .withValues(alpha: on ? 0.95 : 0.10),
                Color.lerp(c, Colors.black, 0.40)!.withValues(alpha: on ? 0.95 : 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: on
                ? [BoxShadow(color: c.withValues(alpha: _down ? 0.5 : 0.28), blurRadius: _down ? 20 : 12)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: Colors.white.withValues(alpha: on ? 1.0 : 0.4)),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: on ? 1.0 : 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: on ? 0.92 : 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small value types ─────────────────────────────────────────────────────────

class _Bubble {
  double x; // 0..1 across the liquid
  double y; // 0..1 from bottom (0) to surface (1)
  final double r;
  final double speed; // fraction of liquid height per second
  final double phase;
  _Bubble(this.x, this.y, this.r, this.speed, this.phase);

  factory _Bubble.random(math.Random rng) => _Bubble(
        0.12 + rng.nextDouble() * 0.76,
        rng.nextDouble(),
        1.2 + rng.nextDouble() * 2.6,
        0.18 + rng.nextDouble() * 0.30,
        rng.nextDouble() * 6.28,
      );

  factory _Bubble.burst(math.Random rng) => _Bubble(
        0.2 + rng.nextDouble() * 0.6,
        0.0,
        1.4 + rng.nextDouble() * 2.8,
        0.40 + rng.nextDouble() * 0.40,
        rng.nextDouble() * 6.28,
      );
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _PhPainter extends CustomPainter {
  final double ph;
  final double target;
  final double tol;
  final double ghostAcid;
  final double ghostBase;
  final double lock;
  final int level;
  final int streak;
  final bool running;
  final bool surge;
  final double time;
  final double ripple;
  final double greenFlash;
  final double missFlash;
  final List<_Bubble> bubbles;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final ValueChanged<Offset> onLayout;

  _PhPainter({
    required this.ph,
    required this.target,
    required this.tol,
    required this.ghostAcid,
    required this.ghostBase,
    required this.lock,
    required this.level,
    required this.streak,
    required this.running,
    required this.surge,
    required this.time,
    required this.ripple,
    required this.greenFlash,
    required this.missFlash,
    required this.bubbles,
    required this.fx,
    required this.pops,
    required this.onLayout,
  });

  static const double _hudH = 56.0;
  static const double _btnReserve = 104.0;

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, time, motes: 28);

    final mainTop = _hudH + 8;
    final mainBottom = size.height - _btnReserve;

    // pH scale strip on the right.
    const stripW = 44.0;
    final stripRight = size.width - 14;
    final stripLeft = stripRight - stripW;
    final stripTop = mainTop + 14;
    final stripBottom = mainBottom - 6;

    // Beaker centered in the space left of the strip.
    final beakerArea = Rect.fromLTRB(14, mainTop, stripLeft - 18, mainBottom);
    final beakerCenter = _paintBeaker(canvas, beakerArea);
    onLayout(beakerCenter);

    _paintScale(canvas, stripLeft, stripTop, stripW, stripBottom - stripTop);
    _paintHud(canvas, size);

    // Juice on top of the beaker.
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    if (greenFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: (greenFlash - 0.3) * 0.28));
    }
    if (missFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: missFlash * 0.20));
    }
    // Surge vignette — a breathing crimson edge in the final seconds.
    if (surge) {
      final pulse = 0.18 + 0.10 * (0.5 + 0.5 * math.sin(time * 6));
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, _kBad.withValues(alpha: pulse)],
            stops: const [0.62, 1.0],
          ).createShader(Offset.zero & size),
      );
    }
  }

  double _yForPh(double p, double top, double h) =>
      top + h * (1.0 - (p.clamp(0.0, 14.0) / 14.0));

  // ── pH scale strip ─────────────────────────────────────────────────────────
  void _paintScale(
      Canvas canvas, double left, double top, double w, double h) {
    final rect = Rect.fromLTWH(left, top, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    // Indicator gradient, pH 14 at top → 0 at bottom.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _kPhColors.reversed.toList(),
        ).createShader(rect)
        ..colorFilter = ColorFilter.mode(
            Colors.black.withValues(alpha: 0.18), BlendMode.darken),
    );

    // STEEP zone (≈ pH 5.5–8.5): hazard hatch + label. Makes the lesson SHOWN —
    // "near 7 every drop leaps". Drawn under the band so the band reads on top.
    final steepTop = _yForPh(8.5, top, h);
    final steepBot = _yForPh(5.5, top, h);
    final steepRect = Rect.fromLTRB(left, steepTop, left + w, steepBot);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
        steepRect, Paint()..color = Colors.black.withValues(alpha: 0.22));
    final hatch = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 2;
    for (double d = -h; d < w + h; d += 8) {
      canvas.drawLine(Offset(left + d, steepBot), Offset(left + d + h, steepTop),
          hatch);
    }
    canvas.restore();

    // Strip outline.
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.18));

    // Target band.
    if (running) {
      final bandTop = _yForPh(target + tol, top, h);
      final bandBot = _yForPh(target - tol, top, h);
      final bandRect = Rect.fromLTRB(left - 5, bandTop, left + w + 5, bandBot);
      final lockGlow = 0.55 + 0.4 * lock;
      canvas.drawRect(bandRect,
          Paint()..color = _kGood.withValues(alpha: 0.10 + 0.18 * lock));
      canvas.drawRect(
          bandRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _kGood.withValues(alpha: lockGlow));
    }

    // Neutral pH-7 reference line.
    final ny = _yForPh(7, top, h);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    for (double x = left; x < left + w; x += 7) {
      canvas.drawLine(Offset(x, ny), Offset(x + 3.5, ny), dash);
    }
    _text(canvas, '7', Offset(left - 12, ny),
        size: 10, color: Colors.white.withValues(alpha: 0.75), bold: true);
    _text(canvas, '14', Offset(left - 13, top + 6),
        size: 9, color: Colors.white.withValues(alpha: 0.55));
    _text(canvas, '0', Offset(left - 11, top + h - 6),
        size: 9, color: Colors.white.withValues(alpha: 0.55));

    // Predictive GHOST ticks — where the next ACID / BASE drop would land. The
    // wider these spread from the current marker, the steeper the curve is here.
    if (running) {
      _ghostTick(canvas, left, w, _yForPh(ghostAcid, top, h), _kAcid);
      _ghostTick(canvas, left, w, _yForPh(ghostBase, top, h), _kBase);
    }

    // Current-pH marker arrow (snappy — tracks taps near-instantly).
    final my = _yForPh(ph, top, h);
    final mc = _phColor(ph);
    final pathm = Path()
      ..moveTo(left - 6, my)
      ..lineTo(left - 17, my - 7)
      ..lineTo(left - 17, my + 7)
      ..close();
    canvas.drawPath(pathm, Paint()..color = mc);
    canvas.drawPath(
        pathm,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawLine(
        Offset(left, my),
        Offset(left + w, my),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 2);

    _text(canvas, 'pH', Offset(left + w / 2, top - 13),
        size: 10, color: _kAccent.withValues(alpha: 0.85), bold: true);
  }

  void _ghostTick(Canvas canvas, double left, double w, double y, Color color) {
    canvas.drawLine(
        Offset(left, y),
        Offset(left + w, y),
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1.4);
    // A filled chevron on the right edge marking the ghost landing point.
    final tipX = left + w + 6;
    final tri = Path()
      ..moveTo(tipX, y - 5)
      ..lineTo(tipX, y + 5)
      ..lineTo(tipX + 7, y)
      ..close();
    canvas.drawPath(tri, Paint()..color = color.withValues(alpha: 0.8));
  }

  // ── Beaker ───────────────────────────────────────────────────────────────────
  Offset _paintBeaker(Canvas canvas, Rect area) {
    final bw = math.min(area.width, 188.0);
    final bh = math.min(area.height * 0.84, 252.0);
    final cx = area.center.dx;
    final topY = area.center.dy - bh / 2;
    final glass = Rect.fromCenter(
        center: Offset(cx, topY + bh / 2), width: bw, height: bh);
    final rr = RRect.fromRectAndCorners(glass,
        bottomLeft: const Radius.circular(26),
        bottomRight: const Radius.circular(26),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6));

    // Glass interior tint.
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.03));

    // Liquid.
    const fillFrac = 0.74;
    final liquidTopY = glass.bottom - glass.height * fillFrac;
    final liquid = _phColor(ph);
    canvas.save();
    canvas.clipRRect(rr);
    final liquidRect =
        Rect.fromLTRB(glass.left, liquidTopY, glass.right, glass.bottom);
    canvas.drawRect(
      liquidRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            liquid.withValues(alpha: 0.85),
            Color.lerp(liquid, Colors.black, 0.30)!.withValues(alpha: 0.95),
          ],
        ).createShader(liquidRect),
    );

    // Surface wobble line.
    final wobble = Path();
    final amp = 2.0 + ripple * 4.0;
    wobble.moveTo(glass.left, liquidTopY);
    for (double x = glass.left; x <= glass.right; x += 6) {
      final yy = liquidTopY + math.sin((x / 18) + time * 3.0) * amp * 0.5;
      wobble.lineTo(x, yy);
    }
    canvas.drawPath(
        wobble,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.30));

    // Bubbles.
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.30);
    for (final b in bubbles) {
      final by = glass.bottom - (glass.bottom - liquidTopY) * b.y;
      final bx = glass.left + 6 + (glass.width - 12) * b.x;
      canvas.drawCircle(Offset(bx, by), b.r, bubblePaint);
    }
    canvas.restore();

    // Glass outline + rim.
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _kGlass.withValues(alpha: 0.55));
    canvas.drawLine(
        Offset(glass.left - 6, glass.top),
        Offset(glass.right + 6, glass.top),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = _kGlass.withValues(alpha: 0.7));

    // Active LOCK ring + big pH readout, centered on the liquid.
    final center = Offset(cx, liquidTopY + (glass.bottom - liquidTopY) * 0.46);
    if (running && lock > 0.01) {
      final ringRect = Rect.fromCircle(center: center, radius: 54);
      canvas.drawArc(
          ringRect,
          -math.pi / 2,
          2 * math.pi * lock,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..color = _kGood.withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    _text(canvas, ph.toStringAsFixed(1), center,
        size: 42,
        color: Colors.white,
        bold: true,
        shadow: Colors.black.withValues(alpha: 0.5));
    _text(canvas, _phLabel(ph), center + const Offset(0, 31),
        size: 11, color: Colors.white.withValues(alpha: 0.85), bold: true);
    return center;
  }

  String _phLabel(double p) {
    if (p < 6.4) return 'ACIDIC';
    if (p > 7.6) return 'BASIC';
    return 'NEUTRAL';
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    _badge(canvas, Offset(16, 14), 'LV $level', _kAccent);
    if (streak > 1) {
      _badge(canvas, Offset(size.width - 94, 14), 'STREAK $streak', _kGood);
    }

    // Target readout (or SURGE / ready text), centered.
    final tColor = running ? _phColor(target) : _kAccent;
    final String label;
    if (!running) {
      label = 'BALANCE THE pH';
    } else if (surge) {
      label = 'SURGE!  TARGET ${target.toStringAsFixed(1)}';
    } else {
      label = 'TARGET  pH ${target.toStringAsFixed(1)}';
    }
    final tp = _layout(label,
        size: 16,
        color: surge ? _kBad : Potatuhs.textPrimary,
        bold: true);
    final tx = size.width / 2 - tp.width / 2;
    const ty = 18.0;
    if (running) {
      canvas.drawCircle(
          Offset(tx - 12, ty + tp.height / 2), 6, Paint()..color = tColor);
      canvas.drawCircle(
          Offset(tx - 12, ty + tp.height / 2),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.6));
    }
    tp.paint(canvas, Offset(tx, ty));
  }

  void _badge(Canvas canvas, Offset at, String text, Color color) {
    final tp = _layout(text, size: 11, color: color, bold: true);
    final rect = Rect.fromLTWH(at.dx, at.dy, tp.width + 18, tp.height + 10);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.5));
    tp.paint(canvas, Offset(at.dx + 9, at.dy + 5));
  }

  // ── Text helpers ─────────────────────────────────────────────────────────────
  TextPainter _layout(String text,
      {required double size, required Color color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(Canvas canvas, String text, Offset center,
      {required double size,
      required Color color,
      bool bold = false,
      Color? shadow}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
          shadows: shadow != null
              ? [Shadow(color: shadow, blurRadius: 10)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PhPainter old) => true;
}
