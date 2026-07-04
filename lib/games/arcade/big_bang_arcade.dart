import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../fx.dart';
import '../mini_game.dart';

const _kFont = 'Avenir';
const Color _kAccent = Color(0xFFFFAB40);
const Color _kAnti = Color(0xFFFF5252);

/// "Big Bang" — scale: Nothing.
///
/// A black void. Sparks of matter pop into existence, pulse, and fade.
/// Tap them before they vanish to forge matter; consecutive catches build a
/// combo multiplier. Red antimatter orbs punish careless thumbs. As matter is
/// created the void slowly fills with drifting star dust.
class BigBangArcade extends StatefulWidget {
  final MiniGameSession session;
  const BigBangArcade({Key? key, required this.session}) : super(key: key);

  @override
  State<BigBangArcade> createState() => _BigBangArcadeState();
}

class _Spark {
  final Offset pos;
  final bool antimatter;
  final double lifespan; // seconds
  final double seed; // 0..1, visual variety
  double age = 0;
  bool caught = false;

  _Spark({
    required this.pos,
    required this.antimatter,
    required this.lifespan,
    required this.seed,
  });

  bool get expired => caught || age >= lifespan;
}

class _Burst {
  final Offset pos;
  final Color color;
  final double seed;
  double age = 0;
  static const double life = 0.55;

  _Burst({required this.pos, required this.color, required this.seed});

  bool get done => age >= life;
}

class _Popup {
  final Offset pos;
  final String text;
  final Color color;
  final double fontSize;
  double age = 0;
  static const double life = 0.9;

  _Popup({
    required this.pos,
    required this.text,
    required this.color,
    this.fontSize = 18,
  });

  bool get done => age >= life;
}

class _Star {
  Offset pos;
  final Offset drift; // px / second
  final double size;
  final double phase; // twinkle offset

  _Star({
    required this.pos,
    required this.drift,
    required this.size,
    required this.phase,
  });
}

class _BigBangArcadeState extends State<BigBangArcade>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  final List<_Spark> _sparks = [];
  final List<_Burst> _bursts = [];
  final List<_Popup> _popups = [];
  final List<_Star> _stars = [];

  Size _fieldSize = Size.zero;
  Duration _lastTick = Duration.zero;
  double _runTime = 0; // seconds elapsed while session.isRunning
  double _spawnClock = 0;
  double _idlePulse = 0; // ambient animation before the run starts

  int _streak = 0; // consecutive catches
  double _flash = 0; // antimatter hit feedback, counts down to 0
  double _comboPop = 0; // badge pop animation, counts down to 0

  static const double _maxFlash = 0.45;

  int get _multiplier => math.min(5, 1 + (math.max(0, _streak - 1) ~/ 3));

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays Big Bang the way a
  /// skilled thumb would, not randomly: it scans the live sparks, ignores every
  /// red antimatter orb, and catches the matter spark that is closest to fading
  /// back into the void (highest age/lifespan ratio). Grabbing the most urgent
  /// spark salvages combos that expiry would otherwise fizzle and banks real
  /// points; catching any matter also extends the streak/multiplier. If no
  /// matter spark is alive this instant, it does nothing. The host owns the
  /// clock, so the round still ends on time.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    _Spark? best;
    var bestUrgency = -1.0;
    for (final s in _sparks) {
      if (s.caught || s.antimatter || s.age >= s.lifespan) continue;
      // Urgency = how far into its life the spark is; 1.0 = about to expire.
      final urgency = s.age / s.lifespan;
      if (urgency > bestUrgency) {
        bestUrgency = urgency;
        best = s;
      }
    }
    if (best == null) return; // no valid target — never tap antimatter or void

    // Fire the exact code path a real tap on this spark would (see [_onTapDown]).
    best.caught = true;
    _catchMatter(best);
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    _idlePulse += dt;

    final running = widget.session.isRunning;
    if (running && _fieldSize != Size.zero) {
      _runTime += dt;
      _spawnClock += dt;

      // Spawn rate ramps from ~700ms down to ~350ms across the run, and
      // matter arrives in waves late-game: 2× after half time, 4× in the
      // last quarter, 8× in the final eighth. Perfection is impossible by
      // design — the late-game ceiling is pure skill.
      final p = _progress;
      final interval = _lerp(0.70, 0.35, p);
      final burst = p >= 0.875
          ? 8
          : p >= 0.75
              ? 4
              : p >= 0.5
                  ? 2
                  : 1;
      while (_spawnClock >= interval) {
        _spawnClock -= interval;
        for (var i = 0; i < burst; i++) {
          _spawnSpark();
        }
      }

      // Age sparks, catch expirations.
      for (final s in _sparks) {
        s.age += dt;
        if (!s.caught && s.age >= s.lifespan && !s.antimatter) {
          // A spark of matter slipped back into the void: combo fizzles.
          // Only during the solo-spawn phase — once waves begin, missing
          // sparks is inevitable, so expiry stops punishing the streak.
          if (burst == 1 && _streak > 0) {
            _streak = 0;
            _popups.add(_Popup(
              pos: s.pos,
              text: 'lost...',
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ));
          }
        }
      }
      _sparks.removeWhere((s) => s.expired);
    } else {
      // Countdown / finished: hold the scene, let leftovers drain out.
      for (final s in _sparks) {
        s.age += dt;
      }
      _sparks.removeWhere((s) => s.expired);
    }

    // Effects always animate so feedback finishes smoothly.
    for (final b in _bursts) {
      b.age += dt;
    }
    _bursts.removeWhere((b) => b.done);
    for (final pp in _popups) {
      pp.age += dt;
    }
    _popups.removeWhere((pp) => pp.done);
    if (_flash > 0) _flash = math.max(0, _flash - dt);
    if (_comboPop > 0) _comboPop = math.max(0, _comboPop - dt);

    // Star dust drifts forever, wrapping at the edges.
    if (_fieldSize != Size.zero) {
      for (final st in _stars) {
        var x = st.pos.dx + st.drift.dx * dt;
        var y = st.pos.dy + st.drift.dy * dt;
        if (x < -4) x = _fieldSize.width + 4;
        if (x > _fieldSize.width + 4) x = -4;
        if (y < -4) y = _fieldSize.height + 4;
        if (y > _fieldSize.height + 4) y = -4;
        st.pos = Offset(x, y);
      }
    }

    if (mounted) setState(() {});
  }

  double get _progress {
    final total = widget.session.spec.durationSeconds.toDouble();
    if (total <= 0) return 1.0;
    return (_runTime / total).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _spawnSpark() {
    const margin = 46.0;
    if (_fieldSize.width <= margin * 2 || _fieldSize.height <= margin * 2) {
      return;
    }
    final pos = Offset(
      margin + _rng.nextDouble() * (_fieldSize.width - margin * 2),
      margin + _rng.nextDouble() * (_fieldSize.height - margin * 2),
    );
    final antimatter = _rng.nextDouble() < 0.20;
    // Lifespan shrinks from ~1.4s to ~0.9s as the run accelerates.
    final lifespan =
        _lerp(1.4, 0.9, _progress) * (0.9 + _rng.nextDouble() * 0.2);
    _sparks.add(_Spark(
      pos: pos,
      antimatter: antimatter,
      lifespan: lifespan,
      seed: _rng.nextDouble(),
    ));
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.session.isRunning) return;
    final tap = details.localPosition;

    _Spark? best;
    var bestDist = double.infinity;
    for (final s in _sparks) {
      if (s.caught || s.age >= s.lifespan) continue;
      final d = (s.pos - tap).distance;
      if (d < 48 && d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    if (best == null) return;

    best.caught = true;
    if (best.antimatter) {
      _hitAntimatter(best);
    } else {
      _catchMatter(best);
    }
  }

  void _catchMatter(_Spark s) {
    _streak += 1;
    widget.session.noteStreak(_streak); // feed the end-of-game streak award
    final mult = _multiplier;
    final gained = 10 * mult;
    widget.session.addScore(gained);

    _comboPop = 0.35;
    _bursts.add(_Burst(pos: s.pos, color: _kAccent, seed: s.seed));
    _popups.add(_Popup(
      pos: s.pos,
      text: '+$gained',
      color: mult > 1 ? const Color(0xFFFFD54F) : _kAccent,
      fontSize: mult > 1 ? 22 : 18,
    ));

    // The void fills with star dust as matter is forged.
    if (_stars.length < 150 && _fieldSize != Size.zero) {
      for (var i = 0; i < 3; i++) {
        _stars.add(_Star(
          pos: Offset(
            _rng.nextDouble() * _fieldSize.width,
            _rng.nextDouble() * _fieldSize.height,
          ),
          drift: Offset(
            (_rng.nextDouble() - 0.5) * 8,
            (_rng.nextDouble() - 0.5) * 8,
          ),
          size: 0.6 + _rng.nextDouble() * 1.4,
          phase: _rng.nextDouble() * math.pi * 2,
        ));
      }
    }
  }

  void _hitAntimatter(_Spark s) {
    widget.session.addScore(-15);
    _streak = 0;
    _flash = _maxFlash;
    _bursts.add(_Burst(pos: s.pos, color: _kAnti, seed: s.seed));
    _popups.add(_Popup(
      pos: s.pos,
      text: '-15',
      color: _kAnti,
      fontSize: 20,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Screen shake while the antimatter flash decays.
    Offset shake = Offset.zero;
    if (_flash > 0) {
      final f = _flash / _maxFlash;
      shake = Offset(
        math.sin(_idlePulse * 70) * 5 * f,
        math.cos(_idlePulse * 63) * 4 * f,
      );
    }

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: shake,
                    child: CustomPaint(
                      painter: _VoidPainter(
                        sparks: _sparks,
                        bursts: _bursts,
                        stars: _stars,
                        time: _idlePulse,
                      ),
                    ),
                  ),
                ),
                // Floating score popups.
                for (final p in _popups) _buildPopup(p),
                // Combo badge.
                if (_streak >= 2) _buildComboBadge(),
                // Red antimatter flash.
                if (_flash > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: _kAnti.withValues(
                            alpha: 0.22 * (_flash / _maxFlash)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopup(_Popup p) {
    final t = (p.age / _Popup.life).clamp(0.0, 1.0);
    final opacity = (1.0 - t * t).clamp(0.0, 1.0);
    final rise = 36.0 * t;
    return Positioned(
      left: p.pos.dx - 50,
      top: p.pos.dy - 26 - rise,
      child: IgnorePointer(
        child: SizedBox(
          width: 100,
          child: Text(
            p.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: p.fontSize,
              fontWeight: FontWeight.bold,
              color: p.color.withValues(alpha: opacity),
              shadows: [
                Shadow(
                  color: p.color.withValues(alpha: 0.8 * opacity),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComboBadge() {
    final mult = _multiplier;
    final pop = _comboPop > 0 ? (_comboPop / 0.35) : 0.0;
    final scale = 1.0 + 0.25 * pop;
    final glow = 0.35 + 0.45 * pop;
    return Positioned(
      top: 12,
      right: 12,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kAccent.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withValues(alpha: glow),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '×$mult',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_streak streak',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoidPainter extends CustomPainter {
  final List<_Spark> sparks;
  final List<_Burst> bursts;
  final List<_Star> stars;
  final double time;

  _VoidPainter({
    required this.sparks,
    required this.bursts,
    required this.stars,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The void: black with the faintest warm gradient breathing at center.
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kAccent.withValues(alpha: 0.05 + 0.02 * math.sin(time * 0.8)),
          Colors.black,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.longestSide * 0.7,
        ),
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    _paintStars(canvas);
    for (final s in sparks) {
      if (s.antimatter) {
        _paintAntimatter(canvas, s);
      } else {
        _paintMatter(canvas, s);
      }
    }
    for (final b in bursts) {
      _paintBurst(canvas, b);
    }
  }

  void _paintStars(Canvas canvas) {
    for (final st in stars) {
      final twinkle = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(time * 2 + st.phase));
      _BigBangArt.star(canvas, st.pos, st.size, twinkle);
    }
  }

  /// 0 → 1 envelope: quick pop-in, sustained pulse, fade-out.
  double _envelope(_Spark s) {
    final t = (s.age / s.lifespan).clamp(0.0, 1.0);
    if (t < 0.15) return t / 0.15; // pop in
    if (t > 0.65) return ((1.0 - t) / 0.35).clamp(0.0, 1.0); // fade out
    return 1.0;
  }

  void _paintMatter(Canvas canvas, _Spark s) {
    _BigBangArt.matter(canvas, s.pos,
        env: _envelope(s), time: time, seed: s.seed);
  }

  void _paintAntimatter(Canvas canvas, _Spark s) {
    _BigBangArt.antimatter(canvas, s.pos,
        env: _envelope(s), time: time, seed: s.seed);
  }

  void _paintBurst(Canvas canvas, _Burst b) {
    _BigBangArt.burst(canvas, b.pos,
        t: (b.age / _Burst.life).clamp(0.0, 1.0),
        color: b.color,
        seed: b.seed);
  }

  @override
  bool shouldRepaint(covariant _VoidPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// _BigBangArt — the component draws, shared by the live painter above and the
// visual manual below so the manual shows the EXACT sparks the player meets.
// ═══════════════════════════════════════════════════════════════════════════

class _BigBangArt {
  _BigBangArt._();

  /// One golden matter spark: halo, glowing body, white-hot core, orbiting
  /// flecks. [env] is the pop-in/fade-out envelope (1.0 = fully alive).
  static void matter(
    Canvas canvas,
    Offset pos, {
    double env = 1.0,
    double time = 0,
    double seed = 0,
  }) {
    if (env <= 0) return;
    final pulse = 1.0 + 0.12 * math.sin(time * 9 + seed * math.pi * 2);
    final r = (13.0 + seed * 6.0) * env * pulse;

    // Outer halo.
    final halo = Paint()
      ..color = _kAccent.withValues(alpha: 0.35 * env)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(pos, r * 1.9, halo);

    // Glowing body.
    final body = Paint()
      ..color = _kAccent.withValues(alpha: 0.95 * env)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(pos, r, body);

    // White-hot core.
    final core = Paint()..color = Colors.white.withValues(alpha: 0.95 * env);
    canvas.drawCircle(pos, r * 0.42, core);

    // Tiny orbiting flecks for richness.
    final fleck = Paint()..color = Colors.white.withValues(alpha: 0.7 * env);
    for (var i = 0; i < 3; i++) {
      final a = time * (2.5 + i) + seed * 10 + i * 2.1;
      final fr = r * (1.35 + 0.25 * i);
      canvas.drawCircle(
        pos + Offset(math.cos(a) * fr, math.sin(a) * fr),
        1.6,
        fleck,
      );
    }
  }

  /// One red antimatter orb: red halo, jagged spinning star, warning ring,
  /// dark anti-core.
  static void antimatter(
    Canvas canvas,
    Offset pos, {
    double env = 1.0,
    double time = 0,
    double seed = 0,
  }) {
    if (env <= 0) return;
    final spin = time * 1.8 + seed * math.pi * 2;
    final r = (15.0 + seed * 5.0) * env;

    // Red halo.
    final halo = Paint()
      ..color = _kAnti.withValues(alpha: 0.30 * env)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(pos, r * 1.7, halo);

    // Jagged star polygon.
    final path = Path();
    const points = 8;
    for (var i = 0; i <= points * 2; i++) {
      final a = spin + i * math.pi / points;
      final rad = i.isEven ? r : r * 0.55;
      final pt = pos + Offset(math.cos(a) * rad, math.sin(a) * rad);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = _kAnti.withValues(alpha: 0.85 * env),
    );

    // Warning ring.
    canvas.drawCircle(
      pos,
      r * 1.35,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kAnti.withValues(alpha: 0.6 * env),
    );

    // Dark anti-core.
    canvas.drawCircle(
      pos,
      r * 0.4,
      Paint()..color = Colors.black.withValues(alpha: 0.9 * env),
    );
  }

  /// The catch/hit burst: expanding ring + radiating particles. [t] 0..1.
  static void burst(
    Canvas canvas,
    Offset pos, {
    required double t,
    required Color color,
    double seed = 0,
  }) {
    final fade = (1.0 - t);

    // Expanding ring.
    canvas.drawCircle(
      pos,
      12 + 52 * Curves.easeOut.transform(t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * fade + 0.5
        ..color = color.withValues(alpha: 0.8 * fade),
    );

    // Radiating particles.
    final paint = Paint();
    const count = 10;
    for (var i = 0; i < count; i++) {
      final a = seed * math.pi * 2 + i * math.pi * 2 / count;
      final dist = 10 + 46 * Curves.easeOut.transform(t);
      final wobble = 1.0 + 0.3 * math.sin(seed * 20 + i * 3.0);
      final pt = pos + Offset(math.cos(a) * dist * wobble, math.sin(a) * dist);
      paint.color =
          (i.isEven ? color : Colors.white).withValues(alpha: 0.9 * fade);
      canvas.drawCircle(pt, 2.4 * fade + 0.4, paint);
    }
  }

  /// One drifting star-dust mote.
  static void star(Canvas canvas, Offset pos, double size, double twinkle) {
    canvas.drawCircle(
      pos,
      size,
      Paint()..color = Colors.white.withValues(alpha: twinkle),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same _BigBangArt the live game uses).
// ═══════════════════════════════════════════════════════════════════════════

/// The void backdrop shared by every card: black with the faint warm breath at
/// center, plus a scatter of star dust. Guards degenerate sizes.
void _legendVoid(Canvas canvas, Size size, {int starCount = 14}) {
  final bgPaint = Paint()
    ..shader = RadialGradient(
      colors: [_kAccent.withValues(alpha: 0.06), Colors.black],
      stops: const [0.0, 1.0],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.longestSide * 0.7,
      ),
    );
  canvas.drawRect(Offset.zero & size, bgPaint);

  final rng = math.Random(7);
  for (var i = 0; i < starCount; i++) {
    _BigBangArt.star(
      canvas,
      Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
      0.6 + rng.nextDouble() * 1.4,
      0.25 + rng.nextDouble() * 0.35,
    );
  }
}

/// Card 1 — the verb: a fresh matter spark to tap, next to one fading away.
void _legendTapMatter(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);

  // A fresh, fully-alive spark with a tap ring around it.
  final fresh = Offset(size.width * 0.36, size.height * 0.44);
  _BigBangArt.matter(canvas, fresh, env: 1.0, time: 1.3, seed: 0.7);
  canvas.drawCircle(
    fresh,
    36,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.75),
  );
  GameFx.text(canvas, 'TAP!', fresh.translate(0, 52), 12, Colors.white,
      weight: FontWeight.w800);

  // The same spark late in life, slipping back into the void.
  final fading = Offset(size.width * 0.74, size.height * 0.58);
  _BigBangArt.matter(canvas, fading, env: 0.30, time: 2.1, seed: 0.2);
  GameFx.text(canvas, 'fading...', fading.translate(0, 30), 11,
      Colors.white.withValues(alpha: 0.5));
}

/// Card 2 — scoring: the catch burst plus the streak combo badge.
void _legendCombo(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);

  // A spark mid-catch: golden burst + score popup.
  final hit = Offset(size.width * 0.34, size.height * 0.52);
  _BigBangArt.burst(canvas, hit, t: 0.35, color: _kAccent, seed: 0.4);
  GameFx.text(canvas, '+50', hit.translate(0, -46), 20,
      const Color(0xFFFFD54F),
      weight: FontWeight.w800, glow: 0.8);

  // The combo badge from the top-right of the live game.
  final badge = Rect.fromCenter(
    center: Offset(size.width * 0.70, size.height * 0.36),
    width: 108,
    height: 34,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(badge, const Radius.circular(14)),
    Paint()..color = Colors.black.withValues(alpha: 0.55),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(badge, const Radius.circular(14)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kAccent.withValues(alpha: 0.7),
  );
  GameFx.text(canvas, '×5', badge.center.translate(-30, 0), 17, _kAccent,
      weight: FontWeight.w800);
  GameFx.text(canvas, '13 streak', badge.center.translate(16, 1), 11,
      Colors.white.withValues(alpha: 0.7),
      weight: FontWeight.w700);

  // A next spark waiting to keep the chain alive.
  _BigBangArt.matter(canvas,
      Offset(size.width * 0.72, size.height * 0.70),
      env: 1.0, time: 0.6, seed: 0.3);
}

/// Card 3 — the danger: the red antimatter orb and its penalty.
void _legendAntimatter(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size);

  final anti = Offset(size.width * 0.5, size.height * 0.44);
  _BigBangArt.antimatter(canvas, anti, env: 1.0, time: 0.9, seed: 0.5);
  _BigBangArt.burst(canvas, anti, t: 0.55, color: _kAnti, seed: 0.8);
  GameFx.text(canvas, '-15', anti.translate(0, -56), 20, _kAnti,
      weight: FontWeight.w800, glow: 0.8);
  GameFx.text(canvas, 'streak lost', anti.translate(0, 58), 12,
      _kAnti.withValues(alpha: 0.85),
      weight: FontWeight.w700);
}

/// Card 4 — the escalation: late-game waves flood the void with sparks.
void _legendWaves(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendVoid(canvas, size, starCount: 26);

  final rng = math.Random(3);
  for (var i = 0; i < 7; i++) {
    final pos = Offset(
      size.width * (0.14 + rng.nextDouble() * 0.72),
      size.height * (0.18 + rng.nextDouble() * 0.60),
    );
    _BigBangArt.matter(canvas, pos,
        env: 0.55 + rng.nextDouble() * 0.45,
        time: rng.nextDouble() * 3,
        seed: rng.nextDouble());
  }
  // One antimatter hiding in the flood.
  _BigBangArt.antimatter(canvas,
      Offset(size.width * 0.62, size.height * 0.62),
      env: 0.9, time: 1.4, seed: 0.35);
  GameFx.text(canvas, 'WAVE ×8', Offset(size.width * 0.5, size.height * 0.88),
      12, _kAccent.withValues(alpha: 0.9),
      weight: FontWeight.w800);
}

/// The visual manual for Big Bang — wired into the registry spec.
final List<LegendFrame> bigBangLegendFrames = [
  const LegendFrame(
      caption: 'Tap gold matter sparks before they fade away',
      paint: _legendTapMatter),
  const LegendFrame(
      caption: 'Chain catches — streaks build up to a ×5 combo',
      paint: _legendCombo),
  const LegendFrame(
      caption: 'Never tap red antimatter: −15 and streak lost',
      paint: _legendAntimatter),
  const LegendFrame(
      caption: 'Late game floods in waves — catch what you can',
      paint: _legendWaves),
];
