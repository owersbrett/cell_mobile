import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants — "Constants"  (BioScale.universeAll)
//
// VERB: TUNE-THE-DIALS. The player adjusts the universe's fundamental
// constants — gravity strength G, the strong force, the cosmological constant
// Λ, the electron/proton mass ratio μ — each on a dial with a narrow
// "habitable" band. Keep them all in band and a universe that forms stars,
// atoms and chemistry stays life-permitting. Drift constantly nudges the dials
// out of band; periodic shocks knock one far and must be stabilised. As the
// round runs, more dials unlock, bands narrow and drift speeds up.
//
// SELF-CONTAINED MODULE. Imports only the framework session, fx.dart, theme
// (via fx) and Flutter — per lib/games/EXTRACTION_RECIPE.md. One Ticker drives
// one CustomPainter; no per-frame setState over a large widget tree.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (all tunable here) ──────────────────────────────────────

/// Fraction of the play area given to the live universe preview (top).
const double _kPreviewFrac = 0.46;

/// Points awarded per second the universe stays life-permitting.
const double _kPointsPerSec = 14.0;

/// Bonus for stabilising a shocked dial back into its band.
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

// ── Palette ────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF8B7CF6); // cosmic violet
const Color _kGreen = Color(0xFF4ED6A8);
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
  bool challenged; // currently shocked, awaiting stabilisation
  double shock; // red flash 1 → 0

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
        challenged = false,
        shock = 0;

  bool inBand(double half) => (value - bandCenter).abs() <= half;
}

/// A precomputed star in the universe preview (deterministic; animated by t).
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
  final top = size.height * _kPreviewFrac;
  final areaH = size.height - top;
  final rowH = areaH / n;
  const inset = 22.0;
  final rects = <Rect>[];
  for (var i = 0; i < n; i++) {
    final cy = top + rowH * i + rowH * 0.66;
    rects.add(Rect.fromLTRB(inset, cy - 7, size.width - inset, cy + 7));
  }
  return rects;
}

class ConstantsGame extends StatefulWidget {
  final MiniGameSession session;
  const ConstantsGame({super.key, required this.session});

  @override
  State<ConstantsGame> createState() => _ConstantsGameState();
}

class _ConstantsGameState extends State<ConstantsGame>
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
  int _challengesSolved = 0;
  bool _alive = false;
  String _diag = 'TUNE THE CONSTANTS';

  // Challenge cadence.
  double _challengeTimer = 5.0;

  // Drag state.
  int _draggingIndex = -1; // index within the ACTIVE dial list

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

  double get _halfWidth {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    return _kHalfWidthStart + (_kHalfWidthEnd - _kHalfWidthStart) * p;
  }

  double get _driftSpeed {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    return _kDriftStart + (_kDriftEnd - _kDriftStart) * p;
  }

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
    _challengesSolved = 0;
    _challengeTimer = 5.0;
    _draggingIndex = -1;
    _particles.clear();
    _pops.clear();
    for (final d in _dials) {
      d.value = d.bandCenter;
      d.active = d.idx < 2;
      d.challenged = false;
      d.shock = 0;
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

      // Apply drift to every active dial the player is not currently holding.
      for (var i = 0; i < active.length; i++) {
        final d = active[i];
        if (i == _draggingIndex) continue;
        d.flipTimer -= dt;
        if (d.flipTimer <= 0) {
          d.flipTimer = 1.5 + _rng.nextDouble() * 2.5;
          if (_rng.nextDouble() < 0.5) d.driftDir = -d.driftDir;
        }
        d.value = (d.value + d.driftDir * drift * dt).clamp(0.0, 1.0);
        if (d.value <= 0.0 || d.value >= 1.0) d.driftDir = -d.driftDir;
      }

      // Challenge shocks.
      _challengeTimer -= dt;
      if (_challengeTimer <= 0) {
        _spawnChallenge(active, half);
        final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
        _challengeTimer = (5.5 - 2.2 * p) + _rng.nextDouble() * 2.0;
      }

      // Resolve any shocked dial that is back in band.
      for (final d in active) {
        if (d.challenged && d.inBand(half)) {
          d.challenged = false;
          _challengesSolved++;
          widget.session.addScore(_kStabilizeBonus);
          _pops.add(FxPop(_knobCenter(d), 'STABILISED +$_kStabilizeBonus',
              _kGreen));
          _particles.addAll(
              FxBurst.spawn(_knobCenter(d), d.color, count: 14, speed: 150));
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

    // Decay flashes; step juice.
    for (final d in _dials) {
      d.shock = math.max(0.0, d.shock - dt * 2.4);
    }
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _checkUnlocks() {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    _maybeUnlock(2, p >= _kUnlock3);
    _maybeUnlock(3, p >= _kUnlock4);
  }

  void _maybeUnlock(int idx, bool cond) {
    final d = _dials[idx];
    if (d.active || !cond) return;
    d.active = true;
    d.value = d.bandCenter;
    d.driftDir = _rng.nextBool() ? 1 : -1;
    d.flipTimer = 1.5 + _rng.nextDouble() * 2.0;
    d.shock = 0.9;
    _pops.add(FxPop(Offset(_lastSize.width / 2, _lastSize.height * 0.40),
        '${d.symbol} ONLINE', d.color));
  }

  void _spawnChallenge(List<_Dial> active, double half) {
    if (active.isEmpty) return;
    // Prefer an un-challenged dial.
    final pool = active.where((d) => !d.challenged).toList();
    if (pool.isEmpty) return;
    final d = pool[_rng.nextInt(pool.length)];
    final dir = d.value >= d.bandCenter ? -1.0 : 1.0; // push toward far side
    final mag = half + 0.18 + _rng.nextDouble() * 0.14;
    d.value = (d.bandCenter + dir * mag).clamp(0.0, 1.0);
    d.challenged = true;
    d.shock = 1.0;
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

  Size _lastSize = const Size(360, 640);

  Offset _knobCenter(_Dial d) {
    final active = _dials.where((x) => x.active).toList();
    final i = active.indexOf(d);
    if (i < 0) return Offset(_lastSize.width / 2, _lastSize.height / 2);
    final rects = _trackRects(active.length, _lastSize);
    final r = rects[i];
    return Offset(r.left + r.width * d.value, r.center.dy);
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void _pickAndSet(Offset local) {
    if (!widget.session.isRunning) return;
    final size = _lastSize;
    final top = size.height * _kPreviewFrac;
    if (local.dy < top) return; // preview area — not a dial
    final active = _dials.where((d) => d.active).toList();
    if (active.isEmpty) return;
    final rowH = (size.height - top) / active.length;
    var i = ((local.dy - top) / rowH).floor().clamp(0, active.length - 1);
    _draggingIndex = i;
    final rects = _trackRects(active.length, size);
    final r = rects[i];
    final tt = ((local.dx - r.left) / r.width).clamp(0.0, 1.0);
    active[i].value = tt;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
      final active = _dials.where((d) => d.active).toList();
      final rects = _trackRects(active.length, _lastSize);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _pickAndSet(d.localPosition),
        onTapUp: (_) => _draggingIndex = -1,
        onPanStart: (d) => _pickAndSet(d.localPosition),
        onPanUpdate: (d) => _pickAndSet(d.localPosition),
        onPanEnd: (_) => _draggingIndex = -1,
        child: ClipRect(
          child: CustomPaint(
            painter: _ConstantsPainter(
              t: _t,
              dials: _dials,
              active: active,
              rects: rects,
              half: _halfWidth,
              alive: _alive,
              diag: _diag,
              streak: _streak,
              solved: _challengesSolved,
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

class _ConstantsPainter extends CustomPainter {
  final double t;
  final List<_Dial> dials; // all four (preview reads inactive as neutral)
  final List<_Dial> active;
  final List<Rect> rects;
  final double half;
  final bool alive;
  final String diag;
  final int streak;
  final int solved;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final bool running;

  _ConstantsPainter({
    required this.t,
    required this.dials,
    required this.active,
    required this.rects,
    required this.half,
    required this.alive,
    required this.diag,
    required this.streak,
    required this.solved,
    required this.particles,
    required this.pops,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 26);

    _paintPreview(canvas, size);

    for (var i = 0; i < active.length; i++) {
      _paintDial(canvas, active[i], rects[i]);
    }

    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  // ── Universe preview ───────────────────────────────────────────────────────

  void _paintPreview(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final previewH = size.height * _kPreviewFrac;
    final center = Offset(cx, previewH * 0.50);
    final pr = math.min(size.width, previewH) * 0.40;

    // Derive preview modifiers from the (live) constants.
    final g = _signed(0);
    final l = _signed(2);
    final sHealth = _health(1);
    final cHealth = _health(3);
    final hViz = _habitability();

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
    final starBase = Color.lerp(const Color(0xFFFFF3D0),
        const Color(0xFF9FB4FF), 0.4)!;
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
      canvas.drawCircle(pos, rad, Paint()..color = starColor.withValues(alpha: a));
    }

    // Warm life-core when thriving.
    if (hViz > 0.65) {
      GameFx.orb(canvas, center, 7 + 5 * (hViz - 0.65) / 0.35, _kGreen,
          glow: hViz);
    }

    // Diagnostic banner.
    final banner = alive ? _kGreen : (running ? _kRed : _kAccent);
    final by = previewH - 30;
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
    GameFx.text(canvas, diag, Offset(cx, by), 12, banner, weight: FontWeight.w800);

    // HUD: stability streak (top-right) and shocks stabilised (top-left).
    if (streak > 0) {
      GameFx.text(canvas, '$streak s STABLE', Offset(size.width - 64, 18), 11,
          _kGreen, weight: FontWeight.w800, glow: 0.5);
    }
    if (solved > 0) {
      GameFx.text(canvas, 'STABILISED $solved', Offset(70, 18), 11, _kAccent,
          weight: FontWeight.w800, glow: 0.4);
    }
  }

  // Signed distance of dial [idx] from its band centre (0 if inactive/centred).
  double _signed(int idx) {
    final d = dials[idx];
    if (!d.active) return 0.0;
    return d.value - d.bandCenter;
  }

  // 1 in band, fading to 0 outside, for dial [idx].
  double _health(int idx) {
    final d = dials[idx];
    if (!d.active) return 1.0;
    final over = math.max(0.0, (d.value - d.bandCenter).abs() - half);
    return (1.0 - over / 0.22).clamp(0.0, 1.0);
  }

  double _habitability() {
    var h = 1.0;
    for (final d in active) {
      h *= _health(d.idx);
    }
    return h;
  }

  // ── Dial row ────────────────────────────────────────────────────────────────

  void _paintDial(Canvas canvas, _Dial d, Rect track) {
    final inBand = d.inBand(half);
    final tint = d.challenged
        ? _kRed
        : (inBand ? _kGreen : d.color);

    // Label above the track.
    final labelY = track.top - 16;
    GameFx.text(canvas, '${d.symbol}  ${d.name}',
        Offset(track.left + 64, labelY), 12, tint, weight: FontWeight.w800);

    // Track.
    final rr = RRect.fromRectAndRadius(track, Radius.circular(track.height / 2));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF15131F));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = d.color.withValues(alpha: 0.30),
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
      Offset(ctrX, track.top - 2),
      Offset(ctrX, track.bottom + 2),
      Paint()
        ..color = _kGreen.withValues(alpha: 0.55)
        ..strokeWidth = 1.4,
    );

    // Knob.
    final knob = Offset(track.left + track.width * d.value, track.center.dy);
    if (d.shock > 0) {
      canvas.drawCircle(
        knob,
        13 + 10 * d.shock,
        Paint()
          ..color = _kRed.withValues(alpha: 0.5 * d.shock)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    GameFx.orb(canvas, knob, 11, tint, glow: inBand ? 1.0 : 0.6);
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
  bool shouldRepaint(covariant _ConstantsPainter old) => true;
}
