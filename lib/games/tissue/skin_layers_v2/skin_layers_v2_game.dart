import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Skin Layers v2 — a tissue-scale, REAL-TIME skin-renewal game.
///
/// The original Skin Layers was a static knowledge-gated memory sort: you filled
/// a whole stack at your leisure, and the round hard-froze for 1.6s after every
/// section. v2 keeps the lesson — skin is a NAMED, depth-ordered stack (Corneum
/// → Granulosum → Spinosum → Basale, papillary/reticular dermis, hypodermis) —
/// and turns it into a flowing, accelerating catch-and-place mechanic.
///
/// A layer tile "docks" at the bottom on a draining TEMPO bar. Drag it up into
/// the band at its correct depth before the tempo runs out. A glowing target
/// band TEACHES the order to a novice and fades as your streak climbs, so the
/// ceiling becomes speed + recall, never pre-existing histology knowledge. Each
/// correct placement makes the next tile dock FASTER — the whole round
/// accelerates to a frantic climax. Fill every band and the skin "comes alive"
/// (sweat beads, a pulse) as a non-blocking flash, then a deeper column seeds
/// instantly — no dead air. Tap the docked tile to read its one-line role.
///
/// The host (MiniGameHost) owns the 60-second clock, the 3-2-1 countdown, the
/// score HUD and the results screen; this widget renders ONLY the play area and
/// reports points via `session.addScore` / `session.noteStreak`. All rendering
/// is a single Ticker-driven CustomPainter — drag just mutates positions, and
/// discrete events mutate fields that the always-running ticker repaints.
class SkinLayersV2Game extends StatefulWidget {
  final MiniGameSession session;
  const SkinLayersV2Game({super.key, required this.session});

  @override
  State<SkinLayersV2Game> createState() => _SkinLayersV2GameState();
}

// ── Layer catalog (self-contained copy; depth drives correct order) ───────────

enum _LayerId {
  epidermis,
  dermis,
  hypodermisMajor,
  corneum,
  granulosum,
  spinosum,
  basale,
  papillary,
  sebaceous,
  hairFollicle,
  nerveEnding,
  reticular,
  sweatGland,
  bloodVessel,
  hypodermis,
}

class _Layer {
  /// Canonical depth: 0 = skin surface, larger = deeper.
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
  _LayerId.epidermis: _Layer(0, 'Epidermis', 'EPI',
      'Outer barrier — waterproofs and shields you from the world.', '🛡',
      Color(0xFFFFCCBC)),
  _LayerId.dermis: _Layer(4, 'Dermis', 'DERM',
      'Tough middle layer — holds nerves, glands, vessels and hair roots.',
      '🧶', Color(0xFFFF8A65)),
  _LayerId.hypodermisMajor: _Layer(11, 'Hypodermis', 'FAT',
      'Deep fat layer — insulates, cushions and stores energy.', '🧈',
      Color(0xFFFFD54F)),
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
  _LayerId.hypodermis: _Layer(11, 'Hypodermis', 'FAT',
      'Hypodermis — deep fat layer; insulates, cushions and stores energy.',
      '🧈', Color(0xFFFFD54F)),
};

_Layer _layer(_LayerId id) => _kLayers[id]!;

// ── State ─────────────────────────────────────────────────────────────────────

class _SkinLayersV2GameState extends State<SkinLayersV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final math.Random _rng;

  double _lastT = 0;
  double _clock = 0;

  // Column (the current skin cross-section being rebuilt).
  int _level = 0;
  List<_LayerId> _correct = const []; // bands, sorted surface(0) → deep
  List<_LayerId?> _filled = const []; // what's locked into each band
  final List<_LayerId> _queue = []; // unplaced layers waiting to dock
  int _columnSize = 0;

  // The docked (incoming) tile + its draining tempo.
  _LayerId? _dock;
  double _dockTime = 0; // seconds remaining for the current tile
  double _dockMaxCur = 1; // the max this tile docked with (for the bar ratio)

  int _placedTotal = 0; // global correct placements — drives the tempo ramp
  int _streak = 0;

  // Drag.
  bool _dragging = false;
  Offset _dragPos = Offset.zero;

  // Role card.
  String _roleText = '';
  Color _roleColor = Colors.white;
  double _roleAge = 99;

  // Juice.
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _aliveGlow = 0;
  int _breakBand = -1;
  double _breakAge = 99;

  // Layout (recomputed on resize and on each new column).
  Size _sz = Size.zero;
  List<Rect> _bandRects = const [];
  Rect _dockRect = Rect.zero;
  Rect _tempoRect = Rect.zero;
  double _bandW = 220, _bandH = 48;

  static const Color _accent = Color(0xFFFF8A65); // warm dermis orange
  static const Color _good = Color(0xFF80CBC4); // healthy teal
  static const Color _break = Color(0xFFFF5252); // order-break red

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _rng = math.Random(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _buildColumn();
    // ATTRACT autopilot: this game can rebuild the skin itself. The host calls
    // [_autoStep] ~every 250ms only while driving hands-free. Dormant in play.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One hands-free placement per host tick. Plays v2 *correctly*, never wrong:
  /// it reads the currently docked layer, finds ITS correct depth band
  /// (`_correct.indexOf(dock)`), aims the drag at that band's center and fires
  /// the game's own [_resolveDrop] handler — so every placement is a healthy
  /// depth match and the streak keeps climbing into the hot combo.
  ///
  /// On the tempo: placing the moment a tile docks is always optimal — scoring
  /// is a binary correct/hot-combo, there is no "wait for the beat" bonus, and
  /// the only role of the draining tempo bar is to punish delay by resetting the
  /// streak. So the favorable beat is simply *now*: place immediately, beat the
  /// drain, never miss. When the last band lands, [_resolveDrop] auto-completes
  /// the column and seeds the next, deeper one instantly.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    final dock = _dock;
    if (dock == null) return; // between columns; next tick has a fresh tile
    if (_dragging) return; // never happens hands-free, but stay safe
    if (_bandRects.isEmpty) return; // layout not measured yet
    final correctBand = _correct.indexOf(dock);
    if (correctBand < 0 || correctBand >= _bandRects.length) return;
    if (_filled[correctBand] != null) return; // depths are unique; guard anyway
    // Aim the drop at the correct band and let the real handler score it.
    _dragPos = _bandRects[correctBand].center;
    _resolveDrop(); // exactly one placement per tick; advances the column
  }

  // ── Column composition ─────────────────────────────────────────────────────

  /// Build the correct depth order for a column at [level]. Level 0 is the
  /// gentle three-layer primer; later levels expand the epidermis into strata
  /// and weave in dermal structures, growing 4 → 7 bands. Depths are unique
  /// within a column, so each tile has exactly one correct band.
  List<_LayerId> _composeColumn(int level) {
    if (level == 0) {
      return const [_LayerId.epidermis, _LayerId.dermis, _LayerId.hypodermis];
    }
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
    final col = <_LayerId>{...required, ...pool.take(need)}.toList()
      ..sort((a, b) => _layer(a).depth.compareTo(_layer(b).depth));
    return col;
  }

  void _buildColumn() {
    _correct = _composeColumn(_level);
    _columnSize = _correct.length;
    _filled = List<_LayerId?>.filled(_columnSize, null);
    _queue
      ..clear()
      ..addAll([..._correct]..shuffle(_rng));
    _dock = null;
    _dragging = false;
    if (_sz != Size.zero) _computeLayout(_sz);
    _dockNext();
  }

  /// Pull the next layer from the queue onto the dock with a fresh tempo.
  void _dockNext() {
    if (_queue.isEmpty) {
      _dock = null;
      return;
    }
    _dock = _queue.removeAt(0);
    // Tempo accelerates with total layers placed — the round's climb.
    _dockMaxCur = (2.6 - _placedTotal * 0.045).clamp(0.85, 2.6);
    _dockTime = _dockMaxCur;
    _showRole(_dock!); // passive teaching the moment a tile arrives
  }

  // ── Layout ───────────────────────────────────────────────────────────────────

  void _computeLayout(Size size) {
    final w = size.width, h = size.height;
    final n = _columnSize;
    if (n <= 0) {
      _bandRects = const [];
      return;
    }
    const gap = 6.0;
    final top = h * 0.12;
    final bottom = h * 0.64;
    final avail = bottom - top;
    _bandH = ((avail - gap * (n - 1)) / n).clamp(26.0, 64.0);
    final totalH = _bandH * n + gap * (n - 1);
    final startY = top + (avail - totalH) / 2;
    _bandW = (w * 0.66).clamp(140.0, 360.0);
    final left = (w - _bandW) / 2;
    _bandRects = [
      for (var i = 0; i < n; i++)
        Rect.fromLTWH(left, startY + i * (_bandH + gap), _bandW, _bandH),
    ];
    // Tempo bar + dock near the bottom.
    final barW = _bandW;
    final barLeft = (w - barW) / 2;
    _tempoRect = Rect.fromLTWH(barLeft, h * 0.78, barW, 8);
    final dockW = (barW * 0.82).clamp(120.0, 300.0);
    _dockRect = Rect.fromCenter(
        center: Offset(w / 2, h * 0.87), width: dockW, height: 50);
  }

  // ── Tick ─────────────────────────────────────────────────────────────────────

  void _onTick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;

    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_roleAge < 99) _roleAge += dt;
    if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 2).clamp(0.0, 1.0);
    if (_breakAge < 99) _breakAge += dt;
    if (_aliveGlow > 0) {
      _aliveGlow = (_aliveGlow - dt * 1.6).clamp(0.0, 1.0);
      // Living skin: sweat beads + sparks rise from the column.
      if (_bandRects.isNotEmpty && _rng.nextDouble() < 0.6) {
        final r = _bandRects[_rng.nextInt(_bandRects.length)];
        _fx.add(FxParticle(
          Offset(r.left + _rng.nextDouble() * r.width, r.center.dy),
          Offset((_rng.nextDouble() - 0.5) * 30, -50 - _rng.nextDouble() * 50),
          _good,
          2.0 + _rng.nextDouble() * 2,
        ));
      }
    }

    if (!widget.session.isRunning) return;
    _clock += dt;

    // The tempo only drains while the tile sits on the dock (committed drags
    // pause the clock so a deliberate placement isn't punished mid-motion).
    if (_dock != null && !_dragging) {
      _dockTime -= dt;
      if (_dockTime <= 0) _missDock();
    }
  }

  // ── Placement / scoring ──────────────────────────────────────────────────────

  void _showRole(_LayerId s) {
    final l = _layer(s);
    _roleText = '${l.name} — ${l.role}';
    _roleColor = l.color;
    _roleAge = 0;
  }

  /// Tempo ran out: requeue the missed layer (so the column can still complete),
  /// reset the streak, flash red, and dock the next tile. No points lost.
  void _missDock() {
    final missed = _dock;
    _streak = 0;
    _wrongFlash = 0.45;
    if (missed != null) _queue.add(missed);
    _dockNext();
  }

  int _bandAt(Offset p) {
    for (var i = 0; i < _bandRects.length; i++) {
      if (_bandRects[i].inflate(6).contains(p)) return i;
    }
    return -1;
  }

  void _resolveDrop() {
    final layer = _dock;
    if (layer == null) return;
    final band = _bandAt(_dragPos);

    // Dropped outside any band, or onto an already-filled band → bounce home,
    // no penalty. (The tempo keeps the pressure on.)
    if (band < 0 || _filled[band] != null) return;

    final correctBand = _correct.indexOf(layer);
    if (band == correctBand) {
      _filled[band] = layer;
      _placedTotal++;
      _streak++;
      widget.session.noteStreak(_streak);
      final hot = _streak >= 5; // a hot streak banks layers double (the combo)
      final gain = hot ? 2 : 1;
      widget.session.addScore(gain);
      final c = _bandRects[band].center;
      _fx.addAll(FxBurst.spawn(c, _layer(layer).color, count: 12));
      _pops.add(FxPop(c.translate(0, -20), hot ? '+2' : '+1', _layer(layer).color));
      _dock = null;
      if (_filled.every((x) => x != null)) {
        _completeColumn();
      } else {
        _dockNext();
      }
    } else {
      // Wrong depth: show the BREAK at the band the player aimed at, reset the
      // streak, and bounce the tile back to the dock to try again.
      _streak = 0;
      _breakBand = band;
      _breakAge = 0;
      _wrongFlash = 0.4;
    }
  }

  void _completeColumn() {
    // Non-blocking celebration: a quick come-alive flash, then the next, deeper
    // column seeds INSTANTLY so play never freezes.
    final bonus = _columnSize;
    widget.session.addScore(bonus);
    _streak++;
    widget.session.noteStreak(_streak);
    _aliveGlow = 1.0;
    if (_bandRects.isNotEmpty) {
      _pops.add(FxPop(Offset(_sz.width / 2, _bandRects.first.top - 14),
          'SKIN ALIVE +$bonus', _good));
      for (final r in _bandRects) {
        _fx.addAll(FxBurst.spawn(r.center, _accent, count: 6, speed: 90));
      }
    }
    _level++;
    _buildColumn();
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  bool _hitDock(Offset p) => _dockRect.inflate(10).contains(p);

  void _onTapUp(Offset p) {
    // Dedicated, non-overloaded info gesture: tap the docked tile to read its
    // role. There is no "remove" to collide with — placed bands lock.
    if (_dock != null && _hitDock(p)) _showRole(_dock!);
  }

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning || _dock == null) return;
    if (!_hitDock(p)) return;
    _dragging = true;
    _dragPos = p;
  }

  void _onPanUpdate(Offset p) {
    if (!_dragging) return;
    _dragPos = p; // ticker repaints — no setState for a smooth drag
  }

  void _onPanEnd() {
    if (!_dragging) return;
    _dragging = false;
    _resolveDrop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        _sz = newSz;
        _computeLayout(newSz);
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTapUp(d.localPosition),
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            painter: _SkinV2Painter(repaint: _ticker, state: this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────

class _SkinV2Painter extends CustomPainter {
  final _SkinLayersV2GameState s;
  _SkinV2Painter({required Listenable repaint, required _SkinLayersV2GameState state})
      : s = state,
        super(repaint: repaint);

  static const Color _accent = _SkinLayersV2GameState._accent;
  static const Color _good = _SkinLayersV2GameState._good;
  static const Color _break = _SkinLayersV2GameState._break;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, _accent, s._clock, motes: 20);

    if (s._wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = _break.withValues(alpha: s._wrongFlash * 0.16));
    }

    _drawHeader(canvas, size);
    _drawDepthGuide(canvas, size);
    _drawBands(canvas, size);
    _drawBoundaries(canvas, size);
    _drawHint(canvas, size);
    _drawTempoAndDock(canvas, size);
    _drawDrag(canvas, size);
    _drawRoleCard(canvas, size);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  void _drawHeader(Canvas canvas, Size size) {
    final goal = s._aliveGlow > 0.5
        ? 'THE SKIN COMES ALIVE'
        : 'DRAG EACH LAYER TO ITS DEPTH — BEAT THE TEMPO';
    GameFx.text(canvas, goal, Offset(size.width / 2, 14), 11,
        Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700);
    GameFx.text(canvas, 'tap the tile to read its role',
        Offset(size.width / 2, 30), 8.5, Colors.white.withValues(alpha: 0.32),
        weight: FontWeight.w600);
    if (s._level > 0) {
      GameFx.text(canvas, 'SECTION ${s._level + 1}',
          Offset(size.width - 42, 16), 10, _accent.withValues(alpha: 0.85),
          weight: FontWeight.w700);
    }
    if (s._streak >= 2) {
      GameFx.text(canvas, '🔥 x${s._streak}', Offset(44, 16), 11,
          (s._streak >= 5 ? _accent : Colors.white).withValues(alpha: 0.85),
          weight: FontWeight.w800);
    }
  }

  void _drawDepthGuide(Canvas canvas, Size size) {
    final rects = s._bandRects;
    if (rects.isEmpty) return;
    final x = rects.first.left - 14;
    canvas.drawLine(
        Offset(x, rects.first.top),
        Offset(x, rects.last.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    GameFx.text(canvas, 'SURFACE', Offset(x - 2, rects.first.top - 10), 8,
        Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
    GameFx.text(canvas, 'DEEP', Offset(x - 2, rects.last.bottom + 10), 8,
        Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
  }

  void _drawBands(Canvas canvas, Size size) {
    for (var i = 0; i < s._bandRects.length; i++) {
      final r = s._bandRects[i];
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
      final layer = s._filled[i];
      if (layer == null) {
        canvas.drawRRect(
            rr, Paint()..color = Colors.white.withValues(alpha: 0.04));
        canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = Colors.white.withValues(alpha: 0.18));
        GameFx.text(canvas, '${i + 1}', Offset(r.left + 12, r.center.dy), 10,
            Colors.white.withValues(alpha: 0.30), weight: FontWeight.w700);
      } else {
        _drawFilledBand(canvas, r, layer, i);
      }
    }
  }

  void _drawFilledBand(Canvas canvas, Rect r, _LayerId id, int i) {
    final l = _layer(id);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    final pulse = s._aliveGlow > 0
        ? 0.5 + 0.5 * math.sin(s._clock * 7 + i * 0.6)
        : 0.0;
    canvas.drawRRect(
        rr,
        Paint()
          ..color = l.color.withValues(alpha: 0.30 + pulse * 0.20 * s._aliveGlow));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = _good.withValues(alpha: 0.85));
    final showFull = r.width >= 130;
    final iconSize = (r.height * 0.42).clamp(13.0, 20.0);
    final labelSize = (r.height * 0.30).clamp(8.0, 12.0);
    if (showFull) {
      GameFx.text(canvas, l.emoji, Offset(r.center.dx - r.width * 0.30,
          r.center.dy), iconSize, Colors.white);
      GameFx.text(canvas, l.name, Offset(r.center.dx + r.width * 0.04,
          r.center.dy), labelSize, Colors.white.withValues(alpha: 0.95),
          weight: FontWeight.w700);
    } else {
      GameFx.text(canvas, l.emoji, Offset(r.center.dx, r.center.dy - r.height * 0.16),
          iconSize, Colors.white);
      GameFx.text(canvas, l.abbrev, Offset(r.center.dx, r.center.dy + r.height * 0.30),
          labelSize, Colors.white.withValues(alpha: 0.92),
          weight: FontWeight.w700);
    }
  }

  // Healthy teal boundary between correctly filled neighbours; a flashing red
  // BREAK at the band the player just dropped into out of order.
  void _drawBoundaries(Canvas canvas, Size size) {
    final rects = s._bandRects;
    for (var i = 0; i < rects.length - 1; i++) {
      if (s._filled[i] == null || s._filled[i + 1] == null) continue;
      final y = (rects[i].bottom + rects[i + 1].top) / 2;
      canvas.drawLine(
          Offset(rects[i].left + 6, y),
          Offset(rects[i].right - 6, y),
          Paint()
            ..color = _good.withValues(alpha: 0.9)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
    if (s._breakBand >= 0 && s._breakBand < rects.length && s._breakAge < 0.6) {
      final r = rects[s._breakBand];
      final a = (1 - s._breakAge / 0.6).clamp(0.0, 1.0);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(12)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = _break.withValues(alpha: 0.95 * a));
    }
  }

  // The live teaching hint: a pulsing target ring on the correct band, strong
  // for a beginner and fading to nothing as the streak climbs (pure recall).
  void _drawHint(Canvas canvas, Size size) {
    final dock = s._dock;
    if (dock == null) return;
    final correctBand = s._correct.indexOf(dock);
    if (correctBand < 0 || correctBand >= s._bandRects.length) return;
    if (s._filled[correctBand] != null) return;
    final strength = (1 - s._streak / 6).clamp(0.0, 1.0);
    if (strength <= 0.02) return;
    final pulse = 0.5 + 0.5 * math.sin(s._clock * 4);
    final r = s._bandRects[correctBand];
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _layer(dock).color.withValues(
              alpha: strength * (0.45 + 0.45 * pulse)));
  }

  void _drawTempoAndDock(Canvas canvas, Size size) {
    final dock = s._dock;
    // Tempo bar — the visible, accelerating cadence.
    final t = s._tempoRect;
    final ratio = (s._dockTime / s._dockMaxCur).clamp(0.0, 1.0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(t, const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.08));
    final danger = ratio < 0.3;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(t.left, t.top, t.width * ratio, t.height),
            const Radius.circular(4)),
        Paint()..color = (danger ? _break : _accent).withValues(alpha: 0.9));

    if (dock == null) return;
    // Docked tile (the incoming layer) — hidden while it's being dragged.
    if (!s._dragging) _drawTile(canvas, dock, s._dockRect.center, s._dockRect, info: true);
  }

  void _drawDrag(Canvas canvas, Size size) {
    if (!s._dragging || s._dock == null) return;
    final rect = Rect.fromCenter(
        center: s._dragPos, width: s._dockRect.width, height: s._dockRect.height);
    _drawTile(canvas, s._dock!, s._dragPos, rect, dragging: true);
  }

  void _drawTile(Canvas canvas, _LayerId id, Offset center, Rect rect,
      {bool dragging = false, bool info = false}) {
    final l = _layer(id);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    if (dragging) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(16)),
          Paint()..color = l.color.withValues(alpha: 0.22));
    }
    canvas.drawRRect(
        rr, Paint()..color = l.color.withValues(alpha: dragging ? 0.45 : 0.34));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = l.color.withValues(alpha: 0.8));
    final iconSize = (rect.height * 0.40).clamp(14.0, 22.0);
    final labelSize = (rect.height * 0.26).clamp(9.0, 13.0);
    GameFx.text(canvas, l.emoji, Offset(center.dx - rect.width * 0.30, center.dy),
        iconSize, Colors.white);
    GameFx.text(canvas, l.name, Offset(center.dx + rect.width * 0.04, center.dy),
        labelSize, Colors.white.withValues(alpha: 0.95), weight: FontWeight.w700);
    if (info) {
      // The always-visible info affordance: a small ⓘ badge on the dock tile.
      final ib = Offset(rect.right - 14, rect.top + 12);
      canvas.drawCircle(ib, 8, Paint()..color = Colors.black.withValues(alpha: 0.35));
      canvas.drawCircle(
          ib,
          8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: 0.6));
      GameFx.text(canvas, 'i', ib.translate(0, -0.5), 10,
          Colors.white.withValues(alpha: 0.85), weight: FontWeight.w800);
    }
  }

  void _drawRoleCard(Canvas canvas, Size size) {
    if (s._roleAge >= 3.0 || s._roleText.isEmpty) return;
    final a = (1 - (s._roleAge - 2.4).clamp(0.0, 0.6) / 0.6).clamp(0.0, 1.0);
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.71),
        width: (size.width - 40).clamp(140.0, 420.0),
        height: 40);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.36 * a));
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
  bool shouldRepaint(covariant _SkinV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame draws the LITERAL
// components a player meets (the same depth-bands, docked tile, tempo bar,
// teal seams and red break ring the live painter uses), so the intro shows
// the real game, not a diagram. Cheap + static: rendered once in the intro.
// ═══════════════════════════════════════════════════════════════════════════

// A representative surface→deep column: Corneum(0) → Spinosum(2) →
// Reticular(8) → Hypodermis(11). Unique depths = one correct band each.
const List<_LayerId> _kLegendColumn = [
  _LayerId.corneum,
  _LayerId.spinosum,
  _LayerId.reticular,
  _LayerId.hypodermis,
];

const Color _lgGood = _SkinLayersV2GameState._good;
const Color _lgAccent = _SkinLayersV2GameState._accent;
const Color _lgBreak = _SkinLayersV2GameState._break;

/// Lay out [n] stacked depth-bands centred in [size] (mirrors `_computeLayout`).
List<Rect> _lgColumnRects(Size size, int n) {
  const gap = 6.0;
  final top = size.height * 0.12;
  final bottom = size.height * 0.62;
  final avail = bottom - top;
  final bandH = ((avail - gap * (n - 1)) / n).clamp(20.0, 60.0);
  final totalH = bandH * n + gap * (n - 1);
  final startY = top + (avail - totalH) / 2;
  final bandW = (size.width * 0.62).clamp(120.0, 320.0);
  final left = (size.width - bandW) / 2;
  return [
    for (var i = 0; i < n; i++)
      Rect.fromLTWH(left, startY + i * (bandH + gap), bandW, bandH),
  ];
}

/// The SURFACE↕DEEP guide rail beside the column (mirrors `_drawDepthGuide`).
void _lgDepthGuide(Canvas canvas, List<Rect> rects) {
  if (rects.isEmpty) return;
  final x = rects.first.left - 14;
  canvas.drawLine(
      Offset(x, rects.first.top),
      Offset(x, rects.last.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
  GameFx.text(canvas, 'SURFACE', Offset(x + 2, rects.first.top - 10), 8,
      Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
  GameFx.text(canvas, 'DEEP', Offset(x + 2, rects.last.bottom + 10), 8,
      Colors.white.withValues(alpha: 0.34), weight: FontWeight.w700);
}

/// One depth-band: empty+numbered when [id] is null, else filled with the
/// layer's real colour/emoji/name and a teal border (mirrors `_drawBands`).
void _lgBand(Canvas canvas, Rect r, {_LayerId? id, int number = 0, bool alive = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
  if (id == null) {
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.04));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.18));
    if (number > 0) {
      GameFx.text(canvas, '$number', Offset(r.left + 12, r.center.dy), 10,
          Colors.white.withValues(alpha: 0.30), weight: FontWeight.w700);
    }
    return;
  }
  final l = _layer(id);
  canvas.drawRRect(
      rr, Paint()..color = l.color.withValues(alpha: alive ? 0.5 : 0.30));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = _lgGood.withValues(alpha: 0.85));
  final showFull = r.width >= 130;
  final iconSize = (r.height * 0.42).clamp(13.0, 20.0);
  final labelSize = (r.height * 0.30).clamp(8.0, 12.0);
  if (showFull) {
    GameFx.text(canvas, l.emoji,
        Offset(r.center.dx - r.width * 0.30, r.center.dy), iconSize, Colors.white);
    GameFx.text(canvas, l.name, Offset(r.center.dx + r.width * 0.04, r.center.dy),
        labelSize, Colors.white.withValues(alpha: 0.95), weight: FontWeight.w700);
  } else {
    GameFx.text(canvas, l.emoji,
        Offset(r.center.dx, r.center.dy - r.height * 0.16), iconSize, Colors.white);
    GameFx.text(canvas, l.abbrev,
        Offset(r.center.dx, r.center.dy + r.height * 0.30), labelSize,
        Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);
  }
}

/// The docked / dragged incoming layer tile (mirrors `_drawTile`).
void _lgTile(Canvas canvas, _LayerId id, Rect rect, {bool dragging = false}) {
  final l = _layer(id);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  if (dragging) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(16)),
        Paint()..color = l.color.withValues(alpha: 0.22));
  }
  canvas.drawRRect(
      rr, Paint()..color = l.color.withValues(alpha: dragging ? 0.45 : 0.34));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = l.color.withValues(alpha: 0.8));
  final iconSize = (rect.height * 0.40).clamp(14.0, 22.0);
  final labelSize = (rect.height * 0.26).clamp(9.0, 13.0);
  GameFx.text(canvas, l.emoji,
      Offset(rect.center.dx - rect.width * 0.30, rect.center.dy), iconSize,
      Colors.white);
  GameFx.text(canvas, l.name,
      Offset(rect.center.dx + rect.width * 0.04, rect.center.dy), labelSize,
      Colors.white.withValues(alpha: 0.95), weight: FontWeight.w700);
}

// Frame 1 — the core verb: an empty numbered column + the docked layer with an
// upward drag arrow aimed at its correct surface band.
void _legendColumn(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final rects = _lgColumnRects(size, 4);
  if (rects.isEmpty) return;
  _lgDepthGuide(canvas, rects);
  for (var i = 0; i < rects.length; i++) {
    _lgBand(canvas, rects[i], number: i + 1);
  }
  final band0 = rects.first;
  final dockW = (band0.width * 0.82).clamp(110.0, 280.0);
  final dockH = (size.height * 0.12).clamp(34.0, 50.0);
  final dockRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.86),
      width: dockW,
      height: dockH);
  _lgTile(canvas, _LayerId.corneum, dockRect);
  // Upward drag arrow: dock → correct (surface) band.
  final tipY = band0.bottom + 6;
  final tipX = band0.center.dx;
  final p = Paint()
    ..color = _layer(_LayerId.corneum).color.withValues(alpha: 0.75)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(tipX, dockRect.top - 6), Offset(tipX, tipY), p);
  canvas.drawLine(Offset(tipX, tipY), Offset(tipX - 6, tipY + 9), p);
  canvas.drawLine(Offset(tipX, tipY), Offset(tipX + 6, tipY + 9), p);
}

// Frame 2 — how to score: the column filled in correct depth order, teal seams
// linking correct neighbours, and a +1 layer bank pop.
void _legendMatch(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final rects = _lgColumnRects(size, 4);
  if (rects.isEmpty) return;
  _lgDepthGuide(canvas, rects);
  for (var i = 0; i < rects.length; i++) {
    _lgBand(canvas, rects[i], id: _kLegendColumn[i]);
  }
  final seam = Paint()
    ..color = _lgGood.withValues(alpha: 0.9)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < rects.length - 1; i++) {
    final y = (rects[i].bottom + rects[i + 1].top) / 2;
    canvas.drawLine(
        Offset(rects[i].left + 6, y), Offset(rects[i].right - 6, y), seam);
  }
  final b = rects[1];
  GameFx.text(canvas, '+1',
      Offset(b.center.dx + b.width * 0.36, b.top - b.height * 0.4), 16,
      _layer(_kLegendColumn[1]).color, weight: FontWeight.w800);
}

// Frame 3 — the danger: an almost-empty red tempo bar and a red BREAK ring on a
// band dropped out of order, with the incoming tile still waiting.
void _legendTempo(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final rects = _lgColumnRects(size, 4);
  if (rects.isEmpty) return;
  _lgBand(canvas, rects[0], id: _kLegendColumn[0]);
  _lgBand(canvas, rects[1], number: 2);
  _lgBand(canvas, rects[2], number: 3);
  _lgBand(canvas, rects[3], id: _kLegendColumn[3]);
  // Red break ring — the wrong-depth drop.
  canvas.drawRRect(
      RRect.fromRectAndRadius(rects[2].inflate(3), const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _lgBreak.withValues(alpha: 0.95));
  // Draining tempo bar (near empty → red).
  final barW = rects.first.width;
  final barLeft = (size.width - barW) / 2;
  final tempo = Rect.fromLTWH(barLeft, size.height * 0.74, barW, 8);
  canvas.drawRRect(RRect.fromRectAndRadius(tempo, const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(tempo.left, tempo.top, tempo.width * 0.2, tempo.height),
          const Radius.circular(4)),
      Paint()..color = _lgBreak.withValues(alpha: 0.9));
  final dockW = (barW * 0.82).clamp(110.0, 280.0);
  final dockH = (size.height * 0.12).clamp(34.0, 50.0);
  final dockRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.88),
      width: dockW,
      height: dockH);
  _lgTile(canvas, _kLegendColumn[2], dockRect);
}

// Frame 4 — the escalation: a completed column pulsing alive with rising sweat
// beads, the hot-streak combo lit, before a deeper column seeds.
void _legendAlive(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final rects = _lgColumnRects(size, 4);
  if (rects.isEmpty) return;
  for (var i = 0; i < rects.length; i++) {
    _lgBand(canvas, rects[i], id: _kLegendColumn[i], alive: true);
  }
  // Rising sweat beads (healthy teal) — the "skin alive" flourish.
  for (var i = 0; i < 7; i++) {
    final r = rects[i % rects.length];
    final x = r.left + r.width * ((i * 0.17 + 0.12) % 1.0);
    final y = r.center.dy - i * 6.0;
    canvas.drawCircle(
        Offset(x, y), 2.5, Paint()..color = _lgGood.withValues(alpha: 0.7));
  }
  GameFx.text(canvas, 'SKIN ALIVE +4',
      Offset(size.width / 2, rects.first.top - 14), 12, _lgGood,
      weight: FontWeight.w800);
  GameFx.text(canvas, '🔥 x5', Offset(size.width / 2, size.height * 0.82), 14,
      _lgAccent, weight: FontWeight.w800);
}

/// The visual manual for Skin Layers v2 — wired into the registry spec.
final List<LegendFrame> skinLayersV2LegendFrames = [
  const LegendFrame(
      caption: 'Drag the incoming layer up to its correct depth',
      paint: _legendColumn),
  const LegendFrame(
      caption: 'Right depth banks a layer — teal seams link them',
      paint: _legendMatch),
  const LegendFrame(
      caption: 'Beat the draining tempo — wrong band breaks red',
      paint: _legendTempo),
  const LegendFrame(
      caption: 'Fill every band: skin comes alive, then dives deeper',
      paint: _legendAlive),
];
