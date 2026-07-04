import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// MEMBRANE GATE v2 — selective-permeability arcade, UX-passed.
///
/// Same lesson as v1 (selective permeability: import what the cell needs by the
/// correct transport route; keep toxins out), rebuilt to clear the
/// Fun-Multiplayer UX bar. The teardown named three killers — this build fixes
/// all three and adds fair scoring + a climax.
///
/// WHAT CHANGED vs the original (see AGENT.md for the full list):
///   1. LEGIBILITY — wanted vs unwanted are now sorted PRE-ATTENTIVELY by
///      silhouette + luminosity + an explicit affordance badge, not hue:
///        • WANTED  → bright/luminous body, smooth round silhouette, a pulsing
///          cyan IMPORT RING and a down-chevron ("pull me in").
///        • UNWANTED → desaturated/muddy body, jagged irregular outline, a red
///          HAZARD ✕ badge ("hands off"). Na⁺ was recoloured off green so it
///          can never collide with Toxin again.
///   2. LIVE SCORE — a large in-widget score, a PACE bar (you vs par), and an
///      always-on multiplier pill. The game never depends on host chrome for
///      the number that decides it.
///   3. FAIR SCORING — tapping a toxin no longer drives the score negative; it
///      resets the streak and triggers a short import LOCKOUT (a readable, fair
///      punish). The multiplier ceiling is lifted (×1→×6) and a PERFECT bonus
///      rewards catching molecules high, so a clean run keeps paying off.
///   4. CATCH-UP — when you fall behind par the membrane slows arrivals and a
///      high-value golden RESCUE nutrient drifts in, keeping party rounds tense.
///   5. CLIMAX — the final 10 s shift to a red "FINAL PUSH" surge, and a single
///      big FINAL MOLECULE beat lands before the buzzer.
///
/// Education preserved: the wanted taxonomy, the three channel proteins that
/// light by transport type, and the per-intake route one-liner all remain.
///
/// PERFORMANCE: one [Ticker] drives one [CustomPainter] via a repaint notifier.
/// No per-frame setState. Haptics are fire-and-forget (no-op on web).

// ─── Tuning ───────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;
const Color _kAccent = Color(0xFF4FC3F7); // membrane / import cyan
const Color _kHazard = Color(0xFFFF5252); // toxin / hazard red

const double _kMembraneFrac = 0.66; // membrane y as fraction of height
const double _kMolRadius = 18.0;
const double _kHitPad = 26.0; // tap forgiveness around a molecule

const double _kSpawnEarly = 1.05; // seconds between arrivals at t=0
const double _kSpawnLate = 0.46; // seconds between arrivals at t=end
const double _kSpawnClimax = 0.30; // arrival interval during the final surge
const double _kFallEarly = 76.0; // px/s descent at t=0
const double _kFallLate = 188.0; // px/s descent at t=end
const double _kIdleSpawn = 1.7; // calm-state arrival interval

const int _kGoodScore = 10;
const int _kPerfectBonus = 6; // caught high, before mid-fall
const int _kMaxMolecules = 14;
const double _kLockout = 0.85; // seconds you cannot import after a toxin tap

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

// WANTED — one luminous, cool/gold palette family. Na⁺/K⁺ recoloured off green
// so they cannot collide with the (now muddy) Toxin. Channel slots:
// 0 = aquaporin, 1 = glucose carrier, 2 = ion channel.
const List<_MolDef> _kWanted = [
  _MolDef('O₂', Color(0xFF7FE9FF), true, _Glyph.gasPair, _Transport.diffusion,
      'Free diffusion'),
  _MolDef('CO₂', Color(0xFFB3F0FF), true, _Glyph.gasTriple,
      _Transport.diffusion, 'Free diffusion'),
  _MolDef('H₂O', Color(0xFF34C9F0), true, _Glyph.water, _Transport.aquaporin,
      'Aquaporin'),
  _MolDef('Na⁺', Color(0xFF5C9DFF), true, _Glyph.ion, _Transport.ionChannel,
      'Ion channel'),
  _MolDef('K⁺', Color(0xFF8AA0FF), true, _Glyph.ion, _Transport.ionChannel,
      'Ion channel'),
  _MolDef('Glucose', Color(0xFFFFD54F), true, _Glyph.hexagon,
      _Transport.glucoseCarrier, 'Glucose transporter'),
  _MolDef('Amino', Color(0xFF4DE0C8), true, _Glyph.amino, _Transport.carrier,
      'Carrier protein'),
];

// UNWANTED — one desaturated, muddy, jagged family. Distinct silhouettes AND a
// shared hazard look, so the eye rejects them without reading a label.
const List<_MolDef> _kUnwanted = [
  _MolDef('Toxin', Color(0xFF6E7B5A), false, _Glyph.spiky, _Transport.diffusion,
      ''),
  _MolDef('Virus', Color(0xFF8A6E84), false, _Glyph.virus, _Transport.diffusion,
      ''),
  _MolDef('Bacterium', Color(0xFF8A7A6D), false, _Glyph.rod,
      _Transport.diffusion, ''),
  _MolDef('Heavy metal', Color(0xFF6B7782), false, _Glyph.metal,
      _Transport.diffusion, ''),
  _MolDef('Waste', Color(0xFF7C7068), false, _Glyph.blob, _Transport.diffusion,
      ''),
];

class _Molecule {
  Offset pos;
  double vx;
  double speed;
  final _MolDef def;
  final double phase;
  final double scale; // rescue molecules are bigger
  final bool rescue; // high-value catch-up nutrient
  bool dead = false;
  _Molecule(this.pos, this.vx, this.speed, this.def, this.phase,
      {this.scale = 1.0, this.rescue = false});

  double get radius => _kMolRadius * scale;
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════
class MembraneGateV2Game extends StatefulWidget {
  final MiniGameSession session;
  const MembraneGateV2Game({super.key, required this.session});

  @override
  State<MembraneGateV2Game> createState() => _MembraneGateV2GameState();
}

class _MembraneGateV2GameState extends State<MembraneGateV2Game>
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
  final List<double> _channelGlow = [0, 0, 0];

  double _spawnAcc = 0;
  int _streak = 0;
  double _flash = 0; // red toxin-intake flash
  double _thrive = 0; // gold good-intake pulse
  double _vitality = 0.6; // 0..1 cosmetic cell health
  double _lockout = 0; // seconds remaining where imports are blocked
  double _shake = 0; // screen-shake impulse on a toxin
  double _rescueCooldown = 4; // seconds before another rescue can drift in
  bool _climaxHit = false; // one-shot climax announce + haptic
  bool _finalBeat = false; // one-shot final-molecule spawn

  // Multiplier ceiling lifted to ×6 (was ×3); climbs every 4 clean imports.
  int get _mult => (1 + _streak ~/ 4).clamp(1, 6);
  double get _membraneY => (_size?.height ?? 600) * _kMembraneFrac;

  // The realistic per-round pace target, used for the PACE bar + catch-up.
  int get _humanMax {
    final m = widget.session.spec.humanMax;
    return m > 0 ? m : 800;
  }

  int get _par => (_humanMax * _progress * 0.88).round();
  bool get _behind => widget.session.score < _par - _humanMax * 0.08;

  bool get _isClimax =>
      widget.session.isRunning && widget.session.remaining.inSeconds <= 10;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: the game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it hands-free). See
    // [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── ATTRACT autopilot ──────────────────────────────────────────────────
  /// One correct, deterministic move per host tick (~250ms). This plays the
  /// game the way a good player does: it IMPORTS the wanted molecules and
  /// NEVER taps a toxin (letting the membrane bounce it). It targets the
  /// wanted molecule nearest the membrane — the one about to be missed — and
  /// imports it through the game's own [_act] handler. No synthetic taps, no
  /// randomness. Molecules that reach the membrane are already resolved in
  /// [_update], so every live wanted molecule here is still catchable.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    // Imports are blocked during a post-toxin lockout — but the bot never taps
    // toxins, so this stays 0; guard anyway to avoid a wasted 'locked' beat.
    if (_lockout > 0) return;
    _Molecule? target;
    var lowest = double.negativeInfinity; // largest dy = nearest the membrane
    for (final m in _mols) {
      if (m.dead || !m.def.wanted) continue; // toxins: do nothing, let them bounce
      if (m.pos.dy > lowest) {
        lowest = m.pos.dy;
        target = m;
      }
    }
    if (target == null) return; // nothing to import this tick
    _act(target); // wanted → import + score, via the game's own handler
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
    final diff = _progress;

    // Decay effect timers.
    if (_flash > 0) _flash = math.max(0, _flash - dt);
    if (_thrive > 0) _thrive = math.max(0, _thrive - dt);
    if (_lockout > 0) _lockout = math.max(0, _lockout - dt);
    if (_shake > 0) _shake = math.max(0, _shake - dt * 6);
    if (_rescueCooldown > 0) _rescueCooldown = math.max(0, _rescueCooldown - dt);
    for (var i = 0; i < _channelGlow.length; i++) {
      if (_channelGlow[i] > 0) {
        _channelGlow[i] = math.max(0, _channelGlow[i] - dt);
      }
    }
    // Vitality drifts gently toward a baseline.
    _vitality += (0.55 - _vitality) * (dt * 0.25);
    _vitality = _vitality.clamp(0.0, 1.0);

    // Climax one-shot: announce the final push.
    if (running && _isClimax && !_climaxHit) {
      _climaxHit = true;
      _pops.add(FxPop(Offset(w / 2, _membraneY * 0.5), 'FINAL PUSH!', _kHazard));
      HapticFeedback.mediumImpact();
    }
    // Final-molecule beat: one big glowing nutrient just before the buzzer.
    if (running && !_finalBeat && widget.session.remaining.inMilliseconds <= 2600) {
      _finalBeat = true;
      _spawnRescue(w, big: true);
    }

    // Catch-up: a trailing player gets a high-value rescue nutrient.
    if (running && _behind && _rescueCooldown <= 0 && _mols.length < _kMaxMolecules) {
      _rescueCooldown = 6.5;
      _spawnRescue(w);
    }

    // Spawn cadence (surges in the climax).
    _spawnAcc += dt;
    final interval = !running
        ? _kIdleSpawn
        : _isClimax
            ? _kSpawnClimax
            : _lerp(_kSpawnEarly, _kSpawnLate, diff);
    if (_spawnAcc >= interval && _mols.length < _kMaxMolecules) {
      _spawnAcc = 0;
      _spawn(w, diff, running);
    }

    // Behind-par trailing players fall a touch slower (a gentle hand).
    final fallScale = (running && _behind) ? 0.85 : 1.0;
    final fall = _lerp(_kFallEarly, _kFallLate, diff) * fallScale;
    final mY = _membraneY;
    for (final m in _mols) {
      m.pos = Offset(
        m.pos.dx + m.vx * dt * 14 * math.sin(_time * 1.3 + m.phase),
        m.pos.dy + m.speed * fall / _kFallEarly * dt,
      );
      if (m.dead) continue;
      if (running) {
        if (m.pos.dy >= mY - m.radius) {
          _resolveAtMembrane(m);
        }
      } else {
        if (m.pos.dy > _size!.height + 30) m.dead = true;
      }
    }
    _mols.removeWhere((m) => m.dead);

    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _spawn(double w, double diff, bool running) {
    // Share of unwanted/mimic molecules grows with difficulty.
    final wantedShare = _lerp(0.62, 0.46, diff);
    final wanted = _rng.nextDouble() < wantedShare || !running;
    final def = wanted
        ? _kWanted[_rng.nextInt(_kWanted.length)]
        : _kUnwanted[_rng.nextInt(_kUnwanted.length)];
    final x = 32 + _rng.nextDouble() * (w - 64);
    _mols.add(_Molecule(
      Offset(x, -_kMolRadius - 10),
      (_rng.nextDouble() - 0.5),
      0.85 + _rng.nextDouble() * 0.4,
      def,
      _rng.nextDouble() * math.pi * 2,
    ));
  }

  // A golden glucose "rescue" nutrient: bigger, slower, worth ×3 — the catch-up.
  void _spawnRescue(double w, {bool big = false}) {
    final def = _kWanted[5]; // Glucose
    final x = 40 + _rng.nextDouble() * (w - 80);
    _mols.add(_Molecule(
      Offset(x, -_kMolRadius - 12),
      (_rng.nextDouble() - 0.5) * 0.6,
      big ? 0.62 : 0.74,
      def,
      _rng.nextDouble() * math.pi * 2,
      scale: big ? 1.7 : 1.4,
      rescue: true,
    ));
  }

  void _resolveAtMembrane(_Molecule m) {
    m.dead = true;
    if (m.def.wanted) {
      // Missed nutrient — the cell starves a little. No score penalty, but the
      // streak breaks and vitality dips.
      _streak = 0;
      _vitality = (_vitality - 0.06).clamp(0.0, 1.0);
      _pops.add(FxPop(m.pos, 'missed', Potatuhs.textFaint));
    } else {
      // Membrane correctly blocked an intruder — satisfying bounce.
      _vitality = (_vitality + 0.02).clamp(0.0, 1.0);
      _particles.addAll(FxBurst.spawn(
          Offset(m.pos.dx, _membraneY), _kAccent,
          count: 6, speed: 70, size: 2.4));
      _pops.add(FxPop(Offset(m.pos.dx, _membraneY - 6), 'blocked',
          _kAccent.withValues(alpha: 0.9)));
    }
  }

  // ─── Gesture ──────────────────────────────────────────────────────────────
  void _onTapUp(TapUpDetails d) {
    if (!widget.session.isRunning || _size == null) return;
    final p = d.localPosition;
    if (p.dy >= _membraneY) return; // taps below the membrane do nothing
    _Molecule? hit;
    var best = double.infinity;
    for (final m in _mols) {
      if (m.dead) continue;
      final dist = (m.pos - p).distance;
      if (dist < m.radius + _kHitPad && dist < best) {
        best = dist;
        hit = m;
      }
    }
    if (hit == null) return;
    _act(hit);
  }

  void _act(_Molecule m) {
    final session = widget.session;
    if (m.def.wanted) {
      // Import is blocked during a toxin lockout — a readable, fair punish.
      if (_lockout > 0) {
        _pops.add(FxPop(m.pos, 'locked', Potatuhs.textFaint));
        return;
      }
      m.dead = true;
      _streak++;
      session.noteStreak(_streak);

      // PERFECT: caught high, before the molecule passes the upper third.
      final perfect = m.pos.dy < _membraneY * 0.5;
      var gain = _kGoodScore * _mult;
      if (perfect) gain += _kPerfectBonus * _mult;
      if (m.rescue) gain *= 3;
      if (_isClimax) gain = (gain * 1.5).round();

      session.addScore(gain);
      _thrive = 0.5;
      _vitality = (_vitality + (m.rescue ? 0.10 : 0.05)).clamp(0.0, 1.0);
      _lightChannel(m.def.transport);
      HapticFeedback.lightImpact();

      // Slurp the molecule down through the membrane into the cell.
      for (var i = 0; i < 10; i++) {
        _particles.add(FxParticle(
          m.pos,
          Offset((_rng.nextDouble() - 0.5) * 60, 60 + _rng.nextDouble() * 90),
          m.def.color,
          2.4 + _rng.nextDouble() * 1.8,
        ));
      }
      final tag = perfect
          ? 'PERFECT +$gain'
          : (m.rescue ? 'RESCUE +$gain' : (_mult > 1 ? '+$gain ×$_mult' : '+$gain'));
      _pops.add(FxPop(m.pos, tag, m.rescue ? Potatuhs.gold : m.def.color));
      if (m.def.channel.isNotEmpty) {
        _pops.add(FxPop(m.pos.translate(0, 18), m.def.channel,
            m.def.color.withValues(alpha: 0.78)));
      }
    } else {
      // Toxin tapped: NO negative score (fair). Reset streak + short lockout.
      m.dead = true;
      _streak = 0;
      _lockout = _kLockout;
      _flash = 0.45;
      _shake = 1.0;
      _vitality = (_vitality - 0.12).clamp(0.0, 1.0);
      HapticFeedback.heavyImpact();
      _particles.addAll(FxBurst.spawn(m.pos, _kHazard, count: 14, speed: 130, size: 3));
      _pops.add(FxPop(m.pos, 'TOXIN! streak lost', _kHazard));
    }
  }

  void _lightChannel(_Transport t) {
    switch (t) {
      case _Transport.aquaporin:
        _channelGlow[0] = 0.7;
        break;
      case _Transport.glucoseCarrier:
      case _Transport.carrier:
        _channelGlow[1] = 0.7;
        break;
      case _Transport.ionChannel:
        _channelGlow[2] = 0.7;
        break;
      case _Transport.diffusion:
        break; // gases slip straight through the lipid
    }
  }

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
        onTapUp: _onTapUp,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _MembraneGateV2Painter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════
class _MembraneGateV2Painter extends CustomPainter {
  final _MembraneGateV2GameState state;
  _MembraneGateV2Painter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._time;
    final climax = state._isClimax;

    // Screen shake on toxin impact.
    final shake = state._shake;
    if (shake > 0) {
      canvas.save();
      canvas.translate(
        math.sin(t * 90) * shake * 5,
        math.cos(t * 80) * shake * 4,
      );
    }

    GameFx.atmosphere(canvas, size, climax ? _kHazard : _kAccent, t,
        motes: 22);

    final mY = state._membraneY;
    _paintCytoplasm(canvas, size, mY);
    _paintMembrane(canvas, size, mY, t);

    for (final m in state._mols) {
      if (m.dead) continue;
      _paintMolecule(canvas, m, t);
    }

    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    if (shake > 0) canvas.restore();

    // Climax vignette (drawn over the shake, fixed to the frame).
    if (climax) _paintClimaxVignette(canvas, size, t);

    _paintScoreHud(canvas, size);
    _paintFlash(canvas, size);

    if (!state.widget.session.isRunning) {
      _paintReady(canvas, size, mY);
    }
  }

  // ── Cell interior ───────────────────────────────────────────────────────
  void _paintCytoplasm(Canvas canvas, Size size, double mY) {
    final vit = state._vitality;
    final healthy =
        Color.lerp(const Color(0xFF3A2A12), const Color(0xFF1A2A1A), 0)!;
    final base = Color.lerp(const Color(0xFF241A0E),
        Color.lerp(Potatuhs.orange, healthy, 1 - vit)!, 0.18)!;
    final rect = Rect.fromLTWH(0, mY, size.width, size.height - mY);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base.withValues(alpha: 0.9), Potatuhs.inkDeep],
        ).createShader(rect),
    );
    final glowAmt = (0.18 + 0.5 * vit + state._thrive).clamp(0.0, 1.0);
    final nx = size.width * 0.5;
    final ny = mY + (size.height - mY) * 0.62;
    final nr = size.shortestSide * 0.16;
    canvas.drawCircle(
      Offset(nx, ny),
      nr * 1.8,
      Paint()
        ..shader = RadialGradient(colors: [
          Potatuhs.gold.withValues(alpha: 0.10 * glowAmt),
          Potatuhs.gold.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: Offset(nx, ny), radius: nr * 1.8)),
    );
    GameFx.orb(canvas, Offset(nx, ny), nr,
        Color.lerp(Potatuhs.sienna, Potatuhs.gold, vit)!,
        glow: 0.4 + 0.4 * glowAmt);
  }

  // ── Phospholipid bilayer + channel proteins ─────────────────────────────
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

    const labels = ['aquaporin', 'glucose', 'ion channel'];
    const cols = [Color(0xFF34C9F0), Color(0xFFFFD54F), Color(0xFF5C9DFF)];
    final slots = [0.25, 0.5, 0.75];
    for (var i = 0; i < slots.length; i++) {
      final cx = size.width * slots[i];
      final glow = state._channelGlow[i];
      final col = cols[i];
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, mY), width: 22, height: 30),
          const Radius.circular(8));
      if (glow > 0) {
        canvas.drawRRect(
            r,
            Paint()
              ..color = col.withValues(alpha: 0.4 * glow)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      canvas.drawRRect(
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                col.withValues(alpha: 0.5 + 0.4 * glow),
                col.withValues(alpha: 0.22 + 0.3 * glow),
              ],
            ).createShader(r.outerRect));
      canvas.drawLine(
          Offset(cx, mY - 11),
          Offset(cx, mY + 11),
          Paint()
            ..color = Potatuhs.inkDeep.withValues(alpha: 0.8)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
      GameFx.text(canvas, labels[i], Offset(cx, mY + 26), 8.5,
          col.withValues(alpha: 0.7 + 0.3 * glow));
    }
  }

  // ── Molecules ────────────────────────────────────────────────────────────
  void _paintMolecule(Canvas canvas, _Molecule m, double t) {
    final c = m.def.color;
    final p = m.pos;
    final bob = math.sin(t * 3 + m.phase) * 1.5;
    final r = m.radius;
    canvas.save();
    canvas.translate(p.dx, p.dy + bob);

    if (m.def.wanted) {
      // WANTED: bright glow + a pulsing IMPORT RING affordance ("pull me in").
      final pulse = 0.5 + 0.5 * math.sin(t * 4 + m.phase);
      canvas.drawCircle(
          Offset.zero,
          r + 4,
          Paint()
            ..color = c.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(
          Offset.zero,
          r + 7 + pulse * 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _kAccent.withValues(alpha: 0.20 + 0.30 * pulse));
      if (m.rescue) {
        // Rescue nutrients carry a gold halo so they read as a prize.
        canvas.drawCircle(
            Offset.zero,
            r + 12,
            Paint()
              ..color = Potatuhs.gold.withValues(alpha: 0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      }
    } else {
      // UNWANTED: dim glow + jagged hazard outline so the silhouette rejects.
      canvas.drawCircle(
          Offset.zero,
          r + 3,
          Paint()
            ..color = c.withValues(alpha: 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      _jaggedRing(canvas, r + 5, _kHazard.withValues(alpha: 0.5), m.phase);
    }

    _paintGlyph(canvas, m, t, r);
    canvas.restore();

    // Shared affordance badges drawn upright (not glyph-rotated).
    if (m.def.wanted) {
      // Down-chevron above: "tap to pull in".
      final cy = -r - 12 + bob;
      final chev = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _kAccent.withValues(alpha: 0.85);
      canvas.drawLine(p.translate(-5, cy), p.translate(0, cy + 5), chev);
      canvas.drawLine(p.translate(5, cy), p.translate(0, cy + 5), chev);
    } else {
      // Hazard ✕ badge top-right: "hands off".
      final bx = p.translate(r * 0.78, -r * 0.78 + bob);
      canvas.drawCircle(bx, 7, Paint()..color = _kHazard);
      canvas.drawCircle(
          bx,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withValues(alpha: 0.9));
      final x = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(bx.translate(-2.6, -2.6), bx.translate(2.6, 2.6), x);
      canvas.drawLine(bx.translate(2.6, -2.6), bx.translate(-2.6, 2.6), x);
    }

    // Label kept for learnability, but no longer load-bearing.
    GameFx.text(canvas, m.def.label, p.translate(0, r + 11 + bob), 9.0,
        (m.def.wanted ? c : Potatuhs.textFaint).withValues(alpha: 0.9));
  }

  void _paintGlyph(Canvas canvas, _Molecule m, double t, double r) {
    final c = m.def.color;
    final unit = r / _kMolRadius;
    switch (m.def.glyph) {
      case _Glyph.gasPair:
        _orbDot(canvas, Offset(-6 * unit, 0), 7 * unit, c);
        _orbDot(canvas, Offset(6 * unit, 0), 7 * unit, c);
        break;
      case _Glyph.gasTriple:
        _orbDot(canvas, Offset(-9 * unit, 0), 5.5 * unit, c.withValues(alpha: 0.9));
        _orbDot(canvas, Offset.zero, 7 * unit, c);
        _orbDot(canvas, Offset(9 * unit, 0), 5.5 * unit, c.withValues(alpha: 0.9));
        break;
      case _Glyph.water:
        _orbDot(canvas, Offset(0, -1 * unit), 8 * unit, c);
        _orbDot(canvas, Offset(-8 * unit, 6 * unit), 4.5 * unit, c.withValues(alpha: 0.85));
        _orbDot(canvas, Offset(8 * unit, 6 * unit), 4.5 * unit, c.withValues(alpha: 0.85));
        break;
      case _Glyph.ion:
        _orbDot(canvas, Offset.zero, (r - 4), c);
        _glyphText(canvas, m.def.label, 11 * unit, Potatuhs.ink);
        break;
      case _Glyph.hexagon:
        _polygon(canvas, 6, r - 3, c, t * 0.4 + m.phase, fill: true);
        break;
      case _Glyph.amino:
        _polygon(canvas, 4, r - 4, c, math.pi / 4, fill: true);
        _glyphText(canvas, 'AA', 9 * unit, Potatuhs.ink);
        break;
      case _Glyph.spiky:
        _star(canvas, 7, r, r - 8, c);
        break;
      case _Glyph.virus:
        _orbDot(canvas, Offset.zero, r - 7, c);
        final spike = Paint()
          ..color = c.withValues(alpha: 0.9)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i / 8 * math.pi * 2;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(d * (r - 7.0), d * (r + 1.0), spike);
          canvas.drawCircle(d * (r + 2.0), 1.8, spike);
        }
        break;
      case _Glyph.rod:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: r * 2.0, height: 13),
                const Radius.circular(6.5)),
            Paint()..color = c);
        canvas.drawLine(
            Offset(r, 0),
            Offset(r + 9, -4),
            Paint()
              ..color = c.withValues(alpha: 0.8)
              ..strokeWidth = 1.6);
        break;
      case _Glyph.metal:
        _polygon(canvas, 6, r - 4, c, 0, fill: true);
        _orbDot(canvas, Offset.zero, 4, _kHazard);
        break;
      case _Glyph.blob:
        _polygon(canvas, 9, r - 5, c, m.phase, fill: true, wobble: 0.18);
        break;
    }
  }

  // A rough, jagged ring — the shared "intruder" silhouette cue.
  void _jaggedRing(Canvas canvas, double r, Color color, double phase) {
    final path = Path();
    const teeth = 11;
    for (var i = 0; i <= teeth; i++) {
      final a = phase + i / teeth * math.pi * 2;
      final rr = r * (i.isEven ? 1.0 : 0.80);
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
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color);
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

  // ── Live score HUD: big number + PACE bar + multiplier ───────────────────
  void _paintScoreHud(Canvas canvas, Size size) {
    final score = state.widget.session.score;
    final running = state.widget.session.isRunning;

    // Big live score, top-centre.
    GameFx.text(canvas, '$score', Offset(size.width / 2, 30), 34,
        Potatuhs.textPrimary,
        display: true, glow: 0.35);
    GameFx.text(
        canvas,
        state.widget.session.spec.scoreUnit,
        Offset(size.width / 2, 52),
        9.5,
        Potatuhs.textSecondary);

    // Multiplier pill, top-left (always visible while playing).
    if (running) {
      final mult = state._mult;
      final locked = state._lockout > 0;
      final label = locked ? 'LOCKED' : '×$mult';
      final col = locked ? _kHazard : (mult > 1 ? Potatuhs.gold : Potatuhs.textSecondary);
      _pill(canvas, Offset(14, 14), label, col, 13);
    }

    // PACE bar, top edge: your fill vs a par tick — "am I keeping up?".
    if (running) {
      final barX = 20.0, barW = size.width - 40, barY = 66.0;
      final hm = state._humanMax.toDouble();
      final youFrac = (score / hm).clamp(0.0, 1.0);
      final parFrac = (state._par / hm).clamp(0.0, 1.0);
      final track = RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 4), const Radius.circular(2));
      canvas.drawRRect(
          track, Paint()..color = Colors.white.withValues(alpha: 0.10));
      final ahead = score >= state._par;
      final fill = RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * youFrac, 4),
          const Radius.circular(2));
      canvas.drawRRect(
          fill,
          Paint()
            ..color = (ahead ? Potatuhs.gold : Potatuhs.orange)
                .withValues(alpha: 0.9));
      // Par tick.
      final tx = barX + barW * parFrac;
      canvas.drawLine(
          Offset(tx, barY - 3),
          Offset(tx, barY + 7),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 2);
      GameFx.text(canvas, ahead ? 'AHEAD OF PACE' : 'PAR',
          Offset(tx, barY + 14), 8, Colors.white.withValues(alpha: 0.6));
    }
  }

  void _pill(Canvas canvas, Offset at, String label, Color col, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx, at.dy, tp.width + 18, tp.height + 10),
        const Radius.circular(8));
    canvas.drawRRect(
        rect, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.82));
    canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = col.withValues(alpha: 0.6));
    tp.paint(canvas, Offset(at.dx + 9, at.dy + 5));
  }

  void _paintClimaxVignette(Canvas canvas, Size size, double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * 6);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            _kHazard.withValues(alpha: 0.0),
            _kHazard.withValues(alpha: 0.04 + 0.06 * pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (state._flash <= 0) return;
    final a = (state._flash / 0.45) * 0.22;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _kHazard.withValues(alpha: a));
  }

  // ── Calm ready state — teaches BOTH verbs (tap / don't tap) ──────────────
  void _paintReady(Canvas canvas, Size size, double mY) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.42));
    final cx = size.width / 2;
    GameFx.text(canvas, 'MEMBRANE GATE', Offset(cx, mY * 0.34), 26,
        Potatuhs.textPrimary,
        display: true, glow: 0.4);

    // Two worked examples, side by side: tap the bright one, leave the dull one.
    final y = mY * 0.60;
    _miniExample(canvas, Offset(cx - 64, y), true);
    _miniExample(canvas, Offset(cx + 64, y), false);
    GameFx.text(canvas, 'TAP to import', Offset(cx - 64, y + 34), 11,
        _kAccent);
    GameFx.text(canvas, "DON'T tap — let it bounce", Offset(cx + 64, y + 34),
        10.5, _kHazard);

    GameFx.text(
        canvas,
        'Bright + glowing = the cell needs it.  Dull + ✕ = keep it out.',
        Offset(cx, y + 64),
        12,
        Potatuhs.textSecondary);
  }

  void _miniExample(Canvas canvas, Offset at, bool wanted) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (wanted) {
      canvas.drawCircle(
          Offset.zero,
          18,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _kAccent.withValues(alpha: 0.5));
      _orbDot(canvas, const Offset(-6, 0), 7, _kWanted[0].color);
      _orbDot(canvas, const Offset(6, 0), 7, _kWanted[0].color);
    } else {
      _jaggedRing(canvas, 16, _kHazard.withValues(alpha: 0.6), 0);
      _star(canvas, 7, 13, 6, _kUnwanted[0].color);
      final bx = const Offset(12, -12);
      canvas.drawCircle(bx, 7, Paint()..color = _kHazard);
      final x = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(bx.translate(-2.6, -2.6), bx.translate(2.6, 2.6), x);
      canvas.drawLine(bx.translate(2.6, -2.6), bx.translate(-2.6, 2.6), x);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MembraneGateV2Painter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each card is drawn STATICALLY with
// the SAME components a player meets in play (the exact luminous wanted orb with
// its import ring + ↓ chevron, the muddy jagged intruder with its ✕ badge, the
// phospholipid bilayer + channel proteins). Self-contained top-level painters so
// they render cheaply in the intro carousel; they reuse this file's taxonomy
// constants (_kWanted / _kUnwanted / _kAccent / _kHazard) directly.
// ═══════════════════════════════════════════════════════════════════════════

// ── Legend draw primitives (mirror the painter's own glyph code) ────────────
void _lOrbDot(Canvas canvas, Offset at, double r, Color c) {
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

void _lGlyphText(Canvas canvas, String s, double size, Color color) {
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

void _lPolygon(Canvas canvas, int sides, double r, Color c, double rot,
    {bool fill = false, double wobble = 0}) {
  if (r <= 0) return;
  final path = Path();
  for (var i = 0; i <= sides; i++) {
    final a = rot + i / sides * math.pi * 2;
    final rr = r * (1 + wobble * math.sin(a * 3));
    final pt = Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
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

void _lStar(Canvas canvas, int points, double outer, double inner, Color c) {
  if (outer <= 0) return;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = i / (points * 2) * math.pi * 2 - math.pi / 2;
    final r = i.isEven ? outer : inner;
    final pt = Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
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

void _lJaggedRing(Canvas canvas, double r, Color color) {
  if (r <= 0) return;
  final path = Path();
  const teeth = 11;
  for (var i = 0; i <= teeth; i++) {
    final a = i / teeth * math.pi * 2;
    final rr = r * (i.isEven ? 1.0 : 0.80);
    final pt = Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  path.close();
  canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color);
}

void _lGlyph(Canvas canvas, _MolDef def, double r) {
  final c = def.color;
  final unit = r / _kMolRadius;
  switch (def.glyph) {
    case _Glyph.gasPair:
      _lOrbDot(canvas, Offset(-6 * unit, 0), 7 * unit, c);
      _lOrbDot(canvas, Offset(6 * unit, 0), 7 * unit, c);
      break;
    case _Glyph.gasTriple:
      _lOrbDot(canvas, Offset(-9 * unit, 0), 5.5 * unit, c.withValues(alpha: 0.9));
      _lOrbDot(canvas, Offset.zero, 7 * unit, c);
      _lOrbDot(canvas, Offset(9 * unit, 0), 5.5 * unit, c.withValues(alpha: 0.9));
      break;
    case _Glyph.water:
      _lOrbDot(canvas, Offset(0, -1 * unit), 8 * unit, c);
      _lOrbDot(canvas, Offset(-8 * unit, 6 * unit), 4.5 * unit, c.withValues(alpha: 0.85));
      _lOrbDot(canvas, Offset(8 * unit, 6 * unit), 4.5 * unit, c.withValues(alpha: 0.85));
      break;
    case _Glyph.ion:
      _lOrbDot(canvas, Offset.zero, r - 4, c);
      _lGlyphText(canvas, def.label, 11 * unit, Potatuhs.ink);
      break;
    case _Glyph.hexagon:
      _lPolygon(canvas, 6, r - 3, c, 0.4, fill: true);
      break;
    case _Glyph.amino:
      _lPolygon(canvas, 4, r - 4, c, math.pi / 4, fill: true);
      _lGlyphText(canvas, 'AA', 9 * unit, Potatuhs.ink);
      break;
    case _Glyph.spiky:
      _lStar(canvas, 7, r, r - 8, c);
      break;
    case _Glyph.virus:
      _lOrbDot(canvas, Offset.zero, r - 7, c);
      final spike = Paint()
        ..color = c.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(d * (r - 7.0), d * (r + 1.0), spike);
        canvas.drawCircle(d * (r + 2.0), 1.8, spike);
      }
      break;
    case _Glyph.rod:
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: r * 2.0, height: 13),
              const Radius.circular(6.5)),
          Paint()..color = c);
      break;
    case _Glyph.metal:
      _lPolygon(canvas, 6, r - 4, c, 0, fill: true);
      _lOrbDot(canvas, Offset.zero, 4, _kHazard);
      break;
    case _Glyph.blob:
      _lPolygon(canvas, 9, r - 5, c, 0.6, fill: true, wobble: 0.18);
      break;
  }
}

/// Draws one molecule exactly as it reads in play: a luminous wanted orb with
/// its pulsing IMPORT RING + ↓ chevron, or a muddy jagged intruder with its
/// red hazard ✕ badge. [rescue] adds the gold prize halo.
void _lMolecule(Canvas canvas, Offset at, _MolDef def, double r,
    {bool rescue = false, bool badge = true}) {
  if (r <= 0) return;
  final c = def.color;
  canvas.save();
  canvas.translate(at.dx, at.dy);
  if (def.wanted) {
    canvas.drawCircle(
        Offset.zero,
        r + 4,
        Paint()
          ..color = c.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(
        Offset.zero,
        r + 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _kAccent.withValues(alpha: 0.42));
    if (rescue) {
      canvas.drawCircle(
          Offset.zero,
          r + 12,
          Paint()
            ..color = Potatuhs.gold.withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
  } else {
    canvas.drawCircle(
        Offset.zero,
        r + 3,
        Paint()
          ..color = c.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    _lJaggedRing(canvas, r + 5, _kHazard.withValues(alpha: 0.5));
  }
  _lGlyph(canvas, def, r);
  canvas.restore();

  if (!badge) return;
  if (def.wanted) {
    final cy = -r - 12;
    final chev = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _kAccent.withValues(alpha: 0.85);
    canvas.drawLine(at.translate(-5, cy), at.translate(0, cy + 5), chev);
    canvas.drawLine(at.translate(5, cy), at.translate(0, cy + 5), chev);
  } else {
    final bx = at.translate(r * 0.78, -r * 0.78);
    canvas.drawCircle(bx, 7, Paint()..color = _kHazard);
    canvas.drawCircle(
        bx,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.9));
    final x = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(bx.translate(-2.6, -2.6), bx.translate(2.6, 2.6), x);
    canvas.drawLine(bx.translate(2.6, -2.6), bx.translate(-2.6, 2.6), x);
  }
}

/// The phospholipid bilayer + the three channel proteins, drawn statically.
void _lMembrane(Canvas canvas, Size size, double mY) {
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
    canvas.drawLine(Offset(x, topY + headR), Offset(x, mY - 1), tailPaint);
    canvas.drawLine(Offset(x, botY - headR), Offset(x, mY + 1), tailPaint);
    canvas.drawCircle(Offset(x, topY), headR, headPaint);
    canvas.drawCircle(Offset(x, botY), headR, headPaint);
  }
  const labels = ['aquaporin', 'glucose', 'ion channel'];
  const cols = [Color(0xFF34C9F0), Color(0xFFFFD54F), Color(0xFF5C9DFF)];
  final slots = [0.25, 0.5, 0.75];
  for (var i = 0; i < slots.length; i++) {
    final cx = size.width * slots[i];
    final col = cols[i];
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, mY), width: 22, height: 30),
        const Radius.circular(8));
    canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              col.withValues(alpha: 0.6),
              col.withValues(alpha: 0.28),
            ],
          ).createShader(r.outerRect));
    canvas.drawLine(
        Offset(cx, mY - 11),
        Offset(cx, mY + 11),
        Paint()
          ..color = Potatuhs.inkDeep.withValues(alpha: 0.8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    GameFx.text(canvas, labels[i], Offset(cx, mY + 26), 8.5,
        col.withValues(alpha: 0.85));
  }
}

// ── Frame 1: the core read + verb — tap the bright, leave the dull ───────────
void _legendRead(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final y = size.height * 0.46;
  final r = (size.shortestSide * 0.13).clamp(16.0, 30.0);
  _lMolecule(canvas, Offset(size.width * 0.30, y), _kWanted[0], r);
  _lMolecule(canvas, Offset(size.width * 0.70, y), _kUnwanted[0], r);
  GameFx.text(canvas, 'TAP to import', Offset(size.width * 0.30, y + r + 22),
      11, _kAccent);
  GameFx.text(canvas, "DON'T tap", Offset(size.width * 0.70, y + r + 22),
      11, _kHazard);
}

// ── Frame 2: the danger — intruders bounce; tapping one LOCKS you out ─────────
void _legendDanger(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final mY = size.height * 0.68;
  _lMembrane(canvas, size, mY);
  final r = (size.shortestSide * 0.11).clamp(14.0, 26.0);
  final y = size.height * 0.34;
  _lMolecule(canvas, Offset(size.width * 0.26, y), _kUnwanted[0], r); // Toxin
  _lMolecule(canvas, Offset(size.width * 0.5, y), _kUnwanted[1], r); // Virus
  _lMolecule(canvas, Offset(size.width * 0.74, y), _kUnwanted[4], r); // Waste
  GameFx.text(canvas, 'let them bounce', Offset(size.width * 0.5, mY + 44),
      11, _kHazard);
}

// ── Frame 3: scoring — catch high for PERFECT, chain to grow the multiplier ──
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final r = (size.shortestSide * 0.12).clamp(15.0, 28.0);
  // High catch = PERFECT.
  _lMolecule(canvas, Offset(size.width * 0.32, size.height * 0.30),
      _kWanted[2], r); // H₂O
  GameFx.text(canvas, 'PERFECT +bonus', Offset(size.width * 0.32,
      size.height * 0.30 - r - 16), 10, Potatuhs.gold);
  // Gold rescue nutrient.
  _lMolecule(canvas, Offset(size.width * 0.70, size.height * 0.56),
      _kWanted[5], r * 1.2, rescue: true); // Glucose rescue
  GameFx.text(canvas, 'RESCUE ×3', Offset(size.width * 0.70,
      size.height * 0.56 + r * 1.2 + 18), 10, Potatuhs.gold);
  GameFx.text(canvas, 'chain imports → ×6', Offset(size.width * 0.5,
      size.height * 0.90), 11, Potatuhs.textSecondary);
}

// ── Frame 4: the climax — final 10s FINAL PUSH surge, imports score ×1.5 ─────
void _legendClimax(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        radius: 1.1,
        colors: [
          _kHazard.withValues(alpha: 0.0),
          _kHazard.withValues(alpha: 0.12),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect),
  );
  final r = (size.shortestSide * 0.16).clamp(20.0, 40.0);
  _lMolecule(canvas, Offset(size.width * 0.5, size.height * 0.46),
      _kWanted[5], r, rescue: true);
  GameFx.text(canvas, 'FINAL PUSH!', Offset(size.width * 0.5,
      size.height * 0.20), 18, _kHazard, display: true, glow: 0.4);
  GameFx.text(canvas, 'imports score ×1.5', Offset(size.width * 0.5,
      size.height * 0.46 + r + 22), 11, Potatuhs.textSecondary);
}

/// The visual manual for Membrane Gate v2 — wired into the registry spec.
final List<LegendFrame> membraneGateV2LegendFrames = [
  const LegendFrame(
      caption: 'Tap bright glowing molecules to import them',
      paint: _legendRead),
  const LegendFrame(
      caption: 'Leave dull ✕-marked intruders — let them bounce',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Catch high = PERFECT; chain imports to grow ×mult',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Final 10s FINAL PUSH: faster, imports score ×1.5',
      paint: _legendClimax),
];
