import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Heartbeat — route blood through the heart IN ORDER, on the beat.
//
// Scale: BioScale.organ. The player taps the chambers/valves in the correct
// circulation sequence — body → right atrium → right ventricle → lungs
// (oxygenate) → left atrium → left ventricle → body — and must tap the NEXT
// stage on the downbeat to pump. Deoxygenated (blue) vs oxygenated (red) blood
// is shown so the loop is visible. Mistimed or out-of-order taps stall the
// flow and break the streak. Streak builds the heart rate (BPM), which tightens
// the timing window — the game accelerates as you play well.
//
// One Ticker drives one CustomPainter. The host owns the clock, countdown,
// score and results; this widget renders ONLY the play area.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (tune freely) ────────────────────────────────────────────
const double _kBaseBpm = 64; // resting rate when the streak is cold
const double _kMaxBpm = 176; // ceiling — streak can't push faster than this
const double _kBpmPerStreak = 5; // each clean pump in a streak adds this much
const double _kIdleBpm = 50; // gentle resting thump in the calm ready state

// Timing window (in beat-phase units, where a full beat is 0..1 and the
// downbeat is phase 0). Shrinks as BPM climbs — the accelerate lever.
const double _kWindowWide = 0.22; // forgiving window at resting rate
const double _kWindowTight = 0.09; // tightest window at max rate
const double _kPerfectFrac = 0.4; // inside this fraction of the window = PERFECT

// Scoring.
const int _kPumpBase = 12; // points for a clean pump
const int _kPerfectBonus = 8; // extra for a dead-on-the-beat pump
const int _kStreakCap = 12; // streak bonus is min(streak, cap)
const int _kCycleBonus = 40; // returning blood to the body completes a cycle

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFFE5484D); // cardinal red — the heart
const Color _kBlue = Color(0xFF42A5F5); // deoxygenated blood
const Color _kBlueDeep = Color(0xFF1565C0);
const Color _kRed = Color(0xFFEF5350); // oxygenated blood
const Color _kRedDeep = Color(0xFFB71C1C);
const Color _kGreen = Color(0xFF69F0AE);
const Color _kWhite = Colors.white;

/// One stage in the circulation loop.
class _Stage {
  final String label; // short tag drawn on the node
  final String full; // full name surfaced for the active stage
  final bool oxy; // true = oxygenated (red), false = deoxygenated (blue)
  const _Stage(this.label, this.full, this.oxy);

  Color get color => oxy ? _kRed : _kBlue;
  Color get deep => oxy ? _kRedDeep : _kBlueDeep;
}

/// The fixed loop. Index order IS the pump order. Blood turns red at the
/// lungs (oxygenate) and back to blue at the body (O₂ delivered).
const List<_Stage> _kLoop = <_Stage>[
  _Stage('BODY', 'Body · O₂ delivered', false),
  _Stage('RA', 'Right Atrium', false),
  _Stage('RV', 'Right Ventricle', false),
  _Stage('LUNGS', 'Lungs · oxygenate', true),
  _Stage('LA', 'Left Atrium', true),
  _Stage('LV', 'Left Ventricle', true),
];

class HeartbeatGame extends StatefulWidget {
  final MiniGameSession session;
  const HeartbeatGame({super.key, required this.session});

  @override
  State<HeartbeatGame> createState() => _HeartbeatGameState();
}

class _HeartbeatGameState extends State<HeartbeatGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  // ── Core state ─────────────────────────────────────────────────────────────
  int _pos = 0; // index of the stage currently holding the blood
  int _streak = 0; // consecutive clean pumps
  int _cycles = 0; // full loops completed
  double _bpm = _kBaseBpm;
  double _window = _kWindowWide;

  // Beat metronome. _beatPhase wraps 0→1 every beat; downbeat is phase 0.
  double _beatPhase = 0.0;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _beatFlash = 0.0; // bloom on a clean pump, 1 → 0
  double _missFlash = 0.0; // red wash on a stall, 1 → 0
  double _perfectFlash = 0.0; // gold ring on a PERFECT pump
  String? _banner; // transient callout (CYCLE, PERFECT, MISS…)
  double _bannerAge = 0.0;
  Color _bannerColor = _kGreen;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  int get _active => (_pos + 1) % _kLoop.length;

  @override
  void initState() {
    super.initState();
    _recalc();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _recalc() {
    _bpm = (_kBaseBpm + _streak * _kBpmPerStreak).clamp(_kBaseBpm, _kMaxBpm);
    final t = ((_bpm - _kBaseBpm) / (_kMaxBpm - _kBaseBpm)).clamp(0.0, 1.0);
    _window = _kWindowWide + (_kWindowTight - _kWindowWide) * t;
  }

  void _resetRun() {
    _pos = 0;
    _streak = 0;
    _cycles = 0;
    _beatPhase = 0.0;
    _beatFlash = 0;
    _missFlash = 0;
    _perfectFlash = 0;
    _banner = null;
    _bannerAge = 0;
    _fx.clear();
    _pops.clear();
    _recalc();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    // Fresh run detected: reset internal state so a session can re-enter clean.
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // Advance the metronome. Idle (calm) thump when not running.
    final bpm = running ? _bpm : _kIdleBpm;
    final period = 60.0 / bpm;
    _beatPhase = (_beatPhase + dt / period) % 1.0;

    // Decay juice.
    _beatFlash = math.max(0.0, _beatFlash - dt * 2.6);
    _missFlash = math.max(0.0, _missFlash - dt * 3.0);
    _perfectFlash = math.max(0.0, _perfectFlash - dt * 2.2);
    if (_banner != null) {
      _bannerAge += dt;
      if (_bannerAge > 1.2) _banner = null;
    }
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  // ── Input ────────────────────────────────────────────────────────────────
  void _handleTap(Offset local, Size size) {
    if (!widget.session.isRunning) return;
    final geo = _HeartGeo.of(size);

    // Nearest node within a generous, thumb-friendly hit radius.
    int hit = -1;
    double best = geo.nodeR * 1.7;
    for (var i = 0; i < geo.nodes.length; i++) {
      final d = (geo.nodes[i] - local).distance;
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit < 0) return;

    // Must tap the NEXT stage in the loop.
    if (hit != _active) {
      _stall('WRONG WAY', geo.nodes[hit]);
      return;
    }

    // Right stage — now check the beat. timingError 0 = dead on the downbeat.
    final te = math.min(_beatPhase, 1 - _beatPhase);
    if (te > _window) {
      _stall(_beatPhase < 0.5 ? 'TOO LATE' : 'TOO SOON', geo.nodes[hit]);
      return;
    }

    _pump(te, geo);
  }

  void _pump(double te, _HeartGeo geo) {
    final perfect = te <= _window * _kPerfectFrac;
    _pos = _active;
    _streak++;
    _recalc();

    var pts = _kPumpBase + _streak.clamp(0, _kStreakCap);
    if (perfect) {
      pts += _kPerfectBonus;
      _perfectFlash = 1.0;
    }

    final stage = _kLoop[_pos];
    final pos = geo.nodes[_pos];
    widget.session.addScore(pts);
    widget.session.noteStreak(_streak);
    _beatFlash = 1.0;
    _fx.addAll(FxBurst.spawn(pos, stage.color,
        count: perfect ? 18 : 12, speed: perfect ? 150 : 110));
    _pops.add(FxPop(pos, '+$pts', perfect ? Potatuhs.gold : _kWhite));

    // Returning blood to the body closes a full circulation cycle.
    if (_pos == 0) {
      _cycles++;
      widget.session.addScore(_kCycleBonus);
      _flash('CYCLE +$_kCycleBonus', Potatuhs.gold);
    } else if (perfect) {
      _flash('PERFECT', Potatuhs.gold);
    } else if (_pos == 3) {
      _flash('OXYGENATED', _kRed);
    }
  }

  void _stall(String why, Offset at) {
    _streak = 0;
    _recalc();
    _missFlash = 0.7;
    _pops.add(FxPop(at, why, _kRedDeep));
  }

  void _flash(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerAge = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _handleTap(d.localPosition, size),
        child: ClipRect(
          child: CustomPaint(
            painter: _HeartPainter(
              loopPos: _pos,
              active: _active,
              beatPhase: _beatPhase,
              window: _window,
              bpm: _bpm,
              streak: _streak,
              cycles: _cycles,
              running: widget.session.isRunning,
              beatFlash: _beatFlash,
              missFlash: _missFlash,
              perfectFlash: _perfectFlash,
              banner: _banner,
              bannerAge: _bannerAge,
              bannerColor: _bannerColor,
              fx: _fx,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Geometry — the six stages laid out on an ellipse so the loop reads as a ring.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartGeo {
  final Offset center;
  final double nodeR;
  final List<Offset> nodes;
  const _HeartGeo(this.center, this.nodeR, this.nodes);

  factory _HeartGeo.of(Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final rx = size.width * 0.33;
    final ry = size.height * 0.33;
    final nodeR = (size.shortestSide * 0.085).clamp(22.0, 42.0);
    final nodes = <Offset>[
      for (var i = 0; i < _kLoop.length; i++)
        center +
            Offset(
              math.cos(math.pi / 2 + i * math.pi / 3) * rx,
              math.sin(math.pi / 2 + i * math.pi / 3) * ry,
            ),
    ];
    return _HeartGeo(center, nodeR, nodes);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — one pass, whole play area.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartPainter extends CustomPainter {
  final int loopPos;
  final int active;
  final double beatPhase;
  final double window;
  final double bpm;
  final int streak;
  final int cycles;
  final bool running;
  final double beatFlash;
  final double missFlash;
  final double perfectFlash;
  final String? banner;
  final double bannerAge;
  final Color bannerColor;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _HeartPainter({
    required this.loopPos,
    required this.active,
    required this.beatPhase,
    required this.window,
    required this.bpm,
    required this.streak,
    required this.cycles,
    required this.running,
    required this.beatFlash,
    required this.missFlash,
    required this.perfectFlash,
    required this.banner,
    required this.bannerAge,
    required this.bannerColor,
    required this.fx,
    required this.pops,
  });

  double get _beatPulse {
    final te = math.min(beatPhase, 1 - beatPhase);
    return math.pow(math.max(0.0, 1 - te / 0.16), 2).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, beatPhase + cycles.toDouble());
    final geo = _HeartGeo.of(size);

    _paintSegments(canvas, geo);
    _paintCenterHeart(canvas, geo);
    for (var i = 0; i < geo.nodes.length; i++) {
      _paintNode(canvas, geo, i);
    }
    _paintApproachRing(canvas, geo);
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintActiveLabel(canvas, size, geo);
    _paintBanner(canvas, size);
    _paintFlashes(canvas, size);
    if (!running) _paintReadyHint(canvas, size);
  }

  // ── Loop segments + flow arrows ────────────────────────────────────────────
  void _paintSegments(Canvas canvas, _HeartGeo geo) {
    final n = geo.nodes.length;
    for (var i = 0; i < n; i++) {
      final a = geo.nodes[i];
      final b = geo.nodes[(i + 1) % n];
      final color = _kLoop[i].color; // blood color leaving stage i
      final isActiveSeg = i == loopPos; // the segment about to be pumped along
      // Pipe.
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color.withValues(alpha: isActiveSeg ? 0.55 : 0.22)
          ..strokeWidth = isActiveSeg ? 7 : 4
          ..strokeCap = StrokeCap.round,
      );
      // Direction chevron at the midpoint.
      _paintArrow(canvas, a, b, color.withValues(alpha: isActiveSeg ? 0.9 : 0.4));
    }
  }

  void _paintArrow(Canvas canvas, Offset a, Offset b, Color color) {
    final mid = Offset.lerp(a, b, 0.5)!;
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    const s = 7.0;
    final tip = mid + u * s;
    final p1 = mid - u * s + perp * s;
    final p2 = mid - u * s - perp * s;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── Central heart that thumps on every beat ───────────────────────────────
  void _paintCenterHeart(Canvas canvas, _HeartGeo geo) {
    final s = geo.nodeR * (0.9 + 0.16 * _beatPulse);
    final path = _heartPath(geo.center, s);
    // Glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.30 + 0.35 * _beatPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kRed, _kAccent, _kRedDeep],
        ).createShader(Rect.fromCircle(center: geo.center, radius: s)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kWhite.withValues(alpha: 0.5),
    );
    // BPM readout under the heart.
    GameFx.text(
      canvas,
      '${bpm.round()} BPM',
      geo.center.translate(0, geo.nodeR * 1.5),
      12,
      _kWhite.withValues(alpha: 0.85),
      weight: FontWeight.w800,
    );
    if (streak >= 2) {
      GameFx.text(
        canvas,
        '🔥 $streak',
        geo.center.translate(0, geo.nodeR * 1.5 + 16),
        12,
        Potatuhs.gold,
        weight: FontWeight.w700,
      );
    }
  }

  Path _heartPath(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.36)
      ..cubicTo(c.dx + s * 1.05, c.dy - s * 0.45, c.dx + s * 0.5, c.dy - s,
          c.dx, c.dy - s * 0.42)
      ..cubicTo(c.dx - s * 0.5, c.dy - s, c.dx - s * 1.05, c.dy - s * 0.45,
          c.dx, c.dy + s * 0.36)
      ..close();
  }

  // ── A circulation stage node ──────────────────────────────────────────────
  void _paintNode(Canvas canvas, _HeartGeo geo, int i) {
    final stage = _kLoop[i];
    final pos = geo.nodes[i];
    final isHere = i == loopPos; // blood currently here
    final isActive = i == active; // next to be tapped
    final dim = !isHere && !isActive;

    final pulse = isHere ? (1.0 + 0.12 * _beatPulse) : 1.0;
    GameFx.orb(
      canvas,
      pos,
      geo.nodeR * pulse,
      dim ? stage.deep : stage.color,
      glow: isHere ? (0.7 + 0.6 * _beatPulse) : (isActive ? 0.7 : 0.25),
      rim: isActive ? _kWhite : null,
    );

    // The blood token sits on the current stage as a bright pulsing core.
    if (isHere) {
      canvas.drawCircle(
        pos,
        geo.nodeR * 0.42 * pulse,
        Paint()
          ..color = _kWhite.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    GameFx.text(
      canvas,
      stage.label,
      pos,
      geo.nodeR * 0.42,
      _kWhite.withValues(alpha: dim ? 0.65 : 0.95),
      weight: FontWeight.w800,
    );
  }

  // ── Rhythm approach ring on the active node ───────────────────────────────
  void _paintApproachRing(Canvas canvas, _HeartGeo geo) {
    if (!running) return;
    final pos = geo.nodes[active];
    // Triangle wave: 0 at the downbeat, 1 between beats.
    final tri = beatPhase < 0.5 ? beatPhase * 2 : (1 - beatPhase) * 2;
    final r = geo.nodeR * (1.0 + 1.8 * tri);
    final te = math.min(beatPhase, 1 - beatPhase);
    final inWindow = te <= window;

    // Static target ring — tap when the approach ring shrinks onto it.
    canvas.drawCircle(
      pos,
      geo.nodeR * 1.18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (inWindow ? _kGreen : _kWhite).withValues(alpha: 0.45),
    );
    // Shrinking approach ring.
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inWindow ? 4 : 2.4
        ..color = (inWindow ? _kGreen : _kLoop[active].color)
            .withValues(alpha: inWindow ? 0.95 : 0.6),
    );
  }

  // ── Active-stage name (the educational label) ─────────────────────────────
  void _paintActiveLabel(Canvas canvas, Size size, _HeartGeo geo) {
    if (!running) return;
    final stage = _kLoop[active];
    final tint = stage.oxy ? _kRed : _kBlue;
    GameFx.text(
      canvas,
      'NEXT  →  ${stage.full}',
      Offset(size.width / 2, size.height - 30),
      14,
      tint,
      weight: FontWeight.w800,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      stage.oxy ? 'oxygenated · red' : 'deoxygenated · blue',
      Offset(size.width / 2, size.height - 12),
      10,
      _kWhite.withValues(alpha: 0.55),
    );
  }

  void _paintBanner(Canvas canvas, Size size) {
    if (banner == null) return;
    final t = (bannerAge / 1.2).clamp(0.0, 1.0);
    final alpha = (1 - t * t);
    GameFx.text(
      canvas,
      banner!,
      Offset(size.width / 2, size.height * 0.18 - 24 * t),
      26,
      bannerColor.withValues(alpha: alpha),
      display: true,
      glow: 0.8 * alpha,
    );
  }

  void _paintFlashes(Canvas canvas, Size size) {
    if (missFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kRedDeep.withValues(alpha: 0.28 * missFlash),
      );
    }
    if (perfectFlash > 0.3) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.14 * perfectFlash),
      );
    }
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'HEARTBEAT',
      Offset(size.width / 2, size.height * 0.12),
      30,
      _kAccent,
      display: true,
      glow: 0.6,
    );
    GameFx.text(
      canvas,
      'Route blood through the heart — in order, on the beat.',
      Offset(size.width / 2, size.height * 0.12 + 30),
      13,
      _kWhite.withValues(alpha: 0.8),
    );
    GameFx.text(
      canvas,
      'Tap the glowing chamber when the ring snaps shut.',
      Offset(size.width / 2, size.height * 0.12 + 50),
      12,
      _kWhite.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => true;
}
