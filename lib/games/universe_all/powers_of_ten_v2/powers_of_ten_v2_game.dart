import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Powers of Ten v2 — "Powers of Ten v2"  (BioScale.universeAll)
//
// UX-passed alternative to `powers_of_ten`. SELF-CONTAINED MODULE. Imports only
// the framework session (MiniGameSession), the shared fx toolkit, the Potatuhs
// theme, and Flutter — nothing from another game.
//
// Verb (unchanged lesson): PLACE-ON-THE-LOG-LADDER. A thing is named and you
// drag a marker to its order of magnitude on a logarithmic ladder (size in
// meters / mass in kg / time in seconds). Closer placement = more points; the
// reveal slides the truth + shows the value + a fact — every drop teaches where
// a thing sits across the powers of ten.
//
// WHAT CHANGED vs v1 (per the teardown brief):
//   1. NO DEAD STOPS. v1 inserted a blocking reveal hold after every item. v2 is
//      a continuous conveyor: dropping loads the next item instantly while the
//      answer slides to truth on a fading rail beside the spine. A per-item
//      timer creates pressure; the round flows instead of stop-starting.
//   2. NO MEMORIZATION CEILING. v1 used fixed item pools (~18/13/12) so returning
//      players recalled answers. v2 GENERATES every item from "scale a known
//      anchor by a factor" templates ("a line of 12,000 sand grains", "3× the
//      Sun's mass") with a randomized factor — the exponent is different every
//      play, so the *reasoning* (interpolate between anchors) is always required.
//   3. CLIMAX. The last 12s is a CASCADE: per-item time collapses, items rapid-
//      fire, and a score multiplier ramps to ×3 — a real finish spike, read off
//      the host clock (session.remaining), not a second timer.
//   4. TIGHT GRAB. The dragged marker rides ON the spine, so finger→marker→truth
//      is one vertical column from the first frame.
//
// PERF: one Ticker drives one CustomPainter (repaint:_ctrl). The painter reads
// live state fields every frame; gesture handlers mutate fields. No per-frame
// setState — the whole play area is a single CustomPaint.
// ═══════════════════════════════════════════════════════════════════════════

const Color _accent = Color(0xFF22D3EE); // scientific cyan (matches the family)
const Color _good = Color(0xFF4CDE80);
const Color _mid = Color(0xFFFFB300);
const Color _bad = Color(0xFFEF5350);

enum _Kind { size, mass, time }

double _log10(double x) => math.log(x) / math.ln10;

// Unicode superscript for "10ⁿ" labels.
const Map<String, String> _supDigits = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
};
String _sup(int n) =>
    n.toString().split('').map((c) => _supDigits[c] ?? c).join();

String _trim(double v) {
  if ((v - v.roundToDouble()).abs() < 0.05) return v.round().toString();
  return v.toStringAsFixed(1);
}

String _grp(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// A readable count for a generated factor N ("12,000", "3.5 million", "0.2").
String _fmtCount(double n) {
  if (n < 1) return _trim(n);
  if (n < 1000) return _grp(n.round());
  if (n < 1e6) return _grp(n.round());
  if (n < 1e9) return '${_trim(n / 1e6)} million';
  if (n < 1e12) return '${_trim(n / 1e9)} billion';
  if (n < 1e15) return '${_trim(n / 1e12)} trillion';
  return '${_trim(n / 1e15)} quadrillion';
}

/// "≈ 3.2 × 10⁷ s" — the resolved magnitude (the lesson's payoff).
String _fmtSci(double exp, String unit) {
  final r = exp.round();
  final mant = math.pow(10, exp - r).toDouble();
  return '≈ ${_trim(mant)} × 10${_sup(r)} $unit';
}

// ---------------------------------------------------------------------------
// Generative templates — "scale a known anchor by a factor". The randomized
// factor makes the target exponent continuous, so it cannot be memorized; the
// reasoning (orders of magnitude = repeated multiplication) is always required.
// ---------------------------------------------------------------------------

class _Tmpl {
  final _Kind kind;
  final String glyph;
  final int tier; // 0 easy … 2 hard
  final double baseExp; // log10 of ONE base unit (SI)
  final double loFE, hiFE; // factor-exponent range (log10 N)
  final String Function(String n) label; // the thing being placed
  final String Function(String n) fact; // the lesson reveal
  const _Tmpl(this.kind, this.glyph, this.tier, this.baseExp, this.loFE,
      this.hiFE, this.label, this.fact);
}

const List<_Tmpl> _tmpls = [
  // ── SIZE · meters ──
  _Tmpl(_Kind.size, '☀️', 0, 9.14, -1, 3, _starLabel, _starFact),
  _Tmpl(_Kind.size, '⬤', 0, -3.30, 0, 6, _sandLabel, _sandFact),
  _Tmpl(_Kind.size, '🧫', 1, -5.0, 0, 5, _cellLabel, _cellFact),
  _Tmpl(_Kind.size, '📄', 1, -4.0, 0, 7, _paperLabel, _paperFact),
  _Tmpl(_Kind.size, '✨', 2, 15.98, -2, 6, _lyLabel, _lyFact),
  // ── MASS · kilograms ──
  _Tmpl(_Kind.mass, '🐘', 0, 3.70, 0, 7, _eleLabel, _eleFact),
  _Tmpl(_Kind.mass, '☀️', 0, 30.30, -2, 3, _sunMLabel, _sunMFact),
  _Tmpl(_Kind.mass, '💧', 1, -4.30, 0, 6, _dropLabel, _dropFact),
  _Tmpl(_Kind.mass, '🧍', 1, 1.85, 0, 7, _pplLabel, _pplFact),
  _Tmpl(_Kind.mass, '🍚', 2, -4.60, 0, 6, _riceLabel, _riceFact),
  // ── TIME · seconds ──
  _Tmpl(_Kind.time, '❤️', 0, -0.07, 0, 8, _beatLabel, _beatFact),
  _Tmpl(_Kind.time, '🌞', 0, 4.94, 0, 6, _dayLabel, _dayFact),
  _Tmpl(_Kind.time, '📸', 1, -3.0, 0, 6, _flashLabel, _flashFact),
  _Tmpl(_Kind.time, '⏳', 1, 9.40, -3, 6, _lifeLabel, _lifeFact),
  _Tmpl(_Kind.time, '📅', 2, 7.50, -7, 6, _yearLabel, _yearFact),
];

// label / fact builders (top-level so the list stays const)
String _starLabel(String n) => 'A star $n× the Sun\'s width';
String _starFact(String n) =>
    'The Sun is ≈1.39 million km across — this star is $n× that.';
String _sandLabel(String n) => 'A line of $n sand grains';
String _sandFact(String n) =>
    'Each grain ≈0.5 mm; $n in a row reach this length.';
String _cellLabel(String n) => '$n cells side by side';
String _cellFact(String n) => 'A cell ≈10 µm wide; $n across span this far.';
String _paperLabel(String n) => 'A stack of $n paper sheets';
String _paperFact(String n) =>
    'One sheet ≈0.1 mm; $n stacked reach this height.';
String _lyLabel(String n) => 'A distance of $n light-years';
String _lyFact(String n) =>
    'One light-year ≈9.5 × 10¹⁵ m; ×$n gives this span.';
String _eleLabel(String n) => 'The mass of $n elephants';
String _eleFact(String n) => 'An elephant ≈5,000 kg; $n of them mass this.';
String _sunMLabel(String n) => 'A star $n× the Sun\'s mass';
String _sunMFact(String n) => 'The Sun ≈2 × 10³⁰ kg; ×$n is this mass.';
String _dropLabel(String n) => 'The mass of $n water drops';
String _dropFact(String n) => 'A drop ≈50 mg; $n drops mass this.';
String _pplLabel(String n) => 'The mass of $n people';
String _pplFact(String n) => 'A person ≈70 kg; $n of them mass this.';
String _riceLabel(String n) => 'The mass of $n grains of rice';
String _riceFact(String n) => 'A rice grain ≈25 mg; $n grains mass this.';
String _beatLabel(String n) => 'The time of $n heartbeats';
String _beatFact(String n) => 'A heartbeat ≈0.85 s; $n beats take this long.';
String _dayLabel(String n) => 'A span of $n days';
String _dayFact(String n) => 'A day ≈86,400 s; $n days is this long.';
String _flashLabel(String n) => 'The time of $n camera flashes';
String _flashFact(String n) => 'A flash ≈1 ms; $n of them last this long.';
String _lifeLabel(String n) => 'A span of $n human lifetimes';
String _lifeFact(String n) =>
    'A lifetime ≈2.5 billion s; ×$n is this duration.';
String _yearLabel(String n) => 'A span of $n years';
String _yearFact(String n) => 'A year ≈3.2 × 10⁷ s; $n years is this long.';

// ---------------------------------------------------------------------------
// Ladders (kept wide + anchored, like v1 — the breadth IS the lesson).
// ---------------------------------------------------------------------------

class _Ladder {
  final double lo, hi;
  final String unit;
  final String unitSi;
  final List<MapEntry<double, String>> anchors;
  const _Ladder(this.lo, this.hi, this.unit, this.unitSi, this.anchors);
}

const _Ladder _sizeLadder = _Ladder(-18, 27, 'SIZE · meters', 'm', [
  MapEntry(-10, 'atom'),
  MapEntry(0, 'human'),
  MapEntry(7, 'Earth'),
  MapEntry(16, 'light-yr'),
  MapEntry(21, 'galaxy'),
]);
const _Ladder _massLadder = _Ladder(-31, 54, 'MASS · kilograms', 'kg', [
  MapEntry(-30, 'electron'),
  MapEntry(2, 'human'),
  MapEntry(24.8, 'Earth'),
  MapEntry(30, 'Sun'),
  MapEntry(42, 'galaxy'),
]);
const _Ladder _timeLadder = _Ladder(-24, 18, 'TIME · seconds', 's', [
  MapEntry(-9, 'ns'),
  MapEntry(0, 'second'),
  MapEntry(7.5, 'year'),
  MapEntry(17.6, 'universe'),
]);

_Ladder _ladderFor(_Kind k) {
  switch (k) {
    case _Kind.size:
      return _sizeLadder;
    case _Kind.mass:
      return _massLadder;
    case _Kind.time:
      return _timeLadder;
  }
}

/// A fading "answer" sliding to truth on the rail beside the spine. Stores
/// ladder-normalized fractions so a ghost stays put even when the live ladder
/// rescales to the next item's kind.
class _Reveal {
  final String glyph;
  final double fracDrop, fracTrue;
  final Color color;
  double age = 0;
  _Reveal(this.glyph, this.fracDrop, this.fracTrue, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME primitives the
// live game uses (the log-ladder spine + decade ticks, the faint named anchors,
// the glowing marker orb, the slide-to-truth reveal, the timer bar, the gold
// cascade). Static + self-contained: they render once in the intro carousel.
// ═══════════════════════════════════════════════════════════════════════════

// A compact demo ladder — same span + anchors as the live SIZE ladder.
const double _legLo = -18, _legHi = 27;

double _legY(double e, double top, double bot) {
  final f = ((e - _legLo) / (_legHi - _legLo)).clamp(0.0, 1.0);
  return bot - f * (bot - top);
}

/// Draws the log-ladder spine the player reads: a vertical rail, decade ticks
/// with 10ⁿ labels, exactly like [_PoTV2Painter._drawLadder].
void _legLadder(
    Canvas canvas, double spineX, double top, double bot, double dim) {
  canvas.drawLine(
    Offset(spineX, top),
    Offset(spineX, bot),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.22 * dim)
      ..strokeWidth = 2,
  );
  for (double n = _legLo; n <= _legHi + 0.01; n += 9) {
    final y = _legY(n, top, bot);
    canvas.drawLine(
      Offset(spineX - 6, y),
      Offset(spineX + 6, y),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16 * dim)
        ..strokeWidth = 1,
    );
    GameFx.text(canvas, '10${_sup(n.round())}', Offset(spineX - 30, y), 10,
        Colors.white.withValues(alpha: 0.5 * dim),
        weight: FontWeight.w700);
  }
}

/// The glowing marker orb + glyph the player drags along the spine.
void _legMarker(
    Canvas canvas, double spineX, double y, String glyph, Color acc) {
  canvas.drawLine(
    Offset(spineX - 36, y),
    Offset(spineX + 36, y),
    Paint()
      ..color = acc.withValues(alpha: 0.35)
      ..strokeWidth = 1.2,
  );
  GameFx.orb(canvas, Offset(spineX, y), 20, acc.withValues(alpha: 0.9),
      glow: 1.0, specular: false);
  GameFx.text(canvas, glyph, Offset(spineX, y), 22, Colors.white);
}

// Frame 1 — the core object + verb: read the named thing, drag its marker.
void _legendPlace(Canvas canvas, Size size) {
  if (size.width < 20 || size.height < 20) return;
  final w = size.width;
  final spineX = w * 0.44;
  final top = size.height * 0.24, bot = size.height * 0.9;

  // The live prompt: glyph + generated name.
  GameFx.text(canvas, '☀️  A star 8× the Sun\'s width',
      Offset(w / 2, size.height * 0.1), 15, Colors.white,
      weight: FontWeight.w800, glow: 0.4);
  GameFx.text(canvas, 'SIZE · meters', Offset(w / 2, size.height * 0.16), 10,
      _accent.withValues(alpha: 0.9), weight: FontWeight.w700);

  _legLadder(canvas, spineX, top, bot, 1.0);

  // Faint named anchors on the right — the scaffold you interpolate between.
  for (final a in _sizeLadder.anchors) {
    final y = _legY(a.key, top, bot);
    canvas.drawLine(
      Offset(spineX + 8, y),
      Offset(spineX + 20, y),
      Paint()
        ..color = _accent.withValues(alpha: 0.16)
        ..strokeWidth = 1,
    );
    GameFx.text(canvas, a.value,
        Offset(spineX + 24 + a.value.length * 3.2, y), 9.5,
        _accent.withValues(alpha: 0.34));
  }

  final my = _legY(3, top, bot);
  _legMarker(canvas, spineX, my, '☀️', _accent);
  // Up/down drag cue above the marker.
  final p = Paint()
    ..color = _accent
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final ay = my - 40;
  canvas.drawLine(Offset(spineX - 8, ay + 6), Offset(spineX, ay - 3), p);
  canvas.drawLine(Offset(spineX + 8, ay + 6), Offset(spineX, ay - 3), p);
}

// Frame 2 — how to score: drop dead-on the true power of ten for PERFECT.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 20 || size.height < 20) return;
  final w = size.width;
  final spineX = w * 0.44;
  final top = size.height * 0.2, bot = size.height * 0.86;

  _legLadder(canvas, spineX, top, bot, 1.0);

  // The slide-to-truth reveal: a dim drop dot, the error band, the ✓ truth orb.
  final yDrop = _legY(4.6, top, bot);
  final yTrue = _legY(5.0, top, bot);
  final rx = spineX + 30;
  canvas.drawLine(
    Offset(rx, yDrop),
    Offset(rx, yTrue),
    Paint()
      ..color = _good.withValues(alpha: 0.5)
      ..strokeWidth = 3,
  );
  canvas.drawCircle(
      Offset(rx, yDrop), 4, Paint()..color = Colors.white.withValues(alpha: 0.35));
  GameFx.orb(canvas, Offset(rx, yTrue), 14, _good, glow: 1.0, specular: false);
  GameFx.text(canvas, '✓', Offset(rx, yTrue), 14, Colors.white,
      weight: FontWeight.w900);

  // The marker resting on the truth + the score pop.
  _legMarker(canvas, spineX, yTrue, '☀️', _good);
  GameFx.text(canvas, 'PERFECT +150', Offset(w / 2, size.height * 0.955), 15,
      _good, weight: FontWeight.w900, glow: 0.5);
}

// Frame 3 — the danger: a per-item timer drains and auto-snaps a forced guess.
void _legendTimer(Canvas canvas, Size size) {
  if (size.width < 20 || size.height < 20) return;
  final w = size.width;
  final spineX = w * 0.44;
  final top = size.height * 0.24, bot = size.height * 0.88;

  // The draining timer bar — same look as [_PoTV2Painter._drawTimerBar].
  final ty = size.height * 0.11;
  final x0 = w * 0.12, x1 = w * 0.88;
  canvas.drawLine(Offset(x0, ty), Offset(x1, ty),
      Paint()..color = Colors.white12..strokeWidth = 4);
  const frac = 0.32;
  canvas.drawLine(
    Offset(x0, ty),
    Offset(x0 + (x1 - x0) * frac, ty),
    Paint()
      ..color = Color.lerp(_bad, _mid, (frac / 0.5).clamp(0, 1))!
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round,
  );
  GameFx.text(canvas, '⏳ TIME LOW', Offset(w / 2, size.height * 0.055), 12,
      _bad, weight: FontWeight.w800);

  _legLadder(canvas, spineX, top, bot, 1.0);
  final my = _legY(1.0, top, bot);
  _legMarker(canvas, spineX, my, '⬤', _mid);
  GameFx.text(canvas, 'auto-snaps if it empties',
      Offset(w / 2, size.height * 0.94), 11, Colors.white54);
}

// Frame 4 — the escalation: the last-12s CASCADE, items rapid-fire, score ×3.
void _legendCascade(Canvas canvas, Size size) {
  if (size.width < 20 || size.height < 20) return;
  final w = size.width;
  final spineX = w * 0.44;
  final top = size.height * 0.26, bot = size.height * 0.9;
  const gold = Potatuhs.gold;

  GameFx.text(canvas, '⚡ CASCADE ×3', Offset(w / 2, size.height * 0.12), 20,
      gold, weight: FontWeight.w900, glow: 0.7);

  _legLadder(canvas, spineX, top, bot, 0.85);

  // Rapid-fire markers streaking down the spine — the climax spike.
  const exps = [14.0, 6.0, -3.0];
  const glyphs = ['✨', '🧫', '⬤'];
  for (int i = 0; i < exps.length; i++) {
    final y = _legY(exps[i], top, bot);
    final a = 1.0 - i * 0.28;
    GameFx.orb(canvas, Offset(spineX, y), 18 * a + 4, gold.withValues(alpha: a),
        glow: 1.0, specular: false);
    GameFx.text(canvas, glyphs[i], Offset(spineX, y), 20 * a + 4, Colors.white);
  }
  GameFx.text(canvas, 'per-item time collapses',
      Offset(w / 2, size.height * 0.955), 11, gold.withValues(alpha: 0.85),
      weight: FontWeight.w700);
}

/// The visual manual for Powers of Ten v2 — wired into the registry spec.
const List<LegendFrame> powersOfTenV2LegendFrames = [
  LegendFrame(
      caption: 'Drag the glowing marker up the log ladder of tens',
      paint: _legendPlace),
  LegendFrame(
      caption: 'Drop it dead-on its true power of ten for PERFECT',
      paint: _legendScore),
  LegendFrame(
      caption: 'Beat the timer bar or it snaps a forced guess',
      paint: _legendTimer),
  LegendFrame(
      caption: 'Last 12s: items cascade and score ramps to ×3',
      paint: _legendCascade),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PowersOfTenV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PowersOfTenV2Game({super.key, required this.session});

  @override
  State<PowersOfTenV2Game> createState() => _PowersOfTenV2GameState();
}

class _PowersOfTenV2GameState extends State<PowersOfTenV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  double _clock = 0;
  double _lastWall = 0;
  bool _started = false;

  // ── active item (generated) ──
  _Kind _kind = _Kind.size;
  String _name = '';
  String _glyph = '';
  String _fact = '';
  String _valueLabel = '';
  double _trueExp = 0;
  _Tmpl? _lastTmpl;

  double _markerExp = 0;
  double _objDrop = 0; // entrance ease
  bool _touched = false; // did the player move the marker this item?

  // ── cadence ──
  int _round = 0;
  double _itemT = 0; // seconds remaining for this item
  double _itemTMax = 1;

  int _streak = 0;

  // ── attract autopilot ──
  // Buffered so each perfect drop is readable: one tick snaps the marker to the
  // item's true magnitude (visible), the next drops it, then a few idle ticks
  // let the reveal slide + fact show before the next item is answered.
  int _autoBuffer = 0;
  static const int _kAutoBufferTicks = 2;

  // ── reveals / juice ──
  final List<_Reveal> _reveals = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  static const double _revealDur = 0.95;

  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastWall = _now();
    // ATTRACT autopilot: this game knows every item's true magnitude, so it can
    // play itself perfectly. Registered always (harmless in normal play — the
    // host only calls it in autoplay). See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays Powers of Ten v2
  /// *correctly*: it snaps the marker to the current item's true order of
  /// magnitude ([_trueExp]) and drops via the game's own [_drop] handler —
  /// always a PERFECT placement. The cascade/climax needs no special handling:
  /// it is the same drop loop running faster (shorter item timers read off the
  /// host clock), so answering the current item each cycle covers it too. A
  /// short buffer keeps each answer readable; the host owns the clock so the
  /// round still ends on time.
  void _autoStep() {
    if (!widget.session.isRunning || !_started) return;
    if (_autoBuffer > 0) {
      _autoBuffer--;
      return;
    }
    // Two beats: first snap the marker onto the truth (visible), then drop it.
    if (_markerExp != _trueExp) {
      _markerExp = _trueExp;
      _touched = true;
      return;
    }
    _drop(); // resolves the current item (perfect) and loads the next
    _autoBuffer = _kAutoBufferTicks;
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── difficulty / cadence ramp ──
  List<_Kind> get _allowedKinds {
    if (_round < 4) return const [_Kind.size];
    if (_round < 9) return const [_Kind.size, _Kind.mass];
    return const [_Kind.size, _Kind.mass, _Kind.time];
  }

  int get _maxTier {
    if (_round < 3) return 0;
    if (_round < 7) return 1;
    return 2;
  }

  double get _band => (7.0 - _round * 0.22).clamp(3.0, 7.0);
  double get _perfectTol => (0.5 - _round * 0.012).clamp(0.25, 0.5);
  double get _goodTol => (1.6 - _round * 0.05).clamp(0.8, 1.6);
  double get _baseItemTime => (5.0 - _round * 0.12).clamp(2.2, 5.0);

  // ── climax (read off the host clock) ──
  bool get _climax =>
      widget.session.isRunning &&
      widget.session.remaining.inMilliseconds <= 12000;
  double get _climaxProg => widget.session.isRunning
      ? (1.0 - widget.session.remaining.inMilliseconds / 12000.0).clamp(0.0, 1.0)
      : 0.0;
  double get _mult => _climax ? (1.0 + 2.0 * _climaxProg).clamp(1.0, 3.0) : 1.0;

  Color get _liveAccent => _climax
      ? Color.lerp(_accent, Potatuhs.gold, _climaxProg * 0.6)!
      : _accent;

  // ── ladder geometry ──
  double get _ladTop => _lastSize.height * 0.22;
  double get _ladBot => _lastSize.height * 0.86;

  double _yForFrac(double f) => _ladBot - f * (_ladBot - _ladTop);
  double _fracForExp(double e, _Kind k) {
    final lad = _ladderFor(k);
    return (e - lad.lo) / (lad.hi - lad.lo);
  }

  double _yForExp(double e) => _yForFrac(_fracForExp(e, _kind));
  double _expForY(double y) {
    final lad = _ladderFor(_kind);
    final f = (_ladBot - y) / (_ladBot - _ladTop);
    return lad.lo + f * (lad.hi - lad.lo);
  }

  void _loadItem() {
    final kinds = _allowedKinds;
    final kind = kinds[_rng.nextInt(kinds.length)];
    final cands = _tmpls
        .where((t) => t.kind == kind && t.tier <= _maxTier && t != _lastTmpl)
        .toList();
    final t = cands[_rng.nextInt(cands.length)];
    _lastTmpl = t;
    final lad = _ladderFor(kind);

    // Target exponent within the template's natural range, clamped to ladder.
    final loE = math.max(t.baseExp + t.loFE, lad.lo + 1.5);
    final hiE = math.min(t.baseExp + t.hiFE, lad.hi - 1.5);
    final targetExp =
        hiE > loE ? loE + _rng.nextDouble() * (hiE - loE) : (lad.lo + lad.hi) / 2;

    // Snap the factor N to a nice human number, then recompute the true exp so
    // the displayed factor and the answer stay exactly consistent.
    final nNice = _niceN(math.pow(10, targetExp - t.baseExp).toDouble());
    double trueExp = t.baseExp + _log10(nNice);
    trueExp = trueExp.clamp(lad.lo + 1, lad.hi - 1);

    final nStr = _fmtCount(nNice);
    _kind = kind;
    _glyph = t.glyph;
    _name = t.label(nStr);
    _fact = t.fact(nStr);
    _trueExp = trueExp;
    _valueLabel = _fmtSci(trueExp, lad.unitSi);

    _markerExp = (lad.lo + lad.hi) / 2;
    _objDrop = 0;
    _touched = false;
    _itemTMax = _baseItemTime * (_climax ? 0.55 : 1.0);
    _itemT = _itemTMax;
  }

  double _niceN(double x) {
    if (x <= 0) return 1;
    final e = _log10(x).floor();
    final base = math.pow(10, e).toDouble();
    final m = x / base; // 1..10
    const snaps = [1.0, 1.5, 2.0, 3.0, 5.0, 7.0, 10.0];
    double best = snaps.first;
    for (final s in snaps) {
      if ((s - m).abs() < (best - m).abs()) best = s;
    }
    return best * base;
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    _clock += dt;

    for (final p in _particles) {
      p.step(dt);
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);
    for (final r in _reveals) {
      r.age += dt / _revealDur;
    }
    _reveals.removeWhere((r) => r.age >= 1);

    if (_objDrop < 1) _objDrop = math.min(1, _objDrop + dt / 0.22);

    if (widget.session.isRunning && !_started) {
      _started = true;
      _round = 0;
      _loadItem();
    }
    if (!widget.session.isRunning) return;

    // Continuous cadence: the per-item timer drains; running out forces a snap
    // estimate and immediately loads the next item — no dead stop.
    _itemT -= dt;
    if (_itemT <= 0) _resolve(forced: true);
  }

  // ── interaction ──
  void _grab(Offset p) {
    if (!widget.session.isRunning) return;
    final lad = _ladderFor(_kind);
    _markerExp = _expForY(p.dy).clamp(lad.lo, lad.hi);
    _touched = true;
  }

  void _move(Offset p) {
    if (!widget.session.isRunning) return;
    final lad = _ladderFor(_kind);
    _markerExp = _expForY(p.dy).clamp(lad.lo, lad.hi);
    _touched = true;
  }

  void _drop() {
    if (!widget.session.isRunning) return;
    _resolve(forced: false);
  }

  void _resolve({required bool forced}) {
    final trueExp = _trueExp;
    final error = (_markerExp - trueExp).abs();
    final band = _band;
    final acc = (1 - error / band).clamp(0.0, 1.0);
    final mult = _mult;

    int base = (100 * acc).round();
    String verdict;
    if (error <= _perfectTol) {
      base += 50;
      verdict = 'PERFECT';
    } else if (error <= _goodTol) {
      verdict = 'CLOSE';
    } else if (acc > 0) {
      verdict = 'OK';
    } else {
      verdict = 'OFF';
    }
    final pts = (base * mult).round();

    if (error <= _goodTol) {
      _streak++;
    } else {
      _streak = 0;
    }

    widget.session.addScore(pts);
    widget.session.noteStreak(_streak);

    // Fading slide-to-truth on the rail (ladder-normalized so it stays put).
    final fracDrop = _fracForExp(_markerExp, _kind);
    final fracTrue = _fracForExp(trueExp, _kind);
    final col = _accForColor(acc.toDouble());
    _reveals.add(_Reveal(_glyph, fracDrop, fracTrue, col));
    if (_reveals.length > 3) _reveals.removeAt(0);

    final rx = _lastSize.width * 0.5 + 30;
    final ry = _yForFrac(fracTrue);
    _pops.add(FxPop(Offset(rx, ry - 8),
        mult > 1.05 ? '$verdict +$pts ×${_trim(mult)}' : '$verdict +$pts', col));
    if (error <= _goodTol) {
      _particles.addAll(FxBurst.spawn(Offset(rx, ry), col,
          count: error <= _perfectTol ? 18 : 10, speed: 130));
    }

    _round++;
    _loadItem();
  }

  Color _accForColor(double acc) {
    if (acc < 0.5) return Color.lerp(_bad, _mid, acc / 0.5)!;
    return Color.lerp(_mid, _good, (acc - 0.5) / 0.5)!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _grab(d.localPosition),
      onTapUp: (_) => _drop(),
      onPanDown: (d) => _grab(d.localPosition),
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _drop(),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PoTV2Painter(this, _ctrl),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — draws the entire play area; repaints every frame via _ctrl.
// ---------------------------------------------------------------------------

class _PoTV2Painter extends CustomPainter {
  final _PowersOfTenV2GameState s;
  _PoTV2Painter(this.s, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    s._lastSize = size;
    final w = size.width;
    final acc = s._liveAccent;
    GameFx.atmosphere(canvas, size, acc, s._clock,
        motes: s._climax ? 46 : 30);

    final lad = _ladderFor(s._kind);
    final spineX = w * 0.5;
    _drawLadder(canvas, size, lad, spineX);

    if (!s.widget.session.isRunning) {
      _drawReady(canvas, size);
      _drawReveals(canvas, spineX);
      FxBurst.paint(canvas, s._particles);
      return;
    }

    _drawTimerBar(canvas, size, acc);

    // Prompt.
    GameFx.text(canvas, '${s._glyph}  ${s._name}',
        Offset(w / 2, size.height * 0.105), 20, Colors.white,
        weight: FontWeight.w800, glow: 0.5);
    GameFx.text(canvas, lad.unit, Offset(w / 2, size.height * 0.15), 11,
        acc.withValues(alpha: 0.9), weight: FontWeight.w700);

    if (s._streak >= 2) {
      GameFx.text(canvas, '🔥 ${s._streak}', Offset(w / 2, size.height * 0.185),
          13, _good, weight: FontWeight.w700);
    }
    if (s._climax) {
      GameFx.text(canvas, '⚡ CASCADE ×${_trim(s._mult)}',
          Offset(w / 2, size.height * 0.185), 14, Potatuhs.gold,
          weight: FontWeight.w900, glow: 0.6);
    }

    _drawReveals(canvas, spineX);
    _drawLiveMarker(canvas, size, spineX, lad, acc);

    FxBurst.paint(canvas, s._particles);
    for (final p in s._pops) {
      p.paint(canvas);
    }

    // The lesson payoff: the most recent answer's value + fact at the bottom.
    if (s._reveals.isNotEmpty) {
      GameFx.text(canvas, s._valueLabel, Offset(w / 2, size.height * 0.93), 14,
          Colors.white, weight: FontWeight.w700);
      _wrappedFact(canvas, s._fact, Offset(w / 2, size.height * 0.965), w - 48);
    }
  }

  // ── ladder spine + decade gridlines + faint named anchors ──
  void _drawLadder(Canvas canvas, Size size, _Ladder lad, double spineX) {
    final top = s._ladTop;
    final bot = s._ladBot;
    final dim = !s.widget.session.isRunning;
    final span = lad.hi - lad.lo;

    canvas.drawLine(
      Offset(spineX, top),
      Offset(spineX, bot),
      Paint()
        ..color = Colors.white.withValues(alpha: dim ? 0.12 : 0.22)
        ..strokeWidth = 2,
    );

    final step = _gridStep(span);
    final startN = (lad.lo / step).ceil() * step;
    for (int n = startN; n <= lad.hi + 0.001; n += step) {
      final y = s._yForFrac((n - lad.lo) / span);
      canvas.drawLine(
        Offset(spineX - 6, y),
        Offset(spineX + 6, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = 1,
      );
      GameFx.text(canvas, '10${_sup(n)}', Offset(spineX - 34, y), 11,
          Colors.white.withValues(alpha: dim ? 0.25 : 0.5),
          weight: FontWeight.w700);
    }

    // Faint anchors on the right — the scaffold you interpolate between. Hidden
    // near the live answer so they don't give it away.
    for (final a in lad.anchors) {
      if (s.widget.session.isRunning && (a.key - s._trueExp).abs() < 0.8) {
        continue;
      }
      final y = s._yForFrac((a.key - lad.lo) / span);
      canvas.drawLine(
        Offset(spineX + 8, y),
        Offset(spineX + 22, y),
        Paint()
          ..color = _accent.withValues(alpha: 0.14)
          ..strokeWidth = 1,
      );
      GameFx.text(canvas, a.value,
          Offset(spineX + 22 + a.value.length * 3.4, y), 9.5,
          _accent.withValues(alpha: 0.30));
    }
  }

  int _gridStep(double span) {
    final target = span / 8.0;
    for (final c in const [1, 2, 3, 5, 10, 15, 20, 25]) {
      if (c >= target) return c;
    }
    return 30;
  }

  void _drawTimerBar(Canvas canvas, Size size, Color acc) {
    final w = size.width;
    final y = size.height * 0.05;
    final frac = (s._itemT / s._itemTMax).clamp(0.0, 1.0);
    final x0 = w * 0.12, x1 = w * 0.88;
    canvas.drawLine(Offset(x0, y), Offset(x1, y),
        Paint()..color = Colors.white12..strokeWidth = 4);
    final col = frac > 0.5
        ? acc
        : Color.lerp(_bad, _mid, (frac / 0.5).clamp(0, 1))!;
    canvas.drawLine(
      Offset(x0, y),
      Offset(x0 + (x1 - x0) * frac, y),
      Paint()
        ..color = col
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── the live, draggable marker — rides ON the spine (tight grab) ──
  void _drawLiveMarker(
      Canvas canvas, Size size, double spineX, _Ladder lad, Color acc) {
    final y = s._yForExp(s._markerExp);
    final ease = Curves.easeOutBack.transform(s._objDrop.clamp(0, 1));
    final r = 22 * ease.clamp(0.35, 1.0);

    // a soft guide tick across the spine
    canvas.drawLine(
      Offset(spineX - 40, y),
      Offset(spineX + 40, y),
      Paint()
        ..color = acc.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );
    GameFx.orb(canvas, Offset(spineX, y), r, acc.withValues(alpha: 0.9),
        glow: 1.0, specular: false);
    GameFx.text(canvas, s._glyph, Offset(spineX, y), 24 * ease.clamp(0.4, 1),
        Colors.white);

    // live exponent readout under the finger — strong affordance + teaches.
    final eRound = s._markerExp.round();
    GameFx.text(canvas, '10${_sup(eRound)}', Offset(spineX + 64, y), 13,
        s._touched ? acc : Colors.white38, weight: FontWeight.w800);
    if (!s._touched) {
      GameFx.text(canvas, 'drag onto the ladder', Offset(spineX, y + 34), 11,
          Colors.white38);
    }
  }

  // ── fading slide-to-truth ghosts on the rail beside the spine ──
  void _drawReveals(Canvas canvas, double spineX) {
    final rx = spineX + 30;
    for (final rv in s._reveals) {
      final t = Curves.easeOut.transform(rv.age.clamp(0, 1));
      final a = (1 - rv.age).clamp(0.0, 1.0);
      final yDrop = s._yForFrac(rv.fracDrop);
      final yNow = s._yForFrac(rv.fracDrop + (rv.fracTrue - rv.fracDrop) * t);

      // error band from your drop to the truth
      canvas.drawLine(
        Offset(rx, yDrop),
        Offset(rx, yNow),
        Paint()
          ..color = rv.color.withValues(alpha: 0.5 * a)
          ..strokeWidth = 3,
      );
      // your drop (dim)
      canvas.drawCircle(Offset(rx, yDrop), 4,
          Paint()..color = Colors.white.withValues(alpha: 0.30 * a));
      // the truth marker sliding home
      GameFx.orb(canvas, Offset(rx, yNow), 13 * a + 5,
          rv.color.withValues(alpha: a), glow: 1.0, specular: false);
      GameFx.text(canvas, '✓', Offset(rx, yNow), 14,
          Colors.white.withValues(alpha: a), weight: FontWeight.w900);
    }
  }

  void _wrappedFact(Canvas canvas, String text, Offset center, double maxW) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 11.5,
            color: Colors.white38),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawReady(Canvas canvas, Size size) {
    final w = size.width;
    GameFx.text(canvas, 'POWERS OF TEN', Offset(w / 2, size.height * 0.40), 30,
        Colors.white,
        display: true, glow: 0.6);
    GameFx.text(canvas, 'Drop each thing at its order of magnitude',
        Offset(w / 2, size.height * 0.48), 13, Colors.white60);
    GameFx.text(canvas, 'from a grain of sand to the whole cosmos',
        Offset(w / 2, size.height * 0.515), 12, _accent.withValues(alpha: 0.8));
    GameFx.text(canvas, 'starts automatically…',
        Offset(w / 2, size.height * 0.58), 11, Colors.white30);
  }

  @override
  bool shouldRepaint(covariant _PoTV2Painter oldDelegate) => false;
}
