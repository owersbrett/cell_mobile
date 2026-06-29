// BranchGame — "Branch" (many-worlds timeline navigation).
//
// A binary TREE of timelines grows toward you from the right. At every quantum
// decision the world SPLITS into two — an UP branch and a DOWN branch — and
// BOTH happen. You ride the leading tip ("you", the observer). Each fork's two
// children carry an AMPLITUDE (the |ψ|² weight of that branch); the higher one
// is drawn brighter/bigger and labelled with its percentage.
//
// TAP the TOP half to steer "you" onto the upper branch, the BOTTOM half for
// the lower one. When the fork reaches the decision line it RESOLVES: you snap
// onto the selected child and collect ITS amplitude as score. Riding the
// higher-amplitude branch is a CLEAN navigation (streak + bonus); riding the
// smaller one still works (no punishment) — you just gathered less of your own
// measure. You can never prune the branch you didn't take: it keeps splitting
// on its own behind you, a fading fractal fan (decoherence pruning the low
// amplitude worlds out of view).
//
// Accelerates: the front advances faster, amplitudes drift toward 50/50 (harder
// to read which world is heavier), and the generations pack tighter so more
// forks are in flight at once.
//
// Self-contained module. Imports only the framework session + shared FX/theme.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tweak here without touching logic
// ---------------------------------------------------------------------------

/// The bright "you ride this" branch color (electric timeline cyan). Chosen to
/// read as DISTINCT from Reality Merge's violet rings.
const Color _bAccent = Color(0xFF54D1FF);

/// Muted color for branches you did not take — the decohering ghost worlds.
const Color _bGhost = Color(0xFF6A6480);

/// Fraction of width where a fork resolves (the "now" line).
const double _bDecisionX = 0.30;

/// Play-field insets (px) — keep the tree clear of the host HUD/timer + bottom.
const double _bFieldTop = 92.0;
const double _bFieldBottom = 56.0;

/// Points awarded scale with the amplitude of the branch you collected.
const double _bAmpPoints = 130.0;

/// Vertical split half-spread (normalized) of a fork's two children.
const double _bSpreadLo = 0.12;
const double _bSpreadHi = 0.07; // extra random component

/// Max trailing segments kept for the wake (older ones have scrolled off).
const int _bTrailCap = 9;

enum _Sel { up, down }

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// The single pending fork growing out of the current node into two children.
class _Fork {
  final int gen; // generation index of the CHILDREN
  final double parentY; // yNorm of the node it grows from
  final double upY;
  final double downY;
  final double upAmp;
  final double downAmp;
  final int seed; // stable seed for decorative sub-fans
  const _Fork({
    required this.gen,
    required this.parentY,
    required this.upY,
    required this.downY,
    required this.upAmp,
    required this.downAmp,
    required this.seed,
  });
}

/// One resolved segment in the wake: the chosen leg (bright) + the ghost leg you
/// abandoned (which keeps splitting on its own).
class _Seg {
  final int gen; // parent generation
  final double pY; // parent yNorm
  final double cY; // chosen child yNorm
  final double gY; // ghost (abandoned) child yNorm
  final double gAmp; // ghost amplitude (drives its decoherence fade)
  final int seed;
  const _Seg({
    required this.gen,
    required this.pY,
    required this.cY,
    required this.gY,
    required this.gAmp,
    required this.seed,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BranchGame extends StatefulWidget {
  final MiniGameSession session;
  const BranchGame({super.key, required this.session});

  @override
  State<BranchGame> createState() => _BranchGameState();
}

class _BranchGameState extends State<BranchGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  Size _size = Size.zero;

  double _clock = 0; // atmosphere clock
  double _t = 0; // running play time → difficulty
  double _lastWall = 0;

  // Branching front.
  int _curGen = 0;
  double _curY = 0.5;
  double _frac = 0; // 0..1 progress of the front toward the next fork
  late _Fork _fork;
  _Sel _sel = _Sel.up;

  final List<_Seg> _trail = [];
  int _streak = 0;

  // Juice.
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];
  double _flash = 0;
  Color _flashColor = Colors.white;
  double _resolvePulse = 0; // brief pulse on the new node after a resolve
  String _lastTier = '';
  double _tierShow = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastWall = _now();
    _fork = _genFork();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── difficulty curves ────────────────────────────────────────────────────

  /// Generations advanced per second — the front speeds up over the round.
  double get _speed => (0.55 + _t * 0.02).clamp(0.55, 1.55);

  /// Amplitude gap above 0.5 for the heavier branch. Shrinks toward a coin
  /// flip so late forks are genuinely hard to read.
  double get _gap => (0.34 - _t * 0.006).clamp(0.06, 0.34);

  /// Generation spacing as a fraction of width. Shrinks so more forks pack into
  /// the field at once ("more simultaneous forks").
  double get _genFrac => (0.36 - _t * 0.0028).clamp(0.20, 0.36);

  // ── geometry ──────────────────────────────────────────────────────────────

  double get _front => _curGen + _frac;

  Offset _screenPos(int gen, double yNorm) {
    final w = _size.width, h = _size.height;
    final genPx = w * _genFrac;
    final dx = w * _bDecisionX + (gen - _front) * genPx;
    final top = _bFieldTop;
    final bot = math.max(top + 40.0, h - _bFieldBottom);
    final dy = top + yNorm.clamp(0.0, 1.0) * (bot - top);
    return Offset(dx, dy);
  }

  // ── fork generation ────────────────────────────────────────────────────────

  _Fork _genFork() {
    final gap = _gap;
    final upHeavy = _rng.nextBool();
    final hi = 0.5 + gap;
    final lo = 0.5 - gap;

    final spread = _bSpreadLo + _rng.nextDouble() * _bSpreadHi;
    var upY = (_curY - spread).clamp(0.06, 0.94);
    var downY = (_curY + spread).clamp(0.06, 0.94);
    // Guarantee a legible vertical gap even when the parent sits near an edge.
    if (downY - upY < 0.14) {
      upY = (0.5 - spread).clamp(0.06, 0.94);
      downY = (0.5 + spread).clamp(0.06, 0.94);
    }

    return _Fork(
      gen: _curGen + 1,
      parentY: _curY,
      upY: upY,
      downY: downY,
      upAmp: upHeavy ? hi : lo,
      downAmp: upHeavy ? lo : hi,
      seed: _rng.nextInt(1 << 20),
    );
  }

  // ── tick ───────────────────────────────────────────────────────────────────

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    if (_size == Size.zero) return;

    setState(() {
      _clock += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.6).clamp(0.0, 1.0);
      if (_resolvePulse > 0) {
        _resolvePulse = (_resolvePulse - dt * 3.0).clamp(0.0, 1.0);
      }
      if (_tierShow > 0) _tierShow = (_tierShow - dt * 1.3).clamp(0.0, 1.0);
      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (!widget.session.isRunning) return; // calm: hold the tree still

      _t += dt;
      _frac += dt * _speed;
      // Resolve every fork the front has crossed this frame.
      var guard = 0;
      while (_frac >= 1.0 && guard++ < 6) {
        _frac -= 1.0;
        _resolveFork();
      }
    });
  }

  // ── resolve ─────────────────────────────────────────────────────────────────

  void _resolveFork() {
    final f = _fork;
    final up = _sel == _Sel.up;
    final chosenY = up ? f.upY : f.downY;
    final ghostY = up ? f.downY : f.upY;
    final chosenAmp = up ? f.upAmp : f.downAmp;
    final ghostAmp = up ? f.downAmp : f.upAmp;
    final clean = chosenAmp >= ghostAmp;

    var pts = (chosenAmp * _bAmpPoints).round();
    String tier;
    if (clean) {
      _streak++;
      pts += (16 + _streak * 3).clamp(0, 80);
      tier = 'CLEAN';
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
      tier = 'SPLIT';
    }
    widget.session.addScore(pts);

    // Record the wake segment BEFORE advancing.
    _trail.add(_Seg(
      gen: _curGen,
      pY: _curY,
      cY: chosenY,
      gY: ghostY,
      gAmp: ghostAmp,
      seed: f.seed,
    ));
    while (_trail.length > _bTrailCap) {
      _trail.removeAt(0);
    }

    // Advance the front onto the chosen child.
    _curGen++;
    _curY = chosenY;

    // Juice at the new node.
    final pos = _screenPos(_curGen, _curY);
    final col = clean ? _bAccent : const Color(0xFFFFC15A);
    _particles.addAll(FxBurst.spawn(pos, col, count: clean ? 18 : 12, speed: 150));
    _pops.add(FxPop(pos.translate(0, -26),
        clean ? 'CLEAN +$pts' : '+$pts', clean ? _bAccent : Colors.white));
    _flash = clean ? 0.6 : 0.35;
    _flashColor = col;
    _resolvePulse = 1.0;
    _lastTier = tier;
    _tierShow = 1.0;

    // Grow the next fork.
    _fork = _genFork();
    _sel = _Sel.up;
  }

  // ── input ───────────────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _size == Size.zero) return;
    final mid = _size.height * 0.5;
    setState(() => _sel = d.localPosition.dy < mid ? _Sel.up : _Sel.down);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      final running = widget.session.isRunning;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BranchPainter(
                clock: _clock,
                pos: _screenPos,
                decisionX: _size.width * _bDecisionX,
                fork: _fork,
                sel: _sel,
                trail: _trail,
                curGen: _curGen,
                curY: _curY,
                resolvePulse: _resolvePulse,
                flash: _flash,
                flashColor: _flashColor,
                particles: _particles,
                pops: _pops,
                running: running,
              ),
            ),
          ),
          // Slim game HUD (host owns score + timer).
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RIDE THE HEAVIER BRANCH',
                    style: Potatuhs.label(size: 12, color: _bAccent)),
                const SizedBox(height: 2),
                Text('gen $_curGen · streak $_streak',
                    style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
              const Spacer(),
              if (_tierShow > 0 && _lastTier.isNotEmpty) _tierChip(),
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
                  running
                      ? 'TAP top / bottom — both worlds happen, ride the bigger one'
                      : 'Every choice splits the world. Ride the heavier branch.',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                    size: 12,
                    color: Colors.white.withValues(alpha: running ? 0.34 : 0.6),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _tierChip() {
    final c = _lastTier == 'CLEAN' ? _bAccent : const Color(0xFFFFC15A);
    return Opacity(
      opacity: _tierShow.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.55)),
        ),
        child: Text(_lastTier,
            style: Potatuhs.label(
                size: 11, color: Colors.white.withValues(alpha: 0.92))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — the live branching tree
// ---------------------------------------------------------------------------

class _BranchPainter extends CustomPainter {
  final double clock;
  final Offset Function(int, double) pos;
  final double decisionX;
  final _Fork fork;
  final _Sel sel;
  final List<_Seg> trail;
  final int curGen;
  final double curY;
  final double resolvePulse;
  final double flash;
  final Color flashColor;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final bool running;

  _BranchPainter({
    required this.clock,
    required this.pos,
    required this.decisionX,
    required this.fork,
    required this.sel,
    required this.trail,
    required this.curGen,
    required this.curY,
    required this.resolvePulse,
    required this.flash,
    required this.flashColor,
    required this.particles,
    required this.pops,
    required this.running,
  });

  bool _ok(Offset o) => o.dx.isFinite && o.dy.isFinite;

  /// Deterministic 0..1 hash from an int seed.
  double _h(int s) {
    final x = math.sin(s * 12.9898 + 4.13) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _bAccent, clock, motes: 34);

    // Decision line — the "now" where forks collapse onto your worldline.
    final lp = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.4;
    canvas.drawLine(
        Offset(decisionX, _bFieldTop - 6),
        Offset(decisionX, size.height - _bFieldBottom + 6),
        lp);

    // ── Wake: chosen worldline (bright) + abandoned ghost branches ──
    for (final s in trail) {
      final p = pos(s.gen, s.pY);
      final c = pos(s.gen + 1, s.cY);
      final g = pos(s.gen + 1, s.gY);
      if (!_ok(p)) continue;
      // Chosen leg — solid bright worldline.
      if (_ok(c)) {
        canvas.drawLine(
          p,
          c,
          Paint()
            ..color = _bAccent.withValues(alpha: 0.55)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
      // Abandoned leg — keeps splitting on its own, decohering away.
      if (_ok(g)) {
        final ga = (0.10 + s.gAmp * 0.22);
        canvas.drawLine(
          p,
          g,
          Paint()
            ..color = _bGhost.withValues(alpha: ga)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
        _ghostFan(canvas, g, pos(s.gen + 2, s.gY), s.seed, ga * 0.8, 2);
      }
    }

    // ── Pending fork: the next quantum decision approaching the line ──
    final parent = pos(fork.gen - 1, fork.parentY);
    final up = pos(fork.gen, fork.upY);
    final down = pos(fork.gen, fork.downY);

    if (_ok(parent)) {
      _drawLeg(canvas, parent, up, fork.upAmp, sel == _Sel.up, fork.seed * 3);
      _drawLeg(
          canvas, parent, down, fork.downAmp, sel == _Sel.down, fork.seed * 7);
    }

    // ── "You" — the observer node at the current tip ──
    final you = pos(curGen, curY);
    if (_ok(you)) {
      if (resolvePulse > 0) {
        canvas.drawCircle(
          you,
          10 + (1 - resolvePulse) * 26,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * resolvePulse + 0.5
            ..color = _bAccent.withValues(alpha: resolvePulse * 0.6),
        );
      }
      GameFx.orb(canvas, you, 8.5, _bAccent, glow: 1.1);
      GameFx.text(canvas, 'YOU', you.translate(0, -22), 10,
          Colors.white.withValues(alpha: 0.7));
    }

    // ── Juice ──
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }

    // ── Resolve flash ──
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color =
              flashColor.withValues(alpha: (flash * 0.12).clamp(0.0, 0.2)),
      );
    }
  }

  /// One fork leg: branch line + child node sized/labelled by its amplitude.
  /// The selected leg is highlighted (this is where "you" will go).
  void _drawLeg(Canvas canvas, Offset parent, Offset child, double amp,
      bool selected, int seed) {
    if (!_ok(child)) return;
    final heavy = amp >= 0.5;
    final base = heavy ? _bAccent : _bGhost;

    // Forward fan beyond the child — the world will keep splitting regardless.
    final ahead = Offset(child.dx + (child.dx - parent.dx), child.dy);
    _ghostFan(canvas, child, ahead, seed, 0.16, 2);

    // The branch line.
    canvas.drawLine(
      parent,
      child,
      Paint()
        ..color = base.withValues(alpha: selected ? 0.9 : (0.32 + amp * 0.3))
        ..strokeWidth = selected ? 4.0 : (1.8 + amp * 2.2)
        ..strokeCap = StrokeCap.round
        ..maskFilter = selected
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null,
    );

    // Selection halo (where "you" are steering).
    if (selected) {
      canvas.drawCircle(
        child,
        13 + 2 * math.sin(clock * 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = _bAccent.withValues(alpha: 0.85),
      );
    }

    // Child node — radius & brightness encode amplitude (Born weight).
    final r = 4.5 + amp * 7.0;
    GameFx.orb(canvas, child, r, base,
        glow: selected ? 1.0 : (0.3 + amp * 0.5));

    // Amplitude label — the educational read.
    final pct = (amp * 100).round();
    GameFx.text(
      canvas,
      '$pct%',
      child.translate(0, -(r + 12)),
      heavy ? 13 : 11,
      (heavy ? _bAccent : _bGhost)
          .withValues(alpha: selected ? 1.0 : 0.85),
      weight: heavy ? FontWeight.w800 : FontWeight.w600,
    );
  }

  /// A small fading fractal fan from [from] toward [toward] — the unridden tree
  /// continuing to split, with each generation decohering (lower alpha).
  void _ghostFan(
      Canvas canvas, Offset from, Offset toward, int seed, double alpha,
      int depth) {
    if (depth <= 0 || alpha < 0.02 || !_ok(from) || !_ok(toward)) return;
    final dx = (toward.dx - from.dx);
    final spreadY = 14.0 + 6.0 * _h(seed);
    for (var k = 0; k < 2; k++) {
      final sign = k == 0 ? -1.0 : 1.0;
      final jitter = (_h(seed * 31 + k * 17) - 0.5) * 10;
      final tip = Offset(
        from.dx + dx * 0.6,
        from.dy + sign * spreadY + jitter,
      );
      if (!_ok(tip)) continue;
      canvas.drawLine(
        from,
        tip,
        Paint()
          ..color = _bGhost.withValues(alpha: alpha)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
          tip, 1.6, Paint()..color = _bGhost.withValues(alpha: alpha * 0.9));
      _ghostFan(canvas, tip, Offset(tip.dx + dx * 0.5, tip.dy),
          seed * 13 + k * 5, alpha * 0.55, depth - 1);
    }
  }

  @override
  bool shouldRepaint(covariant _BranchPainter old) => true;
}
