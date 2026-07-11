// StructureFormationGame — "claim the cosmic web".
//
// Rank-F rebuild (Brett, 2026-07-07, cyummu→yumutsu). The old version was an
// abstract density-sim you couldn't read. This one is a CONTEST over one shared
// young universe: you and rival civilizations plant OWNED seeds; every seed is a
// bright node in its owner's color that pulls filaments and grows a territory.
// You score the share of the web that collapses around YOUR seeds. Solo, the
// rivals are bots; online they are real players — same code, behind one seam
// (StructureSeedSource). See GAME.md.
//
// Self-contained module. Depends only on the framework session + shared FX/theme
// + the seed-source seam. PERFORMANCE: the whole field + FX render on ONE Ticker
// → ONE CustomPainter over flat typed arrays; only a throttled ~15fps setState
// refreshes the HUD text (never the field).
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

import 'structure_seed_source.dart';

// ---------------------------------------------------------------------------
// FEEL / TUNING — change these without touching logic.
// ---------------------------------------------------------------------------

/// Scale accent (cosmic violet — chrome only; territory is drawn per-owner).
const Color _sfAccent = Color(0xFF8E6BFF);

/// Claimant colors. Index 0 is always YOU (warm gold — the one "you" hue);
/// 1..3 are rivals in distinct, high-contrast hues.
const List<Color> kClaimantColors = [
  Color(0xFFFFC24B), // you — gold
  Color(0xFF3FD8E0), // rival — cyan
  Color(0xFFE85CC6), // rival — magenta
  Color(0xFF7BE06B), // rival — green
];

/// Density-field grid. Fixed so the simulation arrays never resize; mapped onto
/// whatever play area we get (portrait is locked, so a tall grid reads well).
const int _cols = 22;
const int _rows = 34;
const int _n = _cols * _rows;

/// Gravitational accretion strength (matter flow toward denser neighbours).
/// Tuned UP from the old build so a claimed node visibly grows in ~1–2s.
const double _gravity = 1.7;

/// Cosmic expansion: pulls every cell toward the mean (dilutes contrast). Gentle
/// early so structure actually forms, ramping over the run.
const double _expansionBase = 0.05;
const double _expansionRamp = 0.34;

/// Dark energy: a late surge (last part of the run) that tears weak/contested
/// structure apart. Kicks in at [_darkEnergyAt]s of the 45s round.
const double _darkEnergyAt = 33.0;
const double _darkEnergyBoost = 0.9;

/// A cell counts as "collapsed into structure" above mean × this ratio;
/// hysteresis un-collapses only below mean × [_uncollapseRatio].
const double _collapseRatio = 2.15;
const double _uncollapseRatio = 1.5;

/// Score = owned collapsed cells × this. Node bonus paid per new local node.
const int _massPerCell = 5;
const int _clusterMinSize = 5;
const int _clusterBonus = 30;

/// Seed economy — limited, slowly replenished, so placement matters.
const int _seedMax = 6;
const double _seedRegenSeconds = 2.0;
const int _seedStart = 6;

/// One seed deposits a Gaussian over-density: peak (high enough that the centre
/// collapses INSTANTLY — the tap is a node NOW), spread, and radius touched.
const double _seedPeak = 2.1;
const double _seedSigma = 1.15;
const int _seedRadius = 2;

/// Below this relative contrast a cell is "void" and isn't drawn.
const double _drawFloor = 0.18;

/// How often (s) to recompute ownership + score.
const double _scanEvery = 0.28;

// Educational payload — surfaced in the bottom banner, refreshed as nodes form.
const List<String> _sfFacts = [
  'Galaxy clusters sit at the knots where cosmic filaments cross.',
  'The cosmic web grew from ripples ~1 part in 100,000 — imprinted on the CMB.',
  'Gravity makes the rich richer: over-dense regions pull in ever more matter.',
  'Matter collapses along sheets and filaments, leaving vast near-empty voids.',
  'Dark energy now accelerates expansion, pulling the largest structures apart.',
  'The same instability that clumps galaxies once clumped the first stars.',
];

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER — atmosphere, the owner-tinted field, seed filaments, and FX in ONE
// pass. Repaints every tick off the game's ticker (no widget rebuild).
// ═══════════════════════════════════════════════════════════════════════════
class _StructurePainter extends CustomPainter {
  final Float32List d;
  final Uint8List collapsed;
  final Uint8List owner; // 0 = unowned, else claimant+1
  final double mean;
  final double t;
  final double fieldAlpha;
  final int claimantCount;
  final List<_Seed> seeds;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _StructurePainter({
    required this.d,
    required this.collapsed,
    required this.owner,
    required this.mean,
    required this.t,
    required this.fieldAlpha,
    required this.claimantCount,
    required this.seeds,
    required this.fx,
    required this.pops,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    GameFx.atmosphere(canvas, size, _sfAccent, t, motes: 40);

    final double cw = size.width / _cols;
    final double ch = size.height / _rows;
    final double ow = cw + 0.7;
    final double oh = ch + 0.7;
    final double safeMean = mean.isFinite && mean > 1e-4 ? mean : 1.0;

    // Filaments FIRST (under the nodes): thin threads between each claimant's
    // own nearby seeds — the literal "web" the player is weaving.
    _paintFilaments(canvas, cw, ch);

    final Paint cell = Paint();
    final Paint core = Paint();
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final int i = r * _cols + c;
        final double dv = d[i];
        if (!dv.isFinite) continue;
        final double rel = dv / safeMean - 1.0;
        if (rel < _drawFloor) continue;
        final double x = c * cw;
        final double y = r * ch;
        final int o = owner[i];
        final bool claimed = collapsed[i] != 0 && o != 0;
        // Claimed structure is drawn in its OWNER'S color (the board is a map of
        // who owns what); unclaimed forming structure is faint neutral violet.
        final Color base = claimed
            ? kClaimantColors[(o - 1) % kClaimantColors.length]
            : const Color(0xFF5B4B8A);
        final double a =
            (0.18 + 0.82 * (rel / 1.6)).clamp(0.0, 1.0) * fieldAlpha;
        cell.color = base.withValues(alpha: a);
        canvas.drawRect(Rect.fromLTWH(x - 0.35, y - 0.35, ow, oh), cell);
        // A claimed core gets a bright inner pip in a lightened owner tint —
        // brightness alone signals a node (no per-cell blur: that stalls the web
        // rasterizer frame-to-frame → the black-screen class of bug).
        if (claimed) {
          core.color = Color.lerp(base, Colors.white, 0.55)!
              .withValues(alpha: 0.7 * fieldAlpha);
          final double inset = cw * 0.30;
          canvas.drawRect(
            Rect.fromLTWH(x + inset, y + inset, cw - 2 * inset + 0.5,
                ch - 2 * inset + 0.5),
            core,
          );
        }
      }
    }

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  /// Thin threads between each claimant's own seeds that sit close together —
  /// the filaments of that owner's web, in the owner's color.
  void _paintFilaments(Canvas canvas, double cw, double ch) {
    if (seeds.length < 2) return;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // Link seeds of the same owner within this many cells (keeps the web local,
    // not a spider across the whole board). O(seeds²) but seeds are few.
    const double maxCell = 8.0;
    const double maxSq = maxCell * maxCell;
    for (int a = 0; a < seeds.length; a++) {
      final sa = seeds[a];
      for (int b = a + 1; b < seeds.length; b++) {
        final sb = seeds[b];
        if (sa.owner != sb.owner) continue;
        final double dc = (sa.col - sb.col).toDouble();
        final double dr = (sa.row - sb.row).toDouble();
        final double dsq = dc * dc + dr * dr;
        if (dsq > maxSq) continue;
        final double fade = (1.0 - dsq / maxSq).clamp(0.0, 1.0);
        line.color = kClaimantColors[(sa.owner - 1) % kClaimantColors.length]
            .withValues(alpha: 0.16 + 0.24 * fade);
        canvas.drawLine(
          Offset((sa.col + 0.5) * cw, (sa.row + 0.5) * ch),
          Offset((sb.col + 0.5) * cw, (sb.row + 0.5) * ch),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StructurePainter oldDelegate) => true;
}

/// One planted seed: grid cell + owner (claimant+1). Drives Voronoi ownership
/// and the filament web.
class _Seed {
  final int col;
  final int row;
  final int owner; // claimant index + 1 (1 = you)
  const _Seed(this.col, this.row, this.owner);
}

// ---------------------------------------------------------------------------
// GAME
// ---------------------------------------------------------------------------
class StructureFormationGame extends StatefulWidget {
  final MiniGameSession session;

  /// Rival source. Null ⇒ solo (an [AiSeedSource] is created). Online passes a
  /// networked source so real players' seeds stream into the same universe.
  final StructureSeedSource? source;

  const StructureFormationGame({super.key, required this.session, this.source});

  @override
  State<StructureFormationGame> createState() => _StructureFormationGameState();
}

class _StructureFormationGameState extends State<StructureFormationGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Random _rng = Random();
  late StructureSeedSource _source;

  // ── Density field (flat typed arrays — mutated every frame, no setState) ──
  final Float32List _d = Float32List(_n);
  final Float32List _delta = Float32List(_n);
  final Uint8List _collapsed = Uint8List(_n);
  final Uint8List _owner = Uint8List(_n); // 0 = unowned, else claimant+1
  double _totalMass = 0;

  // Seeds (for Voronoi ownership + filament drawing).
  final List<_Seed> _seeds = [];

  // ── Clock ──
  double _lastTime = 0;
  double _elapsed = 0;

  // ── Seed economy (local player only) ──
  double _seeds_ = _seedStart.toDouble();
  double _seedRegen = 0;

  // ── Ownership / scoring ──
  double _scanTimer = 0;
  int _localScored = 0; // owned-cell count already converted to score
  int _localNodes = 0; // highest local node count reached (bonus high-water)
  List<int> _ownedCounts = List<int>.filled(kClaimantColors.length, 0);
  final Uint8List _visited = Uint8List(_n);
  final Int32List _stack = Int32List(_n);

  // ── Visual feedback ──
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // ── Education ──
  int _factIndex = 0;
  String _currentFact = _sfFacts[0];

  bool _darkEnergy = false;

  /// Number of seeds the LOCAL player has planted this round. Drives the fading
  /// in-context how-to hint: it shows until the player taps, then fades out.
  int _localSeedsPlanted = 0;

  // ── Cached geometry (for the out-of-build tap hit-test) ──
  double _cellW = 0, _cellH = 0;
  bool _geomReady = false;

  double _uiAccum = 0;

  int get _claimantCount => _source.claimantCount;

  @override
  void initState() {
    super.initState();
    _source = widget.source ??
        AiSeedSource(cols: _cols, rows: _rows, seed: _rng.nextInt(1 << 30));
    _initField();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_update);
    _ticker.forward();
    // ATTRACT autopilot — this game plays itself the right way (spread seeds).
    widget.session.autoPilot = _autoStep;
  }

  /// Seed the nearly-smooth young universe: mean 1.0 with faint ripples (~±4%).
  void _initField() {
    _totalMass = 0;
    for (int i = 0; i < _n; i++) {
      final v = 1.0 + (_rng.nextDouble() - 0.5) * 0.08;
      _d[i] = v;
      _totalMass += v;
      _collapsed[i] = 0;
      _owner[i] = 0;
    }
    _seeds.clear();
  }

  double get _mean => _totalMass / _n;

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _source.dispose();
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot — one spread seed per host tick while running ────────
  void _autoStep() {
    if (!widget.session.isRunning || !_geomReady || _seeds_ < 1) return;
    // Drop the local seed on the cell whose nearest existing local seed is
    // farthest — a maximin spread that stakes wide territory.
    int bestCol = _cols ~/ 2, bestRow = _rows ~/ 2;
    double best = -1;
    final mine = [for (final s in _seeds) if (s.owner == 1) s];
    if (mine.isEmpty) {
      _placeLocalSeed(bestCol, bestRow);
      return;
    }
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        double nearest = double.infinity;
        for (final s in mine) {
          final double dd =
              ((s.row - r) * (s.row - r) + (s.col - c) * (s.col - c)).toDouble();
          if (dd < nearest) nearest = dd;
        }
        if (nearest > best) {
          best = nearest;
          bestCol = c;
          bestRow = r;
        }
      }
    }
    _placeLocalSeed(bestCol, bestRow);
  }

  // ── Simulation step ────────────────────────────────────────────────────────
  void _update() {
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final tsec = now / 1e6;
    final dt = (_lastTime == 0 ? 0.016 : (tsec - _lastTime)).clamp(0.0, 0.05);
    _lastTime = tsec;

    _stepFx(dt);

    if (!widget.session.isRunning) {
      _maybeRebuildHud(dt);
      return;
    }

    _elapsed += dt;

    // Local seed regen.
    if (_seeds_ < _seedMax) {
      _seedRegen += dt;
      if (_seedRegen >= _seedRegenSeconds) {
        _seedRegen -= _seedRegenSeconds;
        _seeds_ = (_seeds_ + 1).clamp(0.0, _seedMax.toDouble());
      }
    }

    // Rival seeds (bots or real players) arriving this frame.
    if (_source is AiSeedSource) {
      (_source as AiSeedSource).reportOwnership(_ownedCounts);
    }
    final rivals = _source.takeRivalSeeds(_elapsed, _ownedCounts[0]);
    for (final rs in rivals) {
      // Clamp owner into range and skip the local slot (rivals never seed as us).
      if (rs.owner <= 0 || rs.owner >= _claimantCount) continue;
      _seedAt(rs.col, rs.row, rs.owner + 1, burst: true);
    }

    _stepPhysics(dt);

    _scanTimer += dt;
    if (_scanTimer >= _scanEvery) {
      _scanTimer = 0;
      _recomputeOwnershipAndScore();
    }

    final wasDark = _darkEnergy;
    _darkEnergy = _elapsed >= _darkEnergyAt;
    if (_darkEnergy && !wasDark) _nextFact();

    _maybeRebuildHud(dt);
  }

  /// Gravity (accretion toward denser neighbours, mass-conserving) + expansion
  /// (dilution toward the mean), over the whole field.
  void _stepPhysics(double dt) {
    final mean = _mean;
    final frac = (_elapsed / 45.0).clamp(0.0, 1.0);
    double expansion = _expansionBase + _expansionRamp * frac;
    if (_darkEnergy) expansion += _darkEnergyBoost;

    for (int i = 0; i < _n; i++) {
      _delta[i] = 0;
    }
    for (int r = 0; r < _rows; r++) {
      final int rowBase = r * _cols;
      for (int c = 0; c < _cols; c++) {
        final int i = rowBase + c;
        final double di = _d[i];
        if (c + 1 < _cols) _flux(i, i + 1, di, _d[i + 1], dt);
        if (r + 1 < _rows) _flux(i, i + _cols, di, _d[i + _cols], dt);
      }
    }
    for (int i = 0; i < _n; i++) {
      double v = _d[i] + _delta[i];
      v += expansion * dt * (mean - v);
      _d[i] = v < 0 ? 0 : v;
    }
  }

  void _flux(int a, int b, double da, double db, double dt) {
    final double diff = db - da; // >0 ⇒ b heavier ⇒ mass flows a→b
    final double avg = (da + db) * 0.5;
    double f = _gravity * dt * diff * avg;
    final double donor = f > 0 ? da : db;
    final double maxMove = 0.25 * donor;
    if (f > maxMove) f = maxMove;
    if (f < -maxMove) f = -maxMove;
    _delta[a] -= f;
    _delta[b] += f;
  }

  /// Recompute which cells are collapsed, assign each to its nearest seed's
  /// owner (Voronoi territory), tally per-claimant owned mass, then score the
  /// local player's growth + any new local web node.
  void _recomputeOwnershipAndScore() {
    final double up = _mean * _collapseRatio;
    final double down = _mean * _uncollapseRatio;
    final counts = List<int>.filled(kClaimantColors.length, 0);
    // Accumulate the local player's owned-cell centroid so a +N score pop can
    // float up right where YOUR territory is growing (the "why am I scoring").
    double localSumX = 0, localSumY = 0;

    for (int i = 0; i < _n; i++) {
      // Hysteresis collapse flag.
      if (_collapsed[i] == 0) {
        if (_d[i] >= up) _collapsed[i] = 1;
      } else {
        if (_d[i] < down) _collapsed[i] = 0;
      }
      if (_collapsed[i] == 0) {
        _owner[i] = 0;
        continue;
      }
      // Nearest seed → owner.
      final int r = i ~/ _cols;
      final int c = i - r * _cols;
      int bestOwner = 0;
      double bestDist = double.infinity;
      for (final s in _seeds) {
        final double dc = (s.col - c).toDouble();
        final double dr = (s.row - r).toDouble();
        final double dd = dc * dc + dr * dr;
        if (dd < bestDist) {
          bestDist = dd;
          bestOwner = s.owner;
        }
      }
      _owner[i] = bestOwner;
      if (bestOwner > 0 && bestOwner <= counts.length) {
        counts[bestOwner - 1]++;
        if (bestOwner == 1) {
          localSumX += c;
          localSumY += r;
        }
      }
    }
    _ownedCounts = counts;

    // Score the local player's owned-mass GROWTH (monotonic — a rival stealing
    // border cells shows in the live bar, but never claws back banked score).
    final int localOwned = counts[0];
    if (localOwned > _localScored) {
      final int gainedCells = localOwned - _localScored;
      final int points = gainedCells * _massPerCell;
      widget.session.addScore(points);
      _localScored = localOwned;
      // Float a "+N" at the centroid of YOUR territory so it's obvious the
      // score climbs because your web is spreading (score-driver feedback).
      if (localOwned > 0 && _geomReady) {
        final double cx = (localSumX / localOwned + 0.5) * _cellW;
        final double cy = (localSumY / localOwned + 0.5) * _cellH;
        _spawnScorePop(Offset(cx, cy), points);
      }
    }

    // New local web node → bonus + streak + a callout.
    final int nodes = _countLocalNodes();
    if (nodes > _localNodes) {
      final int gained = nodes - _localNodes;
      _localNodes = nodes;
      widget.session.addScore(gained * _clusterBonus);
      widget.session.noteStreak(nodes);
      _spawnWebPop(gained);
      _nextFact();
    }
  }

  /// Count connected blobs (≥ [_clusterMinSize]) of LOCAL-owned collapsed cells.
  int _countLocalNodes() {
    for (int i = 0; i < _n; i++) {
      _visited[i] = 0;
    }
    int nodeCount = 0;
    for (int start = 0; start < _n; start++) {
      if (_owner[start] != 1 || _visited[start] != 0) continue;
      int sp = 0;
      _stack[sp++] = start;
      _visited[start] = 1;
      int size = 0;
      while (sp > 0) {
        final int cur = _stack[--sp];
        size++;
        final int cr = cur ~/ _cols;
        final int cc = cur - cr * _cols;
        if (cc > 0) sp = _pushIf(cur - 1, sp);
        if (cc + 1 < _cols) sp = _pushIf(cur + 1, sp);
        if (cr > 0) sp = _pushIf(cur - _cols, sp);
        if (cr + 1 < _rows) sp = _pushIf(cur + _cols, sp);
      }
      if (size >= _clusterMinSize) nodeCount++;
    }
    return nodeCount;
  }

  int _pushIf(int idx, int sp) {
    if (_owner[idx] == 1 && _visited[idx] == 0) {
      _visited[idx] = 1;
      _stack[sp++] = idx;
    }
    return sp;
  }

  // ── FX ─────────────────────────────────────────────────────────────────────
  void _stepFx(double dt) {
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
  }

  /// Float a "+N" at [at] (clamped inside the board) in YOUR color — the live
  /// score-driver: it reads that owning more web is what earns points.
  void _spawnScorePop(Offset at, int points) {
    final double w = _cellW * _cols;
    final double h = _cellH * _rows;
    final Offset p = Offset(
      at.dx.clamp(24.0, w - 24.0),
      at.dy.clamp(90.0, h - 60.0),
    );
    _pops.add(FxPop(p, '+$points', kClaimantColors[0]));
    if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
  }

  void _spawnWebPop(int gained) {
    final x = (_cellW * _cols) * (0.3 + _rng.nextDouble() * 0.4);
    final y = (_cellH * _rows) * 0.34;
    _pops.add(FxPop(Offset(x, y), gained > 1 ? 'WEB ×$gained' : 'WEB NODE',
        kClaimantColors[0]));
  }

  void _nextFact() {
    if (_sfFacts.length <= 1) return;
    int idx;
    do {
      idx = _rng.nextInt(_sfFacts.length);
    } while (idx == _factIndex);
    _factIndex = idx;
    _currentFact = _sfFacts[idx];
  }

  // ── Input: plant one of YOUR seeds ──────────────────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || !_geomReady) return;
    if (_seeds_ < 1) {
      _pops.add(FxPop(d.localPosition, 'NO SEEDS', const Color(0xFFB0A0C0)));
      if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
      return;
    }
    final pos = d.localPosition;
    final int col = (pos.dx / _cellW).floor().clamp(0, _cols - 1);
    final int row = (pos.dy / _cellH).floor().clamp(0, _rows - 1);
    _placeLocalSeed(col, row);
  }

  void _placeLocalSeed(int col, int row) {
    _seedAt(col, row, 1, burst: true); // owner 1 = you
    _seeds_ -= 1;
    _localSeedsPlanted++;
    _source.onLocalSeed(col, row); // broadcast to rivals (no-op solo)
  }

  /// Deposit a Gaussian over-density owned by [ownerPlus1] and register the seed
  /// for Voronoi ownership + filaments. The centre collapses INSTANTLY so the
  /// tap is a visible owned node immediately.
  void _seedAt(int col, int row, int ownerPlus1, {bool burst = false}) {
    _seeds.add(_Seed(col, row, ownerPlus1));
    const double twoSigSq = 2 * _seedSigma * _seedSigma;
    for (int dr = -_seedRadius; dr <= _seedRadius; dr++) {
      final int rr = row + dr;
      if (rr < 0 || rr >= _rows) continue;
      for (int dc = -_seedRadius; dc <= _seedRadius; dc++) {
        final int cc = col + dc;
        if (cc < 0 || cc >= _cols) continue;
        final double dist2 = (dr * dr + dc * dc).toDouble();
        final double add = _seedPeak * exp(-dist2 / twoSigSq);
        if (add < 0.01) continue;
        final int i = rr * _cols + cc;
        _d[i] += add;
        _totalMass += add;
        // Instant claim on the strong centre cells so the node reads NOW.
        if (_d[i] >= _mean * _collapseRatio) {
          _collapsed[i] = 1;
          _owner[i] = ownerPlus1;
        }
      }
    }
    if (burst && _geomReady) {
      final color = kClaimantColors[(ownerPlus1 - 1) % kClaimantColors.length];
      _fx.addAll(FxBurst.spawn(
          Offset((col + 0.5) * _cellW, (row + 0.5) * _cellH), color,
          count: 12, speed: 90, size: 2.6));
      if (_fx.length > 160) _fx.removeRange(0, _fx.length - 160);
    }
  }

  void _maybeRebuildHud(double dt) {
    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      if (mounted) setState(() {});
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _cellW = w / _cols;
      _cellH = h / _rows;
      _geomReady = _cellW > 0 && _cellH > 0;

      return Container(
        color: Potatuhs.inkDeep,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StructurePainter(
                    d: _d,
                    collapsed: _collapsed,
                    owner: _owner,
                    mean: _mean,
                    t: _elapsed,
                    fieldAlpha: running ? 1.0 : 0.5,
                    claimantCount: _claimantCount,
                    seeds: _seeds,
                    fx: _fx,
                    pops: _pops,
                    repaint: _ticker,
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: _onTapDown,
              ),
            ),

            // ── ALWAYS-VISIBLE OBJECTIVE (the one line: what am I doing?) ──
            const Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: IgnorePointer(child: _ObjectiveBanner()),
            ),

            // ── Live share bar: who owns how much of the web ──
            Positioned(
              top: 38,
              left: 12,
              right: 12,
              child: IgnorePointer(child: _shareBar()),
            ),

            // ── Seed budget ──
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: IgnorePointer(child: Center(child: _seedBar(_seeds_.floor()))),
            ),

            if (running && _darkEnergy)
              Positioned(
                top: 126,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _badge('⚡ DARK ENERGY — thin structure is tearing',
                        const Color(0xFFFF6B6B)),
                  ),
                ),
              ),

            // ── Fading in-context how-to: shows once play starts and the player
            //    hasn't planted yet; fades away the moment they act. ──
            if (running && _localSeedsPlanted < 2)
              Positioned(
                left: 24,
                right: 24,
                bottom: 74,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: _localSeedsPlanted == 0 ? 1.0 : 0.0,
                    child: _badge(
                        '👆 TAP anywhere to plant a seed — your territory grows in your colour',
                        kClaimantColors[0]),
                  ),
                ),
              ),

            if (!running)
              const Positioned.fill(child: IgnorePointer(child: _ReadyHint())),

            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _sfAccent.withValues(alpha: 0.45), width: 1),
                  ),
                  child: Text(
                    _currentFact,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(
                        size: 10.5,
                        height: 1.25,
                        color: const Color(0xFFD9CEF0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// The competitive readout: one filled segment per claimant, width ∝ owned
  /// web, YOU first and labelled. Always answers "am I winning?".
  Widget _shareBar() {
    final counts = _ownedCounts;
    int total = 0;
    for (int i = 0; i < _claimantCount && i < counts.length; i++) {
      total += counts[i];
    }
    final int youPct = total == 0 ? 0 : ((counts[0] / total) * 100).round();
    // Are you ahead? Compare your share to the strongest rival for a live verdict.
    int topRival = 0;
    for (int i = 1; i < _claimantCount && i < counts.length; i++) {
      if (counts[i] > topRival) topRival = counts[i];
    }
    final bool leading = counts[0] > topRival;
    final bool anyClaimed = total > 0;
    final Color verdictColor =
        !anyClaimed ? Potatuhs.textSecondary : (leading ? kClaimantColors[0] : const Color(0xFFFF8A8A));
    final String verdict =
        !anyClaimed ? 'CLAIM SOME WEB' : (leading ? 'LEADING' : 'BEHIND');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('YOUR WEB',
                  style: Potatuhs.label(size: 9, color: kClaimantColors[0])),
              const SizedBox(width: 8),
              Text(verdict,
                  style: Potatuhs.label(size: 8.5, color: verdictColor)),
              const Spacer(),
              Text('$youPct%',
                  style: Potatuhs.body(
                      size: 12,
                      weight: FontWeight.w800,
                      color: kClaimantColors[0])),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (int i = 0; i < _claimantCount && i < counts.length; i++)
                    Expanded(
                      flex: total == 0 ? 1 : (counts[i] * 1000 ~/ (total)) + 1,
                      child: Container(
                          color: kClaimantColors[i % kClaimantColors.length]
                              .withValues(alpha: i == 0 ? 1.0 : 0.75)),
                    ),
                  if (total == 0) const Expanded(flex: 20, child: SizedBox()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Legend: which colour is YOU vs each rival — makes the board readable.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < _claimantCount && i < counts.length; i++)
                _legendChip(
                    kClaimantColors[i % kClaimantColors.length],
                    i == 0 ? 'YOU' : 'RIVAL $i',
                    highlight: i == 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String label, {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: highlight
                ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 5)]
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Potatuhs.label(
                size: 8,
                color: highlight ? color : Potatuhs.textSecondary)),
      ],
    );
  }

  Widget _seedBar(int seeds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kClaimantColors[0].withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SEEDS',
              style: Potatuhs.label(size: 9, color: const Color(0xFFE9D9A8))),
          const SizedBox(width: 8),
          for (int i = 0; i < _seedMax; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < seeds ? kClaimantColors[0] : Colors.white12,
                boxShadow: i < seeds
                    ? [
                        BoxShadow(
                            color: kClaimantColors[0].withValues(alpha: 0.6),
                            blurRadius: 5)
                      ]
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(text,
          style:
              Potatuhs.body(size: 10.5, weight: FontWeight.w700, color: color)),
    );
  }
}

/// The always-on objective line. Const so it builds once and never churns the
/// tree during play (static label — never per-frame GameFx.text).
class _ObjectiveBanner extends StatelessWidget {
  const _ObjectiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kClaimantColors[0].withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub, size: 13, color: kClaimantColors[0]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'CLAIM THE COSMIC WEB — seed nodes, own the most mass',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Potatuhs.body(
                  size: 11, weight: FontWeight.w800, color: Potatuhs.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calm, non-interactive instruction shown before the round begins.
class _ReadyHint extends StatelessWidget {
  const _ReadyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub, size: 40, color: kClaimantColors[0].withValues(alpha: 0.9)),
          const SizedBox(height: 12),
          Text('CLAIM THE WEB',
              style: Potatuhs.display(size: 20, color: Potatuhs.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Tap to plant your seeds. Each is a node in YOUR color — gravity '
              'grows it into territory. Own the most cosmic web before the '
              'dark-energy surge. Rivals want it too.',
              textAlign: TextAlign.center,
              style: Potatuhs.body(
                  size: 12.5, color: Potatuhs.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VISUAL MANUAL — legend cards drawn with the game's OWN primitives (owned
// node, filament web, contested border, dark-energy tear). Static + cheap.
// ═══════════════════════════════════════════════════════════════════════════
final List<LegendFrame> structureFormationLegendFrames = [
  LegendFrame(
    caption: 'TAP to plant a seed — a bright node in YOUR color, instantly.',
    paint: (canvas, size) => _legendNode(canvas, size, kClaimantColors[0]),
  ),
  const LegendFrame(
    caption: 'Your seeds link into filaments — you are weaving your web.',
    paint: _legendFilament,
  ),
  const LegendFrame(
    caption: 'Rivals seed too. Nearest seed owns the cell — contest the border.',
    paint: _legendContested,
  ),
  const LegendFrame(
    caption: 'Own the most web before dark energy tears the thin structure.',
    paint: _legendDarkEnergy,
  ),
];

void _legendBg(Canvas canvas, Size size) {
  canvas.drawRect(Offset.zero & size,
      Paint()..color = const Color(0xFF0B0B14));
  GameFx.atmosphere(canvas, size, _sfAccent, 0.4, motes: 22);
}

void _legendNodeAt(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawCircle(c, r,
      Paint()..color = color.withValues(alpha: 0.30));
  canvas.drawCircle(c, r * 0.55,
      Paint()..color = color.withValues(alpha: 0.7));
  canvas.drawCircle(c, r * 0.28,
      Paint()..color = Color.lerp(color, Colors.white, 0.6)!);
}

void _legendNode(Canvas canvas, Size size, Color color) {
  _legendBg(canvas, size);
  _legendNodeAt(canvas, size.center(Offset.zero),
      size.shortestSide * 0.22, color);
}

void _legendFilament(Canvas canvas, Size size) {
  _legendBg(canvas, size);
  final color = kClaimantColors[0];
  final pts = [
    Offset(size.width * 0.28, size.height * 0.34),
    Offset(size.width * 0.6, size.height * 0.28),
    Offset(size.width * 0.72, size.height * 0.62),
    Offset(size.width * 0.4, size.height * 0.7),
  ];
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = color.withValues(alpha: 0.5);
  for (int i = 0; i < pts.length; i++) {
    for (int j = i + 1; j < pts.length; j++) {
      canvas.drawLine(pts[i], pts[j], line);
    }
  }
  for (final p in pts) {
    _legendNodeAt(canvas, p, size.shortestSide * 0.09, color);
  }
}

void _legendContested(Canvas canvas, Size size) {
  _legendBg(canvas, size);
  _legendNodeAt(canvas, Offset(size.width * 0.34, size.height * 0.5),
      size.shortestSide * 0.16, kClaimantColors[0]);
  _legendNodeAt(canvas, Offset(size.width * 0.66, size.height * 0.5),
      size.shortestSide * 0.16, kClaimantColors[1]);
  // The seam between the two territories.
  final seam = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.5);
  canvas.drawLine(Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8), seam);
}

void _legendDarkEnergy(Canvas canvas, Size size) {
  _legendBg(canvas, size);
  final c = size.center(Offset.zero);
  _legendNodeAt(canvas, c, size.shortestSide * 0.18, kClaimantColors[0]);
  // Tearing arrows pulling outward.
  final arrow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFF6B6B);
  for (int i = 0; i < 6; i++) {
    final a = i * pi / 3;
    final from = c + Offset(cos(a), sin(a)) * size.shortestSide * 0.24;
    final to = c + Offset(cos(a), sin(a)) * size.shortestSide * 0.42;
    canvas.drawLine(from, to, arrow);
  }
}
