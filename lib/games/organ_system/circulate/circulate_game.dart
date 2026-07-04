import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Circulate — body-wide oxygen DELIVERY on the organ-system scale.
///
/// The heart pumps a reserve of bright-red **oxygenated** blood. The player
/// ROUTES that blood out along the **arteries** to organs that are flashing
/// "LOW O₂", delivering oxygen before the organ suffers (the **systemic** loop:
/// heart → arteries → organs). Each delivery spends oxygen, so the blood at the
/// heart darkens toward **deoxygenated** blue. To recharge, the player routes
/// that blue blood back to the **lungs** (the **pulmonary** loop: organs →
/// veins → heart → lungs), where it reloads with O₂ and the reserve turns red
/// again. The skill is balancing delivery against recharge while organ demand
/// climbs — run the reserve dry and the organs starve.
///
/// Distinct from the heart-chamber game "Heartbeat": this is whole-body
/// delivery, not a single beat.
///
/// The host ([MiniGameHost]) owns the timer, 3·2·1 countdown, score HUD and
/// results; this widget renders ONLY the play area. Everything — vessels,
/// flowing blood pulses and organ gauges — is drawn by ONE [CustomPainter]
/// driven by ONE `days:1` ticker, with no per-frame setState over a big tree.
class CirculateGame extends StatefulWidget {
  final MiniGameSession session;
  const CirculateGame({super.key, required this.session});

  @override
  State<CirculateGame> createState() => _CirculateGameState();
}

// ── Palette ────────────────────────────────────────────────────────────────
const Color _accent = Color(0xFFE5384B); // arterial crimson — oxygenated blood
const Color _oxy = Color(0xFFFF5566); // bright oxygenated red
const Color _deoxy = Color(0xFF4A7DC4); // deoxygenated blue
const Color _good = Color(0xFF66E08A); // healthy organ green
const Color _danger = Color(0xFFE5533D); // suffering / empty red

/// A body organ fed by an artery from the heart. [o2] drains over time; route
/// oxygenated blood to it to top it back up before it flatlines.
class _Organ {
  final String name;
  final Offset pos; // normalised 0..1 within the play area
  final double drain; // O₂ lost per second
  double o2; // 0..1 oxygen level
  double flash = 0; // delivery / tap feedback, 1 → 0
  bool suffering = false; // latched while o2 == 0
  double pulse = 0; // animates the low-O₂ alarm glow

  _Organ(this.name, this.pos, this.drain, {this.o2 = 0.8});
}

/// A travelling blob of blood routed along a vessel. [target] == -1 means the
/// lungs (recharge); otherwise it is an organ index (delivery).
class _Pulse {
  final int target;
  final bool oxygenated; // red arterial (delivery) vs blue venous (recharge)
  double progress = 0; // 0..1 along heart → target
  _Pulse(this.target, this.oxygenated);
}

class _CirculateGameState extends State<CirculateGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Fixed anatomy (normalised) ──
  static const Offset _heart = Offset(0.20, 0.54);
  static const Offset _lungs = Offset(0.20, 0.22);

  // ── Tunables ──
  static const double _deliverAmt = 0.55; // O₂ a delivery restores
  static const double _deliverCost = 0.34; // reserve spent per delivery
  static const double _rechargeAdd = 0.72; // reserve a lung recharge reloads
  static const double _pulseSpeed = 2.3; // progress/sec (~0.43s travel)
  static const double _lowO2 = 0.34; // below this an organ flashes "LOW O₂"

  // ── Sim state ──
  late List<_Organ> _organs;
  final List<_Pulse> _pulses = [];
  double _reserve = 1.0; // 0..1 oxygenated blood at the heart
  int _streak = 0; // consecutive deliveries without a flatline
  double _clock = 0;
  double _lastT = 0;
  double _nextOrgan = 12.0; // _clock at which the next organ is added
  bool _started = false;

  double _heartBeat = 0; // heartbeat phase for the pumping animation
  double _reserveFlash = 0; // pulse when a recharge lands, 1 → 0
  double _lowFlash = 0; // "RECHARGE AT LUNGS" alert, 1 → 0

  String _banner = '';
  double _bannerLife = 0;
  Color _bannerColor = _good;

  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _w = 1, _h = 1;

  @override
  void initState() {
    super.initState();
    _organs = _buildOrgans(3);
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    // ATTRACT autopilot: this game knows how to circulate for itself. The host
    // only calls this in autoplay; dormant during normal hands-on play. See
    // [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One correct routing move per host tick (~250ms), driven off the game's OWN
  /// state and handlers — no synthetic taps, no randomness. Policy that plays
  /// the systemic/pulmonary balance well:
  ///   1. If the reserve can't fund the next delivery, route blue blood to the
  ///      lungs to recharge ([_routeRecharge]).
  ///   2. Otherwise deliver oxygenated blood to the neediest low organ
  ///      ([_routeDelivery]) — always the correct destination, never a full one.
  ///   3. If every organ is comfortable, keep the reserve topped for the coming
  ///      drain (recharge only while it isn't already full/inbound).
  /// In-flight recharge pulses are counted so it never over-queues the lungs.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // Recharge O₂ already inbound but not yet landed at the heart.
    var inFlightRecharge = 0;
    for (final p in _pulses) {
      if (p.target < 0) inFlightRecharge++;
    }
    final projReserve = _reserve + inFlightRecharge * _rechargeAdd;

    // Neediest organ (lowest O₂) — the correct delivery target.
    int neediest = -1;
    var lowO2 = 2.0;
    for (var i = 0; i < _organs.length; i++) {
      if (_organs[i].o2 < lowO2) {
        lowO2 = _organs[i].o2;
        neediest = i;
      }
    }

    // 1. Can't afford a delivery → recharge at the lungs (unless already full).
    if (_reserve < _deliverCost) {
      if (projReserve < 0.985) _routeRecharge();
      return;
    }

    // 2. Deliver to the neediest organ while it genuinely needs oxygen.
    if (neediest >= 0 && lowO2 < 0.6) {
      _routeDelivery(neediest);
      return;
    }

    // 3. Everyone comfortable → keep the reserve topped for the coming drain.
    if (projReserve < 0.985) _routeRecharge();
  }

  // Real organs of the systemic circuit, ordered by how soon they're added.
  static const List<List<dynamic>> _organSpecs = [
    ['Brain', Offset(0.58, 0.16), 0.075],
    ['Liver', Offset(0.78, 0.40), 0.060],
    ['Muscle', Offset(0.62, 0.82), 0.065],
    ['Kidney', Offset(0.86, 0.62), 0.058],
    ['Stomach', Offset(0.50, 0.50), 0.052],
    ['Limbs', Offset(0.88, 0.86), 0.070],
  ];

  List<_Organ> _buildOrgans(int n) {
    return [
      for (var i = 0; i < n && i < _organSpecs.length; i++)
        _Organ(
          _organSpecs[i][0] as String,
          _organSpecs[i][1] as Offset,
          _organSpecs[i][2] as double,
        ),
    ];
  }

  void _resetSim() {
    _clock = 0;
    _reserve = 1.0;
    _streak = 0;
    _nextOrgan = 12.0;
    _reserveFlash = 0;
    _lowFlash = 0;
    _banner = '';
    _bannerLife = 0;
    _pulses.clear();
    _fx.clear();
    _pops.clear();
    _organs = _buildOrgans(3);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── The single ticker ──
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX + heartbeat animate even during the calm ready state.
    _heartBeat += dt;
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_bannerLife > 0) _bannerLife -= dt;
    if (_reserveFlash > 0) _reserveFlash = (_reserveFlash - dt * 2.0).clamp(0.0, 1.0);
    if (_lowFlash > 0) _lowFlash = (_lowFlash - dt * 1.6).clamp(0.0, 1.0);
    for (final o in _organs) {
      if (o.flash > 0) o.flash = (o.flash - dt * 1.8).clamp(0.0, 1.0);
      o.pulse += dt;
    }
    // Pulses always travel so a delivery in flight at time-up still lands.
    _advancePulses(dt);

    final running = widget.session.isRunning;
    if (!running) {
      if (widget.session.phase == MiniGamePhase.intro) _started = false;
      return;
    }
    if (!_started) {
      _resetSim();
      _started = true;
    }
    _simulate(dt);
  }

  void _advancePulses(double dt) {
    for (var i = _pulses.length - 1; i >= 0; i--) {
      final p = _pulses[i];
      p.progress += _pulseSpeed * dt;
      if (p.progress >= 1.0) {
        _pulses.removeAt(i);
        _land(p);
      }
    }
  }

  void _land(_Pulse p) {
    if (p.target < 0) {
      // Pulmonary loop: blood reloads with O₂ at the lungs → reserve reddens.
      _reserve = (_reserve + _rechargeAdd).clamp(0.0, 1.0);
      _reserveFlash = 1.0;
      _fx.addAll(FxBurst.spawn(_px(_lungs), _oxy, count: 12, speed: 110));
      _setBanner('Recharged — O₂ reloaded', _oxy);
    } else if (p.target < _organs.length) {
      // Systemic loop: O₂ delivered to the organ; reward rescuing a low one.
      final o = _organs[p.target];
      final before = o.o2;
      o.o2 = (o.o2 + _deliverAmt).clamp(0.0, 1.0);
      o.flash = 1.0;
      if (o.suffering && o.o2 > 0.05) o.suffering = false;
      final points = 6 + ((1.0 - before).clamp(0.0, 1.0) * 18).round();
      if (widget.session.isRunning) {
        widget.session.addScore(points);
        _streak += 1;
        widget.session.noteStreak(_streak);
      }
      final at = _px(o.pos);
      _fx.addAll(FxBurst.spawn(at, _good, count: 10, speed: 100));
      _pops.add(FxPop(at.translate(0, -10), '+$points', _good));
    }
  }

  void _simulate(double dt) {
    _clock += dt;

    // Organs burn oxygen; demand climbs through the round.
    final demand = _lerp(1.0, 1.9, (_clock / 50).clamp(0.0, 1.0));
    for (final o in _organs) {
      o.o2 = (o.o2 - o.drain * demand * dt).clamp(0.0, 1.0);
      if (o.o2 <= 0.0 && !o.suffering) {
        o.suffering = true;
        _streak = 0;
        _setBanner('${o.name} starved — O₂ gone!', _danger);
        _fx.addAll(FxBurst.spawn(_px(o.pos), _danger, count: 10, speed: 90));
      }
    }

    // Add organs over time — more of the body to keep perfused.
    if (_clock >= _nextOrgan && _organs.length < _organSpecs.length) {
      final next = _organSpecs[_organs.length];
      _organs.add(_Organ(next[0] as String, next[1] as Offset,
          next[2] as double,
          o2: 0.7));
      _setBanner('New demand: ${next[0]}', Potatuhs.sienna);
      _nextOrgan = _clock + 12.0;
    }
  }

  void _setBanner(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerLife = 1.6;
  }

  // ── Interaction: route blood by tapping a node ──
  void _onTap(Offset norm) {
    if (!widget.session.isRunning) return;
    // Lungs first (recharge), then organs (deliver) — nearest within reach.
    if ((_lungs - norm).distance < 0.12) {
      _routeRecharge();
      return;
    }
    int? hit;
    var best = 0.13;
    for (var i = 0; i < _organs.length; i++) {
      final d = (_organs[i].pos - norm).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit != null) _routeDelivery(hit);
  }

  void _routeRecharge() {
    if (_reserve >= 0.985) {
      _setBanner('Reserve already full', _good);
      return;
    }
    _pulses.add(_Pulse(-1, false)); // blue blood heart → lungs
    _fx.addAll(FxBurst.spawn(_px(_heart), _deoxy, count: 6, speed: 70));
  }

  void _routeDelivery(int i) {
    if (_reserve < _deliverCost) {
      _lowFlash = 1.0;
      _setBanner('Out of O₂ — recharge at the lungs', _danger);
      _fx.addAll(FxBurst.spawn(_px(_organs[i].pos), _danger, count: 5, speed: 60));
      return;
    }
    _reserve -= _deliverCost; // oxygen spent → heart blood darkens to blue
    _organs[i].flash = 0.6;
    _pulses.add(_Pulse(i, true)); // red oxygenated blood heart → organ
    _fx.addAll(FxBurst.spawn(_px(_heart), _oxy, count: 5, speed: 70));
  }

  Offset _px(Offset norm) => Offset(norm.dx * _w, norm.dy * _h);

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      Offset toNorm(Offset local) => Offset(local.dx / _w, local.dy / _h);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTap(toNorm(d.localPosition)),
        child: CustomPaint(
          painter: _CirculatePainter(repaint: _ctrl, state: this),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

class _CirculatePainter extends CustomPainter {
  final _CirculateGameState s;
  _CirculatePainter({required Listenable repaint, required _CirculateGameState state})
      : s = state,
        super(repaint: repaint);

  bool get running => s.widget.session.isRunning;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset px(Offset n) => Offset(n.dx * w, n.dy * h);

    GameFx.atmosphere(canvas, size, _accent, s._heartBeat, motes: 24);

    final heartPx = px(_CirculateGameState._heart);
    final lungsPx = px(_CirculateGameState._lungs);

    // ── Arteries to each organ (under the nodes) ──
    for (var i = 0; i < s._organs.length; i++) {
      final o = s._organs[i];
      final a = px(o.pos);
      final low = o.o2 < _CirculateGameState._lowO2;
      canvas.drawLine(
        heartPx,
        a,
        Paint()
          ..color = (low ? _danger : _oxy)
              .withValues(alpha: low ? 0.30 : 0.16)
          ..strokeWidth = 2,
      );
    }
    // ── Pulmonary vessel heart ↔ lungs ──
    canvas.drawLine(
      heartPx,
      lungsPx,
      Paint()
        ..color = _deoxy.withValues(alpha: 0.30)
        ..strokeWidth = 2.5,
    );

    // ── Blood pulses travelling the vessels ──
    for (final p in s._pulses) {
      final to = p.target < 0
          ? lungsPx
          : (p.target < s._organs.length ? px(s._organs[p.target].pos) : heartPx);
      final pos = Offset.lerp(heartPx, to, p.progress)!;
      final col = p.oxygenated ? _oxy : _deoxy;
      canvas.drawCircle(pos, 7,
          Paint()..color = col.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(pos, 4.5, Paint()..color = col);
    }

    // ── Lungs ──
    final lungGlow = 0.6 + 0.4 * s._reserveFlash;
    GameFx.orb(canvas, lungsPx, 20, _deoxy, glow: lungGlow);
    GameFx.text(canvas, 'LUNGS', lungsPx.translate(0, -30), 10,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
    GameFx.text(canvas, 'tap to recharge', lungsPx.translate(0, 32), 8.5,
        Colors.white.withValues(alpha: 0.45));

    // ── Heart (pumping; colour reflects oxygen reserve red↔blue) ──
    final beat = 0.5 + 0.5 * math.sin(s._heartBeat * 5.0);
    final bloodCol = Color.lerp(_deoxy, _oxy, s._reserve)!;
    final r = 26.0 + beat * 3.5 + s._reserveFlash * 3;
    GameFx.orb(canvas, heartPx, r, bloodCol, glow: 0.9 + s._reserveFlash * 0.5);
    GameFx.text(canvas, 'HEART', heartPx.translate(0, r + 12), 10,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);

    // Reserve gauge (oxygenated blood available) — a bar beside the heart.
    _drawReserve(canvas, heartPx, r);

    // ── Organs ──
    for (var i = 0; i < s._organs.length; i++) {
      _drawOrgan(canvas, px(s._organs[i].pos), s._organs[i]);
    }

    // ── Ready hint ──
    if (!running) {
      GameFx.text(
        canvas,
        'Route red blood to low organs — recharge blue at the lungs',
        Offset(w / 2, h - 22),
        12.5,
        Colors.white.withValues(alpha: 0.62),
      );
    }

    // ── Low-reserve alert ──
    if (s._lowFlash > 0) {
      GameFx.text(canvas, 'RECHARGE AT THE LUNGS',
          Offset(w / 2, h * 0.90), 15,
          _danger.withValues(alpha: s._lowFlash.clamp(0.0, 1.0)),
          weight: FontWeight.w800, glow: 0.6 * s._lowFlash);
    }

    // ── Banner ──
    if (s._bannerLife > 0) {
      final a = (s._bannerLife / 1.6).clamp(0.0, 1.0);
      GameFx.text(canvas, s._banner, Offset(w / 2, h * 0.07), 15,
          s._bannerColor.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.5 * a);
    }

    // ── Juice ──
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  void _drawReserve(Canvas canvas, Offset heart, double r) {
    final barH = 60.0, barW = 11.0;
    final left = heart.dx - r - 22;
    final top = heart.dy - barH / 2;
    final track = Rect.fromLTWH(left, top, barW, barH);
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.4));
    final fillH = barH * s._reserve.clamp(0.0, 1.0);
    final fillCol = s._reserve < 0.34 ? _danger : _oxy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top + (barH - fillH), barW, fillH),
          const Radius.circular(6)),
      Paint()..color = fillCol,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    GameFx.text(canvas, 'O₂', Offset(left + barW / 2, top - 9), 9,
        Colors.white.withValues(alpha: 0.6), weight: FontWeight.w800);
  }

  void _drawOrgan(Canvas canvas, Offset c, _Organ o) {
    final low = o.o2 < _CirculateGameState._lowO2;
    final alarm = low ? (0.5 + 0.5 * math.sin(o.pulse * 6.0)).abs() : 0.0;
    final base = o.suffering
        ? _danger
        : Color.lerp(_danger, _good, o.o2.clamp(0.0, 1.0))!;
    final rr = 17.0 + o.flash * 4 + alarm * 2;

    // Low-O₂ alarm halo.
    if (low && running) {
      canvas.drawCircle(
        c,
        rr + 8 + alarm * 4,
        Paint()..color = _danger.withValues(alpha: 0.12 + alarm * 0.16),
      );
    }
    GameFx.orb(canvas, c, rr, base, glow: low ? 0.5 + alarm * 0.5 : 0.5);

    // O₂ ring gauge.
    final sweep = o.o2.clamp(0.0, 1.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rr + 4),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = (low ? _danger : _good).withValues(alpha: 0.85),
    );

    GameFx.text(canvas, o.name, c.translate(0, rr + 13), 9.5,
        Colors.white.withValues(alpha: 0.80), weight: FontWeight.w700);
    if (low && running) {
      GameFx.text(canvas, o.suffering ? 'STARVED' : 'LOW O₂',
          c.translate(0, rr + 25), 8.5,
          _danger.withValues(alpha: 0.6 + 0.4 * alarm), weight: FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(covariant _CirculatePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components the
// live [_CirculatePainter] renders (heart, lungs, organ + O₂ ring, blood pulse)
// so the manual shows the EXACT anatomy the player meets. Static and cheap.
// ═══════════════════════════════════════════════════════════════════════════

void _mHeart(Canvas canvas, Offset c, double reserve, double r) {
  final bloodCol = Color.lerp(_deoxy, _oxy, reserve.clamp(0.0, 1.0))!;
  GameFx.orb(canvas, c, r, bloodCol, glow: 0.9);
  GameFx.text(canvas, 'HEART', c.translate(0, r + 12), 10,
      Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
}

void _mLungs(Canvas canvas, Offset c, double r) {
  GameFx.orb(canvas, c, r, _deoxy, glow: 0.7);
  GameFx.text(canvas, 'LUNGS', c.translate(0, -r - 12), 10,
      Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
}

void _mOrgan(Canvas canvas, Offset c, double o2, String label,
    {double rr = 17, bool alarm = false}) {
  final low = o2 < _CirculateGameState._lowO2;
  final base = o2 <= 0.0
      ? _danger
      : Color.lerp(_danger, _good, o2.clamp(0.0, 1.0))!;
  if (low) {
    canvas.drawCircle(c, rr + 10 + (alarm ? 3 : 0),
        Paint()..color = _danger.withValues(alpha: 0.18));
  }
  GameFx.orb(canvas, c, rr, base, glow: low ? 0.75 : 0.5);
  final sweep = o2.clamp(0.0, 1.0) * 2 * math.pi;
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: rr + 4),
    -math.pi / 2,
    sweep,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = (low ? _danger : _good).withValues(alpha: 0.85),
  );
  GameFx.text(canvas, label, c.translate(0, rr + 13), 9.5,
      Colors.white.withValues(alpha: 0.80), weight: FontWeight.w700);
  if (low) {
    GameFx.text(canvas, o2 <= 0.0 ? 'STARVED' : 'LOW O₂',
        c.translate(0, rr + 25), 8.5,
        _danger.withValues(alpha: 0.9), weight: FontWeight.w800);
  }
}

void _mArtery(Canvas canvas, Offset from, Offset to, {bool low = false}) {
  canvas.drawLine(
    from,
    to,
    Paint()
      ..color = (low ? _danger : _oxy).withValues(alpha: low ? 0.30 : 0.16)
      ..strokeWidth = 2,
  );
}

void _mPulse(Canvas canvas, Offset pos, bool oxygenated) {
  final col = oxygenated ? _oxy : _deoxy;
  canvas.drawCircle(
      pos,
      7,
      Paint()
        ..color = col.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  canvas.drawCircle(pos, 4.5, Paint()..color = col);
}

void _mReserveBar(Canvas canvas, Offset heart, double r, double reserve) {
  const barH = 60.0, barW = 11.0;
  final left = heart.dx - r - 22;
  final top = heart.dy - barH / 2;
  final track = Rect.fromLTWH(left, top, barW, barH);
  final rrect = RRect.fromRectAndRadius(track, const Radius.circular(6));
  canvas.drawRRect(rrect, Paint()..color = Colors.black.withValues(alpha: 0.4));
  final fillH = barH * reserve.clamp(0.0, 1.0);
  final fillCol = reserve < 0.34 ? _danger : _oxy;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top + (barH - fillH), barW, fillH),
        const Radius.circular(6)),
    Paint()..color = fillCol,
  );
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.25),
  );
  GameFx.text(canvas, 'O₂', Offset(left + barW / 2, top - 9), 9,
      Colors.white.withValues(alpha: 0.6), weight: FontWeight.w800);
}

/// Frame 1 — the core verb: route red blood from the heart out to a low organ.
void _legendDeliver(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final heart = Offset(w * 0.24, h * 0.52);
  final organ = Offset(w * 0.74, h * 0.38);
  _mArtery(canvas, heart, organ, low: true);
  _mPulse(canvas, Offset.lerp(heart, organ, 0.5)!, true);
  _mHeart(canvas, heart, 0.9, 26);
  _mOrgan(canvas, organ, 0.18, 'Brain', alarm: true);
}

/// Frame 2 — scoring: the emptier the organ you rescue, the bigger the payoff.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final low = Offset(w * 0.31, h * 0.50);
  final full = Offset(w * 0.71, h * 0.50);
  _mOrgan(canvas, low, 0.06, 'Muscle', rr: 18, alarm: true);
  _mOrgan(canvas, full, 0.72, 'Liver', rr: 18);
  GameFx.text(canvas, '+24', low.translate(0, -34), 16, _good,
      weight: FontWeight.w800, glow: 0.5);
  GameFx.text(canvas, '+6', full.translate(0, -34), 13,
      _good.withValues(alpha: 0.7), weight: FontWeight.w800);
}

/// Frame 3 — the recharge loop: a blue reserve must go back to the lungs.
void _legendRecharge(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final heart = Offset(w * 0.44, h * 0.62);
  final lungs = Offset(w * 0.44, h * 0.22);
  canvas.drawLine(
    heart,
    lungs,
    Paint()
      ..color = _deoxy.withValues(alpha: 0.30)
      ..strokeWidth = 2.5,
  );
  _mPulse(canvas, Offset.lerp(heart, lungs, 0.5)!, false);
  _mLungs(canvas, lungs, 20);
  _mHeart(canvas, heart, 0.08, 26);
  _mReserveBar(canvas, heart, 26, 0.08);
}

/// Frame 4 — escalation: more organs join and demand climbs; keep them all fed.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final heart = Offset(w * 0.5, h * 0.5);
  const specs = [
    [0.20, 0.20, 0.10],
    [0.82, 0.24, 0.05],
    [0.86, 0.72, 0.14],
    [0.22, 0.78, 0.08],
    [0.60, 0.86, 0.55],
  ];
  const names = ['Brain', 'Liver', 'Kidney', 'Muscle', 'Limbs'];
  for (var i = 0; i < specs.length; i++) {
    final o = Offset(w * specs[i][0], h * specs[i][1]);
    _mArtery(canvas, heart, o, low: specs[i][2] < 0.34);
  }
  _mHeart(canvas, heart, 0.5, 24);
  for (var i = 0; i < specs.length; i++) {
    final o = Offset(w * specs[i][0], h * specs[i][1]);
    _mOrgan(canvas, o, specs[i][2], names[i], rr: 13, alarm: specs[i][2] < 0.34);
  }
}

/// The visual manual for Circulate — wired into the registry spec.
final List<LegendFrame> circulateLegendFrames = [
  const LegendFrame(
      caption: 'Tap a low organ to route red blood from the heart',
      paint: _legendDeliver),
  const LegendFrame(
      caption: 'Rescue near-empty organs for up to +24',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Reserve runs blue? Tap the lungs to recharge O₂',
      paint: _legendRecharge),
  const LegendFrame(
      caption: 'More organs join, demand climbs — deliver faster',
      paint: _legendEscalate),
];
