import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// NEPHRON — run the kidney's filter (60 s score attack, BioScale.organ).
///
/// Blood streams down the nephron's tubule. The player SORTS each molecule:
///   • REABSORB the good stuff (glucose, water, amino acids, needed ions) back
///     into the BLOOD  →  flick it LEFT (tap on its left side).
///   • Let WASTE (urea, toxins, excess salt) leave in the URINE  →  flick it
///     RIGHT (tap on its right side), or simply let it fall out the bottom.
///
/// The teaching is IN the mechanic: the tubule's default is "everything leaves
/// in the urine" — *reabsorption is the active, selective step*. Keeping waste
/// in the blood (or dumping a nutrient to urine) costs score and BLOOD PURITY.
/// It accelerates: faster flow, more molecule types, and subtle calls (needed
/// sodium vs. *excess* sodium look identical — you must read the label).
///
/// PERF: ONE Ticker → ONE CustomPainter. No per-frame setState over a tree;
/// the painter repaints off a [Listenable]. (Reference: arcade/hungry_cell.dart.)

// ─── Tuning ────────────────────────────────────────────────────────────────
const double _kSpawnEarly = 1.15; // s between spawns at t=0
const double _kSpawnPeak = 0.46; // s between spawns at t=duration
const double _kFallEarly = 78.0; // px/s descent at t=0
const double _kFallPeak = 168.0; // px/s descent at t=duration
const double _kGrabRadius = 72.0; // tap pickup radius
const double _kMolR = 21.0; // molecule body radius

const int _kCorrect = 10; // base points for a correct call
const int _kMissWaste = 2; // waste that passively exits in urine
const int _kPenaltyBig = 15; // keeping WASTE in the blood
const int _kPenaltySmall = 8; // dumping a NUTRIENT to urine
const int _kPenaltyMiss = 5; // a nutrient lost out the bottom

const double _kHealthRegen = 0.035; // per correct call
const double _kHealthWasteInBlood = 0.22; // keeping waste in blood
const double _kHealthLostNutrient = 0.10; // dumping a nutrient
const double _kHealthMissNutrient = 0.06; // nutrient out the bottom

// Renal palette
const _kBlood = Color(0xFFE0556B); // peritubular capillary (keep side)
const _kUrine = Color(0xFFC8A23A); // collecting duct (discard side)

// ─── Molecule kinds ──────────────────────────────────────────────────────────
class _Mol {
  final String symbol; // drawn inside the orb
  final String name; // small label below (load-bearing for subtle calls)
  final bool waste; // true → belongs in urine
  final Color color;
  const _Mol(this.symbol, this.name, this.waste, this.color);
}

// Level 1 pool — clear calls, distinct colors.
const _goodBase = [
  _Mol('Glu', 'Glucose', false, Color(0xFFE1C916)),
  _Mol('H₂O', 'Water', false, Color(0xFF6FB7D6)),
  _Mol('AA', 'Amino acid', false, Color(0xFF8FD18A)),
  _Mol('Na⁺', 'Sodium', false, Color(0xFF63C2BE)),
];
const _wasteBase = [
  _Mol('Urea', 'Urea', true, Color(0xFFB07A4B)),
  _Mol('Cr', 'Creatinine', true, Color(0xFF9C6B5A)),
  _Mol('Tox', 'Toxin', true, Color(0xFFE05B5B)),
];

// Level 2 — more types.
const _goodL2 = [
  _Mol('K⁺', 'Potassium', false, Color(0xFF9DB86F)),
  _Mol('HCO₃', 'Bicarbonate', false, Color(0xFF7FB0C9)),
];
const _wasteL2 = [
  _Mol('UA', 'Uric acid', true, Color(0xFFC98A3A)),
  _Mol('NH₃', 'Ammonia', true, Color(0xFF8A9B5C)),
];

// Level 3+ — subtle calls. "Excess" sodium is identical in symbol AND colour to
// needed sodium; only the label gives it away — the kidney really does discard
// surplus ions while reabsorbing the amount the body needs.
const _subtleL3 = [
  _Mol('Na⁺', 'Sodium · EXCESS', true, Color(0xFF63C2BE)),
  _Mol('Rx', 'Drug metabolite', true, Color(0xFFB55BD0)),
];

List<_Mol> _poolFor(int level) {
  final p = <_Mol>[..._goodBase, ..._wasteBase];
  if (level >= 2) p.addAll([..._goodL2, ..._wasteL2]);
  if (level >= 3) p.addAll(_subtleL3);
  return p;
}

// ─── Live molecule ───────────────────────────────────────────────────────────
class _Drop {
  Offset pos;
  final _Mol mol;
  double wobble;
  bool committed = false; // routed by the player → zipping to a gutter
  int zipDir = 0; // -1 blood, +1 urine
  double zipT = 0; // 0→1 zip animation
  double targetX = 0;
  _Drop(this.pos, this.mol, this.wobble);
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class NephronGame extends StatefulWidget {
  final MiniGameSession session;
  const NephronGame({super.key, required this.session});

  @override
  State<NephronGame> createState() => _NephronGameState();
}

class _NephronGameState extends State<NephronGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  bool _ready = false;
  bool _wasRunning = false;

  double _time = 0;
  Duration _last = Duration.zero;

  final List<_Drop> _drops = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _spawnTimer = 0;
  double _health = 1.0;
  int _streak = 0;
  double _flash = 0; // red flash on a bad call
  double _flashGood = 0; // green flash on a good call

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── Geometry ─────────────────────────────────────────────────────────────
  double get _tubuleLeft => _size.width * 0.27;
  double get _tubuleRight => _size.width * 0.73;
  double get _bloodX => _size.width * 0.12;
  double get _urineX => _size.width * 0.88;
  double get _spawnY => _size.height * 0.13;
  double get _exitY => _size.height * 0.93;

  // ─── Progress / difficulty ──────────────────────────────────────────────────
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final elapsed = dur - widget.session.remaining.inMilliseconds / 1000.0;
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  int get _level => (1 + (_progress * 5)).floor().clamp(1, 5);

  // ─── Tick ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (_ready) {
      if (running) {
        _update(dt);
      } else {
        _idle(dt);
      }
    }
    _repaint.tick();
  }

  void _startRun() {
    _drops.clear();
    _particles.clear();
    _pops.clear();
    _spawnTimer = 0.4;
    _health = 1.0;
    _streak = 0;
    _flash = 0;
    _flashGood = 0;
  }

  // Calm ready/finished state: a few molecules drift gently, nothing scores.
  void _idle(double dt) {
    if (_drops.length < 5 && _rng.nextDouble() < dt * 0.8) {
      _drops.add(_Drop(
        Offset(_tubuleLeft + _rng.nextDouble() * (_tubuleRight - _tubuleLeft),
            _spawnY - 30),
        _poolFor(2)[_rng.nextInt(_poolFor(2).length)],
        _rng.nextDouble() * math.pi * 2,
      ));
    }
    for (final d in _drops) {
      d.wobble += dt * 1.5;
      d.pos = Offset(d.pos.dx, d.pos.dy + 26 * dt);
    }
    _drops.removeWhere((d) => d.pos.dy > _exitY + 20);
    _stepFx(dt);
  }

  void _update(double dt) {
    final session = widget.session;
    final progress = _progress;
    final fall = _kFallEarly + (_kFallPeak - _kFallEarly) * progress;
    final interval = _kSpawnEarly + (_kSpawnPeak - _kSpawnEarly) * progress;
    final pool = _poolFor(_level);

    // Spawn
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = interval * (0.8 + _rng.nextDouble() * 0.4);
      _drops.add(_Drop(
        Offset(_tubuleLeft + 14 + _rng.nextDouble() * (_tubuleRight - _tubuleLeft - 28),
            _spawnY - 24),
        pool[_rng.nextInt(pool.length)],
        _rng.nextDouble() * math.pi * 2,
      ));
    }

    // Advance drops
    _drops.removeWhere((d) {
      d.wobble += dt * 3.2;
      if (d.committed) {
        d.zipT += dt * 3.4;
        d.pos = Offset(
          _lerp(d.pos.dx, d.targetX, (dt * 9).clamp(0.0, 1.0)),
          d.pos.dy + fall * 0.25 * dt,
        );
        return d.zipT >= 1.0;
      }
      d.pos = Offset(d.pos.dx, d.pos.dy + fall * dt);
      // Reached the bottom unsorted → passively exits in URINE.
      if (d.pos.dy >= _exitY) {
        if (d.mol.waste) {
          session.addScore(_kMissWaste);
          _pops.add(FxPop(d.pos, '+$_kMissWaste', _kUrine.withValues(alpha: 0.9)));
        } else {
          session.addScore(-_kPenaltyMiss);
          _streak = 0;
          _health = (_health - _kHealthMissNutrient).clamp(0.0, 1.0);
          _flash = 0.5;
          _pops.add(FxPop(d.pos, 'LOST', _kBlood));
        }
        return true;
      }
      return false;
    });

    if (_health <= 0) {
      session.endEarly(); // filter failure — the round ends
      return;
    }

    if (_flash > 0) _flash = math.max(0, _flash - dt * 1.6);
    if (_flashGood > 0) _flashGood = math.max(0, _flashGood - dt * 2.2);
    _stepFx(dt);
  }

  void _stepFx(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  double get _mult => (1 + _streak * 0.1).clamp(1.0, 3.0);

  // ─── Routing (the sort) ─────────────────────────────────────────────────────
  void _route(_Drop d, int dir) {
    final session = widget.session;
    d.committed = true;
    d.zipDir = dir;
    d.zipT = 0;
    d.targetX = dir < 0 ? _bloodX : _urineX;
    final toBlood = dir < 0;
    final good = !d.mol.waste;

    if (toBlood && good) {
      // Correct reabsorption.
      final gain = (_kCorrect * _mult).round();
      session.addScore(gain);
      _streak++;
      session.noteStreak(_streak);
      _health = (_health + _kHealthRegen).clamp(0.0, 1.0);
      _flashGood = 0.5;
      _pops.add(FxPop(d.pos, '+$gain', _kBlood.withValues(alpha: 1)));
      _particles.addAll(FxBurst.spawn(d.pos, d.mol.color, count: 12, speed: 110));
    } else if (!toBlood && !good) {
      // Correct excretion.
      final gain = (_kCorrect * _mult).round();
      session.addScore(gain);
      _streak++;
      session.noteStreak(_streak);
      _health = (_health + _kHealthRegen).clamp(0.0, 1.0);
      _flashGood = 0.5;
      _pops.add(FxPop(d.pos, '+$gain', _kUrine.withValues(alpha: 1)));
      _particles.addAll(FxBurst.spawn(d.pos, d.mol.color, count: 12, speed: 110));
    } else if (toBlood && !good) {
      // Waste kept in the blood — the worst call.
      session.addScore(-_kPenaltyBig);
      _streak = 0;
      _health = (_health - _kHealthWasteInBlood).clamp(0.0, 1.0);
      _flash = 0.6;
      _pops.add(FxPop(d.pos, 'WASTE IN BLOOD', _kBlood));
      _particles.addAll(FxBurst.spawn(d.pos, _kBlood, count: 16, speed: 150));
    } else {
      // Nutrient dumped to urine.
      session.addScore(-_kPenaltySmall);
      _streak = 0;
      _health = (_health - _kHealthLostNutrient).clamp(0.0, 1.0);
      _flash = 0.5;
      _pops.add(FxPop(d.pos, 'NUTRIENT LOST', _kUrine));
      _particles.addAll(FxBurst.spawn(d.pos, _kUrine, count: 14, speed: 130));
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.session.isRunning) return;
    final p = details.localPosition;
    _Drop? best;
    double bestD = _kGrabRadius;
    for (final d in _drops) {
      if (d.committed) continue;
      final dist = (d.pos - p).distance;
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    if (best != null) {
      // Flick: tapping LEFT of the molecule sends it to blood, RIGHT to urine.
      final dir = p.dx < best.pos.dx ? -1 : 1;
      _route(best, dir);
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if ((_size.width - size.width).abs() > 1 ||
          (_size.height - size.height).abs() > 1) {
        _size = size;
      }
      _ready = _size.width > 0 && _size.height > 0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _NephronPainter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _NephronPainter extends CustomPainter {
  final _NephronGameState state;
  _NephronPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  static const _accent = Color(0xFFC65A6E);

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._ready) return;
    final t = state._time;
    final running = state.widget.session.isRunning;

    GameFx.atmosphere(canvas, size, _accent, t, motes: 24);
    _paintGutters(canvas, size, t);
    _paintTubule(canvas, size, t);
    _paintGlomerulus(canvas, size, t);

    for (final d in state._drops) {
      _paintDrop(canvas, d, t, running);
    }
    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    _paintHud(canvas, size);

    // Bad/good call screen flash.
    if (state._flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBlood.withValues(alpha: 0.16 * state._flash));
    }
    if (state._flashGood > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFF6BD089)
                .withValues(alpha: 0.10 * state._flashGood));
    }

    if (!running) _paintReady(canvas, size, t);
  }

  // ── Left blood vessel / right urine duct gutters ─────────────────────────────
  void _paintGutters(Canvas canvas, Size size, double t) {
    void gutter(double cx, Color c, String label, bool down) {
      final rect = Rect.fromLTWH(cx - size.width * 0.11, 0,
          size.width * 0.22, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.withValues(alpha: 0.05), c.withValues(alpha: 0.20)],
          ).createShader(rect),
      );
      // flow streaks
      final p = Paint()
        ..color = c.withValues(alpha: 0.16)
        ..strokeWidth = 2;
      for (var i = 0; i < 7; i++) {
        final phase = (t * 40 + i * 90) % size.height;
        final y = down ? phase : size.height - phase;
        canvas.drawLine(Offset(cx - 10, y), Offset(cx + 10, y + 14), p);
      }
      GameFx.text(canvas, label, Offset(cx, size.height * 0.5), 12,
          c.withValues(alpha: 0.85),
          weight: FontWeight.w800);
    }

    gutter(state._bloodX, _kBlood, 'BLOOD', false);
    gutter(state._urineX, _kUrine, 'URINE', true);
  }

  // ── Central nephron tubule with downward blood flow ──────────────────────────
  void _paintTubule(Canvas canvas, Size size, double t) {
    final l = state._tubuleLeft, r = state._tubuleRight;
    final rect = Rect.fromLTRB(l, size.height * 0.08, r, size.height * 0.97);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withValues(alpha: 0.14),
            _accent.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _accent.withValues(alpha: 0.45),
    );
    // Flowing plasma stripes.
    canvas.save();
    canvas.clipRRect(rr);
    final flow = Paint()..color = Colors.white.withValues(alpha: 0.045);
    for (var i = 0; i < 14; i++) {
      final y = (t * 70 + i * (size.height / 14)) % (size.height + 40) +
          size.height * 0.08 - 20;
      canvas.drawRect(Rect.fromLTWH(l, y, r - l, 6), flow);
    }
    canvas.restore();
  }

  void _paintGlomerulus(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.5, size.height * 0.085);
    // coiled capillary ball
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = _kBlood.withValues(alpha: 0.6);
    for (var i = 0; i < 5; i++) {
      final rad = 9.0 + i * 3.5;
      canvas.drawCircle(c.translate(math.sin(t + i) * 2, 0), rad, p);
    }
    GameFx.orb(canvas, c, 7, _kBlood, glow: 1.2);
    GameFx.text(canvas, 'GLOMERULUS', c.translate(0, -22), 10,
        Potatuhs.textSecondary,
        weight: FontWeight.w700);
  }

  // ── A molecule ───────────────────────────────────────────────────────────────
  void _paintDrop(Canvas canvas, _Drop d, double t, bool running) {
    final wob = Offset(math.sin(d.wobble) * 2.2, math.cos(d.wobble * 0.8) * 1.4);
    final pos = d.pos + wob;
    var alpha = 1.0;
    var r = _kMolR;
    if (d.committed) {
      alpha = (1.0 - d.zipT).clamp(0.0, 1.0);
      r = _kMolR * (1.0 - 0.3 * d.zipT);
    }
    if (!running) alpha *= 0.6;

    // urgency ring near the bottom
    if (!d.committed && running && d.pos.dy > state._exitY - 90) {
      canvas.drawCircle(
        pos,
        r + 6 + 2 * math.sin(t * 9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kBlood.withValues(alpha: 0.5),
      );
    }

    GameFx.orb(canvas, pos, r, d.mol.color.withValues(alpha: alpha),
        glow: alpha);
    GameFx.text(canvas, d.mol.symbol, pos, 12,
        Colors.white.withValues(alpha: alpha),
        weight: FontWeight.w800);
    // label below — load-bearing for the subtle "EXCESS" calls
    GameFx.text(canvas, d.mol.name, pos.translate(0, r + 9), 9,
        Potatuhs.textSecondary.withValues(alpha: 0.85 * alpha),
        weight: FontWeight.w600);
  }

  // ── HUD: blood purity + level + streak ───────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    // Blood-purity bar (bottom-left, away from host's score/timer).
    const barW = 150.0, barH = 9.0;
    final bx = 16.0, by = size.height - 30.0;
    final bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, barW, barH), const Radius.circular(5));
    canvas.drawRRect(bg, Paint()..color = Colors.black.withValues(alpha: 0.45));
    final fillW = barW * state._health.clamp(0.0, 1.0);
    final hue = Color.lerp(_kBlood, const Color(0xFF6BD089), state._health)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, fillW, barH), const Radius.circular(5)),
      Paint()..color = hue,
    );
    GameFx.text(canvas, 'BLOOD PURITY', Offset(bx + barW / 2, by - 9), 9,
        Potatuhs.textSecondary,
        weight: FontWeight.w700);

    // Level + streak multiplier (bottom-right).
    final mult = state._mult;
    final label = 'LV${state._level}'
        '${mult > 1.0 ? '   ×${mult.toStringAsFixed(1)}' : ''}';
    GameFx.text(canvas, label, Offset(size.width - 60, by + 4), 13,
        mult > 1.0 ? Potatuhs.gold : Potatuhs.textSecondary,
        weight: FontWeight.w800, glow: mult > 1.0 ? 0.5 : 0);
  }

  // ── Calm ready / finished overlay ────────────────────────────────────────────
  void _paintReady(Canvas canvas, Size size, double t) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.32));
    GameFx.text(canvas, 'NEPHRON', Offset(size.width / 2, size.height * 0.40),
        34, Potatuhs.textPrimary,
        display: true, glow: 0.4);
    GameFx.text(
        canvas,
        'Reabsorb the good · let waste pass',
        Offset(size.width / 2, size.height * 0.40 + 30),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w600);
    final pulse = 0.5 + 0.5 * math.sin(t * 2.4);
    GameFx.text(
        canvas,
        'Tap LEFT of a molecule → BLOOD   ·   RIGHT → URINE',
        Offset(size.width / 2, size.height * 0.40 + 54),
        11,
        Potatuhs.textFaint.withValues(alpha: 0.6 + 0.4 * pulse),
        weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _NephronPainter oldDelegate) => false;
}
