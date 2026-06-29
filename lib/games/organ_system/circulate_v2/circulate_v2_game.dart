import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Circulate v2 ══════════════════════════════════════════════════════════
/// Body-wide oxygen delivery on the organ-system scale. The heart holds a
/// COUNTABLE reserve of oxygen charges. You ROUTE charges out along the
/// arteries to organs flashing "LOW O₂" (the **systemic** loop:
/// heart → arteries → organs), and you RECHARGE that reserve at the lungs (the
/// **pulmonary** loop: organs → veins → heart → lungs). You cannot deliver
/// oxygen you do not have — so the deliver↔recharge coupling is the game.
///
/// What changed vs v1 (the UX-pass brief — see teardowns/circulate.md):
///   • The hidden reserve economy is now the HERO read. v1 spent a tiny,
///     continuous "reserve" bar that you only noticed when it hit empty. v2
///     DISCRETIZES the reserve into a row of countable O₂ charges right on the
///     heart: "3 / 5". Each delivery visibly spends ONE charge and pops "−1".
///     You watch the loop tighten and learn "I must recharge" by ANTICIPATION,
///     not by failing.
///   • The two actions are sharpened. DELIVER = tap a low organ (red arterial
///     pulse out). RECHARGE = tap the lungs, now a big, persistent, clearly
///     labelled REFUEL node with its own prompt that lights up before you run
///     dry. Distinct colour language: red goes out, blue comes back.
///   • A real climax: the final seconds become a CODE RED surge — demand
///     spikes, organs crash faster, and every delivery scores ×2. The host owns
///     the shared clock, so the surge hits all players equally (no runaway).
///   • Kept from v1 (the teardown's "Keep"): the literal two-loop lesson, the
///     red↔blue oxygenation colour on the heart, rescue-scaled scoring (lower
///     organ = more points = triage), and the no-early-end fairness (a starved
///     organ never ends the run; it can be revived).
///
/// The host ([MiniGameHost]) owns the timer, 3·2·1 countdown, score HUD and
/// results; this widget renders ONLY the play area. Everything — vessels,
/// flowing blood, the charge magazine and organ gauges — is drawn by ONE
/// [CustomPainter] driven by ONE `days:1` ticker, with no per-frame setState.

// ── Palette ────────────────────────────────────────────────────────────────
const Color _accent = Color(0xFFE5384B); // arterial crimson
const Color _oxy = Color(0xFFFF5566); // bright oxygenated red
const Color _deoxy = Color(0xFF4A7DC4); // deoxygenated blue
const Color _good = Color(0xFF66E08A); // healthy organ green
const Color _danger = Color(0xFFE5533D); // suffering / empty red

// ── Education: surfaced as the run plays ────────────────────────────────────
const List<String> _kFacts = [
  'Systemic loop: the heart pumps oxygen-rich RED blood out to every organ.',
  'Pulmonary loop: oxygen-poor BLUE blood returns, and reloads O₂ at the lungs.',
  'You cannot deliver oxygen you do not have — every delivery spends a charge.',
  'Red blood is oxygenated; blue blood has handed its oxygen to the organs.',
  'The lungs are the ONLY place blood reloads oxygen — the recharge half of the loop.',
  'Starved of oxygen, an organ fails — the brain lasts only minutes without it.',
  'Your heart beats ~100,000 times a day, never pausing the two-loop circuit.',
  'A potato has no heart, but moves water and sugar through xylem and phloem.',
];

/// A body organ fed by an artery from the heart. [o2] drains over time; deliver
/// an oxygen charge to top it back up before it flatlines.
class _Organ {
  final String name;
  final Offset pos; // normalised 0..1 within the play area
  final double drain; // O₂ lost per second
  double o2; // 0..1 oxygen level
  double flash = 0; // delivery feedback, 1 → 0
  bool suffering = false; // latched while o2 == 0
  double pulse = 0; // animates the low-O₂ alarm glow

  _Organ(this.name, this.pos, this.drain, {this.o2 = 0.8});
}

/// A travelling blob of blood. [target] == -1 means the lungs (recharge);
/// otherwise it is an organ index (delivery).
class _Pulse {
  final int target;
  final bool oxygenated; // red arterial (delivery) vs blue venous (recharge)
  double progress = 0; // 0..1 along heart → target
  _Pulse(this.target, this.oxygenated);
}

/// A floating "+N" / "−1" label, laid out ONCE at spawn (never re-shaped).
class _Pop {
  double x, y;
  double life = 1.0;
  final TextPainter tp;
  _Pop({required this.x, required this.y, required String label, required Color color})
      : tp = (TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout());
}

class CirculateV2Game extends StatefulWidget {
  final MiniGameSession session;
  const CirculateV2Game({super.key, required this.session});

  @override
  State<CirculateV2Game> createState() => _CirculateV2GameState();
}

class _CirculateV2GameState extends State<CirculateV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Fixed anatomy (normalised) ──
  static const Offset _heart = Offset(0.22, 0.56);
  static const Offset _lungs = Offset(0.22, 0.20);

  // ── Tunables ──
  /// The reserve is a COUNTABLE magazine of oxygen charges — the hero read.
  static const int _chargeCap = 5;
  static const double _deliverAmt = 0.62; // O₂ a delivery restores to an organ
  static const double _pulseSpeed = 2.5; // progress/sec (~0.4s travel)
  static const double _lowO2 = 0.34; // below this an organ flashes "LOW O₂"
  static const double _rechargePrompt = 2; // charges at/below which lungs nag

  static const double _addOrganEvery = 11.0;
  static const double _demandStart = 1.0;
  static const double _demandEnd = 2.0;

  /// The CODE RED climax: final seconds, demand spikes, scoring doubles.
  static const double _surgeWindow = 12.0;
  static const int _surgeMult = 2;
  static const double _surgeDrainMult = 1.6;
  static const double _surgeDemandKick = 0.6;

  static const int _maxParticles = 60;
  static const int _maxPops = 6;

  // ── Sim state ──
  late List<_Organ> _organs;
  final List<_Pulse> _pulses = [];
  int _charges = _chargeCap; // oxygen charges at the heart (the reserve)
  bool _recharging = false; // a pulmonary recharge pulse is in flight
  int _streak = 0; // consecutive deliveries without a flatline
  double _clock = 0; // ever-advancing seconds (idle/heartbeat)
  double _lastT = 0;
  double _runElapsed = 0; // seconds inside the active run
  double _nextOrgan = _addOrganEvery;
  bool _wasRunning = false;
  bool _surge = false;

  double _heartBeat = 0; // heartbeat phase for the pumping animation
  double _reserveFlash = 0; // pulse when a recharge lands, 1 → 0
  double _emptyFlash = 0; // "OUT OF O₂" alert, 1 → 0

  String _banner = '';
  double _bannerLife = 0;
  Color _bannerColor = _good;

  String _fact = _kFacts.first;
  int _lastFact = 0;
  double _factTimer = 0;

  final List<FxParticle> _fx = [];
  final List<_Pop> _pops = [];
  double _w = 1, _h = 1;

  @override
  void initState() {
    super.initState();
    _fact = _kFacts[_nextFact()];
    _organs = _buildOrgans(3);
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Real organs of the systemic circuit, ordered by how soon they appear.
  static const List<List<dynamic>> _organSpecs = [
    ['Brain', Offset(0.60, 0.16), 0.075],
    ['Liver', Offset(0.80, 0.40), 0.060],
    ['Muscle', Offset(0.64, 0.82), 0.066],
    ['Kidney', Offset(0.88, 0.62), 0.058],
    ['Stomach', Offset(0.52, 0.50), 0.052],
    ['Limbs', Offset(0.90, 0.86), 0.072],
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

  void _resetRun() {
    _runElapsed = 0;
    _charges = _chargeCap;
    _recharging = false;
    _streak = 0;
    _nextOrgan = _addOrganEvery;
    _surge = false;
    _reserveFlash = 0;
    _emptyFlash = 0;
    _banner = '';
    _bannerLife = 0;
    _factTimer = 0;
    _pulses.clear();
    _fx.clear();
    _pops.clear();
    _organs = _buildOrgans(3);
  }

  int _nextFact() {
    if (_kFacts.length <= 1) return 0;
    int idx;
    do {
      idx = _rng.nextInt(_kFacts.length);
    } while (idx == _lastFact);
    _lastFact = idx;
    return idx;
  }

  double get _dur {
    final d = widget.session.spec.durationSeconds;
    return d <= 0 ? 55.0 : d.toDouble();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── The single ticker ──
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX + heartbeat animate even during the calm ready state.
    _heartBeat += dt;
    _clock += dt;
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) {
      for (final p in _pops) {
        p.y -= 60 * dt;
        p.life -= dt * 0.95;
      }
      _pops.removeWhere((p) => p.life <= 0);
    }
    if (_bannerLife > 0) _bannerLife -= dt;
    if (_reserveFlash > 0) {
      _reserveFlash = (_reserveFlash - dt * 2.0).clamp(0.0, 1.0);
    }
    if (_emptyFlash > 0) _emptyFlash = (_emptyFlash - dt * 1.6).clamp(0.0, 1.0);
    for (final o in _organs) {
      if (o.flash > 0) o.flash = (o.flash - dt * 1.8).clamp(0.0, 1.0);
      o.pulse += dt;
    }
    // Pulses always travel so a delivery in flight at time-up still lands.
    _advancePulses(dt);

    // Detect a fresh run (session re-entry — the S in GAMES) and reset.
    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    if (running) _simulate(dt);
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
      // Pulmonary loop: blood reloads with O₂ at the lungs → reserve refills.
      _charges = _chargeCap;
      _recharging = false;
      _reserveFlash = 1.0;
      _fx.addAll(FxBurst.spawn(_px(_heart), _oxy, count: 14, speed: 120));
      _capFx();
      _setBanner('Recharged — O₂ reserve full', _oxy);
    } else if (p.target < _organs.length) {
      // Systemic loop: O₂ delivered; reward rescuing a low organ (triage).
      final o = _organs[p.target];
      final before = o.o2;
      o.o2 = (o.o2 + _deliverAmt).clamp(0.0, 1.0);
      o.flash = 1.0;
      if (o.suffering && o.o2 > 0.05) o.suffering = false;
      var points = 5 + ((1.0 - before).clamp(0.0, 1.0) * 15).round();
      if (_surge) points *= _surgeMult;
      if (widget.session.isRunning) {
        widget.session.addScore(points);
        _streak += 1;
        widget.session.noteStreak(_streak);
      }
      final at = _px(o.pos);
      _fx.addAll(FxBurst.spawn(at, _good, count: 10, speed: 100));
      _capFx();
      _addPop(at.dx, at.dy - 14, '+$points', _good);
    }
  }

  void _simulate(double dt) {
    _runElapsed += dt;

    // The CODE RED climax is driven by the host's shared clock (fair: equal for
    // every player). Detect it from remaining time.
    final remMs = widget.session.remaining.inMilliseconds;
    final nowSurge = remMs > 0 && remMs <= _surgeWindow * 1000;
    if (nowSurge && !_surge) {
      _surge = true;
      _setBanner('CODE RED — demand surge! ×2 points', _danger);
    }
    _surge = nowSurge;

    // Organs burn oxygen; demand climbs through the round, spikes in the surge.
    var demand = _lerp(_demandStart, _demandEnd, (_runElapsed / _dur).clamp(0.0, 1.0));
    if (_surge) demand += _surgeDemandKick;
    final drainMult = _surge ? _surgeDrainMult : 1.0;
    for (final o in _organs) {
      o.o2 = (o.o2 - o.drain * demand * drainMult * dt).clamp(0.0, 1.0);
      if (o.o2 <= 0.0 && !o.suffering) {
        o.suffering = true;
        _streak = 0;
        _setBanner('${o.name} starved — route O₂ now!', _danger);
        _fx.addAll(FxBurst.spawn(_px(o.pos), _danger, count: 10, speed: 90));
        _capFx();
      }
    }

    // Add organs over time — more of the body to keep perfused.
    if (_runElapsed >= _nextOrgan && _organs.length < _organSpecs.length) {
      final next = _organSpecs[_organs.length];
      _organs.add(
          _Organ(next[0] as String, next[1] as Offset, next[2] as double, o2: 0.7));
      _setBanner('New demand: ${next[0]}', Potatuhs.sienna);
      _nextOrgan = _runElapsed + _addOrganEvery;
    }

    // Rotate the educational fact on a slow timer.
    _factTimer += dt;
    if (_factTimer >= 4.0) {
      _factTimer = 0;
      _fact = _kFacts[_nextFact()];
    }
  }

  void _capFx() {
    if (_fx.length > _maxParticles) {
      _fx.removeRange(0, _fx.length - _maxParticles);
    }
  }

  void _addPop(double x, double y, String label, Color color) {
    _pops.add(_Pop(x: x, y: y, label: label, color: color));
    if (_pops.length > _maxPops) _pops.removeRange(0, _pops.length - _maxPops);
  }

  void _setBanner(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerLife = 1.7;
  }

  // ── Interaction: route blood by tapping a node ──
  void _onTap(Offset norm) {
    if (!widget.session.isRunning) return;
    // Lungs first (recharge), then organs (deliver) — generous lung target.
    if ((_lungs - norm).distance < 0.15) {
      _routeRecharge();
      return;
    }
    int? hit;
    var best = 0.14;
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
    if (_charges >= _chargeCap && !_recharging) {
      _setBanner('Reserve already full', _good);
      return;
    }
    if (_recharging) return; // one pulmonary cycle at a time
    _recharging = true;
    _pulses.add(_Pulse(-1, false)); // blue blood heart → lungs → reload
    _fx.addAll(FxBurst.spawn(_px(_heart), _deoxy, count: 7, speed: 80));
    _capFx();
  }

  void _routeDelivery(int i) {
    if (_charges <= 0) {
      _emptyFlash = 1.0;
      _setBanner('Out of O₂ — RECHARGE at the lungs', _danger);
      _fx.addAll(FxBurst.spawn(_px(_organs[i].pos), _danger, count: 5, speed: 60));
      _capFx();
      return;
    }
    // Commit one charge immediately (visible cost), score lands with the pulse.
    _charges -= 1;
    _organs[i].flash = 0.6;
    _pulses.add(_Pulse(i, true)); // red oxygenated blood heart → organ
    _fx.addAll(FxBurst.spawn(_px(_heart), _oxy, count: 5, speed: 70));
    _capFx();
    _addPop(_px(_heart).dx, _px(_heart).dy - 44, '−1', _oxy);
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
          painter: _CirculateV2Painter(repaint: _ctrl, state: this),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

class _CirculateV2Painter extends CustomPainter {
  final _CirculateV2GameState s;
  _CirculateV2Painter({required Listenable repaint, required _CirculateV2GameState state})
      : s = state,
        super(repaint: repaint);

  bool get running => s.widget.session.isRunning;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
    Offset px(Offset n) => Offset(n.dx * w, n.dy * h);

    GameFx.atmosphere(canvas, size, s._surge ? Potatuhs.orange : _accent,
        s._heartBeat,
        motes: 24);

    final heartPx = px(_CirculateV2GameState._heart);
    final lungsPx = px(_CirculateV2GameState._lungs);

    // ── Arteries to each organ (under the nodes) ──
    for (var i = 0; i < s._organs.length; i++) {
      final o = s._organs[i];
      final a = px(o.pos);
      final low = o.o2 < _CirculateV2GameState._lowO2;
      canvas.drawLine(
        heartPx,
        a,
        Paint()
          ..color =
              (low ? _danger : _oxy).withValues(alpha: low ? 0.32 : 0.15)
          ..strokeWidth = 2,
      );
    }
    // ── Pulmonary vessel heart ↔ lungs (the recharge artery) ──
    final pulmAlpha = s._charges <= _CirculateV2GameState._rechargePrompt
        ? 0.30 + 0.30 * (0.5 + 0.5 * math.sin(s._clock * 5))
        : 0.28;
    canvas.drawLine(
      heartPx,
      lungsPx,
      Paint()
        ..color = _deoxy.withValues(alpha: pulmAlpha)
        ..strokeWidth = 3,
    );

    // ── Blood pulses travelling the vessels ──
    for (final p in s._pulses) {
      final to = p.target < 0
          ? lungsPx
          : (p.target < s._organs.length ? px(s._organs[p.target].pos) : heartPx);
      final pos = Offset.lerp(heartPx, to, p.progress.clamp(0.0, 1.0))!;
      final col = p.oxygenated ? _oxy : _deoxy;
      canvas.drawCircle(
          pos,
          7,
          Paint()
            ..color = col.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(pos, 4.5, Paint()..color = col);
    }

    // ── Lungs — the big, persistent REFUEL node ──
    _drawLungs(canvas, lungsPx);

    // ── Heart (pumping; colour reflects the oxygen reserve red↔blue) ──
    final beat = 0.5 + 0.5 * math.sin(s._heartBeat * 5.0);
    final frac = (s._charges / _CirculateV2GameState._chargeCap).clamp(0.0, 1.0);
    final bloodCol = Color.lerp(_deoxy, _oxy, frac)!;
    final r = 30.0 + beat * 3.5 + s._reserveFlash * 4;
    GameFx.orb(canvas, heartPx, r, bloodCol, glow: 0.9 + s._reserveFlash * 0.5);
    GameFx.text(canvas, 'HEART', heartPx.translate(0, r + 12), 10,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);

    // ── The HERO read: the countable O₂ charge magazine above the heart ──
    _drawCharges(canvas, heartPx, r);

    // ── Organs ──
    for (var i = 0; i < s._organs.length; i++) {
      _drawOrgan(canvas, px(s._organs[i].pos), s._organs[i]);
    }

    // ── Ready hint (drawn on canvas — host owns the countdown) ──
    if (!running) {
      _drawReadyCard(canvas, w, h);
    } else {
      // Educational fact strip while playing.
      _drawFact(canvas, w, h);
    }

    // ── Empty-reserve alert ──
    if (s._emptyFlash > 0) {
      GameFx.text(
          canvas,
          'RECHARGE AT THE LUNGS',
          Offset(w / 2, h * 0.90),
          16,
          _danger.withValues(alpha: s._emptyFlash.clamp(0.0, 1.0)),
          weight: FontWeight.w800,
          glow: 0.6 * s._emptyFlash);
    }

    // ── CODE RED climax banner ──
    if (s._surge && running) {
      final pulse = 0.6 + 0.4 * math.sin(s._clock * 10);
      GameFx.text(
        canvas,
        'CODE RED ×2',
        Offset(w / 2, 40),
        20,
        Potatuhs.orange.withValues(alpha: pulse.clamp(0.0, 1.0)),
        display: true,
        weight: FontWeight.w800,
        glow: 0.7 * pulse,
      );
    }

    // ── Banner ──
    if (s._bannerLife > 0) {
      final a = (s._bannerLife / 1.7).clamp(0.0, 1.0);
      final y = (s._surge && running) ? h * 0.12 : h * 0.07;
      GameFx.text(canvas, s._banner, Offset(w / 2, y), 15,
          s._bannerColor.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.5 * a);
    }

    // ── Juice ──
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      if (!p.x.isFinite || !p.y.isFinite) continue;
      final a = p.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      final off = Offset(p.x - p.tp.width / 2, p.y);
      if (a >= 0.98) {
        p.tp.paint(canvas, off);
      } else {
        canvas.saveLayer(off & p.tp.size, Paint()..color = Color.fromRGBO(0, 0, 0, a));
        p.tp.paint(canvas, off);
        canvas.restore();
      }
    }
  }

  // ── The hero read: a row of countable oxygen charges on the heart ──────────
  void _drawCharges(Canvas canvas, Offset heart, double r) {
    const cap = _CirculateV2GameState._chargeCap;
    const pipR = 7.0;
    const gap = 8.0;
    final totalW = cap * (pipR * 2) + (cap - 1) * gap;
    final top = heart.dy - r - 30;
    var x = heart.dx - totalW / 2 + pipR;
    final low = s._charges <= _CirculateV2GameState._rechargePrompt;
    final blink = low && running ? (0.4 + 0.6 * (0.5 + 0.5 * math.sin(s._clock * 6))) : 1.0;
    for (var i = 0; i < cap; i++) {
      final filled = i < s._charges;
      final c = Offset(x, top);
      if (filled) {
        GameFx.orb(canvas, c, pipR, _oxy.withValues(alpha: blink.clamp(0.0, 1.0)),
            glow: 0.6, specular: false);
      } else {
        canvas.drawCircle(c, pipR,
            Paint()..color = Colors.white.withValues(alpha: 0.10));
        canvas.drawCircle(
            c,
            pipR,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3
              ..color = _oxy.withValues(alpha: 0.30));
      }
      x += pipR * 2 + gap;
    }
    GameFx.text(
      canvas,
      'O₂ RESERVE  ${s._charges}/$cap',
      Offset(heart.dx, top - 18),
      11.5,
      (low ? _danger : Colors.white).withValues(alpha: 0.85),
      weight: FontWeight.w800,
    );
  }

  void _drawLungs(Canvas canvas, Offset lungsPx) {
    final low = s._charges <= _CirculateV2GameState._rechargePrompt;
    final pulse = low && running ? (0.5 + 0.5 * math.sin(s._clock * 6)).abs() : 0.0;
    // Persistent refuel halo — bright when the reserve is low (anticipation).
    canvas.drawCircle(
      lungsPx,
      26 + pulse * 6,
      Paint()
        ..color = _deoxy.withValues(alpha: 0.14 + pulse * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final lungGlow = 0.6 + 0.4 * s._reserveFlash + pulse * 0.4;
    GameFx.orb(canvas, lungsPx, 22, _deoxy, glow: lungGlow);
    // A small O₂ "+" marker so the refuel meaning reads at a glance.
    GameFx.text(canvas, '+O₂', lungsPx, 11, Colors.white.withValues(alpha: 0.9),
        weight: FontWeight.w800);
    GameFx.text(canvas, 'LUNGS', lungsPx.translate(0, -34), 10,
        Colors.white.withValues(alpha: 0.80), weight: FontWeight.w800);
    final refuelCol = low && running
        ? _oxy.withValues(alpha: (0.6 + 0.4 * pulse).clamp(0.0, 1.0))
        : Colors.white.withValues(alpha: 0.46);
    GameFx.text(canvas, low && running ? 'TAP TO RECHARGE' : 'tap to refuel O₂',
        lungsPx.translate(0, 36), 9.5, refuelCol,
        weight: low ? FontWeight.w800 : FontWeight.w600);
  }

  void _drawReadyCard(Canvas canvas, double w, double h) {
    GameFx.text(
      canvas,
      'Tap a LOW organ to deliver O₂ (−1 charge)',
      Offset(w / 2, h - 40),
      13,
      Colors.white.withValues(alpha: 0.72),
      weight: FontWeight.w700,
    );
    GameFx.text(
      canvas,
      'Tap the LUNGS to recharge your reserve',
      Offset(w / 2, h - 22),
      12.5,
      _deoxy.withValues(alpha: 0.85),
      weight: FontWeight.w600,
    );
  }

  void _drawFact(Canvas canvas, double w, double h) {
    final tp = TextPainter(
      text: TextSpan(
        text: s._fact,
        style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary, height: 1.2),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: w - 40);
    final boxW = tp.width + 24;
    final boxH = tp.height + 12;
    final left = (w - boxW) / 2;
    final top = h - boxH - 12;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, boxW, boxH), const Radius.circular(10));
    canvas.drawRRect(rr, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.82));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _accent.withValues(alpha: 0.35));
    tp.paint(canvas, Offset(left + 12, top + 6));
  }

  void _drawOrgan(Canvas canvas, Offset c, _Organ o) {
    final low = o.o2 < _CirculateV2GameState._lowO2;
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
  bool shouldRepaint(covariant _CirculateV2Painter old) => true;
}
