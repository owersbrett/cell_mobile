import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ── Feel constants ───────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely.

const int _kN = 36; // atoms in the (uncountable) glow cloud

/// Halvings to hit per sample: 50% → 25% → 12.5% → 6.25%. Each beat is the
/// *same* time (one half-life) apart — that constant interval is the lesson AND
/// the skill. Mark the sample EVERY time it halves.
const int _kBeats = 4;

/// Base points for a beat, scaled by timing accuracy.
const int _kBeatPts = 60;

/// Bonus for nailing a beat dead-on (error under [_kPerfectErr] half-lives).
const int _kPerfectBonus = 30;

/// Error (in half-lives) at which a beat scores zero.
const double _kTol = 0.7;

/// "Good enough" error — keeps/extends the streak.
const double _kGoodErr = 0.20;

/// "Excellent" error — earns the perfect bonus.
const double _kPerfectErr = 0.08;

/// Brief flourish between samples (lets the last beat read), then the next —
/// faster — sample spawns. No long reveal pause: pace stays high.
const double _kInterSample = 0.45;

/// How long a per-tap hit flash lingers.
const double _kFlashTime = 0.7;

/// HOLD-TO-ACCELERATE: while the ⏩ button is held, sample time advances this
/// many times faster. Faster decay ⇒ the next halving arrives sooner (tempo
/// reward), but the glow races through each target fraction, so precise taps
/// are HARDER (the gamble). ~2.6× is a spicy-but-playable default.
const double _kAccelMul = 2.6;

/// Reward for the gamble: a beat tapped WHILE accelerating scores this multiple
/// of its normal points. Modest — clearly tunable.
const double _kAccelBonusMul = 1.5;

// ── Layout geometry (single source of truth) ─────────────────────────────────
// The screen is split into non-overlapping vertical bands. Every element anchors
// to one of these fractions so nothing stacks on top of anything else. The cloud
// + its metronome ring live in the CLOUD band; text lives above/below it.
const double _kCloudCY = 0.325; // cloud centre (fraction of height)
const double _kCloudWF = 0.30; // cloud radius = min(w*this, h*_kCloudHF)
const double _kCloudHF = 0.125;
const double _kMetroMax = 1.30; // metronome ring peaks at this × cloud radius
// Cloud band (incl. peak metronome ring) occupies ~0.16 … ~0.49 of height, so
// header text stays ABOVE 0.155 and the step-tracker/curve stay BELOW 0.50.

/// Cloud centre + radius for a given canvas [size]. Every cloud-relative element
/// (cloud, metronome, speed-lines, decay bursts) reads geometry from here so
/// they never disagree or drift into other bands.
({Offset center, double r}) _cloudGeom(Size size) {
  final center = Offset(size.width / 2, size.height * _kCloudCY);
  final r = math.min(size.width * _kCloudWF, size.height * _kCloudHF);
  return (center: center, r: r);
}

// Radioactive isotope palette.
const Color _kAccent = Color(0xFF7DFB5A);
const Color _kGood = Color(0xFF69F0AE);
const Color _kWarn = Color(0xFFFF6E40);
const Color _kWhite = Colors.white;

/// Format a percentage exactly: 50→"50", 25→"25", 12.5→"12.5", 6.25→"6.25".
/// Shows up to 2 decimals and trims trailing zeros (so no "6.2"/"6.3" rounding
/// of the 6.25% target). Used for every target/read percent the player sees.
String _fmtPct(double pct) {
  var s = pct.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// "Half-Life v2" — a UX-passed rebuild of Half-Life.
///
/// A radioactive sample decays in front of you as a **deliberately fuzzy glow
/// cloud** — there is no atom counter to read, so you must *estimate the
/// fraction from feel*. Each sample asks for three measurements in a row at
/// 50%, 25%, 12.5%. The catch (and the lesson): each halving takes the **same**
/// amount of time, so once you nail the first beat you can ride the rhythm for
/// the next two. Closer taps = more points; samples get faster, building to a
/// fast triple-tap climax. Teaches exponential decay and the constant-time
/// half-life: 100 → 50 → 25 → 12.5 %.
class HalfLifeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HalfLifeV2Game({super.key, required this.session});

  @override
  State<HalfLifeV2Game> createState() => _HalfLifeV2GameState();
}

class _HalfLifeV2GameState extends State<HalfLifeV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // Even, uncountable fill positions for the cloud (golden-angle disc).
  late final List<Offset> _unit = _spiral(_kN);

  // ── Run state ──
  bool _started = false;
  int _sample = 0;
  double _hl = 2.3; // seconds per halving for the current sample

  double _t = 0.0; // seconds elapsed in the current sample
  double _frac = 1.0; // theoretical fraction still radioactive (2^-(t/hl))
  final List<double> _th = List.filled(_kN, 0.0); // per-atom decay thresholds
  final List<bool> _alive = List.filled(_kN, true);

  int _nextBeat = 0; // which halving we're hunting (0..._kBeats-1)
  final List<double?> _capN = List.filled(_kBeats, null); // captured half-lives
  final List<int> _capQ = List.filled(_kBeats, 0); // captured quality 0/1/2
  double _interTimer = 0.0; // >0 → in the between-sample flourish

  // HOLD-TO-ACCELERATE: true while the ⏩ button is held (see _kAccelMul).
  bool _accelerating = false;

  // Per-tap hit flash.
  int _flashQ = 0;
  int _flashPts = 0;
  double _flashAge = _kFlashTime + 1;

  int _streak = 0;
  double _idle = 0.0;
  Size _size = Size.zero;
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  double get _capElapsed => (_kBeats + 0.9) * _hl;
  double get _curN => _t / _hl;

  static List<Offset> _spiral(int n) {
    final golden = math.pi * (3 - math.sqrt(5));
    return [
      for (var i = 0; i < n; i++)
        Offset(
          math.sqrt((i + 0.5) / n) * math.cos(i * golden),
          math.sqrt((i + 0.5) / n) * math.sin(i * golden),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _startSample();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: play the game hands-free. Registered always; it's a
    // no-op during hands-on play (the host only calls it in attract mode). This
    // is a timing game, so we leave the default per-tick (~250ms) cadence — no
    // quiz interval. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  /// ATTRACT autopilot — mark the glow at EVERY successive halving. The host
  /// drives this on a ~250ms cadence; the decay advances `curN = t/hl` at the
  /// normal (un-forced) rate, so one window is ~`0.25/hl` half-lives. We look
  /// one window ahead and MARK ([_tap]) at the CLOSEST approach to the current
  /// halving target (`curN == nextBeat + 1`): the instant the next step would
  /// carry us no nearer, provided we're inside the scoring window. Deterministic;
  /// one mark per call; [_tap] itself advances [_nextBeat] through the sequence.
  void _autoStep() {
    if (!widget.session.isRunning || !_started) return;
    if (_interTimer > 0 || _nextBeat >= _kBeats) return;

    final target = (_nextBeat + 1).toDouble(); // halving lands at integer curN
    final step = 0.25 / _hl; // curN advance across one ~250ms autopilot window
    final now = _curN;
    final errNow = (now - target).abs();
    final errNext = (now + step - target).abs();

    // A closer sample is still ahead → wait for it. Otherwise we're at (or just
    // past) the nearest approach: mark now, as long as we'd actually score
    // (inside the zero-point tolerance).
    if (errNow <= errNext && errNow < _kTol) {
      _tap();
    }
  }

  void _startSample() {
    _hl = math.max(1.0, 2.3 - 0.16 * _sample);
    _t = 0.0;
    _frac = 1.0;
    _nextBeat = 0;
    _interTimer = 0.0;
    for (var i = 0; i < _kN; i++) {
      _th[i] = _rng.nextDouble();
      _alive[i] = true;
    }
    for (var b = 0; b < _kBeats; b++) {
      _capN[b] = null;
      _capQ[b] = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _idle += dt;
    _flashAge += dt;

    final running = widget.session.isRunning;

    if (running && !_started) {
      _started = true;
      _sample = 0;
      _streak = 0;
      _startSample();
    }

    if (running && _started) {
      if (_interTimer > 0) {
        _interTimer -= dt;
        if (_interTimer <= 0) {
          _sample++;
          _startSample();
        }
      } else {
        // While held, the ⏩ button races the decay clock (risk/reward).
        _t += dt * (_accelerating ? _kAccelMul : 1.0);
        _frac = math.pow(0.5, _t / _hl).toDouble();
        _decayAtoms();
        if (_nextBeat >= _kBeats) {
          _interTimer = _kInterSample;
        } else if (_t >= _capElapsed) {
          // Player let the sample run out → auto-miss remaining beats.
          while (_nextBeat < _kBeats) {
            _capN[_nextBeat] = _curN;
            _capQ[_nextBeat] = 0;
            _nextBeat++;
          }
          _interTimer = _kInterSample;
        }
      }
    }

    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _decayAtoms() {
    if (_size == Size.zero) return;
    for (var i = 0; i < _kN; i++) {
      final shouldLive = _frac > _th[i];
      if (_alive[i] && !shouldLive) {
        _alive[i] = false;
        _sparks.addAll(
            FxBurst.spawn(_cloudCenter(_size, i), _kAccent, count: 5, speed: 60, size: 2));
      }
    }
  }

  void _tap() {
    if (!widget.session.isRunning || !_started) return;
    if (_interTimer > 0 || _nextBeat >= _kBeats) return;

    final b = _nextBeat;
    final err = (_curN - (b + 1)).abs();
    final base = (_kBeatPts * (1 - err / _kTol)).round().clamp(0, _kBeatPts);
    final perfect = err < _kPerfectErr;
    var pts = perfect ? base + _kPerfectBonus : base;
    // Reward the gamble: a beat marked mid-acceleration pays a bonus multiple.
    if (_accelerating) pts = (pts * _kAccelBonusMul).round();
    final q = perfect ? 2 : (err < _kGoodErr ? 1 : 0);

    _capN[b] = _curN;
    _capQ[b] = q;
    _flashQ = q;
    _flashPts = pts;
    _flashAge = 0;

    if (pts > 0) {
      widget.session.addScore(pts);
      final c = _size == Size.zero ? Offset.zero : _cloudGeom(_size).center;
      _pops.add(FxPop(c, '+$pts', perfect ? _kAccent : _kGood));
      _sparks.addAll(FxBurst.spawn(c, perfect ? _kAccent : _kGood,
          count: perfect ? 14 : 8, speed: 110, size: 3));
    }

    if (err < _kGoodErr) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    _nextBeat++;
  }

  static Offset _cloudCenter(Size size, int i) {
    final g = _cloudGeom(size);
    final u = _spiral(_kN)[i];
    return g.center + u * g.r;
  }

  // Only allow accelerating during live measuring (not pre-start / between
  // samples / after the last beat).
  bool get _canAccel =>
      _started &&
      widget.session.isRunning &&
      _interTimer <= 0 &&
      _nextBeat < _kBeats;

  void _setAccel(bool on) {
    if (_accelerating == on) return;
    if (on && !_canAccel) return;
    setState(() => _accelerating = on);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      final canAccel = _canAccel;
      return Stack(
        children: [
          // Full-area MEASURE surface (under the button).
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _tap(),
              child: CustomPaint(
                size: _size,
                painter: _HalfLifeV2Painter(
                  unit: _unit,
                  hl: _hl,
                  sample: _sample,
                  frac: _frac,
                  alive: _alive,
                  nextBeat: _nextBeat,
                  curN: _curN,
                  capN: _capN,
                  capQ: _capQ,
                  inter: _interTimer > 0,
                  flashQ: _flashQ,
                  flashPts: _flashPts,
                  flashAge: _flashAge,
                  streak: _streak,
                  idle: _idle,
                  started: _started,
                  running: widget.session.isRunning,
                  accelerating: _accelerating,
                  sparks: _sparks,
                  pops: _pops,
                ),
              ),
            ),
          ),
          // ⏩ FORCE DECAY button — its own hit region (opaque Listener) so a
          // hold here NEVER fires a measurement, and taps elsewhere still do.
          // Anchored in the bottom-right strip, BELOW the decay curve. The
          // centred bottom readout is shifted left (see _paintTapHint) so the
          // two controls never collide on narrow (phone / small-embed) widths.
          Positioned(
            right: 14,
            bottom: 16,
            child: _AccelButton(
              enabled: canAccel,
              active: _accelerating,
              onDown: () => _setAccel(true),
              onUp: () => _setAccel(false),
            ),
          ),
        ],
      );
    });
  }
}

/// The risky HOLD-TO-ACCELERATE control. An opaque [Listener] swallows its own
/// pointers so holding it does not reach the measure surface underneath.
class _AccelButton extends StatelessWidget {
  final bool enabled;
  final bool active;
  final VoidCallback onDown;
  final VoidCallback onUp;
  const _AccelButton({
    required this.enabled,
    required this.active,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    final base = enabled ? _kWarn : Potatuhs.textFaint;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: enabled ? (_) => onDown() : null,
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? _kWarn.withValues(alpha: 0.92)
                : base.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: base.withValues(alpha: 0.9), width: 2),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: _kWarn.withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          child: Text(
            '⏩ FORCE DECAY',
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: active ? Colors.black : base,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HalfLifeV2Painter extends CustomPainter {
  final List<Offset> unit;
  final double hl;
  final int sample;
  final double frac;
  final List<bool> alive;
  final int nextBeat;
  final double curN;
  final List<double?> capN;
  final List<int> capQ;
  final bool inter;
  final int flashQ;
  final int flashPts;
  final double flashAge;
  final int streak;
  final double idle;
  final bool started;
  final bool running;
  final bool accelerating;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _HalfLifeV2Painter({
    required this.unit,
    required this.hl,
    required this.sample,
    required this.frac,
    required this.alive,
    required this.nextBeat,
    required this.curN,
    required this.capN,
    required this.capQ,
    required this.inter,
    required this.flashQ,
    required this.flashPts,
    required this.flashAge,
    required this.streak,
    required this.idle,
    required this.started,
    required this.running,
    required this.accelerating,
    required this.sparks,
    required this.pops,
  });

  static double _targetFrac(int beat) => math.pow(0.5, beat + 1).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accelerating ? _kWarn : _kAccent, idle,
        motes: 24);
    _paintHeader(canvas, size);
    _paintMetronome(canvas, size);
    _paintCloud(canvas, size);
    if (accelerating) _paintSpeedLines(canvas, size);
    FxBurst.paint(canvas, sparks);
    _paintStepTracker(canvas, size);
    _paintCurve(canvas, size);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintFlash(canvas, size);
    _paintTapHint(canvas, size);
    if (!started || !running) _paintReady(canvas, size);
  }

  // ── Prompt header ──
  void _paintHeader(Canvas canvas, Size size) {
    if (!started) return;
    GameFx.text(
      canvas,
      'SAMPLE ${sample + 1}   ·   t½ ${hl.toStringAsFixed(1)}s',
      Offset(size.width / 2, size.height * 0.05),
      12,
      Potatuhs.textSecondary,
      weight: FontWeight.w700,
    );

    // The live callout: which halving are we hunting?
    if (nextBeat < _kBeats && !inter) {
      final label = _fmtPct(_targetFrac(nextBeat) * 100);
      final pulse = 0.78 + 0.22 * (0.5 + 0.5 * math.sin(idle * 5));
      GameFx.text(
        canvas,
        'FIND  $label%',
        Offset(size.width / 2, size.height * 0.105),
        26,
        _kAccent.withValues(alpha: pulse),
        display: true,
        glow: 0.6,
      );
    } else {
      GameFx.text(
        canvas,
        'NEXT SAMPLE…',
        Offset(size.width / 2, size.height * 0.105),
        22,
        Potatuhs.textFaint,
        display: true,
      );
    }
    // Loud, persistent RULE: mark the sample every single halving.
    final rulePulse = 0.7 + 0.3 * (0.5 + 0.5 * math.sin(idle * 3.5));
    GameFx.text(
      canvas,
      '⚡ TAP EACH TIME IT HALVES',
      Offset(size.width / 2, size.height * 0.145),
      13,
      _kWhite.withValues(alpha: rulePulse),
      weight: FontWeight.w900,
    );

    if (streak >= 2) {
      GameFx.text(
        canvas,
        '🔥 $streak',
        Offset(size.width * 0.86, size.height * 0.05),
        15,
        _kWarn,
        weight: FontWeight.w800,
      );
    }
  }

  // ── The fuzzy glow cloud (no countable grid, no integer) ──
  void _paintCloud(Canvas canvas, Size size) {
    final g = _cloudGeom(size);
    final center = g.center;
    final r = g.r;
    // Hotter / redder glow while the decay is being forced.
    final cloudCol = accelerating ? Color.lerp(_kAccent, _kWarn, 0.6)! : _kAccent;
    final blob = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);

    // Soft containment halo so the mass reads as one cloud, not dots.
    if (started) {
      canvas.drawCircle(
        center,
        r * (accelerating ? 1.45 : 1.35),
        Paint()
          ..color =
              cloudCol.withValues(alpha: 0.05 * frac + (accelerating ? 0.06 : 0.02))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }

    final breathe = 0.94 + 0.06 * math.sin(idle * 1.8);
    for (var i = 0; i < _kN; i++) {
      if (!alive[i] && started) continue;
      final wobble = Offset(
        math.sin(idle * 1.1 + i) * r * 0.03,
        math.cos(idle * 1.3 + i * 1.7) * r * 0.03,
      );
      final p = center + unit[i] * r * breathe + wobble;
      // Overlapping blurred blobs with no rim/specular → uncountable mass.
      canvas.drawCircle(
          p,
          r * 0.20,
          blob..color = cloudCol.withValues(alpha: accelerating ? 0.52 : 0.42));
      canvas.drawCircle(
          p, r * 0.10, Paint()..color = _kWhite.withValues(alpha: 0.22));
    }
  }

  // ── Metronome: a ring that grows and peaks at each expected halving, so the
  // constant half-life interval is *felt*. Halvings land at integer curN, so
  // the beat phase (curN mod 1) drives one even pulse per half-life. ──
  void _paintMetronome(Canvas canvas, Size size) {
    if (!started || inter || nextBeat >= _kBeats) return;
    final g = _cloudGeom(size);
    final center = g.center;
    final r = g.r;
    final phase = curN - curN.floorToDouble(); // 0 → 1 between halvings
    final grow = phase; // ring swells as the next beat approaches
    // Ring peaks at _kMetroMax × r so it never punches out of the cloud band
    // into the header above or the flash/tracker below.
    final ringR = r * (1.05 + (_kMetroMax - 1.05) * grow);
    final col = accelerating ? _kWarn : _kAccent;
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + 2.5 * grow
        ..color = col.withValues(alpha: 0.10 + 0.45 * grow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  // ── Speed-lines while forcing decay (racing feel). ──
  void _paintSpeedLines(Canvas canvas, Size size) {
    final g = _cloudGeom(size);
    final center = g.center;
    final r = g.r;
    final paint = Paint()
      ..color = _kWarn.withValues(alpha: 0.5)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final ang = (i / 10) * math.pi * 2 + idle * 0.6;
      final phase = (idle * 4 + i) % 1.0;
      final r0 = r * (1.3 + phase * 0.9);
      final r1 = r0 + r * 0.28;
      final dir = Offset(math.cos(ang), math.sin(ang));
      canvas.drawLine(
        center + dir * r0,
        center + dir * r1,
        paint..color = _kWarn.withValues(alpha: 0.45 * (1 - phase)),
      );
    }
  }

  // ── Step tracker: 100 → 50 → 25 → 12.5 → 6.25. Each halving fills as it is
  // captured; the current target is highlighted ("you are hunting X now"). ──
  void _paintStepTracker(Canvas canvas, Size size) {
    if (!started) return;
    final labels = <String>[
      '100',
      for (var b = 0; b < _kBeats; b++) _fmtPct(_targetFrac(b) * 100),
    ];
    final y = size.height * 0.525;
    final n = labels.length;
    final spacing = math.min(size.width / (n + 0.2), 74.0);
    final startX = size.width / 2 - spacing * (n - 1) / 2;

    // Connecting rail behind the pills.
    canvas.drawLine(
      Offset(startX, y),
      Offset(startX + spacing * (n - 1), y),
      Paint()
        ..color = Potatuhs.textFaint.withValues(alpha: 0.25)
        ..strokeWidth = 1.4,
    );

    for (var i = 0; i < n; i++) {
      final x = startX + spacing * i;
      final b = i - 1; // pill 0 is the given start (100%), else beat index
      final done = i == 0 || (b >= 0 && b < capN.length && capN[b] != null);
      final isCurrent = b == nextBeat && !inter && b >= 0;
      final pulse =
          isCurrent ? 0.6 + 0.4 * (0.5 + 0.5 * math.sin(idle * 5)) : 1.0;

      final bg = isCurrent
          ? _kAccent.withValues(alpha: 0.9 * pulse)
          : done
              ? _kGood.withValues(alpha: 0.26)
              : Potatuhs.textFaint.withValues(alpha: 0.10);
      final txtCol = isCurrent
          ? Colors.black
          : done
              ? _kGood
              : Potatuhs.textFaint;

      final w = labels[i].length * 7.0 + 12;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: w, height: 18),
        const Radius.circular(9),
      );
      if (isCurrent) {
        canvas.drawRRect(
          rect.inflate(3),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _kAccent.withValues(alpha: pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawRRect(rect, Paint()..color = bg);
      GameFx.text(canvas, '${labels[i]}%', Offset(x, y), 9.5, txtCol,
          weight: FontWeight.w800);
    }

    if (nextBeat < _kBeats && !inter) {
      GameFx.text(
        canvas,
        'you are hunting ${_fmtPct(_targetFrac(nextBeat) * 100)}% now',
        Offset(size.width / 2, y + 18),
        10,
        _kAccent.withValues(alpha: 0.85),
        weight: FontWeight.w700,
      );
    }
  }

  // ── The exponential decay curve + target rings (the teaching surface) ──
  void _paintCurve(Canvas canvas, Size size) {
    if (!started) return;
    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final top = size.height * 0.585;
    final bot = size.height * 0.85;
    const maxN = _kBeats + 0.9;

    double xAt(double n) => left + (right - left) * (n / maxN);
    double yAt(double f) => bot - (bot - top) * f;

    // Axes.
    final axis = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, top), Offset(left, bot), axis);
    canvas.drawLine(Offset(left, bot), Offset(right, bot), axis);

    // Half-life gridlines.
    final grid = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var n = 1; n <= maxN.ceil(); n++) {
      final x = xAt(n.toDouble());
      if (x > right) break;
      canvas.drawLine(Offset(x, top), Offset(x, bot), grid);
    }

    // The 2^-n curve (the shape — but NO live cursor: you read the cloud).
    final path = Path();
    for (var s = 0; s <= 60; s++) {
      final n = maxN * s / 60;
      final f = math.pow(0.5, n).toDouble();
      final p = Offset(xAt(n), yAt(f));
      if (s == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kAccent.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Target rings for each beat.
    for (var b = 0; b < _kBeats; b++) {
      final tx = xAt((b + 1).toDouble());
      final ty = yAt(_targetFrac(b));
      final captured = capN[b] != null;
      final isNext = b == nextBeat && !inter;

      if (captured) {
        // Frozen tap marker + its quality, and the true % readout (post-tap).
        final mx = xAt(capN[b]!.clamp(0.0, maxN));
        final my = yAt(math.pow(0.5, capN[b]!).clamp(0.0, 1.0).toDouble());
        final qc = capQ[b] == 2
            ? _kAccent
            : (capQ[b] == 1 ? _kGood : _kWarn);
        // Ghost of the target.
        canvas.drawCircle(
            Offset(tx, ty),
            6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = _kGood.withValues(alpha: 0.4));
        // Where you actually measured.
        canvas.drawCircle(Offset(mx, my), 8,
            Paint()..color = qc.withValues(alpha: 0.30));
        canvas.drawCircle(Offset(mx, my), 4, Paint()..color = qc);
        final readPct = math.pow(0.5, capN[b]!).toDouble() * 100;
        GameFx.text(canvas, '${_fmtPct(readPct)}%', Offset(mx, my - 16), 10, qc,
            weight: FontWeight.w800);
      } else {
        final pulse = isNext ? 0.6 + 0.4 * (0.5 + 0.5 * math.sin(idle * 5)) : 1.0;
        final col = isNext ? _kAccent : Potatuhs.textFaint.withValues(alpha: 0.5);
        // Dashed drop-line to the axis for the next target (aim guide).
        if (isNext) {
          _dashedLine(canvas, Offset(tx, ty), Offset(tx, bot),
              Paint()..color = _kAccent.withValues(alpha: 0.4)..strokeWidth = 1.3);
        }
        canvas.drawCircle(
          Offset(tx, ty),
          isNext ? 8 : 5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isNext ? 2.6 : 1.8
            ..color = col.withValues(alpha: pulse),
        );
      }
      // Beat label under the axis.
      final tl = _fmtPct(_targetFrac(b) * 100);
      GameFx.text(canvas, '$tl%', Offset(tx, bot + 12), 9.5,
          Potatuhs.textFaint, weight: FontWeight.w600);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * math.min(d + dash, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  // ── Per-tap hit flash ──
  void _paintFlash(Canvas canvas, Size size) {
    if (flashAge > _kFlashTime) return;
    final a = (1 - flashAge / _kFlashTime).clamp(0.0, 1.0);
    final label = flashQ == 2 ? 'PERFECT!' : (flashQ == 1 ? 'CLOSE' : 'OFF');
    final col = flashQ == 2 ? _kAccent : (flashQ == 1 ? _kGood : _kWarn);
    // The result overlays the cloud centre (reads as "this measurement's grade")
    // and sits well above the step-tracker band, so it never fights the rail.
    GameFx.text(
      canvas,
      label,
      Offset(size.width / 2, size.height * _kCloudCY),
      flashQ == 2 ? 26 : 20,
      col.withValues(alpha: a),
      display: true,
      glow: 0.6 * a,
    );
    if (flashPts > 0) {
      GameFx.text(
        canvas,
        '+$flashPts',
        Offset(size.width / 2, size.height * (_kCloudCY + 0.05)),
        14,
        col.withValues(alpha: a),
        weight: FontWeight.w800,
      );
    }
  }

  // ── Tap affordance (bottom-centre). Doubles as the ⏩ ACCELERATING readout
  // while the FORCE DECAY button is held, so the two never stack on one line. ──
  void _paintTapHint(Canvas canvas, Size size) {
    if (!started || !running) return;
    final live = nextBeat < _kBeats && !inter;
    // Sit left-of-centre: the FORCE DECAY button owns the bottom-right corner.
    final hintX = size.width * 0.34;
    final hintY = size.height * 0.955;
    if (accelerating) {
      final pulse = 0.7 + 0.3 * (0.5 + 0.5 * math.sin(idle * 9));
      GameFx.text(
        canvas,
        '⏩ ACCELERATING',
        Offset(hintX, hintY),
        15,
        _kWarn.withValues(alpha: pulse),
        display: true,
        glow: 0.5 * pulse,
      );
      return;
    }
    final pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(idle * 4));
    GameFx.text(
      canvas,
      'TAP TO MEASURE',
      Offset(hintX, hintY),
      15,
      (live ? _kAccent : Potatuhs.textFaint).withValues(alpha: live ? pulse : 0.4),
      weight: FontWeight.w800,
    );
  }

  // ── Ready / pre-start ──
  void _paintReady(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'RADIOACTIVE SAMPLE',
      Offset(size.width / 2, size.height * 0.62),
      22,
      _kAccent,
      display: true,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      'MARK IT EVERY TIME IT HALVES',
      Offset(size.width / 2, size.height * 0.662),
      14,
      _kWhite,
      weight: FontWeight.w900,
    );
    GameFx.text(
      canvas,
      'tap the glow at 50 · 25 · 12.5 · 6.25%',
      Offset(size.width / 2, size.height * 0.70),
      13,
      Potatuhs.textSecondary,
    );
    GameFx.text(
      canvas,
      'each halving takes the same time — feel it, don\'t count',
      Offset(size.width / 2, size.height * 0.735),
      11,
      Potatuhs.textFaint,
    );
    GameFx.text(
      canvas,
      'hold ⏩ FORCE DECAY to race the clock — bonus points, harder taps',
      Offset(size.width / 2, size.height * 0.775),
      11,
      _kWarn.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _HalfLifeV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (the same glow cloud, decay curve, step rail and FORCE DECAY
// button the live game uses). Static + cheap: rendered once in the intro.
// ═══════════════════════════════════════════════════════════════════════════

/// Golden-angle disc positions for the legend cloud (mirrors the live [_spiral]).
final List<Offset> _kLegendUnit = () {
  final golden = math.pi * (3 - math.sqrt(5));
  return [
    for (var i = 0; i < _kN; i++)
      Offset(
        math.sqrt((i + 0.5) / _kN) * math.cos(i * golden),
        math.sqrt((i + 0.5) / _kN) * math.sin(i * golden),
      ),
  ];
}();

/// The fuzzy, uncountable glow cloud — same overlapping-blurred-blob style as
/// [_HalfLifeV2Painter._paintCloud]. [frac] fades atoms out deterministically
/// (higher = fuller); [hot] tints it toward the FORCE-DECAY warn colour.
void _drawLegendCloud(Canvas canvas, Offset center, double r,
    {double frac = 1.0, bool hot = false}) {
  if (r <= 0) return;
  final cloudCol = hot ? Color.lerp(_kAccent, _kWarn, 0.6)! : _kAccent;
  final blob = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
  canvas.drawCircle(
    center,
    r * (hot ? 1.45 : 1.35),
    Paint()
      ..color = cloudCol.withValues(alpha: 0.05 * frac + (hot ? 0.06 : 0.03))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );
  for (var i = 0; i < _kN; i++) {
    if (frac <= i / _kN) continue; // deterministic decay: front atoms fade first
    final p = center + _kLegendUnit[i] * r;
    canvas.drawCircle(
        p, r * 0.20, blob..color = cloudCol.withValues(alpha: hot ? 0.52 : 0.42));
    canvas.drawCircle(p, r * 0.10, Paint()..color = _kWhite.withValues(alpha: 0.22));
  }
}

/// The 100 → 50 → 25 → 12.5 → 6.25 % step rail (mirrors [_paintStepTracker]).
/// [currentIndex] is the highlighted (accent) pill; earlier pills read as
/// captured (green), later ones faint.
void _drawLegendSteps(Canvas canvas, Size size, double cy, int currentIndex) {
  final labels = <String>[
    '100',
    for (var b = 0; b < _kBeats; b++) _fmtPct(math.pow(0.5, b + 1).toDouble() * 100),
  ];
  final n = labels.length;
  final spacing = math.min(size.width / (n + 0.2), 74.0);
  final startX = size.width / 2 - spacing * (n - 1) / 2;
  canvas.drawLine(
    Offset(startX, cy),
    Offset(startX + spacing * (n - 1), cy),
    Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.25)
      ..strokeWidth = 1.4,
  );
  for (var i = 0; i < n; i++) {
    final x = startX + spacing * i;
    final isCurrent = i == currentIndex;
    final done = i < currentIndex;
    final bg = isCurrent
        ? _kAccent.withValues(alpha: 0.9)
        : done
            ? _kGood.withValues(alpha: 0.26)
            : Potatuhs.textFaint.withValues(alpha: 0.10);
    final txtCol = isCurrent
        ? Colors.black
        : done
            ? _kGood
            : Potatuhs.textFaint;
    final w = labels[i].length * 7.0 + 12;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, cy), width: w, height: 18),
      const Radius.circular(9),
    );
    if (isCurrent) {
      canvas.drawRRect(
        rect.inflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawRRect(rect, Paint()..color = bg);
    GameFx.text(canvas, '${labels[i]}%', Offset(x, cy), 9.5, txtCol,
        weight: FontWeight.w800);
  }
}

/// The exponential-decay curve with its target rings (mirrors [_paintCurve]).
/// [capN] holds captured tap positions in half-lives (null = not yet), [capQ]
/// their quality (2 perfect / 1 close / 0 off); [nextBeat] highlights the ring
/// currently being hunted.
void _drawLegendCurve(Canvas canvas, Size size,
    {required List<double?> capN, required List<int> capQ, int nextBeat = -1}) {
  final left = size.width * 0.14;
  final right = size.width * 0.86;
  final top = size.height * 0.26;
  final bot = size.height * 0.78;
  if (right <= left || bot <= top) return;
  const maxN = _kBeats + 0.9;
  double xAt(double n) => left + (right - left) * (n / maxN);
  double yAt(double f) => bot - (bot - top) * f;

  final axis = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
    ..strokeWidth = 1.2;
  canvas.drawLine(Offset(left, top), Offset(left, bot), axis);
  canvas.drawLine(Offset(left, bot), Offset(right, bot), axis);

  final grid = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.16)
    ..strokeWidth = 1;
  for (var n = 1; n <= maxN.ceil(); n++) {
    final x = xAt(n.toDouble());
    if (x > right) break;
    canvas.drawLine(Offset(x, top), Offset(x, bot), grid);
  }

  final path = Path();
  for (var s = 0; s <= 60; s++) {
    final n = maxN * s / 60;
    final f = math.pow(0.5, n).toDouble();
    final p = Offset(xAt(n), yAt(f));
    s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kAccent.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );

  for (var b = 0; b < _kBeats; b++) {
    final tx = xAt((b + 1).toDouble());
    final ty = yAt(math.pow(0.5, b + 1).toDouble());
    final captured = b < capN.length && capN[b] != null;
    final isNext = b == nextBeat;
    if (captured) {
      final mx = xAt(capN[b]!.clamp(0.0, maxN));
      final my = yAt(math.pow(0.5, capN[b]!).clamp(0.0, 1.0).toDouble());
      final qc = capQ[b] == 2 ? _kAccent : (capQ[b] == 1 ? _kGood : _kWarn);
      // Ghost of the true target ring.
      canvas.drawCircle(
          Offset(tx, ty),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = _kGood.withValues(alpha: 0.4));
      // Where the player actually measured.
      canvas.drawCircle(Offset(mx, my), 8, Paint()..color = qc.withValues(alpha: 0.30));
      canvas.drawCircle(Offset(mx, my), 4, Paint()..color = qc);
      final label = capQ[b] == 2 ? 'PERFECT' : (capQ[b] == 1 ? 'CLOSE' : 'OFF · 0');
      GameFx.text(canvas, label, Offset(mx, my - 16), 10, qc, weight: FontWeight.w800);
    } else {
      final col = isNext ? _kAccent : Potatuhs.textFaint.withValues(alpha: 0.5);
      canvas.drawCircle(
        Offset(tx, ty),
        isNext ? 8 : 5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isNext ? 2.6 : 1.8
          ..color = col,
      );
    }
    GameFx.text(canvas, '${_fmtPct(math.pow(0.5, b + 1).toDouble() * 100)}%',
        Offset(tx, bot + 12), 9.5, Potatuhs.textFaint, weight: FontWeight.w600);
  }
}

/// The ⏩ FORCE DECAY control drawn exactly as [_AccelButton] renders it (held /
/// active state), with the racing speed-lines that appear while it is pressed.
void _drawLegendAccelButton(Canvas canvas, Offset center) {
  const w = 158.0, h = 42.0;
  final rect = Rect.fromCenter(center: center, width: w, height: h);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
  // Active glow.
  canvas.drawRRect(
    rr.inflate(3),
    Paint()
      ..color = _kWarn.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
  );
  canvas.drawRRect(rr, Paint()..color = _kWarn.withValues(alpha: 0.92));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kWarn,
  );
  GameFx.text(canvas, '⏩ FORCE DECAY', center, 13, Colors.black,
      weight: FontWeight.w900);
}

void _drawLegendSpeedLines(Canvas canvas, Offset center, double r) {
  if (r <= 0) return;
  final paint = Paint()
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 10; i++) {
    final ang = (i / 10) * math.pi * 2;
    final dir = Offset(math.cos(ang), math.sin(ang));
    canvas.drawLine(
      center + dir * (r * 1.35),
      center + dir * (r * 1.7),
      paint..color = _kWarn.withValues(alpha: 0.5),
    );
  }
}

void _legendCloud(Canvas canvas, Size size) {
  if (size.width < 4 || size.height < 4) return;
  final center = Offset(size.width / 2, size.height * 0.36);
  final r = math.min(size.width * 0.30, size.height * 0.20);
  _drawLegendCloud(canvas, center, r, frac: 0.9);
  _drawLegendSteps(canvas, size, size.height * 0.78, 1);
}

void _legendScore(Canvas canvas, Size size) {
  if (size.width < 4 || size.height < 4) return;
  _drawLegendCurve(canvas, size,
      capN: [1.0, null, null, null], capQ: [2, 0, 0, 0], nextBeat: 1);
}

void _legendDanger(Canvas canvas, Size size) {
  if (size.width < 4 || size.height < 4) return;
  // A tap that lands late (well past the 50% ring) reads OFF and scores zero.
  _drawLegendCurve(canvas, size,
      capN: [1.42, null, null, null], capQ: [0, 0, 0, 0], nextBeat: -1);
}

void _legendForce(Canvas canvas, Size size) {
  if (size.width < 4 || size.height < 4) return;
  final center = Offset(size.width / 2, size.height * 0.38);
  final r = math.min(size.width * 0.26, size.height * 0.18);
  _drawLegendSpeedLines(canvas, center, r);
  _drawLegendCloud(canvas, center, r, frac: 0.45, hot: true);
  _drawLegendAccelButton(canvas, Offset(size.width / 2, size.height * 0.80));
}

/// The visual manual for Half-Life v2 — wired into the registry spec.
final List<LegendFrame> halfLifeV2LegendFrames = [
  const LegendFrame(
      caption: 'Tap the glow at 50·25·12.5·6.25% as it halves',
      paint: _legendCloud),
  const LegendFrame(
      caption: 'Tap dead-on the ring: closer = more points',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Mistime it and the tap scores zero — streak resets',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Hold ⏩ FORCE DECAY to race the clock for bonus',
      paint: _legendForce),
];
