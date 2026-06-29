import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// TISSUE TYPE — Classify the procedurally-drawn histology sample.
//
// A stained tissue "slide" is drawn from a seeded RNG; the player reads its
// morphology and classifies it as one of the four PRIMARY tissue types:
//   • EPITHELIAL — cells packed edge-to-edge into continuous sheets / linings.
//   • CONNECTIVE — few cells scattered far apart in a big matrix (bone/blood/fat).
//   • MUSCLE     — long parallel fibres built to contract.
//   • NERVOUS    — star-shaped cell bodies trailing branching processes.
//
// Faster correct answers earn more points (speed bonus decays over a window
// that shrinks as the round accelerates). A streak multiplier rewards a run of
// correct calls. Each answer reveals a fact card about that exact subtype. The
// samples get subtler (fainter tells) and the per-sample deadline shrinks as
// you go. The host owns the round timer; this widget never calls endEarly.
//
// PERF: one Ticker drives everything. The heavy sample drawing lives in its own
// RepaintBoundary + CustomPainter that only repaints when the sample changes
// (shouldRepaint keys on the sample id); the cheap ambient/particle layer
// animates every frame. No per-frame setState rebuilds the sample painter.
// ============================================================================

const String _kFont = Potatuhs.bodyFont;

// -- Slide / stain palette (uniform across ALL samples on purpose: the player
//    must read shape, not colour) --------------------------------------------
const Color _kBg        = Color(0xFF0B0810); // near-black scope field
const Color _kSlide     = Color(0xFF150F1C); // faint plum slide tint
const Color _kMembrane  = Color(0xFFE85C9C); // membranes / outlines (magenta)
const Color _kCyto      = Color(0xFF7A2348); // cytoplasm fill (dark rose)
const Color _kNuc       = Color(0xFFB388FF); // nuclei (violet — hematoxylin)
const Color _kFiber     = Color(0xFFC2698F); // fibres / matrix (rose)

// -- UI chrome ---------------------------------------------------------------
const Color _kGold      = Color(0xFFFFD600);
const Color _kGoodGreen = Color(0xFF69F0AE);
const Color _kBadRed    = Color(0xFFFF5252);
const Color _kCardBg    = Color(0xFF161020);
const Color _kCardBorder= Color(0xFF2C2238);
const Color _kTextPri   = Color(0xFFF0EAF5);
const Color _kTextSub   = Color(0xFF978CA8);

// -- Per-type accents (UI only — never used inside the sample) ---------------
const Color _kEpiAccent = Color(0xFF26C6DA); // cyan
const Color _kConAccent = Color(0xFFFFB74D); // amber
const Color _kMusAccent = Color(0xFFEF5350); // red
const Color _kNerAccent = Color(0xFFAB47BC); // violet

// -- Timing / scoring --------------------------------------------------------
const double _kFactFlareDuration = 2.4;
const int    _kMaxPoints   = 130;
const int    _kFloorPoints = 25;
const int    _kStreakStep  = 3;   // every N correct → +1× multiplier
const double _kBaseDeadline = 7.0;
const double _kMinDeadline  = 3.0;
const int    _kRampSamples  = 14; // samples to reach full difficulty
const int    _kBurstCount   = 18;

// ============================================================================
// Tissue model
// ============================================================================

enum _Tissue { epithelial, connective, muscle, nervous }

class _TissueMeta {
  final String label;
  final Color accent;
  final IconData icon;
  final List<String> subtypeNames;
  const _TissueMeta(this.label, this.accent, this.icon, this.subtypeNames);
}

const Map<_Tissue, _TissueMeta> _kMeta = {
  _Tissue.epithelial: _TissueMeta(
    'EPITHELIAL', _kEpiAccent, Icons.grid_view_rounded,
    ['Squamous', 'Cuboidal', 'Columnar', 'Stratified'],
  ),
  _Tissue.connective: _TissueMeta(
    'CONNECTIVE', _kConAccent, Icons.scatter_plot_rounded,
    ['Adipose (fat)', 'Bone', 'Blood', 'Areolar'],
  ),
  _Tissue.muscle: _TissueMeta(
    'MUSCLE', _kMusAccent, Icons.drag_handle_rounded,
    ['Skeletal', 'Cardiac', 'Smooth'],
  ),
  _Tissue.nervous: _TissueMeta(
    'NERVOUS', _kNerAccent, Icons.hub_rounded,
    ['Multipolar neuron', 'Neuron + glia'],
  ),
};

/// One classifiable sample: a tissue type, a subtype index, and the fact shown
/// after answering. Drawing is keyed off (tissue, subtype, seed).
class _Variant {
  final _Tissue tissue;
  final int subtype;
  final String fact;
  const _Variant(this.tissue, this.subtype, this.fact);
}

const List<_Variant> _kVariants = [
  // EPITHELIAL — packed sheets.
  _Variant(_Tissue.epithelial, 0,
      'Squamous: flat, tile-like cells line air sacs and blood vessels — thin enough for gases to slip across.'),
  _Variant(_Tissue.epithelial, 1,
      'Cuboidal: cube-shaped cells line kidney tubules and glands, built to secrete and absorb.'),
  _Variant(_Tissue.epithelial, 2,
      'Columnar: tall cells line the gut; many wear a brush border of microvilli to soak up nutrients.'),
  _Variant(_Tissue.epithelial, 3,
      'Stratified: stacked layers (your skin surface) take the abrasion so deeper layers survive.'),
  // CONNECTIVE — scattered cells in matrix.
  _Variant(_Tissue.connective, 0,
      'Adipose: each cell balloons with one oil droplet, shoving the nucleus to the rim — energy & insulation.'),
  _Variant(_Tissue.connective, 1,
      'Bone: cells sit in rings (lacunae) around a central canal; a hard mineral matrix bears your weight.'),
  _Variant(_Tissue.connective, 2,
      'Blood: a FLUID matrix (plasma) ferries red cells for oxygen and white cells for defence.'),
  _Variant(_Tissue.connective, 3,
      'Areolar: a loose web of fibres with cells scattered between — it packs and cushions around organs.'),
  // MUSCLE — parallel fibres.
  _Variant(_Tissue.muscle, 0,
      'Skeletal: long parallel fibres with cross-stripes (striations); voluntary — it moves your bones.'),
  _Variant(_Tissue.muscle, 1,
      'Cardiac: branching striated fibres joined by intercalated discs; involuntary and tireless — the heart.'),
  _Variant(_Tissue.muscle, 2,
      'Smooth: tapered spindle cells, no stripes, one central nucleus; lines gut & vessels, involuntary.'),
  // NERVOUS — neurons + glia.
  _Variant(_Tissue.nervous, 0,
      'Multipolar neuron: many dendrites radiate from the body to receive, one long axon to send.'),
  _Variant(_Tissue.nervous, 1,
      'Glia: small support cells vastly outnumber neurons, feeding and insulating them.'),
];

// ============================================================================
// Particle (inlined — modules stay self-contained)
// ============================================================================

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

enum _Answer { waiting, correct, wrong }

// ============================================================================
// Widget
// ============================================================================

class TissueTypeGame extends StatefulWidget {
  final MiniGameSession session;
  const TissueTypeGame({super.key, required this.session});

  @override
  State<TissueTypeGame> createState() => _TissueTypeGameState();
}

class _TissueTypeGameState extends State<TissueTypeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // Sample deck (every variant appears before any repeats).
  late List<_Variant> _deck;
  int _deckIdx = 0;

  late _Variant _sample;
  int _sampleId = 0;       // bumps each new sample → painter repaint key
  int _seed = 0;           // RNG seed for the current sample drawing
  double _subtlety = 0;    // 0 = obvious tells … 0.85 = faint
  double _deadline = _kBaseDeadline;

  _Answer _answer = _Answer.waiting;
  _Tissue? _tapped;
  double _sampleTime = 0;     // seconds the current sample has been visible
  double _flareTimer = 0;     // counts down the fact-flare window
  int _samplesShown = 0;

  int _streak = 0;
  int _shownMult = 1;

  final List<_Particle> _particles = [];
  Size _field = Size.zero;
  int _earnedPts = 0;

  // ----------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _deck = List<_Variant>.from(_kVariants)..shuffle(_rng);
    _loadNext();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // -- Sample management -------------------------------------------------------

  void _loadNext() {
    if (_deckIdx >= _deck.length) {
      _deck.shuffle(_rng);
      _deckIdx = 0;
    }
    _sample = _deck[_deckIdx++];
    _sampleId++;
    _seed = _rng.nextInt(1 << 30);

    final d = (_samplesShown / _kRampSamples).clamp(0.0, 1.0);
    _subtlety = d * 0.82;
    _deadline = _kBaseDeadline + (_kMinDeadline - _kBaseDeadline) * d;

    _answer = _Answer.waiting;
    _tapped = null;
    _sampleTime = 0;
    _flareTimer = 0;
  }

  // -- Game loop ---------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) _simulate(dt);
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    if (_answer == _Answer.waiting) {
      _sampleTime += dt;
      if (_sampleTime >= _deadline) _timeout();
    } else {
      _flareTimer -= dt;
      if (_flareTimer <= 0) {
        _samplesShown++;
        _loadNext();
      }
    }

    // Particles.
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  // -- Scoring -----------------------------------------------------------------

  int _speedBonus() {
    final window = _deadline * 0.6;
    final frac = (_sampleTime / window).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMult() => 1 + (_streak ~/ _kStreakStep);

  // -- Input -------------------------------------------------------------------

  void _onTap(_Tissue choice) {
    if (!widget.session.isRunning) return;
    if (_answer != _Answer.waiting) return;

    _tapped = choice;
    if (choice == _sample.tissue) {
      _answer = _Answer.correct;
      _streak++;
      final mult = _streakMult();
      _shownMult = mult;
      _earnedPts = _speedBonus() * mult;
      widget.session.addScore(_earnedPts);
      widget.session.noteStreak(_streak);
      _burst(_field.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0) {
        _burst(_field.center(Offset.zero), _kGold, count: 12);
      }
    } else {
      _answer = _Answer.wrong;
      _streak = 0;
      _shownMult = 1;
      _earnedPts = 0;
    }
    _flareTimer = _kFactFlareDuration;
  }

  void _timeout() {
    _tapped = null;
    _answer = _Answer.wrong;
    _streak = 0;
    _shownMult = 1;
    _earnedPts = 0;
    _flareTimer = _kFactFlareDuration;
  }

  void _skipFlare() {
    if (_answer == _Answer.waiting) return;
    _flareTimer = 0;
    setState(() {});
  }

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60.0 + _rng.nextDouble() * 150.0;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.5 + _rng.nextDouble() * 3.0,
        color.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // -- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            // Ambient field + particles (cheap, animated).
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientPainter(_clock, _particles),
              ),
            ),
            Positioned.fill(child: _buildPlay(constraints)),
            // Fact flare overlays the bottom so it never steals column space.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _answer != _Answer.waiting
                      ? _buildFlare()
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlay(BoxConstraints outer) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(builder: (context, c) {
        const double flareReserve = 138;
        final content = Column(
          children: [
            _buildHUD(),
            // The slide — gets the lion's share of space.
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: _buildSlide(),
              ),
            ),
            // Prompt.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'WHICH TISSUE?',
                style: Potatuhs.label(size: 12, color: _kTextSub)
                    .copyWith(letterSpacing: 2.4),
              ),
            ),
            const SizedBox(height: 8),
            // Four answer buttons (2×2).
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _buildAnswers(),
              ),
            ),
            SizedBox(height: _answer != _Answer.waiting ? flareReserve : 0),
          ],
        );

        final bool tooShort = c.maxHeight < 480;
        if (tooShort) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 480,
                maxHeight: math.max(480, c.maxHeight),
              ),
              child: content,
            ),
          );
        }
        return content;
      }),
    );
  }

  // -- HUD ---------------------------------------------------------------------

  Widget _buildHUD() {
    final score = widget.session.score;
    final remaining = widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths = (remaining.inMilliseconds / 100).floor() % 10;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD1000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        children: [
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextPri,
              shadows: [Shadow(color: _kNerAccent, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          if (_streak >= _kStreakStep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _kGold.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                '×$_shownMult',
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
              color: secs < 5 ? _kBadRed : _kTextPri.withValues(alpha: 0.82),
              shadows: secs < 5
                  ? const [Shadow(color: _kBadRed, blurRadius: 10)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -- Slide -------------------------------------------------------------------

  Widget _buildSlide() {
    // Reveal frame colour: green on correct, red on wrong, neutral while waiting.
    Color frame = _kCardBorder;
    if (_answer == _Answer.correct) frame = _kGoodGreen.withValues(alpha: 0.85);
    if (_answer == _Answer.wrong) frame = _kBadRed.withValues(alpha: 0.85);

    final deadlineFrac =
        (1.0 - (_sampleTime / _deadline)).clamp(0.0, 1.0);
    final barColor = deadlineFrac < 0.3 ? _kBadRed : _kMembrane;

    return Container(
      decoration: BoxDecoration(
        color: _kSlide,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: frame, width: 2),
        boxShadow: _answer == _Answer.correct
            ? [BoxShadow(color: _kGoodGreen.withValues(alpha: 0.25), blurRadius: 18)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The procedurally-drawn sample — isolated so it only repaints
            // when the sample id changes.
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SamplePainter(
                    tissue: _sample.tissue,
                    subtype: _sample.subtype,
                    seed: _seed,
                    subtlety: _subtlety,
                    sampleId: _sampleId,
                  ),
                ),
              ),
            ),
            // Per-sample deadline bar across the top (only while waiting).
            if (_answer == _Answer.waiting)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: deadlineFrac,
                  child: Container(height: 4, color: barColor),
                ),
              ),
            // Scope label.
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '40× H&E',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _kTextSub.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Answers -----------------------------------------------------------------

  Widget _buildAnswers() {
    const types = _Tissue.values;
    return LayoutBuilder(builder: (context, c) {
      const spacing = 10.0;
      final cellW = (c.maxWidth - spacing) / 2;
      double aspect = 2.1;
      if (c.maxHeight.isFinite && c.maxHeight > 0) {
        final cellH = (c.maxHeight - spacing) / 2;
        if (cellH > 0) aspect = (cellW / cellH).clamp(1.4, 3.2);
      }
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspect,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: types.map(_buildTypeButton).toList(),
      );
    });
  }

  Widget _buildTypeButton(_Tissue t) {
    final meta = _kMeta[t]!;
    final answered = _answer != _Answer.waiting;
    final isCorrect = t == _sample.tissue;
    final isTapped = t == _tapped;

    Color border = meta.accent.withValues(alpha: 0.55);
    Color bg = _kCardBg;
    Color fg = _kTextPri;
    Color iconC = meta.accent;

    if (answered) {
      if (isCorrect) {
        border = _kGoodGreen.withValues(alpha: 0.9);
        bg = _kGoodGreen.withValues(alpha: 0.12);
        fg = _kGoodGreen;
        iconC = _kGoodGreen;
      } else if (isTapped) {
        border = _kBadRed.withValues(alpha: 0.9);
        bg = _kBadRed.withValues(alpha: 0.10);
        fg = _kBadRed;
        iconC = _kBadRed;
      } else {
        border = _kCardBorder.withValues(alpha: 0.4);
        fg = _kTextSub;
        iconC = _kTextSub.withValues(alpha: 0.7);
      }
    }

    return GestureDetector(
      onTap: () => _onTap(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.6),
          boxShadow: answered && isCorrect
              ? [BoxShadow(color: _kGoodGreen.withValues(alpha: 0.22), blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(meta.icon, size: 18, color: iconC),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  meta.label,
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
    final correct = _answer == _Answer.correct;
    final meta = _kMeta[_sample.tissue]!;
    final subName = meta.subtypeNames[_sample.subtype];
    final header = correct
        ? (_shownMult > 1
            ? '+$_earnedPts  ×$_shownMult streak!'
            : '+$_earnedPts')
        : (_tapped == null
            ? 'Time! — ${meta.label} · $subName'
            : '${meta.label} · $subName');

    return GestureDetector(
      onTap: _skipFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_sampleId),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : meta.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct
                ? _kGoodGreen.withValues(alpha: 0.55)
                : _kBadRed.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              header,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: correct ? _kGoodGreen : _kBadRed,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _sample.fact,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                color: _kTextSub,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TAP TO CONTINUE',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: meta.accent.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: meta.accent.withValues(alpha: 0.75)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Ambient background + particles (cheap, animates every frame)
// ============================================================================

class _AmbientPainter extends CustomPainter {
  final double clock;
  final List<_Particle> particles;
  const _AmbientPainter(this.clock, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // Two slow stain-coloured orbs for depth.
    final t = clock * 0.2;
    final o1 = Offset(size.width * (0.18 + 0.07 * math.cos(t)),
        size.height * (0.74 + 0.05 * math.sin(t * 0.7)));
    canvas.drawCircle(
      o1,
      size.width * 0.30,
      Paint()
        ..color = _kMembrane.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
    );
    final o2 = Offset(size.width * (0.84 + 0.05 * math.cos(t * 1.2 + 1)),
        size.height * (0.30 + 0.06 * math.sin(t * 0.9 + 2)));
    canvas.drawCircle(
      o2,
      size.width * 0.22,
      Paint()
        ..color = _kNuc.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
    );

    for (final p in particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * a,
        Paint()..color = p.color.withValues(alpha: p.color.a * a),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => true;
}

// ============================================================================
// Sample painter — the procedurally-drawn histology slide.
// Deterministic from `seed`; repaints ONLY when `sampleId` changes.
// ============================================================================

class _SamplePainter extends CustomPainter {
  final _Tissue tissue;
  final int subtype;
  final int seed;
  final double subtlety; // 0 obvious … ~0.82 faint
  final int sampleId;

  const _SamplePainter({
    required this.tissue,
    required this.subtype,
    required this.seed,
    required this.subtlety,
    required this.sampleId,
  });

  /// Tell strength fades as samples get subtler.
  double get _str => (1.0 - subtlety * 0.7).clamp(0.3, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    // Faint slide wash.
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _kFiber.withValues(alpha: 0.025));
    switch (tissue) {
      case _Tissue.epithelial:
        _epithelial(canvas, size, rng);
        break;
      case _Tissue.connective:
        _connective(canvas, size, rng);
        break;
      case _Tissue.muscle:
        _muscle(canvas, size, rng);
        break;
      case _Tissue.nervous:
        _nervous(canvas, size, rng);
        break;
    }
  }

  // -- EPITHELIAL: cells packed edge-to-edge into a sheet ----------------------
  void _epithelial(Canvas canvas, Size size, math.Random rng) {
    int cols, rows;
    switch (subtype) {
      case 0: cols = 5; rows = 4; break;  // squamous — wide & flat
      case 1: cols = 5; rows = 5; break;  // cuboidal — square
      case 2: cols = 9; rows = 2; break;  // columnar — tall
      default: cols = 7; rows = 7;        // stratified — many small layers
    }
    final cw = size.width / cols;
    final ch = size.height / rows;
    // Subtler samples loosen the packing a touch (less obviously a sheet).
    final inset = 1.0 + subtlety * 3.5;

    final fill = Paint()..color = _kCyto.withValues(alpha: 0.55 * _str);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kMembrane.withValues(alpha: 0.85 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.9 * _str);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final jx = (rng.nextDouble() - 0.5) * cw * 0.08;
        final jy = (rng.nextDouble() - 0.5) * ch * 0.08;
        final rect = Rect.fromLTWH(
          c * cw + inset + jx,
          r * ch + inset + jy,
          cw - inset * 2,
          ch - inset * 2,
        );
        final rr = RRect.fromRectAndRadius(
            rect, Radius.circular(math.min(cw, ch) * 0.18));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, edge);
        // Nucleus: centred, but near the base for columnar.
        final ny = subtype == 2
            ? rect.bottom - rect.height * 0.28
            : rect.center.dy;
        canvas.drawCircle(
          Offset(rect.center.dx, ny),
          math.min(cw, ch) * 0.16,
          nuc,
        );
      }
    }
  }

  // -- CONNECTIVE: few cells scattered in a big matrix -------------------------
  void _connective(Canvas canvas, Size size, math.Random rng) {
    switch (subtype) {
      case 0:
        _adipose(canvas, size, rng);
        break;
      case 1:
        _bone(canvas, size, rng);
        break;
      case 2:
        _blood(canvas, size, rng);
        break;
      default:
        _areolar(canvas, size, rng);
    }
  }

  void _adipose(Canvas canvas, Size size, math.Random rng) {
    // Soap-bubble vacuoles: big thin-rimmed circles, nucleus shoved to the rim.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kMembrane.withValues(alpha: 0.85 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.9 * _str);
    final cols = 4, rows = 3;
    final cw = size.width / cols, ch = size.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cw + cw * 0.5 + (rng.nextDouble() - 0.5) * cw * 0.2;
        final cy = r * ch + ch * 0.5 + (rng.nextDouble() - 0.5) * ch * 0.2;
        final rad = math.min(cw, ch) * (0.42 + rng.nextDouble() * 0.06);
        canvas.drawCircle(Offset(cx, cy), rad, rim);
        final na = rng.nextDouble() * math.pi * 2;
        canvas.drawCircle(
          Offset(cx + math.cos(na) * rad * 0.86,
              cy + math.sin(na) * rad * 0.86),
          rad * 0.14,
          nuc,
        );
      }
    }
  }

  void _bone(Canvas canvas, Size size, math.Random rng) {
    // Osteon: concentric rings around a central canal, lacunae along rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kMembrane.withValues(alpha: 0.7 * _str);
    final canal = Paint()..color = _kCyto.withValues(alpha: 0.6 * _str);
    final lac = Paint()..color = _kNuc.withValues(alpha: 0.85 * _str);
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxR = math.min(size.width, size.height) * 0.46;
    canvas.drawCircle(center, maxR * 0.16, canal);
    for (var i = 1; i <= 5; i++) {
      final rad = maxR * (0.18 + i * 0.16);
      canvas.drawCircle(center, rad, ring);
      final n = 6 + i;
      for (var k = 0; k < n; k++) {
        final a = (k / n) * math.pi * 2 + rng.nextDouble() * 0.3;
        // Lacunae: short almond dashes.
        canvas.drawCircle(
          Offset(center.dx + math.cos(a) * rad, center.dy + math.sin(a) * rad),
          2.4,
          lac,
        );
      }
    }
  }

  void _blood(Canvas canvas, Size size, math.Random rng) {
    // Fluid matrix: many red discs (biconcave: ring with pale centre) + a few
    // larger white cells with lobed nuclei.
    final discFill = Paint()..color = _kFiber.withValues(alpha: 0.55 * _str);
    final discCtr = Paint()..color = _kSlide.withValues(alpha: 0.9);
    final wbcFill = Paint()..color = _kCyto.withValues(alpha: 0.5 * _str);
    final wbcNuc = Paint()..color = _kNuc.withValues(alpha: 0.9 * _str);
    final n = (26 * _str).round() + 8;
    for (var i = 0; i < n; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final rad = size.shortestSide * 0.055;
      canvas.drawCircle(Offset(cx, cy), rad, discFill);
      canvas.drawCircle(Offset(cx, cy), rad * 0.45, discCtr);
    }
    for (var i = 0; i < 3; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final rad = size.shortestSide * 0.085;
      canvas.drawCircle(Offset(cx, cy), rad, wbcFill);
      // Lobed nucleus = a couple of overlapping blobs.
      for (var k = 0; k < 3; k++) {
        final a = k * 2.1;
        canvas.drawCircle(
          Offset(cx + math.cos(a) * rad * 0.4, cy + math.sin(a) * rad * 0.4),
          rad * 0.45,
          wbcNuc,
        );
      }
    }
  }

  void _areolar(Canvas canvas, Size size, math.Random rng) {
    // Loose web of wavy fibres + a few scattered spindle cells.
    final fiber = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = _kFiber.withValues(alpha: 0.55 * _str);
    final fibreCount = (12 * _str).round() + 5;
    for (var i = 0; i < fibreCount; i++) {
      final path = Path();
      final y = rng.nextDouble() * size.height;
      path.moveTo(0, y);
      var cx = 0.0;
      var cy = y;
      while (cx < size.width) {
        final nx = cx + size.width * 0.2;
        final ny = cy + (rng.nextDouble() - 0.5) * size.height * 0.3;
        path.quadraticBezierTo(
            cx + size.width * 0.1, cy + (rng.nextDouble() - 0.5) * 40, nx, ny);
        cx = nx;
        cy = ny;
      }
      canvas.drawPath(path, fiber);
    }
    final cellFill = Paint()..color = _kCyto.withValues(alpha: 0.5 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.85 * _str);
    for (var i = 0; i < 6; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final rad = size.shortestSide * 0.05;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rad * 2.6, height: rad),
        cellFill,
      );
      canvas.drawCircle(Offset(cx, cy), rad * 0.4, nuc);
    }
  }

  // -- MUSCLE: long parallel fibres --------------------------------------------
  void _muscle(Canvas canvas, Size size, math.Random rng) {
    if (subtype == 2) {
      _smoothMuscle(canvas, size, rng);
      return;
    }
    final fibres = 6;
    final fh = size.height / fibres;
    final fill = Paint()..color = _kCyto.withValues(alpha: 0.5 * _str);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _kMembrane.withValues(alpha: 0.7 * _str);
    final stria = Paint()
      ..strokeWidth = 1.0
      ..color = _kMembrane.withValues(alpha: 0.5 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.9 * _str);
    final disc = Paint()
      ..strokeWidth = 2.4
      ..color = _kMembrane.withValues(alpha: 0.9 * _str);

    for (var f = 0; f < fibres; f++) {
      final top = f * fh + fh * 0.12;
      final h = fh * 0.76;
      final rect = Rect.fromLTWH(-4, top, size.width + 8, h);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.4));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, edge);
      // Striations: vertical cross-stripes (both skeletal & cardiac).
      final step = size.width / (18 - (subtlety * 8).round());
      for (var x = step * 0.5; x < size.width; x += step) {
        canvas.drawLine(Offset(x, top + 1), Offset(x, top + h - 1), stria);
      }
      if (subtype == 0) {
        // Skeletal: nuclei pushed to the fibre edge.
        for (var k = 0; k < 3; k++) {
          final nx = size.width * (0.2 + k * 0.3) +
              (rng.nextDouble() - 0.5) * 30;
          canvas.drawCircle(Offset(nx, top + 3.5), 3.2, nuc);
        }
      } else {
        // Cardiac: central nucleus + intercalated discs (thick cross lines).
        canvas.drawCircle(
            Offset(size.width * (0.3 + rng.nextDouble() * 0.4), top + h * 0.5),
            3.6, nuc);
        final dx = size.width * (0.4 + rng.nextDouble() * 0.3);
        canvas.drawLine(Offset(dx, top), Offset(dx, top + h), disc);
      }
    }
  }

  void _smoothMuscle(Canvas canvas, Size size, math.Random rng) {
    // Stacked spindle (tapered) cells, single central nucleus, no striations.
    final fill = Paint()..color = _kCyto.withValues(alpha: 0.5 * _str);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _kMembrane.withValues(alpha: 0.75 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.9 * _str);
    final rows = 5;
    final rh = size.height / rows;
    for (var r = 0; r < rows; r++) {
      final cy = r * rh + rh * 0.5;
      final off = (r.isEven ? 0.0 : size.width * 0.12);
      for (var c = -1; c < 3; c++) {
        final cx = off + c * size.width * 0.4 + size.width * 0.25;
        final w = size.width * 0.42;
        final h = rh * 0.62;
        final path = Path();
        path.moveTo(cx - w / 2, cy);
        path.quadraticBezierTo(cx - w * 0.1, cy - h / 2, cx + w / 2, cy);
        path.quadraticBezierTo(cx - w * 0.1, cy + h / 2, cx - w / 2, cy);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, edge);
        canvas.drawCircle(Offset(cx, cy), h * 0.22, nuc);
      }
    }
  }

  // -- NERVOUS: star-shaped cell bodies trailing branching processes -----------
  void _nervous(Canvas canvas, Size size, math.Random rng) {
    // Scattered glial dots (more emphasised in subtype 1).
    final glia = Paint()..color = _kNuc.withValues(alpha: 0.5 * _str);
    final gliaCount = subtype == 1 ? 40 : 22;
    for (var i = 0; i < gliaCount; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.6 + rng.nextDouble() * 1.4,
        glia,
      );
    }

    final neuronCount = subtype == 1 ? 2 : 3;
    final dendrite = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = _kMembrane.withValues(alpha: 0.8 * _str);
    final body = Paint()..color = _kCyto.withValues(alpha: 0.6 * _str);
    final nuc = Paint()..color = _kNuc.withValues(alpha: 0.95 * _str);

    for (var i = 0; i < neuronCount; i++) {
      final cx = size.width * (0.25 + rng.nextDouble() * 0.5);
      final cy = size.height * (0.25 + rng.nextDouble() * 0.5);
      final r = size.shortestSide * 0.07;
      final branches = 5 + rng.nextInt(3);
      // Dendrites: radiate and fork once.
      for (var b = 0; b < branches; b++) {
        final a = (b / branches) * math.pi * 2 + rng.nextDouble() * 0.4;
        final len = r * (2.4 + rng.nextDouble() * 1.6);
        final ex = cx + math.cos(a) * len;
        final ey = cy + math.sin(a) * len;
        canvas.drawLine(Offset(cx, cy), Offset(ex, ey), dendrite);
        // One fork near the tip.
        final fa = a + (rng.nextDouble() - 0.5) * 1.0;
        canvas.drawLine(
          Offset(ex, ey),
          Offset(ex + math.cos(fa) * len * 0.5,
              ey + math.sin(fa) * len * 0.5),
          dendrite,
        );
      }
      // Star-polygon cell body.
      final star = Path();
      final pts = 7;
      for (var k = 0; k <= pts; k++) {
        final a = (k / pts) * math.pi * 2;
        final rr = r * (0.78 + (k.isEven ? 0.32 : 0.0));
        final x = cx + math.cos(a) * rr;
        final y = cy + math.sin(a) * rr;
        if (k == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      star.close();
      canvas.drawPath(star, body);
      canvas.drawPath(star, dendrite);
      canvas.drawCircle(Offset(cx, cy), r * 0.42, nuc);
    }
  }

  @override
  bool shouldRepaint(_SamplePainter old) =>
      old.sampleId != sampleId || old.subtlety != subtlety;
}
