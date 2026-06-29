import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants v2 — "Constants"  (BioScale.universeAll)
//
// UX-passed alternative to `constants`. SAME lesson — the fine-tuning of the
// physical constants: gravity G, the strong force S, the cosmological constant
// Λ and the electron/proton mass ratio μ each sit on a dial with a narrow
// habitable band, and the live cosmos preview shows reality failing in a
// specific, named way when any one drifts out. SAME depth (juggle up to four
// independently drifting dials, one hand) and SAME accelerating climax (bands
// narrow, drift speeds, surges quicken). It is a REFINEMENT, not a rebuild.
//
// What v2 fixes (per docs/ux_pass/teardowns/constants.md):
//  1. INPUT = MENTAL MODEL. v1's `_pickAndSet` snapped a dial to wherever you
//     touched the row, so a tap TELEPORTED the knob and a sloppy vertical drag
//     hijacked a neighbouring dial. v2 grabs the knob of the row you start in,
//     LOCKS that dial for the whole gesture, and uses a RELATIVE drag (the knob
//     tracks your finger 1:1 from where it was) — no teleport jump, no
//     cross-row hijack. Precise corrections under pressure feel earned.
//  2. SURGES TELEGRAPHED, NOT PUNISHING. v1's shocks fired instantly at a random
//     dial. v2 charges a surge first — a growing warning ring + a chevron in the
//     push direction on the target dial — so you can pre-position and CATCH it.
//     Luck becomes anticipation; a caught surge is a STABILISE bonus.
//  3. SPECTATOR LEGIBILITY. A big full-width UNIVERSE HEALTH meter headlines the
//     screen (green→amber→red, with a live %), so a pass-and-play crowd can read
//     "the universe is dying / thriving" from across the room and root for or
//     against the tuner — not just watch one person fiddle.
//
// SELF-CONTAINED MODULE. Imports only the framework session, fx.dart, theme
// (via fx) and Flutter. One Ticker drives one CustomPainter; no per-frame
// setState over a large widget tree.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (all tunable here) ──────────────────────────────────────

/// Fraction of the play area given to the health meter + cosmos preview (top).
const double _kTopFrac = 0.46;

/// Points awarded per second the universe stays life-permitting.
const double _kPointsPerSec = 14.0;

/// Bonus for catching a surged dial back into its band.
const int _kStabilizeBonus = 60;

/// Band half-width at the start of the round and at the end (it narrows).
const double _kHalfWidthStart = 0.135;
const double _kHalfWidthEnd = 0.060;

/// Dial drift speed (value/sec) at the start and the end of the round.
const double _kDriftStart = 0.050;
const double _kDriftEnd = 0.120;

/// Progress fractions at which dials 3 and 4 unlock.
const double _kUnlock3 = 0.30;
const double _kUnlock4 = 0.62;

/// Seconds between surges at the start / end of the round (it quickens).
const double _kSurgeGapStart = 6.5;
const double _kSurgeGapEnd = 3.2;

/// How long a surge telegraphs (charges) before it fires — your warning window.
/// Shrinks toward the climax so late surges demand faster hands.
const double _kChargeStart = 1.6;
const double _kChargeEnd = 0.85;

/// The last fraction of the round is the CLIMAX crunch.
const double _kClimaxFrom = 0.80;

// ── Palette ────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF8B7CF6); // cosmic violet
const Color _kGreen = Color(0xFF4ED6A8);
const Color _kAmber = Color(0xFFFFC857);
const Color _kRed = Color(0xFFFF5A5A);
const Color _kInk = Color(0xFF07060F);

/// One fundamental constant the player tunes.
class _Dial {
  final int idx;
  final String symbol;
  final String name;
  final Color color;
  final double bandCenter;

  double value;
  int driftDir; // +1 / -1
  double flipTimer; // seconds until drift may flip direction
  bool active;

  // Surge state (telegraphed shock).
  double charge; // 1 → 0 while a surge charges on this dial; 0 = none pending
  double chargeDur; // the full charge duration for the pending surge
  int surgeDir; // +1 / -1 — the direction the surge will push
  bool challenged; // a fired surge currently knocked this dial out of band
  double shock; // red flash 1 → 0 when a surge fires
  double caught; // green flash 1 → 0 when a surge is caught

  _Dial({
    required this.idx,
    required this.symbol,
    required this.name,
    required this.color,
    required this.bandCenter,
    required this.active,
  })  : value = bandCenter,
        driftDir = 1,
        flipTimer = 0,
        charge = 0,
        chargeDur = 1,
        surgeDir = 1,
        challenged = false,
        shock = 0,
        caught = 0;

  bool inBand(double half) => (value - bandCenter).abs() <= half;
}

/// A precomputed star in the cosmos preview (deterministic; animated by t).
class _Star {
  final double angle;
  final double radius; // 0..1 of preview radius
  final double speed;
  final double tw; // twinkle phase
  const _Star(this.angle, this.radius, this.speed, this.tw);
}

/// Shared track-rect layout — used by BOTH the gesture handler and the painter
/// so they always agree on where each dial sits.
List<Rect> _trackRects(int n, Size size) {
  if (n <= 0) return const [];
  final top = size.height * _kTopFrac;
  final areaH = size.height - top;
  final rowH = areaH / n;
  const inset = 24.0;
  final rects = <Rect>[];
  for (var i = 0; i < n; i++) {
    final cy = top + rowH * i + rowH * 0.60;
    rects.add(Rect.fromLTRB(inset, cy - 8, size.width - inset, cy + 8));
  }
  return rects;
}

class ConstantsV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ConstantsV2Game({super.key, required this.session});

  @override
  State<ConstantsV2Game> createState() => _ConstantsV2GameState();
}

class _ConstantsV2GameState extends State<ConstantsV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  double _t = 0.0; // global visual clock
  double _elapsed = 0.0; // play-time accumulator
  bool _wasRunning = false;

  // Scoring / streak.
  double _dripAcc = 0.0;
  double _aliveAcc = 0.0;
  int _streak = 0;
  int _caughtCount = 0;
  bool _alive = false;
  double _health = 1.0; // smoothed habitability, for the meter (0..1)
  String _diag = 'TUNE THE CONSTANTS';

  // Surge cadence.
  double _surgeTimer = _kSurgeGapStart;

  // Drag state — relative drag, locked to the grabbed dial for the gesture.
  _Dial? _drag;
  double _grabX = 0.0; // finger x at grab
  double _grabValue = 0.0; // dial value at grab
  double _grabTrackW = 1.0; // width of the grabbed dial's track

  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  late final List<_Dial> _dials = [
    _Dial(
        idx: 0,
        symbol: 'G',
        name: 'GRAVITY',
        color: const Color(0xFF7C9CFF),
        bandCenter: 0.50,
        active: true),
    _Dial(
        idx: 1,
        symbol: 'S',
        name: 'STRONG FORCE',
        color: const Color(0xFFFF8A5B),
        bandCenter: 0.46,
        active: true),
    _Dial(
        idx: 2,
        symbol: 'Λ',
        name: 'COSMOLOGICAL Λ',
        color: _kAccent,
        bandCenter: 0.55,
        active: false),
    _Dial(
        idx: 3,
        symbol: 'μ',
        name: 'MASS RATIO',
        color: _kGreen,
        bandCenter: 0.50,
        active: false),
  ];

  double get _durSecs =>
      widget.session.spec.durationSeconds.clamp(1, 600).toDouble();

  double get _progress => (_elapsed / _durSecs).clamp(0.0, 1.0);

  double get _halfWidth =>
      _kHalfWidthStart + (_kHalfWidthEnd - _kHalfWidthStart) * _progress;

  double get _driftSpeed =>
      _kDriftStart + (_kDriftEnd - _kDriftStart) * _progress;

  bool get _climax => _progress >= _kClimaxFrom;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initRun() {
    _elapsed = 0.0;
    _dripAcc = 0.0;
    _aliveAcc = 0.0;
    _streak = 0;
    _caughtCount = 0;
    _health = 1.0;
    _surgeTimer = _kSurgeGapStart;
    _drag = null;
    _particles.clear();
    _pops.clear();
    for (final d in _dials) {
      d.value = d.bandCenter;
      d.active = d.idx < 2;
      d.charge = 0;
      d.challenged = false;
      d.shock = 0;
      d.caught = 0;
      d.driftDir = _rng.nextBool() ? 1 : -1;
      d.flipTimer = 1.5 + _rng.nextDouble() * 2.0;
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _t += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _initRun();
    _wasRunning = running;

    final active = _dials.where((d) => d.active).toList();

    if (running) {
      _elapsed += dt;
      _checkUnlocks();

      final half = _halfWidth;
      final drift = _driftSpeed;

      // Drift every active dial the player is not currently holding.
      for (final d in active) {
        if (identical(d, _drag)) continue;
        d.flipTimer -= dt;
        if (d.flipTimer <= 0) {
          d.flipTimer = 1.5 + _rng.nextDouble() * 2.5;
          if (_rng.nextDouble() < 0.5) d.driftDir = -d.driftDir;
        }
        d.value = (d.value + d.driftDir * drift * dt).clamp(0.0, 1.0);
        if (d.value <= 0.0 || d.value >= 1.0) d.driftDir = -d.driftDir;
      }

      _stepSurges(active, half, dt);

      // Resolve any challenged dial that is back in band → caught.
      for (final d in active) {
        if (d.challenged && d.inBand(half)) {
          d.challenged = false;
          d.caught = 1.0;
          _caughtCount++;
          widget.session.addScore(_kStabilizeBonus);
          _pops.add(FxPop(_knobCenter(d), 'CAUGHT +$_kStabilizeBonus', _kGreen));
          _particles
              .addAll(FxBurst.spawn(_knobCenter(d), _kGreen, count: 16, speed: 165));
        }
      }

      // Habitability evaluation.
      _alive = active.every((d) => d.inBand(half));
      _diag = _diagnose(active, half);

      if (_alive) {
        _dripAcc += _kPointsPerSec * dt;
        final whole = _dripAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _dripAcc -= whole;
        }
        _aliveAcc += dt;
        while (_aliveAcc >= 1.0) {
          _aliveAcc -= 1.0;
          _streak++;
          widget.session.noteStreak(_streak);
        }
      } else {
        _aliveAcc = 0.0;
        _streak = 0;
        _dripAcc = 0.0;
      }
    } else {
      // Calm ready state: evaluate against current values so the preview reads.
      final half = _halfWidth;
      _alive = active.isNotEmpty && active.every((d) => d.inBand(half));
      _diag = _wasRunning ? 'ROUND COMPLETE' : 'TUNE THE CONSTANTS';
    }

    // Smoothly chase habitability for the health meter (legible, not jittery).
    final target = _habitability(active, _halfWidth);
    _health += (target - _health) * (1 - math.pow(0.0008, dt)).toDouble();

    // Decay flashes; step juice.
    for (final d in _dials) {
      d.shock = math.max(0.0, d.shock - dt * 2.4);
      d.caught = math.max(0.0, d.caught - dt * 2.0);
    }
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _checkUnlocks() {
    _maybeUnlock(2, _progress >= _kUnlock3);
    _maybeUnlock(3, _progress >= _kUnlock4);
  }

  void _maybeUnlock(int idx, bool cond) {
    final d = _dials[idx];
    if (d.active || !cond) return;
    d.active = true;
    d.value = d.bandCenter;
    d.driftDir = _rng.nextBool() ? 1 : -1;
    d.flipTimer = 1.5 + _rng.nextDouble() * 2.0;
    d.caught = 0.9;
    _pops.add(FxPop(Offset(_lastSize.width / 2, _lastSize.height * 0.40),
        '${d.symbol} ONLINE', d.color));
  }

  // ── Surges: telegraph (charge) → fire → can be caught ──────────────────────
  void _stepSurges(List<_Dial> active, double half, double dt) {
    // Advance any charging surge; fire it when the charge completes.
    for (final d in active) {
      if (d.charge > 0) {
        d.charge = math.max(0.0, d.charge - dt / d.chargeDur);
        if (d.charge <= 0) {
          // Fire: push the dial out of band in the telegraphed direction. If the
          // player pre-positioned toward the opposite side, it lands closer in.
          final mag = half + 0.16 + _rng.nextDouble() * 0.12;
          d.value = (d.value + d.surgeDir * mag).clamp(0.0, 1.0);
          d.challenged = true;
          d.shock = 1.0;
        }
      }
    }

    // Spawn a new surge on cadence (only if nothing is charging).
    _surgeTimer -= dt;
    if (_surgeTimer <= 0) {
      final gap = _kSurgeGapStart +
          (_kSurgeGapEnd - _kSurgeGapStart) * _progress;
      _surgeTimer = gap + _rng.nextDouble() * 1.6;
      final pool =
          active.where((d) => d.charge <= 0 && !d.challenged).toList();
      if (pool.isNotEmpty) {
        final d = pool[_rng.nextInt(pool.length)];
        d.chargeDur =
            _kChargeStart + (_kChargeEnd - _kChargeStart) * _progress;
        d.charge = 1.0;
        // Push toward the far side of the band (most disruptive, most readable).
        d.surgeDir = d.value >= d.bandCenter ? 1 : -1;
      }
    }
  }

  String _diagnose(List<_Dial> active, double half) {
    for (final d in active) {
      if (d.inBand(half)) continue;
      final high = d.value > d.bandCenter;
      switch (d.idx) {
        case 0:
          return high
              ? 'GRAVITY TOO STRONG — STARS COLLAPSE'
              : 'GRAVITY TOO WEAK — NO GALAXIES';
        case 1:
          return high
              ? 'STRONG FORCE TOO HIGH — NO HYDROGEN'
              : 'STRONG FORCE OFF — NO NUCLEI';
        case 2:
          return high
              ? 'Λ TOO HIGH — COSMOS RIPS APART'
              : 'Λ TOO LOW — INSTANT RECOLLAPSE';
        default:
          return high
              ? 'MASS RATIO OFF — NO STABLE ATOMS'
              : 'MASS RATIO OFF — NO CHEMISTRY';
      }
    }
    return 'LIFE-PERMITTING';
  }

  double _habitability(List<_Dial> active, double half) {
    if (active.isEmpty) return 1.0;
    var h = 1.0;
    for (final d in active) {
      final over = math.max(0.0, (d.value - d.bandCenter).abs() - half);
      h *= (1.0 - over / 0.22).clamp(0.0, 1.0);
    }
    return h;
  }

  Size _lastSize = const Size(360, 640);

  Offset _knobCenter(_Dial d) {
    final active = _dials.where((x) => x.active).toList();
    final i = active.indexOf(d);
    if (i < 0) return Offset(_lastSize.width / 2, _lastSize.height / 2);
    final rects = _trackRects(active.length, _lastSize);
    final r = rects[i];
    return Offset(r.left + r.width * d.value, r.center.dy);
  }

  // ── Input: grab the row's knob, lock it, drag RELATIVE (no teleport) ────────

  void _grab(Offset local) {
    if (!widget.session.isRunning) return;
    final size = _lastSize;
    final top = size.height * _kTopFrac;
    if (local.dy < top) {
      _drag = null;
      return; // preview area — not a dial
    }
    final active = _dials.where((d) => d.active).toList();
    if (active.isEmpty) return;
    final rects = _trackRects(active.length, size);
    final rowH = (size.height - top) / active.length;
    final i = ((local.dy - top) / rowH).floor().clamp(0, active.length - 1);
    // Lock to this dial for the whole gesture. Relative drag: the knob keeps its
    // current value and moves 1:1 with the finger from here — no jump-to-finger.
    _drag = active[i];
    _grabValue = _drag!.value;
    _grabX = local.dx;
    _grabTrackW = rects[i].width;
  }

  void _dragTo(Offset local) {
    final d = _drag;
    if (d == null || !widget.session.isRunning) return;
    if (_grabTrackW <= 0) return;
    final delta = (local.dx - _grabX) / _grabTrackW;
    d.value = (_grabValue + delta).clamp(0.0, 1.0);
  }

  void _release() {
    _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
      final active = _dials.where((d) => d.active).toList();
      final rects = _trackRects(active.length, _lastSize);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _grab(d.localPosition),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onPanStart: (d) => _grab(d.localPosition),
        onPanUpdate: (d) => _dragTo(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: ClipRect(
          child: CustomPaint(
            painter: _ConstantsV2Painter(
              t: _t,
              dials: _dials,
              active: active,
              rects: rects,
              half: _halfWidth,
              alive: _alive,
              health: _health.clamp(0.0, 1.0),
              diag: _diag,
              streak: _streak,
              caught: _caughtCount,
              climax: _climax && widget.session.isRunning,
              grabbed: _drag,
              particles: _particles,
              pops: _pops,
              running: widget.session.isRunning,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _ConstantsV2Painter extends CustomPainter {
  final double t;
  final List<_Dial> dials; // all four (preview reads inactive as neutral)
  final List<_Dial> active;
  final List<Rect> rects;
  final double half;
  final bool alive;
  final double health;
  final String diag;
  final int streak;
  final int caught;
  final bool climax;
  final _Dial? grabbed;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final bool running;

  _ConstantsV2Painter({
    required this.t,
    required this.dials,
    required this.active,
    required this.rects,
    required this.half,
    required this.alive,
    required this.health,
    required this.diag,
    required this.streak,
    required this.caught,
    required this.climax,
    required this.grabbed,
    required this.particles,
    required this.pops,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 26);

    _paintHealthMeter(canvas, size);
    _paintPreview(canvas, size);

    for (var i = 0; i < active.length; i++) {
      _paintDial(canvas, active[i], rects[i]);
    }

    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  // Health meter color: red → amber → green by habitability.
  Color get _healthColor => health < 0.5
      ? Color.lerp(_kRed, _kAmber, (health / 0.5).clamp(0.0, 1.0))!
      : Color.lerp(_kAmber, _kGreen, ((health - 0.5) / 0.5).clamp(0.0, 1.0))!;

  // ── Universe health meter (the spectator headline) ─────────────────────────
  void _paintHealthMeter(Canvas canvas, Size size) {
    const inset = 24.0;
    final top = 16.0;
    final h = 30.0;
    final rect = Rect.fromLTWH(inset, top, size.width - inset * 2, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    final col = _healthColor;

    // Track.
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF15131F));
    // Fill.
    final fillW = (rect.width * health).clamp(0.0, rect.width);
    if (fillW > 2) {
      final fillRect = Rect.fromLTWH(rect.left, rect.top, fillW, rect.height);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            colors: [col.withValues(alpha: 0.55), col],
          ).createShader(fillRect),
      );
      // Moving energy shimmer along the fill.
      final sx = rect.left + (t * 60) % (fillW + 40) - 20;
      canvas.drawRect(
        Rect.fromLTWH(sx, rect.top, 18, rect.height),
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
      canvas.restore();
    }
    // Border (pulses in the climax).
    final pulse = climax ? 0.6 + 0.4 * math.sin(t * 9) : 1.0;
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = col.withValues(alpha: 0.75 * pulse),
    );

    // Label + live percentage (big, readable from across the room).
    GameFx.text(canvas, 'UNIVERSE', Offset(rect.left + 52, rect.center.dy), 12,
        Colors.white.withValues(alpha: 0.92),
        weight: FontWeight.w800);
    final pct = '${(health * 100).round()}%';
    GameFx.text(canvas, pct, Offset(rect.right - 34, rect.center.dy), 15, col,
        weight: FontWeight.w900, glow: 0.6);
  }

  // ── Cosmos preview ─────────────────────────────────────────────────────────
  void _paintPreview(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topFrac = size.height * _kTopFrac;
    final center = Offset(cx, 56 + (topFrac - 56) * 0.46);
    final pr = math.min(size.width, topFrac) * 0.32;

    final g = _signed(0);
    final l = _signed(2);
    final sHealth = _health(1);
    final cHealth = _health(3);
    final hViz = health;

    final gHigh = math.max(0.0, g);
    final gLow = math.max(0.0, -g);
    final lHigh = math.max(0.0, l);
    final lLow = math.max(0.0, -l);

    var orbitScale = 1.0 / (1 + gHigh * 3.0); // collapse when gravity high
    orbitScale += gLow * 2.0; // disperse when gravity low
    orbitScale += lHigh * 1.6; // Λ high pushes outward
    orbitScale *= 1.0 / (1 + lLow * 2.0); // Λ low recollapses
    orbitScale = orbitScale.clamp(0.05, 2.6);

    final brightness = (0.30 + 0.70 * sHealth) * (0.40 + 0.60 * hViz);

    // Background life-glow grows with habitability.
    canvas.drawCircle(
      center,
      pr * (1.4 + 0.4 * hViz),
      Paint()
        ..shader = RadialGradient(colors: [
          (alive ? _kGreen : _kAccent).withValues(alpha: 0.10 + 0.18 * hViz),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: center, radius: pr * (1.4 + 0.4 * hViz))),
    );

    // Collapse singularity when gravity is far too strong.
    if (gHigh > 0.18) {
      canvas.drawCircle(
        center,
        6 + 16 * gHigh.clamp(0.0, 1.0),
        Paint()
          ..color = _kRed.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Stars.
    final starBase =
        Color.lerp(const Color(0xFFFFF3D0), const Color(0xFF9FB4FF), 0.4)!;
    final starColor =
        cHealth > 0.55 ? starBase : Color.lerp(starBase, _kRed, 0.7)!;
    for (final s in _starsRef) {
      final ang = s.angle + t * s.speed * (0.2 + 0.8 * hViz);
      final r = (s.radius * orbitScale) * pr;
      if (r > pr * 2.4) continue; // dispersed off-stage
      final pos = center + Offset(math.cos(ang), math.sin(ang)) * r;
      final twk = 0.6 + 0.4 * math.sin(t * 2.2 + s.tw);
      final a = (brightness * twk).clamp(0.0, 1.0);
      final rad = 1.4 + 2.0 * brightness;
      canvas.drawCircle(
        pos,
        rad + 2,
        Paint()
          ..color = starColor.withValues(alpha: 0.30 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
          pos, rad, Paint()..color = starColor.withValues(alpha: a));
    }

    // Warm life-core when thriving.
    if (hViz > 0.65) {
      GameFx.orb(canvas, center, 7 + 5 * (hViz - 0.65) / 0.35, _kGreen,
          glow: hViz);
    }

    // Diagnostic banner (the lesson named in plain language).
    final banner = alive ? _kGreen : (running ? _kRed : _kAccent);
    final by = topFrac - 26;
    final chipW = (diag.length * 7.6 + 28).clamp(120.0, size.width - 28);
    final chip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, by), width: chipW, height: 26),
      const Radius.circular(13),
    );
    canvas.drawRRect(chip, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
      chip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = banner.withValues(alpha: 0.7),
    );
    GameFx.text(canvas, diag, Offset(cx, by), 12.5, banner,
        weight: FontWeight.w800);

    // HUD: stability streak (right) and surges caught (left).
    if (streak > 0) {
      GameFx.text(canvas, '$streak s STABLE', Offset(size.width - 64, 60), 11,
          _kGreen,
          weight: FontWeight.w800, glow: 0.5);
    }
    if (caught > 0) {
      GameFx.text(canvas, 'CAUGHT $caught', Offset(64, 60), 11, _kGreen,
          weight: FontWeight.w800, glow: 0.4);
    }
  }

  double _signed(int idx) {
    final d = dials[idx];
    if (!d.active) return 0.0;
    return d.value - d.bandCenter;
  }

  double _health(int idx) {
    final d = dials[idx];
    if (!d.active) return 1.0;
    final over = math.max(0.0, (d.value - d.bandCenter).abs() - half);
    return (1.0 - over / 0.22).clamp(0.0, 1.0);
  }

  // ── Dial row ────────────────────────────────────────────────────────────────
  void _paintDial(Canvas canvas, _Dial d, Rect track) {
    final inBand = d.inBand(half);
    final isGrabbed = identical(d, grabbed);
    final tint = d.challenged ? _kRed : (inBand ? _kGreen : d.color);

    // Label above the track.
    final labelY = track.top - 17;
    GameFx.text(canvas, '${d.symbol}  ${d.name}',
        Offset(track.left + 70, labelY), 12.5, tint,
        weight: FontWeight.w800);

    // Track.
    final rr = RRect.fromRectAndRadius(track, Radius.circular(track.height / 2));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF15131F));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isGrabbed ? 2.0 : 1.1
        ..color = d.color.withValues(alpha: isGrabbed ? 0.7 : 0.30),
    );

    // Habitable band.
    final bandLeft = track.left + track.width * (d.bandCenter - half);
    final bandRight = track.left + track.width * (d.bandCenter + half);
    final bandRect = Rect.fromLTRB(
        bandLeft.clamp(track.left, track.right),
        track.top,
        bandRight.clamp(track.left, track.right),
        track.bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(track.height / 2)),
      Paint()..color = _kGreen.withValues(alpha: 0.22),
    );
    // Band centre tick.
    final ctrX = track.left + track.width * d.bandCenter;
    canvas.drawLine(
      Offset(ctrX, track.top - 3),
      Offset(ctrX, track.bottom + 3),
      Paint()
        ..color = _kGreen.withValues(alpha: 0.55)
        ..strokeWidth = 1.4,
    );

    final knob = Offset(track.left + track.width * d.value, track.center.dy);

    // Telegraphed surge: warning ring + chevron pointing the push direction.
    if (d.charge > 0) {
      final ph = 1.0 - d.charge; // 0 → 1 as it charges
      final ringR = 14 + 16 * (0.5 + 0.5 * math.sin(t * 12));
      canvas.drawCircle(
        knob,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + 2.0 * ph
          ..color = _kAmber.withValues(alpha: 0.30 + 0.5 * ph),
      );
      _paintChevron(canvas, knob, d.surgeDir, _kAmber.withValues(alpha: 0.85));
    }

    // Surge fired: red shock flash.
    if (d.shock > 0) {
      canvas.drawCircle(
        knob,
        14 + 12 * d.shock,
        Paint()
          ..color = _kRed.withValues(alpha: 0.5 * d.shock)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    // Caught: green ring pop.
    if (d.caught > 0) {
      canvas.drawCircle(
        knob,
        14 + 18 * (1 - d.caught),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * d.caught
          ..color = _kGreen.withValues(alpha: d.caught),
      );
    }

    // Knob — bigger when grabbed for clear feedback.
    GameFx.orb(canvas, knob, isGrabbed ? 14 : 12, tint,
        glow: inBand ? 1.0 : 0.6);
  }

  void _paintChevron(Canvas canvas, Offset knob, int dir, Color color) {
    final x = knob.dx + dir * 22;
    final p = Path()
      ..moveTo(x - dir * 5, knob.dy - 6)
      ..lineTo(x + dir * 5, knob.dy)
      ..lineTo(x - dir * 5, knob.dy + 6);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  // A stable, deterministic star field for the preview (seeded so it is
  // identical every frame; animated only by [t]).
  List<_Star> get _starsRef {
    if (_cachedStars != null) return _cachedStars!;
    final rng = math.Random(7);
    _cachedStars = List.generate(34, (i) {
      return _Star(
        rng.nextDouble() * 2 * math.pi,
        0.18 + rng.nextDouble() * 0.82,
        (0.25 + rng.nextDouble() * 0.7) * (rng.nextBool() ? 1 : -1),
        rng.nextDouble() * 2 * math.pi,
      );
    });
    return _cachedStars!;
  }

  static List<_Star>? _cachedStars;

  @override
  bool shouldRepaint(covariant _ConstantsV2Painter old) => true;
}
