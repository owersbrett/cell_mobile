import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Powers of Ten — "Powers of Ten"  (BioScale.universeAll)
//
// SELF-CONTAINED MODULE. Imports only the framework session (MiniGameSession),
// the shared fx toolkit, the Potatuhs theme, and Flutter — nothing from another
// game. Verb: PLACE-ON-THE-SCALE-LADDER. A thing (quark … observable universe)
// is shown and the player drags a marker to its order of magnitude on a
// logarithmic ladder (size in meters / mass in kg / time in seconds, rotating
// in as difficulty climbs). Closer placement = more points; consecutive close
// drops build a streak.
//
// PERF: one Ticker drives one CustomPainter (repaint:_ctrl). The painter reads
// live state fields every frame; gesture handlers mutate fields. NO per-frame
// setState — the whole play area is a single CustomPaint.
//
// EDUCATION is the mechanic: you interpolate between known anchors (atom 10⁻¹⁰,
// human 10⁰, Earth 10⁷, galaxy 10²¹) printed on the ladder, then the reveal
// shows the true magnitude, the real-world value, and a one-line fact — so every
// drop teaches where a thing sits across the quantum-to-cosmic "powers of ten".
// ═══════════════════════════════════════════════════════════════════════════

// ── Brand-distinct accent (cyan "scientific" — deliberately NOT the everything
//    game's purple/gold). ──
const Color _accent = Color(0xFF22D3EE);
const Color _good = Color(0xFF4CDE80);
const Color _mid = Color(0xFFFFB300);
const Color _bad = Color(0xFFEF5350);

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum _Kind { size, mass, time }

enum _Local { ready, placing, revealing }

/// One thing to place. [exp] is log10 of its true value (may be fractional).
class _PoTItem {
  final String name;
  final String glyph;
  final double exp;
  final String valueLabel;
  final String fact;
  final int tier; // 0 easy (far apart) … 2 hard (close / obscure)
  const _PoTItem(
      this.name, this.glyph, this.exp, this.valueLabel, this.fact, this.tier);
}

const List<_PoTItem> _sizeItems = [
  // tier 0
  _PoTItem('Atom', '⚛️', -10, '≈ 0.1 nm  (10⁻¹⁰ m)',
      'A hydrogen atom is about a ten-billionth of a meter wide.', 0),
  _PoTItem('Human', '🧍', 0, '≈ 1.7 m  (10⁰ m)',
      'We sit almost exactly in the middle of the cosmic size range.', 0),
  _PoTItem('Earth', '🌍', 6.9, '12,742 km  (10⁷ m)',
      "Earth's diameter is about 1.3 × 10⁷ m.", 0),
  _PoTItem('The Sun', '☀️', 9.14, '1.39 million km',
      'The Sun is about 109 Earths wide.', 0),
  _PoTItem('Milky Way', '🌌', 21, '~100,000 light-years',
      'Our galaxy spans roughly 10²¹ m.', 0),
  _PoTItem('Observable Universe', '🌠', 26.94, '~93 billion ly',
      'About 8.8 × 10²⁶ m across — the edge of what we can see.', 0),
  // tier 1
  _PoTItem('Virus', '🦠', -7, '≈ 100 nm', 'A typical virus is ~100 nanometers.',
      1),
  _PoTItem('Bacterium', '🧫', -6, '≈ 1 µm',
      'Most bacteria are about one micrometer long.', 1),
  _PoTItem('Red blood cell', '🩸', -5.15, '≈ 7 µm',
      'Red blood cells are about seven micrometers wide.', 1),
  _PoTItem('Ant', '🐜', -2.3, '≈ 5 mm',
      'A small ant is only a few millimeters long.', 1),
  _PoTItem('Blue whale', '🐋', 1.4, '≈ 25 m',
      'The largest animal ever — up to about 30 m.', 1),
  _PoTItem('Mount Everest', '⛰️', 3.95, '8,849 m tall',
      "Earth's tallest peak rises ~8.8 × 10³ m.", 1),
  // tier 2
  _PoTItem('Proton', '•', -15, '≈ 1 fm',
      'A proton is about one femtometer across.', 2),
  _PoTItem('DNA helix', '🧬', -8.7, '≈ 2 nm wide',
      'The DNA double helix is roughly two nanometers wide.', 2),
  _PoTItem('Grain of sand', '⬤', -3.3, '≈ 0.5 mm',
      'A fine grain of sand is about half a millimeter.', 2),
  _PoTItem('Earth–Sun distance', '🛰️', 11.18, '1 AU ≈ 1.5 × 10¹¹ m',
      'One astronomical unit — about 150 million km.', 2),
  _PoTItem('Solar System', '🪐', 12.65, '~9 × 10¹² m',
      "Out to Neptune's orbit is roughly 10¹³ m.", 2),
  _PoTItem('One light-year', '✨', 15.98, '≈ 9.5 × 10¹⁵ m',
      'The distance light travels in a single year.', 2),
  _PoTItem('Andromeda distance', '🌠', 22.4, '~2.5 × 10²² m',
      'The Andromeda galaxy is ~2.5 million light-years away.', 2),
];

const List<_PoTItem> _massItems = [
  // tier 0
  _PoTItem('Electron', '·', -30.04, '9.1 × 10⁻³¹ kg',
      'The electron is among the lightest known particles.', 0),
  _PoTItem('Human', '🧍', 1.85, '≈ 70 kg', 'A person is around 10² kg.', 0),
  _PoTItem('Earth', '🌍', 24.78, '5.97 × 10²⁴ kg',
      'Earth masses nearly 6 × 10²⁴ kg.', 0),
  _PoTItem('The Sun', '☀️', 30.3, '1.99 × 10³⁰ kg',
      "The Sun holds 99.8% of the Solar System's mass.", 0),
  // tier 1
  _PoTItem('Proton', '•', -26.78, '1.7 × 10⁻²⁷ kg',
      'A proton outweighs an electron about 1,836×.', 1),
  _PoTItem('Water molecule', '💧', -25.52, '≈ 3 × 10⁻²⁶ kg',
      'One H₂O molecule is about 3 × 10⁻²⁶ kg.', 1),
  _PoTItem('Apple', '🍎', -0.8, '≈ 150 g',
      'A medium apple is around 0.15 kg.', 1),
  _PoTItem('Car', '🚗', 3.2, '≈ 1.5 t', 'A car masses around 1,500 kg.', 1),
  _PoTItem('Blue whale', '🐋', 5.18, '≈ 150 t',
      'The heaviest animal — up to ~1.5 × 10⁵ kg.', 1),
  // tier 2
  _PoTItem('Bacterium', '🧫', -15, '≈ 10⁻¹⁵ kg',
      'A single bacterium masses about a femtogram.', 2),
  _PoTItem('Grain of sand', '⬤', -6, '≈ 1 mg',
      'A grain of sand is roughly a milligram.', 2),
  _PoTItem('Mountain', '⛰️', 15, '~10¹⁵ kg',
      'A large mountain masses on the order of 10¹⁵ kg.', 2),
  _PoTItem('Milky Way', '🌌', 42, '~10⁴² kg',
      'Our galaxy is on the order of 10⁴² kg.', 2),
  _PoTItem('Observable Universe', '🌠', 53, '~10⁵³ kg',
      'All ordinary matter totals roughly 10⁵³ kg.', 2),
];

const List<_PoTItem> _timeItems = [
  // tier 0
  _PoTItem('Heartbeat', '❤️', -0.07, '≈ 0.85 s',
      'A resting heartbeat is just under a second.', 0),
  _PoTItem('One day', '🌞', 4.94, '86,400 s',
      'A day is about 8.6 × 10⁴ seconds.', 0),
  _PoTItem('One year', '📅', 7.5, '≈ 3.2 × 10⁷ s',
      'A year is roughly 3 × 10⁷ seconds.', 0),
  _PoTItem('Human lifetime', '⏳', 9.4, '≈ 2.5 × 10⁹ s',
      'About 80 years is ~2.5 billion seconds.', 0),
  _PoTItem('Age of Universe', '🌌', 17.64, '13.8 billion yr',
      'The universe is ~4.4 × 10¹⁷ s old.', 0),
  // tier 1
  _PoTItem('Camera flash', '📸', -3, '≈ 1 ms',
      'A camera flash lasts about a millisecond.', 1),
  _PoTItem('Blink of an eye', '👁️', -0.8, '≈ 0.15 s',
      'A blink takes about 150 milliseconds.', 1),
  _PoTItem('Since the dinosaurs', '🦖', 15.32, '~2 × 10¹⁵ s',
      'Non-bird dinosaurs died out ~66 million years ago.', 1),
  // tier 2
  _PoTItem('Muon lifetime', '⏱️', -5.66, '≈ 2.2 µs',
      'A muon survives about 2.2 microseconds before decaying.', 2),
  _PoTItem('One nanosecond', '⚡', -9, '10⁻⁹ s',
      'Light travels only ~30 cm in a nanosecond.', 2),
  _PoTItem('Light crosses a proton', '•', -23.6, '~10⁻²⁴ s',
      'A yoctosecond — light barely crosses a single proton.', 2),
  _PoTItem('Age of the Earth', '🪨', 17.15, '~1.4 × 10¹⁷ s',
      'Earth formed about 4.5 billion years ago.', 2),
];

class _Ladder {
  final double lo, hi;
  final String unit;
  final List<MapEntry<double, String>> anchors;
  const _Ladder(this.lo, this.hi, this.unit, this.anchors);
}

const _Ladder _sizeLadder = _Ladder(-18, 27, 'meters', [
  MapEntry(-10, 'atom'),
  MapEntry(0, 'human'),
  MapEntry(7, 'Earth'),
  MapEntry(16, 'light-yr'),
  MapEntry(21, 'galaxy'),
]);
const _Ladder _massLadder = _Ladder(-31, 54, 'kilograms', [
  MapEntry(-30, 'electron'),
  MapEntry(2, 'human'),
  MapEntry(24.8, 'Earth'),
  MapEntry(30, 'Sun'),
  MapEntry(42, 'galaxy'),
]);
const _Ladder _timeLadder = _Ladder(-24, 18, 'seconds', [
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

List<_PoTItem> _poolFor(_Kind k) {
  switch (k) {
    case _Kind.size:
      return _sizeItems;
    case _Kind.mass:
      return _massItems;
    case _Kind.time:
      return _timeItems;
  }
}

String _kindLabel(_Kind k) {
  switch (k) {
    case _Kind.size:
      return 'SIZE · meters';
    case _Kind.mass:
      return 'MASS · kilograms';
    case _Kind.time:
      return 'TIME · seconds';
  }
}

// Unicode superscript for "10ⁿ" gridline labels.
const Map<String, String> _supDigits = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
};
String _sup(int n) =>
    n.toString().split('').map((c) => _supDigits[c] ?? c).join();

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PowersOfTenGame extends StatefulWidget {
  final MiniGameSession session;
  const PowersOfTenGame({super.key, required this.session});

  @override
  State<PowersOfTenGame> createState() => _PowersOfTenGameState();
}

class _PowersOfTenGameState extends State<PowersOfTenGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  double _clock = 0; // seconds, drives atmosphere drift
  double _lastWall = 0;
  bool _started = false;

  // ── game state ──
  _Local _local = _Local.ready;
  _Kind _kind = _Kind.size;
  _PoTItem? _current;
  int _round = 0;
  double _markerExp = 0; // player-controlled
  double _objDrop = 0; // 0→1 entrance ease for a new item

  // ── reveal snapshot ──
  double _revealT = 0;
  double _lastTrueExp = 0;
  double _lastMarkerExp = 0;
  double _lastError = 0;
  int _lastPts = 0;
  String _lastVerdict = '';

  int _streak = 0;

  // ── juice ──
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // Painter writes the latest canvas size here so gesture handlers can map.
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastWall = _now();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── difficulty ramp (education accelerates: tighter tolerance, harder &
  //    more varied things) ──
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

  double get _band => (8 - _round * 0.3).clamp(3.5, 8.0);
  double get _perfectTol => (0.5 - _round * 0.015).clamp(0.22, 0.5);
  double get _goodTol => (1.6 - _round * 0.05).clamp(0.8, 1.6);
  double get _revealDur => (1.05 - _round * 0.03).clamp(0.6, 1.05);

  // ── ladder geometry (shared by painter + gesture mapping) ──
  double get _ladTop => _lastSize.height * 0.18;
  double get _ladBot => _lastSize.height * 0.86;

  double _yForExp(double e) {
    final lad = _ladderFor(_kind);
    final f = (e - lad.lo) / (lad.hi - lad.lo);
    return _ladBot - f * (_ladBot - _ladTop);
  }

  double _expForY(double y) {
    final lad = _ladderFor(_kind);
    final f = (_ladBot - y) / (_ladBot - _ladTop);
    return lad.lo + f * (lad.hi - lad.lo);
  }

  void _loadItem() {
    final kinds = _allowedKinds;
    final kind = kinds[_rng.nextInt(kinds.length)];
    final prev = _current?.name;
    final pool = _poolFor(kind)
        .where((it) => it.tier <= _maxTier && it.name != prev)
        .toList();
    _kind = kind;
    _current = pool[_rng.nextInt(pool.length)];
    final lad = _ladderFor(kind);
    _markerExp = (lad.lo + lad.hi) / 2;
    _objDrop = 0;
    _local = _Local.placing;
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    _clock += dt;

    // Advance juice every frame (cheap; painter repaints via _ctrl).
    for (final p in _particles) {
      p.step(dt);
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (_objDrop < 1) _objDrop = math.min(1, _objDrop + dt / 0.28);

    // Auto-start when the host enters the playing phase.
    if (widget.session.isRunning && !_started) {
      _started = true;
      _round = 0;
      _loadItem();
    }
    if (!widget.session.isRunning) return;

    if (_local == _Local.revealing) {
      _revealT += dt / _revealDur;
      if (_revealT >= 1) {
        _round++;
        _loadItem();
      }
    }
  }

  // ── interaction ──
  void _grab(Offset p) {
    if (!widget.session.isRunning || _local != _Local.placing) return;
    final lad = _ladderFor(_kind);
    _markerExp = _expForY(p.dy).clamp(lad.lo, lad.hi);
  }

  void _move(Offset p) {
    if (_local != _Local.placing) return;
    final lad = _ladderFor(_kind);
    _markerExp = _expForY(p.dy).clamp(lad.lo, lad.hi);
  }

  void _drop() {
    if (_local != _Local.placing || _current == null) return;
    final trueExp = _current!.exp;
    final error = (_markerExp - trueExp).abs();
    final band = _band;
    final acc = (1 - error / band).clamp(0.0, 1.0);
    int pts = (100 * acc).round();
    String verdict;
    if (error <= _perfectTol) {
      pts += 50;
      verdict = 'PERFECT';
    } else if (error <= _goodTol) {
      verdict = 'CLOSE';
    } else if (acc > 0) {
      verdict = 'OK';
    } else {
      verdict = 'OFF';
    }
    if (error <= _goodTol) {
      _streak++;
    } else {
      _streak = 0;
    }

    widget.session.addScore(pts);
    widget.session.noteStreak(_streak);

    _lastTrueExp = trueExp;
    _lastMarkerExp = _markerExp;
    _lastError = error;
    _lastPts = pts;
    _lastVerdict = verdict;

    // juice at the marker
    final mx = _lastSize.width * 0.42;
    final my = _yForExp(_markerExp);
    final col = _accForColor(acc);
    _pops.add(FxPop(Offset(mx, my - 8), '+$pts', col));
    if (error <= _goodTol) {
      _particles.addAll(FxBurst.spawn(Offset(mx, my), col,
          count: error <= _perfectTol ? 18 : 10, speed: 130));
    }

    _revealT = 0;
    _local = _Local.revealing;
  }

  void _release() {
    if (_local != _Local.placing) return;
    _drop();
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
      onTapUp: (_) => _release(),
      onPanDown: (d) => _grab(d.localPosition),
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _release(),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PoTPainter(this, _ctrl),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — draws the entire play area; repaints every frame via _ctrl.
// ---------------------------------------------------------------------------

class _PoTPainter extends CustomPainter {
  final _PowersOfTenGameState s;
  _PoTPainter(this.s, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    s._lastSize = size;
    final w = size.width;
    GameFx.atmosphere(canvas, size, _accent, s._clock, motes: 30);

    final lad = _ladderFor(s._kind);
    final ladX = w * 0.30;

    _drawLadder(canvas, size, lad, ladX);

    final item = s._current;
    if (item == null || s._local == _Local.ready || !s.widget.session.isRunning) {
      _drawReady(canvas, size);
      _drawParticles(canvas);
      return;
    }

    // Prompt banner.
    GameFx.text(canvas, '${item.glyph}  ${item.name}',
        Offset(w / 2, size.height * 0.075), 22, Colors.white,
        weight: FontWeight.w800, glow: 0.5);
    GameFx.text(
        canvas,
        s._local == _Local.placing
            ? 'drag onto the ladder · release to drop'
            : '',
        Offset(w / 2, size.height * 0.115),
        12,
        Colors.white54);

    // Kind + streak chips (kept inner, away from host's score/timer corners).
    GameFx.text(canvas, _kindLabel(s._kind), Offset(w / 2, size.height * 0.145),
        11, _accent.withValues(alpha: 0.85), weight: FontWeight.w700);
    if (s._streak >= 2) {
      GameFx.text(canvas, '🔥 ${s._streak} streak',
          Offset(w / 2, size.height * 0.92), 13, _good, weight: FontWeight.w700);
    }

    if (s._local == _Local.placing) {
      _drawMarker(canvas, size, ladX, s._markerExp, item.glyph, true, _accent);
    } else {
      _drawReveal(canvas, size, ladX, item);
    }

    _drawParticles(canvas);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  // ── ladder line + decade gridlines + filtered anchors ──
  void _drawLadder(Canvas canvas, Size size, _Ladder lad, double ladX) {
    final top = s._ladTop;
    final bot = s._ladBot;
    final span = lad.hi - lad.lo;
    final dim = s._local == _Local.ready;

    // spine
    canvas.drawLine(
      Offset(ladX, top),
      Offset(ladX, bot),
      Paint()
        ..color = Colors.white.withValues(alpha: dim ? 0.12 : 0.22)
        ..strokeWidth = 2,
    );

    final step = _gridStep(span);
    final startN = (lad.lo / step).ceil() * step;
    for (int n = startN; n <= lad.hi + 0.001; n += step) {
      final y = s._yForExp(n.toDouble());
      canvas.drawLine(
        Offset(ladX - 6, y),
        Offset(ladX + 6, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 1,
      );
      GameFx.text(canvas, '10${_sup(n)}', Offset(ladX - 30, y), 12,
          Colors.white.withValues(alpha: dim ? 0.25 : 0.55),
          weight: FontWeight.w700);
    }
    // unit caption at the top of the spine
    GameFx.text(canvas, lad.unit, Offset(ladX, top - 14), 10,
        Colors.white.withValues(alpha: 0.4));

    // Faint named anchors on the right — the scaffold you interpolate between.
    // Hidden if they'd give away the current item.
    final cur = s._current;
    for (final a in lad.anchors) {
      if (cur != null && (a.key - cur.exp).abs() < 0.6) continue;
      final y = s._yForExp(a.key);
      canvas.drawLine(
        Offset(ladX, y),
        Offset(ladX + 16, y),
        Paint()
          ..color = _accent.withValues(alpha: 0.14)
          ..strokeWidth = 1,
      );
      GameFx.text(canvas, a.value, Offset(ladX + 16 + a.value.length * 3.2, y),
          9.5, _accent.withValues(alpha: 0.30));
    }
  }

  int _gridStep(double span) {
    final target = span / 8.0;
    for (final c in const [1, 2, 3, 5, 10, 15, 20, 25]) {
      if (c >= target) return c;
    }
    return 30;
  }

  // ── draggable marker carrying the thing ──
  void _drawMarker(Canvas canvas, Size size, double ladX, double exp,
      String glyph, bool active, Color color) {
    final y = s._yForExp(exp);
    final w = size.width;
    final ease = Curves.easeOutBack.transform(s._objDrop.clamp(0, 1));
    final gx = w * 0.42 + (1 - ease) * 40;

    // guide line across the ladder
    canvas.drawLine(
      Offset(ladX, y),
      Offset(gx, y),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    // handle triangle on the spine
    final path = Path()
      ..moveTo(ladX, y)
      ..lineTo(ladX + 12, y - 7)
      ..lineTo(ladX + 12, y + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // the thing, riding a soft disc
    GameFx.orb(canvas, Offset(gx, y), 22 * ease.clamp(0.3, 1),
        color.withValues(alpha: 0.85),
        glow: 1.0, specular: false);
    GameFx.text(canvas, glyph, Offset(gx, y), 24 * ease.clamp(0.4, 1),
        Colors.white);
  }

  // ── reveal: marker vs. truth, error band, value + fact ──
  void _drawReveal(Canvas canvas, Size size, double ladX, _PoTItem item) {
    final w = size.width;
    final t = Curves.easeOut.transform(s._revealT.clamp(0, 1));
    final acc = (1 - s._lastError / s._band).clamp(0.0, 1.0);
    final col = s._accForColor(acc.toDouble());

    final yMark = s._yForExp(s._lastMarkerExp);
    // truth slides from the dropped position to the real position
    final yTrue =
        s._yForExp(s._lastMarkerExp + (s._lastTrueExp - s._lastMarkerExp) * t);
    final gx = w * 0.42;

    // error band between your drop and the truth
    canvas.drawLine(
      Offset(gx, yMark),
      Offset(gx, yTrue),
      Paint()
        ..color = col.withValues(alpha: 0.5)
        ..strokeWidth = 3,
    );

    // your drop (dimmed)
    canvas.drawLine(Offset(ladX, yMark), Offset(gx, yMark),
        Paint()..color = Colors.white24..strokeWidth = 1);
    GameFx.text(canvas, item.glyph, Offset(gx, yMark), 18, Colors.white54);

    // the truth marker
    canvas.drawLine(
      Offset(ladX, yTrue),
      Offset(gx, yTrue),
      Paint()
        ..color = col
        ..strokeWidth = 2,
    );
    GameFx.orb(canvas, Offset(gx, yTrue), 20, col, glow: 1.2, specular: false);
    GameFx.text(canvas, '✓', Offset(gx, yTrue), 20, Colors.white,
        weight: FontWeight.w900);

    // verdict + decades-off
    final off = s._lastError;
    GameFx.text(
        canvas,
        '${s._lastVerdict}   ·   +${s._lastPts}',
        Offset(w / 2, size.height * 0.155),
        18,
        col,
        weight: FontWeight.w800,
        glow: 0.6);
    GameFx.text(
        canvas,
        off < 0.5
            ? 'right on the money'
            : '${off.toStringAsFixed(1)} decades off',
        Offset(w / 2, size.height * 0.185),
        12,
        Colors.white54);

    // value + fact (the lesson)
    GameFx.text(canvas, item.valueLabel, Offset(w / 2, size.height * 0.94), 14,
        Colors.white, weight: FontWeight.w700);
    _wrappedFact(canvas, item.fact, Offset(w / 2, size.height * 0.975), w - 48);
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
    GameFx.text(
        canvas,
        'Drag each thing to its size on the ladder',
        Offset(w / 2, size.height * 0.48),
        13,
        Colors.white60);
    GameFx.text(canvas, 'from a quark to the whole universe',
        Offset(w / 2, size.height * 0.515), 12, _accent.withValues(alpha: 0.8));
    GameFx.text(canvas, 'starts automatically…', Offset(w / 2, size.height * 0.58),
        11, Colors.white30);
  }

  void _drawParticles(Canvas canvas) {
    FxBurst.paint(canvas, s._particles);
  }

  @override
  bool shouldRepaint(covariant _PoTPainter oldDelegate) => false;
}
