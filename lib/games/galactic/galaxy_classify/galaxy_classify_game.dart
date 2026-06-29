import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';

// ============================================================================
// GALAXY CLASSIFIER — Hubble-morphology snap-classification (galactic scale).
//
// Galaxies drift across the frame on ONE Ticker → ONE CustomPainter. The
// front-most unclassified galaxy is FRAMED (a pulsing reticle); the player taps
// one of four type buttons — Spiral / Barred Spiral / Elliptical / Irregular —
// before it slides off the left edge. Faster, cleaner calls score more (a speed
// bonus decays from max to a floor over ~4 s since the galaxy was framed); a
// streak multiplier rewards consecutive correct reads. A wrong call or a miss
// reveals the true type. The flythrough accelerates and the distinctions get
// subtler (tight vs loose spirals, more bars) as the round runs.
//
// This is the anti-"collect stars" game: you READ galaxies, you do not chase
// them. Sibling in genre to `arcade/organ_quiz.dart` / `somethings/whose_idea`
// (speed-scored snap classification), but the subject is a moving field, not a
// static card. The host (MiniGameHost) owns the round clock, 3·2·1 countdown,
// score HUD and results; this widget renders ONLY the play area and never calls
// endEarly.
// ============================================================================

const _kFont = 'Avenir';

// -- Palette -----------------------------------------------------------------
const Color _kBg          = Color(0xFF05060D); // deep-space canvas
const Color _kGold        = Color(0xFFFFD600); // streak / bonus flashes
const Color _kGoodGreen   = Color(0xFF69F0AE); // correct highlight
const Color _kBadRed      = Color(0xFFFF5252); // wrong / missed tint
const Color _kTextPrimary = Color(0xFFF0F2F5);
const Color _kTextSub     = Color(0xFF8A93A8);
const Color _kAccent      = Color(0xFF7C6FF0); // cosmic indigo (scale accent)

// Per-type accent colors (also used for the procedural galaxy tints).
const Color _kSpiralBlue   = Color(0xFF5B9BFF);
const Color _kBarredTeal   = Color(0xFF3FD0C9);
const Color _kEllipAmber   = Color(0xFFFFB74D);
const Color _kIrregMagenta = Color(0xFFF06CC6);

// -- Timing / scoring (mirrors organ_quiz / whose_idea) ----------------------
/// Max points for an instant correct classification.
const int    _kMaxPoints   = 120;
/// Floor points for a slow (but correct) classification.
const int    _kFloorPoints = 20;
/// Window (seconds, since the galaxy was framed) over which the speed bonus
/// decays from max to floor.
const double _kDecayWindow = 4.0;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int    _kStreakStep  = 3;
/// Particles spawned on a correct call.
const int    _kBurstCount  = 16;

// ============================================================================
// Types
// ============================================================================

enum GalaxyType { spiral, barredSpiral, elliptical, irregular }

extension _GalaxyTypeMeta on GalaxyType {
  String get label => switch (this) {
        GalaxyType.spiral => 'Spiral',
        GalaxyType.barredSpiral => 'Barred Spiral',
        GalaxyType.elliptical => 'Elliptical',
        GalaxyType.irregular => 'Irregular',
      };

  Color get color => switch (this) {
        GalaxyType.spiral => _kSpiralBlue,
        GalaxyType.barredSpiral => _kBarredTeal,
        GalaxyType.elliptical => _kEllipAmber,
        GalaxyType.irregular => _kIrregMagenta,
      };
}

const List<GalaxyType> _kTypeOrder = [
  GalaxyType.spiral,
  GalaxyType.barredSpiral,
  GalaxyType.elliptical,
  GalaxyType.irregular,
];

// -- Resolution state of a galaxy --------------------------------------------
// 0 = unresolved (still classifiable), 1 = correct, 2 = wrong, 3 = missed.
const int _kUnresolved = 0;
const int _kCorrect = 1;
const int _kWrong = 2;
const int _kMissed = 3;

// ============================================================================
// Internal data
// ============================================================================

/// A single precomputed star in a galaxy's local unit space (radius == 1).
class _Star {
  final Offset p;
  final double s;
  final Color c;
  const _Star(this.p, this.s, this.c);
}

class _GalaxyData {
  final GalaxyType type;
  final List<_Star> stars;
  final double radius;
  final double speedMul;
  final double spinRate;
  final Color glowColor;

  double x;
  double y;
  double spin;

  int resolved = _kUnresolved;
  double resolveAge = 0;
  GalaxyType? guess;
  TextPainter? tag; // reveal/score label, built once on resolve

  _GalaxyData({
    required this.type,
    required this.stars,
    required this.radius,
    required this.speedMul,
    required this.spinRate,
    required this.glowColor,
    required this.x,
    required this.y,
    required this.spin,
  });
}

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

/// Bare Listenable that the field painter repaints from — bumped every tick so
/// the galaxy field animates WITHOUT rebuilding the widget tree (setState is
/// reserved for discrete events: play-start, a classification, a button flash).
class _FrameSignal extends ChangeNotifier {
  void bump() => notifyListeners();
}

// ============================================================================
// Widget
// ============================================================================

class GalaxyClassifyGame extends StatefulWidget {
  final MiniGameSession session;
  const GalaxyClassifyGame({super.key, required this.session});

  @override
  State<GalaxyClassifyGame> createState() => _GalaxyClassifyGameState();
}

class _GalaxyClassifyGameState extends State<GalaxyClassifyGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _FrameSignal _frame = _FrameSignal();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;     // free-running, for ambient motion
  double _playClock = 0; // accumulates only while running, drives difficulty

  final List<_GalaxyData> _galaxies = [];
  final List<_Particle> _particles = [];
  _GalaxyData? _focused;
  double _focusTimer = 0; // seconds since the focused galaxy was framed
  double _spawnTimer = 0;

  int _streak = 0;
  int _lastMultiplier = 1;

  // Brief button-flash feedback (discrete; cleared by a delayed setState).
  GalaxyType? _flashType;
  bool _flashCorrect = false;

  bool _started = false;
  Size _fieldSize = Size.zero;

  // ==========================================================================
  // Init / dispose
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    for (final g in _galaxies) {
      g.tag?.dispose();
    }
    super.dispose();
  }

  // ==========================================================================
  // Game loop
  // ==========================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        _seedInitial();
        if (mounted) setState(() {}); // swap ready-state → field (discrete)
      }
      _simulate(dt);
    }

    _frame.bump(); // animate the field without a widget rebuild
  }

  double get _difficulty => (_playClock / 45.0).clamp(0.0, 1.0);

  void _simulate(double dt) {
    _playClock += dt;
    final diff = _difficulty;
    final speed = _lerp(30, 74, diff);
    final spawnInterval = _lerp(2.3, 1.05, diff);
    final maxOnScreen = 4 + (diff * 3).round();

    // Move galaxies, spin them, age resolved ones, flag misses.
    for (final g in _galaxies) {
      g.x -= speed * g.speedMul * dt;
      g.spin += g.spinRate * dt;
      if (g.resolved != _kUnresolved) g.resolveAge += dt;
      if (g.resolved == _kUnresolved && g.x < g.radius * 0.55) {
        // Slid to the exit edge without a call → a miss; reveal the truth.
        g.resolved = _kMissed;
        g.resolveAge = 0;
        _buildTag(g);
        _streak = 0;
        _lastMultiplier = 1;
      }
    }

    // Remove galaxies fully off the left edge.
    _galaxies.removeWhere((g) {
      if (g.x < -g.radius * 1.8) {
        g.tag?.dispose();
        return true;
      }
      return false;
    });

    // Spawn cadence.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _galaxies.length < maxOnScreen) {
      _spawn(diff);
      _spawnTimer = spawnInterval * (0.85 + _rng.nextDouble() * 0.3);
    }

    // Recompute focus: the front-most (smallest x) unresolved galaxy.
    _GalaxyData? front;
    for (final g in _galaxies) {
      if (g.resolved != _kUnresolved) continue;
      if (front == null || g.x < front.x) front = g;
    }
    if (!identical(front, _focused)) {
      _focused = front;
      _focusTimer = 0;
    } else if (front != null) {
      _focusTimer += dt;
    }

    // Particles.
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  // ==========================================================================
  // Spawning + procedural galaxy generation
  // ==========================================================================

  void _seedInitial() {
    if (_fieldSize.isEmpty) return;
    // A couple already partway across so the field never starts empty.
    final diff = 0.0;
    _spawn(diff, startX: _fieldSize.width * 0.55);
    _spawn(diff, startX: _fieldSize.width * 0.95);
    _spawnTimer = 1.4;
  }

  void _spawn(double diff, {double? startX}) {
    if (_fieldSize.isEmpty) return;
    final type = _pickType(diff);
    final radius = _lerp(46, 34, diff) + _rng.nextDouble() * 8;
    final y = radius * 1.4 +
        _rng.nextDouble() * (_fieldSize.height - radius * 2.8).clamp(1, 4000);
    final stars = _generate(type, diff);
    _galaxies.add(_GalaxyData(
      type: type,
      stars: stars,
      radius: radius,
      speedMul: 0.85 + _rng.nextDouble() * 0.3,
      spinRate: (_rng.nextBool() ? 1 : -1) * (0.08 + _rng.nextDouble() * 0.16),
      glowColor: type.color,
      x: startX ?? (_fieldSize.width + radius),
      y: y,
      spin: _rng.nextDouble() * math.pi * 2,
    ));
  }

  /// Difficulty biases the mix toward the confusable pair (barred vs spiral)
  /// and away from the obvious ones as the round runs.
  GalaxyType _pickType(double diff) {
    final wSpiral = 1.0;
    final wBarred = 0.55 + diff * 0.7; // bars get more common (harder)
    final wEllip = 1.0 - diff * 0.25;
    final wIrreg = 0.85 - diff * 0.2;
    final total = wSpiral + wBarred + wEllip + wIrreg;
    var r = _rng.nextDouble() * total;
    if ((r -= wSpiral) < 0) return GalaxyType.spiral;
    if ((r -= wBarred) < 0) return GalaxyType.barredSpiral;
    if ((r -= wEllip) < 0) return GalaxyType.elliptical;
    return GalaxyType.irregular;
  }

  List<_Star> _generate(GalaxyType type, double diff) {
    switch (type) {
      case GalaxyType.spiral:
        // Tighter winding at high difficulty (subtler read).
        return _genSpiral(windings: _lerp(0.55, 1.25, diff * _rng.nextDouble()),
            barred: false);
      case GalaxyType.barredSpiral:
        return _genSpiral(windings: _lerp(0.5, 1.1, diff * _rng.nextDouble()),
            barred: true);
      case GalaxyType.elliptical:
        return _genElliptical();
      case GalaxyType.irregular:
        return _genIrregular();
    }
  }

  Color _bulgeColor() =>
      Color.lerp(const Color(0xFFFFE9A8), const Color(0xFFFFC25A),
          _rng.nextDouble())!;

  Color _armColor() => Color.lerp(_kSpiralBlue, Colors.white, _rng.nextDouble())!
      .withValues(alpha: 0.92);

  List<_Star> _genSpiral({required double windings, required bool barred}) {
    final stars = <_Star>[];
    final double startR;
    if (barred) {
      const barLen = 0.46;
      startR = barLen;
      for (var i = 0; i < 13; i++) {
        final t = (i / 12) * 2 - 1; // -1..1 along the bar
        stars.add(_Star(
          Offset(t * barLen, (_rng.nextDouble() - 0.5) * 0.10),
          1.7 + _rng.nextDouble() * 1.3,
          _bulgeColor(),
        ));
      }
    } else {
      startR = 0.16;
      for (var i = 0; i < 14; i++) {
        final a = _rng.nextDouble() * math.pi * 2;
        final rad = _rng.nextDouble() * 0.18;
        stars.add(_Star(
          Offset(math.cos(a) * rad, math.sin(a) * rad * 0.9),
          1.7 + _rng.nextDouble() * 1.5,
          _bulgeColor(),
        ));
      }
    }
    // Two arms, both winding the same direction, offset by π.
    for (final armOffset in [0.0, math.pi]) {
      const n = 18;
      for (var i = 0; i < n; i++) {
        final t = i / (n - 1);
        final rad = startR + t * (1.0 - startR);
        final theta = armOffset + t * windings * math.pi * 2;
        final jx = (_rng.nextDouble() - 0.5) * 0.06;
        final jy = (_rng.nextDouble() - 0.5) * 0.06;
        stars.add(_Star(
          Offset(math.cos(theta) * rad + jx, math.sin(theta) * rad + jy),
          1.2 + _rng.nextDouble() * 1.4,
          _armColor(),
        ));
      }
    }
    return stars;
  }

  List<_Star> _genElliptical() {
    final stars = <_Star>[];
    final ellip = 0.5 + _rng.nextDouble() * 0.32; // y-squash (smooth ellipse)
    final pa = _rng.nextDouble() * math.pi;       // position angle
    final cosP = math.cos(pa), sinP = math.sin(pa);
    for (var i = 0; i < 46; i++) {
      // Product of uniforms → dense, smoothly fading center.
      final rad = _rng.nextDouble() * _rng.nextDouble() * 0.98;
      final a = _rng.nextDouble() * math.pi * 2;
      var x = math.cos(a) * rad;
      var y = math.sin(a) * rad * ellip;
      final rx = x * cosP - y * sinP;
      final ry = x * sinP + y * cosP;
      final warm = Color.lerp(const Color(0xFFFFF1D6),
          const Color(0xFFFFC98A), _rng.nextDouble())!;
      stars.add(_Star(
        Offset(rx, ry),
        1.0 + (1.0 - rad) * 1.9,
        warm.withValues(alpha: 0.55 + (1.0 - rad) * 0.45),
      ));
    }
    return stars;
  }

  List<_Star> _genIrregular() {
    final stars = <_Star>[];
    final blobs = 2 + _rng.nextInt(3);
    for (var b = 0; b < blobs; b++) {
      final cx = (_rng.nextDouble() - 0.5) * 0.95;
      final cy = (_rng.nextDouble() - 0.5) * 0.85;
      final spread = 0.18 + _rng.nextDouble() * 0.22;
      final cnt = 7 + _rng.nextInt(8);
      for (var j = 0; j < cnt; j++) {
        final dx = (_rng.nextDouble() - 0.5) * spread * 2;
        final dy = (_rng.nextDouble() - 0.5) * spread * 2;
        final knot = _rng.nextDouble() < 0.18;
        final base = _rng.nextDouble() < 0.25
            ? _kIrregMagenta
            : Color.lerp(_kSpiralBlue, Colors.white, _rng.nextDouble())!;
        stars.add(_Star(
          Offset(cx + dx, cy + dy),
          (knot ? 2.6 : 1.0) + _rng.nextDouble() * 1.3,
          base.withValues(alpha: knot ? 1.0 : 0.8),
        ));
      }
    }
    return stars;
  }

  // ==========================================================================
  // Scoring + input
  // ==========================================================================

  int _speedBonus() {
    final frac = (_focusTimer / _kDecayWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  void _onTypeTap(GalaxyType guess) {
    if (!widget.session.isRunning) return;
    final g = _focused;
    if (g == null || g.resolved != _kUnresolved) return;

    final correct = g.type == guess;
    g.guess = guess;
    g.resolveAge = 0;

    if (correct) {
      g.resolved = _kCorrect;
      _streak++;
      final mult = _streakMultiplier();
      _lastMultiplier = mult;
      widget.session.addScore(_speedBonus() * mult);
      widget.session.noteStreak(_streak);
      _burst(Offset(g.x, g.y), _kGoodGreen);
      if (_streak % _kStreakStep == 0) {
        _burst(Offset(g.x, g.y), _kGold, count: 10);
      }
    } else {
      g.resolved = _kWrong;
      _streak = 0;
      _lastMultiplier = 1;
      _burst(Offset(g.x, g.y), _kBadRed, count: 8);
    }
    _buildTag(g);

    // Discrete button flash; cleared shortly after.
    setState(() {
      _flashType = guess;
      _flashCorrect = correct;
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) setState(() => _flashType = null);
    });
  }

  void _buildTag(_GalaxyData g) {
    g.tag?.dispose();
    final String text;
    final Color color;
    if (g.resolved == _kCorrect) {
      final mult = _lastMultiplier;
      text = mult > 1 ? '+${_speedBonus() * mult}  ×$mult' : '+${_speedBonus()}';
      color = _kGoodGreen;
    } else {
      // Wrong or missed → reveal the true type.
      text = g.type.label;
      color = _kBadRed;
    }
    g.tag = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 55.0 + _rng.nextDouble() * 130.0;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.4 + _rng.nextDouble() * 2.6,
        color.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        children: [
          _buildHUD(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _fieldSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _FieldPainter(
                      repaint: _frame,
                      galaxies: _galaxies,
                      particles: _particles,
                      focused: () => _focused,
                      clock: () => _clock,
                      showHint: !_started,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(top: false, child: _buildButtons()),
        ],
      ),
    );
  }

  // -- HUD (driven by the session, independent of the field repaint) ---------

  Widget _buildHUD() {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final score = widget.session.score;
        final remaining = widget.session.remaining;
        final secs = remaining.inSeconds;
        final tenths = (remaining.inMilliseconds / 100).floor() % 10;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kTextPrimary,
                  shadows: [Shadow(color: _kAccent, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 6),
              if (_streak >= _kStreakStep)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: _kGold.withValues(alpha: 0.7), width: 1),
                  ),
                  child: Text(
                    '×${_streakMultiplier()}',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kGold,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '$secs.$tenths',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: secs < 5
                      ? _kBadRed
                      : _kTextPrimary.withValues(alpha: 0.82),
                  shadows: secs < 5
                      ? const [Shadow(color: _kBadRed, blurRadius: 10)]
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- Type buttons (2×2) ----------------------------------------------------

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _typeButton(_kTypeOrder[0])),
              const SizedBox(width: 8),
              Expanded(child: _typeButton(_kTypeOrder[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _typeButton(_kTypeOrder[2])),
              const SizedBox(width: 8),
              Expanded(child: _typeButton(_kTypeOrder[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeButton(GalaxyType type) {
    final flashing = _flashType == type;
    final flashColor = _flashCorrect ? _kGoodGreen : _kBadRed;
    final base = type.color;
    return GestureDetector(
      onTap: () => _onTypeTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 58,
        decoration: BoxDecoration(
          color: flashing
              ? flashColor.withValues(alpha: 0.16)
              : base.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: flashing
                ? flashColor.withValues(alpha: 0.9)
                : base.withValues(alpha: 0.55),
            width: 1.6,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CustomPaint(painter: _GlyphPainter(type)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: flashing ? flashColor : _kTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Field painter — ALL galaxies + particles on one canvas, repainted by signal
// ============================================================================

class _FieldPainter extends CustomPainter {
  final List<_GalaxyData> galaxies;
  final List<_Particle> particles;
  final _GalaxyData? Function() focused;
  final double Function() clock;
  final bool showHint;

  _FieldPainter({
    required Listenable repaint,
    required this.galaxies,
    required this.particles,
    required this.focused,
    required this.clock,
    required this.showHint,
  }) : super(repaint: repaint);

  static final Paint _star = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    for (final g in galaxies) {
      _drawGalaxy(canvas, g);
    }
    // Reticle drawn on top of the field.
    final f = focused();
    if (f != null) _drawReticle(canvas, f);
    _paintParticles(canvas);
    if (showHint) _paintHint(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    // Deterministic star field — no shimmer between repaints.
    final dust = Paint()..color = Colors.white.withValues(alpha: 0.09);
    for (var i = 0; i < 64; i++) {
      final fx = (i * 73 % 101) / 101.0;
      final fy = (i * 41 % 89) / 89.0;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        0.6 + (i % 3) * 0.4,
        dust,
      );
    }
  }

  void _drawGalaxy(Canvas canvas, _GalaxyData g) {
    final dim = g.resolved == _kUnresolved ? 1.0 : 0.5;
    final scale = g.radius / 38.0;

    // Soft glow disc (broad + diffuse for ellipticals → the "smooth blob").
    final glowR =
        g.type == GalaxyType.elliptical ? g.radius * 1.45 : g.radius * 1.2;
    canvas.drawCircle(
      Offset(g.x, g.y),
      glowR,
      Paint()
        ..color = g.glowColor.withValues(alpha: 0.07 * dim)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    final cosA = math.cos(g.spin), sinA = math.sin(g.spin);
    for (final s in g.stars) {
      final px = s.p.dx * cosA - s.p.dy * sinA;
      final py = s.p.dx * sinA + s.p.dy * cosA;
      _star.color = s.c.withValues(alpha: s.c.a * dim);
      canvas.drawCircle(
        Offset(g.x + px * g.radius, g.y + py * g.radius),
        s.s * scale,
        _star,
      );
    }

    // Reveal / score tag, for ~1.6 s after a galaxy resolves.
    final tag = g.tag;
    if (tag != null && g.resolved != _kUnresolved && g.resolveAge < 1.6) {
      tag.paint(
        canvas,
        Offset(g.x - tag.width / 2, g.y - g.radius - tag.height - 4),
      );
    }
  }

  void _drawReticle(Canvas canvas, _GalaxyData g) {
    final pulse = 0.5 + 0.5 * math.sin(clock() * 4.5);
    final r = g.radius * 1.5;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kAccent.withValues(alpha: 0.45 + 0.4 * pulse);
    canvas.drawCircle(Offset(g.x, g.y), r, ringPaint);

    // Four corner ticks (a framing reticle).
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = _kAccent.withValues(alpha: 0.7 + 0.3 * pulse);
    const len = 7.0;
    for (final a in [
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
      7 * math.pi / 4,
    ]) {
      final c = Offset(g.x + math.cos(a) * r, g.y + math.sin(a) * r);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c - dir * len, c + dir * len, tickPaint);
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * alpha,
        Paint()..color = p.color.withValues(alpha: p.color.a * alpha),
      );
    }
  }

  void _paintHint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Read each galaxy by its shape.\n'
            'Frame it, name it, move on.',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kTextSub,
          height: 1.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 60);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height * 0.5 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_FieldPainter old) => false; // driven by the repaint signal
}

// ============================================================================
// Tiny static glyph for each type button (painted once; never repaints)
// ============================================================================

class _GlyphPainter extends CustomPainter {
  final GalaxyType type;
  const _GlyphPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final color = type.color;
    final p = Paint()..color = color;

    switch (type) {
      case GalaxyType.spiral:
      case GalaxyType.barredSpiral:
        final barred = type == GalaxyType.barredSpiral;
        // Core / bar.
        if (barred) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: R * 1.1, height: R * 0.34),
              const Radius.circular(3),
            ),
            p..color = color.withValues(alpha: 0.95),
          );
        } else {
          canvas.drawCircle(c, R * 0.28, p..color = color.withValues(alpha: 0.95));
        }
        // Two arms.
        final dot = Paint()..color = color.withValues(alpha: 0.85);
        for (final off in [0.0, math.pi]) {
          final startR = barred ? R * 0.55 : R * 0.28;
          for (var i = 0; i < 6; i++) {
            final t = i / 5;
            final rad = startR + t * (R * 0.95 - startR);
            final th = off + t * math.pi * 0.9;
            canvas.drawCircle(
              Offset(c.dx + math.cos(th) * rad, c.dy + math.sin(th) * rad),
              1.4,
              dot,
            );
          }
        }
        break;
      case GalaxyType.elliptical:
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-0.5);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: R * 1.9, height: R * 1.1),
          Paint()
            ..shader = RadialGradient(colors: [
              color,
              color.withValues(alpha: 0.15),
            ]).createShader(
                Rect.fromCircle(center: Offset.zero, radius: R)),
        );
        canvas.restore();
        break;
      case GalaxyType.irregular:
        final seeds = [
          const Offset(-0.4, -0.2),
          const Offset(0.3, -0.35),
          const Offset(0.1, 0.3),
          const Offset(-0.25, 0.35),
          const Offset(0.45, 0.15),
        ];
        for (var i = 0; i < seeds.length; i++) {
          canvas.drawCircle(
            c + Offset(seeds[i].dx * R, seeds[i].dy * R),
            i.isEven ? 2.6 : 1.7,
            Paint()..color = color.withValues(alpha: i.isEven ? 0.95 : 0.7),
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.type != type;
}
