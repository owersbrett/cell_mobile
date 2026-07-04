import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// CROP ROTATION — BioScale.farmSystem
//
// Plant your fields SEASON by SEASON, rotating crop FAMILIES so the soil never
// depletes. Each field tracks soil nitrogen (a bar). Heavy feeders (corn) drain
// it; legumes (beans) FIX nitrogen and restore the bar; roots (potatoes) break
// pest/disease cycles. Repeat the same family on a field and the yield + soil
// crash while pests build; rotate well and yields stay high.
//
// Loop: select a crop from the tray → tap fields to plant them → GROW SEASON.
// The season resolves (yields banked, soil + pests updated), then a fresh
// season begins. Score = total harvest yield across all seasons.
//
// Accelerate: more fields unlock as seasons clear, monoculture crashes get
// harsher, and pest/disease pressure ramps.
//
// Rendering: ONE AnimationController ticks the whole scene into a single
// CustomPainter. No per-frame setState over a big widget tree — the play area
// is just one CustomPaint.
// ============================================================================

// ---------------------------------------------------------------------------
// Crop families (the rotation classes)
// ---------------------------------------------------------------------------

enum _Family { legume, cereal, root, brassica }

class _Crop {
  final _Family family;
  final String name; // crop name shown on the chip ("Beans")
  final String tag; // family label ("Legume")
  final Color color;
  final double baseYield; // raw yield ceiling
  final double nDelta; // nitrogen change after harvest (+ fixes, - drains)
  final double nDep; // 0..1 how strongly yield scales with soil nitrogen
  const _Crop(this.family, this.name, this.tag, this.color, this.baseYield,
      this.nDelta, this.nDep);
}

// The four rotation families — a tidy Norfolk-style four-course set.
const _kCrops = <_Crop>[
  // Legume: nitrogen FIXER. Modest harvest, but it reloads the soil bar.
  _Crop(_Family.legume, 'Beans', 'Legume', Color(0xFF66BB6A), 4.0, 0.30, 0.30),
  // Cereal (corn): the HEAVY FEEDER. Big ceiling, but only on rich soil.
  _Crop(_Family.cereal, 'Corn', 'Heavy Feeder', Color(0xFFFFD54F), 7.2, -0.30,
      0.85),
  // Root (potato): breaks pest/disease cycles. Solid, steady yield.
  _Crop(_Family.root, 'Potatoes', 'Root', Color(0xFFBCAAA4), 5.6, -0.12, 0.45),
  // Brassica (cabbage): leafy moderate feeder, rounds out the rotation.
  _Crop(_Family.brassica, 'Cabbage', 'Brassica', Color(0xFF26C6DA), 5.0, -0.16,
      0.55),
];

_Crop _crop(_Family f) => _kCrops.firstWhere((c) => c.family == f);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components the
// live game uses (crop chips, soil plots, the nitrogen bar, the GROW button).
// Cheap + static: rendered once in the intro carousel, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

// Soil colours reused verbatim from _FarmPainter._drawPlot.
const _kLoamRich = Color(0xFF3A2A1C);
const _kLoamPoor = Color(0xFF6B4A2F);
const _kLoamPest = Color(0xFF7A5230);
const _kNitroLow = Color(0xFFD84315);
const _kNitroHigh = Color(0xFF7CB342);
const _kPestTick = Color(0xFFE53935);
const _kMono = Color(0xFFFF7043);

// One crop glyph, mirroring _FarmPainter._drawCropGlyph (family silhouettes).
void _legendGlyph(Canvas canvas, Rect r, _Crop c, {double alpha = 0.9}) {
  final cx = r.center.dx;
  final cy = r.center.dy - 2;
  final s0 = math.min(r.width, r.height);
  if (s0 <= 0) return;
  final base = c.color.withValues(alpha: alpha);
  switch (c.family) {
    case _Family.cereal: // corn — stalks with kernel heads
      for (int i = -1; i <= 1; i++) {
        final x = cx + i * s0 * 0.16;
        final top = cy - s0 * 0.26;
        canvas.drawLine(
            Offset(x, cy + s0 * 0.18),
            Offset(x, top),
            Paint()
              ..color = const Color(0xFF8BC34A).withValues(alpha: alpha)
              ..strokeWidth = 2.4);
        canvas.drawCircle(Offset(x, top), s0 * 0.06, Paint()..color = base);
      }
      break;
    case _Family.legume: // beans — leafy mound
      for (int i = 0; i < 5; i++) {
        final ang = -math.pi / 2 + (i - 2) * 0.5;
        final lx = cx + math.cos(ang) * s0 * 0.18;
        final ly = cy + math.sin(ang) * s0 * 0.16;
        canvas.drawCircle(Offset(lx, ly), s0 * 0.07, Paint()..color = base);
      }
      break;
    case _Family.root: // potatoes — tubers under a leafy tuft
      for (int i = -1; i <= 1; i++) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + i * s0 * 0.15, cy + s0 * 0.12),
              width: s0 * 0.16,
              height: s0 * 0.11),
          Paint()..color = base,
        );
      }
      canvas.drawCircle(Offset(cx, cy - s0 * 0.05), s0 * 0.08,
          Paint()..color = const Color(0xFF66BB6A).withValues(alpha: alpha));
      break;
    case _Family.brassica: // cabbage — concentric leafy head
      for (int i = 3; i >= 1; i--) {
        canvas.drawCircle(Offset(cx, cy), s0 * 0.07 * i,
            Paint()..color = c.color.withValues(alpha: alpha * (0.4 + 0.2 * i)));
      }
      break;
  }
}

// One soil plot with furrows, an optional crop, pests and the nitrogen bar —
// the literal field the player taps, mirroring _FarmPainter._drawPlot.
void _legendPlot(
  Canvas canvas,
  Rect r, {
  required double nitrogen,
  _Family? crop,
  double pest = 0,
  bool highlight = false,
}) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  final loam = Color.lerp(_kLoamPoor, _kLoamRich, nitrogen)!;
  final soil = Color.lerp(loam, _kLoamPest, pest * 0.6)!;
  canvas.drawRRect(rr, Paint()..color = soil);

  final furrow = Paint()
    ..color = Colors.black.withValues(alpha: 0.12)
    ..strokeWidth = 1;
  for (double y = r.top + 8; y < r.bottom - 6; y += 9) {
    canvas.drawLine(Offset(r.left + 6, y), Offset(r.right - 6, y), furrow);
  }

  if (crop != null) _legendGlyph(canvas, r, _crop(crop));

  if (pest > 0.35) {
    final n = (pest * 4).round().clamp(1, 4);
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(Offset(r.left + 10 + i * 9.0, r.top + 12), 2.6,
          Paint()..color = _kPestTick.withValues(alpha: 0.9));
    }
  }

  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight ? 1.8 : 1.5
        ..color = highlight
            ? const Color(0xFFFFD54F).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.10));

  // Nitrogen bar along the bottom edge.
  final barY = r.bottom - 7, barL = r.left + 8, barW = r.width - 16;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(barL, barY, barW, 4), const Radius.circular(2)),
    Paint()..color = Colors.black.withValues(alpha: 0.35),
  );
  final nColor = Color.lerp(_kNitroLow, _kNitroHigh, nitrogen)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(barL, barY, barW * nitrogen.clamp(0.0, 1.0), 4),
        const Radius.circular(2)),
    Paint()..color = nColor,
  );
  GameFx.text(canvas, 'N', Offset(barL + 4, barY - 8), 7,
      Colors.white.withValues(alpha: 0.4),
      weight: FontWeight.w800);
}

// One crop-tray chip, mirroring _FarmPainter._drawTray.
void _legendChip(Canvas canvas, Rect rect, _Crop c, {bool selected = false}) {
  if (rect.width <= 0 || rect.height <= 0) return;
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  canvas.drawRRect(
      rr,
      Paint()
        ..color = selected
            ? c.color.withValues(alpha: 0.30)
            : Potatuhs.inkPanel.withValues(alpha: 0.85));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.4 : 1.2
        ..color = c.color.withValues(alpha: selected ? 1.0 : 0.5));
  GameFx.orb(canvas, Offset(rect.center.dx, rect.top + 18), 8, c.color,
      glow: selected ? 1.0 : 0.4);
  GameFx.text(canvas, c.name, Offset(rect.center.dx, rect.top + 36), 11,
      Potatuhs.textPrimary,
      weight: FontWeight.w800);
  GameFx.text(canvas, c.tag, Offset(rect.center.dx, rect.top + 50), 8, c.color,
      weight: FontWeight.w700);
}

// The GROW SEASON button, mirroring _FarmPainter._drawGrow.
void _legendGrow(Canvas canvas, Rect r) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  canvas.drawRRect(rr, Paint()..shader = Potatuhs.ctaGradient.createShader(r));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Potatuhs.ink.withValues(alpha: 0.8));
  GameFx.text(canvas, 'GROW SEASON  >', r.center, 15, Potatuhs.ink,
      display: true, weight: FontWeight.w800);
}

// (a) Core objects + verb: the four crop-family cards in the tray.
void _legendCrops(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  const gap = 8.0;
  final w = size.width;
  final chipW = (w - 24 - (_kCrops.length - 1) * gap) / _kCrops.length;
  final chipH = (size.height * 0.62).clamp(0.0, 92.0);
  final top = size.height * 0.5 - chipH / 2;
  for (int i = 0; i < _kCrops.length; i++) {
    final rect = Rect.fromLTWH(12 + i * (chipW + gap), top, chipW, chipH);
    _legendChip(canvas, rect, _kCrops[i], selected: i == 0);
  }
}

// (b) How to score: a planted field + a yield pop, then GROW to bank it.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.36),
      width: size.width * 0.42,
      height: size.height * 0.42);
  _legendPlot(canvas, r, nitrogen: 0.82, crop: _Family.cereal, highlight: true);
  GameFx.text(canvas, '+58', Offset(r.center.dx, r.top - 10), 18,
      _crop(_Family.cereal).color,
      display: true, weight: FontWeight.w800, glow: 0.5);
  final gr = Rect.fromLTWH(
      size.width * 0.16, size.height * 0.72, size.width * 0.68, 46);
  _legendGrow(canvas, gr);
}

// (c) The danger: repeat a family — soil drains, pests swarm the plot.
void _legendMonoculture(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.42),
      width: size.width * 0.46,
      height: size.height * 0.46);
  _legendPlot(canvas, r, nitrogen: 0.16, crop: _Family.cereal, pest: 0.85);
  GameFx.text(canvas, 'MONOCROP', Offset(size.width * 0.5, size.height * 0.82),
      15, _kMono,
      display: true, weight: FontWeight.w800, glow: 0.4);
}

// (d) The payoff / escalation: rotate families to keep soil rich for a bonus.
void _legendRotate(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cy = size.height * 0.40;
  final pw = size.width * 0.32, ph = size.height * 0.40;
  // Last season: nitrogen-fixing legume (soil recovering).
  final left = Rect.fromCenter(
      center: Offset(size.width * 0.28, cy), width: pw, height: ph);
  _legendPlot(canvas, left, nitrogen: 0.5, crop: _Family.legume);
  // This season: heavy feeder on the now-rich soil.
  final right = Rect.fromCenter(
      center: Offset(size.width * 0.72, cy), width: pw, height: ph);
  _legendPlot(canvas, right, nitrogen: 0.9, crop: _Family.cereal);
  // Rotation arrow between them.
  final ay = cy;
  final p = Paint()
    ..color = _kNitroHigh
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(size.width * 0.45, ay), Offset(size.width * 0.55, ay), p);
  canvas.drawLine(
      Offset(size.width * 0.55, ay), Offset(size.width * 0.51, ay - 5), p);
  canvas.drawLine(
      Offset(size.width * 0.55, ay), Offset(size.width * 0.51, ay + 5), p);
  GameFx.text(canvas, 'CLEAN ROTATION  +45',
      Offset(size.width * 0.5, size.height * 0.80), 14, const Color(0xFF9CCC65),
      display: true, weight: FontWeight.w800, glow: 0.4);
}

/// The visual manual for Crop Rotation — wired into the registry spec.
final List<LegendFrame> cropRotationLegendFrames = [
  const LegendFrame(
      caption: 'Pick a crop family from the tray to plant',
      paint: _legendCrops),
  const LegendFrame(
      caption: 'GROW the season to bank each field\'s harvest',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Repeat a family: soil drains, pests swarm',
      paint: _legendMonoculture),
  const LegendFrame(
      caption: 'Rotate families to keep soil rich for a bonus',
      paint: _legendRotate),
];

// ---------------------------------------------------------------------------
// Field model
// ---------------------------------------------------------------------------

class _Plot {
  double nitrogen; // 0..1 soil nitrogen (the bar)
  double pest; // 0..1 pest & disease pressure
  _Family? lastFamily; // what grew here last season
  int sameStreak; // consecutive seasons of the SAME family (monoculture)
  _Family? planned; // crop assigned for the season-in-progress

  // Harvest feedback (drives the pop animation after a GROW).
  double harvestAge; // <0 = idle
  int lastYield;
  bool lastMono; // last harvest was a monoculture repeat
  bool lastRotated; // last harvest rotated to a fresh family

  Rect rect; // current layout rect (set each frame)

  _Plot(this.nitrogen)
      : pest = 0,
        lastFamily = null,
        sameStreak = 0,
        planned = null,
        harvestAge = -1,
        lastYield = 0,
        lastMono = false,
        lastRotated = false,
        rect = Rect.zero;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class CropRotationGame extends StatefulWidget {
  final MiniGameSession session;
  const CropRotationGame({super.key, required this.session});

  @override
  State<CropRotationGame> createState() => _CropRotationGameState();
}

class _CropRotationGameState extends State<CropRotationGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final math.Random _rng;
  double _lastT = 0;
  double _clock = 0;

  // ---- game state ----------------------------------------------------------
  final List<_Plot> _plots = [];
  _Family? _selected; // crop currently held from the tray
  int _seasonsGrown = 0; // completed seasons (drives difficulty + field unlock)
  int _goodStreak = 0; // consecutive flawless (no-monoculture) seasons

  // Season-transition flash (banner shown briefly after a GROW).
  double _seasonFlash = -1;
  String _seasonMsg = '';
  Color _seasonMsgColor = Colors.white;

  // ---- juice ---------------------------------------------------------------
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // ---- layout (computed each frame, read by hit-testing) -------------------
  final List<Rect> _chipRects = []; // one per _kCrops entry
  Rect _growRect = Rect.zero;

  // Field count climbs as seasons clear: 4 → 6 → 8.
  int get _fieldCount => _seasonsGrown >= 5 ? 8 : (_seasonsGrown >= 2 ? 6 : 4);
  // Difficulty level for pest gain / monoculture severity.
  int get _level => _seasonsGrown.clamp(0, 8);

  @override
  void initState() {
    super.initState();
    _rng = math.Random(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    _initPlots(4);
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    // ATTRACT autopilot: this game knows how to farm itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). Dormant
    // unless the host is driving hands-free. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent move per host tick (~250ms). This plays Crop Rotation the way
  /// the game intends — no coordinate math, no random taps: it reads its OWN
  /// fields, and either plants the neediest empty field with a well-rotated crop
  /// (using the same select-then-plant path a tap would take) or, once every
  /// field is planted, GROWs the season to bank the harvest. Deterministic.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // Empty (unplanted) fields still waiting on a crop.
    final empty = _plots.where((p) => p.planned == null).toList();
    if (empty.isEmpty) {
      // Whole farm is planted — resolve the season (the GROW handler).
      _growSeason();
      return;
    }

    // Serve the neediest field first: lowest soil nitrogen (pest pressure nudges
    // it up the queue too, since a fouled plot needs attention).
    empty.sort((a, b) =>
        (a.nitrogen + a.pest * 0.15).compareTo(b.nitrogen + b.pest * 0.15));
    final field = empty.first;
    final family = _autoFamilyFor(field);

    // Plant via the game's own select + plant path (mirrors _onTapUp): pick the
    // crop up from the tray, then drop it on the field.
    setState(() {
      _selected = family;
      field.planned = family;
    });
  }

  /// Pick a good crop family for [field], NEVER repeating the family that grew
  /// there last season (the core rotation rule). Priorities: break a pest cycle
  /// with roots (potatoes), reload depleted soil with a legume, otherwise bank
  /// the biggest harvest the rotation allows.
  _Family _autoFamilyFor(_Plot field) {
    // Candidates exclude last season's family — always rotate.
    final candidates =
        _Family.values.where((f) => f != field.lastFamily).toList();

    // High pest/disease pressure → roots break the cycle hard.
    if (field.pest > 0.5 && candidates.contains(_Family.root)) {
      return _Family.root;
    }
    // Depleted soil → a legume fixes nitrogen and reloads the bar.
    if (field.nitrogen < 0.45 && candidates.contains(_Family.legume)) {
      return _Family.legume;
    }
    // Healthy soil → take the highest-yield crop the rotation permits.
    candidates.sort((a, b) => _crop(b).baseYield.compareTo(_crop(a).baseYield));
    return candidates.first;
  }

  void _initPlots(int n) {
    _plots.clear();
    for (int i = 0; i < n; i++) {
      // Start with healthy-but-varied soil so choices matter from season one.
      _plots.add(_Plot(0.55 + _rng.nextDouble() * 0.25));
    }
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;

    // Host owns the clock: only animate the "alive" idle scene until running,
    // and only run game logic while playing.
    setState(() {
      _clock += dt;

      // Particles + pops (cheap, always animate so the harvest reads as juicy).
      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      for (final p in _plots) {
        if (p.harvestAge >= 0) {
          p.harvestAge += dt;
          if (p.harvestAge > 1.4) p.harvestAge = -1;
        }
      }
      if (_seasonFlash >= 0) {
        _seasonFlash += dt;
        if (_seasonFlash > 1.6) _seasonFlash = -1;
      }
    });
  }

  // ---- input ---------------------------------------------------------------

  void _onTapUp(Offset pos) {
    if (!widget.session.isRunning) return;

    // GROW button.
    if (_growRect.contains(pos)) {
      _growSeason();
      return;
    }

    // Crop tray chips — pick up a family to plant.
    for (int i = 0; i < _chipRects.length; i++) {
      if (_chipRects[i].contains(pos)) {
        setState(() => _selected = _kCrops[i].family);
        return;
      }
    }

    // Fields — plant the held crop, or clear an already-planted field.
    for (final plot in _plots) {
      if (plot.rect.contains(pos)) {
        setState(() {
          if (_selected != null) {
            plot.planned = _selected;
          } else if (plot.planned != null) {
            plot.planned = null; // tap with empty hand clears the plan
          }
        });
        return;
      }
    }
  }

  // ---- resolve a season ----------------------------------------------------

  void _growSeason() {
    if (!widget.session.isRunning) return;

    final lvl = _level;
    int plantedCount = 0;
    bool anyMono = false;

    for (final plot in _plots) {
      final fam = plot.planned;

      if (fam == null) {
        // Fallow: no harvest, but the soil rests and pests fade.
        plot.nitrogen = (plot.nitrogen + 0.10).clamp(0.0, 1.0);
        plot.pest = (plot.pest * 0.80).clamp(0.0, 1.0);
        plot.lastFamily = null; // a rest season also breaks the family streak
        plot.sameStreak = 0;
        plot.lastYield = 0;
        plot.lastMono = false;
        plot.lastRotated = false;
        plot.harvestAge = 0;
        continue;
      }

      plantedCount++;
      final c = _crop(fam);
      final mono = plot.lastFamily == fam;
      final rotated = plot.lastFamily != null && plot.lastFamily != fam;

      // Yield: a crop's nitrogen-dependence decides how much soil matters.
      final soilFactor = 0.30 + 0.70 * plot.nitrogen;
      double y = c.baseYield * ((1 - c.nDep) + c.nDep * soilFactor);

      // Monoculture: yield + soil crash, compounding each repeated season.
      if (mono) {
        anyMono = true;
        final streak = plot.sameStreak + 1;
        plot.sameStreak = streak;
        y *= math.pow(0.55, streak).toDouble();
        plot.pest = (plot.pest + 0.26 + 0.04 * lvl + 0.04 * streak)
            .clamp(0.0, 1.0);
      } else {
        plot.sameStreak = 0;
        if (rotated) y *= 1.12; // a clean rotation keeps yields high
      }

      // Roots break pest/disease cycles hard; any rotation eases pressure.
      if (fam == _Family.root) {
        plot.pest = (plot.pest * 0.25).clamp(0.0, 1.0);
      } else if (rotated) {
        plot.pest = (plot.pest * 0.60).clamp(0.0, 1.0);
      } else {
        plot.pest = (plot.pest + 0.05 + 0.015 * lvl).clamp(0.0, 1.0);
      }

      // Pests/disease shave the harvest.
      y *= (1.0 - 0.55 * plot.pest);

      final yld = math.max(0, (y * 10).round());
      widget.session.addScore(yld);

      // Update soil nitrogen: legumes fix it, feeders drain it; monoculture
      // drains extra (the soil literally crashes).
      plot.nitrogen += c.nDelta;
      if (mono) plot.nitrogen -= 0.05 * plot.sameStreak;
      plot.nitrogen = plot.nitrogen.clamp(0.0, 1.0);

      plot.lastFamily = fam;
      plot.lastYield = yld;
      plot.lastMono = mono;
      plot.lastRotated = rotated;
      plot.harvestAge = 0;
      plot.planned = null;

      _pops.add(FxPop(plot.rect.center, '+$yld',
          mono ? const Color(0xFFFF7043) : c.color));
      _fx.addAll(FxBurst.spawn(plot.rect.center, c.color,
          count: mono ? 4 : 10, speed: 90));
    }

    // Flawless-rotation bonus: a season with crops planted and zero monoculture
    // grows a streak and pays a bonus; any repeat resets it.
    if (plantedCount > 0 && !anyMono) {
      _goodStreak++;
      widget.session.noteStreak(_goodStreak);
      final bonus = 20 + _goodStreak * 10 + lvl * 5;
      widget.session.addScore(bonus);
      _seasonMsg = 'CLEAN ROTATION  +$bonus';
      _seasonMsgColor = const Color(0xFF9CCC65);
    } else if (anyMono) {
      _goodStreak = 0;
      _seasonMsg = 'MONOCROP — SOIL DRAINED';
      _seasonMsgColor = const Color(0xFFFF7043);
    } else {
      _seasonMsg = 'FALLOW SEASON';
      _seasonMsgColor = Potatuhs.textSecondary;
    }

    setState(() {
      _seasonsGrown++;
      _seasonFlash = 0;
      _selected = null;
      // Unlock new fields as the farm grows (existing plots keep their soil).
      while (_plots.length < _fieldCount) {
        _plots.add(_Plot(0.55 + _rng.nextDouble() * 0.20));
      }
    });
  }

  // ---- layout --------------------------------------------------------------

  void _layout(Size sz) {
    final w = sz.width, h = sz.height;

    // Bottom band: GROW button, then the crop tray above it.
    final growH = 50.0;
    _growRect = Rect.fromLTWH(16, h - growH - 12, w - 32, growH);

    final trayH = 64.0;
    final trayTop = _growRect.top - trayH - 10;
    final chipW = (w - 32 - (_kCrops.length - 1) * 8) / _kCrops.length;
    _chipRects
      ..clear();
    for (int i = 0; i < _kCrops.length; i++) {
      _chipRects
          .add(Rect.fromLTWH(16 + i * (chipW + 8), trayTop, chipW, trayH));
    }

    // Field grid fills the space above the tray, below a slim header.
    const gridTop = 44.0;
    final gridBottom = trayTop - 12;
    final cols = _fieldCount <= 4 ? 2 : (_fieldCount <= 6 ? 3 : 4);
    final rows = (_fieldCount / cols).ceil();
    const gap = 10.0;
    final cellW = (w - 32 - (cols - 1) * gap) / cols;
    final cellH = (gridBottom - gridTop - (rows - 1) * gap) / rows;
    for (int i = 0; i < _plots.length; i++) {
      final r = i ~/ cols, col = i % cols;
      // Center the final (possibly short) row.
      final inRow = (r == rows - 1) ? _plots.length - r * cols : cols;
      final rowW = inRow * cellW + (inRow - 1) * gap;
      final startX = (w - rowW) / 2;
      _plots[i].rect = Rect.fromLTWH(
        startX + col * (cellW + gap),
        gridTop + r * (cellH + gap),
        cellW,
        cellH,
      );
    }
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _layout(Size(box.maxWidth, box.maxHeight));
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _FarmPainter(this, _clock),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter — reads the live state, repaints every tick.
// ---------------------------------------------------------------------------

class _FarmPainter extends CustomPainter {
  final _CropRotationGameState s;
  final double clock;
  _FarmPainter(this.s, this.clock);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, const Color(0xFF2E5A2E), clock, motes: 18);

    _drawHeader(canvas, size);
    for (final p in s._plots) {
      _drawPlot(canvas, p);
    }
    _drawTray(canvas);
    _drawGrow(canvas);

    FxBurst.paint(canvas, s._fx);
    for (final pop in s._pops) {
      pop.paint(canvas);
    }

    if (s._seasonFlash >= 0) _drawSeasonFlash(canvas, size);
    if (!s.widget.session.isRunning) _drawReady(canvas, size);
  }

  // ---- header --------------------------------------------------------------

  void _drawHeader(Canvas canvas, Size size) {
    GameFx.text(canvas, 'SEASON ${s._seasonsGrown + 1}', Offset(48, 20), 13,
        Potatuhs.textPrimary,
        weight: FontWeight.w800);
    if (s._goodStreak > 1) {
      GameFx.text(
          canvas,
          'ROTATION x${s._goodStreak}',
          Offset(size.width - 70, 20),
          11,
          const Color(0xFF9CCC65),
          weight: FontWeight.w700);
    }
  }

  // ---- one field plot ------------------------------------------------------

  void _drawPlot(Canvas canvas, _Plot p) {
    final r = p.rect;
    if (r.isEmpty) return;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));

    // Soil bed — color/darkness tracks nitrogen (rich = dark loam, poor = pale
    // dusty). Pests redden it.
    final loam = Color.lerp(
        const Color(0xFF6B4A2F), const Color(0xFF3A2A1C), p.nitrogen)!;
    final soil = Color.lerp(loam, const Color(0xFF7A5230), p.pest * 0.6)!;
    canvas.drawRRect(rr, Paint()..color = soil);

    // Tilled furrow lines for texture.
    final furrow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = r.top + 8; y < r.bottom - 6; y += 9) {
      canvas.drawLine(Offset(r.left + 6, y), Offset(r.right - 6, y), furrow);
    }

    // The planned (not-yet-grown) crop preview, or the standing crop glyph.
    final fam = p.planned;
    if (fam != null) {
      _drawCropGlyph(canvas, r, _crop(fam), preview: true);
    } else if (p.lastFamily != null && p.harvestAge < 0) {
      // Show what last grew here (stubble) so rotation history is legible.
      _drawStubble(canvas, r, _crop(p.lastFamily!));
    }

    // Harvest pop animation: the just-grown crop bursts up then fades.
    if (p.harvestAge >= 0 && p.lastFamily != null && p.lastYield > 0) {
      _drawCropGlyph(canvas, r, _crop(p.lastFamily!),
          grow: (p.harvestAge / 0.5).clamp(0.0, 1.0));
    }

    // Pest/disease warning — little bug ticks when pressure is high.
    if (p.pest > 0.35) {
      final n = (p.pest * 4).round().clamp(1, 4);
      for (int i = 0; i < n; i++) {
        final bx = r.left + 10 + i * 9.0;
        canvas.drawCircle(Offset(bx, r.top + 12), 2.6,
            Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.9));
      }
    }

    // Selection / plantable hint: if a crop is held, outline empty-able fields.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = (s._selected != null && p.planned == null)
          ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.10);
    canvas.drawRRect(rr, border);

    // Nitrogen bar along the bottom edge of the plot.
    final barY = r.bottom - 7;
    final barL = r.left + 8, barW = r.width - 16;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barL, barY, barW, 4), const Radius.circular(2)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    final nColor = Color.lerp(
        const Color(0xFFD84315), const Color(0xFF7CB342), p.nitrogen)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW * p.nitrogen, 4),
          const Radius.circular(2)),
      Paint()..color = nColor,
    );
    // "N" marker.
    GameFx.text(canvas, 'N', Offset(barL + 4, barY - 8), 7,
        Colors.white.withValues(alpha: 0.4),
        weight: FontWeight.w800);
  }

  // Family-specific crop glyph drawn inside the plot.
  void _drawCropGlyph(Canvas canvas, Rect r, _Crop c,
      {bool preview = false, double grow = 1.0}) {
    final cx = r.center.dx;
    final cy = r.center.dy - 2;
    final s0 = math.min(r.width, r.height);
    final a = preview ? 0.55 : (0.6 + 0.4 * grow);
    final base = c.color.withValues(alpha: a);
    final scale = preview ? 1.0 : (0.6 + 0.4 * grow);

    switch (c.family) {
      case _Family.cereal: // corn — tall stalks with a kernel head
        for (int i = -1; i <= 1; i++) {
          final x = cx + i * s0 * 0.16;
          final top = cy - s0 * 0.26 * scale;
          canvas.drawLine(
              Offset(x, cy + s0 * 0.18),
              Offset(x, top),
              Paint()
                ..color = const Color(0xFF8BC34A).withValues(alpha: a)
                ..strokeWidth = 2.4);
          canvas.drawCircle(Offset(x, top), s0 * 0.06 * scale,
              Paint()..color = base);
        }
        break;
      case _Family.legume: // beans — leafy mound with pods
        for (int i = 0; i < 5; i++) {
          final ang = -math.pi / 2 + (i - 2) * 0.5;
          final lx = cx + math.cos(ang) * s0 * 0.18 * scale;
          final ly = cy + math.sin(ang) * s0 * 0.16 * scale;
          canvas.drawCircle(Offset(lx, ly), s0 * 0.07 * scale, Paint()..color = base);
        }
        break;
      case _Family.root: // potatoes — tubers under a leafy tuft
        for (int i = -1; i <= 1; i++) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + i * s0 * 0.15, cy + s0 * 0.12),
                width: s0 * 0.16 * scale,
                height: s0 * 0.11 * scale),
            Paint()..color = base,
          );
        }
        canvas.drawCircle(Offset(cx, cy - s0 * 0.05), s0 * 0.08 * scale,
            Paint()..color = const Color(0xFF66BB6A).withValues(alpha: a));
        break;
      case _Family.brassica: // cabbage — concentric leafy head
        for (int i = 3; i >= 1; i--) {
          canvas.drawCircle(Offset(cx, cy), s0 * 0.07 * i * scale,
              Paint()..color = c.color.withValues(alpha: a * (0.4 + 0.2 * i)));
        }
        break;
    }
  }

  // Faint stubble showing what last grew here (rotation memory).
  void _drawStubble(Canvas canvas, Rect r, _Crop c) {
    final paint = Paint()
      ..color = c.color.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    final cx = r.center.dx, cy = r.center.dy;
    final s0 = math.min(r.width, r.height);
    for (int i = -1; i <= 1; i++) {
      final x = cx + i * s0 * 0.12;
      canvas.drawLine(Offset(x, cy + s0 * 0.10),
          Offset(x, cy - s0 * 0.04), paint);
    }
  }

  // ---- crop tray -----------------------------------------------------------

  void _drawTray(Canvas canvas) {
    for (int i = 0; i < s._chipRects.length; i++) {
      final rect = s._chipRects[i];
      final c = _kCrops[i];
      final isSel = s._selected == c.family;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      canvas.drawRRect(
          rr,
          Paint()
            ..color = isSel
                ? c.color.withValues(alpha: 0.30)
                : Potatuhs.inkPanel.withValues(alpha: 0.85));
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 2.4 : 1.2
            ..color = c.color.withValues(alpha: isSel ? 1.0 : 0.5));

      // Mini crop swatch.
      GameFx.orb(canvas, Offset(rect.center.dx, rect.top + 18), 8, c.color,
          glow: isSel ? 1.0 : 0.4);
      GameFx.text(canvas, c.name, Offset(rect.center.dx, rect.top + 36), 11,
          Potatuhs.textPrimary,
          weight: FontWeight.w800);
      GameFx.text(canvas, c.tag, Offset(rect.center.dx, rect.top + 50), 8,
          c.color, weight: FontWeight.w700);
    }
  }

  // ---- grow button ---------------------------------------------------------

  void _drawGrow(Canvas canvas) {
    final r = s._growRect;
    if (r.isEmpty) return;
    final anyPlanned = s._plots.any((p) => p.planned != null);
    final allPlanned =
        s._plots.isNotEmpty && s._plots.every((p) => p.planned != null);
    final pulse = allPlanned ? (0.5 + 0.5 * math.sin(clock * 5)) : 0.0;

    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = Potatuhs.ctaGradient.createShader(r)
        ..color = anyPlanned ? Colors.white : Colors.white.withValues(alpha: 0.5),
    );
    if (!anyPlanned) {
      canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.35));
    }
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + pulse * 2
          ..color = Potatuhs.ink.withValues(alpha: 0.8));
    GameFx.text(canvas, 'GROW SEASON  >', r.center, 16, Potatuhs.ink,
        display: true, weight: FontWeight.w800);
  }

  // ---- overlays ------------------------------------------------------------

  void _drawSeasonFlash(Canvas canvas, Size size) {
    final t = (s._seasonFlash / 1.6).clamp(0.0, 1.0);
    final a = (1 - t) * 0.95;
    GameFx.text(canvas, s._seasonMsg, Offset(size.width / 2, size.height * 0.32),
        18, s._seasonMsgColor.withValues(alpha: a),
        display: true, weight: FontWeight.w800, glow: 0.6 * a);
  }

  void _drawReady(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.55));
    GameFx.text(canvas, 'CROP ROTATION', Offset(size.width / 2, size.height * 0.40),
        26, Potatuhs.textPrimary,
        display: true, weight: FontWeight.w800, glow: 0.5);
    GameFx.text(
        canvas,
        'Pick a crop, plant your fields, GROW the season.',
        Offset(size.width / 2, size.height * 0.40 + 30),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w600);
    GameFx.text(
        canvas,
        'Rotate families so the soil never runs dry.',
        Offset(size.width / 2, size.height * 0.40 + 50),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _FarmPainter old) => true;
}
