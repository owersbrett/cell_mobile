import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Cosmic Timeline — ORDER THE EPOCHS of the universe.
///
/// A row of empty ordered slots plus a tray of shuffled EPOCH cards (Big Bang →
/// Inflation → Quark Soup → Nucleosynthesis → Recombination/CMB → Dark Ages →
/// First Stars → First Galaxies → Our Sun → Life on Earth → Now). Drag each card
/// into its correct chronological position (earliest → latest). Drop a card in
/// the right slot and the link "flows" (teal) and the card reveals its WHEN — the
/// real moment it happened (e.g. 380,000 yrs, 13.8 Gyr). Put it out of order and
/// the arrow into it BREAKS red so you see exactly where the sequence snaps. Fill
/// every slot in order and the timeline LOCKS: the cards plot onto a LOGARITHMIC
/// deep-time ribbon along the top — where the universe's first second occupies as
/// much timeline as the billions of years since. Then a new, longer/finer timeline
/// appears.
///
/// The lesson is the mechanic: cosmic history is a NAMED, ORDERED sequence and
/// order matters — you can't have stars before atoms, galaxies before stars, or a
/// Sun before the first galaxies. Each card teaches its "when" the moment it lands
/// in place; the log ribbon teaches why early epochs cluster.
///
/// The host (MiniGameHost) owns the clock, the 3-2-1 countdown, the score HUD and
/// the results screen; this widget renders ONLY the play area and reports points
/// via `session.addScore` / `session.noteStreak`. All rendering is a single
/// Ticker-driven CustomPainter — drag just mutates card positions.
class CosmicTimelineGame extends StatefulWidget {
  final MiniGameSession session;
  const CosmicTimelineGame({super.key, required this.session});

  @override
  State<CosmicTimelineGame> createState() => _CosmicTimelineGameState();
}

// ── Epoch catalog ────────────────────────────────────────────────────────────

enum _EpochId {
  bigBang,
  inflation,
  quarkSoup,
  nucleosynthesis,
  recombination,
  darkAges,
  firstStars,
  firstGalaxies,
  sun,
  lifeEarth,
  now,
}

class _Epoch {
  final int rank; // canonical chronological position (earliest = 0)
  final String name;
  final String abbrev;
  final String emoji;
  final Color color;
  final String when; // the revealed timestamp label
  final double tSec; // seconds AFTER the Big Bang, for log-time plotting (0 = BB)
  final String fact; // the one-line education shown when you touch the card
  const _Epoch(this.rank, this.name, this.abbrev, this.emoji, this.color,
      this.when, this.tSec, this.fact);
}

// Seconds-after-Big-Bang for each epoch (approximate, for the log ribbon).
// 1 year ≈ 3.156e7 s.
const Map<_EpochId, _Epoch> _kEpochs = {
  _EpochId.bigBang: _Epoch(0, 'Big Bang', 'BANG', '💥', Color(0xFFFFD54F),
      't = 0', 0, 'Space, time, energy and the whole expansion begin from a hot, dense state.'),
  _EpochId.inflation: _Epoch(1, 'Inflation', 'INFL', '🎈', Color(0xFFFF8A65),
      '10⁻³² s', 1e-32, 'The universe doubles in size dozens of times in a flash, smoothing it out.'),
  _EpochId.quarkSoup: _Epoch(2, 'Quark Soup', 'QUARK', '🍲', Color(0xFFEF5350),
      '10⁻⁶ s', 1e-6, 'Too hot for protons: a plasma of free quarks and gluons fills everything.'),
  _EpochId.nucleosynthesis: _Epoch(3, 'First Nuclei', 'NUCLEI', '⚛️',
      Color(0xFFBA68C8), '3 min', 180,
      'Protons and neutrons fuse into the first hydrogen and helium nuclei.'),
  _EpochId.recombination: _Epoch(4, 'CMB / Recombination', 'CMB', '📡',
      Color(0xFF7986CB), '380,000 yrs', 1.2e13,
      'Nuclei grab electrons into atoms; light breaks free as the cosmic microwave background.'),
  _EpochId.darkAges: _Epoch(5, 'Dark Ages', 'DARK', '🌑', Color(0xFF546E7A),
      '~50 Myr', 1.58e15, 'No stars yet — only cooling hydrogen gas drifting in the dark.'),
  _EpochId.firstStars: _Epoch(6, 'First Stars', 'STARS', '⭐',
      Color(0xFF4FC3F7), '~200 Myr', 6.3e15,
      'Gravity ignites the first stars, flooding the cosmos with light.'),
  _EpochId.firstGalaxies: _Epoch(7, 'First Galaxies', 'GALAXY', '🌌',
      Color(0xFF9575CD), '~1 Gyr', 3.15e16,
      'Stars gather by the billions into the first galaxies.'),
  _EpochId.sun: _Epoch(8, 'Our Sun Forms', 'SUN', '☀️', Color(0xFFFFB300),
      '~9.2 Gyr', 2.9e17, 'A cloud collapses into the Sun and its planets, including Earth.'),
  _EpochId.lifeEarth: _Epoch(9, 'Life on Earth', 'LIFE', '🦠',
      Color(0xFF66BB6A), '~10 Gyr', 3.15e17,
      'The first single-celled life appears in Earth\'s young oceans.'),
  _EpochId.now: _Epoch(10, 'Now', 'NOW', '🪐', Color(0xFF4DD0E1), '13.8 Gyr',
      4.35e17, 'You, reading this — 13.8 billion years after it all began.'),
};

_Epoch _epoch(_EpochId id) => _kEpochs[id]!;

// Log-time bounds for the deep-time ribbon. log10(tSec) spans inflation (-32)
// to now (~17.6); the Big Bang (t=0) is pinned to the far left.
const double _kLogLo = -33.0;
const double _kLogHi = 18.0;

double _logFrac(double tSec) {
  if (tSec <= 0) return 0.0; // Big Bang pinned left
  final l = (math.log(tSec) / math.ln10).clamp(_kLogLo, _kLogHi);
  return ((l - _kLogLo) / (_kLogHi - _kLogLo)).clamp(0.0, 1.0);
}

// ── Mutable play objects ─────────────────────────────────────────────────────

class _Card {
  final _EpochId epoch;
  double x = 0, y = 0; // current center (px)
  double homeX = 0, homeY = 0; // resting tray position
  int? slot; // slot index if placed, else null (in tray)
  _Card(this.epoch);
}

enum _Phase { assemble, reveal }

// ── State ────────────────────────────────────────────────────────────────────

class _CosmicTimelineGameState extends State<CosmicTimelineGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final int _gameSeed;
  late math.Random _rng;

  double _lastT = 0;
  double _clock = 0;

  int _level = 0; // timelines completed = current difficulty level
  _Phase _phase = _Phase.assemble;
  double _timelineStartClock = 0;
  double _revealAge = 0; // seconds into the reveal celebration
  double _revealHold = 2.6;

  // Current timeline.
  List<_EpochId> _correct = const []; // expected order, slot i ⇒ _correct[i]
  List<_Card> _cards = [];
  int _nSlots = 0;
  final Set<int> _scoredSlots = {}; // slot indices already awarded
  int _streak = 0; // consecutive correct placements / clean timelines

  // Layout (recomputed each build).
  List<Rect> _slotRects = const [];
  double _slotW = 56, _slotH = 70, _trayW = 60, _trayH = 58;

  Size _sz = Size.zero;
  _Card? _drag;
  int? _dragOriginSlot;

  // Fact card.
  String _factText = '';
  Color _factColor = Colors.white;
  double _factAge = 99;

  // Juice.
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _lockGlow = 0;

  static const Color _accent = Color(0xFF7C4DFF); // deep cosmic violet

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _gameSeed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    _rng = math.Random(_gameSeed);
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _newTimeline(first: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Timeline composition ─────────────────────────────────────────────────────

  /// Build the correct order for a timeline at [level]. Level 0 is a gentle
  /// 4-card primer of anchor events spread across all of history; later levels
  /// grow longer and fold in the finer early epochs until all 11 are in play.
  List<_EpochId> _composeTimeline(int level) {
    if (level == 0) {
      return const [
        _EpochId.bigBang,
        _EpochId.firstStars,
        _EpochId.sun,
        _EpochId.now,
      ];
    }
    // Always anchor the ends; fill the middle with finer epochs as level rises.
    final required = <_EpochId>{_EpochId.bigBang, _EpochId.now};
    final targetLen = (5 + level).clamp(5, _kEpochs.length);

    final pool = _EpochId.values
        .where((e) => !required.contains(e))
        .toList()
      ..shuffle(_rng);

    final need = (targetLen - required.length).clamp(0, pool.length);
    final chain = <_EpochId>{...required, ...pool.take(need)}.toList()
      ..sort((a, b) => _epoch(a).rank.compareTo(_epoch(b).rank));
    return chain;
  }

  void _newTimeline({bool first = false}) {
    _correct = _composeTimeline(_level);
    _nSlots = _correct.length;
    _scoredSlots.clear();
    _phase = _Phase.assemble;
    _timelineStartClock = _clock;
    _revealAge = 0;
    _drag = null;
    _dragOriginSlot = null;

    // One card per epoch; tray order shuffled so placement is never trivial.
    _cards = [for (final e in _correct) _Card(e)];
    final order = List<int>.generate(_nSlots, (i) => i)..shuffle(_rng);
    _cards = [for (final i in order) _cards[i]];

    if (!first && _sz != Size.zero) _positionCards(_sz.width, _sz.height);
  }

  // ── Layout ───────────────────────────────────────────────────────────────────

  void _computeSlots(double w, double h) {
    final n = _nSlots;
    if (n == 0) {
      _slotRects = const [];
      return;
    }
    const gap = 6.0;
    final avail = w - 16;
    _slotW = ((avail - gap * (n - 1)) / n).clamp(30.0, 84.0);
    _slotH = (_slotW * 1.32).clamp(48.0, 92.0);
    final totalW = _slotW * n + gap * (n - 1);
    final startX = (w - totalW) / 2;
    final top = h * 0.34;
    _slotRects = [
      for (var i = 0; i < n; i++)
        Rect.fromLTWH(startX + i * (_slotW + gap), top, _slotW, _slotH),
    ];
  }

  /// Assign resting tray positions and snap every non-dragged card to its home
  /// (tray) or its slot. Deterministic, so resizes and drops stay consistent.
  void _positionCards(double w, double h) {
    _computeSlots(w, h);
    final n = _cards.length;
    if (n == 0) return;

    _trayW = (_slotW + 4).clamp(46.0, 96.0);
    _trayH = 54;
    const gap = 9.0;
    final perRow = ((w - 14) / (_trayW + gap)).floor().clamp(1, n);
    final rows = (n / perRow).ceil();
    final baseY = h * 0.86;

    for (var i = 0; i < n; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final inRow = (row == rows - 1) ? n - row * perRow : perRow;
      final rowStartX = w / 2 - (inRow - 1) * (_trayW + gap) / 2;
      _cards[i].homeX = rowStartX + col * (_trayW + gap);
      _cards[i].homeY = baseY - (rows - 1 - row) * (_trayH + 8);
    }

    for (final c in _cards) {
      if (identical(c, _drag)) continue;
      if (c.slot != null && c.slot! < _slotRects.length) {
        c.x = _slotRects[c.slot!].center.dx;
        c.y = _slotRects[c.slot!].center.dy;
      } else {
        c.x = c.homeX;
        c.y = c.homeY;
      }
    }
  }

  // ── Tick ─────────────────────────────────────────────────────────────────────

  void _onTick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;

    // Juice decays even before the run starts so the ready state looks alive.
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_factAge < 99) _factAge += dt;
    if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 2).clamp(0.0, 1.0);
    if (_lockGlow > 0) _lockGlow = (_lockGlow - dt * 1.2).clamp(0.0, 1.0);

    if (!widget.session.isRunning) return;
    _clock += dt;

    if (_phase == _Phase.reveal) {
      _revealAge += dt;
      if (_revealAge >= _revealHold) {
        _level++;
        _newTimeline();
      }
    }
  }

  // ── Placement / scoring ──────────────────────────────────────────────────────

  void _showFact(_EpochId e) {
    final ep = _epoch(e);
    _factText = '${ep.name} (${ep.when}) — ${ep.fact}';
    _factColor = ep.color;
    _factAge = 0;
  }

  void _placeCard(_Card c, int slotIdx) {
    c.slot = slotIdx;
    c.x = _slotRects[slotIdx].center.dx;
    c.y = _slotRects[slotIdx].center.dy;
    _showFact(c.epoch);

    final correct = _correct[slotIdx] == c.epoch;
    if (correct) {
      if (!_scoredSlots.contains(slotIdx)) {
        _scoredSlots.add(slotIdx);
        _streak++;
        widget.session.noteStreak(_streak);
        final pts = 15 + _streak * 2;
        widget.session.addScore(pts);
        final ctr = _slotRects[slotIdx].center;
        _fx.addAll(FxBurst.spawn(ctr, _epoch(c.epoch).color, count: 12));
        _pops.add(FxPop(ctr.translate(0, -28), '+$pts', _epoch(c.epoch).color));
      }
    } else {
      _streak = 0;
      _wrongFlash = 0.5;
    }
    _checkComplete();
  }

  void _removeCard(_Card c) {
    c.slot = null;
    c.x = c.homeX;
    c.y = c.homeY;
    _showFact(c.epoch);
  }

  void _checkComplete() {
    if (_phase != _Phase.assemble) return;
    final filled = _cards.every((c) => c.slot != null);
    if (!filled) return;
    final allCorrect = List<bool>.generate(
        _nSlots, (i) => _cardInSlot(i)?.epoch == _correct[i]).every((b) => b);
    if (!allCorrect) {
      // Filled but out of order — the broken arrow shows where it snaps.
      _wrongFlash = 0.5;
      return;
    }
    _completeTimeline();
  }

  void _completeTimeline() {
    final elapsed = _clock - _timelineStartClock;
    final par = _nSlots * 3.2;
    final speedBonus = ((par - elapsed) * 4).clamp(0.0, 60.0).round();
    final bonus = 50 + _level * 12 + speedBonus;
    widget.session.addScore(bonus);
    _streak++;
    widget.session.noteStreak(_streak);
    _lockGlow = 1.0;
    if (_sz != Size.zero) {
      _pops.add(FxPop(Offset(_sz.width / 2, _slotRects.first.top - 22),
          'TIMELINE LOCKED +$bonus', const Color(0xFF80D8FF)));
      for (final r in _slotRects) {
        _fx.addAll(FxBurst.spawn(r.center, _accent, count: 6, speed: 90));
      }
    }
    // Hold on the locked timeline so the deep-time ribbon can be read.
    _phase = _Phase.reveal;
    _revealAge = 0;
    _revealHold = (1.8 + _nSlots * 0.12).clamp(1.8, 3.4);
  }

  _Card? _cardInSlot(int i) {
    for (final c in _cards) {
      if (c.slot == i) return c;
    }
    return null;
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  _Card? _cardAt(Offset p) {
    _Card? best;
    var bestD = double.infinity;
    for (final c in _cards) {
      final half = (c.slot != null ? _slotW : _trayW) * 0.72;
      final d = (Offset(c.x, c.y) - p).distance;
      if (d < half && d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  int? _slotAt(Offset p) {
    for (var i = 0; i < _slotRects.length; i++) {
      if (_slotRects[i].inflate(4).contains(p)) return i;
    }
    return null;
  }

  void _onTapUp(Offset p) {
    if (!widget.session.isRunning || _phase != _Phase.assemble) return;
    final c = _cardAt(p);
    if (c == null) return;
    if (c.slot != null) {
      setState(() => _removeCard(c)); // pull a placed card back to rearrange
    } else {
      setState(() => _showFact(c.epoch)); // teach the epoch on tap
    }
  }

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning || _phase != _Phase.assemble) return;
    final c = _cardAt(p);
    if (c == null) return;
    _drag = c;
    _dragOriginSlot = c.slot;
    if (c.slot != null) c.slot = null; // vacate while carrying
    c.x = p.dx;
    c.y = p.dy;
    setState(() {});
  }

  void _onPanUpdate(Offset p) {
    final c = _drag;
    if (c == null) return;
    c.x = p.dx; // ticker repaints; no setState needed for smooth drag
    c.y = p.dy;
  }

  void _onPanEnd() {
    final c = _drag;
    _drag = null;
    if (c == null) return;
    final target = _slotAt(Offset(c.x, c.y));
    setState(() {
      if (target != null && _cardInSlot(target) == null) {
        _placeCard(c, target);
      } else if (_dragOriginSlot != null &&
          _cardInSlot(_dragOriginSlot!) == null) {
        _placeCard(c, _dragOriginSlot!); // back where it came from
      } else {
        c.x = c.homeX; // home to the tray
        c.y = c.homeY;
      }
    });
    _dragOriginSlot = null;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final newSz = Size(w, h);
      if (_sz != newSz) {
        _sz = newSz;
        _positionCards(w, h);
      } else {
        _computeSlots(w, h);
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d.localPosition),
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
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
  final _CosmicTimelineGameState s;
  _TimelinePainter(
      {required Listenable repaint, required _CosmicTimelineGameState state})
      : s = state,
        super(repaint: repaint);

  static const Color _accent = _CosmicTimelineGameState._accent;
  static const Color _good = Color(0xFF80D8FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _accent, s._clock, motes: 30);

    if (s._wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFFFF5252)
                .withValues(alpha: s._wrongFlash * 0.16));
    }

    _drawHeader(canvas, size);
    _drawRibbon(canvas, size);
    _drawTimeline(canvas, size);
    _drawSlots(canvas, size);
    _drawCards(canvas, size);
    _drawFactCard(canvas, size);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  // Goal line + timeline counter at the very top.
  void _drawHeader(Canvas canvas, Size size) {
    final goal = s._phase == _Phase.reveal
        ? 'TIMELINE LOCKED — READ THE DEEP-TIME RIBBON'
        : 'ORDER THE EPOCHS — DRAG CARDS EARLIEST → LATEST';
    GameFx.text(canvas, goal, Offset(size.width / 2, 14), 11,
        Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700);
    GameFx.text(canvas, 'BIG BANG  ➜  NOW', Offset(size.width / 2, 31), 9,
        Colors.white.withValues(alpha: 0.32));
    if (s._level > 0) {
      GameFx.text(canvas, 'TIMELINE ${s._level + 1}',
          Offset(size.width - 42, 16), 10, _accent.withValues(alpha: 0.85),
          weight: FontWeight.w700);
    }
  }

  // The logarithmic deep-time ribbon: a horizontal axis where each correctly
  // placed epoch is plotted at its log(time-since-Big-Bang) position. Early
  // epochs spread across the left; the recent billions of years cram the right —
  // the visual lesson that the universe's first second is "as long" as eons.
  void _drawRibbon(Canvas canvas, Size size) {
    final y = size.height * 0.205;
    final left = 14.0, right = size.width - 14.0;
    final axis = Paint()
      ..shader = LinearGradient(colors: [
        _accent.withValues(alpha: 0.25),
        _good.withValues(alpha: 0.7),
      ]).createShader(Rect.fromLTWH(left, y, right - left, 1))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), axis);
    GameFx.text(canvas, 'log(time)', Offset(left + 26, y - 12), 8,
        Colors.white.withValues(alpha: 0.30));

    final glow = s._phase == _Phase.reveal
        ? Curves.easeOut.transform((s._revealAge / 0.6).clamp(0.0, 1.0))
        : 1.0;

    for (var i = 0; i < s._nSlots; i++) {
      final card = s._cardInSlot(i);
      if (card == null) continue;
      if (s._correct[i] != card.epoch) continue; // only correct placements plot
      final ep = _epoch(card.epoch);
      final fx = left + (_logFrac(ep.tSec)) * (right - left);
      // Connector from the ribbon down toward this card's slot.
      final sx = s._slotRects[i].center.dx;
      canvas.drawLine(
        Offset(fx, y + 2),
        Offset(sx, s._slotRects[i].top - 4),
        Paint()
          ..color = ep.color.withValues(alpha: 0.16 * glow)
          ..strokeWidth = 1,
      );
      GameFx.orb(canvas, Offset(fx, y), 3.5 + 1.5 * glow,
          ep.color.withValues(alpha: 0.9), glow: 0.8 * glow, specular: false);
      if (s._phase == _Phase.reveal) {
        GameFx.text(canvas, ep.when, Offset(fx, y - 12), 7.5,
            Colors.white.withValues(alpha: 0.7 * glow), weight: FontWeight.w700);
      }
    }
  }

  // The ordered track linking the slot centers, with arrows whose colour tells
  // the player where the order is right (teal flow) vs broken (red snap).
  void _drawTimeline(Canvas canvas, Size size) {
    final rects = s._slotRects;
    if (rects.isEmpty) return;
    final cy = rects.first.center.dy;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(rects.first.left - 12, cy),
        Offset(rects.first.center.dx, cy), track);
    canvas.drawLine(Offset(rects.last.center.dx, cy),
        Offset(rects.last.right + 12, cy), track);

    for (var i = 0; i < rects.length - 1; i++) {
      final a = rects[i].center;
      final b = rects[i + 1].center;
      final leftOk = s._cardInSlot(i)?.epoch == s._correct[i];
      final rightOk = s._cardInSlot(i + 1)?.epoch == s._correct[i + 1];
      final bothFilled =
          s._cardInSlot(i) != null && s._cardInSlot(i + 1) != null;
      Color c;
      if (leftOk && rightOk) {
        c = _good.withValues(alpha: 0.9); // chronology flows
      } else if (bothFilled) {
        c = const Color(0xFFFF5252).withValues(alpha: 0.9); // SNAP here
      } else {
        c = Colors.white.withValues(alpha: 0.16); // not yet linked
      }
      _arrow(canvas, a, b, c);
    }
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final dir = (b - a);
    final len = dir.distance;
    if (len <= 0) return;
    final n = dir / len;
    final start = a + n * (s._slotW * 0.5 + 2);
    final end = b - n * (s._slotW * 0.5 + 2);
    canvas.drawLine(start, end, paint);
    final perp = Offset(-n.dy, n.dx);
    final tip = end;
    canvas.drawLine(tip, tip - n * 7 + perp * 4, paint);
    canvas.drawLine(tip, tip - n * 7 - perp * 4, paint);
  }

  void _drawSlots(Canvas canvas, Size size) {
    for (var i = 0; i < s._slotRects.length; i++) {
      final r = s._slotRects[i];
      final occupied = s._cardInSlot(i) != null;
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
      if (!occupied) {
        canvas.drawRRect(
            rr, Paint()..color = Colors.white.withValues(alpha: 0.04));
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = Colors.white.withValues(alpha: 0.18));
      }
      // Slot number badge (chronological rank label).
      GameFx.text(canvas, '${i + 1}', Offset(r.left + 9, r.top + 8), 9,
          Colors.white.withValues(alpha: 0.30), weight: FontWeight.w700);
    }
  }

  void _drawCards(Canvas canvas, Size size) {
    for (final c in s._cards) {
      if (identical(c, s._drag)) continue;
      _drawCard(canvas, c, dragging: false);
    }
    if (s._drag != null) _drawCard(canvas, s._drag!, dragging: true);
  }

  void _drawCard(Canvas canvas, _Card c, {required bool dragging}) {
    final ep = _epoch(c.epoch);
    final placed = c.slot != null;
    final w = placed ? s._slotW : s._trayW;
    final h = placed ? s._slotH : s._trayH;
    final rect = Rect.fromCenter(center: Offset(c.x, c.y), width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final correct = placed && s._correct[c.slot!] == c.epoch;

    if (dragging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(14)),
        Paint()..color = ep.color.withValues(alpha: 0.22),
      );
    }

    canvas.drawRRect(rr,
        Paint()..color = ep.color.withValues(alpha: dragging ? 0.42 : 0.30));
    Color border;
    if (placed) {
      border = correct ? _good : const Color(0xFFFF8A65);
    } else {
      border = ep.color.withValues(alpha: 0.7);
    }
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = correct ? 2.2 : 1.5
          ..color = border);

    // Emoji icon + abbreviation, scaled to fit small slots.
    final iconSize = (h * 0.30).clamp(13.0, 22.0);
    final labelSize = (w * 0.17).clamp(7.0, 10.5);
    GameFx.text(canvas, ep.emoji, Offset(c.x, c.y - h * 0.22), iconSize,
        Colors.white);
    GameFx.text(canvas, w < 54 ? ep.abbrev : ep.name,
        Offset(c.x, c.y + h * 0.04), labelSize,
        Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);

    // A correctly-placed card reveals its WHEN — the real moment it happened.
    if (correct) {
      GameFx.text(canvas, ep.when, Offset(c.x, c.y + h * 0.32),
          (w * 0.15).clamp(6.5, 9.5), _good.withValues(alpha: 0.95),
          weight: FontWeight.w800);
    }
  }

  void _drawFactCard(Canvas canvas, Size size) {
    if (s._factAge >= 3.6 || s._factText.isEmpty) return;
    final a = (1 - (s._factAge - 3.0).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
    final y = size.height * 0.555;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: (size.width - 32).clamp(160.0, 460.0),
        height: 50);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
        rr, Paint()..color = Colors.black.withValues(alpha: 0.40 * a));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = s._factColor.withValues(alpha: 0.5 * a));
    _wrapText(canvas, s._factText, rect, 10.5,
        Colors.white.withValues(alpha: 0.92 * a));
  }

  // Tiny 2-line word wrap for the fact card (canvas TextPainter).
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
    tp.paint(
        canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) => true;
}
