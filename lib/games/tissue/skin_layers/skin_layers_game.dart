import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Skin Layers — a tissue-scale ANATOMY & DEPTH-ORDER primer.
///
/// You rebuild a slice of skin by stacking its layers in the correct depth
/// order, SURFACE at the top → DEEP at the bottom: the epidermis (and, at
/// higher levels, its sub-strata), the dermis (with hair follicles, glands,
/// vessels and nerves), then the hypodermis (fat). A shuffled tray of layer
/// tiles sits below; drag each into the band at its correct depth. Put a tile
/// in its right place and that link reads healthy; misplace it and the boundary
/// with its neighbour FLAGS red, showing exactly where the order breaks. Fill
/// every band in order and the section "comes alive" — the skin pulses, sweat
/// beads, hair sprouts — you bank a cross-section bonus, then a new, deeper
/// section appears. Tap any tile to read its one-line role.
///
/// The lesson is the mechanic: skin is a NAMED, DEPTH-ORDERED stack of layers,
/// each holding specific structures and doing a specific job — and depth order
/// is not arbitrary (dead barrier on top, living dividing cells below, fat
/// deepest). Every tile teaches what its layer holds and does the moment you
/// touch it.
///
/// The host (MiniGameHost) owns the 60-second clock, the 3-2-1 countdown, the
/// score HUD and the results screen; this widget renders ONLY the play area and
/// reports points via `session.addScore` / `session.noteStreak`. All rendering
/// is a single Ticker-driven CustomPainter — drag just mutates tile positions.
class SkinLayersGame extends StatefulWidget {
  final MiniGameSession session;
  const SkinLayersGame({super.key, required this.session});

  @override
  State<SkinLayersGame> createState() => _SkinLayersGameState();
}

// ── Layer catalog ─────────────────────────────────────────────────────────────

enum _LayerId {
  // Major layers (level-0 primer).
  epidermis,
  dermis,
  hypodermisMajor,
  // Epidermal sub-strata (surface → deep).
  corneum,
  granulosum,
  spinosum,
  basale,
  // Dermal layers + structures (upper → lower).
  papillary,
  sebaceous,
  hairFollicle,
  nerveEnding,
  reticular,
  sweatGland,
  bloodVessel,
  // Deepest.
  hypodermis,
}

class _Layer {
  /// Canonical depth: 0 = skin surface, larger = deeper. Drives correct order.
  final int depth;
  final String name;
  final String abbrev;
  final String role; // the one-line anatomy lesson
  final String emoji;
  final Color color;
  const _Layer(
      this.depth, this.name, this.abbrev, this.role, this.emoji, this.color);
}

const Map<_LayerId, _Layer> _kLayers = {
  // ── Majors (only used together in the level-0 primer) ──
  _LayerId.epidermis: _Layer(0, 'Epidermis', 'EPI',
      'Outer barrier — waterproofs and shields you from the world.', '🛡',
      Color(0xFFFFCCBC)),
  _LayerId.dermis: _Layer(4, 'Dermis', 'DERM',
      'Tough middle layer — holds nerves, glands, vessels and hair roots.',
      '🧶', Color(0xFFFF8A65)),
  _LayerId.hypodermisMajor: _Layer(11, 'Hypodermis', 'FAT',
      'Deep fat layer — insulates, cushions and stores energy.', '🧈',
      Color(0xFFFFD54F)),

  // ── Epidermal strata (surface → deep) ──
  _LayerId.corneum: _Layer(0, 'Corneum', 'CORN',
      'Stratum corneum — dead flat cells form a tough waterproof shield.', '🛡',
      Color(0xFFFFE0D6)),
  _LayerId.granulosum: _Layer(1, 'Granulosum', 'GRAN',
      'Stratum granulosum — cells fill with keratin and begin to die.', '✨',
      Color(0xFFFFD0BE)),
  _LayerId.spinosum: _Layer(2, 'Spinosum', 'SPIN',
      'Stratum spinosum — spiny cells lock together for strength.', '🔗',
      Color(0xFFFFB59C)),
  _LayerId.basale: _Layer(3, 'Basale', 'BASE',
      'Stratum basale — new skin cells divide here; holds pigment cells.', '🌱',
      Color(0xFFFF9478)),

  // ── Dermal layers + structures (upper → lower) ──
  _LayerId.papillary: _Layer(4, 'Papillary', 'PAP',
      'Papillary dermis — loose tissue; capillaries feed the epidermis.', '🫧',
      Color(0xFFFF7F55)),
  _LayerId.sebaceous: _Layer(5, 'Sebaceous', 'OIL',
      'Sebaceous gland — oils the hair and skin to keep it supple.', '🛢',
      Color(0xFFFFEE58)),
  _LayerId.hairFollicle: _Layer(6, 'Hair Follicle', 'HAIR',
      'Hair follicle — the root pocket that grows each hair.', '🧵',
      Color(0xFF8D6E63)),
  _LayerId.nerveEnding: _Layer(7, 'Nerve', 'NERVE',
      'Nerve ending — senses touch, pressure, pain and temperature.', '⚡',
      Color(0xFFBA68C8)),
  _LayerId.reticular: _Layer(8, 'Reticular', 'RETIC',
      'Reticular dermis — dense collagen gives skin strength and stretch.',
      '🧶', Color(0xFFF4511E)),
  _LayerId.sweatGland: _Layer(9, 'Sweat Gland', 'SWEAT',
      'Sweat gland — coiled gland that cools you by releasing sweat.', '💧',
      Color(0xFF4FC3F7)),
  _LayerId.bloodVessel: _Layer(10, 'Blood Vessel', 'VESSEL',
      'Blood vessel — feeds the skin and regulates body heat.', '🩸',
      Color(0xFFEF5350)),

  // ── Deepest ──
  _LayerId.hypodermis: _Layer(11, 'Hypodermis', 'FAT',
      'Hypodermis — deep fat layer; insulates, cushions and stores energy.',
      '🧈', Color(0xFFFFD54F)),
};

_Layer _layer(_LayerId id) => _kLayers[id]!;

// ── Mutable play objects ─────────────────────────────────────────────────────

class _Tile {
  final _LayerId layer;
  double x = 0, y = 0; // current center (px)
  double homeX = 0, homeY = 0; // resting tray position
  int? slot; // band index if placed, else null (in tray)
  _Tile(this.layer);
}

enum _Phase { stack, alive }

// ── State ────────────────────────────────────────────────────────────────────

class _SkinLayersGameState extends State<SkinLayersGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final int _gameSeed;
  late math.Random _rng;

  double _lastT = 0;
  double _clock = 0;

  int _level = 0; // sections completed = current difficulty level
  _Phase _phase = _Phase.stack;
  double _stackStartClock = 0;

  // Current section.
  List<_LayerId> _correct = const []; // expected order, slot i (top) ⇒ deepest down
  List<_Tile> _tiles = [];
  int _nSlots = 0;
  final Set<int> _scoredSlots = {}; // band indices already awarded
  int _streak = 0; // consecutive correct placements / clean sections

  // Layout (recomputed each build).
  List<Rect> _slotRects = const [];
  double _slotW = 220, _slotH = 48, _trayW = 110, _trayH = 38;

  Size _sz = Size.zero;
  _Tile? _drag;
  int? _dragOriginSlot;

  // Role card.
  String _roleText = '';
  Color _roleColor = Colors.white;
  double _roleAge = 99;

  // Alive (come-alive) phase.
  double _aliveAge = 0;
  double _aliveDur = 1.6;

  // Juice.
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _aliveGlow = 0;

  static const Color _accent = Color(0xFFFF8A65); // skin/dermis warm orange
  static const Color _good = Color(0xFF80CBC4);

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
    _newSection(first: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Section composition ──────────────────────────────────────────────────────

  /// Build the correct depth order for a section at [level]. Level 0 is the
  /// gentle three-layer primer; later levels expand the epidermis into its
  /// strata and weave in dermal structures, growing longer and harder.
  List<_LayerId> _composeSection(int level) {
    if (level == 0) {
      return const [
        _LayerId.epidermis,
        _LayerId.dermis,
        _LayerId.hypodermis,
      ];
    }
    // Detailed mode: never mixes the "major" stand-ins with their sub-strata.
    final required = <_LayerId>{
      _LayerId.corneum,
      _LayerId.basale,
      _LayerId.reticular,
      _LayerId.hypodermis,
    };
    final targetLen = (4 + level).clamp(4, 7);

    final pool = <_LayerId>[
      _LayerId.granulosum,
      _LayerId.spinosum,
      _LayerId.papillary,
      _LayerId.sebaceous,
      _LayerId.hairFollicle,
      _LayerId.nerveEnding,
      _LayerId.sweatGland,
      _LayerId.bloodVessel,
    ].where((s) => !required.contains(s)).toList()
      ..shuffle(_rng);

    final need = (targetLen - required.length).clamp(0, pool.length);
    final section = <_LayerId>{...required, ...pool.take(need)}.toList()
      ..sort((a, b) => _layer(a).depth.compareTo(_layer(b).depth));
    return section;
  }

  void _newSection({bool first = false}) {
    _correct = _composeSection(_level);
    _nSlots = _correct.length;
    _scoredSlots.clear();
    _phase = _Phase.stack;
    _stackStartClock = _clock;
    _drag = null;
    _dragOriginSlot = null;
    _aliveAge = 0;
    _aliveGlow = 0;

    // One tile per layer; tray order shuffled so placement is never trivial.
    _tiles = [for (final s in _correct) _Tile(s)];
    final order = List<int>.generate(_nSlots, (i) => i)..shuffle(_rng);
    _tiles = [for (final i in order) _tiles[i]];

    if (!first && _sz != Size.zero) _positionTiles(_sz.width, _sz.height);
  }

  // ── Layout ───────────────────────────────────────────────────────────────────

  void _computeSlots(double w, double h) {
    final n = _nSlots;
    if (n == 0) {
      _slotRects = const [];
      return;
    }
    const gap = 6.0;
    final stackTop = h * 0.10;
    final stackBottom = h * 0.60;
    final avail = stackBottom - stackTop;
    _slotH = ((avail - gap * (n - 1)) / n).clamp(24.0, 66.0);
    final totalH = _slotH * n + gap * (n - 1);
    final startY = stackTop + (avail - totalH) / 2;
    _slotW = (w * 0.70).clamp(120.0, 360.0);
    final left = (w - _slotW) / 2;
    _slotRects = [
      for (var i = 0; i < n; i++)
        Rect.fromLTWH(left, startY + i * (_slotH + gap), _slotW, _slotH),
    ];
  }

  /// Assign resting tray positions and snap every non-dragged tile to its home
  /// (tray) or its band. Deterministic, so resizes and drops stay consistent.
  void _positionTiles(double w, double h) {
    _computeSlots(w, h);
    final n = _tiles.length;
    if (n == 0) return;

    _trayW = (w * 0.30).clamp(82.0, 150.0);
    _trayH = 38;
    const gap = 8.0;
    final perRow = ((w - 16) / (_trayW + gap)).floor().clamp(1, n);
    final rows = (n / perRow).ceil();
    final baseY = h * 0.92;

    for (var i = 0; i < n; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final inRow = (row == rows - 1) ? n - row * perRow : perRow;
      final rowStartX = w / 2 - (inRow - 1) * (_trayW + gap) / 2;
      _tiles[i].homeX = rowStartX + col * (_trayW + gap);
      _tiles[i].homeY = baseY - (rows - 1 - row) * (_trayH + 8);
    }

    for (final t in _tiles) {
      if (identical(t, _drag)) continue;
      if (t.slot != null && t.slot! < _slotRects.length) {
        t.x = _slotRects[t.slot!].center.dx;
        t.y = _slotRects[t.slot!].center.dy;
      } else {
        t.x = t.homeX;
        t.y = t.homeY;
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
    if (_roleAge < 99) _roleAge += dt;
    if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 2).clamp(0.0, 1.0);
    if (_aliveGlow > 0) _aliveGlow = (_aliveGlow - dt * 1.2).clamp(0.0, 1.0);

    if (!widget.session.isRunning) return;
    _clock += dt;

    if (_phase == _Phase.alive) {
      _aliveAge += dt;
      // Living skin: sweat beads + sparks rise from the stack while it pulses.
      if (_sz != Size.zero && _rng.nextDouble() < 0.5 && _slotRects.isNotEmpty) {
        final r = _slotRects[_rng.nextInt(_slotRects.length)];
        _fx.add(FxParticle(
          Offset(r.left + _rng.nextDouble() * r.width, r.center.dy),
          Offset((_rng.nextDouble() - 0.5) * 30, -40 - _rng.nextDouble() * 40),
          _good,
          2.0 + _rng.nextDouble() * 2,
        ));
      }
      if (_aliveAge >= _aliveDur) {
        _level++;
        _newSection();
      }
    }
  }

  // ── Placement / scoring ──────────────────────────────────────────────────────

  void _showRole(_LayerId s) {
    final l = _layer(s);
    _roleText = '${l.name} — ${l.role}';
    _roleColor = l.color;
    _roleAge = 0;
  }

  void _placeTile(_Tile t, int slotIdx) {
    t.slot = slotIdx;
    t.x = _slotRects[slotIdx].center.dx;
    t.y = _slotRects[slotIdx].center.dy;
    _showRole(t.layer);

    final correct = _correct[slotIdx] == t.layer;
    if (correct) {
      if (!_scoredSlots.contains(slotIdx)) {
        _scoredSlots.add(slotIdx);
        _streak++;
        widget.session.noteStreak(_streak);
        final pts = 15 + _streak * 2;
        widget.session.addScore(pts);
        final c = _slotRects[slotIdx].center;
        _fx.addAll(FxBurst.spawn(c, _layer(t.layer).color, count: 12));
        _pops.add(FxPop(c.translate(0, -22), '+$pts', _layer(t.layer).color));
      }
    } else {
      _streak = 0;
      _wrongFlash = 0.5;
    }
    _checkComplete();
  }

  void _removeTile(_Tile t) {
    t.slot = null;
    t.x = t.homeX;
    t.y = t.homeY;
    _showRole(t.layer);
  }

  void _checkComplete() {
    if (_phase != _Phase.stack) return;
    final filled = _tiles.every((t) => t.slot != null);
    if (!filled) return;
    final allCorrect = List<bool>.generate(
        _nSlots, (i) => _tileInSlot(i)?.layer == _correct[i]).every((b) => b);
    if (!allCorrect) {
      // Filled but out of depth order — the red boundary shows where it breaks.
      _wrongFlash = 0.5;
      return;
    }
    _completeSection();
  }

  void _completeSection() {
    final elapsed = _clock - _stackStartClock;
    final par = _nSlots * 3.0;
    final speedBonus = ((par - elapsed) * 4).clamp(0.0, 60.0).round();
    // Clean section grows the streak; the bonus scales with depth + speed.
    _streak++;
    widget.session.noteStreak(_streak);
    final bonus = 40 + _level * 12 + speedBonus;
    widget.session.addScore(bonus);
    _aliveGlow = 1.0;
    if (_sz != Size.zero && _slotRects.isNotEmpty) {
      _pops.add(FxPop(Offset(_sz.width / 2, _slotRects.first.top - 16),
          'SKIN ALIVE +$bonus', _good));
      for (final r in _slotRects) {
        _fx.addAll(FxBurst.spawn(r.center, _accent, count: 6, speed: 90));
      }
    }
    // Begin the alive phase: the rebuilt skin comes to life briefly.
    _phase = _Phase.alive;
    _aliveAge = 0;
    _aliveDur = 1.6;
  }

  _Tile? _tileInSlot(int i) {
    for (final t in _tiles) {
      if (t.slot == i) return t;
    }
    return null;
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  _Tile? _tileAt(Offset p) {
    _Tile? best;
    var bestD = double.infinity;
    for (final t in _tiles) {
      final placed = t.slot != null;
      final halfW = (placed ? _slotW : _trayW) * 0.5 + 6;
      final halfH = (placed ? _slotH : _trayH) * 0.5 + 6;
      final dx = (t.x - p.dx).abs();
      final dy = (t.y - p.dy).abs();
      if (dx <= halfW && dy <= halfH) {
        final d = dx + dy;
        if (d < bestD) {
          bestD = d;
          best = t;
        }
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
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.stack) return;
    final t = _tileAt(p);
    if (t == null) return;
    if (t.slot != null) {
      setState(() => _removeTile(t)); // pull a placed tile back to rearrange
    } else {
      setState(() => _showRole(t.layer)); // teach the role on tap
    }
  }

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning || _phase != _Phase.stack) return;
    final t = _tileAt(p);
    if (t == null) return;
    _drag = t;
    _dragOriginSlot = t.slot;
    if (t.slot != null) t.slot = null; // vacate while carrying
    t.x = p.dx;
    t.y = p.dy;
    setState(() {});
  }

  void _onPanUpdate(Offset p) {
    final t = _drag;
    if (t == null) return;
    t.x = p.dx; // ticker repaints; no setState needed for smooth drag
    t.y = p.dy;
  }

  void _onPanEnd() {
    final t = _drag;
    _drag = null;
    if (t == null) return;
    final target = _slotAt(Offset(t.x, t.y));
    setState(() {
      if (target != null && _tileInSlot(target) == null) {
        _placeTile(t, target);
      } else if (_dragOriginSlot != null &&
          _tileInSlot(_dragOriginSlot!) == null) {
        _placeTile(t, _dragOriginSlot!); // back where it came from
      } else {
        t.x = t.homeX; // home to the tray
        t.y = t.homeY;
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
        _positionTiles(w, h);
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
            painter: _SkinPainter(repaint: _ticker, state: this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _SkinPainter extends CustomPainter {
  final _SkinLayersGameState s;
  _SkinPainter({required Listenable repaint, required _SkinLayersGameState state})
      : s = state,
        super(repaint: repaint);

  static const Color _accent = _SkinLayersGameState._accent;
  static const Color _good = _SkinLayersGameState._good;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _accent, s._clock, motes: 20);

    if (s._wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color =
                const Color(0xFFFF5252).withValues(alpha: s._wrongFlash * 0.16));
    }

    _drawHeader(canvas, size);
    _drawDepthGuide(canvas, size);
    _drawSlots(canvas, size);
    _drawBoundaries(canvas, size);
    _drawTiles(canvas, size);
    _drawRoleCard(canvas, size);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  void _drawHeader(Canvas canvas, Size size) {
    final goal = s._phase == _Phase.alive
        ? 'THE SKIN COMES ALIVE'
        : 'STACK THE SKIN — SURFACE ON TOP, DEEP AT THE BOTTOM';
    GameFx.text(canvas, goal, Offset(size.width / 2, 16), 11,
        Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700);
    if (s._level > 0) {
      GameFx.text(canvas, 'SECTION ${s._level + 1}',
          Offset(size.width - 40, 18), 10, _accent.withValues(alpha: 0.8),
          weight: FontWeight.w700);
    }
  }

  // A soft vertical SURFACE → DEEP guide ribbon beside the stack.
  void _drawDepthGuide(Canvas canvas, Size size) {
    final rects = s._slotRects;
    if (rects.isEmpty) return;
    final x = rects.first.left - 14;
    final top = rects.first.top;
    final bottom = rects.last.bottom;
    canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    GameFx.text(canvas, 'SURFACE', Offset(x - 2, top - 10), 8,
        Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
    GameFx.text(canvas, 'DEEP', Offset(x - 2, bottom + 10), 8,
        Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
  }

  void _drawSlots(Canvas canvas, Size size) {
    final glow = s._aliveGlow;
    for (var i = 0; i < s._slotRects.length; i++) {
      final r = s._slotRects[i];
      final occupied = s._tileInSlot(i) != null;
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
      // Depth-order badge on the left edge.
      GameFx.text(canvas, '${i + 1}', Offset(r.left + 12, r.center.dy), 10,
          Colors.white.withValues(alpha: 0.30), weight: FontWeight.w700);
    }
    if (glow > 0 && s._slotRects.isNotEmpty) {
      final bounds = Rect.fromLTRB(
          s._slotRects.first.left,
          s._slotRects.first.top,
          s._slotRects.first.right,
          s._slotRects.last.bottom);
      canvas.drawRRect(
          RRect.fromRectAndRadius(bounds.inflate(6), const Radius.circular(16)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _good.withValues(alpha: 0.35 * glow));
    }
  }

  // Boundaries between bands: teal where the order is healthy, red where two
  // filled neighbours are out of depth order (the break).
  void _drawBoundaries(Canvas canvas, Size size) {
    final rects = s._slotRects;
    for (var i = 0; i < rects.length - 1; i++) {
      final a = rects[i];
      final b = rects[i + 1];
      final upper = s._tileInSlot(i);
      final lower = s._tileInSlot(i + 1);
      if (upper == null || lower == null) continue;
      final upperOk = upper.layer == s._correct[i];
      final lowerOk = lower.layer == s._correct[i + 1];
      final y = (a.bottom + b.top) / 2;
      final ordered = _layer(upper.layer).depth <= _layer(lower.layer).depth;
      Color c;
      if (upperOk && lowerOk) {
        c = _good.withValues(alpha: 0.9);
      } else if (!ordered) {
        c = const Color(0xFFFF5252).withValues(alpha: 0.95); // BREAK here
      } else {
        c = Colors.white.withValues(alpha: 0.16);
      }
      canvas.drawLine(
          Offset(a.left + 6, y),
          Offset(a.right - 6, y),
          Paint()
            ..color = c
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawTiles(Canvas canvas, Size size) {
    for (final t in s._tiles) {
      if (identical(t, s._drag)) continue;
      _drawTile(canvas, t, dragging: false);
    }
    if (s._drag != null) _drawTile(canvas, s._drag!, dragging: true);
  }

  void _drawTile(Canvas canvas, _Tile t, {required bool dragging}) {
    final l = _layer(t.layer);
    final placed = t.slot != null;
    final w = placed ? s._slotW : s._trayW;
    final h = placed ? s._slotH : s._trayH;
    final rect = Rect.fromCenter(center: Offset(t.x, t.y), width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final correct = placed && s._correct[t.slot!] == t.layer;
    final pulse = (placed && s._phase == _Phase.alive)
        ? 0.5 + 0.5 * math.sin(s._clock * 6 + t.slot! * 0.6)
        : 0.0;

    if (dragging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(14)),
        Paint()..color = l.color.withValues(alpha: 0.22),
      );
    }

    canvas.drawRRect(
        rr,
        Paint()
          ..color = l.color.withValues(
              alpha: (dragging ? 0.42 : 0.30) + pulse * 0.18));
    Color border;
    if (placed) {
      border = correct ? _good : const Color(0xFFFF8A65);
    } else {
      border = l.color.withValues(alpha: 0.7);
    }
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = correct ? 2.2 : 1.5
          ..color = border);

    // Emoji + label. Wide bands show the full name; small tray pills abbreviate.
    final showFull = w >= 130;
    final iconSize = (h * 0.42).clamp(13.0, 20.0);
    final labelSize = (h * 0.28).clamp(8.0, 12.0);
    if (placed && showFull) {
      // Band: icon left, name beside it.
      GameFx.text(canvas, l.emoji, Offset(t.x - w * 0.30, t.y), iconSize,
          Colors.white);
      GameFx.text(canvas, l.name, Offset(t.x + w * 0.04, t.y), labelSize,
          Colors.white.withValues(alpha: 0.94), weight: FontWeight.w700);
    } else {
      // Tray pill: stacked icon over abbreviation.
      GameFx.text(canvas, l.emoji, Offset(t.x, t.y - h * 0.16), iconSize,
          Colors.white);
      GameFx.text(canvas, l.abbrev, Offset(t.x, t.y + h * 0.30), labelSize,
          Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);
    }
  }

  void _drawRoleCard(Canvas canvas, Size size) {
    if (s._roleAge >= 3.0 || s._roleText.isEmpty) return;
    final a = (1 - (s._roleAge - 2.4).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
    final y = size.height * 0.70;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: (size.width - 40).clamp(140.0, 420.0),
        height: 42);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
        rr, Paint()..color = Colors.black.withValues(alpha: 0.34 * a));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = s._roleColor.withValues(alpha: 0.5 * a));
    GameFx.text(canvas, s._roleText, rect.center, 11,
        Colors.white.withValues(alpha: 0.92 * a), weight: FontWeight.w600);
  }

  @override
  bool shouldRepaint(covariant _SkinPainter old) => true;
}
