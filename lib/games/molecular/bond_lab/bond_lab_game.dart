import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Bond Lab — molecular-scale "choose the bond" game.
///
/// Two atoms appear with their electronegativity and metal/nonmetal character.
/// The player decides which bond forms between them — IONIC (a metal donates an
/// electron to a nonmetal), COVALENT (two nonmetals share), or METALLIC (two
/// metals pool a sea of electrons) — and the right call forms the compound. The
/// answer set is the lesson: which kinds of atoms make which kind of bond. The
/// late game leans on polar-covalent traps (two nonmetals with a big EN gap that
/// *look* ionic) and alloys, so the rule, not a color, has to carry you.
///
/// Host owns the clock/score/results; this widget renders only the play area,
/// auto-starts on `session.isRunning`, and reports via `addScore` / `noteStreak`.

// ── Tunables ──────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF7E57C2); // deep violet — distinct from Mixer
const Color _kMetal = Color(0xFFE19816); // warm — metallic character
const Color _kNonmetal = Color(0xFF26C6DA); // cool — nonmetal character
const Color _kElectron = Color(0xFF8CF1FF); // bright electron spark

const double _kAtomR = 38;
const int _kCorrectScore = 10; // + streak bonus
const int _kWrongScore = -5;
const int _kBondTimeBonus = 2; // seconds added on a correct bond
const double _kResultDur = 1.45; // celebration window after a correct bond
const double _kWrongDur = 1.7; // longer, so the explanation can be read

enum _Bond { ionic, covalent, metallic }

String _bondName(_Bond b) => switch (b) {
      _Bond.ionic => 'IONIC',
      _Bond.covalent => 'COVALENT',
      _Bond.metallic => 'METALLIC',
    };

String _bondRule(_Bond b) => switch (b) {
      _Bond.ionic => 'metal + nonmetal',
      _Bond.covalent => 'nonmetal + nonmetal',
      _Bond.metallic => 'metal + metal',
    };

String _bondVerb(_Bond b) => switch (b) {
      _Bond.ionic => 'electrons transfer',
      _Bond.covalent => 'electrons shared',
      _Bond.metallic => 'electron sea',
    };

Color _bondColor(_Bond b) => switch (b) {
      _Bond.ionic => const Color(0xFFFF7043),
      _Bond.covalent => const Color(0xFF26C6DA),
      _Bond.metallic => const Color(0xFFE1C916),
    };

// ── Element + pair data ─────────────────────────────────────────────────────
class _El {
  final String sym;
  final String name;
  final double en; // Pauling electronegativity
  final bool metal;
  const _El(this.sym, this.name, this.en, this.metal);
}

// Clean EN split: every metal < 2.0, every nonmetal > 2.0.
const List<_El> _els = [
  _El('Na', 'Sodium', 0.93, true), // 0
  _El('K', 'Potassium', 0.82, true), // 1
  _El('Li', 'Lithium', 0.98, true), // 2
  _El('Ca', 'Calcium', 1.00, true), // 3
  _El('Mg', 'Magnesium', 1.31, true), // 4
  _El('Al', 'Aluminium', 1.61, true), // 5
  _El('Fe', 'Iron', 1.83, true), // 6
  _El('Cu', 'Copper', 1.90, true), // 7
  _El('Cl', 'Chlorine', 3.16, false), // 8
  _El('O', 'Oxygen', 3.44, false), // 9
  _El('F', 'Fluorine', 3.98, false), // 10
  _El('H', 'Hydrogen', 2.20, false), // 11
  _El('N', 'Nitrogen', 3.04, false), // 12
  _El('C', 'Carbon', 2.55, false), // 13
  _El('S', 'Sulfur', 2.58, false), // 14
  _El('Br', 'Bromine', 2.96, false), // 15
];

class _Pair {
  final int a;
  final int b;
  final String compound; // what forms when bonded correctly
  final int tier; // 0 = clear, 1 = subtler (polar covalent, alloys)
  const _Pair(this.a, this.b, this.compound, this.tier);

  _El get el0 => _els[a];
  _El get el1 => _els[b];

  _Bond get bond {
    final m0 = el0.metal, m1 = el1.metal;
    if (m0 && m1) return _Bond.metallic;
    if (!m0 && !m1) return _Bond.covalent;
    return _Bond.ionic;
  }

  /// True for two-nonmetal pairs with a wide EN gap — a covalent bond that is
  /// strongly polar and tempts a wrong "ionic" call. The teaching twist.
  bool get polar => bond == _Bond.covalent && (el0.en - el1.en).abs() >= 0.9;
}

const List<_Pair> _pairs = [
  // ── Tier 0: clear cases ──
  _Pair(0, 8, 'NaCl · table salt', 0),
  _Pair(1, 8, 'KCl', 0),
  _Pair(1, 15, 'KBr', 0),
  _Pair(2, 10, 'LiF', 0),
  _Pair(3, 9, 'CaO · quicklime', 0),
  _Pair(4, 9, 'MgO', 0),
  _Pair(0, 10, 'NaF', 0),
  _Pair(9, 9, 'O₂', 0),
  _Pair(11, 11, 'H₂', 0),
  _Pair(8, 8, 'Cl₂', 0),
  _Pair(12, 12, 'N₂', 0),
  _Pair(15, 15, 'Br₂', 0),
  _Pair(0, 0, 'Na lattice', 0),
  _Pair(7, 7, 'Cu lattice', 0),
  _Pair(6, 6, 'Fe lattice', 0),
  _Pair(5, 5, 'Al lattice', 0),
  _Pair(1, 1, 'K lattice', 0),
  // ── Tier 1: subtler ──
  _Pair(5, 9, 'Al₂O₃ · alumina', 1),
  _Pair(6, 9, 'FeO · rust', 1),
  _Pair(7, 9, 'CuO', 1),
  _Pair(4, 12, 'Mg₃N₂', 1),
  _Pair(5, 8, 'AlCl₃', 1),
  _Pair(3, 8, 'CaCl₂', 1),
  _Pair(11, 8, 'HCl · hydrochloric', 1), // polar covalent
  _Pair(11, 9, 'H₂O · water', 1), // polar covalent
  _Pair(11, 10, 'HF · hydrofluoric', 1), // polar covalent
  _Pair(12, 11, 'NH₃ · ammonia', 1), // polar covalent
  _Pair(13, 9, 'CO₂', 1), // polar covalent
  _Pair(13, 11, 'CH₄ · methane', 1),
  _Pair(11, 14, 'H₂S', 1),
  _Pair(14, 9, 'SO₂', 1), // polar covalent
  _Pair(7, 6, 'Cu·Fe alloy', 1),
  _Pair(7, 5, 'Cu·Al alloy', 1),
  _Pair(6, 5, 'Fe·Al alloy', 1),
  _Pair(4, 5, 'Mg·Al alloy', 1),
];

// ── Game widget ─────────────────────────────────────────────────────────────
class BondLabGame extends StatefulWidget {
  final MiniGameSession session;
  const BondLabGame({super.key, required this.session});

  @override
  State<BondLabGame> createState() => _BondLabGameState();
}

class _BondLabGameState extends State<BondLabGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (idle shimmer, electron orbits)
  double _elapsed = 0; // advances only while running (difficulty ramp)

  late _Pair _pair;
  int _streak = 0;

  /// -1 while accepting input; otherwise seconds since the answer was given.
  double _transition = -1;
  _Bond? _chosen;
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
      _elapsed += dt;
      if (_transition >= 0) {
        _transition += dt;
        final dur = _lastCorrect ? _kResultDur : _kWrongDur;
        if (_transition >= dur) _next();
      }
    }

    // Effects advance every frame regardless of phase.
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    if (mounted) setState(() {});
  }

  // ── geometry ──
  double get _atomY => _fieldSize.height * 0.30;
  Offset get _leftCenter => Offset(_fieldSize.width * 0.28, _atomY);
  Offset get _rightCenter => Offset(_fieldSize.width * 0.72, _atomY);

  /// The metal atom in an ionic pair is the electron donor.
  bool get _leftIsDonor => _pair.el0.metal;

  double get _difficulty {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return (_elapsed / dur).clamp(0.0, 1.0);
  }

  void _next() {
    final wantTricky = _rng.nextDouble() < _difficulty * 0.75;
    var pool = _pairs.where((p) => p.tier == (wantTricky ? 1 : 0)).toList();
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
  }

  void _choose(_Bond b) {
    if (!widget.session.isRunning || _transition >= 0) return;
    _chosen = b;
    _lastCorrect = b == _pair.bond;
    _transition = 0;

    if (_lastCorrect) {
      _streak++;
      final gain = _kCorrectScore + math.min(_streak, 10).toInt();
      widget.session.addScore(gain);
      widget.session.noteStreak(_streak);
      widget.session.addTime(const Duration(seconds: _kBondTimeBonus));
      final mid = Offset.lerp(_leftCenter, _rightCenter, 0.5)!;
      _pops.add(FxPop(mid.translate(0, -_kAtomR - 18), '+$gain',
          const Color(0xFFFFD54F)));
      _particles.addAll(FxBurst.spawn(mid, _kAccent, count: 18, speed: 150));
      _particles.addAll(FxBurst.spawn(_leftCenter, _kElectron, count: 8));
      _particles.addAll(FxBurst.spawn(_rightCenter, _kElectron, count: 8));
    } else {
      _streak = 0;
      widget.session.addScore(_kWrongScore);
      final mid = Offset.lerp(_leftCenter, _rightCenter, 0.5)!;
      _pops.add(FxPop(mid.translate(0, -_kAtomR - 18), '$_kWrongScore',
          const Color(0xFFFF5252)));
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
                painter: _BondPainter(this),
                size: Size.infinite,
              ),
            ),
            // Bond choices.
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(child: _bondButton(_Bond.ionic)),
                  const SizedBox(width: 10),
                  Expanded(child: _bondButton(_Bond.covalent)),
                  const SizedBox(width: 10),
                  Expanded(child: _bondButton(_Bond.metallic)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _bondButton(_Bond b) {
    final running = widget.session.isRunning;
    final resolving = _transition >= 0;
    final isChosen = resolving && _chosen == b;
    final isCorrect = resolving && _pair.bond == b;

    Color border = _bondColor(b).withValues(alpha: running ? 0.55 : 0.25);
    Color fill = Colors.black.withValues(alpha: 0.42);
    if (isCorrect) {
      border = const Color(0xFF69F0AE);
      fill = const Color(0xFF69F0AE).withValues(alpha: 0.16);
    } else if (isChosen && !isCorrect) {
      border = const Color(0xFFFF5252);
      fill = const Color(0xFFFF5252).withValues(alpha: 0.16);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _choose(b),
      child: Opacity(
        opacity: running ? 1.0 : 0.5,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.6),
            boxShadow: isCorrect || isChosen
                ? [BoxShadow(color: border.withValues(alpha: 0.4), blurRadius: 14)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _bondName(b),
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: _bondColor(b),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _bondVerb(b),
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                  size: 9,
                  weight: FontWeight.w600,
                  color: Potatuhs.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painter ─────────────────────────────────────────────────────────────────
class _BondPainter extends CustomPainter {
  final _BondLabGameState g;
  _BondPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 26);

    final running = g.widget.session.isRunning;
    final resolving = g._transition >= 0;

    _paintPrompt(canvas, size, running, resolving);
    _paintBond(canvas);
    _paintAtoms(canvas, resolving);
    if (resolving) _paintReveal(canvas, size);

    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }
  }

  void _paintPrompt(Canvas canvas, Size size, bool running, bool resolving) {
    final String label;
    Color color = _kAccent;
    if (!running) {
      label = 'BOND LAB';
    } else if (resolving) {
      label = '';
    } else {
      label = 'WHICH BOND FORMS?';
      color = Potatuhs.textSecondary;
    }
    if (label.isEmpty) return;
    GameFx.text(
      canvas,
      label,
      Offset(size.width / 2, size.height * 0.085),
      running ? 16 : 26,
      color.withValues(alpha: 0.9),
      display: !running,
      weight: FontWeight.w800,
      glow: 0.5,
    );
    if (!running) {
      GameFx.text(
        canvas,
        'Read each atom · choose the bond',
        Offset(size.width / 2, size.height * 0.085 + 30),
        13,
        Potatuhs.textSecondary,
      );
    }
  }

  /// The visible bond between the atoms once the player has answered correctly:
  /// transfer (ionic), shared pair (covalent), or electron sea (metallic).
  void _paintBond(Canvas canvas) {
    if (g._transition < 0 || !g._lastCorrect) return;
    final t = g._transition;
    final l = g._leftCenter, r = g._rightCenter;
    final mid = Offset.lerp(l, r, 0.5)!;

    switch (g._pair.bond) {
      case _Bond.ionic:
        // One electron flies from the metal (donor) to the nonmetal.
        final from = g._leftIsDonor ? l : r;
        final to = g._leftIsDonor ? r : l;
        final p = (t / (_kResultDur * 0.5)).clamp(0.0, 1.0);
        final pos = Offset.lerp(from, to, Curves.easeInOut.transform(p))!;
        _electron(canvas, pos, glow: 1.0);
        if (p >= 1) {
          GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.5),
              width: 2);
        }
        break;
      case _Bond.covalent:
        // A shared pair orbits the midpoint — held between both nuclei.
        GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.45),
            width: 2);
        for (var i = 0; i < 2; i++) {
          final a = g._clock * 3.4 + i * math.pi;
          final pos =
              mid + Offset(math.cos(a) * 26, math.sin(a) * 11);
          _electron(canvas, pos, glow: 0.9);
        }
        break;
      case _Bond.metallic:
        // A delocalized sea of electrons drifts around both cores.
        GameFx.glowLine(canvas, l, r, _kAccent.withValues(alpha: 0.4),
            width: 2);
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

  void _paintAtom(
      Canvas canvas, Offset c, _El el, bool resolving, bool isLeft) {
    final color = el.metal ? _kMetal : _kNonmetal;

    // Shake on a wrong answer.
    var at = c;
    if (resolving && !g._lastCorrect) {
      final shake = (1 - (g._transition / _kWrongDur)).clamp(0.0, 1.0);
      at = c.translate(math.sin(g._clock * 34) * 5 * shake, 0);
    }

    GameFx.orb(canvas, at, _kAtomR, color, glow: 0.9);
    GameFx.text(canvas, el.sym, at.translate(0, -2), 26, Colors.white,
        weight: FontWeight.w800, glow: 0.4);

    // Ionic charge badge once the electron has transferred.
    if (resolving && g._lastCorrect && g._pair.bond == _Bond.ionic) {
      final p = (g._transition / (_kResultDur * 0.5)).clamp(0.0, 1.0);
      if (p >= 1) {
        final isDonor = isLeft == g._leftIsDonor;
        final badge = isDonor ? '+' : '−';
        final bColor =
            isDonor ? const Color(0xFFFF7043) : _kNonmetal;
        canvas.drawCircle(
          at.translate(_kAtomR * 0.78, -_kAtomR * 0.78),
          11,
          Paint()..color = bColor,
        );
        GameFx.text(canvas, badge,
            at.translate(_kAtomR * 0.78, -_kAtomR * 0.82), 15, Potatuhs.ink,
            weight: FontWeight.w900);
      }
    }

    // Labels: EN value + class tag — the clues the bond choice rests on.
    GameFx.text(canvas, 'EN ${el.en.toStringAsFixed(2)}',
        at.translate(0, _kAtomR + 16), 13, Colors.white.withValues(alpha: 0.9),
        weight: FontWeight.w700);
    _tag(canvas, at.translate(0, _kAtomR + 38), el.metal ? 'METAL' : 'NONMETAL',
        color);
  }

  void _tag(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: Potatuhs.label(size: 9, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
        center: center, width: tp.width + 16, height: tp.height + 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.6),
    );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Result banner: the compound on a correct call, or the corrective rule on a
  /// wrong one — the moment the lesson lands.
  void _paintReveal(Canvas canvas, Size size) {
    final y = size.height * 0.49;
    if (g._lastCorrect) {
      var text = '✓  ${g._pair.compound}';
      if (g._pair.polar) text = '$text  · polar covalent';
      GameFx.text(canvas, text, Offset(size.width / 2, y), 18,
          const Color(0xFF69F0AE),
          weight: FontWeight.w800, glow: 0.6);
    } else {
      final correct = g._pair.bond;
      GameFx.text(
          canvas,
          '✗  ${_bondRule(correct)} → ${_bondName(correct)}',
          Offset(size.width / 2, y),
          17,
          const Color(0xFFFF8A80),
          weight: FontWeight.w800,
          glow: 0.5);
      GameFx.text(canvas, g._pair.compound,
          Offset(size.width / 2, y + 26), 13, Potatuhs.textSecondary);
    }
  }

  @override
  bool shouldRepaint(_BondPainter oldDelegate) => true;
}
