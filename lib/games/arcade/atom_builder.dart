import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

const _kFont = 'Avenir';
const Color _kAccent = Color(0xFF5C6BC0);
const Color _kProtonColor = Color(0xFFFF5252);
const Color _kNeutronColor = Color(0xFFB0BEC5);
const Color _kElectronColor = Color(0xFF40C4FF);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kWarn = Color(0xFFFFB300); // instability / "needs a nucleus"

// Nuclear stability: protons repel, neutrons are the strong-force glue.
// When unpaired protons (gotP - gotN) build up past this, the core starts to
// destabilise; left unbalanced long enough, a proton decays away.
const int _kStableExcess = 1; // 1 unpaired proton is fine (hydrogen-1)
const double _kInstabilityGain = 0.34; // per excess-proton, per second
const double _kInstabilityRecover = 0.7; // per second once balanced

enum _ParticleKind { proton, neutron, electron }

/// A noble-gas checkpoint. In the game's clean model protons = neutrons =
/// electrons = [count]; reaching it completes a full electron shell.
class _Noble {
  final String name;
  final String symbol;
  final int count; // cumulative p = n = e at this checkpoint
  const _Noble(this.name, this.symbol, this.count);
}

/// The ladder: build ONE continuously-growing atom up through the noble
/// gases. You can't begin a shell until the one below it is perfectly
/// balanced (p = n = e at that checkpoint).
const List<_Noble> _kNobles = [
  _Noble('HELIUM', 'He', 2),
  _Noble('NEON', 'Ne', 10),
  _Noble('ARGON', 'Ar', 18),
  _Noble('KRYPTON', 'Kr', 36),
  _Noble('XENON', 'Xe', 54),
];

/// Electron capacity per shell (period model). Cumulative sums land on the
/// noble gases: 2, 10, 18, 36, 54. Drives both the gating and the drawing.
const List<int> _kShellCaps = [2, 8, 8, 18, 18];

class _FallingParticle {
  _ParticleKind kind;
  double x;
  double y;
  double vy;
  double drift; // gentle horizontal sway
  double phase; // glow/sway phase seed
  bool dead = false;
  _FallingParticle({
    required this.kind,
    required this.x,
    required this.y,
    required this.vy,
    required this.drift,
    required this.phase,
  });
}

class _Flier {
  final _ParticleKind kind;
  final Offset from;
  double t = 0; // 0..1 flight progress
  _Flier({required this.kind, required this.from});
}

class _Popup {
  final String text;
  final Color color;
  final Offset pos;
  final double scale;
  double age = 0;
  _Popup(this.text, this.color, this.pos, {this.scale = 1});
}

class _BurstSpark {
  final Offset origin;
  final double angle;
  final double speed;
  final Color color;
  double age = 0;
  _BurstSpark(this.origin, this.angle, this.speed, this.color);
}

class AtomBuilderGame extends StatefulWidget {
  final MiniGameSession session;
  const AtomBuilderGame({Key? key, required this.session}) : super(key: key);

  @override
  State<AtomBuilderGame> createState() => _AtomBuilderGameState();
}

class _AtomBuilderGameState extends State<AtomBuilderGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0; // always-running visual clock (orbits, glow pulses)
  double _runTime = 0; // gameplay time, advances only while running
  double _spawnAccum = 0;

  int _nobleIndex = 0; // next noble-gas checkpoint to reach
  int _gotP = 0;
  int _gotN = 0;
  int _gotE = 0;

  final List<_FallingParticle> _falling = [];
  final List<_Flier> _fliers = [];
  final List<_Popup> _popups = [];
  final List<_BurstSpark> _sparks = [];

  double _flashAlpha = 0; // red error flash
  double _bannerAge = -1; // >=0 while completion banner is showing
  String _bannerText = '';
  double _nucleusKick = 0; // wobble impulse when a particle lands
  double _instability = 0; // 0..1 — fills when protons outnumber neutrons

  Size _fieldSize = Size.zero;

  _Noble get _target => _kNobles[_nobleIndex];

  /// Current shell ceiling: you can only collect particles up to the next
  /// noble checkpoint, so the shell above stays locked until this one is full.
  int get _cap => _target.count;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- loop --

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    if (widget.session.isRunning) {
      _runTime += dt;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    final size = _fieldSize;
    if (size == Size.zero) return;

    // Difficulty ramp over the 45s run.
    final total = widget.session.spec.durationSeconds.toDouble();
    final ramp = (_runTime / total).clamp(0.0, 1.0);
    final fallSpeed = 105.0 + 80.0 * ramp;
    final spawnEvery = 0.62 - 0.20 * ramp;

    // Spawn.
    _spawnAccum += dt;
    while (_spawnAccum >= spawnEvery) {
      _spawnAccum -= spawnEvery;
      _spawnParticle(size, fallSpeed);
    }

    // Fall + sway.
    for (final p in _falling) {
      p.y += p.vy * dt;
      p.x += math.sin(_clock * 1.6 + p.phase) * p.drift * dt;
      if (p.y > size.height + 40) p.dead = true;
    }
    _falling.removeWhere((p) => p.dead);

    // Fliers toward the atom.
    for (final f in _fliers) {
      f.t += dt / 0.38;
    }
    _fliers.removeWhere((f) {
      if (f.t >= 1) {
        _nucleusKick = 1;
        return true;
      }
      return false;
    });

    // Popups, sparks, flash, banner, wobble decay.
    for (final pop in _popups) {
      pop.age += dt;
    }
    _popups.removeWhere((p) => p.age > 0.9);
    for (final s in _sparks) {
      s.age += dt;
    }
    _sparks.removeWhere((s) => s.age > 0.7);
    _flashAlpha = math.max(0, _flashAlpha - dt * 2.6);
    _nucleusKick = math.max(0, _nucleusKick - dt * 3.2);
    if (_bannerAge >= 0) {
      _bannerAge += dt;
      if (_bannerAge > 1.4) _bannerAge = -1;
    }

    _simulateStability(dt);
  }

  /// Unpaired protons repel; without neutron glue the core grows unstable and
  /// eventually a proton decays away. Balanced cores (neutrons ≥ protons) are
  /// rock-solid, so good play is never punished — only greedy proton-grabbing.
  void _simulateStability(double dt) {
    final excess = _gotP - _gotN;
    if (excess > _kStableExcess) {
      _instability += dt * (excess - _kStableExcess) * _kInstabilityGain;
    } else {
      _instability = math.max(0, _instability - dt * _kInstabilityRecover);
    }

    if (_instability >= 1.0 && _gotP > 0) {
      // Beta-ish decay: shed one proton back out of the nucleus.
      _gotP--;
      // An electron with no proton left to orbit drifts off too.
      if (_gotE > _gotP) _gotE = _gotP;
      _instability = 0.45;
      _nucleusKick = 1;
      _flashAlpha = 0.5;
      _popups.add(_Popup('DECAY −1p', _kWarn,
          _atomCenter(_fieldSize) - const Offset(0, 54)));
      final origin = _atomCenter(_fieldSize);
      for (int i = 0; i < 10; i++) {
        final a = (i / 10) * math.pi * 2;
        _sparks.add(_BurstSpark(origin, a, 70 + _rng.nextDouble() * 60,
            _kProtonColor));
      }
    }
  }

  void _spawnParticle(Size size, double fallSpeed) {
    final needed = <_ParticleKind>[
      if (_gotP < _cap) _ParticleKind.proton,
      if (_gotN < _cap) _ParticleKind.neutron,
      if (_gotE < _cap) _ParticleKind.electron,
    ];
    final notNeeded = _ParticleKind.values
        .where((k) => !needed.contains(k))
        .toList(growable: false);

    _ParticleKind kind;
    if (needed.isNotEmpty && (_rng.nextDouble() < 0.65 || notNeeded.isEmpty)) {
      kind = needed[_rng.nextInt(needed.length)];
    } else if (notNeeded.isNotEmpty) {
      kind = notNeeded[_rng.nextInt(notNeeded.length)];
    } else {
      kind = _ParticleKind.values[_rng.nextInt(3)];
    }

    _falling.add(_FallingParticle(
      kind: kind,
      x: 30 + _rng.nextDouble() * (size.width - 60),
      y: -28,
      vy: fallSpeed * (0.85 + _rng.nextDouble() * 0.3),
      drift: 8 + _rng.nextDouble() * 14,
      phase: _rng.nextDouble() * math.pi * 2,
    ));
  }

  // ---------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    final tap = d.localPosition;

    _FallingParticle? hit;
    double bestDist = 48; // generous one-thumb hit radius
    for (final p in _falling) {
      final dist = (Offset(p.x, p.y) - tap).distance;
      if (dist < bestDist) {
        bestDist = dist;
        hit = p;
      }
    }
    if (hit == null) return;

    hit.dead = true;

    // An electron needs a proton to orbit. You can't collect one onto an
    // empty core, and electrons can never outnumber protons — so the shell
    // can only grow once the nucleus has the charge to hold it.
    if (hit.kind == _ParticleKind.electron &&
        _gotE < _cap &&
        _gotE >= _gotP) {
      widget.session.addScore(-3);
      _flashAlpha = 0.4;
      _popups.add(_Popup('NEEDS A PROTON', _kWarn, Offset(hit.x, hit.y)));
      return;
    }

    bool needsIt;
    switch (hit.kind) {
      case _ParticleKind.proton:
        needsIt = _gotP < _cap;
        break;
      case _ParticleKind.neutron:
        needsIt = _gotN < _cap;
        break;
      case _ParticleKind.electron:
        needsIt = _gotE < _cap;
        break;
    }

    if (needsIt) {
      widget.session.addScore(5);
      _popups.add(_Popup('+5', _kGood, Offset(hit.x, hit.y)));
      _fliers.add(_Flier(kind: hit.kind, from: Offset(hit.x, hit.y)));
      switch (hit.kind) {
        case _ParticleKind.proton:
          _gotP++;
          break;
        case _ParticleKind.neutron:
          _gotN++;
          break;
        case _ParticleKind.electron:
          _gotE++;
          break;
      }
      _checkComplete();
    } else {
      widget.session.addScore(-10);
      _flashAlpha = 0.55;
      _popups.add(_Popup('-10', _kBad, Offset(hit.x, hit.y)));
    }
  }

  void _checkComplete() {
    // A noble checkpoint is reached only when the whole shell is perfectly
    // balanced — equal protons, neutrons and electrons at the cap.
    if (_gotP < _cap || _gotN < _cap || _gotE < _cap) return;

    widget.session.addScore(50);
    _bannerText = '${_target.name} — STABLE!';
    _bannerAge = 0;

    final origin = _atomCenter(_fieldSize);
    _popups.add(_Popup('+50', _kAccent, origin - const Offset(0, 60),
        scale: 1.6));
    for (int i = 0; i < 26; i++) {
      final a = (i / 26) * math.pi * 2;
      final colors = [_kProtonColor, _kNeutronColor, _kElectronColor, _kAccent];
      _sparks.add(_BurstSpark(
          origin, a, 120 + _rng.nextDouble() * 140, colors[i % colors.length]));
    }

    // The atom keeps growing — unlock the next shell, don't reset.
    if (_nobleIndex < _kNobles.length - 1) _nobleIndex++;
  }

  Offset _atomCenter(Size size) =>
      Offset(size.width / 2, size.height * 0.72);

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AtomFieldPainter(
                  clock: _clock,
                  gotP: _gotP,
                  gotN: _gotN,
                  gotE: _gotE,
                  falling: _falling,
                  fliers: _fliers,
                  popups: _popups,
                  sparks: _sparks,
                  flashAlpha: _flashAlpha,
                  nucleusKick: _nucleusKick,
                  instability: _instability,
                  atomCenter: _atomCenter(_fieldSize),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _TargetPanel(
                target: _target,
                cap: _cap,
                gotP: _gotP,
                gotN: _gotN,
                gotE: _gotE,
              ),
            ),
            if (_bannerAge >= 0) _buildBanner(),
          ],
        ),
      );
    });
  }

  Widget _buildBanner() {
    // Pop in, hold, fade out.
    final t = _bannerAge;
    final opacity = t < 0.15
        ? t / 0.15
        : t > 1.0
            ? (1 - (t - 1.0) / 0.4).clamp(0.0, 1.0)
            : 1.0;
    final scale = t < 0.2 ? 0.7 + 0.3 * (t / 0.2) : 1.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity.toDouble(),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: _kAccent.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withValues(alpha: 0.5),
                        blurRadius: 30),
                  ],
                ),
                child: Text(
                  _bannerText,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [Shadow(color: _kAccent, blurRadius: 16)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- target UI --

class _TargetPanel extends StatelessWidget {
  final _Noble target;
  final int cap;
  final int gotP;
  final int gotN;
  final int gotE;
  const _TargetPanel({
    required this.target,
    required this.cap,
    required this.gotP,
    required this.gotN,
    required this.gotE,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: _kAccent.withValues(alpha: 0.18), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withValues(alpha: 0.18),
              border: Border.all(color: _kAccent),
              boxShadow: [
                BoxShadow(
                    color: _kAccent.withValues(alpha: 0.4), blurRadius: 10),
              ],
            ),
            child: Text(
              target.symbol,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REACH ${target.name}',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _ProgressChip(
                        label: 'p', got: gotP, need: cap, color: _kProtonColor),
                    const SizedBox(width: 8),
                    _ProgressChip(
                        label: 'n', got: gotN, need: cap, color: _kNeutronColor),
                    const SizedBox(width: 8),
                    _ProgressChip(
                        label: 'e', got: gotE, need: cap, color: _kElectronColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final int got;
  final int need;
  final Color color;
  const _ProgressChip({
    required this.label,
    required this.got,
    required this.need,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final done = need > 0 && got >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: done ? 0.3 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: done ? 1.0 : 0.5)),
      ),
      child: Text(
        '$label $got/$need',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: done ? Colors.white : color,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- painter --

class _AtomFieldPainter extends CustomPainter {
  final double clock;
  final int gotP;
  final int gotN;
  final int gotE;
  final List<_FallingParticle> falling;
  final List<_Flier> fliers;
  final List<_Popup> popups;
  final List<_BurstSpark> sparks;
  final double flashAlpha;
  final double nucleusKick;
  final double instability;
  final Offset atomCenter;

  _AtomFieldPainter({
    required this.clock,
    required this.gotP,
    required this.gotN,
    required this.gotE,
    required this.falling,
    required this.fliers,
    required this.popups,
    required this.sparks,
    required this.flashAlpha,
    required this.nucleusKick,
    required this.instability,
    required this.atomCenter,
  });

  static const double _particleRadius = 22;

  Color _kindColor(_ParticleKind k) {
    switch (k) {
      case _ParticleKind.proton:
        return _kProtonColor;
      case _ParticleKind.neutron:
        return _kNeutronColor;
      case _ParticleKind.electron:
        return _kElectronColor;
    }
  }

  String _kindLabel(_ParticleKind k) {
    switch (k) {
      case _ParticleKind.proton:
        return '+';
      case _ParticleKind.neutron:
        return 'n';
      case _ParticleKind.electron:
        return '−';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    _paintAtom(canvas, size);
    for (final p in falling) {
      _paintFalling(canvas, p);
    }
    for (final f in fliers) {
      _paintFlier(canvas, f);
    }
    for (final s in sparks) {
      _paintSpark(canvas, s);
    }
    for (final pop in popups) {
      _paintPopup(canvas, pop);
    }
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBad.withValues(alpha: flashAlpha * 0.30),
      );
    }
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    // Faint starfield-style dots, deterministic from index.
    final paint = Paint();
    for (int i = 0; i < 36; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 89) / 89.0;
      final tw = 0.5 + 0.5 * math.sin(clock * 1.3 + i * 1.7);
      paint.color = _kAccent.withValues(alpha: 0.05 + 0.07 * tw);
      canvas.drawCircle(
          Offset(fx * size.width, fy * size.height), 1.4 + tw, paint);
    }
  }

  // ------------------------------------------------------------- the atom --

  void _paintAtom(Canvas canvas, Size size) {
    // Landing kick + an erratic, fast jitter that grows with instability.
    final jitter = instability * 6.0;
    final wobble = Offset(
      math.sin(clock * 7.0) * 3.0 * nucleusKick +
          math.sin(clock * 31.0) * jitter,
      math.cos(clock * 8.5) * 3.0 * nucleusKick +
          math.cos(clock * 27.0) * jitter,
    );
    final c = atomCenter + wobble;
    final nucleons = gotP + gotN;

    // Ambient glow under the atom — flushes warning-amber as it destabilises.
    final glowColor = Color.lerp(_kAccent, _kWarn, instability)!;
    canvas.drawCircle(
      c,
      62,
      Paint()
        ..color = glowColor.withValues(alpha: 0.10 + 0.18 * instability)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    if (instability > 0.05) {
      // Pulsing "danger" ring around an unstable nucleus.
      canvas.drawCircle(
        c,
        30 + 4 * math.sin(clock * 12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kWarn.withValues(alpha: 0.25 + 0.5 * instability),
      );
    }

    // Electron shells fill in period order (2, 8, 8, 18, 18).
    final shellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    int remaining = gotE;
    for (int s = 0; s < _kShellCaps.length && remaining >= 0; s++) {
      final radius = 40.0 + s * 21.0;
      final inShell = math.min(remaining, _kShellCaps[s]);
      remaining -= inShell;
      final active = inShell > 0;
      shellPaint.color =
          _kElectronColor.withValues(alpha: active ? 0.35 : 0.12);
      canvas.drawCircle(c, radius, shellPaint);

      final spin = clock * (1.4 - s * 0.35) * (s.isEven ? 1 : -1);
      for (int i = 0; i < inShell; i++) {
        final a = spin + (i / math.max(1, inShell)) * math.pi * 2;
        final pos = c + Offset(math.cos(a), math.sin(a)) * radius;
        canvas.drawCircle(
          pos,
          7,
          Paint()
            ..color = _kElectronColor.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(pos, 4.2, Paint()..color = _kElectronColor);
        canvas.drawCircle(
            pos, 1.8, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
      if (remaining <= 0 && s >= 1) break;
    }

    // Nucleus: protons + neutrons packed in a sunflower-spiral cluster.
    if (nucleons == 0) {
      // Empty-core hint ring.
      canvas.drawCircle(
        c,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _kAccent.withValues(alpha: 0.4),
      );
      return;
    }
    const nucleonR = 8.0;
    final golden = math.pi * (3 - math.sqrt(5));
    // Interleave p/n through the spiral for a mixed-looking core.
    final kinds = <Color>[];
    int pLeft = gotP, nLeft = gotN;
    while (pLeft > 0 || nLeft > 0) {
      if (pLeft > 0) {
        kinds.add(_kProtonColor);
        pLeft--;
      }
      if (nLeft > 0) {
        kinds.add(_kNeutronColor);
        nLeft--;
      }
    }
    for (int i = 0; i < nucleons; i++) {
      final color = kinds[i];
      final r = nucleonR * 0.95 * math.sqrt(i + 0.5);
      final a = i * golden + math.sin(clock * 2.2 + i) * 0.05;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(
        pos,
        nucleonR + 3,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(pos, nucleonR, Paint()..color = color);
      canvas.drawCircle(pos - const Offset(2, 2), 2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  // ------------------------------------------------------ falling particles --

  void _paintFalling(Canvas canvas, _FallingParticle p) {
    final color = _kindColor(p.kind);
    final pos = Offset(p.x, p.y);

    // Glow trail behind the particle (upward, since it falls down).
    for (int i = 1; i <= 4; i++) {
      final t = i / 4.0;
      canvas.drawCircle(
        pos - Offset(0, p.vy * 0.10 * t),
        _particleRadius * (1 - 0.55 * t),
        Paint()
          ..color = color.withValues(alpha: 0.14 * (1 - t))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Pulsing halo.
    final pulse = 0.5 + 0.5 * math.sin(clock * 4 + p.phase);
    canvas.drawCircle(
      pos,
      _particleRadius + 6 + pulse * 3,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body.
    canvas.drawCircle(pos, _particleRadius, Paint()..color = color);
    canvas.drawCircle(
      pos,
      _particleRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(pos - const Offset(6, 7), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.3));

    _drawText(
      canvas,
      _kindLabel(p.kind),
      pos,
      fontSize: p.kind == _ParticleKind.neutron ? 20 : 24,
      color: Colors.black.withValues(alpha: 0.85),
      bold: true,
    );
  }

  void _paintFlier(Canvas canvas, _Flier f) {
    final t = f.t.clamp(0.0, 1.0);
    final eased = Curves.easeInQuad.transform(t);
    final pos = Offset.lerp(f.from, atomCenter, eased)!;
    final color = _kindColor(f.kind);
    final r = _particleRadius * (1 - 0.6 * t);
    canvas.drawCircle(
      pos,
      r + 6,
      Paint()
        ..color = color.withValues(alpha: 0.4 * (1 - t) + 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(pos, r, Paint()..color = color);
  }

  void _paintSpark(Canvas canvas, _BurstSpark s) {
    final t = (s.age / 0.7).clamp(0.0, 1.0);
    final dist = s.speed * s.age;
    final pos = s.origin + Offset(math.cos(s.angle), math.sin(s.angle)) * dist;
    canvas.drawCircle(
      pos,
      5 * (1 - t) + 1,
      Paint()
        ..color = s.color.withValues(alpha: (1 - t) * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintPopup(Canvas canvas, _Popup pop) {
    final t = (pop.age / 0.9).clamp(0.0, 1.0);
    final pos = pop.pos - Offset(0, 36 * Curves.easeOut.transform(t));
    _drawText(
      canvas,
      pop.text,
      pos,
      fontSize: 22 * pop.scale,
      color: pop.color.withValues(alpha: (1 - t).toDouble()),
      bold: true,
      glow: pop.color.withValues(alpha: (1 - t) * 0.8),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    bool bold = false,
    Color? glow,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          shadows:
              glow != null ? [Shadow(color: glow, blurRadius: 12)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AtomFieldPainter oldDelegate) => true;
}
