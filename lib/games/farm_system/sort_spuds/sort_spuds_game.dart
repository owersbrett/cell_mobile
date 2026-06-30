import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';

import '../../fx.dart';
import '../../potato.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Sort the Spuds — farm-system grading / quality-control gauntlet
//
// Potatoes ride a conveyor belt. The player grades each one into the right bin
// — SMALL / MEDIUM / LARGE — and CULLS the defective ones (rotten / green /
// blemished) into the REJECT bin before they fall off the end. A rotten spud
// sent to a sale bin contaminates the crate and costs big; a perfectly good
// spud thrown to cull is wasted product. The belt speeds up and size grades
// grow subtler as the round wears on.
//
// HALFWAY ESCALATION: at the midpoint of the round the grading line SPLITS —
// the bins shrink, the belt slides up, and a SECOND belt slides in beneath it.
// From there the player grades TWO conveyors at once, each with its own row of
// (smaller) bins. The reflow is animated, not a snap.
//
// PERFORMANCE: one Ticker drives one CustomPainter. All belt/potato/bin/FX
// state is mutated in the tick WITHOUT setState; the canvas repaints off the
// ticker (`repaint: _ticker`). The host (MiniGameHost) owns the clock,
// countdown, score readout and results — this widget renders ONLY the play
// area and reports points via `session.addScore` / `session.noteStreak`.
//
// The spud itself is drawn with the canonical `PotatoArt` renderer so it looks
// identical to potatoes everywhere else in the app. `SortSpudsArt` exposes the
// component draws (spud + bin) so the visual manual (legendFrames, below) shows
// the LITERAL pieces a player meets, not a redrawn diagram.
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
/// The defect issues should stay APPARENT — the floor is high so a bad spud is
/// always readable; difficulty comes from belt speed + size ambiguity + the
/// two-belt split, not from hiding the rot.
const double _kDefectVisMax = 1.00; // easy: very obvious defects
const double _kDefectVisMin = 0.78; // hard: still clearly visible

/// Probability a freshly-spawned spud is defective (must be culled).
const double _kDefectChance = 0.32;

/// Max spuds alive on ONE belt at once (a safety cap; per-belt now).
const int _kMaxSpuds = 7;

/// Routing animation duration: spud flies from belt into the chosen bin.
const double _kRouteTime = 0.26;

/// Fraction of the round at which the line splits into two belts (the showpiece
/// escalation). 0.5 = exactly halfway.
const double _kSplitFraction = 0.5;

/// Seconds the split reflow animation takes (belt slides up, second belt slides
/// in, bins shrink).
const double _kSplitTime = 1.15;

// Size-grade band centres (true size value 0..1). Bands: [0,.33] [.33,.66] [.66,1].
const List<double> _kGradeCentres = [0.165, 0.5, 0.835];
const double _kGradeBandHalf = 0.158; // clamp half-width inside each band

// ── Palette (farm grading line) ────────────────────────────────────────────

const Color _kBelt = Color(0xFF3A3027); // dark conveyor rubber
const Color _kBeltTread = Color(0xFF5A4A3A); // tread slats
const Color _kSpud = Color(0xFFC9A36B); // healthy tan potato
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

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ── Defect kinds ───────────────────────────────────────────────────────────

enum _Defect { none, rotten, green, blemish }

// ── One potato on the line ─────────────────────────────────────────────────

class _Spud {
  double pos; // 0 (left spawn) → 1 (right fall-off)
  final int belt; // 0 = first/top belt, 1 = second belt (post-split)
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
    required this.belt,
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
  final int lane;
  final int bin;
  final bool good;
  double life; // seconds remaining
  _BinFlash(this.lane, this.bin, this.good, this.life);
}

// ───────────────────────────────────────────────────────────────────────────
// Geometry — one or two LANES (belt strip + its row of 4 bins), derived from
// the play-area size and the split progress. Shared by painter + hit-test so
// taps and drawing always agree on where the bins are.
// ───────────────────────────────────────────────────────────────────────────

class _Lane {
  final Rect belt;
  final double beltY;
  final List<Rect> bins; // 4
  final double alpha; // 1 = solid; <1 while a lane is forming
  const _Lane(this.belt, this.beltY, this.bins, this.alpha);
}

class _Geo {
  final double w, h;
  final double beltLeft, beltRight;
  final double factY;
  final List<_Lane> lanes;

  _Geo._(this.w, this.h, this.beltLeft, this.beltRight, this.factY, this.lanes);

  factory _Geo(Size size, {double split = 0}) {
    final w = size.width, h = size.height;
    const left = 10.0;
    final right = w - 10.0;

    _Lane mk(double bt, double bb, double nt, double nb, double alpha) {
      const gap = 8.0;
      final binW = (w - gap * 5) / 4;
      final bins = <Rect>[
        for (int i = 0; i < 4; i++)
          Rect.fromLTRB(
              gap + i * (binW + gap), nt, gap + i * (binW + gap) + binW, nb),
      ];
      return _Lane(
          Rect.fromLTRB(left, bt, right, bb), (bt + bb) / 2, bins, alpha);
    }

    // Single-belt layout (the calm/early game) — the original generous layout.
    final single = mk(h * 0.225, h * 0.48, h * 0.645, h - 12, 1.0);
    if (split <= 0) {
      return _Geo._(w, h, left, right, h * 0.575, [single]);
    }

    // Two-belt target layout — two stacked (belt + shrunken bin-row) lanes.
    final top = mk(h * 0.08, h * 0.235, h * 0.265, h * 0.45, 1.0);
    final bot = mk(h * 0.52, h * 0.675, h * 0.705, h * 0.89, 1.0);

    // Lane 0 reflows single → top; lane 1 slides up from below + fades in.
    final l0 = _lerpLane(single, top, split);
    final slide = (1 - split) * h * 0.25;
    final l1 = _Lane(
      bot.belt.translate(0, slide),
      bot.beltY + slide,
      [for (final r in bot.bins) r.translate(0, slide)],
      split,
    );
    final factY = _lerp(h * 0.575, h * 0.485, split);
    return _Geo._(w, h, left, right, factY, [l0, l1]);
  }

  static _Lane _lerpLane(_Lane a, _Lane b, double t) => _Lane(
        Rect.lerp(a.belt, b.belt, t)!,
        _lerp(a.beltY, b.beltY, t),
        [for (int i = 0; i < 4; i++) Rect.lerp(a.bins[i], b.bins[i], t)!],
        _lerp(a.alpha, b.alpha, t),
      );

  double spudX(double pos) => beltLeft + pos * (beltRight - beltLeft);

  /// Tap → (lane, bin) or null. Forgiving: accepts taps from just above a bin
  /// row down to just below it, for whichever lane the tap falls in.
  ({int lane, int bin})? binAt(Offset p) {
    for (int li = 0; li < lanes.length; li++) {
      final lane = lanes[li];
      final top = lane.bins.first.top;
      final bottom = lane.bins.first.bottom;
      if (p.dy < top - h * 0.05 || p.dy > bottom + h * 0.03) continue;
      for (int i = 0; i < 4; i++) {
        final r = lane.bins[i];
        if (p.dx >= r.left - 4 && p.dx <= r.right + 4) {
          return (lane: li, bin: i);
        }
      }
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SortSpudsArt — the component draws, shared by the live painter and the visual
// manual so the manual shows the EXACT spud + crate the player will meet.
// ═══════════════════════════════════════════════════════════════════════════

class SortSpudsArt {
  SortSpudsArt._();

  /// Draws one potato centred at [c]. The body uses the canonical [PotatoArt];
  /// the defect tells (rot / green cap / scab) layer on top, their strength set
  /// by [defectVis] so a bad spud reads clearly.
  static void spud(
    Canvas canvas,
    Offset c, {
    required double sizeVal,
    _Defect defect = _Defect.none,
    double defectVis = 1.0,
    double seed = 0,
    double scale = 1.0,
  }) {
    final r = (11 + sizeVal * 15) * scale;
    final rx = r * 1.075;
    final ry = r * 0.81;
    final w = rx * 2, h = ry * 2;

    // Drop shadow.
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, ry), width: w * 0.9, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Body — greened spuds tint their whole skin a touch.
    final baseColor = defect == _Defect.green
        ? Color.lerp(_kSpud, _kGreen, 0.30 * defectVis)!
        : _kSpud;
    PotatoArt.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      seed: seed,
      color: baseColor,
      eyes: true,
    );

    // Defect tells — kept apparent (high alpha) so the issue is easy to spot.
    switch (defect) {
      case _Defect.rotten:
        final rng = Random((seed * 1000).toInt());
        for (int i = 0; i < 3; i++) {
          final a = rng.nextDouble() * 6.28;
          final rr = r * (0.30 + rng.nextDouble() * 0.45);
          final pp = c.translate(cos(a) * r * 0.5, sin(a) * ry * 0.7);
          canvas.drawCircle(
            pp,
            rr * 0.55,
            Paint()
              ..color = _kRot.withValues(alpha: 0.95 * defectVis)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        }
        break;
      case _Defect.green:
        // A greened cap clipped to the tuber silhouette.
        final clip = PotatoArt.path(c, rx, ry, seed);
        canvas.save();
        canvas.clipPath(clip);
        canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(0, -ry * 0.45), width: w, height: h * 0.75),
          Paint()..color = _kGreen.withValues(alpha: 0.62 * defectVis),
        );
        canvas.restore();
        break;
      case _Defect.blemish:
        final rng = Random((seed * 777).toInt());
        for (int i = 0; i < 5; i++) {
          final pp = c.translate(
            (rng.nextDouble() - 0.5) * w * 0.7,
            (rng.nextDouble() - 0.5) * h * 0.6,
          );
          canvas.drawCircle(
            pp,
            2.0 + rng.nextDouble() * 2.0,
            Paint()..color = _kScab.withValues(alpha: 0.92 * defectVis),
          );
        }
        break;
      case _Defect.none:
        break;
    }
  }

  /// Draws one grading crate. [glyphIndex] 0..2 = a size silhouette, 3 = cull X.
  static void bin(
    Canvas canvas,
    Rect r, {
    required Color accent,
    required String label,
    required int glyphIndex,
    double alpha = 1.0,
    bool flashActive = false,
    bool flashGood = true,
    double flashAmt = 0,
  }) {
    final rrect = RRect.fromRectAndRadius(r, const Radius.circular(12));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.22 * alpha),
            accent.withValues(alpha: 0.08 * alpha),
          ],
        ).createShader(r),
    );
    if (flashActive) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = (flashGood ? accent : const Color(0xFFE5534B))
              .withValues(alpha: 0.4 * flashAmt * alpha),
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.8 * alpha),
    );

    // Mouth opening at the top (where spuds drop in).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 6, r.top - 3, r.width - 12, 6),
        const Radius.circular(3),
      ),
      Paint()..color = accent.withValues(alpha: 0.9 * alpha),
    );

    // Grade glyph: small / medium / large silhouette, or a cull X.
    final gc = Offset(r.center.dx, r.top + r.height * 0.40);
    if (glyphIndex < 3) {
      final gr = 7.0 + glyphIndex * 4.0;
      canvas.drawOval(
        Rect.fromCenter(center: gc, width: gr * 2.1, height: gr * 1.5),
        Paint()..color = accent.withValues(alpha: 0.85 * alpha),
      );
    } else {
      const s = 9.0;
      final p = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(gc.translate(-s, -s), gc.translate(s, s), p);
      canvas.drawLine(gc.translate(s, -s), gc.translate(-s, s), p);
    }

    GameFx.text(
      canvas,
      label,
      Offset(r.center.dx, r.bottom - 14),
      r.width < 78 ? 10 : 12,
      Colors.white.withValues(alpha: 0.92 * alpha),
      weight: FontWeight.w800,
    );
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
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same SortSpudsArt the live game uses).
// ═══════════════════════════════════════════════════════════════════════════

void _legendGrades(Canvas canvas, Size size) {
  final cy = size.height * 0.48;
  final xs = [size.width * 0.25, size.width * 0.5, size.width * 0.75];
  const labels = ['SMALL', 'MEDIUM', 'LARGE'];
  for (int i = 0; i < 3; i++) {
    SortSpudsArt.spud(canvas, Offset(xs[i], cy),
        sizeVal: _kGradeCentres[i], seed: i * 1.7 + 1, scale: 1.15);
    GameFx.text(canvas, labels[i], Offset(xs[i], size.height * 0.86), 11,
        _kBinAccent[i],
        weight: FontWeight.w800);
  }
}

void _legendMatch(Canvas canvas, Size size) {
  SortSpudsArt.spud(canvas, Offset(size.width * 0.5, size.height * 0.30),
      sizeVal: 0.835, seed: 4.2, scale: 1.25);
  // a downward chevron cue
  final p = Paint()
    ..color = _kBinAccent[2]
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final cx = size.width * 0.5, cy = size.height * 0.51;
  canvas.drawLine(Offset(cx - 8, cy - 5), Offset(cx, cy + 4), p);
  canvas.drawLine(Offset(cx + 8, cy - 5), Offset(cx, cy + 4), p);
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.74),
      width: size.width * 0.34,
      height: size.height * 0.34);
  SortSpudsArt.bin(canvas, r,
      accent: _kBinAccent[2], label: 'LARGE', glyphIndex: 2);
}

void _legendCull(Canvas canvas, Size size) {
  final cy = size.height * 0.36;
  final xs = [size.width * 0.25, size.width * 0.5, size.width * 0.75];
  const defs = [_Defect.rotten, _Defect.green, _Defect.blemish];
  for (int i = 0; i < 3; i++) {
    SortSpudsArt.spud(canvas, Offset(xs[i], cy),
        sizeVal: 0.5, defect: defs[i], defectVis: 1.0, seed: i * 3.1 + 2);
  }
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.80),
      width: size.width * 0.5,
      height: size.height * 0.26);
  SortSpudsArt.bin(canvas, r,
      accent: _kBinAccent[3], label: 'REJECT', glyphIndex: 3);
}

void _legendSplit(Canvas canvas, Size size) {
  for (int b = 0; b < 2; b++) {
    final top = size.height * (b == 0 ? 0.22 : 0.62);
    final rect = Rect.fromLTWH(
        size.width * 0.08, top, size.width * 0.84, size.height * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = _kBelt,
    );
    SortSpudsArt.spud(canvas, Offset(rect.center.dx - 30, rect.center.dy),
        sizeVal: b == 0 ? 0.3 : 0.7, seed: b * 5.0 + 1, scale: 0.9);
    SortSpudsArt.spud(canvas, Offset(rect.center.dx + 30, rect.center.dy),
        sizeVal: b == 0 ? 0.7 : 0.4,
        defect: b == 0 ? _Defect.none : _Defect.rotten,
        seed: b * 7.0 + 3,
        scale: 0.9);
  }
}

/// The visual manual for Sort the Spuds — wired into the registry spec.
final List<LegendFrame> sortSpudsLegendFrames = [
  const LegendFrame(
      caption: 'Grade each spud by size: SMALL · MEDIUM · LARGE',
      paint: _legendGrades),
  const LegendFrame(
      caption: 'Tap the crate that matches the gold-ringed spud',
      paint: _legendMatch),
  const LegendFrame(
      caption: 'Cull rotten, green or blemished spuds into REJECT',
      paint: _legendCull),
  const LegendFrame(
      caption: 'Halfway through, the line splits — sort TWO belts at once',
      paint: _legendSplit),
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
  double _split = 0; // 0 = one belt, 1 = two belts (animated at halftime)
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
  // (single) belt so the scene reads before the host's countdown hands over.
  void _seedCalmPreview() {
    _spuds.clear();
    for (int i = 0; i < 3; i++) {
      _spuds.add(_Spud(
        pos: 0.22 + i * 0.26,
        belt: 0,
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

  // Belts feeding spuds right now: 1 until the split fully forms, then 2.
  int get _activeBelts => _split >= 1.0 ? 2 : 1;

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
        _split = 0;
        _spuds.clear();
      }
      _elapsed += dt;

      // Halftime line-split: ramp _split 0→1 once past the midpoint.
      final half = widget.session.spec.durationSeconds * _kSplitFraction;
      if (_elapsed >= half && _split < 1.0) {
        _split = (_split + dt / _kSplitTime).clamp(0.0, 1.0);
      }

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

      // Spawn each active belt independently, keeping even spacing.
      for (int b = 0; b < _activeBelts; b++) {
        final live = _spuds
            .where((s) => s.belt == b && s.binTarget == null && !s.dead)
            .toList();
        if (live.length < _kMaxSpuds) {
          double? newest;
          for (final s in live) {
            if (newest == null || s.pos < newest) newest = s.pos;
          }
          if (newest == null || newest > _spawnGap) _spawn(b);
        }
      }
    }

    _spuds.removeWhere((s) => s.dead);
    // No setState — the CustomPaint repaints off the ticker.
  }

  void _spawn(int belt) {
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
      belt: belt,
      sizeVal: sizeVal,
      defect: defect,
      trueBin: trueBin,
      defectVis: _defectVis,
      seed: _rng.nextDouble() * 100,
      wobble: _rng.nextDouble() * 6.28,
    ));
  }

  // ── Leading spud on a belt (the one a bin-tap will sort) ───────────────────
  _Spud? _leading(int belt) {
    _Spud? best;
    for (final s in _spuds) {
      if (s.belt != belt || s.binTarget != null || s.dead) continue;
      if (best == null || s.pos > best.pos) best = s;
    }
    return best;
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _size == Size.zero) return;
    final geo = _Geo(_size, split: _split);
    final hit = geo.binAt(d.localPosition);
    if (hit == null) return;
    final s = _leading(hit.lane);
    if (s == null) return;
    _dispatch(s, hit.bin, geo, hit.lane);
  }

  void _dispatch(_Spud s, int bin, _Geo geo, int laneIdx) {
    final lane = geo.lanes[laneIdx];
    s.binTarget = bin;
    s.anim = 0;
    s.fromX = geo.spudX(s.pos);
    s.fromY = lane.beltY + sin(_animClock * 3 + s.wobble) * 3;

    final correct = bin == s.trueBin;
    s.correct = correct;
    final binCentre = lane.bins[bin].topCenter;

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
    _flashes.add(_BinFlash(laneIdx, bin, correct, 0.45));
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
              split: _split,
              beltSpeed: _started ? _beltSpeed : _kBeltSpeedMin,
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
  final double split;
  final double beltSpeed;
  final String fact;
  final bool running;

  _SortSpudsPainter({
    required this.spuds,
    required this.fx,
    required this.pops,
    required this.flashes,
    required this.clock,
    required this.split,
    required this.beltSpeed,
    required this.fact,
    required this.running,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.shortestSide <= 0) {
      return;
    }
    final geo = _Geo(size, split: split);

    GameFx.atmosphere(canvas, size, Potatuhs.sienna, clock, motes: 16);

    for (final lane in geo.lanes) {
      _drawBelt(canvas, lane);
    }
    _drawFactStrip(canvas, geo);
    for (int li = 0; li < geo.lanes.length; li++) {
      _drawBins(canvas, li, geo.lanes[li]);
    }

    final lead0 = _leadingOf(0);
    final lead1 = _leadingOf(1);

    // Spuds still on the belt (back-to-front by position).
    final onBelt = spuds.where((s) => s.binTarget == null).toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));
    for (final s in onBelt) {
      final laneIdx = s.belt.clamp(0, geo.lanes.length - 1);
      final lane = geo.lanes[laneIdx];
      final x = geo.spudX(s.pos);
      final y = lane.beltY + sin(clock * 3 + s.wobble) * 3;
      final hl = identical(s, s.belt == 0 ? lead0 : lead1);
      _drawSpud(canvas, Offset(x, y), s, highlight: hl);
    }

    // Routing spuds flying into their bins.
    for (final s in spuds) {
      if (s.binTarget == null) continue;
      final laneIdx = s.belt.clamp(0, geo.lanes.length - 1);
      final lane = geo.lanes[laneIdx];
      final target = lane.bins[s.binTarget!].topCenter.translate(0, 14);
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

  _Spud? _leadingOf(int belt) {
    _Spud? best;
    for (final s in spuds) {
      if (s.belt != belt || s.binTarget != null || s.dead) continue;
      if (best == null || s.pos > best.pos) best = s;
    }
    return best;
  }

  // ── Conveyor belt ─────────────────────────────────────────────────────────
  void _drawBelt(Canvas canvas, _Lane lane) {
    final rect = lane.belt;
    final a = lane.alpha;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = _kBelt.withValues(alpha: a));
    // Scrolling tread slats — the motion cue. Offset by the belt clock.
    const slatGap = 26.0;
    final scroll = (clock * beltSpeed * (rect.right - rect.left)) % slatGap;
    final paint = Paint()
      ..color = _kBeltTread.withValues(alpha: 0.6 * a)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (double x = rect.left - slatGap + scroll;
        x < rect.right + slatGap;
        x += slatGap) {
      canvas.drawLine(
        Offset(x, rect.top + 4),
        Offset(x + 12, rect.bottom - 4),
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
        ..color = Colors.white.withValues(alpha: 0.10 * a),
    );
    for (final cx in [rect.left + 4, rect.right - 4]) {
      canvas.drawCircle(
        Offset(cx, rect.bottom + 2),
        7,
        Paint()..color = _kBeltTread.withValues(alpha: 0.7 * a),
      );
    }
  }

  // ── A single potato (with highlight ring) ─────────────────────────────────
  void _drawSpud(Canvas canvas, Offset c, _Spud s,
      {required bool highlight, double scale = 1.0}) {
    if (highlight) {
      final r = (11 + s.sizeVal * 15) * scale;
      final w = r * 2.15;
      final h = r * 1.62;
      final pulse = 0.5 + 0.5 * sin(clock * 5);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w + 14 + pulse * 6, height: h + 14),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Potatuhs.gold.withValues(alpha: 0.45 + pulse * 0.35),
      );
    }
    SortSpudsArt.spud(
      canvas,
      c,
      sizeVal: s.sizeVal,
      defect: s.defect,
      defectVis: s.defectVis,
      seed: s.seed,
      scale: scale,
    );
  }

  // ── Bins (one lane's row of 4) ────────────────────────────────────────────
  void _drawBins(Canvas canvas, int laneIdx, _Lane lane) {
    for (int i = 0; i < 4; i++) {
      final flash = _flashFor(laneIdx, i);
      SortSpudsArt.bin(
        canvas,
        lane.bins[i],
        accent: _kBinAccent[i],
        label: _kBinLabel[i],
        glyphIndex: i,
        alpha: lane.alpha,
        flashActive: flash != null,
        flashGood: flash?.good ?? false,
        flashAmt: flash != null ? (flash.life / 0.45).clamp(0.0, 1.0) : 0,
      );
    }
  }

  _BinFlash? _flashFor(int lane, int bin) {
    for (final f in flashes) {
      if (f.lane == lane && f.bin == bin) return f;
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
    final beltTop = geo.lanes.first.belt.top;
    GameFx.text(
      canvas,
      'GRADE THE SPUDS',
      Offset(geo.w / 2, beltTop - geo.h * 0.06),
      20,
      Potatuhs.textPrimary,
      display: true,
      glow: 0.4,
    );
    GameFx.text(
      canvas,
      'Tap the bin that matches each potato — cull the bad ones',
      Offset(geo.w / 2, beltTop - geo.h * 0.02),
      11,
      Potatuhs.textSecondary,
    );
  }

  @override
  bool shouldRepaint(covariant _SortSpudsPainter oldDelegate) => true;
}
