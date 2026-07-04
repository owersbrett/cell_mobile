import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';

// ═══ Spiral Arms ═══════════════════════════════════════════════════════════
//
// A galaxy disk rotates DIFFERENTIALLY — inner stars complete an orbit far
// faster than outer stars. Any pattern drawn on the disk therefore SHEARS and
// tries to wind itself into a tight smear ("the winding problem"). Real spiral
// arms survive because they are DENSITY WAVES — slow-rotating traffic-jam
// patterns the stars merely pass through — not fixed structures of the same
// stars.
//
// The player keeps the spiral coherent by PULSING on the beat: every on-beat
// tap reinforces the density wave and snaps the visible stars back onto crisp
// arms. Neglect it and coherence bleeds away — the raw, sheared orbital
// positions take over and the arms smear into a featureless disk.
//
// Rendering: ONE Ticker drives all physics; a single CustomPainter draws the
// whole disk, the arms, the beat ring and the HUD. No per-frame setState over
// a big widget tree.

// ── Feel constants (tune freely by playtest) ────────────────────────────────
const int _kStarCount = 170;

/// Coherence (0–1) is how crisp the arms are. It always bleeds away; on-beat
/// pulses top it up.
const double _kCohStart = 0.72;
const double _kCohDecayBase = 0.085; // per second at level 1
const double _kCohDecayPerLevel = 0.030;
const double _kCohOnBeatBoost = 0.16; // ×accuracy
const double _kCohMissedBeat = 0.07; // passive miss (beat passed untapped)
const double _kCohBadTap = 0.10; // tapped off-beat

/// Beat timing. Period shrinks and the hit window tightens as you accelerate.
const double _kBeatPeriodL1 = 1.10; // seconds
const double _kBeatPeriodMin = 0.60;
const double _kBeatPeriodPerLevel = 0.12;
const double _kHitWindowL1 = 0.17; // fraction of the beat cycle
const double _kHitWindowMin = 0.085;
const double _kHitWindowPerLevel = 0.020;

/// Scoring.
const double _kPointsPerSec = 11.0; // ×coherence, dripped every second
const int _kOnBeatBase = 8; // ×multiplier ×accuracy

/// Differential rotation. Inner stars spin faster: omega(r) ~ 1/(soft + r).
const double _kOmegaBase = 0.85;
const double _kOmegaSoft = 0.28;
const double _kOmegaPerLevel = 0.18;

/// The density wave itself rotates SLOWLY (the pattern speed) — far slower than
/// the stars. That contrast is the whole point.
const double _kPatternSpeed = 0.16;

/// How tightly the arms wind (radians of sweep across the disk).
const double _kWind = 3.4;

const double _kLevelEverySec = 12.0; // ramps difficulty over the 60s round
const int _kMaxLevel = 5;
const int _kMultiplierCap = 20; // streak capped here for the multiplier

// ── Palette ──────────────────────────────────────────────────────────────────
const _kFont = 'Outfit';
const _kVoid = Color(0xFF07060D);
const _kCore = Color(0xFFFFE9B0);
const _kArmHot = Color(0xFFFFB060); // density-wave glow (Potatuhs orange-gold)
const _kArmCool = Color(0xFF8FA7FF); // young blue stars in the arms
const _kAccent = Color(0xFFE1A636);
const _kGood = Color(0xFF69F0AE);
const _kBad = Color(0xFFFF6E6E);
const _kWhite = Colors.white;

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Static, cheap, drawn statically in
// the pre-game intro. They redraw the LITERAL galaxy the player meets, using the
// game's own palette + crisp-vs-sheared thesis (display = lerp(orbit, crisp,
// coherence)) so the card shows exactly what "crisp arms" vs "a smear" mean.
// ═══════════════════════════════════════════════════════════════════════════

void _legendText(
  Canvas canvas,
  String text,
  Offset at, {
  required double size,
  required Color color,
  bool bold = true,
  bool leftAlign = false,
  bool rightAlign = false,
  Color? glow,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 1.0,
        color: color,
        shadows: glow != null ? [Shadow(color: glow, blurRadius: 12)] : null,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = rightAlign
      ? at.dx - tp.width
      : (leftAlign ? at.dx : at.dx - tp.width / 2);
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

class _LegendStar {
  final double r; // 0–1 radius fraction
  final double jitter; // spread around the arm spine
  final int arm;
  final double brightness;
  final bool blue;
  const _LegendStar(this.r, this.jitter, this.arm, this.brightness, this.blue);
}

/// Deterministic star set for a legend disk (fewer than live play — static).
List<_LegendStar> _legendStars(int arms, [int count = 90]) {
  final rng = math.Random(11);
  final out = <_LegendStar>[];
  for (var i = 0; i < count; i++) {
    final r = 0.16 + 0.82 * math.sqrt(rng.nextDouble());
    final arm = rng.nextInt(arms);
    final jitter = (rng.nextDouble() - 0.5) * 0.55;
    out.add(_LegendStar(
        r, jitter, arm, 0.45 + rng.nextDouble() * 0.55, rng.nextDouble() < 0.28));
  }
  return out;
}

/// The void backdrop + a faint deterministic star scatter (game background).
void _legendVoid(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _kVoid);
  final w = math.max(1, size.width.toInt());
  final h = math.max(1, size.height.toInt());
  final bg = Paint();
  for (var i = 0; i < 46; i++) {
    final a = 0.10 + 0.16 * ((i * 31 % 100) / 100.0);
    bg.color = _kWhite.withValues(alpha: a);
    canvas.drawCircle(Offset((i * 73 % w).toDouble(), (i * 137 % h).toDouble()),
        i.isEven ? 0.8 : 1.3, bg);
  }
}

/// Draws one galaxy: disk glow, arm spines (only while coherent), stars whose
/// position lerps between the SHEARED orbit and the CRISP wave by [coherence],
/// and the bright core — the same physics the live painter renders.
void _legendGalaxy(
  Canvas canvas,
  Offset center,
  double diskR, {
  required int arms,
  required double coherence,
  double patternPhase = 0.7,
  double shear = 3.2,
}) {
  if (diskR <= 1) return;

  // Faint disk halo.
  canvas.drawCircle(
    center,
    diskR,
    Paint()
      ..shader = RadialGradient(colors: [
        _kAccent.withValues(alpha: 0.06),
        _kAccent.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: center, radius: diskR)),
  );

  // Arm spines glow only while the wave is coherent — the density wave itself.
  final glow = (coherence - 0.1).clamp(0.0, 1.0);
  if (glow > 0.01) {
    for (var arm = 0; arm < arms; arm++) {
      final path = Path();
      final armBase = arm * (2 * math.pi / arms);
      var first = true;
      for (double r = 0.16; r <= 1.0; r += 0.05) {
        final ang = patternPhase + armBase - _kWind * r;
        final p = center + Offset(math.cos(ang), math.sin(ang)) * (diskR * r);
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = _kArmHot.withValues(alpha: 0.12 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  // Stars: display = lerp(sheared orbit, crisp wave) by coherence.
  final dot = Paint();
  for (final s in _legendStars(arms)) {
    final armBase = s.arm * (2 * math.pi / arms);
    final crisp = patternPhase + armBase - _kWind * s.r + s.jitter;
    // Sheared: inner stars (small r) wound much further — differential rotation.
    final orbit = crisp + shear / (_kOmegaSoft + s.r);
    final rad = diskR * s.r;
    final orbitP = Offset(math.cos(orbit), math.sin(orbit)) * rad;
    final crispP = Offset(math.cos(crisp), math.sin(crisp)) * rad;
    final pos = center + Offset.lerp(orbitP, crispP, coherence)!;

    final base = s.blue ? _kArmCool : _kArmHot;
    final col = Color.lerp(base, _kWhite, 0.25 + 0.35 * coherence)!;
    final rr = (1.1 + 1.7 * s.brightness) * (1.0 + 0.5 * coherence);
    final alpha = (s.brightness * (0.55 + 0.45 * coherence)).clamp(0.0, 1.0);
    dot.color = col.withValues(alpha: alpha);
    canvas.drawCircle(pos, rr, dot);
  }

  // Core.
  canvas.drawCircle(
    center,
    diskR * 0.30,
    Paint()
      ..shader = RadialGradient(colors: [
        _kCore.withValues(alpha: 0.85),
        _kArmHot.withValues(alpha: 0.20),
        _kArmHot.withValues(alpha: 0.0),
      ], stops: const [
        0.0,
        0.4,
        1.0
      ]).createShader(Rect.fromCircle(center: center, radius: diskR * 0.30)),
  );
  canvas.drawCircle(center, diskR * 0.05, Paint()..color = _kWhite);
}

/// The incoming/target beat rings (the timing tell the player pulses on).
void _legendBeatRing(Canvas canvas, Offset center, double diskR,
    {double beatPhase = 0.86, bool onBeat = true}) {
  final targetR = diskR * 1.18;
  final outerR = diskR * 1.62;
  canvas.drawCircle(
    center,
    targetR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = onBeat ? 3.0 : 1.6
      ..color =
          (onBeat ? _kGood : _kAccent).withValues(alpha: onBeat ? 0.9 : 0.4),
  );
  final incomingR = outerR + (targetR - outerR) * beatPhase;
  canvas.drawCircle(
    center,
    incomingR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kWhite.withValues(alpha: 0.55 + 0.35 * beatPhase),
  );
}

/// The coherence HUD bar (same colors/states as the live game top bar).
void _legendCoherenceBar(Canvas canvas, Size size, double coherence) {
  const pad = 22.0;
  final top = size.height * 0.10;
  final w = size.width - pad * 2;
  if (w <= 4) return;
  const h = 12.0;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, top, w, h), const Radius.circular(6)),
    Paint()..color = _kWhite.withValues(alpha: 0.08),
  );
  final fillW = (w * coherence).clamp(0.0, w);
  final crisp = coherence > 0.66;
  final mid = coherence > 0.33;
  final fillColor = crisp ? _kGood : (mid ? _kAccent : _kBad);
  if (fillW > 2) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, top, fillW, h), const Radius.circular(6)),
      Paint()..color = fillColor.withValues(alpha: 0.9),
    );
  }
  final state = crisp ? 'CRISP' : (mid ? 'SHEARING' : 'SMEARING');
  _legendText(canvas, 'ARM COHERENCE', Offset(pad + 2, top + h + 10),
      size: 9, color: _kWhite.withValues(alpha: 0.55), leftAlign: true);
  _legendText(canvas, state, Offset(size.width - pad - 2, top + h + 10),
      size: 9, color: fillColor, rightAlign: true);
}

// ── Frame 1 · the core object + the verb ────────────────────────────────────
void _legendPulse(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);
  final center = Offset(size.width / 2, size.height * 0.48);
  final diskR = math.min(size.width, size.height) * 0.30;
  _legendGalaxy(canvas, center, diskR, arms: 2, coherence: 0.92);
  _legendBeatRing(canvas, center, diskR, beatPhase: 0.86, onBeat: true);
  _legendText(canvas, 'PULSE ON THE BEAT',
      Offset(center.dx, center.dy + diskR * 1.6),
      size: 11, color: _kAccent.withValues(alpha: 0.85));
}

// ── Frame 2 · how to score ──────────────────────────────────────────────────
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);
  final center = Offset(size.width / 2, size.height * 0.56);
  final diskR = math.min(size.width, size.height) * 0.27;
  _legendGalaxy(canvas, center, diskR, arms: 2, coherence: 0.95);
  _legendCoherenceBar(canvas, size, 0.95);
  _legendText(canvas, 'PERFECT  +18',
      Offset(center.dx, center.dy - diskR * 1.25),
      size: 18, color: _kGood, glow: _kGood.withValues(alpha: 0.7));
  _legendText(canvas, '×3.0  · 12 streak',
      Offset(center.dx, center.dy + diskR * 1.45),
      size: 12, color: _kGood);
}

// ── Frame 3 · the danger ────────────────────────────────────────────────────
void _legendSmear(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);
  final center = Offset(size.width / 2, size.height * 0.56);
  final diskR = math.min(size.width, size.height) * 0.30;
  _legendGalaxy(canvas, center, diskR, arms: 2, coherence: 0.12, shear: 5.5);
  // Red bleed — the game's missed-beat flash.
  canvas.drawRect(
      Offset.zero & size, Paint()..color = _kBad.withValues(alpha: 0.10));
  _legendCoherenceBar(canvas, size, 0.14);
  _legendText(canvas, 'off-beat', Offset(center.dx, center.dy - diskR * 1.25),
      size: 15, color: _kBad);
}

// ── Frame 4 · the escalation ────────────────────────────────────────────────
void _legendLevels(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);
  final cy = size.height * 0.44;
  final xs = [size.width * 0.22, size.width * 0.5, size.width * 0.78];
  const arms = [2, 3, 4];
  final r = math.min(size.width * 0.15, size.height * 0.19);
  for (var i = 0; i < 3; i++) {
    _legendGalaxy(canvas, Offset(xs[i], cy), r,
        arms: arms[i], coherence: 0.9, patternPhase: 0.5 + i);
    _legendText(canvas, '${arms[i]} ARMS', Offset(xs[i], cy + r * 1.55),
        size: 11, color: _kAccent);
  }
  _legendText(canvas, 'FASTER SPIN · TIGHTER BEAT',
      Offset(size.width / 2, size.height * 0.85),
      size: 11, color: _kWhite.withValues(alpha: 0.7));
}

/// The visual manual for Spiral Arms — wired into the registry spec.
final List<LegendFrame> spiralArmsLegendFrames = [
  const LegendFrame(
      caption: "Tap on the beat to pulse the galaxy's spiral wave",
      paint: _legendPulse),
  const LegendFrame(
      caption: 'Crisp arms score every second — chain on-beat pulses',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Miss the beat and the arms shear into a smear',
      paint: _legendSmear),
  const LegendFrame(
      caption: 'Levels add arms (2 to 4) and tighten the beat',
      paint: _legendLevels),
];

/// "Spiral Arms" — pulse on the beat to reinforce the galaxy's density wave and
/// keep its spiral arms crisp while differential rotation tries to shear them
/// into a featureless smear.
class SpiralArmsGame extends StatefulWidget {
  final MiniGameSession session;
  const SpiralArmsGame({super.key, required this.session});

  @override
  State<SpiralArmsGame> createState() => _SpiralArmsGameState();
}

class _SpiralArmsGameState extends State<SpiralArmsGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random(7);

  final List<_Star> _stars = [];
  int _arms = 2;

  // ── Core run state ──────────────────────────────────────────────────────────
  bool _wasRunning = false;
  double _runTime = 0.0;
  int _level = 1;
  double _coherence = _kCohStart;
  double _patternPhase = 0.0;

  // Beat.
  double _beatPhase = 0.0; // 0→1 each beat; hit point is the wrap boundary.
  bool _beatScored = false; // one scoring tap per beat.

  // Streak / scoring.
  int _streak = 0;
  double _pointAcc = 0.0; // fractional point accumulator (drip).

  // Juice.
  double _pulseFlash = 0.0; // ring bloom on a good pulse, 1→0
  double _badFlash = 0.0; // red flash on a bad/missed beat, 1→0
  double _coreThrob = 0.0; // core brightens on the beat boundary
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  // ── Derived ─────────────────────────────────────────────────────────────────
  double get _beatPeriod => math.max(
      _kBeatPeriodMin, _kBeatPeriodL1 - (_level - 1) * _kBeatPeriodPerLevel);
  double get _hitWindow => math.max(
      _kHitWindowMin, _kHitWindowL1 - (_level - 1) * _kHitWindowPerLevel);
  double get _omegaScale => _kOmegaBase + (_level - 1) * _kOmegaPerLevel;
  double get _decayRate => _kCohDecayBase + (_level - 1) * _kCohDecayPerLevel;
  int get _armsForLevel => _level >= 5 ? 4 : (_level >= 3 ? 3 : 2);
  double get _multiplier => 1.0 + math.min(_streak, _kMultiplierCap) / 5.0;

  /// Distance from the beat hit point (the wrap boundary), 0 = perfect.
  double get _beatError => math.min(_beatPhase, 1.0 - _beatPhase);

  @override
  void initState() {
    super.initState();
    _buildStars(_armsForLevel);
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself on the beat.
    // Registered always (harmless in normal play — the host only calls it in
    // autoplay). See [_autoStep]. Rhythm game → default cadence (every ~250ms
    // tick) so the bot can act on every beat.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free pulse per host tick (~250ms), on the beat — never off it.
  ///
  /// The beat ring shrinks continuously ([_beatPhase] 0→1 each beat, advancing
  /// at 1/[_beatPeriod] per second); the hit point is the wrap boundary and
  /// [_beatError] is the distance to it (0 = perfect). Because the host only
  /// polls every ~250ms while the ring keeps moving, we don't just "pulse if
  /// on target now" — we look ONE tick ahead and fire at the local minimum of
  /// the beat error (the ring's closest approach to the target ring):
  ///
  ///   • Only ever fire when firing NOW already scores — i.e. the current error
  ///     is inside the on-beat window ([_hitWindow]). Tapping outside it is an
  ///     off-beat penalty that resets the streak, so we never do it.
  ///   • Predict the error one tick ahead ([_beatPhase] + rate·0.25, wrapped).
  ///     If a tighter (closer-to-beat) tick is still ahead we wait for it; we
  ///     fire only when NOW is at least as close as NEXT — the local minimum.
  ///
  /// [_handleTap] flips [_beatScored], so extra ticks in the same beat no-op:
  /// exactly one on-beat pulse is banked per beat. Deterministic; no taps.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_beatScored) return; // already banked this beat — nothing to do.

    // The host drives this on ~250ms cadence; look exactly one window ahead.
    const window = 0.25;
    final rate = 1.0 / _beatPeriod; // beatPhase advances this much per second.

    final nowErr = _beatError;
    // Off-beat would reset the streak — only pulse when NOW already scores.
    if (nowErr > _hitWindow) return;

    // Predict the beat error one tick ahead (wrap into the next beat if needed).
    final nextPhase = _beatPhase + rate * window;
    final wrapped = nextPhase - nextPhase.floorToDouble(); // 0..1
    final nextErr = math.min(wrapped, 1.0 - wrapped);

    // A tighter tick is still ahead → wait for the local minimum rather than
    // pulse early. Fire only when NOW is at least as close as NEXT.
    if (nextErr < nowErr) return;

    _handleTap();
  }

  // ── Star field ────────────────────────────────────────────────────────────
  // Each star keeps a FIXED radius and arm membership, plus a live orbital
  // angle that advances under differential rotation. Its crisp density-wave
  // angle is derived each frame from the (slow) pattern phase.
  void _buildStars(int arms) {
    _arms = arms;
    _stars.clear();
    for (var i = 0; i < _kStarCount; i++) {
      // Bias radius outward a little so the disk isn't core-heavy.
      final r = 0.16 + 0.82 * math.sqrt(_rng.nextDouble());
      final arm = _rng.nextInt(arms);
      // Angular spread around the arm spine — a populated arm, not a wire.
      final jitter = (_rng.nextDouble() - 0.5) * 0.55;
      final star = _Star(
        r: r,
        arm: arm,
        jitter: jitter,
        brightness: 0.45 + _rng.nextDouble() * 0.55,
        twinklePhase: _rng.nextDouble() * math.pi * 2,
        blue: _rng.nextDouble() < 0.28, // young blue stars hug the arms
      );
      star.orbitAngle = _crispAngle(star, arms);
      _stars.add(star);
    }
  }

  double _crispAngle(_Star s, int arms) {
    final armBase = s.arm * (2 * math.pi / arms);
    // Trailing logarithmic-ish spiral; the wave rotates at the pattern speed.
    final wind = -_kWind * s.r;
    return _patternPhase + armBase + wind + s.jitter;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;

    // Detect run start → fresh round.
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // The density wave always drifts slowly (calm in the ready state too).
    _patternPhase = _wrap(_patternPhase + _kPatternSpeed * dt);

    if (running) {
      _runTime += dt;

      // Difficulty ramp.
      final newLevel =
          (1 + (_runTime / _kLevelEverySec).floor()).clamp(1, _kMaxLevel);
      if (newLevel != _level) {
        _level = newLevel;
        if (_armsForLevel != _arms) _buildStars(_armsForLevel);
      }

      // Beat advance + boundary handling.
      _beatPhase += dt / _beatPeriod;
      if (_beatPhase >= 1.0) {
        _beatPhase -= 1.0;
        _coreThrob = 1.0;
        if (!_beatScored) {
          // Beat passed untapped — the wave weakens.
          _coherence = math.max(0.0, _coherence - _kCohMissedBeat);
          _streak = 0;
          _badFlash = 0.5;
        }
        _beatScored = false;
      }

      // Coherence always bleeds (the disk shears toward a smear).
      _coherence = (_coherence - _decayRate * dt).clamp(0.0, 1.0);

      // Drip points for keeping the arms crisp.
      _pointAcc += _kPointsPerSec * _coherence * dt;
      if (_pointAcc >= 1.0) {
        final whole = _pointAcc.floor();
        widget.session.addScore(whole);
        _pointAcc -= whole;
      }
    } else {
      // Calm ready state: hold the arms nicely crisp and still.
      _coherence = _coherence + (0.85 - _coherence) * math.min(1.0, dt * 2.0);
      _beatPhase = 0.0;
    }

    // Stars orbit under differential rotation (always — alive in ready state).
    final spin = running ? _omegaScale : 0.28;
    for (final s in _stars) {
      final omega = spin / (_kOmegaSoft + s.r);
      s.orbitAngle = _wrap(s.orbitAngle + omega * dt);
    }

    // Decay juice.
    _pulseFlash = math.max(0.0, _pulseFlash - dt * 2.6);
    _badFlash = math.max(0.0, _badFlash - dt * 3.0);
    _coreThrob = math.max(0.0, _coreThrob - dt * 3.2);
    for (final s in _sparks) {
      s.age += dt;
    }
    _sparks.removeWhere((s) => s.age >= s.life);
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    setState(() {});
  }

  void _resetRun() {
    _runTime = 0.0;
    _level = 1;
    _coherence = _kCohStart;
    _streak = 0;
    _pointAcc = 0.0;
    _beatPhase = 0.0;
    _beatScored = false;
    _sparks.clear();
    _popups.clear();
    if (_armsForLevel != _arms) _buildStars(_armsForLevel);
  }

  static double _wrap(double a) {
    const tau = 2 * math.pi;
    a %= tau;
    return a < 0 ? a + tau : a;
  }

  // ── Input ───────────────────────────────────────────────────────────────────
  void _handleTap() {
    if (!widget.session.isRunning) return;
    final err = _beatError;
    final window = _hitWindow;

    if (err <= window && !_beatScored) {
      // On-beat pulse — reinforce the density wave.
      _beatScored = true;
      final accuracy = (1.0 - err / window).clamp(0.0, 1.0);
      _coherence = (_coherence + _kCohOnBeatBoost * accuracy).clamp(0.0, 1.0);
      _streak++;
      widget.session.noteStreak(_streak);

      final pts = math.max(1, (_kOnBeatBase * _multiplier * accuracy).round());
      widget.session.addScore(pts);

      _pulseFlash = 1.0;
      _spawnSparks(accuracy > 0.7 ? 20 : 12);
      final label = accuracy > 0.85
          ? 'PERFECT  +$pts'
          : (accuracy > 0.5 ? '+$pts' : 'ok  +$pts');
      _popups.add(_Popup(label, _kGood, big: accuracy > 0.85));
    } else if (!_beatScored) {
      // Off-beat — disrupts the wave.
      _beatScored = true; // consume the beat; no spamming back in
      _coherence = math.max(0.0, _coherence - _kCohBadTap);
      _streak = 0;
      _badFlash = 0.7;
      _popups.add(_Popup('off-beat', _kBad, big: false));
    }
  }

  void _spawnSparks(int count) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed = 70.0 + _rng.nextDouble() * 150.0;
      _sparks.add(_Spark(
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.35 + _rng.nextDouble() * 0.4,
        radius: 1.0 + _rng.nextDouble() * 2.0,
        color: i.isEven ? _kArmHot : _kWhite,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handleTap(),
      child: ClipRect(
        child: CustomPaint(
          painter: _SpiralPainter(
            stars: _stars,
            arms: _arms,
            patternPhase: _patternPhase,
            wind: _kWind,
            coherence: _coherence,
            beatPhase: _beatPhase,
            hitWindow: _hitWindow,
            beatError: _beatError,
            level: _level,
            streak: _streak,
            multiplier: _multiplier,
            running: widget.session.isRunning,
            pulseFlash: _pulseFlash,
            badFlash: _badFlash,
            coreThrob: _coreThrob,
            sparks: _sparks,
            popups: _popups,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double r; // 0–1 radius fraction
  final int arm;
  final double jitter; // angular spread around the arm spine
  final double brightness;
  final double twinklePhase;
  final bool blue;
  double orbitAngle = 0.0;

  _Star({
    required this.r,
    required this.arm,
    required this.jitter,
    required this.brightness,
    required this.twinklePhase,
    required this.blue,
  });
}

class _Spark {
  Offset vel;
  double age = 0.0;
  final double life;
  final double radius;
  final Color color;
  _Spark({
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
  });
}

class _Popup {
  final String text;
  final Color color;
  final bool big;
  final double life;
  double age = 0.0;
  _Popup(this.text, this.color, {required this.big}) : life = big ? 1.2 : 0.85;
}

// ─────────────────────────────────────────────────────────────────────────────

class _SpiralPainter extends CustomPainter {
  final List<_Star> stars;
  final int arms;
  final double patternPhase;
  final double wind;
  final double coherence;
  final double beatPhase;
  final double hitWindow;
  final double beatError;
  final int level;
  final int streak;
  final double multiplier;
  final bool running;
  final double pulseFlash;
  final double badFlash;
  final double coreThrob;
  final List<_Spark> sparks;
  final List<_Popup> popups;

  _SpiralPainter({
    required this.stars,
    required this.arms,
    required this.patternPhase,
    required this.wind,
    required this.coherence,
    required this.beatPhase,
    required this.hitWindow,
    required this.beatError,
    required this.level,
    required this.streak,
    required this.multiplier,
    required this.running,
    required this.pulseFlash,
    required this.badFlash,
    required this.coreThrob,
    required this.sparks,
    required this.popups,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final diskR = math.min(size.width, size.height) * 0.40;

    _paintBackground(canvas, size, center, diskR);
    _paintDisk(canvas, center, diskR);
    _paintStars(canvas, center, diskR);
    _paintCore(canvas, center, diskR);
    _paintBeatRing(canvas, center, diskR);
    _paintSparks(canvas, center);
    _paintFlashes(canvas, size);
    _paintHud(canvas, size);
    _paintPopups(canvas, size);
  }

  // ── Background ──────────────────────────────────────────────────────────────
  void _paintBackground(Canvas canvas, Size size, Offset center, double diskR) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kVoid);

    // Soft galactic halo behind the disk.
    canvas.drawCircle(
      center,
      diskR * 1.9,
      Paint()
        ..shader = RadialGradient(colors: [
          _kAccent.withValues(alpha: 0.10),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: diskR * 1.9)),
    );

    // A scatter of faint background stars (deterministic — derived from index).
    final bg = Paint()..color = _kWhite.withValues(alpha: 0.5);
    for (var i = 0; i < 70; i++) {
      final x = (i * 73 % size.width.toInt()).toDouble();
      final y = (i * 137 % size.height.toInt()).toDouble();
      final a = 0.10 + 0.18 * ((i * 31 % 100) / 100.0);
      bg.color = _kWhite.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.8 : 1.3, bg);
    }
  }

  // ── Faint disk + the density-wave arm spines ───────────────────────────────
  void _paintDisk(Canvas canvas, Offset center, double diskR) {
    canvas.drawCircle(
      center,
      diskR,
      Paint()
        ..shader = RadialGradient(colors: [
          _kAccent.withValues(alpha: 0.05),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: diskR)),
    );

    // The arm spines glow only while the wave is coherent — they are the
    // density wave itself, and they smear away as coherence drops.
    final glow = (coherence - 0.1).clamp(0.0, 1.0);
    if (glow <= 0.01) return;
    for (var arm = 0; arm < arms; arm++) {
      final path = Path();
      final armBase = arm * (2 * math.pi / arms);
      bool first = true;
      for (double r = 0.16; r <= 1.0; r += 0.04) {
        final ang = patternPhase + armBase - wind * r;
        final p = center + Offset(math.cos(ang), math.sin(ang)) * (diskR * r);
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = _kArmHot.withValues(alpha: 0.10 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  // ── Stars: display position lerps between the SHEARED orbital position and
  // the CRISP density-wave position by coherence. Coherence high → snapped onto
  // the arms; coherence low → raw sheared orbits → a featureless smear. ───────
  void _paintStars(Canvas canvas, Offset center, double diskR) {
    final dot = Paint();
    for (final s in stars) {
      final armBase = s.arm * (2 * math.pi / arms);
      final crisp = patternPhase + armBase - wind * s.r + s.jitter;
      final rad = diskR * s.r;

      final orbitP =
          Offset(math.cos(s.orbitAngle), math.sin(s.orbitAngle)) * rad;
      final crispP = Offset(math.cos(crisp), math.sin(crisp)) * rad;
      final pos = center + Offset.lerp(orbitP, crispP, coherence)!;

      // Density enhancement: a star reads as "in the arm" when its true orbit
      // currently sits near the crisp spine — the traffic-jam brightening.
      final dAng = (_angDiff(s.orbitAngle, crisp)).abs();
      final inArm = (1.0 - (dAng / 0.5)).clamp(0.0, 1.0);
      final twinkle =
          0.85 + 0.15 * math.sin(patternPhase * 6 + s.twinklePhase);

      final base = s.blue ? _kArmCool : _kArmHot;
      final col = Color.lerp(base, _kWhite, 0.25 + 0.45 * inArm * coherence)!;
      final r = (1.1 + 1.9 * s.brightness) * (1.0 + 0.7 * inArm * coherence);
      final alpha = (s.brightness * twinkle * (0.55 + 0.45 * coherence))
          .clamp(0.0, 1.0);

      // Halo on the brighter arm stars.
      if (inArm > 0.4 && coherence > 0.3) {
        dot
          ..color = col.withValues(alpha: 0.25 * inArm * coherence)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(pos, r * 2.4, dot);
        dot.maskFilter = null;
      }
      dot.color = col.withValues(alpha: alpha);
      canvas.drawCircle(pos, r, dot);
    }
  }

  void _paintCore(Canvas canvas, Offset center, double diskR) {
    final throb = 1.0 + 0.18 * coreThrob;
    canvas.drawCircle(
      center,
      diskR * 0.30 * throb,
      Paint()
        ..shader = RadialGradient(colors: [
          _kCore.withValues(alpha: 0.85),
          _kArmHot.withValues(alpha: 0.20),
          _kArmHot.withValues(alpha: 0.0),
        ], stops: const [
          0.0,
          0.4,
          1.0
        ]).createShader(
            Rect.fromCircle(center: center, radius: diskR * 0.30 * throb)),
    );
    canvas.drawCircle(
        center, diskR * 0.05 * throb, Paint()..color = _kWhite);
  }

  // ── Beat ring: a ring shrinks from the disk edge to the target ring each
  // beat; pulse when it lands on the target. Tightness shows the hit window. ──
  void _paintBeatRing(Canvas canvas, Offset center, double diskR) {
    if (!running) return;
    final targetR = diskR * 1.18;
    final outerR = diskR * 1.62;

    // Target ring (fixed) — the line you want the incoming ring to land on.
    final onBeat = beatError <= hitWindow;
    canvas.drawCircle(
      center,
      targetR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = onBeat ? 3.0 : 1.6
        ..color = (onBeat ? _kGood : _kAccent)
            .withValues(alpha: onBeat ? 0.9 : 0.4),
    );

    // Incoming ring: radius lerps from outer → target as the beat completes.
    final incomingR = outerR + (targetR - outerR) * beatPhase;
    canvas.drawCircle(
      center,
      incomingR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kWhite.withValues(alpha: 0.55 + 0.35 * beatPhase),
    );

    // Pulse bloom on a good hit.
    if (pulseFlash > 0) {
      canvas.drawCircle(
        center,
        targetR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 + 10 * pulseFlash
          ..color = _kGood.withValues(alpha: 0.5 * pulseFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    _text(canvas, 'PULSE ON THE BEAT',
        Offset(center.dx, center.dy + diskR * 1.55),
        size: 10, color: _kAccent.withValues(alpha: 0.7), bold: true);
  }

  void _paintSparks(Canvas canvas, Offset center) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final pos = center + s.vel * s.age;
      canvas.drawCircle(
          pos, s.radius * t, Paint()..color = s.color.withValues(alpha: t));
    }
  }

  void _paintFlashes(Canvas canvas, Size size) {
    if (badFlash > 0.05) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: 0.18 * badFlash));
    }
  }

  // ── HUD: coherence bar, level, streak/multiplier ──────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    // Coherence bar across the top.
    const pad = 18.0;
    const top = 14.0;
    final w = size.width - pad * 2;
    const h = 12.0;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, top, w, h), const Radius.circular(6));
    canvas.drawRRect(track, Paint()..color = _kWhite.withValues(alpha: 0.08));

    final fillW = (w * coherence).clamp(0.0, w);
    final crisp = coherence > 0.66;
    final mid = coherence > 0.33;
    final fillColor = crisp ? _kGood : (mid ? _kAccent : _kBad);
    if (fillW > 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, top, fillW, h), const Radius.circular(6)),
        Paint()..color = fillColor.withValues(alpha: 0.9),
      );
    }
    _text(canvas, 'ARM COHERENCE', Offset(pad + 2, top + h + 11),
        size: 9,
        color: _kWhite.withValues(alpha: 0.55),
        bold: true,
        leftAlign: true);

    final state = crisp ? 'CRISP' : (mid ? 'SHEARING' : 'SMEARING');
    _text(canvas, state, Offset(size.width - pad - 2, top + h + 11),
        size: 9, color: fillColor, bold: true, rightAlign: true);

    // Level + streak/multiplier badge — top corners below the bar handled in
    // canvas to avoid widget rebuilds.
    _text(canvas, 'LV $level', Offset(pad + 2, top + h + 30),
        size: 11, color: _kAccent, bold: true, leftAlign: true);

    if (streak > 1) {
      _text(canvas, '×${multiplier.toStringAsFixed(1)}  · $streak streak',
          Offset(size.width - pad - 2, top + h + 30),
          size: 11, color: _kGood, bold: true, rightAlign: true);
    }
  }

  void _paintPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 40.0 * t;
      _text(
        canvas,
        p.text,
        Offset(size.width / 2, size.height * 0.30 - rise),
        size: p.big ? 20 : 15,
        color: p.color.withValues(alpha: alpha),
        bold: true,
        glow: p.color.withValues(alpha: alpha * 0.8),
      );
    }
  }

  double _angDiff(double a, double b) {
    var d = (a - b) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    return d;
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required double size,
    required Color color,
    bool bold = false,
    bool leftAlign = false,
    bool rightAlign = false,
    Color? glow,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 1.0,
          color: color,
          shadows:
              glow != null ? [Shadow(color: glow, blurRadius: 12)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = rightAlign
        ? at.dx - tp.width
        : (leftAlign ? at.dx : at.dx - tp.width / 2);
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter old) => true;
}
