import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

import '../../theme/potatuhs.dart' show Potatuhs;
import '../../games/atoms/atom_provenance.dart'
    show AtomProvenance, provenanceForZ;

const _kFont = Potatuhs.bodyFont; // Outfit
const Color _kAccent = Color(0xFF5C6BC0);
const Color _kProtonColor = Color(0xFFFF5252);
const Color _kNeutronColor = Color(0xFFB0BEC5);
const Color _kElectronColor = Color(0xFF40C4FF);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kWarn = Color(0xFFFFB300); // instability / "needs a nucleus"

// ── Element name table (Z = 1..54) ───────────────────────────────────────────
/// Each entry is [name, symbol]. Index 0 is unused (Z=0 = no element).
/// Z=1 → index 1 (Hydrogen), Z=54 → index 54 (Xenon).
const List<List<String>> _kElements = [
  ['', ''],            // 0 – placeholder
  ['HYDROGEN',   'H'],  // 1
  ['HELIUM',     'He'], // 2
  ['LITHIUM',    'Li'], // 3
  ['BERYLLIUM',  'Be'], // 4
  ['BORON',      'B'],  // 5
  ['CARBON',     'C'],  // 6
  ['NITROGEN',   'N'],  // 7
  ['OXYGEN',     'O'],  // 8
  ['FLUORINE',   'F'],  // 9
  ['NEON',       'Ne'], // 10
  ['SODIUM',     'Na'], // 11
  ['MAGNESIUM',  'Mg'], // 12
  ['ALUMINIUM',  'Al'], // 13
  ['SILICON',    'Si'], // 14
  ['PHOSPHORUS', 'P'],  // 15
  ['SULFUR',     'S'],  // 16
  ['CHLORINE',   'Cl'], // 17
  ['ARGON',      'Ar'], // 18
  ['POTASSIUM',  'K'],  // 19
  ['CALCIUM',    'Ca'], // 20
  ['SCANDIUM',   'Sc'], // 21
  ['TITANIUM',   'Ti'], // 22
  ['VANADIUM',   'V'],  // 23
  ['CHROMIUM',   'Cr'], // 24
  ['MANGANESE',  'Mn'], // 25
  ['IRON',       'Fe'], // 26
  ['COBALT',     'Co'], // 27
  ['NICKEL',     'Ni'], // 28
  ['COPPER',     'Cu'], // 29
  ['ZINC',       'Zn'], // 30
  ['GALLIUM',    'Ga'], // 31
  ['GERMANIUM',  'Ge'], // 32
  ['ARSENIC',    'As'], // 33
  ['SELENIUM',   'Se'], // 34
  ['BROMINE',    'Br'], // 35
  ['KRYPTON',    'Kr'], // 36
  ['RUBIDIUM',   'Rb'], // 37
  ['STRONTIUM',  'Sr'], // 38
  ['YTTRIUM',    'Y'],  // 39
  ['ZIRCONIUM',  'Zr'], // 40
  ['NIOBIUM',    'Nb'], // 41
  ['MOLYBDENUM', 'Mo'], // 42
  ['TECHNETIUM', 'Tc'], // 43
  ['RUTHENIUM',  'Ru'], // 44
  ['RHODIUM',    'Rh'], // 45
  ['PALLADIUM',  'Pd'], // 46
  ['SILVER',     'Ag'], // 47
  ['CADMIUM',    'Cd'], // 48
  ['INDIUM',     'In'], // 49
  ['TIN',        'Sn'], // 50
  ['ANTIMONY',   'Sb'], // 51
  ['TELLURIUM',  'Te'], // 52
  ['IODINE',     'I'],  // 53
  ['XENON',      'Xe'], // 54
];

/// Returns "NAME · SYM" for the element with atomic number [z],
/// or null when [z] is 0 (nothing built yet).
String? _elementLabel(int z) {
  if (z <= 0 || z >= _kElements.length) return null;
  final e = _kElements[z];
  return '${e[0]} · ${e[1]}';
}

// ── Fertilizer banking ────────────────────────────────────────────────────────
// The four potato macronutrients are auto-banked when the proton count passes
// their atomic number. Each adds _kFertilizerBonus to the final score.
// Tune _kFertilizerBonus freely — all four banked = 4× the bonus.
const int _kFertilizerBonus = 25; // points per banked nutrient (all 4 → +100)

// Atomic numbers at which each nutrient is banked (crossed on proton increment).
const Map<String, int> _kNutrientAtomicNumbers = {
  'N': 7,  // Nitrogen
  'P': 15, // Phosphorus
  'S': 16, // Sulfur
  'K': 19, // Potassium
};

// Display order for the FERTILIZER indicator row.
const List<String> _kNutrientOrder = ['N', 'P', 'S', 'K'];
// ──────────────────────────────────────────────────────────────────────────────

// Nuclear stability: protons repel, neutrons are the strong-force glue.
// When unpaired protons (gotP - gotN) build up past this, the core starts to
// destabilise; left unbalanced long enough, a proton decays away.
const int _kStableExcess = 1; // 1 unpaired proton is fine (hydrogen-1)
const double _kInstabilityGain = 0.34; // per excess-proton, per second
const double _kInstabilityRecover = 0.7; // per second once balanced

// Field dynamics. Particles now fly in from every edge with velocity and feel
// forces, so the screen reads as a living swarm instead of a tidy waterfall.
const double _kElectronPull = 5200.0; // electron→proton attraction strength
const double _kNucleusPull = 26.0; // built nucleus's tug on free electrons
const double _kNeutronBreakRadius = 50.0; // free neutrons scatter within this
const double _kNeutronBreakForce = 520.0; // how hard they shove things away
const double _kMaxSpeed = 300.0; // velocity clamp so nothing flings off
const double _kParticleLifetime = 11.0; // seconds before a stray despawns

enum _ParticleKind { proton, neutron, electron }

/// A noble-gas checkpoint. In the game's clean model protons = neutrons =
/// electrons = [count]; reaching it completes a full electron shell.
class _Noble {
  final String name;
  final String symbol;
  final int count; // cumulative p = n = e at this checkpoint
  const _Noble(this.name, this.symbol, this.count);
}

/// The ladder: build ONE continuously-growing atom up through the noble
/// gases. You can't begin a shell until the one below it is perfectly
/// balanced (p = n = e at that checkpoint).
const List<_Noble> _kNobles = [
  _Noble('HELIUM', 'He', 2),
  _Noble('NEON', 'Ne', 10),
  _Noble('ARGON', 'Ar', 18),
  _Noble('KRYPTON', 'Kr', 36),
  _Noble('XENON', 'Xe', 54),
];

/// Electron capacity per shell (period model). Cumulative sums land on the
/// noble gases: 2, 10, 18, 36, 54. Drives both the gating and the drawing.
const List<int> _kShellCaps = [2, 8, 8, 18, 18];

/// A free particle drifting across the field. Unlike the old "falls straight
/// down" model, these stream in from any edge with a velocity vector, then
/// respond to forces: electrons are pulled toward protons, and free neutrons
/// shove everything nearby away as they barrel through.
class _FieldParticle {
  _ParticleKind kind;
  double x;
  double y;
  double vx;
  double vy;
  double phase; // glow pulse phase seed
  double life = 0; // seconds alive, for off-screen despawn
  bool dead = false;
  _FieldParticle({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.phase,
  });
}

class _Flier {
  final _ParticleKind kind;
  final Offset from;
  double t = 0; // 0..1 flight progress
  _Flier({required this.kind, required this.from});
}

class _Popup {
  final String text;
  final Color color;
  final Offset pos;
  final double scale;
  double age = 0;
  _Popup(this.text, this.color, this.pos, {this.scale = 1});
}

class _BurstSpark {
  final Offset origin;
  final double angle;
  final double speed;
  final Color color;
  double age = 0;
  _BurstSpark(this.origin, this.angle, this.speed, this.color);
}

class AtomBuilderGame extends StatefulWidget {
  final MiniGameSession session;
  const AtomBuilderGame({Key? key, required this.session}) : super(key: key);

  @override
  State<AtomBuilderGame> createState() => _AtomBuilderGameState();
}

class _AtomBuilderGameState extends State<AtomBuilderGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0; // always-running visual clock (orbits, glow pulses)
  double _runTime = 0; // gameplay time, advances only while running
  double _spawnAccum = 0;

  /// Rises each time you collect, decays over time. Drives the spawn rate and
  /// particle speed, so a hot streak floods the field and lets a sharp player
  /// climb further up the noble ladder — "fill fast, they come faster."
  double _tempo = 0;

  int _nobleIndex = 0; // next noble-gas checkpoint to reach
  int _gotP = 0;
  int _gotN = 0;
  int _gotE = 0;

  final List<_FieldParticle> _particles = [];
  final List<_Flier> _fliers = [];
  final List<_Popup> _popups = [];
  final List<_BurstSpark> _sparks = [];

  double _flashAlpha = 0; // red error flash
  double _bannerAge = -1; // >=0 while completion banner is showing
  String _bannerText = '';
  double _nucleusKick = 0; // wobble impulse when a particle lands
  double _instability = 0; // 0..1 — fills when protons outnumber neutrons

  // ── Fertilizer state ────────────────────────────────────────────────────────
  /// Which nutrient symbols have already been banked this game.
  /// Checked in the UI to light up the N P S K indicator row.
  final Set<String> _bankedNutrients = {};
  // ──────────────────────────────────────────────────────────────────────────

  // ── Cosmic provenance flare ──────────────────────────────────────────────
  /// Z values whose provenance card has already been shown this session.
  final Set<int> _seenProvenance = {};

  /// Age of the currently-showing provenance card (seconds). -1 = hidden.
  double _provAge = -1;

  /// The provenance entry currently displayed (null when hidden).
  AtomProvenance? _provEntry;

  /// Total display window for the provenance card (seconds).
  static const double _kProvDuration = 3.2;
  // ────────────────────────────────────────────────────────────────────────

  Size _fieldSize = Size.zero;

  _Noble get _target => _kNobles[_nobleIndex];

  /// Current shell ceiling: you can only collect particles up to the next
  /// noble checkpoint, so the shell above stays locked until this one is full.
  int get _cap => _target.count;

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
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Atom Builder *correctly*,
  /// never randomly: it scans the free particles on the field, keeps only the
  /// kinds the current noble target still needs (and, for electrons, only when
  /// the nucleus has a spare proton to hold one — otherwise catching it is the
  /// "NEEDS A PROTON" penalty), then catches the single most urgent one: the
  /// particle closest to despawning (greatest [_FieldParticle.life]). It fires
  /// the same [_collectParticle] handler a real tap uses, so scoring, fertilizer
  /// banking and shell completion all run identically. It NEVER catches a kind
  /// the target doesn't need (that's −10); if none is on screen it simply waits.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    _FieldParticle? best;
    for (final p in _particles) {
      if (!_kindNeeded(p.kind)) continue;
      // Most urgent = closest to leaving the field (greatest life). Strict >
      // keeps the first among ties, so the choice is deterministic.
      if (best == null || p.life > best.life) best = p;
    }
    if (best == null) return; // nothing needed on screen — never grab a wrong one
    _collectParticle(best);
  }

  /// Whether a particle of [kind] is currently a safe, scoring catch — i.e. the
  /// target still needs it. Electrons only count when there is a free proton for
  /// them to orbit ([_gotE] < [_gotP]); otherwise the game penalises the grab.
  bool _kindNeeded(_ParticleKind kind) {
    switch (kind) {
      case _ParticleKind.proton:
        return _gotP < _cap;
      case _ParticleKind.neutron:
        return _gotN < _cap;
      case _ParticleKind.electron:
        return _gotE < _cap && _gotE < _gotP;
    }
  }

  // ---------------------------------------------------------------- loop --

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    if (widget.session.isRunning) {
      _runTime += dt;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    final size = _fieldSize;
    if (size == Size.zero) return;

    // Pace is driven by the hottest of: elapsed time, your collection tempo,
    // and how much you've already built — whichever is pushing hardest. So a
    // skilled streak escalates the swarm (more particles, faster) instead of
    // the game only ramping on a fixed clock.
    final total = widget.session.spec.durationSeconds.toDouble();
    final timeRamp = (_runTime / total).clamp(0.0, 1.0);
    _tempo = math.max(0.0, _tempo - dt * 0.16);
    final built = ((_gotP + _gotN + _gotE) / 24.0).clamp(0.0, 1.0);
    final drive = math.max(timeRamp, math.max(_tempo, built));
    final baseSpeed = 95.0 + 150.0 * drive;
    final spawnEvery = (0.60 - 0.42 * drive).clamp(0.14, 0.60);

    // Spawn from the edges.
    _spawnAccum += dt;
    while (_spawnAccum >= spawnEvery) {
      _spawnAccum -= spawnEvery;
      _spawnParticle(size, baseSpeed, drive);
    }

    _applyForces(dt, size);

    // Integrate, clamp speed, despawn strays.
    for (final p in _particles) {
      final sp = math.sqrt(p.vx * p.vx + p.vy * p.vy);
      if (sp > _kMaxSpeed) {
        p.vx *= _kMaxSpeed / sp;
        p.vy *= _kMaxSpeed / sp;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life += dt;
      const m = 70.0;
      if (p.x < -m ||
          p.x > size.width + m ||
          p.y < -m ||
          p.y > size.height + m ||
          p.life > _kParticleLifetime) {
        p.dead = true;
      }
    }
    _particles.removeWhere((p) => p.dead);

    // Fliers toward the atom.
    for (final f in _fliers) {
      f.t += dt / 0.38;
    }
    _fliers.removeWhere((f) {
      if (f.t >= 1) {
        _nucleusKick = 1;
        return true;
      }
      return false;
    });

    // Popups, sparks, flash, banner, wobble decay.
    for (final pop in _popups) {
      pop.age += dt;
    }
    _popups.removeWhere((p) => p.age > 0.9);
    for (final s in _sparks) {
      s.age += dt;
    }
    _sparks.removeWhere((s) => s.age > 0.7);
    _flashAlpha = math.max(0, _flashAlpha - dt * 2.6);
    _nucleusKick = math.max(0, _nucleusKick - dt * 3.2);
    if (_bannerAge >= 0) {
      _bannerAge += dt;
      if (_bannerAge > 1.4) _bannerAge = -1;
    }
    if (_provAge >= 0) {
      _provAge += dt;
      if (_provAge > _kProvDuration) {
        _provAge = -1;
        _provEntry = null;
      }
    }

    _simulateStability(dt);
  }

  /// Unpaired protons repel; without neutron glue the core grows unstable and
  /// eventually a proton decays away. Balanced cores (neutrons ≥ protons) are
  /// rock-solid, so good play is never punished — only greedy proton-grabbing.
  void _simulateStability(double dt) {
    final excess = _gotP - _gotN;
    if (excess > _kStableExcess) {
      _instability += dt * (excess - _kStableExcess) * _kInstabilityGain;
    } else {
      _instability = math.max(0, _instability - dt * _kInstabilityRecover);
    }

    if (_instability >= 1.0 && _gotP > 0) {
      // Beta-ish decay: shed one proton back out of the nucleus.
      _gotP--;
      // An electron with no proton left to orbit drifts off too.
      if (_gotE > _gotP) _gotE = _gotP;
      _instability = 0.45;
      _nucleusKick = 1;
      _flashAlpha = 0.5;
      _popups.add(_Popup('DECAY −1p', _kWarn,
          _atomCenter(_fieldSize) - const Offset(0, 54)));
      final origin = _atomCenter(_fieldSize);
      for (int i = 0; i < 10; i++) {
        final a = (i / 10) * math.pi * 2;
        _sparks.add(_BurstSpark(origin, a, 70 + _rng.nextDouble() * 60,
            _kProtonColor));
      }
    }
  }

  /// Electrons are drawn toward the nearest free proton (and toward the charged
  /// nucleus), so opposite charges visibly clump together — then free neutrons
  /// barrel through and scatter whatever they pass, breaking those clusters.
  void _applyForces(double dt, Size size) {
    final center = _atomCenter(size);
    for (final p in _particles) {
      if (p.kind != _ParticleKind.electron) continue;

      // Pull toward the nearest free proton.
      _FieldParticle? proton;
      double best = double.infinity;
      for (final q in _particles) {
        if (q.kind != _ParticleKind.proton) continue;
        final dx = q.x - p.x, dy = q.y - p.y;
        final d2 = dx * dx + dy * dy;
        if (d2 < best) {
          best = d2;
          proton = q;
        }
      }
      if (proton != null) {
        final dx = proton.x - p.x, dy = proton.y - p.y;
        final dist = math.sqrt(best).clamp(18.0, 1e9);
        final a = _kElectronPull / (dist * dist);
        p.vx += dx / dist * a * dt;
        p.vy += dy / dist * a * dt;
      }

      // Gentle tug toward the nucleus, stronger the more protons it holds.
      if (_gotP > 0) {
        final dx = center.dx - p.x, dy = center.dy - p.y;
        final dist = math.sqrt(dx * dx + dy * dy).clamp(40.0, 1e9);
        final a = _kNucleusPull * _gotP / dist;
        p.vx += dx / dist * a * dt;
        p.vy += dy / dist * a * dt;
      }
    }

    // Free neutrons shove nearby protons & electrons away — the "breaking".
    for (final n in _particles) {
      if (n.kind != _ParticleKind.neutron) continue;
      for (final o in _particles) {
        if (identical(o, n) || o.kind == _ParticleKind.neutron) continue;
        final dx = o.x - n.x, dy = o.y - n.y;
        final d2 = dx * dx + dy * dy;
        if (d2 < _kNeutronBreakRadius * _kNeutronBreakRadius && d2 > 1) {
          final dist = math.sqrt(d2);
          final push = _kNeutronBreakForce * (1 - dist / _kNeutronBreakRadius);
          o.vx += dx / dist * push * dt;
          o.vy += dy / dist * push * dt;
        }
      }
    }
  }

  void _spawnParticle(Size size, double baseSpeed, double drive) {
    final needed = <_ParticleKind>[
      if (_gotP < _cap) _ParticleKind.proton,
      if (_gotN < _cap) _ParticleKind.neutron,
      if (_gotE < _cap) _ParticleKind.electron,
    ];
    final notNeeded = _ParticleKind.values
        .where((k) => !needed.contains(k))
        .toList(growable: false);

    _ParticleKind kind;
    // At a high tempo, sprinkle extra free neutrons in as disruptors.
    if (drive > 0.3 && _rng.nextDouble() < 0.20 * drive) {
      kind = _ParticleKind.neutron;
    } else if (needed.isNotEmpty &&
        (_rng.nextDouble() < 0.65 || notNeeded.isEmpty)) {
      kind = needed[_rng.nextInt(needed.length)];
    } else if (notNeeded.isNotEmpty) {
      kind = notNeeded[_rng.nextInt(notNeeded.length)];
    } else {
      kind = _ParticleKind.values[_rng.nextInt(3)];
    }

    // Enter from a random edge.
    late double x, y;
    switch (_rng.nextInt(4)) {
      case 0: // top
        x = _rand(20, size.width - 20);
        y = -26;
        break;
      case 1: // bottom
        x = _rand(20, size.width - 20);
        y = size.height + 26;
        break;
      case 2: // left
        x = -26;
        y = _rand(20, size.height - 20);
        break;
      default: // right
        x = size.width + 26;
        y = _rand(20, size.height - 20);
    }

    // Aim across the field toward the atom, with spread so particles fan
    // through the play area instead of all converging on one point.
    final aim = _atomCenter(size) + Offset(_rand(-100, 100), _rand(-90, 90));
    var dx = aim.dx - x, dy = aim.dy - y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 0) {
      dx /= dist;
      dy /= dist;
    }
    var speed = baseSpeed * (0.8 + _rng.nextDouble() * 0.5);
    if (kind == _ParticleKind.neutron) speed *= 1.4; // neutrons come in hot

    _particles.add(_FieldParticle(
      kind: kind,
      x: x,
      y: y,
      vx: dx * speed,
      vy: dy * speed,
      phase: _rng.nextDouble() * math.pi * 2,
    ));
  }

  double _rand(double a, double b) => a + _rng.nextDouble() * (b - a);

  // ---------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    final tap = d.localPosition;

    _FieldParticle? hit;
    double bestDist = 48; // generous one-thumb hit radius
    for (final p in _particles) {
      final dist = (Offset(p.x, p.y) - tap).distance;
      if (dist < bestDist) {
        bestDist = dist;
        hit = p;
      }
    }
    if (hit == null) return;

    _collectParticle(hit);
  }

  /// Fold a single field particle into the atom — the shared outcome of both a
  /// player tap and the attract-mode autopilot. Applies the scoring rules (+5 for
  /// a needed particle, −10 for one the target doesn't need, −3 for an electron
  /// with no proton to orbit) and updates the nucleus / shell / fertilizer state.
  void _collectParticle(_FieldParticle hit) {
    hit.dead = true;

    // An electron needs a proton to orbit. You can't collect one onto an
    // empty core, and electrons can never outnumber protons — so the shell
    // can only grow once the nucleus has the charge to hold it.
    if (hit.kind == _ParticleKind.electron &&
        _gotE < _cap &&
        _gotE >= _gotP) {
      widget.session.addScore(-3);
      _flashAlpha = 0.4;
      _popups.add(_Popup('NEEDS A PROTON', _kWarn, Offset(hit.x, hit.y)));
      return;
    }

    bool needsIt;
    switch (hit.kind) {
      case _ParticleKind.proton:
        needsIt = _gotP < _cap;
        break;
      case _ParticleKind.neutron:
        needsIt = _gotN < _cap;
        break;
      case _ParticleKind.electron:
        needsIt = _gotE < _cap;
        break;
    }

    if (needsIt) {
      widget.session.addScore(5);
      _tempo = math.min(1.0, _tempo + 0.14); // a good grab speeds the swarm up
      _popups.add(_Popup('+5', _kGood, Offset(hit.x, hit.y)));
      _fliers.add(_Flier(kind: hit.kind, from: Offset(hit.x, hit.y)));
      switch (hit.kind) {
        case _ParticleKind.proton:
          _gotP++;
          _checkFertilizerCrossing(_gotP, Offset(hit.x, hit.y));
          _checkProvenance(_gotP);
          break;
        case _ParticleKind.neutron:
          _gotN++;
          break;
        case _ParticleKind.electron:
          _gotE++;
          break;
      }
      _checkComplete();
    } else {
      widget.session.addScore(-10);
      _flashAlpha = 0.55;
      _popups.add(_Popup('-10', _kBad, Offset(hit.x, hit.y)));
    }
  }

  /// Called each time a proton is successfully collected.
  /// Auto-banks any nutrient whose atomic number the new [protonCount] just
  /// crossed, emitting a celebratory popup and crediting the score bonus.
  void _checkFertilizerCrossing(int protonCount, Offset hitPos) {
    _kNutrientAtomicNumbers.forEach((symbol, atomicNum) {
      if (protonCount == atomicNum && !_bankedNutrients.contains(symbol)) {
        _bankedNutrients.add(symbol);
        widget.session.addScore(_kFertilizerBonus);

        // Celebratory popup — positioned above the tap, like existing popups.
        final names = {
          'N': 'NITROGEN',
          'P': 'PHOSPHORUS',
          'S': 'SULFUR',
          'K': 'POTASSIUM',
        };
        _popups.add(_Popup(
          '${names[symbol]} BANKED 🥔',
          _kGood,
          hitPos - const Offset(0, 30),
          scale: 1.1,
        ));

        // Flash the field green for a beat (reuse _flashAlpha channel via a
        // brief _bannerAge overlay isn't right — use a dedicated green flash).
        // We repurpose _bannerText + _bannerAge for this celebratory banner,
        // same as the noble-gas completion banner.
        _bannerText = '+$_kFertilizerBonus · ${names[symbol]} FERTILIZER 🥔';
        _bannerAge = 0;
      }
    });
  }

  /// Called the first time the player's proton count reaches a Z value that has
  /// a provenance entry. Starts a brief, non-scoring, auto-fading card overlay
  /// that shows where the element was forged and its potato role.
  /// Each Z fires at most once per session (_seenProvenance guards re-trigger).
  void _checkProvenance(int z) {
    if (_seenProvenance.contains(z)) return;
    final entry = provenanceForZ(z);
    if (entry == null) return;
    _seenProvenance.add(z);
    _provEntry = entry;
    _provAge = 0;
  }

  void _checkComplete() {
    // A noble checkpoint is reached only when the whole shell is perfectly
    // balanced — equal protons, neutrons and electrons at the cap.
    if (_gotP < _cap || _gotN < _cap || _gotE < _cap) return;

    widget.session.addScore(50);
    _bannerText = '${_target.name} — STABLE!';
    _bannerAge = 0;

    final origin = _atomCenter(_fieldSize);
    _popups.add(_Popup('+50', _kAccent, origin - const Offset(0, 60),
        scale: 1.6));
    for (int i = 0; i < 26; i++) {
      final a = (i / 26) * math.pi * 2;
      final colors = [_kProtonColor, _kNeutronColor, _kElectronColor, _kAccent];
      _sparks.add(_BurstSpark(
          origin, a, 120 + _rng.nextDouble() * 140, colors[i % colors.length]));
    }

    // The atom keeps growing — unlock the next shell, don't reset.
    if (_nobleIndex < _kNobles.length - 1) _nobleIndex++;
  }

  // Centered in the open play field — between the target panel (top) and the
  // fact card (bottom) — so the nucleus + orbits don't collide with either.
  Offset _atomCenter(Size size) =>
      Offset(size.width / 2, size.height * 0.5);

  // ---------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AtomFieldPainter(
                  clock: _clock,
                  gotP: _gotP,
                  gotN: _gotN,
                  gotE: _gotE,
                  shellCap: _cap,
                  falling: _particles,
                  fliers: _fliers,
                  popups: _popups,
                  sparks: _sparks,
                  flashAlpha: _flashAlpha,
                  nucleusKick: _nucleusKick,
                  instability: _instability,
                  atomCenter: _atomCenter(_fieldSize),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _TargetPanel(
                target: _target,
                cap: _cap,
                gotP: _gotP,
                gotN: _gotN,
                gotE: _gotE,
              ),
            ),
            if (_bannerAge >= 0) _buildBanner(),
            // Fertilizer indicator — bottom-left, unobtrusive.
            Positioned(
              bottom: 12,
              left: 12,
              child: _FertilizerIndicator(banked: _bankedNutrients),
            ),
            // Cosmic provenance flare — HUD ribbon above the fertilizer bar.
            if (_provAge >= 0 && _provEntry != null) _buildProvenanceCard(),
          ],
        ),
      );
    });
  }

  Widget _buildBanner() {
    // Pop in, hold, fade out.
    final t = _bannerAge;
    final opacity = t < 0.15
        ? t / 0.15
        : t > 1.0
            ? (1 - (t - 1.0) / 0.4).clamp(0.0, 1.0)
            : 1.0;
    final scale = t < 0.2 ? 0.7 + 0.3 * (t / 0.2) : 1.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity.toDouble(),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: _kAccent.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withValues(alpha: 0.5),
                        blurRadius: 30),
                  ],
                ),
                child: Text(
                  _bannerText,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [Shadow(color: _kAccent, blurRadius: 16)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A fading two-line ribbon that shows the cosmic origin of the newly-reached
  /// element and its potato role. Non-scoring; never blocks input (IgnorePointer);
  /// fades in over 0.25 s, holds, then fades out over the last 0.6 s.
  Widget _buildProvenanceCard() {
    final entry = _provEntry!;
    final t = _provAge;
    const fadeIn = 0.25;
    final fadeOut = _kProvDuration - 0.6;
    final opacity = t < fadeIn
        ? (t / fadeIn).clamp(0.0, 1.0)
        : t > fadeOut
            ? (1.0 - (t - fadeOut) / 0.6).clamp(0.0, 1.0)
            : 1.0;

    final roleText = entry.potatoRole;

    return Positioned(
      bottom: 56, // sits just above the fertilizer bar
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
                  color: _kElectronColor.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                    color: _kElectronColor.withValues(alpha: 0.22),
                    blurRadius: 18),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.name.toUpperCase()} · ${entry.symbol}  —  forged in ${entry.forgedIn}',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kElectronColor.withValues(alpha: 0.95),
                    letterSpacing: 0.6,
                  ),
                ),
                if (roleText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '🥔  $roleText',
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------- fertilizer UI --

/// A compact "N P S K" row that lights up as each nutrient is banked.
/// Lives in the bottom-left corner so it doesn't compete with the target panel.
class _FertilizerIndicator extends StatelessWidget {
  final Set<String> banked;
  const _FertilizerIndicator({required this.banked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGood.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FERTILIZER',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _kGood.withValues(alpha: 0.55),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 6),
          for (final sym in _kNutrientOrder) ...[
            _NutrientPip(symbol: sym, lit: banked.contains(sym)),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _NutrientPip extends StatelessWidget {
  final String symbol;
  final bool lit;
  const _NutrientPip({required this.symbol, required this.lit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? _kGood.withValues(alpha: 0.25) : Colors.transparent,
        border: Border.all(
          color: lit ? _kGood : _kGood.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: lit
            ? [BoxShadow(color: _kGood.withValues(alpha: 0.45), blurRadius: 8)]
            : null,
      ),
      child: Text(
        symbol,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: lit ? Colors.white : _kGood.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- target UI --

class _TargetPanel extends StatelessWidget {
  final _Noble target;
  final int cap;
  final int gotP;
  final int gotN;
  final int gotE;
  const _TargetPanel({
    required this.target,
    required this.cap,
    required this.gotP,
    required this.gotN,
    required this.gotE,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: _kAccent.withValues(alpha: 0.18), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withValues(alpha: 0.18),
              border: Border.all(color: _kAccent),
              boxShadow: [
                BoxShadow(
                    color: _kAccent.withValues(alpha: 0.4), blurRadius: 10),
              ],
            ),
            child: Text(
              target.symbol,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REACH ${target.name}',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
                if (_elementLabel(gotP) != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _elementLabel(gotP)!,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kAccent.withValues(alpha: 0.95),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    _ProgressChip(
                        label: 'p', got: gotP, need: cap, color: _kProtonColor),
                    const SizedBox(width: 8),
                    _ProgressChip(
                        label: 'n', got: gotN, need: cap, color: _kNeutronColor),
                    const SizedBox(width: 8),
                    _ProgressChip(
                        label: 'e', got: gotE, need: cap, color: _kElectronColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final int got;
  final int need;
  final Color color;
  const _ProgressChip({
    required this.label,
    required this.got,
    required this.need,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final done = need > 0 && got >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: done ? 0.3 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: done ? 1.0 : 0.5)),
      ),
      child: Text(
        '$label $got/$need',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: done ? Colors.white : color,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- painter --

class _AtomFieldPainter extends CustomPainter {
  final double clock;
  final int gotP;
  final int gotN;
  final int gotE;
  final int shellCap; // current noble-gas checkpoint count (p=n=e target)
  final List<_FieldParticle> falling;
  final List<_Flier> fliers;
  final List<_Popup> popups;
  final List<_BurstSpark> sparks;
  final double flashAlpha;
  final double nucleusKick;
  final double instability;
  final Offset atomCenter;

  _AtomFieldPainter({
    required this.clock,
    required this.gotP,
    required this.gotN,
    required this.gotE,
    required this.shellCap,
    required this.falling,
    required this.fliers,
    required this.popups,
    required this.sparks,
    required this.flashAlpha,
    required this.nucleusKick,
    required this.instability,
    required this.atomCenter,
  });

  static const double _particleRadius = 22;

  Color _kindColor(_ParticleKind k) {
    switch (k) {
      case _ParticleKind.proton:
        return _kProtonColor;
      case _ParticleKind.neutron:
        return _kNeutronColor;
      case _ParticleKind.electron:
        return _kElectronColor;
    }
  }

  String _kindLabel(_ParticleKind k) {
    switch (k) {
      case _ParticleKind.proton:
        return '+';
      case _ParticleKind.neutron:
        return 'n';
      case _ParticleKind.electron:
        return '−';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    _paintAtom(canvas, size);
    for (final p in falling) {
      _paintFalling(canvas, p);
    }
    for (final f in fliers) {
      _paintFlier(canvas, f);
    }
    for (final s in sparks) {
      _paintSpark(canvas, s);
    }
    for (final pop in popups) {
      _paintPopup(canvas, pop);
    }
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBad.withValues(alpha: flashAlpha * 0.30),
      );
    }
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    // Faint starfield-style dots, deterministic from index.
    final paint = Paint();
    for (int i = 0; i < 36; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 89) / 89.0;
      final tw = 0.5 + 0.5 * math.sin(clock * 1.3 + i * 1.7);
      paint.color = _kAccent.withValues(alpha: 0.05 + 0.07 * tw);
      canvas.drawCircle(
          Offset(fx * size.width, fy * size.height), 1.4 + tw, paint);
    }
  }

  // ------------------------------------------------------------- the atom --

  void _paintAtom(Canvas canvas, Size size) {
    // Landing kick + an erratic, fast jitter that grows with instability.
    final jitter = instability * 6.0;
    final wobble = Offset(
      math.sin(clock * 7.0) * 3.0 * nucleusKick +
          math.sin(clock * 31.0) * jitter,
      math.cos(clock * 8.5) * 3.0 * nucleusKick +
          math.cos(clock * 27.0) * jitter,
    );
    final c = atomCenter + wobble;
    final nucleons = gotP + gotN;

    // Ambient glow under the atom — flushes warning-amber as it destabilises.
    final glowColor = Color.lerp(_kAccent, _kWarn, instability)!;
    canvas.drawCircle(
      c,
      62,
      Paint()
        ..color = glowColor.withValues(alpha: 0.10 + 0.18 * instability)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    if (instability > 0.05) {
      // Pulsing "danger" ring around an unstable nucleus.
      canvas.drawCircle(
        c,
        30 + 4 * math.sin(clock * 12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kWarn.withValues(alpha: 0.25 + 0.5 * instability),
      );
    }

    // Electron shells fill in period order (2, 8, 8, 18, 18).
    // ── Pass 1: draw filled (active) shells ──
    final shellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    int remaining = gotE;
    int lastFilledShell = -1; // index of the last shell that has any electrons
    for (int s = 0; s < _kShellCaps.length && remaining >= 0; s++) {
      final radius = 40.0 + s * 21.0;
      final inShell = math.min(remaining, _kShellCaps[s]);
      remaining -= inShell;
      final active = inShell > 0;
      if (active) lastFilledShell = s;
      shellPaint.color =
          _kElectronColor.withValues(alpha: active ? 0.35 : 0.12);
      canvas.drawCircle(c, radius, shellPaint);

      final spin = clock * (1.4 - s * 0.35) * (s.isEven ? 1 : -1);
      for (int i = 0; i < inShell; i++) {
        final a = spin + (i / math.max(1, inShell)) * math.pi * 2;
        final pos = c + Offset(math.cos(a), math.sin(a)) * radius;
        canvas.drawCircle(
          pos,
          7,
          Paint()
            ..color = _kElectronColor.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(pos, 4.2, Paint()..color = _kElectronColor);
        canvas.drawCircle(
            pos, 1.8, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
      if (remaining <= 0 && s >= 1) break;
    }

    // ── Pass 2: faint rings for upcoming (not-yet-filled) shells ──
    // Determine how many shells the current checkpoint requires in total.
    int capAccum = 0;
    int totalShellsNeeded = 0;
    for (int s = 0; s < _kShellCaps.length; s++) {
      capAccum += _kShellCaps[s];
      totalShellsNeeded = s + 1;
      if (capAccum >= shellCap) break;
    }
    final previewPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int s = lastFilledShell + 1; s < totalShellsNeeded; s++) {
      final radius = 40.0 + s * 21.0;
      // Subtle dash-like stipple: draw a dashed circle via short arcs.
      previewPaint.color = _kElectronColor.withValues(alpha: 0.10);
      canvas.drawCircle(c, radius, previewPaint);
    }

    // Nucleus: protons + neutrons packed in a sunflower-spiral cluster.
    if (nucleons == 0) {
      // Empty-core hint ring.
      canvas.drawCircle(
        c,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _kAccent.withValues(alpha: 0.4),
      );
      return;
    }
    const nucleonR = 8.0;
    final golden = math.pi * (3 - math.sqrt(5));
    // Interleave p/n through the spiral for a mixed-looking core.
    final kinds = <Color>[];
    int pLeft = gotP, nLeft = gotN;
    while (pLeft > 0 || nLeft > 0) {
      if (pLeft > 0) {
        kinds.add(_kProtonColor);
        pLeft--;
      }
      if (nLeft > 0) {
        kinds.add(_kNeutronColor);
        nLeft--;
      }
    }
    for (int i = 0; i < nucleons; i++) {
      final color = kinds[i];
      final r = nucleonR * 0.95 * math.sqrt(i + 0.5);
      final a = i * golden + math.sin(clock * 2.2 + i) * 0.05;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(
        pos,
        nucleonR + 3,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(pos, nucleonR, Paint()..color = color);
      canvas.drawCircle(pos - const Offset(2, 2), 2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  // ------------------------------------------------------ falling particles --

  void _paintFalling(Canvas canvas, _FieldParticle p) {
    final color = _kindColor(p.kind);
    final pos = Offset(p.x, p.y);

    // Glow trail streaming out behind the particle's direction of travel.
    final vel = Offset(p.vx, p.vy);
    final vlen = vel.distance;
    final dir = vlen > 1 ? vel / vlen : const Offset(0, 1);
    for (int i = 1; i <= 4; i++) {
      final t = i / 4.0;
      canvas.drawCircle(
        pos - dir * (vlen * 0.06 * t),
        _particleRadius * (1 - 0.55 * t),
        Paint()
          ..color = color.withValues(alpha: 0.14 * (1 - t))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Pulsing halo.
    final pulse = 0.5 + 0.5 * math.sin(clock * 4 + p.phase);
    canvas.drawCircle(
      pos,
      _particleRadius + 6 + pulse * 3,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body.
    canvas.drawCircle(pos, _particleRadius, Paint()..color = color);
    canvas.drawCircle(
      pos,
      _particleRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawCircle(pos - const Offset(6, 7), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.3));

    _drawText(
      canvas,
      _kindLabel(p.kind),
      pos,
      fontSize: p.kind == _ParticleKind.neutron ? 20 : 24,
      color: Colors.black.withValues(alpha: 0.85),
      bold: true,
    );
  }

  void _paintFlier(Canvas canvas, _Flier f) {
    final t = f.t.clamp(0.0, 1.0);
    final eased = Curves.easeInQuad.transform(t);
    final pos = Offset.lerp(f.from, atomCenter, eased)!;
    final color = _kindColor(f.kind);
    final r = _particleRadius * (1 - 0.6 * t);
    canvas.drawCircle(
      pos,
      r + 6,
      Paint()
        ..color = color.withValues(alpha: 0.4 * (1 - t) + 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(pos, r, Paint()..color = color);
  }

  void _paintSpark(Canvas canvas, _BurstSpark s) {
    final t = (s.age / 0.7).clamp(0.0, 1.0);
    final dist = s.speed * s.age;
    final pos = s.origin + Offset(math.cos(s.angle), math.sin(s.angle)) * dist;
    canvas.drawCircle(
      pos,
      5 * (1 - t) + 1,
      Paint()
        ..color = s.color.withValues(alpha: (1 - t) * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintPopup(Canvas canvas, _Popup pop) {
    final t = (pop.age / 0.9).clamp(0.0, 1.0);
    final pos = pop.pos - Offset(0, 36 * Curves.easeOut.transform(t));
    _drawText(
      canvas,
      pop.text,
      pos,
      fontSize: 22 * pop.scale,
      color: pop.color.withValues(alpha: (1 - t).toDouble()),
      bold: true,
      glow: pop.color.withValues(alpha: (1 - t) * 0.8),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    bool bold = false,
    Color? glow,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          shadows:
              glow != null ? [Shadow(color: glow, blurRadius: 12)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AtomFieldPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME particle /
// atom recipes the live _AtomFieldPainter uses (colors, halos, glyphs,
// sunflower nucleus, electron shells). Static + cheap: intro only.
// ═══════════════════════════════════════════════════════════════════════════

void _legendText(
  Canvas canvas,
  String text,
  Offset center,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.bold,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// One free field particle, exactly as [_AtomFieldPainter._paintFalling] draws
/// it (minus the motion trail): halo, colored body, white rim, highlight, glyph.
void _legendParticle(Canvas canvas, Offset pos, _ParticleKind kind,
    {double radius = 22}) {
  final color = switch (kind) {
    _ParticleKind.proton => _kProtonColor,
    _ParticleKind.neutron => _kNeutronColor,
    _ParticleKind.electron => _kElectronColor,
  };
  canvas.drawCircle(
    pos,
    radius + 7,
    Paint()
      ..color = color.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  canvas.drawCircle(pos, radius, Paint()..color = color);
  canvas.drawCircle(
    pos,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.55),
  );
  canvas.drawCircle(pos - Offset(radius * 0.27, radius * 0.32), radius * 0.23,
      Paint()..color = Colors.white.withValues(alpha: 0.3));
  final label = switch (kind) {
    _ParticleKind.proton => '+',
    _ParticleKind.neutron => 'n',
    _ParticleKind.electron => '−',
  };
  _legendText(canvas, label, pos,
      kind == _ParticleKind.neutron ? radius * 0.9 : radius * 1.1,
      Colors.black.withValues(alpha: 0.85));
}

/// The built atom, mirroring [_AtomFieldPainter._paintAtom]: ambient glow
/// (amber-shifted by [instability]), electron shells in period order
/// ([_kShellCaps]), and the sunflower-spiral p/n nucleus.
void _legendAtom(
  Canvas canvas,
  Offset c, {
  required int protons,
  required int neutrons,
  required int electrons,
  double scale = 1.0,
  double instability = 0,
}) {
  if (scale <= 0) return;

  // Ambient glow — flushes warning-amber as the core destabilises.
  final glowColor = Color.lerp(_kAccent, _kWarn, instability)!;
  canvas.drawCircle(
    c,
    50 * scale,
    Paint()
      ..color = glowColor.withValues(alpha: 0.10 + 0.18 * instability)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
  );
  if (instability > 0.05) {
    canvas.drawCircle(
      c,
      30 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kWarn.withValues(alpha: 0.25 + 0.5 * instability),
    );
  }

  // Electron shells fill in period order (2, 8, 8, 18, 18).
  int remaining = electrons;
  final shellPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  for (int s = 0; s < _kShellCaps.length; s++) {
    final inShell = math.min(remaining, _kShellCaps[s]);
    remaining -= inShell;
    final radius = (34.0 + s * 16.0) * scale;
    shellPaint.color =
        _kElectronColor.withValues(alpha: inShell > 0 ? 0.35 : 0.12);
    canvas.drawCircle(c, radius, shellPaint);
    for (int i = 0; i < inShell; i++) {
      final a = s * 0.7 + (i / math.max(1, inShell)) * math.pi * 2;
      final pos = c + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawCircle(
        pos,
        6 * scale,
        Paint()
          ..color = _kElectronColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(pos, 4.0 * scale, Paint()..color = _kElectronColor);
      canvas.drawCircle(pos, 1.7 * scale,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
    if (remaining <= 0) break;
  }

  // Nucleus: protons + neutrons packed in the sunflower spiral.
  final nucleons = protons + neutrons;
  if (nucleons == 0) {
    canvas.drawCircle(
      c,
      10 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _kAccent.withValues(alpha: 0.4),
    );
    return;
  }
  final nucleonR = 7.5 * scale;
  final golden = math.pi * (3 - math.sqrt(5));
  final kinds = <Color>[];
  int pLeft = protons, nLeft = neutrons;
  while (pLeft > 0 || nLeft > 0) {
    if (pLeft > 0) {
      kinds.add(_kProtonColor);
      pLeft--;
    }
    if (nLeft > 0) {
      kinds.add(_kNeutronColor);
      nLeft--;
    }
  }
  for (int i = 0; i < nucleons; i++) {
    final r = nucleonR * 0.95 * math.sqrt(i + 0.5);
    final a = i * golden;
    final pos = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(
      pos,
      nucleonR + 2.5,
      Paint()
        ..color = kinds[i].withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(pos, nucleonR, Paint()..color = kinds[i]);
    canvas.drawCircle(pos - Offset(nucleonR * 0.25, nucleonR * 0.25),
        nucleonR * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.5));
  }
}

/// A HUD progress chip ("p 2/2"), same shape as [_ProgressChip].
void _legendChip(Canvas canvas, Offset center, String label, Color color,
    {double width = 52}) {
  final rect = Rect.fromCenter(center: center, width: width, height: 20);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
  canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.3));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color,
  );
  _legendText(canvas, label, center, 11, Colors.white);
}

// ── The frames ───────────────────────────────────────────────────────────────

/// (a) The core objects + the verb: the three particle kinds, tap to catch.
void _legendCatch(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final r = (w * 0.085).clamp(10.0, 24.0);
  final xs = [w * 0.22, w * 0.5, w * 0.78];
  const kinds = [
    _ParticleKind.proton,
    _ParticleKind.neutron,
    _ParticleKind.electron,
  ];
  const names = ['PROTON', 'NEUTRON', 'ELECTRON'];
  const colors = [_kProtonColor, _kNeutronColor, _kElectronColor];
  final cy = h * 0.40;
  for (int i = 0; i < 3; i++) {
    _legendParticle(canvas, Offset(xs[i], cy), kinds[i], radius: r);
    _legendText(canvas, names[i], Offset(xs[i], h * 0.68), 10, colors[i]);
  }
  // Tap-ripple cue on the proton.
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.8);
  canvas.drawCircle(Offset(xs[0], cy), r + 8, ring);
  ring.color = Colors.white.withValues(alpha: 0.35);
  canvas.drawCircle(Offset(xs[0], cy), r + 14, ring);
  _legendText(canvas, 'TAP TO CATCH', Offset(w * 0.5, h * 0.88), 11,
      Colors.white.withValues(alpha: 0.7));
}

/// (b) How to score: a perfectly balanced helium atom, +5 catches, +50 stable.
void _legendTarget(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final scale = (size.shortestSide / 200).clamp(0.4, 1.2);
  _legendAtom(canvas, Offset(w * 0.5, h * 0.42),
      protons: 2, neutrons: 2, electrons: 2, scale: scale);
  _legendText(canvas, '+5', Offset(w * 0.16, h * 0.18), 16, _kGood);
  _legendText(canvas, 'HELIUM — STABLE! +50', Offset(w * 0.5, h * 0.14), 12,
      _kAccent);
  final chipW = (w * 0.26).clamp(40.0, 56.0);
  final cy = h * 0.85;
  _legendChip(canvas, Offset(w * 0.22, cy), 'p 2/2', _kProtonColor,
      width: chipW);
  _legendChip(canvas, Offset(w * 0.5, cy), 'n 2/2', _kNeutronColor,
      width: chipW);
  _legendChip(canvas, Offset(w * 0.78, cy), 'e 2/2', _kElectronColor,
      width: chipW);
}

/// (c) The danger: a proton-heavy core jitters amber and decays; neutrons glue.
void _legendDecay(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final scale = (size.shortestSide / 210).clamp(0.4, 1.2);
  final core = Offset(w * 0.38, h * 0.46);
  _legendAtom(canvas, core,
      protons: 5, neutrons: 1, electrons: 2, scale: scale, instability: 0.85);
  _legendText(canvas, 'DECAY −1p', Offset(w * 0.38, h * 0.12), 13, _kWarn);

  // A neutron inbound to glue the core back together.
  final nr = (w * 0.06).clamp(8.0, 16.0);
  final nPos = Offset(w * 0.84, h * 0.46);
  _legendParticle(canvas, nPos, _ParticleKind.neutron, radius: nr);
  final arrow = Paint()
    ..color = _kNeutronColor.withValues(alpha: 0.8)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  final aFrom = Offset(nPos.dx - nr - 6, nPos.dy);
  final aTo = Offset(core.dx + 44 * scale, core.dy);
  canvas.drawLine(aFrom, aTo, arrow);
  canvas.drawLine(aTo, aTo + const Offset(8, -6), arrow);
  canvas.drawLine(aTo, aTo + const Offset(8, 6), arrow);

  _legendText(canvas, 'WRONG GRAB −10', Offset(w * 0.5, h * 0.88), 11, _kBad);
}

/// (d) The escalation: the noble-gas ladder — the atom keeps growing.
void _legendLadder(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final base = (size.shortestSide / 210).clamp(0.3, 1.0);
  final xs = [w * 0.18, w * 0.5, w * 0.84];
  final scales = [base * 0.42, base * 0.52, base * 0.62];
  const counts = [2, 10, 18]; // He, Ne, Ar — p = n = e at each checkpoint
  const symbols = ['He', 'Ne', 'Ar'];
  final cy = h * 0.42;
  final arrow = Paint()
    ..color = _kAccent.withValues(alpha: 0.7)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (int i = 0; i < 3; i++) {
    _legendAtom(canvas, Offset(xs[i], cy),
        protons: counts[i],
        neutrons: counts[i],
        electrons: counts[i],
        scale: scales[i]);
    _legendText(canvas, symbols[i], Offset(xs[i], h * 0.78), 12, _kAccent);
    if (i < 2) {
      final mx = (xs[i] + xs[i + 1]) / 2;
      canvas.drawLine(Offset(mx - 6, cy), Offset(mx + 6, cy), arrow);
      canvas.drawLine(Offset(mx + 6, cy), Offset(mx + 1, cy - 4), arrow);
      canvas.drawLine(Offset(mx + 6, cy), Offset(mx + 1, cy + 4), arrow);
    }
  }
  _legendText(canvas, 'THE SWARM SPEEDS UP', Offset(w * 0.5, h * 0.92), 10,
      Colors.white.withValues(alpha: 0.7));
}

/// The visual manual for Atom Builder — wired into the registry spec.
final List<LegendFrame> atomBuilderLegendFrames = [
  const LegendFrame(
      caption: 'Tap flying protons +, neutrons n, electrons −',
      paint: _legendCatch),
  const LegendFrame(
      caption: 'Balance p = n = e for the noble: +5, stable +50',
      paint: _legendTarget),
  const LegendFrame(
      caption: 'Extra protons decay the core — glue with neutrons',
      paint: _legendDecay),
  const LegendFrame(
      caption: 'Finish a shell to climb: He → Ne → Ar → Kr → Xe',
      paint: _legendLadder),
];
