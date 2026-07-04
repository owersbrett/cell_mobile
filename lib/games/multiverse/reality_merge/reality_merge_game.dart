// RealityMergeGame — "Reality Merge" align-two-universes lock game.
//
// A dim GREY TARGET ring sits on screen at some size / position / rotation /
// hue. Your BRIGHT ring must be aligned to it. Exactly ONE property is "live"
// at a time and OSCILLATES as a fair triangle wave; every other property is
// auto-matched to the target so the ring always reads as "one thing is off and
// moving." TAP ANYWHERE to LOCK the live property at its current value, scored
// by accuracy (PERFECT / GREAT / OK — a way-off tap still locks and advances,
// no punishment). Properties lock in a fixed order:
//   SIZE → X → Y → ROTATION → HUE
// When every ACTIVE property is locked → MERGE: burst + bonus + "+score" pop,
// then the next attempt begins. The number of properties per merge grows by +1
// every 3 merges (cap 5); once at 5 dims, the oscillation SPEEDS UP endlessly.
//
// Self-contained module. Depends only on the framework session + shared FX.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tweak here without touching logic
// ---------------------------------------------------------------------------

/// Accent used for atmosphere + your bright ring's default chroma.
const Color _rmAccent = Color(0xFF8A7BFF); // multiverse violet

/// The dim ghost color of the target ring.
const Color _rmGhost = Color(0xFF6C6A78);

/// Full sweep (one triangle-wave period, value 0→1→0) duration at base speed.
const double _rmSweepBase = 2.0;

/// Sweep period shrinks by this factor per "overspeed" step once at 5 dims.
/// Each completed merge past the cap multiplies the period by this (faster).
const double _rmOverspeedFactor = 0.92;

/// Floor on the sweep period so it never becomes impossible.
const double _rmSweepFloor = 0.75;

/// Merges between each +1 to the active-dimension count.
const int _rmMergesPerStep = 3;

/// Maximum number of lockable dimensions.
const int _rmMaxDims = 5;

/// Accuracy tiers (normalized error 0..1, smaller = better) and their points.
/// A lock with error above the OK band still locks (advances) for ~0 points.
const double _rmPerfectErr = 0.045;
const double _rmGreatErr = 0.11;
const double _rmOkErr = 0.22;
const int _rmPerfectPts = 100;
const int _rmGreatPts = 55;
const int _rmOkPts = 22;

/// Bonus awarded when a full attempt MERGES, scaled by active dim count.
const int _rmMergeBonusPer = 60;

/// Guard window (s): ignore a second tap landing within this of a lock, so one
/// physical tap can't double-fire across two live properties.
const double _rmTapGuard = 0.12;

// Play-field insets (px) — keep rings clear of the host HUD/timer + bottom.
const double _rmTopInset = 92.0;
const double _rmBottomInset = 64.0;
const double _rmSideInset = 30.0;

// ---------------------------------------------------------------------------
// Property model
// ---------------------------------------------------------------------------

/// The five lockable properties, in fixed lock order.
enum _Prop { size, x, y, rotation, hue }

/// The active-dim count → which props are in play (always a prefix of this).
const List<_Prop> _rmOrder = [
  _Prop.size,
  _Prop.x,
  _Prop.y,
  _Prop.rotation,
  _Prop.hue,
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class RealityMergeGame extends StatefulWidget {
  final MiniGameSession session;
  const RealityMergeGame({super.key, required this.session});

  @override
  State<RealityMergeGame> createState() => _RealityMergeGameState();
}

class _RealityMergeGameState extends State<RealityMergeGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Random _rng = Random();

  double _clock = 0; // animation clock (atmosphere / pulses)
  double _lastWall = 0;

  Size _size = Size.zero;

  // Progression.
  int _merges = 0; // completed merges this run
  int _activeDims = 1; // how many props must be locked this attempt (1..5)

  // ── Target values (all normalized 0..1; mapped to pixels in painter) ──
  // size: 0..1 fraction of the size range. x/y: 0..1 across the field.
  // rotation: 0..1 of a full turn. hue: 0..1 around the wheel.
  late Map<_Prop, double> _target;

  // ── Your ring's locked/live values (normalized 0..1) ──
  // For props not yet reached this attempt, the value is auto-matched to the
  // target so only the live one reads as "off."
  late Map<_Prop, double> _mine;

  // Which prop is currently live (index into the active prefix), or -1 if the
  // attempt is fully locked (mid-merge celebration).
  int _liveIdx = 0;

  // Triangle-wave sweep phase 0..1 for the live property's oscillation.
  double _sweepT = 0;
  // Direction the live value is offset by the sweep: a fresh target/offset.
  // Sweep maps to value via a per-prop window so it always crosses the target.
  late double _sweepLo;
  late double _sweepHi;

  // Merge celebration state.
  bool _merging = false;
  double _mergeT = 0; // 0..1 celebration progress
  Offset _mergeCenter = Offset.zero;

  // Lock feedback flashes.
  double _flash = 0;
  Color _flashColor = Colors.white;
  double _lockPulse = 0; // brief ring-snap pulse on a lock
  String _lastTier = '';
  double _tierShow = 0;

  // Streak of consecutive PERFECT/GREAT locks.
  int _streak = 0;

  // Tap-guard timer.
  double _sinceLock = 999;

  // Juice.
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = []; // pixel-space anchors

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastWall = _now();
    _newAttempt(first: true);

    // ATTRACT autopilot: this game knows how to time its own locks. The host
    // calls it on the autopilot cadence (~250ms) while running; it is a no-op
    // during hands-on play. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free lock per host tick (~250ms). This is a TIMING
  /// game: the live property sweeps as a triangle wave and can pass clean
  /// through the target between two ticks, so "lock if aligned now" would miss
  /// its closest approach most of the time. Instead we read the live value and
  /// its sweep, then look exactly one tick ahead:
  ///
  ///   • Only ever lock when locking NOW already scores — i.e. the current
  ///     error (via the game's own [_propError]) is inside the scoring band
  ///     ([_rmOkErr]). Locking while the value is far off is a 0-point OFF lock,
  ///     so we never do it.
  ///   • Among the ticks inside that band, lock on the LOCAL MINIMUM of error:
  ///     only when NOW is at least as close to the target as the NEXT tick will
  ///     be (`errNow <= errNext`). If a tighter tick is still ahead we wait for
  ///     it — this prefers PERFECT/GREAT and guarantees a positive score.
  ///
  /// Reuses the game's own lock handler ([_onTap]) so there is exactly one place
  /// that freezes the value and scores it. Deterministic; no synthetic taps.
  void _autoStep() {
    if (!widget.session.isRunning || _size == Size.zero) return;
    // Nothing live to lock: mid-merge celebration or fully-locked attempt.
    if (_merging || _liveIdx < 0 || _liveIdx >= _activeDims) return;
    // Respect the tap guard so we don't waste a tick on a no-op lock.
    if (_sinceLock < _rmTapGuard) return;

    final prop = _rmOrder[_liveIdx];
    final tgt = _target[prop]!;

    // The host drives this on ~250ms cadence; look exactly one window ahead.
    const window = 0.25;
    final valueNow = _liveValue();
    final errNow = _propError(prop, valueNow, tgt);
    if (errNow > _rmOkErr) return; // off-target → a lock would score nothing.

    // Predict the value one tick from now by advancing the sweep phase, then
    // measure its error with the same property-aware metric the lock uses.
    final nextT = _sweepT + window / _sweepPeriod();
    final valueNext = _sweepLo + (_sweepHi - _sweepLo) * _tri(nextT);
    final errNext = _propError(prop, valueNext, tgt);

    // A tighter tick is still ahead → wait for it rather than settle now.
    if (errNow > errNext) return;

    _onTap();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── attempt setup ────────────────────────────────────────────────────────

  void _newAttempt({bool first = false}) {
    // Active dims grow +1 every _rmMergesPerStep merges, capped at _rmMaxDims.
    _activeDims = (1 + _merges ~/ _rmMergesPerStep).clamp(1, _rmMaxDims);

    // Random target. Keep size/x/y away from the extremes so the ring always
    // fits and reads clearly.
    _target = {
      _Prop.size: 0.30 + _rng.nextDouble() * 0.55,
      _Prop.x: 0.22 + _rng.nextDouble() * 0.56,
      _Prop.y: 0.22 + _rng.nextDouble() * 0.56,
      _Prop.rotation: _rng.nextDouble(),
      _Prop.hue: _rng.nextDouble(),
    };

    // Start every prop matched to the target; the live one then sweeps.
    _mine = Map<_Prop, double>.from(_target);

    _liveIdx = 0;
    _merging = false;
    _mergeT = 0;
    _sinceLock = 999;
    _beginSweep();
  }

  /// (Re)build the oscillation window for the current live property. The window
  /// is centered so the triangle wave crosses the target twice per sweep
  /// (giving two fair alignment windows), while staying within [0,1].
  void _beginSweep() {
    final prop = _rmOrder[_liveIdx];
    final tgt = _target[prop]!;
    // Half-width of the swing. Big enough to be clearly "off" at the extremes.
    const half = 0.42;
    _sweepLo = (tgt - half).clamp(0.0, 1.0);
    _sweepHi = (tgt + half).clamp(0.0, 1.0);
    // Guarantee a non-degenerate window even if the target sat near an edge.
    if (_sweepHi - _sweepLo < 0.30) {
      _sweepLo = (tgt - 0.30).clamp(0.0, 1.0);
      _sweepHi = (_sweepLo + 0.60).clamp(0.0, 1.0);
      if (_sweepHi > 1.0) {
        _sweepHi = 1.0;
        _sweepLo = 0.40;
      }
    }
    // Start the phase at a random point so attempts don't feel mechanical.
    _sweepT = _rng.nextDouble();
  }

  /// Current sweep period (s) — base, then accelerates once past the cap.
  double _sweepPeriod() {
    final overCap =
        (_merges - (_rmMaxDims - 1) * _rmMergesPerStep).clamp(0, 1000);
    final scaled = _rmSweepBase * pow(_rmOverspeedFactor, overCap).toDouble();
    return scaled.clamp(_rmSweepFloor, _rmSweepBase);
  }

  /// Triangle wave 0→1→0 over phase [0,1).
  double _tri(double t) {
    final p = t % 1.0;
    return p < 0.5 ? p * 2.0 : 2.0 - p * 2.0;
  }

  /// The live property's current oscillating value (normalized 0..1).
  double _liveValue() {
    return _sweepLo + (_sweepHi - _sweepLo) * _tri(_sweepT);
  }

  // ── tick ───────────────────────────────────────────────────────────────

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    if (!widget.session.isRunning || _size == Size.zero) return;

    setState(() {
      _clock += dt;
      _sinceLock += dt;
      if (_flash > 0) _flash = (_flash - dt * 3).clamp(0.0, 1.0);
      if (_lockPulse > 0) _lockPulse = (_lockPulse - dt * 4).clamp(0.0, 1.0);
      if (_tierShow > 0) _tierShow = (_tierShow - dt * 1.4).clamp(0.0, 1.0);

      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (_merging) {
        _mergeT = (_mergeT + dt / 0.85).clamp(0.0, 1.0);
        if (_mergeT >= 1.0) _newAttempt();
        return;
      }

      // Advance the live property's sweep.
      _sweepT += dt / _sweepPeriod();
      // Keep the live value synced into _mine so the painter + lock read it.
      _mine[_rmOrder[_liveIdx]] = _liveValue();
    });
  }

  // ── lock ─────────────────────────────────────────────────────────────────

  void _onTap() {
    if (!widget.session.isRunning || _size == Size.zero) return;
    if (_merging) return;
    // Guard against a double-fire from one physical tap.
    if (_sinceLock < _rmTapGuard) return;
    _sinceLock = 0;

    setState(() {
      final prop = _rmOrder[_liveIdx];
      final locked = _liveValue();
      _mine[prop] = locked; // freeze it at the tapped instant

      // Score by accuracy. Error metric is property-aware: rotation/hue wrap.
      final err = _propError(prop, locked, _target[prop]!);
      int pts;
      String tier;
      if (err <= _rmPerfectErr) {
        pts = _rmPerfectPts;
        tier = 'PERFECT';
      } else if (err <= _rmGreatErr) {
        pts = _rmGreatPts;
        tier = 'GREAT';
      } else if (err <= _rmOkErr) {
        pts = _rmOkPts;
        tier = 'OK';
      } else {
        pts = 0;
        tier = 'OFF';
      }

      if (pts > 0) {
        widget.session.addScore(pts);
        final pos = _ringCenter();
        _pops.add(FxPop(pos.translate(0, -_ringRadius() - 14), '+$pts',
            tier == 'PERFECT' ? _rmGhostBright() : Colors.white));
      }

      // Streak counts consecutive PERFECT/GREAT locks.
      if (tier == 'PERFECT' || tier == 'GREAT') {
        _streak++;
        widget.session.noteStreak(_streak);
      } else {
        _streak = 0;
      }

      // Lock feedback.
      _lastTier = tier;
      _tierShow = 1.0;
      _lockPulse = 1.0;
      final fc = _tierColor(tier);
      _flash = 0.55;
      _flashColor = fc;
      final c = _ringCenter();
      _particles.addAll(FxBurst.spawn(c, fc, count: 14, speed: 130));

      // Advance to the next live property, or MERGE.
      _liveIdx++;
      if (_liveIdx >= _activeDims) {
        _beginMerge();
      } else {
        _beginSweep();
      }
    });
  }

  void _beginMerge() {
    _merging = true;
    _mergeT = 0;
    _liveIdx = -1;
    _mergeCenter = _ringCenter();

    final bonus = _rmMergeBonusPer * _activeDims;
    widget.session.addScore(bonus);
    _merges++;

    // Big satisfying burst + "+bonus" pop.
    _flash = 0.85;
    _flashColor = _rmGhostBright();
    _particles.addAll(FxBurst.spawn(_mergeCenter, _rmGhostBright(),
        count: 30, speed: 200));
    _particles
        .addAll(FxBurst.spawn(_mergeCenter, _rmAccent, count: 18, speed: 120));
    _pops.add(FxPop(_mergeCenter, 'MERGE +$bonus', _rmGhostBright()));
  }

  // ── property math ──────────────────────────────────────────────────────

  /// Normalized error 0..1 between two values for a property. Rotation and hue
  /// wrap around (a notch at 0.99 is close to 0.01).
  double _propError(_Prop p, double a, double b) {
    if (p == _Prop.rotation || p == _Prop.hue) {
      var d = (a - b).abs() % 1.0;
      if (d > 0.5) d = 1.0 - d;
      return (d * 2.0).clamp(0.0, 1.0); // 0.5 wrap-dist → full error
    }
    return (a - b).abs().clamp(0.0, 1.0);
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'PERFECT':
        return const Color(0xFF69F0AE); // mint
      case 'GREAT':
        return const Color(0xFF40C4FF); // cyan
      case 'OK':
        return const Color(0xFFFFD54F); // amber
      default:
        return const Color(0xFFFF8A80); // soft red (no punishment, just info)
    }
  }

  /// A bright readable variant of the multiverse accent for celebration.
  Color _rmGhostBright() => const Color(0xFFB9AEFF);

  // ── field / geometry mapping ─────────────────────────────────────────────

  Rect _field() {
    // Guard against tiny viewports: never let the field invert.
    final right = max(_rmSideInset + 40.0, _size.width - _rmSideInset);
    final bottom = max(_rmTopInset + 40.0, _size.height - _rmBottomInset);
    return Rect.fromLTRB(_rmSideInset, _rmTopInset, right, bottom);
  }

  /// Max ring radius given the field (so the biggest size still fits).
  double _maxRadius() {
    final f = _field();
    final r = (f.shortestSide * 0.42);
    return r.isFinite && r > 4 ? r : 4.0;
  }

  double _minRadius() => _maxRadius() * 0.22;

  double _radiusFor(double sizeNorm) {
    final lo = _minRadius();
    final hi = _maxRadius();
    return lo + (hi - lo) * sizeNorm.clamp(0.0, 1.0);
  }

  Offset _centerFor(double xNorm, double yNorm) {
    final f = _field();
    // Inset center range by max radius so a big ring never clips the field.
    final m = _maxRadius();
    // Guard: if the field is too small to inset by m, fall back to the field
    // center range without inset (clamp lo<=hi to avoid a throwing clamp).
    double lerp(double lo, double hi, double t) => lo + (hi - lo) * t;
    final xl = f.left + m;
    final xr = f.right - m;
    final yl = f.top + m;
    final yr = f.bottom - m;
    final cx = xr > xl ? lerp(xl, xr, xNorm) : f.center.dx;
    final cy = yr > yl ? lerp(yl, yr, yNorm) : f.center.dy;
    return Offset(cx, cy);
  }

  Offset _ringCenter() => _centerFor(_mine[_Prop.x]!, _mine[_Prop.y]!);
  double _ringRadius() => _radiusFor(_mine[_Prop.size]!);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _onTap(),
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RMPainter(
                clock: _clock,
                target: _target,
                mine: _mine,
                liveIdx: _liveIdx,
                activeDims: _activeDims,
                centerFor: _centerFor,
                radiusFor: _radiusFor,
                merging: _merging,
                mergeT: _mergeT,
                mergeCenter: _mergeCenter,
                lockPulse: _lockPulse,
                flash: _flash,
                flashColor: _flashColor,
                particles: _particles,
                pops: _pops,
              ),
            ),
          ),
          // Slim game-specific HUD — names the live property + escalation.
          // (Host owns score + timer.)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ALIGN: ${_liveLabel()}',
                    style: Potatuhs.label(size: 12, color: _rmAccent)),
                const SizedBox(height: 2),
                Text('$_activeDims dim${_activeDims == 1 ? '' : 's'} · $_merges merged',
                    style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
              const Spacer(),
              if (_tierShow > 0 && _lastTier.isNotEmpty)
                _tierChip(_lastTier, _tierShow),
            ]),
          ),
          // Hint, lower-center.
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  _merging ? 'REALITIES MERGED' : 'TAP to lock the moving ring',
                  style: Potatuhs.body(
                      size: 12,
                      color: (_merging ? _rmGhostBright() : Colors.white)
                          .withValues(alpha: _merging ? 0.9 : 0.32)),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  String _liveLabel() {
    if (_merging || _liveIdx < 0 || _liveIdx >= _activeDims) return '—';
    switch (_rmOrder[_liveIdx]) {
      case _Prop.size:
        return 'SIZE';
      case _Prop.x:
        return 'HORIZONTAL';
      case _Prop.y:
        return 'VERTICAL';
      case _Prop.rotation:
        return 'ROTATION';
      case _Prop.hue:
        return 'HUE';
    }
  }

  Widget _tierChip(String label, double show) {
    final c = _tierColor(label);
    return Opacity(
      opacity: show.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.55)),
        ),
        child: Text(label,
            style: Potatuhs.label(size: 11, color: Colors.white.withValues(alpha: 0.92))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — two rings + live-property motion + lock juice
// ---------------------------------------------------------------------------

class _RMPainter extends CustomPainter {
  final double clock;
  final Map<_Prop, double> target;
  final Map<_Prop, double> mine;
  final int liveIdx;
  final int activeDims;
  final Offset Function(double, double) centerFor;
  final double Function(double) radiusFor;
  final bool merging;
  final double mergeT;
  final Offset mergeCenter;
  final double lockPulse;
  final double flash;
  final Color flashColor;
  final List<FxParticle> particles;
  final List<FxPop> pops;

  _RMPainter({
    required this.clock,
    required this.target,
    required this.mine,
    required this.liveIdx,
    required this.activeDims,
    required this.centerFor,
    required this.radiusFor,
    required this.merging,
    required this.mergeT,
    required this.mergeCenter,
    required this.lockPulse,
    required this.flash,
    required this.flashColor,
    required this.particles,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _rmAccent, clock, motes: 40);

    // ── Target (ghost) ring ────────────────────────────────────────────────
    final tCenter = centerFor(target[_Prop.x]!, target[_Prop.y]!);
    final tRadius = radiusFor(target[_Prop.size]!);
    final tHue = _RMArt.hueColor(target[_Prop.hue]!, sat: 0.35, val: 0.72);
    if (_okRect(tCenter, tRadius)) {
      _RMArt.ghostRing(canvas, tCenter, tRadius, target[_Prop.rotation]!, tHue);
    }

    // ── Your (bright) ring ─────────────────────────────────────────────────
    final mCenter = centerFor(mine[_Prop.x]!, mine[_Prop.y]!);
    final mRadius = radiusFor(mine[_Prop.size]!);
    final mHueNorm = activeDims > _rmOrder.indexOf(_Prop.hue)
        ? mine[_Prop.hue]!
        : target[_Prop.hue]!;
    final mColor = _RMArt.hueColor(mHueNorm, sat: 0.72, val: 1.0);
    if (_okRect(mCenter, mRadius)) {
      _RMArt.liveRing(canvas, mCenter, mRadius, mine[_Prop.rotation]!, mColor,
          lockPulse: lockPulse);
    }

    // ── Merge celebration: collapsing bright rings into one ────────────────
    if (merging && _okRect(mergeCenter, 10)) {
      final base = radiusFor(target[_Prop.size]!);
      for (int k = 0; k < 3; k++) {
        final t = (mergeT - k * 0.12).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final rr = base * (1.0 + t * 2.4);
        final a = (1.0 - t) * 0.5;
        if (a <= 0) continue;
        canvas.drawCircle(
          mergeCenter,
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 * (1 - t) + 0.5
            ..color = const Color(0xFFB9AEFF).withValues(alpha: a),
        );
      }
    }

    // ── Particles + pops ───────────────────────────────────────────────────
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }

    // ── Lock flash overlay ─────────────────────────────────────────────────
    if (flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = flashColor.withValues(alpha: (flash * 0.12).clamp(0.0, 0.2)));
    }
  }

  /// Reject non-finite or degenerate geometry before drawing.
  bool _okRect(Offset c, double r) =>
      c.dx.isFinite && c.dy.isFinite && r.isFinite && r > 1.0;

  @override
  bool shouldRepaint(covariant _RMPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// _RMArt — the ring component draws, shared by the live painter and the visual
// manual so the manual shows the EXACT ghost/bright rings the player will meet.
// ═══════════════════════════════════════════════════════════════════════════

class _RMArt {
  _RMArt._();

  /// Map a hue-norm (0..1) to a readable saturated color.
  static Color hueColor(double hueNorm, {double sat = 0.62, double val = 1.0}) {
    final h = (hueNorm % 1.0) * 360.0;
    return HSVColor.fromAHSV(1.0, h.isFinite ? h : 0.0, sat, val).toColor();
  }

  static void ghostRing(
      Canvas canvas, Offset c, double r, double rotNorm, Color hue) {
    // Faint filled disc so the target reads as a "dim other reality."
    canvas.drawCircle(
      c,
      r,
      Paint()..color = _rmGhost.withValues(alpha: 0.05),
    );
    // Dashed ghost outline.
    dashedRing(canvas, c, r, _rmGhost.withValues(alpha: 0.45), 1.6);
    // Subtle hue hint on the ring so a hue mismatch is legible.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = hue.withValues(alpha: 0.18),
    );
    // Target notch (rotation marker) — a ghosted tick at the rotation angle.
    notch(canvas, c, r, rotNorm, _rmGhost.withValues(alpha: 0.6), 2.2);
    // Center crosshair so position alignment is readable.
    final cp = Paint()
      ..color = _rmGhost.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), cp);
    canvas.drawLine(c.translate(0, -6), c.translate(0, 6), cp);
  }

  static void liveRing(
      Canvas canvas, Offset c, double r, double rotNorm, Color color,
      {double lockPulse = 0}) {
    // Lock-snap pulse expands a faint echo.
    if (lockPulse > 0) {
      canvas.drawCircle(
        c,
        r * (1.0 + (1 - lockPulse) * 0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * lockPulse + 0.5
          ..color = Colors.white.withValues(alpha: lockPulse * 0.5),
      );
    }

    // Glow halo.
    canvas.drawCircle(
      c,
      r + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Bright body ring.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = color.withValues(alpha: 0.95),
    );
    // Inner thin ring for richness.
    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    // Rotation notch — a bright marker bump the player aligns to the target's.
    notch(canvas, c, r, rotNorm, Colors.white.withValues(alpha: 0.95), 3.2,
        bulb: true, bulbColor: color);
    // Center dot.
    canvas.drawCircle(c, 3.0, Paint()..color = color.withValues(alpha: 0.9));
  }

  /// A radial tick (and optional bulb) at angle [rotNorm] (0..1 of a turn).
  static void notch(Canvas canvas, Offset c, double r, double rotNorm,
      Color color, double width,
      {bool bulb = false, Color? bulbColor}) {
    final ang = (rotNorm % 1.0) * 2 * pi - pi / 2; // 0 = top
    final dir = Offset(cos(ang), sin(ang));
    final inner = c + dir * (r - 8);
    final outer = c + dir * (r + 8);
    canvas.drawLine(
      inner,
      outer,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    if (bulb) {
      canvas.drawCircle(
        c + dir * (r + 9),
        4.5,
        Paint()..color = (bulbColor ?? color).withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        c + dir * (r + 9),
        7.0,
        Paint()
          ..color = (bulbColor ?? color).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  static void dashedRing(
      Canvas canvas, Offset c, double r, Color color, double w) {
    if (r <= 1) return;
    const segments = 48;
    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < segments; i += 2) {
      final a0 = i / segments * 2 * pi;
      final a1 = (i + 1) / segments * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same _RMArt the live painter uses).
// ═══════════════════════════════════════════════════════════════════════════

/// Hue-norm used for the manual's bright ring — lands on the multiverse violet.
const double _rmLegendHue = 0.72;

/// Outward double-chevrons on the diagonals: "this dimension is sweeping."
void _legendSweepChevrons(Canvas canvas, Offset c, double rInner, double rOuter) {
  final p = Paint()
    ..color = _rmAccent.withValues(alpha: 0.85)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (int k = 0; k < 4; k++) {
    final a = pi / 4 + k * pi / 2;
    final dir = Offset(cos(a), sin(a));
    final side = Offset(-dir.dy, dir.dx);
    final tip = c + dir * (rInner + (rOuter - rInner) * 0.62);
    canvas.drawLine(tip - dir * 7 + side * 5, tip, p);
    canvas.drawLine(tip - dir * 7 - side * 5, tip, p);
  }
}

/// One mini ghost+bright ring pair, mis-aligned per [dim] (index into _rmOrder).
void _legendMiniPair(Canvas canvas, Offset c, double r, int dim) {
  final ghostHue = _RMArt.hueColor(_rmLegendHue, sat: 0.35, val: 0.72);
  const rot = 0.0; // notch up unless rotation is the mismatch
  switch (dim) {
    case 0: // SIZE — same centre, smaller bright ring.
      _RMArt.ghostRing(canvas, c, r, rot, ghostHue);
      _RMArt.liveRing(canvas, c, r * 0.55, rot, _RMArt.hueColor(_rmLegendHue));
      break;
    case 1: // X — bright ring shifted sideways.
      _RMArt.ghostRing(canvas, c.translate(-r * 0.42, 0), r * 0.8, rot, ghostHue);
      _RMArt.liveRing(canvas, c.translate(r * 0.42, 0), r * 0.8, rot,
          _RMArt.hueColor(_rmLegendHue));
      break;
    case 2: // Y — bright ring shifted down.
      _RMArt.ghostRing(canvas, c.translate(0, -r * 0.42), r * 0.8, rot, ghostHue);
      _RMArt.liveRing(canvas, c.translate(0, r * 0.42), r * 0.8, rot,
          _RMArt.hueColor(_rmLegendHue));
      break;
    case 3: // ROTATION — same ring, notches at different angles.
      _RMArt.ghostRing(canvas, c, r, 0.0, ghostHue);
      _RMArt.liveRing(canvas, c, r, 0.35, _RMArt.hueColor(_rmLegendHue));
      break;
    default: // HUE — aligned geometry, clashing colors.
      _RMArt.ghostRing(canvas, c, r, rot, _RMArt.hueColor(0.35, sat: 0.5, val: 0.85));
      _RMArt.liveRing(canvas, c, r, rot, _RMArt.hueColor(_rmLegendHue));
  }
}

void _legendAlign(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.50);
  final big = size.shortestSide * 0.34;
  if (!big.isFinite || big <= 2) return;
  // The dim other-reality target, and your bright ring off in ONE dimension.
  _RMArt.ghostRing(
      canvas, c, big, 0.1, _RMArt.hueColor(_rmLegendHue, sat: 0.35, val: 0.72));
  _RMArt.liveRing(canvas, c, big * 0.55, 0.1, _RMArt.hueColor(_rmLegendHue));
  _legendSweepChevrons(canvas, c, big * 0.55, big);
  GameFx.text(canvas, 'TAP = LOCK', Offset(c.dx, size.height * 0.93), 11,
      Colors.white.withValues(alpha: 0.85),
      weight: FontWeight.w800);
}

void _legendMerge(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.52);
  final r = size.shortestSide * 0.26;
  if (!r.isFinite || r <= 2) return;
  const bright = Color(0xFFB9AEFF); // celebration violet (same as in-game)
  // Expanding merge echoes, exactly like the in-game celebration.
  for (int k = 0; k < 3; k++) {
    final t = 0.25 + k * 0.18;
    canvas.drawCircle(
      c,
      r * (1.0 + t * 1.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1 - t) + 0.5
        ..color = bright.withValues(alpha: (1.0 - t) * 0.5),
    );
  }
  // Rings fully aligned — one reality.
  _RMArt.ghostRing(
      canvas, c, r, 0.1, _RMArt.hueColor(_rmLegendHue, sat: 0.35, val: 0.72));
  _RMArt.liveRing(canvas, c, r, 0.1, _RMArt.hueColor(_rmLegendHue));
  GameFx.text(canvas, 'MERGE +60', Offset(c.dx, size.height * 0.10), 13, bright,
      weight: FontWeight.w800);
}

void _legendDimensions(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  const labels = ['SIZE', 'X', 'Y', 'ROT', 'HUE'];
  final cellW = size.width / 5;
  final r = min(cellW * 0.30, size.height * 0.18);
  if (!r.isFinite || r <= 1.5) return;
  final cy = size.height * 0.42;
  for (int i = 0; i < 5; i++) {
    final cx = cellW * (i + 0.5);
    _legendMiniPair(canvas, Offset(cx, cy), r, i);
    GameFx.text(canvas, labels[i], Offset(cx, size.height * 0.76), 10,
        _rmAccent.withValues(alpha: 0.95),
        weight: FontWeight.w800);
  }
  GameFx.text(canvas, '+1 DIMENSION EVERY 3 MERGES',
      Offset(size.width * 0.5, size.height * 0.92), 10,
      Colors.white.withValues(alpha: 0.75),
      weight: FontWeight.w800);
}

void _legendScoring(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  // Same tier colors the in-game chips use.
  const tiers = ['PERFECT', 'GREAT', 'OK'];
  const pts = ['+100', '+55', '+22'];
  const colors = [Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFFFD54F)];
  final offs = [0.0, 0.28, 0.62]; // lock error grows left → right
  final cellW = size.width / 3;
  final r = min(cellW * 0.30, size.height * 0.20);
  if (!r.isFinite || r <= 1.5) return;
  final cy = size.height * 0.42;
  final ghostHue = _RMArt.hueColor(_rmLegendHue, sat: 0.35, val: 0.72);
  for (int i = 0; i < 3; i++) {
    final c = Offset(cellW * (i + 0.5), cy);
    _RMArt.ghostRing(canvas, c, r, 0.0, ghostHue);
    _RMArt.liveRing(canvas, c.translate(r * offs[i], r * offs[i] * 0.4), r,
        0.0, _RMArt.hueColor(_rmLegendHue));
    GameFx.text(canvas, tiers[i], Offset(c.dx, size.height * 0.78), 10,
        colors[i],
        weight: FontWeight.w800);
    GameFx.text(canvas, pts[i], Offset(c.dx, size.height * 0.90), 10,
        Colors.white.withValues(alpha: 0.8),
        weight: FontWeight.w800);
  }
}

/// The visual manual for Reality Merge — wired into the registry spec.
final List<LegendFrame> realityMergeLegendFrames = [
  const LegendFrame(
      caption: 'Tap to lock your bright ring onto the ghost ring',
      paint: _legendAlign),
  const LegendFrame(
      caption: 'Lock every dimension to MERGE for a big bonus',
      paint: _legendMerge),
  const LegendFrame(
      caption: 'Every 3 merges adds a dimension: size→x→y→rot→hue',
      paint: _legendDimensions),
  const LegendFrame(
      caption: 'Tighter locks score more: PERFECT · GREAT · OK',
      paint: _legendScoring),
];
