// NeuronConnectGame — "Neural Cascade" aim-the-axon time trial.
//
// Drag a neuron to swing its AXON. Aim the chain SOURCE → (relays) → TARGET;
// the instant every hop lines up (and no glial blocker sits in the beam) the
// action potential auto-cascades and you score. Each cleared circuit spawns a
// harder one that introduces ONE new twist: a relay, interference, a diagonal
// field, irregular spacing, then entropy drift. 60-second blitz.
//
// Self-contained module. Depends only on the framework session + shared FX.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tweak here without touching logic
// ---------------------------------------------------------------------------

/// Total seconds for the blitz.
const double _ncDuration = 60.0;

/// Points for clearing a circuit, multiplied by (puzzle index + 1).
const int _ncBasePoints = 100;

/// Bonus points scaled by the fraction of the run still remaining.
const int _ncTimeBonusMax = 60;

/// How long (s) the chain must hold full alignment before it auto-fires. Stops
/// a one-frame flicker (esp. under entropy drift) from firing prematurely.
const double _ncArmTime = 0.12;

/// Seconds for the action potential to travel the whole chain.
const double _ncFireTravel = 0.5;

/// Touch grab radius (px) for picking up a neuron to aim it.
const double _ncGrabRadius = 58.0;

// Play-field insets (px) — keep nodes clear of the host HUD/timer + bottom.
const double _ncTopInset = 96.0;
const double _ncBottomInset = 54.0;
const double _ncSideInset = 34.0;

// Palette.
const Color _ncAccent = Color(0xFF9C6FFF); // relay violet / scale accent
const Color _ncSource = Color(0xFF40C4FF); // electric cyan — emitter
const Color _ncTarget = Color(0xFFFF6B6B); // warm coral — receiver
const Color _ncRelay = Color(0xFF9C6FFF); // violet — relay
const Color _ncLock = Color(0xFF69F0AE); // mint — hop aligned/locked
const Color _ncSignal = Color(0xFFE0F7FA); // near-white action potential
const Color _ncBlocker = Color(0xFF6A4A7A); // glial debris
const Color _ncDanger = Color(0xFFFF5252); // interference warning

double _deg(double d) => d * pi / 180.0;

// ---------------------------------------------------------------------------
// Field mapping — neurons live in unit space [0..1]² inside the play field.
// ---------------------------------------------------------------------------

Rect _ncField(Size s) => Rect.fromLTRB(
    _ncSideInset, _ncTopInset, s.width - _ncSideInset, s.height - _ncBottomInset);

Offset _ncToPixel(Offset u, Size s) {
  final f = _ncField(s);
  return Offset(f.left + u.dx * f.width, f.top + u.dy * f.height);
}

double _ncSomaR(Size s) => (_ncField(s).shortestSide * 0.052).clamp(15.0, 30.0);

/// Smallest absolute angular difference between two headings.
double _angDiff(double a, double b) {
  var d = (a - b) % (2 * pi);
  if (d > pi) d -= 2 * pi;
  if (d < -pi) d += 2 * pi;
  return d.abs();
}

/// Distance from point [p] to segment [a]→[b].
double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lenSq < 1e-6) return (p - a).distance;
  var t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum _NodeType { source, relay, target, blocker }

class _Neuron {
  final Offset base; // unit-space anchor
  final _NodeType type;
  double axon; // aim heading (radians, pixel-space) — source/relay only
  final double driftPhase;
  final double driftAmp; // unit-space wobble amplitude (entropy)
  final double dendriteSeed;

  _Neuron({
    required this.base,
    required this.type,
    required this.axon,
    required this.driftPhase,
    required this.driftAmp,
    required this.dendriteSeed,
  });

  bool get aimable => type == _NodeType.source || type == _NodeType.relay;

  /// Current unit-space position including entropy drift.
  Offset posAt(double t) => driftAmp <= 0
      ? base
      : Offset(
          (base.dx + sin(t * 1.1 + driftPhase) * driftAmp).clamp(0.05, 0.95),
          (base.dy + cos(t * 0.9 + driftPhase * 1.7) * driftAmp).clamp(0.05, 0.95),
        );
}

class _Puzzle {
  final List<_Neuron> nodes;
  final List<int> chain; // ordered indices: source … target
  final double tolerance; // radians a hop may be off and still lock
  final String twist; // the new component this round introduces
  _Puzzle(this.nodes, this.chain, this.tolerance, this.twist);
}

// ---------------------------------------------------------------------------
// Puzzle generation — curated onboarding curve, then procedural escalation.
// ---------------------------------------------------------------------------

_Puzzle _ncGen(int idx, Random rng) {
  int relays;
  bool blocker = false;
  bool diagonal = false;
  bool irregular = false;
  double drift = 0;
  double tol;
  String twist;

  switch (idx) {
    case 0:
      relays = 0;
      tol = _deg(16);
      twist = 'AIM THE AXON';
      break;
    case 1:
      relays = 1;
      tol = _deg(14);
      twist = 'RELAY ADDED';
      break;
    case 2:
      relays = 1;
      blocker = true;
      tol = _deg(13);
      twist = 'INTERFERENCE';
      break;
    case 3:
      relays = 2;
      diagonal = true;
      tol = _deg(11);
      twist = 'DIAGONAL FIELD';
      break;
    case 4:
      relays = 2;
      irregular = true;
      tol = _deg(10);
      twist = 'IRREGULAR SPACING';
      break;
    default:
      relays = (2 + (idx - 3) ~/ 2).clamp(2, 4);
      blocker = idx.isOdd;
      diagonal = idx % 3 == 0;
      irregular = true;
      drift = ((idx - 4) * 0.0035).clamp(0.0, 0.024);
      tol = _deg((10 - (idx - 4) * 0.55).clamp(6.0, 10.0));
      twist = drift > 0 ? 'ENTROPY FIELD' : 'DEEP CASCADE';
  }

  // Endpoints. Diagonal puzzles run corner-to-corner; others run side-to-side
  // with vertical variance so aims aren't all horizontal.
  final start = diagonal
      ? Offset(0.12, 0.14 + rng.nextDouble() * 0.12)
      : Offset(0.10, 0.22 + rng.nextDouble() * 0.5);
  final end = diagonal
      ? Offset(0.88, 0.86 - rng.nextDouble() * 0.12)
      : Offset(0.90, 0.22 + rng.nextDouble() * 0.5);

  // Relay parametric positions along start→end (irregular = uneven spacing).
  final ts = <double>[];
  for (int k = 1; k <= relays; k++) {
    ts.add(irregular
        ? (0.12 + 0.76 * rng.nextDouble())
        : k / (relays + 1));
  }
  ts.sort();

  final perp = Offset(-(end - start).dy, (end - start).dx); // ⟂ to the path
  final perpN = perp.distance < 1e-6 ? const Offset(0, 1) : perp / perp.distance;

  // Build path points: source, relays (jittered off-axis), target.
  final pts = <Offset>[start];
  for (int k = 0; k < relays; k++) {
    final base = Offset.lerp(start, end, ts[k])!;
    final jitter = (rng.nextDouble() - 0.5) * (diagonal ? 0.30 : 0.40);
    var p = base + perpN * jitter;
    p = Offset(p.dx.clamp(0.10, 0.90), p.dy.clamp(0.10, 0.90));
    pts.add(p);
  }
  pts.add(end);

  final nodes = <_Neuron>[];
  final chain = <int>[];
  for (int i = 0; i < pts.length; i++) {
    final type = i == 0
        ? _NodeType.source
        : (i == pts.length - 1 ? _NodeType.target : _NodeType.relay);
    // Scramble the initial axon well clear of the unit-space exact heading so
    // the puzzle never starts solved (pixel distortion is small vs this offset).
    double axon = 0;
    if (type != _NodeType.target) {
      final next = pts[i + 1];
      final exactUnit = atan2(next.dy - pts[i].dy, next.dx - pts[i].dx);
      final off = (1.0 + rng.nextDouble() * 1.6) * (rng.nextBool() ? 1 : -1);
      axon = exactUnit + off;
    }
    nodes.add(_Neuron(
      base: pts[i],
      type: type,
      axon: axon,
      driftPhase: rng.nextDouble() * 2 * pi,
      driftAmp: drift,
      dendriteSeed: rng.nextDouble() * 2 * pi,
    ));
    chain.add(i);
  }

  // Optional glial blocker: sit it just off a chain segment so a sloppy aim
  // clips it, while the true heading stays clear. Verify clearance or skip.
  if (blocker) {
    const margin = 0.075;
    for (int attempt = 0; attempt < 12; attempt++) {
      final seg = rng.nextInt(pts.length - 1);
      final mid = Offset.lerp(pts[seg], pts[seg + 1], 0.4 + rng.nextDouble() * 0.2)!;
      final side = rng.nextBool() ? 1.0 : -1.0;
      var b = mid + perpN * (margin * 1.7 * side);
      b = Offset(b.dx.clamp(0.10, 0.90), b.dy.clamp(0.10, 0.90));
      bool clear = true;
      for (int h = 0; h < pts.length - 1; h++) {
        if (_distToSegment(b, pts[h], pts[h + 1]) < margin) {
          clear = false;
          break;
        }
      }
      if (clear) {
        nodes.add(_Neuron(
          base: b,
          type: _NodeType.blocker,
          axon: 0,
          driftPhase: rng.nextDouble() * 2 * pi,
          driftAmp: 0,
          dendriteSeed: rng.nextDouble() * 2 * pi,
        ));
        break;
      }
    }
  }

  return _Puzzle(nodes, chain, tol, twist);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class NeuronConnectGame extends StatefulWidget {
  final MiniGameSession session;
  const NeuronConnectGame({Key? key, required this.session}) : super(key: key);
  @override
  State<NeuronConnectGame> createState() => _NeuronConnectGameState();
}

class _NeuronConnectGameState extends State<NeuronConnectGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Random _rng = Random();
  late final int _seedBase;

  double _clock = 0; // animation/drift clock
  double _elapsed = 0; // play time consumed
  double _lastWall = 0;

  int _idx = 0;
  int _cleared = 0;
  int _streak = 0;
  late _Puzzle _puzzle;

  Size _size = Size.zero;

  // Aiming.
  int? _grabbed;

  // Firing cascade.
  bool _firing = false;
  double _fireT = 0;
  double _armT = 0;

  // Juice.
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = []; // pos stored in UNIT space; converted in painter
  double _flash = 0;

  @override
  void initState() {
    super.initState();
    _seedBase = _rng.nextInt(1 << 20);
    _puzzle = _ncGen(0, Random(_seedBase));
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

  void _nextPuzzle() {
    _idx++;
    _puzzle = _ncGen(_idx, Random(_seedBase + _idx * 1009));
    _grabbed = null;
    _firing = false;
    _fireT = 0;
    _armT = 0;
  }

  // ── chain validity ─────────────────────────────────────────────────────

  /// Is hop [h] (chain[h] → chain[h+1]) currently aligned AND clear of blockers?
  bool _hopLocked(int h) {
    final nodes = _puzzle.nodes;
    final a = nodes[_puzzle.chain[h]];
    final b = nodes[_puzzle.chain[h + 1]];
    final ap = _ncToPixel(a.posAt(_clock), _size);
    final bp = _ncToPixel(b.posAt(_clock), _size);
    final exact = atan2(bp.dy - ap.dy, bp.dx - ap.dx);
    if (_angDiff(a.axon, exact) > _puzzle.tolerance) return false;
    // Beam must not pass through a glial blocker.
    final clearR = _ncSomaR(_size) * 1.15;
    for (final n in nodes) {
      if (n.type != _NodeType.blocker) continue;
      if (_distToSegment(_ncToPixel(n.posAt(_clock), _size), ap, bp) < clearR) {
        return false;
      }
    }
    return true;
  }

  bool get _solved {
    for (int h = 0; h < _puzzle.chain.length - 1; h++) {
      if (!_hopLocked(h)) return false;
    }
    return true;
  }

  // ── tick ───────────────────────────────────────────────────────────────

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    if (!widget.session.isRunning || _size == Size.zero) return;

    setState(() {
      _clock += dt;
      _elapsed += dt;
      if (_flash > 0) _flash = (_flash - dt * 3).clamp(0.0, 1.0);

      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (_firing) {
        _fireT += dt / _ncFireTravel;
        if (_fireT >= 1.0) _onCascadeComplete();
        return;
      }

      // Auto-fire once the whole chain holds alignment for the arm window.
      if (_solved) {
        _armT += dt;
        if (_armT >= _ncArmTime) {
          _firing = true;
          _fireT = 0;
          _grabbed = null;
        }
      } else {
        _armT = 0;
      }
    });
  }

  void _onCascadeComplete() {
    _cleared++;
    _streak++;
    widget.session.noteStreak(_streak);
    final remainFrac = (1 - _elapsed / _ncDuration).clamp(0.0, 1.0);
    final pts =
        _ncBasePoints * (_idx + 1) + (_ncTimeBonusMax * remainFrac).round();
    widget.session.addScore(pts);
    _flash = 0.7;

    // Burst at the target + a score pop above it.
    final tgt = _puzzle.nodes[_puzzle.chain.last];
    final tp = _ncToPixel(tgt.posAt(_clock), _size);
    _particles.addAll(FxBurst.spawn(tp, _ncSignal, count: 24, speed: 150));
    _particles.addAll(FxBurst.spawn(tp, _ncTarget, count: 14, speed: 90));
    final pop = FxPop(tgt.posAt(_clock), '+$pts', _ncLock); // unit-space anchor
    _pops.add(pop);

    _nextPuzzle();
  }

  // ── input — drag a neuron to swing its axon toward the finger ───────────

  int? _aimableAt(Offset p) {
    int? best;
    double bestD = _ncGrabRadius;
    for (int i = 0; i < _puzzle.nodes.length; i++) {
      final n = _puzzle.nodes[i];
      if (!n.aimable) continue;
      final d = (p - _ncToPixel(n.posAt(_clock), _size)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void _onPanStart(DragStartDetails d) {
    if (_firing || !widget.session.isRunning) return;
    _grabbed = _aimableAt(d.localPosition);
    if (_grabbed != null) _aimTo(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_grabbed == null) return;
    setState(() => _aimTo(d.localPosition));
  }

  void _aimTo(Offset p) {
    final n = _puzzle.nodes[_grabbed!];
    final c = _ncToPixel(n.posAt(_clock), _size);
    n.axon = atan2(p.dy - c.dy, p.dx - c.dx);
  }

  void _onPanEnd(_) => _grabbed = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NCPainter(
                puzzle: _puzzle,
                clock: _clock,
                grabbed: _grabbed,
                firing: _firing,
                fireT: _fireT,
                armFrac: (_armT / _ncArmTime).clamp(0.0, 1.0),
                hopLocked: List.generate(
                    _puzzle.chain.length - 1, (h) => _hopLocked(h)),
                particles: _particles,
                pops: _pops,
                flash: _flash,
              ),
            ),
          ),
          // Slim game-specific HUD — names the twist so the player learns it.
          // (Host owns score + timer.)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CIRCUIT #${_idx + 1}',
                    style: Potatuhs.label(size: 12, color: _ncAccent)),
                const SizedBox(height: 2),
                Text('$_cleared cleared',
                    style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
              const Spacer(),
              _twistChip(_puzzle.twist),
            ]),
          ),
          // Hint, lower-center.
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  _firing ? 'SIGNAL!' : 'Drag a neuron to aim its axon',
                  style: Potatuhs.body(
                      size: 12,
                      color: (_firing ? _ncLock : Colors.white)
                          .withValues(alpha: _firing ? 0.85 : 0.3)),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _twistChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _ncAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ncAccent.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 12, color: _ncAccent),
        const SizedBox(width: 5),
        Text(label,
            style: Potatuhs.label(size: 10, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — neurological visual system
// soma orb → dendrites → tapering axon process w/ growth cone → synapse beams
// ---------------------------------------------------------------------------

class _NCPainter extends CustomPainter {
  final _Puzzle puzzle;
  final double clock;
  final int? grabbed;
  final bool firing;
  final double fireT;
  final double armFrac;
  final List<bool> hopLocked;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final double flash;

  _NCPainter({
    required this.puzzle,
    required this.clock,
    required this.grabbed,
    required this.firing,
    required this.fireT,
    required this.armFrac,
    required this.hopLocked,
    required this.particles,
    required this.pops,
    required this.flash,
  });

  Color _colorFor(_NodeType t) {
    switch (t) {
      case _NodeType.source:
        return _ncSource;
      case _NodeType.target:
        return _ncTarget;
      case _NodeType.relay:
        return _ncRelay;
      case _NodeType.blocker:
        return _ncBlocker;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _ncAccent, clock, motes: 40);

    final somaR = _ncSomaR(size);
    Offset px(_Neuron n) => _ncToPixel(n.posAt(clock), size);

    // 1. Intended connections — faint dotted guides so the player reads the
    //    SOURCE → relay → TARGET order even before any hop locks.
    for (int h = 0; h < puzzle.chain.length - 1; h++) {
      final a = px(puzzle.nodes[puzzle.chain[h]]);
      final b = px(puzzle.nodes[puzzle.chain[h + 1]]);
      if (!hopLocked[h]) _dottedGuide(canvas, a, b);
    }

    // 2. Blockers (glial debris) — drawn under the beams.
    for (final n in puzzle.nodes) {
      if (n.type == _NodeType.blocker) _drawBlocker(canvas, px(n), somaR * 1.05);
    }

    // 3. Locked synapse beams (bright). During firing the leading edge glows.
    for (int h = 0; h < puzzle.chain.length - 1; h++) {
      if (!hopLocked[h]) continue;
      final a = px(puzzle.nodes[puzzle.chain[h]]);
      final b = px(puzzle.nodes[puzzle.chain[h + 1]]);
      GameFx.glowLine(canvas, a, b, _ncLock, width: 3.0);
    }

    // 4. Neurons.
    for (int i = 0; i < puzzle.nodes.length; i++) {
      final n = puzzle.nodes[i];
      final c = px(n);
      if (n.type == _NodeType.blocker) continue; // already drawn
      _drawNeuron(canvas, n, c, somaR, i == grabbed);
    }

    // 5. Action potential travelling the chain.
    if (firing) _drawSignal(canvas, size, somaR);

    // 6. Particles + pops.
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      final tmp = FxPop(Offset(0, 0), p.text, p.color)..life = p.life;
      // pops store a unit-space anchor in .pos — convert to pixels here.
      final pixel = _ncToPixel(p.pos, size);
      tmp.pos = pixel;
      tmp.paint(canvas);
    }

    // 7. Completion flash.
    if (flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _ncLock.withValues(alpha: flash * 0.12));
    }
  }

  // ── neuron rendering ────────────────────────────────────────────────────

  void _drawNeuron(
      Canvas canvas, _Neuron n, Offset c, double somaR, bool grabbed) {
    final color = _colorFor(n.type);
    final isSource = n.type == _NodeType.source;
    final isTarget = n.type == _NodeType.target;
    final phase = n.dendriteSeed;

    // Atmosphere halo.
    final haloR = somaR * (isSource || isTarget ? 2.0 : 1.5);
    final haloA = (isSource || isTarget ? 0.18 : 0.10) +
        0.06 * sin(clock * 1.6 + phase);
    canvas.drawCircle(
        c,
        haloR,
        Paint()
          ..color = color.withValues(alpha: haloA.clamp(0.0, 0.3))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    // Dendrites — receptive tendrils. Target gets a full receptive crown.
    _drawDendrites(canvas, c, somaR, n.aimable ? n.axon : null, color, phase);

    // Axon process — the thing you aim (source/relay).
    if (n.aimable) _drawAxon(canvas, c, somaR, n.axon, color);

    // Soma.
    GameFx.orb(canvas, c, somaR, color,
        glow: grabbed ? 1.4 : (isSource ? 1.1 : 0.85));

    // Identity rings.
    if (isSource) {
      final r = somaR * (1.45 + 0.18 * sin(clock * 2.4 + phase));
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _ncSource.withValues(
                alpha: (0.5 * (1 - (r - somaR * 1.45) / (somaR * 0.18)))
                    .clamp(0.0, 0.5)));
      GameFx.text(canvas, 'SOURCE', c.translate(0, somaR + 12), 8.5,
          _ncSource.withValues(alpha: 0.85));
    } else if (isTarget) {
      for (int ring = 0; ring < 2; ring++) {
        final rr = somaR * (1.45 + ring * 0.32) +
            (ring == 1 ? somaR * 0.12 * sin(clock * 1.4) : 0);
        canvas.drawCircle(
            c,
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = ring == 0 ? 2.0 : 1.2
              ..color = _ncTarget.withValues(alpha: ring == 0 ? 0.55 : 0.25));
      }
      GameFx.text(canvas, 'TARGET', c.translate(0, somaR + 12), 8.5,
          _ncTarget.withValues(alpha: 0.85));
    }

    // Grabbed: an aim arc sweeping with the axon for tactile feedback.
    if (grabbed && n.aimable) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: somaR + 14),
          n.axon - 0.5,
          1.0,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.6));
    }
  }

  /// Tapering axon shaft + growth-cone tip in the aim direction.
  void _drawAxon(Canvas canvas, Offset c, double somaR, double angle, Color color) {
    final dir = Offset(cos(angle), sin(angle));
    final start = c + dir * somaR;
    final len = somaR * 1.9;
    final end = c + dir * (somaR + len);

    // Glow underlay.
    canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Core shaft.
    canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round);
    // Growth cone — a small bright bulb that arms up before firing.
    final coneR = 3.2 + 1.6 * armFrac;
    canvas.drawCircle(end, coneR + 2,
        Paint()..color = color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(end, coneR, Paint()..color = Colors.white.withValues(alpha: 0.92));
  }

  /// Short branching dendrites. When [axonAngle] is given they cluster on the
  /// opposite side (a real neuron's dendrites face away from the axon); for the
  /// target (null) they form a full receptive crown.
  void _drawDendrites(Canvas canvas, Offset c, double somaR, double? axonAngle,
      Color color, double phase) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    const n = 5;
    for (int k = 0; k < n; k++) {
      double ang;
      if (axonAngle != null) {
        // Spread around the side opposite the axon (axon + pi ± spread).
        ang = axonAngle + pi + (k - (n - 1) / 2) * 0.5;
      } else {
        ang = k / n * 2 * pi + phase * 0.2;
      }
      ang += 0.05 * sin(phase + clock * 0.8 + k);
      final s = c + Offset(cos(ang), sin(ang)) * somaR * 0.95;
      final e = c + Offset(cos(ang), sin(ang)) * somaR * (1.55 + 0.12 * sin(phase + k));
      final a = (0.22 + 0.10 * sin(phase + clock * 0.5 + k)).clamp(0.0, 0.35);
      p.color = color.withValues(alpha: a);
      canvas.drawLine(s, e, p);
      canvas.drawCircle(e, 1.4, Paint()..color = color.withValues(alpha: a * 0.7));
    }
  }

  void _drawBlocker(Canvas canvas, Offset c, double r) {
    // Lumpy glial mass.
    canvas.drawCircle(
        c,
        r * 1.4,
        Paint()
          ..color = _ncDanger.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF2A2440),
            const Color(0xFF120E20),
          ]).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _ncDanger.withValues(alpha: 0.3 + 0.15 * sin(clock * 3)));
    // Inscribed hazard slash.
    final xr = r * 0.4;
    final xp = Paint()
      ..color = _ncDanger.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-xr, -xr), c.translate(xr, xr), xp);
    canvas.drawLine(c.translate(xr, -xr), c.translate(-xr, xr), xp);
  }

  void _dottedGuide(Canvas canvas, Offset a, Offset b) {
    final total = (b - a).distance;
    if (total < 1) return;
    final dir = (b - a) / total;
    const dash = 5.0, gap = 7.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    double d = 12; // start a little out from the soma
    while (d < total - 12) {
      final s = a + dir * d;
      final e = a + dir * min(d + dash, total - 12);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  void _drawSignal(Canvas canvas, Size size, double somaR) {
    // Build the chain polyline in pixels, then place the wavefront at fireT.
    final poly = <Offset>[
      for (final i in puzzle.chain)
        _ncToPixel(puzzle.nodes[i].posAt(clock), size)
    ];
    double total = 0;
    final segLen = <double>[];
    for (int i = 0; i < poly.length - 1; i++) {
      final l = (poly[i + 1] - poly[i]).distance;
      segLen.add(l);
      total += l;
    }
    if (total < 1) return;
    var target = fireT * total;
    Offset head = poly.last;
    for (int i = 0; i < segLen.length; i++) {
      if (target <= segLen[i]) {
        head = Offset.lerp(poly[i], poly[i + 1], target / segLen[i])!;
        break;
      }
      target -= segLen[i];
    }
    // Bright travelling pulse.
    canvas.drawCircle(head, somaR * 0.9,
        Paint()..color = _ncSignal.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    GameFx.orb(canvas, head, somaR * 0.42, _ncSignal, glow: 1.4);
  }

  @override
  bool shouldRepaint(covariant _NCPainter old) => true;
}
