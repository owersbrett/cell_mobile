import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Electron Shells v2 — a UX-passed rebuild of `electron_shells`.
//
// Same lesson: fill the electron shells of a target atom INSIDE-OUT (K=2, L=8,
// M=8, N=8) until the atom is neutral; a full outer shell is a stable octet
// (or duet). What changed, per the teardown:
//
//  • The original OVERLOADED one tap (grab-an-electron vs select-a-ring) and the
//    electrons were interchangeable drifting targets → a target-acquisition
//    chore, not a choice. v2's only verb is "tap a TRAY electron." Each tray
//    electron carries a visible ENERGY LEVEL (K/L/M/N); the decision is *which
//    one belongs in the shell you must fill next*. No aim, no overload.
//  • The original's `addTime(3s)` per atom let a leader extend their own clock —
//    a runaway. v2 has a FIXED host clock; the per-atom bonus instead ESCALATES
//    with the atom's complexity (more shells = bigger payoff), which is fair
//    because every player faces the same progression. A last-8s FINAL SURGE
//    doubles points for a shared, readable climax.
//  • The octet GAP is surfaced as a NUMBER on the active shell ("need 6").
//
// Perf contract: one Ticker → one CustomPainter. Host owns the clock, countdown,
// score HUD and results; this widget renders ONLY the play area and the tray,
// and re-arms a fresh run from session.isRunning.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kAccent = Color(0xFF4F9DFF); // electron blue (brand identity)
const Color _kNucleus = Potatuhs.orange; // proton warmth
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kGold = Color(0xFFFFD54F);

/// Per-energy-level colour. The active shell ring is drawn in its level colour,
/// and tray electrons are coloured by the level they belong to — so matching is
/// a colour+letter read, which IS the lesson (energy levels fill inside-out).
Color _levelColor(int level) {
  switch (level) {
    case 1:
      return _kAccent; // K — blue
    case 2:
      return _kGood; // L — mint
    case 3:
      return _kGold; // M — gold
    default:
      return Potatuhs.orange; // N — orange
  }
}

/// Vertical space reserved at the top for the target panel.
const double _kPanelReserve = 104;

/// Vertical space reserved at the bottom for the electron tray.
const double _kTrayReserve = 104;

/// Visual radius of a seated electron orb.
const double _kElectronR = 9;

/// Visual radius of a tray electron.
const double _kTrayR = 20;

/// One-thumb tap radius for a tray electron.
const double _kTrayHit = 36;

/// Last-N milliseconds of the round where points double (the climax window).
const int _kSurgeMs = 8000;

// Scoring — fixed per-event (no streak multiplier → no runaway leader). The
// atom bonus ESCALATES with shell count instead of extending the clock.
const int _kPlace = 5; // one electron seated
const int _kShell = 15; // a shell completed (octet/duet)
const int _kAtomBase = 30; // base for stabilizing any atom
const int _kAtomPerShell = 15; // + this per shell (bigger atoms pay more)
const int _kPenalty = -6; // wrong-level pick

const List<String> _shellLetters = ['K', 'L', 'M', 'N'];

/// Physical max capacity for shell index [i] (the 2-8-8-8 teaching model).
int _shellMax(int i) => i == 0 ? 2 : 8;

// ---------------------------------------------------------------------------
// Element data — neutral configurations (KEEP: chemically accurate first 20).
// ---------------------------------------------------------------------------

class _Element {
  final int z; // atomic number = protons = electrons (neutral)
  final String symbol;
  final String name;
  final List<int> config; // electrons per shell, e.g. Na = [2, 8, 1]
  const _Element(this.z, this.symbol, this.name, this.config);
}

const List<_Element> _elements = [
  _Element(1, 'H', 'Hydrogen', [1]),
  _Element(2, 'He', 'Helium', [2]),
  _Element(3, 'Li', 'Lithium', [2, 1]),
  _Element(4, 'Be', 'Beryllium', [2, 2]),
  _Element(5, 'B', 'Boron', [2, 3]),
  _Element(6, 'C', 'Carbon', [2, 4]),
  _Element(7, 'N', 'Nitrogen', [2, 5]),
  _Element(8, 'O', 'Oxygen', [2, 6]),
  _Element(9, 'F', 'Fluorine', [2, 7]),
  _Element(10, 'Ne', 'Neon', [2, 8]),
  _Element(11, 'Na', 'Sodium', [2, 8, 1]),
  _Element(12, 'Mg', 'Magnesium', [2, 8, 2]),
  _Element(13, 'Al', 'Aluminium', [2, 8, 3]),
  _Element(14, 'Si', 'Silicon', [2, 8, 4]),
  _Element(15, 'P', 'Phosphorus', [2, 8, 5]),
  _Element(16, 'S', 'Sulfur', [2, 8, 6]),
  _Element(17, 'Cl', 'Chlorine', [2, 8, 7]),
  _Element(18, 'Ar', 'Argon', [2, 8, 8]),
  _Element(19, 'K', 'Potassium', [2, 8, 8, 1]),
  _Element(20, 'Ca', 'Calcium', [2, 8, 8, 2]),
];

/// True when the element's outermost shell is a full octet/duet (a noble gas).
bool _isNoble(_Element e) {
  final last = e.config.length - 1;
  return e.config[last] == _shellMax(last);
}

// ---------------------------------------------------------------------------
// Runtime entities
// ---------------------------------------------------------------------------

/// A candidate electron sitting in the tray. [level] is 1-based (1 = K) — the
/// shell it belongs to. [wild] electrons fit any shell.
class _TrayE {
  int level;
  bool wild;
  double bob; // idle bob phase
  double age; // 0→1 pop-in
  double buzz; // 1→0 wrong-tap shake
  _TrayE(this.level, this.wild, this.bob) : age = 0, buzz = 0;
}

/// An electron flying from a tray slot into shell [shell], slot [slot].
class _Flying {
  final Offset from;
  final int shell;
  final int slot;
  final bool wild;
  double t = 0; // 0..1
  _Flying(this.from, this.shell, this.slot, this.wild);
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL scene primitives
// (same nucleus/shell/tray rendering the live game uses). Cheap + static.
// ═══════════════════════════════════════════════════════════════════════════

/// Draws a literal in-game atom: warm nucleus, shell rings (active one brighter),
/// seated electron orbs, and ghost slots for the octet gap — exactly as the play
/// painter does. [base] scales the whole atom; optionally shows the NEXT label.
void _legendAtom(
  Canvas canvas,
  Offset c,
  List<int> config,
  List<int> filled,
  double base, {
  bool showNext = false,
}) {
  final n = config.length;
  if (n == 0) return;
  final nucR = (base * 0.11).clamp(10.0, 30.0).toDouble();
  final maxR = base * 0.44;
  final inner = nucR + base * 0.10;
  final step = ((maxR - inner) / n).clamp(1.0, base).toDouble();

  var active = n - 1;
  for (var i = 0; i < n; i++) {
    if (filled[i] < config[i]) {
      active = i;
      break;
    }
  }

  for (var i = 0; i < n; i++) {
    final r = inner + step * (i + 1);
    final cap = _shellMax(i);
    final lvlColor = _levelColor(i + 1);
    final isActive = i == active && filled[i] < config[i];

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.6 : 1.4
        ..color = lvlColor.withValues(alpha: isActive ? 0.55 : 0.18),
    );

    // Ghost / needed-but-empty slots — spaced by full capacity so the gap reads.
    for (var s = filled[i]; s < cap; s++) {
      final a = -math.pi / 2 + 2 * math.pi * s / cap;
      final at = c + Offset(math.cos(a), math.sin(a)) * r;
      final needed = s < config[i];
      canvas.drawCircle(
        at,
        _kElectronR * 0.7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = needed ? 1.4 : 1.0
          ..color = (needed ? lvlColor : Colors.white)
              .withValues(alpha: needed ? 0.5 : 0.12),
      );
    }
    // Seated electrons — the real orbs.
    for (var s = 0; s < filled[i]; s++) {
      final a = -math.pi / 2 + 2 * math.pi * s / cap;
      final at = c + Offset(math.cos(a), math.sin(a)) * r;
      GameFx.orb(canvas, at, _kElectronR, lvlColor, glow: 0.9);
    }
  }

  // Nucleus (proton count).
  GameFx.orb(canvas, c, nucR, _kNucleus, glow: 1.2);
  final z = config.fold<int>(0, (a, b) => a + b);
  GameFx.text(canvas, '$z', c, nucR * 0.8, Colors.white,
      display: true, glow: 0.6);

  if (showNext) {
    GameFx.text(
      canvas,
      'NEXT ${_shellLetters[active]} · need ${config[active] - filled[active]}',
      c.translate(0, -(inner + step * n) - 14),
      12,
      _levelColor(active + 1),
      weight: FontWeight.w800,
      glow: 0.5,
    );
  }
}

/// One tray electron orb with its energy-level letter (or `+` for a wildcard),
/// matching `_paintTray`.
void _legendTrayOrb(
    Canvas canvas, Offset at, double r, Color color, String label) {
  canvas.drawCircle(
    at,
    r + 6,
    Paint()
      ..color = color.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  GameFx.orb(canvas, at, r, color, glow: 0.8);
  GameFx.text(canvas, label, at, r * 0.95, Colors.white,
      display: true, glow: 0.4);
}

// Frame A — the atom you build, filled inside-out.
void _legendBuildFrame(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final base = math.min(size.width, size.height);
  final c = Offset(size.width * 0.5, size.height * 0.52);
  // Carbon-ish: K full (2/2), L partway (3/4) → active shell is L.
  _legendAtom(canvas, c, const [2, 4], const [2, 3], base, showNext: true);
}

// Frame B — the tray: three lettered electrons; tap the one for the active shell.
void _legendTrayFrame(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final base = math.min(size.width, size.height);
  final cx = size.width * 0.5;
  final cy = size.height * 0.54;
  final r = (base * 0.12).clamp(14.0, 26.0).toDouble();
  final spacing = math.min(size.width * 0.28, base * 0.42);

  // Tray base bar.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy), width: size.width * 0.9, height: base * 0.44),
      const Radius.circular(16),
    ),
    Paint()..color = Colors.black.withValues(alpha: 0.32),
  );

  const labels = ['K', 'L', '+'];
  const levels = [1, 2, 0]; // 0 = gold wildcard
  const activeIdx = 1; // the L electron matches the active shell
  for (var i = 0; i < 3; i++) {
    final at = Offset(cx + (i - 1) * spacing, cy);
    final wild = levels[i] == 0;
    final color = wild ? _kGold : _levelColor(levels[i]);
    if (i == activeIdx) {
      // Selection ring around the electron the player should tap.
      canvas.drawCircle(
        at,
        r + 9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: 0.85),
      );
    }
    _legendTrayOrb(canvas, at, r, color, labels[i]);
  }
  GameFx.text(canvas, 'TAP L', Offset(cx, cy - base * 0.30), 12,
      _levelColor(2),
      weight: FontWeight.w800, glow: 0.4);
}

// Frame C — the danger: a wrong-level pick costs points and resets the streak.
void _legendWrongFrame(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final base = math.min(size.width, size.height);
  final c = Offset(size.width * 0.5, size.height * 0.46);
  final r = (base * 0.15).clamp(16.0, 32.0).toDouble();
  final color = _levelColor(3); // an M electron picked while L is still open
  _legendTrayOrb(canvas, c, r, color, 'M');

  // Red X over the bad pick.
  final p = Paint()
    ..color = _kBad
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  final s = r * 0.85;
  canvas.drawLine(c.translate(-s, -s), c.translate(s, s), p);
  canvas.drawLine(c.translate(s, -s), c.translate(-s, s), p);

  GameFx.text(canvas, '-6', c.translate(0, -r - 16), 16, _kBad,
      display: true, glow: 0.5);
  GameFx.text(canvas, 'FILL L FIRST', Offset(size.width * 0.5, size.height * 0.82),
      13, _kBad,
      weight: FontWeight.w800);
}

// Frame D — the payoff / climax: full octet + the final-surge x2 band.
void _legendSurgeFrame(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final base = math.min(size.width, size.height);
  final c = Offset(size.width * 0.5, size.height * 0.56);
  // Neon 2-8 fully filled — a stable noble octet.
  _legendAtom(canvas, c, const [2, 8], const [2, 8], base);
  GameFx.text(canvas, 'OCTET!', c.translate(0, -(base * 0.44) - 14), 14, _kGold,
      display: true, glow: 0.6);

  // Surge band across the top edge.
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, 6),
    Paint()..color = _kGold.withValues(alpha: 0.7),
  );
  GameFx.text(canvas, 'FINAL SURGE  x2',
      Offset(size.width * 0.5, size.height * 0.12), 13, _kGold,
      display: true, glow: 0.6);
}

/// The visual manual for Electron Shells v2 — wired into the registry spec.
final List<LegendFrame> electronShellsV2LegendFrames = [
  const LegendFrame(
      caption: 'Fill shells inside-out: K first, then L, M, N',
      paint: _legendBuildFrame),
  const LegendFrame(
      caption: 'Tap the tray electron matching the active shell',
      paint: _legendTrayFrame),
  const LegendFrame(
      caption: 'Avoid wrong picks: -6 and your streak resets',
      paint: _legendWrongFrame),
  const LegendFrame(
      caption: 'Finish octets; last 8s SURGE doubles every point',
      paint: _legendSurgeFrame),
];

// ---------------------------------------------------------------------------
// Game widget
// ---------------------------------------------------------------------------

class ElectronShellsV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ElectronShellsV2Game({super.key, required this.session});

  @override
  State<ElectronShellsV2Game> createState() => _ElectronShellsV2GameState();
}

class _ElectronShellsV2GameState extends State<ElectronShellsV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (idle shimmer, ring orbit)
  double _elapsed = 0; // advances only while running (difficulty ramp)
  bool _started = false; // re-arms a fresh run from isRunning

  late _Element _target;
  late List<int> _filled; // electrons seated per shell
  int _placedTotal = 0; // electrons seated this atom
  int _completedAtoms = 0;
  int _streak = 0;

  final List<_TrayE> _tray = [];
  final List<_Flying> _flying = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  /// Celebration timeline; -1 = inactive, otherwise seconds since stabilizing.
  double _celebT = -1;

  /// Pulse (1→0) kicked on the active shell when the player misclicks.
  double _hintPulse = 0;

  /// Transient guidance caption + its age. -1 = hidden.
  String _hint = '';
  double _hintAge = -1;

  Size? _fieldSize;

  @override
  void initState() {
    super.initState();
    _loadElement(_elements[2]); // Lithium (2,1) — shows K then L
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- autopilot --

  /// ATTRACT mode: one competent move per call. Sort electrons by energy level
  /// inside-out — seat one tray electron into the CORRECT (lowest not-yet-full)
  /// shell, which is exactly `_activeShell`. A valid tray electron is one whose
  /// level matches the active shell (or a wildcard); `_ensureMatch` guarantees
  /// at least one exists. Tapping it routes through the real `_tapTray` handler,
  /// so it can never overfill or place out of order. No randomness, no synthetic
  /// taps — if nothing can be placed (mid-flight or celebrating), return.
  void _autoStep() {
    if (!widget.session.isRunning || _celebT >= 0) return;
    final lvl = _activeShell + 1;
    for (var i = 0; i < _tray.length; i++) {
      final e = _tray[i];
      if (e.wild || e.level == lvl) {
        _tapTray(i);
        return;
      }
    }
  }

  // ----------------------------------------------------------------- model --

  /// The shell that must be filled next (lowest with room left).
  int get _activeShell {
    for (var i = 0; i < _target.config.length; i++) {
      if (_filled[i] < _target.config[i]) return i;
    }
    return _target.config.length - 1;
  }

  /// Electrons still needed to neutralize the active shell.
  int get _activeNeed => _target.config[_activeShell] - _filled[_activeShell];

  bool get _surge {
    final ms = widget.session.remaining.inMilliseconds;
    return widget.session.isRunning && ms > 0 && ms <= _kSurgeMs;
  }

  void _resetRun() {
    _elapsed = 0;
    _completedAtoms = 0;
    _streak = 0;
    _flying.clear();
    _particles.clear();
    _pops.clear();
    _celebT = -1;
    _hint = '';
    _hintAge = -1;
    _loadElement(_elements[2]);
  }

  void _loadElement(_Element e) {
    _target = e;
    _filled = List<int>.filled(e.config.length, 0);
    _placedTotal = 0;
    _tray.clear();
    for (var i = 0; i < 3; i++) {
      _tray.add(_makeElectron());
    }
    _ensureMatch();
  }

  /// How many elements are "unlocked" — grows with time + clears so atoms get
  /// bigger (more shells / electrons) as the round accelerates.
  int get _unlocked {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final p = (_elapsed / dur).clamp(0.0, 1.0);
    final boost = math.min(_completedAtoms, 8);
    final n = (5 + p * (_elements.length - 5) + boost).round();
    return n.clamp(5, _elements.length);
  }

  void _nextElement() {
    final hi = _unlocked - 1;
    final lo = math.max(0, hi - 5);
    _Element pick;
    var guard = 0;
    do {
      pick = _elements[lo + _rng.nextInt(hi - lo + 1)];
      guard++;
    } while (pick.z == _target.z && guard < 6);
    _loadElement(pick);
  }

  int get _maxLevel => _target.config.length;

  _TrayE _makeElectron({int? forceLevel}) {
    final bob = _rng.nextDouble() * math.pi * 2;
    if (forceLevel != null) return _TrayE(forceLevel, false, bob);
    // Small chance of a gold wildcard that fits any shell.
    if (_maxLevel >= 2 && _rng.nextDouble() < 0.06) {
      return _TrayE(0, true, bob);
    }
    // Bias toward the active level so the tray stays playable; otherwise a
    // decoy at some other existing shell.
    final lvl = _rng.nextDouble() < 0.45
        ? _activeShell + 1
        : 1 + _rng.nextInt(_maxLevel);
    return _TrayE(lvl, false, bob);
  }

  /// Guarantee at least one tray electron can be seated into the active shell.
  void _ensureMatch() {
    final lvl = _activeShell + 1;
    if (_tray.any((e) => e.wild || e.level == lvl)) return;
    _tray[_rng.nextInt(_tray.length)] = _makeElectron(forceLevel: lvl);
  }

  // ----------------------------------------------------------------- ticker --

  void _onTick(Duration now) {
    final dt =
        ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = now;
    _clock += dt;
    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        _resetRun();
      }
      _elapsed += dt;
      _update(dt);
    } else {
      _started = false; // re-arm for the next fresh run
    }
    if (mounted) setState(() {});
  }

  Offset get _center {
    final s = _fieldSize ?? const Size(360, 640);
    const top = _kPanelReserve;
    final bottom = s.height - _kTrayReserve;
    return Offset(s.width * 0.5, (top + bottom) * 0.5);
  }

  double get _nucleusR => 24;

  double _ringRadius(int i) {
    final s = _fieldSize ?? const Size(360, 640);
    final vert = (s.height - _kPanelReserve - _kTrayReserve) * 0.5 - 14;
    final maxR = math.min(s.width * 0.5 - 18, vert).clamp(60.0, 240.0);
    final n = _target.config.length;
    final inner = _nucleusR + 30;
    if (n == 1) return inner + (maxR - inner) * 0.55;
    final step = (maxR - inner) / n;
    return inner + step * (i + 1);
  }

  /// World position of slot [slot] on shell [i] (slots spaced by full capacity
  /// so the octet gap is visible). Slowly orbits for life.
  Offset _slotPos(int i, int slot) {
    final cap = _shellMax(i);
    final a = -math.pi / 2 + 2 * math.pi * slot / cap + _clock * 0.15;
    final r = _ringRadius(i);
    return _center + Offset(math.cos(a), math.sin(a)) * r;
  }

  Offset _traySlotPos(int i) {
    final s = _fieldSize ?? const Size(360, 640);
    final spacing = math.min(s.width * 0.26, 116.0);
    final dx = s.width * 0.5 + (i - 1) * spacing;
    return Offset(dx, s.height - _kTrayReserve * 0.5);
  }

  // ------------------------------------------------------------------- sim --

  void _update(double dt) {
    for (final e in _tray) {
      e.bob += dt * 2.2;
      if (e.age < 1) e.age = math.min(1, e.age + dt / 0.22);
      if (e.buzz > 0) e.buzz = math.max(0, e.buzz - dt / 0.4);
    }

    for (final f in List<_Flying>.from(_flying)) {
      f.t += dt / 0.34;
      if (f.t >= 1) {
        _flying.remove(f);
        _seat(f);
      }
    }

    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    if (_celebT >= 0) {
      _celebT += dt;
      if (_celebT >= 1.4) {
        _celebT = -1;
        _nextElement();
      }
    }
    if (_hintPulse > 0) _hintPulse = math.max(0, _hintPulse - dt / 0.7);
    if (_hintAge >= 0) {
      _hintAge += dt;
      if (_hintAge > 2.0) {
        _hintAge = -1;
        _hint = '';
      }
    }
  }

  void _award(int base) =>
      widget.session.addScore(_surge ? base * 2 : base);

  void _seat(_Flying f) {
    _filled[f.shell]++;
    _placedTotal++;
    final at = _slotPos(f.shell, f.slot);
    _particles
        .addAll(FxBurst.spawn(at, _levelColor(f.shell + 1), count: 6, speed: 70, size: 2.4));

    // Shell just reached its configured count?
    if (_filled[f.shell] == _target.config[f.shell]) {
      final isFull = _target.config[f.shell] == _shellMax(f.shell);
      if (isFull) {
        _award(_kShell);
        _pop(f.shell == 0 ? 'DUET!' : 'OCTET!',
            _center.translate(0, -_ringRadius(f.shell) - 18), _kGold);
      }
    }

    // Atom neutral & every shell at its configured count → stable!
    final stable = _placedTotal == _target.z &&
        List.generate(_target.config.length,
            (i) => _filled[i] == _target.config[i]).every((x) => x);
    if (stable && _celebT < 0) {
      _streak++;
      widget.session.noteStreak(_streak);
      final bonus = _kAtomBase + _kAtomPerShell * _target.config.length;
      _award(bonus);
      _completedAtoms++;
      _pop('+${_surge ? bonus * 2 : bonus}', _center.translate(0, -8), _kGold);
      _particles
          .addAll(FxBurst.spawn(_center, _kAccent, count: 20, speed: 150, size: 3));
      _celebT = 0;
    } else {
      _ensureMatch();
    }
  }

  void _pop(String text, Offset at, Color color) =>
      _pops.add(FxPop(at, text, color));

  void _flash(String hint) {
    _hint = hint;
    _hintAge = 0;
    _hintPulse = 1.0;
  }

  // ----------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _celebT >= 0) return;
    final p = d.localPosition;
    for (var i = 0; i < _tray.length; i++) {
      if ((_traySlotPos(i) - p).distance <= _kTrayHit) {
        _tapTray(i);
        return;
      }
    }
  }

  void _tapTray(int i) {
    final e = _tray[i];
    final a = _activeShell;
    final lvl = a + 1;

    if (e.wild || e.level == lvl) {
      // Valid → fly into the active shell's next slot.
      final slot = _filled[a];
      _award(_kPlace);
      _flying.add(_Flying(_traySlotPos(i), a, slot, e.wild));
      _tray[i] = _makeElectron();
      _ensureMatch();
      return;
    }

    // Wrong energy level — teach why.
    e.buzz = 1.0;
    final String why;
    if (e.level - 1 < a) {
      why = '${_shellLetters[e.level - 1]} IS FULL';
    } else {
      why = 'FILL ${_shellLetters[a]} FIRST';
    }
    _penalty(why, _traySlotPos(i));
  }

  void _penalty(String why, Offset at) {
    widget.session.addScore(_kPenalty);
    _streak = 0;
    _pop('$_kPenalty', at.translate(0, -_kTrayR - 6), _kBad);
    _flash(why);
  }

  // ----------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  painter: _ShellsV2Painter(this),
                  size: Size.infinite,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: IgnorePointer(child: _panel()),
            ),
            if (_hintAge >= 0)
              Positioned(
                bottom: _kTrayReserve + 6,
                left: 12,
                right: 12,
                child: IgnorePointer(child: _hintBar()),
              ),
          ],
        ),
      );
    });
  }

  Widget _panel() {
    final e = _target;
    final cfg = e.config.join('-');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        boxShadow: Potatuhs.glow(_kAccent, strength: 0.18, blur: 16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kNucleus.withValues(alpha: 0.7)),
              color: _kNucleus.withValues(alpha: 0.12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${e.z}',
                    style: Potatuhs.label(size: 9, color: _kNucleus)),
                Text(e.symbol,
                    style: Potatuhs.display(size: 20, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.name,
                    style: Potatuhs.body(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text('Build  $cfg   ·   ${e.z} electrons',
                    style: Potatuhs.body(
                        size: 12, color: _kAccent.withValues(alpha: 0.95))),
                const SizedBox(height: 4),
                Row(children: [
                  for (var i = 0; i < e.config.length; i++) ...[
                    _shellChip(i),
                    const SizedBox(width: 6),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shellChip(int i) {
    final done = _filled[i] >= _target.config[i];
    final active = i == _activeShell && !done;
    final color = done ? _kGood : (active ? _levelColor(i + 1) : Potatuhs.textFaint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: active ? 0.9 : 0.5)),
        color: color.withValues(alpha: active ? 0.18 : 0.06),
      ),
      child: Text('${_shellLetters[i]} ${_filled[i]}/${_target.config[i]}',
          style:
              Potatuhs.body(size: 11, weight: FontWeight.w700, color: color)),
    );
  }

  Widget _hintBar() {
    final a = (1 - (_hintAge / 2.0)).clamp(0.0, 1.0);
    return Opacity(
      opacity: a < 0.3 ? a / 0.3 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBad.withValues(alpha: 0.6)),
        ),
        child: Text(_hint,
            style:
                Potatuhs.body(size: 13, weight: FontWeight.w700, color: _kBad)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — one painter draws the whole scene each frame.
// ---------------------------------------------------------------------------

class _ShellsV2Painter extends CustomPainter {
  final _ElectronShellsV2GameState g;
  _ShellsV2Painter(this.g) : super(repaint: g.widget.session);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 24);
    _paintShells(canvas);
    _paintNucleus(canvas);
    _paintFlying(canvas);
    _paintTray(canvas, size);
    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }
    if (g._celebT >= 0) _paintCeleb(canvas);
    if (g._surge) _paintSurge(canvas, size);
  }

  void _paintShells(Canvas canvas) {
    final active = g._activeShell;
    for (var i = 0; i < g._target.config.length; i++) {
      final r = g._ringRadius(i);
      final cap = _shellMax(i);
      final isActive = i == active && g._filled[i] < g._target.config[i];
      final lvlColor = _levelColor(i + 1);

      final pulse = isActive ? 0.5 + 0.5 * math.sin(g._clock * 4) : 0.0;
      final hint = isActive ? g._hintPulse : 0.0;
      canvas.drawCircle(
        g._center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.6 : 1.4
          ..color = lvlColor.withValues(
              alpha: 0.16 + 0.3 * pulse + 0.4 * hint),
      );

      // Slot dots: needed-but-empty as outlines, octet-gap (beyond config) as
      // faint ghosts so the gap to a full octet stays visible.
      for (var s = g._filled[i]; s < cap; s++) {
        final at = g._slotPos(i, s);
        final needed = s < g._target.config[i];
        canvas.drawCircle(
          at,
          _kElectronR * 0.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = needed ? 1.4 : 1.0
            ..color = (needed ? lvlColor : Colors.white)
                .withValues(alpha: needed ? 0.5 : 0.12),
        );
      }
      // Seated electrons (real orbs).
      for (var s = 0; s < g._filled[i]; s++) {
        GameFx.orb(canvas, g._slotPos(i, s), _kElectronR, lvlColor, glow: 0.9);
      }
    }

    // "NEED n" gap number on the active shell — instant legibility.
    if (g._celebT < 0) {
      final r = g._ringRadius(active);
      final at = g._center.translate(0, -r - 16);
      GameFx.text(
          canvas,
          'NEXT ${_shellLetters[active]} · need ${g._activeNeed}',
          at,
          12,
          _levelColor(active + 1),
          weight: FontWeight.w800,
          glow: 0.5);
    }
  }

  void _paintNucleus(Canvas canvas) {
    final c = g._center;
    final r = g._nucleusR;
    final pulse = 1 + 0.05 * math.sin(g._clock * 3);
    GameFx.orb(canvas, c, r * pulse, _kNucleus, glow: 1.2);
    GameFx.text(canvas, '${g._target.z}', c, r * 0.8, Colors.white,
        display: true, glow: 0.6);
    GameFx.text(canvas, 'p+', c.translate(0, r * 0.62), 8,
        Colors.white.withValues(alpha: 0.7));
  }

  void _paintFlying(Canvas canvas) {
    for (final f in g._flying) {
      final to = g._slotPos(f.shell, f.slot);
      final t = Curves.easeInOut.transform(f.t.clamp(0.0, 1.0));
      final at = Offset.lerp(f.from, to, t)!;
      final color = f.wild ? _kGold : _levelColor(f.shell + 1);
      canvas.drawCircle(
        at,
        _kElectronR + 5,
        Paint()
          ..color = color.withValues(alpha: 0.25 * (1 - t) + 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      GameFx.orb(canvas, at, _kElectronR, color, glow: 1.0);
    }
  }

  void _paintTray(Canvas canvas, Size size) {
    // Tray base bar.
    final barTop = size.height - _kTrayReserve;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, barTop + 8, size.width - 20, _kTrayReserve - 18),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
    GameFx.text(
        canvas,
        'TAP THE ELECTRON FOR SHELL ${_shellLetters[g._activeShell]}',
        Offset(size.width * 0.5, barTop + 18),
        10,
        Colors.white.withValues(alpha: 0.6),
        weight: FontWeight.w700);

    for (var i = 0; i < g._tray.length; i++) {
      final e = g._tray[i];
      var at = g._traySlotPos(i);
      if (e.buzz > 0) {
        at = at.translate(math.sin(g._clock * 50) * 5 * e.buzz, 0);
      }
      final scale = 0.5 + 0.5 * Curves.easeOutBack.transform(e.age.clamp(0, 1));
      final r = _kTrayR * scale;
      final color = e.wild ? _kGold : _levelColor(e.level);
      // Soft seat glow.
      canvas.drawCircle(
        at,
        r + 6,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      GameFx.orb(canvas, at, r, color, glow: 0.8);
      // Level badge: shell letter (or + for wild).
      final label = e.wild ? '+' : _shellLetters[e.level - 1];
      GameFx.text(canvas, label, at, r * 0.95, Colors.white,
          display: true, glow: 0.4);
    }
  }

  void _paintCeleb(Canvas canvas) {
    final t = g._celebT;
    final opacity = t < 0.15
        ? t / 0.15
        : t > 1.0
            ? (1 - (t - 1.0) / 0.4).clamp(0.0, 1.0)
            : 1.0;
    final scale = 0.85 + 0.15 * (t < 0.2 ? t / 0.2 : 1.0);
    final tag = _isNoble(g._target) ? 'NOBLE — FULL OCTET' : 'NEUTRAL ATOM';
    final outer = g._ringRadius(g._target.config.length - 1);
    final at = g._center.translate(0, -outer - 34);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    GameFx.text(canvas, '${g._target.name.toUpperCase()} — STABLE!',
        Offset.zero, 20, Colors.white.withValues(alpha: opacity),
        display: true, glow: 0.8 * opacity);
    GameFx.text(canvas, tag, const Offset(0, 22), 12,
        _kGold.withValues(alpha: opacity),
        weight: FontWeight.w700);
    canvas.restore();
  }

  void _paintSurge(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(g._clock * 6);
    // Top edge glow band.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 6),
      Paint()..color = _kGold.withValues(alpha: 0.4 + 0.4 * pulse),
    );
    GameFx.text(
        canvas,
        'FINAL SURGE  ×2',
        Offset(size.width * 0.5, 78),
        13,
        _kGold.withValues(alpha: 0.7 + 0.3 * pulse),
        display: true,
        glow: 0.6);
  }

  @override
  bool shouldRepaint(_ShellsV2Painter oldDelegate) => true;
}
