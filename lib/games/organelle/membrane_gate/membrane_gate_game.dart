import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// MEMBRANE GATE — selective-permeability arcade (60 s score attack).
///
/// A phospholipid bilayer spans the screen. Molecules drift down from the
/// extracellular space toward the membrane. The membrane is selectively
/// permeable: the player is the gatekeeper.
///
///   • TAP a WANTED molecule (O₂, CO₂, H₂O, Na⁺, K⁺, glucose, amino acid)
///     to transport it INTO the cell.            → +10 × streak multiplier
///   • DO NOT tap UNWANTED molecules (toxins, viruses, bacteria, heavy
///     metals, waste). Let them reach the membrane and BOUNCE — the
///     selectively-permeable membrane keeps them out for free.
///   • Tapping a toxin = you let it in.          → −8, streak reset
///   • A wanted molecule that reaches the membrane untaken = a missed
///     nutrient (the cell starves a little).     → streak reset
///
/// Difficulty ramps: faster arrivals, faster descent, and a rising share of
/// "mimic" molecules that resemble the good ones.
///
/// Teaches: selective permeability, simple diffusion (gases through the
/// lipid), osmosis (water through aquaporins), and facilitated transport
/// (ions/glucose/amino acids through matching channel & carrier proteins).
///
/// PERFORMANCE: one [Ticker] drives a single [CustomPainter] via a repaint
/// notifier. No per-frame setState.

// ─── Tuning ───────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;
const Color _kAccent = Color(0xFF4FC3F7); // membrane / transport cyan

const double _kMembraneFrac = 0.64; // membrane y as fraction of height
const double _kMolRadius = 17.0;
const double _kHitPad = 24.0; // tap forgiveness around a molecule

const double _kSpawnEarly = 1.05; // seconds between arrivals at t=0
const double _kSpawnLate = 0.42; // seconds between arrivals at t=end
const double _kFallEarly = 74.0; // px/s descent at t=0
const double _kFallLate = 184.0; // px/s descent at t=end
const double _kIdleSpawn = 1.7; // calm-state arrival interval

const int _kGoodScore = 10;
const int _kToxinPenalty = 8;
const int _kMaxMolecules = 14;

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

// Channel slots: 0 = aquaporin, 1 = glucose carrier, 2 = ion channel.
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

class _Molecule {
  Offset pos;
  double vx;
  double speed;
  final _MolDef def;
  final double phase;
  bool dead = false;
  _Molecule(this.pos, this.vx, this.speed, this.def, this.phase);
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
  final List<double> _channelGlow = [0, 0, 0];

  double _spawnAcc = 0;
  int _streak = 0;
  double _flash = 0; // red toxin-intake flash
  double _thrive = 0; // gold good-intake pulse
  double _vitality = 0.6; // 0..1 cosmetic cell health

  int get _mult => (1 + _streak ~/ 5).clamp(1, 3);
  double get _membraneY => (_size?.height ?? 600) * _kMembraneFrac;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── Difficulty ───────────────────────────────────────────────────────────
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final elapsed =
        dur - widget.session.remaining.inMilliseconds / 1000.0;
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
    for (var i = 0; i < _channelGlow.length; i++) {
      if (_channelGlow[i] > 0) _channelGlow[i] = math.max(0, _channelGlow[i] - dt);
    }
    // Vitality drifts gently toward a baseline.
    _vitality += (0.55 - _vitality) * (dt * 0.25);
    _vitality = _vitality.clamp(0.0, 1.0);

    // Spawn cadence.
    _spawnAcc += dt;
    final interval = running
        ? _lerp(_kSpawnEarly, _kSpawnLate, diff)
        : _kIdleSpawn;
    if (_spawnAcc >= interval && _mols.length < _kMaxMolecules) {
      _spawnAcc = 0;
      _spawn(w, diff, running);
    }

    final fall = _lerp(_kFallEarly, _kFallLate, diff);
    final mY = _membraneY;
    for (final m in _mols) {
      m.pos = Offset(
        m.pos.dx + m.vx * dt * 14 * math.sin(_time * 1.3 + m.phase),
        m.pos.dy + m.speed * fall / _kFallEarly * dt,
      );
      if (m.dead) continue;
      if (running) {
        if (m.pos.dy >= mY - _kMolRadius) {
          _resolveAtMembrane(m);
        }
      } else {
        // Calm ready state: molecules drift past and fade out, no scoring.
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
    final x = 30 + _rng.nextDouble() * (w - 60);
    _mols.add(_Molecule(
      Offset(x, -_kMolRadius - 10),
      (_rng.nextDouble() - 0.5),
      0.85 + _rng.nextDouble() * 0.4,
      def,
      _rng.nextDouble() * math.pi * 2,
    ));
  }

  void _resolveAtMembrane(_Molecule m) {
    m.dead = true;
    if (m.def.wanted) {
      // Missed nutrient — the cell starves a little. No penalty score, but
      // the streak breaks and vitality dips.
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
      if (dist < _kMolRadius + _kHitPad && dist < best) {
        best = dist;
        hit = m;
      }
    }
    if (hit == null) return;
    _act(hit);
  }

  void _act(_Molecule m) {
    m.dead = true;
    final session = widget.session;
    if (m.def.wanted) {
      _streak++;
      session.noteStreak(_streak);
      final gain = _kGoodScore * _mult;
      session.addScore(gain);
      _thrive = 0.5;
      _vitality = (_vitality + 0.05).clamp(0.0, 1.0);
      _lightChannel(m.def.transport);
      // Slurp the molecule down through the membrane into the cell.
      for (var i = 0; i < 10; i++) {
        _particles.add(FxParticle(
          m.pos,
          Offset((_rng.nextDouble() - 0.5) * 60, 60 + _rng.nextDouble() * 90),
          m.def.color,
          2.4 + _rng.nextDouble() * 1.8,
        ));
      }
      final tag = _mult > 1 ? '+$gain ×$_mult' : '+$gain';
      _pops.add(FxPop(m.pos, tag, m.def.color));
      if (m.def.channel.isNotEmpty) {
        _pops.add(FxPop(m.pos.translate(0, 18), m.def.channel,
            m.def.color.withValues(alpha: 0.75)));
      }
    } else {
      _streak = 0;
      session.addScore(-_kToxinPenalty);
      _flash = 0.45;
      _vitality = (_vitality - 0.12).clamp(0.0, 1.0);
      _particles.addAll(FxBurst.spawn(m.pos, const Color(0xFFFF5252),
          count: 14, speed: 130, size: 3));
      _pops.add(FxPop(m.pos, 'TOXIN IN −$_kToxinPenalty',
          const Color(0xFFFF5252)));
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
    _paintMembrane(canvas, size, mY, t);

    // Molecules above the membrane.
    for (final m in state._mols) {
      if (m.dead) continue;
      _paintMolecule(canvas, m, t);
    }

    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    _paintHud(canvas, size);
    _paintFlash(canvas, size);

    if (!state.widget.session.isRunning) {
      _paintReady(canvas, size, mY);
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
    // Nucleus glow low in the cell — brightens with vitality / thrive.
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
      // Tails (between heads, pointing inward).
      canvas.drawLine(
          Offset(x, topY + headR), Offset(x + sway * 0.4, mY - 1), tailPaint);
      canvas.drawLine(
          Offset(x, botY - headR), Offset(x - sway * 0.4, mY + 1), tailPaint);
      canvas.drawCircle(Offset(x, topY + sway * 0.3), headR, headPaint);
      canvas.drawCircle(Offset(x, botY - sway * 0.3), headR, headPaint);
    }

    // Channel proteins embedded at three slots.
    const labels = ['aquaporin', 'glucose', 'ion channel'];
    const cols = [Color(0xFF4DD0E1), Color(0xFFFFD54F), Color(0xFFAED581)];
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
      // Central pore.
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
    canvas.save();
    canvas.translate(p.dx, p.dy + bob);

    // Soft glow halo for everything.
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
            Offset(_kMolRadius, 0),
            Offset(_kMolRadius + 9, -4),
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

    // Label under each molecule for learnability.
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

  // ── HUD: streak multiplier ───────────────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    if (state._streak < 5) return;
    final label = 'STREAK ×${state._mult}';
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(
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
    GameFx.text(canvas, 'MEMBRANE GATE',
        Offset(size.width / 2, mY * 0.42), 26, Potatuhs.textPrimary,
        display: true, glow: 0.4);
    GameFx.text(
        canvas,
        'Tap the molecules the cell NEEDS',
        Offset(size.width / 2, mY * 0.42 + 30),
        13,
        Potatuhs.textSecondary);
    GameFx.text(
        canvas,
        'Let toxins bounce off the membrane',
        Offset(size.width / 2, mY * 0.42 + 50),
        13,
        Potatuhs.textSecondary);
  }

  @override
  bool shouldRepaint(covariant _MembraneGatePainter oldDelegate) => false;
}
