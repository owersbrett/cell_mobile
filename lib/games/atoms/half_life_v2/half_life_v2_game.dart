import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ── Feel constants ───────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely.

const int _kN = 36; // atoms in the (uncountable) glow cloud

/// Halvings to hit per sample: 50% → 25% → 12.5%. Each beat is the *same* time
/// (one half-life) apart — that constant interval is the lesson AND the skill.
const int _kBeats = 3;

/// Base points for a beat, scaled by timing accuracy.
const int _kBeatPts = 60;

/// Bonus for nailing a beat dead-on (error under [_kPerfectErr] half-lives).
const int _kPerfectBonus = 30;

/// Error (in half-lives) at which a beat scores zero.
const double _kTol = 0.7;

/// "Good enough" error — keeps/extends the streak.
const double _kGoodErr = 0.20;

/// "Excellent" error — earns the perfect bonus.
const double _kPerfectErr = 0.08;

/// Brief flourish between samples (lets the last beat read), then the next —
/// faster — sample spawns. No long reveal pause: pace stays high.
const double _kInterSample = 0.45;

/// How long a per-tap hit flash lingers.
const double _kFlashTime = 0.7;

// Radioactive isotope palette.
const Color _kAccent = Color(0xFF7DFB5A);
const Color _kGood = Color(0xFF69F0AE);
const Color _kWarn = Color(0xFFFF6E40);
const Color _kWhite = Colors.white;

/// "Half-Life v2" — a UX-passed rebuild of Half-Life.
///
/// A radioactive sample decays in front of you as a **deliberately fuzzy glow
/// cloud** — there is no atom counter to read, so you must *estimate the
/// fraction from feel*. Each sample asks for three measurements in a row at
/// 50%, 25%, 12.5%. The catch (and the lesson): each halving takes the **same**
/// amount of time, so once you nail the first beat you can ride the rhythm for
/// the next two. Closer taps = more points; samples get faster, building to a
/// fast triple-tap climax. Teaches exponential decay and the constant-time
/// half-life: 100 → 50 → 25 → 12.5 %.
class HalfLifeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HalfLifeV2Game({super.key, required this.session});

  @override
  State<HalfLifeV2Game> createState() => _HalfLifeV2GameState();
}

class _HalfLifeV2GameState extends State<HalfLifeV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // Even, uncountable fill positions for the cloud (golden-angle disc).
  late final List<Offset> _unit = _spiral(_kN);

  // ── Run state ──
  bool _started = false;
  int _sample = 0;
  double _hl = 2.3; // seconds per halving for the current sample

  double _t = 0.0; // seconds elapsed in the current sample
  double _frac = 1.0; // theoretical fraction still radioactive (2^-(t/hl))
  final List<double> _th = List.filled(_kN, 0.0); // per-atom decay thresholds
  final List<bool> _alive = List.filled(_kN, true);

  int _nextBeat = 0; // which halving we're hunting (0,1,2)
  final List<double?> _capN = List.filled(_kBeats, null); // captured half-lives
  final List<int> _capQ = List.filled(_kBeats, 0); // captured quality 0/1/2
  double _interTimer = 0.0; // >0 → in the between-sample flourish

  // Per-tap hit flash.
  int _flashQ = 0;
  int _flashPts = 0;
  double _flashAge = _kFlashTime + 1;

  int _streak = 0;
  double _idle = 0.0;
  Size _size = Size.zero;
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  double get _capElapsed => (_kBeats + 0.9) * _hl;
  double get _curN => _t / _hl;

  static List<Offset> _spiral(int n) {
    final golden = math.pi * (3 - math.sqrt(5));
    return [
      for (var i = 0; i < n; i++)
        Offset(
          math.sqrt((i + 0.5) / n) * math.cos(i * golden),
          math.sqrt((i + 0.5) / n) * math.sin(i * golden),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _startSample();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startSample() {
    _hl = math.max(1.0, 2.3 - 0.16 * _sample);
    _t = 0.0;
    _frac = 1.0;
    _nextBeat = 0;
    _interTimer = 0.0;
    for (var i = 0; i < _kN; i++) {
      _th[i] = _rng.nextDouble();
      _alive[i] = true;
    }
    for (var b = 0; b < _kBeats; b++) {
      _capN[b] = null;
      _capQ[b] = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _idle += dt;
    _flashAge += dt;

    final running = widget.session.isRunning;

    if (running && !_started) {
      _started = true;
      _sample = 0;
      _streak = 0;
      _startSample();
    }

    if (running && _started) {
      if (_interTimer > 0) {
        _interTimer -= dt;
        if (_interTimer <= 0) {
          _sample++;
          _startSample();
        }
      } else {
        _t += dt;
        _frac = math.pow(0.5, _t / _hl).toDouble();
        _decayAtoms();
        if (_nextBeat >= _kBeats) {
          _interTimer = _kInterSample;
        } else if (_t >= _capElapsed) {
          // Player let the sample run out → auto-miss remaining beats.
          while (_nextBeat < _kBeats) {
            _capN[_nextBeat] = _curN;
            _capQ[_nextBeat] = 0;
            _nextBeat++;
          }
          _interTimer = _kInterSample;
        }
      }
    }

    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _decayAtoms() {
    if (_size == Size.zero) return;
    for (var i = 0; i < _kN; i++) {
      final shouldLive = _frac > _th[i];
      if (_alive[i] && !shouldLive) {
        _alive[i] = false;
        _sparks.addAll(
            FxBurst.spawn(_cloudCenter(_size, i), _kAccent, count: 5, speed: 60, size: 2));
      }
    }
  }

  void _tap() {
    if (!widget.session.isRunning || !_started) return;
    if (_interTimer > 0 || _nextBeat >= _kBeats) return;

    final b = _nextBeat;
    final err = (_curN - (b + 1)).abs();
    final base = (_kBeatPts * (1 - err / _kTol)).round().clamp(0, _kBeatPts);
    final perfect = err < _kPerfectErr;
    final pts = perfect ? base + _kPerfectBonus : base;
    final q = perfect ? 2 : (err < _kGoodErr ? 1 : 0);

    _capN[b] = _curN;
    _capQ[b] = q;
    _flashQ = q;
    _flashPts = pts;
    _flashAge = 0;

    if (pts > 0) {
      widget.session.addScore(pts);
      final c = _size == Size.zero
          ? Offset.zero
          : Offset(_size.width / 2, _size.height * 0.30);
      _pops.add(FxPop(c, '+$pts', perfect ? _kAccent : _kGood));
      _sparks.addAll(FxBurst.spawn(c, perfect ? _kAccent : _kGood,
          count: perfect ? 14 : 8, speed: 110, size: 3));
    }

    if (err < _kGoodErr) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    _nextBeat++;
  }

  static Offset _cloudCenter(Size size, int i) {
    final c = Offset(size.width / 2, size.height * 0.30);
    final r = math.min(size.width * 0.34, size.height * 0.155);
    final u = _spiral(_kN)[i];
    return c + u * r;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tap(),
        child: CustomPaint(
          size: _size,
          painter: _HalfLifeV2Painter(
            unit: _unit,
            hl: _hl,
            sample: _sample,
            frac: _frac,
            alive: _alive,
            nextBeat: _nextBeat,
            capN: _capN,
            capQ: _capQ,
            inter: _interTimer > 0,
            flashQ: _flashQ,
            flashPts: _flashPts,
            flashAge: _flashAge,
            streak: _streak,
            idle: _idle,
            started: _started,
            running: widget.session.isRunning,
            sparks: _sparks,
            pops: _pops,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HalfLifeV2Painter extends CustomPainter {
  final List<Offset> unit;
  final double hl;
  final int sample;
  final double frac;
  final List<bool> alive;
  final int nextBeat;
  final List<double?> capN;
  final List<int> capQ;
  final bool inter;
  final int flashQ;
  final int flashPts;
  final double flashAge;
  final int streak;
  final double idle;
  final bool started;
  final bool running;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _HalfLifeV2Painter({
    required this.unit,
    required this.hl,
    required this.sample,
    required this.frac,
    required this.alive,
    required this.nextBeat,
    required this.capN,
    required this.capQ,
    required this.inter,
    required this.flashQ,
    required this.flashPts,
    required this.flashAge,
    required this.streak,
    required this.idle,
    required this.started,
    required this.running,
    required this.sparks,
    required this.pops,
  });

  static double _targetFrac(int beat) => math.pow(0.5, beat + 1).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, idle, motes: 24);
    _paintHeader(canvas, size);
    _paintCloud(canvas, size);
    FxBurst.paint(canvas, sparks);
    _paintCurve(canvas, size);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintFlash(canvas, size);
    _paintTapHint(canvas, size);
    if (!started || !running) _paintReady(canvas, size);
  }

  // ── Prompt header ──
  void _paintHeader(Canvas canvas, Size size) {
    if (!started) return;
    GameFx.text(
      canvas,
      'SAMPLE ${sample + 1}   ·   t½ ${hl.toStringAsFixed(1)}s',
      Offset(size.width / 2, size.height * 0.05),
      12,
      Potatuhs.textSecondary,
      weight: FontWeight.w700,
    );

    // The live callout: which halving are we hunting?
    if (nextBeat < _kBeats && !inter) {
      final pct = (_targetFrac(nextBeat) * 100);
      final label = pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
      final pulse = 0.78 + 0.22 * (0.5 + 0.5 * math.sin(idle * 5));
      GameFx.text(
        canvas,
        'FIND  $label%',
        Offset(size.width / 2, size.height * 0.105),
        26,
        _kAccent.withValues(alpha: pulse),
        display: true,
        glow: 0.6,
      );
    } else {
      GameFx.text(
        canvas,
        'NEXT SAMPLE…',
        Offset(size.width / 2, size.height * 0.105),
        22,
        Potatuhs.textFaint,
        display: true,
      );
    }
    GameFx.text(
      canvas,
      'feel the glow — no counting',
      Offset(size.width / 2, size.height * 0.145),
      11,
      Potatuhs.textFaint,
    );

    if (streak >= 2) {
      GameFx.text(
        canvas,
        '🔥 $streak',
        Offset(size.width * 0.86, size.height * 0.05),
        15,
        _kWarn,
        weight: FontWeight.w800,
      );
    }
  }

  // ── The fuzzy glow cloud (no countable grid, no integer) ──
  void _paintCloud(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.30);
    final r = math.min(size.width * 0.34, size.height * 0.155);
    final blob = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);

    // Soft containment halo so the mass reads as one cloud, not dots.
    if (started) {
      canvas.drawCircle(
        center,
        r * 1.35,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.05 * frac + 0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }

    final breathe = 0.94 + 0.06 * math.sin(idle * 1.8);
    for (var i = 0; i < _kN; i++) {
      if (!alive[i] && started) continue;
      final wobble = Offset(
        math.sin(idle * 1.1 + i) * r * 0.03,
        math.cos(idle * 1.3 + i * 1.7) * r * 0.03,
      );
      final p = center + unit[i] * r * breathe + wobble;
      // Overlapping blurred blobs with no rim/specular → uncountable mass.
      canvas.drawCircle(p, r * 0.20, blob..color = _kAccent.withValues(alpha: 0.42));
      canvas.drawCircle(
          p, r * 0.10, Paint()..color = _kWhite.withValues(alpha: 0.22));
    }
  }

  // ── The exponential decay curve + target rings (the teaching surface) ──
  void _paintCurve(Canvas canvas, Size size) {
    if (!started) return;
    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final top = size.height * 0.52;
    final bot = size.height * 0.82;
    final maxN = _kBeats + 0.9;

    double xAt(double n) => left + (right - left) * (n / maxN);
    double yAt(double f) => bot - (bot - top) * f;

    // Axes.
    final axis = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, top), Offset(left, bot), axis);
    canvas.drawLine(Offset(left, bot), Offset(right, bot), axis);

    // Half-life gridlines.
    final grid = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var n = 1; n <= maxN.ceil(); n++) {
      final x = xAt(n.toDouble());
      if (x > right) break;
      canvas.drawLine(Offset(x, top), Offset(x, bot), grid);
    }

    // The 2^-n curve (the shape — but NO live cursor: you read the cloud).
    final path = Path();
    for (var s = 0; s <= 60; s++) {
      final n = maxN * s / 60;
      final f = math.pow(0.5, n).toDouble();
      final p = Offset(xAt(n), yAt(f));
      if (s == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kAccent.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Target rings for each beat.
    for (var b = 0; b < _kBeats; b++) {
      final tx = xAt((b + 1).toDouble());
      final ty = yAt(_targetFrac(b));
      final captured = capN[b] != null;
      final isNext = b == nextBeat && !inter;

      if (captured) {
        // Frozen tap marker + its quality, and the true % readout (post-tap).
        final mx = xAt(capN[b]!.clamp(0.0, maxN));
        final my = yAt(math.pow(0.5, capN[b]!).clamp(0.0, 1.0).toDouble());
        final qc = capQ[b] == 2
            ? _kAccent
            : (capQ[b] == 1 ? _kGood : _kWarn);
        // Ghost of the target.
        canvas.drawCircle(
            Offset(tx, ty),
            6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = _kGood.withValues(alpha: 0.4));
        // Where you actually measured.
        canvas.drawCircle(Offset(mx, my), 8,
            Paint()..color = qc.withValues(alpha: 0.30));
        canvas.drawCircle(Offset(mx, my), 4, Paint()..color = qc);
        final readPct = math.pow(0.5, capN[b]!).toDouble() * 100;
        final rl = readPct >= 10
            ? readPct.toStringAsFixed(0)
            : readPct.toStringAsFixed(1);
        GameFx.text(canvas, '$rl%', Offset(mx, my - 16), 10, qc,
            weight: FontWeight.w800);
      } else {
        final pulse = isNext ? 0.6 + 0.4 * (0.5 + 0.5 * math.sin(idle * 5)) : 1.0;
        final col = isNext ? _kAccent : Potatuhs.textFaint.withValues(alpha: 0.5);
        // Dashed drop-line to the axis for the next target (aim guide).
        if (isNext) {
          _dashedLine(canvas, Offset(tx, ty), Offset(tx, bot),
              Paint()..color = _kAccent.withValues(alpha: 0.4)..strokeWidth = 1.3);
        }
        canvas.drawCircle(
          Offset(tx, ty),
          isNext ? 8 : 5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isNext ? 2.6 : 1.8
            ..color = col.withValues(alpha: pulse),
        );
      }
      // Beat label under the axis.
      final tpct = (_targetFrac(b) * 100);
      final tl = tpct >= 10 ? tpct.toStringAsFixed(0) : tpct.toStringAsFixed(1);
      GameFx.text(canvas, '$tl%', Offset(tx, bot + 12), 10,
          Potatuhs.textFaint, weight: FontWeight.w600);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * math.min(d + dash, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  // ── Per-tap hit flash ──
  void _paintFlash(Canvas canvas, Size size) {
    if (flashAge > _kFlashTime) return;
    final a = (1 - flashAge / _kFlashTime).clamp(0.0, 1.0);
    final label = flashQ == 2 ? 'PERFECT!' : (flashQ == 1 ? 'CLOSE' : 'OFF');
    final col = flashQ == 2 ? _kAccent : (flashQ == 1 ? _kGood : _kWarn);
    GameFx.text(
      canvas,
      label,
      Offset(size.width / 2, size.height * 0.42),
      flashQ == 2 ? 26 : 20,
      col.withValues(alpha: a),
      display: true,
      glow: 0.6 * a,
    );
    if (flashPts > 0) {
      GameFx.text(
        canvas,
        '+$flashPts',
        Offset(size.width / 2, size.height * 0.46),
        14,
        col.withValues(alpha: a),
        weight: FontWeight.w800,
      );
    }
  }

  // ── Tap affordance ──
  void _paintTapHint(Canvas canvas, Size size) {
    if (!started || !running) return;
    final live = nextBeat < _kBeats && !inter;
    final pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(idle * 4));
    GameFx.text(
      canvas,
      'TAP TO MEASURE',
      Offset(size.width / 2, size.height * 0.93),
      15,
      (live ? _kAccent : Potatuhs.textFaint).withValues(alpha: live ? pulse : 0.4),
      weight: FontWeight.w800,
    );
  }

  // ── Ready / pre-start ──
  void _paintReady(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'RADIOACTIVE SAMPLE',
      Offset(size.width / 2, size.height * 0.62),
      22,
      _kAccent,
      display: true,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      'tap when the glow hits 50% · 25% · 12.5%',
      Offset(size.width / 2, size.height * 0.665),
      13,
      Potatuhs.textSecondary,
    );
    GameFx.text(
      canvas,
      'each halving takes the same time — ride the beat',
      Offset(size.width / 2, size.height * 0.70),
      11,
      Potatuhs.textFaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HalfLifeV2Painter old) => true;
}
