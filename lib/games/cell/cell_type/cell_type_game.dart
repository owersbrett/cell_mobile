import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ============================================================================
// CELL TYPE — Read a procedurally drawn cell and classify it (BioScale.cell).
//
// A cell is drawn live from its structural tells — cell wall, chloroplasts,
// central vacuole, nucleus (or nucleoid), flagellum, relative size. The player
// classifies it as PLANT / ANIMAL / BACTERIAL / FUNGAL before the next one
// loads. Speed-scored with a streak multiplier (same idiom as Organ Rush). The
// tells get subtler and the speed window shrinks as the round runs, so the
// structural differences ARE the difficulty curve — that's the education.
//
// The host owns the 60 s clock, score readout, countdown and results. This
// widget only renders the play area, gates on session.isRunning, and reports
// through session.addScore / session.noteStreak. It never calls endEarly.
// ============================================================================

const String _kFont = Potatuhs.bodyFont;

// -- Palette -----------------------------------------------------------------
const Color _kPlant     = Color(0xFF4CAF50); // chlorophyll green
const Color _kAnimal    = Color(0xFFE8567E); // membrane pink
const Color _kBacterial = Color(0xFF26C6DA); // prokaryote teal
const Color _kFungal    = Color(0xFFE0A93B); // chitin amber
const Color _kGold      = Color(0xFFE1C916); // streak flash (Potatuhs.gold)
const Color _kGood      = Color(0xFF69F0AE);
const Color _kBad       = Color(0xFFFF5252);
const Color _kCardBg    = Color(0xFF1B1A17);
const Color _kCardEdge  = Color(0xFF34302A);

// -- Timing / scoring --------------------------------------------------------
const double _kFlareDuration = 1.9;  // seconds the fact card holds before advance
const int    _kMaxPoints     = 110;  // instant-answer ceiling
const int    _kFloorPoints   = 15;   // very-slow-answer floor
const double _kDecayFast     = 3.4;  // decay window (s) at round start
const double _kDecaySlow     = 1.7;  // decay window (s) at round end
const int    _kStreakStep    = 3;    // every N correct = +1x multiplier

// ============================================================================
// Cell model
// ============================================================================

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
}

/// One procedurally specified cell. Feature flags are the tells; positions are
/// frozen at creation so organelles drift around a stable base, never jump.
class _Cell {
  final _CellType type;
  final double sizeFactor;   // fraction of the available radius the cell fills
  final bool wall;           // rigid outer wall present
  final int chloroplasts;    // green photosynthetic bodies (plant only)
  final bool bigVacuole;     // large central vacuole (plant)
  final bool nucleus;        // true nucleus (eukaryotes); false = nucleoid
  final Offset nucleusAt;    // unit-space nucleus center
  final bool flagellum;      // whip tail (some bacteria)
  final bool rod;            // bacterial rod (true) vs coccus (false)
  final double wobbleSeed;   // membrane deform phase
  final List<Offset> spots;  // unit-space organelle/granule/ribosome anchors
  final double clarity;      // 1 = obvious tells, 0 = subtle (harder)

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

// ============================================================================
// Facts — the per-answer education. One is shown after each classification.
// ============================================================================

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

// ============================================================================
// Widget
// ============================================================================

class CellTypeGame extends StatefulWidget {
  final MiniGameSession session;
  const CellTypeGame({super.key, required this.session});

  @override
  State<CellTypeGame> createState() => _CellTypeGameState();
}

/// Lightweight repaint pump — ticked every frame so the cell painter repaints
/// without rebuilding the widget tree (no per-frame setState over the buttons).
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

enum _Answer { waiting, correct, wrong }

class _CellTypeGameState extends State<CellTypeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _Repaint repaint = _Repaint();

  Duration _lastElapsed = Duration.zero;
  double clock = 0; // seconds, read by painter

  // Current cell + classification state.
  late _Cell cell;
  _CellType? _lastType;
  _Answer answer = _Answer.waiting;
  _CellType? _tapped;
  String _fact = '';
  int _factIdx = 0;
  double _questionT = 0;  // seconds the current cell has been on screen
  double _flareT = 0;     // counts down from _kFlareDuration after an answer

  // Streak / scoring.
  int _streak = 0;
  int _shownMult = 1;

  // Feedback flash on the cell stage (0..1) + its colour, read by painter.
  double flash = 0;
  Color flashColor = _kGood;

  final List<FxParticle> particles = [];
  Size _stageSize = Size.zero;
  bool _wasRunning = false;

  @override
  void initState() {
    super.initState();
    cell = _generate(0);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  // -- Difficulty --------------------------------------------------------------

  /// 0 at the start of the round, 1 at the end. Drives tell subtlety + speed.
  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  double get _decayWindow =>
      _kDecayFast + (_kDecaySlow - _kDecayFast) * _progress;

  // -- Loop --------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    clock += dt;

    // Auto-start: when the host flips us into play, present a fresh cell.
    final running = widget.session.isRunning;
    if (running && !_wasRunning) {
      _resetForPlay();
    }
    _wasRunning = running;

    if (running) {
      if (answer == _Answer.waiting) {
        _questionT += dt;
      } else {
        _flareT -= dt;
        if (_flareT <= 0) {
          _loadNext();
        }
      }
    }

    if (flash > 0) flash = (flash - dt / 0.5).clamp(0.0, 1.0);
    particles.removeWhere((p) => !p.step(dt));

    repaint.tick();
  }

  void _resetForPlay() {
    setState(() {
      _streak = 0;
      _shownMult = 1;
      cell = _generate(0);
      answer = _Answer.waiting;
      _tapped = null;
      _questionT = 0;
      _flareT = 0;
    });
  }

  // -- Cell generation ---------------------------------------------------------

  _CellType _pickType() {
    // Even spread, but never the same type twice running (keeps it readable).
    _CellType t;
    do {
      t = _CellType.values[_rng.nextInt(_CellType.values.length)];
    } while (t == _lastType && _rng.nextDouble() < 0.7);
    _lastType = t;
    return t;
  }

  _Cell _generate(double progress) {
    final type = _pickType();
    // clarity: obvious early (1.0) → subtle late (~0.35). Subtle plants lose
    // chloroplasts, subtle bacteria become cocci, fungal/plant blur.
    final clarity = (1.0 - progress * 0.65).clamp(0.35, 1.0);
    final spots = <Offset>[];

    switch (type) {
      case _CellType.plant:
        // More chloroplasts when clear; can drop to 1–2 when subtle.
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
        // Granules + small vacuoles, wall but NO chloroplasts. Plant look-alike.
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
        // Mitochondria scattered; no wall, no big vacuole. Fungal look-alike
        // when subtle (both round) — the tell is the absence of a wall.
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
          nucleusAt: Offset(
              0.16 * (_rng.nextDouble() * 2 - 1), 0.12 * (_rng.nextDouble() * 2 - 1)),
          flagellum: false,
          rod: false,
          wobbleSeed: _rng.nextDouble() * 6.28,
          spots: spots,
          clarity: clarity,
        );

      case _CellType.bacterial:
        // Tiny, NO nucleus (nucleoid), ribosome dots, wall + capsule. Rod when
        // clear; coccus (small round) when subtle to flirt with animal cells.
        final rod = clarity > 0.55 ? true : _rng.nextBool();
        for (var i = 0; i < 9 + _rng.nextInt(5); i++) {
          spots.add(_ringSpot(0.0, 0.62));
        }
        return _Cell(
          type: type,
          sizeFactor: 0.42 + 0.06 * clarity, // clearly small = the big tell
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
    setState(() {
      cell = _generate(_progress);
      answer = _Answer.waiting;
      _tapped = null;
      _questionT = 0;
      _flareT = 0;
    });
  }

  // -- Scoring -----------------------------------------------------------------

  int _speedBonus() {
    final frac = (_questionT / _decayWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _mult() => 1 + (_streak ~/ _kStreakStep);

  void _classify(_CellType guess) {
    if (!widget.session.isRunning || answer != _Answer.waiting) return;
    _tapped = guess;
    final correct = guess == cell.type;
    final facts = _kFacts[cell.type]!;
    _fact = facts[_factIdx % facts.length];
    _factIdx++;

    if (correct) {
      answer = _Answer.correct;
      _streak++;
      _shownMult = _mult();
      widget.session.addScore(_speedBonus() * _shownMult);
      widget.session.noteStreak(_streak);
      flash = 1.0;
      flashColor = _kGood;
      particles.addAll(FxBurst.spawn(
        _stageSize.center(Offset.zero),
        _kGood,
        count: 16,
        speed: 150,
      ));
      if (_streak % _kStreakStep == 0) {
        particles.addAll(FxBurst.spawn(
          _stageSize.center(Offset.zero),
          _kGold,
          count: 12,
          speed: 120,
        ));
      }
    } else {
      answer = _Answer.wrong;
      _streak = 0;
      _shownMult = 1;
      flash = 1.0;
      flashColor = _kBad;
    }
    _flareT = _kFlareDuration;
    setState(() {});
  }

  void _skipFlare() {
    if (answer == _Answer.waiting) return;
    _flareT = 0;
    _loadNext();
  }

  // ============================================================================
  // Build
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 480;
          final content = Column(
            children: [
              _buildHud(),
              // Cell stage — the read-the-tells area. Gets the most space.
              Expanded(
                flex: short ? 4 : 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: LayoutBuilder(builder: (context, c) {
                    _stageSize = Size(c.maxWidth, c.maxHeight);
                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _StagePainter(this),
                      ),
                    );
                  }),
                ),
              ),
              // Prompt / classify buttons.
              Expanded(
                flex: short ? 5 : 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _buildChoices(),
                ),
              ),
            ],
          );

          return Stack(
            children: [
              Positioned.fill(child: content),
              // Fact flare overlays the bottom so it never reflows the grid.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: answer != _Answer.waiting
                        ? _buildFlare()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // -- HUD (rebuilds only on session changes, not per frame) -------------------

  Widget _buildHud() {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          final score = widget.session.score;
          final secs = widget.session.remaining.inSeconds;
          final tenths =
              (widget.session.remaining.inMilliseconds / 100).floor() % 10;
          return Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Potatuhs.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (_streak >= _kStreakStep)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: _kGold.withValues(alpha: 0.7)),
                    ),
                    child: Text(
                      'x$_shownMult',
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kGold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '$secs.$tenths',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: secs < 5
                        ? _kBad
                        : Potatuhs.textPrimary.withValues(alpha: 0.8),
                    shadows: secs < 5
                        ? const [Shadow(color: _kBad, blurRadius: 10)]
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -- Choices -----------------------------------------------------------------

  Widget _buildChoices() {
    return Column(
      children: [
        Text(
          'WHAT KIND OF CELL?',
          style: Potatuhs.label(size: 12, color: Potatuhs.textSecondary),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children: _CellType.values.map(_buildChoiceCard).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceCard(_CellType t) {
    final answered = answer != _Answer.waiting;
    final isCorrect = t == cell.type;
    final isTapped = t == _tapped;

    Color edge = _kCardEdge;
    Color bg = _kCardBg;
    Color fg = Potatuhs.textPrimary;
    if (answered) {
      if (isCorrect) {
        edge = _kGood.withValues(alpha: 0.9);
        bg = _kGood.withValues(alpha: 0.12);
        fg = _kGood;
      } else if (isTapped) {
        edge = _kBad.withValues(alpha: 0.9);
        bg = _kBad.withValues(alpha: 0.10);
        fg = _kBad;
      } else {
        edge = _kCardEdge.withValues(alpha: 0.4);
        fg = Potatuhs.textFaint;
      }
    }

    return GestureDetector(
      onTap: () => _classify(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: edge, width: 1.6),
          boxShadow: answered && isCorrect
              ? [BoxShadow(color: _kGood.withValues(alpha: 0.22), blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(t.icon,
                  size: 18,
                  color: answered ? fg : t.accent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Fact flare --------------------------------------------------------------

  Widget _buildFlare() {
    final ok = answer == _Answer.correct;
    final pts = ok ? _speedBonus() : 0;
    final header = ok
        ? (_shownMult > 1 ? '+${pts * _shownMult}  x$_shownMult streak' : '+$pts')
        : 'It was ${cell.type.label}';
    return GestureDetector(
      onTap: _skipFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey('$_factIdx'),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: (ok ? _kGood : _kBad).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (ok ? _kGood : _kBad).withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(cell.type.icon, size: 16, color: cell.type.accent),
                const SizedBox(width: 6),
                Text(
                  header,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: ok ? _kGood : _kBad,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _fact,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12.5,
                color: Potatuhs.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TAP TO CONTINUE',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: cell.type.accent.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: cell.type.accent.withValues(alpha: 0.75)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Stage painter — draws the cell + ambient field + juice. Repaints off the
// _Repaint pump, reading live state; the widget tree is not rebuilt per frame.
// ============================================================================

class _StagePainter extends CustomPainter {
  final _CellTypeGameState s;
  _StagePainter(this.s) : super(repaint: s.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = s.cell;
    final accent = cell.type.accent;
    GameFx.atmosphere(canvas, size, accent, s.clock, motes: 22);

    // Answer flash ring around the whole stage.
    if (s.flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = s.flashColor.withValues(alpha: 0.5 * s.flash),
      );
    }

    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * 0.46;
    final radius = base * cell.sizeFactor;
    final breathe = 1 + 0.012 * math.sin(s.clock * 1.6 + cell.wobbleSeed);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathe);

    switch (cell.type) {
      case _CellType.plant:
        _paintPlant(canvas, radius, cell);
      case _CellType.fungal:
        _paintFungal(canvas, radius, cell);
      case _CellType.animal:
        _paintAnimal(canvas, radius, cell);
      case _CellType.bacterial:
        _paintBacterial(canvas, radius, cell);
    }
    canvas.restore();

    FxBurst.paint(canvas, s.particles);
  }

  // -- Shared helpers ----------------------------------------------------------

  /// A blobby membrane path: a circle deformed by low-frequency sine, in cell
  /// local space (centred on origin).
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

  void _nucleus(Canvas canvas, Offset at, double r, Color tint) {
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
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    canvas.drawCircle(at, r,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = Colors.white.withValues(alpha: 0.5));
    // Nucleolus.
    canvas.drawCircle(at.translate(r * 0.2, -r * 0.1), r * 0.32,
        Paint()..color = Color.lerp(tint, Colors.black, 0.45)!);
  }

  // -- Plant: rigid walled box, chloroplasts, big central vacuole --------------

  void _paintPlant(Canvas canvas, double r, _Cell cell) {
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: r * 1.9, height: r * 1.9),
      Radius.circular(r * 0.22),
    );
    // Outer cellulose wall (thick, double-layered, the boxy tell).
    canvas.drawRRect(
        box, Paint()..color = const Color(0xFF6B8E3D).withValues(alpha: 0.9));
    final inner = box.deflate(r * 0.10);
    _fillBody(canvas, Path()..addRRect(inner), r, _kPlant);
    canvas.drawRRect(box,
        Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.05..color = const Color(0xFF8FB45A));

    // Big central vacuole — a large pale region that pushes everything out.
    if (cell.bigVacuole) {
      canvas.drawCircle(
        Offset(r * 0.06, r * 0.06),
        r * 0.62,
        Paint()
          ..color = const Color(0xFF9FD8E8).withValues(alpha: 0.22),
      );
      canvas.drawCircle(Offset(r * 0.06, r * 0.06), r * 0.62,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: 0.18));
    }

    // Chloroplasts — green stadium bodies hugging the wall, with grana stripes.
    for (var i = 0; i < cell.chloroplasts; i++) {
      final sp = cell.spots[i % cell.spots.length];
      final drift = 0.018 * r * math.sin(s.clock * 0.9 + i);
      final c = Offset(sp.dx * r + drift, sp.dy * r - drift);
      final ang = math.atan2(sp.dy, sp.dx) + 1.0;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ang);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: r * 0.34, height: r * 0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r * 0.08)),
        Paint()..color = const Color(0xFF2E7D32),
      );
      // Grana stack lines.
      final lp = Paint()
        ..color = const Color(0xFF8BC34A).withValues(alpha: 0.85)
        ..strokeWidth = 1.1;
      for (var g = -1; g <= 1; g++) {
        canvas.drawLine(Offset(-r * 0.1, g * r * 0.04),
            Offset(r * 0.1, g * r * 0.04), lp);
      }
      canvas.restore();
    }

    _nucleus(canvas, Offset(cell.nucleusAt.dx * r, cell.nucleusAt.dy * r),
        r * 0.22, const Color(0xFF7E57C2));
  }

  // -- Fungal: round wall (chitin), nucleus, granules, NO chloroplasts ---------

  void _paintFungal(Canvas canvas, double r, _Cell cell) {
    final path = _membrane(r, cell.wobbleSeed, deform: 0.03, lobes: 5);
    // Chitin wall (the tell vs animal): a clear outer ring.
    canvas.drawPath(
        path, Paint()..color = const Color(0xFFBE8A3A).withValues(alpha: 0.95));
    final innerPath = _membrane(r * 0.9, cell.wobbleSeed, deform: 0.03, lobes: 5);
    _fillBody(canvas, innerPath, r, _kFungal);
    canvas.drawPath(path,
        Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.05..color = const Color(0xFFE0B050));

    // Small vacuoles + glycogen granules (no big central vacuole, no green).
    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      final drift = 0.02 * r * math.sin(s.clock * 1.1 + i);
      final c = Offset(sp.dx * r, sp.dy * r + drift);
      if (i.isEven) {
        canvas.drawCircle(c, r * 0.12,
            Paint()..color = const Color(0xFFF3E2BE).withValues(alpha: 0.30));
      } else {
        canvas.drawCircle(c, r * 0.05,
            Paint()..color = const Color(0xFF7A5A28));
      }
    }
    _nucleus(canvas, Offset(cell.nucleusAt.dx * r, cell.nucleusAt.dy * r),
        r * 0.22, const Color(0xFF8D6E63));
  }

  // -- Animal: wall-less round blob, central nucleus, mitochondria -------------

  void _paintAnimal(Canvas canvas, double r, _Cell cell) {
    final path = _membrane(r, cell.wobbleSeed, deform: 0.08, lobes: 5);
    _fillBody(canvas, path, r, _kAnimal);
    // Single thin membrane (NO wall) — the key tell.
    canvas.drawPath(path,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: 0.55));

    // Mitochondria — small orange ovals with a cristae squiggle.
    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      final drift = 0.025 * r * math.sin(s.clock * 1.3 + i * 1.7);
      final c = Offset(sp.dx * r + drift, sp.dy * r);
      final ang = math.atan2(sp.dy, sp.dx);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ang);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: r * 0.30, height: r * 0.14),
          Radius.circular(r * 0.07),
        ),
        Paint()..color = const Color(0xFFEF8E3D),
      );
      final cp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF8A3B12);
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
        r * 0.30, const Color(0xFF5C6BC0));
  }

  // -- Bacterial: tiny, NO nucleus (nucleoid), ribosomes, wall, flagellum ------

  void _paintBacterial(Canvas canvas, double r, _Cell cell) {
    // Capsule halo.
    final bodyRect = cell.rod
        ? Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 1.3)
        : Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 1.7);
    final radius = Radius.circular(bodyRect.height / 2);

    // Flagellum (whip tail) — drawn first so the body sits on top.
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
          ..color = _kBacterial.withValues(alpha: 0.7),
      );
    }

    // Capsule (outer protective layer).
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect.inflate(r * 0.16), radius),
      Paint()..color = _kBacterial.withValues(alpha: 0.14),
    );
    // Cell wall + body.
    final body = RRect.fromRectAndRadius(bodyRect, radius);
    _fillBody(canvas, Path()..addRRect(body), r, _kBacterial);
    canvas.drawRRect(body,
        Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.07..color = const Color(0xFF80DEEA));

    // Nucleoid — a free tangle of DNA in the centre (NO membrane: the big tell).
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
        ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.85),
    );

    // Ribosome dots scattered across the cytoplasm.
    final rib = Paint()..color = const Color(0xFF00838F);
    final maxX = bodyRect.width / 2 - r * 0.15;
    final maxY = bodyRect.height / 2 - r * 0.15;
    for (var i = 0; i < cell.spots.length; i++) {
      final sp = cell.spots[i];
      canvas.drawCircle(
          Offset(sp.dx * maxX, sp.dy * maxY), r * 0.045, rib);
    }
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) => false;
}
