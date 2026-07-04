import 'dart:math';

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// COMPANION PLANTING — adjacency-puzzle garden (BioScale.farmSystem)
//
// Place crop tiles onto a garden GRID so orthogonal NEIGHBORS help, not hurt.
// Good pairings (Three Sisters: corn+beans+squash; basil/marigold near tomato)
// score and thrive; bad neighbors (fennel near almost anything; onions next to
// beans; potato beside tomato) wilt. Each placement flashes a "+helps / -hurts"
// cue so the relationships are learnable. A brief GROWTH phase after the plot
// fills rewards good layouts. Accelerate: bigger plots + more crops with
// subtler relationships.
//
// HOST owns the clock, the 3·2·1 countdown, the score HUD and the results
// screen. This widget renders ONLY the play area, runs on ONE Ticker driving a
// single CustomPainter, and gates all progress on session.isRunning.
// ============================================================================

// ---------------------------------------------------------------------------
// Crop definitions
// ---------------------------------------------------------------------------

enum _Crop {
  corn,
  bean,
  squash,
  marigold,
  tomato,
  basil,
  potato,
  onion,
  fennel,
  carrot,
  cabbage,
  lettuce,
}

class _CropInfo {
  final String label;
  final String glyph; // 1–2 char badge initial
  final Color color;
  const _CropInfo(this.label, this.glyph, this.color);
}

const Map<_Crop, _CropInfo> _kCrops = {
  _Crop.corn: _CropInfo('Corn', 'Co', Color(0xFFFFD54F)),
  _Crop.bean: _CropInfo('Beans', 'Be', Color(0xFF66BB6A)),
  _Crop.squash: _CropInfo('Squash', 'Sq', Color(0xFFFF8A65)),
  _Crop.marigold: _CropInfo('Marigold', 'Mg', Color(0xFFFFB300)),
  _Crop.tomato: _CropInfo('Tomato', 'To', Color(0xFFEF5350)),
  _Crop.basil: _CropInfo('Basil', 'Ba', Color(0xFF26A69A)),
  _Crop.potato: _CropInfo('Potato', 'Po', Color(0xFFBCAAA4)),
  _Crop.onion: _CropInfo('Onion', 'On', Color(0xFFCE93D8)),
  _Crop.fennel: _CropInfo('Fennel', 'Fe', Color(0xFFC0CA33)),
  _Crop.carrot: _CropInfo('Carrot', 'Ca', Color(0xFFFFA726)),
  _Crop.cabbage: _CropInfo('Cabbage', 'Cb', Color(0xFF4DB6AC)),
  _Crop.lettuce: _CropInfo('Lettuce', 'Le', Color(0xFF9CCC65)),
};

// Friendly companion pairs (symmetric). Real companion-planting relationships:
// nitrogen fixing, pest repulsion, shade, pollinator attraction.
const List<List<_Crop>> _kFriendPairs = [
  // Three Sisters
  [_Crop.corn, _Crop.bean],
  [_Crop.corn, _Crop.squash],
  [_Crop.bean, _Crop.squash],
  // Marigold the pest-repeller
  [_Crop.marigold, _Crop.tomato],
  [_Crop.marigold, _Crop.potato],
  [_Crop.marigold, _Crop.bean],
  [_Crop.marigold, _Crop.squash],
  // Basil + tomato (pest repel + flavour)
  [_Crop.basil, _Crop.tomato],
  // Beans fix nitrogen → feed heavy feeders
  [_Crop.bean, _Crop.cabbage],
  [_Crop.bean, _Crop.potato],
  [_Crop.potato, _Crop.corn],
  [_Crop.potato, _Crop.cabbage],
  // Carrot / onion / lettuce trio
  [_Crop.carrot, _Crop.onion],
  [_Crop.carrot, _Crop.tomato],
  [_Crop.carrot, _Crop.lettuce],
  [_Crop.onion, _Crop.cabbage],
  [_Crop.lettuce, _Crop.onion],
];

// Antagonistic pairs (symmetric). Allelopathy, shared pests, competition.
const List<List<_Crop>> _kFoePairs = [
  [_Crop.onion, _Crop.bean], // alliums inhibit legume nodulation
  [_Crop.potato, _Crop.tomato], // both nightshades — blight + beetles
  [_Crop.potato, _Crop.squash], // heavy feeders compete
  [_Crop.tomato, _Crop.corn], // shared earworm / fruitworm
  [_Crop.cabbage, _Crop.tomato],
  // Fennel — allelopathic loner, antagonises nearly everything
  [_Crop.fennel, _Crop.tomato],
  [_Crop.fennel, _Crop.bean],
  [_Crop.fennel, _Crop.corn],
  [_Crop.fennel, _Crop.carrot],
  [_Crop.fennel, _Crop.cabbage],
  [_Crop.fennel, _Crop.potato],
  [_Crop.fennel, _Crop.squash],
  [_Crop.fennel, _Crop.onion],
  [_Crop.fennel, _Crop.basil],
  [_Crop.fennel, _Crop.lettuce],
];

int _pairKey(_Crop a, _Crop b) {
  final x = a.index, y = b.index;
  return x < y ? x * 100 + y : y * 100 + x;
}

final Map<int, int> _kRelations = () {
  final m = <int, int>{};
  for (final p in _kFriendPairs) {
    m[_pairKey(p[0], p[1])] = 1;
  }
  for (final p in _kFoePairs) {
    m[_pairKey(p[0], p[1])] = -1;
  }
  return m;
}();

/// +1 = helps, -1 = hurts, 0 = neutral (same crop is neutral).
int _relation(_Crop a, _Crop b) =>
    a == b ? 0 : (_kRelations[_pairKey(a, b)] ?? 0);

// ---------------------------------------------------------------------------
// Lightweight transient objects
// ---------------------------------------------------------------------------

class _Tile {
  final _Crop crop;
  double x, y, homeX, homeY;
  _Tile(this.crop, this.x, this.y)
      : homeX = x,
        homeY = y;
}

class _Cell {
  _Crop crop;
  double age; // grow-in animation
  double thrive; // set in growth phase: >0 thrives, <0 wilts, 0 neutral
  _Cell(this.crop)
      : age = 0,
        thrive = 0;
}

class _Link {
  final Offset a, b;
  final Color color;
  double age;
  _Link(this.a, this.b, this.color) : age = 0;
}

class _Pop {
  double x, y, age;
  final String text;
  final Color color;
  _Pop(this.x, this.y, this.text, this.color) : age = 0;
}

class _Dot {
  double x, y, vx, vy, life, size;
  final Color color;
  _Dot(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color);
}

enum _Phase { placing, growth }

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL garden
// components (the same soil beds, crop orbs and help/hurt links the live game
// renders). Static and cheap: painted once on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

// The game's own link/thrive/wilt palette (matches the inline colours the
// _GardenPainter uses in play — named here, not invented).
const Color _kHelpGreen = Color(0xFF8BE58B); // "+helps" link + thrive glow
const Color _kHurtRed = Color(0xFFFF6B6B); // "−hurts" link + wilt cue
const Color _kThriveTint = Color(0xFFB9F6CA); // healthy leaf tint (growth)
const Color _kWiltTint = Color(0xFF6D4C41); // browned wilt tint (growth)

/// One rounded soil bed, mirroring `_GardenPainter._drawGrid`. [tint] draws the
/// green/red/neutral hover ring; otherwise a faint white edge.
void _legendCell(Canvas canvas, Rect rect,
    {Color? tint, bool occupied = false}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));
  canvas.drawRRect(
    rr,
    Paint()
      ..color = _GardenPainter._soil.withValues(alpha: occupied ? 0.85 : 0.5),
  );
  if (tint != null) {
    canvas.drawRRect(rr, Paint()..color = tint.withValues(alpha: 0.18));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = tint.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  } else {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withValues(alpha: occupied ? 0.05 : 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// One planted crop orb + badge, mirroring `_GardenPainter._drawPlants`.
/// [thrive] > 0 swells + green-glows it; < 0 shrinks + browns it.
void _legendPlant(Canvas canvas, Offset center, _Crop crop, double radius,
    {double thrive = 0}) {
  final info = _kCrops[crop]!;
  var r = radius;
  Color body = info.color;
  if (thrive > 0) {
    r *= 1.18;
    body = Color.lerp(info.color, _kThriveTint, 0.25)!;
    canvas.drawCircle(
      center,
      r + 5,
      Paint()
        ..color = _kHelpGreen.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  } else if (thrive < 0) {
    r *= 0.78;
    body = Color.lerp(info.color, _kWiltTint, 0.55)!;
  }
  GameFx.orb(canvas, center, r, body, glow: 0.5);
  GameFx.text(canvas, info.glyph, center, r * 0.7,
      Colors.white.withValues(alpha: 0.95),
      weight: FontWeight.w800);
}

/// A help/hurt relationship beam, mirroring `_GardenPainter._drawLinks`.
void _legendLink(Canvas canvas, Offset a, Offset b, Color color) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );
}

/// A small downward chevron drop cue (as in the placing preview).
void _legendDrop(Canvas canvas, Offset tip, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(tip.translate(-8, -9), tip, p);
  canvas.drawLine(tip.translate(8, -9), tip, p);
}

// Frame 1 — the verb: drag a crop tile from the tray onto an empty soil cell.
void _legendPlace(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gx = size.width / 2 - cs;
  final gy = size.height * 0.34;
  final cells = <Rect>[];
  for (int r = 0; r < 2; r++) {
    for (int c = 0; c < 2; c++) {
      cells.add(Rect.fromLTWH(gx + c * cs + 3, gy + r * cs + 3, cs - 6, cs - 6));
    }
  }
  // i0 already planted (corn); i1 is the green-tinted drop target.
  for (int i = 0; i < 4; i++) {
    _legendCell(canvas, cells[i],
        tint: i == 1 ? _kHelpGreen : null, occupied: i == 0);
  }
  _legendPlant(canvas, cells[0].center, _Crop.corn, cs * 0.30);
  // Beans tile hovering above the target, dropping in.
  final tileC = Offset(cells[1].center.dx, gy - cs * 0.62);
  _legendPlant(canvas, tileC, _Crop.bean, cs * 0.30);
  _legendDrop(canvas, Offset(cells[1].center.dx, gy - cs * 0.14),
      _kHelpGreen);
}

// Frame 2 — how to score: friendly neighbours flash a green "+helps" link.
void _legendHelps(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gy = size.height * 0.40;
  final left = Rect.fromCenter(
      center: Offset(size.width * 0.5 - cs * 0.55, gy),
      width: cs,
      height: cs);
  final right = Rect.fromCenter(
      center: Offset(size.width * 0.5 + cs * 0.55, gy),
      width: cs,
      height: cs);
  _legendCell(canvas, left, occupied: true);
  _legendCell(canvas, right, occupied: true);
  _legendLink(canvas, left.center, right.center, _kHelpGreen);
  _legendPlant(canvas, left.center, _Crop.corn, cs * 0.30);
  _legendPlant(canvas, right.center, _Crop.bean, cs * 0.30);
  GameFx.text(canvas, '+helps  +12', Offset(size.width * 0.5, gy - cs * 0.85),
      13, _kHelpGreen,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame 3 — the danger: bad neighbours flash a red "−hurts" link + break combo.
void _legendHurts(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gy = size.height * 0.40;
  final left = Rect.fromCenter(
      center: Offset(size.width * 0.5 - cs * 0.55, gy),
      width: cs,
      height: cs);
  final right = Rect.fromCenter(
      center: Offset(size.width * 0.5 + cs * 0.55, gy),
      width: cs,
      height: cs);
  _legendCell(canvas, left, occupied: true);
  _legendCell(canvas, right, occupied: true);
  _legendLink(canvas, left.center, right.center, _kHurtRed);
  // Potato beside tomato — both nightshades, a classic foe pairing.
  _legendPlant(canvas, left.center, _Crop.potato, cs * 0.30, thrive: -1);
  _legendPlant(canvas, right.center, _Crop.tomato, cs * 0.30, thrive: -1);
  GameFx.text(canvas, '−hurts', Offset(size.width * 0.5, gy - cs * 0.85), 13,
      _kHurtRed,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame 4 — the payoff/twist: fill the bed foe-free for a FLAWLESS harvest.
void _legendFlawless(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.20).clamp(18.0, 60.0);
  final gx = size.width / 2 - cs * 1.5;
  final gy = size.height * 0.24;
  // 3×3, all friend/neutral crops → every plant thrives, zero foes.
  const layout = [
    _Crop.corn, _Crop.bean, _Crop.squash, //
    _Crop.bean, _Crop.squash, _Crop.corn, //
    _Crop.marigold, _Crop.corn, _Crop.bean,
  ];
  for (int i = 0; i < 9; i++) {
    final c = i % 3, r = i ~/ 3;
    final rect = Rect.fromLTWH(gx + c * cs + 3, gy + r * cs + 3, cs - 6, cs - 6);
    _legendCell(canvas, rect, occupied: true);
    _legendPlant(canvas, rect.center, layout[i], cs * 0.30, thrive: 1);
  }
  GameFx.text(canvas, 'FLAWLESS PLOT', Offset(size.width * 0.5, gy + cs * 3.3),
      14, Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.6);
}

/// The visual manual for Companion Planting — wired into the registry spec.
final List<LegendFrame> companionPlantingLegendFrames = [
  const LegendFrame(
      caption: 'Drag crop tiles from the tray onto empty soil',
      paint: _legendPlace),
  const LegendFrame(
      caption: 'Friends touching flash green: +12 each',
      paint: _legendHelps),
  const LegendFrame(
      caption: 'Foes flash red — they wilt and break your combo',
      paint: _legendHurts),
  const LegendFrame(
      caption: 'Fill the bed foe-free for a FLAWLESS harvest bonus',
      paint: _legendFlawless),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class CompanionPlantingGame extends StatefulWidget {
  final MiniGameSession session;
  const CompanionPlantingGame({super.key, required this.session});

  @override
  State<CompanionPlantingGame> createState() => _CompanionPlantingGameState();
}

class _CompanionPlantingGameState extends State<CompanionPlantingGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final int _seed;
  late Random _rng;
  double _lastT = 0;
  double _clock = 0;

  // ---- run state ----
  int _combo = 0;
  int _plotsCompleted = 0;
  int _flawlessStreak = 0;
  int _level = 0;

  // ---- plot ----
  int _cols = 3, _rows = 3;
  List<_Cell?> _grid = [];
  List<_Crop> _palette = [];
  final List<_Tile> _hand = [];
  static const int _handSize = 5;

  // ---- phase ----
  _Phase _phase = _Phase.placing;
  double _growthAge = 0;
  bool _growthAwarded = false;

  // ---- input ----
  int? _dragIndex;
  int? _hoverCell;

  // ---- effects ----
  final List<_Link> _links = [];
  final List<_Pop> _pops = [];
  final List<_Dot> _fx = [];

  // ---- geometry ----
  Size _sz = Size.zero;
  Offset _origin = Offset.zero;
  double _cellSize = 0;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    _rng = Random(_seed);
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _startPlot();
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
  /// One hands-free placement per host tick (~250ms). This plays Companion
  /// Planting *well*, not randomly: it scores every (hand-tile × empty-cell)
  /// combo with the game's OWN friend/foe rules — summing [_relation] over the
  /// occupied orthogonal neighbours ([_neighbors]) — and drops the tile into the
  /// spot with the best net benefit, always preferring a placement that creates
  /// NO foe adjacency (a foe-free spot nets ≥ 0, so whenever one exists we take
  /// it and never wilt a neighbour). Ties resolve to the first candidate in
  /// hand/grid order → fully deterministic. It calls the game's own
  /// [_placeTile]; the host owns the clock, so the round still ends on time
  /// while the bot banks real points and fills flawless plots.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.placing) return; // growth phase self-advances
    if (_hand.isEmpty) return;

    // Gather the empty cells once.
    final empties = <int>[];
    for (int i = 0; i < _grid.length; i++) {
      if (_grid[i] == null) empties.add(i);
    }
    if (empties.isEmpty) return;

    _Tile? bestTile;
    int bestCell = -1;
    int bestNet = 0;
    bool bestFoeFree = false;
    bool found = false;

    for (final tile in _hand) {
      for (final cell in empties) {
        int net = 0;
        bool foe = false;
        for (final n in _neighbors(cell)) {
          final occ = _grid[n];
          if (occ == null) continue;
          final rel = _relation(tile.crop, occ.crop);
          net += rel;
          if (rel < 0) foe = true;
        }
        final foeFree = !foe;
        // Ranking: any foe-free spot beats any spot that wilts a neighbour;
        // within the same class prefer higher net; ties keep the first seen.
        final better = !found ||
            (foeFree && !bestFoeFree) ||
            (foeFree == bestFoeFree && net > bestNet);
        if (better) {
          found = true;
          bestTile = tile;
          bestCell = cell;
          bestNet = net;
          bestFoeFree = foeFree;
        }
      }
    }

    if (bestTile == null || bestCell < 0) return;
    setState(() => _placeTile(bestTile!, bestCell));
  }

  // ---- plot setup ----------------------------------------------------------

  /// Plot dimensions per level — bigger plots as the climb continues.
  List<int> _plotForLevel(int lvl) {
    switch (lvl) {
      case 0:
        return [3, 3];
      case 1:
        return [4, 3];
      case 2:
        return [4, 4];
      case 3:
        return [4, 4];
      case 4:
        return [5, 4];
      default:
        return [5, 5];
    }
  }

  /// Crop palette per level. Early levels are all friends/neutral (pure
  /// positive feedback); foes (fennel, onion×bean, potato×tomato) enter later.
  List<_Crop> _paletteForLevel(int lvl) {
    final p = <_Crop>[_Crop.corn, _Crop.bean, _Crop.squash, _Crop.marigold];
    if (lvl >= 1) p.addAll([_Crop.tomato, _Crop.basil]);
    if (lvl >= 2) p.addAll([_Crop.potato, _Crop.onion]);
    if (lvl >= 3) p.add(_Crop.fennel);
    if (lvl >= 4) p.addAll([_Crop.carrot, _Crop.cabbage]);
    if (lvl >= 5) p.add(_Crop.lettuce);
    return p;
  }

  void _startPlot() {
    _level = _plotsCompleted.clamp(0, 6);
    final dim = _plotForLevel(_level);
    _cols = dim[0];
    _rows = dim[1];
    _grid = List<_Cell?>.filled(_cols * _rows, null);
    _palette = _paletteForLevel(_level);
    _hand.clear();
    _links.clear();
    _phase = _Phase.placing;
    _growthAge = 0;
    _growthAwarded = false;
    _dragIndex = null;
    _hoverCell = null;
    _computeGrid();
    _refillHand();
  }

  int get _placedCount => _grid.where((c) => c != null).length;
  int get _totalCells => _cols * _rows;

  void _refillHand() {
    while (_hand.length < _handSize &&
        _placedCount + _hand.length < _totalCells) {
      _hand.add(_Tile(_palette[_rng.nextInt(_palette.length)], 0, 0));
    }
    _layoutHand();
  }

  void _computeGrid() {
    if (_sz == Size.zero) return;
    final top = 64.0;
    final trayTop = _sz.height * 0.66;
    final areaW = _sz.width - 32;
    final areaH = (trayTop - top - 12).clamp(40.0, double.infinity);
    _cellSize = min(areaW / _cols, areaH / _rows);
    final gridW = _cellSize * _cols;
    final gridH = _cellSize * _rows;
    _origin = Offset(
      (_sz.width - gridW) / 2,
      top + (areaH - gridH) / 2,
    );
  }

  void _layoutHand() {
    if (_sz == Size.zero || _hand.isEmpty) return;
    final n = _hand.length;
    final spacing = (_sz.width - 32) / _handSize;
    final tileW = spacing.clamp(56.0, 92.0);
    final startX = _sz.width / 2 - (n - 1) * tileW / 2;
    final y = _sz.height * 0.86;
    for (int i = 0; i < n; i++) {
      _hand[i].x = startX + i * tileW;
      _hand[i].y = y;
      _hand[i].homeX = _hand[i].x;
      _hand[i].homeY = _hand[i].y;
    }
  }

  // ---- geometry helpers ----------------------------------------------------

  Offset _cellCenter(int idx) {
    final c = idx % _cols, r = idx ~/ _cols;
    return Offset(
      _origin.dx + (c + 0.5) * _cellSize,
      _origin.dy + (r + 0.5) * _cellSize,
    );
  }

  int? _cellAt(Offset p) {
    if (_cellSize <= 0) return null;
    final lx = p.dx - _origin.dx, ly = p.dy - _origin.dy;
    if (lx < 0 || ly < 0) return null;
    final c = (lx / _cellSize).floor(), r = (ly / _cellSize).floor();
    if (c < 0 || c >= _cols || r < 0 || r >= _rows) return null;
    return r * _cols + c;
  }

  List<int> _neighbors(int idx) {
    final c = idx % _cols, r = idx ~/ _cols;
    final out = <int>[];
    if (c > 0) out.add(idx - 1);
    if (c < _cols - 1) out.add(idx + 1);
    if (r > 0) out.add(idx - _cols);
    if (r < _rows - 1) out.add(idx + _cols);
    return out;
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (!widget.session.isRunning) return;

    setState(() {
      _clock += dt;

      for (final c in _grid) {
        if (c != null) c.age += dt;
      }
      for (final l in _links) {
        l.age += dt;
      }
      _links.removeWhere((l) => l.age > 0.9);
      for (final p in _pops) {
        p.age += dt;
        p.y -= 26 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.3);
      for (final d in _fx) {
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vy += 200 * dt;
        d.life -= dt;
      }
      _fx.removeWhere((d) => d.life <= 0);

      if (_phase == _Phase.growth) {
        _growthAge += dt;
        if (_growthAge > 0.15 && !_growthAwarded) _awardGrowth();
        if (_growthAge > 1.6) {
          _plotsCompleted++;
          _startPlot();
        }
      }
    });
  }

  // ---- placement -----------------------------------------------------------

  void _placeTile(_Tile tile, int cell) {
    _grid[cell] = _Cell(tile.crop);
    _hand.remove(tile);

    // Score adjacency against already-placed neighbours.
    int friends = 0, foes = 0;
    final here = _cellCenter(cell);
    for (final n in _neighbors(cell)) {
      final occ = _grid[n];
      if (occ == null) continue;
      final rel = _relation(tile.crop, occ.crop);
      if (rel > 0) {
        friends++;
        _links.add(_Link(here, _cellCenter(n), const Color(0xFF8BE58B)));
      } else if (rel < 0) {
        foes++;
        _links.add(_Link(here, _cellCenter(n), const Color(0xFFFF6B6B)));
      }
    }

    if (foes == 0 && friends > 0) {
      _combo++;
    } else if (foes > 0) {
      _combo = 0;
    }

    int pts = friends * 12;
    if (foes == 0 && friends > 0 && _combo > 1) pts += _combo * 4;
    if (pts > 0) {
      widget.session.addScore(pts);
      _burst(here, _kCrops[tile.crop]!.color, 10);
    }

    // Learnable cue.
    if (friends > 0) {
      _pops.add(_Pop(here.dx, here.dy - _cellSize * 0.5,
          '+helps ×$friends', const Color(0xFF8BE58B)));
    }
    if (foes > 0) {
      _pops.add(_Pop(here.dx, here.dy + _cellSize * 0.5,
          '−hurts ×$foes', const Color(0xFFFF6B6B)));
    }

    _refillHand();

    if (_placedCount >= _totalCells) {
      _phase = _Phase.growth;
      _growthAge = 0;
      _growthAwarded = false;
    }
  }

  /// Growth phase: each plant's net (friend − foe) neighbours decide whether it
  /// thrives (bonus) or wilts. A foe-free plot is a flawless harvest bonus.
  void _awardGrowth() {
    _growthAwarded = true;
    int bonus = 0;
    int foeEdges = 0;
    for (int i = 0; i < _grid.length; i++) {
      final cell = _grid[i];
      if (cell == null) continue;
      int net = 0;
      for (final n in _neighbors(i)) {
        final occ = _grid[n];
        if (occ == null) continue;
        final rel = _relation(cell.crop, occ.crop);
        net += rel;
        if (rel < 0) foeEdges++;
      }
      cell.thrive = net.toDouble();
      if (net > 0) {
        final b = 8 * net;
        bonus += b;
        _burst(_cellCenter(i), const Color(0xFF8BE58B), 8);
      }
    }
    // foeEdges double-counts each bad edge (both endpoints) — that's fine, it
    // just makes a clean plot the clear target.
    final flawless = foeEdges == 0;
    if (flawless) {
      _flawlessStreak++;
      widget.session.noteStreak(_flawlessStreak);
      final hb = 25 + _level * 10;
      bonus += hb;
      final mid = Offset(_sz.width / 2, _origin.dy + _rows * _cellSize / 2);
      _pops.add(_Pop(mid.dx, mid.dy,
          'FLAWLESS PLOT  +$hb', const Color(0xFFFFD54F)));
    } else {
      _flawlessStreak = 0;
    }
    if (bonus > 0) {
      widget.session.addScore(bonus);
    }
  }

  void _burst(Offset at, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 50 + _rng.nextDouble() * 110;
      _fx.add(_Dot(at.dx, at.dy, cos(a) * spd, sin(a) * spd - 30,
          0.4 + _rng.nextDouble() * 0.4, 2 + _rng.nextDouble() * 3, color));
    }
  }

  // ---- input ---------------------------------------------------------------

  void _onPanStart(Offset pos) {
    if (!widget.session.isRunning || _phase != _Phase.placing) return;
    double best = double.infinity;
    int bestI = -1;
    for (int i = 0; i < _hand.length; i++) {
      final t = _hand[i];
      final d = (pos - Offset(t.x, t.y)).distance;
      if (d < 54 && d < best) {
        best = d;
        bestI = i;
      }
    }
    if (bestI >= 0) _dragIndex = bestI;
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex == null || _dragIndex! >= _hand.length) return;
    setState(() {
      _hand[_dragIndex!].x = pos.dx;
      _hand[_dragIndex!].y = pos.dy;
      final cell = _cellAt(pos);
      _hoverCell = (cell != null && _grid[cell] == null) ? cell : null;
    });
  }

  void _onPanEnd() {
    if (_dragIndex == null || _dragIndex! >= _hand.length) return;
    final tile = _hand[_dragIndex!];
    final cell = _cellAt(Offset(tile.x, tile.y));
    setState(() {
      if (cell != null && _grid[cell] == null) {
        _placeTile(tile, cell);
      } else {
        tile.x = tile.homeX;
        tile.y = tile.homeY;
      }
      _dragIndex = null;
      _hoverCell = null;
    });
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        _sz = newSz;
        _computeGrid();
        _layoutHand();
      }
      // Hover preview net, for the cell tint.
      int hoverNet = 0;
      if (_hoverCell != null && _dragIndex != null &&
          _dragIndex! < _hand.length) {
        final crop = _hand[_dragIndex!].crop;
        for (final n in _neighbors(_hoverCell!)) {
          final occ = _grid[n];
          if (occ != null) hoverNet += _relation(crop, occ.crop);
        }
      }
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GardenPainter(
              clock: _clock,
              running: widget.session.isRunning,
              phase: _phase,
              growthAge: _growthAge,
              cols: _cols,
              rows: _rows,
              origin: _origin,
              cellSize: _cellSize,
              grid: _grid,
              hand: _hand,
              dragIndex: _dragIndex,
              hoverCell: _hoverCell,
              hoverNet: hoverNet,
              links: _links,
              pops: _pops,
              fx: _fx,
              combo: _combo,
              level: _level,
              plots: _plotsCompleted,
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GardenPainter extends CustomPainter {
  final double clock;
  final bool running;
  final _Phase phase;
  final double growthAge;
  final int cols, rows;
  final Offset origin;
  final double cellSize;
  final List<_Cell?> grid;
  final List<_Tile> hand;
  final int? dragIndex;
  final int? hoverCell;
  final int hoverNet;
  final List<_Link> links;
  final List<_Pop> pops;
  final List<_Dot> fx;
  final int combo;
  final int level;
  final int plots;

  _GardenPainter({
    required this.clock,
    required this.running,
    required this.phase,
    required this.growthAge,
    required this.cols,
    required this.rows,
    required this.origin,
    required this.cellSize,
    required this.grid,
    required this.hand,
    required this.dragIndex,
    required this.hoverCell,
    required this.hoverNet,
    required this.links,
    required this.pops,
    required this.fx,
    required this.combo,
    required this.level,
    required this.plots,
  });

  static const Color _soil = Color(0xFF3E2C22);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, const Color(0xFF4C7A2F), clock, motes: 22);

    _drawGrid(canvas);
    _drawLinks(canvas);
    _drawPlants(canvas);
    if (phase == _Phase.placing) _drawHand(canvas);
    _drawParticles(canvas);
    _drawPops(canvas);
    _drawHud(canvas, size);
    if (!running) _drawReady(canvas, size);
  }

  // ---- grid ----------------------------------------------------------------

  void _drawGrid(Canvas canvas) {
    if (cellSize <= 0) return;
    const inset = 3.0;
    for (int i = 0; i < cols * rows; i++) {
      final c = i % cols, r = i ~/ cols;
      final rect = Rect.fromLTWH(
        origin.dx + c * cellSize + inset,
        origin.dy + r * cellSize + inset,
        cellSize - inset * 2,
        cellSize - inset * 2,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));
      final occupied = grid[i] != null;
      // Soil bed.
      canvas.drawRRect(
        rr,
        Paint()
          ..color = _soil.withValues(alpha: occupied ? 0.85 : 0.5),
      );
      // Hover tint: green if net friendly, red if net hostile.
      if (i == hoverCell) {
        final hint = hoverNet > 0
            ? const Color(0xFF8BE58B)
            : hoverNet < 0
                ? const Color(0xFFFF6B6B)
                : Colors.white;
        canvas.drawRRect(rr, Paint()..color = hint.withValues(alpha: 0.18));
        canvas.drawRRect(
          rr,
          Paint()
            ..color = hint.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawRRect(
          rr,
          Paint()
            ..color = Colors.white.withValues(alpha: occupied ? 0.05 : 0.09)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  // ---- relationship links --------------------------------------------------

  void _drawLinks(Canvas canvas) {
    for (final l in links) {
      final a = (1 - l.age / 0.9).clamp(0.0, 1.0);
      canvas.drawLine(
        l.a,
        l.b,
        Paint()
          ..color = l.color.withValues(alpha: 0.7 * a)
          ..strokeWidth = 3 * a + 1
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ---- plants --------------------------------------------------------------

  void _drawPlants(Canvas canvas) {
    if (cellSize <= 0) return;
    for (int i = 0; i < grid.length; i++) {
      final cell = grid[i];
      if (cell == null) continue;
      final info = _kCrops[cell.crop]!;
      final center = Offset(
        origin.dx + (i % cols + 0.5) * cellSize,
        origin.dy + (i ~/ cols + 0.5) * cellSize,
      );
      final pop = (cell.age / 0.25).clamp(0.0, 1.0);
      var radius = cellSize * 0.30 * Curves.easeOutBack.transform(pop);

      // Growth-phase thrive/wilt response.
      Color body = info.color;
      if (phase == _Phase.growth && growthAge > 0.15) {
        final g = ((growthAge - 0.15) / 0.6).clamp(0.0, 1.0);
        if (cell.thrive > 0) {
          radius *= 1 + 0.18 * g;
          body = Color.lerp(info.color, const Color(0xFFB9F6CA), 0.25 * g)!;
          canvas.drawCircle(
            center,
            radius + 5,
            Paint()
              ..color = const Color(0xFF8BE58B).withValues(alpha: 0.25 * g)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        } else if (cell.thrive < 0) {
          radius *= 1 - 0.22 * g;
          body = Color.lerp(info.color, const Color(0xFF6D4C41), 0.55 * g)!;
        }
      }

      GameFx.orb(canvas, center, radius, body, glow: 0.5);
      GameFx.text(canvas, info.glyph, center, cellSize * 0.20,
          Colors.white.withValues(alpha: 0.95),
          weight: FontWeight.w800);
      if (cellSize > 54) {
        GameFx.text(
          canvas,
          info.label,
          center.translate(0, radius + cellSize * 0.16),
          cellSize * 0.13,
          Colors.white.withValues(alpha: 0.6),
          weight: FontWeight.w600,
        );
      }
    }
  }

  // ---- hand / tray ---------------------------------------------------------

  void _drawHand(Canvas canvas) {
    for (int i = 0; i < hand.length; i++) {
      final t = hand[i];
      final info = _kCrops[t.crop]!;
      final dragging = i == dragIndex;
      final r = dragging ? cellSize * 0.32 : 22.0;
      final radius = r.clamp(18.0, 30.0);
      if (dragging) {
        canvas.drawCircle(
          Offset(t.x, t.y),
          radius + 8,
          Paint()..color = info.color.withValues(alpha: 0.2),
        );
      }
      GameFx.orb(canvas, Offset(t.x, t.y), radius, info.color, glow: 0.6);
      GameFx.text(canvas, info.glyph, Offset(t.x, t.y), radius * 0.7,
          Colors.white, weight: FontWeight.w800);
      GameFx.text(
        canvas,
        info.label,
        Offset(t.x, t.y + radius + 11),
        10,
        Colors.white.withValues(alpha: 0.65),
        weight: FontWeight.w600,
      );
    }
  }

  // ---- particles / pops ----------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final d in fx) {
      final a = d.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(d.x, d.y), d.size * a,
          Paint()..color = d.color.withValues(alpha: a));
    }
  }

  void _drawPops(Canvas canvas) {
    for (final p in pops) {
      final a = (1 - p.age / 1.3).clamp(0.0, 1.0);
      GameFx.text(canvas, p.text, Offset(p.x, p.y), 13 + p.age * 1.5,
          p.color.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.5 * a);
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Phase / plot label (top-left). Host draws the run timer + score.
    final label = phase == _Phase.growth ? 'GROWING…' : 'PLANT THE PLOT';
    GameFx.text(canvas, label, Offset(64, 22), 11,
        Colors.white.withValues(alpha: 0.45),
        weight: FontWeight.w700);
    if (plots > 0) {
      GameFx.text(canvas, '×$plots harvested', Offset(70, 40), 10,
          Colors.white.withValues(alpha: 0.3),
          weight: FontWeight.w600);
    }

    // Level pips (top-right).
    for (int i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(size.width - 16 - i * 9.0, 18),
        2.6,
        Paint()
          ..color = i < level
              ? const Color(0xFFAED581).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
      );
    }

    // Combo (bottom-right).
    if (combo > 1) {
      GameFx.text(canvas, 'x$combo', Offset(size.width - 30, size.height - 44),
          17, const Color(0xFFAED581),
          weight: FontWeight.w800, glow: 0.5);
    }
  }

  void _drawReady(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'Place crops so neighbours help',
      Offset(size.width / 2, size.height * 0.74),
      13,
      Colors.white.withValues(alpha: 0.5),
      weight: FontWeight.w600,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPainter old) => true;
}
