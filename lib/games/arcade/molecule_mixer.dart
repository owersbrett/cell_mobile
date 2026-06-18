import 'dart:math' as math;

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/molecular/molecule_facts.dart'
    show MoleculeFact, factForFormula;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFF00BCD4);

/// Seconds added to the clock each time a molecule is completed.
const int _kMoleculeTimeBonus = 4;

/// Vertical space reserved at the top of the play field for the target panel.
const double _kPanelReserve = 112;

/// Visual radius of a floating atom.
const double _kAtomR = 21;

/// Effective tap radius (generous, one-thumb friendly).
const double _kHitR = 34;

// ---------------------------------------------------------------------------
// Element + molecule data
// ---------------------------------------------------------------------------

class _ElementDef {
  final String symbol;
  final Color color;
  final Color textColor;
  final bool outlined;
  const _ElementDef(this.symbol, this.color, this.textColor,
      {this.outlined = false});
}

const List<_ElementDef> _elements = [
  _ElementDef('H', Color(0xFFF5F5F5), Color(0xFF111111)), // 0
  _ElementDef('O', Color(0xFFEF5350), Colors.white), // 1
  _ElementDef('C', Color(0xFF37474F), Colors.white, outlined: true), // 2
  _ElementDef('N', Color(0xFF42A5F5), Colors.white), // 3
  _ElementDef('Cl', Color(0xFF66BB6A), Colors.white), // 4
];

const int _eH = 0, _eO = 1, _eC = 2, _eN = 3, _eCl = 4;

class _SlotDef {
  final int element;
  final Offset offset; // in molecule units, scaled at paint time
  const _SlotDef(this.element, this.offset);
}

class _MoleculeDef {
  final String formula;
  final String name;
  final List<_SlotDef> slots;
  final List<List<int>> bonds; // index pairs into slots
  final bool advanced; // 4-5 atom molecules, favored late game
  const _MoleculeDef(this.formula, this.name, this.slots, this.bonds,
      {this.advanced = false});
}

const List<_MoleculeDef> _molecules = [
  _MoleculeDef('H₂O', 'Water', [
    _SlotDef(_eO, Offset(0, -0.18)),
    _SlotDef(_eH, Offset(-0.92, 0.52)),
    _SlotDef(_eH, Offset(0.92, 0.52)),
  ], [
    [0, 1],
    [0, 2],
  ]),
  _MoleculeDef('O₂', 'Oxygen', [
    _SlotDef(_eO, Offset(-0.62, 0)),
    _SlotDef(_eO, Offset(0.62, 0)),
  ], [
    [0, 1],
  ]),
  _MoleculeDef('CO₂', 'Carbon dioxide', [
    _SlotDef(_eC, Offset(0, 0)),
    _SlotDef(_eO, Offset(-1.18, 0)),
    _SlotDef(_eO, Offset(1.18, 0)),
  ], [
    [0, 1],
    [0, 2],
  ]),
  _MoleculeDef(
      'CH₄',
      'Methane',
      [
        _SlotDef(_eC, Offset(0, 0)),
        _SlotDef(_eH, Offset(0, -1.05)),
        _SlotDef(_eH, Offset(1.05, 0)),
        _SlotDef(_eH, Offset(0, 1.05)),
        _SlotDef(_eH, Offset(-1.05, 0)),
      ],
      [
        [0, 1],
        [0, 2],
        [0, 3],
        [0, 4],
      ],
      advanced: true),
  _MoleculeDef(
      'NH₃',
      'Ammonia',
      [
        _SlotDef(_eN, Offset(0, -0.22)),
        _SlotDef(_eH, Offset(-0.95, 0.52)),
        _SlotDef(_eH, Offset(0.95, 0.52)),
        _SlotDef(_eH, Offset(0, -1.22)),
      ],
      [
        [0, 1],
        [0, 2],
        [0, 3],
      ],
      advanced: true),
  _MoleculeDef('N₂', 'Nitrogen', [
    _SlotDef(_eN, Offset(-0.62, 0)),
    _SlotDef(_eN, Offset(0.62, 0)),
  ], [
    [0, 1],
  ]),
  _MoleculeDef(
      'H₂O₂',
      'Hydrogen peroxide',
      [
        _SlotDef(_eO, Offset(-0.52, 0)),
        _SlotDef(_eO, Offset(0.52, 0)),
        _SlotDef(_eH, Offset(-1.22, -0.62)),
        _SlotDef(_eH, Offset(1.22, 0.62)),
      ],
      [
        [0, 1],
        [0, 2],
        [1, 3],
      ],
      advanced: true),
  _MoleculeDef('HCl', 'Hydrochloric acid', [
    _SlotDef(_eH, Offset(-0.68, 0)),
    _SlotDef(_eCl, Offset(0.68, 0)),
  ], [
    [0, 1],
  ]),
];

// ---------------------------------------------------------------------------
// Backbone helpers
// ---------------------------------------------------------------------------

/// Returns the slot index of the backbone atom for [mol], or null if the
/// molecule is ungated (diatomic or no single clear hub).
///
/// The backbone is defined as the slot with the highest bond-degree.
/// Ungated conditions:
///   • max degree == 1  (diatomic — every slot touches exactly one bond)
///   • tie: two or more slots share the maximum degree
int? _backboneSlot(_MoleculeDef mol) {
  if (mol.bonds.isEmpty) return null;

  // Compute degree for each slot index.
  final degree = List<int>.filled(mol.slots.length, 0);
  for (final b in mol.bonds) {
    degree[b[0]]++;
    degree[b[1]]++;
  }

  final maxDeg = degree.reduce(math.max);

  // Ungated: diatomic (maxDeg == 1) or tie.
  if (maxDeg <= 1) return null;
  final hubs = [for (var i = 0; i < degree.length; i++) if (degree[i] == maxDeg) i];
  if (hubs.length != 1) return null;

  return hubs.first;
}

// ---------------------------------------------------------------------------
// Runtime entities
// ---------------------------------------------------------------------------

class _Slot {
  final _SlotDef def;
  int state = 0; // 0 empty, 1 incoming (atom flying in), 2 filled
  double fillTime = -1; // _clock when filled, drives bond draw-in
  _Slot(this.def);
}

class _FieldAtom {
  Offset pos;
  Offset vel;
  final int element;
  double wobble; // phase for soft bobbing
  double shake = 0; // wrong-tap red shake, decays to 0
  _FieldAtom(this.pos, this.vel, this.element, this.wobble);
}

class _FlyingAtom {
  final int element;
  final Offset from;
  final int slotIndex;
  double t = 0; // 0..1
  _FlyingAtom(this.element, this.from, this.slotIndex);
}

class _Particle {
  Offset pos;
  Offset vel;
  double t = 0; // 0..1 life
  final Color color;
  final double size;
  _Particle(this.pos, this.vel, this.color, this.size);
}

class _Popup {
  final String text;
  final Offset pos;
  final Color color;
  double t = 0; // 0..1 life
  _Popup(this.text, this.pos, this.color);
}

// ---------------------------------------------------------------------------
// Game widget
// ---------------------------------------------------------------------------

class MoleculeMixerGame extends StatefulWidget {
  final MiniGameSession session;
  const MoleculeMixerGame({Key? key, required this.session}) : super(key: key);

  @override
  State<MoleculeMixerGame> createState() => _MoleculeMixerGameState();
}

class _MoleculeMixerGameState extends State<MoleculeMixerGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  final math.Random _rng = math.Random();

  double _clock = 0; // always advances (shimmer, bond anims)
  double _elapsed = 0; // advances only while running (difficulty ramp)

  late _MoleculeDef _target;
  late List<_Slot> _slots;
  /// Slot index of the backbone atom, or null if this molecule is ungated.
  int? _backbone;
  int _completedCount = 0;

  final List<_FieldAtom> _atoms = [];
  final List<_FlyingAtom> _flying = [];
  final List<_Particle> _particles = [];
  final List<_Popup> _popups = [];

  /// Celebration timeline; -1 = inactive, otherwise seconds since completion.
  double _celebT = -1;

  /// Backbone pulse intensity (1 → 0). Set to 1 when the player taps a
  /// peripheral before the backbone; decays to 0 over ~0.7 s.
  double _backbonePulse = 0;

  // ── Molecule fun-fact flare ───────────────────────────────────────────────
  /// Formula strings whose fact card has already been shown this session.
  final Set<String> _seenFacts = {};

  /// Age of the currently-showing fact card (seconds). -1 = hidden.
  double _factAge = -1;

  /// The fact entry currently displayed (null when hidden).
  MoleculeFact? _factEntry;

  /// Total display window for the fact card (seconds).
  static const double _kFactDuration = 3.2;
  // ─────────────────────────────────────────────────────────────────────────

  Size? _fieldSize;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _target = _molecules[_rng.nextInt(_molecules.length)];
    _slots = _target.slots.map((d) => _Slot(d)).toList();
    _backbone = _backboneSlot(_target);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

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

  // ------------------------------------------------------------------ sim --

  double get _speedMul {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return 1.0 + (_elapsed / dur).clamp(0.0, 1.0) * 0.7;
  }

  Rect get _bounds {
    final s = _fieldSize ?? Size.zero;
    return Rect.fromLTRB(12, _kPanelReserve + 8, s.width - 12, s.height - 12);
  }

  Offset get _buildCenter {
    final s = _fieldSize ?? const Size(360, 640);
    return Offset(
        s.width * 0.5, _kPanelReserve + (s.height - _kPanelReserve) * 0.52);
  }

  double get _unit {
    final s = _fieldSize ?? const Size(360, 640);
    return (math.min(s.width, s.height - _kPanelReserve) * 0.115)
        .clamp(26.0, 42.0);
  }

  Offset _slotWorld(_Slot slot) =>
      _buildCenter + slot.def.offset * _unit * 1.6;

  void _update(double dt) {
    final b = _bounds;
    if (b.isEmpty) return;

    // Keep the gas alive: ~10-14 atoms at once.
    while (_atoms.length < 12) {
      _spawnAtom(fromEdge: true);
    }

    // Drift + soft bounce.
    for (final a in _atoms) {
      a.wobble += dt * 2.2;
      final wob = Offset(
          math.sin(a.wobble * 1.3 + a.vel.dx) * 6,
          math.cos(a.wobble + a.vel.dy) * 6);
      a.pos += (a.vel + wob) * dt * _speedMul;
      if (a.pos.dx < b.left + _kAtomR && a.vel.dx < 0) {
        a.vel = Offset(-a.vel.dx, a.vel.dy);
      }
      if (a.pos.dx > b.right - _kAtomR && a.vel.dx > 0) {
        a.vel = Offset(-a.vel.dx, a.vel.dy);
      }
      if (a.pos.dy < b.top + _kAtomR && a.vel.dy < 0) {
        a.vel = Offset(a.vel.dx, -a.vel.dy);
      }
      if (a.pos.dy > b.bottom - _kAtomR && a.vel.dy > 0) {
        a.vel = Offset(a.vel.dx, -a.vel.dy);
      }
      if (a.shake > 0) a.shake = math.max(0, a.shake - dt * 2.6);
    }

    // Atoms flying into the construction zone.
    for (final f in List<_FlyingAtom>.from(_flying)) {
      f.t += dt / 0.38;
      if (f.t >= 1) {
        _flying.remove(f);
        _arrive(f);
      }
    }

    // Particles + popups.
    for (final p in List<_Particle>.from(_particles)) {
      p.t += dt / 0.6;
      if (p.t >= 1) {
        _particles.remove(p);
      } else {
        p.pos += p.vel * dt;
        p.vel *= math.pow(0.04, dt).toDouble(); // drag
      }
    }
    for (final p in List<_Popup>.from(_popups)) {
      p.t += dt / 0.9;
      if (p.t >= 1) _popups.remove(p);
    }

    // Celebration timeline.
    if (_celebT >= 0) {
      _celebT += dt;
      if (_celebT >= 1.35) {
        _celebT = -1;
        _nextTarget();
      }
    }

    // Backbone pulse decay.
    if (_backbonePulse > 0) {
      _backbonePulse = math.max(0, _backbonePulse - dt / 0.7);
    }

    // Fact-flare card age advance + auto-dismiss.
    if (_factAge >= 0) {
      _factAge += dt;
      if (_factAge > _kFactDuration) {
        _factAge = -1;
        _factEntry = null;
      }
    }
  }

  void _arrive(_FlyingAtom f) {
    final slot = _slots[f.slotIndex];
    slot.state = 2;
    slot.fillTime = _clock;
    final at = _slotWorld(slot);
    _burst(at, _elements[slot.def.element].color, count: 6, speed: 60);
    _burst(at, _kAccent, count: 4, speed: 90);
    if (_celebT < 0 && _slots.every((s) => s.state == 2)) {
      widget.session.addScore(30);
      widget.session.addTime(const Duration(seconds: _kMoleculeTimeBonus));
      _completedCount++;
      _popups.add(_Popup('+30', _buildCenter.translate(0, -_unit * 2.2),
          const Color(0xFFFFD54F)));
      _popups.add(_Popup('+${_kMoleculeTimeBonus}s',
          _buildCenter.translate(0, -_unit * 3.4),
          const Color(0xFF69F0AE)));
      _burst(_buildCenter, _kAccent, count: 16, speed: 140);
      _celebT = 0;
      _checkFact(_target.formula);
    }
  }

  /// Called once per molecule completion. Fires the fact card the first time
  /// [formula] is completed in a session; subsequent completions of the same
  /// molecule are skipped (_seenFacts guards re-trigger). Non-scoring.
  void _checkFact(String formula) {
    if (_seenFacts.contains(formula)) return;
    final entry = factForFormula(formula);
    if (entry == null) return;
    _seenFacts.add(formula);
    _factEntry = entry;
    _factAge = 0;
  }

  void _nextTarget() {
    var pool = _molecules.where((m) => m != _target).toList();
    // Difficulty ramp: later targets favor 4-5 atom molecules.
    final advBias = _elapsed > 18 || _completedCount >= 3;
    if (advBias && _rng.nextDouble() < 0.65) {
      final adv = pool.where((m) => m.advanced).toList();
      if (adv.isNotEmpty) pool = adv;
    }
    _target = pool[_rng.nextInt(pool.length)];
    _slots = _target.slots.map((d) => _Slot(d)).toList();
    _backbone = _backboneSlot(_target);
    _ensureSupply(); // flood in the parts for the new compound
  }

  List<int> get _neededElements => _slots
      .where((s) => s.state == 0)
      .map((s) => s.def.element)
      .toSet()
      .toList();

  void _spawnAtom({bool fromEdge = false, bool anywhere = false, int? element}) {
    final b = _bounds;
    if (b.isEmpty) return;
    // Forced element wins; otherwise bias ~60% toward what's still needed.
    final needed = _neededElements;
    int el;
    if (element != null) {
      el = element;
    } else if (needed.isNotEmpty && _rng.nextDouble() < 0.6) {
      el = needed[_rng.nextInt(needed.length)];
    } else {
      el = _rng.nextInt(_elements.length);
    }
    Offset pos;
    if (anywhere || !fromEdge) {
      pos = Offset(b.left + _rng.nextDouble() * b.width,
          b.top + _rng.nextDouble() * b.height);
    } else {
      // Enter from a random edge, drifting inward.
      final side = _rng.nextInt(4);
      switch (side) {
        case 0:
          pos = Offset(b.left + _kAtomR, b.top + _rng.nextDouble() * b.height);
          break;
        case 1:
          pos = Offset(b.right - _kAtomR, b.top + _rng.nextDouble() * b.height);
          break;
        case 2:
          pos = Offset(b.left + _rng.nextDouble() * b.width, b.top + _kAtomR);
          break;
        default:
          pos =
              Offset(b.left + _rng.nextDouble() * b.width, b.bottom - _kAtomR);
      }
    }
    final ang = _rng.nextDouble() * math.pi * 2;
    final speed = 22 + _rng.nextDouble() * 20;
    _atoms.add(_FieldAtom(pos, Offset(math.cos(ang), math.sin(ang)) * speed,
        el, _rng.nextDouble() * math.pi * 2));
  }

  /// Guarantees the field holds more than enough of every atom the current
  /// target needs — called when a new molecule is set (and on first seed), so a
  /// fresh compound always has the parts to build it. Floods in from the edges:
  /// each required element topped to (count + buffer), plus a little variety.
  void _ensureSupply() {
    if (_bounds.isEmpty) return;
    final need = <int, int>{};
    for (final s in _slots) {
      need[s.def.element] = (need[s.def.element] ?? 0) + 1;
    }
    // Cull crowding first: drop atoms the new target doesn't need.
    if (_atoms.length > 14) {
      final spare =
          _atoms.where((a) => !need.containsKey(a.element)).toList();
      for (final a in spare) {
        if (_atoms.length <= 12) break;
        _atoms.remove(a);
      }
    }
    final have = <int, int>{};
    for (final a in _atoms) {
      have[a.element] = (have[a.element] ?? 0) + 1;
    }
    const buffer = 2; // a couple spare of each, so you never come up short
    need.forEach((element, count) {
      for (var i = have[element] ?? 0; i < count + buffer; i++) {
        _spawnAtom(fromEdge: true, element: element);
      }
    });
    // A pinch of variety (decoys) — not too many.
    for (var i = 0; i < 2; i++) {
      _spawnAtom(fromEdge: true);
    }
  }

  void _seedField() {
    if (_seeded || _bounds.isEmpty) return;
    _seeded = true;
    for (var i = 0; i < 12; i++) {
      _spawnAtom(anywhere: true);
    }
    _ensureSupply(); // make sure the very first molecule is buildable
  }

  void _burst(Offset at, Color color, {int count = 8, double speed = 100}) {
    for (var i = 0; i < count; i++) {
      final ang = _rng.nextDouble() * math.pi * 2;
      final v = Offset(math.cos(ang), math.sin(ang)) *
          (speed * (0.5 + _rng.nextDouble()));
      _particles.add(
          _Particle(at, v, color, 2.0 + _rng.nextDouble() * 3.0));
    }
  }

  // ----------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _celebT >= 0) return;
    final p = d.localPosition;
    _FieldAtom? best;
    var bestDist = double.infinity;
    for (final a in _atoms) {
      final dist = (a.pos - p).distance;
      if (dist <= _kHitR && dist < bestDist) {
        best = a;
        bestDist = dist;
      }
    }
    if (best == null) return;

    final slotIdx = _slots.indexWhere(
        (s) => s.state == 0 && s.def.element == best!.element);
    if (slotIdx >= 0) {
      // Backbone gate: the backbone slot must be filled before any peripheral.
      final bb = _backbone;
      if (bb != null && slotIdx != bb && _slots[bb].state == 0) {
        // Sequencing violation — no penalty, just guidance.
        _popups.add(_Popup(
          'BACKBONE FIRST',
          best.pos.translate(0, -_kAtomR - 6),
          const Color(0xFFFFB300),
        ));
        // Pulse the backbone slot world position so the painter can highlight it.
        _backbonePulse = 1.0;
        return;
      }
      // Needed atom: claim slot, fly it in.
      _slots[slotIdx].state = 1;
      widget.session.addScore(5);
      _popups.add(_Popup('+5', best.pos.translate(0, -_kAtomR - 6),
          const Color(0xFF69F0AE)));
      _burst(best.pos, _elements[best.element].color, count: 8, speed: 110);
      _flying.add(_FlyingAtom(best.element, best.pos, slotIdx));
      _atoms.remove(best);
    } else {
      // Unneeded atom: penalty + red shake.
      widget.session.addScore(-10);
      _popups.add(_Popup('-10', best.pos.translate(0, -_kAtomR - 6),
          const Color(0xFFFF5252)));
      best.shake = 1.0;
    }
  }

  // ----------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      _seedField();
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  painter: _MixerPainter(this),
                  size: Size.infinite,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: IgnorePointer(child: _buildTargetPanel()),
            ),
            if (_celebT >= 0 && _celebT < 1.0) _buildBanner(),
            // Molecule fun-fact flare — bottom ribbon, auto-fading, non-scoring.
            if (_factAge >= 0 && _factEntry != null) _buildFactCard(),
          ],
        ),
      );
    });
  }

  Widget _buildTargetPanel() {
    // Distinct elements in order of first appearance.
    final order = <int>[];
    for (final s in _target.slots) {
      if (!order.contains(s.element)) order.add(s.element);
    }
    // The backbone element (if gated), used to mark it in the panel.
    final bb = _backbone;
    final backboneElement = bb != null ? _target.slots[bb].element : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
              color: _kAccent.withValues(alpha: 0.18),
              blurRadius: 16,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _target.formula,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: _kAccent.withValues(alpha: 0.9),
                        blurRadius: 12),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'TARGET',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _kAccent.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _target.name,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kAccent.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final e in order) ...[
                _elementSlots(e, isBackbone: e == backboneElement),
                const SizedBox(width: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _elementSlots(int element, {bool isBackbone = false}) {
    final def = _elements[element];
    final slots =
        _slots.where((s) => s.def.element == element).toList();
    // Determine whether the backbone slot for this element is still unfilled.
    final backboneFilled = _backbone != null && _slots[_backbone!].state > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          def.symbol,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: def.outlined ? Colors.white : def.color,
            shadows: [
              Shadow(color: def.color.withValues(alpha: 0.8), blurRadius: 8),
            ],
          ),
        ),
        // Backbone marker: a small amber "CORE" pill shown while the backbone
        // is still empty so the player knows what to place first.
        if (isBackbone && !backboneFilled) ...[
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.7),
                  width: 0.8),
            ),
            child: const Text(
              'CORE',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Color(0xFFFFB300),
              ),
            ),
          ),
        ],
        const SizedBox(width: 5),
        for (final s in slots)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.state > 0
                    ? def.color
                    : Colors.transparent,
                border: Border.all(
                    color: s.state > 0
                        ? def.color
                        : Colors.white.withValues(alpha: 0.45),
                    width: 1.4),
                boxShadow: s.state > 0
                    ? [
                        BoxShadow(
                            color: def.color.withValues(alpha: 0.7),
                            blurRadius: 6),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /// A fading two-line ribbon that shows what the completed molecule is and
  /// its role in potato biology. Non-scoring; never blocks input (IgnorePointer);
  /// fades in over 0.25 s, holds, then fades out over the last 0.6 s.
  Widget _buildFactCard() {
    final entry = _factEntry!;
    final t = _factAge;
    const fadeIn = 0.25;
    final fadeOut = _kFactDuration - 0.6;
    final opacity = t < fadeIn
        ? (t / fadeIn).clamp(0.0, 1.0)
        : t > fadeOut
            ? (1.0 - (t - fadeOut) / 0.6).clamp(0.0, 1.0)
            : 1.0;

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _kAccent.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                    color: _kAccent.withValues(alpha: 0.22),
                    blurRadius: 18),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.name.toUpperCase()}  —  ${entry.whatItIs}',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kAccent.withValues(alpha: 0.95),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '🥔  ${entry.potatoFact}',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final t = _celebT;
    final opacity = t < 0.15
        ? t / 0.15
        : t > 0.75
            ? ((1 - (t - 0.75) / 0.25).clamp(0.0, 1.0))
            : 1.0;
    final scale = 0.85 + 0.15 * (t < 0.2 ? t / 0.2 : 1.0);
    final center = _buildCenter;
    return Positioned(
      left: 0,
      right: 0,
      top: center.dy - _unit * 3.6 - 30,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.toDouble(),
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _kAccent.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withValues(alpha: 0.4),
                        blurRadius: 22),
                  ],
                ),
                child: Text(
                  '${_target.formula}  ${_target.name.toUpperCase()}!',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: _kAccent, blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _MixerPainter extends CustomPainter {
  final _MoleculeMixerGameState g;
  _MixerPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    _paintShimmer(canvas, size);
    _paintConstruction(canvas);
    _paintFieldAtoms(canvas);
    _paintFlying(canvas);
    _paintParticles(canvas);
    _paintPopups(canvas);
  }

  // Faint fluid background shimmer: slow drifting glow blobs.
  void _paintShimmer(Canvas canvas, Size size) {
    final t = g._clock;
    for (var i = 0; i < 4; i++) {
      final phase = i * 1.7;
      final cx = size.width * (0.5 + 0.38 * math.sin(t * 0.13 + phase * 2.1));
      final cy = size.height *
          (0.5 + 0.36 * math.cos(t * 0.1 + phase * 1.3 + i));
      final r = size.shortestSide * (0.34 + 0.1 * math.sin(t * 0.21 + phase));
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          _kAccent.withValues(alpha: 0.05 + 0.02 * math.sin(t * 0.5 + i)),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _paintConstruction(Canvas canvas) {
    final center = g._buildCenter;
    final unit = g._unit;
    final celebrating = g._celebT >= 0;

    // Celebration transform: pulse, then float away and fade.
    var alpha = 1.0;
    var scale = 1.0;
    var lift = 0.0;
    if (celebrating) {
      final t = g._celebT;
      if (t <= 0.45) {
        scale = 1.0 + 0.25 * math.sin(math.pi * t / 0.45);
      } else {
        final u = ((t - 0.45) / 0.9).clamp(0.0, 1.0);
        final ease = Curves.easeIn.transform(u);
        alpha = 1.0 - ease;
        lift = -150.0 * ease;
        scale = 1.0 + 0.08 * u;
      }
    }

    canvas.save();
    canvas.translate(center.dx, center.dy + lift);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    // Construction zone halo.
    final zoneR = unit * 2.6;
    canvas.drawCircle(
      center,
      zoneR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kAccent.withValues(alpha: 0.12 * alpha),
    );
    canvas.drawCircle(
      center,
      zoneR,
      Paint()
        ..shader = RadialGradient(colors: [
          _kAccent.withValues(alpha: 0.0),
          _kAccent.withValues(alpha: 0.05 * alpha),
        ]).createShader(Rect.fromCircle(center: center, radius: zoneR)),
    );

    // Bonds (under atoms) — glow lines drawing in once both ends are filled.
    for (final bond in g._target.bonds) {
      final a = g._slots[bond[0]];
      final b = g._slots[bond[1]];
      if (a.state != 2 || b.state != 2) continue;
      final start = g._slotWorld(a);
      final end = g._slotWorld(b);
      final since = g._clock - math.max(a.fillTime, b.fillTime);
      final p = (since / 0.35).clamp(0.0, 1.0);
      final tip = Offset.lerp(start, end, Curves.easeOut.transform(p))!;
      // Wide soft glow.
      canvas.drawLine(
        start,
        tip,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.4 * alpha)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Bright core, pulsing faintly once complete.
      final pulse = p >= 1 ? 0.75 + 0.25 * math.sin(g._clock * 6) : 1.0;
      canvas.drawLine(
        start,
        tip,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * pulse * alpha)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Slots: ghost outlines for empty/incoming, full atoms for filled.
    for (var i = 0; i < g._slots.length; i++) {
      final slot = g._slots[i];
      final at = g._slotWorld(slot);
      final def = _elements[slot.def.element];
      final isBackbone = g._backbone == i;
      if (slot.state == 2) {
        final since = g._clock - slot.fillTime;
        final pop = since < 0.25
            ? 1.0 + 0.3 * math.sin(math.pi * since / 0.25)
            : 1.0;
        _drawAtom(canvas, at, slot.def.element, _kAtomR * pop,
            alpha: alpha, glow: 1.0);
      } else {
        // Backbone pulse: bright amber ring animates when the player taps a
        // peripheral before placing the backbone.
        if (isBackbone && g._backbonePulse > 0) {
          final pulse = g._backbonePulse;
          final ring = _kAtomR * 0.85 + 7 * (1 - pulse);
          canvas.drawCircle(
            at,
            ring,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = const Color(0xFFFFB300).withValues(alpha: 0.9 * pulse * alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }

        // Ghost slot: faint dashed-feel ring + dim symbol.
        canvas.drawCircle(
          at,
          _kAtomR * 0.85,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isBackbone && slot.state == 0 ? 2.2 : 1.4
            ..color = isBackbone && slot.state == 0
                ? def.color.withValues(alpha: 0.6 * alpha)
                : def.color.withValues(alpha: 0.35 * alpha),
        );
        canvas.drawCircle(
          at,
          _kAtomR * 0.85,
          Paint()
            ..color = def.color.withValues(alpha: 0.07 * alpha),
        );
        _drawText(canvas, def.symbol, at, 14,
            Colors.white.withValues(alpha: 0.4 * alpha));
      }
    }

    canvas.restore();
  }

  void _paintFieldAtoms(Canvas canvas) {
    for (final a in g._atoms) {
      var at = a.pos;
      if (a.shake > 0) {
        at = at.translate(math.sin(a.shake * 32) * 4.5 * a.shake, 0);
      }
      _drawAtom(canvas, at, a.element, _kAtomR, glow: 0.6);
      if (a.shake > 0) {
        canvas.drawCircle(
          at,
          _kAtomR + 5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color =
                const Color(0xFFFF5252).withValues(alpha: 0.8 * a.shake)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  void _paintFlying(Canvas canvas) {
    for (final f in g._flying) {
      final slot = g._slots[f.slotIndex];
      final to = g._slotWorld(slot);
      final t = Curves.easeInOut.transform(f.t.clamp(0.0, 1.0));
      final base = Offset.lerp(f.from, to, t)!;
      // Slight arc for life.
      final arc = Offset(0, -28 * math.sin(math.pi * t));
      final at = base + arc;
      // Comet trail.
      canvas.drawCircle(
        at,
        _kAtomR + 6,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.25 * (1 - t) + 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      _drawAtom(canvas, at, f.element, _kAtomR * (1.0 - 0.15 * t), glow: 1.0);
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in g._particles) {
      final a = (1 - p.t).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * (1 - p.t * 0.5),
        Paint()..color = p.color.withValues(alpha: 0.85 * a),
      );
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in g._popups) {
      final a = (1 - p.t).clamp(0.0, 1.0);
      final at = p.pos.translate(0, -42 * Curves.easeOut.transform(p.t));
      _drawText(canvas, p.text, at, 19, p.color.withValues(alpha: a),
          shadows: [
            Shadow(color: p.color.withValues(alpha: 0.8 * a), blurRadius: 10),
          ]);
    }
  }

  void _drawAtom(Canvas canvas, Offset at, int element, double r,
      {double alpha = 1.0, double glow = 0.8}) {
    final def = _elements[element];
    // Glow halo.
    canvas.drawCircle(
      at,
      r + 4,
      Paint()
        ..color = def.color.withValues(alpha: 0.35 * glow * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Body with subtle 3D shading.
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(def.color, Colors.white, 0.35)!
                .withValues(alpha: alpha),
            def.color.withValues(alpha: alpha),
            Color.lerp(def.color, Colors.black, 0.3)!
                .withValues(alpha: alpha),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    if (def.outlined) {
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = Colors.white.withValues(alpha: 0.85 * alpha),
      );
    }
    _drawText(canvas, def.symbol, at, r * 0.78,
        def.textColor.withValues(alpha: alpha));
  }

  void _drawText(Canvas canvas, String text, Offset center, double size,
      Color color,
      {List<Shadow>? shadows}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MixerPainter oldDelegate) => true;
}
