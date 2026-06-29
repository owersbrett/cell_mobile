import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/fx.dart';

// ============================================================================
// STANDARD MODEL — sort-and-place
//
// Particles stream in from the top and drift downward. The player drags each
// one into the correct FAMILY bin of the Standard Model:
//   • QUARKS   — up/down/charm/strange/top/bottom (color-charged matter)
//   • LEPTONS  — electron/muon/tau + their neutrinos
//   • BOSONS   — photon/gluon/W/Z/Higgs (force carriers + mass)
//
// Correct drop → score, names + classifies the particle, particle bursts.
// Wrong bin    → fizzle (no points, streak resets). A particle that sinks past
// the bins unsorted is a miss.
//
// Visual tells (electric-charge badge, color-charge rim, mass→orb-size) help
// the player classify — and FADE as difficulty climbs, so late game tests real
// knowledge (which generation, force-carrier vs matter), not pattern-matching.
//
// PERF: one Ticker → one CustomPainter. Particle count is capped (<=7); no
// per-frame setState over a big widget tree.
// ============================================================================

enum _Family { quark, lepton, boson }

const _kQuarkColor = Color(0xFFFF7043); // matter, color-charged
const _kLeptonColor = Color(0xFF42A5F5); // light matter
const _kBosonColor = Color(0xFFFFCA28); // force carriers
const _kNeutral = Color(0xFF9E9E9E);

Color _familyColor(_Family f) {
  switch (f) {
    case _Family.quark:
      return _kQuarkColor;
    case _Family.lepton:
      return _kLeptonColor;
    case _Family.boson:
      return _kBosonColor;
  }
}

String _familyName(_Family f) {
  switch (f) {
    case _Family.quark:
      return 'QUARKS';
    case _Family.lepton:
      return 'LEPTONS';
    case _Family.boson:
      return 'BOSONS';
  }
}

/// Immutable particle definition (one of the 17 Standard Model particles).
class _PData {
  final String symbol; // glyph drawn on the orb — the identity tell
  final String name; // full name, flashed on a correct sort
  final _Family family; // the answer
  final int generation; // 1/2/3 for matter; 0 for bosons (force label instead)
  final String forceLabel; // for bosons: the force / role
  final String chargeLabel; // electric charge, e.g. '+⅔', '−1', '0', '±1'
  final Color chargeColor; // charge tell colour
  final bool hasColor; // carries strong colour-charge (quarks + gluon)
  final int massRank; // 0 (≈massless) .. 5 (heaviest) → orb size tell

  const _PData(
    this.symbol,
    this.name,
    this.family,
    this.generation,
    this.forceLabel,
    this.chargeLabel,
    this.chargeColor,
    this.hasColor,
    this.massRank,
  );

  /// Short classification flashed on a correct drop.
  String get classify {
    if (family == _Family.boson) return '$name · $forceLabel · $chargeLabel';
    final fam = family == _Family.quark ? 'quark' : 'lepton';
    return '$name · gen $generation $fam · $chargeLabel';
  }
}

const _pos = Color(0xFFEF5350); // positive charge
const _neg = Color(0xFF42A5F5); // negative charge
const _neu = Color(0xFF9E9E9E); // neutral
const _mix = Color(0xFFAB47BC); // ± (W boson)

// The full Standard Model roster.
const _kParticles = <_PData>[
  // ---- Quarks (up-type +⅔ / down-type −⅓, all colour-charged) ----
  _PData('u', 'Up', _Family.quark, 1, '', '+⅔', _pos, true, 1),
  _PData('d', 'Down', _Family.quark, 1, '', '−⅓', _neg, true, 1),
  _PData('c', 'Charm', _Family.quark, 2, '', '+⅔', _pos, true, 3),
  _PData('s', 'Strange', _Family.quark, 2, '', '−⅓', _neg, true, 2),
  _PData('t', 'Top', _Family.quark, 3, '', '+⅔', _pos, true, 5),
  _PData('b', 'Bottom', _Family.quark, 3, '', '−⅓', _neg, true, 4),
  // ---- Leptons (charged −1 + neutral neutrinos) ----
  _PData('e', 'Electron', _Family.lepton, 1, '', '−1', _neg, false, 1),
  _PData('μ', 'Muon', _Family.lepton, 2, '', '−1', _neg, false, 2),
  _PData('τ', 'Tau', _Family.lepton, 3, '', '−1', _neg, false, 3),
  _PData('νe', 'Electron neutrino', _Family.lepton, 1, '', '0', _neu, false, 0),
  _PData('νμ', 'Muon neutrino', _Family.lepton, 2, '', '0', _neu, false, 0),
  _PData('ντ', 'Tau neutrino', _Family.lepton, 3, '', '0', _neu, false, 0),
  // ---- Bosons (force carriers + Higgs) ----
  _PData('γ', 'Photon', _Family.boson, 0, 'EM force', '0', _neu, false, 0),
  _PData('g', 'Gluon', _Family.boson, 0, 'strong force', '0', _neu, true, 0),
  _PData('W', 'W boson', _Family.boson, 0, 'weak force', '±1', _mix, false, 4),
  _PData('Z', 'Z boson', _Family.boson, 0, 'weak force', '0', _neu, false, 4),
  _PData('H', 'Higgs', _Family.boson, 0, 'mass', '0', _neu, false, 5),
];

// The "tricky" set — neutral charge / ambiguous tells. Weighted up at higher
// difficulty so the late game forces real family knowledge.
const _kTricky = <int>[9, 10, 11, 12, 13, 15, 16]; // neutrinos, photon, gluon, Z, Higgs

/// A live particle on screen.
class _Particle {
  final int id;
  final _PData data;
  double x, y;
  double vy;
  bool dragging = false;
  _Particle(this.id, this.data, this.x, this.y, this.vy);
}

class StandardModelGame extends StatefulWidget {
  final MiniGameSession session;
  const StandardModelGame({super.key, required this.session});

  @override
  State<StandardModelGame> createState() => _StandardModelGameState();
}

class _StandardModelGameState extends State<StandardModelGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Random _rng = Random();

  double _lastT = 0;
  double _clock = 0; // ambient clock (always advances)

  // ---- run state -----------------------------------------------------------
  bool _wasRunning = false;
  double _elapsed = 0; // seconds of active play this run
  int _sorted = 0; // particles correctly sorted (the score driver)
  int _streak = 0;
  double _spawnTimer = 0;
  int _nextId = 0;

  final List<_Particle> _particles = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  int? _dragId;
  int _hoverBin = -1; // 0/1/2 while dragging over a bin, else -1
  double _wrongFlash = 0;
  double _rightFlash = 0;

  Size _sz = Size.zero;

  // ---- difficulty: climbs as you succeed AND as time passes ----------------
  int get _difficulty =>
      ((_sorted ~/ 4) + (_elapsed ~/ 14)).clamp(0, 6);

  double get _fallSpeed => (42 + _difficulty * 13).clamp(42, 130).toDouble();
  double get _spawnInterval => (1.55 - _difficulty * 0.16).clamp(0.62, 1.55);
  int get _maxConcurrent => (3 + _difficulty).clamp(3, 7);

  // ---- lifecycle -----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- geometry (shared with painter) --------------------------------------
  double get _binTop => _sz.height - 96;
  double get _dangerLine => _binTop - 4;

  Rect _binRect(int i) {
    const gap = 8.0;
    final w = (_sz.width - gap * 4) / 3;
    final x = gap + i * (w + gap);
    return Rect.fromLTWH(x, _binTop + 6, w, 84);
  }

  _Family _familyForBin(int i) =>
      const [_Family.quark, _Family.lepton, _Family.boson][i];

  double _radiusFor(_PData d) => 19 + d.massRank * 1.7;

  // ---- run management ------------------------------------------------------
  void _startRun() {
    _elapsed = 0;
    _sorted = 0;
    _streak = 0;
    _spawnTimer = 0;
    _particles.clear();
    _fx.clear();
    _pops.clear();
    _dragId = null;
    _hoverBin = -1;
  }

  void _spawn() {
    if (_sz == Size.zero) return;
    // Bias toward tricky particles as difficulty climbs.
    int idx;
    if (_difficulty >= 3 && _rng.nextDouble() < 0.45) {
      idx = _kTricky[_rng.nextInt(_kTricky.length)];
    } else {
      idx = _rng.nextInt(_kParticles.length);
    }
    final d = _kParticles[idx];
    final r = _radiusFor(d);
    final x = r + 8 + _rng.nextDouble() * (_sz.width - 2 * r - 16);
    final y = -r - _rng.nextDouble() * 30;
    final vy = _fallSpeed * (0.85 + _rng.nextDouble() * 0.3);
    _particles.add(_Particle(_nextId++, d, x, y, vy));
  }

  // ---- tick ----------------------------------------------------------------
  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;

    setState(() {
      _clock += dt;
      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 2.5).clamp(0, 1);
      if (_rightFlash > 0) _rightFlash = (_rightFlash - dt * 2.5).clamp(0, 1);

      if (widget.session.isRunning) {
        if (!_wasRunning) _startRun();
        _wasRunning = true;
        _runPhysics(dt);
      } else {
        _wasRunning = false;
      }
    });
  }

  void _runPhysics(double dt) {
    _elapsed += dt;

    // Spawn.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _particles.length < _maxConcurrent) {
      _spawn();
      _spawnTimer = _spawnInterval * (0.8 + _rng.nextDouble() * 0.4);
    }

    // Advance falls; detect misses.
    for (final p in _particles) {
      if (p.dragging) continue;
      p.y += p.vy * dt;
    }
    _particles.removeWhere((p) {
      if (!p.dragging && p.y > _dangerLine) {
        // Missed — slipped past the detector.
        _streak = 0;
        _pops.add(FxPop(Offset(p.x, _dangerLine - 10), '—', _kNeutral));
        return true;
      }
      return false;
    });
  }

  // ---- input ---------------------------------------------------------------
  void _onPanStart(Offset pos) {
    if (!widget.session.isRunning) return;
    double best = 46;
    _Particle? pick;
    for (final p in _particles) {
      final d = (Offset(p.x, p.y) - pos).distance;
      if (d < best) {
        best = d;
        pick = p;
      }
    }
    if (pick != null) {
      pick.dragging = true;
      _dragId = pick.id;
    }
  }

  void _onPanUpdate(Offset pos) {
    if (_dragId == null) return;
    final p = _particles.firstWhere((e) => e.id == _dragId,
        orElse: () => _particles.isEmpty
            ? _Particle(-1, _kParticles.first, 0, 0, 0)
            : _particles.first);
    if (p.id != _dragId) return;
    p.x = pos.dx;
    p.y = pos.dy;
    _hoverBin = -1;
    for (int i = 0; i < 3; i++) {
      if (_binRect(i).contains(pos)) {
        _hoverBin = i;
        break;
      }
    }
  }

  void _onPanEnd() {
    if (_dragId == null) return;
    final idx = _particles.indexWhere((e) => e.id == _dragId);
    if (idx < 0) {
      _dragId = null;
      _hoverBin = -1;
      return;
    }
    final p = _particles[idx];
    p.dragging = false;
    final bin = _hoverBin;
    _dragId = null;
    _hoverBin = -1;

    if (bin < 0) return; // released in the field — keep falling.

    if (_familyForBin(bin) == p.data.family) {
      _resolveCorrect(p, idx, bin);
    } else {
      _resolveWrong(p, idx);
    }
  }

  void _resolveCorrect(_Particle p, int idx, int bin) {
    _particles.removeAt(idx);
    _sorted++;
    _streak++;
    widget.session.noteStreak(_streak);

    final speedBonus = ((1 - (p.y / _dangerLine)).clamp(0.0, 1.0) * 8).round();
    final pts = 10 + _streak.clamp(0, 12) * 2 + _difficulty * 2 + speedBonus;
    widget.session.addScore(pts);

    final c = _familyColor(p.data.family);
    final target = _binRect(bin).center;
    _fx.addAll(FxBurst.spawn(target, c, count: 14, speed: 120));
    _pops.add(FxPop(target.translate(0, -26), p.data.classify, c));
    _pops.add(FxPop(Offset(p.x, p.y - 12), '+$pts', Colors.white));
    _rightFlash = 0.5;
  }

  void _resolveWrong(_Particle p, int idx) {
    // Fizzle: no points, streak resets, particle vanishes.
    _streak = 0;
    _particles.removeAt(idx);
    _fx.addAll(FxBurst.spawn(Offset(p.x, p.y), const Color(0xFFFF5252),
        count: 10, speed: 70));
    _pops.add(FxPop(Offset(p.x, p.y - 12), '✗ ${_familyName(p.data.family)}',
        const Color(0xFFFF5252)));
    _wrongFlash = 0.5;
  }

  // ---- build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            painter: _SMPainter(
              clock: _clock,
              running: widget.session.isRunning,
              particles: _particles,
              fx: _fx,
              pops: _pops,
              dragId: _dragId,
              hoverBin: _hoverBin,
              difficulty: _difficulty,
              streak: _streak,
              sorted: _sorted,
              wrongFlash: _wrongFlash,
              rightFlash: _rightFlash,
              binTop: _binTop,
              radiusFor: _radiusFor,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter — one painter draws the whole play area.
// ---------------------------------------------------------------------------
class _SMPainter extends CustomPainter {
  final double clock;
  final bool running;
  final List<_Particle> particles;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final int? dragId;
  final int hoverBin;
  final int difficulty;
  final int streak;
  final int sorted;
  final double wrongFlash;
  final double rightFlash;
  final double binTop;
  final double Function(_PData) radiusFor;

  _SMPainter({
    required this.clock,
    required this.running,
    required this.particles,
    required this.fx,
    required this.pops,
    required this.dragId,
    required this.hoverBin,
    required this.difficulty,
    required this.streak,
    required this.sorted,
    required this.wrongFlash,
    required this.rightFlash,
    required this.binTop,
    required this.radiusFor,
  });

  static const _accent = Color(0xFF7C4DFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _accent, clock, motes: 30);

    if (wrongFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 23, 68, wrongFlash * 0.16));
    }
    if (rightFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Color.fromRGBO(124, 77, 255, rightFlash * 0.10));
    }

    _drawBins(canvas, size);
    _drawParticles(canvas);
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
    _drawHud(canvas, size);

    if (!running) _drawReady(canvas, size);
  }

  // ---- bins ----------------------------------------------------------------
  void _drawBins(Canvas canvas, Size size) {
    const fams = [_Family.quark, _Family.lepton, _Family.boson];
    const subs = ['6 · color-charged', '6 · e μ τ + ν', '5 · force + mass'];
    const gap = 8.0;
    final w = (size.width - gap * 4) / 3;
    for (int i = 0; i < 3; i++) {
      final c = _familyColor(fams[i]);
      final rect = Rect.fromLTWH(gap + i * (w + gap), binTop + 6, w, 84);
      final hovered = hoverBin == i;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));

      if (hovered) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                rect.inflate(4), const Radius.circular(16)),
            Paint()
              ..color = c.withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      canvas.drawRRect(rr,
          Paint()..color = c.withValues(alpha: hovered ? 0.26 : 0.10));
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = hovered ? 2.4 : 1.4
            ..color = c.withValues(alpha: hovered ? 0.9 : 0.45));

      GameFx.text(canvas, _familyName(fams[i]), rect.center.translate(0, -12),
          15, c.withValues(alpha: 0.95),
          display: true);
      GameFx.text(canvas, subs[i], rect.center.translate(0, 14), 10,
          Colors.white.withValues(alpha: 0.45),
          weight: FontWeight.w500);
    }
  }

  // ---- particles -----------------------------------------------------------
  void _drawParticles(Canvas canvas) {
    // Family colour fades to neutral as difficulty climbs (a finer-distinction
    // ramp: late game you must read the symbol, not the colour).
    final famStrength = (1 - difficulty / 4.0).clamp(0.0, 1.0);
    final showCharge = difficulty < 4;
    final showColorRim = difficulty < 5;

    for (final p in particles) {
      final d = p.data;
      final r = radiusFor(d);
      final center = Offset(p.x, p.y);
      final isDrag = p.id == dragId;
      final baseColor =
          Color.lerp(_kNeutral, _familyColor(d.family), famStrength)!;

      GameFx.orb(canvas, center, r, baseColor, glow: isDrag ? 1.4 : 0.8);

      // Colour-charge rim — quarks & gluon carry strong colour.
      if (showColorRim && d.hasColor) {
        for (int k = 0; k < 3; k++) {
          final a = clock * 1.4 + k * 2 * pi / 3;
          final cc = const [
            Color(0xFFFF5252),
            Color(0xFF4CAF50),
            Color(0xFF448AFF)
          ][k];
          canvas.drawCircle(
              center + Offset(cos(a), sin(a)) * (r + 3.5),
              2.2,
              Paint()..color = cc.withValues(alpha: 0.85));
        }
      }

      // Symbol — the persistent identity tell.
      GameFx.text(canvas, d.symbol, center, r * 0.92,
          Colors.white.withValues(alpha: 0.96),
          weight: FontWeight.w800);

      // Electric-charge badge (top-right).
      if (showCharge) {
        final bc = center + Offset(r * 0.72, -r * 0.72);
        canvas.drawCircle(bc, 8.5, Paint()..color = const Color(0xFF14110F));
        canvas.drawCircle(
            bc,
            8.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = d.chargeColor.withValues(alpha: 0.9));
        GameFx.text(canvas, d.chargeLabel, bc, 8, d.chargeColor,
            weight: FontWeight.w700);
      }
    }
  }

  // ---- HUD -----------------------------------------------------------------
  void _drawHud(Canvas canvas, Size size) {
    // Sorted count (top-left) — the score driver, mirrored for clarity.
    GameFx.text(canvas, 'SORTED $sorted', Offset(54, 20), 11,
        Colors.white.withValues(alpha: 0.30),
        weight: FontWeight.w700);

    // Streak (top-centre) when hot.
    if (streak > 1) {
      GameFx.text(canvas, 'x$streak streak', Offset(size.width / 2, 20), 12,
          const Color(0xFFFFCA28),
          weight: FontWeight.w700, glow: 0.5);
    }

    // Difficulty pips (top-right).
    if (difficulty > 0) {
      for (int i = 0; i < 6; i++) {
        final cx = size.width - 16 - i * 9.0;
        canvas.drawCircle(
            Offset(cx, 18),
            2.6,
            Paint()
              ..color = i < difficulty
                  ? _accent.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.10));
      }
    }
  }

  void _drawReady(Canvas canvas, Size size) {
    GameFx.text(
        canvas,
        'Drag each particle to its family',
        Offset(size.width / 2, size.height * 0.30),
        16,
        Colors.white.withValues(alpha: 0.7),
        weight: FontWeight.w700);
    GameFx.text(
        canvas,
        'QUARKS · LEPTONS · BOSONS',
        Offset(size.width / 2, size.height * 0.30 + 26),
        12,
        _accent.withValues(alpha: 0.8),
        weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _SMPainter old) => true;
}
