// StructureFormationGame — "Structure Formation" cosmic-web cultivation blitz.
//
// Start from a nearly-smooth early universe: a faint density field, almost
// uniform, like the cosmic microwave background. TAP to SEED tiny over-densities
// (plant a fluctuation). GRAVITY then amplifies every over-density — matter
// flows toward the denser side, clumps merge, and ridges weave the filamentary
// cosmic web. Meanwhile cosmic EXPANSION dilutes contrast and, late in the run,
// DARK ENERGY surges and tries to stretch your structure apart. Seed wisely:
// spread fluctuations to build many nodes; over-seeding one spot or starving a
// region wastes it. Score = mass that collapses into structure + well-formed
// clusters (web nodes) before time runs out. 60-second blitz.
//
// Self-contained module. Depends only on the framework session + shared FX/theme.
// PERFORMANCE: the entire density field + particles render on ONE Ticker →
// ONE CustomPainter. The simulation mutates flat typed-array state every frame
// WITHOUT setState; only a throttled ~15fps setState refreshes the HUD text.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / TUNING CONSTANTS — change these without touching logic.
// ---------------------------------------------------------------------------

/// Scale accent (cosmic violet — the cosmic-web hue).
const Color _sfAccent = Color(0xFF8E6BFF);

/// Density-field grid. Fixed (independent of screen) so the simulation arrays
/// never resize; the field is mapped onto whatever play area we get. Portrait
/// is locked, so a tall grid reads naturally.
const int _cols = 22;
const int _rows = 38;
const int _n = _cols * _rows;

/// Gravitational accretion strength (matter flow toward denser neighbours).
const double _gravity = 1.0;

/// Cosmic expansion: pulls every cell toward the mean (dilutes contrast). Ramps
/// over the run; competes with gravity. Base + linear ramp by elapsed fraction.
const double _expansionBase = 0.11;
const double _expansionRamp = 0.55;

/// Dark energy: a late surge (last [_darkEnergyAt]s) that adds to expansion and
/// actively tears structure apart.
const double _darkEnergyAt = 46.0;
const double _darkEnergyBoost = 1.05;

/// A cell counts as "collapsed into structure" above mean × this ratio.
const double _collapseRatio = 2.4;
/// Hysteresis: a collapsed cell only un-collapses below mean × this (stops a
/// flickering cell from re-scoring repeatedly).
const double _uncollapseRatio = 1.6;

/// Points for one cell newly collapsing into structure (the mass score).
const int _massPoints = 6;
/// A connected blob of this many collapsed cells is a "well-formed cluster"
/// (a web node). Reaching a new high count of nodes pays this each.
const int _clusterMinSize = 5;
const int _clusterBonus = 40;

/// Seed economy. Limited fluctuations, slowly replenished — over-seeding burns
/// the budget, so placement matters.
const int _seedMax = 7;
const double _seedRegenSeconds = 2.2;
const int _seedStart = 7;

/// One seed deposits a small Gaussian over-density: peak amplitude + spread (in
/// cells) + the radius it touches.
const double _seedPeak = 2.3;
const double _seedSigma = 1.05;
const int _seedRadius = 2;

/// Below this relative contrast a cell is "void" and isn't drawn (keeps the
/// early universe near-smooth and the draw-call count low — only structure is
/// painted over the atmospheric background).
const double _drawFloor = 0.16;

/// How often (s) to flood-fill the collapsed cells for cluster scoring.
const double _clusterScanEvery = 0.35;

// Educational payload — surfaced in a fixed banner, refreshed as web nodes form.
const List<String> _sfFacts = [
  'The cosmic web grew from tiny density ripples — about 1 part in 100,000 — seen in the CMB.',
  'Gravity amplifies over-dense regions: the rich get richer over billions of years.',
  'Matter collapses along sheets and filaments, leaving vast near-empty voids.',
  'Galaxy clusters sit at the knots where cosmic filaments cross.',
  'The early universe was almost perfectly smooth — structure is its slow self-assembly.',
  'Expansion stretches space and fights gravity; only dense enough seeds collapse.',
  'Dark energy now accelerates expansion, pulling the largest structures apart.',
  'The same instability that clumps galaxies once clumped the first stars.',
];

// ---------------------------------------------------------------------------
// PAINTER — draws the atmosphere, the density field, and all FX in ONE pass.
// Repaints every tick off the game's ticker (no widget rebuild needed).
// ---------------------------------------------------------------------------
class _StructurePainter extends CustomPainter {
  final Float32List d;
  final Uint8List collapsed;
  final double mean;
  final double t; // seconds clock (drift / shimmer)
  final double fieldAlpha; // dims the field in the calm ready state
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _StructurePainter({
    required this.d,
    required this.collapsed,
    required this.mean,
    required this.t,
    required this.fieldAlpha,
    required this.fx,
    required this.pops,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Any non-finite metric must not reach the draw calls — a single NaN can
    // make the rasterizer drop the whole frame (black screen).
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    // Cosmic background: gradient + drifting star motes (the smooth backdrop the
    // web condenses out of).
    GameFx.atmosphere(canvas, size, _sfAccent, t, motes: 46);

    final double cw = size.width / _cols;
    final double ch = size.height / _rows;
    // Tiny overlap kills seams between neighbouring lit cells (filaments read as
    // continuous threads, not a tile grid).
    final double ow = cw + 0.7;
    final double oh = ch + 0.7;
    final double safeMean = mean.isFinite && mean > 1e-4 ? mean : 1.0;

    final Paint cell = Paint();
    final Paint hot = Paint();
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final int i = r * _cols + c;
        final double dv = d[i];
        if (!dv.isFinite) continue;
        final double rel = dv / safeMean - 1.0; // relative over-density
        if (rel < _drawFloor) continue;
        final double x = c * cw;
        final double y = r * ch;
        final double a =
            (0.22 + 0.78 * (rel / 1.5)).clamp(0.0, 1.0) * fieldAlpha;
        cell.color = _cosmicColor(rel).withValues(alpha: a);
        canvas.drawRect(Rect.fromLTWH(x - 0.35, y - 0.35, ow, oh), cell);
        // Collapsed cells get a hot white core overlay (no per-cell blur — that
        // is a per-frame web-rasterizer stall; brightness alone signals a node).
        if (collapsed[i] != 0) {
          hot.color = const Color(0xFFFFF6E0)
              .withValues(alpha: 0.5 * fieldAlpha);
          final double inset = cw * 0.28;
          canvas.drawRect(
            Rect.fromLTWH(x + inset, y + inset, cw - 2 * inset + 0.5,
                ch - 2 * inset + 0.5),
            hot,
          );
        }
      }
    }

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  /// Maps a relative over-density to the cosmic-web colour ramp:
  /// deep blue (sheets) → violet (filaments) → orange (collapsing) → white-hot
  /// (cluster cores).
  Color _cosmicColor(double rel) {
    const stops = <Color>[
      Color(0xFF1E3A8A), // deep blue — faint sheet
      Color(0xFF6D45C9), // violet — filament
      Color(0xFFC2410C), // deep orange — collapsing
      Color(0xFFF59E0B), // amber — dense
      Color(0xFFFFF1C9), // near white-hot — cluster core
    ];
    // Map rel ∈ [floor .. ~2.6] across the stops.
    final double f =
        ((rel - _drawFloor) / (2.6 - _drawFloor)).clamp(0.0, 1.0);
    final double scaled = f * (stops.length - 1);
    final int idx = scaled.floor().clamp(0, stops.length - 2);
    final double frac = (scaled - idx).clamp(0.0, 1.0);
    return Color.lerp(stops[idx], stops[idx + 1], frac)!;
  }

  @override
  bool shouldRepaint(_StructurePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// GAME
// ---------------------------------------------------------------------------
class StructureFormationGame extends StatefulWidget {
  final MiniGameSession session;
  const StructureFormationGame({super.key, required this.session});

  @override
  State<StructureFormationGame> createState() => _StructureFormationGameState();
}

class _StructureFormationGameState extends State<StructureFormationGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Random _rng = Random();

  // ── Density field (flat typed arrays — mutated every frame, no setState) ──
  final Float32List _d = Float32List(_n);
  final Float32List _delta = Float32List(_n);
  final Uint8List _collapsed = Uint8List(_n);
  double _totalMass = 0;

  // ── Clock ──
  double _lastTime = 0;
  double _elapsed = 0;

  // ── Seed economy ──
  double _seeds = _seedStart.toDouble();
  double _seedRegen = 0;

  // ── Cluster scoring ──
  int _maxClusters = 0; // highest count of web nodes reached this run
  double _clusterTimer = 0;
  final Uint8List _visited = Uint8List(_n);
  final Int32List _stack = Int32List(_n);

  // ── Visual feedback ──
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // ── Education ──
  int _factIndex = 0;
  String _currentFact = _sfFacts[0];

  // ── Late-game flag (dark energy) ──
  bool _darkEnergy = false;

  // ── Cached geometry (from build) for the out-of-build tap hit-test ──
  double _cellW = 0, _cellH = 0;
  bool _geomReady = false;

  // ── HUD rebuild throttle ──
  double _uiAccum = 0;

  @override
  void initState() {
    super.initState();
    _initField();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_update);
    _ticker.forward();
  }

  /// Seed the nearly-smooth early universe: mean density 1.0 with faint random
  /// fluctuations (~±4%), like the tiny ripples imprinted on the CMB.
  void _initField() {
    _totalMass = 0;
    for (int i = 0; i < _n; i++) {
      final v = 1.0 + (_rng.nextDouble() - 0.5) * 0.08;
      _d[i] = v;
      _totalMass += v;
      _collapsed[i] = 0;
    }
  }

  double get _mean => _totalMass / _n;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Simulation step ─────────────────────────────────────────────────────
  void _update() {
    // Always advance FX so the ready-state shimmer / lingering particles move,
    // but only advance the physics + clock while the host says we're playing.
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final tsec = now / 1e6;
    final dt = (_lastTime == 0 ? 0.016 : (tsec - _lastTime)).clamp(0.0, 0.05);
    _lastTime = tsec;

    _stepFx(dt);

    if (!widget.session.isRunning) {
      // Calm ready state — no growth, no seed regen, no scoring.
      _maybeRebuildHud(dt);
      return;
    }

    _elapsed += dt;

    // Seed regen (capped).
    if (_seeds < _seedMax) {
      _seedRegen += dt;
      if (_seedRegen >= _seedRegenSeconds) {
        _seedRegen -= _seedRegenSeconds;
        _seeds = (_seeds + 1).clamp(0.0, _seedMax.toDouble());
      }
    }

    _stepPhysics(dt);
    _scoreCollapse();

    _clusterTimer += dt;
    if (_clusterTimer >= _clusterScanEvery) {
      _clusterTimer = 0;
      _scoreClusters();
    }

    final wasDark = _darkEnergy;
    _darkEnergy = _elapsed >= _darkEnergyAt;
    if (_darkEnergy && !wasDark) {
      _nextFact();
    }

    _maybeRebuildHud(dt);
  }

  /// Gravity (accretion toward denser neighbours, mass-conserving) + cosmic
  /// expansion (dilution toward the mean) over the whole field.
  void _stepPhysics(double dt) {
    final mean = _mean;
    // Expansion rate ramps over the run; dark energy surges at the end.
    final frac = (_elapsed / 60.0).clamp(0.0, 1.0);
    double expansion = _expansionBase + _expansionRamp * frac;
    if (_darkEnergy) expansion += _darkEnergyBoost;

    // Clear the accumulation buffer.
    for (int i = 0; i < _n; i++) {
      _delta[i] = 0;
    }

    // Mass-conserving accretion: visit each right/down edge once and move mass
    // from the lighter cell into the heavier (gravity pulls matter into wells).
    for (int r = 0; r < _rows; r++) {
      final int rowBase = r * _cols;
      for (int c = 0; c < _cols; c++) {
        final int i = rowBase + c;
        final double di = _d[i];
        // Right neighbour.
        if (c + 1 < _cols) {
          _flux(i, i + 1, di, _d[i + 1], dt);
        }
        // Down neighbour.
        if (r + 1 < _rows) {
          _flux(i, i + _cols, di, _d[i + _cols], dt);
        }
      }
    }

    // Apply accretion, then expansion (pulls each cell toward the mean). Both
    // conserve total mass, so [_totalMass] only changes when the player seeds.
    for (int i = 0; i < _n; i++) {
      double v = _d[i] + _delta[i];
      v += expansion * dt * (mean - v);
      _d[i] = v < 0 ? 0 : v;
    }
  }

  /// Move mass between cells [a] and [b] along one edge, accumulating into
  /// [_delta]. Flows from the lighter cell into the heavier one (gravitational
  /// instability), at a rate scaled by local density, clamped so a donor can
  /// never lose more than a quarter of its mass in one step (stability).
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

  /// Rising-edge scoring: every cell that newly crosses the collapse threshold
  /// is mass that just fell into structure. Hysteresis prevents re-scoring a
  /// flickering cell.
  void _scoreCollapse() {
    final double up = _mean * _collapseRatio;
    final double down = _mean * _uncollapseRatio;
    int newlyCollapsed = 0;
    for (int i = 0; i < _n; i++) {
      if (_collapsed[i] == 0) {
        if (_d[i] >= up) {
          _collapsed[i] = 1;
          newlyCollapsed++;
        }
      } else {
        if (_d[i] < down) _collapsed[i] = 0;
      }
    }
    if (newlyCollapsed > 0) {
      widget.session.addScore(newlyCollapsed * _massPoints);
    }
  }

  /// Flood-fill the collapsed cells (4-connected) into clusters. A cluster of
  /// at least [_clusterMinSize] cells is a "well-formed" web node. Whenever the
  /// run reaches a NEW high count of nodes, award the bonus for each new node —
  /// rewarding a richer web, never double-paying when structure is torn and
  /// re-forms.
  void _scoreClusters() {
    for (int i = 0; i < _n; i++) {
      _visited[i] = 0;
    }
    int nodeCount = 0;
    for (int start = 0; start < _n; start++) {
      if (_collapsed[start] == 0 || _visited[start] != 0) continue;
      // Iterative flood fill over this connected component.
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

    if (nodeCount > _maxClusters) {
      final int gained = nodeCount - _maxClusters;
      _maxClusters = nodeCount;
      widget.session.addScore(gained * _clusterBonus);
      widget.session.noteStreak(nodeCount);
      _nextFact();
      _spawnWebPop(gained);
    }
  }

  /// Push neighbour [idx] onto the flood-fill stack if it's an unvisited
  /// collapsed cell; returns the new stack pointer.
  int _pushIf(int idx, int sp) {
    if (_collapsed[idx] != 0 && _visited[idx] == 0) {
      _visited[idx] = 1;
      _stack[sp++] = idx;
    }
    return sp;
  }

  // ── FX ───────────────────────────────────────────────────────────────────
  void _stepFx(double dt) {
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
  }

  void _spawnWebPop(int gained) {
    // A floating callout near the top-centre of the field.
    final x = (_cellW * _cols) * (0.3 + _rng.nextDouble() * 0.4);
    final y = (_cellH * _rows) * 0.32;
    _pops.add(FxPop(Offset(x, y), gained > 1 ? 'WEB ×$gained' : 'WEB NODE',
        const Color(0xFFFFE08A)));
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

  // ── Input: seed a density fluctuation ─────────────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || !_geomReady) return;
    if (_seeds < 1) {
      // Out of seeds — a tiny visual "denied" pulse so the tap isn't silent.
      _pops.add(FxPop(d.localPosition, 'NO SEEDS',
          const Color(0xFFB0A0C0)));
      if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
      return;
    }
    final pos = d.localPosition;
    final int col = (pos.dx / _cellW).floor().clamp(0, _cols - 1);
    final int row = (pos.dy / _cellH).floor().clamp(0, _rows - 1);
    _seedAt(col, row);
    _seeds -= 1;

    // Seed burst FX.
    _fx.addAll(FxBurst.spawn(pos, _sfAccent, count: 12, speed: 90, size: 2.6));
    if (_fx.length > 160) _fx.removeRange(0, _fx.length - 160);
  }

  /// Deposit a small Gaussian over-density centred on (col,row). Adds mass to
  /// the field (raising total mass — the only thing that does).
  void _seedAt(int col, int row) {
    final double twoSigSq = 2 * _seedSigma * _seedSigma;
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
      }
    }
  }

  void _maybeRebuildHud(double dt) {
    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      if (mounted) setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _cellW = w / _cols;
      _cellH = h / _rows;
      _geomReady = _cellW > 0 && _cellH > 0;

      final int seedsDisplay = _seeds.floor();

      return Container(
        color: Potatuhs.inkDeep,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Field + FX canvas — one painter, repaints off the ticker.
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StructurePainter(
                    d: _d,
                    collapsed: _collapsed,
                    mean: _mean,
                    t: _elapsed,
                    fieldAlpha: running ? 1.0 : 0.55,
                    fx: _fx,
                    pops: _pops,
                    repaint: _ticker,
                  ),
                ),
              ),
            ),

            // Full-area tap surface — seeds a fluctuation anywhere you tap.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: _onTapDown,
              ),
            ),

            // ── Seed budget (top-centre, clear of the host quit/disruption) ──
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(child: _seedBar(seedsDisplay)),
              ),
            ),

            // ── Dark-energy warning badge ──
            if (running && _darkEnergy)
              Positioned(
                top: 44,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _badge('⚡ DARK ENERGY — structure is pulling apart',
                        const Color(0xFFFF6B6B)),
                  ),
                ),
              ),

            // ── Calm ready-state hint (intro/countdown) ──
            if (!running)
              const Positioned.fill(
                child: IgnorePointer(child: _ReadyHint()),
              ),

            // ── Education banner (fixed, refreshes as nodes form) ──
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
                      color: const Color(0xFFD9CEF0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _seedBar(int seeds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sfAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SEEDS',
              style: Potatuhs.label(size: 9, color: const Color(0xFFB9A8E8))),
          const SizedBox(width: 8),
          for (int i = 0; i < _seedMax; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < seeds ? _sfAccent : Colors.white12,
                boxShadow: i < seeds
                    ? [BoxShadow(color: _sfAccent.withValues(alpha: 0.6), blurRadius: 5)]
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
      child: Text(
        text,
        style: Potatuhs.body(
            size: 10.5, weight: FontWeight.w700, color: color),
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
          Icon(Icons.grain, size: 40, color: _sfAccent.withValues(alpha: 0.85)),
          const SizedBox(height: 12),
          Text('STRUCTURE FORMATION',
              style: Potatuhs.display(size: 20, color: Potatuhs.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'A nearly-smooth universe. Tap to seed tiny density ripples — '
              'gravity will grow them into the cosmic web.',
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
