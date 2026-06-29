import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Bond Lab v2 — a UX-passed rebuild of `bond_lab`.
//
// Same lesson: ionic = metal + nonmetal (transfer), covalent = two nonmetals
// (share), metallic = two metals (electron sea). What changed, per the teardown:
//
//  • THE ANSWER WAS PRINTED ON THE ATOMS. v1 rendered a literal METAL / NONMETAL
//    tag, so the optimal play was tag-matching — no chemistry. v2 HIDES the tag.
//    Each atom shows only its symbol + electronegativity (EN), plotted on a live
//    EN ruler with the 2.0 metal/nonmetal divide marked. You must READ the EN to
//    judge each atom's character — EN is now load-bearing, not decoration.
//  • EN WAS DEAD DATA. v1 ignored EN entirely. v2 adds a real decision axis built
//    ON EN: covalent splits into POLAR vs NONPOLAR by the EN GAP (ΔEN ≥ 0.5 =
//    polar). So the famous trap — HF (ΔEN 1.78, looks ionic) — is now POLAR
//    COVALENT, because both atoms sit above 2.0 (nonmetals share, even with a big
//    gap). The gap is the genuine read, not a freebie. Four answers, not three.
//  • SHALLOW + REFLEXY. v2 rewards speed-under-uncertainty (a draining speed
//    bonus) and a capped streak, so chemistry beats thumb-speed.
//  • RUNAWAY / FLAT. v1's +2s/correct let a leader stretch their own clock. v2
//    uses a FIXED host clock (no addTime) for comparable scores, plus a last-8s
//    FINAL SURGE ×2 for a shared, readable climax. Difficulty ramps clear →
//    subtle → trap as the round accelerates.
//
// Perf contract: one Ticker → one CustomPainter. Host owns the clock, countdown,
// score HUD and results; this widget renders ONLY the play area + answer buttons,
// and re-arms a fresh run from session.isRunning.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kAccent = Color(0xFF7E57C2); // deep violet — bond_lab identity
const Color _kElectron = Color(0xFF8CF1FF); // bright electron spark
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kGold = Color(0xFFFFD54F);

const double _kAtomR = 36;
const double _kMetalCutoff = 2.0; // EN < 2.0 ⇒ metal, > 2.0 ⇒ nonmetal
const double _kPolarCutoff = 0.5; // ΔEN ≥ 0.5 ⇒ polar covalent
const double _kEnMin = 0.8; // EN ruler bounds
const double _kEnMax = 4.0;

// Scoring — fixed per-event (capped streak, no addTime → no runaway leader).
const int _kCorrect = 10; // base per correct classification
const int _kSpeedMax = 10; // max speed bonus, drains over _kSpeedWindow
const double _kSpeedWindow = 3.5; // seconds before the speed bonus hits 0
const int _kStreakCap = 8; // streak bonus is capped → scores stay comparable
const int _kWrong = -5;
const double _kResultDur = 1.30; // correct-answer celebration window
const double _kWrongDur = 1.95; // wrong window — longer, to read the correction
const int _kSurgeMs = 8000; // last 8s: all gains ×2 (the climax)

enum _Class { ionic, polar, nonpolar, metallic }

String _className(_Class c) => switch (c) {
      _Class.ionic => 'IONIC',
      _Class.polar => 'POLAR',
      _Class.nonpolar => 'NONPOLAR',
      _Class.metallic => 'METALLIC',
    };

String _classSub(_Class c) => switch (c) {
      _Class.ionic => 'metal → nonmetal · transfer',
      _Class.polar => 'two nonmetals · uneven share',
      _Class.nonpolar => 'two nonmetals · even share',
      _Class.metallic => 'two metals · electron sea',
    };

Color _classColor(_Class c) => switch (c) {
      _Class.ionic => const Color(0xFFFF7043), // orange — transfer
      _Class.polar => const Color(0xFF29B6F6), // blue — uneven
      _Class.nonpolar => const Color(0xFF66BB6A), // green — even
      _Class.metallic => const Color(0xFFE1C916), // gold — sea
    };

/// The corrective lesson shown when the player misses — names the misconception.
String _classRule(_Class c) => switch (c) {
      _Class.ionic => 'metal (EN<2.0) + nonmetal → it TRANSFERS',
      _Class.polar => 'two nonmetals, big ΔEN → still SHARES (polar)',
      _Class.nonpolar => 'two nonmetals, small ΔEN → even SHARE',
      _Class.metallic => 'two metals (EN<2.0) → electron SEA',
    };

// ── Element + pair data (KEEP: clean EN split, real compounds) ───────────────
class _El {
  final String sym;
  final String name;
  final double en; // Pauling electronegativity — THE read
  const _El(this.sym, this.name, this.en);
  bool get metal => en < _kMetalCutoff;
}

// Clean EN split: every metal < 2.0, every nonmetal > 2.0 — so EN alone decides
// character. This is load-bearing; do not add metalloids (Si, B) without a spec
// change (they'd straddle the 2.0 divide and break the binary read).
const List<_El> _els = [
  _El('Na', 'Sodium', 0.93), // 0
  _El('K', 'Potassium', 0.82), // 1
  _El('Li', 'Lithium', 0.98), // 2
  _El('Ca', 'Calcium', 1.00), // 3
  _El('Mg', 'Magnesium', 1.31), // 4
  _El('Al', 'Aluminium', 1.61), // 5
  _El('Fe', 'Iron', 1.83), // 6
  _El('Cu', 'Copper', 1.90), // 7 — borderline metal (just under 2.0)
  _El('Cl', 'Chlorine', 3.16), // 8
  _El('O', 'Oxygen', 3.44), // 9
  _El('F', 'Fluorine', 3.98), // 10
  _El('H', 'Hydrogen', 2.20), // 11
  _El('N', 'Nitrogen', 3.04), // 12
  _El('C', 'Carbon', 2.55), // 13
  _El('S', 'Sulfur', 2.58), // 14
  _El('Br', 'Bromine', 2.96), // 15
];

class _Pair {
  final int a;
  final int b;
  final String compound; // what forms when classified correctly
  final int tier; // 0 = clear, 1 = subtle, 2 = trap/borderline
  const _Pair(this.a, this.b, this.compound, this.tier);

  _El get el0 => _els[a];
  _El get el1 => _els[b];

  double get gap => (el0.en - el1.en).abs();

  /// Derived (never authored): character from EN, then polarity from ΔEN.
  _Class get cls {
    final m0 = el0.metal, m1 = el1.metal;
    if (m0 && m1) return _Class.metallic;
    if (m0 != m1) return _Class.ionic;
    return gap >= _kPolarCutoff ? _Class.polar : _Class.nonpolar;
  }

  /// Index of the more electronegative atom (the δ− end of a polar bond).
  bool get rightIsMoreEN => el1.en >= el0.en;
}

const List<_Pair> _pairs = [
  // ── Tier 0: clear ──
  _Pair(0, 8, 'NaCl · table salt', 0),
  _Pair(1, 8, 'KCl', 0),
  _Pair(2, 10, 'LiF', 0),
  _Pair(0, 10, 'NaF', 0),
  _Pair(3, 9, 'CaO · quicklime', 0),
  _Pair(4, 9, 'MgO', 0),
  _Pair(9, 9, 'O₂', 0),
  _Pair(12, 12, 'N₂', 0),
  _Pair(8, 8, 'Cl₂', 0),
  _Pair(11, 11, 'H₂', 0),
  _Pair(15, 15, 'Br₂', 0),
  _Pair(0, 0, 'Na lattice', 0),
  _Pair(7, 7, 'Cu lattice', 0),
  _Pair(6, 6, 'Fe lattice', 0),
  _Pair(5, 5, 'Al lattice', 0),
  _Pair(1, 1, 'K lattice', 0),
  // ── Tier 1: subtle ──
  _Pair(1, 15, 'KBr', 1),
  _Pair(5, 8, 'AlCl₃', 1),
  _Pair(3, 8, 'CaCl₂', 1),
  _Pair(5, 9, 'Al₂O₃ · alumina', 1),
  _Pair(6, 9, 'FeO · rust', 1),
  _Pair(7, 9, 'CuO', 1),
  _Pair(4, 12, 'Mg₃N₂', 1),
  _Pair(13, 11, 'CH₄ · methane', 1), // ΔEN 0.35 → nonpolar
  _Pair(11, 8, 'HCl', 1), // ΔEN 0.96 → polar
  _Pair(11, 9, 'H₂O · water', 1), // ΔEN 1.24 → polar
  _Pair(12, 11, 'NH₃ · ammonia', 1), // ΔEN 0.84 → polar
  _Pair(13, 9, 'CO₂', 1), // ΔEN 0.89 → polar
  _Pair(14, 9, 'SO₂', 1), // ΔEN 0.86 → polar
  _Pair(7, 6, 'Cu·Fe alloy', 1),
  _Pair(7, 5, 'Cu·Al alloy', 1),
  _Pair(6, 5, 'Fe·Al alloy', 1),
  _Pair(4, 5, 'Mg·Al alloy', 1),
  // ── Tier 2: traps + borderline ──
  _Pair(11, 10, 'HF', 2), // ΔEN 1.78 — big gap, but BOTH nonmetal → polar
  _Pair(8, 10, 'ClF', 2), // ΔEN 0.82 → polar
  _Pair(15, 10, 'BrF', 2), // ΔEN 1.02 → polar
  _Pair(15, 8, 'BrCl', 2), // ΔEN 0.20 → nonpolar (interhalogen)
  _Pair(13, 14, 'CS₂', 2), // ΔEN 0.03 → nonpolar
  _Pair(6, 8, 'FeCl₃', 2), // Fe 1.83 — borderline metal → ionic
  _Pair(7, 8, 'CuCl₂', 2), // Cu 1.90 — borderline metal → ionic
];

// ── Game widget ─────────────────────────────────────────────────────────────
class BondLabV2Game extends StatefulWidget {
  final MiniGameSession session;
  const BondLabV2Game({super.key, required this.session});

  @override
  State<BondLabV2Game> createState() => _BondLabV2GameState();
}

class _BondLabV2GameState extends State<BondLabV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (idle shimmer, electron orbits)
  double _elapsed = 0; // advances only while running (difficulty ramp)
  bool _started = false; // re-arms a fresh run from isRunning

  late _Pair _pair;
  int _streak = 0;
  double _qTime = 0; // seconds on the current question (speed bonus)

  /// -1 while accepting input; otherwise seconds since the answer was given.
  double _transition = -1;
  _Class? _chosen;
  bool _lastCorrect = false;

  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  Size _fieldSize = const Size(360, 640);

  @override
  void initState() {
    super.initState();
    _pair = _pairs[_rng.nextInt(_pairs.length)];
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration now) {
    final dt =
        ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = now;
    _clock += dt;

    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        _resetRun();
      }
      _elapsed += dt;
      if (_transition >= 0) {
        _transition += dt;
        final dur = _lastCorrect ? _kResultDur : _kWrongDur;
        if (_transition >= dur) _next();
      } else {
        _qTime += dt;
      }
    } else {
      _started = false; // re-arm for the next fresh run
    }

    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    if (mounted) setState(() {});
  }

  void _resetRun() {
    _elapsed = 0;
    _streak = 0;
    _qTime = 0;
    _transition = -1;
    _chosen = null;
    _particles.clear();
    _pops.clear();
    _pair = _pairs.firstWhere((p) => p.tier == 0);
  }

  // ── geometry ──
  double get _atomY => _fieldSize.height * 0.36;
  Offset get _leftCenter => Offset(_fieldSize.width * 0.30, _atomY);
  Offset get _rightCenter => Offset(_fieldSize.width * 0.70, _atomY);
  Offset get _mid => Offset.lerp(_leftCenter, _rightCenter, 0.5)!;

  /// In an ionic pair, the metal (lower EN) donates the electron.
  bool get _leftIsDonor => _pair.el0.metal;

  double get _difficulty {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return (_elapsed / dur).clamp(0.0, 1.0);
  }

  bool get _surge {
    final ms = widget.session.remaining.inMilliseconds;
    return widget.session.isRunning && ms > 0 && ms <= _kSurgeMs;
  }

  void _next() {
    final d = _difficulty;
    final x = _rng.nextDouble();
    int tier;
    if (x < 0.6 - 0.5 * d) {
      tier = 0;
    } else if (x < 1.0 - 0.35 * d) {
      tier = 1;
    } else {
      tier = 2;
    }
    var pool = _pairs.where((p) => p.tier == tier).toList();
    if (pool.isEmpty) pool = _pairs;
    _Pair p;
    var guard = 0;
    do {
      p = pool[_rng.nextInt(pool.length)];
      guard++;
    } while (p.compound == _pair.compound && guard < 8);
    _pair = p;
    _transition = -1;
    _chosen = null;
    _qTime = 0;
  }

  void _choose(_Class c) {
    if (!widget.session.isRunning || _transition >= 0) return;
    _chosen = c;
    _lastCorrect = c == _pair.cls;
    _transition = 0;

    if (_lastCorrect) {
      _streak++;
      final speedFrac = (1 - _qTime / _kSpeedWindow).clamp(0.0, 1.0);
      final speedBonus = (speedFrac * _kSpeedMax).round();
      final streakBonus = _streak < _kStreakCap ? _streak : _kStreakCap;
      var gain = _kCorrect + speedBonus + streakBonus;
      if (_surge) gain *= 2;
      widget.session.addScore(gain);
      widget.session.noteStreak(_streak);
      _pops.add(FxPop(
          _mid.translate(0, -_kAtomR - 20), '+$gain', _kGold));
      _particles.addAll(FxBurst.spawn(_mid, _kAccent, count: 18, speed: 150));
      _particles.addAll(FxBurst.spawn(_leftCenter, _kElectron, count: 8));
      _particles.addAll(FxBurst.spawn(_rightCenter, _kElectron, count: 8));
    } else {
      _streak = 0;
      widget.session.addScore(_kWrong);
      _pops.add(FxPop(
          _mid.translate(0, -_kAtomR - 20), '$_kWrong', _kBad));
    }
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BondV2Painter(this),
                size: Size.infinite,
              ),
            ),
            // Answer grid: 2×2. Row 1 = type extremes, Row 2 = covalent split.
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: _bondButton(_Class.ionic)),
                    const SizedBox(width: 10),
                    Expanded(child: _bondButton(_Class.metallic)),
                  ]),
                  const SizedBox(height: 6),
                  Text('— covalent: how evenly shared? —',
                      style: Potatuhs.label(
                          size: 9, color: Potatuhs.textFaint)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: _bondButton(_Class.polar)),
                    const SizedBox(width: 10),
                    Expanded(child: _bondButton(_Class.nonpolar)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _bondButton(_Class c) {
    final running = widget.session.isRunning;
    final resolving = _transition >= 0;
    final isChosen = resolving && _chosen == c;
    final isCorrect = resolving && _pair.cls == c;
    final col = _classColor(c);

    Color border = col.withValues(alpha: running ? 0.55 : 0.22);
    Color fill = Colors.black.withValues(alpha: 0.42);
    if (isCorrect) {
      border = _kGood;
      fill = _kGood.withValues(alpha: 0.16);
    } else if (isChosen && !isCorrect) {
      border = _kBad;
      fill = _kBad.withValues(alpha: 0.16);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _choose(c),
      child: Opacity(
        opacity: running ? 1.0 : 0.5,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.6),
            boxShadow: (isCorrect || isChosen)
                ? [BoxShadow(color: border.withValues(alpha: 0.4), blurRadius: 14)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_className(c),
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                      size: 14, weight: FontWeight.w800, color: col)),
              const SizedBox(height: 2),
              Text(_classSub(c),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Potatuhs.body(
                      size: 8.5,
                      weight: FontWeight.w600,
                      color: Potatuhs.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painter ─────────────────────────────────────────────────────────────────
class _BondV2Painter extends CustomPainter {
  final _BondLabV2GameState g;
  _BondV2Painter(this.g) : super(repaint: g.widget.session);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 24);

    final running = g.widget.session.isRunning;
    final resolving = g._transition >= 0;

    _paintPrompt(canvas, size, running, resolving);
    if (running || resolving) {
      _paintRuler(canvas, size);
      _paintBond(canvas);
      _paintAtoms(canvas, resolving);
      if (resolving) _paintReveal(canvas, size);
      if (!resolving) _paintSpeedMeter(canvas, size);
    }
    if (g._surge) _paintSurge(canvas, size);

    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }
  }

  void _paintPrompt(Canvas canvas, Size size, bool running, bool resolving) {
    if (!running && g._transition < 0) {
      GameFx.text(canvas, 'BOND LAB v2', Offset(size.width / 2, size.height * 0.30),
          26, _kAccent.withValues(alpha: 0.9),
          display: true, weight: FontWeight.w800, glow: 0.5);
      GameFx.text(
          canvas,
          'Read electronegativity · pick the bond',
          Offset(size.width / 2, size.height * 0.30 + 30),
          13,
          Potatuhs.textSecondary);
      return;
    }
    if (resolving) return;
    GameFx.text(canvas, 'WHICH BOND FORMS?',
        Offset(size.width / 2, size.height * 0.075), 15, Potatuhs.textSecondary,
        weight: FontWeight.w800);
  }

  /// The live EN axis — the genuine read. Atoms are plotted by their EN; the 2.0
  /// divide tells metal (left) from nonmetal (right). The GAP between the two
  /// dots is what the player must judge for polar vs nonpolar.
  void _paintRuler(Canvas canvas, Size size) {
    final y = size.height * 0.165;
    final x0 = size.width * 0.10, x1 = size.width * 0.90;
    double px(double en) =>
        x0 + (x1 - x0) * ((en - _kEnMin) / (_kEnMax - _kEnMin)).clamp(0.0, 1.0);

    // Axis line.
    canvas.drawLine(Offset(x0, y), Offset(x1, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 2);
    // Metal/nonmetal divide at 2.0.
    final dx = px(_kMetalCutoff);
    canvas.drawLine(Offset(dx, y - 12), Offset(dx, y + 12),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1.4);
    GameFx.text(canvas, 'EN 2.0', Offset(dx, y - 22), 9,
        Colors.white.withValues(alpha: 0.55));
    GameFx.text(canvas, 'metal', Offset((x0 + dx) / 2, y + 22), 9,
        const Color(0xFFE1C916).withValues(alpha: 0.6),
        weight: FontWeight.w700);
    GameFx.text(canvas, 'nonmetal', Offset((dx + x1) / 2, y + 22), 9,
        const Color(0xFF29B6F6).withValues(alpha: 0.6),
        weight: FontWeight.w700);

    // The two atom dots on the axis.
    for (var i = 0; i < 2; i++) {
      final el = i == 0 ? g._pair.el0 : g._pair.el1;
      final at = Offset(px(el.en), y);
      canvas.drawCircle(at, 6,
          Paint()..color = _kElectron.withValues(alpha: 0.9));
      canvas.drawCircle(at, 6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.8));
      GameFx.text(canvas, el.sym, at.translate(0, -16), 11, Colors.white,
          weight: FontWeight.w800);
    }
  }

  void _paintBond(Canvas canvas) {
    if (g._transition < 0 || !g._lastCorrect) return;
    final t = g._transition;
    final l = g._leftCenter, r = g._rightCenter, mid = g._mid;

    switch (g._pair.cls) {
      case _Class.ionic:
        final from = g._leftIsDonor ? l : r;
        final to = g._leftIsDonor ? r : l;
        final p = (t / (_kResultDur * 0.5)).clamp(0.0, 1.0);
        final pos = Offset.lerp(from, to, Curves.easeInOut.transform(p))!;
        if (p >= 1) {
          GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.5), width: 2);
        }
        _electron(canvas, pos, glow: 1.0);
        break;
      case _Class.polar:
        // Shared pair, but pulled toward the more electronegative atom (δ−).
        GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.45), width: 2);
        final bias = g._pair.rightIsMoreEN ? 0.22 : -0.22;
        final orbit = Offset.lerp(l, r, 0.5 + bias)!;
        for (var i = 0; i < 2; i++) {
          final a = g._clock * 3.4 + i * math.pi;
          _electron(canvas, orbit + Offset(math.cos(a) * 24, math.sin(a) * 11),
              glow: 0.9);
        }
        break;
      case _Class.nonpolar:
        // Shared pair centered — shared evenly between equal pulls.
        GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.45), width: 2);
        for (var i = 0; i < 2; i++) {
          final a = g._clock * 3.4 + i * math.pi;
          _electron(canvas, mid + Offset(math.cos(a) * 26, math.sin(a) * 11),
              glow: 0.9);
        }
        break;
      case _Class.metallic:
        GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.4), width: 2);
        for (var i = 0; i < 7; i++) {
          final a = g._clock * 1.8 + i * (2 * math.pi / 7);
          final pos = mid +
              Offset(math.cos(a) * (60 + 14 * math.sin(a * 1.7 + i)),
                  math.sin(a * 0.8) * 26);
          _electron(canvas, pos, glow: 0.7);
        }
        break;
    }
  }

  void _electron(Canvas canvas, Offset at, {double glow = 1.0}) {
    canvas.drawCircle(
      at,
      8,
      Paint()
        ..color = _kElectron.withValues(alpha: 0.4 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(at, 4, Paint()..color = _kElectron);
    GameFx.text(canvas, '−', at, 9, Potatuhs.ink, weight: FontWeight.w900);
  }

  void _paintAtoms(Canvas canvas, bool resolving) {
    _paintAtom(canvas, g._leftCenter, g._pair.el0, resolving, true);
    _paintAtom(canvas, g._rightCenter, g._pair.el1, resolving, false);
  }

  void _paintAtom(Canvas canvas, Offset c, _El el, bool resolving, bool isLeft) {
    // Neutral violet orbs — the character is NOT printed; it lives in the EN.
    var at = c;
    if (resolving && !g._lastCorrect) {
      final shake = (1 - (g._transition / _kWrongDur)).clamp(0.0, 1.0);
      at = c.translate(math.sin(g._clock * 34) * 5 * shake, 0);
    }

    GameFx.orb(canvas, at, _kAtomR, _kAccent, glow: 0.9);
    GameFx.text(canvas, el.sym, at.translate(0, -2), 26, Colors.white,
        weight: FontWeight.w800, glow: 0.4);

    // Charge badges on reveal: full ± for ionic, partial δ± for polar covalent.
    if (resolving && g._lastCorrect) {
      final cls = g._pair.cls;
      if (cls == _Class.ionic) {
        final p = (g._transition / (_kResultDur * 0.5)).clamp(0.0, 1.0);
        if (p >= 1) {
          final isDonor = isLeft == g._leftIsDonor;
          _badge(canvas, at, isDonor ? '+' : '−',
              isDonor ? const Color(0xFFFF7043) : _kElectron, 15);
        }
      } else if (cls == _Class.polar) {
        // The more-electronegative atom carries the δ− end of the dipole.
        final thisIsMoreEN =
            isLeft ? !g._pair.rightIsMoreEN : g._pair.rightIsMoreEN;
        _badge(canvas, at, thisIsMoreEN ? 'δ−' : 'δ+',
            thisIsMoreEN ? _kElectron : const Color(0xFFFF7043), 12);
      }
    }

    GameFx.text(canvas, 'EN ${el.en.toStringAsFixed(2)}',
        at.translate(0, _kAtomR + 16), 14, Colors.white.withValues(alpha: 0.92),
        weight: FontWeight.w700);
  }

  void _badge(Canvas canvas, Offset at, String text, Color color, double size) {
    final p = at.translate(_kAtomR * 0.80, -_kAtomR * 0.80);
    canvas.drawCircle(p, 12, Paint()..color = color);
    GameFx.text(canvas, text, p, size, Potatuhs.ink, weight: FontWeight.w900);
  }

  /// Result banner: compound + WHY on a hit, or the corrective rule on a miss.
  void _paintReveal(Canvas canvas, Size size) {
    final y = size.height * 0.52;
    final cls = g._pair.cls;
    final dEN = g._pair.gap.toStringAsFixed(2);
    if (g._lastCorrect) {
      GameFx.text(canvas, '✓  ${g._pair.compound}', Offset(size.width / 2, y),
          18, _kGood, weight: FontWeight.w800, glow: 0.6);
      final why = switch (cls) {
        _Class.ionic => 'ionic · metal hands an e− to the nonmetal',
        _Class.polar => 'polar covalent · ΔEN $dEN — shared, pulled δ−',
        _Class.nonpolar => 'nonpolar covalent · ΔEN $dEN — shared evenly',
        _Class.metallic => 'metallic · a sea of shared electrons',
      };
      GameFx.text(canvas, why, Offset(size.width / 2, y + 24), 12,
          Potatuhs.textSecondary);
    } else {
      GameFx.text(
          canvas,
          '✗  ${_className(cls)}',
          Offset(size.width / 2, y),
          18,
          _kBad,
          weight: FontWeight.w800,
          glow: 0.5);
      GameFx.text(canvas, _classRule(cls), Offset(size.width / 2, y + 24), 12,
          const Color(0xFFFF8A80));
      GameFx.text(canvas, '${g._pair.compound}  ·  ΔEN $dEN',
          Offset(size.width / 2, y + 44), 11, Potatuhs.textSecondary);
    }
  }

  /// A draining speed-bonus meter — the per-question pace cue. Rewards reading
  /// the EN fast and confidently; not a hard timeout.
  void _paintSpeedMeter(Canvas canvas, Size size) {
    final frac = (1 - g._qTime / _kSpeedWindow).clamp(0.0, 1.0);
    if (frac <= 0) return;
    final w = size.width * 0.46;
    final x = (size.width - w) / 2;
    final y = size.height * 0.475;
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 5), const Radius.circular(3));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * frac, 5), const Radius.circular(3)),
      Paint()..color = _kGold.withValues(alpha: 0.7),
    );
  }

  void _paintSurge(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(g._clock * 6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6),
        Paint()..color = _kGold.withValues(alpha: 0.4 + 0.4 * pulse));
    GameFx.text(canvas, 'FINAL SURGE  ×2', Offset(size.width * 0.5, 24), 13,
        _kGold.withValues(alpha: 0.7 + 0.3 * pulse),
        display: true, glow: 0.6);
  }

  @override
  bool shouldRepaint(_BondV2Painter oldDelegate) => true;
}
