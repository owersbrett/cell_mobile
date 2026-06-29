import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Standard Model v2 — UX-passed rebuild of `standard_model`.
//
// SAME LESSON (preserved): particles stream down; sort each into its FAMILY —
// QUARKS / LEPTONS / BOSONS. Correct placement scores and NAMES + CLASSIFIES
// the particle (`Charm · gen 2 quark · +⅔`). The full 17-particle roster, the
// tricky-set weighting, and the fading visual tells (family colour → charge
// badge → colour-charge rim drop out as difficulty climbs) all stay, so late
// game still tests real knowledge, not colour-matching.
//
// WHAT CHANGED vs v1 (per the UX teardown):
//   1. THE VERB IS NO LONGER DRAG-ONE-AT-A-TIME. Three ways to sort, by skill:
//        • TAP a particle → it FREEZES (held, stops falling) so a novice can
//          think; TAP a bin to send it there. Low floor.
//        • ARM a bin (tap an empty bin) → then every TAP on a particle fires it
//          straight into the armed bin. One tap per sort — rapid-clear a cluster
//          of the same family. Raises the ceiling far above drag.
//        • FLICK a particle toward a bin (throw) — one gesture. Drag-and-drop
//          still works as a fallback.
//   2. LOWER SYMBOL FLOOR. A fading mini-LEGEND prints each family's real
//      members under its bin early in the run (training wheels that fade by the
//      mid tiers), and a WRONG drop pulses the CORRECT bin — you learn the
//      family at the moment you miss it, before the colour tell is gone.
//   3. A CLIMAX. In the final stretch a BEAM BURST fires: fastest stream,
//      densest field, and the streak multiplier cap doubles. Every 10th sort
//      throws a screen-wide MILESTONE flash so the standing reads to onlookers
//      in pass-and-play.
//
// Perf: ONE Ticker → ONE CustomPainter. Painter is rebuilt each tick with fresh
// values; the play tree is just a CustomPaint, so no per-frame setState over
// big widget trees.
// ═══════════════════════════════════════════════════════════════════════════

enum _Family { quark, lepton, boson }

const _kQuarkColor = Color(0xFFFF7043); // matter, colour-charged
const _kLeptonColor = Color(0xFF42A5F5); // light matter
const _kBosonColor = Color(0xFFFFCA28); // force carriers
const _kNeutral = Color(0xFF9E9E9E);
const _kAccent = Color(0xFF7C4DFF);

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

int _familyIndex(_Family f) => f.index;
_Family _familyForBin(int i) =>
    const [_Family.quark, _Family.lepton, _Family.boson][i];

/// Immutable particle definition (one of the 17 Standard Model particles).
class _PData {
  final String symbol; // glyph drawn on the orb — the identity tell
  final String name; // full name, flashed on a correct sort
  final _Family family; // the answer
  final int generation; // 1/2/3 for matter; 0 for bosons
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

// The full Standard Model roster (preserved from v1).
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

// The "tricky" set — neutral / ambiguous tells. Weighted up at higher
// difficulty so the late game forces real family knowledge.
const _kTricky = <int>[9, 10, 11, 12, 13, 15, 16];

// Mini-legend members per family (the fading learnable cue).
const _kLegend = <String>['u d c s t b', 'e μ τ ν', 'γ g W Z H'];
const _kBinSub = <String>['6 · colour-charged', '6 · e μ τ + ν', '5 · force + mass'];

/// A live particle on screen.
class _Particle {
  final int id;
  final _PData data;
  double x, y;
  double vy;
  bool dragging = false;
  _Particle(this.id, this.data, this.x, this.y, this.vy);
}

// ── Shared geometry (input + painter read the same bins) ─────────────────────
double _binTopFor(Size sz) => sz.height - 100;
double _dangerLineFor(Size sz) => _binTopFor(sz) - 4;
Rect _binRectFor(Size sz, int i) {
  const gap = 8.0;
  final w = (sz.width - gap * 4) / 3;
  return Rect.fromLTWH(gap + i * (w + gap), _binTopFor(sz) + 6, w, 90);
}

class StandardModelV2Game extends StatefulWidget {
  final MiniGameSession session;
  const StandardModelV2Game({super.key, required this.session});

  @override
  State<StandardModelV2Game> createState() => _StandardModelV2GameState();
}

class _StandardModelV2GameState extends State<StandardModelV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  double _lastT = 0;
  double _clock = 0; // ambient clock (always advances)

  // ---- run state -----------------------------------------------------------
  bool _wasRunning = false;
  double _elapsed = 0;
  int _sorted = 0;
  int _streak = 0;
  double _spawnTimer = 0;
  int _nextId = 0;
  bool _climax = false;

  final List<_Particle> _particles = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  int? _selId; // tapped & frozen, awaiting a bin
  int? _dragId; // currently dragged
  int _hoverBin = -1; // bin under a drag
  int _armedBin = -1; // armed family → tap-to-fire

  double _wrongFlash = 0;
  double _rightFlash = 0;
  int _pulseBin = -1; // correct-bin teach pulse after a wrong drop
  double _pulseT = 0;
  double _milestoneT = 0;
  String _milestoneText = '';

  Size _sz = Size.zero;

  // ---- difficulty: climbs as you succeed AND as time passes ----------------
  int get _difficulty => ((_sorted ~/ 4) + (_elapsed ~/ 14)).clamp(0, 6);

  double get _fallSpeed =>
      (42 + _difficulty * 13).toDouble() * (_climax ? 1.32 : 1.0);
  double get _spawnInterval =>
      (1.55 - _difficulty * 0.16).clamp(0.62, 1.55) * (_climax ? 0.62 : 1.0);
  int get _maxConcurrent =>
      (3 + _difficulty + (_climax ? 2 : 0)).clamp(3, 9);

  int get _multiplier =>
      (1 + _streak ~/ 4).clamp(1, _climax ? 8 : 4);

  // ---- lifecycle -----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- geometry ------------------------------------------------------------
  double _radiusFor(_PData d) => 19 + d.massRank * 1.7;

  int _binAt(Offset p) {
    for (int i = 0; i < 3; i++) {
      if (_binRectFor(_sz, i).contains(p)) return i;
    }
    return -1;
  }

  _Particle? _pickParticle(Offset p, {double pad = 8}) {
    double best = double.infinity;
    _Particle? pick;
    for (final q in _particles) {
      final r = _radiusFor(q.data) + pad;
      final d = (Offset(q.x, q.y) - p).distance;
      if (d < r && d < best) {
        best = d;
        pick = q;
      }
    }
    return pick;
  }

  // ---- run management ------------------------------------------------------
  void _startRun() {
    _elapsed = 0;
    _sorted = 0;
    _streak = 0;
    _spawnTimer = 0;
    _climax = false;
    _particles.clear();
    _fx.clear();
    _pops.clear();
    _selId = null;
    _dragId = null;
    _hoverBin = -1;
    _armedBin = -1;
    _pulseBin = -1;
    _pulseT = 0;
    _milestoneT = 0;
  }

  void _spawn() {
    if (_sz == Size.zero) return;
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
  void _onTick(Duration _) {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;

    _clock += dt;
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    _wrongFlash = math.max(0.0, _wrongFlash - dt * 2.5);
    _rightFlash = math.max(0.0, _rightFlash - dt * 2.5);
    _pulseT = math.max(0.0, _pulseT - dt * 1.1);
    _milestoneT = math.max(0.0, _milestoneT - dt * 1.0);

    if (widget.session.isRunning) {
      if (!_wasRunning) _startRun();
      _wasRunning = true;
      _runPhysics(dt);
    } else {
      _wasRunning = false;
    }

    setState(() {});
  }

  void _runPhysics(double dt) {
    _elapsed += dt;
    final remSec = widget.session.remaining.inMilliseconds / 1000.0;
    _climax = remSec > 0 && remSec <= 10;

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _particles.length < _maxConcurrent) {
      _spawn();
      _spawnTimer = _spawnInterval * (0.8 + _rng.nextDouble() * 0.4);
    }

    // Advance falls (frozen selection and the dragged orb hold still).
    final danger = _dangerLineFor(_sz);
    for (final p in _particles) {
      if (p.dragging || p.id == _selId) continue;
      p.y += p.vy * dt;
    }
    _particles.removeWhere((p) {
      if (!p.dragging && p.id != _selId && p.y > danger) {
        _streak = 0;
        _pops.add(FxPop(Offset(p.x, danger - 10), '—', _kNeutral));
        return true;
      }
      return false;
    });
  }

  // ---- input ---------------------------------------------------------------
  void _onTapUp(Offset pos) {
    if (!widget.session.isRunning) return;

    final bin = _binAt(pos);
    if (bin >= 0) {
      if (_selId != null) {
        final idx = _particles.indexWhere((e) => e.id == _selId);
        _selId = null;
        if (idx >= 0) _resolve(_particles[idx], bin);
      } else {
        _armedBin = (_armedBin == bin) ? -1 : bin; // toggle arm
      }
      return;
    }

    final p = _pickParticle(pos, pad: 10);
    if (p != null) {
      if (_armedBin >= 0) {
        _resolve(p, _armedBin); // one-tap fire into the armed bin
      } else {
        _selId = (_selId == p.id) ? null : p.id; // freeze / unfreeze
      }
      return;
    }
    _selId = null; // tapped empty space
  }

  void _onPanStart(Offset pos) {
    if (!widget.session.isRunning) return;
    final p = _pickParticle(pos, pad: 26);
    if (p != null) {
      p.dragging = true;
      _dragId = p.id;
      _selId = null;
    }
  }

  void _onPanUpdate(Offset pos) {
    if (_dragId == null) return;
    final idx = _particles.indexWhere((e) => e.id == _dragId);
    if (idx < 0) return;
    _particles[idx].x = pos.dx;
    _particles[idx].y = pos.dy;
    _hoverBin = _binAt(pos);
  }

  void _onPanEnd(Velocity v) {
    if (_dragId == null) return;
    final idx = _particles.indexWhere((e) => e.id == _dragId);
    final hover = _hoverBin;
    final dragId = _dragId;
    _dragId = null;
    _hoverBin = -1;
    if (idx < 0) return;
    final p = _particles[idx];
    p.dragging = false;

    int bin = hover;
    if (bin < 0) bin = _flickBin(p, v); // throw toward a bin
    if (bin >= 0) {
      _resolve(p, bin);
    }
    // else: released in the field — keeps falling.
    if (p.id == dragId) {/* explicit no-op for clarity */}
  }

  // A fast downward flick throws the orb at the bin it points toward.
  int _flickBin(_Particle p, Velocity v) {
    final pps = v.pixelsPerSecond;
    if (pps.distance < 650 || pps.dy < 120) return -1;
    final projX = p.x + pps.dx * 0.12;
    int best = 0;
    double bestD = double.infinity;
    for (int i = 0; i < 3; i++) {
      final d = (projX - _binRectFor(_sz, i).center.dx).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  // ---- resolution ----------------------------------------------------------
  void _resolve(_Particle p, int bin) {
    final i = _particles.indexWhere((e) => e.id == p.id);
    if (i < 0) return;
    if (_selId == p.id) _selId = null;
    if (_familyForBin(bin) == p.data.family) {
      _resolveCorrect(p, i, bin);
    } else {
      _resolveWrong(p, i);
    }
  }

  void _resolveCorrect(_Particle p, int idx, int bin) {
    _particles.removeAt(idx);
    _sorted++;
    _streak++;
    widget.session.noteStreak(_streak);

    final danger = _dangerLineFor(_sz);
    final speedBonus = ((1 - (p.y / danger)).clamp(0.0, 1.0) * 6).round();
    final mult = _multiplier;
    final base = 10 + _difficulty * 2 + speedBonus;
    widget.session.addScore(base * mult);

    final c = _familyColor(p.data.family);
    final target = _binRectFor(_sz, bin).center;
    _fx.addAll(FxBurst.spawn(target, c, count: 14, speed: 120));
    _pops.add(FxPop(target.translate(0, -30), p.data.classify, c));
    _pops.add(FxPop(Offset(p.x, p.y - 12),
        mult > 1 ? '+${base * mult} ×$mult' : '+${base * mult}', Colors.white));
    _rightFlash = 0.5;

    if (_sorted % 10 == 0) {
      _milestoneT = 1.0;
      _milestoneText = '$_sorted SORTED';
    }
  }

  void _resolveWrong(_Particle p, int idx) {
    _streak = 0;
    _particles.removeAt(idx);
    _fx.addAll(FxBurst.spawn(Offset(p.x, p.y), const Color(0xFFFF5252),
        count: 10, speed: 70));
    _pops.add(FxPop(Offset(p.x, p.y - 12),
        '✗ ${_familyName(p.data.family)}', const Color(0xFFFF5252)));
    _wrongFlash = 0.5;
    // Teach: pulse the bin it SHOULD have gone in.
    _pulseBin = _familyIndex(p.data.family);
    _pulseT = 1.0;
  }

  // ---- build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d.localPosition),
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (d) => _onPanEnd(d.velocity),
        child: ClipRect(
          child: CustomPaint(
            painter: _SMV2Painter(
              clock: _clock,
              running: widget.session.isRunning,
              particles: _particles,
              fx: _fx,
              pops: _pops,
              selId: _selId,
              dragId: _dragId,
              hoverBin: _hoverBin,
              armedBin: _armedBin,
              difficulty: _difficulty,
              streak: _streak,
              multiplier: _multiplier,
              sorted: _sorted,
              climax: _climax,
              wrongFlash: _wrongFlash,
              rightFlash: _rightFlash,
              pulseBin: _pulseBin,
              pulseT: _pulseT,
              milestoneT: _milestoneT,
              milestoneText: _milestoneText,
              radiusFor: _radiusFor,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — one painter draws the whole play area.
// ═══════════════════════════════════════════════════════════════════════════
class _SMV2Painter extends CustomPainter {
  final double clock;
  final bool running;
  final List<_Particle> particles;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final int? selId;
  final int? dragId;
  final int hoverBin;
  final int armedBin;
  final int difficulty;
  final int streak;
  final int multiplier;
  final int sorted;
  final bool climax;
  final double wrongFlash;
  final double rightFlash;
  final int pulseBin;
  final double pulseT;
  final double milestoneT;
  final String milestoneText;
  final double Function(_PData) radiusFor;

  _SMV2Painter({
    required this.clock,
    required this.running,
    required this.particles,
    required this.fx,
    required this.pops,
    required this.selId,
    required this.dragId,
    required this.hoverBin,
    required this.armedBin,
    required this.difficulty,
    required this.streak,
    required this.multiplier,
    required this.sorted,
    required this.climax,
    required this.wrongFlash,
    required this.rightFlash,
    required this.pulseBin,
    required this.pulseT,
    required this.milestoneT,
    required this.milestoneText,
    required this.radiusFor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _kAccent, clock, motes: 30);

    if (climax) _drawBeams(canvas, size);

    if (wrongFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 23, 68, wrongFlash * 0.16));
    }
    if (rightFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Color.fromRGBO(124, 77, 255, rightFlash * 0.10));
    }

    _drawBins(canvas, size);
    _drawParticles(canvas, size);
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
    _drawHud(canvas, size);
    if (milestoneT > 0) _drawMilestone(canvas, size);
    if (!running) _drawReady(canvas, size);
  }

  // ---- climax beams --------------------------------------------------------
  void _drawBeams(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (int i = 0; i < 7; i++) {
      final x = ((i * 0.1379 + clock * 0.18) % 1.0) * size.width;
      final a = 0.05 + 0.04 * (0.5 + 0.5 * math.sin(clock * 3 + i));
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kAccent.withValues(alpha: 0.0), _kAccent.withValues(alpha: a)],
      ).createShader(Rect.fromLTWH(x - 12, 0, 24, size.height));
      canvas.drawRect(Rect.fromLTWH(x - 12, 0, 24, size.height), paint);
    }
  }

  // ---- bins ----------------------------------------------------------------
  void _drawBins(Canvas canvas, Size size) {
    const fams = [_Family.quark, _Family.lepton, _Family.boson];
    // Legend training-wheels strength: full early, gone by ~tier 2.5.
    final legendStrength = (1 - difficulty / 2.5).clamp(0.0, 1.0);

    for (int i = 0; i < 3; i++) {
      final c = _familyColor(fams[i]);
      final rect = _binRectFor(size, i);
      final hovered = hoverBin == i;
      final armed = armedBin == i;
      final pulse = (pulseBin == i) ? pulseT : 0.0;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));

      if (hovered || armed || pulse > 0) {
        final glow = math.max(armed ? 0.30 : 0.0, pulse * 0.35);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(16)),
            Paint()
              ..color = c.withValues(alpha: (hovered ? 0.25 : glow).clamp(0, 1))
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      canvas.drawRRect(
          rr,
          Paint()
            ..color = c.withValues(
                alpha: hovered || armed ? 0.26 : 0.10 + pulse * 0.12));
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (hovered || armed) ? 2.6 : 1.4 + pulse * 1.6
            ..color = c.withValues(
                alpha: (hovered || armed ? 0.95 : 0.45 + pulse * 0.5)
                    .clamp(0, 1)));

      // Title (lifts up a touch when the legend is showing).
      final hasLegend = legendStrength > 0.02;
      final titleDy = hasLegend ? -26.0 : -12.0;
      GameFx.text(canvas, _familyName(fams[i]), rect.center.translate(0, titleDy),
          15, c.withValues(alpha: 0.95),
          display: true);
      GameFx.text(canvas, _kBinSub[i], rect.center.translate(0, titleDy + 17),
          10, Colors.white.withValues(alpha: 0.45),
          weight: FontWeight.w500);

      // Fading mini-legend — the learnable cue.
      if (hasLegend) {
        GameFx.text(canvas, _kLegend[i], rect.center.translate(0, 18), 13,
            c.withValues(alpha: 0.85 * legendStrength),
            weight: FontWeight.w700);
      }

      if (armed) {
        GameFx.text(canvas, 'ARMED', rect.center.translate(0, 34), 9,
            Colors.white.withValues(alpha: 0.9),
            weight: FontWeight.w800, glow: 0.6);
      }
    }
  }

  // ---- particles -----------------------------------------------------------
  void _drawParticles(Canvas canvas, Size size) {
    final famStrength = (1 - difficulty / 4.0).clamp(0.0, 1.0);
    final showCharge = difficulty < 4;
    final showColorRim = difficulty < 5;

    for (final p in particles) {
      final d = p.data;
      final r = radiusFor(d);
      final center = Offset(p.x, p.y);
      final isDrag = p.id == dragId;
      final isSel = p.id == selId;
      final baseColor =
          Color.lerp(_kNeutral, _familyColor(d.family), famStrength)!;

      // Frozen-selection ring (pulses).
      if (isSel) {
        final pr = r + 7 + 2.5 * math.sin(clock * 6);
        canvas.drawCircle(
            center,
            pr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = Colors.white.withValues(alpha: 0.85));
      }

      GameFx.orb(canvas, center, r, baseColor,
          glow: isDrag || isSel ? 1.5 : 0.8);

      if (showColorRim && d.hasColor) {
        for (int k = 0; k < 3; k++) {
          final a = clock * 1.4 + k * 2 * math.pi / 3;
          final cc = const [
            Color(0xFFFF5252),
            Color(0xFF4CAF50),
            Color(0xFF448AFF)
          ][k];
          canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * (r + 3.5),
              2.2, Paint()..color = cc.withValues(alpha: 0.85));
        }
      }

      GameFx.text(canvas, d.symbol, center, r * 0.92,
          Colors.white.withValues(alpha: 0.96),
          weight: FontWeight.w800);

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
    GameFx.text(canvas, 'SORTED $sorted', Offset(54, 20), 11,
        Colors.white.withValues(alpha: 0.30),
        weight: FontWeight.w700);

    if (climax) {
      final pulse = 0.5 + 0.5 * math.sin(clock * 6);
      GameFx.text(canvas, '⚡ BEAM BURST', Offset(size.width / 2, 20), 13,
          Color.lerp(_kAccent, Colors.white, pulse)!,
          weight: FontWeight.w800, glow: 0.7);
    } else if (streak > 1) {
      GameFx.text(
          canvas,
          multiplier > 1 ? 'x$streak  ·  ×$multiplier' : 'x$streak streak',
          Offset(size.width / 2, 20),
          12,
          const Color(0xFFFFCA28),
          weight: FontWeight.w700,
          glow: 0.5);
    }

    if (difficulty > 0) {
      for (int i = 0; i < 6; i++) {
        final cx = size.width - 16 - i * 9.0;
        canvas.drawCircle(
            Offset(cx, 18),
            2.6,
            Paint()
              ..color = i < difficulty
                  ? _kAccent.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.10));
      }
    }
  }

  void _drawMilestone(Canvas canvas, Size size) {
    final a = milestoneT.clamp(0.0, 1.0);
    final scale = 1.0 + (1 - a) * 0.4;
    GameFx.text(canvas, milestoneText, Offset(size.width / 2, size.height * 0.32),
        30 * scale, _kAccent.withValues(alpha: a),
        display: true, glow: 0.8 * a);
  }

  void _drawReady(Canvas canvas, Size size) {
    GameFx.text(canvas, 'Sort each particle into its family',
        Offset(size.width / 2, size.height * 0.26), 16,
        Colors.white.withValues(alpha: 0.75),
        weight: FontWeight.w700);
    GameFx.text(canvas, 'QUARKS · LEPTONS · BOSONS',
        Offset(size.width / 2, size.height * 0.26 + 26), 12,
        _kAccent.withValues(alpha: 0.85),
        weight: FontWeight.w600);
    GameFx.text(canvas, 'Tap a particle, then a bin',
        Offset(size.width / 2, size.height * 0.26 + 58), 12,
        Colors.white.withValues(alpha: 0.55), weight: FontWeight.w500);
    GameFx.text(canvas, 'or ARM a bin and tap to rapid-sort  ·  flick to throw',
        Offset(size.width / 2, size.height * 0.26 + 78), 11,
        Colors.white.withValues(alpha: 0.40), weight: FontWeight.w500);
  }

  @override
  bool shouldRepaint(covariant _SMV2Painter old) => true;
}
