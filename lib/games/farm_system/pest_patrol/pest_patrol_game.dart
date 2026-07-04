import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Pest Patrol — Integrated Pest Management (BioScale.farmSystem / Hot Potato)
//
// CONTRACT: PestPatrolGame(session: session). The MiniGameHost owns the clock,
// countdown, score HUD and results; this widget only simulates the field,
// reports points via session.addScore / session.noteStreak, and gates all play
// on session.isRunning. While the host counts down (not yet running) the field
// renders a calm, near-still preview.
//
// MECHANIC: control pests with the RIGHT BENEFICIAL species instead of nuking
// the field. Pick a predator (ladybug / lacewing / bird) and release it onto a
// matching pest (aphid / mite / caterpillar). The pesticide button clears every
// pest instantly BUT also kills your beneficials + pollinators and breeds
// resistance — so leaning on it backfires across the round. Score = crop health
// preserved (a per-second dividend) + smart predator kills; resistance from
// spraying shrinks the dividend, so low spray use scores best.
//
// RENDERING: one Ticker → one CustomPainter (the "harvest lesson"). No
// per-entity widgets, capped entity/particle counts, no per-frame setState over
// a big tree — the painter repaints off a ChangeNotifier.
// ---------------------------------------------------------------------------

// ---- feel constants --------------------------------------------------------

const double _kBarH = 74.0; // predator/spray selection bar (bottom)
const double _kCropRowH = 58.0; // crop band the pests nibble at

// Pests
const int _kPestMaxAlive = 28; // headroom for descending swarms
const double _kPestSpeedBase = 34.0; // px/s downward at t=0
const double _kPestSpeedScale = 2.3; // ×base at t=duration
const double _kPestSwayAmp = 16.0;
const double _kPestNibble = 0.085; // crop-health/sec while at the crops
const double _kPestRadius = 12.0;
const double _kSpawnBase = 1.2; // seconds between trickle spawns at t=0
const double _kSpawnMin = 0.32; // at t=duration

// Swarms — clustered waves that descend together (the real pressure).
const double _kSwarmFirstDelay = 4.5; // grace before the first wave
const double _kSwarmIntervalMax = 7.0; // seconds between waves at t=0
const double _kSwarmIntervalMin = 3.2; // at t=duration
const int _kSwarmSizeMin = 3; // pests per wave at t=0
const int _kSwarmSizeMax = 8; // at t=duration

// Beneficials (released predators)
const int _kBenMaxAlive = 8;
const double _kBenSpeed = 230.0;
const double _kBenLife = 5.0;
const double _kBenEatRadius = 24.0;
const double _kDeployCooldown = 1.05; // summoning is a rationed, deliberate act

// Pollinators (bees) — purely there to be harmed by pesticide
const int _kPollinatorCount = 4;

// Crop health
const double _kCropRegen = 0.018; // /sec when no pest is feeding
const double _kHealthDividend = 5.0; // score/sec at full health, zero resistance
const double _kPollinatorDividend = 1.6; // score/sec per live bee (× 1-resistance)

// Pesticide spray
const int _kSprayPenalty = 22;
const double _kSprayResistance = 0.18;
const double _kSprayCooldown = 2.6;
const double _kResistanceMax = 0.85;
const double _kResistanceDecay = 0.02; // /sec
const int _kBenLostPenalty = 4; // per beneficial killed by spray

// Scoring
const int _kSmartKill = 12;
const int _kComboMax = 6;

// ---- palette ---------------------------------------------------------------
const Color _kAccent = Color(0xFF8BC34A); // leaf green (spec accent)
const Color _kSkyTop = Color(0xFF12230F);
const Color _kSkyHorizon = Color(0xFF35400F);
const Color _kSoilTop = Color(0xFF4A2A0E);
const Color _kSoilBot = Color(0xFF26150A);
const Color _kCropHealthy = Color(0xFF6FBF4A);
const Color _kCropSick = Color(0xFF8A5A1E);
const Color _kBarBg = Color(0xEE15120F);
const Color _kAphid = Color(0xFF9CCC65); // green sap-sucker
const Color _kMite = Color(0xFFEF5350); // red spider mite
const Color _kCaterpillar = Color(0xFFFFCA28); // amber chewer
const Color _kLadybug = Color(0xFFE53935);
const Color _kLacewing = Color(0xFF80DEEA);
const Color _kBird = Color(0xFF7986CB);
const Color _kPollinator = Color(0xFFFFD54F);
const Color _kDanger = Color(0xFFE53935);
const Color _kResistance = Color(0xFFFF7043);

// ---- kinds + matching ------------------------------------------------------

enum _PestType { aphid, mite, caterpillar }

enum _BenType { ladybug, lacewing, bird }

/// The biocontrol pairing the game teaches: each beneficial counters one pest.
_PestType _prey(_BenType b) {
  switch (b) {
    case _BenType.ladybug:
      return _PestType.aphid;
    case _BenType.lacewing:
      return _PestType.mite;
    case _BenType.bird:
      return _PestType.caterpillar;
  }
}

/// Inverse of [_prey]: the correct beneficial to release on a given pest. Used
/// by the ATTRACT autopilot so it only ever makes matching (never-spray) moves.
_BenType _counter(_PestType p) {
  switch (p) {
    case _PestType.aphid:
      return _BenType.ladybug;
    case _PestType.mite:
      return _BenType.lacewing;
    case _PestType.caterpillar:
      return _BenType.bird;
  }
}

Color _pestColor(_PestType t) {
  switch (t) {
    case _PestType.aphid:
      return _kAphid;
    case _PestType.mite:
      return _kMite;
    case _PestType.caterpillar:
      return _kCaterpillar;
  }
}

Color _benColor(_BenType t) {
  switch (t) {
    case _BenType.ladybug:
      return _kLadybug;
    case _BenType.lacewing:
      return _kLacewing;
    case _BenType.bird:
      return _kBird;
  }
}

String _benGlyph(_BenType t) {
  switch (t) {
    case _BenType.ladybug:
      return '🐞';
    case _BenType.lacewing:
      return '🦗';
    case _BenType.bird:
      return '🐦';
  }
}

String _benName(_BenType t) {
  switch (t) {
    case _BenType.ladybug:
      return 'LADYBUG';
    case _BenType.lacewing:
      return 'LACEWING';
    case _BenType.bird:
      return 'BIRD';
  }
}

// ---- data classes ----------------------------------------------------------

class _Pest {
  double x, y;
  final _PestType type;
  final double seed;
  bool dead = false;
  double deathAge = 0;
  double feeding = 0; // 0..1 settle as it reaches the crops
  _Pest(this.x, this.y, this.type, this.seed);
}

class _Ben {
  double x, y;
  final _BenType type;
  double age = 0;
  int eaten = 0;
  final double seed;
  bool leaving = false;
  _Ben(this.x, this.y, this.type, this.seed);
}

class _Bee {
  double x, y;
  double phase;
  bool dead = false;
  double deathAge = 0;
  _Bee(this.x, this.y, this.phase);
}

class _Popup {
  double x, y, age = 0;
  final String text;
  final Color color;
  final double scale;
  _Popup(this.x, this.y, this.text, this.color, {this.scale = 1.0});
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ===========================================================================
// Visual manual — the legend carousel cards. Each frame draws the LITERAL
// in-game components (the same pests, beneficials, crops and spray button the
// player meets) using this game's own constants + palette, so the intro shows
// the real thing rather than an abstract diagram. Cheap + static: no ticker,
// no state, size-guarded against degenerate boxes.
// ===========================================================================

/// A pest orb with legs and its type tell — mirrors `_drawPest`.
void _legPest(Canvas canvas, Offset c, _PestType type,
    {double r = _kPestRadius, double alpha = 1.0}) {
  final color = _pestColor(type).withValues(alpha: alpha);
  final leg = Paint()
    ..color = Colors.black.withValues(alpha: 0.45 * alpha)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (var i = -1; i <= 1; i++) {
    canvas.drawLine(Offset(c.dx - r * 0.5, c.dy + i * 3),
        Offset(c.dx - r - 3, c.dy + i * 4), leg);
    canvas.drawLine(Offset(c.dx + r * 0.5, c.dy + i * 3),
        Offset(c.dx + r + 3, c.dy + i * 4), leg);
  }
  GameFx.orb(canvas, c, r, color, glow: 0.5 * alpha);
  if (type == _PestType.caterpillar) {
    for (var k = 1; k <= 2; k++) {
      canvas.drawCircle(Offset(c.dx, c.dy - k * 6.0), r * (0.8 - k * 0.12),
          Paint()..color = color);
    }
  } else if (type == _PestType.mite) {
    final eye = Paint()..color = Colors.white.withValues(alpha: 0.85 * alpha);
    canvas.drawCircle(Offset(c.dx - 3, c.dy - 2), 1.6, eye);
    canvas.drawCircle(Offset(c.dx + 3, c.dy - 2), 1.6, eye);
  }
}

/// A released beneficial (emoji + hunting halo) — mirrors `_drawBen`.
void _legBen(Canvas canvas, Offset c, _BenType type,
    {double size = 22, double alpha = 1.0}) {
  final color = _benColor(type);
  canvas.drawCircle(
      c,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.22 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  _legGlyph(canvas, _benGlyph(type), c, size, alpha: alpha);
}

/// A pollinator bee — mirrors `_drawBee`.
void _legBee(Canvas canvas, Offset c, {double alpha = 1.0}) {
  GameFx.orb(canvas, c, 5, _kPollinator.withValues(alpha: alpha),
      glow: 0.6 * alpha, specular: false);
  final wing = Paint()..color = Colors.white.withValues(alpha: 0.45 * alpha);
  canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - 4, c.dy - 3), width: 6, height: 4),
      wing);
  canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx + 4, c.dy - 3), width: 6, height: 4),
      wing);
}

/// A short crop row along [topY], tinted by [health] — mirrors `_drawCrops`.
void _legCropRow(Canvas canvas, Size size, double topY, {double health = 1.0}) {
  final color = Color.lerp(_kCropSick, _kCropHealthy, health)!;
  const n = 7;
  final dx = size.width / n;
  final leaf = Paint()..color = color;
  final stem = Paint()
    ..color = Color.lerp(_kCropSick, const Color(0xFF2E6B2C), health)!
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < n; i++) {
    final x = dx * (i + 0.5);
    final h = 20 + health * 14;
    canvas.drawLine(Offset(x, topY), Offset(x, topY - h), stem);
    for (var k = 0; k < 3; k++) {
      final ly = topY - h * (0.4 + 0.25 * k);
      final side = k.isEven ? 1 : -1;
      final tip = Offset(x + side * 9, ly - 3);
      final path = Path()
        ..moveTo(x, ly)
        ..quadraticBezierTo(x + side * 6, ly - 7, tip.dx, tip.dy)
        ..quadraticBezierTo(x + side * 5, ly + 1, x, ly);
      canvas.drawPath(path, leaf);
    }
  }
}

/// Small text/emoji glyph — mirrors the painter's `_glyph`.
void _legGlyph(Canvas canvas, String s, Offset center, double size,
    {Color color = Colors.white, double alpha = 1.0}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color.withValues(alpha: alpha),
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// A rightward arrow from [a] to [b].
void _legArrow(Canvas canvas, Offset a, Offset b) {
  final p = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(a, b, p);
  canvas.drawLine(Offset(b.dx - 6, b.dy - 5), b, p);
  canvas.drawLine(Offset(b.dx - 6, b.dy + 5), b, p);
}

// ---- the four cards --------------------------------------------------------

/// Card 1 — the core verb: each pest is countered by one matching beneficial.
void _legendPairs(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  const pests = [_PestType.aphid, _PestType.mite, _PestType.caterpillar];
  const bens = [_BenType.ladybug, _BenType.lacewing, _BenType.bird];
  for (var i = 0; i < pests.length; i++) {
    final y = size.height * (0.24 + 0.26 * i);
    _legPest(canvas, Offset(size.width * 0.26, y), pests[i]);
    _legArrow(canvas, Offset(size.width * 0.40, y), Offset(size.width * 0.56, y));
    _legBen(canvas, Offset(size.width * 0.70, y), bens[i]);
  }
}

/// Card 2 — scoring: a matched beneficial eats pests (+points) over green crops.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legCropRow(canvas, size, size.height * 0.82, health: 1.0);
  _legBee(canvas, Offset(size.width * 0.80, size.height * 0.54));
  final pc = Offset(size.width * 0.42, size.height * 0.44);
  _legPest(canvas, pc, _PestType.aphid, alpha: 0.45);
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * math.pi * 2;
    canvas.drawCircle(pc + Offset(math.cos(a), math.sin(a)) * 12, 2.2,
        Paint()..color = _kAphid.withValues(alpha: 0.7));
  }
  _legBen(canvas, Offset(size.width * 0.30, size.height * 0.40), _BenType.ladybug);
  GameFx.text(canvas, '+12', Offset(size.width * 0.54, size.height * 0.30), 18,
      _kLadybug,
      weight: FontWeight.w800, glow: 0.5);
}

/// Card 3 — the trap: SPRAY nukes the field but kills helpers/bees + resistance.
void _legendSpray(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final r = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.32),
      width: size.width * 0.30,
      height: size.height * 0.26);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = _kDanger.withValues(alpha: 0.16));
  canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kDanger.withValues(alpha: 0.7));
  _legGlyph(canvas, '☠', Offset(r.center.dx, r.center.dy - 6), 26,
      color: _kDanger);
  GameFx.text(canvas, 'SPRAY', Offset(r.center.dx, r.bottom - 12), 11, _kDanger,
      weight: FontWeight.w800);
  // Casualties below — a faded helper + bee.
  _legBen(canvas, Offset(size.width * 0.28, size.height * 0.64), _BenType.ladybug,
      alpha: 0.4);
  _legBee(canvas, Offset(size.width * 0.72, size.height * 0.64), alpha: 0.4);
  // A resistance meter climbing.
  final by = size.height * 0.86;
  final bw = size.width * 0.6;
  final bx = size.width * 0.2;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw, 8), const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.5));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw * 0.6, 8), const Radius.circular(4)),
      Paint()..color = _kResistance);
  GameFx.text(canvas, 'RESISTANCE', Offset(size.width * 0.5, by - 11), 9,
      _kResistance,
      weight: FontWeight.w700);
}

/// Card 4 — escalation: swarms drop in, and pest variety unlocks over time.
void _legendSwarm(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legCropRow(canvas, size, size.height * 0.86, health: 0.6);
  const types = [
    _PestType.aphid,
    _PestType.mite,
    _PestType.caterpillar,
    _PestType.aphid,
    _PestType.mite,
    _PestType.caterpillar,
    _PestType.aphid,
  ];
  for (var i = 0; i < types.length; i++) {
    final fx = (i + 0.5) / types.length;
    final x = size.width * (0.10 + 0.80 * fx);
    final y = size.height * (0.20 + 0.34 * (((i * 7) % 5) / 4));
    _legPest(canvas, Offset(x, y), types[i], r: 10);
  }
  GameFx.text(canvas, 'SWARM!', Offset(size.width * 0.5, size.height * 0.08), 16,
      _kDanger,
      weight: FontWeight.w800, glow: 0.5);
}

/// The visual manual for Pest Patrol — wired into the registry spec.
final List<LegendFrame> pestPatrolLegendFrames = [
  const LegendFrame(
      caption: 'Match each pest to its predator, then release',
      paint: _legendPairs),
  const LegendFrame(
      caption: 'A matched helper eats pests: +12 and keeps crops green',
      paint: _legendScore),
  const LegendFrame(
      caption: 'SPRAY nukes all — kills helpers, bees, breeds resistance',
      paint: _legendSpray),
  const LegendFrame(
      caption: 'Swarms escalate: aphids, then mites, then caterpillars',
      paint: _legendSwarm),
];

// ---- widget ----------------------------------------------------------------

class PestPatrolGame extends StatefulWidget {
  final MiniGameSession session;
  const PestPatrolGame({super.key, required this.session});

  @override
  State<PestPatrolGame> createState() => _PestPatrolGameState();
}

class _PestPatrolGameState extends State<PestPatrolGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  bool _seeded = false;
  bool _began = false; // becomes true once the host starts the round
  double _time = 0;
  Duration _lastElapsed = Duration.zero;

  // Field
  final List<_Pest> _pests = [];
  final List<_Ben> _bens = [];
  final List<_Bee> _bees = [];
  final List<FxParticle> _particles = [];
  final List<_Popup> _popups = [];

  double _cropHealth = 1.0;
  double _resistance = 0.0;
  int _combo = 1;
  int _streak = 0;

  double _spawnTimer = _kSpawnBase;
  double _swarmTimer = _kSwarmFirstDelay;
  double _dividendTimer = 0;
  double _deployCd = 0;
  double _sprayCd = 0;

  // Selection
  _BenType? _selected;
  double _shake = 0;
  double _sprayFlash = 0; // 0..1 full-field flash after a spray

  // ---- derived layout -------------------------------------------------------

  double get _barTop => _size.height - _kBarH;
  double get _cropLineY => _size.height - _kBarH - _kCropRowH;

  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    if (dur <= 0) return 0;
    final elapsed = dur - widget.session.remaining.inMilliseconds / 1000.0;
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  double get _pestSpeed =>
      _kPestSpeedBase * (1 + (_kPestSpeedScale - 1) * _progress);

  double get _spawnInterval =>
      (_kSpawnBase - (_kSpawnBase - _kSpawnMin) * _progress)
          .clamp(_kSpawnMin, _kSpawnBase);

  double get _swarmInterval =>
      _kSwarmIntervalMax - (_kSwarmIntervalMax - _kSwarmIntervalMin) * _progress;

  int get _swarmSize =>
      (_kSwarmSizeMin + (_kSwarmSizeMax - _kSwarmSizeMin) * _progress).round();

  int get _liveBens => _bens.where((b) => !b.leaving).length;
  int get _liveBees => _bees.where((b) => !b.dead).length;

  // ---- lifecycle ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ---- ATTRACT autopilot ----------------------------------------------------
  /// One hands-free move per host tick (~250ms). This plays Pest Patrol
  /// *correctly*, not randomly: it finds the pest closest to the crop (the most
  /// urgent threat), ARMS the beneficial that counters that pest's type
  /// (ladybug→aphid, lacewing→mite, bird→caterpillar) and releases it right on
  /// that pest via the game's own [_deploy] handler. It NEVER sprays — spray
  /// harms helpers/bees and breeds resistance. Deterministic; one action/tick.
  /// The host owns the clock, so the round still ends on time; the bot just
  /// banks real biocontrol kills until it does.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    // Summon is rationed and capped — wait rather than fire a no-op.
    if (_deployCd > 0 || _liveBens >= _kBenMaxAlive) return;
    // Most urgent pest = the live one nearest the crop (largest y). Feeding
    // pests sit at the crop line, so this naturally prioritizes active damage.
    _Pest? target;
    double bestY = -double.infinity;
    for (final p in _pests) {
      if (p.dead) continue;
      if (p.y > bestY) {
        bestY = p.y;
        target = p;
      }
    }
    if (target == null) return; // no pests → nothing to do
    final ben = _counter(target.type); // correct match only, never spray
    _selected = ben; // arm the matching beneficial
    _deploy(ben, Offset(target.x, target.y)); // release it on the pest
  }

  void _seed() {
    _pests.clear();
    _bens.clear();
    _bees.clear();
    _particles.clear();
    _popups.clear();
    // A few aphids already drifting in — the calm "ready" picture.
    for (var i = 0; i < 3; i++) {
      _pests.add(_Pest(
        _size.width * (0.25 + 0.25 * i),
        _size.height * (0.16 + 0.10 * i),
        _PestType.aphid,
        _rng.nextDouble() * math.pi * 2,
      ));
    }
    // Pollinators wander the crop band.
    for (var i = 0; i < _kPollinatorCount; i++) {
      _bees.add(_Bee(
        _size.width * (0.15 + 0.7 * _rng.nextDouble()),
        _cropLineY - 20 - _rng.nextDouble() * 40,
        _rng.nextDouble() * math.pi * 2,
      ));
    }
    _seeded = true;
  }

  void _beginRound() {
    _began = true;
    _cropHealth = 1.0;
    _resistance = 0.0;
    _combo = 1;
    _streak = 0;
    _spawnTimer = _kSpawnBase * 0.6;
    _swarmTimer = _kSwarmFirstDelay;
    _dividendTimer = 0;
    _deployCd = 0;
    _sprayCd = 0;
    _selected = null;
  }

  // ---- loop -----------------------------------------------------------------

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastElapsed = elapsed;
    _time += dt;
    if (_size == Size.zero) {
      _repaint.tick();
      return;
    }
    if (!_seeded) _seed();

    final running = widget.session.isRunning;
    if (running && !_began) _beginRound();

    _updateBees(dt, running);
    _updatePests(dt, running);
    _updateBens(dt);
    _updateParticles(dt);
    _updatePopups(dt);
    if (_shake > 0) _shake = math.max(0, _shake - dt * 9);
    if (_sprayFlash > 0) _sprayFlash = math.max(0, _sprayFlash - dt * 2.2);
    if (_deployCd > 0) _deployCd = math.max(0, _deployCd - dt);
    if (_sprayCd > 0) _sprayCd = math.max(0, _sprayCd - dt);

    if (running) {
      _spawn(dt);
      _spawnSwarm(dt);
      _decayResistance(dt);
      _payDividend(dt);
    }

    _repaint.tick();
  }

  void _decayResistance(double dt) {
    if (_resistance > 0) {
      _resistance = math.max(0, _resistance - _kResistanceDecay * dt);
    }
  }

  /// The "preserve crop health" score stream: a per-second dividend scaled by
  /// crop health and live pollinators, shrunk by pesticide resistance. This is
  /// where leaning on the spray quietly costs you.
  void _payDividend(double dt) {
    _dividendTimer += dt;
    if (_dividendTimer < 1.0) return;
    _dividendTimer -= 1.0;
    final gross = _cropHealth * _kHealthDividend +
        _liveBees * _kPollinatorDividend;
    final net = (gross * (1.0 - _resistance)).round();
    if (net > 0) widget.session.addScore(net);
  }

  void _updateBees(double dt, bool running) {
    for (var i = _bees.length - 1; i >= 0; i--) {
      final b = _bees[i];
      if (b.dead) {
        b.deathAge += dt;
        if (b.deathAge > 0.6) _bees.removeAt(i);
        continue;
      }
      if (!running) continue;
      b.phase += dt;
      b.x += math.sin(b.phase * 1.3) * 26 * dt;
      b.y += math.cos(b.phase * 0.9) * 14 * dt;
      b.x = b.x.clamp(14.0, _size.width - 14.0);
      b.y = b.y.clamp(_cropLineY - 54, _cropLineY - 6);
    }
  }

  void _updatePests(double dt, bool running) {
    final speed = _pestSpeed * (1 + _resistance * 0.6);
    var feedingAny = false;
    for (var i = _pests.length - 1; i >= 0; i--) {
      final p = _pests[i];
      if (p.dead) {
        p.deathAge += dt;
        if (p.deathAge > 0.4) _pests.removeAt(i);
        continue;
      }
      if (!running) continue;
      if (p.y < _cropLineY) {
        p.y += speed * dt;
        p.x += math.sin(_time * 1.6 + p.seed) * _kPestSwayAmp * dt;
        p.x = p.x.clamp(10.0, _size.width - 10.0);
      } else {
        // At the crops — settle and feed, drifting slowly along the row.
        p.y = _cropLineY + 4 + math.sin(_time + p.seed) * 3;
        p.feeding = (p.feeding + dt * 2).clamp(0.0, 1.0);
        p.x += math.sin(_time * 0.8 + p.seed) * 8 * dt;
        p.x = p.x.clamp(10.0, _size.width - 10.0);
        final bite = _kPestNibble * (1 + _resistance) * dt;
        _cropHealth = (_cropHealth - bite).clamp(0.0, 1.0);
        feedingAny = true;
      }
    }
    if (running && !feedingAny && _cropHealth < 1.0) {
      _cropHealth = (_cropHealth + _kCropRegen * dt).clamp(0.0, 1.0);
    }
  }

  void _updateBens(double dt) {
    for (var i = _bens.length - 1; i >= 0; i--) {
      final ben = _bens[i];
      ben.age += dt;
      if (ben.leaving || ben.age > _kBenLife) {
        ben.leaving = true;
        ben.y -= 140 * dt; // fly off the top
        if (ben.y < -30 || ben.age > _kBenLife + 1.2) _bens.removeAt(i);
        continue;
      }
      // Hunt the nearest live pest of the matching type.
      final target = _nearestPrey(ben);
      if (target == null) {
        // Nothing to eat — drift and wind down early.
        ben.x += math.sin(_time + ben.seed) * 30 * dt;
        ben.y += math.cos(_time * 0.8 + ben.seed) * 18 * dt;
        if (ben.age > 1.6) ben.leaving = true;
        continue;
      }
      final to = Offset(target.x - ben.x, target.y - ben.y);
      final dist = to.distance;
      if (dist < _kBenEatRadius) {
        _eatPest(ben, target);
      } else if (dist > 0) {
        final v = to / dist * _kBenSpeed * dt;
        ben.x += v.dx;
        ben.y += v.dy;
      }
    }
  }

  _Pest? _nearestPrey(_Ben ben) {
    final prey = _prey(ben.type);
    _Pest? best;
    double bestD = double.infinity;
    for (final p in _pests) {
      if (p.dead || p.type != prey) continue;
      final dx = p.x - ben.x;
      final dy = p.y - ben.y;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  void _eatPest(_Ben ben, _Pest p) {
    p.dead = true;
    p.deathAge = 0;
    ben.eaten++;
    final pts = _kSmartKill * _combo;
    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);
    _combo = (_combo + 1).clamp(1, _kComboMax);
    _particles.addAll(FxBurst.spawn(
        Offset(p.x, p.y), _pestColor(p.type),
        count: 8, speed: 110));
    _popup(p.x, p.y - 14, '+$pts', _benColor(ben.type));
  }

  void _updateParticles(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    if (_particles.length > 130) {
      _particles.removeRange(0, _particles.length - 130);
    }
  }

  void _updatePopups(double dt) {
    for (var i = _popups.length - 1; i >= 0; i--) {
      _popups[i].age += dt;
      _popups[i].y -= 34 * dt;
      if (_popups[i].age > 0.9) _popups.removeAt(i);
    }
    if (_popups.length > 10) _popups.removeRange(0, _popups.length - 10);
  }

  void _popup(double x, double y, String text, Color color,
          {double scale = 1.0}) =>
      _popups.add(_Popup(x, y, text, color, scale: scale));

  // ---- spawning -------------------------------------------------------------

  void _spawn(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0) return;
    _spawnTimer = _spawnInterval + _rng.nextDouble() * 0.4;
    if (_pests.where((p) => !p.dead).length >= _kPestMaxAlive) return;
    _pests.add(_Pest(
      18 + _rng.nextDouble() * (_size.width - 36),
      -12,
      _randomPestType(),
      _rng.nextDouble() * math.pi * 2,
    ));
  }

  /// A descending SWARM — a cluster of pests that drops in together, staggered
  /// in height so it cascades down the field as one wave. This is the main
  /// pressure: the lone-trickle alone is too easy to keep up with.
  void _spawnSwarm(double dt) {
    _swarmTimer -= dt;
    if (_swarmTimer > 0) return;
    _swarmTimer = _swarmInterval;
    final available = _kPestMaxAlive - _pests.where((p) => !p.dead).length;
    if (available <= 0) return;
    final count = math.min(_swarmSize, available);
    if (count <= 0) return;

    // Spread the wave across most of the width with jitter; stagger start
    // heights so it reads as a descending swarm, not a single rank.
    final margin = 18.0;
    final span = (_size.width - margin * 2).clamp(1.0, double.infinity);
    for (var i = 0; i < count; i++) {
      final frac = count == 1 ? 0.5 : i / (count - 1);
      final x = (margin + frac * span + (_rng.nextDouble() - 0.5) * 34)
          .clamp(margin, _size.width - margin);
      final y = -12.0 - _rng.nextDouble() * 70;
      _pests.add(_Pest(x, y, _randomPestType(), _rng.nextDouble() * math.pi * 2));
    }
    _shake = math.max(_shake, 5);
    _popup(_size.width / 2, _cropLineY * 0.45, 'SWARM!', _kDanger, scale: 1.3);
  }

  /// Pest variety unlocks as the round accelerates: aphids → +mites → +
  /// caterpillars, so the player must keep switching to the matching predator.
  _PestType _randomPestType() {
    final p = _progress;
    final roll = _rng.nextDouble();
    if (p < 0.34) return _PestType.aphid;
    if (p < 0.67) return roll < 0.55 ? _PestType.aphid : _PestType.mite;
    if (roll < 0.4) return _PestType.aphid;
    if (roll < 0.72) return _PestType.mite;
    return _PestType.caterpillar;
  }

  // ---- gestures -------------------------------------------------------------

  void _onTapDown(Offset pos) {
    if (_size == Size.zero) return;
    // Bottom bar owns its strip.
    if (pos.dy >= _barTop) {
      _onBarTap(pos);
      return;
    }
    if (!widget.session.isRunning) return;
    // Release the armed predator onto the field.
    if (_selected == null) {
      _shake = math.max(_shake, 3);
      _popup(pos.dx, pos.dy, 'PICK A PREDATOR', Colors.white70);
      return;
    }
    _deploy(_selected!, pos);
  }

  void _onBarTap(Offset pos) {
    final n = 4; // ladybug, lacewing, bird, spray
    final slot = (pos.dx / (_size.width / n)).floor().clamp(0, n - 1);
    if (slot == 3) {
      _spray();
      return;
    }
    final type = _BenType.values[slot];
    // Selection is read by the painter via the repaint notifier; no setState.
    _selected = (_selected == type) ? null : type;
  }

  void _deploy(_BenType type, Offset pos) {
    if (_deployCd > 0) {
      // Summon is on cooldown — nudge so the tap isn't silently swallowed.
      _shake = math.max(_shake, 2);
      return;
    }
    if (_liveBens >= _kBenMaxAlive) {
      _shake = math.max(_shake, 3);
      return;
    }
    _deployCd = _kDeployCooldown;
    _bens.add(_Ben(pos.dx, pos.dy.clamp(0.0, _cropLineY + 20),
        type, _rng.nextDouble() * math.pi * 2));
    _particles.addAll(FxBurst.spawn(pos, _benColor(type), count: 6, speed: 90));
  }

  /// The trap: a spray clears every pest at once, but kills your beneficials and
  /// pollinators, breeds resistance (smaller dividend + tougher pests), and
  /// costs points outright.
  void _spray() {
    if (!widget.session.isRunning) return;
    if (_sprayCd > 0) return;
    _sprayCd = _kSprayCooldown;
    _sprayFlash = 1.0;
    _shake = 8;
    _resistance = math.min(_kResistanceMax, _resistance + _kSprayResistance);
    widget.session.addScore(-_kSprayPenalty);
    _combo = 1;
    _streak = 0;

    for (final p in _pests) {
      if (!p.dead) {
        p.dead = true;
        p.deathAge = 0;
      }
    }
    var lostBens = 0;
    for (final b in _bens) {
      if (!b.leaving) {
        b.leaving = true;
        lostBens++;
      }
    }
    var lostBees = 0;
    for (final b in _bees) {
      if (!b.dead) {
        b.dead = true;
        b.deathAge = 0;
        lostBees++;
      }
    }
    final beneficialsLost = lostBens + lostBees;
    if (beneficialsLost > 0) {
      widget.session.addScore(-_kBenLostPenalty * beneficialsLost);
    }
    _particles.addAll(FxBurst.spawn(
        Offset(_size.width / 2, _cropLineY - 20), _kResistance,
        count: 22, speed: 160));
    _popup(_size.width / 2, _cropLineY - 36, 'PESTICIDE −', _kDanger,
        scale: 1.3);
    if (beneficialsLost > 0) {
      _popup(_size.width / 2, _cropLineY - 60,
          'KILLED $beneficialsLost HELPERS', _kResistance);
    }
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      if (_size != size) {
        _size = size;
        _seeded = false;
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (e) => _onTapDown(e.localPosition),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _PestPatrolPainter(state: this, repaint: _repaint),
            ),
          ),
        ),
      );
    });
  }
}

// ===========================================================================
// Painter — the whole field in one pass.
// ===========================================================================

class _PestPatrolPainter extends CustomPainter {
  final _PestPatrolGameState state;
  _PestPatrolPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final s = state;
    if (s.shakeOn) {
      canvas.save();
      canvas.translate(
        math.sin(s.timeVal * 47) * s.shakeVal,
        math.cos(s.timeVal * 37) * s.shakeVal,
      );
    }

    _drawBackground(canvas, size);
    _drawCrops(canvas, size);
    for (final b in s.beesView) {
      _drawBee(canvas, b);
    }
    for (final p in s.pestsView) {
      _drawPest(canvas, p);
    }
    for (final b in s.bensView) {
      _drawBen(canvas, b);
    }
    FxBurst.paint(canvas, s.particlesView);
    _drawPopups(canvas);
    if (s.sprayFlashVal > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = _kResistance.withValues(alpha: 0.28 * s.sprayFlashVal),
      );
    }
    _drawHud(canvas, size);
    _drawBar(canvas, size);
    if (!s.isRunningView) _drawReadyHint(canvas, size);

    if (s.shakeOn) canvas.restore();
  }

  // ---- field ----------------------------------------------------------------

  void _drawBackground(Canvas canvas, Size size) {
    final cropLine = state.cropLineYView;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, cropLine + 10),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kSkyTop, _kSkyHorizon],
        ).createShader(Rect.fromLTWH(0, 0, size.width, cropLine + 10)),
    );
    final soilTop = cropLine + 10;
    canvas.drawRect(
      Rect.fromLTWH(0, soilTop, size.width, size.height - soilTop),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kSoilTop, _kSoilBot],
        ).createShader(
            Rect.fromLTWH(0, soilTop, size.width, size.height - soilTop)),
    );
  }

  void _drawCrops(Canvas canvas, Size size) {
    final cropLine = state.cropLineYView;
    final health = state.cropHealthView;
    final color = Color.lerp(_kCropSick, _kCropHealthy, health)!;
    const n = 9;
    final dx = size.width / n;
    final leaf = Paint()..color = color;
    final stem = Paint()
      ..color = Color.lerp(_kCropSick, const Color(0xFF2E6B2C), health)!
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final x = dx * (i + 0.5);
      final droop = (1 - health) * 10;
      final h = 22 + health * 18;
      canvas.drawLine(
          Offset(x, cropLine + 14), Offset(x, cropLine + 14 - h + droop), stem);
      // a few leaves
      for (var k = 0; k < 3; k++) {
        final ly = cropLine + 14 - h * (0.4 + 0.25 * k) + droop;
        final side = k.isEven ? 1 : -1;
        final wob = math.sin(state.timeVal * 1.5 + i + k) * 2;
        final tip = Offset(x + side * (9 + wob), ly - 3);
        final path = Path()
          ..moveTo(x, ly)
          ..quadraticBezierTo(x + side * 6, ly - 7, tip.dx, tip.dy)
          ..quadraticBezierTo(x + side * 5, ly + 1, x, ly);
        canvas.drawPath(path, leaf);
      }
    }
  }

  void _drawBee(Canvas canvas, _Bee b) {
    final a = b.dead ? (1 - (b.deathAge / 0.6)).clamp(0.0, 1.0) : 1.0;
    if (a <= 0) return;
    final c = _kPollinator.withValues(alpha: a);
    GameFx.orb(canvas, Offset(b.x, b.y), 5, c, glow: 0.6 * a, specular: false);
    // wings
    final wing = Paint()..color = Colors.white.withValues(alpha: 0.45 * a);
    final flap = math.sin(b.phase * 22).abs() * 3 + 2;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(b.x - 4, b.y - 3), width: 6, height: flap),
        wing);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(b.x + 4, b.y - 3), width: 6, height: flap),
        wing);
    if (b.dead) {
      // little down-arrow puff so the loss reads
      canvas.drawCircle(Offset(b.x, b.y),
          5 + b.deathAge * 10, Paint()..color = _kResistance.withValues(alpha: 0.3 * a));
    }
  }

  void _drawPest(Canvas canvas, _Pest p) {
    final a = p.dead ? (1 - (p.deathAge / 0.4)).clamp(0.0, 1.0) : 1.0;
    if (a <= 0) return;
    final color = _pestColor(p.type).withValues(alpha: a);
    final c = Offset(p.x, p.y);
    final r = _kPestRadius;
    // legs
    final leg = Paint()
      ..color = Colors.black.withValues(alpha: 0.45 * a)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final wig = math.sin(state.timeVal * 9 + p.seed) * 2;
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(Offset(c.dx - r * 0.5, c.dy + i * 3),
          Offset(c.dx - r - 3, c.dy + i * 4 + wig), leg);
      canvas.drawLine(Offset(c.dx + r * 0.5, c.dy + i * 3),
          Offset(c.dx + r + 3, c.dy + i * 4 - wig), leg);
    }
    GameFx.orb(canvas, c, r, color, glow: 0.5 * a);
    // type marker
    if (p.type == _PestType.caterpillar) {
      // segmented body trailing up
      for (var k = 1; k <= 2; k++) {
        canvas.drawCircle(Offset(c.dx, c.dy - k * 6.0),
            r * (0.8 - k * 0.12), Paint()..color = color);
      }
    } else if (p.type == _PestType.mite) {
      final eye = Paint()..color = Colors.white.withValues(alpha: 0.85 * a);
      canvas.drawCircle(Offset(c.dx - 3, c.dy - 2), 1.6, eye);
      canvas.drawCircle(Offset(c.dx + 3, c.dy - 2), 1.6, eye);
    }
    if (p.feeding > 0.4 && !p.dead) {
      // chomp ring at the crop line
      canvas.drawCircle(
          c,
          r + 4 + math.sin(state.timeVal * 8 + p.seed) * 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = _kDanger.withValues(alpha: 0.5 * a));
    }
  }

  void _drawBen(Canvas canvas, _Ben b) {
    final fade = b.leaving
        ? (1 - (b.age - _kBenLife) / 1.2).clamp(0.0, 1.0)
        : 1.0;
    final a = b.leaving ? math.max(0.3, fade) : 1.0;
    final c = Offset(b.x, b.y);
    final color = _benColor(b.type);
    // soft hunting halo so the active helper is legible against the field
    canvas.drawCircle(
        c,
        16,
        Paint()
          ..color = color.withValues(alpha: 0.22 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    _glyph(canvas, _benGlyph(b.type), c, 22, alpha: a);
  }

  void _drawPopups(Canvas canvas) {
    for (final p in state.popupsView) {
      final f = (p.age / 0.9).clamp(0.0, 1.0);
      final alpha = f < 0.7 ? 1.0 : (1 - (f - 0.7) / 0.3);
      GameFx.text(canvas, p.text, Offset(p.x, p.y), 15 * p.scale,
          p.color.withValues(alpha: alpha),
          weight: FontWeight.w800, glow: 0.5 * alpha);
    }
  }

  // ---- HUD ------------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    const pad = 14.0;
    const top = 12.0;
    // Crop-health bar
    const barW = 150.0;
    const barH = 12.0;
    final health = state.cropHealthView;
    final track = RRect.fromRectAndRadius(
        const Rect.fromLTWH(pad, top, barW, barH), const Radius.circular(6));
    canvas.drawRRect(track, Paint()..color = Colors.black.withValues(alpha: 0.5));
    final fillColor = Color.lerp(_kDanger, _kCropHealthy, health)!;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, top, barW * health, barH),
            const Radius.circular(6)),
        Paint()..color = fillColor);
    canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.25));
    _glyph(canvas, 'CROP', Offset(pad + barW + 26, top + barH / 2), 11,
        color: Colors.white70);

    // Resistance bar (only once it matters)
    final res = state.resistanceView;
    if (res > 0.04) {
      const ry = top + barH + 8;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(pad, ry, barW, 7),
              const Radius.circular(4)),
          Paint()..color = Colors.black.withValues(alpha: 0.5));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(pad, ry, barW * (res / _kResistanceMax), 7),
              const Radius.circular(4)),
          Paint()..color = _kResistance);
      _glyph(canvas, 'RESISTANCE', Offset(pad + barW + 44, ry + 3.5), 9,
          color: _kResistance);
    }

    // Combo badge
    final combo = state.comboView;
    if (combo > 1) {
      _glyph(canvas, '×$combo', Offset(size.width - 30, top + 10), 18,
          color: _kAccent);
    }
  }

  void _drawReadyHint(Canvas canvas, Size size) {
    final y = state.cropLineYView * 0.5;
    _glyph(canvas, 'MATCH THE PREDATOR TO THE PEST',
        Offset(size.width / 2, y), 14, color: Colors.white70);
    _glyph(canvas, 'spray backfires — use beneficials',
        Offset(size.width / 2, y + 22), 11, color: _kResistance);
  }

  // ---- the selection bar ----------------------------------------------------

  void _drawBar(Canvas canvas, Size size) {
    final top = state.barTopView;
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, _kBarH),
        Paint()..color = _kBarBg);
    canvas.drawLine(Offset(0, top), Offset(size.width, top),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 1);
    final n = 4;
    final w = size.width / n;
    for (var i = 0; i < 3; i++) {
      _drawPredButton(canvas, _BenType.values[i], Rect.fromLTWH(i * w, top, w, _kBarH));
    }
    _drawSprayButton(canvas, Rect.fromLTWH(3 * w, top, w, _kBarH));
  }

  void _drawPredButton(Canvas canvas, _BenType type, Rect r) {
    final selected = state.selectedView == type;
    // Deploy cooldown is global across all three predators — every button shows
    // the same sweep so the player can see when the next summon is ready.
    final cd = state.deployCdView;
    final onCd = cd > 0;
    final color = _benColor(type);
    final pad = const EdgeInsets.all(6);
    final inner = pad.deflateRect(r);
    canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(12)),
        Paint()
          ..color = selected
              ? color.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: onCd ? 0.03 : 0.05));
    canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.2 : 1.2
          ..color =
              color.withValues(alpha: selected ? 0.95 : (onCd ? 0.25 : 0.4)));
    final cx = r.center.dx;
    final dim = onCd ? 0.4 : 1.0;
    _glyph(canvas, _benGlyph(type), Offset(cx - 14, r.top + 26), 22, alpha: dim);
    // prey swatch — teaches the pairing right on the button
    final prey = _prey(type);
    canvas.drawCircle(Offset(cx + 12, r.top + 22), 6,
        Paint()..color = _pestColor(prey).withValues(alpha: dim));
    canvas.drawLine(Offset(cx - 2, r.top + 22), Offset(cx + 5, r.top + 22),
        Paint()
          ..color = Colors.white60.withValues(alpha: dim)
          ..strokeWidth = 1.4);
    _glyph(canvas, _benName(type), Offset(cx, r.bottom - 12), 9,
        color: (selected ? color : Colors.white70).withValues(alpha: dim));
    if (onCd) {
      final frac = (cd / _kDeployCooldown).clamp(0.0, 1.0);
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx - 14, r.top + 26), radius: 16),
          -math.pi / 2,
          math.pi * 2 * frac,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: 0.7));
    }
  }

  void _drawSprayButton(Canvas canvas, Rect r) {
    final cd = state.sprayCdView;
    final inner = const EdgeInsets.all(6).deflateRect(r);
    final disabled = cd > 0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(12)),
        Paint()
          ..color = _kDanger.withValues(alpha: disabled ? 0.08 : 0.16));
    canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _kDanger.withValues(alpha: disabled ? 0.3 : 0.7));
    final cx = r.center.dx;
    _glyph(canvas, '☠', Offset(cx, r.top + 24), 22,
        color: _kDanger.withValues(alpha: disabled ? 0.4 : 1.0));
    _glyph(canvas, 'SPRAY', Offset(cx, r.bottom - 12), 9,
        color: _kDanger.withValues(alpha: disabled ? 0.4 : 0.9));
    if (disabled) {
      // cooldown sweep
      final frac = (cd / _kSprayCooldown).clamp(0.0, 1.0);
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, r.top + 24), radius: 16),
          -math.pi / 2,
          math.pi * 2 * frac,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _kDanger.withValues(alpha: 0.6));
    }
  }

  // ---- helper ---------------------------------------------------------------

  void _glyph(Canvas canvas, String s, Offset center, double size,
      {Color color = Colors.white, double alpha = 1.0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: alpha),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PestPatrolPainter oldDelegate) => false;
}

// ---- painter views onto state (kept tiny + read-only) ----------------------

extension _StateView on _PestPatrolGameState {
  double get timeVal => _time;
  bool get shakeOn => _shake > 0;
  double get shakeVal => _shake;
  double get sprayFlashVal => _sprayFlash;
  double get cropHealthView => _cropHealth;
  double get resistanceView => _resistance;
  int get comboView => _combo;
  double get cropLineYView => _cropLineY;
  double get barTopView => _barTop;
  double get sprayCdView => _sprayCd;
  double get deployCdView => _deployCd;
  bool get isRunningView => widget.session.isRunning;
  _BenType? get selectedView => _selected;
  List<_Pest> get pestsView => _pests;
  List<_Ben> get bensView => _bens;
  List<_Bee> get beesView => _bees;
  List<FxParticle> get particlesView => _particles;
  List<_Popup> get popupsView => _popups;
}
