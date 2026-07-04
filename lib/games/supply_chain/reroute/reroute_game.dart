import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Reroute! — disruption & resilience on the supply-chain scale.
///
/// A handful of source FARMS / PORTS on the left feed your FACTORY on the
/// right along routes (edges). Goods flow down the ONE active route into the
/// factory's input silo (a buffer). The factory consumes that buffer to make
/// fries/chips, and PRODUCES — and scores — only while it has supply.
///
/// Disruptions strike live: a route goes DOWN (storm / closure — drawn broken)
/// or a source DEPLETES (drought — drawn empty). When your active supply line
/// breaks, the silo stops refilling and the factory STARVES. The player TAPS a
/// healthy alternate source to REROUTE and keep the line fed. The skill is
/// keeping diverse backups ready: the cheapest/closest routes fail most, so a
/// single fast supplier is fragile — redundancy is what survives the shocks.
///
/// The host (MiniGameHost) owns the timer, 3-2-1 countdown, score HUD and
/// results; this widget only renders the 60-second play area and reports
/// produced units to the session. Everything — network, flowing goods and
/// disruption FX — is drawn by ONE [CustomPainter] driven by ONE ticker, with
/// no per-frame setState, to stay cheap.
class RerouteGame extends StatefulWidget {
  final MiniGameSession session;
  const RerouteGame({super.key, required this.session});

  @override
  State<RerouteGame> createState() => _RerouteGameState();
}

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _accent = Color(0xFF2EC4B6); // logistics teal — "flow / resilience"
const Color _good = Color(0xFF66E08A); // healthy / rerouted green
const Color _danger = Color(0xFFE5533D); // route down / starving red
const Color _idleSrc = Color(0xFF8FA8B2); // a healthy-but-idle source

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the SAME
// primitives the live game uses (source orbs + stock arc, the factory + silo
// gauge, the flowing goods beam and the severed-route dash). Static, cheap,
// size-guarded — rendered once in the intro, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One source node: an orb + its stock arc + name/state labels — a stripped
/// copy of the game's own `_drawSource`.
void _legSource(
  Canvas canvas,
  Offset c,
  double r, {
  required Color color,
  double stock = 1.0,
  bool active = false,
  String? name,
  String? state,
  Color? stateColor,
}) {
  GameFx.orb(canvas, c, r, color, glow: active ? 1.0 : 0.5);
  if (active) {
    canvas.drawCircle(
      c,
      r + 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _good.withValues(alpha: 0.9),
    );
  }
  final sweep = stock.clamp(0.0, 1.0) * 2 * math.pi;
  if (sweep > 0) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 4),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = (stock < 0.2 ? _danger : _good).withValues(alpha: 0.85),
    );
  }
  if (name != null) {
    GameFx.text(canvas, name, c.translate(0, r + 14), 9.5,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w700);
  }
  if (state != null) {
    GameFx.text(canvas, state, c.translate(0, r + 26), 8,
        stateColor ?? Colors.white.withValues(alpha: 0.45),
        weight: FontWeight.w800);
  }
}

/// The factory orb + its input-silo gauge — a stripped copy of `_drawFactory`.
void _legFactory(Canvas canvas, Offset c, double buffer, {bool starving = false}) {
  const r = 28.0;
  final body = starving ? Color.lerp(Potatuhs.orange, _danger, 0.55)! : Potatuhs.orange;
  GameFx.orb(canvas, c, r, body, glow: 0.9);
  GameFx.text(canvas, 'FACTORY', c.translate(0, r + 14), 11,
      Colors.white.withValues(alpha: 0.75), weight: FontWeight.w800);

  const barH = 60.0, barW = 12.0;
  final left = c.dx - r - 24;
  final top = c.dy - barH / 2;
  final track = Rect.fromLTWH(left, top, barW, barH);
  final rr = RRect.fromRectAndRadius(track, const Radius.circular(6));
  canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.4));
  final fillH = barH * buffer.clamp(0.0, 1.0);
  final fillColor =
      buffer < 0.18 ? _danger : (buffer < 0.45 ? Potatuhs.sienna : _good);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top + (barH - fillH), barW, fillH),
        const Radius.circular(6)),
    Paint()..color = fillColor,
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.25),
  );
  GameFx.text(canvas, 'SILO', Offset(left + barW / 2, top - 10), 8,
      Colors.white.withValues(alpha: 0.5));
  if (starving) {
    GameFx.text(canvas, 'STARVING', c.translate(0, -r - 16), 12,
        _danger.withValues(alpha: 0.9), weight: FontWeight.w800, glow: 0.5);
  }
}

/// A live supply line: the bright flowing beam + travelling goods dots.
void _legLiveRoute(Canvas canvas, Offset a, Offset b) {
  GameFx.glowLine(canvas, a, b, _accent, width: 3.5);
  for (var i = 0; i < 4; i++) {
    final p = Offset.lerp(a, b, (i + 1) / 5)!;
    canvas.drawCircle(p, 4, Paint()..color = _good.withValues(alpha: 0.95));
    canvas.drawCircle(
      p,
      6,
      Paint()
        ..color = _good.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}

/// A severed route: red dashed line with a break + storm ✕ — mirrors
/// `_drawBrokenRoute` without the live pulse.
void _legBrokenRoute(Canvas canvas, Offset a, Offset b) {
  final paint = Paint()
    ..color = _danger.withValues(alpha: 0.65)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  const dash = 10.0, gap = 8.0;
  final dir = b - a;
  final len = dir.distance;
  if (len <= 0) return;
  final unit = dir / len;
  var d = 0.0;
  while (d < len) {
    if ((d / len - 0.5).abs() > 0.10) {
      canvas.drawLine(
          a + unit * d, a + unit * math.min(d + dash, len), paint);
    }
    d += dash + gap;
  }
  final breakPt = Offset.lerp(a, b, 0.5)!;
  canvas.drawCircle(
    breakPt,
    8,
    Paint()
      ..color = _danger.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  GameFx.text(canvas, '✕', breakPt, 16, _danger);
}

/// A dim, standing idle backup route (drawn under the nodes).
void _legIdleRoute(Canvas canvas, Offset a, Offset b) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = _idleSrc.withValues(alpha: 0.22)
      ..strokeWidth = 2,
  );
}

/// FRAME 1 — the network & the core verb: tap a healthy backup to reroute the
/// live line onto it.
void _legendReroute(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 8 || h < 8) return;
  final factory = Offset(w * 0.76, h * 0.5);
  final active = Offset(w * 0.2, h * 0.3);
  final backup = Offset(w * 0.2, h * 0.72);

  _legLiveRoute(canvas, active, factory);
  _legIdleRoute(canvas, backup, factory);
  _legFactory(canvas, factory, 0.75);
  _legSource(canvas, active, 18,
      color: _accent, active: true, name: 'Farm', state: 'FEEDING', stateColor: _good);
  _legSource(canvas, backup, 18,
      color: _idleSrc, name: 'Port', state: 'READY');

  // Tap cue on the ready backup.
  canvas.drawCircle(
    backup,
    28,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _good.withValues(alpha: 0.7),
  );
  GameFx.text(canvas, 'TAP', backup.translate(0, -34), 11, _good,
      weight: FontWeight.w800, glow: 0.4);
}

/// FRAME 2 — scoring: a fed silo keeps the factory producing (+1 per unit).
void _legendScore(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 8 || h < 8) return;
  final factory = Offset(w * 0.66, h * 0.5);
  final source = Offset(w * 0.18, h * 0.5);

  _legLiveRoute(canvas, source, factory);
  _legFactory(canvas, factory, 0.95);
  _legSource(canvas, source, 18,
      color: _accent, active: true, name: 'Farm', state: 'FEEDING', stateColor: _good);
  GameFx.text(canvas, '+1', factory.translate(w * 0.16, -h * 0.1), 22, _good,
      weight: FontWeight.w800, glow: 0.6);
}

/// FRAME 3 — the danger: storms down routes, droughts empty sources; a cut-off
/// factory starves and scores nothing.
void _legendDanger(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 8 || h < 8) return;
  final factory = Offset(w * 0.76, h * 0.5);
  final downSrc = Offset(w * 0.2, h * 0.3);
  final drySrc = Offset(w * 0.2, h * 0.72);

  _legBrokenRoute(canvas, downSrc, factory);
  _legIdleRoute(canvas, drySrc, factory);
  _legFactory(canvas, factory, 0.06, starving: true);
  _legSource(canvas, downSrc, 18,
      color: _danger, stock: 1.0, name: 'Farm', state: 'DOWN', stateColor: _danger);
  _legSource(canvas, drySrc, 18,
      color: _danger, stock: 0.0, name: 'Port', state: 'EMPTY', stateColor: _danger);
}

/// FRAME 4 — the escalation: late in the round shocks strike TWO routes at
/// once, so keep diverse backups ready.
void _legendEscalation(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 8 || h < 8) return;
  final factory = Offset(w * 0.76, h * 0.5);
  final s0 = Offset(w * 0.2, h * 0.22);
  final s1 = Offset(w * 0.2, h * 0.5);
  final s2 = Offset(w * 0.2, h * 0.78);

  _legBrokenRoute(canvas, s0, factory);
  _legBrokenRoute(canvas, s2, factory);
  _legLiveRoute(canvas, s1, factory);
  _legFactory(canvas, factory, 0.6);
  _legSource(canvas, s0, 15, color: _danger, name: null, state: 'DOWN', stateColor: _danger);
  _legSource(canvas, s1, 15,
      color: _accent, active: true, name: null, state: 'FEEDING', stateColor: _good);
  _legSource(canvas, s2, 15, color: _danger, name: null, state: 'DOWN', stateColor: _danger);
}

/// The visual manual for Reroute! — wired into the registry spec.
final List<LegendFrame> rerouteLegendFrames = [
  const LegendFrame(
      caption: 'Tap a healthy source to REROUTE the live line',
      paint: _legendReroute),
  const LegendFrame(
      caption: 'A fed silo keeps the factory making fries: +1 each',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Storms down routes, droughts empty sources — starve = 0',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Late game shocks hit TWO routes — keep backups ready',
      paint: _legendEscalation),
];

/// A source farm/port and its single route to the factory.
class _Source {
  final String name;
  final Offset pos; // normalised 0..1 in the play area
  final double yield; // delivery rate into the silo when active (per second)
  final double failBias; // relative weight to be hit by a disruption

  double stock = 1.0; // 0..1 — a depletion shock empties it; it regrows
  double downFor = 0.0; // seconds the route stays broken; >0 == down
  double flash = 0.0; // tap / break feedback, 1 → 0
  double flowPhase = 0.0; // animates the goods dots travelling the route

  _Source(this.name, this.pos, this.yield, this.failBias);

  bool get routeUp => downFor <= 0;
  bool get usable => routeUp && stock > 0.04;
}

class _RerouteGameState extends State<RerouteGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Tunables ───────────────────────────────────────────────────────────────
  static const double _consumption = 0.16; // silo drain/s (factory eats supply)
  static const double _baseProd = 4.0; // units/s at a FULL silo
  static const double _activeDrain = 0.06; // active source's stock drain/s
  static const double _regen = 0.05; // any source's stock regrowth/s

  // Factory position + source layout (normalised).
  static const Offset _factory = Offset(0.80, 0.50);

  // ── Sim state ────────────────────────────────────────────────────────────────
  late List<_Source> _sources;
  int _active = 0; // index of the source currently feeding the factory
  double _buffer = 0.70; // 0..1 — the factory's input silo
  double _prodAcc = 0.0; // fractional produced units, pops into addScore(1)
  int _streak = 0; // consecutive units produced without a starve
  bool _starved = false; // latched while the silo is empty

  double _clock = 0; // seconds elapsed while playing
  double _lastT = 0;
  bool _started = false; // rising-edge guard so the sim resets on play start

  double _nextDisrupt = 4.0; // _clock at which the next shock fires
  double _factoryFlash = 0; // produced-bloom on the factory, 1 → 0
  double _starveFlash = 0; // pulsing alarm while starving, 0..1

  // Transient on-board banner ("Storm hits Backyard Farm!").
  String _banner = '';
  double _bannerLife = 0;
  Color _bannerColor = _danger;

  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _w = 1, _h = 1; // last layout size (px), for fx placement

  @override
  void initState() {
    super.initState();
    _sources = _buildSources();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    // ATTRACT autopilot: this game knows how to keep its own line fed. Registered
    // always (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One competent, deterministic reroute per host tick. It reads the sim's own
  /// state and calls the game's own reroute handler ([_onTap]) — no randomness,
  /// no synthetic taps. Policy: hold position while the active line is healthy
  /// and the silo is comfortably full; otherwise pick the best HEALTHY source
  /// reachable by an OPEN route (high delivery rate weighted by remaining stock
  /// so it won't run dry mid-feed) and reroute to it. Never reroutes onto a
  /// down/empty source, and won't churn off a fine line unless a candidate is
  /// genuinely stronger.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    final active = _sources[_active];
    final lineHealthy = active.usable;

    // Supply line is fine and the silo is comfortably full — hold position.
    if (lineHealthy && _buffer > 0.5) return;

    // Best healthy source: yield weighted by how much stock it still holds.
    int? best;
    var bestScore = 0.0;
    for (var i = 0; i < _sources.length; i++) {
      final s = _sources[i];
      if (!s.usable) continue; // never reroute to a down/empty source
      final score = s.yield * (0.3 + 0.7 * s.stock);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    if (best == null || best == _active) return;

    // If the current line still feeds, only switch to a genuinely stronger
    // source (avoid pointless churn between comparable backups).
    if (lineHealthy) {
      final activeScore = active.yield * (0.3 + 0.7 * active.stock);
      if (bestScore <= activeScore) return;
    }

    // Route the tap through the game's own reroute handler via the source's
    // normalised position (sources are >0.2 apart, so this selects exactly it).
    _onTap(_sources[best].pos);
  }

  List<_Source> _buildSources() {
    // x≈0.14 column; cheap/fast suppliers fail most, the slow overseas port
    // is the resilient backup. yields net positive vs _consumption.
    return [
      _Source('Backyard Farm', const Offset(0.14, 0.16), 0.42, 4.0),
      _Source('River Port', const Offset(0.14, 0.39), 0.34, 2.0),
      _Source('Highland Farm', const Offset(0.14, 0.62), 0.30, 1.6),
      _Source('Overseas Port', const Offset(0.14, 0.85), 0.24, 0.6),
    ];
  }

  void _resetSim() {
    _clock = 0;
    _buffer = 0.70;
    _prodAcc = 0;
    _streak = 0;
    _starved = false;
    _active = 0;
    _nextDisrupt = 4.0;
    _factoryFlash = 0;
    _starveFlash = 0;
    _banner = '';
    _bannerLife = 0;
    for (final s in _sources) {
      s.stock = 1.0;
      s.downFor = 0;
      s.flash = 0;
    }
  }

  // ── Loop ─────────────────────────────────────────────────────────────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX always animate (even during the calm ready state).
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_bannerLife > 0) _bannerLife -= dt;
    for (final s in _sources) {
      if (s.flash > 0) s.flash = (s.flash - dt * 1.8).clamp(0.0, 1.0);
      s.flowPhase += dt;
    }
    if (_factoryFlash > 0) _factoryFlash = (_factoryFlash - dt * 2.2).clamp(0.0, 1.0);

    final running = widget.session.isRunning;
    if (!running) {
      // Reset the rising-edge guard so a fresh run replays clean.
      if (widget.session.phase == MiniGamePhase.intro) _started = false;
      return;
    }
    if (!_started) {
      _resetSim();
      _started = true;
    }
    _simulate(dt);
  }

  void _simulate(double dt) {
    _clock += dt;

    // Source stock: regrow toward full; the active source slowly draws down.
    for (var i = 0; i < _sources.length; i++) {
      final s = _sources[i];
      if (s.downFor > 0) s.downFor = (s.downFor - dt).clamp(0.0, 30.0);
      var stock = s.stock + _regen * dt;
      if (i == _active && s.usable) stock -= (_activeDrain + _regen) * dt;
      s.stock = stock.clamp(0.0, 1.0);
    }

    // Supply: the active route refills the silo; the factory always consumes.
    _buffer -= _consumption * dt;
    final a = _sources[_active];
    if (a.usable) _buffer += a.yield * dt;
    _buffer = _buffer.clamp(0.0, 1.0);

    // Production scales with how full the silo is — keeping it topped (a strong
    // source) produces fast; limping along on a weak backup produces slowly;
    // an empty silo produces nothing (the factory has starved).
    if (_buffer > 0.001) {
      if (_starved) _starveFlash = 0; // recovered
      _starved = false;
      _prodAcc += _baseProd * _buffer * dt;
      while (_prodAcc >= 1.0) {
        _prodAcc -= 1.0;
        widget.session.addScore(1);
        _streak += 1;
        widget.session.noteStreak(_streak);
        _factoryFlash = 1.0;
      }
    } else {
      if (!_starved) {
        _starved = true;
        _streak = 0;
        _setBanner('FACTORY STARVING — reroute!', _danger);
      }
      _starveFlash = (0.5 + 0.5 * math.sin(_clock * 7.0)).abs();
    }

    // Disruptions.
    if (_clock >= _nextDisrupt) {
      _triggerDisruption();
      // Escalation: shocks get more frequent over the round.
      final base = _lerp(5.2, 2.2, (_clock / 50).clamp(0.0, 1.0));
      _nextDisrupt = _clock + base + _rng.nextDouble() * 1.4;
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _triggerDisruption() {
    // Keep at least one source usable so the player always has an out.
    final usable = [
      for (var i = 0; i < _sources.length; i++)
        if (_sources[i].usable) i
    ];
    if (usable.length <= 1) return;

    // After 35s, shocks can hit two routes at once.
    var count = (_clock > 35 && _rng.nextDouble() < 0.5) ? 2 : 1;
    count = math.min(count, usable.length - 1);

    final pool = [...usable];
    for (var k = 0; k < count; k++) {
      // Weighted pick — cheap/close routes (high failBias) fail most.
      final total = pool.fold<double>(0, (s, i) => s + _sources[i].failBias);
      var r = _rng.nextDouble() * total;
      var pick = pool.first;
      for (final i in pool) {
        r -= _sources[i].failBias;
        if (r <= 0) {
          pick = i;
          break;
        }
      }
      pool.remove(pick);
      final s = _sources[pick];
      s.flash = 1.0;
      final mid = Offset.lerp(_px(s.pos), _px(_factory), 0.5)!;
      _fx.addAll(FxBurst.spawn(mid, _danger, count: 12, speed: 130));
      if (_rng.nextDouble() < 0.7) {
        // Route closure (storm).
        s.downFor = _lerp(5.0, 3.0, (_clock / 50).clamp(0.0, 1.0));
        _setBanner('Storm closes ${s.name}!', _danger);
      } else {
        // Source depletion (drought).
        s.stock = 0.0;
        _setBanner('${s.name} runs dry!', _danger);
      }
    }
  }

  void _setBanner(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerLife = 1.8;
  }

  // ── Interaction ──────────────────────────────────────────────────────────────
  void _onTap(Offset norm) {
    if (!widget.session.isRunning) return;
    // Nearest source within reach.
    int? hit;
    var best = 0.14;
    for (var i = 0; i < _sources.length; i++) {
      final d = (_sources[i].pos - norm).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit == null) return;
    final s = _sources[hit];
    s.flash = 1.0;
    if (!s.usable) {
      final why = s.routeUp ? '${s.name} is empty' : '${s.name} route is down';
      _setBanner(why, _danger);
      _fx.addAll(FxBurst.spawn(_px(s.pos), _danger, count: 8, speed: 90));
      return;
    }
    if (hit == _active) return;
    _active = hit;
    _setBanner('Rerouted to ${s.name}', _good);
    _fx.addAll(FxBurst.spawn(_px(s.pos), _good, count: 12, speed: 120));
  }

  Offset _px(Offset norm) => Offset(norm.dx * _w, norm.dy * _h);

  // ── Build ────────────────────────────────────────────────────────────────────
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
          painter: _ReroutePainter(repaint: _ctrl, state: this),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

class _ReroutePainter extends CustomPainter {
  final _RerouteGameState s;
  _ReroutePainter({required Listenable repaint, required _RerouteGameState state})
      : s = state,
        super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset px(Offset n) => Offset(n.dx * w, n.dy * h);
    final clock = s._clock;
    final running = s.widget.session.isRunning;

    GameFx.atmosphere(canvas, size, _accent, clock, motes: 26);

    final factoryPx = px(_RerouteGameState._factory);

    // ── Routes (drawn under the nodes) ─────────────────────────────────────────
    for (var i = 0; i < s._sources.length; i++) {
      final src = s._sources[i];
      final a = px(src.pos);
      final isActive = i == s._active;
      if (!src.routeUp) {
        _drawBrokenRoute(canvas, a, factoryPx, clock);
      } else if (isActive && src.usable) {
        // The live supply line: a bright flowing beam + travelling goods.
        GameFx.glowLine(canvas, a, factoryPx, _accent, width: 3.5);
        _drawGoods(canvas, a, factoryPx, src.flowPhase);
      } else {
        // A standing, idle alternative — dim so backups read as "ready".
        canvas.drawLine(
          a,
          factoryPx,
          Paint()
            ..color = (src.usable ? _idleSrc : _danger).withValues(alpha: 0.22)
            ..strokeWidth = 2,
        );
      }
    }

    // ── Factory ────────────────────────────────────────────────────────────────
    _drawFactory(canvas, factoryPx, size);

    // ── Sources ────────────────────────────────────────────────────────────────
    for (var i = 0; i < s._sources.length; i++) {
      _drawSource(canvas, px(s._sources[i].pos), s._sources[i], i == s._active);
    }

    // ── Goal / ready hint ──────────────────────────────────────────────────────
    if (!running) {
      GameFx.text(
        canvas,
        'Keep the factory fed — tap a healthy source to reroute',
        Offset(w / 2, h - 24),
        13,
        Colors.white.withValues(alpha: 0.62),
      );
    }

    // ── Banner ─────────────────────────────────────────────────────────────────
    if (s._bannerLife > 0) {
      final a = (s._bannerLife / 1.8).clamp(0.0, 1.0);
      GameFx.text(
        canvas,
        s._banner,
        Offset(w / 2, h * 0.10),
        16,
        s._bannerColor.withValues(alpha: a),
        weight: FontWeight.w800,
        glow: 0.6 * a,
      );
    }

    // ── Juice on top ───────────────────────────────────────────────────────────
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  void _drawBrokenRoute(Canvas canvas, Offset a, Offset b, double clock) {
    // Dashed red line with a gap in the middle (the closure).
    final paint = Paint()
      ..color = _danger.withValues(alpha: 0.65)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dash = 10.0, gap = 8.0;
    final dir = b - a;
    final len = dir.distance;
    if (len <= 0) return;
    final unit = dir / len;
    var d = 0.0;
    while (d < len) {
      // Leave a clear break around the centre to read as "severed".
      final mid = (d / len - 0.5).abs();
      if (mid > 0.10) {
        final p1 = a + unit * d;
        final p2 = a + unit * math.min(d + dash, len);
        canvas.drawLine(p1, p2, paint);
      }
      d += dash + gap;
    }
    // A storm spark at the break.
    final breakPt = Offset.lerp(a, b, 0.5)!;
    final pulse = 0.5 + 0.5 * math.sin(clock * 6);
    canvas.drawCircle(
      breakPt,
      6 + pulse * 3,
      Paint()
        ..color = _danger.withValues(alpha: 0.4 + 0.3 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    GameFx.text(canvas, '✕', breakPt, 16, _danger);
  }

  void _drawGoods(Canvas canvas, Offset a, Offset b, double phase) {
    const n = 4;
    for (var i = 0; i < n; i++) {
      final t = ((phase * 0.5 + i / n) % 1.0);
      final p = Offset.lerp(a, b, t)!;
      canvas.drawCircle(
        p,
        4,
        Paint()..color = _good.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = _good.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  void _drawFactory(Canvas canvas, Offset c, Size size) {
    final flash = s._factoryFlash;
    final starve = s._starveFlash;
    final body = Color.lerp(Potatuhs.orange, _danger, starve * 0.6)!;
    final r = 30.0 + flash * 4;
    GameFx.orb(canvas, c, r, body, glow: 0.9 + flash * 0.6);
    GameFx.text(canvas, 'FACTORY', c.translate(0, r + 14), 11,
        Colors.white.withValues(alpha: 0.75), weight: FontWeight.w800);

    // Input silo gauge — a vertical bar to the left of the factory.
    final barH = 64.0, barW = 12.0;
    final left = c.dx - r - 26;
    final top = c.dy - barH / 2;
    final track = Rect.fromLTWH(left, top, barW, barH);
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.4));
    final fillH = barH * s._buffer.clamp(0.0, 1.0);
    final fillColor = s._buffer < 0.18
        ? _danger
        : (s._buffer < 0.45 ? Potatuhs.sienna : _good);
    final fillRect =
        Rect.fromLTWH(left, top + (barH - fillH), barW, fillH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(6)),
      Paint()..color = fillColor,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    GameFx.text(canvas, 'SILO', Offset(left + barW / 2, top - 10), 8,
        Colors.white.withValues(alpha: 0.5));

    if (s._starved && running) {
      GameFx.text(canvas, 'STARVING', c.translate(0, -r - 16), 13,
          _danger.withValues(alpha: 0.6 + 0.4 * starve),
          weight: FontWeight.w800, glow: 0.6 * starve);
    }
  }

  bool get running => s.widget.session.isRunning;

  void _drawSource(Canvas canvas, Offset c, _Source src, bool isActive) {
    final usable = src.usable;
    final base = !src.routeUp
        ? _danger
        : (src.stock <= 0.04
            ? _danger
            : (isActive ? _accent : _idleSrc));
    final r = 18.0 + src.flash * 4;
    GameFx.orb(canvas, c, r, base, glow: isActive ? 1.0 : 0.5);

    // Active ring.
    if (isActive && usable) {
      canvas.drawCircle(
        c,
        r + 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _good.withValues(alpha: 0.9),
      );
    }

    // Stock arc around the node (how much product it has).
    final sweep = (src.stock.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 4),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = (src.stock < 0.2 ? _danger : _good).withValues(alpha: 0.85),
    );

    // Name + state label.
    GameFx.text(canvas, src.name, c.translate(0, r + 14), 9.5,
        Colors.white.withValues(alpha: 0.78), weight: FontWeight.w700);
    final state = !src.routeUp
        ? 'DOWN'
        : (src.stock <= 0.04 ? 'EMPTY' : (isActive ? 'FEEDING' : 'READY'));
    final stateColor = !usable
        ? _danger
        : (isActive ? _good : Colors.white.withValues(alpha: 0.45));
    GameFx.text(canvas, state, c.translate(0, r + 26), 8, stateColor,
        weight: FontWeight.w800);
  }

  @override
  bool shouldRepaint(covariant _ReroutePainter old) => true;
}
