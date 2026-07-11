import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// MEMBRANE GATE — selective-permeability tug-of-war (60 s score attack).
///
/// A phospholipid bilayer spans the screen with FOUR channel gates embedded in
/// it (Lipid · Aquaporin · Ion · Carrier). Molecules drift in a shared field
/// above the membrane. The whole game is a continuous PULL / REPEL loop:
///
///   • HOLD a gate (press & hold, or slide between them) to make it ACTIVE.
///     An active gate glows and radiates a PULL FIELD that continuously drags
///     every nearby molecule toward it. Steer the RIGHT molecule into it:
///        Lipid ← gases · Aquaporin ← water · Ion ← Na⁺/K⁺ · Carrier ← sugar/AA.
///     A molecule that reaches the gate it belongs to = imported, +score.
///     A wrong molecule dragged into a gate = rejected, penalty, gate flares red.
///   • RELEASE (no gate held) = HISTAMINE / REPEL mode. A defensive field
///     switches on across the membrane and shoves intruders (toxin/virus/…)
///     AWAY, back up out of the cell, staving them off. Wanted molecules are
///     lighter and drift back down, so you can pull them again.
///
/// The loop is a constant tug-of-war: PULL the molecules you want to their
/// correct gate, then LET GO to PUSH the ones you don't away. Multiple
/// molecules are always on screen, so the player is always choosing.
///
/// Difficulty ramps: more molecules, faster drift, more intruders, tighter
/// timing.
///
/// Teaches: selective permeability, simple diffusion (gases through the
/// lipid), osmosis (water through aquaporins), facilitated transport
/// (ions/glucose/amino acids through their matching channel & carrier gates),
/// and the immune-style repel response that keeps intruders out.
///
/// PERFORMANCE: one [Ticker] drives a single [CustomPainter] via a repaint
/// notifier. No per-frame setState.

// ─── Tuning ───────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;
const Color _kAccent = Color(0xFF4FC3F7); // membrane / transport cyan
const Color _kHistamine = Color(0xFFFF7043); // repel-field warm orange

const double _kMembraneFrac = 0.72; // membrane y as fraction of height
const double _kMolRadius = 17.0;
const double _kGateHalfW = 30.0; // horizontal reach of a gate's tap zone

const int _kGoodScore = 10;
const int _kWrongGatePenalty = 6;
const int _kIntruderReject = 4; // reward for repelling an intruder off-screen

const int _kMaxMoleculesEarly = 5;
const int _kMaxMoleculesLate = 10;
const double _kSpawnEarly = 1.15; // seconds between arrivals at t=0
const double _kSpawnLate = 0.5; // seconds between arrivals at t=end
const double _kDriftEarly = 30.0; // px/s baseline downward drift at t=0
const double _kDriftLate = 66.0; // px/s baseline downward drift at t=end
const double _kIdleSpawn = 1.9; // calm-state arrival interval

// Pull field: an active gate drags molecules toward its mouth.
const double _kPullRange = 320.0; // px radius the active gate reaches
const double _kPullAccel = 900.0; // px/s² pull acceleration at the mouth
const double _kIntakeRadius = 26.0; // reaching this near the gate mouth resolves

// Repel / histamine field (no gate held): pushes molecules up & away.
const double _kRepelAccel = 640.0; // px/s² outward on intruders near membrane
const double _kRepelBand = 200.0; // px above membrane the field acts within

const double _kDamping = 2.4; // velocity damping so motion stays controllable
const double _kMaxSpeed = 340.0; // clamp molecule speed

// ─── Gates (the pull targets embedded in the membrane) ──────────────────────
enum _Gate { lipid, aquaporin, ion, carrier }

_Gate _gateFor(_Transport t) {
  switch (t) {
    case _Transport.diffusion:
      return _Gate.lipid; // small nonpolar gases slip through the bilayer
    case _Transport.aquaporin:
      return _Gate.aquaporin;
    case _Transport.ionChannel:
      return _Gate.ion;
    case _Transport.glucoseCarrier:
    case _Transport.carrier:
      return _Gate.carrier;
  }
}

const List<_Gate> _kGateOrder = [
  _Gate.lipid,
  _Gate.aquaporin,
  _Gate.ion,
  _Gate.carrier,
];
const List<String> _kGateLabels = ['lipid', 'aquaporin', 'ion', 'carrier'];
const List<Color> _kGateColors = [
  Color(0xFFB0A48C), // lipid — warm neutral
  Color(0xFF4DD0E1), // aquaporin — water cyan
  Color(0xFFAED581), // ion channel — green
  Color(0xFFFFD54F), // carrier — glucose gold
];

// ─── Molecule taxonomy ──────────────────────────────────────────────────────
enum _Transport { diffusion, aquaporin, ionChannel, glucoseCarrier, carrier }

enum _Glyph { gasPair, gasTriple, water, ion, hexagon, amino, spiky, virus, rod, metal, blob }

class _MolDef {
  final String label;
  final Color color;
  final bool wanted;
  final _Glyph glyph;
  final _Transport transport;
  final String channel; // educational one-liner shown on intake
  const _MolDef(this.label, this.color, this.wanted, this.glyph,
      this.transport, this.channel);
}

const List<_MolDef> _kWanted = [
  _MolDef('O₂', Color(0xFFB3E5FC), true, _Glyph.gasPair, _Transport.diffusion,
      'Free diffusion'),
  _MolDef('CO₂', Color(0xFFCFD8DC), true, _Glyph.gasTriple,
      _Transport.diffusion, 'Free diffusion'),
  _MolDef('H₂O', Color(0xFF4DD0E1), true, _Glyph.water, _Transport.aquaporin,
      'Aquaporin'),
  _MolDef('Na⁺', Color(0xFFAED581), true, _Glyph.ion, _Transport.ionChannel,
      'Ion channel'),
  _MolDef('K⁺', Color(0xFFBA68C8), true, _Glyph.ion, _Transport.ionChannel,
      'Ion channel'),
  _MolDef('Glucose', Color(0xFFFFD54F), true, _Glyph.hexagon,
      _Transport.glucoseCarrier, 'Glucose transporter'),
  _MolDef('Amino', Color(0xFF4DB6AC), true, _Glyph.amino, _Transport.carrier,
      'Carrier protein'),
];

const List<_MolDef> _kUnwanted = [
  _MolDef('Toxin', Color(0xFF8BC34A), false, _Glyph.spiky, _Transport.diffusion,
      ''),
  _MolDef('Virus', Color(0xFFE040FB), false, _Glyph.virus, _Transport.diffusion,
      ''),
  _MolDef('Bacterium', Color(0xFFA1887F), false, _Glyph.rod,
      _Transport.diffusion, ''),
  _MolDef('Heavy metal', Color(0xFF78909C), false, _Glyph.metal,
      _Transport.diffusion, ''),
  _MolDef('Waste', Color(0xFFBCAAA4), false, _Glyph.blob, _Transport.diffusion,
      ''),
];

// Lookup by label so the legend can pull the EXACT _MolDef the game spawns.
_MolDef _defFor(String label) =>
    [..._kWanted, ..._kUnwanted].firstWhere((d) => d.label == label);

class _Molecule {
  Offset pos;
  Offset vel; // px/s — steered by pull/repel fields
  final _MolDef def;
  final double phase;
  bool dead = false;
  double flareGate = -1; // >=0 while being pulled by gate index (for tinting)
  _Molecule(this.pos, this.vel, this.def, this.phase);
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════
class MembraneGateGame extends StatefulWidget {
  final MiniGameSession session;
  const MembraneGateGame({super.key, required this.session});

  @override
  State<MembraneGateGame> createState() => _MembraneGateGameState();
}

class _MembraneGateGameState extends State<MembraneGateGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size? _size;
  double _time = 0;
  Duration _lastElapsed = Duration.zero;

  final List<_Molecule> _mols = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];
  final List<double> _gateGlow = [0, 0, 0, 0]; // import flash per gate
  final List<double> _gateReject = [0, 0, 0, 0]; // wrong-molecule flash per gate

  int _activeGate = -1; // gate currently held (pulling); -1 = repel mode
  double _repelPulse = 0; // brief histamine burst when the player releases
  double _spawnAcc = 0;
  int _streak = 0;
  double _flash = 0; // red penalty flash
  double _thrive = 0; // gold good-intake pulse
  double _vitality = 0.6; // 0..1 cosmetic cell health
  double _nucleusSeed = 0; // fixed per-run wobble seed for the organic nucleus

  // Autopilot state: which gate ATTRACT is currently "holding".
  int _autoHoldGate = -1;

  int get _mult => (1 + _streak ~/ 5).clamp(1, 3);
  double get _membraneY => (_size?.height ?? 600) * _kMembraneFrac;

  double _gateX(int i) {
    final w = _size?.width ?? 360;
    return w * (0.5 + i) / _kGateOrder.length;
  }

  Offset _gateCenter(int i) => Offset(_gateX(i), _membraneY);

  // Which gate (if any) sits nearest a touch point on/above the membrane band.
  int _gateNear(Offset p) {
    // Anywhere in the lower ~40% counts as steering; snap to the closest gate
    // column so sliding between gates is forgiving.
    var best = -1;
    var bestDx = _kGateHalfW + 18;
    for (var i = 0; i < _kGateOrder.length; i++) {
      final dx = (p.dx - _gateX(i)).abs();
      if (dx < bestDx) {
        bestDx = dx;
        best = i;
      }
    }
    return best;
  }

  @override
  void initState() {
    super.initState();
    _nucleusSeed = _rng.nextDouble() * math.pi * 2;
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play the pull/repel loop.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free decision per host tick. Plays the tug-of-war a competent
  /// gatekeeper would: find the most-urgent WANTED molecule (closest to the
  /// membrane), HOLD its correct gate to pull it in; when nothing wanted is
  /// pending OR an intruder is bearing down, RELEASE to repel. Deterministic:
  /// reads the game's own [_mols] and drives [_activeGate]. Host owns the clock.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    final mY = _membraneY;

    // Pick the wanted molecule most urgently near the membrane.
    _Molecule? want;
    var bestDist = double.infinity;
    // Is a nasty intruder about to hit the membrane? Then repel instead.
    var intruderClose = false;
    for (final m in _mols) {
      if (m.dead) continue;
      final gap = mY - m.pos.dy;
      if (!m.def.wanted) {
        if (gap > 0 && gap < 70) intruderClose = true;
        continue;
      }
      if (gap < -_kMolRadius) continue; // already below membrane
      if (gap < bestDist) {
        bestDist = gap;
        want = m;
      }
    }

    if (intruderClose && (want == null || bestDist > 130)) {
      _releaseGate(); // histamine sweep
      _autoHoldGate = -1;
      return;
    }
    if (want == null) {
      _releaseGate();
      _autoHoldGate = -1;
      return;
    }
    final gate = _kGateOrder.indexOf(_gateFor(want.def.transport));
    if (gate != _autoHoldGate) {
      _autoHoldGate = gate;
      _pressGate(gate);
    } else {
      _activeGate = gate; // keep holding
    }
  }

  // ─── Difficulty ───────────────────────────────────────────────────────────
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final elapsed = dur - widget.session.remaining.inMilliseconds / 1000.0;
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  // ─── Tick ─────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastElapsed = elapsed;
    _time += dt;
    if (_size != null) _update(dt);
    _repaint.tick();
  }

  void _update(double dt) {
    final running = widget.session.isRunning;
    final w = _size!.width;
    final h = _size!.height;
    final diff = _progress;
    final mY = _membraneY;

    // Between runs (intro / results): drop the hold so a fresh round is clean.
    if (!running && _activeGate != -1) _activeGate = -1;

    // Decay effect timers.
    if (_flash > 0) _flash = math.max(0, _flash - dt);
    if (_thrive > 0) _thrive = math.max(0, _thrive - dt);
    if (_repelPulse > 0) _repelPulse = math.max(0, _repelPulse - dt);
    for (var i = 0; i < _gateGlow.length; i++) {
      if (_gateGlow[i] > 0) _gateGlow[i] = math.max(0, _gateGlow[i] - dt);
      if (_gateReject[i] > 0) _gateReject[i] = math.max(0, _gateReject[i] - dt);
    }
    _vitality += (0.55 - _vitality) * (dt * 0.25);
    _vitality = _vitality.clamp(0.0, 1.0);

    // Spawn cadence + population cap both ramp with difficulty.
    final maxMols =
        _lerp(_kMaxMoleculesEarly.toDouble(), _kMaxMoleculesLate.toDouble(), diff)
            .round();
    _spawnAcc += dt;
    final interval =
        running ? _lerp(_kSpawnEarly, _kSpawnLate, diff) : _kIdleSpawn;
    if (_spawnAcc >= interval && _mols.length < maxMols) {
      _spawnAcc = 0;
      _spawn(w, diff, running);
    }

    final baseDrift = _lerp(_kDriftEarly, _kDriftLate, diff);
    final activeCenter = _activeGate >= 0 ? _gateCenter(_activeGate) : null;

    for (final m in _mols) {
      if (m.dead) continue;
      m.flareGate = -1;

      // ── Field forces ──────────────────────────────────────────────────
      var ax = 0.0;
      var ay = baseDrift * 0.6; // gentle constant settle downward

      if (running && activeCenter != null) {
        // PULL: the held gate drags this molecule toward its mouth.
        final to = activeCenter - m.pos;
        final d = to.distance;
        if (d > 1 && d < _kPullRange) {
          final strength = _kPullAccel * (1 - d / _kPullRange);
          ax += to.dx / d * strength;
          ay += to.dy / d * strength;
          m.flareGate = _activeGate.toDouble();
        }
      } else if (running) {
        // REPEL / HISTAMINE: no gate held → push things up & away from the
        // membrane. Intruders are shoved hard; wanted molecules feel a lighter
        // nudge so they can be re-pulled.
        final gap = mY - m.pos.dy; // >0 = above membrane
        if (gap >= -_kMolRadius && gap < _kRepelBand) {
          final falloff = (1 - gap / _kRepelBand).clamp(0.0, 1.0);
          final boost = 1.0 + _repelPulse * 2.2; // stronger right after release
          final push = (m.def.wanted ? 0.28 : 1.0) *
              _kRepelAccel *
              falloff *
              boost;
          ay -= push; // upward
          // Splay away from centre so the field reads as radial.
          final cx = (m.pos.dx - w / 2);
          ax += cx.sign * push * 0.35;
        }
      }

      // Integrate with damping.
      m.vel = Offset(m.vel.dx + ax * dt, m.vel.dy + ay * dt);
      final damp = math.pow(1 / (1 + _kDamping), dt).toDouble();
      m.vel = m.vel * damp;
      // Idle horizontal sway when no strong force.
      final sway = math.sin(_time * 1.1 + m.phase) * 8;
      var v = m.vel + Offset(sway, 0);
      final sp = v.distance;
      if (sp > _kMaxSpeed) v = v * (_kMaxSpeed / sp);
      m.pos = m.pos + v * dt;

      // Keep in horizontal bounds (soft bounce).
      if (m.pos.dx < 24) {
        m.pos = Offset(24, m.pos.dy);
        m.vel = Offset(m.vel.dx.abs(), m.vel.dy);
      } else if (m.pos.dx > w - 24) {
        m.pos = Offset(w - 24, m.pos.dy);
        m.vel = Offset(-m.vel.dx.abs(), m.vel.dy);
      }

      if (!running) {
        // Calm ready state: drift past and fade, no scoring.
        if (m.pos.dy > h + 30) m.dead = true;
        continue;
      }

      // ── Resolution ────────────────────────────────────────────────────
      // Repelled off the top of the screen.
      if (m.pos.dy < -_kMolRadius - 24) {
        _leaveTop(m);
        continue;
      }
      // Reached an active gate's mouth → import / reject.
      if (activeCenter != null &&
          (m.pos - activeCenter).distance < _kIntakeRadius) {
        _resolveAtGate(m, _activeGate);
        continue;
      }
      // Slipped past the membrane with no gate pulling it (or a wrong gate that
      // didn't catch it) → passive membrane resolution.
      if (m.pos.dy >= mY + _kMolRadius * 0.6) {
        _resolveAtMembrane(m);
      }
    }
    _mols.removeWhere((m) => m.dead);

    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _spawn(double w, double diff, bool running) {
    final wantedShare = _lerp(0.64, 0.46, diff);
    final wanted = _rng.nextDouble() < wantedShare || !running;
    final def = wanted
        ? _kWanted[_rng.nextInt(_kWanted.length)]
        : _kUnwanted[_rng.nextInt(_kUnwanted.length)];
    final x = 34 + _rng.nextDouble() * (w - 68);
    _mols.add(_Molecule(
      Offset(x, -_kMolRadius - 8),
      Offset((_rng.nextDouble() - 0.5) * 24, 18 + _rng.nextDouble() * 20),
      def,
      _rng.nextDouble() * math.pi * 2,
    ));
  }

  // A molecule pushed back off the top of the screen.
  void _leaveTop(_Molecule m) {
    m.dead = true;
    if (!m.def.wanted) {
      // Repelled an intruder — the defensive win. Reward it.
      const gain = _kIntruderReject;
      widget.session.addScore(gain);
      _vitality = (_vitality + 0.02).clamp(0.0, 1.0);
      _pops.add(FxPop(Offset(m.pos.dx, math.max(m.pos.dy, 20)),
          'REPELLED +$gain', _kHistamine));
    }
    // A wanted molecule blown out the top is simply lost — no penalty (the
    // player will get more); the streak isn't touched here.
  }

  // A molecule reached the mouth of the ACTIVE gate.
  void _resolveAtGate(_Molecule m, int gi) {
    m.dead = true;
    final correct = m.def.wanted && _gateFor(m.def.transport) == _kGateOrder[gi];
    if (correct) {
      _streak++;
      widget.session.noteStreak(_streak);
      final gain = _kGoodScore * _mult;
      widget.session.addScore(gain);
      _gateGlow[gi] = 0.85;
      _thrive = 0.5;
      _vitality = (_vitality + 0.05).clamp(0.0, 1.0);
      final c = _kGateColors[gi];
      final tag = _mult > 1 ? '+$gain ×$_mult' : '+$gain';
      _pops.add(FxPop(_gateCenter(gi).translate(0, -22), tag, c));
      for (var i = 0; i < 10; i++) {
        _particles.add(FxParticle(
          m.pos,
          Offset((_rng.nextDouble() - 0.5) * 60, 60 + _rng.nextDouble() * 90),
          c,
          2.4 + _rng.nextDouble() * 1.8,
        ));
      }
      if (m.def.channel.isNotEmpty) {
        _pops.add(FxPop(_gateCenter(gi).translate(0, 30), m.def.channel,
            c.withValues(alpha: 0.85)));
      }
    } else {
      // Wrong molecule pulled into a gate → hard reject.
      _streak = 0;
      _flash = 0.4;
      _gateReject[gi] = 0.6;
      _vitality = (_vitality - 0.06).clamp(0.0, 1.0);
      widget.session.addScore(-_kWrongGatePenalty);
      final label = m.def.wanted ? 'WRONG GATE' : 'INTRUDER';
      _pops.add(FxPop(_gateCenter(gi).translate(0, -22),
          '$label −$_kWrongGatePenalty', const Color(0xFFFF5252)));
      _particles.addAll(FxBurst.spawn(_gateCenter(gi), const Color(0xFFFF5252),
          count: 10, speed: 110, size: 2.6));
      // Kick it back up so it isn't instantly re-caught.
      final back = Offset((m.pos.dx - _gateX(gi)), -1).direction;
      m.vel = Offset(math.cos(back), math.sin(back)) * 220;
    }
  }

  // A molecule crossed the membrane with no gate catching it.
  void _resolveAtMembrane(_Molecule m) {
    m.dead = true;
    if (m.def.wanted) {
      // Missed nutrient — the cell starves a little; streak breaks.
      _streak = 0;
      _vitality = (_vitality - 0.05).clamp(0.0, 1.0);
      _pops.add(FxPop(m.pos, 'missed', Potatuhs.textFaint));
    } else {
      // An intruder slipped in — you should have repelled it. Penalty.
      _flash = 0.35;
      _streak = 0;
      widget.session.addScore(-_kWrongGatePenalty);
      _vitality = (_vitality - 0.08).clamp(0.0, 1.0);
      _pops.add(FxPop(Offset(m.pos.dx, _membraneY - 6),
          'BREACH −$_kWrongGatePenalty', const Color(0xFFFF5252)));
      _particles.addAll(FxBurst.spawn(Offset(m.pos.dx, _membraneY),
          const Color(0xFFFF5252),
          count: 8, speed: 90, size: 2.6));
    }
  }

  // ─── Gesture: HOLD a gate = pull · RELEASE = repel ─────────────────────────
  void _pressGate(int gi) {
    if (gi < 0) {
      _releaseGate();
      return;
    }
    _activeGate = gi;
  }

  void _releaseGate() {
    if (_activeGate != -1) {
      _repelPulse = 0.55; // a histamine burst on release
    } else if (_repelPulse <= 0) {
      _repelPulse = 0.35;
    }
    _activeGate = -1;
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    _pressGate(_gateNear(d.localPosition));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning) return;
    final g = _gateNear(d.localPosition);
    if (g == -1) {
      _releaseGate();
    } else {
      _activeGate = g;
    }
  }

  void _onPanEnd(_) => _releaseGate();

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    _pressGate(_gateNear(d.localPosition));
  }

  void _onTapUp(TapUpDetails d) => _releaseGate();
  void _onTapCancel() => _releaseGate();

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (_size == null ||
          (_size!.width - size.width).abs() > 1 ||
          (_size!.height - size.height).abs() > 1) {
        _size = size;
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: () => _releaseGate(),
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _MembraneGatePainter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════
class _MembraneGatePainter extends CustomPainter {
  final _MembraneGateGameState state;
  _MembraneGatePainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._time;
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 22);

    final mY = state._membraneY;
    _paintCytoplasm(canvas, size, mY);

    // The field cue reads FIRST so the player understands the mode they're in.
    if (state.widget.session.isRunning) {
      if (state._activeGate >= 0) {
        _paintPullField(canvas, size, state._activeGate, t);
      } else {
        _paintRepelField(canvas, size, mY, t);
      }
    }

    _paintMembrane(canvas, size, mY, t);

    for (final m in state._mols) {
      if (m.dead) continue;
      _paintMolecule(canvas, m, t);
    }

    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    _paintModeBanner(canvas, size);
    _paintHud(canvas, size);
    _paintFlash(canvas, size);

    if (!state.widget.session.isRunning) {
      _paintReady(canvas, size, mY);
    }
  }

  // ── Active-gate PULL field: converging beams + a soft bloom cone ──────────
  void _paintPullField(Canvas canvas, Size size, int gi, double t) {
    final c = _kGateColors[gi];
    final gate = state._gateCenter(gi);
    // Soft radial bloom that reads as "suction toward this gate".
    canvas.drawCircle(
      gate,
      _kPullRange * 0.9,
      Paint()
        ..shader = RadialGradient(colors: [
          c.withValues(alpha: 0.20),
          c.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: gate, radius: _kPullRange * 0.9))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    // Inflowing streamers: dashes flowing DOWN toward the gate mouth.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = c.withValues(alpha: 0.5);
    for (var k = 0; k < 5; k++) {
      final a = (t * 1.4 + k / 5) % 1.0; // 0..1 collapsing inward
      final r = _kPullRange * (1 - a) * 0.9;
      final alpha = 0.42 * a;
      canvas.drawCircle(
          gate,
          r,
          ring
            ..color = c.withValues(alpha: alpha)
            ..strokeWidth = 1.4 + 2.0 * a);
    }
  }

  // ── Histamine / REPEL field: an upward-pushing shield across the membrane ──
  void _paintRepelField(Canvas canvas, Size size, double mY, double t) {
    final intensity = (0.42 + state._repelPulse * 1.1).clamp(0.0, 1.0);
    // A warm barrier band just above the membrane, brighter right after release.
    final band = Rect.fromLTWH(0, mY - _kRepelBand, size.width, _kRepelBand);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _kHistamine.withValues(alpha: 0.16 * intensity),
            _kHistamine.withValues(alpha: 0.0),
          ],
        ).createShader(band),
    );
    // Upward chevrons drifting up to say "pushing OUT".
    final chev = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = _kHistamine.withValues(alpha: 0.28 * intensity);
    const cols = 6;
    for (var i = 0; i < cols; i++) {
      final x = size.width * (0.5 + i) / cols;
      for (var r = 0; r < 3; r++) {
        final phase = (t * 0.9 + r / 3 + i * 0.13) % 1.0;
        final y = mY - 8 - phase * (_kRepelBand - 24);
        final a = (1 - phase) * 0.5 * intensity;
        canvas.drawLine(Offset(x - 8, y + 6), Offset(x, y),
            chev..color = _kHistamine.withValues(alpha: a));
        canvas.drawLine(Offset(x + 8, y + 6), Offset(x, y),
            chev..color = _kHistamine.withValues(alpha: a));
      }
    }
  }

  // ── Cell interior ───────────────────────────────────────────────────────
  void _paintCytoplasm(Canvas canvas, Size size, double mY) {
    final vit = state._vitality;
    final healthy = Color.lerp(
        const Color(0xFF3A2A12), const Color(0xFF1A2A1A), 0)!;
    final base = Color.lerp(const Color(0xFF241A0E),
        Color.lerp(Potatuhs.orange, healthy, 1 - vit)!, 0.18)!;
    final rect = Rect.fromLTWH(0, mY, size.width, size.height - mY);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            base.withValues(alpha: 0.9),
            Potatuhs.inkDeep,
          ],
        ).createShader(rect),
    );
    final glowAmt = (0.18 + 0.5 * vit + state._thrive).clamp(0.0, 1.0);
    final nx = size.width * 0.5;
    final ny = mY + (size.height - mY) * 0.55;
    final nr = size.shortestSide * 0.15;
    _paintNucleus(canvas, Offset(nx, ny), nr, vit, glowAmt,
        state._time, state._nucleusSeed);
  }

  void _paintNucleus(Canvas canvas, Offset c, double r, double vit,
      double glowAmt, double t, double seed) {
    final core = Color.lerp(Potatuhs.sienna, Potatuhs.gold, vit)!;
    canvas.drawCircle(
      c.translate(-r * 0.15, -r * 0.15),
      r * 2.0,
      Paint()
        ..shader = RadialGradient(colors: [
          core.withValues(alpha: 0.16 * glowAmt),
          core.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: r * 2.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    final path = Path();
    const steps = 44;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * math.pi * 2;
      final wob = 1.0 +
          0.10 * math.sin(a * 3 + seed + t * 0.5) +
          0.05 * math.sin(a * 5 - seed * 1.7 - t * 0.35);
      final rr = r * wob;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr * 0.92);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(core, Colors.white, 0.42)!,
            core,
            Color.lerp(core, Colors.black, 0.5)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.15)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Color.lerp(core, Colors.white, 0.55)!
            .withValues(alpha: 0.35 + 0.35 * glowAmt),
    );
    for (var i = 0; i < 6; i++) {
      final s = seed + i * 2.3;
      final rad = r * (0.25 + 0.42 * ((s * 0.618) % 1.0));
      final ang = s * 1.7 + t * (0.2 + 0.08 * (i % 3));
      final p = c + Offset(math.cos(ang) * rad, math.sin(ang) * rad * 0.85);
      canvas.drawCircle(
          p,
          r * (0.10 + 0.05 * ((s * 0.31) % 1.0)),
          Paint()
            ..color =
                Color.lerp(core, Colors.black, 0.4)!.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    canvas.drawCircle(
      c.translate(-r * 0.22, -r * 0.26),
      r * 0.20,
      Paint()
        ..color = Color.lerp(core, Colors.white, 0.5)!
            .withValues(alpha: 0.5 + 0.3 * glowAmt)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  // ── Phospholipid bilayer + FOUR channel gates ────────────────────────────
  void _paintMembrane(Canvas canvas, Size size, double mY, double t) {
    const headR = 4.6;
    const gap = 13.0;
    final headPaint = Paint()..color = Potatuhs.orange.withValues(alpha: 0.85);
    final tailPaint = Paint()
      ..color = Potatuhs.sienna.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final topY = mY - 9;
    final botY = mY + 9;
    for (double x = gap; x < size.width; x += gap) {
      final sway = math.sin(t * 1.6 + x * 0.05) * 1.2;
      canvas.drawLine(
          Offset(x, topY + headR), Offset(x + sway * 0.4, mY - 1), tailPaint);
      canvas.drawLine(
          Offset(x, botY - headR), Offset(x - sway * 0.4, mY + 1), tailPaint);
      canvas.drawCircle(Offset(x, topY + sway * 0.3), headR, headPaint);
      canvas.drawCircle(Offset(x, botY - sway * 0.3), headR, headPaint);
    }

    final active = state._activeGate;
    for (var i = 0; i < _kGateOrder.length; i++) {
      final cx = state._gateX(i);
      final glow = state._gateGlow[i];
      final reject = state._gateReject[i];
      final col = _kGateColors[i];
      final isActive = i == active;
      final activePulse =
          isActive ? 0.55 + 0.35 * (0.5 + 0.5 * math.sin(t * 6)) : 0.0;
      final drawCol = reject > 0
          ? Color.lerp(col, const Color(0xFFFF5252), reject)!
          : col;

      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, mY), width: 30, height: 40),
          const Radius.circular(9));

      final haloAmt =
          math.max(glow, math.max(activePulse, reject)).clamp(0.0, 1.0);
      if (haloAmt > 0) {
        canvas.drawRRect(
            r,
            Paint()
              ..color = drawCol.withValues(alpha: 0.55 * haloAmt)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      }
      canvas.drawRRect(
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                drawCol.withValues(alpha: 0.5 + 0.4 * glow + 0.2 * activePulse),
                drawCol.withValues(alpha: 0.24 + 0.3 * glow + 0.12 * activePulse),
              ],
            ).createShader(r.outerRect));
      canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isActive ? 2.6 : 1.4
            ..color = Color.lerp(drawCol, Colors.white, 0.4)!
                .withValues(alpha: 0.6 + 0.4 * activePulse));
      canvas.drawLine(
          Offset(cx, mY - 15),
          Offset(cx, mY + 15),
          Paint()
            ..color = Potatuhs.inkDeep.withValues(alpha: 0.8)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
      GameFx.text(canvas, _kGateLabels[i], Offset(cx, mY + 32), 8.5,
          drawCol.withValues(alpha: 0.72 + 0.28 * math.max(glow, activePulse)));
    }
  }

  // ── Molecules ────────────────────────────────────────────────────────────
  void _paintMolecule(Canvas canvas, _Molecule m, double t) {
    final c = m.def.color;
    final p = m.pos;
    final bob = math.sin(t * 3 + m.phase) * 1.5;
    canvas.save();
    canvas.translate(p.dx, p.dy + bob);

    // Being actively pulled → a directional tint ring so it reads as "moving in".
    if (m.flareGate >= 0) {
      final pulse = 0.5 + 0.5 * math.sin(t * 7 + m.phase);
      canvas.drawCircle(
          Offset.zero,
          _kMolRadius + 8 + pulse * 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = _kGateColors[m.flareGate.toInt()]
                .withValues(alpha: 0.4 + 0.4 * pulse));
    }

    canvas.drawCircle(
        Offset.zero,
        _kMolRadius + 4,
        Paint()
          ..color = c.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));

    switch (m.def.glyph) {
      case _Glyph.gasPair:
        _orbDot(canvas, const Offset(-6, 0), 7, c);
        _orbDot(canvas, const Offset(6, 0), 7, c);
        break;
      case _Glyph.gasTriple:
        _orbDot(canvas, const Offset(-9, 0), 5.5, c.withValues(alpha: 0.9));
        _orbDot(canvas, Offset.zero, 7, c);
        _orbDot(canvas, const Offset(9, 0), 5.5, c.withValues(alpha: 0.9));
        break;
      case _Glyph.water:
        _orbDot(canvas, const Offset(0, -1), 8, c);
        _orbDot(canvas, const Offset(-8, 6), 4.5, c.withValues(alpha: 0.85));
        _orbDot(canvas, const Offset(8, 6), 4.5, c.withValues(alpha: 0.85));
        break;
      case _Glyph.ion:
        _orbDot(canvas, Offset.zero, _kMolRadius - 4, c);
        _glyphText(canvas, m.def.label, 11, Potatuhs.ink);
        break;
      case _Glyph.hexagon:
        _polygon(canvas, 6, _kMolRadius - 3, c, t * 0.4 + m.phase, fill: true);
        break;
      case _Glyph.amino:
        _polygon(canvas, 4, _kMolRadius - 4, c, math.pi / 4, fill: true);
        _glyphText(canvas, 'AA', 9, Potatuhs.ink);
        break;
      case _Glyph.spiky:
        _star(canvas, 7, _kMolRadius, _kMolRadius - 8, c);
        break;
      case _Glyph.virus:
        _orbDot(canvas, Offset.zero, _kMolRadius - 7, c);
        final spike = Paint()
          ..color = c.withValues(alpha: 0.9)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i / 8 * math.pi * 2;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(d * (_kMolRadius - 7.0), d * (_kMolRadius + 1.0), spike);
          canvas.drawCircle(d * (_kMolRadius + 2.0), 1.8, spike);
        }
        break;
      case _Glyph.rod:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: _kMolRadius * 2.0, height: 13),
                const Radius.circular(6.5)),
            Paint()..color = c);
        canvas.drawLine(
            const Offset(_kMolRadius, 0),
            const Offset(_kMolRadius + 9, -4),
            Paint()
              ..color = c.withValues(alpha: 0.8)
              ..strokeWidth = 1.6);
        break;
      case _Glyph.metal:
        _polygon(canvas, 6, _kMolRadius - 4, c, 0, fill: true);
        _orbDot(canvas, Offset.zero, 4, const Color(0xFFFF5252));
        break;
      case _Glyph.blob:
        _polygon(canvas, 9, _kMolRadius - 5, c, m.phase, fill: true, wobble: 0.18);
        break;
    }
    canvas.restore();

    GameFx.text(canvas, m.def.label, p.translate(0, _kMolRadius + 9 + bob), 8.5,
        c.withValues(alpha: 0.85));
  }

  void _orbDot(Canvas canvas, Offset at, double r, Color c) {
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(c, Colors.white, 0.5)!, c],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  void _glyphText(Canvas canvas, String s, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  void _polygon(Canvas canvas, int sides, double r, Color c, double rot,
      {bool fill = false, double wobble = 0}) {
    final path = Path();
    for (var i = 0; i <= sides; i++) {
      final a = rot + i / sides * math.pi * 2;
      final rr = r * (1 + wobble * math.sin(a * 3));
      final pt = Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    if (fill) {
      canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [Color.lerp(c, Colors.white, 0.35)!, c],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Color.lerp(c, Colors.white, 0.4)!.withValues(alpha: 0.8));
  }

  void _star(Canvas canvas, int points, double outer, double inner, Color c) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = i / (points * 2) * math.pi * 2 - math.pi / 2;
      final r = i.isEven ? outer : inner;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Color.lerp(c, Colors.white, 0.5)!);
  }

  // ── Mode banner: tells the player which field is live ────────────────────
  void _paintModeBanner(Canvas canvas, Size size) {
    if (!state.widget.session.isRunning) return;
    final pulling = state._activeGate >= 0;
    final label = pulling
        ? 'PULLING → ${_kGateLabels[state._activeGate]}'
        : 'HISTAMINE — repelling';
    final col = pulling ? _kGateColors[state._activeGate] : _kHistamine;
    GameFx.text(canvas, label, Offset(size.width / 2, 20), 12.5, col,
        weight: FontWeight.w800, glow: 0.4);
  }

  // ── HUD: streak multiplier ───────────────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    if (state._streak < 5) return;
    final label = 'STREAK ×${state._mult}';
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Potatuhs.gold)),
      textDirection: TextDirection.ltr,
    )..layout();
    final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 14, tp.width + 18, tp.height + 10),
        const Radius.circular(8));
    canvas.drawRRect(
        pillRect, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.8));
    canvas.drawRRect(
        pillRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Potatuhs.gold.withValues(alpha: 0.6));
    tp.paint(canvas, const Offset(23, 19));
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (state._flash <= 0) return;
    final a = (state._flash / 0.45) * 0.22;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFFF1744).withValues(alpha: a));
  }

  // ── Calm ready state ─────────────────────────────────────────────────────
  void _paintReady(Canvas canvas, Size size, double mY) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.35));
    final cy = mY * 0.34;
    GameFx.text(canvas, 'MEMBRANE GATE',
        Offset(size.width / 2, cy), 26, Potatuhs.textPrimary,
        display: true, glow: 0.4);
    GameFx.text(canvas, 'HOLD a gate to PULL the right molecules in',
        Offset(size.width / 2, cy + 30), 13, _kAccent);
    GameFx.text(canvas, 'slide between gates to steer what you want',
        Offset(size.width / 2, cy + 50), 12, Potatuhs.textSecondary);
    GameFx.text(canvas, 'LET GO to trigger HISTAMINE — repel intruders away',
        Offset(size.width / 2, cy + 74), 13, _kHistamine);
    GameFx.text(canvas, 'lipid←gases · aquaporin←water · ion←Na⁺/K⁺ · carrier←sugar/AA',
        Offset(size.width / 2, cy + 96), 10.5, Potatuhs.textFaint);
  }

  @override
  bool shouldRepaint(covariant _MembraneGatePainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each is drawn with the SAME
// molecule defs, colors and glyph shapes the live game uses.
// ═══════════════════════════════════════════════════════════════════════════

void _lgOrb(Canvas canvas, Offset at, double r, Color c) {
  if (r <= 0) return;
  canvas.drawCircle(
    at,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [Color.lerp(c, Colors.white, 0.5)!, c],
      ).createShader(Rect.fromCircle(center: at, radius: r)),
  );
}

void _lgGlyphText(Canvas canvas, String s, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(
        text: s,
        style: TextStyle(
            fontFamily: _kFont,
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
}

void _lgPolygon(Canvas canvas, int sides, double r, Color c, double rot,
    {double wobble = 0}) {
  if (r <= 0) return;
  final path = Path();
  for (var i = 0; i <= sides; i++) {
    final a = rot + i / sides * math.pi * 2;
    final rr = r * (1 + wobble * math.sin(a * 3));
    final pt = Offset(math.cos(a) * rr, math.sin(a) * rr);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Color.lerp(c, Colors.white, 0.35)!, c],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
  canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(c, Colors.white, 0.4)!.withValues(alpha: 0.8));
}

void _lgStar(Canvas canvas, int points, double outer, double inner, Color c) {
  if (outer <= 0) return;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = i / (points * 2) * math.pi * 2 - math.pi / 2;
    final r = i.isEven ? outer : inner;
    final pt = Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = c);
  canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(c, Colors.white, 0.5)!);
}

void _lgMolecule(Canvas canvas, Offset center, _MolDef def,
    {double scale = 1.0, bool showLabel = true}) {
  final c = def.color;
  final rad = _kMolRadius * scale;
  if (rad <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);

  canvas.drawCircle(
      Offset.zero,
      _kMolRadius + 4,
      Paint()
        ..color = c.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));

  switch (def.glyph) {
    case _Glyph.gasPair:
      _lgOrb(canvas, const Offset(-6, 0), 7, c);
      _lgOrb(canvas, const Offset(6, 0), 7, c);
      break;
    case _Glyph.gasTriple:
      _lgOrb(canvas, const Offset(-9, 0), 5.5, c.withValues(alpha: 0.9));
      _lgOrb(canvas, Offset.zero, 7, c);
      _lgOrb(canvas, const Offset(9, 0), 5.5, c.withValues(alpha: 0.9));
      break;
    case _Glyph.water:
      _lgOrb(canvas, const Offset(0, -1), 8, c);
      _lgOrb(canvas, const Offset(-8, 6), 4.5, c.withValues(alpha: 0.85));
      _lgOrb(canvas, const Offset(8, 6), 4.5, c.withValues(alpha: 0.85));
      break;
    case _Glyph.ion:
      _lgOrb(canvas, Offset.zero, _kMolRadius - 4, c);
      _lgGlyphText(canvas, def.label, 11, Potatuhs.ink);
      break;
    case _Glyph.hexagon:
      _lgPolygon(canvas, 6, _kMolRadius - 3, c, 0.4);
      break;
    case _Glyph.amino:
      _lgPolygon(canvas, 4, _kMolRadius - 4, c, math.pi / 4);
      _lgGlyphText(canvas, 'AA', 9, Potatuhs.ink);
      break;
    case _Glyph.spiky:
      _lgStar(canvas, 7, _kMolRadius, _kMolRadius - 8, c);
      break;
    case _Glyph.virus:
      _lgOrb(canvas, Offset.zero, _kMolRadius - 7, c);
      final spike = Paint()
        ..color = c.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(d * (_kMolRadius - 7.0), d * (_kMolRadius + 1.0), spike);
        canvas.drawCircle(d * (_kMolRadius + 2.0), 1.8, spike);
      }
      break;
    case _Glyph.rod:
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: _kMolRadius * 2.0, height: 13),
              const Radius.circular(6.5)),
          Paint()..color = c);
      break;
    case _Glyph.metal:
      _lgPolygon(canvas, 6, _kMolRadius - 4, c, 0);
      _lgOrb(canvas, Offset.zero, 4, const Color(0xFFFF5252));
      break;
    case _Glyph.blob:
      _lgPolygon(canvas, 9, _kMolRadius - 5, c, 0.7, wobble: 0.18);
      break;
  }
  canvas.restore();

  if (showLabel) {
    GameFx.text(canvas, def.label,
        center.translate(0, (_kMolRadius + 10) * scale), 8.5 * scale,
        c.withValues(alpha: 0.9));
  }
}

/// A horizontal slice of the bilayer with the four channel gates.
void _lgMembrane(Canvas canvas, Size size, double y, {bool channels = true}) {
  const headR = 4.6;
  const gap = 13.0;
  final headPaint = Paint()..color = Potatuhs.orange.withValues(alpha: 0.85);
  final tailPaint = Paint()
    ..color = Potatuhs.sienna.withValues(alpha: 0.5)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  final topY = y - 9;
  final botY = y + 9;
  for (double x = gap; x < size.width; x += gap) {
    canvas.drawLine(Offset(x, topY + headR), Offset(x, y - 1), tailPaint);
    canvas.drawLine(Offset(x, botY - headR), Offset(x, y + 1), tailPaint);
    canvas.drawCircle(Offset(x, topY), headR, headPaint);
    canvas.drawCircle(Offset(x, botY), headR, headPaint);
  }
  if (!channels) return;
  for (var i = 0; i < _kGateOrder.length; i++) {
    final cx = size.width * (0.5 + i) / _kGateOrder.length;
    final col = _kGateColors[i];
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: 28, height: 38),
        const Radius.circular(9));
    canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              col.withValues(alpha: 0.55),
              col.withValues(alpha: 0.28),
            ],
          ).createShader(r.outerRect));
    canvas.drawLine(
        Offset(cx, y - 14),
        Offset(cx, y + 14),
        Paint()
          ..color = Potatuhs.inkDeep.withValues(alpha: 0.8)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    GameFx.text(canvas, _kGateLabels[i], Offset(cx, y + 30), 8.0,
        col.withValues(alpha: 0.85));
  }
}

// Frame 1 — HOLD a gate to PULL the right molecule in.
void _legendPull(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final mY = size.height * 0.80;
  _lgMembrane(canvas, size, mY);
  // Carrier gate (index 3) is held & glowing; pull streamers converge on it.
  final gate = Offset(size.width * (0.5 + 3) / _kGateOrder.length, mY);
  final glow = RRect.fromRectAndRadius(
      Rect.fromCenter(center: gate, width: 32, height: 42),
      const Radius.circular(9));
  canvas.drawRRect(
      glow,
      Paint()
        ..color = _kGateColors[3].withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  // Glucose being sucked toward it.
  final mol = Offset(size.width * 0.5, size.height * 0.34);
  canvas.drawLine(
      mol,
      gate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = _kGateColors[3].withValues(alpha: 0.7));
  _lgMolecule(canvas, mol, _defFor('Glucose'), scale: 1.1);
  GameFx.text(canvas, 'HOLD a gate → it PULLS the right molecule in',
      Offset(size.width * 0.5, size.height * 0.14), 12.5, _kGateColors[3],
      weight: FontWeight.w800);
}

// Frame 2 — the gate map: each molecule has ONE correct gate.
void _legendMap(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final mY = size.height * 0.78;
  _lgMembrane(canvas, size, mY);
  final pairs = <List<dynamic>>[
    ['O₂', 0], ['H₂O', 1], ['Na⁺', 2], ['Glucose', 3],
  ];
  for (final pr in pairs) {
    final gi = pr[1] as int;
    final gx = size.width * (0.5 + gi) / _kGateOrder.length;
    final at = Offset(gx, size.height * 0.34);
    _lgMolecule(canvas, at, _defFor(pr[0] as String), scale: 0.9,
        showLabel: false);
    canvas.drawLine(
        at.translate(0, 14),
        Offset(gx, mY - 18),
        Paint()
          ..color = _kGateColors[gi]
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round);
  }
  GameFx.text(canvas, 'gases→lipid · water→aquaporin · ions→ion · sugar→carrier',
      Offset(size.width * 0.5, size.height * 0.13), 11, Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

// Frame 3 — LET GO = HISTAMINE, repel intruders away.
void _legendRepel(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final mY = size.height * 0.82;
  _lgMembrane(canvas, size, mY);
  // Repel band + up-chevrons.
  final band = Rect.fromLTWH(0, mY - size.height * 0.5, size.width,
      size.height * 0.5);
  canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _kHistamine.withValues(alpha: 0.20),
            _kHistamine.withValues(alpha: 0.0),
          ],
        ).createShader(band));
  final toxin = _defFor('Toxin');
  final tp = Offset(size.width * 0.5, size.height * 0.40);
  _lgMolecule(canvas, tp, toxin, showLabel: false);
  // Up-arrow shoving it out.
  final arrow = Paint()
    ..color = _kHistamine
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(tp.translate(0, -22), tp.translate(0, -56), arrow);
  canvas.drawLine(tp.translate(-8, -46), tp.translate(0, -56), arrow);
  canvas.drawLine(tp.translate(8, -46), tp.translate(0, -56), arrow);
  GameFx.text(canvas, 'LET GO → HISTAMINE pushes intruders AWAY',
      Offset(size.width * 0.5, size.height * 0.14), 12.5, _kHistamine,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'repel one off-screen: +4',
      Offset(size.width * 0.5, mY + 34), 11,
      _kHistamine.withValues(alpha: 0.9));
}

// Frame 4 — the tug-of-war: pull good, push bad, faster & thicker.
void _legendTug(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final mY = size.height * 0.84;
  _lgMembrane(canvas, size, mY, channels: false);
  final field = <List<dynamic>>[
    ['O₂', 0.18, 0.24], ['Toxin', 0.42, 0.20], ['K⁺', 0.66, 0.26],
    ['Waste', 0.84, 0.22], ['Amino', 0.30, 0.46], ['Heavy metal', 0.55, 0.50],
    ['CO₂', 0.78, 0.52], ['Bacterium', 0.20, 0.66], ['Glucose', 0.48, 0.68],
    ['Virus', 0.74, 0.66],
  ];
  for (final m in field) {
    _lgMolecule(canvas, Offset(size.width * (m[1] as double),
        size.height * (m[2] as double)), _defFor(m[0] as String),
        scale: 0.7, showLabel: false);
  }
  GameFx.text(canvas, 'Pull the good in, push the bad out — it speeds up',
      Offset(size.width * 0.5, size.height * 0.12), 12.5, Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

/// The visual manual for Membrane Gate — wired into the registry spec.
final List<LegendFrame> membraneGateLegendFrames = [
  const LegendFrame(
      caption: 'Hold a gate to PULL the right molecule into it',
      paint: _legendPull),
  const LegendFrame(
      caption: 'Each molecule has one correct gate — steer it there',
      paint: _legendMap),
  const LegendFrame(
      caption: 'Let go to trigger HISTAMINE and repel intruders away',
      paint: _legendRepel),
  const LegendFrame(
      caption: 'Pull the good in, push the bad out — it speeds up',
      paint: _legendTug),
];
