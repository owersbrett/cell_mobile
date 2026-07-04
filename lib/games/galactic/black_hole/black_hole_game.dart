// ═══════════════════════════════════════════════════════════════════════════════
// BlackHoleGame — "Black-Hole Heart"
// The galaxy's central engine: a SUPERMASSIVE black hole (Sgr A*). Fling stars
// into STABLE orbits around it. Too little tangential speed and a star spirals
// past the event horizon and is SWALLOWED; too much and it ESCAPES off the field.
// The sweet spot is a real orbit — and CLOSER orbits are FASTER, score MORE, and
// are far more PRECARIOUS (stronger pull, relativistic whip, faster decay).
//
// This is deliberately NOT the gentle planet-orbit feel of orbit_catch /
// orbital_mechanic. Here there is ONE overwhelming central mass, a lethal event
// horizon, an accretion glow, a pseudo-relativistic correction that makes close
// orbits precess and whip, and accretion drag that slowly decays every orbit so
// the field must be actively managed. The black hole always wins eventually; you
// score by how long and how tight you can ride the edge.
//
// HOST CONTRACT: the MiniGameHost owns intro / 3·2·1 countdown / score-HUD /
// timer / results. This widget renders ONLY the play area, runs its loop only
// while widget.session.isRunning, reports points via widget.session.addScore and
// streaks via widget.session.noteStreak. It draws no timer, no score, no
// game-over. A swallowed/escaped star only ends THAT star — a fresh fling always
// re-enters cleanly (the GAMES "S").
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). No import of any other game.
//
// PERFORMANCE: ONE Ticker drives the whole sim + fx + preview; one
// CustomPainter draws everything. The widget subtree under CustomPaint stays
// tiny (a few pills) to avoid the black-screen / jitter bug-class.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tune these without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Gravity. a = GM / r² · (1 + relK·horizon/r). The relativistic term makes the
// pull blow up faster than Newton near the horizon → close orbits whip + precess.
const double _kGM = 1.4e7; // circular speed sqrt(GM/r): ~305 px/s at r=150
const double _kRelK = 1.0; // strength of the pseudo-relativistic correction

// Event horizon (lethal) + inner stable boundary (ISCO analog).
const double _kHorizonBase = 32.0; // px; grows slightly over the round
const double _kHorizonGrow = 12.0; // px added by t=60 (safe-zone tightens)
const double _kIscoFactor = 2.1; // ISCO ring = horizon × this (extra-unstable inside)

// Accretion drag — every orbit slowly decays (energy bleeds to the disk). Inside
// the ISCO it decays much faster, so the tightest, highest-scoring orbits are the
// most precarious. This is the management pressure of the whole game.
const double _kDragBase = 0.045; // per second, outside ISCO
const double _kDragInner = 3.2; // multiplier inside the ISCO

// Fling input (direct aim: the drag vector IS the launch velocity).
const double _kDragToSpeed = 3.2; // drag px → px/s
const double _kMinSpeed = 50.0;
const double _kMaxSpeed = 540.0;
const double _kStarRadius = 6.0;

// Scoring.
const double _kPtsPerSec = 44.0; // base income/sec, scaled by closeness
const double _kClosenessRef = 150.0; // closeness = ref/r, clamped
const double _kClosenessMin = 0.16;
const double _kClosenessMax = 1.45;
const int _kRevBonus = 60; // per full revolution, scaled by closeness

// Population cap (grows over the round → more to juggle).
const int _kStartCap = 4;
const int _kMaxCap = 7;
const double _kCapEverySec = 18.0;

// Gravitational kicks — periodic perturbations (the "relativistic whip" event)
// that destabilize every orbit; the player must re-manage. Begins after a grace.
const double _kKickFirst = 15.0; // s before the first kick
const double _kKickEvery = 10.0; // s between kicks
const double _kKickStrength = 78.0; // px/s impulse magnitude

// Trajectory preview (same sim as the live star).
const int _kPreviewSteps = 150;
const double _kPreviewDt = 0.020;

// ─────────────────────────────────────────────────────────────────────────────

/// A star in flight around the black hole. Positions/velocities are canvas px.
class _Star {
  double x, y;
  double vx, vy;
  bool alive;
  double accAngle; // signed accumulated sweep (rad) → revolutions
  double? prevAngle;
  double bornT;
  final List<Offset> trail;
  _Star({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.bornT,
  })  : alive = true,
        accAngle = 0,
        prevAngle = null,
        trail = <Offset>[];
}

class BlackHoleGame extends StatefulWidget {
  final MiniGameSession session;
  const BlackHoleGame({super.key, required this.session});
  @override
  State<BlackHoleGame> createState() => _BlackHoleGameState();
}

class _BlackHoleGameState extends State<BlackHoleGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  Size _canvasSize = Size.zero;
  double _t = 0.0; // seconds since mount (atmosphere + schedule clock)

  final List<_Star> _stars = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // Aim / fling.
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;

  // Progress (host owns the score/timer/results).
  double _pointBank = 0.0; // fractional score, flushed to session as integers
  int _streak = 0; // consecutive revolutions banked without losing a star
  int _swallowed = 0;

  // Schedule / pacing.
  double _nextKickT = _kKickFirst;
  double _kickFlash = 0.0; // 0..1, decays — the whip pulse
  double _swallowFlash = 0.0; // 0..1, decays — horizon feed pulse

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game can aim and fling itself. Registered here,
    // dormant in normal play — the host only invokes it in hands-free mode.
    // See [_autoStep]. Cleared on dispose.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent fling per host tick (~250ms). Acts only when the field is
  /// IDLE (no star alive) so it never re-flings over a star that is still
  /// riding. It births a star at a fixed radius from the black hole and
  /// launches it TANGENTIALLY (perpendicular to the radial direction) at the
  /// local circular-orbit speed — the dead centre of the stable band between
  /// swallow (too slow) and escape (too fast, v_esc = √2·v_circ).
  ///
  /// The launch radius is pinned just OUTSIDE the ISCO (r = isco × 1.45): the
  /// tightest orbit that still decays slowly, so the demo rides a high-
  /// closeness, high-scoring orbit without being fed to the horizon on the
  /// first lap (biased toward the faster/tighter, higher-scoring side while
  /// staying stable). The circular speed uses the game's OWN gravity —
  /// including the pseudo-relativistic close-in correction — so it is genuinely
  /// circular here:  a = GM/r²·(1 + relK·horizon/r),  v_circ = √(a·r).
  /// Reuses [_flingStar], the same spawn path a drag-release takes.
  /// Deterministic; guarded on session.isRunning.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_canvasSize == Size.zero) return;
    if (_aliveCount > 0) return; // a star is still riding — don't re-fling
    if (_aliveCount >= _cap) return;

    final c = _center;
    final horizon = _horizon;
    final r = _isco * 1.45; // just outside the ISCO — tight but stable
    // Fixed radial direction (straight up); origin sits at radius r from the hole.
    final origin = Offset(c.dx, c.dy - r);
    final rel = origin - c; // radial vector (hole → star)
    final rr = rel.distance;
    if (rr <= horizon + _kStarRadius) return; // never birth inside the horizon

    // Circular-orbit speed at r under the game's own (relativistic) gravity.
    final a = (_kGM / (rr * rr)) * (1 + _kRelK * horizon / rr);
    final vCirc = sqrt(a * rr);
    // Unit tangent — perpendicular to the radial direction → a round orbit.
    final tangent = Offset(-rel.dy, rel.dx) / rr;
    _flingStar(origin, tangent * vCirc);
  }

  /// Births a star at [origin] with launch velocity [vel] — the shared spawn
  /// path used by both a drag-release and the attract autopilot.
  void _flingStar(Offset origin, Offset vel) {
    setState(() {
      _stars.add(_Star(
          x: origin.dx, y: origin.dy, vx: vel.dx, vy: vel.dy, bornT: _t));
    });
  }

  // ── derived geometry ───────────────────────────────────────────────────────
  Offset get _center =>
      Offset(_canvasSize.width / 2, _canvasSize.height * 0.5);

  double get _horizon {
    final p = (_t / 60.0).clamp(0.0, 1.0);
    return _kHorizonBase + _kHorizonGrow * p;
  }

  double get _isco => _horizon * _kIscoFactor;

  double get _escapeR =>
      _canvasSize == Size.zero ? 1e9 : _canvasSize.longestSide * 0.62;

  int get _cap => (_kStartCap + (_t / _kCapEverySec).floor()).clamp(_kStartCap, _kMaxCap);

  int get _aliveCount => _stars.where((s) => s.alive).length;

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the sim must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) {
      // Keep the canvas alive behind the host's countdown / results.
      setState(() => _t += dt);
      return;
    }
    setState(() {
      _t += dt;
      if (_kickFlash > 0) _kickFlash = (_kickFlash - dt * 1.6).clamp(0.0, 1.0);
      if (_swallowFlash > 0) {
        _swallowFlash = (_swallowFlash - dt * 2.2).clamp(0.0, 1.0);
      }

      // Gravitational kick event.
      if (_t >= _nextKickT) {
        _applyKick();
        _nextKickT = _t + _kKickEvery;
      }

      double income = 0.0;
      for (final s in _stars) {
        if (!s.alive) continue;
        _advanceStar(s, dt);
        if (!s.alive) continue;
        income += _scoreStar(s, dt);
      }
      _pointBank += income;
      final whole = _pointBank.floor();
      if (whole > 0) {
        widget.session.addScore(whole);
        _pointBank -= whole;
      }

      _stars.removeWhere((s) => !s.alive && s.trail.isEmpty);
      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── physics — one overwhelming central mass, sub-stepped ────────────────────
  void _advanceStar(_Star s, double dt) {
    if (_canvasSize == Size.zero) return;
    final c = _center;
    final horizon = _horizon;
    final isco = _isco;
    const subSteps = 6;
    final subDt = dt / subSteps;

    for (int i = 0; i < subSteps; i++) {
      final dx = c.dx - s.x;
      final dy = c.dy - s.y;
      final r2 = dx * dx + dy * dy;
      final r = sqrt(r2);

      if (r <= horizon) {
        // Crossed the event horizon — swallowed.
        s.alive = false;
        _onSwallowed(Offset(s.x, s.y));
        return;
      }

      // Newtonian pull + pseudo-relativistic close-in correction.
      final a = (_kGM / r2) * (1 + _kRelK * horizon / r);
      s.vx += (dx / r) * a * subDt;
      s.vy += (dy / r) * a * subDt;

      // Accretion drag — orbits decay; tighter (inside ISCO) decays much faster.
      final drag = _kDragBase * (r < isco ? _kDragInner : 1.0);
      final damp = 1.0 - drag * subDt;
      s.vx *= damp;
      s.vy *= damp;

      s.x += s.vx * subDt;
      s.y += s.vy * subDt;

      if (r > _escapeR) {
        // Flung clear of the field — escaped, lost.
        s.alive = false;
        _onEscaped();
        return;
      }
    }

    // Trail.
    s.trail.add(Offset(s.x, s.y));
    if (s.trail.length > 46) s.trail.removeAt(0);

    // Revolution accounting (once per frame).
    final ang = atan2(s.y - c.dy, s.x - c.dx);
    if (s.prevAngle != null) {
      double d = ang - s.prevAngle!;
      if (d > pi) d -= 2 * pi;
      if (d <= -pi) d += 2 * pi;
      s.accAngle += d;
      if (s.accAngle.abs() >= 2 * pi) {
        s.accAngle -= s.accAngle.sign * 2 * pi;
        _onRevolution(s);
      }
    }
    s.prevAngle = ang;
  }

  double _closeness(double r) =>
      (_kClosenessRef / r).clamp(_kClosenessMin, _kClosenessMax);

  /// Continuous orbital income for one star this frame. Tighter = more.
  double _scoreStar(_Star s, double dt) {
    final r = (Offset(s.x, s.y) - _center).distance;
    return _kPtsPerSec * _closeness(r) * dt;
  }

  void _onRevolution(_Star s) {
    final r = (Offset(s.x, s.y) - _center).distance;
    final close = _closeness(r);
    final bonus = (_kRevBonus * close).round();
    widget.session.addScore(bonus);
    _streak++;
    widget.session.noteStreak(_streak);
    _pops.add(FxPop(Offset(s.x, s.y - 14), '+$bonus', Potatuhs.gold));
    if (_streak >= 2) {
      _pops.add(FxPop(Offset(s.x, s.y - 36), '${_streak}x', Potatuhs.orange));
    }
    _fx.addAll(FxBurst.spawn(Offset(s.x, s.y), Potatuhs.gold,
        count: 8, speed: 90, size: 3));
  }

  void _onSwallowed(Offset at) {
    _swallowed++;
    _streak = 0;
    _swallowFlash = 1.0;
    // Particles sucked toward the singularity.
    _fx.addAll(FxBurst.spawn(at, _kAccretionHot, count: 14, speed: 120, size: 4));
    _fx.addAll(FxBurst.spawn(at, _kAccretionViolet, count: 8, speed: 70, size: 3));
  }

  void _onEscaped() {
    _streak = 0;
  }

  void _applyKick() {
    final rng = Random();
    for (final s in _stars) {
      if (!s.alive) continue;
      final ang = rng.nextDouble() * 2 * pi;
      final mag = _kKickStrength * (0.6 + rng.nextDouble() * 0.8);
      s.vx += cos(ang) * mag;
      s.vy += sin(ang) * mag;
    }
    _kickFlash = 1.0;
  }

  // ── fling input (direct aim) ───────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    if (_aliveCount >= _cap) return;
    // Cannot birth a star inside the event horizon.
    if ((d.localPosition - _center).distance <= _horizon + _kStarRadius) return;
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    final start = _dragStart;
    if (start == null || _dragCurrent == null) {
      _clearDrag();
      return;
    }
    if (!widget.session.isRunning || _aliveCount >= _cap) {
      _clearDrag();
      return;
    }
    final v = _launchVector();
    _clearDrag();
    _flingStar(start, v);
  }

  void _clearDrag() {
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  /// Direct-aim launch velocity: direction = drag vector, speed = length curve.
  Offset _launchVector() {
    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) return const Offset(0, 0);
    final speed = (len * _kDragToSpeed).clamp(_kMinSpeed, _kMaxSpeed);
    return Offset(dx / len * speed, dy / len * speed);
  }

  // ── trajectory preview — same gravity sim, dimensionally identical ─────────
  List<Offset> _buildPreview() {
    if (!_isDragging || !widget.session.isRunning || _canvasSize == Size.zero) {
      return const [];
    }
    final c = _center;
    final horizon = _horizon;
    final isco = _isco;
    final v = _launchVector();
    double px = _dragStart!.dx, py = _dragStart!.dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[];
    for (int i = 0; i < _kPreviewSteps; i++) {
      final dx = c.dx - px;
      final dy = c.dy - py;
      final r2 = dx * dx + dy * dy;
      final r = sqrt(r2);
      if (r <= horizon) {
        pts.add(Offset(px, py));
        break; // would be swallowed
      }
      final a = (_kGM / r2) * (1 + _kRelK * horizon / r);
      vx += (dx / r) * a * _kPreviewDt;
      vy += (dy / r) * a * _kPreviewDt;
      final drag = _kDragBase * (r < isco ? _kDragInner : 1.0);
      final damp = 1.0 - drag * _kPreviewDt;
      vx *= damp;
      vy *= damp;
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      if (r > _escapeR) break; // would escape
    }
    return pts;
  }

  /// Classifies the previewed shot for the aim readout.
  String _previewVerdict(List<Offset> preview) {
    if (preview.isEmpty) return '';
    final last = preview.last;
    final rLast = (last - _center).distance;
    if (rLast <= _horizon + _kStarRadius) return 'SWALLOWED';
    if (rLast > _escapeR) return 'ESCAPES';
    return 'ORBIT';
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      final preview = _buildPreview();
      final verdict = _previewVerdict(preview);
      return GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _BlackHolePainter(
            center: _center,
            horizon: _horizon,
            isco: _isco,
            escapeR: _escapeR,
            stars: _stars,
            fx: _fx,
            pops: _pops,
            preview: preview,
            verdict: verdict,
            dragStart: _dragStart,
            launchVector: _isDragging ? _launchVector() : null,
            t: _t,
            kickFlash: _kickFlash,
            swallowFlash: _swallowFlash,
          ),
          child: Stack(children: [
            // Top HUD — star population vs cap + swallowed count. Score/timer
            // are the host's.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _cap,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: i < _aliveCount
                                ? Potatuhs.gold
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    if (_swallowed > 0)
                      Text(
                        'fed $_swallowed',
                        style: TextStyle(
                          fontFamily: Potatuhs.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kAccretionViolet.withValues(alpha: 0.85),
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom hint banner.
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _aliveCount == 0
                        ? 'FLING A STAR INTO ORBIT'
                        : 'CLOSE = FAST = RISKY',
                    style: const TextStyle(
                      fontFamily: Potatuhs.displayFont,
                      fontSize: 12,
                      color: Potatuhs.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// Accretion palette — the disk runs hot (inner) → violet (exotic outer haze).
const Color _kAccretionHot = Color(0xFFE16416); // brand orange, Doppler-bright
const Color _kAccretionGold = Color(0xFFE1C916);
const Color _kAccretionViolet = Color(0xFF8B5CF6);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL components the
// player meets in play (the same event-horizon + accretion-disk + star-orb
// rendering the live painter uses), never abstract diagrams. Static + cheap.
// ═══════════════════════════════════════════════════════════════════════════

/// The black hole itself: tilted accretion disk, lensing halo, pure-black void
/// and the bright gold photon ring — a static twin of [_BlackHolePainter]'s
/// `_paintAccretionDisk` + `_paintEventHorizon`.
void _legendHole(Canvas canvas, Offset c, double horizon) {
  final isco = horizon * _kIscoFactor;
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1.0, 0.42); // foreshorten → disk tilt
  final outer = isco * 3.4;
  for (int i = 0; i < 5; i++) {
    final rr = horizon * 1.2 + (outer - horizon) * (i / 5.0);
    final hot = i / 4.0;
    final col = Color.lerp(_kAccretionViolet, _kAccretionHot, hot)!;
    canvas.drawCircle(
      Offset.zero,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (10 - i * 1.4).clamp(2.0, 10.0)
        ..color = col.withValues(alpha: 0.11 + 0.11 * hot)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
  canvas.drawCircle(
    Offset.zero,
    horizon * 1.45,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = _kAccretionGold.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.restore();
  // Lensing shadow halo.
  canvas.drawCircle(
    c,
    horizon + 16,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
  );
  // The void — pure black disk.
  canvas.drawCircle(c, horizon, Paint()..color = Colors.black);
  // Photon ring.
  canvas.drawCircle(
    c,
    horizon + 1.5,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kAccretionGold.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
  );
}

/// A star orb — same [GameFx.orb] call the game uses; [closeness] 0..1 drives
/// gold → Doppler-white (tighter = hotter).
void _legendStar(Canvas canvas, Offset p, double closeness) {
  final col = Color.lerp(Potatuhs.gold, Colors.white, closeness.clamp(0.0, 1.0))!;
  GameFx.orb(canvas, p, _kStarRadius + 1, col,
      glow: 1.6 + closeness, rim: Colors.white, specular: true);
}

/// A faint orbit ring guide.
void _legendOrbit(Canvas canvas, Offset c, double r, Color color, double alpha) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: alpha),
  );
}

/// A decaying spiral polyline (the star's trail bleeding inward), drawn in the
/// game's airForce+white trail style.
void _legendSpiral(
    Canvas canvas, Offset c, double rStart, double rEnd, double turns) {
  final path = Path();
  const steps = 64;
  for (int i = 0; i <= steps; i++) {
    final f = i / steps;
    final r = rStart + (rEnd - rStart) * f;
    final ang = -pi / 2 + turns * 2 * pi * f;
    final p = Offset(c.dx + cos(ang) * r, c.dy + sin(ang) * r);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Potatuhs.airForce.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.6),
  );
}

/// A bold aim arrow — the fling gesture, mirroring `_paintAim`.
void _legendArrow(Canvas canvas, Offset from, Offset to, Color color) {
  final d = to - from;
  final len = d.distance;
  if (len < 0.5) return;
  final dir = d / len;
  final p = Paint()
    ..color = color.withValues(alpha: 0.95)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  // Birth marker at the origin of the drag.
  canvas.drawCircle(
    from,
    8,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: 0.8),
  );
  canvas.drawLine(from, to, p);
  final perp = Offset(-dir.dy, dir.dx);
  canvas.drawLine(to, to - dir * 11 + perp * 7, p);
  canvas.drawLine(to, to - dir * 11 - perp * 7, p);
}

// ── Frame 1: the core object + the fling verb ───────────────────────────────
void _legendFling(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 4 || h < 4) return;
  final c = Offset(w * 0.5, h * 0.52);
  final horizon = (min(w, h) * 0.12).clamp(14.0, 34.0);
  final orbitR = horizon * 3.0;
  _legendOrbit(canvas, c, orbitR, Potatuhs.airForce, 0.28);
  _legendHole(canvas, c, horizon);
  // Trajectory preview curving into the orbit ring.
  for (int i = 0; i < 18; i++) {
    final f = i / 18.0;
    final ang = pi * 0.75 + f * pi * 0.9;
    final rr = orbitR * (1.35 - 0.35 * f);
    canvas.drawCircle(
      Offset(c.dx + cos(ang) * rr, c.dy + sin(ang) * rr),
      (2.6 - f * 1.6).clamp(0.8, 2.6),
      Paint()..color = Potatuhs.gold.withValues(alpha: (1 - f) * 0.6),
    );
  }
  // The star, riding the orbit.
  _legendStar(canvas, Offset(c.dx + orbitR, c.dy - 2), 0.4);
  // Fling gesture: birth marker + aim arrow from open space.
  final birth = Offset(c.dx - orbitR * 1.15, c.dy + orbitR * 0.65);
  _legendArrow(canvas, birth, birth + Offset(orbitR * 0.5, -orbitR * 0.55),
      Potatuhs.gold);
}

// ── Frame 2: how to score — tighter orbits pay more ─────────────────────────
void _legendScore(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 4 || h < 4) return;
  final c = Offset(w * 0.5, h * 0.54);
  final horizon = (min(w, h) * 0.12).clamp(14.0, 34.0);
  final tightR = horizon * 2.0;
  final wideR = horizon * 3.6;
  _legendOrbit(canvas, c, wideR, Potatuhs.airForce, 0.22);
  _legendOrbit(canvas, c, tightR, _kAccretionGold, 0.4);
  _legendHole(canvas, c, horizon);
  // Cool, distant star: dim gold, low payout.
  _legendStar(canvas, Offset(c.dx - wideR, c.dy), 0.05);
  GameFx.text(canvas, '+8', Offset(c.dx - wideR, c.dy - 20), 12,
      Potatuhs.gold.withValues(alpha: 0.8),
      display: true);
  // Tight, hot star: Doppler-white, big payout.
  _legendStar(canvas, Offset(c.dx + tightR, c.dy), 0.95);
  GameFx.text(canvas, '+60', Offset(c.dx + tightR + 4, c.dy - 22), 15,
      Potatuhs.gold,
      display: true, glow: 0.5);
}

// ── Frame 3: the danger — swallowed or escaped, both lose the star ──────────
void _legendDanger(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 4 || h < 4) return;
  final c = Offset(w * 0.5, h * 0.52);
  final horizon = (min(w, h) * 0.12).clamp(14.0, 34.0);
  final escapeR = min(w, h) * 0.46;
  // Faint escape boundary.
  canvas.drawCircle(
    c,
    escapeR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.14),
  );
  _legendHole(canvas, c, horizon);
  // Left: a star spiralling past the horizon — swallowed.
  _legendSpiral(canvas, c, horizon * 3.4, horizon + 3, 1.15);
  _legendStar(canvas, Offset(c.dx - horizon * 3.4, c.dy - 6), 0.2);
  GameFx.text(canvas, 'SWALLOWED', Offset(c.dx - horizon * 2.4, c.dy + horizon * 3.2),
      10, _kAccretionViolet, display: true);
  // Right: a star flung clear of the field — escaped.
  final esc = Offset(c.dx + escapeR * 0.86, c.dy - escapeR * 0.34);
  _legendStar(canvas, esc, 0.3);
  _legendArrow(canvas, Offset(c.dx + horizon * 2.2, c.dy - horizon * 0.8), esc,
      Potatuhs.airForce);
  GameFx.text(canvas, 'ESCAPES', Offset(esc.dx - 6, esc.dy - 16), 10,
      Potatuhs.airForce, display: true);
}

// ── Frame 4: late-game escalation — the gravitational kick ──────────────────
void _legendKick(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 4 || h < 4) return;
  final c = Offset(w * 0.5, h * 0.52);
  final horizon = (min(w, h) * 0.12).clamp(14.0, 34.0);
  final orbitR = horizon * 3.0;
  // Violet whip-flash wash.
  canvas.drawRect(Offset.zero & size,
      Paint()..color = _kAccretionViolet.withValues(alpha: 0.10));
  _legendOrbit(canvas, c, orbitR, Potatuhs.airForce, 0.22);
  _legendHole(canvas, c, horizon);
  final star = Offset(c.dx + orbitR * 0.72, c.dy - orbitR * 0.6);
  _legendStar(canvas, star, 0.6);
  // Jolt arrows kicking the star off its path in several directions.
  const dirs = [
    Offset(0.9, -0.5),
    Offset(-0.3, -1.0),
    Offset(1.0, 0.3),
  ];
  for (final d in dirs) {
    final len = d.distance;
    final u = d / len;
    _legendArrow(canvas, star + u * 12, star + u * 30, _kAccretionViolet);
  }
}

/// The visual manual for Black-Hole Heart — wired into the registry spec.
final List<LegendFrame> blackHoleLegendFrames = [
  const LegendFrame(
      caption: 'Drag to fling a star into orbit around the hole',
      paint: _legendFling),
  const LegendFrame(
      caption: 'Ride tight orbits: closer = faster = more points',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Too slow is swallowed, too fast escapes — both lost',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Gravitational kicks jolt every orbit — re-manage fast',
      paint: _legendKick),
];

// ── Painter ─────────────────────────────────────────────────────────────────
class _BlackHolePainter extends CustomPainter {
  final Offset center;
  final double horizon;
  final double isco;
  final double escapeR;
  final List<_Star> stars;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final List<Offset> preview;
  final String verdict;
  final Offset? dragStart;
  final Offset? launchVector;
  final double t;
  final double kickFlash;
  final double swallowFlash;

  _BlackHolePainter({
    required this.center,
    required this.horizon,
    required this.isco,
    required this.escapeR,
    required this.stars,
    required this.fx,
    required this.pops,
    required this.preview,
    required this.verdict,
    required this.dragStart,
    required this.launchVector,
    required this.t,
    required this.kickFlash,
    required this.swallowFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccretionViolet, t, motes: 60);

    _paintEscapeRing(canvas);
    _paintAccretionDisk(canvas);
    _paintGuideRings(canvas);
    _paintEventHorizon(canvas);

    _paintPreview(canvas);
    _paintAim(canvas);

    for (final s in stars) {
      _paintStar(canvas, s);
    }

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    if (kickFlash > 0) _paintKick(canvas, size);
  }

  void _paintEscapeRing(Canvas canvas) {
    // Faint boundary: beyond this, stars are lost to the field.
    canvas.drawCircle(
      center,
      escapeR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.05),
    );
  }

  void _paintAccretionDisk(Canvas canvas) {
    // A tilted, rotating disk of hot gas spiralling in. Drawn as nested arcs
    // foreshortened on the Y axis so it reads as a disk seen near edge-on.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, 0.42); // foreshorten → disk tilt

    final outer = isco * 3.4;
    final pulse = 0.5 + 0.5 * sin(t * 1.4);
    for (int i = 0; i < 5; i++) {
      final rr = horizon * 1.2 + (outer - horizon) * (i / 5.0);
      final hot = i / 4.0; // inner rings hotter
      final col = Color.lerp(_kAccretionViolet, _kAccretionHot, hot)!;
      canvas.drawCircle(
        Offset.zero,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (10 - i * 1.4).clamp(2.0, 10.0)
          ..color = col.withValues(alpha: (0.10 + 0.10 * hot) * (0.7 + 0.3 * pulse))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // Bright inner glow ring near the horizon (the photon-heated edge).
    canvas.drawCircle(
      Offset.zero,
      horizon * 1.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = _kAccretionGold.withValues(alpha: 0.30 + 0.18 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  void _paintGuideRings(Canvas canvas) {
    // ISCO ring — inside it orbits decay fast (dashed danger ring).
    _dashedCircle(canvas, center, isco,
        _kAccretionGold.withValues(alpha: 0.22), 14, 9);
    // Sweet-spot hint just outside ISCO.
    canvas.drawCircle(
      center,
      isco * 1.35,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Potatuhs.airForce.withValues(alpha: 0.10),
    );
  }

  void _paintEventHorizon(Canvas canvas) {
    // Lensing shadow halo.
    canvas.drawCircle(
      center,
      horizon + 16,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55 + 0.25 * swallowFlash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // The void itself — pure black disk.
    canvas.drawCircle(center, horizon, Paint()..color = Colors.black);
    // Photon ring — bright thin rim at the horizon, flares when feeding.
    canvas.drawCircle(
      center,
      horizon + 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 + 2.0 * swallowFlash
        ..color = Color.lerp(_kAccretionGold, Colors.white, 0.3 + 0.5 * swallowFlash)!
            .withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  void _paintStar(Canvas canvas, _Star s) {
    // Trail in a few alpha bands (old → new), each band ONE polyline path with
    // one blurred stroke — not a blurred draw per segment. Per-segment blur was
    // a Gaussian pass per trail segment per star per frame, the biggest cost
    // in this painter.
    final trail = s.trail;
    const bands = 3;
    final n = trail.length;
    if (n >= 2) {
      for (var b = 0; b < bands; b++) {
        // Overlap each band by one point so the polyline stays connected.
        final start = max(0, n * b ~/ bands - 1);
        final end = n * (b + 1) ~/ bands;
        if (end - start < 2) continue;
        final path = Path()..moveTo(trail[start].dx, trail[start].dy);
        for (var i = start + 1; i < end; i++) {
          path.lineTo(trail[i].dx, trail[i].dy);
        }
        final frac = (b + 1) / bands;
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Potatuhs.airForce.withValues(alpha: 0.34 * frac)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(alpha: 0.7 * frac)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    if (!s.alive) return;
    // Closer + faster → hotter/whiter (Doppler-bright); far → cooler gold.
    final r = (Offset(s.x, s.y) - center).distance;
    final close = ((_kClosenessRef / r).clamp(_kClosenessMin, _kClosenessMax) -
            _kClosenessMin) /
        (_kClosenessMax - _kClosenessMin);
    final col = Color.lerp(Potatuhs.gold, Colors.white, close.clamp(0.0, 1.0))!;
    GameFx.orb(canvas, Offset(s.x, s.y), _kStarRadius, col,
        glow: 1.6 + close, rim: Colors.white, specular: true);
  }

  void _paintPreview(Canvas canvas) {
    if (preview.isEmpty) return;
    final base = verdict == 'ORBIT'
        ? Potatuhs.gold
        : (verdict == 'SWALLOWED' ? _kAccretionViolet : Potatuhs.airForce);
    for (int i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final alpha = (1.0 - frac) * 0.6;
      final rr = (3.0 - frac * 2.0).clamp(0.6, 3.0);
      canvas.drawCircle(
          preview[i], rr, Paint()..color = base.withValues(alpha: alpha));
    }
  }

  void _paintAim(Canvas canvas) {
    if (dragStart == null || launchVector == null) return;
    final speed = launchVector!.distance;
    final col = verdict == 'ORBIT'
        ? Potatuhs.gold
        : (verdict == 'SWALLOWED' ? _kAccretionViolet : Potatuhs.airForce);
    // Birth marker.
    canvas.drawCircle(
      dragStart!,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = col.withValues(alpha: 0.8),
    );
    if (speed < 0.5) return;
    final dir = launchVector! / speed;
    final tip = dragStart! + dir * (26 + (speed / _kMaxSpeed) * 40);
    final p = Paint()
      ..color = col.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(dragStart!, tip, p);
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawLine(tip, tip - dir * 10 + perp * 6, p);
    canvas.drawLine(tip, tip - dir * 10 - perp * 6, p);
    // Verdict label near the marker.
    if (verdict.isNotEmpty) {
      GameFx.text(canvas, verdict, dragStart!.translate(0, -22), 11, col,
          display: true, glow: 0.5);
    }
  }

  void _paintKick(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kAccretionViolet.withValues(alpha: 0.10 * kickFlash),
    );
    GameFx.text(
      canvas,
      'GRAVITATIONAL KICK',
      Offset(size.width / 2, size.height * 0.22),
      16,
      Colors.white.withValues(alpha: kickFlash),
      display: true,
      glow: 0.8 * kickFlash,
    );
  }

  void _dashedCircle(Canvas canvas, Offset c, double radius, Color color,
      int dashes, double gapDeg) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    final step = 2 * pi / dashes;
    final gap = gapDeg * pi / 180;
    for (int i = 0; i < dashes; i++) {
      final start = i * step + t * 0.15;
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius), start,
          step - gap, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlackHolePainter old) => true;
}
