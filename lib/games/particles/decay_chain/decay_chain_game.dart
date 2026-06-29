import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Decay Chain — particles scale. VERB: CATCH-THE-PRODUCTS.
//
// An unstable particle sits in the detector with a shrinking decay fuse. When
// it DECAYS it bursts into product particles that fly outward. Tap the REAL
// decay products before they escape; the impostor that sneaks in would violate
// conservation of charge — tap it and you're penalised. Catch a whole decay
// clean for a streak bonus. Catch an unstable product (a muon, a pion) and it
// decays AGAIN where you caught it — a multi-step chain.
//
// One Ticker → one CustomPainter. All play state lives in lightweight data
// objects the painter reads by reference; the only widget is a single
// GestureDetector over a CustomPaint, so the per-frame setState is cheap.
// ═══════════════════════════════════════════════════════════════════════════

const _accent = Color(0xFF64DD17); // radioactive lime — the reactor energy
const _negColor = Color(0xFF40C4FF); // charge −1 (blue)
const _posColor = Color(0xFFFF7043); // charge +1 (orange)
const _neuColor = Color(0xFF9E9E9E); // charge 0 (grey)
const _cleanColor = Color(0xFF76FF03);
const _badColor = Color(0xFFFF5252);

/// The particle species roster. Symbols carry their charge so the equation
/// reads like real physics: `n⁰ → p⁺ + e⁻ + ν̄`.
enum _P {
  electron,
  positron,
  proton,
  neutron,
  muon,
  pion,
  photon,
  neutrino,
  antineutrino,
}

int _charge(_P p) {
  switch (p) {
    case _P.electron:
    case _P.muon:
    case _P.pion:
      return -1;
    case _P.positron:
    case _P.proton:
      return 1;
    case _P.neutron:
    case _P.photon:
    case _P.neutrino:
    case _P.antineutrino:
      return 0;
  }
}

String _sym(_P p) {
  switch (p) {
    case _P.electron:
      return 'e⁻';
    case _P.positron:
      return 'e⁺';
    case _P.proton:
      return 'p⁺';
    case _P.neutron:
      return 'n⁰';
    case _P.muon:
      return 'μ⁻';
    case _P.pion:
      return 'π⁻';
    case _P.photon:
      return 'γ';
    case _P.neutrino:
      return 'ν';
    case _P.antineutrino:
      return 'ν̄';
  }
}

/// Decay products for an unstable species (charge is conserved in every list).
/// `null` ⇒ stable on this timescale (a catch end-point, no further chain).
List<_P>? _decay(_P p) {
  switch (p) {
    case _P.neutron: // β⁻ decay
      return const [_P.proton, _P.electron, _P.antineutrino];
    case _P.muon:
      return const [_P.electron, _P.neutrino, _P.antineutrino];
    case _P.pion: // → muon (itself unstable: the multi-step chain)
      return const [_P.muon, _P.antineutrino];
    default:
      return null;
  }
}

Color _chargeColor(int c) =>
    c < 0 ? _negColor : (c > 0 ? _posColor : _neuColor);

/// Species that can seed a fresh decay in the detector.
const _parents = [_P.neutron, _P.muon, _P.pion];

/// An impostor never belongs to the current decay — catching it breaks
/// conservation. Drawn from this pool minus the real products.
const _impostorPool = [_P.positron, _P.photon, _P.proton, _P.muon, _P.electron];

// ───────────────────────────────────────────────────────────────────────────

/// A bookkeeping record for one decay event: did the player catch every real
/// product with no impostors and no escapes? Then it's a CLEAN decay.
class _Batch {
  final List<_Product> products = [];
  int correctTotal = 0;
  int correctCaught = 0;
  bool spoiled = false; // an impostor caught OR a real product escaped
  bool awarded = false;
}

/// A product particle in flight after a decay.
class _Product {
  final _P kind;
  final bool impostor;
  final _Batch batch;
  Offset pos;
  Offset vel;
  double born; // clock at spawn (fade-in)
  bool resolved = false;
  _Product(this.kind, this.impostor, this.batch, this.pos, this.vel,
      this.born);
}

/// An unstable particle waiting to decay (the central reactor, or a chained
/// product caught mid-flight that re-decays in place).
class _Pending {
  final _P kind;
  final Offset pos;
  double fuse;
  final double fuseMax;
  final bool central;
  _Pending(this.kind, this.pos, this.fuse, this.central) : fuseMax = fuse;
}

class DecayChainGame extends StatefulWidget {
  final MiniGameSession session;
  const DecayChainGame({super.key, required this.session});

  @override
  State<DecayChainGame> createState() => _DecayChainGameState();
}

class _DecayChainGameState extends State<DecayChainGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  double _clock = 0; // always-advancing visual clock
  double _elapsed = 0; // play-time clock (difficulty ramp)
  bool _started = false;

  final List<_Pending> _pending = [];
  final List<_Product> _live = [];
  final List<_Batch> _batches = [];
  double _respawn = double.infinity; // countdown to next central parent
  String _equation = '';
  int _streak = 0;

  // Juice.
  final List<FxParticle> _bursts = [];
  final List<FxPop> _pops = [];
  double _flash = 0;
  Color _flashColor = _cleanColor;

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

  double get _prog =>
      (_elapsed / widget.session.spec.durationSeconds).clamp(0.0, 1.0);

  Offset get _center => Offset(_size.width / 2, _size.height / 2);

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt <= 0) return;

    _clock += dt;
    final session = widget.session;
    final running = session.isRunning;
    final phase = session.phase;

    // Re-arm for a fresh run when the host resets to intro/countdown.
    if (!running &&
        (phase == MiniGamePhase.intro ||
            phase == MiniGamePhase.countdown)) {
      _started = false;
    }

    if (running && !_started && _size.shortestSide > 10) {
      _begin();
    }
    if (running && _started) {
      _elapsed += dt;
      _updatePlay(dt);
    }

    _stepFx(dt);
    setState(() {});
  }

  void _begin() {
    _pending.clear();
    _live.clear();
    _batches.clear();
    _bursts.clear();
    _pops.clear();
    _elapsed = 0;
    _streak = 0;
    _respawn = double.infinity;
    _flash = 0;
    _started = true;
    _spawnCentral();
  }

  void _spawnCentral() {
    final kind = _parents[_rng.nextInt(_parents.length)];
    final fuse = _lerp(1.5, 0.8, _prog);
    _pending.add(_Pending(kind, _center, fuse, true));
    _respawn = double.infinity;
    final products = _decay(kind)!;
    _equation =
        '${_sym(kind)} → ${products.map(_sym).join(' + ')}';
  }

  void _updatePlay(double dt) {
    // Central-reactor cadence.
    if (_respawn.isFinite) {
      _respawn -= dt;
      if (_respawn <= 0) _spawnCentral();
    }

    // Fuses → decays.
    final expired = <_Pending>[];
    for (final p in _pending) {
      p.fuse -= dt;
      if (p.fuse <= 0) expired.add(p);
    }
    for (final p in expired) {
      _pending.remove(p);
      _emitDecay(p);
      if (p.central) _respawn = _lerp(1.6, 0.7, _prog);
    }

    // Move products; escapes leave the detector.
    final escaped = <_Product>[];
    final bounds =
        Rect.fromLTWH(-44, -44, _size.width + 88, _size.height + 88);
    for (final p in _live) {
      p.pos += p.vel * dt;
      if (!bounds.contains(p.pos)) escaped.add(p);
    }
    for (final p in escaped) {
      p.resolved = true;
      _live.remove(p);
      if (!p.impostor) {
        // A real product got away — penalty, decay no longer clean.
        widget.session.addScore(-5);
        p.batch.spoiled = true;
      }
      _checkBatch(p.batch);
    }
  }

  void _emitDecay(_Pending pending) {
    final products = _decay(pending.kind);
    if (products == null) return;

    final batch = _Batch();
    final speed = _lerp(72, 150, _prog) * (_size.shortestSide / 380.0);
    final base = _rng.nextDouble() * 2 * math.pi;

    // Real products fan out evenly.
    final all = <_P>[...products];
    final impostorCount = _impostorCount();
    for (var i = 0; i < impostorCount; i++) {
      final imp = _pickImpostor(products);
      if (imp != null) all.add(imp);
    }

    final n = all.length;
    for (var i = 0; i < n; i++) {
      final kind = all[i];
      final isImp = i >= products.length;
      final ang = base + i / n * 2 * math.pi + (_rng.nextDouble() - 0.5) * 0.5;
      final v = speed * (0.85 + _rng.nextDouble() * 0.35);
      final prod = _Product(
        kind,
        isImp,
        batch,
        pending.pos,
        Offset(math.cos(ang), math.sin(ang)) * v,
        _clock,
      );
      batch.products.add(prod);
      if (!isImp) batch.correctTotal++;
      _live.add(prod);
    }
    _batches.add(batch);

    // A little puff at the decay vertex.
    _bursts.addAll(
        FxBurst.spawn(pending.pos, _accent, count: 10, speed: 90, size: 2.4));
  }

  int _impostorCount() {
    final chance = _lerp(0.25, 0.7, _prog);
    var c = _rng.nextDouble() < chance ? 1 : 0;
    if (_prog > 0.5 && _rng.nextDouble() < chance * 0.5) c++;
    return c;
  }

  _P? _pickImpostor(List<_P> real) {
    final pool = _impostorPool.where((k) => !real.contains(k)).toList();
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  void _handleTap(Offset at) {
    if (!widget.session.isRunning) return;
    final tapR = 34.0;
    _Product? best;
    var bestD = tapR * tapR;
    for (final p in _live) {
      if (p.resolved) continue;
      final d = (p.pos - at).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    if (best != null) _resolveCatch(best);
  }

  void _resolveCatch(_Product p) {
    p.resolved = true;
    _live.remove(p);

    if (p.impostor) {
      widget.session.addScore(-12);
      _streak = 0;
      p.batch.spoiled = true;
      _pops.add(FxPop(p.pos, '−12 IMPOSTOR', _badColor));
      _bursts.addAll(
          FxBurst.spawn(p.pos, _badColor, count: 14, speed: 130, size: 3));
      _flash = 0.8;
      _flashColor = _badColor;
    } else {
      widget.session.addScore(10);
      p.batch.correctCaught++;
      final col = _chargeColor(_charge(p.kind));
      _pops.add(FxPop(p.pos, '+10', col));
      _bursts.addAll(FxBurst.spawn(p.pos, col, count: 12, speed: 120, size: 3));

      // Unstable product → re-decays where it was caught (the chain).
      if (_decay(p.kind) != null) {
        _pending.add(_Pending(p.kind, p.pos, _lerp(0.95, 0.6, _prog), false));
        _pops.add(FxPop(p.pos.translate(0, 18), 'CHAIN!', _accent));
      }
    }
    _checkBatch(p.batch);
  }

  void _checkBatch(_Batch b) {
    if (b.awarded) return;
    if (!b.products.every((p) => p.resolved)) return;

    if (!b.spoiled && b.correctCaught == b.correctTotal) {
      _streak++;
      final bonus = 25 + math.min(_streak, 10) * 3;
      widget.session.addScore(bonus);
      widget.session.noteStreak(_streak);
      _pops.add(FxPop(_center, 'CLEAN +$bonus', _cleanColor));
      _bursts.addAll(
          FxBurst.spawn(_center, _cleanColor, count: 22, speed: 170, size: 3.4));
      _flash = 0.7;
      _flashColor = _cleanColor;
    } else {
      _streak = 0;
    }
    b.awarded = true;
    _batches.remove(b);
  }

  void _stepFx(double dt) {
    _bursts.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    _flash = math.max(0, _flash - dt * 2.4);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleTap(d.localPosition),
          child: ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: _DecayPainter(
                clock: _clock,
                started: _started,
                pending: _pending,
                live: _live,
                bursts: _bursts,
                pops: _pops,
                flash: _flash,
                flashColor: _flashColor,
                equation: _equation,
                streak: _streak,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Painter — one pass, reads game state by reference.
// ───────────────────────────────────────────────────────────────────────────

class _DecayPainter extends CustomPainter {
  final double clock;
  final bool started;
  final List<_Pending> pending;
  final List<_Product> live;
  final List<FxParticle> bursts;
  final List<FxPop> pops;
  final double flash;
  final Color flashColor;
  final String equation;
  final int streak;

  _DecayPainter({
    required this.clock,
    required this.started,
    required this.pending,
    required this.live,
    required this.bursts,
    required this.pops,
    required this.flash,
    required this.flashColor,
    required this.equation,
    required this.streak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _accent, clock, motes: 30);
    final center = Offset(size.width / 2, size.height / 2);

    _detectorRing(canvas, center, size);

    if (!started) {
      _primer(canvas, center, size);
      _flashOverlay(canvas, size);
      return;
    }

    for (final p in pending) {
      _pendingParticle(canvas, p);
    }
    for (final p in live) {
      _product(canvas, p);
    }

    FxBurst.paint(canvas, bursts);
    for (final p in pops) {
      p.paint(canvas);
    }

    _hud(canvas, size);
    _flashOverlay(canvas, size);
  }

  void _detectorRing(Canvas canvas, Offset center, Size size) {
    final r = size.shortestSide * 0.46;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _accent.withValues(alpha: 0.14),
    );
    // Slowly rotating detector ticks for life.
    final tick = Paint()..color = _accent.withValues(alpha: 0.18);
    final spin = clock * 0.12;
    for (var i = 0; i < 48; i++) {
      final a = spin + i * math.pi / 24;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * r,
        center + dir * (r + (i % 6 == 0 ? 8 : 3)),
        tick..strokeWidth = i % 6 == 0 ? 1.6 : 1.0,
      );
    }
  }

  void _pendingParticle(Canvas canvas, _Pending p) {
    final t = (p.fuse / p.fuseMax).clamp(0.0, 1.0);
    final urgency = 1 - t; // 0 → 1 as it nears decay
    final pulse = 1 + 0.10 * math.sin(clock * (6 + urgency * 18));
    final r = (p.central ? 26.0 : 18.0) * pulse;
    final c = _chargeColor(_charge(p.kind));

    // Energetic halo that intensifies near decay.
    canvas.drawCircle(
      p.pos,
      r + 12 + urgency * 10,
      Paint()
        ..color = _accent.withValues(alpha: 0.10 + 0.25 * urgency)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    GameFx.orb(canvas, p.pos, r, c, glow: 1.0, rim: _accent);

    // Decay fuse arc (lime → red as it expires).
    final fuseCol = Color.lerp(_badColor, _accent, t)!;
    canvas.drawArc(
      Rect.fromCircle(center: p.pos, radius: r + 7),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = fuseCol.withValues(alpha: 0.95),
    );

    GameFx.text(canvas, _sym(p.kind), p.pos, p.central ? 18 : 14,
        Colors.white, weight: FontWeight.w800, glow: 0.6);
  }

  void _product(Canvas canvas, _Product p) {
    final age = (clock - p.born).clamp(0.0, 1.0);
    final fade = (age / 0.18).clamp(0.0, 1.0);
    final c = _chargeColor(_charge(p.kind));
    final r = 15.0;

    // Motion trail.
    final back = p.pos - (p.vel * 0.06);
    canvas.drawLine(
      back,
      p.pos,
      Paint()
        ..color = c.withValues(alpha: 0.35 * fade)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Impostors flicker with a warning ring so a sharp eye can refuse them.
    if (p.impostor) {
      final warn = 0.5 + 0.5 * math.sin(clock * 12);
      canvas.drawCircle(
        p.pos,
        r + 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _badColor.withValues(alpha: 0.5 * warn * fade),
      );
    }

    GameFx.orb(canvas, p.pos, r * fade, c, glow: 0.9);
    GameFx.text(canvas, _sym(p.kind), p.pos, 13,
        Colors.white.withValues(alpha: fade),
        weight: FontWeight.w800);
  }

  void _hud(Canvas canvas, Size size) {
    if (equation.isNotEmpty) {
      GameFx.text(canvas, equation, Offset(size.width / 2, 22), 16,
          Potatuhs.textPrimary,
          weight: FontWeight.w800, glow: 0.4);
      GameFx.text(canvas, 'catch the real products · refuse the impostor',
          Offset(size.width / 2, 42), 10.5, Potatuhs.textFaint);
    }
    if (streak > 1) {
      GameFx.text(canvas, '×$streak CLEAN', Offset(size.width / 2, size.height - 22),
          14, _cleanColor,
          weight: FontWeight.w800, glow: 0.5);
    }
  }

  void _primer(Canvas canvas, Offset center, Size size) {
    final pulse = 1 + 0.06 * math.sin(clock * 2.0);
    canvas.drawCircle(
      center,
      40 * pulse,
      Paint()
        ..color = _accent.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    GameFx.orb(canvas, center, 26 * pulse, _neuColor, glow: 1.0, rim: _accent);
    GameFx.text(canvas, 'n⁰', center, 18, Colors.white,
        weight: FontWeight.w800);
    GameFx.text(canvas, 'REACTOR PRIMED', center.translate(0, 64), 13,
        _accent,
        weight: FontWeight.w800, glow: 0.5);
    GameFx.text(canvas, 'tap the decay products as they fly out',
        center.translate(0, 86), 11, Potatuhs.textFaint);
  }

  void _flashOverlay(Canvas canvas, Size size) {
    if (flash <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = flashColor.withValues(alpha: 0.12 * flash),
    );
  }

  @override
  bool shouldRepaint(covariant _DecayPainter oldDelegate) => true;
}
