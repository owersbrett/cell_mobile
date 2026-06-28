import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GalaxyCollectorGame — "Star Collector"  (BioScale.galactic)
//    Stars drift across the galaxy — tap them before they escape!
//    Every star telegraphs its escape path with a ghost trail.
//    Tutorial: the first star is slow with a pulsing TAP ME prompt.
//    Escalation: wave 1 = 1 star, grows to 6+ at wave 4+, timing tightens.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Feel constants ─────────────────────────────────────────────────────────
// Game clock
const double _kGcGameDuration     = 60.0;  // total seconds

// Star sizes (pixel radius)
const double _kGcStarRadiusMin    = 18.0;
const double _kGcStarRadiusMax    = 30.0;  // bigger = easier tap target, smaller = harder

// Star lifetime: how many seconds it crosses the screen before escaping
const double _kGcLifeWave1        = 5.5;   // generous at first
const double _kGcLifeMin          = 2.0;   // floor — never instant

// Spawn interval (seconds between new stars)
const double _kGcSpawnWave1       = 3.0;
const double _kGcSpawnMin         = 0.55;

// Max simultaneous stars per wave
const int    _kGcMaxStarsWave1    = 1;
const int    _kGcMaxStarsCap      = 7;

// Tutorial: first N stars are in tutorial mode (slow + labelled)
const int    _kGcTutorialStars    = 1;

// Tap hitbox multiplier (make tap area generously larger than visual radius)
const double _kGcHitMult          = 1.55;

// Points
const int    _kGcPointsBase       = 10;
const int    _kGcBonusPerWave     = 4;
const int    _kGcComboBonus       = 5;   // extra per star when on combo ≥3
const int    _kGcPenaltyEscape    = -6;  // star escaped the screen

// Wave: new wave every N seconds
const double _kGcWaveDuration     = 15.0;
// ────────────────────────────────────────────────────────────────────────────

class GalaxyCollectorGame extends StatefulWidget {
  final MiniGameSession session;
  const GalaxyCollectorGame({Key? key, required this.session})
      : super(key: key);
  @override
  State<GalaxyCollectorGame> createState() => _GalaxyCollectorGameState();
}

enum _GCPhase { start, playing, gameOver }

// A single drifting star
class _GCStar {
  /// Position in normalised [0,1] coords
  double x, y;
  /// Velocity in normalised coords/sec
  final double vx, vy;
  /// Pixel radius of the orb
  final double radius;
  /// Total life when spawned (seconds)
  final double maxLife;
  /// Remaining life before escape
  double life;
  /// Scale-in animation [0→1]
  double scale;
  /// Flash on collection
  double flashGood;
  /// Whether this star has been collected (pending removal)
  bool collected;
  /// Whether this is a tutorial star (labelled)
  final bool isTutorial;
  /// Colour of this star
  final Color color;
  /// A unique index so the painter can derive a stable bob phase
  final int idx;

  _GCStar({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.maxLife,
    required this.color, required this.isTutorial,
    required this.idx,
  }) : life = maxLife, scale = 0.0, flashGood = 0.0, collected = false;
}

class _GalaxyCollectorGameState extends State<GalaxyCollectorGame>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  final Random _rng = Random();
  // Host owns intro/countdown/results; begin playing immediately.
  _GCPhase _phase = _GCPhase.playing;

  // Gameplay state
  int _score = 0, _wave = 1, _highScore = 0;
  int _combo = 0, _bestCombo = 0;
  double _spawnTimer = 0.0;
  double _waveTimer  = 0.0;
  double _gameTimer  = 0.0;   // total elapsed seconds
  double _flashGood  = 0.0;
  double _flashBad   = 0.0;
  String? _toastText;
  double _toastTimer = 0.0;
  int    _starsSpawned = 0;   // total ever spawned (used for tutorial gate)
  double _clock = 0.0;        // seconds clock for painter animations

  final List<_GCStar>        _stars     = [];
  final List<FxParticle>     _particles = [];
  final List<FxPop>          _pops      = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)..forward();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _highScore = prefs.getInt('galaxy_collector_hs') ?? 0; });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('galaxy_collector_hs', _score);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _startGame() {
    setState(() {
      _phase = _GCPhase.playing;
      _score = 0; _wave = 1; _combo = 0; _bestCombo = 0;
      _spawnTimer = 0.0; _waveTimer = 0.0; _gameTimer = 0.0; _clock = 0.0;
      _flashGood = 0.0; _flashBad = 0.0;
      _toastText = null; _toastTimer = 0.0;
      _starsSpawned = 0;
      _stars.clear(); _particles.clear(); _pops.clear();
    });
  }

  void _endGame() {
    _saveHighScore();
    setState(() { _phase = _GCPhase.gameOver; });
  }

  // ── Per-wave derived values ──────────────────────────────────────────────
  double get _starLife     => (_kGcLifeWave1  - (_wave - 1) * 0.45).clamp(_kGcLifeMin, _kGcLifeWave1);
  double get _spawnInterval => (_kGcSpawnWave1 - (_wave - 1) * 0.38).clamp(_kGcSpawnMin, _kGcSpawnWave1);
  int    get _maxStars     => (_kGcMaxStarsWave1 + (_wave - 1)).clamp(1, _kGcMaxStarsCap);

  // ── Game loop ────────────────────────────────────────────────────────────
  void _tick() {
    // Host owns the clock — only advance during the playing phase.
    if (!widget.session.isRunning) return;
    const dt = 1 / 60.0;
    setState(() {
      _gameTimer += dt;
      _clock += dt;
      _waveTimer += dt;

      // Wave progression every 15s
      if (_waveTimer >= _kGcWaveDuration) {
        _waveTimer = 0.0;
        _wave++;
        _toast('Wave $_wave!');
      }

      // Spawn stars
      _spawnTimer -= dt;
      if (_spawnTimer <= 0.0 && _stars.where((s) => !s.collected).length < _maxStars) {
        _spawnTimer = _spawnInterval * (0.75 + _rng.nextDouble() * 0.5);
        _spawnStar();
      }

      // Update stars
      for (final s in _stars) {
        if (s.collected) {
          s.flashGood = (s.flashGood - dt * 3.0).clamp(0.0, 1.0);
          continue;
        }
        s.scale = (s.scale + dt / 0.30).clamp(0.0, 1.0);
        s.x += s.vx * dt;
        s.y += s.vy * dt;
        s.life -= dt;

        // Escaped?
        if (s.life <= 0.0 || s.x < -0.15 || s.x > 1.15 || s.y < -0.15 || s.y > 1.15) {
          _score = max(0, _score + _kGcPenaltyEscape);
          widget.session.addScore(_kGcPenaltyEscape); // report to host
          _combo = 0;
          _flashBad = 0.55;
          s.collected = true; // mark for removal
          _toast('Escaped!');
        }
      }
      _stars.removeWhere((s) => s.collected && s.flashGood <= 0.01);

      // Particles & pops
      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (_flashGood > 0) _flashGood = (_flashGood - dt * 2.8).clamp(0.0, 1.0);
      if (_flashBad  > 0) _flashBad  = (_flashBad  - dt * 2.8).clamp(0.0, 1.0);
      if (_toastTimer > 0) { _toastTimer -= dt; if (_toastTimer <= 0) _toastText = null; }
    });
  }

  void _spawnStar() {
    // Pick an edge and aim across
    final edge = _rng.nextInt(4);
    double sx, sy, tx, ty;
    switch (edge) {
      case 0: // top
        sx = 0.1 + _rng.nextDouble() * 0.8; sy = -0.06;
        tx = 0.1 + _rng.nextDouble() * 0.8; ty = 1.06;
        break;
      case 1: // right
        sx = 1.06; sy = 0.1 + _rng.nextDouble() * 0.8;
        tx = -0.06; ty = 0.1 + _rng.nextDouble() * 0.8;
        break;
      case 2: // bottom
        sx = 0.1 + _rng.nextDouble() * 0.8; sy = 1.06;
        tx = 0.1 + _rng.nextDouble() * 0.8; ty = -0.06;
        break;
      default: // left
        sx = -0.06; sy = 0.1 + _rng.nextDouble() * 0.8;
        tx = 1.06; ty = 0.1 + _rng.nextDouble() * 0.8;
    }

    final isTut = _starsSpawned < _kGcTutorialStars;
    final life = isTut ? _kGcLifeWave1 * 1.8 : _starLife;

    final dx = tx - sx, dy = ty - sy;
    final dist = sqrt(dx * dx + dy * dy).clamp(0.01, 2.5);
    // Velocity to cross the screen in `life` seconds
    final vx = (dx / dist) * (dist / life);
    final vy = (dy / dist) * (dist / life);

    // Radius: tutorial stars are larger; later waves spawn smaller ones
    final radius = isTut
        ? _kGcStarRadiusMax
        : _kGcStarRadiusMax - (_wave - 1) * 1.2;

    // Colour: cycle through a small palette of warm/cool star colours
    final starColors = [
      Potatuhs.gold,
      Potatuhs.orange,
      Potatuhs.airForce,
      Potatuhs.glaucous,
      Potatuhs.sienna,
      const Color(0xFF88CCEE), // pale blue
      const Color(0xFFFFEE88), // pale yellow
    ];
    final col = starColors[_starsSpawned % starColors.length];

    _stars.add(_GCStar(
      x: sx, y: sy, vx: vx, vy: vy,
      radius: radius.clamp(_kGcStarRadiusMin, _kGcStarRadiusMax),
      maxLife: life, color: col,
      isTutorial: isTut, idx: _starsSpawned,
    ));
    _starsSpawned++;
  }

  // ── Tap handling — collect the topmost star under the tap point ──────────
  void _handleTap(Offset localPos, Size screenSize) {
    final w = screenSize.width, h = screenSize.height;
    final tapX = localPos.dx, tapY = localPos.dy;

    _GCStar? hit;
    double bestDist = double.infinity;

    for (final s in _stars) {
      if (s.collected) continue;
      // Distance in pixel space
      final px = s.x * w, py = s.y * h;
      final d = sqrt((tapX - px) * (tapX - px) + (tapY - py) * (tapY - py));
      if (d < s.radius * _kGcHitMult && d < bestDist) {
        bestDist = d;
        hit = s;
      }
    }

    if (hit == null) return;

    setState(() {
      hit!.collected = true;
      hit.flashGood  = 1.0;
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
      final base    = _kGcPointsBase + _kGcBonusPerWave * _wave;
      final comboEx = _combo >= 3 ? _kGcComboBonus * (_combo - 2) : 0;
      final pts     = base + comboEx;
      _score += pts;
      widget.session.addScore(pts); // report to host scoreboard
      _flashGood = 0.4;

      // Particles
      _particles.addAll(FxBurst.spawn(
        Offset(hit.x * w, hit.y * h),
        hit.color, count: 16, speed: 130, size: 3.5,
      ));
      // Score pop
      _pops.add(FxPop(
        Offset(hit.x * w, hit.y * h),
        _combo >= 3 ? '+$pts ×$_combo!' : '+$pts',
        _combo >= 3 ? Potatuhs.gold : Potatuhs.textPrimary,
      ));

      final comboMsg = _combo >= 3 ? '×$_combo COMBO!' : null;
      if (comboMsg != null) _toast(comboMsg);
    });
  }

  void _toast(String t) { _toastText = t; _toastTimer = 1.3; }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth, h = constraints.maxHeight;
      return GestureDetector(
        onTapDown: (d) => _handleTap(d.localPosition, Size(w, h)),
        child: CustomPaint(
          painter: _StarCollectorPainter(
            stars:     _stars,
            particles: _particles,
            pops:      _pops,
            flashGood: _flashGood,
            flashBad:  _flashBad,
            clock:     _clock,
          ),
          child: Stack(children: [
            // ── HUD strip (game-specific; host draws score + timer) ──────
            Positioned(top: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.fromLTRB(14, 44, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Wave (game-specific; host owns score + timer)
                  Text('W$_wave', style: Potatuhs.label(size: 14, color: Potatuhs.airForce)),
                ],
              ),
            )),
            // (Intro/instructions handled by the host.)
            // ── Combo banner ─────────────────────────────────────────────
            if (_combo >= 3) Positioned(
              top: 100, left: 0, right: 0,
              child: Center(child: Text(
                '×$_combo COMBO',
                style: Potatuhs.display(size: 22, color: Potatuhs.gold),
              )),
            ),
            // ── Toast ─────────────────────────────────────────────────────
            if (_toastText != null) Positioned(
              top: 130, left: 0, right: 0,
              child: Center(child: Builder(builder: (_) {
                final isGood = !_toastText!.contains('Escaped');
                final fade   = (_toastTimer / 1.3).clamp(0.0, 1.0);
                final col    = (isGood ? Potatuhs.gold : const Color(0xFFFF5252))
                    .withValues(alpha: fade);
                return Text(
                  _toastText!,
                  style: Potatuhs.display(size: 20, color: col),
                );
              })),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildStart() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Potatuhs.inkDeep, Color.lerp(Potatuhs.inkDeep, Potatuhs.glaucous, 0.18)!],
          ),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('STAR COLLECTOR', style: Potatuhs.display(size: 34, color: Potatuhs.gold)),
          const SizedBox(height: 14),
          Text(
            'Stars drift across the galaxy.\nTap them before they escape!',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 16, color: Potatuhs.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Chains of 3+ stars = COMBO bonus',
            textAlign: TextAlign.center,
            style: Potatuhs.label(size: 13, color: Potatuhs.airForce),
          ),
          const SizedBox(height: 28),
          if (_highScore > 0) Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Best: $_highScore',
              style: Potatuhs.display(size: 18, color: Potatuhs.gold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: Potatuhs.ctaGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('TAP TO PLAY', style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
          ),
        ])),
      ),
    );
  }

  Widget _buildOver() {
    final newHigh = _score >= _highScore && _score > 0;
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Potatuhs.inkDeep, Color.lerp(Potatuhs.inkDeep, Potatuhs.glaucous, 0.18)!],
          ),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('TIME\'S UP', style: Potatuhs.display(size: 30, color: Potatuhs.orange)),
          const SizedBox(height: 22),
          Text('$_score', style: Potatuhs.display(size: 52, color: Potatuhs.gold)),
          Text('POINTS', style: Potatuhs.label(size: 13, color: Potatuhs.textFaint)),
          const SizedBox(height: 10),
          if (newHigh) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('NEW HIGH SCORE!', style: Potatuhs.display(size: 20, color: Potatuhs.gold)),
          ),
          if (!newHigh) Text(
            'Best: $_highScore',
            style: Potatuhs.label(size: 15, color: Potatuhs.textFaint),
          ),
          const SizedBox(height: 6),
          Text('Wave Reached: $_wave', style: Potatuhs.body(size: 15, color: Potatuhs.airForce)),
          const SizedBox(height: 4),
          Text('Best Combo: ×$_bestCombo', style: Potatuhs.body(size: 15, color: Potatuhs.sienna)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: Potatuhs.ctaGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('PLAY AGAIN', style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
          ),
        ])),
      ),
    );
  }
}

// ── Canvas painter ────────────────────────────────────────────────────────────
class _StarCollectorPainter extends CustomPainter {
  final List<_GCStar>    stars;
  final List<FxParticle> particles;
  final List<FxPop>      pops;
  final double flashGood, flashBad, clock;

  const _StarCollectorPainter({
    required this.stars,
    required this.particles,
    required this.pops,
    required this.flashGood,
    required this.flashBad,
    required this.clock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // ── Atmospheric background ──────────────────────────────────────────
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, clock, motes: 48);

    // ── Stars ──────────────────────────────────────────────────────────
    for (final s in stars) {
      if (s.scale <= 0) continue;
      final a = s.scale.clamp(0.0, 1.0);
      final px = s.x * w;
      final py = s.y * h;

      // Ghost trail: dots showing where the star is heading
      if (!s.collected) {
        final lifeRatio = (s.life / s.maxLife).clamp(0.0, 1.0);
        // Draw 5 ghost dots along the future path
        for (int gi = 1; gi <= 5; gi++) {
          final frac = gi / 5.0;
          final gx = px + s.vx * w * frac * s.life;
          final gy = py + s.vy * h * frac * s.life;
          // Only draw if still on screen-ish
          if (gx < -20 || gx > w + 20 || gy < -20 || gy > h + 20) break;
          final ga = (0.22 - frac * 0.18) * a * lifeRatio;
          canvas.drawCircle(
            Offset(gx, gy),
            s.radius * (0.20 - frac * 0.03),
            Paint()..color = s.color.withValues(alpha: ga)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }

        // Urgency pulse ring: appears when < 40 % life left
        final urgency = 1.0 - lifeRatio;
        if (urgency > 0.6) {
          final pulseA = (urgency - 0.6) / 0.4;
          final pulse = 0.5 + 0.5 * sin(clock * 8.0 + s.idx.toDouble());
          canvas.drawCircle(
            Offset(px, py),
            s.radius * (1.55 + pulse * 0.25) * a,
            Paint()
              ..color = const Color(0xFFFF5252).withValues(alpha: pulseA * 0.5 * a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }

        // Tutorial label: pulsing "TAP!" arrow above the star
        if (s.isTutorial) {
          final pulse = 0.65 + 0.35 * sin(clock * 4.0);
          GameFx.text(
            canvas,
            '▼ TAP!',
            Offset(px, py - s.radius * 1.8 - 14),
            15,
            Potatuhs.gold.withValues(alpha: pulse * a),
            display: true,
            glow: 0.8 * pulse,
          );
        }
      }

      // ── Star orb ─────────────────────────────────────────────────────
      // Good-flash: brighten on collection
      final effectiveGlow = s.collected ? 0.0 : 1.0;
      if (s.flashGood > 0) {
        canvas.drawCircle(
          Offset(px, py),
          s.radius * 2.2 * a,
          Paint()
            ..color = s.color.withValues(alpha: s.flashGood * 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
      }

      GameFx.orb(
        canvas, Offset(px, py), s.radius * a, s.color,
        glow: effectiveGlow * a,
      );

      // Draw little ray spikes around the star for readability (it's a STAR)
      if (!s.collected) {
        final spikePaint = Paint()
          ..color = s.color.withValues(alpha: 0.45 * a)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        final spokeCount = 6;
        final spikeLen = s.radius * 0.65;
        final bob = clock * 0.8 + s.idx * 0.4; // slow rotation
        for (int sp = 0; sp < spokeCount; sp++) {
          final ang = bob + sp * (2 * pi / spokeCount);
          final inner = s.radius * 1.08 * a;
          final outer = (s.radius + spikeLen) * a;
          canvas.drawLine(
            Offset(px + cos(ang) * inner, py + sin(ang) * inner),
            Offset(px + cos(ang) * outer, py + sin(ang) * outer),
            spikePaint,
          );
        }
      }
    }

    // ── FxBurst particles ──────────────────────────────────────────────
    FxBurst.paint(canvas, particles);

    // ── Score pops ────────────────────────────────────────────────────
    for (final p in pops) { p.paint(canvas); }

    // ── Screen flashes ────────────────────────────────────────────────
    if (flashGood > 0) canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Potatuhs.gold.withValues(alpha: flashGood * 0.12),
    );
    if (flashBad > 0) canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFFF5252).withValues(alpha: flashBad * 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _StarCollectorPainter old) => true;
}
