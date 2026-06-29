import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart' show Potatuhs;

// ─────────────────────────────────────────────────────────────────────────────
// ISOTOPES — a build-a-spec nuclide puzzle.
//
// A prompt names a target nuclide ("Carbon-14", "Oxygen with 10 neutrons",
// "¹⁴C"). The player dials PROTONS and NEUTRONS with +/- steppers. Protons set
// the element (atomic number Z); protons + neutrons set the mass number A. When
// the build matches, LOCK IT IN. Score = nuclides built + speed bonus + streak.
//
// Education is in the mechanic: the element name/symbol updates live as you turn
// the proton dial (so you discover Z↔element), and the mass number A = Z+N reads
// out live as you turn the neutron dial (so you feel isotopes — same element,
// different neutrons). Prompts accelerate: explicit counts → named mass numbers →
// neutron counts → raw isotope notation, across a widening pool of elements.
// ─────────────────────────────────────────────────────────────────────────────

const String _kFont = Potatuhs.bodyFont; // Outfit

const Color _kAccent = Color(0xFF4DD0E1); // cyan — "science"
const Color _kProton = Color(0xFFFF5252); // red
const Color _kNeutron = Color(0xFFB0BEC5); // grey
const Color _kElectron = Color(0xFF82B1FF); // faint blue
const Color _kGood = Color(0xFF69F0AE); // match green
const Color _kBad = Color(0xFFFF5252); // error red

// Stepper bounds.
const int _kMaxProtons = 26;
const int _kMaxNeutrons = 40;

// Scoring.
const int _kBase = 10; // points for any correct lock
const int _kMaxSpeedBonus = 10; // extra for a fast lock
const double _kSpeedWindow = 7.0; // seconds of speed-bonus runway per prompt
const int _kMaxStreakBonus = 8; // streak score cap per lock

// ── Element name/symbol table, Z = 1..26 ─────────────────────────────────────
// Index 0 is a placeholder (Z=0 → "no element"). The readout uses this for ANY
// dialed Z so the player always sees what element they've made — that honesty
// is the teaching of "protons define the element".
const List<List<String>> _kElements = [
  ['', ''], // 0 — placeholder
  ['HYDROGEN', 'H'], // 1
  ['HELIUM', 'He'], // 2
  ['LITHIUM', 'Li'], // 3
  ['BERYLLIUM', 'Be'], // 4
  ['BORON', 'B'], // 5
  ['CARBON', 'C'], // 6
  ['NITROGEN', 'N'], // 7
  ['OXYGEN', 'O'], // 8
  ['FLUORINE', 'F'], // 9
  ['NEON', 'Ne'], // 10
  ['SODIUM', 'Na'], // 11
  ['MAGNESIUM', 'Mg'], // 12
  ['ALUMINIUM', 'Al'], // 13
  ['SILICON', 'Si'], // 14
  ['PHOSPHORUS', 'P'], // 15
  ['SULFUR', 'S'], // 16
  ['CHLORINE', 'Cl'], // 17
  ['ARGON', 'Ar'], // 18
  ['POTASSIUM', 'K'], // 19
  ['CALCIUM', 'Ca'], // 20
  ['SCANDIUM', 'Sc'], // 21
  ['TITANIUM', 'Ti'], // 22
  ['VANADIUM', 'V'], // 23
  ['CHROMIUM', 'Cr'], // 24
  ['MANGANESE', 'Mn'], // 25
  ['IRON', 'Fe'], // 26
];

String _nameForZ(int z) =>
    (z >= 1 && z < _kElements.length) ? _kElements[z][0] : '—';
String _symbolForZ(int z) =>
    (z >= 1 && z < _kElements.length) ? _kElements[z][1] : '—';

// ── Target pool: (Z, plausible neutron counts) ───────────────────────────────
// Real, recognisable isotopes. The pool widens with the player's level.
class _PoolEntry {
  final int z;
  final List<int> neutrons;
  const _PoolEntry(this.z, this.neutrons);
}

const List<_PoolEntry> _kPool = [
  _PoolEntry(1, [0, 1, 2]), // protium / deuterium / tritium
  _PoolEntry(2, [1, 2]), // He-3, He-4
  _PoolEntry(3, [3, 4]), // Li-6, Li-7
  _PoolEntry(4, [5]), // Be-9
  _PoolEntry(5, [5, 6]), // B-10, B-11
  _PoolEntry(6, [6, 7, 8]), // C-12, C-13, C-14
  _PoolEntry(7, [7, 8]), // N-14, N-15
  _PoolEntry(8, [8, 9, 10]), // O-16, O-17, O-18
  _PoolEntry(9, [10]), // F-19
  _PoolEntry(10, [10, 11, 12]), // Ne-20, Ne-21, Ne-22
  _PoolEntry(11, [12]), // Na-23
  _PoolEntry(12, [12, 13, 14]), // Mg-24, Mg-25, Mg-26
  _PoolEntry(13, [14]), // Al-27
  _PoolEntry(14, [14, 15, 16]), // Si-28, Si-29, Si-30
  _PoolEntry(15, [16]), // P-31
  _PoolEntry(16, [16, 17, 18]), // S-32, S-33, S-34
  _PoolEntry(17, [18, 20]), // Cl-35, Cl-37
  _PoolEntry(18, [18, 22]), // Ar-36, Ar-40
  _PoolEntry(19, [20, 22]), // K-39, K-41
  _PoolEntry(20, [20, 22, 24]), // Ca-40, Ca-42, Ca-44
  _PoolEntry(26, [28, 30, 32]), // Fe-54, Fe-56, Fe-58
];

/// How the prompt is phrased. Higher = harder (less is handed to the player).
enum _PromptKind { counts, massName, neutrons, symbol }

/// One target nuclide plus how it's posed.
class _Nuclide {
  final int z;
  final int n;
  final _PromptKind kind;
  const _Nuclide(this.z, this.n, this.kind);
  int get a => z + n;
}

// Superscript digits for isotope notation (¹⁴C).
const Map<String, String> _kSup = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
};
String _superscript(int v) =>
    v.toString().split('').map((c) => _kSup[c] ?? c).join();

// ─────────────────────────────────────────────────────────────────────────────

class IsotopesGame extends StatefulWidget {
  final MiniGameSession session;
  const IsotopesGame({super.key, required this.session});

  @override
  State<IsotopesGame> createState() => _IsotopesGameState();
}

class _IsotopesGameState extends State<IsotopesGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _AtomModel _model = _AtomModel();

  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  // Round progress.
  int _solves = 0; // nuclides built this run — drives difficulty
  int _streak = 0; // consecutive correct locks
  double _promptElapsed = 0; // seconds the current prompt has been up (running)

  _Nuclide _target = const _Nuclide(6, 6, _PromptKind.counts);

  // Transient banner ("NOT A MATCH" / "CARBON-14 ✓").
  String _banner = '';
  Color _bannerColor = _kGood;
  double _bannerAge = -1;

  @override
  void initState() {
    super.initState();
    _pickTarget(); // calm ready-state prompt visible before the round
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── loop ───────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _model.clock.value += dt; // drives the painter (no setState per frame)

    final running = widget.session.isRunning;
    if (running && !_wasRunning) {
      _wasRunning = true;
      _onRunStart();
    } else if (!running) {
      _wasRunning = false;
    }
    if (running) _promptElapsed += dt;

    // Advance juice (read by the painter; no rebuild needed).
    for (final p in _model.particles) {
      p.step(dt);
    }
    _model.particles.removeWhere((p) => p.life <= 0);
    _model.flash = math.max(0, _model.flash - dt * 2.6);
    _model.success = math.max(0, _model.success - dt * 1.8);
    if (_bannerAge >= 0) {
      _bannerAge += dt;
      if (_bannerAge > 1.3) {
        _bannerAge = -1;
        if (mounted) setState(() {});
      }
    }
  }

  /// Fired the first frame the host flips the round to `playing`. Resets the
  /// build to a clean slate and serves a fresh first prompt.
  void _onRunStart() {
    setState(() {
      _solves = 0;
      _streak = 0;
      _model.particles.clear();
      _model.flash = 0;
      _model.success = 0;
      _bannerAge = -1;
      _model.z = 1;
      _model.n = 0;
      _pickTarget();
      _refreshMatch();
    });
  }

  // ── difficulty / target selection ───────────────────────────────────────────

  /// Elements allowed at the current level (widens as you build more).
  List<_PoolEntry> get _allowedPool {
    final int zCap = _solves < 3
        ? 8
        : _solves < 7
            ? 14
            : _solves < 12
                ? 20
                : 26;
    final pool = _kPool.where((e) => e.z <= zCap).toList();
    return pool.isEmpty ? _kPool : pool;
  }

  /// Prompt kinds unlocked at the current level, biased toward the newest.
  _PromptKind _chooseKind() {
    final unlocked = <_PromptKind>[_PromptKind.counts];
    if (_solves >= 2) unlocked.add(_PromptKind.massName);
    if (_solves >= 4) unlocked.add(_PromptKind.neutrons);
    if (_solves >= 7) unlocked.add(_PromptKind.symbol);
    // Weight the two hardest unlocked kinds more heavily.
    final bag = <_PromptKind>[...unlocked];
    if (unlocked.length >= 2) bag.add(unlocked[unlocked.length - 1]);
    if (unlocked.length >= 3) bag.add(unlocked[unlocked.length - 2]);
    return bag[_rng.nextInt(bag.length)];
  }

  void _pickTarget() {
    final pool = _allowedPool;
    _PoolEntry e = pool[_rng.nextInt(pool.length)];
    // Avoid serving the exact same element back-to-back when we can.
    if (pool.length > 1) {
      int guard = 0;
      while (e.z == _target.z && guard++ < 4) {
        e = pool[_rng.nextInt(pool.length)];
      }
    }
    final n = e.neutrons[_rng.nextInt(e.neutrons.length)];
    _target = _Nuclide(e.z, n, _chooseKind());
    _promptElapsed = 0;
  }

  // ── build interaction ───────────────────────────────────────────────────────

  void _bumpProtons(int d) {
    setState(() {
      _model.z = (_model.z + d).clamp(0, _kMaxProtons);
      _refreshMatch();
    });
  }

  void _bumpNeutrons(int d) {
    setState(() {
      _model.n = (_model.n + d).clamp(0, _kMaxNeutrons);
      _refreshMatch();
    });
  }

  void _refreshMatch() {
    _model.matched = _model.z == _target.z && _model.n == _target.n;
  }

  void _lockIn() {
    if (!widget.session.isRunning) return;
    if (_model.matched) {
      // Score: base + speed runway + capped streak bonus.
      _streak++;
      final speed = (_kMaxSpeedBonus *
              (1 - (_promptElapsed / _kSpeedWindow)).clamp(0.0, 1.0))
          .round();
      final streakBonus = math.min(_streak, _kMaxStreakBonus);
      widget.session.addScore(_kBase + speed + streakBonus);
      widget.session.noteStreak(_streak);

      _solves++;
      _model.success = 1.0;
      _spawnBurst(_kGood);
      _showBanner('${_nameForZ(_target.z)}-${_target.a}  ✓', _kGood);

      setState(() {
        _pickTarget();
        _refreshMatch();
      });
    } else {
      // Kind failure: no score loss, but the streak breaks and the field flashes.
      _streak = 0;
      _model.flash = 0.7;
      _spawnBurst(_kBad);
      _showBanner('NOT A MATCH', _kBad);
      setState(() {});
    }
  }

  void _spawnBurst(Color color) {
    _model.particles.addAll(
      FxBurst.spawn(_model.nucleusCenter, color, count: 16, speed: 150),
    );
  }

  void _showBanner(String text, Color color) {
    _banner = text;
    _bannerColor = color;
    _bannerAge = 0;
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return Column(
      children: [
        // Prompt / target card.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: _TargetCard(
            target: _target,
            zMatch: _model.z == _target.z,
            nMatch: _model.n == _target.n,
          ),
        ),
        // The live atom + readout.
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _NuclidePainter(_model),
                  ),
                ),
              ),
              // Live element readout — the "protons define the element" teacher.
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _ReadoutBar(z: _model.z, n: _model.n),
              ),
              if (_bannerAge >= 0) _buildBanner(),
            ],
          ),
        ),
        // Steppers.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'PROTONS',
                  sub: 'sets the element',
                  value: _model.z,
                  color: _kProton,
                  matched: _model.z == _target.z,
                  enabled: running,
                  onMinus: _model.z > 0 ? () => _bumpProtons(-1) : null,
                  onPlus: _model.z < _kMaxProtons ? () => _bumpProtons(1) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stepper(
                  label: 'NEUTRONS',
                  sub: 'sets the isotope',
                  value: _model.n,
                  color: _kNeutron,
                  matched: _model.n == _target.n,
                  enabled: running,
                  onMinus: _model.n > 0 ? () => _bumpNeutrons(-1) : null,
                  onPlus:
                      _model.n < _kMaxNeutrons ? () => _bumpNeutrons(1) : null,
                ),
              ),
            ],
          ),
        ),
        // Lock button.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: _LockButton(
            armed: _model.matched && running,
            enabled: running,
            onTap: _lockIn,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final t = _bannerAge;
    final opacity = t < 0.12
        ? (t / 0.12)
        : t > 0.95
            ? (1 - (t - 0.95) / 0.35).clamp(0.0, 1.0)
            : 1.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity.toDouble(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _bannerColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _bannerColor.withValues(alpha: 0.9)),
                boxShadow: [
                  BoxShadow(
                      color: _bannerColor.withValues(alpha: 0.45),
                      blurRadius: 24),
                ],
              ),
              child: Text(
                _banner,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: _bannerColor, blurRadius: 14)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════ model + painter ══

/// Mutable simulation state shared with the painter. The State mutates it; the
/// painter reads it every frame (repaint driven by [clock]) so no per-frame
/// setState is needed over the widget tree.
class _AtomModel {
  final ValueNotifier<double> clock = ValueNotifier<double>(0);
  int z = 1;
  int n = 0;
  bool matched = false;
  double flash = 0; // red error flash, 0..1
  double success = 0; // green success pulse, 0..1
  final List<FxParticle> particles = [];

  Size lastSize = Size.zero;
  Offset get nucleusCenter =>
      Offset(lastSize.width / 2, lastSize.height * 0.52);
}

/// Electron shell capacities (period model): 2, 8, 18… enough for Z ≤ 26.
const List<int> _kShellCaps = [2, 8, 18];

class _NuclidePainter extends CustomPainter {
  final _AtomModel m;
  _NuclidePainter(this.m) : super(repaint: m.clock);

  @override
  void paint(Canvas canvas, Size size) {
    m.lastSize = size;
    final clock = m.clock.value;
    GameFx.atmosphere(canvas, size, _kAccent, clock, motes: 26);

    final c = Offset(size.width / 2, size.height * 0.52);

    // Match aura: the whole atom blooms green when the build is correct, so the
    // confirm is felt, not just read.
    final auraT = m.matched ? 1.0 : 0.0;
    final successPulse = m.success;
    if (auraT > 0 || successPulse > 0) {
      final pulse = 0.5 + 0.5 * math.sin(clock * 4);
      canvas.drawCircle(
        c,
        96 + 8 * pulse,
        Paint()
          ..color = _kGood.withValues(
              alpha: 0.10 * auraT + 0.18 * successPulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }

    _paintElectronShells(canvas, c, clock);
    _paintNucleus(canvas, c, clock);

    // Error flash over the whole field.
    if (m.flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBad.withValues(alpha: m.flash * 0.22),
      );
    }

    FxBurst.paint(canvas, m.particles);
  }

  void _paintElectronShells(Canvas canvas, Offset c, double clock) {
    // Neutral-atom electrons = Z. Drawn faintly to reinforce element identity.
    int remaining = m.z;
    final shellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int s = 0; s < _kShellCaps.length && remaining > 0; s++) {
      final radius = 56.0 + s * 22.0;
      final inShell = math.min(remaining, _kShellCaps[s]);
      remaining -= inShell;
      shellPaint.color = _kElectron.withValues(alpha: 0.18);
      canvas.drawCircle(c, radius, shellPaint);
      final spin = clock * (1.0 - s * 0.3) * (s.isEven ? 1 : -1);
      for (int i = 0; i < inShell; i++) {
        final a = spin + (i / inShell) * math.pi * 2;
        final pos = c + Offset(math.cos(a), math.sin(a)) * radius;
        canvas.drawCircle(
          pos,
          5,
          Paint()
            ..color = _kElectron.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(pos, 3, Paint()..color = _kElectron);
      }
    }
  }

  void _paintNucleus(Canvas canvas, Offset c, double clock) {
    final nucleons = m.z + m.n;
    if (nucleons == 0) {
      canvas.drawCircle(
        c,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _kAccent.withValues(alpha: 0.4),
      );
      return;
    }
    // Interleave protons / neutrons through a golden-angle spiral so the core
    // reads as a mixed cluster.
    final colors = <Color>[];
    int p = m.z, n = m.n;
    while (p > 0 || n > 0) {
      if (p > 0) {
        colors.add(_kProton);
        p--;
      }
      if (n > 0) {
        colors.add(_kNeutron);
        n--;
      }
    }
    const nucleonR = 7.5;
    final golden = math.pi * (3 - math.sqrt(5));
    for (int i = 0; i < nucleons; i++) {
      final r = nucleonR * 0.95 * math.sqrt(i + 0.5);
      final a = i * golden + math.sin(clock * 1.6 + i) * 0.04;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r;
      GameFx.orb(canvas, pos, nucleonR, colors[i],
          glow: 0.6, specular: false);
    }
  }

  @override
  bool shouldRepaint(covariant _NuclidePainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════ widgets ══

/// The prompt card. Shows the asked-for nuclide (phrased by [_PromptKind]) plus
/// two status pills that confirm the element axis (Z) and the isotope axis (N).
class _TargetCard extends StatelessWidget {
  final _Nuclide target;
  final bool zMatch;
  final bool nMatch;
  const _TargetCard({
    required this.target,
    required this.zMatch,
    required this.nMatch,
  });

  @override
  Widget build(BuildContext context) {
    final name = _nameForZ(target.z);
    final symbol = _symbolForZ(target.z);

    String headline;
    String sub;
    switch (target.kind) {
      case _PromptKind.counts:
        headline = '${target.z} PROTONS · ${target.n} NEUTRONS';
        sub = 'build it from the counts';
        break;
      case _PromptKind.massName:
        headline = '$name-${target.a}';
        sub = 'element + mass number A=${target.a}';
        break;
      case _PromptKind.neutrons:
        headline = '$name';
        sub = 'the isotope with ${target.n} neutrons';
        break;
      case _PromptKind.symbol:
        headline = '${_superscript(target.a)}$symbol';
        sub = 'read the isotope notation';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: _kAccent.withValues(alpha: 0.16), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Text(
            'BUILD',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: _kAccent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusPill(label: 'ELEMENT', ok: zMatch, color: _kProton),
              const SizedBox(width: 10),
              _StatusPill(label: 'ISOTOPE', ok: nMatch, color: _kNeutron),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool ok;
  final Color color;
  const _StatusPill({required this.label, required this.ok, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = ok ? _kGood : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: ok ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: ok ? 1.0 : 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: ok ? Colors.white : c.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live build readout: the big element symbol/name from Z, plus Z / N / A chips.
/// This is the in-mechanic lesson: turn the proton dial and the element changes;
/// turn the neutron dial and A changes while the element stays put.
class _ReadoutBar extends StatelessWidget {
  final int z;
  final int n;
  const _ReadoutBar({required this.z, required this.n});

  @override
  Widget build(BuildContext context) {
    final symbol = _symbolForZ(z);
    final name = _nameForZ(z);
    final a = z + n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Isotope notation: superscript A + symbol.
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withValues(alpha: 0.14),
              border: Border.all(color: _kAccent.withValues(alpha: 0.6)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: _kFont, color: Colors.white),
                children: [
                  if (z >= 1)
                    TextSpan(
                      text: _superscript(a),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  TextSpan(
                    text: symbol,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  z >= 1 ? name : 'NO ELEMENT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniChip(label: 'Z', value: '$z', color: _kProton),
                    const SizedBox(width: 6),
                    _MiniChip(label: 'N', value: '$n', color: _kNeutron),
                    const SizedBox(width: 6),
                    _MiniChip(label: 'A', value: '$a', color: _kAccent),
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

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// A labelled +/- stepper. Big tap targets; the value glows green when this
/// axis matches the target.
class _Stepper extends StatelessWidget {
  final String label;
  final String sub;
  final int value;
  final Color color;
  final bool matched;
  final bool enabled;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _Stepper({
    required this.label,
    required this.sub,
    required this.value,
    required this.color,
    required this.matched,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = matched ? _kGood : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched
              ? _kGood.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: color,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 9.5,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(
                  icon: Icons.remove,
                  color: color,
                  onTap: enabled ? onMinus : null),
              Text(
                '$value',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  shadows: matched
                      ? [const Shadow(color: _kGood, blurRadius: 14)]
                      : null,
                ),
              ),
              _StepButton(
                  icon: Icons.add,
                  color: color,
                  onTap: enabled ? onPlus : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? color.withValues(alpha: 0.22) : Colors.white10,
          border: Border.all(
              color: on ? color : Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon,
            color: on ? Colors.white : Colors.white24, size: 24),
      ),
    );
  }
}

/// The commit button. Glows green and reads "✓" when the build matches and the
/// round is live; otherwise a calm neutral state.
class _LockButton extends StatelessWidget {
  final bool armed;
  final bool enabled;
  final VoidCallback onTap;
  const _LockButton(
      {required this.armed, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = armed ? _kGood : _kAccent;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 56,
        decoration: BoxDecoration(
          color: c.withValues(alpha: armed ? 0.9 : 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.9), width: 1.5),
          boxShadow: armed
              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 22)]
              : null,
        ),
        child: Center(
          child: Text(
            armed ? 'LOCK IT IN  ✓' : 'LOCK IT IN',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: armed ? Colors.black : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
