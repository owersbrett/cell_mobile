import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/fx.dart';

// ============================================================================
// DEFEND THE CELL — memory + speed game
//
// Phase flow per round:
//   study  → memorize the correct arrangement (3 s, shrinking)
//   place  → drag pieces from memory before pathogen eats the rings
//   result → flash correct/wrong, then next round
//
// Pressure: pathogen ring creeps inward; each unfilled zone it consumes costs
// a life. Timer shrinks each round. Decoy pieces penalise wrong drops.
// Combo multiplier rewards perfect runs.
// ============================================================================

// ---------------------------------------------------------------------------
// Tissue definitions
// ---------------------------------------------------------------------------

enum _Tissue {
  // ---- Plant zones (original) ----
  pith,
  vascular,
  cortex,
  epidermis,
  // ---- Plant zones (new) ----
  periderm,       // Potato tuber outer skin
  tuberCortex,    // Potato tuber cortex
  vascularRing,   // Potato tuber vascular ring
  tuberPith,      // Potato tuber pith
  woodyXylem,     // Woody stem secondary xylem (core)
  woodyBark,      // Woody stem bark (outermost)
  woodyCambium,   // Woody stem cambium ring
  woodyPhloem,    // Woody stem phloem (inner bark)
  // ---- Animal zones ----
  skinEpidermis,  // Skin: outermost
  dermis,         // Skin: middle
  hypodermis,     // Skin: innermost (subcutaneous fat)
  mucosa,         // Gut: innermost lining
  submucosa,      // Gut: connective tissue layer
  muscularis,     // Gut: muscle layer
  serosa,         // Gut: outermost serous coat
  intima,         // Blood vessel: innermost (tunica interna)
  media,          // Blood vessel: middle (tunica media)
  adventitia,     // Blood vessel: outermost (tunica externa)
  // ---- Decoys (plant) ----
  phloem,
  xylem,
  cambium,
  parenchyma,
  // ---- Decoys (animal) ----
  endothelium,
  myelin,
  periosteum,
  epithelium,
}

class _TissueInfo {
  final double innerFrac;
  final double outerFrac;
  final Color color;
  final String label;
  final bool isReal; // real ring zone vs decoy
  const _TissueInfo(
      this.innerFrac, this.outerFrac, this.color, this.label, this.isReal);
}

// Real zones — all placeable ring zones across plant and animal organs.
// innerFrac/outerFrac define the visual band position (0=centre, 1=edge).
const _kRealZones = <_Tissue, _TissueInfo>{
  // ---- Original plant zones ----
  _Tissue.pith: _TissueInfo(
      0.00, 0.24, Color(0xFFA5D6A7), 'Pith', true),
  _Tissue.vascular: _TissueInfo(
      0.24, 0.50, Color(0xFFEF5350), 'Vascular', true),
  _Tissue.cortex: _TissueInfo(
      0.50, 0.78, Color(0xFF66BB6A), 'Cortex', true),
  _Tissue.epidermis: _TissueInfo(
      0.78, 1.00, Color(0xFF42A5F5), 'Epidermis', true),

  // ---- Potato tuber (4 zones) ----
  _Tissue.tuberPith: _TissueInfo(
      0.00, 0.25, Color(0xFFFFF176), 'Pith', true),
  _Tissue.vascularRing: _TissueInfo(
      0.25, 0.52, Color(0xFFFF7043), 'Vasc. Ring', true),
  _Tissue.tuberCortex: _TissueInfo(
      0.52, 0.78, Color(0xFFA5D6A7), 'Cortex', true),
  _Tissue.periderm: _TissueInfo(
      0.78, 1.00, Color(0xFF8D6E63), 'Periderm', true),

  // ---- Woody stem (4 zones) ----
  _Tissue.woodyXylem: _TissueInfo(
      0.00, 0.30, Color(0xFFD7CCC8), 'Sec. Xylem', true),
  _Tissue.woodyCambium: _TissueInfo(
      0.30, 0.52, Color(0xFF26C6DA), 'Cambium', true),
  _Tissue.woodyPhloem: _TissueInfo(
      0.52, 0.75, Color(0xFFAED581), 'Phloem', true),
  _Tissue.woodyBark: _TissueInfo(
      0.75, 1.00, Color(0xFF8D6E63), 'Bark', true),

  // ---- Skin (3 zones) ----
  _Tissue.hypodermis: _TissueInfo(
      0.00, 0.30, Color(0xFFFFC107), 'Hypodermis', true),
  _Tissue.dermis: _TissueInfo(
      0.30, 0.68, Color(0xFFFF8A65), 'Dermis', true),
  _Tissue.skinEpidermis: _TissueInfo(
      0.68, 1.00, Color(0xFFFFCCBC), 'Epidermis', true),

  // ---- Gut wall (4 zones, lumen innermost) ----
  _Tissue.mucosa: _TissueInfo(
      0.00, 0.26, Color(0xFFCE93D8), 'Mucosa', true),
  _Tissue.submucosa: _TissueInfo(
      0.26, 0.52, Color(0xFF9FA8DA), 'Submucosa', true),
  _Tissue.muscularis: _TissueInfo(
      0.52, 0.78, Color(0xFFEF9A9A), 'Muscularis', true),
  _Tissue.serosa: _TissueInfo(
      0.78, 1.00, Color(0xFFFFF59D), 'Serosa', true),

  // ---- Blood vessel (3 zones, lumen innermost) ----
  _Tissue.intima: _TissueInfo(
      0.00, 0.28, Color(0xFFEF5350), 'Intima', true),
  _Tissue.media: _TissueInfo(
      0.28, 0.65, Color(0xFFFFB74D), 'Media', true),
  _Tissue.adventitia: _TissueInfo(
      0.65, 1.00, Color(0xFF80CBC4), 'Adventitia', true),
};

// Decoy chips — same visual style but wrong answer.
// Pool mixes plant + animal terms so players must know the actual system.
const _kDecoyColors = <_Tissue, Color>{
  // Plant decoys
  _Tissue.phloem: Color(0xFFFFB74D),
  _Tissue.xylem: Color(0xFFCE93D8),
  _Tissue.cambium: Color(0xFF80DEEA),
  _Tissue.parenchyma: Color(0xFFFF8A65),
  // Animal decoys
  _Tissue.endothelium: Color(0xFFEF9A9A),
  _Tissue.myelin: Color(0xFFF0F4C3),
  _Tissue.periosteum: Color(0xFFBCAAA4),
  _Tissue.epithelium: Color(0xFFB2DFDB),
};

const _kDecoyLabels = <_Tissue, String>{
  _Tissue.phloem: 'Phloem',
  _Tissue.xylem: 'Xylem',
  _Tissue.cambium: 'Cambium',
  _Tissue.parenchyma: 'Parenchyma',
  _Tissue.endothelium: 'Endothelium',
  _Tissue.myelin: 'Myelin',
  _Tissue.periosteum: 'Periosteum',
  _Tissue.epithelium: 'Epithelium',
};

// Full decoy pool split by kingdom — used to pick contextually mixed decoys.
const _kPlantDecoys = <_Tissue>[
  _Tissue.phloem,
  _Tissue.xylem,
  _Tissue.cambium,
  _Tissue.parenchyma,
];

const _kAnimalDecoys = <_Tissue>[
  _Tissue.endothelium,
  _Tissue.myelin,
  _Tissue.periosteum,
  _Tissue.epithelium,
];

// Combined pool for cross-kingdom confusion challenges.
const _kAllDecoys = <_Tissue>[
  _Tissue.phloem,
  _Tissue.xylem,
  _Tissue.cambium,
  _Tissue.parenchyma,
  _Tissue.endothelium,
  _Tissue.myelin,
  _Tissue.periosteum,
  _Tissue.epithelium,
];

// Per-organ arrangements: which zones appear and in which order the study
// phase reveals them. Not every organ uses all zones. Zones are sorted
// dynamically by outerFrac (outermost first) for rendering and pathogen logic.
enum _Kingdom { plant, animal }

class _OrganConfig {
  final String name;
  final List<_Tissue> zones; // real zones required for this organ
  final int baseDecoyCount;  // minimum decoys (escalation adds more)
  final _Kingdom kingdom;    // drives decoy pool selection
  const _OrganConfig(this.name, this.zones, this.baseDecoyCount, this.kingdom);
}

const _kOrgans = <_OrganConfig>[
  // ---- Original plant organs ----
  _OrganConfig('Stem', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
    _Tissue.pith,
  ], 2, _Kingdom.plant),
  _OrganConfig('Root', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
    _Tissue.pith,
  ], 2, _Kingdom.plant),
  _OrganConfig('Leaf (vein)', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
  ], 2, _Kingdom.plant),
  _OrganConfig('Young Stem', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.pith,
  ], 2, _Kingdom.plant),

  // ---- Potato tuber (hero plant slice) ----
  _OrganConfig('Potato Tuber', [
    _Tissue.periderm,
    _Tissue.tuberCortex,
    _Tissue.vascularRing,
    _Tissue.tuberPith,
  ], 2, _Kingdom.plant),

  // ---- Woody stem ----
  _OrganConfig('Woody Stem', [
    _Tissue.woodyBark,
    _Tissue.woodyPhloem,
    _Tissue.woodyCambium,
    _Tissue.woodyXylem,
  ], 2, _Kingdom.plant),

  // ---- Animal: Skin ----
  _OrganConfig('Skin', [
    _Tissue.skinEpidermis,
    _Tissue.dermis,
    _Tissue.hypodermis,
  ], 2, _Kingdom.animal),

  // ---- Animal: Gut wall ----
  _OrganConfig('Gut Wall', [
    _Tissue.serosa,
    _Tissue.muscularis,
    _Tissue.submucosa,
    _Tissue.mucosa,
  ], 2, _Kingdom.animal),

  // ---- Animal: Blood vessel ----
  _OrganConfig('Blood Vessel', [
    _Tissue.adventitia,
    _Tissue.media,
    _Tissue.intima,
  ], 2, _Kingdom.animal),
];

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

enum _Phase { studyCountdown, study, place, result, complete }

class _Chip {
  final _Tissue tissue;
  final bool isDecoy;
  double x, y;
  double homeX, homeY;
  _Chip(this.tissue, this.isDecoy, this.x, this.y)
      : homeX = x,
        homeY = y;
}

class _ZoneFill {
  final _Tissue zone;
  final bool correct;
  double age;
  _ZoneFill(this.zone, this.correct) : age = 0;
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup(this.x, this.y, this.text, this.color) : age = 0;
}

class _Dot {
  double x, y, vx, vy, life, size;
  Color color;
  _Dot({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 4,
  });
}

// Pathogen tendril — organic creeping line
class _Tendril {
  final double angle;
  double progress; // 0..1 fraction along the outerRadius
  double speed;
  _Tendril(this.angle, this.progress, this.speed);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class TissueLayerGame extends StatefulWidget {
  final MiniGameSession session;
  const TissueLayerGame({super.key, required this.session});
  @override
  State<TissueLayerGame> createState() => _TissueLayerGameState();
}

class _TissueLayerGameState extends State<TissueLayerGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  // Per-game random base, fixed for the lifetime of this playthrough so the run
  // is reproducible-within-itself but different every time the game mounts.
  // Each round derives its own seeded Random from this base + the round index,
  // so consecutive rounds never share a layout and no two playthroughs match.
  late final int _gameSeed;
  late Random _rng; // re-seeded per round from _gameSeed (see _startRound)

  // ---- game state ----------------------------------------------------------
  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _perfectStreak = 0; // consecutive flawless rounds → session.noteStreak
  int _sectionsCompleted = 0;
  int _roundIndex = 0; // index into _playOrder
  List<int> _playOrder = []; // shuffled+interleaved order into _kOrgans
  double _lastT = 0;
  double _clock = 0; // seconds clock for ambient fx drift

  // ---- per-round randomness ------------------------------------------------
  // A whole-cross-section rotation, randomized each round, so the spatial
  // anchor of textures/labels (and the pathogen entry point) shifts — the same
  // organ never looks identical twice.
  double _roundRotation = 0;
  // Order zones light up during the study phase. Randomized each round so the
  // memorization is a fresh sequence, not a fixed "all at once" reveal.
  List<_Tissue> _studyOrder = [];

  // ---- per-round state -----------------------------------------------------
  _Phase _phase = _Phase.studyCountdown;
  double _phaseTimer = 0;
  double _roundTimeLimit = 25.0; // shrinks each round
  double _roundTimeLeft = 25.0;
  double _studyDuration = 3.5;
  double _pathogenSpeedMul = 1.0; // pressure ramps up at higher tiers
  int _wrongPenalty = 4; // seconds lost per wrong drop, grows with difficulty
  bool _roundFlawless = true; // no wrong drops / consumed zones this round

  // Default-initialised (not `late`) so the painter can safely read it on the
  // first frame, before _initGame()/_startRound() runs. _startRound() reassigns
  // it for real each round.
  _OrganConfig _organ = _kOrgans.first;
  final Set<_Tissue> _filled = {};       // correctly placed zones
  final Map<_Tissue, bool> _dropped = {}; // zone → correct?
  final List<_ZoneFill> _fillAnims = [];
  double _resultAge = -1;

  final List<_Chip> _chips = [];
  int? _dragIndex;
  _Tissue? _hoveredZone;

  // ---- pathogen ------------------------------------------------------------
  // How far the pathogen ring has crept inward, as a fraction of radius.
  // 0 = just outside epidermis, 1 = reached pith center.
  double _pathogenFrac = 0.0;
  final List<_Tendril> _tendrils = [];
  double _pathogenConsumedAge = -1; // flash when zone is consumed

  // ---- particles / effects -------------------------------------------------
  final List<_Dot> _fx = [];
  final List<_Popup> _pops = [];
  double _wrongFlash = 0;
  double _completeGlow = -1;

  Size _sz = Size.zero;

  Offset get _center => Offset(_sz.width / 2, _sz.height * 0.37);
  double get _radius => min(_sz.width * 0.42, _sz.height * 0.29);

  // ---- lifecycle -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Fresh per-game seed each mount: every playthrough draws a different
    // organ order, rotations, study sequences and decoy sets.
    _gameSeed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    _rng = Random(_gameSeed);
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    // Host owns the lifecycle (countdown / timer / results). Spin the game up
    // immediately; the tick gates real progress on widget.session.isRunning.
    _initGame();
    _started = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- initialisation ------------------------------------------------------

  void _initGame() {
    _score = 0;
    _lives = 3;
    _combo = 0;
    _perfectStreak = 0;
    _sectionsCompleted = 0;
    _roundIndex = 0;
    _gameOver = false;
    _roundTimeLimit = 25.0;
    _pathogenFrac = 0.0;
    _fx.clear();
    _pops.clear();
    _wrongFlash = 0;
    _completeGlow = -1;
    _pathogenConsumedAge = -1;
    _buildPlayOrder();
    _startRound();
  }

  /// Shuffle the specimens and weave the (distinct) animal organs evenly through
  /// the (near-identical) plant cross-sections, so you never face the same kind
  /// of slice back-to-back — the variety the game was missing.
  void _buildPlayOrder() {
    final plant = <int>[];
    final animal = <int>[];
    for (int i = 0; i < _kOrgans.length; i++) {
      (_kOrgans[i].kingdom == _Kingdom.plant ? plant : animal).add(i);
    }
    plant.shuffle(_rng);
    animal.shuffle(_rng);
    final total = plant.length + animal.length;
    final order = <int>[];
    int pi = 0, ai = 0;
    for (int k = 0; k < total; k++) {
      // Drop an animal in at its proportional slot; fill with plants otherwise.
      final wantAnimal =
          ai < animal.length && (ai + 1) * total <= (k + 1) * animal.length;
      if (wantAnimal || pi >= plant.length) {
        order.add(animal[ai++]);
      } else {
        order.add(plant[pi++]);
      }
    }
    _playOrder = order;
  }

  void _startRound() {
    // Per-round Random derived from the game seed + round index. Deterministic
    // within this playthrough, but distinct for every round and every game.
    _rng = Random(_gameSeed ^ (_roundIndex * 0x9E3779B1));

    if (_playOrder.isEmpty) _buildPlayOrder();
    // Reshuffle for a fresh mix each time we loop through every specimen.
    final orderIdx = _roundIndex % _playOrder.length;
    if (orderIdx == 0 && _roundIndex > 0) _buildPlayOrder();
    _organ = _kOrgans[_playOrder[_roundIndex % _playOrder.length]];
    _filled.clear();
    _dropped.clear();
    _fillAnims.clear();
    _dragIndex = null;
    _hoveredZone = null;
    _resultAge = -1;
    _roundFlawless = true;

    // Fresh whole-section rotation every round → the texture/label anchor and
    // pathogen entry point shift, so even a repeated organ never looks the same.
    _roundRotation = _rng.nextDouble() * 2 * pi;

    // Randomized study reveal sequence — the zones light up one-by-one in a new
    // order each round, turning a static "memorize" into a fresh mini-sequence.
    _studyOrder = List<_Tissue>.from(_organ.zones)..shuffle(_rng);

    // ---- Difficulty tier -----------------------------------------------------
    // A single escalating level drives every pressure knob below, so the ramp
    // reads as one coherent climb. Gentle early, genuinely hard late.
    final lvl = _difficulty; // 0..N, grows with sections cleared

    // Pathogen starts at outer edge; grows inward during place phase
    _pathogenFrac = 0.0;
    _tendrils.clear();
    // More tendrils later = a denser, more menacing creep front.
    final tendrilCount = (16 + lvl * 2).clamp(16, 30);
    for (int i = 0; i < tendrilCount; i++) {
      final angle =
          _roundRotation + i / tendrilCount * 2 * pi + _rng.nextDouble() * 0.25;
      _tendrils
          .add(_Tendril(angle, 0.0, 0.012 + _rng.nextDouble() * 0.008));
    }

    // ---- Escalation ramp (tiered, capped) ------------------------------------
    // Round time: starts at 26 s, sheds ~2 s per tier, floor 9 s.
    _roundTimeLimit = (26.0 - lvl * 2.0).clamp(9.0, 26.0);
    _roundTimeLeft = _roundTimeLimit;

    // Study time: starts at 3.6 s, sheds 0.35 s per tier, floor 1.4 s.
    _studyDuration = (3.6 - lvl * 0.35).clamp(1.4, 3.6);

    // Pathogen pressure: creeps 0..100% faster relative to the round timer as
    // tiers climb, so late rounds bite well before the clock runs out.
    _pathogenSpeedMul = (1.0 + lvl * 0.12).clamp(1.0, 2.0);

    // Wrong-drop time penalty grows so sloppy guessing hurts more later.
    _wrongPenalty = (4 + lvl).clamp(4, 9);

    // Study phase starts immediately (no separate countdown for simplicity)
    _phase = _Phase.study;
    _phaseTimer = _studyDuration;

    _buildChips();
  }

  // Difficulty tier. Climbs one step roughly every two cleared sections, so the
  // ramp is felt but earned. Capped so the floors above stay reachable.
  int get _difficulty => (_sectionsCompleted ~/ 2).clamp(0, 8);

  void _buildChips() {
    _chips.clear();
    if (_sz == Size.zero) return;

    // Real chips matching the organ's required zones
    final realTissues = List<_Tissue>.from(_organ.zones)..shuffle(_rng);

    // ---- Escalating decoy count ----------------------------------------------
    // Starts at organ's baseDecoyCount; gains 1 extra per difficulty tier so
    // the tray fills with plausible wrong answers as the climb continues.
    // Capped so total chips ≤ 8 (avoids chip tray overflow on small screens).
    final extraDecoys = _difficulty;
    final maxExtra = (8 - realTissues.length - _organ.baseDecoyCount).clamp(0, 4);
    final decoyCount = (_organ.baseDecoyCount + extraDecoys).clamp(
        _organ.baseDecoyCount, _organ.baseDecoyCount + maxExtra);

    // Pick decoys: from tier 2 mix cross-kingdom decoys for harder
    // pattern-matching (plant terms among animal slices and vice-versa).
    final List<_Tissue> decoyPool;
    if (_difficulty >= 2) {
      decoyPool = List<_Tissue>.from(_kAllDecoys);
    } else {
      decoyPool = List<_Tissue>.from(
          _organ.kingdom == _Kingdom.animal ? _kAnimalDecoys : _kPlantDecoys);
    }
    decoyPool.shuffle(_rng);
    final decoys = decoyPool.take(decoyCount).toList();

    final all = [
      ...realTissues.map((t) => _Chip(t, false, 0, 0)),
      ...decoys.map((t) => _Chip(t, true, 0, 0)),
    ]..shuffle(_rng);

    final n = all.length;
    const chipSpacing = 86.0;
    const rowH = 44.0; // vertical distance between rows

    // How many chips fit in one row without overflowing (with side padding)
    final availableW = _sz.width - 16.0; // 8px padding each side
    final perRow = (availableW / chipSpacing).floor().clamp(1, n);

    // Number of rows needed
    final rows = (n / perRow).ceil();

    // Bottom row baseline; if two rows, the first row sits higher
    final baseY = _sz.height * 0.82;

    for (int i = 0; i < n; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;

      // How many chips are in this particular row?
      final chipsInRow = (row == rows - 1) ? n - row * perRow : perRow;

      // Centre the row horizontally
      final rowStartX = _sz.width / 2 - (chipsInRow - 1) * chipSpacing / 2;

      // Offset upward for earlier rows so that the last row is at baseY
      final y = baseY - (rows - 1 - row) * rowH;

      all[i].x = rowStartX + col * chipSpacing;
      all[i].y = y;
      all[i].homeX = all[i].x;
      all[i].homeY = all[i].y;
    }
    _chips.addAll(all);
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    // Host gates the run: only advance while in the playing phase.
    if (!widget.session.isRunning) return;

    setState(() {
      _clock += dt;
      // particles
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 180 * dt;
        p.life -= dt;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // popups
      for (final p in _pops) {
        p.age += dt;
        p.y -= 28 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.4);

      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 3).clamp(0, 1.0);
      if (_completeGlow >= 0) _completeGlow += dt;
      if (_pathogenConsumedAge >= 0) _pathogenConsumedAge += dt;

      for (final f in _fillAnims) {
        f.age += dt;
      }

      // phase logic
      switch (_phase) {
        case _Phase.study:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            _phase = _Phase.place;
            _roundTimeLeft = _roundTimeLimit;
          }
          break;

        case _Phase.place:
          _roundTimeLeft -= dt;

          // Pathogen advances during place phase. Base travel spans the round
          // time limit; the difficulty multiplier makes it bite sooner later.
          final pathogenSpeed = _pathogenSpeedMul / _roundTimeLimit;
          _pathogenFrac += pathogenSpeed * dt;
          _pathogenFrac = _pathogenFrac.clamp(0.0, 1.0);

          // Tendrils advance at slightly different speeds
          for (final t in _tendrils) {
            t.progress = _pathogenFrac + sin(t.angle * 3) * 0.04;
            t.progress = t.progress.clamp(0.0, 1.0);
          }

          // Check if pathogen has consumed an unfilled zone
          _checkPathogenConsumption();

          if (_roundTimeLeft <= 0) {
            _roundTimeLeft = 0;
            _pathogenFrac = 1.0;
            // Consume all remaining unfilled zones
            _consumeAllUnfilled();
            _endRound();
          }
          break;

        case _Phase.result:
          _resultAge += dt;
          if (_resultAge > 1.8) {
            if (_lives <= 0) {
              widget.session.endEarly();
            } else {
              _sectionsCompleted++;
              _roundIndex++;
              _startRound();
            }
          }
          break;

        case _Phase.complete:
          _completeGlow += dt;
          if (_completeGlow > 1.5) {
            _sectionsCompleted++;
            _roundIndex++;
            _startRound();
          }
          break;

        case _Phase.studyCountdown:
          break;
      }
    });
  }

  // ---- pathogen zone consumption -------------------------------------------

  // The pathogen's outer front in terms of zone outerFrac (epidermis is 1.0,
  // pith is 0.0). _pathogenFrac=0 means just touching the epidermis edge.
  double get _pathogenOuterEdge => 1.0 - _pathogenFrac;

  void _checkPathogenConsumption() {
    // Sort zones outermost → innermost (largest outerFrac first) so the
    // pathogen eats them in the correct biological order regardless of kingdom.
    final order = List<_Tissue>.from(_organ.zones)
      ..sort((a, b) => _kRealZones[b]!.outerFrac
          .compareTo(_kRealZones[a]!.outerFrac));
    for (final z in order) {
      if (_filled.contains(z)) continue;
      final info = _kRealZones[z]!;
      // Pathogen consumes a zone when its front passes the zone's inner edge
      if (_pathogenOuterEdge <= info.innerFrac) {
        _lives--;
        _filled.add(z); // mark as "consumed" (not correctly filled)
        _dropped[z] = false;
        _fillAnims.add(_ZoneFill(z, false));
        _pathogenConsumedAge = 0;
        _wrongFlash = 0.5;
        _roundFlawless = false;
        _pops.add(_Popup(
          _center.dx + (_rng.nextDouble() - 0.5) * _radius,
          _center.dy,
          '✗ ${info.label} consumed!',
          const Color(0xFFFF5252),
        ));
        _combo = 0;
        if (_lives <= 0) {
          _endRound();
          return;
        }
      }
    }
  }

  void _consumeAllUnfilled() {
    for (final z in _organ.zones) {
      if (!_filled.contains(z)) {
        _lives = (_lives - 1).clamp(0, 3);
        _filled.add(z);
        _dropped[z] = false;
        _fillAnims.add(_ZoneFill(z, false));
      }
    }
  }

  void _endRound() {
    _phase = _Phase.result;
    _resultAge = 0;
  }

  // ---- zone hit test -------------------------------------------------------

  _Tissue? _hitZone(Offset pos) {
    final dx = pos.dx - _center.dx;
    final dy = pos.dy - _center.dy;
    final frac = sqrt(dx * dx + dy * dy) / _radius;
    for (final z in _organ.zones) {
      final info = _kRealZones[z]!;
      if (frac >= info.innerFrac && frac <= info.outerFrac) return z;
    }
    return null;
  }

  // ---- input ---------------------------------------------------------------

  void _onPanStart(Offset pos) {
    if (_phase != _Phase.place) return;

    double best = double.infinity;
    int bestI = -1;
    for (int i = 0; i < _chips.length; i++) {
      final c = _chips[i];
      final d = sqrt(pow(pos.dx - c.x, 2) + pow(pos.dy - c.y, 2));
      if (d < 52 && d < best) {
        best = d;
        bestI = i;
      }
    }
    if (bestI >= 0) _dragIndex = bestI;
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex == null || _dragIndex! >= _chips.length) return;
    setState(() {
      _chips[_dragIndex!].x = pos.dx;
      _chips[_dragIndex!].y = pos.dy;
      _hoveredZone = _hitZone(pos);
    });
  }

  void _onPanEnd() {
    if (_dragIndex == null || _dragIndex! >= _chips.length) return;
    final chip = _chips[_dragIndex!];
    _hoveredZone = null;
    final zone = _hitZone(Offset(chip.x, chip.y));

    setState(() {
      if (zone != null && !_filled.contains(zone)) {
        if (!chip.isDecoy && chip.tissue == zone) {
          // ---- correct placement ----
          _placeCorrect(chip, zone);
        } else {
          // ---- wrong placement (decoy or wrong zone) ----
          _placeWrong(chip, zone);
        }
      } else {
        // Dropped outside or on filled zone — snap home
        _snapHome(chip);
      }
      _dragIndex = null;
    });
  }

  void _placeCorrect(_Chip chip, _Tissue zone) {
    _filled.add(zone);
    _dropped[zone] = true;
    _fillAnims.add(_ZoneFill(zone, true));
    _chips.remove(chip);

    _combo++;
    // Speed bonus: more time remaining = more points
    final speedBonus = (_roundTimeLeft / _roundTimeLimit * 20).round();
    final pts = 15 + _combo * 5 + speedBonus;
    _score += pts;
    widget.session.addScore(pts);

    final info = _kRealZones[zone]!;
    final midR = (info.innerFrac + info.outerFrac) / 2 * _radius;
    _burst(_center.dx + cos(0) * midR, _center.dy, info.color, 18);
    _pops.add(_Popup(chip.x, chip.y - 20, '+$pts', info.color));

    // Check if all required zones filled
    if (_organ.zones.every((z) => _filled.contains(z))) {
      _combo += 3; // bonus for completing
      // Completion bonus scales with the difficulty tier, so the hard rounds
      // pay out more — the ramp is genuinely worth pushing into.
      final bonus = 50 + _sectionsCompleted * 15 + _difficulty * 20;
      _score += bonus;
      widget.session.addScore(bonus);

      // Flawless round → grow the streak; a slip resets it. Streak feeds the
      // host's streak tracker and awards an escalating perfect bonus.
      if (_roundFlawless) {
        _perfectStreak++;
        widget.session.noteStreak(_perfectStreak);
        if (_perfectStreak >= 2) {
          final perfectBonus = _perfectStreak * 15;
          _score += perfectBonus;
          widget.session.addScore(perfectBonus);
          _pops.add(_Popup(_center.dx, _center.dy + 10,
              'PERFECT x$_perfectStreak  +$perfectBonus',
              const Color(0xFFFFD54F)));
        }
      } else {
        _perfectStreak = 0;
      }

      _pops.add(_Popup(_center.dx, _center.dy - 40,
          '${_organ.name}  +$bonus', Colors.white));
      _completeGlow = 0;
      _phase = _Phase.complete;
      _burstAll();
    }
  }

  void _placeWrong(_Chip chip, _Tissue zone) {
    _combo = 0;
    _roundFlawless = false;
    _lives = (_lives - 1).clamp(0, 3);
    _roundTimeLeft = (_roundTimeLeft - _wrongPenalty).clamp(0, _roundTimeLimit);
    _wrongFlash = 0.5;
    _pops.add(
        _Popup(chip.x, chip.y - 20, '-${_wrongPenalty}s  ✗', const Color(0xFFFF5252)));
    _snapHome(chip);
    if (_lives <= 0) {
      _consumeAllUnfilled();
      _endRound();
    }
  }

  void _snapHome(_Chip chip) {
    chip.x = chip.homeX;
    chip.y = chip.homeY;
  }

  void _burst(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 120;
      _fx.add(_Dot(
        x: x,
        y: y,
        vx: cos(a) * spd,
        vy: sin(a) * spd - 30,
        life: 0.4 + _rng.nextDouble() * 0.4,
        color: color,
        size: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _burstAll() {
    for (final z in _organ.zones) {
      final info = _kRealZones[z]!;
      final midR = (info.innerFrac + info.outerFrac) / 2 * _radius;
      _burst(_center.dx + cos(z.index * 1.2) * midR,
          _center.dy + sin(z.index * 1.2) * midR, info.color, 12);
    }
    _burst(_center.dx, _center.dy, Colors.white, 20);
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        final wasZero = _sz == Size.zero;
        _sz = newSz;
        // Chips couldn't be laid out before first layout (size was zero); build
        // them once the real size arrives, then keep them positioned on resize.
        if (_started && (_chips.isNotEmpty || wasZero)) _buildChips();
      }
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            painter: _GamePainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              studyDuration: _studyDuration,
              clock: _clock,
              roundRotation: _roundRotation,
              studyOrder: List.of(_studyOrder),
              difficulty: _difficulty,
              organ: _organ.name,
              organZones: _organ.zones,
              filled: Set.of(_filled),
              dropped: Map.of(_dropped),
              fillAnims: List.of(_fillAnims),
              chips: List.of(_chips),
              dragIndex: _dragIndex,
              hoveredZone: _hoveredZone,
              center: _center,
              radius: _radius,
              score: _score,
              lives: _lives,
              combo: _combo,
              sectionsCompleted: _sectionsCompleted,
              roundTimeLeft: _roundTimeLeft,
              roundTimeLimit: _roundTimeLimit,
              pathogenFrac: _pathogenFrac,
              tendrils: List.of(_tendrils),
              particles: List.of(_fx),
              popups: List.of(_pops),
              wrongFlash: _wrongFlash,
              completeGlow: _completeGlow,
              pathogenConsumedAge: _pathogenConsumedAge,
              resultAge: _resultAge,
              gameOver: _gameOver,
              started: _started,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GamePainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer;
  final double studyDuration;
  final double clock;
  final double roundRotation;
  final List<_Tissue> studyOrder;
  final int difficulty;
  final String organ;
  final List<_Tissue> organZones;
  final Set<_Tissue> filled;
  final Map<_Tissue, bool> dropped;
  final List<_ZoneFill> fillAnims;
  final List<_Chip> chips;
  final int? dragIndex;
  final _Tissue? hoveredZone;
  final Offset center;
  final double radius;
  final int score;
  final int lives;
  final int combo;
  final int sectionsCompleted;
  final double roundTimeLeft;
  final double roundTimeLimit;
  final double pathogenFrac;
  final List<_Tendril> tendrils;
  final List<_Dot> particles;
  final List<_Popup> popups;
  final double wrongFlash;
  final double completeGlow;
  final double pathogenConsumedAge;
  final double resultAge;
  final bool gameOver;
  final bool started;

  _GamePainter({
    required this.phase,
    required this.phaseTimer,
    required this.studyDuration,
    required this.clock,
    required this.roundRotation,
    required this.studyOrder,
    required this.difficulty,
    required this.organ,
    required this.organZones,
    required this.filled,
    required this.dropped,
    required this.fillAnims,
    required this.chips,
    required this.dragIndex,
    required this.hoveredZone,
    required this.center,
    required this.radius,
    required this.score,
    required this.lives,
    required this.combo,
    required this.sectionsCompleted,
    required this.roundTimeLeft,
    required this.roundTimeLimit,
    required this.pathogenFrac,
    required this.tendrils,
    required this.particles,
    required this.popups,
    required this.wrongFlash,
    required this.completeGlow,
    required this.pathogenConsumedAge,
    required this.resultAge,
    required this.gameOver,
    required this.started,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Atmospheric background (gradient + drifting motes + glow blooms) instead
    // of flat black — shared GameFx so the cell reads as living tissue.
    if (size.width > 0 && size.height > 0) {
      GameFx.atmosphere(canvas, size, const Color(0xFF2E7D5B), clock, motes: 28);
    } else {
      canvas.drawRect(
          Offset.zero & size, Paint()..color = const Color(0xFF070714));
    }

    if (wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 23, 68, wrongFlash * 0.18));
    }

    _drawPathogen(canvas);
    _drawCrossSection(canvas, size);
    _drawChips(canvas, size);
    _drawParticles(canvas);
    _drawPopups(canvas);
    _drawHud(canvas, size);

    if (phase == _Phase.study) _drawStudyOverlay(canvas, size);
    if (phase == _Phase.result) _drawResultOverlay(canvas, size);
    if (completeGlow >= 0 && phase == _Phase.complete) {
      _drawCompleteOverlay(canvas, size);
    }
  }

  // ---- pathogen ------------------------------------------------------------

  void _drawPathogen(Canvas canvas) {
    if (pathogenFrac <= 0) return;

    // The pathogen "front" in radius units: it starts at outermost edge and
    // pushes inward. pathogenFrac=0 → outermost, pathogenFrac=1 → center.
    final outerEdge = radius * 1.02;
    final innerFront = radius * (1.0 - pathogenFrac);

    // Sickly green-black fog fill from outer edge to inner front
    final gradient = ui.Gradient.radial(center, outerEdge, [
      const Color(0x00000000),
      const Color(0x00000000),
      Color.fromRGBO(30, 80, 10, 0.55),
      Color.fromRGBO(10, 40, 5, 0.75),
    ], [
      0.0,
      (innerFront / outerEdge).clamp(0.0, 1.0),
      ((innerFront + 12) / outerEdge).clamp(0.0, 1.0),
      1.0,
    ]);
    canvas.drawCircle(center, outerEdge, Paint()..shader = gradient);

    // Tendril spores — little dots radiating from the front
    for (final t in tendrils) {
      final fr = 1.0 - t.progress;
      final r = radius * fr;
      final dx = cos(t.angle) * r;
      final dy = sin(t.angle) * r;
      // tendril line
      final paint = Paint()
        ..color = Color.fromRGBO(60, 180, 20,
            (0.15 + t.progress * 0.35).clamp(0.0, 0.55))
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(center.dx + dx, center.dy + dy),
        Offset(center.dx + cos(t.angle) * outerEdge,
            center.dy + sin(t.angle) * outerEdge),
        paint,
      );
      // spore dot at front
      canvas.drawCircle(
        Offset(center.dx + dx, center.dy + dy),
        1.5 + t.progress * 2,
        Paint()
          ..color =
              Color.fromRGBO(80, 220, 30, (t.progress * 0.7).clamp(0, 0.7)),
      );
    }

    // Pulsing danger ring
    if (pathogenFrac < 0.95) {
      final pulse = sin(pathogenFrac * 40) * 0.5 + 0.5;
      canvas.drawCircle(
        center,
        innerFront,
        Paint()
          ..color = Color.fromRGBO(60, 220, 10, 0.18 + pulse * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + pulse,
      );
    }
  }

  // ---- cross-section -------------------------------------------------------

  void _drawCrossSection(Canvas canvas, Size size) {
    // Microscope field ring
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Draw zones outermost → innermost (sorted by outerFrac descending) so
    // inner rings are painted on top — works for any organ, plant or animal.
    final order = List<_Tissue>.from(organZones)
      ..sort((a, b) =>
          _kRealZones[b]!.outerFrac.compareTo(_kRealZones[a]!.outerFrac));

    for (final zone in order) {
      final info = _kRealZones[zone]!;
      final outerR = radius * info.outerFrac;
      final innerR = radius * info.innerFrac;
      final isFilled = filled.contains(zone);
      final wasCorrect = dropped[zone] ?? true;
      final isHovered = hoveredZone == zone && !isFilled;

      if (isFilled) {
        _drawFilledZone(canvas, zone, info, innerR, outerR, wasCorrect);
      } else if (phase == _Phase.study) {
        _drawStudyZone(canvas, zone, info, innerR, outerR);
      } else {
        _drawEmptyZone(canvas, zone, info, innerR, outerR, isHovered);
      }
    }

    // Complete glow pulse
    if (completeGlow >= 0 && completeGlow < 1.5) {
      final a = sin(completeGlow / 1.5 * pi) * 0.3;
      canvas.drawCircle(
          center,
          radius * (1.0 + completeGlow * 0.06),
          Paint()..color = Colors.white.withValues(alpha: a));
    }

    // Organ label above
    if (started) {
      _paintText(canvas, organ, 12, Colors.white.withValues(alpha: 0.28),
          FontWeight.w400, center.dx, center.dy - radius - 26, true);
    }
  }

  void _drawStudyZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR) {
    // Sequential reveal: each zone lights up at its slot in the (randomized)
    // studyOrder, so the memorization is a fresh sequence every round rather
    // than a single static flash. The whole sequence completes with time to
    // spare before the place phase.
    final n = studyOrder.isEmpty ? 1 : studyOrder.length;
    final slot = studyOrder.indexOf(zone);
    final idx = slot < 0 ? 0 : slot;

    // Elapsed fraction of the study phase (0 at start → 1 at end).
    final elapsed = (1.0 - phaseTimer / studyDuration).clamp(0.0, 1.0);
    // Reveal window: spread the n zones across the first 75% of study time,
    // each fading in over a short, snappy window.
    final span = 0.75 / n;
    final startAt = idx * span;
    final fadeIn = ((elapsed - startAt) / (span * 0.9)).clamp(0.0, 1.0);
    if (fadeIn <= 0) {
      // Not yet revealed — show the dashed placeholder so its slot is visible.
      _drawDashedRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.10));
      return;
    }

    // A brief brightening pop right as the zone appears, easing to steady.
    final pop = (1.0 - ((elapsed - startAt) / (span * 1.4)).clamp(0.0, 1.0));
    final boost = 0.20 * pop;

    _fillRing(canvas, innerR, outerR,
        info.color.withValues(alpha: (0.55 + boost) * fadeIn));
    _strokeRing(
        canvas, innerR, outerR, info.color.withValues(alpha: (0.8 + boost) * fadeIn));
    _drawTextureDots(canvas, zone, info, innerR, outerR, fadeIn);

    // Label shown large during study
    final labelR = (innerR + outerR) / 2;
    _paintText(canvas, info.label, 12, info.color.withValues(alpha: 0.9 * fadeIn),
        FontWeight.w600, center.dx, center.dy - labelR - 6, true);
  }

  void _drawEmptyZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, bool isHovered) {
    // Just question mark rings
    final alpha = isHovered ? 0.4 : 0.12;
    _drawDashedRing(canvas, innerR, outerR, info.color.withValues(alpha: alpha));

    if (isHovered) {
      _fillRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.07));
    }

    final labelR = (innerR + outerR) / 2;
    _paintText(canvas, '?', isHovered ? 14 : 11,
        info.color.withValues(alpha: isHovered ? 0.55 : 0.20),
        FontWeight.w300, center.dx, center.dy - labelR - 6, true);
  }

  void _drawFilledZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, bool correct) {
    final anim = fillAnims.firstWhere((f) => f.zone == zone,
        orElse: () => _ZoneFill(zone, correct)..age = 10);
    final t = (anim.age / 0.4).clamp(0.0, 1.0);

    if (correct) {
      _fillRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.35 * t));
      _strokeRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.5 * t));
      _drawTextureDots(canvas, zone, info, innerR, outerR, t);
      final labelR = (innerR + outerR) / 2;
      _paintText(canvas, info.label, 10,
          info.color.withValues(alpha: 0.55 * t),
          FontWeight.w500, center.dx, center.dy - labelR - 6, true);
    } else {
      // Pathogen-consumed zone — sickly green tint
      final consumed = Color.lerp(info.color, const Color(0xFF33691E), 0.7)!;
      _fillRing(canvas, innerR, outerR, consumed.withValues(alpha: 0.30 * t));
      _strokeRing(canvas, innerR, outerR, consumed.withValues(alpha: 0.45 * t));
      final labelR = (innerR + outerR) / 2;
      _paintText(canvas, '✗', 14, consumed.withValues(alpha: 0.7 * t),
          FontWeight.bold, center.dx, center.dy - labelR - 6, true);
    }
  }

  // ---- chip tray -----------------------------------------------------------

  void _drawChips(Canvas canvas, Size size) {
    if (phase != _Phase.place && phase != _Phase.study) return;
    // During study show chips greyed out (can't interact)
    final studyMode = phase == _Phase.study;
    for (int i = 0; i < chips.length; i++) {
      final chip = chips[i];
      final isDragging = i == dragIndex;
      _drawOneChip(canvas, chip, isDragging, studyMode);
    }
  }

  void _drawOneChip(Canvas canvas, _Chip chip, bool isDragging, bool studyMode) {
    Color chipColor;
    String label;
    if (chip.isDecoy) {
      chipColor = _kDecoyColors[chip.tissue]!;
      label = _kDecoyLabels[chip.tissue]!;
    } else {
      chipColor = _kRealZones[chip.tissue]!.color;
      label = _kRealZones[chip.tissue]!.label;
    }

    final alpha = studyMode ? 0.25 : (isDragging ? 0.75 : 0.50);
    const chipW = 78.0;
    const chipH = 34.0;

    if (isDragging) {
      // glow halo
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(chip.x, chip.y),
                width: chipW + 16,
                height: chipH + 16),
            const Radius.circular(16)),
        Paint()..color = chipColor.withValues(alpha: 0.2),
      );
    }

    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(chip.x, chip.y), width: chipW, height: chipH),
        const Radius.circular(8));

    canvas.drawRRect(rect, Paint()..color = chipColor.withValues(alpha: alpha));
    canvas.drawRRect(
        rect,
        Paint()
          ..color = chipColor.withValues(alpha: alpha + 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    _paintText(canvas, label, 11,
        Colors.white.withValues(alpha: studyMode ? 0.3 : 0.88),
        FontWeight.w600, chip.x, chip.y, true);
  }

  // ---- particles / popups --------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final a = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.size * a,
          Paint()..color = p.color.withValues(alpha: a));
    }
  }

  void _drawPopups(Canvas canvas) {
    for (final p in popups) {
      final a = (1 - p.age / 1.4).clamp(0.0, 1.0);
      _paintText(canvas, p.text, 14 + p.age * 1.5,
          p.color.withValues(alpha: a), FontWeight.bold, p.x, p.y, true);
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Lives (top-left) — cell dots
    for (int i = 0; i < 3; i++) {
      final cx = 20.0 + i * 22.0;
      if (i < lives) {
        canvas.drawCircle(
            Offset(cx, 20), 6, Paint()..color = const Color(0xFF4CAF50));
      } else {
        canvas.drawCircle(
            Offset(cx, 20),
            6,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.14)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }

    // Sections (top-left below lives)
    if (sectionsCompleted > 0) {
      _paintText(canvas, '×$sectionsCompleted cells', 11,
          Colors.white.withValues(alpha: 0.22), FontWeight.w400, 20, 38, false);
    }

    // Difficulty tier pips (top-right) — fills up as the climb escalates so the
    // earned ramp is legible to the player.
    if (difficulty > 0) {
      for (int i = 0; i < 8; i++) {
        final cx = size.width - 16 - i * 9.0;
        final on = i < difficulty;
        canvas.drawCircle(
          Offset(cx, 18),
          2.6,
          Paint()
            ..color = on
                ? const Color(0xFFFF7043).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.10),
        );
      }
      _paintText(canvas, 'TIER $difficulty', 8,
          Colors.white.withValues(alpha: 0.28), FontWeight.w600,
          size.width - 36, 30, true);
    }

    // (Host draws the run timer + live score; the in-cell pathogen ring is the
    // game-specific round-pressure visual, kept below.)

    // Combo (bottom-right)
    if (combo > 1) {
      _paintText(canvas, 'x$combo', 17, const Color(0xFFFFB74D), FontWeight.bold,
          size.width - 28, size.height - 40, true);
    }

    // Phase label (bottom-left)
    final phaseLabel = phase == _Phase.study
        ? 'MEMORIZE'
        : phase == _Phase.place
            ? 'PLACE'
            : '';
    if (phaseLabel.isNotEmpty) {
      _paintText(canvas, phaseLabel, 9,
          Colors.white.withValues(alpha: 0.22), FontWeight.w500, 16, size.height - 38, false);
    }
  }

  // ---- overlays ------------------------------------------------------------

  void _drawStudyOverlay(Canvas canvas, Size size) {
    // Study bar at top showing how much time remains to memorize
    final frac = (phaseTimer / studyDuration).clamp(0.0, 1.0);
    const barH = 3.0;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, barH),
        Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * (1 - frac), barH),
        Paint()..color = const Color(0xFF80CBC4));

    // "MEMORIZE" label floats below the cross-section
    final y = center.dy + radius + 22;
    _paintText(canvas, 'MEMORIZE — then place from memory', 11,
        Colors.white.withValues(alpha: 0.45), FontWeight.w400,
        size.width / 2, y, true);

    // Countdown seconds
    _paintText(canvas, phaseTimer.ceil().toString(), 28,
        const Color(0xFF80CBC4).withValues(alpha: 0.7), FontWeight.w300,
        size.width / 2, y + 20, true);
  }

  void _drawResultOverlay(Canvas canvas, Size size) {
    // Brief flash showing what the correct answer was
    final a = (1 - resultAge / 1.8).clamp(0.0, 1.0) * 0.85;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: a * 0.5));

    final label = lives <= 0 ? 'SECTION LOST' : 'NEXT ROUND';
    _paintText(canvas, label, 22,
        (lives <= 0 ? const Color(0xFFFF5252) : const Color(0xFF80CBC4))
            .withValues(alpha: a),
        FontWeight.bold, size.width / 2, size.height / 2, true);
  }

  void _drawCompleteOverlay(Canvas canvas, Size size) {
    final a = (sin(completeGlow * 4) * 0.5 + 0.5) * 0.35;
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF4CAF50).withValues(alpha: a));
    _paintText(canvas, '${organ.toUpperCase()} DEFENDED', 20,
        Colors.white.withValues(alpha: (1 - completeGlow / 1.5).clamp(0, 1.0)),
        FontWeight.bold, size.width / 2, size.height / 2, true);
  }

  // ---- helpers -------------------------------------------------------------

  void _fillRing(Canvas canvas, double innerR, double outerR, Color color) {
    if (innerR > 0) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outerR))
        ..addOval(Rect.fromCircle(center: center, radius: innerR));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawCircle(center, outerR, Paint()..color = color);
    }
  }

  void _strokeRing(Canvas canvas, double innerR, double outerR, Color color) {
    canvas.drawCircle(center, outerR,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    if (innerR > 0) {
      canvas.drawCircle(center, innerR,
          Paint()
            ..color = color.withValues(alpha: color.a * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
    }
  }

  void _drawTextureDots(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, double alpha) {
    final midR = (innerR + outerR) / 2;
    final dotCount = zone == _Tissue.pith ? 6 : 12;
    final dotR = (outerR - innerR) * 0.07;
    for (int i = 0; i < dotCount; i++) {
      final a = (i / dotCount) * 2 * pi + zone.index * 1.5 + roundRotation;
      final r = midR + (outerR - innerR) * 0.22 * sin(i * 3.7);
      canvas.drawCircle(
        Offset(center.dx + cos(a) * r, center.dy + sin(a) * r),
        dotR,
        Paint()..color = info.color.withValues(alpha: 0.16 * alpha),
      );
    }
  }

  void _drawDashedRing(Canvas canvas, double innerR, double outerR, Color color) {
    _drawDashedCircle(canvas, outerR, color);
    if (innerR > 0) {
      _drawDashedCircle(canvas, innerR, color.withValues(alpha: color.a * 0.6));
    }
  }

  void _drawDashedCircle(Canvas canvas, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const segs = 32;
    const gap = 0.38;
    for (int i = 0; i < segs; i++) {
      final start = i / segs * 2 * pi;
      final sweep = (1 - gap) / segs * 2 * pi;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r), start, sweep, false, paint);
    }
  }

  void _paintText(Canvas canvas, String text, double fontSize, Color color,
      FontWeight weight, double x, double y, bool centred) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        centred
            ? Offset(x - tp.width / 2, y - tp.height / 2)
            : Offset(x, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
