import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Cosmic Timeline v2 — INSERT THE EPOCH (UX-passed alternative to
/// `cosmic_timeline`).
///
/// Same lesson — order the epochs of the universe (Big Bang → now), learn the
/// real "when" of each, and feel deep-time on a logarithmic ribbon — rebuilt as
/// a fast, accelerating, large-target conveyor instead of a one-shot drag race.
///
/// Why v2 (per the teardown):
///  • **Variety, not one rote sequence.** The v1 always sorted the SAME 11
///    ranked epochs into the SAME order, so once memorized it collapsed to drag
///    speed. v2 draws from an 18-epoch catalog and shows a *moving window* of a
///    few placed cards; you must judge where ONE incoming epoch fits *relative
///    to the cards currently visible* — a different decision every time.
///  • **Legible, thumb-sized targets.** v1 crammed up to 11 draggable cards down
///    to ~30px. v2 caps the rail to a handful of large cards and you TAP THE GAP
///    where the epoch belongs — the tap bucket is a full rail-band-tall zone,
///    never a 30px grab.
///  • **It accelerates.** Difficulty is a tightening per-card timer + a final
///    CASCADE, not longer rows. The round builds to a frantic finish.
///
/// Kept from v1 (the good parts): teal flow on a correct, in-order rail; a RED
/// SNAP arrow that points from your wrong gap to the right one; the revealed
/// "when" + one-line fact on placement; and the logarithmic deep-time ribbon —
/// here fed continuously as epochs scroll off the rail and "lock" onto it.
///
/// The host (MiniGameHost) owns the clock, the 3-2-1 countdown, the score HUD
/// and results; pacing reads `session.remaining`. This widget renders ONLY the
/// play area and reports points via `session.addScore` / `session.noteStreak`.
/// One Ticker → one CustomPainter; taps mutate state, the ticker repaints.
class CosmicTimelineV2Game extends StatefulWidget {
  final MiniGameSession session;
  const CosmicTimelineV2Game({super.key, required this.session});

  @override
  State<CosmicTimelineV2Game> createState() => _CosmicTimelineV2GameState();
}

// ── Epoch catalog (18, strictly chronological) ───────────────────────────────

enum _EpochId {
  bigBang,
  planck,
  inflation,
  quarkSoup,
  nuclei,
  recombination,
  darkAges,
  firstStars,
  firstGalaxies,
  reionization,
  cosmicNoon,
  sun,
  lifeEarth,
  cambrian,
  dinosaurs,
  dinoEnd,
  humans,
  now,
}

class _Epoch {
  final int rank; // canonical chronological position (earliest = 0)
  final String name;
  final String abbrev;
  final String emoji;
  final Color color;
  final String when; // revealed timestamp label
  final double tSec; // seconds AFTER the Big Bang, for log-time plotting
  final String fact; // one-line education shown on placement
  const _Epoch(this.rank, this.name, this.abbrev, this.emoji, this.color,
      this.when, this.tSec, this.fact);
}

// Seconds-after-Big-Bang for each epoch (standard cosmology approximations;
// 1 yr ≈ 3.156e7 s). Values are monotonic in rank — the load-bearing education.
const Map<_EpochId, _Epoch> _kEpochs = {
  _EpochId.bigBang: _Epoch(0, 'Big Bang', 'BANG', '💥', Color(0xFFFFD54F),
      't = 0', 0, 'Space, time and energy erupt from a hot, dense state.'),
  _EpochId.planck: _Epoch(1, 'Planck Epoch', 'PLANCK', '⏱️', Color(0xFFFFCA28),
      '10⁻⁴³ s', 1e-43,
      'Gravity splits from the other forces — the earliest instant physics can describe.'),
  _EpochId.inflation: _Epoch(2, 'Inflation', 'INFL', '🎈', Color(0xFFFF8A65),
      '10⁻³² s', 1e-32,
      'The universe doubles in size dozens of times in a flash, smoothing it out.'),
  _EpochId.quarkSoup: _Epoch(3, 'Quark Soup', 'QUARK', '🍲', Color(0xFFEF5350),
      '10⁻⁶ s', 1e-6,
      'Too hot for protons: a plasma of free quarks and gluons fills everything.'),
  _EpochId.nuclei: _Epoch(4, 'First Nuclei', 'NUCLEI', '⚛️', Color(0xFFBA68C8),
      '3 min', 180,
      'Protons and neutrons fuse into the first hydrogen and helium nuclei.'),
  _EpochId.recombination: _Epoch(5, 'CMB / Recombination', 'CMB', '📡',
      Color(0xFF7986CB), '380,000 yrs', 1.2e13,
      'Nuclei grab electrons into atoms; light breaks free as the cosmic microwave background.'),
  _EpochId.darkAges: _Epoch(6, 'Dark Ages', 'DARK', '🌑', Color(0xFF546E7A),
      '~100 Myr', 3.15e15,
      'No stars yet — only cooling hydrogen gas drifting in the dark.'),
  _EpochId.firstStars: _Epoch(7, 'First Stars', 'STARS', '⭐', Color(0xFF4FC3F7),
      '~200 Myr', 6.3e15,
      'Gravity ignites the first stars, flooding the cosmos with light.'),
  _EpochId.firstGalaxies: _Epoch(8, 'First Galaxies', 'GALAXY', '🌌',
      Color(0xFF9575CD), '~400 Myr', 1.26e16,
      'Stars gather by the billions into the first galaxies.'),
  _EpochId.reionization: _Epoch(9, 'Reionization', 'REION', '🔆',
      Color(0xFF4DB6AC), '~1 Gyr', 3.15e16,
      'Starlight re-ionizes the hydrogen fog; the universe turns transparent.'),
  _EpochId.cosmicNoon: _Epoch(10, 'Cosmic Noon', 'NOON', '🌟', Color(0xFF26C6DA),
      '~3.3 Gyr', 1.04e17,
      'Peak star formation — galaxies build stars faster than at any time since.'),
  _EpochId.sun: _Epoch(11, 'Our Sun Forms', 'SUN', '☀️', Color(0xFFFFB300),
      '~9.2 Gyr', 2.9e17,
      'A cloud collapses into the Sun and its planets, including Earth.'),
  _EpochId.lifeEarth: _Epoch(12, 'Life on Earth', 'LIFE', '🦠',
      Color(0xFF66BB6A), '~10 Gyr', 3.15e17,
      'The first single-celled life appears in Earth\'s young oceans.'),
  _EpochId.cambrian: _Epoch(13, 'Cambrian Explosion', 'CAMBR', '🐚',
      Color(0xFF26A69A), '~13.2 Gyr', 4.18e17,
      'The seas fill with complex animals in a burst of new body plans.'),
  _EpochId.dinosaurs: _Epoch(14, 'Dinosaurs Reign', 'DINO', '🦕',
      Color(0xFF8D6E63), '~13.6 Gyr', 4.30e17,
      'Dinosaurs rule the land for over 150 million years.'),
  _EpochId.dinoEnd: _Epoch(15, 'Dinosaurs End', 'IMPACT', '☄️',
      Color(0xFFFF7043), '~13.73 Gyr', 4.335e17,
      'An asteroid ends the dinosaurs; mammals inherit the Earth.'),
  _EpochId.humans: _Epoch(16, 'First Humans', 'HUMAN', '🧑', Color(0xFFFFA726),
      '~13.8 Gyr', 4.349e17,
      'Modern humans appear — a blink ago on the cosmic clock.'),
  _EpochId.now: _Epoch(17, 'Now', 'NOW', '🪐', Color(0xFF4DD0E1), '13.8 Gyr',
      4.35e17, 'You, reading this — 13.8 billion years after it all began.'),
};

_Epoch _epoch(_EpochId id) => _kEpochs[id]!;

// Log-time bounds for the deep-time ribbon. log10(tSec) spans Planck (-43) to
// now (~17.6); the Big Bang (t=0) is pinned to the far left.
const double _kLogLo = -44.0;
const double _kLogHi = 18.0;

double _logFrac(double tSec) {
  if (tSec <= 0) return 0.0; // Big Bang pinned left
  final l = (math.log(tSec) / math.ln10).clamp(_kLogLo, _kLogHi);
  return ((l - _kLogLo) / (_kLogHi - _kLogLo)).clamp(0.0, 1.0);
}

bool _ok(double v) => v.isFinite;

// ── Mutable play objects ─────────────────────────────────────────────────────

/// A card flying from the incoming slot into its rail gap (juice on resolve).
class _Fly {
  final _EpochId epoch;
  final double fromX, fromY, toX, toY;
  final bool good;
  double age = 0;
  _Fly(this.epoch, this.fromX, this.fromY, this.toX, this.toY, this.good);
}

/// An epoch that scrolled off the rail and locked onto the deep-time ribbon.
class _Locked {
  final _EpochId epoch;
  double age = 0;
  _Locked(this.epoch);
}

// ── State ────────────────────────────────────────────────────────────────────

class _CosmicTimelineV2GameState extends State<CosmicTimelineV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final math.Random _rng;

  double _lastT = 0;
  double _clock = 0; // animation/drift clock only

  // Conveyor.
  static const int _maxRail = 5;
  static const int _seedRail = 3;
  List<_EpochId> _rail = []; // always sorted ascending by rank
  List<_EpochId> _queue = []; // upcoming draws (pop from end)
  _EpochId? _incoming; // the card awaiting placement
  _Fly? _fly; // resolving card in flight
  int _pendingGap = 0; // gap index the flying card commits into
  final List<_Locked> _locked = []; // epochs plotted on the ribbon

  // Per-card timer (the accelerating pressure).
  double _cardTimer = 0;
  double _cardTimerMax = 6;

  int _streak = 0;
  int _placed = 0; // total resolved (for the per-card index label)

  // Layout (recomputed each build).
  Size _sz = Size.zero;
  double _railY = 0;
  double _cardW = 84, _cardH = 96;
  List<double> _railCenters = const [];
  double _incX = 0, _incY = 0;

  // Fact card.
  String _factText = '';
  Color _factColor = Colors.white;
  double _factAge = 99;

  // Juice.
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _wrongFromX = 0, _wrongToX = 0;
  double _ribbonGlow = 0;

  static const Color _accent = Color(0xFF7C4DFF); // deep cosmic violet
  static const Color _good = Color(0xFF80D8FF);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _rng = math.Random(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _seed();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Conveyor setup ───────────────────────────────────────────────────────────

  void _seed() {
    final pool = _EpochId.values.toList()..shuffle(_rng);
    final seed = pool.take(_seedRail).toList()
      ..sort((a, b) => _epoch(a).rank.compareTo(_epoch(b).rank));
    _rail = seed;
    _queue = pool.skip(_seedRail).toList();
    _drawNext();
  }

  void _refillQueue() {
    final onRail = _rail.toSet();
    _queue = _EpochId.values
        .where((e) => !onRail.contains(e) && e != _incoming)
        .toList()
      ..shuffle(_rng);
  }

  void _drawNext() {
    if (_queue.isEmpty) _refillQueue();
    if (_queue.isEmpty) {
      _incoming = null;
      return;
    }
    _incoming = _queue.removeLast();
    _setTimerForNew();
  }

  void _setTimerForNew() {
    final total = widget.session.spec.durationSeconds.toDouble();
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    final progress = total > 0 ? (1 - remain / total).clamp(0.0, 1.0) : 0.0;
    var base = 6.0 + (2.8 - 6.0) * progress; // 6s early → 2.8s late
    if (_cascade) base *= 0.7; // CASCADE: ~30% tighter
    _cardTimerMax = base;
    _cardTimer = base;
  }

  bool get _cascade {
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return remain > 0 && remain <= 12;
  }

  int _correctGapFor(_EpochId e) {
    final r = _epoch(e).rank;
    var g = 0;
    for (final c in _rail) {
      if (_epoch(c).rank < r) g++;
    }
    return g;
  }

  // ── Tick ─────────────────────────────────────────────────────────────────────

  void _onTick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    _clock += dt;

    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_factAge < 99) _factAge += dt;
    if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 1.6).clamp(0.0, 1.0);
    if (_ribbonGlow > 0) _ribbonGlow = (_ribbonGlow - dt * 1.0).clamp(0.0, 1.0);
    for (final l in _locked) {
      l.age += dt;
    }

    // Advance a resolving card in flight.
    if (_fly != null) {
      _fly!.age += dt;
      if (_fly!.age >= 0.3) _commitFly();
    }

    if (!widget.session.isRunning) return;

    // Tighten the per-card clock; timeout = a forced miss.
    if (_incoming != null && _fly == null) {
      _cardTimer -= dt;
      if (_cardTimer <= 0) _resolve(null);
    }
  }

  // ── Placement / scoring ──────────────────────────────────────────────────────

  void _showFact(_EpochId e) {
    final ep = _epoch(e);
    _factText = '${ep.name} (${ep.when}) — ${ep.fact}';
    _factColor = ep.color;
    _factAge = 0;
  }

  double _gapX(int gap) {
    if (_railCenters.isEmpty) return _sz.width / 2;
    if (gap <= 0) return _railCenters.first - _cardW * 0.7;
    if (gap >= _railCenters.length) {
      return _railCenters.last + _cardW * 0.7;
    }
    return (_railCenters[gap - 1] + _railCenters[gap]) / 2;
  }

  /// Resolve the current incoming card. [gapTapped] null = the timer ran out.
  /// Either way the card is then *inserted correctly* (so the rail stays a valid
  /// ordered window and the player still learns its place); only scoring differs.
  void _resolve(int? gapTapped) {
    final inc = _incoming;
    if (inc == null || _fly != null) return;
    final correctGap = _correctGapFor(inc);
    final correct = gapTapped != null && gapTapped == correctGap;
    final ep = _epoch(inc);

    if (correct) {
      _streak++;
      widget.session.noteStreak(_streak);
      final speedFrac = (_cardTimer / _cardTimerMax).clamp(0.0, 1.0);
      final speedBonus = (speedFrac * 18).round();
      final mult = 1 + math.min(_streak, 10) * 0.06; // capped ×1.6, no runaway
      final pts = ((22 + speedBonus) * mult).round();
      widget.session.addScore(pts);
      final at = Offset(_gapX(correctGap), _railY);
      _fx.addAll(FxBurst.spawn(at, ep.color, count: 12));
      _pops.add(FxPop(at.translate(0, -30), '+$pts', _good));
    } else {
      _streak = 0;
      if (gapTapped != null) {
        // RED SNAP: show where it should have gone.
        _wrongFromX = _gapX(gapTapped);
        _wrongToX = _gapX(correctGap);
        _wrongFlash = 1.0;
        _pops.add(FxPop(Offset(_gapX(gapTapped), _railY - 36), 'WRONG GAP',
            const Color(0xFFFF5252)));
      } else {
        _wrongFlash = 0.7;
        _pops.add(FxPop(Offset(_incX, _incY - 30), 'TOO SLOW',
            const Color(0xFFFFB74D)));
      }
    }

    // Fly the card to its correct gap, then commit it there.
    _pendingGap = correctGap;
    final to = Offset(_gapX(correctGap), _railY);
    _fly = _Fly(inc, _incX, _incY, to.dx, to.dy, correct);
    _incoming = null;
    _showFact(inc);
    _placed++;
  }

  void _commitFly() {
    final f = _fly;
    _fly = null;
    if (f == null) return;
    final idx = _pendingGap.clamp(0, _rail.length);
    _rail.insert(idx, f.epoch);
    // Cap the rail to keep targets large; the oldest epoch locks to the ribbon.
    if (_rail.length > _maxRail) {
      var pop = 0;
      if (pop == idx) pop = 1; // never pop the card we just placed
      final off = _rail.removeAt(pop);
      _locked.add(_Locked(off));
      if (_locked.length > 40) _locked.removeAt(0);
      _ribbonGlow = 1.0;
      if (widget.session.isRunning) widget.session.addScore(8); // survival
    }
    _drawNext();
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  void _onTapUp(Offset p) {
    if (!widget.session.isRunning || _incoming == null || _fly != null) {
      // Outside play, let a tap on a rail card re-teach its fact.
      _maybeShowRailFact(p);
      return;
    }
    final inBand = (p.dy - _railY).abs() <= _cardH * 0.85 + 18;
    if (!inBand) {
      _maybeShowRailFact(p);
      return;
    }
    // Map the tap to an insertion gap: the count of card centers left of it.
    var gap = 0;
    for (final cx in _railCenters) {
      if (cx < p.dx) gap++;
    }
    setState(() => _resolve(gap));
  }

  void _maybeShowRailFact(Offset p) {
    for (var i = 0; i < _railCenters.length; i++) {
      if ((p - Offset(_railCenters[i], _railY)).distance < _cardW * 0.6) {
        setState(() => _showFact(_rail[i]));
        return;
      }
    }
  }

  // ── Layout ───────────────────────────────────────────────────────────────────

  void _computeLayout(double w, double h) {
    _railY = h * 0.70;
    _incX = w / 2;
    _incY = h * 0.42;
    final n = _rail.length.clamp(1, _maxRail);
    const gap = 10.0;
    final avail = w - 24;
    _cardW = ((avail - gap * (n - 1)) / n).clamp(48.0, 104.0);
    _cardH = (_cardW * 1.12).clamp(54.0, 116.0);
    final totalW = _cardW * n + gap * (n - 1);
    final startX = (w - totalW) / 2 + _cardW / 2;
    _railCenters = [for (var i = 0; i < n; i++) startX + i * (_cardW + gap)];
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth, h = box.maxHeight;
      _sz = Size(w, h);
      _computeLayout(w, h);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _TimelinePainter(repaint: _ticker, state: this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _TimelinePainter extends CustomPainter {
  final _CosmicTimelineV2GameState s;
  _TimelinePainter(
      {required Listenable repaint, required _CosmicTimelineV2GameState state})
      : s = state,
        super(repaint: repaint);

  static const Color _accent = _CosmicTimelineV2GameState._accent;
  static const Color _good = _CosmicTimelineV2GameState._good;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cascade = s._cascade;
    GameFx.atmosphere(canvas, size, cascade ? const Color(0xFFFF5C8A) : _accent,
        s._clock, motes: cascade ? 44 : 30);

    if (s._wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFFFF5252)
                .withValues(alpha: s._wrongFlash * 0.14));
    }

    _drawHeader(canvas, size, cascade);
    _drawRibbon(canvas, size);
    _drawRail(canvas, size);
    _drawWrongSnap(canvas);
    _drawIncoming(canvas, size, cascade);
    _drawFly(canvas);
    _drawFactCard(canvas, size);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  void _drawHeader(Canvas canvas, Size size, bool cascade) {
    final goal = cascade
        ? 'CASCADE — TAP THE GAP, FAST!'
        : 'TAP THE GAP WHERE THE EPOCH FITS';
    GameFx.text(canvas, goal, Offset(size.width / 2, 14), 11,
        cascade
            ? const Color(0xFFFF8AB0)
            : Colors.white.withValues(alpha: 0.55),
        weight: FontWeight.w700, glow: cascade ? 0.5 : 0);
    GameFx.text(canvas, 'EARLIEST  ◀  RAIL  ▶  LATEST',
        Offset(size.width / 2, 31), 9, Colors.white.withValues(alpha: 0.32));
    GameFx.text(canvas, 'PLACED ${s._placed}', Offset(size.width - 42, 16), 10,
        _accent.withValues(alpha: 0.85), weight: FontWeight.w700);
  }

  // The logarithmic deep-time ribbon: every epoch that scrolled off the rail is
  // plotted at its log(time-since-Big-Bang). Early epochs spread left; the recent
  // billions of years cram right — the universe's first second is "as long" as eons.
  void _drawRibbon(Canvas canvas, Size size) {
    final y = size.height * 0.20;
    final left = 16.0, right = size.width - 16.0;
    final axis = Paint()
      ..shader = LinearGradient(colors: [
        _accent.withValues(alpha: 0.25),
        _good.withValues(alpha: 0.7),
      ]).createShader(Rect.fromLTWH(left, y, right - left, 1))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), axis);
    GameFx.text(canvas, 'log(time) — locked epochs', Offset(left + 70, y - 12),
        8, Colors.white.withValues(alpha: 0.30));

    for (final l in s._locked) {
      final ep = _epoch(l.epoch);
      final fx = left + _logFrac(ep.tSec) * (right - left);
      if (!_ok(fx)) continue;
      final pop = Curves.easeOut.transform((l.age / 0.5).clamp(0.0, 1.0));
      GameFx.orb(canvas, Offset(fx, y), 3.0 + 1.6 * pop,
          ep.color.withValues(alpha: 0.9),
          glow: 0.7 * pop, specular: false);
    }
    // Most-recent lock labels its "when".
    if (s._locked.isNotEmpty) {
      final l = s._locked.last;
      final ep = _epoch(l.epoch);
      final fx = left + _logFrac(ep.tSec) * (right - left);
      if (_ok(fx)) {
        GameFx.text(canvas, ep.when, Offset(fx, y - 13), 7.5,
            Colors.white.withValues(alpha: 0.7), weight: FontWeight.w700);
      }
    }
  }

  void _drawRail(Canvas canvas, Size size) {
    final c = s._railCenters;
    if (c.isEmpty) return;
    final y = s._railY;

    // Base track with end caps.
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.first - s._cardW * 0.8, y),
        Offset(c.last + s._cardW * 0.8, y), track);

    // Teal "flow" arrows between the in-order cards (the rail is always sorted).
    for (var i = 0; i < c.length - 1; i++) {
      _arrow(canvas, Offset(c[i], y), Offset(c[i + 1], y),
          _good.withValues(alpha: 0.85));
    }

    // Insertion-gap carets: pulsing ▾ that mark every tappable gap.
    final pulse = 0.5 + 0.5 * math.sin(s._clock * 3.2);
    for (var g = 0; g <= c.length; g++) {
      final gx = s._gapX(g);
      if (!_ok(gx)) continue;
      _caret(canvas, gx, y - s._cardH * 0.5 - 8,
          _accent.withValues(alpha: 0.4 + 0.4 * pulse));
    }

    // Cards.
    for (var i = 0; i < c.length; i++) {
      _drawCard(canvas, Offset(c[i], y), _epoch(s._rail[i]),
          revealWhen: true, dragging: false);
    }
  }

  void _drawWrongSnap(Canvas canvas) {
    if (s._wrongFlash <= 0 || s._wrongFromX == s._wrongToX) return;
    final a = s._wrongFlash;
    final y = s._railY - s._cardH * 0.5 - 8;
    _arrow(
        canvas,
        Offset(s._wrongFromX, y),
        Offset(s._wrongToX, y),
        const Color(0xFFFF5252).withValues(alpha: 0.95 * a));
    GameFx.orb(canvas, Offset(s._wrongToX, y), 5,
        const Color(0xFF80D8FF).withValues(alpha: a), glow: a, specular: false);
  }

  void _drawIncoming(Canvas canvas, Size size, bool cascade) {
    final e = s._incoming;
    if (e == null) return;
    final pos = Offset(s._incX, s._incY);
    GameFx.text(canvas, 'WHERE DOES IT GO?', Offset(pos.dx, pos.dy - 64), 10,
        Colors.white.withValues(alpha: 0.5), weight: FontWeight.w700);
    _drawCard(canvas, pos, _epoch(e), revealWhen: false, dragging: true);

    // Timer bar under the incoming card (teal → red as it depletes).
    if (s._cardTimerMax > 0) {
      final frac = (s._cardTimer / s._cardTimerMax).clamp(0.0, 1.0);
      final barW = (s._cardW + 24).clamp(80.0, 200.0);
      final bx = pos.dx - barW / 2;
      final by = pos.dy + s._cardH * 0.5 + 12;
      final bg = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barW, 6), const Radius.circular(3));
      canvas.drawRRect(bg, Paint()..color = Colors.white.withValues(alpha: 0.10));
      final col = Color.lerp(const Color(0xFFFF5252), _good, frac)!;
      final fg = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barW * frac, 6), const Radius.circular(3));
      canvas.drawRRect(fg, Paint()..color = col);
    }
    // A downward chevron hinting "drop me below".
    _caret(canvas, pos.dx, pos.dy + s._cardH * 0.5 + 26,
        Colors.white.withValues(alpha: 0.35));
  }

  void _drawFly(Canvas canvas) {
    final f = s._fly;
    if (f == null) return;
    final t = Curves.easeInOut.transform((f.age / 0.3).clamp(0.0, 1.0));
    final x = f.fromX + (f.toX - f.fromX) * t;
    final y = f.fromY + (f.toY - f.fromY) * t;
    if (!_ok(x) || !_ok(y)) return;
    _drawCard(canvas, Offset(x, y), _epoch(f.epoch),
        revealWhen: f.good, dragging: true,
        border: f.good ? _good : const Color(0xFFFF8A65));
  }

  void _drawCard(Canvas canvas, Offset center, _Epoch ep,
      {required bool revealWhen, required bool dragging, Color? border}) {
    final w = dragging ? (s._cardW + 14).clamp(70.0, 132.0) : s._cardW;
    final h = dragging ? (s._cardH + 14).clamp(64.0, 140.0) : s._cardH;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    if (dragging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(16)),
        Paint()..color = ep.color.withValues(alpha: 0.22),
      );
    }
    canvas.drawRRect(rr,
        Paint()..color = ep.color.withValues(alpha: dragging ? 0.42 : 0.30));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = dragging ? 2.2 : 1.6
          ..color = border ?? ep.color.withValues(alpha: 0.85));

    final iconSize = (h * 0.30).clamp(14.0, 26.0);
    final labelSize = (w * 0.17).clamp(7.5, 11.0);
    GameFx.text(canvas, ep.emoji, center.translate(0, -h * 0.22), iconSize,
        Colors.white);
    GameFx.text(canvas, w < 70 ? ep.abbrev : ep.name,
        center.translate(0, h * 0.04), labelSize,
        Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);
    if (revealWhen) {
      GameFx.text(canvas, ep.when, center.translate(0, h * 0.30),
          (w * 0.15).clamp(7.0, 10.0), _good.withValues(alpha: 0.95),
          weight: FontWeight.w800);
    }
  }

  // A small downward triangle (insertion caret).
  void _caret(Canvas canvas, double x, double y, Color color) {
    if (!_ok(x)) return;
    final path = Path()
      ..moveTo(x - 5, y - 5)
      ..lineTo(x + 5, y - 5)
      ..lineTo(x, y + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final dir = (b - a);
    final len = dir.distance;
    if (len <= 0.01) return;
    final n = dir / len;
    final start = a + n * (s._cardW * 0.5 + 2);
    final end = b - n * (s._cardW * 0.5 + 2);
    if ((end - start).distance <= 0) return;
    canvas.drawLine(start, end, paint);
    final perp = Offset(-n.dy, n.dx);
    canvas.drawLine(end, end - n * 7 + perp * 4, paint);
    canvas.drawLine(end, end - n * 7 - perp * 4, paint);
  }

  void _drawFactCard(Canvas canvas, Size size) {
    if (s._factAge >= 3.6 || s._factText.isEmpty) return;
    final a = (1 - (s._factAge - 3.0).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
    final y = size.height * 0.88;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: (size.width - 32).clamp(160.0, 460.0),
        height: 50);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
        rr, Paint()..color = Colors.black.withValues(alpha: 0.42 * a));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = s._factColor.withValues(alpha: 0.5 * a));
    _wrapText(canvas, s._factText, rect, 10.5,
        Colors.white.withValues(alpha: 0.92 * a));
  }

  void _wrapText(
      Canvas canvas, String text, Rect rect, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 18);
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) => true;
}
