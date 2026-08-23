import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Circulate v2 ══════════════════════════════════════════════════════════
/// Whole-body gas cycle on the organ-system scale. You run THREE braided jobs:
///   • **INHALE (hold)** — draw O₂ into the countable reserve at the heart.
///   • **EXHALE (hold)** — vent the CO₂ pressure the cells hand back (real
///     physiology: exhaling is how CO₂ leaves). Neglect it → acidosis, organs
///     drain faster.
///   • **HEARTBEAT (double-tap — lub-dub)** — breathing alone moves no blood;
///     the beat is the pump. It fires every PRIMED organ a red arterial pulse.
/// Oxygen-starved organs keep coming online (the loop kept intact from the prior
/// version) and demand delivery: **tap** one to PRIME it, then lub-dub to pump.
///
/// The host ([MiniGameHost]) owns the timer, 3·2·1 countdown, score HUD and
/// results; this widget renders the play area + a bottom control row. Everything
/// animated — vessels, blood, lungs, the charge magazine, the CO₂ bar, the
/// lub-dub — is drawn by ONE [CustomPainter] driven by ONE `days:1` ticker with
/// no per-frame setState. The three buttons are lightweight widgets that only
/// flip a boolean (hold) or feed the lub-dub detector (beat).

// ── Palette ────────────────────────────────────────────────────────────────
const Color _accent = Color(0xFFE5384B); // arterial crimson
const Color _oxy = Color(0xFFFF5566); // bright oxygenated red
const Color _deoxy = Color(0xFF4A7DC4); // deoxygenated blue
const Color _good = Color(0xFF66E08A); // healthy organ green
const Color _danger = Color(0xFFE5533D); // suffering / empty red
const Color _co2Col = Color(0xFFC9A24B); // CO₂ pressure — warm ochre

// ── Education: surfaced as the run plays ────────────────────────────────────
const List<String> _kFacts = [
  'Inhaling loads O₂ into the blood; exhaling expels the CO₂ cells give back.',
  'Breathing alone moves no blood — the HEART is the pump. Lub-dub.',
  'The two heart sounds, "lub" then "dub", are its valves snapping shut.',
  'Unvented CO₂ turns the blood acidic — every organ feels the stress.',
  'Red blood is oxygenated; it hands its O₂ to the organs and returns spent.',
  'Systemic loop: the beat pumps oxygen-rich blood out to every organ.',
  'Pulmonary loop: spent blood returns to the lungs to reload O₂ and dump CO₂.',
  'Starved of oxygen, an organ fails — the brain lasts only minutes without it.',
  'A potato respires too — O₂ in, CO₂ out — through pores called lenticels.',
];

/// A body organ fed by an artery from the heart. [o2] drains over time; PRIME it
/// (tap) and it delivers on the next heartbeat pump.
class _Organ {
  final String name;
  final Offset pos; // normalised 0..1 within the play area
  final double drain; // O₂ lost per second
  double o2; // 0..1 oxygen level
  double flash = 0; // delivery / prime feedback, 1 → 0
  bool suffering = false; // latched while o2 == 0
  bool armed = false; // primed for the next pump
  double pulse = 0; // animates the low-O₂ alarm glow

  _Organ(this.name, this.pos, this.drain, {this.o2 = 0.8});
}

/// A travelling blob of oxygenated blood, heart → organ [target] (a delivery).
class _Pulse {
  final int target;
  double progress = 0; // 0..1 along heart → target
  _Pulse(this.target);
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
  static const Offset _heart = Offset(0.24, 0.58);
  static const Offset _lungs = Offset(0.24, 0.22);

  // ── Tunables ──
  /// The reserve is a COUNTABLE magazine of oxygen charges — the hero read.
  static const int _chargeCap = 5;
  static const double _deliverAmt = 0.62; // O₂ a delivery restores to an organ
  static const double _pulseSpeed = 2.5; // progress/sec (~0.4s travel)
  static const double _lowO2 = 0.34; // below this an organ flashes "LOW O₂"

  // Breath + beat.
  static const double _inhaleRate = 3.2; // charges/sec drawn in while holding
  static const double _exhaleRate = 0.85; // CO₂/sec vented while holding
  static const double _co2BaseRate = 0.05; // CO₂/sec metabolic accrual
  static const double _co2PerDeliver = 0.06; // CO₂ added per organ pumped
  static const double _co2Warn = 0.6; // acidosis stress threshold
  static const double _co2DrainBoost = 0.9; // extra drain factor at CO₂ == 1
  static const double _beatWindow = 0.5; // s between the "lub" and the "dub"

  static const double _addOrganEvery = 11.0;
  static const double _demandStart = 1.0;
  static const double _demandEnd = 2.0;

  /// The CODE RED climax: final seconds, demand spikes, scoring doubles.
  static const double _surgeWindow = 12.0;
  static const int _surgeMult = 2;
  static const double _surgeDrainMult = 1.6;
  static const double _surgeDemandKick = 0.6;
  static const double _surgeCo2Mult = 1.5;

  static const int _maxParticles = 60;
  static const int _maxPops = 6;

  // ── Sim state ──
  late List<_Organ> _organs;
  final List<_Pulse> _pulses = [];
  double _o2 = _chargeCap.toDouble(); // continuous reserve 0..cap
  double _co2 = 0.0; // CO₂ pressure 0..1
  bool _inhaling = false;
  bool _exhaling = false;
  int _streak = 0; // consecutive deliveries without a flatline
  double _clock = 0; // ever-advancing seconds (idle/heartbeat)
  double _lastT = 0;
  double _runElapsed = 0; // seconds inside the active run
  double _nextOrgan = _addOrganEvery;
  bool _wasRunning = false;
  bool _surge = false;

  // Whole-number reserve = the countable pip read + what a pump can spend.
  int get _charges => _o2.floor().clamp(0, _chargeCap);

  double _heartBeat = 0; // idle heartbeat phase (pumping animation)
  double _lubDub = 0; // pump animation, 1 → 0
  double _lubPending = 0; // "lub" landed, waiting for the "dub", 1 → 0
  double _lastBeatTapT = -999; // clock time of the last beat-tap
  double _reserveFlash = 0; // pulse when the reserve tops up, 1 → 0
  double _emptyFlash = 0; // "HOLD INHALE" alert, 1 → 0
  double _co2Flash = 0; // "HOLD EXHALE" / acidosis alert, 1 → 0
  double _inhaleAnim = 0; // 0..1 lungs-expanding
  double _exhaleAnim = 0; // 0..1 lungs-venting

  // In-context teaching (re-arms every fresh session — the S in GAMES).
  bool _taughtPrime = false;
  bool _taughtBeat = false;
  bool _taughtInhale = false;
  bool _taughtExhale = false;

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
    // ATTRACT autopilot: vent CO₂ when high, top up O₂ when low, prime the
    // neediest organs and lub-dub to pump (see [MiniGameSession.autoPilot]).
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  /// One competent attract move per call (~every 250ms). Deterministic and it
  /// drives ALL THREE controls: exhale if CO₂ is climbing, inhale if the reserve
  /// is thin, prime the neediest low organ, then beat the heart to pump what's
  /// primed. Discrete effect per call (like a brief hold / a lub-dub).
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // 1. Vent CO₂ before it starts choking the body.
    if (_co2 > _co2Warn - 0.05) {
      _autoExhaleTick();
      return;
    }

    // 2. Keep enough O₂ in the reserve to fund a pump.
    if (_o2 < 2.0) {
      _autoInhaleTick();
      return;
    }

    // 3. Prime the neediest low organ that isn't already armed.
    int? neediest;
    var lowest = double.infinity;
    for (var i = 0; i < _organs.length; i++) {
      final o = _organs[i];
      if (!o.armed && o.o2 < _lowO2 && o.o2 < lowest) {
        lowest = o.o2;
        neediest = i;
      }
    }
    if (neediest != null) {
      _prime(neediest);
      return;
    }

    // 4. Something primed → pump it out with a heartbeat.
    if (_organs.any((o) => o.armed)) {
      _pumpHeart();
      return;
    }

    // 5. Nothing urgent: keep the reserve topped for the surge to come.
    if (_o2 < _chargeCap) _autoInhaleTick();
  }

  void _autoInhaleTick() {
    _o2 = (_o2 + 1.4).clamp(0.0, _chargeCap.toDouble());
    _inhaleAnim = 1.0;
    _taughtInhale = true;
  }

  void _autoExhaleTick() {
    _co2 = (_co2 - 0.32).clamp(0.0, 1.0);
    _exhaleAnim = 1.0;
    _taughtExhale = true;
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
    _o2 = _chargeCap.toDouble();
    _co2 = 0.0;
    _inhaling = false;
    _exhaling = false;
    _streak = 0;
    _nextOrgan = _addOrganEvery;
    _surge = false;
    _lubDub = 0;
    _lubPending = 0;
    _lastBeatTapT = -999;
    _reserveFlash = 0;
    _emptyFlash = 0;
    _co2Flash = 0;
    _inhaleAnim = 0;
    _exhaleAnim = 0;
    _taughtPrime = false;
    _taughtBeat = false;
    _taughtInhale = false;
    _taughtExhale = false;
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
    if (_reserveFlash > 0) _reserveFlash = (_reserveFlash - dt * 2.0).clamp(0.0, 1.0);
    if (_emptyFlash > 0) _emptyFlash = (_emptyFlash - dt * 1.6).clamp(0.0, 1.0);
    if (_co2Flash > 0) _co2Flash = (_co2Flash - dt * 1.6).clamp(0.0, 1.0);
    if (_lubDub > 0) _lubDub = (_lubDub - dt * 2.2).clamp(0.0, 1.0);

    // The "lub" waits a beat window for its "dub"; if it expires it was a lone
    // tap (no pump) — decay its ripple.
    if (_lubPending > 0) {
      _lubPending = (_lubPending - dt / _beatWindow).clamp(0.0, 1.0);
    }

    // Ease the breath animations toward their held state.
    final inTarget = _inhaling ? 1.0 : 0.0;
    final exTarget = _exhaling ? 1.0 : 0.0;
    final k = 1 - math.pow(0.0006, dt).toDouble();
    _inhaleAnim += (inTarget - _inhaleAnim) * k;
    _exhaleAnim += (exTarget - _exhaleAnim) * k;

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

    if (running) {
      // Held breaths act on the reserve / CO₂ every frame.
      if (_inhaling) {
        _o2 = (_o2 + _inhaleRate * dt).clamp(0.0, _chargeCap.toDouble());
        if (_o2 >= _chargeCap) _reserveFlash = math.max(_reserveFlash, 0.6);
        _taughtInhale = true;
      }
      if (_exhaling) {
        _co2 = (_co2 - _exhaleRate * dt).clamp(0.0, 1.0);
        _taughtExhale = true;
      }
      _simulate(dt);
    }
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
    if (p.target < 0 || p.target >= _organs.length) return;
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
    // Delivered O₂ is burned by the cell — CO₂ is handed back.
    _co2 = (_co2 + _co2PerDeliver).clamp(0.0, 1.0);
    final at = _px(o.pos);
    _fx.addAll(FxBurst.spawn(at, _good, count: 10, speed: 100));
    _capFx();
    _addPop(at.dx, at.dy - 14, '+$points', _good);
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

    // Metabolic CO₂ keeps building; the surge speeds it up. It must be vented.
    _co2 = (_co2 + _co2BaseRate * (_surge ? _surgeCo2Mult : 1.0) * dt)
        .clamp(0.0, 1.0);
    if (_co2 >= _co2Warn && !_taughtExhale) {
      _co2Flash = math.max(_co2Flash, 0.9);
    }

    // Organs burn oxygen; demand climbs, spikes in the surge, and high CO₂
    // (acidosis) makes every organ drain faster.
    var demand = _lerp(_demandStart, _demandEnd, (_runElapsed / _dur).clamp(0.0, 1.0));
    if (_surge) demand += _surgeDemandKick;
    final co2Stress = _co2 <= _co2Warn
        ? 1.0
        : 1.0 + _co2DrainBoost * ((_co2 - _co2Warn) / (1.0 - _co2Warn));
    final drainMult = (_surge ? _surgeDrainMult : 1.0) * co2Stress;
    for (final o in _organs) {
      o.o2 = (o.o2 - o.drain * demand * drainMult * dt).clamp(0.0, 1.0);
      if (o.o2 <= 0.0 && !o.suffering) {
        o.suffering = true;
        _streak = 0;
        _setBanner('${o.name} starved — prime it & beat!', _danger);
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

  // ── Interaction on the play field ──
  void _onTap(Offset norm) {
    if (!widget.session.isRunning) return;
    // Heart node first (a beat-tap); then organs (prime).
    if ((_heart - norm).distance < 0.15) {
      _beatTap();
      return;
    }
    int? hit;
    var best = 0.15;
    for (var i = 0; i < _organs.length; i++) {
      final d = (_organs[i].pos - norm).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit != null) _prime(hit);
  }

  /// PRIME an organ: arm it for the next pump. No charge is spent yet — the
  /// heartbeat spends it. This is the beloved "tap the starving node" loop.
  void _prime(int i) {
    if (!widget.session.isRunning) return;
    final o = _organs[i];
    if (o.armed) return;
    o.armed = true;
    o.flash = math.max(o.flash, 0.4);
    _taughtPrime = true;
    _fx.addAll(FxBurst.spawn(_px(o.pos), _oxy, count: 5, speed: 55));
    _capFx();
  }

  /// A heart tap. Two within [_beatWindow] make a lub-dub → a pump.
  void _beatTap() {
    if (!widget.session.isRunning) return;
    if (_clock - _lastBeatTapT <= _beatWindow) {
      _lastBeatTapT = -999;
      _lubPending = 0;
      _pumpHeart();
    } else {
      _lastBeatTapT = _clock;
      _lubPending = 1.0; // the "lub" — waiting for the "dub"
      _fx.addAll(FxBurst.spawn(_px(_heart), _oxy, count: 3, speed: 45));
      _capFx();
    }
  }

  /// The lub-dub pump: fire every primed organ a delivery, neediest first,
  /// spending one charge each while the reserve allows.
  void _pumpHeart() {
    _lubDub = 1.0;
    _taughtBeat = true;

    final armed = <int>[
      for (var i = 0; i < _organs.length; i++)
        if (_organs[i].armed) i
    ];
    if (armed.isEmpty) {
      _setBanner('Nothing primed — tap a LOW organ', Potatuhs.sienna);
      return;
    }
    armed.sort((a, b) => _organs[a].o2.compareTo(_organs[b].o2));

    var fired = 0;
    var blocked = false;
    for (final i in armed) {
      if (_o2 >= 1.0) {
        _o2 -= 1.0;
        _organs[i].armed = false;
        _organs[i].flash = 0.6;
        _pulses.add(_Pulse(i));
        fired += 1;
        _addPop(_px(_heart).dx, _px(_heart).dy - 44 - fired * 4.0, '−1', _oxy);
      } else {
        blocked = true;
      }
    }
    if (fired > 0) {
      _fx.addAll(FxBurst.spawn(_px(_heart), _oxy, count: 6 + fired * 2, speed: 90));
      _capFx();
    }
    if (blocked) {
      _emptyFlash = 1.0;
      _setBanner('Out of O₂ — HOLD INHALE', _danger);
    }
  }

  // Button hooks (the bottom control row).
  void _setInhale(bool on) {
    if (!widget.session.isRunning) return;
    _inhaling = on;
    if (on) _exhaling = false; // one breath direction at a time
  }

  void _setExhale(bool on) {
    if (!widget.session.isRunning) return;
    _exhaling = on;
    if (on) _inhaling = false;
  }

  Offset _px(Offset norm) => Offset(norm.dx * _w, norm.dy * _h);

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
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
          }),
        ),
        _ControlRow(
          onInhaleDown: () => _setInhale(true),
          onInhaleUp: () => _setInhale(false),
          onExhaleDown: () => _setExhale(true),
          onExhaleUp: () => _setExhale(false),
          onBeat: _beatTap,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bottom control row — three lightweight buttons. HOLD inhale/exhale, double-tap
// heartbeat. All rich animated feedback lives on the canvas; these only flip a
// flag (hold) or feed the beat detector, so they never rebuild per frame.
// ═══════════════════════════════════════════════════════════════════════════

class _ControlRow extends StatelessWidget {
  final VoidCallback onInhaleDown, onInhaleUp, onExhaleDown, onExhaleUp, onBeat;
  const _ControlRow({
    required this.onInhaleDown,
    required this.onInhaleUp,
    required this.onExhaleDown,
    required this.onExhaleUp,
    required this.onBeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: _accent.withValues(alpha: 0.35), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HoldButton(
              label: 'INHALE',
              sub: 'hold · O₂ in',
              icon: Icons.south,
              color: _deoxy,
              onDown: onInhaleDown,
              onUp: onInhaleUp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BeatButton(color: _oxy, onTap: onBeat),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HoldButton(
              label: 'EXHALE',
              sub: 'hold · CO₂ out',
              icon: Icons.north,
              color: _co2Col,
              onDown: onExhaleDown,
              onUp: onExhaleUp,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  final String label, sub;
  final IconData icon;
  final Color color;
  final VoidCallback onDown, onUp;
  const _HoldButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onDown,
    required this.onUp,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    v ? widget.onDown() : widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: _down ? 0.34 : 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: c.withValues(alpha: _down ? 0.95 : 0.55),
            width: _down ? 2 : 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: c),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Potatuhs.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.sub,
              style: const TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Potatuhs.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeatButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  const _BeatButton({required this.color, required this.onTap});

  @override
  State<_BeatButton> createState() => _BeatButtonState();
}

class _BeatButtonState extends State<_BeatButton> {
  bool _flash = false;

  void _hit() {
    widget.onTap();
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _hit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: _flash ? 0.40 : 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: c.withValues(alpha: _flash ? 0.95 : 0.6),
            width: _flash ? 2.4 : 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 15, color: c),
                const SizedBox(width: 5),
                const Text(
                  'HEARTBEAT',
                  style: TextStyle(
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Potatuhs.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'double-tap · lub-dub',
              style: TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Potatuhs.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// The painter — one ticker drives all motion.
// ═══════════════════════════════════════════════════════════════════════════

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

    // ── Arteries to each organ (bright when primed) ──
    for (var i = 0; i < s._organs.length; i++) {
      final o = s._organs[i];
      final a = px(o.pos);
      final low = o.o2 < _CirculateV2GameState._lowO2;
      if (o.armed) {
        // A primed artery pulses bright — it will fire on the next lub-dub.
        final glow = 0.5 + 0.5 * math.sin(s._clock * 7);
        canvas.drawLine(
          heartPx,
          a,
          Paint()
            ..color = _oxy.withValues(alpha: 0.45 + 0.30 * glow)
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      } else {
        canvas.drawLine(
          heartPx,
          a,
          Paint()
            ..color = (low ? _danger : _oxy).withValues(alpha: low ? 0.32 : 0.15)
            ..strokeWidth = 2,
        );
      }
    }
    // ── Pulmonary vessel heart ↔ lungs (breathing flows along it) ──
    final breath = math.max(s._inhaleAnim, s._exhaleAnim);
    canvas.drawLine(
      heartPx,
      lungsPx,
      Paint()
        ..color = _deoxy.withValues(alpha: 0.26 + 0.30 * breath)
        ..strokeWidth = 3,
    );

    // ── Blood pulses travelling out to the organs ──
    for (final p in s._pulses) {
      final to = (p.target >= 0 && p.target < s._organs.length)
          ? px(s._organs[p.target].pos)
          : heartPx;
      final pos = Offset.lerp(heartPx, to, p.progress.clamp(0.0, 1.0))!;
      canvas.drawCircle(
          pos,
          7,
          Paint()
            ..color = _oxy.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(pos, 4.5, Paint()..color = _oxy);
    }

    // ── Lungs — breathing node + the CO₂ pressure bar ──
    _drawLungs(canvas, lungsPx);
    _drawCo2Bar(canvas, lungsPx);

    // ── Heart (pumping; colour reflects the oxygen reserve red↔blue) ──
    _drawHeart(canvas, heartPx);

    // ── The HERO read: the countable O₂ charge magazine above the heart ──
    _drawCharges(canvas, heartPx);

    // ── Organs ──
    for (var i = 0; i < s._organs.length; i++) {
      _drawOrgan(canvas, px(s._organs[i].pos), s._organs[i]);
    }

    // ── In-context teaching prompts (in-world, no modals) ──
    if (running) {
      _drawTeach(canvas, w, h, heartPx, lungsPx);
      _drawFact(canvas, w, h);
    } else {
      _drawReadyCard(canvas, w, h);
    }

    // ── Empty-reserve alert ──
    if (s._emptyFlash > 0) {
      GameFx.text(
          canvas,
          'HOLD INHALE — DRAW O₂',
          Offset(w / 2, h * 0.92),
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

  // ── The heart: idle beat + the lub-dub pump rings ────────────────────────
  void _drawHeart(Canvas canvas, Offset heart) {
    // Lub-dub rings: an inner "lub" and an outer "dub" ripple on a pump.
    if (s._lubDub > 0) {
      final e = 1 - s._lubDub;
      for (final ring in const [0.0, 0.35]) {
        final rt = (e - ring).clamp(0.0, 1.0);
        if (rt <= 0) continue;
        canvas.drawCircle(
          heart,
          34 + rt * 44,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5 * (1 - rt)
            ..color = _oxy.withValues(alpha: 0.55 * (1 - rt))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    // A pending "lub" — a small held ring waiting for the "dub".
    if (s._lubPending > 0) {
      canvas.drawCircle(
        heart,
        30 + 6 * (1 - s._lubPending),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _oxy.withValues(alpha: 0.4 * s._lubPending),
      );
    }

    final beat = 0.5 + 0.5 * math.sin(s._heartBeat * 5.0);
    final frac = (s._o2 / _CirculateV2GameState._chargeCap).clamp(0.0, 1.0);
    final bloodCol = Color.lerp(_deoxy, _oxy, frac)!;
    final r = 30.0 + beat * 3.5 + s._lubDub * 7 + s._reserveFlash * 3;
    GameFx.orb(canvas, heart, r, bloodCol, glow: 0.9 + s._lubDub * 0.6);
    GameFx.text(canvas, 'HEART', heart.translate(0, r + 12), 10,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
  }

  // ── The hero read: a row of countable oxygen charges on the heart ──────────
  void _drawCharges(Canvas canvas, Offset heart) {
    const cap = _CirculateV2GameState._chargeCap;
    const pipR = 7.0;
    const gap = 8.0;
    const totalW = cap * (pipR * 2) + (cap - 1) * gap;
    final top = heart.dy - 30 - 30;
    var x = heart.dx - totalW / 2 + pipR;
    final whole = s._charges;
    final frac = (s._o2 - whole).clamp(0.0, 1.0); // the filling pip
    final low = whole <= 1;
    final blink = low && running ? (0.4 + 0.6 * (0.5 + 0.5 * math.sin(s._clock * 6))) : 1.0;
    for (var i = 0; i < cap; i++) {
      final c = Offset(x, top);
      if (i < whole) {
        GameFx.orb(canvas, c, pipR, _oxy.withValues(alpha: blink.clamp(0.0, 1.0)),
            glow: 0.6, specular: false);
      } else {
        canvas.drawCircle(
            c, pipR, Paint()..color = Colors.white.withValues(alpha: 0.10));
        if (i == whole && frac > 0.02) {
          // The active pip fills as you inhale.
          canvas.drawCircle(
              c, pipR * frac, Paint()..color = _oxy.withValues(alpha: 0.7));
        }
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
      'O₂ RESERVE  $whole/$cap',
      Offset(heart.dx, top - 18),
      11.5,
      (low ? _danger : Colors.white).withValues(alpha: 0.85),
      weight: FontWeight.w800,
    );
  }

  void _drawLungs(Canvas canvas, Offset lungsPx) {
    // Breathing scales the lungs: inhale expands, exhale contracts a touch.
    const base = 22.0;
    final r = base + s._inhaleAnim * 8 - s._exhaleAnim * 3;
    if (s._inhaleAnim > 0.05) {
      canvas.drawCircle(
        lungsPx,
        r + 8 + s._inhaleAnim * 6,
        Paint()
          ..color = _deoxy.withValues(alpha: 0.10 + s._inhaleAnim * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    GameFx.orb(canvas, lungsPx, r, _deoxy, glow: 0.6 + s._inhaleAnim * 0.5);
    // O₂ in on inhale, CO₂ out on exhale — a directional marker.
    final mark = s._exhaleAnim > s._inhaleAnim ? 'CO₂↑' : 'O₂';
    GameFx.text(canvas, mark, lungsPx, 11, Colors.white.withValues(alpha: 0.9),
        weight: FontWeight.w800);
    GameFx.text(canvas, 'LUNGS', lungsPx.translate(0, -r - 12), 10,
        Colors.white.withValues(alpha: 0.80), weight: FontWeight.w800);
  }

  // ── CO₂ pressure bar — the vent axis, beside the lungs ─────────────────────
  void _drawCo2Bar(Canvas canvas, Offset lungsPx) {
    const barH = 70.0, barW = 12.0;
    final left = lungsPx.dx + 40;
    final top = lungsPx.dy - barH / 2;
    final track = Rect.fromLTWH(left, top, barW, barH);
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.4));
    final high = s._co2 >= _CirculateV2GameState._co2Warn;
    final blink = high && running ? (0.6 + 0.4 * math.sin(s._clock * 6)).abs() : 1.0;
    final fillH = barH * s._co2.clamp(0.0, 1.0);
    final fillCol = high ? _danger : _co2Col;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top + (barH - fillH), barW, fillH),
          const Radius.circular(6)),
      Paint()..color = fillCol.withValues(alpha: blink.clamp(0.0, 1.0)),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    GameFx.text(canvas, 'CO₂', Offset(left + barW / 2, top - 10), 9.5,
        (high ? _danger : Colors.white).withValues(alpha: 0.7),
        weight: FontWeight.w800);
    if (high && running) {
      GameFx.text(canvas, 'HIGH', Offset(left + barW / 2, top + barH + 10), 8.5,
          _danger.withValues(alpha: blink.clamp(0.0, 1.0)),
          weight: FontWeight.w800);
    }
  }

  // ── In-context teaching: fires once per fresh session, on first occurrence ──
  void _drawTeach(Canvas canvas, double w, double h, Offset heart, Offset lungs) {
    // 1. First low organ → teach the prime tap.
    if (!s._taughtPrime) {
      for (final o in s._organs) {
        if (o.o2 < _CirculateV2GameState._lowO2) {
          final c = s._px(o.pos);
          GameFx.text(canvas, 'TAP TO PRIME', c.translate(0, -34), 10,
              _oxy.withValues(alpha: 0.9),
              weight: FontWeight.w800, glow: 0.4);
          break;
        }
      }
    } else if (!s._taughtBeat && s._organs.any((o) => o.armed)) {
      // 2. Something primed but never pumped → teach the lub-dub.
      GameFx.text(canvas, 'DOUBLE-TAP ♥  LUB-DUB!', heart.translate(0, -68), 11,
          _oxy, weight: FontWeight.w800, glow: 0.5);
    }
    // 3. CO₂ high and never vented → teach exhale (near the bar).
    if (!s._taughtExhale && s._co2 >= _CirculateV2GameState._co2Warn) {
      GameFx.text(canvas, 'HOLD EXHALE →', Offset(lungs.dx + 92, lungs.dy), 10.5,
          _danger.withValues(alpha: (0.6 + 0.4 * s._co2Flash).clamp(0.0, 1.0)),
          weight: FontWeight.w800, glow: 0.4);
    }
    // 4. Reserve empty and never inhaled → teach the inhale hold (bottom-left,
    // over the INHALE button).
    if (!s._taughtInhale && s._charges == 0) {
      final blink = 0.55 + 0.45 * math.sin(s._clock * 6);
      GameFx.text(canvas, 'HOLD INHALE ↓', Offset(w * 0.18, h - 14), 11,
          _oxy.withValues(alpha: blink.clamp(0.0, 1.0)),
          weight: FontWeight.w800, glow: 0.4);
    }
  }

  void _drawReadyCard(Canvas canvas, double w, double h) {
    GameFx.text(
      canvas,
      'HOLD INHALE for O₂ · tap a LOW organ to prime',
      Offset(w / 2, h - 40),
      12.5,
      Colors.white.withValues(alpha: 0.72),
      weight: FontWeight.w700,
    );
    GameFx.text(
      canvas,
      'DOUBLE-TAP the heart (lub-dub) to pump · HOLD EXHALE to vent CO₂',
      Offset(w / 2, h - 22),
      11.5,
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
    final top = h - boxH - 10;
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

    // A PRIMED ring — armed for the next pump.
    if (o.armed) {
      canvas.drawCircle(
        c,
        rr + 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _oxy.withValues(alpha: 0.85),
      );
    }

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
    if (o.armed) {
      GameFx.text(canvas, 'PRIMED', c.translate(0, rr + 25), 8.5,
          _oxy.withValues(alpha: 0.9), weight: FontWeight.w800);
    } else if (low && running) {
      GameFx.text(canvas, o.suffering ? 'STARVED' : 'LOW O₂',
          c.translate(0, rr + 25), 8.5,
          _danger.withValues(alpha: 0.6 + 0.4 * alarm), weight: FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(covariant _CirculateV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the SAME GameFx
// primitives + palette the live game uses. The player meets the breathing lungs,
// the countable O₂ reserve pips, the prime-then-lub-dub delivery, the CO₂ vent
// and the CODE RED surge here, before ever tapping.
// ═══════════════════════════════════════════════════════════════════════════

/// The countable O₂ charge magazine above the heart — the hero read.
void _legendReservePips(
    Canvas canvas, Offset heart, double r, int charges, int cap) {
  const pipR = 8.0;
  const gap = 9.0;
  final totalW = cap * (pipR * 2) + (cap - 1) * gap;
  final top = heart.dy - r - 30;
  var x = heart.dx - totalW / 2 + pipR;
  for (var i = 0; i < cap; i++) {
    final c = Offset(x, top);
    if (i < charges) {
      GameFx.orb(canvas, c, pipR, _oxy, glow: 0.6, specular: false);
    } else {
      canvas.drawCircle(
          c, pipR, Paint()..color = Colors.white.withValues(alpha: 0.10));
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
  GameFx.text(canvas, 'O₂ RESERVE  $charges/$cap', Offset(heart.dx, top - 18),
      12, Colors.white.withValues(alpha: 0.9),
      weight: FontWeight.w800);
}

/// One organ with its O₂ ring gauge — mirrors [_CirculateV2Painter._drawOrgan].
void _legendOrgan(Canvas canvas, Offset c, double o2, String name,
    {bool low = false, bool primed = false, double rr = 18}) {
  final base = Color.lerp(_danger, _good, o2.clamp(0.0, 1.0))!;
  if (low) {
    canvas.drawCircle(
        c, rr + 10, Paint()..color = _danger.withValues(alpha: 0.16));
  }
  GameFx.orb(canvas, c, rr, base, glow: low ? 0.7 : 0.5);
  if (primed) {
    canvas.drawCircle(
      c,
      rr + 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _oxy.withValues(alpha: 0.85),
    );
  }
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
  GameFx.text(canvas, name, c.translate(0, rr + 13), 9.5,
      Colors.white.withValues(alpha: 0.80),
      weight: FontWeight.w700);
  if (primed) {
    GameFx.text(canvas, 'PRIMED', c.translate(0, rr + 25), 8.5,
        _oxy.withValues(alpha: 0.9), weight: FontWeight.w800);
  } else if (low) {
    GameFx.text(canvas, 'LOW O₂', c.translate(0, rr + 25), 8.5,
        _danger.withValues(alpha: 0.9), weight: FontWeight.w800);
  }
}

/// Frame 1 — INHALE: draw O₂ into the reserve.
void _legendInhale(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final lungs = Offset(w * 0.5, h * 0.36);
  final r = math.min(w, h) * 0.14;
  // Inhale halo — pulling O₂ in.
  canvas.drawCircle(
    lungs,
    r + 12,
    Paint()
      ..color = _deoxy.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  GameFx.orb(canvas, lungs, r, _deoxy, glow: 0.9);
  GameFx.text(canvas, 'O₂', lungs, 12, Colors.white.withValues(alpha: 0.9),
      weight: FontWeight.w800);
  GameFx.text(canvas, 'LUNGS', lungs.translate(0, -r - 12), 10,
      Colors.white.withValues(alpha: 0.80), weight: FontWeight.w800);
  GameFx.text(canvas, 'HOLD  INHALE', Offset(w * 0.5, h * 0.72), 15, _oxy,
      display: false, weight: FontWeight.w800, glow: 0.4);
  _legendReservePips(canvas, Offset(w * 0.5, h * 0.88), 4, 4, 5);
}

/// Frame 2 — PRIME: tap a low organ to arm it for the pump.
void _legendPrime(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final heart = Offset(w * 0.26, h * 0.60);
  final organ = Offset(w * 0.74, h * 0.42);
  final r = math.min(w, h) * 0.11;
  // A primed artery, lit bright.
  canvas.drawLine(
      heart,
      organ,
      Paint()
        ..color = _oxy.withValues(alpha: 0.6)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round);
  GameFx.orb(canvas, heart, r, Color.lerp(_deoxy, _oxy, 0.7)!, glow: 0.9);
  GameFx.text(canvas, 'HEART', heart.translate(0, r + 12), 10,
      Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
  _legendOrgan(canvas, organ, 0.14, 'ORGAN', low: true, primed: true, rr: r);
  GameFx.text(canvas, 'TAP TO PRIME', Offset(w * 0.5, h * 0.86), 14, _oxy,
      weight: FontWeight.w800, glow: 0.4);
}

/// Frame 3 — HEARTBEAT: double-tap (lub-dub) to pump the primed blood out.
void _legendBeat(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final heart = Offset(w * 0.30, h * 0.56);
  final r = math.min(w, h) * 0.12;
  final organs = [Offset(w * 0.72, h * 0.38), Offset(w * 0.80, h * 0.72)];
  // Lub-dub rings.
  for (final ring in const [42.0, 64.0]) {
    canvas.drawCircle(
      heart,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _oxy.withValues(alpha: ring < 50 ? 0.5 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
  for (final o in organs) {
    final pos = Offset.lerp(heart, o, 0.55)!;
    canvas.drawCircle(
        pos,
        7,
        Paint()
          ..color = _oxy.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(pos, 4.5, Paint()..color = _oxy);
  }
  GameFx.orb(canvas, heart, r, _oxy, glow: 1.3);
  GameFx.text(canvas, 'HEART', heart.translate(0, r + 12), 10,
      Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
  for (final o in organs) {
    _legendOrgan(canvas, o, 0.55, 'ORGAN', rr: r * 0.75);
  }
  GameFx.text(canvas, 'DOUBLE-TAP  ♥  LUB-DUB', Offset(w * 0.5, h * 0.90), 13,
      _oxy, weight: FontWeight.w800, glow: 0.4);
}

/// Frame 4 — EXHALE: vent the rising CO₂ before it chokes the body.
void _legendExhale(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final lungs = Offset(w * 0.38, h * 0.42);
  final r = math.min(w, h) * 0.12;
  GameFx.orb(canvas, lungs, r, _deoxy, glow: 0.8);
  GameFx.text(canvas, 'CO₂↑', lungs, 11, Colors.white.withValues(alpha: 0.9),
      weight: FontWeight.w800);
  GameFx.text(canvas, 'LUNGS', lungs.translate(0, -r - 12), 10,
      Colors.white.withValues(alpha: 0.80), weight: FontWeight.w800);
  // A high CO₂ bar (danger).
  const barH = 80.0, barW = 16.0;
  final left = lungs.dx + r + 22;
  final top = lungs.dy - barH / 2;
  final track = Rect.fromLTWH(left, top, barW, barH);
  final rr = RRect.fromRectAndRadius(track, const Radius.circular(6));
  canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.4));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top + barH * 0.15, barW, barH * 0.85),
        const Radius.circular(6)),
    Paint()..color = _danger,
  );
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25));
  GameFx.text(canvas, 'CO₂', Offset(left + barW / 2, top - 10), 10, _danger,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'HOLD  EXHALE', Offset(w * 0.5, h * 0.86), 14, _co2Col,
      weight: FontWeight.w800, glow: 0.4);
}

/// Frame 5 — CODE RED: the final surge.
void _legendCodeRed(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final heart = Offset(w * 0.28, h * 0.60);
  final r = math.min(w, h) * 0.10;
  final organs = [Offset(w * 0.68, h * 0.42), Offset(w * 0.80, h * 0.74)];
  const names = ['Brain', 'Muscle'];
  const o2s = [0.10, 0.20];
  const pops = ['+40', '+30'];
  GameFx.text(canvas, 'CODE RED ×2', Offset(w * 0.5, h * 0.16), 20,
      Potatuhs.orange,
      display: true, weight: FontWeight.w800, glow: 0.7);
  for (final o in organs) {
    canvas.drawLine(
        heart,
        o,
        Paint()
          ..color = _danger.withValues(alpha: 0.32)
          ..strokeWidth = 2);
  }
  GameFx.orb(canvas, heart, r, Color.lerp(_deoxy, _oxy, 0.4)!, glow: 0.9);
  GameFx.text(canvas, 'HEART', heart.translate(0, r + 12), 10,
      Colors.white.withValues(alpha: 0.78), weight: FontWeight.w800);
  for (var i = 0; i < organs.length; i++) {
    _legendOrgan(canvas, organs[i], o2s[i], names[i], low: true, rr: r * 0.9);
    GameFx.text(canvas, pops[i], organs[i].translate(0, -r - 12), 15,
        Potatuhs.orange,
        weight: FontWeight.w800, glow: 0.4);
  }
}

/// The visual manual for Circulate v2 — wired into the registry spec.
final List<LegendFrame> circulateV2LegendFrames = [
  const LegendFrame(
      caption: 'HOLD INHALE to draw O₂ into the reserve',
      paint: _legendInhale),
  const LegendFrame(
      caption: 'Tap a LOW organ to PRIME it for delivery',
      paint: _legendPrime),
  const LegendFrame(
      caption: 'Double-tap the heart — LUB-DUB — to pump O₂ out',
      paint: _legendBeat),
  const LegendFrame(
      caption: 'HOLD EXHALE to vent CO₂ before it chokes the body',
      paint: _legendExhale),
  const LegendFrame(
      caption: 'CODE RED: final 12s, demand spikes, every deliver ×2',
      paint: _legendCodeRed),
];
