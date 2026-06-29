import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ════════════════════════════════════════════════════════════════════════════
// CELL TYPE v2 — UX-refined alternative to `cell_type` (BioScale.cell).
//
// Same lesson: classify a procedurally-drawn cell as PLANT / ANIMAL / BACTERIAL
// / FUNGAL by its real structural tells (rigid wall, green chloroplasts, central
// vacuole, true nucleus vs free nucleoid, relative size, flagellum). The
// procedural organelles still MAP to biology — that fidelity is preserved.
//
// What changed vs the original `CellTypeGame` (mapped to the teardown):
//
// • KILL THE 1.9s FLARE (teardown #2 — "the flare fights pace"). There is NO
//   post-answer gate. A tap CONFIRMS instantly and the NEXT specimen loads the
//   same frame; the reveal (flash, burst, a ~0.7s non-blocking toast naming the
//   deciding tell) animates over the incoming cell WITHOUT stopping the round.
//   The full fact is reserved for WRONG answers (teardown brief). So the round
//   ACCELERATES — throughput is bounded only by how fast you read.
//
// • A SECOND SKILL AXIS BEYOND RECALL (teardown #4 / rubric "skill depth"). Each
//   specimen "resolves under the microscope": it loads unfocused (silhouette +
//   size visible — a real tell — but fine organelles hazy) and sharpens over a
//   short window. A visible BONUS RING shrinks as it sharpens, and the live read
//   multiplier (×1.8 → ×1.0) ticks down with it. So the second axis is
//   CALIBRATED CONFIDENCE: snap-read the partial cell for big points (expert
//   pattern recognition, higher miss-risk) vs wait for full clarity for a safe
//   but smaller score. Recall AND nerve, two independent skills.
//
// • FAIR, NON-RUNAWAY SCORING (teardown #1 — the unbounded `_mult()` was a
//   runaway engine). The streak multiplier is CAPPED 1× → 3×. The big swing is
//   the skill-gated read bonus, which a TRAILING player can bank just as well —
//   so a lead is legible (~3× a confused player) and never uncatchable. Reads in
//   pass-and-play / party standings, not just solo.
//
// • SCAFFOLD THE READ + LEGIBLE RAMP (teardown #3). A persistent micro-LEGEND
//   maps each type to its deciding tell on-screen (the decision tree is no
//   longer manual-only); it's bold early and fades as you master the round — a
//   legible difficulty signal. The BONUS RING makes the scoring window visible
//   instead of the original's invisible shrinking decay.
//
// • CLIMAX (teardown #4). The last 8s is FINAL CELLS: specimens resolve faster
//   (shorter read windows), points ×2, an alarm vignette + banner. Ends on a
//   flourish, not a silent clock expiry.
//
// KEPT: the procedural organelle rendering, the tell-degradation by progress
// (subtle plants shed chloroplasts, bacteria rod→coccus, fungal≈plant), the
// per-type `_kFacts`, and the clean perf architecture: ONE Ticker → ONE
// CustomPainter under a RepaintBoundary, NO per-frame setState over a tree.
// ════════════════════════════════════════════════════════════════════════════

const String _kFont = Potatuhs.bodyFont;

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _kPlant = Color(0xFF4CAF50); // chlorophyll green
const Color _kAnimal = Color(0xFFE8567E); // membrane pink
const Color _kBacterial = Color(0xFF26C6DA); // prokaryote teal
const Color _kFungal = Color(0xFFE0A93B); // chitin amber
const Color _kGold = Color(0xFFE1C916); // streak / bonus gold
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kCardBg = Color(0xFF1B1A17);
const Color _kCardEdge = Color(0xFF34302A);

// ── Scoring / timing ─────────────────────────────────────────────────────────
const int _kBase = 60; // base points for a correct read
const double _kReadMax = 1.8; // read multiplier at focus 0 (snap)
const double _kReadMin = 1.0; // read multiplier at focus 1 (fully resolved)
const int _kStreakStep = 3; // every N correct = +1× multiplier
const int _kMultMax = 3; // CAP — the non-runaway guarantee
const double _kFocusStart = 1.5; // seconds to fully resolve, early round
const double _kFocusEnd = 0.9; // seconds to fully resolve, late round
const double _kSurgeAt = 8.0; // FINAL CELLS window (seconds remaining)
const double _kSurgeFocusMul = 0.7; // resolve faster in the surge
const double _kSurgeScoreMul = 2.0;

// ════════════════════════════════════════════════════════════════════════════
// Cell model
// ════════════════════════════════════════════════════════════════════════════

enum _CellType { plant, animal, bacterial, fungal }

extension _CellTypeMeta on _CellType {
  String get label => switch (this) {
        _CellType.plant => 'PLANT',
        _CellType.animal => 'ANIMAL',
        _CellType.bacterial => 'BACTERIAL',
        _CellType.fungal => 'FUNGAL',
      };
  Color get accent => switch (this) {
        _CellType.plant => _kPlant,
        _CellType.animal => _kAnimal,
        _CellType.bacterial => _kBacterial,
        _CellType.fungal => _kFungal,
      };
  IconData get icon => switch (this) {
        _CellType.plant => Icons.eco_rounded,
        _CellType.animal => Icons.cruelty_free_rounded,
        _CellType.bacterial => Icons.coronavirus_rounded,
        _CellType.fungal => Icons.spa_rounded,
      };

  /// The deciding tell, short — the on-screen decision tree (also the legend).
  String get tell => switch (this) {
        _CellType.plant => 'wall + green chloroplasts',
        _CellType.animal => 'no wall — bare membrane',
        _CellType.bacterial => 'tiny, no nucleus',
        _CellType.fungal => 'walled but no green',
      };
}

/// One procedurally specified cell. Feature flags are the tells; positions are
/// frozen at creation so organelles drift around a stable base, never jump.
class _Cell {
  final _CellType type;
  final double sizeFactor;
  final bool wall;
  final int chloroplasts;
  final bool bigVacuole;
  final bool nucleus;
  final Offset nucleusAt;
  final bool flagellum;
  final bool rod;
  final double wobbleSeed;
  final List<Offset> spots;
  final double clarity; // 1 = obvious tells, 0 = subtle (harder)

  const _Cell({
    required this.type,
    required this.sizeFactor,
    required this.wall,
    required this.chloroplasts,
    required this.bigVacuole,
    required this.nucleus,
    required this.nucleusAt,
    required this.flagellum,
    required this.rod,
    required this.wobbleSeed,
    required this.spots,
    required this.clarity,
  });
}

// ── Facts — the per-answer education (kept from the original) ─────────────────
const Map<_CellType, List<String>> _kFacts = {
  _CellType.plant: [
    'Plant cells have a rigid cellulose WALL, green CHLOROPLASTS for '
        'photosynthesis, and one large central VACUOLE.',
    'That big central vacuole stores water — turgor pressure inside it is what '
        'keeps a plant standing upright.',
    'Chloroplasts are the green organelles where sunlight is turned into sugar. '
        'Only plant (and algal) cells carry them.',
  ],
  _CellType.animal: [
    'Animal cells have NO wall — only a flexible membrane — so they settle into '
        'rounded, irregular blobs.',
    'No chloroplasts and no large vacuole: animals get energy by eating, not '
        'from light.',
    'The nucleus sits near the centre, ringed by mitochondria — the cell\'s '
        'power plants.',
  ],
  _CellType.bacterial: [
    'Bacteria are prokaryotes: tiny, and with NO nucleus — their DNA floats '
        'free as a tangled nucleoid.',
    'A bacterium is roughly 10x smaller than a typical plant or animal cell.',
    'Many bacteria swim with a whip-like flagellum, wrapped in a wall and a '
        'protective capsule.',
  ],
  _CellType.fungal: [
    'Fungal cells have a WALL (made of chitin, not cellulose) but NO '
        'chloroplasts — fungi never photosynthesise.',
    'A fungus is the in-between cell: walled like a plant, but a heterotroph '
        'that eats like an animal.',
    'Yeast is a single fungal cell — round, walled, with a real nucleus and a '
        'few small vacuoles.',
  ],
};

// ════════════════════════════════════════════════════════════════════════════
// Widget
// ════════════════════════════════════════════════════════════════════════════

class CellTypeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const CellTypeV2Game({super.key, required this.session});

  @override
  State<CellTypeV2Game> createState() => _CellTypeV2GameState();
}

/// Lightweight repaint pump — ticked every frame so the painter repaints
/// without rebuilding the widget tree (no per-frame setState over the buttons).
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _CellTypeV2GameState extends State<CellTypeV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _Repaint repaint = _Repaint();

  Duration _lastElapsed = Duration.zero;
  double clock = 0; // seconds, read by painter

  late _Cell cell;
  _CellType? _lastType;
  double focus = 0; // 0 = just loaded (hazy), 1 = fully resolved
  int _factIdx = 0;

  // Streak / scoring.
  int streak = 0;
  int shownMult = 1;

  // Feedback (all non-blocking, decay over time — none gate the clock).
  double flash = 0;
  Color flashColor = _kGood;
  double pressLife = 0;
  _CellType? lastTapped;
  bool lastCorrect = false;

  // Non-blocking toast.
  String toastText = '';
  String toastSub = '';
  Color toastColor = _kGood;
  double toastLife = 0;

  final List<FxParticle> particles = [];
  final List<FxPop> pops = [];

  Size _size = Size.zero;
  bool _wasRunning = false;
  bool surge = false;
  bool _endShown = false;

  @override
  void initState() {
    super.initState();
    cell = _generate(0);
    focus = 1; // ready-state specimen shows fully resolved
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  // ── Difficulty ───────────────────────────────────────────────────────────
  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  double get _focusTime {
    final base = _kFocusStart + (_kFocusEnd - _kFocusStart) * _progress;
    return surge ? base * _kSurgeFocusMul : base;
  }

  /// Read multiplier for the CURRENT focus — high (snap) when hazy, 1.0 crisp.
  double get _readMult => _kReadMax + (_kReadMin - _kReadMax) * focus;

  /// Legend opacity — bold early (scaffold), faint once you've mastered it.
  double get _legendAlpha => (1.0 - _progress * 0.8).clamp(0.2, 1.0);

  // ── Loop ─────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetForPlay();
    _wasRunning = running;

    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    surge = running && remain <= _kSurgeAt;

    if (running) {
      focus = (focus + dt / _focusTime).clamp(0.0, 1.0);
    } else if (widget.session.phase == MiniGamePhase.finished && !_endShown) {
      _endShown = true;
      _toast('TIME!', 'specimens read', _kGold, life: 1.4);
      flash = 1.0;
      flashColor = _kGold;
      particles.addAll(
          FxBurst.spawn(_stageCenter(_size), _kGold, count: 22, speed: 200));
    }

    if (flash > 0) flash = (flash - dt / 0.45).clamp(0.0, 1.0);
    if (pressLife > 0) pressLife = (pressLife - dt / 0.28).clamp(0.0, 1.0);
    if (toastLife > 0) toastLife = math.max(0.0, toastLife - dt);
    particles.removeWhere((p) => !p.step(dt));
    pops.removeWhere((p) => !p.step(dt));

    repaint.tick();
  }

  void _resetForPlay() {
    streak = 0;
    shownMult = 1;
    _endShown = false;
    toastLife = 0;
    pops.clear();
    particles.clear();
    cell = _generate(0);
    focus = 0;
  }

  // ── Cell generation (kept from the original — the biology is the lesson) ──
  _CellType _pickType() {
    _CellType t;
    do {
      t = _CellType.values[_rng.nextInt(_CellType.values.length)];
    } while (t == _lastType && _rng.nextDouble() < 0.7);
    _lastType = t;
    return t;
  }

  _Cell _generate(double progress) {
    final type = _pickType();
    final clarity = (1.0 - progress * 0.65).clamp(0.35, 1.0);
    final spots = <Offset>[];

    switch (type) {
      case _CellType.plant:
        final n = (2 + (clarity * 5)).round() + _rng.nextInt(2);
        for (var i = 0; i < n; i++) {
          spots.add(_ringSpot(0.30, 0.78));
        }
        return _Cell(
          type: type,
          sizeFactor: 0.92,
          wall: true,
          chloroplasts: n,
          bigVacuole: true,
          nucleus: true,
          nucleusAt: Offset(0.46 * (_rng.nextBool() ? 1 : -1),
              0.40 * (_rng.nextBool() ? 1 : -1)),
          flagellum: false,
          rod: false,
          wobbleSeed: _rng.nextDouble() * 6.28,
          spots: spots,
          clarity: clarity,
        );

      case _CellType.fungal:
        for (var i = 0; i < 5 + _rng.nextInt(3); i++) {
          spots.add(_ringSpot(0.20, 0.7));
        }
        return _Cell(
          type: type,
          sizeFactor: 0.80,
          wall: true,
          chloroplasts: 0,
          bigVacuole: false,
          nucleus: true,
          nucleusAt: Offset(0.34 * (_rng.nextBool() ? 1 : -1),
              0.30 * (_rng.nextBool() ? 1 : -1)),
          flagellum: false,
          rod: false,
          wobbleSeed: _rng.nextDouble() * 6.28,
          spots: spots,
          clarity: clarity,
        );

      case _CellType.animal:
        for (var i = 0; i < 4 + _rng.nextInt(3); i++) {
          spots.add(_ringSpot(0.22, 0.68));
        }
        return _Cell(
          type: type,
          sizeFactor: 0.84,
          wall: false,
          chloroplasts: 0,
          bigVacuole: false,
          nucleus: true,
          nucleusAt: Offset(0.16 * (_rng.nextDouble() * 2 - 1),
              0.12 * (_rng.nextDouble() * 2 - 1)),
          flagellum: false,
          rod: false,
          wobbleSeed: _rng.nextDouble() * 6.28,
          spots: spots,
          clarity: clarity,
        );

      case _CellType.bacterial:
        final rod = clarity > 0.55 ? true : _rng.nextBool();
        for (var i = 0; i < 9 + _rng.nextInt(5); i++) {
          spots.add(_ringSpot(0.0, 0.62));
        }
        return _Cell(
          type: type,
          sizeFactor: 0.42 + 0.06 * clarity,
          wall: true,
          chloroplasts: 0,
          bigVacuole: false,
          nucleus: false,
          nucleusAt: Offset.zero,
          flagellum: clarity > 0.5 ? true : _rng.nextBool(),
          rod: rod,
          wobbleSeed: _rng.nextDouble() * 6.28,
          spots: spots,
          clarity: clarity,
        );
    }
  }

  Offset _ringSpot(double rMin, double rMax) {
    final a = _rng.nextDouble() * 6.28;
    final r = rMin + _rng.nextDouble() * (rMax - rMin);
    return Offset(math.cos(a) * r, math.sin(a) * r);
  }

  void _loadNext() {
    cell = _generate(_progress);
    focus = 0;
  }

  // ── Scoring — instant confirm, no gate ────────────────────────────────────
  int _mult() => math.min(_kMultMax, 1 + (streak ~/ _kStreakStep));

  void _classify(_CellType guess) {
    if (!widget.session.isRunning) return;
    final correct = guess == cell.type;
    final answered = cell.type;
    lastTapped = guess;
    lastCorrect = correct;
    pressLife = 1.0;
    final center = _stageCenter(_size);

    if (correct) {
      streak++;
      shownMult = _mult();
      final pts = (_kBase *
              _readMult *
              shownMult *
              (surge ? _kSurgeScoreMul : 1.0))
          .round();
      widget.session.addScore(pts);
      widget.session.noteStreak(streak);
      flash = 1.0;
      flashColor = _kGood;
      pops.add(FxPop(center, '+$pts', _kGood));
      particles
          .addAll(FxBurst.spawn(center, _kGood, count: 16, speed: 150));
      if (streak % _kStreakStep == 0) {
        particles
            .addAll(FxBurst.spawn(center, _kGold, count: 12, speed: 120));
      }
      _toast('✓ ${answered.label}', answered.tell, _kGood, life: 0.7);
    } else {
      streak = 0;
      shownMult = 1;
      flash = 1.0;
      flashColor = _kBad;
      particles.addAll(FxBurst.spawn(center, _kBad, count: 12, speed: 130));
      final facts = _kFacts[answered]!;
      _toast('✗ It was ${answered.label}', facts[_factIdx % facts.length],
          _kBad,
          life: 1.6);
      _factIdx++;
    }
    _loadNext(); // NEXT specimen the same frame — the round never stalls.
  }

  void _toast(String text, String sub, Color color, {required double life}) {
    toastText = text;
    toastSub = sub;
    toastColor = color;
    toastLife = life;
  }

  // ── Geometry (shared by hit-test and painter) ─────────────────────────────
  double _choicesHeight(Size s) =>
      math.max(150.0, math.min(s.height * 0.40, 240.0));

  Rect _choiceRect(Size size, int i) {
    final h = _choicesHeight(size);
    final top = size.height - h;
    const pad = 12.0;
    const gap = 10.0;
    final col = i % 2;
    final row = i ~/ 2;
    final cw = (size.width - pad * 2 - gap) / 2;
    final ch = (h - pad * 2 - gap) / 2;
    final x = pad + col * (cw + gap);
    final y = top + pad + row * (ch + gap);
    return Rect.fromLTWH(x, y, cw, ch);
  }

  Offset _stageCenter(Size s) {
    if (s == Size.zero) return Offset.zero;
    final stageH = s.height - _choicesHeight(s);
    return Offset(s.width / 2, stageH * 0.46);
  }

  void _onTapDown(Offset p) {
    if (!widget.session.isRunning) return;
    for (var i = 0; i < _CellType.values.length; i++) {
      if (_choiceRect(_size, i).contains(p)) {
        _classify(_CellType.values[i]);
        return;
      }
    }
  }

  // ── Build — one GestureDetector wrapping one CustomPaint ───────────────────
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, c) {
        _size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTapDown(d.localPosition),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _StagePainter(this),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Stage painter — the whole game is canvas: resolving cell + bonus ring +
// legend + choice deck + non-blocking toast + surge. Repaints off the _Repaint
// pump reading live state; the widget tree is not rebuilt per frame.
// ════════════════════════════════════════════════════════════════════════════

class _StagePainter extends CustomPainter {
  final _CellTypeV2GameState s;
  _StagePainter(this.s) : super(repaint: s.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = s.cell;
    final accent = s.surge ? _kBad : cell.type.accent;
    GameFx.atmosphere(canvas, size, accent, s.clock, motes: 20);

    if (s.flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = s.flashColor.withValues(alpha: 0.5 * s.flash),
      );
    }

    final choicesH = s._choicesHeight(size);
    final stageH = size.height - choicesH;
    final center = Offset(size.width / 2, stageH * 0.46);
    final base = math.min(size.width, stageH) * 0.42;
    final radius = base * cell.sizeFactor;

    _paintBonusRing(canvas, center, base);
    _paintCell(canvas, center, radius, cell);
    _paintReadMult(canvas, center, base);
    _paintFx(canvas, center);
    _paintLegend(canvas, size, stageH);
    _paintStreakChip(canvas, size);
    _paintChoices(canvas, size);
    _paintToast(canvas, size, stageH);
    if (s.surge) _paintSurge(canvas, size);
    _paintFlash(canvas, size);
  }

  // ── The BONUS RING — shrinks as the cell resolves (the legible 2nd axis) ──
  void _paintBonusRing(Canvas canvas, Offset center, double base) {
    if (!s.widget.session.isRunning && s.focus >= 1) return;
    final ringR = base * 1.22;
    // Track.
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // Bonus arc — full when hazy (high payout), empties as it sharpens.
    final remaining = (1.0 - s.focus).clamp(0.0, 1.0);
    if (remaining <= 0.01) return;
    final col = s.surge ? _kBad : _kGold;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringR),
      -math.pi / 2,
      -remaining * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = col.withValues(alpha: 0.85)
        ..maskFilter = remaining > 0.5
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null,
    );
  }

  void _paintReadMult(Canvas canvas, Offset center, double base) {
    if (!s.widget.session.isRunning) return;
    final m = s._readMult;
    final col = m > 1.45 ? _kGold : Colors.white.withValues(alpha: 0.75);
    GameFx.text(canvas, '×${m.toStringAsFixed(1)} READ',
        Offset(center.dx, center.dy - base * 1.22 - 16), 12, col,
        weight: FontWeight.w800, glow: m > 1.45 ? 0.5 : 0);
  }

  // ── The resolving cell. Body/size always visible (size IS a tell); fine
  //    organelles fade in with focus + a settling jitter — "coming into focus".
  /// [det] (detail) is the focus-eased alpha for fine internal structure.
  void _paintCell(Canvas canvas, Offset center, double radius, _Cell cell) {
    final breathe = 1 + 0.012 * math.sin(s.clock * 1.6 + cell.wobbleSeed);
    final det = Curves.easeIn.transform(s.focus); // organelles resolve late
    final jit = (1 - s.focus) * radius * 0.05; // settling shudder while hazy

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathe);

    switch (cell.type) {
      case _CellType.plant:
        _paintPlant(canvas, radius, cell, det, jit);
      case _CellType.fungal:
        _paintFungal(canvas, radius, cell, det, jit);
      case _CellType.animal:
        _paintAnimal(canvas, radius, cell, det, jit);
      case _CellType.bacterial:
        _paintBacterial(canvas, radius, cell, det, jit);
    }
    canvas.restore();

    // Defocus haze — a translucent accent disk muting detail while hazy (a
    // cheap "out of focus" fake; no per-frame blur over the whole cell).
    if (s.focus < 0.98) {
      canvas.drawCircle(
        center,
        radius * 1.05,
        Paint()
          ..color = cell.type.accent.withValues(alpha: 0.20 * (1 - s.focus))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  double _drift(double seed) => math.sin(s.clock * 0.9 + seed);

  // -- Shared organelle helpers (focus-gated) --------------------------------
  Path _membrane(double r, double seed, {double deform = 0.06, int lobes = 6}) {
    final path = Path();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * 2 * math.pi;
      final wob = 1 +
          deform * math.sin(a * lobes + seed) +
          deform * 0.5 * math.cos(a * (lobes + 3) - seed);
      final p = Offset(math.cos(a) * r * wob, math.sin(a) * r * wob);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _fillBody(Canvas canvas, Path path, double r, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.30)!.withValues(alpha: 0.55),
            color.withValues(alpha: 0.34),
            Color.lerp(color, Colors.black, 0.5)!.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
  }

  void _nucleus(Canvas canvas, Offset at, double r, Color tint, double det) {
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(tint, Colors.white, 0.4)!,
            tint,
            Color.lerp(tint, Colors.black, 0.4)!,
          ],
        ).createShader(Rect.fromCircle(center: at, radius: r))
        ..color = Colors.white.withValues(alpha: det),
    );
    canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.5 * det));
    canvas.drawCircle(at.translate(r * 0.2, -r * 0.1), r * 0.32,
        Paint()..color = Color.lerp(tint, Colors.black, 0.45)!.withValues(alpha: det));
  }

  // -- Plant -----------------------------------------------------------------
  void _paintPlant(Canvas canvas, double r, _Cell cell, double det, double jit) {
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.9, height: r * 1.9),
      Radius.circular(r * 0.22),
    );
    canvas.drawRRect(
        box, Paint()..color = const Color(0xFF6B8E3D).withValues(alpha: 0.9));
    final inner = box.deflate(r * 0.10);
    _fillBody(canvas, Path()..addRRect(inner), r, _kPlant);
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..color = const Color(0xFF8FB45A));

    if (cell.bigVacuole) {
      canvas.drawCircle(Offset(r * 0.06, r * 0.06), r * 0.62,
          Paint()..color = const Color(0xFF9FD8E8).withValues(alpha: 0.22 * det));
    }

    // Chloroplasts — the green tell, fading in with focus.
    for (var i = 0; i < cell.chloroplasts; i++) {
      final sp = cell.spots[i % cell.spots.length];
      final d = 0.018 * r * _drift(i.toDouble());
      final c = Offset(sp.dx * r + d + jit * _drift(i + 3.0),
          sp.dy * r - d + jit * _drift(i + 7.0));
      final ang = math.atan2(sp.dy, sp.dx) + 1.0;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ang);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 0.34, height: r * 0.16),
            Radius.circular(r * 0.08)),
        Paint()..color = const Color(0xFF2E7D32).withValues(alpha: det),
      );
      final lp = Paint()
        ..color = const Color(0xFF8BC34A).withValues(alpha: 0.85 * det)
        ..strokeWidth = 1.1;
      for (var g = -1; g <= 1; g++) {
        canvas.drawLine(Offset(-r * 0.1, g * r * 0.04),
            Offset(r * 0.1, g * r * 0.04), lp);
      }
      canvas.restore();
    }

    _nucleus(canvas, Offset(cell.nucleusAt.dx * r, cell.nucleusAt.dy * r),
        r * 0.22, const Color(0xFF7E57C2), det);
  }

  // -- Fungal ----------------------------------------------------------------
  void _paintFungal(Canvas canvas, double r, _Cell cell, double det, double jit) {
    final path = _membrane(r, cell.wobbleSeed, deform: 0.03, lobes: 5);
    canvas.drawPath(
        path, Paint()..color = const Color(0xFFBE8A3A).withValues(alpha: 0.95));
    final innerPath = _membrane(r * 0.9, cell.wobbleSeed, deform: 0.03, lobes: 5);
    _fillBody(canvas, innerPath, r, _kFungal);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..color = const Color(0xFFE0B050));

    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      final d = 0.02 * r * math.sin(s.clock * 1.1 + i);
      final c = Offset(sp.dx * r + jit * _drift(i + 2.0), sp.dy * r + d);
      if (i.isEven) {
        canvas.drawCircle(c, r * 0.12,
            Paint()..color = const Color(0xFFF3E2BE).withValues(alpha: 0.30 * det));
      } else {
        canvas.drawCircle(c, r * 0.05,
            Paint()..color = const Color(0xFF7A5A28).withValues(alpha: det));
      }
    }
    _nucleus(canvas, Offset(cell.nucleusAt.dx * r, cell.nucleusAt.dy * r),
        r * 0.22, const Color(0xFF8D6E63), det);
  }

  // -- Animal ----------------------------------------------------------------
  void _paintAnimal(Canvas canvas, double r, _Cell cell, double det, double jit) {
    final path = _membrane(r, cell.wobbleSeed, deform: 0.08, lobes: 5);
    _fillBody(canvas, path, r, _kAnimal);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: 0.55));

    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      final d = 0.025 * r * math.sin(s.clock * 1.3 + i * 1.7);
      final c = Offset(sp.dx * r + d + jit * _drift(i + 4.0), sp.dy * r);
      final ang = math.atan2(sp.dy, sp.dx);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ang);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 0.30, height: r * 0.14),
          Radius.circular(r * 0.07),
        ),
        Paint()..color = const Color(0xFFEF8E3D).withValues(alpha: det),
      );
      final cp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF8A3B12).withValues(alpha: det);
      final crista = Path();
      for (var x = -3; x <= 3; x++) {
        final px = x * r * 0.04;
        final py = (x.isEven ? 1 : -1) * r * 0.03;
        if (x == -3) {
          crista.moveTo(px, py);
        } else {
          crista.lineTo(px, py);
        }
      }
      canvas.drawPath(crista, cp);
      canvas.restore();
    }
    _nucleus(canvas, Offset(cell.nucleusAt.dx * r, cell.nucleusAt.dy * r),
        r * 0.30, const Color(0xFF5C6BC0), det);
  }

  // -- Bacterial -------------------------------------------------------------
  void _paintBacterial(
      Canvas canvas, double r, _Cell cell, double det, double jit) {
    final bodyRect = cell.rod
        ? Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 1.3)
        : Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 1.7);
    final radius = Radius.circular(bodyRect.height / 2);

    if (cell.flagellum) {
      final p = Path();
      final startX = -bodyRect.width / 2;
      p.moveTo(startX, 0);
      for (var i = 0; i <= 24; i++) {
        final t = i / 24;
        final x = startX - t * r * 1.5;
        final y = math.sin(t * 12 + s.clock * 6) * r * 0.18 * t;
        p.lineTo(x, y);
      }
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = _kBacterial.withValues(alpha: 0.7 * det),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect.inflate(r * 0.16), radius),
      Paint()..color = _kBacterial.withValues(alpha: 0.14),
    );
    final body = RRect.fromRectAndRadius(bodyRect, radius);
    _fillBody(canvas, Path()..addRRect(body), r, _kBacterial);
    canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.07
          ..color = const Color(0xFF80DEEA));

    // Nucleoid — free DNA (the big tell: NO nucleus), fading in with focus.
    final dna = Path();
    for (var i = 0; i <= 40; i++) {
      final t = i / 40;
      final ang = t * 6.28 * 2;
      final rr = r * (0.18 + 0.10 * math.sin(ang * 1.5));
      final x = math.cos(ang) * rr;
      final y = math.sin(ang) * rr * (cell.rod ? 1.4 : 1.0);
      if (i == 0) {
        dna.moveTo(x, y);
      } else {
        dna.lineTo(x, y);
      }
    }
    canvas.drawPath(
      dna,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.85 * det),
    );

    final rib = Paint()..color = const Color(0xFF00838F).withValues(alpha: det);
    final maxX = bodyRect.width / 2 - r * 0.15;
    final maxY = bodyRect.height / 2 - r * 0.15;
    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      canvas.drawCircle(
          Offset(sp.dx * maxX + jit * _drift(i + 1.0), sp.dy * maxY),
          r * 0.045,
          rib);
    }
  }

  // ── Choice deck (canvas buttons; hit-tested by the state) ─────────────────
  void _paintChoices(Canvas canvas, Size size) {
    final running = s.widget.session.isRunning;
    for (var i = 0; i < _CellType.values.length; i++) {
      final t = _CellType.values[i];
      final rect = s._choiceRect(size, i);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      Color edge = _kCardEdge;
      Color bg = _kCardBg;
      Color fg = Potatuhs.textPrimary;
      double scale = 1.0;

      // Brief per-button press feedback (does not gate; next cell already up).
      if (s.pressLife > 0 && s.lastTapped == t) {
        final c = s.lastCorrect ? _kGood : _kBad;
        edge = c.withValues(alpha: 0.9);
        bg = c.withValues(alpha: 0.14);
        fg = c;
        scale = 1.0 + 0.05 * s.pressLife;
      }

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(scale);
      canvas.translate(-rect.center.dx, -rect.center.dy);

      canvas.drawRRect(rr, Paint()..color = bg);
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = edge,
      );
      if (s.pressLife > 0 && s.lastTapped == t && s.lastCorrect) {
        canvas.drawRRect(
          rr,
          Paint()
            ..color = _kGood.withValues(alpha: 0.22 * s.pressLife)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Icon + label, centred.
      final iconColor = (s.pressLife > 0 && s.lastTapped == t)
          ? fg
          : (running ? t.accent : t.accent.withValues(alpha: 0.6));
      _icon(canvas, t.icon, rect.center.translate(-rect.width * 0.28, 0), 20,
          iconColor);
      _label(canvas, t.label, rect.center.translate(rect.width * 0.06, 0), 14,
          fg);
      canvas.restore();
    }
  }

  void _icon(Canvas canvas, IconData ic, Offset at, double sz, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(ic.codePoint),
        style: TextStyle(
          fontFamily: ic.fontFamily,
          package: ic.fontPackage,
          fontSize: sz,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _label(Canvas canvas, String s2, Offset at, double sz, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s2,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: sz,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Persistent micro-legend (the on-screen decision tree, scaffold) ───────
  void _paintLegend(Canvas canvas, Size size, double stageH) {
    final a = s._legendAlpha;
    final y = stageH - 30.0;
    GameFx.text(canvas, 'READ THE TELL', Offset(size.width / 2, stageH - 46),
        10, Colors.white.withValues(alpha: 0.4 * a),
        weight: FontWeight.w700);
    final colW = size.width / 4;
    for (var i = 0; i < _CellType.values.length; i++) {
      final t = _CellType.values[i];
      final cx = colW * i + colW / 2;
      _icon(canvas, t.icon, Offset(cx - 30, y), 13,
          t.accent.withValues(alpha: 0.8 * a));
      _legendText(canvas, t.label, Offset(cx + 4, y - 5), 9.0,
          Colors.white.withValues(alpha: 0.75 * a), FontWeight.w800);
      _legendText(canvas, _shortTell(t), Offset(cx + 4, y + 6), 7.5,
          Colors.white.withValues(alpha: 0.45 * a), FontWeight.w500);
    }
  }

  String _shortTell(_CellType t) => switch (t) {
        _CellType.plant => 'wall+green',
        _CellType.animal => 'no wall',
        _CellType.bacterial => 'tiny',
        _CellType.fungal => 'wall,no green',
      };

  void _legendText(
      Canvas canvas, String txt, Offset at, double sz, Color c, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
          text: txt,
          style: TextStyle(
              fontFamily: _kFont, fontSize: sz, fontWeight: w, color: c)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Streak / multiplier chip (capped — legible standing) ──────────────────
  void _paintStreakChip(Canvas canvas, Size size) {
    if (s.shownMult <= 1) return;
    GameFx.text(canvas, '×${s.shownMult} STREAK', Offset(size.width - 56, 20),
        13, _kGold,
        weight: FontWeight.w800, glow: 0.5);
  }

  void _paintFx(Canvas canvas, Offset center) {
    FxBurst.paint(canvas, s.particles);
    for (final p in s.pops) {
      p.paint(canvas);
    }
  }

  // ── Non-blocking toast (correct: short tell · wrong: full fact) ───────────
  void _paintToast(Canvas canvas, Size size, double stageH) {
    if (s.toastLife <= 0.01) return;
    final a = (s.toastLife.clamp(0.0, 0.4) / 0.4); // fade in last 0.4s
    final y = stageH - 86.0;
    GameFx.text(canvas, s.toastText, Offset(size.width / 2, y), 17,
        s.toastColor.withValues(alpha: a),
        weight: FontWeight.w900, glow: 0.6 * a, display: false);
    _wrapText(canvas, s.toastSub, Offset(size.width / 2, y + 18),
        size.width * 0.86, 11.5, Colors.white.withValues(alpha: 0.7 * a));
  }

  void _wrapText(Canvas canvas, String txt, Offset center, double maxW,
      double sz, Color c) {
    final tp = TextPainter(
      text: TextSpan(
          text: txt,
          style: TextStyle(
              fontFamily: _kFont, fontSize: sz, color: c, height: 1.3)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    tp.paint(canvas, center - Offset(tp.width / 2, 0));
  }

  // ── FINAL CELLS climax ────────────────────────────────────────────────────
  void _paintSurge(Canvas canvas, Size size) {
    final pulse = 0.16 + 0.12 * (0.5 + 0.5 * math.sin(s.clock * 6));
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, _kBad.withValues(alpha: pulse)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
    GameFx.text(canvas, 'FINAL CELLS  ×2', Offset(size.width / 2, 26), 16,
        _kBad,
        display: true,
        glow: 0.7 + 0.3 * (0.5 + 0.5 * math.sin(s.clock * 6)));
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (s.flash > 0.3 && s.flashColor == _kBad) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: (s.flash - 0.3) * 0.30));
    }
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) => false;
}
