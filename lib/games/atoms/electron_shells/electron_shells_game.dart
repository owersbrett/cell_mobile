import 'dart:math' as math;

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Electron Shells — BUILD/FILL the electron configuration of a target atom.
//
// A target element is shown (symbol, name, atomic number Z). Electrons drift in
// the field. The player TAPS an electron to drop it into the currently-selected
// shell, filling shells inside-out and respecting capacity (K=2, L=8, M=8, N=8)
// until the atom is neutral (electrons == protons) — a stable configuration.
//
// • Tap an electron → it flies into the SELECTED shell and fills one slot.
// • Tap a shell ring → select it (you must move outward as each shell fills).
// • Overfill a shell, or fill out of order → UNSTABLE (penalty + reset streak).
// • Complete the configuration → the atom stabilizes → the next element loads.
//
// Teaches electron configuration, shells/energy levels, and the octet rule:
// each shell shows its full capacity as ghost slots, so the gap to a full
// octet (why atoms react) is visible as you build.
//
// Perf contract: one Ticker → one CustomPainter; no per-frame setState over a
// big widget tree. Host owns the clock, 3·2·1 countdown, score HUD and results;
// this widget renders ONLY the play area and auto-starts on session.isRunning.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kAccent = Color(0xFF4F9DFF); // electron blue
const Color _kNucleus = Potatuhs.orange; // proton warmth (complement)
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kGold = Color(0xFFFFD54F);

/// Vertical space reserved at the top for the target panel.
const double _kPanelReserve = 104;

/// Visual radius of a floating / placed electron.
const double _kElectronR = 9;

/// Generous one-thumb tap radius for grabbing an electron.
const double _kHitR = 30;

/// Tolerance band (px) for selecting a shell by tapping near its ring.
const double _kRingTol = 28;

/// Score added to the clock-less score per event.
const int _kPlace = 6; // one electron seated
const int _kShell = 12; // a shell completed
const int _kAtom = 40; // a whole atom stabilized
const int _kPenalty = -7; // unstable placement

// ---------------------------------------------------------------------------
// Element data — neutral configurations, K=2 then octets (2,8,8,8 model).
// First 20 elements: enough to teach periods 1–4 and the octet rule.
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

const List<String> _shellLetters = ['K', 'L', 'M', 'N'];

/// Physical max capacity for shell index [i] (the 2-8-8-8 teaching model).
int _shellMax(int i) => i == 0 ? 2 : 8;

/// True when the element's outermost shell is a full octet/duet (a noble gas).
bool _isStableShellSet(_Element e) {
  final last = e.config.length - 1;
  return e.config[last] == _shellMax(last);
}

// ---------------------------------------------------------------------------
// Runtime entities
// ---------------------------------------------------------------------------

class _Electron {
  Offset pos;
  Offset vel;
  double wobble;
  double spin; // self-rotation phase for the little "‑" charge glint
  _Electron(this.pos, this.vel, this.wobble, this.spin);
}

/// An electron flying from the field into shell [shell], slot [slot].
class _Flying {
  final Offset from;
  final int shell;
  final int slot;
  double t = 0; // 0..1
  _Flying(this.from, this.shell, this.slot);
}

// ---------------------------------------------------------------------------
// Game widget
// ---------------------------------------------------------------------------

class ElectronShellsGame extends StatefulWidget {
  final MiniGameSession session;
  const ElectronShellsGame({super.key, required this.session});

  @override
  State<ElectronShellsGame> createState() => _ElectronShellsGameState();
}

class _ElectronShellsGameState extends State<ElectronShellsGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (idle shimmer, ring spin)
  double _elapsed = 0; // advances only while running (difficulty ramp)

  late _Element _target;
  late List<int> _filled; // electrons seated per shell
  int _activeShell = 0; // shell the next electron drops into
  int _placedTotal = 0; // electrons seated this atom
  int _completedAtoms = 0;
  int _streak = 0;

  final List<_Electron> _field = [];
  final List<_Flying> _flying = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  /// Celebration timeline; -1 = inactive, otherwise seconds since stabilizing.
  double _celebT = -1;

  /// Pulse (1→0) on the shell that should be filled next, kicked when the
  /// player tries something invalid so the guidance flashes.
  double _hintPulse = 0;

  /// Transient guidance caption + its age (seconds). -1 = hidden.
  String _hint = '';
  double _hintAge = -1;

  Size? _fieldSize;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _loadElement(_elements[2]); // start on Lithium (2,1) — shows K then L
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to seat its own electrons. The host
    // only invokes this in hands-free attract mode. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free seat per host tick (~250ms). Plays the game *correctly*:
  /// it finds the innermost shell that still needs electrons (inside-out fill,
  /// counting in-flight electrons so it never overfills or seats out of order),
  /// selects that shell, then drops the nearest floating electron into its next
  /// free slot via the game's own [_placeInto] handler — exactly one seat. When
  /// the atom is neutral (or every remaining slot is already covered by
  /// in-flight electrons) it returns and lets the celebration advance to the
  /// next element. Deterministic: no randomness, no synthetic taps.
  void _autoStep() {
    if (!widget.session.isRunning || _celebT >= 0) return;
    // Innermost shell that still needs electrons, counting in-flight ones so a
    // slot already covered by a flying electron is not seated twice.
    var target = -1;
    for (var i = 0; i < _target.config.length; i++) {
      if (_filled[i] + _pendingIn(i) < _target.config[i]) {
        target = i;
        break;
      }
    }
    if (target < 0) return; // atom complete / all remaining slots in flight
    if (_field.isEmpty) return; // no electron floating yet — wait a tick
    _activeShell = target; // select the correct shell before seating
    // Deterministic pick: the electron nearest the nucleus.
    _Electron? pick;
    var best = double.infinity;
    for (final e in _field) {
      final d = (e.pos - _center).distance;
      if (d < best) {
        best = d;
        pick = e;
      }
    }
    if (pick != null) _placeInto(pick);
  }

  // ----------------------------------------------------------------- model --

  void _loadElement(_Element e) {
    _target = e;
    _filled = List<int>.filled(e.config.length, 0);
    _activeShell = 0;
    _placedTotal = 0;
    _ensureSupply();
  }

  /// How many elements are "unlocked" — grows with time and clears so the atoms
  /// get bigger (more shells / electrons) as the round accelerates.
  int get _unlocked {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final p = (_elapsed / dur).clamp(0.0, 1.0);
    final boost = math.min(_completedAtoms, 8);
    final n = (5 + p * (_elements.length - 5) + boost).round();
    return n.clamp(5, _elements.length);
  }

  void _nextElement() {
    final hi = _unlocked - 1;
    final lo = math.max(0, hi - 5); // drop the very easy ones late
    _Element pick;
    var guard = 0;
    do {
      pick = _elements[lo + _rng.nextInt(hi - lo + 1)];
      guard++;
    } while (pick.z == _target.z && guard < 6);
    _loadElement(pick);
  }

  // ----------------------------------------------------------------- ticker --

  void _onTick(Duration now) {
    final dt =
        ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _lastTick = now;
    _clock += dt;
    // Idle under the countdown overlay: render the scene but do not simulate.
    if (widget.session.isRunning) {
      _elapsed += dt;
      _update(dt);
    }
    if (mounted) setState(() {});
  }

  /// Electron drift speeds up over the round (accelerate).
  double get _speedMul {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return 1.0 + (_elapsed / dur).clamp(0.0, 1.0) * 0.9;
  }

  Rect get _bounds {
    final s = _fieldSize ?? Size.zero;
    return Rect.fromLTRB(14, _kPanelReserve + 8, s.width - 14, s.height - 14);
  }

  Offset get _center {
    final s = _fieldSize ?? const Size(360, 640);
    return Offset(
        s.width * 0.5, _kPanelReserve + (s.height - _kPanelReserve) * 0.5);
  }

  double get _nucleusR => 24;

  /// Radius of shell ring [i] for the current element.
  double _ringRadius(int i) {
    final s = _fieldSize ?? const Size(360, 640);
    final maxR = math.min(s.width * 0.5 - 18,
            (s.height - _kPanelReserve) * 0.5 - 18)
        .clamp(70.0, 260.0);
    final n = _target.config.length;
    final inner = _nucleusR + 30;
    if (n == 1) return inner + (maxR - inner) * 0.55;
    final step = (maxR - inner) / n;
    return inner + step * (i + 1);
  }

  /// World position of slot [slot] on shell [i] (slots spaced by full capacity
  /// so the octet gap is visible).
  Offset _slotPos(int i, int slot) {
    final cap = _shellMax(i);
    final a = -math.pi / 2 + 2 * math.pi * slot / cap + _clock * 0.15;
    final r = _ringRadius(i);
    return _center + Offset(math.cos(a), math.sin(a)) * r;
  }

  // ------------------------------------------------------------------- sim --

  /// Electrons still needed to neutralize the atom.
  int get _remainingNeeded => _target.z - _placedTotal;

  void _update(double dt) {
    final b = _bounds;
    if (b.isEmpty) return;

    // Keep enough electrons floating for what's left to place.
    final want = (_remainingNeeded + 4).clamp(6, 16);
    while (_field.length < want) {
      _spawn(fromEdge: true);
    }

    for (final e in _field) {
      e.wobble += dt * 2.4;
      e.spin += dt * 5;
      final wob = Offset(math.sin(e.wobble * 1.3 + e.vel.dx) * 6,
          math.cos(e.wobble + e.vel.dy) * 6);
      e.pos += (e.vel + wob) * dt * _speedMul;
      if (e.pos.dx < b.left + _kElectronR && e.vel.dx < 0) {
        e.vel = Offset(-e.vel.dx, e.vel.dy);
      }
      if (e.pos.dx > b.right - _kElectronR && e.vel.dx > 0) {
        e.vel = Offset(-e.vel.dx, e.vel.dy);
      }
      if (e.pos.dy < b.top + _kElectronR && e.vel.dy < 0) {
        e.vel = Offset(e.vel.dx, -e.vel.dy);
      }
      if (e.pos.dy > b.bottom - _kElectronR && e.vel.dy > 0) {
        e.vel = Offset(e.vel.dx, -e.vel.dy);
      }
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
      if (_hintAge > 2.2) {
        _hintAge = -1;
        _hint = '';
      }
    }
  }

  void _spawn({bool fromEdge = false, bool anywhere = false}) {
    final b = _bounds;
    if (b.isEmpty) return;
    Offset pos;
    if (anywhere || !fromEdge) {
      pos = Offset(b.left + _rng.nextDouble() * b.width,
          b.top + _rng.nextDouble() * b.height);
    } else {
      final side = _rng.nextInt(4);
      switch (side) {
        case 0:
          pos = Offset(b.left + _kElectronR, b.top + _rng.nextDouble() * b.height);
          break;
        case 1:
          pos = Offset(b.right - _kElectronR, b.top + _rng.nextDouble() * b.height);
          break;
        case 2:
          pos = Offset(b.left + _rng.nextDouble() * b.width, b.top + _kElectronR);
          break;
        default:
          pos = Offset(b.left + _rng.nextDouble() * b.width, b.bottom - _kElectronR);
      }
    }
    final ang = _rng.nextDouble() * math.pi * 2;
    final speed = 24 + _rng.nextDouble() * 22;
    _field.add(_Electron(pos, Offset(math.cos(ang), math.sin(ang)) * speed,
        _rng.nextDouble() * math.pi * 2, _rng.nextDouble() * math.pi * 2));
  }

  void _ensureSupply() {
    if (_bounds.isEmpty) return;
    final want = (_remainingNeeded + 4).clamp(6, 16);
    while (_field.length < want) {
      _spawn(fromEdge: true);
    }
  }

  /// The shell that SHOULD be filled next (lowest with room left in its config).
  int get _shouldFill {
    for (var i = 0; i < _target.config.length; i++) {
      if (_filled[i] < _target.config[i]) return i;
    }
    return _target.config.length - 1; // all done
  }

  void _seat(_Flying f) {
    _filled[f.shell]++;
    _placedTotal++;
    final at = _slotPos(f.shell, f.slot);
    _particles.addAll(FxBurst.spawn(at, _kAccent, count: 6, speed: 70, size: 2.4));

    // Shell just completed its configured electrons?
    if (_filled[f.shell] == _target.config[f.shell]) {
      final isOctet = _target.config[f.shell] == _shellMax(f.shell);
      if (isOctet && f.shell > 0) {
        widget.session.addScore(_kShell);
        _pop('OCTET!', _center.translate(0, -_ringRadius(f.shell) - 18), _kGold);
      } else if (isOctet) {
        widget.session.addScore(_kShell);
        _pop('DUET!', _center.translate(0, -_ringRadius(f.shell) - 18), _kGold);
      }
      // advance selection outward so the flow keeps moving
      if (_activeShell < _target.config.length - 1) _activeShell++;
    }

    // Atom neutral & every shell at its configured count → stable!
    final stable = _placedTotal == _target.z &&
        List.generate(_target.config.length,
            (i) => _filled[i] == _target.config[i]).every((x) => x);
    if (stable && _celebT < 0) {
      _streak++;
      widget.session.noteStreak(_streak);
      widget.session.addScore(_kAtom);
      _completedAtoms++;
      _pop('+$_kAtom', _center.translate(0, -8), _kGold);
      _pop('+3s', _center.translate(0, -34), _kGood);
      _particles.addAll(
          FxBurst.spawn(_center, _kAccent, count: 20, speed: 150, size: 3));
      _celebT = 0;
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

    // 1) Grab the nearest electron under the thumb.
    _Electron? best;
    var bestDist = double.infinity;
    for (final e in _field) {
      final dist = (e.pos - p).distance;
      if (dist <= _kHitR && dist < bestDist) {
        best = e;
        bestDist = dist;
      }
    }
    if (best != null) {
      _placeInto(best);
      return;
    }

    // 2) Otherwise, did they tap on/near a shell ring to select it?
    final fromCenter = (p - _center).distance;
    for (var i = 0; i < _target.config.length; i++) {
      if ((fromCenter - _ringRadius(i)).abs() <= _kRingTol) {
        _activeShell = i;
        return;
      }
    }
  }

  /// How many electrons are currently in flight toward shell [shell]. In-flight
  /// electrons haven't seated (`_filled[shell]++` happens on landing), so they
  /// must be counted alongside `_filled` to make overfill/order guards correct
  /// under rapid taps.
  int _pendingIn(int shell) => _flying.where((f) => f.shell == shell).length;

  void _placeInto(_Electron e) {
    final shell = _activeShell;

    // Out-of-order: an inner shell still needs electrons — counting in-flight
    // ones so a shell already being completed by pending electrons is not a gap.
    var innerGap = false; // truly unfilled (deliberate wrong tap)
    var innerGapPending = false; // only unfilled until in-flight ones land
    for (var i = 0; i < shell; i++) {
      if (_filled[i] + _pendingIn(i) < _target.config[i]) {
        innerGap = true;
        break;
      }
      if (_filled[i] < _target.config[i]) {
        innerGapPending = true;
      }
    }
    if (innerGap) {
      _penalty('FILL INNER FIRST', e.pos);
      return;
    }
    // Inner shells will be completed by in-flight electrons — quiet no-op
    // (don't punish rapid taps for a gap already covered).
    if (innerGapPending) return;

    // Effective fill = seated + in-flight toward this shell.
    final effective = _filled[shell] + _pendingIn(shell);
    // Overfill: this shell already holds (or will hold) its share.
    if (effective >= _target.config[shell]) {
      // Only truly-full-by-seated placements are deliberate mistakes worth a
      // penalty; "full" purely because of pending in-flight electrons is a
      // rapid-tap artefact → silent no-op, no score/streak hit.
      if (_filled[shell] >= _target.config[shell]) {
        final full = _filled[shell] >= _shellMax(shell);
        _penalty(full ? 'SHELL FULL — NEXT RING' : 'NEUTRAL — TAP NEXT RING',
            e.pos);
      }
      return;
    }

    // Valid placement — next free slot accounts for in-flight electrons.
    final slot = effective; // next free slot index
    widget.session.addScore(_kPlace);
    _flying.add(_Flying(e.pos, shell, slot));
    _field.remove(e);
  }

  void _penalty(String why, Offset at) {
    widget.session.addScore(_kPenalty);
    _streak = 0;
    _pop('$_kPenalty', at.translate(0, -_kElectronR - 6), _kBad);
    _flash(why);
  }

  // ----------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_seeded && !_bounds.isEmpty) {
        _seeded = true;
        for (var i = 0; i < 8; i++) {
          _spawn(anywhere: true);
        }
      }
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  painter: _ShellsPainter(this),
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
            if (_hintAge >= 0) Positioned(
              bottom: 14,
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
    final cfg = e.config.join(',');
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
          // Atomic number + symbol tile.
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
                Text('Seat ${e.z} electrons   ·   $cfg',
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
    final active = i == _activeShell;
    final color = done ? _kGood : (active ? _kAccent : Potatuhs.textFaint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: active ? 0.9 : 0.5)),
        color: color.withValues(alpha: active ? 0.18 : 0.06),
      ),
      child: Text('${_shellLetters[i]} ${_filled[i]}/${_target.config[i]}',
          style: Potatuhs.body(
              size: 11, weight: FontWeight.w700, color: color)),
    );
  }

  Widget _hintBar() {
    final a = (1 - (_hintAge / 2.2)).clamp(0.0, 1.0);
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
            style: Potatuhs.body(
                size: 13, weight: FontWeight.w700, color: _kBad)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — one painter draws the whole scene each frame.
// ---------------------------------------------------------------------------

class _ShellsPainter extends CustomPainter {
  final _ElectronShellsGameState g;
  _ShellsPainter(this.g) : super(repaint: g.widget.session);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 26);
    _paintShells(canvas);
    _paintNucleus(canvas);
    _paintFlying(canvas);
    _paintField(canvas);
    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }
    if (g._celebT >= 0) _paintCeleb(canvas);
  }

  void _paintShells(Canvas canvas) {
    final should = g._shouldFill;
    for (var i = 0; i < g._target.config.length; i++) {
      final r = g._ringRadius(i);
      final cap = _shellMax(i);
      final active = i == g._activeShell;
      final isNext = i == should;

      // Ring line.
      final ringPulse =
          isNext ? 0.5 + 0.5 * math.sin(g._clock * 4) : 0.0;
      final hint = isNext ? g._hintPulse : 0.0;
      canvas.drawCircle(
        g._center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.4 : 1.4
          ..color = (active
                  ? _kAccent
                  : isNext
                      ? Color.lerp(_kAccent, _kGood, 0.5)!
                      : _kAccent)
              .withValues(
                  alpha: 0.18 + 0.22 * ringPulse + 0.4 * hint),
      );

      // Slot dots: filled electrons solid, needed-but-empty as outlines,
      // octet-gap (beyond config) as faint ghosts so the gap to 8 is visible.
      for (var s = 0; s < cap; s++) {
        final at = g._slotPos(i, s);
        if (s < g._filled[i]) {
          continue; // drawn as real electrons below
        }
        final needed = s < g._target.config[i];
        canvas.drawCircle(
          at,
          _kElectronR * 0.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = needed ? 1.4 : 1.0
            ..color = (needed ? _kAccent : Colors.white)
                .withValues(alpha: needed ? 0.5 : 0.12),
        );
      }
      // Seated electrons (real orbs).
      for (var s = 0; s < g._filled[i]; s++) {
        GameFx.orb(canvas, g._slotPos(i, s), _kElectronR, _kAccent,
            glow: 0.9);
      }
    }
  }

  void _paintNucleus(Canvas canvas) {
    final c = g._center;
    final r = g._nucleusR;
    // Pulsing warm core (protons + neutrons).
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
      canvas.drawCircle(
        at,
        _kElectronR + 5,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.25 * (1 - t) + 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      GameFx.orb(canvas, at, _kElectronR, _kAccent, glow: 1.0);
    }
  }

  void _paintField(Canvas canvas) {
    for (final e in g._field) {
      GameFx.orb(canvas, e.pos, _kElectronR, _kAccent, glow: 0.55);
      // little white "−" charge glint
      GameFx.text(canvas, '−', e.pos, _kElectronR * 1.1,
          Colors.white.withValues(alpha: 0.85));
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
    final stableTag =
        _isStableShellSet(g._target) ? 'NOBLE — FULL OCTET' : 'NEUTRAL ATOM';
    final outer = g._ringRadius(g._target.config.length - 1);
    final at = g._center.translate(0, -outer - 34);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    GameFx.text(canvas, '${g._target.name.toUpperCase()} — STABLE!', Offset.zero,
        20, Colors.white.withValues(alpha: opacity),
        display: true, glow: 0.8 * opacity);
    GameFx.text(canvas, stableTag, const Offset(0, 22), 12,
        _kGold.withValues(alpha: opacity),
        weight: FontWeight.w700);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShellsPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same GameFx orb / ring / slot language the live painter uses).
// Static + cheap: rendered once in the intro carousel, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One floating field electron: blue orb + white "−" charge glint (the exact
/// look of [_ShellsPainter._paintField]).
void _legendElectron(Canvas canvas, Offset at, {double glow = 0.55}) {
  GameFx.orb(canvas, at, _kElectronR, _kAccent, glow: glow);
  GameFx.text(canvas, '−', at, _kElectronR * 1.1,
      Colors.white.withValues(alpha: 0.85));
}

/// Radius of shell ring [i] of [n] rings inside a legend atom of [outerR] —
/// the same inner-offset + even-step shape the live `_ringRadius` uses.
double _legendRingR(double outerR, int n, int i) {
  final nucleusR = math.max(11.0, outerR * 0.20);
  final inner = nucleusR + outerR * 0.22;
  if (n == 1) return inner + (outerR - inner) * 0.55;
  return inner + (outerR - inner) / n * (i + 1);
}

/// Slot position [s] on ring [i] (slots spaced by FULL capacity so the
/// octet gap stays visible, exactly like the live `_slotPos`).
Offset _legendSlotPos(Offset c, double outerR, int n, int i, int s) {
  final cap = _shellMax(i);
  final a = -math.pi / 2 + 2 * math.pi * s / cap;
  return c + Offset(math.cos(a), math.sin(a)) * _legendRingR(outerR, n, i);
}

/// Nucleus + concentric shells in the game's visual language: seated
/// electrons are solid orbs, needed-but-empty slots blue outlines, octet-gap
/// slots faint white ghosts. [config]/[filled] = electrons per shell.
void _legendAtom(
  Canvas canvas,
  Offset c, {
  required int z,
  required List<int> config,
  required List<int> filled,
  required double outerR,
  int activeShell = 0,
}) {
  if (outerR <= 0 || !outerR.isFinite) return;
  final n = config.length;
  for (var i = 0; i < n; i++) {
    final active = i == activeShell;
    canvas.drawCircle(
      c,
      _legendRingR(outerR, n, i),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.4 : 1.4
        ..color = _kAccent.withValues(alpha: active ? 0.55 : 0.26),
    );
    final cap = _shellMax(i);
    for (var s = 0; s < cap; s++) {
      final at = _legendSlotPos(c, outerR, n, i, s);
      if (s < filled[i]) {
        GameFx.orb(canvas, at, _kElectronR * 0.9, _kAccent, glow: 0.8);
      } else {
        final needed = s < config[i];
        canvas.drawCircle(
          at,
          _kElectronR * 0.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = needed ? 1.4 : 1.0
            ..color = (needed ? _kAccent : Colors.white)
                .withValues(alpha: needed ? 0.55 : 0.16),
        );
      }
    }
  }
  // Warm nucleus, labeled with Z protons.
  final nucleusR = math.max(11.0, outerR * 0.20);
  GameFx.orb(canvas, c, nucleusR, _kNucleus, glow: 1.2);
  GameFx.text(canvas, '$z', c, nucleusR * 0.8, Colors.white,
      display: true, glow: 0.6);
  if (nucleusR >= 14) {
    GameFx.text(canvas, 'p+', c.translate(0, nucleusR * 0.62), 8,
        Colors.white.withValues(alpha: 0.7));
  }
}

/// (1) The verb: tap a floating electron → it flies into the selected shell.
void _legendTapSeat(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.44, size.height * 0.60);
  final outerR = math.min(size.width, size.height) * 0.30;
  const config = [2, 1]; // Lithium — the game's start element
  _legendAtom(canvas, c,
      z: 3, config: config, filled: const [0, 0], outerR: outerR);

  // The tapped electron (with a gold tap-ring cue) up in the field…
  final e = Offset(size.width * 0.82, size.height * 0.16);
  for (var i = 0; i < 2; i++) {
    canvas.drawCircle(
      e,
      _kElectronR + 6.0 + i * 6.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _kGold.withValues(alpha: 0.7 - i * 0.3),
    );
  }
  _legendElectron(canvas, e, glow: 0.9);

  // …and its twin mid-flight toward the open K slot (halo like _paintFlying).
  final target = _legendSlotPos(c, outerR, config.length, 0, 0);
  final mid = Offset.lerp(e, target, 0.58)!;
  canvas.drawCircle(
    mid,
    _kElectronR + 5,
    Paint()
      ..color = _kAccent.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  GameFx.orb(canvas, mid, _kElectronR, _kAccent, glow: 1.0);
}

/// (2) Scoring: a completed Neon — every shell at its config → OCTET + STABLE.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.60);
  final outerR = math.min(size.width, size.height) * 0.30;
  _legendAtom(canvas, c,
      z: 10,
      config: const [2, 8],
      filled: const [2, 8],
      outerR: outerR,
      activeShell: 1);
  GameFx.text(canvas, 'OCTET! +12', Offset(size.width * 0.5, size.height * 0.10),
      14, _kGold,
      display: true, glow: 0.7);
  final seat = _legendSlotPos(c, outerR, 2, 1, 2); // right-hand L electron
  GameFx.text(canvas, '+$_kPlace', seat.translate(20, -12), 12, _kGood,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'STABLE! +$_kAtom',
      Offset(size.width * 0.5, size.height * 0.22), 12, _kGold,
      weight: FontWeight.w800);
}

/// (3) The danger: seating outward while K still has a gap → UNSTABLE −7.
void _legendUnstable(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.62);
  final outerR = math.min(size.width, size.height) * 0.32;
  const config = [2, 8, 1]; // Sodium
  _legendAtom(canvas, c,
      z: 11,
      config: config,
      filled: const [1, 0, 0],
      outerR: outerR,
      activeShell: 2);

  // An electron aimed at the OUTER ring while K is still open — crossed out.
  final bad = _legendSlotPos(c, outerR, config.length, 2, 1); // upper right
  _legendElectron(canvas, bad, glow: 0.8);
  final x = Paint()
    ..color = _kBad
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  const s = 13.0;
  canvas.drawLine(bad.translate(-s, -s), bad.translate(s, s), x);
  canvas.drawLine(bad.translate(s, -s), bad.translate(-s, s), x);
  GameFx.text(canvas, '$_kPenalty', bad.translate(0, -_kElectronR - 16), 13,
      _kBad,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'FILL INNER FIRST',
      Offset(size.width * 0.5, size.height * 0.10), 12, _kBad,
      weight: FontWeight.w800);
}

/// (4) Escalation: bigger atoms (more shells) + faster-drifting electrons.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.58);
  final outerR = math.min(size.width, size.height) * 0.36;
  _legendAtom(canvas, c,
      z: 20, // Calcium — a late 4-shell atom
      config: const [2, 8, 8, 2],
      filled: const [2, 8, 3, 0],
      outerR: outerR,
      activeShell: 2);

  // Speed-streaked field electrons.
  const spots = [Offset(0.13, 0.16), Offset(0.88, 0.30), Offset(0.16, 0.90)];
  const dirs = [Offset(0.83, 0.55), Offset(-0.9, 0.44), Offset(0.94, -0.34)];
  for (var i = 0; i < spots.length; i++) {
    final p = Offset(size.width * spots[i].dx, size.height * spots[i].dy);
    canvas.drawLine(
      p - dirs[i] * 24,
      p,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.35)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    _legendElectron(canvas, p, glow: 0.7);
  }
}

/// The visual manual for Electron Shells — wired into the registry spec.
final List<LegendFrame> electronShellsLegendFrames = [
  const LegendFrame(
      caption: 'Tap a drifting electron to seat it in the ring',
      paint: _legendTapSeat),
  const LegendFrame(
      caption: 'Fill every shell: octet +12, stable atom +40',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Skip or overfill a shell: unstable, −7',
      paint: _legendUnstable),
  const LegendFrame(
      caption: 'Later: bigger atoms, faster-drifting electrons',
      paint: _legendEscalate),
];
