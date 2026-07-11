import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ===========================================================================
// Solar Storm — manage space weather from an active Sun (solarSystems scale).
//
// CONTRACT: SolarStormGame(session: session). The MiniGameHost owns the clock,
// countdown, score HUD and results; this widget only simulates the Sun, reports
// points via session.addScore / session.noteStreak, and gates all play on
// session.isRunning. Renders nothing but the play area.
//
// RENDERING: the whole scene (roiling Sun, sunspots, flares/CMEs, defense belt,
// FX) is ONE Ticker → ONE CustomPainter. No per-entity widgets, capped particle
// and threat counts, one reused blur Paint. The score, timer and results are
// host chrome.
//
// MECHANIC: sunspots bubble up on the Sun's surface and BUILD toward eruption —
// TAP one to quell it (early = more points). A sunspot left to mature ERUPTS,
// launching a coronal mass ejection toward Earth's satellite belt. Bright solar
// FLARES also fire directly. TAP an incoming flare / CME to raise shields and
// deflect it — catching it early (high up) scores a clean-defense bonus. A storm
// that reaches the belt undefended damages the satellites / power grid (lose
// points). A solar-cycle intensity ramps over the round toward "solar maximum":
// more sunspots, faster storms, simultaneous threats.
// ===========================================================================

// ── feel constants ─────────────────────────────────────────────────────────

// Sunspots (TAP to quell before they erupt)
const double _kSpotSpawnBase = 2.2; // secs between sunspots at cycle start
const double _kSpotSpawnMin = 0.75; // …at solar maximum
const double _kSpotGrowthBase = 0.17; // intensity/sec at cycle start
const double _kSpotGrowthMax = 0.42; // …at solar maximum
const int _kSpotMaxAlive = 7;
const int _kSpotQuellBase = 10; // base points for quelling
const int _kSpotEarlyBonus = 12; // ×(1-intensity): early quell scores more
const int _kSpotEruptPenalty = -6; // missed spot erupts

// Storms — flares (fast EM burst) and CMEs (slow plasma cloud)
const double _kCmeSpeedBase = 0.34; // progress/sec sun→belt at cycle start
const double _kCmeSpeedMax = 0.60; // …at solar maximum
const double _kFlareSpeedBase = 0.72; // flares travel much faster
const double _kFlareSpeedMax = 1.20;
const int _kStormMaxAlive = 6;
const int _kCmeDeflect = 20; // base points, deflecting a CME
const int _kFlareDeflect = 28; // flares score more (smaller window)
const int _kDeflectEarlyBonus = 22; // ×(1-progress): catch it high = bonus
const int _kCmeHit = -18; // CME reaches belt undefended
const int _kFlareHit = -12;
const double _kCmeGridDamage = 16; // grid integrity lost on a CME hit
const double _kFlareGridDamage = 11;

// Direct flares (fire straight off the Sun, no sunspot) — late-cycle pressure
const double _kFlareSpawnBase = 7.5; // rare early
const double _kFlareSpawnMin = 2.6; // common near maximum

// Power grid / satellite belt
const double _kGridMax = 100.0;
const double _kGridRegen = 3.2; // integrity/sec self-repair

// Combo / juice
const int _kComboStep = 5; // every N-streak raises the multiplier
const int _kComboMax = 4;
const double _kShakeDecay = 4.5;
const double _kPopupLife = 0.85;
const int _kParticleCap = 130;

// ── palette (brand-aligned, solar) ─────────────────────────────────────────
const Color _kSpace = Color(0xFF070510);
const Color _kSpaceMid = Color(0xFF160C1E);
const Color _kSunCore = Color(0xFFFFF6D0);
const Color _kSunMid = Potatuhs.gold; // 0xFFE1C916
const Color _kSunEdge = Potatuhs.orange; // 0xFFE16416
const Color _kCorona = Color(0xFFFFB24D);
const Color _kSpotDark = Color(0xFF2A1606);
const Color _kSpotRim = Color(0xFFFFC247);
const Color _kFlare = Color(0xFFFFF0A0);
const Color _kCme = Color(0xFFFF6A3D);
const Color _kShield = Color(0xFF5BC8F0);
const Color _kGridGood = Color(0xFF6BD08A);
const Color _kEarth = Color(0xFF3E84D6);
const Color _kDanger = Color(0xFFE53935);
const Color _kText = Potatuhs.textPrimary;

// ── data classes ───────────────────────────────────────────────────────────

class _Sunspot {
  double ang; // angle on the disk
  double dist; // 0..1 from sun centre (kept on the visible face)
  double intensity; // 0..1 — builds toward eruption
  final double growth; // intensity/sec
  final double seed;
  bool quelled = false;
  double quellAge = 0;
  _Sunspot(this.ang, this.dist, this.growth, this.seed) : intensity = 0;
}

class _Storm {
  final Offset origin; // screen pos at the Sun
  final Offset target; // screen pos at the defense belt
  final double speed; // progress/sec
  final bool isFlare;
  final double radius;
  final double seed;
  double progress = 0; // 0 at Sun, 1 at belt
  bool deflected = false;
  double deflectAge = 0;
  _Storm(this.origin, this.target, this.speed, this.isFlare, this.radius,
      this.seed);

  Offset get pos => Offset.lerp(origin, target, progress)!;
}

class _Popup {
  double x, y;
  final String text;
  final Color color;
  final double scale;
  double age = 0;
  _Popup(this.x, this.y, this.text, this.color, this.scale);
}

class _Granule {
  final double ang, dist, r, speed, bright;
  _Granule(this.ang, this.dist, this.r, this.speed, this.bright);
}

class _Star {
  final double x, y, r, phase;
  _Star(this.x, this.y, this.r, this.phase);
}

// ── widget ──────────────────────────────────────────────────────────────────

class SolarStormGame extends StatefulWidget {
  final MiniGameSession session;
  const SolarStormGame({super.key, required this.session});

  @override
  State<SolarStormGame> createState() => _SolarStormGameState();
}

class _SolarStormGameState extends State<SolarStormGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  double _t = 0; // decorative clock (always advances)
  bool _running = false;

  // Round state
  double _elapsed = 0;
  double _cycle = 0; // 0..1 solar-minimum → solar-maximum
  double _grid = _kGridMax;
  int _streak = 0;
  double _shake = 0;
  double _redFlash = 0; // grid-damage screen flash

  // Comprehension: an in-context HOW-TO hint that fades once the player acts.
  bool _actedThisRun = false; // player has quelled/deflected at least once
  double _hintAlpha = 1.0; // 1 → visible, eases to 0 after first action / grace

  // Threats
  final List<_Sunspot> _spots = [];
  final List<_Storm> _storms = [];
  double _spotTimer = 0;
  double _flareTimer = 0;

  // FX
  final List<FxParticle> _particles = [];
  final List<_Popup> _popups = [];

  // Decoration
  final List<_Granule> _granules = [];
  final List<_Star> _stars = [];

  int get _mult => (1 + _streak ~/ _kComboStep).clamp(1, _kComboMax);

  double get _round {
    final d = widget.session.spec.durationSeconds.toDouble();
    return d > 1 ? d : 60.0;
  }

  // ── geometry ───────────────────────────────────────────────────────────
  Offset get _sunCenter => Offset(_size.width * 0.5, _size.height * 0.27);
  double get _sunR =>
      math.min(_size.width * 0.36, _size.height * 0.24).clamp(1.0, 9999.0);
  double get _beltY => _size.height * 0.84;

  Offset _spotPos(_Sunspot s) =>
      _sunCenter +
      Offset(math.cos(s.ang), math.sin(s.ang)) * (s.dist * _sunR * 0.82);

  // ── lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 9; i++) {
      _granules.add(_Granule(
        _rng.nextDouble() * math.pi * 2,
        0.15 + _rng.nextDouble() * 0.7,
        0.16 + _rng.nextDouble() * 0.18,
        0.3 + _rng.nextDouble() * 0.6,
        _rng.nextDouble(),
      ));
    }
    for (var i = 0; i < 48; i++) {
      _stars.add(_Star(
        _rng.nextDouble(),
        _rng.nextDouble(),
        0.5 + _rng.nextDouble() * 1.4,
        _rng.nextDouble() * math.pi * 2,
      ));
    }
    // A couple of calm, never-erupting spots so the "ready" Sun has texture.
    _seedIdleSpots();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  void _seedIdleSpots() {
    _spots.clear();
    for (var i = 0; i < 2; i++) {
      final s = _Sunspot(_rng.nextDouble() * math.pi * 2,
          0.25 + _rng.nextDouble() * 0.4, 0, _rng.nextDouble());
      s.intensity = 0.2 + _rng.nextDouble() * 0.18;
      _spots.add(s);
    }
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Reads the live threat board and
  /// fires the single most competent move — no randomness, no synthetic taps,
  /// reusing the game's own [_deflect] / [_quell] handlers.
  ///
  /// Priority = highest damage risk first: a moving storm (flare / CME) nearest
  /// the satellite belt (max [_Storm.progress]) is the imminent grid hit, so it
  /// is deflected first. With no storm in flight, the sunspot nearest eruption
  /// (max [_Sunspot.intensity]) is quelled before it can launch a CME. Ties
  /// resolve to the first match; deterministic. Does nothing if the sky is clear
  /// or the round is not running.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // 1) Most urgent moving storm — the one closest to the belt.
    _Storm? storm;
    for (final st in _storms) {
      if (st.deflected) continue;
      if (storm == null || st.progress > storm.progress) storm = st;
    }
    if (storm != null) {
      _deflect(storm);
      return;
    }

    // 2) No storms → quell the sunspot nearest eruption, stopping the next CME.
    _Sunspot? spot;
    for (final s in _spots) {
      if (s.quelled) continue;
      if (spot == null || s.intensity > spot.intensity) spot = s;
    }
    if (spot != null) _quell(spot);
  }

  void _resetRun() {
    _elapsed = 0;
    _cycle = 0;
    _grid = _kGridMax;
    _streak = 0;
    _shake = 0;
    _redFlash = 0;
    _spots.clear();
    _storms.clear();
    _particles.clear();
    _popups.clear();
    _spotTimer = _kSpotSpawnBase * 0.5;
    _flareTimer = _kFlareSpawnBase;
    _actedThisRun = false;
    _hintAlpha = 1.0;
  }

  // ── game loop ──────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _t += dt;

    final running = widget.session.isRunning;
    if (running && !_running) _resetRun();
    if (!running && _running) _seedIdleSpots();
    _running = running;

    _shake = math.max(0, _shake - dt * _kShakeDecay);
    _redFlash = math.max(0, _redFlash - dt * 2.2);
    _stepParticles(dt);
    _stepPopups(dt);

    if (running && _size != Size.zero) {
      _elapsed += dt;
      // HOW-TO hint: hold while the player hasn't acted and we're still early;
      // once they act (or after a ~6s grace) ease it out so it never obscures.
      final holdHint = !_actedThisRun && _elapsed < 6.0;
      _hintAlpha = holdHint
          ? math.min(1.0, _hintAlpha + dt * 4)
          : math.max(0.0, _hintAlpha - dt * 1.6);
      _cycle = (_elapsed / _round).clamp(0.0, 1.0);
      _grid = (_grid + _kGridRegen * dt).clamp(0.0, _kGridMax);
      _stepSunspots(dt);
      _stepStorms(dt);
      _spawnSunspots(dt);
      _spawnFlares(dt);
    }

    if (mounted) setState(() {});
  }

  double _lerpCycle(double a, double b) => a + (b - a) * _cycle;

  void _stepSunspots(double dt) {
    for (var i = _spots.length - 1; i >= 0; i--) {
      final s = _spots[i];
      if (s.quelled) {
        s.quellAge += dt;
        if (s.quellAge > 0.4) _spots.removeAt(i);
        continue;
      }
      s.intensity += s.growth * dt;
      if (s.intensity >= 1.0) {
        // Erupt → launch a CME from this spot.
        _spawnStorm(_spotPos(s), isFlare: false);
        widget.session.addScore(_kSpotEruptPenalty);
        _streak = 0;
        _shake = math.max(_shake, 0.5);
        _spawnPopup(_spotPos(s).dx, _spotPos(s).dy, 'ERUPTION', _kCme, 1.0);
        _spots.removeAt(i);
      }
    }
  }

  void _stepStorms(double dt) {
    for (var i = _storms.length - 1; i >= 0; i--) {
      final st = _storms[i];
      if (st.deflected) {
        st.deflectAge += dt;
        if (st.deflectAge > 0.45) _storms.removeAt(i);
        continue;
      }
      st.progress += st.speed * dt;
      if (st.progress >= 1.0) {
        // Reached the belt undefended → grid damage.
        widget.session.addScore(st.isFlare ? _kFlareHit : _kCmeHit);
        _grid = (_grid - (st.isFlare ? _kFlareGridDamage : _kCmeGridDamage))
            .clamp(0.0, _kGridMax);
        _streak = 0;
        _shake = 1.0;
        _redFlash = 0.8;
        _spawnPopup(st.target.dx, _beltY - 26,
            st.isFlare ? '$_kFlareHit' : '$_kCmeHit', _kDanger, 1.1);
        _spawnParticles(Offset(st.target.dx, _beltY), _kDanger, count: 14);
        _storms.removeAt(i);
      }
    }
  }

  // ── spawning ───────────────────────────────────────────────────────────
  void _spawnSunspots(double dt) {
    _spotTimer -= dt;
    if (_spotTimer > 0) return;
    _spotTimer = _lerpCycle(_kSpotSpawnBase, _kSpotSpawnMin) +
        _rng.nextDouble() * 0.4;
    if (_spots.where((s) => !s.quelled).length >= _kSpotMaxAlive) return;
    _spots.add(_Sunspot(
      _rng.nextDouble() * math.pi * 2,
      0.12 + _rng.nextDouble() * 0.68,
      _lerpCycle(_kSpotGrowthBase, _kSpotGrowthMax) *
          (0.85 + _rng.nextDouble() * 0.3),
      _rng.nextDouble(),
    ));
  }

  void _spawnFlares(double dt) {
    _flareTimer -= dt;
    if (_flareTimer > 0) return;
    _flareTimer =
        _lerpCycle(_kFlareSpawnBase, _kFlareSpawnMin) + _rng.nextDouble() * 1.2;
    if (_elapsed < 4) return; // grace at the start
    if (_storms.where((s) => !s.deflected).length >= _kStormMaxAlive) return;
    final ang = _rng.nextDouble() * math.pi * 2;
    final origin = _sunCenter +
        Offset(math.cos(ang), math.sin(ang)) * (_sunR * 0.78);
    _spawnStorm(origin, isFlare: true);
  }

  void _spawnStorm(Offset origin, {required bool isFlare}) {
    if (_storms.where((s) => !s.deflected).length >= _kStormMaxAlive) return;
    final targetX = _size.width * (0.12 + _rng.nextDouble() * 0.76);
    final speed = isFlare
        ? _lerpCycle(_kFlareSpeedBase, _kFlareSpeedMax)
        : _lerpCycle(_kCmeSpeedBase, _kCmeSpeedMax);
    _storms.add(_Storm(
      origin,
      Offset(targetX, _beltY),
      speed * (0.9 + _rng.nextDouble() * 0.2),
      isFlare,
      isFlare ? 12.0 : 20.0,
      _rng.nextDouble(),
    ));
  }

  // ── particles / popups ─────────────────────────────────────────────────
  void _stepParticles(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    if (_particles.length > _kParticleCap) {
      _particles.removeRange(0, _particles.length - _kParticleCap);
    }
  }

  void _stepPopups(double dt) {
    for (var i = _popups.length - 1; i >= 0; i--) {
      _popups[i].age += dt;
      _popups[i].y -= 36 * dt;
      if (_popups[i].age > _kPopupLife) _popups.removeAt(i);
    }
    if (_popups.length > 10) _popups.removeRange(0, _popups.length - 10);
  }

  void _spawnParticles(Offset at, Color color, {int count = 12}) {
    _particles.addAll(FxBurst.spawn(at, color, count: count, speed: 140));
  }

  void _spawnPopup(double x, double y, String text, Color color, double scale) {
    _popups.add(_Popup(x, y, text, color, scale));
  }

  // ── input ──────────────────────────────────────────────────────────────
  void _onTapDown(Offset p) {
    if (!widget.session.isRunning) return;

    // Incoming storms first — they are the urgent, moving threat.
    for (var i = _storms.length - 1; i >= 0; i--) {
      final st = _storms[i];
      if (st.deflected) continue;
      if ((st.pos - p).distance < st.radius + 26) {
        _deflect(st);
        return;
      }
    }
    // Then sunspots on the Sun's face.
    for (var i = _spots.length - 1; i >= 0; i--) {
      final s = _spots[i];
      if (s.quelled) continue;
      if ((_spotPos(s) - p).distance < 34) {
        _quell(s);
        return;
      }
    }
  }

  void _deflect(_Storm st) {
    st.deflected = true;
    st.deflectAge = 0;
    final early = ((1.0 - st.progress) * _kDeflectEarlyBonus).round();
    final pts =
        ((st.isFlare ? _kFlareDeflect : _kCmeDeflect) + early) * _mult;
    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);
    _noteSuccess(st.pos);
    final at = st.pos;
    _spawnPopup(at.dx, at.dy - 14, '+$pts', _kShield, 1.1);
    if (st.progress < 0.35) {
      _spawnPopup(at.dx, at.dy - 34, 'EARLY!', _kSunCore, 0.85);
    }
    _spawnParticles(at, _kShield, count: 14);
  }

  void _quell(_Sunspot s) {
    s.quelled = true;
    s.quellAge = 0;
    final early = ((1.0 - s.intensity) * _kSpotEarlyBonus).round();
    final pts = (_kSpotQuellBase + early) * _mult;
    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);
    _noteSuccess(_spotPos(s));
    final at = _spotPos(s);
    _spawnPopup(at.dx, at.dy - 10, '+$pts', _kSunMid, 1.0);
    if (s.intensity < 0.35) {
      _spawnPopup(at.dx, at.dy - 30, 'EARLY!', _kSunCore, 0.85);
    }
    _spawnParticles(at, _kSpotRim, count: 10);
  }

  /// First successful action of the run flips the hint off and shows a one-time
  /// "NICE!" so the player instantly connects tap → points.
  void _noteSuccess(Offset at) {
    if (!_actedThisRun) {
      _actedThisRun = true;
      _spawnPopup(at.dx, at.dy - 52, 'NICE! CATCH EARLY = MORE', _kSunCore, 0.8);
    }
  }

  // ── build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (e) => _onTapDown(e.localPosition),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _SolarStormPainter(
                t: _t,
                cycle: _cycle,
                grid: _grid / _kGridMax,
                running: _running,
                mult: _mult,
                streak: _streak,
                shake: _shake,
                redFlash: _redFlash,
                hintAlpha: _hintAlpha,
                sunCenter: _sunCenter,
                sunR: _sunR,
                beltY: _beltY,
                spots: _spots,
                spotPositions: [for (final s in _spots) _spotPos(s)],
                storms: _storms,
                particles: _particles,
                popups: _popups,
                granules: _granules,
                stars: _stars,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );
    });
  }
}

// ===========================================================================
// Painter — the whole scene in one pass.
// ===========================================================================

class _SolarStormPainter extends CustomPainter {
  final double t, cycle, grid, shake, redFlash, hintAlpha;
  final bool running;
  final int mult, streak;
  final Offset sunCenter;
  final double sunR, beltY;
  final List<_Sunspot> spots;
  final List<Offset> spotPositions;
  final List<_Storm> storms;
  final List<FxParticle> particles;
  final List<_Popup> popups;
  final List<_Granule> granules;
  final List<_Star> stars;

  _SolarStormPainter({
    required this.t,
    required this.cycle,
    required this.grid,
    required this.running,
    required this.mult,
    required this.streak,
    required this.shake,
    required this.redFlash,
    required this.hintAlpha,
    required this.sunCenter,
    required this.sunR,
    required this.beltY,
    required this.spots,
    required this.spotPositions,
    required this.storms,
    required this.particles,
    required this.popups,
    required this.granules,
    required this.stars,
  });

  final Paint _blur = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (shake > 0) {
      canvas.save();
      canvas.translate(
          math.sin(t * 46) * shake * 7, math.cos(t * 38) * shake * 7);
    }

    _drawSpace(canvas, size);
    _drawCorona(canvas);
    _drawSun(canvas);
    _drawSunspots(canvas);
    _drawStorms(canvas);
    _drawBelt(canvas, size);
    FxBurst.paint(canvas, particles);
    _drawPopups(canvas);
    _drawMeters(canvas, size);
    _drawComboBadge(canvas, size);
    if (running) {
      _drawObjective(canvas, size);
      if (hintAlpha > 0.02) _drawHint(canvas, size);
    }
    if (redFlash > 0.02) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kDanger.withValues(alpha: 0.22 * redFlash));
    }
    if (!running) _drawReadyLabel(canvas, size);

    if (shake > 0) canvas.restore();
  }

  // ── background ─────────────────────────────────────────────────────────
  void _drawSpace(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kSpaceMid, _kSpace, Color(0xFF02040A)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    final star = Paint();
    for (final s in stars) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * 1.6 + s.phase));
      star.color = Colors.white.withValues(alpha: 0.5 * tw);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, star);
    }
  }

  // ── corona ─────────────────────────────────────────────────────────────
  void _drawCorona(Canvas canvas) {
    final pulse = 1.0 + 0.05 * math.sin(t * 1.4);
    final intensity = 0.10 + 0.10 * cycle;
    for (var i = 3; i >= 1; i--) {
      final r = sunR * (1.25 + i * 0.55) * pulse;
      canvas.drawCircle(
        sunCenter,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            _kCorona.withValues(alpha: intensity / i),
            _kCorona.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: sunCenter, radius: r)),
      );
    }
  }

  // ── Sun disk + granulation ─────────────────────────────────────────────
  void _drawSun(Canvas canvas) {
    // Body.
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: const [_kSunCore, _kSunMid, _kSunEdge],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunR)),
    );
    // Granulation — drifting blobs clipped to the disk.
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: sunCenter, radius: sunR)));
    for (final g in granules) {
      final a = g.ang + t * g.speed * 0.4;
      final d = g.dist + 0.06 * math.sin(t * g.speed + g.bright * 6);
      final c = sunCenter +
          Offset(math.cos(a), math.sin(a)) * (d * sunR);
      final bright = g.bright > 0.5;
      _blur.color = (bright ? _kSunCore : _kSunEdge)
          .withValues(alpha: 0.18 + 0.12 * math.sin(t * g.speed * 1.7));
      canvas.drawCircle(c, sunR * g.r, _blur);
    }
    canvas.restore();
    // Limb.
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kSunEdge.withValues(alpha: 0.6),
    );
  }

  // ── sunspots ───────────────────────────────────────────────────────────
  void _drawSunspots(Canvas canvas) {
    for (var i = 0; i < spots.length; i++) {
      final s = spots[i];
      final p = spotPositions[i];
      if (s.quelled) {
        final f = (1 - s.quellAge / 0.4).clamp(0.0, 1.0);
        canvas.drawCircle(p, 14 * (1 - f) + 4,
            Paint()..color = _kSunCore.withValues(alpha: 0.5 * f));
        continue;
      }
      final r = 7.0 + s.intensity * 9.0;
      // TAP reticle — a dashed ring says "this is a target". Green-gold while
      // it's still an early, high-value quell; shifts toward danger as it nears
      // eruption so the player reads urgency without a manual.
      final early = (1.0 - s.intensity).clamp(0.0, 1.0);
      final reticleCol = Color.lerp(_kDanger, _kGridGood, early)!;
      final rPulse = 1 + 0.08 * math.sin(t * 3 + s.seed * 6);
      _tapReticle(canvas, p, (r + 10) * rPulse, reticleCol, 0.55);
      // Dark umbra.
      canvas.drawCircle(p, r, Paint()..color = _kSpotDark);
      canvas.drawCircle(
          p, r * 1.45, Paint()..color = _kSpotDark.withValues(alpha: 0.4));
      // Building rim — brightens & pulses as it nears eruption.
      if (s.intensity > 0.45) {
        final heat = ((s.intensity - 0.45) / 0.55).clamp(0.0, 1.0);
        final pulse = 0.5 + 0.5 * math.sin(t * (6 + 8 * heat));
        canvas.drawCircle(
          p,
          r + 3 + 3 * heat,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + 2 * heat
            ..color = _kSpotRim.withValues(alpha: (0.4 + 0.6 * heat) * pulse),
        );
      }
    }
  }

  // ── storms ─────────────────────────────────────────────────────────────
  void _drawStorms(Canvas canvas) {
    for (final st in storms) {
      final pos = st.pos;
      final col = st.isFlare ? _kFlare : _kCme;
      if (st.deflected) {
        final f = (1 - st.deflectAge / 0.45).clamp(0.0, 1.0);
        // Shield ripple on deflection.
        canvas.drawCircle(
          pos,
          (st.radius + 8) + 40 * (1 - f),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * f
            ..color = _kShield.withValues(alpha: 0.8 * f),
        );
        continue;
      }
      // Warning aim line as it nears the belt.
      if (st.progress > 0.4) {
        final warn = ((st.progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final dash = Paint()
          ..color = _kDanger.withValues(alpha: 0.3 * warn)
          ..strokeWidth = 1.5;
        canvas.drawLine(pos, st.target, dash);
      }
      // Trail back toward the Sun.
      for (var k = 5; k >= 1; k--) {
        final tp = Offset.lerp(pos, st.origin, k / 14)!;
        canvas.drawCircle(
            tp,
            st.radius * (1 - k / 8),
            Paint()..color = col.withValues(alpha: 0.10 * (6 - k)));
      }
      // Glow + core.
      _blur.color = col.withValues(alpha: 0.5);
      canvas.drawCircle(pos, st.radius * 1.5, _blur);
      canvas.drawCircle(pos, st.radius, Paint()..color = col);
      canvas.drawCircle(pos, st.radius * 0.45,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
      // TAP reticle — signals the storm is interactive. Bright green (big early
      // bonus) high up, fading toward red danger as it nears the belt.
      final early = (1.0 - st.progress).clamp(0.0, 1.0);
      final reticleCol = Color.lerp(_kDanger, _kGridGood, early)!;
      final rPulse = 1 + 0.10 * math.sin(t * 4 + st.seed * 6);
      _tapReticle(canvas, pos, (st.radius + 14) * rPulse, reticleCol, 0.65);
    }
  }

  /// A dashed crosshair ring that reads as "tap me". Cheap: 8 arc segments.
  void _tapReticle(Canvas canvas, Offset c, double r, Color color, double a) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: a);
    const seg = 8;
    for (var i = 0; i < seg; i++) {
      final start = (i / seg) * math.pi * 2 + t * 0.6;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start,
          math.pi * 2 / seg * 0.55, false, p);
    }
  }

  // ── defense belt: Earth + satellites + grid bar ─────────────────────────
  void _drawBelt(Canvas canvas, Size size) {
    // Earth glow at the bottom.
    final earthC = Offset(size.width * 0.5, size.height * 1.02);
    final eR = size.width * 0.28;
    canvas.drawCircle(
      earthC,
      eR,
      Paint()
        ..shader = RadialGradient(colors: [
          _kEarth.withValues(alpha: 0.9),
          _kEarth.withValues(alpha: 0.25),
        ]).createShader(Rect.fromCircle(center: earthC, radius: eR)),
    );
    // Satellite belt — a row of small craft just above Earth.
    final hurt = grid < 0.35;
    final satCol = hurt ? _kDanger : _kShield;
    const n = 5;
    final panel = Paint()..color = satCol.withValues(alpha: 0.75);
    final body = Paint()..color = _kText;
    for (var i = 0; i < n; i++) {
      final sx = size.width * ((i + 0.5) / n);
      final bob = math.sin(t * 1.5 + i) * 3;
      final c = Offset(sx, beltY + bob);
      canvas.drawRect(
        Rect.fromCenter(center: c.translate(-9, 0), width: 7, height: 12),
        panel,
      );
      canvas.drawRect(
        Rect.fromCenter(center: c.translate(9, 0), width: 7, height: 12),
        panel,
      );
      canvas.drawCircle(c, 3.5, body);
    }
    // Faint shield arc over the belt.
    final shieldA = 0.10 + 0.12 * grid;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, beltY + 30),
          width: size.width * 1.05,
          height: 130),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (hurt ? _kDanger : _kShield).withValues(alpha: shieldA),
    );
  }

  // ── meters: solar cycle (left) + grid integrity (right) ─────────────────
  void _drawMeters(Canvas canvas, Size size) {
    final top = size.height * 0.34;
    final bot = size.height * 0.74;
    final h = bot - top;
    // Solar cycle — left edge, fills upward, orange→red toward maximum.
    _verticalMeter(
      canvas,
      Offset(14, top),
      h,
      cycle,
      Color.lerp(_kSunMid, _kDanger, cycle)!,
      'SUN',
      cycle > 0.92 ? 'MAX' : null,
    );
    // Grid integrity — right edge, green→red as it depletes.
    _verticalMeter(
      canvas,
      Offset(size.width - 22, top),
      h,
      grid,
      Color.lerp(_kDanger, _kGridGood, grid)!,
      'GRID',
      null,
    );
  }

  void _verticalMeter(Canvas canvas, Offset at, double h, double frac,
      Color color, String label, String? topLabel) {
    const w = 8.0;
    final track =
        RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, w, h),
            const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final fh = h * frac.clamp(0.0, 1.0);
    final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx, at.dy + h - fh, w, fh), const Radius.circular(4));
    canvas.drawRRect(fill, Paint()..color = color.withValues(alpha: 0.9));
    _text(canvas, label, Offset(at.dx + w / 2, at.dy + h + 12), 9,
        _kText.withValues(alpha: 0.7), bold: true);
    if (topLabel != null) {
      _text(canvas, topLabel, Offset(at.dx + w / 2, at.dy - 10), 9,
          _kDanger, bold: true);
    }
  }

  void _drawComboBadge(Canvas canvas, Size size) {
    if (mult <= 1) return;
    _text(canvas, 'x$mult  $streak STREAK',
        Offset(size.width * 0.5, size.height * 0.5), 13,
        _kSunCore.withValues(alpha: 0.85), bold: true);
  }

  // ── popups ─────────────────────────────────────────────────────────────
  void _drawPopups(Canvas canvas) {
    for (final p in popups) {
      final a = (1 - p.age / _kPopupLife).clamp(0.0, 1.0);
      _text(canvas, p.text, Offset(p.x, p.y), 16 * p.scale,
          p.color.withValues(alpha: a),
          bold: true, glow: 0.7 * a);
    }
  }

  // ── always-visible objective + fading how-to hint ────────────────────────
  // The objective TextPainter is built once (static string) and reused every
  // frame — no per-frame layout for the persistent label.
  static final TextPainter _objectiveTp = TextPainter(
    text: const TextSpan(
      text: 'TAP SPOTS & STORMS — CATCH THEM EARLY FOR MORE POINTS',
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _kText,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _drawObjective(Canvas canvas, Size size) {
    final w = _objectiveTp.width + 26;
    final h = _objectiveTp.height + 10;
    final left = (size.width - w) / 2;
    const top = 8.0;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h), const Radius.circular(9));
    canvas.drawRRect(rr, Paint()..color = _kSpace.withValues(alpha: 0.55));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kSunMid.withValues(alpha: 0.35));
    _objectiveTp.paint(
        canvas, Offset(left + 13, top + (h - _objectiveTp.height) / 2));
  }

  void _drawHint(Canvas canvas, Size size) {
    // Sits just under the objective; a bright, unmissable green-gold callout
    // that names both targets and the winning behavior, then eases away.
    final a = hintAlpha.clamp(0.0, 1.0);
    const y = 46.0;
    _text(
        canvas,
        'DARK SPOTS on the Sun · GLOWING STORMS falling toward Earth',
        Offset(size.width * 0.5, y),
        12,
        _kSunCore.withValues(alpha: 0.9 * a),
        bold: true,
        glow: 0.5 * a);
    _text(
        canvas,
        'green ring = tap now for the big bonus · red = about to hit',
        Offset(size.width * 0.5, y + 18),
        10.5,
        _kText.withValues(alpha: 0.75 * a));
  }

  void _drawReadyLabel(Canvas canvas, Size size) {
    _text(canvas, 'SOLAR MINIMUM', Offset(size.width * 0.5, sunCenter.dy),
        13, _kSunCore.withValues(alpha: 0.5), bold: true);
    _text(
        canvas,
        'Tap dark sunspots · tap incoming storms · catch them early',
        Offset(size.width * 0.5, size.height * 0.6),
        12,
        _kText.withValues(alpha: 0.6));
  }

  // ── text helper ────────────────────────────────────────────────────────
  void _text(Canvas canvas, String s, Offset center, double size, Color color,
      {bool bold = false, double glow = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: 0.5,
          color: color,
          shadows: glow > 0
              ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 12)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SolarStormPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards. Each frame draws the LITERAL in-game
// components (Sun, sunspot, flare/CME, satellite belt) in the game's own style
// and palette, statically. Cheap, size-guarded, no per-frame animation.
// ═══════════════════════════════════════════════════════════════════════════

/// The Sun disk (body gradient + limb) centred at [c] with radius [r] —
/// mirrors `_SolarStormPainter._drawSun` without the drifting granulation.
void _legendSun(Canvas canvas, Offset c, double r) {
  if (r <= 0) return;
  // Soft corona halo.
  canvas.drawCircle(
    c,
    r * 1.7,
    Paint()
      ..shader = RadialGradient(colors: [
        _kCorona.withValues(alpha: 0.18),
        _kCorona.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: c, radius: r * 1.7)),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = const RadialGradient(
        colors: [_kSunCore, _kSunMid, _kSunEdge],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kSunEdge.withValues(alpha: 0.6),
  );
}

/// One sunspot at [p]. [intensity] 0..1 sizes the umbra and lights the warning
/// rim just as `_drawSunspots` does at high heat.
void _legendSunspot(Canvas canvas, Offset p, double intensity) {
  final r = 7.0 + intensity * 9.0;
  canvas.drawCircle(p, r, Paint()..color = _kSpotDark);
  canvas.drawCircle(
      p, r * 1.45, Paint()..color = _kSpotDark.withValues(alpha: 0.4));
  if (intensity > 0.45) {
    final heat = ((intensity - 0.45) / 0.55).clamp(0.0, 1.0);
    canvas.drawCircle(
      p,
      r + 3 + 3 * heat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 2 * heat
        ..color = _kSpotRim.withValues(alpha: 0.4 + 0.6 * heat),
    );
  }
}

/// A travelling storm at [pos]: glow + white-hot core with a trail toward
/// [origin]. [isFlare] picks the pale-flare vs orange-CME colour and size.
void _legendStorm(Canvas canvas, Offset pos, Offset origin,
    {required bool isFlare}) {
  final col = isFlare ? _kFlare : _kCme;
  final radius = isFlare ? 12.0 : 20.0;
  for (var k = 5; k >= 1; k--) {
    final tp = Offset.lerp(pos, origin, k / 14)!;
    canvas.drawCircle(tp, radius * (1 - k / 8),
        Paint()..color = col.withValues(alpha: 0.10 * (6 - k)));
  }
  canvas.drawCircle(
      pos,
      radius * 1.5,
      Paint()
        ..color = col.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  canvas.drawCircle(pos, radius, Paint()..color = col);
  canvas.drawCircle(
      pos, radius * 0.45, Paint()..color = Colors.white.withValues(alpha: 0.9));
}

/// The satellite defense belt across [beltY]. [hurt] reddens it (grid damaged).
void _legendBelt(Canvas canvas, Size size, double beltY, {bool hurt = false}) {
  final satCol = hurt ? _kDanger : _kShield;
  const n = 5;
  final panel = Paint()..color = satCol.withValues(alpha: 0.75);
  final body = Paint()..color = _kText;
  for (var i = 0; i < n; i++) {
    final c = Offset(size.width * ((i + 0.5) / n), beltY);
    canvas.drawRect(
        Rect.fromCenter(center: c.translate(-9, 0), width: 7, height: 12),
        panel);
    canvas.drawRect(
        Rect.fromCenter(center: c.translate(9, 0), width: 7, height: 12),
        panel);
    canvas.drawCircle(c, 3.5, body);
  }
  canvas.drawArc(
    Rect.fromCenter(
        center: Offset(size.width * 0.5, beltY + 30),
        width: size.width * 1.05,
        height: 130),
    math.pi,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = satCol.withValues(alpha: hurt ? 0.28 : 0.22),
  );
}

/// A stroked shield ripple at [pos] — the deflect tell.
void _legendShieldRipple(Canvas canvas, Offset pos, double radius) {
  canvas.drawCircle(
    pos,
    radius + 22,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _kShield.withValues(alpha: 0.8),
  );
}

/// A tap cue ring + crosshair at [p].
void _legendTapCue(Canvas canvas, Offset p, double radius) {
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = _kShield.withValues(alpha: 0.85);
  canvas.drawCircle(p, radius, ring);
  final tick = Paint()
    ..color = _kShield.withValues(alpha: 0.85)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(p.translate(-radius - 6, 0), p.translate(-radius, 0), tick);
  canvas.drawLine(p.translate(radius, 0), p.translate(radius + 6, 0), tick);
}

void _legendCaptionMark(
    Canvas canvas, String s, Offset center, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

// ── Frame 1: the core object + verb — tap a maturing sunspot ────────────────
void _legendQuell(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.46);
  final r = math.min(size.width * 0.30, size.height * 0.30).clamp(1.0, 9999.0);
  _legendSun(canvas, c, r);
  final spot = c + Offset(r * 0.28, -r * 0.10);
  _legendSunspot(canvas, spot, 0.9);
  _legendTapCue(canvas, spot, 26);
}

// ── Frame 2: how to score — deflect flares & CMEs high ──────────────────────
void _legendDeflect(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final sun = Offset(size.width * 0.5, size.height * 0.16);
  final sunR = math.min(size.width * 0.18, size.height * 0.16).clamp(1.0, 9999.0);
  _legendSun(canvas, sun, sunR);
  final beltY = size.height * 0.86;
  _legendBelt(canvas, size, beltY);
  // A flare caught high (small, near the Sun) with a shield ripple.
  final flarePos = Offset(size.width * 0.34, size.height * 0.42);
  _legendStorm(canvas, flarePos, sun, isFlare: true);
  _legendShieldRipple(canvas, flarePos, 12);
  _legendTapCue(canvas, flarePos, 24);
  // A slower CME lower down still incoming.
  final cmePos = Offset(size.width * 0.66, size.height * 0.58);
  _legendStorm(canvas, cmePos, sun, isFlare: false);
}

// ── Frame 3: the danger — a storm hits the belt undefended ──────────────────
void _legendHit(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final sun = Offset(size.width * 0.5, size.height * 0.16);
  final sunR = math.min(size.width * 0.18, size.height * 0.16).clamp(1.0, 9999.0);
  _legendSun(canvas, sun, sunR);
  final beltY = size.height * 0.80;
  final hitX = size.width * 0.5;
  // Impact burst at the belt.
  canvas.drawCircle(
      Offset(hitX, beltY),
      34,
      Paint()
        ..color = _kDanger.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  _legendStorm(canvas, Offset(hitX, beltY), sun, isFlare: false);
  _legendBelt(canvas, size, beltY, hurt: true);
  _legendCaptionMark(canvas, '-18', Offset(hitX, beltY - 46), 20, _kDanger);
}

// ── Frame 4: escalation — solar maximum swarms with threats ─────────────────
void _legendMaximum(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.30);
  final r = math.min(size.width * 0.22, size.height * 0.20).clamp(1.0, 9999.0);
  _legendSun(canvas, c, r);
  // Several sunspots at once.
  _legendSunspot(canvas, c + Offset(-r * 0.35, -r * 0.2), 0.85);
  _legendSunspot(canvas, c + Offset(r * 0.42, r * 0.1), 0.6);
  _legendSunspot(canvas, c + Offset(r * 0.05, r * 0.45), 0.95);
  final beltY = size.height * 0.88;
  _legendBelt(canvas, size, beltY);
  // Simultaneous storms.
  _legendStorm(canvas, Offset(size.width * 0.28, size.height * 0.60), c,
      isFlare: true);
  _legendStorm(canvas, Offset(size.width * 0.74, size.height * 0.66), c,
      isFlare: false);
  // "SOLAR MAX" tell in the game's danger colour.
  _legendCaptionMark(
      canvas, 'SOLAR MAX', Offset(size.width * 0.5, size.height * 0.09), 14,
      _kDanger);
}

/// The visual manual for Solar Storm — wired into the registry spec.
final List<LegendFrame> solarStormLegendFrames = [
  const LegendFrame(
      caption: 'Tap a sunspot to quell it before it erupts',
      paint: _legendQuell),
  const LegendFrame(
      caption: 'Tap flares and CMEs early to shield the grid',
      paint: _legendDeflect),
  const LegendFrame(
      caption: 'Let one reach the belt and the grid takes damage',
      paint: _legendHit),
  const LegendFrame(
      caption: 'At solar maximum, threats swarm — keep your streak',
      paint: _legendMaximum),
];
