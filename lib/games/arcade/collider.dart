import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../mini_game.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFFAB47BC);
const _kMagenta = Color(0xFFFF4FD8);
const _kCyan = Color(0xFF00E5FF);
const _kRed = Color(0xFFFF5252);

// ---------------------------------------------------------------------------
// Feel constants — tune these for play-balance. These are SHARED by every
// collider; each collider derives its own level-scaled values from them but
// the base feel is common.
// ---------------------------------------------------------------------------

/// Number of concentric rings. Ring 0 = innermost / slowest / lowest score.
const int _kRingCount = 5;

/// Smallest ring radius as a fraction of min(width, height).
const double _kInnerRadiusFraction = 0.18;

/// Outermost ring radius as a fraction of min(width, height).
const double _kOuterRadiusFraction = 0.42;

/// Base orbit speed (rad/s) on the innermost ring. Each ring above multiplies
/// this by _kSpeedPerLevel^level, so outer rings are noticeably faster.
const double _kBaseSpeed1 = 1.4; // rad/s, particle 1 clockwise
const double _kBaseSpeed2 = 1.75; // rad/s, particle 2 counter-clockwise

/// Multiplier applied per ring level to orbit speed (level 0 = ×1.0).
/// At ring 4 this gives speed × 1.38 — fast enough that outer rings require
/// genuine precision to maintain.
const double _kSpeedPerLevel = 1.08;

/// Angular separation thresholds for PERFECT / CLOSE.
const double _kPerfectSep = 10 * math.pi / 180; // < 10 degrees
const double _kCloseSep = 25 * math.pi / 180; // < 25 degrees

/// Base PERFECT score at ring 0. Each ring up adds _kScorePerLevel points.
const int _kBasePerfectScore = 15;

/// Extra points per ring level for a PERFECT hit.
const int _kScorePerLevel = 8;

/// Base CLOSE score at ring 0. Each ring up adds half _kScorePerLevel.
const int _kBaseCloseScore = 6;

/// Miss penalty (applied on every miss regardless of level).
const int _kMissPenalty = 5;

/// Slow-drift factor while the countdown overlay is covering the game.
const double _kIdleFactor = 0.22;

/// How long the single→double split animation takes (seconds).
const double _kSplitDuration = 0.9;

// --- Shake-to-boost --------------------------------------------------------
// Shaking the device speeds the particles up: a vigorous shake can roughly
// triple orbit speed (great for chaining hits, harder to time). The boost
// decays on its own once you stop shaking. Shake is whole-device, so it
// boosts BOTH colliders equally once the second one is online.

/// Gravity-removed accelerometer magnitude (m/s²) above which a shake registers.
const double _kShakeThreshold = 12.0;

/// How much each unit of shake (above threshold) adds to the boost per event.
const double _kShakeGain = 0.06;

/// Maximum extra speed multiplier from shaking (0 = none, 2.0 = ×3 total).
const double _kMaxShakeBoost = 2.0;

/// How fast the boost bleeds off once shaking stops (per second).
const double _kShakeDecay = 1.6;

// ---------------------------------------------------------------------------

/// "Collider" — two counter-orbiting particles on a concentric ring ladder.
/// Start on ring 0 (innermost / slowest). Land a collision → promote to next
/// ring (faster, higher score). Miss once → drop one ring. Miss twice in a row
/// → back to ring 0. At halftime a SECOND collider comes online: the screen
/// splits into a top and a bottom ladder and the player must juggle both,
/// tapping in the top half to fire the top collider and the bottom half for
/// the bottom. Each collider promotes/demotes independently.
class ColliderGame extends StatefulWidget {
  final MiniGameSession session;
  const ColliderGame({Key? key, required this.session}) : super(key: key);

  @override
  State<ColliderGame> createState() => _ColliderGameState();
}

class _ColliderGameState extends State<ColliderGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // Shake-to-boost state (GLOBAL — one shake boosts both colliders).
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  double _shakeBoost = 0.0; // extra speed multiplier, decays toward 0

  // ── Colliders (one counter-orbiting ring ladder each) ───────────────────────
  final List<_Collider> _colliders = [];

  // ── Global FX (shared across all colliders) ─────────────────────────────────
  double _shake = 0.0; // screen-shake, 1 → 0
  double _idlePhase = 0.0;
  double _splitAnim = 0.0; // 0 = single collider centred, 1 = two split
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  // Last known viewport, so tap handlers / spawns can resolve geometry off-frame.
  Size _size = const Size(400, 800);

  @override
  void initState() {
    super.initState();
    // Collider #1 — present from the start, with randomized initial angles.
    final a1 = _rng.nextDouble() * 2 * math.pi;
    final a2 = a1 + math.pi * (0.7 + _rng.nextDouble() * 0.6);
    _colliders.add(_Collider(angle1: a1, angle2: a2));
    _ticker = createTicker(_onTick)..start();

    // ATTRACT autopilot: this game knows how to time its own collisions. The
    // host calls it on the autopilot cadence (~250ms) while running; it is a
    // no-op during hands-on play. See [_autoStep]. Registered always (harmless).
    widget.session.autoPilot = _autoStep;

    // Shake the device → speed the particles up.
    _accelSub = userAccelerometerEventStream().listen((e) {
      if (!widget.session.isRunning) return;
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mag > _kShakeThreshold) {
        _shakeBoost = math.min(
          _kMaxShakeBoost,
          _shakeBoost + (mag - _kShakeThreshold) * _kShakeGain,
        );
      }
    });
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _accelSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). This is a TIMING
  /// game: the particles may sweep clean through the crossing between two ticks,
  /// so "tap if currently aligned" would miss most collisions. Instead, for each
  /// collider we read the two particles' phase and their (level-scaled, shake-
  /// boosted) RELATIVE angular speed, then look one tick ahead:
  ///
  ///   • Only ever fire when firing NOW already scores — i.e. the current
  ///     separation is inside the CLOSE band ([_kCloseSep]). Tapping while the
  ///     particles are apart is a −5 miss, so we never do it.
  ///   • Among the ticks inside that band, fire on the one that is the LOCAL
  ///     MINIMUM of separation: only when NOW is at least as close to the
  ///     crossing as the NEXT tick will be (`sepNow <= sepNext`). If a tighter
  ///     tick is still ahead we wait for it — this prefers a PERFECT ([_kPerfectSep])
  ///     and guarantees a positive score.
  ///
  /// When two colliders are online we fire only the single best opportunity this
  /// tick (one move per call), matching how a real player taps.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // The host drives this on ~250ms cadence; look exactly one window ahead.
    const window = 0.25;
    final boost = 1.0 + _shakeBoost;

    int bestIdx = -1;
    double bestSep = double.infinity;

    for (var i = 0; i < _colliders.length; i++) {
      final c = _colliders[i];

      // Relative angular speed (rad/s): particle 1 advances, particle 2 recedes,
      // so the phase gap closes at the SUM of their level-scaled speeds.
      final omega = (_kBaseSpeed1 + _kBaseSpeed2) * c.speedFactor * boost;
      if (omega <= 0) continue;

      final sepNow = c.separation;
      if (sepNow >= _kCloseSep) continue; // apart → a tap would be a miss.

      // Predict the separation one tick from now from the signed phase gap.
      final gap = _wrap(c.angle1 - c.angle2); // advances at +omega
      final gapNext = _wrap(gap + omega * window);
      final sepNext = gapNext > math.pi ? 2 * math.pi - gapNext : gapNext;

      // A tighter tick is still ahead → wait for it rather than settle for CLOSE.
      if (sepNow > sepNext) continue;

      if (sepNow < bestSep) {
        bestSep = sepNow;
        bestIdx = i;
      }
    }

    if (bestIdx >= 0) _fireCollider(bestIdx);
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;

    // ── Halftime: bring the second collider online exactly once ──────────────
    if (running && _colliders.length == 1) {
      // Host owns the clock; halfway = remaining ≤ half the run length.
      final halfMs = widget.session.spec.durationSeconds * 500;
      if (widget.session.remaining.inMilliseconds <= halfMs) {
        _spawnSecondCollider();
      }
    }

    // Advance the split transition toward its target (only ever grows: once a
    // second collider exists it never leaves).
    if (_colliders.length > 1 && _splitAnim < 1.0) {
      _splitAnim = math.min(1.0, _splitAnim + dt / _kSplitDuration);
    }

    // Shake boost bleeds off over time; only applies while actually playing.
    _shakeBoost = math.max(0.0, _shakeBoost - dt * _kShakeDecay);
    final boost = running ? (1.0 + _shakeBoost) : 1.0;

    _idlePhase += dt;

    // ── Per-collider update ──────────────────────────────────────────────────
    for (final c in _colliders) {
      final factor = (running ? c.speedFactor : _kIdleFactor) * boost;
      c.angle1 = _wrap(c.angle1 + _kBaseSpeed1 * factor * dt);
      c.angle2 = _wrap(c.angle2 - _kBaseSpeed2 * factor * dt);

      // Per-collider juice decay.
      c.flash = math.max(0.0, c.flash - dt * 3.2);
      c.missFlash = math.max(0.0, c.missFlash - dt * 3.5);
    }

    // ── Global juice decay ───────────────────────────────────────────────────
    _shake = math.max(0.0, _shake - dt * 4.0);

    for (final s in _sparks) {
      s.age += dt;
      s.pos += s.vel * dt;
      s.vel *= math.pow(0.04, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    setState(() {});
  }

  void _spawnSecondCollider() {
    // Collider #2 — starts fresh at ring 0; collider #1 keeps its state.
    final a1 = _rng.nextDouble() * 2 * math.pi;
    final a2 = a1 + math.pi * (0.7 + _rng.nextDouble() * 0.6);
    _colliders.add(_Collider(angle1: a1, angle2: a2));
    _shake = 1.0;

    final origin = Offset(_size.width / 2, _size.height / 2);
    _popups.add(_Popup('SECOND COLLIDER ONLINE', origin, _kMagenta, big: true));
    _spawnSparks(origin, 40, big: true);
  }

  void _handleTap(Size size, Offset localPos) {
    if (!widget.session.isRunning) return;

    // Route the tap to a collider by zone: single → collider 0; split → the
    // half the finger landed in (top y<h/2 → collider 0, bottom → collider 1).
    final int idx;
    if (_colliders.length <= 1) {
      idx = 0;
    } else {
      idx = localPos.dy < size.height / 2 ? 0 : 1;
    }
    _fireCollider(idx);
  }

  /// Score a firing of collider [idx] against its CURRENT separation, using the
  /// same PERFECT / CLOSE / MISS thresholds as a real tap. Both the finger
  /// ([_handleTap]) and the attract autopilot ([_autoStep]) go through here so
  /// there is exactly one place that decides what a hit is worth.
  void _fireCollider(int idx) {
    final size = _size;
    final c = _colliders[idx];

    final sep = c.separation;
    final geom = _colliderGeo(size, _splitAnim, idx, _colliders.length);
    final ringRadius = geom.radiusForLevel(c.level);
    final hitAngle = c.crossingAngle;
    final hitPos = geom.pointAtRadius(hitAngle, ringRadius);

    if (sep < _kPerfectSep) {
      final score = _kBasePerfectScore + c.level * _kScorePerLevel;
      widget.session.addScore(score);
      c.flash = 1.0;
      _shake = 1.0;
      c.flashAngle = hitAngle;
      _spawnSparks(hitPos, 34, big: true);
      _popups.add(_Popup('PERFECT +$score', hitPos, Colors.white, big: true));
      _promote(c);
    } else if (sep < _kCloseSep) {
      final score = _kBaseCloseScore + c.level * (_kScorePerLevel ~/ 2);
      widget.session.addScore(score);
      c.flash = 0.55;
      _shake = 0.4;
      c.flashAngle = hitAngle;
      _spawnSparks(hitPos, 16, big: false);
      _popups.add(_Popup('CLOSE +$score', hitPos, _kCyan, big: false));
      _promote(c);
    } else {
      widget.session.addScore(-_kMissPenalty);
      c.missFlash = 1.0;
      _popups.add(_Popup('−$_kMissPenalty', geom.center, _kRed, big: false));
      _applyMiss(c);
      return; // _applyMiss respawns internally; skip the shared respawn.
    }

    _respawn(c);
  }

  /// Successful hit: go up one ring, reset that collider's miss counter.
  void _promote(_Collider c) {
    c.consecutiveMisses = 0;
    if (c.level < _kRingCount - 1) {
      c.level++;
    }
    // If already at the cap, stay and keep scoring (no demotion).
  }

  /// Miss logic: first miss → drop one ring; second consecutive miss → ring 0.
  void _applyMiss(_Collider c) {
    c.consecutiveMisses++;
    if (c.consecutiveMisses >= 2) {
      c.level = 0;
      c.consecutiveMisses = 0;
    } else {
      if (c.level > 0) c.level--;
    }
    _respawn(c);
  }

  void _respawn(_Collider c) {
    c.angle1 = _rng.nextDouble() * 2 * math.pi;
    final gap = 1.2 + _rng.nextDouble() * (math.pi - 1.2);
    c.angle2 = _wrap(c.angle1 + (_rng.nextBool() ? gap : -gap));
  }

  void _spawnSparks(Offset origin, int count, {required bool big}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed =
          (big ? 140.0 : 90.0) + _rng.nextDouble() * (big ? 240 : 140);
      final palette = [
        Colors.white,
        _kMagenta,
        _kCyan,
        _kAccent,
        const Color(0xFFFFE082),
      ];
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.45 + _rng.nextDouble() * 0.55,
        radius: 1.2 + _rng.nextDouble() * (big ? 2.6 : 1.6),
        color: palette[_rng.nextInt(palette.length)],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!size.width.isFinite ||
            !size.height.isFinite ||
            size.width <= 0 ||
            size.height <= 0) {
          return const SizedBox.shrink();
        }
        _size = size;

        final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 14 * _shake : 0.0;
        final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 14 * _shake : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTap(size, details.localPosition),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: CustomPaint(
                      painter: _ColliderPainter(
                        colliders: _colliders,
                        split: _splitAnim,
                        idlePhase: _idlePhase,
                        sparks: _sparks,
                        popups: _popups,
                      ),
                    ),
                  ),
                ),

                // Ring / level readout(s) — one per collider, positioned near it.
                ..._buildBadges(size),

                // Shake-boost meter (only while a boost is active) — GLOBAL, since
                // one shake boosts both colliders.
                if (_shakeBoost > 0.02)
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kMagenta.withValues(
                                alpha: 0.4 +
                                    0.5 * (_shakeBoost / _kMaxShakeBoost))),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt,
                              size: 13,
                              color: _kMagenta.withValues(alpha: 0.95)),
                          const SizedBox(width: 3),
                          Text(
                            '×${(1 + _shakeBoost).toStringAsFixed(1)}',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: _kMagenta.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ring badges — before the split, a single badge top-right; after the split,
  // a small badge floated above each collider's ladder.
  List<Widget> _buildBadges(Size size) {
    if (_colliders.length <= 1) {
      return [
        Positioned(top: 10, right: 12, child: _ringBadge(_colliders[0])),
      ];
    }
    final list = <Widget>[];
    for (var i = 0; i < _colliders.length; i++) {
      final geom = _colliderGeo(size, _splitAnim, i, _colliders.length);
      final outerR = geom.radiusForLevel(_kRingCount - 1);
      final top =
          (geom.center.dy - outerR - 26.0).clamp(6.0, size.height - 30.0);
      list.add(Positioned(top: top, right: 12, child: _ringBadge(_colliders[i])));
    }
    return list;
  }

  Widget _ringBadge(_Collider c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
      ),
      child: Text(
        'RING ${c.level + 1} / $_kRingCount',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: _kAccent.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-collider state. Each collider promotes/demotes INDEPENDENTLY; the feel
// constants are shared top-level, the level-scaled derived values live here.
// ---------------------------------------------------------------------------

class _Collider {
  // Particle state.
  double angle1;
  double angle2;

  // Ring / level state.
  int level = 0; // 0 = innermost ring
  int consecutiveMisses = 0;

  // Per-collider juice.
  double flash = 0.0;
  double missFlash = 0.0;
  double flashAngle = 0.0;

  _Collider({required this.angle1, required this.angle2});

  // Current orbit speed multiplier derived from ring level.
  double get speedFactor => math.pow(_kSpeedPerLevel, level).toDouble();

  double get separation {
    final d = (angle1 - angle2).abs() % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  double get crossingAngle {
    final d = _wrap(angle2 - angle1);
    final half = d <= math.pi ? d / 2 : (d - 2 * math.pi) / 2;
    return _wrap(angle1 + half);
  }
}

// ---------------------------------------------------------------------------
// Geometry — concentric ring ladder. A single helper resolves each collider's
// centre + effective min-dimension from the split animation and its slot, so
// the painter, badges and tap handler all agree. Guarded against degenerate
// viewports.
// ---------------------------------------------------------------------------

/// Smoothstep 0..1.
double _smooth(double t) {
  if (t <= 0) return 0;
  if (t >= 1) return 1;
  return t * t * (3 - 2 * t);
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;

double _wrap(double a) {
  const tau = 2 * math.pi;
  a %= tau;
  return a < 0 ? a + tau : a;
}

class _RingGeometry {
  final Offset center;
  final double minDim;

  const _RingGeometry(this.center, this.minDim);

  /// Radius for a given ring level (0 = innermost).
  double radiusForLevel(int level) {
    if (_kRingCount <= 1) return minDim * _kOuterRadiusFraction;
    final t = level / (_kRingCount - 1);
    return minDim *
        (_kInnerRadiusFraction +
            t * (_kOuterRadiusFraction - _kInnerRadiusFraction));
  }

  Offset pointAtRadius(double angle, double radius) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

/// Resolve geometry for a given collider slot. `colliderCount <= 1` is the
/// original full-size centred layout (visuals IDENTICAL to pre-halftime). With
/// two colliders, we lerp from that single layout to a split top/bottom layout:
/// slot 0 rises toward h*0.28, slot 1 sinks toward h*0.72, and the effective
/// min-dim shrinks so each ladder's outer ring fits comfortably in its half
/// without the two overlapping.
_RingGeometry _colliderGeo(Size size, double split, int slot, int colliderCount) {
  final w = size.width;
  final h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
    return const _RingGeometry(Offset(1, 1), 1);
  }

  final singleMinDim = math.min(w, h);

  if (colliderCount <= 1) {
    return _RingGeometry(Offset(w / 2, h / 2), singleMinDim);
  }

  final e = _smooth(split);
  // Shrunk min-dim so a collider's outer ring (0.42×) spans ~0.14×h — leaving
  // clearance around each half. Also bounded by width on narrow viewports.
  final twoMinDim = math.max(24.0, math.min(w * 0.9, h * 0.34));
  final minDim = _lerpD(singleMinDim, twoMinDim, e);

  final cy = slot == 0
      ? _lerpD(h / 2, h * 0.28, e) // top ladder rises
      : _lerpD(h / 2, h * 0.72, e); // bottom ladder sinks

  return _RingGeometry(Offset(w / 2, cy), minDim);
}

// ---------------------------------------------------------------------------
// Data classes.
// ---------------------------------------------------------------------------

class _Spark {
  Offset pos; // absolute canvas position
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
      : life = big ? 1.1 : 0.85;
}

// ---------------------------------------------------------------------------
// Painter — loops over every collider drawing its ladder at its own slot
// geometry. The background grid + vignette stay shared/global; sparks and
// popups are drawn once, globally, in absolute coordinates.
// ---------------------------------------------------------------------------

class _ColliderPainter extends CustomPainter {
  final List<_Collider> colliders;
  final double split;
  final double idlePhase;
  final List<_Spark> sparks;
  final List<_Popup> popups;

  _ColliderPainter({
    required this.colliders,
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

    for (var i = 0; i < colliders.length; i++) {
      final c = colliders[i];
      final geom = _colliderGeo(size, split, i, colliders.length);
      _paintVignette(canvas, geom);
      _paintDetector(canvas, geom);
      _paintAllRings(canvas, geom, c);
      _paintConvergenceGlow(canvas, geom, c);
      _paintParticle(canvas, geom, c, c.angle1, 1.0, _kMagenta);
      _paintParticle(canvas, geom, c, c.angle2, -1.0, _kCyan);
      _paintFlash(canvas, geom, c);
    }

    _paintSparks(canvas);
    _paintPopups(canvas);
  }

  // ── Background (shared) ──────────────────────────────────────────────────────

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final grid = Paint()
      ..color = _kAccent.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  // ── Per-collider vignette glow ───────────────────────────────────────────────

  void _paintVignette(Canvas canvas, _RingGeometry geom) {
    final outerR = geom.radiusForLevel(_kRingCount - 1);
    canvas.drawCircle(
      geom.center,
      outerR * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.10),
            _kAccent.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: geom.center, radius: outerR * 1.5)),
    );
  }

  void _paintDetector(Canvas canvas, _RingGeometry geom) {
    final outerR = geom.radiusForLevel(_kRingCount - 1);

    // Outer detector shell and tick marks.
    final shell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(geom.center, outerR * 1.22, shell);

    final tick = Paint()
      ..color = _kAccent.withValues(alpha: 0.22)
      ..strokeWidth = 1.5;
    final spin = idlePhase * 0.15;
    for (var i = 0; i < 36; i++) {
      final a = spin + i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        geom.center + dir * (outerR * 1.22),
        geom.center + dir * (outerR * 1.22 + (i % 6 == 0 ? 9.0 : 4.0)),
        tick,
      );
    }
  }

  /// Draw all rings faintly; the current ring is drawn brightly.
  void _paintAllRings(Canvas canvas, _RingGeometry geom, _Collider c) {
    for (var i = 0; i < _kRingCount; i++) {
      final r = geom.radiusForLevel(i);
      final isCurrent = i == c.level;

      // Bloom glow (only for current ring).
      if (isCurrent) {
        canvas.drawCircle(
          geom.center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..color = _kAccent.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Beam pipe.
      canvas.drawCircle(
        geom.center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrent ? 3.0 : 1.0
          ..color = isCurrent
              ? _kAccent.withValues(alpha: 0.75)
              : _kAccent.withValues(alpha: 0.18),
      );

      // Miss feedback on current ring.
      if (isCurrent && c.missFlash > 0) {
        canvas.drawCircle(
          geom.center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = _kRed.withValues(alpha: 0.5 * c.missFlash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  /// The ring segment between the particles brightens as they converge.
  void _paintConvergenceGlow(Canvas canvas, _RingGeometry geom, _Collider c) {
    final separation = c.separation;
    if (separation >= math.pi * 0.999) return;
    final closeness = (1 - separation / math.pi).clamp(0.0, 1.0);
    final intensity = math.pow(closeness, 3).toDouble();
    if (intensity <= 0.02) return;

    final r = geom.radiusForLevel(c.level);
    final rect = Rect.fromCircle(center: geom.center, radius: r);
    final start = c.crossingAngle - separation / 2;

    canvas.drawArc(
      rect,
      start,
      separation,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 + 6 * intensity
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.10 + 0.55 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _paintParticle(Canvas canvas, _RingGeometry geom, _Collider c,
      double angle, double direction, Color color) {
    final r = geom.radiusForLevel(c.level);

    // Comet tail.
    const tailCount = 16;
    for (var i = tailCount; i >= 1; i--) {
      final t = i / tailCount;
      final trailAngle = angle - direction * t * 0.55;
      final p = geom.pointAtRadius(trailAngle, r);
      canvas.drawCircle(
        p,
        5.5 * (1 - t) + 0.8,
        Paint()..color = color.withValues(alpha: 0.30 * (1 - t) * (1 - t)),
      );
    }

    final pos = geom.pointAtRadius(angle, r);

    // Bloom.
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Body.
    canvas.drawCircle(pos, 7, Paint()..color = color);
    // Hot white core.
    canvas.drawCircle(
        pos, 3, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  void _paintSparks(Canvas canvas) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final paint = Paint()..color = s.color.withValues(alpha: t);
      final dir = s.vel.distance > 1
          ? s.vel / s.vel.distance
          : const Offset(1, 0);
      canvas.drawLine(s.pos - dir * (6 * t), s.pos, paint..strokeWidth = 1.6);
      canvas.drawCircle(s.pos, s.radius * t, paint);
    }
  }

  void _paintFlash(Canvas canvas, _RingGeometry geom, _Collider c) {
    if (c.flash <= 0) return;
    final r = geom.radiusForLevel(c.level);
    final pos = geom.pointAtRadius(c.flashAngle, r);

    canvas.drawCircle(
      pos,
      26 + 70 * (1 - c.flash),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 * c.flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(pos, 12 * c.flash,
        Paint()..color = Colors.white.withValues(alpha: c.flash));

    canvas.drawCircle(
      pos,
      18 + 90 * (1 - c.flash),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * c.flash
        ..color = _kAccent.withValues(alpha: 0.8 * c.flash),
    );
  }

  void _paintPopups(Canvas canvas) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 36.0 * t;
      final scale = p.big ? 1.0 + 0.25 * (1 - t) : 1.0;

      final painter = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: (p.big ? 22 : 16) * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: alpha * 0.8),
                  blurRadius: 12),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        p.origin - Offset(painter.width / 2, painter.height / 2 + rise),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColliderPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL in-game
// components (same ring-ladder + particle style the live painter uses).
// Static + cheap: rendered once on the intro screen, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

bool _legendBadSize(Size size) =>
    !size.width.isFinite ||
    !size.height.isFinite ||
    size.width <= 0 ||
    size.height <= 0;

/// Ring ladder exactly as [_ColliderPainter._paintAllRings] draws it: every
/// ring faint, the current ring bright with a bloom (red-flashed on a miss).
void _legendLadder(Canvas canvas, _RingGeometry geom, int currentLevel,
    {bool missFlash = false}) {
  for (var i = 0; i < _kRingCount; i++) {
    final r = geom.radiusForLevel(i);
    final isCurrent = i == currentLevel;

    if (isCurrent) {
      canvas.drawCircle(
        geom.center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = _kAccent.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    canvas.drawCircle(
      geom.center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2.8 : 1.0
        ..color = _kAccent.withValues(alpha: isCurrent ? 0.75 : 0.18),
    );

    if (isCurrent && missFlash) {
      canvas.drawCircle(
        geom.center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = _kRed.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }
}

/// One orbiting particle with its comet tail, bloom, body and hot white core —
/// mirroring [_ColliderPainter._paintParticle].
void _legendParticle(Canvas canvas, _RingGeometry geom, int level,
    double angle, double direction, Color color,
    {double scale = 1.0}) {
  final r = geom.radiusForLevel(level);

  const tailCount = 12;
  for (var i = tailCount; i >= 1; i--) {
    final t = i / tailCount;
    final p = geom.pointAtRadius(angle - direction * t * 0.55, r);
    canvas.drawCircle(
      p,
      (5.0 * (1 - t) + 0.8) * scale,
      Paint()..color = color.withValues(alpha: 0.30 * (1 - t) * (1 - t)),
    );
  }

  final pos = geom.pointAtRadius(angle, r);
  canvas.drawCircle(
    pos,
    14 * scale,
    Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  canvas.drawCircle(pos, 6.5 * scale, Paint()..color = color);
  canvas.drawCircle(pos, 2.8 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.95));
}

/// Small glowing label in the game's popup style.
void _legendText(
    Canvas canvas, String text, Offset center, double fontSize, Color color) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Frame 1 — the core objects: the ring ladder with the two counter-orbiting
/// particles well apart, comet tails showing their opposite directions.
void _legendOrbit(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final geom = _RingGeometry(
    Offset(size.width / 2, size.height / 2),
    math.min(size.width, size.height),
  );
  _legendLadder(canvas, geom, 0);
  _legendParticle(canvas, geom, 0, math.pi * 0.85, 1.0, _kMagenta);
  _legendParticle(canvas, geom, 0, -math.pi * 0.15, -1.0, _kCyan);
}

/// Frame 2 — how to score: the particles converging at the crossing, the white
/// convergence glow lit, the collision flash and a PERFECT popup. Hits climb
/// the ladder to faster, higher-scoring rings.
void _legendTapCross(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final geom = _RingGeometry(
    Offset(size.width / 2, size.height / 2),
    math.min(size.width, size.height),
  );
  const level = 1;
  const crossing = -math.pi / 2; // meet at the top
  const halfSep = 0.10;
  _legendLadder(canvas, geom, level);

  // Convergence glow on the arc between the particles.
  final r = geom.radiusForLevel(level);
  canvas.drawArc(
    Rect.fromCircle(center: geom.center, radius: r),
    crossing - halfSep,
    halfSep * 2,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );

  // Collision flash at the crossing point.
  final hit = geom.pointAtRadius(crossing, r);
  canvas.drawCircle(
    hit,
    30,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
  );
  canvas.drawCircle(
    hit,
    22,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kAccent.withValues(alpha: 0.8),
  );

  _legendParticle(canvas, geom, level, crossing - halfSep, 1.0, _kMagenta);
  _legendParticle(canvas, geom, level, crossing + halfSep, -1.0, _kCyan);

  _legendText(canvas, 'PERFECT +$_kBasePerfectScore',
      Offset(geom.center.dx, geom.center.dy - r * 0.35), 15, Colors.white);
}

/// Frame 3 — the penalty: tapping while the particles are apart costs points
/// and demotes you a ring (two misses in a row send you back to ring 1).
void _legendMiss(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;
  final geom = _RingGeometry(
    Offset(size.width / 2, size.height / 2),
    math.min(size.width, size.height),
  );
  const level = 1;
  _legendLadder(canvas, geom, level, missFlash: true);
  _legendParticle(canvas, geom, level, math.pi * 0.75, 1.0, _kMagenta);
  _legendParticle(canvas, geom, level, -math.pi * 0.25, -1.0, _kCyan);

  // Demotion arrow: current ring → the ring below it.
  final r1 = geom.radiusForLevel(level);
  final r0 = geom.radiusForLevel(level - 1);
  final from = geom.pointAtRadius(0, r1 - 4);
  final to = geom.pointAtRadius(0, r0 + 4);
  final arrow = Paint()
    ..color = _kRed.withValues(alpha: 0.9)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(from, to, arrow);
  canvas.drawLine(to, to + const Offset(6, -7), arrow);
  canvas.drawLine(to, to + const Offset(-6, -7), arrow);

  _legendText(canvas, '−$_kMissPenalty', geom.center, 20, _kRed);
}

/// Frame 4 — the halftime escalation: the screen splits into TWO independent
/// ring ladders; tap the top half for the top collider, bottom for the bottom.
void _legendSplit(Canvas canvas, Size size) {
  if (_legendBadSize(size)) return;

  // Divider between the two tap zones.
  final divider = Paint()
    ..color = _kAccent.withValues(alpha: 0.35)
    ..strokeWidth = 1.5;
  final midY = size.height / 2;
  const dash = 8.0;
  for (double x = 4; x < size.width - 4; x += dash * 2) {
    canvas.drawLine(Offset(x, midY),
        Offset(math.min(x + dash, size.width - 4), midY), divider);
  }

  for (var slot = 0; slot < 2; slot++) {
    final geom = _colliderGeo(size, 1.0, slot, 2);
    _legendLadder(canvas, geom, slot == 0 ? 2 : 0);
    final a = slot == 0 ? math.pi * 0.7 : math.pi * 0.2;
    _legendParticle(canvas, geom, slot == 0 ? 2 : 0, a, 1.0, _kMagenta,
        scale: 0.8);
    _legendParticle(canvas, geom, slot == 0 ? 2 : 0, a + math.pi * 0.8, -1.0,
        _kCyan,
        scale: 0.8);
  }
}

/// The visual manual for Collider — wired into the registry spec.
final List<LegendFrame> colliderLegendFrames = [
  const LegendFrame(
      caption: 'Two particles orbit the ring in opposite ways',
      paint: _legendOrbit),
  const LegendFrame(
      caption: 'Tap as they cross — hits climb to faster rings',
      paint: _legendTapCross),
  const LegendFrame(
      caption: 'Tap while apart: −5 and you drop a ring',
      paint: _legendMiss),
  const LegendFrame(
      caption: 'At halftime, juggle TWO colliders — tap each half',
      paint: _legendSplit),
];
