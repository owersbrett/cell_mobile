import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ── Feel constants ──────────────────────────────────────────────────────────
// All timing/scoring tunables live here. Play-test and adjust freely.

/// Seconds a nerve signal takes to travel the nerve at the calm baseline.
const double _kBasePeriod = 1.10;

/// Tightest signal period at full ramp (fastest cadence).
const double _kMinPeriod = 0.50;

/// Half-width of the strike window (phase units 0–1) at baseline — generous.
const double _kBaseWindow = 0.150;

/// Half-width of the strike window at full ramp — tight.
const double _kMinWindow = 0.060;

/// Phase (0–1) at which the signal reaches the junction: the ideal tap moment.
const double _kTargetPhase = 0.84;

/// Successful contractions needed to climb one skill level.
const int _kHitsPerLevel = 5;

/// Skill-ramp levels from baseline → min cadence/window.
const int _kMaxLevel = 8;

/// Force a single twitch adds to the contraction (0–1). Rapid hits SUM toward
/// fused tetanus; one isolated twitch relaxes before the next signal.
const double _kTwitchAmount = 0.50;

/// Contraction relaxation rate (units/sec) when no new signal sustains it.
const double _kRelaxRate = 1.30;

/// Contraction above this counts as sustained (tetanus).
const double _kTetanusThreshold = 0.80;

/// Max tetanus bonus (points/sec) at ZERO fatigue. The drip decays as the
/// muscle fatigues — this is what tames the old runaway-leader engine.
const double _kMaxDrip = 20.0;

/// Fatigue accrued per second while holding tetanus (~1/this sec to fully tire).
const double _kFatigueRate = 0.34;

/// Fatigue recovered per second while the muscle is rested.
const double _kRecoverRate = 0.55;

/// Contraction below this lets fatigue recover (the muscle "rests").
const double _kRestLevel = 0.30;

/// Seconds-remaining threshold that triggers the FINAL BURST crescendo.
const double _kFinalBurstSecs = 10.0;

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kMuscle = Color(0xFFE05260); // muscle red (accent)
const Color _kMuscleDeep = Color(0xFF8E2C3A);
const Color _kActin = Color(0xFFFFCBB0); // thin filaments
const Color _kMyosin = Color(0xFF6E1E2C); // thick filaments
const Color _kZdisc = Color(0xFFFFE0C2);
const Color _kSignal = Potatuhs.gold; // action potential = brand energy
const Color _kFused = Color(0xFF69F0AE); // tetanus fused green
const Color _kFatigue = Color(0xFFE19816); // fatigue amber (brand sienna)
const Color _kRed = Color(0xFFFF5252);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, each drawn with the REAL components
// (the same nerve, sarcomere, and HUD bars the live game paints).
// ═══════════════════════════════════════════════════════════════════════════

/// Draws one sarcomere at [shorten] (0 relaxed → 1 fully contracted), centred at
/// [cx],[cy] over width [w]. Mirrors [_TwitchV2Painter._paintSarcomere] so the
/// legend shows the literal actin-over-myosin the player watches shorten.
void _legendSarcomere(
    Canvas canvas, double cx, double cy, double w, double shorten,
    {Color? active}) {
  final restHalf = w * 0.31;
  final contractedHalf = w * 0.165;
  final half = restHalf + (contractedHalf - restHalf) * shorten;
  final myosinHalf = w * 0.125;
  final rowGap = w * 0.052;
  const rows = 3;
  final zColor = Color.lerp(_kZdisc, active ?? _kZdisc, 0.6 * shorten)!;

  for (final dir in [-1.0, 1.0]) {
    final zx = cx + dir * half;
    canvas.drawLine(
      Offset(zx, cy - rowGap * 1.7),
      Offset(zx, cy + rowGap * 1.7),
      Paint()
        ..color = zColor.withValues(alpha: 0.9)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }
  for (var r = 0; r < rows; r++) {
    final y = cy + (r - (rows - 1) / 2) * rowGap;
    for (final dir in [-1.0, 1.0]) {
      final zx = cx + dir * half;
      canvas.drawLine(
        Offset(zx, y),
        Offset(cx + dir * (myosinHalf * 0.35), y),
        Paint()
          ..color = _kActin.withValues(alpha: 0.85)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      Offset(cx - myosinHalf, y),
      Offset(cx + myosinHalf, y),
      Paint()
        ..color = Color.lerp(_kMyosin, _kMuscle, 0.3 + 0.5 * shorten)!
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Frame 1 — the verb: a signal races the nerve into the strike zone; tap then.
void _legendBeat(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final y = size.height * 0.55;
  final left = size.width * 0.10;
  final right = size.width * 0.90;
  final span = right - left;

  canvas.drawLine(
    Offset(left, y),
    Offset(right, y),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );

  final zoneHalfPx = _kBaseWindow * span;
  final targetX = left + _kTargetPhase * span;
  final zoneRect =
      Rect.fromLTRB(targetX - zoneHalfPx, y - 22, targetX + zoneHalfPx, y + 22);
  canvas.drawRRect(RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)),
      Paint()..color = _kSignal.withValues(alpha: 0.18));
  canvas.drawRRect(
    RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kSignal.withValues(alpha: 0.7),
  );
  canvas.drawLine(Offset(targetX, y - 26), Offset(targetX, y + 26),
      Paint()..color = _kSignal.withValues(alpha: 0.85)..strokeWidth = 2);

  // Junction orb at the muscle end.
  GameFx.orb(canvas, Offset(left + span, y), 9, _kMuscle, glow: 0.9);

  // The travelling signal, arriving in-zone (green = on the beat).
  final pulseX = targetX - zoneHalfPx * 0.4;
  for (var i = 1; i <= 5; i++) {
    final tx = pulseX - i * span * 0.02;
    if (tx < left) continue;
    canvas.drawCircle(Offset(tx, y), 4.5 * (1 - i / 6),
        Paint()..color = _kSignal.withValues(alpha: 0.18 * (1 - i / 6)));
  }
  GameFx.orb(canvas, Offset(pulseX, y), 8.5, _kFused, glow: 1.4);

  GameFx.text(canvas, 'STRIKE ZONE', Offset(targetX, y + 42), 10,
      _kSignal.withValues(alpha: 0.85), weight: FontWeight.w800);
}

/// Frame 2 — how to score: a clean hit fires a contraction; the sarcomere
/// shortens and the FORCE bar fills.
void _legendContract(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  _legendSarcomere(canvas, size.width * 0.5, size.height * 0.40, size.width,
      0.62,
      active: _kMuscle);

  // Force bar filling.
  final margin = size.width * 0.14;
  final barW = size.width - margin * 2;
  final by = size.height * 0.74;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, by, barW, 9), const Radius.circular(5)),
    Paint()..color = Colors.white.withValues(alpha: 0.10),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, by, barW * 0.62, 9), const Radius.circular(5)),
    Paint()..color = _kMuscle.withValues(alpha: 0.92),
  );
  GameFx.text(canvas, 'FORCE', Offset(size.width * 0.5, by + 22), 11,
      _kMuscle.withValues(alpha: 0.9), weight: FontWeight.w800);
}

/// Frame 3 — the twist & the danger: stack taps into TETANUS (green, past the
/// line) for bonus, but the FATIGUE strip fills and eats it away.
void _legendTetanus(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  _legendSarcomere(canvas, size.width * 0.5, size.height * 0.34, size.width,
      0.92,
      active: _kFused);

  final margin = size.width * 0.14;
  final barW = size.width - margin * 2;
  final by = size.height * 0.66;

  // Force bar pushed past the tetanus line → fused green.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, by, barW, 9), const Radius.circular(5)),
    Paint()..color = Colors.white.withValues(alpha: 0.10),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, by, barW * 0.92, 9), const Radius.circular(5)),
    Paint()..color = _kFused.withValues(alpha: 0.92),
  );
  final tx = margin + barW * _kTetanusThreshold;
  canvas.drawLine(Offset(tx, by - 5), Offset(tx, by + 14),
      Paint()..color = _kFused.withValues(alpha: 0.8)..strokeWidth = 1.5);

  // Fatigue strip filling amber→red beneath.
  final fy = by + 14;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, fy, barW, 5), const Radius.circular(3)),
    Paint()..color = Colors.white.withValues(alpha: 0.07),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, fy, barW * 0.7, 5), const Radius.circular(3)),
    Paint()..color = Color.lerp(_kFatigue, _kRed, 0.5)!.withValues(alpha: 0.85),
  );

  GameFx.text(canvas, 'TETANUS', Offset(size.width * 0.5, by - 26), 15, _kFused,
      display: true, glow: 0.5);
  GameFx.text(canvas, 'FATIGUE', Offset(size.width * 0.5, fy + 20), 10,
      _kFatigue.withValues(alpha: 0.9), weight: FontWeight.w800);
}

/// Frame 4 — the escalation: the last 10s trigger FINAL BURST — fastest
/// cadence, signals bunched, 1.5× payout.
void _legendBurst(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final y = size.height * 0.50;
  final left = size.width * 0.10;
  final right = size.width * 0.90;
  final span = right - left;

  canvas.drawLine(
    Offset(left, y),
    Offset(right, y),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  // Junction.
  GameFx.orb(canvas, Offset(right, y), 9, _kMuscle, glow: 1.0);
  // Signals bunched tight → fast cadence.
  for (final f in [0.30, 0.52, 0.74]) {
    GameFx.orb(canvas, Offset(left + f * span, y), 7, _kSignal, glow: 1.1);
  }
  GameFx.text(canvas, 'FINAL BURST', Offset(size.width * 0.5, size.height * 0.24),
      17, _kSignal, display: true, glow: 0.7);
  GameFx.text(canvas, '1.5× PAYOUT', Offset(size.width * 0.5, size.height * 0.74),
      12, _kSignal.withValues(alpha: 0.9), weight: FontWeight.w800);
}

/// The visual manual for Twitch v2 — wired into the registry spec.
final List<LegendFrame> twitchV2LegendFrames = [
  const LegendFrame(
      caption: 'Tap the instant the signal hits the strike zone',
      paint: _legendBeat),
  const LegendFrame(
      caption: 'A clean hit fires a contraction — force builds',
      paint: _legendContract),
  const LegendFrame(
      caption: 'Stack fast taps into TETANUS — but it FATIGUES',
      paint: _legendTetanus),
  const LegendFrame(
      caption: 'Last 10s: FINAL BURST — fastest pace, 1.5× points',
      paint: _legendBurst),
];

/// "Twitch" v2 — drive muscle contraction by TIMING taps to a nerve signal.
/// A signal travels the axon toward the neuromuscular junction; tap as it
/// arrives in the strike zone to fire a contraction. Actin slides over myosin
/// and the sarcomere shortens. Rapid on-time taps SUM into a sustained tetanus
/// for bonus force — but holding tetanus builds FATIGUE that decays the bonus,
/// so you must release and recover. A time-driven ramp plus a final-seconds
/// burst means every run, even a flubbed one, accelerates to a finish.
class TwitchV2Game extends StatefulWidget {
  final MiniGameSession session;
  const TwitchV2Game({super.key, required this.session});

  @override
  State<TwitchV2Game> createState() => _TwitchV2GameState();
}

class _TwitchV2GameState extends State<TwitchV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Core rhythm state ──────────────────────────────────────────────────────
  double _phase = 0.0; // 0→1 within the current signal travel
  bool _beatResolved = false; // already tapped/missed for this signal
  bool _prevRunning = false;
  Size _lastSize = Size.zero; // latest laid-out size, for autopilot fires

  // ── Contraction / scoring ──────────────────────────────────────────────────
  double _contraction = 0.0; // 0 (relaxed) → 1 (fully shortened)
  double _fatigue = 0.0; // 0 (fresh) → 1 (spent): decays the tetanus bonus
  int _level = 0;
  int _hits = 0;
  int _streak = 0;
  bool _inTetanus = false; // true while contraction held past threshold
  double _tetanusAcc = 0.0; // fractional tetanus points carried over
  double _tetanusGlow = 0.0; // visual: how long held in tetanus

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _fireFlash = 0.0; // bloom on a clean hit
  double _missFlash = 0.0; // red flash on a wasted signal
  double _idle = 0.0; // ambient breathing / pulsing clock
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  // ── Derived ramp ────────────────────────────────────────────────────────────
  // Difficulty is the GREATER of a time ramp (everyone accelerates) and a skill
  // ramp (mastery accelerates faster) — so a struggling player still gets pace.
  double get _skillRamp => (_level / _kMaxLevel).clamp(0.0, 1.0);

  double _timeRamp() {
    final dur = widget.session.spec.durationSeconds;
    if (dur <= 0) return 0.0;
    final remS = widget.session.remaining.inMilliseconds / 1000.0;
    return (1.0 - remS / dur).clamp(0.0, 1.0);
  }

  bool _finalBurst() {
    if (!widget.session.isRunning) return false;
    return widget.session.remaining.inMilliseconds / 1000.0 <= _kFinalBurstSecs;
  }

  double _ramp() {
    var r = math.max(_skillRamp, _timeRamp());
    if (_finalBurst()) r = math.max(r, 0.82); // floor the pace for the climax
    return r.clamp(0.0, 1.0);
  }

  double get _period {
    final r = _ramp();
    var p = _kBasePeriod + (_kMinPeriod - _kBasePeriod) * r;
    if (_finalBurst()) p *= 0.9; // extra crescendo kick
    return p;
  }

  double get _window {
    final r = _ramp();
    return _kBaseWindow + (_kMinWindow - _kBaseWindow) * r;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();

    // ATTRACT autopilot: this game knows how to fire on its own beat. The host
    // calls it on the autopilot cadence (~250ms) while running; it is a no-op
    // during hands-on play. See [_autoStep]. Registered always (harmless).
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent hands-free FIRE per host tick (~250ms). This is a rhythm
  /// game: the signal races continuously toward the junction on a recurring
  /// beat, so it can sweep clean through the strike window between two ~250ms
  /// ticks — a naive "fire if in-zone now" would land off-beat most beats.
  /// Instead we read the beat's phase + rate and look exactly one tick ahead:
  ///
  ///   • Only ever fire when firing NOW already scores — i.e. the CURRENT phase
  ///     is inside the on-beat window ([_window]) around the junction target
  ///     ([_kTargetPhase]). [_handleTap] scores off the live `_phase`, and a
  ///     fire outside the window wastes the signal (streak reset), so we never
  ///     do it — never off-beat.
  ///   • Among the in-window ticks, fire on the LOCAL MINIMUM of |phase −
  ///     target|: only when NOW is at least as close to the beat as the NEXT
  ///     tick will be (`errNow <= errNext`). If a tighter tick is still ahead we
  ///     wait for it — this pulls each fire toward PERFECT.
  ///
  /// The [_beatResolved] latch means at most one fire per beat; it clears when
  /// the signal wraps, so we keep firing across beats to build/hold tetanus.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_beatResolved) return; // this beat already fired/missed.

    // The signal advances at this rate while running; look one host tick ahead.
    final phaseSpeed = 1.0 / _period;
    const tick = 0.25; // host autopilot cadence, seconds.

    final errNow = (_phase - _kTargetPhase).abs();
    if (errNow > _window) return; // off-beat → a fire would waste it.

    // Predict the beat one tick out; if a closer-to-target tick is still ahead,
    // wait for it rather than settle for an off-center hit.
    final errNext = (_phase + phaseSpeed * tick - _kTargetPhase).abs();
    if (errNow > errNext) return;

    _handleTap(_lastSize);
  }

  void _resetRun() {
    _phase = 0.0;
    _beatResolved = false;
    _contraction = 0.0;
    _fatigue = 0.0;
    _level = 0;
    _hits = 0;
    _streak = 0;
    _inTetanus = false;
    _tetanusAcc = 0.0;
    _tetanusGlow = 0.0;
    _sparks.clear();
    _pops.clear();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    if (running && !_prevRunning) _resetRun();
    _prevRunning = running;

    _idle += dt;

    // Advance the signal along the nerve. Drift slowly in the calm ready state.
    final phaseSpeed = running ? (1.0 / _period) : 0.28;
    _phase += phaseSpeed * dt;
    if (_phase >= 1.0) {
      _phase -= 1.0;
      // A signal arrived and left untapped while playing → wasted (relax).
      if (running && !_beatResolved) _registerMiss(passive: true);
      _beatResolved = false;
    }

    // Contraction always relaxes; rapid hits out-pace this (summation).
    _contraction = math.max(0.0, _contraction - _kRelaxRate * dt);

    if (running) {
      if (_contraction >= _kTetanusThreshold) {
        // Held in tetanus: bonus force, but the muscle FATIGUES, decaying it.
        if (!_inTetanus) {
          _inTetanus = true;
          HapticFeedback.mediumImpact();
        }
        _tetanusGlow = math.min(1.0, _tetanusGlow + dt * 2.0);
        _fatigue = math.min(1.0, _fatigue + _kFatigueRate * dt);
        var drip = _kMaxDrip * (1.0 - _fatigue);
        if (_finalBurst()) drip *= 1.5; // climax pays out for everyone
        _tetanusAcc += drip * dt;
        final whole = _tetanusAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _tetanusAcc -= whole;
        }
      } else {
        _inTetanus = false;
        _tetanusGlow = math.max(0.0, _tetanusGlow - dt * 1.6);
        // Rested muscle recovers its capacity to fuse again.
        if (_contraction < _kRestLevel) {
          _fatigue = math.max(0.0, _fatigue - _kRecoverRate * dt);
        }
      }
    } else {
      _tetanusGlow = math.max(0.0, _tetanusGlow - dt * 1.6);
      _fatigue = math.max(0.0, _fatigue - _kRecoverRate * dt);
      _inTetanus = false;
    }

    // Decay juice.
    _fireFlash = math.max(0.0, _fireFlash - dt * 3.0);
    _missFlash = math.max(0.0, _missFlash - dt * 3.5);

    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;

    // Already resolved this signal → a wasted twitch (firing off-beat).
    if (_beatResolved) {
      _registerMiss(passive: false);
      return;
    }

    final err = (_phase - _kTargetPhase).abs();
    if (err <= _window) {
      _registerHit(quality: (1.0 - err / _window).clamp(0.0, 1.0), size: size);
    } else {
      _registerMiss(passive: false);
    }
  }

  void _registerHit({required double quality, required Size size}) {
    _beatResolved = true;
    _hits++;
    _streak++;
    widget.session.noteStreak(_streak);
    HapticFeedback.lightImpact();

    // Sliding filaments: the twitch summates onto the current contraction.
    _contraction = math.min(1.0, _contraction + _kTwitchAmount);

    // Streak multiplier is modest and resets on any miss — catch-up-able, not a
    // runaway. The old uncatchable lead lived in the tetanus drip, now fatigued.
    final mult = 1.0 + math.min(_streak * 0.06, 0.8); // up to 1.8×
    var pts = ((9 + (quality * 13).round()) * mult).round();
    if (_finalBurst()) pts = (pts * 1.5).round(); // climax bonus for all
    widget.session.addScore(pts);

    if (_hits % _kHitsPerLevel == 0 && _level < _kMaxLevel) _level++;

    _fireFlash = 0.4 + 0.6 * quality;
    final c = Offset(size.width / 2, size.height * 0.34);
    if (_sparks.length < 90) {
      _sparks.addAll(FxBurst.spawn(c, quality > 0.7 ? _kFused : _kSignal,
          count: 9 + (quality * 13).round(), speed: 150, size: 3));
    }
    if (_pops.length < 12) {
      final tag = quality > 0.85 ? 'PERFECT +$pts' : '+$pts';
      _pops.add(FxPop(c, tag, quality > 0.7 ? _kFused : _kMuscle));
    }
  }

  void _registerMiss({required bool passive}) {
    if (!passive) _beatResolved = true;
    _streak = 0;
    _missFlash = 0.7;
    if (!passive && _sparks.length < 90) {
      _sparks.addAll(FxBurst.spawn(
        Offset(MediaQuery.of(context).size.width * 0.5, 0),
        _kRed,
        count: 6,
        speed: 90,
        size: 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _lastSize = size;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handleTap(size),
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _TwitchV2Painter(
              phase: _phase,
              targetPhase: _kTargetPhase,
              window: _window,
              contraction: _contraction,
              fatigue: _fatigue,
              tetanusGlow: _tetanusGlow,
              level: _level,
              streak: _streak,
              fireFlash: _fireFlash,
              missFlash: _missFlash,
              idle: _idle,
              running: widget.session.isRunning,
              finalBurst: _finalBurst(),
              sparks: _sparks,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TwitchV2Painter extends CustomPainter {
  final double phase;
  final double targetPhase;
  final double window;
  final double contraction;
  final double fatigue;
  final double tetanusGlow;
  final int level;
  final int streak;
  final double fireFlash;
  final double missFlash;
  final double idle;
  final bool running;
  final bool finalBurst;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _TwitchV2Painter({
    required this.phase,
    required this.targetPhase,
    required this.window,
    required this.contraction,
    required this.fatigue,
    required this.tetanusGlow,
    required this.level,
    required this.streak,
    required this.fireFlash,
    required this.missFlash,
    required this.idle,
    required this.running,
    required this.finalBurst,
    required this.sparks,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kMuscle, idle, motes: finalBurst ? 30 : 22);

    _paintSarcomere(canvas, size);
    _paintNerve(canvas, size);
    FxBurst.paint(canvas, sparks);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintHud(canvas, size);
    _paintFlash(canvas, size);
  }

  // ── The sarcomere: actin sliding over myosin as it shortens ─────────────────
  void _paintSarcomere(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.34;

    final breathe = running ? 0.0 : 0.04 * (0.5 + 0.5 * math.sin(idle * 1.6));
    final shorten = (contraction + breathe).clamp(0.0, 1.0);

    final restHalf = size.width * 0.31;
    final contractedHalf = size.width * 0.165;
    final half = restHalf + (contractedHalf - restHalf) * shorten;
    final myosinHalf = size.width * 0.125; // myosin length is fixed
    final rowGap = size.height * 0.052;
    const rows = 3;

    // Fused tetanus glows green; fatigue tints it amber to read "tiring".
    final activeColor = Color.lerp(_kFused, _kFatigue, fatigue)!;

    final glowR = size.width * 0.34;
    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(colors: [
          _kMuscle.withValues(alpha: 0.10 + 0.22 * shorten + 0.2 * tetanusGlow),
          _kMuscle.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );

    // Z-discs — the boundaries that move inward as the muscle shortens.
    final zColor = Color.lerp(_kZdisc, activeColor, 0.6 * tetanusGlow)!;
    for (final dir in [-1.0, 1.0]) {
      final zx = cx + dir * half;
      canvas.drawLine(
        Offset(zx, cy - rowGap * 1.7),
        Offset(zx, cy + rowGap * 1.7),
        Paint()
          ..color = zColor.withValues(alpha: 0.9)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, 1.5 + 3 * (shorten + tetanusGlow)),
      );
    }

    for (var r = 0; r < rows; r++) {
      final y = cy + (r - (rows - 1) / 2) * rowGap;

      // Actin thin filaments — anchored at the Z-discs, sliding toward center.
      for (final dir in [-1.0, 1.0]) {
        final zx = cx + dir * half;
        canvas.drawLine(
          Offset(zx, y),
          Offset(cx + dir * (myosinHalf * 0.35), y),
          Paint()
            ..color = _kActin.withValues(alpha: 0.85)
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      }

      // Myosin thick filament — fixed in the center; actin overlaps it more
      // as the muscle shortens (the sliding-filament idea, made visible).
      canvas.drawLine(
        Offset(cx - myosinHalf, y),
        Offset(cx + myosinHalf, y),
        Paint()
          ..color = Color.lerp(_kMyosin, _kMuscle, 0.3 + 0.5 * shorten)!
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      for (var i = -2; i <= 2; i++) {
        final hx = cx + i * (myosinHalf / 2.4);
        canvas.drawCircle(Offset(hx, y), 1.6,
            Paint()..color = _kActin.withValues(alpha: 0.5));
      }
    }
  }

  // ── The nerve: signal travels toward the junction; tap in the strike zone ───
  void _paintNerve(Canvas canvas, Size size) {
    final y = size.height * 0.74;
    final left = size.width * 0.10;
    final right = size.width * 0.90;
    final span = right - left;

    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Strike zone — the timing window around the junction.
    final zoneHalfPx = window * span;
    final targetX = left + targetPhase * span;
    final zoneRect = Rect.fromLTRB(
        targetX - zoneHalfPx, y - 22, targetX + zoneHalfPx, y + 22);
    final zoneTint = missFlash > 0.05
        ? _kRed
        : (fireFlash > 0.05 ? _kFused : _kSignal);
    canvas.drawRRect(
      RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)),
      Paint()..color = zoneTint.withValues(alpha: 0.16 + 0.5 * fireFlash),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = zoneTint.withValues(alpha: 0.7),
    );
    canvas.drawLine(
      Offset(targetX, y - 26),
      Offset(targetX, y + 26),
      Paint()
        ..color = zoneTint.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );

    // Axon terminal / neuromuscular junction at the muscle end.
    final junctionX = left + span;
    GameFx.orb(canvas, Offset(junctionX, y), 9,
        Color.lerp(_kMuscleDeep, _kMuscle, 0.4 + 0.6 * contraction)!,
        glow: 0.6 + contraction);
    // Connector hinting cause (junction) → effect (muscle above).
    canvas.drawLine(
      Offset(targetX, y - 26),
      Offset(size.width / 2, size.height * 0.46),
      Paint()
        ..color = _kSignal.withValues(alpha: 0.10 + 0.25 * fireFlash)
        ..strokeWidth = 1.4,
    );

    // The travelling signal pulse (action potential).
    final pulseX = left + phase * span;
    final approaching = (phase - targetPhase).abs() <= window;
    GameFx.orb(canvas, Offset(pulseX, y), approaching ? 8.5 : 6.5,
        approaching ? _kFused : _kSignal,
        glow: approaching ? 1.4 : 0.9);
    for (var i = 1; i <= 5; i++) {
      final tp = (phase - i * 0.02);
      if (tp < 0) continue;
      canvas.drawCircle(
        Offset(left + tp * span, y),
        4.5 * (1 - i / 6),
        Paint()..color = _kSignal.withValues(alpha: 0.18 * (1 - i / 6)),
      );
    }

    // Calm-state prompt — Russ-voiced, on-brand, still legible in <3s.
    if (!running) {
      GameFx.text(canvas, 'uhhh… FIRE ON THE BEAT',
          Offset(size.width / 2, size.height * 0.88), 13,
          _kSignal.withValues(alpha: 0.75), weight: FontWeight.w800, glow: 0.4);
    }
  }

  // ── HUD: force bar, fatigue strip, level, streak, callouts ──────────────────
  void _paintHud(Canvas canvas, Size size) {
    const margin = 18.0;
    final barW = size.width - margin * 2;

    // Force bar (contraction strength).
    final barRect = Rect.fromLTWH(margin, 16, barW, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    final fillC = contraction >= _kTetanusThreshold
        ? Color.lerp(_kFused, _kFatigue, fatigue)!
        : _kMuscle;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, 16, barW * contraction, 9),
          const Radius.circular(5)),
      Paint()..color = fillC.withValues(alpha: 0.92),
    );
    final tx = margin + barW * _kTetanusThreshold;
    canvas.drawLine(Offset(tx, 12), Offset(tx, 29),
        Paint()..color = _kFused.withValues(alpha: 0.7)..strokeWidth = 1.5);
    GameFx.text(canvas, 'FORCE', Offset(margin + 22, 36), 9,
        Colors.white.withValues(alpha: 0.45), weight: FontWeight.w700);

    // Fatigue strip beneath — fills amber→red as the held muscle tires.
    final fatRect = Rect.fromLTWH(margin, 30, barW, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fatRect, const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    if (fatigue > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, 30, barW * fatigue, 4),
            const Radius.circular(3)),
        Paint()
          ..color = Color.lerp(_kFatigue, _kRed, fatigue)!
              .withValues(alpha: 0.85),
      );
    }

    // Level + streak.
    GameFx.text(canvas, 'LV ${level + 1}', Offset(size.width - 40, 40), 12,
        _kMuscle.withValues(alpha: 0.95), weight: FontWeight.w800);
    if (streak > 1) {
      GameFx.text(canvas, '${streak}x', Offset(size.width - 40, 56), 11,
          _kSignal.withValues(alpha: 0.9), weight: FontWeight.w700);
    }

    // TETANUS / FATIGUED callouts above the muscle.
    if (fatigue > 0.7 && contraction >= _kTetanusThreshold) {
      GameFx.text(canvas, 'FATIGUED — RELAX',
          Offset(size.width / 2, size.height * 0.20), 16,
          _kFatigue.withValues(alpha: 0.95), display: true, glow: 0.6);
    } else if (tetanusGlow > 0.4) {
      GameFx.text(canvas, 'TETANUS', Offset(size.width / 2, size.height * 0.20),
          18, _kFused.withValues(alpha: tetanusGlow), display: true, glow: 0.7);
    }

    // FINAL BURST crescendo banner — pulsing, brand-gold.
    if (finalBurst) {
      final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(idle * 9.0));
      GameFx.text(canvas, 'FINAL BURST',
          Offset(size.width / 2, size.height * 0.62), 17,
          _kSignal.withValues(alpha: pulse), display: true, glow: 0.7);
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (missFlash > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kRed.withValues(alpha: (missFlash - 0.25) * 0.18));
    }
    if (fireFlash > 0.4) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kFused.withValues(alpha: (fireFlash - 0.4) * 0.22));
    }
    if (finalBurst) {
      final p = 0.5 + 0.5 * math.sin(idle * 9.0);
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kSignal.withValues(alpha: 0.04 + 0.04 * p));
    }
  }

  @override
  bool shouldRepaint(covariant _TwitchV2Painter old) => true;
}
