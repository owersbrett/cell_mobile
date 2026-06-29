import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';

import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Sort the Spuds — farm-system grading / quality-control gauntlet
//
// Potatoes ride a conveyor belt. The player grades each one into the right bin
// — SMALL / MEDIUM / LARGE — and CULLS the defective ones (rotten / green /
// blemished) into the REJECT bin before they fall off the end. A rotten spud
// sent to a sale bin contaminates the crate and costs big; a perfectly good
// spud thrown to cull is wasted product. The belt speeds up, size grades grow
// subtler, and defects get sneakier as the round wears on.
//
// PERFORMANCE: one Ticker drives one CustomPainter. All belt/potato/bin/FX
// state is mutated in the tick WITHOUT setState; the canvas repaints off the
// ticker (`repaint: _ticker`). The host (MiniGameHost) owns the clock,
// countdown, score readout and results — this widget renders ONLY the play
// area and reports points via `session.addScore` / `session.noteStreak`.
// ═══════════════════════════════════════════════════════════════════════════

// ── Tuning constants ───────────────────────────────────────────────────────

/// Seconds over which difficulty ramps from 0 → 1, then plateaus.
const double _kRampSeconds = 45.0;

/// Belt travel speed in pos-units/second (a spud crosses 0→1). Ramps with diff.
const double _kBeltSpeedMin = 0.115; // easy: ~8.7s to cross
const double _kBeltSpeedMax = 0.290; // hard: ~3.4s to cross

/// Spacing between spawned spuds, in belt pos-units. Tightens with difficulty
/// so the belt gets more crowded as it speeds up.
const double _kSpawnGapMax = 0.34; // easy: sparse belt
const double _kSpawnGapMin = 0.17; // hard: crowded belt

/// How far a spud's rendered size may drift from its grade's centre. Larger =
/// sizes land near the SMALL/MEDIUM/LARGE boundaries → harder to read by eye.
/// Stays below the band half-width (0.165) so the labelled grade is never wrong.
const double _kSizeSpreadMin = 0.045; // easy: clearly small / medium / large
const double _kSizeSpreadMax = 0.150; // hard: ambiguous, near the boundaries

/// Visibility multiplier on a defect's tell (dark rot, green cap, scab spots).
/// Drops with difficulty so blemishes get sneakier.
const double _kDefectVisMax = 1.00; // easy: obvious defects
const double _kDefectVisMin = 0.45; // hard: subtle defects

/// Probability a freshly-spawned spud is defective (must be culled).
const double _kDefectChance = 0.32;

/// Max spuds alive on the belt at once (a safety cap).
const int _kMaxSpuds = 9;

/// Routing animation duration: spud flies from belt into the chosen bin.
const double _kRouteTime = 0.26;

// Size-grade band centres (true size value 0..1). Bands: [0,.33] [.33,.66] [.66,1].
const List<double> _kGradeCentres = [0.165, 0.5, 0.835];
const double _kGradeBandHalf = 0.158; // clamp half-width inside each band

// ── Palette (farm grading line) ────────────────────────────────────────────

const Color _kBelt = Color(0xFF3A3027); // dark conveyor rubber
const Color _kBeltTread = Color(0xFF5A4A3A); // tread slats
const Color _kSpud = Color(0xFFC9A36B); // healthy tan potato
const Color _kSpudDark = Color(0xFF6B4E2E); // shadow / eyes
const Color _kRot = Color(0xFF2E2A1A); // rot patch
const Color _kGreen = Color(0xFF6E8B3D); // greening (solanine)
const Color _kScab = Color(0xFF4A3320); // blemish / scab

// Bin accents, indexed 0..3 = SMALL, MEDIUM, LARGE, REJECT.
const List<Color> _kBinAccent = [
  Color(0xFF7FB069), // SMALL — green crate
  Potatuhs.gold, // MEDIUM — gold
  Potatuhs.orange, // LARGE — orange
  Color(0xFFD64545), // REJECT — cull red
];
const List<String> _kBinLabel = ['SMALL', 'MEDIUM', 'LARGE', 'REJECT'];

// ── Defect kinds ───────────────────────────────────────────────────────────

enum _Defect { none, rotten, green, blemish }

// ── One potato on the line ─────────────────────────────────────────────────

class _Spud {
  double pos; // 0 (left spawn) → 1 (right fall-off)
  final double sizeVal; // 0..1 rendered size value
  final _Defect defect;
  final int trueBin; // 0..3 — the correct bin
  final double defectVis; // visibility of the defect tell at spawn
  final double seed; // deterministic render variation
  final double wobble; // little bob phase

  // Routing/resolution state.
  int? binTarget; // null = riding belt; else routing into this bin
  bool correct = false;
  double anim = 0; // 0..1 routing progress
  double fromX = 0, fromY = 0; // belt position captured at dispatch
  bool dead = false; // remove next sweep

  _Spud({
    required this.pos,
    required this.sizeVal,
    required this.defect,
    required this.trueBin,
    required this.defectVis,
    required this.seed,
    required this.wobble,
  });
}

// ── A brief coloured flash over a bin (correct=green, wrong=red) ────────────

class _BinFlash {
  final int bin;
  final bool good;
  double life; // seconds remaining
  _BinFlash(this.bin, this.good, this.life);
}

// ───────────────────────────────────────────────────────────────────────────
// Geometry — derived from the play-area size. Shared by painter + hit-test so
// taps and drawing always agree on where the bins are.
// ───────────────────────────────────────────────────────────────────────────

class _Geo {
  final double w, h;
  final double beltLeft, beltRight, beltTop, beltBottom, beltY;
  final double binTop, binBottom, binGap, binW;
  final double factY;

  _Geo(Size size)
      : w = size.width,
        h = size.height,
        beltLeft = 10,
        beltRight = size.width - 10,
        beltTop = size.height * 0.225,
        beltBottom = size.height * 0.225 + size.height * 0.255,
        beltY = size.height * 0.225 + size.height * 0.255 / 2,
        binTop = size.height * 0.645,
        binBottom = size.height - 12,
        binGap = 8,
        binW = (size.width - 8 * 5) / 4,
        factY = size.height * 0.575;

  double spudX(double pos) => beltLeft + pos * (beltRight - beltLeft);

  Rect binRect(int i) {
    final left = binGap + i * (binW + binGap);
    return Rect.fromLTRB(left, binTop, left + binW, binBottom);
  }

  /// Tap → bin index, or -1. Accepts taps anywhere in the lower band so the
  /// targets are forgiving.
  int binAt(Offset p) {
    if (p.dy < binTop - h * 0.06) return -1;
    for (int i = 0; i < 4; i++) {
      final r = binRect(i);
      if (p.dx >= r.left - binGap / 2 && p.dx <= r.right + binGap / 2) return i;
    }
    return -1;
  }
}

// ── Educational micro-facts (grading & quality control) ─────────────────────

const List<String> _kGradeFacts = [
  'Graders sort by SIZE so buyers get a uniform pack.',
  'Cull the bad ones — one rotten spud spoils the whole crate.',
  'Green skin = solanine. Greened potatoes are pulled from sale.',
  'Blemishes & scab downgrade a potato below table grade.',
  'US grades: No.1 is clean & well-shaped; culls go to feed or starch.',
  'Sorting by size sets the price — big bakers earn more than smalls.',
  'Quality control protects the brand at every step of the chain.',
];

// ═══════════════════════════════════════════════════════════════════════════
// Widget
// ═══════════════════════════════════════════════════════════════════════════

class SortSpudsGame extends StatefulWidget {
  final MiniGameSession session;
  const SortSpudsGame({super.key, required this.session});

  @override
  State<SortSpudsGame> createState() => _SortSpudsGameState();
}

class _SortSpudsGameState extends State<SortSpudsGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Random _rng = Random();

  final List<_Spud> _spuds = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  final List<_BinFlash> _flashes = [];

  double _animClock = 0; // always-advancing, drives belt tread + bobs
  double _elapsed = 0; // play-time only, drives difficulty
  double _lastTime = 0;
  bool _started = false; // becomes true on the first running tick
  int _streak = 0;
  String _fact = _kGradeFacts.first;
  int _lastFact = 0;

  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _seedCalmPreview();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // Calm ready-state: a few clearly-graded, defect-free spuds parked on the
  // belt so the scene reads before the host's countdown hands over control.
  void _seedCalmPreview() {
    _spuds.clear();
    for (int i = 0; i < 3; i++) {
      _spuds.add(_Spud(
        pos: 0.22 + i * 0.26,
        sizeVal: _kGradeCentres[i],
        defect: _Defect.none,
        trueBin: i,
        defectVis: 1.0,
        seed: i * 1.7,
        wobble: i * 2.1,
      ));
    }
  }

  // ── Difficulty curve ──────────────────────────────────────────────────────
  double get _difficulty => (_elapsed / _kRampSeconds).clamp(0.0, 1.0);
  double get _beltSpeed =>
      _kBeltSpeedMin + (_kBeltSpeedMax - _kBeltSpeedMin) * _difficulty;
  double get _spawnGap =>
      _kSpawnGapMax - (_kSpawnGapMax - _kSpawnGapMin) * _difficulty;
  double get _sizeSpread =>
      _kSizeSpreadMin + (_kSizeSpreadMax - _kSizeSpreadMin) * _difficulty;
  double get _defectVis =>
      _kDefectVisMax - (_kDefectVisMax - _kDefectVisMin) * _difficulty;

  // ── Frame ─────────────────────────────────────────────────────────────────
  void _tick() {
    final now = _now();
    final dt = (_lastTime == 0 ? 0.016 : (now - _lastTime)).clamp(0.0, 0.05);
    _lastTime = now;
    _animClock += dt;

    // Visual-only decay always runs so flashes/particles settle smoothly even
    // between rounds.
    for (final f in _flashes) {
      f.life -= dt;
    }
    _flashes.removeWhere((f) => f.life <= 0);
    for (final p in _fx) {
      p.step(dt);
    }
    _fx.removeWhere((p) => p.life <= 0);
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);

    // Routing animations advance regardless so a dispatched spud finishes its
    // flight even right as the buzzer sounds.
    for (final s in _spuds) {
      if (s.binTarget != null && !s.dead) {
        s.anim = (s.anim + dt / _kRouteTime).clamp(0.0, 1.0);
        if (s.anim >= 1.0) s.dead = true;
      }
    }

    // The host owns the clock — only simulate the belt while playing.
    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        _elapsed = 0;
        _spuds.clear();
      }
      _elapsed += dt;

      final speed = _beltSpeed;
      for (final s in _spuds) {
        if (s.binTarget != null) continue;
        s.pos += speed * dt;
        if (s.pos >= 1.0) {
          // Fell off the end unsorted — a miss.
          s.dead = true;
          _onMiss();
        }
      }

      // Spawn to keep the belt fed with even spacing.
      if (_spuds.where((s) => s.binTarget == null && !s.dead).length <
          _kMaxSpuds) {
        double? newest;
        for (final s in _spuds) {
          if (s.binTarget == null && !s.dead) {
            if (newest == null || s.pos < newest) newest = s.pos;
          }
        }
        if (newest == null || newest > _spawnGap) _spawn();
      }
    }

    _spuds.removeWhere((s) => s.dead);
    // No setState — the CustomPaint repaints off the ticker.
  }

  void _spawn() {
    final defective = _rng.nextDouble() < _kDefectChance;
    _Defect defect;
    int trueBin;
    double sizeVal;
    if (defective) {
      const kinds = [_Defect.rotten, _Defect.green, _Defect.blemish];
      defect = kinds[_rng.nextInt(kinds.length)];
      trueBin = 3; // REJECT
      // A defective spud still has a size; let it look like any sale grade so
      // the player can't shortcut on size alone.
      final slot = _rng.nextInt(3);
      sizeVal = _kGradeCentres[slot];
    } else {
      defect = _Defect.none;
      trueBin = _rng.nextInt(3);
      final spread = _sizeSpread;
      final c = _kGradeCentres[trueBin];
      sizeVal = (c + (_rng.nextDouble() - 0.5) * 2 * spread)
          .clamp(c - _kGradeBandHalf, c + _kGradeBandHalf);
    }
    _spuds.add(_Spud(
      pos: 0.0,
      sizeVal: sizeVal,
      defect: defect,
      trueBin: trueBin,
      defectVis: _defectVis,
      seed: _rng.nextDouble() * 100,
      wobble: _rng.nextDouble() * 6.28,
    ));
  }

  // ── Leading spud (the one a bin-tap will sort) ────────────────────────────
  _Spud? _leading() {
    _Spud? best;
    for (final s in _spuds) {
      if (s.binTarget != null || s.dead) continue;
      if (best == null || s.pos > best.pos) best = s;
    }
    return best;
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _size == Size.zero) return;
    final geo = _Geo(_size);
    final bin = geo.binAt(d.localPosition);
    if (bin < 0) return;
    final s = _leading();
    if (s == null) return;
    _dispatch(s, bin, geo);
  }

  void _dispatch(_Spud s, int bin, _Geo geo) {
    s.binTarget = bin;
    s.anim = 0;
    s.fromX = geo.spudX(s.pos);
    s.fromY = geo.beltY + sin(_animClock * 3 + s.wobble) * 3;

    final correct = bin == s.trueBin;
    s.correct = correct;
    final binCentre = geo.binRect(bin).topCenter;

    int delta;
    if (correct) {
      _streak++;
      widget.session.noteStreak(_streak);
      // Culling a defect is the QC payoff; a clean size sort is the base.
      final base = bin == 3 ? 14 : 10;
      final comboBonus = _streak >= 3 ? (_streak - 2) * 2 : 0;
      delta = base + comboBonus;
    } else {
      _streak = 0;
      if (s.trueBin == 3) {
        // Rotten spud waved into a SALE bin — contaminates the crate.
        delta = -30;
      } else if (bin == 3) {
        // Good product thrown to cull — waste.
        delta = -12;
      } else {
        // Wrong size grade.
        delta = -6;
      }
    }

    widget.session.addScore(delta);
    _flashes.add(_BinFlash(bin, correct, 0.45));
    final popColor = correct ? _kBinAccent[bin] : const Color(0xFFE5534B);
    final sign = delta >= 0 ? '+' : '';
    _pops.add(FxPop(
      binCentre.translate(0, -10),
      '$sign$delta',
      popColor,
    ));
    if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
    _fx.addAll(FxBurst.spawn(binCentre, popColor,
        count: correct ? 12 : 8, speed: 130));

    // On a clean cull, surface a fresh grading fact (the E payoff).
    if (correct && bin == 3) _nextFact();
  }

  void _onMiss() {
    _streak = 0;
    widget.session.addScore(-5);
  }

  void _nextFact() {
    if (_kGradeFacts.length <= 1) return;
    int idx;
    do {
      idx = _rng.nextInt(_kGradeFacts.length);
    } while (idx == _lastFact);
    _lastFact = idx;
    _fact = _kGradeFacts[idx];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _SortSpudsPainter(
              spuds: _spuds,
              fx: _fx,
              pops: _pops,
              flashes: _flashes,
              clock: _animClock,
              beltSpeed: _started ? _beltSpeed : _kBeltSpeedMin,
              leading: _leading(),
              fact: _fact,
              running: widget.session.isRunning,
              repaint: _ticker,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — draws the whole play area in one pass, repainting off the ticker.
// ═══════════════════════════════════════════════════════════════════════════

class _SortSpudsPainter extends CustomPainter {
  final List<_Spud> spuds;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final List<_BinFlash> flashes;
  final double clock;
  final double beltSpeed;
  final _Spud? leading;
  final String fact;
  final bool running;

  _SortSpudsPainter({
    required this.spuds,
    required this.fx,
    required this.pops,
    required this.flashes,
    required this.clock,
    required this.beltSpeed,
    required this.leading,
    required this.fact,
    required this.running,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || !size.height.isFinite || size.shortestSide <= 0) {
      return;
    }
    final geo = _Geo(size);

    GameFx.atmosphere(canvas, size, Potatuhs.sienna, clock, motes: 16);

    _drawBelt(canvas, geo);
    _drawFactStrip(canvas, geo);
    _drawBins(canvas, geo);

    // Spuds still on the belt (back-to-front by position).
    final onBelt = spuds.where((s) => s.binTarget == null).toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));
    for (final s in onBelt) {
      final x = geo.spudX(s.pos);
      final y = geo.beltY + sin(clock * 3 + s.wobble) * 3;
      _drawSpud(canvas, Offset(x, y), s, highlight: identical(s, leading));
    }

    // Routing spuds flying into their bins.
    for (final s in spuds) {
      if (s.binTarget == null) continue;
      final target = geo.binRect(s.binTarget!).topCenter.translate(0, 14);
      final t = Curves.easeIn.transform(s.anim);
      final p = Offset.lerp(Offset(s.fromX, s.fromY), target, t)!;
      _drawSpud(canvas, p, s, highlight: false, scale: 1.0 - 0.35 * t);
    }

    FxBurst.paint(canvas, fx);
    for (final pop in pops) {
      pop.paint(canvas);
    }

    if (!running) _drawReadyHint(canvas, geo);
  }

  // ── Conveyor belt ─────────────────────────────────────────────────────────
  void _drawBelt(Canvas canvas, _Geo geo) {
    final rect = Rect.fromLTRB(geo.beltLeft, geo.beltTop, geo.beltRight,
        geo.beltBottom);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = _kBelt);
    // Scrolling tread slats — the motion cue. Offset by the belt clock.
    final slatGap = 26.0;
    final scroll = (clock * beltSpeed * (geo.beltRight - geo.beltLeft)) %
        slatGap;
    final paint = Paint()
      ..color = _kBeltTread.withValues(alpha: 0.6)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (double x = geo.beltLeft - slatGap + scroll;
        x < geo.beltRight + slatGap;
        x += slatGap) {
      canvas.drawLine(
        Offset(x, geo.beltTop + 4),
        Offset(x + 12, geo.beltBottom - 4),
        paint,
      );
    }
    canvas.restore();
    // Rim + edge rollers.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    for (final cx in [geo.beltLeft + 4, geo.beltRight - 4]) {
      canvas.drawCircle(
        Offset(cx, geo.beltBottom + 2),
        7,
        Paint()..color = _kBeltTread.withValues(alpha: 0.7),
      );
    }
  }

  // ── A single potato (with its defect tells) ───────────────────────────────
  void _drawSpud(Canvas canvas, Offset c, _Spud s,
      {required bool highlight, double scale = 1.0}) {
    final r = (11 + s.sizeVal * 15) * scale;
    final w = r * 2.15;
    final h = r * 1.62;

    if (highlight) {
      // Pulsing "this one" ring above the belt so the player knows which spud a
      // bin-tap will grade.
      final pulse = 0.5 + 0.5 * sin(clock * 5);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w + 14 + pulse * 6, height: h + 14),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Potatuhs.gold.withValues(alpha: 0.45 + pulse * 0.35),
      );
    }

    // Drop shadow.
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, h * 0.5), width: w * 0.9, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Body with an earthy radial shade.
    final body = Rect.fromCenter(center: c, width: w, height: h);
    final baseColor = s.defect == _Defect.green
        ? Color.lerp(_kSpud, _kGreen, 0.25 * s.defectVis)!
        : _kSpud;
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(baseColor, Colors.white, 0.35)!,
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.4)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(body),
    );

    // Defect tells (strength scaled by visibility → sneakier late game).
    switch (s.defect) {
      case _Defect.rotten:
        final rng = Random((s.seed * 1000).toInt());
        for (int i = 0; i < 3; i++) {
          final a = rng.nextDouble() * 6.28;
          final rr = r * (0.25 + rng.nextDouble() * 0.4);
          final pp = c.translate(cos(a) * r * 0.5, sin(a) * h * 0.28);
          canvas.drawCircle(
            pp,
            rr * 0.5,
            Paint()
              ..color = _kRot.withValues(alpha: 0.85 * s.defectVis)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        }
        break;
      case _Defect.green:
        // A greened cap across the top of the tuber.
        canvas.save();
        canvas.clipRect(body);
        canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(0, -h * 0.32), width: w, height: h * 0.7),
          Paint()..color = _kGreen.withValues(alpha: 0.5 * s.defectVis),
        );
        canvas.restore();
        break;
      case _Defect.blemish:
        final rng = Random((s.seed * 777).toInt());
        for (int i = 0; i < 4; i++) {
          final pp = c.translate(
            (rng.nextDouble() - 0.5) * w * 0.7,
            (rng.nextDouble() - 0.5) * h * 0.6,
          );
          canvas.drawCircle(
            pp,
            1.6 + rng.nextDouble() * 1.6,
            Paint()..color = _kScab.withValues(alpha: 0.8 * s.defectVis),
          );
        }
        break;
      case _Defect.none:
        break;
    }

    // Eyes (the little sprout dimples) — character, and they read as a real spud.
    final eye = Paint()..color = _kSpudDark.withValues(alpha: 0.55);
    canvas.drawCircle(c.translate(-w * 0.16, -h * 0.05), r * 0.07, eye);
    canvas.drawCircle(c.translate(w * 0.12, h * 0.12), r * 0.06, eye);

    // Rim light.
    canvas.drawOval(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(baseColor, Colors.white, 0.4)!
            .withValues(alpha: 0.5),
    );
  }

  // ── Bins ──────────────────────────────────────────────────────────────────
  void _drawBins(Canvas canvas, _Geo geo) {
    for (int i = 0; i < 4; i++) {
      final r = geo.binRect(i);
      final accent = _kBinAccent[i];
      final flash = _flashFor(i);
      final rrect = RRect.fromRectAndRadius(r, const Radius.circular(12));

      // Crate body.
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.08),
            ],
          ).createShader(r),
      );
      // Flash overlay (correct=accent green glow, wrong=red).
      if (flash != null) {
        final a = (flash.life / 0.45).clamp(0.0, 1.0);
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = (flash.good ? accent : const Color(0xFFE5534B))
                .withValues(alpha: 0.4 * a),
        );
      }
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.8),
      );

      // Mouth opening at the top (where spuds drop in).
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + 6, r.top - 3, r.width - 12, 6),
          const Radius.circular(3),
        ),
        Paint()..color = accent.withValues(alpha: 0.9),
      );

      // Grade glyph: small / medium / large potato silhouette, or a cull X.
      final gc = Offset(r.center.dx, r.top + r.height * 0.42);
      if (i < 3) {
        final gr = 7.0 + i * 4.0;
        canvas.drawOval(
          Rect.fromCenter(center: gc, width: gr * 2.1, height: gr * 1.5),
          Paint()..color = accent.withValues(alpha: 0.85),
        );
      } else {
        final s = 9.0;
        final p = Paint()
          ..color = accent
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(gc.translate(-s, -s), gc.translate(s, s), p);
        canvas.drawLine(gc.translate(s, -s), gc.translate(-s, s), p);
      }

      // Label.
      GameFx.text(
        canvas,
        _kBinLabel[i],
        Offset(r.center.dx, r.bottom - 14),
        r.width < 78 ? 10 : 12,
        Colors.white.withValues(alpha: 0.92),
        weight: FontWeight.w800,
      );
    }
  }

  _BinFlash? _flashFor(int bin) {
    for (final f in flashes) {
      if (f.bin == bin) return f;
    }
    return null;
  }

  // ── Education strip ───────────────────────────────────────────────────────
  void _drawFactStrip(Canvas canvas, _Geo geo) {
    GameFx.text(
      canvas,
      fact,
      Offset(geo.w / 2, geo.factY),
      geo.w < 360 ? 10.5 : 12,
      Potatuhs.textSecondary,
      weight: FontWeight.w600,
    );
  }

  // ── Ready hint (calm pre-start) ───────────────────────────────────────────
  void _drawReadyHint(Canvas canvas, _Geo geo) {
    GameFx.text(
      canvas,
      'GRADE THE SPUDS',
      Offset(geo.w / 2, geo.beltTop - geo.h * 0.06),
      20,
      Potatuhs.textPrimary,
      display: true,
      glow: 0.4,
    );
    GameFx.text(
      canvas,
      'Tap the bin that matches each potato — cull the bad ones',
      Offset(geo.w / 2, geo.beltTop - geo.h * 0.02),
      11,
      Potatuhs.textSecondary,
    );
  }

  @override
  bool shouldRepaint(covariant _SortSpudsPainter oldDelegate) => true;
}
