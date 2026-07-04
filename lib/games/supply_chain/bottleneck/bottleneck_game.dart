import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../mini_game.dart';

/// Bottleneck — "Keep the Line Moving".
///
/// A potato supply chain runs as a left→right conveyor of five stages:
///   Farm → Wash → Process → Warehouse → Ship.
/// Potatoes ripen into the Farm's bin and flow stage→stage. Each stage moves
/// product at its own RATE into the next stage's bin. When a stage is too slow
/// for what's arriving, potatoes PILE UP in its bin while every downstream
/// stage STARVES — and if a bin overflows its buffer, those potatoes ROT
/// (wasted). The slowest stage caps the WHOLE chain's output (Theory of
/// Constraints).
///
/// The player TAPS a stage to BOOST it for a moment (then a short cooldown).
/// The skill is reading the line: boost the CURRENT bottleneck — the bin that's
/// filling — not the fast stages that are already keeping up. Boosting a
/// non-bottleneck does nothing for throughput.
///
/// Rates DRIFT over time so the bottleneck wanders; incoming demand rises; late
/// in the round two stages can choke at once.
///
/// Score = potatoes SHIPPED out the end during the round. The host owns the
/// clock, 3-2-1 countdown, score HUD and results; this widget renders only the
/// play area and reports through the session.
class BottleneckGame extends StatefulWidget {
  final MiniGameSession session;
  const BottleneckGame({super.key, required this.session});

  @override
  State<BottleneckGame> createState() => _BottleneckGameState();
}

// ── Tuning (all in one place; play-test freely) ───────────────────────────────
const int _kStages = 5;

/// Per-stage base throughput (potatoes/second) before drift / boost.
const List<double> _kBaseRate = [2.7, 2.2, 1.8, 2.3, 2.0];

/// Each bin holds this many potatoes before it overflows → waste.
const double _kBinCap = 14.0;

/// Incoming demand into the Farm bin: ramps base → peak across the round.
const double _kInflowStart = 1.4;
const double _kInflowPeak = 3.3;

/// A boost lasts this long, multiplies the stage rate, then locks out for
/// [_kCooldown] seconds.
const double _kBoostDuration = 1.3;
const double _kBoostMult = 2.5;
const double _kCooldown = 1.7;

/// A bin counts as bottlenecked once its fill ratio passes this (drops over the
/// round so chokes flag a touch earlier as it gets harder).
const double _kBottleneckRatio = 0.45;

// ── Palette (potato supply-chain) ─────────────────────────────────────────────
const Color _kBelt = Color(0xFF2A2622);
const Color _kBeltEdge = Color(0xFF3D352E);
const Color _kPotato = Color(0xFFE8B873);
const Color _kPotatoDark = Color(0xFFB07C3E);
const Color _kStarve = Color(0xFF6E8B6A); // calm green = flowing fine
const Color _kWarn = Color(0xFFE16416); // brand orange = filling up
const Color _kChoke = Color(0xFFE2574B); // red = bottleneck / overflow
const Color _kShip = Color(0xFF7FC8C2);
const String _kFont = Potatuhs.bodyFont;

class _Stage {
  final String name;
  final IconData icon;
  final double driftSpeed; // rad/s of this stage's rate wobble
  final double driftPhase;
  const _Stage(this.name, this.icon, this.driftSpeed, this.driftPhase);
}

const List<_Stage> _kStageDefs = [
  _Stage('FARM', Icons.agriculture, 0.55, 0.0),
  _Stage('WASH', Icons.water_drop, 0.70, 1.7),
  _Stage('PROCESS', Icons.settings, 0.62, 3.1),
  _Stage('STORE', Icons.warehouse, 0.78, 4.6),
  _Stage('SHIP', Icons.local_shipping, 0.66, 5.9),
];

class _Popup {
  Offset pos;
  final String text;
  final Color color;
  double age = 0;
  final double life;
  _Popup(this.pos, this.text, this.color, {this.life = 0.9});
}

class _BottleneckGameState extends State<BottleneckGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  // Per-stage state.
  final List<double> _queue = List<double>.filled(_kStages, 0);
  final List<double> _boostT = List<double>.filled(_kStages, 0);
  final List<double> _coolT = List<double>.filled(_kStages, 0);
  final List<double> _overflowFlash = List<double>.filled(_kStages, 0);
  final List<double> _effRate = List<double>.filled(_kStages, 0);

  double _elapsed = 0; // seconds spent in the playing phase
  double _shippedAcc = 0; // fractional shipped tally
  int _shippedScored = 0; // whole potatoes already reported to the session
  int _flowStreak = 0; // consecutive shipments with no overflow
  double _throughput = 0; // smoothed potatoes/sec out the end
  double _beltPhase = 0;
  double _denyShake = 0; // feedback when tapping a stage on cooldown

  final List<_Popup> _popups = [];

  // Last layout, for hit-testing taps → stage index and popup placement.
  double _w = 1, _h = 1;

  double get _duration =>
      widget.session.spec.durationSeconds.toDouble().clamp(1, 600);

  @override
  void initState() {
    super.initState();
    // Seed a little product so the calm pre-round preview reads as a live line.
    _queue[0] = 3;
    _queue[1] = 1.5;
    // ATTRACT autopilot: this game knows how to read its own line and boost the
    // real bottleneck. Registered always (harmless in normal play — the host
    // only calls it in autoplay). See [_autoStep]. Bottleneck is an action game,
    // so the interval stays at the default (act every ~250ms tick).
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). Reads the game's own
  /// bin levels and boosts the TRUE bottleneck: the most-backed-up stage that is
  /// actually boostable (not mid-boost, not on cooldown). Bins share one cap
  /// [_kBinCap], so the largest queue is the highest fill ratio — the same stage
  /// the UI flags red. Boosting a fast/cooling stage is wasted, so those are
  /// skipped; if nothing is boostable (or the line is empty) it does nothing and
  /// waits. Deterministic: ties resolve to the most-backed-up, then the first.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    var best = -1;
    var bestQueue = 0.0;
    for (var i = 0; i < _kStages; i++) {
      // Not boostable: currently boosting or still cooling down (see [_tapAt]).
      if (_boostT[i] > 0 || _coolT[i] > 0) continue;
      // Strict > keeps it deterministic and only fires on a real backlog
      // (queue 0 never wins), so we never waste a boost on an idle stage.
      if (_queue[i] > bestQueue) {
        bestQueue = _queue[i];
        best = i;
      }
    }
    if (best < 0) return; // nothing worth boosting right now
    _boostStage(best);
  }

  // ── Simulation ──────────────────────────────────────────────────────────────
  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    _beltPhase += (0.4 + _throughput) * dt;
    _denyShake = math.max(0, _denyShake - dt * 4);
    for (var i = 0; i < _kStages; i++) {
      _overflowFlash[i] = math.max(0, _overflowFlash[i] - dt * 2.2);
    }
    for (final p in _popups) {
      p.age += dt;
      p.pos = p.pos.translate(0, -34 * dt);
    }
    _popups.removeWhere((p) => p.age >= p.life);

    if (running) {
      _step(dt);
    } else {
      // Calm idle drift: gently churn product without scoring so the line
      // looks alive during the ready / countdown state.
      _idleDrift(dt);
    }

    if (mounted) setState(() {});
  }

  double _progress() => (_elapsed / _duration).clamp(0.0, 1.0);

  /// This stage's instantaneous rate: base × drift wobble × boost. Drift makes
  /// the slowest (bottleneck) stage wander; amplitude grows late so two stages
  /// can choke at once.
  double _rateOf(int i, double p) {
    final s = _kStageDefs[i];
    final amp = 0.34 + 0.12 * p;
    final wobble = math.sin(_elapsed * s.driftSpeed + s.driftPhase);
    final mult = (0.62 + amp * wobble).clamp(0.22, 1.05);
    final boost = _boostT[i] > 0 ? _kBoostMult : 1.0;
    return _kBaseRate[i] * mult * boost;
  }

  void _step(double dt) {
    _elapsed += dt;
    final p = _progress();

    for (var i = 0; i < _kStages; i++) {
      _boostT[i] = math.max(0, _boostT[i] - dt);
      _coolT[i] = math.max(0, _coolT[i] - dt);
      _effRate[i] = _rateOf(i, p);
    }

    // Demand ripens into the Farm bin.
    _queue[0] += (_kInflowStart + (_kInflowPeak - _kInflowStart) * p) * dt;

    // Flow is computed from the current snapshot, then applied — so processing
    // order can't bias which stage wins the frame.
    final flow = List<double>.filled(_kStages, 0);
    for (var i = 0; i < _kStages; i++) {
      flow[i] = math.min(_queue[i], _effRate[i] * dt);
    }
    for (var i = 0; i < _kStages; i++) {
      _queue[i] -= flow[i];
      if (i < _kStages - 1) {
        _queue[i + 1] += flow[i];
      } else {
        _shippedAcc += flow[i];
      }
    }

    // Overflow: anything past the bin cap rots. Upstream stages over-feeding a
    // slow stage is exactly what fills it — the bottleneck's bin is what spills.
    var wasted = false;
    for (var i = 0; i < _kStages; i++) {
      if (_queue[i] > _kBinCap) {
        _queue[i] = _kBinCap;
        _overflowFlash[i] = 1.0;
        wasted = true;
      }
    }
    if (wasted) _flowStreak = 0;

    // Score whole shipped potatoes.
    final delta = _shippedAcc.floor() - _shippedScored;
    if (delta > 0) {
      widget.session.addScore(delta);
      _shippedScored += delta;
      _flowStreak += delta;
      widget.session.noteStreak(_flowStreak);
      _popups.add(_Popup(
        Offset(_w * 0.86, _h * 0.30),
        '+$delta',
        _kShip,
      ));
    }

    // Smoothed throughput out the end (potatoes/sec).
    final inst = flow[_kStages - 1] / dt;
    _throughput += (inst - _throughput) * (dt * 2.5).clamp(0.0, 1.0);
  }

  void _idleDrift(double dt) {
    // Trickle through the chain at a gentle fixed rate, recycling at the end so
    // nothing accumulates or scores before the round starts.
    const r = 1.2;
    final flow = List<double>.filled(_kStages, 0);
    for (var i = 0; i < _kStages; i++) {
      flow[i] = math.min(_queue[i], r * dt);
    }
    for (var i = 0; i < _kStages; i++) {
      _queue[i] -= flow[i];
      if (i < _kStages - 1) {
        _queue[i + 1] += flow[i];
      }
    }
    // Recycle shipped product back to the farm so the preview loops calmly.
    _queue[0] += flow[_kStages - 1] + 0.8 * dt;
    if (_queue[0] > 5) _queue[0] = 5;
    for (var i = 0; i < _kStages; i++) {
      _effRate[i] = _kBaseRate[i] * 0.7;
    }
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _tapAt(Offset local) {
    if (!widget.session.isRunning) return;
    final colW = _w / _kStages;
    final i = (local.dx / colW).floor().clamp(0, _kStages - 1);
    _boostStage(i);
  }

  /// Boost stage [i] — the shared BOOST handler behind both a real tap ([_tapAt])
  /// and the attract autopilot ([_autoStep]). Refuses a stage that's already
  /// boosting or cooling down (that's the wasted tap the deny-shake warns about).
  void _boostStage(int i) {
    if (!widget.session.isRunning) return;
    if (_coolT[i] > 0 || _boostT[i] > 0) {
      _denyShake = 1.0;
      return;
    }
    _boostT[i] = _kBoostDuration;
    _coolT[i] = _kBoostDuration + _kCooldown;
    final colW = _w / _kStages;
    _popups.add(_Popup(
      Offset(colW * (i + 0.5), _h * 0.16),
      'BOOST',
      _kStageColor(i, _bottleneckSet().contains(i)),
      life: 0.7,
    ));
  }

  /// Indices whose bins are bottlenecked (filling). Always includes the single
  /// worst if anything is meaningfully backed up, plus any other stage over the
  /// threshold — so late-round double-chokes both light up.
  Set<int> _bottleneckSet() {
    final thresh = _kBottleneckRatio - 0.12 * _progress();
    final out = <int>{};
    var worst = -1;
    var worstFill = 0.0;
    for (var i = 0; i < _kStages; i++) {
      final fill = _queue[i] / _kBinCap;
      if (fill >= thresh) out.add(i);
      if (fill > worstFill) {
        worstFill = fill;
        worst = i;
      }
    }
    if (worst >= 0 && worstFill >= 0.3) out.add(worst);
    return out;
  }

  static Color _kStageColor(int i, bool choking) {
    if (choking) return _kChoke;
    return i == _kStages - 1 ? _kShip : _kStarve;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tapAt(d.localPosition),
        child: CustomPaint(
          size: Size(_w, _h),
          painter: _BottleneckPainter(this),
        ),
      );
    });
  }
}

class _BottleneckPainter extends CustomPainter {
  final _BottleneckGameState s;
  _BottleneckPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final running = s.widget.session.isRunning;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF14110F));

    final colW = size.width / _kStages;
    final bottlenecks = s._bottleneckSet();

    // Geometry: a header strip, the conveyor band, the bins, a boost footer.
    const headerH = 30.0;
    final topMeterH = 34.0;
    final beltY = topMeterH + headerH + 14;
    final binTop = beltY + 18;
    final footerH = 26.0;
    final binBottom = size.height - footerH - 8;
    final binH = math.max(20.0, binBottom - binTop);

    _paintThroughput(canvas, size, topMeterH);
    _paintBelt(canvas, size, beltY, colW);

    for (var i = 0; i < _kStages; i++) {
      final cx = colW * (i + 0.5);
      final choking = bottlenecks.contains(i);
      final fill = (s._queue[i] / _kBinCap).clamp(0.0, 1.0);
      final color = _BottleneckGameState._kStageColor(i, choking);

      _paintStageHeader(
          canvas, i, cx, topMeterH + 6, colW, choking, color);
      _paintBin(canvas, i, cx, binTop, binH, colW, fill, choking, color);
      _paintFooter(canvas, i, cx, size.height - footerH - 2, colW);
    }

    _paintExit(canvas, size, binTop, binH);

    if (!running) _paintReadyHint(canvas, size);

    for (final p in s._popups) {
      _paintPopup(canvas, p);
    }
  }

  // ── Throughput meter (top) ─────────────────────────────────────────────────
  void _paintThroughput(Canvas canvas, Size size, double h) {
    const pad = 14.0;
    final barW = size.width - pad * 2;
    final y = h * 0.5 + 4;
    // Track.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, y, barW, 7),
      const Radius.circular(4),
    );
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    // Fill — normalised against a healthy ~3.5/s line.
    final frac = (s._throughput / 3.5).clamp(0.0, 1.0);
    final fillColor = Color.lerp(_kWarn, _kStarve, frac)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, y, barW * frac, 7),
        const Radius.circular(4),
      ),
      Paint()
        ..color = fillColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    _text(canvas, 'THROUGHPUT', Offset(pad, y - 12),
        size: 9, color: Colors.white.withValues(alpha: 0.45), align: -1, bold: true);
    _text(canvas, '${s._throughput.toStringAsFixed(1)}/s',
        Offset(size.width - pad, y - 12),
        size: 11, color: fillColor, align: 1, bold: true);
  }

  // ── Conveyor belt with drifting potatoes ───────────────────────────────────
  void _paintBelt(Canvas canvas, Size size, double y, double colW) {
    final belt = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, y - 9, size.width - 12, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(belt, Paint()..color = _kBelt);
    canvas.drawRRect(
      belt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kBeltEdge,
    );
    // Scrolling potatoes ride the belt; speed already folded into _beltPhase.
    final span = size.width - 24;
    const spacing = 34.0;
    final count = (span / spacing).floor();
    final off = (s._beltPhase * 26) % spacing;
    for (var k = 0; k <= count; k++) {
      final x = 12 + k * spacing + off;
      if (x < 10 || x > size.width - 10) continue;
      _potato(canvas, Offset(x, y), 6.5, 4.5, 1.0);
    }
  }

  // ── Stage header: icon + name + rate ───────────────────────────────────────
  void _paintStageHeader(Canvas canvas, int i, double cx, double top,
      double colW, bool choking, Color color) {
    final def = _kStageDefs[i];
    _icon(canvas, def.icon, Offset(cx, top + 10), 17,
        choking ? _kChoke : Colors.white.withValues(alpha: 0.8));
    _text(canvas, def.name, Offset(cx, top + 24),
        size: 10,
        color: choking ? _kChoke : Colors.white.withValues(alpha: 0.7),
        align: 0,
        bold: true);
    // Rate read-out (potatoes/s this stage is currently moving).
    final boosted = s._boostT[i] > 0;
    _text(canvas, '${s._effRate[i].toStringAsFixed(1)}/s',
        Offset(cx, top + 37),
        size: 9,
        color: boosted ? _kShip : Colors.white.withValues(alpha: 0.4),
        align: 0,
        bold: boosted);
  }

  // ── Bin: the input buffer; pile height = queue, overflow = waste ───────────
  void _paintBin(Canvas canvas, int i, double cx, double top, double h,
      double colW, double fill, bool choking, Color color) {
    final binW = colW * 0.62;
    final left = cx - binW / 2;
    final shake = (choking && s._overflowFlash[i] > 0)
        ? (s._rng.nextDouble() - 0.5) * 4 * s._overflowFlash[i]
        : 0.0;
    final rect = Rect.fromLTWH(left + shake, top, binW, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Bin body.
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.28));

    // Fill.
    final fillH = h * fill;
    if (fillH > 2) {
      final fillRect = Rect.fromLTWH(
          left + shake, top + h - fillH, binW, fillH);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
          fillRect, Paint()..color = color.withValues(alpha: 0.22));
      // Surface potatoes bobbing at the top of the pile.
      final n = (fill * 6).ceil().clamp(0, 6);
      for (var k = 0; k < n; k++) {
        final px = left + shake + binW * (0.22 + 0.56 * ((k * 0.37) % 1));
        final bob = math.sin(s._beltPhase * 2 + k * 1.3) * 2;
        final py = top + h - fillH + 6 + (k % 2) * 7 + bob;
        _potato(canvas, Offset(px, py), 6, 4.2, 1.0);
      }
      canvas.restore();
    }

    // Border — colour tells the story: green ok, orange filling, red choke.
    final fillColor = fill < 0.25
        ? _kStarve
        : (fill < 0.7 ? _kWarn : _kChoke);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = choking ? 2.4 : 1.4
        ..color = choking
            ? _kChoke
            : fillColor.withValues(alpha: 0.55),
    );

    // Boost glow.
    if (s._boostT[i] > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kShip.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Bottleneck tag.
    if (choking) {
      final pulse = 0.5 + 0.5 * math.sin(s._beltPhase * 4);
      _text(canvas, 'BOTTLENECK', Offset(cx, top - 6),
          size: 8.5,
          color: _kChoke.withValues(alpha: 0.6 + 0.4 * pulse),
          align: 0,
          bold: true);
    } else if (fill < 0.12 && i > 0) {
      // Downstream of a choke and empty → starving.
      _text(canvas, 'idle', Offset(cx, top - 5),
          size: 8,
          color: Colors.white.withValues(alpha: 0.25),
          align: 0,
          bold: true);
    }
  }

  // ── Footer: tap-to-boost affordance + cooldown ─────────────────────────────
  void _paintFooter(Canvas canvas, int i, double cx, double y, double colW) {
    final boosting = s._boostT[i] > 0;
    final cooling = s._coolT[i] > 0 && !boosting;
    final w = colW * 0.7;
    final rect = Rect.fromCenter(center: Offset(cx, y + 8), width: w, height: 18);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    if (cooling) {
      // Cooldown drains the pill left→right.
      final frac = (s._coolT[i] / _kCooldown).clamp(0.0, 1.0);
      canvas.drawRRect(
          rr, Paint()..color = Colors.white.withValues(alpha: 0.06));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, w * (1 - frac), 18),
          const Radius.circular(9),
        ),
        Paint()..color = _kWarn.withValues(alpha: 0.18),
      );
      _text(canvas, 'cooldown', Offset(cx, y + 8),
          size: 8, color: Colors.white.withValues(alpha: 0.35), align: 0);
    } else if (boosting) {
      canvas.drawRRect(rr, Paint()..color = _kShip.withValues(alpha: 0.25));
      _text(canvas, 'BOOSTING', Offset(cx, y + 8),
          size: 8.5, color: _kShip, align: 0, bold: true);
    } else {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.18),
      );
      _text(canvas, 'TAP', Offset(cx, y + 8),
          size: 8.5, color: Colors.white.withValues(alpha: 0.45), align: 0, bold: true);
    }
  }

  // ── Ship exit at the right edge ────────────────────────────────────────────
  void _paintExit(Canvas canvas, Size size, double binTop, double binH) {
    final y = binTop + binH * 0.5;
    final x = size.width - 4;
    canvas.drawCircle(
      Offset(x, y),
      14,
      Paint()
        ..color = _kShip.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    _text(
      canvas,
      'Tap the BOTTLENECK to keep potatoes shipping',
      Offset(size.width / 2, size.height - 14),
      size: 11,
      color: Colors.white.withValues(alpha: 0.5),
      align: 0,
      bold: true,
    );
  }

  void _paintPopup(Canvas canvas, _Popup p) {
    final a = (1 - p.age / p.life).clamp(0.0, 1.0);
    _text(canvas, p.text, p.pos,
        size: p.text == 'BOOST' ? 12 : 15,
        color: p.color.withValues(alpha: a),
        align: 0,
        bold: true);
  }

  // ── Draw helpers ────────────────────────────────────────────────────────────
  void _potato(Canvas canvas, Offset c, double rx, double ry, double a) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.35);
    final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(rect, Paint()..color = _kPotatoDark.withValues(alpha: a));
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(-0.4, -0.6), width: rx * 1.7, height: ry * 1.6),
      Paint()..color = _kPotato.withValues(alpha: a),
    );
    canvas.restore();
  }

  void _icon(Canvas canvas, IconData icon, Offset center, double sz, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// [align]: -1 left, 0 centre, 1 right (relative to [at]).
  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required Color color,
      int align = 0,
      bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == 0
        ? -tp.width / 2
        : (align < 0 ? 0.0 : -tp.width);
    tp.paint(canvas, at + Offset(dx, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BottleneckPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same belt, bins and potatoes the live game uses). Static and
// cheap: rendered once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One tuber in the game's own two-oval style (mirrors `_BottleneckPainter._potato`).
void _legPotato(Canvas canvas, Offset c, double rx, double ry,
    {Color body = _kPotato, bool rot = false}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(0.35);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    Paint()..color = _kPotatoDark,
  );
  canvas.drawOval(
    Rect.fromCenter(
        center: const Offset(-0.4, -0.6), width: rx * 1.7, height: ry * 1.6),
    Paint()..color = body,
  );
  if (rot) {
    // A dark choke-coloured blemish so an overflowed spud reads as spoiled.
    canvas.drawCircle(
        const Offset(1.5, 0.5), rx * 0.5, Paint()..color = _kChoke.withValues(alpha: 0.85));
  }
  canvas.restore();
}

void _legIcon(Canvas canvas, IconData icon, Offset center, double sz, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: sz,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

void _legText(Canvas canvas, String text, Offset at,
    {required double size, required Color color, bool bold = true}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: size,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        letterSpacing: 0.4,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, at + Offset(-tp.width / 2, -tp.height / 2));
}

/// One stage bin: buffer body, coloured fill with surface potatoes, and a
/// border whose colour tells the story (green ok → orange filling → red choke).
void _legBin(Canvas canvas, Rect rect,
    {required double fill, required Color border, bool choke = false}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
  canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.28));
  final fillH = rect.height * fill.clamp(0.0, 1.0);
  if (fillH > 2) {
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - fillH, rect.width, fillH),
      Paint()..color = border.withValues(alpha: 0.22),
    );
    final n = (fill * 5).ceil().clamp(0, 5);
    for (var k = 0; k < n; k++) {
      final px = rect.left + rect.width * (0.24 + 0.52 * ((k * 0.37) % 1));
      final py = rect.bottom - fillH + 7 + (k % 2) * 7;
      _legPotato(canvas, Offset(px, py), 6, 4.2);
    }
    canvas.restore();
  }
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = choke ? 2.4 : 1.4
      ..color = border.withValues(alpha: choke ? 1.0 : 0.55),
  );
}

/// Frame 1 — the line: potatoes ride the belt out the SHIP end, which scores.
void _legendChain(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 1 || h <= 1) return;
  final beltY = h * 0.44;
  final belt = RRect.fromRectAndRadius(
    Rect.fromLTWH(w * 0.05, beltY - 9, w * 0.72, 18),
    const Radius.circular(9),
  );
  canvas.drawRRect(belt, Paint()..color = _kBelt);
  canvas.drawRRect(
    belt,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _kBeltEdge,
  );
  for (var k = 0; k < 6; k++) {
    _legPotato(canvas, Offset(w * 0.10 + k * (w * 0.63 / 6), beltY), 6.5, 4.5);
  }
  final ex = Offset(w * 0.88, beltY);
  canvas.drawCircle(
    ex,
    18,
    Paint()
      ..color = _kShip.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  _legIcon(canvas, Icons.local_shipping, ex, 22, _kShip);
  _legText(canvas, 'SHIP', Offset(ex.dx, beltY + 26), size: 10, color: _kShip);
  _legText(canvas, '+3', Offset(ex.dx, beltY - 30), size: 16, color: _kShip);
}

/// Frame 2 — the verb: tap the red BOTTLENECK bin to boost that stage.
void _legendBoost(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 1 || h <= 1) return;
  final cx = w * 0.5;
  _legIcon(canvas, Icons.settings, Offset(cx, h * 0.15), 20, _kChoke);
  _legText(canvas, 'PROCESS', Offset(cx, h * 0.27), size: 11, color: _kChoke);
  _legText(canvas, 'BOTTLENECK', Offset(cx, h * 0.36), size: 9, color: _kChoke);
  _legBin(canvas, Rect.fromCenter(center: Offset(cx, h * 0.58), width: w * 0.30, height: h * 0.34),
      fill: 0.85, border: _kChoke, choke: true);
  final pill = Rect.fromCenter(center: Offset(cx, h * 0.86), width: w * 0.38, height: 20);
  canvas.drawRRect(
    RRect.fromRectAndRadius(pill, const Radius.circular(10)),
    Paint()..color = _kShip.withValues(alpha: 0.25),
  );
  _legText(canvas, 'TAP TO BOOST', Offset(cx, h * 0.86), size: 10, color: _kShip);
}

/// Frame 3 — the danger: a full bin overflows and the spilled spuds rot.
void _legendOverflow(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 1 || h <= 1) return;
  final cx = w * 0.5;
  _legText(canvas, 'OVERFLOW', Offset(cx, h * 0.14), size: 12, color: _kChoke);
  final rect = Rect.fromCenter(center: Offset(cx, h * 0.56), width: w * 0.30, height: h * 0.34);
  _legBin(canvas, rect, fill: 1.0, border: _kChoke, choke: true);
  // Spilled potatoes rotting above the rim.
  for (var k = 0; k < 3; k++) {
    _legPotato(canvas, Offset(rect.left + rect.width * (0.28 + 0.22 * k), rect.top - 4), 6, 4.2,
        rot: true);
  }
  _legText(canvas, 'ROT · WASTED', Offset(cx, h * 0.88), size: 10, color: _kWarn);
}

/// Frame 4 — the escalation: late round, two stages choke at once.
void _legendDoubleChoke(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 1 || h <= 1) return;
  const names = ['WASH', 'STORE'];
  const icons = [Icons.water_drop, Icons.warehouse];
  final xs = [w * 0.30, w * 0.70];
  for (var i = 0; i < 2; i++) {
    final cx = xs[i];
    _legIcon(canvas, icons[i], Offset(cx, h * 0.18), 18, _kChoke);
    _legText(canvas, names[i], Offset(cx, h * 0.30), size: 10, color: _kChoke);
    _legBin(canvas, Rect.fromCenter(center: Offset(cx, h * 0.60), width: w * 0.26, height: h * 0.34),
        fill: 0.82, border: _kChoke, choke: true);
  }
  _legText(canvas, 'TWO CHOKES', Offset(w * 0.5, h * 0.90), size: 11, color: _kChoke);
}

/// The visual manual for Bottleneck — wired into the registry spec.
final List<LegendFrame> bottleneckLegendFrames = [
  const LegendFrame(
      caption: 'Potatoes ride the line — shipping them out the end scores',
      paint: _legendChain),
  const LegendFrame(
      caption: 'Tap the red BOTTLENECK bin to BOOST that stage',
      paint: _legendBoost),
  const LegendFrame(
      caption: 'Let a bin fill and it OVERFLOWS — spuds rot, wasted',
      paint: _legendOverflow),
  const LegendFrame(
      caption: 'Late on, TWO stages choke at once — triage your boosts',
      paint: _legendDoubleChoke),
];
