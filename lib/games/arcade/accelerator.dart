import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

// ── Feel constants ────────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely. These are SHARED by
// every rig (accelerator beam) — each rig derives its own level-scaled values
// from them but the base feel is common.

/// Base drain rate (energy/s) at level 1.  Energy is always 0-1.
const double _kDrainBase = 0.18;

/// Extra drain added every level (multiplied by level index 0-based).
/// So level 2 drains at _kDrainBase + 1*_kDrainStep, etc.
const double _kDrainStep = 0.04;

/// Energy added per tap.  Tapers by 5% per level so spamming helps less.
const double _kTapBoost = 0.12;

/// Full-width of the target band at level 1 (fraction of gauge, 0-1 space).
const double _kBandWidthL1 = 0.28;

/// Band width shrinks by this per level; clamped to [_kBandMinWidth].
const double _kBandShrinkPerLevel = 0.03;

/// Narrowest the band can ever get (keeps it humanly possible at extreme levels).
const double _kBandMinWidth = 0.06;

/// Centre of the target band (0 = bottom, 1 = top).  Fixed throughout.
const double _kBandCentre = 0.62;

/// Energy must stay in-band for this many seconds to level up.
const double _kLevelUpDwell = 2.5; // seconds — shorter feels faster

/// Points awarded on level-up: base + (level² × bonus).
const int _kPointsBase = 30;
const int _kPointsBonusPerLevelSq = 8;

/// Points per second of in-band dwell (ongoing drip while holding the band).
const double _kDwellPointsPerSec = 4.0;

/// How fast the charge meter (dwellAcc) bleeds back down while OUT of band,
/// in seconds-of-charge lost per real second. Slightly gentler than the 1.0/s
/// fill rate so a brief slip is recoverable instead of a full reset.
const double _kDwellPullbackRate = 0.8;

/// How long the single→double split animation takes (seconds).
const double _kSplitDuration = 0.9;

/// ATTRACT autopilot cadence — the host calls the hook roughly this often
/// (seconds). Used to look one tick ahead: pump a beam whose energy would drain
/// out the bottom of its band before the next call.
const double _kAutoTick = 0.25;

// ── Colour palette ────────────────────────────────────────────────────────────
const _kFont = 'Avenir'; // matches Collider
const _kAccent = Color(0xFFCE93D8); // lighter purple — chrome / grid
const _kGreen = Color(0xFF69F0AE);
const _kOrange = Color(0xFFFF6E40);
const _kOrangeDeep = Color(0xFFE64A19);
const _kCyan = Color(0xFF00E5FF);
const _kCyanDeep = Color(0xFF0091EA);
const _kRed = Color(0xFFFF5252);
const _kWhite = Colors.white;

/// "Accelerator" — pump energy into a particle beam and hold resonance to
/// force a collision. Each collision advances a level (band narrows, drain
/// speeds up). At halftime a SECOND collider comes online: two beams drain at
/// once and the player must sustain both, one thumb per beam.
class AcceleratorGame extends StatefulWidget {
  final MiniGameSession session;
  const AcceleratorGame({Key? key, required this.session}) : super(key: key);

  @override
  State<AcceleratorGame> createState() => _AcceleratorGameState();
}

class _AcceleratorGameState extends State<AcceleratorGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Rigs (one accelerator beam each) ────────────────────────────────────────
  final List<_Rig> _rigs = [];

  // ── Global FX (shared across all rigs) ──────────────────────────────────────
  double _shake = 0.0; // screen-shake, 1 → 0
  double _idlePhase = 0.0;
  double _splitAnim = 0.0; // 0 = single rig centred, 1 = two rigs split
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  // Last known viewport, so tap handlers can resolve rig geometry off-frame.
  Size _size = const Size(400, 800);

  @override
  void initState() {
    super.initState();
    // Rig #1 — the cyan beam, present from the start.
    _rigs.add(_Rig(accent: _kCyan, accentDeep: _kCyanDeep, angle1: 0.0));
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
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
  /// One hands-free move per host tick (~250ms). Plays Accelerator *correctly*,
  /// not randomly: for each live beam it looks one tick ahead — if the needle
  /// is below its green band, or the constant drain would push it below the
  /// band before the next call, it taps that beam's PUMP handler. A needle
  /// already sitting comfortably in-band is left alone so it never overshoots
  /// out the top into the red. In the two-beam phase it services whichever
  /// beam(s) need energy, one competent pump each. The host owns the clock, so
  /// the round still ends on time; the bot just banks real dwell points.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    for (var i = 0; i < _rigs.length; i++) {
      final rig = _rigs[i];
      // Already at/above the band top — let it drain rather than blow past.
      if (rig.energy >= rig.bandMax) continue;
      // Where the needle will sit after one tick of constant drain.
      final projected = rig.energy - rig.drainRate * _kAutoTick;
      // Below the band now, or about to fall out the bottom → feed it.
      if (projected <= rig.bandMin) _pump(i);
    }
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;

    // ── Halftime: bring the second beam online exactly once ──────────────────
    if (running && _rigs.length == 1) {
      // Host owns the clock; halfway = remaining ≤ half the run length.
      final halfMs = widget.session.spec.durationSeconds * 500;
      if (widget.session.remaining.inMilliseconds <= halfMs) {
        _spawnSecondBeam();
      }
    }

    // Advance the split transition toward its target (only ever grows: once a
    // second beam exists it never leaves).
    if (_rigs.length > 1 && _splitAnim < 1.0) {
      _splitAnim = math.min(1.0, _splitAnim + dt / _kSplitDuration);
    }

    _idlePhase += dt;

    // ── Per-rig update ───────────────────────────────────────────────────────
    for (final rig in _rigs) {
      // Orbit particles regardless of running state (idle-drift during countdown).
      final orbitSpeed = running ? (0.8 + rig.energy * 2.4) : 0.25;
      rig.angle1 = _wrap(rig.angle1 + orbitSpeed * dt);
      rig.angle2 = _wrap(rig.angle2 + (orbitSpeed * 0.83 + 0.18) * dt);

      if (running) {
        // Drain energy constantly.
        rig.energy = (rig.energy - rig.drainRate * dt).clamp(0.0, 1.0);

        // Dwell and scoring.
        if (rig.inBand) {
          rig.dwellAcc += dt;
          final drip = (_kDwellPointsPerSec * dt).round();
          if (drip > 0) widget.session.addScore(drip);

          if (rig.dwellAcc >= _kLevelUpDwell) {
            _levelUp(rig);
          }
        } else {
          // Out of band: pull the charge meter back toward 0 instead of hard
          // resetting, so the player can recover by getting back in-band.
          if (rig.dwellAcc > 0.1) {
            rig.missFlash = 0.6;
          }
          rig.dwellAcc = math.max(0.0, rig.dwellAcc - dt * _kDwellPullbackRate);
        }
      }

      // Per-rig juice decay.
      rig.ringFlash = math.max(0.0, rig.ringFlash - dt * 2.8);
      rig.missFlash = math.max(0.0, rig.missFlash - dt * 3.5);
    }

    // ── Global juice decay ───────────────────────────────────────────────────
    _shake = math.max(0.0, _shake - dt * 4.5);

    for (final s in _sparks) {
      s.age += dt;
      s.vel *= math.pow(0.05, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    setState(() {});
  }

  static double _wrap(double a) {
    const tau = 2 * math.pi;
    a %= tau;
    return a < 0 ? a + tau : a;
  }

  void _spawnSecondBeam() {
    // Rig #2 — the orange beam. Starts fresh at level 1; rig #1 keeps its state.
    _rigs.add(_Rig(accent: _kOrange, accentDeep: _kOrangeDeep, angle1: math.pi * 0.5));
    _shake = 1.0;

    final origin = Offset(_size.width / 2, _size.height * 0.5);
    _popups.add(_Popup('SECOND BEAM ONLINE', origin, _kOrange, big: true));
    _spawnSparks(40, origin);
  }

  void _levelUp(_Rig rig) {
    final pts = _kPointsBase + (rig.level * rig.level * _kPointsBonusPerLevelSq);
    widget.session.addScore(pts);
    rig.level++;
    rig.dwellAcc = 0.0;
    rig.energy = rig.bandMin * 0.85; // reset energy below band for a fresh dwell

    rig.ringFlash = 1.0;
    _shake = 1.0;

    final slot = _rigs.indexOf(rig);
    final origin = _rigGeo(_size, _splitAnim, slot, _rigs.length).center;
    _popups.add(_Popup('LV${rig.level}  +$pts', origin, _kGreen, big: true));
    _spawnSparks(32, origin);
  }

  void _pump(int rigIndex) {
    if (!widget.session.isRunning) return;
    if (rigIndex < 0 || rigIndex >= _rigs.length) return;
    final rig = _rigs[rigIndex];
    rig.energy = (rig.energy + rig.tapBoost).clamp(0.0, 1.0);

    final origin = _rigGeo(_size, _splitAnim, rigIndex, _rigs.length).center;
    _spawnSparks(8, origin, small: true);
  }

  void _spawnSparks(int count, Offset origin, {bool small = false}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed =
          (small ? 60.0 : 130.0) + _rng.nextDouble() * (small ? 80 : 180);
      final palette = [
        _kWhite,
        _kAccent,
        _kGreen,
        _kCyan,
        const Color(0xFFFFE082),
      ];
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.35 + _rng.nextDouble() * 0.45,
        radius: 1.0 + _rng.nextDouble() * (small ? 1.4 : 2.4),
        color: palette[_rng.nextInt(palette.length)],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (!size.width.isFinite ||
          !size.height.isFinite ||
          size.width <= 0 ||
          size.height <= 0) {
        return const SizedBox.shrink();
      }
      _size = size;
      final w = size.width;

      final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 12 * _shake : 0.0;
      final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 12 * _shake : 0.0;

      final eased = _smooth(_splitAnim);
      final twoRigs = _rigs.length > 1;

      // ── Bottom PUMP button metrics ─────────────────────────────────────────
      const btnH = 66.0;
      const btnBottom = 18.0;
      const gap = 12.0;
      final singleW = math.min(w * 0.66, 340.0);
      final pairW = math.max(80.0, (w - gap * 3) / 2);

      return ClipRect(
        child: Stack(
          children: [
            // Everything visual lives on ONE painter (both rings, both gauges,
            // particles, sparks, popups, flashes).
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: CustomPaint(
                  painter: _AcceleratorPainter(
                    rigs: _rigs,
                    split: _splitAnim,
                    idlePhase: _idlePhase,
                    sparks: _sparks,
                    popups: _popups,
                  ),
                ),
              ),
            ),

            // Per-rig level badges (small widgets — allowed alongside the painter).
            ..._buildBadges(size),

            // Single centred PUMP button — fades out as the split animates in.
            Positioned(
              bottom: btnBottom,
              left: (w - singleW) / 2,
              width: singleW,
              height: btnH,
              child: Opacity(
                opacity: (1 - eased).clamp(0.0, 1.0),
                child: IgnorePointer(
                  ignoring: eased > 0.5,
                  child: _PumpButton(
                    color: _rigs[0].accent,
                    colorDeep: _rigs[0].accentDeep,
                    label: 'PUMP',
                    onPump: () => _pump(0),
                  ),
                ),
              ),
            ),

            // Two PUMP buttons once the second beam exists — fade in with split.
            // Bottom-LEFT (cyan) drives the TOP beam; bottom-RIGHT (orange) the BOTTOM.
            if (twoRigs)
              Positioned(
                bottom: btnBottom,
                left: gap,
                width: pairW,
                height: btnH,
                child: Opacity(
                  opacity: eased.clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: eased < 0.5,
                    child: _PumpButton(
                      color: _rigs[0].accent,
                      colorDeep: _rigs[0].accentDeep,
                      label: 'PUMP  TOP',
                      onPump: () => _pump(0),
                    ),
                  ),
                ),
              ),
            if (twoRigs)
              Positioned(
                bottom: btnBottom,
                left: w - gap - pairW,
                width: pairW,
                height: btnH,
                child: Opacity(
                  opacity: eased.clamp(0.0, 1.0),
                  child: IgnorePointer(
                    ignoring: eased < 0.5,
                    child: _PumpButton(
                      color: _rigs[1].accent,
                      colorDeep: _rigs[1].accentDeep,
                      label: 'PUMP  BOT',
                      onPump: () => _pump(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildBadges(Size size) {
    final list = <Widget>[];
    for (var i = 0; i < _rigs.length; i++) {
      final geo = _rigGeo(size, _splitAnim, i, _rigs.length);
      final top =
          (geo.center.dy - geo.radius - 26.0).clamp(6.0, size.height - 30.0);
      list.add(Positioned(top: top, right: 12, child: _badge(_rigs[i])));
    }
    return list;
  }

  Widget _badge(_Rig rig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rig.accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        'LV ${rig.level}',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: rig.accent.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-accelerator state. Each rig levels INDEPENDENTLY; feel constants are
// shared top-level, the level-scaled derived values live here.

class _Rig {
  double energy = 0.0; // 0-1 normalised
  double dwellAcc = 0.0; // seconds spent in-band this run
  int level = 1;

  double angle1;
  double angle2 = math.pi;

  double ringFlash = 0.0; // green bloom on level-up, 1 → 0
  double missFlash = 0.0; // red ring flash when out-of-band warning

  /// Identity colour — makes the button→beam mapping instantly legible.
  final Color accent;
  final Color accentDeep;

  _Rig({required this.accent, required this.accentDeep, double angle1 = 0.0})
      : angle1 = angle1;

  double get drainRate => _kDrainBase + (level - 1) * _kDrainStep;
  double get tapBoost => _kTapBoost * math.pow(0.95, level - 1).toDouble();
  double get bandWidth => math.max(
      _kBandMinWidth, _kBandWidthL1 - (level - 1) * _kBandShrinkPerLevel);
  double get bandMin => (_kBandCentre - bandWidth / 2).clamp(0.0, 1.0);
  double get bandMax => (_kBandCentre + bandWidth / 2).clamp(0.0, 1.0);
  bool get inBand => energy >= bandMin && energy <= bandMax;
}

// ─────────────────────────────────────────────────────────────────────────────

class _Spark {
  Offset pos; // absolute canvas origin
  Offset vel;
  double age = 0.0;
  final double life;
  final double radius;
  final Color color;

  _Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
  });
}

class _Popup {
  final String text;
  final Offset origin; // absolute canvas position
  final Color color;
  final bool big;
  final double life;
  double age = 0.0;
  _Popup(this.text, this.origin, this.color, {required this.big})
      : life = big ? 1.3 : 0.9;
}

// ─────────────────────────────────────────────────────────────────────────────
// Geometry. A single helper resolves ring centre + radius + gauge rect for a
// rig from the split animation and its slot, so the painter, badges and tap
// handlers all agree. Everything guarded against degenerate viewports.

class _RigGeo {
  final Offset center;
  final double radius;
  final Rect gauge;
  const _RigGeo(this.center, this.radius, this.gauge);

  Offset pointAt(double angle) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

/// Smoothstep 0..1.
double _smooth(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return t * t * (3 - 2 * t);
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;

Rect _gaugeRect(double top, double bottom, double h) {
  final hiTop = math.max(5.0, h - 40.0);
  final t = top.clamp(4.0, hiTop);
  final hiBot = math.max(t + 30.0, h - 8.0);
  final b = bottom.clamp(t + 30.0, hiBot);
  return Rect.fromLTWH(24.0, t, 22.0, b - t);
}

_RigGeo _rigGeo(Size size, double split, int slot, int rigCount) {
  final w = size.width;
  final h = size.height;
  final e = _smooth(split);

  final singleR = math.max(24.0, math.min(w, h) * 0.31);
  final twoR = math.max(24.0, math.min(w * 0.27, h * 0.15));

  if (rigCount <= 1) {
    return _RigGeo(
      Offset(w / 2, h * 0.46),
      singleR,
      _gaugeRect(80.0, math.max(120.0, h - 96.0), h),
    );
  }

  final r = _lerpD(singleR, twoR, e);
  if (slot == 0) {
    // Top beam: rises from centre to the upper third.
    final cy = _lerpD(h * 0.46, h * 0.29, e);
    final gTop = _lerpD(80.0, h * 0.09, e);
    final gBot = _lerpD(math.max(120.0, h - 96.0), h * 0.46, e);
    return _RigGeo(Offset(w / 2, cy), r, _gaugeRect(gTop, gBot, h));
  } else {
    // Bottom beam: sinks from centre to the lower third, clear of the buttons.
    final cy = _lerpD(h * 0.46, h * 0.70, e);
    final gTop = _lerpD(80.0, h * 0.52, e);
    final gBot = _lerpD(math.max(120.0, h - 96.0), h - 96.0, e);
    return _RigGeo(Offset(w / 2, cy), r, _gaugeRect(gTop, gBot, h));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AcceleratorPainter extends CustomPainter {
  final List<_Rig> rigs;
  final double split;
  final double idlePhase;
  final List<_Spark> sparks;
  final List<_Popup> popups;

  _AcceleratorPainter({
    required this.rigs,
    required this.split,
    required this.idlePhase,
    required this.sparks,
    required this.popups,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    _paintBackground(canvas, size);

    for (var i = 0; i < rigs.length; i++) {
      final rig = rigs[i];
      final geo = _rigGeo(size, split, i, rigs.length);
      _paintRigBackdrop(canvas, geo, rig);
      _paintRing(canvas, geo, rig);
      _paintParticle(canvas, geo, rig.angle1, rig.accent);
      _paintParticle(
          canvas, geo, rig.angle2, Color.lerp(rig.accent, _kWhite, 0.35)!);
      _paintGauge(canvas, geo, rig);
      _paintDwellArc(canvas, geo, rig);
      _paintRigFlash(canvas, geo, rig);
    }

    _paintSparks(canvas);
    _paintPopups(canvas);
  }

  // ── Background (shared) ──────────────────────────────────────────────────────

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF080811));

    final grid = Paint()
      ..color = _kAccent.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  // ── Per-rig backdrop (vignette + rotating ticks) ─────────────────────────────

  void _paintRigBackdrop(Canvas canvas, _RigGeo geom, _Rig rig) {
    canvas.drawCircle(
      geom.center,
      geom.radius * 1.8,
      Paint()
        ..shader = RadialGradient(colors: [
          rig.accentDeep.withValues(alpha: 0.12),
          rig.accentDeep.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: geom.center, radius: geom.radius * 1.8)),
    );

    final tick = Paint()
      ..color = rig.accent.withValues(alpha: 0.20)
      ..strokeWidth = 1.4;
    final spin = idlePhase * 0.12;
    for (var i = 0; i < 36; i++) {
      final a = spin + i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        geom.center + dir * (geom.radius * 1.32),
        geom.center + dir * (geom.radius * 1.32 + (i % 6 == 0 ? 9.0 : 4.0)),
        tick,
      );
    }
  }

  // ── Ring ────────────────────────────────────────────────────────────────────

  void _paintRing(Canvas canvas, _RigGeo geom, _Rig rig) {
    final dwellFrac = (rig.dwellAcc / _kLevelUpDwell).clamp(0.0, 1.0);

    final Color ringTint;
    if (rig.inBand) {
      ringTint = Color.lerp(rig.accentDeep, _kGreen, 0.55 + 0.45 * dwellFrac)!;
    } else if (rig.energy > rig.bandMax) {
      ringTint = _kRed;
    } else {
      ringTint = rig.accentDeep;
    }

    // Bloom.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = ringTint.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Beam pipe.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rig.inBand ? 3.5 : 2.8
        ..color = ringTint.withValues(alpha: rig.inBand ? 0.80 : 0.50),
    );

    // Miss flash — outer red halo.
    if (rig.missFlash > 0) {
      canvas.drawCircle(
        geom.center,
        geom.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = _kRed.withValues(alpha: 0.55 * rig.missFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  // ── Particles ───────────────────────────────────────────────────────────────

  void _paintParticle(
      Canvas canvas, _RigGeo geom, double angle, Color color) {
    const tailCount = 14;
    for (var i = tailCount; i >= 1; i--) {
      final t = i / tailCount;
      final trailAngle = angle - t * 0.45;
      final p = geom.pointAt(trailAngle);
      canvas.drawCircle(
        p,
        5 * (1 - t) + 0.8,
        Paint()..color = color.withValues(alpha: 0.28 * (1 - t) * (1 - t)),
      );
    }
    final pos = geom.pointAt(angle);
    canvas.drawCircle(
        pos,
        15,
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(pos, 6.5, Paint()..color = color);
    canvas.drawCircle(
        pos, 2.8, Paint()..color = Colors.white.withValues(alpha: 0.90));
  }

  // ── Gauge ───────────────────────────────────────────────────────────────────

  void _paintGauge(Canvas canvas, _RigGeo geom, _Rig rig) {
    final rect = geom.gauge;
    final left = rect.left;
    final top = rect.top;
    final gaugeW = rect.width;
    final gaugeH = rect.height;
    if (gaugeH <= 4) return;

    // Background track.
    final trackRR = RRect.fromRectAndRadius(rect, const Radius.circular(11));
    canvas.drawRRect(trackRR, Paint()..color = const Color(0xFF14141F));
    canvas.drawRRect(
      trackRR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = rig.accent.withValues(alpha: 0.30),
    );

    // Target band — highlighted in the rig's identity colour.
    final bandTopY = top + gaugeH * (1.0 - rig.bandMax);
    final bandBotY = top + gaugeH * (1.0 - rig.bandMin);
    final bandRect =
        Rect.fromLTRB(left + 2, bandTopY, left + gaugeW - 2, bandBotY);
    canvas.drawRect(
      bandRect,
      Paint()..color = rig.accent.withValues(alpha: 0.16),
    );
    canvas.drawRect(
      bandRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kGreen.withValues(alpha: 0.70),
    );

    // Energy fill — rig colour below band, green in band, red above.
    final fillH = gaugeH * rig.energy;
    final fillTop = top + gaugeH - fillH;
    final fillColor = rig.energy > rig.bandMax
        ? _kRed
        : (rig.energy >= rig.bandMin ? _kGreen : rig.accent);

    if (fillH > 2) {
      final fillRR = RRect.fromRectAndCorners(
        Rect.fromLTWH(left + 4, fillTop, gaugeW - 8, fillH),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      );
      canvas.drawRRect(
          fillRR, Paint()..color = fillColor.withValues(alpha: 0.85));
    }

    // Indicator line at current energy level.
    final indY = top + gaugeH * (1.0 - rig.energy);
    canvas.drawLine(
      Offset(left - 2, indY),
      Offset(left + gaugeW + 2, indY),
      Paint()
        ..color = fillColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Dwell arc ───────────────────────────────────────────────────────────────

  void _paintDwellArc(Canvas canvas, _RigGeo geom, _Rig rig) {
    final dwellFrac = (rig.dwellAcc / _kLevelUpDwell).clamp(0.0, 1.0);
    if (dwellFrac <= 0.01) return;
    final innerR = geom.radius * 0.62;
    final rect = Rect.fromCircle(center: geom.center, radius: innerR);
    final sweep = math.pi * 2 * dwellFrac;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = _kGreen.withValues(alpha: 0.60 + 0.35 * dwellFrac)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final tipAngle = -math.pi / 2 + sweep;
    final tipPos =
        geom.center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * innerR;
    canvas.drawCircle(
        tipPos,
        4.5,
        Paint()
          ..color = _kGreen.withValues(alpha: 0.90)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // ── Ring flash (localised per rig) ──────────────────────────────────────────

  void _paintRigFlash(Canvas canvas, _RigGeo geom, _Rig rig) {
    if (rig.ringFlash <= 0.02) return;
    final a = rig.ringFlash;
    final rad = geom.radius * 1.6;
    canvas.drawCircle(
      geom.center,
      rad,
      Paint()
        ..shader = RadialGradient(colors: [
          _kGreen.withValues(alpha: 0.35 * a),
          _kGreen.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: geom.center, radius: rad)),
    );
  }

  // ── Sparks (absolute) ───────────────────────────────────────────────────────

  void _paintSparks(Canvas canvas) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final pos = s.pos + s.vel * s.age;
      final dir =
          s.vel.distance > 1 ? s.vel / s.vel.distance : const Offset(1, 0);
      final paint = Paint()..color = s.color.withValues(alpha: t);
      canvas.drawLine(pos - dir * (5 * t), pos, paint..strokeWidth = 1.5);
      canvas.drawCircle(pos, s.radius * t, paint);
    }
  }

  // ── Popups ──────────────────────────────────────────────────────────────────

  void _paintPopups(Canvas canvas) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 44.0 * t;

      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: p.big ? 22 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: alpha * 0.8),
                  blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        p.origin - Offset(tp.width / 2, tp.height / 2 + rise),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AcceleratorPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// The interactive PUMP button — a widget (not painted on canvas) with press
// feedback, colour-matched to the beam it drives. One tap = one pump.

class _PumpButton extends StatefulWidget {
  final Color color;
  final Color colorDeep;
  final String label;
  final VoidCallback onPump;

  const _PumpButton({
    Key? key,
    required this.color,
    required this.colorDeep,
    required this.label,
    required this.onPump,
  }) : super(key: key);

  @override
  State<_PumpButton> createState() => _PumpButtonState();
}

class _PumpButtonState extends State<_PumpButton> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bright = _down ? 0.25 : 0.0;
    final top = Color.lerp(widget.color, _kWhite, bright)!;
    final bottom = Color.lerp(widget.colorDeep, _kWhite, bright)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _setDown(true);
        widget.onPump();
      },
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kWhite.withValues(alpha: _down ? 0.85 : 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _down ? 0.65 : 0.40),
                blurRadius: _down ? 24 : 16,
                spreadRadius: _down ? 1 : 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: _kWhite.withValues(alpha: 0.98),
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards. Each card is drawn with the REAL rig
// renderer (_AcceleratorPainter's own component methods on real _Rig state) so
// the manual shows the literal ring, beam, gauge and PUMP button the player
// will meet. Static, cheap, degenerate-size guarded.
// ═════════════════════════════════════════════════════════════════════════════

bool _legendBadSize(Size size) =>
    !size.width.isFinite ||
    !size.height.isFinite ||
    size.width <= 0 ||
    size.height <= 0;

/// A painter instance whose component methods we borrow for the static cards.
_AcceleratorPainter _legendArt({List<_Popup> popups = const []}) =>
    _AcceleratorPainter(
      rigs: const [],
      split: 0,
      idlePhase: 0.7,
      sparks: const [],
      popups: popups,
    );

/// Static canvas version of the interactive [_PumpButton] widget — same
/// gradient, border, glow and label styling, so the card matches play.
void _legendPumpButton(
  Canvas canvas,
  Rect r,
  Color color,
  Color colorDeep,
  String label, {
  double fontSize = 15,
}) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));

  // Glow.
  canvas.drawRRect(
    rr.inflate(2),
    Paint()
      ..color = color.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );
  // Body gradient.
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, colorDeep],
      ).createShader(r),
  );
  // Border.
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kWhite.withValues(alpha: 0.45),
  );
  // Label.
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: _kWhite.withValues(alpha: 0.98),
        shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
}

void _legendLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color, {
  double fontSize = 11,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: color.withValues(alpha: 0.95),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

// ── Frame 1: the rig + the verb — tap PUMP to feed the beam ──────────────────

void _legendPump(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final art = _legendArt();
  final rig = _Rig(accent: _kCyan, accentDeep: _kCyanDeep, angle1: -math.pi / 3)
    ..energy = 0.40;
  final radius = math.max(12.0, math.min(size.width, size.height) * 0.24);
  final geo =
      _RigGeo(Offset(size.width / 2, size.height * 0.38), radius, Rect.zero);

  art._paintRigBackdrop(canvas, geo, rig);
  art._paintRing(canvas, geo, rig);
  art._paintParticle(canvas, geo, rig.angle1, rig.accent);
  art._paintParticle(
      canvas, geo, rig.angle2 + 0.8, Color.lerp(rig.accent, _kWhite, 0.35)!);

  _legendPumpButton(
    canvas,
    Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.86),
      width: math.min(size.width * 0.55, 200.0),
      height: math.min(44.0, size.height * 0.16),
    ),
    _kCyan,
    _kCyanDeep,
    'PUMP',
  );
}

// ── Frame 2: scoring — hold the needle in the green band, charge a level ─────

void _legendBand(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final popup = _Popup(
    'LV2  +38',
    Offset(size.width * 0.64, size.height * 0.13),
    _kGreen,
    big: true,
  );
  final art = _legendArt(popups: [popup]);
  final rig = _Rig(accent: _kCyan, accentDeep: _kCyanDeep, angle1: math.pi / 5)
    ..energy = _kBandCentre // dead-centre of the target band → green
    ..dwellAcc = _kLevelUpDwell * 0.65; // charge arc two-thirds full

  final gauge = Rect.fromLTWH(
      size.width * 0.16 - 13, size.height * 0.10, 26, size.height * 0.78);
  final radius = math.max(12.0, math.min(size.width, size.height) * 0.21);
  final geo =
      _RigGeo(Offset(size.width * 0.64, size.height * 0.52), radius, gauge);

  art._paintRing(canvas, geo, rig); // reads green: in-band
  art._paintDwellArc(canvas, geo, rig); // the charge arc
  art._paintParticle(canvas, geo, rig.angle1, rig.accent);
  art._paintGauge(canvas, geo, rig); // band + green fill + needle
  art._paintPopups(canvas); // the level-up reward
}

// ── Frame 3: the danger — constant drain low, red overshoot high ─────────────

void _legendDrain(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final art = _legendArt();

  // Left gauge: stalled — energy drained out below the band.
  final low = _Rig(accent: _kCyan, accentDeep: _kCyanDeep)..energy = 0.16;
  // Right gauge: overshot — pumped past the band into the red.
  final hot = _Rig(accent: _kCyan, accentDeep: _kCyanDeep)..energy = 0.94;

  final gh = size.height * 0.64;
  final lowGauge =
      Rect.fromLTWH(size.width * 0.30 - 13, size.height * 0.08, 26, gh);
  final hotGauge =
      Rect.fromLTWH(size.width * 0.70 - 13, size.height * 0.08, 26, gh);
  art._paintGauge(canvas, _RigGeo(Offset.zero, 1, lowGauge), low);
  art._paintGauge(canvas, _RigGeo(Offset.zero, 1, hotGauge), hot);

  // Drain chevrons beside the stalled gauge — energy always falls.
  final chev = Paint()
    ..color = _kCyan.withValues(alpha: 0.85)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final cx = lowGauge.right + 16;
  for (var i = 0; i < 2; i++) {
    final cy = lowGauge.top + gh * (0.38 + i * 0.16);
    canvas.drawLine(Offset(cx - 7, cy - 5), Offset(cx, cy + 4), chev);
    canvas.drawLine(Offset(cx + 7, cy - 5), Offset(cx, cy + 4), chev);
  }

  // Red warning glow at the overshot gauge's top.
  canvas.drawCircle(
    Offset(hotGauge.center.dx, hotGauge.top + 8),
    16,
    Paint()
      ..color = _kRed.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );

  _legendLabel(canvas, 'TOO LOW', Offset(lowGauge.center.dx, lowGauge.bottom + 16),
      _kCyan);
  _legendLabel(canvas, 'TOO HIGH', Offset(hotGauge.center.dx, hotGauge.bottom + 16),
      _kRed);
}

// ── Frame 4: the twist — halftime brings a second, colour-matched beam ───────

void _legendTwoBeams(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final art = _legendArt();
  final cyanRig =
      _Rig(accent: _kCyan, accentDeep: _kCyanDeep, angle1: -math.pi / 2.4)
        ..energy = _kBandCentre;
  final orangeRig =
      _Rig(accent: _kOrange, accentDeep: _kOrangeDeep, angle1: math.pi * 0.7)
        ..energy = 0.40;

  final r = math.max(10.0, math.min(size.width * 0.15, size.height * 0.17));
  final cGeo = _RigGeo(Offset(size.width * 0.28, size.height * 0.36), r, Rect.zero);
  final oGeo = _RigGeo(Offset(size.width * 0.72, size.height * 0.36), r, Rect.zero);

  for (final pair in [(cGeo, cyanRig), (oGeo, orangeRig)]) {
    art._paintRigBackdrop(canvas, pair.$1, pair.$2);
    art._paintRing(canvas, pair.$1, pair.$2);
    art._paintParticle(canvas, pair.$1, pair.$2.angle1, pair.$2.accent);
  }

  final btnW = size.width * 0.34;
  final btnH = math.min(38.0, size.height * 0.16);
  final btnY = size.height * 0.82;
  _legendPumpButton(
    canvas,
    Rect.fromCenter(
        center: Offset(size.width * 0.28, btnY), width: btnW, height: btnH),
    _kCyan,
    _kCyanDeep,
    'PUMP  TOP',
    fontSize: 11,
  );
  _legendPumpButton(
    canvas,
    Rect.fromCenter(
        center: Offset(size.width * 0.72, btnY), width: btnW, height: btnH),
    _kOrange,
    _kOrangeDeep,
    'PUMP  BOT',
    fontSize: 11,
  );
}

/// The visual manual for Accelerator — wired into the registry spec.
final List<LegendFrame> acceleratorLegendFrames = [
  const LegendFrame(
      caption: 'Tap PUMP to feed energy into the beam', paint: _legendPump),
  const LegendFrame(
      caption: 'Hold energy in the green band to charge a level-up',
      paint: _legendBand),
  const LegendFrame(
      caption: 'Beam drains fast — don\'t stall low or overshoot red',
      paint: _legendDrain),
  const LegendFrame(
      caption: 'Halftime: 2nd beam online — match button colour to beam',
      paint: _legendTwoBeams),
];
