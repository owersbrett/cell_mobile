import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Decay Chain v2 — particles scale. VERB: CATCH-THE-PRODUCTS.
//
// A UX-passed rebuild of decay_chain. An unstable particle sits in the detector
// with a shrinking fuse; on decay it bursts into product particles that fly
// outward. Tap the REAL products before they escape; REFUSE the impostor that
// would violate conservation of charge. Catch a whole decay clean for a streak
// bonus. Catch an unstable product (a muon, a pion) and it re-decays where you
// caught it — a multi-step chain.
//
// UX-pass fixes (see docs/ux_pass/teardowns/decay_chain.md):
//  • Impostor tell is now READABLE UNDER MOTION — a bold segmented red ring +
//    a red ✗ "violates charge" badge — instead of a faint 12 Hz flicker.
//  • Charge legibility: every product carries a big +/−/0 charge badge early
//    (the novice aid) that FADES as difficulty climbs, leaving the bare physics
//    symbol — the late-game knowledge test (mirrors standard_model's tell-fade).
//  • The equation HUD renders as charge-coloured chips that light when a live
//    real product of that kind is in flight — tying flying orb → equation.
//  • A MELTDOWN climax: the final window runs the fastest fuses and a
//    catch-combo multiplier, resolving the ramp into a read-from-across-the-room
//    finish beat.
//
// One Ticker → one CustomPainter. All play state lives in lightweight data
// objects the painter reads by reference; the only widget is a single
// GestureDetector over a CustomPaint, so the per-frame setState is cheap.
// ═══════════════════════════════════════════════════════════════════════════

const _accent = Color(0xFF7CFC2E); // radioactive lime — the reactor energy
const _negColor = Color(0xFF40C4FF); // charge −1 (blue)
const _posColor = Color(0xFFFF7043); // charge +1 (orange)
const _neuColor = Color(0xFFB0BEC5); // charge 0 (light grey, legible)
const _cleanColor = Color(0xFF76FF03);
const _badColor = Color(0xFFFF5252);
const _meltColor = Color(0xFFFF3D00); // meltdown red

const double _meltdownStart = 0.76; // _prog at which the climax begins

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

String _chargeBadge(int c) => c < 0 ? '−' : (c > 0 ? '+' : '0');

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
  _Product(this.kind, this.impostor, this.batch, this.pos, this.vel, this.born);
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

class DecayChainV2Game extends StatefulWidget {
  final MiniGameSession session;
  const DecayChainV2Game({super.key, required this.session});

  @override
  State<DecayChainV2Game> createState() => _DecayChainV2GameState();
}

class _DecayChainV2GameState extends State<DecayChainV2Game>
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
  _P _parentKind = _P.neutron;
  List<_P> _parentProducts = const [];
  int _streak = 0; // consecutive CLEAN decays
  int _combo = 0; // consecutive catches (drives the meltdown multiplier)

  // Climax bookkeeping.
  bool _melt = false;
  double _meltBanner = 0; // fades the "MELTDOWN" callout in

  // Spectator milestone flash (big, centred, read-from-across-the-room).
  String _milestone = '';
  Color _milestoneColor = _cleanColor;
  double _milestoneT = 0;

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

  /// Novice aid strength — fades over the first 45% of the run.
  double get _aid => (1 - _prog / 0.45).clamp(0.0, 1.0);

  /// Meltdown intensity 0→1 across the final window.
  double get _meltAmt =>
      ((_prog - _meltdownStart) / (1 - _meltdownStart)).clamp(0.0, 1.0);

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
        (phase == MiniGamePhase.intro || phase == MiniGamePhase.countdown)) {
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
    _combo = 0;
    _melt = false;
    _meltBanner = 0;
    _milestone = '';
    _milestoneT = 0;
    _respawn = double.infinity;
    _flash = 0;
    _started = true;
    _spawnCentral();
  }

  void _spawnCentral() {
    _parentKind = _parents[_rng.nextInt(_parents.length)];
    final fuse = _fuse(true);
    _pending.add(_Pending(_parentKind, _center, fuse, true));
    _respawn = double.infinity;
    _parentProducts = _decay(_parentKind)!;
  }

  double _fuse(bool central) {
    var f = _lerp(central ? 1.5 : 0.95, central ? 0.8 : 0.6, _prog);
    if (_melt) f *= 0.7; // meltdown: fastest fuses
    return f;
  }

  void _updatePlay(double dt) {
    // Enter the meltdown climax once, with a banner + flash.
    if (!_melt && _prog >= _meltdownStart) {
      _melt = true;
      _meltBanner = 1.4;
      _flash = 0.9;
      _flashColor = _meltColor;
      _flashMilestone('⚠ MELTDOWN', _meltColor);
    }
    _meltBanner = math.max(0, _meltBanner - dt);

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
      if (p.central) {
        var gap = _lerp(1.6, 0.75, _prog);
        if (_melt) gap *= 0.66;
        _respawn = gap;
      }
    }

    // Move products; escapes leave the detector.
    final escaped = <_Product>[];
    final bounds = Rect.fromLTWH(-44, -44, _size.width + 88, _size.height + 88);
    for (final p in _live) {
      p.pos += p.vel * dt;
      if (!bounds.contains(p.pos)) escaped.add(p);
    }
    for (final p in escaped) {
      p.resolved = true;
      _live.remove(p);
      if (!p.impostor) {
        // A real product got away — penalty, decay no longer clean.
        widget.session.addScore(-4);
        p.batch.spoiled = true;
        _combo = 0;
      }
      _checkBatch(p.batch);
    }
  }

  void _emitDecay(_Pending pending) {
    final products = _decay(pending.kind);
    if (products == null) return;

    final batch = _Batch();
    final speed = _lerp(70, 150, _prog) * (_size.shortestSide / 380.0);
    final base = _rng.nextDouble() * 2 * math.pi;

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

    _bursts.addAll(FxBurst.spawn(pending.pos,
        _melt ? _meltColor : _accent, count: 10, speed: 90, size: 2.4));
  }

  int _impostorCount() {
    final chance = _lerp(0.22, 0.65, _prog);
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
    const tapR = 36.0;
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
      _combo = 0;
      p.batch.spoiled = true;
      _pops.add(FxPop(p.pos, '−12 IMPOSTOR', _badColor));
      _bursts.addAll(
          FxBurst.spawn(p.pos, _badColor, count: 14, speed: 130, size: 3));
      _flash = 0.8;
      _flashColor = _badColor;
    } else {
      _combo++;
      // Meltdown catch-combo multiplier — bounded so there's no runaway.
      final mult = _melt ? (1.0 + 0.25 * math.min(_combo, 4)) : 1.0; // ≤ ×2
      final pts = (10 * mult).round();
      widget.session.addScore(pts);
      p.batch.correctCaught++;
      final col = _chargeColor(_charge(p.kind));
      _pops.add(FxPop(p.pos, _melt && mult > 1 ? '+$pts' : '+10', col));
      _bursts.addAll(FxBurst.spawn(p.pos, col, count: 12, speed: 120, size: 3));

      // Unstable product → re-decays where it was caught (the chain).
      if (_decay(p.kind) != null) {
        _pending.add(_Pending(p.kind, p.pos, _fuse(false), false));
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
      final bonus = 20 + math.min(_streak, 8) * 4;
      widget.session.addScore(bonus);
      widget.session.noteStreak(_streak);
      _pops.add(FxPop(_center, 'CLEAN +$bonus', _cleanColor));
      _bursts.addAll(FxBurst.spawn(_center, _cleanColor,
          count: 22, speed: 170, size: 3.4));
      _flash = 0.6;
      _flashColor = _cleanColor;
      // Spectator milestone every few clean decays.
      if (_streak >= 3 && _streak % 3 == 0) {
        _flashMilestone('CLEAN ×$_streak', _cleanColor);
      }
    } else {
      _streak = 0;
    }
    b.awarded = true;
    _batches.remove(b);
  }

  void _flashMilestone(String text, Color color) {
    _milestone = text;
    _milestoneColor = color;
    _milestoneT = 1.1;
  }

  void _stepFx(double dt) {
    _bursts.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    _flash = math.max(0, _flash - dt * 2.4);
    _milestoneT = math.max(0, _milestoneT - dt);
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
                parentKind: _parentKind,
                parentProducts: _parentProducts,
                streak: _streak,
                combo: _combo,
                aid: _aid,
                melt: _melt,
                meltAmt: _meltAmt,
                meltBanner: _meltBanner,
                milestone: _milestone,
                milestoneColor: _milestoneColor,
                milestoneT: _milestoneT,
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
  final _P parentKind;
  final List<_P> parentProducts;
  final int streak;
  final int combo;
  final double aid;
  final bool melt;
  final double meltAmt;
  final double meltBanner;
  final String milestone;
  final Color milestoneColor;
  final double milestoneT;

  _DecayPainter({
    required this.clock,
    required this.started,
    required this.pending,
    required this.live,
    required this.bursts,
    required this.pops,
    required this.flash,
    required this.flashColor,
    required this.parentKind,
    required this.parentProducts,
    required this.streak,
    required this.combo,
    required this.aid,
    required this.melt,
    required this.meltAmt,
    required this.meltBanner,
    required this.milestone,
    required this.milestoneColor,
    required this.milestoneT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, melt ? _meltColor : _accent, clock,
        motes: 30);
    final center = Offset(size.width / 2, size.height / 2);

    _detectorRing(canvas, center, size);
    if (melt) _meltdownEdges(canvas, size);

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
    _milestoneOverlay(canvas, size);
    _flashOverlay(canvas, size);
  }

  void _detectorRing(Canvas canvas, Offset center, Size size) {
    final r = size.shortestSide * 0.46;
    final ringCol = melt ? _meltColor : _accent;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = ringCol.withValues(alpha: 0.14 + 0.12 * meltAmt),
    );
    final tick = Paint()..color = ringCol.withValues(alpha: 0.18);
    final spin = clock * (0.12 + 0.4 * meltAmt);
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

  /// Meltdown: pulsing red vignette at the screen edges — read from across the
  /// room without looking at the score.
  void _meltdownEdges(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(clock * 7);
    final a = (0.10 + 0.16 * meltAmt) * (0.6 + 0.4 * pulse);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _meltColor.withValues(alpha: 0.0),
            _meltColor.withValues(alpha: a),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  void _pendingParticle(Canvas canvas, _Pending p) {
    final t = (p.fuse / p.fuseMax).clamp(0.0, 1.0);
    final urgency = 1 - t;
    final pulse = 1 + 0.10 * math.sin(clock * (6 + urgency * 18));
    final r = (p.central ? 26.0 : 18.0) * pulse;
    final c = _chargeColor(_charge(p.kind));

    canvas.drawCircle(
      p.pos,
      r + 12 + urgency * 10,
      Paint()
        ..color = (melt ? _meltColor : _accent)
            .withValues(alpha: 0.10 + 0.25 * urgency)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    GameFx.orb(canvas, p.pos, r, c, glow: 1.0, rim: melt ? _meltColor : _accent);

    final fuseCol = Color.lerp(_badColor, melt ? _meltColor : _accent, t)!;
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

    GameFx.text(canvas, _sym(p.kind), p.pos, p.central ? 18 : 14, Colors.white,
        weight: FontWeight.w800, glow: 0.6);
  }

  void _product(Canvas canvas, _Product p) {
    final age = (clock - p.born).clamp(0.0, 1.0);
    final fade = (age / 0.18).clamp(0.0, 1.0);
    final ch = _charge(p.kind);
    final c = _chargeColor(ch);
    final r = 15.0 * fade;

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

    // Real products get a soft green "belongs" halo early (the novice aid),
    // which fades as difficulty climbs.
    if (!p.impostor && aid > 0.02) {
      canvas.drawCircle(
        p.pos,
        r + 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _cleanColor.withValues(alpha: 0.45 * aid * fade),
      );
    }

    GameFx.orb(canvas, p.pos, r, c, glow: 0.9);
    GameFx.text(canvas, _sym(p.kind), p.pos, 13,
        Colors.white.withValues(alpha: fade),
        weight: FontWeight.w800);

    // Charge badge — the readable charge label. Big & bright early (novice
    // aid), shrinks toward a small persistent dot of colour as the aid fades.
    final badgeA = (0.35 + 0.65 * aid) * fade;
    final badgeR = (6.0 + 3.0 * aid);
    final bc = Offset(p.pos.dx + r + 2, p.pos.dy - r - 2);
    canvas.drawCircle(bc, badgeR,
        Paint()..color = c.withValues(alpha: 0.9 * badgeA));
    canvas.drawCircle(
        bc,
        badgeR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.7 * badgeA));
    if (aid > 0.04) {
      GameFx.text(canvas, _chargeBadge(ch), bc, 10 + 2 * aid,
          Colors.white.withValues(alpha: badgeA),
          weight: FontWeight.w900);
    }

    // IMPOSTOR TELL — readable under motion: a bold segmented red ring that
    // pulses slowly (not a faint 12 Hz flicker) + a red ✗ "violates charge"
    // badge. This is the always-on, refuse-it-on-skill cue.
    if (p.impostor) {
      final warn = 0.72 + 0.28 * math.sin(clock * 5);
      final ringR = r + 7;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _badColor.withValues(alpha: 0.95 * warn * fade);
      const seg = 12;
      for (var i = 0; i < seg; i++) {
        final a0 = clock * 1.2 + i / seg * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: p.pos, radius: ringR),
          a0,
          (2 * math.pi / seg) * 0.55,
          false,
          ringPaint,
        );
      }
      // ✗ badge, top-left, opposite the charge badge.
      final xc = Offset(p.pos.dx - r - 2, p.pos.dy - r - 2);
      canvas.drawCircle(xc, 8.0 * fade,
          Paint()..color = _badColor.withValues(alpha: 0.95 * warn * fade));
      GameFx.text(canvas, '✗', xc, 12 * fade,
          Colors.white.withValues(alpha: fade),
          weight: FontWeight.w900);
    }
  }

  void _hud(Canvas canvas, Size size) {
    // Equation as charge-coloured chips. A product chip lights when a live real
    // product of that kind is in flight (ties flying orb → equation).
    _equationHud(canvas, size);

    // Persistent reminder.
    GameFx.text(canvas, 'catch the real products · refuse the ✗ impostor',
        Offset(size.width / 2, 52), 10.5, Potatuhs.textFaint);

    // Spectator standing — streak (and combo during meltdown).
    if (streak > 1) {
      GameFx.text(canvas, '×$streak CLEAN',
          Offset(size.width / 2, size.height - 22), 14, _cleanColor,
          weight: FontWeight.w800, glow: 0.5);
    }
    if (melt && combo >= 2) {
      final pulse = 0.7 + 0.3 * math.sin(clock * 9);
      GameFx.text(canvas, 'COMBO ×$combo',
          Offset(size.width / 2, size.height - 46), 17,
          _meltColor.withValues(alpha: pulse),
          weight: FontWeight.w900, glow: 0.6);
    }
  }

  void _equationHud(Canvas canvas, Size size) {
    final products = parentProducts;
    if (products.isEmpty) return;

    // Build the token list: parent, '→', products joined by '+'.
    // Measure widths to centre the row.
    const gap = 8.0;
    final cx = size.width / 2;
    const y = 24.0;

    // Pre-measure.
    final widths = <double>[];
    double total = 0;
    double tokenW(String s, double fs) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: fs,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    // tokens: [parentSym, '→', prod0, '+', prod1, '+', ...]
    final tokens = <_Tok>[];
    tokens.add(_Tok(_sym(parentKind), _chargeColor(_charge(parentKind)), true));
    tokens.add(_Tok('→', Potatuhs.textFaint, false));
    for (var i = 0; i < products.length; i++) {
      if (i > 0) tokens.add(_Tok('+', Potatuhs.textFaint, false));
      tokens.add(_Tok(_sym(products[i]), _chargeColor(_charge(products[i])),
          true, products[i]));
    }
    for (final t in tokens) {
      final w = tokenW(t.text, 17);
      widths.add(w);
      total += w + gap;
    }
    total -= gap;

    double x = cx - total / 2;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      final w = widths[i];
      final mid = Offset(x + w / 2, y);
      if (t.isParticle && t.kind != null) {
        // Light the chip if a live, unresolved real product of this kind flies.
        final lit = live.any((p) => !p.impostor && !p.resolved && p.kind == t.kind);
        if (lit) {
          canvas.drawCircle(
            mid,
            w / 2 + 8,
            Paint()
              ..color = t.color.withValues(alpha: 0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
      }
      GameFx.text(canvas, t.text, mid, 17, t.color,
          weight: FontWeight.w900, glow: t.isParticle ? 0.3 : 0);
      x += w + gap;
    }
  }

  void _milestoneOverlay(Canvas canvas, Size size) {
    if (milestoneT <= 0) return;
    final a = (milestoneT / 1.1).clamp(0.0, 1.0);
    final pop = 1.0 + 0.25 * (1 - a);
    GameFx.text(canvas, milestone, Offset(size.width / 2, size.height * 0.40),
        30 * pop, milestoneColor.withValues(alpha: a),
        display: true, glow: 0.7 * a);
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
    GameFx.text(canvas, 'n⁰', center, 18, Colors.white, weight: FontWeight.w800);
    GameFx.text(canvas, 'REACTOR PRIMED', center.translate(0, 64), 13, _accent,
        weight: FontWeight.w800, glow: 0.5);
    GameFx.text(canvas, 'tap the real products · refuse the ✗ impostor',
        center.translate(0, 86), 11, Potatuhs.textFaint);
  }

  void _flashOverlay(Canvas canvas, Size size) {
    // Meltdown banner rides on top of the flash overlay.
    if (meltBanner > 0) {
      final a = (meltBanner / 1.4).clamp(0.0, 1.0);
      GameFx.text(canvas, '⚠ MELTDOWN', Offset(size.width / 2, size.height * 0.5),
          40 + 12 * (1 - a), _meltColor.withValues(alpha: a),
          display: true, glow: 0.8 * a);
      GameFx.text(canvas, 'fastest fuses · combo multiplier live',
          Offset(size.width / 2, size.height * 0.5 + 38), 12,
          Potatuhs.textSecondary.withValues(alpha: a),
          weight: FontWeight.w700);
    }
    if (flash <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = flashColor.withValues(alpha: 0.12 * flash),
    );
  }

  @override
  bool shouldRepaint(covariant _DecayPainter oldDelegate) => true;
}

/// A drawn token in the equation HUD.
class _Tok {
  final String text;
  final Color color;
  final bool isParticle;
  final _P? kind;
  _Tok(this.text, this.color, this.isParticle, [this.kind]);
}
