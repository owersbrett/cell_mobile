import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// NEPHRON v2 — run the kidney's filter (60 s, BioScale.organ), UX-passed.
///
/// SAME LESSON as v1: the tubule's default is "everything leaves in the urine,"
/// and *reabsorption is the active, selective step*. Doing nothing sends a
/// molecule to URINE — correct for waste, wrong for a nutrient. You REABSORB
/// nutrients (water, glucose, amino acids, needed ions) back to the BLOOD and
/// EXCRETE waste (urea, toxins, excess ions) to the URINE. It accelerates, adds
/// molecule types, and ends with the subtle Na⁺ vs Na⁺·EXCESS call.
///
/// WHAT CHANGED vs the original (full list in AGENT.md):
///   1. AFFORDANCE — the verb is now a REAL drag/flick. You grab a molecule and
///      physically sweep it LEFT (blood) or RIGHT (urine); a fast flick commits
///      by velocity, a slow drag commits by which side you let go on. v1 said
///      "FLICK" but routed by a static tap x-position with no gesture at all.
///   2. FAIRNESS — the `endEarly()` fail-out on zero BLOOD PURITY is GONE. Every
///      player rides the full 60 s, so standings are comparable. Purity is now a
///      tension gauge + a gentle catch-up (low purity slows the flow), never a
///      shorter clock.
///   3. SCAFFOLD — early game tags nutrients (green REABSORB aura) vs waste (red
///      hazard ✕) pre-attentively so a first-timer learns the categories; the
///      tell is stripped as the level climbs, ending on the read-the-label
///      EXCESS twist — exactly how the kidney discriminates surplus from need.
///   4. READABLE SCORE — a big in-widget score, a streak multiplier pill, and a
///      PURITY gauge; the number that decides the round never relies on chrome.
///   5. CLIMAX — the final 10 s become a red "FINAL FLUSH" surge (×1.5) with one
///      big final molecule beat, so the accelerate climbs to the buzzer.
///
/// PERFORMANCE: one [Ticker] → one [CustomPainter] via a repaint notifier. No
/// per-frame setState over a tree. Haptics are fire-and-forget (no-op on web).

// ─── Tuning ────────────────────────────────────────────────────────────────
const Color _kBlood = Color(0xFFE0556B); // peritubular capillary (reabsorb)
const Color _kUrine = Color(0xFFC8A23A); // collecting duct (excrete)
const Color _kGood = Color(0xFF6BD089); // scaffold: nutrient aura
const Color _kHazard = Color(0xFFFF5C5C); // scaffold: waste badge

const double _kSpawnEarly = 1.15; // s between spawns at t=0
const double _kSpawnPeak = 0.40; // s between spawns at t=duration
const double _kSpawnClimax = 0.26; // s between spawns during FINAL FLUSH
const double _kSpawnCurve = 1.35; // >1 = gentle start, steep late-game ramp
const double _kBurstOn = 0.40; // progress where cluster spawns begin
const double _kBurst3On = 0.75; // progress where triple clusters can appear
const double _kBurstChance = 0.45; // chance a spawn is a cluster once unlocked
const double _kFallEarly = 70.0; // px/s descent at t=0
const double _kFallPeak = 158.0; // px/s descent at t=duration
const double _kGrabRadius = 64.0; // grab pickup radius
const double _kMolR = 22.0; // molecule body radius
const int _kMaxDrops = 13;

const double _kFlickV = 320.0; // px/s pan velocity that counts as a flick
const double _kCommitZone = 0.10; // fraction of width past centre to commit

const int _kCorrect = 10; // base points for a correct call
const int _kMissWaste = 2; // waste that passively exits in urine
const int _kMaxMult = 4;

const double _kPurRegen = 0.045; // per correct call
const double _kPurWasteInBlood = 0.18; // keeping waste in blood (harshest)
const double _kPurLostNutrient = 0.10; // dumping a nutrient
const double _kPurMissNutrient = 0.06; // nutrient out the bottom unsorted

// ─── Molecule kinds ──────────────────────────────────────────────────────────
class _Mol {
  final String symbol; // drawn inside the orb
  final String name; // small label below (load-bearing for subtle calls)
  final bool waste; // true → belongs in urine
  final Color color;
  const _Mol(this.symbol, this.name, this.waste, this.color);
}

// Level 1 pool — clear calls, distinct colours.
const _goodBase = [
  _Mol('Glu', 'Glucose', false, Color(0xFFE1C916)),
  _Mol('H₂O', 'Water', false, Color(0xFF6FB7D6)),
  _Mol('AA', 'Amino acid', false, Color(0xFF8FD18A)),
  _Mol('Na⁺', 'Sodium', false, Color(0xFF63C2BE)),
];
const _wasteBase = [
  _Mol('Urea', 'Urea', true, Color(0xFFB07A4B)),
  _Mol('Cr', 'Creatinine', true, Color(0xFF9C6B5A)),
  _Mol('Tox', 'Toxin', true, Color(0xFFE05B5B)),
];

// Level 2 — more types.
const _goodL2 = [
  _Mol('K⁺', 'Potassium', false, Color(0xFF9DB86F)),
  _Mol('HCO₃', 'Bicarbonate', false, Color(0xFF7FB0C9)),
];
const _wasteL2 = [
  _Mol('UA', 'Uric acid', true, Color(0xFFC98A3A)),
  _Mol('NH₃', 'Ammonia', true, Color(0xFF8A9B5C)),
];

// Level 3+ — subtle calls. "Excess" sodium is identical in symbol AND colour to
// needed sodium; only the label gives it away — the kidney really does discard
// surplus ions while reabsorbing the amount the body needs.
const _subtleL3 = [
  _Mol('Na⁺', 'Sodium · EXCESS', true, Color(0xFF63C2BE)),
  _Mol('Rx', 'Drug metabolite', true, Color(0xFFB55BD0)),
];

List<_Mol> _poolFor(int level) {
  final p = <_Mol>[..._goodBase, ..._wasteBase];
  if (level >= 2) p.addAll([..._goodL2, ..._wasteL2]);
  if (level >= 3) p.addAll(_subtleL3);
  return p;
}

// ─── Live molecule ───────────────────────────────────────────────────────────
class _Drop {
  Offset pos;
  final _Mol mol;
  double wobble;
  final double scale; // the big final-beat molecule is larger
  bool held = false; // grabbed by the player's drag
  bool committed = false; // routed → zipping to a gutter
  int zipDir = 0; // -1 blood, +1 urine
  double zipT = 0; // 0→1 zip animation
  double targetX = 0;
  _Drop(this.pos, this.mol, this.wobble, {this.scale = 1.0});
  double get radius => _kMolR * scale;
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (the same orbs, tubule and gutters the live game uses).
// ═══════════════════════════════════════════════════════════════════════════

const Color _kLegendAccent = Color(0xFFC65A6E); // matches _NephronV2Painter

/// Draws one molecule orb in the live game's style: glowing orb + symbol +
/// name label, with the optional early-level scaffold tell (green ring for a
/// nutrient, red ✕ badge for waste).
void _legendMol(
  Canvas canvas,
  Offset c, {
  required _Mol mol,
  double scale = 1.0,
  bool scaffold = false,
}) {
  final r = _kMolR * scale;
  if (scaffold) {
    if (!mol.waste) {
      canvas.drawCircle(
        c,
        r + 7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kGood.withValues(alpha: 0.7),
      );
    } else {
      final bx = c.translate(r * 0.78, -r * 0.78);
      canvas.drawCircle(bx, 7, Paint()..color = _kHazard);
      final x = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(bx.translate(-2.6, -2.6), bx.translate(2.6, 2.6), x);
      canvas.drawLine(bx.translate(2.6, -2.6), bx.translate(-2.6, 2.6), x);
    }
  }
  GameFx.orb(canvas, c, r, mol.color, glow: 1.0);
  GameFx.text(canvas, mol.symbol, c, 12 * scale, Colors.white,
      weight: FontWeight.w800);
  GameFx.text(canvas, mol.name, c.translate(0, r + 9), 9,
      Potatuhs.textSecondary.withValues(alpha: 0.85),
      weight: FontWeight.w600);
}

/// Draws a vertical destination gutter (BLOOD on the left, URINE on the right).
void _legendGutter(Canvas canvas, Rect rect, Color c, String label,
    String arrow) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(10)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.withValues(alpha: 0.08), c.withValues(alpha: 0.30)],
      ).createShader(rect),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(10)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = c.withValues(alpha: 0.6),
  );
  GameFx.text(canvas, arrow, Offset(rect.center.dx, rect.center.dy - 12), 22,
      c, weight: FontWeight.w900);
  GameFx.text(canvas, label, Offset(rect.center.dx, rect.center.dy + 10), 11, c,
      weight: FontWeight.w800);
}

/// The central falling tubule.
void _legendTubuleRect(Canvas canvas, Rect rect) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kLegendAccent.withValues(alpha: 0.16),
          _kLegendAccent.withValues(alpha: 0.05),
        ],
      ).createShader(rect),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kLegendAccent.withValues(alpha: 0.45),
  );
}

/// Draws a small directional arrow from [a] to [b] (a routed molecule's path).
void _legendArrow(Canvas canvas, Offset a, Offset b, Color c) {
  final p = Paint()
    ..color = c
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(a, b, p);
  final dir = (b - a);
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);
  const head = 8.0;
  canvas.drawLine(b, b - u * head + n * head * 0.6, p);
  canvas.drawLine(b, b - u * head - n * head * 0.6, p);
}

// (a) The whole apparatus: tubule in the middle, BLOOD left, URINE right.
void _legendTubule(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  _legendGutter(canvas, Rect.fromLTWH(w * 0.04, h * 0.14, w * 0.20, h * 0.72),
      _kBlood, 'BLOOD', '◄');
  _legendGutter(canvas, Rect.fromLTWH(w * 0.76, h * 0.14, w * 0.20, h * 0.72),
      _kUrine, 'URINE', '►');
  _legendTubuleRect(
      canvas, Rect.fromLTWH(w * 0.32, h * 0.10, w * 0.36, h * 0.80));
  _legendMol(canvas, Offset(w * 0.5, h * 0.42), mol: _goodBase[0]);
}

// (b) A nutrient flicked LEFT → reabsorbed into the blood.
void _legendReabsorb(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  _legendGutter(canvas, Rect.fromLTWH(w * 0.04, h * 0.14, w * 0.22, h * 0.72),
      _kBlood, 'BLOOD', '◄');
  final from = Offset(w * 0.60, h * 0.50);
  final to = Offset(w * 0.30, h * 0.50);
  _legendArrow(canvas, from, to, _kGood);
  _legendMol(canvas, from, mol: _goodBase[0], scaffold: true);
}

// (c) Waste sent RIGHT → excreted to urine; a wrong call costs blood purity.
void _legendExcrete(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  _legendGutter(canvas, Rect.fromLTWH(w * 0.74, h * 0.10, w * 0.22, h * 0.60),
      _kUrine, 'URINE', '►');
  final from = Offset(w * 0.40, h * 0.38);
  final to = Offset(w * 0.70, h * 0.38);
  _legendArrow(canvas, from, to, _kHazard);
  _legendMol(canvas, from, mol: _wasteBase[0], scaffold: true);

  // Blood-purity gauge cost of a wrong call.
  const barW = 150.0, barH = 9.0;
  final bx = (w - barW) / 2, by = h * 0.82;
  if (barW <= 0) return;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, barW, barH), const Radius.circular(5)),
    Paint()..color = Colors.black.withValues(alpha: 0.45),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, barW * 0.45, barH), const Radius.circular(5)),
    Paint()..color = _kBlood,
  );
  GameFx.text(canvas, 'WRONG CALL DROPS BLOOD PURITY',
      Offset(w / 2, by - 10), 9, Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

// (d) The SURGE — clusters of 2–3 arrive together as the round accelerates.
void _legendSurge(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  _legendTubuleRect(
      canvas, Rect.fromLTWH(w * 0.20, h * 0.08, w * 0.60, h * 0.84));
  // A staggered wave of three molecules, no scaffold (late-game tell stripped).
  _legendMol(canvas, Offset(w * 0.36, h * 0.30), mol: _goodBase[1], scale: 0.85);
  _legendMol(canvas, Offset(w * 0.60, h * 0.44), mol: _wasteBase[0], scale: 0.85);
  _legendMol(canvas, Offset(w * 0.44, h * 0.62), mol: _subtleL3[0], scale: 0.85);
  GameFx.text(canvas, 'SURGE!', Offset(w / 2, h * 0.86), 14, _kBlood,
      weight: FontWeight.w900);
}

/// The visual manual for Nephron — wired into the registry spec.
final List<LegendFrame> nephronLegendFrames = [
  const LegendFrame(
      caption: 'Molecules fall the tubule: BLOOD left, URINE right',
      paint: _legendTubule),
  const LegendFrame(
      caption: 'Flick a nutrient LEFT to reabsorb it into the blood',
      paint: _legendReabsorb),
  const LegendFrame(
      caption: 'Send waste RIGHT to urine — wrong calls drop purity',
      paint: _legendExcrete),
  const LegendFrame(
      caption: 'SURGE: clusters arrive fast — read labels, no color tell',
      paint: _legendSurge),
];

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class NephronV2Game extends StatefulWidget {
  final MiniGameSession session;
  const NephronV2Game({super.key, required this.session});

  @override
  State<NephronV2Game> createState() => _NephronV2GameState();
}

class _NephronV2GameState extends State<NephronV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  bool _ready = false;
  bool _wasRunning = false;

  double _time = 0;
  Duration _last = Duration.zero;

  final List<_Drop> _drops = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _spawnTimer = 0;
  double _purity = 1.0; // 0..1 tension gauge (never ends the round)
  int _streak = 0;
  double _flash = 0; // red flash on a bad call
  double _flashGood = 0; // green flash on a good call
  double _shake = 0; // screen shake on the worst call

  _Drop? _held; // molecule currently under the finger
  bool _climaxHit = false; // one-shot FINAL FLUSH announce
  bool _finalBeat = false; // one-shot big final molecule
  bool _surgeHit = false; // one-shot cluster-spawn announce

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── Attract autopilot ────────────────────────────────────────────────────────
  // One competent move per call: route the most urgent (lowest, closest to the
  // exit) actionable molecule the correct way — nutrient back to BLOOD, waste to
  // URINE — via the game's own [_route]. No randomness, no synthetic gestures.
  void _autoStep() {
    if (!widget.session.isRunning || !_ready) return;
    _Drop? target;
    for (final d in _drops) {
      if (d.committed || d.held) continue;
      // Most urgent = furthest down; ties keep the first encountered.
      if (target == null || d.pos.dy > target.pos.dy) target = d;
    }
    if (target == null) return;
    // Nutrient (good) → blood (dir -1); waste → urine (dir +1).
    _route(target, target.mol.waste ? 1 : -1);
  }

  // ─── Geometry ─────────────────────────────────────────────────────────────
  double get _tubuleLeft => _size.width * 0.27;
  double get _tubuleRight => _size.width * 0.73;
  double get _bloodX => _size.width * 0.12;
  double get _urineX => _size.width * 0.88;
  double get _spawnY => _size.height * 0.15;
  double get _exitY => _size.height * 0.92;

  // ─── Progress / difficulty ──────────────────────────────────────────────────
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final elapsed = dur - widget.session.remaining.inMilliseconds / 1000.0;
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  int get _level => (1 + (_progress * 5)).floor().clamp(1, 5);

  /// Scaffolding (the friend/foe tell) is on at low levels, stripped from L3 up.
  bool get _scaffold => _level <= 2;

  int get _mult => (1 + _streak ~/ 4).clamp(1, _kMaxMult);

  bool get _isClimax =>
      widget.session.isRunning && widget.session.remaining.inSeconds <= 10;

  // ─── Tick ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (_ready) {
      if (running) {
        _update(dt);
      } else {
        _idle(dt);
      }
    }
    _repaint.tick();
  }

  void _startRun() {
    _drops.clear();
    _particles.clear();
    _pops.clear();
    _spawnTimer = 0.4;
    _purity = 1.0;
    _streak = 0;
    _flash = 0;
    _flashGood = 0;
    _shake = 0;
    _held = null;
    _climaxHit = false;
    _finalBeat = false;
    _surgeHit = false;
  }

  // Calm ready/finished state: a few molecules drift gently, nothing scores.
  void _idle(double dt) {
    if (_drops.length < 5 && _rng.nextDouble() < dt * 0.8) {
      _drops.add(_Drop(
        Offset(_tubuleLeft + _rng.nextDouble() * (_tubuleRight - _tubuleLeft),
            _spawnY - 30),
        _poolFor(1)[_rng.nextInt(_poolFor(1).length)],
        _rng.nextDouble() * math.pi * 2,
      ));
    }
    for (final d in _drops) {
      d.wobble += dt * 1.5;
      d.pos = Offset(d.pos.dx, d.pos.dy + 26 * dt);
    }
    _drops.removeWhere((d) => d.pos.dy > _exitY + 20);
    _stepFx(dt);
  }

  void _update(double dt) {
    final session = widget.session;
    final progress = _progress;

    // Effect-timer decay.
    if (_flash > 0) _flash = math.max(0, _flash - dt * 1.6);
    if (_flashGood > 0) _flashGood = math.max(0, _flashGood - dt * 2.2);
    if (_shake > 0) _shake = math.max(0, _shake - dt * 6);

    // FINAL FLUSH one-shots.
    if (_isClimax && !_climaxHit) {
      _climaxHit = true;
      _pops.add(FxPop(Offset(_size.width / 2, _size.height * 0.34),
          'FINAL FLUSH!', _kUrine));
      HapticFeedback.mediumImpact();
    }
    if (!_finalBeat && session.remaining.inMilliseconds <= 2600) {
      _finalBeat = true;
      _spawnBigFinal();
    }

    // Catch-up: low purity gently slows the flow (a hand, not a shorter clock).
    final calm = (1.0 - _purity).clamp(0.0, 1.0);
    final fall = (_kFallEarly + (_kFallPeak - _kFallEarly) * progress) *
        (1.0 - 0.20 * calm);
    // Eased ramp: gentle early, steep late (the escalating-to-impossible law).
    final baseInterval = _isClimax
        ? _kSpawnClimax
        : _kSpawnEarly +
            (_kSpawnPeak - _kSpawnEarly) *
                math.pow(progress, _kSpawnCurve).toDouble();
    final interval = baseInterval * (1.0 + 0.30 * calm);

    // One-shot cue the moment cluster spawns unlock, so the shift is taught,
    // not sprung.
    if (!_surgeHit && progress >= _kBurstOn) {
      _surgeHit = true;
      _pops.add(FxPop(
          Offset(_size.width / 2, _size.height * 0.34), 'SURGE!', _kBlood));
      HapticFeedback.lightImpact();
    }

    // Spawn — singles early; once the shift heats up, clusters of 2 (then 3)
    // arrive together as a wave.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _drops.length < _kMaxDrops) {
      var burst = 1;
      if (progress >= _kBurstOn && _rng.nextDouble() < _kBurstChance) {
        burst = (progress >= _kBurst3On && _rng.nextBool()) ? 3 : 2;
      }
      burst = math.min(burst, _kMaxDrops - _drops.length);
      // A cluster buys a slightly longer beat before the next wave.
      _spawnTimer = interval *
          (0.8 + _rng.nextDouble() * 0.4) *
          (burst > 1 ? 1.35 : 1.0);
      final pool = _poolFor(_level);
      final span = _tubuleRight - _tubuleLeft - 32;
      for (var i = 0; i < burst; i++) {
        // Spread cluster members across the tubule and stagger their entry
        // heights so they read as a wave, not one overlapping blob.
        final fx = burst == 1
            ? _rng.nextDouble()
            : (i + 0.15 + _rng.nextDouble() * 0.7) / burst;
        _drops.add(_Drop(
          Offset(_tubuleLeft + 16 + fx * span,
              _spawnY - 24 - i * (_kMolR * 2.2)),
          pool[_rng.nextInt(pool.length)],
          _rng.nextDouble() * math.pi * 2,
        ));
      }
    }

    // Advance drops.
    _drops.removeWhere((d) {
      d.wobble += dt * 3.2;
      if (d.held) {
        return false; // a held molecule is frozen under the finger
      }
      if (d.committed) {
        d.zipT += dt * 3.4;
        d.pos = Offset(
          _lerp(d.pos.dx, d.targetX, (dt * 9).clamp(0.0, 1.0)),
          d.pos.dy + fall * 0.25 * dt,
        );
        return d.zipT >= 1.0;
      }
      d.pos = Offset(d.pos.dx, d.pos.dy + fall * dt);
      // Reached the bottom unsorted → passively exits in URINE.
      if (d.pos.dy >= _exitY) {
        if (d.mol.waste) {
          session.addScore(_kMissWaste);
          _pops.add(FxPop(d.pos, '+$_kMissWaste', _kUrine.withValues(alpha: 0.9)));
        } else {
          _streak = 0;
          _purity = (_purity - _kPurMissNutrient).clamp(0.0, 1.0);
          _flash = 0.45;
          _pops.add(FxPop(d.pos, 'LOST', _kBlood));
        }
        return true;
      }
      return false;
    });

    _stepFx(dt);
  }

  void _stepFx(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _spawnBigFinal() {
    // A single big, slow nutrient as the closing beat — a clean prize to land.
    _drops.add(_Drop(
      Offset(_size.width * 0.5, _spawnY - 30),
      _goodBase[0], // Glucose
      _rng.nextDouble() * math.pi * 2,
      scale: 1.6,
    ));
  }

  // ─── Routing (the sort) ─────────────────────────────────────────────────────
  void _route(_Drop d, int dir) {
    final session = widget.session;
    d.held = false;
    d.committed = true;
    d.zipDir = dir;
    d.zipT = 0;
    d.targetX = dir < 0 ? _bloodX : _urineX;
    final toBlood = dir < 0;
    final good = !d.mol.waste;

    int gain = _kCorrect * _mult;
    if (_isClimax) gain = (gain * 1.5).round();
    if (d.scale > 1.3) gain *= 2; // the big final beat pays double

    if ((toBlood && good) || (!toBlood && !good)) {
      // Correct call (reabsorb a nutrient, or excrete waste).
      session.addScore(gain);
      _streak++;
      session.noteStreak(_streak);
      _purity = (_purity + _kPurRegen).clamp(0.0, 1.0);
      _flashGood = 0.5;
      final col = toBlood ? _kBlood : _kUrine;
      final tag = _mult > 1 ? '+$gain ×$_mult' : '+$gain';
      _pops.add(FxPop(d.pos, tag, col));
      _particles.addAll(FxBurst.spawn(d.pos, d.mol.color, count: 12, speed: 110));
      HapticFeedback.lightImpact();
    } else if (toBlood && !good) {
      // Waste kept in the blood — the worst call. NO negative score (fair):
      // the streak breaks and purity drops, a readable punish.
      _streak = 0;
      _purity = (_purity - _kPurWasteInBlood).clamp(0.0, 1.0);
      _flash = 0.6;
      _shake = 1.0;
      _pops.add(FxPop(d.pos, 'WASTE IN BLOOD', _kBlood));
      _particles.addAll(FxBurst.spawn(d.pos, _kBlood, count: 16, speed: 150));
      HapticFeedback.heavyImpact();
    } else {
      // Nutrient dumped to urine.
      _streak = 0;
      _purity = (_purity - _kPurLostNutrient).clamp(0.0, 1.0);
      _flash = 0.5;
      _pops.add(FxPop(d.pos, 'NUTRIENT LOST', _kUrine));
      _particles.addAll(FxBurst.spawn(d.pos, _kUrine, count: 14, speed: 130));
      HapticFeedback.mediumImpact();
    }
  }

  // ─── Gesture: a REAL drag/flick (grab → sweep → release) ─────────────────────
  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    final p = d.localPosition;
    _Drop? best;
    double bestD = _kGrabRadius;
    for (final drop in _drops) {
      if (drop.committed || drop.held) continue;
      final dist = (drop.pos - p).distance;
      if (dist < bestD) {
        bestD = dist;
        best = drop;
      }
    }
    if (best != null) {
      best.held = true;
      _held = best;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final held = _held;
    if (held == null) return;
    // Direct manipulation: the molecule follows the finger inside the canvas.
    final p = d.localPosition;
    held.pos = Offset(
      p.dx.clamp(0.0, _size.width),
      p.dy.clamp(_spawnY - 30, _exitY),
    );
  }

  void _onPanEnd(DragEndDetails d) {
    final held = _held;
    _held = null;
    if (held == null) return;
    held.held = false;
    if (!widget.session.isRunning) return;

    final vx = d.velocity.pixelsPerSecond.dx;
    final center = _size.width / 2;
    final zone = _size.width * _kCommitZone;
    int dir = 0;
    if (vx < -_kFlickV) {
      dir = -1; // fast flick left → blood
    } else if (vx > _kFlickV) {
      dir = 1; // fast flick right → urine
    } else if (held.pos.dx < center - zone) {
      dir = -1; // released on the blood side
    } else if (held.pos.dx > center + zone) {
      dir = 1; // released on the urine side
    }
    // dir == 0 → released in the centre with no flick: drop keeps falling.
    if (dir != 0) _route(held, dir);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if ((_size.width - size.width).abs() > 1 ||
          (_size.height - size.height).abs() > 1) {
        _size = size;
      }
      _ready = _size.width > 0 && _size.height > 0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _NephronV2Painter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _NephronV2Painter extends CustomPainter {
  final _NephronV2GameState state;
  _NephronV2Painter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  static const _accent = Color(0xFFC65A6E);

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._ready) return;
    final t = state._time;
    final running = state.widget.session.isRunning;
    final climax = state._isClimax;

    // Screen shake on the worst call.
    final shake = state._shake;
    if (shake > 0) {
      canvas.save();
      canvas.translate(math.sin(t * 90) * shake * 5, math.cos(t * 80) * shake * 4);
    }

    GameFx.atmosphere(canvas, size, climax ? _kUrine : _accent, t, motes: 22);
    _paintGutters(canvas, size, t, climax);
    _paintTubule(canvas, size, t);
    _paintGlomerulus(canvas, size, t);

    for (final d in state._drops) {
      _paintDrop(canvas, d, t, running);
    }
    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    if (shake > 0) canvas.restore();

    if (climax) _paintClimaxVignette(canvas, size, t);
    _paintHud(canvas, size);

    // Bad/good call screen flash.
    if (state._flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBlood.withValues(alpha: 0.16 * state._flash));
    }
    if (state._flashGood > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: 0.10 * state._flashGood));
    }

    if (!running) _paintReady(canvas, size, t);
  }

  // ── Left blood vessel / right urine duct gutters ─────────────────────────────
  void _paintGutters(Canvas canvas, Size size, double t, bool climax) {
    void gutter(double cx, Color c, String label, String arrow, bool down,
        double intensity) {
      final rect = Rect.fromLTWH(
          cx - size.width * 0.13, 0, size.width * 0.26, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.withValues(alpha: 0.05 * intensity),
              c.withValues(alpha: 0.24 * intensity),
            ],
          ).createShader(rect),
      );
      // flow streaks
      final p = Paint()
        ..color = c.withValues(alpha: 0.16 * intensity)
        ..strokeWidth = 2;
      for (var i = 0; i < 7; i++) {
        final phase = (t * 40 + i * 90) % size.height;
        final y = down ? phase : size.height - phase;
        canvas.drawLine(Offset(cx - 10, y), Offset(cx + 10, y + 14), p);
      }
      GameFx.text(canvas, arrow, Offset(cx, size.height * 0.5 - 16), 26,
          c.withValues(alpha: 0.9), weight: FontWeight.w900);
      GameFx.text(canvas, label, Offset(cx, size.height * 0.5 + 8), 13,
          c.withValues(alpha: 0.9), weight: FontWeight.w800);
    }

    // The BLOOD gutter dims as purity falls — the tension reads on the vessel.
    final bloodInt = (0.45 + 0.55 * state._purity).clamp(0.0, 1.0);
    gutter(state._bloodX, _kBlood, 'BLOOD', '◄', false, bloodInt);
    gutter(state._urineX, _kUrine, 'URINE', '►', true, climax ? 1.2 : 1.0);
  }

  // ── Central nephron tubule with downward blood flow ──────────────────────────
  void _paintTubule(Canvas canvas, Size size, double t) {
    final l = state._tubuleLeft, r = state._tubuleRight;
    final rect = Rect.fromLTRB(l, size.height * 0.10, r, size.height * 0.97);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withValues(alpha: 0.14),
            _accent.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _accent.withValues(alpha: 0.45),
    );
    // Flowing plasma stripes.
    canvas.save();
    canvas.clipRRect(rr);
    final flow = Paint()..color = Colors.white.withValues(alpha: 0.045);
    for (var i = 0; i < 14; i++) {
      final y = (t * 70 + i * (size.height / 14)) % (size.height + 40) +
          size.height * 0.10 - 20;
      canvas.drawRect(Rect.fromLTWH(l, y, r - l, 6), flow);
    }
    canvas.restore();
  }

  void _paintGlomerulus(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.5, size.height * 0.095);
    // Softer, tighter filtration rings — suggest the capillary tuft without
    // shouting. Fewer rings, smaller radii, lower alpha that fades outward.
    for (var i = 0; i < 3; i++) {
      final rad = 7.0 + i * 3.0; // 7 · 10 · 13 (was up to 23)
      canvas.drawCircle(
        c.translate(math.sin(t + i) * 1.4, 0),
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _kBlood.withValues(alpha: 0.34 - i * 0.07),
      );
    }
    GameFx.orb(canvas, c, 6, _kBlood, glow: 1.0);
    // Label sits clear ABOVE the rings (outer ring ≈ 13px) with real air.
    GameFx.text(canvas, 'GLOMERULUS', c.translate(0, -26), 9.5,
        Potatuhs.textSecondary.withValues(alpha: 0.85),
        weight: FontWeight.w700);
  }

  // ── A molecule ───────────────────────────────────────────────────────────────
  void _paintDrop(Canvas canvas, _Drop d, double t, bool running) {
    final wob = d.held
        ? Offset.zero
        : Offset(math.sin(d.wobble) * 2.2, math.cos(d.wobble * 0.8) * 1.4);
    final pos = d.pos + wob;
    var alpha = 1.0;
    var r = d.radius;
    if (d.committed) {
      alpha = (1.0 - d.zipT).clamp(0.0, 1.0);
      r = d.radius * (1.0 - 0.3 * d.zipT);
    }
    if (!running) alpha *= 0.6;

    final good = !d.mol.waste;
    final scaffold = state._scaffold && running;

    // Held → bright selection ring so the grabbed molecule reads clearly, plus
    // a live direction hint that lights the side you are about to commit to.
    if (d.held) {
      canvas.drawCircle(
        pos,
        r + 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Potatuhs.textPrimary.withValues(alpha: 0.85),
      );
      final center = state._size.width / 2;
      final side = d.pos.dx < center ? _kBlood : _kUrine;
      canvas.drawCircle(
        pos,
        r + 16,
        Paint()
          ..color = side.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // SCAFFOLD (early levels only): a pre-attentive friend/foe tell that the
    // higher levels strip, ending on the read-the-label EXCESS twist.
    if (scaffold && !d.committed) {
      if (good) {
        final pulse = 0.5 + 0.5 * math.sin(t * 4 + d.wobble);
        canvas.drawCircle(
            pos,
            r + 6 + pulse * 2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = _kGood.withValues(alpha: (0.3 + 0.4 * pulse) * alpha));
      } else {
        // Hazard ✕ badge top-right: "this one goes to urine".
        final bx = pos.translate(r * 0.78, -r * 0.78);
        canvas.drawCircle(bx, 7, Paint()..color = _kHazard.withValues(alpha: alpha));
        final x = Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(bx.translate(-2.6, -2.6), bx.translate(2.6, 2.6), x);
        canvas.drawLine(bx.translate(2.6, -2.6), bx.translate(-2.6, 2.6), x);
      }
    }

    // Urgency ring near the bottom.
    if (!d.committed && !d.held && running && d.pos.dy > state._exitY - 90) {
      canvas.drawCircle(
        pos,
        r + 6 + 2 * math.sin(t * 9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kBlood.withValues(alpha: 0.5),
      );
    }

    GameFx.orb(canvas, pos, r, d.mol.color.withValues(alpha: alpha), glow: alpha);
    GameFx.text(canvas, d.mol.symbol, pos, 12 * d.scale,
        Colors.white.withValues(alpha: alpha),
        weight: FontWeight.w800);
    // Label below — load-bearing for the subtle "EXCESS" calls.
    GameFx.text(canvas, d.mol.name, pos.translate(0, r + 9), 9,
        Potatuhs.textSecondary.withValues(alpha: 0.85 * alpha),
        weight: FontWeight.w600);
  }

  // ── HUD: purity gauge + level/multiplier ─────────────────────────────────────
  // The live score lives in the host's top bar ("N molecules") — no in-canvas
  // stamp here, so the tube entry (glomerulus + label) reads clean. Transient
  // +N pops near scoring events carry the juice.
  void _paintHud(Canvas canvas, Size size) {
    final running = state.widget.session.isRunning;

    // Blood-purity gauge (bottom-left). A tension gauge — NOT a clock.
    const barW = 150.0, barH = 9.0;
    final bx = 16.0, by = size.height - 30.0;
    final bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, barW, barH), const Radius.circular(5));
    canvas.drawRRect(bg, Paint()..color = Colors.black.withValues(alpha: 0.45));
    final fillW = barW * state._purity.clamp(0.0, 1.0);
    final hue = Color.lerp(_kBlood, _kGood, state._purity)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, fillW, barH), const Radius.circular(5)),
      Paint()..color = hue,
    );
    GameFx.text(canvas, 'BLOOD PURITY', Offset(bx + barW / 2, by - 9), 9,
        Potatuhs.textSecondary,
        weight: FontWeight.w700);

    // Level + streak multiplier (bottom-right).
    if (running) {
      final mult = state._mult;
      final label = 'LV${state._level}'
          '${mult > 1 ? '   ×$mult' : ''}';
      GameFx.text(canvas, label, Offset(size.width - 60, by + 4), 13,
          mult > 1 ? Potatuhs.gold : Potatuhs.textSecondary,
          weight: FontWeight.w800, glow: mult > 1 ? 0.5 : 0);
    }
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
            _kUrine.withValues(alpha: 0.0),
            _kUrine.withValues(alpha: 0.04 + 0.06 * pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  // ── Calm ready / finished overlay ────────────────────────────────────────────
  void _paintReady(Canvas canvas, Size size, double t) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.34));
    final cx = size.width / 2;
    GameFx.text(canvas, 'NEPHRON', Offset(cx, size.height * 0.36), 34,
        Potatuhs.textPrimary,
        display: true, glow: 0.4);
    GameFx.text(canvas, 'Reabsorb the good · let waste pass',
        Offset(cx, size.height * 0.36 + 30), 13, Potatuhs.textSecondary,
        weight: FontWeight.w600);

    // The verb, spelled out as a real gesture with directional cues.
    final pulse = 0.5 + 0.5 * math.sin(t * 2.4);
    GameFx.text(canvas, '◄ DRAG / FLICK to BLOOD     URINE to FLICK / DRAG ►',
        Offset(cx, size.height * 0.36 + 56), 11,
        Potatuhs.textFaint.withValues(alpha: 0.6 + 0.4 * pulse),
        weight: FontWeight.w700);
    GameFx.text(
        canvas,
        'Green ring = nutrient (keep) · red ✕ = waste (excrete)',
        Offset(cx, size.height * 0.36 + 78), 10.5,
        Potatuhs.textSecondary.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _NephronV2Painter oldDelegate) => false;
}
