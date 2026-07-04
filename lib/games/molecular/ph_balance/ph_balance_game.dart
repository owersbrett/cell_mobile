import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══ pH Balance ═══════════════════════════════════════════════════════════════
//
// VERB = TITRATE / BALANCE. A beaker holds a liquid at some pH. Each round names
// a TARGET pH; the player taps ACID (H⁺, lowers pH) or BASE (OH⁻, raises pH) to
// titrate the liquid onto the target band and HOLD it there. The catch — and the
// lesson — is that the titration curve is steep near pH 7: a single drop swings
// the needle hard through the neutralization point, so it overshoots and slings
// the other way. A universal-indicator color (red→green→violet) and a live 0–14
// scale teach acids, bases, and neutralization in the mechanic itself.
//
// Host owns the clock / countdown / score readout / results. This widget renders
// ONLY the play area: one Ticker drives one CustomPainter; taps mutate state and
// the next frame paints it (no per-tap setState).

// ── Feel constants (all tunable in one place) ────────────────────────────────

// Tolerance: half-width of the target band, in pH units. Tightens per level.
const double _kTolStart = 0.90;
const double _kTolStep = 0.06;
const double _kTolMin = 0.35;

// Hold time (s) the needle must stay in-band to score a target. Quickens.
const double _kHoldStart = 1.25;
const double _kHoldStep = 0.04;
const double _kHoldMin = 0.75;

// Drop strength: base pH delta per drop (before the steepness multiplier).
// Grows per level → stronger acid/base → faster, harder-to-tame swings.
const double _kDropBase = 0.090;
const double _kDropStep = 0.012;
const double _kDropMax = 0.200;

// Steepness of the titration curve near pH 7 (the neutralization spike).
// effect = drop × (1 + steepK · gaussian(pH−7)). Grows per level.
const double _kSteepBase = 1.8;
const double _kSteepStep = 0.12;
const double _kSteepMax = 3.2;
const double _kSigma = 1.7; // width of the steep region around pH 7

// Passive acidifying drift (CO₂ creep) — kicks in at level 3+, forcing the
// player to keep actively titrating to hold a basic target.
const double _kDriftStep = 0.05;
const double _kDriftMax = 0.35;

// At level 4+ the target itself slowly drifts along the scale (moving goal).
const double _kTargetDrift = 0.18; // pH/s

// ATTRACT autopilot cadence — the host calls the hook roughly this often
// (seconds). Used to look one tick ahead so the acidifying drift is corrected
// before it pushes the needle out the bottom of the band.
const double _kAutoTick = 0.25;

// Scoring.
const int _kHitBase = 40; // points for landing & holding a target
const int _kHitBonus = 30; // extra, scaled by how centered the land was
const double _kDripPerSec = 4.0; // points/sec while holding in-band
const double _kHoldPullback = 0.7; // hold-meter bleed rate when out of band

// ── Palette ──────────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont; // 'Outfit'
const Color _kAccent = Color(0xFF3DDC97); // neutral-green, the game accent
const Color _kInk = Color(0xFF0C1410); // deep beaker-lab background
const Color _kGlass = Color(0xFFBFE9DA);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kAcid = Color(0xFFEF5350); // acid button (red end)
const Color _kBase = Color(0xFF5E7CE2); // base button (blue end)

// Universal-indicator color ramp, one entry per integer pH 0..14.
const List<Color> _kPhColors = [
  Color(0xFFE53935), // 0  strong acid — red
  Color(0xFFEF5350), // 1
  Color(0xFFFF7043), // 2
  Color(0xFFFF9800), // 3  orange
  Color(0xFFFFB300), // 4
  Color(0xFFFDD835), // 5  yellow
  Color(0xFFD4E157), // 6  lime
  Color(0xFF66BB6A), // 7  NEUTRAL — green
  Color(0xFF26A69A), // 8  teal
  Color(0xFF29B6F6), // 9
  Color(0xFF2196F3), // 10 blue
  Color(0xFF3F51B5), // 11 indigo
  Color(0xFF5E35B1), // 12
  Color(0xFF7B1FA2), // 13 purple
  Color(0xFF6A1B9A), // 14 strong base — violet
];

Color _phColor(double ph) {
  final p = ph.clamp(0.0, 14.0);
  final i = p.floor().clamp(0, 13);
  return Color.lerp(_kPhColors[i], _kPhColors[i + 1], p - i)!;
}

/// "pH Balance" — titrate the beaker to the target pH and hold it. Acid and base
/// drops swing hardest near neutral, where the titration curve is steep.
class PhBalanceGame extends StatefulWidget {
  final MiniGameSession session;
  const PhBalanceGame({super.key, required this.session});

  @override
  State<PhBalanceGame> createState() => _PhBalanceGameState();
}

class _PhBalanceGameState extends State<PhBalanceGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────────
  double _ph = 7.0; // displayed (eased) pH
  double _phGoal = 7.0; // chemical pH the drops set; _ph eases toward it
  double _target = 4.0;
  double _tol = _kTolStart;
  double _holdNeeded = _kHoldStart;
  double _holdAcc = 0.0; // seconds held in-band toward the current target
  double _dripAcc = 0.0; // fractional drip-point accumulator
  int _level = 1;
  int _targetsHit = 0;
  int _streak = 0;
  int _targetDriftDir = 1;
  bool _approached = false; // got near the band → arms overshoot detection
  bool _wasRunning = false;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _idle = 0.0;
  double _greenFlash = 0.0;
  double _missFlash = 0.0;
  double _ripple = 0.0;
  double _acidPulse = 0.0;
  double _basePulse = 0.0;
  final List<_Bubble> _bubbles = [];
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  // ── Per-level derived values ────────────────────────────────────────────────
  double get _dropStrength =>
      math.min(_kDropMax, _kDropBase + (_level - 1) * _kDropStep);
  double get _steepK =>
      math.min(_kSteepMax, _kSteepBase + (_level - 1) * _kSteepStep);
  double get _driftRate =>
      _level < 3 ? 0.0 : math.min(_kDriftMax, (_level - 2) * _kDriftStep);

  double _steep(double ph) {
    final d = ph - 7.0;
    return 1.0 + _steepK * math.exp(-(d * d) / (2 * _kSigma * _kSigma));
  }

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 7; i++) {
      _bubbles.add(_Bubble.random(_rng));
    }
    // ATTRACT autopilot: this game knows how to titrate itself. Registered
    // always (harmless in normal play — the host only calls it in autoplay).
    // See [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Titrates pH Balance
  /// *correctly*, not randomly: it reads the current needle, projects it one
  /// tick ahead by the acidifying drift, and adds a single ACID or BASE drop
  /// to steer toward the target band. Once the needle is inside the band it
  /// does NOTHING — so it never overshoots the neutralization spike past the
  /// target. Holding in-band is passive (scored in [_onTick]); there is no
  /// separate lock to call. The host owns the clock, so the round still ends
  /// on time; the bot just banks real hold points until it does.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    // Where the needle will sit next tick: the passive drift acidifies (lowers)
    // the pH, so project it downward by one tick's worth.
    final projected = _ph - _driftRate * _kAutoTick;
    if (projected > _target + _tol) {
      _addDrop(true); // above the band → ACID lowers pH toward it
    } else if (projected < _target - _tol) {
      _addDrop(false); // below the band → BASE raises pH toward it
    }
    // In-band → hold: do nothing so we don't sling past the target.
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRound();
    _wasRunning = running;

    _idle += dt;
    // Ease the visible needle toward the chemical pH (smooth titration motion).
    _ph += (_phGoal - _ph) * (1 - math.exp(-dt * 14));

    if (running) {
      // Passive acidifying drift at higher levels.
      if (_driftRate > 0) {
        _phGoal = (_phGoal - _driftRate * dt).clamp(0.0, 14.0);
      }
      // Drifting target at the top levels.
      if (_level >= 4) {
        _target += _targetDriftDir * _kTargetDrift * dt;
        if (_target < 1.0) {
          _target = 1.0;
          _targetDriftDir = 1;
        } else if (_target > 13.0) {
          _target = 13.0;
          _targetDriftDir = -1;
        }
      }

      final err = (_ph - _target).abs();
      final inBand = err <= _tol;
      if (err < _tol * 1.6) _approached = true;
      // Overshoot: was closing in, now flung well past → break the streak.
      if (_approached && err > _tol * 3.5) {
        _streak = 0;
        _missFlash = 0.85;
        _approached = false;
      }

      if (inBand) {
        _holdAcc += dt;
        _dripAcc += _kDripPerSec * dt;
        if (_dripAcc >= 1) {
          final n = _dripAcc.floor();
          widget.session.addScore(n);
          _dripAcc -= n;
        }
        if (_holdAcc >= _holdNeeded) _registerHit(err);
      } else {
        _holdAcc = math.max(0.0, _holdAcc - dt * _kHoldPullback);
      }
    }

    _updateBubbles(dt, running);
    for (final s in _sparks) {
      s.age += dt;
      s.pos += s.vel * dt;
      s.vel *= math.pow(0.06, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    _greenFlash = math.max(0.0, _greenFlash - dt * 2.5);
    _missFlash = math.max(0.0, _missFlash - dt * 3.0);
    _ripple = math.max(0.0, _ripple - dt * 1.8);
    _acidPulse = math.max(0.0, _acidPulse - dt * 3.0);
    _basePulse = math.max(0.0, _basePulse - dt * 3.0);

    setState(() {});
  }

  void _startRound() {
    _targetsHit = 0;
    _streak = 0;
    _holdAcc = 0;
    _dripAcc = 0;
    _approached = false;
    _phGoal = 7.0;
    _ph = 7.0;
    _newTarget();
  }

  void _registerHit(double err) {
    final centered = (1 - err / _tol).clamp(0.0, 1.0);
    final pts = _kHitBase + (centered * _kHitBonus).round();
    widget.session.addScore(pts);
    _targetsHit++;
    _streak++;
    widget.session.noteStreak(_streak);
    _greenFlash = 1.0;
    _holdAcc = 0;
    _approached = false;
    _popups.add(_Popup('+$pts', _kGood));
    _spawnSparks(18);
    _newTarget();
  }

  void _newTarget() {
    _level = _targetsHit + 1;
    _tol = math.max(_kTolMin, _kTolStart - (_level - 1) * _kTolStep);
    _holdNeeded = math.max(_kHoldMin, _kHoldStart - (_level - 1) * _kHoldStep);
    // Bias toward the hard near-neutral region as the level climbs.
    final neutralChance = (0.18 + _level * 0.06).clamp(0.0, 0.65);
    double t = 7.0;
    var tries = 0;
    do {
      if (_rng.nextDouble() < neutralChance) {
        t = 6.0 + _rng.nextDouble() * 2.0; // 6–8: steep, twitchy
      } else {
        t = 1.5 + _rng.nextDouble() * 11.0; // 1.5–12.5
      }
      tries++;
    } while ((t - _ph).abs() < 1.6 && tries < 8);
    _target = t;
    _targetDriftDir = _rng.nextBool() ? 1 : -1;
  }

  void _addDrop(bool acid) {
    if (!widget.session.isRunning) return;
    final delta = _dropStrength * _steep(_phGoal);
    _phGoal = (_phGoal + (acid ? -delta : delta)).clamp(0.0, 14.0);
    _ripple = 1.0;
    if (acid) {
      _acidPulse = 1.0;
    } else {
      _basePulse = 1.0;
    }
    for (var i = 0; i < 4; i++) {
      _bubbles.add(_Bubble.burst(_rng));
    }
  }

  void _updateBubbles(double dt, bool running) {
    final rate = running ? (0.7 + _ripple) : 0.35;
    for (final b in _bubbles) {
      b.y += b.speed * rate * dt;
      b.x += math.sin((_idle + b.phase) * 1.6) * 0.05 * dt;
    }
    _bubbles.removeWhere((b) => b.y > 1.0);
    if (_bubbles.length < 7 && _rng.nextDouble() < 0.5) {
      _bubbles.add(_Bubble.random(_rng)..y = 0.0);
    }
  }

  void _spawnSparks(int count) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed = 90.0 + _rng.nextDouble() * 150;
      _sparks.add(_Spark(
        pos: Offset.zero,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.35 + _rng.nextDouble() * 0.4,
        radius: 1.2 + _rng.nextDouble() * 2.2,
        color: i.isEven ? _kGood : _kAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PhPainter(
                ph: _ph,
                target: _target,
                tol: _tol,
                holdFrac: (_holdAcc / _holdNeeded).clamp(0.0, 1.0),
                level: _level,
                streak: _streak,
                running: running,
                idle: _idle,
                ripple: _ripple,
                greenFlash: _greenFlash,
                missFlash: _missFlash,
                bubbles: _bubbles,
                sparks: _sparks,
                popups: _popups,
              ),
            ),
          ),
          // Two big titration buttons along the bottom.
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: _DropButton(
                    label: 'ACID',
                    sub: 'H⁺  pH ▼',
                    color: _kAcid,
                    icon: Icons.south_rounded,
                    enabled: running,
                    pulse: _acidPulse,
                    onTap: () => _addDrop(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropButton(
                    label: 'BASE',
                    sub: 'OH⁻  pH ▲',
                    color: _kBase,
                    icon: Icons.north_rounded,
                    enabled: running,
                    pulse: _basePulse,
                    onTap: () => _addDrop(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom titration button ───────────────────────────────────────────────────

class _DropButton extends StatefulWidget {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final bool enabled;
  final double pulse;
  final VoidCallback onTap;
  const _DropButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.enabled,
    required this.pulse,
    required this.onTap,
  });

  @override
  State<_DropButton> createState() => _DropButtonState();
}

class _DropButtonState extends State<_DropButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final c = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: on ? () => setState(() => _down = false) : null,
      onTapUp: on
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: c.withValues(alpha: on ? 0.20 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: c.withValues(alpha: on ? (0.55 + 0.4 * widget.pulse) : 0.18),
              width: 2,
            ),
            boxShadow: (on && widget.pulse > 0)
                ? [BoxShadow(color: c.withValues(alpha: 0.5 * widget.pulse), blurRadius: 18)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: c.withValues(alpha: on ? 1.0 : 0.4)),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: (on ? Potatuhs.textPrimary : Potatuhs.textFaint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: c.withValues(alpha: on ? 0.95 : 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small value types ─────────────────────────────────────────────────────────

class _Bubble {
  double x; // 0..1 across the liquid
  double y; // 0..1 from bottom (0) to surface (1)
  final double r;
  final double speed; // fraction of liquid height per second
  final double phase;
  _Bubble(this.x, this.y, this.r, this.speed, this.phase);

  factory _Bubble.random(math.Random rng) => _Bubble(
        0.12 + rng.nextDouble() * 0.76,
        rng.nextDouble(),
        1.2 + rng.nextDouble() * 2.6,
        0.18 + rng.nextDouble() * 0.30,
        rng.nextDouble() * 6.28,
      );

  factory _Bubble.burst(math.Random rng) => _Bubble(
        0.2 + rng.nextDouble() * 0.6,
        0.0,
        1.4 + rng.nextDouble() * 2.8,
        0.40 + rng.nextDouble() * 0.40,
        rng.nextDouble() * 6.28,
      );
}

class _Spark {
  Offset pos;
  Offset vel;
  double age = 0.0;
  final double life;
  final double radius;
  final Color color;
  _Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
  });
}

class _Popup {
  final String text;
  final Color color;
  final double life;
  double age = 0.0;
  _Popup(this.text, this.color) : life = 1.1;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _PhPainter extends CustomPainter {
  final double ph;
  final double target;
  final double tol;
  final double holdFrac;
  final int level;
  final int streak;
  final bool running;
  final double idle;
  final double ripple;
  final double greenFlash;
  final double missFlash;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  final List<_Popup> popups;

  _PhPainter({
    required this.ph,
    required this.target,
    required this.tol,
    required this.holdFrac,
    required this.level,
    required this.streak,
    required this.running,
    required this.idle,
    required this.ripple,
    required this.greenFlash,
    required this.missFlash,
    required this.bubbles,
    required this.sparks,
    required this.popups,
  });

  static const double _hudH = 56.0;
  static const double _btnReserve = 104.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    _paintGrid(canvas, size);

    const mainTop = _hudH + 8;
    final mainBottom = size.height - _btnReserve;

    // pH scale strip on the right.
    const stripW = 42.0;
    final stripRight = size.width - 14;
    final stripLeft = stripRight - stripW;
    const stripTop = mainTop + 10;
    final stripBottom = mainBottom - 6;
    _paintScale(canvas, stripLeft, stripTop, stripW, stripBottom - stripTop);

    // Beaker centered in the space left of the strip.
    final beakerArea = Rect.fromLTRB(14, mainTop, stripLeft - 14, mainBottom);
    _paintBeaker(canvas, beakerArea);

    _paintHud(canvas, size);
    _paintSparks(canvas, beakerArea.center);
    _paintPopups(canvas, beakerArea);

    if (greenFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: (greenFlash - 0.3) * 0.30));
    }
    if (missFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: missFlash * 0.22));
    }
  }

  double _yForPh(double p, double top, double h) =>
      top + h * (1.0 - (p.clamp(0.0, 14.0) / 14.0));

  void _paintGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _kAccent.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  // ── pH scale strip ─────────────────────────────────────────────────────────
  void _paintScale(
      Canvas canvas, double left, double top, double w, double h) {
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h), const Radius.circular(10));
    // Indicator gradient, pH 14 at top → 0 at bottom.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _kPhColors.reversed.toList(),
        ).createShader(Rect.fromLTWH(left, top, w, h))
        ..colorFilter = ColorFilter.mode(
            Colors.black.withValues(alpha: 0.18), BlendMode.darken),
    );
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.18));

    // Target band.
    final bandTop = _yForPh(target + tol, top, h);
    final bandBot = _yForPh(target - tol, top, h);
    final bandRect = Rect.fromLTRB(left - 4, bandTop, left + w + 4, bandBot);
    canvas.drawRect(bandRect, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawRect(
        bandRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9));

    // Neutral pH-7 reference line.
    final ny = _yForPh(7, top, h);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    for (double x = left; x < left + w; x += 7) {
      canvas.drawLine(Offset(x, ny), Offset(x + 3.5, ny), dash);
    }
    _text(canvas, '7', Offset(left - 12, ny),
        size: 10, color: Colors.white.withValues(alpha: 0.75), bold: true);
    _text(canvas, '14', Offset(left - 13, top + 6),
        size: 9, color: Colors.white.withValues(alpha: 0.55));
    _text(canvas, '0', Offset(left - 11, top + h - 6),
        size: 9, color: Colors.white.withValues(alpha: 0.55));

    // Current-pH marker arrow on the strip.
    final my = _yForPh(ph, top, h);
    final mc = _phColor(ph);
    final path = Path()
      ..moveTo(left - 6, my)
      ..lineTo(left - 16, my - 6)
      ..lineTo(left - 16, my + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = mc);
    canvas.drawLine(
        Offset(left, my),
        Offset(left + w, my),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 2);

    _text(canvas, 'pH', Offset(left + w / 2, top - 12),
        size: 10, color: _kAccent.withValues(alpha: 0.8), bold: true);
  }

  // ── Beaker ───────────────────────────────────────────────────────────────────
  void _paintBeaker(Canvas canvas, Rect area) {
    final bw = math.min(area.width, 188.0);
    final bh = math.min(area.height * 0.84, 250.0);
    final cx = area.center.dx;
    final topY = area.center.dy - bh / 2;
    final glass = Rect.fromCenter(
        center: Offset(cx, topY + bh / 2), width: bw, height: bh);
    final rr = RRect.fromRectAndCorners(glass,
        bottomLeft: const Radius.circular(26),
        bottomRight: const Radius.circular(26),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6));

    // Glass interior tint.
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.03));

    // Liquid.
    const fillFrac = 0.74;
    final liquidTopY = glass.bottom - glass.height * fillFrac;
    final liquid = _phColor(ph);
    canvas.save();
    canvas.clipRRect(rr);
    final liquidRect =
        Rect.fromLTRB(glass.left, liquidTopY, glass.right, glass.bottom);
    canvas.drawRect(
      liquidRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            liquid.withValues(alpha: 0.85),
            Color.lerp(liquid, Colors.black, 0.30)!.withValues(alpha: 0.95),
          ],
        ).createShader(liquidRect),
    );

    // Surface wobble line.
    final wobble = Path();
    final amp = 2.0 + ripple * 4.0;
    wobble.moveTo(glass.left, liquidTopY);
    for (double x = glass.left; x <= glass.right; x += 6) {
      final yy = liquidTopY +
          math.sin((x / 18) + idle * 3.0) * amp * 0.5;
      wobble.lineTo(x, yy);
    }
    canvas.drawPath(
        wobble,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.30));

    // Bubbles.
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.30);
    for (final b in bubbles) {
      final by = glass.bottom - (glass.bottom - liquidTopY) * b.y;
      final bx = glass.left + 6 + (glass.width - 12) * b.x;
      canvas.drawCircle(Offset(bx, by), b.r, bubblePaint);
    }
    canvas.restore();

    // Glass outline + rim.
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _kGlass.withValues(alpha: 0.55));
    canvas.drawLine(
        Offset(glass.left - 6, glass.top),
        Offset(glass.right + 6, glass.top),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = _kGlass.withValues(alpha: 0.7));

    // Hold-progress ring + big pH readout, centered on the liquid.
    final center = Offset(cx, liquidTopY + (glass.bottom - liquidTopY) * 0.46);
    if (holdFrac > 0.01) {
      final ringRect = Rect.fromCircle(center: center, radius: 52);
      canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * holdFrac, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = _kGood.withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    _text(canvas, ph.toStringAsFixed(1), center,
        size: 40,
        color: Colors.white,
        bold: true,
        shadow: Colors.black.withValues(alpha: 0.5));
    _text(canvas, _phLabel(ph), center + const Offset(0, 30),
        size: 11,
        color: Colors.white.withValues(alpha: 0.85),
        bold: true);
  }

  String _phLabel(double p) {
    if (p < 6.4) return 'ACIDIC';
    if (p > 7.6) return 'BASIC';
    return 'NEUTRAL';
  }

  // ── HUD ───────────────────────────────────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    // Level badge (left).
    _badge(canvas, const Offset(16, 14), 'LV $level', _kAccent);
    // Streak badge (right) when active.
    if (streak > 1) {
      _badge(canvas, Offset(size.width - 92, 14), 'STREAK $streak', _kGood);
    }

    // Target readout, centered.
    final tColor = _phColor(target);
    final label = running ? 'TARGET  pH ${target.toStringAsFixed(1)}' : 'BALANCE THE pH';
    final tp = _layout(label,
        size: 16, color: Potatuhs.textPrimary, bold: true);
    final tx = size.width / 2 - tp.width / 2;
    const ty = 18.0;
    if (running) {
      canvas.drawCircle(
          Offset(tx - 12, ty + tp.height / 2), 6, Paint()..color = tColor);
      canvas.drawCircle(
          Offset(tx - 12, ty + tp.height / 2),
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.6));
    }
    tp.paint(canvas, Offset(tx, ty));
  }

  void _badge(Canvas canvas, Offset at, String text, Color color) {
    final tp = _layout(text, size: 11, color: color, bold: true);
    final rect = Rect.fromLTWH(at.dx, at.dy, tp.width + 18, tp.height + 10);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.5));
    tp.paint(canvas, Offset(at.dx + 9, at.dy + 5));
  }

  // ── Sparks & popups ─────────────────────────────────────────────────────────
  void _paintSparks(Canvas canvas, Offset center) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final pos = center + s.pos + s.vel * s.age;
      canvas.drawCircle(
          pos, s.radius * t, Paint()..color = s.color.withValues(alpha: t));
    }
  }

  void _paintPopups(Canvas canvas, Rect area) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 40.0 * t;
      _text(
        canvas,
        p.text,
        Offset(area.center.dx, area.top + 24 - rise),
        size: 22,
        color: p.color.withValues(alpha: alpha),
        bold: true,
        shadow: p.color.withValues(alpha: alpha * 0.7),
      );
    }
  }

  // ── Text helpers ─────────────────────────────────────────────────────────────
  TextPainter _layout(String text,
      {required double size, required Color color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(Canvas canvas, String text, Offset center,
      {required double size,
      required Color color,
      bool bold = false,
      Color? shadow}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
          shadows: shadow != null
              ? [Shadow(color: shadow, blurRadius: 10)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PhPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL components
// (same beaker / indicator strip / titration buttons the live game paints).
// Static + cheap: rendered once on the intro screen, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

bool _lgDegenerate(Size size) =>
    size.width <= 0 ||
    size.height <= 0 ||
    !size.width.isFinite ||
    !size.height.isFinite;

void _lgText(Canvas canvas, String text, Offset center, double fontSize,
    Color color,
    {FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// The 0–14 universal-indicator strip: gradient, optional white target band,
/// dashed neutral-7 line, and the current-pH marker arrow — mirrors
/// [_PhPainter._paintScale].
void _lgStrip(Canvas canvas, Rect r,
    {required double ph,
    double? target,
    double tol = 0.9,
    bool emphasizeSeven = false}) {
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _kPhColors.reversed.toList(),
      ).createShader(r)
      ..colorFilter = ColorFilter.mode(
          Colors.black.withValues(alpha: 0.18), BlendMode.darken),
  );
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.18));

  double yFor(double p) => r.top + r.height * (1 - p.clamp(0.0, 14.0) / 14.0);

  if (target != null) {
    final band =
        Rect.fromLTRB(r.left - 3, yFor(target + tol), r.right + 3, yFor(target - tol));
    canvas.drawRect(band, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawRect(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9));
  }

  // Neutral pH-7 dashed reference.
  final ny = yFor(7);
  final dash = Paint()
    ..color = Colors.white.withValues(alpha: emphasizeSeven ? 0.95 : 0.55)
    ..strokeWidth = emphasizeSeven ? 2.0 : 1.4;
  for (double x = r.left; x < r.right; x += 7) {
    canvas.drawLine(Offset(x, ny), Offset(x + 3.5, ny), dash);
  }
  _lgText(canvas, '7', Offset(r.left - 10, ny), 9,
      Colors.white.withValues(alpha: 0.8));
  _lgText(canvas, '14', Offset(r.left - 11, r.top + 5), 8,
      Colors.white.withValues(alpha: 0.55));
  _lgText(canvas, '0', Offset(r.left - 9, r.bottom - 5), 8,
      Colors.white.withValues(alpha: 0.55));

  // Current-pH marker arrow + needle line.
  final my = yFor(ph);
  final tri = Path()
    ..moveTo(r.left - 4, my)
    ..lineTo(r.left - 13, my - 5)
    ..lineTo(r.left - 13, my + 5)
    ..close();
  canvas.drawPath(tri, Paint()..color = _phColor(ph));
  canvas.drawLine(
      Offset(r.left, my),
      Offset(r.right, my),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2);
}

/// The beaker with universal-indicator liquid, wobble line, bubbles, glass rim,
/// pH readout and optional green hold ring — mirrors [_PhPainter._paintBeaker].
void _lgBeaker(Canvas canvas, Rect area,
    {required double ph, double holdFrac = 0}) {
  final bw = math.min(area.width, 150.0);
  final bh = math.min(area.height * 0.92, 190.0);
  if (bw <= 0 || bh <= 0) return;
  final glass = Rect.fromCenter(center: area.center, width: bw, height: bh);
  final rr = RRect.fromRectAndCorners(glass,
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
      topLeft: const Radius.circular(5),
      topRight: const Radius.circular(5));

  canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.03));

  // Liquid, colored by the indicator ramp.
  const fillFrac = 0.74;
  final liquidTopY = glass.bottom - glass.height * fillFrac;
  final liquid = _phColor(ph);
  canvas.save();
  canvas.clipRRect(rr);
  final liquidRect =
      Rect.fromLTRB(glass.left, liquidTopY, glass.right, glass.bottom);
  canvas.drawRect(
    liquidRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          liquid.withValues(alpha: 0.85),
          Color.lerp(liquid, Colors.black, 0.30)!.withValues(alpha: 0.95),
        ],
      ).createShader(liquidRect),
  );

  // Static surface wobble.
  final wobble = Path()..moveTo(glass.left, liquidTopY);
  for (double x = glass.left; x <= glass.right; x += 6) {
    wobble.lineTo(x, liquidTopY + math.sin(x / 14) * 1.6);
  }
  canvas.drawPath(
      wobble,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.30));

  // A few fixed bubbles.
  final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.30);
  const bubbleSpots = [
    Offset(0.30, 0.25),
    Offset(0.62, 0.55),
    Offset(0.45, 0.80),
    Offset(0.74, 0.30),
    Offset(0.22, 0.62),
  ];
  for (final b in bubbleSpots) {
    final bx = glass.left + glass.width * b.dx;
    final by = glass.bottom - (glass.bottom - liquidTopY) * b.dy;
    canvas.drawCircle(Offset(bx, by), 1.6 + b.dx * 2.4, bubblePaint);
  }
  canvas.restore();

  // Glass outline + rim.
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _kGlass.withValues(alpha: 0.55));
  canvas.drawLine(
      Offset(glass.left - 5, glass.top),
      Offset(glass.right + 5, glass.top),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _kGlass.withValues(alpha: 0.7));

  // Hold ring + readout, centered on the liquid.
  final center =
      Offset(glass.center.dx, liquidTopY + (glass.bottom - liquidTopY) * 0.46);
  final ringR = math.min(bw, bh) * 0.26;
  if (holdFrac > 0.01) {
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringR),
        -math.pi / 2,
        2 * math.pi * holdFrac.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = _kGood.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
  }
  _lgText(canvas, ph.toStringAsFixed(1), center, math.min(26.0, bw * 0.20),
      Colors.white);
  final tag = ph < 6.4 ? 'ACIDIC' : (ph > 7.6 ? 'BASIC' : 'NEUTRAL');
  _lgText(canvas, tag, center + Offset(0, ringR * 0.72), 9,
      Colors.white.withValues(alpha: 0.85));
}

/// One titration button (the game's ACID / BASE controls), canvas-drawn to
/// match [_DropButton]: tinted pill, border, chevron, label + formula line.
void _lgButton(Canvas canvas, Rect r,
    {required String label,
    required String sub,
    required Color color,
    required bool up}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.20));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.65));

  // Chevron arrow (up for BASE, down for ACID).
  final ac = Offset(r.center.dx - r.width * 0.28, r.center.dy - r.height * 0.14);
  final p = Paint()
    ..color = color
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  const s = 5.0;
  if (up) {
    canvas.drawLine(ac.translate(-s, s * 0.6), ac.translate(0, -s * 0.6), p);
    canvas.drawLine(ac.translate(s, s * 0.6), ac.translate(0, -s * 0.6), p);
  } else {
    canvas.drawLine(ac.translate(-s, -s * 0.6), ac.translate(0, s * 0.6), p);
    canvas.drawLine(ac.translate(s, -s * 0.6), ac.translate(0, s * 0.6), p);
  }

  _lgText(
      canvas,
      label,
      Offset(r.center.dx + r.width * 0.08, r.center.dy - r.height * 0.14),
      14,
      Potatuhs.textPrimary);
  _lgText(canvas, sub, Offset(r.center.dx, r.center.dy + r.height * 0.22), 10,
      color.withValues(alpha: 0.95), weight: FontWeight.w700);
}

// ── Frame 1: the beaker, the indicator scale, the target band ────────────────
void _legendTarget(Canvas canvas, Size size) {
  if (_lgDegenerate(size)) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);

  // TARGET readout with its color dot, like the in-game HUD.
  const target = 4.0;
  final ty = size.height * 0.10;
  canvas.drawCircle(Offset(size.width * 0.30, ty), 5,
      Paint()..color = _phColor(target));
  canvas.drawCircle(
      Offset(size.width * 0.30, ty),
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.6));
  _lgText(canvas, 'TARGET  pH 4.0', Offset(size.width * 0.52, ty), 12,
      Potatuhs.textPrimary);

  // Beaker (current pH 9.5, basic blue) + the strip showing the band to reach.
  _lgBeaker(
      canvas,
      Rect.fromLTRB(size.width * 0.06, size.height * 0.20, size.width * 0.66,
          size.height * 0.96),
      ph: 9.5);
  _lgStrip(
      canvas,
      Rect.fromLTWH(size.width * 0.80, size.height * 0.20,
          math.min(26.0, size.width * 0.09), size.height * 0.74),
      ph: 9.5,
      target: target);
}

// ── Frame 2: the verb — ACID and BASE drop buttons ───────────────────────────
void _legendDrops(Canvas canvas, Size size) {
  if (_lgDegenerate(size)) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);

  // Mini strip showing what each drop does to the marker.
  final strip = Rect.fromLTWH(size.width * 0.44, size.height * 0.08,
      math.min(24.0, size.width * 0.08), size.height * 0.44);
  _lgStrip(canvas, strip, ph: 7.0);
  final arrow = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  // Red arrow pulling the marker down (acid)…
  arrow.color = _kAcid;
  final ax = strip.left - size.width * 0.14;
  canvas.drawLine(Offset(ax, strip.top + strip.height * 0.42),
      Offset(ax, strip.top + strip.height * 0.78), arrow);
  canvas.drawLine(Offset(ax - 5, strip.top + strip.height * 0.68),
      Offset(ax, strip.top + strip.height * 0.78), arrow);
  canvas.drawLine(Offset(ax + 5, strip.top + strip.height * 0.68),
      Offset(ax, strip.top + strip.height * 0.78), arrow);
  // …blue arrow pushing it up (base).
  arrow.color = _kBase;
  final bx = strip.right + size.width * 0.14;
  canvas.drawLine(Offset(bx, strip.top + strip.height * 0.58),
      Offset(bx, strip.top + strip.height * 0.22), arrow);
  canvas.drawLine(Offset(bx - 5, strip.top + strip.height * 0.32),
      Offset(bx, strip.top + strip.height * 0.22), arrow);
  canvas.drawLine(Offset(bx + 5, strip.top + strip.height * 0.32),
      Offset(bx, strip.top + strip.height * 0.22), arrow);

  // The two real bottom buttons.
  final btnTop = size.height * 0.62;
  final btnH = size.height * 0.26;
  _lgButton(
      canvas,
      Rect.fromLTWH(size.width * 0.06, btnTop, size.width * 0.41, btnH),
      label: 'ACID',
      sub: 'H⁺  pH ▼',
      color: _kAcid,
      up: false);
  _lgButton(
      canvas,
      Rect.fromLTWH(size.width * 0.53, btnTop, size.width * 0.41, btnH),
      label: 'BASE',
      sub: 'OH⁻  pH ▲',
      color: _kBase,
      up: true);
}

// ── Frame 3: how to score — land in the band and hold it ─────────────────────
void _legendHold(Canvas canvas, Size size) {
  if (_lgDegenerate(size)) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);

  // Beaker sitting ON target (pH 4.0) with the green hold ring 3/4 full.
  _lgBeaker(
      canvas,
      Rect.fromLTRB(size.width * 0.06, size.height * 0.16, size.width * 0.66,
          size.height * 0.96),
      ph: 4.0,
      holdFrac: 0.75);
  // Strip: marker inside the white band.
  _lgStrip(
      canvas,
      Rect.fromLTWH(size.width * 0.80, size.height * 0.16,
          math.min(26.0, size.width * 0.09), size.height * 0.74),
      ph: 4.0,
      target: 4.0);

  // The score popup the hit fires.
  _lgText(canvas, '+70', Offset(size.width * 0.36, size.height * 0.10), 20,
      _kGood);
}

// ── Frame 4: the danger — the steep zone around pH 7 slings past the band ────
void _legendSteep(Canvas canvas, Size size) {
  if (_lgDegenerate(size)) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);

  // Strip with a near-neutral band; the neutral-7 line is the hot zone.
  final strip = Rect.fromLTWH(size.width * 0.60, size.height * 0.10,
      math.min(26.0, size.width * 0.09), size.height * 0.80);
  _lgStrip(canvas, strip, ph: 9.4, target: 6.4, tol: 0.7, emphasizeSeven: true);

  double yFor(double p) =>
      strip.top + strip.height * (1 - p.clamp(0.0, 14.0) / 14.0);

  // Red swing arc: one drop near 7 flings the needle from 5.6 clean past
  // the band to 9.4 — the overshoot that breaks the streak.
  final swing = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = _kBad;
  final x0 = strip.left - size.width * 0.10;
  final path = Path()
    ..moveTo(x0, yFor(5.6))
    ..quadraticBezierTo(
        x0 - size.width * 0.22, (yFor(5.6) + yFor(9.4)) / 2, x0, yFor(9.4));
  canvas.drawPath(path, swing);
  // Arrowhead at the flung end.
  canvas.drawLine(Offset(x0, yFor(9.4)), Offset(x0 - 9, yFor(9.4) + 3), swing);
  canvas.drawLine(Offset(x0, yFor(9.4)), Offset(x0 - 4, yFor(9.4) + 9), swing);

  _lgText(canvas, 'OVERSHOOT!', Offset(size.width * 0.26, yFor(9.4) - 16), 13,
      _kBad);
  _lgText(canvas, 'STREAK ✕', Offset(size.width * 0.26, yFor(9.4) + 4), 10,
      _kBad.withValues(alpha: 0.85), weight: FontWeight.w700);
  _lgText(canvas, 'steep near 7', Offset(size.width * 0.30, yFor(7.0)), 10,
      Colors.white.withValues(alpha: 0.75), weight: FontWeight.w700);
  _lgText(canvas, 'one drop', Offset(size.width * 0.26, yFor(5.6) + 14), 10,
      Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700);
}

/// The visual manual for pH Balance — wired into the registry spec.
final List<LegendFrame> phBalanceLegendFrames = [
  const LegendFrame(
      caption: 'Steer the beaker\'s pH onto the white target band',
      paint: _legendTarget),
  const LegendFrame(
      caption: 'Tap ACID (H⁺) to lower pH · BASE (OH⁻) to raise it',
      paint: _legendDrops),
  const LegendFrame(
      caption: 'Hold in the band till the green ring fills: +40',
      paint: _legendHold),
  const LegendFrame(
      caption: 'Drops swing hardest near pH 7 — don\'t overshoot',
      paint: _legendSteep),
];
