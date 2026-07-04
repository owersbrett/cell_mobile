import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ── Feel constants ──────────────────────────────────────────────────────────
// All timing/scoring tunables live here. Play-test and adjust freely.

/// Seconds a nerve signal takes to travel the nerve at level 0 (slowest).
const double _kBasePeriod = 1.15;

/// Tightest signal period at full acceleration (fastest cadence).
const double _kMinPeriod = 0.52;

/// Half-width of the strike window (in phase units, 0–1) at level 0 — generous.
const double _kBaseWindow = 0.14;

/// Half-width of the strike window at full acceleration — tight.
const double _kMinWindow = 0.055;

/// Phase (0–1) at which the signal reaches the junction: the ideal tap moment.
const double _kTargetPhase = 0.85;

/// Successful contractions needed to climb one acceleration level.
const int _kHitsPerLevel = 6;

/// Levels of ramp from base → min cadence/window.
const int _kMaxLevel = 10;

/// Force a single twitch adds to the contraction (0–1). Rapid hits SUM toward
/// fused tetanus; one isolated twitch relaxes before the next signal.
const double _kTwitchAmount = 0.52;

/// Contraction relaxation rate (units/sec) when no new signal sustains it.
const double _kRelaxRate = 1.35;

/// Contraction above this counts as sustained (tetanus) — it drips bonus force.
const double _kTetanusThreshold = 0.80;

/// Bonus points per second while held in tetanus.
const double _kTetanusPointsPerSec = 12.0;

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kMuscle = Color(0xFFE05260); // muscle red (accent)
const Color _kMuscleDeep = Color(0xFF8E2C3A);
const Color _kActin = Color(0xFFFFCBB0); // thin filaments
const Color _kMyosin = Color(0xFF6E1E2C); // thick filaments
const Color _kZdisc = Color(0xFFFFE0C2);
const Color _kSignal = Color(0xFFFFE066); // nerve action potential
const Color _kGreen = Color(0xFF69F0AE);
const Color _kRed = Color(0xFFFF5252);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME sarcomere +
// nerve primitives the live game uses (static, one-off; safe on any size).
// ═══════════════════════════════════════════════════════════════════════════

/// Draws the sarcomere (Z-discs + myosin + sliding actin) centred at [cy] with a
/// given [contraction] 0→1. [glow] tints it green toward the tetanus look.
void _legendSarcomere(Canvas canvas, Size size, double cy, double contraction,
    {double glow = 0}) {
  final cx = size.width / 2;
  final shorten = contraction.clamp(0.0, 1.0);
  final restHalf = size.width * 0.31;
  final contractedHalf = size.width * 0.165;
  final half = restHalf + (contractedHalf - restHalf) * shorten;
  final myosinHalf = size.width * 0.125;
  final rowGap = size.height * 0.052;
  const rows = 3;

  final glowR = size.width * 0.34;
  canvas.drawCircle(
    Offset(cx, cy),
    glowR,
    Paint()
      ..shader = RadialGradient(colors: [
        _kMuscle.withValues(alpha: 0.10 + 0.22 * shorten + 0.2 * glow),
        _kMuscle.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
  );

  final zColor = Color.lerp(_kZdisc, _kGreen, 0.6 * glow)!;
  for (final dir in [-1.0, 1.0]) {
    final zx = cx + dir * half;
    canvas.drawLine(
      Offset(zx, cy - rowGap * 1.7),
      Offset(zx, cy + rowGap * 1.7),
      Paint()
        ..color = zColor.withValues(alpha: 0.9)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, 1.5 + 3 * (shorten + glow)),
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
    for (var i = -2; i <= 2; i++) {
      final hx = cx + i * (myosinHalf / 2.4);
      canvas.drawCircle(Offset(hx, y), 1.6,
          Paint()..color = _kActin.withValues(alpha: 0.5));
    }
  }
}

/// Draws the nerve track, strike zone and a travelling signal pulse at [phase].
void _legendNerve(Canvas canvas, Size size, double y, double phase,
    Color pulseColor,
    {Color zoneTint = _kSignal}) {
  final left = size.width * 0.10;
  final right = size.width * 0.90;
  final span = right - left;
  const window = 0.11;

  canvas.drawLine(
    Offset(left, y),
    Offset(right, y),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );

  final zoneHalfPx = window * span;
  final targetX = left + _kTargetPhase * span;
  final zoneRect =
      Rect.fromLTRB(targetX - zoneHalfPx, y - 22, targetX + zoneHalfPx, y + 22);
  canvas.drawRRect(
    RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)),
    Paint()..color = zoneTint.withValues(alpha: 0.16),
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
  GameFx.orb(canvas, Offset(left + span, y), 9, _kMuscle, glow: 0.8);

  // The travelling action potential + its short trailing tail.
  final pulseX = left + phase.clamp(0.0, 1.0) * span;
  GameFx.orb(canvas, Offset(pulseX, y), 8.0, pulseColor, glow: 1.2);
  for (var i = 1; i <= 5; i++) {
    final tp = phase - i * 0.02;
    if (tp < 0) continue;
    canvas.drawCircle(
      Offset(left + tp * span, y),
      4.5 * (1 - i / 6),
      Paint()..color = pulseColor.withValues(alpha: 0.18 * (1 - i / 6)),
    );
  }
}

void _legendSignal(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendNerve(canvas, size, size.height * 0.55, _kTargetPhase, _kGreen);
}

void _legendFire(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendSarcomere(canvas, size, size.height * 0.44, 0.85);
  GameFx.text(canvas, '+24', Offset(size.width * 0.5, size.height * 0.74), 18,
      _kGreen,
      weight: FontWeight.w800, glow: 0.5);
}

void _legendWaste(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendSarcomere(canvas, size, size.height * 0.38, 0.0);
  _legendNerve(canvas, size, size.height * 0.74, 0.45, _kRed, zoneTint: _kRed);
}

void _legendTetanus(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  const margin = 24.0;
  final barW = size.width - margin * 2;
  final barY = size.height * 0.18;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, barY, barW, 10), const Radius.circular(5)),
    Paint()..color = Colors.white.withValues(alpha: 0.10),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(margin, barY, barW * 0.94, 10),
        const Radius.circular(5)),
    Paint()..color = _kGreen.withValues(alpha: 0.92),
  );
  final tx = margin + barW * _kTetanusThreshold;
  canvas.drawLine(
    Offset(tx, barY - 4),
    Offset(tx, barY + 14),
    Paint()
      ..color = _kGreen.withValues(alpha: 0.8)
      ..strokeWidth = 1.5,
  );
  _legendSarcomere(canvas, size, size.height * 0.52, 0.95, glow: 1.0);
  GameFx.text(canvas, 'TETANUS', Offset(size.width * 0.5, size.height * 0.84),
      18, _kGreen,
      display: true, glow: 0.7);
}

/// The visual manual for Twitch — wired into the registry spec.
final List<LegendFrame> twitchLegendFrames = [
  const LegendFrame(
      caption: 'A signal races the nerve — tap as it hits the strike zone',
      paint: _legendSignal),
  const LegendFrame(
      caption: 'On-time taps fire a contraction: actin slides, you score',
      paint: _legendFire),
  const LegendFrame(
      caption: 'Mistime it or miss — the muscle relaxes, your streak resets',
      paint: _legendWaste),
  const LegendFrame(
      caption: 'Chain fast taps past the line to fuse TETANUS: bonus force',
      paint: _legendTetanus),
];

/// "Twitch" — drive muscle contraction by TIMING taps to the nerve signal.
/// A signal travels the nerve toward the neuromuscular junction; tap as it
/// arrives in the strike zone to fire a contraction. The sarcomere's actin
/// filaments slide over the myosin and the muscle shortens. Rapid on-time taps
/// SUM into a sustained tetanus for bonus force; mistimed taps waste the signal.
/// Acceleration: faster signals, tighter windows.
class TwitchGame extends StatefulWidget {
  final MiniGameSession session;
  const TwitchGame({super.key, required this.session});

  @override
  State<TwitchGame> createState() => _TwitchGameState();
}

class _TwitchGameState extends State<TwitchGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Core rhythm state ──────────────────────────────────────────────────────
  double _phase = 0.0; // 0→1 within the current signal travel
  bool _beatResolved = false; // already tapped/missed for this signal
  bool _prevRunning = false;

  // ── Contraction / scoring ──────────────────────────────────────────────────
  double _contraction = 0.0; // 0 (relaxed) → 1 (fully shortened)
  int _level = 0;
  int _hits = 0;
  int _streak = 0;
  double _tetanusAcc = 0.0; // fractional tetanus points carried over
  double _tetanusGlow = 0.0; // visual: how long held in tetanus

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _fireFlash = 0.0; // green bloom on a clean hit
  double _missFlash = 0.0; // red flash on a wasted signal
  double _idle = 0.0; // ambient breathing clock
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  // Last known viewport, so the attract autopilot can fire off-frame.
  Size _lastSize = Size.zero;

  // ── Derived acceleration ────────────────────────────────────────────────────
  double get _ramp => (_level / _kMaxLevel).clamp(0.0, 1.0);
  double get _period => _kBasePeriod + (_kMinPeriod - _kBasePeriod) * _ramp;
  double get _window => _kBaseWindow + (_kMinWindow - _kBaseWindow) * _ramp;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();

    // ATTRACT autopilot: this game knows how to time its own twitches. The host
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
  /// One competent hands-free move per host tick (~250ms). This is a TIMING
  /// game: the signal races continuously toward the junction, so it can sweep
  /// clean through the strike zone between two ~250ms ticks — a naive "tap if
  /// in-zone now" would fire late (or on the wrong side) most beats. Instead we
  /// read the signal's phase + speed and look exactly one tick ahead:
  ///
  ///   • Only ever fire when firing NOW already scores — i.e. the CURRENT phase
  ///     is inside the strike window ([_window]) around dead-center
  ///     ([_kTargetPhase]). [_handleTap] scores off the live `_phase`, and a tap
  ///     outside the window wastes the signal (streak reset), so we never do it.
  ///   • Among the in-window ticks, fire on the LOCAL MINIMUM of |phase −
  ///     center|: only when NOW is at least as close to dead-center as the NEXT
  ///     tick will be (`errNow <= errNext`). If a tighter tick is still ahead we
  ///     wait for it — this pulls the tap toward PERFECT.
  ///
  /// The [_beatResolved] guard means at most one fire per travelling signal
  /// (matching a real player); it clears when the signal wraps.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_beatResolved) return; // this signal already tapped/missed.

    // The signal advances at this rate while running; look one host tick ahead.
    final phaseSpeed = 1.0 / _period;
    const window = 0.25; // host autopilot cadence, seconds.

    final errNow = (_phase - _kTargetPhase).abs();
    if (errNow > _window) return; // outside the zone → a tap would waste it.

    // Predict the signal one tick out; if a closer-to-center tick is still
    // ahead, wait for it rather than settle for an off-center hit.
    final errNext = (_phase + phaseSpeed * window - _kTargetPhase).abs();
    if (errNow > errNext) return;

    _handleTap(_lastSize);
  }

  void _resetRun() {
    _phase = 0.0;
    _beatResolved = false;
    _contraction = 0.0;
    _level = 0;
    _hits = 0;
    _streak = 0;
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

    if (running) {
      // Contraction relaxes continuously; rapid hits out-pace this (summation).
      _contraction = math.max(0.0, _contraction - _kRelaxRate * dt);

      // Tetanus: sustained high contraction drips bonus force.
      if (_contraction >= _kTetanusThreshold) {
        _tetanusGlow = math.min(1.0, _tetanusGlow + dt * 2.0);
        _tetanusAcc += _kTetanusPointsPerSec * dt;
        final whole = _tetanusAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _tetanusAcc -= whole;
        }
      } else {
        _tetanusGlow = math.max(0.0, _tetanusGlow - dt * 1.6);
      }
    } else {
      _contraction = math.max(0.0, _contraction - _kRelaxRate * dt);
      _tetanusGlow = math.max(0.0, _tetanusGlow - dt * 1.6);
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

    // No live signal in the strike approach → a wasted twitch.
    if (_beatResolved) {
      _registerMiss(passive: false);
      return;
    }

    final err = (_phase - _kTargetPhase).abs();
    if (err <= _window) {
      _registerHit(quality: (1.0 - err / _window).clamp(0.0, 1.0), size: size);
    } else {
      // Mistimed tap fires the nerve at the wrong instant — signal wasted.
      _registerMiss(passive: false);
    }
  }

  void _registerHit({required double quality, required Size size}) {
    _beatResolved = true;
    _hits++;
    _streak++;
    widget.session.noteStreak(_streak);

    // Sliding filaments: the twitch summates onto the current contraction.
    _contraction = math.min(1.0, _contraction + _kTwitchAmount);

    final mult = 1.0 + (_streak * 0.08).clamp(0.0, 1.4); // up to 2.4×
    final base = 10 + (quality * 15).round();
    final pts = (base * mult).round();
    widget.session.addScore(pts);

    if (_hits % _kHitsPerLevel == 0 && _level < _kMaxLevel) _level++;

    _fireFlash = 0.4 + 0.6 * quality;
    final c = Offset(size.width / 2, size.height * 0.34);
    _sparks.addAll(FxBurst.spawn(c, quality > 0.7 ? _kGreen : _kSignal,
        count: 10 + (quality * 14).round(), speed: 150, size: 3));
    final tag = quality > 0.85 ? 'PERFECT +$pts' : '+$pts';
    _pops.add(FxPop(c, tag, quality > 0.7 ? _kGreen : _kMuscle));
  }

  void _registerMiss({required bool passive}) {
    if (!passive) _beatResolved = true;
    _streak = 0;
    _missFlash = 0.7;
    if (!passive) {
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
            painter: _TwitchPainter(
              phase: _phase,
              targetPhase: _kTargetPhase,
              window: _window,
              contraction: _contraction,
              tetanusGlow: _tetanusGlow,
              level: _level,
              streak: _streak,
              fireFlash: _fireFlash,
              missFlash: _missFlash,
              idle: _idle,
              running: widget.session.isRunning,
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

class _TwitchPainter extends CustomPainter {
  final double phase;
  final double targetPhase;
  final double window;
  final double contraction;
  final double tetanusGlow;
  final int level;
  final int streak;
  final double fireFlash;
  final double missFlash;
  final double idle;
  final bool running;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _TwitchPainter({
    required this.phase,
    required this.targetPhase,
    required this.window,
    required this.contraction,
    required this.tetanusGlow,
    required this.level,
    required this.streak,
    required this.fireFlash,
    required this.missFlash,
    required this.idle,
    required this.running,
    required this.sparks,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kMuscle, idle, motes: 22);

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

    // Gentle ambient breathing when relaxed; contraction overrides it.
    final breathe = running ? 0.0 : 0.04 * (0.5 + 0.5 * math.sin(idle * 1.6));
    final shorten = (contraction + breathe).clamp(0.0, 1.0);

    final restHalf = size.width * 0.31;
    final contractedHalf = size.width * 0.165;
    final half = restHalf + (contractedHalf - restHalf) * shorten;
    final myosinHalf = size.width * 0.125; // myosin length is fixed
    final rowGap = size.height * 0.052;
    const rows = 3;

    // Soft muscle-fiber glow that brightens as it contracts.
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
    final zColor = Color.lerp(_kZdisc, _kGreen, 0.6 * tetanusGlow)!;
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

    // Filament rows: myosin (thick, centered) + actin (thin, from each Z-disc).
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
      // Myosin heads (cross-bridges) as little ticks.
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

    // Nerve track.
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
        : (fireFlash > 0.05 ? _kGreen : _kSignal);
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
    // Junction center line (the exact beat).
    canvas.drawLine(
      Offset(targetX, y - 26),
      Offset(targetX, y + 26),
      Paint()
        ..color = zoneTint.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );

    // Axon terminal / neuromuscular junction at the muscle end.
    final junctionX = left + span; // far right
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
        approaching ? _kGreen : _kSignal,
        glow: approaching ? 1.4 : 0.9);
    // A short trailing tail behind the pulse.
    for (var i = 1; i <= 5; i++) {
      final tp = (phase - i * 0.02);
      if (tp < 0) continue;
      canvas.drawCircle(
        Offset(left + tp * span, y),
        4.5 * (1 - i / 6),
        Paint()..color = _kSignal.withValues(alpha: 0.18 * (1 - i / 6)),
      );
    }

    // Calm-state prompt.
    if (!running) {
      GameFx.text(canvas, 'TAP THE SIGNAL ON THE BEAT',
          Offset(size.width / 2, size.height * 0.88), 13,
          _kSignal.withValues(alpha: 0.7), weight: FontWeight.w700, glow: 0.4);
    }
  }

  // ── HUD: contraction force bar, level, streak, tetanus call-out ─────────────
  void _paintHud(Canvas canvas, Size size) {
    // Force bar (contraction strength) along the top.
    const margin = 18.0;
    final barW = size.width - margin * 2;
    final barRect = Rect.fromLTWH(margin, 16, barW, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    final fillC = contraction >= _kTetanusThreshold ? _kGreen : _kMuscle;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, 16, barW * contraction, 9),
          const Radius.circular(5)),
      Paint()..color = fillC.withValues(alpha: 0.92),
    );
    // Tetanus threshold tick.
    final tx = margin + barW * _kTetanusThreshold;
    canvas.drawLine(Offset(tx, 12), Offset(tx, 29),
        Paint()..color = _kGreen.withValues(alpha: 0.7)..strokeWidth = 1.5);

    GameFx.text(canvas, 'FORCE', Offset(margin + 22, 36), 9,
        Colors.white.withValues(alpha: 0.45), weight: FontWeight.w700);

    // Level + streak.
    GameFx.text(canvas, 'LV ${level + 1}',
        Offset(size.width - 40, 40), 12, _kMuscle.withValues(alpha: 0.95),
        weight: FontWeight.w800);
    if (streak > 1) {
      GameFx.text(canvas, '${streak}x', Offset(size.width - 40, 56), 11,
          _kSignal.withValues(alpha: 0.9), weight: FontWeight.w700);
    }

    if (tetanusGlow > 0.4) {
      GameFx.text(canvas, 'TETANUS', Offset(size.width / 2, size.height * 0.20),
          18, _kGreen.withValues(alpha: tetanusGlow), display: true, glow: 0.7);
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (missFlash > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kRed.withValues(alpha: (missFlash - 0.25) * 0.18));
    }
    if (fireFlash > 0.4) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGreen.withValues(alpha: (fireFlash - 0.4) * 0.22));
    }
  }

  @override
  bool shouldRepaint(covariant _TwitchPainter old) => true;
}
