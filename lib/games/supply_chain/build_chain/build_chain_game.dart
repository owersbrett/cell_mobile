import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Build the Chain — a supply-chain STRUCTURE & VOCABULARY primer.
///
/// You assemble a potato supply chain: a row of empty ordered slots plus a tray
/// of shuffled STAGE tiles (Farm → Wash/Sort → Process → … → Store). Drag each
/// tile into the correct sequential position (upstream → downstream). Place a
/// tile in its right slot and goods can FLOW through that link; put it in the
/// wrong place and the arrow into it BREAKS — you see exactly where the chain
/// snaps. Fill every slot in order and the chain locks in: potatoes run the line
/// (a brief FLOW phase) and a stage occasionally STALLS — tap to clear it and
/// keep goods moving. Then a new, longer/variant chain appears.
///
/// The lesson is the mechanic: a supply chain is a NAMED, ORDERED sequence of
/// stages from raw material to customer, and ORDER matters — you can't warehouse
/// before you process, can't sell before you stock. Every tile teaches its role
/// the moment you touch it.
///
/// The host (MiniGameHost) owns the 60-second clock, the 3-2-1 countdown, the
/// score HUD and the results screen; this widget renders ONLY the play area and
/// reports points via `session.addScore` / `session.noteStreak`. All rendering
/// is a single Ticker-driven CustomPainter — drag just mutates tile positions.
class BuildChainGame extends StatefulWidget {
  final MiniGameSession session;
  const BuildChainGame({super.key, required this.session});

  @override
  State<BuildChainGame> createState() => _BuildChainGameState();
}

// ── Stage catalog ────────────────────────────────────────────────────────────

enum _StageId {
  farm,
  wash,
  quality,
  process,
  packaging,
  cold,
  warehouse,
  distribute,
  store,
  exportPort,
}

class _Stage {
  final int rank; // canonical upstream→downstream position
  final String name;
  final String abbrev;
  final String role; // the one-line vocabulary lesson
  final String emoji;
  final Color color;
  const _Stage(this.rank, this.name, this.abbrev, this.role, this.emoji,
      this.color);
}

const Map<_StageId, _Stage> _kStages = {
  _StageId.farm: _Stage(0, 'Farm', 'FARM',
      'Grow and harvest the raw potatoes.', '🌱', Color(0xFF66BB6A)),
  _StageId.wash: _Stage(1, 'Wash & Sort', 'WASH',
      'Clean off the dirt and grade spuds by size and quality.', '🚿',
      Color(0xFF4DD0E1)),
  _StageId.quality: _Stage(2, 'Quality Check', 'QC',
      'Inspect the batch and reject bruised or green potatoes.', '🔍',
      Color(0xFF7986CB)),
  _StageId.process: _Stage(3, 'Process', 'PROC',
      'Cut and cook the potatoes into fries and chips.', '🏭',
      Color(0xFFFF7043)),
  _StageId.packaging: _Stage(4, 'Packaging', 'PACK',
      'Seal the product into bags and boxes.', '📦', Color(0xFFFFCA28)),
  _StageId.cold: _Stage(5, 'Cold Storage', 'COLD',
      'Keep the product frozen and fresh until it ships.', '❄️',
      Color(0xFF4FC3F7)),
  _StageId.warehouse: _Stage(6, 'Warehouse', 'WHSE',
      'Hold finished stock until stores place an order.', '🏬',
      Color(0xFF8D6E63)),
  _StageId.distribute: _Stage(7, 'Distribute', 'TRUCK',
      'Load the trucks and haul product out to stores.', '🚚',
      Color(0xFF9575CD)),
  _StageId.store: _Stage(8, 'Store', 'STORE',
      'Stock the shelves and sell to the customer.', '🏪', Color(0xFFEF5350)),
  _StageId.exportPort: _Stage(9, 'Export Port', 'PORT',
      'Ship product overseas to reach distant markets.', '🚢',
      Color(0xFF26A69A)),
};

_Stage _stage(_StageId id) => _kStages[id]!;

// ── Mutable play objects ─────────────────────────────────────────────────────

class _Tile {
  final _StageId stage;
  double x = 0, y = 0; // current center (px)
  double homeX = 0, homeY = 0; // resting tray position
  int? slot; // slot index if placed, else null (in tray)
  _Tile(this.stage);
}

class _Potato {
  double pos; // continuous position along the belt, 0..(nSlots+1)
  int lastStop; // highest integer stop already entered (for stall rolls)
  _Potato(this.pos) : lastStop = 0;
}

enum _Phase { assemble, flow }

// ── State ────────────────────────────────────────────────────────────────────

class _BuildChainGameState extends State<BuildChainGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final int _gameSeed;
  late math.Random _rng;

  double _lastT = 0;
  double _clock = 0;

  int _level = 0; // chains completed = current difficulty level
  _Phase _phase = _Phase.assemble;
  double _chainStartClock = 0;

  // Current chain.
  List<_StageId> _correct = const []; // expected order, slot i ⇒ _correct[i]
  List<_Tile> _tiles = [];
  int _nSlots = 0;
  final Set<int> _scoredSlots = {}; // slot indices already awarded
  int _streak = 0; // consecutive correct placements / clean chains

  // Layout (recomputed each build).
  List<Rect> _slotRects = const [];
  double _slotW = 56, _slotH = 64, _trayW = 60, _trayH = 56;

  Size _sz = Size.zero;
  _Tile? _drag;
  int? _dragOriginSlot;

  // Role card.
  String _roleText = '';
  Color _roleColor = Colors.white;
  double _roleAge = 99;

  // Flow phase.
  final List<_Potato> _potatoes = [];
  int _delivered = 0;
  int _deliverGoal = 3;
  bool _flowFlawless = true;
  int? _stalledSlot;
  double _stallAge = 0;
  double _stallWindow = 2.0;
  double _spawnGap = 0; // delay before next potato spawns

  // Juice.
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _chainGlow = 0;

  static const Color _accent = Color(0xFFFF7043); // supply-chain orange

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
    _newChain(first: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Chain composition ────────────────────────────────────────────────────────

  /// Build the correct order for a chain at [level]. Level 0 is the gentle
  /// fixed primer; later levels grow longer and mix in the advanced stages and
  /// an occasional export branch (ends at the port instead of the store).
  List<_StageId> _composeChain(int level) {
    if (level == 0) {
      return const [
        _StageId.farm,
        _StageId.wash,
        _StageId.process,
        _StageId.store,
      ];
    }
    final useExport = level >= 3 && _rng.nextDouble() < 0.33;
    final endId = useExport ? _StageId.exportPort : _StageId.store;
    final endRank = _stage(endId).rank;
    final required = <_StageId>{_StageId.farm, _StageId.process, endId};
    final targetLen = (4 + level).clamp(4, 7);

    final pool = _StageId.values.where((s) {
      final r = _stage(s).rank;
      return !required.contains(s) &&
          s != _StageId.store &&
          s != _StageId.exportPort &&
          r > _stage(_StageId.farm).rank &&
          r < endRank;
    }).toList()
      ..shuffle(_rng);

    final need = (targetLen - required.length).clamp(0, pool.length);
    final chain = <_StageId>{...required, ...pool.take(need)}.toList()
      ..sort((a, b) => _stage(a).rank.compareTo(_stage(b).rank));
    return chain;
  }

  void _newChain({bool first = false}) {
    _correct = _composeChain(_level);
    _nSlots = _correct.length;
    _scoredSlots.clear();
    _phase = _Phase.assemble;
    _chainStartClock = _clock;
    _drag = null;
    _dragOriginSlot = null;
    _potatoes.clear();
    _delivered = 0;
    _deliverGoal = 3;
    _flowFlawless = true;
    _stalledSlot = null;
    _stallWindow = (2.2 - _level * 0.12).clamp(1.1, 2.2);

    // One tile per stage; tray order shuffled so placement is never trivial.
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
    const gap = 7.0;
    final avail = w - 20;
    _slotW = ((avail - gap * (n - 1)) / n).clamp(34.0, 84.0);
    _slotH = (_slotW * 1.18).clamp(44.0, 84.0);
    final totalW = _slotW * n + gap * (n - 1);
    final startX = (w - totalW) / 2;
    final top = h * 0.20;
    _slotRects = [
      for (var i = 0; i < n; i++)
        Rect.fromLTWH(startX + i * (_slotW + gap), top, _slotW, _slotH),
    ];
  }

  /// Assign resting tray positions and snap every non-dragged tile to its home
  /// (tray) or its slot. Deterministic, so resizes and drops stay consistent.
  void _positionTiles(double w, double h) {
    _computeSlots(w, h);
    final n = _tiles.length;
    if (n == 0) return;

    _trayW = (_slotW + 4).clamp(48.0, 96.0);
    _trayH = 52;
    const gap = 10.0;
    final perRow = ((w - 16) / (_trayW + gap)).floor().clamp(1, n);
    final rows = (n / perRow).ceil();
    final baseY = h * 0.86;

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
    if (_chainGlow > 0) _chainGlow = (_chainGlow - dt * 1.4).clamp(0.0, 1.0);

    if (!widget.session.isRunning) return;
    _clock += dt;
    if (_phase == _Phase.flow) _tickFlow(dt);
  }

  void _tickFlow(double dt) {
    // Spawn one potato at a time onto the belt.
    if (_potatoes.isEmpty && _delivered < _deliverGoal) {
      if (_spawnGap > 0) {
        _spawnGap -= dt;
      } else {
        _potatoes.add(_Potato(0));
      }
    }

    final speed = 3.0; // belt stops per second
    for (final p in List<_Potato>.of(_potatoes)) {
      // A stalled stage halts the potato sitting in it.
      if (_stalledSlot != null) {
        final atSlot = p.pos.round() - 1;
        if (atSlot == _stalledSlot) {
          _stallAge += dt;
          if (_stallAge >= _stallWindow) {
            // Missed: the stage backs up, goods spoil. Flow continues.
            _flowFlawless = false;
            _wrongFlash = 0.4;
            final r = _slotRects[_stalledSlot!];
            _pops.add(FxPop(r.center.translate(0, -28), 'STALLED', _accent));
            _stalledSlot = null;
            _stallAge = 0;
          }
          continue; // frozen until cleared / timed out
        }
      }

      p.pos += speed * dt;

      // Entering a new stage may trigger a stall (only one at a time).
      final entered = p.pos.floor();
      if (entered > p.lastStop && entered >= 1 && entered <= _nSlots) {
        p.lastStop = entered;
        if (_stalledSlot == null) {
          final chance = (0.16 + _level * 0.05).clamp(0.16, 0.5);
          if (_rng.nextDouble() < chance) {
            _stalledSlot = entered - 1;
            _stallAge = 0;
          }
        }
      }

      if (p.pos >= _nSlots + 1) {
        _potatoes.remove(p);
        _delivered++;
        widget.session.addScore(5); // flow upkeep
        _spawnGap = 0.35;
        if (_delivered >= _deliverGoal) {
          _endFlow();
        }
      }
    }
  }

  void _endFlow() {
    if (_flowFlawless) {
      _streak++;
      widget.session.noteStreak(_streak);
      widget.session.addScore(25);
      if (_sz != Size.zero) {
        _pops.add(FxPop(Offset(_sz.width / 2, _sz.height * 0.32),
            'CLEAN LINE +25', const Color(0xFF80CBC4)));
      }
    } else {
      _streak = 0;
    }
    _level++;
    _newChain();
  }

  // ── Placement / scoring ──────────────────────────────────────────────────────

  void _showRole(_StageId s) {
    final st = _stage(s);
    _roleText = '${st.name} — ${st.role}';
    _roleColor = st.color;
    _roleAge = 0;
  }

  void _placeTile(_Tile t, int slotIdx) {
    t.slot = slotIdx;
    t.x = _slotRects[slotIdx].center.dx;
    t.y = _slotRects[slotIdx].center.dy;
    _showRole(t.stage);

    final correct = _correct[slotIdx] == t.stage;
    if (correct) {
      if (!_scoredSlots.contains(slotIdx)) {
        _scoredSlots.add(slotIdx);
        _streak++;
        widget.session.noteStreak(_streak);
        final pts = 15 + _streak * 2;
        widget.session.addScore(pts);
        final c = _slotRects[slotIdx].center;
        _fx.addAll(FxBurst.spawn(c, _stage(t.stage).color, count: 12));
        _pops.add(FxPop(c.translate(0, -26), '+$pts', _stage(t.stage).color));
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
    _showRole(t.stage);
  }

  void _checkComplete() {
    if (_phase != _Phase.assemble) return;
    final filled = _tiles.every((t) => t.slot != null);
    if (!filled) return;
    final allCorrect = List<bool>.generate(
        _nSlots, (i) => _tileInSlot(i)?.stage == _correct[i]).every((b) => b);
    if (!allCorrect) {
      // Filled but out of order — the broken arrow shows where it snaps.
      _wrongFlash = 0.5;
      return;
    }
    _completeChain();
  }

  void _completeChain() {
    final elapsed = _clock - _chainStartClock;
    final par = _nSlots * 3.0;
    final speedBonus = ((par - elapsed) * 4).clamp(0.0, 60.0).round();
    final bonus = 50 + _level * 12 + speedBonus;
    widget.session.addScore(bonus);
    _chainGlow = 1.0;
    if (_sz != Size.zero) {
      _pops.add(FxPop(Offset(_sz.width / 2, _slotRects.first.top - 18),
          'CHAIN LOCKED +$bonus', const Color(0xFF80CBC4)));
      for (final r in _slotRects) {
        _fx.addAll(FxBurst.spawn(r.center, _accent, count: 6, speed: 90));
      }
    }
    // Begin the flow phase: potatoes run the line.
    _phase = _Phase.flow;
    _delivered = 0;
    _deliverGoal = 3;
    _flowFlawless = true;
    _stalledSlot = null;
    _spawnGap = 0.2;
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
      final half = (t.slot != null ? _slotW : _trayW) * 0.7;
      final d = (Offset(t.x, t.y) - p).distance;
      if (d < half && d < bestD) {
        bestD = d;
        best = t;
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
    if (_phase == _Phase.flow) {
      // Tap a stalled stage to clear it and keep goods flowing.
      if (_stalledSlot != null && _slotRects[_stalledSlot!].inflate(6).contains(p)) {
        widget.session.addScore(12);
        final c = _slotRects[_stalledSlot!].center;
        _fx.addAll(FxBurst.spawn(c, const Color(0xFF80CBC4), count: 10));
        _pops.add(FxPop(c.translate(0, -24), 'CLEARED +12',
            const Color(0xFF80CBC4)));
        _stalledSlot = null;
        _stallAge = 0;
      }
      return;
    }
    final t = _tileAt(p);
    if (t == null) return;
    if (t.slot != null) {
      setState(() => _removeTile(t)); // pull a placed tile back to rearrange
    } else {
      setState(() => _showRole(t.stage)); // teach the role on tap
    }
  }

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning || _phase != _Phase.assemble) return;
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
            painter: _ChainPainter(repaint: _ticker, state: this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _ChainPainter extends CustomPainter {
  final _BuildChainGameState s;
  _ChainPainter({required Listenable repaint, required _BuildChainGameState state})
      : s = state,
        super(repaint: repaint);

  static const Color _accent = _BuildChainGameState._accent;
  static const Color _good = Color(0xFF80CBC4);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _accent, s._clock, motes: 22);

    if (s._wrongFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFFF5252).withValues(alpha: s._wrongFlash * 0.16));
    }

    _drawHeader(canvas, size);
    _drawBelt(canvas, size);
    _drawSlots(canvas, size);
    if (s._phase == _Phase.flow) _drawFlow(canvas, size);
    _drawTiles(canvas, size);
    _drawRoleCard(canvas, size);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  // Goal line + level pips at the very top.
  void _drawHeader(Canvas canvas, Size size) {
    final goal = s._phase == _Phase.assemble
        ? 'BUILD THE CHAIN — DRAG STAGES INTO ORDER'
        : 'KEEP IT FLOWING — TAP A STALLED STAGE';
    GameFx.text(canvas, goal, Offset(size.width / 2, 16), 11,
        Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700);
    GameFx.text(canvas, 'UPSTREAM  ➜  DOWNSTREAM', Offset(size.width / 2, 34),
        9, Colors.white.withValues(alpha: 0.32));
    if (s._level > 0) {
      GameFx.text(canvas, 'CHAIN ${s._level + 1}',
          Offset(size.width - 36, 18), 10, _accent.withValues(alpha: 0.8),
          weight: FontWeight.w700);
    }
  }

  // The conveyor: a soft line linking the slot centers, with arrows whose colour
  // tells the player where the order is right (teal) vs broken (red).
  void _drawBelt(Canvas canvas, Size size) {
    final rects = s._slotRects;
    if (rects.isEmpty) return;
    final cy = rects.first.center.dy;

    // Entry / exit stubs.
    final entry = Offset(rects.first.left - 14, cy);
    final exit = Offset(rects.last.right + 14, cy);
    final belt = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(entry, Offset(rects.first.center.dx, cy), belt);
    canvas.drawLine(Offset(rects.last.center.dx, cy), exit, belt);

    for (var i = 0; i < rects.length - 1; i++) {
      final a = rects[i].center;
      final b = rects[i + 1].center;
      final leftOk = s._tileInSlot(i)?.stage == s._correct[i];
      final rightOk = s._tileInSlot(i + 1)?.stage == s._correct[i + 1];
      final bothFilled =
          s._tileInSlot(i) != null && s._tileInSlot(i + 1) != null;
      Color c;
      if (leftOk && rightOk) {
        c = _good.withValues(alpha: 0.9); // goods flow
      } else if (bothFilled) {
        c = const Color(0xFFFF5252).withValues(alpha: 0.9); // BREAK here
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
    // Arrowhead.
    final perp = Offset(-n.dy, n.dx);
    final tip = end;
    canvas.drawLine(tip, tip - n * 7 + perp * 4, paint);
    canvas.drawLine(tip, tip - n * 7 - perp * 4, paint);
  }

  void _drawSlots(Canvas canvas, Size size) {
    for (var i = 0; i < s._slotRects.length; i++) {
      final r = s._slotRects[i];
      final occupied = s._tileInSlot(i) != null;
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
      if (!occupied) {
        // Empty target: a dashed-look outline tinted by the expected stage so
        // the structure (number of stages) reads before anything is placed.
        canvas.drawRRect(
            rr,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.04));
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = Colors.white.withValues(alpha: 0.18));
      }
      // Slot number badge.
      GameFx.text(canvas, '${i + 1}', Offset(r.left + 9, r.top + 8), 9,
          Colors.white.withValues(alpha: 0.30), weight: FontWeight.w700);
    }
  }

  void _drawFlow(Canvas canvas, Size size) {
    final rects = s._slotRects;
    if (rects.isEmpty) return;
    final cy = rects.first.center.dy;
    final entryX = rects.first.left - 14;
    final exitX = rects.last.right + 14;

    double beltX(double pos) {
      // pos 0 = entry, pos i (1..n) = slot i-1 center, pos n+1 = exit.
      if (pos <= 0) return entryX;
      if (pos >= s._nSlots + 1) return exitX;
      final seg = pos.floor();
      final frac = pos - seg;
      double sx(int k) {
        if (k <= 0) return entryX;
        if (k >= s._nSlots + 1) return exitX;
        return rects[k - 1].center.dx;
      }
      return sx(seg) + (sx(seg + 1) - sx(seg)) * frac;
    }

    // Stalled stage flashes red and asks to be tapped.
    if (s._stalledSlot != null && s._stalledSlot! < rects.length) {
      final r = rects[s._stalledSlot!];
      final pulse = 0.5 + 0.5 * math.sin(s._clock * 9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFF5252).withValues(alpha: 0.4 + pulse * 0.5),
      );
      GameFx.text(canvas, 'TAP!', Offset(r.center.dx, r.bottom + 12), 10,
          const Color(0xFFFF5252).withValues(alpha: 0.6 + pulse * 0.4),
          weight: FontWeight.w800);
    }

    for (final p in s._potatoes) {
      final c = Offset(beltX(p.pos), cy);
      GameFx.orb(canvas, c, 9, const Color(0xFFD7B377), glow: 0.8);
      GameFx.text(canvas, '🥔', c, 13, Colors.white);
    }

    // Delivered tally.
    GameFx.text(canvas, 'DELIVERED  ${s._delivered}/${s._deliverGoal}',
        Offset(size.width / 2, rects.first.top - 16), 10,
        _good.withValues(alpha: 0.8), weight: FontWeight.w700);
  }

  void _drawTiles(Canvas canvas, Size size) {
    // Draw resting/placed tiles first, the dragged one last (on top).
    for (final t in s._tiles) {
      if (identical(t, s._drag)) continue;
      _drawTile(canvas, t, dragging: false);
    }
    if (s._drag != null) _drawTile(canvas, s._drag!, dragging: true);
  }

  void _drawTile(Canvas canvas, _Tile t, {required bool dragging}) {
    final st = _stage(t.stage);
    final placed = t.slot != null;
    final w = placed ? s._slotW : s._trayW;
    final h = placed ? s._slotH : s._trayH;
    final rect = Rect.fromCenter(center: Offset(t.x, t.y), width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final correct = placed && s._correct[t.slot!] == t.stage;
    final stalled = s._phase == _Phase.flow && s._stalledSlot == t.slot;

    if (dragging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(14)),
        Paint()..color = st.color.withValues(alpha: 0.22),
      );
    }

    canvas.drawRRect(rr,
        Paint()..color = st.color.withValues(alpha: dragging ? 0.42 : 0.30));
    Color border;
    if (stalled) {
      border = const Color(0xFFFF5252);
    } else if (placed) {
      border = correct ? _good : const Color(0xFFFF8A65);
    } else {
      border = st.color.withValues(alpha: 0.7);
    }
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = correct || stalled ? 2.2 : 1.5
          ..color = border);

    // Emoji icon + abbreviation, scaled to fit small slots.
    final iconSize = (h * 0.34).clamp(13.0, 22.0);
    final labelSize = (w * 0.18).clamp(7.5, 11.0);
    GameFx.text(canvas, st.emoji, Offset(t.x, t.y - h * 0.16), iconSize,
        Colors.white);
    GameFx.text(canvas, w < 56 ? st.abbrev : st.name,
        Offset(t.x, t.y + h * 0.28), labelSize,
        Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);
  }

  void _drawRoleCard(Canvas canvas, Size size) {
    if (s._roleAge >= 3.0 || s._roleText.isEmpty) return;
    final a = (1 - (s._roleAge - 2.4).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
    final y = (s._slotRects.isEmpty
            ? size.height * 0.5
            : s._slotRects.first.bottom + 34) +
        18;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: (size.width - 40).clamp(140.0, 420.0),
        height: 40);
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
  bool shouldRepaint(covariant _ChainPainter old) => true;
}
